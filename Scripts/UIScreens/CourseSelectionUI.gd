## Presents the player-facing Course Source selection before the Lobby.
##
## This screen displays availability and metadata from CourseManager through
## GameManager. It does not expose teacher authoring or content mutation tools.
extends Control

#region ========== References ==========

@onready var backButton: Button = $MainMargin/PageLayout/Header/BackButton
@onready var settingsButton: Button = $MainMargin/PageLayout/Header/SettingsButton
@onready var courseGrid: GridContainer = $MainMargin/PageLayout/ContentCenter/CourseContent/CourseGrid
@onready var coreCourseButton: Button = $MainMargin/PageLayout/ContentCenter/CourseContent/CourseGrid/CoreCourseButton
@onready var importedCourseButton: Button = $MainMargin/PageLayout/ContentCenter/CourseContent/CourseGrid/ImportedCourseButton
@onready var studioCourseButton: Button = $MainMargin/PageLayout/ContentCenter/CourseContent/CourseGrid/StudioCourseButton
@onready var settingsPanel = $SettingsPanel

#endregion

#region ========== Variables ==========

var courseButtons: Dictionary = {}

#endregion

#region ========== Godot Functions ==========

# Connects navigation and presents all Course Source availability states.
func _ready() -> void:
	courseButtons = {
		"core_curriculum": coreCourseButton,
		"imported_course": importedCourseButton,
		"studio_course": studioCourseButton
	}
	backButton.pressed.connect(GameManager.OpenHome)
	settingsButton.pressed.connect(settingsPanel.Open)
	coreCourseButton.pressed.connect(SelectCourse.bind("core_curriculum"))
	importedCourseButton.pressed.connect(SelectCourse.bind("imported_course"))
	studioCourseButton.pressed.connect(SelectCourse.bind("studio_course"))
	get_viewport().size_changed.connect(UpdateResponsiveLayout)
	RefreshCourseCards()
	UpdateResponsiveLayout()
	coreCourseButton.grab_focus()

#endregion

#region ========== Functions ==========

# Updates cards from centralized Course metadata and availability rules.
func RefreshCourseCards() -> void:
	for courseSummaryValue in GameManager.GetCourseSourceSummaries():
		var courseSummary: Dictionary = courseSummaryValue
		var courseSourceId: String = courseSummary.get("id", "")
		if not courseButtons.has(courseSourceId):
			continue

		var courseButton: Button = courseButtons[courseSourceId]
		var available: bool = courseSummary.get("available", false)
		var metadataLabel: Label = courseButton.get_node("CardMargin/CardLayout/MetadataLabel")
		var statusLabel: Label = courseButton.get_node("CardMargin/CardLayout/StatusLabel")
		courseButton.disabled = not available
		metadataLabel.text = (
			tr("%d Levels  •  %d Questions") % [
				int(courseSummary.get("levelCount", 0)),
				int(courseSummary.get("questionCount", 0))
			]
			if available
			else tr("Not available yet")
		)
		statusLabel.text = (
			tr("AVAILABLE") if available else tr("UNAVAILABLE")
		)

# Keeps three cards readable on wide screens and stacked on narrow screens.
func UpdateResponsiveLayout() -> void:
	var viewportWidth := get_viewport_rect().size.x
	courseGrid.columns = 1 if viewportWidth < 1100.0 else 3

# Selects one available Course Source before entering its gameplay Lobby.
func SelectCourse(courseSourceId: String) -> void:
	if GameManager.SelectCourseSource(courseSourceId):
		GameManager.OpenLobby()

#endregion
