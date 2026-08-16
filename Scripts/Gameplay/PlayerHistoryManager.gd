## Owns the persistent, bounded history of completed Question performance.
##
## Raw event timelines remain temporary telemetry. This service stores only the
## stable summary fields required by later Skill analysis and recommendations.
extends RefCounted

#region ========== Configuration ==========

const PLAYER_HISTORY_SCHEMA_VERSION: int = 1
const MAX_HISTORY_RECORDS: int = 1000
const ENABLE_CONSOLE_OUTPUT: bool = true

#endregion

#region ========== Functions ==========

# Saves one completed telemetry summary and returns the stored record.
func RecordCompletedQuestion(telemetryRecord: Dictionary) -> Dictionary:
	if telemetryRecord.is_empty():
		return {}

	var history: Array = GetHistory()
	var historyRecord := BuildHistoryRecord(telemetryRecord)
	history.append(historyRecord)

	# Keep storage bounded while retaining the newest learning evidence.
	while history.size() > MAX_HISTORY_RECORDS:
		history.pop_front()

	SaveManager.SetSection("playerHistory", history)

	if ENABLE_CONSOLE_OUTPUT:
		print("[M5 Player History] savedRecords=", history.size())

	return historyRecord.duplicate(true)

# Returns an isolated copy of the complete saved Question history.
func GetHistory() -> Array:
	var savedHistory = SaveManager.GetSection("playerHistory")
	return savedHistory if savedHistory is Array else []

# Removes event-level detail and preserves deterministic analysis inputs.
func BuildHistoryRecord(telemetryRecord: Dictionary) -> Dictionary:
	return {
		"historySchemaVersion": PLAYER_HISTORY_SCHEMA_VERSION,
		"telemetrySchemaVersion": telemetryRecord.get("telemetrySchemaVersion", 1),
		"questionId": telemetryRecord.get("questionId", ""),
		"levelId": telemetryRecord.get("levelId", ""),
		"levelTitle": telemetryRecord.get("levelTitle", ""),
		"levelTypeId": telemetryRecord.get("levelTypeId", ""),
		"sessionType": telemetryRecord.get("sessionType", "level"),
		"expression": telemetryRecord.get("expression", ""),
		"skills": telemetryRecord.get("skills", []).duplicate(),
		"startedAtUnixMs": telemetryRecord.get("startedAtUnixMs", 0),
		"firstActionType": telemetryRecord.get("firstActionType", ""),
		"firstActionTimeMs": telemetryRecord.get("firstActionTimeMs", -1),
		"totalSolveTimeMs": telemetryRecord.get("totalSolveTimeMs", -1),
		"sharedMetrics": telemetryRecord.get("sharedMetrics", {}).duplicate(true),
		"modeMetrics": telemetryRecord.get("modeMetrics", {}).duplicate(true),
		"behaviorPatterns": telemetryRecord.get("behaviorPatterns", []).duplicate(),
		"primaryBehaviorPattern": telemetryRecord.get("primaryBehaviorPattern", ""),
		"outcome": telemetryRecord.get("outcome", {}).duplicate(true)
	}

#endregion
