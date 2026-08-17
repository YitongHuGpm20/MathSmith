## Provides weak-Skill detection, recommendations, and weighted selection.
##
## All initial M5 thresholds and weights are centralized here for manual
## validation. Weighting changes probability only and never excludes content.
extends RefCounted

#region ========== Configuration ==========

const WEAK_SKILL_MASTERY_THRESHOLD: int = 80
const MINIMUM_SKILL_ATTEMPTS: int = 1
const BASE_QUESTION_WEIGHT: int = 1
const WEAK_SKILL_WEIGHT_BONUS: int = 2
const ENABLE_CONSOLE_OUTPUT: bool = true

#endregion

#region ========== Functions ==========

# Returns learned Skills below the configured Mastery threshold, weakest first.
func GetWeakSkills(skillProgress: Dictionary) -> Array[String]:
	var weakSkills: Array[String] = []

	for skillIdValue in skillProgress:
		var skillId := str(skillIdValue)
		var summary: Dictionary = skillProgress.get(skillId, {})
		if (
			int(summary.get("attemptCount", 0)) >= MINIMUM_SKILL_ATTEMPTS
			and int(summary.get("masteryScore", 0)) < WEAK_SKILL_MASTERY_THRESHOLD
		):
			weakSkills.append(skillId)

	weakSkills.sort_custom(func(firstSkill: String, secondSkill: String) -> bool:
		var firstSummary: Dictionary = skillProgress.get(firstSkill, {})
		var secondSummary: Dictionary = skillProgress.get(secondSkill, {})
		var firstScore: int = firstSummary.get("masteryScore", 0)
		var secondScore: int = secondSummary.get("masteryScore", 0)
		if firstScore == secondScore:
			return firstSkill < secondSkill
		return firstScore < secondScore
	)
	return weakSkills

# Builds Level recommendations from Skill overlap, preserving stable ordering.
func BuildWeakSkillRecommendations(levels: Array, skillProgress: Dictionary) -> Array[Dictionary]:
	var weakSkills := GetWeakSkills(skillProgress)
	var recommendations: Array[Dictionary] = []

	for level in levels:
		var matchedSkills: Array[String] = []
		for skillValue in level.get("skills", []):
			var skillId := str(skillValue)
			if skillId in weakSkills:
				matchedSkills.append(skillId)

		if matchedSkills.is_empty():
			continue

		recommendations.append({
			"levelId": level.get("id", ""),
			"levelTitle": level.get("title", ""),
			"weakSkills": matchedSkills,
			"recommendationScore": GetRecommendationScore(matchedSkills, skillProgress)
		})

	recommendations.sort_custom(func(first: Dictionary, second: Dictionary) -> bool:
		var firstScore: int = first.get("recommendationScore", 0)
		var secondScore: int = second.get("recommendationScore", 0)
		if firstScore == secondScore:
			return str(first.get("levelId", "")) < str(second.get("levelId", ""))
		return firstScore > secondScore
	)

	if ENABLE_CONSOLE_OUTPUT:
		print("[M5 Weak Skills] ", JSON.stringify(weakSkills))
		print("[M5 Recommendations] ", JSON.stringify(recommendations))

	return recommendations

# Selects one candidate using shared Skill weights and an optional excluded key.
func SelectWeightedQuestion(
	candidates: Array,
	weakSkills: Array[String],
	excludedQuestionKey: String = ""
) -> Dictionary:
	var eligibleCandidates: Array[Dictionary] = []
	var totalWeight := 0

	for candidateValue in candidates:
		if not candidateValue is Dictionary:
			continue
		var candidate: Dictionary = candidateValue
		if not excludedQuestionKey.is_empty() and GetQuestionKey(candidate) == excludedQuestionKey:
			continue

		var weight := GetQuestionWeight(candidate, weakSkills)
		eligibleCandidates.append({"question": candidate, "weight": weight})
		totalWeight += weight

	if eligibleCandidates.is_empty() and not excludedQuestionKey.is_empty():
		return SelectWeightedQuestion(candidates, weakSkills)
	if eligibleCandidates.is_empty() or totalWeight <= 0:
		return {}

	var selectedWeight := randi_range(1, totalWeight)
	for weightedCandidate in eligibleCandidates:
		selectedWeight -= int(weightedCandidate["weight"])
		if selectedWeight <= 0:
			var selectedQuestion: Dictionary = weightedCandidate["question"].duplicate(true)
			PrintWeightedSelection(selectedQuestion, int(weightedCandidate["weight"]), weakSkills)
			return selectedQuestion

	var fallbackQuestion: Dictionary = eligibleCandidates.back()["question"].duplicate(true)
	PrintWeightedSelection(fallbackQuestion, int(eligibleCandidates.back()["weight"]), weakSkills)
	return fallbackQuestion

# Returns a weighted sample without replacement for finite practice sessions.
func SelectWeightedQuestions(
	candidates: Array,
	weakSkills: Array[String],
	selectionCount: int
) -> Array[Dictionary]:
	var remainingCandidates: Array = candidates.duplicate(true)
	var selectedQuestions: Array[Dictionary] = []

	while not remainingCandidates.is_empty() and selectedQuestions.size() < selectionCount:
		var selectedQuestion := SelectWeightedQuestion(remainingCandidates, weakSkills)
		if selectedQuestion.is_empty():
			break
		selectedQuestions.append(selectedQuestion)

		for candidateIndex in range(remainingCandidates.size() - 1, -1, -1):
			if GetQuestionKey(remainingCandidates[candidateIndex]) == GetQuestionKey(selectedQuestion):
				remainingCandidates.remove_at(candidateIndex)
				break

	return selectedQuestions

# Calculates the non-zero selection weight for one Question.
func GetQuestionWeight(questionData: Dictionary, weakSkills: Array[String]) -> int:
	var weight := BASE_QUESTION_WEIGHT
	for skillValue in questionData.get("skills", []):
		if str(skillValue) in weakSkills:
			weight += WEAK_SKILL_WEIGHT_BONUS
	return weight

# Converts matched Skill weakness into a stable recommendation ranking value.
func GetRecommendationScore(matchedSkills: Array[String], skillProgress: Dictionary) -> int:
	var recommendationScore := 0
	for skillId in matchedSkills:
		var skillSummary: Dictionary = skillProgress.get(skillId, {})
		recommendationScore += 100 - int(skillSummary.get("masteryScore", 0))
	return recommendationScore

# Returns the stable identity shared by all replay Question shapes.
func GetQuestionKey(questionData: Dictionary) -> String:
	var levelId := str(questionData.get("levelId", questionData.get("sourceLevelId", "")))
	var questionId := str(questionData.get("questionId", questionData.get("id", "")))
	return "%s:%s" % [levelId, questionId]

# Prints one concise selection sample for manual distribution validation.
func PrintWeightedSelection(
	questionData: Dictionary,
	questionWeight: int,
	weakSkills: Array[String]
) -> void:
	if not ENABLE_CONSOLE_OUTPUT:
		return

	print("[M5 Weighted Selection] ", JSON.stringify({
		"questionKey": GetQuestionKey(questionData),
		"skills": questionData.get("skills", []),
		"weight": questionWeight,
		"weakSkills": weakSkills
	}))

#endregion
