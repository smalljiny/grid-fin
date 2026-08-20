#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# ///
"""쓰기 경계 훅 — 프로젝트 루트 밖 쓰기를 막는다.

**차단이 성립하는 지점이다.** `PreToolUse` 의 종료 코드 2는 파일이 생기지 않게
하고 stderr 가 모델에게 전달된다(1차 실측 2026-08-09).

**여기서 보는 것은 파일 경계 하나다.** 차단하는 계층은 오탐 0% 를 요구하는데
경로 비교는 오탐이 원리적으로 없다. 금지 패턴과 시크릿은 규칙 목록이 있어야
하고 그 목록은 선언 설정 파일이 담는다(이슈 #3).

**등록 확인도 여기서 한다.** 세션 시작은 막지 못하므로 실제 차단이 이 지점으로
옮겨져 있다(미결 목록 파일의 S33).

**예외가 나면 막는다.** 차단 훅이 예외에서 통과하면 검사하지 않은 것이 통과한
것으로 보이고, 그것이 fail-open 이다.
"""
import json
import pathlib
import sys

# 배포된 트리에 __pycache__ 를 만들지 않는다. payload/ 로 새면 이진 파일이라
# 3-way merge 가 실패한다(1차 실측 2026-08-20).
sys.dont_write_bytecode = True

# **import 자체를 감싼다.** 공용 모듈이 없거나 깨지면 여기서 죽는데,
# 그러면 파이썬이 종료 코드 1로 끝내고 Claude Code 는 그것을 차단으로 읽지 않는다.
# **게이트를 지우는 것으로 게이트를 지날 수 있게 된다.**
try:
    sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent.parent / "gridfin"))
    import gate  # noqa: E402
except BaseException as _exc:  # noqa: BLE001
    _fail = {"ok": False,
             "missing": [{"kind": "hook_error",
                          "path": "%s: %s" % (type(_exc).__name__, _exc)}]}
    _line = "GRIDFIN_GATE " + json.dumps(_fail, ensure_ascii=False, sort_keys=True)
    sys.stderr.write("공용 모듈을 부를 수 없다 — 막는다.\n" + _line + "\n")
    sys.exit(2)

EVENT = "PreToolUse"


def main() -> int:
    try:
        return _run()
    except BaseException as exc:  # noqa: BLE001 — 새면 검사 없이 통과한다
        _block({"ok": False,
                "missing": [{"kind": "hook_error",
                             "path": "%s: %s" % (type(exc).__name__, exc)}]})
        return 2


def _run() -> int:
    data = gate.read_input(sys.stdin)

    root = gate.project_root(data)
    result = gate.check_registration(root)
    if not result["ok"]:
        _block(result)
        return 2

    target = ((data.get("tool_input") or {}).get("file_path")) or ""
    if not target:
        _block({"ok": False,
                "missing": [{"kind": "hook_input", "path": "tool_input.file_path 가 없다"}]})
        return 2

    if not gate.inside_root(target, root):
        _block({"ok": False,
                "missing": [{"kind": "outside_root", "path": target}]})
        return 2
    return 0


def _block(result: dict) -> None:
    sys.stderr.write(gate.blocked(EVENT, result))


if __name__ == "__main__":
    sys.exit(main())
