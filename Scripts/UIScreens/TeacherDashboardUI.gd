## Presents the temporary Teacher Dashboard destination for the M6 access flow.
##
## Authoring and management controls are intentionally deferred to the next step.
extends Control

#region ========== References ==========

@onready var homeButton: Button = %HomeButton
@onready var settingsButton: Button = %SettingsButton
@onready var settingsPanel = $SettingsPanel

#endregion

#region ========== Godot Functions ==========

# Connects the placeholder workspace navigation without adding authoring behavior.
func _ready() -> void:
	homeButton.pressed.connect(GameManager.OpenHome)
	settingsButton.pressed.connect(settingsPanel.Open)
	homeButton.grab_focus()

#endregion
