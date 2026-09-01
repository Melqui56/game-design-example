# Cross-platform Makefile for the game.
#
# On Windows, LÖVE is installed by scripts/bootstrap.ps1 into
# %LOCALAPPDATA%\Programs\LOVE; the Makefile resolves the absolute path so it
# does not depend on a session's PATH. On Linux/macOS it uses `love` from PATH.

# On Windows, LÖVE is installed by scripts/bootstrap.ps1 into
# %LOCALAPPDATA%\Programs\LOVE; the Makefile resolves the absolute path so it
# does not depend on a session's PATH. On Linux/macOS it uses `love` from PATH.

ifeq ($(OS),Windows_NT)
  LOVE := "$(LOCALAPPDATA)/Programs/LOVE/love.exe"
else
  LOVE := love
endif

.PHONY: help doctor lint test check smoke run dev sprites verify-sprites

help: ## show all targets
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-16s %s\n", $$1, $$2}'

doctor: ## verify toolchain is present (no install)
	./scripts/bootstrap.sh --check

lint: ## static analysis (Lua 5.1/LuaJIT dialect)
	luacheck src tests

test: ## headless logic specs (busted)
	busted tests/spec

check: lint test ## local CI: full quality gate

sprites: ## bake ASCII sprite maps into sheet.png + atlas.lua (needs love)
	$(LOVE) scripts/gen_sprites

verify-sprites: ## validate the generated spritesheet pixels (needs love)
	$(LOVE) scripts/verify_sheet

smoke: ## boot the game for 6 seconds (opens a window)
	$(LOVE) .

dev: ## run the game with hot reload (restarts on file change)
	$(LOVE) . --dev

run: ## run the game
	$(LOVE) .