## Presents Game Scene state and forwards player requests to GameManager.
##
## This script owns node references, button bindings, card presentation, and
## visual feedback. It does not make gameplay or answer-validation decisions.
extends Node

#region ========== Signals ==========

signal checkRequested
signal hintRequested
signal retryRequested
signal lobbyRequested
signal orderChanged

#endregion

#region ========== Constants ==========

const STEP_CARD_SCENE: PackedScene = preload("res://Scenes/Menus/StepCard.tscn")

#endregion

#region ========== References ==========

@onready var stepArea = $"../MainMargin/MainLayout/StepScroll/StepArea"
@onready var mainMargin: MarginContainer = $"../MainMargin"
@onready var mainLayout: VBoxContainer = $"../MainMargin/MainLayout"
@onready var questionPanel: PanelContainer = $"../MainMargin/MainLayout/QuestionPanel"
@onready var levelTitleLabel: Label = $"../MainMargin/MainLayout/TopBar/LevelTitleLabel"
@onready var progressLabel: Label = $"../MainMargin/MainLayout/TopBar/ProgressLabel"
@onready var ruleLabel: Label = $"../MainMargin/MainLayout/RuleLabel"
@onready var equationLabel: Label = $"../MainMargin/MainLayout/QuestionPanel/CenterContainer/EquationLabel"
@onready var feedbackLabel: Label = $"../MainMargin/MainLayout/FeedbackLabel"
@onready var hintButton: Button = $"../MainMargin/MainLayout/BottomBar/HintButton"
@onready var checkButton: Button = $"../MainMargin/MainLayout/BottomBar/CheckButton"
@onready var topLobbyButton: Button = $"../MainMargin/MainLayout/TopBar/LobbyButton"
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
	topLobbyButton.pressed.connect(_on_lobby_button_pressed)
	retryButton.pressed.connect(_on_retry_button_pressed)
	lobbyButton.pressed.connect(_on_lobby_button_pressed)
	stepArea.orderChanged.connect(_on_step_order_changed)
	get_viewport().size_changed.connect(UpdateResponsiveLayout)
	UpdateResponsiveLayout()

	# Wait until every sibling UI branch has completed its ready lifecycle.
	GameManager.call_deferred("RegisterGameUI", self)

# Releases this scene's UI reference before its nodes leave the tree.
func _exit_tree() -> void:
	GameManager.UnregisterGameUI(self)

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
		stepCard.Setup(steps[stepIndex])

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
			stepArea.PreviewCardPosition(child, targetIndex)
			return true

	return false

# Compresses vertical chrome on smaller windows so five Steps remain visible.
func UpdateResponsiveLayout() -> void:
	var viewportSize := get_viewport().get_visible_rect().size
	var compactLayout := viewportSize.y < 760.0
	var horizontalMargin := 24 if viewportSize.x < 900.0 else 56
	var verticalMargin := 18 if compactLayout else 32

	mainMargin.add_theme_constant_override("margin_left", horizontalMargin)
	mainMargin.add_theme_constant_override("margin_right", horizontalMargin)
	mainMargin.add_theme_constant_override("margin_top", verticalMargin)
	mainMargin.add_theme_constant_override("margin_bottom", verticalMargin)
	mainLayout.add_theme_constant_override("separation", 8 if compactLayout else 14)
	stepArea.add_theme_constant_override("separation", 6 if compactLayout else 10)
	questionPanel.custom_minimum_size.y = 70.0 if compactLayout else 92.0

# Displays the visual state for a correct answer.
func ShowCorrectAnswer() -> void:
	feedbackLabel.text = "Correct!"
	hintButton.disabled = true
	checkButton.text = "Next"
	AudioManager.PlayCorrect()

# Displays the visual state for an incorrect answer.
func ShowIncorrectAnswer() -> void:
	feedbackLabel.text = "Not quite. Try again."
	AudioManager.PlayWrong()

# Displays feedback after a hint places one correct step.
func ShowHintUsed(revealedHintCount: int) -> void:
	feedbackLabel.text = "Hint: Step %d has been placed correctly." % revealedHintCount
	AudioManager.PlayHint()

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
	AudioManager.PlayVictory()

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

# Forwards visual ordering changes for gameplay-owned Hint availability checks.
func _on_step_order_changed() -> void:
	orderChanged.emit()

#endregion
