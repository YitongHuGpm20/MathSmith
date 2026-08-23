## Validates parsed MathSmith CSV records before any Course content is replaced.
##
## This service owns deterministic authoring Errors, Warnings, and row statuses.
## It reuses the production ExpressionParser and StepGenerator for math checks.
extends RefCounted

#region ========== Constants ==========

const ERROR_SEVERITY: String = "Error"
const WARNING_SEVERITY: String = "Warning"
const VALID_SEVERITY: String = "Valid"
const EXPECTED_COLUMN_COUNT: int = 10
const LONG_SOLUTION_STEP_COUNT: int = 8
const HIGH_QUESTION_COUNT: int = 100
const HIGH_SKILL_TAG_COUNT: int = 5
const COURSE_ID_PATTERN: String = "^[a-z0-9]+(?:_[a-z0-9]+)*$"
const LEVEL_ID_PATTERN: String = "^[a-z0-9]+(?:_[a-z0-9]+)*$"
const QUESTION_ID_PATTERN: String = "^[A-Za-z0-9]+(?:_[A-Za-z0-9]+)*$"
const SKILL_ID_PATTERN: String = "^[a-z0-9]+(?:_[a-z0-9]+)*$"
const EXPRESSION_CHARACTER_PATTERN: String = "^[0-9+\\-*/() ]+$"

const VALID_LEVEL_TYPES: Array[String] = [
	"step_ordering",
	"multiple_choice_ordering",
	"fill_in_process"
]

const RECORD_FIELDS: Dictionary = {
	"COURSE": ["course_id", "course_name"],
	"LEVEL": ["level_id", "level_name", "level_type", "skill_tags"],
	"QUESTION": ["level_id", "question_id", "expression"]
}

const ALLOWED_RECORD_FIELDS: Dictionary = {
	"COURSE": ["record_type", "course_id", "course_name", "course_description"],
	"LEVEL": ["record_type", "level_id", "level_name", "level_type", "skill_tags"],
	"QUESTION": ["record_type", "level_id", "question_id", "expression"]
}

#endregion

#region ========== References ==========

var expressionParser := preload("res://Scripts/Math/ExpressionParser.gd").new()
var stepGenerator := preload("res://Scripts/Math/StepGenerator.gd").new()
var csvParser := preload("res://Scripts/Gameplay/CourseCsvParser.gd").new()

#endregion

#region ========== Functions ==========

# Validates a parser result and returns a complete deterministic authoring report.
func ValidateParseResult(parseResult: Dictionary) -> Dictionary:
	var report := CreateValidationReport(parseResult)

	if not parseResult.get("readSucceeded", false):
		AddIssue(
			report,
			0,
			"",
			"",
			"",
			"file",
			ERROR_SEVERITY,
			parseResult.get("errorMessage", "Unable to read CSV file."),
			"Choose an accessible UTF-8 CSV file and try again."
		)
		return FinalizeReport(report, parseResult)

	ValidateHeaders(parseResult, report)
	ValidatePhysicalRows(parseResult, report)
	ValidateRecordStructure(parseResult, report)
	ValidateCourseRecords(parseResult, report)
	ValidateLevelRecords(parseResult, report)
	ValidateQuestionRecords(parseResult, report)
	ValidateCourseComposition(parseResult, report)
	return FinalizeReport(report, parseResult)

# Creates the stable report contract consumed by the later Validation Results UI.
func CreateValidationReport(parseResult: Dictionary) -> Dictionary:
	return {
		"filename": parseResult.get("filename", ""),
		"isValid": false,
		"status": ERROR_SEVERITY,
		"errorCount": 0,
		"warningCount": 0,
		"validCount": 0,
		"issues": [],
		"rowResults": []
	}

