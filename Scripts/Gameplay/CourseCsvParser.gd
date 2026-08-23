## Parses MathSmith's author-facing CSV records into normalized Course data.
##
## This service owns CSV file reading, row mapping, and runtime-shape assembly.
## It intentionally does not validate IDs, expressions, pedagogy, or import safety.
extends RefCounted

#region ========== Constants ==========

const CSV_SCHEMA_VERSION: int = 1
const COURSE_RECORD_TYPE: String = "COURSE"
const LEVEL_RECORD_TYPE: String = "LEVEL"
const QUESTION_RECORD_TYPE: String = "QUESTION"

const EXPECTED_HEADERS: PackedStringArray = [
	"record_type",
	"course_id",
	"course_name",
	"course_description",
	"level_id",
	"level_name",
	"level_type",
	"skill_tags",
	"question_id",
	"expression"
]

const LEVEL_TYPE_DEFINITIONS: Dictionary = {
	"step_ordering": {
		"title": "Step Ordering",
		"rule": "Arrange the solution steps in the correct order."
	},
	"multiple_choice_ordering": {
		"title": "Multiple-Choice Ordering",
		"rule": "Choose the correct solution steps and arrange them in the correct order."
	},
	"fill_in_process": {
		"title": "Fill in the Process",
		"rule": "Complete the missing values in the solution process."
	}
}

#endregion

#region ========== Functions ==========

# Reads one UTF-8 CSV file and returns records plus best-effort runtime Course data.
func ParseFile(filePath: String) -> Dictionary:
	var parseResult := CreateParseResult(filePath)
	var csvFile := FileAccess.open(filePath, FileAccess.READ)

	if csvFile == null:
		parseResult["errorMessage"] = "Unable to open CSV file."
		return parseResult

	# Read the author-defined header separately so every later row keeps its file line.
	if csvFile.eof_reached():
		csvFile.close()
		parseResult["errorMessage"] = "CSV file is empty."
		return parseResult

	var headers: PackedStringArray = csvFile.get_csv_line()
	if not headers.is_empty():
		headers[0] = headers[0].trim_prefix(String.chr(0xFEFF)).strip_edges()
	for headerIndex in range(1, headers.size()):
		headers[headerIndex] = headers[headerIndex].strip_edges()
	parseResult["headers"] = headers

	var fileRowNumber: int = 1
	while not csvFile.eof_reached():
		fileRowNumber += 1
		var csvValues: PackedStringArray = csvFile.get_csv_line()
		if IsEmptyCsvRow(csvValues):
			continue

		var parsedRow := CreateParsedRow(headers, csvValues, fileRowNumber)
		parseResult["rows"].append(parsedRow)
		CategorizeRecord(parseResult, parsedRow)

	csvFile.close()
	parseResult["readSucceeded"] = true
	parseResult["content"] = BuildRuntimeContent(parseResult)
	parseResult["metadata"] = BuildCourseMetadata(parseResult)
	return parseResult

# Creates a stable parse-result shape for both successful reads and file failures.
func CreateParseResult(filePath: String) -> Dictionary:
	return {
		"csvSchemaVersion": CSV_SCHEMA_VERSION,
		"filePath": filePath,
		"filename": filePath.get_file(),
		"readSucceeded": false,
		"errorMessage": "",
		"headers": PackedStringArray(),
		"rows": [],
		"courseRecords": [],
		"levelRecords": [],
		"questionRecords": [],
		"unknownRecords": [],
		"content": {},
		"metadata": {}
	}

# Maps one physical CSV row without silently discarding extra or missing columns.
func CreateParsedRow(
	headers: PackedStringArray,
	csvValues: PackedStringArray,
	fileRowNumber: int
) -> Dictionary:
	var fields: Dictionary = {}
	for headerIndex in range(headers.size()):
		var headerName: String = headers[headerIndex]
		if headerName.is_empty():
			continue
		fields[headerName] = (
			csvValues[headerIndex].strip_edges()
			if headerIndex < csvValues.size()
			else ""
		)

	return {
		"rowNumber": fileRowNumber,
		"columnCount": csvValues.size(),
		"recordType": String(fields.get("record_type", "")),
		"fields": fields
	}

