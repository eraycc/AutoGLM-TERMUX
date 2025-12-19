from __future__ import annotations

import os
from typing import Any

from fastapi import Depends, FastAPI, HTTPException
from fastapi.responses import HTMLResponse, JSONResponse

from . import __version__
from .adb import connect, devices, disconnect, pair, restart_server
from .autoglm_process import start as start_autoglm
from .autoglm_process import status as autoglm_status
from .autoglm_process import stop as stop_autoglm
from .autoglm_process import tail_log
from .auth import AuthResult, require_token
from .config import AutoglmConfig, read_config, write_config

app = FastAPI(title="AutoGLM Web", version=__version__)


def _server_info() -> dict[str, Any]:
    return {
        "version": __version__,
        "host": os.environ.get("AUTOGLM_WEB_HOST", "0.0.0.0"),
        "port": int(os.environ.get("AUTOGLM_WEB_PORT", "8000")),
    }


@app.get("/health")
def health() -> dict[str, str]:
    return {"status": "ok"}


@app.get("/", response_class=HTMLResponse)
def index() -> str:
    return f"""<!doctype html>
<html lang="zh-CN">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>AutoGLM Web</title>
  <style>
    :root {{ color-scheme: light dark; }}
    body {{ font-family: system-ui, -apple-system, Segoe UI, Roboto, Arial; margin: 0; padding: 18px; }}
    .wrap {{ max-width: 1100px; margin: 0 auto; }}
    .row {{ display: flex; gap: 12px; flex-wrap: wrap; }}
    .card {{ border: 1px solid rgba(128,128,128,.35); border-radius: 10px; padding: 14px; flex: 1; min-width: 320px; }}
    label {{ display:block; font-size: 12px; opacity:.8; margin-top:10px; }}
    input, textarea {{ width: 100%; padding: 10px; border-radius: 8px; border: 1px solid rgba(128,128,128,.35); background: transparent; }}
    button {{ padding: 10px 12px; border-radius: 8px; border: 1px solid rgba(128,128,128,.35); background: transparent; cursor: pointer; }}
    button.primary {{ background: rgba(0, 120, 255, .15); }}
    button.danger {{ background: rgba(255, 0, 0, .12); }}
    .muted {{ opacity: .75; font-size: 12px; }}
    pre {{ white-space: pre-wrap; word-break: break-word; border: 1px solid rgba(128,128,128,.35); border-radius: 10px; padding: 12px; min-height: 220px; max-height: 420px; overflow: auto; }}
    table {{ width: 100%; border-collapse: collapse; }}
    th, td {{ border-bottom: 1px solid rgba(128,128,128,.25); padding: 8px; text-align: left; font-size: 13px; }}
    .pill {{ display:inline-block; padding: 2px 8px; border-radius: 999px; border: 1px solid rgba(128,128,128,.35); font-size: 12px; }}
    code {{ font-family: ui-monospace, SFMono-Regular, Menlo, Consolas, monospace; font-size: 12px; }}
  </style>
</head>
<body>
  <div class="wrap">
    <h2 style="margin:0 0 6px 0;">AutoGLM Web <span class="muted">v{__version__}</span></h2>
    <div class="muted" id="serverInfo"></div>

    <div class="card" style="margin-top:12px;">
      <div class="row" style="align-items:end;">
        <div style="flex:1; min-width:240px;">
          <label>管理 Token（首次运行后由 autoglm-web 生成）</label>
          <input id="token" placeholder="粘贴 Token（将保存在本浏览器 localStorage）" />
        </div>
        <div style="display:flex; gap:8px;">
          <button class="primary" onclick="saveToken()">保存 Token</button>
          <button onclick="clearToken()">清除</button>
          <button onclick="refreshAll()">刷新全部</button>
        </div>
      </div>
      <div class="muted">
        安全提示：不要把 Token 发给任何人；如怀疑泄露，请在 Termux 执行 <code>autoglm-web reset-token</code>。
      </div>
    </div>

    <div class="row" style="margin-top:12px;">
      <div class="card">
        <h3 style="margin-top:0;">配置</h3>
        <label>Base URL</label>
        <input id="base_url" />
        <label>Model</label>
        <input id="model" />
        <label>API Key</label>
        <input id="api_key" placeholder="为空则保持不变" />
        <label>Max Steps</label>
        <input id="max_steps" />
        <label>语言 (cn/en)</label>
        <input id="lang" />
        <label>Device ID（留空自动检测）</label>
        <input id="device_id" />
        <div class="row" style="margin-top:12px;">
          <button class="primary" onclick="saveConfig()">保存配置</button>
          <button onclick="loadConfig()">重新加载</button>
        </div>
        <div class="muted" id="configMsg"></div>
      </div>

      <div class="card">
        <h3 style="margin-top:0;">ADB 管理</h3>
        <div class="row" style="align-items:end;">
          <div style="flex:1; min-width:240px;">
            <label>配对 IP:Port（Wireless Debugging 配对弹窗）</label>
            <input id="pair_host" placeholder="例如 192.168.1.13:42379" />
          </div>
          <div style="width:180px;">
            <label>配对码</label>
            <input id="pair_code" placeholder="6 位数字" />
          </div>
          <button class="primary" onclick="adbPair()">配对</button>
        </div>
        <div class="row" style="align-items:end; margin-top:10px;">
          <div style="flex:1; min-width:240px;">
            <label>连接 IP:Port（Wireless Debugging 主界面）</label>
            <input id="connect_host" placeholder="例如 192.168.1.13:5555" />
          </div>
          <button class="primary" onclick="adbConnect()">连接</button>
          <button onclick="adbDisconnectAll()">断开全部</button>
          <button onclick="adbRestart()">重启 ADB 服务</button>
        </div>

        <div style="margin-top:12px;">
          <div class="row" style="align-items:center;">
            <h4 style="margin:0; flex:1;">设备列表</h4>
            <button onclick="loadDevices()">刷新</button>
          </div>
          <table>
            <thead>
              <tr><th>Serial</th><th>Status</th><th>Model</th><th>操作</th></tr>
            </thead>
            <tbody id="devicesBody"></tbody>
          </table>
        </div>
        <div class="muted" id="adbMsg"></div>
      </div>
    </div>

    <div class="row" style="margin-top:12px;">
      <div class="card">
        <h3 style="margin-top:0;">运行</h3>
        <div class="row">
          <button class="primary" onclick="autoglmStart()">启动 AutoGLM</button>
          <button class="danger" onclick="autoglmStop()">停止 AutoGLM</button>
          <button onclick="autoglmStatus()">刷新状态</button>
        </div>
        <div style="margin-top:10px;">
          <span class="pill" id="runPill">unknown</span>
          <span class="muted" id="runMsg"></span>
        </div>
      </div>

      <div class="card">
        <h3 style="margin-top:0;">日志</h3>
        <div class="row" style="align-items:center;">
          <button onclick="clearLogView()">清屏</button>
          <button onclick="toggleFollow()" id="followBtn">暂停滚动</button>
          <span class="muted">自动轮询（本页不把 Token 放到 URL）</span>
        </div>
        <pre id="logBox"></pre>
      </div>
    </div>
  </div>

<script>
const LS_TOKEN_KEY = "autoglm_web_token";
let logOffset = 0;
let follow = true;

function authHeader() {{
  const t = localStorage.getItem(LS_TOKEN_KEY) || "";
  return t ? {{ "Authorization": "Bearer " + t }} : {{}};
}}

function setMsg(id, msg) {{
  const el = document.getElementById(id);
  if (el) el.textContent = msg || "";
}}

function saveToken() {{
  const t = document.getElementById("token").value.trim();
  if (!t) return;
  localStorage.setItem(LS_TOKEN_KEY, t);
  refreshAll();
}}

function clearToken() {{
  localStorage.removeItem(LS_TOKEN_KEY);
  document.getElementById("token").value = "";
  setMsg("configMsg", "Token 已清除");
}}

async function apiJson(path, options={{}}) {{
  const headers = Object.assign({{ "Content-Type": "application/json" }}, authHeader(), options.headers || {{}});
  const resp = await fetch(path, Object.assign({{}}, options, {{ headers }}));
  const text = await resp.text();
  let data = null;
  try {{ data = text ? JSON.parse(text) : null; }} catch (e) {{ data = null; }}
  if (!resp.ok) {{
    const msg = (data && data.detail) ? data.detail : text || (resp.status + "");
    throw new Error(msg);
  }}
  return data;
}}

async function loadConfig() {{
  try {{
    const data = await apiJson("/api/config");
    document.getElementById("base_url").value = data.base_url || "";
    document.getElementById("model").value = data.model || "";
    document.getElementById("api_key").value = "";
    document.getElementById("max_steps").value = data.max_steps || "";
    document.getElementById("device_id").value = data.device_id || "";
    document.getElementById("lang").value = data.lang || "";
    setMsg("configMsg", "配置已加载（API Key 已隐藏，修改时请重新填写）");
  }} catch (e) {{
    setMsg("configMsg", "加载失败: " + e.message);
  }}
}}

async function saveConfig() {{
  const payload = {{
    base_url: document.getElementById("base_url").value.trim(),
    model: document.getElementById("model").value.trim(),
    api_key: document.getElementById("api_key").value.trim(),
    max_steps: document.getElementById("max_steps").value.trim(),
    device_id: document.getElementById("device_id").value.trim(),
    lang: document.getElementById("lang").value.trim(),
  }};
  try {{
    const data = await apiJson("/api/config", {{ method: "POST", body: JSON.stringify(payload) }});
    setMsg("configMsg", data.message || "已保存");
    await loadConfig();
  }} catch (e) {{
    setMsg("configMsg", "保存失败: " + e.message);
  }}
}}

function renderDevices(list, selected) {{
  const body = document.getElementById("devicesBody");
  body.innerHTML = "";
  for (const d of list) {{
    const tr = document.createElement("tr");
    const isSelected = selected && d.serial === selected;
    tr.innerHTML = `
      <td>${{d.serial}} ${{isSelected ? '<span class="pill">selected</span>' : ''}}</td>
      <td>${{d.status}}</td>
      <td>${{d.model || ''}}</td>
      <td>
        <button onclick="selectDevice('${{d.serial}}')">选用</button>
        <button onclick="disconnectOne('${{d.serial}}')">断开</button>
      </td>
    `;
    body.appendChild(tr);
  }}
}}

async function loadDevices() {{
  try {{
    const data = await apiJson("/api/adb/devices");
    renderDevices(data.devices || [], data.selected_device || "");
    setMsg("adbMsg", "设备已刷新");
  }} catch (e) {{
    setMsg("adbMsg", "刷新失败: " + e.message);
  }}
}}

async function adbPair() {{
  const host = document.getElementById("pair_host").value.trim();
  const code = document.getElementById("pair_code").value.trim();
  try {{
    const data = await apiJson("/api/adb/pair", {{ method: "POST", body: JSON.stringify({{ host, code }}) }});
    setMsg("adbMsg", data.output || data.message || "完成");
    await loadDevices();
  }} catch (e) {{
    setMsg("adbMsg", "配对失败: " + e.message);
  }}
}}

async function adbConnect() {{
  const host = document.getElementById("connect_host").value.trim();
  try {{
    const data = await apiJson("/api/adb/connect", {{ method: "POST", body: JSON.stringify({{ host }}) }});
    setMsg("adbMsg", data.output || data.message || "完成");
    await loadDevices();
  }} catch (e) {{
    setMsg("adbMsg", "连接失败: " + e.message);
  }}
}}

async function disconnectOne(serial) {{
  try {{
    const data = await apiJson("/api/adb/disconnect", {{ method: "POST", body: JSON.stringify({{ target: serial }}) }});
    setMsg("adbMsg", data.output || data.message || "完成");
    await loadDevices();
  }} catch (e) {{
    setMsg("adbMsg", "断开失败: " + e.message);
  }}
}}

async function adbDisconnectAll() {{
  try {{
    const data = await apiJson("/api/adb/disconnect", {{ method: "POST", body: JSON.stringify({{ target: "" }}) }});
    setMsg("adbMsg", data.output || data.message || "完成");
    await loadDevices();
  }} catch (e) {{
    setMsg("adbMsg", "断开失败: " + e.message);
  }}
}}

async function adbRestart() {{
  try {{
    const data = await apiJson("/api/adb/restart", {{ method: "POST" }});
    setMsg("adbMsg", data.output || data.message || "完成");
    await loadDevices();
  }} catch (e) {{
    setMsg("adbMsg", "重启失败: " + e.message);
  }}
}}

async function selectDevice(serial) {{
  try {{
    const data = await apiJson("/api/config/device", {{ method: "POST", body: JSON.stringify({{ device_id: serial }}) }});
    setMsg("adbMsg", data.message || "已设置");
    await loadDevices();
  }} catch (e) {{
    setMsg("adbMsg", "设置失败: " + e.message);
  }}
}}

async function autoglmStart() {{
  try {{
    const data = await apiJson("/api/autoglm/start", {{ method: "POST" }});
    setMsg("runMsg", data.message || "已启动");
    await autoglmStatus();
  }} catch (e) {{
    setMsg("runMsg", "启动失败: " + e.message);
  }}
}}

async function autoglmStop() {{
  try {{
    const data = await apiJson("/api/autoglm/stop", {{ method: "POST" }});
    setMsg("runMsg", data.message || "已停止");
    await autoglmStatus();
  }} catch (e) {{
    setMsg("runMsg", "停止失败: " + e.message);
  }}
}}

async function autoglmStatus() {{
  try {{
    const data = await apiJson("/api/autoglm/status");
    document.getElementById("runPill").textContent = data.running ? ("running pid=" + data.pid) : "stopped";
  }} catch (e) {{
    document.getElementById("runPill").textContent = "unknown";
    setMsg("runMsg", "状态获取失败: " + e.message);
  }}
}}

function clearLogView() {{
  document.getElementById("logBox").textContent = "";
}}

function toggleFollow() {{
  follow = !follow;
  document.getElementById("followBtn").textContent = follow ? "暂停滚动" : "恢复滚动";
}}

async function pollLogs() {{
  try {{
    const data = await apiJson("/api/logs/tail?offset=" + logOffset);
    if (data && data.text) {{
      const box = document.getElementById("logBox");
      box.textContent += data.text;
      if (follow) box.scrollTop = box.scrollHeight;
    }}
    logOffset = data.offset || logOffset;
  }} catch (e) {{
    // token 未填/服务未启动时会报错，忽略即可
  }}
  setTimeout(pollLogs, 1000);
}}

async function refreshAll() {{
  await loadConfig();
  await loadDevices();
  await autoglmStatus();
}}

async function loadServerInfo() {{
  const r = await fetch("/api/info");
  const j = await r.json();
  document.getElementById("serverInfo").textContent = "监听 " + j.host + ":" + j.port + "（同一局域网可访问）";
}}

document.getElementById("token").value = localStorage.getItem(LS_TOKEN_KEY) || "";
loadServerInfo();
refreshAll();
pollLogs();
</script>
</body>
</html>"""


