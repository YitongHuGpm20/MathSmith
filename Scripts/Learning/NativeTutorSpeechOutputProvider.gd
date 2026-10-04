## Uses Godot's platform text-to-speech interface for Tutor response playback.
extends "res://Scripts/Learning/TutorSpeechOutputProvider.gd"

#region ========== Functions ==========

# Identifies the system voice implementation.
func GetProviderId() -> String:
	return "godot_system_tts"

# Checks Godot's platform feature before exposing speech controls.
func IsSupported() -> bool:
	return DisplayServer.has_feature(DisplayServer.FEATURE_TEXT_TO_SPEECH)

# Speaks one visible Tutor response using a matching installed system voice.
func Speak(text: String, languageCode: String) -> Dictionary:
	if not IsSupported() or text.strip_edges().is_empty():
		return BuildState(false, "unsupported")
	var voiceLanguage := "zh" if languageCode.begins_with("zh") else "en"
	var voiceIds := DisplayServer.tts_get_voices_for_language(voiceLanguage)
	if voiceIds.is_empty():
		return BuildState(false, "voice_unavailable")
	DisplayServer.tts_stop()
	DisplayServer.tts_speak(text, voiceIds[0], 60, 1.0, 1.0, 1, true)
	return BuildState(true)

# Stops the current system utterance immediately.
func Stop() -> void:
	if IsSupported():
		DisplayServer.tts_stop()

# Mirrors system speech state for predictable button reset.
func IsSpeaking() -> bool:
	return IsSupported() and DisplayServer.tts_is_speaking()

#endregion
