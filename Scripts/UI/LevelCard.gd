## Presents one reusable mathematical Level option in the Lobby.
##
## This UI component displays Level title, Skills, and Question count, then
## emits its Level ID when pressed. GameManager owns the actual selection.
extends Button

#region ========== Signals ==========

signal levelSelected(levelId: String)

#endregion

#region ========== References ==========

@onready var levelNumberLabel: Label = $CardMargin/CardLayout/TopRow/LevelNumberLabel
@onready var questionCountLabel: Label = $CardMargin/CardLayout/TopRow/QuestionCountLabel
@onready var titleLabel: Label = $CardMargin/CardLayout/TitleLabel
@onready var skillsLabel: Label = $CardMargin/CardLayout/SkillsLabel

#endregion

#region ========== Variables ==========

var levelId: String = ""
var levelTitle: String = ""
var levelSkills: Array = []
var questionCount: int = 0
var levelNumber: int = 1

#endregion

#region ========== Godot Functions ==========

# Connects interaction and applies data received before the card became ready.
func _ready() -> void:
	pressed.connect(_on_pressed)
	UpdateDisplay()

#endregion

#region ========== Functions ==========

# Stores one Level definition and refreshes this reusable card.
func Setup(levelData: Dictionary, displayLevelNumber: int) -> void:
	levelId = levelData.get("id", "")
	levelTitle = levelData.get("title", "Untitled Level")
	levelSkills = levelData.get("skills", [])
	questionCount = levelData.get("questions", []).size()
	levelNumber = displayLevelNumber

	if is_node_ready():
		UpdateDisplay()

# Updates all card text from its stored Level data.
func UpdateDisplay() -> void:
	levelNumberLabel.text = "LEVEL %02d" % levelNumber
	questionCountLabel.text = "%d QUESTIONS" % questionCount
	titleLabel.text = levelTitle
	skillsLabel.text = FormatSkills(levelSkills)
	tooltip_text = "Select " + levelTitle

# Converts snake_case Skill IDs into readable display labels.
func FormatSkills(skills: Array) -> String:
	var displaySkills: PackedStringArray = []

	for skill in skills:
		displaySkills.append(str(skill).replace("_", " ").capitalize())

	return "  |  ".join(displaySkills)

# Updates the card's visual toggle state without changing gameplay state.
func SetSelectedState(isSelected: bool) -> void:
	set_pressed_no_signal(isSelected)

#endregion

#region ========== Signal Callbacks ==========

# Emits the stored Level ID for the Lobby to forward to GameManager.
func _on_pressed() -> void:
	levelSelected.emit(levelId)

#endregion