# Requires the documented headers in their canonical authoring order.
func ValidateHeaders(parseResult: Dictionary, report: Dictionary) -> void:
	var actualHeaders: PackedStringArray = parseResult.get("headers", PackedStringArray())
	var expectedHeaders: PackedStringArray = csvParser.GetExpectedHeaders()

	if actualHeaders == expectedHeaders:
		return

	AddIssue(
		report,
		1,
		"",
		"",
		"",
		"header",
		ERROR_SEVERITY,
		"CSV headers do not match the MathSmith authoring schema.",
		"Restore the exact header row from MathSmith_Course_Template.csv."
	)

# Reports spreadsheet rows whose physical column count differs from the schema.
func ValidatePhysicalRows(parseResult: Dictionary, report: Dictionary) -> void:
	for parsedRowValue in parseResult.get("rows", []):
		var parsedRow: Dictionary = parsedRowValue
		if int(parsedRow.get("columnCount", 0)) == EXPECTED_COLUMN_COUNT:
			continue

		AddRowIssue(
			report,
			parsedRow,
			"row",
			ERROR_SEVERITY,
			"Row contains %d columns instead of %d."
			% [int(parsedRow.get("columnCount", 0)), EXPECTED_COLUMN_COUNT],
			"Check commas and CSV quotation marks on this row."
		)

# Ensures every row uses one known record type and only its intended fields.
func ValidateRecordStructure(parseResult: Dictionary, report: Dictionary) -> void:
	for parsedRowValue in parseResult.get("rows", []):
		var parsedRow: Dictionary = parsedRowValue
		var recordType: String = parsedRow.get("recordType", "")
		var fields: Dictionary = parsedRow.get("fields", {})

		if not RECORD_FIELDS.has(recordType):
			AddRowIssue(
				report,
				parsedRow,
				"record_type",
				ERROR_SEVERITY,
				"Unknown Record Type '%s'." % recordType,
				"Use COURSE, LEVEL, or QUESTION exactly as written."
			)
			continue

		for requiredField in RECORD_FIELDS[recordType]:
			if String(fields.get(requiredField, "")).is_empty():
				AddRowIssue(
					report,
					parsedRow,
					requiredField,
					ERROR_SEVERITY,
					"Required field '%s' is empty." % requiredField,
					"Enter a value in the '%s' column." % requiredField
				)

		# Reject misplaced data so separated Course, Level, and Question sections stay clear.
		for fieldName in fields:
			if (
				fieldName not in ALLOWED_RECORD_FIELDS[recordType]
				and not String(fields.get(fieldName, "")).is_empty()
			):
				AddRowIssue(
					report,
					parsedRow,
					fieldName,
					ERROR_SEVERITY,
					"Field '%s' does not belong on a %s record." % [fieldName, recordType],
					"Move this value to the appropriate record section or clear the cell."
				)

# Requires exactly one first-row COURSE record and validates its authoring ID.
func ValidateCourseRecords(parseResult: Dictionary, report: Dictionary) -> void:
	var courseRecords: Array = parseResult.get("courseRecords", [])
	if courseRecords.size() != 1:
		AddIssue(
			report,
			0,
			"COURSE",
			"",
			"",
			"record_type",
			ERROR_SEVERITY,
			"CSV must contain exactly one COURSE record.",
			"Keep one COURSE row at the beginning of the file."
		)
		if courseRecords.is_empty():
			return

	var courseRecord: Dictionary = courseRecords[0]
	var fields: Dictionary = courseRecord.get("fields", {})
	if int(courseRecord.get("rowNumber", 0)) != 2:
		AddRowIssue(
			report,
			courseRecord,
			"record_type",
			ERROR_SEVERITY,
			"COURSE must be the first content record.",
			"Move the COURSE record directly below the header."
		)

	if not MatchesPattern(fields.get("course_id", ""), COURSE_ID_PATTERN):
		AddRowIssue(
			report,
			courseRecord,
			"course_id",
			ERROR_SEVERITY,
			"Course ID must use lowercase snake_case.",
			"Use lowercase letters, numbers, and single underscores."
		)

	if String(fields.get("course_description", "")).is_empty():
		AddRowIssue(
			report,
			courseRecord,
			"course_description",
			WARNING_SEVERITY,
			"Optional Course description is empty.",
			"Add a short player-facing summary if one is available."
		)

