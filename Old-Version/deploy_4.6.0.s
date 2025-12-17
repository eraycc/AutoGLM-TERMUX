#!/usr/bin/env bash
# Open-AutoGLM Termux 纯 ADB 方案 - 一键部署脚本
# 版本: 4.6.0 (全面国际化支持)
set -euo pipefail

##########  基础工具  ##########
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; PURPLE='\033[0;35m'; CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

##########  语言配置  ##########
LANG_CHOICE="cn"

##########  国际化文本  ##########
declare -A I18N

init_i18n() {
  # 部署脚本文本
  I18N["deploy_title_cn"]="Open-AutoGLM 一键部署脚本 (ADB 纯方案)"
  I18N["deploy_title_en"]="Open-AutoGLM One-Click Deploy Script (ADB Only)"
  I18N["deploy_version_cn"]="版本: 4.6.0"
  I18N["deploy_version_en"]="Version: 4.6.0"
  
  I18N["checking_deps_cn"]="检查并安装基础依赖..."
  I18N["checking_deps_en"]="Checking and installing dependencies..."
  
  I18N["python_exists_cn"]="Python 已存在"
  I18N["python_exists_en"]="Python already installed"
  I18N["python_install_cn"]="安装 Python..."
  I18N["python_install_en"]="Installing Python..."
  
  I18N["pip_exists_cn"]="pip 已存在"
  I18N["pip_exists_en"]="pip already installed"
  I18N["pip_install_cn"]="安装 python-pip..."
  I18N["pip_install_en"]="Installing python-pip..."
  
  I18N["git_exists_cn"]="Git 已存在"
  I18N["git_exists_en"]="Git already installed"
  I18N["git_install_cn"]="安装 Git..."
  I18N["git_install_en"]="Installing Git..."
  
  I18N["rust_exists_cn"]="Rust 已存在"
  I18N["rust_exists_en"]="Rust already installed"
  I18N["rust_install_cn"]="安装 Rust 编译工具链..."
  I18N["rust_install_en"]="Installing Rust toolchain..."
  
  I18N["adb_exists_cn"]="ADB 已存在"
  I18N["adb_exists_en"]="ADB already installed"
  I18N["adb_install_cn"]="安装 ADB..."
  I18N["adb_install_en"]="Installing ADB..."
  I18N["adb_manual_cn"]="请手动安装 ADB 工具"
  I18N["adb_manual_en"]="Please manually install ADB tools"
  
  I18N["setuptools_cn"]="确保 setuptools 已安装..."
  I18N["setuptools_en"]="Ensuring setuptools is installed..."
  
  I18N["no_pkg_manager_cn"]="未找到适配的包管理器，请手动安装"
  I18N["no_pkg_manager_en"]="No compatible package manager found, please install manually"
  
  # 镜像配置
  I18N["pip_mirror_prompt_cn"]="请输入 pip 镜像地址（阿里 https://mirrors.aliyun.com/pypi/simple）"
  I18N["pip_mirror_prompt_en"]="Enter pip mirror URL (Aliyun https://mirrors.aliyun.com/pypi/simple)"
  I18N["cargo_mirror_prompt_cn"]="请输入 Cargo 镜像地址（清华 sparse+https://mirrors.tuna.tsinghua.edu.cn/crates.io-index/）"
  I18N["cargo_mirror_prompt_en"]="Enter Cargo mirror URL (Tsinghua sparse+https://mirrors.tuna.tsinghua.edu.cn/crates.io-index/)"
  I18N["mirror_tip_cn"]="（直接回车跳过，输入 default 使用推荐源）"
  I18N["mirror_tip_en"]="(Press Enter to skip, type 'default' for recommended)"
  I18N["pip_mirror_skip_cn"]="跳过 pip 镜像配置"
  I18N["pip_mirror_skip_en"]="Skipping pip mirror configuration"
  I18N["pip_mirror_set_cn"]="设置 pip 镜像"
  I18N["pip_mirror_set_en"]="Setting pip mirror"
  I18N["cargo_mirror_skip_cn"]="跳过 Cargo 镜像配置"
  I18N["cargo_mirror_skip_en"]="Skipping Cargo mirror configuration"
  I18N["cargo_mirror_set_cn"]="设置 Cargo 镜像"
  I18N["cargo_mirror_set_en"]="Setting Cargo mirror"
  
  # Python 依赖安装
  I18N["install_py_deps_cn"]="安装/升级核心 Python 包..."
  I18N["install_py_deps_en"]="Installing/upgrading core Python packages..."
  I18N["openai_install_title_cn"]="正在安装 openai 模块，请耐心等待..."
  I18N["openai_install_title_en"]="Installing openai module, please wait..."
  I18N["openai_install_tip_cn"]="openai 的部分依赖需要 Rust 编译，可能耗时较长（5-15分钟）"
  I18N["openai_install_tip_en"]="Some openai dependencies require Rust compilation (5-15 minutes)"
  
  # 项目克隆
  I18N["clone_detected_cn"]="检测到本地已存在 Open-AutoGLM 目录"
  I18N["clone_detected_en"]="Local Open-AutoGLM directory detected"
  I18N["clone_update_ask_cn"]="是否更新代码？（y/N）"
  I18N["clone_update_ask_en"]="Update code? (y/N)"
  I18N["clone_updating_cn"]="正在更新代码..."
  I18N["clone_updating_en"]="Updating code..."
  I18N["clone_update_fail_cn"]="更新失败，使用本地代码"
  I18N["clone_update_fail_en"]="Update failed, using local code"
  I18N["clone_skip_cn"]="跳过更新，使用本地代码"
  I18N["clone_skip_en"]="Skipping update, using local code"
  I18N["clone_cloning_cn"]="克隆仓库..."
  I18N["clone_cloning_en"]="Cloning repository..."
  I18N["install_project_deps_cn"]="安装项目依赖..."
  I18N["install_project_deps_en"]="Installing project dependencies..."
  I18N["install_project_cn"]="安装项目本体..."
  I18N["install_project_en"]="Installing project..."
  
  # 配置界面
  I18N["config_title_cn"]="配置 Open-AutoGLM 参数"
  I18N["config_title_en"]="Configure Open-AutoGLM Parameters"
  I18N["config_tip_cn"]="直接回车使用 [默认值]"
  I18N["config_tip_en"]="Press Enter to use [default value]"
  I18N["config_base_url_cn"]="AI 接口 Base URL"
  I18N["config_base_url_en"]="AI API Base URL"
  I18N["config_model_cn"]="AI 模型名称"
  I18N["config_model_en"]="AI Model Name"
  I18N["config_apikey_cn"]="AI API Key"
  I18N["config_apikey_en"]="AI API Key"
  I18N["config_max_steps_cn"]="每任务最大步数"
  I18N["config_max_steps_en"]="Max Steps Per Task"
  I18N["config_device_id_cn"]="ADB 设备 ID（单设备留空自动检测）"
  I18N["config_device_id_en"]="ADB Device ID (leave empty for auto-detect)"
  I18N["config_lang_cn"]="语言 cn/en"
  I18N["config_lang_en"]="Language cn/en"
  I18N["config_saved_cn"]="配置已保存到"
  I18N["config_saved_en"]="Configuration saved to"
  
  # ADB Keyboard 提醒
  I18N["adb_keyboard_title_cn"]="重要提醒：安装 ADB Keyboard"
  I18N["adb_keyboard_title_en"]="Important: Install ADB Keyboard"
  I18N["adb_keyboard_desc_cn"]="此工具用于文本输入，必须安装！"
  I18N["adb_keyboard_desc_en"]="This tool is required for text input!"
  I18N["adb_keyboard_download_cn"]="下载地址:"
  I18N["adb_keyboard_download_en"]="Download URL:"
  I18N["adb_keyboard_steps_cn"]="安装步骤:"
  I18N["adb_keyboard_steps_en"]="Installation Steps:"
  I18N["adb_keyboard_step1_cn"]="下载并安装 ADBKeyboard.apk 到安卓设备"
  I18N["adb_keyboard_step1_en"]="Download and install ADBKeyboard.apk on Android device"
  I18N["adb_keyboard_step2_cn"]="进入 设置 → 系统 → 语言和输入法 → 虚拟键盘 → 管理键盘"
  I18N["adb_keyboard_step2_en"]="Go to Settings → System → Language & Input → Virtual Keyboard → Manage"
  I18N["adb_keyboard_step3_cn"]="启用 'ADB Keyboard' 即可（可暂不切换）"
  I18N["adb_keyboard_step3_en"]="Enable 'ADB Keyboard' (no need to switch yet)"
  I18N["adb_keyboard_step4_cn"]="使用原输入法继续下面的配置"
  I18N["adb_keyboard_step4_en"]="Continue with your current input method"
  I18N["understood_cn"]="已了解，按回车继续..."
  I18N["understood_en"]="Understood, press Enter to continue..."
  
  # ADB 无线调试配置
  I18N["adb_wizard_title_cn"]="ADB 无线调试配置向导"
  I18N["adb_wizard_title_en"]="ADB Wireless Debugging Setup Wizard"
  I18N["adb_wizard_steps_cn"]="请按以下步骤操作:"
  I18N["adb_wizard_steps_en"]="Please follow these steps:"
  I18N["adb_wizard_step1_cn"]="确保手机和 Termux 设备在同一 WiFi 网络下"
  I18N["adb_wizard_step1_en"]="Ensure phone and Termux device are on the same WiFi"
  I18N["adb_wizard_step2_cn"]="进入 设置 → 关于手机 → 连续点击版本号 7 次（开启开发者模式）"
  I18N["adb_wizard_step2_en"]="Go to Settings → About Phone → Tap Build Number 7 times"
  I18N["adb_wizard_step3_cn"]="返回 设置 → 系统 → 开发者选项"
  I18N["adb_wizard_step3_en"]="Go back to Settings → System → Developer Options"
  I18N["adb_wizard_step4_cn"]="开启 '无线调试'"
  I18N["adb_wizard_step4_en"]="Enable 'Wireless Debugging'"
  I18N["adb_wizard_step5_cn"]="建议: 将无线调试界面和 Termux 分屏显示"
  I18N["adb_wizard_step5_en"]="Tip: Split screen with Wireless Debugging and Termux"
  I18N["adb_pair_title_cn"]="第一步：配对设备"
  I18N["adb_pair_title_en"]="Step 1: Pair Device"
  I18N["adb_pair_tip_cn"]="点击无线调试界面中的「使用配对码配对」"
  I18N["adb_pair_tip_en"]="Tap 'Pair device with pairing code' in Wireless Debugging"
  I18N["adb_pair_host_cn"]="输入配对码弹窗显示的 IP:端口"
  I18N["adb_pair_host_en"]="Enter IP:Port from pairing dialog"
  I18N["adb_pair_code_cn"]="输入配对码（6 位数字）"
  I18N["adb_pair_code_en"]="Enter pairing code (6 digits)"
  I18N["adb_pairing_cn"]="正在配对"
  I18N["adb_pairing_en"]="Pairing"
  I18N["adb_pair_success_cn"]="配对成功！"
  I18N["adb_pair_success_en"]="Pairing successful!"
  I18N["adb_pair_fail_cn"]="配对失败，请检查输入是否正确！"
  I18N["adb_pair_fail_en"]="Pairing failed, please check your input!"
  I18N["adb_connect_title_cn"]="第二步：连接设备"
  I18N["adb_connect_title_en"]="Step 2: Connect Device"
  I18N["adb_connect_tip_cn"]="查看无线调试主界面（不是配对码弹窗）显示的 IP 地址和端口"
  I18N["adb_connect_tip_en"]="Check the IP:Port on Wireless Debugging main screen (not pairing dialog)"
  I18N["adb_connect_host_cn"]="输入无线调试界面的 IP:端口"
  I18N["adb_connect_host_en"]="Enter IP:Port from Wireless Debugging screen"
  I18N["adb_connecting_cn"]="正在连接"
  I18N["adb_connecting_en"]="Connecting"
  I18N["adb_connect_success_cn"]="连接成功！设备已就绪！"
  I18N["adb_connect_success_en"]="Connected successfully! Device is ready!"
  I18N["adb_connect_fail_cn"]="设备未正确连接，请重试！"
  I18N["adb_connect_fail_en"]="Device not connected properly, please retry!"
  I18N["adb_connect_fail2_cn"]="连接失败，请检查 IP:端口 和网络连接！"
  I18N["adb_connect_fail2_en"]="Connection failed, please check IP:Port and network!"
  I18N["empty_input_cn"]="不能为空！"
  I18N["empty_input_en"]="Cannot be empty!"
  
  # ADB 设备状态
  I18N["adb_devices_cn"]="当前 ADB 设备列表:"
  I18N["adb_devices_en"]="Current ADB Device List:"
  I18N["adb_detected_cn"]="检测到已连接的 ADB 设备:"
  I18N["adb_detected_en"]="Connected ADB devices detected:"
  I18N["adb_reconfig_ask_cn"]="是否需要重新配置 ADB？(y/N)"
  I18N["adb_reconfig_ask_en"]="Reconfigure ADB? (y/N)"
  I18N["adb_not_detected_cn"]="未检测到 ADB 设备"
  I18N["adb_not_detected_en"]="No ADB device detected"
  I18N["adb_config_now_cn"]="是否现在配置 ADB 无线调试？(Y/n)"
  I18N["adb_config_now_en"]="Configure ADB wireless debugging now? (Y/n)"
  I18N["adb_config_skip_cn"]="跳过 ADB 配置，稍后可运行 autoglm 进行配置"
  I18N["adb_config_skip_en"]="Skipping ADB config, run 'autoglm' later to configure"
  I18N["adb_config_fail_cn"]="ADB 配置失败，稍后可运行 autoglm 重试"
  I18N["adb_config_fail_en"]="ADB config failed, run 'autoglm' later to retry"
  
  # 部署完成
  I18N["deploy_complete_cn"]="部署完成！"
  I18N["deploy_complete_en"]="Deployment Complete!"
  I18N["launcher_created_cn"]="启动器已创建"
  I18N["launcher_created_en"]="Launcher created"
  I18N["run_autoglm_cn"]="运行 autoglm 打开智能启动面板"
  I18N["run_autoglm_en"]="Run 'autoglm' to open the smart control panel"
  I18N["run_autoglm_help_cn"]="运行 autoglm --help 查看更多选项"
  I18N["run_autoglm_help_en"]="Run 'autoglm --help' for more options"
  I18N["autoglm_ready_cn"]="提示: autoglm 命令已设置并生效！"
  I18N["autoglm_ready_en"]="Tip: autoglm command is ready!"
  I18N["source_tip_cn"]="提示: 新终端窗口自动加载配置，当前窗口若运行autoglm失败，请手动执行下面代码后重新运行:"
  I18N["source_tip_en"]="Tip: New terminal windows auto-load config. If autoglm fails in current window, run:"
}

