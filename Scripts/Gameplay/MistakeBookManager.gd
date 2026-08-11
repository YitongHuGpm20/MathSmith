## Manages persistent Mistake Book entries and deterministic explanations.
##
## GameManager supplies current Question context. This service handles entry
## deduplication, rule classification, explanation text, and Local Save writes.
extends RefCounted

#region ========== Functions ==========

# Returns an isolated copy of every saved mistake entry.
func GetEntries() -> Array:
	var savedEntries = SaveManager.GetSection("mistakeBook")
	return savedEntries if savedEntries is Array else []

# Adds or updates one Question without duplicating its mode-specific entry.
func RecordQuestion(questionContext: Dictionary) -> void:
	var entryKey := "%s:%s:%s" % [
		questionContext.get("levelTypeId", ""),
		questionContext.get("levelId", ""),
		questionContext.get("questionId", "")
	]
	var mistakeEntries := GetEntries()
	var entryIndex := -1

	for savedIndex in range(mistakeEntries.size()):
		if mistakeEntries[savedIndex].get("entryKey", "") == entryKey:
			entryIndex = savedIndex
			break

	var existingEntry: Dictionary = mistakeEntries[entryIndex] if entryIndex >= 0 else {}
	var expression: String = questionContext.get("expression", "")
	var mistakeEntry := questionContext.duplicate(true)
	mistakeEntry["entryKey"] = entryKey
	mistakeEntry["incorrectAttempts"] = maxi(
		existingEntry.get("incorrectAttempts", 0),
		questionContext.get("incorrectAttempts", 0)
	)
	mistakeEntry["hintUsed"] = (
		existingEntry.get("hintUsed", false)
		or questionContext.get("hintUsed", false)
	)
	mistakeEntry["errorCategory"] = GetMistakeCategory(expression)
	mistakeEntry["explanation"] = GetMistakeExplanation(expression)
	mistakeEntry["updatedAt"] = int(Time.get_unix_time_from_system())

	if entryIndex >= 0:
		mistakeEntries[entryIndex] = mistakeEntry
	else:
		mistakeEntries.push_front(mistakeEntry)

	SaveManager.SetSection("mistakeBook", mistakeEntries)

# Removes one saved mistake by its stable mode, Level, and Question key.
func RemoveEntry(entryKey: String) -> void:
	var mistakeEntries := GetEntries()

	for entryIndex in range(mistakeEntries.size() - 1, -1, -1):
		if mistakeEntries[entryIndex].get("entryKey", "") == entryKey:
			mistakeEntries.remove_at(entryIndex)

	SaveManager.SetSection("mistakeBook", mistakeEntries)

# Classifies the mathematical rule used by a saved deterministic explanation.
func GetMistakeCategory(expression: String) -> String:
	if "(" in expression:
		return "Parentheses"
	if ExpressionHasMixedPrecedence(expression):
		return "Order of Operations"
	if "/" in expression:
		return "Division"
	if "*" in expression:
		return "Multiplication"
	if "-" in expression:
		return "Subtraction"
	return "Addition and Regrouping"

# Returns a rule explanation without generating any new answer content.
func GetMistakeExplanation(expression: String) -> String:
	if "(" in expression:
		return "Resolve the operations inside parentheses before the surrounding operation. Each transformation must preserve the expression's value."
	if ExpressionHasMixedPrecedence(expression):
		return "Resolve multiplication and division before addition and subtraction, working from left to right within the same priority."
	if "/" in expression:
		return "When decomposing division, split the dividend into parts that are each divisible by the divisor."
	if "*" in expression:
		return "Decompose a factor into useful parts, calculate each partial product, and then combine the partial products."
	if "-" in expression:
		return "Decompose the amount being subtracted into manageable parts while preserving the original difference."
	return "Decompose and regroup the addends to make friendly totals while preserving the original sum."

# Detects whether precedence between high- and low-priority operations applies.
func ExpressionHasMixedPrecedence(expression: String) -> bool:
	var hasHigherPriorityOperation := "*" in expression or "/" in expression
	var hasLowerPriorityOperation := "+" in expression or "-" in expression
	return hasHigherPriorityOperation and hasLowerPriorityOperation

#endregion
