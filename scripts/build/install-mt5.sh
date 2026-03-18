#!/usr/bin/env bash
set -euo pipefail

log() {
  printf '[build][mt5] %s\n' "$*"
}

fail() {
  printf '[build][mt5][error] %s\n' "$*" >&2
  exit 1
}

run_gui() {
  if [[ -n "${DISPLAY:-}" ]]; then
    "$@"
    return
  fi

  command -v xvfb-run >/dev/null 2>&1 || fail "未检测到 DISPLAY，且 xvfb-run 未安装"
  xvfb-run -a "$@"
}

wait_for_wineserver() {
  local timeout_secs="${WINE_WAIT_TIMEOUT:-60}"

  if timeout "${timeout_secs}" wineserver -w; then
    return
  fi

  log "wineserver 等待超时，强制结束残留进程"
  wineserver -k >/dev/null 2>&1 || true
  sleep 2
}

BUILD_WINEPREFIX="${BUILD_WINEPREFIX:-${WINEPREFIX:-/config/.wine}}"
MT5_INSTALLER_DIR="${MT5_INSTALLER_DIR:-/opt/installers}"
WINE_GECKO_DIR="${WINE_GECKO_DIR:-/opt/wine-offline/gecko}"
WINE_MONO_DIR="${WINE_MONO_DIR:-/opt/wine-offline/mono}"
MT5_INSTALL_TIMEOUT="${MT5_INSTALL_TIMEOUT:-600}"
MT5_LINUX_EXE="${BUILD_WINEPREFIX}/drive_c/Program Files/MetaTrader 5/terminal64.exe"
MT5_INSTALLER="${MT5_INSTALLER_DIR}/mt5setup.exe"
MONO_MARKER_DIR="${BUILD_WINEPREFIX}/drive_c/windows/mono"
MONO_INSTALLER="$(find "${WINE_MONO_DIR}" -maxdepth 1 -type f -name 'wine-mono-*.msi' | sort | head -n 1 || true)"

export WINEPREFIX="${BUILD_WINEPREFIX}"
export WINEDEBUG="${WINEDEBUG:--all}"
export WINEARCH="${WINEARCH:-win64}"
export WINEDLLOVERRIDES="${WINEDLLOVERRIDES:-winemenubuilder.exe=d}"
export DISPLAY="${DISPLAY:-:1}"
export GST_PLUGIN_SYSTEM_PATH_1_0="${GST_PLUGIN_SYSTEM_PATH_1_0:-}"
export GST_PLUGIN_PATH_1_0="${GST_PLUGIN_PATH_1_0:-}"
export GST_REGISTRY="${GST_REGISTRY:-/tmp/gstreamer-registry.dat}"

command -v wine >/dev/null 2>&1 || fail "wine 未安装"
command -v timeout >/dev/null 2>&1 || fail "timeout 未安装"

mkdir -p "$(dirname "${WINEPREFIX}")"
[[ -f "${MT5_INSTALLER}" ]] || fail "缺少预下载 MT5 安装器: ${MT5_INSTALLER}"
[[ -d "${WINE_GECKO_DIR}" ]] || fail "缺少 Gecko 离线目录: ${WINE_GECKO_DIR}"
[[ -d "${WINE_MONO_DIR}" ]] || fail "缺少 Mono 离线目录: ${WINE_MONO_DIR}"
[[ -n "${MONO_INSTALLER}" ]] || fail "缺少 Mono 安装器: ${WINE_MONO_DIR}"

if [[ ! -f "${WINEPREFIX}/system.reg" ]]; then
  log "初始化 Wine 前缀 ${WINEPREFIX}"
  rm -rf "${WINEPREFIX}"
  run_gui winecfg -v=win10 >/tmp/mt5-winecfg-init.log 2>&1 || {
    cat /tmp/mt5-winecfg-init.log >&2
    fail "winecfg 初始化失败"
  }
  wait_for_wineserver
fi

log "设置 Wine 为 Windows 10 模式"
run_gui winecfg -v=win10 >/tmp/mt5-winver.log 2>&1 || {
  cat /tmp/mt5-winver.log >&2
  fail "设置 Wine Windows 版本失败"
}
wait_for_wineserver

if [[ ! -d "${MONO_MARKER_DIR}" ]]; then
  log "安装 Wine Mono"
  run_gui wine msiexec /i "${MONO_INSTALLER}" /qn >/tmp/mt5-mono.log 2>&1 || {
    cat /tmp/mt5-mono.log >&2
    fail "Wine Mono 安装失败"
  }
  wait_for_wineserver
else
  log "Wine Mono 已安装，跳过"
fi

log "执行 MT5 无人值守安装"
log "注意: mt5setup.exe 是引导安装器，仍可能联网下载 MT5 主体"
rm -f /tmp/mt5-install.log
run_gui bash -lc "wine \"${MT5_INSTALLER}\" /auto" >/tmp/mt5-install.log 2>&1 &
INSTALLER_PID=$!
START_TIME=$SECONDS
INSTALLER_EXIT_REPORTED=0

while (( SECONDS - START_TIME < MT5_INSTALL_TIMEOUT )); do
  if [[ -f "${MT5_LINUX_EXE}" ]]; then
    break
  fi

  if [[ "${INSTALLER_EXIT_REPORTED}" -eq 0 ]] && ! kill -0 "${INSTALLER_PID}" 2>/dev/null; then
    set +e
    wait "${INSTALLER_PID}"
    INSTALLER_STATUS=$?
    set -e
    log "MT5 安装器进程已退出，返回码: ${INSTALLER_STATUS}，继续等待安装结果"
    INSTALLER_EXIT_REPORTED=1
  fi

  sleep 5
done

if [[ ! -f "${MT5_LINUX_EXE}" ]]; then
  {
    echo
    echo "[build][mt5][error] MT5 安装超时 (${MT5_INSTALL_TIMEOUT}s)"
    ps -ef | grep -Ei 'mt5setup|terminal64|wine|winedevice|wineserver' | grep -v grep || true
  } >>/tmp/mt5-install.log
  wineserver -k >/dev/null 2>&1 || true
  cat /tmp/mt5-install.log >&2
  fail "MT5 无人值守安装失败"
fi

wait_for_wineserver

[[ -f "${MT5_LINUX_EXE}" ]] || fail "未找到 terminal64.exe: ${MT5_LINUX_EXE}"
log "MT5 已安装: ${MT5_LINUX_EXE}"