# 获取国际化文本
i18n() {
  local key="${1}_${LANG_CHOICE}"
  echo "${I18N[$key]:-$1}"
}

log_info()  { echo -e "${BLUE}[INFO]${NC}  $*" >&2; }
log_succ()  { echo -e "${GREEN}[SUCC]${NC} $*" >&2; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $*" >&2; }
log_err()   { echo -e "${RED}[ERROR]${NC} $*" >&2; }

in_termux() { [[ -n "${TERMUX_VERSION:-}" ]]; }

##########  语言选择  ##########
select_language() {
  echo
  echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${CYAN}║${NC}  ${BOLD}请选择语言 / Please select language${NC}                        ${CYAN}║${NC}"
  echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
  echo
  echo -e "  ${GREEN}cn${NC} - 中文 (Chinese)"
  echo -e "  ${GREEN}en${NC} - English"
  echo
  read -rp "输入 cn 或 en / Enter cn or en [cn]: " lang_input
  lang_input="${lang_input:-cn}"
  
  case "$lang_input" in
    en|EN|En)
      LANG_CHOICE="en"
      echo -e "${GREEN}Language set to English${NC}"
      ;;
    *)
      LANG_CHOICE="cn"
      echo -e "${GREEN}语言设置为中文${NC}"
      ;;
  esac
  echo
}

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
      log_err "$(i18n no_pkg_manager): $*"
      exit 1
    fi
  fi
}

##########  镜像源配置  ##########
ask_mirror() {
  local tip="$1" default="$2" var="$3"
  read -rp "${tip} $(i18n mirror_tip): " input
  input="${input:-}"
  if [[ "$input" == "default" ]]; then
    input="$default"
  fi
  printf -v "$var" '%s' "$input"
}

setup_pip_mirror() {
  local url="$1"
  if [[ -z "$url" ]]; then
    log_info "$(i18n pip_mirror_skip)"
    return 0
  fi
  log_info "$(i18n pip_mirror_set): $url"
  local host
  host=$(echo "$url" | sed -E 's|https?://([^/]+).*|\1|')
  pip config set global.index-url "$url" 2>/dev/null || true
  pip config set install.trusted-host "$host" 2>/dev/null || true
}

setup_cargo_mirror() {
  local url="$1"
  if [[ -z "$url" ]]; then
    log_info "$(i18n cargo_mirror_skip)"
    return 0
  fi
  log_info "$(i18n cargo_mirror_set): $url"
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
    log_succ "$(i18n python_exists): $(python --version)"
  else
    log_info "$(i18n python_install)"
    pkg_install python
  fi
}

ensure_pip() {
  if python -m pip --version &>/dev/null; then
    log_succ "$(i18n pip_exists)"
  else
    log_info "$(i18n pip_install)"
    pkg_install python-pip
  fi
}

ensure_git() {
  if command -v git &>/dev/null; then
    log_succ "$(i18n git_exists): $(git --version)"
  else
    log_info "$(i18n git_install)"
    pkg_install git
  fi
}

ensure_rust() {
  if command -v rustc &>/dev/null; then
    log_succ "$(i18n rust_exists): $(rustc --version)"
  else
    log_info "$(i18n rust_install)"
    pkg_install rust binutils
  fi
}

ensure_adb() {
  if command -v adb &>/dev/null; then
    log_succ "$(i18n adb_exists): $(adb version | head -1)"
    return 0
  fi
  
  log_info "$(i18n adb_install)"
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
    log_warn "$(i18n adb_manual)"
    return 1
  fi
}

ensure_setuptools() {
  log_info "$(i18n setuptools)"
  python -m pip install --upgrade setuptools wheel 2>/dev/null || true
}

##########  ADB 设备计数（修复算术错误）  ##########
get_adb_device_count() {
  local count
  count=$(adb devices 2>/dev/null | awk 'NR>1 && $2=="device" {count++} END {print count+0}')
  echo "${count:-0}" | tr -d '[:space:]'
}

##########  ADB Keyboard 提醒 ##########
remind_adb_keyboard() {
  echo
  echo -e "${YELLOW}╔══════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${YELLOW}║${NC}          ${BOLD}${RED}$(i18n adb_keyboard_title)${NC}                        ${YELLOW}║${NC}"
  echo -e "${YELLOW}╚══════════════════════════════════════════════════════════════╝${NC}"
  echo
  echo -e "${CYAN}$(i18n adb_keyboard_desc)${NC}"
  echo
  echo -e "${BLUE}$(i18n adb_keyboard_download)${NC}"
  echo -e "  ${GREEN}https://github.com/senzhk/ADBKeyBoard/blob/master/ADBKeyboard.apk${NC}"
  echo
  echo -e "${BLUE}$(i18n adb_keyboard_steps)${NC}"
  echo -e "  ${GREEN}1.${NC} $(i18n adb_keyboard_step1)"
  echo -e "  ${GREEN}2.${NC} $(i18n adb_keyboard_step2)"
  echo -e "  ${GREEN}3.${NC} $(i18n adb_keyboard_step3)"
  echo -e "  ${GREEN}4.${NC} $(i18n adb_keyboard_step4)"
  echo
  read -rp "$(i18n understood) "
}

##########  ADB 无线调试配置向导  ##########
configure_adb_wireless() {
  echo
  echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${CYAN}║${NC}              ${BOLD}$(i18n adb_wizard_title)${NC}                            ${CYAN}║${NC}"
  echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
  echo
  echo -e "${BLUE}$(i18n adb_wizard_steps)${NC}"
  echo -e "  ${GREEN}1.${NC} $(i18n adb_wizard_step1)"
  echo -e "  ${GREEN}2.${NC} $(i18n adb_wizard_step2)"
  echo -e "  ${GREEN}3.${NC} $(i18n adb_wizard_step3)"
  echo -e "  ${GREEN}4.${NC} $(i18n adb_wizard_step4)"
  echo -e "  ${GREEN}5.${NC} ${YELLOW}$(i18n adb_wizard_step5)${NC}"
  echo
  
  echo -e "${YELLOW}━━━ $(i18n adb_pair_title) ━━━${NC}"
  echo -e "${CYAN}$(i18n adb_pair_tip)${NC}"
  echo
  read -rp "  $(i18n adb_pair_host): " pair_host
  if [[ -z "$pair_host" ]]; then
    log_err "IP:Port $(i18n empty_input)"
    return 1
  fi
  
  read -rp "  $(i18n adb_pair_code): " pair_code
  if [[ -z "$pair_code" ]]; then
    log_err "$(i18n adb_pair_code) $(i18n empty_input)"
    return 1
  fi
  
  log_info "$(i18n adb_pairing) $pair_host ..."
  if adb pair "$pair_host" "$pair_code" 2>&1; then
    log_succ "$(i18n adb_pair_success)"
  else
    log_err "$(i18n adb_pair_fail)"
    return 1
  fi
  
  echo
  echo -e "${YELLOW}━━━ $(i18n adb_connect_title) ━━━${NC}"
  echo -e "${CYAN}$(i18n adb_connect_tip)${NC}"
  echo
  read -rp "  $(i18n adb_connect_host): " connect_host
  if [[ -z "$connect_host" ]]; then
    log_err "IP:Port $(i18n empty_input)"
    return 1
  fi
  
  log_info "$(i18n adb_connecting) $connect_host ..."
  if adb connect "$connect_host" 2>&1; then
    sleep 1
    local count
    count=$(get_adb_device_count)
    if [[ "$count" -gt 0 ]]; then
      log_succ "$(i18n adb_connect_success)"
      echo
      adb devices
      return 0
    else
      log_err "$(i18n adb_connect_fail)"
      return 1
    fi
  else
    log_err "$(i18n adb_connect_fail2)"
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
  log_info "$(i18n adb_devices)"
  adb devices -l 2>/dev/null || echo "  ($(i18n adb_not_detected))"
  echo
}

##########  Python 依赖  ##########
install_py_deps() {
  log_info "$(i18n install_py_deps)"
  ensure_setuptools

  if in_termux; then
    pkg_install python-pillow
  else
    python -m pip install --upgrade pillow
  fi

  echo
  echo -e "${YELLOW}╔══════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${YELLOW}║${NC}  ${BOLD}$(i18n openai_install_title)${NC}                       ${YELLOW}║${NC}"
  echo -e "${YELLOW}║${NC}  ${CYAN}$(i18n openai_install_tip)${NC}  ${YELLOW}║${NC}"
  echo -e "${YELLOW}╚══════════════════════════════════════════════════════════════╝${NC}"
  echo

  python -m pip install --upgrade maturin openai requests
}

##########  项目拉取/更新  ##########
clone_or_update() {
  local dir="$HOME/Open-AutoGLM"
  if [[ -d $dir/.git ]]; then
    log_warn "$(i18n clone_detected)"
    read -rp "$(i18n clone_update_ask): " ans
    case "${ans:-n}" in
      [Yy]*)
        log_info "$(i18n clone_updating)"
        git -C "$dir" pull --ff-only || log_warn "$(i18n clone_update_fail)"
        ;;
      *)
        log_info "$(i18n clone_skip)"
        ;;
    esac
  else
    log_info "$(i18n clone_cloning)"
    rm -rf "$dir"
    git clone https://github.com/zai-org/Open-AutoGLM.git "$dir"
  fi

  in_termux && sed -i '/[Pp]illow/d' "$dir/requirements.txt" 2>/dev/null || true
  
  log_info "$(i18n install_project_deps)"
  python -m pip install -r "$dir/requirements.txt"
  
  log_info "$(i18n install_project)"
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

  echo
  echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${CYAN}║${NC}              ${BOLD}$(i18n config_title)${NC}                          ${CYAN}║${NC}"
  echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
  echo
  echo -e "${YELLOW}$(i18n config_tip)${NC}"
  echo

  read -rp "  $(i18n config_base_url) [${DEFAULT_BASE_URL}]: " base_url
  base_url=${base_url:-$DEFAULT_BASE_URL}

  read -rp "  $(i18n config_model) [${DEFAULT_MODEL}]: " model
  model=${model:-$DEFAULT_MODEL}

  read -rp "  $(i18n config_apikey) [${DEFAULT_API_KEY}]: " api_key
  api_key=${api_key:-$DEFAULT_API_KEY}

  read -rp "  $(i18n config_max_steps) [${DEFAULT_MAX_STEPS}]: " max_steps
  max_steps=${max_steps:-$DEFAULT_MAX_STEPS}

  read -rp "  $(i18n config_device_id) []: " device_id
  device_id=${device_id:-$DEFAULT_DEVICE_ID}

  cat > ~/.autoglm/config.sh <<EOF
#!/bin/bash
# AutoGLM Configuration - Generated at $(date)
export PHONE_AGENT_BASE_URL="$base_url"
export PHONE_AGENT_MODEL="$model"
export PHONE_AGENT_API_KEY="$api_key"
export PHONE_AGENT_MAX_STEPS="$max_steps"
export PHONE_AGENT_DEVICE_ID="$device_id"
export PHONE_AGENT_LANG="$LANG_CHOICE"
EOF

  chmod +x ~/.autoglm/config.sh
  grep -q 'source ~/.autoglm/config.sh' ~/.bashrc 2>/dev/null || echo 'source ~/.autoglm/config.sh' >> ~/.bashrc
  
  log_succ "$(i18n config_saved) ~/.autoglm/config.sh"
}

