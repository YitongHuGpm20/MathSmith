## Coordinates deterministic Tutor pages from one structured context snapshot.
##
## This service does not read gameplay systems directly. GameManager supplies a
## course-scoped Tutor Context and TutorManager converts it into UI page data.
extends RefCounted

#region ========== References ==========

var responseBuilder := preload("res://Scripts/Learning/TutorResponseBuilder.gd").new()

#endregion

#region ========== Functions ==========

# Builds the initial guided page using only the active Course Source context.
func BuildOpeningPage(tutorContext: Dictionary) -> Dictionary:
	var screenId: String = tutorContext.get("screen", {}).get("id", "")
	if screenId == "home_scene":
		return BuildHomeOpeningPage()
	if screenId == "game_scene":
		if tutorContext.get("session", {}).get("teacherPreview", false):
			return BuildTeacherPreviewOpeningPage(tutorContext)
		if not tutorContext.get("session", {}).get("summary", {}).is_empty():
			return BuildSessionSummaryOpeningPage(tutorContext)
		return BuildGameplayOpeningPage(tutorContext)
	if screenId == "mistake_book_scene":
		return BuildMistakeBookOpeningPage(tutorContext)
	return BuildLobbyOpeningPage(tutorContext)

# Builds a global Home response without reading any default Course data.
func BuildHomeOpeningPage() -> Dictionary:
	return {
		"contextLabel": "MATHSMITH TUTOR",
		"title": "How can I help?",
		"response": "I can explain MathSmith's learning tools and provide Course-specific guidance after you enter a Course.",
		"options": [
			{
				"actionId": "explain_mathsmith",
				"label": "What is MathSmith?",
				"nextPage": {
					"contextLabel": "MATHSMITH TUTOR",
					"title": "About MathSmith",
					"response": "MathSmith is a step-based math learning game. It focuses on rebuilding and understanding the reasoning process behind each calculation.",
					"options": []
				}
			},
			{
				"actionId": "explain_game_modes",
				"label": "How do the game modes work?",
				"nextPage": {
					"contextLabel": "MATHSMITH TUTOR",
					"title": "Game Modes",
					"response": "Step Ordering asks you to arrange a complete process. Multiple-Choice Ordering asks you to choose each next Step. Fill in the Process asks you to complete missing values.",
					"options": []
				}
			},
			{
				"actionId": "explain_first_step",
				"label": "What should I do first?",
				"nextPage": {
					"contextLabel": "MATHSMITH TUTOR",
					"title": "Getting Started",
					"response": "Select Play, choose a Course, then begin with a Level in the first gameplay mode. Tutor will use that Course's data only after you enter it.",
					"options": []
				}
			},
			{
				"actionId": "explain_progress_location",
				"label": "Show my progress",
				"nextPage": {
					"contextLabel": "MATHSMITH TUTOR",
					"title": "Course Progress",
					"response": "Progress is stored separately for each Course. Enter a Course and open Tutor there to review its learning data without mixing Course Sources.",
					"options": []
				}
			},
			{
				"actionId": "open_course_selection",
				"label": "Choose a Course"
			},
			{
				"actionId": "open_settings",
				"label": "Open Settings"
			}
		]
	}

