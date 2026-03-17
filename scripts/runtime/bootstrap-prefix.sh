#!/usr/bin/env bash
set -euo pipefail

log() {
  printf '[runtime][bootstrap] %s\n' "$*"
}

fail() {
  printf '[runtime][bootstrap][error] %s\n' "$*" >&2
  exit 1
}

RUNTIME_WINEPREFIX="${WINEPREFIX:-/config/.wine}"
RUNTIME_PARENT="$(dirname "${RUNTIME_WINEPREFIX}")"
MT5_LINUX_EXE="${RUNTIME_WINEPREFIX}/drive_c/Program Files/MetaTrader 5/terminal64.exe"
mkdir -p "${RUNTIME_PARENT}" || fail "无法创建运行目录父路径: ${RUNTIME_PARENT}"
[[ -w "${RUNTIME_PARENT}" ]] || fail "运行目录父路径不可写: ${RUNTIME_PARENT}"

if [[ ! -d "${RUNTIME_WINEPREFIX}" ]]; then
  log "首次创建运行时前缀目录: ${RUNTIME_WINEPREFIX}"
  mkdir -p "${RUNTIME_WINEPREFIX}" || fail "创建运行时前缀失败"
else
  log "运行时前缀已存在，跳过初始化"
fi

[[ -d "${RUNTIME_WINEPREFIX}" ]] || fail "运行时前缀不存在: ${RUNTIME_WINEPREFIX}"
[[ -w "${RUNTIME_WINEPREFIX}" ]] || fail "运行时前缀不可写: ${RUNTIME_WINEPREFIX}"

touch "${RUNTIME_WINEPREFIX}/.write-test" || fail "运行时前缀写入测试失败: ${RUNTIME_WINEPREFIX}"
rm -f "${RUNTIME_WINEPREFIX}/.write-test"

if [[ -f "${MT5_LINUX_EXE}" ]]; then
  log "检测到已有 MT5 安装"
else
  log "当前前缀中还没有 MT5，启动阶段将执行首次安装"
fi

log "运行时前缀已就绪"