##########  创建启动器脚本  ##########
make_launcher() {
  mkdir -p ~/bin
  
  cat > ~/bin/autoglm <<'LAUNCHER_EOF'
#!/bin/bash
# AutoGLM Smart Control Panel
# Version: 4.6.0 (Full i18n Support)

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

##########  国际化文本  ##########
declare -A I18N

init_i18n() {
  # 主菜单
  I18N["panel_title_cn"]="🤖 AutoGLM 智能启动面板"
  I18N["panel_title_en"]="🤖 AutoGLM Smart Control Panel"
  I18N["panel_subtitle_cn"]="Open-AutoGLM Phone Agent Controller"
  I18N["panel_subtitle_en"]="Open-AutoGLM Phone Agent Controller"
  
  # 当前配置
  I18N["current_config_cn"]="当前配置"
  I18N["current_config_en"]="Current Configuration"
  I18N["api_url_cn"]="API 地址"
  I18N["api_url_en"]="API URL"
  I18N["model_name_cn"]="模型名称"
  I18N["model_name_en"]="Model Name"
  I18N["api_key_cn"]="API Key"
  I18N["api_key_en"]="API Key"
  I18N["max_steps_cn"]="最大步数"
  I18N["max_steps_en"]="Max Steps"
  I18N["device_id_cn"]="设备 ID"
  I18N["device_id_en"]="Device ID"
  I18N["auto_detect_cn"]="自动检测"
  I18N["auto_detect_en"]="Auto Detect"
  I18N["language_cn"]="语言"
  I18N["language_en"]="Language"
  
  # ADB 状态
  I18N["adb_status_cn"]="ADB 状态"
  I18N["adb_status_en"]="ADB Status"
  I18N["adb_connected_cn"]="已连接"
  I18N["adb_connected_en"]="Connected"
  I18N["adb_devices_cn"]="台设备"
  I18N["adb_devices_en"]="device(s)"
  I18N["adb_online_cn"]="台在线"
  I18N["adb_online_en"]="online"
  I18N["adb_total_cn"]="台总计"
  I18N["adb_total_en"]="total"
  I18N["adb_offline_cn"]="均离线/未授权"
  I18N["adb_offline_en"]="all offline/unauthorized"
  I18N["adb_no_device_cn"]="未检测到设备"
  I18N["adb_no_device_en"]="No device detected"
  
  # 主菜单选项
  I18N["menu_main_cn"]="主菜单"
  I18N["menu_main_en"]="Main Menu"
  I18N["menu_start_cn"]="🚀 使用当前配置启动"
  I18N["menu_start_en"]="🚀 Start with Current Config"
  I18N["menu_adb_cn"]="📱 ADB 设备管理"
  I18N["menu_adb_en"]="📱 ADB Device Management"
  I18N["menu_config_cn"]="⚙️  修改 AI 配置"
  I18N["menu_config_en"]="⚙️  Modify AI Configuration"
  I18N["menu_apps_cn"]="📋 查看支持的应用列表"
  I18N["menu_apps_en"]="📋 View Supported Apps"
  I18N["menu_view_config_cn"]="🔍 查看详细配置"
  I18N["menu_view_config_en"]="🔍 View Detailed Config"
  I18N["menu_lang_cn"]="🌐 切换语言 / Switch Language"
  I18N["menu_lang_en"]="🌐 Switch Language / 切换语言"
  I18N["menu_uninstall_cn"]="🗑️  一键卸载"
  I18N["menu_uninstall_en"]="🗑️  Uninstall"
  I18N["menu_exit_cn"]="❌ 退出"
  I18N["menu_exit_en"]="❌ Exit"
  I18N["menu_select_cn"]="请选择"
  I18N["menu_select_en"]="Please select"
  I18N["invalid_choice_cn"]="无效选择"
  I18N["invalid_choice_en"]="Invalid choice"
  I18N["goodbye_cn"]="再见！"
  I18N["goodbye_en"]="Goodbye!"
  
  # ADB Keyboard
  I18N["adb_keyboard_title_cn"]="⚠️  重要提醒：安装 ADB Keyboard"
  I18N["adb_keyboard_title_en"]="⚠️  Important: Install ADB Keyboard"
  I18N["adb_keyboard_desc_cn"]="此工具用于文本输入，必须安装！"
  I18N["adb_keyboard_desc_en"]="This tool is required for text input!"
  I18N["adb_keyboard_download_cn"]="下载地址:"
  I18N["adb_keyboard_download_en"]="Download URL:"
  I18N["adb_keyboard_steps_cn"]="安装步骤:"
  I18N["adb_keyboard_steps_en"]="Installation Steps:"
  I18N["adb_keyboard_step1_cn"]="下载并安装 ADBKeyboard.apk 到安卓设备"
  I18N["adb_keyboard_step1_en"]="Download and install ADBKeyboard.apk on Android device"
  I18N["adb_keyboard_step2_cn"]="进入 设置 → 系统 → 语言和输入法 → 虚拟键盘 → 管理键盘"
  I18N["adb_keyboard_step2_en"]="Go to Settings → System → Language & Input → Virtual Keyboard → Manage"
  I18N["adb_keyboard_step3_cn"]="开启 'ADB Keyboard'"
  I18N["adb_keyboard_step3_en"]="Enable 'ADB Keyboard'"
  I18N["adb_keyboard_step4_cn"]="运行时需切换到 ADB Keyboard 输入法"
  I18N["adb_keyboard_step4_en"]="Switch to ADB Keyboard when running"
  I18N["understood_cn"]="已了解，按回车继续..."
  I18N["understood_en"]="Understood, press Enter to continue..."
  
  # ADB 配置向导
  I18N["adb_wizard_title_cn"]="📱 ADB 无线调试配置向导"
  I18N["adb_wizard_title_en"]="📱 ADB Wireless Debugging Setup Wizard"
  I18N["adb_wizard_steps_cn"]="请按以下步骤操作:"
  I18N["adb_wizard_steps_en"]="Please follow these steps:"
  I18N["adb_wizard_step1_cn"]="确保手机和 Termux 设备在同一 WiFi 网络下"
  I18N["adb_wizard_step1_en"]="Ensure phone and Termux device are on the same WiFi"
  I18N["adb_wizard_step2_cn"]="进入 设置 → 关于手机 → 连续点击版本号 7 次（开启开发者模式）"
  I18N["adb_wizard_step2_en"]="Go to Settings → About Phone → Tap Build Number 7 times"
  I18N["adb_wizard_step3_cn"]="返回 设置 → 系统 → 开发者选项"
  I18N["adb_wizard_step3_en"]="Go back to Settings → System → Developer Options"
  I18N["adb_wizard_step4_cn"]="开启 '无线调试'"
  I18N["adb_wizard_step4_en"]="Enable 'Wireless Debugging'"
  I18N["adb_wizard_step5_cn"]="建议: 将无线调试界面和 Termux 分屏显示"
  I18N["adb_wizard_step5_en"]="Tip: Split screen with Wireless Debugging and Termux"
  I18N["adb_pair_title_cn"]="第一步：配对设备"
  I18N["adb_pair_title_en"]="Step 1: Pair Device"
  I18N["adb_pair_tip_cn"]="点击无线调试界面中的「使用配对码配对」"
  I18N["adb_pair_tip_en"]="Tap 'Pair device with pairing code' in Wireless Debugging"
  I18N["adb_pair_host_cn"]="输入配对码弹窗显示的 IP:端口（如 192.168.1.13:42379）"
  I18N["adb_pair_host_en"]="Enter IP:Port from pairing dialog (e.g. 192.168.1.13:42379)"
  I18N["adb_pair_code_cn"]="输入配对码（6 位数字）"
  I18N["adb_pair_code_en"]="Enter pairing code (6 digits)"
  I18N["adb_pairing_cn"]="正在配对"
  I18N["adb_pairing_en"]="Pairing"
  I18N["adb_pair_success_cn"]="配对成功！"
  I18N["adb_pair_success_en"]="Pairing successful!"
  I18N["adb_pair_fail_cn"]="配对失败，请检查输入！"
  I18N["adb_pair_fail_en"]="Pairing failed, please check input!"
  I18N["adb_connect_title_cn"]="第二步：连接设备"
  I18N["adb_connect_title_en"]="Step 2: Connect Device"
  I18N["adb_connect_tip_cn"]="查看无线调试主界面（不是配对码弹窗）显示的 IP 地址和端口"
  I18N["adb_connect_tip_en"]="Check the IP:Port on Wireless Debugging main screen"
  I18N["adb_connect_host_cn"]="输入无线调试界面的 IP:端口（如 192.168.1.13:5555）"
  I18N["adb_connect_host_en"]="Enter IP:Port from Wireless Debugging (e.g. 192.168.1.13:5555)"
  I18N["adb_connecting_cn"]="正在连接"
  I18N["adb_connecting_en"]="Connecting"
  I18N["adb_connect_success_cn"]="连接成功！设备已就绪！"
  I18N["adb_connect_success_en"]="Connected successfully! Device ready!"
  I18N["adb_connect_warn_cn"]="连接可能未完全成功，请检查设备状态"
  I18N["adb_connect_warn_en"]="Connection may not be complete, please check device status"
  I18N["adb_connect_fail_cn"]="连接失败"
  I18N["adb_connect_fail_en"]="Connection failed"
  I18N["empty_input_cn"]="不能为空！"
  I18N["empty_input_en"]="Cannot be empty!"
  I18N["press_enter_cn"]="按回车返回..."
  I18N["press_enter_en"]="Press Enter to continue..."
  I18N["press_enter_main_cn"]="按回车返回主菜单..."
  I18N["press_enter_main_en"]="Press Enter to return to main menu..."
  
  # 设备列表
  I18N["device_list_title_cn"]="📋 ADB 设备详细列表"
  I18N["device_list_title_en"]="📋 ADB Device List"
  I18N["no_device_cn"]="未检测到任何设备"
  I18N["no_device_en"]="No device detected"
  I18N["device_list_cn"]="设备列表："
  I18N["device_list_en"]="Device List:"
  I18N["col_num_cn"]="序"
  I18N["col_num_en"]="No"
  I18N["col_addr_cn"]="设备地址"
  I18N["col_addr_en"]="Device Address"
  I18N["col_status_cn"]="状态"
  I18N["col_status_en"]="Status"
  I18N["col_model_cn"]="型号"
  I18N["col_model_en"]="Model"
  I18N["col_type_cn"]="类型"
  I18N["col_type_en"]="Type"
  I18N["status_online_cn"]="在线"
  I18N["status_online_en"]="Online"
  I18N["status_offline_cn"]="离线"
  I18N["status_offline_en"]="Offline"
  I18N["status_unauth_cn"]="未授权"
  I18N["status_unauth_en"]="Unauthorized"
  I18N["type_wireless_cn"]="无线"
  I18N["type_wireless_en"]="Wireless"
  I18N["type_usb_cn"]="USB"
  I18N["type_usb_en"]="USB"
  I18N["unknown_model_cn"]="未知型号"
  I18N["unknown_model_en"]="Unknown"
  I18N["current_selected_cn"]="表示当前选中的设备"
  I18N["current_selected_en"]="indicates currently selected device"
  
  # 切换设备
  I18N["switch_device_title_cn"]="🔄 切换 ADB 设备"
  I18N["switch_device_title_en"]="🔄 Switch ADB Device"
  I18N["available_devices_cn"]="可选设备："
  I18N["available_devices_en"]="Available Devices:"
  I18N["current_cn"]="当前"
  I18N["current_en"]="Current"
  I18N["auto_detect_option_cn"]="留空（自动检测，适用于单设备）"
  I18N["auto_detect_option_en"]="Empty (auto-detect, for single device)"
  I18N["cancel_return_cn"]="取消返回"
  I18N["cancel_return_en"]="Cancel and return"
  I18N["select_device_cn"]="请选择要使用的设备"
  I18N["select_device_en"]="Select device to use"
  I18N["auto_detect_mode_cn"]="已设置为自动检测模式"
  I18N["auto_detect_mode_en"]="Set to auto-detect mode"
  I18N["device_status_warn_cn"]="该设备当前状态为"
  I18N["device_status_warn_en"]="Device current status is"
  I18N["may_not_work_cn"]="可能无法正常使用"
  I18N["may_not_work_en"]="may not work properly"
  I18N["still_select_cn"]="是否仍要选择？(y/N)"
  I18N["still_select_en"]="Still select? (y/N)"
  I18N["switched_to_cn"]="已切换到设备"
  I18N["switched_to_en"]="Switched to device"
  
  # 断开设备
  I18N["disconnect_title_cn"]="🔌 断开 ADB 设备"
  I18N["disconnect_title_en"]="🔌 Disconnect ADB Device"
  I18N["connected_devices_cn"]="已连接的设备："
  I18N["connected_devices_en"]="Connected Devices:"
  I18N["disconnect_all_cn"]="断开所有无线设备"
  I18N["disconnect_all_en"]="Disconnect all wireless devices"
  I18N["restart_adb_cn"]="重启 ADB 服务（断开所有设备）"
  I18N["restart_adb_en"]="Restart ADB server (disconnect all)"
  I18N["select_disconnect_cn"]="请选择要断开的设备"
  I18N["select_disconnect_en"]="Select device to disconnect"
  I18N["disconnecting_all_cn"]="断开所有无线设备..."
  I18N["disconnecting_all_en"]="Disconnecting all wireless devices..."
  I18N["all_disconnected_cn"]="已断开所有无线设备"
  I18N["all_disconnected_en"]="All wireless devices disconnected"
  I18N["restart_warn_cn"]="重启 ADB 服务将断开所有设备（包括 USB）"
  I18N["restart_warn_en"]="Restarting ADB will disconnect all devices (including USB)"
  I18N["confirm_restart_cn"]="确认重启？(y/N)"
  I18N["confirm_restart_en"]="Confirm restart? (y/N)"
  I18N["restarting_adb_cn"]="正在重启 ADB 服务..."
  I18N["restarting_adb_en"]="Restarting ADB server..."
  I18N["adb_restarted_cn"]="ADB 服务已重启"
  I18N["adb_restarted_en"]="ADB server restarted"
  I18N["disconnecting_cn"]="断开无线设备"
  I18N["disconnecting_en"]="Disconnecting wireless device"
  I18N["disconnected_cn"]="已断开"
  I18N["disconnected_en"]="Disconnected"
  I18N["usb_cannot_disconnect_cn"]="USB 设备无法通过软件断开"
  I18N["usb_cannot_disconnect_en"]="USB devices cannot be disconnected via software"
  I18N["usb_tip_cn"]="请物理拔除 USB 线缆，或选择 'r' 重启 ADB 服务"
  I18N["usb_tip_en"]="Please unplug USB cable, or select 'r' to restart ADB"
  I18N["cleared_selection_cn"]="已清除当前设备选择"
  I18N["cleared_selection_en"]="Cleared current device selection"
  
  # 快速连接
  I18N["quick_connect_title_cn"]="⚡ 快速连接"
  I18N["quick_connect_title_en"]="⚡ Quick Connect"
  I18N["quick_connect_tip_cn"]="适用于已配对过的设备"
  I18N["quick_connect_tip_en"]="For previously paired devices"
  I18N["enter_ip_port_cn"]="输入设备 IP:端口（如 192.168.1.13:5555）"
  I18N["enter_ip_port_en"]="Enter device IP:Port (e.g. 192.168.1.13:5555)"
  
  # ADB 管理菜单
  I18N["adb_menu_title_cn"]="ADB 设备管理"
  I18N["adb_menu_title_en"]="ADB Device Management"
  I18N["current_device_cn"]="当前选中设备"
  I18N["current_device_en"]="Currently Selected Device"
  I18N["menu_pair_cn"]="📱 配对新设备（配对+连接）"
  I18N["menu_pair_en"]="📱 Pair New Device (pair+connect)"
  I18N["menu_quick_cn"]="⚡ 快速连接（已配对过）"
  I18N["menu_quick_en"]="⚡ Quick Connect (previously paired)"
  I18N["menu_list_cn"]="📋 查看设备详细列表"
  I18N["menu_list_en"]="📋 View Device List"
  I18N["menu_switch_cn"]="🔄 切换活动设备"
  I18N["menu_switch_en"]="🔄 Switch Active Device"
  I18N["menu_disconnect_cn"]="🔌 断开设备连接"
  I18N["menu_disconnect_en"]="🔌 Disconnect Device"
  I18N["menu_keyboard_cn"]="❓ ADB Keyboard 安装说明"
  I18N["menu_keyboard_en"]="❓ ADB Keyboard Install Guide"
  I18N["menu_back_cn"]="↩️  返回主菜单"
  I18N["menu_back_en"]="↩️  Return to Main Menu"
  
  # 修改配置
  I18N["modify_config_title_cn"]="⚙️  修改 AI 配置"
  I18N["modify_config_title_en"]="⚙️  Modify AI Configuration"
  I18N["keep_current_cn"]="直接回车保持当前值不变"
  I18N["keep_current_en"]="Press Enter to keep current value"
  I18N["config_saved_cn"]="配置已保存并生效！"
  I18N["config_saved_en"]="Configuration saved and applied!"
  
  # 查看配置
  I18N["view_config_title_cn"]="🔍 详细配置信息"
  I18N["view_config_title_en"]="🔍 Detailed Configuration"
  I18N["env_config_cn"]="环境变量配置:"
  I18N["env_config_en"]="Environment Variables:"
  I18N["var_name_cn"]="变量名"
  I18N["var_name_en"]="Variable"
  I18N["var_value_cn"]="值"
  I18N["var_value_en"]="Value"
  I18N["config_file_path_cn"]="配置文件路径"
  I18N["config_file_path_en"]="Config File Path"
  I18N["project_dir_cn"]="项目目录"
  I18N["project_dir_en"]="Project Directory"
  
  # 应用列表
  I18N["getting_apps_cn"]="正在获取支持的应用列表..."
  I18N["getting_apps_en"]="Getting supported apps list..."
  I18N["get_apps_fail_cn"]="获取失败，请检查项目是否正确安装"
  I18N["get_apps_fail_en"]="Failed, please check if project is installed correctly"
  I18N["project_not_exist_cn"]="项目目录不存在"
  I18N["project_not_exist_en"]="Project directory does not exist"
  
  # 切换语言
  I18N["switch_lang_title_cn"]="🌐 切换语言 / Switch Language"
  I18N["switch_lang_title_en"]="🌐 Switch Language / 切换语言"
  I18N["current_lang_cn"]="当前语言: 中文"
  I18N["current_lang_en"]="Current Language: English"
  I18N["select_lang_cn"]="请选择语言 / Please select language:"
  I18N["select_lang_en"]="Please select language / 请选择语言:"
  I18N["lang_cn_cn"]="中文 (Chinese)"
  I18N["lang_cn_en"]="中文 (Chinese)"
  I18N["lang_en_cn"]="English"
  I18N["lang_en_en"]="English"
  I18N["lang_saved_cn"]="语言已切换为中文并保存！"
  I18N["lang_saved_en"]="Language switched to English and saved!"
  
  # 启动
  I18N["start_title_cn"]="🚀 启动 AutoGLM"
  I18N["start_title_en"]="🚀 Starting AutoGLM"
  I18N["config_info_cn"]="配置信息:"
  I18N["config_info_en"]="Configuration:"
  I18N["starting_cn"]="正在启动..."
  I18N["starting_en"]="Starting..."
  I18N["no_adb_device_cn"]="未检测到在线的 ADB 设备！"
  I18N["no_adb_device_en"]="No online ADB device detected!"
  I18N["config_adb_first_cn"]="请先配置 ADB 无线调试（菜单选项 2）"
  I18N["config_adb_first_en"]="Please configure ADB wireless debugging first (menu option 2)"
  I18N["config_adb_now_cn"]="是否现在配置 ADB？(Y/n)"
  I18N["config_adb_now_en"]="Configure ADB now? (Y/n)"
  I18N["project_not_found_cn"]="项目目录不存在"
  I18N["project_not_found_en"]="Project directory not found"
  I18N["reinstall_tip_cn"]="请重新运行 deploy.sh 安装"
  I18N["reinstall_tip_en"]="Please re-run deploy.sh to install"
  
  # 卸载
  I18N["uninstall_title_cn"]="🗑️  一键卸载"
  I18N["uninstall_title_en"]="🗑️  Uninstall"
  I18N["uninstall_basic_cn"]="🧹 卸载 Open-AutoGLM + autoglm 控制面板"
  I18N["uninstall_basic_en"]="🧹 Uninstall Open-AutoGLM + autoglm panel"
  I18N["uninstall_basic_desc_cn"]="可选择性删除：pip依赖、项目目录、命令和配置"
  I18N["uninstall_basic_desc_en"]="Optionally remove: pip deps, project dir, command and config"
  I18N["uninstall_full_cn"]="💣 完全卸载（包括运行环境）"
  I18N["uninstall_full_en"]="💣 Full Uninstall (including runtime)"
  I18N["uninstall_full_desc_cn"]="除上述内容外，还可选择卸载："
  I18N["uninstall_full_desc_en"]="Besides above, optionally remove:"
  I18N["uninstall_full_desc2_cn"]="核心pip包、镜像配置、系统包等"
  I18N["uninstall_full_desc2_en"]="core pip packages, mirror config, system packages, etc."
  I18N["select_uninstall_cn"]="请选择卸载方式："
  I18N["select_uninstall_en"]="Select uninstall method:"
  
  I18N["uninstall_guide_cn"]="此选项将引导您逐项选择要卸载的内容"
  I18N["uninstall_guide_en"]="This will guide you through each item to uninstall"
  I18N["step_cn"]="第"
  I18N["step_en"]="Step"
  I18N["step_suffix_cn"]="步"
  I18N["step_suffix_en"]=""
  I18N["pip_deps_cn"]="pip 依赖包"
  I18N["pip_deps_en"]="pip dependencies"
  I18N["detected_req_cn"]="检测到项目依赖文件"
  I18N["detected_req_en"]="Detected project requirements file"
  I18N["uninstall_pip_ask_cn"]="是否卸载项目安装的 pip 依赖包？"
  I18N["uninstall_pip_ask_en"]="Uninstall project pip dependencies?"
  I18N["skip_pip_cn"]="跳过 pip 依赖卸载"
  I18N["skip_pip_en"]="Skipping pip dependencies uninstall"
  I18N["req_not_found_cn"]="未找到 requirements.txt，跳过此步骤"
  I18N["req_not_found_en"]="requirements.txt not found, skipping"
  I18N["uninstall_main_ask_cn"]="是否卸载项目本体包（open-autoglm）？"
  I18N["uninstall_main_ask_en"]="Uninstall project package (open-autoglm)?"
  I18N["main_uninstalled_cn"]="项目本体已卸载"
  I18N["main_uninstalled_en"]="Project package uninstalled"
  
  I18N["project_dir_cn"]="项目目录"
  I18N["project_dir_en"]="Project Directory"
  I18N["delete_project_ask_cn"]="是否删除 Open-AutoGLM 项目目录？"
  I18N["delete_project_ask_en"]="Delete Open-AutoGLM project directory?"
  I18N["deleted_cn"]="已删除"
  I18N["deleted_en"]="Deleted"
  I18N["keep_project_cn"]="保留项目目录"
  I18N["keep_project_en"]="Keeping project directory"
  I18N["dir_not_exist_cn"]="项目目录不存在，跳过此步骤"
  I18N["dir_not_exist_en"]="Project directory not found, skipping"
  
  I18N["command_config_cn"]="autoglm 命令与配置文件"
  I18N["command_config_en"]="autoglm command and config files"
  I18N["includes_cn"]="包含以下内容："
  I18N["includes_en"]="Includes:"
  I18N["autoglm_cmd_cn"]="autoglm 命令"
  I18N["autoglm_cmd_en"]="autoglm command"
  I18N["config_dir_cn"]="配置文件目录"
  I18N["config_dir_en"]="Config directory"
  I18N["bashrc_env_cn"]=".bashrc 中的环境变量配置"
  I18N["bashrc_env_en"]="Environment variables in .bashrc"
  I18N["delete_cmd_ask_cn"]="是否删除 autoglm 命令、配置文件和环境变量？"
  I18N["delete_cmd_ask_en"]="Delete autoglm command, config and environment variables?"
  I18N["cleaned_bashrc_cn"]="已清理 .bashrc 中的环境变量"
  I18N["cleaned_bashrc_en"]="Cleaned environment variables from .bashrc"
  I18N["keep_cmd_cn"]="保留 autoglm 命令和配置文件"
  I18N["keep_cmd_en"]="Keeping autoglm command and config files"
  
  I18N["core_pip_cn"]="部署时安装的核心 pip 包"
  I18N["core_pip_en"]="Core pip packages installed during deployment"
  I18N["core_pip_list_cn"]="包含以下包："
  I18N["core_pip_list_en"]="Includes:"
  I18N["uninstall_core_ask_cn"]="是否卸载这些核心 pip 包？"
  I18N["uninstall_core_ask_en"]="Uninstall these core pip packages?"
  I18N["uninstalling_core_cn"]="卸载核心 pip 包..."
  I18N["uninstalling_core_en"]="Uninstalling core pip packages..."
  I18N["core_uninstalled_cn"]="核心 pip 包已卸载"
  I18N["core_uninstalled_en"]="Core pip packages uninstalled"
  I18N["keep_core_cn"]="保留核心 pip 包"
  I18N["keep_core_en"]="Keeping core pip packages"
  
  I18N["pip_mirror_cn"]="pip 镜像配置"
  I18N["pip_mirror_en"]="pip mirror configuration"
  I18N["current_pip_mirror_cn"]="当前 pip 镜像"
  I18N["current_pip_mirror_en"]="Current pip mirror"
  I18N["delete_pip_mirror_ask_cn"]="是否删除 pip 镜像配置？"
  I18N["delete_pip_mirror_ask_en"]="Delete pip mirror configuration?"
  I18N["pip_mirror_deleted_cn"]="pip 镜像配置已删除"
  I18N["pip_mirror_deleted_en"]="pip mirror configuration deleted"
  I18N["keep_pip_mirror_cn"]="保留 pip 镜像配置"
  I18N["keep_pip_mirror_en"]="Keeping pip mirror configuration"
  I18N["no_pip_mirror_cn"]="未检测到 pip 镜像配置，跳过此步骤"
  I18N["no_pip_mirror_en"]="No pip mirror config detected, skipping"
  
  I18N["cargo_mirror_cn"]="Cargo 镜像配置"
  I18N["cargo_mirror_en"]="Cargo mirror configuration"
  I18N["detected_cargo_cn"]="检测到 Cargo 配置"
  I18N["detected_cargo_en"]="Detected Cargo config"
  I18N["delete_cargo_ask_cn"]="是否删除 Cargo 镜像配置？"
  I18N["delete_cargo_ask_en"]="Delete Cargo mirror configuration?"
  I18N["cargo_deleted_cn"]="Cargo 镜像配置已删除"
  I18N["cargo_deleted_en"]="Cargo mirror configuration deleted"
  I18N["keep_cargo_cn"]="保留 Cargo 镜像配置"
  I18N["keep_cargo_en"]="Keeping Cargo mirror configuration"
  I18N["no_cargo_cn"]="未检测到 Cargo 镜像配置，跳过此步骤"
  I18N["no_cargo_en"]="No Cargo mirror config detected, skipping"
  
  I18N["termux_pkg_cn"]="Termux 系统包"
  I18N["termux_pkg_en"]="Termux System Packages"
  I18N["warn_affect_cn"]="警告：卸载系统包可能影响其他程序！"
  I18N["warn_affect_en"]="Warning: Uninstalling system packages may affect other programs!"
  I18N["uninstall_pillow_cn"]="是否卸载 python-pillow？"
  I18N["uninstall_pillow_en"]="Uninstall python-pillow?"
  I18N["pillow_uninstalled_cn"]="python-pillow 已卸载"
  I18N["pillow_uninstalled_en"]="python-pillow uninstalled"
  I18N["uninstall_rust_cn"]="是否卸载 Rust 编译工具链（rust, binutils）？"
  I18N["uninstall_rust_en"]="Uninstall Rust toolchain (rust, binutils)?"
  I18N["rust_uninstalled_cn"]="Rust 工具链已卸载"
  I18N["rust_uninstalled_en"]="Rust toolchain uninstalled"
  I18N["uninstall_adb_cn"]="是否卸载 ADB 工具（android-tools）？"
  I18N["uninstall_adb_en"]="Uninstall ADB tools (android-tools)?"
  I18N["adb_uninstalled_cn"]="ADB 工具已卸载"
  I18N["adb_uninstalled_en"]="ADB tools uninstalled"
  
  I18N["uninstall_complete_cn"]="✅ 卸载操作完成！"
  I18N["uninstall_complete_en"]="✅ Uninstall complete!"
  I18N["reopen_terminal_cn"]="提示: 请重新打开终端以使更改生效"
  I18N["reopen_terminal_en"]="Tip: Please reopen terminal for changes to take effect"
  I18N["no_action_cn"]="未执行任何卸载操作"
  I18N["no_action_en"]="No uninstall action performed"
  I18N["cmd_deleted_exit_cn"]="autoglm 命令已删除，即将退出..."
  I18N["cmd_deleted_exit_en"]="autoglm command deleted, exiting..."
  
  I18N["will_uninstall_cn"]="将卸载以下 pip 依赖包："
  I18N["will_uninstall_en"]="Will uninstall the following pip packages:"
  I18N["project_main_cn"]="项目本体"
  I18N["project_main_en"]="project package"
  I18N["uninstalling_cn"]="卸载"
  I18N["uninstalling_en"]="Uninstalling"
  I18N["pip_uninstall_done_cn"]="pip 依赖卸载完成"
  I18N["pip_uninstall_done_en"]="pip dependencies uninstall complete"
  
  # Help
  I18N["help_title_cn"]="AutoGLM - 智能手机控制代理"
  I18N["help_title_en"]="AutoGLM - Smart Phone Control Agent"
  I18N["help_usage_cn"]="用法:"
  I18N["help_usage_en"]="Usage:"
  I18N["help_menu_cn"]="打开交互式菜单"
  I18N["help_menu_en"]="Open interactive menu"
  I18N["help_setup_adb_cn"]="ADB 设备管理"
  I18N["help_setup_adb_en"]="ADB device management"
  I18N["help_devices_cn"]="查看设备列表"
  I18N["help_devices_en"]="View device list"
  I18N["help_switch_cn"]="切换 ADB 设备"
  I18N["help_switch_en"]="Switch ADB device"
  I18N["help_disconnect_cn"]="断开设备连接"
  I18N["help_disconnect_en"]="Disconnect device"
  I18N["help_reconfig_cn"]="修改配置"
  I18N["help_reconfig_en"]="Modify configuration"
  I18N["help_apps_cn"]="查看支持的应用"
  I18N["help_apps_en"]="View supported apps"
  I18N["help_uninstall_cn"]="卸载"
  I18N["help_uninstall_en"]="Uninstall"
  I18N["help_params_cn"]="参数:"
  I18N["help_params_en"]="Parameters:"
  I18N["help_base_url_cn"]="设置 API 地址"
  I18N["help_base_url_en"]="Set API URL"
  I18N["help_model_cn"]="设置模型名称"
  I18N["help_model_en"]="Set model name"
  I18N["help_apikey_cn"]="设置 API Key"
  I18N["help_apikey_en"]="Set API Key"
  I18N["help_max_steps_cn"]="设置最大步数"
  I18N["help_max_steps_en"]="Set max steps"
  I18N["help_device_id_cn"]="设置 ADB 设备 ID"
  I18N["help_device_id_en"]="Set ADB device ID"
  I18N["help_lang_cn"]="设置语言"
  I18N["help_lang_en"]="Set language"
  I18N["unknown_param_cn"]="未知参数"
  I18N["unknown_param_en"]="Unknown parameter"
  I18N["use_help_cn"]="使用 --help 查看帮助"
  I18N["use_help_en"]="Use --help for help"
}

# 获取国际化文本
i18n() {
  local key="${1}_${PHONE_AGENT_LANG:-cn}"
  echo "${I18N[$key]:-$1}"
}

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
  init_i18n
}

