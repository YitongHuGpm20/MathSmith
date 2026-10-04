## Presents MathSmith's reusable option-based Tutor interface.
##
## This component owns panel interaction and page history only. Tutor services
## will provide deterministic responses, options, context, and navigation.
extends Control

#region ========== Constants ==========

const NAVIGATION_ICON: Texture2D = preload("res://Assets/Icons/external-link.svg")
const SPEAKER_ICON: Texture2D = preload("res://Assets/Icons/volume.svg")

#endregion

#region ========== Signals ==========

signal optionSelected(actionId: String)
signal messageSubmitted(userMessage: String)
signal closed

#endregion

#region ========== References ==========

@onready var tutorCard: PanelContainer = %TutorCard
@onready var contextLabel: Label = %ContextLabel
@onready var guidedModeButton: Button = %GuidedModeButton
@onready var chatModeButton: Button = %ChatModeButton
@onready var responseTitleLabel: Label = %ResponseTitleLabel
@onready var responseLabel: Label = %ResponseLabel
@onready var optionLabel: Label = %OptionLabel
@onready var optionList: VBoxContainer = %OptionList
@onready var conversationLabel: Label = %ConversationLabel
@onready var conversationList: VBoxContainer = %ConversationList
@onready var requestStatusLabel: Label = %RequestStatusLabel
@onready var suggestedActionButton: Button = %SuggestedActionButton
@onready var composer: HBoxContainer = %Composer
@onready var messageInput: LineEdit = %MessageInput
@onready var voiceInputButton: Button = %VoiceInputButton
@onready var sendButton: Button = %SendButton
@onready var retryButton: Button = %RetryButton
@onready var backButton: Button = %BackButton
@onready var previousButton: Button = %PreviousButton
@onready var closeButton: Button = %CloseButton

#endregion

#region ========== Variables ==========

var pageStack: Array[Dictionary] = []
var responseHistory: Array[Dictionary] = []
var previousHistoryIndex: int = -1
var lastSubmittedMessage: String = ""
var requestPending: bool = false
var requestStateId: String = "idle"
var currentInterfaceMode: String = "guided"
var currentSuggestedAction: Dictionary = {}
var speechInputManager := preload(
	"res://Scripts/Learning/TutorSpeechInputManager.gd"
).new()
var voiceListening: bool = false
var speechStateId: String = "idle"
var speechOutputManager := preload(
	"res://Scripts/Learning/TutorSpeechOutputManager.gd"
).new()
var activeSpeechButton: Button = null
var tutorVoiceSpeaking: bool = false

#endregion

#region ========== Godot Functions ==========

# Binds navigation controls and keeps the drawer responsive.
func _ready() -> void:
	backButton.pressed.connect(GoBack)
	previousButton.pressed.connect(ShowPreviousResponse)
	closeButton.pressed.connect(Close)
	suggestedActionButton.pressed.connect(SelectSuggestedAction)
	suggestedActionButton.icon = NAVIGATION_ICON
	guidedModeButton.pressed.connect(SetInterfaceMode.bind("guided"))
	chatModeButton.pressed.connect(SetInterfaceMode.bind("chat"))
	sendButton.pressed.connect(SubmitCurrentMessage)
	voiceInputButton.pressed.connect(ToggleVoiceInput)
	retryButton.pressed.connect(RetryLastMessage)
	messageInput.text_submitted.connect(_on_message_input_submitted)
	messageInput.text_changed.connect(_on_message_input_changed)
	LocalizationManager.languageChanged.connect(_on_language_changed)
	GameManager.tutorSettingsChanged.connect(_on_tutor_settings_changed)
	GameManager.tutorConversationCleared.connect(ClearConversationDisplay)
	get_viewport().size_changed.connect(UpdateResponsiveLayout)
	UpdateResponsiveLayout()
	UpdateComposerState()
	SetInterfaceMode("guided")
	RefreshTutorSettings()
	set_process(false)

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
	SetInterfaceMode("guided")

# Closes the Tutor without changing any game or navigation state.
func Close() -> void:
	if voiceListening:
		StopVoiceInput()
	StopTutorVoice()
	messageInput.release_focus()
	visible = false
	closed.emit()

