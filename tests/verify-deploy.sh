#!/usr/bin/env bash
# 이슈 #1 배포 스크립트 — 검증 명령 35개
#
# 출처: docs/tmp/issue-1-spec.md 의 「검증 명령」 절 (교차 검토 10회차 결과)
# 보관 이유: 이것은 구현 단계의 산출물이다. 스펙과 구현 계획이 끝난 뒤 tests/ 로 옮긴다.
#            지금 버리면 열 회차가 찾아낸 시험이 사라진다.
# 전제: tests/make-fixtures.sh 가 V1 V2 V3 RM CONF CONFJ V_SPACE V_ROOT 를 내보낸다.
#       gridfin 이 아직 없으므로 지금 실행하면 전부 실패한다.
#

set -uo pipefail   # -e 는 시험 함수 안에서만 건다. 실행기가 결과를 모아야 한다

# 이 실행이 만드는 임시 디렉터리를 한 곳에 모은다. 끝나면 통째로 지운다.
# fixture 저장소와 시험마다 만드는 대상 디렉터리가 전부 여기 들어간다.
# gridfin 은 저장소의 bin/ 에 있다. 전역 설치 없이 시험이 돌게 PATH 앞에 붙인다.
PATH="$(cd "$(dirname "$0")/../bin" && pwd):$PATH"; export PATH

GRIDFIN_RUN=$(mktemp -d)
trap 'rm -rf "$GRIDFIN_RUN"' EXIT
export TMPDIR="$GRIDFIN_RUN"

# ── 준비물 ──────────────────────────────────────────────
# 하네스 저장소 8개를 만드는 스크립트를 #1이 함께 만든다. 검증 블록은 그것을 부른다.
# 이 블록이 그대로 실행되어야 「검증 명령이 실행 가능하다」는 이 저장소의 요건을 만족한다.
eval "$(bash tests/make-fixtures.sh)"   # V1 V2 V3 RM CONF CONFJ V_SPACE V_ROOT 를 내보낸다

# V1     : 「fixture payload」 절의 자리표시본 그대로
# V2     : V1에서 allow에 "Bash(rg:*)" 추가·"Bash(gh:*)" 삭제 / PreToolUse에 matcher "Edit" 추가
#          / SessionStart의 command를 session-start-v2.py로 변경 / pre-commit.py 끝에 한 줄 추가
# V3     : V2에서 pre-commit.py 끝에 또 한 줄 추가
# RM     : V1에서 format.py를 뺀 것
# CONF   : V1에서 pre-commit.py의 첫 줄을 고친 것
# CONFJ  : V1에서 statusLine.command를 ".../status-harness.py"로 바꾼 것
# V_SPACE: V1에 payload/claude/scripts/hooks/"이름 있는 훅.py" 를 더한 것
# V_ROOT : V1에 payload/root/gridfin.json 을 더한 것

# 건너뛴 파일의 매니페스트 항목이 그대로인지 보는 보조 함수
entry() { jq -c --arg d "$2" '.files[] | select(.dest==$d) | {sourceSha,sourceHash,installedHash}' "$1"; }

# 시험마다 v1이 배포된 새 대상을 만든다
# fresh는 실패를 반드시 전파한다. 아래 형태가 아니면 배포 실패가 조용히 통과한다 —
#   d=$(mktemp -d); (cd "$d" && ...) >/dev/null; echo "$d"
#   command substitution 안에서는 set -e가 기대처럼 전파되지 않는다(실측)
fresh() {
  d=$(mktemp -d)
  if ! (cd "$d" && git init -q && gridfin deploy --from "$V1" >/dev/null); then rm -rf "$d"; return 1; fi
  echo "$d"
}
# 충돌 시 남는 .merged는 배포 산출물이 아니라 보고물이므로 제외한다
# 공백·유니코드 파일명을 견디도록 NUL로 구분한다
tree_hash() { find "$1" -type f ! -name '*.merged' -print0 | sort -z | xargs -0 shasum -a 256 | shasum -a 256 | cut -d' ' -f1; }
# 거부(2)와 부분 실패(1)를 구별한다. 아무 비0이나 받으면 전부 같은 코드를 내는 구현이 통과한다
rejected() { if "$@"; then return 1; else test $? -eq 2; fi; }
partial()  { if "$@"; then return 1; else test $? -eq 1; fi; }

# ── 시험 ──────────────────────────────────────────────────

t1_desc="배포되면 파일과 매니페스트가 생기고 서로 맞는다"
t1() {
  T=$(fresh); cd "$T"
  jq -e . .harness/manifest.json > /dev/null
  jq -e . .claude/settings.json > /dev/null
  # 쉼표는 항목마다 붙는 구분자가 아니다 — 파이프로 갈라야 항목마다 NUL 이 붙는다
  jq -rj '.files[] | .dest, "\u0000"' .harness/manifest.json | while IFS= read -r -d '' d; do test -f "$d"; done
  jq -e '[.files[].dest] | index(".harness/manifest.json") == null' .harness/manifest.json
}

