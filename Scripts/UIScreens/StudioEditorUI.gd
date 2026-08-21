## Presents the MathSmith Studio workspace for visual Course authoring.
##
## This first editor shell browses persistent Studio Levels and Questions.
## Focused editing actions are added in the following M6 development steps.
extends Control

#region ========== References ==========

@onready var dashboardButton: Button = %DashboardButton
@onready var settingsButton: Button = %SettingsButton
@onready var courseNameLabel: Label = %CourseNameLabel
@onready var levelCountLabel: Label = %LevelCountLabel
@onready var levelList: VBoxContainer = %LevelList
@onready var emptyLevelLabel: Label = %EmptyLevelLabel
@onready var levelTitleLabel: Label = %LevelTitleLabel
@onready var levelTypeValue: Label = %LevelTypeValue
@onready var skillValue: Label = %SkillValue
@onready var questionList: VBoxContainer = %QuestionList
@onready var emptyQuestionLabel: Label = %EmptyQuestionLabel
@onready var settingsPanel = $SettingsPanel

#endregion

#region ========== Variables ==========

var studioContent: Dictionary = {}
var studioMetadata: Dictionary = {}
var selectedLevelIndex: int = -1

#endregion

#region ========== Godot Functions ==========

# Connects navigation and restores the persistent Studio working dataset.
func _ready() -> void:
	dashboardButton.pressed.connect(GameManager.OpenTeacherDashboard)
	settingsButton.pressed.connect(settingsPanel.Open)
	LoadStudioCourse()
	dashboardButton.grab_focus()

#endregion

#region ========== Functions ==========

# Loads an isolated authoring snapshot and builds the editor navigation.
func LoadStudioCourse() -> void:
	var studioCourse: Dictionary = GameManager.GetStudioCourseData()
	studioContent = studioCourse.get("content", {})
	studioMetadata = studioCourse.get("metadata", {})
	courseNameLabel.text = studioMetadata.get("courseName", tr("Untitled Studio Course"))
	RefreshLevelList()

# Rebuilds the Level navigator without modifying Studio working data.
func RefreshLevelList() -> void:
	ClearContainer(levelList)
	var courseLevels: Array = studioContent.get("levels", [])
	levelCountLabel.text = tr("%d Levels") % courseLevels.size()
	emptyLevelLabel.visible = courseLevels.is_empty()

	for levelIndex in range(courseLevels.size()):
		var levelData: Dictionary = courseLevels[levelIndex]
		var levelButton := Button.new()
		levelButton.custom_minimum_size = Vector2(0, 58)
		levelButton.text = "%02d   %s" % [levelIndex + 1, levelData.get("title", tr("Untitled Level"))]
		levelButton.alignment = HORIZONTAL_ALIGNMENT_LEFT
		levelButton.pressed.connect(SelectLevel.bind(levelIndex))
		levelList.add_child(levelButton)

	if courseLevels.is_empty():
		ClearLevelDetails()
	else:
		SelectLevel(clampi(selectedLevelIndex, 0, courseLevels.size() - 1))

# Displays one selected Level and its authored Questions.
func SelectLevel(levelIndex: int) -> void:
	var courseLevels: Array = studioContent.get("levels", [])
	if levelIndex < 0 or levelIndex >= courseLevels.size():
		return

	selectedLevelIndex = levelIndex
	var levelData: Dictionary = courseLevels[levelIndex]
	levelTitleLabel.text = levelData.get("title", tr("Untitled Level"))
	levelTypeValue.text = FormatLevelType(levelData.get("levelTypeId", "step_ordering"))
	skillValue.text = ", ".join(PackedStringArray(levelData.get("skills", [])))
	RefreshQuestionList(levelData.get("questions", []))

# Rebuilds readable Question rows for the selected Level.
func RefreshQuestionList(questions: Array) -> void:
	ClearContainer(questionList)
	emptyQuestionLabel.visible = questions.is_empty()
	for questionIndex in range(questions.size()):
		var questionData: Dictionary = questions[questionIndex]
		var questionRow := PanelContainer.new()
		questionRow.custom_minimum_size = Vector2(0, 62)
		var questionLabel := Label.new()
		questionLabel.text = "%02d    %s    %s" % [
			questionIndex + 1,
			questionData.get("id", ""),
			questionData.get("expression", "")
		]
		questionLabel.add_theme_font_size_override("font_size", 17)
		questionRow.add_child(questionLabel)
		questionList.add_child(questionRow)

# Presents the empty editor state before the first Level is authored.
func ClearLevelDetails() -> void:
	selectedLevelIndex = -1
	levelTitleLabel.text = tr("No Level Selected")
	levelTypeValue.text = "—"
	skillValue.text = "—"
	ClearContainer(questionList)
	emptyQuestionLabel.visible = true

# Converts stored identifiers into author-facing Gameplay Mode names.
func FormatLevelType(levelTypeId: String) -> String:
	return levelTypeId.replace("_", " ").capitalize()

# Removes dynamically generated editor rows safely between refreshes.
func ClearContainer(container: Container) -> void:
	for child in container.get_children():
		child.queue_free()

#endregion