# Starts or stops one explicit Push-to-Talk recognition session.
func ToggleVoiceInput() -> void:
	if requestPending:
		return
	if voiceListening:
		StopVoiceInput()
		return
	var speechState := speechInputManager.StartListening(TranslationServer.get_locale())
	HandleSpeechInputState(speechState)

# Stops recording while leaving recognized text editable and unsent.
func StopVoiceInput() -> void:
	HandleSpeechInputState(speechInputManager.StopListening())

# Applies normalized provider states without exposing browser error details.
func HandleSpeechInputState(speechState: Dictionary) -> void:
	var status: String = speechState.get("status", "error")
	speechStateId = status
	match status:
		"listening", "processing":
			voiceListening = true
			voiceInputButton.theme_type_variation = &"ButtonPrimary"
			requestStatusLabel.text = tr(
				"Listening... Press the microphone again to stop."
				if status == "listening"
				else "Processing speech..."
			)
			requestStatusLabel.visible = currentInterfaceMode == "chat"
			set_process(true)
		"transcript":
			voiceListening = false
			voiceInputButton.theme_type_variation = &""
			messageInput.text = speechState.get("transcript", "")
			messageInput.caret_column = messageInput.text.length()
			requestStatusLabel.text = tr("Voice transcription ready. Review it before sending.")
			requestStatusLabel.visible = currentInterfaceMode == "chat"
			set_process(false)
			UpdateComposerState()
		"idle":
			voiceListening = false
			voiceInputButton.theme_type_variation = &""
			requestStatusLabel.visible = false
			set_process(false)
		_:
			voiceListening = false
			voiceInputButton.theme_type_variation = &""
			var errorCode: String = speechState.get("errorCode", "")
			requestStatusLabel.text = tr(
				"Microphone permission was denied. You can continue typing."
				if errorCode == "permission_denied"
				else "Voice input is unavailable. You can continue typing."
			)
			requestStatusLabel.visible = currentInterfaceMode == "chat"
			set_process(false)

# Polls asynchronous Web speech callbacks only during explicit listening.
func _process(_delta: float) -> void:
	if voiceListening:
		HandleSpeechInputState(speechInputManager.Poll())
	if tutorVoiceSpeaking and not speechOutputManager.IsSpeaking():
		ResetTutorVoiceState()
	set_process(voiceListening or tutorVoiceSpeaking)

# Separates deterministic guided choices from free-form text conversation.
func SetInterfaceMode(interfaceMode: String) -> void:
	if interfaceMode == "chat" and not GameManager.IsConversationalTutorEnabled():
		interfaceMode = "guided"
	currentInterfaceMode = "chat" if interfaceMode == "chat" else "guided"
	var showingChat := currentInterfaceMode == "chat"

	# Keep only the selected interaction surface visible and visually active.
	guidedModeButton.set_pressed_no_signal(not showingChat)
	chatModeButton.set_pressed_no_signal(showingChat)
	guidedModeButton.theme_type_variation = &"" if showingChat else &"ButtonPrimary"
	chatModeButton.theme_type_variation = &"ButtonPrimary" if showingChat else &""
	responseTitleLabel.visible = not showingChat
	responseLabel.visible = not showingChat
	optionLabel.visible = not showingChat and not optionList.get_children().is_empty()
	optionList.visible = not showingChat
	backButton.visible = not showingChat
	previousButton.visible = not showingChat
	conversationLabel.visible = showingChat
	conversationList.visible = showingChat
	composer.visible = showingChat
	requestStatusLabel.visible = (
		showingChat
		and (
			requestStateId != "idle"
			or speechStateId != "idle"
			or IsDevelopmentProvider()
		)
	)
	if showingChat and requestStateId == "idle" and speechStateId == "idle":
		requestStatusLabel.text = (
			tr("Development Mock — no live AI connection.")
			if IsDevelopmentProvider()
			else ""
		)
	suggestedActionButton.visible = showingChat and not currentSuggestedAction.is_empty()
	if showingChat:
		messageInput.grab_focus()
	else:
		messageInput.release_focus()

# Submits the current player text through the host screen's M8 request bridge.
func SubmitCurrentMessage() -> void:
	if requestPending:
		return
	var userMessage := messageInput.text.strip_edges()
	if userMessage.is_empty():
		return
	lastSubmittedMessage = userMessage
	messageInput.clear()
	speechStateId = "idle"
	SetSuggestedAction({})
	AppendConversationMessage("player", userMessage)
	SetRequestState("thinking")
	messageSubmitted.emit(userMessage)

