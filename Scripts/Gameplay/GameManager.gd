## Coordinates MathSmith's active Level and all three gameplay interactions.
##
## This script owns live Question state, gameplay validation, scoring, and
## navigation. Focused services own content loading, choice generation,
## persistent Level progress, and Mistake Book storage.
extends Node

#region ========== Constants ==========

const HOME_SCENE_PATH: String = "res://Scenes/HomeScene.tscn"
const LOBBY_SCENE_PATH: String = "res://Scenes/LobbyScene.tscn"
const GAME_SCENE_PATH: String = "res://Scenes/GameScene.tscn"
const MISTAKE_BOOK_SCENE_PATH: String = "res://Scenes/MistakeBookScene.tscn"
const DEFAULT_LEVEL_TYPE_ID: String = "step_ordering"
const MULTIPLE_CHOICE_LEVEL_TYPE_ID: String = "multiple_choice_ordering"
const FILL_PROCESS_LEVEL_TYPE_ID: String = "fill_in_process"
const MAX_QUESTION_SCORE: int = 100
const INCORRECT_ATTEMPT_PENALTY: int = 15
const HINT_SCORE_PENALTY: int = 15
const EARLY_LEVEL_HINT_BUDGET: int = 3
const MIDDLE_LEVEL_HINT_BUDGET: int = 4
const ADVANCED_LEVEL_HINT_BUDGET: int = 5

#endregion

#region ========== References ==========

var gameUI: Node = null
var levelLoader := preload("res://Scripts/Gameplay/LevelLoader.gd").new()
var stepGenerator := preload("res://Scripts/Math/StepGenerator.gd").new()
var choiceGenerator := preload("res://Scripts/Math/ChoiceGenerator.gd").new()
var progressManager := preload("res://Scripts/Gameplay/ProgressManager.gd").new()
var mistakeBookManager := preload("res://Scripts/Gameplay/MistakeBookManager.gd").new()

#endregion

#region ========== Variables ==========

var levels: Array = []
var levelTypes: Dictionary = {}
var selectedLevelTypeId: String = DEFAULT_LEVEL_TYPE_ID
var currentLevel: Dictionary = {}
var currentQuestionIndex: int = 0
var correctSteps: Array[String] = []
var questionCompleted: bool = false
var revealedHintCount: int = 0
var consecutiveIncorrectAttempts: int = 0
var currentExpression: String = ""
var currentChoiceStage: int = 0
var currentChoiceOptions: Array[String] = []
var unavailableChoiceOptions: Array[String] = []
var fillBlankAnswers: Dictionary = {}
var revealedFillBlankIds: Array[String] = []
var currentQuestionScore: int = MAX_QUESTION_SCORE
var currentLevelScore: int = 0
var incorrectAttempts: int = 0
var hintsUsed: int = 0
var currentLevelIncorrectAttempts: int = 0
var currentLevelHintsUsed: int = 0
var questionScoreCommitted: bool = false
var remainingHints: int = 0
var levelHintBudget: int = 0

#endregion

#region ========== Godot Functions ==========

# Loads shared content before any gameplay or menu scene requests it.
func _ready() -> void:
	var contentData: Dictionary = levelLoader.LoadContentData()

	if contentData.is_empty():
		return

	# Publish validated content and preserve the initial default Level.
	levelTypes = contentData["level_types"]
	levels = contentData["levels"]
	currentLevel = levels[0]
	progressManager.Initialize(DEFAULT_LEVEL_TYPE_ID)

#endregion

#region ========== Scene Navigation ==========

# Opens the Home Scene while preserving current-session progress.
func OpenHome() -> void:
	ChangeScene(HOME_SCENE_PATH)

# Opens the Lobby Scene while preserving current-session progress.
func OpenLobby() -> void:
	ChangeScene(LOBBY_SCENE_PATH)

# Opens the saved deterministic Question review collection.
func OpenMistakeBook() -> void:
	ChangeScene(MISTAKE_BOOK_SCENE_PATH)

# Opens the Game Scene for the currently selected Level.
func OpenGame() -> void:
	if currentLevel.is_empty():
		push_error("Cannot open Game Scene without a selected Level.")
		return

	ChangeScene(GAME_SCENE_PATH)

