## Parses arithmetic expressions and generates human-readable teaching steps.
##
## This gameplay service applies grade-appropriate strategies such as making
## ten, place-value decomposition, distributive multiplication, fact-family
## division, and operation precedence. GameManager owns the gameplay flow.
extends RefCounted

#region ========== Variables ==========

var tokens: Array[String] = []
var tokenIndex: int = 0
var nextNodeId: int = 0

#endregion

#region ========== Functions ==========

# Generates ordered teaching steps for one parser-compatible expression.
func GenerateSteps(expression: String) -> Array[String]:
	var expressionTree := ParseExpression(expression)

	if expressionTree.is_empty():
		push_error("Failed to parse expression: " + expression)
		return []

	var operationCount := CountOperations(expressionTree)

	if operationCount == 0:
		return []

	# A single operation receives a full strategy demonstration.
	if operationCount == 1:
		return FormatLocalSteps(GenerateDetailedOperationSteps(expressionTree))

	# Multi-operation expressions emphasize order and reduce one operation at a time.
	return GenerateExpressionReductionSteps(expressionTree, operationCount)

# Parses a complete expression into an operator tree.
func ParseExpression(expression: String) -> Dictionary:
	tokens = TokenizeExpression(expression)
	tokenIndex = 0
	nextNodeId = 0

	if tokens.is_empty():
		return {}

	var expressionTree := ParseAdditionAndSubtraction()

	# Reject expressions containing unused or malformed tokens.
	if expressionTree.is_empty() or tokenIndex != tokens.size():
		return {}

	return expressionTree

# Converts ASCII arithmetic text into number and operator tokens.
func TokenizeExpression(expression: String) -> Array[String]:
	var parsedTokens: Array[String] = []
	var currentNumber: String = ""

	for character in expression:
		if character.is_valid_int():
			currentNumber += character
			continue

		# Commit a completed number before processing the next symbol.
		if not currentNumber.is_empty():
			parsedTokens.append(currentNumber)
			currentNumber = ""

		if character in ["+", "-", "*", "/", "(", ")"]:
			parsedTokens.append(character)
		elif character != " ":
			return []

	if not currentNumber.is_empty():
		parsedTokens.append(currentNumber)

	return parsedTokens

# Parses left-associative addition and subtraction operations.
func ParseAdditionAndSubtraction() -> Dictionary:
	var leftNode := ParseMultiplicationAndDivision()

	while not leftNode.is_empty() and HasCurrentToken(["+", "-"]):
		var operation: String = AdvanceToken()
		var rightNode := ParseMultiplicationAndDivision()

		if rightNode.is_empty():
			return {}

		leftNode = CreateOperationNode(operation, leftNode, rightNode)

	return leftNode

# Parses left-associative multiplication and division operations.
func ParseMultiplicationAndDivision() -> Dictionary:
	var leftNode := ParseFactor()

	while not leftNode.is_empty() and HasCurrentToken(["*", "/"]):
		var operation: String = AdvanceToken()
		var rightNode := ParseFactor()

		if rightNode.is_empty():
			return {}

		leftNode = CreateOperationNode(operation, leftNode, rightNode)

	return leftNode

# Parses a whole number or a parenthesized subexpression.
func ParseFactor() -> Dictionary:
	if tokenIndex >= tokens.size():
		return {}

	var currentToken: String = tokens[tokenIndex]

	if currentToken == "(":
		tokenIndex += 1
		var groupedNode := ParseAdditionAndSubtraction()

		if tokenIndex >= tokens.size() or tokens[tokenIndex] != ")":
			return {}

		tokenIndex += 1
		return groupedNode

	if not currentToken.is_valid_int():
		return {}

	tokenIndex += 1
	return CreateNumberNode(int(currentToken))

# Creates one uniquely identifiable number node.
func CreateNumberNode(value: int) -> Dictionary:
	var numberNode := {
		"id": nextNodeId,
		"type": "number",
		"value": value
	}
	nextNodeId += 1
	return numberNode

# Creates one uniquely identifiable binary operation node.
func CreateOperationNode(operation: String, leftNode: Dictionary, rightNode: Dictionary) -> Dictionary:
	var operationNode := {
		"id": nextNodeId,
		"type": "operation",
		"operation": operation,
		"left": leftNode,
		"right": rightNode
	}
	nextNodeId += 1
	return operationNode

# Returns whether the current parser token matches an allowed value.
func HasCurrentToken(allowedTokens: Array) -> bool:
	return tokenIndex < tokens.size() and tokens[tokenIndex] in allowedTokens

# Returns the current token and advances the parser position.
func AdvanceToken() -> String:
	var currentToken := tokens[tokenIndex]
	tokenIndex += 1
	return currentToken

# Counts binary operations contained in an expression tree.
func CountOperations(expressionNode: Dictionary) -> int:
	if expressionNode["type"] == "number":
		return 0

	return 1 + CountOperations(expressionNode["left"]) + CountOperations(expressionNode["right"])

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

		var firstChunk := maxi(int(smallerNumber / 2), 1)
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
		"(%s) + (%s)" % [JoinNumbers(firstParts), JoinNumbers(secondParts)],
		groupedParts,
		groupedTotals,
		str(finalAnswer)
	]

