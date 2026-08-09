# Attached Object
extends PanelContainer

# References
@onready var orderLabel: Label = $MarginContainer/HBoxContainer/OrderLabel
@onready var stepLabel: Label = $MarginContainer/HBoxContainer/StepLabel

# Variables
var stepText: String = ""

# ========== Functions ==========

# Set up step card texts
func Setup(order: int, text: String) -> void:
	stepText = text
	orderLabel.text = str(order) + "."
	stepLabel.text = text


func _get_drag_data(atPosition: Vector2):
	var preview := duplicate()
	preview.modulate.a = 0.7
	set_drag_preview(preview)
	return self

func _can_drop_data(atPosition: Vector2, data) -> bool:
	return data is PanelContainer and data != self


func _drop_data(atPosition: Vector2, data) -> void:
	if data.get_parent() != get_parent():
		return

	var stepArea = get_parent()
	var targetIndex := get_index()
	stepArea.move_child(data, targetIndex)
	UpdateOrderLabels()


func UpdateOrderLabels() -> void:
	var stepArea = get_parent()

	for i in range(stepArea.get_child_count()):
		var card = stepArea.get_child(i)

		if card.has_method("Setup"):
			card.Setup(i + 1, card.stepText)
