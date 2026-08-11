# Future Development Roadmap

M1–M4 establish the core gameplay, content architecture, learning loop, progression, persistence, and replay systems.

The remaining milestones intentionally move outward from the player experience:

```text
M5
Understand the Learner
		↓
M6
Enable Content Authors
		↓
M7
Connect the Systems Through Guided Support
```

The following tasks are planned, not currently implemented.

---

# M5 — Analytics & Adaptive Learning

**Goal: Observe player behavior, identify learning patterns, and use those findings to improve practice.**

M5 extends the existing score, Mistake Book, Skill Tag, Local Save, and replay systems rather than replacing them.

## Behavior Tracking

- [ ] Create a lightweight gameplay telemetry model
- [ ] Record Question start and completion timestamps
- [ ] Record total solve time
- [ ] Record time before first player action
- [ ] Record incorrect attempts
- [ ] Record Hint usage
- [ ] Record highest Progressive Error Feedback level reached
- [ ] Record gameplay interaction type
- [ ] Record associated Skill Tags
- [ ] Record Question Score
- [ ] Record Level Score
- [ ] Record Step Ordering drag / reorder count
- [ ] Record Multiple-Choice selection changes
- [ ] Record Fill in the Process answer revisions
- [ ] Store completed session telemetry through Local Save
- [ ] Define a lightweight Player History schema

## Skill Analysis

- [ ] Aggregate results by Skill Tag
- [ ] Calculate Skill-level accuracy
- [ ] Calculate average attempts by Skill
- [ ] Calculate average Hint usage by Skill
- [ ] Calculate average solve time by Skill
- [ ] Compare performance across gameplay interactions
- [ ] Identify repeated error categories
- [ ] Create simple Skill Mastery values
- [ ] Separate observed behavior from inferred player ability

## Learning Behavior Patterns

- [ ] Define observable solving patterns without over-claiming cognition
- [ ] Compare first-action time with later correction behavior
- [ ] Detect repeated submission / brute-force patterns
- [ ] Detect high-revision exploratory solving patterns
- [ ] Detect high-confidence first-attempt patterns
- [ ] Document which conclusions are evidence-based versus hypotheses

Example:

```text
Observed:
Long first-action time
Low revision count
First-attempt success

Possible interpretation:
Deliberate solving pattern

Do not claim:
"This player is a deliberate thinker."
```

## Adaptive Practice

- [ ] Identify currently weak Skills
- [ ] Recommend relevant Levels
- [ ] Recommend Mistake Practice when appropriate
- [ ] Add weighted Question selection based on weak Skills
- [ ] Allow Practice sessions to favor weak Skills
- [ ] Allow Zen Mode Question weights to adapt to player performance
- [ ] Prevent adaptive weighting from eliminating content variety
- [ ] Keep recommendation logic deterministic and explainable

## Player-Facing Skill Mastery

- [ ] Create a Skill Mastery screen
- [ ] Display Skill percentages
- [ ] Display simple mastery states
- [ ] Show improvement over recent sessions
- [ ] Link weak Skills to relevant practice
- [ ] Connect Skill Mastery to Player History

Potential states:

```text
Mastered
Strong
Developing
Needs Practice
```

## Developer / Analytics Overlay

- [ ] Create a developer-facing analytics screen
- [ ] Show current session telemetry
- [ ] Show Skill performance summaries
- [ ] Show interaction-mode performance
- [ ] Show repeated error categories
- [ ] Show Hint usage patterns
- [ ] Show first-action and solve-time statistics
- [ ] Add filters for Level, Skill, Mode, and Question
- [ ] Keep developer analytics separate from player-facing UI

## M5 Validation

- [ ] Confirm telemetry does not alter gameplay behavior
- [ ] Confirm saved analytics remain compatible with existing Save data
- [ ] Review whether every tracked metric has a clear purpose
- [ ] Remove telemetry that does not support a product or design decision
- [ ] Validate Skill calculations with representative player histories
- [ ] Confirm adaptive practice remains transparent and predictable

### M5 Key Question

> **What can player behavior tell us about where the learner is struggling, without making unsupported assumptions about cognition?**

