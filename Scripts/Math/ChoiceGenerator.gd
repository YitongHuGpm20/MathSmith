## Generates plausible deterministic-answer distractors for choice gameplay.
##
## This math service changes numeric values or operators, filters equivalent
## results with ExpressionParser, and returns a shuffled candidate collection.
extends RefCounted

#region ========== References ==========

var expressionParser := preload("res://Scripts/Math/ExpressionParser.gd").new()

#endregion

#region ========== Functions ==========

# Creates plausible, unique, non-equivalent distractors around one correct Step.
func BuildChoiceOptions(correctStep: String, candidateCount: int) -> Array[String]:
	var choices: Array[String] = [correctStep]
	var correctValue = EvaluateStepText(correctStep)
	var numberPattern := RegEx.new()
	numberPattern.compile("[0-9]+")
	var numberMatches := numberPattern.search_all(correctStep)
	var adjustments: Array[int] = [1, -1, 2, -2, 10, -10]

	# Arithmetic-value changes create believable mistakes without random nonsense.
	for numberMatch in numberMatches:
		var originalNumber := int(numberMatch.get_string())

		for adjustment in adjustments:
			var changedNumber := originalNumber + adjustment

			if changedNumber < 0:
				continue

			var candidate := (
				correctStep.left(numberMatch.get_start())
					+ str(changedNumber)
					+ correctStep.substr(numberMatch.get_end())
			)
			AppendValidDistractor(choices, candidate, correctValue)

			if choices.size() >= candidateCount:
				break

		if choices.size() >= candidateCount:
			break

	# Operator changes provide a fallback for unusually short numeric Steps.
	if choices.size() < candidateCount:
		var operatorChanges := {
			" + ": " - ",
			" - ": " + ",
			" * ": " + ",
			" / ": " * "
		}

		for sourceOperator in operatorChanges:
			if sourceOperator not in correctStep:
				continue

			var candidate := correctStep.replace(sourceOperator, operatorChanges[sourceOperator])
			AppendValidDistractor(choices, candidate, correctValue)

			if choices.size() >= candidateCount:
				break

	choices.shuffle()
	return choices

# Adds one distractor only when it parses and evaluates differently from the answer.
func AppendValidDistractor(choices: Array[String], candidate: String, correctValue: Variant) -> void:
	if candidate in choices:
		return

	var candidateValue = EvaluateStepText(candidate)

	if candidateValue == null or candidateValue == correctValue:
		return

	choices.append(candidate)

# Evaluates one displayed Step for deterministic equivalence filtering.
func EvaluateStepText(stepText: String) -> Variant:
	var expressionText := stepText.trim_prefix("= ")
	var expressionTree := expressionParser.ParseExpression(expressionText)

	if expressionTree.is_empty():
		return null

	var resultData := EvaluateExpressionNode(expressionTree)
	return resultData.get("value") if resultData.get("valid", false) else null

# Evaluates a parser node while rejecting invalid or non-whole-number division.
func EvaluateExpressionNode(expressionNode: Dictionary) -> Dictionary:
	if expressionNode["type"] == "number":
		return {"valid": true, "value": expressionNode["value"]}

	var leftResult := EvaluateExpressionNode(expressionNode["left"])
	var rightResult := EvaluateExpressionNode(expressionNode["right"])

	if not leftResult["valid"] or not rightResult["valid"]:
		return {"valid": false}

	var leftValue: int = leftResult["value"]
	var rightValue: int = rightResult["value"]

	match expressionNode["operation"]:
		"+":
			return {"valid": true, "value": leftValue + rightValue}
		"-":
			return {"valid": true, "value": leftValue - rightValue}
		"*":
			return {"valid": true, "value": leftValue * rightValue}
		"/":
			if rightValue == 0 or leftValue % rightValue != 0:
				return {"valid": false}
			return {"valid": true, "value": floori(float(leftValue) / float(rightValue))}

	return {"valid": false}

#endregion