# Places recognized records into ordered collections while retaining unknown rows.
func CategorizeRecord(parseResult: Dictionary, parsedRow: Dictionary) -> void:
	match parsedRow.get("recordType", ""):
		COURSE_RECORD_TYPE:
			parseResult["courseRecords"].append(parsedRow)
		LEVEL_RECORD_TYPE:
			parseResult["levelRecords"].append(parsedRow)
		QUESTION_RECORD_TYPE:
			parseResult["questionRecords"].append(parsedRow)
		_:
			parseResult["unknownRecords"].append(parsedRow)

# Builds existing gameplay content shape without deciding whether it is valid to import.
func BuildRuntimeContent(parseResult: Dictionary) -> Dictionary:
	var runtimeLevels: Array = []
	var runtimeLevelIndexes: Dictionary = {}

	# Preserve authored LEVEL record order as runtime Level order.
	for levelRecordValue in parseResult.get("levelRecords", []):
		var levelRecord: Dictionary = levelRecordValue
		var fields: Dictionary = levelRecord.get("fields", {})
		var levelId: String = fields.get("level_id", "")
		var levelData := {
			"id": levelId,
			"title": fields.get("level_name", ""),
			"levelTypeId": fields.get("level_type", ""),
			"skills": ParseSkillTags(fields.get("skill_tags", "")),
			"questions": []
		}
		runtimeLevels.append(levelData)
		if not runtimeLevelIndexes.has(levelId):
			runtimeLevelIndexes[levelId] = runtimeLevels.size() - 1

	# Attach Questions through explicit level_id references, independent of row grouping.
	for questionRecordValue in parseResult.get("questionRecords", []):
		var questionRecord: Dictionary = questionRecordValue
		var fields: Dictionary = questionRecord.get("fields", {})
		var parentLevelId: String = fields.get("level_id", "")
		if not runtimeLevelIndexes.has(parentLevelId):
			continue

		var levelIndex: int = runtimeLevelIndexes[parentLevelId]
		runtimeLevels[levelIndex]["questions"].append({
			"id": fields.get("question_id", ""),
			"expression": fields.get("expression", "")
		})

	return {
		"level_types": LEVEL_TYPE_DEFINITIONS.duplicate(true),
		"levels": runtimeLevels
	}

# Extracts lightweight Course metadata without requiring a valid single COURSE row.
func BuildCourseMetadata(parseResult: Dictionary) -> Dictionary:
	var metadata := {
		"csvSchemaVersion": CSV_SCHEMA_VERSION,
		"originalFilename": parseResult.get("filename", ""),
		"courseId": "",
		"courseName": "",
		"courseDescription": "",
		"levelCount": parseResult.get("levelRecords", []).size(),
		"questionCount": parseResult.get("questionRecords", []).size()
	}

	var courseRecords: Array = parseResult.get("courseRecords", [])
	if courseRecords.is_empty():
		return metadata

	var fields: Dictionary = courseRecords[0].get("fields", {})
	metadata["courseId"] = fields.get("course_id", "")
	metadata["courseName"] = fields.get("course_name", "")
	metadata["courseDescription"] = fields.get("course_description", "")
	return metadata

# Splits Level-owned semicolon tags while ignoring accidental empty segments.
func ParseSkillTags(skillText: String) -> Array[String]:
	var skillTags: Array[String] = []
	for skillTag in skillText.split(";", false):
		var normalizedSkill := skillTag.strip_edges()
		if not normalizedSkill.is_empty():
			skillTags.append(normalizedSkill)
	return skillTags

# Identifies blank spreadsheet rows without assigning them authoring meaning.
func IsEmptyCsvRow(csvValues: PackedStringArray) -> bool:
	for csvValue in csvValues:
		if not csvValue.strip_edges().is_empty():
			return false
	return true

# Returns the canonical header contract for authoring UI and validation.
func GetExpectedHeaders() -> PackedStringArray:
	return EXPECTED_HEADERS.duplicate()

#endregion
