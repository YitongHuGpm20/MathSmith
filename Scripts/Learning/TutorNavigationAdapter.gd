## Parses stable Tutor action IDs into existing MathSmith navigation commands.
##
## This adapter never changes scenes or learning state. GameManager remains the
## single owner that executes the returned command through existing functions.
extends RefCounted

#region ========== Functions ==========

# Converts one option action into a normalized command and optional target.
func ParseAction(actionId: String) -> Dictionary:
	var separatorIndex: int = actionId.find(":")
	if separatorIndex < 0:
		return {"command": actionId, "target": ""}
	return {
		"command": actionId.left(separatorIndex),
		"target": actionId.substr(separatorIndex + 1)
	}

#endregion
