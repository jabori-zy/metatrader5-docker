#!/usr/bin/env bash
set -euo pipefail

log() {
  printf '[build][mt5] %s\n' "$*"
}

fail() {
  printf '[build][mt5][error] %s\n' "$*" >&2
  exit 1
}

BUILD_WINEPREFIX="${BUILD_WINEPREFIX:-${MT5_TEMPLATE_WINEPREFIX:-/opt/mt5-template/.wine}}"
MT5_SETUP_URL="${MT5_SETUP_URL:-https://download.terminal.free/cdn/web/metaquotes.software.corp/mt5/mt5setup.exe}"
MT5_LINUX_EXE="${BUILD_WINEPREFIX}/drive_c/Program Files/MetaTrader 5/terminal64.exe"
MT5_INSTALLER="/tmp/mt5setup.exe"

export WINEPREFIX="${BUILD_WINEPREFIX}"
export WINEDEBUG="${WINEDEBUG:--all}"
export WINEARCH="${WINEARCH:-win64}"

command -v wine >/dev/null 2>&1 || fail "wine 未安装"
command -v xvfb-run >/dev/null 2>&1 || fail "xvfb-run 未安装"
command -v curl >/dev/null 2>&1 || fail "curl 未安装"

mkdir -p "${WINEPREFIX}"

if [[ ! -f "${WINEPREFIX}/system.reg" ]]; then
  log "初始化 Wine 前缀 ${WINEPREFIX}"
  xvfb-run -a wineboot --init >/tmp/mt5-wineboot.log 2>&1 || {
    cat /tmp/mt5-wineboot.log >&2
    fail "wineboot 初始化失败"
  }
  wineserver -w
fi

log "设置 Wine 为 Windows 10 模式"
xvfb-run -a wine reg add 'HKEY_CURRENT_USER\Software\Wine' /v Version /t REG_SZ /d win10 /f >/tmp/mt5-winver.log 2>&1 || {
  cat /tmp/mt5-winver.log >&2
  fail "设置 Wine Windows 版本失败"
}

log "下载 MT5 安装器"
curl -fL "${MT5_SETUP_URL}" -o "${MT5_INSTALLER}" || fail "下载 MT5 安装器失败: ${MT5_SETUP_URL}"

log "执行 MT5 无人值守安装"
xvfb-run -a bash -lc \
  'wine /tmp/mt5setup.exe /auto "/path:C:\Program Files\MetaTrader 5"' \
  >/tmp/mt5-install.log 2>&1 || {
    cat /tmp/mt5-install.log >&2
    fail "MT5 无人值守安装失败"
  }
wineserver -w
rm -f "${MT5_INSTALLER}"

[[ -f "${MT5_LINUX_EXE}" ]] || fail "未找到 terminal64.exe: ${MT5_LINUX_EXE}"
log "MT5 已安装: ${MT5_LINUX_EXE}"

