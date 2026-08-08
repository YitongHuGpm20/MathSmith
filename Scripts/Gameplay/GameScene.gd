# Attached Object
extends Control

# Variables
const STEP_CARD_SCENE = preload("res://Scenes/Menus/StepCard.tscn")

# References
@onready var stepArea: VBoxContainer = $MainMargin/MainLayout/StepArea

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	CreateTestCards()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func CreateTestCards() -> void:
	var testSteps: Array[String] = [
		"21 + 29",
		"= (20 + 1) + (20 + 9)",
		"= (20 + 20) + (1 + 9)",
		"= 40 + 10",
		"= 50"
	]
	
	for i in range(testSteps.size()):
		var card = STEP_CARD_SCENE.instantiate()
		stepArea.add_child(card)
		card.Setup(i + 1, testSteps[i])