---

# M6 — Content Authoring Pipeline

**Goal: Allow teachers, curriculum designers, and content specialists to create and validate MathSmith content without editing project code.**

M6 moves MathSmith from a developer-authored prototype toward a reusable content platform.

## Authoring Schema

- [ ] Review the current JSON schema for author-facing requirements
- [ ] Define required and optional content fields
- [ ] Document Level Type fields
- [ ] Document Level fields
- [ ] Document Question fields
- [ ] Document Skill Tag conventions
- [ ] Define unique ID requirements
- [ ] Define supported mathematical syntax
- [ ] Define validation rules
- [ ] Define content versioning strategy

## CSV Template

- [ ] Create a downloadable CSV template
- [ ] Add example rows
- [ ] Add human-readable column names
- [ ] Document required fields
- [ ] Document supported operators and syntax
- [ ] Document Skill Tag formatting
- [ ] Include sample Levels across multiple difficulty ranges

## CSV Upload

- [ ] Add local CSV file selection
- [ ] Parse uploaded CSV
- [ ] Convert CSV rows into runtime content data
- [ ] Support multiple Levels in one upload
- [ ] Preserve Question and Level IDs
- [ ] Prevent uploaded content from silently overwriting existing content

## Content Validation

- [ ] Validate required fields
- [ ] Validate duplicate IDs
- [ ] Validate missing Level references
- [ ] Validate malformed mathematical expressions
- [ ] Validate unsupported operators
- [ ] Validate empty Questions
- [ ] Validate Skill Tags
- [ ] Validate Level Type values
- [ ] Validate Question counts
- [ ] Validate whether `ExpressionParser` can parse each expression
- [ ] Validate whether `StepGenerator` can generate a usable process
- [ ] Produce human-readable validation errors
- [ ] Identify the exact row / field causing each error

Example:

```text
Row 17
Question ID: L06_Q04

Error:
Expression "18 + / 4" could not be parsed.

Suggested Action:
Check the operator sequence.
```

## CSV → Runtime Content

- [ ] Convert validated CSV into the internal runtime structure
- [ ] Keep imported content compatible with existing LevelLoader logic
- [ ] Allow imported content to use all three gameplay interactions
- [ ] Preserve existing scoring and Hint systems
- [ ] Preserve Search and Filter support
- [ ] Preserve localization-ready data structure

## Visual Content Editor

- [ ] Create a teacher-facing editor screen
- [ ] Display all Levels
- [ ] Add Level
- [ ] Delete Level
- [ ] Rename Level
- [ ] Edit Level title
- [ ] Edit Skill Tags
- [ ] Reorder Levels
- [ ] Add Question
- [ ] Delete Question
- [ ] Edit mathematical expression
- [ ] Duplicate Question
- [ ] Display Question count
- [ ] Validate changes in real time
- [ ] Surface clear error states
- [ ] Avoid exposing raw JSON where unnecessary

## Generated-Step Preview

- [ ] Preview the generated solution for any Question
- [ ] Display `ExpressionParser` result where useful
- [ ] Display generated Step sequence
- [ ] Flag generation failures
- [ ] Allow authors to identify pedagogically awkward generated output
- [ ] Keep preview separate from saved/published content

## Teacher Preview Mode

- [ ] Launch selected content directly into gameplay
- [ ] Preview Step Ordering
- [ ] Preview Multiple-Choice Ordering
- [ ] Preview Fill in the Process
- [ ] Return directly to Editor after preview
- [ ] Preserve unsaved editing state
- [ ] Clearly distinguish Preview from normal player progression
- [ ] Prevent Preview sessions from changing player records

## Authoring Workflow

Implement the intended workflow:

```text
Create / Import
→ Validate
→ Preview
→ Play
→ Revise
→ Validate Again
→ Save / Publish
```

## Export

- [ ] Export editor content as JSON
- [ ] Export editor content as CSV where practical
- [ ] Preserve IDs and Skill Tags
- [ ] Validate before export
- [ ] Warn authors about unresolved content errors

## M6 Documentation

