# M7 Tutor Architecture

MathSmith Tutor is a deterministic guidance layer. It connects existing gameplay, learning, review, analytics, replay, and course systems without owning their calculations.

## Responsibility Flow

```text
Existing MathSmith State
-> TutorContextProvider
-> TutorManager
-> TutorResponseBuilder
-> TutorPanel
-> TutorNavigationAdapter
-> Existing GameManager Actions
```

## Responsibilities

- `TutorContextProvider` creates an isolated snapshot for the active Course Source.
- `TutorManager` chooses context-specific option sets for Home, Lobby, Gameplay, Session Summary, Mistake Book, and Teacher Preview.
- `TutorResponseBuilder` formats deterministic explanations, summaries, recommendations, confirmations, and replay guidance.
- `TutorPanel` owns presentation, scrolling, option history, Back, Previous, Close, keyboard input, and localization refresh.
- `TutorNavigationAdapter` parses stable action IDs. `GameManager` executes them through existing navigation and session functions.

## Source of Truth

Tutor reads existing values only:

- StepGenerator output for correct processes
- MistakeBookManager categories and explanations
- live Score counters and stored session summaries
- M5 Player History, Skill Mastery, weak Skills, behavior patterns, Level recommendations, and adaptive selection
- active Course Source identity and Teacher Preview state

Tutor does not calculate mathematical correctness, Mastery, adaptive weights, Stars, saved progress, or Question selection.

## Course Isolation

Core Curriculum, Imported Course, and Studio Course keep separate progress, mistakes, history, Mastery, recommendations, and replay data. Home receives no default Course learning data. Teacher Preview receives authored content context but suppresses player learning data and writes.

## Optional Generative Guidance

No LLM is used by M7. A future optional language layer must consume the validated Tutor Context, preserve deterministic MathSmith outputs as the source of truth, and retain the current option-based fallback.
