from __future__ import annotations

import argparse
import os
import sys

from .security import load_or_create_token, reset_token


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(prog="autoglm-web")
    sub = parser.add_subparsers(dest="cmd", required=True)

    run_p = sub.add_parser("run", help="启动 Web 管理端")
    run_p.add_argument("--host", default=os.environ.get("AUTOGLM_WEB_HOST", "0.0.0.0"))
    run_p.add_argument("--port", type=int, default=int(os.environ.get("AUTOGLM_WEB_PORT", "8000")))

    sub.add_parser("token", help="显示当前管理 Token（请妥善保管）")
    sub.add_parser("reset-token", help="重置管理 Token（旧 Token 立刻失效）")

    args = parser.parse_args(argv)

    if args.cmd == "token":
        print(load_or_create_token())
        return 0
    if args.cmd == "reset-token":
        print(reset_token())
        return 0
    if args.cmd == "run":
        token = load_or_create_token()
        host = args.host
        port = args.port
        os.environ["AUTOGLM_WEB_HOST"] = host
        os.environ["AUTOGLM_WEB_PORT"] = str(port)
        print(f"[autoglm-web] token: {token}")
        print(f"[autoglm-web] listening: http://{host}:{port}/")
        try:
            import uvicorn
        except Exception as e:
            print(f"缺少依赖 uvicorn: {e}", file=sys.stderr)
            return 1
        uvicorn.run("autoglm_web.app:app", host=host, port=port, log_level="info")
        return 0

    return 2


if __name__ == "__main__":
    raise SystemExit(main())
