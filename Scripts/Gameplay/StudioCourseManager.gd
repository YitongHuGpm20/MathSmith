## Owns the persistent working data for the independently authored Studio Course.
##
## A Studio draft may contain no Levels while it is being authored. Only a
## complete playable Studio Course is registered with the runtime CourseManager.
extends RefCounted

#region ========== Constants ==========

const STUDIO_COURSE_SOURCE_ID: String = "studio_course"

#endregion

#region ========== Functions ==========

# Creates and persists a new empty Studio Course without affecting player data.
func CreateNewStudioCourse(levelTypes: Dictionary) -> Dictionary:
	if HasStudioCourse():
		return CreateOperationResult(false)

	var currentUnixMs := int(Time.get_unix_time_from_system() * 1000.0)
	var studioContent := {
		"level_types": levelTypes.duplicate(true),
		"levels": []
	}
	var studioMetadata := {
		"courseSource": STUDIO_COURSE_SOURCE_ID,
		"displayName": "Studio Course",
		"courseName": "Untitled Studio Course",
		"createdAtUnixMs": currentUnixMs,
		"lastModifiedAtUnixMs": currentUnixMs,
		"levelCount": 0,
		"questionCount": 0
	}
	var succeeded := SaveManager.SetPersistedCourseContent(
		STUDIO_COURSE_SOURCE_ID,
		studioContent,
		studioMetadata
	)
	return CreateOperationResult(succeeded)

# Deep-copies Imported content into an independently persisted Studio Course.
func CopyImportedCourseToStudio(
	courseManager: RefCounted,
	importedContent: Dictionary,
	importedMetadata: Dictionary,
	replaceExisting: bool
) -> Dictionary:
	if importedContent.is_empty() or not courseManager.IsUsableContent(importedContent):
		return CreateOperationResult(false)
	if HasStudioCourse() and not replaceExisting:
		return CreateOperationResult(false)

	var previousStudioCourse := SaveManager.GetPersistedCourseContent(
		STUDIO_COURSE_SOURCE_ID
	)
	var previousContent: Dictionary = previousStudioCourse.get("content", {})
	var previousMetadata: Dictionary = previousStudioCourse.get("metadata", {})
	var contentChanged := JSON.stringify(previousContent) != JSON.stringify(importedContent)
	var currentUnixMs := int(Time.get_unix_time_from_system() * 1000.0)
	var studioMetadata := importedMetadata.duplicate(true)
	studioMetadata["courseSource"] = STUDIO_COURSE_SOURCE_ID
	studioMetadata["displayName"] = "Studio Course"
	studioMetadata["createdAtUnixMs"] = currentUnixMs
	studioMetadata["copiedFrom"] = "imported_course"
	studioMetadata["copiedAtUnixMs"] = currentUnixMs
	studioMetadata["lastModifiedAtUnixMs"] = currentUnixMs

	# Register a deep runtime copy, then roll it back if disk persistence fails.
	if not courseManager.RegisterCourseContent(
		STUDIO_COURSE_SOURCE_ID,
		importedContent.duplicate(true),
		studioMetadata
	):
		return CreateOperationResult(false)
	if SaveManager.SetPersistedCourseContent(
		STUDIO_COURSE_SOURCE_ID,
		importedContent.duplicate(true),
		studioMetadata,
		contentChanged
	):
		return CreateOperationResult(true)

	if courseManager.IsUsableContent(previousContent):
		courseManager.RegisterCourseContent(
			STUDIO_COURSE_SOURCE_ID,
			previousContent,
			previousMetadata
		)
	else:
		courseManager.ClearCourseContent(STUDIO_COURSE_SOURCE_ID)
	return CreateOperationResult(false)

# Returns whether persistent Studio working data exists, even when still empty.
func HasStudioCourse() -> bool:
	return SaveManager.HasPersistedCourseContent(STUDIO_COURSE_SOURCE_ID)

# Returns metadata describing the persistent Studio working dataset.
func GetStudioCourseSummary() -> Dictionary:
	var persistedCourse := SaveManager.GetPersistedCourseContent(STUDIO_COURSE_SOURCE_ID)
	var studioContent: Dictionary = persistedCourse.get("content", {})
	var studioMetadata: Dictionary = persistedCourse.get("metadata", {})
	return {
		"exists": not studioContent.is_empty(),
		"levelCount": studioContent.get("levels", []).size(),
		"questionCount": CountQuestions(studioContent.get("levels", [])),
		"metadata": studioMetadata.duplicate(true)
	}

# Returns an isolated snapshot for the Visual Course Editor workspace.
func GetStudioCourseData() -> Dictionary:
	return SaveManager.GetPersistedCourseContent(STUDIO_COURSE_SOURCE_ID)

# Counts authored Questions without requiring the draft to be playable yet.
func CountQuestions(courseLevels: Array) -> int:
	var questionCount := 0
	for levelValue in courseLevels:
		questionCount += levelValue.get("questions", []).size()
	return questionCount

# Returns consistent feedback for Studio authoring operations.
func CreateOperationResult(succeeded: bool) -> Dictionary:
	return {"succeeded": succeeded}

#endregion
