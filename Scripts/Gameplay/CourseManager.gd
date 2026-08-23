## Owns MathSmith's active Course Source and its independent runtime content.
##
## This manager centralizes Course Source identity, availability, metadata, and
## content access. It does not own player progress or authoring persistence.
extends RefCounted

#region ========== Constants ==========

const CORE_CURRICULUM_SOURCE_ID: String = "core_curriculum"
const IMPORTED_COURSE_SOURCE_ID: String = "imported_course"
const STUDIO_COURSE_SOURCE_ID: String = "studio_course"

const COURSE_SOURCE_DISPLAY_NAMES: Dictionary = {
	CORE_CURRICULUM_SOURCE_ID: "Core Curriculum",
	IMPORTED_COURSE_SOURCE_ID: "Imported Course",
	STUDIO_COURSE_SOURCE_ID: "Studio Course"
}

#endregion

#region ========== Variables ==========

var courseSources: Dictionary = {}
var currentCourseSourceId: String = CORE_CURRICULUM_SOURCE_ID

#endregion

#region ========== Functions ==========

# Creates all supported Course Sources and installs immutable built-in content.
func Initialize(coreContentData: Dictionary) -> bool:
	if not IsUsableContent(coreContentData):
		push_error("Core Curriculum content is missing Level Types or Levels.")
		return false

	courseSources.clear()
	for courseSourceId in COURSE_SOURCE_DISPLAY_NAMES:
		courseSources[courseSourceId] = CreateEmptyCourseSource(courseSourceId)

	courseSources[CORE_CURRICULUM_SOURCE_ID] = CreateCourseSource(
		CORE_CURRICULUM_SOURCE_ID,
		coreContentData,
		{"builtIn": true}
	)
	currentCourseSourceId = CORE_CURRICULUM_SOURCE_ID
	return true

# Registers replaceable Imported or Studio content after external validation.
func RegisterCourseContent(
	courseSourceId: String,
	contentData: Dictionary,
	metadata: Dictionary = {}
) -> bool:
	if courseSourceId == CORE_CURRICULUM_SOURCE_ID or not courseSources.has(courseSourceId):
		return false
	if not IsUsableContent(contentData):
		return false

	courseSources[courseSourceId] = CreateCourseSource(
		courseSourceId,
		contentData,
		metadata
	)
	return true

# Clears one replaceable runtime Course Source without affecting built-in content.
func ClearCourseContent(courseSourceId: String) -> bool:
	if courseSourceId == CORE_CURRICULUM_SOURCE_ID or not courseSources.has(courseSourceId):
		return false
	courseSources[courseSourceId] = CreateEmptyCourseSource(courseSourceId)
	if currentCourseSourceId == courseSourceId:
		currentCourseSourceId = CORE_CURRICULUM_SOURCE_ID
	return true

# Selects one available Course Source without guessing from gameplay state.
func SelectCourseSource(courseSourceId: String) -> bool:
	if not IsCourseSourceAvailable(courseSourceId):
		return false

	currentCourseSourceId = courseSourceId
	return true

# Returns the reliable active Course Source context used by later M6 systems.
func GetCurrentCourseSourceId() -> String:
	return currentCourseSourceId

# Returns isolated content for the active Course Source.
func GetCurrentCourseContent() -> Dictionary:
	if not courseSources.has(currentCourseSourceId):
		return {}
	return courseSources[currentCourseSourceId]["content"].duplicate(true)

# Returns isolated content for one explicitly requested Course Source.
func GetCourseContent(courseSourceId: String) -> Dictionary:
	if not IsCourseSourceAvailable(courseSourceId):
		return {}
	return courseSources[courseSourceId]["content"].duplicate(true)

# Returns player-facing metadata for every supported Course Source.
func GetCourseSourceSummaries() -> Array[Dictionary]:
	var summaries: Array[Dictionary] = []
	for courseSourceId in COURSE_SOURCE_DISPLAY_NAMES:
		var courseSource: Dictionary = courseSources.get(
			courseSourceId,
			CreateEmptyCourseSource(courseSourceId)
		)
		var metadata: Dictionary = courseSource.get("metadata", {})
		summaries.append({
			"id": courseSourceId,
			"displayName": COURSE_SOURCE_DISPLAY_NAMES[courseSourceId],
			"available": courseSource.get("available", false),
			"levelCount": metadata.get("levelCount", 0),
			"questionCount": metadata.get("questionCount", 0),
			"metadata": metadata.duplicate(true)
		})
	return summaries

# Returns whether a known Course Source currently contains playable content.
func IsCourseSourceAvailable(courseSourceId: String) -> bool:
	if not courseSources.has(courseSourceId):
		return false
	return courseSources[courseSourceId].get("available", false)

# Builds one normalized runtime Course Source entry and calculated metadata.
func CreateCourseSource(
	courseSourceId: String,
	contentData: Dictionary,
	metadata: Dictionary
) -> Dictionary:
	var normalizedMetadata := metadata.duplicate(true)
	normalizedMetadata["courseSource"] = courseSourceId
	normalizedMetadata["displayName"] = COURSE_SOURCE_DISPLAY_NAMES[courseSourceId]
	normalizedMetadata["levelCount"] = contentData.get("levels", []).size()
	normalizedMetadata["questionCount"] = CountQuestions(contentData.get("levels", []))
	return {
		"available": true,
		"content": contentData.duplicate(true),
		"metadata": normalizedMetadata
	}

# Builds the unavailable state used by Imported and Studio before authoring.
func CreateEmptyCourseSource(courseSourceId: String) -> Dictionary:
	return {
		"available": false,
		"content": {},
		"metadata": {
			"courseSource": courseSourceId,
			"displayName": COURSE_SOURCE_DISPLAY_NAMES[courseSourceId],
			"levelCount": 0,
			"questionCount": 0
		}
	}

# Checks the minimal normalized runtime shape without duplicating validation.
func IsUsableContent(contentData: Dictionary) -> bool:
	if not contentData.get("level_types", {}) is Dictionary:
		return false
	if contentData.get("level_types", {}).is_empty():
		return false
	if not contentData.get("levels", []) is Array:
		return false
	var courseLevels: Array = contentData.get("levels", [])
	if courseLevels.is_empty():
		return false
	for levelValue in courseLevels:
		if not levelValue is Dictionary:
			return false
		var questions: Array = levelValue.get("questions", [])
		if questions.is_empty():
			return false
		for questionValue in questions:
			if not questionValue is Dictionary:
				return false
			if str(questionValue.get("id", "")).is_empty():
				return false
			if str(questionValue.get("expression", "")).is_empty():
				return false
	return true

# Counts Questions across all Levels for lightweight Course metadata.
func CountQuestions(courseLevels: Array) -> int:
	var questionCount := 0
	for level in courseLevels:
		questionCount += level.get("questions", []).size()
	return questionCount

#endregion
