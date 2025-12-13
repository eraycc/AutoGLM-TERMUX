
AutoGLM-Termux 部署工具

[![版本](https://img.shields.io/badge/版本-4.3.1-brightgreen)](https://github.com/eraycc/AutoGLM-TERMUX)
[![Open-AutoGLM](https://img.shields.io/badge/Open--AutoGLM-最新版-blue)](https://github.com/zai-org/Open-AutoGLM)
[![Termux](https://img.shields.io/badge/Termux-支持-black)](https://termux.dev/)
[![License](https://img.shields.io/badge/License-MIT-orange)](https://opensource.org/licenses/MIT)

在安卓手机上通过 Termux 快速部署 Open-AutoGLM 智能体，实现手机自动化操作！

---

📖 项目简介

AutoGLM-Termux 是一个专为 Termux 环境优化的 Open-AutoGLM 一键部署解决方案。它通过纯 ADB 方案，让你的安卓手机变身 AI 智能体，能够：
- 理解自然语言指令
- 自动执行手机操作（点击、滑动、输入等）
- 支持 50+ 款主流中文 App
- 完全无线控制，无需 Root

> ⚠️ 合规声明：本项目仅供学习和研究使用，严禁用于任何违法活动。请遵守 [Open-AutoGLM 使用条款](https://github.com/zai-org/Open-AutoGLM/blob/main/resources/privacy_policy.txt)。

---

✨ 功能特性

- 一键部署：自动化安装所有依赖和环境配置
- 智能镜像：自动配置国内 pip 和 Cargo 镜像源，加速下载
- 无线 ADB：内置 ADB 无线调试配置向导，告别数据线
- 交互式菜单：可视化启动面板，管理配置更轻松
- 自动重连：支持 ADB 设备自动检测和连接
- 配置持久化：环境变量自动保存，重启 Termux 无需重新配置
- 多设备支持：可管理多个 ADB 设备

---

🍭部署演示


![1000114284](https://github.com/user-attachments/assets/d4e89a3c-8d39-41a8-a44e-bed00c74fdb0)
![1000114273](https://github.com/user-attachments/assets/3ca780ce-631c-4ae3-996a-8f3bf4eb4037)
![1000114283](https://github.com/user-attachments/assets/dd618ffc-4138-4bcf-bf0a-03562b364875)

---

📱 前置要求

1. 安卓手机（Android 7.0+）
2. Termux 已安装（[下载地址](https://github.com/termux/termux-app/releases/)）
3. 网络连接：手机和 Termux 设备需在同一 WiFi 网络下
4. API Key：需要智谱 AI 或 ModelScope 的 API Key 或 其他支持图片识别的AI模型

---

🚀 快速开始（推荐）

在 Termux 中执行以下命令，一键完成部署：

```bash
# 1. 更新 Termux 包列表
pkg upgrade -y

# 2. 下载部署脚本
curl -O https://raw.githubusercontent.com/eraycc/AutoGLM-TERMUX/refs/heads/main/deploy.sh

# 3. 授予执行权限
chmod +x deploy.sh

# 4. 运行部署脚本
./deploy.sh
```

或带有卸载菜单的beta版本（未测试卸载功能）

```bash
# 1. 更新 Termux 包列表
pkg upgrade -y

# 2. 下载部署脚本
curl -O curl -O https://github.com/eraycc/AutoGLM-TERMUX/raw/refs/heads/main/deploy-beta.sh

# 3. 授予执行权限
chmod +x deploy-beta.sh

# 4. 运行部署脚本
./deploy-beta.sh
```

部署完成后，输入 `autoglm` 即可启动智能控制面板。

---

📋 详细部署步骤

步骤 1：安装 Termux

从 [GitHub Releases](https://github.com/termux/termux-app/releases/) 下载最新版 Termux APK 并安装。

步骤 2：更新 Termux

首次启动 Termux 后，执行：

```bash
pkg upgrade -y
```

步骤 3：设置termux pkg下载加速源

- 执行下面的命令打开termux的pkg加速源设置GUI
- 选择Mirror group - Rotate between several mirrors (recommended)这一项
- 点击OK进入，通过上下箭头切换到Mirrors in Chinese Mainland - All in Chinese Mainland
- 再次点击OK，等待自动配置完成即可

```bash
termux-change-repo
```

步骤 3：运行部署脚本

```bash
curl -O https://raw.githubusercontent.com/eraycc/AutoGLM-TERMUX/refs/heads/main/deploy.sh
chmod +x deploy.sh
./deploy.sh
```

步骤 4：脚本执行流程

脚本将自动完成以下操作：

1. 安装依赖：Python、pip、Git、Rust、ADB
2. 配置镜像源：可选配置国内 pip/Cargo 镜像加速
3. 安装 Python 包：maturin、openai、requests、Pillow
4. 克隆项目：从 GitHub 拉取 Open-AutoGLM 最新代码
5. 交互式配置：设置 API Key、模型参数等
6. ADB Keyboard 提醒：提示安装必需的输入法工具
7. ADB 无线配置：引导完成手机无线调试连接
8. 创建启动器：生成 `autoglm` 快捷命令

---

🔧 ADB Keyboard 安装指南

这是必须步骤，否则无法输入中文！

下载安装包

```
https://github.com/senzhk/ADBKeyBoard/blob/master/ADBKeyboard.apk
```

安装步骤
1. 下载 APK 文件到手机
2. 点击安装（可能需要在设置中允许"安装未知应用"）
3. 进入 设置 → 系统 → 语言和输入法 → 虚拟键盘 → 管理键盘
4. 启用 "ADB Keyboard"（可保持当前输入法不变）
5. 返回 Termux 继续配置

> 💡 提示：运行时 Agent 会自动切换输入法，无需手动切换

---

📶 ADB 无线调试配置

手机端操作
1. 确保手机和 Termux 在同一 WiFi 网络
2. 进入 设置 → 关于手机 → 连续点击版本号 7 次（开启开发者模式）
3. 返回 设置 → 系统 → 开发者选项
4. 开启 "无线调试"

Termux 端配对与连接
部署脚本会引导你完成：
1. 配对：输入手机显示的 IP:端口 和 6 位配对码
2. 连接：输入无线调试主界面的 IP:端口
3. 验证：自动检测设备连接状态

常用 ADB 命令

```bash
# 查看已连接设备
adb devices

# 手动连接设备
adb connect 192.168.1.100:5555

# 断开所有设备
adb disconnect
```

---

🎮 使用方法

启动控制面板

```bash
autoglm
```

主菜单功能

```
1. 🚀 使用当前配置启动    # 直接运行 AutoGLM
2. 📱 配置 ADB 无线调试   # 重新配置 ADB 连接
3. ⚙️  修改 AI 配置       # 修改 API Key、模型等
4. 📋 查看支持的应用列表  # 显示支持的 50+ 款 App
5. 🔍 查看详细配置        # 显示当前所有配置信息
6. 🔌 查看 ADB 设备列表   # 显示已连接设备
0. ❌ 退出               # 退出程序
```

命令行参数

```bash
# 直接启动（绕过菜单）
autoglm --start

# 重新配置 ADB
autoglm --setup-adb

# 修改配置
autoglm --reconfig

# 查看支持的应用
autoglm --list-apps

# 手动指定参数启动
autoglm --base-url URL --model MODEL --apikey KEY "你的指令"
```

使用示例

```bash
# 示例 1：打开美团搜索火锅
autoglm
# 然后在交互界面输入：打开美团搜索附近的火锅店

# 示例 2：直接执行指令
autoglm --base-url https://open.bigmodel.cn/api/paas/v4 \
        --model autoglm-phone \
        --apikey sk-xxxxx \
        "打开微信发送消息给文件传输助手：Hello World"
```

---

⚙️ 配置说明

环境变量
部署完成后，配置保存在 `~/.autoglm/config.sh`，包含：

变量名	说明	默认值	
`PHONE_AGENT_BASE_URL`	API 基础地址	`https://open.bigmodel.cn/api/paas/v4`	
`PHONE_AGENT_MODEL`	模型名称	`autoglm-phone`	
`PHONE_AGENT_API_KEY`	你的 API Key	`sk-your-apikey`	
`PHONE_AGENT_MAX_STEPS`	最大执行步数	`100`	
`PHONE_AGENT_DEVICE_ID`	ADB 设备 ID	自动检测	
`PHONE_AGENT_LANG`	语言	`cn`	

支持的模型服务

1. 智谱 BigModel（推荐）
- Base URL: `https://open.bigmodel.cn/api/paas/v4`
- 模型: `autoglm-phone`
- 申请地址: [BigModel 控制台](https://open.bigmodel.cn/)

2. ModelScope 魔搭社区
- Base URL: `https://api-inference.modelscope.cn/v1`
- 模型: `ZhipuAI/AutoGLM-Phone-9B`
- 申请地址: [ModelScope 平台](https://modelscope.cn/)

---

📦 项目结构

```
~/
├── Open-AutoGLM/                 # 项目代码
├── .autoglm/
│   └── config.sh                # 配置文件
├── bin/
│   └── autoglm                  # 启动脚本
└── .cargo/
    └── config.toml              # Cargo 镜像配置
```

---

🔍 支持的应用列表

运行 `autoglm --list-apps` 查看完整列表，主要包括：

- 社交通讯：微信、QQ、微博
- 电商购物：淘宝、京东、拼多多
- 美食外卖：美团、饿了么、肯德基
- 出行旅游：携程、12306、滴滴出行
- 视频娱乐：B站、抖音、爱奇艺
- 音乐音频：网易云音乐、QQ音乐、喜马拉雅
- 生活服务：大众点评、高德地图、百度地图
- 内容社区：小红书、知乎、豆瓣

---

⚠️ 常见问题与故障排除

1. `adb devices` 不显示设备
- 检查 USB 调试：开发者选项中必须开启 USB 调试
- 检查数据线：使用支持数据传输的线，非充电线
- 授权弹窗：手机上点击"允许 USB 调试"
- 重启 ADB：执行 `adb kill-server && adb start-server`

2. 能打开应用但无法点击
- 开启安全调试：部分手机需要开启"USB 调试（安全设置）"
- 重新配对 wireless：删除旧配对，重新执行 `adb pair`

3. 中文输入失败或乱码
- 安装 ADB Keyboard：必须安装并启用
- 检查输入法：设置 → 语言和输入法 → 启用 ADB Keyboard

4. 截图黑屏
- 敏感页面：支付、银行等应用会黑屏，正常现象
- 权限限制：部分应用禁止截图，Agent 会请求人工接管

5. 模型连接失败
- 检查 API Key：确认 Key 有效且未过期
- 网络问题：确保 Termux 能访问外部网络
- Base URL：确认 URL 格式正确，结尾有 `/v1`

6. 环境变量未生效

```bash
# 手动加载配置
source ~/.bashrc
# 或
source ~/.autoglm/config.sh
```

7. 更新失败

```bash
# 手动删除旧目录后重试
rm -rf ~/Open-AutoGLM
./deploy.sh
```

---

🔄 更新日志

v4.3.1 (当前版本)
- 修复 setuptools 依赖问题
- 优化镜像源配置流程
- 增强 ADB 设备检测稳定性
- 改进错误提示和引导

v4.3.0
- 新增交互式启动面板 `autoglm` 命令
- 支持无线 ADB 配对和连接向导
- 自动配置 pip 和 Cargo 国内镜像
- 支持多设备管理

v4.2.0
- 优化 Termux 兼容性
- 增加 ADB Keyboard 安装提醒
- 支持配置持久化

---

🤝 贡献指南

欢迎提交 Issue 和 Pull Request！

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

---

📄 许可证

本项目采用 MIT 许可证。详见 [LICENSE](LICENSE) 文件。

---

🔗 相关链接

- Open-AutoGLM 官方项目: https://github.com/zai-org/Open-AutoGLM
- Termux 官网: https://termux.dev/
- AutoGLM 论文: https://arxiv.org/abs/2411.00820
- 智谱 AI: https://www.zhipuai.cn/
- ModelScope: https://modelscope.cn/

---

🙏 致谢

- [Open-AutoGLM](https://github.com/zai-org/Open-AutoGLM) - 核心框架
- [ADBKeyBoard](https://github.com/senzhk/ADBKeyBoard) - 输入解决方案
- [Termux](https://termux.dev/) - 强大的终端模拟器

---

💬 社区支持

遇到问题？需要帮助？

- 提交 [Issue](https://github.com/eraycc/AutoGLM-TERMUX/issues)
- 查看 [Open-AutoGLM 文档](https://github.com/zai-org/Open-AutoGLM/blob/main/README.md)
- 加入 Open-AutoGLM 微信社区（见官方项目 README）

---

⭐ 如果这个项目对你有帮助，请点个 Star 支持一下！

---

📢 免责声明

本项目仅为 Open-AutoGLM 的自动化部署工具，所有核心功能由 Open-AutoGLM 提供。请确保遵守当地法律法规，合法使用本工具。开发者不对任何滥用行为承担责任。
