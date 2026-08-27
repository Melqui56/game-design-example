# ADR-0003: Testing and linting toolchain

**Status:** Accepted
**Date:** 2026-08-26

## Context

We want verifiable quality in the repo: tests running in CI and code that
follows a consistent standard. The game's pure logic must not depend on LÖVE
so it can be tested headless (without opening a window).

## Decision

- **busted** (lunarmodules) as the test framework. It is the de facto Lua
  standard (~7M downloads) and is actively maintained.
- **luacheck** (lunarmodules) as the static linter. Configuration is pinned to
  the **Lua 5.1 / LuaJIT dialect** (`std = "lua51"`), because LÖVE embeds
  LuaJIT; this prevents a test passing in another dialect in the editor and
  then failing inside the game.
- Installed via **LuaRocks 3** (Lua's package manager), since neither busted
  nor luacheck are packaged in Fedora's repos.
- Window-proof testing: pure logic modules (game rules, waves, save system)
  are written without touching `love.*`, so they run with plain `busted` in
  CI. The layer that does use `love.*` (rendering, input) stays thin and is
  validated by running the game itself, not by CI.

## Consequences

- CI stays green with passing tests plus clean lint on every commit.
- The "logic without `love.*`" discipline from day one gives us a cleaner
  architecture as a free side effect (separation of concerns).
- Writing render-facing code is slightly slower (no headless coverage),
  mitigated by keeping the graphics layer thin.