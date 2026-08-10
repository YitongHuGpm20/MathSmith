## Generates human-readable teaching Steps from parsed arithmetic expressions.
##
## This gameplay service applies grade-appropriate strategies such as making
## ten, place-value decomposition, distributive multiplication, fact-family
## division, and operation precedence. GameManager owns the gameplay flow.
extends RefCounted

#region ========== References ==========

var expressionParser := preload("res://Scripts/Math/ExpressionParser.gd").new()

#endregion

#region ========== Functions ==========

# Generates ordered teaching steps for one parser-compatible expression.
func GenerateSteps(expression: String) -> Array[String]:
	var expressionTree := expressionParser.ParseExpression(expression)

	if expressionTree.is_empty():
		push_error("Failed to parse expression: " + expression)
		return []

	var operationCount: int = expressionParser.CountOperations(expressionTree)

	if operationCount == 0:
		return []

	# Prefer purposeful regrouping when an addition chain offers an easier sum.
	var threeAddendSteps := GenerateThreeAddendMakeTenSteps(expressionTree)

	if not threeAddendSteps.is_empty():
		return FinalizeSteps(expression, FormatLocalSteps(threeAddendSteps))

	var fourAddendSteps := GenerateFourAddendGroupingSteps(expressionTree)

	if not fourAddendSteps.is_empty():
		return FinalizeSteps(expression, FormatLocalSteps(fourAddendSteps))

	var cancellationSteps := GenerateAdditionSubtractionCancellationSteps(expressionTree)

	if not cancellationSteps.is_empty():
		return FinalizeSteps(expression, FormatLocalSteps(cancellationSteps))

	# A single operation receives a full strategy demonstration.
	if operationCount == 1:
		return FinalizeSteps(expression, FormatLocalSteps(GenerateDetailedOperationSteps(expressionTree)))

	# Multi-operation expressions emphasize order and reduce one operation at a time.
	return FinalizeSteps(expression, GenerateExpressionReductionSteps(expressionTree))

# Generates two paired tens by splitting the middle of three addends.
func GenerateThreeAddendMakeTenSteps(expressionTree: Dictionary) -> Array[String]:
	var addends: Array[int] = []

	if not CollectAdditionOperands(expressionTree, addends) or addends.size() != 3:
		return []

	var firstNumber := addends[0]
	var middleNumber := addends[1]
	var lastNumber := addends[2]

	# This strategy applies when the middle addend completes both outer tens.
	if firstNumber >= 10 or lastNumber >= 10:
		return []

	var firstAmountToTen := 10 - firstNumber
	var lastAmountToTen := 10 - lastNumber

	if firstAmountToTen <= 0 or lastAmountToTen <= 0:
		return []

	if firstAmountToTen + lastAmountToTen != middleNumber:
		return []

	return [
		"%d + (%d + %d) + %d" % [
			firstNumber,
			firstAmountToTen,
			lastAmountToTen,
			lastNumber
		],
		"(%d + %d) + (%d + %d)" % [
			firstNumber,
			firstAmountToTen,
			lastAmountToTen,
			lastNumber
		],
		"10 + 10",
		"20"
	]

# Flattens an addition-only expression tree into its ordered numeric addends.
func CollectAdditionOperands(expressionNode: Dictionary, addends: Array[int]) -> bool:
	if expressionNode["type"] == "number":
		addends.append(expressionNode["value"])
		return true

	if expressionNode["operation"] != "+":
		return false

	return (
		CollectAdditionOperands(expressionNode["left"], addends)
		and CollectAdditionOperands(expressionNode["right"], addends)
	)

# Groups four addends into two pairs when pairing makes both sums easier to read.
func GenerateFourAddendGroupingSteps(expressionTree: Dictionary) -> Array[String]:
	var addends: Array[int] = []

	if not CollectAdditionOperands(expressionTree, addends) or addends.size() != 4:
		return []

	var pairings := [
		[0, 1, 2, 3],
		[0, 2, 1, 3],
		[0, 3, 1, 2]
	]
	var bestPairing: Array = []
	var bestScore := 100000

	# Prefer pair totals close to a multiple of five, then preserve source order on ties.
	for pairing in pairings:
		var firstTotal: int = addends[pairing[0]] + addends[pairing[1]]
		var secondTotal: int = addends[pairing[2]] + addends[pairing[3]]
		var pairingScore := DistanceToMultipleOfFive(firstTotal) + DistanceToMultipleOfFive(secondTotal)

		if pairingScore < bestScore:
			bestScore = pairingScore
			bestPairing = pairing

	if bestPairing.is_empty() or bestPairing == pairings[0]:
		return []

	var firstLeft: int = addends[bestPairing[0]]
	var firstRight: int = addends[bestPairing[1]]
	var secondLeft: int = addends[bestPairing[2]]
	var secondRight: int = addends[bestPairing[3]]
	var firstPairTotal := firstLeft + firstRight
	var secondPairTotal := secondLeft + secondRight
	return [
		"(%d + %d) + (%d + %d)" % [firstLeft, firstRight, secondLeft, secondRight],
		"%d + %d" % [firstPairTotal, secondPairTotal],
		str(firstPairTotal + secondPairTotal)
	]

