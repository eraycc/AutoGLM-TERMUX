from __future__ import annotations

import os
from typing import Any

from fastapi import Depends, FastAPI, HTTPException
from fastapi.responses import HTMLResponse, JSONResponse

from . import __version__
from .adb import connect, devices, disconnect, list_packages, pair, restart_server
from .autoglm_process import start as start_autoglm
from .autoglm_process import status as autoglm_status
from .autoglm_process import stop as stop_autoglm
from .autoglm_process import tail_log
from .apps_config import add_entries, load_app_packages
from .auth import AuthResult, require_token
from .config import AutoglmConfig, config_exists, read_config, write_config
from .storage import (
    delete_app,
    delete_task,
    list_apps,
    list_tasks,
    upsert_app,
    upsert_task,
)
from .tasks_runner import (
    get_interactive_log,
    new_session,
    run_prompt_once,
    run_app_by_id,
    run_task_by_id,
    send_interactive,
)

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

        <div style="margin-top:12px;">
          <div class="row" style="align-items:center;">
            <h4 style="margin:0; flex:1;">已安装应用（第三方）</h4>
            <button onclick="fetchPackages()">获取包名</button>
          </div>
          <div class="row" style="margin-top:8px; align-items:end;">
            <div style="flex:1; min-width:200px;">
              <label>选择包名</label>
              <select id="pkg_select" style="width:100%; padding:8px; border-radius:8px;"></select>
            </div>
            <div style="flex:1; min-width:200px;">
              <label>应用名称（写入 apps.py 时使用，不填则默认用包名）</label>
              <input id="pkg_name" placeholder="例如 wechat" />
            </div>
            <button class="primary" onclick="addToAppsConfig()">添加到 apps.py</button>
          </div>
          <div class="muted" id="pkgMsg"></div>
        </div>

      </div>
    </div>

    <div class="row" style="margin-top:12px;">
      <div class="card">
        <h3 style="margin-top:0;">应用库（启动/宏步骤）</h3>
        <div class="row">
          <div style="flex:1; min-width:200px;">
            <label>应用 ID（留空则新增）</label>
            <input id="app_id" placeholder="留空代表新应用" />
          </div>
          <div style="flex:1; min-width:200px;">
            <label>名称</label>
            <input id="app_name" />
          </div>
        </div>
        <label>描述</label>
        <input id="app_desc" />
        <label>步骤（JSON 数组，支持 adb_shell/adb_input/adb_tap/adb_swipe/adb_keyevent/app_launch/sleep/autoglm_prompt/note）</label>
        <textarea id="app_steps" rows="6" placeholder='[{{"type":"app_launch","package":"com.example.app"}},{{"type":"sleep","ms":800}}]'></textarea>
        <div class="row" style="margin-top:10px;">
          <button class="primary" onclick="saveApp()">保存/更新</button>
          <button onclick="resetAppForm()">清空表单</button>
          <button onclick="loadApps()">刷新列表</button>
        </div>
        <div class="muted" id="appMsg"></div>
        <table style="margin-top:10px;">
          <thead><tr><th>ID</th><th>名称</th><th>操作</th></tr></thead>
          <tbody id="appsBody"></tbody>
        </table>
      </div>

      <div class="card">
        <h3 style="margin-top:0;">任务（可引用应用或自定义步骤）</h3>
        <div class="row">
          <div style="flex:1; min-width:200px;">
            <label>任务 ID（留空则新增）</label>
            <input id="task_id" placeholder="留空代表新任务" />
          </div>
          <div style="flex:1; min-width:200px;">
            <label>名称</label>
            <input id="task_name" />
          </div>
        </div>
        <label>描述</label>
        <input id="task_desc" />
        <label>自然语言指令（可选，填了则直接调用模型执行，无需写步骤）</label>
        <textarea id="task_prompt" rows="3" placeholder="例如：打开微信并给张三发一条消息"></textarea>
        <label>步骤（JSON 数组，支持 type: app/app_id 或与应用步骤相同的宏类型；如果已填写自然语言指令，可以留空）</label>
        <textarea id="task_steps" rows="6" placeholder='[{{"type":"app","app_id":"<应用ID>"}},{{"type":"adb_input","text":"Hello"}}]'></textarea>
        <div class="row" style="margin-top:10px;">
          <button class="primary" onclick="saveTask()">保存/更新</button>
          <button onclick="resetTaskForm()">清空表单</button>
          <button onclick="loadTasks()">刷新列表</button>
        </div>
        <div class="muted" id="taskMsg"></div>
        <table style="margin-top:10px;">
          <thead><tr><th>ID</th><th>名称</th><th>操作</th></tr></thead>
          <tbody id="tasksBody"></tbody>
        </table>
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

    <div class="row" style="margin-top:12px;">
      <div class="card">
        <h3 style="margin-top:0;">交互模式（仅记录日志片段）</h3>
        <div class="row" style="align-items:end;">
          <button class="primary" onclick="startSession()">新建会话</button>
          <div class="muted" id="sessionLabel" style="margin-left:8px;">尚未创建</div>
        </div>
        <label>发送内容</label>
        <input id="session_input" placeholder="输入指令/备注，将写入日志并保持 AutoGLM 运行" />
        <div class="row" style="margin-top:8px;">
          <button onclick="sendSession()">发送</button>
          <button onclick="loadSessionLog()">刷新日志</button>
        </div>
        <pre id="sessionLog" style="min-height:160px; max-height:260px;"></pre>
        <div class="muted" id="sessionMsg"></div>
      </div>
    </div>
  </div>

