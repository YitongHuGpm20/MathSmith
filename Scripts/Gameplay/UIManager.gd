## Presents gameplay state and forwards player UI requests to GameManager.
##
## This script owns node references, button bindings, card presentation, and
## visual feedback. It does not make gameplay or answer-validation decisions.
extends Node

#region ========== Signals ==========

signal checkRequested
signal hintRequested
signal retryRequested
signal lobbyRequested

#endregion

#region ========== Constants ==========

const STEP_CARD_SCENE: PackedScene = preload("res://Scenes/Menus/StepCard.tscn")

#endregion

#region ========== References ==========

@onready var stepArea = $"../MainMargin/MainLayout/StepArea"
@onready var levelTitleLabel: Label = $"../MainMargin/MainLayout/TopBar/LevelTitleLabel"
@onready var progressLabel: Label = $"../MainMargin/MainLayout/TopBar/ProgressLabel"
@onready var ruleLabel: Label = $"../MainMargin/MainLayout/RuleLabel"
@onready var equationLabel: Label = $"../MainMargin/MainLayout/QuestionPanel/CenterContainer/EquationLabel"
@onready var feedbackLabel: Label = $"../MainMargin/MainLayout/FeedbackLabel"
@onready var hintButton: Button = $"../MainMargin/MainLayout/BottomBar/HintButton"
@onready var checkButton: Button = $"../MainMargin/MainLayout/BottomBar/CheckButton"
@onready var endMenu: PanelContainer = $"../EndMenu"
@onready var resultLabel: Label = $"../EndMenu/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ResultLabel"
@onready var retryButton: Button = $"../EndMenu/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/RetryButton"
@onready var lobbyButton: Button = $"../EndMenu/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/LobbyButton"

#endregion

#region ========== Godot Functions ==========

# Connects scene controls to UI request signals.
func _ready() -> void:
	hintButton.pressed.connect(_on_hint_button_pressed)
	checkButton.pressed.connect(_on_check_button_pressed)
	retryButton.pressed.connect(_on_retry_button_pressed)
	lobbyButton.pressed.connect(_on_lobby_button_pressed)

#endregion

#region ========== Functions ==========

# Displays a newly loaded question and rebuilds its step cards.
func ShowQuestion(
	levelTitle: String,
	ruleText: String,
	expression: String,
	questionNumber: int,
	questionCount: int,
	steps: Array[String]
) -> void:
	levelTitleLabel.text = levelTitle
	ruleLabel.text = ruleText
	equationLabel.text = expression
	progressLabel.text = "%d/%d" % [questionNumber, questionCount]
	feedbackLabel.text = "Arrange the solution steps in the correct order."
	hintButton.disabled = false
	checkButton.disabled = false
	checkButton.text = "Check"
	CreateStepCards(steps)

# Rebuilds the step area from the supplied display order.
func CreateStepCards(steps: Array[String]) -> void:
	ClearStepCards()

	# Instantiate one reusable visual card for each generated step.
	for stepIndex in range(steps.size()):
		var stepCard := STEP_CARD_SCENE.instantiate()
		stepArea.add_child(stepCard)
		stepCard.Setup(stepIndex + 1, steps[stepIndex])

# Removes all cards from the current question display.
func ClearStepCards() -> void:
	for child in stepArea.get_children():
		child.queue_free()

# Returns the step text in its current visual order for gameplay validation.
func GetStepOrder() -> Array[String]:
	var displayedSteps: Array[String] = []

	for child in stepArea.get_children():
		displayedSteps.append(child.stepText)

	return displayedSteps

# Moves the requested visual step card to a specified position.
func PlaceStepAt(stepText: String, targetIndex: int) -> bool:
	for child in stepArea.get_children():
		if child.stepText == stepText:
			stepArea.move_child(child, targetIndex)
			stepArea.UpdateOrderLabels()
			return true

	return false

# Displays the visual state for a correct answer.
func ShowCorrectAnswer() -> void:
	feedbackLabel.text = "Correct!"
	checkButton.text = "Next"

# Displays the visual state for an incorrect answer.
func ShowIncorrectAnswer() -> void:
	feedbackLabel.text = "Not quite. Try again."

# Displays feedback after a hint places one correct step.
func ShowHintUsed(revealedHintCount: int) -> void:
	feedbackLabel.text = "Hint: Step %d has been placed correctly." % revealedHintCount

# Enables or disables the hint control without changing gameplay state.
func SetHintAvailable(isAvailable: bool) -> void:
	hintButton.disabled = not isAvailable

# Displays a safe visual error state when gameplay data cannot be used.
func ShowDataError(message: String) -> void:
	feedbackLabel.text = message
	hintButton.disabled = true
	checkButton.disabled = true

# Displays the level completion overlay and result text.
func ShowEndMenu(completedCount: int, questionCount: int) -> void:
	resultLabel.text = "%d / %d Questions Completed" % [completedCount, questionCount]
	endMenu.visible = true

# Hides the level completion overlay before gameplay restarts.
func HideEndMenu() -> void:
	endMenu.visible = false

#endregion

#region ========== Signal Callbacks ==========

# Forwards the Check button request to GameManager.
func _on_check_button_pressed() -> void:
	checkRequested.emit()

# Forwards the Hint button request to GameManager.
func _on_hint_button_pressed() -> void:
	hintRequested.emit()

# Forwards the retry request to GameManager.
func _on_retry_button_pressed() -> void:
	retryRequested.emit()

# Forwards the Lobby request to GameManager.
func _on_lobby_button_pressed() -> void:
	lobbyRequested.emit()

#endregion