t2_desc="파일마다 sourceSha로 base를 꺼낼 수 있고 sourceHash가 그것과 맞는다"
t2() {
  #      전 항목을 돈다. 하나만 맞는 구현이 통과하지 못한다
  T=$(fresh); cd "$T"
  jq -r '.files[] | [.sourceSha, .src, .sourceHash] | @tsv' .harness/manifest.json |
  while IFS=$'\t' read -r sha src want; do
    git -C "$V1" cat-file -e "$sha^{commit}"
    got="sha256:$(git -C "$V1" show "$sha:$src" | shasum -a 256 | cut -d' ' -f1)"
    test "$want" = "$got"
  done
}

t3_desc="JSON 배열은 원소 단위로 병합된다 — 추가·삭제·보존을 함께 본다"
t3() {
  T=$(fresh); cd "$T"
  jq '.env.MINE = "keep" | .permissions.allow += ["Bash(mytool:*)"]' \
     .claude/settings.json > t.json && mv t.json .claude/settings.json
  gridfin deploy --from "$V2"
  jq -e '.env.MINE == "keep"' .claude/settings.json                               # owned 밖은 그대로
  jq -e '.permissions.allow | index("Bash(mytool:*)")' .claude/settings.json       # 사용자 원소가 남는다
  jq -e '.permissions.allow | index("Bash(rg:*)")' .claude/settings.json        # 하네스 추가가 반영된다
  jq -e '.permissions.allow | index("Bash(gh:*)") == null' .claude/settings.json  # 하네스 삭제가 반영된다
}

t4_desc="hooks의 중첩 배열은 matcher 식별자로 갈린다"
t4() {
  T=$(fresh); cd "$T"
  jq '.hooks.PreToolUse += [{"matcher":"MyTool","hooks":[]}]' \
     .claude/settings.json > t.json && mv t.json .claude/settings.json
  gridfin deploy --from "$V2"
  jq -e '[.hooks.PreToolUse[].matcher] | index("MyTool")' .claude/settings.json
  jq -e '[.hooks.PreToolUse[].matcher] | index("Edit")' .claude/settings.json
}

t5_desc="텍스트는 3-way merge다 — 이어붙이기와 구별한다"
t5() {
  #      사용자는 파일 중간에, V2는 파일 끝에 줄을 더한다
  T=$(fresh); cd "$T"
  awk 'NR==2{print "// 사용자가 중간에 넣은 줄"}1' .claude/scripts/hooks/pre-commit.py > t.py
  cat t.py > .claude/scripts/hooks/pre-commit.py && rm t.py   # mv 는 모드를 떨어뜨린다
  gridfin deploy --from "$V2"
  git -C "$V2" show HEAD:payload/claude/scripts/hooks/pre-commit.py |
    awk 'NR==2{print "// 사용자가 중간에 넣은 줄"}1' > expected.py
  diff expected.py .claude/scripts/hooks/pre-commit.py
  #      단순 이어붙이기는 사용자 줄이 끝으로 가므로 이 비교에서 실패한다
}

t6_desc="충돌하면 살아 있는 파일이 바이트까지 그대로다"
t6() {
  T=$(fresh); cd "$T"
  #      사용자와 CONF가 같은 첫 줄을 각각 다르게 고친 상태를 만든다
  #      mv 로 갈아치우면 모드가 떨어진다. 되쓰기로 실행 비트를 유지한다
  awk 'NR==1{print "// 사용자가 고친 첫 줄"; next}1' .claude/scripts/hooks/pre-commit.py > t.py
  cat t.py > .claude/scripts/hooks/pre-commit.py && rm t.py
  BEFORE=$(tree_hash .claude)
  partial  gridfin deploy --from "$CONF"
  test "$(tree_hash .claude)" = "$BEFORE"        # .merged를 뺀 트리는 그대로다
  test -f .claude/scripts/hooks/pre-commit.py.merged   # 병합 결과는 옆에 나온다
  #      tree_hash 는 내용만 본다. 충돌한 파일의 실행 비트를 떨어뜨리는 구현이
  #      내용만 유지하면 통과해 버리므로 모드를 따로 본다. 30번은 성공 경로만 본다
  test -x .claude/scripts/hooks/pre-commit.py
}

