## Presents and persists the shared MathSmith Settings panel.
##
## This UI applies audio changes through AudioManager and stores preferences
## through SaveManager. It never owns gameplay or Level progress decisions.
extends Control

#region ========== Constants ==========

const US_FLAG: Texture2D = preload("res://Assets/Icons/us_flag.svg")
const CN_FLAG: Texture2D = preload("res://Assets/Icons/cn_flag.svg")
const ENGLISH_LANGUAGE_INDEX: int = 0
const SIMPLIFIED_CHINESE_LANGUAGE_INDEX: int = 1

#endregion

#region ========== Signals ==========

signal progressReset

#endregion

#region ========== References ==========

@onready var settingsContent: VBoxContainer = $Overlay/CenterContainer/Panel/Margin/SettingsContent
@onready var resetContent: VBoxContainer = $Overlay/CenterContainer/Panel/Margin/ResetContent
@onready var masterSlider: HSlider = $Overlay/CenterContainer/Panel/Margin/SettingsContent/MasterRow/MasterSlider
@onready var masterValueLabel: Label = $Overlay/CenterContainer/Panel/Margin/SettingsContent/MasterRow/MasterValueLabel
@onready var sfxSlider: HSlider = $Overlay/CenterContainer/Panel/Margin/SettingsContent/SFXRow/SFXSlider
@onready var sfxValueLabel: Label = $Overlay/CenterContainer/Panel/Margin/SettingsContent/SFXRow/SFXValueLabel
@onready var muteToggle: CheckBox = $Overlay/CenterContainer/Panel/Margin/SettingsContent/MuteRow/MuteToggle
@onready var languageButton: OptionButton = $Overlay/CenterContainer/Panel/Margin/SettingsContent/LanguageRow/LanguageButton
@onready var resetProgressButton: Button = $Overlay/CenterContainer/Panel/Margin/SettingsContent/ResetProgressButton
@onready var closeButton: Button = $Overlay/CenterContainer/Panel/Margin/SettingsContent/CloseButton
@onready var cancelResetButton: Button = $Overlay/CenterContainer/Panel/Margin/ResetContent/Actions/CancelButton
@onready var confirmResetButton: Button = $Overlay/CenterContainer/Panel/Margin/ResetContent/Actions/ConfirmButton

#endregion

#region ========== Godot Functions ==========

# Connects Settings controls once and keeps the reusable overlay hidden.
func _ready() -> void:
	masterSlider.value_changed.connect(_on_master_slider_value_changed)
	masterSlider.drag_ended.connect(_on_volume_slider_drag_ended)
	sfxSlider.value_changed.connect(_on_sfx_slider_value_changed)
	sfxSlider.drag_ended.connect(_on_volume_slider_drag_ended)
	muteToggle.toggled.connect(_on_mute_toggle_toggled)
	languageButton.item_selected.connect(_on_language_button_item_selected)
	resetProgressButton.pressed.connect(_on_reset_progress_button_pressed)
	closeButton.pressed.connect(Close)
	cancelResetButton.pressed.connect(_on_cancel_reset_button_pressed)
	confirmResetButton.pressed.connect(_on_confirm_reset_button_pressed)
	SetupLanguageOptions()
	visible = false

#endregion

#region ========== Functions ==========

# Opens the main Settings view using the latest persisted values.
func Open() -> void:
	var settingsData: Dictionary = SaveManager.GetSection("settings")
	settingsContent.visible = true
	resetContent.visible = false
	masterSlider.set_value_no_signal(settingsData.get("masterVolume", 1.0) * 100.0)
	sfxSlider.set_value_no_signal(settingsData.get("sfxVolume", 1.0) * 100.0)
	muteToggle.set_pressed_no_signal(settingsData.get("mute", false))
	languageButton.select(
		SIMPLIFIED_CHINESE_LANGUAGE_INDEX
		if settingsData.get("language", "en") == "zh_CN"
		else ENGLISH_LANGUAGE_INDEX
	)
	UpdateVolumeLabels()
	visible = true

# Closes either Settings view without changing gameplay state.
func Close() -> void:
	visible = false

# Updates both readable percentage labels.
func UpdateVolumeLabels() -> void:
	masterValueLabel.text = "%d%%" % roundi(masterSlider.value)
	sfxValueLabel.text = "%d%%" % roundi(sfxSlider.value)

# Builds the two locally supported language choices with flag icons.
func SetupLanguageOptions() -> void:
	languageButton.clear()
	languageButton.add_icon_item(US_FLAG, "English")
	languageButton.add_icon_item(CN_FLAG, "简体中文")

# Stores the current Settings values in one versioned section.
func SaveSettings() -> void:
	SaveManager.SetSection("settings", {
		"masterVolume": masterSlider.value / 100.0,
		"sfxVolume": sfxSlider.value / 100.0,
		"mute": muteToggle.button_pressed,
		"language": (
			"zh_CN"
			if languageButton.selected == SIMPLIFIED_CHINESE_LANGUAGE_INDEX
			else "en"
		)
	})

#endregion

#region ========== Signal Callbacks ==========

# Applies Master Volume continuously while the slider moves.
func _on_master_slider_value_changed(newValue: float) -> void:
	UpdateVolumeLabels()
	AudioManager.SetMasterVolume(newValue / 100.0)

# Applies SFX Volume continuously while the slider moves.
func _on_sfx_slider_value_changed(newValue: float) -> void:
	UpdateVolumeLabels()
	AudioManager.SetSFXVolume(newValue / 100.0)

# Writes volume preferences once after either slider interaction ends.
func _on_volume_slider_drag_ended(_valueChanged: bool) -> void:
	SaveSettings()
	AudioManager.PlayButton()

# Applies and persists the shared mute state immediately.
func _on_mute_toggle_toggled(isMuted: bool) -> void:
	AudioManager.SetMuted(isMuted)
	SaveSettings()

# Persists the selected future localization language.
func _on_language_button_item_selected(_index: int) -> void:
	var localeCode := (
		"zh_CN"
		if languageButton.selected == SIMPLIFIED_CHINESE_LANGUAGE_INDEX
		else "en"
	)
	LocalizationManager.SetLanguage(localeCode)

# Replaces Settings controls with an in-style destructive confirmation.
func _on_reset_progress_button_pressed() -> void:
	settingsContent.visible = false
	resetContent.visible = true

# Returns from confirmation without modifying Local Save data.
func _on_cancel_reset_button_pressed() -> void:
	resetContent.visible = false
	settingsContent.visible = true

# Clears player learning data only after explicit confirmation.
func _on_confirm_reset_button_pressed() -> void:
	SaveManager.ResetPlayerProgress()
	GameManager.ReloadPersistentProgress()
	progressReset.emit()
	Close()

#endregion
