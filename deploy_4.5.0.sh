#!/usr/bin/env bash
# Open-AutoGLM Termux 纯 ADB 方案 - 一键部署脚本
# 版本: 4.5.0 (增强 ADB 设备管理)
set -euo pipefail

##########  基础工具  ##########
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; PURPLE='\033[0;35m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'
log_info()  { echo -e "${BLUE}[INFO]${NC}  $*" >&2; }
log_succ()  { echo -e "${GREEN}[SUCC]${NC} $*" >&2; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $*" >&2; }
log_err()   { echo -e "${RED}[ERROR]${NC} $*" >&2; }

in_termux() { [[ -n "${TERMUX_VERSION:-}" ]]; }

pkg_install() {
  if in_termux; then
    pkg install -y "$@"
  else
    if command -v apt-get &>/dev/null; then
      sudo apt-get update -y && sudo apt-get install -y "$@"
    elif command -v yum &>/dev/null; then
      sudo yum install -y "$@"
    elif command -v pacman &>/dev/null; then
      sudo pacman -Sy --noconfirm "$@"
    elif command -v brew &>/dev/null; then
      brew install "$@" || true
    else
      log_err "未找到适配的包管理器，请手动安装：$*"
      exit 1
    fi
  fi
}

##########  镜像源配置  ##########
ask_mirror() {
  local tip="$1" default="$2" var="$3"
  read -rp "${tip}（直接回车跳过，输入 default 使用推荐源）: " input
  input="${input:-}"
  if [[ "$input" == "default" ]]; then
    input="$default"
  fi
  printf -v "$var" '%s' "$input"
}

setup_pip_mirror() {
  local url="$1"
  if [[ -z "$url" ]]; then
    log_info "跳过 pip 镜像配置"
    return 0
  fi
  log_info "设置 pip 镜像：$url"
  local host
  host=$(echo "$url" | sed -E 's|https?://([^/]+).*|\1|')
  pip config set global.index-url "$url" 2>/dev/null || true
  pip config set install.trusted-host "$host" 2>/dev/null || true
}

setup_cargo_mirror() {
  local url="$1"
  if [[ -z "$url" ]]; then
    log_info "跳过 Cargo 镜像配置"
    return 0
  fi
  log_info "设置 Cargo 镜像：$url"
  mkdir -p ~/.cargo
  rm -f ~/.cargo/config ~/.cargo/config.toml
  cat > ~/.cargo/config.toml <<EOF
[source.crates-io]
replace-with = 'my'

[source.my]
registry = "$url"

[net]
git-fetch-with-cli = true
EOF
}

##########  依赖安装  ##########
ensure_python() {
  if command -v python &>/dev/null; then
    log_succ "Python 已存在：$(python --version)"
  else
    log_info "安装 Python..."
    pkg_install python
  fi
}

ensure_pip() {
  if python -m pip --version &>/dev/null; then
    log_succ "pip 已存在"
  else
    log_info "安装 python-pip..."
    pkg_install python-pip
  fi
}

ensure_git() {
  if command -v git &>/dev/null; then
    log_succ "Git 已存在：$(git --version)"
  else
    log_info "安装 Git..."
    pkg_install git
  fi
}

ensure_rust() {
  if command -v rustc &>/dev/null; then
    log_succ "Rust 已存在：$(rustc --version)"
  else
    log_info "安装 Rust 编译工具链..."
    pkg_install rust binutils
  fi
}

ensure_adb() {
  if command -v adb &>/dev/null; then
    log_succ "ADB 已存在：$(adb version | head -1)"
    return 0
  fi
  
  log_info "安装 ADB..."
  if in_termux; then
    pkg_install android-tools
  elif command -v apt-get &>/dev/null; then
    sudo apt-get update -y && sudo apt-get install -y adb
  elif command -v yum &>/dev/null; then
    sudo yum install -y android-tools
  elif command -v pacman &>/dev/null; then
    sudo pacman -Sy --noconfirm android-tools
  elif command -v brew &>/dev/null; then
    brew install android-platform-tools
  else
    log_warn "请手动安装 ADB 工具"
    return 1
  fi
}

ensure_setuptools() {
  log_info "确保 setuptools 已安装..."
  python -m pip install --upgrade setuptools wheel 2>/dev/null || true
}

##########  ADB 设备计数（修复算术错误）  ##########
get_adb_device_count() {
  local count
  # 匹配 device 状态（不是 offline/unauthorized 等）
  count=$(adb devices 2>/dev/null | awk 'NR>1 && $2=="device" {count++} END {print count+0}')
  echo "${count:-0}" | tr -d '[:space:]'
}

##########  ADB Keyboard 提醒 ##########
remind_adb_keyboard() {
  echo
  echo -e "${YELLOW}╔══════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${YELLOW}║${NC}          ${BOLD}${RED}重要提醒：安装 ADB Keyboard${NC}                        ${YELLOW}║${NC}"
  echo -e "${YELLOW}╚══════════════════════════════════════════════════════════════╝${NC}"
  echo
  echo -e "${CYAN}此工具用于文本输入，必须安装！${NC}"
  echo
  echo -e "${BLUE}下载地址:${NC}"
  echo -e "  ${GREEN}https://github.com/senzhk/ADBKeyBoard/blob/master/ADBKeyboard.apk${NC}"
  echo
  echo -e "${BLUE}安装步骤:${NC}"
  echo -e "  ${GREEN}1.${NC} 下载并安装 ADBKeyboard.apk 到安卓设备"
  echo -e "  ${GREEN}2.${NC} 进入 设置 → 系统 → 语言和输入法 → 虚拟键盘 → 管理键盘"
  echo -e "  ${GREEN}3.${NC} 启用 'ADB Keyboard' 即可（可暂不切换）"
  echo -e "  ${GREEN}4.${NC} 使用原输入法继续下面的配置"
  echo
  read -rp "已了解，按回车继续... "
}

##########  ADB 无线调试配置向导  ##########
configure_adb_wireless() {
  echo
  echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${CYAN}║${NC}              ${BOLD}ADB 无线调试配置向导${NC}                            ${CYAN}║${NC}"
  echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
  echo
  echo -e "${BLUE}请按以下步骤操作:${NC}"
  echo -e "  ${GREEN}1.${NC} 确保手机和 Termux 设备在同一 WiFi 网络下"
  echo -e "  ${GREEN}2.${NC} 进入 设置 → 关于手机 → 连续点击版本号 7 次（开启开发者模式）"
  echo -e "  ${GREEN}3.${NC} 返回 设置 → 系统 → 开发者选项"
  echo -e "  ${GREEN}4.${NC} 开启 '无线调试'"
  echo -e "  ${GREEN}5.${NC} ${YELLOW}建议:${NC} 将无线调试界面和 Termux 分屏显示"
  echo
  
  echo -e "${YELLOW}━━━ 第一步：配对设备 ━━━${NC}"
  echo -e "${CYAN}点击无线调试界面中的「使用配对码配对」${NC}"
  echo
  read -rp "  输入配对码弹窗显示的 IP:端口: " pair_host
  if [[ -z "$pair_host" ]]; then
    log_err "IP:端口不能为空！"
    return 1
  fi
  
  read -rp "  输入配对码（6 位数字）: " pair_code
  if [[ -z "$pair_code" ]]; then
    log_err "配对码不能为空！"
    return 1
  fi
  
  log_info "正在配对 $pair_host ..."
  if adb pair "$pair_host" "$pair_code" 2>&1; then
    log_succ "配对成功！"
  else
    log_err "配对失败，请检查输入是否正确！"
    return 1
  fi
  
  echo
  echo -e "${YELLOW}━━━ 第二步：连接设备 ━━━${NC}"
  echo -e "${CYAN}查看无线调试主界面（不是配对码弹窗）显示的 IP 地址和端口${NC}"
  echo
  read -rp "  输入无线调试界面的 IP:端口: " connect_host
  if [[ -z "$connect_host" ]]; then
    log_err "IP:端口不能为空！"
    return 1
  fi
  
  log_info "正在连接 $connect_host ..."
  if adb connect "$connect_host" 2>&1; then
    sleep 1
    local count
    count=$(get_adb_device_count)
    if [[ "$count" -gt 0 ]]; then
      log_succ "连接成功！设备已就绪！"
      echo
      adb devices
      return 0
    else
      log_err "设备未正确连接，请重试！"
      return 1
    fi
  else
    log_err "连接失败，请检查 IP:端口 和网络连接！"
    return 1
  fi
}

check_adb_configured() {
  local count
  count=$(get_adb_device_count)
  [[ "$count" -gt 0 ]]
}

show_adb_devices() {
  echo
  log_info "当前 ADB 设备列表:"
  adb devices -l 2>/dev/null || echo "  (无法获取设备列表)"
  echo
}

##########  Python 依赖  ##########
install_py_deps() {
  log_info "安装/升级核心 Python 包..."
  ensure_setuptools

  if in_termux; then
    pkg_install python-pillow
  else
    python -m pip install --upgrade pillow
  fi

  echo
  echo -e "${YELLOW}╔══════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${YELLOW}║${NC}  ${BOLD}正在安装 openai 模块，请耐心等待...${NC}                       ${YELLOW}║${NC}"
  echo -e "${YELLOW}║${NC}  ${CYAN}openai 的部分依赖需要 Rust 编译，可能耗时较长（5-15分钟）${NC}  ${YELLOW}║${NC}"
  echo -e "${YELLOW}╚══════════════════════════════════════════════════════════════╝${NC}"
  echo

  python -m pip install --upgrade maturin openai requests
}

##########  项目拉取/更新  ##########
clone_or_update() {
  local dir="$HOME/Open-AutoGLM"
  if [[ -d $dir/.git ]]; then
    log_warn "检测到本地已存在 Open-AutoGLM 目录"
    read -rp "是否更新代码？（y/N）: " ans
    case "${ans:-n}" in
      [Yy]*)
        log_info "正在更新代码..."
        git -C "$dir" pull --ff-only || log_warn "更新失败，使用本地代码"
        ;;
      *)
        log_info "跳过更新，使用本地代码"
        ;;
    esac
  else
    log_info "克隆仓库..."
    rm -rf "$dir"
    git clone https://github.com/zai-org/Open-AutoGLM.git "$dir"
  fi

  in_termux && sed -i '/[Pp]illow/d' "$dir/requirements.txt" 2>/dev/null || true
  
  log_info "安装项目依赖..."
  python -m pip install -r "$dir/requirements.txt"
  
  log_info "安装项目本体..."
  python -m pip install -e "$dir"
}

