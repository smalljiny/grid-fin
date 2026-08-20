#!/usr/bin/env bash
# 이슈 #2 워크트리 주입 스크립트 — 단위 조건
#
# 스펙: docs/work/2-hook-scripts/spec.md §3.7 · §6.6
#
#   bash tests/verify-inject.sh          전부
#   bash tests/verify-inject.sh 29 33    고른 것만 (번호는 검증 조건 번호다)

set -uo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

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

# 배포가 끝난 메인 저장소를 만든다
main_repo() {
  d=$(mk)
  if ! ( cd "$d" && git -c init.defaultBranch=main init -q . &&
         git config user.email a@b && git config user.name a &&
         printf 'x\n' > f.txt && git add -A && git commit -qm init &&
         "$ROOT/bin/gridfin" deploy --from "$(fixture_harness)" >/dev/null ); then
    rm -rf "$d"; return 1
  fi
  printf '%s' "$d"
}

# 워크트리를 하나 판다. **부를 때마다 다른 이름을 쓴다** — 같은 지점을 가리키면
# 옛 워크트리를 재사용하며 깨는 변이가 통과한다(이슈 #1 실측).
#
# **셈수를 쓰면 안 된다.** 시험마다 부속 셸에서 실행되므로 셈수가 매번 0으로
# 되돌아가 경로가 겹친다. 실제로 겹쳐서 따로 돌리면 통과하는 시험이 함께
# 돌리면 실패했다(1차 실측 2026-08-20). mktemp 로 뽑는다.
worktree_of() {  # $1=메인 저장소
  parent=$(mk)
  w="$parent/wt"
  git -C "$1" worktree add -q -b "b$(basename "$parent")" "$w" >/dev/null 2>&1 || return 1
  printf '%s' "$w"
}

inject() { "$ROOT/bin/gridfin-inject" "$@"; }
rejected() { if "$@" >/dev/null 2>&1; then return 1; else test $? -eq 2; fi; }
partial()  { if "$@" >/dev/null 2>&1; then return 1; else test $? -eq 1; fi; }
tree_sum() { find "$@" -type f -print0 2>/dev/null | sort -z | xargs -0 shasum -a 256 | shasum -a 256; }

# ── 6.6 워크트리 주입 ──────────────────────────────────────

c29_desc="C29 매니페스트의 항목과 매니페스트 자신이 워크트리에 들어간다"
c29() {
  M=$(main_repo); W=$(worktree_of "$M")
  inject "$W" > /dev/null
  #      매니페스트가 먼저다. 없으면 워크트리의 훅이 기대 목록을 못 만든다
  test -f "$W/.harness/manifest.json"
  #      files 의 항목이 전부 들어간다
  while IFS= read -r d; do
    test -f "$W/$d" || { printf '없다: %s\n' "$d"; return 1; }
  done < <(jq -r '.files[].dest' "$M/.harness/manifest.json")
  #      실행 비트가 보존된다. 없으면 셔뱅이 뜻이 없다
  test -x "$W/.claude/scripts/hooks/session-start.py"
  #      내용이 같다
  diff -r "$M/.claude" "$W/.claude"
}

c30_desc="C30 주입한 항목이 워크트리의 git status 에 뜨지 않는다"
c30() {
  M=$(main_repo); W=$(worktree_of "$M")
  inject "$W" > /dev/null
  test -z "$(git -C "$W" status --porcelain)"
  #      살아 있음 검사. 무시를 걷으면 뜨는지 본다 —
  #      없으면 「무시되고 있다」와 「넣지 않았다」가 같은 값이다
  common=$(git -C "$W" rev-parse --git-common-dir)
  : > "$common/info/exclude"
  test -n "$(git -C "$W" status --porcelain)"
}

c31_desc="C31 무시는 배포가 심은 블록이 하고 패턴이 루트 기준으로 고정된다"
c31() {
  M=$(main_repo); W=$(worktree_of "$M")
  common=$(git -C "$W" rev-parse --git-common-dir)
  before=$(shasum -a 256 < "$common/info/exclude")
  inject "$W" > /dev/null
  #      주입이 무시 목록을 쓰지 않는다. 쓰는 주체를 둘로 만들지 않는다
  test "$(shasum -a 256 < "$common/info/exclude")" = "$before"
  #      패턴이 루트 기준으로 고정된다 — 하위의 같은 이름은 안 숨긴다
  mkdir -p "$W/sub/.claude"; printf 'x\n' > "$W/sub/.claude/keep.txt"
  git -C "$W" status --porcelain --untracked-files=all | grep -q 'sub/.claude/keep.txt'
}

