## Presents the Teacher Dashboard and its M6 content-management entry points.
##
## This UI binds authoring services and displays validation feedback. Parsing
## and validation remain focused services; no selected CSV is persisted yet.
extends Control

#region ========== References ==========

@onready var homeButton: Button = %HomeButton
@onready var settingsButton: Button = %SettingsButton
@onready var workspaceGrid: GridContainer = %WorkspaceGrid
@onready var importedStatusLabel: Label = %ImportedStatusLabel
@onready var importedMetadataLabel: Label = %ImportedMetadataLabel
@onready var studioStatusLabel: Label = %StudioStatusLabel
@onready var studioMetadataLabel: Label = %StudioMetadataLabel
@onready var importCsvButton: Button = %ImportCsvButton
@onready var validationResultsButton: Button = %ValidationResultsButton
@onready var importedPreviewButton: Button = %ImportedPreviewButton
@onready var csvFileDialog: FileDialog = %CsvFileDialog
@onready var validationOverlay: PanelContainer = %ValidationOverlay
@onready var validationStatusLabel: Label = %ValidationStatusLabel
@onready var validationCountsLabel: Label = %ValidationCountsLabel
@onready var validationFilenameLabel: Label = %ValidationFilenameLabel
@onready var validationIssueList: VBoxContainer = %ValidationIssueList
@onready var validationEmptyLabel: Label = %ValidationEmptyLabel
@onready var closeValidationButton: Button = %CloseValidationButton
@onready var confirmValidatedImportButton: Button = %ConfirmValidatedImportButton
@onready var confirmImportDialog: ConfirmationDialog = %ConfirmImportDialog
@onready var importNoticeDialog: AcceptDialog = %ImportNoticeDialog
@onready var importedPreviewPopup: PopupPanel = %ImportedPreviewPopup
@onready var importedPreviewLevelOption: OptionButton = %ImportedPreviewLevelOption
@onready var startImportedPreviewButton: Button = %StartImportedPreviewButton
@onready var cancelImportedPreviewButton: Button = %CancelImportedPreviewButton
@onready var settingsPanel = $SettingsPanel

#endregion

#region ========== Variables ==========

var csvParser := preload("res://Scripts/Gameplay/CourseCsvParser.gd").new()
var csvValidator := preload("res://Scripts/Gameplay/CourseCsvValidator.gd").new()
var lastParseResult: Dictionary = {}
var lastValidationReport: Dictionary = {}
var pendingImportIsReplacement: bool = false

#endregion

#region ========== Godot Functions ==========

# Connects Dashboard navigation, CSV selection, and responsive presentation.
func _ready() -> void:
	homeButton.pressed.connect(GameManager.OpenHome)
	settingsButton.pressed.connect(settingsPanel.Open)
	importCsvButton.pressed.connect(OpenCsvFileDialog)
	validationResultsButton.pressed.connect(OpenLastValidationResults)
	csvFileDialog.file_selected.connect(_on_csv_file_selected)
	closeValidationButton.pressed.connect(CloseValidationResults)
	confirmValidatedImportButton.pressed.connect(RequestValidatedImport)
	confirmImportDialog.confirmed.connect(CommitValidatedImport)
	importedPreviewButton.pressed.connect(OpenImportedPreviewSelection)
	startImportedPreviewButton.pressed.connect(StartSelectedImportedPreview)
	cancelImportedPreviewButton.pressed.connect(importedPreviewPopup.hide)
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
		var metadata: Dictionary = courseSummary.get("metadata", {})

		if courseSourceId == "imported_course":
			importedStatusLabel.text = tr("Current Imported Course") if available else tr("No Imported Course")
			importedMetadataLabel.text = BuildMetadataText(available, levelCount, questionCount, metadata)
			importedPreviewButton.disabled = not available
		elif courseSourceId == "studio_course":
			studioStatusLabel.text = tr("Current Studio Course") if available else tr("No Studio Course")
			studioMetadataLabel.text = BuildMetadataText(available, levelCount, questionCount, metadata)

# Builds consistent lightweight metadata for both authoring workspaces.
func BuildMetadataText(
	available: bool,
	levelCount: int,
	questionCount: int,
	metadata: Dictionary
) -> String:
	if not available:
		return tr("Create or import content to make this Course available.")

	var metadataLines: Array[String] = []
	if not String(metadata.get("courseName", "")).is_empty():
		metadataLines.append(String(metadata.get("courseName", "")))
	metadataLines.append(tr("%d Levels  •  %d Questions") % [levelCount, questionCount])
	if not String(metadata.get("originalFilename", "")).is_empty():
		metadataLines.append(tr("File: %s") % metadata.get("originalFilename", ""))
	var lastModifiedUnixMs: int = int(metadata.get("lastModifiedAtUnixMs", 0))
	if lastModifiedUnixMs > 0:
		metadataLines.append(
			tr("Last Updated: %s")
			% Time.get_datetime_string_from_unix_time(
				int(float(lastModifiedUnixMs) / 1000.0),
				true
			)
		)
	return "\n".join(metadataLines)

