#!/usr/bin/env bash
#
# bootstrap.sh — provision local environment for the game project.
#
# Usage:
#   ./bootstrap.sh            detect, install what's missing, verify.
#   ./bootstrap.sh --check    only verify the environment, change nothing.
#
# Idempotent: safe to run any number of times.
#
# Supported today: Fedora / Ubuntu / Debian (Linux).
# macOS and Windows are designed-for but not wired up (see docs/adr/0002).

set -euo pipefail

# ---------------------------------------------------------------------------
# Terminal output helpers
# ---------------------------------------------------------------------------

if [[ -t 1 ]]; then
  C_GREEN="\033[32m"; C_YELLOW="\033[33m"; C_RED="\033[31m"; C_RESET="\033[0m"
else
  C_GREEN=""; C_YELLOW=""; C_RED=""; C_RESET=""
fi

info() { echo -e "${C_GREEN}[bootstrap]${C_RESET} $*"; }
warn() { echo -e "${C_YELLOW}[bootstrap]${C_RESET} $*"; }
err()  { echo -e "${C_RED}[bootstrap]${C_RESET} $*" >&2; }

# ---------------------------------------------------------------------------
# CLI options
# ---------------------------------------------------------------------------

CHECK=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --check|-c) CHECK=true ;;
    -h|--help) sed -n '2,7p' "$0"; exit 0 ;;
    *) err "unknown option: $1"; exit 1 ;;
  esac
  shift
done

# ---------------------------------------------------------------------------
# Environment detection
# ---------------------------------------------------------------------------

command_exists() { command -v "$1" >/dev/null 2>&1; }

require_sudo() {
  if [[ $EUID -eq 0 ]]; then
    echo ""
  elif command_exists sudo && sudo -n true >/dev/null 2>&1; then
    echo "sudo"
  elif command_exists sudo; then
    echo "sudo"
  else
    err "need root privileges to install packages and no 'sudo' found."
    exit 1
  fi
}

case "$(uname -s)" in
  Linux)
    if [[ -r /etc/os-release ]]; then
      source /etc/os-release
      DISTRO="${ID:-unknown}"
    else
      err "cannot detect distro: missing /etc/os-release"
      exit 1
    fi
    ;;
  *)
    err "'$(uname -s)' not supported yet. Only Linux is wired up for now."
    exit 1
    ;;
esac

# ---------------------------------------------------------------------------
# Package helpers (idempotent: ask the system BEFORE mutating)
# ---------------------------------------------------------------------------

available() {
  case "$DISTRO" in
    fedora)  dnf list --installed "$1" >/dev/null 2>&1 ;;
    ubuntu|debian) dpkg -s "$1" >/dev/null 2>&1 ;;
    *) err "no package lookup for distro '$DISTRO'"; return 1 ;;
  esac
}

install_package() {
  local pkg="$1"
  if available "$pkg"; then
    info "already installed: $pkg"
    return 0
  fi
  warn "installing $pkg ..."
  case "$DISTRO" in
    fedora)
      $SUDO dnf install -y "$pkg"
      ;;
    ubuntu|debian)
      $SUDO apt-get update -qq
      $SUDO apt-get install -y -qq "$pkg"
      ;;
    *)
      err "unsupported distro '$DISTRO'"
      return 1
      ;;
  esac
  if ! available "$pkg"; then
    err "installation of '$pkg' did not register in the package DB. Abort."
    return 1
  fi
}

install_rock() {
  local rock="$1"
  if command_exists "$rock"; then
    info "rock present: $rock"
    return 0
  fi
  warn "installing rock: $rock ..."
  $SUDO /usr/bin/luarocks install "$rock"
  if ! command_exists "$rock"; then
    err "could not install rock '$rock'. Abort."
    return 1
  fi
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

PACKAGES="love luajit luarocks lua lua-devel"
ROCKS="busted luacheck"

if [[ "$CHECK" == true ]]; then
  info "checking environment ..."
  MISSING=()
  for pkg in $PACKAGES; do
    if available "$pkg"; then
      info "ok: $pkg"
    else
      MISSING+=("$pkg")
    fi
  done
  for rock in $ROCKS; do
    if command_exists "$rock"; then
      info "ok: $rock"
    else
      MISSING+=("$rock")
    fi
  done
  if [[ ${#MISSING[@]} -gt 0 ]]; then
    err "missing (install with ./bootstrap.sh): ${MISSING[*]}"
    exit 1
  fi
  info "all dependencies present."
  exit 0
fi

SUDO="$(require_sudo)"

info "detected: $DISTRO"
for pkg in $PACKAGES; do
  install_package "$pkg"
done
for rock in $ROCKS; do
  install_rock "$rock"
done

info "verifying ..."
love --version
luajit -v
busted --version
luacheck --version

info "environment ready."