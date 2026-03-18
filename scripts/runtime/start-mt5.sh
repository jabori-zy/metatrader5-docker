#!/usr/bin/env bash
set -euo pipefail

log() {
  printf '[runtime][start] %s\n' "$*"
}

fail() {
  printf '[runtime][start][error] %s\n' "$*" >&2
  exit 1
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

export WINEPREFIX="/opt/mt5-prefix"
export WINEDEBUG="${WINEDEBUG:--all}"
export WINEDLLOVERRIDES="${WINEDLLOVERRIDES:-winemenubuilder.exe=d}"
export WINE_GECKO_DIR="${WINE_GECKO_DIR:-/opt/wine-offline/gecko}"
export WINE_MONO_DIR="${WINE_MONO_DIR:-/opt/wine-offline/mono}"
export MT5_INSTALLER_DIR="${MT5_INSTALLER_DIR:-/opt/installers}"

MT5_LINUX_EXE="${WINEPREFIX}/drive_c/Program Files/MetaTrader 5/terminal64.exe"

"${SCRIPT_DIR}/bootstrap-prefix.sh"

[[ -f "${MT5_LINUX_EXE}" ]] || fail "terminal64.exe not found: ${MT5_LINUX_EXE}"

log "starting MetaTrader 5"
# shellcheck disable=SC2086
wine "${MT5_LINUX_EXE}" /portable ${MT5_CMD_OPTIONS:-} &
MT5_PID=$!

for _ in $(seq 1 30); do
  if pgrep -fa terminal64.exe >/dev/null; then
    log "MetaTrader 5 started"
    wait "${MT5_PID}"
    exit $?
  fi
  sleep 2
done

fail "MetaTrader 5 process failed to start"
