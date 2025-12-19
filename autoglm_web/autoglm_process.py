from __future__ import annotations

import os
import signal
import subprocess
import time
from dataclasses import dataclass
from pathlib import Path

from .config import AutoglmConfig


def _autoglm_dir() -> Path:
    return Path(os.environ.get("AUTOGLM_DIR", str(Path.home() / "Open-AutoGLM"))).expanduser()


def _state_dir() -> Path:
    base = Path(os.environ.get("AUTOGLM_HOME", str(Path.home() / ".autoglm"))).expanduser()
    return base / "web"


def pid_file() -> Path:
    return _state_dir() / "autoglm.pid"


def log_file() -> Path:
    return _state_dir() / "autoglm.log"


@dataclass(frozen=True)
class ProcessStatus:
    running: bool
    pid: int | None
    log_path: str
    autoglm_dir: str


def _is_running(pid: int) -> bool:
    try:
        os.kill(pid, 0)
        return True
    except Exception:
        return False


def status() -> ProcessStatus:
    _state_dir().mkdir(parents=True, exist_ok=True)
    pid = None
    if pid_file().exists():
        try:
            pid = int(pid_file().read_text(encoding="utf-8").strip())
        except Exception:
            pid = None
    running = bool(pid) and _is_running(pid)
    if pid and not running:
        try:
            pid_file().unlink()
        except Exception:
            pass
        pid = None
    return ProcessStatus(
        running=running,
        pid=pid,
        log_path=str(log_file()),
        autoglm_dir=str(_autoglm_dir()),
    )


def start(cfg: AutoglmConfig) -> tuple[bool, str]:
    st = status()
    if st.running:
        return False, f"AutoGLM 已在运行 (pid={st.pid})"

    workdir = _autoglm_dir()
    if not workdir.exists():
        return False, f"未找到 Open-AutoGLM 目录: {workdir}"

    _state_dir().mkdir(parents=True, exist_ok=True)
    lf = log_file()
    log_fp = lf.open("a", encoding="utf-8")

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

    try:
        proc = subprocess.Popen(
            args,
            cwd=str(workdir),
            stdout=log_fp,
            stderr=subprocess.STDOUT,
            text=True,
        )
    except Exception as e:
        log_fp.close()
        return False, f"启动失败: {e}"

    pid_file().write_text(str(proc.pid) + "\n", encoding="utf-8")
    try:
        pid_file().chmod(0o600)
    except Exception:
        pass
    log_fp.write(f"\n[autoglm-web] started pid={proc.pid} at {time.strftime('%F %T')}\n")
    log_fp.flush()
    return True, f"已启动 (pid={proc.pid})"


def stop() -> tuple[bool, str]:
    st = status()
    if not st.pid:
        return False, "当前没有由 Web 管理端启动的进程"
    pid = st.pid
    try:
        os.kill(pid, signal.SIGTERM)
    except Exception as e:
        return False, f"停止失败: {e}"

    for _ in range(30):
        if not _is_running(pid):
            break
        time.sleep(0.2)
    if _is_running(pid):
        try:
            os.kill(pid, signal.SIGKILL)
        except Exception:
            pass

    try:
        pid_file().unlink()
    except Exception:
        pass
    return True, "已停止"


def tail_log(offset: int, max_bytes: int = 32_000) -> tuple[int, str]:
    lf = log_file()
    if not lf.exists():
        return 0, ""
    size = lf.stat().st_size
    if offset < 0 or offset > size:
        offset = max(0, size - max_bytes)
    with lf.open("rb") as f:
        f.seek(offset)
        data = f.read(max_bytes)
        new_offset = offset + len(data)
    try:
        text = data.decode("utf-8", errors="replace")
    except Exception:
        text = ""
    return new_offset, text