# Stacks dashboard workspaces on narrower windows while retaining full-width cards.
func UpdateResponsiveLayout() -> void:
	workspaceGrid.columns = 1 if get_viewport_rect().size.x < 1180.0 else 2

# Opens the platform file picker without modifying any existing Course Source.
func OpenCsvFileDialog() -> void:
	csvFileDialog.popup_centered_ratio(0.72)

# Reopens the most recent in-memory validation report during this Dashboard visit.
func OpenLastValidationResults() -> void:
	if not lastValidationReport.is_empty():
		PresentValidationReport()

# Builds the complete author-facing report after a CSV file has been selected.
func PresentValidationReport() -> void:
	ClearValidationIssues()
	validationFilenameLabel.text = lastValidationReport.get("filename", "")
	validationStatusLabel.text = tr(String(lastValidationReport.get("status", "Error")))
	validationCountsLabel.text = tr("%d Errors  •  %d Warnings  •  %d Valid") % [
		int(lastValidationReport.get("errorCount", 0)),
		int(lastValidationReport.get("warningCount", 0)),
		int(lastValidationReport.get("validCount", 0))
	]
	validationStatusLabel.add_theme_color_override(
		"font_color",
		GetSeverityColor(lastValidationReport.get("status", "Error"))
	)
	confirmValidatedImportButton.visible = lastValidationReport.get("isValid", false)

	var issues: Array = lastValidationReport.get("issues", [])
	validationEmptyLabel.visible = issues.is_empty()
	if issues.is_empty():
		validationEmptyLabel.text = tr("All parsed records passed validation.")
	else:
		for issueValue in issues:
			validationIssueList.add_child(CreateValidationIssueCard(issueValue))

	validationOverlay.visible = true
	closeValidationButton.grab_focus()

# Creates one readable issue card with source context and a suggested correction.
func CreateValidationIssueCard(issue: Dictionary) -> PanelContainer:
	var issueCard := PanelContainer.new()
	var issueMargin := MarginContainer.new()
	var issueContent := VBoxContainer.new()
	var contextLabel := Label.new()
	var messageLabel := Label.new()
	var expressionLabel := Label.new()
	var actionLabel := Label.new()
	var severity: String = issue.get("severity", "Error")
	var rowNumber: int = int(issue.get("rowNumber", 0))

	issueCard.custom_minimum_size.y = 142.0
	issueMargin.add_theme_constant_override("margin_left", 20)
	issueMargin.add_theme_constant_override("margin_top", 16)
	issueMargin.add_theme_constant_override("margin_right", 20)
	issueMargin.add_theme_constant_override("margin_bottom", 16)
	issueContent.add_theme_constant_override("separation", 7)
	contextLabel.text = BuildIssueContext(issue)
	contextLabel.add_theme_color_override("font_color", GetSeverityColor(severity))
	contextLabel.add_theme_font_size_override("font_size", 15)
	messageLabel.text = "%s: %s" % [tr(severity), issue.get("message", "")]
	messageLabel.add_theme_font_size_override("font_size", 17)
	messageLabel.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	expressionLabel.text = BuildExpressionContext(rowNumber)
	expressionLabel.visible = not expressionLabel.text.is_empty()
	expressionLabel.add_theme_color_override("font_color", Color(0.62, 0.72, 0.84, 1.0))
	actionLabel.text = tr("Suggested Action: %s") % issue.get("suggestedAction", "")
	actionLabel.add_theme_color_override("font_color", Color(0.52, 0.62, 0.74, 1.0))
	actionLabel.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	issueCard.add_child(issueMargin)
	issueMargin.add_child(issueContent)
	issueContent.add_child(contextLabel)
	issueContent.add_child(messageLabel)
	issueContent.add_child(expressionLabel)
	issueContent.add_child(actionLabel)
	return issueCard

# Formats available row, record, Level, Question, and field identifiers.
func BuildIssueContext(issue: Dictionary) -> String:
	var contextParts: Array[String] = []
	var rowNumber: int = int(issue.get("rowNumber", 0))
	if rowNumber > 0:
		contextParts.append(tr("Row %d") % rowNumber)
	if not String(issue.get("recordType", "")).is_empty():
		contextParts.append(String(issue.get("recordType", "")))
	if not String(issue.get("levelId", "")).is_empty():
		contextParts.append(tr("Level: %s") % issue.get("levelId", ""))
	if not String(issue.get("questionId", "")).is_empty():
		contextParts.append(tr("Question: %s") % issue.get("questionId", ""))
	if not String(issue.get("field", "")).is_empty():
		contextParts.append(tr("Field: %s") % issue.get("field", ""))
	return "  •  ".join(contextParts)

# Finds the source expression for an issue's physical CSV row when one exists.
func BuildExpressionContext(rowNumber: int) -> String:
	for parsedRowValue in lastParseResult.get("rows", []):
		var parsedRow: Dictionary = parsedRowValue
		if int(parsedRow.get("rowNumber", 0)) != rowNumber:
			continue
		var expression: String = parsedRow.get("fields", {}).get("expression", "")
		return tr("Expression: %s") % expression if not expression.is_empty() else ""
	return ""

