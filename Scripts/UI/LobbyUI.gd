## Presents the Lobby and its currently available Level Type.
##
## This script only binds shared content to visual controls. Level selection,
## gameplay state, and scene navigation remain owned by GameManager.
extends Control

#region ========== Constants ==========

const LEVEL_CARD_SCENE: PackedScene = preload("res://Scenes/Menus/LevelCard.tscn")

#endregion

#region ========== References ==========

@onready var currentLevelTypeLabel: Label = $MainMargin/MainLayout/Header/CurrentLevelTypeLabel
@onready var stepOrderingButton: Button = $MainMargin/MainLayout/LevelTypeRow/StepOrderingButton
@onready var levelCountLabel: Label = $MainMargin/MainLayout/SectionHeader/LevelCountLabel
@onready var levelCardContainer: GridContainer = $MainMargin/MainLayout/LevelScroll/LevelCardContainer

#endregion

#region ========== Godot Functions ==========

# Displays the selected playable Level Type when the Lobby enters the tree.
func _ready() -> void:
	var selectedLevelType := GameManager.GetLevelTypeById(GameManager.selectedLevelTypeId)
	ShowSelectedLevelType(selectedLevelType)
	levelCountLabel.text = "%d Levels" % GameManager.GetLevels().size()
	CreateLevelCards(GameManager.GetLevels())

#endregion

#region ========== Functions ==========

# Updates the Lobby header and selected Type button from shared content.
func ShowSelectedLevelType(levelTypeData: Dictionary) -> void:
	var levelTypeTitle: String = levelTypeData.get("title", "Step Ordering")
	currentLevelTypeLabel.text = "Current Mode: " + levelTypeTitle
	stepOrderingButton.text = levelTypeTitle
	stepOrderingButton.disabled = true

# Rebuilds the Lobby grid from validated Level content.
func CreateLevelCards(levels: Array) -> void:
	ClearLevelCards()
	var selectedLevelId: String = GameManager.GetSelectedLevelId()

	# Instantiate the same reusable scene for every data-driven Level.
	for levelIndex in range(levels.size()):
		var levelCard := LEVEL_CARD_SCENE.instantiate()
		levelCardContainer.add_child(levelCard)
		levelCard.Setup(levels[levelIndex], levelIndex + 1)
		levelCard.SetSelectedState(levels[levelIndex]["id"] == selectedLevelId)
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

#endregion
