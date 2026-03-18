#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"

log() {
  printf '[runtime][bootstrap] %s\n' "$*"
}

fail() {
  printf '[runtime][bootstrap][error] %s\n' "$*" >&2
  exit 1
}

RUNTIME_WINEPREFIX="/opt/mt5-prefix"
MT5_LINUX_EXE="${RUNTIME_WINEPREFIX}/drive_c/Program Files/MetaTrader 5/terminal64.exe"

export WINEPREFIX="${RUNTIME_WINEPREFIX}"

[[ -d "${RUNTIME_WINEPREFIX}" ]] || fail "preinstalled Wine prefix does not exist: ${RUNTIME_WINEPREFIX}"
[[ -f "${MT5_LINUX_EXE}" ]] || fail "terminal64.exe not found: ${MT5_LINUX_EXE}"

PYTHON_EXE="$(find_windows_python || true)"
[[ -n "${PYTHON_EXE}" ]] || fail "Windows Python was not found in preinstalled prefix"

log "preinstalled Wine prefix is ready"
