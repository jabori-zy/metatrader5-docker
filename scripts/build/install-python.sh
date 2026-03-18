#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=../lib/common.sh
source "${SCRIPT_DIR}/../lib/common.sh"

log() {
  printf '[build][python] %s\n' "$*"
}

fail() {
  printf '[build][python][error] %s\n' "$*" >&2
  exit 1
}

BUILD_WINEPREFIX="${BUILD_WINEPREFIX:-${WINEPREFIX:-/opt/mt5-prefix}}"
MT5_INSTALLER_DIR="${MT5_INSTALLER_DIR:-/opt/installers}"
WINE_GECKO_DIR="${WINE_GECKO_DIR:-/opt/wine-offline/gecko}"
WINE_MONO_DIR="${WINE_MONO_DIR:-/opt/wine-offline/mono}"
PYTHON_INSTALLER="${MT5_INSTALLER_DIR}/python-3.9.13-amd64.exe"

export WINEPREFIX="${BUILD_WINEPREFIX}"
export WINEDEBUG="${WINEDEBUG:--all}"
export WINEARCH="${WINEARCH:-win64}"
export WINEDLLOVERRIDES="${WINEDLLOVERRIDES:-winemenubuilder.exe=d}"
export DISPLAY="${DISPLAY:-}"
export GST_PLUGIN_SYSTEM_PATH_1_0="${GST_PLUGIN_SYSTEM_PATH_1_0:-}"
export GST_PLUGIN_PATH_1_0="${GST_PLUGIN_PATH_1_0:-}"
export GST_REGISTRY="${GST_REGISTRY:-/tmp/gstreamer-registry.dat}"

command -v wine >/dev/null 2>&1 || fail "wine is not installed"
command -v winepath >/dev/null 2>&1 || fail "winepath is not installed"
command -v timeout >/dev/null 2>&1 || fail "timeout is not installed"

mkdir -p "${WINEPREFIX}"
[[ -f "${PYTHON_INSTALLER}" ]] || fail "pre-downloaded Python installer not found: ${PYTHON_INSTALLER}"
[[ -d "${WINE_GECKO_DIR}" ]] || fail "Gecko offline directory not found: ${WINE_GECKO_DIR}"
[[ -d "${WINE_MONO_DIR}" ]] || fail "Mono offline directory not found: ${WINE_MONO_DIR}"

log "running Python silent installation"
run_gui wine "${PYTHON_INSTALLER}" /quiet InstallAllUsers=1 PrependPath=1 Include_test=0 >/tmp/python-install.log 2>&1 || {
  cat /tmp/python-install.log >&2
  fail "Python silent installation failed"
}
wait_for_wineserver

PYTHON_LINUX_EXE="$(find_windows_python || true)"
[[ -n "${PYTHON_LINUX_EXE}" ]] || fail "installed python.exe not found"
PYTHON_WIN_EXE="$(winepath -w "${PYTHON_LINUX_EXE}")"
log "detected Windows Python: ${PYTHON_LINUX_EXE}"

log "verifying Windows Python version"
run_gui wine python --version >/tmp/python-version.log 2>&1 || {
  cat /tmp/python-version.log >&2
  fail "Python version check failed"
}
cat /tmp/python-version.log

log "upgrading pip"
run_gui wine "${PYTHON_WIN_EXE}" -m pip install --upgrade pip >/tmp/python-pip-upgrade.log 2>&1 || {
  cat /tmp/python-pip-upgrade.log >&2
  fail "pip upgrade failed"
}

log "installing MetaTrader5 Python package"
run_gui wine "${PYTHON_WIN_EXE}" -m pip install MetaTrader5 >/tmp/python-mt5-pkg.log 2>&1 || {
  cat /tmp/python-mt5-pkg.log >&2
  fail "MetaTrader5 package installation failed"
}

log "verifying MetaTrader5 Python package import"
run_gui wine "${PYTHON_WIN_EXE}" -c 'import MetaTrader5; print(MetaTrader5.__version__)' >/tmp/python-mt5-import.log 2>&1 || {
  cat /tmp/python-mt5-import.log >&2
  fail "MetaTrader5 package import verification failed"
}
cat /tmp/python-mt5-import.log