##########  交互式配置  ##########
configure_env() {
  mkdir -p ~/.autoglm

  local DEFAULT_BASE_URL="https://open.bigmodel.cn/api/paas/v4"
  local DEFAULT_MODEL="autoglm-phone"
  local DEFAULT_API_KEY="sk-your-apikey"
  local DEFAULT_MAX_STEPS="100"
  local DEFAULT_DEVICE_ID=""
  local DEFAULT_LANG="cn"

  echo
  echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${CYAN}║${NC}              ${BOLD}配置 Open-AutoGLM 参数${NC}                          ${CYAN}║${NC}"
  echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
  echo
  echo -e "${YELLOW}直接回车使用 [默认值]${NC}"
  echo

  read -rp "  AI 接口 Base URL [${DEFAULT_BASE_URL}]: " base_url
  base_url=${base_url:-$DEFAULT_BASE_URL}

  read -rp "  AI 模型名称 [${DEFAULT_MODEL}]: " model
  model=${model:-$DEFAULT_MODEL}

  read -rp "  AI API Key [${DEFAULT_API_KEY}]: " api_key
  api_key=${api_key:-$DEFAULT_API_KEY}

  read -rp "  每任务最大步数 [${DEFAULT_MAX_STEPS}]: " max_steps
  max_steps=${max_steps:-$DEFAULT_MAX_STEPS}

  read -rp "  ADB 设备 ID（单设备留空自动检测）[]: " device_id
  device_id=${device_id:-$DEFAULT_DEVICE_ID}

  read -rp "  语言 cn/en [${DEFAULT_LANG}]: " lang
  lang=${lang:-$DEFAULT_LANG}

  cat > ~/.autoglm/config.sh <<EOF
#!/bin/bash
# AutoGLM 配置文件 - 自动生成于 $(date)
export PHONE_AGENT_BASE_URL="$base_url"
export PHONE_AGENT_MODEL="$model"
export PHONE_AGENT_API_KEY="$api_key"
export PHONE_AGENT_MAX_STEPS="$max_steps"
export PHONE_AGENT_DEVICE_ID="$device_id"
export PHONE_AGENT_LANG="$lang"
EOF

  chmod +x ~/.autoglm/config.sh
  grep -q 'source ~/.autoglm/config.sh' ~/.bashrc 2>/dev/null || echo 'source ~/.autoglm/config.sh' >> ~/.bashrc
  
  log_succ "配置已保存到 ~/.autoglm/config.sh"
}

##########  创建启动器脚本  ##########
make_launcher() {
  mkdir -p ~/bin
  
  cat > ~/bin/autoglm <<'LAUNCHER_EOF'
#!/bin/bash
# AutoGLM 智能启动面板
# 版本: 4.5.0

##########  颜色定义  ##########
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

##########  配置文件  ##########
CONFIG_FILE="$HOME/.autoglm/config.sh"
AUTOGLM_DIR="$HOME/Open-AutoGLM"

##########  加载配置  ##########
load_config() {
  if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
  else
    export PHONE_AGENT_BASE_URL="https://open.bigmodel.cn/api/paas/v4"
    export PHONE_AGENT_MODEL="autoglm-phone"
    export PHONE_AGENT_API_KEY="sk-your-apikey"
    export PHONE_AGENT_MAX_STEPS="100"
    export PHONE_AGENT_DEVICE_ID=""
    export PHONE_AGENT_LANG="cn"
  fi
}

##########  保存配置  ##########
save_config() {
  mkdir -p ~/.autoglm
  cat > "$CONFIG_FILE" <<EOF
#!/bin/bash
# AutoGLM 配置文件 - 自动生成于 $(date)
export PHONE_AGENT_BASE_URL="$PHONE_AGENT_BASE_URL"
export PHONE_AGENT_MODEL="$PHONE_AGENT_MODEL"
export PHONE_AGENT_API_KEY="$PHONE_AGENT_API_KEY"
export PHONE_AGENT_MAX_STEPS="$PHONE_AGENT_MAX_STEPS"
export PHONE_AGENT_DEVICE_ID="$PHONE_AGENT_DEVICE_ID"
export PHONE_AGENT_LANG="$PHONE_AGENT_LANG"
EOF
  chmod +x "$CONFIG_FILE"
}

##########  清屏并显示标题  ##########
show_header() {
  clear
  echo -e "${PURPLE}╔══════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${PURPLE}║${NC}      ${BOLD}${CYAN}🤖 AutoGLM 智能启动面板${NC}                               ${PURPLE}║${NC}"
  echo -e "${PURPLE}║${NC}      ${GREEN}Open-AutoGLM Phone Agent Controller${NC}                    ${PURPLE}║${NC}"
  echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════╝${NC}"
  echo
}

##########  显示当前配置  ##########
show_current_config() {
  echo -e "${CYAN}━━━ 当前配置 ━━━${NC}"
  echo -e "  ${BLUE}API 地址${NC}   : ${GREEN}$PHONE_AGENT_BASE_URL${NC}"
  echo -e "  ${BLUE}模型名称${NC}   : ${GREEN}$PHONE_AGENT_MODEL${NC}"
  echo -e "  ${BLUE}API Key${NC}    : ${GREEN}${PHONE_AGENT_API_KEY:0:12}...${NC}"
  echo -e "  ${BLUE}最大步数${NC}   : ${GREEN}$PHONE_AGENT_MAX_STEPS${NC}"
  echo -e "  ${BLUE}设备 ID${NC}    : ${GREEN}${PHONE_AGENT_DEVICE_ID:-自动检测}${NC}"
  echo -e "  ${BLUE}语言${NC}       : ${GREEN}$PHONE_AGENT_LANG${NC}"
  echo
}

##########  获取在线设备数量  ##########
get_adb_device_count() {
  local count
  count=$(adb devices 2>/dev/null | awk 'NR>1 && $2=="device" {count++} END {print count+0}')
  echo "${count:-0}" | tr -d '[:space:]'
}

##########  获取所有设备数量（包括 offline）  ##########
get_adb_all_device_count() {
  local count
  count=$(adb devices 2>/dev/null | awk 'NR>1 && NF>=2 && $1!="" {count++} END {print count+0}')
  echo "${count:-0}" | tr -d '[:space:]'
}

##########  解析设备信息  ##########
# 返回格式: serial|status|model|type
parse_device_info() {
  local line="$1"
  local serial status model device_type
  
  serial=$(echo "$line" | awk '{print $1}')
  status=$(echo "$line" | awk '{print $2}')
  
  # 提取 model
  model=$(echo "$line" | grep -oP 'model:\K[^ ]+' || echo "未知型号")
  
  # 判断连接类型
  if [[ "$serial" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:[0-9]+$ ]]; then
    device_type="无线"
  else
    device_type="USB"
  fi
  
  echo "${serial}|${status}|${model}|${device_type}"
}

##########  获取状态显示文字  ##########
get_status_display() {
  local status="$1"
  case "$status" in
    device)
      echo -e "${GREEN}在线${NC}"
      ;;
    offline)
      echo -e "${RED}离线${NC}"
      ;;
    unauthorized)
      echo -e "${YELLOW}未授权${NC}"
      ;;
    *)
      echo -e "${YELLOW}${status}${NC}"
      ;;
  esac
}

