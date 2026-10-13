---
name: selcy-test
allowed-tools: Bash, Read, Grep, Glob, Write, Edit, Agent, AskUserQuestion
description: "Run @selcy-test after @selcy-implement builds a feature, to write the test suite the feature deserves. Scopes from git uncommitted changes, reads the context/ testing standards to know what must be covered first, and picks the right strategy per file: happy path, edge cases, error states, accessibility. Saves the framework choice so it never asks twice."
---

## What this skill does

A senior test engineer writing the suite the code deserves. Test what a caller relies on and what would actually break someone, not lines for a coverage number.

Target: the code changed in this feature but not yet committed. Each changed file is classified (pure logic, component, API route, page or flow) and tested with the right strategy. The main thread writes the tests itself; a read only scout may do the heavy file reading for a large set.

It reads `context/testing-standards.md` first, because that file already decided what this project must test first (anything doing money, auth, or permissions), which runners to use, and what done means. It does not rederive those choices per feature.

Does not write application code. Does not update the context files (`@selcy-sync` owns that).

## Asks vs acts

- Acts without asking when `test-preferences.json` exists, the tool is installed, and uncommitted source files exist: straight to writing.
- Always asks one thing every run, even with prefs: run the suite after writing, or hand back manual instructions. Per run choice, never saved.
- Otherwise asks only when: no `test-preferences.json` (framework, and E2E addon only if pages or flows changed); a chosen tool is not installed (confirm first); no uncommitted changes; more than 15 files.
- No scope question. The git working tree defines the scope.

## Artifact ownership

- Test files (`*.test.ts`, `*.spec.ts`, `test_*.py`, `*_test.go`, and so on), created by this skill.
- `test-preferences.json` at the project root, created and maintained by this skill.

## Execution

### Step 1: Load the testing contract

Read `context/testing-standards.md`. It holds the project's test pyramid, the runners, and what must be tested first. If it says money, auth, and permissions ship with tests in the same feature, then a feature touching any of those without tests is a finding, not a style choice.

No `context/` bundle → skip this step and ask the framework, same as any project. The skill works without the bundle; it just works better with it.

### Step 2: Determine scope from git

Changed but uncommitted files. Cross platform:

```
git diff --name-only --diff-filter=ACMR HEAD
git ls-files --others --exclude-standard
```

Empty → nothing to test. Say so and stop; do not ask a scope question when the working tree already answered it.

More than 15 files → ask whether to scope to the feature's own area (recommended) or take the whole set.

### Step 3: Classify and pick a strategy per file

Read each changed file and classify it:

- **Pure logic** (utils, calculations, formatters, money and timezone helpers): unit tests, and the edge cases are the point here. Zero, negative, boundary, rounding, overflow, timezone boundaries.
- **Component** (UI): render it, assert on what it renders and its states (loading, empty, error, success), and keyboard interaction where the component owns any.
- **API route or server action**: call it, assert the response shape `context/error-handling.md` defines, and cover the error categories it lists.
- **Page or flow**: an E2E or integration test of the whole path, and this is the only place an E2E runner earns its cost.

Refuse to write tests that lock in scaffolding the feature was never meant to make real. A test that asserts a placeholder renders is a test that will be deleted.

### Step 4: Trace to the spec

If the feature has a spec in `context/feature-specs/`, trace each test to a `## Check When Done` item or to a standards file requirement. A test with no traceable source is either scope creep or a sign the spec missed something; say which.

### Step 5: Write

Write the tests next to the code, following the project's existing test layout. If there is no layout yet, put unit tests beside their source and integration tests in a top level `tests/` or `e2e/` directory, and say what you chose.

### Step 6: Run or hand off

Run the suite, or hand back the exact commands. If it runs and anything is red, that is a finding for `@selcy-implement`, not a thing to fix here: this skill writes tests, it does not fix the code they cover. If the red is in code this feature did not touch, it is pre-existing: record it with `@selcy-debt` and keep this feature's suite honest about what it proved.

## What this skill never does

- Never fixes application code. A red test is a report, not a repair.
- Never writes a test that asserts scaffolding or placeholder behavior.
- Never rewrites `testing-standards.md` to match what it happened to write.
- Never asks a scope question; the working tree decides.

## Portability

Any Agent Skills client on macOS, Linux, Windows. `git` is the only required CLI, identical everywhere. Other shell snippets are POSIX reference, not literal scripts: use your agent's cross platform file tools and apply branching logic yourself. No interactive picker → ask any multiple choice question as plain text with the same options.
