#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# ///
"""세션 시작 훅 — 훅 등록을 확인하고 알린다. 막지 않는다.

**세션 시작에서는 차단이 성립하지 않는다.** 종료 코드 2로 끝내도 세션이 그대로
진행되고 stderr 가 모델에게 도달하지 않는다(1차 실측 2026-08-20 · Claude Code
2.1.237 · darwin 25.5.0 · `claude -p`. 대화형은 재지 않았다).

**그래서 여기서는 알리기만 하고 실제 차단은 쓰기 경계와 커밋 경계가 한다.**
알리는 채널은 종료 코드 0 + stdout JSON 의 additionalContext 다 — 도달을 실측했다.
"""
import json
import pathlib
import sys

# 배포된 트리에 __pycache__ 를 만들지 않는다. 만들면 매니페스트에 없는 파일이
# 배포물 옆에 쌓이고, payload/ 로 새어 들어가면 이진 파일이라 3-way merge 가
# 실패한다(1차 실측 2026-08-20 — 이슈 #1의 시험 31개가 그것으로 깨졌다).
sys.dont_write_bytecode = True

# **import 자체를 감싼다.** 공용 모듈이 없거나 깨지면 여기서 죽는데,
# 그러면 파이썬이 종료 코드 1로 끝내고 **아무 말도 남지 않는다.**
# 여기서는 막지 못하므로 알리고 0으로 끝낸다 — 차단은 쓰기 경계가 한다.
try:
    sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent.parent / "gridfin"))
    import gate  # noqa: E402
except BaseException as _exc:  # noqa: BLE001
    _fail = {"ok": False,
             "missing": [{"kind": "hook_error",
                          "path": "%s: %s" % (type(_exc).__name__, _exc)}]}
    sys.stdout.write(json.dumps(
        {"hookSpecificOutput": {
            "hookEventName": "SessionStart",
            "additionalContext": "공용 모듈을 부를 수 없다.\nGRIDFIN_GATE "
                                 + json.dumps(_fail, ensure_ascii=False, sort_keys=True)}},
        ensure_ascii=False))
    sys.exit(0)

EVENT = "SessionStart"


def main() -> int:
    """예상 밖 예외가 나도 종료 코드 2로 새지 않는다.

    「어느 경우에도」는 열거로 보장되지 않는다. 바깥에서 모든 예외를 잡고
    **0을 돌려주는 경로를 하나로 만든다.** 다만 조용히 지나가지 않는다 —
    무슨 일이 났는지 결손으로 실어 보낸다.
    """
    try:
        return _run()
    except BaseException as exc:   # noqa: BLE001 — 여기서 새면 차단으로 오인된다
        try:
            _report({"ok": False,
                     "missing": [{"kind": "hook_error",
                                  "path": "%s: %s" % (type(exc).__name__, exc)}]})
        except BaseException:      # noqa: BLE001 — 보고조차 실패해도 막지 않는다
            pass
        return 0


def _run() -> int:
    try:
        data = gate.read_input(sys.stdin)
    except gate.BadInput as exc:
        # 입력이 깨져도 막지 않는다. 막을 수 없는 지점이기 때문이다.
        # 다만 조용히 지나가지 않는다 — 결손으로 실어 보낸다.
        result = {"ok": False,
                  "missing": [{"kind": "hook_input", "path": str(exc)}]}
        _report(result)
        return 0

    result = gate.check_registration(gate.project_root(data))
    if result["ok"]:
        # 통과하면 아무것도 쓰지 않는다. 매 세션마다 한 줄씩 얹지 않는다.
        return 0
    _report(result)
    return 0


def _report(result: dict) -> None:
    text = "%s\n%s" % (gate.describe(result), gate.gate_line(result))
    sys.stdout.write(gate.additional_context(EVENT, text))


if __name__ == "__main__":
    sys.exit(main())
