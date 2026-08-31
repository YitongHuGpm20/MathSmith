## Builds centralized deterministic Tutor response templates.
##
## Templates consume validated Tutor Context values and existing tutorial text.
## They never calculate answers, scores, Mastery, or adaptive weights.
extends RefCounted

#region ========== Functions ==========

# Builds the active mode explanation from the existing Tutorial definition.
func BuildGameplayRulePage(tutorContext: Dictionary) -> Dictionary:
	var gameplay: Dictionary = tutorContext.get("gameplay", {})
	var tutorial: Dictionary = gameplay.get("tutorial", {})
	var tutorialKey: String = tutorial.get("instructions", "")
	var tutorialText: String = String(
		TranslationServer.translate(tutorialKey)
	).replace("\\n", "\n")
	return {
		"contextLabel": "GAMEPLAY",
		"title": tutorial.get("title", "Gameplay Mode"),
		"response": tutorialText,
		"options": []
	}

# Explains only Score deductions and results recorded by existing gameplay state.
func BuildScoringRulePage(tutorContext: Dictionary) -> Dictionary:
	var gameplay: Dictionary = tutorContext.get("gameplay", {})
	var session: Dictionary = tutorContext.get("session", {})
	var summary: Dictionary = session.get("summary", {})
	var startingScore: int = gameplay.get("startingQuestionScore", 100)
	var currentScore: int = gameplay.get("questionScore", startingScore)
	var hintsUsed: int = gameplay.get("questionHintsUsed", 0)
	var incorrectAttempts: int = gameplay.get("questionIncorrectAttempts", 0)
	var actualHintPenalty: int = gameplay.get("actualHintPenalty", 0)
	var actualIncorrectPenalty: int = gameplay.get("actualIncorrectPenalty", 0)
	var scoreLines := PackedStringArray()
	scoreLines.append(T("This Question started with %d points.") % startingScore)
	if actualHintPenalty > 0:
		scoreLines.append(T("- %d Hint use(s): -%d") % [
			hintsUsed,
			actualHintPenalty
		])
	if incorrectAttempts > 0:
		scoreLines.append(T("- The first incorrect attempt: no Score penalty"))
	if actualIncorrectPenalty > 0:
		scoreLines.append(T("- Repeated incorrect attempts: -%d") % actualIncorrectPenalty)
	if actualHintPenalty == 0 and actualIncorrectPenalty == 0:
		scoreLines.append(T("- No points have been deducted from this Question."))
	scoreLines.append(T("Current Question Score: %d") % currentScore)

	if not summary.is_empty() and summary.has("maxScore"):
		scoreLines.append("")
		scoreLines.append(T("Level Score: %d / %d") % [
			int(summary.get("score", 0)),
			int(summary.get("maxScore", 0))
		])
		scoreLines.append(T("Final percentage: %d%%") % int(summary.get("percentage", 0)))
		if summary.has("stars"):
			scoreLines.append(T("Star rating: %d / 3") % int(summary.get("stars", 0)))
	return {
		"contextLabel": "SCORE BREAKDOWN",
		"title": "Why This Score?",
		"response": "\n".join(scoreLines),
		"options": []
	}

# Summarizes only fields supplied by the completed session's existing result.
func BuildPerformanceSummaryPage(tutorContext: Dictionary) -> Dictionary:
	var summary: Dictionary = tutorContext.get("session", {}).get("summary", {})
	var summaryLines := PackedStringArray()
	var title: String = summary.get("levelTitle", "Session Performance")
	if summary.get("isZenSession", false):
		title = "Zen Mode"
		summaryLines.append(T("Questions solved: %d") % int(summary.get("solvedCount", 0)))
		summaryLines.append(T("Accuracy: %d%%") % int(summary.get("accuracy", 0)))
		summaryLines.append(T("Best solved count: %d") % int(summary.get("bestSolvedCount", 0)))
	elif summary.get("isSurvivalSession", false):
		title = "Survival Mode"
		summaryLines.append(T("Questions solved: %d") % int(summary.get("solvedCount", 0)))
		summaryLines.append(T("Incorrect attempts: %d") % int(summary.get("incorrectAttempts", 0)))
		summaryLines.append(T("Best solved count: %d") % int(summary.get("bestSolvedCount", 0)))
	else:
		summaryLines.append(T("Questions completed: %d / %d") % [
			int(summary.get("questionsCompleted", 0)),
			int(summary.get("questionCount", 0))
		])
		summaryLines.append(T("Score: %d / %d") % [
			int(summary.get("score", 0)),
			int(summary.get("maxScore", 0))
		])
		summaryLines.append(T("Final percentage: %d%%") % int(summary.get("percentage", 0)))
		summaryLines.append(T("Incorrect attempts: %d") % int(summary.get("incorrectAttempts", 0)))
		summaryLines.append(T("Hints used: %d") % int(summary.get("hintsUsed", 0)))
		if (
			summary.has("stars")
			and not summary.get("isPracticeSession", false)
			and not summary.get("isTeacherPreview", false)
		):
			summaryLines.append(T("Stars: %d / 3") % int(summary.get("stars", 0)))
	if summary.get("isNewBest", false):
		summaryLines.append(T("New best result"))
	return {
		"contextLabel": "PERFORMANCE SUMMARY",
		"title": title,
		"response": "\n".join(summaryLines),
		"options": []
	}

