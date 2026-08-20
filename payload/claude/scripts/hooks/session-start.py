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
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent.parent / "gridfin"))
import gate  # noqa: E402

EVENT = "SessionStart"


def main() -> int:
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
