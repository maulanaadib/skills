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

<COMPONENT_CONVENTION_BULLETS>
