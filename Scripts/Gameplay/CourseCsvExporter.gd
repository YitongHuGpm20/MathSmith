## Converts one Studio Course snapshot into MathSmith's authoring CSV schema.
##
## The service builds a parser-compatible in-memory result for shared validation,
## then writes the same ordered COURSE, LEVEL, and QUESTION records to disk.
extends RefCounted

#region ========== References ==========

var csvParser := preload("res://Scripts/Gameplay/CourseCsvParser.gd").new()
var expressionFormatter := preload("res://Scripts/Math/ExpressionFormatter.gd").new()

#endregion

#region ========== Functions ==========

# Builds canonical CSV rows without touching the filesystem.
func BuildParseResult(
	studioContent: Dictionary,
	studioMetadata: Dictionary,
	filename: String
) -> Dictionary:
	var parseResult: Dictionary = csvParser.CreateParseResult(filename)
	parseResult["filename"] = filename.get_file()
	parseResult["headers"] = csvParser.GetExpectedHeaders()
	parseResult["readSucceeded"] = true

	var courseId: String = String(studioMetadata.get("courseId", "studio_course"))
	if courseId.is_empty():
		courseId = "studio_course"
	AppendRow(parseResult, PackedStringArray([
		"COURSE",
		courseId,
		String(studioMetadata.get("courseName", "Untitled Studio Course")),
		String(studioMetadata.get("courseDescription", "")),
		"", "", "", "", "", ""
	]))

	# Keep every Level definition together before the Question section.
	for levelValue in studioContent.get("levels", []):
		var levelData: Dictionary = levelValue
		var skillTags: Array[String] = []
		for skillValue in levelData.get("skills", []):
			skillTags.append(String(skillValue))
		AppendRow(parseResult, PackedStringArray([
			"", "", "", "",
			String(levelData.get("id", "")),
			String(levelData.get("title", "")),
			String(levelData.get("levelTypeId", "")),
			";".join(PackedStringArray(skillTags)),
			"", ""
		]), "LEVEL")

	# Preserve Level order and authored Question order within each Level.
	for levelValue in studioContent.get("levels", []):
		var levelData: Dictionary = levelValue
		for questionValue in levelData.get("questions", []):
			var questionData: Dictionary = questionValue
			AppendRow(parseResult, PackedStringArray([
				"", "", "", "",
				String(levelData.get("id", "")),
				"", "", "",
				String(questionData.get("id", "")),
				expressionFormatter.FormatForAuthoring(
					String(questionData.get("expression", ""))
				)
			]), "QUESTION")

	parseResult["content"] = csvParser.BuildRuntimeContent(parseResult)
	parseResult["metadata"] = csvParser.BuildCourseMetadata(parseResult)
	return parseResult

# Writes one already-built and validated result using Godot's CSV escaping.
func ExportParseResult(filePath: String, parseResult: Dictionary) -> Dictionary:
	var normalizedPath: String = filePath
	if normalizedPath.get_extension().to_lower() != "csv":
		normalizedPath += ".csv"
	var csvFile := FileAccess.open(normalizedPath, FileAccess.WRITE)
	if csvFile == null:
		return {"succeeded": false, "filePath": normalizedPath}

	csvFile.store_csv_line(parseResult.get("headers", PackedStringArray()))
	for parsedRowValue in parseResult.get("rows", []):
		var parsedRow: Dictionary = parsedRowValue
		var fields: Dictionary = parsedRow.get("fields", {})
		var csvValues := PackedStringArray()
		for headerName in parseResult.get("headers", PackedStringArray()):
			csvValues.append(String(fields.get(headerName, "")))
		csvFile.store_csv_line(csvValues)
	csvFile.close()
	return {"succeeded": true, "filePath": normalizedPath}

# Adds one ten-column row to all parser collections with a stable row number.
func AppendRow(
	parseResult: Dictionary,
	csvValues: PackedStringArray,
	recordTypeOverride: String = ""
) -> void:
	if not recordTypeOverride.is_empty():
		csvValues[0] = recordTypeOverride
	var rowNumber: int = parseResult["rows"].size() + 2
	var parsedRow: Dictionary = csvParser.CreateParsedRow(
		parseResult["headers"],
		csvValues,
		rowNumber
	)
	parseResult["rows"].append(parsedRow)
	csvParser.CategorizeRecord(parseResult, parsedRow)

#endregion
