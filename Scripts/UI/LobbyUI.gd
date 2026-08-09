## Presents the Lobby and its currently available Level Type.
##
## This script only binds shared content to visual controls. Level selection,
## gameplay state, and scene navigation remain owned by GameManager.
extends Control

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

#endregion

#region ========== Functions ==========

# Updates the Lobby header and selected Type button from shared content.
func ShowSelectedLevelType(levelTypeData: Dictionary) -> void:
	var levelTypeTitle: String = levelTypeData.get("title", "Step Ordering")
	currentLevelTypeLabel.text = "Current Mode: " + levelTypeTitle
	stepOrderingButton.text = levelTypeTitle
	stepOrderingButton.disabled = true

# Returns the visual container used by the next Level Card task.
func GetLevelCardContainer() -> GridContainer:
	return levelCardContainer

#endregion
