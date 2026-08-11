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
@onready var progressLabel: Label = $CardMargin/CardLayout/ProgressLabel

#endregion

#region ========== Variables ==========

var levelId: String = ""
var levelTitle: String = ""
var levelSkills: Array = []
var questionCount: int = 0
var levelNumber: int = 1
var completedQuestions: int = 0
var levelCompleted: bool = false
var levelNeedsPractice: bool = false
var isFeatureCard: bool = false
var featureBadge: String = ""
var featureDescription: String = ""

#endregion

#region ========== Godot Functions ==========

# Connects interaction and applies data received before the card became ready.
func _ready() -> void:
	pressed.connect(_on_pressed)
	UpdateDisplay()

#endregion

#region ========== Functions ==========

# Stores one Level definition and refreshes this reusable card.
func Setup(levelData: Dictionary, displayLevelNumber: int, progressData: Dictionary) -> void:
	isFeatureCard = false
	levelId = levelData.get("id", "")
	levelTitle = levelData.get("title", "Untitled Level")
	levelSkills = levelData.get("skills", [])
	questionCount = levelData.get("questions", []).size()
	levelNumber = displayLevelNumber
	completedQuestions = progressData.get("completedQuestions", 0)
	levelCompleted = progressData.get("completed", false)
	levelNeedsPractice = progressData.get("needsPractice", false)

	if is_node_ready():
		UpdateDisplay()

# Stores one secondary feature definition in the existing reusable card layout.
func SetupFeature(featureData: Dictionary) -> void:
	isFeatureCard = true
	levelId = featureData.get("id", "")
	levelTitle = featureData.get("title", "Other")
	featureBadge = featureData.get("badge", "")
	featureDescription = featureData.get("description", "")
	set_pressed_no_signal(false)

	if is_node_ready():
		UpdateDisplay()

# Updates all card text from its stored Level data.
func UpdateDisplay() -> void:
	if isFeatureCard:
		UpdateFeatureDisplay()
		return

	levelNumberLabel.text = tr("LEVEL_NUMBER_FORMAT") % levelNumber
	questionCountLabel.text = tr("QUESTION_COUNT_FORMAT") % questionCount
	titleLabel.text = tr(levelTitle)
	skillsLabel.text = FormatSkills(levelSkills)
	progressLabel.text = GetProgressText()
	tooltip_text = "Select " + levelTitle

# Presents a secondary feature using the Level Card's established visual language.
func UpdateFeatureDisplay() -> void:
	levelNumberLabel.text = tr("OTHER_FEATURE")
	questionCountLabel.text = tr(featureBadge)
	titleLabel.text = tr(levelTitle)
	skillsLabel.text = tr(featureDescription)
	progressLabel.text = ""
	tooltip_text = tr(featureDescription)

# Converts snake_case Skill IDs into readable display labels.
func FormatSkills(skills: Array) -> String:
	var displaySkills: PackedStringArray = []

	for skill in skills:
		displaySkills.append(tr(str(skill).replace("_", " ").capitalize()))

	return "  |  ".join(displaySkills)

# Returns a concise current-session progress label for this Level.
func GetProgressText() -> String:
	if levelCompleted:
		return tr("Completed").to_upper()

	if levelNeedsPractice:
		return tr("Needs Practice").to_upper()

	if completedQuestions > 0:
		return "%s  %d/%d" % [tr("In Progress").to_upper(), completedQuestions, questionCount]

	return tr("Not Started").to_upper()

# Updates the card's visual toggle state without changing gameplay state.
func SetSelectedState(isSelected: bool) -> void:
	set_pressed_no_signal(isSelected)

#endregion

#region ========== Signal Callbacks ==========

# Emits the stored Level ID for the Lobby to forward to GameManager.
func _on_pressed() -> void:
	levelSelected.emit(levelId)

#endregion
