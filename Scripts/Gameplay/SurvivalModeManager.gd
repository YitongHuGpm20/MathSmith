## Manages MathSmith's three-life Survival replay session.
##
## This service owns the random full-content Question pool, adjacent-repeat
## prevention, remaining lives, solved count, and persistent best result.
extends RefCounted

#region ========== Constants ==========

const STARTING_LIVES: int = 3

#endregion

#region ========== Variables ==========

var questionPool: Array[Dictionary] = []
var lastQuestionKey: String = ""
var remainingLives: int = STARTING_LIVES
var solvedCount: int = 0
var sessionEnded: bool = false

#endregion

#region ========== Functions ==========

# Creates a fresh Survival session from every validated Level Question.
func Initialize(levels: Array) -> bool:
	BuildQuestionPool(levels)

	if questionPool.is_empty():
		return false

	lastQuestionKey = ""
	remainingLives = STARTING_LIVES
	solvedCount = 0
	sessionEnded = false
	return true

# Removes one life and returns true when the session should end.
func LoseLife() -> bool:
	if sessionEnded:
		return true

	remainingLives = maxi(0, remainingLives - 1)
	return remainingLives <= 0

# Records one completed Question exactly when GameManager commits it.
func RecordSolvedQuestion() -> void:
	if not sessionEnded:
		solvedCount += 1

# Returns the lives remaining in the current session.
func GetRemainingLives() -> int:
	return remainingLives

# Returns the number of Questions completed in the current session.
func GetSolvedCount() -> int:
	return solvedCount

# Returns one random Question and random interaction without adjacent repetition.
func GetNextQuestion(levelTypeIds: Array[String]) -> Dictionary:
	var candidates: Array[Dictionary] = []

	for questionData in questionPool:
		if GetQuestionKey(questionData) != lastQuestionKey:
			candidates.append(questionData)

	if candidates.is_empty():
		candidates.assign(questionPool)

	var selectedQuestion: Dictionary = candidates.pick_random()
	lastQuestionKey = GetQuestionKey(selectedQuestion)
	var selectedLevelTypeId: String = levelTypeIds.pick_random()
	return {
		"id": selectedQuestion.get("questionId", ""),
		"expression": selectedQuestion.get("expression", ""),
		"levelTypeId": selectedLevelTypeId,
		"sourceLevelId": selectedQuestion.get("levelId", ""),
		"skills": selectedQuestion.get("skills", []).duplicate()
	}

# Saves the best solved count and returns the complete Survival summary.
func Finish(incorrectAttemptCount: int) -> Dictionary:
	if sessionEnded:
		return {}

	sessionEnded = true
	var survivalSaveData: Dictionary = SaveManager.GetCourseSection("survivalMode")
	var previousBest: int = survivalSaveData.get("bestSolvedCount", 0)
	var isNewBest := solvedCount > previousBest
	var bestSolvedCount := maxi(previousBest, solvedCount)
	survivalSaveData["bestSolvedCount"] = bestSolvedCount
	SaveManager.SetCourseSection("survivalMode", survivalSaveData)
	return {
		"isSurvivalSession": true,
		"solvedCount": solvedCount,
		"incorrectAttempts": incorrectAttemptCount,
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
