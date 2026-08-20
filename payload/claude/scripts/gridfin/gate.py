"""훅이 함께 쓰는 코드. 훅이 아니다 — settings.json 이 이것을 부르지 않는다.

`.claude/scripts/hooks/` 에 두지 않는다. 등록 확인의 기대 목록이 그 디렉터리의
직속 자녀에서 나오므로, 등록되지 않는 파일을 거기 두면 확인하는 코드가 자기
자신을 결손으로 잡는다(미결 목록 파일의 S34).

훅에서 부르는 방법 — `__file__` 기준으로 경로를 만든다. 실행 디렉터리와 무관하다.

    import pathlib, sys
    sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent.parent / "gridfin"))
    import gate
"""

import json
import os
import pathlib

TOKEN_GATE = "GRIDFIN_GATE"
TOKEN_FORMAT = "GRIDFIN_FORMAT"

HOOK_DIR = ".claude/scripts/hooks"
SETTINGS = ".claude/settings.json"
MANIFEST = ".harness/manifest.json"

_PREFIXES = ("${CLAUDE_PROJECT_DIR}/", "$CLAUDE_PROJECT_DIR/")


class BadInput(Exception):
    """stdin 이 JSON 객체가 아니다."""


def read_input(stream) -> dict:
    """훅이 받는 stdin JSON 을 읽는다. 형태가 아니면 BadInput 을 낸다."""
    try:
        data = json.load(stream)
    except Exception as exc:
        raise BadInput(str(exc)) from exc
    if not isinstance(data, dict):
        raise BadInput("최상위가 객체가 아니다")
    return data


def project_root(data: dict) -> pathlib.Path | None:
    """프로젝트 루트를 알아낸다. 환경변수를 먼저 보고 없으면 stdin 의 cwd 를 쓴다.

    둘 다 없으면 None 이다 — 판정할 수 없다는 뜻이고, 차단하는 훅은 막아야 한다.
    루트에서 세션을 시작하면 둘이 같은 곳을 가리키는 것을 실측했다
    (훅 실측 조사 M3, 2026-08-09).
    """
    for candidate in (os.environ.get("CLAUDE_PROJECT_DIR"), data.get("cwd")):
        if candidate:
            return pathlib.Path(candidate).resolve()
    return None


def normalize(command: str, root: pathlib.Path) -> str | None:
    """선언의 명령 문자열을 저장소 루트 기준 상대 경로로 맞춘다.

    맞출 수 없으면 None 이다 — 사용자가 더한 훅이므로 기대 목록과 대조하지 않는다.
    첫 낱말만 경로로 본다. 하네스의 선언은 셔뱅으로 부르므로 경로가 언제나 첫 낱말이다.
    """
    words = (command or "").split()
    if not words:
        return None
    first = words[0]
    for prefix in _PREFIXES:
        if first.startswith(prefix):
            return first[len(prefix):]
    if first.startswith("/"):
        try:
            return str(pathlib.Path(first).resolve().relative_to(root))
        except ValueError:
            return None
    return None


def _expected(manifest: dict) -> set[str]:
    """매니페스트의 files 에서 훅 디렉터리의 직속 자녀만 뽑는다.

    「직속 자녀」로 못 박는다. 하위 디렉터리를 만드는 순간 그 안의 파일이
    기대 목록에 들어가 자기 자신을 결손으로 잡기 때문이다.
    """
    out = set()
    for entry in manifest.get("files") or []:
        dest = entry.get("dest") or ""
        if not dest.startswith(HOOK_DIR + "/"):
            continue
        if "/" in dest[len(HOOK_DIR) + 1:]:
            continue
        out.add(dest)
    return out


def _declared(settings: dict, root: pathlib.Path) -> set[str]:
    out = set()
    for group_list in (settings.get("hooks") or {}).values():
        for group in group_list or []:
            for hook in (group or {}).get("hooks") or []:
                path = normalize((hook or {}).get("command", ""), root)
                if path:
                    out.add(path)
    return out