t7_desc="base를 못 꺼내면 덮지 않고 건너뛴다"
t7() {
  #      로컬 경로 clone은 --depth를 무시하므로 file:// 전송을 강제한다
  T=$(fresh); cd "$T"
  SH=$(mktemp -d); git clone -q --depth 1 "file://$V2" "$SH/h"
  #      매니페스트의 source.path 를 없는 경로로 바꿔 되돌아갈 곳을 끊는다.
  #      끊지 않으면 본문의 조회 순서대로 원본 저장소에서 base를 찾아 시험이 헛돈다
  jq '.source.path = "/nonexistent"' .harness/manifest.json > t.json && mv t.json .harness/manifest.json
  #      먼저 base 부재가 실제로 성립하는지 확인한다 — 이 확인이 없으면 시험이 헛돈다
  ! git -C "$SH/h" cat-file -e "$(jq -r '.files[0].sourceSha' .harness/manifest.json)^{commit}"
  BEFORE=$(tree_hash .claude); E=$(entry .harness/manifest.json .claude/scripts/hooks/pre-commit.py)
  partial  gridfin deploy --from "$SH/h"
  test "$(tree_hash .claude)" = "$BEFORE"
  test ! -e .claude/scripts/hooks/pre-commit.py.merged   # base 부재는 충돌이 아니다. 종료 코드 255를
                                                         # 충돌로 읽는 구현이 여기서 걸린다
  test "$(entry .harness/manifest.json .claude/scripts/hooks/pre-commit.py)" = "$E"
}

t8_desc="사라진 배포물은 사용자가 안 건드렸을 때만 지운다"
t8() {
  T=$(fresh); cd "$T"
  test -f .claude/scripts/hooks/format.py                       # v1에 있었다
  gridfin deploy --from "$RM"                                    # RM은 format.py를 뺀 하네스
  test ! -f .claude/scripts/hooks/format.py                      # 안 건드린 것은 지워진다
  
  #      사용자가 고친 삭제 대상은 남는다 — installedHash를 안 보는 구현이 여기서 걸린다
  T=$(fresh); cd "$T"
  echo "// 내가 고쳤다" >> .claude/scripts/hooks/format.py
  partial  gridfin deploy --from "$RM"
  test -f .claude/scripts/hooks/format.py
  grep -q '내가 고쳤다' .claude/scripts/hooks/format.py
  #      항목이 남아야 다음 배포가 다시 시도한다. 스펙 §6 이 「재지 않는 것」으로
  #      꼽았던 자리다 — 파일만 보면 항목을 지우는 구현이 통과한다
  jq -e '[.files[].dest] | index(".claude/scripts/hooks/format.py")' .harness/manifest.json
}

t9_desc="하네스가 dirty하면 거부하고 대상에 아무것도 쓰지 않는다"
t9() {
  T=$(fresh); cd "$T"
  #      V2를 더럽힌다. 이미 배포된 V1을 다시 배포하면 dirty 검사를 안 해도
  #      바뀔 것이 없어 시험이 헛돈다. 27번이 이것을 세 종류로 넓힌다
  BEFORE="$(tree_hash .claude)$(tree_hash .harness)"
  touch "$V2/payload/dirty.tmp"
  rejected gridfin deploy --from "$V2"
  test "$(tree_hash .claude)$(tree_hash .harness)" = "$BEFORE"
  rm "$V2/payload/dirty.tmp"
}

t10_desc="대상이 git 저장소가 아니면 거부하고 아무것도 쓰지 않는다"
t10() {
  T=$(mktemp -d); cd "$T"
  rejected gridfin deploy --from "$V1"
  test -z "$(ls -A)"
}

t11_desc="식별자가 유일하지 않으면 거부한다"
t11() {
  T=$(fresh); cd "$T"
  #      식별자가 쌍이므로 matcher와 command가 둘 다 같은 원소를 하나 더 넣어야 중복이 된다
  jq '.hooks.PreToolUse += [.hooks.PreToolUse[0]]' \
     .claude/settings.json > t.json && mv t.json .claude/settings.json
  jq -e '[.hooks.PreToolUse[] | [.matcher, .hooks[0].command]] as $k
         | ($k | length) != ($k | unique | length)' .claude/settings.json
  BEFORE=$(tree_hash .claude)
  rejected gridfin deploy --from "$V2"
  test "$(tree_hash .claude)" = "$BEFORE"
}

t12_desc="sourceHash가 안 맞으면 그 파일을 건드리지 않는다"
t12() {
  #       대조를 아예 안 하는 구현을 걸러낸다
  T=$(fresh); cd "$T"
  jq '(.files[] | select(.dest==".claude/scripts/hooks/pre-commit.py") | .sourceHash) = "sha256:0000"' \
     .harness/manifest.json > t.json && mv t.json .harness/manifest.json
  BEFORE=$(tree_hash .claude)
  rejected gridfin deploy --from "$V2"
  test "$(tree_hash .claude)" = "$BEFORE"
}

