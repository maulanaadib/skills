---
name: selcy-grill
allowed-tools: Bash, Read, Grep, Glob, Write, Edit, Agent, AskUserQuestion
description: "Run /selcy-grill on any decision in a running project. Interviews you relentlessly across the design tree until every branch is resolved, then writes the decision down where the bundle keeps it. The interview primitive behind /selcy-sdd, usable on its own. Use it before a change whose design is still open."
---

## What this skill does

The interview primitive, on its own. `/selcy-sdd` uses this discipline once, at project start, to settle everything before the bundle is written. This skill uses it on **one decision**, in a project that is already running, when you are about to touch something whose design is still open.

You run it instead of guessing. You have a change in mind, you can feel that the design is not settled, and you know that if you start building now the builder will either invent the answer or stop and ask you mid build. This skill settles it first.

It exists because the interview was locked inside `/selcy-sdd`, which runs once. Every project after that first run, and every brownfield project that never ran it, had no way to get a decision grilled. The frontier mechanics are the useful part; the one-shot framing was not.

## When to run it

- **Before a change whose design is open.** You are about to touch the payment flow, or add a new entity, or change how sessions work, and you can name two or three ways it could go.
- **When `/selcy-implement`'s gate failed.** It stopped and said a value has no named source. That is an owed decision, and this skill is how you settle it properly instead of answering it in the builder's chat, under pressure, mid build.
- **When you disagree with a standards file.** The bundle says one thing, the code says another, or you have learned something since it was written. Grill the decision, then update the file with the outcome.
- **When a bug revealed a flawed decision.** `/selcy-debug` says "this is not a coding mistake, the decision was wrong." Grill the replacement decision before rebuilding on it.

Do not run it for a change with one obvious implementation. Grilling a settled question wastes everyone's time and trains you to skip the skill when the question is hard.

## The design tree

The decision is a tree, not a list. Every decision branches into the decisions that hang off it. Work the tree in **rounds**.

The **frontier** is every question whose prerequisites are already settled: the questions you can ask now without guessing at answers you have not heard yet. Ask the whole frontier in one round, then wait for the answers before the next round.

A question whose answer depends on another question still open in this round belongs to a **later round**, not this one. Each round of answers reshapes the tree: settled decisions push the frontier outward and unblock the questions that depended on them. Recompute the frontier after every round.

This is the whole mechanic. It is why the interview does not ask you about deployment before you have said what the product is, and why it never asks a question whose answer it is about to invalidate.

## Finding facts is your job, never the engineer's

When a frontier question needs a fact from the environment, look it up yourself. Read the code, read the config, read the bundle, check what is installed. Do not ask the engineer for anything you could look up.

Do not block on it either. A running lookup is an unsettled prerequisite, so only the questions downstream of it wait; ask the rest of the frontier now. The _decisions_ are the engineer's: put each to them and wait.

This matters most on a running project, where the answer is often already in the code and the engineer's memory of it is stale. "Which fields does the Invoice have" is answered by `schema.prisma`, not by the engineer, and the schema is more likely to be right.

## Step 0: Frame the decision

Ask the engineer one question, in plain text: **what is the decision you are here to settle?** If they gave it as an argument, restate it in one line and confirm.

Then name the scope, in one line each:

- **What this decision touches.** The module, the feature, the file, the flow.
- **What it does not touch.** The boundary, so the interview does not sprawl into the whole system.
- **Where the answer will be written.** Which bundle file owns this decision, if a bundle exists. See Step 4.

If there is a `context/` bundle, read the file that owns this kind of decision **before** you ask anything, and treat it as settled context:

| If the decision is about | Read first |
| --- | --- |
| The stack, storage, auth model, invariants, env vars | `architecture-context.md` |
| Module boundaries, architecture style, when to split | `architecture-standards.md` |
| Auth, authorization, validation, secrets, compliance | `security-standards.md` |
| Error shape, categories, logging, observability | `error-handling.md` |
| Runners, the pyramid, what is tested first | `testing-standards.md` |
| Entities, fields, indexes, relations, migrations | `data-model.md` |
| Theme, colors, typography, components | `ui-context.md` |
| Type strictness, folder contract, git workflow | `code-standards.md` |

A decision that contradicts a standards file is not settled by this skill alone. It is settled here, then written to that file, and `/selcy-sync` is what flags the specs that the change made stale.

## Step 1: Build the tree, silently

Before the first question, build the tree in your own head or in scratch space. Do not show it to the engineer.

