## Presents the MathSmith Home Scene and its primary Play action.
##
## This script only binds the Play button and emits a UI request. GameManager
## owns scene navigation and persistent runtime state.
extends Control

#region ========== Signals ==========

signal playRequested

#endregion

#region ========== References ==========

@onready var playButton: Button = $MainCenter/HeroPanel/HeroMargin/HeroLayout/PlayButton

#endregion

#region ========== Godot Functions ==========

# Connects the primary action and gives it initial keyboard focus.
func _ready() -> void:
	playButton.pressed.connect(_on_play_button_pressed)
	playButton.grab_focus()

#endregion

#region ========== Signal Callbacks ==========

# Emits a navigation request without changing scenes from the UI layer.
func _on_play_button_pressed() -> void:
	playRequested.emit()

#endregion