@app.get("/api/info")
def info() -> dict[str, Any]:
    return _server_info()


@app.get("/api/config")
def get_config(_: AuthResult = Depends(require_token)) -> JSONResponse:
    cfg = read_config()
    return JSONResponse(cfg.as_public_dict(mask_api_key=True))


@app.post("/api/config")
def set_config(payload: dict[str, Any], _: AuthResult = Depends(require_token)) -> dict[str, Any]:
    cfg = read_config()
    base_url = str(payload.get("base_url", cfg.base_url) or cfg.base_url).strip()
    model = str(payload.get("model", cfg.model) or cfg.model).strip()
    api_key = str(payload.get("api_key", "") or "").strip()
    max_steps = str(payload.get("max_steps", cfg.max_steps) or cfg.max_steps).strip()
    device_id = str(payload.get("device_id", cfg.device_id) or "").strip()
    lang = str(payload.get("lang", cfg.lang) or cfg.lang).strip()

    if not api_key:
        api_key = cfg.api_key

    updated = AutoglmConfig(
        base_url=base_url,
        model=model,
        api_key=api_key,
        max_steps=max_steps,
        device_id=device_id,
        lang=lang,
    )
    write_config(updated)
    return {"ok": True, "message": "配置已保存"}


@app.post("/api/config/device")
def set_device(payload: dict[str, Any], _: AuthResult = Depends(require_token)) -> dict[str, Any]:
    cfg = read_config()
    device_id = str(payload.get("device_id", "") or "").strip()
    updated = AutoglmConfig(
        base_url=cfg.base_url,
        model=cfg.model,
        api_key=cfg.api_key,
        max_steps=cfg.max_steps,
        device_id=device_id,
        lang=cfg.lang,
    )
    write_config(updated)
    return {"ok": True, "message": f"已设置设备: {device_id or '自动检测'}"}