t13_desc="matcher가 없는 사건도 병합된다 — 이 계약을 때리는 시험이 따로 있어야 한다"
t13() {
  #       식별자를 /matcher 하나로 고정한 구현은 여기서만 걸린다
  T=$(fresh); cd "$T"
  jq '.hooks.SessionStart += [{"hooks":[{"type":"command","command":"${CLAUDE_PROJECT_DIR}/.claude/scripts/hooks/my-own.py"}]}]' \
     .claude/settings.json > t.json && mv t.json .claude/settings.json
  gridfin deploy --from "$V2"
  jq -e '[.hooks.SessionStart[].hooks[0].command] | index("${CLAUDE_PROJECT_DIR}/.claude/scripts/hooks/my-own.py")' .claude/settings.json
  jq -e '[.hooks.SessionStart[].hooks[0].command] | map(select(test("session-start-v2"))) | length == 1' \
     .claude/settings.json                                   # 하네스 갱신이 반영된다
  jq -e '[.hooks.SessionStart[].hooks[0].command] | map(select(test("session-start.py"))) | length == 0' \
     .claude/settings.json                                   # 옛 원소가 남지 않는다
}

t14_desc="사용자가 안 건드린 파일은 새 버전으로 갱신된다 — ours==base면 theirs를 따른다"
t14() {
  T=$(fresh); cd "$T"
  gridfin deploy --from "$V2"
  git -C "$V2" show HEAD:payload/claude/scripts/hooks/pre-commit.py > want.py
  diff want.py .claude/scripts/hooks/pre-commit.py
}

t15_desc="JSON도 양쪽이 같은 자리를 다르게 고치면 충돌이다"
t15() {
  T=$(fresh); cd "$T"
  #      값 자리에서 충돌을 만든다. 원시 배열은 원소가 곧 식별자라 충돌이 생기지 않는다
  jq '.statusLine.command = "${CLAUDE_PROJECT_DIR}/.claude/scripts/hooks/my-status.py"' \
     .claude/settings.json > t.json && mv t.json .claude/settings.json
  BEFORE=$(tree_hash .claude); E=$(entry .harness/manifest.json .claude/settings.json)
  partial  gridfin deploy --from "$CONFJ"
  test "$(tree_hash .claude)" = "$BEFORE"
  test -f .claude/settings.json.merged
  test "$(entry .harness/manifest.json .claude/settings.json)" = "$E"   # 건너뛴 파일의 항목은 그대로다
}

t16_desc="대상 JSON이 무효면 건드리지 않는다"
t16() {
  T=$(fresh); cd "$T"
  printf '{ 깨진 JSON' > .claude/settings.json
  BEFORE=$(shasum -a 256 .claude/settings.json | cut -d' ' -f1)
  partial  gridfin deploy --from "$V2"
  test "$(shasum -a 256 .claude/settings.json | cut -d' ' -f1)" = "$BEFORE"
}

t17_desc="exclude 블록에는 주입한 것만 들어간다"
t17() {
  T=$(mktemp -d); cd "$T" && git init -q
  mkdir -p .claude && echo x > .claude/tracked.txt && git add -A && git commit -qm init
  gridfin deploy --from "$V1"
  grep -q '^\.harness/$' .git/info/exclude
  ! grep -q '^\.claude/$' .git/info/exclude          # 이미 추적 중이므로 넣지 않는다
}

t18_desc="pointer 부재와 JSON null을 구별한다"
t18() {
  T=$(fresh); cd "$T"
  #      command를 같게 두고 matcher만 null과 부재로 가른다. 그래야 구별을 실제로 때린다
  jq '.hooks.SessionStart += [{"matcher":null,"hooks":[{"type":"command","command":"${CLAUDE_PROJECT_DIR}/.claude/scripts/hooks/same.py"}]},
                              {"hooks":[{"type":"command","command":"${CLAUDE_PROJECT_DIR}/.claude/scripts/hooks/same.py"}]}]' \
     .claude/settings.json > t.json && mv t.json .claude/settings.json
  gridfin deploy --from "$V2"
  jq -e '[.hooks.SessionStart[] | select(.hooks[0].command == "${CLAUDE_PROJECT_DIR}/.claude/scripts/hooks/same.py")] | length == 2' \
     .claude/settings.json
  #      null과 부재를 같게 다루면 두 원소가 같은 식별자가 되어 유일성 위반으로 거부되거나 하나로 합쳐진다
}

t19_desc="매니페스트가 스키마를 지킨다 — 필수 필드가 빠져도 통과하면 안 된다"
t19() {
  T=$(fresh); cd "$T"
  jq -e 'has("attemptedSha") and has("deployedAt") and (.source|has("path")) and (.source|has("remote"))' \
     .harness/manifest.json
  jq -e '.files | all(has("src") and has("dest") and has("merge")
                      and has("sourceSha") and has("sourceHash") and has("installedHash"))' \
     .harness/manifest.json
  jq -e '.files | all(.merge == "text" or .merge == "json")' .harness/manifest.json
  jq -e '.files[] | select(.merge=="json") | .owned
         | all(has("pointer") and has("key")
               and (.key == null or ((.key|type) == "array" and (.key|all(startswith("/"))))))' \
     .harness/manifest.json
}

