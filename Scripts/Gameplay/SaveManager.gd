## Owns MathSmith's versioned Local Save data in Godot user storage.
##
## This manager validates top-level save sections and provides focused read,
## write, and reset entry points. Feature managers own the meaning of each
## section and pass serializable data through this shared persistence layer.
extends Node

#region ========== Constants ==========

const SAVE_FILE_PATH: String = "user://mathsmith_save.json"
const SAVE_SCHEMA_VERSION: int = 7
const CORE_CURRICULUM_SOURCE_ID: String = "core_curriculum"
const IMPORTED_COURSE_SOURCE_ID: String = "imported_course"
const STUDIO_COURSE_SOURCE_ID: String = "studio_course"
const COURSE_SOURCE_IDS: Array[String] = [
	CORE_CURRICULUM_SOURCE_ID,
	IMPORTED_COURSE_SOURCE_ID,
	STUDIO_COURSE_SOURCE_ID
]

#endregion

#region ========== Variables ==========

var saveData: Dictionary = {}
var activeCourseSourceId: String = CORE_CURRICULUM_SOURCE_ID
var coursePlayerDataWritesBlocked: bool = false

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
		"courseState": {"selectedCourseSource": CORE_CURRICULUM_SOURCE_ID},
		"courseData": {
			CORE_CURRICULUM_SOURCE_ID: GetDefaultCoursePlayerData(),
			IMPORTED_COURSE_SOURCE_ID: GetDefaultCoursePlayerData(),
			STUDIO_COURSE_SOURCE_ID: GetDefaultCoursePlayerData()
		},
		"courseContent": {
			IMPORTED_COURSE_SOURCE_ID: GetDefaultPersistedCourseContent(),
			STUDIO_COURSE_SOURCE_ID: GetDefaultPersistedCourseContent()
		},
		"tutorialState": {}
	}

# Returns a fresh independent player-learning dataset for one Course Source.
func GetDefaultCoursePlayerData() -> Dictionary:
	return {
		"levelProgress": {},
		"mistakeBook": [],
		"skillProgress": {},
		"zenMode": {"bestSolvedCount": 0},
		"survivalMode": {"bestSolvedCount": 0},
		"playerHistory": []
	}

# Returns an empty persistent authoring payload kept separate from player data.
func GetDefaultPersistedCourseContent() -> Dictionary:
	return {"content": {}, "metadata": {}}

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

	var requiresMigration: bool = (
		int(parsedData.get("version", 0)) < SAVE_SCHEMA_VERSION
		or not parsedData.has("courseData")
		or not parsedData.has("courseContent")
	)
	MergeSavedSections(parsedData)

	# Persist successful schema migration only after the complete merge exists.
	if requiresMigration:
		SaveLocalData()

# Preserves known serializable sections while filling absent future fields.
func MergeSavedSections(parsedData: Dictionary) -> void:
	var defaultData := GetDefaultSaveData()

	# Global preferences and tutorials remain shared across Course Sources.
	for sectionName in ["settings", "tutorialState", "courseState"]:
		if (
			parsedData.has(sectionName)
			and typeof(parsedData[sectionName]) == typeof(defaultData[sectionName])
		):
			saveData[sectionName] = parsedData[sectionName].duplicate(true)

	if parsedData.get("courseData", {}) is Dictionary and not parsedData.get("courseData", {}).is_empty():
		MergeCourseData(parsedData["courseData"])
	else:
		MigrateLegacyPlayerData(parsedData)

	# Imported and Studio content persist independently from their player records.
	var savedCourseContent = parsedData.get("courseContent", {})
	if savedCourseContent is Dictionary:
		MergePersistedCourseContent(savedCourseContent)

	# Loaded data always adopts the schema understood by this build.
	saveData["version"] = SAVE_SCHEMA_VERSION
	activeCourseSourceId = saveData["courseState"].get(
		"selectedCourseSource",
		CORE_CURRICULUM_SOURCE_ID
	)
	if activeCourseSourceId not in COURSE_SOURCE_IDS:
		activeCourseSourceId = CORE_CURRICULUM_SOURCE_ID
		saveData["courseState"]["selectedCourseSource"] = activeCourseSourceId