<script>
const LS_TOKEN_KEY = "autoglm_web_token";
let logOffset = 0;
let follow = true;
let sessionId = "";
let appsCache = [];
let tasksCache = [];

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

// 应用库
function renderApps(list) {{
  appsCache = list || [];
  const body = document.getElementById("appsBody");
  body.innerHTML = "";
  for (const a of appsCache) {{
    const tr = document.createElement("tr");
    tr.innerHTML = `
      <td>${{a.id}}</td>
      <td>${{a.name || ''}}</td>
      <td>
        <button onclick="runApp('${{a.id}}')">运行</button>
        <button onclick="editApp('${{a.id}}')">编辑</button>
        <button onclick="deleteApp('${{a.id}}')">删除</button>
      </td>
    `;
    body.appendChild(tr);
  }}
}}

async function loadApps() {{
  try {{
    const data = await apiJson("/api/apps");
    renderApps(data.apps || []);
    setMsg("appMsg", "应用列表已刷新");
  }} catch (e) {{
    setMsg("appMsg", "刷新失败: " + e.message);
  }}
}}

function resetAppForm() {{
  document.getElementById("app_id").value = "";
  document.getElementById("app_name").value = "";
  document.getElementById("app_desc").value = "";
  document.getElementById("app_steps").value = "";
}}

async function saveApp() {{
  const stepsRaw = document.getElementById("app_steps").value.trim() || "[]";
  let steps;
  try {{
    steps = JSON.parse(stepsRaw);
  }} catch (e) {{
    setMsg("appMsg", "步骤 JSON 解析失败: " + e.message);
    return;
  }}
  const payload = {{
    id: document.getElementById("app_id").value.trim(),
    name: document.getElementById("app_name").value.trim(),
    description: document.getElementById("app_desc").value.trim(),
    steps,
  }};
  try {{
    const data = await apiJson("/api/apps", {{ method: "POST", body: JSON.stringify(payload) }});
    setMsg("appMsg", data.message || "已保存");
    await loadApps();
    if (!payload.id) resetAppForm();
  }} catch (e) {{
    setMsg("appMsg", "保存失败: " + e.message);
  }}
}}

function editApp(id) {{
  const a = appsCache.find(x => x.id === id);
  if (!a) return;
  document.getElementById("app_id").value = a.id;
  document.getElementById("app_name").value = a.name || "";
  document.getElementById("app_desc").value = a.description || "";
  document.getElementById("app_steps").value = JSON.stringify(a.steps || [], null, 2);
}}

