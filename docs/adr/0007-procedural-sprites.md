# ADR-0007: Procedural pixel sprites

**Status:** Accepted
**Date:** 2026-08-27

## Context

The game needs recognizable, animated characters (a cowboy vs zombies) but the
project deliberately avoids external art assets: everything must be
reproducible from source and reviewable as code.

## Decision

- Sprites are defined **as ASCII pixel maps** (arrays of strings) and baked
  into `Canvas` textures at load time (`src/fw/sprites.lua`). Each character
  maps to a palette color.
- Characters are built as **frame arrays** (idle/walk) and animated with
  `src/core/anim.lua` (pure, unit-tested). A "flash" variant (all-white) is
  baked per frame for hit feedback.
- Entities own their animations (`player.idle_anim`, `player.walk_anim`,
  `enemy.anim`) and tick them in their update.
- The cowboy sprite is flipped horizontally to face its aim; a gun barrel and
  muzzle flash are drawn as overlays toward the aim direction. Zombies flip to
  face their target.
- The arena is a **dark map**: a darkness overlay plus an additive radial
  light around the player (`src/fw/light.lua`), creating a lantern effect.

## Consequences

- Art is versionable, diffable and tweakable as data — no binary assets.
- Animations, facing and effects are expressed in code and testable.
- Sprite quality is bounded by what is reasonable to hand-encode as text;
  a future art pass can swap `sprites.lua` for real spritesheets without
  changing the entity/controller code.