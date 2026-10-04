# M8 Conversational AI Tutor — Manual Validation

Use this checklist in both English and Simplified Chinese. Test Core Curriculum,
Imported Course, and Studio Course separately where available.

## Conversation and Grounding

- Guided and Chat remain separate interaction surfaces.
- Chat shows player and Tutor messages, thinking, retry, and validated actions.
- `/mock-action` shows only an action allowed by the current deterministic page.
- `/mock-invalid-action` never displays or executes the untrusted action.
- Unsolved Questions do not expose the validated process or final answer.
- Conversation resets when changing Course Source or choosing Clear Conversation.

## Presence and Voice

- Inactivity and repeated errors show at most one non-blocking notice per Question.
- A notice never opens Tutor, steals focus, pauses gameplay, or reveals an answer.
- Push-to-Talk requires an explicit click and never sends a transcript automatically.
- Unsupported or denied speech input leaves text Chat usable.
- Tutor voice is player-requested, stops predictably, and never hides response text.

## Settings and Failure

- Conversational AI Off disables Chat while Guided Tutor still works.
- Tutor Voice Off stops speech and hides replay controls.
- Proactive Tutor Off suppresses and clears notices.
- All three settings survive a restart without changing player progress.
- Provider failure shows a friendly error and leaves deterministic guidance usable.

## Diagnostics and Isolation

- F3 reports provider, request, context, action, fallback, speech, and proactive state.
- F3 never shows a secret, full save, filesystem path, or raw private provider data.
- Context follows the active Course, Level, Question, screen, Skills, and locale.
- Teacher Preview does not write History, Mastery, Mistakes, adaptive data, or progress.
- English UI receives English Mock responses; Simplified Chinese receives Chinese ones.
