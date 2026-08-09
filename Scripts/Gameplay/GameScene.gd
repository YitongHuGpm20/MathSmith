# Attached Object
extends Control

# ========== References ==========
# Main Game
@onready var stepArea: VBoxContainer = $MainMargin/MainLayout/StepArea
@onready var levelTitleLabel: Label = $MainMargin/MainLayout/TopBar/LevelTitleLabel
@onready var progressLabel: Label = $MainMargin/MainLayout/TopBar/ProgressLabel
@onready var ruleLabel: Label = $MainMargin/MainLayout/RuleLabel
@onready var equationLabel: Label = $MainMargin/MainLayout/QuestionPanel/CenterContainer/EquationLabel
@onready var feedbackLabel: Label = $MainMargin/MainLayout/FeedbackLabel
@onready var hintButton: Button = $MainMargin/MainLayout/BottomBar/HintButton
@onready var checkButton: Button = $MainMargin/MainLayout/BottomBar/CheckButton

# End Menu
@onready var endMenu: PanelContainer = $EndMenu
@onready var resultLabel: Label = $EndMenu/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ResultLabel
@onready var retryButton: Button = $EndMenu/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/RetryButton
@onready var lobbyButton: Button = $EndMenu/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/LobbyButton

# Variables
const STEP_CARD_SCENE = preload("res://Scenes/Menus/StepCard.tscn")
var levelLoader := preload("res://Scripts/Gameplay/LevelLoader.gd").new()
var stepGenerator := preload("res://Scripts/Gameplay/StepGenerator.gd").new()
var currentLevel: Dictionary
var currentQuestionIndex: int = 0
var correctSteps: Array[String] = []
var shuffledSteps: Array[String] = []
var questionCompleted: bool = false
var revealedHintCount: int = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var levels = levelLoader.LoadLevels()
	if levels.size() == 0:
		return

	currentLevel = levels[0]
	LoadQuestion(currentQuestionIndex)
	
	# Bind button events
	hintButton.pressed.connect(UseHint)
	checkButton.pressed.connect(CheckAnswer)
	retryButton.pressed.connect(RestartLevel)
	lobbyButton.pressed.connect(BackToLobby)

func LoadQuestion(questionIndex: int) -> void:
	revealedHintCount = 0
	hintButton.disabled = false
	
	var questions = currentLevel["questions"]

	if questionIndex < 0 or questionIndex >= questions.size():
		push_error("Question index out of range: " + str(questionIndex))
		return

	currentQuestionIndex = questionIndex
	var currentQuestion = questions[currentQuestionIndex]
	var expression = currentQuestion["expression"]
	levelTitleLabel.text = currentLevel["title"]
	ruleLabel.text = currentLevel["rule"]
	equationLabel.text = expression
	progressLabel.text = "%d/%d" % [currentQuestionIndex + 1, questions.size()]
	correctSteps = stepGenerator.GenerateAdditionSteps(expression)

	if correctSteps.size() == 0:
		push_error("Failed to generate steps for expression: " + expression)
		return

	ShuffleSteps()
	CreateStepCards(shuffledSteps)

	feedbackLabel.text = "Arrange the solution steps in the correct order."

func CreateStepCards(steps: Array[String]) -> void:
	ClearStepCards()
	
	for i in range(steps.size()):
		var card = STEP_CARD_SCENE.instantiate()
		stepArea.add_child(card)
		card.Setup(i + 1, steps[i])

func ClearStepCards() -> void:
	for child in stepArea.get_children():
		child.queue_free()

func ShuffleSteps() -> void:
	shuffledSteps = correctSteps.duplicate()

	if shuffledSteps.size() <= 1:
		return

	while shuffledSteps == correctSteps:
		shuffledSteps.shuffle()

func CheckAnswer() -> void:
	if questionCompleted:
		GoToNextQuestion()
		return

	var currentSteps: Array[String] = []

	for child in stepArea.get_children():
		if "stepText" in child:
			currentSteps.append(child.stepText)

	if currentSteps == correctSteps:
		questionCompleted = true

		feedbackLabel.text = "Correct!"
		checkButton.text = "Next"
	else:
		feedbackLabel.text = "Not quite. Try again."

func UseHint() -> void:
	if revealedHintCount >= correctSteps.size():
		hintButton.disabled = true
		return

	var targetStep = correctSteps[revealedHintCount]
	var targetCard = null

	for child in stepArea.get_children():
		if child.stepText == targetStep:
			targetCard = child
			break

	if targetCard == null:
		return

	stepArea.move_child(targetCard, revealedHintCount)
	UpdateStepOrderLabels()
	revealedHintCount += 1
	feedbackLabel.text = "Hint: Step %d has been placed correctly." % revealedHintCount

	if revealedHintCount >= correctSteps.size():
		hintButton.disabled = true

func UpdateStepOrderLabels() -> void:
	for i in range(stepArea.get_child_count()):
		var card = stepArea.get_child(i)
		if card.has_method("Setup"):
			card.Setup(i + 1, card.stepText)

func GoToNextQuestion() -> void:
	currentQuestionIndex += 1

	var questions = currentLevel["questions"]

	if currentQuestionIndex >= questions.size():
		ShowEndMenu()
		return

	questionCompleted = false
	checkButton.text = "Check"

	LoadQuestion(currentQuestionIndex)

func ShowEndMenu() -> void:
	endMenu.visible = true
	var questionCount = currentLevel["questions"].size()
	resultLabel.text = "%d / %d Questions Completed" % [questionCount, questionCount]

func RestartLevel() -> void:
	currentQuestionIndex = 0
	questionCompleted = false
	endMenu.visible = false
	checkButton.disabled = false
	checkButton.text = "Check"
	LoadQuestion(currentQuestionIndex)

func BackToLobby() -> void:
	print("Back to Lobby")
