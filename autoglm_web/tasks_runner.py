from __future__ import annotations

import json
import time
import uuid
from typing import Any

from . import adb
from . import autoglm_process
from .config import read_config
from .storage import find_by_id, list_apps, list_tasks


def _log_line(text: str) -> None:
    lf = autoglm_process.log_file()
    lf.parent.mkdir(parents=True, exist_ok=True)
    with lf.open("a", encoding="utf-8") as f:
        f.write(f"[{time.strftime('%F %T')}] {text}\n")


def ensure_autoglm_running() -> None:
    st = autoglm_process.status()
    if not st.running:
        cfg = read_config()
        ok, msg = autoglm_process.start(cfg)
        _log_line(f"[autoglm] start: {msg}")
        if not ok:
            raise RuntimeError(f"启动 AutoGLM 失败: {msg}")


def _format(value: Any, params: dict[str, Any]) -> Any:
    if isinstance(value, str):
        try:
            return value.format(**params)
        except Exception:
            return value
    return value


def run_step(step: dict[str, Any], params: dict[str, Any]) -> tuple[bool, str]:
    stype = step.get("type", "")
    if stype == "note":
        msg = _format(step.get("text", ""), params)
        _log_line(f"[note] {msg}")
        return True, msg
    if stype == "sleep":
        ms = int(step.get("ms", 500))
        adb.pause_ms(ms)
        return True, f"sleep {ms}ms"
    if stype == "adb_shell":
        cmd = _format(step.get("command", ""), params)
        ok, out = adb.shell(cmd)
        _log_line(f"[adb shell] {cmd} -> {out}")
        return ok, out
    if stype == "adb_input":
        text = _format(step.get("text", ""), params)
        ok, out = adb.input_text(text)
        _log_line(f"[adb input] {text} -> {out}")
        return ok, out
    if stype == "adb_tap":
        x = int(step.get("x", 0))
        y = int(step.get("y", 0))
        ok, out = adb.tap(x, y)
        _log_line(f"[adb tap] ({x},{y}) -> {out}")
        return ok, out
    if stype == "adb_swipe":
        x1 = int(step.get("x1", 0))
        y1 = int(step.get("y1", 0))
        x2 = int(step.get("x2", 0))
        y2 = int(step.get("y2", 0))
        duration_ms = int(step.get("duration_ms", 300))
        ok, out = adb.swipe(x1, y1, x2, y2, duration_ms)
        _log_line(f"[adb swipe] ({x1},{y1})->({x2},{y2}) {duration_ms}ms -> {out}")
        return ok, out
    if stype == "adb_keyevent":
        key = _format(step.get("key", ""), params)
        ok, out = adb.keyevent(key)
        _log_line(f"[adb keyevent] {key} -> {out}")
        return ok, out
    if stype == "app_launch":
        package = _format(step.get("package", ""), params)
        activity = _format(step.get("activity", ""), params) or None
        action = step.get("action", "auto")
        ok, out = adb.start_app(package, activity, action=action)
        _log_line(f"[app launch] {package} {activity or ''} -> {out}")
        return ok, out
    if stype == "autoglm_prompt":
        # 目前仅写入日志并确保进程运行
        ensure_autoglm_running()
        text = _format(step.get("text", ""), params)
        _log_line(f"[autoglm prompt] {text}")
        return True, "已写入提示并保持 AutoGLM 运行"
    return False, f"未知步骤类型: {stype}"


def run_app_by_id(app_id: str, params: dict[str, Any] | None = None) -> list[dict[str, Any]]:
    params = params or {}
    apps = list_apps()
    app = find_by_id(apps, app_id)
    if not app:
        raise ValueError("未找到应用")
    results: list[dict[str, Any]] = []
    steps = app.get("steps", [])
    ensure_autoglm_running()
    for st in steps:
        ok, out = run_step(st, params)
        results.append({"type": st.get("type"), "ok": ok, "output": out})
        if not ok:
            break
    return results


def run_task_by_id(task_id: str, params: dict[str, Any] | None = None) -> list[dict[str, Any]]:
    params = params or {}
    tasks = list_tasks()
    task = find_by_id(tasks, task_id)
    if not task:
        raise ValueError("未找到任务")
    results: list[dict[str, Any]] = []
    steps = task.get("steps", [])
    ensure_autoglm_running()
    for st in steps:
        if st.get("type") == "app":
            app_id = st.get("app_id", "")
            sub_res = run_app_by_id(app_id, params)
            results.append({"type": "app", "app_id": app_id, "ok": True, "output": sub_res})
            # 如果子步骤失败，sub_res 会包含 ok=false，我们这里简单继续由子结果决定
            if any(not r.get("ok") for r in sub_res):
                break
            continue
        ok, out = run_step(st, params)
        results.append({"type": st.get("type"), "ok": ok, "output": out})
        if not ok:
            break
    return results


# 简单的内存会话，用于交互模式（仅日志片段）
_sessions: dict[str, list[str]] = {}


def new_session() -> str:
    sid = uuid.uuid4().hex
    _sessions[sid] = []
    _log_line(f"[session {sid}] started")
    return sid


def send_interactive(sid: str, text: str) -> list[str]:
    if sid not in _sessions:
        raise ValueError("会话不存在")
    ensure_autoglm_running()
    line = f"[session {sid}] {text}"
    _sessions[sid].append(line)
    _log_line(line)
    return _sessions[sid][-20:]


def get_interactive_log(sid: str) -> list[str]:
    if sid not in _sessions:
        return []
    return _sessions[sid][-50:]