- What does this decision directly settle?
- What hangs off it? For each branch, what would change if the answer went the other way?
- Which branches are already settled by the bundle, the code, or the config? Those are leaves. Do not ask them; state them as context in the first round so the engineer can correct you if they are wrong.
- Which branches are genuinely open? Those are the frontier.

You are not interviewing to explore the space. You are interviewing to resolve a tree you have already mapped. An unstructured interview on a running project is an open ended discussion, which is exactly what the engineer was trying to avoid by running this skill.

## Step 2: Run the rounds

Every question is a decision panel, never a neutral menu:

- 2 to 4 concrete options, real to this project, each with a one line consequence.
- Exactly one marked `(recommended)`, with a one line why. You are making the call and letting the engineer override, not offloading it.
- Never add your own `Other` option. If the agent has a picker it appends `Other` automatically; if not, say in plain text that a free text answer is welcome.
- Batch related questions up to 4 per round.
- Fold prior answers forward so the interview reads as one continuous conversation, not a form.
- Infer and skip anything already answered, already in the code, or already in the bundle. Re asking is a bug.

Format each round so the engineer can answer it fast:

```text
**Q1 — <question title>**
<question body, and the options with consequences>

➡️ Recommended: <your pick> — <one line why>

---

**Q2 — <question title>**
...
```

Word each question so "yes" accepts your recommended answer. The engineer should be able to answer a round by reading the recommendations and saying yes, no, or a number.

After each round, recompute the frontier. Some answers will have closed branches you expected to ask about; say so, and drop them. Some will have opened branches you did not anticipate; add them. The tree is live, not a script.

## Step 3: The completeness gate

The interview is done when the frontier is empty: every branch of the design tree visited, nothing left silently assumed.

Before you declare it done, check the branches you marked as leaves in Step 1. Each one was settled by the bundle or the code. State each back to the engineer in the final round, with its source, so they can object to one without having to restate the whole decision. "I am taking the session model from `security-standards.md` as read; tell me if that is wrong."

Then one confirmation round: the whole decision shown back, with every resolved branch and its source, and one question: approve, or change something. Until it is approved, nothing is written.

## Step 4: Write the decision down

A decision that stays in chat is a decision the next chat does not have. Where it goes depends on what exists:

**A `context/` bundle exists** → write it to the file that owns it, from the table in Step 0. Surgical edit: add a line, or rewrite the one line this decision replaced. Never rewrite a whole section, and never touch prose the engineer wrote by hand without asking. Then run `/selcy-sync` or tell the engineer to, because a standards file change may have made specs stale, and that is what catches it.

**No bundle exists** → write it to `decisions/` at the project root, one file per decision, dated, with the question, the options, the pick, and the why. This is the thinnest possible record, and it is enough for a project that is not using the full loop. If the project later runs `/selcy-audit`, those files are the first place it looks for decisions the code cannot express.

**The decision is load bearing and hard to reverse** → also write it as an ADR, in `docs/adr/` or wherever the project keeps them, following the convention the repo already uses. Only when all three are true: hard to reverse, surprising without context, and the result of a real trade off. If any is missing, the line in the standards file is enough and an ADR is ceremony.

## Step 5: Report

In plain language:

- The decision, in one sentence.
- What it settled, and what it left open on purpose, with the reason.
- Where it was written, with the file path.
- What it made stale, if anything, and the exact `/selcy-sync` or `/selcy-sdd specs <feature>` command to fix each.
- The exact next step: usually `/selcy-implement`, now that the gate that stopped it has an answer.

Keep it short. The decision is the artifact; the report is a handoff.

## What this skill never does

- **Never builds anything.** It settles a decision and writes it down. Building is `/selcy-implement`.
- **Never asks a question it could answer by reading.** Looking up a fact is your job.
- **Never writes to chat memory and calls it done.** If it is not in a file, the next chat does not have it.
- **Never edits a feature spec.** If the decision changes what a feature must build, that spec is regenerated by `/selcy-sdd specs <feature>`, not edited here.
- **Never rewrites a standards file wholesale.** Surgical edits only. A standards file is a contract other features are built against; a rewrite breaks them all.
- **Never skips the confirmation round.** An unconfirmed decision written to a contract file is a silent decision, which is the exact failure this loop exists to prevent.

## Portability

Any Agent Skills client on macOS, Linux, Windows. No interactive question picker → ask every round as plain text with the same options and the same `(recommended)` marker. Shell snippets are POSIX reference; use your agent's cross platform file tools for every file action.
