#!/usr/bin/env bash
set -euo pipefail

WINEPREFIX="${WINEPREFIX:-/config/.wine}"
MT5_LINUX_EXE="${WINEPREFIX}/drive_c/Program Files/MetaTrader 5/terminal64.exe"
STARTUP_MARKER="/config/.mt5-startup-in-progress"

if [[ -f "${STARTUP_MARKER}" ]]; then
  printf '[healthcheck] 检测到首次启动初始化中，暂不判定失败\n'
  exit 0
fi

if [[ ! -d "${WINEPREFIX}" ]]; then
  printf '[healthcheck] WINEPREFIX 不存在: %s\n' "${WINEPREFIX}" >&2
  exit 1
fi

if [[ ! -w "${WINEPREFIX}" ]]; then
  printf '[healthcheck] WINEPREFIX 不可写: %s\n' "${WINEPREFIX}" >&2
  exit 1
fi

if [[ ! -f "${MT5_LINUX_EXE}" ]]; then
  printf '[healthcheck] terminal64.exe 缺失: %s\n' "${MT5_LINUX_EXE}" >&2
  exit 1
fi

if ! pgrep -fa terminal64.exe >/dev/null; then
  printf '[healthcheck] 未检测到 terminal64.exe 进程\n' >&2
  exit 1
fi

exit 0
