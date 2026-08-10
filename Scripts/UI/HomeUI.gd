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

@onready var playButton: Button = %PlayButton
@onready var creditsButton: Button = %CreditsButton
@onready var exitButton: Button = %ExitButton
@onready var creditsOverlay: PanelContainer = $CreditsOverlay
@onready var closeCreditsButton: Button = %CloseButton
@onready var mainMargin: MarginContainer = $MainMargin
@onready var landingContent: VBoxContainer = %LandingContent
@onready var featureGrid: GridContainer = %FeatureGrid
@onready var titleLabel: Label = %TitleLabel
@onready var taglineLabel: Label = %TaglineLabel

#endregion

#region ========== Godot Functions ==========

# Connects the primary action and gives it initial keyboard focus.
func _ready() -> void:
	playButton.pressed.connect(_on_play_button_pressed)
	creditsButton.pressed.connect(_on_credits_button_pressed)
	closeCreditsButton.pressed.connect(_on_close_credits_button_pressed)
	exitButton.pressed.connect(_on_exit_button_pressed)
	playRequested.connect(GameManager.OpenLobby)
	exitRequested.connect(GameManager.QuitGame)
	get_viewport().size_changed.connect(UpdateResponsiveLayout)
	UpdateResponsiveLayout()
	playButton.grab_focus()

#endregion

#region ========== Functions ==========

# Adapts landing-page width, feature columns, and typography to the viewport.
func UpdateResponsiveLayout() -> void:
	var viewportWidth := get_viewport_rect().size.x
	var narrowLayout := viewportWidth < 900.0
	var pageMargin := 24 if narrowLayout else 72

	mainMargin.add_theme_constant_override("margin_left", pageMargin)
	mainMargin.add_theme_constant_override("margin_right", pageMargin)
	featureGrid.columns = 1 if narrowLayout else 3
	titleLabel.add_theme_font_size_override("font_size", 56 if narrowLayout else 82)
	taglineLabel.add_theme_font_size_override("font_size", 22 if narrowLayout else 28)

	if narrowLayout:
		landingContent.custom_minimum_size.x = maxf(viewportWidth - pageMargin * 2.0, 320.0)
	else:
		landingContent.custom_minimum_size.x = minf(viewportWidth * 0.72, 1320.0)

#endregion

#region ========== Signal Callbacks ==========

# Emits a navigation request without changing scenes from the UI layer.
func _on_play_button_pressed() -> void:
	playRequested.emit()

# Opens the local Credits overlay without involving gameplay state.
func _on_credits_button_pressed() -> void:
	creditsOverlay.visible = true
	closeCreditsButton.grab_focus()

# Closes the Credits overlay and restores focus to its Home action.
func _on_close_credits_button_pressed() -> void:
	creditsOverlay.visible = false
	creditsButton.grab_focus()

# Emits the application exit request through the shared manager.
func _on_exit_button_pressed() -> void:
	exitRequested.emit()

#endregion