# Builds Course-specific Lobby options from only the active Course Source.
func BuildLobbyOpeningPage(tutorContext: Dictionary) -> Dictionary:
	var courseContext: Dictionary = tutorContext.get("course", {})
	var learningContext: Dictionary = tutorContext.get("learning", {})
	var mistakeContext: Dictionary = tutorContext.get("mistakeBook", {})
	var courseName: String = courseContext.get("displayName", "Current Course")
	var weakSkills: Array = learningContext.get("weakSkills", [])
	var options: Array[Dictionary] = [
		{
			"actionId": "show_practice_direction",
			"label": "What should I practice?",
			"nextPage": responseBuilder.BuildWeakSkillRecommendationPage(tutorContext)
		},
		{
			"actionId": "show_weak_skills",
			"label": "What are my weak Skills?",
			"nextPage": BuildWeakSkillOverviewPage(courseName, weakSkills)
		},
		{
			"actionId": "show_course_context",
			"label": "Show Skill Mastery",
			"nextPage": BuildCourseDataPage(courseName, learningContext, mistakeContext)
		},
		{
			"actionId": "show_relevant_levels",
			"label": "Show relevant Levels",
			"nextPage": responseBuilder.BuildRelevantLevelPage(tutorContext)
		},
		{
			"actionId": "explain_tutor_scope",
			"label": "How does Tutor use my data?",
			"nextPage": BuildCourseIsolationPage(courseName)
		}
	]
	options.append({
		"actionId": "show_player_history",
		"label": "Show recent History",
		"nextPage": responseBuilder.BuildPlayerHistoryPage(tutorContext)
	})
	options.append({
		"actionId": "open_settings",
		"label": "Open Settings"
	})
	options.append({
		"actionId": "show_behavior_pattern",
		"label": "Explain my recent solve pattern",
		"nextPage": responseBuilder.BuildBehaviorPatternPage(tutorContext)
	})
	options.append({
		"actionId": "show_practice_modes",
		"label": "Explore practice modes",
		"nextPage": responseBuilder.BuildPracticeModePage(tutorContext)
	})
	if mistakeContext.get("hasEntries", false):
		options.append({
			"actionId": "confirm_mistake_book",
			"label": "Open Mistake Book",
			"nextPage": responseBuilder.BuildActionConfirmationPage(
				courseName.to_upper(),
				"Open Mistake Book?",
				T("Review %d saved mistake entries from this Course.") % int(mistakeContext.get("entryCount", 0)),
				"Open",
				"open_mistake_book"
			)
		})
	if not weakSkills.is_empty():
		options.append({
			"actionId": "confirm_adaptive_practice",
			"label": "Start Adaptive Practice",
			"nextPage": responseBuilder.BuildActionConfirmationPage(
				courseName.to_upper(),
				"Start Adaptive Practice?",
				"Existing M5 weights will increase the chance of weaker-Skill Questions while preserving content variety.",
				"Start",
				"start_adaptive_practice"
			)
		})
	return {
		"contextLabel": courseName.to_upper(),
		"title": "Course Guidance",
		"response": T("Tutor is using only %s learning data.") % T(courseName),
		"options": options
	}

# Builds rule-focused options only while the player is inside GameScene.
func BuildGameplayOpeningPage(tutorContext: Dictionary) -> Dictionary:
	var courseName: String = tutorContext.get("course", {}).get(
		"displayName",
		"Current Course"
	)
	var gameplayContext: Dictionary = tutorContext.get("gameplay", {})
	var questionContext: Dictionary = tutorContext.get("question", {})
	var sessionSummary: Dictionary = tutorContext.get("session", {}).get("summary", {})
	var options: Array[Dictionary] = [
		{
			"actionId": "explain_gameplay_mode",
			"label": "Explain this game mode",
			"nextPage": responseBuilder.BuildGameplayRulePage(tutorContext)
		},
		{
			"actionId": "explain_relevant_rule",
			"label": "Explain the Rule",
			"nextPage": responseBuilder.BuildMistakeRulePage(tutorContext)
		},
		{
			"actionId": "explain_feedback_rules",
			"label": "How do Hints and error feedback work?",
			"nextPage": responseBuilder.BuildFeedbackRulePage(tutorContext)
		},
		{
			"actionId": "open_tutorial",
			"label": "Open the gameplay Tutorial"
		},
		{
			"actionId": "confirm_lobby",
			"label": "Return to Lobby",
			"nextPage": responseBuilder.BuildActionConfirmationPage(
				"NAVIGATION", "Return to Lobby?",
				"The current unfinished Level will restart when opened again.",
				"Return", "open_lobby"
			)
		},
		{
			"actionId": "open_settings",
			"label": "Open Settings"
		}
	]
	if questionContext.get("completed", false):
		options.insert(2, {
			"actionId": "show_correct_process",
			"label": "Show the Correct Process",
			"nextPage": responseBuilder.BuildCorrectProcessPage(tutorContext)
		})
	if (
		int(gameplayContext.get("questionHintsUsed", 0)) > 0
		or int(gameplayContext.get("questionIncorrectAttempts", 0)) > 0
	):
		options.insert(1, {
			"actionId": "explain_scoring_rules",
			"label": "Why did I lose points?",
			"nextPage": responseBuilder.BuildScoringRulePage(tutorContext)
		})
	elif not sessionSummary.is_empty():
		options.insert(1, {
			"actionId": "explain_session_score",
			"label": "How was my result calculated?",
			"nextPage": responseBuilder.BuildScoringRulePage(tutorContext)
		})
	return {
		"contextLabel": courseName.to_upper(),
		"title": "Gameplay Help",
		"response": "Choose what you want to understand. Tutor will explain the existing rules without revealing the current answer.",
		"options": options
	}

