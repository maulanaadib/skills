---
name: selcy-implement
allowed-tools: Bash, Read, Grep, Glob, Write, Edit, Agent, AskUserQuestion
description: "Run /selcy-implement to build one feature spec into working code. Reads the context/ bundle (AGENTS.md plus the context files it names) and the one feature spec, gates on input coverage so nothing load bearing is invented mid build, builds, runs the spec's Check When Done, updates progress-tracker.md, and commits. The builder half of /selcy-sdd."
---

## What this skill does

The builder. It turns one feature spec into working code, and it is the skill the `/selcy-sdd` bundle is shaped for.

`/selcy-sdd` runs once and writes the whole `context/` bundle. `/selcy-implement` runs once per feature, in its own new chat, and builds exactly one spec. Nothing else in the bundle is in scope for that chat.

It exists because a generic builder skill pointed at a different file convention cannot find this bundle. A builder that looks for specs under `docs/specs/` will not find one under `context/feature-specs/`, so it gates and asks questions whose answers are already written down. This skill reads the bundle where the bootstrap put it.

## The loop it serves

1. New chat. Run `/selcy-implement`, or `/selcy-implement <feature>`.
2. The builder resolves the feature, reads `AGENTS.md` at the project root, then the context files it names, then the one feature spec.
3. It gates: every value the build must produce has a named source in the bundle, or it stops and asks.
4. It builds, following the standards files as contracts.
5. It runs the spec's `## Check When Done`, then lint, typecheck, and tests.
6. It updates `context/progress-tracker.md` per the spec's `## Progress Tracker` section.
7. It commits per the spec's `## Commit and Push` section, on the branch the bundle named at planning time.
8. You close the chat. Next feature, new chat, same pattern.

Two rules keep the loop safe across chats:

- **One feature spec per chat.** Never two. A mistake in one chat must not touch another feature, and it is what makes each chat cheap to throw away and redo.
- **Progress lives in `progress-tracker.md`, never in chat memory.** If it is not written to that file, the next chat does not know it happened.

## Commands

One command, intent inferred from state:

- **No argument** → build the current feature: the one `progress-tracker.md` lists as In Progress, else the first one under Next Up.
- **`<number>` or `<name>`** → build that feature, resolved against `context/feature-specs/`. Match on the number prefix first, then on a name fragment. Ambiguous → list the matches and stop.
- **`rework <feature>`** → rebuild a feature already marked Completed. Asks first, because a completed feature usually means downstream features already depend on what it produced.

## Execution

### Step 0: Resolve the feature

Read `context/progress-tracker.md` first. Then:

- No `context/` bundle at all → stop. Tell the engineer to run `/selcy-sdd` first on a new project, or `/selcy-audit` on a codebase that already exists; there is nothing to build from either way.
- No feature spec found for the argument → stop, and list what is in `context/feature-specs/`.
- Feature already Completed and this is not a `rework` → warn, and ask whether to rework or pick another.
- Otherwise → proceed, and say in one line which feature you resolved and how.

### Step 1: Load the bundle

Read `AGENTS.md` at the project root and follow its read order exactly: it lists the context files in the order a builder needs them. Then read the one feature spec.

**Where it lives matters.** The read order is at the **project root**, not under `context/`, because that is the file agents auto-load. If you find a `context/AGENTS.md` instead, read it — it is a bundle from before the root convention, and the bundle is still the bundle — but say so in one line, because that project needs the one-time move `/selcy-sdd` documents.

Do not read other feature specs. They are out of scope, and reading them invites scope creep.

The standards files (architecture, security, error handling, testing, data model) are contracts. A feature may add to them, never relax them. If a spec contradicts a standards file, the standards file wins, and you say so rather than building the contradiction.

### Step 2: The input coverage gate

Before writing any code, enumerate every value this build must produce, compute, or display. Take them from the spec's `## Goal`, `## Design`, `## Implementation`, and `## Check When Done`. For each, ask: does the bundle name where it comes from?

A named source is any of these:

- an input the spec names,
- a database column or entity in `data-model.md` or in the spec,
- a derivation from a value the spec or `architecture-context.md` names,
- a prior decision recorded in a standards file or in `architecture-context.md`,
- an environment variable in the `architecture-context.md` env var table.

Any required value with no named source is an owed decision. Do not judge this by introspection. A build model rationalizes a real decision as "just wiring" and waves it through. Enumerate the values, then check each against the bundle. Mechanical, not intuitive.

Also owed, without enumerating:

- a provider, library, or integration not already in the stack table or the env var table,
- a whole page or screen whose composition `ui-context.md` and the spec together do not pin down,
- a data model for a new entity, down to fields and indexes,
- a behavior that is not trivial (search, generation, wizards, payment flows),
- a permission or ownership rule (who may read and mutate what),
- money or timezone handling, if the bundle never settled the rule and this feature touches it.

