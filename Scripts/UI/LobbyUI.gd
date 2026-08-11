## Presents the Lobby and its currently available Level Type.
##
## This script only binds shared content to visual controls. Level selection,
## gameplay state, and scene navigation remain owned by GameManager.
extends Control

#region ========== Constants ==========

const LEVEL_CARD_SCENE: PackedScene = preload("res://Scenes/Menus/LevelCard.tscn")

#endregion

#region ========== References ==========

@onready var homeButton: Button = $MainMargin/MainLayout/Header/HomeButton
@onready var settingsButton: Button = $MainMargin/MainLayout/Header/SettingsButton
@onready var stepOrderingButton: Button = $MainMargin/MainLayout/LevelTypeRow/StepOrderingButton
@onready var choiceOrderingButton: Button = $MainMargin/MainLayout/LevelTypeRow/ChoiceOrderingButton
@onready var fillProcessButton: Button = $MainMargin/MainLayout/LevelTypeRow/FillProcessButton
@onready var searchInput: LineEdit = $MainMargin/MainLayout/SearchRow/SearchInput
@onready var filterButton: OptionButton = $MainMargin/MainLayout/SearchRow/FilterButton
@onready var levelCountLabel: Label = $MainMargin/MainLayout/SectionHeader/LevelCountLabel
@onready var levelCardContainer: GridContainer = $MainMargin/MainLayout/LevelScroll/LevelCardContainer
@onready var settingsPanel = $SettingsPanel

#endregion

#region ========== Variables ==========

var allLevels: Array = []
var filterValues: Array[String] = []

#endregion

#region ========== Godot Functions ==========

# Displays the selected playable Level Type when the Lobby enters the tree.
func _ready() -> void:
	homeButton.pressed.connect(_on_home_button_pressed)
	settingsButton.pressed.connect(settingsPanel.Open)
	settingsPanel.progressReset.connect(RefreshLevelCards)
	stepOrderingButton.pressed.connect(_on_step_ordering_button_pressed)
	choiceOrderingButton.pressed.connect(_on_choice_ordering_button_pressed)
	fillProcessButton.pressed.connect(_on_fill_process_button_pressed)
	searchInput.text_changed.connect(_on_search_input_text_changed)
	filterButton.item_selected.connect(_on_filter_button_item_selected)
	get_viewport().size_changed.connect(UpdateResponsiveLayout)
	ShowSelectedLevelType()
	allLevels = GameManager.GetLevels()
	SetupFilters()
	RefreshLevelCards()
	UpdateResponsiveLayout()

#endregion

#region ========== Functions ==========

# Updates the Lobby header and selected Type button from shared content.
func ShowSelectedLevelType() -> void:
	var stepOrderingData := GameManager.GetLevelTypeById("step_ordering")
	var choiceOrderingData := GameManager.GetLevelTypeById("multiple_choice_ordering")
	var fillProcessData := GameManager.GetLevelTypeById("fill_in_process")
	stepOrderingButton.text = stepOrderingData.get("title", "Step Ordering")
	choiceOrderingButton.text = choiceOrderingData.get("title", "Multiple-Choice Ordering")
	fillProcessButton.text = fillProcessData.get("title", "Fill in the Process")
	stepOrderingButton.set_pressed_no_signal(GameManager.selectedLevelTypeId == "step_ordering")
	choiceOrderingButton.set_pressed_no_signal(
		GameManager.selectedLevelTypeId == "multiple_choice_ordering"
	)
	fillProcessButton.set_pressed_no_signal(GameManager.selectedLevelTypeId == "fill_in_process")

# Adapts the Level grid to wide, medium, and narrow windows.
func UpdateResponsiveLayout() -> void:
	var viewportWidth := get_viewport_rect().size.x

	if viewportWidth >= 1100:
		levelCardContainer.columns = 3
	elif viewportWidth >= 720:
		levelCardContainer.columns = 2
	else:
		levelCardContainer.columns = 1

# Builds progress and Skill filters from the currently loaded Level data.
func SetupFilters() -> void:
	var skills: Array[String] = []
	filterButton.clear()
	filterValues.clear()
	AddFilterOption("All Levels", "all")
	AddFilterOption("Not Started", "status:not_started")
	AddFilterOption("In Progress", "status:in_progress")
	AddFilterOption("Needs Practice", "status:needs_practice")
	AddFilterOption("Completed", "status:completed")

	# Collect each Skill once so content changes automatically update the filter.
	for level in allLevels:
		for skill in level.get("skills", []):
			var skillId := str(skill)
			if not skills.has(skillId):
				skills.append(skillId)

	skills.sort()
	for skill in skills:
		AddFilterOption(str(skill).replace("_", " ").capitalize(), "skill:" + skill)

# Adds one display label and its internal deterministic filter value.
func AddFilterOption(displayText: String, filterValue: String) -> void:
	filterButton.add_item(displayText)
	filterValues.append(filterValue)

