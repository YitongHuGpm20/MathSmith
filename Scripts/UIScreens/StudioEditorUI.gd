## Presents the MathSmith Studio workspace for visual Course authoring.
##
## This first editor shell browses persistent Studio Levels and Questions.
## Focused editing actions are added in the following M6 development steps.
extends Control

#region ========== References ==========

@onready var dashboardButton: Button = %DashboardButton
@onready var settingsButton: Button = %SettingsButton
@onready var courseNameLabel: Label = %CourseNameLabel
@onready var savedStateLabel: Label = %SavedState
@onready var levelCountLabel: Label = %LevelCountLabel
@onready var levelList: VBoxContainer = %LevelList
@onready var emptyLevelLabel: Label = %EmptyLevelLabel
@onready var addLevelButton: Button = %AddLevelButton
@onready var levelTitleLabel: Label = %LevelTitleLabel
@onready var levelTypeValue: Label = %LevelTypeValue
@onready var skillValue: Label = %SkillValue
@onready var levelNameEdit: LineEdit = %LevelNameEdit
@onready var levelTypeOption: OptionButton = %LevelTypeOption
@onready var skillTagsEdit: LineEdit = %SkillTagsEdit
@onready var saveLevelButton: Button = %SaveLevelButton
@onready var previewLevelButton: Button = %PreviewLevelButton
@onready var moveLevelUpButton: Button = %MoveLevelUpButton
@onready var moveLevelDownButton: Button = %MoveLevelDownButton
@onready var deleteLevelButton: Button = %DeleteLevelButton
@onready var questionList: VBoxContainer = %QuestionList
@onready var emptyQuestionLabel: Label = %EmptyQuestionLabel
@onready var addQuestionButton: Button = %AddQuestionButton
@onready var questionIdEdit: LineEdit = %QuestionIdEdit
@onready var expressionEdit: LineEdit = %ExpressionEdit
@onready var expressionValidationLabel: Label = %ExpressionValidationLabel
@onready var saveQuestionButton: Button = %SaveQuestionButton
@onready var duplicateQuestionButton: Button = %DuplicateQuestionButton
@onready var previewQuestionButton: Button = %PreviewQuestionButton
@onready var deleteQuestionButton: Button = %DeleteQuestionButton
@onready var confirmDeleteLevelDialog: ConfirmationDialog = %ConfirmDeleteLevelDialog
@onready var confirmDeleteQuestionDialog: ConfirmationDialog = %ConfirmDeleteQuestionDialog
@onready var questionNoticeDialog: AcceptDialog = %QuestionNoticeDialog
@onready var solutionExpressionLabel: Label = %SolutionExpressionLabel
@onready var solutionStepList: VBoxContainer = %SolutionStepList
@onready var solutionEmptyLabel: Label = %SolutionEmptyLabel
@onready var settingsPanel = $SettingsPanel

#endregion

#region ========== Variables ==========

var studioContent: Dictionary = {}
var studioMetadata: Dictionary = {}
var selectedLevelIndex: int = -1
var selectedQuestionIndex: int = -1
var expressionValidator := preload(
	"res://Scripts/Gameplay/CourseCsvValidator.gd"
).new()
var currentExpressionValidation: Dictionary = {}

#endregion

#region ========== Godot Functions ==========

# Connects navigation and restores the persistent Studio working dataset.
func _ready() -> void:
	dashboardButton.pressed.connect(GameManager.OpenTeacherDashboard)
	settingsButton.pressed.connect(settingsPanel.Open)
	addLevelButton.pressed.connect(AddLevel)
	saveLevelButton.pressed.connect(SaveSelectedLevel)
	previewLevelButton.pressed.connect(PreviewSelectedLevel)
	moveLevelUpButton.pressed.connect(MoveSelectedLevel.bind(-1))
	moveLevelDownButton.pressed.connect(MoveSelectedLevel.bind(1))
	deleteLevelButton.pressed.connect(confirmDeleteLevelDialog.popup_centered)
	confirmDeleteLevelDialog.confirmed.connect(DeleteSelectedLevel)
	addQuestionButton.pressed.connect(AddQuestion)
	saveQuestionButton.pressed.connect(SaveSelectedQuestion)
	duplicateQuestionButton.pressed.connect(DuplicateSelectedQuestion)
	previewQuestionButton.pressed.connect(PreviewSelectedQuestion)
	deleteQuestionButton.pressed.connect(confirmDeleteQuestionDialog.popup_centered)
	confirmDeleteQuestionDialog.confirmed.connect(DeleteSelectedQuestion)
	expressionEdit.text_changed.connect(ValidateExpressionLive)
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
	RestorePreviewSelection(GameManager.ConsumeStudioEditorReturnSelection())
	SetSaveState(true)
	RefreshLevelList()

