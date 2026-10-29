---
name: selcy-debt
allowed-tools: Bash, Read, Grep, Glob, Write, Edit, Agent, AskUserQuestion
description: "Run /selcy-debt when you find a bug that is not yours, or a gotcha the next chat needs. Records pre-existing bugs with the feature that owns them, and per-module gotchas, in context/debt.md so the current chat stays clean and the finding has a home. Read only on the debt file. Never fixes anything."
---

## What this skill does

The memory the loop was missing. Two things pile up in a running project and have nowhere to go:

1. **A pre-existing bug found while building feature N that belongs to feature M.** You are building the customers page and you find a bug in the auth flow. It is not a regression from your feature. It is not yours to fix inside this feature's scope. But if you do not write it down somewhere structured, one of three things happens: you fix it now and blow through the feature's scope, you write it in chat and the next chat never sees it, or you append it to `progress-tracker.md` Session Notes where it sits forever, unowned, until someone re-trips it.

2. **A gotcha.** Something the next chat has to know before it touches a module again. The seed script only works with the flag in a specific order. The E2E suite has to be started before the dev server, not after. The Dockerfile copies `prisma` before it can generate the client, so a schema change needs a clean build. These are hard won, expensive to relearn, and they currently accumulate without bound in Session Notes.

This skill records both, in one file, in a shape the loop can act on. It is the reason a finding made in feature 07's chat survives into feature 12's chat.

## When to run it

- **You found a bug that predates your change.** You were building feature N, the failure is in feature M's code, and reverting your change would not make it go away. Record it, then finish feature N.
- **You hit something and had to learn it the hard way.** You lost time to it. If the next chat would lose the same time, it is a gotcha.
- **`/selcy-check` failed on something your feature did not touch.** The verifier found a red item in another feature's surface. That is a pre-existing bug, not a regression; record it and the current feature's verdict stays honest.
- **`/selcy-audit` surfaced a finding.** A missing test level, a security check that is not there, an inconsistency between two files. The audit reports them; this skill is where they get recorded.
- **`/selcy-sync` flagged a drift nobody has fixed yet.** A spec contradicts a standards file. That is debt with a known fix.

Do not run it for a bug your own change introduced. That is `/selcy-debug`, in this chat, right now. Debt is for findings that outlive the chat that found them.

## The one rule that makes it work

**The bug gets an owner, and the owner is a feature, not a person.**

A finding with no owner is noise. `progress-tracker.md` Session Notes is a list of findings with no owner, which is why it grows without bound and why nothing ever clears it. This file gives every finding a home: the feature whose scope it falls inside, or `foundation` when it is cross cutting, or `unowned` when you genuinely cannot tell. Those three are the only options, and `unowned` is the one that means *triage me*.

## Commands

- **No argument** → record mode. You bring the finding, this skill writes it down.
- **`list`** → read only. Print the debt file grouped by owner, open first, resolved last. Use it at the start of a chat that is about to touch a module, to see what the last chat learned.
- **`<module>`** → read only, filtered. `selcy-debt auth` prints only the findings whose owner or module is `auth`. Run this before you touch that module.
- **`resolve <id>`** → mark one finding resolved. Takes a one line how, and the command or commit that fixed it. Does not delete the row; resolved rows are the audit trail that the debt was real and is gone.
- **`triage`** → review every `unowned` finding and assign it an owner, one panel. Use it when the unowned list grows past a handful.

## Step 0: Find the file

`context/debt.md` at the project root, alongside the rest of the bundle. It is a bundle file, so the same rules apply: it is read by the next chat, it is not chat memory, and it is maintained surgically.

If it does not exist, create it from the structure in Step 3. If `context/` itself does not exist, this skill still works: write `debt.md` at the project root and say so. A project that has not run `/selcy-sdd` or `/selcy-audit` still finds bugs, and this is the thinnest possible record for them. If the project later runs `/selcy-audit`, the audit reads this file first, because it is the list of everything the code's previous maintainers already knew was wrong.

## Step 1: Classify the finding

Ask one question, and answer it from the code, not from memory:

**Is this a bug or a gotcha?**

- **Bug** → something is wrong. There is a wrong behavior in the running app. It needs fixing. Record: the symptom, the surface, the owner, the evidence.
- **Gotcha** → nothing is wrong. There is a trap in how the module has to be worked with. It needs *knowing*. Record: the module, the trap, the correct incantation, the cost of relearning it.

If you cannot tell, it is a bug. A gotcha you are unsure about is a bug you have not reproduced yet.

## Step 2: Assign the owner

For a **bug**, the owner is the feature whose scope the fix falls inside, never the feature that found it. Determine it from the code:

- Read the failing surface. Which feature spec built it? Check `progress-tracker.md` for the feature that owns the module the failing code lives in.
- Cross cutting, or in code every feature shares (a shared component, a shared util, the schema) → owner is `foundation`.
- No bundle exists, or the code predates the bundle → owner is `unowned`. Say plainly that this means *triage me*, and recommend `/selcy-debt triage` when the list grows.

