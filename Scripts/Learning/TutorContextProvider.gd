## Builds one course-scoped snapshot for MathSmith's deterministic Tutor.
##
## The provider only normalizes state supplied by existing systems. It does not
## calculate correctness, Mastery, recommendations, scoring, or progression.
extends RefCounted

#region ========== Constants ==========

const TUTOR_CONTEXT_SCHEMA_VERSION: int = 1
const RECENT_HISTORY_LIMIT: int = 5
const RECOMMENDATION_LIMIT: int = 3

#endregion

#region ========== Functions ==========

# Builds the stable context contract consumed by later Tutor services and UI.
func BuildContext(
	runtimeState: Dictionary,
	learningState: Dictionary,
	courseState: Dictionary
) -> Dictionary:
	var playerHistory: Array = learningState.get("playerHistory", [])
	var recommendations: Array = learningState.get("recommendations", [])
	return {
		"tutorContextSchemaVersion": TUTOR_CONTEXT_SCHEMA_VERSION,
		"generatedAtUnixMs": int(Time.get_unix_time_from_system() * 1000.0),
		"screen": runtimeState.get("screen", {}).duplicate(true),
		"course": BuildCourseContext(courseState),
		"session": runtimeState.get("session", {}).duplicate(true),
		"level": runtimeState.get("level", {}).duplicate(true),
		"question": runtimeState.get("question", {}).duplicate(true),
		"gameplay": runtimeState.get("gameplay", {}).duplicate(true),
		"mistakeBook": BuildMistakeContext(learningState.get("mistakeEntries", [])),
		"learning": {
			"skillProgress": learningState.get("skillProgress", {}).duplicate(true),
			"weakSkills": learningState.get("weakSkills", []).duplicate(),
			"recommendations": recommendations.slice(
				0,
				mini(RECOMMENDATION_LIMIT, recommendations.size())
			),
			"recentHistory": GetRecentHistory(playerHistory),
			"historyRecordCount": playerHistory.size(),
			"hasMinimumEvidence": not learningState.get("skillProgress", {}).is_empty()
		},
		"telemetry": learningState.get("activeTelemetry", {}).duplicate(true),
		"adaptive": learningState.get("adaptive", {}).duplicate(true)
	}

# Keeps Course identity explicit so Tutor responses never mix saved sources.
func BuildCourseContext(courseState: Dictionary) -> Dictionary:
	return {
		"sourceId": courseState.get("sourceId", "core_curriculum"),
		"displayName": courseState.get("displayName", "Core Curriculum"),
		"levelCount": int(courseState.get("levelCount", 0)),
		"available": bool(courseState.get("available", false)),
		"isTeacherPreview": bool(courseState.get("isTeacherPreview", false))
	}

# Summarizes saved mistakes without changing their deterministic explanations.
func BuildMistakeContext(mistakeEntriesValue: Variant) -> Dictionary:
	var mistakeEntries: Array = mistakeEntriesValue if mistakeEntriesValue is Array else []
	return {
		"entryCount": mistakeEntries.size(),
		"hasEntries": not mistakeEntries.is_empty(),
		"entries": mistakeEntries.duplicate(true)
	}

# Returns newest completed Question records while preserving stored chronology.
func GetRecentHistory(playerHistory: Array) -> Array:
	var firstIndex := maxi(0, playerHistory.size() - RECENT_HISTORY_LIMIT)
	return playerHistory.slice(firstIndex, playerHistory.size()).duplicate(true)

#endregion
