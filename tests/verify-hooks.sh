#!/usr/bin/env bash
# 이슈 #2 훅 스크립트 — 단위 조건
#
# 스펙: docs/work/2-hook-scripts/spec.md §6
# 층: 단위만 실행한다. 「실제로 멈췄는가」는 통합 조건이고 tests/verify-hooks-live.sh 에 있다.
#     훅 스크립트는 파일을 만들지 않으므로 여기서 잴 수 있는 것은 종료 코드와 보고 형식까지다.
#
#   bash tests/verify-hooks.sh          전부
#   bash tests/verify-hooks.sh 1 5      고른 것만 (번호는 검증 조건 번호다)

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

# 하네스 픽스처. payload/ 를 복제해 커밋한 저장소다.
# 실물 저장소를 --from 으로 주면 payload/ 가 dirty 할 때 배포가 거부된다.
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

# 배포가 끝난 대상 저장소를 하나 만든다.
# command substitution 안에서는 set -e 가 기대처럼 전파되지 않으므로 직접 전파한다
deployed() {
  d=$(mk)
  if ! (cd "$d" && git init -q && "$ROOT/bin/gridfin" deploy --from "$(fixture_harness)" >/dev/null); then
    rm -rf "$d"; return 1
  fi
  printf '%s' "$d"
}

# SessionStart 훅을 부르고 stdout 을 돌려준다. 종료 코드는 $HOOK_RC 에 남긴다.
# 필드는 실측한 것 그대로다(2026-08-20, Claude Code 2.1.237)
# 종료 코드를 파일로 넘긴다. 이 함수는 명령 치환 안에서 불리므로
# 변수에 담으면 부속 셸에 갇혀 밖으로 나오지 않는다(실측)
run_session_start() {  # $1=대상 디렉터리
  in="$GRIDFIN_RUN/ss.json"
  printf '{"session_id":"t","transcript_path":"/dev/null","cwd":"%s","hook_event_name":"SessionStart","source":"startup"}' "$1" > "$in"
  rc=0
  ( cd "$1" && CLAUDE_PROJECT_DIR="$1" "$1/.claude/scripts/hooks/session-start.py" ) < "$in" > "$GRIDFIN_RUN/ss.out" 2>"$GRIDFIN_RUN/ss.err" || rc=$?
  printf '%s' "$rc" > "$GRIDFIN_RUN/ss.rc"
  cat "$GRIDFIN_RUN/ss.out"
}
hook_rc() { cat "$GRIDFIN_RUN/ss.rc"; }

# additionalContext 에 실린 GRIDFIN_GATE 줄의 JSON 을 꺼낸다
gate_json() { jq -r '.hookSpecificOutput.additionalContext' | sed -n 's/^.*GRIDFIN_GATE //p' | head -1; }

# 「보고하지 않는다」를 재는 시험은 그것만으로 거짓 통과한다 —
# 아무것도 안 하는 구현이 언제나 통과하기 때문이다.
# 같은 대상을 일부러 깨서 보고가 실제로 나오는지 함께 본다.
assert_gate_live() {  # $1=대상 디렉터리
  rm "$1/.claude/scripts/hooks/format.py"
  run_session_start "$1" | grep -q GRIDFIN_GATE
}

# ── 6.1 등록과 배선 ────────────────────────────────────────

