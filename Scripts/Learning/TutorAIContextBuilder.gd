## Builds a data-minimized, course-scoped context for optional AI providers.
##
## The builder whitelists M7 values and never reads save data or calculates truth.
extends RefCounted

#region ========== Constants ==========

const AI_CONTEXT_SCHEMA_VERSION: int = 1
const RELEVANT_HISTORY_LIMIT: int = 3
const RELEVANT_MISTAKE_LIMIT: int = 3

#endregion

#region ========== Functions ==========

# Converts one deterministic M7 snapshot into the M8 provider contract.
func BuildContext(
	tutorContext: Dictionary,
	requestIntent: String,
	availableActions: Array,
	languageCode: String
) -> Dictionary:
	var course: Dictionary = tutorContext.get("course", {})
	var session: Dictionary = tutorContext.get("session", {})
	var level: Dictionary = tutorContext.get("level", {})
	var question: Dictionary = tutorContext.get("question", {})
	var gameplay: Dictionary = tutorContext.get("gameplay", {})
	var learning: Dictionary = tutorContext.get("learning", {})
	var courseSourceId: String = course.get("sourceId", "")
	var skillTags := NormalizeStringArray(question.get("skills", level.get("skills", [])))
	var questionCompleted: bool = question.get("completed", false)
	var isTeacherPreview: bool = session.get("teacherPreview", false)
	var canRevealValidatedProcess: bool = questionCompleted or isTeacherPreview

	return {
		"aiContextSchemaVersion": AI_CONTEXT_SCHEMA_VERSION,
		"requestIntent": requestIntent,
		"language": languageCode,
		"courseSource": {
			"sourceId": courseSourceId,
			"displayName": course.get("displayName", ""),
			"available": course.get("available", false),
			"teacherPreview": isTeacherPreview
		},
		"screen": {
			"id": tutorContext.get("screen", {}).get("id", "")
		},
		"session": {
			"type": session.get("type", "none"),
			"teacherPreview": isTeacherPreview,
			"canWritePlayerData": session.get("canWritePlayerData", false),
			"summary": BuildSafeSummary(session.get("summary", {}))
		},
		"level": BuildLevelContext(level),
		"mode": {
			"id": gameplay.get("modeId", level.get("typeId", ""))
		},
		"question": {
			"id": question.get("id", ""),
			"expression": question.get("expression", ""),
			"skillTags": skillTags,
			"completed": questionCompleted,
			"ruleCategory": question.get("ruleCategory", ""),
			"ruleExplanation": question.get("ruleExplanation", ""),
			"canRevealValidatedProcess": canRevealValidatedProcess,
			"validatedProcess": (
				question.get("correctProcess", []).duplicate()
				if canRevealValidatedProcess
				else []
			)
		},
		"performance": BuildPerformanceContext(gameplay),
		"mastery": BuildRelevantMastery(learning.get("skillProgress", {}), skillTags),
		"weakSkills": NormalizeStringArray(learning.get("weakSkills", [])),
		"relevantHistory": BuildRelevantHistory(
			learning.get("recentHistory", []), courseSourceId, skillTags
		),
		"relevantMistakes": BuildRelevantMistakes(
			tutorContext.get("mistakeBook", {}).get("entries", []),
			courseSourceId,
			skillTags
		),
		"recommendation": BuildRelevantRecommendation(
			learning.get("recommendations", []), skillTags
		),
		"behaviorEvidence": BuildBehaviorEvidence(tutorContext.get("telemetry", {})),
		"availableActions": BuildSafeActions(availableActions)
	}

# Keeps Level context concise and excludes complete authored content.
func BuildLevelContext(level: Dictionary) -> Dictionary:
	return {
		"id": level.get("id", ""),
		"title": level.get("title", ""),
		"typeId": level.get("typeId", ""),
		"skills": NormalizeStringArray(level.get("skills", [])),
		"questionIndex": level.get("questionIndex", 0),
		"questionCount": level.get("questionCount", 0)
	}

# Exposes only recorded score, attempts, Hints, and feedback state.
func BuildPerformanceContext(gameplay: Dictionary) -> Dictionary:
	return {
		"questionScore": gameplay.get("questionScore", 0),
		"startingQuestionScore": gameplay.get("startingQuestionScore", 0),
		"incorrectAttempts": gameplay.get("questionIncorrectAttempts", 0),
		"hintsUsed": gameplay.get("questionHintsUsed", 0),
		"remainingHints": gameplay.get("remainingHints", 0),
		"maximumProgressiveFeedbackReached": (
			int(gameplay.get("progressiveFeedbackLevel", 0)) >= 3
		)
	}

# Includes completed-session results without exposing unrelated save sections.
func BuildSafeSummary(summaryValue: Variant) -> Dictionary:
	var summary: Dictionary = summaryValue if summaryValue is Dictionary else {}
	if summary.is_empty():
		return {}
	return {
		"score": summary.get("score", 0),
		"stars": summary.get("stars", 0),
		"incorrectAttempts": summary.get("incorrectAttempts", 0),
		"hintsUsed": summary.get("hintsUsed", 0),
		"isPracticeSession": summary.get("isPracticeSession", false),
		"isTeacherPreview": summary.get("isTeacherPreview", false)
	}

# Selects Mastery summaries only for Skills relevant to the current Question.
func BuildRelevantMastery(skillProgressValue: Variant, skillTags: Array[String]) -> Dictionary:
	var skillProgress: Dictionary = (
		skillProgressValue if skillProgressValue is Dictionary else {}
	)
	var relevantMastery: Dictionary = {}
	for skillId in skillTags:
		if not skillProgress.has(skillId):
			continue
		var summary: Dictionary = skillProgress.get(skillId, {})
		relevantMastery[skillId] = {
			"masteryScore": summary.get("masteryScore", 0),
			"attemptCount": summary.get("attemptCount", 0),
			"hasEnoughEvidence": summary.get("hasEnoughEvidence", false)
		}
	return relevantMastery