# Replaces active-solving options with result-focused actions after a session ends.
func BuildSessionSummaryOpeningPage(tutorContext: Dictionary) -> Dictionary:
	var courseName: String = tutorContext.get("course", {}).get(
		"displayName",
		"Current Course"
	)
	var summary: Dictionary = tutorContext.get("session", {}).get("summary", {})
	var mistakeContext: Dictionary = tutorContext.get("mistakeBook", {})
	var options: Array[Dictionary] = [
		{
			"actionId": "show_performance_summary",
			"label": "How did I do?",
			"nextPage": responseBuilder.BuildPerformanceSummaryPage(tutorContext)
		},
		{
			"actionId": "show_next_practice",
			"label": "What should I practice next?",
			"nextPage": responseBuilder.BuildWeakSkillRecommendationPage(tutorContext)
		}
	]
	options.append({
		"actionId": "show_recent_history",
		"label": "Show recent Question History",
		"nextPage": responseBuilder.BuildPlayerHistoryPage(tutorContext)
	})
	options.append({
		"actionId": "confirm_lobby",
		"label": "Return to Lobby",
		"nextPage": responseBuilder.BuildActionConfirmationPage(
			"NAVIGATION", "Return to Lobby?", "Review the Course Lobby and choose another activity.",
			"Return", "open_lobby"
		)
	})
	options.append({
		"actionId": "show_practice_modes",
		"label": "Choose another practice mode",
		"nextPage": responseBuilder.BuildPracticeModePage(tutorContext)
	})
	if (
		summary.has("stars")
		and not summary.get("isPracticeSession", false)
		and not summary.get("isTeacherPreview", false)
	):
		options.append({
			"actionId": "explain_star_rating",
			"label": "Why did I get this Star rating?",
			"nextPage": responseBuilder.BuildStarRatingPage(tutorContext)
		})
	if mistakeContext.get("hasEntries", false):
		options.append({
			"actionId": "review_session_mistakes",
			"label": "Review my mistakes",
			"nextPage": responseBuilder.BuildActionConfirmationPage(
				courseName.to_upper(),
				"Open Mistake Book?",
				T("Review %d saved mistake entries from this Course.") % int(mistakeContext.get("entryCount", 0)),
				"Open",
				"open_mistake_book"
			)
		})
	return {
		"contextLabel": "SESSION SUMMARY",
		"title": "Session Complete",
		"response": "Your completed result is ready. Choose what you want to review next.",
		"options": options
	}

# Gives teacher QA full deterministic process access without player-data options.
func BuildTeacherPreviewOpeningPage(tutorContext: Dictionary) -> Dictionary:
	var courseName: String = tutorContext.get("course", {}).get("displayName", "Preview Course")
	return {
		"contextLabel": "TEACHER PREVIEW",
		"title": courseName,
		"response": "Preview guidance reads this authored Course and does not write Player History, Mastery, Mistake Book, adaptive data, or analytics.",
		"options": [
			{
				"actionId": "preview_gameplay_rule",
				"label": "Explain this game mode",
				"nextPage": responseBuilder.BuildGameplayRulePage(tutorContext)
			},
			{
				"actionId": "preview_question_rule",
				"label": "Explain this Question's rule",
				"nextPage": responseBuilder.BuildMistakeRulePage(tutorContext)
			},
			{
				"actionId": "preview_correct_process",
				"label": "Show the generated process",
				"nextPage": responseBuilder.BuildCorrectProcessPage(tutorContext)
			}
		]
	}

