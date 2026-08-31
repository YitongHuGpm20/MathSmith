## Presents Yitong Hu's personal brand before MathSmith opens.
##
## The Splash Screen owns only its short visual sequence and transitions to
## HomeScene without reading or changing gameplay data.
extends Control

#region ========== Constants ==========

const HOME_SCENE_PATH: String = "res://Scenes/HomeScene.tscn"
const FADE_IN_DURATION: float = 0.55
const HOLD_DURATION: float = 1.25
const FADE_OUT_DURATION: float = 0.5

#endregion

#region ========== References ==========

@onready var brandGroup: Control = %BrandGroup
@onready var logo: TextureRect = %Logo
@onready var transitionOverlay: ColorRect = %TransitionOverlay

#endregion

#region ========== Variables ==========

var splashTween: Tween = null
var transitionStarted: bool = false

#endregion

#region ========== Godot Functions ==========

# Starts the single non-blocking brand animation after layout is available.
func _ready() -> void:
	brandGroup.modulate.a = 0.0
	brandGroup.scale = Vector2(0.94, 0.94)
	transitionOverlay.modulate.a = 0.0
	await get_tree().process_frame
	brandGroup.pivot_offset = brandGroup.size * 0.5
	logo.pivot_offset = logo.size * 0.5
	PlaySplashSequence()

# Allows the Splash Screen to be skipped without triggering duplicate changes.
func _unhandled_input(event: InputEvent) -> void:
	if event.is_pressed() and not transitionStarted:
		BeginHomeTransition()
		get_viewport().set_input_as_handled()

#endregion

#region ========== Functions ==========

# Fades and settles the personal Logo before opening the main menu.
func PlaySplashSequence() -> void:
	splashTween = create_tween()
	splashTween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	splashTween.tween_property(brandGroup, "modulate:a", 1.0, FADE_IN_DURATION)
	splashTween.parallel().tween_property(
		brandGroup,
		"scale",
		Vector2.ONE,
		FADE_IN_DURATION
	)
	splashTween.tween_interval(HOLD_DURATION)
	splashTween.tween_callback(BeginHomeTransition)

# Covers the screen cleanly before loading HomeScene exactly once.
func BeginHomeTransition() -> void:
	if transitionStarted:
		return
	transitionStarted = true
	if splashTween != null and splashTween.is_running():
		splashTween.kill()
	var exitTween := create_tween()
	exitTween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	exitTween.tween_property(brandGroup, "modulate:a", 0.0, FADE_OUT_DURATION)
	exitTween.parallel().tween_property(
		brandGroup,
		"scale",
		Vector2(1.035, 1.035),
		FADE_OUT_DURATION
	)
	exitTween.parallel().tween_property(
		transitionOverlay,
		"modulate:a",
		1.0,
		FADE_OUT_DURATION
	)
	exitTween.tween_callback(OpenHomeScene)

# Hands startup control to the existing Home Scene.
func OpenHomeScene() -> void:
	get_tree().change_scene_to_file(HOME_SCENE_PATH)

#endregion