show_adb_status() {
  local online_count all_count
  online_count=$(get_adb_device_count)
  all_count=$(get_adb_all_device_count)
  
  if [[ "$online_count" -gt 0 ]]; then
    if [[ "$all_count" -gt "$online_count" ]]; then
      echo -e "${GREEN}━━━ ADB 状态: ✓ ${online_count} 台在线${NC} ${YELLOW}/ ${all_count} 台总计 ━━━${NC}"
    else
      echo -e "${GREEN}━━━ ADB 状态: ✓ 已连接 ${online_count} 台设备 ━━━${NC}"
    fi
  elif [[ "$all_count" -gt 0 ]]; then
    echo -e "${YELLOW}━━━ ADB 状态: ⚠ ${all_count} 台设备（均离线/未授权）━━━${NC}"
  else
    echo -e "${RED}━━━ ADB 状态: ✗ 未检测到设备 ━━━${NC}"
  fi
  echo
}

##########  显示主菜单  ##########
show_main_menu() {
  show_header
  show_adb_status
  show_current_config
  
  echo -e "${YELLOW}━━━ 主菜单 ━━━${NC}"
  echo
  echo -e "  ${GREEN}1.${NC} 🚀 使用当前配置启动"
  echo -e "  ${GREEN}2.${NC} 📱 ADB 设备管理"
  echo -e "  ${GREEN}3.${NC} ⚙️  修改 AI 配置"
  echo -e "  ${GREEN}4.${NC} 📋 查看支持的应用列表"
  echo -e "  ${GREEN}5.${NC} 🔍 查看详细配置"
  echo -e "  ${GREEN}6.${NC} 🗑️  一键卸载"
  echo -e "  ${GREEN}0.${NC} ❌ 退出"
  echo
}

##########  ADB Keyboard 提醒  ##########
remind_adb_keyboard() {
  show_header
  echo -e "${YELLOW}╔══════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${YELLOW}║${NC}          ${BOLD}${RED}⚠️  重要提醒：安装 ADB Keyboard${NC}                     ${YELLOW}║${NC}"
  echo -e "${YELLOW}╚══════════════════════════════════════════════════════════════╝${NC}"
  echo
  echo -e "${CYAN}此工具用于文本输入，必须安装！${NC}"
  echo
  echo -e "${BLUE}下载地址:${NC}"
  echo -e "  ${GREEN}https://github.com/senzhk/ADBKeyBoard/blob/master/ADBKeyboard.apk${NC}"
  echo
  echo -e "${BLUE}安装步骤:${NC}"
  echo -e "  ${GREEN}1.${NC} 下载并安装 ADBKeyboard.apk 到安卓设备"
  echo -e "  ${GREEN}2.${NC} 进入 ${YELLOW}设置 → 系统 → 语言和输入法 → 虚拟键盘 → 管理键盘${NC}"
  echo -e "  ${GREEN}3.${NC} 开启 ${YELLOW}'ADB Keyboard'${NC}"
  echo -e "  ${GREEN}4.${NC} 运行时需切换到 ADB Keyboard 输入法"
  echo
  read -rp "已了解，按回车继续... "
}

##########  配置 ADB 无线调试  ##########
configure_adb_wireless() {
  show_header
  echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${CYAN}║${NC}              ${BOLD}📱 ADB 无线调试配置向导${NC}                         ${CYAN}║${NC}"
  echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
  echo
  echo -e "${BLUE}请按以下步骤操作:${NC}"
  echo -e "  ${GREEN}1.${NC} 确保手机和 Termux 设备在同一 WiFi 网络下"
  echo -e "  ${GREEN}2.${NC} 进入 ${YELLOW}设置 → 关于手机 → 连续点击版本号 7 次${NC}（开启开发者模式）"
  echo -e "  ${GREEN}3.${NC} 返回 ${YELLOW}设置 → 系统 → 开发者选项${NC}"
  echo -e "  ${GREEN}4.${NC} 开启 ${YELLOW}'无线调试'${NC}"
  echo -e "  ${GREEN}5.${NC} ${CYAN}建议:${NC} 将无线调试界面和 Termux 分屏显示"
  echo
  
  echo -e "${YELLOW}━━━ 第一步：配对设备 ━━━${NC}"
  echo -e "${CYAN}点击无线调试界面中的「使用配对码配对」${NC}"
  echo
  read -rp "  输入配对码弹窗显示的 IP:端口（如 192.168.1.13:42379）: " pair_host
  if [[ -z "$pair_host" ]]; then
    echo -e "${RED}[ERROR] IP:端口不能为空！${NC}"
    read -rp "按回车返回... "
    return 1
  fi
  
  read -rp "  输入配对码（6 位数字）: " pair_code
  if [[ -z "$pair_code" ]]; then
    echo -e "${RED}[ERROR] 配对码不能为空！${NC}"
    read -rp "按回车返回... "
    return 1
  fi
  
  echo -e "${BLUE}[INFO]${NC} 正在配对 $pair_host ..."
  if adb pair "$pair_host" "$pair_code" 2>&1; then
    echo -e "${GREEN}[SUCC]${NC} 配对成功！"
  else
    echo -e "${RED}[ERROR]${NC} 配对失败，请检查输入！"
    read -rp "按回车返回... "
    return 1
  fi
  
  echo
  echo -e "${YELLOW}━━━ 第二步：连接设备 ━━━${NC}"
  echo -e "${CYAN}查看无线调试主界面（不是配对码弹窗）显示的 IP 地址和端口${NC}"
  echo
  read -rp "  输入无线调试界面的 IP:端口（如 192.168.1.13:5555）: " connect_host
  if [[ -z "$connect_host" ]]; then
    echo -e "${RED}[ERROR] IP:端口不能为空！${NC}"
    read -rp "按回车返回... "
    return 1
  fi
  
  echo -e "${BLUE}[INFO]${NC} 正在连接 $connect_host ..."
  if adb connect "$connect_host" 2>&1; then
    sleep 1
    local count
    count=$(get_adb_device_count)
    if [[ "$count" -gt 0 ]]; then
      echo
      echo -e "${GREEN}[SUCC]${NC} 连接成功！设备已就绪！"
      echo
      adb devices -l
      echo
      read -rp "按回车返回... "
      return 0
    fi
  fi
  
  echo -e "${RED}[ERROR]${NC} 连接失败，请检查 IP:端口 和网络！"
  read -rp "按回车返回... "
  return 1
}

