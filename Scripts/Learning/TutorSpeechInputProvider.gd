## Defines the optional speech-to-text contract used by M8 Tutor Chat.
##
## Providers only return editable transcript text. They never send a Tutor
## message, interpret learning intent, or run continuously in the background.
extends RefCounted

#region ========== Functions ==========

# Returns a stable provider identifier for UI state and diagnostics.
func GetProviderId() -> String:
	return "unavailable"

# Reports whether this runtime can explicitly start speech recognition.
func IsSupported() -> bool:
	return false

# Begins one player-requested listening session.
func StartListening(_languageCode: String) -> Dictionary:
	return BuildState("error", "", "unsupported")

# Ends the current session and allows a provider to finalize its transcript.
func StopListening() -> Dictionary:
	return BuildState("error", "", "unsupported")

# Returns the latest normalized provider state without blocking gameplay.
func Poll() -> Dictionary:
	return BuildState("idle")

# Creates the shared state contract consumed by TutorPanel.
func BuildState(
	status: String,
	transcript: String = "",
	errorCode: String = ""
) -> Dictionary:
	return {
		"providerId": GetProviderId(),
		"status": status,
		"transcript": transcript,
		"errorCode": errorCode
	}

#endregion
