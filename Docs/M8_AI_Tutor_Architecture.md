# M8 Conversational AI Tutor Architecture

## M8.1 Boundary

M8.1 adds an AI-ready context and provider boundary without adding chat UI,
networking, voice, proactive intervention, or a production AI dependency.

The deterministic authority chain remains:

```text
ExpressionParser / StepGenerator -> mathematical truth
Score / Progress systems          -> progression truth
M5 Learning systems              -> analytics and Mastery truth
CourseManager                    -> Course/content truth
M7 Tutor                         -> deterministic guidance and fallback
M8 provider                      -> optional conversational wording only
```

## Runtime Flow

```text
GameManager.GetTutorContext()
    -> M7 TutorContextProvider course-scoped snapshot
    -> TutorAIContextBuilder whitelist and data minimization
    -> TutorAIManager
        -> session-only TutorConversationManager
        -> swappable TutorAIProvider
        -> MockTutorAIProvider during development

Any unavailable or invalid provider result
    -> untouched M7 deterministic Tutor page
```

M8 does not modify TutorPanel in this checkpoint. The option-based M7 Tutor
continues to be the only player-facing implementation.

## Provider Contract

Providers implement:

```text
GetProviderId()
IsAvailable()
RequestResponse(ai_context, conversation, user_message)
```

Normalized results contain `success`, `providerId`, `tutorText`, `intent`,
`suggestedAction`, `fallbackRequired`, and `errorCode`. Provider actions are
proposals only. A later checkpoint must validate them through MathSmith's M7
navigation boundary before showing or executing anything.

## Context Sent to a Future Provider

`TutorAIContextBuilder` uses a strict whitelist. It may include:

- current Course Source ID, display name, availability, and preview state;
- current screen, session type, Level summary, gameplay mode, and Question;
- expression and Skill Tags;
- recorded score, attempts, Hints, and Progressive Feedback state;
- relevant Skill Mastery summaries;
- at most three relevant History records;
- at most three relevant Mistake Book records;
- one existing deterministic recommendation;
- limited M5 behavior evidence;
- currently available M7 action IDs and labels;
- active locale.

The full save file, unrelated Course data, filesystem paths, authored Course
collections, and debug state are not included.

## Active Question Safety

The validated process is included only when the Question is completed or the
session is Teacher Preview. While a player Question is unsolved,
`canRevealValidatedProcess` is false and `validatedProcess` is empty. This
preserves the existing Hint and Progressive Error Feedback philosophy.

## Course Isolation

M8 starts from the already course-scoped M7 snapshot. The AI builder performs a
second boundary check on History and Mistake records when they contain a
`courseSourceId`. Conversation memory resets whenever `sourceId` changes.
Teacher Preview continues to suppress player learning data and player writes.

## Conversation Memory

Memory is limited to 12 messages, exists only in memory, is never saved, and
resets across Course Sources or through `ClearTutorAIConversation()`.
Long-term truth still comes only from existing History, Mastery, Mistake Book,
and Course save data.

## Web / itch.io Security

A Godot Web export is an untrusted client. A future production implementation
must use:

```text
Godot Web build -> secure MathSmith backend/proxy -> AI provider
```

No production API key may be stored in GDScript, exported resources, project
settings, JavaScript, or the Web package. Provider configuration must select a
backend endpoint, not expose an upstream secret. Local `.env`, `.env.local`,
`Secrets/`, and `*.secret` files are ignored by Git.

The current mock provider uses no network and is explicitly marked
`developmentOnly`. Public gameplay remains fully functional through M7 without
any AI service.

## M8.2 Text Conversation

The existing floating Tutor panel now contains a compact text composer and a
session-visible message list. The option-based M7 content remains visible and
usable beside conversation rather than being replaced by a generic chatbot.

