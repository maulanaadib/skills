# UI Context

## Theme

<THEME_MODE_SUMMARY>

All colors are defined as CSS custom properties in `globals.css` and mapped to Tailwind tokens via `@theme inline`. Components must use these tokens — no hardcoded hex values or raw Tailwind color classes like `zinc-*`.

| Role | CSS Variable | Hex / Value |
| --- | --- | --- |
<COLOR_TABLE_ROWS>

Tailwind utility names map to these variables. <TOKEN_USAGE_NOTES>

## Typography

| Role | Font | CSS Variable |
| --- | --- | --- |
<TYPOGRAPHY_TABLE_ROWS>

<FONT_LOADING_NOTES>

## Border Radius

Radius increases with surface depth — smaller for inner elements, larger for outer containers.

| Context | Class |
| --- | --- |
<RADIUS_TABLE_ROWS>

## Component Conventions

<COMPONENT_CONVENTION_BULLETS>## Design Reference

<DESIGN_REFERENCE_BLOCK>

## Screens

Ordered list of the product's screens. Each row traces back to a job in
`product-context.md` — a screen with no job is cut. This is the screen list a
design tool (pen.dev, Figma AI) works from: tokens above say *how it looks*,
this table says *what exists*.

| # | Screen | One-line purpose | Job (product-context.md) |
| --- | --- | --- | --- |
| 1 | <SCREEN_NAME> | <WHAT_THE_USER_DOES_HERE> | <JOB_ID_OR_DESCRIPTION> |

<SCREEN_TABLE_ROWS>