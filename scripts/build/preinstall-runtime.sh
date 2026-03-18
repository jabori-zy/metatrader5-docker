#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"

log() {
  printf '[build][preinstall] %s\n' "$*"
}

fail() {
  printf '[build][preinstall][error] %s\n' "$*" >&2
  exit 1
}

PREINSTALLED_WINEPREFIX="${PREINSTALLED_WINEPREFIX:-/opt/mt5-prefix}"

export WINEPREFIX="${PREINSTALLED_WINEPREFIX}"
export WINEDEBUG="${WINEDEBUG:--all}"
export WINEARCH="${WINEARCH:-win64}"
export WINEDLLOVERRIDES="${WINEDLLOVERRIDES:-winemenubuilder.exe=d}"
export DISPLAY="${DISPLAY:-}"
export GST_PLUGIN_SYSTEM_PATH_1_0="${GST_PLUGIN_SYSTEM_PATH_1_0:-}"
export GST_PLUGIN_PATH_1_0="${GST_PLUGIN_PATH_1_0:-}"
export GST_REGISTRY="${GST_REGISTRY:-/tmp/gstreamer-registry.dat}"

command -v wine >/dev/null 2>&1 || fail "wine is not installed"

mkdir -p "$(dirname "${WINEPREFIX}")"
rm -rf "${WINEPREFIX}"

log "downloading offline assets"
"${SCRIPT_DIR}/download-offline-assets.sh"

log "initializing base Wine prefix ${WINEPREFIX}"
run_gui wineboot -u >/tmp/preinstall-wineboot.log 2>&1 || {
  cat /tmp/preinstall-wineboot.log >&2
  fail "base Wine prefix initialization failed"
}
wait_for_wineserver

[[ -d "${WINEPREFIX}/drive_c" ]] || fail "drive_c not found after base prefix initialization"

log "preinstalled runtime is ready"