# Validates unique Levels, supported modes, Skill formatting, and row order.
func ValidateLevelRecords(parseResult: Dictionary, report: Dictionary) -> void:
	var seenLevelIds: Dictionary = {}
	var firstQuestionRow: int = GetFirstRecordRow(parseResult.get("questionRecords", []))

	for levelRecordValue in parseResult.get("levelRecords", []):
		var levelRecord: Dictionary = levelRecordValue
		var fields: Dictionary = levelRecord.get("fields", {})
		var levelId: String = fields.get("level_id", "")

		if firstQuestionRow > 0 and int(levelRecord.get("rowNumber", 0)) > firstQuestionRow:
			AddRowIssue(
				report,
				levelRecord,
				"record_type",
				ERROR_SEVERITY,
				"LEVEL records must appear before QUESTION records.",
				"Move this Level definition into the LEVEL section."
			)

		if seenLevelIds.has(levelId):
			AddRowIssue(
				report,
				levelRecord,
				"level_id",
				ERROR_SEVERITY,
				"Duplicate Level ID '%s'." % levelId,
				"Give every Level a unique stable ID."
			)
		else:
			seenLevelIds[levelId] = levelRecord.get("rowNumber", 0)

		if not MatchesPattern(levelId, LEVEL_ID_PATTERN):
			AddRowIssue(
				report,
				levelRecord,
				"level_id",
				ERROR_SEVERITY,
				"Level ID must use lowercase snake_case.",
				"Use lowercase letters, numbers, and single underscores."
			)

		var levelType: String = fields.get("level_type", "")
		if not levelType in VALID_LEVEL_TYPES:
			AddRowIssue(
				report,
				levelRecord,
				"level_type",
				ERROR_SEVERITY,
				"Invalid Level Type '%s'." % levelType,
				"Use step_ordering, multiple_choice_ordering, or fill_in_process."
			)

		ValidateSkillTags(levelRecord, report)

# Validates every Question reference, ID, expression, and generated solution.
func ValidateQuestionRecords(parseResult: Dictionary, report: Dictionary) -> void:
	var levelRowsById: Dictionary = {}
	var seenQuestionIds: Dictionary = {}
	for levelRecordValue in parseResult.get("levelRecords", []):
		var levelRecord: Dictionary = levelRecordValue
		var levelFields: Dictionary = levelRecord.get("fields", {})
		var levelId: String = levelFields.get("level_id", "")
		if not levelRowsById.has(levelId):
			levelRowsById[levelId] = int(levelRecord.get("rowNumber", 0))

	for questionRecordValue in parseResult.get("questionRecords", []):
		var questionRecord: Dictionary = questionRecordValue
		var fields: Dictionary = questionRecord.get("fields", {})
		var levelId: String = fields.get("level_id", "")
		var questionId: String = fields.get("question_id", "")

		if not levelRowsById.has(levelId):
			AddRowIssue(
				report,
				questionRecord,
				"level_id",
				ERROR_SEVERITY,
				"Question references undefined Level '%s'." % levelId,
				"Create the Level first or correct this level_id."
			)
		elif int(levelRowsById[levelId]) > int(questionRecord.get("rowNumber", 0)):
			AddRowIssue(
				report,
				questionRecord,
				"level_id",
				ERROR_SEVERITY,
				"Question references a Level defined later in the file.",
				"Move all LEVEL records above the QUESTION section."
			)

		if seenQuestionIds.has(questionId):
			AddRowIssue(
				report,
				questionRecord,
				"question_id",
				ERROR_SEVERITY,
				"Duplicate Question ID '%s'." % questionId,
				"Give every Question a unique stable ID."
			)
		else:
			seenQuestionIds[questionId] = true

		if not MatchesPattern(questionId, QUESTION_ID_PATTERN):
			AddRowIssue(
				report,
				questionRecord,
				"question_id",
				ERROR_SEVERITY,
				"Question ID contains unsupported characters.",
				"Use letters, numbers, and single underscores without spaces."
			)

		ValidateQuestionExpression(questionRecord, report)

