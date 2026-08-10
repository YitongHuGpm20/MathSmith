## Presents the MathSmith Home Scene and its primary menu actions.
##
## This script binds buttons and presents the Credits dialog. GameManager owns
## scene navigation, application exit, and persistent runtime state.
extends Control

#region ========== Signals ==========

signal playRequested
signal exitRequested

#endregion

#region ========== References ==========

@onready var playButton: Button = $MainCenter/HeroPanel/HeroMargin/HeroLayout/PlayButton
@onready var creditsButton: Button = $MainCenter/HeroPanel/HeroMargin/HeroLayout/MenuButtonRow/CreditsButton
@onready var exitButton: Button = $MainCenter/HeroPanel/HeroMargin/HeroLayout/MenuButtonRow/ExitButton
@onready var creditsDialog: AcceptDialog = $CreditsDialog

#endregion

#region ========== Godot Functions ==========

# Connects the primary action and gives it initial keyboard focus.
func _ready() -> void:
	playButton.pressed.connect(_on_play_button_pressed)
	creditsButton.pressed.connect(_on_credits_button_pressed)
	exitButton.pressed.connect(_on_exit_button_pressed)
	playRequested.connect(GameManager.OpenLobby)
	exitRequested.connect(GameManager.QuitGame)
	playButton.grab_focus()

#endregion

#region ========== Signal Callbacks ==========

# Emits a navigation request without changing scenes from the UI layer.
func _on_play_button_pressed() -> void:
	playRequested.emit()

# Opens the local Credits dialog without involving gameplay state.
func _on_credits_button_pressed() -> void:
	creditsDialog.popup_centered()

# Emits the application exit request through the shared manager.
func _on_exit_button_pressed() -> void:
	exitRequested.emit()

#endregion
