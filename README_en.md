AutoGLM-Termux Deployment Tool

[![Version](https://img.shields.io/badge/Version-5.0.1-brightgreen)](https://github.com/eraycc/AutoGLM-TERMUX)
[![Open-AutoGLM](https://img.shields.io/badge/Open--AutoGLM-Latest_Release-blue)](https://github.com/zai-org/Open-AutoGLM)
[![Termux](https://img.shields.io/badge/Termux-Supported-black)](https://termux.dev/)
[![License](https://img.shields.io/badge/License-MIT-orange)](https://opensource.org/licenses/MIT)

[🌐 Switch to Chinese document / 切换到中文文档](https://github.com/eraycc/AutoGLM-TERMUX/blob/main/README.md)

Quickly deploy the Open-AutoGLM agent on your Android phone via Termux. Achieve mobile automation without needing ROOT, a PC, or any other device!

---

📖 Project Introduction

AutoGLM-Termux is a one-click deployment solution for Open-AutoGLM optimized for the Termux environment. Using a pure ADB approach, it transforms your Android phone into an AI agent capable of:
- Understanding natural language instructions
- Automatically performing phone operations (tap, swipe, input, etc.)
- Supporting 50+ popular Chinese apps
- Enhanced ADB device management: Supports multi-device switching, quick connection, device status monitoring
- One-click uninstall: Completely removes the project and its runtime environment
- Fully wireless control, no Root, PC, or other devices required
- Comprehensive internationalization support, switching between Chinese and English
- **New:** **Supports voice recognition input**, allowing phone control via voice

> ⚠️ Compliance Statement: This project is for learning and research purposes only. Any illegal use is strictly prohibited. Please comply with the [Open-AutoGLM Terms of Use](https://github.com/zai-org/Open-AutoGLM/blob/main/resources/privacy_policy.txt).

---

✨ Features

- **One-click Deployment:** Automatically installs all dependencies and environment configurations.
- **Smart Mirrors:** Automatically configures pip and Cargo mirrors for faster downloads in China (supports entering `default` to use recommended sources). **Note:** For users outside China, it's recommended to use default or region-specific mirror sources for optimal speed.
- **Wireless ADB:** Built-in ADB wireless debugging setup wizard, say goodbye to cables.
- **Voice Recognition:** Supports voice input commands, freeing your hands (requires Termux:API installation).
- **ADB Device Management:** Visual device list, switch active device, disconnect, quick reconnect.
- **Interactive Menu:** Visual launch panel for easier configuration management.
- **Auto-reconnect:** Supports automatic ADB device detection and connection.
- **Persistent Configuration:** Environment variables are automatically saved; no need to reconfigure after restarting Termux.
- **Multi-device Support:** In the same LAN (with VPN off), an Android device can use wireless debugging to connect to and automatically control other Android phone devices via ADB. Supports managing multiple ADB devices.
- **One-click Uninstall:** Offers both basic and complete uninstall modes for clean removal without leftovers.
- **New:** Multi-language support, freely switch between Chinese and English.

---

🍭 Deployment Demo

![1000114284](https://github.com/user-attachments/assets/d4e89a3c-8d39-41a8-a44e-bed00c74fdb0)

![1000114273](https://github.com/user-attachments/assets/3ca780ce-631c-4ae3-996a-8f3bf4eb4037)

![1000114283](https://github.com/user-attachments/assets/dd618ffc-4138-4bcf-bf0a-03562b364875)

---

📱 Prerequisites

1.  An Android phone (Android 7.0+)
2.  Termux installed ([Download Link](https://github.com/termux/termux-app/releases/))
3.  Network Connection: Phone and Termux device must be on the same WiFi network.
4.  API Key: Requires an API key from Zhipu AI, ModelScope, or another AI model that supports image recognition.

5.  **Voice Recognition (Optional):** For voice control, install the Termux:API app.
    - Download: https://github.com/termux/termux-api/releases/
    - After installation, go to **Settings > Apps (App Management)** or long-press the Termux:API icon on the desktop, enter the app permission management interface, and grant **Microphone** permission.
    > For older Android versions or if the above Termux:API APK cannot be installed, refer to official docs: [Termux-microphone-record](https://wiki.termux.com/wiki/Termux-microphone-record), [Termux:API](https://wiki.termux.com/wiki/Termux:API), or try downloading a compatible version from [f-droid](https://f-droid.org/packages/com.termux.api/).

6.  **ADB Keyboard (Mandatory):**
    - Download: https://github.com/senzhk/ADBKeyBoard/blob/master/ADBKeyboard.apk
    - After installation, go to **Settings → System → Languages & input → Virtual keyboard → Manage keyboards**, and enable **"ADB Keyboard"**.
    - **This step is mandatory, otherwise Chinese input will not work.**
    > For older Android systems like Android 7 and below, if the above ADB Keyboard cannot be installed, try this version: https://github.com/eraycc/AutoGLM-TERMUX/blob/main/ADBKeyboard/ADBKeyboard.apk

---

🚀 Quick Start (Recommended)

Execute the following commands in Termux to complete deployment or update with one click:

```bash
# 1. Update Termux package lists
pkg upgrade -y

# 2. Download the deployment script
curl -O https://raw.githubusercontent.com/eraycc/AutoGLM-TERMUX/refs/heads/main/deploy.sh

# 3. Grant execution permission
chmod +x deploy.sh

# 4. Run the deployment script
./deploy.sh
```

After deployment is complete, enter `autoglm` to launch the intelligent control panel.

---

📋 Detailed Deployment Steps

If you need more detailed installation guidance, follow these steps:

**Step 1: Install Termux**

Download the latest Termux APK from [GitHub Releases](https://github.com/termux/termux-app/releases/) and install it.

**Step 2: Update Termux**

After launching Termux for the first time, execute:

```bash
pkg upgrade -y
```

**Step 3: Set up Termux pkg download mirror source**

Execute the command below to open the Termux pkg mirror source configuration GUI:
- Select `Mirror group - Rotate between several mirrors (recommended)`
- Click OK to enter, use the up/down arrow keys to select `Mirrors in Chinese Mainland - All in Chinese Mainland`
- Click OK again, and wait for the automatic configuration to complete.

```bash
termux-change-repo
```
> **Note for international users:** If you are not in China, you may skip this step or choose a mirror group closer to your region for better download speeds. Using Chinese mainland mirrors might be slower outside China.

**Step 4: Run the deployment script**

```bash
curl -O https://raw.githubusercontent.com/eraycc/AutoGLM-TERMUX/refs/heads/main/deploy.sh
chmod +x deploy.sh
./deploy.sh
```

**Step 5: Script Execution Flow**

The script will automatically perform the following:

1.  **Language Selection:** Prompts to choose between Chinese or English interface on first run.
2.  **Install Dependencies:** Python, pip, Git, Rust, ADB (automatically detects multiple package managers).
3.  **Configure Mirror Sources:** Optionally configures pip/Cargo mirrors for faster downloads in China (enter `default` to use recommended sources). **Users elsewhere should use default or their regional sources.**
4.  **Install Python Packages:** maturin, openai, requests, Pillow (Pillow is installed via pkg in Termux environment).
5.  **Clone Project:** Pulls the latest Open-AutoGLM code from GitHub.
6.  **Voice Recognition Setup:** Option to enable voice control functionality.
7.  **Interactive Configuration:** Set API Key, model parameters, etc. (new device ID configuration).
8.  **ADB Keyboard Reminder:** Prompts to install the required input method tool (mandatory step).
9.  **ADB Wireless Configuration:** Guides you through setting up phone wireless debugging connection (supports auto-detection of connected devices).
10. **Create Launcher:** Generates the `autoglm` shortcut command and automatically adds it to PATH.

---

🎮 Usage

**Launch Control Panel**

```bash
autoglm
```

**Main Menu Functions**

```
1. 🚀 Start with current config    # Directly run AutoGLM (auto-detects device)
2. 🎤 Start with voice recognition # Control phone via voice input (requires voice feature enabled)
3. 📱 ADB Device Management      # Enter enhanced device management submenu
4. ⚙️  Modify AI config          # Modify API Key, model, etc.
5. 🎙️ Modify voice recognition config # Modify voice recognition parameters
6. 📋 View supported apps list   # Display list of 50+ supported apps
7. 🔍 View detailed config       # Display all current configuration info
8. 🌐 Switch Language / 切换语言  # Switch between Chinese and English interface
9. 🗑️ One-click uninstall       # Enter uninstall menu
0. ❌ Exit                      # Exit the program
```

**ADB Device Management Submenu**

```
1. 📱 Pair new device (Pair + Connect)
2. ⚡ Quick Connect (Already paired)
3. 📋 View detailed device list
4. 🔄 Switch active device
5. 🔌 Disconnect device
6. ❓ ADB Keyboard installation guide
0. ↩️ Return to main menu
```

**Command-line Arguments**

```bash
# Directly start interactive mode (bypass menu)
autoglm --start or autoglm -s

# Single task mode
autoglm --start "Task description" or autoglm -s "Task description"

# ADB Device Management (enter submenu)
autoglm --setup-adb

# Quickly view device list
autoglm --devices

# Switch active device
autoglm --switch-device

# Disconnect device
autoglm --disconnect

# Modify configuration
autoglm --reconfig

# View supported apps
autoglm --list-apps

# One-click uninstall (enter uninstall menu)
autoglm --uninstall

# Switch language
autoglm --lang cn    # Switch to Chinese
autoglm --lang en    # Switch to English

# Voice recognition mode (requires voice feature enabled)
autoglm --voice

# Manually specify parameters to start
autoglm --base-url URL --model MODEL --apikey KEY --device-id ID "Your instruction"

# Show help
autoglm --help
```

**Usage Examples**

```bash
# Example 1: Open Meituan and search for hotpot
autoglm
# Then enter in the interactive interface: "Open Meituan and search for nearby hotpot restaurants"

# Example 2: Voice control (requires voice feature enabled)
autoglm --voice
# Follow prompts and say command: "Open WeChat and send a message to Zhang San"

# Example 3: Directly execute instruction
autoglm --base-url https://open.bigmodel.cn/api/paas/v4 \
        --model autoglm-phone \
        --apikey sk-xxxxx \
        "Open WeChat and send message to File Transfer Assistant: Hello World"

# Example 4: Switch to a specific device in multi-device environment
autoglm --switch-device
# Or specify directly via command line
autoglm --device-id 192.168.1.100:5555 "Open Bilibili"

# Example 5: Quickly view status of all devices
autoglm --devices

# Example 6: Switch language to English
autoglm --lang en
```

---

🎯 Advanced: Customizing & Extending App Support

Besides the built-in 50+ popular apps, you can modify the configuration file to make AutoGLM support one-click launching of more apps.

**Preparation**

1.  Download and install MT Manager (a file manager for Android)
    Download link: https://mt2.cn/download/

**Configuration Steps**

**Step 1: Grant MT Manager access to Termux files**
1.  Open MT Manager, expand the sidebar.
2.  Click the "three dots" menu button at the top, select "Add local storage".
3.  In the new interface, click the top-left "three dots" again to open the sidebar.
4.  Find and select "Termux" (shows available space: xx GB).
5.  Click "Use this folder" to authorize.

**Step 2: Modify the app configuration file**
1.  Return to MT Manager homepage, find "Termux Home" in the sidebar.
2.  Navigate to directory: `Open-AutoGLM/phone_agent/config/`
3.  Open the `apps.py` file.
4.  Locate the `APP_PACKAGES` configuration dictionary.
5.  Add your custom apps at the end of the dictionary, format: `"App Name": "App Package Name"`

**Example Configuration**
Add at the end of the `APP_PACKAGES` dictionary:

```python
    # Custom Apps
    "via": "mark.via",
    "浏览器": "mark.via", # "Browser"
    "via浏览器": "mark.via", # "via Browser"
    "米游社": "com.mihoyo.hyperion",
    "fclash": "com.follow.clash",
    "clash": "com.github.metacubex.clash.meta",
    "云原神": "com.miHoYo.cloudgames.ys",
    "firefox": "org.mozilla.firefox",
    "telegram": "org.telegram.messenger.web",
    "kimi": "com.moonshot.kimichat",
    "酷狗概念版": "com.kugou.android.lite",
    "mt管理器": "bin.mt.plus",
    "youtube": "com.google.android.youtube",
    # Add more...
```

**Notes**
- App package names can be queried via app store links or third-party tools (MT Manager sidebar -> Tools -> Extract APK can also show it).
- Ensure the package name is accurate, otherwise the app cannot be opened.
- It's recommended to back up the original file before modifying.
- Some apps may require additional configuration for full automation.

---

⚙️ Configuration

**Environment Variables**
After deployment, configurations are saved in `~/.autoglm/config.sh`, including:

Variable Name | Description | Default Value
:--- | :--- | :---
`PHONE_AGENT_BASE_URL` | API Base URL | `https://open.bigmodel.cn/api/paas/v4`
`PHONE_AGENT_MODEL` | Model Name | `autoglm-phone`
`PHONE_AGENT_API_KEY` | Your API Key | `sk-your-apikey`
`PHONE_AGENT_MAX_STEPS` | Max Execution Steps | `100`
`PHONE_AGENT_DEVICE_ID` | ADB Device ID (New) | Auto-detected (leave empty)
`PHONE_AGENT_LANG` | Language | `cn`
`VOICE_ENABLED` | Voice Recognition Switch | `false`
`VOICE_API_BASE_URL` | Voice Recognition API Base URL | https://api.siliconflow.cn/v1
`VOICE_API_MODEL` | Voice Recognition Model | FunAudioLLM/SenseVoiceSmall
`VOICE_API_KEY` | Voice Recognition API Key | sk-your-key
`VOICE_MAX_DURATION` | Maximum Recording Duration (seconds) | 60

**New Variables Explained:**
- `PHONE_AGENT_DEVICE_ID`: Specifies the device to control in multi-device environments. Format: IP:Port or device serial number. If left empty, the only online device is auto-detected.
- `VOICE_ENABLED`: Whether voice recognition is enabled.
- `VOICE_API_BASE_URL`: Base URL for the voice recognition service.
- `VOICE_API_MODEL`: Voice recognition model to use.
- `VOICE_MAX_DURATION`: Maximum recording time per session (seconds).

**Supported Model Services (AI model needs image recognition capability)**

1.  **Zhipu BigModel** (Recommended, currently the official autoglm-phone model is [temporarily free](https://docs.bigmodel.cn/cn/guide/models/vlm/autoglm-phone))
    - Base URL: `https://open.bigmodel.cn/api/paas/v4`
    - Model: `autoglm-phone`
    - Registration: [BigModel AFF Invite](https://www.bigmodel.cn/claude-code?ic=COJZ8EMHXZ)
    - API Key Application: [Zhipu apikeys](https://open.bigmodel.cn/usercenter/proj-mgmt/apikeys)

2.  **ModelScope Community**
    - Base URL: `https://api-inference.modelscope.cn/v1`
    - Model: `ZhipuAI/AutoGLM-Phone-9B`
    - Application: [ModelScope Platform](https://modelscope.cn/)

3.  **Other Custom AI API integration with AutoGLM**
    - Supports OpenAI-compatible format API interfaces.
    - Must ensure the model has image understanding capability.

4.  **Voice Recognition Service (Optional)**
    - Requires: An OpenAI-compatible format AI speech recognition API.
    - Recommended Platform: [SiliconFlow AFF Invite](https://cloud.siliconflow.cn/i/eQGNraUT), free 20M Tokens upon registration.
    - Base URL: `https://api.siliconflow.cn/v1`
    - Recommended Model: `FunAudioLLM/SenseVoiceSmall` (currently free) [SiliconFlow Model Pricing](https://siliconflow.cn/pricing)
    - API Key Application: [SiliconFlow apikey](https://cloud.siliconflow.cn/me/account/ak)
    > Voice recognition can also use Zhipu BigModel's `glm-asr-2512` model. See [Official Documentation](https://docs.bigmodel.cn/cn/guide/models/sound-and-video/glm-asr-2512).

---

📦 Project Structure

```
~/
├── Open-AutoGLM/                 # Project code
├── .autoglm/
│   └── config.sh                # Configuration file
├── bin/
│   └── autoglm                  # Launch script (automatically added to PATH)
└── .cargo/
    └── config.toml              # Cargo mirror configuration
```

---

🔍 Supported Apps List

Run `autoglm --list-apps` to view the complete list, mainly including:

- Social & Communication: WeChat, QQ, Weibo
- E-commerce & Shopping: Taobao, JD.com, Pinduoduo
- Food Delivery: Meituan, Ele.me, KFC
- Travel & Transportation: Ctrip, 12306, Didi Chuxing
- Video & Entertainment: Bilibili, Douyin (TikTok), iQiyi
- Music & Audio: NetEase Cloud Music, QQ Music, Himalaya
- Lifestyle Services: Dianping (Meituan), Gaode Maps, Baidu Maps
- Content Communities: Xiaohongshu (RED), Zhihu, Douban

---

🗑️ Uninstall Guide

**New Feature:** The project provides two uninstall modes for safe cleanup.

**Basic Uninstall (Recommended)**
Uninstalls Open-AutoGLM + the autoglm control panel.
- Selective deletion: pip dependencies, project directory, command, and configuration.
- Keeps the runtime environment, doesn't affect other programs.

**Complete Uninstall (Use with Caution)**
In addition to Basic Uninstall contents, you can also choose to uninstall:
- Core pip packages (maturin, openai, requests, Pillow)
- pip/Cargo mirror configuration
- Termux system packages (python-pillow, rust, android-tools)
- ⚠️ Warning: May affect other programs relying on these packages.

**Execution:**

```bash
autoglm --uninstall
```

Enter the interactive uninstall menu and select as needed.

---

⚠️ Common Issues & Troubleshooting

1.  **`adb devices` shows no device or device unauthorized**
    - Check USB Debugging: Must enable **USB debugging** and **Wireless debugging** in Developer Options.
    - Check Network: Ensure phone and Termux are on the same WiFi network.
    - Authorization Popup: Tap **"Allow USB debugging"** on the phone.
    - Re-pair: Delete old pairing and execute `adb pair` again.
    - Restart ADB: Execute `adb kill-server && adb start-server`.

2.  **Apps open but can't click or input**
    - Enable Secure Debugging: Some phones need **"USB debugging (Security settings)"** enabled.
    - Must Install ADB Keyboard: Settings → Languages & input → Enable **ADB Keyboard**.
    - Switch Input Method: Need to switch to ADB Keyboard when running (Agent will do this automatically).

3.  **Screenshot is black**
    - Sensitive Pages: Payment, banking apps will show black screens, this is normal.
    - Permission Restrictions: Some apps prohibit screenshots; Agent will request manual takeover.

4.  **Model Connection Failure**
    - Check API Key: Confirm Key is valid and not expired.
    - Network Issue: Ensure Termux can access external networks.
    - Base URL: Confirm URL format is correct, ending with `/v1` if applicable.

5.  **Cannot select device in multi-device environment**
    - Use `autoglm --devices` to view all devices.
    - Use `autoglm --switch-device` to switch the active device.
    - Or specify `PHONE_AGENT_DEVICE_ID="IP:Port"` in the configuration.

6.  **Environment variables not taking effect**

```bash
   # Manually load configuration
   source ~/.bashrc
   # or
   source ~/.autoglm/config.sh
   ```

7.  **`autoglm` command still works after uninstall**
    - Reopen the terminal window.
    - Or manually execute `source ~/.bashrc` to reload configuration.
    - Or manually execute `hash -r` to refresh command cache.

8.  **Update failed**

```bash
   # Manually delete old directory and retry
   rm -rf ~/Open-AutoGLM
   ./deploy.sh
   ```

9.  **Language switching issue**
    - Use `autoglm --lang cn` or `autoglm --lang en` to switch language.
    - Or select the "Switch Language" option in the main menu.

10. **Voice recognition function not working**
    - Ensure voice recognition was enabled during deployment.
    - Check if Termux:API app is installed and microphone permission is granted.
    - Confirm voice recognition API configuration is correct.
    - Check network connection is normal.

11. **ADB Keyboard installed but shows error on startup**
    - Ensure ADB Keyboard is installed and enabled.
    - If multiple devices are paired via ADB wireless debugging and switching to another device causes ADB Keyboard error, try restarting Termux and reconnecting, or enter the ADB management menu to disconnect all connections, restart ADB, reconnect, and then start AutoGLM again.

---

🔄 Changelog

**v5.0.1 (Current Version)**
- New: Comprehensive voice recognition support, control phone via voice.
- New: Voice recognition configuration wizard, supports multiple services.
- Fix: Voice recognition and quick start issues.
- Optimize: Interactive menu, dynamically displays voice function options.

**v4.6.0**
- New: Full internationalization support, switch between Chinese/English interfaces.
- New: Language selection wizard, choose language during deployment.

**v4.5.0**
- Enhanced ADB device management: Supports viewing device list, switching, disconnecting, quick connect.
- New one-click uninstall function: Provides basic and complete uninstall modes.
- Improved multi-device support: Can specify device ID, auto-detects online devices.
- Optimized interactive experience: Clearer device status display (online/offline/unauthorized).
- Fixed arithmetic error: Corrected device count issue.
- Extended command-line arguments: Added `--devices`, `--switch-device`, `--disconnect`, `--uninstall`.
- Enhanced compatibility: Supports multiple package managers (apt, yum, pacman, brew).

**v4.3.0**
- New interactive launch panel `autoglm` command.
- Supports wireless ADB pairing and connection wizard.
- Automatic configuration of pip and Cargo mirrors for China.
- Supports multi-device management.

**v4.2.0**
- Optimized Termux compatibility.
- Added ADB Keyboard installation reminder.
- Supports configuration persistence.

---

🤝 Contributing

Issues and Pull Requests are welcome!

1.  Fork this repository.
2.  Create your feature branch (`git checkout -b feature/AmazingFeature`).
3.  Commit your changes (`git commit -m 'Add some AmazingFeature'`).
4.  Push to the branch (`git push origin feature/AmazingFeature`).
5.  Open a Pull Request.

---

📄 License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

---

🔗 Related Links

- Open-AutoGLM Official Project: https://github.com/zai-org/Open-AutoGLM
- Termux Official Website: https://termux.dev/
- AutoGLM Paper: https://arxiv.org/abs/2411.00820
- Zhipu AI: https://www.zhipuai.cn/
- ModelScope: https://modelscope.cn/
- SiliconFlow (Voice Recognition): https://siliconflow.cn/

---

🙏 Acknowledgments

- [Open-AutoGLM](https://github.com/zai-org/Open-AutoGLM) - Core framework.
- [ADBKeyBoard](https://github.com/senzhk/ADBKeyBoard) - Input solution.
- [Termux](https://termux.dev/) - Powerful terminal emulator.
- [Termux:API](https://github.com/termux/termux-api) - Voice recognition support.

---

💬 Community & Support

Encountered a problem? Need help?

- Submit an [Issue](https://github.com/eraycc/AutoGLM-TERMUX/issues).
- Check the [Open-AutoGLM Documentation](https://github.com/zai-org/Open-AutoGLM/blob/main/README.md).
- Join the Open-AutoGLM WeChat community (see the official project README).

---

⭐ If this project helped you, please give it a Star!

---

📢 Disclaimer

This project is only an automated deployment tool for Open-AutoGLM. All core functionalities are provided by Open-AutoGLM. Please ensure compliance with local laws and regulations and use this tool legally. The developers are not responsible for any misuse.
