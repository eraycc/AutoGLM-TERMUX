AutoGLM-Termux 部署工具

[![版本](https://img.shields.io/badge/版本-4.5.0-brightgreen)](https://github.com/eraycc/AutoGLM-TERMUX)
[![Open-AutoGLM](https://img.shields.io/badge/Open--AutoGLM-最新版-blue)](https://github.com/zai-org/Open-AutoGLM)
[![Termux](https://img.shields.io/badge/Termux-支持-black)](https://termux.dev/)
[![License](https://img.shields.io/badge/License-MIT-orange)](https://opensource.org/licenses/MIT)

在安卓手机上通过 Termux 快速部署 Open-AutoGLM 智能体，实现手机自动化操作！

---

📖 项目简介

AutoGLM-Termux 是一个专为 Termux 环境优化的 Open-AutoGLM 一键部署解决方案。它通过纯 ADB 方案，让你的安卓手机化身 AI 智能体，能够：
- 理解自然语言指令
- 自动执行手机操作（点击、滑动、输入等）
- 支持 50+ 款主流中文 App
- 增强 ADB 设备管理：支持多设备切换、快速连接、设备状态监控
- 一键卸载功能：完整卸载项目及运行环境
- 完全无线控制，无需 Root

> ⚠️ 合规声明：本项目仅供学习和研究使用，严禁用于任何违法活动。请遵守 [Open-AutoGLM 使用条款](https://github.com/zai-org/Open-AutoGLM/blob/main/resources/privacy_policy.txt)。

---

✨ 功能特性

- 一键部署：自动化安装所有依赖和环境配置
- 智能镜像：自动配置国内 pip 和 Cargo 镜像源，加速下载（支持输入 `default` 使用推荐源）
- 无线 ADB：内置 ADB 无线调试配置向导，告别数据线
- ADB 设备管理：可视化设备列表、切换活动设备、断开连接、快速重连
- 交互式菜单：可视化启动面板，管理配置更轻松
- 自动重连：支持 ADB 设备自动检测和连接
- 配置持久化：环境变量自动保存，重启 Termux 无需重新配置
- 多设备支持：同一局域网内，关闭VPN的情况下，可用安卓设备使用无线调试连接其他手机adb实现自动控制其他安卓手机设备，支持管理多个 ADB 设备
- 一键卸载：提供基本卸载和完全卸载两种模式，干净清理不残留

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

部署完成后，输入 `autoglm` 即可启动智能控制面板。

---

📱 前置要求

1. 安卓手机（Android 7.0+）
2. Termux 已安装（[下载地址](https://github.com/termux/termux-app/releases/)）
3. 网络连接：手机和 Termux 设备需在同一 WiFi 网络下
4. API Key：需要智谱 AI 或 ModelScope 的 API Key 或 其他支持图片识别的AI模型

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
5. 提示：运行 AutoGLM 时，Agent 会自动切换输入法，但需要启用
6. 返回 Termux 继续配置

---

🎮 使用方法

启动控制面板

```bash
autoglm
```

主菜单功能

```
1. 🚀 使用当前配置启动    # 直接运行 AutoGLM（自动检测设备）
2. 📱 ADB 设备管理       # 进入增强的设备管理子菜单
3. ⚙️  修改 AI 配置       # 修改 API Key、模型等
4. 📋 查看支持的应用列表  # 显示支持的 50+ 款 App
5. 🔍 查看详细配置        # 显示当前所有配置信息
6. 🗑️  一键卸载           # 进入卸载菜单
0. ❌ 退出               # 退出程序
```

ADB 设备管理子菜单

```
1. 📱 配对新设备（配对+连接）
2. ⚡ 快速连接（已配对过）
3. 📋 查看设备详细列表
4. 🔄 切换活动设备
5. 🔌 断开设备连接
6. ❓ ADB Keyboard 安装说明
0. ↩️  返回主菜单
```

命令行参数

```bash
# 直接启动（绕过菜单）
autoglm --start

# ADB 设备管理（进入子菜单）
autoglm --setup-adb

# 快速查看设备列表
autoglm --devices

# 切换活动设备
autoglm --switch-device

# 断开设备连接
autoglm --disconnect

# 修改配置
autoglm --reconfig

# 查看支持的应用
autoglm --list-apps

# 一键卸载（进入卸载菜单）
autoglm --uninstall

# 手动指定参数启动
autoglm --base-url URL --model MODEL --apikey KEY --device-id ID "你的指令"

# 显示帮助
autoglm --help
```

---

🎯 进阶玩法：自定义扩展应用支持

除了内置的50+款主流应用外，你还可以通过修改配置文件，让AutoGLM支持一键打开更多应用。

准备工作

1. 下载并安装MT管理器
   下载链接：https://mt2.cn/download/

配置步骤

步骤1：授予MT管理器Termux文件访问权限
1. 打开MT管理器，展开侧边栏
2. 点击顶部"三个点"更多按钮，选择"添加本地存储"
3. 在新界面中再次点击左上角"三个点"，打开侧边栏
4. 找到并选择"Termux"（显示可用空间：xx GB）
5. 点击"使用此文件夹"授权

步骤2：修改应用配置文件
1. 返回MT管理器首页，在侧边栏中找到"Termux Home"
2. 进入目录：`Open-AutoGLM/phone_agent/config/`
3. 打开`apps.py`文件
4. 定位到`APP_PACKAGES`配置字典
5. 在字典末尾添加你的自定义应用，格式：`"应用名称": "应用包名"`

示例配置
在`APP_PACKAGES`字典末尾添加：

```python
    # 自定义应用
    "via": "mark.via",
    "浏览器": "mark.via",
    "via浏览器": "mark.via",
    "米游社": "com.mihoyo.hyperion",
    "fclash": "com.follow.clash",
    "clash": "com.github.metacubex.clash.meta",
    "deepseek": "chat.deepseek.com",
    "云原神": "com.miHoYo.cloudgames.ys",
    "firefox": "org.mozilla.firefox",
    "telegram": "org.telegram.messenger.web",
    "kimi": "com.moonshot.kimichat",
    "酷狗概念版": "com.kugou.android.lite",
    "mt管理器": "bin.mt.plus",
    "youtube": "com.google.android.youtube",
    "微博lite": "com.web.weibo",
    # 继续添加更多...
```

保存修改后，重启AutoGLM即可生效。

注意事项
- 应用包名可通过应用商店链接或第三方工具查询
- 确保包名准确无误，否则无法打开应用
- 修改前建议备份原始文件
- 部分应用可能需要额外配置才能完全自动化

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

🗑️ 卸载指南

新增功能：项目提供两种卸载方式，可安全清理安装内容

基本卸载（推荐）
卸载 Open-AutoGLM + autoglm 控制面板
- 可选择性删除：pip依赖、项目目录、命令和配置
- 保留运行环境，不影响其他程序

完全卸载（谨慎使用）
除基本卸载内容外，还可选择卸载：
- 核心 pip 包（maturin、openai、requests、Pillow）
- pip/Cargo 镜像配置
- Termux 系统包（python-pillow、rust、android-tools）
- ⚠️ 警告：可能影响依赖这些包的其他程序

执行方式：

```bash
autoglm --uninstall
```

进入交互式卸载菜单，按需选择即可。

---

⚠️ 常见问题与故障排除

1. `adb devices` 不显示设备或显示未授权
   - 检查 USB 调试：开发者选项中必须开启 USB 调试 和 无线调试
   - 检查网络：确保手机和 Termux 在同一 WiFi 网络
   - 授权弹窗：手机上点击 "允许 USB 调试"
   - 重新配对：删除旧配对，重新执行 `adb pair`
   - 重启 ADB：执行 `adb kill-server && adb start-server`

2. 能打开应用但无法点击或输入
   - 开启安全调试：部分手机需要开启 "USB 调试（安全设置）"
   - 必须安装 ADB Keyboard：设置 → 语言和输入法 → 启用 ADB Keyboard
   - 切换输入法：运行时需切换到 ADB Keyboard（Agent 会自动切换）

3. 截图黑屏
   - 敏感页面：支付、银行等应用会黑屏，正常现象
   - 权限限制：部分应用禁止截图，Agent 会请求人工接管

4. 模型连接失败
   - 检查 API Key：确认 Key 有效且未过期
   - 网络问题：确保 Termux 能访问外部网络
   - Base URL：确认 URL 格式正确，结尾有 `/v1`

5. 多设备环境下无法选择设备
   - 使用 `autoglm --devices` 查看所有设备
   - 使用 `autoglm --switch-device` 切换活动设备
   - 或在配置中指定 `PHONE_AGENT_DEVICE_ID="IP:端口"`

6. 环境变量未生效
   
```bash
   # 手动加载配置
   source ~/.bashrc
   # 或
   source ~/.autoglm/config.sh
   ```

7. 卸载后 autoglm 命令仍可用
   - 重新打开终端窗口
   - 或手动执行 `hash -r` 刷新命令缓存

8. 更新失败
   
```bash
   # 手动删除旧目录后重试
   rm -rf ~/Open-AutoGLM
   ./deploy.sh
   ```

---

🔄 更新日志

v4.5.0 (当前版本)
- 增强 ADB 设备管理：支持设备列表查看、切换、断开、快速连接
- 新增一键卸载功能：提供基本卸载和完全卸载两种模式
- 改进多设备支持：可指定设备 ID，自动检测在线设备
- 优化交互体验：设备状态显示更清晰（在线/离线/未授权）
- 修复算术错误：修正设备计数问题
- 扩展命令行参数：新增 `--devices`, `--switch-device`, `--disconnect`, `--uninstall`
- 增强兼容性：支持多种包管理器（apt、yum、pacman、brew）

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