# Replays the last failed request without adding a duplicate visible message.
func RetryLastMessage() -> void:
	if requestPending or lastSubmittedMessage.is_empty():
		return
	SetRequestState("thinking")
	messageSubmitted.emit(lastSubmittedMessage)

# Displays a normalized M8 result while leaving M7 options intact.
func ShowConversationResponse(responseData: Dictionary) -> void:
	if responseData.get("success", false):
		AppendConversationMessage("tutor", responseData.get("tutorText", ""))
		SetSuggestedAction(responseData.get("suggestedAction", {}))
		SetRequestState("idle")
		return
	SetRequestState("error")

# Displays only the action already normalized by TutorActionValidator.
func SetSuggestedAction(actionValue: Variant) -> void:
	currentSuggestedAction = actionValue.duplicate(true) if actionValue is Dictionary else {}
	if currentSuggestedAction.is_empty():
		suggestedActionButton.visible = false
		return
	suggestedActionButton.text = tr(String(currentSuggestedAction.get("label", "Continue")))
	suggestedActionButton.visible = currentInterfaceMode == "chat"

# Emits the trusted M7 action ID; GameManager remains the only executor.
func SelectSuggestedAction() -> void:
	var actionId: String = currentSuggestedAction.get("actionId", "")
	if actionId.is_empty():
		return
	SetSuggestedAction({})
	optionSelected.emit(actionId)

# Adds one visually distinct player or Tutor message to the current panel.
func AppendConversationMessage(role: String, messageText: String) -> void:
	if messageText.strip_edges().is_empty():
		return
	var messageRow := HBoxContainer.new()
	messageRow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	messageRow.add_theme_constant_override("separation", 8)
	var messageLabel := Label.new()
	messageLabel.text = messageText.strip_edges()
	messageLabel.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	messageLabel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	messageLabel.add_theme_font_size_override("font_size", 16)
	if role == "player":
		messageLabel.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		messageLabel.add_theme_color_override("font_color", Color(0.35, 0.8, 1.0, 1.0))
	else:
		messageLabel.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		messageLabel.add_theme_color_override("font_color", Color(0.76, 0.84, 0.92, 1.0))
	messageRow.add_child(messageLabel)
	if (
		role == "tutor"
		and GameManager.IsTutorVoiceEnabled()
		and speechOutputManager.GetStatus().get("supported", false)
	):
		var speechButton := Button.new()
		speechButton.custom_minimum_size = Vector2(36, 36)
		speechButton.icon = SPEAKER_ICON
		speechButton.tooltip_text = tr("Read aloud")
		speechButton.focus_mode = Control.FOCUS_ALL
		speechButton.set_meta("tutorVoiceButton", true)
		speechButton.pressed.connect(ToggleTutorVoice.bind(messageText, speechButton))
		messageRow.add_child(speechButton)
	conversationList.add_child(messageRow)
	conversationLabel.visible = currentInterfaceMode == "chat"
	conversationList.visible = currentInterfaceMode == "chat"

# Plays or stops one visible Tutor response without changing its text.
func ToggleTutorVoice(messageText: String, speechButton: Button) -> void:
	if not GameManager.IsTutorVoiceEnabled():
		return
	if tutorVoiceSpeaking and activeSpeechButton == speechButton:
		StopTutorVoice()
		return
	StopTutorVoice()
	var speechResult := speechOutputManager.Speak(
		messageText,
		TranslationServer.get_locale()
	)
	if not speechResult.get("success", false):
		requestStatusLabel.text = tr("Tutor voice is unavailable. The response remains readable.")
		requestStatusLabel.visible = currentInterfaceMode == "chat"
		return
	activeSpeechButton = speechButton
	tutorVoiceSpeaking = true
	speechButton.theme_type_variation = &"ButtonPrimary"
	speechButton.tooltip_text = tr("Stop voice")
	set_process(true)

# Stops current Tutor speech before another utterance or panel close.
func StopTutorVoice() -> void:
	speechOutputManager.Stop()
	ResetTutorVoiceState()