# Filters recent History to the active Course and relevant Skills when present.
func BuildRelevantHistory(
	historyValue: Variant,
	courseSourceId: String,
	skillTags: Array[String]
) -> Array[Dictionary]:
	var history: Array = historyValue if historyValue is Array else []
	var relevantRecords: Array[Dictionary] = []
	for recordValue in history:
		if not recordValue is Dictionary:
			continue
		var record: Dictionary = recordValue
		if not IsRecordInCourse(record, courseSourceId):
			continue
		var recordSkills := NormalizeStringArray(record.get("skills", []))
		if not skillTags.is_empty() and not HasSharedSkill(recordSkills, skillTags):
			continue
		var outcome: Dictionary = record.get("outcome", {})
		relevantRecords.append({
			"questionId": record.get("questionId", ""),
			"levelId": record.get("levelId", ""),
			"skills": recordSkills,
			"score": outcome.get("questionScore", record.get("questionScore", 0)),
			"incorrectAttempts": outcome.get("incorrectAttempts", 0),
			"hintsUsed": outcome.get("hintsUsed", 0),
			"behaviorPattern": record.get("behaviorPattern", {})
		})
	return relevantRecords.slice(
		maxi(0, relevantRecords.size() - RELEVANT_HISTORY_LIMIT),
		relevantRecords.size()
	)

# Filters Mistake Book evidence without exposing entries from another Course.
func BuildRelevantMistakes(
	mistakesValue: Variant,
	courseSourceId: String,
	skillTags: Array[String]
) -> Array[Dictionary]:
	var mistakes: Array = mistakesValue if mistakesValue is Array else []
	var relevantMistakes: Array[Dictionary] = []
	for entryValue in mistakes:
		if not entryValue is Dictionary:
			continue
		var entry: Dictionary = entryValue
		if not IsRecordInCourse(entry, courseSourceId):
			continue
		var entrySkills := NormalizeStringArray(
			entry.get("skills", entry.get("sourceSkills", []))
		)
		if not skillTags.is_empty() and not HasSharedSkill(entrySkills, skillTags):
			continue
		relevantMistakes.append({
			"questionId": entry.get("questionId", entry.get("id", "")),
			"levelId": entry.get("levelId", entry.get("sourceLevelId", "")),
			"expression": entry.get("expression", ""),
			"skills": entrySkills,
			"category": entry.get("category", entry.get("mistakeCategory", "")),
			"explanation": entry.get("explanation", entry.get("mistakeExplanation", ""))
		})
		if relevantMistakes.size() >= RELEVANT_MISTAKE_LIMIT:
			break
	return relevantMistakes

# Selects one existing recommendation supported by the current Skill context.
func BuildRelevantRecommendation(
	recommendationsValue: Variant,
	skillTags: Array[String]
) -> Dictionary:
	var recommendations: Array = (
		recommendationsValue if recommendationsValue is Array else []
	)
	for recommendationValue in recommendations:
		if not recommendationValue is Dictionary:
			continue
		var recommendation: Dictionary = recommendationValue
		var matchedSkills := NormalizeStringArray(recommendation.get("matchedSkills", []))
		if skillTags.is_empty() or HasSharedSkill(matchedSkills, skillTags):
			return {
				"levelId": recommendation.get("levelId", ""),
				"levelTitle": recommendation.get("levelTitle", ""),
				"matchedSkills": matchedSkills,
				"recommendationScore": recommendation.get("recommendationScore", 0)
			}
	return {}

# Reduces telemetry to evidence already classified by deterministic M5 systems.
func BuildBehaviorEvidence(telemetryValue: Variant) -> Dictionary:
	var telemetry: Dictionary = telemetryValue if telemetryValue is Dictionary else {}
	if telemetry.is_empty():
		return {}
	return {
		"firstActionTimeMs": telemetry.get("firstActionTimeMs", -1),
		"totalSolveTimeMs": telemetry.get("totalSolveTimeMs", -1),
		"sharedMetrics": telemetry.get("sharedMetrics", {}).duplicate(true),
		"behaviorPattern": telemetry.get("behaviorPattern", {}).duplicate(true)
	}

# Whitelists M7 actions; future AI output must still pass Navigation validation.
func BuildSafeActions(actionsValue: Variant) -> Array[Dictionary]:
	var actions: Array = actionsValue if actionsValue is Array else []
	var safeActions: Array[Dictionary] = []
	for actionValue in actions:
		if not actionValue is Dictionary:
			continue
		var action: Dictionary = actionValue
		var actionId: String = action.get("actionId", "")
		if actionId.is_empty():
			continue
		safeActions.append({
			"actionId": actionId,
			"label": action.get("label", "")
		})
	return safeActions

# Treats missing source IDs as already scoped by the M7 provider.
func IsRecordInCourse(record: Dictionary, courseSourceId: String) -> bool:
	var recordSourceId: String = record.get("courseSourceId", "")
	return recordSourceId.is_empty() or recordSourceId == courseSourceId

# Returns whether two normalized Skill collections overlap.
func HasSharedSkill(firstSkills: Array[String], secondSkills: Array[String]) -> bool:
	for skillId in firstSkills:
		if skillId in secondSkills:
			return true
	return false

# Converts untyped saved arrays into a safe String collection.
func NormalizeStringArray(values: Variant) -> Array[String]:
	var normalizedValues: Array[String] = []
	if not values is Array:
		return normalizedValues
	for value in values:
		normalizedValues.append(String(value))
	return normalizedValues

#endregion
