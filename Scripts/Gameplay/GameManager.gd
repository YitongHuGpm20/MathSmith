## Controls the complete M1 gameplay loop for the active level.
##
## This script owns level loading, question state, gameplay validation, hints,
## progression, and level completion. StepGenerator produces teaching steps,
## while UIManager only presents gameplay state.
extends Node

#region ========== Constants ==========

const LEVEL_DATA_PATH: String = "res://Data/SampleLevels.json"
const HOME_SCENE_PATH: String = "res://Scenes/HomeScene.tscn"
const LOBBY_SCENE_PATH: String = "res://Scenes/LobbyScene.tscn"
const GAME_SCENE_PATH: String = "res://Scenes/GameScene.tscn"
const DEFAULT_LEVEL_TYPE_ID: String = "step_ordering"
const EXPECTED_LEVEL_COUNT: int = 12
const EXPECTED_QUESTION_COUNTS: Array[int] = [5, 5, 6, 6, 7, 7, 8, 8, 9, 9, 10, 10]
const REQUIRED_LEVEL_TYPE_IDS: Array[String] = [
	"step_ordering",
	"multiple_choice_ordering",
	"fill_in_process"
]

#endregion

#region ========== References ==========

var uiManager: Node = null
var stepGenerator := preload("res://Scripts/Gameplay/StepGenerator.gd").new()

#endregion

#region ========== Variables ==========

var levels: Array = []
var levelTypes: Dictionary = {}
var selectedLevelTypeId: String = DEFAULT_LEVEL_TYPE_ID
var currentLevel: Dictionary = {}
var currentQuestionIndex: int = 0
var correctSteps: Array[String] = []
var questionCompleted: bool = false
var revealedHintCount: int = 0
var levelProgress: Dictionary = {}

#endregion

#region ========== Godot Functions ==========

# Loads shared content before any gameplay or menu scene requests it.
func _ready() -> void:
	if not LoadContentData():
		return

	# Preserve the M1 default until Lobby selection is connected to gameplay.
	currentLevel = levels[0]

#endregion

#region ========== Functions ==========

# Opens the Home Scene while preserving current-session progress.
func OpenHome() -> void:
	ChangeScene(HOME_SCENE_PATH)

# Opens the Lobby Scene while preserving current-session progress.
func OpenLobby() -> void:
	ChangeScene(LOBBY_SCENE_PATH)

# Opens the Game Scene for the currently selected Level.
func OpenGame() -> void:
	if currentLevel.is_empty():
		push_error("Cannot open Game Scene without a selected Level.")
		return

	ChangeScene(GAME_SCENE_PATH)

# Changes scenes through one guarded navigation entry point.
func ChangeScene(scenePath: String) -> void:
	var changeError := get_tree().change_scene_to_file(scenePath)

	if changeError != OK:
		push_error("Failed to open scene '%s' with error %d." % [scenePath, changeError])

# Registers the active Game Scene UI and starts its current Level.
func RegisterUIManager(newUIManager: Node) -> void:
	if is_instance_valid(uiManager):
		DisconnectUIManagerSignals()

	uiManager = newUIManager
	uiManager.checkRequested.connect(CheckAnswer)
	uiManager.hintRequested.connect(UseHint)
	uiManager.retryRequested.connect(RestartLevel)
	uiManager.lobbyRequested.connect(BackToLobby)

	# Surface content errors only after a visual UI is available.
	if levels.is_empty():
		uiManager.ShowDataError("No valid level data could be loaded.")
		return

	if currentLevel.is_empty():
		currentLevel = levels[0]

	LoadQuestion(0)

# Releases a departing Game Scene UI without changing persistent gameplay data.
func UnregisterUIManager(departingUIManager: Node) -> void:
	if uiManager != departingUIManager:
		return

	DisconnectUIManagerSignals()
	uiManager = null

