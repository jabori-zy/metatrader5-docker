#!/usr/bin/env bash
set -euo pipefail

log() {
  printf '[build][python] %s\n' "$*"
}

fail() {
  printf '[build][python][error] %s\n' "$*" >&2
  exit 1
}

BUILD_WINEPREFIX="${BUILD_WINEPREFIX:-${MT5_TEMPLATE_WINEPREFIX:-/opt/mt5-template/.wine}}"
PYTHON_SETUP_URL="${PYTHON_SETUP_URL:-https://www.python.org/ftp/python/3.14.0/python-3.14.0-amd64.exe}"
PYTHON_INSTALLER="/tmp/python-installer.exe"

export WINEPREFIX="${BUILD_WINEPREFIX}"
export WINEDEBUG="${WINEDEBUG:--all}"
export WINEARCH="${WINEARCH:-win64}"

command -v wine >/dev/null 2>&1 || fail "wine 未安装"
command -v winepath >/dev/null 2>&1 || fail "winepath 未安装"
command -v xvfb-run >/dev/null 2>&1 || fail "xvfb-run 未安装"
command -v curl >/dev/null 2>&1 || fail "curl 未安装"

mkdir -p "${WINEPREFIX}"

log "下载 Python 3.14 安装器"
curl -fL "${PYTHON_SETUP_URL}" -o "${PYTHON_INSTALLER}" || fail "下载 Python 安装器失败: ${PYTHON_SETUP_URL}"

log "执行 Python 静默安装"
xvfb-run -a wine "${PYTHON_INSTALLER}" /quiet InstallAllUsers=1 PrependPath=1 Include_test=0 >/tmp/python-install.log 2>&1 || {
  cat /tmp/python-install.log >&2
  fail "Python 静默安装失败"
}
wineserver -w
rm -f "${PYTHON_INSTALLER}"

PYTHON_LINUX_EXE="$(find "${WINEPREFIX}/drive_c" -type f -path '*/Python*/python.exe' | sort | head -n 1)"
[[ -n "${PYTHON_LINUX_EXE}" ]] || fail "未找到已安装的 python.exe"
PYTHON_WIN_EXE="$(winepath -w "${PYTHON_LINUX_EXE}")"

log "验证 Windows Python 版本"
xvfb-run -a wine "${PYTHON_WIN_EXE}" --version >/tmp/python-version.log 2>&1 || {
  cat /tmp/python-version.log >&2
  fail "Python 版本检查失败"
}
cat /tmp/python-version.log

log "升级 pip"
xvfb-run -a wine "${PYTHON_WIN_EXE}" -m pip install --upgrade pip >/tmp/python-pip-upgrade.log 2>&1 || {
  cat /tmp/python-pip-upgrade.log >&2
  fail "pip 升级失败"
}

log "安装 MetaTrader5 Python 包"
xvfb-run -a wine "${PYTHON_WIN_EXE}" -m pip install MetaTrader5 >/tmp/python-mt5-pkg.log 2>&1 || {
  cat /tmp/python-mt5-pkg.log >&2
  fail "MetaTrader5 包安装失败"
}

log "验证 MetaTrader5 Python 包导入"
xvfb-run -a wine "${PYTHON_WIN_EXE}" -c 'import MetaTrader5; print(MetaTrader5.__version__)' >/tmp/python-mt5-import.log 2>&1 || {
  cat /tmp/python-mt5-import.log >&2
  fail "MetaTrader5 包导入验证失败"
}
cat /tmp/python-mt5-import.log

