#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

mkdir -p "$(dirname "${WINEPREFIX}")"
rm -rf "${WINEPREFIX}"

log "downloading offline assets"
"${SCRIPT_DIR}/download-offline-assets.sh"

log "installing Windows Python into ${WINEPREFIX}"
"${SCRIPT_DIR}/install-python.sh"

PYTHON_EXE="$(find "${WINEPREFIX}/drive_c" -type f -path '*/Program Files*/Python*/python.exe' | sort | head -n 1 || true)"
[[ -n "${PYTHON_EXE}" ]] || fail "python.exe not found after preinstall"

log "preinstalled runtime is ready"
