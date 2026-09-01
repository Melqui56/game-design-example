# ADR-0009: Title art direction and the slanted-plate UI

**Status:** Accepted
**Date:** 2026-09-01

## Context

The first title screen (ADR-0008 pipeline, commit `b97ac64`) was correct but
read as programmer art: the menu was centred labels on a flat rectangle, the
hero was the 30x38 in-game sprite scaled 3x, and the logo was Press Start 2P
text with a faked two-tone band. The play HUD was a translucent black strip
with three lines of text, sharing no visual language with the menus.

We wanted the screen to read like a shipped game's key art, and we wanted one
grammar across every surface rather than three unrelated looks.

## Decision

### One shape: the slanted plate

`ui.slant_panel` draws a right-leaning parallelogram with a hard offset
shadow, an optional hairline rule and an optional accent tip. **Every** panel
in the game is built from it — the three menus (`ui.slant_menu`), the HUD
readouts (`ui.hud_stat`), and the wave banner (`ui.banner`). Selection
inverts: a gold plate with black text against black plates with muted text.
Labels stay upright; only the plates skew, so the pixel font keeps its edges.

Consequence: adding a new panel means calling the primitive, not inventing a
box. Retuning the look is one function.

### Kinetic entry, and where that state lives

Plates stagger in and the highlight punches on every cursor move. The timing
is pure state so it stays testable: `title_scene.menu_items` returns per-item
`{ dx, alpha }`, and `menu.pop` (in `src/core/menu.lua`) is the punch, decayed
by `menu.update`. `src/fw/ui.lua` only draws what it is handed.

`menu_items` is keyed off elapsed time rather than the intro progress: the
stagger runs past the end of the intro, and keying it to `intro` froze the last
plate mid-flight when the intro clamped at 1.

### The portrait is authored, not derived

The bust is a hand-authored 80x100 sprite drawn at scale 2, plus a separate
40x46 revolver so the gun can cock and kick without redrawing the body. It is
`shade = "flat"`: every tone is chosen by hand through explicit light and dark
palette keys.

Pose: back to the menu on the diagonal, head turned away so the face reads in
near silhouette against the sunset, with one eye burning under the brim. The
silhouette and the two rim lights (`rim_cool` behind, `rim_warm` in front) do
the work; the face is deliberately not rendered.

We tried generating the portrait procedurally from polygons and shading passes
first. It produced muddy, unreadable forms over many iterations. Authoring in
horizontal scanline runs — the unit a pixel artist actually works in — and
looking at a render after every pass is what made it converge.

### The logo is a real sprite

`assets/sprites/logo.lua` holds a western slab display face: the 11 glyphs the
title needs, one colour, no shading. The build tool composes them into words
and `pixel.bevel_step` embosses each letter from its own edges (bright where it
faces the top-left light, dark where it faces away, base inside). So the logo
is chiselled art baked into `sheet.png`, not text, and adding a word costs a
line in `words`.

Press Start 2P remains the font for all actual text (ADR-0005). The logo is not
text.

## Consequences

- One primitive change restyles menus, HUD and banners together.
- The portrait cannot be regenerated from a script; it is edited as ASCII, like
  every other sprite (ADR-0007). `make sprites` then `make verify-sprites`.
- `verify_sheet` now pins the portrait and logo dimensions and samples their
  bevel steps, so a stale committed sheet fails loudly.
- `ui.menu_items` survives only until its last caller is gone; the three menus
  now go through `ui.slant_menu`.
- Glyphs are per-letter widths, so the word compositor reads each glyph's own
  width rather than assuming a fixed cell.
