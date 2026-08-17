## Coordinates MathSmith's telemetry, learning history, and adaptive analysis.
##
## GameManager reports gameplay events through this facade. Focused learning
## services remain independently configurable without leaking orchestration
## order into the main gameplay controller.
extends RefCounted

#region ========== References ==========

var telemetryManager := preload("res://Scripts/Learning/TelemetryManager.gd").new()
var playerHistoryManager := preload("res://Scripts/Learning/PlayerHistoryManager.gd").new()
var skillMasteryManager := preload("res://Scripts/Learning/SkillMasteryManager.gd").new()
var behaviorPatternManager := preload("res://Scripts/Learning/BehaviorPatternManager.gd").new()
var adaptiveLearningManager := preload("res://Scripts/Learning/AdaptiveLearningManager.gd").new()

#endregion

#region ========== Learning State ==========

# Rebuilds derived Skill data from persistent Question history.
func Initialize() -> void:
	skillMasteryManager.RebuildSkillProgress(playerHistoryManager.GetHistory())

# Returns completed in-memory telemetry without exposing tracker state.
func GetQuestionTelemetryRecords() -> Array[Dictionary]:
	return telemetryManager.GetCompletedRecords()

# Returns the current unfinished Question record with live elapsed time.
func GetActiveQuestionTelemetry() -> Dictionary:
	return telemetryManager.GetActiveQuestionSnapshot()

# Returns the persistent history of completed Question summaries.
func GetPlayerHistory() -> Array:
	return playerHistoryManager.GetHistory()

# Returns persisted Skill aggregation and Mastery values.
func GetSkillProgress() -> Dictionary:
	return skillMasteryManager.GetSkillProgress()

# Returns learned Skills below the centralized Mastery threshold.
func GetWeakSkills() -> Array[String]:
	return adaptiveLearningManager.GetWeakSkills(GetSkillProgress())

# Returns ranked Levels whose declared Skills match current learning needs.
func GetWeakSkillRecommendations(levels: Array) -> Array[Dictionary]:
	return adaptiveLearningManager.BuildWeakSkillRecommendations(levels, GetSkillProgress())

# Selects a finite weighted sample for adaptive replay sessions.
func SelectWeightedQuestions(candidates: Array, selectionCount: int) -> Array[Dictionary]:
	return adaptiveLearningManager.SelectWeightedQuestions(
		candidates,
		GetWeakSkills(),
		selectionCount
	)

#endregion

#region ========== Question Lifecycle ==========

# Starts raw telemetry after a Question becomes interactive.
func BeginQuestion(questionContext: Dictionary) -> void:
	telemetryManager.BeginQuestion(questionContext)

# Finalizes telemetry, behavior classification, history, and Skill progress.
func CompleteQuestion(outcomeData: Dictionary) -> void:
	var completedTelemetry := telemetryManager.CompleteQuestion(outcomeData)
	if completedTelemetry.is_empty():
		return

	var behaviorAnalysis := behaviorPatternManager.AnalyzeQuestion(completedTelemetry)
	completedTelemetry["behaviorPatterns"] = behaviorAnalysis["patterns"]
	completedTelemetry["primaryBehaviorPattern"] = behaviorAnalysis["primaryPattern"]
	playerHistoryManager.RecordCompletedQuestion(completedTelemetry)
	skillMasteryManager.RebuildSkillProgress(playerHistoryManager.GetHistory())

#endregion

#region ========== Behavior Events ==========

# Records a Check submission for the active gameplay interaction.
func RecordCheckSubmission(levelTypeId: String) -> void:
	telemetryManager.RecordCheckSubmission(levelTypeId)

# Records one incorrect attempt for shared and mode-specific metrics.
func RecordIncorrectAttempt(levelTypeId: String) -> void:
	telemetryManager.RecordIncorrectAttempt(levelTypeId)

# Records one successful player-requested Hint use.
func RecordHintUse() -> void:
	telemetryManager.RecordHintUse()

# Records one Multiple-Choice option selection.
func RecordChoiceSelection() -> void:
	telemetryManager.RecordChoiceSelection()

# Records the beginning of one Step Card drag.
func RecordStepDragStarted() -> void:
	telemetryManager.RecordStepDragStarted()

# Records one player-driven Step Card index change.
func RecordStepReordered() -> void:
	telemetryManager.RecordStepReordered()

# Records one successful Step Card drop.
func RecordStepDragCompleted() -> void:
	telemetryManager.RecordStepDragCompleted()

# Records one player-originated Fill input change.
func RecordFillValueChanged(blankId: String) -> void:
	telemetryManager.RecordFillValueChanged(blankId)

#endregion
