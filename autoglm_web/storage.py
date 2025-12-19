from __future__ import annotations

import json
import os
import threading
import uuid
from pathlib import Path
from typing import Any, Callable


_lock = threading.Lock()


def _web_dir() -> Path:
    base = Path(os.environ.get("AUTOGLM_HOME", str(Path.home() / ".autoglm"))).expanduser()
    return base / "web"


def apps_path() -> Path:
    return _web_dir() / "apps.json"


def tasks_path() -> Path:
    return _web_dir() / "tasks.json"


def _load_json(path: Path) -> list[dict[str, Any]]:
    if not path.exists():
        return []
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return []


def _dump_json(path: Path, data: list[dict[str, Any]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_suffix(".tmp")
    tmp.write_text(json.dumps(data, ensure_ascii=False, indent=2), encoding="utf-8")
    tmp.replace(path)


def list_apps() -> list[dict[str, Any]]:
    with _lock:
        return _load_json(apps_path())


def list_tasks() -> list[dict[str, Any]]:
    with _lock:
        return _load_json(tasks_path())


def _save(path: Path, items: list[dict[str, Any]]) -> None:
    with _lock:
        _dump_json(path, items)


def upsert_app(app: dict[str, Any]) -> dict[str, Any]:
    with _lock:
        items = _load_json(apps_path())
        if "id" not in app or not app["id"]:
            app["id"] = uuid.uuid4().hex
            items.append(app)
        else:
            found = False
            for idx, it in enumerate(items):
                if it.get("id") == app["id"]:
                    items[idx] = app
                    found = True
                    break
            if not found:
                items.append(app)
        _dump_json(apps_path(), items)
        return app


def delete_app(app_id: str) -> bool:
    with _lock:
        items = _load_json(apps_path())
        new_items = [it for it in items if it.get("id") != app_id]
        changed = len(new_items) != len(items)
        if changed:
            _dump_json(apps_path(), new_items)
        return changed


def upsert_task(task: dict[str, Any]) -> dict[str, Any]:
    with _lock:
        items = _load_json(tasks_path())
        if "id" not in task or not task["id"]:
            task["id"] = uuid.uuid4().hex
            items.append(task)
        else:
            found = False
            for idx, it in enumerate(items):
                if it.get("id") == task["id"]:
                    items[idx] = task
                    found = True
                    break
            if not found:
                items.append(task)
        _dump_json(tasks_path(), items)
        return task


def delete_task(task_id: str) -> bool:
    with _lock:
        items = _load_json(tasks_path())
        new_items = [it for it in items if it.get("id") != task_id]
        changed = len(new_items) != len(items)
        if changed:
            _dump_json(tasks_path(), new_items)
        return changed


def find_by_id(items: list[dict[str, Any]], item_id: str) -> dict[str, Any] | None:
    for it in items:
        if it.get("id") == item_id:
            return it
    return None

