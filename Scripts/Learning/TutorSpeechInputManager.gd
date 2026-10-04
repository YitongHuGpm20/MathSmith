## Selects and normalizes the optional M8 speech-input provider.
extends RefCounted

#region ========== References ==========

var provider = (
	preload("res://Scripts/Learning/WebTutorSpeechInputProvider.gd").new()
	if OS.has_feature("web")
	else preload("res://Scripts/Learning/MockTutorSpeechInputProvider.gd").new()
)

#endregion

#region ========== Functions ==========

# Exposes the selected provider without any secret or microphone state.
func GetStatus() -> Dictionary:
	return {
		"providerId": provider.GetProviderId(),
		"supported": provider.IsSupported(),
		"developmentOnly": provider.GetProviderId() == "mock_speech_input"
	}

# Begins explicit Push-to-Talk in the current MathSmith language.
func StartListening(languageCode: String) -> Dictionary:
	return provider.StartListening(languageCode)

# Ends explicit Push-to-Talk without automatically sending the transcript.
func StopListening() -> Dictionary:
	return provider.StopListening()

# Polls a provider only while TutorPanel has an active voice session.
func Poll() -> Dictionary:
	return provider.Poll()

#endregion