t20_desc="병합 뒤에는 installedHash가 sourceHash와 달라진다"
t20() {
  #       둘을 같게 기록하는 구현이 여기서 걸린다
  T=$(fresh); cd "$T"
  awk 'NR==2{print "// 사용자 줄"}1' .claude/scripts/hooks/pre-commit.py > t.py
  cat t.py > .claude/scripts/hooks/pre-commit.py && rm t.py   # mv 는 모드를 떨어뜨린다
  gridfin deploy --from "$V2"
  jq -e '.files[] | select(.dest==".claude/scripts/hooks/pre-commit.py")
         | .installedHash != .sourceHash' .harness/manifest.json
}

t21_desc="삭제된 배포물은 매니페스트 files에서도 빠진다"
t21() {
  T=$(fresh); cd "$T"
  gridfin deploy --from "$RM"
  jq -e '[.files[].dest] | index(".claude/scripts/hooks/format.py") == null' .harness/manifest.json
}

t22_desc="멱등성 — 같은 하네스로 세 번 배포해도 아무것도 안 바뀐다"
t22() {
  T=$(fresh); cd "$T"
  #      내용 비교만 하면 안 된다. deployedAt 이 초 단위라 빠른 재배포는
  #      우연히 같은 값이 나와 「다시 쓰는 구현」이 통과해 버린다(실측).
  #      mtime 은 「안 썼다」와 「같은 내용을 다시 썼다」를 가른다
  BEFORE="$(tree_hash .claude)$(shasum -a 256 .harness/manifest.json | cut -d' ' -f1)"
  #      mtime 도 초 단위라 같은 초에 묻힌다. 옛 시각으로 돌려놓고 그대로인지 본다 —
  #      시계 해상도에 기대지 않는다
  touch -t 200001010000 .harness/manifest.json
  gridfin deploy --from "$V1"
  gridfin deploy --from "$V1"
  test "$(tree_hash .claude)$(shasum -a 256 .harness/manifest.json | cut -d' ' -f1)" = "$BEFORE"
  test "$(date -r .harness/manifest.json +%Y)" = "2000"   # 다시 쓰지 않았다
}

t23_desc="연쇄 갱신 — V1 → V2 → V3에서 base가 매번 올바른 리비전에서 나온다"
t23() {
  T=$(fresh); cd "$T"
  awk 'NR==2{print "// 사용자 줄"}1' .claude/scripts/hooks/pre-commit.py > t.py
  cat t.py > .claude/scripts/hooks/pre-commit.py && rm t.py   # mv 는 모드를 떨어뜨린다
  gridfin deploy --from "$V2"
  gridfin deploy --from "$V3"
  grep -q '사용자 줄' .claude/scripts/hooks/pre-commit.py       # 두 번을 지나도 살아남는다
  git -C "$V3" show HEAD:payload/claude/scripts/hooks/pre-commit.py |
    awk 'NR==2{print "// 사용자 줄"}1' > want.py
  diff want.py .claude/scripts/hooks/pre-commit.py
}

t24_desc="되돌림 — V2 배포 뒤 V1로 다시 배포해도 사용자 수정이 산다"
t24() {
  #       V1과 V2가 같은 저장소의 두 리비전인 경우다
  T=$(fresh); cd "$T"
  awk 'NR==2{print "// 사용자 줄"}1' .claude/scripts/hooks/pre-commit.py > t.py
  cat t.py > .claude/scripts/hooks/pre-commit.py && rm t.py   # mv 는 모드를 떨어뜨린다
  gridfin deploy --from "$V2"
  gridfin deploy --from "$V1"                                    # 리비전이 뒤로 간다
  grep -q '사용자 줄' .claude/scripts/hooks/pre-commit.py
  git -C "$V1" show HEAD:payload/claude/scripts/hooks/pre-commit.py |
    awk 'NR==2{print "// 사용자 줄"}1' > want.py
  diff want.py .claude/scripts/hooks/pre-commit.py
}

t25_desc="삭제 뒤 부활 — RM으로 지운 파일이 V1 재배포로 돌아온다"
t25() {
  T=$(fresh); cd "$T"
  gridfin deploy --from "$RM"
  test ! -f .claude/scripts/hooks/format.py
  gridfin deploy --from "$V1"
  test -f .claude/scripts/hooks/format.py
  jq -e '[.files[].dest] | index(".claude/scripts/hooks/format.py")' .harness/manifest.json
}

