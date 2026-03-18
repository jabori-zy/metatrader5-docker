#!/usr/bin/env bash
set -euo pipefail

log() {
  printf '[build][assets] %s\n' "$*"
}

fail() {
  printf '[build][assets][error] %s\n' "$*" >&2
  exit 1
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || fail "缺少命令: $1"
}

get_app_ver() {
  local app="${1^^}"
  local wine_ver="$2"
  local url="https://raw.githubusercontent.com/wine-mirror/wine/wine-${wine_ver}/dlls/appwiz.cpl/addons.c"

  curl -fsSL "$url" | grep -E "^#define ${app}_VERSION\\s" | awk -F'"' '{print $2}'
}

download_file() {
  local url="$1"
  local output="$2"

  log "下载 $(basename "$output")"
  curl -fL "$url" -o "$output" || fail "下载失败: $url"
  [[ -s "$output" ]] || fail "下载文件为空: $output"
}

require_cmd curl
require_cmd wine

MT5_INSTALLER_DIR="${MT5_INSTALLER_DIR:-/opt/installers}"
WINE_GECKO_DIR="${WINE_GECKO_DIR:-/opt/wine-offline/gecko}"
WINE_MONO_DIR="${WINE_MONO_DIR:-/opt/wine-offline/mono}"
MT5_SETUP_URL="${MT5_SETUP_URL:-https://download.mql5.com/cdn/web/metaquotes.software.corp/mt5/mt5setup.exe}"
PYTHON_SETUP_URL="${PYTHON_SETUP_URL:-https://www.python.org/ftp/python/3.14.0/python-3.14.0-amd64.exe}"

mkdir -p "$MT5_INSTALLER_DIR" "$WINE_GECKO_DIR" "$WINE_MONO_DIR"

WINE_VER="$(wine --version | awk '{print $1}' | sed -E 's/^wine-//')"
[[ -n "$WINE_VER" ]] || fail "无法解析 wine 版本"
log "检测到 wine 版本: $WINE_VER"

GECKO_VER="$(get_app_ver gecko "$WINE_VER")"
MONO_VER="$(get_app_ver mono "$WINE_VER")"
[[ -n "$GECKO_VER" ]] || fail "无法解析 Gecko 版本"
[[ -n "$MONO_VER" ]] || fail "无法解析 Mono 版本"
log "Gecko 版本: $GECKO_VER"
log "Mono 版本: $MONO_VER"

download_file "$MT5_SETUP_URL" "$MT5_INSTALLER_DIR/mt5setup.exe"
download_file "$PYTHON_SETUP_URL" "$MT5_INSTALLER_DIR/python-3.14.0-amd64.exe"
download_file "https://dl.winehq.org/wine/wine-gecko/${GECKO_VER}/wine-gecko-${GECKO_VER}-x86.msi" \
  "$WINE_GECKO_DIR/wine-gecko-${GECKO_VER}-x86.msi"
download_file "https://dl.winehq.org/wine/wine-gecko/${GECKO_VER}/wine-gecko-${GECKO_VER}-x86_64.msi" \
  "$WINE_GECKO_DIR/wine-gecko-${GECKO_VER}-x86_64.msi"
download_file "https://dl.winehq.org/wine/wine-mono/${MONO_VER}/wine-mono-${MONO_VER}-x86.msi" \
  "$WINE_MONO_DIR/wine-mono-${MONO_VER}-x86.msi"

log "离线资源已准备完成"
