---
name: selcy-audit
allowed-tools: Bash, Read, Grep, Glob, Write, Edit, Agent, AskUserQuestion
description: "Run /selcy-audit on an existing codebase with no context/ bundle. Reads the real code and reverse-engineers the context/ bundle from it, so /selcy-implement, /selcy-check, /selcy-test and /selcy-sync work on a project you did not start from scratch. Observes, never invents."
---

## What this skill does

The brownfield entry point. It is what you run when the project already exists and there is no `context/` bundle: a codebase you inherited, a project you are maintaining, a legacy app you are continuing, or your own project from before you used `/selcy-sdd`.

`/selcy-sdd` interviews you and writes the bundle from your answers. `/selcy-audit` reads the code and writes the bundle from **what the code actually says**. Same output shape, opposite direction. Every skill downstream of the bundle works unchanged, because the files are identical.

It exists because the loop had exactly one door, and it was greenfield only. `/selcy-implement` stops and says "run `/selcy-sdd` first" when it finds no bundle, which is correct but useless on a codebase that has been running for two years. This skill is that door.

## The one rule that makes it safe

**The code is the source of truth, not the engineer, and not you.**

On a greenfield project the engineer's answers create the truth. On a brownfield project the truth already exists and it is in the repo. So the discipline inverts:

- **OBSERVE**: anything the code, the config, the dependency manifest, the migrations, or the tests can tell you. This is nearly everything. Read it.
- **ASK**: only what no file can answer, and only after you have looked. "What is the deploy target" is answered by the Dockerfile and the CI config, not by the engineer.
- **NEVER INVENT**: if nothing in the repo settles a field, write `not evident from the repo` and say so in the report. Do not fill it with a sensible default and do not guess. A bundle that guesses is worse than a gap, because `/selcy-implement` will read the guess as a settled contract and build against it.

A bundle with honest gaps is a map with blank spots. A bundle with invented facts is a map with wrong roads. Only one of them gets you lost.

## When to run it

- **No `context/` bundle exists** and you want to work on this codebase with the selcy loop. Run it once, the same way you would run `/selcy-sdd` on a new project.
- **A `context/` bundle exists but you do not trust it.** Run with `verify` to compare the bundle against the repo and report where they disagree. Do not let it rewrite anything in that mode; it reports, you decide.
- **Never alongside `/selcy-sdd`.** Two conventions must not both be seeded in one project. If a bundle exists and is trusted, use `/selcy-sync` to maintain it, not this skill.

## Commands

- **No argument** → full audit. Read the repo, write the bundle, report the gaps.
- **`verify`** → read only. Compare an existing bundle against the repo and report every disagreement. Writes nothing. Use this first when you are not sure the bundle still matches the code.
- **`<file>`** → re-audit one context file only, for example `architecture-context` or `data-model`. Use it after a large change invalidated one file.

## Step 0: Route and confirm the target

Find the project root. A `context/` directory there means a bundle exists; route accordingly:

- Bundle exists, argument is `verify` → Step 5 (verify mode, read only).
- Bundle exists, no argument → stop. Ask: audit fresh and overwrite, or `verify` first? Never overwrite a bundle without asking; it may hold curated decisions the engineer wrote by hand, and `/selcy-sync` is the tool that maintains an existing bundle.
- No bundle → continue to Step 1.

Say in one line which route you took.

## Step 1: Survey the repo before writing anything

Read the whole repo before you write a single file. The bundle is one document split across files; writing the first file before you have read the last is how contradictions get baked in.

What to read, and what each one settles:

| Read | Settles |
| --- | --- |
| Dependency manifest (`package.json`, `pyproject.toml`, `go.mod`, `Cargo.toml`, `Gemfile`, `composer.json`) | The stack table. Real versions, not guesses. Also the test runners, from the dev and test dependencies. |
| Lockfile (`package-lock.json`, `yarn.lock`, `pnpm-lock.yaml`, and equivalents) | Whether a dependency is actually installed, not just declared. |
| Config for the framework (e.g. `next.config.*`, `vite.config.*`, `nuxt.config.*`, `tsconfig.json`, `pyproject` tool sections) | Rendering strategy, path aliases, build target, strictness. |
| The migration directory (`prisma/migrations`, `migrations/`, `db/migrate`, `alembic`) | The data model as the code actually evolved it, plus the migration rule. |
| The ORM schema or model files (`schema.prisma`, `models.py`, `*.entity.ts`, `schema.rb`) | Entities, fields, indexes, relations. This is `data-model.md`, read not asked. |
| Auth config (e.g. `auth.ts`, `auth.config.*`, middleware, session store) | Auth and session model, and where session lives. |
| The route or controller tree | Module boundaries and the folder contract, from how the code is actually organized. |
| Test config and the test directories | Runners and the test pyramid, from what the project actually runs. |
| CI config (`.github/workflows`, `.gitlab-ci.yml`, `Jenkinsfile`) | CI checks, from what the pipeline actually gates on. |
| `Dockerfile`, `compose` files, deploy configs | Hosting target, the service topology, and the env var list. |
| `.env.example`, `.env.sample`, `docker-compose` env blocks | The env var table, from the names the project already uses. |
| `README`, existing `AGENTS.md`, `CONTRIBUTING`, comments at the top of key files | Conventions the engineer already wrote down. Trust these over your inference, and quote them. |
| `git log` | What is actually being worked on, and the commit convention the repo already follows. |

Dispatch sub-agents for the heavy reading. A large codebase is more than one context window; each survey is a self-contained question with a written answer, which is exactly what a sub-agent is for. Do not block on a survey that is still running: note it as unsettled and keep reading what you can.

## Step 2: Write the bundle, one file at a time

Write the same files `/selcy-sdd` writes, in the same shape, so downstream skills need no adaptation:

- `AGENTS.md` at the **project root** — the read order. Last, because it points at the others. Root, not `context/`, because that is where agents auto-load it from.
- `context/architecture-context.md` — stack table from the manifest, system boundaries from the service topology, storage model, auth model, invariants, and the env var table from `.env.example` or the compose file.
- `context/data-model.md` — from the schema and migrations. Entities, fields, indexes, relations, and the migration rule the repo actually follows (which migrations exist, whether they are forward only).
- `context/architecture-standards.md` — module boundaries from the real folder structure, dependency direction from the real imports, split triggers inferred from how the code is actually divided.
- `context/security-standards.md` — from the auth config, the validation approach the code actually uses, and how secrets are handled. If the code validates at the boundary, say so; if it does not, say that too, because that is a real finding.
- `context/error-handling.md` — the error shape the code actually returns. Read the API routes and the error classes, then write what you found, not what a well designed project would have.
- `context/testing-standards.md` — runners from the config, and what the existing tests actually cover. Report the real pyramid, including when it is flat or missing a level.
- `context/ui-context.md` — only if the project has a UI. From the theme config, the tokens, the component library in the manifest, and the fonts.
- `context/code-standards.md` — type strictness from `tsconfig` or the equivalent, the folder contract from the real tree, and the git workflow from the commit history.
- `context/ai-workflow-rules.md` — the workflow the repo actually supports, and what a builder working in it should assume.
- `context/product-context.md` and `context/project-overview.md` — the why and the what, from the README, the routes, and the features the code actually implements. These are the two files most likely to need an engineer's input, because product intent is the one thing code expresses badly. See Step 3.
- `context/progress-tracker.md` — written fresh, with current phase `Audit complete, build not started`, and a Next Up built from what the repo shows is unfinished: TODOs, `FIXME`s, half wired features, and tests that are missing for anything touching money, auth, or permissions.

Rules that apply to every file:

- **Quote, then label.** When you write a fact, it came from somewhere. Say where. A stack row with no source is a guess wearing a contract's clothes.
- **Write the code as it is, not as it should be.** If the error handling is inconsistent across routes, `error-handling.md` says it is inconsistent and names the shapes it found. That is a useful contract, because it tells a builder exactly what they are working with. A cleaned up version is a lie a builder will trust.
- **A gap is a finding, not a hole to fill.** No migrations directory is a finding about the migration rule. No tests is a finding about the testing pyramid. Write it down plainly; the engineer decides whether to fix it, and `/selcy-debt` is where it gets recorded.
- **Never overwrite a file the engineer wrote by hand without asking.** If an `AGENTS.md` or a `README` already carries conventions, quote it into the bundle and credit it, rather than rewriting it in your own words. This applies to the root `AGENTS.md` too, which this skill writes: if one already exists and it does not carry the generated marker, ask before replacing it.

