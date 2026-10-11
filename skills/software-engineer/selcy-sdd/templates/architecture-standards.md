# Architecture Standards

The shape of the system. A feature spec describes what to build; this file constrains where it goes and how it connects.

## Architecture Style

<ARCHITECTURE_STYLE_PARAGRAPHS>

The chosen style and one line why. Modular monolith by default for a small team: one deploy, one codebase, module boundaries enforced by convention and lint, not by network.

## Module Boundaries

<MODULE_BOUNDARY_BULLETS>

The modules and what each owns. A feature touches one module; crossing two is a scope split, not a design choice.

## When To Split

<SPLIT_TRIGGERS_BULLETS>

The conditions that justify extracting a module or service, written down so the decision is not relitigated per feature. Default: split only on measured evidence (a team boundary, a scaling bottleneck, an independent deploy need), never on anticipated scale.

## Cross Module Contracts

<CROSS_MODULE_CONTRACT_BULLETS>

How modules talk. Same process call, typed interface, no network hop unless this file says so.

## Dependency Direction

<DEPENDENCY_DIRECTION_BULLETS>

What may depend on what. No cycles, no feature importing another feature's internals.

## Scaling Posture

<SCALING_POSTURE_BULLETS>

What is expected to scale, how, and what is explicitly not scaled yet. Keeps premature optimization out of feature specs.
