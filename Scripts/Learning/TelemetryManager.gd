## Records raw M5 Question behavior without interpreting player intent.
##
## Raw telemetry remains memory-only and deterministic. Persistent history,
## behavior analysis, and adaptive systems consume its completed summaries.
extends RefCounted

#region ========== Configuration ==========

const TELEMETRY_SCHEMA_VERSION: int = 1
const ENABLE_CONSOLE_OUTPUT: bool = false
const MAX_MEMORY_RECORDS: int = 200
const MAX_EVENTS_PER_QUESTION: int = 500

#endregion

#region ========== Variables ==========

var activeQuestion: Dictionary = {}
var completedRecords: Array[Dictionary] = []
var questionStartTicksMs: int = 0
var uniqueEditedBlankIds: Dictionary = {}

#endregion

#region ========== Functions ==========

# Clears in-memory analytics when the active Course Source changes.
func ResetCourseContext() -> void:
	activeQuestion.clear()
	completedRecords.clear()
	uniqueEditedBlankIds.clear()
	questionStartTicksMs = 0

# Starts a fresh raw record when one Question becomes interactive.
func BeginQuestion(questionContext: Dictionary) -> void:
	questionStartTicksMs = Time.get_ticks_msec()
	uniqueEditedBlankIds.clear()
	activeQuestion = {
		"telemetrySchemaVersion": TELEMETRY_SCHEMA_VERSION,
		"questionId": questionContext.get("questionId", ""),
		"levelId": questionContext.get("levelId", ""),
		"levelTitle": questionContext.get("levelTitle", ""),
		"levelTypeId": questionContext.get("levelTypeId", ""),
		"sessionType": questionContext.get("sessionType", "level"),
		"expression": questionContext.get("expression", ""),
		"skills": questionContext.get("skills", []).duplicate(),
		"startedAtUnixMs": int(Time.get_unix_time_from_system() * 1000.0),
		"firstActionType": "",
		"firstActionTimeMs": -1,
		"totalSolveTimeMs": -1,
		"sharedMetrics": {
			"totalActions": 0,
			"checkSubmissions": 0,
			"hintUses": 0,
			"incorrectAttempts": 0
		},
		"modeMetrics": {
			"stepOrdering": {
				"dragStarts": 0,
				"reorderMoves": 0,
				"completedDrops": 0
			},
			"multipleChoiceOrdering": {
				"optionSelections": 0,
				"incorrectSelections": 0
			},
			"fillInProcess": {
				"valueEdits": 0,
				"editedBlankCount": 0,
				"checkSubmissions": 0,
				"incorrectSubmissions": 0
			}
		},
		"events": []
	}

# Records a Check submission for Step Ordering or Fill in the Process.
func RecordCheckSubmission(levelTypeId: String) -> void:
	if not HasActiveQuestion():
		return

	IncrementSharedMetric("checkSubmissions")
	RecordAction("check_submission")

	if levelTypeId == "fill_in_process":
		IncrementModeMetric("fillInProcess", "checkSubmissions")

# Records one successful player-requested Hint use.
func RecordHintUse() -> void:
	if not HasActiveQuestion():
		return

	IncrementSharedMetric("hintUses")
	RecordAction("hint_use")

# Records one validated incorrect attempt after its source action is counted.
func RecordIncorrectAttempt(levelTypeId: String) -> void:
	if not HasActiveQuestion():
		return

	IncrementSharedMetric("incorrectAttempts")

	if levelTypeId == "multiple_choice_ordering":
		IncrementModeMetric("multipleChoiceOrdering", "incorrectSelections")
	elif levelTypeId == "fill_in_process":
		IncrementModeMetric("fillInProcess", "incorrectSubmissions")

	RecordEvent("incorrect_attempt")

# Records the start of one Step Card drag, including cancelled drags.
func RecordStepDragStarted() -> void:
	if not HasActiveQuestion():
		return

	IncrementModeMetric("stepOrdering", "dragStarts")
	RecordAction("step_drag_started")

# Records each actual card index change during a player drag.
func RecordStepReordered() -> void:
	if not HasActiveQuestion():
		return

	IncrementModeMetric("stepOrdering", "reorderMoves")
	RecordAction("step_reordered")

