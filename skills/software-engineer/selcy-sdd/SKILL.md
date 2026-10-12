---
name: selcy-sdd
allowed-tools: Bash, Read, Grep, Glob, Write, Edit, Agent, AskUserQuestion
description: "Run /selcy-sdd once at project start. Interviews you in structured rounds (combining /scope product questions with /architect technical questions), then batch generates the full SDD context bundle plus numbered feature specs. Safe to resume in a new chat. Each feature spec is then built with /selcy-implement in its own chat."
---

## What this skill does

The one-shot SDD generator. It does the slow, careful part once: it interviews you across every dimension `/scope` and `/architect` would cover, in batched decision panels, until nothing load bearing is left open. Then it writes the whole spec driven development context bundle in one pass, in the exact shape your project already uses, plus one numbered feature spec per feature.

After it runs, you never need it again for this project. You build each feature in its own new chat with `/selcy-implement`, pointing at one feature spec file. No chat memory is needed at any point: all state lives in files.

It exists because `/scope` and `/architect` are deliberately one decision at a time. That is correct for a living project, but expensive at project start, when you want the whole context bundle written once and then forgotten about. This skill front loads the interview, then batch writes.

It is the greenfield door. On a codebase that already exists, the door is `/selcy-audit`, which reads the code and writes the same bundle from it. On a decision that is still open later in the project, the interview is available on its own as `/selcy-grill`. On a deliberate change to a project that already has a bundle, the door is `change` mode, below.

## The loop it hands off to

This is the workflow the generated files are shaped for. Read it as the contract the output must serve:

1. New chat. Run `/selcy-implement <feature>` (or just ask: read `context/feature-specs/NN-name.md` and build it).
2. The builder reads `AGENTS.md` at the project root, which sends it to the context files in order, then the one feature spec.
3. It builds. Nothing else in the bundle is in scope for that chat.
4. It updates `context/progress-tracker.md` (completed, in progress, next up, open questions, session notes).
5. You close the chat. Open a new one. Next feature spec. Same pattern.

Two rules make that loop safe across chats:
- **One feature spec per chat.** Never two. That is what keeps a mistake in one chat from touching the others, and what makes each chat cheap to throw away and redo.
- **Progress lives in `progress-tracker.md`, never in chat memory.** If it is not written to that file, the next chat does not know it happened.

## Artifact ownership

Writes only these, all under `context/`:

**Product and state**
- `AGENTS.md` at the **project root** (the read order, the entry point every later chat reads first). Root, not `context/`, because that is where agents auto-load it from — a read order that is not auto-loaded is a read order the builder has to be told about, and the orchestrator's builder is a bare `opencode run` that loads nothing else.
- `context/product-context.md` (the why: problem, users, success metrics, non goals)
- `context/project-overview.md` (the what: product definition, goals, features, scope)
- `context/progress-tracker.md` (current phase, completed work, open questions, next steps)

**Technical standards** (one concern each, so no feature spec rederives them)
- `context/architecture-context.md` (stack, system boundaries, storage model, invariants)
- `context/architecture-standards.md` (architecture style, module boundaries, when to split)
- `context/security-standards.md` (auth, authorization, validation, secrets, compliance)
- `context/error-handling.md` (error contract, logging, observability)
- `context/testing-standards.md` (test pyramid, what is tested first, definition of done)
- `context/data-model.md` (canonical entities, indexes, migration rules)

**Presentation and process**
- `context/ui-context.md` (theme, colors, typography, component conventions)
- `context/code-standards.md` (implementation rules and conventions)
- `context/ai-workflow-rules.md` (development workflow, scoping rules, delivery approach)

**Feature specs**
- `context/feature-specs/00-project-setup.md` (scaffold plus boilerplate cleanup, always first; plus the GitHub repo and the first deploy when Stage 5b and 5c asked for them)
- `context/feature-specs/NN-kebab-name.md`, one per feature
- `context/.sdd-state.md` (the resume state, see below; dot prefixed so it is clearly internal)

It does not write `docs/specs/` (that is `/architect`'s), does not write `docs/scope/` (that is `/scope`'s), and does not write application code. If a `docs/` SDD pipeline already exists in this project, ask before writing the `context/` bundle: the two conventions should not both be seeded.

