# Interview guide

Read this in full before you ask the first question. It holds the stages, the round mechanics, and the completeness gate. Do not open the interview, generate a question, or write a file until you have read it.

## Round mechanics

The interview works a **design tree**, not a checklist. Every decision branches into the decisions that hang off it. Work the tree in **rounds**.

The **frontier** is every question whose prerequisites are already settled: the questions you can ask _now_ without guessing at answers you have not heard yet. Ask the whole frontier in one round, then wait for the answers before the next round.

A question whose answer depends on another question still open in this round belongs to a **later round**, not this one. Each round of answers reshapes the tree: settled decisions push the frontier outward and unblock the questions that depended on them. Recompute the frontier after every round.

The stages below are the **dimensions** the tree must eventually cover. They are not a script. Ask Stage 0 first, because nearly everything hangs off it, but after that ask what is ready, not what is next.

Every question is a decision panel, never a neutral menu:

- 2 to 4 concrete options, real to this project, each with a one line consequence.
- Exactly one marked `(recommended)`, with a one line why. You are making the call and letting the engineer override, not offloading it.
- Never add your own `Other` option. If the agent has a picker it appends `Other` automatically; if not, say in plain text that a free text answer is welcome.
- Batch related questions up to 4 per round. Fold prior answers forward so the interview reads as one continuous conversation.
- Infer and skip anything already answered, already in the repo, or already in state. Re asking is a bug.

**Finding facts is your job, never the engineer's.** When a frontier question needs a fact from the environment (the repo, the filesystem, what is already installed), look it up yourself; do not ask the engineer for anything you could look up. Do not block on it: a running lookup is an unsettled prerequisite, so only the questions downstream of it wait; ask the rest of the frontier now. The _decisions_ are the engineer's: put each to them and wait.

State is saved after every round, so a lost chat resumes cleanly.

## Stage 0: Framing (3 to 5 rounds)

The product and the working terms. Cheap to ask, and everything downstream reads them.

- **Product name and one line description.** What it is and who it is for, in one sentence each.
- **Doc language.** Indonesian or English for the generated context files and feature specs. Code, file paths, commands, and identifiers stay English either way. (Recommended: match how the engineer talks in this chat.)
- **MVP boundary.** The smallest version that delivers the core value. The single most important question in the interview; every later cut is judged against it. Offer 2 to 3 concrete shapes of the MVP, not an open field.
- **Primary audience.** Only if the one line description did not already settle it.
- **Monetization.** Free / subscription / one time / usage based / ads / none yet. Shapes whether billing is a foundation or a deferred feature.
- **Success metric.** Signups, activation, revenue, retention. Informs whether analytics is a foundation.
- **Hard constraints.** Deadline, budget, team size, compliance scope (PCI, GDPR, HIPAA, region specific). Any of these can reorder the whole plan.

## Stage 1: Capabilities (1 to 2 rounds, multi select)

The cross cutting capabilities this product plausibly needs. Present as a multi select, never name the implementing tool here (that is Stage 3):

authentication, multi tenant orgs, payments or billing, email or notifications, file or media upload, search, realtime collaboration, admin panel, public API, AI features, offline support, internationalization.

For each selected, confirm: **in this first build, or deferred?** Each in scope selection becomes one or more features. Each deferred one is recorded in `project-overview.md` under Out Of Scope, so the plan stays honest about what was considered and cut.

## Stage 2: Cross cutting and go to market (1 to 2 rounds)

Routinely forgotten, and expensive to retrofit. Ask even for internal tools, where the answer is often "not applicable":

- **SEO.** Public or marketing pages, metadata, sitemap, structured data, social cards, SSR or SSG needs. Skip for auth walled internal apps, and say why you skipped.
- **Performance.** Core Web Vitals targets, caching expectations, expected load and concurrency.
- **Analytics and error monitoring.** Product analytics, error tracking, conversion events.
- **Accessibility.** WCAG target level, keyboard navigation, screen reader support.
- **Legal and compliance.** Cookie consent, privacy policy and terms, GDPR or CCPA scope, age gating.

