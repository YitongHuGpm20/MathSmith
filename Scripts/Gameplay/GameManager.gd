## Controls the complete M1 gameplay loop for the active level.
##
## This script owns question state, gameplay validation, navigation, progress,
## and level completion. LevelLoader supplies content, StepGenerator produces
## teaching steps, and GameUI only presents Game Scene state.
extends Node

#region ========== Constants ==========

const HOME_SCENE_PATH: String = "res://Scenes/HomeScene.tscn"
const LOBBY_SCENE_PATH: String = "res://Scenes/LobbyScene.tscn"
const GAME_SCENE_PATH: String = "res://Scenes/GameScene.tscn"
const DEFAULT_LEVEL_TYPE_ID: String = "step_ordering"

#endregion

#region ========== References ==========

var gameUI: Node = null
var levelLoader := preload("res://Scripts/Gameplay/LevelLoader.gd").new()
var stepGenerator := preload("res://Scripts/Math/StepGenerator.gd").new()

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
	var contentData: Dictionary = levelLoader.LoadContentData()

	if contentData.is_empty():
		return

	# Publish validated content and preserve the initial default Level.
	levelTypes = contentData["level_types"]
	levels = contentData["levels"]
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
func RegisterGameUI(newGameUI: Node) -> void:
	if is_instance_valid(gameUI):
		DisconnectGameUISignals()

	gameUI = newGameUI
	gameUI.checkRequested.connect(CheckAnswer)
	gameUI.hintRequested.connect(UseHint)
	gameUI.retryRequested.connect(RestartLevel)
	gameUI.lobbyRequested.connect(BackToLobby)

	# Surface content errors only after a visual UI is available.
	if levels.is_empty():
		gameUI.ShowDataError("No valid level data could be loaded.")
		return

	if currentLevel.is_empty():
		currentLevel = levels[0]

	LoadQuestion(0)

# Releases a departing Game Scene UI without changing persistent gameplay data.
func UnregisterGameUI(departingGameUI: Node) -> void:
	if gameUI != departingGameUI:
		return

	DisconnectGameUISignals()
	gameUI = null

# Disconnects all request signals owned by the active Game Scene UI.
func DisconnectGameUISignals() -> void:
	if not is_instance_valid(gameUI):
		return

	if gameUI.checkRequested.is_connected(CheckAnswer):
		gameUI.checkRequested.disconnect(CheckAnswer)

	if gameUI.hintRequested.is_connected(UseHint):
		gameUI.hintRequested.disconnect(UseHint)

	if gameUI.retryRequested.is_connected(RestartLevel):
		gameUI.retryRequested.disconnect(RestartLevel)

	if gameUI.lobbyRequested.is_connected(BackToLobby):
		gameUI.lobbyRequested.disconnect(BackToLobby)

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
		gameUI.ShowDataError("This question could not be loaded.")
		return

	# Present the question and a shuffled copy of its correct steps.
	var shuffledSteps := ShuffleSteps(correctSteps)
	gameUI.ShowQuestion(
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

	var currentSteps: Array[String] = gameUI.GetStepOrder()

	# Update gameplay state only after an exact ordered match.
	if currentSteps == correctSteps:
		questionCompleted = true
		RecordQuestionCompletion()
		gameUI.ShowCorrectAnswer()
	else:
		gameUI.ShowIncorrectAnswer()

# Places the next correct step and updates the remaining hint availability.
func UseHint() -> void:
	if revealedHintCount >= correctSteps.size():
		gameUI.SetHintAvailable(false)
		return

	# The manager selects the correct step; the UI only moves its visual card.
	var targetStep := correctSteps[revealedHintCount]
	var stepWasPlaced: bool = gameUI.PlaceStepAt(targetStep, revealedHintCount)

	if not stepWasPlaced:
		return

	revealedHintCount += 1
	gameUI.ShowHintUsed(revealedHintCount)
	gameUI.SetHintAvailable(revealedHintCount < correctSteps.size())

# Advances to the next question or completes the current level.
func GoToNextQuestion() -> void:
	var questions: Array = currentLevel.get("questions", [])
	var nextQuestionIndex := currentQuestionIndex + 1

	# Complete the level after the final question.
	if nextQuestionIndex >= questions.size():
		CompleteCurrentLevel()
		gameUI.ShowEndMenu(questions.size(), questions.size())
		return

	LoadQuestion(nextQuestionIndex)

# Restarts the active level from its first question.
func RestartLevel() -> void:
	gameUI.HideEndMenu()
	LoadQuestion(0)

# Returns to the Lobby while preserving current-session Level progress.
func BackToLobby() -> void:
	OpenLobby()

#endregion