Never overwrite an existing `context/` file without asking. If the bundle already exists, route to resume mode, which gap fills and regenerates only what you ask for.

**The root `AGENTS.md` is the one file this skill writes outside `context/`, and it needs two guards.**

- **Never overwrite one a human wrote.** Before writing it, check whether it already exists. If it does and it does not carry the marker below, stop and ask: quote the existing content into the bundle and credit it, or ask permission to replace it. An `AGENTS.md` another tool or engineer authored is their file, and this skill silently replacing it is exactly the failure mode `/selcy-audit` guards against.
- **Mark what you generate.** Every `AGENTS.md` this skill writes starts with a comment marking it generated: `<!-- generated by /selcy-sdd; regenerate with /selcy-sdd context -->`. That marker is how a later run tells its own output from a curated file, and it is the only reason the guard above can be cheap instead of always asking.

**Migrating a project that has `context/AGENTS.md`.** Move its contents to the root `AGENTS.md` and delete the `context/` copy, so the two never diverge. Ask before deleting the old file; do not remove it silently. A project with no root `AGENTS.md` and a `context/AGENTS.md` is a project from before this rule, and the move is a one-time step.

## Resume state: `context/.sdd-state.md`

Every answer, every decomposed feature, and every per feature decision lives in `context/.sdd-state.md`. This is what makes new chat resumption possible: the skill is stateless between chats, the file is the memory.

- Written after every interview round, not only at the end. If a chat dies mid interview, the next `/selcy-sdd` picks up at the last answered round.
- Format and field meanings are in `state-format.md`. Read that file before reading or writing state.
- It is internal: dot prefixed, and `AGENTS.md` never points later chats at it. Builders read the generated context files, not the state.

## Asks vs acts

Same discipline as `/scope` and `/architect`, compressed into one pass:

- **INFER**: anything the prompt, the repo, or already answered state reveals. Never re ask it.
- **LOOK UP**: anything you can find in the environment (the repo, the filesystem, what is installed). Never ask the engineer for a fact you could look up yourself.
- **ASK**: only what the engineer alone knows (business rules, preferences, constraints, taste). Batched, up to 4 per round, as many rounds as it takes.
- **RECOMMEND**: anything expertise settles. Every round is an options panel with exactly one `(recommended)` and a one line why. You may override any pick. Never a neutral menu, never a silent decision.

The interview is complete when every dimension in `interview-guide.md` is answered, inferred with the inference stated back to you, or marked not applicable with a reason. A short interview is a red flag here, same as `/architect`: a real project spans many dimensions.

## Commands

One command, intent inferred from state (never a subcommand you must memorize):

- **No state yet** → full interview, then generate everything. The default first run.
- **State exists, no argument** → resume. Re reads state, tells you where you stopped, continues from there.
- **`resume`** → same as above, explicit. Use this in a new chat.
- **`specs`** → skip the interview, regenerate every feature spec from current state and context. Use it after you edit state or a context file by hand and want the specs to match.
- **`specs <feature>`** → regenerate or add one feature spec only. Use it to enroll a feature you forgot, or to rework one spec without touching the rest.
- **`context`** → regenerate only the six context files plus the root `AGENTS.md` from state. Use it when the interview answers changed but the feature list did not.
- **`change`** → the modification door. Interview the change, compute its blast radius, write one change spec. Works on any bundle, including one written by `/selcy-audit`. See **Change mode** below.

Ambiguous (a feature name that also looks like a keyword) → infer the most likely reading, say which one you chose.

## Portability (any OS, any agent)

Any Agent Skills client on macOS, Linux, Windows. Shell snippets are POSIX reference, not literal scripts; use your agent's cross platform file tools (read, search/glob, write, create dir) for every file action. Create `context/feature-specs/` with your write tool, not `mkdir`. No interactive question picker → ask every panel as plain text with the same options and the same `(recommended)` marker.

Bundled files, all paths relative to this skill's folder, read on demand not upfront:
- `interview-guide.md` (the question dimensions and round mechanics) read before the first question.
- `state-format.md` read before first reading or writing state.
- `decision-gate.md` (the per feature clear versus unclear decision test) read before generating any feature spec.
- `templates/*.md` read only at write time, one per output file. `templates/change-spec.md` is read only in change mode.

## Execution

### Step 0: Route

Read `context/.sdd-state.md` if it exists (else fresh). Then:

- Fresh → Step 1.
- State exists and argument is `resume` or empty → Step 1, resuming from the last answered round.
- Argument is `specs` → skip to Step 4, all features.
- Argument is `specs <feature>` → skip to Step 4, that feature only.
- Argument is `context` → skip to Step 3.
- Argument is `change` → **Change mode**, below.

Tell the user which route you took in one line.

### Step 1: Interview

Read `interview-guide.md` in full before asking anything, then run it. It holds the stages, the round mechanics, and the completeness gate. Save state after every round.

The interview ends with one confirmation panel: the full plan (stack, build approach, workflow tier, ordered feature list, deferred list) shown back for approval. Only after you approve does generation start. Until then, anything can still change.

### Step 2: Freeze the feature list

From the approved plan, fix the ordered feature list and numbering. **`00-project-setup` is always first**, written from the Stage 3 stack decision: it scaffolds the project and cleans the framework boilerplate, and no product behavior lives in it. Then `01`, `02`, ... Numbering is stable once written: a later added feature gets the next free number, existing ones never renumber (that would break every chat that references a file). Foundations next, then slices in build order, then deferred (deferred features get no spec yet, only a line in `project-overview.md`).

Write the list to state.

**Split oversized features before the list is frozen.** A feature spec that is too large is not a feature, it is several, and the cost of discovering that mid build is a confused builder, many iterations, and a build that has to be abandoned and restarted. The signal is not line count alone; it is any of:

- **More than one module.** A feature that touches auth, invoices, and PDF rendering is three features that happen to be described together.
- **More than one distinct user-facing surface with its own state.** A page plus a background job plus a settings panel.
- **A piece that could ship and be verified on its own.** If one part of the feature has a working `## Check When Done` without the other parts, it is a separate feature.
- **Roughly more than a dozen `## Check When Done` items.** Beyond that the builder loses the thread of what it is proving.

When a feature trips any of these, split it into parts that each stand alone, and letter them instead of renumbering: `11-audit-maintenance`, `11-backup-restore`, `11-deploy-acceptance`. The parent number keeps the relationship visible and the letters keep the order. Never renumber existing features to make room — a lettered suffix is how a split avoids breaking every file that already references `NN-name`.

Say the split out loud in the report, with the reason. The engineer may disagree and want it whole; that is their call, and a split proposed at the feature list stage costs one sentence to undo, while a feature discovered to be too large mid build costs a restart.

**A spec that is too thin is the same failure, in the other direction.** A feature list of headings is not a plan, it is a prompt for the builder to decide what the spec should have said. Every decision the spec leaves open is a decision the builder makes alone, mid build, and whatever it guesses becomes the contract the next feature inherits. The minimum a feature spec carries, all of it, every feature:

- **Named data.** The entities, fields, and the migration name, or an explicit statement that this feature adds no schema. "CRUD customer" without the fields forces the builder to invent them, and invented field names leak into every downstream feature.
- **Named services and surfaces.** The module or file the work lives in, and the routes or pages it exposes. "Add a list page" without the path is a guess the builder makes once and every later feature depends on.
- **Named permissions and boundaries.** Who can do what, and how the feature is isolated from other tenants, users, or modules. Absent this, the builder ships an open endpoint and calls it done.
- **Honest placeholders.** When a part of the feature depends on a later feature, say so and show a placeholder that does not pretend to be the real thing. A zero that looks like a computed total is a lie the next feature has to unwind.
- **A `## Scope Limits` section with at least one deferred item and a one line why.** A spec that cannot name anything it is not doing has not been scoped; it is a wish.
- **A `## Check When Done` where every item is verifiable by running something**, not by reading the code. "Build passes" is verifiable. "The code is clean" is not. If an item cannot be phrased as an action with a pass or fail result, it is not a check.

This is the floor, not a target. A spec at the floor is buildable in one chat without the builder inventing a contract; a spec below it is an interview that happens during the build, which is exactly the failure the one-feature-per-chat rule exists to prevent.

### Step 3: Generate the context bundle

Read every file in `templates/` except `templates/feature-spec.md` and `templates/project-setup.md`, then write them all in one pass. Every ALL_CAPS placeholder in a template is an input you already gathered in the interview; apply each as you read.

