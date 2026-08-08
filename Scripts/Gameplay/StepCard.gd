# Attached Object
extends PanelContainer

# References
@onready var orderLabel: Label = $MarginContainer/HBoxContainer/OrderLabel
@onready var stepLabel: Label = $MarginContainer/HBoxContainer/StepLabel

# Functions
func Setup(order: int, stepText: String) -> void:
	orderLabel.text = str(order) + "."
	stepLabel.text = stepText