# Exits the running application from a shared menu action.
func QuitGame() -> void:
	get_tree().quit()

# Changes scenes through one guarded navigation entry point.
func ChangeScene(scenePath: String) -> void:
	var changeError := get_tree().change_scene_to_file(scenePath)

	if changeError != OK:
		push_error("Failed to open scene '%s' with error %d." % [scenePath, changeError])

#endregion

#region ========== Game UI Registration ==========

# Registers the active Game Scene UI and starts its current Level.
func RegisterGameUI(newGameUI: Node) -> void:
	if is_instance_valid(gameUI):
		DisconnectGameUISignals()

	gameUI = newGameUI
	gameUI.checkRequested.connect(CheckAnswer)
	gameUI.hintRequested.connect(UseHint)
	gameUI.retryRequested.connect(RestartLevel)
	gameUI.nextLevelRequested.connect(OpenNextLevel)
	gameUI.lobbyRequested.connect(BackToLobby)
	gameUI.orderChanged.connect(UpdateHintAvailability)
	gameUI.choiceSelected.connect(SelectMultipleChoice)
	gameUI.tutorialDismissed.connect(RecordTutorialViewed)
	gameUI.tutorialRequested.connect(ShowCurrentTutorial)
	gameUI.reviewMistakesRequested.connect(OpenMistakeBook)

	# Surface content errors only after a visual UI is available.
	if levels.is_empty():
		gameUI.ShowDataError("No valid level data could be loaded.")
		return

	if currentLevel.is_empty():
		currentLevel = levels[0]

	ResetLevelScoring()
	LoadQuestion(0)
	ShowTutorialIfNeeded()

# Releases a departing Game Scene UI without changing persistent gameplay data.
func UnregisterGameUI(departingGameUI: Node) -> void:
	if gameUI != departingGameUI:
		return

	DisconnectGameUISignals()
	gameUI = null

# Disconnects all request signals owned by the active Game Scene UI.
func DisconnectGameUISignals() -> void:
	if not is_instance_valid(gameUI):
		return

	if gameUI.checkRequested.is_connected(CheckAnswer):
		gameUI.checkRequested.disconnect(CheckAnswer)

	if gameUI.hintRequested.is_connected(UseHint):
		gameUI.hintRequested.disconnect(UseHint)

	if gameUI.retryRequested.is_connected(RestartLevel):
		gameUI.retryRequested.disconnect(RestartLevel)

	if gameUI.nextLevelRequested.is_connected(OpenNextLevel):
		gameUI.nextLevelRequested.disconnect(OpenNextLevel)

	if gameUI.lobbyRequested.is_connected(BackToLobby):
		gameUI.lobbyRequested.disconnect(BackToLobby)

	if gameUI.orderChanged.is_connected(UpdateHintAvailability):
		gameUI.orderChanged.disconnect(UpdateHintAvailability)

	if gameUI.choiceSelected.is_connected(SelectMultipleChoice):
		gameUI.choiceSelected.disconnect(SelectMultipleChoice)

	if gameUI.tutorialDismissed.is_connected(RecordTutorialViewed):
		gameUI.tutorialDismissed.disconnect(RecordTutorialViewed)

	if gameUI.tutorialRequested.is_connected(ShowCurrentTutorial):
		gameUI.tutorialRequested.disconnect(ShowCurrentTutorial)

	if gameUI.reviewMistakesRequested.is_connected(OpenMistakeBook):
		gameUI.reviewMistakesRequested.disconnect(OpenMistakeBook)

#endregion

#region ========== Content and Level Selection ==========

# Returns all Level Types that describe available gameplay interactions.
func GetLevelTypes() -> Dictionary:
	return levelTypes

# Returns one Level Type or an empty Dictionary when the ID is unknown.
func GetLevelTypeById(levelTypeId: String) -> Dictionary:
	return levelTypes.get(levelTypeId, {})

# Returns the rule owned by the currently selected Level Type.
func GetSelectedLevelTypeRule() -> String:
	var selectedLevelType: Dictionary = GetLevelTypeById(selectedLevelTypeId)
	return selectedLevelType.get("rule", "")

