## Validates optional AI action proposals against current deterministic M7 UI.
##
## Providers may suggest an action, but only MathSmith decides whether it is
## currently available and which trusted action ID and label the UI receives.
extends RefCounted

#region ========== Constants ==========

const EXECUTABLE_COMMANDS: Array[String] = [
	"open_home",
	"open_course_selection",
	"open_lobby",
	"open_mistake_book",
	"open_skill_mastery",
	"start_level",
	"start_adaptive_practice",
	"start_mistake_practice",
	"start_zen",
	"start_survival",
	"open_tutorial",
	"open_settings"
]

#endregion

#region ========== Functions ==========

# Collects executable actions exposed anywhere in the current M7 page tree.
func GetAvailableActions(pageData: Dictionary) -> Array[Dictionary]:
	var actionsById: Dictionary = {}
	CollectPageActions(pageData, actionsById)
	var availableActions: Array[Dictionary] = []
	for actionValue in actionsById.values():
		availableActions.append(actionValue)
	return availableActions

# Accepts only an exact action ID from the context supplied to the provider.
func ValidateSuggestedAction(
	proposedActionValue: Variant,
	availableActionsValue: Variant
) -> Dictionary:
	var proposedAction: Dictionary = (
		proposedActionValue if proposedActionValue is Dictionary else {}
	)
	var proposedActionId: String = proposedAction.get("actionId", "")
	var availableActions: Array = (
		availableActionsValue if availableActionsValue is Array else []
	)
	if proposedActionId.is_empty():
		return {"valid": true, "action": {}, "rejectionReason": ""}

	for availableActionValue in availableActions:
		if not availableActionValue is Dictionary:
			continue
		var availableAction: Dictionary = availableActionValue
		if availableAction.get("actionId", "") == proposedActionId:
			return {
				"valid": true,
				"action": availableAction.duplicate(true),
				"rejectionReason": ""
			}
	return {
		"valid": false,
		"action": {},
		"rejectionReason": "action_not_available_in_current_context"
	}

# Traverses deterministic next pages while excluding explanation-only actions.
func CollectPageActions(pageData: Dictionary, actionsById: Dictionary) -> void:
	var options: Array = pageData.get("options", [])
	for optionValue in options:
		if not optionValue is Dictionary:
			continue
		var option: Dictionary = optionValue
		var actionId: String = option.get("actionId", "")
		if IsExecutableAction(actionId):
			actionsById[actionId] = {
				"actionId": actionId,
				"label": option.get("label", "Continue")
			}
		var nextPage: Dictionary = option.get("nextPage", {})
		if not nextPage.is_empty():
			CollectPageActions(nextPage, actionsById)

# Matches GameManager's existing Tutor command surface without executing it.
func IsExecutableAction(actionId: String) -> bool:
	var separatorIndex := actionId.find(":")
	var command := actionId if separatorIndex < 0 else actionId.left(separatorIndex)
	return command in EXECUTABLE_COMMANDS

#endregion
