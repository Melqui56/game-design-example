# ADR-0008: Procedural spritesheet pipeline (data-as-code → PNG + atlas)

**Status:** Accepted
**Date:** 2026-09-01
**Supersedes the bake path in:** ADR-0007 (runtime canvas baking)

## Context

ADR-0007 kept sprites as ASCII maps baked into `Canvas` textures at load time.
That worked, but every frame was a separate texture, the outline had to be
pre-baked per sprite, and there was no single atlas to feed a `SpriteBatch`.
We wanted an asset pipeline closer to what engines use (a real spritesheet +
atlas) while keeping the "everything is code / versionable" property.

## Decision

- **Sprites stay authored as ASCII maps** in `assets/sprites/*.lua`
  (data-as-code): a `palette` mapping + `sets` of frames, plus props.
- A **build tool** (`scripts/gen_sprites`, a small LÖVE app) bakes those maps
  into **`assets/sprites/sheet.png`** (single texture, power-of-two width,
  nearest-neighbor) plus **`assets/sprites/atlas.lua`** (set → frame rects).
  Run via `love scripts/gen_sprites` (Makefile target `make sprites`).
- The **runtime** loads the sheet + atlas (`src/fw/sprite_atlas.lua`) and
  draws everything through **one `SpriteBatch`** (`src/fw/render.lua`),
  sorted by world Y for the painter's algorithm.
- **Outline and hit-flash are computed in a pixel shader**
  (`src/fw/shaders.lua`) from the sprite's alpha, instead of baking extra
  "flash" images. `OutlineColor`/`FlashAmount` are uniforms, so effects are
  tunable per frame.
- The generated PNG + atlas are **committed**; the ASCII maps remain the
  source of truth.

## Consequences

- **One draw call** for all sprites (characters, props) instead of one per
  sprite; the sheet is a standard texture atlas any engine can consume.
- **Art stays editable as code**: edit an ASCII map, run `make sprites`, done.
  Variants (color swaps, scale) are trivial from data.
- **No binary art authored by hand**: the PNG is derived, diffable via its
  source maps, and reproducible from a clean checkout.
- **Shader effects replace baked variants**: outline and flash are runtime
  uniforms; the sheet stays small (no duplicate flash frames).
- Adds a build step: anyone changing sprites must run `make sprites`
  (and ideally `make verify-sprites`) before committing.

## Verification

- `scripts/verify_sheet` reads the committed PNG and asserts sampled pixels
  (main colors + outline) match the palette — guards against stale sheets.
- CI gate unchanged: `make check` (lint + headless logic tests).