# Selects the interaction mode while preserving the shared mathematical content.
func SelectLevelType(levelTypeId: String) -> bool:
	if not levelTypes.has(levelTypeId):
		push_error("Cannot select unknown Level Type ID: " + levelTypeId)
		return false

	selectedLevelTypeId = levelTypeId
	return true

# Returns all validated levels for future Lobby card generation.
func GetLevels() -> Array:
	return levels

# Returns the level matching an ID or an empty Dictionary when none exists.
func GetLevelById(levelId: String) -> Dictionary:
	for level in levels:
		if level["id"] == levelId:
			return level

	return {}

# Selects mathematical Level content without changing the active Level Type.
func SelectLevel(levelId: String) -> bool:
	var selectedLevel := GetLevelById(levelId)

	if selectedLevel.is_empty():
		push_error("Cannot select unknown Level ID: " + levelId)
		return false

	# Reset transient gameplay state for the newly selected Level.
	currentLevel = selectedLevel
	currentQuestionIndex = 0
	correctSteps.clear()
	questionCompleted = false
	revealedHintCount = 0
	consecutiveIncorrectAttempts = 0
	currentExpression = ""
	currentChoiceStage = 0
	currentChoiceOptions.clear()
	unavailableChoiceOptions.clear()
	fillBlankAnswers.clear()
	revealedFillBlankIds.clear()
	ResetLevelScoring()
	return true

# Returns the selected Level ID or an empty String before content is available.
func GetSelectedLevelId() -> String:
	return currentLevel.get("id", "")

#endregion

#region ========== Persistent Progress ==========

# Returns lightweight progress for one Level during the current run.
func GetLevelProgress(levelId: String) -> Dictionary:
	return progressManager.GetLevelProgress(selectedLevelTypeId, levelId)

# Records the completed session as Level Complete or Needs Practice.
func RecordLevelResult(starCount: int) -> Dictionary:
	var levelId: String = GetSelectedLevelId()
	return progressManager.RecordLevelResult(
		selectedLevelTypeId,
		levelId,
		currentLevel.get("questions", []).size(),
		currentLevelScore,
		starCount
	)

# Reloads cleared or externally changed progress from Local Save storage.
func ReloadPersistentProgress() -> void:
	progressManager.ReloadPersistentProgress()

#endregion

#region ========== Tutorials ==========

# Shows interaction guidance only for an enabled and unviewed Level Type.
func ShowTutorialIfNeeded() -> void:
	var tutorialState: Dictionary = SaveManager.GetSection("tutorialState")

	if tutorialState.get(selectedLevelTypeId, false):
		return

	ShowCurrentTutorial()

# Opens the active Level Type tutorial when requested from the Game UI.
func ShowCurrentTutorial() -> void:
	var tutorialData := GetTutorialData(selectedLevelTypeId)

	if tutorialData.is_empty():
		return

	gameUI.ShowTutorial(tutorialData["title"], tutorialData["instructions"])

# Returns deterministic interaction instructions without exposing any solution.
func GetTutorialData(levelTypeId: String) -> Dictionary:
	match levelTypeId:
		DEFAULT_LEVEL_TYPE_ID:
			return {
				"title": "Step Ordering",
				"instructions": "TUTORIAL_STEP_ORDERING"
			}
		MULTIPLE_CHOICE_LEVEL_TYPE_ID:
			return {
				"title": "Multiple-Choice Ordering",
				"instructions": "TUTORIAL_MULTIPLE_CHOICE"
			}
		FILL_PROCESS_LEVEL_TYPE_ID:
			return {
				"title": "Fill in the Process",
				"instructions": "TUTORIAL_FILL_PROCESS"
			}

	return {}

# Persists that the current Level Type tutorial has been dismissed once.
func RecordTutorialViewed() -> void:
	var tutorialState: Dictionary = SaveManager.GetSection("tutorialState")
	tutorialState[selectedLevelTypeId] = true
	SaveManager.SetSection("tutorialState", tutorialState)

#endregion

#region ========== Question Setup ==========

