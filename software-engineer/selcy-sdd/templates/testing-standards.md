# Testing Standards

What must be tested, where, and from which slice onward. A feature spec references this instead of redefining test strategy per feature.

## Strategy

<STRATEGY_PARAGRAPHS>

## Test Pyramid

| Level | What it covers | Runner | Required from |
| --- | --- | --- | --- |
<TEST_PYRAMID_TABLE_ROWS>

## What Must Be Tested First

<FIRST_TESTED_BULLETS>

Money, auth, permissions, and any invariant in `architecture-context.md`. These ship with tests in the same feature, never deferred.

## Naming and Location

<NAMING_BULLETS>

## Definition of Done

<DEFINITION_OF_DONE_BULLETS>

A feature is not done because it works. It is done because it is verified against its spec.
