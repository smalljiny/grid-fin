#!/usr/bin/env bash
# 이슈 #2 훅 스크립트 — 통합 조건 2개
#
# 스펙: docs/work/2-hook-scripts/spec.md §6.9
#
# **단위 시험이 답하지 못하는 것 하나만 여기서 잰다** — 도구 호출이 실제로
# 진행되지 않았는가. 훅 스크립트는 파일을 만들지 않으므로 스크립트를 직접 불러
# 「파일이 생기지 않았다」를 재면 언제나 통과한다.
#
# **결과가 없는 것만으로는 판정하지 않는다.** 모델이 도구를 아예 부르지 않아도
# 파일은 생기지 않는다. 네 가지가 함께 참이어야 한다 —
#   ⓐ 세션 기록에 그 도구 호출이 있고
#   ⓑ 훅이 발화했으며
#   ⓒ 그 호출의 결과가 차단이고
#   ⓓ 산출물이 없다.
# 시도 자체를 못 시키면 통과가 아니라 **미판정**이다.
#
# **회귀 실행 대상에서 빠진다.** verify-hooks.sh 가 이 파일을 부르지 않는다 —
# claude -p 를 부르고 네트워크를 요구한다.
#
#   bash tests/verify-hooks-live.sh

set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
MODEL="${GRIDFIN_LIVE_MODEL:-haiku}"

command -v claude >/dev/null || { printf '  건너뜀 — claude 명령이 없다\n'; exit 0; }

GRIDFIN_RUN=$(mktemp -d)
trap 'rm -rf "$GRIDFIN_RUN"' EXIT
export TMPDIR="$GRIDFIN_RUN"
mk() { mktemp -d "$GRIDFIN_RUN/t.XXXXXXXX"; }

fixture_harness() {
  h="$GRIDFIN_RUN/harness"
  if [ ! -d "$h" ]; then
    git -c init.defaultBranch=main init -q "$h"
    git -C "$h" config user.email fixture@gridfin
    git -C "$h" config user.name  gridfin-fixture
    cp -R "$ROOT/payload" "$h/payload"
    git -C "$h" add -A
    git -C "$h" commit -qm v1
  fi
  printf '%s' "$h"
}

deployed() {
  d=$(mk)
  if ! ( cd "$d" && git -c init.defaultBranch=main init -q . &&
         git config user.email a@b && git config user.name a &&
         printf 'x\n' > f.txt && git add -A && git commit -qm init &&
         "$ROOT/bin/gridfin" deploy --from "$(fixture_harness)" >/dev/null ); then
    rm -rf "$d"; return 1
  fi
  printf '%s' "$d"
}

# 훅이 발화한 것을 부수 효과로 남긴다. stream-json 의 훅 사건에만 기대지 않는다
mark_hook() {  # $1=대상 $2=훅 이름
  f="$1/.claude/scripts/hooks/$2.py"
  python3 - "$f" "$1/훅발화-$2.log" <<'PY'
import io, sys
path, log = sys.argv[1], sys.argv[2]
s = io.open(path, encoding="utf-8").read()
mark = "\nimport pathlib as _pl\n_pl.Path(%r).open('a').write('fired\\n')\n" % log
s = s.replace('\nEVENT = "', mark + '\nEVENT = "', 1)
io.open(path, "w", encoding="utf-8").write(s)
PY
}

run_claude() {  # $1=대상 $2=프롬프트 → 기록을 $GRIDFIN_RUN/stream.jsonl 에 남긴다
  ( cd "$1" && CLAUDE_PROJECT_DIR="$1" claude -p "$2" \
      --output-format stream-json --verbose --model "$MODEL" ) \
    < /dev/null > "$GRIDFIN_RUN/stream.jsonl" 2>"$GRIDFIN_RUN/stream.err"
}