c32_desc="C32 이미 추적되는 항목은 건너뛰고 내용이 바뀌지 않는다"
c32() {
  M=$(main_repo)
  #      메인에서 배포물 하나를 추적 상태로 만든다
  ( cd "$M" && git add -f .claude/settings.json && git commit -qm "설정을 추적한다" )
  W=$(worktree_of "$M")
  printf '{"사용자":"고친 것"}\n' > "$W/.claude/settings.json"
  before=$(shasum -a 256 < "$W/.claude/settings.json")
  #      추적되는 항목이 수정 상태여도 완전 성공이다.
  #      status 를 파싱하면 이 줄의 경로가 두 글자 밀려 엉뚱한 판정이 나온다
  inject "$W" > /dev/null
  #      이름이 바뀐 파일이 있어도 마찬가지다 — R  옛것 -> 새것 형태다
  ( cd "$W" && git mv f.txt g.txt )
  inject "$W" > /dev/null
  #      추적되는 파일은 건드리지 않는다. 덮으면 사용자의 커밋된 파일이 바뀐다
  test "$(shasum -a 256 < "$W/.claude/settings.json")" = "$before"
  #      나머지는 들어간다
  test -f "$W/.claude/scripts/hooks/session-start.py"
}

c33_desc="C33 워크트리의 .git 이 파일인 상태에서 동작한다"
c33() {
  M=$(main_repo); W=$(worktree_of "$M")
  #      전제를 시험이 직접 확인한다. 디렉터리면 이 조건이 아무것도 재지 않는다
  test -f "$W/.git"; test ! -d "$W/.git"
  inject "$W" > /dev/null
  test -f "$W/.claude/scripts/gridfin/gate.py"
}

c34_desc="C34 디렉터리 심볼릭 링크를 만들지 않는다"
c34() {
  M=$(main_repo); W=$(worktree_of "$M")
  inject "$W" > /dev/null
  #      넣은 것 중 어느 것도 링크가 아니다. 디렉터리든 파일이든 실물이어야 한다.
  #      워크트리의 .claude 가 메인을 가리키면 워크트리에서 고친 것이 메인의
  #      훅을 바꾼다 — 그것이 관측된 사고다
  for d in .claude .claude/scripts .claude/scripts/hooks .claude/scripts/gridfin .harness; do
    test ! -L "$W/$d"
  done
  while IFS= read -r f; do
    test ! -L "$W/$f" || { printf '링크다: %s\n' "$f"; return 1; }
  done < <(jq -r '.files[].dest' "$M/.harness/manifest.json")
  #      실물이라 워크트리에서 고쳐도 메인이 안 바뀐다
  before=$(shasum -a 256 < "$M/.claude/scripts/hooks/session-start.py")
  printf '# 워크트리에서 고친 줄\n' >> "$W/.claude/scripts/hooks/session-start.py"
  test "$(shasum -a 256 < "$M/.claude/scripts/hooks/session-start.py")" = "$before"
}

c38_desc="C38 주입 뒤 워크트리에서 pre-write.py 를 부르면 등록 확인이 통과한다"
c38() {
  M=$(main_repo); W=$(worktree_of "$M")
  inject "$W" > /dev/null
  in="$GRIDFIN_RUN/pw.json"
  printf '{"cwd":"%s","hook_event_name":"PreToolUse","tool_input":{"file_path":"%s/ok.txt","content":"x"}}' "$W" "$W" > "$in"
  rc=0
  ( cd "$W" && CLAUDE_PROJECT_DIR="$W" "$W/.claude/scripts/hooks/pre-write.py" ) < "$in" >/dev/null 2>&1 || rc=$?
  test "$rc" = 0
  #      살아 있음 검사. 훅 하나를 지우면 막힌다
  rm "$W/.claude/scripts/hooks/format.py"
  rc=0
  ( cd "$W" && CLAUDE_PROJECT_DIR="$W" "$W/.claude/scripts/hooks/pre-write.py" ) < "$in" >/dev/null 2>&1 || rc=$?
  test "$rc" = 2
}

