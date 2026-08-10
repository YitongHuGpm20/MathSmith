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
@onready var stepOrderingButton: Button = $MainMargin/MainLayout/LevelTypeRow/StepOrderingButton
@onready var choiceOrderingButton: Button = $MainMargin/MainLayout/LevelTypeRow/ChoiceOrderingButton
@onready var levelCountLabel: Label = $MainMargin/MainLayout/SectionHeader/LevelCountLabel
@onready var levelCardContainer: GridContainer = $MainMargin/MainLayout/LevelScroll/LevelCardContainer

#endregion

#region ========== Godot Functions ==========

# Displays the selected playable Level Type when the Lobby enters the tree.
func _ready() -> void:
	homeButton.pressed.connect(_on_home_button_pressed)
	stepOrderingButton.pressed.connect(_on_step_ordering_button_pressed)
	choiceOrderingButton.pressed.connect(_on_choice_ordering_button_pressed)
	get_viewport().size_changed.connect(UpdateResponsiveLayout)
	ShowSelectedLevelType()
	levelCountLabel.text = "%d Levels" % GameManager.GetLevels().size()
	CreateLevelCards(GameManager.GetLevels())
	UpdateResponsiveLayout()

#endregion

#region ========== Functions ==========

# Updates the Lobby header and selected Type button from shared content.
func ShowSelectedLevelType() -> void:
	var stepOrderingData := GameManager.GetLevelTypeById("step_ordering")
	var choiceOrderingData := GameManager.GetLevelTypeById("multiple_choice_ordering")
	stepOrderingButton.text = stepOrderingData.get("title", "Step Ordering")
	choiceOrderingButton.text = choiceOrderingData.get("title", "Multiple-Choice Ordering")
	stepOrderingButton.set_pressed_no_signal(GameManager.selectedLevelTypeId == "step_ordering")
	choiceOrderingButton.set_pressed_no_signal(
		GameManager.selectedLevelTypeId == "multiple_choice_ordering"
	)

# Adapts the Level grid to wide, medium, and narrow windows.
func UpdateResponsiveLayout() -> void:
	var viewportWidth := get_viewport_rect().size.x

	if viewportWidth >= 1100:
		levelCardContainer.columns = 3
	elif viewportWidth >= 720:
		levelCardContainer.columns = 2
	else:
		levelCardContainer.columns = 1

# Rebuilds the Lobby grid from validated Level content.
func CreateLevelCards(levels: Array) -> void:
	ClearLevelCards()
	var selectedLevelId: String = GameManager.GetSelectedLevelId()

	# Instantiate the same reusable scene for every data-driven Level.
	for levelIndex in range(levels.size()):
		var levelCard := LEVEL_CARD_SCENE.instantiate()
		levelCardContainer.add_child(levelCard)
		var levelId: String = levels[levelIndex]["id"]
		levelCard.Setup(
			levels[levelIndex],
			levelIndex + 1,
			GameManager.GetLevelProgress(levelId)
		)
		levelCard.SetSelectedState(levelId == selectedLevelId)
		levelCard.levelSelected.connect(_on_level_card_selected)

# Removes existing cards before the Lobby grid is regenerated.
func ClearLevelCards() -> void:
	for child in levelCardContainer.get_children():
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

# Selects Multiple-Choice Ordering without changing shared Level content.
func _on_choice_ordering_button_pressed() -> void:
	if GameManager.SelectLevelType("multiple_choice_ordering"):
		ShowSelectedLevelType()

#endregion
