<PROJECT_NAME> Project Setup

## Goal

Stand up the raw project from the stack decision and clean the framework boilerplate, so feature 01 builds into a real project instead of a template. No product behavior lives in this file.

## Scaffold

<SCAFFOLD_STEPS>

Initialize the project with the framework's own initializer for the stack Stage 3 chose. Keep the repo the initializer creates. Install only what the first slice needs, not every library the stack names.

## Boilerplate Cleanup

<CLEANUP_STEPS>

What to delete, what to simplify, what the placeholder page renders. These are taste calls, so they are asked, not inferred.

## Verify

<VERIFY_STEPS>

A dev server or build runs, and the placeholder page renders. Nothing else is verified here.

## GitHub Repository

<GITHUB_REPO_STEPS>

Create the remote and push the first commit. Ask the engineer for the repository URL (for example `https://github.com/maulanaadib/ghost-ai.git`) before touching git; never invent an owner or repo name. If the engineer has not created the empty repo on GitHub yet, tell them to create it first, without a README or a license, then continue.

The sequence, adapted to the platform the engineer is on:

```
echo "# <REPO_NAME>" >> README.md
git init
git add README.md
git commit -m "first commit"
git branch -M main
git remote add origin <REPO_URL>
git push -u origin main
```

Rules:
- If the initializer already created a git repo with commits, do not run `git init` again; add the remote and push instead.
- Never force push, and never overwrite an existing remote branch.
- Commit the scaffold and the cleanup as one first commit, not many.

If the engineer gave no repository URL, this project is local only. Skip this section entirely: no remote, no push, no `git remote add`. Say so plainly in the handoff so no later feature spec assumes a remote exists. The project still gets a local git repo and local commits, so the `## Commit and Push` section of every feature spec still runs, it just never pushes.

## First Deploy

<FIRST_DEPLOY_STEPS>

Only when Stage 5c decided the first deploy happens here. If Stage 5c deferred it, or the project is local only, skip this section and say why in the handoff.

The steps, in order:

1. Create the project on the hosting target Stage 3 chose, linked to the repository from the section above.
2. Set every env var from the `architecture-context.md` env var table, with production values. Never commit them to the repo.
3. Trigger a build and wait for it to finish.
4. Open the deployed URL and confirm the placeholder page renders.

Rules:
- Production env values come from the engineer, never invented. Ask for each one by name from the env var table.
- If a value is not ready yet (a database not provisioned, a key not generated), ask whether to defer the whole deploy, not whether to ship a placeholder value. A deploy with a missing secret is a broken deploy, not a partial one.
- A failed build here is expected and cheap: the app is a placeholder. Fix it here, in this feature, rather than inside a later feature that never planned for it.

## Commit and Push

This feature is only ready to commit after `Verify` passes and the first deploy (when it runs in this feature) succeeds.

The order is fixed:

1. `Verify` passes: a dev server or build runs, and the placeholder page renders.
2. The first deploy, when Stage 5c put it here, succeeds and the URL responds.
3. Lint and typecheck pass (`<LINT_COMMAND>`, `<TYPECHECK_COMMAND>`).
4. Only then, ask the engineer which branch to commit to, as a decision panel:
   - **`main`** (recommended for a solo build where `main` is the working branch)
   - **a new branch** (for example `develop` or `feature/<name>`, when the engineer wants review or keeps `main` deployable)
   Never commit silently, and never pick the branch without asking.
5. Commit the scaffold, the boilerplate cleanup, and the first deploy as one commit, not many: `<COMMIT_MESSAGE>`.
6. Push to the chosen branch. Never force push.

If the project is local only, step 6 is skipped: commit locally and stop. Say so in the handoff.

## Scope Limits

<SCOPE_LIMIT_BULLETS>

No product features, no business data models, no route protection, no UI beyond the placeholder. Every one of those belongs to a numbered feature spec.