##########  显示设备详细列表  ##########
show_device_list() {
  show_header
  echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${CYAN}║${NC}              ${BOLD}📋 ADB 设备详细列表${NC}                              ${CYAN}║${NC}"
  echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
  echo
  
  local all_count
  all_count=$(get_adb_all_device_count)
  
  if [[ "$all_count" -eq 0 ]]; then
    echo -e "${YELLOW}未检测到任何设备${NC}"
    echo
    read -rp "按回车返回... "
    return
  fi
  
  echo -e "${BLUE}设备列表：${NC}"
  echo -e "┌────┬────────────────────────┬──────────┬────────────────┬────────┐"
  printf "│ %-2s │ %-22s │ %-8s │ %-14s │ %-6s │\n" "序" "设备地址" "状态" "型号" "类型"
  echo -e "├────┼────────────────────────┼──────────┼────────────────┼────────┤"
  
  local i=1
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    local info serial status model dtype status_display
    info=$(parse_device_info "$line")
    IFS='|' read -r serial status model dtype <<< "$info"
    status_display=$(get_status_display "$status")
    
    # 截断过长的字段
    [[ ${#serial} -gt 22 ]] && serial="${serial:0:19}..."
    [[ ${#model} -gt 14 ]] && model="${model:0:11}..."
    
    # 标记当前选中的设备
    local marker=""
    if [[ "$serial" == "${PHONE_AGENT_DEVICE_ID:-}" ]]; then
      marker="${GREEN}*${NC}"
    fi
    
    printf "│ ${GREEN}%-2s${NC} │ %-22s │ %b │ %-14s │ %-6s │%b\n" "$i" "$serial" "$status_display" "$model" "$dtype" "$marker"
    ((i++))
  done < <(adb devices -l 2>/dev/null | awk 'NR>1 && NF>=2 && $1!=""')
  
  echo -e "└────┴────────────────────────┴──────────┴────────────────┴────────┘"
  
  if [[ -n "${PHONE_AGENT_DEVICE_ID:-}" ]]; then
    echo -e "\n${GREEN}*${NC} 表示当前选中的设备"
  fi
  echo
  read -rp "按回车返回... "
}

##########  切换 ADB 设备  ##########
switch_adb_device() {
  show_header
  echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${CYAN}║${NC}              ${BOLD}🔄 切换 ADB 设备${NC}                                 ${CYAN}║${NC}"
  echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
  echo
  
  local all_count
  all_count=$(get_adb_all_device_count)
  
  if [[ "$all_count" -eq 0 ]]; then
    echo -e "${RED}[ERROR]${NC} 未检测到任何 ADB 设备！"
    echo -e "${YELLOW}请先配置 ADB 无线调试连接设备${NC}"
    echo
    read -rp "按回车返回... "
    return 1
  fi
  
  echo -e "${BLUE}可选设备：${NC}"
  echo -e "${CYAN}────────────────────────────────────────────────────────────────${NC}"
  
  # 收集设备信息
  local devices=()
  local statuses=()
  local models=()
  local dtypes=()
  local i=1
  
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    local info serial status model dtype status_display
    info=$(parse_device_info "$line")
    IFS='|' read -r serial status model dtype <<< "$info"
    status_display=$(get_status_display "$status")
    
    devices+=("$serial")
    statuses+=("$status")
    models+=("$model")
    dtypes+=("$dtype")
    
    local marker=""
    if [[ "$serial" == "${PHONE_AGENT_DEVICE_ID:-}" ]]; then
      marker=" ${GREEN}[当前]${NC}"
    fi
    
    echo -e "  ${GREEN}$i.${NC} $serial - ${CYAN}$model${NC} ($dtype) [${status_display}]${marker}"
    ((i++))
  done < <(adb devices -l 2>/dev/null | awk 'NR>1 && NF>=2 && $1!=""')
  
  echo -e "${CYAN}────────────────────────────────────────────────────────────────${NC}"
  echo
  echo -e "  ${GREEN}0.${NC} 留空（自动检测，适用于单设备）"
  echo -e "  ${GREEN}c.${NC} 取消返回"
  echo
  
  read -rp "请选择要使用的设备 [1-$((i-1))/0/c]: " choice
  
  case "$choice" in
    c|C)
      return 0
      ;;
    0)
      PHONE_AGENT_DEVICE_ID=""
      save_config
      echo -e "${GREEN}[SUCC]${NC} 已设置为自动检测模式"
      read -rp "按回车继续... "
      ;;
    *)
      if [[ "$choice" =~ ^[0-9]+$ ]] && [[ "$choice" -ge 1 ]] && [[ "$choice" -le "${#devices[@]}" ]]; then
        local idx=$((choice-1))
        local selected_device="${devices[$idx]}"
        local selected_status="${statuses[$idx]}"
        
        if [[ "$selected_status" != "device" ]]; then
          echo -e "${YELLOW}[WARN]${NC} 该设备当前状态为 ${selected_status}，可能无法正常使用"
          read -rp "是否仍要选择？(y/N): " confirm
          if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            return 0
          fi
        fi
        
        PHONE_AGENT_DEVICE_ID="$selected_device"
        save_config
        echo -e "${GREEN}[SUCC]${NC} 已切换到设备: ${CYAN}$PHONE_AGENT_DEVICE_ID${NC}"
        read -rp "按回车继续... "
      else
        echo -e "${RED}无效选择${NC}"
        read -rp "按回车继续... "
      fi
      ;;
  esac
}

##########  断开指定设备  ##########
disconnect_device() {
  show_header
  echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${CYAN}║${NC}              ${BOLD}🔌 断开 ADB 设备${NC}                                 ${CYAN}║${NC}"
  echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
  echo
  
  local all_count
  all_count=$(get_adb_all_device_count)
  
  if [[ "$all_count" -eq 0 ]]; then
    echo -e "${YELLOW}当前没有已连接的设备${NC}"
    echo
    read -rp "按回车返回... "
    return
  fi
  
  echo -e "${BLUE}已连接的设备：${NC}"
  echo -e "${CYAN}────────────────────────────────────────────────────────────────${NC}"
  
  local devices=()
  local dtypes=()
  local i=1
  
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    local info serial status model dtype status_display
    info=$(parse_device_info "$line")
    IFS='|' read -r serial status model dtype <<< "$info"
    status_display=$(get_status_display "$status")
    
    devices+=("$serial")
    dtypes+=("$dtype")
    
    echo -e "  ${GREEN}$i.${NC} $serial - ${CYAN}$model${NC} ($dtype) [${status_display}]"
    ((i++))
  done < <(adb devices -l 2>/dev/null | awk 'NR>1 && NF>=2 && $1!=""')
  
  echo -e "${CYAN}────────────────────────────────────────────────────────────────${NC}"
  echo
  echo -e "  ${GREEN}a.${NC} 断开所有无线设备"
  echo -e "  ${GREEN}r.${NC} 重启 ADB 服务（断开所有设备）"
  echo -e "  ${GREEN}c.${NC} 取消返回"
  echo
  
  read -rp "请选择要断开的设备 [1-$((i-1))/a/r/c]: " choice
  
  case "$choice" in
    c|C)
      return 0
      ;;
    a|A)
      echo -e "${BLUE}[INFO]${NC} 断开所有无线设备..."
      adb disconnect 2>/dev/null || true
      echo -e "${GREEN}[SUCC]${NC} 已断开所有无线设备"
      sleep 1
      adb devices
      read -rp "按回车继续... "
      ;;
    r|R)
      echo -e "${YELLOW}[WARN]${NC} 重启 ADB 服务将断开所有设备（包括 USB）"
      read -rp "确认重启？(y/N): " confirm
      if [[ "$confirm" =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}[INFO]${NC} 正在重启 ADB 服务..."
        adb kill-server 2>/dev/null || true
        sleep 1
        adb start-server 2>/dev/null || true
        echo -e "${GREEN}[SUCC]${NC} ADB 服务已重启"
        sleep 1
        adb devices
      fi
      read -rp "按回车继续... "
      ;;
    *)
      if [[ "$choice" =~ ^[0-9]+$ ]] && [[ "$choice" -ge 1 ]] && [[ "$choice" -le "${#devices[@]}" ]]; then
        local idx=$((choice-1))
        local selected_device="${devices[$idx]}"
        local selected_type="${dtypes[$idx]}"
        
        if [[ "$selected_type" == "无线" ]]; then
          echo -e "${BLUE}[INFO]${NC} 断开无线设备: $selected_device"
          adb disconnect "$selected_device" 2>&1
          echo -e "${GREEN}[SUCC]${NC} 已断开: $selected_device"
          
          # 如果断开的是当前选中的设备，清空配置
          if [[ "$selected_device" == "${PHONE_AGENT_DEVICE_ID:-}" ]]; then
            PHONE_AGENT_DEVICE_ID=""
            save_config
            echo -e "${YELLOW}[INFO]${NC} 已清除当前设备选择"
          fi
        else
          echo -e "${YELLOW}[WARN]${NC} USB 设备无法通过软件断开"
          echo -e "${CYAN}请物理拔除 USB 线缆，或选择 'r' 重启 ADB 服务${NC}"
        fi
        read -rp "按回车继续... "
      else
        echo -e "${RED}无效选择${NC}"
        read -rp "按回车继续... "
      fi
      ;;
  esac
}

