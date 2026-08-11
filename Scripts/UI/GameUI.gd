## Presents Game Scene state and forwards player requests to GameManager.
##
## This script owns node references, button bindings, card presentation, and
## visual feedback. It does not make gameplay or answer-validation decisions.
extends Node

#region ========== Signals ==========

signal checkRequested
signal hintRequested
signal retryRequested
signal nextLevelRequested
signal lobbyRequested
signal orderChanged
signal choiceSelected(choiceText: String)
signal tutorialDismissed
signal tutorialRequested
signal reviewMistakesRequested

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
@onready var fillModeScroll: ScrollContainer = $"../MainMargin/MainLayout/FillModeScroll"
@onready var fillModeArea: VBoxContainer = $"../MainMargin/MainLayout/FillModeScroll/FillModeArea"
@onready var mainMargin: MarginContainer = $"../MainMargin"
@onready var mainLayout: VBoxContainer = $"../MainMargin/MainLayout"
@onready var questionPanel: PanelContainer = $"../MainMargin/MainLayout/QuestionPanel"
@onready var optionTopSpacer: Control = $"../MainMargin/MainLayout/OptionTopSpacer"
@onready var levelTitleLabel: Label = $"../MainMargin/MainLayout/TopBar/LevelTitleLabel"
@onready var progressLabel: Label = $"../MainMargin/MainLayout/TopBar/ProgressGroup/ProgressLabel"
@onready var progressBar: ProgressBar = $"../MainMargin/MainLayout/TopBar/ProgressGroup/ProgressBar"
@onready var scoreLabel: Label = $"../MainMargin/MainLayout/TopBar/ScoreGroup/ScoreLabel"
@onready var scoreGainLabel: Label = $"../MainMargin/MainLayout/TopBar/ScoreGroup/ScoreGainLabel"
@onready var ruleLabel: Label = $"../MainMargin/MainLayout/RuleLabel"
@onready var equationLabel: Label = $"../MainMargin/MainLayout/QuestionPanel/CenterContainer/EquationLabel"
@onready var feedbackLabel: Label = $"../MainMargin/MainLayout/FeedbackLabel"
@onready var hintButton: Button = $"../MainMargin/MainLayout/BottomBar/HintButton"
@onready var checkButton: Button = $"../MainMargin/MainLayout/BottomBar/CheckButton"
@onready var topLobbyButton: Button = $"../MainMargin/MainLayout/TopBar/LobbyButton"
@onready var tutorialButton: Button = $"../MainMargin/MainLayout/TopBar/TutorialButton"
@onready var settingsButton: Button = $"../MainMargin/MainLayout/TopBar/SettingsButton"
@onready var endMenu: PanelContainer = $"../EndMenu"
@onready var completeLabel: Label = $"../EndMenu/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/CompleteLabel"
@onready var completeIcon: TextureRect = $"../EndMenu/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/CompleteIcon"
@onready var starsLabel: Label = $"../EndMenu/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/StarsLabel"
@onready var resultLabel: Label = $"../EndMenu/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ResultLabel"
@onready var sessionMetaLabel: Label = $"../EndMenu/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/SessionMetaLabel"
@onready var statsLabel: Label = $"../EndMenu/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/StatsLabel"
@onready var bestScoreLabel: Label = $"../EndMenu/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/BestScoreLabel"
@onready var newBestLabel: Label = $"../EndMenu/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/NewBestLabel"
@onready var nextLevelButton: Button = $"../EndMenu/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/NextLevelButton"
@onready var retryButton: Button = $"../EndMenu/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/RetryButton"
@onready var reviewMistakesButton: Button = $"../EndMenu/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/ReviewMistakesButton"
@onready var lobbyButton: Button = $"../EndMenu/CenterContainer/PanelContainer/MarginContainer/VBoxContainer/LobbyButton"
@onready var tutorialOverlay: PanelContainer = $"../TutorialOverlay"
@onready var tutorialTitleLabel: Label = $"../TutorialOverlay/CenterContainer/PanelContainer/MarginContainer/Content/TutorialTitleLabel"
@onready var tutorialInstructionsLabel: Label = $"../TutorialOverlay/CenterContainer/PanelContainer/MarginContainer/Content/TutorialInstructionsLabel"
@onready var closeTutorialButton: Button = $"../TutorialOverlay/CenterContainer/PanelContainer/MarginContainer/Content/Actions/CloseButton"
@onready var settingsPanel = $"../SettingsPanel"

