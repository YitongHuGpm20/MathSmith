## Detects deterministic player behavior patterns from one Question record.
##
## Every threshold and priority is centralized for manual M5 tuning. This
## service classifies recorded behavior but never changes scoring or gameplay.
extends RefCounted

#region ========== Threshold Configuration ==========

const FIRST_ACTION_HESITATION_MS: int = 8000
const LONG_SOLVE_TIME_MS: int = 30000
const REPEATED_INCORRECT_ATTEMPTS: int = 2
const REPEATED_HINT_USES: int = 2
const REPEATED_CHECK_SUBMISSIONS: int = 3
const EXCESSIVE_REORDER_MOVES: int = 12
const EXCESSIVE_FILL_REVISIONS: int = 3
const ENABLE_CONSOLE_OUTPUT: bool = true

#endregion

#region ========== Priority Configuration ==========

const PRIORITY_CRITICAL: int = 300
const PRIORITY_HIGH: int = 200
const PRIORITY_MEDIUM: int = 100

const PATTERN_PRIORITIES: Dictionary = {
	"repeated_incorrect_attempts": PRIORITY_CRITICAL,
	"repeated_hint_use": PRIORITY_HIGH,
	"repeated_submissions": PRIORITY_HIGH,
	"excessive_reordering": PRIORITY_MEDIUM,
	"excessive_fill_revision": PRIORITY_MEDIUM,
	"long_solve_time": PRIORITY_MEDIUM,
	"first_action_hesitation": PRIORITY_MEDIUM
}

const PATTERN_TIE_BREAK_ORDER: Array[String] = [
	"repeated_incorrect_attempts",
	"repeated_hint_use",
	"repeated_submissions",
	"excessive_reordering",
	"excessive_fill_revision",
	"long_solve_time",
	"first_action_hesitation"
]

#endregion

#region ========== Functions ==========

# Returns every matching behavior pattern and the single highest priority one.
func AnalyzeQuestion(questionRecord: Dictionary) -> Dictionary:
	var detectedPatterns: Array[String] = []
	var sharedMetrics: Dictionary = questionRecord.get("sharedMetrics", {})
	var modeMetrics: Dictionary = questionRecord.get("modeMetrics", {})
	var firstActionTimeMs: int = questionRecord.get("firstActionTimeMs", -1)
	var totalSolveTimeMs: int = questionRecord.get("totalSolveTimeMs", -1)

	# Shared patterns apply consistently across all gameplay modes.
	if firstActionTimeMs >= FIRST_ACTION_HESITATION_MS:
		detectedPatterns.append("first_action_hesitation")
	if totalSolveTimeMs >= LONG_SOLVE_TIME_MS:
		detectedPatterns.append("long_solve_time")
	if int(sharedMetrics.get("incorrectAttempts", 0)) >= REPEATED_INCORRECT_ATTEMPTS:
		detectedPatterns.append("repeated_incorrect_attempts")
	if int(sharedMetrics.get("hintUses", 0)) >= REPEATED_HINT_USES:
		detectedPatterns.append("repeated_hint_use")
	if int(sharedMetrics.get("checkSubmissions", 0)) >= REPEATED_CHECK_SUBMISSIONS:
		detectedPatterns.append("repeated_submissions")

	# Mode-specific patterns use only the interaction data relevant to that mode.
	var stepMetrics: Dictionary = modeMetrics.get("stepOrdering", {})
	if int(stepMetrics.get("reorderMoves", 0)) >= EXCESSIVE_REORDER_MOVES:
		detectedPatterns.append("excessive_reordering")

	var fillMetrics: Dictionary = modeMetrics.get("fillInProcess", {})
	var fillRevisionCount := maxi(
		0,
		int(fillMetrics.get("valueEdits", 0)) - int(fillMetrics.get("editedBlankCount", 0))
	)
	if fillRevisionCount >= EXCESSIVE_FILL_REVISIONS:
		detectedPatterns.append("excessive_fill_revision")

	var analysis := {
		"patterns": detectedPatterns,
		"primaryPattern": GetHighestPriorityPattern(detectedPatterns)
	}

	if ENABLE_CONSOLE_OUTPUT:
		print("[M5 Behavior Patterns] ", JSON.stringify(analysis))

	return analysis

# Selects one stable primary pattern using priority and explicit tie ordering.
func GetHighestPriorityPattern(detectedPatterns: Array[String]) -> String:
	var selectedPattern := ""
	var selectedPriority := -1

	for patternId in PATTERN_TIE_BREAK_ORDER:
		if patternId not in detectedPatterns:
			continue

		var patternPriority: int = PATTERN_PRIORITIES.get(patternId, 0)
		if patternPriority > selectedPriority:
			selectedPattern = patternId
			selectedPriority = patternPriority

	return selectedPattern

#endregion
