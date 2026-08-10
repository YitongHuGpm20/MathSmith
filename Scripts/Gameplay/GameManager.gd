## Controls the complete M1 gameplay loop for the active level.
##
## This script owns question state, gameplay validation, navigation, progress,
## and level completion. LevelLoader supplies content, StepGenerator produces
## teaching steps, and GameUI only presents Game Scene state.
extends Node

#region ========== Constants ==========

const HOME_SCENE_PATH: String = "res://Scenes/HomeScene.tscn"
const LOBBY_SCENE_PATH: String = "res://Scenes/LobbyScene.tscn"
const GAME_SCENE_PATH: String = "res://Scenes/GameScene.tscn"
const DEFAULT_LEVEL_TYPE_ID: String = "step_ordering"
const MULTIPLE_CHOICE_LEVEL_TYPE_ID: String = "multiple_choice_ordering"
const FILL_PROCESS_LEVEL_TYPE_ID: String = "fill_in_process"
const MAX_QUESTION_SCORE: int = 100
const INCORRECT_ATTEMPT_PENALTY: int = 10
const HINT_SCORE_PENALTY: int = 10

#endregion

#region ========== References ==========

var gameUI: Node = null
var levelLoader := preload("res://Scripts/Gameplay/LevelLoader.gd").new()
var stepGenerator := preload("res://Scripts/Math/StepGenerator.gd").new()
var expressionParser := preload("res://Scripts/Math/ExpressionParser.gd").new()

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
var levelProgress: Dictionary = {}
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

#endregion

#region ========== Functions ==========

# Opens the Home Scene while preserving current-session progress.
func OpenHome() -> void:
	ChangeScene(HOME_SCENE_PATH)

# Opens the Lobby Scene while preserving current-session progress.
func OpenLobby() -> void:
	ChangeScene(LOBBY_SCENE_PATH)

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

# Registers the active Game Scene UI and starts its current Level.
func RegisterGameUI(newGameUI: Node) -> void:
	if is_instance_valid(gameUI):
		DisconnectGameUISignals()

	gameUI = newGameUI
	gameUI.checkRequested.connect(CheckAnswer)
	gameUI.hintRequested.connect(UseHint)
	gameUI.retryRequested.connect(RestartLevel)
	gameUI.lobbyRequested.connect(BackToLobby)
	gameUI.orderChanged.connect(UpdateHintAvailability)
	gameUI.choiceSelected.connect(SelectMultipleChoice)

	# Surface content errors only after a visual UI is available.
	if levels.is_empty():
		gameUI.ShowDataError("No valid level data could be loaded.")
		return

	if currentLevel.is_empty():
		currentLevel = levels[0]

	ResetLevelScoring()
	LoadQuestion(0)

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

	if gameUI.lobbyRequested.is_connected(BackToLobby):
		gameUI.lobbyRequested.disconnect(BackToLobby)

	if gameUI.orderChanged.is_connected(UpdateHintAvailability):
		gameUI.orderChanged.disconnect(UpdateHintAvailability)

	if gameUI.choiceSelected.is_connected(SelectMultipleChoice):
		gameUI.choiceSelected.disconnect(SelectMultipleChoice)

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

# Returns lightweight progress for one Level during the current run.
func GetLevelProgress(levelId: String) -> Dictionary:
	return levelProgress.get(
		levelId,
		{
			"completedQuestions": 0,
			"completed": false
		}
	)

# Records the highest completed Question reached in the selected Level.
func RecordQuestionCompletion() -> void:
	var levelId: String = GetSelectedLevelId()

	if levelId.is_empty():
		return

	var progressData := GetLevelProgress(levelId)
	progressData["completedQuestions"] = maxi(
		progressData["completedQuestions"],
		currentQuestionIndex + 1
	)
	levelProgress[levelId] = progressData

# Marks the selected Level complete for the remainder of the current run.
func CompleteCurrentLevel(starCount: int) -> void:
	var levelId: String = GetSelectedLevelId()

	if levelId.is_empty():
		return

	var progressData := GetLevelProgress(levelId)
	progressData["completedQuestions"] = currentLevel.get("questions", []).size()
	progressData["completed"] = progressData.get("completed", false) or starCount >= 1
	levelProgress[levelId] = progressData

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

