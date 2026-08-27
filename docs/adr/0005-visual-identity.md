# ADR-0005: Pixel-art visual identity and design system

**Status:** Accepted
**Date:** 2026-08-27

## Context

The early prototype rendered with the default font, hard-coded ad-hoc colors
and flat primitives, which reads as "programmer art". We want a cohesive,
product-like look with a retro arcade identity.

## Decision

- Render to a **low-resolution virtual canvas (480x270)** scaled 2x with
  nearest-neighbor filtering (`src/fw/retro.lua`): every shape snaps to a
  chunky pixel grid.
- All colors come from **`src/core/palette.lua`** (a curated dark arcade
  palette). No hard-coded color numbers in scenes.
- Bundled font **Press Start 2P** (OFL license, `assets/fonts/`) for titles,
  menus and HUD.
- **Layered backgrounds**: a vertical night→dusk gradient canvas
  (`src/fw/backdrop.lua`) plus a starfield layer; entities get 1px outlines
  for definition.
- Layout coordinates are virtual (`retro.getDimensions()`), decoupling
  resolution from logic.

## Consequences

- Instant retro cohesion across all scenes; retuning colors is a single file
  change.
- The virtual canvas costs one scaled blit per frame and buys the pixel look
  for free.
- New visual work must go through `palette` + `ui` helpers; ad-hoc colors are
  caught by review.
- The bundled font keeps its OFL license alongside it
  (`assets/fonts/OFL.txt`).