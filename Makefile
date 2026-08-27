.PHONY: help doctor lint test check smoke run dev

help: ## show all targets
	@grep -E '^[a-zA-Z_-]+:.*?## ' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  %-12s %s\n", $$1, $$2}'

doctor: ## verify toolchain is present (no install)
	./scripts/bootstrap.sh --check

lint: ## static analysis (Lua 5.1/LuaJIT dialect)
	luacheck src tests

test: ## headless logic specs (busted)
	busted tests/spec

check: lint test ## local CI: full quality gate

smoke: ## boot the game for 6 seconds (opens a window)
	timeout 6 love .

dev: ## run the game with hot reload (restarts on file change)
	LOVE_DEV=1 love .

run: ## run the game
	love .