# Records a successful drag release even when no index changed.
func RecordStepDragCompleted() -> void:
	if not HasActiveQuestion():
		return

	IncrementModeMetric("stepOrdering", "completedDrops")
	RecordAction("step_drag_completed")

# Records one Multiple-Choice option selection before correctness is known.
func RecordChoiceSelection() -> void:
	if not HasActiveQuestion():
		return

	IncrementModeMetric("multipleChoiceOrdering", "optionSelections")
	RecordAction("choice_selected")

# Records one player-originated Fill value edit and its unique field identity.
func RecordFillValueChanged(blankId: String) -> void:
	if not HasActiveQuestion():
		return

	IncrementModeMetric("fillInProcess", "valueEdits")

	if not blankId.is_empty():
		uniqueEditedBlankIds[blankId] = true
		activeQuestion["modeMetrics"]["fillInProcess"]["editedBlankCount"] = (
			uniqueEditedBlankIds.size()
		)

	RecordAction("fill_value_changed", {"blankId": blankId})

# Finalizes one solved Question and returns an isolated raw record.
func CompleteQuestion(outcomeData: Dictionary) -> Dictionary:
	if not HasActiveQuestion():
		return {}

	activeQuestion["totalSolveTimeMs"] = GetElapsedMs()
	activeQuestion["outcome"] = outcomeData.duplicate(true)
	RecordEvent("question_completed")
	var completedRecord: Dictionary = activeQuestion.duplicate(true)
	completedRecords.append(completedRecord)

	if completedRecords.size() > MAX_MEMORY_RECORDS:
		completedRecords.pop_front()

	if ENABLE_CONSOLE_OUTPUT:
		print("[M5 Telemetry] ", JSON.stringify(completedRecord, "  "))

	activeQuestion.clear()
	uniqueEditedBlankIds.clear()
	return completedRecord

# Returns isolated completed records for analysis systems and inspection.
func GetCompletedRecords() -> Array[Dictionary]:
	return completedRecords.duplicate(true)

# Returns the live record so manual debugging can inspect an unfinished Question.
func GetActiveQuestionSnapshot() -> Dictionary:
	if not HasActiveQuestion():
		return {}

	var snapshot: Dictionary = activeQuestion.duplicate(true)
	snapshot["elapsedTimeMs"] = GetElapsedMs()
	return snapshot

# Returns whether one Question is currently accepting raw telemetry.
func HasActiveQuestion() -> bool:
	return not activeQuestion.is_empty()

# Counts one player action and captures First Action exactly once.
func RecordAction(actionType: String, details: Dictionary = {}) -> void:
	IncrementSharedMetric("totalActions")

	if activeQuestion.get("firstActionTimeMs", -1) < 0:
		activeQuestion["firstActionTimeMs"] = GetElapsedMs()
		activeQuestion["firstActionType"] = actionType

	RecordEvent(actionType, details)

# Adds one timestamped event while enforcing the centralized memory limit.
func RecordEvent(eventType: String, details: Dictionary = {}) -> void:
	var events: Array = activeQuestion.get("events", [])

	if events.size() >= MAX_EVENTS_PER_QUESTION:
		return

	var eventData := {
		"type": eventType,
		"elapsedMs": GetElapsedMs()
	}

	for detailKey in details:
		eventData[detailKey] = details[detailKey]

	events.append(eventData)
	activeQuestion["events"] = events

# Increments one shared integer metric without exposing its storage shape.
func IncrementSharedMetric(metricName: String) -> void:
	var sharedMetrics: Dictionary = activeQuestion["sharedMetrics"]
	sharedMetrics[metricName] = int(sharedMetrics.get(metricName, 0)) + 1
	activeQuestion["sharedMetrics"] = sharedMetrics

# Increments one gameplay-mode metric without interpreting its meaning.
func IncrementModeMetric(modeName: String, metricName: String) -> void:
	var modeMetrics: Dictionary = activeQuestion["modeMetrics"]
	var selectedMetrics: Dictionary = modeMetrics[modeName]
	selectedMetrics[metricName] = int(selectedMetrics.get(metricName, 0)) + 1
	modeMetrics[modeName] = selectedMetrics
	activeQuestion["modeMetrics"] = modeMetrics

# Returns monotonic milliseconds since the active Question began.
func GetElapsedMs() -> int:
	return maxi(0, Time.get_ticks_msec() - questionStartTicksMs)

#endregion
