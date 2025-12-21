from __future__ import annotations

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


def shell(cmd: str, timeout_s: int = 20) -> tuple[bool, str]:
    rc, out = _run_adb(["shell", cmd], timeout_s=timeout_s)
    return rc == 0, out


def input_text(text: str) -> tuple[bool, str]:
    safe = text.replace(" ", "%s")
    return shell(f"input text \"{safe}\"")


def tap(x: int, y: int) -> tuple[bool, str]:
    return shell(f"input tap {x} {y}")


def swipe(x1: int, y1: int, x2: int, y2: int, duration_ms: int = 300) -> tuple[bool, str]:
    return shell(f"input swipe {x1} {y1} {x2} {y2} {duration_ms}")


def keyevent(key: str) -> tuple[bool, str]:
    return shell(f"input keyevent {key}")


def start_app(package: str, activity: str | None = None, action: str = "auto") -> tuple[bool, str]:
    if action == "monkey" or (action == "auto" and not activity):
        return shell(f"monkey -p {package} -c android.intent.category.LAUNCHER 1")
    if activity:
        return shell(f"am start -n {package}/{activity}")
    return shell(f"monkey -p {package} -c android.intent.category.LAUNCHER 1")


def pause_ms(ms: int) -> None:
    sleep(max(ms, 0) / 1000)