##########  快速连接设备  ##########
quick_connect() {
  show_header
  echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${CYAN}║${NC}              ${BOLD}⚡ 快速连接${NC}                                     ${CYAN}║${NC}"
  echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
  echo
  echo -e "${YELLOW}适用于已配对过的设备${NC}"
  echo
  read -rp "输入设备 IP:端口（如 192.168.1.13:5555）: " connect_host
  
  if [[ -z "$connect_host" ]]; then
    echo -e "${RED}[ERROR]${NC} IP:端口不能为空"
    read -rp "按回车返回... "
    return 1
  fi
  
  echo -e "${BLUE}[INFO]${NC} 正在连接 $connect_host ..."
  if adb connect "$connect_host" 2>&1; then
    sleep 1
    local count
    count=$(get_adb_device_count)
    if [[ "$count" -gt 0 ]]; then
      echo -e "${GREEN}[SUCC]${NC} 连接成功！"
      echo
      adb devices -l
    else
      echo -e "${YELLOW}[WARN]${NC} 连接可能未完全成功，请检查设备状态"
      adb devices -l
    fi
  else
    echo -e "${RED}[ERROR]${NC} 连接失败"
  fi
  echo
  read -rp "按回车继续... "
}

##########  ADB 设备管理菜单  ##########
adb_menu() {
  while true; do
    show_header
    show_adb_status
    
    # 显示当前选中的设备
    if [[ -n "${PHONE_AGENT_DEVICE_ID:-}" ]]; then
      echo -e "${BLUE}当前选中设备:${NC} ${GREEN}$PHONE_AGENT_DEVICE_ID${NC}"
      echo
    fi
    
    echo -e "${YELLOW}━━━ ADB 设备管理 ━━━${NC}"
    echo
    echo -e "  ${GREEN}1.${NC} 📱 配对新设备（配对+连接）"
    echo -e "  ${GREEN}2.${NC} ⚡ 快速连接（已配对过）"
    echo -e "  ${GREEN}3.${NC} 📋 查看设备详细列表"
    echo -e "  ${GREEN}4.${NC} 🔄 切换活动设备"
    echo -e "  ${GREEN}5.${NC} 🔌 断开设备连接"
    echo -e "  ${GREEN}6.${NC} ❓ ADB Keyboard 安装说明"
    echo -e "  ${GREEN}0.${NC} ↩️  返回主菜单"
    echo
    read -rp "请选择 [0-6]: " choice
    
    case "$choice" in
      1)
        configure_adb_wireless
        ;;
      2)
        quick_connect
        ;;
      3)
        show_device_list
        ;;
      4)
        switch_adb_device
        ;;
      5)
        disconnect_device
        ;;
      6)
        remind_adb_keyboard
        ;;
      0)
        return
        ;;
      *)
        echo -e "${RED}无效选择${NC}"
        sleep 1
        ;;
    esac
  done
}

##########  修改 AI 配置  ##########
modify_config() {
  show_header
  echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${CYAN}║${NC}              ${BOLD}⚙️  修改 AI 配置${NC}                                  ${CYAN}║${NC}"
  echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
  echo
  echo -e "${YELLOW}直接回车保持当前值不变${NC}"
  echo
  
  local new_val
  
  read -rp "  API 地址 [$PHONE_AGENT_BASE_URL]: " new_val
  [[ -n "$new_val" ]] && PHONE_AGENT_BASE_URL="$new_val"
  
  read -rp "  模型名称 [$PHONE_AGENT_MODEL]: " new_val
  [[ -n "$new_val" ]] && PHONE_AGENT_MODEL="$new_val"
  
  read -rp "  API Key [$PHONE_AGENT_API_KEY]: " new_val
  [[ -n "$new_val" ]] && PHONE_AGENT_API_KEY="$new_val"
  
  read -rp "  最大步数 [$PHONE_AGENT_MAX_STEPS]: " new_val
  [[ -n "$new_val" ]] && PHONE_AGENT_MAX_STEPS="$new_val"
  
  read -rp "  设备 ID [${PHONE_AGENT_DEVICE_ID:-留空自动检测}]: " new_val
  PHONE_AGENT_DEVICE_ID="$new_val"
  
  read -rp "  语言 cn/en [$PHONE_AGENT_LANG]: " new_val
  [[ -n "$new_val" ]] && PHONE_AGENT_LANG="$new_val"
  
  save_config
  
  echo
  echo -e "${GREEN}[SUCC]${NC} 配置已保存并生效！"
  read -rp "按回车返回主菜单... "
}

##########  查看详细配置  ##########
view_config() {
  show_header
  echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${CYAN}║${NC}              ${BOLD}🔍 详细配置信息${NC}                                 ${CYAN}║${NC}"
  echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
  echo
  echo -e "${BLUE}环境变量配置:${NC}"
  echo -e "┌────────────────────────┬────────────────────────────────────┐"
  printf "│ %-22s │ %-34s │\n" "变量名" "值"
  echo -e "├────────────────────────┼────────────────────────────────────┤"
  printf "│ %-22s │ %-34s │\n" "PHONE_AGENT_BASE_URL" "$PHONE_AGENT_BASE_URL"
  printf "│ %-22s │ %-34s │\n" "PHONE_AGENT_MODEL" "$PHONE_AGENT_MODEL"
  printf "│ %-22s │ %-34s │\n" "PHONE_AGENT_API_KEY" "${PHONE_AGENT_API_KEY:0:20}..."
  printf "│ %-22s │ %-34s │\n" "PHONE_AGENT_MAX_STEPS" "$PHONE_AGENT_MAX_STEPS"
  printf "│ %-22s │ %-34s │\n" "PHONE_AGENT_DEVICE_ID" "${PHONE_AGENT_DEVICE_ID:-自动检测}"
  printf "│ %-22s │ %-34s │\n" "PHONE_AGENT_LANG" "$PHONE_AGENT_LANG"
  echo -e "└────────────────────────┴────────────────────────────────────┘"
  echo
  echo -e "${BLUE}配置文件路径:${NC} $CONFIG_FILE"
  echo -e "${BLUE}项目目录:${NC} $AUTOGLM_DIR"
  echo
  read -rp "按回车返回主菜单... "
}

##########  查看支持的应用  ##########
list_apps() {
  show_header
  echo -e "${CYAN}正在获取支持的应用列表...${NC}"
  echo
  if [[ -d "$AUTOGLM_DIR" ]]; then
    cd "$AUTOGLM_DIR"
    python main.py --list-apps 2>/dev/null || echo -e "${RED}获取失败，请检查项目是否正确安装${NC}"
  else
    echo -e "${RED}项目目录不存在: $AUTOGLM_DIR${NC}"
  fi
  echo
  read -rp "按回车返回主菜单... "
}

##########  检测是否在 Termux 环境  ##########
in_termux() {
  [[ -n "${TERMUX_VERSION:-}" ]]
}

##########  询问是否执行操作  ##########
ask_yes_no() {
  local prompt="$1"
  local default="${2:-n}"
  local answer
  
  if [[ "$default" == "y" ]]; then
    read -rp "$prompt (Y/n): " answer
    case "${answer:-y}" in
      [Nn]*) return 1 ;;
      *) return 0 ;;
    esac
  else
    read -rp "$prompt (y/N): " answer
    case "${answer:-n}" in
      [Yy]*) return 0 ;;
      *) return 1 ;;
    esac
  fi
}