@app.get("/api/adb/devices")
def adb_devices(_: AuthResult = Depends(require_token)) -> dict[str, Any]:
    cfg = read_config()
    return {"devices": [d.__dict__ for d in devices()], "selected_device": cfg.device_id or ""}


@app.post("/api/adb/pair")
def adb_pair(payload: dict[str, Any], _: AuthResult = Depends(require_token)) -> dict[str, Any]:
    host = str(payload.get("host", "") or "").strip()
    code = str(payload.get("code", "") or "").strip()
    if not host or not code:
        raise HTTPException(status_code=400, detail="host/code 不能为空")
    ok, out = pair(host, code)
    if not ok:
        raise HTTPException(status_code=500, detail=out or "pair failed")
    return {"ok": True, "output": out}


@app.post("/api/adb/connect")
def adb_connect(payload: dict[str, Any], _: AuthResult = Depends(require_token)) -> dict[str, Any]:
    host = str(payload.get("host", "") or "").strip()
    if not host:
        raise HTTPException(status_code=400, detail="host 不能为空")
    ok, out = connect(host)
    if not ok:
        raise HTTPException(status_code=500, detail=out or "connect failed")
    return {"ok": True, "output": out}


@app.post("/api/adb/disconnect")
def adb_disconnect(payload: dict[str, Any], _: AuthResult = Depends(require_token)) -> dict[str, Any]:
    target = str(payload.get("target", "") or "").strip()
    ok, out = disconnect(target or None)
    if not ok:
        raise HTTPException(status_code=500, detail=out or "disconnect failed")
    return {"ok": True, "output": out}