# Returns the active replay button to its normal visual state.
func ResetTutorVoiceState() -> void:
	if is_instance_valid(activeSpeechButton):
		activeSpeechButton.theme_type_variation = &""
		activeSpeechButton.tooltip_text = tr("Read aloud")
	activeSpeechButton = null
	tutorVoiceSpeaking = false

# Applies optional Tutor settings without rebuilding deterministic page state.
func RefreshTutorSettings() -> void:
	chatModeButton.disabled = not GameManager.IsConversationalTutorEnabled()
	if chatModeButton.disabled and currentInterfaceMode == "chat":
		SetInterfaceMode("guided")
	if not GameManager.IsTutorVoiceEnabled():
		StopTutorVoice()
	for messageRow in conversationList.get_children():
		for child in messageRow.get_children():
			if child is Button and child.get_meta("tutorVoiceButton", false):
				child.visible = GameManager.IsTutorVoiceEnabled()

# Clears visible transient chat when the conversation service is reset.
func ClearConversationDisplay() -> void:
	StopTutorVoice()
	for child in conversationList.get_children():
		child.queue_free()
	lastSubmittedMessage = ""
	SetSuggestedAction({})
	SetRequestState("idle")

# Exposes only non-secret runtime state to the developer overlay.
func GetTutorDiagnostics() -> Dictionary:
	return {
		"interfaceMode": currentInterfaceMode,
		"requestState": requestStateId,
		"suggestedActionId": currentSuggestedAction.get("actionId", ""),
		"speechInput": speechInputManager.GetStatus(),
		"speechOutput": speechOutputManager.GetStatus()
	}

# Applies the loading, ready, and retry states without blocking M7 controls.
func SetRequestState(stateId: String) -> void:
	requestStateId = stateId
	requestPending = stateId == "thinking"
	requestStatusLabel.visible = (
		currentInterfaceMode == "chat"
		and (stateId != "idle" or IsDevelopmentProvider())
	)
	retryButton.visible = stateId == "error"
	match stateId:
		"thinking":
			requestStatusLabel.text = tr("Tutor is thinking...")
		"error":
			requestStatusLabel.text = tr("Conversational Tutor is unavailable. Guided options still work.")
		_:
			requestStatusLabel.text = (
				tr("Development Mock — no live AI connection.")
				if IsDevelopmentProvider()
				else ""
			)
	UpdateComposerState()

# Enables Send only when a non-empty message can be submitted.
func UpdateComposerState() -> void:
	messageInput.editable = not requestPending and not voiceListening
	sendButton.disabled = (
		requestPending
		or voiceListening
		or messageInput.text.strip_edges().is_empty()
	)
	voiceInputButton.disabled = requestPending or not speechInputManager.GetStatus().get("supported", false)
	retryButton.disabled = requestPending

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
	optionLabel.visible = currentInterfaceMode == "guided" and not pageOptions.is_empty()

	for optionValue in pageOptions:
		var optionData: Dictionary = optionValue
		var optionButton := Button.new()
		optionButton.custom_minimum_size = Vector2(0, 54)
		optionButton.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		optionButton.alignment = HORIZONTAL_ALIGNMENT_LEFT
		optionButton.focus_mode = Control.FOCUS_ALL
		optionButton.text = tr(String(optionData.get("label", "Continue")))
		if IsNavigationAction(String(optionData.get("actionId", ""))):
			optionButton.icon = NAVIGATION_ICON
			optionButton.icon_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			optionButton.theme_type_variation = &"ButtonPrimary"
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

# Resubmits a message from the keyboard using the same validation as Send.
func _on_message_input_submitted(_submittedText: String) -> void:
	SubmitCurrentMessage()

# Refreshes Send availability while the player edits the composer.
func _on_message_input_changed(_newText: String) -> void:
	UpdateComposerState()

# Distinguishes actions that leave Tutor content and open another game destination.
func IsNavigationAction(actionId: String) -> bool:
	return (
		actionId.begins_with("open_")
		or actionId.begins_with("start_")
		or actionId.begins_with("confirm_")
	)

# Makes the non-production provider explicit in the player-facing Chat surface.
func IsDevelopmentProvider() -> bool:
	return GameManager.GetTutorAIStatus().get("developmentOnly", false)

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

# Refreshes only optional interaction controls after Settings changes.
func _on_tutor_settings_changed(_settingsData: Dictionary) -> void:
	RefreshTutorSettings()

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