## Step 3: Ask only what the code cannot answer

After the survey, some fields will still be open. Ask them in **one batched panel**, not one at a time, and only the ones that are genuinely closed to you:

- **Product intent.** What the product is for, and who it is for. The routes tell you what it does; they do not tell you why. This is usually worth asking.
- **The MVP boundary, if you are planning new work.** What is core versus what can wait. Only ask if the engineer wants a feature plan out of this audit; if they just want the bundle so they can maintain what exists, skip it.
- **Decisions the code deliberately punted on.** A config value that is still the framework default, a TODO on a security check, a feature behind a flag. Show the engineer what you found and ask whether it is settled or still open.
- **Anything two files disagree about.** If the Dockerfile says one thing and the README says another, that is not a fact you can read; it is a decision the engineer has to make. Present both and ask.

Every question is a decision panel with options and one marked `(recommended)`, the same as `/selcy-sdd`. Never a neutral menu, never a free field when concrete options exist.

Do **not** ask:

- Anything in the dependency manifest. That is a fact.
- Anything the migrations or the schema answer. That is a fact.
- Anything the CI or Dockerfile answers. That is a fact.
- Anything you have not yet looked for. Looking is your job, and asking first is the failure mode this skill exists to prevent.

## Step 4: Report

In plain language, in this order:

1. **What the bundle now says**, one line per file.
2. **The gaps**, every field written as `not evident from the repo`, with the file and line you checked. This is the most useful part of the report: it is the map of what the engineer knows and the code does not.
3. **The findings**, things the audit surfaced that are not gaps in the bundle but problems in the code: a security check that is missing, a test level that is absent, an inconsistency between two files, a migration story that does not exist. Each one is a candidate for `/selcy-debt`.
4. **The exact next step.** Usually: open a new chat, run `/selcy-implement` on the first feature under Next Up, or `/selcy-debt` to record the findings before they get lost.

Keep it short. It is a handoff, not an assessment of the codebase.

## Step 5: verify mode (read only)

Used when a bundle exists and you want to know whether it still matches the code. Writes nothing.

For each file in the bundle, read it, then read the code it describes. Report only disagreements, in three categories:

- **Stale**: the bundle names something the code no longer has. A dependency that was removed, a table that was dropped, a route that was deleted, an env var that is no longer read.
- **Missing**: the code has something the bundle never recorded. A new module, a new table, a new env var, a new service in the compose file.
- **Wrong**: both name it, but they disagree. The bundle says the error shape is one thing and the routes return another.

For each: the file and line in the bundle, the file and line in the code, and the recommended fix, which is almost always `/selcy-sync` for a drift in a standards file, or `/selcy-sdd specs <feature>` for a spec that no longer matches.

Never edit anything in verify mode. It is a report. `/selcy-sync` is the tool that acts on it.

## What this skill never does

- **Never invents a fact to fill a gap.** `not evident from the repo` is a complete and correct answer.
- **Never writes application code.** It reads it and writes about it.
- **Never overwrites an existing bundle without asking**, and never overwrites a file the engineer wrote by hand without asking.
- **Never runs `/selcy-sdd`.** That is the greenfield door. If the engineer wants a fresh interview on an existing codebase, tell them the interview will contradict the code and let them decide.
- **Never edits the feature list or decides what to build next.** It reports what the repo shows is unfinished; what to do about it is the engineer's.
- **Never fixes the findings it surfaces.** It reports them. Recording them is `/selcy-debt`, fixing them is `/selcy-implement` or `/selcy-debug`.

## Portability

Any Agent Skills client on macOS, Linux, Windows. Shell snippets are POSIX reference; use your agent's cross platform file tools for every file action. The survey table above names what to look for, not literal filenames for every stack; read the equivalents for the language you find.