# Checks Skill syntax, duplicates, and unusually broad Level configurations.
func ValidateSkillTags(levelRecord: Dictionary, report: Dictionary) -> void:
	var fields: Dictionary = levelRecord.get("fields", {})
	var rawSkillText: String = fields.get("skill_tags", "")
	var skillTags: Array[String] = csvParser.ParseSkillTags(rawSkillText)
	var seenSkills: Dictionary = {}

	for skillTag in skillTags:
		if not MatchesPattern(skillTag, SKILL_ID_PATTERN):
			AddRowIssue(
				report,
				levelRecord,
				"skill_tags",
				ERROR_SEVERITY,
				"Skill Tag '%s' must use lowercase snake_case." % skillTag,
				"Use semicolon-separated lowercase Skill IDs."
			)
		if seenSkills.has(skillTag):
			AddRowIssue(
				report,
				levelRecord,
				"skill_tags",
				ERROR_SEVERITY,
				"Skill Tag '%s' is duplicated." % skillTag,
				"List each Skill once per Level."
			)
		seenSkills[skillTag] = true

	if skillTags.size() > HIGH_SKILL_TAG_COUNT:
		AddRowIssue(
			report,
			levelRecord,
			"skill_tags",
			WARNING_SEVERITY,
			"Level uses an unusually large number of Skill Tags.",
			"Review whether every listed Skill is directly practiced."
		)

# Uses production math systems only after lightweight syntax and arithmetic checks.
func ValidateQuestionExpression(questionRecord: Dictionary, report: Dictionary) -> void:
	var fields: Dictionary = questionRecord.get("fields", {})
	var expression: String = fields.get("expression", "")
	if expression.is_empty():
		return
	var validationResult := ValidateExpressionForAuthoring(expression)
	if validationResult.get("severity", VALID_SEVERITY) == VALID_SEVERITY:
		return
	AddRowIssue(
		report,
		questionRecord,
		"expression",
		validationResult.get("severity", ERROR_SEVERITY),
		validationResult.get("message", "Expression cannot be validated."),
		validationResult.get("suggestedAction", "Revise the mathematical expression.")
	)

# Returns deterministic live authoring feedback using the production math pipeline.
func ValidateExpressionForAuthoring(expression: String) -> Dictionary:
	var normalizedExpression := expression.strip_edges()
	if normalizedExpression.is_empty():
		return CreateExpressionValidationResult(
			false,
			ERROR_SEVERITY,
			"Expression is required.",
			"Enter a supported arithmetic expression."
		)
	if not MatchesPattern(normalizedExpression, EXPRESSION_CHARACTER_PATTERN):
		return CreateExpressionValidationResult(
			false,
			ERROR_SEVERITY,
			"Expression contains unsupported syntax.",
			"Use whole numbers, spaces, +, -, *, /, and parentheses only."
		)

	var expressionTree: Dictionary = expressionParser.ParseExpression(normalizedExpression)
	if expressionTree.is_empty():
		return CreateExpressionValidationResult(
			false,
			ERROR_SEVERITY,
			"ExpressionParser could not parse this expression.",
			"Check operator order, numbers, and matching parentheses."
		)

	var arithmeticCheck := ValidateIntegerArithmetic(expressionTree)
	if not arithmeticCheck.get("valid", false):
		return CreateExpressionValidationResult(
			false,
			ERROR_SEVERITY,
			arithmeticCheck.get("message", "Expression cannot be evaluated safely."),
			arithmeticCheck.get("suggestedAction", "Revise the mathematical expression.")
		)

	var generatedSteps: Array[String] = stepGenerator.GenerateSteps(normalizedExpression)
	if generatedSteps.is_empty():
		return CreateExpressionValidationResult(
			false,
			ERROR_SEVERITY,
			"StepGenerator could not create a usable solution.",
			"Use a supported expression containing at least one operation."
		)
	if generatedSteps.size() > LONG_SOLUTION_STEP_COUNT:
		return CreateExpressionValidationResult(
			true,
			WARNING_SEVERITY,
			"Generated solution is unusually long (%d steps)." % generatedSteps.size(),
			"Preview the Question and review its readability.",
			generatedSteps
		)
	return CreateExpressionValidationResult(
		true,
		VALID_SEVERITY,
		"Expression is valid and generates %d solution steps." % generatedSteps.size(),
		"",
		generatedSteps
	)

