#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# ///
"""커밋 경계 훅 — 선언 설정이 없으면 커밋을 막는다.

**여기서 확정하는 것은 경계 인식과 부재 처리다.** 무엇을 검사할지는 선언 설정
파일이 담고(이슈 #3), 결과를 판정하는 것은 어댑터다(이슈 #4).

**부재를 통과가 아니라 차단으로 둔다.** 선언되지 않은 부재는 결손이다. 통과로
두면 검사가 없는 것과 검사가 통과한 것이 같은 값으로 보인다.

**판정 불가도 막는다.** 셸 문법을 못 읽어 커밋인지 아닌지 모르면 통과시키지
않는다. 판정 불가를 통과로 두면 그것이 곧 게이트를 지나는 길이 된다.
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

    # **커밋인지 먼저 가른다.** 등록 확인을 앞에 두면 등록이 깨졌을 때
    # 커밋이 아닌 `Bash` 호출까지 전부 막힌다. **그러면 복구 경로가 막힌다** —
    # 결손을 고치는 방법이 재배포인데 그것도 `Bash` 로 실행된다.
    command = (data.get("tool_input") or {}).get("command")
    verdict = gate.is_commit(command)
    if verdict is None:
        _block({"ok": False,
                "missing": [{"kind": "hook_input",
                             "path": "명령을 판정할 수 없다: %r" % (command,)}]})
        return 2
    if not verdict:
        return 0

    root = gate.project_root(data)
    result = gate.check_registration(root)
    if not result["ok"]:
        _block(result)
        return 2

    if not (root / gate.CONFIG).is_file():
        _block({"ok": False,
                "missing": [{"kind": "config", "path": gate.CONFIG}]})
        return 2
    return 0


def _block(result: dict) -> None:
    sys.stderr.write(gate.blocked(EVENT, result))


if __name__ == "__main__":
    sys.exit(main())