##########  卸载项目 pip 依赖  ##########
uninstall_pip_deps() {
  local req_file="$AUTOGLM_DIR/requirements.txt"
  
  if [[ ! -f "$req_file" ]]; then
    echo -e "${YELLOW}[WARN]${NC} 未找到 requirements.txt，跳过 pip 依赖卸载"
    return 0
  fi
  
  echo -e "${BLUE}[INFO]${NC} 将卸载以下 pip 依赖包："
  echo -e "${CYAN}────────────────────────────────────────${NC}"
  
  local pkg_list=()
  while IFS= read -r pkg || [[ -n "$pkg" ]]; do
    [[ -z "$pkg" || "$pkg" =~ ^# ]] && continue
    local pkg_name
    pkg_name=$(echo "$pkg" | sed -E 's/[<>=!].*//' | sed 's/\[.*\]//' | tr -d ' ')
    if [[ -n "$pkg_name" ]]; then
      pkg_list+=("$pkg_name")
      echo -e "  • $pkg_name"
    fi
  done < "$req_file"
  
  echo -e "  • open-autoglm (项目本体)"
  echo -e "${CYAN}────────────────────────────────────────${NC}"
  echo
  
  echo -e "${BLUE}[INFO]${NC} 卸载项目本体..."
  python -m pip uninstall -y open-autoglm 2>/dev/null || true
  python -m pip uninstall -y autoglm 2>/dev/null || true
  python -m pip uninstall -y Open-AutoGLM 2>/dev/null || true
  
  for pkg_name in "${pkg_list[@]}"; do
    echo -e "${BLUE}[INFO]${NC} 卸载 $pkg_name ..."
    python -m pip uninstall -y "$pkg_name" 2>/dev/null || true
  done
  
  echo -e "${GREEN}[SUCC]${NC} pip 依赖卸载完成"
}

##########  卸载 Open-AutoGLM + 控制面板  ##########
uninstall_basic() {
  show_header
  echo -e "${RED}╔══════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${RED}║${NC}              ${BOLD}🗑️  卸载 Open-AutoGLM + 控制面板${NC}                 ${RED}║${NC}"
  echo -e "${RED}╚══════════════════════════════════════════════════════════════╝${NC}"
  echo
  echo -e "${YELLOW}此选项将引导您逐项选择要卸载的内容${NC}"
  echo
  
  local did_something=false
  
  echo -e "${CYAN}━━━ 第 1 步：pip 依赖包 ━━━${NC}"
  if [[ -f "$AUTOGLM_DIR/requirements.txt" ]]; then
    echo -e "${YELLOW}检测到项目依赖文件：$AUTOGLM_DIR/requirements.txt${NC}"
    echo
    if ask_yes_no "是否卸载项目安装的 pip 依赖包？"; then
      uninstall_pip_deps
      did_something=true
    else
      echo -e "${BLUE}[INFO]${NC} 跳过 pip 依赖卸载"
    fi
  else
    echo -e "${YELLOW}[WARN]${NC} 未找到 requirements.txt，跳过此步骤"
    if ask_yes_no "是否卸载项目本体包（open-autoglm）？"; then
      python -m pip uninstall -y open-autoglm 2>/dev/null || true
      python -m pip uninstall -y autoglm 2>/dev/null || true
      python -m pip uninstall -y Open-AutoGLM 2>/dev/null || true
      echo -e "${GREEN}[SUCC]${NC} 项目本体已卸载"
      did_something=true
    fi
  fi
  echo
  
  echo -e "${CYAN}━━━ 第 2 步：项目目录 ━━━${NC}"
  if [[ -d "$AUTOGLM_DIR" ]]; then
    echo -e "${YELLOW}项目目录：$AUTOGLM_DIR${NC}"
    echo
    if ask_yes_no "是否删除 Open-AutoGLM 项目目录？"; then
      rm -rf "$AUTOGLM_DIR"
      echo -e "${GREEN}[SUCC]${NC} 已删除: $AUTOGLM_DIR"
      did_something=true
    else
      echo -e "${BLUE}[INFO]${NC} 保留项目目录"
    fi
  else
    echo -e "${YELLOW}[WARN]${NC} 项目目录不存在，跳过此步骤"
  fi
  echo
  
  echo -e "${CYAN}━━━ 第 3 步：autoglm 命令与配置文件 ━━━${NC}"
  echo -e "${YELLOW}包含以下内容：${NC}"
  echo -e "  • autoglm 命令: ${CYAN}$HOME/bin/autoglm${NC}"
  echo -e "  • 配置文件目录: ${CYAN}$HOME/.autoglm${NC}"
  echo -e "  • .bashrc 中的环境变量配置"
  echo
  if ask_yes_no "是否删除 autoglm 命令、配置文件和环境变量？"; then
    if [[ -f "$HOME/bin/autoglm" ]]; then
      rm -f "$HOME/bin/autoglm"
      echo -e "${GREEN}[SUCC]${NC} 已删除: $HOME/bin/autoglm"
    fi
    
    if [[ -d "$HOME/.autoglm" ]]; then
      rm -rf "$HOME/.autoglm"
      echo -e "${GREEN}[SUCC]${NC} 已删除: $HOME/.autoglm"
    fi
    
    if [[ -f "$HOME/.bashrc" ]]; then
      sed -i '/source ~\/.autoglm\/config.sh/d' "$HOME/.bashrc" 2>/dev/null || true
      sed -i '/source \$HOME\/.autoglm\/config.sh/d' "$HOME/.bashrc" 2>/dev/null || true
      echo -e "${GREEN}[SUCC]${NC} 已清理 .bashrc 中的环境变量"
    fi
    did_something=true
  else
    echo -e "${BLUE}[INFO]${NC} 保留 autoglm 命令和配置文件"
  fi
  echo
  
  if [[ "$did_something" == true ]]; then
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║${NC}              ${BOLD}✅ 卸载操作完成！${NC}                                ${GREEN}║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
    echo -e "${YELLOW}提示: 请重新打开终端以使更改生效${NC}"
  else
    echo -e "${BLUE}[INFO]${NC} 未执行任何卸载操作"
  fi
  echo
  read -rp "按回车继续... "
  
  if [[ ! -f "$HOME/bin/autoglm" ]]; then
    echo -e "${YELLOW}autoglm 命令已删除，即将退出...${NC}"
    exit 0
  fi
}

##########  完全卸载  ##########
uninstall_full() {
  show_header
  echo -e "${RED}╔══════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${RED}║${NC}              ${BOLD}🗑️  完全卸载（包括运行环境）${NC}                    ${RED}║${NC}"
  echo -e "${RED}╚══════════════════════════════════════════════════════════════╝${NC}"
  echo
  echo -e "${YELLOW}此选项将引导您逐项选择要卸载的内容${NC}"
  echo -e "${RED}${BOLD}⚠️  注意：卸载运行环境可能影响其他程序！${NC}"
  echo
  
  local did_something=false
  
  echo -e "${CYAN}━━━ 第 1 步：项目 pip 依赖包 ━━━${NC}"
  if [[ -f "$AUTOGLM_DIR/requirements.txt" ]]; then
    echo -e "${YELLOW}检测到项目依赖文件：$AUTOGLM_DIR/requirements.txt${NC}"
    echo
    if ask_yes_no "是否卸载项目安装的 pip 依赖包？"; then
      uninstall_pip_deps
      did_something=true
    else
      echo -e "${BLUE}[INFO]${NC} 跳过项目 pip 依赖卸载"
    fi
  else
    echo -e "${YELLOW}[WARN]${NC} 未找到 requirements.txt"
    if ask_yes_no "是否卸载项目本体包（open-autoglm）？"; then
      python -m pip uninstall -y open-autoglm 2>/dev/null || true
      python -m pip uninstall -y autoglm 2>/dev/null || true
      python -m pip uninstall -y Open-AutoGLM 2>/dev/null || true
      echo -e "${GREEN}[SUCC]${NC} 项目本体已卸载"
      did_something=true
    fi
  fi
  echo
  
  echo -e "${CYAN}━━━ 第 2 步：部署时安装的核心 pip 包 ━━━${NC}"
  echo -e "${YELLOW}包含以下包：${NC}"
  echo -e "  • maturin"
  echo -e "  • openai"
  echo -e "  • requests"
  if ! in_termux; then
    echo -e "  • pillow"
  fi
  echo
  if ask_yes_no "是否卸载这些核心 pip 包？"; then
    echo -e "${BLUE}[INFO]${NC} 卸载核心 pip 包..."
    python -m pip uninstall -y maturin 2>/dev/null || true
    python -m pip uninstall -y openai 2>/dev/null || true
    python -m pip uninstall -y requests 2>/dev/null || true
    if ! in_termux; then
      python -m pip uninstall -y pillow 2>/dev/null || true
    fi
    echo -e "${GREEN}[SUCC]${NC} 核心 pip 包已卸载"
    did_something=true
  else
    echo -e "${BLUE}[INFO]${NC} 保留核心 pip 包"
  fi
  echo
  
  echo -e "${CYAN}━━━ 第 3 步：项目目录 ━━━${NC}"
  if [[ -d "$AUTOGLM_DIR" ]]; then
    echo -e "${YELLOW}项目目录：$AUTOGLM_DIR${NC}"
    echo
    if ask_yes_no "是否删除 Open-AutoGLM 项目目录？"; then
      rm -rf "$AUTOGLM_DIR"
      echo -e "${GREEN}[SUCC]${NC} 已删除: $AUTOGLM_DIR"
      did_something=true
    else
      echo -e "${BLUE}[INFO]${NC} 保留项目目录"
    fi
  else
    echo -e "${YELLOW}[WARN]${NC} 项目目录不存在，跳过此步骤"
  fi
  echo
  
  echo -e "${CYAN}━━━ 第 4 步：autoglm 命令与配置文件 ━━━${NC}"
  echo -e "${YELLOW}包含以下内容：${NC}"
  echo -e "  • autoglm 命令: ${CYAN}$HOME/bin/autoglm${NC}"
  echo -e "  • 配置文件目录: ${CYAN}$HOME/.autoglm${NC}"
  echo -e "  • .bashrc 中的环境变量配置"
  echo
  if ask_yes_no "是否删除 autoglm 命令、配置文件和环境变量？"; then
    if [[ -f "$HOME/bin/autoglm" ]]; then
      rm -f "$HOME/bin/autoglm"
      echo -e "${GREEN}[SUCC]${NC} 已删除: $HOME/bin/autoglm"
    fi
    
    if [[ -d "$HOME/.autoglm" ]]; then
      rm -rf "$HOME/.autoglm"
      echo -e "${GREEN}[SUCC]${NC} 已删除: $HOME/.autoglm"
    fi
    
    if [[ -f "$HOME/.bashrc" ]]; then
      sed -i '/source ~\/.autoglm\/config.sh/d' "$HOME/.bashrc" 2>/dev/null || true
      sed -i '/source \$HOME\/.autoglm\/config.sh/d' "$HOME/.bashrc" 2>/dev/null || true
      echo -e "${GREEN}[SUCC]${NC} 已清理 .bashrc 中的环境变量"
    fi
    did_something=true
  else
    echo -e "${BLUE}[INFO]${NC} 保留 autoglm 命令和配置文件"
  fi
  echo
  
  echo -e "${CYAN}━━━ 第 5 步：pip 镜像配置 ━━━${NC}"
  local pip_mirror
  pip_mirror=$(pip config get global.index-url 2>/dev/null || echo "")
  if [[ -n "$pip_mirror" ]]; then
    echo -e "${YELLOW}当前 pip 镜像：$pip_mirror${NC}"
    echo
    if ask_yes_no "是否删除 pip 镜像配置？"; then
      pip config unset global.index-url 2>/dev/null || true
      pip config unset install.trusted-host 2>/dev/null || true
      echo -e "${GREEN}[SUCC]${NC} pip 镜像配置已删除"
      did_something=true
    else
      echo -e "${BLUE}[INFO]${NC} 保留 pip 镜像配置"
    fi
  else
    echo -e "${YELLOW}[INFO]${NC} 未检测到 pip 镜像配置，跳过此步骤"
  fi
  echo
  
  echo -e "${CYAN}━━━ 第 6 步：Cargo 镜像配置 ━━━${NC}"
  if [[ -f "$HOME/.cargo/config.toml" ]]; then
    echo -e "${YELLOW}检测到 Cargo 配置：$HOME/.cargo/config.toml${NC}"
    echo
    if ask_yes_no "是否删除 Cargo 镜像配置？"; then
      rm -f "$HOME/.cargo/config.toml"
      rm -f "$HOME/.cargo/config"
      echo -e "${GREEN}[SUCC]${NC} Cargo 镜像配置已删除"
      did_something=true
    else
      echo -e "${BLUE}[INFO]${NC} 保留 Cargo 镜像配置"
    fi
  else
    echo -e "${YELLOW}[INFO]${NC} 未检测到 Cargo 镜像配置，跳过此步骤"
  fi
  echo
  
  if in_termux; then
    echo -e "${CYAN}━━━ 第 7 步：Termux 系统包 ━━━${NC}"
    echo -e "${RED}${BOLD}⚠️  警告：卸载系统包可能影响其他程序！${NC}"
    echo
    
    if pkg list-installed 2>/dev/null | grep -q "python-pillow"; then
      if ask_yes_no "是否卸载 python-pillow？"; then
        pkg uninstall -y python-pillow 2>/dev/null || true
        echo -e "${GREEN}[SUCC]${NC} python-pillow 已卸载"
        did_something=true
      fi
    fi
    
    if command -v rustc &>/dev/null; then
      if ask_yes_no "是否卸载 Rust 编译工具链（rust, binutils）？"; then
        pkg uninstall -y rust binutils 2>/dev/null || true
        echo -e "${GREEN}[SUCC]${NC} Rust 工具链已卸载"
        did_something=true
      fi
    fi
    
    if command -v adb &>/dev/null; then
      if ask_yes_no "是否卸载 ADB 工具（android-tools）？"; then
        pkg uninstall -y android-tools 2>/dev/null || true
        echo -e "${GREEN}[SUCC]${NC} ADB 工具已卸载"
        did_something=true
      fi
    fi
    echo
  fi
  
  if [[ "$did_something" == true ]]; then
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║${NC}              ${BOLD}✅ 卸载操作完成！${NC}                                ${GREEN}║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
    echo -e "${YELLOW}提示: 请重新打开终端以使更改生效${NC}"
  else
    echo -e "${BLUE}[INFO]${NC} 未执行任何卸载操作"
  fi
  echo
  read -rp "按回车继续... "
  
  if [[ ! -f "$HOME/bin/autoglm" ]]; then
    echo -e "${YELLOW}autoglm 命令已删除，即将退出...${NC}"
    exit 0
  fi
}

##########  卸载子菜单  ##########
uninstall_menu() {
  while true; do
    show_header
    echo -e "${RED}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║${NC}              ${BOLD}🗑️  一键卸载${NC}                                     ${RED}║${NC}"
    echo -e "${RED}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
    echo -e "${YELLOW}请选择卸载方式：${NC}"
    echo
    echo -e "  ${GREEN}1.${NC} 🧹 卸载 Open-AutoGLM + autoglm 控制面板"
    echo -e "     ${CYAN}可选择性删除：pip依赖、项目目录、命令和配置${NC}"
    echo
    echo -e "  ${GREEN}2.${NC} 💣 完全卸载（包括运行环境）"
    echo -e "     ${CYAN}除上述内容外，还可选择卸载：${NC}"
    echo -e "     ${CYAN}核心pip包、镜像配置、系统包等${NC}"
    echo
    echo -e "  ${GREEN}0.${NC} ↩️  返回主菜单"
    echo
    read -rp "请选择 [0-2]: " choice
    
    case "$choice" in
      1)
        uninstall_basic
        ;;
      2)
        uninstall_full
        ;;
      0)
        return
        ;;
      *)
        echo -e "${RED}无效选择${NC}"
        sleep 1
        ;;
    esac
  done
}

