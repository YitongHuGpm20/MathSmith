# MathSmith

**A data-driven educational math game about understanding the process—not just entering the answer.**

MathSmith is a Godot-based portfolio project created by **Yitong Hu** to demonstrate educational game technical design, gameplay design, UI/UX implementation, data-driven content development, rapid prototyping, and milestone-based project planning.

Players rebuild mathematical reasoning through three interaction types, receive progressively more useful feedback, review saved mistakes, and replay the full question pool through focused challenge modes.

> **Project Status:** M1–M4 Complete  
> **Engine:** Godot 4.7.1  
> **Target Resolution:** 1920 × 1080  
> **Languages:** English / Simplified Chinese

---

# Portfolio Presentation & Milestone Recordings

The portfolio presentation documents the design process, milestone strategy, iteration findings, and final implementation.

- [View MathSmith Portfolio Presentation](Docs/Presentation/MathSmith.pptx)
- [View MathSmith Portfolio Presentation Online](https://docs.google.com/presentation/d/1pEMtKXkR5GvK5Gaz90E30Xhha7ux3LYvIaGfRUnblSA/edit?usp=sharing)
- [M1 — Core Foundation Recording](Docs/Recordings/MathSmith_Demo_M1.mp4)
- [M2 — Content Expansion & UI Foundation Recording](Docs/Recordings/MathSmith_Demo_M2.mp4)
- [M3 — Gameplay Expansion & Polish Recording](Docs/Recordings/MathSmith_Demo_M3.mp4)
- [M4 — Learning Loop & Replayability Recording](Docs/Recordings/MathSmith_Demo_M4.mp4)

---

# Project Goals

MathSmith was designed around four goals:

- Teach the reasoning between a Question and its answer.
- Present mathematical transformations through readable, school-appropriate steps.
- Reuse one content source across multiple gameplay interactions.
- Build a complete learning loop with feedback, review, progression, and replayability.

The project was also used as a Technical Design exercise in building an extensible educational game system from a small playable prototype.

---

# Design Questions & Prototype Goals

Rather than beginning with a large feature list, MathSmith began with three questions covering **Design, Technical Design, and Production**.

## Design Question

**Can players practice mathematical reasoning by rebuilding the solution process instead of only submitting a final answer?**

Many math activities evaluate only the final result:

```text
Question
→ Answer
→ Correct / Incorrect
```

MathSmith instead explores:

```text
Question
→ Reasoning Process
→ Player Interaction
→ Feedback
→ Understanding
```

The design hypothesis was that intermediate mathematical transformations could become meaningful player actions rather than passive instructional text.

---

## Technical Question

**Can mathematical expressions automatically become reusable playable content?**

The technical goal was to minimize manually authored gameplay data.

Instead of storing a separate solution sequence for every Question and every gameplay interaction, MathSmith uses:

```text
Authored Expression
→ ExpressionParser
→ StepGenerator
→ Human-Readable Solution Process
→ Gameplay Interaction
```

The Question defines the mathematical problem.

The runtime systems determine how that problem becomes an interactive learning experience.

---

## Production Question

**Can the prototype remain complete and playable while its systems expand?**

Development was structured around vertical milestones.

Each milestone needed to leave behind:

- A complete player flow
- A stable playable build
- A build that could be playtested
- A build that could be demonstrated
- Clear findings that could guide the next milestone

This prevented the project from becoming a collection of partially completed systems.

---

# Pre-Production Framework

Before implementation, I use a lightweight planning process to define the experience, identify risk, understand available resources, and align dependencies.

The goal is not to completely design the final product before prototyping.

The goal is to understand **what needs to be proven first**.

---

## 1. Define the Experience

Before building, I establish several core questions:

### Player

- Who is the target player?
- What prior knowledge can I assume?
- What level of game familiarity can I assume?
- In what context will the experience be used?

### Learning Goal

- What should the player understand or practice?
- What behavior demonstrates that understanding?
- What information should remain hidden from the player?
- What assistance should the system provide?

### Interaction

- What are the player's primary verbs?
- What decisions does the player make?
- What is the core gameplay loop?
- What is the feedback loop?
- What creates meaningful challenge?

### Prototype

- What assumption am I trying to validate?
- What does the prototype need in order to answer that question?
- What does it explicitly not need yet?
- What defines success or failure?

For MathSmith, the initial question was not whether I could build menus, progression, localization, or save data.

The highest-risk assumption was:

> **Can generated mathematical reasoning be understandable and useful enough to become gameplay?**

That became the focus of M1.

---

# 2. Scope & Production Planning

Features are divided into three categories:

### Must Have

Required to validate the current design hypothesis.

### Should Have

Meaningfully improves the quality or completeness of the current vertical slice.

### Nice to Have

Potentially valuable, but not necessary until the core experience is stable.

I prioritize work based on:

```text
Risk
→ Dependency
→ Player Impact
→ Development Cost
```

The most uncertain or foundational systems are tested before lower-risk polish.

This also helps prevent technically interesting features from expanding the scope before the core player experience has been validated.

---

# 3. Resources & Constraints

Before implementation, I identify what already exists and what actually needs to be built.

This includes:

### Technology

- Engine
- Plugins
- Existing gameplay systems
- Existing UI systems
- Available libraries
- Version control
- Development tools
- AI-assisted development tools

### Content

- Existing curriculum or learning content
- Content format
- Content ownership
- Authoring workflow
- Validation requirements
- Localization requirements

### Presentation

- Existing UI assets
- Icons
- Art
- Animation
- Audio
- Typography
- Visual guidelines

### Production

- Available development time
- Team size
- Team expertise
- Technical constraints
- External dependencies
- Delivery requirements

For MathSmith, I intentionally reused lightweight external resources such as Lucide icons and Kenney sound effects so development time could remain focused on gameplay, educational systems, data architecture, and interaction quality.

---

# 4. Cross-Functional Alignment

In a multidisciplinary production environment, Technical Design often sits between several disciplines.

Before implementation, I would align with each discipline on the questions that affect the system.

| Discipline | Key Questions |
| --- | --- |
| **Game Design** | What player behavior and experience are we targeting? |
| **Pedagogy / Content** | What should the player learn, and what constitutes an appropriate learning process? |
| **Engineering** | What should be systemic, reusable, data-driven, or engine-level? |
| **UX / UI** | How should interaction states, hierarchy, feedback, and accessibility be communicated? |
| **Art / Animation** | What visual feedback supports the instructional and gameplay intent? |
| **Product** | What user outcome and product requirement does the experience serve? |
| **Production** | What is the scope, dependency order, risk, schedule, and Definition of Done? |

The goal is to establish a shared understanding of:

```text
What are we building?
Why are we building it?
What needs to be systemic?
What needs to be authored?
Who owns each dependency?
What does "done" mean?
```

This reduces implementation ambiguity and helps Technical Design translate intent between disciplines.

---

# My Role

**Educational Game Technical Designer / Game Designer / Project Planner**

I designed and implemented:

- Core gameplay rules and interaction flows
- Data-driven Level and Question architecture
- Mathematical expression parsing
- Procedural Step generation
- Educational feedback and Hint systems
- Scoring and progression
- Mistake review and practice systems
- Home, Lobby, gameplay, Settings, and review UI/UX
- Local Save
- Localization
- Replay modes
- Milestone scope
- Development order
- Testing priorities
- Iteration plans
- Technical architecture and refactoring decisions

---

# Milestone Strategy — Vertical, Not Siloed

MathSmith was intentionally developed through **vertical milestones** rather than discipline-specific production phases.

I did not approach development as:

```text
Build All Gameplay
→ Build All Content
→ Build All UI
→ Add Progression
→ Test Everything
```

Instead, each milestone expanded multiple parts of the experience while preserving a complete player journey.

| Milestone | Goal | Primary Question |
| --- | --- | --- |
| **M1 — Prove** | Prove the core gameplay | Does rebuilding a solution process work as gameplay? |
| **M2 — Scale** | Build a complete playable flow | Can the system support larger content and a complete product flow? |
| **M3 — Extend** | Prove framework extensibility | Can the same content pipeline support different learning interactions? |
| **M4 — Complete** | Complete the learning loop | Can progression, review, persistence, and replay create a complete experience? |

Each milestone intentionally touched several areas:

```text
Gameplay
+
Systems
+
Content
+
UI / UX
+
Testing
```

rather than completing one discipline in isolation.

## Milestone Rule

Every milestone should end with:

- A complete player journey
- A stable playable build
- Something that can be playtested
- Something that can be presented
- A clear set of findings
- A foundation for the next milestone

This allows design decisions to respond to actual player experience before too much dependent work is built.

---

# Core Experience

MathSmith uses the following learning loop:

```text
Choose Content
→ Rebuild the Solution Process
→ Receive Progressive Feedback
→ Earn Score and Stars
→ Save Progress
→ Review Mistakes
→ Practice Again
→ Replay Through Challenge Modes
```

The project currently contains:

- **12 Levels**
- **90 authored Questions**
- **3 core gameplay interactions**
- **Mistake Practice**
- **Zen Mode**
- **Survival Mode**
- **English and Simplified Chinese localization**
- **Versioned Local Save data**

Because the same authored Question content can be reused across multiple interactions and replay systems, the number of playable Question experiences is significantly larger than the authored Question count.

---

# Core Gameplay Interactions

## 1. Step Ordering

Players drag complete solution steps into the correct order.

The interaction emphasizes:

- Sequence
- Mathematical transformation
- Understanding how one step leads to another

The player is reconstructing an existing reasoning process.

---

## 2. Multiple-Choice Ordering

Players select the correct next step from a set of plausible alternatives.

Incorrect options are generated deterministically and filtered to avoid equivalent or accidentally correct answers.

This interaction changes the player verb from:

```text
Reconstruct
```

to:

```text
Recognize + Select
```

while still consuming the same generated mathematical process.

---

## 3. Fill in the Process

Players complete missing values inside a generated solution process.

Instead of identifying the entire next step, the player focuses on the arithmetic connecting one transformation to another.

This interaction emphasizes:

```text
Recall + Apply
```

---

# Shared Gameplay Architecture

All three gameplay interactions reuse:

- Level data
- Question expressions
- `ExpressionParser`
- `StepGenerator`
- Correct solution process
- Skill Tags
- Scoring framework
- Hint budgets
- Progressive feedback framework

The architecture is therefore:

```text
Question Data
      ↓
ExpressionParser
      ↓
StepGenerator
      ↓
Correct Mathematical Process
      ↓
 ┌───────────────┬─────────────────────┬─────────────────────┐
 ↓               ↓                     ↓
Step Ordering    Multi-Choice          Fill in the Process
```

A change to the mathematical content or Step generation can therefore improve multiple gameplay interactions without maintaining separate Question libraries.

---

# Learning & Feedback Design

## Progressive Error Feedback

MathSmith intentionally avoids immediately explaining the solution after the player's first mistake.

Automatic feedback becomes progressively more informative across repeated incorrect attempts.

### First Incorrect Attempt

Generic retry feedback.

The player knows the answer is incorrect but retains the opportunity to solve the problem independently.

### Second Incorrect Attempt

Directional feedback.

The system identifies the mathematical area the player should reconsider.

### Third and Later Incorrect Attempts

Contextual rule explanation.

The system explains the relevant mathematical principle without simply giving the complete solution.

The progression is:

```text
Try Again
→ Direction
→ Explanation
```

This creates room for productive struggle while still preventing the player from becoming permanently stuck.

---

## Hints vs. Error Feedback

Automatic error feedback and player-requested Hints are intentionally separate systems.

**Error Feedback** responds to player behavior.

**Hints** represent an explicit request for assistance.

This distinction allows Hint usage to become meaningful gameplay and progression data rather than simply another form of automatic correction.

Hint availability is limited per Level and becomes more generous as Level complexity increases.

---

# Mistake Book

A Question is saved when the player:

- Makes repeated incorrect attempts
- Uses a Hint

Each Mistake Book entry stores:

- Original expression
- Source Level
- Gameplay interaction
- Skill Tags
- Reason the Question was saved
- Deterministic mathematical explanation
- Complete correct solution process

The Mistake Book turns failure into future practice content.

---

# Mistake Practice

Mistake Practice creates a randomized session using up to 10 unique Mistake Book entries.

Each Question retains the gameplay interaction in which it was originally recorded.

The loop becomes:

```text
Make Mistake
→ Save Mistake
→ Review Explanation
→ Practice Again
```

This allows mistakes to become part of the long-term learning loop rather than temporary feedback.

---

# Replay Modes

## Zen Mode

A three-minute mixed-mode session using the complete Question pool.

The mode:

- Randomizes Questions
- Randomizes gameplay interactions
- Prevents immediate Question repetition
- Tracks solved Questions
- Tracks accuracy
- Saves the player's best solved count

Zen Mode creates a lightweight replay loop focused on speed and continued practice.

---

## Survival Mode

An untimed mixed-mode session with three shared lives.

Every incorrect submission or incorrect option removes one life.

The mode continues until all lives are lost.

It records the player's highest solved Question count.

Survival Mode creates a different pressure profile from Zen Mode:

```text
Zen
→ Time Pressure

Survival
→ Accuracy Pressure
```

---

# Milestone Development

# M1 — PROVE

**Goal: Prove the core gameplay**

## Core Systems

- Established the Godot project structure
- Built the Home → Lobby → Game flow
- Implemented JSON content loading and validation
- Implemented `ExpressionParser`
- Implemented `StepGenerator`
- Built the initial `GameManager` gameplay loop

## Gameplay

- Step Ordering
- Drag-and-drop Step Cards
- Check
- Hint
- Next Question
- Correct and incorrect feedback
- Question progression

## UI / UX

- Initial Home Scene
- Initial Lobby Scene
- Initial Game Scene
- Reusable Level Card
- Reusable Step Card
- Basic navigation

## Result

M1 proved the core pipeline:

```text
Expression
→ Generated Solution Steps
→ Interactive Step Ordering
→ Validation
→ Feedback
```

The core learning mechanic was viable enough to continue development.

---

# M2 — SCALE

**Goal: Build a complete playable flow**

## Content & Systems

- Expanded content to 12 Levels and 90 Questions
- Expanded Question difficulty across Levels
- Improved generated solution steps
- Added flexible three-to-five-step and longer solution processes
- Improved classroom-style reasoning strategies

## Product Flow

- Data-driven Level selection
- Home
- Lobby
- Game
- End Menu
- Settings entry point
- Credits
- Exit flow

## UI / UX

- Established the 1920 × 1080 presentation
- Created the dark educational-technology visual language
- Standardized cards
- Standardized buttons
- Standardized spacing
- Standardized typography
- Added responsive behavior
- Added local Lucide icons
- Added local UI SFX

## Content Improvements

- Removed trivial two-single-digit Questions
- Removed unnecessary `+ 0`
- Removed unnecessary single-number parentheses
- Improved make-ten strategies
- Improved decomposition
- Improved regrouping
- Improved order-of-operations presentation
- Reduced excessive mental calculation inside individual steps

## Result

M2 demonstrated that the prototype could scale from a gameplay test into a data-driven product flow without abandoning the original content architecture.

---

# M3 — EXTEND

**Goal: Prove the gameplay framework is extensible**

## New Gameplay Interactions

- Multiple-Choice Ordering
- Fill in the Process

## Shared Systems

All three interactions reuse:

- Question content
- Expression parsing
- Step generation
- Skill Tags
- Feedback
- Hint framework

## New Features

- Progressive Error Feedback
- Lobby search
- Level filtering
- Skill filtering
- Question and expression search

## Interaction Improvements

- Whole-card dragging
- Dynamic Step Card reordering
- Larger draggable areas
- Unified expression alignment
- Improved spacing
- Improved Fill input presentation
- Up to five visible Step Cards

## Stability Improvements

- Fixed rapid-Hint card overlap
- Fixed repeated-Check validation
- Fixed option lifecycle issues
- Locked options after correct answers
- Separated completion records by gameplay interaction

## Result

M3 demonstrated that the mathematical content system was not tied to one interaction.

The same generated reasoning could support multiple player verbs without duplicating the Question library.

---

# M4 — COMPLETE

**Goal: Complete the learning loop and improve replayability**

## Progression

- Question Score
- Level Score
- Star ratings
- Limited Hints
- Level Complete
- Needs Practice
- Session Summary

## Player Support

- First-time tutorials
- Reusable Settings
- English / Simplified Chinese localization
- Versioned Local Save

## Review

- Mistake Book
- Mistake explanations
- Complete correct solution display
- Mistake Practice

## Replay

- Zen Mode
- Survival Mode
- Persistent personal bests

## UI / UX

- Level progress bar
- Best-star display
- Score feedback animation
- Remaining Hint display
- Zen timer
- Final-ten-second warning
- Survival life display
- Mistake Book screen
- Secondary feature cards
- Improved Settings
- Improved Credits

## Architecture

- Split UI into `Screens` and `Components`
- Extracted `ProgressManager`
- Extracted `MistakeBookManager`
- Extracted `ZenModeManager`
- Extracted `SurvivalModeManager`
- Extracted `ChoiceGenerator`
- Reorganized `GameManager` by responsibility

## Result

M4 transformed the prototype from:

```text
Play
→ Finish
```

into:

```text
Play
→ Feedback
→ Score
→ Progress
→ Review
→ Practice
→ Replay
```

This completed the first full learning loop.

---

# Playtest → Learn → Iterate

One of the most important findings during development was:

> **Mathematically correct does not necessarily mean pedagogically useful.**

This became a major design and Technical Design lesson from the project.

---

## Initial Problem

Early versions of `StepGenerator` could produce mathematically valid transformations that did not resemble how a student or teacher would naturally reason through the problem.

Playtesting exposed several categories of problems:

- Unnatural decomposition
- Redundant transformations
- Unnecessary parentheses
- Artificial intermediate steps
- Large reasoning jumps
- Too much mental arithmetic inside one step
- Division processes that were mathematically valid but pedagogically unclear

These were not traditional calculation bugs.

The final answer could still be correct.

The problem was the **quality of the reasoning presented to the player**.

---

## Initial Generation Goal

The early system placed too much emphasis on producing enough intermediate steps.

Conceptually:

```text
Expression
→ Generate Valid Transformations
→ Reach Desired Step Count
→ Final Answer
```

This occasionally created transformations whose primary purpose was satisfying the generator rather than helping the learner.

---

## Revised Generation Goal

The goal was changed to:

> **Generate the minimum number of meaningful, human-readable reasoning steps required to explain the transformation.**

This changed the priority from:

```text
Step Quantity
```

to:

```text
Reasoning Quality
```

---

# Iteration Loop

The development loop became:

```text
Build
↓
Playtest
↓
Observe Unexpected Reasoning
↓
Classify the Problem
↓
Adjust Generation Rules
↓
Adjust Example Content When Necessary
↓
Replay Across Question Types
↓
Stabilize
```

Playtesting was intentionally performed after implementing each new gameplay interaction.

The reason was that the same generated mathematical content could expose different problems depending on how the player interacted with it.

A Step sequence that looked acceptable when read passively might become confusing when:

- Dragged into order
- Selected one step at a time
- Used as the structure for Fill in the Process

---

# Resulting StepGenerator Rules

Iteration produced several generation principles:

- Avoid meaningless `+ 0`
- Avoid unnecessary parentheses around single values
- Prefer recognizable make-ten strategies
- Prefer meaningful decomposition
- Prefer meaningful regrouping
- Respect operation precedence
- Avoid excessive mental arithmetic within one step
- Avoid transformations that exist only to increase step count
- Avoid unnecessarily large reasoning jumps
- Prefer readable intermediate states
- Allow different Questions to naturally require different numbers of steps

The generator therefore evolved from:

> A system that produces mathematically valid transformations

toward:

> A system that attempts to produce readable instructional reasoning.

---

# Educational Design Approach

MathSmith does not simply reduce every expression directly to its final value.

`StepGenerator` creates intermediate transformations intended to resemble recognizable classroom strategies.

These include:

- Making ten
- Decomposing by place value
- Regrouping addends
- Partial products
- Division decomposition
- Parentheses
- Operation precedence
- Multi-step expression reduction

For example:

```text
8 + 5 + 7

= 8 + (2 + 3) + 7
= (8 + 2) + (3 + 7)
= 10 + 10
= 20
```

The educational design goal is not to maximize the number of visible steps.

It is to expose enough reasoning for the learner to understand **why the expression changes from one state to the next**.

---

# Key Design Decisions & Tradeoffs

## 1. Shared Content Instead of Mode-Specific Question Libraries

### Decision

All three core gameplay interactions consume the same Question content and generated solution process.

### Why

Maintaining separate Question libraries would create duplicated content and increase the cost of:

- Content editing
- QA
- Localization
- Mathematical corrections
- Future gameplay expansion

### Tradeoff

Gameplay interactions must adapt to a shared mathematical representation instead of defining completely independent Question formats.

### Result

```text
One Question
→ One Correct Process
→ Multiple Gameplay Interactions
```

---

# 2. Procedural Steps Instead of Manually Authored Solutions

### Decision

Store mathematical expressions in content data and generate solution processes at runtime.

### Why

Manually authoring every solution process would increase content cost and make large-scale iteration difficult.

### Tradeoff

`StepGenerator` becomes a critical system that requires substantial testing because mathematically valid output may still be pedagogically poor.

### Result

Content remains lightweight while generation rules remain centralized and reusable.

---

# 3. Progressive Feedback Instead of Immediate Explanation

### Decision

Do not reveal the relevant mathematical rule after the player's first mistake.

### Why

Immediate explanation can remove the opportunity for productive struggle.

### Feedback Escalation

```text
Incorrect Attempt 1
→ Retry

Incorrect Attempt 2
→ Direction

Incorrect Attempt 3+
→ Rule Explanation
```

### Tradeoff

Players may require multiple attempts before receiving detailed support.

The separate Hint system provides an explicit escape route when the player wants assistance sooner.

---

# 4. Hints as a Limited Resource

### Decision

Hints are limited per Level rather than unlimited.

### Why

Hints should support learning without becoming the default solution strategy.

The budget increases as Levels become more complex.

### Tradeoff

Hint limits must remain generous enough that the system does not punish players for requesting help.

The design therefore favors relatively forgiving limits.

---

# 5. Deterministic Feedback Instead of Runtime LLM Responses

### Decision

Error explanations, Hints, distractors, and mathematical transformations are deterministic and rule-based.

### Why

Mathematical learning feedback should remain:

- Predictable
- Testable
- Fast
- Reproducible
- Pedagogically controllable

### Tradeoff

Feedback is less conversational than a generative tutor.

However, every output can be validated against known rules.

No LLM is currently used at runtime.

---

# 6. Versioned Save Data

### Decision

Persistent data uses an explicit schema version.

### Why

The project accumulated multiple persistent systems during M4:

- Settings
- Progress
- Stars
- Scores
- Mistake Book
- Tutorials
- Replay records

Future milestones may change their structure.

### Result

Older save data can be migrated or repaired instead of automatically becoming invalid.

---

# 7. Replay Modes Do Not Modify Standard Level Progress

### Decision

Zen Mode, Survival Mode, and Mistake Practice maintain independent session behavior and records.

### Why

Replay modes serve different learning and motivational purposes from structured Level progression.

Players should be able to experiment in replay modes without accidentally changing their standard Level records.

---

# Technical Architecture

```text
MathSmith/
├── Assets/
│   ├── Icons/
│   └── SFX/
├── Data/
│   └── SampleLevels.json
├── Localization/
├── Scenes/
│   └── Menus/
├── Scripts/
│   ├── Gameplay/
│   │   ├── GameManager.gd
│   │   ├── LevelLoader.gd
│   │   ├── SaveManager.gd
│   │   ├── ProgressManager.gd
│   │   ├── MistakeBookManager.gd
│   │   ├── ZenModeManager.gd
│   │   └── SurvivalModeManager.gd
│   ├── Math/
│   │   ├── ExpressionParser.gd
│   │   ├── StepGenerator.gd
│   │   └── ChoiceGenerator.gd
│   └── UI/
│       ├── Screens/
│       └── Components/
└── Themes/
```

---

# Architectural Principles

## Content Is the Source of Truth

JSON is the single source of truth for Level and Question content.

```text
JSON
→ Runtime Content
→ Math Systems
→ Gameplay
```

---

## Content Is Separate from Presentation

Mathematical content does not define how it must be presented.

The same Question can therefore support multiple gameplay interactions.

---

## Mathematical Logic Is Separate from UI

`ExpressionParser`, `StepGenerator`, and `ChoiceGenerator` operate independently from screen presentation.

This allows mathematical systems to evolve without tightly coupling them to a specific interface.

---

## Managers Have Focused Responsibilities

As the project expanded, responsibilities were extracted from `GameManager`.

Examples include:

- `ProgressManager`
- `MistakeBookManager`
- `ZenModeManager`
- `SurvivalModeManager`

This reduces the responsibility of the central gameplay controller as systems become more complex.

---

## Persistent Systems Are Versioned

Save data contains an explicit schema version.

Older data can therefore be migrated or repaired as systems evolve.

---

## Replay Is Isolated from Structured Progress

Replay modes do not overwrite standard Level progression.

---

## Learning Logic Is Deterministic

Error explanations, mathematical transformations, and distractors are rule-based.

No runtime LLM is required for the current learning experience.

---

# Save Data

MathSmith stores local progress through Godot's `user://` directory:

```text
user://mathsmith_save.json
```

The current Save schema stores:

- Settings
- Language
- Mode-specific Level progress
- Best scores
- Best stars
- Mistake Book entries
- Tutorial state
- Zen Mode best result
- Survival Mode best result
- Reserved Skill Progress data
- Reserved Player History data

Interrupted Levels do not save partial Question progress.

Reset Progress removes progression data while preserving user settings.

---

# Future Development

The current M1–M4 build establishes the core learning, content, progression, and replay architecture.

Future milestones would explore systems that build on this foundation rather than expanding the core prototype indefinitely.

---

## M5 — Analytics & Adaptive Learning

**Goal: Observe player behavior and adapt practice**

Potential systems:

- Behavior tracking
- Time-to-first-action
- Total Question time
- Move / reorder behavior
- Submission count
- Hint usage
- Skill-level performance analysis
- Error pattern analysis
- Skill Mastery
- Weak Skill identification
- Adaptive Practice recommendations
- Weighted Question selection
- Developer / Analytics Overlay

The purpose of this milestone would be to answer:

> **What can player behavior tell us about where the learner is struggling?**

---

## M6 — Content Authoring Pipeline

**Goal: Allow educators and content specialists to create and validate content**

Potential systems:

- Downloadable CSV template
- CSV upload
- CSV validation
- Human-readable validation errors
- CSV → Runtime Level Data
- Visual Content Editor
- Add / delete / edit Questions
- Teacher Preview Mode
- Editor → Preview → Revise workflow

The purpose would be to move content creation away from direct project-file editing.

The target workflow would become:

```text
Author
→ Validate
→ Preview
→ Play
→ Revise
→ Publish
```

---

## M7 — Guided Smart Tutor & Final Polish

**Goal: Connect existing systems into a guided learning experience**

A future MathSmith Tutor could help the player:

- Understand gameplay rules
- Interpret repeated mistakes
- Review performance
- Identify weak Skills
- Navigate to relevant Levels
- Open Mistake Practice
- Start Zen practice
- Choose context-aware next actions

The Tutor would be introduced after deterministic learning systems, player history, and content architecture are established.

This allows AI-assisted guidance to operate on structured and validated learning data rather than replacing the underlying educational systems.

---

# Key Learnings

## Design for Iteration

Build the smallest complete experience first.

Validate it.

Then expand.

---

## Separate Content from Presentation

Reusable content architecture made it possible to add new gameplay interactions without creating independent Question libraries.

---

## Test Meaning, Not Only Correctness

A system can be technically correct and mathematically correct while still producing a poor learning experience.

Playtesting must evaluate:

```text
Correctness
+
Readability
+
Intent
+
Player Understanding
```

---

## Keep Every Milestone Playable

A playable milestone creates something that can be:

- Tested
- Reviewed
- Demonstrated
- Evaluated
- Changed

before too many dependent systems are built.

---

## Build Systems Around Real Findings

Several of MathSmith's most important design changes came from actually playing generated content rather than predicting every problem during planning.

The project therefore follows:

```text
Plan
→ Build
→ Play
→ Observe
→ Adjust
→ Stabilize
→ Expand
```

rather than treating design documentation as a fixed specification.

---

# Running the Project

1. Install Godot 4.7.1 or a compatible Godot 4.x version.
2. Clone this repository.
3. Import `project.godot` through the Godot Project Manager.
4. Run the project from `HomeScene`.

The project is configured for a 1920 × 1080 viewport with responsive `canvas_items` stretching.

---

# Controls

- **Mouse:** Navigate UI, choose options, and drag Step Cards
- **Check:** Validate Step Ordering or Fill in the Process
- **Hint:** Request limited mode-specific assistance
- **Next:** Advance after completing a Question

---

# Credits

- **Design and Development:** Yitong Hu
- **Sound Effects:** Kenney
- **Icons:** Lucide
- **Engine:** Godot

---

# License

This repository is currently presented as a personal portfolio project.

Third-party assets remain subject to their respective licenses.
