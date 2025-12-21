from __future__ import annotations

import shlex
import subprocess
from dataclasses import dataclass
from time import sleep


@dataclass(frozen=True)
class AdbDevice:
    serial: str
    status: str
    product: str | None = None
    model: str | None = None
    device: str | None = None
    transport_id: str | None = None


def _run_adb(args: list[str], timeout_s: int = 20) -> tuple[int, str]:
    proc = subprocess.run(
        ["adb", *args],
        capture_output=True,
        text=True,
        timeout=timeout_s,
    )
    out = (proc.stdout or "") + (proc.stderr or "")
    return proc.returncode, out.strip()


def devices() -> list[AdbDevice]:
    code, out = _run_adb(["devices", "-l"], timeout_s=20)
    if code != 0:
        return []
    lines = [ln.strip() for ln in out.splitlines() if ln.strip()]
    if not lines:
        return []
    result: list[AdbDevice] = []
    for line in lines[1:]:
        parts = line.split()
        if len(parts) < 2:
            continue
        serial, status = parts[0], parts[1]
        kv = {}
        for p in parts[2:]:
            if ":" in p:
                k, v = p.split(":", 1)
                kv[k] = v
        result.append(
            AdbDevice(
                serial=serial,
                status=status,
                product=kv.get("product"),
                model=kv.get("model"),
                device=kv.get("device"),
                transport_id=kv.get("transport_id"),
            )
        )
    return result


def pair(host_port: str, code: str) -> tuple[bool, str]:
    rc, out = _run_adb(["pair", host_port, code], timeout_s=60)
    return rc == 0, out


def connect(host_port: str) -> tuple[bool, str]:
    rc, out = _run_adb(["connect", host_port], timeout_s=30)
    return rc == 0, out


def disconnect(host_port: str | None = None) -> tuple[bool, str]:
    args = ["disconnect"] if not host_port else ["disconnect", host_port]
    rc, out = _run_adb(args, timeout_s=30)
    return rc == 0, out


def restart_server() -> tuple[bool, str]:
    rc1, out1 = _run_adb(["kill-server"], timeout_s=10)
    rc2, out2 = _run_adb(["start-server"], timeout_s=10)
    ok = rc1 == 0 and rc2 == 0
    out = "\n".join([s for s in [out1, out2] if s]).strip()
    return ok, out


def list_packages(third_party: bool = True) -> list[str]:
    args = ["shell", "pm", "list", "packages"]
    if third_party:
        args.append("-3")
    code, out = _run_adb(args, timeout_s=30)
    if code != 0:
        return []
    pkgs = []
    for ln in out.splitlines():
        ln = ln.strip()
        if not ln:
            continue
        if ln.startswith("package:"):
            ln = ln.replace("package:", "", 1)
        pkgs.append(ln)
    return pkgs


def _package_label(pkg: str) -> str | None:
    # 尝试从 dumpsys 中获取 application-label
    cmd = ["shell", "dumpsys", "package", pkg]
    code, out = _run_adb(cmd, timeout_s=8)
    if code != 0 or not out:
        return None
    for ln in out.splitlines():
        ln = ln.strip()
        if "application-label:" in ln:
            return ln.split("application-label:", 1)[1].strip()
        if "application-label-zh:" in ln:
            return ln.split("application-label-zh:", 1)[1].strip()
    return None


def list_packages_with_labels(third_party: bool = True, limit: int | None = None) -> list[dict[str, str]]:
    pkgs = list_packages(third_party=third_party)
    if limit is not None:
        pkgs = pkgs[:limit]
    result: list[dict[str, str]] = []
    for pkg in pkgs:
        label = _package_label(pkg) or ""
        result.append({"package": pkg, "label": label})
    return result


def shell(cmd: str, timeout_s: int = 20) -> tuple[bool, str]:
    rc, out = _run_adb(["shell", cmd], timeout_s=timeout_s)
    return rc == 0, out


def input_text(text: str) -> tuple[bool, str]:
    # 使用 shell 转义规避命令注入，同时去掉换行符避免意外分行
    sanitized = text.replace("\r", " ").replace("\n", " ")
    safe = shlex.quote(sanitized)
    return shell(f"input text {safe}")


def tap(x: int, y: int) -> tuple[bool, str]:
    return shell(f"input tap {x} {y}")


def swipe(x1: int, y1: int, x2: int, y2: int, duration_ms: int = 300) -> tuple[bool, str]:
    return shell(f"input swipe {x1} {y1} {x2} {y2} {duration_ms}")


def keyevent(key: str) -> tuple[bool, str]:
    return shell(f"input keyevent {key}")


def start_app(package: str, activity: str | None = None, action: str = "auto") -> tuple[bool, str]:
    # 严格限制包名/Activity 以防命令注入
    def _validate(name: str, field: str) -> None:
        if not name or not all(ch.isalnum() or ch in "._" for ch in name):
            raise ValueError(f"{field} 非法：仅允许字母/数字/._")

    _validate(package, "package")
    if activity:
        # Activity 形如 com.xx/.MainActivity 或 com.xx/com.xx.MainActivity，统一校验组件名
        parts = activity.split("/", 1)
        for p in parts:
            _validate(p, "activity")

    if action == "monkey" or (action == "auto" and not activity):
        return shell(f"monkey -p {package} -c android.intent.category.LAUNCHER 1")
    if activity:
        return shell(f"am start -n {package}/{activity}")
    return shell(f"monkey -p {package} -c android.intent.category.LAUNCHER 1")


def pause_ms(ms: int) -> None:
    sleep(max(ms, 0) / 1000)