##########  启动 AutoGLM  ##########
start_autoglm() {
  local device_count
  device_count=$(get_adb_device_count)
  
  if [[ "$device_count" -eq 0 ]]; then
    echo
    echo -e "${RED}[ERROR]${NC} 未检测到在线的 ADB 设备！"
    echo -e "${YELLOW}请先配置 ADB 无线调试（菜单选项 2）${NC}"
    echo
    read -rp "是否现在配置 ADB？(Y/n): " ans
    case "${ans:-y}" in
      [Nn]*)
        return 1
        ;;
      *)
        adb_menu
        device_count=$(get_adb_device_count)
        if [[ "$device_count" -eq 0 ]]; then
          return 1
        fi
        ;;
    esac
  fi
  
  if [[ ! -d "$AUTOGLM_DIR" ]]; then
    echo -e "${RED}[ERROR]${NC} 项目目录不存在: $AUTOGLM_DIR"
    echo -e "${YELLOW}请重新运行 deploy.sh 安装${NC}"
    read -rp "按回车返回... "
    return 1
  fi
  
  local CMD_ARGS=()
  CMD_ARGS+=(--base-url "$PHONE_AGENT_BASE_URL")
  CMD_ARGS+=(--model "$PHONE_AGENT_MODEL")
  CMD_ARGS+=(--apikey "$PHONE_AGENT_API_KEY")
  
  [[ -n "${PHONE_AGENT_DEVICE_ID:-}" ]] && CMD_ARGS+=(--device-id "$PHONE_AGENT_DEVICE_ID")
  
  echo
  echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${CYAN}║${NC}              ${BOLD}🚀 启动 AutoGLM${NC}                                  ${CYAN}║${NC}"
  echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
  echo
  echo -e "${BLUE}配置信息:${NC}"
  echo -e "  API    : ${GREEN}$PHONE_AGENT_BASE_URL${NC}"
  echo -e "  Model  : ${GREEN}$PHONE_AGENT_MODEL${NC}"
  echo -e "  Steps  : ${GREEN}$PHONE_AGENT_MAX_STEPS${NC}"
  echo -e "  Lang   : ${GREEN}$PHONE_AGENT_LANG${NC}"
  [[ -n "${PHONE_AGENT_DEVICE_ID:-}" ]] && echo -e "  Device : ${GREEN}$PHONE_AGENT_DEVICE_ID${NC}"
  echo
  echo -e "${YELLOW}正在启动...${NC}"
  echo
  
  cd "$AUTOGLM_DIR"
  exec python main.py "${CMD_ARGS[@]}"
}