Each `yes` becomes its own feature or folds into a relevant feature's acceptance criteria.

## Stage 3: Stack (2 to 4 rounds)

This is where `/architect` ARCHITECTURE mode lands. One round per dependency cluster, each option carrying a recommendation and a one line why. Recommend on top of what the repo and Stage 0 already show; never recommend a tool that fights an existing constraint.

Cluster order (each batched round covers one):

1. **Language and runtime, framework, rendering strategy.** Monolith versus split front and back end; server components versus SPA; SSR or SSG needs from Stage 2.
2. **Database, ORM or query layer, and local dev database.** Relational versus document; migration strategy; how the engineer runs it locally (Docker, installer, managed, sqlite for dev).
3. **Auth and session.** Self hosted library versus managed provider; where session and user data live; MFA and social needs.
4. **Storage, hosting, background jobs, observability, testing.** Blob or file storage; hosting target; long running work (queue, durable tasks, or none yet); error tracking; unit and e2e test runners.

For each tool, also settle the **money and precision rule** if the product touches money, and the **timezone rule** if it touches reporting, shifts, or daily buckets. These are the two decisions most often silently invented during a build, and they are cheap to settle here.

Every Stage 3 answer is written to state and becomes the `architecture-context.md` stack table. Nothing here is deferred to feature specs.

### How to recommend a stack honestly

The engineer often does not know the options well enough to compare them. That is exactly when a recommendation matters most, and exactly when it is most dangerous: a confident pick the engineer cannot evaluate is a silent decision dressed as a recommendation.

Three rules, in order:

1. **Fit for this project first, always.** The recommendation is the option that best fits the Stage 0 product, the Stage 2 constraints, and what the repo already shows. Never the one you would pick in the abstract, never the one that wins a popularity contest.
2. **Name the tradeoff, not just the winner.** Every option in the panel carries a one line consequence, and the recommended one states what it gives up. "X, because it fits this project; it costs you Y" is a recommendation. "X (recommended)" is a menu.
3. **Say when the choice barely matters.** Some stack choices are genuinely load bearing (the database, the auth model). Others are not, and a senior engineer would tell you so. When two options are both fine for this project, say that plainly and recommend the one the engineer already knows, because familiarity is a real advantage: they can debug it, read its errors, and ship in it. Do not manufacture a difference to look rigorous.

**The AI tooling factor is a real constraint, and say it out loud.** How well AI tooling supports a stack is a legitimate engineering consideration for a project that will be built with AI assistance, and it is not the same as hype. Some stacks have deep agent support, mature docs that models have trained on, and large ecosystems of examples; others are thinner there, which shows up as worse suggestions and harder debugging, not as a worse language. When this factor is what tips a recommendation, name it as the reason, so the engineer can weigh it against their own priorities instead of guessing why you picked. And when the engineer's existing familiarity is the stronger argument, say that too. Neither is the default; both are allowed to win on the merits for this project.

**When the engineer does not know the options:** do not shrink the panel to one option and do not drop the tradeoffs. Give the recommendation, state what it gives up, and add one line on what kind of project would suit the other option instead. That is how an engineer learns to compare without the interview becoming a lecture.

## Stage 3b: Architecture shape (1 round)

The system shape, decided once so no feature spec reinvents it.

- **Architecture style.** Modular monolith, monorepo, or microservices. Present each with its real cost, recommend exactly one. (Recommended: modular monolith for a small team. One deploy, one codebase, module boundaries enforced by convention and lint, not by network. Microservices buy independent deploy at the cost of distributed system failure modes a small team cannot absorb.)
- **Module boundaries.** The modules the product will have, and what each owns. A feature touches one module.
- **Split triggers.** The conditions that would justify extracting a module or service. Written down so the decision is not relitigated per feature. Default: split only on measured evidence (a team boundary, a scaling bottleneck, an independent deploy need), never on anticipated scale.
- **Dependency direction.** What may depend on what. No cycles, no feature importing another feature's internals.

