## Supplies deterministic development responses for the M8 provider contract.
##
## This provider performs no networking and does not imitate mathematical AI.
## It exists only for architecture, context, and fallback validation.
extends "res://Scripts/Learning/TutorAIProvider.gd"

#region ========== Constants ==========

const MOCK_PROVIDER_ID: String = "mock_development"

#endregion

#region ========== Functions ==========

# Identifies this provider as an explicit development-only implementation.
func GetProviderId() -> String:
	return MOCK_PROVIDER_ID

# Keeps the deterministic provider available without network configuration.
func IsAvailable() -> bool:
	return true

# Confirms receipt of safe context without generating or validating mathematics.
func RequestResponse(
	aiContext: Dictionary,
	_conversation: Array,
	userMessage: String
) -> Dictionary:
	var screenId: String = aiContext.get("screen", {}).get("id", "unknown")
	var useChinese: bool = String(aiContext.get("language", "en")).begins_with("zh")
	var suggestedAction: Dictionary = {}
	var responseIntent: String = aiContext.get("requestIntent", "OTHER")
	var tutorText := (
		"开发用模拟导师已收到经过筛选的情境：" + screenId
		if useChinese
		else "Mock Tutor received the approved context for: " + screenId
	)

	# Explicit development commands test validation without imitating language AI.
	if userMessage == "/mock-action":
		var availableActions: Array = aiContext.get("availableActions", [])
		if not availableActions.is_empty():
			suggestedAction = availableActions[0].duplicate(true)
			responseIntent = "NAVIGATION"
		tutorText = (
			"开发用模拟导师从已批准的操作列表中提出了一项操作。"
			if useChinese
			else "Mock Tutor proposed one action from the approved action list."
		)
	elif userMessage == "/mock-invalid-action":
		suggestedAction = {
			"actionId": "delete_all_player_data",
			"label": "Untrusted Action"
		}
		responseIntent = "NAVIGATION"
		tutorText = (
			"开发用模拟导师返回了一项故意设置为无效的操作，用于验证安全检查。"
			if useChinese
			else "Mock Tutor returned an intentionally invalid action for validation."
		)
	return {
		"success": true,
		"providerId": GetProviderId(),
		"tutorText": tutorText,
		"intent": responseIntent,
		"suggestedAction": suggestedAction,
		"fallbackRequired": false,
		"errorCode": "",
		"developmentOnly": true
	}

#endregion
