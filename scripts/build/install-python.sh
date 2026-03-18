#!/usr/bin/env bash
set -euo pipefail

log() {
  printf '[build][python] %s\n' "$*"
}

fail() {
  printf '[build][python][error] %s\n' "$*" >&2
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

find_windows_python() {
  local preferred_32="${WINEPREFIX}/drive_c/Program Files (x86)/Python314-32/python.exe"
  local preferred="${WINEPREFIX}/drive_c/Program Files/Python314/python.exe"

  if [[ -f "${preferred_32}" ]]; then
    printf '%s\n' "${preferred_32}"
    return
  fi

  if [[ -f "${preferred}" ]]; then
    printf '%s\n' "${preferred}"
    return
  fi

  find "${WINEPREFIX}/drive_c" -type f \( -path '*/Program Files*/Python314*/python.exe' -o -path '*/Program Files*/Python*/python.exe' \) | sort | head -n 1
}

BUILD_WINEPREFIX="${BUILD_WINEPREFIX:-${WINEPREFIX:-/config/.wine}}"
MT5_INSTALLER_DIR="${MT5_INSTALLER_DIR:-/opt/installers}"
WINE_GECKO_DIR="${WINE_GECKO_DIR:-/opt/wine-offline/gecko}"
WINE_MONO_DIR="${WINE_MONO_DIR:-/opt/wine-offline/mono}"
PYTHON_INSTALLER="${MT5_INSTALLER_DIR}/python-3.14.0.exe"

export WINEPREFIX="${BUILD_WINEPREFIX}"
export WINEDEBUG="${WINEDEBUG:--all}"
export WINEARCH="${WINEARCH:-win64}"
export WINEDLLOVERRIDES="${WINEDLLOVERRIDES:-winemenubuilder.exe=d}"
export DISPLAY="${DISPLAY:-:1}"
export GST_PLUGIN_SYSTEM_PATH_1_0="${GST_PLUGIN_SYSTEM_PATH_1_0:-}"
export GST_PLUGIN_PATH_1_0="${GST_PLUGIN_PATH_1_0:-}"
export GST_REGISTRY="${GST_REGISTRY:-/tmp/gstreamer-registry.dat}"

command -v wine >/dev/null 2>&1 || fail "wine 未安装"
command -v winepath >/dev/null 2>&1 || fail "winepath 未安装"
command -v timeout >/dev/null 2>&1 || fail "timeout 未安装"

mkdir -p "${WINEPREFIX}"
[[ -f "${PYTHON_INSTALLER}" ]] || fail "缺少预下载 Python 安装器: ${PYTHON_INSTALLER}"
[[ -d "${WINE_GECKO_DIR}" ]] || fail "缺少 Gecko 离线目录: ${WINE_GECKO_DIR}"
[[ -d "${WINE_MONO_DIR}" ]] || fail "缺少 Mono 离线目录: ${WINE_MONO_DIR}"

log "执行 Python 静默安装"
run_gui wine "${PYTHON_INSTALLER}" /quiet InstallAllUsers=1 PrependPath=1 Include_test=0 >/tmp/python-install.log 2>&1 || {
  cat /tmp/python-install.log >&2
  fail "Python 静默安装失败"
}
wait_for_wineserver

PYTHON_LINUX_EXE="$(find_windows_python || true)"
[[ -n "${PYTHON_LINUX_EXE}" ]] || fail "未找到已安装的 python.exe"
PYTHON_WIN_EXE="$(winepath -w "${PYTHON_LINUX_EXE}")"
log "检测到 Windows Python: ${PYTHON_LINUX_EXE}"

log "验证 Windows Python 版本"
run_gui wine python --version >/tmp/python-version.log 2>&1 || {
  cat /tmp/python-version.log >&2
  fail "Python 版本检查失败"
}
cat /tmp/python-version.log

log "升级 pip"
run_gui wine "${PYTHON_WIN_EXE}" -m pip install --upgrade pip >/tmp/python-pip-upgrade.log 2>&1 || {
  cat /tmp/python-pip-upgrade.log >&2
  fail "pip 升级失败"
}

log "安装 MetaTrader5 Python 包"
run_gui wine "${PYTHON_WIN_EXE}" -m pip install MetaTrader5 >/tmp/python-mt5-pkg.log 2>&1 || {
  cat /tmp/python-mt5-pkg.log >&2
  fail "MetaTrader5 包安装失败"
}

log "验证 MetaTrader5 Python 包导入"
run_gui wine "${PYTHON_WIN_EXE}" -c 'import MetaTrader5; print(MetaTrader5.__version__)' >/tmp/python-mt5-import.log 2>&1 || {
  cat /tmp/python-mt5-import.log >&2
  fail "MetaTrader5 包导入验证失败"
}
cat /tmp/python-mt5-import.log