# Returns how far a value is from a nearby mental-math landmark.
func DistanceToMultipleOfFive(value: int) -> int:
	var remainder := value % 5
	return mini(remainder, 5 - remainder)

# Uses cancellation when the final subtraction naturally reduces the preceding addend.
func GenerateAdditionSubtractionCancellationSteps(expressionTree: Dictionary) -> Array[String]:
	if expressionTree["type"] != "operation" or expressionTree["operation"] != "-":
		return []

	var additionNode: Dictionary = expressionTree["left"]
	var subtractedNode: Dictionary = expressionTree["right"]

	if (
		additionNode["type"] != "operation"
		or additionNode["operation"] != "+"
		or additionNode["left"]["type"] != "number"
		or additionNode["right"]["type"] != "number"
		or subtractedNode["type"] != "number"
	):
		return []

	var baseValue: int = additionNode["left"]["value"]
	var addedValue: int = additionNode["right"]["value"]
	var subtractedValue: int = subtractedNode["value"]
	var difference := addedValue - subtractedValue

	if difference < 0:
		return []

	if difference == 0:
		return [str(baseValue)]

	return [
		"%d + (%d - %d)" % [baseValue, addedValue, subtractedValue],
		"%d + %d" % [baseValue, difference],
		str(baseValue + difference)
	]

# Produces a complete teaching strategy for a single binary operation.
func GenerateDetailedOperationSteps(operationNode: Dictionary) -> Array[String]:
	var leftValue: int = operationNode["left"]["value"]
	var rightValue: int = operationNode["right"]["value"]
	var operation: String = operationNode["operation"]

	match operation:
		"+":
			return GenerateAdditionSteps(leftValue, rightValue)
		"-":
			return GenerateSubtractionSteps(leftValue, rightValue)
		"*":
			return GenerateMultiplicationSteps(leftValue, rightValue)
		"/":
			return GenerateDivisionSteps(leftValue, rightValue)

	return []

# Generates addition steps using make-ten or place-value decomposition.
func GenerateAdditionSteps(firstNumber: int, secondNumber: int) -> Array[String]:
	var finalAnswer := firstNumber + secondNumber

	# Use the make-ten strategy for one-digit sums that cross ten.
	if firstNumber < 10 and secondNumber < 10 and finalAnswer > 10:
		var largerNumber := maxi(firstNumber, secondNumber)
		var smallerNumber := mini(firstNumber, secondNumber)
		var amountToTen := 10 - largerNumber
		var remainingAmount := smallerNumber - amountToTen
		return [
			"%d + %d + %d" % [largerNumber, amountToTen, remainingAmount],
			"10 + %d" % remainingAmount,
			str(finalAnswer)
		]

	# Use counting-on chunks for a small sum that does not cross ten.
	if firstNumber < 10 and secondNumber < 10:
		var largerNumber := maxi(firstNumber, secondNumber)
		var smallerNumber := mini(firstNumber, secondNumber)

		# Avoid padding a one-count strategy with a meaningless zero addend.
		if smallerNumber == 1:
			return [
				"Start at %d" % largerNumber,
				"Count on 1: %d" % finalAnswer,
				str(finalAnswer)
			]

		var firstChunk := maxi(floori(smallerNumber / 2.0), 1)
		var secondChunk := smallerNumber - firstChunk
		return [
			"%d + %d + %d" % [largerNumber, firstChunk, secondChunk],
			"%d + %d" % [largerNumber + firstChunk, secondChunk],
			str(finalAnswer)
		]

	# Combine a one-digit addend directly with the ones of a larger number.
	if firstNumber < 10 or secondNumber < 10:
		var largerNumber := maxi(firstNumber, secondNumber)
		var smallerNumber := mini(firstNumber, secondNumber)
		var largerOnes := largerNumber % 10
		var higherPlaces := largerNumber - largerOnes
		var onesTotal := largerOnes + smallerNumber

		if largerOnes == 0:
			return [
				"Start at %d" % largerNumber,
				"Count on %d: %d" % [smallerNumber, finalAnswer],
				str(finalAnswer)
			]

		# Bridge through the next ten when the combined ones exceed ten.
		if onesTotal > 10:
			var amountToNextTen := 10 - largerOnes
			var remainingAmount := smallerNumber - amountToNextTen
			return [
				"%d + (%d + %d)" % [largerNumber, amountToNextTen, remainingAmount],
				"(%d + %d) + %d" % [largerNumber, amountToNextTen, remainingAmount],
				"%d + %d" % [largerNumber + amountToNextTen, remainingAmount],
				str(finalAnswer)
			]

		return [
			"%d + (%d + %d)" % [higherPlaces, largerOnes, smallerNumber],
			"%d + %d" % [higherPlaces, onesTotal],
			str(finalAnswer)
		]

	# Decompose two larger values by place before combining like places.
	var firstParts := GetPlaceValueParts(firstNumber)
	var secondParts := GetPlaceValueParts(secondNumber)
	var groupedParts := GroupPlaceValueParts(firstParts, secondParts)
	var groupedTotals := SumPlaceValueGroups(firstParts, secondParts)
	return [
		"%s + %s" % [FormatPlaceValueDecomposition(firstParts), FormatPlaceValueDecomposition(secondParts)],
		groupedParts,
		groupedTotals,
		str(finalAnswer)
	]

