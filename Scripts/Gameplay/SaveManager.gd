## Owns MathSmith's versioned Local Save data in Godot user storage.
##
## This manager validates top-level save sections and provides focused read,
## write, and reset entry points. Feature managers own the meaning of each
## section and pass serializable data through this shared persistence layer.
extends Node

#region ========== Constants ==========

const SAVE_FILE_PATH: String = "user://mathsmith_save.json"
const SAVE_SCHEMA_VERSION: int = 5

#endregion

#region ========== Variables ==========

var saveData: Dictionary = {}

#endregion

#region ========== Godot Functions ==========

# Loads and validates Local Save data before later autoloads request it.
func _ready() -> void:
	LoadSaveData()

#endregion

#region ========== Functions ==========

# Returns a fresh schema containing current persistent learning data sections.
func GetDefaultSaveData() -> Dictionary:
	return {
		"version": SAVE_SCHEMA_VERSION,
		"settings": {
			"masterVolume": 1.0,
			"sfxVolume": 1.0,
			"mute": false,
			"language": "en"
		},
		"levelProgress": {},
		"mistakeBook": [],
		"skillProgress": {},
		"zenMode": {"bestSolvedCount": 0},
		"survivalMode": {"bestSolvedCount": 0},
		"playerHistory": [],
		"tutorialState": {}
	}

# Loads JSON data and restores missing sections from the current schema.
func LoadSaveData() -> void:
	saveData = GetDefaultSaveData()

	if not FileAccess.file_exists(SAVE_FILE_PATH):
		return

	var saveFile := FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)

	if saveFile == null:
		push_warning("Local Save could not be opened for reading.")
		return

	var parsedData = JSON.parse_string(saveFile.get_as_text())

	if not parsedData is Dictionary:
		push_warning("Local Save contains invalid JSON and defaults will be used.")
		return

	MergeSavedSections(parsedData)

# Preserves known serializable sections while filling absent future fields.
func MergeSavedSections(parsedData: Dictionary) -> void:
	var defaultData := GetDefaultSaveData()

	for sectionName in defaultData:
		if sectionName == "version":
			continue

		if parsedData.has(sectionName) and typeof(parsedData[sectionName]) == typeof(defaultData[sectionName]):
			saveData[sectionName] = parsedData[sectionName]

	# Loaded data always adopts the schema understood by this build.
	saveData["version"] = SAVE_SCHEMA_VERSION

# Writes the complete versioned schema to Godot's user storage.
func SaveLocalData() -> bool:
	var saveFile := FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)

	if saveFile == null:
		push_error("Local Save could not be opened for writing.")
		return false

	saveFile.store_string(JSON.stringify(saveData, "\t"))
	return true

# Returns an isolated copy so feature code cannot mutate storage accidentally.
func GetSection(sectionName: String) -> Variant:
	if not saveData.has(sectionName):
		return null

	var sectionData: Variant = saveData[sectionName]
	return sectionData.duplicate(true) if sectionData is Array or sectionData is Dictionary else sectionData

# Replaces one known section and optionally writes it immediately.
func SetSection(sectionName: String, sectionData: Variant, saveImmediately: bool = true) -> bool:
	if sectionName == "version" or not saveData.has(sectionName):
		push_error("Cannot save unknown Local Save section: " + sectionName)
		return false

	saveData[sectionName] = (
		sectionData.duplicate(true)
		if sectionData is Array or sectionData is Dictionary
		else sectionData
	)

	return SaveLocalData() if saveImmediately else true

# Restores the default schema after a confirmed Reset Progress action.
func ResetAllData() -> bool:
	saveData = GetDefaultSaveData()
	return SaveLocalData()

# Clears player learning records while preserving current preferences.
func ResetPlayerProgress() -> bool:
	var settingsData: Dictionary = GetSection("settings")
	saveData = GetDefaultSaveData()
	saveData["settings"] = settingsData
	return SaveLocalData()

#endregion
