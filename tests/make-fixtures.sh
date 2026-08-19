#!/usr/bin/env bash
# 검증에 쓸 하네스 저장소 8개를 만들고 경로를 export 문으로 내보낸다.
#
#   eval "$(bash tests/make-fixtures.sh)"
#
# 8개를 한 저장소의 워크트리로 만드는 이유가 있다. 스펙 §3.4가 「릴리스
# 저장소들은 같은 객체 이력을 공유해야 한다」고 요구한다. 따로 만든 저장소는
# 서로의 리비전을 못 꺼내므로 되돌림 시험과 연쇄 갱신 시험이 성립하지 않는다.
# 워크트리는 객체 저장소를 공유한다.
#
# 이 스크립트는 표준 출력에 export 문만 낸다. 그 밖의 말은 표준 오류로 낸다.
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
BASE=$(mktemp -d)
HARNESS="$BASE/harness"

say() { printf '%s\n' "$*" >&2; }

# ── V1 — payload 자리표시본 그대로
git -c init.defaultBranch=main init -q "$HARNESS"
git -C "$HARNESS" config user.email fixture@gridfin
git -C "$HARNESS" config user.name  gridfin-fixture
cp -R "$ROOT/payload" "$HARNESS/payload"
mkdir -p "$HARNESS/docs" && printf 'fixture\n' > "$HARNESS/docs/README.md"
git -C "$HARNESS" add -A
git -C "$HARNESS" commit -qm "v1"

# ── 변형마다 워크트리를 하나씩 판다
branch() {  # $1=이름 $2=시작 브랜치
  local d="$BASE/$1"
  git -C "$HARNESS" worktree add -q -b "$1" "$d" "$2"
  printf '%s' "$d"
}
save() { git -C "$1" add -A; git -C "$1" commit -qm "$2"; }

# V2 — allow 추가·삭제 / PreToolUse에 matcher 하나 추가
#      SessionStart의 command 변경 / pre-commit.js 끝에 한 줄
V2=$(branch v2 main)
jq '.permissions.allow = (.permissions.allow - ["Bash(gh:*)"] + ["Bash(rg:*)"])
    | .hooks.PreToolUse += [{"matcher":"Edit",
        "hooks":[{"type":"command","command":"node \"${CLAUDE_PROJECT_DIR}/.claude/scripts/hooks/format.js\""}]}]
    | .hooks.SessionStart[0].hooks[0].command =
        "node \"${CLAUDE_PROJECT_DIR}/.claude/scripts/hooks/session-start-v2.js\""' \
   "$V2/payload/claude/settings.json" > "$V2/t.json"
mv "$V2/t.json" "$V2/payload/claude/settings.json"
printf '// v2가 끝에 더한 줄\n' >> "$V2/payload/claude/scripts/hooks/pre-commit.js"
save "$V2" "v2"

# V3 — v2에서 pre-commit.js 끝에 또 한 줄
V3=$(branch v3 v2)
printf '// v3가 끝에 더한 줄\n' >> "$V3/payload/claude/scripts/hooks/pre-commit.js"
save "$V3" "v3"

# RM — v1에서 format.js 를 뺀다
RM=$(branch rm main)
rm "$RM/payload/claude/scripts/hooks/format.js"
save "$RM" "rm"

# CONF — v1에서 pre-commit.js 의 첫 줄을 고친다 (텍스트 충돌용)
CONF=$(branch conf main)
awk 'NR==1{print "// 하네스가 고친 첫 줄"; next}1' \
  "$CONF/payload/claude/scripts/hooks/pre-commit.js" > "$CONF/t.js"
mv "$CONF/t.js" "$CONF/payload/claude/scripts/hooks/pre-commit.js"
save "$CONF" "conf"

# CONFJ — v1에서 statusLine.command 를 바꾼다 (값 자리 충돌용)
CONFJ=$(branch confj main)
jq '.statusLine.command = "node \"${CLAUDE_PROJECT_DIR}/.claude/scripts/hooks/status-harness.js\""' \
   "$CONFJ/payload/claude/settings.json" > "$CONFJ/t.json"
mv "$CONFJ/t.json" "$CONFJ/payload/claude/settings.json"
save "$CONFJ" "confj"

# V_SPACE — 공백과 유니코드가 든 파일 이름
V_SPACE=$(branch v-space main)
printf '// #2가 채운다 — 지금은 자리표시본\n// hook: 이름 있는 훅\nprocess.exit(0);\n' \
  > "$V_SPACE/payload/claude/scripts/hooks/이름 있는 훅.js"
chmod +x "$V_SPACE/payload/claude/scripts/hooks/이름 있는 훅.js"
save "$V_SPACE" "v-space"

# V_ROOT — payload/root/ 에 파일이 생긴 경우
V_ROOT=$(branch v-root main)
mkdir -p "$V_ROOT/payload/root"
printf '{ "python": {}, "typescript": {} }\n' > "$V_ROOT/payload/root/gridfin.json"
save "$V_ROOT" "v-root"

say "fixture 8개를 만들었다: $BASE"
cat <<EOF
export FIXTURE_BASE='$BASE'
export V1='$HARNESS'
export V2='$V2'
export V3='$V3'
export RM='$RM'
export CONF='$CONF'
export CONFJ='$CONFJ'
export V_SPACE='$V_SPACE'
export V_ROOT='$V_ROOT'
EOF
