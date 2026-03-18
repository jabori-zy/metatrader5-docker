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
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"

export WINEPREFIX="/opt/mt5-prefix"
export WINEDEBUG="${WINEDEBUG:--all}"
export WINEDLLOVERRIDES="${WINEDLLOVERRIDES:-winemenubuilder.exe=d}"
export WINE_GECKO_DIR="${WINE_GECKO_DIR:-/opt/wine-offline/gecko}"
export WINE_MONO_DIR="${WINE_MONO_DIR:-/opt/wine-offline/mono}"
export MT5_INSTALLER_DIR="${MT5_INSTALLER_DIR:-/opt/installers}"

MT5_LINUX_EXE="${WINEPREFIX}/drive_c/Program Files/MetaTrader 5/terminal64.exe"
MT5_LOG_DIR="/config/logs"
MT5_LOG_FILE="${MT5_LOG_DIR}/mt5.log"
STARTUP_MARKER="/config/.mt5-startup-in-progress"

cleanup_startup_marker() {
  rm -f "${STARTUP_MARKER}"
}

mkdir -p "${MT5_LOG_DIR}" || fail "failed to create log directory: ${MT5_LOG_DIR}"
touch "${MT5_LOG_FILE}" || fail "failed to create log file: ${MT5_LOG_FILE}"
exec > >(tee -a "${MT5_LOG_FILE}") 2>&1

touch "${STARTUP_MARKER}" || fail "failed to create startup marker: ${STARTUP_MARKER}"
trap cleanup_startup_marker EXIT

"${SCRIPT_DIR}/bootstrap-prefix.sh"

if [[ ! -f "${MT5_LINUX_EXE}" ]]; then
  log "MT5 not detected, running first-time installation"
  /scripts/build/install-mt5.sh || fail "MT5 first-time installation failed, check ${MT5_LOG_FILE}"
fi

PYTHON_EXE="$(find_windows_python || true)"
if [[ -z "${PYTHON_EXE}" ]]; then
  log "Windows Python not detected, running first-time installation"
  /scripts/build/install-python.sh || fail "Windows Python first-time installation failed, check ${MT5_LOG_FILE}"
fi

[[ -f "${MT5_LINUX_EXE}" ]] || fail "terminal64.exe not found: ${MT5_LINUX_EXE}"

log "starting MetaTrader 5"
# shellcheck disable=SC2086
wine "${MT5_LINUX_EXE}" /portable ${MT5_CMD_OPTIONS:-} >>"${MT5_LOG_FILE}" 2>&1 &
MT5_PID=$!

for _ in $(seq 1 30); do
  if pgrep -fa terminal64.exe >/dev/null; then
    log "MetaTrader 5 started"
    cleanup_startup_marker
    wait "${MT5_PID}"
    exit $?
  fi
  sleep 2
done

fail "MetaTrader 5 process failed to start, check ${MT5_LOG_FILE}"
