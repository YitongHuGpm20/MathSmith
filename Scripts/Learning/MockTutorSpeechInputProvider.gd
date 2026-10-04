## Provides explicit Push-to-Talk simulation for desktop editor validation.
##
## This development provider never accesses a microphone or network service.
extends "res://Scripts/Learning/TutorSpeechInputProvider.gd"

#region ========== Variables ==========

var listening: bool = false

#endregion

#region ========== Functions ==========

# Identifies the transcript as development-only mock input.
func GetProviderId() -> String:
	return "mock_speech_input"

# Keeps the Push-to-Talk UI testable in non-Web debug builds.
func IsSupported() -> bool:
	return true

# Enters a deterministic listening state after explicit player input.
func StartListening(_languageCode: String) -> Dictionary:
	listening = true
	return BuildState("listening")

# Produces editable sample text only when the player explicitly stops.
func StopListening() -> Dictionary:
	if not listening:
		return BuildState("error", "", "not_listening")
	listening = false
	return BuildState("transcript", "Explain this problem.")

# Reports the current simulated listening state.
func Poll() -> Dictionary:
	return BuildState("listening" if listening else "idle")

#endregion