# Rebuilds the Level grid using the current search text and selected filter.
func RefreshLevelCards() -> void:
	var filteredLevels: Array = []
	var searchText := searchInput.text.strip_edges().to_lower()
	var selectedFilter := "all"

	if filterButton.selected >= 0 and filterButton.selected < filterValues.size():
		selectedFilter = filterValues[filterButton.selected]

	for levelIndex in range(allLevels.size()):
		var level: Dictionary = allLevels[levelIndex]
		if MatchesSearch(level, levelIndex, searchText) and MatchesFilter(level, selectedFilter):
			filteredLevels.append({"data": level, "number": levelIndex + 1})

	levelCountLabel.text = "%d of %d Levels" % [filteredLevels.size(), allLevels.size()]
	CreateLevelCards(filteredLevels)

# Matches searchable Level metadata and every Question expression or ID.
func MatchesSearch(level: Dictionary, levelIndex: int, searchText: String) -> bool:
	if searchText.is_empty():
		return true

	var searchableParts: PackedStringArray = [
		str(levelIndex + 1),
		str(level.get("id", "")),
		str(level.get("title", "")),
		" ".join(PackedStringArray(level.get("skills", [])))
	]

	for question in level.get("questions", []):
		searchableParts.append(str(question.get("id", "")))
		searchableParts.append(str(question.get("expression", "")))

	return " ".join(searchableParts).to_lower().contains(searchText)

# Matches one progress state or Skill selected from the filter control.
func MatchesFilter(level: Dictionary, selectedFilter: String) -> bool:
	if selectedFilter == "all":
		return true

	var levelId: String = level.get("id", "")
	var progressData := GameManager.GetLevelProgress(levelId)
	if selectedFilter.begins_with("status:"):
		var status := selectedFilter.trim_prefix("status:")
		if status == "completed":
			return progressData.get("completed", false)
		if status == "needs_practice":
			return progressData.get("needsPractice", false)
		if status == "in_progress":
			return (
				progressData.get("completedQuestions", 0) > 0
				and not progressData.get("completed", false)
				and not progressData.get("needsPractice", false)
			)
		return progressData.get("completedQuestions", 0) == 0

	if selectedFilter.begins_with("skill:"):
		return level.get("skills", []).has(selectedFilter.trim_prefix("skill:"))

	return true

# Rebuilds the Lobby grid from validated Level content.
func CreateLevelCards(levelEntries: Array) -> void:
	ClearLevelCards()
	var selectedLevelId: String = GameManager.GetSelectedLevelId()

	# Instantiate the same reusable scene for every data-driven Level.
	for levelEntry in levelEntries:
		var level: Dictionary = levelEntry["data"]
		var levelCard := LEVEL_CARD_SCENE.instantiate()
		levelCardContainer.add_child(levelCard)
		var levelId: String = level["id"]
		levelCard.Setup(
			level,
			levelEntry["number"],
			GameManager.GetLevelProgress(levelId)
		)
		levelCard.SetSelectedState(levelId == selectedLevelId)
		levelCard.levelSelected.connect(_on_level_card_selected)

# Removes existing cards before the Lobby grid is regenerated.
func ClearLevelCards() -> void:
	for child in levelCardContainer.get_children():
		levelCardContainer.remove_child(child)
		child.queue_free()

#endregion

#region ========== Signal Callbacks ==========

# Forwards Level selection to GameManager and refreshes visual selection.
func _on_level_card_selected(levelId: String) -> void:
	if not GameManager.SelectLevel(levelId):
		return

	for levelCard in levelCardContainer.get_children():
		levelCard.SetSelectedState(levelCard.levelId == levelId)

	GameManager.OpenGame()

# Returns to Home through GameManager's navigation entry point.
func _on_home_button_pressed() -> void:
	GameManager.OpenHome()

# Selects the existing drag-and-drop Step Ordering interaction.
func _on_step_ordering_button_pressed() -> void:
	if GameManager.SelectLevelType("step_ordering"):
		ShowSelectedLevelType()
		RefreshLevelCards()

# Selects Multiple-Choice Ordering without changing shared Level content.
func _on_choice_ordering_button_pressed() -> void:
	if GameManager.SelectLevelType("multiple_choice_ordering"):
		ShowSelectedLevelType()
		RefreshLevelCards()

# Selects Fill in the Process without duplicating Question or solution data.
func _on_fill_process_button_pressed() -> void:
	if GameManager.SelectLevelType("fill_in_process"):
		ShowSelectedLevelType()
		RefreshLevelCards()

# Applies search immediately while the player types.
func _on_search_input_text_changed(_newText: String) -> void:
	RefreshLevelCards()

# Applies the selected progress or Skill filter.
func _on_filter_button_item_selected(_index: int) -> void:
	RefreshLevelCards()

#endregion
