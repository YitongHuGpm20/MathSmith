## Loads and validates MathSmith's shared Level Type and Level content.
##
## This data service owns file access and content Schema validation. It returns
## validated data to GameManager but does not own gameplay or session state.
extends RefCounted

#region ========== Constants ==========

const LEVEL_DATA_PATH: String = "res://Data/SampleLevels.json"
const EXPECTED_LEVEL_COUNT: int = 12
const EXPECTED_QUESTION_COUNTS: Array[int] = [5, 5, 6, 6, 7, 7, 8, 8, 9, 9, 10, 10]
const REQUIRED_LEVEL_TYPE_IDS: Array[String] = [
	"step_ordering",
	"multiple_choice_ordering",
	"fill_in_process"
]

#endregion

#region ========== Functions ==========

# Loads and validates the complete content file as one atomic operation.
func LoadContentData() -> Dictionary:
	var levelFile := FileAccess.open(LEVEL_DATA_PATH, FileAccess.READ)

	# Reject missing or inaccessible data files.
	if levelFile == null:
		push_error("Failed to open level data: " + LEVEL_DATA_PATH)
		return {}

	var jsonText := levelFile.get_as_text()
	levelFile.close()

	# Parse the JSON text into Godot data structures.
	var json := JSON.new()
	var parseError := json.parse(jsonText)

	if parseError != OK:
		push_error(
			"Failed to parse level JSON at line %d: %s"
			% [json.get_error_line(), json.get_error_message()]
		)
		return {}

	var contentData: Variant = json.data

	if not ValidateContentRoot(contentData):
		return {}

	if not ValidateLevelTypes(contentData["level_types"]):
		return {}

	if not ValidateLevels(contentData["levels"]):
		return {}

	return contentData

# Validates the required top-level content collections.
func ValidateContentRoot(contentData: Variant) -> bool:
	if typeof(contentData) != TYPE_DICTIONARY:
		push_error("Content JSON root must be a Dictionary.")
		return false

	if not contentData.has("level_types") or typeof(contentData["level_types"]) != TYPE_DICTIONARY:
		push_error("Content JSON must contain a 'level_types' Dictionary.")
		return false

	if not contentData.has("levels") or typeof(contentData["levels"]) != TYPE_ARRAY:
		push_error("Content JSON must contain a 'levels' Array.")
		return false

	return true

# Validates the three interaction definitions shared by all mathematical Levels.
func ValidateLevelTypes(levelTypeData: Dictionary) -> bool:
	if levelTypeData.size() != REQUIRED_LEVEL_TYPE_IDS.size():
		push_error("Content JSON must define exactly three Level Types.")
		return false

	# Require each known Level Type to contain only its display title and rule.
	for levelTypeId in REQUIRED_LEVEL_TYPE_IDS:
		if not levelTypeData.has(levelTypeId) or typeof(levelTypeData[levelTypeId]) != TYPE_DICTIONARY:
			push_error("Missing Level Type '%s'." % levelTypeId)
			return false

		var levelType: Dictionary = levelTypeData[levelTypeId]

		if levelType.size() != 2:
			push_error("Level Type '%s' must contain only title and rule." % levelTypeId)
			return false

		for fieldName in ["title", "rule"]:
			if not levelType.has(fieldName) or typeof(levelType[fieldName]) != TYPE_STRING:
				push_error("Level Type '%s' is missing String field '%s'." % [levelTypeId, fieldName])
				return false

			if levelType[fieldName].strip_edges().is_empty():
				push_error("Level Type '%s' has an empty '%s' field." % [levelTypeId, fieldName])
				return false

	return true

# Validates the complete ordered Level collection and its unique IDs.
func ValidateLevels(levelData: Array) -> bool:
	if levelData.size() != EXPECTED_LEVEL_COUNT:
		push_error("Content JSON must contain exactly %d Levels." % EXPECTED_LEVEL_COUNT)
		return false

	var levelIds: Dictionary = {}

	for levelIndex in range(levelData.size()):
		var level: Variant = levelData[levelIndex]

		if not ValidateLevelData(level, levelIndex):
			return false

		var levelId: String = level["id"]

		if levelIds.has(levelId):
			push_error("Duplicate Level ID: " + levelId)
			return false

		levelIds[levelId] = true

	return true