# Resolves stable IDs back into editor indices after returning from Preview.
func RestorePreviewSelection(returnSelection: Dictionary) -> void:
	selectedLevelIndex = -1
	selectedQuestionIndex = -1
	var returnLevelId: String = returnSelection.get("levelId", "")
	var returnQuestionId: String = returnSelection.get("questionId", "")
	if returnLevelId.is_empty():
		return

	var courseLevels: Array = studioContent.get("levels", [])
	for levelIndex in range(courseLevels.size()):
		var levelData: Dictionary = courseLevels[levelIndex]
		if levelData.get("id", "") != returnLevelId:
			continue
		selectedLevelIndex = levelIndex
		var questions: Array = levelData.get("questions", [])
		for questionIndex in range(questions.size()):
			if questions[questionIndex].get("id", "") == returnQuestionId:
				selectedQuestionIndex = questionIndex
				break
		return

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

	if selectedLevelIndex != levelIndex:
		selectedQuestionIndex = -1
	selectedLevelIndex = levelIndex
	var levelData: Dictionary = courseLevels[levelIndex]
	levelTitleLabel.text = levelData.get("title", tr("Untitled Level"))
	levelTypeValue.text = FormatLevelType(levelData.get("levelTypeId", "step_ordering"))
	skillValue.text = ", ".join(PackedStringArray(levelData.get("skills", [])))
	levelNameEdit.text = levelData.get("title", "")
	BuildLevelTypeOptions(levelData.get("levelTypeId", "step_ordering"))
	skillTagsEdit.text = ", ".join(PackedStringArray(levelData.get("skills", [])))
	SetLevelEditingEnabled(true)
	moveLevelUpButton.disabled = levelIndex == 0
	moveLevelDownButton.disabled = levelIndex == courseLevels.size() - 1
	RefreshQuestionList(levelData.get("questions", []))

# Adds a uniquely identified empty Level and selects it for immediate editing.
func AddLevel() -> void:
	var courseLevels: Array = studioContent.get("levels", [])
	var levelId := CreateUniqueLevelId(courseLevels)
	courseLevels.append({
		"id": levelId,
		"title": tr("Untitled Level"),
		"levelTypeId": "step_ordering",
		"skills": [],
		"questions": []
	})
	studioContent["levels"] = courseLevels
	selectedLevelIndex = courseLevels.size() - 1
	PersistStudioChanges()

# Saves the current Level fields while preserving all of its Questions.
func SaveSelectedLevel() -> bool:
	if not ApplySelectedLevelFields():
		return false
	return PersistStudioChanges()

# Applies current Level controls to working memory without writing separately.
func ApplySelectedLevelFields() -> bool:
	var courseLevels: Array = studioContent.get("levels", [])
	if selectedLevelIndex < 0 or selectedLevelIndex >= courseLevels.size():
		return false
	var levelData: Dictionary = courseLevels[selectedLevelIndex]
	var levelTitle := levelNameEdit.text.strip_edges()
	levelData["title"] = tr("Untitled Level") if levelTitle.is_empty() else levelTitle
	levelData["levelTypeId"] = levelTypeOption.get_item_metadata(
		levelTypeOption.selected
	)
	levelData["skills"] = ParseSkillTags(skillTagsEdit.text)
	courseLevels[selectedLevelIndex] = levelData
	studioContent["levels"] = courseLevels
	return true

# Moves the complete selected Level without breaking its Question ownership.
func MoveSelectedLevel(direction: int) -> void:
	var courseLevels: Array = studioContent.get("levels", [])
	var targetIndex := selectedLevelIndex + direction
	if targetIndex < 0 or targetIndex >= courseLevels.size():
		return
	var selectedLevel: Dictionary = courseLevels[selectedLevelIndex]
	courseLevels.remove_at(selectedLevelIndex)
	courseLevels.insert(targetIndex, selectedLevel)
	selectedLevelIndex = targetIndex
	studioContent["levels"] = courseLevels
	PersistStudioChanges()

