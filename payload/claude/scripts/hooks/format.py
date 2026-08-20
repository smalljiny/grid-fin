#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.11"
# ///
"""포맷 훅 — 쓴 뒤에 고치고, 고친 사실을 알린다. 막지 않는다.

**쓰기 전에 고치지 않는다.** 훅이 쓸 내용을 바꾸는 것은 되지만 **조용하다** —
실측에서 디스크는 바뀐 내용이었고 모델은 자기가 쓴 내용을 그대로 알고 있었다
(판정 문서 §5-2 실측 5). 그것이 이 설계가 가장 나쁜 실패로 지목한 형태다.

**그래서 쓴 뒤에 고치고 `additionalContext` 로 보고한다**(실측 6). 종료 코드 0 의
stderr 는 모델에게 도달하지 않으므로 쓰지 않는다.

**「알리기만 하는 훅은 만들지 않는다」와 충돌하지 않는다.** 그 규칙이 가리키는
것은 **도달하지 않는 채널**이다. `additionalContext` 는 도달이 확인됐다.

**등록 확인을 부르지 않는다.** 차단하지 않는 계층이므로 결손을 셀 근거가 없고,
차단할 수 없는 훅이 결손을 이유로 무엇을 할 수도 없다.

**어느 경우에도 종료 코드 2를 내지 않는다.** `PostToolUse` 의 2는 차단이 아니라
교정 요청이고(실측 3), 포맷은 이미 스스로 고쳤으므로 요청할 것이 없다.
"""
import hashlib
import json
import pathlib
import subprocess
import sys

# 배포된 트리에 __pycache__ 를 만들지 않는다(1차 실측 2026-08-20).
sys.dont_write_bytecode = True

CONFIG = "gridfin.json"
TOKEN = "GRIDFIN_FORMAT"
EVENT = "PostToolUse"
TIMEOUT = 60


def main() -> int:
    try:
        _run()
    except BaseException:  # noqa: BLE001 — 여기서 새면 2가 아닌 값이라도 시끄럽다
        pass
    return 0


def _run() -> None:
    data = json.load(sys.stdin)
    root = _root(data)
    target = ((data.get("tool_input") or {}).get("file_path")) or ""
    if not root or not target:
        return

    path = pathlib.Path(target)
    if not path.is_absolute():
        path = root / path
    if not path.is_file():
        return

    command = _declared(root, path.suffix)
    if not command:
        return

    before = _digest(path)
    try:
        subprocess.run(list(command) + [str(path)],
                       cwd=str(root), capture_output=True, timeout=TIMEOUT)
    except Exception:
        # 도구가 없거나 죽었다. 포맷은 게이트가 아니므로 그냥 지나간다
        return
    if _digest(path) == before:
        # 바뀐 것이 없으면 아무것도 쓰지 않는다. 매 쓰기마다 한 줄씩 얹지 않는다
        return

    line = "%s %s" % (TOKEN, json.dumps({"changed": [str(path)]},
                                        ensure_ascii=False, sort_keys=True))
    sys.stdout.write(json.dumps(
        {"hookSpecificOutput": {
            "hookEventName": EVENT,
            "additionalContext": "포맷이 파일을 고쳤다 — %s\n%s" % (path, line)}},
        ensure_ascii=False))


def _root(data: dict) -> pathlib.Path | None:
    import os
    for candidate in (os.environ.get("CLAUDE_PROJECT_DIR"), data.get("cwd")):
        if candidate:
            return pathlib.Path(candidate).resolve()
    return None


def _declared(root: pathlib.Path, suffix: str) -> list[str] | None:
    """선언 설정 파일의 `format` 절에서 확장자에 걸린 명령을 꺼낸다.

    **이 훅이 읽는 지점은 이것 하나다.** 나머지 절은 전부 이슈 #3이 정한다.
    """
    try:
        config = json.loads((root / CONFIG).read_text(encoding="utf-8"))
    except Exception:
        return None
    table = config.get("format")
    if not isinstance(table, dict):
        return None
    command = table.get(suffix)
    if not isinstance(command, list) or not command:
        return None
    return [str(x) for x in command]


def _digest(path: pathlib.Path) -> str | None:
    try:
        return hashlib.sha256(path.read_bytes()).hexdigest()
    except OSError:
        return None


if __name__ == "__main__":
    sys.exit(main())