- [ ] Write a content-authoring guide
- [ ] Document supported math syntax
- [ ] Document Level Type behavior
- [ ] Document Skill Tag conventions
- [ ] Document validation errors
- [ ] Add example content
- [ ] Document Preview workflow

## M6 Validation

- [ ] Test authoring without manually editing project files
- [ ] Test malformed CSV imports
- [ ] Test duplicate IDs
- [ ] Test invalid expressions
- [ ] Test large content imports
- [ ] Confirm Teacher Preview does not affect progression
- [ ] Confirm edited Questions work in all supported gameplay modes
- [ ] Confirm exported data can be loaded back into MathSmith

### M6 Key Question

> **Can a content specialist create, validate, preview, and revise playable MathSmith content without engineering support?**

---

# M7 — Guided Smart Tutor & Final Polish

**Goal: Connect existing learning, progress, review, and analytics systems through a guided player-facing assistant.**

The Tutor should not replace MathSmith's deterministic mathematical systems.

It should help the player understand and navigate information already produced by those systems.

---

## Tutor Design Principles

- [ ] Keep core mathematics deterministic
- [ ] Keep scoring deterministic
- [ ] Keep progression deterministic
- [ ] Keep Question validation deterministic
- [ ] Use structured game state as Tutor context
- [ ] Do not allow the Tutor to invent player progress
- [ ] Do not allow the Tutor to invent mathematical correctness
- [ ] Prefer constrained choices over unrestricted chat for the first implementation
- [ ] Make Tutor actions transparent and reversible

## Option-Based Tutor

Create a guided, website-chatbot-style interaction rather than beginning with unrestricted free text.

Potential options:

```text
What should I practice?
Explain this game mode.
Why did I lose points?
Review my mistakes.
What am I good at?
What should I do next?
Open Mistake Book.
Practice a weak Skill.
Start Zen Mode.
```

Tasks:

- [ ] Create Tutor panel / screen
- [ ] Create reusable option buttons
- [ ] Create context-dependent option sets
- [ ] Add Back / Previous behavior
- [ ] Prevent irrelevant options from appearing
- [ ] Preserve normal navigation when Tutor closes

## Gameplay Rule Guidance

- [ ] Explain Step Ordering rules
- [ ] Explain Multiple-Choice Ordering rules
- [ ] Explain Fill in the Process rules
- [ ] Explain scoring
- [ ] Explain Stars
- [ ] Explain Hint limits
- [ ] Explain Needs Practice
- [ ] Explain Mistake Book
- [ ] Explain Zen Mode
- [ ] Explain Survival Mode

Reuse existing tutorial content where practical.

## Error Explanation

- [ ] Reuse deterministic Progressive Error Feedback
- [ ] Reuse stored Mistake Book explanations
- [ ] Show relevant mathematical rules
- [ ] Show correct reasoning steps when appropriate
- [ ] Avoid immediately revealing full solutions when the player is still actively solving
- [ ] Distinguish "Explain the rule" from "Show the answer"

## Performance Summary

Use M5 analytics and existing progress data to answer questions such as:

- [ ] What Skills are strongest?
- [ ] What Skills need more practice?
- [ ] Which gameplay interaction is most difficult?
- [ ] How has recent performance changed?
- [ ] What mistakes are repeated?
- [ ] How often are Hints required?

Keep summaries grounded in actual stored data.

## Practice Recommendations

- [ ] Recommend weak Skills
- [ ] Recommend relevant Levels
- [ ] Recommend Mistake Practice
- [ ] Recommend Zen Mode where appropriate
- [ ] Recommend standard Level replay
- [ ] Explain why a recommendation was made
- [ ] Allow the player to reject a recommendation
- [ ] Avoid creating one mandatory learning path

Example:

```text
Recommendation:
Practice Parentheses

Why:
Your recent Parentheses sessions have lower scores
and require more Hints than your other Skills.

[Practice Parentheses]
[Review Mistakes]
[Maybe Later]
```

## Guided Navigation

Allow Tutor options to navigate directly to:

- [ ] Relevant Level
- [ ] Lobby
- [ ] Mistake Book
- [ ] Mistake Practice
- [ ] Skill Mastery
- [ ] Player History
- [ ] Zen Mode
- [ ] Survival Mode
- [ ] Settings
- [ ] Tutorial