#endregion

#region ========== Variables ==========

var fillInputs: Dictionary = {}
var displayedLevelScore: int = 0
var scoreTween: Tween = null

#endregion

#region ========== Godot Functions ==========

# Connects scene controls to UI request signals.
func _ready() -> void:
	hintButton.pressed.connect(_on_hint_button_pressed)
	checkButton.pressed.connect(_on_check_button_pressed)
	topLobbyButton.pressed.connect(_on_lobby_button_pressed)
	tutorialButton.pressed.connect(_on_tutorial_button_pressed)
	settingsButton.pressed.connect(settingsPanel.Open)
	retryButton.pressed.connect(_on_retry_button_pressed)
	nextLevelButton.pressed.connect(_on_next_level_button_pressed)
	reviewMistakesButton.pressed.connect(_on_review_mistakes_button_pressed)
	lobbyButton.pressed.connect(_on_lobby_button_pressed)
	closeTutorialButton.pressed.connect(_on_close_tutorial_button_pressed)
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
	ConfigureGameplayMode("step_ordering")
	SetupQuestionHeader(levelTitle, ruleText, expression, questionNumber, questionCount)
	feedbackLabel.text = tr("Arrange the solution steps in the correct order.")
	hintButton.disabled = false
	checkButton.visible = true
	checkButton.disabled = false
	checkButton.text = tr("Check")
	CreateStepCards(steps)

# Displays a newly loaded Multiple-Choice question and clears prior stages.
func ShowMultipleChoiceQuestion(
	levelTitle: String,
	ruleText: String,
	expression: String,
	questionNumber: int,
	questionCount: int
) -> void:
	ConfigureGameplayMode("multiple_choice_ordering")
	SetupQuestionHeader(levelTitle, ruleText, expression, questionNumber, questionCount)
	feedbackLabel.text = tr("Choose the next correct solution step.")
	hintButton.disabled = false
	checkButton.visible = false
	checkButton.disabled = true
	checkButton.text = tr("Check")
	ClearResolvedSteps()
	ClearChoiceButtons()

# Displays a generated Fill-in process while preserving the shared solution order.
func ShowFillProcessQuestion(
	levelTitle: String,
	ruleText: String,
	expression: String,
	questionNumber: int,
	questionCount: int,
	fillStepData: Array
) -> void:
	ConfigureGameplayMode("fill_in_process")
	SetupQuestionHeader(levelTitle, ruleText, expression, questionNumber, questionCount)
	feedbackLabel.text = tr("Complete the missing values in the solution process.")
	hintButton.disabled = false
	checkButton.visible = true
	checkButton.disabled = false
	checkButton.text = tr("Check")
	CreateFillProcess(fillStepData)

# Applies header content shared by every gameplay interaction mode.
func SetupQuestionHeader(
	levelTitle: String,
	ruleText: String,
	expression: String,
	questionNumber: int,
	questionCount: int
) -> void:
	levelTitleLabel.text = tr(levelTitle)
	ruleLabel.text = tr(ruleText)
	equationLabel.text = expression
	progressLabel.text = "%d/%d" % [questionNumber, questionCount]
	progressBar.max_value = questionCount
	progressBar.value = questionNumber

# Displays only points already earned by completing Questions.
func UpdateScore(_currentScore: int, levelScore: int) -> void:
	var earnedScore := levelScore - displayedLevelScore
	displayedLevelScore = levelScore
	scoreLabel.text = "%s %d" % [tr("Score"), levelScore]

	if earnedScore > 0:
		PlayScoreGainAnimation(earnedScore)
	else:
		scoreGainLabel.visible = false

