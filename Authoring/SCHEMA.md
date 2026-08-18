# MathSmith CSV Authoring Schema

Schema version: `1`

One CSV contains three explicit record types so Course setup, Level creation, and Question creation remain separate while still living in one portable file.

## Column Order

```text
record_type,course_id,course_name,course_description,level_id,level_name,level_type,skill_tags,question_id,expression
```

Keep header names and column order exactly as written in the template.

## File Structure

Use records in this order:

```text
COURSE
LEVEL
LEVEL
...
QUESTION
QUESTION
...
```

Example:

```csv
record_type,course_id,course_name,course_description,level_id,level_name,level_type,skill_tags,question_id,expression
COURSE,number_sense,Number Sense,Arithmetic practice,,,,,,
LEVEL,,,,level_01,Addition,step_ordering,addition;decomposition,,
LEVEL,,,,level_02,Mixed Operations,multiple_choice_ordering,mixed_operations;precedence,,
QUESTION,,,,level_01,,,,NS01_Q01,18 + 7
QUESTION,,,,level_01,,,,NS01_Q02,27 + 16
QUESTION,,,,level_02,,,,NS02_Q01,18 + 12 / 3 - 4
```

## Record Types

### COURSE

Exactly one `COURSE` record is required and must be the first content row.

Required fields: `record_type`, `course_id`, and `course_name`. `course_description` is optional. All Level and Question fields remain blank.

### LEVEL

Add one `LEVEL` record for every Level. Their order defines the authored Level order.

Required fields: `record_type`, `level_id`, `level_name`, `level_type`, and `skill_tags`. All Course and Question fields remain blank.

### QUESTION

Add one `QUESTION` record for every Question. `level_id` explicitly connects it to an existing `LEVEL` record.

Required fields: `record_type`, `level_id`, `question_id`, and `expression`. All Course fields and descriptive Level fields remain blank.

Question order within each Level follows the order of its `QUESTION` records. Runtime gameplay may still randomize Question order according to existing MathSmith rules.

## Field Reference

| Field | Used By | Format | Example |
|---|---|---|---|
| `record_type` | Every row | `COURSE`, `LEVEL`, or `QUESTION` | `LEVEL` |
| `course_id` | COURSE | Stable lowercase snake_case ID | `number_sense_course` |
| `course_name` | COURSE | Player-facing name | `Number Sense Workshop` |
| `course_description` | COURSE | Optional short summary | `Practice structured arithmetic reasoning` |
| `level_id` | LEVEL, QUESTION | Stable lowercase snake_case ID | `level_01` |
| `level_name` | LEVEL | Player-facing name | `Build Friendly Numbers` |
| `level_type` | LEVEL | Supported Level Type ID | `step_ordering` |
| `skill_tags` | LEVEL | Semicolon-separated lowercase snake_case tags | `addition;decomposition` |
| `question_id` | QUESTION | Stable letters/numbers/underscores ID | `NS01_Q01` |
| `expression` | QUESTION | Supported mathematical expression | `18 + 12 / 3 - 4` |

Whitespace surrounding values is ignored. Record Type and Level Type values are case-sensitive.

## Supported Level Types

| Level Type | Gameplay Mode |
|---|---|
| `step_ordering` | Arrange generated solution steps into the correct order. |
| `multiple_choice_ordering` | Select the correct option at each solution stage. |
| `fill_in_process` | Complete missing values in the generated solution process. |

Do not use display names such as `Step Ordering` in the CSV.

## Skill Tags

Skill Tags belong to a `LEVEL` record and automatically apply to every Question referencing that Level. Use one or more lowercase snake_case tags separated by semicolons:

```text
mixed_operations;precedence;multi_step
```

Do not use commas or duplicate a tag within one Level. Prefer mathematical concepts over difficulty labels.

## ID Rules

- `course_id` and `level_id` use lowercase letters, numbers, and underscores.
- `question_id` may use uppercase letters for readability.
- IDs cannot contain spaces.
- Every `level_id` must be unique within the Course.
- Every `question_id` must be unique across the entire Course.
- Every Question must reference a previously defined `level_id`.
- Keep IDs stable after players begin using a Course because saved data refers to them.
- Reusing IDs for materially different content may reset Imported Course player data during replacement.

## Expression Syntax

Supported: whole-number literals, `+`, `-`, `*`, `/`, parentheses, and spaces for readability.

Valid examples:

```text
38 + 24
18 + 12 / 3 - 4
(8 + 4) * 3 - 6
60 / (4 + 6) + (3 * 5)
```

Do not use equals signs, supplied answers, decimals, variables, exponents, implicit multiplication, `×`, `÷`, empty parentheses, or division by zero.

Expressions must pass MathSmith's existing `ExpressionParser` and allow `StepGenerator` to create a usable educational solution. Divisions should resolve to whole-number results without decimal intermediate values.

## CSV Formatting

- Save as UTF-8 CSV.
- Use commas as separators.
- Use standard CSV quoting for values containing commas, double quotes, or line breaks.
- Escape a double quote inside a quoted value by writing it twice.
- Do not add decorative rows above the header.
- Empty trailing rows are allowed and ignored.

## Validation Expectations

- **Error** blocks import and preserves the current Imported Course.
- **Warning** allows import but highlights unusual content for review.
- **Valid** means the record and generated solution passed validation.

Validation feedback should identify the row, Record Type, Level ID, Question ID, field, severity, issue, and suggested action whenever available.
