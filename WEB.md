# AutoGLM Web 管理端（可选安装）

目标：在同一局域网内，用电脑/平板浏览器管理 Termux 上的 AutoGLM（配置/启动/看日志 + ADB 配对、连接、切换、断开）。

## 安全说明（务必阅读）

- Web 管理端默认监听 `0.0.0.0`，意味着同一 Wi-Fi 下其他设备都能访问到端口。
- 本项目使用 **首次运行自动生成的管理 Token** 做鉴权；任何人拿到 Token，都可以控制你的 ADB/AutoGLM。
- Token 会保存在 `~/.autoglm/web_token`，如怀疑泄露请立刻重置：`autoglm-web reset-token`。

## 安装

在 Termux 中执行：

```bash
curl -O https://raw.githubusercontent.com/a251231/AutoGLM-TERMUX/refs/heads/main/install_web.sh
chmod +x install_web.sh
./install_web.sh
```

安装后会生成命令：`~/bin/autoglm-web`（并自动写入 `~/.bashrc` 的 PATH）。

## 启动

```bash
autoglm-web run --host 0.0.0.0 --port 8000
```

启动时会在终端打印 `token`，也可以随时查看：

```bash
autoglm-web token
```

## 访问

1. 获取手机的局域网 IP（例如 `192.168.1.23`）
2. 在电脑/平板浏览器打开：

```
http://192.168.1.23:8000/
```

3. 在页面顶部粘贴 Token，点击“保存 Token”，然后即可使用所有功能。

## 功能范围

- 配置：读取/保存 `~/.autoglm/config.sh`（API Key 页面只显示隐藏值，修改时需重新填写）
- 运行：启动/停止 `~/Open-AutoGLM/main.py`，并写入日志到 `~/.autoglm/web/autoglm.log`
- 日志：页面轮询读取日志（不把 Token 放到 URL）
- ADB：设备列表、配对、连接、断开、重启 ADB 服务、切换活动设备（写入配置中的 `PHONE_AGENT_DEVICE_ID`）

## 常驻服务（termux-services / runit）

如果你希望 Web 管理端在后台常驻（Termux 重启后也能自动拉起），推荐使用 `termux-services`。

### 一键安装并启用

```bash
curl -O https://raw.githubusercontent.com/a251231/AutoGLM-TERMUX/refs/heads/main/install_web_service.sh
chmod +x install_web_service.sh
./install_web_service.sh
```

安装后：

- 服务名：`autoglm-web`
- 服务目录：`$PREFIX/var/service/autoglm-web`
- 日志目录：`~/.autoglm/web_service_logs`
- 环境配置：`~/.autoglm/web_service.env`

### 常用命令

```bash
sv status autoglm-web
sv up autoglm-web
sv down autoglm-web
sv restart autoglm-web
```

也可以用便捷命令：

```bash
autoglm-web-service status
autoglm-web-service tail
```

### 修改监听端口/目录

编辑 `~/.autoglm/web_service.env`，修改后执行：

```bash
sv restart autoglm-web
```

## 常见问题

### 1) 后台被杀 / 断线

Android 可能会杀掉后台进程。建议：

- `termux-wake-lock`（保持唤醒）
- 需要常驻可考虑安装 `termux-services` 并用 `sv` 管理（后续可再集成）

### 2) Open-AutoGLM 目录不在 `~/Open-AutoGLM`

可以在启动前设置环境变量：

```bash
export AUTOGLM_DIR="$HOME/你的路径/Open-AutoGLM"
autoglm-web run --host 0.0.0.0 --port 8000
```
