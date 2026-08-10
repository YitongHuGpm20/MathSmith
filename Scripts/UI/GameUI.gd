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
signal choiceSelected(choiceText: String)

#endregion

#region ========== Constants ==========

const STEP_CARD_SCENE: PackedScene = preload("res://Scenes/Menus/StepCard.tscn")

#endregion

#region ========== References ==========

@onready var stepArea = $"../MainMargin/MainLayout/StepScroll/StepArea"
@onready var stepScroll: ScrollContainer = $"../MainMargin/MainLayout/StepScroll"
@onready var choiceModeScroll: ScrollContainer = $"../MainMargin/MainLayout/ChoiceModeScroll"
@onready var stageLabel: Label = $"../MainMargin/MainLayout/ChoiceModeScroll/ChoiceModeArea/StageLabel"
@onready var resolvedSteps: VBoxContainer = $"../MainMargin/MainLayout/ChoiceModeScroll/ChoiceModeArea/ResolvedSteps"
@onready var choiceSeparator: HSeparator = $"../MainMargin/MainLayout/ChoiceModeScroll/ChoiceModeArea/ChoiceSeparator"
@onready var choiceGrid: GridContainer = $"../MainMargin/MainLayout/ChoiceModeScroll/ChoiceModeArea/ChoiceGrid"
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
	ConfigureGameplayMode(true)
	SetupQuestionHeader(levelTitle, ruleText, expression, questionNumber, questionCount)
	feedbackLabel.text = "Arrange the solution steps in the correct order."
	hintButton.disabled = false
	checkButton.visible = true
	checkButton.disabled = false
	checkButton.text = "Check"
	CreateStepCards(steps)

# Displays a newly loaded Multiple-Choice question and clears prior stages.
func ShowMultipleChoiceQuestion(
	levelTitle: String,
	ruleText: String,
	expression: String,
	questionNumber: int,
	questionCount: int
) -> void:
	ConfigureGameplayMode(false)
	SetupQuestionHeader(levelTitle, ruleText, expression, questionNumber, questionCount)
	feedbackLabel.text = "Choose the next correct solution step."
	hintButton.disabled = false
	checkButton.visible = false
	checkButton.disabled = true
	checkButton.text = "Check"
	ClearResolvedSteps()
	ClearChoiceButtons()

# Applies header content shared by every gameplay interaction mode.
func SetupQuestionHeader(
	levelTitle: String,
	ruleText: String,
	expression: String,
	questionNumber: int,
	questionCount: int
) -> void:
	levelTitleLabel.text = levelTitle
	ruleLabel.text = ruleText
	equationLabel.text = expression
	progressLabel.text = "%d/%d" % [questionNumber, questionCount]

# Switches between the existing drag area and Multiple-Choice presentation.
func ConfigureGameplayMode(showStepOrdering: bool) -> void:
	stepScroll.visible = showStepOrdering
	choiceModeScroll.visible = not showStepOrdering

# Rebuilds the step area from the supplied display order.
func CreateStepCards(steps: Array[String]) -> void:
	ClearStepCards()

	# Instantiate one reusable visual card for each generated step.
	for _stepIndex in range(steps.size()):
		var stepCard := STEP_CARD_SCENE.instantiate()
		stepArea.add_child(stepCard)
		stepCard.Setup(steps[_stepIndex])

# Removes all cards from the current question display.
func ClearStepCards() -> void:
	for child in stepArea.get_children():
		child.queue_free()

# Displays the candidates for one solution stage in randomized order.
func ShowChoiceStage(stageIndex: int, stageCount: int, choices: Array[String]) -> void:
	stageLabel.text = "Choose step %d of %d" % [stageIndex + 1, stageCount]
	choiceSeparator.visible = true
	ClearChoiceButtons()

	for choiceText in choices:
		var choiceButton := Button.new()
		choiceButton.custom_minimum_size = Vector2(0, 58)
		choiceButton.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		choiceButton.text = choiceText
		choiceButton.set_meta("choiceText", choiceText)
		choiceButton.pressed.connect(_on_choice_button_pressed.bind(choiceText))
		choiceGrid.add_child(choiceButton)

# Clears the final candidate set after the complete process has been resolved.
func ShowMultipleChoiceComplete() -> void:
	ClearChoiceButtons()
	stageLabel.text = "Solution complete"
	choiceSeparator.visible = false
	ShowCorrectAnswer(false)

# Adds one resolved Step above the remaining candidates.
func AddResolvedChoiceStep(stepText: String) -> void:
	var resolvedLabel := Label.new()
	resolvedLabel.custom_minimum_size = Vector2(0, 42)
	resolvedLabel.text = stepText
	resolvedLabel.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	resolvedLabel.add_theme_color_override("font_color", Color(0.48, 0.92, 0.76, 1))
	resolvedLabel.add_theme_font_size_override("font_size", 17)
	resolvedSteps.add_child(resolvedLabel)
	AudioManager.PlayCorrect()

# Marks an incorrect candidate while keeping the remaining choices available.
func ShowIncorrectChoice(choiceText: String) -> void:
	for choiceButton in choiceGrid.get_children():
		if choiceButton.get_meta("choiceText", "") == choiceText:
			choiceButton.disabled = true
			choiceButton.modulate = Color(1, 0.48, 0.48, 0.78)
			break

	feedbackLabel.text = "That step does not follow here. Try another option."
	AudioManager.PlayWrong()

# Removes one incorrect candidate as the Multiple-Choice Hint action.
func RemoveChoiceOption(choiceText: String) -> void:
	for choiceButton in choiceGrid.get_children():
		if choiceButton.get_meta("choiceText", "") == choiceText:
			choiceButton.visible = false
			choiceButton.disabled = true
			break

# Removes prior question choices immediately before rebuilding the stage.
func ClearChoiceButtons() -> void:
	for child in choiceGrid.get_children():
		choiceGrid.remove_child(child)
		child.queue_free()

# Removes the accumulated correct process before a new question loads.
func ClearResolvedSteps() -> void:
	for child in resolvedSteps.get_children():
		resolvedSteps.remove_child(child)
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
	choiceGrid.columns = 1 if viewportSize.x < 900.0 else 2
	questionPanel.custom_minimum_size.y = 70.0 if compactLayout else 92.0

# Displays the visual state for a correct answer.
func ShowCorrectAnswer(playAudio: bool = true) -> void:
	feedbackLabel.text = "Correct!"
	hintButton.disabled = true
	checkButton.visible = true
	checkButton.disabled = false
	checkButton.text = "Next"

	if playAudio:
		AudioManager.PlayCorrect()

# Displays the visual state for an incorrect answer.
func ShowIncorrectAnswer() -> void:
	feedbackLabel.text = "Not quite. Try again."
	AudioManager.PlayWrong()

# Displays feedback after a hint places one correct step.
func ShowHintUsed(revealedHintCount: int) -> void:
	feedbackLabel.text = "Hint: Step %d has been placed correctly." % revealedHintCount
	AudioManager.PlayHint()

# Displays feedback after a Multiple-Choice Hint removes one distractor.
func ShowMultipleChoiceHintUsed() -> void:
	feedbackLabel.text = "Hint: One incorrect option was removed."
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

# Forwards one visual candidate selection to GameManager for validation.
func _on_choice_button_pressed(choiceText: String) -> void:
	choiceSelected.emit(choiceText)

#endregion