# Disconnects all request signals owned by the active Game Scene UI.
func DisconnectUIManagerSignals() -> void:
	if not is_instance_valid(uiManager):
		return

	if uiManager.checkRequested.is_connected(CheckAnswer):
		uiManager.checkRequested.disconnect(CheckAnswer)

	if uiManager.hintRequested.is_connected(UseHint):
		uiManager.hintRequested.disconnect(UseHint)

	if uiManager.retryRequested.is_connected(RestartLevel):
		uiManager.retryRequested.disconnect(RestartLevel)

	if uiManager.lobbyRequested.is_connected(BackToLobby):
		uiManager.lobbyRequested.disconnect(BackToLobby)

# Loads and validates Level Types and Levels from the project JSON file.
func LoadContentData() -> bool:
	var levelFile := FileAccess.open(LEVEL_DATA_PATH, FileAccess.READ)

	# Reject missing or inaccessible data files.
	if levelFile == null:
		push_error("Failed to open level data: " + LEVEL_DATA_PATH)
		return false

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
		return false

	# Validate the root structure required by the gameplay loop.
	var contentData: Variant = json.data

	if typeof(contentData) != TYPE_DICTIONARY:
		push_error("Content JSON root must be a Dictionary.")
		return false

	if not contentData.has("level_types") or typeof(contentData["level_types"]) != TYPE_DICTIONARY:
		push_error("Content JSON must contain a 'level_types' Dictionary.")
		return false

	if not contentData.has("levels") or typeof(contentData["levels"]) != TYPE_ARRAY:
		push_error("Content JSON must contain a 'levels' Array.")
		return false

	# Validate interaction types independently from mathematical content.
	if not ValidateLevelTypes(contentData["level_types"]):
		return false

	var loadedLevels: Array = contentData["levels"]
	var levelIds: Dictionary = {}

	if loadedLevels.size() != EXPECTED_LEVEL_COUNT:
		push_error("Content JSON must contain exactly %d Levels." % EXPECTED_LEVEL_COUNT)
		return false

	# Validate every level before exposing the collection to gameplay systems.
	for levelIndex in range(loadedLevels.size()):
		var level: Variant = loadedLevels[levelIndex]

		if not ValidateLevelData(level, levelIndex):
			return false

		var levelId: String = level["id"]

		if levelIds.has(levelId):
			push_error("Duplicate Level ID: " + levelId)
			return false

		levelIds[levelId] = true

	# Publish validated content only after the complete file passes validation.
	levelTypes = contentData["level_types"]
	levels = loadedLevels
	return true

# Returns all Level Types that describe available gameplay interactions.
func GetLevelTypes() -> Dictionary:
	return levelTypes

# Returns one Level Type or an empty Dictionary when the ID is unknown.
func GetLevelTypeById(levelTypeId: String) -> Dictionary:
	return levelTypes.get(levelTypeId, {})

# Returns the rule owned by the currently selected Level Type.
func GetSelectedLevelTypeRule() -> String:
	var selectedLevelType: Dictionary = GetLevelTypeById(selectedLevelTypeId)
	return selectedLevelType.get("rule", "")

# Returns all validated levels for future Lobby card generation.
func GetLevels() -> Array:
	return levels

# Returns the level matching an ID or an empty Dictionary when none exists.
func GetLevelById(levelId: String) -> Dictionary:
	for level in levels:
		if level["id"] == levelId:
			return level

	return {}

# Selects mathematical Level content without changing the active Level Type.
func SelectLevel(levelId: String) -> bool:
	var selectedLevel := GetLevelById(levelId)

	if selectedLevel.is_empty():
		push_error("Cannot select unknown Level ID: " + levelId)
		return false

	# Reset transient gameplay state for the newly selected Level.
	currentLevel = selectedLevel
	currentQuestionIndex = 0
	correctSteps.clear()
	questionCompleted = false
	revealedHintCount = 0
	return true

# Returns the selected Level ID or an empty String before content is available.
func GetSelectedLevelId() -> String:
	return currentLevel.get("id", "")

# Returns lightweight progress for one Level during the current run.
func GetLevelProgress(levelId: String) -> Dictionary:
	return levelProgress.get(
		levelId,
		{
			"completedQuestions": 0,
			"completed": false
		}
	)