# Removes dynamically generated issue cards before presenting another report.
func ClearValidationIssues() -> void:
	for issueCard in validationIssueList.get_children():
		validationIssueList.remove_child(issueCard)
		issueCard.queue_free()

# Returns deterministic colors for validation severity labels and issue contexts.
func GetSeverityColor(severity: String) -> Color:
	match severity:
		"Valid":
			return Color(0.32, 0.88, 0.7, 1.0)
		"Warning":
			return Color(1.0, 0.72, 0.28, 1.0)
		_:
			return Color(1.0, 0.36, 0.42, 1.0)

# Closes the report and restores focus to its Dashboard entry point.
func CloseValidationResults() -> void:
	validationOverlay.visible = false
	validationResultsButton.grab_focus()

# Presents every Imported Level with its authored Gameplay Mode for QA selection.
func OpenImportedPreviewSelection() -> void:
	importedPreviewLevelOption.clear()
	for levelValue in GameManager.GetCourseSourceLevels("imported_course"):
		var levelData: Dictionary = levelValue
		var levelTitle: String = levelData.get("title", "Untitled Level")
		var levelTypeId: String = levelData.get("levelTypeId", "")
		importedPreviewLevelOption.add_item("%s  •  %s" % [levelTitle, levelTypeId])
		importedPreviewLevelOption.set_item_metadata(
			importedPreviewLevelOption.item_count - 1,
			levelData.get("id", "")
		)

	startImportedPreviewButton.disabled = importedPreviewLevelOption.item_count == 0
	importedPreviewPopup.popup_centered(Vector2i(680, 310))

# Launches the selected Imported Level through the real isolated Game Scene.
func StartSelectedImportedPreview() -> void:
	var selectedIndex: int = importedPreviewLevelOption.selected
	if selectedIndex < 0 or selectedIndex >= importedPreviewLevelOption.item_count:
		return
	var levelId: String = str(importedPreviewLevelOption.get_item_metadata(selectedIndex))
	# Closes the popup while this Dashboard still belongs to the active SceneTree.
	importedPreviewPopup.hide()
	GameManager.StartImportedCoursePreview(levelId)

# Requests first-import confirmation while deferring replacement to the next step.
func RequestValidatedImport() -> void:
	if GameManager.HasCourseSourceContent("imported_course"):
		pendingImportIsReplacement = true
		confirmImportDialog.title = tr("Replace Imported Course")
		confirmImportDialog.ok_button_text = tr("Replace Course")
		confirmImportDialog.dialog_text = tr(
			"An Imported Course already exists. Replace it with the validated Course? Imported player data will reset only if the Course content changed."
		)
		confirmImportDialog.popup_centered()
		return

	pendingImportIsReplacement = false
	var metadata: Dictionary = lastParseResult.get("metadata", {})
	confirmImportDialog.title = tr("Confirm Import")
	confirmImportDialog.ok_button_text = tr("Import Course")
	confirmImportDialog.dialog_text = tr(
		"Import %s with %d Levels and %d Questions?"
	) % [
		metadata.get("courseName", tr("this Course")),
		int(metadata.get("levelCount", 0)),
		int(metadata.get("questionCount", 0))
	]
	confirmImportDialog.popup_centered()

# Persists one validated first import and refreshes all availability metadata.
func CommitValidatedImport() -> void:
	if lastValidationReport.is_empty() or not lastValidationReport.get("isValid", false):
		return

	var importResult: Dictionary
	if pendingImportIsReplacement:
		importResult = GameManager.ReplaceImportedCourse(
			lastParseResult.get("content", {}),
			lastParseResult.get("metadata", {})
		)
	else:
		importResult = GameManager.SaveFirstImportedCourse(
			lastParseResult.get("content", {}),
			lastParseResult.get("metadata", {})
		)

	if not importResult.get("succeeded", false):
		importNoticeDialog.title = tr("Import Failed")
		importNoticeDialog.dialog_text = tr("The Imported Course could not be saved. Existing content was not changed.")
		importNoticeDialog.popup_centered()
		return

	RefreshCourseStatus()
	CloseValidationResults()
	importNoticeDialog.title = (
		tr("Replacement Complete") if pendingImportIsReplacement else tr("Import Complete")
	)
	importNoticeDialog.dialog_text = (
		tr("The Imported Course was replaced and its player data was reset because the content changed.")
		if importResult.get("playerDataReset", false)
		else tr("The Imported Course is saved and now available to players.")
	)
	importNoticeDialog.popup_centered()
	pendingImportIsReplacement = false

#endregion

#region ========== Signal Callbacks ==========

# Parses and validates one selected file without registering or persisting it.
func _on_csv_file_selected(filePath: String) -> void:
	lastParseResult = csvParser.ParseFile(filePath)
	lastValidationReport = csvValidator.ValidateParseResult(lastParseResult)
	validationResultsButton.disabled = false
	PresentValidationReport()

#endregion