##########  保存配置  ##########
save_config() {
  mkdir -p ~/.autoglm
  cat > "$CONFIG_FILE" <<EOF
#!/bin/bash
# AutoGLM Configuration - Generated at $(date)
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
  echo -e "${PURPLE}║${NC}      ${BOLD}${CYAN}$(i18n panel_title)${NC}                               ${PURPLE}║${NC}"
  echo -e "${PURPLE}║${NC}      ${GREEN}$(i18n panel_subtitle)${NC}                    ${PURPLE}║${NC}"
  echo -e "${PURPLE}╚══════════════════════════════════════════════════════════════╝${NC}"
  echo
}

##########  显示当前配置  ##########
show_current_config() {
  echo -e "${CYAN}━━━ $(i18n current_config) ━━━${NC}"
  echo -e "  ${BLUE}$(i18n api_url)${NC}   : ${GREEN}$PHONE_AGENT_BASE_URL${NC}"
  echo -e "  ${BLUE}$(i18n model_name)${NC}   : ${GREEN}$PHONE_AGENT_MODEL${NC}"
  echo -e "  ${BLUE}$(i18n api_key)${NC}    : ${GREEN}${PHONE_AGENT_API_KEY:0:12}...${NC}"
  echo -e "  ${BLUE}$(i18n max_steps)${NC}   : ${GREEN}$PHONE_AGENT_MAX_STEPS${NC}"
  echo -e "  ${BLUE}$(i18n device_id)${NC}    : ${GREEN}${PHONE_AGENT_DEVICE_ID:-$(i18n auto_detect)}${NC}"
  echo -e "  ${BLUE}$(i18n language)${NC}       : ${GREEN}$PHONE_AGENT_LANG${NC}"
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
parse_device_info() {
  local line="$1"
  local serial status model device_type
  
  serial=$(echo "$line" | awk '{print $1}')
  status=$(echo "$line" | awk '{print $2}')
  
  model=$(echo "$line" | grep -oP 'model:\K[^ ]+' || echo "$(i18n unknown_model)")
  
  if [[ "$serial" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:[0-9]+$ ]]; then
    device_type="$(i18n type_wireless)"
  else
    device_type="$(i18n type_usb)"
  fi
  
  echo "${serial}|${status}|${model}|${device_type}"
}

##########  获取状态显示文字  ##########
get_status_display() {
  local status="$1"
  case "$status" in
    device)
      echo -e "${GREEN}$(i18n status_online)${NC}"
      ;;
    offline)
      echo -e "${RED}$(i18n status_offline)${NC}"
      ;;
    unauthorized)
      echo -e "${YELLOW}$(i18n status_unauth)${NC}"
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
      echo -e "${GREEN}━━━ $(i18n adb_status): ✓ ${online_count} $(i18n adb_online)${NC} ${YELLOW}/ ${all_count} $(i18n adb_total) ━━━${NC}"
    else
      echo -e "${GREEN}━━━ $(i18n adb_status): ✓ $(i18n adb_connected) ${online_count} $(i18n adb_devices) ━━━${NC}"
    fi
  elif [[ "$all_count" -gt 0 ]]; then
    echo -e "${YELLOW}━━━ $(i18n adb_status): ⚠ ${all_count} $(i18n adb_devices)（$(i18n adb_offline)）━━━${NC}"
  else
    echo -e "${RED}━━━ $(i18n adb_status): ✗ $(i18n adb_no_device) ━━━${NC}"
  fi
  echo
}