## Stage 3c: Security (1 round)

Non negotiable rules, written once so every feature inherits them instead of deriving its own.

- **Auth and session.** How identity is established and where session lives.
- **Authorization model.** Who may read and mutate what. The rule every mutation boundary enforces.
- **Input validation.** Where and how external input is validated (at the boundary, before any logic runs).
- **Secrets.** How secrets are stored and read, and what must never be logged.
- **Compliance scope.** GDPR, CCPA, UU PDP, PCI, HIPAA, or none. Named explicitly, because it changes what a feature must do.
- **Data protection.** What is PII in this product, how it is handled, and what must not be stored.

If the engineer has no opinion, recommend the strictest default that does not slow the first build, and say it is a default.

## Stage 3d: Error handling and observability (1 round)

The contract for failure. Decided once, so a builder never invents an error shape mid feature.

- **Error response shape.** One shape for every API response, success and failure.
- **Error categories.** Validation, not found, unauthorized, conflict, rate limited, internal. Which are retryable.
- **Logging.** What is logged, at what level, and what must never appear in a log line (secrets, tokens, PII).
- **Observability.** Error tracking, metrics, tracing. Which from day one, which deferred.
- **User facing errors.** What the user sees. Plain language, no stack traces, no internal names.

## Stage 3e: Testing (1 round)

What must be tested, where, and from which slice onward.

- **Runners.** Unit, integration, e2e. Which tools.
- **Test pyramid.** What each level covers, and from which feature onward it is required.
- **What is tested first.** Money, auth, permissions, and any invariant in `architecture-context.md`. These ship with tests in the same feature, never deferred.
- **Definition of done.** A feature is not done because it works. It is done because it is verified against its spec.

## Stage 4: UI direction (1 to 2 rounds)

Only if the product has a UI. Needed because `ui-context.md` is a foundation file every feature spec references.

**Before asking anything in this stage, check what already exists.** A design that the engineer has already settled is not a question, and re-asking it is how this skill overwrites a frozen decision with a fresh recommendation:

- **`ui-context.md` already exists** → **skip this stage entirely.** Read it back into state, say "UI direction is already settled in `ui-context.md`, skipping this stage," and continue to Stage 5. Do not re-ask theme, color, typography, or component foundation. The engineer already answered.
- **A design reference file exists but no `ui-context.md`** (the engineer names one, or a file like `design.md`, `design-system.md`, or a screenshot/repo reference is present at the project root) → **extract from it instead of asking.** Read the reference, derive the color table, typography, and radius scale from what it actually shows, and write them into `ui-context.md` with a `## Design Reference` section pointing back at the file. Then ask only what the reference cannot answer: **component foundation** (a component library versus hand rolled), because that is an implementation decision, not a design one. Say what you extracted and what you are still asking.
- **Neither exists** → check UI risk before running the full stage below. If the
  product has **5 or more screens, or any screen whose composition is genuinely
  unknown** (novel layout, untested user flow, no reference app) → **recommend a
  pen.dev session first**, before writing tokens. Say it as a panel: **design
  tool session first** (recommended when UI risk is real — wireframes resolve
  layout before tokens lock it in) or **skip to tokens now** (when the
  engineer already knows the layout and wants speed). If they pick the session:
  hand them the screen list (from the `## Screens` table — write it first, even
  provisionally, so the tool has something to work from), the three files
  (`ui-context.md` tokens so far, `product-context.md`, `project-overview.md`),
  and tell them to return with a `design-<name>.pen` (or PNG) saved at the
  project root. On return, **extract from it instead of asking** (same rule as
  the design-reference gate above) and record it under `## Design Reference`.
  This gate is what connects the suite to the design tool: without it, tokens
  are written blind and the first time anyone sees the layout is mid-build.
  Only when UI risk is low → run the full stage below.
- **Neither exists and UI risk is low** → run the full stage below.

This gate is what makes the skill usable on a project where the design is already decided. Without it, `/selcy-sdd` re-interviews a settled design and may recommend against it.

