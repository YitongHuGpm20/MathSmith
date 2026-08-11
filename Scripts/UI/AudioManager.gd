## Centralizes reusable MathSmith UI and gameplay-feedback sound effects.
##
## This Autoload binds Button interactions across scenes and exposes focused
## playback functions for drag, drop, answer, Hint, and completion feedback.
extends Node

#region ========== Constants ==========

const BUTTON_STREAM: AudioStream = preload("res://Assets/Audio/Button.ogg")
const DRAG_STREAM: AudioStream = preload("res://Assets/Audio/Drag.ogg")
const DROP_STREAM: AudioStream = preload("res://Assets/Audio/Drop.ogg")
const CORRECT_STREAM: AudioStream = preload("res://Assets/Audio/Correct.ogg")
const WRONG_STREAM: AudioStream = preload("res://Assets/Audio/Wrong.ogg")
const HINT_STREAM: AudioStream = preload("res://Assets/Audio/Hint.ogg")
const VICTORY_STREAM: AudioStream = preload("res://Assets/Audio/Victory.ogg")

#endregion

#region ========== References ==========

var buttonPlayer: AudioStreamPlayer
var interactionPlayer: AudioStreamPlayer
var feedbackPlayer: AudioStreamPlayer
var masterVolume: float = 1.0
var sfxVolume: float = 1.0
var muted: bool = false

#endregion

#region ========== Godot Functions ==========

# Creates reusable players and binds buttons already present in the first scene.
func _ready() -> void:
	buttonPlayer = CreateAudioPlayer("ButtonPlayer")
	interactionPlayer = CreateAudioPlayer("InteractionPlayer")
	feedbackPlayer = CreateAudioPlayer("FeedbackPlayer")
	LoadAudioSettings()
	get_tree().node_added.connect(_on_node_added)
	RegisterButtons(get_tree().current_scene)

#endregion

#region ========== Functions ==========

# Creates one polyphonic player so repeated UI interactions do not cut each other off.
func CreateAudioPlayer(playerName: String) -> AudioStreamPlayer:
	var audioPlayer := AudioStreamPlayer.new()
	audioPlayer.name = playerName
	audioPlayer.max_polyphony = 4
	add_child(audioPlayer)
	return audioPlayer

# Loads persisted audio preferences and applies them to every SFX channel.
func LoadAudioSettings() -> void:
	var settingsData: Dictionary = SaveManager.GetSection("settings")
	masterVolume = settingsData.get("masterVolume", 1.0)
	sfxVolume = settingsData.get("sfxVolume", 1.0)
	muted = settingsData.get("mute", false)
	ApplyAudioVolume()

# Updates the shared Master Volume from a normalized linear value.
func SetMasterVolume(newVolume: float) -> void:
	masterVolume = clampf(newVolume, 0.0, 1.0)
	ApplyAudioVolume()

# Updates the shared SFX Volume from a normalized linear value.
func SetSFXVolume(newVolume: float) -> void:
	sfxVolume = clampf(newVolume, 0.0, 1.0)
	ApplyAudioVolume()

# Applies or removes mute without losing either saved volume level.
func SetMuted(isMuted: bool) -> void:
	muted = isMuted
	ApplyAudioVolume()

# Combines Master and SFX values for MathSmith's current audio-only mix.
func ApplyAudioVolume() -> void:
	var combinedVolume := masterVolume * sfxVolume
	var volumeDecibels := -80.0 if muted or combinedVolume <= 0.0 else linear_to_db(combinedVolume)

	for audioPlayer in [buttonPlayer, interactionPlayer, feedbackPlayer]:
		if is_instance_valid(audioPlayer):
			audioPlayer.volume_db = volumeDecibels

# Recursively connects all Buttons contained in a newly loaded UI branch.
func RegisterButtons(rootNode: Node) -> void:
	if not is_instance_valid(rootNode):
		return

	if rootNode is Button:
		RegisterButton(rootNode)

	for child in rootNode.get_children():
		RegisterButtons(child)

# Connects one Button once while preserving its existing actions.
func RegisterButton(button: Button) -> void:
	if not button.pressed.is_connected(PlayButton):
		button.pressed.connect(PlayButton)

# Plays the standard sound used by every enabled Button interaction.
func PlayButton() -> void:
	PlayStream(buttonPlayer, BUTTON_STREAM)

# Plays feedback when a Step Card begins dragging.
func PlayDrag() -> void:
	PlayStream(interactionPlayer, DRAG_STREAM)

# Plays feedback when a Step Card is placed.
func PlayDrop() -> void:
	PlayStream(interactionPlayer, DROP_STREAM)

# Plays positive answer feedback.
func PlayCorrect() -> void:
	PlayStream(feedbackPlayer, CORRECT_STREAM)

# Plays incorrect answer feedback.
func PlayWrong() -> void:
	PlayStream(feedbackPlayer, WRONG_STREAM)

# Plays focused Hint feedback.
func PlayHint() -> void:
	PlayStream(feedbackPlayer, HINT_STREAM)

# Plays Level completion feedback.
func PlayVictory() -> void:
	PlayStream(feedbackPlayer, VICTORY_STREAM)

# Assigns and plays a stream through the requested reusable channel.
func PlayStream(audioPlayer: AudioStreamPlayer, audioStream: AudioStream) -> void:
	if not is_instance_valid(audioPlayer):
		return

	audioPlayer.stream = audioStream
	audioPlayer.play()

# Registers Buttons added later, including generated Level and Step UI.
func _on_node_added(addedNode: Node) -> void:
	if addedNode is Button:
		RegisterButton(addedNode)

#endregion
