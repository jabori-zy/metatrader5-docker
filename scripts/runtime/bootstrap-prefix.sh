#!/usr/bin/env bash
set -euo pipefail

log() {
  printf '[runtime][bootstrap] %s\n' "$*"
}

fail() {
  printf '[runtime][bootstrap][error] %s\n' "$*" >&2
  exit 1
}

RUNTIME_WINEPREFIX="${WINEPREFIX:-/config/.wine}"
RUNTIME_PARENT="$(dirname "${RUNTIME_WINEPREFIX}")"
MT5_LINUX_EXE="${RUNTIME_WINEPREFIX}/drive_c/Program Files/MetaTrader 5/terminal64.exe"
mkdir -p "${RUNTIME_PARENT}" || fail "failed to create parent directory: ${RUNTIME_PARENT}"
[[ -w "${RUNTIME_PARENT}" ]] || fail "parent directory is not writable: ${RUNTIME_PARENT}"

if [[ ! -d "${RUNTIME_WINEPREFIX}" ]]; then
  log "creating Wine prefix directory for the first time: ${RUNTIME_WINEPREFIX}"
  mkdir -p "${RUNTIME_WINEPREFIX}" || fail "failed to create Wine prefix directory"
else
  log "Wine prefix already exists, skipping initialization"
fi

[[ -d "${RUNTIME_WINEPREFIX}" ]] || fail "Wine prefix does not exist: ${RUNTIME_WINEPREFIX}"
[[ -w "${RUNTIME_WINEPREFIX}" ]] || fail "Wine prefix is not writable: ${RUNTIME_WINEPREFIX}"

touch "${RUNTIME_WINEPREFIX}/.write-test" || fail "Wine prefix write test failed: ${RUNTIME_WINEPREFIX}"
rm -f "${RUNTIME_WINEPREFIX}/.write-test"

if [[ -f "${MT5_LINUX_EXE}" ]]; then
  log "existing MT5 installation detected"
else
  log "no MT5 found in current prefix, first-time installation will run at startup"
fi

log "Wine prefix is ready"
