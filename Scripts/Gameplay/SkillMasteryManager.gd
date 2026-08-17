## Aggregates persistent Question history into deterministic Skill performance.
##
## Each completed Question contributes equally to every declared Skill. Mastery
## combines average performance with gradually accumulated evidence.
extends RefCounted

#region ========== Configuration ==========

const SKILL_PROGRESS_SCHEMA_VERSION: int = 2
const MINIMUM_SCORE: int = 0
const MAXIMUM_SCORE: int = 100
const MASTERY_EVIDENCE_QUESTION_COUNT: int = 10
const ENABLE_CONSOLE_OUTPUT: bool = true

#endregion

#region ========== Functions ==========

# Rebuilds every Skill summary from saved history and persists the result.
func RebuildSkillProgress(playerHistory: Array) -> Dictionary:
	var skillProgress := AggregateHistory(playerHistory)
	SaveManager.SetSection("skillProgress", skillProgress)

	if ENABLE_CONSOLE_OUTPUT:
		print("[M5 Skill Progress] ", JSON.stringify(skillProgress, "  "))

	return skillProgress.duplicate(true)

# Returns isolated persisted Skill summaries for inspection and later UI work.
func GetSkillProgress() -> Dictionary:
	var savedProgress = SaveManager.GetSection("skillProgress")
	return savedProgress if savedProgress is Dictionary else {}

# Collects raw totals for each Skill before calculating derived values.
func AggregateHistory(playerHistory: Array) -> Dictionary:
	var skillProgress: Dictionary = {}

	for historyRecord in playerHistory:
		if not historyRecord is Dictionary:
			continue

		var outcome: Dictionary = historyRecord.get("outcome", {})
		var sharedMetrics: Dictionary = historyRecord.get("sharedMetrics", {})
		var questionScore := clampi(
			int(outcome.get("questionScore", MINIMUM_SCORE)),
			MINIMUM_SCORE,
			MAXIMUM_SCORE
		)

		# Apply the same completed performance once to every declared Skill.
		for skillValue in historyRecord.get("skills", []):
			var skillId := str(skillValue)
			if skillId.is_empty():
				continue

			var summary: Dictionary = skillProgress.get(skillId, CreateEmptySummary(skillId))
			summary["attemptCount"] += 1
			summary["completedCount"] += 1 if outcome.get("completed", false) else 0
			summary["totalScore"] += questionScore
			summary["totalIncorrectAttempts"] += int(
				sharedMetrics.get("incorrectAttempts", 0)
			)
			summary["totalHintsUsed"] += int(sharedMetrics.get("hintUses", 0))
			summary["totalSolveTimeMs"] += maxi(
				0,
				int(historyRecord.get("totalSolveTimeMs", 0))
			)
			summary["lastPlayedAtUnixMs"] = maxi(
				int(summary["lastPlayedAtUnixMs"]),
				int(historyRecord.get("startedAtUnixMs", 0))
			)
			skillProgress[skillId] = summary

	# Derive readable averages only after all records have contributed.
	for skillId in skillProgress:
		FinalizeSummary(skillProgress[skillId])

	return skillProgress

# Creates the stable persisted shape for a newly encountered Skill.
func CreateEmptySummary(skillId: String) -> Dictionary:
	return {
		"skillProgressSchemaVersion": SKILL_PROGRESS_SCHEMA_VERSION,
		"skillId": skillId,
		"attemptCount": 0,
		"completedCount": 0,
		"totalScore": 0,
		"averageScore": 0.0,
		"masteryScore": 0,
		"evidenceProgress": 0.0,
		"totalIncorrectAttempts": 0,
		"totalHintsUsed": 0,
		"totalSolveTimeMs": 0,
		"averageSolveTimeMs": 0,
		"lastPlayedAtUnixMs": 0
	}

# Calculates performance averages and evidence-adjusted Skill Mastery.
func FinalizeSummary(summary: Dictionary) -> void:
	var attemptCount: int = summary.get("attemptCount", 0)
	if attemptCount <= 0:
		return

	var averageScore := float(summary.get("totalScore", 0)) / float(attemptCount)
	var evidenceProgress := minf(
		1.0,
		float(attemptCount) / float(MASTERY_EVIDENCE_QUESTION_COUNT)
	)
	summary["averageScore"] = snappedf(averageScore, 0.01)
	summary["evidenceProgress"] = snappedf(evidenceProgress, 0.01)
	summary["masteryScore"] = clampi(
		roundi(averageScore * evidenceProgress),
		MINIMUM_SCORE,
		MAXIMUM_SCORE
	)
	summary["averageSolveTimeMs"] = roundi(
		float(summary.get("totalSolveTimeMs", 0)) / float(attemptCount)
	)

#endregion