# Loads the requested question and prepares its ordered and shuffled steps.
func LoadQuestion(questionIndex: int) -> void:
	var questions: Array = currentLevel.get("questions", [])

	# Reject invalid question indices before changing gameplay state.
	if questionIndex < 0 or questionIndex >= questions.size():
		push_error("Question index out of range: " + str(questionIndex))
		return

	currentQuestionIndex = questionIndex
	questionCompleted = false
	revealedHintCount = 0
	consecutiveIncorrectAttempts = 0
	currentChoiceStage = 0
	currentChoiceOptions.clear()
	unavailableChoiceOptions.clear()
	fillBlankAnswers.clear()
	revealedFillBlankIds.clear()
	ResetQuestionScoring()

	var currentQuestion: Dictionary = questions[currentQuestionIndex]
	var expression: String = currentQuestion.get("expression", "")
	currentExpression = expression
	correctSteps = stepGenerator.GenerateSteps(expression)

	# Stop if the expression cannot produce a valid solution process.
	if correctSteps.is_empty():
		push_error("Failed to generate steps for expression: " + expression)
		gameUI.ShowDataError("This question could not be loaded.")
		return

	# Level Type changes interaction only; all modes consume the same correct Steps.
	if selectedLevelTypeId == MULTIPLE_CHOICE_LEVEL_TYPE_ID:
		gameUI.ShowMultipleChoiceQuestion(
			currentLevel.get("title", "Untitled Level"),
			GetSelectedLevelTypeRule(),
			expression,
			currentQuestionIndex + 1,
			questions.size()
		)
		PrepareMultipleChoiceStage()
	elif selectedLevelTypeId == FILL_PROCESS_LEVEL_TYPE_ID:
		var fillStepData := BuildFillProcessData(correctSteps)
		gameUI.ShowFillProcessQuestion(
			currentLevel.get("title", "Untitled Level"),
			GetSelectedLevelTypeRule(),
			expression,
			currentQuestionIndex + 1,
			questions.size(),
			fillStepData
		)
	else:
		var shuffledSteps := ShuffleSteps(correctSteps)
		gameUI.ShowQuestion(
			currentLevel.get("title", "Untitled Level"),
			GetSelectedLevelTypeRule(),
			expression,
			currentQuestionIndex + 1,
			questions.size(),
			shuffledSteps
		)

	gameUI.UpdateScore(currentQuestionScore, currentLevelScore)
	gameUI.UpdateHintCount(remainingHints)

	if remainingHints <= 0:
		gameUI.SetHintAvailable(false)

# Returns a shuffled step list that differs from the correct order when possible.
func ShuffleSteps(orderedSteps: Array[String]) -> Array[String]:
	var shuffledSteps: Array[String] = orderedSteps.duplicate()

	if shuffledSteps.size() <= 1:
		return shuffledSteps

	# Prevent a question from initially appearing already solved.
	while shuffledSteps == orderedSteps:
		shuffledSteps.shuffle()

	return shuffledSteps

#endregion

#region ========== Step Ordering ==========

# Validates the displayed step order or advances after a correct answer.
func CheckAnswer() -> void:
	if questionCompleted:
		GoToNextQuestion()
		return

	if selectedLevelTypeId == MULTIPLE_CHOICE_LEVEL_TYPE_ID:
		return

	if selectedLevelTypeId == FILL_PROCESS_LEVEL_TYPE_ID:
		CheckFillProcess()
		return

	var currentSteps: Array[String] = gameUI.GetStepOrder()

	# Update gameplay state only after an exact ordered match.
	if currentSteps == correctSteps:
		CompleteQuestion()
		gameUI.ShowCorrectAnswer()
	else:
		gameUI.ShowIncorrectAnswer(RegisterIncorrectAttempt())

# Places the next correct step and updates the remaining hint availability.
func UseHint() -> void:
	# Ignore stale or programmatic requests after the shared budget is exhausted.
	if remainingHints <= 0:
		gameUI.SetHintAvailable(false)
		return

	if selectedLevelTypeId == MULTIPLE_CHOICE_LEVEL_TYPE_ID:
		UseMultipleChoiceHint()
		return

	if selectedLevelTypeId == FILL_PROCESS_LEVEL_TYPE_ID:
		UseFillProcessHint()
		return

	var currentSteps: Array[String] = gameUI.GetStepOrder()
	var firstIncorrectIndex := GetFirstIncorrectStepIndex(currentSteps)

	if firstIncorrectIndex < 0:
		# Give general strategy without revealing that the current order is correct.
		RegisterHintUsed()
		gameUI.ShowOrderingReviewHint()
		UpdateSharedHintAvailability(true)
		return

	# Place the first incorrect step so every Hint resolves one useful error.
	var targetStep := correctSteps[firstIncorrectIndex]
	var stepWasPlaced: bool = gameUI.PlaceStepAt(targetStep, firstIncorrectIndex)

	if not stepWasPlaced:
		return

	revealedHintCount += 1
	RegisterHintUsed()
	gameUI.ShowHintUsed(revealedHintCount)
	UpdateHintAvailability()