##########  显示主菜单  ##########
show_main_menu() {
  show_header
  show_adb_status
  show_current_config
  
  echo -e "${YELLOW}━━━ $(i18n menu_main) ━━━${NC}"
  echo
  echo -e "  ${GREEN}1.${NC} $(i18n menu_start)"
  echo -e "  ${GREEN}2.${NC} $(i18n menu_adb)"
  echo -e "  ${GREEN}3.${NC} $(i18n menu_config)"
  echo -e "  ${GREEN}4.${NC} $(i18n menu_apps)"
  echo -e "  ${GREEN}5.${NC} $(i18n menu_view_config)"
  echo -e "  ${GREEN}6.${NC} $(i18n menu_lang)"
  echo -e "  ${GREEN}7.${NC} $(i18n menu_uninstall)"
  echo -e "  ${GREEN}0.${NC} $(i18n menu_exit)"
  echo
}

##########  ADB Keyboard 提醒  ##########
remind_adb_keyboard() {
  show_header
  echo -e "${YELLOW}╔══════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${YELLOW}║${NC}          ${BOLD}${RED}$(i18n adb_keyboard_title)${NC}                     ${YELLOW}║${NC}"
  echo -e "${YELLOW}╚══════════════════════════════════════════════════════════════╝${NC}"
  echo
  echo -e "${CYAN}$(i18n adb_keyboard_desc)${NC}"
  echo
  echo -e "${BLUE}$(i18n adb_keyboard_download)${NC}"
  echo -e "  ${GREEN}https://github.com/senzhk/ADBKeyBoard/blob/master/ADBKeyboard.apk${NC}"
  echo
  echo -e "${BLUE}$(i18n adb_keyboard_steps)${NC}"
  echo -e "  ${GREEN}1.${NC} $(i18n adb_keyboard_step1)"
  echo -e "  ${GREEN}2.${NC} $(i18n adb_keyboard_step2)"
  echo -e "  ${GREEN}3.${NC} $(i18n adb_keyboard_step3)"
  echo -e "  ${GREEN}4.${NC} $(i18n adb_keyboard_step4)"
  echo
  read -rp "$(i18n understood) "
}