async function deleteApp(id) {{
  if (!confirm("删除该应用？")) return;
  try {{
    await apiJson(`/api/apps/${{id}}`, {{ method: "DELETE" }});
    setMsg("appMsg", "已删除");
    await loadApps();
  }} catch (e) {{
    setMsg("appMsg", "删除失败: " + e.message);
  }}
}}

async function runApp(id) {{
  try {{
    const data = await apiJson(`/api/apps/${{id}}/run`, {{ method: "POST", body: JSON.stringify({{}}) }});
    setMsg("appMsg", "执行完成");
    console.log(data);
  }} catch (e) {{
    setMsg("appMsg", "执行失败: " + e.message);
  }}
}}

// 任务
function renderTasks(list) {{
  tasksCache = list || [];
  const body = document.getElementById("tasksBody");
  body.innerHTML = "";
  for (const t of tasksCache) {{
    const tr = document.createElement("tr");
    tr.innerHTML = `
      <td>${{t.id}}</td>
      <td>${{t.name || ''}}</td>
      <td>
        <button onclick="runTask('${{t.id}}')">运行</button>
        <button onclick="editTask('${{t.id}}')">编辑</button>
        <button onclick="deleteTask('${{t.id}}')">删除</button>
      </td>
    `;
    body.appendChild(tr);
  }}
}}

async function loadTasks() {{
  try {{
    const data = await apiJson("/api/tasks");
    renderTasks(data.tasks || []);
    setMsg("taskMsg", "任务列表已刷新");
  }} catch (e) {{
    setMsg("taskMsg", "刷新失败: " + e.message);
  }}
}}

function resetTaskForm() {{
  document.getElementById("task_id").value = "";
  document.getElementById("task_name").value = "";
  document.getElementById("task_desc").value = "";
  document.getElementById("task_steps").value = "";
}}

async function saveTask() {{
  const stepsRaw = document.getElementById("task_steps").value.trim() || "[]";
  let steps;
  try {{
    steps = JSON.parse(stepsRaw);
  }} catch (e) {{
    setMsg("taskMsg", "步骤 JSON 解析失败: " + e.message);
    return;
  }}
  const payload = {{
    id: document.getElementById("task_id").value.trim(),
    name: document.getElementById("task_name").value.trim(),
    description: document.getElementById("task_desc").value.trim(),
    prompt: document.getElementById("task_prompt").value.trim(),
    steps,
  }};
  try {{
    const data = await apiJson("/api/tasks", {{ method: "POST", body: JSON.stringify(payload) }});
    setMsg("taskMsg", data.message || "已保存");
    await loadTasks();
    if (!payload.id) resetTaskForm();
  }} catch (e) {{
    setMsg("taskMsg", "保存失败: " + e.message);
  }}
}}

function editTask(id) {{
  const t = tasksCache.find(x => x.id === id);
  if (!t) return;
  document.getElementById("task_id").value = t.id;
  document.getElementById("task_name").value = t.name || "";
  document.getElementById("task_desc").value = t.description || "";
  document.getElementById("task_prompt").value = t.prompt || "";
  document.getElementById("task_steps").value = JSON.stringify(t.steps || [], null, 2);
}}

async function deleteTask(id) {{
  if (!confirm("删除该任务？")) return;
  try {{
    await apiJson(`/api/tasks/${{id}}`, {{ method: "DELETE" }});
    setMsg("taskMsg", "已删除");
    await loadTasks();
  }} catch (e) {{
    setMsg("taskMsg", "删除失败: " + e.message);
  }}
}}

async function runTask(id) {{
  try {{
    const data = await apiJson(`/api/tasks/${{id}}/run`, {{ method: "POST", body: JSON.stringify({{}}) }});
    setMsg("taskMsg", "执行完成");
    console.log(data);
  }} catch (e) {{
    setMsg("taskMsg", "执行失败: " + e.message);
  }}
}}

