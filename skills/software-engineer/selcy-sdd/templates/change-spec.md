<CHANGE_TITLE>

## Goal

<ONE_TO_THREE_SENTENCE_GOAL_OF_THE_CHANGE>

## What This Changes

Per surface, the status quo and the new state. Written so the delta is visible without diffing the code.

### <SURFACE_1_NAME>

- **Status quo:** <WHAT_IT_DOES_NOW>
- **New state:** <WHAT_IT_WILL_DO_AFTER_THIS_CHANGE>

### <SURFACE_2_NAME>

- **Status quo:** <WHAT_IT_DOES_NOW>
- **New state:** <WHAT_IT_WILL_DO_AFTER_THIS_CHANGE>

## Design

<DESIGN_BULLETS_OR_PARAGRAPHS>

## Implementation

<IMPLEMENTATION_STEPS>

## Dependencies

<DEPENDENCIES>

## Blast Radius

What else this change hits, and what to do about it. Every item carries all three fields; an item missing one is not finished.

### BR-1: <SURFACE_OR_CONTRACT_NAME>

- **Konsekuensi:** <WHAT_THIS_CHANGE_DOES_TO_THAT_SURFACE, with the file and section>
- **Solusi:** <THE_CONCRETE_STEP: a command like /selcy-sdd specs 03-customers-projects, or a named edit to a standards file>
- **Pencegahan:** <WHAT_TO_DO_BEFORE_THE_CHANGE, including /selcy-test for an uncovered surface>

### BR-2: <SURFACE_OR_CONTRACT_NAME>

- **Konsekuensi:** <WHAT_THIS_CHANGE_DOES_TO_THAT_SURFACE, with the file and section>
- **Solusi:** <THE_CONCRETE_STEP>
- **Pencegahan:** <WHAT_TO_DO_BEFORE_THE_CHANGE>

## Scope Limits

<SCOPE_LIMIT_BULLETS, with at least one deferred item and a one line why>

## Check When Done

Every item is verifiable by running something, not by reading the code. At least one item must prove existing behavior still works — name the existing surface and the behavior to observe on it.

- <NEW_BEHAVIOR_CHECK>
- <EXISTING_BEHAVIOR_STILL_WORKS_CHECK> — regression guard
- <MORE_CHECKS>

## Commit and Push

This change is only ready to commit after `Check When Done` passes and the test suite is green. Not before, not on the promise of fixing it later.

The order is fixed:

1. Every item in `Check When Done` passes, including the regression guard.
2. Tests pass (`<TEST_COMMAND>`).
3. Lint and typecheck pass (`<LINT_COMMAND>`, `<TYPECHECK_COMMAND>`).
4. Commit to the branch the bundle names. This is written, not asked:
   - If the bundle's branch strategy is **trunk-based on `main`** — commit to `main`. Do not ask. The engineer already answered this at planning time, and asking again in an unattended build blocks every change on a question that was settled.
   - If the bundle's branch strategy is **feature branches** — create `<BRANCH_NAME>` and commit there. Do not ask which one; the bundle named it.
   - Only ask if the bundle names no branch strategy at all. Then ask once, as a decision panel: **`main`** (recommended for a solo build where `main` is the working branch) or **a new branch** (for example `develop` or `change/<name>`, when the engineer wants review or keeps `main` deployable). Never commit silently, and never pick the branch without asking.
5. Commit with a message that names the change: `<COMMIT_MESSAGE>`.
6. Push to the chosen branch. Never force push.

If any step fails, stop and fix it before committing. A red test or a failed check is a stop condition, not a thing to commit around.

## Progress Tracker

When this change lands, update `context/progress-tracker.md`. This section is mandatory: without it the next chat starts blind.

- Add `<CHANGE_NAME>` under **Completed** when `Check When Done` passes, including the regression guard.
- Add to **Open Questions**: <OPEN_QUESTIONS_TO_RAISE_OR_RESOLVE>
- Add to **Architecture Decisions**: <DECISIONS_THIS_CHANGE_RECORDS>
- Add one line to **Session Notes**: <ONE_LINE_RESUME_NOTE>
- Do not touch other features' rows. If this change turns out to cross a feature boundary, stop and say so instead of editing another spec's scope.
