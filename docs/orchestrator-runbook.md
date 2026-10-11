# Runbook: the selcy-orchestrator automation

How to go from an empty folder to a built product, unattended, with Hermes as the orchestrator and opencode as the builder.

## What this is

```text
you  ──/selcy-sdd──▶  context/ bundle  ──you approve──▶  /selcy-orchestrate (once)
                                                            │
                                                            ▼
                                              kanban board: one card per feature
                                                            │
                                              ┌─────────────┴──────────────┐
                                              │  gateway dispatcher         │  ← ticks every 60s,
                                              │  claims the next ready card  │     already running
                                              │  spawns selcy-orchestrator   │
                                              └─────────────┬──────────────┘
                                                            │
                                       ┌────────────────────┴───────────────┐
                                       │ worker: delegate one feature       │
                                       │   to `opencode run`                │ ← new session,
                                       │ verify against Check When Done     │   visible in your history
                                       │ kanban_complete / kanban_block     │
                                       └────────────────────────────────────┘
                                                            │
                                              stop: owed decision / failed / gate mismatch
```

Five pieces, each with one job:

| Piece | Job | Where it lives |
| --- | --- | --- |
| `selcy-orchestrator` profile | Read the card, delegate one feature, verify, close the card | `~/.hermes/profiles/selcy-orchestrator/` |
| `SOUL.md` | The worker's rules: never build, never edit specs, never answer owed decisions | Same folder |
| `selcy-orchestrate` skill | The two phases: bootstrap the board, then the worker loop | This repo, `skills/orchestrator/selcy-orchestrate/SKILL.md` |
| Kanban board | The trigger and the state. One card per feature, chained in order | `~/.hermes/kanban.db` |
| Gateway dispatcher | The event loop. Claims a ready card every 60s and spawns the worker | Runs as a background service |

The trigger is not a cron job and not a human. It is the dispatcher: a loop inside the gateway that claims any card in `ready` status and spawns the assigned profile. You create the cards once; the board does the rest.

This repo also holds the spec-driven skills (`/selcy-sdd`, `/selcy-implement`, `/selcy-check`, `/selcy-test`, `/selcy-debug`, `/selcy-sync`) under `skills/software-engineer/`. The orchestrator lives at `skills/orchestrator/selcy-orchestrate`.

## One time setup

### 1. Install the two skill bundles into the new project

Both install from this repo, but to **different agents, on purpose**. The `-a` flag decides which agent reads the skill:

```bash
cd <new-project-dir>

# The spec-driven skills → the BUILDER. /selcy-sdd and /selcy-implement run inside `opencode run`,
# so these must land where opencode reads them.
npx skills@latest add maulanaadib/skills -a opencode

# This orchestrator → the ORCHESTRATOR. The dispatcher spawns the selcy-orchestrator
# Hermes profile to work each card, so this must land where Hermes reads it.
npx skills@latest add maulanaadib/skills -a hermes-agent
```

Where each one lands:

| Bundle | Agent flag | Directory created |
| --- | --- | --- |
| `maulanaadib/skills` | `-a opencode` | `.agents/skills/` |
| `maulanaadib/skills` | `-a hermes-agent` | `.hermes/skills/` |

Note: `npx skills add` copies every skill in the repo, so each agent receives all seven. Only the ones that agent invokes will ever load; the rest sit idle. Getting the `-a` flags backwards is still the most common install failure, and it fails silently: the file is on disk, the agent that needs it never loads it. If `opencode run` later says it does not know `/selcy-sdd`, or the Hermes worker says it has no `selcy-orchestrate` skill, check this table.

### 2. Install the orchestrator skill into the Hermes profile

The worker needs the skill on the profile, not just in the project:

```bash
hermes -p selcy-orchestrator skills install https://raw.githubusercontent.com/maulanaadib/skills/main/skills/orchestrator/selcy-orchestrate/SKILL.md --yes
```

### 3. Enable the kanban toolset on the profile

