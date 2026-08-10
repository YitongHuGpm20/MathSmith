## Manages drag-and-drop placement inside the Game Scene Step list.
##
## This UI component previews card positions and animates live reordering. It
## does not validate the resulting order or make gameplay progression decisions.
extends VBoxContainer

#region ========== Signals ==========

signal orderChanged

#endregion

#region ========== Godot Functions ==========

# Accepts StepCard controls dragged within this step area.
func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if not data is PanelContainer or data.get_parent() != self:
		return false

	PreviewCardPosition(data, GetDropIndex(at_position.y))
	return true

# Moves a dropped StepCard to the position nearest the pointer.
func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if data.get_parent() != self:
		return

	# Hovering already selected the position; dropping confirms the visual order.
	ConfirmCardPosition()
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

# Moves a dragged card immediately and animates surrounding cards into place.
func PreviewCardPosition(stepCard: Control, targetIndex: int) -> void:
	var currentIndex := stepCard.get_index()
	var boundedIndex := clampi(targetIndex, 0, get_child_count() - 1)

	if boundedIndex == currentIndex:
		return

	var previousPositions: Dictionary = {}

	for child in get_children():
		previousPositions[child] = child.position

	move_child(stepCard, boundedIndex)
	queue_sort()
	AnimateCardPositions.call_deferred(previousPositions, stepCard)
	orderChanged.emit()

# Tweens non-dragged cards from their previous slots to their new slots.
func AnimateCardPositions(previousPositions: Dictionary, draggedCard: Control) -> void:
	for child in get_children():
		if child == draggedCard or not previousPositions.has(child):
			continue

		var targetPosition: Vector2 = child.position
		var previousPosition: Vector2 = previousPositions[child]

		if previousPosition.is_equal_approx(targetPosition):
			continue

		child.position = previousPosition
		var reorderTween := child.create_tween()
		reorderTween.set_trans(Tween.TRANS_QUAD)
		reorderTween.set_ease(Tween.EASE_OUT)
		reorderTween.tween_property(child, "position", targetPosition, 0.14)

# Emits the final order after a drag is released.
func ConfirmCardPosition() -> void:
	orderChanged.emit()

#endregion