# Deletes one confirmed Level and every Question that belongs to it.
func DeleteSelectedLevel() -> void:
	var courseLevels: Array = studioContent.get("levels", [])
	if selectedLevelIndex < 0 or selectedLevelIndex >= courseLevels.size():
		return
	courseLevels.remove_at(selectedLevelIndex)
	selectedLevelIndex = mini(selectedLevelIndex, courseLevels.size() - 1)
	studioContent["levels"] = courseLevels
	PersistStudioChanges()

# Writes authoring changes and rebuilds the editor from the saved snapshot.
func PersistStudioChanges() -> bool:
	var saveResult: Dictionary = GameManager.SaveStudioCourse(
		studioContent,
		studioMetadata
	)
	if not saveResult.get("succeeded", false):
		# Restore the last persisted snapshot so failed writes never look saved.
		var persistedCourse: Dictionary = GameManager.GetStudioCourseData()
		studioContent = persistedCourse.get("content", {})
		studioMetadata = persistedCourse.get("metadata", {})
		SetSaveState(false)
		RefreshLevelList()
		return false
	var studioCourse: Dictionary = GameManager.GetStudioCourseData()
	studioContent = studioCourse.get("content", {})
	studioMetadata = studioCourse.get("metadata", {})
	SetSaveState(true)
	RefreshLevelList()
	return true

# Shows whether the latest synchronous autosave reached persistent storage.
func SetSaveState(savedSuccessfully: bool) -> void:
	savedStateLabel.text = tr("SAVED") if savedSuccessfully else tr("ERROR")
	savedStateLabel.add_theme_color_override(
		"font_color",
		Color(0.32, 0.88, 0.7, 1)
		if savedSuccessfully
		else Color(1.0, 0.4, 0.42, 1)
	)

# Builds the supported Gameplay Mode selector from the real Course schema.
func BuildLevelTypeOptions(selectedLevelTypeId: String) -> void:
	levelTypeOption.clear()
	var levelTypes: Dictionary = studioContent.get("level_types", {})
	for levelTypeIdValue in levelTypes:
		var levelTypeId: String = levelTypeIdValue
		var levelTypeData: Dictionary = levelTypes[levelTypeId]
		levelTypeOption.add_item(levelTypeData.get("title", FormatLevelType(levelTypeId)))
		var optionIndex := levelTypeOption.item_count - 1
		levelTypeOption.set_item_metadata(optionIndex, levelTypeId)
		if levelTypeId == selectedLevelTypeId:
			levelTypeOption.select(optionIndex)

# Converts comma-separated author input into normalized unique Skill IDs.
func ParseSkillTags(skillText: String) -> Array[String]:
	var skillTags: Array[String] = []
	for skillValue in skillText.split(",", false):
		var skillId := skillValue.strip_edges().to_lower().replace(" ", "_")
		if not skillId.is_empty() and skillId not in skillTags:
			skillTags.append(skillId)
	return skillTags

# Generates the next stable Studio Level ID without reusing an existing ID.
func CreateUniqueLevelId(courseLevels: Array) -> String:
	var levelNumber := courseLevels.size() + 1
	var levelId := "studio_level_%02d" % levelNumber
	var existingIds: Array[String] = []
	for levelValue in courseLevels:
		existingIds.append(levelValue.get("id", ""))
	while levelId in existingIds:
		levelNumber += 1
		levelId = "studio_level_%02d" % levelNumber
	return levelId

# Rebuilds readable Question rows for the selected Level.
func RefreshQuestionList(questions: Array) -> void:
	ClearContainer(questionList)
	emptyQuestionLabel.visible = questions.is_empty()
	for questionIndex in range(questions.size()):
		var questionData: Dictionary = questions[questionIndex]
		var questionRow := Button.new()
		questionRow.custom_minimum_size = Vector2(0, 62)
		questionRow.text = "%02d    %s    %s" % [
			questionIndex + 1,
			questionData.get("id", ""),
			questionData.get("expression", "")
		]
		questionRow.alignment = HORIZONTAL_ALIGNMENT_LEFT
		questionRow.pressed.connect(SelectQuestion.bind(questionIndex))
		questionList.add_child(questionRow)

	addQuestionButton.disabled = selectedLevelIndex < 0
	if questions.is_empty():
		ClearQuestionDetails()
	else:
		SelectQuestion(clampi(selectedQuestionIndex, 0, questions.size() - 1))

