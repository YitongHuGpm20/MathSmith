# M7 Manual Validation

M7 requires owner playtesting. Implementation does not imply pedagogical or UX validation.

## Entry and Context

- Home shows global guidance and no default Course data.
- Lobby shows only the selected Core, Imported, or Studio Course data.
- Gameplay options match the active interaction mode.
- Session Summary replaces active-solving options after completion.
- Mistake Book `Ask Tutor` reads the selected card only.

## Explanations

- A new active Question never exposes the correct process.
- Correct process appears after completion, in Mistake Book review, or Teacher Preview QA.
- Rule explanations match existing Mistake Book logic.
- Score breakdown matches actual Hint and repeated-error deductions.
- Level Score, percentage, Stars, Zen, and Survival summaries match the result UI.

## Recommendations and Navigation

- Weak Skills and Mastery match the M5 Skill Mastery panel.
- No-data Courses show Not Enough Data instead of forced recommendations.
- Relevant Levels come from Skill Tags and M5 rankings.
- Major navigation and replay actions require Start/Open confirmation.
- Not Now leaves the current screen and state unchanged.

## Isolation

- Switching Course Sources changes Tutor history, mistakes, Skills, and recommendations.
- Teacher Preview shows rule/process QA but writes no history, Mastery, mistakes, adaptive data, or analytics.

## Presentation

- English and Simplified Chinese option labels fit the panel.
- Long responses scroll.
- Tab focus is visible without an initially highlighted option.
- Escape closes Tutor.
- Bubble, options, and Close use one shared subtle Button SFX.
- Tutor does not cover required gameplay controls at supported window sizes.
