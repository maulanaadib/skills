---
name: selcy-sync
allowed-tools: Bash, Read, Grep, Glob, Write, Edit, Agent
description: "Run /selcy-sync after you edit a context/ file by hand, or after a feature lands, to keep the bundle honest. Reconciles progress-tracker.md against the repo, detects a context file that drifted from the feature specs, and flags specs the change made stale. Surgical edits only: adds lines, rewrites single lines it owns. Never a whole section, never curated prose."
---

## What this skill does

Closes the loop on a completed change, and closes the one real gap the bundle has: nothing forces a builder to notice that a context file changed after the specs were written.

The bundle is a set of contracts. A standards file is a contract every feature spec inherits. When you edit one by hand, every spec that depends on it is now potentially stale, and the next `/selcy-implement` chat will read a spec whose details no longer match the standards it is supposed to follow. This skill is what catches that.

Run it in two situations:

- **After you edit a `context/` file by hand.** Especially a standards file, the stack table, or the env var table.
- **After a feature lands.** To reconcile `progress-tracker.md` with what the repo actually shows.

## Commands

- **No argument** → reconcile everything below, in order.
- **`stale`** → only the drift check (Step 2). Fast; use it to see what a manual edit broke.
- **`progress`** → only the progress-tracker reconciliation (Step 1).

## Execution

### Step 1: Reconcile progress-tracker.md

Read the repo, then read `context/progress-tracker.md`. For each feature it lists:

- **Completed** → verify the evidence exists: the code, the tests, the commit. If the repo shows the work but the tracker does not say Completed, correct the row. If the tracker says Completed but the repo shows no evidence, flag it; do not silently revert it, because the engineer may know something the repo does not show.
- **In Progress** → verify the work is partway. If the repo shows it finished, propose marking it Completed and running `/selcy-check` to confirm.
- **Next Up** → verify nothing in the repo already built it. If something did, flag it: either the feature was built without a spec, or the tracker is behind.

Surgical edits only. Correct a cell, never rewrite the file. Flag unexpected state instead of clobbering it.

Session Notes is the one section that does grow without bound, because findings land there when they have nowhere else to go. When it carries a bug that predates the feature being tracked, or a gotcha the next chat needs, point at `/selcy-debt` as the file that owns those. Sync reconciles progress; it does not migrate findings.

### Step 2: Drift check (the reason this skill exists)

For each standards file and each foundation file the specs depend on, compare it against every feature spec that references it:

- **architecture-standards.md** → does any spec place its feature in a module this file no longer names, or cross a boundary this file no longer allows?
- **security-standards.md** → does any spec describe an auth, authorization, or validation approach this file contradicts?
- **error-handling.md** → does any spec define an error shape or category this file no longer defines?
- **testing-standards.md** → does any spec promise tests this file no longer requires?
- **data-model.md** → does any spec reference an entity, column, or index this file changed or removed?
- **architecture-context.md** → does any spec name a stack entry, an invariant, or an env var this file no longer has?

For each drift found, report:

- the file and line that changed,
- the spec and section that now contradicts it,
- the recommended fix, which is almost always: regenerate that spec with `/selcy-sdd specs <feature>`.

**This skill never rewrites a feature spec.** It detects and reports. Regenerating is `/selcy-sdd`'s job, because regeneration may surface a new owed decision that needs a panel.

### Step 3: Flag what it must not touch

Report, without editing:

- **Curated prose** in any context file: prose the engineer wrote by hand, as opposed to fields the bootstrap generated. When unsure whether a passage is curated, flag it as a conflict and let the engineer decide.
- **A spec whose feature is In Progress.** It is being built right now; syncing it mid build would change the contract under the builder. Flag it and come back after the feature lands.
- The feature list itself. Adding, removing, or reordering features is `/selcy-sdd`'s.

### Step 4: Report

In plain language:

- What was reconciled and corrected (with the exact cells).
- What drifted, and the exact `/selcy-sdd specs <feature>` command to fix each.
- What was flagged and left alone, and why.

Keep it short. It is a report, not an audit document.

## What this skill never does

- Never rewrites a feature spec, even one it found stale.
- Never rewrites curated prose.
- Never edits a spec whose feature is In Progress.
- Never changes the feature list.
- Never clobbers unexpected state; it flags it.

## Portability

Any Agent Skills client on macOS, Linux, Windows. `git` is the only required CLI. Other shell snippets are POSIX reference; use your agent's cross platform file tools. Runs inline on the main thread; the drift check is reading and comparing, which the main thread does directly.
