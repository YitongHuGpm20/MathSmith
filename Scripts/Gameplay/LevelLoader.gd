# Attached Object
extends Node

# Variables
const LEVEL_DATA_PATH := "res://Data/SampleLevels.json"

# Functions
func LoadLevels() -> Array:
	# Load external data file
	var file := FileAccess.open(LEVEL_DATA_PATH, FileAccess.READ)

	if file == null:
		push_error("Failed to open level data: " + LEVEL_DATA_PATH)
		return []

	# Translate JSON to string
	var jsonText := file.get_as_text()
	file.close()

	# Translate string to Godot-readable data structure
	var json := JSON.new()
	var error := json.parse(jsonText)

	if error != OK:
		push_error(
			"Failed to parse level JSON at line %d: %s"
			% [json.get_error_line(), json.get_error_message()]
		)
		return []

	# Translation completed
	var data = json.data

	if typeof(data) != TYPE_DICTIONARY:
		push_error("Level JSON root must be a Dictionary.")
		return []

	if not data.has("levels"):
		push_error("Level JSON is missing the 'levels' field.")
		return []

	if typeof(data["levels"]) != TYPE_ARRAY:
		push_error("'levels' must be an Array.")
		return []

	return data["levels"]
