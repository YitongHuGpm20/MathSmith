## Coordinates M8 context, transient conversation, and swappable AI providers.
##
## Existing M7 pages remain the fallback and no provider can mutate gameplay.
extends RefCounted

#region ========== References ==========

var contextBuilder := preload("res://Scripts/Learning/TutorAIContextBuilder.gd").new()
var actionValidator := preload("res://Scripts/Learning/TutorActionValidator.gd").new()
var conversationManager := preload(
	"res://Scripts/Learning/TutorConversationManager.gd"
).new()
var provider = preload("res://Scripts/Learning/MockTutorAIProvider.gd").new()

#endregion

#region ========== Variables ==========

var aiEnabled: bool = true
var lastRequestState: String = "idle"
var lastIntent: String = "OTHER"
var lastSuggestedActionId: String = ""
var lastFallbackUsed: bool = false
var lastResponseLatencyMs: int = 0

#endregion

#region ========== Functions ==========

# Enables optional conversation without affecting deterministic Guided Tutor.
func SetEnabled(isEnabled: bool) -> void:
	aiEnabled = isEnabled
	if not aiEnabled:
		lastRequestState = "disabled"
	elif lastRequestState == "disabled":
		lastRequestState = "idle"

# Builds the approved provider payload and enforces conversation Course scope.
func BuildAIContext(
	tutorContext: Dictionary,
	requestIntent: String,
	availableActions: Array,
	languageCode: String
) -> Dictionary:
	var aiContext := contextBuilder.BuildContext(
		tutorContext,
		requestIntent,
		availableActions,
		languageCode
	)
	conversationManager.EnsureCourseScope(
		aiContext.get("courseSource", {}).get("sourceId", "")
	)
	return aiContext

# Exercises the provider contract while returning the untouched M7 fallback page.
func RequestResponse(
	aiContext: Dictionary,
	userMessage: String,
	fallbackPage: Dictionary
) -> Dictionary:
	var requestStartedMs := Time.get_ticks_msec()
	lastIntent = aiContext.get("requestIntent", "OTHER")
	lastSuggestedActionId = ""
	lastFallbackUsed = false
	lastRequestState = "requesting"
	var normalizedMessage := userMessage.strip_edges()
	if not aiEnabled:
		return CompleteFallback(requestStartedMs, fallbackPage, "ai_disabled")
	if normalizedMessage.is_empty() or not provider.IsAvailable():
		return CompleteFallback(requestStartedMs, fallbackPage, "provider_unavailable")

	conversationManager.AddMessage("player", normalizedMessage)
	var providerResult: Dictionary = provider.RequestResponse(
		aiContext,
		conversationManager.GetConversation(),
		normalizedMessage
	)
	if not IsValidProviderResult(providerResult):
		return CompleteFallback(requestStartedMs, fallbackPage, "invalid_response")

	# Replace all provider action data with MathSmith's trusted action contract.
	var actionValidation := actionValidator.ValidateSuggestedAction(
		providerResult.get("suggestedAction", {}),
		aiContext.get("availableActions", [])
	)
	providerResult["suggestedAction"] = actionValidation.get("action", {})
	providerResult["actionRejected"] = not actionValidation.get("valid", false)
	providerResult["actionRejectionReason"] = actionValidation.get("rejectionReason", "")

	conversationManager.AddMessage("tutor", providerResult.get("tutorText", ""))
	providerResult["fallbackPage"] = fallbackPage.duplicate(true)
	providerResult["conversationMessageCount"] = conversationManager.GetMessageCount()
	lastSuggestedActionId = providerResult.get("suggestedAction", {}).get("actionId", "")
	lastRequestState = "ready"
	lastResponseLatencyMs = Time.get_ticks_msec() - requestStartedMs
	return providerResult

# Extracts the current executable action surface from deterministic M7 pages.
func GetAvailableActions(fallbackPage: Dictionary) -> Array[Dictionary]:
	return actionValidator.GetAvailableActions(fallbackPage)

# Exposes non-secret architecture state for manual M8.1 validation.
func GetStatus() -> Dictionary:
	return {
		"aiEnabled": aiEnabled,
		"providerId": provider.GetProviderId(),
		"providerAvailable": provider.IsAvailable(),
		"developmentOnly": provider.GetProviderId() == "mock_development",
		"conversationMessageCount": conversationManager.GetMessageCount(),
		"fallback": "m7_deterministic_tutor",
		"requestState": lastRequestState,
		"detectedIntent": lastIntent,
		"suggestedActionId": lastSuggestedActionId,
		"fallbackActive": lastFallbackUsed,
		"responseLatencyMs": lastResponseLatencyMs
	}

# Records one safe fallback result for the developer overlay.
func CompleteFallback(
	requestStartedMs: int,
	fallbackPage: Dictionary,
	errorCode: String
) -> Dictionary:
	lastRequestState = "fallback"
	lastFallbackUsed = true
	lastResponseLatencyMs = Time.get_ticks_msec() - requestStartedMs
	return BuildFallbackResult(provider.GetProviderId(), fallbackPage, errorCode)

# Clears only transient AI conversation memory.
func ClearConversation() -> void:
	conversationManager.ClearConversation()
	lastRequestState = "idle" if aiEnabled else "disabled"
	lastIntent = "OTHER"
	lastSuggestedActionId = ""
	lastFallbackUsed = false
	lastResponseLatencyMs = 0

# Requires a small stable response contract before UI may consume provider data.
func IsValidProviderResult(providerResult: Dictionary) -> bool:
	return (
		providerResult.get("success", false)
		and providerResult.get("tutorText", "") is String
		and not String(providerResult.get("tutorText", "")).strip_edges().is_empty()
		and providerResult.get("suggestedAction", {}) is Dictionary
	)

# Preserves the complete deterministic M7 page when conversational AI fails.
func BuildFallbackResult(
	providerId: String,
	fallbackPage: Dictionary,
	errorCode: String
) -> Dictionary:
	return {
		"success": false,
		"providerId": providerId,
		"tutorText": "",
		"intent": "OTHER",
		"suggestedAction": {},
		"fallbackRequired": true,
		"fallbackPage": fallbackPage.duplicate(true),
		"errorCode": errorCode,
		"conversationMessageCount": conversationManager.GetMessageCount()
	}

#endregion