t26_desc="충돌 보고물은 다음 성공 배포가 치운다"
t26() {
  T=$(fresh); cd "$T"
  #      mv 로 갈아치우면 모드가 떨어진다. 되쓰기로 실행 비트를 유지한다
  awk 'NR==1{print "// 사용자가 고친 첫 줄"; next}1' .claude/scripts/hooks/pre-commit.py > t.py
  cat t.py > .claude/scripts/hooks/pre-commit.py && rm t.py
  partial  gridfin deploy --from "$CONF"
  test -f .claude/scripts/hooks/pre-commit.py.merged
  git -C "$CONF" show HEAD:payload/claude/scripts/hooks/pre-commit.py > .claude/scripts/hooks/pre-commit.py
  gridfin deploy --from "$CONF"                                  # 사용자가 해결했으므로 성공한다
  test ! -e .claude/scripts/hooks/pre-commit.py.merged
}

t27_desc="dirty는 payload 안만 본다 — 세 종류를 각각 만든다"
t27() {
  T=$(fresh); cd "$T"
  echo x > "$V2/docs/dirty.md"                                   # payload 밖은 막지 않는다
  gridfin deploy --from "$V2"
  rm "$V2/docs/dirty.md"
  for kind in untracked staged modified; do
    T=$(fresh); cd "$T"
    case $kind in
      untracked) touch "$V2/payload/new.tmp" ;;
      staged)    touch "$V2/payload/new.tmp" && git -C "$V2" add payload/new.tmp ;;
      modified)  echo "// 고침" >> "$V2/payload/claude/scripts/hooks/format.py" ;;
    esac
    BEFORE="$(tree_hash .claude)$(tree_hash .harness)"
    rejected gridfin deploy --from "$V2"        # dirty를 만든 저장소와 배포 저장소가 같아야 한다
    test "$(tree_hash .claude)$(tree_hash .harness)" = "$BEFORE"
    git -C "$V2" reset -q; git -C "$V2" checkout -q -- payload; rm -f "$V2/payload/new.tmp"
  done
}

t28_desc="워크트리에 배포된다 — .git이 파일인 곳에서도 성립한다"
t28() {
  T=$(fresh); cd "$T"
  git worktree add -q ../wt -b wt && cd ../wt
  gridfin deploy --from "$V1"
  test -f .claude/settings.json
  test -f .harness/manifest.json
  #      무시 목록이 실제로 걸렸는지 본다. 워크트리 전용 exclude는 git이 읽지 않으므로
  #      경로를 잘못 풀면 여기서 걸린다
  test -z "$(git status --porcelain -- .claude .harness)"
  grep -q '^\.harness/$' "$(git rev-parse --git-common-dir)/info/exclude"
}

t29_desc="dest가 심볼릭 링크면 건너뛰고 링크 바깥을 안 고친다"
t29() {
  T=$(fresh); cd "$T"
  OUT=$(mktemp -d); cp .claude/scripts/hooks/pre-commit.py "$OUT/real.py"
  BEFORE=$(shasum -a 256 "$OUT/real.py" | cut -d' ' -f1)
  ln -sf "$OUT/real.py" .claude/scripts/hooks/pre-commit.py
  partial  gridfin deploy --from "$V2"          # 심볼릭 링크는 파일별 건너뛰기다
  test "$(shasum -a 256 "$OUT/real.py" | cut -d' ' -f1)" = "$BEFORE"
  test -L .claude/scripts/hooks/pre-commit.py
}

t30_desc="실행 비트가 보존된다 — 배포 직후와 병합 뒤 둘 다"
t30() {
  T=$(fresh); cd "$T"
  test -x .claude/scripts/hooks/pre-commit.py
  awk 'NR==2{print "// 사용자 줄"}1' .claude/scripts/hooks/pre-commit.py > t.py
  cat t.py > .claude/scripts/hooks/pre-commit.py && rm t.py
  gridfin deploy --from "$V2"
  test -x .claude/scripts/hooks/pre-commit.py
}

t31_desc="잠금 — 같은 대상에 둘이 동시에 배포하면 하나만 성공한다"
t31() {
  T=$(fresh); cd "$T"
  #      잠금을 잡은 채로 두면 「시작할 때만 보고 유지하지 않는」 구현이 통과한다.
  #      실제로 둘을 겹쳐 돌려 하나만 성공하는지 본다
  gridfin deploy --from "$V2" & P1=$!
  gridfin deploy --from "$V3" & P2=$!
  #      set -e 아래에서 wait 가 비0을 내면 그 줄에서 죽는다. 판정까지 못 간다(실측)
  R1=0; wait "$P1" || R1=$?
  R2=0; wait "$P2" || R2=$?
  test $(( (R1==0) + (R2==0) )) -eq 1                            # 하나만 성공한다
  test $(( (R1==2) + (R2==2) )) -eq 1                            # 나머지는 잠금 실패로 거부된다
}

t32_desc="공백과 유니코드가 든 파일 이름을 견딘다"
t32() {
  #       V1에 payload/claude/scripts/hooks/이름 있는 훅.py 를 넣은 하네스로 배포한다
  T=$(mktemp -d); cd "$T" && git init -q
  gridfin deploy --from "$V_SPACE"
  test -f ".claude/scripts/hooks/이름 있는 훅.py"
  jq -e '[.files[].dest] | index(".claude/scripts/hooks/이름 있는 훅.py")' .harness/manifest.json
}