# Briefly celebrates newly committed points without obstructing gameplay.
func PlayScoreGainAnimation(earnedScore: int) -> void:
	if scoreTween and scoreTween.is_valid():
		scoreTween.kill()

	scoreGainLabel.text = "+%d" % earnedScore
	scoreGainLabel.visible = true
	scoreGainLabel.modulate = Color(1, 1, 1, 0)
	scoreGainLabel.scale = Vector2(0.82, 0.82)
	scoreLabel.pivot_offset = scoreLabel.size * 0.5
	scoreLabel.scale = Vector2.ONE

	# Fade and pop the earned amount, then restore the compact score display.
	scoreTween = create_tween().set_parallel(true)
	scoreTween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	scoreTween.tween_property(scoreGainLabel, "modulate:a", 1.0, 0.18)
	scoreTween.tween_property(scoreGainLabel, "scale", Vector2.ONE, 0.18)
	scoreTween.tween_property(scoreLabel, "scale", Vector2(1.08, 1.08), 0.18)
	scoreTween.chain().set_parallel(true)
	scoreTween.tween_property(scoreGainLabel, "modulate:a", 0.0, 0.45).set_delay(0.35)
	scoreTween.tween_property(scoreLabel, "scale", Vector2.ONE, 0.25).set_delay(0.2)
	scoreTween.chain().tween_callback(scoreGainLabel.hide)

# Switches between the existing drag area and Multiple-Choice presentation.
func ConfigureGameplayMode(levelTypeId: String) -> void:
	stepScroll.visible = levelTypeId == "step_ordering"
	choiceModeScroll.visible = levelTypeId == "multiple_choice_ordering"
	fillModeScroll.visible = levelTypeId == "fill_in_process"
	optionTopSpacer.visible = levelTypeId != "multiple_choice_ordering"

# Rebuilds the step area from the supplied display order.
func CreateStepCards(steps: Array[String]) -> void:
	ClearStepCards()

	# Instantiate one reusable visual card for each generated step.
	for _stepIndex in range(steps.size()):
		var stepCard := STEP_CARD_SCENE.instantiate()
		stepArea.add_child(stepCard)
		stepCard.Setup(steps[_stepIndex])
		stepCard.SetInteractionLocked(false)

# Removes all cards from the current question display.
func ClearStepCards() -> void:
	stepArea.StopCardPositionTweens()

	for child in stepArea.get_children():
		stepArea.remove_child(child)
		child.queue_free()

# Displays the candidates for one solution stage in randomized order.
func ShowChoiceStage(stageIndex: int, stageCount: int, choices: Array[String]) -> void:
	stageLabel.text = tr("CHOOSE_STEP_FORMAT") % [stageIndex + 1, stageCount]
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
func ShowIncorrectChoice(choiceText: String, feedbackMessage: String) -> void:
	for choiceButton in choiceGrid.get_children():
		if choiceButton.get_meta("choiceText", "") == choiceText:
			choiceButton.disabled = true
			choiceButton.modulate = Color(1, 0.48, 0.48, 0.78)
			break

	feedbackLabel.text = tr(feedbackMessage)
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