Rules that apply to every generated file:
- Match the existing `context/` voice and density exactly. These are working documents an engineer scans, not reports. Terse tables, short bullets, no prose padding.
- Respect the language chosen in the interview for generated files. Code, file paths, command flags, and identifiers stay in English regardless.
- **A standards file is a contract, not a survey.** Write rules the project will actually enforce, in the imperative. If the interview did not settle a field, ask rather than inventing it. This is the one place the skill must not silently decide.
- `progress-tracker.md` is written fresh: current phase `Specs generated, build not started`, current goal feature 00, completed `None yet`, next up feature 00 then 01, and any open questions the interview left.

### Step 4: Generate feature specs

Read `decision-gate.md` in full, then process features in order, `00-project-setup` first. For each:

1. Enumerate the decisions that feature requires (data model, integrations, UI composition, behavior, edge and error handling, security), using `decision-gate.md`.
2. Resolve each against state and the generated context files. Already answered → fill it in, silently.
3. Unresolved → collect them and ask, batched, one round for that feature. This is the only place generation pauses. If a feature resolves fully, write it without asking and say so.
4. **Check the size again, on the actual content you are about to write.** The Step 2 check runs on the plan; this one runs on the spec. If the decisions you enumerated span more than one module or surface, or the `## Check When Done` list runs long, stop and split here rather than writing an oversized spec. Letter the parts and generate each as its own spec. A split now is cheaper than a split after the build has started, and it is the same rule.
5. Read `templates/feature-spec.md` (or `templates/project-setup.md` for feature 00), write `context/feature-specs/NN-kebab-name.md`.
6. **Every spec ends with a mandatory `## Progress Tracker` section** naming the exact `progress-tracker.md` fields to update when the feature lands. This is what makes the per chat loop work without the engineer repeating instructions.
7. **Every spec except `00-project-setup` carries a `## Commit and Push` section** with the fixed order: `Check When Done` passes, tests green, lint and typecheck green, then ask which branch (main versus a new branch), then commit and push. Never commit on a red test, never pick the branch without asking. `00-project-setup` carries the same section, minus the push step when Stage 5b recorded no repository URL: the project is local only, so it commits locally and never pushes.
8. Update state: that feature's spec is `generated`.

Never batch questions across features. One feature's unresolved decisions per round, so you can approve or correct one feature at a time, exactly like the chat loop it feeds.

### Step 5: Handoff report

Report, in plain language:
- What was written (file list, counts).
- Which features needed extra questions versus which were resolved from the interview (so you know where the skill decided for you, and can object).
- Any decision it flagged as weakly supported (an answer inferred rather than asked).
- The exact next step: open a new chat, run `/selcy-implement 00-project-setup` (it scaffolds the project, cleans the boilerplate, sets up the GitHub repo when one was given, and performs the first deploy when Stage 5c asked for it), then continue with feature 01.

Keep it short. The report is a handoff, not a summary of the project.

## Change mode

The third door. `/selcy-sdd` creates a bundle, `/selcy-audit` inherits one, and `change` **modifies** a project that already has one: your own project after the first build, or a repo you cloned and want to change freely.

It exists because no skill in the loop handles a deliberate change. `/selcy-audit`'s one rule is *the code is the source of truth, never invent*, which is the opposite of an intentional change. `/selcy-grill` settles one decision and writes one line to a standards file, but it does not plan a change that spans surfaces, and it does not look ahead to what the change will break. `/selcy-implement` builds one feature spec and has no concept of editing code that already exists.

**The freedom is in choosing the target, not in how it executes.** You may name anything in the repo, including core internals. What keeps that safe is not a smaller scope, it is knowing what else the change will hit before you touch it. That is what the blast radius is for.

**One change per spec, one spec per chat.** The same rule as features. A change that touches three surfaces is three change specs, each with its own chat, so a mistake in one never reaches the others. You may change anything you like, as many times as you like — just not all at once.

### Step 0: Route and confirm the target

Read `AGENTS.md` at the project root, then the context files it names. Then:

- **No bundle exists** → stop. Say which door applies: `/selcy-sdd` for an empty directory, `/selcy-audit` for a codebase that already exists. `change` mode has nothing to read.
- **Bundle exists** → continue. It does not matter who wrote it. A bundle from `/selcy-audit` works the same as one from `/selcy-sdd`.

Ask one question, in plain text: **what do you want to change?** If it was given as an argument, restate it in one line and confirm.

