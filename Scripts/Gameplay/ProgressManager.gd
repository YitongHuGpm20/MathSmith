## Manages mode-specific Level progress and persistent best results.
##
## This data service owns Local Save migration, interrupted-session cleanup,
## and completed Level result updates. GameManager supplies session results.
extends RefCounted

#region ========== Variables ==========

var levelProgress: Dictionary = {}
var defaultLevelTypeId: String = "step_ordering"

#endregion

#region ========== Functions ==========

# Loads persistent progress and remembers the legacy mode migration target.
func Initialize(initialLevelTypeId: String) -> void:
	defaultLevelTypeId = initialLevelTypeId
	LoadLevelProgress()

# Returns isolated progress for one Level within one gameplay mode.
func GetLevelProgress(levelTypeId: String, levelId: String) -> Dictionary:
	var modeProgress: Dictionary = levelProgress.get(levelTypeId, {})
	return modeProgress.get(
		levelId,
		{
			"completedQuestions": 0,
			"completed": false,
			"needsPractice": false,
			"bestScore": -1,
			"bestStars": 0
		}
	).duplicate(true)

# Saves one fully completed Level session and returns best-result metadata.
func RecordLevelResult(
	levelTypeId: String,
	levelId: String,
	questionCount: int,
	levelScore: int,
	starCount: int
) -> Dictionary:
	if levelId.is_empty():
		return {}

	var progressData := GetLevelProgress(levelTypeId, levelId)
	var wasCompleted: bool = progressData.get("completed", false)
	var previousBestScore: int = progressData.get("bestScore", -1)
	var isNewBest := levelScore > previousBestScore
	progressData["completedQuestions"] = questionCount
	progressData["completed"] = wasCompleted or starCount >= 1
	progressData["needsPractice"] = not progressData["completed"] and starCount == 0
	progressData["bestScore"] = maxi(previousBestScore, levelScore)
	progressData["bestStars"] = maxi(progressData.get("bestStars", 0), starCount)
	SetLevelProgress(levelTypeId, levelId, progressData)
	SaveLevelProgress()
	return {
		"bestScore": progressData["bestScore"],
		"isNewBest": isNewBest
	}

# Reloads cleared or externally changed progress from Local Save storage.
func ReloadPersistentProgress() -> void:
	LoadLevelProgress()

# Loads mode-specific progress and migrates the previous shared Level format.
func LoadLevelProgress() -> void:
	var loadedProgress = SaveManager.GetSection("levelProgress")
	levelProgress = loadedProgress if loadedProgress is Dictionary else {}
	var legacyProgress: Dictionary = {}

	# Old saves stored Level IDs directly, which represented Step Ordering play.
	for progressKey in levelProgress.keys():
		if str(progressKey).begins_with("level_"):
			legacyProgress[progressKey] = levelProgress[progressKey]

	if not legacyProgress.is_empty():
		levelProgress = {defaultLevelTypeId: legacyProgress}

	var progressWasChanged := ClearIncompleteSavedProgress()

	if not legacyProgress.is_empty() or progressWasChanged:
		SaveLevelProgress()

# Removes obsolete per-Question progress so interrupted Levels always restart.
func ClearIncompleteSavedProgress() -> bool:
	var progressWasChanged := false

	for levelTypeId in levelProgress:
		var modeProgress: Dictionary = levelProgress.get(levelTypeId, {})

		for levelId in modeProgress:
			var progressData: Dictionary = modeProgress.get(levelId, {})
			var hasFinalResult: bool = (
				progressData.get("completed", false)
				or progressData.get("needsPractice", false)
			)

			if not hasFinalResult and progressData.get("completedQuestions", 0) > 0:
				progressData["completedQuestions"] = 0
				modeProgress[levelId] = progressData
				progressWasChanged = true

		levelProgress[levelTypeId] = modeProgress

	return progressWasChanged

# Stores one Level result under its exact gameplay mode.
func SetLevelProgress(levelTypeId: String, levelId: String, progressData: Dictionary) -> void:
	var modeProgress: Dictionary = levelProgress.get(levelTypeId, {})
	modeProgress[levelId] = progressData
	levelProgress[levelTypeId] = modeProgress

# Writes the complete progress collection through the shared SaveManager.
func SaveLevelProgress() -> void:
	SaveManager.SetSection("levelProgress", levelProgress)

#endregion
