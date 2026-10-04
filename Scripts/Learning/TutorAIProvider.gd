## Defines the stable provider contract for MathSmith's optional AI Tutor layer.
##
## Providers receive only an approved AI context snapshot and may shape wording.
## They never determine mathematical truth, progression, or player learning state.
extends RefCounted

#region ========== Constants ==========

const PROVIDER_ID: String = "unavailable"

#endregion

#region ========== Functions ==========

# Returns the stable identifier used by diagnostics and future configuration.
func GetProviderId() -> String:
	return PROVIDER_ID

# Reports whether this provider can currently accept a request.
func IsAvailable() -> bool:
	return false

# Returns a normalized unavailable result for providers without an implementation.
func RequestResponse(
	_aiContext: Dictionary,
	_conversation: Array,
	_userMessage: String
) -> Dictionary:
	return {
		"success": false,
		"providerId": GetProviderId(),
		"tutorText": "",
		"intent": "OTHER",
		"suggestedAction": {},
		"fallbackRequired": true,
		"errorCode": "provider_unavailable",
		"developmentOnly": false
	}

#endregion