## Context Awareness

The Tutor should know appropriate structured context such as:

- [ ] Current screen
- [ ] Current Level
- [ ] Current gameplay interaction
- [ ] Current Question
- [ ] Remaining Hints
- [ ] Current Score
- [ ] Current Star projection where appropriate
- [ ] Recent incorrect attempts
- [ ] Stored Skill Mastery
- [ ] Mistake Book state
- [ ] Recent Player History

Do not expose internal developer data directly to the player.

## AI / Generative Extension

Only after the deterministic Tutor workflow is stable:

- [ ] Evaluate where generative explanations add real value
- [ ] Pass only structured validated context to the model
- [ ] Keep mathematical answers grounded in deterministic MathSmith data
- [ ] Constrain generated explanations to known Question state
- [ ] Add fallback deterministic responses
- [ ] Review generated language for developmental appropriateness
- [ ] Review generated language for pedagogical soundness
- [ ] Prevent hallucinated player history
- [ ] Prevent hallucinated rules or answers

## Localization

- [ ] Translate all remaining Tutor UI
- [ ] Support English
- [ ] Support Simplified Chinese
- [ ] Validate text expansion
- [ ] Validate terminology consistency across gameplay and Tutor responses

## Final UI / UX Polish

- [ ] Review hierarchy across all screens
- [ ] Standardize final spacing
- [ ] Standardize icon sizing
- [ ] Standardize interaction states
- [ ] Improve keyboard / focus behavior
- [ ] Review responsive behavior
- [ ] Review readability of complex expressions
- [ ] Review accessibility
- [ ] Review Tutorial UX
- [ ] Review Settings UX
- [ ] Review Mistake Book UX
- [ ] Review Skill Mastery UX
- [ ] Review History UX
- [ ] Review Tutor UX

## Final Audio / Feedback Polish

- [ ] Review all SFX levels
- [ ] Remove excessive repeated sounds
- [ ] Standardize correct / incorrect feedback
- [ ] Improve Level completion feedback
- [ ] Improve Star feedback
- [ ] Improve replay-mode feedback
- [ ] Add audio settings validation

## Final Content Review

- [ ] Re-play representative Questions from every Level
- [ ] Review generated reasoning
- [ ] Review distractor quality
- [ ] Review Fill blank quality
- [ ] Review localization
- [ ] Review tutorials
- [ ] Review mathematical terminology
- [ ] Review developmental appropriateness with subject-matter expertise

## Final Production Pass

- [ ] Remove debug-only UI
- [ ] Remove unused assets
- [ ] Remove obsolete code paths
- [ ] Clean warnings
- [ ] Review project naming
- [ ] Review folder organization
- [ ] Review Save migration
- [ ] Review documentation
- [ ] Update screenshots
- [ ] Update portfolio presentation
- [ ] Record final project demo
- [ ] Update README project status

### M7 Key Question

> **Can the systems MathSmith already understands about content, mistakes, progress, and player performance be turned into useful guidance without giving control of mathematical correctness to generative AI?**

---

# Roadmap Summary

| Milestone | Goal | Major Deliverables |
| --- | --- | --- |
| **M5 — Analytics & Adaptive Learning** | Understand player behavior and adapt practice | Telemetry, Skill Analysis, Skill Mastery, Adaptive Practice, Developer Analytics |
| **M6 — Content Authoring Pipeline** | Allow educators to create their own content | CSV Import, Validation, Visual Editor, Teacher Preview, Export |
| **M7 — Guided Smart Tutor & Final Polish** | Connect learning systems into guided support | Option-Based Tutor, Performance Summary, Recommendations, Navigation, Final Polish |

The overall progression is:

```text
M1 — Can the core idea work?
             ↓
M2 — Can it scale into a complete product flow?
             ↓
M3 — Can the framework support multiple interactions?
             ↓
M4 — Can it create a complete learning and replay loop?
             ↓
M5 — Can the system understand player performance?
             ↓
M6 — Can educators create content without engineering support?
             ↓
M7 — Can these systems guide the learner intelligently?
```
