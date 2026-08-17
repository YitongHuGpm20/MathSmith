## Presents the temporary Teacher Dashboard destination for the M6 access flow.
##
## Authoring and management controls are intentionally deferred to the next step.
extends Control

#region ========== References ==========

@onready var homeButton: Button = %HomeButton
@onready var settingsButton: Button = %SettingsButton
@onready var workspaceGrid: GridContainer = %WorkspaceGrid
@onready var importedStatusLabel: Label = %ImportedStatusLabel
@onready var importedMetadataLabel: Label = %ImportedMetadataLabel
@onready var studioStatusLabel: Label = %StudioStatusLabel
@onready var studioMetadataLabel: Label = %StudioMetadataLabel
@onready var settingsPanel = $SettingsPanel

#endregion

#region ========== Godot Functions ==========

# Connects the placeholder workspace navigation without adding authoring behavior.
func _ready() -> void:
	homeButton.pressed.connect(GameManager.OpenHome)
	settingsButton.pressed.connect(settingsPanel.Open)
	get_viewport().size_changed.connect(UpdateResponsiveLayout)
	RefreshCourseStatus()
	UpdateResponsiveLayout()
	homeButton.grab_focus()

#endregion

#region ========== Functions ==========

# Presents current Imported and Studio availability without mutating Course data.
func RefreshCourseStatus() -> void:
	for courseSummaryValue in GameManager.GetCourseSourceSummaries():
		var courseSummary: Dictionary = courseSummaryValue
		var courseSourceId: String = courseSummary.get("id", "")
		var available: bool = courseSummary.get("available", false)
		var levelCount: int = int(courseSummary.get("levelCount", 0))
		var questionCount: int = int(courseSummary.get("questionCount", 0))

		if courseSourceId == "imported_course":
			importedStatusLabel.text = tr("Current Imported Course") if available else tr("No Imported Course")
			importedMetadataLabel.text = BuildMetadataText(available, levelCount, questionCount)
		elif courseSourceId == "studio_course":
			studioStatusLabel.text = tr("Current Studio Course") if available else tr("No Studio Course")
			studioMetadataLabel.text = BuildMetadataText(available, levelCount, questionCount)

# Builds consistent lightweight metadata for both authoring workspaces.
func BuildMetadataText(available: bool, levelCount: int, questionCount: int) -> String:
	if not available:
		return tr("Create or import content to make this Course available.")

	return tr("%d Levels  •  %d Questions") % [levelCount, questionCount]

# Stacks dashboard workspaces on narrower windows while retaining full-width cards.
func UpdateResponsiveLayout() -> void:
	workspaceGrid.columns = 1 if get_viewport_rect().size.x < 1180.0 else 2

#endregion