// 交互模式
async function startSession() {{
  try {{
    const data = await apiJson("/api/interactive/start", {{ method: "POST" }});
    sessionId = data.session_id;
    document.getElementById("sessionLabel").textContent = "会话: " + sessionId;
    setMsg("sessionMsg", "会话已创建");
    document.getElementById("sessionLog").textContent = "";
  }} catch (e) {{
    setMsg("sessionMsg", "创建失败: " + e.message);
  }}
}}

async function sendSession() {{
  const text = document.getElementById("session_input").value.trim();
  if (!sessionId) {{
    setMsg("sessionMsg", "请先创建会话");
    return;
  }}
  if (!text) return;
  try {{
    const data = await apiJson(`/api/interactive/${{sessionId}}/send`, {{ method: "POST", body: JSON.stringify({{ text }}) }});
    document.getElementById("sessionLog").textContent = (data.logs || []).join("\\n");
    document.getElementById("session_input").value = "";
  }} catch (e) {{
    setMsg("sessionMsg", "发送失败: " + e.message);
  }}
}}

// 已安装包名
async function fetchPackages() {{
  try {{
    const data = await apiJson("/api/adb/packages");
    const pkgs = data.packages || [];
    const sel = document.getElementById("pkg_select");
    sel.innerHTML = "";
    pkgs.forEach(p => {{
      const opt = document.createElement("option");
      opt.value = p;
      opt.textContent = p;
      sel.appendChild(opt);
    }});
    setMsg("pkgMsg", `已获取 ${pkgs.length} 个包名`);
  }} catch (e) {{
    setMsg("pkgMsg", "获取失败: " + e.message);
  }}
}}

async function addToAppsConfig() {{
  const sel = document.getElementById("pkg_select");
  const pkg = sel.value;
  if (!pkg) {{
    setMsg("pkgMsg", "请先获取并选择包名");
    return;
  }}
  const nameInput = document.getElementById("pkg_name").value.trim() || pkg;
  const payload = {{ items: [{{ name: nameInput, package: pkg }}] }};
  try {{
    const data = await apiJson("/api/adb/packages/add", {{ method: "POST", body: JSON.stringify(payload) }});
    setMsg("pkgMsg", data.message || "已写入 apps.py");
  }} catch (e) {{
    setMsg("pkgMsg", "写入失败: " + e.message);
  }}
}}

