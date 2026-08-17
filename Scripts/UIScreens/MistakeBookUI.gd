## Presents saved Questions with deterministic explanations and correct answers.
##
## This screen reads and removes persistent mistake entries through GameManager.
## It creates review cards visually but does not own mathematical generation.
extends Control

#region ========== References ==========

@onready var backButton: Button = $MainMargin/MainLayout/Header/BackButton
@onready var countLabel: Label = $MainMargin/MainLayout/Header/CountLabel
@onready var emptyLabel: Label = $MainMargin/MainLayout/MistakeScroll/Content/EmptyLabel
@onready var entryContainer: VBoxContainer = $MainMargin/MainLayout/MistakeScroll/Content/EntryContainer

#endregion

#region ========== Godot Functions ==========

# Connects navigation and builds every saved review card.
func _ready() -> void:
	backButton.pressed.connect(_on_back_button_pressed)
	LocalizationManager.languageChanged.connect(_on_language_changed)
	RefreshEntries()

#endregion

#region ========== Functions ==========

# Rebuilds the review list from the current persistent Mistake Book.
func RefreshEntries() -> void:
	ClearEntries()
	var mistakeEntries := GameManager.GetMistakeBookEntries()
	countLabel.text = tr("MISTAKE_COUNT_FORMAT") % mistakeEntries.size()
	emptyLabel.visible = mistakeEntries.is_empty()

	for entry in mistakeEntries:
		entryContainer.add_child(CreateMistakeCard(entry))

# Creates one readable card containing context, reason, explanation, and answer.
func CreateMistakeCard(entry: Dictionary) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(0, 310)
	var cardStyle := StyleBoxFlat.new()
	cardStyle.bg_color = Color(0.05, 0.075, 0.12, 0.97)
	cardStyle.border_color = Color(0.14, 0.28, 0.43, 0.95)
	cardStyle.set_border_width_all(1)
	cardStyle.set_corner_radius_all(16)
	card.add_theme_stylebox_override("panel", cardStyle)

	var cardMargin := MarginContainer.new()
	cardMargin.add_theme_constant_override("margin_left", 24)
	cardMargin.add_theme_constant_override("margin_top", 20)
	cardMargin.add_theme_constant_override("margin_right", 24)
	cardMargin.add_theme_constant_override("margin_bottom", 20)
	card.add_child(cardMargin)

	var cardLayout := VBoxContainer.new()
	cardLayout.add_theme_constant_override("separation", 11)
	cardMargin.add_child(cardLayout)
	cardLayout.add_child(CreateCardHeader(entry))
	cardLayout.add_child(CreateMetadataLabel(entry))
	cardLayout.add_child(CreateReasonLabel(entry))
	cardLayout.add_child(CreateSectionLabel(tr("Explanation")))
	cardLayout.add_child(CreateBodyLabel(tr(entry.get("explanation", ""))))
	cardLayout.add_child(CreateSectionLabel(tr("Correct Answer")))
	cardLayout.add_child(CreateAnswerLabel(entry.get("answerSteps", [])))
	return card

# Creates an expression heading and a right-aligned remove action.
func CreateCardHeader(entry: Dictionary) -> HBoxContainer:
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 16)
	var expressionLabel := Label.new()
	expressionLabel.text = entry.get("expression", "")
	expressionLabel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	expressionLabel.add_theme_font_size_override("font_size", 25)
	expressionLabel.add_theme_color_override("font_color", Color(0.86, 0.93, 1, 1))
	header.add_child(expressionLabel)

	var removeButton := Button.new()
	removeButton.text = tr("Remove")
	removeButton.tooltip_text = tr("Remove this Question from the Mistake Book.")
	removeButton.pressed.connect(_on_remove_button_pressed.bind(entry.get("entryKey", "")))
	header.add_child(removeButton)
	return header

# Formats the source Level, interaction mode, and translated Skill tags.
func CreateMetadataLabel(entry: Dictionary) -> Label:
	var skillNames: PackedStringArray = []

	for skill in entry.get("skills", []):
		skillNames.append(tr(str(skill).replace("_", " ").capitalize()))

	var metadataLabel := Label.new()
	metadataLabel.text = "%s  •  %s  •  %s" % [
		tr(entry.get("levelTitle", "Untitled Level")),
		tr(entry.get("levelTypeTitle", "Unknown Mode")),
		" / ".join(skillNames)
	]
	metadataLabel.add_theme_font_size_override("font_size", 14)
	metadataLabel.add_theme_color_override("font_color", Color(0.48, 0.75, 0.94, 1))
	return metadataLabel

# Explains why the Question qualified for review without judging the player.
func CreateReasonLabel(entry: Dictionary) -> Label:
	var reasons: PackedStringArray = []
	var incorrectCount: int = entry.get("incorrectAttempts", 0)

	if incorrectCount >= 2:
		reasons.append(tr("INCORRECT_ATTEMPT_COUNT_FORMAT") % incorrectCount)
	if entry.get("hintUsed", false):
		reasons.append(tr("Hint used"))

	var reasonLabel := Label.new()
	reasonLabel.text = "%s: %s  •  %s: %s" % [
		tr("Why Saved"),
		"; ".join(reasons),
		tr("Focus"),
		tr(entry.get("errorCategory", ""))
	]
	reasonLabel.add_theme_color_override("font_color", Color(0.72, 0.78, 0.87, 1))
	return reasonLabel

# Creates a compact cyan section heading.
func CreateSectionLabel(sectionText: String) -> Label:
	var sectionLabel := Label.new()
	sectionLabel.text = sectionText.to_upper()
	sectionLabel.add_theme_font_size_override("font_size", 13)
	sectionLabel.add_theme_color_override("font_color", Color(0.35, 0.8, 1, 1))
	return sectionLabel

# Creates wrapped explanatory copy for one saved rule.
func CreateBodyLabel(bodyText: String) -> Label:
	var bodyLabel := Label.new()
	bodyLabel.text = bodyText
	bodyLabel.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bodyLabel.add_theme_color_override("font_color", Color(0.76, 0.81, 0.89, 1))
	return bodyLabel

# Formats the generated correct process as a readable multiline answer.
func CreateAnswerLabel(answerSteps: Array) -> Label:
	var formattedSteps: PackedStringArray = []

	for answerStep in answerSteps:
		formattedSteps.append(str(answerStep))

	var answerLabel := CreateBodyLabel("\n".join(formattedSteps))
	answerLabel.add_theme_font_size_override("font_size", 17)
	answerLabel.add_theme_color_override("font_color", Color(0.42, 0.9, 0.72, 1))
	return answerLabel

# Removes all generated cards before rebuilding the list.
func ClearEntries() -> void:
	for child in entryContainer.get_children():
		entryContainer.remove_child(child)
		child.queue_free()

#endregion

#region ========== Signal Callbacks ==========

# Returns to the shared Lobby navigation entry point.
func _on_back_button_pressed() -> void:
	GameManager.OpenLobby()

# Removes one resolved entry and immediately refreshes the page.
func _on_remove_button_pressed(entryKey: String) -> void:
	GameManager.RemoveMistakeBookEntry(entryKey)
	RefreshEntries()

# Rebuilds dynamic review copy after the active locale changes.
func _on_language_changed(_localeCode: String) -> void:
	RefreshEntries()

#endregion
