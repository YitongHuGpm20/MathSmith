# Attached Object
extends VBoxContainer

# ========== Functions ==========


func _can_drop_data(atPosition: Vector2, data) -> bool:
	return data is PanelContainer


func _drop_data(atPosition: Vector2, data) -> void:
	if data.get_parent() != self:
		return

	var targetIndex := GetDropIndex(atPosition.y)
	move_child(data, targetIndex)
	UpdateOrderLabels()


func GetDropIndex(mouseY: float) -> int:
	for i in range(get_child_count()):
		var child := get_child(i)

		if mouseY < child.position.y + child.size.y * 0.5:
			return i

	return get_child_count() - 1


func UpdateOrderLabels() -> void:
	for i in range(get_child_count()):
		var card = get_child(i)

		if card.has_method("Setup"):
			card.Setup(i + 1, card.stepText)
