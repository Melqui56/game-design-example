# Game Design Example U

A small top-down arcade roguelite built with [LÖVE](https://love2d.org/) 11.5
and Lua. Testable pure logic, a thin render layer, and a local CI loop.

> Work in progress. Current stage: running skeleton (boot, scene machine,
> movable player, headless tests, local CI).

## Stack

- LÖVE 11.5 (LuaJIT 2.1 on the runtime)
- busted + luacheck (tests and lint, headless)
- Makefile (local CI); GitHub Actions available but manual only
- Pixel-art identity: Press Start 2P font (OFL) + virtual 480x270 canvas

## Quick start

```bash
./scripts/bootstrap.sh   # idempotent: installs the toolchain and verifies it
make check               # local CI: lint + headless tests
love .                   # run the game
```

For direct verification without changing your system:

```bash
./scripts/bootstrap.sh --check
```

## CI

The full quality gate runs locally and costs nothing:

```bash
make check        # luacheck + busted (fail on any warning/failure)
make lint         # luacheck only
make test         # busted only
make dev          # run with hot reload — restarts the game on file change
make smoke        # boots the game for 6 seconds
make run          # runs the game
make doctor       # verifies the toolchain is present
```

GitHub Actions is configured for manual dispatch only
(`workflow_dispatch`) — it never auto-runs on push, so heavy local iteration
does not burn CI minutes. See [docs/adr/0004](docs/adr/0004-local-ci.md).

## Requirements

- Linux (script supports Fedora, Ubuntu/Debian). macOS/Windows planned.

## Quick start

```bash
./scripts/bootstrap.sh   # idempotent: installs the toolchain and verifies it
love .                   # run the game
```

For direct verification without changing your system:

```bash
./scripts/bootstrap.sh --check
```

## Tests

The same gate is exposed by the Makefile:

```bash
make check               # lint + tests
luacheck src tests       # lint (pinned to the Lua 5.1/LuaJIT dialect)
busted tests/spec        # runs the headless logic specs
```

## Project layout

```
conf.lua     LÖVE configuration
main.lua     thin entry point
src/core/     pure logic, no love.* (playable and testable headless)
src/fw/       thin love.* glue (app, scene machine, input, render)
src/game/     controllers wiring core + fw per scene
tests/spec/   busted specs (core only)
assets/       fonts (Press Start 2P, OFL)
docs/adr/     architecture decision records
scripts/      bootstrap.sh (idempotent environment provisioning)
```

## Docs

- [docs/adr/0001](docs/adr/0001-toolchain-and-runtime.md) — toolchain & runtime
- [docs/adr/0002](docs/adr/0002-bootstrap-strategy.md) — provisioning strategy
- [docs/adr/0003](docs/adr/0003-testing-and-linting.md) — testing & linting
- [docs/adr/0004](docs/adr/0004-local-ci.md) — local CI as the primary verification loop
- [docs/adr/0005](docs/adr/0005-visual-identity.md) — pixel-art visual identity
- [docs/adr/0006](docs/adr/0006-state-machines.md) — state machines as the core pattern

## License

MIT. See [LICENSE](LICENSE).