# Returns the first incorrect position or -1 when the displayed order is solved.
func GetFirstIncorrectStepIndex(displayedSteps: Array[String]) -> int:
	for stepIndex in range(correctSteps.size()):
		if stepIndex >= displayedSteps.size() or displayedSteps[stepIndex] != correctSteps[stepIndex]:
			return stepIndex

	return -1

# Keeps Hint available without using answer correctness as a visual signal.
func UpdateHintAvailability() -> void:
	if (
		not is_instance_valid(gameUI)
		or questionCompleted
		or selectedLevelTypeId == MULTIPLE_CHOICE_LEVEL_TYPE_ID
	):
		return

	UpdateSharedHintAvailability(true)

#endregion

#region ========== Fill in the Process ==========

# Derives numeric blanks directly from generated correct Steps.
func BuildFillProcessData(solutionSteps: Array[String]) -> Array:
	var fillStepData: Array = []
	var numberPattern := RegEx.new()
	numberPattern.compile("[0-9]+")

	for stepIndex in range(solutionSteps.size()):
		var stepText := solutionSteps[stepIndex]
		var numberMatches := numberPattern.search_all(stepText)

		if numberMatches.is_empty():
			fillStepData.append({"segments": [stepText], "blankIds": []})
			continue

		# Later reasoning lines may contain two blanks; the final result uses one.
		var desiredBlankCount := 1

		if stepIndex > 0 and stepIndex < solutionSteps.size() - 1 and numberMatches.size() >= 2:
			desiredBlankCount = 2

		var selectedMatchStart := numberMatches.size() - desiredBlankCount
		var segments: Array[String] = []
		var blankIds: Array[String] = []
		var textCursor := 0

		for matchIndex in range(selectedMatchStart, numberMatches.size()):
			var numberMatch: RegExMatch = numberMatches[matchIndex]
			segments.append(stepText.substr(textCursor, numberMatch.get_start() - textCursor))
			var blankId := "S%d_B%d" % [stepIndex, matchIndex - selectedMatchStart]
			blankIds.append(blankId)
			fillBlankAnswers[blankId] = numberMatch.get_string()
			textCursor = numberMatch.get_end()

		segments.append(stepText.substr(textCursor))
		fillStepData.append({"segments": segments, "blankIds": blankIds})

	return fillStepData

# Validates every generated blank while preserving empty and incorrect states.
func CheckFillProcess() -> void:
	var enteredAnswers: Dictionary = gameUI.GetFillAnswers()
	var correctBlankIds: Array[String] = []
	var incorrectBlankIds: Array[String] = []

	for blankId in fillBlankAnswers:
		var enteredAnswer: String = enteredAnswers.get(blankId, "")

		if enteredAnswer == fillBlankAnswers[blankId]:
			correctBlankIds.append(blankId)
		elif not enteredAnswer.is_empty():
			incorrectBlankIds.append(blankId)

	if correctBlankIds.size() == fillBlankAnswers.size():
		CompleteQuestion()
		gameUI.ShowFillComplete()
		return

	gameUI.ShowFillValidation(
		correctBlankIds,
		incorrectBlankIds,
		RegisterIncorrectAttempt()
	)
	UpdateFillHintAvailability(enteredAnswers)

# Reveals one unresolved value without exposing the rest of the process.
func UseFillProcessHint() -> void:
	var enteredAnswers: Dictionary = gameUI.GetFillAnswers()

	for blankId in fillBlankAnswers:
		if (
			blankId not in revealedFillBlankIds
			and enteredAnswers.get(blankId, "") != fillBlankAnswers[blankId]
		):
			revealedFillBlankIds.append(blankId)
			revealedHintCount += 1
			RegisterHintUsed()
			gameUI.RevealFillBlank(blankId, fillBlankAnswers[blankId])
			enteredAnswers[blankId] = fillBlankAnswers[blankId]
			UpdateFillHintAvailability(enteredAnswers)
			return

	UpdateSharedHintAvailability(false)