@app.post("/api/adb/restart")
def adb_restart(_: AuthResult = Depends(require_token)) -> dict[str, Any]:
    ok, out = restart_server()
    if not ok:
        raise HTTPException(status_code=500, detail=out or "restart failed")
    return {"ok": True, "output": out}


@app.get("/api/autoglm/status")
def get_status(_: AuthResult = Depends(require_token)) -> dict[str, Any]:
    st = autoglm_status()
    return {"running": st.running, "pid": st.pid, "log_path": st.log_path, "autoglm_dir": st.autoglm_dir}


@app.post("/api/autoglm/start")
def start(_: AuthResult = Depends(require_token)) -> dict[str, Any]:
    cfg = read_config()
    ok, msg = start_autoglm(cfg)
    if not ok:
        raise HTTPException(status_code=500, detail=msg)
    return {"ok": True, "message": msg}


@app.post("/api/autoglm/stop")
def stop(_: AuthResult = Depends(require_token)) -> dict[str, Any]:
    ok, msg = stop_autoglm()
    if not ok:
        raise HTTPException(status_code=500, detail=msg)
    return {"ok": True, "message": msg}


@app.get("/api/logs/tail")
def logs_tail(offset: int = 0, _: AuthResult = Depends(require_token)) -> dict[str, Any]:
    new_offset, text = tail_log(offset)
    return {"offset": new_offset, "text": text}
