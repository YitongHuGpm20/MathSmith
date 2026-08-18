# MathSmith CSV Authoring Kit

This folder is the starting point for creating a MathSmith Course without editing game code.

## Files

- `MathSmith_Course_Template.csv` — clean starter file to copy and complete.
- `MathSmith_Course_Example.csv` — finished example covering all three Gameplay Modes.
- `SCHEMA.md` — complete field definitions and validation rules.

## Basic Workflow

1. Copy `MathSmith_Course_Template.csv` and rename the copy.
2. Fill in the Course, Level, Skill, and Question content.
3. Define the Course once, create Levels in the `LEVEL` section, then add Questions in the `QUESTION` section.
4. Save the file as UTF-8 CSV with comma-separated columns.
5. Launch MathSmith and open **Teacher Tools**.
6. Import the CSV.
7. Review the Validation Results and fix any reported errors.
8. Preview the Course and revise the CSV when necessary.

## Quick Formatting Notes

- Keep every `course_id`, `level_id`, and `question_id` stable and unique within its scope.
- Separate multiple Skill Tags with semicolons, for example `addition;decomposition`.
- Use one of these Level Types:
  - `step_ordering`
  - `multiple_choice_ordering`
  - `fill_in_process`
- Expressions currently support whole numbers, `+`, `-`, `*`, `/`, and parentheses.
- Do not rename or remove columns from the template.
- Keep Level definitions together above the Question rows.
- Each Question uses `level_id` to identify its parent Level; Level descriptions never repeat in Question rows.

See `SCHEMA.md` before building a production Course or troubleshooting validation results.
