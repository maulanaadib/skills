# Decision gate

Read this in full before generating any feature spec. It is the test that decides whether a feature writes silently from state or pauses to ask.

## The core rule

A feature spec is a build contract. Every value the builder must produce, compute, or display has to have a named source somewhere in the bundle: an input, a database column, a derivation from a named value, a prior decision in `architecture-context.md`, or a line in the spec itself.

> Enumerate every value this build must produce, compute, or display. For each, does the bundle name where it comes from? Any required value with no named source is an unresolved decision, and it must be asked, not invented.

This is the same input coverage test `/selcy-implement` runs on itself. If the gate passes here, the build runs without stopping. If it fails here, the build would have stopped, or worse, silently invented. Asking now is strictly cheaper.

## Step 1: Enumerate the decisions

For each feature, list what it requires across these nine categories. Not every category applies to every feature; say which do not.

- **Data model.** New entities, fields, relations, indexes, constraints, migrations. Which are already settled in `data-model.md`?
- **Integrations.** Providers, libraries, SDKs, external services. Which are already chosen in the stack table? Any env var a new integration needs is a row in the `architecture-context.md` env var table, not a name invented in the spec.
- **UI composition.** Pages, sections, component inventory, layout, states (loading, empty, error, success), asset strategy. Settled only if `ui-context.md` pins the design system and the spec pins the page.
- **Behavior.** What the feature does, precisely. Search, filtering, wizards, generation, flows. The classic owed decision: "what exactly should it do?" is open.
- **Edge and error handling.** Failure modes, retries, idempotency, partial failure, permission denial, empty and error states. Which follow `error-handling.md` without a new decision?
- **Security.** Auth, authorization, input validation, secrets, compliance. Which follow `security-standards.md` without a new decision?
- **Architecture placement.** Which module the feature lives in, and whether it crosses a module boundary (a scope split, not a design choice).
- **Testing.** What this feature must ship tests for, per `testing-standards.md`.
- **Scope limits.** What this feature deliberately does not do, so the builder does not build it.

## Step 2: Resolve each

For every enumerated decision, in order:

1. **Answered in state or the interview** → fill it into the spec. Silently. This is the point of the whole skill: the interview already paid for this answer.
2. **Settled by the stack or a context file** → fill it in, and cite the file in the spec so the builder knows it is not this feature's decision to reopen.
3. **Derivable from a prior feature spec** → fill it in, and name the feature it depends on.
4. **Unresolved** → collect it. These are the only questions generation asks.

## Step 3: Ask, one feature at a time

If a feature has unresolved decisions:

- Ask them as one batched round for that feature, up to 4 questions. Same round mechanics as the interview: options, one `(recommended)`, one line why.
- Never batch across features. The engineer approves or corrects one feature at a time, exactly like the per feature chat loop this feeds.
- Record the answers in state under that feature's `unresolved decisions`, then write the spec.

If a feature resolves fully from state and context, write it without asking and say so in the handoff report, so the engineer knows the skill decided for them and can object.

## Step 3b: Write the progress tracker handoff

Every feature spec ends with a `## Progress Tracker` section. This is not optional, and it is the fix for the loop breaking in practice: it tells the builder exactly which `progress-tracker.md` fields to touch when the feature lands, so the engineer never has to repeat the instruction per chat.

It names, concretely:
- the feature name to move from `Next Up` to `In Progress`, then to `Completed`
- any `Open Questions` the feature answers or raises
- any `Architecture Decisions` the feature records
- one line of `Session Notes` so the next chat can resume

Without this section, the per chat loop silently degrades: the builder finishes, the engineer closes the chat, and the next chat starts blind. With it, closing a chat is safe.

## What must never be silently decided

Even with a full interview behind it, these stay questions, because they are where a builder most often invents:

- A **provider, library, or integration** not already in the stack table.
- A **whole page or screen** whose composition `ui-context.md` does not pin.
- A **data model** for a new entity, down to fields and indexes.
- A **behavior** that is not trivial (search, generation, wizards, payment flows).
- A **permission or ownership rule** (who may read and mutate what).
- **Money or timezone** handling, if Stage 3 did not settle the rule and this feature touches it.

## Scope limits are mandatory

Every feature spec ends with a `## Scope Limits` section listing what is deliberately out. This is what keeps one feature from silently absorbing the next one, and what makes the per chat loop safe: a builder reading the spec knows the boundary of its own chat.

Write it even when it feels obvious. "Do not add persistence yet" is the line that stops a canvas feature from becoming a persistence feature.