# Keeps Hint available only while at least one unrevealed value is unresolved.
func UpdateFillHintAvailability(enteredAnswers: Dictionary) -> void:
	for blankId in fillBlankAnswers:
		if (
			blankId not in revealedFillBlankIds
			and enteredAnswers.get(blankId, "") != fillBlankAnswers[blankId]
		):
			UpdateSharedHintAvailability(true)
			return

	UpdateSharedHintAvailability(false)

#endregion

#region ========== Progressive Error Feedback ==========

# Records one automatic-feedback attempt and returns its progressive message.
func RegisterIncorrectAttempt() -> String:
	consecutiveIncorrectAttempts += 1
	incorrectAttempts += 1
	currentLevelIncorrectAttempts += 1

	# The first mistake is penalty-free; repeated guessing has a stronger cost.
	if incorrectAttempts >= 2:
		currentQuestionScore = maxi(0, currentQuestionScore - INCORRECT_ATTEMPT_PENALTY)

	gameUI.UpdateScore(currentQuestionScore, currentLevelScore)

	# Repeated mistakes qualify this Question for persistent review.
	if incorrectAttempts >= 2:
		UpdateMistakeBookEntry()

	if consecutiveIncorrectAttempts == 1:
		return "Not quite. Review your work and try again."

	if consecutiveIncorrectAttempts == 2:
		return GetDirectionalErrorFeedback()

	return GetContextualErrorFeedback()

# Identifies a general area to review without exposing the exact correction.
func GetDirectionalErrorFeedback() -> String:
	if selectedLevelTypeId == FILL_PROCESS_LEVEL_TYPE_ID:
		return "Check the arithmetic in the highlighted missing values."

	if "(" in currentExpression:
		return "Check how the grouped parts of the expression are being handled."

	if HasMixedOperationPrecedence():
		return "Check the order in which the operations are being solved."

	if "/" in currentExpression:
		return "Check how the dividend is being divided into equal groups."

	if "*" in currentExpression:
		return "Check the multiplication strategy used in each step."

	if "-" in currentExpression:
		return "Check how the subtraction is decomposed between steps."

	return "Check how the addends are decomposed and regrouped."

# Explains the relevant mathematical rule after repeated incorrect attempts.
func GetContextualErrorFeedback() -> String:
	if "(" in currentExpression:
		return "Operations inside parentheses must be resolved before the surrounding operation."

	if HasMixedOperationPrecedence():
		return "Multiplication and division must be resolved before addition and subtraction."

	if "/" in currentExpression:
		return "A division decomposition must split the dividend into parts divisible by the divisor."

	if "*" in currentExpression:
		return "Partial products must represent the same factors as the original multiplication."

	if "-" in currentExpression:
		return "Each subtraction transformation must preserve the value of the original difference."

	return "Regrouping addends may change their grouping, but it must preserve the same total."

# Returns whether standard operation precedence is relevant to the active expression.
func HasMixedOperationPrecedence() -> bool:
	var hasHigherPriorityOperation := "*" in currentExpression or "/" in currentExpression
	var hasLowerPriorityOperation := "+" in currentExpression or "-" in currentExpression
	return hasHigherPriorityOperation and hasLowerPriorityOperation

#endregion

#region ========== Multiple Choice Ordering ==========

# Builds one randomized candidate set for the active solution stage.
func PrepareMultipleChoiceStage() -> void:
	if currentChoiceStage >= correctSteps.size():
		CompleteQuestion()
		gameUI.ShowMultipleChoiceComplete()
		return

	var correctStep := correctSteps[currentChoiceStage]
	var candidateCount := 4 if correctSteps.size() >= 4 else 3
	currentChoiceOptions = choiceGenerator.BuildChoiceOptions(correctStep, candidateCount)
	unavailableChoiceOptions.clear()
	gameUI.ShowChoiceStage(currentChoiceStage, correctSteps.size(), currentChoiceOptions)
	UpdateSharedHintAvailability(currentChoiceOptions.size() > 1)

