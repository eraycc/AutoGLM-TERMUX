from __future__ import annotations

import os
import subprocess
import time
import uuid
from pathlib import Path
from typing import Any

from . import adb
from . import autoglm_process
from .config import config_sh_path, read_config
from .storage import find_by_id, list_tasks


def _log_line(text: str) -> None:
    lf = autoglm_process.log_file()
    lf.parent.mkdir(parents=True, exist_ok=True)
    with lf.open("a", encoding="utf-8") as f:
        f.write(f"[{time.strftime('%F %T')}] {text}\n")


def _autoglm_dir() -> Path:
    return Path(os.environ.get("AUTOGLM_DIR", str(Path.home() / "Open-AutoGLM"))).expanduser()


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
        text = _format(step.get("text", ""), params)
        try:
            output = run_prompt_once(text)
            _log_line(f"[autoglm prompt] {text}")
            for ln in output.splitlines():
                _log_line(f"[autoglm prompt output] {ln}")
            return True, output
        except Exception as e:
            _log_line(f"[autoglm prompt error] {e}")
            return False, str(e)
    return False, f"未知步骤类型: {stype}"


def run_task_by_id(task_id: str, params: dict[str, Any] | None = None) -> list[dict[str, Any]]:
    params = params or {}
    tasks = list_tasks()
    task = find_by_id(tasks, task_id)
    if not task:
        raise ValueError("未找到任务")
    results: list[dict[str, Any]] = []
    prompt = task.get("prompt", "")
    if prompt:
        try:
            output = run_prompt_once(prompt)
            results.append({"type": "autoglm_prompt", "ok": True, "output": output})
            return results
        except Exception as e:
            results.append({"type": "autoglm_prompt", "ok": False, "output": str(e)})
            return results
    steps = task.get("steps", [])
    ensure_autoglm_running()
    for st in steps:
        if st.get("type") == "app":
            app_id = st.get("app_id", "")
            msg = f"应用库功能已移除，无法执行应用 {app_id or '未指定'}，请直接在任务步骤中编排 adb_* 或 autoglm_prompt"
            results.append({"type": "app", "app_id": app_id, "ok": False, "output": msg})
            break
        ok, out = run_step(st, params)
        results.append({"type": st.get("type"), "ok": ok, "output": out})
        if not ok:
            break
    return results


MAX_SESSIONS = 50  # 会话上限，超出则丢弃最早的
_sessions: dict[str, list[str]] = {}
_session_offsets: dict[str, int] = {}


def new_session() -> str:
    sid = uuid.uuid4().hex
    # 控制会话总数
    if len(_sessions) >= MAX_SESSIONS:
        # FIFO 删除最早创建的会话
        oldest_sid = next(iter(_sessions))
        del _sessions[oldest_sid]
        _session_offsets.pop(oldest_sid, None)
    _sessions[sid] = []
    try:
        _session_offsets[sid] = autoglm_process.log_file().stat().st_size
    except Exception:
        _session_offsets[sid] = 0
    _log_line(f"[session {sid}] started")
    return sid


def send_interactive(sid: str, text: str) -> list[str]:
    if sid not in _sessions:
        raise ValueError("会话不存在")
    st = autoglm_process.status()
    if not st.running:
        raise ValueError("AutoGLM 未在运行，请先启动")
    output_lines: list[str] = []
    ok, msg = autoglm_process.send_input(text)
    if not ok:
        output_lines = [f"执行失败: {msg}"]
    else:
        offset = _session_offsets.get(sid, 0)
        collected: list[str] = []
        try:
            # 轮询几次，尽量获取完整日志片段
            for _ in range(12):
                new_offset, chunk = autoglm_process.tail_log(offset)
                offset = new_offset
                if chunk:
                    collected.extend(chunk.splitlines())
                    # 若已有输出，跳出；否则继续等
                    if chunk.strip():
                        break
                time.sleep(0.25)
            _session_offsets[sid] = offset
            output_lines = [ln for ln in collected if ln.strip()]
            if not output_lines:
                output_lines = ["已发送，暂无新日志（可能仍在执行）"]
        except Exception as e:
            output_lines = [f"发送成功，但读取日志失败: {e}"]
    line = f"[session {sid}] {text}"
    _sessions[sid].append(line)
    for ln in output_lines:
        _sessions[sid].append(f"[session {sid}] {ln}")
    _log_line(line)
    for ln in output_lines:
        _log_line(f"[session {sid} output] {ln}")
    return _sessions[sid][-20:]


def get_interactive_log(sid: str) -> list[str]:
    if sid not in _sessions:
        return []
    return _sessions[sid][-50:]


def run_prompt_once(prompt: str, timeout_s: int = 600) -> str:
    cfg = read_config()
    if not cfg.api_key or cfg.api_key == "sk-your-apikey":
        raise RuntimeError(f"API Key 未配置：请在 {config_sh_path()} 填写有效密钥或通过 Web 界面保存配置")
    workdir = _autoglm_dir()
    if not workdir.exists():
        raise RuntimeError(f"未找到 Open-AutoGLM 目录: {workdir}")
    args = [
        "python",
        "main.py",
        "--base-url",
        cfg.base_url,
        "--model",
        cfg.model,
        "--apikey",
        cfg.api_key,
    ]
    if cfg.device_id:
        args += ["--device-id", cfg.device_id]
    if str(cfg.max_steps).strip():
        args += ["--max-steps", str(cfg.max_steps)]
    if cfg.lang:
        args += ["--lang", cfg.lang]

    input_data = f"{prompt}\nquit\n"
    try:
        proc = subprocess.run(
            args,
            cwd=str(workdir),
            input=input_data,
            text=True,
            capture_output=True,
            timeout=timeout_s,
        )
    except subprocess.TimeoutExpired:
        raise RuntimeError("执行超时")
    output = (proc.stdout or "") + ("\n" + proc.stderr if proc.stderr else "")
    if proc.returncode != 0:
        brief_out = output.strip()
        if len(brief_out) > 800:
            brief_out = brief_out[:800] + "...(truncated)"
        raise RuntimeError(f"AutoGLM 子进程退出码 {proc.returncode}，输出: {brief_out or '无'}")
    _log_line(f"[prompt once] {prompt}")
    return output.strip()