# Records the highest completed Question reached in the selected Level.
func RecordQuestionCompletion() -> void:
	var levelId: String = GetSelectedLevelId()

	if levelId.is_empty():
		return

	var progressData := GetLevelProgress(levelId)
	progressData["completedQuestions"] = maxi(
		progressData["completedQuestions"],
		currentQuestionIndex + 1
	)
	levelProgress[levelId] = progressData

# Marks the selected Level complete for the remainder of the current run.
func CompleteCurrentLevel() -> void:
	var levelId: String = GetSelectedLevelId()

	if levelId.is_empty():
		return

	var progressData := GetLevelProgress(levelId)
	progressData["completedQuestions"] = currentLevel.get("questions", []).size()
	progressData["completed"] = true
	levelProgress[levelId] = progressData

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

# Validates the metadata and questions required by one level definition.
func ValidateLevelData(levelData: Variant, levelIndex: int) -> bool:
	if typeof(levelData) != TYPE_DICTIONARY:
		push_error("Level at index %d must be a Dictionary." % levelIndex)
		return false

	if levelData.size() != 4:
		push_error("Level at index %d must contain only id, title, skills, and questions." % levelIndex)
		return false

	# Require the lightweight metadata used by gameplay and future Level Cards.
	var requiredTextFields: Array[String] = ["id", "title"]

	for fieldName in requiredTextFields:
		if not levelData.has(fieldName) or typeof(levelData[fieldName]) != TYPE_STRING:
			push_error("Level at index %d is missing String field '%s'." % [levelIndex, fieldName])
			return false

		if levelData[fieldName].strip_edges().is_empty():
			push_error("Level field '%s' cannot be empty at index %d." % [fieldName, levelIndex])
			return false

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

	if not levelData.has("questions") or typeof(levelData["questions"]) != TYPE_ARRAY:
		push_error("Level '%s' must contain a questions Array." % levelData["id"])
		return false

	if levelData["questions"].size() != EXPECTED_QUESTION_COUNTS[levelIndex]:
		push_error(
			"Level '%s' must contain exactly %d Questions."
			% [levelData["id"], EXPECTED_QUESTION_COUNTS[levelIndex]]
		)
		return false

	# Validate every question and prevent duplicate IDs within this level.
	var questionIds: Dictionary = {}

	for questionIndex in range(levelData["questions"].size()):
		var question: Variant = levelData["questions"][questionIndex]

		if not ValidateQuestionData(question, levelData["id"], questionIndex):
			return false

		if questionIds.has(question["id"]):
			push_error("Duplicate Question ID '%s' in Level '%s'." % [question["id"], levelData["id"]])
			return false

		questionIds[question["id"]] = true

	return true

# Validates one question against the data needed by the M1 gameplay mode.
func ValidateQuestionData(questionData: Variant, levelId: String, questionIndex: int) -> bool:
	if typeof(questionData) != TYPE_DICTIONARY:
		push_error("Question at index %d in Level '%s' must be a Dictionary." % [questionIndex, levelId])
		return false

	if questionData.size() != 2:
		push_error("Question %d in Level '%s' must contain only id and expression." % [questionIndex, levelId])
		return false

	# Require the lightweight Question fields shared by every Level Type.
	for fieldName in ["id", "expression"]:
		if not questionData.has(fieldName) or typeof(questionData[fieldName]) != TYPE_STRING:
			push_error("Question %d in Level '%s' is missing String field '%s'." % [questionIndex, levelId, fieldName])
			return false

		if questionData[fieldName].strip_edges().is_empty():
			push_error("Question field '%s' cannot be empty in Level '%s'." % [fieldName, levelId])
			return false

	# Accept parser-friendly ASCII arithmetic while rejecting malformed parentheses.
	if not IsExpressionSyntaxValid(questionData["expression"]):
		push_error("Question '%s' has invalid expression syntax." % questionData["id"])
		return false

	return true