**Gate passes** → Step 3. Say in one line that it passed, so the engineer knows the build is grounded.

**Gate fails** → do not invent. Present what is owed as a decision panel, one question per owed decision, batched up to four, each with options and one marked `(recommended)`:

- **Answer now** (recommended when the engineer knows it and it is this feature's business rule): the answer is written into the spec and into `context/.sdd-state.md`, then the build continues.
- **Regenerate the spec**: route to `/selcy-sdd specs <feature>`, when the decision is load bearing and touches more than this feature. Stop this chat; the next `/selcy-implement` picks up the regenerated spec.
- **Build on a flagged assumption**: record the assumption in `progress-tracker.md` under Open Questions as decision debt, build on it, and say plainly it is unratified. Cheap and honest; the debt stays visible until someone settles it.

Never silently pick. An unnamed source is exactly the failure the bundle exists to prevent.

### Step 3: Build

Build inline on the main thread. Track which slices the feature needs:

- **UI**: components, pages, layouts, routes.
- **Logical**: API routes, services, data layers, business logic, integrations.
- Most features are both.

Install dependencies just in time: only what this feature's `## Implementation` names, not every library the stack table lists. Each later feature installs its own.

Follow the standards files. They are not suggestions. In particular:

- Validate input at the boundary, before any logic runs, the way `security-standards.md` states.
- Return errors in the shape `error-handling.md` defines. Never invent a new error shape mid feature.
- Ship the tests `testing-standards.md` requires for this feature in the same feature, never deferred.
- Put the feature in the module `architecture-standards.md` names. If the feature seems to cross a module boundary, that is a scope question, not a design choice. Stop and say so.

Respect `## Scope Limits`. It lists what the feature deliberately does not do. "Do not add persistence yet" is the line that stops a canvas feature from becoming a persistence feature. If the build seems to need something the scope limits exclude, that is an owed decision, not a license to expand.

### Step 4: Self check

Run, in order:

1. Every item in the spec's `## Check When Done`. Each is a claim about the built feature; verify it, do not assume it.
2. Lint and typecheck.
3. The test suite, if `testing-standards.md` requires tests for this feature.

A red item is a stop condition, not a thing to commit around. Fix it before Step 6. If an item cannot pass because the spec itself is wrong, that is an owed decision: go back to Step 2, do not silently build something else.

### Step 5: Update progress-tracker.md

Per the spec's `## Progress Tracker` section, which names the exact fields. Move the feature from Next Up to In Progress (if it was not already), then to Completed when Step 4 passes. Add the open questions the feature raises or resolves, the architecture decisions it records, and one line of session notes so the next chat can resume.

Do not touch other features' rows. If this build turned out to cross a feature boundary, stop and say so instead of editing another spec's scope.

If the build surfaced a bug that predates it, in another feature's code, do not fix it here. Record it with `/selcy-debt` and finish this feature. Fixing another feature from inside this chat is scope creep in the exact shape this loop exists to prevent, and the finding would be lost when this chat closes.

### Step 6: Commit and push

Follow the spec's `## Commit and Push` section. The order is fixed:

1. `Check When Done` passes.
2. Tests pass.
3. Lint and typecheck pass.
4. Commit to the branch the spec names. The spec writes this, it does not ask: trunk-based on `main` → commit to `main`; feature branches → commit to the named branch. Only when the spec names no branch at all do you ask, once, as a decision panel: `main` (recommended for a solo trunk based build) or a new branch such as `feature/<name>`. Never commit silently, and never pick the branch without asking when the spec left it open.
5. Commit with a message that names the feature.
6. Push. Never force push.

If the project is local only (no repository URL in state), step 6 is skipped: commit locally and stop.

### Step 7: Handoff

Report in plain language: what was built, which `Check When Done` items passed, what was left as decision debt, and the exact next step, which is always: close this chat, open a new one, run `/selcy-implement` for the next feature.

Keep it short. It is a handoff, not a summary of the project.

## What this skill never does

- Never builds two features in one chat.
- Never edits another feature's spec, and never rewrites a standards file to make a build fit.
- Never invents a value the bundle does not name.
- Never commits on a red test or a failed check.
- Never picks the commit branch without asking, when the spec left the branch open. When the spec names it, commit to it — the engineer settled that at planning time.
- Never renumbers or rewrites the feature list; that is `/selcy-sdd`'s.

## Portability

Any Agent Skills client on macOS, Linux, Windows. `git` is the only required CLI. Other shell snippets are POSIX reference, not literal scripts: use your agent's cross platform file, process, and test tools. Builds inline on the main thread; the only subagents are read only scouts for exploring a large codebase, on the cheapest model. No interactive question picker → ask every panel as plain text with the same options and the same `(recommended)` marker.
