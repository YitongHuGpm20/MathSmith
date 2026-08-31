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
		var exists: bool = courseSummary.get("exists", available)
		var descriptionLabel: Label = courseButton.get_node("CardMargin/CardLayout/DescriptionLabel")
		var metadataLabel: Label = courseButton.get_node("CardMargin/CardLayout/MetadataLabel")
		var statusLabel: Label = courseButton.get_node("CardMargin/CardLayout/StatusLabel")
		courseButton.disabled = not available
		if available:
			metadataLabel.text = tr("%d Levels  •  %d Questions") % [
				int(courseSummary.get("levelCount", 0)),
				int(courseSummary.get("questionCount", 0))
			]
		else:
			ApplyEmptyCourseState(
				courseSourceId,
				exists,
				descriptionLabel,
				metadataLabel
			)
		statusLabel.text = tr("AVAILABLE") if available else tr("UNAVAILABLE")
		statusLabel.add_theme_color_override(
			"font_color",
			Color(0.35, 0.9, 0.72, 1.0) if available else Color(0.55, 0.62, 0.72, 1.0)
		)

# Gives each unavailable Course Source a precise player-facing explanation.
func ApplyEmptyCourseState(
	courseSourceId: String,
	exists: bool,
	descriptionLabel: Label,
	metadataLabel: Label
) -> void:
	if courseSourceId == "imported_course":
		descriptionLabel.text = tr("No course imported yet.")
		metadataLabel.text = tr("Use Teacher Tools to import a CSV Course.")
	elif courseSourceId == "studio_course" and exists:
		descriptionLabel.text = tr("This Studio Course has no playable Levels yet.")
		metadataLabel.text = tr("Add valid content in MathSmith Studio.")
	else:
		descriptionLabel.text = tr("No Studio Course created yet.")
		metadataLabel.text = tr("Use Teacher Tools to create a Studio Course.")

# Keeps three cards readable on wide screens and stacked on narrow screens.
func UpdateResponsiveLayout() -> void:
	var viewportWidth := get_viewport_rect().size.x
	courseGrid.columns = 1 if viewportWidth < 1100.0 else 3

# Selects one available Course Source before entering its gameplay Lobby.
func SelectCourse(courseSourceId: String) -> void:
	if GameManager.SelectCourseSource(courseSourceId):
		GameManager.OpenLobby()

#endregion
