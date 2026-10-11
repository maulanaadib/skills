# Development Workflow

## Approach

Build this project incrementally using a spec-driven workflow. Context files define what to build, how to build it, and what the current state of progress is. Always implement against these specs — do not infer or invent behavior from scratch.

## Scoping Rules

- Work on one feature unit or subsystem at a time.
- Prefer small, verifiable increments over large speculative changes.
- Do not combine unrelated system boundaries in a single implementation step.

## When To Split Work

Split an implementation step if it combines:

<WHEN_TO_SPLIT_BULLETS>

If a change cannot be verified end to end quickly, the scope is too broad — split it.

## Handling Missing Requirements

- Do not invent product behavior that is not defined in the context files.
- If a requirement is ambiguous, resolve it in the relevant context file before implementing.
- If a requirement is missing, add it as an open question in `progress-tracker.md` before continuing.

## Protected Foundation Components

Do not modify generated third-party foundation components unless explicitly instructed.

This includes:

<PROTECTED_COMPONENTS_BULLETS>

These should remain default and reusable.

Project-specific styling, layout changes, and feature logic must be implemented in app-level components instead of modifying foundation components.

Only modify these files when a task explicitly requires it.

## Keeping Docs In Sync

Update the relevant context file whenever implementation changes:

<KEEPING_IN_SYNC_BULLETS>

Progress state must reflect the actual state of the implementation, not the intended state.

## Before Moving To The Next Unit

<BEFORE_NEXT_BULLETS>

## Commit and Push

A feature is only ready to commit after its `Check When Done` passes and the test suite is green. This is not negotiable, and it is the same in every feature spec.

The order is fixed:

1. Every item in the feature spec's `Check When Done` passes.
2. Tests pass.
3. Lint and typecheck pass.
4. Ask which branch to commit to. Never commit silently, never pick the branch without asking.
5. Commit with a message that names the feature.
6. Push. Never force push.

A red test or a failed check is a stop condition, not a thing to commit around. Fix it first.

<COMMIT_BRANCH_DEFAULT_NOTE>
