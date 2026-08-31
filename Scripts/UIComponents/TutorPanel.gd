## Presents MathSmith's reusable option-based Tutor interface.
##
## This component owns panel interaction and page history only. Tutor services
## will provide deterministic responses, options, context, and navigation.
extends Control

#region ========== Signals ==========

signal optionSelected(actionId: String)
signal closed

#endregion

#region ========== References ==========

@onready var tutorCard: PanelContainer = %TutorCard
@onready var contextLabel: Label = %ContextLabel
@onready var responseTitleLabel: Label = %ResponseTitleLabel
@onready var responseLabel: Label = %ResponseLabel
@onready var optionLabel: Label = %OptionLabel
@onready var optionList: VBoxContainer = %OptionList
@onready var backButton: Button = %BackButton
@onready var previousButton: Button = %PreviousButton
@onready var closeButton: Button = %CloseButton

#endregion

#region ========== Variables ==========

var pageStack: Array[Dictionary] = []
var responseHistory: Array[Dictionary] = []
var previousHistoryIndex: int = -1

#endregion

#region ========== Godot Functions ==========

# Binds navigation controls and keeps the drawer responsive.
func _ready() -> void:
	backButton.pressed.connect(GoBack)
	previousButton.pressed.connect(ShowPreviousResponse)
	closeButton.pressed.connect(Close)
	LocalizationManager.languageChanged.connect(_on_language_changed)
	get_viewport().size_changed.connect(UpdateResponsiveLayout)
	UpdateResponsiveLayout()

#endregion

#region ========== Functions ==========

# Opens one caller-provided page or the temporary core-UI validation page.
func Open(initialPage: Dictionary = {}) -> void:
	visible = true
	pageStack.clear()
	responseHistory.clear()
	previousHistoryIndex = -1
	var openingPage := initialPage
	if openingPage.is_empty():
		openingPage = CreateValidationPage()
	ShowPage(openingPage, true)

# Closes the Tutor without changing any game or navigation state.
func Close() -> void:
	visible = false
	closed.emit()

# Displays one structured response and optionally adds it to Back history.
func ShowPage(pageData: Dictionary, rememberPage: bool = true) -> void:
	if rememberPage:
		pageStack.append(pageData.duplicate(true))
	responseHistory.append(pageData.duplicate(true))
	previousHistoryIndex = responseHistory.size() - 1
	RenderPage(pageData)

# Returns to the parent option page without closing the Tutor.
func GoBack() -> void:
	if pageStack.size() <= 1:
		return
	pageStack.pop_back()
	var parentPage: Dictionary = pageStack.back()
	responseHistory.append(parentPage.duplicate(true))
	previousHistoryIndex = responseHistory.size() - 1
	RenderPage(parentPage)

# Reviews an earlier response without changing the current option branch.
func ShowPreviousResponse() -> void:
	if previousHistoryIndex <= 0:
		return
	previousHistoryIndex -= 1
	RenderPage(responseHistory[previousHistoryIndex])

# Draws text and context-aware options from one stable page contract.
func RenderPage(pageData: Dictionary) -> void:
	contextLabel.text = tr(String(pageData.get("contextLabel", "GUIDED TUTOR")))
	responseTitleLabel.text = tr(String(pageData.get("title", "MathSmith Tutor")))
	responseLabel.text = tr(String(pageData.get("response", "")))
	ClearOptions()
	var pageOptions: Array = pageData.get("options", [])
	optionLabel.visible = not pageOptions.is_empty()

	for optionValue in pageOptions:
		var optionData: Dictionary = optionValue
		var optionButton := Button.new()
		optionButton.custom_minimum_size = Vector2(0, 54)
		optionButton.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		optionButton.alignment = HORIZONTAL_ALIGNMENT_LEFT
		optionButton.focus_mode = Control.FOCUS_ALL
		optionButton.text = tr(String(optionData.get("label", "Continue")))
		optionButton.tooltip_text = optionButton.text
		optionButton.pressed.connect(SelectOption.bind(optionData))
		optionList.add_child(optionButton)

	backButton.disabled = pageStack.size() <= 1
	previousButton.disabled = previousHistoryIndex <= 0

# Emits the stable action ID and previews UI history until Tutor logic connects.
func SelectOption(optionData: Dictionary) -> void:
	var actionId: String = optionData.get("actionId", "")
	optionSelected.emit(actionId)
	var nextPage: Dictionary = optionData.get("nextPage", {})
	if not nextPage.is_empty():
		ShowPage(nextPage, true)

# Removes generated buttons before another response is rendered.
func ClearOptions() -> void:
	for optionButton in optionList.get_children():
		optionButton.queue_free()

# Keeps the drawer readable without covering the complete viewport.
func UpdateResponsiveLayout() -> void:
	var viewportSize := get_viewport_rect().size
	var panelWidth := minf(480.0, maxf(340.0, viewportSize.x - 120.0))
	var panelHeight := minf(650.0, maxf(480.0, viewportSize.y * 0.76))

	# Align the lower-right speech corner directly above the floating Tutor bubble.
	tutorCard.offset_right = -66.0
	tutorCard.offset_left = tutorCard.offset_right - panelWidth
	tutorCard.offset_bottom = -28.0
	tutorCard.offset_top = tutorCard.offset_bottom - panelHeight

# Supports keyboard dismissal without changing the current gameplay state.
func _unhandled_key_input(event: InputEvent) -> void:
	if visible and event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Close()
		get_viewport().set_input_as_handled()

# Refreshes the visible page when Settings changes the active locale.
func _on_language_changed(_localeCode: String) -> void:
	if visible and not responseHistory.is_empty():
		RenderPage(responseHistory[previousHistoryIndex])

# Creates a deterministic placeholder used only to validate the core UI flow.
func CreateValidationPage() -> Dictionary:
	return {
		"contextLabel": tr("HOME"),
		"title": tr("How can I help?"),
		"response": tr("Choose a topic. MathSmith Tutor uses game data and guided options instead of free-form chat."),
		"options": [
			{
				"actionId": "validation_about",
				"label": tr("What is MathSmith?"),
				"nextPage": {
					"contextLabel": tr("HOME"),
					"title": tr("Learn the process"),
					"response": tr("MathSmith helps you rebuild the reasoning behind arithmetic, one step at a time."),
					"options": []
				}
			},
			{
				"actionId": "validation_modes",
				"label": tr("How do the game modes work?"),
				"nextPage": {
					"contextLabel": tr("HOME"),
					"title": tr("Three guided modes"),
					"response": tr("You can order solution steps, choose each next step, or fill missing values in a process."),
					"options": []
				}
			}
		]
	}

#endregion
