# MathSmith

**A data-driven educational math game about understanding the process—not just entering the answer.**

MathSmith is a Godot-based portfolio project created by **Yitong Hu** to demonstrate educational game technical design, gameplay design, UI/UX implementation, data-driven content development, and milestone-based project planning.

Players rebuild mathematical reasoning through three interaction types, receive progressively more useful feedback, review saved mistakes, and replay the full question pool through focused challenge modes.

> Project status: **M1–M4 complete**  
> Engine: **Godot 4.7.1**  
> Target resolution: **1920 × 1080**  
> Languages: **English and Simplified Chinese**

## Portfolio Presentation and Milestone Recordings

The presentation and milestone recordings were added to the following locations:

- [View MathSmith Portfolio Presentation](Docs/Presentation/MathSmith.pptx)
- [View MathSmith Portfolio Presentation online](https://docs.google.com/presentation/d/1pEMtKXkR5GvK5Gaz90E30Xhha7ux3LYvIaGfRUnblSA/edit?usp=sharing)
- [M1 — Core Foundation Recording](Docs/Recordings/MathSmith_Demo_M1.mp4)
- [M2 — Content Expansion & UI Foundation Recording](Docs/Recordings/MathSmith_Demo_M2.mp4)
- [M3 — Gameplay Expansion & Polish Recording](Docs/Recordings/MathSmith_Demo_M3.mp4)
- [M4 — Learning Loop & Replayability Recording](Docs/Recordings/MathSmith_Demo_M4.mp4)

> These links are reserved for the final media files and will become active once the presentation and recordings are added.

## Project Goals

MathSmith was designed around four goals:

- Teach the reasoning between a question and its answer.
- Present mathematical transformations in school-appropriate steps.
- Reuse one content source across multiple gameplay interactions.
- Build a complete learning loop with feedback, review, progress, and replayability.

## My Role

**Educational Game Technical Designer / Game Designer / Project Planner**

I designed and implemented:

- Core gameplay rules and interaction flows
- Data-driven Level and Question architecture
- Mathematical expression parsing and Step generation
- Educational feedback, Hint, scoring, and review systems
- Home, Lobby, gameplay, Settings, and review UI/UX
- Local Save and bilingual localization systems
- Milestone scope, development order, testing priorities, and iteration plans

## Core Experience

MathSmith uses the following learning loop:

```text
Choose Content
→ Rebuild the Solution Process
→ Receive Progressive Feedback
→ Earn Score and Stars
→ Save Progress
→ Review Mistakes
→ Replay Through Practice Modes
```

The project currently contains:

- **12 Levels**
- **90 Questions**
- **3 core gameplay interactions**
- **4 secondary learning and replay features**
- **English and Simplified Chinese localization**
- **Versioned Local Save data**

## Core Gameplay Interactions

### Step Ordering

Players drag complete solution steps into the correct order. The interaction emphasizes the structure and sequence of a mathematical process.

### Multiple-Choice Ordering

Players select the correct next step from a set of plausible alternatives. Incorrect options are generated deterministically and filtered to avoid equivalent answers.

### Fill in the Process

Players complete missing values inside a generated solution process. This mode focuses attention on the arithmetic connecting one transformation to the next.

All three interactions reuse the same Level data, expressions, generated correct steps, scoring rules, Hint budget, and progressive feedback framework.

## Learning and Replay Features

### Progressive Error Feedback

Feedback becomes more informative across consecutive incorrect attempts:

1. Generic retry guidance
2. Directional feedback about the relevant mathematical area
3. Contextual explanation of the violated rule

The automatic feedback system remains separate from player-requested Hints.

### Mistake Book

A Question is saved when the player makes repeated incorrect attempts or uses a Hint. Each saved entry includes:

- Original expression
- Source Level and gameplay interaction
- Skill tags
- Reason it was saved
- Deterministic mathematical explanation
- Complete correct solution process

### Mistake Practice

Creates a randomized practice session using up to 10 unique Mistake Book entries. Each Question retains the gameplay interaction in which it was originally recorded.

### Zen Mode

A three-minute mixed-mode session using the complete Question pool. It tracks solved Questions, accuracy, and the player's best solved count while preventing immediate Question repetition.

### Survival Mode

An untimed mixed-mode session with three shared lives. Every incorrect submission or incorrect option removes one life. The session saves the player's best solved count.

## Milestone Development

### M1 — Core Foundation

#### Core Systems

- Established the Godot project structure and Home → Lobby → Game flow
- Implemented JSON content loading and validation
- Implemented `ExpressionParser` and `StepGenerator`
- Built the initial `GameManager` gameplay loop

#### New Features

- Step Ordering gameplay
- Drag-and-drop Step Cards
- Check, Hint, and Question progression
- Basic correct and incorrect feedback

#### UI / UX

- Initial Home, Lobby, and Game scenes
- Reusable Level Card and Step Card components
- Basic navigation between all primary scenes

#### Fixes and Optimization

- Resolved initial scene and resource reference problems
- Fixed Step Card setup and answer validation issues
- Established consistent script, file, function, and variable naming

### M2 — Content Expansion & UI Foundation

#### Core Systems

- Expanded the shared content schema to 12 Levels and 90 Questions
- Improved generated solution steps to match recognizable classroom strategies
- Added flexible three-to-five-step and longer solution processes

#### New Features

- Data-driven Level selection
- Expanded Home, Lobby, Game, Settings, and Credits navigation
- Local UI sound effects
- Local Lucide icon library

#### UI / UX

- Established the 1920 × 1080 dark educational-technology visual language
- Standardized cards, buttons, spacing, typography, and responsive behavior
- Redesigned HomeScene and LobbyScene

#### Fixes and Optimization

- Removed trivial two-single-digit questions and unnecessary `+ 0` steps
- Removed unnecessary single-number parentheses
- Refined make-ten, decomposition, regrouping, and order-of-operations steps
- Fixed Theme parsing and moved-resource reference errors

### M3 — Gameplay Expansion & Polish

#### New Features

- Multiple-Choice Ordering
- Fill in the Process
- Progressive Error Feedback
- Lobby search and filtering

#### Extended Features

- Shared Question content across all three gameplay interactions
- Mode-specific deterministic Hint behavior
- Search across Levels, Skills, Question IDs, and expressions

#### UI / UX

- Unified presentation across all three interactions
- Improved expression alignment, input spacing, and wide-screen readability
- Supported up to five visible Step Cards at the target resolution

#### Fixes and Optimization

- Reworked drag behavior so the entire selected card follows the pointer
- Added dynamic Step Card reordering
- Fixed rapid-Hint overlap and repeated-Check validation problems
- Locked interactive options after a correct answer
- Separated completion records by gameplay interaction

### M4 — Learning Loop & Replayability

#### New Features

- Question and Level scoring
- Best-score and star-rating persistence
- Shared limited Hint budgets
- Level Complete and Needs Practice results
- Session Summary
- First-time interaction tutorials
- English and Simplified Chinese localization
- Versioned Local Save system

#### Extended Features

- Mistake Book with explanations and correct answers
- Randomized Mistake Practice
- Three-minute Zen Mode
- Three-life Survival Mode
- Persistent replay records

#### UI / UX

- Level progress bar and best-star display
- Score icon and score-gain animation
- Remaining Hint display
- Zen timer with final-ten-second warning
- Survival life display
- Reusable Settings and Mistake Book screens
- Other category for secondary learning and replay features

#### Fixes and Optimization

- Prevented interrupted Levels from saving partial progress
- Improved Hint availability and rapid-animation safety
- Fixed incorrect cross-mode progress sharing
- Added old-save migration and missing-section recovery
- Reorganized UI scripts into `Screens` and `Components`
- Extracted focused progress, Mistake Book, Zen, Survival, and choice-generation services

## Educational Design Approach

MathSmith does not simply reduce every expression to its final value. `StepGenerator` creates intermediate transformations intended to resemble strategies used in real classrooms, including:

- Making ten
- Decomposing by place value
- Regrouping addends
- Partial products
- Division decomposition
- Parentheses and operation precedence
- Multi-step expression reduction

For example:

```text
8 + 5 + 7
= 8 + (2 + 3) + 7
= (8 + 2) + (3 + 7)
= 10 + 10
= 20
```

## Technical Architecture

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

### Architectural Principles

- JSON is the single source of truth for Level and Question content.
- Gameplay interactions consume the same generated correct process.
- Gameplay logic remains separate from visual presentation.
- Persistent systems use a versioned Save schema.
- Replay modes do not overwrite standard Level progress.
- Error explanations and distractors are deterministic and rule-based.
- No LLM is used at runtime.

## Running the Project

1. Install Godot 4.7.1 or a compatible Godot 4.x version.
2. Clone this repository.
3. Import `project.godot` through the Godot Project Manager.
4. Run the project from `HomeScene`.

The project is configured for a 1920 × 1080 viewport with responsive `canvas_items` stretching.

## Controls

- **Mouse:** Navigate UI, choose options, and drag Step Cards
- **Check:** Validate Step Ordering or Fill in the Process
- **Hint:** Request limited mode-specific assistance
- **Next:** Advance after completing a Question

## Save Data

MathSmith stores local progress through Godot's `user://` directory:

```text
user://mathsmith_save.json
```

The current Save schema stores:

- Settings and language
- Mode-specific Level progress
- Best scores and stars
- Mistake Book entries
- Tutorial state
- Zen Mode best result
- Survival Mode best result
- Reserved Skill Progress and Player History sections

## Credits

- **Design and Development:** Yitong Hu
- **Sound Effects:** [Kenney](https://kenney.nl/)
- **Icons:** [Lucide](https://lucide.dev/)
- **Engine:** [Godot](https://godotengine.org/)

## License

This repository is currently presented as a personal portfolio project. Third-party assets remain subject to their respective licenses.