##########  配置 ADB 无线调试  ##########
configure_adb_wireless() {
  show_header
  echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${CYAN}║${NC}              ${BOLD}$(i18n adb_wizard_title)${NC}                         ${CYAN}║${NC}"
  echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
  echo
  echo -e "${BLUE}$(i18n adb_wizard_steps)${NC}"
  echo -e "  ${GREEN}1.${NC} $(i18n adb_wizard_step1)"
  echo -e "  ${GREEN}2.${NC} $(i18n adb_wizard_step2)"
  echo -e "  ${GREEN}3.${NC} $(i18n adb_wizard_step3)"
  echo -e "  ${GREEN}4.${NC} $(i18n adb_wizard_step4)"
  echo -e "  ${GREEN}5.${NC} ${CYAN}$(i18n adb_wizard_step5)${NC}"
  echo
  
  echo -e "${YELLOW}━━━ $(i18n adb_pair_title) ━━━${NC}"
  echo -e "${CYAN}$(i18n adb_pair_tip)${NC}"
  echo
  read -rp "  $(i18n adb_pair_host): " pair_host
  if [[ -z "$pair_host" ]]; then
    echo -e "${RED}[ERROR] IP:Port $(i18n empty_input)${NC}"
    read -rp "$(i18n press_enter) "
    return 1
  fi
  
  read -rp "  $(i18n adb_pair_code): " pair_code
  if [[ -z "$pair_code" ]]; then
    echo -e "${RED}[ERROR] $(i18n adb_pair_code) $(i18n empty_input)${NC}"
    read -rp "$(i18n press_enter) "
    return 1
  fi
  
  echo -e "${BLUE}[INFO]${NC} $(i18n adb_pairing) $pair_host ..."
  if adb pair "$pair_host" "$pair_code" 2>&1; then
    echo -e "${GREEN}[SUCC]${NC} $(i18n adb_pair_success)"
  else
    echo -e "${RED}[ERROR]${NC} $(i18n adb_pair_fail)"
    read -rp "$(i18n press_enter) "
    return 1
  fi
  
  echo
  echo -e "${YELLOW}━━━ $(i18n adb_connect_title) ━━━${NC}"
  echo -e "${CYAN}$(i18n adb_connect_tip)${NC}"
  echo
  read -rp "  $(i18n adb_connect_host): " connect_host
  if [[ -z "$connect_host" ]]; then
    echo -e "${RED}[ERROR] IP:Port $(i18n empty_input)${NC}"
    read -rp "$(i18n press_enter) "
    return 1
  fi
  
  echo -e "${BLUE}[INFO]${NC} $(i18n adb_connecting) $connect_host ..."
  if adb connect "$connect_host" 2>&1; then
    sleep 1
    local count
    count=$(get_adb_device_count)
    if [[ "$count" -gt 0 ]]; then
      echo
      echo -e "${GREEN}[SUCC]${NC} $(i18n adb_connect_success)"
      echo
      adb devices -l
      echo
      read -rp "$(i18n press_enter) "
      return 0
    fi
  fi
  
  echo -e "${RED}[ERROR]${NC} $(i18n adb_connect_fail)"
  read -rp "$(i18n press_enter) "
  return 1
}

##########  显示设备详细列表  ##########
show_device_list() {
  show_header
  echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${CYAN}║${NC}              ${BOLD}$(i18n device_list_title)${NC}                              ${CYAN}║${NC}"
  echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
  echo
  
  local all_count
  all_count=$(get_adb_all_device_count)
  
  if [[ "$all_count" -eq 0 ]]; then
    echo -e "${YELLOW}$(i18n no_device)${NC}"
    echo
    read -rp "$(i18n press_enter) "
    return
  fi
  
  echo -e "${BLUE}$(i18n device_list)${NC}"
  echo -e "┌────┬────────────────────────┬──────────┬────────────────┬────────┐"
  printf "│ %-2s │ %-22s │ %-8s │ %-14s │ %-6s │\n" "$(i18n col_num)" "$(i18n col_addr)" "$(i18n col_status)" "$(i18n col_model)" "$(i18n col_type)"
  echo -e "├────┼────────────────────────┼──────────┼────────────────┼────────┤"
  
  local i=1
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    local info serial status model dtype status_display
    info=$(parse_device_info "$line")
    IFS='|' read -r serial status model dtype <<< "$info"
    status_display=$(get_status_display "$status")
    
    [[ ${#serial} -gt 22 ]] && serial="${serial:0:19}..."
    [[ ${#model} -gt 14 ]] && model="${model:0:11}..."
    
    local marker=""
    if [[ "$serial" == "${PHONE_AGENT_DEVICE_ID:-}" ]]; then
      marker="${GREEN}*${NC}"
    fi
    
    printf "│ ${GREEN}%-2s${NC} │ %-22s │ %b │ %-14s │ %-6s │%b\n" "$i" "$serial" "$status_display" "$model" "$dtype" "$marker"
    ((i++))
  done < <(adb devices -l 2>/dev/null | awk 'NR>1 && NF>=2 && $1!=""')
  
  echo -e "└────┴────────────────────────┴──────────┴────────────────┴────────┘"
  
  if [[ -n "${PHONE_AGENT_DEVICE_ID:-}" ]]; then
    echo -e "\n${GREEN}*${NC} $(i18n current_selected)"
  fi
  echo
  read -rp "$(i18n press_enter) "
}

##########  切换 ADB 设备  ##########
switch_adb_device() {
  show_header
  echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${CYAN}║${NC}              ${BOLD}$(i18n switch_device_title)${NC}                                 ${CYAN}║${NC}"
  echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
  echo
  
  local all_count
  all_count=$(get_adb_all_device_count)
  
  if [[ "$all_count" -eq 0 ]]; then
    echo -e "${RED}[ERROR]${NC} $(i18n no_device)！"
    echo -e "${YELLOW}$(i18n config_adb_first)${NC}"
    echo
    read -rp "$(i18n press_enter) "
    return 1
  fi
  
  echo -e "${BLUE}$(i18n available_devices)${NC}"
  echo -e "${CYAN}────────────────────────────────────────────────────────────────${NC}"
  
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
      marker=" ${GREEN}[$(i18n current)]${NC}"
    fi
    
    echo -e "  ${GREEN}$i.${NC} $serial - ${CYAN}$model${NC} ($dtype) [${status_display}]${marker}"
    ((i++))
  done < <(adb devices -l 2>/dev/null | awk 'NR>1 && NF>=2 && $1!=""')
  
  echo -e "${CYAN}────────────────────────────────────────────────────────────────${NC}"
  echo
  echo -e "  ${GREEN}0.${NC} $(i18n auto_detect_option)"
  echo -e "  ${GREEN}c.${NC} $(i18n cancel_return)"
  echo
  
  read -rp "$(i18n select_device) [1-$((i-1))/0/c]: " choice
  
  case "$choice" in
    c|C)
      return 0
      ;;
    0)
      PHONE_AGENT_DEVICE_ID=""
      save_config
      echo -e "${GREEN}[SUCC]${NC} $(i18n auto_detect_mode)"
      read -rp "$(i18n press_enter) "
      ;;
    *)
      if [[ "$choice" =~ ^[0-9]+$ ]] && [[ "$choice" -ge 1 ]] && [[ "$choice" -le "${#devices[@]}" ]]; then
        local idx=$((choice-1))
        local selected_device="${devices[$idx]}"
        local selected_status="${statuses[$idx]}"
        
        if [[ "$selected_status" != "device" ]]; then
          echo -e "${YELLOW}[WARN]${NC} $(i18n device_status_warn) ${selected_status}, $(i18n may_not_work)"
          read -rp "$(i18n still_select): " confirm
          if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
            return 0
          fi
        fi
        
        PHONE_AGENT_DEVICE_ID="$selected_device"
        save_config
        echo -e "${GREEN}[SUCC]${NC} $(i18n switched_to): ${CYAN}$PHONE_AGENT_DEVICE_ID${NC}"
        read -rp "$(i18n press_enter) "
      else
        echo -e "${RED}$(i18n invalid_choice)${NC}"
        read -rp "$(i18n press_enter) "
      fi
      ;;
  esac
}

##########  断开指定设备  ##########
disconnect_device() {
  show_header
  echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${CYAN}║${NC}              ${BOLD}$(i18n disconnect_title)${NC}                                 ${CYAN}║${NC}"
  echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
  echo
  
  local all_count
  all_count=$(get_adb_all_device_count)
  
  if [[ "$all_count" -eq 0 ]]; then
    echo -e "${YELLOW}$(i18n no_device)${NC}"
    echo
    read -rp "$(i18n press_enter) "
    return
  fi
  
  echo -e "${BLUE}$(i18n connected_devices)${NC}"
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
  echo -e "  ${GREEN}a.${NC} $(i18n disconnect_all)"
  echo -e "  ${GREEN}r.${NC} $(i18n restart_adb)"
  echo -e "  ${GREEN}c.${NC} $(i18n cancel_return)"
  echo
  
  read -rp "$(i18n select_disconnect) [1-$((i-1))/a/r/c]: " choice
  
  case "$choice" in
    c|C)
      return 0
      ;;
    a|A)
      echo -e "${BLUE}[INFO]${NC} $(i18n disconnecting_all)"
      adb disconnect 2>/dev/null || true
      echo -e "${GREEN}[SUCC]${NC} $(i18n all_disconnected)"
      sleep 1
      adb devices
      read -rp "$(i18n press_enter) "
      ;;
    r|R)
      echo -e "${YELLOW}[WARN]${NC} $(i18n restart_warn)"
      read -rp "$(i18n confirm_restart): " confirm
      if [[ "$confirm" =~ ^[Yy]$ ]]; then
        echo -e "${BLUE}[INFO]${NC} $(i18n restarting_adb)"
        adb kill-server 2>/dev/null || true
        sleep 1
        adb start-server 2>/dev/null || true
        echo -e "${GREEN}[SUCC]${NC} $(i18n adb_restarted)"
        sleep 1
        adb devices
      fi
      read -rp "$(i18n press_enter) "
      ;;
    *)
      if [[ "$choice" =~ ^[0-9]+$ ]] && [[ "$choice" -ge 1 ]] && [[ "$choice" -le "${#devices[@]}" ]]; then
        local idx=$((choice-1))
        local selected_device="${devices[$idx]}"
        local selected_type="${dtypes[$idx]}"
        
        if [[ "$selected_type" == "$(i18n type_wireless)" ]]; then
          echo -e "${BLUE}[INFO]${NC} $(i18n disconnecting): $selected_device"
          adb disconnect "$selected_device" 2>&1
          echo -e "${GREEN}[SUCC]${NC} $(i18n disconnected): $selected_device"
          
          if [[ "$selected_device" == "${PHONE_AGENT_DEVICE_ID:-}" ]]; then
            PHONE_AGENT_DEVICE_ID=""
            save_config
            echo -e "${YELLOW}[INFO]${NC} $(i18n cleared_selection)"
          fi
        else
          echo -e "${YELLOW}[WARN]${NC} $(i18n usb_cannot_disconnect)"
          echo -e "${CYAN}$(i18n usb_tip)${NC}"
        fi
        read -rp "$(i18n press_enter) "
      else
        echo -e "${RED}$(i18n invalid_choice)${NC}"
        read -rp "$(i18n press_enter) "
      fi
      ;;
  esac
}

##########  快速连接设备  ##########
quick_connect() {
  show_header
  echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${CYAN}║${NC}              ${BOLD}$(i18n quick_connect_title)${NC}                                     ${CYAN}║${NC}"
  echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
  echo
  echo -e "${YELLOW}$(i18n quick_connect_tip)${NC}"
  echo
  read -rp "$(i18n enter_ip_port): " connect_host
  
  if [[ -z "$connect_host" ]]; then
    echo -e "${RED}[ERROR]${NC} IP:Port $(i18n empty_input)"
    read -rp "$(i18n press_enter) "
    return 1
  fi
  
  echo -e "${BLUE}[INFO]${NC} $(i18n adb_connecting) $connect_host ..."
  if adb connect "$connect_host" 2>&1; then
    sleep 1
    local count
    count=$(get_adb_device_count)
    if [[ "$count" -gt 0 ]]; then
      echo -e "${GREEN}[SUCC]${NC} $(i18n adb_connect_success)"
      echo
      adb devices -l
    else
      echo -e "${YELLOW}[WARN]${NC} $(i18n adb_connect_warn)"
      adb devices -l
    fi
  else
    echo -e "${RED}[ERROR]${NC} $(i18n adb_connect_fail)"
  fi
  echo
  read -rp "$(i18n press_enter) "
}

##########  ADB 设备管理菜单  ##########
adb_menu() {
  while true; do
    show_header
    show_adb_status
    
    if [[ -n "${PHONE_AGENT_DEVICE_ID:-}" ]]; then
      echo -e "${BLUE}$(i18n current_device):${NC} ${GREEN}$PHONE_AGENT_DEVICE_ID${NC}"
      echo
    fi
    
    echo -e "${YELLOW}━━━ $(i18n adb_menu_title) ━━━${NC}"
    echo
    echo -e "  ${GREEN}1.${NC} $(i18n menu_pair)"
    echo -e "  ${GREEN}2.${NC} $(i18n menu_quick)"
    echo -e "  ${GREEN}3.${NC} $(i18n menu_list)"
    echo -e "  ${GREEN}4.${NC} $(i18n menu_switch)"
    echo -e "  ${GREEN}5.${NC} $(i18n menu_disconnect)"
    echo -e "  ${GREEN}6.${NC} $(i18n menu_keyboard)"
    echo -e "  ${GREEN}0.${NC} $(i18n menu_back)"
    echo
    read -rp "$(i18n menu_select) [0-6]: " choice
    
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
        echo -e "${RED}$(i18n invalid_choice)${NC}"
        sleep 1
        ;;
    esac
  done
}

