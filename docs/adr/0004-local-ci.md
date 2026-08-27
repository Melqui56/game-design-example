# ADR-0004: Local CI as the primary verification loop

**Status:** Accepted
**Date:** 2026-08-26
**Supersedes consideration in:** ADR-0002 (GitHub Actions auto-run on push)

## Context

During heavy iteration (many small commits), running GitHub Actions on every
push burns CI minutes and adds latency to feedback. We want a fast, free,
repeatable verification loop that runs on the developer machine.

## Decision

- A **Makefile** is the local CI: `make check` runs lint + headless tests in
  one gate; `make smoke` boots the game briefly; `make doctor` verifies the
  toolchain. It costs nothing and runs in seconds.
- **GitHub Actions is manual only** (`workflow_dispatch`): it never auto-runs
  on push. It stays in the repo so a final, clean verification on a pristine
  machine is one click away when needed.
- The verification steps are identical in both places (`busted` + `luacheck`),
  so a green `make check` locally means the same as the manual CI job.

## Consequences

- Iterating locally is free and immediate; no CI minutes spent per push.
- `make check` codifies the quality gate in one memorable command.
- If the workflow is ever re-enabled on push, no Makefile changes are needed —
  the two paths already agree.