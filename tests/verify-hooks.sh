#!/usr/bin/env bash
# 이슈 #2 훅 스크립트 — 단위 조건
#
# 스펙: docs/work/2-hook-scripts/spec.md §6
# 층: 단위만 실행한다. 「실제로 멈췄는가」는 통합 조건이고 tests/verify-hooks-live.sh 에 있다.
#     훅 스크립트는 파일을 만들지 않으므로 여기서 잴 수 있는 것은 종료 코드와 보고 형식까지다.
#
#   bash tests/verify-hooks.sh          전부
#   bash tests/verify-hooks.sh 1 3      고른 것만

set -uo pipefail   # -e 는 시험 함수 안에서만 건다. 실행기가 결과를 모아야 한다

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
P="$ROOT/payload"

GRIDFIN_RUN=$(mktemp -d)
trap 'rm -rf "$GRIDFIN_RUN"' EXIT
export TMPDIR="$GRIDFIN_RUN"
mk() { mktemp -d "$GRIDFIN_RUN/t.XXXXXXXX"; }

# 시간을 걸어 실행한다. 이 머신에 timeout(1) 이 없다 — coreutils 를 요구하지 않는다.
# 훅이 stdin 을 안 읽고 매달리면 시험 전체가 멈추므로 상한이 필요하다.
# 124 는 timeout(1) 의 관례를 따른 것이다.
bounded() {
  secs=$1; shift
  "$@" & pid=$!
  i=0
  while kill -0 "$pid" 2>/dev/null; do
    i=$((i+1))
    if [ "$i" -gt $((secs * 20)) ]; then
      kill -9 "$pid" 2>/dev/null; wait "$pid" 2>/dev/null
      return 124
    fi
    sleep 0.05
  done
  wait "$pid"
}