# Builds one reusable live-validation response for Studio and later previews.
func CreateExpressionValidationResult(
	valid: bool,
	severity: String,
	message: String,
	suggestedAction: String,
	generatedSteps: Array[String] = []
) -> Dictionary:
	return {
		"valid": valid,
		"severity": severity,
		"message": message,
		"suggestedAction": suggestedAction,
		"generatedSteps": generatedSteps.duplicate(),
		"stepCount": generatedSteps.size()
	}

# Recursively rejects division by zero and decimal intermediate results.
func ValidateIntegerArithmetic(expressionNode: Dictionary) -> Dictionary:
	if expressionNode.get("type", "") == "number":
		return {"valid": true, "value": int(expressionNode.get("value", 0))}

	var leftResult := ValidateIntegerArithmetic(expressionNode.get("left", {}))
	if not leftResult.get("valid", false):
		return leftResult
	var rightResult := ValidateIntegerArithmetic(expressionNode.get("right", {}))
	if not rightResult.get("valid", false):
		return rightResult

	var leftValue: int = leftResult.get("value", 0)
	var rightValue: int = rightResult.get("value", 0)
	match expressionNode.get("operation", ""):
		"+":
			return {"valid": true, "value": leftValue + rightValue}
		"-":
			return {"valid": true, "value": leftValue - rightValue}
		"*":
			return {"valid": true, "value": leftValue * rightValue}
		"/":
			if rightValue == 0:
				return {
					"valid": false,
					"message": "Expression divides by zero.",
					"suggestedAction": "Change the divisor so it cannot evaluate to zero."
				}
			if leftValue % rightValue != 0:
				return {
					"valid": false,
					"message": "Division creates a decimal intermediate result.",
					"suggestedAction": "Use values that divide evenly into whole numbers."
				}
			return {"valid": true, "value": int(float(leftValue) / float(rightValue))}

	return {
		"valid": false,
		"message": "Expression contains an unsupported operation.",
		"suggestedAction": "Use +, -, *, or / only."
	}

# Requires playable Level and Question collections and warns on unusually large files.
func ValidateCourseComposition(parseResult: Dictionary, report: Dictionary) -> void:
	var levelRecords: Array = parseResult.get("levelRecords", [])
	var questionRecords: Array = parseResult.get("questionRecords", [])
	if levelRecords.is_empty():
		AddIssue(report, 0, "LEVEL", "", "", "level_id", ERROR_SEVERITY, "Course has no Levels.", "Add at least one LEVEL record.")
	if questionRecords.is_empty():
		AddIssue(report, 0, "QUESTION", "", "", "question_id", ERROR_SEVERITY, "Course has no Questions.", "Add at least one QUESTION record.")

	var questionCountsByLevel: Dictionary = {}
	for questionRecordValue in questionRecords:
		var fields: Dictionary = questionRecordValue.get("fields", {})
		var levelId: String = fields.get("level_id", "")
		questionCountsByLevel[levelId] = int(questionCountsByLevel.get(levelId, 0)) + 1
	for levelRecordValue in levelRecords:
		var levelRecord: Dictionary = levelRecordValue
		var fields: Dictionary = levelRecord.get("fields", {})
		var levelId: String = fields.get("level_id", "")
		if int(questionCountsByLevel.get(levelId, 0)) == 0:
			AddRowIssue(report, levelRecord, "level_id", ERROR_SEVERITY, "Level contains no Questions.", "Add at least one QUESTION referencing this level_id.")

	if questionRecords.size() > HIGH_QUESTION_COUNT:
		AddIssue(
			report,
			0,
			"COURSE",
			"",
			"",
			"question_id",
			WARNING_SEVERITY,
			"Course contains an unusually high Question count (%d)." % questionRecords.size(),
			"Review Course size and authoring performance before import."
		)

