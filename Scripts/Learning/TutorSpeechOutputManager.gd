## Coordinates optional Tutor speech output without changing response content.
extends RefCounted

#region ========== References ==========

var provider := preload(
	"res://Scripts/Learning/NativeTutorSpeechOutputProvider.gd"
).new()

#endregion

#region ========== Functions ==========

# Returns non-sensitive platform support information.
func GetStatus() -> Dictionary:
	return {
		"providerId": provider.GetProviderId(),
		"supported": provider.IsSupported(),
		"speaking": provider.IsSpeaking()
	}

# Interrupts any prior utterance and speaks one already-visible response.
func Speak(text: String, languageCode: String) -> Dictionary:
	provider.Stop()
	return provider.Speak(text, languageCode)

# Stops speech without changing Chat content.
func Stop() -> void:
	provider.Stop()

# Reports completion so UI playback state can reset.
func IsSpeaking() -> bool:
	return provider.IsSpeaking()

#endregion
