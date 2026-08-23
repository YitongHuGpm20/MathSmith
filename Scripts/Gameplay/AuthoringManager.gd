## Coordinates MathSmith's CSV authoring services behind one stable workflow API.
##
## Parser, Validator, and Exporter remain focused implementations. Teacher UI
## requests authoring operations here instead of depending on their call order.
extends RefCounted

#region ========== References ==========

var csvParser := preload("res://Scripts/Gameplay/CourseCsvParser.gd").new()
var csvValidator := preload("res://Scripts/Gameplay/CourseCsvValidator.gd").new()
var csvExporter := preload("res://Scripts/Gameplay/CourseCsvExporter.gd").new()

#endregion

#region ========== Functions ==========

# Parses and validates one external authoring CSV without persisting it.
func ParseAndValidateCourseCsv(filePath: String) -> Dictionary:
	var parseResult: Dictionary = csvParser.ParseFile(filePath)
	return CreateValidationWorkflowResult(parseResult)

# Converts one Studio snapshot into canonical rows and validates before export.
func BuildAndValidateStudioExport(
	studioContent: Dictionary,
	studioMetadata: Dictionary,
	filename: String
) -> Dictionary:
	var parseResult: Dictionary = csvExporter.BuildParseResult(
		studioContent,
		studioMetadata,
		filename
	)
	return CreateValidationWorkflowResult(parseResult)

# Exposes the shared production-backed expression check to Studio UI.
func ValidateExpression(expression: String) -> Dictionary:
	return csvValidator.ValidateExpressionForAuthoring(expression)

# Writes only a validation-approved parser result to the selected destination.
func ExportValidatedCourseCsv(
	filePath: String,
	parseResult: Dictionary,
	validationReport: Dictionary
) -> Dictionary:
	if not validationReport.get("isValid", false):
		return {"succeeded": false, "filePath": filePath}
	return csvExporter.ExportParseResult(filePath, parseResult)

# Returns one consistent contract for import and Studio export validation UI.
func CreateValidationWorkflowResult(parseResult: Dictionary) -> Dictionary:
	return {
		"parseResult": parseResult,
		"validationReport": csvValidator.ValidateParseResult(parseResult)
	}

#endregion
