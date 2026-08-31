## Animates the reusable floating Tutor entry bubble.
extends Button

#region ========== Variables ==========

var bubbleTween: Tween = null

#endregion

#region ========== Godot Functions ==========

# Starts subtle motion and binds pointer-driven rolling feedback.
func _ready() -> void:
	mouse_entered.connect(AnimateHover)
	mouse_exited.connect(AnimateRest)
	ConfigureBubble.call_deferred()

#endregion

#region ========== Functions ==========

# Centers transforms before beginning the idle animation.
func ConfigureBubble() -> void:
	pivot_offset = size * 0.5
	StartIdle()

# Rotates slowly by a few degrees while the Tutor is available.
func StartIdle() -> void:
	KillBubbleTween()
	bubbleTween = create_tween().set_loops()
	bubbleTween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	bubbleTween.tween_property(self, "rotation", deg_to_rad(3.0), 1.4)
	bubbleTween.tween_property(self, "rotation", deg_to_rad(-3.0), 1.4)

# Rolls and enlarges the bubble slightly under the pointer.
func AnimateHover() -> void:
	KillBubbleTween()
	bubbleTween = create_tween().set_parallel(true)
	bubbleTween.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	bubbleTween.tween_property(self, "rotation", deg_to_rad(18.0), 0.28)
	bubbleTween.tween_property(self, "scale", Vector2(1.08, 1.08), 0.28)

# Returns smoothly to rest and resumes idle motion.
func AnimateRest() -> void:
	KillBubbleTween()
	bubbleTween = create_tween().set_parallel(true)
	bubbleTween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	bubbleTween.tween_property(self, "rotation", 0.0, 0.24)
	bubbleTween.tween_property(self, "scale", Vector2.ONE, 0.24)
	bubbleTween.chain().tween_callback(StartIdle)

# Prevents idle and hover animations from competing.
func KillBubbleTween() -> void:
	if bubbleTween != null and bubbleTween.is_valid():
		bubbleTween.kill()
	bubbleTween = null

#endregion