- **Theme mode.** Dark only, light only, or both. (Recommended: pick one only for the first build; theming both is a feature of its own.)
- **Color direction.** A named direction plus the accent color or colors. If the engineer has brand colors, take the hex values now.
- **Typography.** Font family or families (UI and mono), and how they load.
- **Component foundation.** A component library (shadcn/ui, or other) versus hand rolled. Radius scale and spacing scale.
- **Design references.** Any app, screenshot, or repo the engineer wants the UI to feel like. Optional but high value; it removes a whole class of later questions. If the engineer names one, record it as a file path (for example `design.md` at the project root) so `ui-context.md` can point at it and later builders can find it. A reference with no path is a preference that dies with the chat that heard it.

If the engineer has no opinion, recommend a complete, coherent default and say it is a default they can replace. A decided default beats an unresolved one.

## Stage 5: Code standards (1 round)

What `/audit` would ask, compressed. These become `code-standards.md`:

- **Type strictness.** Strict mode, `any` policy, validation at boundaries.
- **File organization.** The folder contract (where lib, components, API or routes, data layers live).
- **Testing strategy.** Which runners, from which slice onward, what must be tested first (anything doing money, auth, or permissions).
- **Git workflow.** Branch per feature or trunk, commit cadence, whether the AI may commit.

## Stage 5b: Repository (1 round)

- **GitHub repository URL.** The engineer supplies it (for example `https://github.com/maulanaadib/ghost-ai.git`). Never invent an owner or repo name. If the repo does not exist yet, tell the engineer to create an empty one on GitHub first, without a README or a license, then continue.
- **Branch strategy.** Commit straight to `main`, or work on a branch (`develop`, or `feature/<name>`) and keep `main` deployable. (Recommended: `main` for a solo build, a branch when the engineer wants review.) This is written into the `## Commit and Push` section of every feature spec as a statement, not a question — the spec says commit to `main`, or names the branch. Asking it per feature blocks an unattended build on a question this stage already answered. To change it for one feature, edit that feature's spec.
- **Commit cadence.** One commit per feature spec (recommended), or per milestone inside it.

Recorded in state and echoed into `ai-workflow-rules.md`, because that is the file later builders read.

## Stage 5c: Deployment and CI (1 round, conditional)

How the project ships, and the one infra decision that cannot be deferred past feature 00. Conditional on the Stage 5b repository answer.

**The local only exception.** If Stage 5b recorded no repository URL, the project is local only. Say so plainly, then ask only the env var convention question below. Mark first deploy, trigger, and CI checks not applicable with the reason "no remote repository". Never push anything, and never ask about a deploy target for a project with no repo to deploy from.

If there is a repository URL, ask all four:

- **First deploy.** Does `00-project-setup` also perform the first deploy (link the project on the host, set every env var, trigger the build, verify the URL responds)? Or is deploy handled later, when there is something to show? (Recommended: do it in `00-project-setup`. At that point the app is a placeholder, the env var list is three or four entries, and a failed deploy breaks no business logic. The cost of deferring rises every feature: by feature 05 the app has a data model, auth, and a dozen env vars the engineer must recall from memory, and the deploy gets debugged inside a feature that never planned for it.)
- **Deploy trigger.** Auto deploy on push to `main`, manual deploy from the host only, or a preview deployment per pull request with `main` deploying on merge. (Recommended: auto on `main` for a solo trunk based build, which is the branch strategy Stage 5b already recommended; preview per PR only when the engineer works on branches and wants a review step before merge. The trigger must agree with the Stage 5b branch strategy, it never overrides it.)
- **CI checks.** What must pass before a change lands: lint and typecheck only, or lint and typecheck plus the test suite. (Recommended: match the Stage 6 workflow tier. Prototype and Alpha, lint and typecheck, because the loop is still fast and wrong is cheap. Beta and GA, add the test suite, because at that tier a regression reaching `main` costs more than the CI minutes. Note the interaction with the trigger: only the preview per PR trigger actually gates a merge. Auto deploy on `main` runs the checks after the code is already live, so at Beta and GA the two choices pull toward each other, and the real gate lives in each feature spec's `## Commit and Push` section instead.)
- **Env var convention.** The dev env file name (`.env.local` for Next.js, `.env` for most others), the full list of env vars the Stage 3 stack requires, and where production values live. (Recommended: `.env.local` for dev, gitignored, production values set on the hosting dashboard and never in the repo.) This list is written to `architecture-context.md` as the env var table, so every later feature inherits the same variable names instead of inventing its own and shipping an `undefined` to production.

Recorded in state. Echoed into `architecture-context.md` as the env var table, and into `00-project-setup.md` as the first deploy steps.

## Stage 6: Build approach and workflow tier (1 round)

- **Build approach.** Present the four by their guiding principle, recommend exactly one:
  - **Tracer Bullet**: vertical slices, each feature end to end through every layer, working. (Recommended for production builds.)
  - **Skateboard**: thinnest usable whole first, then grow. For fast validation of one core loop.
  - **Facade**: clickable UI shell on placeholder data, then wire the back. Prototype grade, say so plainly.
  - **Journey**: one complete user path per phase. When the experience is the product.

  **The default is Tracer Bullet alone.** A sequence is a different goal, not a better default, so recommend one only when the engineer's stated goal matches it, and never present a sequence as the safe pick.

  **Facade then Tracer Bullet** is the sequence for validation before investment: build the whole frontend on dummy data first, so the engineer can click through and validate the product before any backend exists, then fill each feature in vertically (UI → endpoint → database) one feature at a time. Recommend it when the engineer is unsure the product is worth building and wants that answer cheap. Say the cost plainly: the UI is not built twice, but the data layer is — a mock layer is written and thrown away, and the real data invalidates assumptions the mock hid (shape, nullability, pagination, latency, error states), so the same UI files get touched again. When the engineer picks a sequence, record both halves in order, and decompose features per the **current** half only — a Facade half produces UI shell features, and the Tracer Bullet half produces the wiring features that replace the dummy data. A wiring feature is a real feature with its own spec and its own chat, not a subtask of the UI feature it completes.
- **Workflow tier.** Prototype, Alpha, Beta, or GA. How much process each feature warrants, and what closes `done` at that tier. (Recommended: Beta for a real product, Alpha for a throwaway validation.)

Both are recorded on the state header and echoed into `ai-workflow-rules.md`, because that is the file later builders read.

## Stage 7: Feature decomposition (1 to 2 rounds, then one confirmation round)

You reason here, you do not ask. From every answer so far, produce the ordered feature list:

- **`00-project-setup` is always first.** Scaffold the project from the Stage 3 stack decision and clean the framework boilerplate. No product behavior lives in it. It exists because feature 01 otherwise starts by fighting a template.
- **Then foundations.** Tooling and standards, data model, design system, walking skeleton. Never buried as sub tasks of a feature.
- **Then slices**, ordered by the Stage 6 approach. Keep features small: one page or one cohesive unit each. A listing, a detail page, and a cart are three features, not one storefront.
- **Then explicitly deferred** nice to haves, each with a one line why it is out.
- Per feature: a 1 to 2 line intent, and a `Done when` line of observable outcomes (acceptance criteria seeds, the WHAT, never the HOW).

Then the **confirmation round**: show the whole plan back (stack summary, approach, tier, the numbered feature list with intents, the deferred list) and ask one question, approve or change. Until this is approved, nothing is generated and any earlier answer can still be revisited.

## Completeness gate (before generating, do not skip)

Do not write a single file until every dimension above is accounted for. Each is:

- **answered** by the engineer, or
- **inferred**, with the inference stated back in the confirmation round so the engineer can object, or
- **not applicable**, with the reason recorded in state.

Any dimension still open → keep asking. An unasked dimension becomes a silent decision during a build, which is exactly the failure this skill exists to prevent. Depth is the goal: when in doubt, ask the extra question. Never fold two distinct dimensions into one option, never end with a dimension silently skipped.

A short interview is a red flag. A real project spans every stage above.