# Validates one candidate and advances only when it matches the intended Step.
func SelectMultipleChoice(choiceText: String) -> void:
	if questionCompleted or currentChoiceStage >= correctSteps.size():
		return

	var correctStep := correctSteps[currentChoiceStage]

	if choiceText != correctStep:
		if choiceText not in unavailableChoiceOptions:
			unavailableChoiceOptions.append(choiceText)
		gameUI.ShowIncorrectChoice(choiceText, RegisterIncorrectAttempt())
		UpdateMultipleChoiceHintAvailability(correctStep)
		return

	gameUI.AddResolvedChoiceStep(correctStep)
	currentChoiceStage += 1
	PrepareMultipleChoiceStage()

# Removes one unused incorrect candidate without revealing later solution stages.
func UseMultipleChoiceHint() -> void:
	if questionCompleted or currentChoiceStage >= correctSteps.size():
		UpdateSharedHintAvailability(false)
		return

	var correctStep := correctSteps[currentChoiceStage]
	var removableChoices: Array[String] = []

	for choiceText in currentChoiceOptions:
		if choiceText != correctStep and choiceText not in unavailableChoiceOptions:
			removableChoices.append(choiceText)

	if removableChoices.is_empty():
		UpdateSharedHintAvailability(false)
		return

	removableChoices.shuffle()
	var removedChoice := removableChoices[0]
	unavailableChoiceOptions.append(removedChoice)
	revealedHintCount += 1
	RegisterHintUsed()
	gameUI.RemoveChoiceOption(removedChoice)
	gameUI.ShowMultipleChoiceHintUsed()
	UpdateMultipleChoiceHintAvailability(correctStep)

# Disables Hint after every incorrect option in the current stage is unavailable.
func UpdateMultipleChoiceHintAvailability(correctStep: String) -> void:
	for choiceText in currentChoiceOptions:
		if choiceText != correctStep and choiceText not in unavailableChoiceOptions:
			UpdateSharedHintAvailability(true)
			return

	UpdateSharedHintAvailability(false)

#endregion

#region ========== Question Progression ==========

# Advances to the next question or completes the current level.
func GoToNextQuestion() -> void:
	var questions: Array = currentLevel.get("questions", [])
	var nextQuestionIndex := currentQuestionIndex + 1

	# Complete the level after the final question.
	if nextQuestionIndex >= questions.size():
		var maxLevelScore: int = questions.size() * MAX_QUESTION_SCORE
		var starCount := CalculateStarRating(currentLevelScore, maxLevelScore)
		var scorePercentage := roundi(float(currentLevelScore) / float(maxLevelScore) * 100.0)
		var resultData := RecordLevelResult(starCount)
		var currentLevelIndex := levels.find(currentLevel)
		gameUI.ShowEndMenu({
			"levelTitle": currentLevel.get("title", "Untitled Level"),
			"levelTypeTitle": GetLevelTypeById(selectedLevelTypeId).get("title", "Unknown Mode"),
			"score": currentLevelScore,
			"maxScore": maxLevelScore,
			"percentage": scorePercentage,
			"stars": starCount,
			"questionsCompleted": questions.size(),
			"questionCount": questions.size(),
			"incorrectAttempts": currentLevelIncorrectAttempts,
			"hintsUsed": currentLevelHintsUsed,
			"bestScore": resultData.get("bestScore", currentLevelScore),
			"isNewBest": resultData.get("isNewBest", false),
			"hasNextLevel": currentLevelIndex >= 0 and currentLevelIndex < levels.size() - 1
		})
		return

	LoadQuestion(nextQuestionIndex)

#endregion

#region ========== Scoring and Hints ==========

# Resets all score counters owned by one newly started Level session.
func ResetLevelScoring() -> void:
	currentLevelScore = 0
	currentLevelIncorrectAttempts = 0
	currentLevelHintsUsed = 0
	levelHintBudget = GetLevelHintBudget()
	remainingHints = levelHintBudget
	ResetQuestionScoring()

# Gives a newly loaded Question its full score and fresh action counters.
func ResetQuestionScoring() -> void:
	currentQuestionScore = MAX_QUESTION_SCORE
	incorrectAttempts = 0
	hintsUsed = 0
	questionScoreCommitted = false