##########  修改 AI 配置  ##########
modify_config() {
  show_header
  echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${CYAN}║${NC}              ${BOLD}$(i18n modify_config_title)${NC}                                  ${CYAN}║${NC}"
  echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
  echo
  echo -e "${YELLOW}$(i18n keep_current)${NC}"
  echo
  
  local new_val
  
  read -rp "  $(i18n api_url) [$PHONE_AGENT_BASE_URL]: " new_val
  [[ -n "$new_val" ]] && PHONE_AGENT_BASE_URL="$new_val"
  
  read -rp "  $(i18n model_name) [$PHONE_AGENT_MODEL]: " new_val
  [[ -n "$new_val" ]] && PHONE_AGENT_MODEL="$new_val"
  
  read -rp "  $(i18n api_key) [$PHONE_AGENT_API_KEY]: " new_val
  [[ -n "$new_val" ]] && PHONE_AGENT_API_KEY="$new_val"
  
  read -rp "  $(i18n max_steps) [$PHONE_AGENT_MAX_STEPS]: " new_val
  [[ -n "$new_val" ]] && PHONE_AGENT_MAX_STEPS="$new_val"
  
  read -rp "  $(i18n device_id) [${PHONE_AGENT_DEVICE_ID:-$(i18n auto_detect)}]: " new_val
  PHONE_AGENT_DEVICE_ID="$new_val"
  
  save_config
  
  echo
  echo -e "${GREEN}[SUCC]${NC} $(i18n config_saved)"
  read -rp "$(i18n press_enter_main) "
}

##########  查看详细配置  ##########
view_config() {
  show_header
  echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${CYAN}║${NC}              ${BOLD}$(i18n view_config_title)${NC}                                 ${CYAN}║${NC}"
  echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
  echo
  echo -e "${BLUE}$(i18n env_config)${NC}"
  echo -e "┌────────────────────────┬────────────────────────────────────┐"
  printf "│ %-22s │ %-34s │\n" "$(i18n var_name)" "$(i18n var_value)"
  echo -e "├────────────────────────┼────────────────────────────────────┤"
  printf "│ %-22s │ %-34s │\n" "PHONE_AGENT_BASE_URL" "$PHONE_AGENT_BASE_URL"
  printf "│ %-22s │ %-34s │\n" "PHONE_AGENT_MODEL" "$PHONE_AGENT_MODEL"
  printf "│ %-22s │ %-34s │\n" "PHONE_AGENT_API_KEY" "${PHONE_AGENT_API_KEY:0:20}..."
  printf "│ %-22s │ %-34s │\n" "PHONE_AGENT_MAX_STEPS" "$PHONE_AGENT_MAX_STEPS"
  printf "│ %-22s │ %-34s │\n" "PHONE_AGENT_DEVICE_ID" "${PHONE_AGENT_DEVICE_ID:-$(i18n auto_detect)}"
  printf "│ %-22s │ %-34s │\n" "PHONE_AGENT_LANG" "$PHONE_AGENT_LANG"
  echo -e "└────────────────────────┴────────────────────────────────────┘"
  echo
  echo -e "${BLUE}$(i18n config_file_path):${NC} $CONFIG_FILE"
  echo -e "${BLUE}$(i18n project_dir):${NC} $AUTOGLM_DIR"
  echo
  read -rp "$(i18n press_enter_main) "
}

##########  查看支持的应用  ##########
list_apps() {
  show_header
  echo -e "${CYAN}$(i18n getting_apps)${NC}"
  echo
  if [[ -d "$AUTOGLM_DIR" ]]; then
    cd "$AUTOGLM_DIR"
    python main.py --list-apps 2>/dev/null || echo -e "${RED}$(i18n get_apps_fail)${NC}"
  else
    echo -e "${RED}$(i18n project_not_exist): $AUTOGLM_DIR${NC}"
  fi
  echo
  read -rp "$(i18n press_enter_main) "
}

##########  切换语言  ##########
switch_language() {
  show_header
  echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${CYAN}║${NC}              ${BOLD}$(i18n switch_lang_title)${NC}                ${CYAN}║${NC}"
  echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
  echo
  echo -e "${BLUE}$(i18n current_lang)${NC}"
  echo
  echo -e "$(i18n select_lang)"
  echo
  echo -e "  ${GREEN}cn${NC} - $(i18n lang_cn)"
  echo -e "  ${GREEN}en${NC} - $(i18n lang_en)"
  echo -e "  ${GREEN}c${NC}  - $(i18n cancel_return)"
  echo
  read -rp "$(i18n menu_select) [cn/en/c]: " lang_choice
  
  case "$lang_choice" in
    cn|CN)
      PHONE_AGENT_LANG="cn"
      save_config
      init_i18n
      echo -e "${GREEN}[SUCC]${NC} 语言已切换为中文并保存！"
      ;;
    en|EN)
      PHONE_AGENT_LANG="en"
      save_config
      init_i18n
      echo -e "${GREEN}[SUCC]${NC} Language switched to English and saved!"
      ;;
    c|C)
      return 0
      ;;
    *)
      echo -e "${RED}$(i18n invalid_choice)${NC}"
      ;;
  esac
  read -rp "$(i18n press_enter) "
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
    echo -e "${YELLOW}[WARN]${NC} $(i18n req_not_found)"
    return 0
  fi
  
  echo -e "${BLUE}[INFO]${NC} $(i18n will_uninstall)"
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
  
  echo -e "  • open-autoglm ($(i18n project_main))"
  echo -e "${CYAN}────────────────────────────────────────${NC}"
  echo
  
  echo -e "${BLUE}[INFO]${NC} $(i18n uninstalling) open-autoglm..."
  python -m pip uninstall -y open-autoglm 2>/dev/null || true
  python -m pip uninstall -y autoglm 2>/dev/null || true
  python -m pip uninstall -y Open-AutoGLM 2>/dev/null || true
  
  for pkg_name in "${pkg_list[@]}"; do
    echo -e "${BLUE}[INFO]${NC} $(i18n uninstalling) $pkg_name ..."
    python -m pip uninstall -y "$pkg_name" 2>/dev/null || true
  done
  
  echo -e "${GREEN}[SUCC]${NC} $(i18n pip_uninstall_done)"
}

##########  卸载 Open-AutoGLM + 控制面板  ##########
uninstall_basic() {
  show_header
  echo -e "${RED}╔══════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${RED}║${NC}              ${BOLD}$(i18n uninstall_basic)${NC}                 ${RED}║${NC}"
  echo -e "${RED}╚══════════════════════════════════════════════════════════════╝${NC}"
  echo
  echo -e "${YELLOW}$(i18n uninstall_guide)${NC}"
  echo
  
  local did_something=false
  
  echo -e "${CYAN}━━━ $(i18n step) 1 $(i18n step_suffix): $(i18n pip_deps) ━━━${NC}"
  if [[ -f "$AUTOGLM_DIR/requirements.txt" ]]; then
    echo -e "${YELLOW}$(i18n detected_req): $AUTOGLM_DIR/requirements.txt${NC}"
    echo
    if ask_yes_no "$(i18n uninstall_pip_ask)"; then
      uninstall_pip_deps
      did_something=true
    else
      echo -e "${BLUE}[INFO]${NC} $(i18n skip_pip)"
    fi
  else
    echo -e "${YELLOW}[WARN]${NC} $(i18n req_not_found)"
    if ask_yes_no "$(i18n uninstall_main_ask)"; then
      python -m pip uninstall -y open-autoglm 2>/dev/null || true
      python -m pip uninstall -y autoglm 2>/dev/null || true
      python -m pip uninstall -y Open-AutoGLM 2>/dev/null || true
      echo -e "${GREEN}[SUCC]${NC} $(i18n main_uninstalled)"
      did_something=true
    fi
  fi
  echo
  
  echo -e "${CYAN}━━━ $(i18n step) 2 $(i18n step_suffix): $(i18n project_dir) ━━━${NC}"
  if [[ -d "$AUTOGLM_DIR" ]]; then
    echo -e "${YELLOW}$(i18n project_dir): $AUTOGLM_DIR${NC}"
    echo
    if ask_yes_no "$(i18n delete_project_ask)"; then
      rm -rf "$AUTOGLM_DIR"
      echo -e "${GREEN}[SUCC]${NC} $(i18n deleted): $AUTOGLM_DIR"
      did_something=true
    else
      echo -e "${BLUE}[INFO]${NC} $(i18n keep_project)"
    fi
  else
    echo -e "${YELLOW}[WARN]${NC} $(i18n dir_not_exist)"
  fi
  echo
  
  echo -e "${CYAN}━━━ $(i18n step) 3 $(i18n step_suffix): $(i18n command_config) ━━━${NC}"
  echo -e "${YELLOW}$(i18n includes)${NC}"
  echo -e "  • $(i18n autoglm_cmd): ${CYAN}$HOME/bin/autoglm${NC}"
  echo -e "  • $(i18n config_dir): ${CYAN}$HOME/.autoglm${NC}"
  echo -e "  • $(i18n bashrc_env)"
  echo
  if ask_yes_no "$(i18n delete_cmd_ask)"; then
    if [[ -f "$HOME/bin/autoglm" ]]; then
      rm -f "$HOME/bin/autoglm"
      echo -e "${GREEN}[SUCC]${NC} $(i18n deleted): $HOME/bin/autoglm"
    fi
    
    if [[ -d "$HOME/.autoglm" ]]; then
      rm -rf "$HOME/.autoglm"
      echo -e "${GREEN}[SUCC]${NC} $(i18n deleted): $HOME/.autoglm"
    fi
    
    if [[ -f "$HOME/.bashrc" ]]; then
      sed -i '/source ~\/.autoglm\/config.sh/d' "$HOME/.bashrc" 2>/dev/null || true
      sed -i '/source \$HOME\/.autoglm\/config.sh/d' "$HOME/.bashrc" 2>/dev/null || true
      echo -e "${GREEN}[SUCC]${NC} $(i18n cleaned_bashrc)"
    fi
    did_something=true
  else
    echo -e "${BLUE}[INFO]${NC} $(i18n keep_cmd)"
  fi
  echo
  
  if [[ "$did_something" == true ]]; then
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║${NC}              ${BOLD}$(i18n uninstall_complete)${NC}                                ${GREEN}║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
    echo -e "${YELLOW}$(i18n reopen_terminal)${NC}"
  else
    echo -e "${BLUE}[INFO]${NC} $(i18n no_action)"
  fi
  echo
  read -rp "$(i18n press_enter) "
  
  if [[ ! -f "$HOME/bin/autoglm" ]]; then
    echo -e "${YELLOW}$(i18n cmd_deleted_exit)${NC}"
    exit 0
  fi
}

