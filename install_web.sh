#!/usr/bin/env bash
set -euo pipefail

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; NC='\033[0m'

log() { echo -e "${BLUE}[INFO]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
err() { echo -e "${RED}[ERROR]${NC} $*"; }
succ() { echo -e "${GREEN}[OK]${NC} $*"; }

in_termux() { [[ -n "${TERMUX_VERSION:-}" ]]; }

ensure_cmd() {
  local cmd="$1" pkg="$2"
  if command -v "$cmd" >/dev/null 2>&1; then
    return 0
  fi
  if in_termux && command -v pkg >/dev/null 2>&1; then
    log "安装依赖: $pkg"
    pkg install -y "$pkg"
    return 0
  fi
  err "缺少命令: $cmd（请先安装 $pkg）"
  return 1
}

download_web_sources() {
  local dest_dir="$1"
  mkdir -p "$dest_dir"

  if [[ -d "./autoglm_web" ]]; then
    log "检测到当前目录包含 autoglm_web，直接复制"
    rm -rf "$dest_dir/autoglm_web"
    cp -R "./autoglm_web" "$dest_dir/"
    return 0
  fi

  ensure_cmd curl curl
  ensure_cmd tar tar

  local repo="${AUTOGLM_TERMUX_REPO_URL:-https://github.com/a251231/AutoGLM-TERMUX}"
  local branch="${AUTOGLM_TERMUX_BRANCH:-main}"
  local url="$repo/archive/refs/heads/$branch.tar.gz"

  log "下载 Web 源码: $url"
  local tmp
  tmp="$(mktemp -d 2>/dev/null || echo "/tmp/autoglm_web_$RANDOM")"
  mkdir -p "$tmp"
  curl -L "$url" -o "$tmp/src.tgz"
  tar -xzf "$tmp/src.tgz" -C "$tmp"

  local src_root
  src_root="$(find "$tmp" -maxdepth 1 -type d -name 'AutoGLM-TERMUX-*' | head -n 1 || true)"
  if [[ -z "$src_root" || ! -d "$src_root/autoglm_web" ]]; then
    err "下载/解压失败：未找到 autoglm_web 目录"
    return 1
  fi

  rm -rf "$dest_dir/autoglm_web"
  cp -R "$src_root/autoglm_web" "$dest_dir/"
  rm -rf "$tmp" || true
}

main() {
  log "开始安装 AutoGLM Web 管理端（可选组件）"

  if in_termux; then
    ensure_cmd python python
  else
    ensure_cmd python python3
  fi

  if ! python -m pip --version >/dev/null 2>&1; then
    if in_termux; then
      ensure_cmd pip python-pip
    else
      err "缺少 pip：请先安装 pip"
      exit 1
    fi
  fi

  log "安装 Python 依赖: fastapi uvicorn"
  python -m pip install --upgrade pip >/dev/null 2>&1 || true
  python -m pip install --upgrade fastapi uvicorn

  local install_dir="${AUTOGLM_WEB_INSTALL_DIR:-$HOME/.autoglm/webapp}"
  download_web_sources "$install_dir"

  mkdir -p "$HOME/bin"
  cat > "$HOME/bin/autoglm-web" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
export PYTHONPATH="$HOME/.autoglm/webapp:${PYTHONPATH:-}"
exec python -m autoglm_web "$@"
EOF
  chmod +x "$HOME/bin/autoglm-web"

  if ! grep -q 'export PATH=.*$HOME/bin' "$HOME/.bashrc" 2>/dev/null; then
    echo 'export PATH="$HOME/bin:$PATH"' >> "$HOME/.bashrc"
  fi

  succ "安装完成：已生成命令 ~/bin/autoglm-web"
  echo
  echo -e "查看 Token：${GREEN}autoglm-web token${NC}"
  echo -e "启动服务：${GREEN}autoglm-web run --host 0.0.0.0 --port 8000${NC}"
  echo -e "安装常驻服务（termux-services）：${GREEN}curl -O https://raw.githubusercontent.com/a251231/AutoGLM-TERMUX/refs/heads/main/install_web_service.sh && chmod +x install_web_service.sh && ./install_web_service.sh${NC}"
}

main "$@"