##########  解析命令行参数  ##########
parse_args() {
  while [[ $# -gt 0 ]]; do
    case $1 in
      --base-url)
        PHONE_AGENT_BASE_URL="$2"
        shift 2
        ;;
      --model)
        PHONE_AGENT_MODEL="$2"
        shift 2
        ;;
      --apikey)
        PHONE_AGENT_API_KEY="$2"
        shift 2
        ;;
      --max-steps)
        PHONE_AGENT_MAX_STEPS="$2"
        shift 2
        ;;
      --device-id)
        PHONE_AGENT_DEVICE_ID="$2"
        shift 2
        ;;
      --lang)
        PHONE_AGENT_LANG="$2"
        shift 2
        ;;
      --list-apps)
        cd "$AUTOGLM_DIR" 2>/dev/null && python main.py --list-apps
        exit $?
        ;;
      --setup-adb)
        load_config
        adb_menu
        exit 0
        ;;
      --switch-device)
        load_config
        switch_adb_device
        exit 0
        ;;
      --disconnect)
        load_config
        disconnect_device
        exit 0
        ;;
      --devices)
        load_config
        show_device_list
        exit 0
        ;;
      --reconfig)
        load_config
        modify_config
        exit 0
        ;;
      --uninstall)
        load_config
        uninstall_menu
        exit 0
        ;;
      --help|-h)
        echo -e "${BOLD}${CYAN}AutoGLM - 智能手机控制代理${NC}"
        echo
        echo -e "${YELLOW}用法:${NC}"
        echo "  autoglm                # 打开交互式菜单"
        echo "  autoglm --setup-adb    # ADB 设备管理"
        echo "  autoglm --devices      # 查看设备列表"
        echo "  autoglm --switch-device # 切换 ADB 设备"
        echo "  autoglm --disconnect   # 断开设备连接"
        echo "  autoglm --reconfig     # 修改配置"
        echo "  autoglm --list-apps    # 查看支持的应用"
        echo "  autoglm --uninstall    # 卸载"
        echo
        echo -e "${YELLOW}参数:${NC}"
        echo "  --base-url URL       设置 API 地址"
        echo "  --model NAME         设置模型名称"
        echo "  --apikey KEY         设置 API Key"
        echo "  --max-steps N        设置最大步数"
        echo "  --device-id ID       设置 ADB 设备 ID"
        echo "  --lang cn|en         设置语言"
        exit 0
        ;;
      --start|-s)
        DIRECT_START=true
        shift
        ;;
      *)
        echo -e "${RED}未知参数: $1${NC}"
        echo "使用 --help 查看帮助"
        exit 1
        ;;
    esac
  done
}

##########  主菜单循环  ##########
main_menu_loop() {
  while true; do
    show_main_menu
    read -rp "请选择 [0-6]: " choice
    
    case "$choice" in
      1)
        start_autoglm
        ;;
      2)
        adb_menu
        ;;
      3)
        modify_config
        ;;
      4)
        list_apps
        ;;
      5)
        view_config
        ;;
      6)
        uninstall_menu
        ;;
      0)
        echo
        echo -e "${GREEN}再见！${NC}"
        exit 0
        ;;
      *)
        echo -e "${RED}无效选择，请输入 0-6${NC}"
        sleep 1
        ;;
    esac
  done
}

##########  主入口  ##########
main() {
  load_config
  parse_args "$@"
  
  if [[ "${DIRECT_START:-false}" == true ]]; then
    start_autoglm
    exit $?
  fi
  
  main_menu_loop
}

main "$@"
LAUNCHER_EOF
  
  chmod +x ~/bin/autoglm
  
  if ! grep -q 'export PATH=.*~/bin' ~/.bashrc 2>/dev/null; then
    echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc
  fi
  
  log_succ "启动器已创建: ~/bin/autoglm"
}

##########  主流程  ##########
main() {
  echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${BLUE}║${NC}       ${BOLD}Open-AutoGLM 一键部署脚本 (ADB 纯方案)${NC}              ${BLUE}║${NC}"
  echo -e "${BLUE}║${NC}       ${CYAN}版本: 4.5.0${NC}                                          ${BLUE}║${NC}"
  echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
  echo
  
  log_info "检查并安装基础依赖..."
  ensure_python
  ensure_pip
  ensure_git
  ensure_rust
  ensure_adb
  
  ensure_setuptools
  
  echo
  
  local pip_mirror="" cargo_mirror=""
  ask_mirror "请输入 pip 镜像地址（阿里 https://mirrors.aliyun.com/pypi/simple）" \
             "https://mirrors.aliyun.com/pypi/simple" pip_mirror
  ask_mirror "请输入 Cargo 镜像地址（清华 sparse+https://mirrors.tuna.tsinghua.edu.cn/crates.io-index/）" \
             "sparse+https://mirrors.tuna.tsinghua.edu.cn/crates.io-index/" cargo_mirror
  setup_pip_mirror "$pip_mirror"
  setup_cargo_mirror "$cargo_mirror"

  install_py_deps

  clone_or_update

  configure_env

  remind_adb_keyboard

  echo
  if check_adb_configured; then
    log_succ "检测到已连接的 ADB 设备:"
    adb devices
    read -rp "是否需要重新配置 ADB？(y/N): " reconf
    if [[ "$reconf" == "y" || "$reconf" == "Y" ]]; then
      configure_adb_wireless
    fi
  else
    log_warn "未检测到 ADB 设备"
    read -rp "是否现在配置 ADB 无线调试？(Y/n): " conf
    case "${conf:-y}" in
      [Nn]*)
        log_info "跳过 ADB 配置，稍后可运行 autoglm 进行配置"
        ;;
      *)
        configure_adb_wireless || log_warn "ADB 配置失败，稍后可运行 autoglm 重试"
        ;;
    esac
  fi

  make_launcher

  # 立即重载 bashrc 使配置生效
  source ~/.bashrc 2>/dev/null || true
  source ~/.autoglm/config.sh 2>/dev/null || true
  export PATH="$HOME/bin:$PATH"

  echo
  echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${GREEN}║${NC}              ${BOLD}✅ 部署完成！${NC}                                    ${GREEN}║${NC}"
  echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
  echo
  echo -e "运行 ${CYAN}autoglm${NC} 打开智能启动面板"
  echo -e "运行 ${CYAN}autoglm --help${NC} 查看更多选项"
  echo
  echo -e "${GREEN}提示: autoglm 命令已设置并生效！${NC}"
  echo -e "${YELLOW}提示: 新终端窗口自动加载配置，当前窗口若运行autoglm失败，请手动执行下面代码后重新运行:${NC}"
  echo -e "  ${GREEN}source ~/.bashrc${NC}"
  echo
}

main "$@"