# Builds ordered process lines and inserts numeric inputs between text segments.
func CreateFillProcess(fillStepData: Array) -> void:
	ClearFillProcess()

	for stepData in fillStepData:
		var stepAnchor := Control.new()
		stepAnchor.custom_minimum_size = Vector2(0, 54)
		stepAnchor.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		fillModeArea.add_child(stepAnchor)
		var stepRow := HBoxContainer.new()
		stepRow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		stepRow.anchor_left = 0.5
		stepRow.offset_left = -112.0
		stepRow.add_theme_constant_override("separation", 6)
		stepAnchor.add_child(stepRow)
		var segments: Array = stepData["segments"]
		var blankIds: Array = stepData["blankIds"]

		for blankIndex in range(blankIds.size()):
			AddFillTextSegment(stepRow, segments[blankIndex])
			var blankId: String = blankIds[blankIndex]
			var fillInput := LineEdit.new()
			fillInput.custom_minimum_size = Vector2(84, 42)
			fillInput.max_length = 8
			fillInput.placeholder_text = "?"
			fillInput.alignment = HORIZONTAL_ALIGNMENT_CENTER
			fillInput.add_theme_font_size_override("font_size", 18)
			ApplyFillInputState(fillInput, "empty")
			fillInput.text_changed.connect(_on_fill_input_text_changed.bind(fillInput))
			stepRow.add_child(fillInput)
			fillInputs[blankId] = fillInput

		AddFillTextSegment(stepRow, segments.back())

	if not fillInputs.is_empty():
		fillInputs.values()[0].grab_focus()

# Adds one immutable expression segment around Fill-in inputs.
func AddFillTextSegment(stepRow: HBoxContainer, segmentText: String) -> void:
	if segmentText.is_empty():
		return

	var segmentLabel := Label.new()
	segmentLabel.text = segmentText
	segmentLabel.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	segmentLabel.add_theme_font_size_override("font_size", 19)
	stepRow.add_child(segmentLabel)

# Returns current player entries keyed by generated blank ID.
func GetFillAnswers() -> Dictionary:
	var enteredAnswers: Dictionary = {}

	for blankId in fillInputs:
		enteredAnswers[blankId] = fillInputs[blankId].text.strip_edges()

	return enteredAnswers

# Applies correct, incorrect, and empty states after one Check request.
func ShowFillValidation(
	correctBlankIds: Array[String],
	incorrectBlankIds: Array[String],
	feedbackMessage: String
) -> void:
	for blankId in fillInputs:
		var fillInput: LineEdit = fillInputs[blankId]

		if blankId in correctBlankIds:
			fillInput.editable = false
			ApplyFillInputState(
				fillInput,
				"revealed" if fillInput.get_meta("revealedByHint", false) else "correct"
			)
		elif blankId in incorrectBlankIds:
			ApplyFillInputState(fillInput, "incorrect")
		else:
			ApplyFillInputState(fillInput, "empty")

	feedbackLabel.text = tr(feedbackMessage)
	AudioManager.PlayWrong()

# Locks every input in its correct state when the full process is complete.
func ShowFillComplete() -> void:
	for fillInput in fillInputs.values():
		fillInput.editable = false
		ApplyFillInputState(
			fillInput,
			"revealed" if fillInput.get_meta("revealedByHint", false) else "correct"
		)

	ShowCorrectAnswer()

# Reveals one missing value and marks it as supplied by Hint.
func RevealFillBlank(blankId: String, answer: String) -> void:
	if not fillInputs.has(blankId):
		return

	var fillInput: LineEdit = fillInputs[blankId]
	fillInput.text = answer
	fillInput.editable = false
	fillInput.set_meta("revealedByHint", true)
	ApplyFillInputState(fillInput, "revealed")
	feedbackLabel.text = tr("Hint: One missing value was revealed.")
	AudioManager.PlayHint()

# Clears all generated rows and input references before the next question.
func ClearFillProcess() -> void:
	fillInputs.clear()

	for child in fillModeArea.get_children():
		fillModeArea.remove_child(child)
		child.queue_free()

