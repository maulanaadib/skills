---
name: selcy-debug
allowed-tools: Bash, Read, Grep, Glob, Write, Edit, Agent
description: "Run /selcy-debug when something is broken. Reproduces the bug on demand, narrows it to the smallest failing surface, changes one thing at a time, fixes the root cause with the smallest possible change, and hands a regression test to /selcy-test. No features, no extra refactors."
---

## What this skill does

The investigator who trusts evidence over intuition. A bug is a case to be proven: reproduce it on demand, narrow it to the smallest failing surface, change one thing at a time so every result means something.

Resist patching what you see (the null, the crash) before understanding why it is there. A fix you cannot explain is a bug you have not caught.

A structured root cause investigation, not guess and check. Bugs are found by a loop: reproduce → localize → hypothesize → test the hypothesis → fix the root cause → verify. This skill runs that loop with discipline, one hypothesis at a time, each confirmed or rejected by evidence, until the cause is proven. Then it applies the smallest fix.

## Asks vs acts

Acts. It reproduces, investigates, and fixes. It asks only when it cannot reproduce the bug from what it was given, then it asks for exact steps, inputs, environment, and the observed versus expected behavior. It does not ask permission to investigate.

## Artifact ownership

Writes the minimal code fix for the root cause. Recommends `/selcy-test` for the regression test, or writes a failing then passing test inline if that is the fastest proof. Does not add features, refactor unrelated code, or rewrite a spec.

If the bug reveals a flawed decision rather than a coding mistake, it says so and points at `/selcy-sdd specs <feature>` rather than papering over it. A bug caused by a wrong standards file is not fixed by editing code around it.

If the bug predates the change being investigated, it is not this feature's to fix here. Record it with `/selcy-debt` and hand it to the feature that owns it.

## Execution

### Step 0: Capture the symptom

Pin it down precisely, before touching code:

- **Observed**: the exact error, stack trace, wrong output, or screenshot.
- **Expected**: what the spec, a standards file, or the feature's `Check When Done` says should happen. Name the source. If no source names the expected behavior, that is an owed decision and the bug is partly a spec gap; say so.
- **Reproducible**: the exact steps that trigger it, every time or intermittently.

### Step 1: Reproduce

Reproduce it on demand before anything else. If you cannot, do not guess at a fix. Ask for the missing detail, or set up the conditions the report describes.

An intermittent bug is still reproducible; it just has a condition you have not found yet. Find the condition before fixing.

### Step 2: Localize

Narrow to the smallest failing surface. Bisect: the whole app, the feature, the module, the function, the line. Use the stack trace, the logs, and the feature spec to jump, but verify each jump.

### Step 3: Hypothesize, one at a time

Form one hypothesis about the cause. Design the cheapest test that would confirm or reject it. Run it.

- Confirmed → you have a candidate cause. Move to Step 4.
- Rejected → you have eliminated one possibility, which is real progress. Form the next hypothesis.

Never hold two hypotheses at once, and never fix before a hypothesis is confirmed. A fix built on an unconfirmed guess is a guess about the bug, not a fix for it.

### Step 4: Fix the root cause

The smallest change that removes the cause. Not the symptom: if the cause is a missing validation, the fix adds the validation, it does not catch the resulting error downstream.

One change. Then verify. If the fix does not work, revert it and return to Step 3 with the new evidence; do not stack changes until something happens to work.

### Step 5: Verify

The bug no longer reproduces under the exact steps from Step 0, and the feature's `Check When Done` still passes. Both, not just the first: a fix that silences the bug and breaks the feature is not a fix.

### Step 6: Hand off the regression test

Recommend `/selcy-test` for a regression test that would catch this bug if it returns. Or write a failing test that reproduces the bug, confirm it fails before the fix and passes after, and hand it to the engineer.

The regression test is the point. A bug fixed without one is a bug that can come back unnoticed.

## What this skill never does

- Never fixes a symptom it cannot explain.
- Never holds two hypotheses at once.
- Never stacks changes until something works.
- Never refactors unrelated code while it is in there.
- Never adds a feature, even one the bug obviously suggests.
- Never edits a standards file or a spec to make the observed behavior correct.

## Portability

Any Agent Skills client on macOS, Linux, Windows. Commands are reference; use the project's real test and run commands and your agent's own tools. The investigation can run in a subagent or inline if your tool has no subagents.
