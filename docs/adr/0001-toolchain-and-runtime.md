# ADR-0001: Toolchain and runtime

**Status:** Accepted
**Date:** 2026-08-26

## Context

A 2D game built with Lua and LÖVE. We need to pin the
runtime version so that development and CI use exactly the same environment.

## Decision

- **LÖVE 11.5** as the pinned stable version. It is the latest stable release
  (December 2023) as of this ADR; 12.0 is still under development, and we do
  not target unstable runtimes in a project that must be verifiable.
- **LuaJIT 2.1**, the interpreter LÖVE embeds by default since 11.4
  (Lua 5.1 dialect).
- Source code is written in the **Lua 5.1 / LuaJIT dialect** (no 5.2+).
- Installation through each OS's official package manager, with a final
  version check (`love --version`).

## Consequences

- The same game code runs on Windows, macOS, Linux, Android and iOS, which
  maximizes the reach of a demo.
- Pinning the version means any machine (and our CI) replicates the same
  runtime.
- Fedora and Ubuntu/Debian ship LÖVE 11.x in their official repos, so setup
  is reproducible without downloading binaries by hand.

## Sources

- love2d.org — official release changelogs (11.5, latest stable).
- love2d.org — LÖVE embeds LuaJIT; JIT is disabled by default only on macOS
  arm64 due to JIT reliability.