# 기록에서 도구 호출을 찾는다
tool_called() {  # $1=도구 이름 $2=문자열
  python3 - "$GRIDFIN_RUN/stream.jsonl" "$1" "$2" <<'PY'
import json, sys
path, tool, needle = sys.argv[1], sys.argv[2], sys.argv[3]
for line in open(path, encoding="utf-8"):
    line = line.strip()
    if not line:
        continue
    try:
        event = json.loads(line)
    except Exception:
        continue
    for block in (event.get("message") or {}).get("content") or []:
        if not isinstance(block, dict) or block.get("type") != "tool_use":
            continue
        if block.get("name") != tool:
            continue
        if needle in json.dumps(block.get("input") or {}, ensure_ascii=False):
            sys.exit(0)
sys.exit(1)
PY
}

# 그 호출의 결과가 차단이었는가
tool_blocked() {  # $1=문자열
  python3 - "$GRIDFIN_RUN/stream.jsonl" "$1" <<'PY'
import json, sys
path, needle = sys.argv[1], sys.argv[2]
blob = []
for line in open(path, encoding="utf-8"):
    line = line.strip()
    if not line:
        continue
    try:
        event = json.loads(line)
    except Exception:
        continue
    for block in (event.get("message") or {}).get("content") or []:
        if isinstance(block, dict) and block.get("type") == "tool_result":
            blob.append(json.dumps(block, ensure_ascii=False))
text = "\n".join(blob)
sys.exit(0 if ("GRIDFIN_GATE" in text or needle in text) else 1)
PY
}

# ── 6.9 통합 ──────────────────────────────────────────────

c43_desc="C43 루트 밖에 쓰라고 시키면 파일이 생기지 않는다"
c43() {
  T=$(deployed); mark_hook "$T" pre-write
  O=$(mk); victim="$O/victim.txt"
  run_claude "$T" "$(printf 'Write 도구로 %s 에 hello 라고 써라. 실패하면 그대로 보고하고 다른 방법을 찾지 마라.' "$victim")"
  #      ⓐ 그 경로의 Write 또는 Edit 호출이 기록에 있다
  tool_called Write "$victim" || tool_called Edit "$victim" || {
    printf '미판정 — 모델이 쓰기를 시도하지 않았다\n'; return 1; }
  #      ⓑ 훅이 발화했다
  test -f "$T/훅발화-pre-write.log"
  #      ⓒ 결과가 차단이다
  tool_blocked "$victim"
  #      ⓓ 파일이 생기지 않았다
  test ! -e "$victim"
}

c44_desc="C44 선언 설정이 없는 상태로 커밋하라고 시키면 커밋이 생기지 않는다"
c44() {
  T=$(deployed); mark_hook "$T" pre-commit
  test ! -f "$T/gridfin.json"
  before=$(git -C "$T" rev-parse HEAD)
  printf 'y\n' > "$T/새파일.txt"
  run_claude "$T" 'Bash 도구로 git add -A && git commit -m "시험" 를 실행해라. 실패하면 그대로 보고하고 다른 방법을 찾지 마라.'
  #      ⓐ 커밋 명령의 Bash 호출이 기록에 있다
  tool_called Bash "commit" || { printf '미판정 — 모델이 커밋을 시도하지 않았다\n'; return 1; }
  #      ⓑ 훅이 발화했다
  test -f "$T/훅발화-pre-commit.log"
  #      ⓒ 결과가 차단이다
  tool_blocked "GRIDFIN_GATE"
  #      ⓓ 커밋이 생기지 않았다
  test "$(git -C "$T" rev-parse HEAD)" = "$before"
}

# ── 실행기 ────────────────────────────────────────────────
ALL="43 44"

pass=0; fail=0
for n in ${*:-$ALL}; do
  desc=$(eval "printf '%s' \"\${c${n}_desc:-}\"")
  if [ -z "$desc" ]; then printf '  ???  %-3s 그런 시험이 없다\n' "$n"; fail=$((fail+1)); continue; fi
  log="$GRIDFIN_RUN/t$n.log"
  ( set -e; "c$n" ) >"$log" 2>&1
  rc=$?
  if [ "$rc" -eq 0 ]; then
    printf '  PASS %-3s %s\n' "$n" "$desc"; pass=$((pass+1))
  else
    printf '  FAIL %-3s %s\n' "$n" "$desc"; fail=$((fail+1))
    tail -5 "$log" | sed 's/^/         /'
  fi
done
printf '\n  통과 %s · 실패 %s\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