t33_desc="--json이 무엇이 되고 무엇이 안 됐는지 답한다"
t33() {
  T=$(fresh); cd "$T"
  #      mv 로 갈아치우면 모드가 떨어진다. 되쓰기로 실행 비트를 유지한다
  awk 'NR==1{print "// 사용자가 고친 첫 줄"; next}1' .claude/scripts/hooks/pre-commit.py > t.py
  cat t.py > .claude/scripts/hooks/pre-commit.py && rm t.py
  partial gridfin deploy --from "$CONF" --json > out.json
  jq -e '.outcome == "partial"' out.json
  jq -e '.files[] | select(.dest==".claude/scripts/hooks/pre-commit.py") | .status == "conflict"' out.json
  jq -e '.files[] | select(.dest==".claude/settings.json") | .status | IN("updated","unchanged")' out.json
}

t34_desc="전체 거부는 reason을 담는다"
t34() {
  T=$(fresh); cd "$T"
  touch "$V2/payload/dirty.tmp"
  rejected gridfin deploy --from "$V2" --json > out.json
  jq -e '.outcome == "rejected" and .reason == "harness_dirty"' out.json
  jq -e '.files | length == 0' out.json
  rm "$V2/payload/dirty.tmp"
}

t35_desc="payload/root/ 에 파일을 넣으면 스크립트를 안 고쳐도 배포된다"
t35() {
  #       payload/claude 만 하드코딩한 구현이 여기서 걸린다. #3이 이 경로에 의존한다
  T=$(mktemp -d); cd "$T" && git init -q
  gridfin deploy --from "$V_ROOT"                # V_ROOT = V1 + payload/root/gridfin.json
  test -f gridfin.json
  jq -e '[.files[].dest] | index("gridfin.json")' .harness/manifest.json
}

t36_desc="삭제 판정은 installedHash로 한다 — 병합으로 설치본이 달라진 파일도 지운다"
t36() {
  #      format.py 는 한 번도 병합되지 않아 installedHash 와 sourceHash 가 같다.
  #      그래서 두 필드를 바꿔 써도 8·21·25가 전부 통과한다(변이로 실측).
  #      먼저 병합을 일으켜 두 값을 갈라 놓고 나서 지운다
  T=$(fresh); cd "$T"
  echo "// 내가 고쳤다" >> .claude/scripts/hooks/format.py
  gridfin deploy --from "$V2"                    # V2 는 format.py 를 안 건드린다 — ours 가 산다
  jq -e '.files[] | select(.dest==".claude/scripts/hooks/format.py")
         | .installedHash != .sourceHash' .harness/manifest.json
  gridfin deploy --from "$RM"                    # 설치 이후로는 안 건드렸으므로 지운다
  test ! -f .claude/scripts/hooks/format.py
}

t37_desc="이미 없는 삭제 대상은 매니페스트에서만 빼고 성공으로 끝낸다"
t37() {
  T=$(fresh); cd "$T"
  rm .claude/scripts/hooks/format.py             # 사용자가 먼저 지웠다
  gridfin deploy --from "$RM"                    # 할 일이 없다. 부분 실패가 아니다
  jq -e '[.files[].dest] | index(".claude/scripts/hooks/format.py") == null' .harness/manifest.json
}

