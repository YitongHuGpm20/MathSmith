## Controls the complete M1 gameplay loop for the active level.
##
## This script owns level loading, question state, step generation, validation,
## hints, progression, and level completion. UIManager only presents this state.
extends Control

#region ========== Constants ==========

const LEVEL_DATA_PATH: String = "res://Data/SampleLevels.json"

#endregion

#region ========== References ==========

@onready var uiManager = $UIManager

#endregion

#region ========== Variables ==========

var levels: Array = []
var currentLevel: Dictionary = {}
var currentQuestionIndex: int = 0
var correctSteps: Array[String] = []
var questionCompleted: bool = false
var revealedHintCount: int = 0

#endregion

#region ========== Godot Functions ==========

# Initializes level data, connects UI requests, and starts the first question.
func _ready() -> void:
	uiManager.checkRequested.connect(CheckAnswer)
	uiManager.hintRequested.connect(UseHint)
	uiManager.retryRequested.connect(RestartLevel)
	uiManager.lobbyRequested.connect(BackToLobby)

	levels = LoadLevels()

	# Stop initialization when no valid level data is available.
	if levels.is_empty():
		uiManager.ShowDataError("No valid level data could be loaded.")
		return

	# M1 starts with the first level until M2 introduces level selection.
	currentLevel = levels[0]
	LoadQuestion(0)

#endregion

#region ========== Functions ==========

# Loads and validates all level definitions from the project JSON file.
func LoadLevels() -> Array:
	var levelFile := FileAccess.open(LEVEL_DATA_PATH, FileAccess.READ)

	# Reject missing or inaccessible data files.
	if levelFile == null:
		push_error("Failed to open level data: " + LEVEL_DATA_PATH)
		return []

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
		return []

	# Validate the root structure required by the gameplay loop.
	var levelData: Variant = json.data

	if typeof(levelData) != TYPE_DICTIONARY:
		push_error("Level JSON root must be a Dictionary.")
		return []

	if not levelData.has("levels") or typeof(levelData["levels"]) != TYPE_ARRAY:
		push_error("Level JSON must contain a 'levels' Array.")
		return []

	return levelData["levels"]

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
	correctSteps = GenerateAdditionSteps(expression)

	# Stop if the expression cannot produce a valid solution process.
	if correctSteps.is_empty():
		push_error("Failed to generate steps for expression: " + expression)
		uiManager.ShowDataError("This question could not be loaded.")
		return

	# Present the question and a shuffled copy of its correct steps.
	var shuffledSteps := ShuffleSteps(correctSteps)
	uiManager.ShowQuestion(
		currentLevel.get("title", "Untitled Level"),
		currentLevel.get("rule", "Arrange the solution steps in the correct order."),
		expression,
		currentQuestionIndex + 1,
		questions.size(),
		shuffledSteps
	)

# Generates the ordered solution process for a two-number addition expression.
func GenerateAdditionSteps(expression: String) -> Array[String]:
	var parts := expression.split("+")

	# M1 only supports addition expressions containing exactly two numbers.
	if parts.size() != 2:
		push_error("Invalid addition expression: " + expression)
		return []

	var firstNumber := int(parts[0].strip_edges())
	var secondNumber := int(parts[1].strip_edges())
	var firstTens := firstNumber - firstNumber % 10
	var firstOnes := firstNumber % 10
	var secondTens := secondNumber - secondNumber % 10
	var secondOnes := secondNumber % 10
	var tensTotal := firstTens + secondTens
	var onesTotal := firstOnes + secondOnes
	var finalAnswer := firstNumber + secondNumber

	# Build the learning sequence from decomposition through final answer.
	return [
		"= (%d + %d) + (%d + %d)" % [firstTens, firstOnes, secondTens, secondOnes],
		"= (%d + %d) + (%d + %d)" % [firstTens, secondTens, firstOnes, secondOnes],
		"= %d + %d" % [tensTotal, onesTotal],
		"= %d" % finalAnswer
	]

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
		uiManager.ShowEndMenu(questions.size(), questions.size())
		return

	LoadQuestion(nextQuestionIndex)

# Restarts the active level from its first question.
func RestartLevel() -> void:
	uiManager.HideEndMenu()
	LoadQuestion(0)

# Handles the future Lobby navigation entry point without changing M1 behavior.
func BackToLobby() -> void:
	print("Lobby navigation will be implemented in the M2 navigation task.")

#endregion
