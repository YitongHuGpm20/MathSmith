## Defines the optional text-to-speech contract for M8 Tutor responses.
##
## Speech is supplementary. Provider failure never removes visible Tutor text.
extends RefCounted

#region ========== Functions ==========

# Returns a stable provider identifier for diagnostics.
func GetProviderId() -> String:
	return "unavailable"

# Reports whether speech output is available on this runtime.
func IsSupported() -> bool:
	return false

# Starts one explicit utterance and returns normalized state.
func Speak(_text: String, _languageCode: String) -> Dictionary:
	return BuildState(false, "unsupported")

# Stops the active utterance without affecting visible text.
func Stop() -> void:
	pass

# Reports whether an utterance is still active.
func IsSpeaking() -> bool:
	return false

# Creates the stable result consumed by TutorPanel.
func BuildState(success: bool, errorCode: String = "") -> Dictionary:
	return {
		"providerId": GetProviderId(),
		"success": success,
		"errorCode": errorCode
	}

#endregion
