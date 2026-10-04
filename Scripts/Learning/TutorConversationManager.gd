## Stores lightweight M8 conversation turns for only the current app session.
##
## Conversation memory is never saved and resets when the Course Source changes.
extends RefCounted

#region ========== Constants ==========

const MAX_MESSAGE_COUNT: int = 12
const VALID_ROLES: Array[String] = ["player", "tutor"]

#endregion

#region ========== Variables ==========

var activeCourseSourceId: String = ""
var messages: Array[Dictionary] = []

#endregion

#region ========== Functions ==========

# Resets transient memory when a request crosses a Course Source boundary.
func EnsureCourseScope(courseSourceId: String) -> void:
	if activeCourseSourceId == courseSourceId:
		return
	activeCourseSourceId = courseSourceId
	messages.clear()

# Adds one concise turn while enforcing the centralized memory limit.
func AddMessage(role: String, content: String) -> void:
	if role not in VALID_ROLES or content.strip_edges().is_empty():
		return
	messages.append({
		"role": role,
		"content": content.strip_edges()
	})
	while messages.size() > MAX_MESSAGE_COUNT:
		messages.pop_front()

# Returns an immutable copy suitable for a provider request.
func GetConversation() -> Array[Dictionary]:
	return messages.duplicate(true)

# Returns the current number of retained player and Tutor messages.
func GetMessageCount() -> int:
	return messages.size()

# Clears the current conversation without changing saved learning data.
func ClearConversation() -> void:
	messages.clear()

#endregion