# Charges one successful Hint use without allowing a negative Question Score.
func RegisterHintUsed() -> void:
	hintsUsed += 1
	currentLevelHintsUsed += 1
	remainingHints = maxi(0, remainingHints - 1)
	currentQuestionScore = maxi(0, currentQuestionScore - HINT_SCORE_PENALTY)
	gameUI.UpdateScore(currentQuestionScore, currentLevelScore)
	gameUI.UpdateHintCount(remainingHints)

	# Any requested Hint qualifies this Question for persistent review.
	UpdateMistakeBookEntry()

#endregion

#region ========== Mistake Book ==========

# Returns an isolated copy of every saved mistake entry.
func GetMistakeBookEntries() -> Array:
	return mistakeBookManager.GetEntries()

# Adds or updates the current Question without duplicating its mode-specific entry.
func UpdateMistakeBookEntry() -> void:
	var questions: Array = currentLevel.get("questions", [])

	if currentQuestionIndex < 0 or currentQuestionIndex >= questions.size():
		return

	var question: Dictionary = questions[currentQuestionIndex]
	mistakeBookManager.RecordQuestion({
		"questionId": question.get("id", ""),
		"levelId": currentLevel.get("id", ""),
		"levelTitle": currentLevel.get("title", "Untitled Level"),
		"levelTypeId": selectedLevelTypeId,
		"levelTypeTitle": GetLevelTypeById(selectedLevelTypeId).get("title", "Unknown Mode"),
		"expression": currentExpression,
		"skills": currentLevel.get("skills", []).duplicate(),
		"incorrectAttempts": incorrectAttempts,
		"hintUsed": hintsUsed > 0,
		"answerSteps": correctSteps.duplicate()
	})

# Removes one saved mistake by its stable mode, Level, and Question key.
func RemoveMistakeBookEntry(entryKey: String) -> void:
	mistakeBookManager.RemoveEntry(entryKey)

#endregion

#region ========== Shared Hints and Level Completion ==========

# Returns the fixed shared Hint budget for the selected Level range.
func GetLevelHintBudget() -> int:
	var selectedLevelIndex := 0
	var selectedLevelId := GetSelectedLevelId()

	for levelIndex in range(levels.size()):
		if levels[levelIndex].get("id", "") == selectedLevelId:
			selectedLevelIndex = levelIndex
			break

	if selectedLevelIndex < 4:
		return EARLY_LEVEL_HINT_BUDGET
	if selectedLevelIndex < 8:
		return MIDDLE_LEVEL_HINT_BUDGET

	return ADVANCED_LEVEL_HINT_BUDGET

# Combines mode-specific usefulness with the shared remaining Hint count.
func UpdateSharedHintAvailability(isModeHintAvailable: bool) -> void:
	gameUI.SetHintAvailable(isModeHintAvailable and remainingHints > 0)

# Completes one Question and commits its final score to the Level exactly once.
func CompleteQuestion() -> void:
	if questionScoreCommitted:
		return

	questionCompleted = true
	consecutiveIncorrectAttempts = 0
	questionScoreCommitted = true
	currentLevelScore += currentQuestionScore
	gameUI.UpdateScore(currentQuestionScore, currentLevelScore)

# Calculates a Level rating using score percentage as its only input.
func CalculateStarRating(levelScore: int, maxLevelScore: int) -> int:
	if maxLevelScore <= 0:
		return 0

	var scoreRatio := float(levelScore) / float(maxLevelScore)

	if scoreRatio >= 0.95:
		return 3
	if scoreRatio >= 0.8:
		return 2
	if scoreRatio >= 0.6:
		return 1

	return 0

# Restarts the active level from its first question.
func RestartLevel() -> void:
	gameUI.HideEndMenu()
	ResetLevelScoring()
	LoadQuestion(0)

# Starts the next data-driven Level while preserving the selected Level Type.
func OpenNextLevel() -> void:
	var currentLevelIndex := levels.find(currentLevel)

	if currentLevelIndex < 0 or currentLevelIndex >= levels.size() - 1:
		OpenLobby()
		return

	if SelectLevel(levels[currentLevelIndex + 1].get("id", "")):
		OpenGame()

# Returns to the Lobby while preserving current-session Level progress.
func BackToLobby() -> void:
	OpenLobby()

#endregion