# Applies a compact visual state without moving answer logic into the UI.
func ApplyFillInputState(fillInput: LineEdit, state: String) -> void:
	var inputStyle := StyleBoxFlat.new()
	inputStyle.corner_radius_top_left = 10
	inputStyle.corner_radius_top_right = 10
	inputStyle.corner_radius_bottom_right = 10
	inputStyle.corner_radius_bottom_left = 10
	inputStyle.border_width_left = 1
	inputStyle.border_width_top = 1
	inputStyle.border_width_right = 1
	inputStyle.border_width_bottom = 1

	match state:
		"correct":
			inputStyle.bg_color = Color(0.06, 0.22, 0.17, 1)
			inputStyle.border_color = Color(0.3, 0.88, 0.65, 1)
		"incorrect":
			inputStyle.bg_color = Color(0.25, 0.075, 0.09, 1)
			inputStyle.border_color = Color(1, 0.38, 0.45, 1)
		"revealed":
			inputStyle.bg_color = Color(0.055, 0.17, 0.25, 1)
			inputStyle.border_color = Color(0.3, 0.75, 1, 1)
		_:
			inputStyle.bg_color = Color(0.055, 0.075, 0.12, 1)
			inputStyle.border_color = Color(0.2, 0.34, 0.5, 1)

	fillInput.add_theme_stylebox_override("normal", inputStyle)
	fillInput.add_theme_stylebox_override("read_only", inputStyle)
	var focusStyle: StyleBoxFlat = inputStyle.duplicate()
	focusStyle.border_width_left = 2
	focusStyle.border_width_top = 2
	focusStyle.border_width_right = 2
	focusStyle.border_width_bottom = 2
	focusStyle.border_color = Color(0.78, 0.9, 1, 1)
	fillInput.add_theme_stylebox_override("focus", focusStyle)

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
			stepArea.PreviewCardPosition(child, targetIndex, true)
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
	feedbackLabel.text = tr("Correct!")
	SetStepCardsLocked(true)
	hintButton.disabled = true
	checkButton.visible = true
	checkButton.disabled = false
	checkButton.text = tr("Next")

	if playAudio:
		AudioManager.PlayCorrect()

# Locks or unlocks every Step Ordering card without changing its appearance.
func SetStepCardsLocked(isLocked: bool) -> void:
	for stepCard in stepArea.get_children():
		stepCard.SetInteractionLocked(isLocked)

# Displays the visual state for an incorrect answer.
func ShowIncorrectAnswer(feedbackMessage: String) -> void:
	feedbackLabel.text = tr(feedbackMessage)
	AudioManager.PlayWrong()

# Displays feedback after a hint places one correct step.
func ShowHintUsed(revealedHintCount: int) -> void:
	feedbackLabel.text = tr("Hint: Step %d has been placed correctly.") % revealedHintCount
	AudioManager.PlayHint()

# Gives general ordering guidance without confirming the current answer state.
func ShowOrderingReviewHint() -> void:
	feedbackLabel.text = tr("Hint: Compare each step with the transformation before it.")
	AudioManager.PlayHint()

# Displays feedback after a Multiple-Choice Hint removes one distractor.
func ShowMultipleChoiceHintUsed() -> void:
	feedbackLabel.text = tr("Hint: One incorrect option was removed.")
	AudioManager.PlayHint()

# Enables or disables the hint control without changing gameplay state.
func SetHintAvailable(isAvailable: bool) -> void:
	hintButton.disabled = not isAvailable

# Displays the number of shared Hints remaining in the active Level.
func UpdateHintCount(remainingHintCount: int) -> void:
	hintButton.text = "%s (%d)" % [tr("Hint"), remainingHintCount]

# Displays a safe visual error state when gameplay data cannot be used.
func ShowDataError(message: String) -> void:
	feedbackLabel.text = message
	hintButton.disabled = true
	checkButton.disabled = true