# Returns a shuffled step list that differs from the correct order when possible.
func ShuffleSteps(orderedSteps: Array[String]) -> Array[String]:
	var shuffledSteps: Array[String] = orderedSteps.duplicate()

	if shuffledSteps.size() <= 1:
		return shuffledSteps

	# Prevent a question from initially appearing already solved.
	while shuffledSteps == orderedSteps:
		shuffledSteps.shuffle()

	return shuffledSteps

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
	if selectedLevelTypeId == MULTIPLE_CHOICE_LEVEL_TYPE_ID:
		UseMultipleChoiceHint()
		return

	if selectedLevelTypeId == FILL_PROCESS_LEVEL_TYPE_ID:
		UseFillProcessHint()
		return

	var currentSteps: Array[String] = gameUI.GetStepOrder()
	var firstIncorrectIndex := GetFirstIncorrectStepIndex(currentSteps)

	if firstIncorrectIndex < 0:
		gameUI.SetHintAvailable(false)
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

# Keeps Hint available only while the active question still contains an error.
func UpdateHintAvailability() -> void:
	if (
		not is_instance_valid(gameUI)
		or questionCompleted
		or selectedLevelTypeId == MULTIPLE_CHOICE_LEVEL_TYPE_ID
	):
		return

	gameUI.SetHintAvailable(GetFirstIncorrectStepIndex(gameUI.GetStepOrder()) >= 0)

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

	gameUI.SetHintAvailable(false)

# Keeps Hint available only while at least one unrevealed value is unresolved.
func UpdateFillHintAvailability(enteredAnswers: Dictionary) -> void:
	for blankId in fillBlankAnswers:
		if (
			blankId not in revealedFillBlankIds
			and enteredAnswers.get(blankId, "") != fillBlankAnswers[blankId]
		):
			gameUI.SetHintAvailable(true)
			return

	gameUI.SetHintAvailable(false)

# Records one automatic-feedback attempt and returns its progressive message.
func RegisterIncorrectAttempt() -> String:
	consecutiveIncorrectAttempts += 1
	incorrectAttempts += 1
	currentLevelIncorrectAttempts += 1

	# The first mistake is penalty-free; every later mistake costs ten points.
	if incorrectAttempts >= 2:
		currentQuestionScore = maxi(0, currentQuestionScore - INCORRECT_ATTEMPT_PENALTY)

	gameUI.UpdateScore(currentQuestionScore, currentLevelScore)

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

# Builds one randomized candidate set for the active solution stage.
func PrepareMultipleChoiceStage() -> void:
	if currentChoiceStage >= correctSteps.size():
		CompleteQuestion()
		gameUI.ShowMultipleChoiceComplete()
		return

	var correctStep := correctSteps[currentChoiceStage]
	var candidateCount := 4 if correctSteps.size() >= 4 else 3
	currentChoiceOptions = BuildChoiceOptions(correctStep, candidateCount)
	unavailableChoiceOptions.clear()
	gameUI.ShowChoiceStage(currentChoiceStage, correctSteps.size(), currentChoiceOptions)
	gameUI.SetHintAvailable(currentChoiceOptions.size() > 1)

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
		gameUI.SetHintAvailable(false)
		return

	var correctStep := correctSteps[currentChoiceStage]
	var removableChoices: Array[String] = []

	for choiceText in currentChoiceOptions:
		if choiceText != correctStep and choiceText not in unavailableChoiceOptions:
			removableChoices.append(choiceText)

	if removableChoices.is_empty():
		gameUI.SetHintAvailable(false)
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
			gameUI.SetHintAvailable(true)
			return

	gameUI.SetHintAvailable(false)

# Creates plausible, unique, non-equivalent distractors around one correct Step.
func BuildChoiceOptions(correctStep: String, candidateCount: int) -> Array[String]:
	var choices: Array[String] = [correctStep]
	var correctValue = EvaluateStepText(correctStep)
	var numberPattern := RegEx.new()
	numberPattern.compile("[0-9]+")
	var numberMatches := numberPattern.search_all(correctStep)
	var adjustments: Array[int] = [1, -1, 2, -2, 10, -10]

	# Arithmetic-value changes create believable mistakes without random nonsense.
	for numberMatch in numberMatches:
		var originalNumber := int(numberMatch.get_string())

		for adjustment in adjustments:
			var changedNumber := originalNumber + adjustment

			if changedNumber < 0:
				continue

			var candidate := (
				correctStep.left(numberMatch.get_start())
				+ str(changedNumber)
				+ correctStep.substr(numberMatch.get_end())
			)
			AppendValidDistractor(choices, candidate, correctValue)

			if choices.size() >= candidateCount:
				break

		if choices.size() >= candidateCount:
			break

	# Operator changes provide a fallback for unusually short numeric Steps.
	if choices.size() < candidateCount:
		var operatorChanges := {
			" + ": " - ",
			" - ": " + ",
			" * ": " + ",
			" / ": " * "
		}

		for sourceOperator in operatorChanges:
			if sourceOperator not in correctStep:
				continue

			var candidate := correctStep.replace(sourceOperator, operatorChanges[sourceOperator])
			AppendValidDistractor(choices, candidate, correctValue)

			if choices.size() >= candidateCount:
				break

	choices.shuffle()
	return choices

