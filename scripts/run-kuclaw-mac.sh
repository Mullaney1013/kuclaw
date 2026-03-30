#!/bin/zsh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
BUILD_DIR="${ROOT_DIR}/build"
APP_PATH="${BUILD_DIR}/apps/kuclaw-desktop/Kuclaw.app"
BIN_PATH="${APP_PATH}/Contents/MacOS/Kuclaw"
LOG_DIR="${HOME}/Library/Logs"
LOG_FILE="${LOG_DIR}/Kuclaw.manual.log"

MODE="open"
DO_BUILD=0
KILL_OLD=1

usage() {
  cat <<'EOF'
用法:
  ./scripts/run-kuclaw-mac.sh [--build] [--direct] [--no-kill]

选项:
  --build    启动前执行 cmake 构建；若 build 目录不存在则自动先 configure。
  --direct   直接运行二进制，并把日志写入 ~/Library/Logs/Kuclaw.manual.log。
  --open     使用 open 启动 .app（默认，最适合完整 GUI 会话）。
  --no-kill  启动前不主动结束旧的 Kuclaw 进程。
  -h, --help 显示帮助。

说明:
  1. 请在 macOS 已登录桌面的 Terminal.app / iTerm2 中运行。
  2. 默认会先 pkill 旧的 Kuclaw，再走 open 打开 .app。
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --build)
      DO_BUILD=1
      ;;
    --direct)
      MODE="direct"
      ;;
    --open)
      MODE="open"
      ;;
    --no-kill)
      KILL_OLD=0
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "未知参数: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
  shift
done

if [[ "${OSTYPE:-}" != darwin* ]]; then
  echo "这个脚本只适用于 macOS。" >&2
  exit 1
fi

if [[ -n "${SSH_CONNECTION:-}" || -n "${SSH_TTY:-}" ]]; then
  echo "检测到当前是 SSH 会话。Kuclaw 需要本地 Aqua GUI 会话，建议改在 Terminal.app / iTerm2 中运行。" >&2
fi

mkdir -p "${LOG_DIR}"

if [[ "${DO_BUILD}" -eq 1 ]]; then
  if [[ ! -f "${BUILD_DIR}/CMakeCache.txt" ]]; then
    if command -v brew >/dev/null 2>&1; then
      QT_PREFIX="$(brew --prefix qt 2>/dev/null || true)"
    else
      QT_PREFIX=""
    fi

    if [[ -n "${QT_PREFIX}" ]]; then
      cmake -S "${ROOT_DIR}" -B "${BUILD_DIR}" -DCMAKE_PREFIX_PATH="${QT_PREFIX}"
    else
      cmake -S "${ROOT_DIR}" -B "${BUILD_DIR}"
    fi
  fi

  cmake --build "${BUILD_DIR}" --target kuclaw_desktop -j "${KUCLAW_BUILD_JOBS:-4}"
fi

if [[ ! -d "${APP_PATH}" || ! -x "${BIN_PATH}" ]]; then
  cat >&2 <<EOF
未找到 Kuclaw 可执行产物:
  ${APP_PATH}

可以先运行:
  ./scripts/run-kuclaw-mac.sh --build
EOF
  exit 1
fi

if [[ "${KILL_OLD}" -eq 1 ]]; then
  pkill -x Kuclaw 2>/dev/null || true
  sleep 0.2
fi

if [[ "${MODE}" == "open" ]]; then
  open -n "${APP_PATH}"
  echo "Kuclaw 已通过 open 启动:"
  echo "  ${APP_PATH}"
  exit 0
fi

echo "Kuclaw 以前台方式启动，日志同时写入:"
echo "  ${LOG_FILE}"
exec "${BIN_PATH}" 2>&1 | tee -a "${LOG_FILE}"