# Creates row-level status summaries after all cross-record checks have completed.
func FinalizeReport(report: Dictionary, parseResult: Dictionary) -> Dictionary:
	report["errorCount"] = CountIssues(report.get("issues", []), ERROR_SEVERITY)
	report["warningCount"] = CountIssues(report.get("issues", []), WARNING_SEVERITY)
	report["isValid"] = report["errorCount"] == 0
	report["status"] = (
		ERROR_SEVERITY
		if report["errorCount"] > 0
		else WARNING_SEVERITY if report["warningCount"] > 0 else VALID_SEVERITY
	)

	for parsedRowValue in parseResult.get("rows", []):
		var parsedRow: Dictionary = parsedRowValue
		var rowNumber: int = int(parsedRow.get("rowNumber", 0))
		var rowStatus := GetRowStatus(report.get("issues", []), rowNumber)
		report["rowResults"].append({
			"rowNumber": rowNumber,
			"recordType": parsedRow.get("recordType", ""),
			"status": rowStatus
		})
		if rowStatus == VALID_SEVERITY:
			report["validCount"] += 1
	return report

# Appends one structured issue for later filtering and author-facing display.
func AddIssue(
	report: Dictionary,
	rowNumber: int,
	recordType: String,
	levelId: String,
	questionId: String,
	fieldName: String,
	severity: String,
	message: String,
	suggestedAction: String
) -> void:
	report["issues"].append({
		"rowNumber": rowNumber,
		"recordType": recordType,
		"levelId": levelId,
		"questionId": questionId,
		"field": fieldName,
		"severity": severity,
		"message": message,
		"suggestedAction": suggestedAction
	})

# Adds an issue using identifying context already parsed from one physical row.
func AddRowIssue(
	report: Dictionary,
	parsedRow: Dictionary,
	fieldName: String,
	severity: String,
	message: String,
	suggestedAction: String
) -> void:
	var fields: Dictionary = parsedRow.get("fields", {})
	AddIssue(
		report,
		int(parsedRow.get("rowNumber", 0)),
		parsedRow.get("recordType", ""),
		fields.get("level_id", ""),
		fields.get("question_id", ""),
		fieldName,
		severity,
		message,
		suggestedAction
	)

# Returns the first physical row used by one ordered record collection.
func GetFirstRecordRow(records: Array) -> int:
	if records.is_empty():
		return 0
	return int(records[0].get("rowNumber", 0))

# Compiles and applies one centralized authoring text pattern.
func MatchesPattern(value: String, pattern: String) -> bool:
	var regularExpression := RegEx.new()
	return regularExpression.compile(pattern) == OK and regularExpression.search(value) != null

# Counts issues by one deterministic severity.
func CountIssues(issues: Array, severity: String) -> int:
	var issueCount: int = 0
	for issueValue in issues:
		if issueValue.get("severity", "") == severity:
			issueCount += 1
	return issueCount

# Derives one row's strongest status using Error before Warning before Valid.
func GetRowStatus(issues: Array, rowNumber: int) -> String:
	var rowStatus: String = VALID_SEVERITY
	for issueValue in issues:
		if int(issueValue.get("rowNumber", 0)) != rowNumber:
			continue
		if issueValue.get("severity", "") == ERROR_SEVERITY:
			return ERROR_SEVERITY
		if issueValue.get("severity", "") == WARNING_SEVERITY:
			rowStatus = WARNING_SEVERITY
	return rowStatus

#endregion