def _load(path: pathlib.Path, absent_kind: str, broken_kind: str, rel: str):
    """JSON 을 읽는다. 실패하면 결손 한 건을 돌려준다.

    없는 것과 깨진 것을 가른다 — 복구가 다르다. 없으면 재배포이고 깨졌으면 고치는 것이다.
    """
    try:
        return json.loads(path.read_text(encoding="utf-8")), None
    except FileNotFoundError:
        return None, {"kind": absent_kind, "path": rel}
    except Exception:
        return None, {"kind": broken_kind, "path": rel}


def check_registration(root: pathlib.Path | None) -> dict:
    """훅 등록을 확인한다. 매니페스트의 기대 목록과 설정의 선언을 교차 검사한다.

    돌려주는 것은 {"ok": bool, "missing": [{"kind", "path"}]} 다.
    kind 는 닫힌 목록이 아니다 — 읽는 쪽은 모르는 값을 만나도 결손으로 센다.
    """
    if root is None:
        return {"ok": False, "missing": [{"kind": "project_root", "path": ""}]}

    manifest, failure = _load(
        root / MANIFEST, "manifest", "manifest_unreadable", MANIFEST)
    if failure:
        return {"ok": False, "missing": [failure]}

    settings, failure = _load(
        root / SETTINGS, "settings", "settings_unreadable", SETTINGS)
    if failure:
        return {"ok": False, "missing": [failure]}

    expected = _expected(manifest)
    declared = _declared(settings, root)

    missing = []
    for dest in sorted(expected):
        if dest not in declared:
            missing.append({"kind": "hook_declaration", "path": dest})
        elif not (root / dest).is_file():
            missing.append({"kind": "hook_file", "path": dest})
    return {"ok": not missing, "missing": missing}


def gate_line(result: dict) -> str:
    """게이트 판정을 기계가 읽는 한 줄로 만든다."""
    return "%s %s" % (TOKEN_GATE, json.dumps(result, ensure_ascii=False, sort_keys=True))


def format_line(changed: list[str]) -> str:
    """포맷 보고를 기계가 읽는 한 줄로 만든다."""
    payload = {"changed": sorted(changed)}
    return "%s %s" % (TOKEN_FORMAT, json.dumps(payload, ensure_ascii=False, sort_keys=True))


def additional_context(event: str, text: str) -> str:
    """도달이 확인된 채널. 종료 코드 0 + stdout JSON 이다(1차 실측 2026-08-20)."""
    return json.dumps(
        {"hookSpecificOutput": {"hookEventName": event, "additionalContext": text}},
        ensure_ascii=False,
    )


def inside_root(target: str, root: pathlib.Path) -> bool:
    """대상 경로가 프로젝트 루트 안인가.

    **심볼릭 링크를 따라간 뒤에 비교한다.** 루트 안의 링크가 밖을 가리키면
    경로 문자열만으로는 안에 있는 것으로 보인다.

    **쓰기 직전이라 대상이 아직 없어도 성립한다.** `Path.resolve()` 는 없는
    경로에도 동작하고, 존재하는 앞부분의 링크는 풀어 준다. 없는 조상을 직접
    되짚는 코드를 두었다가 변이 검사에서 아무 시험에도 안 걸려 지웠다 —
    `resolve()` 가 이미 하는 일이었다.
    """
    if not target:
        return False
    path = pathlib.Path(target)
    if not path.is_absolute():
        path = root / path
    try:
        resolved = path.resolve()
    except OSError:
        return False
    try:
        resolved.relative_to(root)
    except ValueError:
        return False
    return True


def blocked(event: str, result: dict) -> str:
    """차단하는 훅이 stderr 에 내는 것. 종료 코드 2와 함께 쓴다."""
    return "%s\n%s\n" % (describe(result), gate_line(result))


def describe(result: dict) -> str:
    """사람이 읽는 한 줄. 계약이 아니다 — 판정은 언제나 GRIDFIN_GATE 줄로 한다."""
    if result.get("ok"):
        return "훅 등록 확인 통과."
    items = ", ".join(
        "%s(%s)" % (m.get("path") or "-", m.get("kind")) for m in result.get("missing", []))
    kinds = {m.get("kind") for m in result.get("missing", [])}
    if kinds == {"outside_root"}:
        return "프로젝트 루트 밖에는 쓰지 않는다 — %s." % items
    return "게이트가 막았다 — %s. `gridfin deploy` 를 다시 실행한다." % items