# Checks the lightweight expression contract intended for the future parser.
func IsExpressionSyntaxValid(expression: String) -> bool:
	var expressionPattern := RegEx.new()
	var compileError := expressionPattern.compile("^[0-9+\\-*/() ]+$")

	if compileError != OK or expressionPattern.search(expression) == null:
		return false

	var parenthesisDepth: int = 0

	# Ensure parentheses are balanced and never close before they open.
	for character in expression:
		if character == "(":
			parenthesisDepth += 1
		elif character == ")":
			parenthesisDepth -= 1

		if parenthesisDepth < 0:
			return false

	return parenthesisDepth == 0

# Loads the requested question and prepares its ordered and shuffled steps.
func LoadQuestion(questionIndex: int) -> void:
	var questions: Array = currentLevel.get("questions", [])

	# Reject invalid question indices before changing gameplay state.
	if questionIndex < 0 or questionIndex >= questions.size():
		push_error("Question index out of range: " + str(questionIndex))
		return

	currentQuestionIndex = questionIndex
	questionCompleted = false
	revealedHintCount = 0

	var currentQuestion: Dictionary = questions[currentQuestionIndex]
	var expression: String = currentQuestion.get("expression", "")
	correctSteps = stepGenerator.GenerateSteps(expression)

	# Stop if the expression cannot produce a valid solution process.
	if correctSteps.is_empty():
		push_error("Failed to generate steps for expression: " + expression)
		uiManager.ShowDataError("This question could not be loaded.")
		return

	# Present the question and a shuffled copy of its correct steps.
	var shuffledSteps := ShuffleSteps(correctSteps)
	uiManager.ShowQuestion(
		currentLevel.get("title", "Untitled Level"),
		GetSelectedLevelTypeRule(),
		expression,
		currentQuestionIndex + 1,
		questions.size(),
		shuffledSteps
	)

# Returns a shuffled step list that differs from the correct order when possible.
func ShuffleSteps(orderedSteps: Array[String]) -> Array[String]:
	var shuffledSteps: Array[String] = orderedSteps.duplicate()

	if shuffledSteps.size() <= 1:
		return shuffledSteps

	# Prevent a question from initially appearing already solved.
	while shuffledSteps == orderedSteps:
		shuffledSteps.shuffle()

	return shuffledSteps

# Validates the displayed step order or advances after a correct answer.
func CheckAnswer() -> void:
	if questionCompleted:
		GoToNextQuestion()
		return

	var currentSteps: Array[String] = uiManager.GetStepOrder()

	# Update gameplay state only after an exact ordered match.
	if currentSteps == correctSteps:
		questionCompleted = true
		RecordQuestionCompletion()
		uiManager.ShowCorrectAnswer()
	else:
		uiManager.ShowIncorrectAnswer()

# Places the next correct step and updates the remaining hint availability.
func UseHint() -> void:
	if revealedHintCount >= correctSteps.size():
		uiManager.SetHintAvailable(false)
		return

	# The manager selects the correct step; the UI only moves its visual card.
	var targetStep := correctSteps[revealedHintCount]
	var stepWasPlaced: bool = uiManager.PlaceStepAt(targetStep, revealedHintCount)

	if not stepWasPlaced:
		return

	revealedHintCount += 1
	uiManager.ShowHintUsed(revealedHintCount)
	uiManager.SetHintAvailable(revealedHintCount < correctSteps.size())

# Advances to the next question or completes the current level.
func GoToNextQuestion() -> void:
	var questions: Array = currentLevel.get("questions", [])
	var nextQuestionIndex := currentQuestionIndex + 1

	# Complete the level after the final question.
	if nextQuestionIndex >= questions.size():
		CompleteCurrentLevel()
		uiManager.ShowEndMenu(questions.size(), questions.size())
		return

	LoadQuestion(nextQuestionIndex)

# Restarts the active level from its first question.
func RestartLevel() -> void:
	uiManager.HideEndMenu()
	LoadQuestion(0)

# Returns to the Lobby while preserving current-session Level progress.
func BackToLobby() -> void:
	OpenLobby()

#endregion
