## Normalizes teacher-authored arithmetic into MathSmith's display format.
##
## Player-facing multiplication uses x while the parser receives canonical *.
extends RefCounted

#region ========== Functions ==========

# Formats one expression with consistent multiplication and operator spacing.
func FormatForAuthoring(expression: String) -> String:
	var compactExpression := expression.replace("*", "x").replace("X", "x").replace("×", "x")
	compactExpression = compactExpression.replace(" ", "").replace("\t", "")
	compactExpression = compactExpression.replace("\n", "").replace("\r", "")
	var formattedExpression := ""

	# Add one readable space around every supported binary operator.
	for character in compactExpression:
		if character in ["+", "-", "x", "/"]:
			formattedExpression += " %s " % character
		else:
			formattedExpression += character

	return formattedExpression.strip_edges()

# Converts display multiplication into the canonical parser operator.
func ToParserExpression(expression: String) -> String:
	return FormatForAuthoring(expression).replace("x", "*")

#endregion
