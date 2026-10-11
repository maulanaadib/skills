<FEATURE_TITLE>

## Goal

<ONE_TO_THREE_SENTENCE_GOAL>

## Design

<DESIGN_BULLETS_OR_PARAGRAPHS>

## Implementation

<IMPLEMENTATION_STEPS>

## Dependencies

<DEPENDENCIES>

## Scope Limits

<SCOPE_LIMIT_BULLETS>

## Check When Done

<CHECK_BULLETS>

## Commit and Push

This feature is only ready to commit after `Check When Done` passes and the test suite is green. Not before, not on the promise of fixing it later.

The order is fixed:

1. Every item in `Check When Done` passes.
2. Tests pass (`<TEST_COMMAND>`).
3. Lint and typecheck pass (`<LINT_COMMAND>`, `<TYPECHECK_COMMAND>`).
4. Only then, ask the engineer which branch to commit to, as a decision panel:
   - **`main`** (recommended for a solo build where `main` is the working branch)
   - **a new branch** (for example `develop` or `feature/<name>`, when the engineer wants review or keeps `main` deployable)
   Never commit silently, and never pick the branch without asking.
5. Commit with a message that names the feature: `<COMMIT_MESSAGE>`.
6. Push to the chosen branch. Never force push.

If any step fails, stop and fix it before committing. A red test or a failed check is a stop condition, not a thing to commit around.

## Progress Tracker

When this feature lands, update `context/progress-tracker.md`. This section is mandatory: without it the next chat starts blind.

- Move `<FEATURE_NAME>` from **Next Up** to **In Progress** at build start, then to **Completed** when `Check When Done` passes.
- Add to **Open Questions**: <OPEN_QUESTIONS_TO_RAISE_OR_RESOLVE>
- Add to **Architecture Decisions**: <DECISIONS_THIS_FEATURE_RECORDS>
- Add one line to **Session Notes**: <ONE_LINE_RESUME_NOTE>
- Do not touch other features' rows. If this fix turns out to cross a feature boundary, stop and say so instead of editing another spec's scope.