# Generates subtraction steps using compensation, bridging, or place-value chunks.
func GenerateSubtractionSteps(firstNumber: int, secondNumber: int) -> Array[String]:
	var finalAnswer := firstNumber - secondNumber
	var onesValue := firstNumber % 10
	var nextRoundTen := ceili(secondNumber / 10.0) * 10
	var compensation := nextRoundTen - secondNumber

	# Subtract a nearby round number and compensate when the correction is small.
	if secondNumber >= 10 and compensation > 0 and compensation <= 2:
		var roundedDifference := firstNumber - nextRoundTen
		return [
			"%d - %d + %d" % [firstNumber, nextRoundTen, compensation],
			"%d + %d" % [roundedDifference, compensation],
			str(finalAnswer)
		]

	# Bridge through the previous multiple of ten when subtraction crosses it.
	if firstNumber <= 100 and onesValue > 0 and secondNumber > onesValue:
		var remainingAmount := secondNumber - onesValue
		return [
			"%d - %d - %d" % [firstNumber, onesValue, remainingAmount],
			"%d - %d" % [firstNumber - onesValue, remainingAmount],
			str(finalAnswer)
		]

	# Subtract multi-digit values in place-value chunks from largest to smallest.
	if secondNumber >= 10:
		var subtractionParts: Array[int] = []

		for placePart in GetPlaceValueParts(secondNumber):
			if placePart != 0:
				subtractionParts.append(placePart)

		var generatedSteps: Array[String] = []
		var runningValue := firstNumber

		generatedSteps.append("%d - %s" % [firstNumber, JoinSubtractions(subtractionParts)])

		for partIndex in range(subtractionParts.size()):
			runningValue -= subtractionParts[partIndex]
			var remainingParts := subtractionParts.slice(partIndex + 1)

			if remainingParts.is_empty():
				generatedSteps.append(str(runningValue))
			else:
				generatedSteps.append("%d - %s" % [runningValue, JoinSubtractions(remainingParts)])

		return generatedSteps

	# Split a one-digit subtrahend into manageable chunks for counting back.
	if secondNumber == 1:
		return [
			"Start at %d" % firstNumber,
			"Count back 1: %d" % finalAnswer,
			str(finalAnswer)
		]

	var firstChunk := maxi(floori(secondNumber / 2.0), 1)
	var secondChunk := secondNumber - firstChunk
	return [
		"%d - %d - %d" % [firstNumber, firstChunk, secondChunk],
		"%d - %d" % [firstNumber - firstChunk, secondChunk],
		str(finalAnswer)
	]

