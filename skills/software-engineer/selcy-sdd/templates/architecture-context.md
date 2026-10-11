# Architecture Context

## Stack

| Layer | Technology | Role |
| --- | --- | --- |
<STACK_TABLE_ROWS>

## System Boundaries

<SYSTEM_BOUNDARY_BULLETS>

## Storage Model

<STORAGE_MODEL_BULLETS>

## Auth and Collaboration Model

<AUTH_MODEL_BULLETS>

## Invariants

<INVARIANT_NUMBERED>

## Environment Variables

<ENV_VAR_TABLE>

The canonical list, decided once in Stage 5c so every feature uses the same names. A feature that needs a new variable adds a row here first, it never invents a name in its own spec.

| Variable | Purpose | Dev value | Production value |
| --- | --- | --- | --- |
<ENV_VAR_ROWS>

Rules:
- Dev values live in the dev env file Stage 5c named (`.env.local` for Next.js), which is gitignored.
- Production values live on the hosting dashboard, never in the repo.
- A variable with no production value yet is written `not provisioned yet`, never left blank, so a missing secret is visible instead of silently `undefined`.
