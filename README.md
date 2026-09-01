# Game Design Example U

A small top-down arcade roguelite built with [LÖVE](https://love2d.org/) 11.5
and Lua. Testable pure logic, a thin render layer, and a local CI loop.

> Work in progress. Current stage: playable top-down arcade roguelite
> (movement, waves, upgrades, procedural sprites via a real asset pipeline).

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

### Windows

The same toolchain is provisioned by a PowerShell bootstrap (Lua, LÖVE,
busted, luacheck). Run from PowerShell:

```powershell
.\scripts\bootstrap.ps1   # idempotent: install + verify
.\scripts\test.ps1        # lint + tests (Windows `make check`)
.\scripts\run.ps1         # run the game
```

## CI

The full quality gate runs locally and costs nothing:

```bash
make check        # luacheck + busted (fail on any warning/failure)
make lint         # luacheck only
make test         # busted only
make sprites      # bake ASCII sprite maps -> sheet.png + atlas.lua
make verify-sprites # validate the generated spritesheet pixels
make dev          # run with hot reload — restarts the game on file change
make smoke        # boots the game for 6 seconds
make run          # runs the game
make doctor       # verifies the toolchain is present
```

On Windows, `.\scripts\test.ps1` runs the same lint + test gate.

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
assets/sprites/  ASCII sprite maps (data-as-code) + generated sheet.png/atlas.lua
assets/fonts/     Press Start 2P, OFL
docs/adr/     architecture decision records
scripts/      bootstrap + test/run helpers; gen_sprites/ build tool
```

## Sprites

Sprites are authored as **ASCII maps** (data-as-code) in
`assets/sprites/*.lua`. A small LÖVE build tool bakes them into a single PNG
spritesheet + atlas, applying **procedural shading**: each material gets a
5-step light ramp with hue-shift, and pixels are shaded from a top-left light
direction (`scripts/pixel.lua`, pure Lua and unit-tested).

```bash
make sprites          # love scripts/gen_sprites
make verify-sprites   # love scripts/verify_sheet  (checks sampled pixels)
```

At runtime, `src/fw/sprite_atlas.lua` loads the sheet + atlas, and
`src/fw/render.lua` draws all sprites through **one SpriteBatch** with a
pixel shader for outline / hit-flash effects. See
[docs/adr/0008](docs/adr/0008-procedural-sprite-pipeline.md).

## Docs

- [docs/adr/0001](docs/adr/0001-toolchain-and-runtime.md) — toolchain & runtime
- [docs/adr/0002](docs/adr/0002-bootstrap-strategy.md) — provisioning strategy
- [docs/adr/0003](docs/adr/0003-testing-and-linting.md) — testing & linting
- [docs/adr/0004](docs/adr/0004-local-ci.md) — local CI as the primary verification loop
- [docs/adr/0005](docs/adr/0005-visual-identity.md) — pixel-art visual identity
- [docs/adr/0006](docs/adr/0006-state-machines.md) — state machines as the core pattern
- [docs/adr/0007](docs/adr/0007-procedural-sprites.md) — procedural sprites
- [docs/adr/0008](docs/adr/0008-procedural-sprite-pipeline.md) — spritesheet pipeline (SpriteBatch + shader)

## License

MIT. See [LICENSE](LICENSE).