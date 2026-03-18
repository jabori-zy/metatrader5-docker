#!/usr/bin/env bash
set -euo pipefail

WINEPREFIX="/opt/mt5-prefix"
MT5_LINUX_EXE="${WINEPREFIX}/drive_c/Program Files/MetaTrader 5/terminal64.exe"

if [[ ! -d "${WINEPREFIX}" ]]; then
  printf '[healthcheck] preinstalled WINEPREFIX does not exist: %s\n' "${WINEPREFIX}" >&2
  exit 1
fi

if [[ ! -f "${MT5_LINUX_EXE}" ]]; then
  printf '[healthcheck] terminal64.exe not found: %s\n' "${MT5_LINUX_EXE}" >&2
  exit 1
fi

if ! pgrep -fa terminal64.exe >/dev/null; then
  printf '[healthcheck] terminal64.exe process not detected\n' >&2
  exit 1
fi

exit 0
