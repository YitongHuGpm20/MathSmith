extends Node


func GenerateAdditionSteps(expression: String) -> Array[String]:
	var parts := expression.split("+")

	if parts.size() != 2:
		push_error("Invalid addition expression: " + expression)
		return []

	var firstNumber := int(parts[0].strip_edges())
	var secondNumber := int(parts[1].strip_edges())

	var firstTens := (firstNumber / 10) * 10
	var firstOnes := firstNumber % 10

	var secondTens := (secondNumber / 10) * 10
	var secondOnes := secondNumber % 10

	var tensTotal := firstTens + secondTens
	var onesTotal := firstOnes + secondOnes
	var finalAnswer := firstNumber + secondNumber

	var steps: Array[String] = [
		"%d + %d" % [firstNumber, secondNumber],
		"(%d + %d) + (%d + %d)" % [
			firstTens,
			firstOnes,
			secondTens,
			secondOnes
		],
		"(%d + %d) + (%d + %d)" % [
			firstTens,
			secondTens,
			firstOnes,
			secondOnes
		],
		"%d + %d" % [tensTotal, onesTotal],
		str(finalAnswer)
	]

	return steps
