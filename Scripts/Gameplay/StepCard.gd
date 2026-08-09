## Presents one draggable solution step inside the gameplay step area.
##
## This UI component stores display text and supports visual drag-and-drop. It
## does not know whether its current position is correct.
extends PanelContainer

#region ========== References ==========

@onready var orderLabel: Label = $MarginContainer/HBoxContainer/OrderLabel
@onready var stepLabel: Label = $MarginContainer/HBoxContainer/StepLabel

#endregion

#region ========== Variables ==========

var stepText: String = ""

#endregion

#region ========== Godot Functions ==========

# Creates a translucent visual copy while this card is being dragged.
func _get_drag_data(at_position: Vector2) -> Variant:
	var dragPreview := duplicate()
	dragPreview.modulate.a = 0.7
	set_drag_preview(dragPreview)
	return self

# Accepts another StepCard from the same visual step area.
func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	return data is PanelContainer and data != self

# Moves the dragged card to this card's current list position.
func _drop_data(at_position: Vector2, data: Variant) -> void:
	if data.get_parent() != get_parent():
		return

	# Delegate list positioning and label refresh to the shared StepArea.
	var stepArea := get_parent()
	stepArea.move_child(data, get_index())
	stepArea.UpdateOrderLabels()

#endregion

#region ========== Functions ==========

# Applies the displayed order number and generated solution text.
func Setup(orderNumber: int, displayText: String) -> void:
	stepText = displayText
	orderLabel.text = str(orderNumber) + "."
	stepLabel.text = displayText

#endregion
