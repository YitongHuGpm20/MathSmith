## Owns safe Imported Course persistence and replacement policy.
##
## This service keeps validated content unchanged until explicit confirmation,
## resets only Imported Course player data when content materially changes, and
## rolls runtime state back when Local Save persistence fails.
extends RefCounted

#region ========== Constants ==========

const IMPORTED_COURSE_SOURCE_ID: String = "imported_course"
const STUDIO_COURSE_SOURCE_ID: String = "studio_course"
const RESET_PLAYER_DATA_ON_CONTENT_CHANGE: bool = true

#endregion

#region ========== Functions ==========

# Restores independently persisted Imported and Studio content at application start.
func RestorePersistedCourseSources(courseManager: RefCounted) -> void:
	for courseSourceId in [IMPORTED_COURSE_SOURCE_ID, STUDIO_COURSE_SOURCE_ID]:
		var persistedCourse: Dictionary = SaveManager.GetPersistedCourseContent(courseSourceId)
		var persistedContent: Dictionary = persistedCourse.get("content", {})
		var persistedMetadata: Dictionary = persistedCourse.get("metadata", {})
		if persistedContent.is_empty():
			continue
		# Studio working data may intentionally remain incomplete between edits.
		if (
			courseSourceId == STUDIO_COURSE_SOURCE_ID
			and not courseManager.IsUsableContent(persistedContent)
		):
			continue
		if not courseManager.RegisterCourseContent(courseSourceId, persistedContent, persistedMetadata):
			push_warning("Saved Course content could not be restored: " + courseSourceId)

# Registers and persists the first validated Imported Course atomically.
func SaveFirstImportedCourse(
	courseManager: RefCounted,
	contentData: Dictionary,
	metadata: Dictionary
) -> Dictionary:
	if courseManager.IsCourseSourceAvailable(IMPORTED_COURSE_SOURCE_ID):
		return CreateImportResult(false, false)

	var persistedMetadata := BuildImportMetadata(metadata, {})
	if not courseManager.RegisterCourseContent(
		IMPORTED_COURSE_SOURCE_ID,
		contentData,
		persistedMetadata
	):
		return CreateImportResult(false, false)

	if not SaveManager.SetPersistedCourseContent(
		IMPORTED_COURSE_SOURCE_ID,
		contentData,
		persistedMetadata
	):
		courseManager.ClearCourseContent(IMPORTED_COURSE_SOURCE_ID)
		return CreateImportResult(false, false)

	return CreateImportResult(true, false)

# Replaces one existing Imported Course only after external validation and confirmation.
func ReplaceImportedCourse(
	courseManager: RefCounted,
	contentData: Dictionary,
	metadata: Dictionary
) -> Dictionary:
	if not courseManager.IsCourseSourceAvailable(IMPORTED_COURSE_SOURCE_ID):
		return SaveFirstImportedCourse(courseManager, contentData, metadata)

	var previousPersistedCourse := SaveManager.GetPersistedCourseContent(
		IMPORTED_COURSE_SOURCE_ID
	)
	var previousContent: Dictionary = previousPersistedCourse.get("content", {})
	var previousMetadata: Dictionary = previousPersistedCourse.get("metadata", {})
	var contentChanged := HasMaterialContentChange(previousContent, contentData)
	var shouldResetPlayerData := RESET_PLAYER_DATA_ON_CONTENT_CHANGE and contentChanged
	var persistedMetadata := BuildImportMetadata(metadata, previousMetadata)

	# Update runtime first, then restore its snapshot if the atomic Save write fails.
	if not courseManager.RegisterCourseContent(
		IMPORTED_COURSE_SOURCE_ID,
		contentData,
		persistedMetadata
	):
		return CreateImportResult(false, false)

	if not SaveManager.SetPersistedCourseContent(
		IMPORTED_COURSE_SOURCE_ID,
		contentData,
		persistedMetadata,
		shouldResetPlayerData
	):
		courseManager.RegisterCourseContent(
			IMPORTED_COURSE_SOURCE_ID,
			previousContent,
			previousMetadata
		)
		return CreateImportResult(false, false)

	return CreateImportResult(true, shouldResetPlayerData)

# Preserves original import time while refreshing source and modification metadata.
func BuildImportMetadata(metadata: Dictionary, previousMetadata: Dictionary) -> Dictionary:
	var persistedMetadata := metadata.duplicate(true)
	var currentUnixMs := int(Time.get_unix_time_from_system() * 1000.0)
	persistedMetadata["importedAtUnixMs"] = previousMetadata.get(
		"importedAtUnixMs",
		currentUnixMs
	)
	persistedMetadata["lastModifiedAtUnixMs"] = currentUnixMs
	return persistedMetadata

# Compares normalized runtime data instead of filenames or display-only metadata.
func HasMaterialContentChange(previousContent: Dictionary, newContent: Dictionary) -> bool:
	return JSON.stringify(previousContent) != JSON.stringify(newContent)

# Removes Imported content and only its Course-scoped player records.
func RemoveImportedCourse(courseManager: RefCounted) -> Dictionary:
	if not SaveManager.HasPersistedCourseContent(IMPORTED_COURSE_SOURCE_ID):
		return CreateImportResult(false, false)
	if not SaveManager.ClearPersistedCourseContent(IMPORTED_COURSE_SOURCE_ID):
		return CreateImportResult(false, false)
	courseManager.ClearCourseContent(IMPORTED_COURSE_SOURCE_ID)
	return CreateImportResult(true, true)

# Returns consistent operation feedback for the Teacher Dashboard.
func CreateImportResult(succeeded: bool, playerDataReset: bool) -> Dictionary:
	return {
		"succeeded": succeeded,
		"playerDataReset": playerDataReset
	}

#endregion
