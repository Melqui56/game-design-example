# ADR-0006: State machines as the core architectural pattern

**Status:** Accepted
**Date:** 2026-08-27

## Context

Scenes already behave like a state machine (menu/play/pause/gameover), but
entities were stateless data + functions. That left decisions like
"can this entity take damage right now?" scattered in controllers, and made
new states (stun, invulnerability, death) hard to add without if-chains.

## Decision

- A generic, dependency-free **finite state machine** in `src/core/fsm.lua`
  (pure, unit-tested). A machine holds `states`, a `current` name and an
  `owner`; `change` fires `exit`/`enter` callbacks, `update` runs only the
  current state.
- **Scene machine** (`src/fw/scene_manager.lua`) is the top-level FSM: it
  routes callbacks to the active scene.
- **Entities own their lifecycle through FSMs**:
  - Player: `alive → hit → alive` with a brief invulnerability window and
    blink, `→ dead`. Damage is *refused* while `hit`/`dead`.
  - Enemy: `chase → dying → removed` (a short death delay lets the sprite
    flash before removal).
- Controllers no longer decide "can it take damage": they call
  `take_damage`, which returns whether damage was applied, and the FSM
  decides.

## Consequences

- New behavior = new state, not new if-chains.
- Invulnerability, hit-flash and death timing are testable pure logic.
- Tests cover both the FSM itself and its usage in player/enemy.
- The scene machine and entity FSMs share one pattern, making the codebase
  easier to reason about.