The feature that found it goes in a separate field, `found-while`, and it is never the owner. This is the whole point: feature 07 finds the bug, feature 03 owns it, and feature 07's chat does not have to fix it to close.

For a **gotcha**, the owner is the module the trap lives in. Use the module name from `architecture-standards.md` if a bundle exists, or the folder name if not.

## Step 3: Write the row

Append to `context/debt.md`. Two sections, one shape each.

### Bugs

```markdown
### BUG-<n> — <one line symptom>

- **status**: open
- **owner**: <feature name, `foundation`, or `unowned`>
- **found-while**: <feature being worked on when it was found, or `audit`>
- **surface**: <the route, component, function, or file where it shows up>
- **evidence**: <how you know. The failing assertion, the error, the repro step. Not a guess.>
- **impact**: <who hits it and when. One line.>
- **fix scope**: <one line on what fixing it touches. Leave blank if you do not know; do not guess.>
- **recorded**: <date>
```

### Gotchas

```markdown
### GOTCHA-<n> — <one line: the trap>

- **module**: <the module or folder the trap lives in>
- **the trap**: <what a reasonable person would do, and why it fails>
- **do this instead**: <the exact step or order that works>
- **cost of relearning**: <one line: the time or the failure mode it caused>
- **recorded**: <date> by <feature or chat that learned it>
```

Numbering continues from the highest existing id in the file. Never renumber, never recycle an id, never delete a row. Resolve in place by editing `status`.

Rules that apply to every row:

- **Evidence or it does not go in.** "The select component is broken" is not a finding. "Every `Select.Value` renders `undefined` because the shared wrapper does not forward the slot prop, reproduced on `/customers` and `/settings`" is a finding. If you cannot state how you know, you have not found it yet.
- **Write the fix scope only if you know it.** A blank `fix scope` is honest and useful; a guessed one becomes a wrong plan someone trusts.
- **One finding per row.** Two bugs found in the same investigation are two rows. A row with two owners is a row nobody owns.
- **Never write a fix into the row.** The row records the finding. The fix is `/selcy-implement` or `/selcy-debug` in a separate chat, scoped to the owning feature.

## Step 4: Say what the current chat should do

After recording, answer one question out loud: **does the current feature still ship?**

- **Yes, the finding is outside its scope** → say so plainly, finish the feature, and name the exact next step for the finding: a new chat running `/selcy-debug` or `/selcy-implement` scoped to the owning feature. This is the normal case, and it is the answer to the failure mode this skill exists for: the current chat does not have to fix a bug it did not make, and the bug does not get lost.
- **No, the finding blocks it** → the current feature cannot ship until the owning feature is fixed. Say so, and stop. Do not fix the other feature from inside this chat; that is scope creep in the exact shape this loop exists to prevent. Recommend a separate chat for the owner, and say the current feature is blocked on it.
- **Unsure** → ask, as a decision panel: ship and record, or block and fix. Never decide this silently.

## Step 5: Report

In plain language, in this order:

1. **The id**, so the engineer can refer to it: `BUG-4` or `GOTCHA-2`.
2. **The owner and the found-while**, in one line, because that distinction is the whole value: "BUG-4, owned by 03-auth, found while building 07-project-apis."
3. **What the current chat does now**, from Step 4.
4. **The exact next step for the finding**, as a command: `/selcy-debug` in a new chat scoped to 03-auth, or `/selcy-implement` if the fix is a small scoped change.
5. **Whether the debt file was created or already existed.**

Keep it short. The row is the artifact; the report is a handoff.

## What this skill never does

- **Never fixes the finding it records.** Recording is this skill's entire job. Fixing is `/selcy-debug` or `/selcy-implement`, in a chat scoped to the owner. A skill that both records and fixes will end up fixing from inside the wrong feature's chat, which is the exact scope creep this loop exists to prevent.
- **Never edits a feature spec or a standards file.** If the finding means a spec is wrong, that is `/selcy-sdd specs <feature>` to regenerate it, not an edit here.
- **Never deletes or renumbers a row.** Resolve in place. The resolved rows are the audit trail, and an id that changes breaks every reference to it.
- **Never records a bug the current change introduced.** That is `/selcy-debug`, now, in this chat. Debt is for findings that outlive the chat.
- **Never writes to `progress-tracker.md` Session Notes.** That is where the unbounded growth came from. The debt file replaces it for findings; Session Notes keeps one line per session for resume context, which is all it was ever meant to hold.
- **Never records a finding without evidence.** If you cannot say how you know, it is not a finding yet.
- **Never decides silently whether the current feature still ships.** When it is not clear, ask.

## Portability

Any Agent Skills client on macOS, Linux, Windows. No interactive question picker → ask Step 4's question as plain text with the same options. Shell snippets are POSIX reference; use your agent's cross platform file tools for every file action.