# Displays one selected Question in the focused editing controls.
func SelectQuestion(questionIndex: int) -> void:
	var questions := GetSelectedLevelQuestions()
	if questionIndex < 0 or questionIndex >= questions.size():
		return
	selectedQuestionIndex = questionIndex
	var questionData: Dictionary = questions[questionIndex]
	questionIdEdit.text = questionData.get("id", "")
	expressionEdit.text = questionData.get("expression", "")
	ValidateExpressionLive(expressionEdit.text)
	SetQuestionEditingEnabled(true)

# Adds a blank uniquely identified Question to the selected Level.
func AddQuestion() -> void:
	var questions := GetSelectedLevelQuestions()
	if selectedLevelIndex < 0:
		return
	questions.append({
		"id": CreateUniqueQuestionId("studio_question"),
		"expression": ""
	})
	SetSelectedLevelQuestions(questions)
	selectedQuestionIndex = questions.size() - 1
	PersistStudioChanges()

# Saves the selected Question after enforcing Course-wide ID uniqueness.
func SaveSelectedQuestion() -> bool:
	if not ApplySelectedQuestionFields():
		return false
	return PersistStudioChanges()

# Applies valid Question controls to working memory without a separate write.
func ApplySelectedQuestionFields() -> bool:
	var questions := GetSelectedLevelQuestions()
	if selectedQuestionIndex < 0 or selectedQuestionIndex >= questions.size():
		return false
	var questionId := questionIdEdit.text.strip_edges()
	if questionId.is_empty() or IsQuestionIdUsedElsewhere(
		questionId,
		selectedLevelIndex,
		selectedQuestionIndex
	):
		ShowQuestionNotice(
			tr("Question ID Required") if questionId.is_empty() else tr("Duplicate Question ID")
		)
		return false
	currentExpressionValidation = expressionValidator.ValidateExpressionForAuthoring(
		expressionEdit.text
	)
	if not currentExpressionValidation.get("valid", false):
		ShowQuestionNotice(currentExpressionValidation.get("message", tr("Invalid Expression")))
		return false
	var questionData: Dictionary = questions[selectedQuestionIndex]
	questionData["id"] = questionId
	questionData["expression"] = expressionEdit.text.strip_edges()
	questions[selectedQuestionIndex] = questionData
	SetSelectedLevelQuestions(questions)
	return true

# Saves and launches only the selected Question in isolated real gameplay.
func PreviewSelectedQuestion() -> void:
	if not ApplySelectedLevelFields() or not ApplySelectedQuestionFields():
		return
	if not PersistStudioChanges():
		return
	var courseLevels: Array = studioContent.get("levels", [])
	if selectedLevelIndex < 0 or selectedLevelIndex >= courseLevels.size():
		return
	var questions := GetSelectedLevelQuestions()
	if selectedQuestionIndex < 0 or selectedQuestionIndex >= questions.size():
		return
	GameManager.StartStudioQuestionPreview(
		courseLevels[selectedLevelIndex].get("id", ""),
		questions[selectedQuestionIndex].get("id", "")
	)

# Validates and launches every Question in the selected Level from the start.
func PreviewSelectedLevel() -> void:
	if not ApplySelectedLevelFields():
		return
	if selectedQuestionIndex >= 0 and not ApplySelectedQuestionFields():
		return
	var courseLevels: Array = studioContent.get("levels", [])
	var levelData: Dictionary = courseLevels[selectedLevelIndex]
	if not ValidateLevelForPreview(levelData):
		return
	if not PersistStudioChanges():
		return
	var returnQuestionId := ""
	var questions: Array = levelData.get("questions", [])
	if selectedQuestionIndex >= 0 and selectedQuestionIndex < questions.size():
		returnQuestionId = questions[selectedQuestionIndex].get("id", "")
	GameManager.StartStudioLevelPreview(
		levelData.get("id", ""),
		returnQuestionId
	)

# Requires every authored Question to pass the shared production validator.
func ValidateLevelForPreview(levelData: Dictionary) -> bool:
	var questions: Array = levelData.get("questions", [])
	if questions.is_empty():
		ShowPreviewNotice(tr("Add at least one valid Question before previewing this Level."))
		return false
	for questionValue in questions:
		var questionData: Dictionary = questionValue
		var validationResult: Dictionary = expressionValidator.ValidateExpressionForAuthoring(
			questionData.get("expression", "")
		)
		if not validationResult.get("valid", false):
			ShowPreviewNotice(
				tr("Question %s: %s") % [
					questionData.get("id", ""),
					tr(validationResult.get("message", "Invalid Expression"))
				]
			)
			return false
	return true