# Adds one distractor only when it parses and evaluates differently from the answer.
func AppendValidDistractor(choices: Array[String], candidate: String, correctValue: Variant) -> void:
	if candidate in choices:
		return

	var candidateValue = EvaluateStepText(candidate)

	if candidateValue == null or candidateValue == correctValue:
		return

	choices.append(candidate)

# Evaluates one displayed Step for deterministic equivalence filtering.
func EvaluateStepText(stepText: String) -> Variant:
	var expressionText := stepText.trim_prefix("= ")
	var expressionTree := expressionParser.ParseExpression(expressionText)

	if expressionTree.is_empty():
		return null

	var resultData := EvaluateExpressionNode(expressionTree)
	return resultData.get("value") if resultData.get("valid", false) else null

# Evaluates a parser node while rejecting invalid or non-whole-number division.
func EvaluateExpressionNode(expressionNode: Dictionary) -> Dictionary:
	if expressionNode["type"] == "number":
		return {"valid": true, "value": expressionNode["value"]}

	var leftResult := EvaluateExpressionNode(expressionNode["left"])
	var rightResult := EvaluateExpressionNode(expressionNode["right"])

	if not leftResult["valid"] or not rightResult["valid"]:
		return {"valid": false}

	var leftValue: int = leftResult["value"]
	var rightValue: int = rightResult["value"]

	match expressionNode["operation"]:
		"+":
			return {"valid": true, "value": leftValue + rightValue}
		"-":
			return {"valid": true, "value": leftValue - rightValue}
		"*":
			return {"valid": true, "value": leftValue * rightValue}
		"/":
			if rightValue == 0 or leftValue % rightValue != 0:
				return {"valid": false}
			return {"valid": true, "value": floori(float(leftValue) / float(rightValue))}

	return {"valid": false}

# Advances to the next question or completes the current level.
func GoToNextQuestion() -> void:
	var questions: Array = currentLevel.get("questions", [])
	var nextQuestionIndex := currentQuestionIndex + 1

	# Complete the level after the final question.
	if nextQuestionIndex >= questions.size():
		var maxLevelScore: int = questions.size() * MAX_QUESTION_SCORE
		var starCount := CalculateStarRating(currentLevelScore, maxLevelScore)
		var scorePercentage := roundi(float(currentLevelScore) / float(maxLevelScore) * 100.0)
		CompleteCurrentLevel(starCount)
		gameUI.ShowEndMenu(currentLevelScore, maxLevelScore, scorePercentage, starCount)
		return

	LoadQuestion(nextQuestionIndex)

# Resets all score counters owned by one newly started Level session.
func ResetLevelScoring() -> void:
	currentLevelScore = 0
	currentLevelIncorrectAttempts = 0
	currentLevelHintsUsed = 0
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
	currentQuestionScore = maxi(0, currentQuestionScore - HINT_SCORE_PENALTY)
	gameUI.UpdateScore(currentQuestionScore, currentLevelScore)

# Completes one Question and commits its final score to the Level exactly once.
func CompleteQuestion() -> void:
	if questionScoreCommitted:
		return

	questionCompleted = true
	consecutiveIncorrectAttempts = 0
	questionScoreCommitted = true
	currentLevelScore += currentQuestionScore
	RecordQuestionCompletion()
	gameUI.UpdateScore(currentQuestionScore, currentLevelScore)

# Calculates a Level rating using score percentage as its only input.
func CalculateStarRating(levelScore: int, maxLevelScore: int) -> int:
	if maxLevelScore <= 0:
		return 0

	var scoreRatio := float(levelScore) / float(maxLevelScore)

	if scoreRatio >= 0.9:
		return 3
	if scoreRatio >= 0.7:
		return 2
	if scoreRatio >= 0.5:
		return 1

	return 0

# Restarts the active level from its first question.
func RestartLevel() -> void:
	gameUI.HideEndMenu()
	ResetLevelScoring()
	LoadQuestion(0)

# Returns to the Lobby while preserving current-session Level progress.
func BackToLobby() -> void:
	OpenLobby()

#endregion