# Generates subtraction steps by bridging through a ten or subtracting chunks.
func GenerateSubtractionSteps(firstNumber: int, secondNumber: int) -> Array[String]:
	var finalAnswer := firstNumber - secondNumber
	var onesValue := firstNumber % 10

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

	var firstChunk := maxi(int(secondNumber / 2), 1)
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
			"(%s) * %d" % [JoinNumbers(placeParts), smallerNumber],
			JoinProducts(placeParts, smallerNumber),
			JoinNumbers(productParts),
			str(finalAnswer)
		]

	# Use equal groups and regroup them into two easier partial sums.
	if secondNumber == 1:
		return [
			"1 group of %d" % firstNumber,
			"%d * 1" % firstNumber,
			str(finalAnswer)
		]

	var repeatedAddends: Array[int] = []

	for addendIndex in range(secondNumber):
		repeatedAddends.append(firstNumber)

	var firstGroupCount := maxi(secondNumber / 2, 1)
	var secondGroupCount := secondNumber - firstGroupCount
	return [
		JoinNumbers(repeatedAddends),
		"%d + %d" % [firstNumber * firstGroupCount, firstNumber * secondGroupCount],
		str(finalAnswer)
	]

# Generates division steps using the inverse multiplication relationship.
func GenerateDivisionSteps(dividend: int, divisor: int) -> Array[String]:
	if divisor == 0 or dividend % divisor != 0:
		push_error("Step Ordering currently requires exact whole-number division.")
		return []

	var quotient := int(dividend / divisor)
	return [
		"%d * ? = %d" % [divisor, dividend],
		"%d * %d = %d" % [divisor, quotient, dividend],
		str(quotient)
	]

# Generates reduction steps while preserving parser-defined operation order.
func GenerateExpressionReductionSteps(expressionTree: Dictionary, operationCount: int) -> Array[String]:
	var generatedSteps: Array[String] = []
	var remainingOperations := operationCount

	while remainingOperations > 0:
		var nextOperation := FindNextOperation(expressionTree)

		if nextOperation.is_empty():
			return []

		var operationResult := EvaluateOperation(nextOperation)

		# Expand the first operation when only two reductions would be too short.
		if operationCount == 2 and remainingOperations == 2:
			for localExpression in GenerateCompactOperationSteps(nextOperation):
				AppendUniqueStep(
					generatedSteps,
					"= " + FormatExpression(expressionTree, nextOperation["id"], localExpression)
				)
		else:
			AppendUniqueStep(
				generatedSteps,
				"= " + FormatExpression(expressionTree, nextOperation["id"], str(operationResult))
			)

		ReplaceOperationWithNumber(nextOperation, operationResult)
		remainingOperations -= 1

	return generatedSteps

# Produces a short pedagogical expansion before reducing one nested operation.
func GenerateCompactOperationSteps(operationNode: Dictionary) -> Array[String]:
	var leftValue: int = operationNode["left"]["value"]
	var rightValue: int = operationNode["right"]["value"]
	var operation: String = operationNode["operation"]
	var result := EvaluateOperation(operationNode)

	match operation:
		"+":
			if leftValue < 10 and rightValue < 10 and leftValue + rightValue > 10:
				var largerNumber := maxi(leftValue, rightValue)
				var amountToTen := 10 - largerNumber
				return [
					"%d + %d + %d" % [largerNumber, amountToTen, mini(leftValue, rightValue) - amountToTen],
					str(result)
				]
			return ["(%s) + (%s)" % [JoinNumbers(GetPlaceValueParts(leftValue)), JoinNumbers(GetPlaceValueParts(rightValue))], str(result)]
		"-":
			var firstChunk := maxi(int(rightValue / 2), 1)
			return ["%d - %d - %d" % [leftValue, firstChunk, rightValue - firstChunk], str(result)]
		"*":
			if rightValue == 1:
				return ["1 group of %d" % leftValue, str(result)]
			return ["%d * (%d + 1)" % [leftValue, rightValue - 1], str(result)]
		"/":
			var quotient := int(leftValue / rightValue)

			if quotient == 1:
				return ["%d fits into %d once" % [rightValue, leftValue], str(result)]

			var firstQuotientPart := maxi(quotient - 1, 1)
			var firstDividendPart := firstQuotientPart * rightValue
			return ["(%d + %d) / %d" % [firstDividendPart, leftValue - firstDividendPart, rightValue], str(result)]

	return [str(result)]

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
			return int(leftValue / rightValue)

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
		return replacement if parentOperation.is_empty() else "(" + replacement + ")"

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

# Converts local expressions into Step Card display strings.
func FormatLocalSteps(localSteps: Array[String]) -> Array[String]:
	var formattedSteps: Array[String] = []

	for localStep in localSteps:
		AppendUniqueStep(formattedSteps, "= " + localStep)

	return formattedSteps

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

		remainingNumber = int(remainingNumber / 10)
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
