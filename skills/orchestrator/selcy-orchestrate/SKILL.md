---
name: selcy-orchestrate
allowed-tools: Bash, Read, Grep, Glob, Write, Edit, Agent
description: "Turns an approved /selcy-sdd spec bundle into a kanban board of feature cards, then works them one at a time as the dispatcher spawns it. Each card delegates one feature to `opencode run`, resumes that same session if the build is interrupted instead of starting a new one, runs an independent review session and an independent test session, verifies against the spec's Check When Done, and completes or blocks. Fully autonomous once the bundle is approved — the board is the trigger."
---

## What this skill does

The automation layer for [skills](https://github.com/maulanaadib/skills). It turns an approved spec bundle into a built product with no further human attention.

`/selcy-sdd` writes the bundle. You approve the plan. Then this skill takes over: it reads `context/progress-tracker.md`, creates one kanban card per remaining feature, and the dispatcher keeps spawning the orchestrator profile to work them until the tracker says every feature is done or something needs a human.

It exists because the selcy loop is deliberately one feature per chat, and a human opening a new chat per feature is the bottleneck on a seven-feature project. The loop's safety does not come from the human being present each time; it comes from the contract being in the files. This skill drives that loop mechanically, and stops the moment the contract cannot answer a question.

## The session contract

Every `opencode run` creates a session, and those sessions are how the engineer reviews what happened. Left unmanaged, one feature ends up as `feat-04`, `feat-04-r1`, `feat-04-r2` running side by side, and the engineer cannot tell which one is real. Three rules prevent that:

| Kind of work | Session | Why |
| --- | --- | --- |
| **Build** | `feat-<NN>-<slug>`, **resumed** if interrupted | A build accumulates context. Throwing it away after a crash means re-reading the whole bundle and re-doing the reasoning. |
| **Review** | `feat-<NN>-<slug>-review`, always new | A reviewer that inherits the builder's session inherits its rationalization. Fresh session, code on disk versus the spec. |
| **Test** | `feat-<NN>-<slug>-test`, always new | A tester that inherits the builder's session writes tests for what the builder already thought of, not the edge cases it missed. |

The worker never lets one feature accumulate build sessions. A new build session is created **once**, on the first delegation; every interruption after that resumes it. The session id is the card's memory across dispatcher ticks, which is the only reason a resume is possible at all.

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
         "Update context/progress-tracker.md as needed, then implement "
         "exactly as specified. The spec's ## Check When Done is the contract.",
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

The comment thread is also where this card's own history lives. Before delegating anything, look for a **session id** in the thread or metadata. Its presence or absence decides B1:

- **No session id yet** → this is the first attempt on this feature. Create a new build session (B1a).
- **A session id is present** → this feature was delegated before and the run ended without completing. **Resume that session** (B1b). Never start a new one.

This is the difference between one session per feature and three. If you skip this check, a worker that crashed mid-build spawns a sibling session, the engineer sees two sessions for one feature, and neither holds the full picture.

### B1. Delegate one feature

The message always names the feature spec and nothing else. What changes is whether the session is new or resumed.

#### B1a. First delegation — create the session

```bash
opencode run --dir <project-dir> --title "feat-<NN>-<slug>" --auto "Read context/feature-specs/<NN-name>.md, update context/progress-tracker.md as needed, then implement exactly as specified."
```

The `--title` is what makes the session findable in the list later. A session with a generic or auto-generated title is invisible to the engineer reviewing the run, which is the only reason these sessions get kept at all.

When the run starts, record the session id it prints in the card, as a comment and in metadata:

```text
kanban_comment(text="build session: ses_<id> — feat-<NN>-<slug>")
```

Do this immediately, not after the build. If the worker dies before the run finishes, the next tick has to be able to find the session to resume it. A session id written only after success is a session id written too late.

#### B1b. Any later delegation — resume the session

If the card already names a build session, continue it. Do not create a new one.

```bash
opencode run --dir <project-dir> --session ses_<id> --auto "Continue building the feature in context/feature-specs/<NN-name>.md. Update context/progress-tracker.md as needed."
```

`--continue` resumes the most recent session in the project directory; `--session <id>` resumes the specific one this card named. Prefer `--session`, because with more than one feature in flight the most recent session is not necessarily this card's.

Rules that make this safe:

- **The message is a pointer, not a brief.** Do not paraphrase the spec, do not add requirements, do not scope it.
- **Name the spec and the tracker, nothing else.** The form is: *read `context/feature-specs/<NN-name>.md`, update `context/progress-tracker.md` as needed, then implement exactly as specified.* Do not tell the builder to read `context/AGENTS.md` — the project-root `AGENTS.md` is auto-loaded by the builder, and instructing it to read the copy under `context/` confuses it about which one governs. Do not add negative instructions ("do not read X") either; name what to read, positively.
- **One feature per run.** Never two. A failure must stay contained to one feature.
- **`--dir` pins the working directory.** The worker may be running from elsewhere; the build must happen in the project directory.
- **Heartbeat while you wait.** `opencode run` is synchronous and can take many minutes. Call `kanban_heartbeat(note="delegated <NN> to opencode run, waiting")` while it runs, at least once an hour. Without a heartbeat the dispatcher may reclaim the card mid-build and you lose the run.
- **Wait for it.** Do not background it, do not poll, do not time it out and move on.
- **Never fork a sibling session for the same feature.** If the card names a session, that session is the build. A crash is a reason to resume, not a reason to start over.

### B2. Read the result

`opencode run` exits zero or non-zero. Both are information:

- **Exit zero** → the builder believes it finished. That is a claim, not proof. Go to B3.
- **Exit non-zero** → the build failed, or the builder stopped on a question it could not answer. Read the output. Go to B4.

### B3. Review and test, in separate sessions

A build that exits zero is a builder saying it is finished. Verify it, then have two other sessions look at it independently. The whole point is that they are not the builder.

#### B3a. Review — new session, different model

Create a session named `feat-<NN>-<slug>-review`, on a **different model than the one that built the feature**. A model reviewing its own output shares its own blind spots; if the builder let a bug through, the same model is likely to let it through again.

**Which model is the engineer's call, so ask.** Before the first review on a project, ask the engineer which model to use for review, and which for test. Record both answers in a card comment, and reuse them for every feature after that — the engineer should not have to answer twice. If the engineer has not answered yet, **do not silently fall back to the builder model and call it a review**. Ask, and block the card until they answer. A same-model review is weaker, and the engineer decides whether to accept that, not the worker.

```bash
opencode run --dir <project-dir> --title "feat-<NN>-<slug>-review" --model <review-model> --auto "Read context/feature-specs/<NN-name>.md, then review the implementation against its ## Check When Done and the standards files. Report findings only. Do not edit any file."
```

The reviewer **never edits code**. It reads the spec, reads the code on disk, and reports. This is separation of duties: the reviewer's job is to notice, the builder's job is to fix. A reviewer that fixes loses the independent perspective that made it worth spawning, and the builder never learns what it missed.

Record the review session id in the card the same way as the build session.

#### B3b. Test — new session, different model

Create a session named `feat-<NN>-<slug>-test`, on the model the engineer named for test. The tester reads the spec and the code and writes the suite from scratch. It does not read the builder's session, because a test suite written from the builder's reasoning covers the cases the builder already considered.

```bash
opencode run --dir <project-dir> --title "feat-<NN>-<slug>-test" --model <test-model> --auto "Read context/feature-specs/<NN-name>.md and context/testing-standards.md, then write the test suite this feature requires. Run it and report the result."
```

The tester writes tests and runs them. It does not fix the implementation when they go red — that goes back to the builder, in the build session, via B4.

#### B3c. Read all three results

Only now do you judge the feature. Read, in order:

1. The feature spec's `## Check When Done`. Every item is a claim the build must prove.
2. The builder's output. Did it address each item, or only the ones that went well?
3. The reviewer's findings. These are the items the builder and the checklist missed.
4. The tester's result. Red tests are failures, whatever the builder claimed.
5. `context/progress-tracker.md` again. Did the builder move this feature to Completed and set the next Current Goal? If it did not, the builder itself did not consider the feature done; do not override that judgment.

If every checklist item is addressed, the reviewer found nothing blocking, the suite is green, and the tracker advanced → the feature is done. Call `kanban_complete(summary=..., metadata=...)` with what changed, how it was verified, which sessions hold the evidence, and what risk is still open. The dispatcher promotes the next card on the next tick.

If an item was skipped, the reviewer found a blocking issue, a test is red, or the tracker did not advance → the feature is not done. Go to B4.

### B4. Block and report, and hand the fix back to the build session

The worker never retries a failed build blindly, never answers an owed decision, and never edits the spec to make a failure go away. It blocks the card:

- **The feature** that stopped.
- **Why**, in one of four kinds:
  - **Failed** — the build errored. Surface the error and the spec section it was working on.
  - **Owed decision** — the builder asked a question the bundle does not answer. Surface the question verbatim. Do not answer it, do not pick the recommended option on the engineer's behalf.
  - **Gate mismatch** — the builder claimed done but a `Check When Done` item is unaddressed, or the tracker did not advance. Surface which item.
  - **Review or test failure** — the reviewer found a blocking issue, or a test is red. Surface the finding verbatim, and which session produced it.
- **The exact command** to resume once the engineer has resolved it.

Then call `kanban_block(reason="...")` with the above. Do not delegate the next feature. A failed feature means the next one may be built on a broken foundation — and the parent chain means the next card will not promote anyway.

**Then tell the engineer, in the reply, not only in the card.** A blocked card is a request for a human decision, and the engineer is not watching the board. State the feature, the kind of block, the question or error verbatim, and the exact command to resume. A block reason written only to the card is a block the engineer finds hours later, if at all — and the question the builder asked goes unanswered while the whole run waits.

When the engineer unblocks, the fix goes back to the **build session**, not a new one. The card already names it, so B0 finds it and B1b resumes it, and the builder picks up the failure with its own implementation context intact. That is the loop: review and test find it, the build session fixes it, review and test look again.

If the failure came from review or test, name those sessions in the block reason. The engineer may want to read the reviewer's reasoning before deciding, and that reasoning is only findable if the session id is in the card.

## What this skill never does

- Never writes application code. It delegates; it does not build.
- Never edits a file under `context/`. Those are contracts. A wrong spec is a human decision.
- Never answers an owed decision. It surfaces the question and blocks.
- Never batches features. One per card, one per delegation, always.
- Never retries a failed delegation automatically. A retry without new information is the same failure again. The card stays blocked until a human unblocks it.
- Never marks a feature complete itself. It reads the tracker; the builder writes it. `kanban_complete` is called only when the tracker says every feature is done.
- Never runs `/selcy-sdd`, `/selcy-implement`, `/selcy-check`, `/selcy-test`, or `/selcy-debug` itself. Those are the builder's tools, and the orchestrator delegating to itself is the loop it exists to prevent.
- Never creates a second build session for a feature that already has one. An interrupted build is resumed, not restarted. `feat-04` and `feat-04-r1` running side by side is this rule failing.
- Never lets the reviewer or the tester edit implementation code. They report; the build session fixes.
- Never deletes a session the engineer may need. Probe and smoke sessions are the engineer's signal that something ran; deleting them silently is why the engineer stops trusting the session list. Name them in the report instead.
- Never gives a time estimate for a build. A build's duration depends on the model, the provider, the feature's real size, and how many owed decisions surface, none of which the worker can see. An estimate the engineer arranges their day around and then misses is worse than no estimate. Report **state** instead — what phase the build is in, what it has written, what it is waiting on — which is verifiable and does not expire.
- Never waits on the engineer for a push credential it has already been given. When a push fails with a permission error and the engineer has already named an approved credential, use it. Sitting blocked for hours on a 403 while the approved credential sits unused is a worker waiting for permission it already has. If no credential has been approved, **then** ask — and say the push is otherwise complete.

## Session hygiene

The session list is the engineer's audit trail, and it becomes useless when it is full of noise. The worker keeps it readable by following four rules, none of which involve deleting anything quietly:

- **Name every session you create.** `--title "feat-<NN>-<slug>"`, `-review`, `-test`. A session with an auto-generated title is invisible in the list, and invisible sessions are what the engineer ends up cleaning up by hand.

- **One build session per feature.** This is the rule that failed when a worker crashed mid-build and spawned a sibling. The session id lives in the card, so a resumed run is always possible; there is no situation that justifies a new build session for a feature that already has one.

- **Never delete a session you did not create, and never delete a session silently.** If the project has probe sessions (`QWEN_OK`, `MIMO_OK`, smoke tests, empty sessions), name them in the report and let the engineer decide. Deleting them yourself removes the evidence that a probe ran at all, and the engineer who asked for the cleanup cannot tell what was removed.

- **Report the session list when it is noisy.** When a feature finishes and the project has more sessions than features, say so in the card, with the names. Cleanup is the engineer's call; noticing is the worker's.

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