# Merges known Course fields while restoring any fields absent from old M6 data.
func MergeCourseData(savedCourseData: Dictionary) -> void:
	for courseSourceId in COURSE_SOURCE_IDS:
		var mergedCourseData := GetDefaultCoursePlayerData()
		var savedPlayerData = savedCourseData.get(courseSourceId, {})

		if savedPlayerData is Dictionary:
			for sectionName in mergedCourseData:
				if (
					savedPlayerData.has(sectionName)
					and typeof(savedPlayerData[sectionName]) == typeof(mergedCourseData[sectionName])
				):
					mergedCourseData[sectionName] = savedPlayerData[sectionName].duplicate(true)

		saveData["courseData"][courseSourceId] = mergedCourseData

# Merges only replaceable Course Source content from a versioned Local Save.
func MergePersistedCourseContent(savedCourseContent: Dictionary) -> void:
	for courseSourceId in [IMPORTED_COURSE_SOURCE_ID, STUDIO_COURSE_SOURCE_ID]:
		var savedCourseValue = savedCourseContent.get(courseSourceId, {})
		if not savedCourseValue is Dictionary:
			continue

		var persistedCourse := GetDefaultPersistedCourseContent()
		if savedCourseValue.get("content", {}) is Dictionary:
			persistedCourse["content"] = savedCourseValue.get("content", {}).duplicate(true)
		if savedCourseValue.get("metadata", {}) is Dictionary:
			persistedCourse["metadata"] = savedCourseValue.get("metadata", {}).duplicate(true)
		saveData["courseContent"][courseSourceId] = persistedCourse

# Moves all pre-M6 player-learning sections into Core Curriculum exactly once.
func MigrateLegacyPlayerData(parsedData: Dictionary) -> void:
	var migratedCoreData := GetDefaultCoursePlayerData()

	for sectionName in migratedCoreData:
		if (
			parsedData.has(sectionName)
			and typeof(parsedData[sectionName]) == typeof(migratedCoreData[sectionName])
		):
			migratedCoreData[sectionName] = parsedData[sectionName].duplicate(true)

	saveData["courseData"][CORE_CURRICULUM_SOURCE_ID] = migratedCoreData

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

# Selects the Course scope used by all player-learning feature managers.
func SetActiveCourseSource(courseSourceId: String, saveImmediately: bool = true) -> bool:
	if courseSourceId not in COURSE_SOURCE_IDS:
		return false

	activeCourseSourceId = courseSourceId
	saveData["courseState"]["selectedCourseSource"] = courseSourceId
	return SaveLocalData() if saveImmediately else true

# Returns isolated player-learning data from the active Course Source.
func GetCourseSection(sectionName: String) -> Variant:
	var coursePlayerData: Dictionary = saveData["courseData"].get(
		activeCourseSourceId,
		GetDefaultCoursePlayerData()
	)
	if not coursePlayerData.has(sectionName):
		return null

	var sectionData: Variant = coursePlayerData[sectionName]
	return sectionData.duplicate(true) if sectionData is Array or sectionData is Dictionary else sectionData

# Replaces one known section only inside the active Course Source.
func SetCourseSection(
	sectionName: String,
	sectionData: Variant,
	saveImmediately: bool = true
) -> bool:
	if coursePlayerDataWritesBlocked:
		return false
	var defaultCourseData := GetDefaultCoursePlayerData()
	if not defaultCourseData.has(sectionName):
		push_error("Cannot save unknown Course player-data section: " + sectionName)
		return false

	var coursePlayerData: Dictionary = saveData["courseData"].get(
		activeCourseSourceId,
		GetDefaultCoursePlayerData()
	)
	coursePlayerData[sectionName] = (
		sectionData.duplicate(true)
		if sectionData is Array or sectionData is Dictionary
		else sectionData
	)
	saveData["courseData"][activeCourseSourceId] = coursePlayerData
	return SaveLocalData() if saveImmediately else true

# Clears player-learning data for exactly one Course Source.
func ResetCoursePlayerData(courseSourceId: String) -> bool:
	if coursePlayerDataWritesBlocked:
		return false
	if courseSourceId not in COURSE_SOURCE_IDS:
		return false

	saveData["courseData"][courseSourceId] = GetDefaultCoursePlayerData()
	return SaveLocalData()

# Returns isolated persisted content for one replaceable Course Source.
func GetPersistedCourseContent(courseSourceId: String) -> Dictionary:
	if courseSourceId not in [IMPORTED_COURSE_SOURCE_ID, STUDIO_COURSE_SOURCE_ID]:
		return GetDefaultPersistedCourseContent()
	return saveData.get("courseContent", {}).get(
		courseSourceId,
		GetDefaultPersistedCourseContent()
	).duplicate(true)

