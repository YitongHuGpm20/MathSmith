## Manages MathSmith's timed Zen replay session.
##
## This service owns the three-minute clock, flattened random Question pool,
## adjacent-repeat prevention, solved count, accuracy, and persistent best.
extends RefCounted

#region ========== Constants ==========

const DURATION_SECONDS: float = 180.0

#endregion

#region ========== Variables ==========

var questionPool: Array[Dictionary] = []
var lastQuestionKey: String = ""
var timeRemaining: float = 0.0
var solvedCount: int = 0
var sessionEnded: bool = false
var weakSkills: Array[String] = []
var adaptiveLearningManager := preload("res://Scripts/Learning/AdaptiveLearningManager.gd").new()

#endregion

#region ========== Functions ==========

# Creates a fresh timed session from every validated Level Question.
func Initialize(levels: Array, skillProgress: Dictionary = {}) -> bool:
	BuildQuestionPool(levels)

	if questionPool.is_empty():
		return false

	lastQuestionKey = ""
	timeRemaining = DURATION_SECONDS
	solvedCount = 0
	sessionEnded = false
	weakSkills = adaptiveLearningManager.GetWeakSkills(skillProgress)
	return true

# Decrements the clock and returns true on its first expiration frame.
func AdvanceTime(delta: float) -> bool:
	if sessionEnded:
		return false

	timeRemaining = maxf(0.0, timeRemaining - delta)
	return timeRemaining <= 0.0

# Returns the rounded-up time displayed during an active session.
func GetRemainingSeconds() -> int:
	return ceili(timeRemaining)

# Returns the number of Questions completed during the current session.
func GetSolvedCount() -> int:
	return solvedCount

# Records one completed Question exactly when GameManager commits it.
func RecordSolvedQuestion() -> void:
	solvedCount += 1

# Returns one random Question and random interaction without adjacent repetition.
func GetNextQuestion(levelTypeIds: Array[String]) -> Dictionary:
	var selectedQuestion := adaptiveLearningManager.SelectWeightedQuestion(
		questionPool,
		weakSkills,
		lastQuestionKey
	)
	lastQuestionKey = GetQuestionKey(selectedQuestion)
	var selectedLevelTypeId: String = levelTypeIds.pick_random()
	return {
		"id": selectedQuestion.get("questionId", ""),
		"expression": selectedQuestion.get("expression", ""),
		"levelTypeId": selectedLevelTypeId,
		"sourceLevelId": selectedQuestion.get("levelId", ""),
		"skills": selectedQuestion.get("skills", []).duplicate()
	}

# Saves the best solved count and returns the complete Zen summary.
func Finish(incorrectAttemptCount: int) -> Dictionary:
	if sessionEnded:
		return {}

	sessionEnded = true
	var zenSaveData: Dictionary = SaveManager.GetCourseSection("zenMode")
	var previousBest: int = zenSaveData.get("bestSolvedCount", 0)
	var isNewBest := solvedCount > previousBest
	var bestSolvedCount := maxi(previousBest, solvedCount)
	zenSaveData["bestSolvedCount"] = bestSolvedCount
	SaveManager.SetCourseSection("zenMode", zenSaveData)
	var totalAttempts := solvedCount + incorrectAttemptCount
	var accuracy := (
		roundi(float(solvedCount) / float(totalAttempts) * 100.0)
		if totalAttempts > 0
		else 0
	)
	return {
		"isZenSession": true,
		"solvedCount": solvedCount,
		"accuracy": accuracy,
		"bestSolvedCount": bestSolvedCount,
		"isNewBest": isNewBest
	}

# Flattens validated content while retaining source identity and Skills.
func BuildQuestionPool(levels: Array) -> void:
	questionPool.clear()

	for level in levels:
		for question in level.get("questions", []):
			questionPool.append({
				"questionId": question.get("id", ""),
				"expression": question.get("expression", ""),
				"levelId": level.get("id", ""),
				"skills": level.get("skills", []).duplicate()
			})

# Returns the source identity used to prevent immediate repetition.
func GetQuestionKey(questionData: Dictionary) -> String:
	return "%s:%s" % [
		questionData.get("levelId", ""),
		questionData.get("questionId", "")
	]

#endregion
