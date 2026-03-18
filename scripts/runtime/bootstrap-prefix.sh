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

export WINEPREFIX="${RUNTIME_WINEPREFIX}"

[[ -d "${RUNTIME_WINEPREFIX}" ]] || fail "preinstalled Wine prefix does not exist: ${RUNTIME_WINEPREFIX}"
[[ -d "${RUNTIME_WINEPREFIX}/drive_c" ]] || fail "preinstalled drive_c does not exist: ${RUNTIME_WINEPREFIX}/drive_c"

log "preinstalled Wine prefix is ready"
