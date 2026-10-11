---
name: selcy-orchestrate
allowed-tools: Bash, Read, Grep, Glob, Write, Edit, Agent
description: "Turns an approved /selcy-sdd spec bundle into a kanban board of feature cards, then works them one at a time as the dispatcher spawns it. Each card delegates one feature to `opencode run`, verifies against the spec's Check When Done, and completes or blocks. Fully autonomous once the bundle is approved — the board is the trigger."
---

## What this skill does

The automation layer for [skills](https://github.com/maulanaadib/skills). It turns an approved spec bundle into a built product with no further human attention.

`/selcy-sdd` writes the bundle. You approve the plan. Then this skill takes over: it reads `context/progress-tracker.md`, creates one kanban card per remaining feature, and the dispatcher keeps spawning the orchestrator profile to work them until the tracker says every feature is done or something needs a human.

It exists because the selcy loop is deliberately one feature per chat, and a human opening a new chat per feature is the bottleneck on a seven-feature project. The loop's safety does not come from the human being present each time; it comes from the contract being in the files. This skill drives that loop mechanically, and stops the moment the contract cannot answer a question.

## The trigger

This skill does not run on a timer and does not need a human to start each feature. The kanban dispatcher is the trigger.

The dispatcher is a loop inside the Hermes gateway that ticks every 60 seconds. On every tick it claims any card in `ready` status and spawns the assigned profile as a worker. So the whole automation is: **create the cards once, then walk away.** The board is the event loop.

This is why the skill is split in two:

- **Phase A — Bootstrap.** Run once, by you, in a chat. Reads the tracker, creates one card per remaining feature, links them in order. Then it is done. It never runs again for this project.
- **Phase B — Worker loop.** Never started by you. The dispatcher spawns the orchestrator profile once per card. The worker delegates that one feature to `opencode run`, verifies it, and closes the card. The next tick spawns it again for the next card.

## Prerequisites

All four must be true, or the skill stops and says which one is missing:

1. A `context/` bundle exists in the project directory, written by `/selcy-sdd` or `/selcy-audit`.
2. `context/progress-tracker.md` names a current goal that is a feature spec in `context/feature-specs/`.
3. `opencode` is on PATH and can run in the project directory.
4. The kanban toolset is enabled on this profile (`hermes -p selcy-orchestrator tools enable kanban`). Without it the `kanban_*` tools are not in the schema and the worker cannot close its own card.

The skill never creates a bundle, never edits the feature list, and never runs `/selcy-sdd` or `/selcy-audit`. If the bundle is missing, that is a human decision about what to build; tell the engineer to run `/selcy-sdd` first on a new project, or `/selcy-audit` on a codebase that already exists.

## Phase A: Bootstrap the board

Run this phase once, after you approve the plan. It is the only part you ever start yourself.

### A0. Confirm the gate state

Read `context/progress-tracker.md`. Find:

- **Current Phase** — if it says the build is complete, stop and report that.
- **Current Goal** — the feature to delegate. It must name a spec file.
- **Completed** — features already done. Never create a card for one of these.
- **In Progress** — if a feature is listed here, it resumes rather than starting fresh.

If Current Goal is missing or names no spec file, stop. That is a bundle state a human must fix.

### A1. Create one card per remaining feature

For each feature the tracker names as not completed, in tracker order:

```text
kanban_create(
    title="Build <NN>: <feature name>",
    assignee="selcy-orchestrator",
    body="Build the feature in context/feature-specs/<NN-name>.md. "
         "Read context/AGENTS.md first, then the spec. "
         "The spec's ## Check When Done is the contract.",
    parents=[<previous card id>],   # omit on the first card
)
```

Rules that make this safe:

- **One feature per card, one card per feature.** Never two features on one card. A failure must stay contained to one feature.
- **Chain them in order.** Each card's parent is the one before it. The dispatcher only promotes a card to `ready` when its parent is `done`, so the chain enforces the build order without any timer.
- **The body is a pointer, not a brief.** Do not paraphrase the spec, do not add requirements, do not scope it. The builder reads the spec; your summary can only lose information.
- **Idempotency.** If you are not sure whether the cards already exist, `kanban_list(status="todo")` first and skip the ones already created. Re-running bootstrap must not duplicate cards.

### A2. Report and finish

List the card ids you created, in order. Then finish. Do not start working the cards yourself — the dispatcher will spawn you for the first one within 60 seconds.

## Phase B: The worker loop

You never start this. The dispatcher spawns you because a card is `ready`. `HERMES_KANBAN_TASK` names it, `HERMES_KANBAN_WORKSPACE` names the project directory.

Read this as the contract the worker must not deviate from.

### B0. Read the card

Call ``kanban_show()``, the tool the dispatcher grants you. It returns the card title, body, parent results, and the comment thread. The parent results section is how the previous feature's handoff reaches you — read it, because the builder's summary and metadata say what changed and what was verified.

### B1. Delegate one feature

Run `opencode run` in the project directory. The message names the feature spec and nothing else:

```bash
opencode run --dir <project-dir> "Read context/AGENTS.md, then build the feature in context/feature-specs/<NN-name>.md"
```

Rules that make this safe:

- **The message is a pointer, not a brief.** Do not paraphrase the spec, do not add requirements, do not scope it.
- **One feature per run.** Never two. A failure must stay contained to one feature.
- **`--dir` pins the working directory.** The worker may be running from elsewhere; the build must happen in the project directory.
- **Heartbeat while you wait.** `opencode run` is synchronous and can take many minutes. Call `kanban_heartbeat(note="delegated <NN> to opencode run, waiting")` while it runs, at least once an hour. Without a heartbeat the dispatcher may reclaim the card mid-build and you lose the run.
- **Wait for it.** Do not background it, do not poll, do not time it out and move on.

### B2. Read the result

`opencode run` exits zero or non-zero. Both are information:

- **Exit zero** → the builder believes it finished. That is a claim, not proof. Go to B3.
- **Exit non-zero** → the build failed, or the builder stopped on a question it could not answer. Read the output. Go to B4.

### B3. Verify against the spec

Do not trust green output. Check it:

1. Read the feature spec's `## Check When Done`. Every item is a claim the build must prove.
2. Read the builder's output. Did it address each item, or only the ones that went well?
3. Read `context/progress-tracker.md` again. Did the builder move this feature to Completed and set the next Current Goal? If it did not, the builder itself did not consider the feature done; do not override that judgment.

If every checklist item is addressed and the tracker advanced → the feature is done. Call `kanban_complete(summary=..., metadata=...)` with what changed, how it was verified, and what risk is still open. The dispatcher promotes the next card on the next tick.

If an item was skipped, failed, or the tracker did not advance → the feature is not done. Go to B4.

### B4. Block and report

The worker never retries a failed build blindly, never answers an owed decision, and never edits the spec to make a failure go away. It blocks the card:

- **The feature** that stopped.
- **Why**, in one of three kinds:
  - **Failed** — the build errored. Surface the error and the spec section it was working on.
  - **Owed decision** — the builder asked a question the bundle does not answer. Surface the question verbatim. Do not answer it, do not pick the recommended option on the engineer's behalf.
  - **Gate mismatch** — the builder claimed done but a `Check When Done` item is unaddressed, or the tracker did not advance. Surface which item.
- **The exact command** to resume once the engineer has resolved it.

Then call `kanban_block(reason="...")` with the above. Do not delegate the next feature. A failed feature means the next one may be built on a broken foundation — and the parent chain means the next card will not promote anyway.

## What this skill never does

- Never writes application code. It delegates; it does not build.
- Never edits a file under `context/`. Those are contracts. A wrong spec is a human decision.
- Never answers an owed decision. It surfaces the question and blocks.
- Never batches features. One per card, one per delegation, always.
- Never retries a failed delegation automatically. A retry without new information is the same failure again. The card stays blocked until a human unblocks it.
- Never marks a feature complete itself. It reads the tracker; the builder writes it. `kanban_complete` is called only when the tracker says every feature is done.
- Never runs `/selcy-sdd`, `/selcy-implement`, `/selcy-check`, `/selcy-test`, or `/selcy-debug` itself. Those are the builder's tools, and the orchestrator delegating to itself is the loop it exists to prevent.

## When to stop the whole run, not just one card

A single feature failure blocks its card, and the parent chain stops the rest. These stop the whole run and tell the engineer to rebuild the bundle:

- `progress-tracker.md` is missing or unreadable. The orchestrator has no source of truth.
- The Current Goal names a spec file that does not exist.
- Three consecutive cards blocked at delegation before any of them produced output. That pattern means the environment, not the features, is broken.

## How to resume after a stop

The board is the state. Nothing needs re-starting:

```bash
# See what is blocked and why
hermes kanban list --status blocked
hermes kanban show <card-id>

# Once you have resolved the reason
hermes kanban unblock <card-id>
```

`unblock` returns the card to `ready`, and the dispatcher picks it up on the next tick. The worker reads the tracker first, so it resumes wherever the loop stopped.

If the bundle itself was wrong, fix `context/`, run `/selcy-sync` to detect drift, regenerate specs with `/selcy-sdd specs <feature>` if needed, then unblock.

## Portability

Any Agent Skills client on macOS, Linux, Windows. `opencode` and `git` are the required CLIs. Shell snippets are POSIX reference; on Windows run them through the agent's cross platform shell. The delegation command is the only shell call that must work exactly; substitute the equivalent non-interactive invocation for your builder if it is not opencode.

The kanban half of this skill is Hermes-specific. On a client without kanban, run Phase A as a plain list and Phase B as a loop in a single long chat; the delegation and verification contract above is unchanged.