async function loadSessionLog() {{
  if (!sessionId) return;
  try {{
    const data = await apiJson(`/api/interactive/${{sessionId}}/log`);
    document.getElementById("sessionLog").textContent = (data.logs || []).join("\\n");
  }} catch (e) {{
    setMsg("sessionMsg", "获取日志失败: " + e.message);
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
  await loadApps();
  await loadTasks();
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
        # 如果当前配置文件不存在或仍是默认占位符，则拒绝保存空的 API Key，避免覆盖真实配置
        if not config_exists() or cfg.api_key == "sk-your-apikey":
            raise HTTPException(status_code=400, detail="首次保存配置必须填写有效的 API Key")
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

@app.get("/api/adb/packages")
def adb_packages(_: AuthResult = Depends(require_token)) -> dict[str, Any]:
    pkgs = list_packages(third_party=True)
    return {"packages": pkgs}

# 写入 apps.py
@app.post("/api/adb/packages/add")
def adb_packages_add(payload: dict[str, Any], _: AuthResult = Depends(require_token)) -> dict[str, Any]:
    items = payload.get("items", [])
    if not isinstance(items, list) or not items:
        raise HTTPException(status_code=400, detail="items 不能为空")
    entries: dict[str, str] = {}
    for it in items:
        name = str(it.get("name", "")).strip()
        pkg = str(it.get("package", "")).strip()
        if not name or not pkg:
            continue
        entries[name] = pkg
    if not entries:
        raise HTTPException(status_code=400, detail="未提供有效的 name/package")
    try:
        data = add_entries(entries)
    except FileNotFoundError:
        raise HTTPException(status_code=404, detail="未找到 apps.py，请先确认 Open-AutoGLM 路径")
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    return {"ok": True, "size": len(data), "message": f"已写入 {len(entries)} 项到 apps.py"}

# 应用库
@app.get("/api/apps")
def api_list_apps(_: AuthResult = Depends(require_token)) -> dict[str, Any]:
    return {"apps": list_apps()}


@app.post("/api/apps")
def api_save_app(payload: dict[str, Any], _: AuthResult = Depends(require_token)) -> dict[str, Any]:
    steps = payload.get("steps", [])
    if not isinstance(steps, list):
        raise HTTPException(status_code=400, detail="steps 必须为数组")
    app = {
        "id": str(payload.get("id", "") or ""),
        "name": str(payload.get("name", "") or ""),
        "description": str(payload.get("description", "") or ""),
        "steps": steps,
    }
    saved = upsert_app(app)
    return {"ok": True, "app": saved, "message": "已保存"}


@app.delete("/api/apps/{app_id}")
def api_delete_app(app_id: str, _: AuthResult = Depends(require_token)) -> dict[str, Any]:
    ok = delete_app(app_id)
    if not ok:
        raise HTTPException(status_code=404, detail="未找到应用")
    return {"ok": True}


@app.post("/api/apps/{app_id}/run")
def api_run_app(app_id: str, payload: dict[str, Any] | None = None, _: AuthResult = Depends(require_token)) -> dict[str, Any]:
    params = payload or {}
    try:
        results = run_app_by_id(app_id, params)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    return {"ok": True, "results": results}

# 任务
@app.get("/api/tasks")
def api_list_tasks(_: AuthResult = Depends(require_token)) -> dict[str, Any]:
    return {"tasks": list_tasks()}


@app.post("/api/tasks")
def api_save_task(payload: dict[str, Any], _: AuthResult = Depends(require_token)) -> dict[str, Any]:
    steps = payload.get("steps", [])
    if not isinstance(steps, list):
        raise HTTPException(status_code=400, detail="steps 必须为数组")
    task = {
        "id": str(payload.get("id", "") or ""),
        "name": str(payload.get("name", "") or ""),
        "description": str(payload.get("description", "") or ""),
        "prompt": str(payload.get("prompt", "") or ""),
        "steps": steps,
    }
    saved = upsert_task(task)
    return {"ok": True, "task": saved, "message": "已保存"}


@app.delete("/api/tasks/{task_id}")
def api_delete_task(task_id: str, _: AuthResult = Depends(require_token)) -> dict[str, Any]:
    ok = delete_task(task_id)
    if not ok:
        raise HTTPException(status_code=404, detail="未找到任务")
    return {"ok": True}


@app.post("/api/tasks/{task_id}/run")
def api_run_task(task_id: str, payload: dict[str, Any] | None = None, _: AuthResult = Depends(require_token)) -> dict[str, Any]:
    params = payload or {}
    try:
        results = run_task_by_id(task_id, params)
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
    return {"ok": True, "results": results}

# 交互模式（仅日志片段）
@app.post("/api/interactive/start")
def api_interactive_start(_: AuthResult = Depends(require_token)) -> dict[str, Any]:
    sid = new_session()
    return {"session_id": sid}


@app.post("/api/interactive/{sid}/send")
def api_interactive_send(sid: str, payload: dict[str, Any], _: AuthResult = Depends(require_token)) -> dict[str, Any]:
    text = str(payload.get("text", "") or "").strip()
    if not text:
        raise HTTPException(status_code=400, detail="text 不能为空")
    try:
        logs = send_interactive(sid, text)
    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))
    return {"logs": logs}


@app.get("/api/interactive/{sid}/log")
def api_interactive_log(sid: str, _: AuthResult = Depends(require_token)) -> dict[str, Any]:
    logs = get_interactive_log(sid)
    return {"logs": logs}


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