# Explains the stored Star result without recalculating or changing its rating.
func BuildStarRatingPage(tutorContext: Dictionary) -> Dictionary:
	var summary: Dictionary = tutorContext.get("session", {}).get("summary", {})
	return {
		"contextLabel": "STAR RESULT",
		"title": T("%d of 3 Stars") % int(summary.get("stars", 0)),
		"response": T("Your Level finished at %d%% with a Score of %d / %d. MathSmith used that final percentage to produce the displayed %d-Star result.") % [
			int(summary.get("percentage", 0)),
			int(summary.get("score", 0)),
			int(summary.get("maxScore", 0)),
			int(summary.get("stars", 0))
		],
		"options": []
	}

# Presents up to three existing M5 weak-Skill results without reclassifying them.
func BuildWeakSkillRecommendationPage(tutorContext: Dictionary) -> Dictionary:
	var courseName: String = tutorContext.get("course", {}).get(
		"displayName",
		"Current Course"
	)
	var learning: Dictionary = tutorContext.get("learning", {})
	var skillProgress: Dictionary = learning.get("skillProgress", {})
	var weakSkills: Array = learning.get("weakSkills", [])
	var levelRecommendations: Array = learning.get("recommendations", [])
	if skillProgress.is_empty():
		return BuildNotEnoughDataPage(courseName)
	if weakSkills.is_empty():
		return {
			"contextLabel": courseName.to_upper(),
			"title": "No Weak Skill Identified",
			"response": "The current M5 analysis does not identify a weak Skill in this Course. Continue playing so the evidence can stay current.",
			"options": []
		}

	var recommendationLines := PackedStringArray()
	var recommendationOptions: Array[Dictionary] = []
	var recommendationCount: int = mini(3, weakSkills.size())
	for weakSkillIndex in range(recommendationCount):
		var skillId: String = String(weakSkills[weakSkillIndex])
		var skillSummary: Dictionary = skillProgress.get(skillId, {})
		var relevantLevelName: String = GetFirstRecommendedLevelForSkill(
			skillId,
			levelRecommendations
		)
		if not recommendationLines.is_empty():
			recommendationLines.append("")
		recommendationLines.append(T("%d. %s - %d%% Mastery") % [
			weakSkillIndex + 1,
			FormatSkillName(skillId),
			int(skillSummary.get("masteryScore", 0))
		])
		recommendationLines.append(T("Why:"))
		recommendationLines.append(T("- Identified by the existing M5 weak-Skill analysis"))
		recommendationLines.append(T("- %d completed Questions, %d Hints, %d incorrect attempts") % [
			int(skillSummary.get("completedCount", 0)),
			int(skillSummary.get("totalHintsUsed", 0)),
			int(skillSummary.get("totalIncorrectAttempts", 0))
		])
		recommendationLines.append(T("Suggested:"))
		if relevantLevelName.is_empty():
			recommendationLines.append(T("- Practice content tagged with this Skill"))
		else:
			recommendationLines.append("- %s" % T(relevantLevelName))
			AppendLevelPracticeOption(
				recommendationOptions,
				skillId,
				levelRecommendations
			)

	return {
		"contextLabel": courseName.to_upper(),
		"title": "Weak Skill Recommendations",
		"response": "\n".join(recommendationLines),
		"options": recommendationOptions
	}