c1_desc="C1 사건 3개에 훅 4개를 선언하고, 선언된 명령 경로 4개가 payload 안에 파일로 있다"
c1() {
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

c2_desc="C2 훅 스크립트 4개가 uv 셔뱅으로 직접 실행되고, stdin 의 JSON 을 읽어 종료한다"
c2() {
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

c4_desc="C4 rules.json 의 소유 지점 4개와 식별자 유일성"
c4() {
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

# ── 6.2 세션 시작 ──────────────────────────────────────────

c3_desc="C3 공용 모듈이 기대 목록에 들어가지 않는다 — 배포된 대상에서 ok 가 참이다"
c3() {
  T=$(deployed)
  #      공용 모듈이 배포는 된다
  test -f "$T/.claude/scripts/gridfin/gate.py"
  #      그런데 hooks/ 의 직속 자녀가 아니므로 기대 목록에 없다
  jq -e '[.files[].dest | select(startswith(".claude/scripts/hooks/"))] | length == 4' "$T/.harness/manifest.json" > /dev/null
  #      그래서 등록 확인이 통과한다. 모듈을 hooks/ 아래 두면 여기서 결손이 난다
  out=$(run_session_start "$T")
  test "$(hook_rc)" = 0
  printf '%s' "$out" | grep -q GRIDFIN_GATE && return 1

  #      기대 목록이 「직속 자녀」로 한정된다.
  #      hooks/ 아래에 디렉터리를 파고 파일을 넣어도 결손이 나지 않아야 한다.
  #      한정하지 않으면 hooks/lib/ 를 만드는 순간 같은 자기모순이 되살아난다(S34)
  mkdir -p "$T/.claude/scripts/hooks/lib"
  printf 'x\n' > "$T/.claude/scripts/hooks/lib/helper.py"
  jq '.files += [{"dest":".claude/scripts/hooks/lib/helper.py"}]' "$T/.harness/manifest.json" > "$T/t.json"
  mv "$T/t.json" "$T/.harness/manifest.json"
  out=$(run_session_start "$T")
  test "$(hook_rc)" = 0
  printf '%s' "$out" | grep -q GRIDFIN_GATE && return 1
  #      그 상태에서 검사가 여전히 살아 있다
  assert_gate_live "$T"
}

c5_desc="C5 등록이 온전하면 종료 코드 0으로 끝나고 결손을 보고하지 않는다"
c5() {
  T=$(deployed)
  out=$(run_session_start "$T")
  test "$(hook_rc)" = 0
  #      아무것도 보고하지 않는다. 「보고는 하는데 ok 가 참」과 구별한다
  test -z "$out"
  #      검사가 살아 있는지 함께 본다. 없으면 아무것도 안 하는 구현이 통과한다
  assert_gate_live "$T"

  #      환경변수가 없으면 stdin 의 cwd 로 루트를 찾는다.
  #      환경변수만 보면 하위 세션이나 다른 실행기에서 루트를 못 찾는다
  T2=$(deployed)
  in="$GRIDFIN_RUN/ss2.json"
  printf '{"session_id":"t","transcript_path":"/dev/null","cwd":"%s","hook_event_name":"SessionStart","source":"startup"}' "$T2" > "$in"
  rc=0
  ( cd / && env -u CLAUDE_PROJECT_DIR "$T2/.claude/scripts/hooks/session-start.py" ) < "$in" > "$GRIDFIN_RUN/ss2.out" 2>&1 || rc=$?
  test "$rc" = 0
  test ! -s "$GRIDFIN_RUN/ss2.out"
  #      그 경로에서도 검사가 살아 있다
  rm "$T2/.claude/scripts/hooks/format.py"
  ( cd / && env -u CLAUDE_PROJECT_DIR "$T2/.claude/scripts/hooks/session-start.py" ) < "$in" | grep -q GRIDFIN_GATE
}

c6_desc="C6 훅 선언 1개를 지우면 additionalContext 에 hook_declaration 으로 그 경로를 싣는다"
c6() {
  T=$(deployed)
  jq 'del(.hooks.PostToolUse)' "$T/.claude/settings.json" > "$T/t.json"
  mv "$T/t.json" "$T/.claude/settings.json"
  g=$(run_session_start "$T" | gate_json)
  test "$(hook_rc)" = 0
  printf '%s' "$g" | jq -e '.ok == false' > /dev/null
  printf '%s' "$g" | jq -e '[.missing[] | select(.kind=="hook_declaration") | .path]
                            | index(".claude/scripts/hooks/format.py") != null' > /dev/null

  #      기대 목록이 매니페스트에서 나온다. 스크립트에 박아 두면 이것을 못 잡는다 —
  #      배포 대상이 늘 때마다 고칠 곳이 늘지 않는 것이 이 설계의 요점이다
  T2=$(deployed)
  printf 'x\n' > "$T2/.claude/scripts/hooks/extra.py"
  jq '.files += [{"dest":".claude/scripts/hooks/extra.py"}]' "$T2/.harness/manifest.json" > "$T2/t.json"
  mv "$T2/t.json" "$T2/.harness/manifest.json"
  g=$(run_session_start "$T2" | gate_json)
  printf '%s' "$g" | jq -e '[.missing[] | select(.kind=="hook_declaration") | .path]
                            | index(".claude/scripts/hooks/extra.py") != null' > /dev/null
}

c7_desc="C7 선언된 경로가 파일로 없으면 kind 가 hook_file 이다"
c7() {
  T=$(deployed)
  rm "$T/.claude/scripts/hooks/pre-write.py"
  g=$(run_session_start "$T" | gate_json)
  test "$(hook_rc)" = 0
  printf '%s' "$g" | jq -e '.ok == false' > /dev/null
  printf '%s' "$g" | jq -e '[.missing[] | select(.kind=="hook_file") | .path]
                            | index(".claude/scripts/hooks/pre-write.py") != null' > /dev/null
  #      선언이 사라진 것이 아니므로 hook_declaration 으로 보고하지 않는다
  printf '%s' "$g" | jq -e '[.missing[] | select(.kind=="hook_declaration")] | length == 0' > /dev/null
}

c8_desc="C8 매니페스트가 없으면 kind 가 manifest 다"
c8() {
  T=$(deployed)
  rm "$T/.harness/manifest.json"
  g=$(run_session_start "$T" | gate_json)
  test "$(hook_rc)" = 0
  printf '%s' "$g" | jq -e '.ok == false and ([.missing[].kind] | index("manifest") != null)' > /dev/null
}

c9_desc="C9 session-start.py 는 어느 경우에도 종료 코드 2를 내지 않는다"
c9() {
  T=$(deployed)
  #      ⓐ 정상
  run_session_start "$T" > /dev/null; test "$(hook_rc)" != 2
  #      ⓑ 매니페스트가 깨진 JSON — 예외를 삼켜 조용히 통과해도 안 되고 막아도 안 된다
  printf 'not json' > "$T/.harness/manifest.json"
  g=$(run_session_start "$T" | gate_json); test "$(hook_rc)" != 2
  printf '%s' "$g" | jq -e '.ok == false' > /dev/null
  #      ⓒ 설정이 깨진 JSON
  T2=$(deployed); printf '{' > "$T2/.claude/settings.json"
  g=$(run_session_start "$T2" | gate_json); test "$(hook_rc)" != 2
  printf '%s' "$g" | jq -e '.ok == false' > /dev/null
  #      ⓓ stdin 이 JSON 이 아니다
  T3=$(deployed); rc=0
  printf 'not json' | ( cd "$T3" && CLAUDE_PROJECT_DIR="$T3" "$T3/.claude/scripts/hooks/session-start.py" ) >/dev/null 2>&1 || rc=$?
  test "$rc" != 2
  #      ⓔ 설정 파일 자체가 없다
  T4=$(deployed); rm "$T4/.claude/settings.json"
  run_session_start "$T4" > /dev/null; test "$(hook_rc)" != 2
}

c16_desc="C16 사용자가 더한 훅 선언이 있어도 등록 확인이 통과한다"
c16() {
  T=$(deployed)
  #      기대 목록에 없는 경로를 사용자가 더한다. 파일은 만들지 않는다 —
  #      하네스가 배포하지 않은 것의 존재까지 책임지면 남의 훅 때문에 막힌다
  jq '.hooks.PreToolUse += [{"matcher":"Read","hooks":[{"type":"command",
       "command":"${CLAUDE_PROJECT_DIR}/.claude/scripts/hooks-mine/mine.py"}]}]'      "$T/.claude/settings.json" > "$T/t.json"
  mv "$T/t.json" "$T/.claude/settings.json"
  out=$(run_session_start "$T")
  test "$(hook_rc)" = 0
  test -z "$out"
  #      사용자 훅을 그대로 둔 채 하네스 훅을 깨면 보고가 나온다 —
  #      남의 선언 때문에 검사가 통째로 꺼진 것이 아니다
  assert_gate_live "$T"
}

