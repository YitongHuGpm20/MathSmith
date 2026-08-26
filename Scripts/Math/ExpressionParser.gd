## Converts MathSmith arithmetic text into a parser-compatible expression tree.
##
## This service owns tokenization, parentheses, left associativity, and standard
## operator precedence. StepGenerator owns all pedagogical step strategies.
extends RefCounted

#region ========== Variables ==========

var tokens: Array[String] = []
var tokenIndex: int = 0
var nextNodeId: int = 0

#endregion

#region ========== Functions ==========

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
	var parserExpression := expression.replace("x", "*").replace("X", "*").replace("×", "*")

	for character in parserExpression:
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

#endregion
