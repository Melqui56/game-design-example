# ADR-0002: Environment provisioning with an idempotent bootstrap script

**Status:** Accepted
**Date:** 2026-08-26

## Context

Anyone cloning the repo must be able to bring up the development environment
with a single command, on any machine, and repeatably — avoiding "works on my
machine". Two approaches were evaluated: an idempotent script and a DevContainer.

## Decision

- **`scripts/bootstrap.sh`** is the source of truth for the environment: it
  detects the OS, asks the system about its state before mutating anything
  (idempotent), installs what is missing, and verifies at the end. Exits with
  a non-zero code if anything fails.
- **Linux first** (Fedora, Ubuntu/Debian), structured per-distro with `case`
  so macOS/Windows can be added without rewriting.
- The **same procedure is replicated in CI** (GitHub Actions, clean Ubuntu
  container) to run tests and build the `.love` artifact reproducibly. Docker
  is used where it matters (CI), not for interactive gameplay.
- **DevContainer as the main development path is rejected**: LÖVE needs
  GPU/OpenGL, audio and a window; running it inside a container means mounting
  X11/Wayland sockets and mapping the graphics device, which is fragile. It is
  the wrong tool for the nail of native gameplay.
- **`--check` lists all missing dependencies at once** (no fail-fast), so the
  user sees the full picture before deciding to install.

## Consequences

- A single command goes from `git clone` to a running game in under two minutes.
- Rebuilding the environment from scratch can be proven in CI whenever a clean
  machine is available.
- Two install branches (dnf/apt) must be maintained, but the cost is low and
  the benefit (onboarding + CI) is high.