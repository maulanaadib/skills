# Data Model

The canonical entities. A feature spec may add a field or a relation, but it may not redefine an entity that already lives here. Two features describing the same entity differently is the bug this file exists to prevent.

## Conventions

<CONVENTIONS_BULLETS>

## Entities

### <ENTITY_NAME>

<ENTITY_DESCRIPTION>

| Field | Type | Constraints | Notes |
| --- | --- | --- | --- |
<ENTITY_FIELD_TABLE_ROWS>

<ENTITY_RELATIONS>

## Indexes

<INDEXES_BULLETS>

## Migration Rules

<MIGRATION_RULES_BULLETS>

Migrations are forward only and additive first. A breaking migration is a spec decision, not a build time surprise.