# Validates the metadata and Questions required by one Level definition.
func ValidateLevelData(levelData: Variant, levelIndex: int) -> bool:
	if typeof(levelData) != TYPE_DICTIONARY:
		push_error("Level at index %d must be a Dictionary." % levelIndex)
		return false

	if levelData.size() != 4:
		push_error("Level at index %d must contain only id, title, skills, and questions." % levelIndex)
		return false

	# Require the lightweight metadata used by gameplay and Level Cards.
	for fieldName in ["id", "title"]:
		if not levelData.has(fieldName) or typeof(levelData[fieldName]) != TYPE_STRING:
			push_error("Level at index %d is missing String field '%s'." % [levelIndex, fieldName])
			return false

		if levelData[fieldName].strip_edges().is_empty():
			push_error("Level field '%s' cannot be empty at index %d." % [fieldName, levelIndex])
			return false

	if not ValidateSkills(levelData):
		return false

	if not levelData.has("questions") or typeof(levelData["questions"]) != TYPE_ARRAY:
		push_error("Level '%s' must contain a questions Array." % levelData["id"])
		return false

	if levelData["questions"].size() != EXPECTED_QUESTION_COUNTS[levelIndex]:
		push_error(
			"Level '%s' must contain exactly %d Questions."
			% [levelData["id"], EXPECTED_QUESTION_COUNTS[levelIndex]]
		)
		return false

	return ValidateQuestions(levelData["questions"], levelData["id"])

# Validates the Level-owned Skill collection.
func ValidateSkills(levelData: Dictionary) -> bool:
	if not levelData.has("skills") or typeof(levelData["skills"]) != TYPE_ARRAY:
		push_error("Level '%s' must contain a skills Array." % levelData["id"])
		return false

	if levelData["skills"].is_empty():
		push_error("Level '%s' must contain at least one Skill." % levelData["id"])
		return false

	for skill in levelData["skills"]:
		if typeof(skill) != TYPE_STRING or skill.strip_edges().is_empty():
			push_error("Level '%s' contains an invalid Skill." % levelData["id"])
			return false

	return true

# Validates every lightweight Question and prevents duplicate IDs per Level.
func ValidateQuestions(questionData: Array, levelId: String) -> bool:
	var questionIds: Dictionary = {}

	for questionIndex in range(questionData.size()):
		var question: Variant = questionData[questionIndex]

		if not ValidateQuestionData(question, levelId, questionIndex):
			return false

		if questionIds.has(question["id"]):
			push_error("Duplicate Question ID '%s' in Level '%s'." % [question["id"], levelId])
			return false

		questionIds[question["id"]] = true

	return true

# Validates one lightweight Question and its parser-compatible expression.
func ValidateQuestionData(questionData: Variant, levelId: String, questionIndex: int) -> bool:
	if typeof(questionData) != TYPE_DICTIONARY:
		push_error("Question at index %d in Level '%s' must be a Dictionary." % [questionIndex, levelId])
		return false

	if questionData.size() != 2:
		push_error("Question %d in Level '%s' must contain only id and expression." % [questionIndex, levelId])
		return false

	for fieldName in ["id", "expression"]:
		if not questionData.has(fieldName) or typeof(questionData[fieldName]) != TYPE_STRING:
			push_error("Question %d in Level '%s' is missing String field '%s'." % [questionIndex, levelId, fieldName])
			return false

		if questionData[fieldName].strip_edges().is_empty():
			push_error("Question field '%s' cannot be empty in Level '%s'." % [fieldName, levelId])
			return false

	if not IsExpressionSyntaxValid(questionData["expression"]):
		push_error("Question '%s' has invalid expression syntax." % questionData["id"])
		return false

	return true

# Checks the lightweight ASCII expression contract used by ExpressionParser.
func IsExpressionSyntaxValid(expression: String) -> bool:
	var expressionPattern := RegEx.new()
	var compileError := expressionPattern.compile("^[0-9+\\-*/() ]+$")

	if compileError != OK or expressionPattern.search(expression) == null:
		return false

	var parenthesisDepth: int = 0

	for character in expression:
		if character == "(":
			parenthesisDepth += 1
		elif character == ")":
			parenthesisDepth -= 1

		if parenthesisDepth < 0:
			return false

	return parenthesisDepth == 0

#endregion