# Persists normalized Imported or Studio content without touching player data.
func SetPersistedCourseContent(
	courseSourceId: String,
	contentData: Dictionary,
	metadata: Dictionary,
	resetCoursePlayerData: bool = false
) -> bool:
	if courseSourceId not in [IMPORTED_COURSE_SOURCE_ID, STUDIO_COURSE_SOURCE_ID]:
		return false
	if contentData.is_empty():
		return false
	if resetCoursePlayerData and coursePlayerDataWritesBlocked:
		return false

	var previousCourseContent: Dictionary = saveData["courseContent"].get(
		courseSourceId,
		GetDefaultPersistedCourseContent()
	).duplicate(true)
	var previousPlayerData: Dictionary = saveData["courseData"].get(
		courseSourceId,
		GetDefaultCoursePlayerData()
	).duplicate(true)
	saveData["courseContent"][courseSourceId] = {
		"content": contentData.duplicate(true),
		"metadata": metadata.duplicate(true)
	}
	if resetCoursePlayerData:
		saveData["courseData"][courseSourceId] = GetDefaultCoursePlayerData()
	if SaveLocalData():
		return true

	# Restore in-memory state when disk persistence fails.
	saveData["courseContent"][courseSourceId] = previousCourseContent
	saveData["courseData"][courseSourceId] = previousPlayerData
	return false

# Reports whether one replaceable Course Source has saved runtime content.
func HasPersistedCourseContent(courseSourceId: String) -> bool:
	return not GetPersistedCourseContent(courseSourceId).get("content", {}).is_empty()

# Removes one replaceable Course and its isolated player data atomically.
func ClearPersistedCourseContent(courseSourceId: String) -> bool:
	if courseSourceId not in [IMPORTED_COURSE_SOURCE_ID, STUDIO_COURSE_SOURCE_ID]:
		return false
	if coursePlayerDataWritesBlocked:
		return false

	var previousCourseContent: Dictionary = saveData["courseContent"][courseSourceId].duplicate(true)
	var previousPlayerData: Dictionary = saveData["courseData"][courseSourceId].duplicate(true)
	var previousCourseState: Dictionary = saveData["courseState"].duplicate(true)
	var previousActiveCourseSourceId: String = activeCourseSourceId
	saveData["courseContent"][courseSourceId] = GetDefaultPersistedCourseContent()
	saveData["courseData"][courseSourceId] = GetDefaultCoursePlayerData()
	if activeCourseSourceId == courseSourceId:
		activeCourseSourceId = CORE_CURRICULUM_SOURCE_ID
		saveData["courseState"]["selectedCourseSource"] = CORE_CURRICULUM_SOURCE_ID
	if SaveLocalData():
		return true

	# Restore every affected section if the save file could not be written.
	saveData["courseContent"][courseSourceId] = previousCourseContent
	saveData["courseData"][courseSourceId] = previousPlayerData
	saveData["courseState"] = previousCourseState
	activeCourseSourceId = previousActiveCourseSourceId
	return false

# Restores the default schema after a confirmed Reset Progress action.
func ResetAllData() -> bool:
	if coursePlayerDataWritesBlocked:
		return false
	saveData = GetDefaultSaveData()
	activeCourseSourceId = CORE_CURRICULUM_SOURCE_ID
	return SaveLocalData()

# Clears player learning records while preserving current preferences.
func ResetPlayerProgress() -> bool:
	if coursePlayerDataWritesBlocked:
		return false
	var settingsData: Dictionary = GetSection("settings")
	var courseState: Dictionary = GetSection("courseState")
	var courseContent: Dictionary = GetSection("courseContent")
	saveData = GetDefaultSaveData()
	saveData["settings"] = settingsData
	saveData["courseState"] = courseState
	saveData["courseContent"] = courseContent
	activeCourseSourceId = courseState.get(
		"selectedCourseSource",
		CORE_CURRICULUM_SOURCE_ID
	)
	return SaveLocalData()

# Blocks every Course-scoped player-data mutation during isolated QA sessions.
func SetCoursePlayerDataWritesBlocked(writesBlocked: bool) -> void:
	coursePlayerDataWritesBlocked = writesBlocked

#endregion
