## Builds finite Mistake Practice and Adaptive Practice session data.
##
## This service owns replay Question shaping, source metadata, and mixed-mode
## assignment. GameManager remains responsible for live gameplay and scenes.
extends RefCounted

#region ========== Functions ==========

# Creates a weighted finite session from saved Mistake Book entries.
func BuildMistakePracticeSession(
	mistakeEntries: Array,
	questionCount: int,
	defaultLevelTypeId: String,
	learningManager
) -> Dictionary:
	if mistakeEntries.is_empty():
		return {}

	var practiceCount := mini(questionCount, mistakeEntries.size())
	var selectedMistakes: Array[Dictionary] = learningManager.SelectWeightedQuestions(
		mistakeEntries,
		practiceCount
	)
	var practiceQuestions: Array = []
	var practiceSkills: Array = []

	for entryIndex in range(selectedMistakes.size()):
		var mistakeEntry: Dictionary = selectedMistakes[entryIndex]
		practiceQuestions.append({
			"id": "practice_%02d_%s" % [entryIndex, mistakeEntry.get("questionId", "")],
			"sourceQuestionId": mistakeEntry.get("questionId", ""),
			"expression": mistakeEntry.get("expression", ""),
			"levelTypeId": mistakeEntry.get("levelTypeId", defaultLevelTypeId),
			"sourceEntryKey": mistakeEntry.get("entryKey", ""),
			"sourceLevelId": mistakeEntry.get("levelId", ""),
			"sourceLevelTitle": mistakeEntry.get("levelTitle", ""),
			"skills": mistakeEntry.get("skills", []).duplicate()
		})
		AppendUniqueSkills(practiceSkills, mistakeEntry.get("skills", []))

	return {
		"initialLevelTypeId": practiceQuestions[0].get("levelTypeId", defaultLevelTypeId),
		"level": {
			"id": "mistake_practice",
			"title": "Mistake Practice",
			"skills": practiceSkills,
			"questions": practiceQuestions
		}
	}

# Creates a weighted mixed-mode session from the complete authored content.
func BuildAdaptivePracticeSession(
	levels: Array,
	questionCount: int,
	gameplayModeIds: Array[String],
	defaultLevelTypeId: String,
	learningManager
) -> Dictionary:
	var questionPool := BuildQuestionPool(levels)
	if questionPool.is_empty() or gameplayModeIds.is_empty():
		return {}

	var practiceCount := mini(questionCount, questionPool.size())
	var selectedQuestions: Array[Dictionary] = learningManager.SelectWeightedQuestions(
		questionPool,
		practiceCount
	)
	var practiceSkills: Array = []

	for questionIndex in range(selectedQuestions.size()):
		var questionData: Dictionary = selectedQuestions[questionIndex]
		questionData["id"] = "adaptive_%02d_%s" % [
			questionIndex,
			questionData.get("sourceQuestionId", "")
		]
		questionData["levelTypeId"] = gameplayModeIds.pick_random()
		AppendUniqueSkills(practiceSkills, questionData.get("skills", []))

	return {
		"initialLevelTypeId": selectedQuestions[0].get("levelTypeId", defaultLevelTypeId),
		"level": {
			"id": "adaptive_practice",
			"title": "Adaptive Practice",
			"skills": practiceSkills,
			"questions": selectedQuestions
		}
	}

# Flattens authored Levels while preserving stable source metadata.
func BuildQuestionPool(levels: Array) -> Array[Dictionary]:
	var questionPool: Array[Dictionary] = []
	for level in levels:
		for question in level.get("questions", []):
			questionPool.append({
				"questionId": question.get("id", ""),
				"sourceQuestionId": question.get("id", ""),
				"expression": question.get("expression", ""),
				"sourceLevelId": level.get("id", ""),
				"sourceLevelTitle": level.get("title", ""),
				"skills": level.get("skills", []).duplicate()
			})
	return questionPool

# Adds Skill IDs without duplicating session metadata.
func AppendUniqueSkills(targetSkills: Array, sourceSkills: Array) -> void:
	for skill in sourceSkills:
		if skill not in targetSkills:
			targetSkills.append(skill)

#endregion
