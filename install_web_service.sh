#!/usr/bin/env bash
set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

log() { echo -e "${BLUE}[INFO]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
err() { echo -e "${RED}[ERROR]${NC} $*"; }
succ() { echo -e "${GREEN}[OK]${NC} $*"; }

in_termux() { [[ -n "${TERMUX_VERSION:-}" ]] && [[ -n "${PREFIX:-}" ]]; }

ensure_termux() {
  if ! in_termux; then
    err "该脚本仅用于 Termux 环境（需要 TERMUX_VERSION/PREFIX）"
    exit 1
  fi
}

ensure_pkg() {
  if ! command -v pkg >/dev/null 2>&1; then
    err "未找到 pkg，请确认在 Termux 中运行"
    exit 1
  fi
}

ensure_termux_services() {
  if ! command -v sv >/dev/null 2>&1; then
    log "安装 termux-services（提供 sv/sv-enable 等）"
    pkg install -y termux-services
  fi
  if ! command -v sv >/dev/null 2>&1; then
    err "termux-services 安装失败：未找到 sv"
    exit 1
  fi
  if ! command -v sv-enable >/dev/null 2>&1; then
    warn "未找到 sv-enable，后续将尝试直接用 sv 管理（但建议安装 termux-services）"
  fi
}

write_env_file() {
  local env_file="$HOME/.autoglm/web_service.env"
  mkdir -p "$HOME/.autoglm"
  if [[ -f "$env_file" ]]; then
    log "检测到已有配置: $env_file（保持不变）"
    return 0
  fi
  cat > "$env_file" <<'EOF'
# AutoGLM Web Service Environment
# 修改后执行：sv restart autoglm-web
AUTOGLM_WEB_HOST=0.0.0.0
AUTOGLM_WEB_PORT=8000

# Open-AutoGLM 目录（默认 ~/Open-AutoGLM）
# AUTOGLM_DIR=$HOME/Open-AutoGLM

# 自定义 ~/.autoglm 目录（默认 ~/.autoglm）
# AUTOGLM_HOME=$HOME/.autoglm
EOF
  chmod 600 "$env_file" || true
  succ "已创建: $env_file"
}

install_service_files() {
  local svc_dir="$PREFIX/var/service/autoglm-web"
  local run_script="$svc_dir/run"
  local log_dir="$svc_dir/log"
  local log_run="$log_dir/run"

  mkdir -p "$svc_dir" "$log_dir"

  cat > "$run_script" <<'EOF'
#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

export HOME="${HOME:-/data/data/com.termux/files/home}"
export PATH="$HOME/bin:$PATH"

ENV_FILE="$HOME/.autoglm/web_service.env"
if [[ -f "$ENV_FILE" ]]; then
  # shellcheck disable=SC1090
  source "$ENV_FILE"
fi

export AUTOGLM_WEB_HOST="${AUTOGLM_WEB_HOST:-0.0.0.0}"
export AUTOGLM_WEB_PORT="${AUTOGLM_WEB_PORT:-8000}"

# 如果用户安装了 Termux API，可选保持唤醒（不强制）
if command -v termux-wake-lock >/dev/null 2>&1; then
  termux-wake-lock >/dev/null 2>&1 || true
fi

exec autoglm-web run --host "$AUTOGLM_WEB_HOST" --port "$AUTOGLM_WEB_PORT"
EOF
  chmod +x "$run_script"

  cat > "$log_run" <<'EOF'
#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

export HOME="${HOME:-/data/data/com.termux/files/home}"
LOG_BASE="$HOME/.autoglm/web_service_logs"
mkdir -p "$LOG_BASE"

exec svlogd -tt "$LOG_BASE"
EOF
  chmod +x "$log_run"

  succ "已写入服务目录: $svc_dir"
}

enable_and_start() {
  if command -v sv-enable >/dev/null 2>&1; then
    sv-enable autoglm-web >/dev/null 2>&1 || true
  fi
  sv up autoglm-web >/dev/null 2>&1 || true
  sv status autoglm-web || true
}

install_cli_helper() {
  mkdir -p "$HOME/bin"
  cat > "$HOME/bin/autoglm-web-service" <<'EOF'
#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

usage() {
  cat <<USAGE
用法:
  autoglm-web-service install        # 安装并启用服务
  autoglm-web-service start          # 启动
  autoglm-web-service stop           # 停止
  autoglm-web-service restart        # 重启
  autoglm-web-service status         # 状态
  autoglm-web-service logs           # 查看日志目录
  autoglm-web-service tail           # tail -f 日志
  autoglm-web-service uninstall      # 移除服务（不卸载 Python 依赖）
USAGE
}

require_termux() {
  if [[ -z "${TERMUX_VERSION:-}" || -z "${PREFIX:-}" ]]; then
    echo "该命令仅用于 Termux" >&2
    exit 1
  fi
}

svc_dir() { echo "$PREFIX/var/service/autoglm-web"; }
log_dir() { echo "$HOME/.autoglm/web_service_logs"; }
installer_path() { echo "$HOME/.autoglm/install_web_service.sh"; }

cmd="${1:-}"
case "$cmd" in
  install)
    if [[ -f "$(installer_path)" ]]; then
      exec bash "$(installer_path)"
    fi
    echo "未找到安装脚本：$(installer_path)" >&2
    echo "请重新下载并执行 install_web_service.sh" >&2
    exit 1
    ;;
  start)
    require_termux
    sv up autoglm-web
    ;;
  stop)
    require_termux
    sv down autoglm-web
    ;;
  restart)
    require_termux
    sv restart autoglm-web
    ;;
  status)
    require_termux
    sv status autoglm-web
    ;;
  logs)
    echo "$(log_dir)"
    ;;
  tail)
    require_termux
    mkdir -p "$(log_dir)"
    tail -n 200 -f "$(log_dir)/current"
    ;;
  uninstall)
    require_termux
    sv down autoglm-web >/dev/null 2>&1 || true
    if command -v sv-disable >/dev/null 2>&1; then
      sv-disable autoglm-web >/dev/null 2>&1 || true
    fi
    rm -rf "$(svc_dir)"
    echo "已移除服务目录: $(svc_dir)"
    ;;
  ""|-h|--help|help)
    usage
    ;;
  *)
    echo "未知命令: $cmd" >&2
    usage
    exit 1
    ;;
esac
EOF
  chmod +x "$HOME/bin/autoglm-web-service"
  succ "已生成命令: ~/bin/autoglm-web-service"
}

main() {
  ensure_termux
  ensure_pkg

  if ! command -v autoglm-web >/dev/null 2>&1; then
    warn "未找到 autoglm-web，建议先执行 install_web.sh 安装 Web 端"
  fi

  ensure_termux_services
  mkdir -p "$HOME/.autoglm"
  cp -f "$0" "$HOME/.autoglm/install_web_service.sh" 2>/dev/null || true
  write_env_file
  install_service_files
  enable_and_start
  install_cli_helper

  echo
  succ "常驻服务已就绪"
  echo -e "查看 Token：${GREEN}autoglm-web token${NC}"
  echo -e "查看状态：${GREEN}sv status autoglm-web${NC}"
  echo -e "查看日志：${GREEN}autoglm-web-service tail${NC}"
}

main "$@"