# Generates multiplication steps using repeated addition or the distributive property.
func GenerateMultiplicationSteps(firstNumber: int, secondNumber: int) -> Array[String]:
	var finalAnswer := firstNumber * secondNumber

	# Use partial products when either factor contains multiple digits.
	if firstNumber >= 10 or secondNumber >= 10:
		var largerNumber := maxi(firstNumber, secondNumber)
		var smallerNumber := mini(firstNumber, secondNumber)
		var placeParts := GetPlaceValueParts(largerNumber)
		var productParts: Array[int] = []

		for placePart in placeParts:
			productParts.append(placePart * smallerNumber)

		return [
			"%s * %d" % [FormatPlaceValueDecomposition(placeParts), smallerNumber],
			JoinProducts(placeParts, smallerNumber),
			JoinNumbers(productParts),
			str(finalAnswer)
		]

	# Use the distributive property to turn equal groups into partial products.
	if secondNumber == 1:
		return [
			"1 group of %d" % firstNumber,
			"%d * 1" % firstNumber,
			str(finalAnswer)
		]

	var firstGroupCount := maxi(floori(secondNumber / 2.0), 1)
	var secondGroupCount := secondNumber - firstGroupCount
	return [
		"%d * (%d + %d)" % [firstNumber, firstGroupCount, secondGroupCount],
		"(%d * %d) + (%d * %d)" % [
			firstNumber,
			firstGroupCount,
			firstNumber,
			secondGroupCount
		],
		"%d + %d" % [firstNumber * firstGroupCount, firstNumber * secondGroupCount],
		str(finalAnswer)
	]

# Generates division steps directly or with useful partial-quotient decomposition.
func GenerateDivisionSteps(dividend: int, divisor: int) -> Array[String]:
	if divisor == 0 or dividend % divisor != 0:
		push_error("Step Ordering currently requires exact whole-number division.")
		return []

	var quotient := floori(float(dividend) / float(divisor))

	# Show partial quotients only for a larger division with a clean round chunk.
	if dividend >= 80 and quotient >= 10:
		var firstQuotientPart := quotient - 1

		while firstQuotientPart > 0 and firstQuotientPart * divisor % 10 != 0:
			firstQuotientPart -= 1

		var secondQuotientPart := quotient - firstQuotientPart

		if firstQuotientPart > 0 and secondQuotientPart > 0:
			var firstDividendPart := firstQuotientPart * divisor
			var secondDividendPart := secondQuotientPart * divisor
			return [
				"(%d + %d) / %d" % [firstDividendPart, secondDividendPart, divisor],
				"%d / %d + %d / %d" % [firstDividendPart, divisor, secondDividendPart, divisor],
				"%d + %d" % [firstQuotientPart, secondQuotientPart],
				str(quotient)
			]

	# Known division facts need no artificial inverse-equation detour.
	return [str(quotient)]

# Generates reduction steps while preserving parser-defined operation order.
func GenerateExpressionReductionSteps(expressionTree: Dictionary) -> Array[String]:
	var generatedSteps: Array[String] = []
	var remainingOperations := expressionParser.CountOperations(expressionTree)

	while remainingOperations > 0:
		var nextOperation := FindNextOperation(expressionTree)

		if nextOperation.is_empty():
			return []

		var operationResult := EvaluateOperation(nextOperation)

		# Resolve the operation directly; expansion is reserved for standalone teaching facts.
		AppendUniqueStep(
			generatedSteps,
			"= " + FormatExpression(expressionTree, nextOperation["id"], str(operationResult))
		)

		ReplaceOperationWithNumber(nextOperation, operationResult)
		remainingOperations -= 1

		# Collapse an obvious add-then-subtract cancellation after precedence is resolved.
		var cancellationNode := FindResolvedCancellation(expressionTree)

		if not cancellationNode.is_empty():
			var cancellationResult: int = cancellationNode["left"]["left"]["value"]
			ReplaceOperationWithNumber(cancellationNode, cancellationResult)
			remainingOperations -= 2
			AppendUniqueStep(generatedSteps, "= " + FormatExpression(expressionTree))

	return generatedSteps

# Finds a numeric pattern shaped like (a + b) - b after earlier reductions.
func FindResolvedCancellation(expressionNode: Dictionary) -> Dictionary:
	if expressionNode["type"] == "number":
		return {}

	if (
		expressionNode["operation"] == "-"
		and expressionNode["left"]["type"] == "operation"
		and expressionNode["left"]["operation"] == "+"
		and expressionNode["left"]["left"]["type"] == "number"
		and expressionNode["left"]["right"]["type"] == "number"
		and expressionNode["right"]["type"] == "number"
		and expressionNode["left"]["right"]["value"] == expressionNode["right"]["value"]
	):
		return expressionNode

	var leftMatch := FindResolvedCancellation(expressionNode["left"])

	if not leftMatch.is_empty():
		return leftMatch

	return FindResolvedCancellation(expressionNode["right"])