# settings.json 의 선언에서 명령 경로를 뽑아 저장소 루트 기준으로 맞춘다.
# 스펙 §3.3 의 정규화 규칙과 같다 — 접두를 벗기고, 첫 낱말만 경로로 본다.
declared_paths() {
  jq -r '.hooks | to_entries[] | .value[] | .hooks[] | .command' "$1" |
  while IFS= read -r c; do
    c=${c%% *}
    c=${c#\$\{CLAUDE_PROJECT_DIR\}/}
    c=${c#\$CLAUDE_PROJECT_DIR/}
    printf '%s\n' "$c"
  done
}

# ── 6.1 등록과 배선 ────────────────────────────────────────

t1_desc="C1 사건 3개에 훅 4개를 선언하고, 선언된 명령 경로 4개가 payload 안에 파일로 있다"
t1() {
  S="$P/claude/settings.json"
  jq -e . "$S" > /dev/null

  #      사건이 정확히 셋이다. 넷이면 설계가 정한 값과 어긋난다
  test "$(jq -r '.hooks | keys | length' "$S")" = 3
  jq -e '.hooks | has("SessionStart") and has("PreToolUse") and has("PostToolUse")' "$S" > /dev/null

  #      훅 항목이 정확히 넷이다
  test "$(jq -r '[.hooks[][] .hooks[]] | length' "$S")" = 4

  #      배선이 하나씩이다. 이름만 맞고 자리가 틀린 것을 잡는다
  jq -e '.hooks.SessionStart | length == 1' "$S" > /dev/null
  jq -e '.hooks.PreToolUse   | length == 2' "$S" > /dev/null
  jq -e '.hooks.PostToolUse  | length == 1' "$S" > /dev/null

  #      쓰기 경계와 커밋 경계가 다른 스크립트다. 지금은 뒤바뀌어 있다
  jq -e '[.hooks.PreToolUse[] | select(.matcher | test("Write")) | .hooks[0].command] | length == 1
         and (.[0] | test("pre-write\\.py$"))' "$S" > /dev/null
  jq -e '[.hooks.PreToolUse[] | select(.matcher == "Bash") | .hooks[0].command] | length == 1
         and (.[0] | test("pre-commit\\.py$"))' "$S" > /dev/null
  jq -e '[.hooks.PostToolUse[] | .hooks[0].command] | .[0] | test("format\\.py$")' "$S" > /dev/null

  #      선언된 경로 넷이 payload 안에 실물로 있다
  n=0
  while IFS= read -r p; do
    test -f "$P/claude/${p#.claude/}"
    n=$((n+1))
  done < <(declared_paths "$S")
  test "$n" = 4
}

t2_desc="C2 훅 스크립트 4개가 uv 셔뱅으로 직접 실행되고, stdin 의 JSON 을 읽어 종료한다"
t2() {
  S="$P/claude/settings.json"
  in="$GRIDFIN_RUN/probe.json"
  printf '%s' '{"hook_event_name":"Probe","cwd":"/tmp"}' > "$in"

  #      디렉터리를 훑지 않는다. settings.json 이 선언한 경로에서 뽑는다 —
  #      선언이 다른 파일을 가리켜도 디렉터리에 넷이 남아 있으면 통과하기 때문이다
  n=0
  while IFS= read -r p; do
    f="$P/claude/${p#.claude/}"
    test -f "$f"
    #      실행 비트가 없으면 셔뱅이 뜻이 없다
    test -x "$f"
    head -1 "$f" | grep -qF '#!/usr/bin/env -S uv run --script'
    #      직접 실행된다. stdin 에 JSON 을 넣고 걸리지 않는지 본다.
    #      종료 코드는 훅마다 다르므로 여기서 보지 않는다 — 실행 자체를 잰다.
    #      파이프 대신 파일로 넣는다. bounded 가 배경으로 돌리므로 stdin 을 물려받아야 한다
    rc=0
    bounded 60 "$f" < "$in" >/dev/null 2>&1 || rc=$?
    test "$rc" != 124   # 타임아웃이면 stdin 을 안 읽고 매달린 것이다
    test "$rc" != 126   # 실행 불가
    test "$rc" != 127   # 셔뱅이 풀리지 않았다
    n=$((n+1))
  done < <(declared_paths "$S")
  test "$n" = 4

  #      선언되지 않은 훅 스크립트가 디렉터리에 남아 있지 않다.
  #      남으면 등록 확인의 기대 목록에 들어가 자기 자신을 결손으로 잡는다(스펙 §3.3)
  test "$(find "$P/claude/scripts/hooks" -maxdepth 1 -type f | wc -l | tr -d ' ')" = 4
}

t3_desc="C4 rules.json 의 소유 지점 4개와 식별자 유일성"
t3() {
  R="$P/rules.json"
  jq -e . "$R" > /dev/null
  O='.["claude/settings.json"].owned'

  #      소유 지점이 정확히 넷이고 넷이 무엇인지 못 박는다
  jq -e "$O | length == 4" "$R" > /dev/null
  for ptr in /hooks/SessionStart /hooks/PreToolUse /hooks/PostToolUse /permissions/allow; do
    jq -e --arg p "$ptr" "$O | map(.pointer) | index(\$p) != null" "$R" > /dev/null
  done

  #      훅 배열 셋은 식별자가 (matcher, command) 쌍이다
  for ptr in /hooks/SessionStart /hooks/PreToolUse /hooks/PostToolUse; do
    jq -e --arg p "$ptr" \
      "$O | map(select(.pointer == \$p))[0].key == [\"/matcher\", \"/hooks/0/command\"]" "$R" > /dev/null
  done
  #      permissions.allow 는 문자열 배열이라 식별자가 값 자체다
  jq -e "$O | map(select(.pointer == \"/permissions/allow\"))[0].key == null" "$R" > /dev/null

  #      실물 설정에서 그 쌍이 실제로 유일해야 한다.
  #      유일하지 않으면 배포가 거부되어 정상 경로가 막힌다
  S="$P/claude/settings.json"
  for ev in SessionStart PreToolUse PostToolUse; do
    jq -e --arg e "$ev" \
      '[.hooks[$e][] | [(.matcher // null), .hooks[0].command]] as $k
       | ($k | length) == ($k | unique | length)' "$S" > /dev/null
  done
}

# ── 실행기 ────────────────────────────────────────────────
ALL="1 2 3"

pass=0; fail=0
for n in ${*:-$ALL}; do
  desc=$(eval "printf '%s' \"\${t${n}_desc:-}\"")
  if [ -z "$desc" ]; then printf '  ???  %-3s 그런 시험이 없다\n' "$n"; fail=$((fail+1)); continue; fi
  log="$GRIDFIN_RUN/t$n.log"
  ( set -e; "t$n" ) >"$log" 2>&1
  rc=$?
  if [ "$rc" -eq 0 ]; then
    printf '  PASS %-3s %s\n' "$n" "$desc"; pass=$((pass+1))
  else
    printf '  FAIL %-3s %s\n' "$n" "$desc"; fail=$((fail+1))
    tail -3 "$log" | sed 's/^/         /'
  fi
done
printf '\n  통과 %s · 실패 %s\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
