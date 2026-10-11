---
name: selcy-sdd
allowed-tools: Bash, Read, Grep, Glob, Write, Edit, Agent, AskUserQuestion
description: "Run /selcy-sdd once at project start. Interviews you in structured rounds (combining /scope product questions with /architect technical questions), then batch generates the full SDD context bundle plus numbered feature specs. Safe to resume in a new chat. Each feature spec is then built with /selcy-implement in its own chat."
---

## What this skill does

The one-shot SDD generator. It does the slow, careful part once: it interviews you across every dimension `/scope` and `/architect` would cover, in batched decision panels, until nothing load bearing is left open. Then it writes the whole spec driven development context bundle in one pass, in the exact shape your project already uses, plus one numbered feature spec per feature.

After it runs, you never need it again for this project. You build each feature in its own new chat with `/selcy-implement`, pointing at one feature spec file. No chat memory is needed at any point: all state lives in files.

It exists because `/scope` and `/architect` are deliberately one decision at a time. That is correct for a living project, but expensive at project start, when you want the whole context bundle written once and then forgotten about. This skill front loads the interview, then batch writes.

It is the greenfield door. On a codebase that already exists, the door is `/selcy-audit`, which reads the code and writes the same bundle from it. On a decision that is still open later in the project, the interview is available on its own as `/selcy-grill`.

## The loop it hands off to

This is the workflow the generated files are shaped for. Read it as the contract the output must serve:

1. New chat. Run `/selcy-implement <feature>` (or just ask: read `context/feature-specs/NN-name.md` and build it).
2. The builder reads `context/AGENTS.md`, which sends it to the context files in order, then the one feature spec.
3. It builds. Nothing else in the bundle is in scope for that chat.
4. It updates `context/progress-tracker.md` (completed, in progress, next up, open questions, session notes).
5. You close the chat. Open a new one. Next feature spec. Same pattern.

Two rules make that loop safe across chats:
- **One feature spec per chat.** Never two. That is what keeps a mistake in one chat from touching the others, and what makes each chat cheap to throw away and redo.
- **Progress lives in `progress-tracker.md`, never in chat memory.** If it is not written to that file, the next chat does not know it happened.

## Artifact ownership

Writes only these, all under `context/`:

**Product and state**
- `context/AGENTS.md` (the read order, the entry point every later chat reads first)
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
- **`context`** → regenerate only the six context files plus `AGENTS.md` from state. Use it when the interview answers changed but the feature list did not.

Ambiguous (a feature name that also looks like a keyword) → infer the most likely reading, say which one you chose.

## Portability (any OS, any agent)

Any Agent Skills client on macOS, Linux, Windows. Shell snippets are POSIX reference, not literal scripts; use your agent's cross platform file tools (read, search/glob, write, create dir) for every file action. Create `context/feature-specs/` with your write tool, not `mkdir`. No interactive question picker → ask every panel as plain text with the same options and the same `(recommended)` marker.

Bundled files, all paths relative to this skill's folder, read on demand not upfront:
- `interview-guide.md` (the question dimensions and round mechanics) read before the first question.
- `state-format.md` read before first reading or writing state.
- `decision-gate.md` (the per feature clear versus unclear decision test) read before generating any feature spec.
- `templates/*.md` read only at write time, one per output file.

## Execution

### Step 0: Route

Read `context/.sdd-state.md` if it exists (else fresh). Then:

- Fresh → Step 1.
- State exists and argument is `resume` or empty → Step 1, resuming from the last answered round.
- Argument is `specs` → skip to Step 4, all features.
- Argument is `specs <feature>` → skip to Step 4, that feature only.
- Argument is `context` → skip to Step 3.

Tell the user which route you took in one line.

### Step 1: Interview

Read `interview-guide.md` in full before asking anything, then run it. It holds the stages, the round mechanics, and the completeness gate. Save state after every round.

The interview ends with one confirmation panel: the full plan (stack, build approach, workflow tier, ordered feature list, deferred list) shown back for approval. Only after you approve does generation start. Until then, anything can still change.

### Step 2: Freeze the feature list

From the approved plan, fix the ordered feature list and numbering. **`00-project-setup` is always first**, written from the Stage 3 stack decision: it scaffolds the project and cleans the framework boilerplate, and no product behavior lives in it. Then `01`, `02`, ... Numbering is stable once written: a later added feature gets the next free number, existing ones never renumber (that would break every chat that references a file). Foundations next, then slices in build order, then deferred (deferred features get no spec yet, only a line in `project-overview.md`).

Write the list to state.

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
4. Read `templates/feature-spec.md` (or `templates/project-setup.md` for feature 00), write `context/feature-specs/NN-kebab-name.md`.
5. **Every spec ends with a mandatory `## Progress Tracker` section** naming the exact `progress-tracker.md` fields to update when the feature lands. This is what makes the per chat loop work without the engineer repeating instructions.
6. **Every spec except `00-project-setup` carries a `## Commit and Push` section** with the fixed order: `Check When Done` passes, tests green, lint and typecheck green, then ask which branch (main versus a new branch), then commit and push. Never commit on a red test, never pick the branch without asking. `00-project-setup` carries the same section, minus the push step when Stage 5b recorded no repository URL: the project is local only, so it commits locally and never pushes.
7. Update state: that feature's spec is `generated`.

Never batch questions across features. One feature's unresolved decisions per round, so you can approve or correct one feature at a time, exactly like the chat loop it feeds.

### Step 5: Handoff report

Report, in plain language:
- What was written (file list, counts).
- Which features needed extra questions versus which were resolved from the interview (so you know where the skill decided for you, and can object).
- Any decision it flagged as weakly supported (an answer inferred rather than asked).
- The exact next step: open a new chat, run `/selcy-implement 00-project-setup` (it scaffolds the project, cleans the boilerplate, sets up the GitHub repo when one was given, and performs the first deploy when Stage 5c asked for it), then continue with feature 01.

Keep it short. The report is a handoff, not a summary of the project.