# Finds the next fully numeric operation in left-to-right tree order.
func FindNextOperation(expressionNode: Dictionary) -> Dictionary:
	if expressionNode["type"] == "number":
		return {}

	if expressionNode["left"]["type"] == "operation":
		return FindNextOperation(expressionNode["left"])

	if expressionNode["right"]["type"] == "operation":
		return FindNextOperation(expressionNode["right"])

	return expressionNode

# Evaluates one binary operation whose children are numeric.
func EvaluateOperation(operationNode: Dictionary) -> int:
	var leftValue: int = operationNode["left"]["value"]
	var rightValue: int = operationNode["right"]["value"]

	match operationNode["operation"]:
		"+":
			return leftValue + rightValue
		"-":
			return leftValue - rightValue
		"*":
			return leftValue * rightValue
		"/":
			if rightValue == 0 or leftValue % rightValue != 0:
				push_error("Step Ordering currently requires exact whole-number division.")
				return 0
			return floori(float(leftValue) / float(rightValue))

	return 0

# Replaces a completed operation node with its numeric result in place.
func ReplaceOperationWithNumber(operationNode: Dictionary, result: int) -> void:
	var nodeId: int = operationNode["id"]
	operationNode.clear()
	operationNode["id"] = nodeId
	operationNode["type"] = "number"
	operationNode["value"] = result

# Formats an expression tree with an optional teaching expansion override.
func FormatExpression(expressionNode: Dictionary, targetNodeId: int = -1, replacement: String = "") -> String:
	return FormatNode(expressionNode, "", false, targetNodeId, replacement)

# Recursively formats operations and preserves required precedence parentheses.
func FormatNode(
	expressionNode: Dictionary,
	parentOperation: String,
	isRightChild: bool,
	targetNodeId: int,
	replacement: String
) -> String:
	if expressionNode["id"] == targetNodeId and not replacement.is_empty():
		# A completed numeric result never needs parentheses around itself.
		if replacement.is_valid_int() or parentOperation.is_empty():
			return replacement

		# Addition chains remain readable without redundant associative grouping.
		if parentOperation == "+" and IsAdditionOnlyExpression(replacement):
			return replacement

		return "(" + replacement + ")"

	if expressionNode["type"] == "number":
		return str(expressionNode["value"])

	var operation: String = expressionNode["operation"]
	var leftText := FormatNode(expressionNode["left"], operation, false, targetNodeId, replacement)
	var rightText := FormatNode(expressionNode["right"], operation, true, targetNodeId, replacement)
	var formattedText := "%s %s %s" % [leftText, operation, rightText]

	if NeedsParentheses(operation, parentOperation, isRightChild):
		return "(" + formattedText + ")"

	return formattedText

# Determines when child operations require parentheses in formatted output.
func NeedsParentheses(operation: String, parentOperation: String, isRightChild: bool) -> bool:
	if parentOperation.is_empty():
		return false

	var operationPrecedence := GetOperationPrecedence(operation)
	var parentPrecedence := GetOperationPrecedence(parentOperation)

	if operationPrecedence < parentPrecedence:
		return true

	return isRightChild and operationPrecedence == parentPrecedence and parentOperation in ["-", "/"]

# Returns standard arithmetic precedence for one binary operator.
func GetOperationPrecedence(operation: String) -> int:
	return 2 if operation in ["*", "/"] else 1

# Returns whether text contains only whole numbers, spaces, and addition signs.
func IsAdditionOnlyExpression(expression: String) -> bool:
	var additionPattern := RegEx.new()
	return (
		additionPattern.compile("^[0-9+ ]+$") == OK
		and additionPattern.search(expression) != null
	)

# Converts local expressions into Step Card display strings.
func FormatLocalSteps(localSteps: Array[String]) -> Array[String]:
	var formattedSteps: Array[String] = []

	for localStep in localSteps:
		AppendUniqueStep(formattedSteps, "= " + localStep)

	return formattedSteps