# Uses the shared insufficient-evidence wording without forcing a recommendation.
func BuildNotEnoughDataPage(courseName: String) -> Dictionary:
	return {
		"contextLabel": courseName.to_upper(),
		"title": "Not Enough Data Yet",
		"response": "Complete a few more Questions in this Course so MathSmith can identify stronger and weaker Skills.",
		"options": []
	}

# Finds the first already-ranked M5 Level recommendation matching one Skill.
func GetFirstRecommendedLevelForSkill(skillId: String, recommendations: Array) -> String:
	for recommendationValue in recommendations:
		if not recommendationValue is Dictionary:
			continue
		var recommendation: Dictionary = recommendationValue
		if skillId in recommendation.get("weakSkills", []):
			return String(recommendation.get("levelTitle", ""))
	return ""

# Adds one unique Level action with explicit confirmation before navigation.
func AppendLevelPracticeOption(
	options: Array[Dictionary],
	skillId: String,
	recommendations: Array
) -> void:
	for recommendationValue in recommendations:
		if not recommendationValue is Dictionary:
			continue
		var recommendation: Dictionary = recommendationValue
		if skillId not in recommendation.get("weakSkills", []):
			continue
		var levelId: String = recommendation.get("levelId", "")
		var levelTitle: String = recommendation.get("levelTitle", "")
		if levelId.is_empty():
			return
		for existingOption in options:
			if existingOption.get("actionId", "") == "confirm_level:" + levelId:
				return
		options.append({
			"actionId": "confirm_level:" + levelId,
			"label": T("Practice %s") % T(levelTitle),
			"nextPage": BuildActionConfirmationPage(
				"RECOMMENDED LEVEL",
				T("Start %s?") % T(levelTitle),
				T("This Level is already ranked by M5 for overlap with %s.") % FormatSkillName(skillId),
				"Start",
				"start_level:" + levelId
			)
		})
		return

# Builds the shared confirmation contract used before major Tutor actions.
func BuildActionConfirmationPage(
	contextText: String,
	titleText: String,
	responseText: String,
	confirmLabel: String,
	confirmActionId: String
) -> Dictionary:
	return {
		"contextLabel": contextText,
		"title": titleText,
		"response": responseText,
		"options": [
			{
				"actionId": confirmActionId,
				"label": confirmLabel
			},
			{
				"actionId": "cancel_action",
				"label": "Not Now",
				"nextPage": {
					"contextLabel": contextText,
					"title": "Action Cancelled",
					"response": "Nothing was changed. You can choose another Tutor option.",
					"options": []
				}
			}
		]
	}

# Lists the already-ranked M5 Levels without hard-coded Skill mappings.
func BuildRelevantLevelPage(tutorContext: Dictionary) -> Dictionary:
	var courseName: String = tutorContext.get("course", {}).get("displayName", "Current Course")
	var recommendations: Array = tutorContext.get("learning", {}).get("recommendations", [])
	if recommendations.is_empty():
		return BuildNotEnoughDataPage(courseName)
	var levelLines := PackedStringArray()
	var options: Array[Dictionary] = []
	for recommendationValue in recommendations:
		if not recommendationValue is Dictionary:
			continue
		var recommendation: Dictionary = recommendationValue
		var levelId: String = recommendation.get("levelId", "")
		var levelTitle: String = recommendation.get("levelTitle", "")
		var matchedSkills := PackedStringArray()
		for skillValue in recommendation.get("weakSkills", []):
			matchedSkills.append(FormatSkillName(String(skillValue)))
		levelLines.append("%s - %s" % [T(levelTitle), ", ".join(matchedSkills)])
		options.append({
			"actionId": "confirm_level:" + levelId,
			"label": T("Practice %s") % T(levelTitle),
			"nextPage": BuildActionConfirmationPage(
				"RECOMMENDED LEVEL",
				T("Start %s?") % T(levelTitle),
				"This uses the existing M5 Level recommendation for the active Course.",
				"Start",
				"start_level:" + levelId
			)
		})
	return {
		"contextLabel": courseName.to_upper(),
		"title": "Relevant Levels",
		"response": "\n".join(levelLines),
		"options": options
	}

