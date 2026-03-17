#!/usr/bin/env bash
set -euo pipefail

log() {
  printf '[runtime][bootstrap] %s\n' "$*"
}

fail() {
  printf '[runtime][bootstrap][error] %s\n' "$*" >&2
  exit 1
}

TEMPLATE_WINEPREFIX="${MT5_TEMPLATE_WINEPREFIX:-/opt/mt5-template/.wine}"
RUNTIME_WINEPREFIX="${WINEPREFIX:-/config/.wine}"
RUNTIME_PARENT="$(dirname "${RUNTIME_WINEPREFIX}")"
MT5_LINUX_EXE="${RUNTIME_WINEPREFIX}/drive_c/Program Files/MetaTrader 5/terminal64.exe"

[[ -d "${TEMPLATE_WINEPREFIX}" ]] || fail "模板前缀不存在: ${TEMPLATE_WINEPREFIX}"
mkdir -p "${RUNTIME_PARENT}" || fail "无法创建运行目录父路径: ${RUNTIME_PARENT}"
[[ -w "${RUNTIME_PARENT}" ]] || fail "运行目录父路径不可写: ${RUNTIME_PARENT}"

if [[ ! -d "${RUNTIME_WINEPREFIX}" ]]; then
  log "首次初始化运行时前缀: ${RUNTIME_WINEPREFIX}"
  cp -a "${TEMPLATE_WINEPREFIX}" "${RUNTIME_WINEPREFIX}" || fail "复制模板前缀失败"
else
  log "运行时前缀已存在，跳过初始化"
fi

[[ -d "${RUNTIME_WINEPREFIX}" ]] || fail "运行时前缀不存在: ${RUNTIME_WINEPREFIX}"
[[ -w "${RUNTIME_WINEPREFIX}" ]] || fail "运行时前缀不可写: ${RUNTIME_WINEPREFIX}"
[[ -f "${MT5_LINUX_EXE}" ]] || fail "terminal64.exe 缺失: ${MT5_LINUX_EXE}"

touch "${RUNTIME_WINEPREFIX}/.write-test" || fail "运行时前缀写入测试失败: ${RUNTIME_WINEPREFIX}"
rm -f "${RUNTIME_WINEPREFIX}/.write-test"

log "运行时前缀已就绪"

