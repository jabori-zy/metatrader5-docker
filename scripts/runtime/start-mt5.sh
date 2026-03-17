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
"${SCRIPT_DIR}/bootstrap-prefix.sh"

export WINEPREFIX="${WINEPREFIX:-/config/.wine}"
export WINEDEBUG="${WINEDEBUG:--all}"
export WINEDLLOVERRIDES="${WINEDLLOVERRIDES:-winemenubuilder.exe=d}"
export WINE_GECKO_DIR="${WINE_GECKO_DIR:-/opt/wine-offline/gecko}"
export WINE_MONO_DIR="${WINE_MONO_DIR:-/opt/wine-offline/mono}"
export MT5_INSTALLER_DIR="${MT5_INSTALLER_DIR:-/opt/installers}"

MT5_LINUX_EXE="${WINEPREFIX}/drive_c/Program Files/MetaTrader 5/terminal64.exe"
MT5_LOG_DIR="/config/logs"
MT5_LOG_FILE="${MT5_LOG_DIR}/mt5.log"
PYTHON_MARKER="$(find "${WINEPREFIX}/drive_c" -type f -path '*/Python*/python.exe' | sort | head -n 1 || true)"

mkdir -p "${MT5_LOG_DIR}" || fail "无法创建日志目录: ${MT5_LOG_DIR}"

if [[ ! -f "${MT5_LINUX_EXE}" ]]; then
  log "未检测到 MT5，执行首次安装"
  /scripts/build/install-mt5.sh >>"${MT5_LOG_FILE}" 2>&1 || fail "MT5 首次安装失败，请检查 ${MT5_LOG_FILE}"
fi

if [[ -z "${PYTHON_MARKER}" ]]; then
  log "未检测到 Windows Python，执行首次安装"
  /scripts/build/install-python.sh >>"${MT5_LOG_FILE}" 2>&1 || fail "Python 首次安装失败，请检查 ${MT5_LOG_FILE}"
fi

[[ -f "${MT5_LINUX_EXE}" ]] || fail "未找到 terminal64.exe: ${MT5_LINUX_EXE}"

log "启动 MetaTrader 5"
# shellcheck disable=SC2086
wine "${MT5_LINUX_EXE}" /portable ${MT5_CMD_OPTIONS:-} >>"${MT5_LOG_FILE}" 2>&1 &
MT5_PID=$!

for _ in $(seq 1 30); do
  if pgrep -fa terminal64.exe >/dev/null; then
    log "MetaTrader 5 已启动"
    wait "${MT5_PID}"
    exit $?
  fi
  sleep 2
done

fail "MetaTrader 5 进程未成功启动，请检查 ${MT5_LOG_FILE}"