# Shows why a Level cannot enter real-gameplay Preview yet.
func ShowPreviewNotice(message: String) -> void:
	questionNoticeDialog.title = tr("Preview Unavailable")
	questionNoticeDialog.dialog_text = message
	questionNoticeDialog.popup_centered()

# Creates an independent copy with a generated unique Question ID.
func DuplicateSelectedQuestion() -> void:
	var questions := GetSelectedLevelQuestions()
	if selectedQuestionIndex < 0 or selectedQuestionIndex >= questions.size():
		return
	var duplicatedQuestion: Dictionary = questions[selectedQuestionIndex].duplicate(true)
	duplicatedQuestion["id"] = CreateUniqueQuestionId(
		str(duplicatedQuestion.get("id", "studio_question")) + "_copy"
	)
	questions.insert(selectedQuestionIndex + 1, duplicatedQuestion)
	SetSelectedLevelQuestions(questions)
	selectedQuestionIndex += 1
	PersistStudioChanges()

# Deletes only the selected Question after explicit confirmation.
func DeleteSelectedQuestion() -> void:
	var questions := GetSelectedLevelQuestions()
	if selectedQuestionIndex < 0 or selectedQuestionIndex >= questions.size():
		return
	questions.remove_at(selectedQuestionIndex)
	selectedQuestionIndex = mini(selectedQuestionIndex, questions.size() - 1)
	SetSelectedLevelQuestions(questions)
	PersistStudioChanges()

# Returns a mutable copy of the selected Level's Question collection.
func GetSelectedLevelQuestions() -> Array:
	var courseLevels: Array = studioContent.get("levels", [])
	if selectedLevelIndex < 0 or selectedLevelIndex >= courseLevels.size():
		return []
	return courseLevels[selectedLevelIndex].get("questions", []).duplicate(true)

# Replaces Questions only inside the selected Level without changing its metadata.
func SetSelectedLevelQuestions(questions: Array) -> void:
	var courseLevels: Array = studioContent.get("levels", [])
	if selectedLevelIndex < 0 or selectedLevelIndex >= courseLevels.size():
		return
	var levelData: Dictionary = courseLevels[selectedLevelIndex]
	levelData["questions"] = questions.duplicate(true)
	courseLevels[selectedLevelIndex] = levelData
	studioContent["levels"] = courseLevels

# Generates a stable unique Question ID across every Studio Level.
func CreateUniqueQuestionId(preferredBase: String) -> String:
	var normalizedBase := preferredBase.strip_edges().to_lower().replace(" ", "_")
	if normalizedBase.is_empty():
		normalizedBase = "studio_question"
	var candidateId := normalizedBase
	var suffix := 2
	while IsQuestionIdUsedElsewhere(candidateId, -1, -1):
		candidateId = "%s_%02d" % [normalizedBase, suffix]
		suffix += 1
	return candidateId

# Checks Course-wide Question identity while allowing the current record itself.
func IsQuestionIdUsedElsewhere(
	questionId: String,
	ignoredLevelIndex: int,
	ignoredQuestionIndex: int
) -> bool:
	var courseLevels: Array = studioContent.get("levels", [])
	for levelIndex in range(courseLevels.size()):
		var questions: Array = courseLevels[levelIndex].get("questions", [])
		for questionIndex in range(questions.size()):
			if levelIndex == ignoredLevelIndex and questionIndex == ignoredQuestionIndex:
				continue
			if questions[questionIndex].get("id", "") == questionId:
				return true
	return false

# Shows a focused authoring error without mutating the current draft.
func ShowQuestionNotice(message: String) -> void:
	questionNoticeDialog.title = tr("Question Cannot Be Saved")
	questionNoticeDialog.dialog_text = message
	questionNoticeDialog.popup_centered()

# Updates deterministic validation feedback after every Expression edit.
func ValidateExpressionLive(expression: String) -> void:
	currentExpressionValidation = expressionValidator.ValidateExpressionForAuthoring(
		expression
	)
	var severity: String = currentExpressionValidation.get("severity", "Error")
	var message: String = currentExpressionValidation.get("message", "")
	var suggestedAction: String = currentExpressionValidation.get("suggestedAction", "")
	if severity == "Valid":
		message = tr("Expression is valid and generates %d solution steps.") % int(
			currentExpressionValidation.get("stepCount", 0)
		)
	elif severity == "Warning":
		message = tr("Generated solution is unusually long (%d steps).") % int(
			currentExpressionValidation.get("stepCount", 0)
		)
	expressionValidationLabel.text = "%s  •  %s" % [tr(severity.to_upper()), tr(message)]
	if not suggestedAction.is_empty():
		expressionValidationLabel.text += "  " + tr(suggestedAction)
	match severity:
		"Valid":
			expressionValidationLabel.add_theme_color_override(
				"font_color",
				Color(0.32, 0.88, 0.7, 1)
			)
		"Warning":
			expressionValidationLabel.add_theme_color_override(
				"font_color",
				Color(1.0, 0.72, 0.28, 1)
			)
		_:
			expressionValidationLabel.add_theme_color_override(
				"font_color",
				Color(1.0, 0.4, 0.42, 1)
			)
	RefreshGeneratedSolutionPreview(expression, currentExpressionValidation)