t38_desc="삭제 경로에 심볼릭 링크가 있으면 저장소 밖을 안 지운다"
t38() {
  #      29번은 쓰기만 본다. 지우기는 되돌릴 수 없어 따로 봐야 한다 —
  #      링크 방어를 빼도 29번은 통과했다(변이로 실측)
  T=$(fresh); cd "$T"
  OUT=$(mktemp -d); cp .claude/scripts/hooks/*.py "$OUT/"
  rm -rf .claude/scripts/hooks
  ln -s "$OUT" .claude/scripts/hooks
  partial  gridfin deploy --from "$RM"
  test -f "$OUT/format.py"                       # 저장소 밖 파일이 살아 있다

  #      대상 안을 가리키는 링크도 안 지운다. 바깥 링크는 경로를 풀어 보는 검사가
  #      이미 막지만, 안쪽 링크는 링크 검사만 막는다(변이로 실측). 링크는 사용자 것이다
  T=$(fresh); cd "$T"
  cp .claude/scripts/hooks/format.py .claude/scripts/hooks/keep.py
  rm .claude/scripts/hooks/format.py
  ln -s keep.py .claude/scripts/hooks/format.py
  partial  gridfin deploy --from "$RM"
  test -L .claude/scripts/hooks/format.py
}

t39_desc="매니페스트의 dest가 대상 밖을 가리키면 지우지 않는다"
t39() {
  #      배포 경로의 dest 는 git ls-tree 가 만들지만 삭제 경로는 매니페스트에서
  #      곧장 받는다. ../ 와 절대 경로가 실제로 저장소 밖을 지웠다(실측)
  T=$(fresh); cd "$T"
  echo 지우면 안 되는 파일 > "$T/../victim.txt"
  H="sha256:$(shasum -a 256 "$T/../victim.txt" | cut -d' ' -f1)"
  jq --arg h "$H" '.files += [{src:"payload/claude/x", dest:"../victim.txt", merge:"text",
       sourceSha:.attemptedSha, sourceHash:$h, installedHash:$h}]' .harness/manifest.json > t.json
  cat t.json > .harness/manifest.json && rm t.json
  partial  gridfin deploy --from "$V1"
  test -f "$T/../victim.txt"
  rm "$T/../victim.txt"
}

t40_desc="부분 실패가 남은 대상도 다시 배포하면 매니페스트를 다시 쓰지 않는다"
t40() {
  #      22번은 성공 경로만 본다. 충돌이나 delete_pending 이 남으면 배포할 때마다
  #      부분 실패로 끝나는데, 그때마다 다시 쓰면 「여러 번 배포해도 아무것도 안
  #      바뀐다」가 부분 실패 경로에서만 깨진다(교차 검토 실측)
  T=$(fresh); cd "$T"
  echo "// 내가 고쳤다" >> .claude/scripts/hooks/format.py
  partial  gridfin deploy --from "$RM"
  BEFORE=$(shasum -a 256 .harness/manifest.json | cut -d' ' -f1)
  touch -t 200001010000 .harness/manifest.json
  partial  gridfin deploy --from "$RM"
  test "$(shasum -a 256 .harness/manifest.json | cut -d' ' -f1)" = "$BEFORE"
  test "$(date -r .harness/manifest.json +%Y)" = "2000"   # 다시 쓰지 않았다

  #      충돌이 남은 경우도 같다. 지우다 만 것과 병합하다 만 것은 다른 경로다
  T=$(fresh); cd "$T"
  awk 'NR==1{print "// 사용자가 고친 첫 줄"; next}1' .claude/scripts/hooks/pre-commit.py > t.py
  cat t.py > .claude/scripts/hooks/pre-commit.py && rm t.py
  partial  gridfin deploy --from "$CONF"
  touch -t 200001010000 .harness/manifest.json
  partial  gridfin deploy --from "$CONF"
  test "$(date -r .harness/manifest.json +%Y)" = "2000"
}

# ── 실행기 ────────────────────────────────────────────────
# 시험마다 함수로 나눈 이유가 있다. set -e 가 걸린 한 덩어리로 두면 첫 실패에서
# 멈춰 어느 시험이 통과했는지 알 수 없다. 단계적 구현에서는 대부분의 시험이
# 설계상 실패하므로 그 형태로는 진행 상황을 잴 수 없다.
#
#   bash tests/verify-deploy.sh          전부
#   bash tests/verify-deploy.sh 1 2 19   고른 것만

ALL="1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 29 30 31 32 33 34 35 36 37 38 39 40"

restore_fixtures() {
  # 앞 시험이 fixture 를 더럽힌 채 실패해도 다음 시험이 영향받지 않게 되돌린다.
  # 한 덩어리로 돌 때는 첫 실패에서 멈춰 이 문제가 없었다.
  for r in "$V1" "$V2" "$V3" "$RM" "$CONF" "$CONFJ" "$V_SPACE" "$V_ROOT"; do
    git -C "$r" reset -q --hard >/dev/null 2>&1 || true
    git -C "$r" clean -qfd      >/dev/null 2>&1 || true
  done
}

pass=0; fail=0
for n in ${*:-$ALL}; do
  desc=$(eval "printf '%s' \"\${t${n}_desc:-}\"")
  if [ -z "$desc" ]; then printf '  ???  %-3s 그런 시험이 없다\n' "$n"; fail=$((fail+1)); continue; fi
  log="$GRIDFIN_RUN/t$n.log"
  # if ( set -e; ... ) 로 감싸면 안 된다. 조건 자리의 명령에는 errexit 가 걸리지
  # 않고 그것이 함수 안까지 퍼져, 시험이 끝까지 돌고 마지막 명령의 결과만으로
  # 판정된다(실측). 따로 돌리고 종료 코드를 받는다.
  ( set -e; "t$n" ) >"$log" 2>&1
  rc=$?
  if [ "$rc" -eq 0 ]; then
    printf '  PASS %-3s %s\n' "$n" "$desc"; pass=$((pass+1))
  else
    printf '  FAIL %-3s %s\n' "$n" "$desc"; fail=$((fail+1))
    tail -3 "$log" | sed 's/^/         /'
  fi
  restore_fixtures
done
printf '\n  통과 %s · 실패 %s\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