c17_desc="C17 선언 경로가 세 형태 중 어느 것이어도 기대 목록과 대조된다"
c17() {
  for form in 1 2 3; do
    T=$(deployed)
    case $form in
      1) v='${CLAUDE_PROJECT_DIR}/.claude/scripts/hooks/session-start.py' ;;
      2) v='$CLAUDE_PROJECT_DIR/.claude/scripts/hooks/session-start.py' ;;
      3) v="$T/.claude/scripts/hooks/session-start.py" ;;
    esac
    jq --arg v "$v" '.hooks.SessionStart[0].hooks[0].command = $v'        "$T/.claude/settings.json" > "$T/t.json"
    mv "$T/t.json" "$T/.claude/settings.json"
    out=$(run_session_start "$T")
    test "$(hook_rc)" = 0
    #      셋 다 같은 경로로 풀려야 하므로 결손이 없다
    test -z "$out"
    #      그 형태를 둔 채 다른 훅을 깨면 보고가 나온다 —
    #      경로가 안 풀려서 조용한 것이 아니라 실제로 대조가 됐다
    assert_gate_live "$T"
  done
}

# ── 실행기 ────────────────────────────────────────────────
ALL="1 2 3 4 5 6 7 8 9 16 17"

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
    tail -3 "$log" | sed 's/^/         /'
  fi
done
printf '\n  통과 %s · 실패 %s\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
