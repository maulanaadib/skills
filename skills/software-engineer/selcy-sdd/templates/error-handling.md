# Error Handling and Observability

The contract for failure. When something breaks, every layer fails the same way, so a builder never invents an error shape mid feature.

## Error Response Shape

<ERROR_SHAPE_CODE_BLOCK>

One shape for every API response, success and failure. A client can rely on it everywhere.

## Error Categories

| Category | Meaning | HTTP status | Retryable |
| --- | --- | --- | --- |
<ERROR_CATEGORIES_TABLE_ROWS>

## Handling Rules

<HANDLING_RULES_BULLETS>

## Logging

<LOGGING_BULLETS>

What is logged, at what level, and what must never appear in a log line.

## Observability

<OBSERVABILITY_BULLETS>

## User Facing Errors

<USER_FACING_BULLETS>

What the user sees. Plain language, no stack traces, no internal names.