# Removes repeated source expressions and guarantees consistent display prefixes.
func FinalizeSteps(sourceExpression: String, generatedSteps: Array[String]) -> Array[String]:
	var finalSteps: Array[String] = []
	var normalizedSource := NormalizeExpressionText(sourceExpression)

	for generatedStep in generatedSteps:
		var normalizedStep := NormalizeExpressionText(generatedStep.trim_prefix("= "))

		if normalizedStep == normalizedSource:
			continue

		AppendUniqueStep(finalSteps, generatedStep)

	return finalSteps

# Normalizes spacing for reliable unchanged-expression comparisons.
func NormalizeExpressionText(expression: String) -> String:
	return expression.replace(" ", "")

# Adds a step only when it differs from the previously generated display step.
func AppendUniqueStep(generatedSteps: Array[String], stepText: String) -> void:
	if generatedSteps.is_empty() or generatedSteps.back() != stepText:
		generatedSteps.append(stepText)

# Returns the non-zero expanded place-value parts of a whole number.
func GetPlaceValueParts(number: int) -> Array[int]:
	var placeParts: Array[int] = []
	var placeValue: int = 1
	var remainingNumber := number

	while remainingNumber > 0:
		var digitValue := remainingNumber % 10

		placeParts.push_front(digitValue * placeValue)

		remainingNumber = floori(remainingNumber / 10.0)
		placeValue *= 10

	if placeParts.is_empty():
		placeParts.append(0)

	return placeParts

# Groups matching place-value parts from two addends.
func GroupPlaceValueParts(firstParts: Array[int], secondParts: Array[int]) -> String:
	var maxPlaces := maxi(firstParts.size(), secondParts.size())
	var paddedFirst := PadPlaceValueParts(firstParts, maxPlaces)
	var paddedSecond := PadPlaceValueParts(secondParts, maxPlaces)
	var groups: Array[String] = []

	for partIndex in range(maxPlaces):
		var firstPart: int = paddedFirst[partIndex]
		var secondPart: int = paddedSecond[partIndex]

		# Omit zero placeholders instead of exposing mechanical place alignment.
		if firstPart == 0 and secondPart == 0:
			continue
		elif firstPart == 0:
			groups.append(str(secondPart))
		elif secondPart == 0:
			groups.append(str(firstPart))
		else:
			groups.append("(%d + %d)" % [firstPart, secondPart])

	return " + ".join(groups)

# Returns the total for each matching place-value group.
func SumPlaceValueGroups(firstParts: Array[int], secondParts: Array[int]) -> String:
	var maxPlaces := maxi(firstParts.size(), secondParts.size())
	var paddedFirst := PadPlaceValueParts(firstParts, maxPlaces)
	var paddedSecond := PadPlaceValueParts(secondParts, maxPlaces)
	var groupTotals: Array[int] = []

	for partIndex in range(maxPlaces):
		groupTotals.append(paddedFirst[partIndex] + paddedSecond[partIndex])

	return JoinNumbers(groupTotals)

# Pads missing leading place values with zeroes for aligned grouping.
func PadPlaceValueParts(placeParts: Array[int], targetSize: int) -> Array[int]:
	var paddedParts := placeParts.duplicate()

	while paddedParts.size() < targetSize:
		paddedParts.push_front(0)

	return paddedParts

# Joins number parts into a readable addition expression.
func JoinNumbers(numbers: Array[int]) -> String:
	var numberTexts: PackedStringArray = []

	for number in numbers:
		if number != 0 or numbers.size() == 1:
			numberTexts.append(str(number))

	return " + ".join(numberTexts)

# Wraps a place-value sum only when it contains multiple visible terms.
func FormatPlaceValueDecomposition(placeParts: Array[int]) -> String:
	var visiblePartCount: int = 0

	for placePart in placeParts:
		if placePart != 0:
			visiblePartCount += 1

	var decomposition := JoinNumbers(placeParts)
	return "(" + decomposition + ")" if visiblePartCount > 1 else decomposition

# Joins number parts into a readable sequential subtraction expression.
func JoinSubtractions(numbers: Array[int]) -> String:
	var numberTexts: PackedStringArray = []

	for number in numbers:
		if number != 0 or numbers.size() == 1:
			numberTexts.append(str(number))

	return " - ".join(numberTexts)

# Joins place-value multiplication into a partial-product expression.
func JoinProducts(placeParts: Array[int], multiplier: int) -> String:
	var productTexts: PackedStringArray = []

	for placePart in placeParts:
		if placePart != 0 or placeParts.size() == 1:
			productTexts.append("(%d * %d)" % [placePart, multiplier])

	return " + ".join(productTexts)

#endregion