Then name the boundary, one line each: what this change touches, and what it does not. A change with no boundary is a rewrite, and a rewrite is not a change.

### Step 1: Interview the change

Use the `/selcy-grill` discipline on the change itself: the change is a design tree, worked in rounds, each round asking the whole frontier, every question a panel of 2 to 4 concrete options with a one line consequence and exactly one `(recommended)`. Read `interview-guide.md` for the round mechanics before the first question.

**Finding facts is your job.** When a question needs a fact, read the code, the config, or the bundle. "Which routes read this column" is answered by grep, not by the engineer. Do not ask for anything you could look up.

**The consequences are the interview.** A change that touches auth does not only touch auth; it touches the session store, the middleware, and every route that reads the session. Each of those is a branch of the tree, and each branch is a question: *this change will also affect X — keep it, change it, or break it?* That is the warning the engineer asked for, and it arrives before anything is written, not after.

The interview is done when the frontier is empty. End with one confirmation round: the whole change shown back, every resolved branch with its source, and one question: approve, or change something.

### Step 2: Blast radius

Before writing any spec, read the bundle and compute what else this change will hit. This is the step that makes a change to core internals safe, and it is the reason this mode exists.

For each surface the change touches, check it against every bundle file and every feature spec that names it:

| Check | Question |
| --- | --- |
| `data-model.md` | Which entities, fields, or indexes does this change add, alter, or remove? Which specs reference them? |
| `architecture-standards.md` | Does this change cross a module boundary the standards file names, or move work between modules? |
| `security-standards.md` | Does this change touch auth, authorization, validation, or secrets? Which specs inherit the rule it changes? |
| `error-handling.md` | Does this change alter the error shape or a category every server action inherits? |
| `testing-standards.md` | Which surfaces does this change touch that the testing standards require covered? |
| `architecture-context.md` | Does this change add, remove, or rename an env var, invariant, or stack entry? |
| `ui-context.md` | Does this change alter tokens, typography, or component conventions other features inherit? |
| Every feature spec | Does this change alter a surface another spec describes as built? |

**Every item in the blast radius carries three things, and an item missing any of them is not finished:**

- **Konsekuensi** — what the change does to that surface, stated plainly. Name the file and the line or section.
- **Solusi** — the concrete step that keeps the repo working. A command (`/selcy-sdd specs 03-customers-projects`, `/selcy-sync`), or a named edit to a standards file. Not a principle, not a best practice — a step the engineer can run.
- **Pencegahan** — what to do **before** the change so the breakage never happens. This is where the honest warning lands: when the blast radius touches a surface with no test coverage, say so and name the surface, and recommend `/selcy-test` for that surface **before** the change, not after. A surface with no tests is a surface where a breakage is invisible until production.

**A blast radius item with no solution is a stop condition.** Report it and ask; do not write the spec around it.

### Step 3: Write the change spec

One file, `context/feature-specs/NN-change-<kebab-name.md>`, using `templates/change-spec.md`. It carries everything a feature spec carries — the minimum density floor from Step 2 above applies, including `## Scope Limits` with at least one deferred item — plus two sections a change owns and a feature does not:

- **`## What This Changes`** — per surface, the status quo and the new state. "The `/api/customers` endpoint currently returns X; after this change it returns Y." Written so the engineer can see the delta without diffing the code.
- **`## Blast Radius`** — the items from Step 2, each with its Konsekuensi, Solusi, and Pencegahan.

**`## Check When Done` must include at least one item that proves existing behavior still works.** A change spec that only verifies the new behavior has not proven the repo did not break. Name the existing surface and the behavior to observe on it. This is what lets `/selcy-check verify` catch a regression without any change to that skill.

Numbering: the next free number, never renumber existing specs. A change spec is a peer of a feature spec — `/selcy-implement` builds it the same way, in its own chat.

### Step 4: Handoff report

Report, in plain language:

- The change as one line.
- The blast radius, grouped: which specs and standards files this change makes stale, and the exact command to regenerate each.
- Which surfaces have no test coverage and should get `/selcy-test` **before** the change.
- The exact next step: a new chat running `/selcy-implement <NN>`.

Then run `/selcy-sync` or tell the engineer to, because a change that touched a standards file may have made other specs stale, and that is what catches it.