The worker closes its own card with `kanban_complete` / `kanban_block`. Without this toolset those tools are not in its schema and it cannot finish a card:

```bash
hermes -p selcy-orchestrator tools enable kanban
```

### 4. Confirm the profile can run

```bash
hermes -p selcy-orchestrator profile show
```

Check it has a model and API keys. If not, run `selcy-orchestrator setup` (the wrapper the profile create step made) or set the keys in the profile's `.env`.

### 5. Confirm the dispatcher is running

It should already be up — on Windows it installs as a startup item, on Linux `hermes gateway start` installs a systemd user unit. Verify:

```bash
hermes gateway status
hermes cron status
```

If it is not running, start it and it will survive reboots:

```bash
hermes gateway start
```

On Linux, one extra step matters. Workers are fire-and-forget processes that must outlive the dispatcher tick, so the gateway spawns each one in its own systemd scope. That needs your user's session bus — without it the spawn is refused as an infrastructure failure and the card stays in `ready`. Enable lingering once:

```bash
sudo loginctl enable-linger <your-user>
```

This is the only Linux-specific gotcha in the whole setup. Everything else — the board, the dispatcher loop, the worker protocol, the skill — is identical on both platforms.

## The run

### Phase 1: the interview (you are present)

```bash
cd <new-project-dir>
opencode run "/selcy-sdd"
```

You answer the panels. You approve the plan at the confirmation panel. The bundle is written to `context/`, plus one file at the project root: `AGENTS.md`, the read order every later chat loads. Root, not `context/`, because that is the file `opencode` auto-loads — the orchestrator's builder is a bare `opencode run` that loads nothing else, so the read order has to be where it is looked for.

**If this project already has a `context/AGENTS.md`** from before this convention, move it to the root and delete the `context/` copy so the two never diverge. `/selcy-sdd` asks before deleting the old file.

**This is the last time you must be present.** Everything after this is the orchestrator.

### Phase 2: bootstrap the board (you do this once)

```bash
hermes -p selcy-orchestrator chat
```

Then in the chat:

```text
/selcy-orchestrate
```

The skill reads `context/progress-tracker.md`, creates one kanban card per remaining feature, chains them in order, and reports the card ids. Then it stops. It does not start working them — that is the dispatcher's job.

### Phase 3: the build (you are not)

Within 60 seconds the dispatcher claims the first card and spawns the orchestrator profile as a worker. The worker delegates that one feature to `opencode run`, verifies the result against the spec's `Check When Done`, and closes the card. Completing a card promotes the next one in the chain, and the next tick spawns the worker again.

You can watch it without touching it:

```bash
hermes kanban list              # the board
hermes kanban watch             # live event stream, Ctrl+C to exit
hermes kanban show <card-id>    # one card: comments, runs, events
hermes kanban log <card-id>     # the worker's own log
```

Every `opencode run` also creates a session you can inspect later, so the full history of every feature build is visible even if you were not watching:

```bash
opencode session list
opencode export <session-id>
```

The session names are the contract, and they are what keeps the list readable:

| Work | Session | Resumed? |
| --- | --- | --- |
| Build | `feat-<NN>-<slug>` | Yes — an interrupted build resumes this session, it never spawns a sibling |
| Review | `feat-<NN>-<slug>-review` | No, always new, different model |
| Test | `feat-<NN>-<slug>-test` | No, always new, different model |

If you see `feat-04` and `feat-04-r1` side by side, that is the old failure mode and it is fixed: the worker records the session id in the card and resumes it on the next tick instead of starting over. One feature, one build session, however many interruptions it takes.

The worker never deletes sessions itself. If the list has probe sessions (`QWEN_OK`, `MIMO_OK`, smoke tests, empty runs), the worker names them in the card and leaves them for you to remove — deleting them silently removes the evidence that a probe ran.

### Phase 4: when it stops

It stops for one of three reasons. Each has a different response:

| Why it stopped | What you do |
| --- | --- |
| **Owed decision** — the builder asked a question the bundle does not answer | Answer it. Then edit `context/` if the answer is a new rule, and unblock the card. |
| **Failed** — the build errored | Read the opencode session for the error. Fix the environment or the code, then unblock. Do not blindly re-run. |
| **Review or test failure** — the reviewer found a blocking issue, or a test is red | Read the `-review` or `-test` session for the finding. The fix goes back to the build session, not a new one. |
| **Gate mismatch** — the builder claimed done but a checklist item is unaddressed | Read the opencode session. Either the item is genuinely missing, or the spec is wrong. Fix one of them, then unblock. |

Resuming never restarts anything. The board is the state:

```bash
hermes kanban list --status blocked     # see what stopped and why
hermes kanban show <card-id>            # read the block reason
hermes kanban unblock <card-id>         # back to ready; next tick resumes it
```

The worker reads `progress-tracker.md` first, so it picks up wherever the loop stopped.

**The worker tells you when it blocks, in its reply, not only in the card.** A blocked card is a request for a decision and you are not watching the board. If you find a block hours late, or answer a question the builder asked without ever being told it was asked, that is this rule failing. The reply names the feature, the kind of block, the question or error verbatim, and the command to resume.

**The worker does not give time estimates.** A build's duration depends on the model, the provider, the feature's real size, and how many owed decisions surface, none of which the worker can see. An estimate you arrange your day around and then miss is worse than no estimate. It reports **state** instead — what phase the build is in, what it has written, what it is waiting on — which is verifiable and does not expire. The heartbeat is the mechanism for this: it proves the run is alive without predicting when it finishes.

**The worker uses a push credential you have already approved.** When a push fails with a permission error and you have named an approved credential, the worker uses it rather than blocking. A card that sits blocked for hours on a 403, while the approved credential sits unused, is a worker waiting for permission it already has. If no credential has been approved, **then** it asks — and says the push is otherwise complete.

## The rules that keep this safe

These are in `SOUL.md` and in the skill. They are the reason unattended is safe here:

- **One feature per card, one card per feature.** A failure stays contained to one feature.
- **Cards are chained in order.** A card only promotes when its parent is done, so a blocked card stops the whole rest of the chain automatically.
- **The orchestrator never writes application code.** It delegates. If it could build, it could build the wrong thing at full speed.
- **The orchestrator never edits `context/`.** Those are contracts. A wrong spec is a human decision. The root `AGENTS.md` is part of that contract set — it is generated by `/selcy-sdd`, not edited by the orchestrator.
- **The orchestrator never answers an owed decision.** It surfaces the question verbatim and blocks. It never picks the recommended option on your behalf.
- **The orchestrator has no memory between ticks.** Every spawn is a fresh turn. State lives in the card and in `context/`, never in chat. This is why a correction you gave it once can appear to be forgotten after a restart — it was never written down.
- **A failed build is never auto-retried.** The card stays blocked until a human unblocks it. A retry without new information is the same failure again.
- **The worker never gives a time estimate for a build.** It reports state, not duration.
- **The worker never waits on you for a credential you already approved.** It uses it, and only asks when none has been approved.
- **Green output is not proof.** The worker verifies against the spec's `Check When Done` and re-reads the tracker to confirm the builder itself advanced it.
- **Progress is in the files, not in the agent.** The worker forgets between spawns and reads `progress-tracker.md` at the start of every run. The board carries the state, not the model.

## When not to use this

- **You want to review each feature before the next one starts.** This is unattended. Use `/selcy-implement` per feature in a new chat instead.
- **The project has no spec bundle.** Run `/selcy-sdd` first. The orchestrator will refuse and tell you to.
- **You want to change what is being built.** Edit the bundle, run `/selcy-sync`, then resume. The orchestrator never edits the bundle for you.

## Uninstall or disable

```bash
# Stop the dispatcher
hermes gateway stop

# Remove the profile
hermes profile delete selcy-orchestrator

# Remove the skill from a project
npx skills@latest remove selcy-orchestrate
```

The `context/` bundle stays untouched. Removing the orchestrator never removes the specs or the code.
