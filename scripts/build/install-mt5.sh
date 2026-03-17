#!/usr/bin/env bash
set -euo pipefail

log() {
  printf '[build][mt5] %s\n' "$*"
}

fail() {
  printf '[build][mt5][error] %s\n' "$*" >&2
  exit 1
}

BUILD_WINEPREFIX="${BUILD_WINEPREFIX:-${WINEPREFIX:-/config/.wine}}"
MT5_INSTALLER_DIR="${MT5_INSTALLER_DIR:-/opt/installers}"
WINE_GECKO_DIR="${WINE_GECKO_DIR:-/opt/wine-offline/gecko}"
WINE_MONO_DIR="${WINE_MONO_DIR:-/opt/wine-offline/mono}"
MT5_LINUX_EXE="${BUILD_WINEPREFIX}/drive_c/Program Files/MetaTrader 5/terminal64.exe"
MT5_INSTALLER="${MT5_INSTALLER_DIR}/mt5setup.exe"

export WINEPREFIX="${BUILD_WINEPREFIX}"
export WINEDEBUG="${WINEDEBUG:--all}"
export WINEARCH="${WINEARCH:-win64}"
export WINEDLLOVERRIDES="${WINEDLLOVERRIDES:-winemenubuilder.exe=d}"
export GST_PLUGIN_SYSTEM_PATH_1_0="${GST_PLUGIN_SYSTEM_PATH_1_0:-}"
export GST_PLUGIN_PATH_1_0="${GST_PLUGIN_PATH_1_0:-}"
export GST_REGISTRY="${GST_REGISTRY:-/tmp/gstreamer-registry.dat}"

command -v wine >/dev/null 2>&1 || fail "wine 未安装"
command -v xvfb-run >/dev/null 2>&1 || fail "xvfb-run 未安装"

mkdir -p "$(dirname "${WINEPREFIX}")"
[[ -f "${MT5_INSTALLER}" ]] || fail "缺少预下载 MT5 安装器: ${MT5_INSTALLER}"
[[ -d "${WINE_GECKO_DIR}" ]] || fail "缺少 Gecko 离线目录: ${WINE_GECKO_DIR}"
[[ -d "${WINE_MONO_DIR}" ]] || fail "缺少 Mono 离线目录: ${WINE_MONO_DIR}"

if [[ ! -f "${WINEPREFIX}/system.reg" ]]; then
  log "初始化 Wine 前缀 ${WINEPREFIX}"
  rm -rf "${WINEPREFIX}"
  xvfb-run -a wineboot -u >/tmp/mt5-wineboot.log 2>&1 || {
    cat /tmp/mt5-wineboot.log >&2
    log "wineboot 首次初始化失败，清理前缀后重试一次"
    rm -rf "${WINEPREFIX}"
    xvfb-run -a wineboot -u >/tmp/mt5-wineboot-retry.log 2>&1 || {
      cat /tmp/mt5-wineboot-retry.log >&2
      fail "wineboot 初始化失败"
    }
  }
  wineserver -w
fi

log "设置 Wine 为 Windows 10 模式"
xvfb-run -a wine reg add 'HKEY_CURRENT_USER\Software\Wine' /v Version /t REG_SZ /d win10 /f >/tmp/mt5-winver.log 2>&1 || {
  cat /tmp/mt5-winver.log >&2
  fail "设置 Wine Windows 版本失败"
}

log "执行 MT5 无人值守安装"
xvfb-run -a bash -lc \
  "wine \"${MT5_INSTALLER}\" /auto \"/path:C:\\Program Files\\MetaTrader 5\"" \
  >/tmp/mt5-install.log 2>&1 || {
    cat /tmp/mt5-install.log >&2
    fail "MT5 无人值守安装失败"
  }
wineserver -w

[[ -f "${MT5_LINUX_EXE}" ]] || fail "未找到 terminal64.exe: ${MT5_LINUX_EXE}"
log "MT5 已安装: ${MT5_LINUX_EXE}"
