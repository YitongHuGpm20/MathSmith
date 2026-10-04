## Evaluates conservative deterministic triggers for proactive Tutor notices.
##
## This service decides only WHEN a notice is allowed. It does not generate
## mathematics, open Tutor, interrupt gameplay, or execute any action.
extends RefCounted

#region ========== Constants ==========

const INACTIVITY_THRESHOLD_SECONDS: float = 18.0
const GLOBAL_COOLDOWN_SECONDS: float = 75.0
const REPEATED_INCORRECT_ATTEMPTS: int = 2
const MAX_NOTICES_PER_QUESTION: int = 1

#endregion

#region ========== Variables ==========

var proactiveEnabled: bool = true
var activeQuestionKey: String = ""
var inactivitySeconds: float = 0.0
var globalCooldownSeconds: float = 0.0
var questionNoticeCount: int = 0
var lastTriggerId: String = ""
var noticeActive: bool = false

#endregion

#region ========== Functions ==========

# Applies the player preference and dismisses any stale notice when disabled.
func SetEnabled(isEnabled: bool) -> void:
	proactiveEnabled = isEnabled
	if not proactiveEnabled:
		noticeActive = false
		inactivitySeconds = 0.0

# Starts a fresh per-Question allowance without bypassing the global cooldown.
func BeginQuestion(questionKey: String) -> void:
	activeQuestionKey = questionKey
	inactivitySeconds = 0.0
	questionNoticeCount = 0
	lastTriggerId = ""
	noticeActive = false

# Resets inactivity whenever the player interacts with the current Question.
func RecordPlayerActivity() -> void:
	inactivitySeconds = 0.0
	noticeActive = false

# Evaluates repeated mistakes using the existing gameplay-owned attempt count.
func RecordIncorrectAttempt(incorrectAttemptCount: int) -> Dictionary:
	RecordPlayerActivity()
	if incorrectAttemptCount < REPEATED_INCORRECT_ATTEMPTS:
		return {}
	return TryCreateNotice("repeated_incorrect_attempts")

# Advances centralized timers and returns at most one non-blocking notice.
func Advance(delta: float, canInterrupt: bool) -> Dictionary:
	globalCooldownSeconds = maxf(0.0, globalCooldownSeconds - delta)
	if not proactiveEnabled or not canInterrupt or activeQuestionKey.is_empty():
		return {}
	inactivitySeconds += delta
	if inactivitySeconds < INACTIVITY_THRESHOLD_SECONDS:
		return {}
	return TryCreateNotice("inactivity")

# Records one permitted trigger and starts the shared cooldown.
func TryCreateNotice(triggerId: String) -> Dictionary:
	if (
		not proactiveEnabled
		or questionNoticeCount >= MAX_NOTICES_PER_QUESTION
		or globalCooldownSeconds > 0.0
	):
		return {}
	questionNoticeCount += 1
	globalCooldownSeconds = GLOBAL_COOLDOWN_SECONDS
	inactivitySeconds = 0.0
	lastTriggerId = triggerId
	noticeActive = true
	return {
		"state": "NOTICE",
		"triggerId": triggerId,
		"message": "Need a hand?"
	}

# Marks explicit Tutor engagement without opening anything automatically.
func RecordTutorEngagement() -> void:
	RecordPlayerActivity()

# Exposes non-sensitive trigger state for later developer diagnostics.
func GetStatus() -> Dictionary:
	return {
		"enabled": proactiveEnabled,
		"state": "NOTICE" if noticeActive else "IDLE",
		"activeQuestionKey": activeQuestionKey,
		"questionNoticeCount": questionNoticeCount,
		"inactivitySeconds": inactivitySeconds,
		"cooldownRemainingSeconds": globalCooldownSeconds,
		"lastTriggerId": lastTriggerId
	}

#endregion