# Displays the level completion overlay and result text.
func ShowEndMenu(summaryData: Dictionary) -> void:
	var levelScore: int = summaryData.get("score", 0)
	var maxLevelScore: int = summaryData.get("maxScore", 0)
	var scorePercentage: int = summaryData.get("percentage", 0)
	var starCount: int = summaryData.get("stars", 0)
	var levelCompleted := starCount >= 1
	completeLabel.text = tr("LEVEL COMPLETE") if levelCompleted else tr("NEEDS PRACTICE")
	completeLabel.add_theme_color_override(
		"font_color",
		Color(0.45, 0.82, 1, 1) if levelCompleted else Color(1, 0.68, 0.34, 1)
	)
	completeIcon.modulate = (
		Color(0.35, 0.9, 0.72, 1) if levelCompleted else Color(1, 0.68, 0.34, 1)
	)
	completeIcon.visible = levelCompleted
	starsLabel.text = "★".repeat(starCount) + "☆".repeat(3 - starCount)
	sessionMetaLabel.text = "%s\n%s" % [
		tr(summaryData.get("levelTitle", "Untitled Level")),
		tr(summaryData.get("levelTypeTitle", "Unknown Mode"))
	]
	resultLabel.text = "%s %d / %d  •  %d%%" % [tr("Score"), levelScore, maxLevelScore, scorePercentage]
	statsLabel.text = (
		"%s     %d / %d\n%s       %d\n%s               %d"
		% [
			tr("Questions Completed"),
			summaryData.get("questionsCompleted", 0),
			summaryData.get("questionCount", 0),
			tr("Incorrect Attempts"),
			summaryData.get("incorrectAttempts", 0),
			tr("Hints Used"),
			summaryData.get("hintsUsed", 0)
		]
	)
	bestScoreLabel.text = "%s  %d / %d" % [
		tr("Best Score"),
		summaryData.get("bestScore", levelScore),
		maxLevelScore
	]
	newBestLabel.text = tr("NEW BEST")
	newBestLabel.visible = summaryData.get("isNewBest", false)
	nextLevelButton.visible = levelCompleted and summaryData.get("hasNextLevel", false)
	retryButton.text = tr("Play Again") if levelCompleted else tr("Try Again")
	endMenu.visible = true

	if levelCompleted:
		AudioManager.PlayVictory()

# Hides the level completion overlay before gameplay restarts.
func HideEndMenu() -> void:
	endMenu.visible = false

# Presents interaction-only guidance over the newly loaded gameplay screen.
func ShowTutorial(tutorialTitle: String, instructions: String) -> void:
	tutorialTitleLabel.text = tr(tutorialTitle)
	tutorialInstructionsLabel.text = tr(instructions).replace("\\n", "\n")
	tutorialOverlay.visible = true
	closeTutorialButton.grab_focus()

# Closes the current tutorial before notifying its persistent state owner.
func HideTutorial() -> void:
	tutorialOverlay.visible = false

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

# Forwards the next-Level request to the gameplay owner.
func _on_next_level_button_pressed() -> void:
	nextLevelRequested.emit()

# Opens the persistent Mistake Book from the completed-session summary.
func _on_review_mistakes_button_pressed() -> void:
	reviewMistakesRequested.emit()

# Forwards the Lobby request to GameManager.
func _on_lobby_button_pressed() -> void:
	lobbyRequested.emit()

# Forwards visual ordering changes for gameplay-owned Hint availability checks.
func _on_step_order_changed() -> void:
	orderChanged.emit()

# Forwards one visual candidate selection to GameManager for validation.
func _on_choice_button_pressed(choiceText: String) -> void:
	choiceSelected.emit(choiceText)

# Closes either tutorial action and records that the mode has been viewed.
func _on_close_tutorial_button_pressed() -> void:
	HideTutorial()
	tutorialDismissed.emit()

# Requests the current Level Type tutorial independently of first-view state.
func _on_tutorial_button_pressed() -> void:
	tutorialRequested.emit()

# Restricts Fill-in fields to whole-number input with one optional leading minus.
func _on_fill_input_text_changed(newText: String, fillInput: LineEdit) -> void:
	var filteredText := ""

	for characterIndex in range(newText.length()):
		var character := newText[characterIndex]

		if character.is_valid_int() or (character == "-" and characterIndex == 0):
			filteredText += character

	if filteredText == newText:
		return

	fillInput.text = filteredText
	fillInput.caret_column = filteredText.length()

#endregion