# Summarizes recent stored Question history without claiming unsupported trends.
func BuildPlayerHistoryPage(tutorContext: Dictionary) -> Dictionary:
	var courseName: String = tutorContext.get("course", {}).get("displayName", "Current Course")
	var recentHistory: Array = tutorContext.get("learning", {}).get("recentHistory", [])
	if recentHistory.is_empty():
		return BuildNotEnoughDataPage(courseName)
	var historyLines := PackedStringArray()
	var firstIndex: int = maxi(0, recentHistory.size() - 3)
	for historyIndex in range(firstIndex, recentHistory.size()):
		var historyRecord: Dictionary = recentHistory[historyIndex]
		var outcome: Dictionary = historyRecord.get("outcome", {})
		historyLines.append(T("%s - %d points - %s") % [
			historyRecord.get("expression", "Question"),
			int(outcome.get("questionScore", 0)),
			T("Completed") if outcome.get("completed", false) else T("Incomplete")
		])
	return {
		"contextLabel": courseName.to_upper(),
		"title": "Recent Question History",
		"response": "\n".join(historyLines),
		"options": []
	}

# Presents the latest session-based behavior label with its stored evidence.
func BuildBehaviorPatternPage(tutorContext: Dictionary) -> Dictionary:
	var courseName: String = tutorContext.get("course", {}).get("displayName", "Current Course")
	var recentHistory: Array = tutorContext.get("learning", {}).get("recentHistory", [])
	if recentHistory.is_empty():
		return BuildNotEnoughDataPage(courseName)
	var latestRecord: Dictionary = recentHistory.back()
	var patternName: String = latestRecord.get("primaryBehaviorPattern", "")
	if patternName.is_empty():
		return BuildNotEnoughDataPage(courseName)
	var sharedMetrics: Dictionary = latestRecord.get("sharedMetrics", {})
	var evidenceLines := PackedStringArray()
	evidenceLines.append(T("Observed Pattern: %s") % FormatSkillName(patternName))
	evidenceLines.append(T("Evidence from this completed Question:"))
	evidenceLines.append(T("- First action time: %d ms") % int(latestRecord.get("firstActionTimeMs", -1)))
	evidenceLines.append(T("- Total actions: %d") % int(sharedMetrics.get("totalActions", 0)))
	evidenceLines.append(T("- Incorrect attempts: %d") % int(sharedMetrics.get("incorrectAttempts", 0)))
	evidenceLines.append(T("- Hints used: %d") % int(sharedMetrics.get("hintUses", 0)))
	return {
		"contextLabel": courseName.to_upper(),
		"title": "Recent Solve Pattern",
		"response": "\n".join(evidenceLines),
		"options": []
	}

# Explains replay modes and provides explicit confirmation for each start action.
func BuildPracticeModePage(tutorContext: Dictionary) -> Dictionary:
	var courseName: String = tutorContext.get("course", {}).get("displayName", "Current Course")
	var hasWeakSkills: bool = not tutorContext.get("learning", {}).get("weakSkills", []).is_empty()
	var hasMistakes: bool = tutorContext.get("mistakeBook", {}).get("hasEntries", false)
	var options: Array[Dictionary] = []
	if hasWeakSkills:
		options.append({
			"actionId": "confirm_adaptive_practice",
			"label": "Adaptive Practice",
			"nextPage": BuildActionConfirmationPage(
				courseName.to_upper(), "Start Adaptive Practice?",
				"M5 weighting increases the chance of weaker-Skill Questions while preserving variety.",
				"Start", "start_adaptive_practice"
			)
		})
	if hasMistakes:
		options.append({
			"actionId": "confirm_mistake_practice",
			"label": "Mistake Practice",
			"nextPage": BuildActionConfirmationPage(
				courseName.to_upper(), "Start Mistake Practice?",
				"Practice up to ten Questions selected from this Course's Mistake Book.",
				"Start", "start_mistake_practice"
			)
		})
	options.append({
		"actionId": "confirm_zen",
		"label": "Zen Mode",
		"nextPage": BuildActionConfirmationPage(
			courseName.to_upper(), "Start Zen Mode?",
			"Zen Mode is three minutes of mixed practice using the existing adaptive Question selection.",
			"Start", "start_zen"
		)
	})
	options.append({
		"actionId": "confirm_survival",
		"label": "Survival Mode",
		"nextPage": BuildActionConfirmationPage(
			courseName.to_upper(), "Start Survival Mode?",
			"Survival Mode is untimed mixed practice with three lives and accuracy pressure.",
			"Start", "start_survival"
		)
	})
	return {
		"contextLabel": courseName.to_upper(),
		"title": "Practice Modes",
		"response": "Choose a replay mode. Options appear only when their required Course data exists.",
		"options": options
	}