# Lists existing weak-Skill classifications without recalculating Mastery.
func BuildWeakSkillOverviewPage(courseName: String, weakSkills: Array) -> Dictionary:
	var responseText: String = T("No weak Skills are currently identified for this Course.")
	if not weakSkills.is_empty():
		var skillNames := PackedStringArray()
		for skillValue in weakSkills:
			skillNames.append(T(String(skillValue).replace("_", " ").capitalize()))
		responseText = T("TUTOR_WEAK_SKILLS_FORMAT") % "\n- ".join(skillNames)
	return {
		"contextLabel": courseName.to_upper(),
		"title": "Weak Skills",
		"response": responseText,
		"options": []
	}

# Introduces saved review guidance without selecting an entry implicitly.
func BuildMistakeBookOpeningPage(tutorContext: Dictionary) -> Dictionary:
	var courseName: String = tutorContext.get("course", {}).get(
		"displayName",
		"Current Course"
	)
	var entryCount: int = tutorContext.get("mistakeBook", {}).get("entryCount", 0)
	var options: Array[Dictionary] = []
	if entryCount > 0:
		options.append({
			"actionId": "confirm_mistake_practice",
			"label": "Start Mistake Practice",
			"nextPage": responseBuilder.BuildActionConfirmationPage(
				courseName.to_upper(),
				"Start Mistake Practice?",
				"Practice up to ten saved Questions from this Course.",
				"Start",
				"start_mistake_practice"
			)
		})
	options.append({
		"actionId": "open_lobby",
		"label": "Return to Lobby"
	})
	return {
		"contextLabel": courseName.to_upper(),
		"title": "Mistake Book Guidance",
		"response": T("This Course has %d saved mistake entries. Select Ask Tutor on a Question card to inspect why it was saved, explain its existing rule, or reveal its stored correct process.") % entryCount,
		"options": options
	}

# Builds guidance from one saved entry without generating new mathematics.
func BuildSavedMistakePage(mistakeEntry: Dictionary) -> Dictionary:
	return responseBuilder.BuildSavedMistakePage(mistakeEntry)

# Summarizes real counts without exposing raw analytics or mixing Courses.
func BuildCourseDataPage(
	courseName: String,
	learningContext: Dictionary,
	mistakeContext: Dictionary
) -> Dictionary:
	var skillProgress: Dictionary = learningContext.get("skillProgress", {})
	var weakSkills: Array = learningContext.get("weakSkills", [])
	return {
		"contextLabel": courseName.to_upper(),
		"title": "Current Course Data",
		"response": (
			T("TUTOR_COURSE_DATA_FORMAT")
			% [
				int(learningContext.get("historyRecordCount", 0)),
				skillProgress.size(),
				weakSkills.size(),
				int(mistakeContext.get("entryCount", 0))
			]
		),
		"options": [
			{
				"actionId": "open_skill_mastery",
				"label": "Open Skill Mastery"
			}
		]
	}

# Explains the active-source boundary without claiming any new analysis.
func BuildCourseIsolationPage(courseName: String) -> Dictionary:
	return {
		"contextLabel": courseName.to_upper(),
		"title": "Course-Scoped Guidance",
		"response": (
			T("Tutor uses only %s data while this Course is active. Other Course progress, mistakes, history, and Skill values are not included.")
			% T(courseName)
		),
		"options": []
	}

# Translates one stable Tutor fragment through the shared catalog.
func T(sourceText: String) -> String:
	return String(TranslationServer.translate(sourceText))

#endregion