The UI emits a message request to its host screen. The host routes it through
`GameManager.RequestTutorAIResponse()`, which builds fresh course-scoped context
and delegates to `TutorAIManager`. The normalized result returns to the panel
for presentation. Input is locked while a request is pending, and an invalid or
unavailable response exposes a retry state while leaving M7 guidance intact.

M8.2 still uses the clearly marked deterministic Mock provider. It introduces
no provider networking, production credentials, structured action execution,
voice, or proactive behavior.

## M8.3 Grounding and Structured Actions

`TutorActionValidator` derives a trusted action list by recursively inspecting
the current deterministic M7 page tree. It keeps only commands already handled
by GameManager. This list is included in the minimized provider context.

A provider may return one `suggestedAction`, but `TutorAIManager` replaces its
contents with the matching trusted action and label. Unknown, stale, or invalid
action IDs are discarded. The Chat UI displays a visually distinct action
button only after validation. Selecting it emits the existing M7 action signal;
the provider never executes gameplay or navigation directly.

The Mock provider supports `/mock-action` and `/mock-invalid-action` solely for
manual development validation. These exact commands are not an intent model and
do not attempt to imitate natural-language AI behavior.

## M8.4 Proactive Tutor

`TutorProactiveManager` deterministically decides when a non-blocking notice is
allowed. Initial centralized values are 18 seconds of inactivity, two incorrect
attempts, a 75-second global cooldown, and at most one notice per Question.

GameUI reports meaningful player activity but does not classify behavior. The
manager returns a NOTICE event, and the existing Tutor bubble displays a small
localized suggestion. It never opens Tutor, takes keyboard focus, pauses play,
reveals an answer, or performs navigation. Tutor, Settings, Tutorial, completion
overlays, solved Questions, and Teacher Preview suppress proactive notices.

## M8.5 Voice Input

Tutor Chat now supports explicit Push-to-Talk through a provider abstraction.
`WebTutorSpeechInputProvider` uses browser `SpeechRecognition` only after a
player click and performs non-continuous, single-utterance recognition. The
desktop editor uses a clearly identified Mock provider for UI validation and
never accesses the microphone.

Speech providers return only normalized listening, processing, transcript, and
error states. A transcript is placed into the editable Chat input and is never
sent automatically. Permission denial or unsupported browsers leave text Chat
fully available. MathSmith does not persist captured audio or transcript data.

## M8.6 Tutor Voice

Visible Tutor replies may be read through `TutorSpeechOutputProvider`. The
initial implementation uses Godot's platform text-to-speech interface and a
voice matching the active English or Simplified Chinese locale when available.

Speech is always player-requested through the speaker button beside a Tutor
message. Starting a new utterance stops the previous one; pressing the active
button stops it. Closing Tutor also stops speech. Text remains visible at all
times, and missing platform voices never affect conversation or gameplay.

## M8.7 Settings, Diagnostics, and Fallback

Settings persist three optional controls: Conversational AI, Tutor Voice, and
Proactive Tutor. Disabling conversation removes only the Chat surface; the M7
Guided Tutor remains available. Disabling voice stops active speech and hides
speech controls. Disabling proactive help clears pending notices. Clearing the
current conversation deletes only transient turns and never learning records.

The version 8 save migration merges new preference fields into older Settings
instead of replacing progress. The gameplay F3 overlay reports provider,
request, minimized context, structured action, fallback, speech, and proactive
state. It never displays credentials, raw provider errors, or the full save.

## M8.8 Localization and Final Boundary

All static M8 controls are present in the shared English and Simplified Chinese
catalog. The development Mock provider also follows the active MathSmith locale.
UI language remains controlled by Settings, while future production providers
receive the current locale in their minimized request context.

M8 ships without a production provider or embedded secret. Public builds keep
the deterministic Mock/development boundary and the complete M7 fallback. A
future live deployment must add a server-side proxy and must preserve context
whitelisting, action validation, active-Question reveal rules, Course isolation,
and graceful fallback.