# Converts stored snake_case Skill IDs into player-facing labels.
func FormatSkillName(skillId: String) -> String:
	return T(skillId.replace("_", " ").capitalize())

# Translates one stable response fragment through MathSmith's existing catalog.
func T(sourceText: String) -> String:
	return String(TranslationServer.translate(sourceText))

# Keeps automatic error feedback separate from player-requested Hint help.
func BuildFeedbackRulePage(_tutorContext: Dictionary) -> Dictionary:
	return {
		"contextLabel": "GAMEPLAY",
		"title": "Hints and Error Feedback",
		"response": "Hints are limited, player-requested help and may reduce your Score. Progressive Error Feedback appears automatically after repeated incorrect attempts: first generic feedback, then directional guidance, then a contextual rule explanation. It does not spend a Hint.",
		"options": []
	}

# Reuses the deterministic Mistake Book rule explanation for the active Question.
func BuildMistakeRulePage(tutorContext: Dictionary) -> Dictionary:
	var question: Dictionary = tutorContext.get("question", {})
	var ruleCategory: String = question.get("ruleCategory", "Relevant Rule")
	var ruleExplanation: String = question.get(
		"ruleExplanation",
		"No rule explanation is available for this Question."
	)
	return {
		"contextLabel": "QUESTION RULE",
		"title": ruleCategory,
		"response": ruleExplanation,
		"options": []
	}

# Shows only the correct process already generated by the gameplay system.
func BuildCorrectProcessPage(tutorContext: Dictionary) -> Dictionary:
	var question: Dictionary = tutorContext.get("question", {})
	var correctProcess: Array = question.get("correctProcess", [])
	var formattedSteps := PackedStringArray()
	for stepValue in correctProcess:
		formattedSteps.append(String(stepValue))
	var responseText: String = T("No generated process is available for this Question.")
	if not formattedSteps.is_empty():
		responseText = T("TUTOR_CORRECT_PROCESS_FORMAT") % "\n".join(formattedSteps)
	return {
		"contextLabel": "QUESTION PROCESS",
		"title": question.get("expression", "Correct Process"),
		"response": responseText,
		"options": []
	}

# Builds separate review actions from fields already persisted in Mistake Book.
func BuildSavedMistakePage(mistakeEntry: Dictionary) -> Dictionary:
	var answerStepsValue: Variant = mistakeEntry.get("answerSteps", [])
	var answerSteps: Array = (
		answerStepsValue.duplicate()
		if answerStepsValue is Array
		else []
	)
	var questionContext := {
		"question": {
			"expression": mistakeEntry.get("expression", ""),
			"ruleCategory": mistakeEntry.get("errorCategory", "Relevant Rule"),
			"ruleExplanation": mistakeEntry.get("explanation", ""),
			"correctProcess": answerSteps
		}
	}
	var savedReasons := PackedStringArray()
	var incorrectAttempts: int = mistakeEntry.get("incorrectAttempts", 0)
	if incorrectAttempts >= 2:
		savedReasons.append(T("%d incorrect attempts") % incorrectAttempts)
	if mistakeEntry.get("hintUsed", false):
		savedReasons.append(T("a Hint was used"))
	var reasonText: String = T("This Question was saved for later review.")
	if not savedReasons.is_empty():
		reasonText = T("This Question was saved after %s.") % T(" and ").join(savedReasons)
	return {
		"contextLabel": "MISTAKE REVIEW",
		"title": mistakeEntry.get("expression", "Saved Question"),
		"response": "Choose how you want to review this saved Question.",
		"options": [
			{
				"actionId": "explain_saved_reason",
				"label": "Why was this Question saved?",
				"nextPage": {
					"contextLabel": "MISTAKE REVIEW",
					"title": "Why Saved",
					"response": reasonText,
					"options": []
				}
			},
			{
				"actionId": "explain_saved_rule",
				"label": "Explain the Rule",
				"nextPage": BuildMistakeRulePage(questionContext)
			},
			{
				"actionId": "show_saved_process",
				"label": "Show the Correct Process",
				"nextPage": BuildCorrectProcessPage(questionContext)
			}
		]
	}

#endregion