c35_desc="C35 워크트리가 아니거나 매니페스트가 없으면 아무것도 쓰지 않고 거부한다"
c35() {
  M=$(main_repo)
  #      메인 저장소를 주면 거부한다. --git-dir 와 --git-common-dir 가 같다
  rejected inject "$M"
  #      메인의 하위 디렉터리도 거부한다. test -d .git 으로 판정하면
  #      거기엔 .git 이 없어 워크트리로 오인한다
  mkdir -p "$M/sub"
  rejected inject "$M/sub"
  test ! -d "$M/sub/.claude"
  #      git 저장소가 아니면 거부한다
  D=$(mk); rejected inject "$D"; test -z "$(ls -A "$D")"
  #      매니페스트가 없으면 거부하고 아무것도 안 쓴다
  M2=$(main_repo); W=$(worktree_of "$M2"); rm "$M2/.harness/manifest.json"
  rejected inject "$W"
  test ! -d "$W/.claude"
  #      인자가 없으면 거부한다
  rejected inject

  #      매니페스트의 dest 가 저장소 밖을 가리키면 거부하고 아무것도 안 쓴다.
  #      이슈 #1 이 삭제 경로에서 실제로 겪은 종류다 — 배포 경로는 git ls-tree 가
  #      만들어 밖을 못 가리키지만 주입은 매니페스트에서 곧장 받는다
  M3=$(main_repo); W3=$(worktree_of "$M3"); O=$(mk)
  jq --arg d "../$(basename "$O")/victim.txt" \
     '.files += [{"dest":$d}]' "$M3/.harness/manifest.json" > "$M3/t.json"
  mv "$M3/t.json" "$M3/.harness/manifest.json"
  rejected inject "$W3"
  test ! -d "$W3/.claude"
  test -z "$(ls -A "$O")"
  #      절대 경로도 같다
  M4=$(main_repo); W4=$(worktree_of "$M4")
  jq --arg d "/tmp/gridfin-victim.txt" '.files += [{"dest":$d}]' \
     "$M4/.harness/manifest.json" > "$M4/t.json"
  mv "$M4/t.json" "$M4/.harness/manifest.json"
  rejected inject "$W4"
  test ! -e /tmp/gridfin-victim.txt
}

c36_desc="C36 두 번 실행해도 결과가 같고 무시 목록 파일이 바뀌지 않는다"
c36() {
  M=$(main_repo); W=$(worktree_of "$M")
  common=$(git -C "$W" rev-parse --git-common-dir)
  inject "$W" > /dev/null
  a=$(tree_sum "$W/.claude" "$W/.harness")
  e=$(shasum -a 256 < "$common/info/exclude")
  inject "$W" > /dev/null
  b=$(tree_sum "$W/.claude" "$W/.harness")
  test "$a" = "$b"
  test "$e" = "$(shasum -a 256 < "$common/info/exclude")"
  test -z "$(git -C "$W" status --porcelain)"
}

c37_desc="C37 항목 하나를 못 넣으면 나머지를 진행하고 종료 코드 1로 끝낸다"
c37() {
  M=$(main_repo); W=$(worktree_of "$M")
  #      목적지 디렉터리 하나에 쓸 수 없게 만든다
  mkdir -p "$W/.claude/scripts/hooks"
  chmod 500 "$W/.claude/scripts/hooks"
  partial inject "$W"
  #      어느 항목이 실패했는지 보고한다
  inject "$W" > "$GRIDFIN_RUN/out.txt" 2>&1 || true
  chmod 700 "$W/.claude/scripts/hooks"
  grep -q 'session-start.py' "$GRIDFIN_RUN/out.txt"
  #      나머지는 들어갔다
  test -f "$W/.harness/manifest.json"
  test -f "$W/.claude/settings.json"

  #      무시 블록이 덮지 않는 경우도 같은 층이다 — 나머지를 진행하고 1로 끝낸다
  M2=$(main_repo); W2=$(worktree_of "$M2")
  common=$(git -C "$W2" rev-parse --git-common-dir)
  : > "$common/info/exclude"
  partial inject "$W2"
  test -f "$W2/.claude/settings.json"

  #      경로에 공백과 유니코드가 있어도 찾아낸다.
  #      git status 를 파싱하면 이 경로가 따옴표와 8진 이스케이프로 나와
  #      매니페스트의 dest 와 맞지 않는다 — 안 뜨는 것으로 잘못 판정한다
  M3=$(main_repo); W3=$(worktree_of "$M3")
  n=".claude/scripts/hooks/이름 있는 훅.py"
  printf 'x\n' > "$M3/$n"
  jq --arg d "$n" '.files += [{"dest":$d}]' "$M3/.harness/manifest.json" > "$M3/t.json"
  mv "$M3/t.json" "$M3/.harness/manifest.json"
  common=$(git -C "$W3" rev-parse --git-common-dir)
  : > "$common/info/exclude"
  inject "$W3" > "$GRIDFIN_RUN/out3.txt" 2>&1 || true
  grep -q '이름 있는 훅.py' "$GRIDFIN_RUN/out3.txt"
}

# ── 실행기 ────────────────────────────────────────────────
ALL="29 30 31 32 33 34 35 36 37 38"

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