##########  完全卸载  ##########
uninstall_full() {
  show_header
  echo -e "${RED}╔══════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${RED}║${NC}              ${BOLD}$(i18n uninstall_full)${NC}                    ${RED}║${NC}"
  echo -e "${RED}╚══════════════════════════════════════════════════════════════╝${NC}"
  echo
  echo -e "${YELLOW}$(i18n uninstall_guide)${NC}"
  echo -e "${RED}${BOLD}⚠️ $(i18n warn_affect)${NC}"
  echo
  
  local did_something=false
  
  echo -e "${CYAN}━━━ $(i18n step) 1 $(i18n step_suffix): $(i18n pip_deps) ━━━${NC}"
  if [[ -f "$AUTOGLM_DIR/requirements.txt" ]]; then
    echo -e "${YELLOW}$(i18n detected_req): $AUTOGLM_DIR/requirements.txt${NC}"
    echo
    if ask_yes_no "$(i18n uninstall_pip_ask)"; then
      uninstall_pip_deps
      did_something=true
    else
      echo -e "${BLUE}[INFO]${NC} $(i18n skip_pip)"
    fi
  else
    echo -e "${YELLOW}[WARN]${NC} $(i18n req_not_found)"
    if ask_yes_no "$(i18n uninstall_main_ask)"; then
      python -m pip uninstall -y open-autoglm 2>/dev/null || true
      python -m pip uninstall -y autoglm 2>/dev/null || true
      python -m pip uninstall -y Open-AutoGLM 2>/dev/null || true
      echo -e "${GREEN}[SUCC]${NC} $(i18n main_uninstalled)"
      did_something=true
    fi
  fi
  echo
  
  echo -e "${CYAN}━━━ $(i18n step) 2 $(i18n step_suffix): $(i18n core_pip) ━━━${NC}"
  echo -e "${YELLOW}$(i18n core_pip_list)${NC}"
  echo -e "  • maturin"
  echo -e "  • openai"
  echo -e "  • requests"
  if ! in_termux; then
    echo -e "  • pillow"
  fi
  echo
  if ask_yes_no "$(i18n uninstall_core_ask)"; then
    echo -e "${BLUE}[INFO]${NC} $(i18n uninstalling_core)"
    python -m pip uninstall -y maturin 2>/dev/null || true
    python -m pip uninstall -y openai 2>/dev/null || true
    python -m pip uninstall -y requests 2>/dev/null || true
    if ! in_termux; then
      python -m pip uninstall -y pillow 2>/dev/null || true
    fi
    echo -e "${GREEN}[SUCC]${NC} $(i18n core_uninstalled)"
    did_something=true
  else
    echo -e "${BLUE}[INFO]${NC} $(i18n keep_core)"
  fi
  echo
  
  echo -e "${CYAN}━━━ $(i18n step) 3 $(i18n step_suffix): $(i18n project_dir) ━━━${NC}"
  if [[ -d "$AUTOGLM_DIR" ]]; then
    echo -e "${YELLOW}$(i18n project_dir): $AUTOGLM_DIR${NC}"
    echo
    if ask_yes_no "$(i18n delete_project_ask)"; then
      rm -rf "$AUTOGLM_DIR"
      echo -e "${GREEN}[SUCC]${NC} $(i18n deleted): $AUTOGLM_DIR"
      did_something=true
    else
      echo -e "${BLUE}[INFO]${NC} $(i18n keep_project)"
    fi
  else
    echo -e "${YELLOW}[WARN]${NC} $(i18n dir_not_exist)"
  fi
  echo
  
  echo -e "${CYAN}━━━ $(i18n step) 4 $(i18n step_suffix): $(i18n command_config) ━━━${NC}"
  echo -e "${YELLOW}$(i18n includes)${NC}"
  echo -e "  • $(i18n autoglm_cmd): ${CYAN}$HOME/bin/autoglm${NC}"
  echo -e "  • $(i18n config_dir): ${CYAN}$HOME/.autoglm${NC}"
  echo -e "  • $(i18n bashrc_env)"
  echo
  if ask_yes_no "$(i18n delete_cmd_ask)"; then
    if [[ -f "$HOME/bin/autoglm" ]]; then
      rm -f "$HOME/bin/autoglm"
      echo -e "${GREEN}[SUCC]${NC} $(i18n deleted): $HOME/bin/autoglm"
    fi
    
    if [[ -d "$HOME/.autoglm" ]]; then
      rm -rf "$HOME/.autoglm"
      echo -e "${GREEN}[SUCC]${NC} $(i18n deleted): $HOME/.autoglm"
    fi
    
    if [[ -f "$HOME/.bashrc" ]]; then
      sed -i '/source ~\/.autoglm\/config.sh/d' "$HOME/.bashrc" 2>/dev/null || true
      sed -i '/source \$HOME\/.autoglm\/config.sh/d' "$HOME/.bashrc" 2>/dev/null || true
      echo -e "${GREEN}[SUCC]${NC} $(i18n cleaned_bashrc)"
    fi
    did_something=true
  else
    echo -e "${BLUE}[INFO]${NC} $(i18n keep_cmd)"
  fi
  echo
  
  echo -e "${CYAN}━━━ $(i18n step) 5 $(i18n step_suffix): $(i18n pip_mirror) ━━━${NC}"
  local pip_mirror
  pip_mirror=$(pip config get global.index-url 2>/dev/null || echo "")
  if [[ -n "$pip_mirror" ]]; then
    echo -e "${YELLOW}$(i18n current_pip_mirror): $pip_mirror${NC}"
    echo
    if ask_yes_no "$(i18n delete_pip_mirror_ask)"; then
      pip config unset global.index-url 2>/dev/null || true
      pip config unset install.trusted-host 2>/dev/null || true
      echo -e "${GREEN}[SUCC]${NC} $(i18n pip_mirror_deleted)"
      did_something=true
    else
      echo -e "${BLUE}[INFO]${NC} $(i18n keep_pip_mirror)"
    fi
  else
    echo -e "${YELLOW}[INFO]${NC} $(i18n no_pip_mirror)"
  fi
  echo
  
  echo -e "${CYAN}━━━ $(i18n step) 6 $(i18n step_suffix): $(i18n cargo_mirror) ━━━${NC}"
  if [[ -f "$HOME/.cargo/config.toml" ]]; then
    echo -e "${YELLOW}$(i18n detected_cargo): $HOME/.cargo/config.toml${NC}"
    echo
    if ask_yes_no "$(i18n delete_cargo_ask)"; then
      rm -f "$HOME/.cargo/config.toml"
      rm -f "$HOME/.cargo/config"
      echo -e "${GREEN}[SUCC]${NC} $(i18n cargo_deleted)"
      did_something=true
    else
      echo -e "${BLUE}[INFO]${NC} $(i18n keep_cargo)"
    fi
  else
    echo -e "${YELLOW}[INFO]${NC} $(i18n no_cargo)"
  fi
  echo
  
  if in_termux; then
    echo -e "${CYAN}━━━ $(i18n step) 7 $(i18n step_suffix): $(i18n termux_pkg) ━━━${NC}"
    echo -e "${RED}${BOLD}⚠️  $(i18n warn_affect)${NC}"
    echo
    
    if pkg list-installed 2>/dev/null | grep -q "python-pillow"; then
      if ask_yes_no "$(i18n uninstall_pillow)"; then
        pkg uninstall -y python-pillow 2>/dev/null || true
        echo -e "${GREEN}[SUCC]${NC} $(i18n pillow_uninstalled)"
        did_something=true
      fi
    fi
    
    if command -v rustc &>/dev/null; then
      if ask_yes_no "$(i18n uninstall_rust)"; then
        pkg uninstall -y rust binutils 2>/dev/null || true
        echo -e "${GREEN}[SUCC]${NC} $(i18n rust_uninstalled)"
        did_something=true
      fi
    fi
    
    if command -v adb &>/dev/null; then
      if ask_yes_no "$(i18n uninstall_adb)"; then
        pkg uninstall -y android-tools 2>/dev/null || true
        echo -e "${GREEN}[SUCC]${NC} $(i18n adb_uninstalled)"
        did_something=true
      fi
    fi
    echo
  fi
  
  if [[ "$did_something" == true ]]; then
    echo -e "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║${NC}              ${BOLD}$(i18n uninstall_complete)${NC}                                ${GREEN}║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
    echo -e "${YELLOW}$(i18n reopen_terminal)${NC}"
  else
    echo -e "${BLUE}[INFO]${NC} $(i18n no_action)"
  fi
  echo
  read -rp "$(i18n press_enter) "
  
  if [[ ! -f "$HOME/bin/autoglm" ]]; then
    echo -e "${YELLOW}$(i18n cmd_deleted_exit)${NC}"
    exit 0
  fi
}

##########  卸载子菜单  ##########
uninstall_menu() {
  while true; do
    show_header
    echo -e "${RED}╔══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║${NC}              ${BOLD}$(i18n uninstall_title)${NC}                                     ${RED}║${NC}"
    echo -e "${RED}╚══════════════════════════════════════════════════════════════╝${NC}"
    echo
    echo -e "${YELLOW}$(i18n select_uninstall)${NC}"
    echo
    echo -e "  ${GREEN}1.${NC} $(i18n uninstall_basic)"
    echo -e "     ${CYAN}$(i18n uninstall_basic_desc)${NC}"
    echo
    echo -e "  ${GREEN}2.${NC} $(i18n uninstall_full)"
    echo -e "     ${CYAN}$(i18n uninstall_full_desc)${NC}"
    echo -e "     ${CYAN}$(i18n uninstall_full_desc2)${NC}"
    echo
    echo -e "  ${GREEN}0.${NC} $(i18n menu_back)"
    echo
    read -rp "$(i18n menu_select) [0-2]: " choice
    
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
        echo -e "${RED}$(i18n invalid_choice)${NC}"
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
    echo -e "${RED}[ERROR]${NC} $(i18n no_adb_device)"
    echo -e "${YELLOW}$(i18n config_adb_first)${NC}"
    echo
    read -rp "$(i18n config_adb_now): " ans
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
    echo -e "${RED}[ERROR]${NC} $(i18n project_not_found): $AUTOGLM_DIR"
    echo -e "${YELLOW}$(i18n reinstall_tip)${NC}"
    read -rp "$(i18n press_enter) "
    return 1
  fi
  
  local CMD_ARGS=()
  CMD_ARGS+=(--base-url "$PHONE_AGENT_BASE_URL")
  CMD_ARGS+=(--model "$PHONE_AGENT_MODEL")
  CMD_ARGS+=(--apikey "$PHONE_AGENT_API_KEY")
  
  [[ -n "${PHONE_AGENT_DEVICE_ID:-}" ]] && CMD_ARGS+=(--device-id "$PHONE_AGENT_DEVICE_ID")
  
  echo
  echo -e "${CYAN}╔══════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${CYAN}║${NC}              ${BOLD}$(i18n start_title)${NC}                                  ${CYAN}║${NC}"
  echo -e "${CYAN}╚══════════════════════════════════════════════════════════════╝${NC}"
  echo
  echo -e "${BLUE}$(i18n config_info)${NC}"
  echo -e "  API    : ${GREEN}$PHONE_AGENT_BASE_URL${NC}"
  echo -e "  Model  : ${GREEN}$PHONE_AGENT_MODEL${NC}"
  echo -e "  Steps  : ${GREEN}$PHONE_AGENT_MAX_STEPS${NC}"
  echo -e "  Lang   : ${GREEN}$PHONE_AGENT_LANG${NC}"
  [[ -n "${PHONE_AGENT_DEVICE_ID:-}" ]] && echo -e "  Device : ${GREEN}$PHONE_AGENT_DEVICE_ID${NC}"
  echo
  echo -e "${YELLOW}$(i18n starting)${NC}"
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
        save_config
        init_i18n
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
        echo -e "${BOLD}${CYAN}$(i18n help_title)${NC}"
        echo
        echo -e "${YELLOW}$(i18n help_usage)${NC}"
        echo "  autoglm                # $(i18n help_menu)"
        echo "  autoglm --setup-adb    # $(i18n help_setup_adb)"
        echo "  autoglm --devices      # $(i18n help_devices)"
        echo "  autoglm --switch-device # $(i18n help_switch)"
        echo "  autoglm --disconnect   # $(i18n help_disconnect)"
        echo "  autoglm --reconfig     # $(i18n help_reconfig)"
        echo "  autoglm --list-apps    # $(i18n help_apps)"
        echo "  autoglm --uninstall    # $(i18n help_uninstall)"
        echo
        echo -e "${YELLOW}$(i18n help_params)${NC}"
        echo "  --base-url URL       $(i18n help_base_url)"
        echo "  --model NAME         $(i18n help_model)"
        echo "  --apikey KEY         $(i18n help_apikey)"
        echo "  --max-steps N        $(i18n help_max_steps)"
        echo "  --device-id ID       $(i18n help_device_id)"
        echo "  --lang cn|en         $(i18n help_lang)"
        exit 0
        ;;
      --start|-s)
        DIRECT_START=true
        shift
        ;;
      *)
        echo -e "${RED}$(i18n unknown_param): $1${NC}"
        echo "$(i18n use_help)"
        exit 1
        ;;
    esac
  done
}

##########  主菜单循环  ##########
main_menu_loop() {
  while true; do
    show_main_menu
    read -rp "$(i18n menu_select) [0-7]: " choice
    
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
        switch_language
        ;;
      7)
        uninstall_menu
        ;;
      0)
        echo
        echo -e "${GREEN}$(i18n goodbye)${NC}"
        exit 0
        ;;
      *)
        echo -e "${RED}$(i18n invalid_choice)${NC}"
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
  
  log_succ "$(i18n launcher_created): ~/bin/autoglm"
}

##########  主流程  ##########
main() {
  # 初始化国际化
  init_i18n
  
  # 语言选择
  select_language
  
  echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${BLUE}║${NC}       ${BOLD}$(i18n deploy_title)${NC}              ${BLUE}║${NC}"
  echo -e "${BLUE}║${NC}       ${CYAN}$(i18n deploy_version)${NC}                                          ${BLUE}║${NC}"
  echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
  echo
  
  log_info "$(i18n checking_deps)"
  ensure_python
  ensure_pip
  ensure_git
  ensure_rust
  ensure_adb
  
  ensure_setuptools
  
  echo
  
  local pip_mirror="" cargo_mirror=""
  ask_mirror "$(i18n pip_mirror_prompt)" \
             "https://mirrors.aliyun.com/pypi/simple" pip_mirror
  ask_mirror "$(i18n cargo_mirror_prompt)" \
             "sparse+https://mirrors.tuna.tsinghua.edu.cn/crates.io-index/" cargo_mirror
  setup_pip_mirror "$pip_mirror"
  setup_cargo_mirror "$cargo_mirror"

  install_py_deps

  clone_or_update

  configure_env

  remind_adb_keyboard

  echo
  if check_adb_configured; then
    log_succ "$(i18n adb_detected)"
    adb devices
    read -rp "$(i18n adb_reconfig_ask): " reconf
    if [[ "$reconf" == "y" || "$reconf" == "Y" ]]; then
      configure_adb_wireless
    fi
  else
    log_warn "$(i18n adb_not_detected)"
    read -rp "$(i18n adb_config_now): " conf
    case "${conf:-y}" in
      [Nn]*)
        log_info "$(i18n adb_config_skip)"
        ;;
      *)
        configure_adb_wireless || log_warn "$(i18n adb_config_fail)"
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
  echo -e "${GREEN}║${NC}              ${BOLD}✅ $(i18n deploy_complete)${NC}                                    ${GREEN}║${NC}"
  echo -e "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
  echo
  echo -e "$(i18n run_autoglm) ${CYAN}autoglm${NC}"
  echo -e "$(i18n run_autoglm_help) ${CYAN}autoglm --help${NC}"
  echo
  echo -e "${GREEN}$(i18n autoglm_ready)${NC}"
  echo -e "${YELLOW}$(i18n source_tip)${NC}"
  echo -e "  ${GREEN}source ~/.bashrc${NC}"
  echo
}

main "$@"