# Displays the real generated teaching sequence for the current Expression.
func RefreshGeneratedSolutionPreview(
	expression: String,
	validationResult: Dictionary
) -> void:
	ClearGeneratedStepRows()
	var normalizedExpression := expression.strip_edges()
	solutionExpressionLabel.text = normalizedExpression if not normalizedExpression.is_empty() else "—"
	var generatedSteps: Array = validationResult.get("generatedSteps", [])
	var canPreview: bool = (
		bool(validationResult.get("valid", false))
		and not generatedSteps.is_empty()
	)
	solutionEmptyLabel.visible = not canPreview
	if not canPreview:
		return

	for generatedStepValue in generatedSteps:
		var generatedStep: String = generatedStepValue
		var stepLabel := Label.new()
		stepLabel.text = generatedStep
		stepLabel.add_theme_font_size_override("font_size", 18)
		stepLabel.add_theme_color_override(
			"font_color",
			Color(0.82, 0.9, 0.98, 1)
		)
		stepLabel.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		solutionStepList.add_child(stepLabel)

# Clears generated preview rows immediately during rapid text editing.
func ClearGeneratedStepRows() -> void:
	for child in solutionStepList.get_children():
		child.free()

# Restores the generated-solution empty state when no Question is selected.
func ClearGeneratedSolutionPreview() -> void:
	ClearGeneratedStepRows()
	solutionExpressionLabel.text = "—"
	solutionEmptyLabel.visible = true

# Presents the empty editor state before the first Level is authored.
func ClearLevelDetails() -> void:
	selectedLevelIndex = -1
	selectedQuestionIndex = -1
	levelTitleLabel.text = tr("No Level Selected")
	levelTypeValue.text = "—"
	skillValue.text = "—"
	levelNameEdit.clear()
	levelTypeOption.clear()
	skillTagsEdit.clear()
	SetLevelEditingEnabled(false)
	ClearContainer(questionList)
	emptyQuestionLabel.visible = true
	addQuestionButton.disabled = true
	ClearQuestionDetails()

# Converts stored identifiers into author-facing Gameplay Mode names.
func FormatLevelType(levelTypeId: String) -> String:
	return levelTypeId.replace("_", " ").capitalize()

# Enables authoring controls only while a valid Level is selected.
func SetLevelEditingEnabled(enabled: bool) -> void:
	levelNameEdit.editable = enabled
	levelTypeOption.disabled = not enabled
	skillTagsEdit.editable = enabled
	saveLevelButton.disabled = not enabled
	previewLevelButton.disabled = not enabled
	moveLevelUpButton.disabled = not enabled
	moveLevelDownButton.disabled = not enabled
	deleteLevelButton.disabled = not enabled

# Clears and locks Question fields when the selected Level contains none.
func ClearQuestionDetails() -> void:
	selectedQuestionIndex = -1
	questionIdEdit.clear()
	expressionEdit.clear()
	expressionValidationLabel.text = tr("Select or add a Question to validate its Expression.")
	expressionValidationLabel.add_theme_color_override(
		"font_color",
		Color(0.52, 0.62, 0.74, 1)
	)
	currentExpressionValidation.clear()
	ClearGeneratedSolutionPreview()
	SetQuestionEditingEnabled(false)

# Enables Question actions only while one authored Question is selected.
func SetQuestionEditingEnabled(enabled: bool) -> void:
	questionIdEdit.editable = enabled
	expressionEdit.editable = enabled
	saveQuestionButton.disabled = not enabled
	duplicateQuestionButton.disabled = not enabled
	previewQuestionButton.disabled = not enabled
	deleteQuestionButton.disabled = not enabled

# Removes dynamically generated editor rows safely between refreshes.
func ClearContainer(container: Container) -> void:
	for child in container.get_children():
		child.queue_free()

#endregion
