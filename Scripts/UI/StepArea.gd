## Manages drag-and-drop placement inside the Game Scene Step list.
##
## This UI component changes card positions and refreshes order labels. It does
## not validate the resulting order or make gameplay progression decisions.
extends VBoxContainer

#region ========== Signals ==========

signal orderChanged

#endregion

#region ========== Godot Functions ==========

# Accepts StepCard controls dragged within this step area.
func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data is PanelContainer

# Moves a dropped StepCard to the position nearest the pointer.
func _drop_data(at_position: Vector2, data: Variant) -> void:
	if data.get_parent() != self:
		return

	# Reposition the card and refresh all displayed order numbers.
	var targetIndex := GetDropIndex(at_position.y)
	move_child(data, targetIndex)
	UpdateOrderLabels()
	orderChanged.emit()
	AudioManager.PlayDrop()

#endregion

#region ========== Functions ==========

# Returns the child index nearest the supplied vertical pointer position.
func GetDropIndex(mouseY: float) -> int:
	for childIndex in range(get_child_count()):
		var child := get_child(childIndex)

		if mouseY < child.position.y + child.size.y * 0.5:
			return childIndex

	return maxi(get_child_count() - 1, 0)

# Refreshes every card label after the visual order changes.
func UpdateOrderLabels() -> void:
	for childIndex in range(get_child_count()):
		var stepCard := get_child(childIndex)
		stepCard.Setup(childIndex + 1, stepCard.stepText)

#endregion
