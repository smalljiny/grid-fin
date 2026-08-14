# 하네스 배포 방식 — 선택지 조사와 실증

**최초 작성**: 2026-08-02
**최종 수정**: 2026-08-02
**대상 프로젝트**: grid fin (신규 개인용 개발 하네스)
**조사 대상**: `/Users/mario/Workspace/harness` (기존 하네스 원본), cygnus (배포 대상 실사례)
**성격**: 1차 관측 + 실측 검증. §4의 실험은 이 문서 작성 중 직접 실행한 결과다.
**범위**: 조사까지. 메커니즘 선택과 배선 확정은 피쳐 목록 정의 이후 단계로 미룬다.

관련 문서: [error-recurrence-prevention.md](error-recurrence-prevention.md) §7.9 (원본 반영 — 경계·검출·전파)

---

## 0. 조사 요약

| # | 관측 | 근거 |
|---|---|---|
| 1 | **현행 배포의 핀은 gitignore 안에 있다.** 추적되지 않는 핀은 버전 식별 기능을 하지 못한다 | §1.1. `deploy-harness.sh`가 심는 ignore 블록이 매니페스트 자신을 포함한다 |
| 2 | **하네스의 절반은 Codex용이다.** Claude 전용 메커니즘은 배포 대상의 절반만 덮는다 | §1.3, §2.1 |
| 3 | **심볼릭 링크는 배치 메커니즘이지 버전 메커니즘이 아니다** | §2.2. 실제 사례를 뜯어보면 스토어 + 락파일 + 링크의 조합이고, 버전 식별은 락파일이 한다 |
| 4 | **Copier는 `.copier-answers.yml`의 `_commit`으로 핀을 추적 파일에 남긴다** | §2.3, §4.1 |
| 5 | **`.gitignore` 통짜 무시 하에서는 `copier update`가 로컬 수정을 경고 없이 삭제한다** | §4.2 실증. 3-way merge가 git 기계로 수행되므로 추적되지 않으면 무력화된다 |
| 6 | **템플릿에 `{{ _copier_conf.answers_file }}.jinja`가 없으면 `copier update` 자체가 불가능하다** | §4.1 실증. 질문 세트가 0개인 설계에서 특히 놓치기 쉽다 |
| 7 | **`_tasks`는 `copier update`에서도 실행되며, 1회 update당 3번 돈다** | §4.3, §4.4 실증. 중간 상태 트리에서도 실행된다 |
| 8 | **블록 원본이 merge 충돌 상태면 마커가 상시 로드 컨텍스트로 흘러든다** | §5.1 실증 |
| 9 | **AGENTS.md/CLAUDE.md 이중화가 도구 skew 문제의 원인이다** | §6.1. 표준 구조는 원본을 하나로 만든다 |
| 10 | **상시 로드 예산 문제가 배포 방식과 독립적으로 존재한다** | §6.3. 외부 자료의 200줄 권고와 선행 조사 권고 #6이 같은 지점을 가리킨다 |

---

## 구현 참조 자료 — 검증된 메커니즘 정리

> **이 문서는 다른 조사와 성격이 다르다.** 근거의 중심이 문헌이 아니라 **이 조사 중 직접 실행한 Copier 실험**(§4·§5.1)이며, 재현 스크립트가 부록 A에 실려 있다. **기존 하네스 고고학이 아니라 이 프로젝트를 위해 생성한 1차 실증**이므로 구현 시 그대로 참조할 자료다. 아래는 그것을 배선 결정에 쓸 형태로 정돈한 것이다.

### A. 핀은 두 필드가 각각 다른 일을 한다

이 조사에서 가장 이식성 높은 결론이다 (§2.2).

| 필드 | 답하는 질문 | 없으면 |
|---|---|---|
| **`sha` / commit ID** (해석된 리비전) | *"업스트림의 어느 리비전인가"* | **설치를 재현할 수 없다.** 움직이는 `main`을 상대로 무력 |
| **`contentHash`** (설치된 내용 해시) | *"설치 이후 디스크에서 바뀌었나"* | 드리프트를 검출할 수 없다 |

**둘은 대체 관계가 아니다.** `~/.agents/.skill-lock.json`은 `skillFolderHash`만 갖고 `ref`·`commit`이 없어 후자에만 답한다.

> **다른 경로에서 같은 요구가 나왔다** — [보안 §2.2](security.md)의 OWASP ASI04가 완화책으로 ***"Pinning by content hash **and** commit ID, with staged rollout and auto-rollback"*** 을 든다. 재현성 축과 공급망 보안 축이 같은 두 필드를 부른다.

### B. 3-way merge의 동작 전제 — 실증됨

**§4.2에서 직접 실험해 확인했다.** 동일 시나리오를 두 프로젝트에서 실행.

| | `.claude`가 gitignore된 프로젝트 | `.claude`가 추적되는 프로젝트 |
|---|---|---|
| 로컬 수정 | **경고 없이 소실.** 충돌 없음, `.rej` 없음 | `<<<<<<< before updating` 충돌 마커 |
| `git status` | 변화 없음 | **`UU .claude/core.md`** |

**원인**: Copier의 3-way merge는 **git 기계로 수행된다.** 대상이 추적되지 않으면 병합 기준이 없어 **단순 덮어쓰기로 퇴화**한다.

**두 함의가 곧 구현 요구사항이다.**

1. **gitignore 통짜 무시 제거는 정리 항목이 아니라 동작 전제조건**이다
2. 추적만 되면 `UU` 마커가 *"이 프로젝트가 core를 고쳤다"* 는 신호를 update마다 띄운다 — **별도 해시 매니페스트 없이 드리프트 검출을 얻는다**

### C. Copier 배선의 함정 넷 — 전부 실증

| # | 관측 | 구현 시 대응 |
|---|---|---|
| 1 | **`copier.yml`에 `_answers_file`을 선언하는 것만으로는 `.copier-answers.yml`이 생기지 않는다.** 템플릿 트리에 `{{ _copier_conf.answers_file }}.jinja`가 있어야 한다 | 없으면 **`copier update` 자체가 불가능**. 질문 세트가 0개인 설계에서 특히 놓치기 쉽다 |
| 2 | **`_tasks`는 `copier update`에서도 실행되며 1회 update당 3번 돈다.** 첫 실행은 **update 이전 상태의 트리**를 본다 | **멱등하지 않으면 깨진다.** `test -f` 방식은 안전, 누적·카운트·append는 위험 |
| 3 | **옛 템플릿의 태스크가 먼저 돈다** | 태스크 스크립트 변경은 그것을 도입하는 update에서 **즉시 반영되지 않는다** |
| 4 | **마커가 없으면 조용한 no-op** | 자동 실행 태스크는 프롬프트를 띄울 수 없다. **작업 수행과 수행 여부 검증을 분리**해야 한다 |

### D. 상시 로드 파일을 렌더 경로에 두는 위험 — 실증

**§5.1에서 재현했다.** 상시 로드 파일 자체를 렌더 경로 밖에 두어도 구멍이 남는다 — **블록의 원본(`rules/*.md`)이 렌더 대상이고 3-way merge를 받으며, 블록 재생성 스크립트는 merge 이후에 그 파일들을 읽는다.**

결과: 충돌 마커가 든 파일이 그대로 상시 로드 블록에 실린다. **Claude Code가 지시로 읽는 파일 안에 `<<<<<<<` 가 박힌다.**

AGENTS.md는 더 나쁘다 — Codex에 `@import`가 없어 본문이 **인라인**되므로 21KB 블록 안의 충돌은 사실상 해소 불가다.

### E. 메커니즘 선택지 비교

| | 현행 쉘+매니페스트 | Claude 플러그인 | 스토어+심볼릭 링크 | **Copier** |
|---|---|---|---|---|
| 핀이 추적되나 | ✗ (gitignore 안) | ✓ `settings.json` | 락파일에 달림 | ✓ `.copier-answers.yml`의 `_commit` |
| 버전 롤백 | ✗ | ✓ `ref` | ✗ | ✓ `--vcs-ref` |
| **Codex 절반 커버** | ✓ | **✗** | ✓ | ✓ |
| 로컬 수정 보존 | ✗ | N/A (편집 불가) | N/A | ✓ 3-way merge |
| 드리프트 검출 | ✗ | N/A (드리프트 불가) | contentHash | 충돌 마커 (B의 조건 하에서) |
| 필요 메커니즘 수 | 1 | **2** | 2 | 1 |

**판단 기준** (§3):

- 배포 대상이 Claude Code만 쓴다면 → 플러그인이 유일하게 드리프트를 **구조적으로** 없앤다(core가 프로젝트 트리 밖)
- **Codex 절반을 포함해야 한다면** → 플러그인 단독 불가. 하네스의 절반이 `.codex/`·`AGENTS.md`다
- 도구 중립 + 단일 메커니즘 + 추적되는 핀을 동시에 요구하면 → 조사 범위에서 **Copier만 셋을 다 만족**(B의 전제조건 하에)

### F. 심볼릭 링크에 관한 사실 확인

| 사실 | 근거 |
|---|---|
| **심볼릭 링크는 배치 메커니즘이지 버전 메커니즘이 아니다** | 실제 사례를 뜯으면 **스토어 + 락파일 + 링크** 조합이고 버전 식별은 락파일이 한다 (§2.2) |
| Claude Code는 심볼릭 링크된 스킬 디렉터리를 따라간다 | 확인됨 — `~/.claude/skills/cmux-*` → `~/.agents/skills/*` |
| **저장소 밖을 가리키는 링크는 커밋할 수 없다** | git은 mode `120000` blob에 **대상 경로 문자열**을 저장한다. 절대경로는 머신 종속, 상대경로는 배치 강제 |
| **같은 저장소 안 형제 파일 링크는 안전** | 경로가 저장소 내부에서 해석된다 (`ln -s AGENTS.md CLAUDE.md`) |

### G. AGENTS.md / CLAUDE.md 이중화

Codex에 `@import`가 없어 AGENTS.md에 harness-guide를 21KB 인라인한 구조가 파생 문제의 원인이다 — skew 방지, 충돌 해소 불가가 전부 여기서 나온다.

표준 구조는 이중화 자체를 없앤다 — **`AGENTS.md`가 공통 규칙의 유일한 원본**(Codex가 직접 읽음), **`CLAUDE.md`는 `@AGENTS.md` + Claude 전용 규칙만**. 원본이 하나면 skew가 정의상 발생하지 않는다.

**단 §6.2의 미검증 항목이 남는다** — §4의 실측은 전부 **경로 목록형** 블록(`@.tack/rules/...`)을 검증한 것이고, Codex에 실제로 필요한 **concat-인라인** 방식은 실행해보지 않았다.

### H. 다른 조사와 맞물리는 지점

| 지점 | 연결 |
|---|---|
| A의 두 필드 | [보안 §2.2](security.md) OWASP ASI04가 같은 분리를 요구. [보안 §5.2](security.md)는 `openai-codex` 마켓플레이스에 **둘 다 없음**을 관측 |
| B의 gitignore 전제 | [상태·연속성 §4.0](state-and-continuity.md) — 같은 gitignore가 네이티브 `/rewind` 롤백 범위에서도 상태를 뺀다 |
| §6.3의 상시/온디맨드 분류 | [지시 계층 D](instruction-layers.md)의 ETH 연구가 그 분류를 지지하되 "길이" 축은 반박 |
| E의 플러그인 항목 | [강제 메커니즘 A](enforcement-mechanisms.md) — 플러그인의 `hooks/hooks.json`은 로드되고 비플러그인 프로젝트의 동일 파일명은 로드되지 않는다 |

---

## 1. 문제 — 무엇이 고장나 있었나

> **이 절과 §6.5는 기존 하네스 실측이며, 위 메커니즘이 어떤 문제를 푸는지 확인하는 보조 근거다.** §4·§5는 이 조사 중 직접 실행한 실험이므로 자료 쪽에 속한다.

기존 하네스는 `scripts/deploy-harness.sh`(rsync 기반)로 대상 프로젝트에 파일을 복사하고, `.harness/.deploy-manifest.json`에 소스 커밋과 파일 목록을 기록한다.

```json
{
  "manifest_version": 1,
  "deployed_at": "2026-05-27T04:31:29.444Z",
  "source": { "commit": "233a7fadcdbb...", "branch": "develop" },
  "files": [ ".claude/agents/architect.md", ... ]
}
```

여기에 두 개의 결함이 있다.

### 1.1 핀이 gitignore 안에 있다

`deploy-harness.sh`가 대상 프로젝트에 심는 ignore 블록이 매니페스트 자신을 포함한다.

```
# BEGIN harness local ignores
.harness-backups/
.claude/sessions/
.claude/checkpoints.log
.claude/settings.local.json
.harness/.deploy-manifest.json      ← 핀이 여기 있다
docs/_local/
# END harness local ignores
```

**추적되지 않는 핀은 핀이 아니다.** 프로젝트를 클론한 다른 머신·다른 사람은 어느 버전의 하네스를 쓰는지 알 방법이 없고, git diff가 없으니 업데이트가 무엇을 바꿨는지도 보이지 않는다. "버전관리와 업데이트가 잘 되지 않는다"는 체감의 기계적 원인이다.

### 1.2 통짜 무시가 관리 블록을 덮었다

cygnus `.gitignore` 165~175행:

```
# BEGIN harness local ignores
...
# END harness local ignores
.claude          ← 관리 블록 바깥
.codex
.harness
```

관리 블록은 세션 로그·체크포인트 같은 산출물만 무시하도록 설계되어 있다. 즉 `.claude/`와 `.harness/`는 **추적되기를 기대하는 설계**다. 그런데 블록 바깥의 통짜 무시가 그것을 덮어 추적 파일이 0건이 됐다.

이것이 선행 조사 §6.1에서 측정한 학습 44% 유실의 인프라적 원인이다. 그리고 §4.2에서 보듯 **메커니즘을 바꿔도 이 줄이 남아 있으면 같은 유실이 재현된다.**

### 1.3 배포 전체 목록 — 무엇을 옮겨야 하는가

| 대상 | 성격 |
|---|---|
| `.claude/{agents,commands,skills}/` | Claude 전용 컴포넌트 |
| `.claude/hooks/hooks.json` + `.claude/scripts/hooks/*.js` | 훅 |
| `.claude/settings.json` | 권한·statusLine (프로젝트 스코프) |
| `.codex/`, `AGENTS.md` | **Codex 전용 — Claude 도구가 읽지 않는다** |
| `.harness/{rules,contracts,templates}/`, `harness-guide.md` | 공유 규칙 |
| `CLAUDE.md` | 프로젝트 내용 + 하네스 블록 |
| `.harness/commit-scopes.md` | **프로젝트 소유 config** |
| `docs/_local/` 스캐폴드, `dev-context.json` | 로컬 상태 |

**Codex 절반이 존재한다는 사실이 이후 모든 판단을 지배한다.** Claude 전용 메커니즘은 이 목록의 절반밖에 덮지 못한다.

---

## 2. 검토한 선택지

### 2.1 Claude Code 플러그인

마켓플레이스 + 플러그인 구조. 이 머신에서 스키마를 직접 확인했다.

```json
// ~/.claude/plugins/marketplaces/claude-plugins-official/.claude-plugin/marketplace.json
"source": { "source": "git-subdir", "url": "...",
            "ref": "v1.5.5", "sha": "30287f5e3f12..." }
```

`ref`/`sha`로 **버전이 고정된다.** 그리고 활성화는 추적되는 `.claude/settings.json`에 들어간다 — `~/Workspace/dotu/.claude/settings.json`에 `enabledPlugins`가, `~/.claude/settings.json`에 `extraKnownMarketplaces`가 실사용 중이다.

**강점**: core가 프로젝트 트리 밖(`~/.claude/plugins/cache/`)에 있어 드리프트가 구조적으로 불가능하다. 선행 조사 §7.9.3의 (a) 심볼릭 링크가 "버전 고정 불가"를 대가로 얻던 것을 대가 없이 얻는다.

**제약**: §1.3 목록의 절반만 덮는다. `settings.json`, `CLAUDE.md`, `AGENTS.md`, `.codex/`, config 계층, 로컬 스캐폴드가 전부 밖에 남고 두 번째 메커니즘이 필요해진다. 원 문제가 "버전관리·업데이트가 어렵다"이므로 메커니즘 수 증가 자체가 비용이다.

**부수 확인**: 플러그인 `SessionStart` 훅이 상시 컨텍스트를 주입할 수 있다(superpowers 5.0.6이 그 방식). 즉 `@import`의 대안 채널은 존재한다.

**이 선택지가 유리해지는 조건**: 배포 대상이 Claude Code만 쓰는 경우, 또는 하네스의 Claude 슬라이스만 외부에 공개 배포하려는 경우.

### 2.2 공유 체크아웃 + 심볼릭 링크

이 머신에서 이미 돌고 있는 패턴이다.

```
~/.claude/skills/cmux-billing -> ../../.agents/skills/cmux-billing
```

**Claude Code가 심볼릭 링크된 스킬 디렉터리를 따라간다는 것은 확인된 사실이다** — 위 링크로 걸린 스킬들이 세션의 사용 가능 스킬 목록에 실제로 나타난다.

그런데 `~/.agents`는 git 체크아웃이 **아니다.** git 저장소가 아니고 `.skill-lock.json`이 있다.

```json
"cmux": {
  "source": "manaflow-ai/cmux",
  "sourceUrl": "https://github.com/manaflow-ai/cmux.git",
  "skillPath": "skills/cmux/SKILL.md",
  "skillFolderHash": "d7b4a428df2255...",
  "installedAt": "2026-07-15T00:37:53.940Z"
}
```

즉 실제 패턴은 "git 체크아웃 + 심볼릭 링크"가 아니라 **스토어 + 락파일 + 심볼릭 링크** 세 요소의 조합이고, 하는 일이 각각 다르다.

| 요소 | 역할 |
|---|---|
| 스토어 | 내용이 프로젝트 밖에 한 벌만 존재 |
| 락파일 | 어느 버전인지 기록 |
| 심볼릭 링크 | 도구가 보는 곳에 **배치** |

**심볼릭 링크는 배치 메커니즘이지 버전 메커니즘이 아니다.** "복사본이 낡는다"는 고치지만 "어느 버전인가"는 손대지 않는다. §1.1의 문제는 후자다.

그리고 저 락파일조차 핀이 아니다. `ref`도 `commit`도 없고 `skillFolderHash`는 **설치된 폴더의 내용 해시**다 — "설치 이후 디스크에서 바뀌었나"에는 답하지만 "업스트림의 어느 리비전인가"에는 답하지 못한다. 움직이는 `main`을 상대로 내용 해시만으로는 설치를 재현할 수 없다.

> 이것이 선행 조사 권고 #17("배포 매니페스트에 파일별 해시")을 정정한다. **해시만으로는 부족하다.** 두 필드가 각각 다른 일을 해야 한다 — `sha`(해석된 리비전) = 재현 가능한 핀, `contentHash` = 드리프트 검출.

**심볼릭 링크를 커밋할 수 없는 이유**: git은 심볼릭 링크를 mode `120000` blob으로 저장하고 내용은 **대상 경로 문자열 그 자체**다. 절대경로는 머신 종속이고, 상대경로는 형제 디렉터리 배치를 강제한다. 둘 다 클론을 넘어가지 못한다. 이 방식을 쓴다면 커밋 대상은 링크가 아니라 락파일이고 링크는 재생성되어야 한다.

**예외**: 대상이 같은 저장소 안의 형제 파일인 경우(`ln -s AGENTS.md CLAUDE.md`)는 경로가 저장소 내부에서 해석되므로 안전하다. §6.4 참조.

**제약**: 버전 식별 기능이 없어 스토어와 락파일을 별도로 구성해야 한다.

### 2.3 Copier

Python 템플릿 렌더링 도구. `uvx copier`로 설치 없이 실행된다(이 머신에 uv 0.10.4 확인).

```bash
uvx copier copy gh:<owner>/<repo> <dest>   # 최초 배포
uvx copier update                          # 갱신
uvx copier update --vcs-ref <git-tag>      # 특정 버전 고정·롤백
```

| 요구 | Copier의 대응 |
|---|---|
| 핀이 추적되어야 함 (§1.1) | `.copier-answers.yml`의 `_commit` — 커밋 대상 |
| 버전 = 식별 가능한 리비전 | git 태그, `--vcs-ref`로 롤백 |
| 도구 중립 (§1.3) | 파일 렌더링이므로 Claude/Codex 구분 없음 |
| core/config 경계 (선행 #16) | `_skip_if_exists` |
| 로컬 수정 보존 | **3-way merge** — 복사 기반 배포에는 없던 것 |
| 배포 범위 제한 | `_subdirectory` |
| 스캐폴드 | `_tasks` |

**제약**: 파일이 프로젝트로 복사되므로 core가 프로젝트 트리 안에 존재한다. 드리프트가 가능하며, 3-way merge가 그것을 없애는 대신 **충돌로 노출**한다. 그리고 그 노출은 §4.2의 조건(추적됨)에서만 작동한다. 외부 런타임(Python/uv) 의존이 추가된다.

**선행 조사 §7.9.3에 대한 정정**: 그 절은 전파 전략을 (a) 심볼릭 링크 / (b) 배포+드리프트 강제 둘로 놓고 "동시 운용 프로젝트 수"로 갈랐다. Copier는 (b) 계열이되 드리프트를 없애는 대신 3-way merge로 관리 가능하게 만드는 제3의 형태다. (b)의 실패 모드였던 "원본 반영 명령을 안 돌리면 유실"이 §4.2의 조건 하에서 충돌 마커로 노출된다.

---

## 3. 선택지 비교

| | 현행 쉘+매니페스트 | 플러그인 | 스토어+심볼릭 링크 | Copier |
|---|---|---|---|---|
| 핀이 추적되나 | ✗ (gitignore) | ✓ `settings.json` | 락파일에 달림 | ✓ `.copier-answers.yml` |
| 버전 롤백 | ✗ | ✓ `ref` | ✗ (락파일에 리비전 없음) | ✓ `--vcs-ref` |
| Codex 절반 커버 | ✓ | **✗** | ✓ | ✓ |
| 로컬 수정 보존 | ✗ (덮어씀) | N/A (편집 불가) | N/A | ✓ 3-way merge |
| 드리프트 검출 | ✗ (해시 없음) | N/A (드리프트 불가) | contentHash | 충돌 마커 (조건부) |
| 외부 의존 | rsync | Claude Code | 설치 도구 | Python/uv |
| 필요 메커니즘 수 | 1 | **2** | 2 | 1 |

**판단 기준**:

- 배포 대상이 Claude Code만 쓴다면 → 플러그인이 유일하게 드리프트를 구조적으로 없앤다.
- Codex 절반을 포함해야 한다면 → 플러그인 단독으로는 불가능하고, 메커니즘을 둘로 늘리거나 도구 중립적 방식을 써야 한다.
- 도구 중립 + 단일 메커니즘 + 추적되는 핀을 동시에 요구한다면 → 조사 범위에서 Copier만 셋을 다 만족한다. 단 §4.2의 전제조건이 붙는다.

플러그인과 Copier는 배타적이지 않다. Claude 슬라이스를 외부에 공개 배포할 필요가 생기면 그때 병행할 수 있다.

---

## 4. 실증

이 절의 결과는 부록 A의 스크립트로 재현 가능하다. 환경: macOS, uv 0.10.4, `copier@latest` (uvx).

### 4.1 answers 파일은 템플릿이 직접 넣어야 한다

`copier.yml`에 `_answers_file`을 선언하는 것만으로는 `.copier-answers.yml`이 생성되지 않는다. 첫 시도에서 배포는 성공했으나 answers 파일이 없었다.

```
$ uvx copier copy --vcs-ref v1.0.0 ../tmpl .
    create  .claude/core.md
    create  CLAUDE.md
$ cat .copier-answers.yml
cat: .copier-answers.yml: No such file or directory
```

템플릿 트리에 `{{ _copier_conf.answers_file }}.jinja`를 추가한 뒤에야 생성됐다.

```yaml
_commit: v1.0.0
_src_path: ../tmpl
```

**질문 세트가 0개인 설계에서 특히 놓치기 쉽다** — 질문이 없으니 answers 파일도 불필요해 보이지만, 이 파일이 핀을 담는 유일한 파일다. 없으면 `copier update`가 아예 불가능하다.

### 4.2 gitignore 통짜 무시 하에서는 update가 로컬 수정을 조용히 삭제한다

동일 시나리오를 두 프로젝트에서 실행했다. core 파일에 로컬 수정 한 줄을 넣고 템플릿 v1 → v2로 update.

**A. `.claude`가 gitignore된 프로젝트**

```
$ cat .claude/core.md
core rule v2 — upstream 개선
```

로컬 수정이 사라졌다. 경고 없음, 충돌 없음, `.rej` 없음.

**B. `.claude`가 추적되는 프로젝트**

```
$ cat .claude/core.md
<<<<<<< before updating
core rule v1
로컬에서 추가한 규칙
=======
core rule v2 — upstream 개선
>>>>>>> after updating

$ git status --short
UU .claude/core.md
 M .tack/guide.md          ← 수정 없던 파일은 깔끔히 v2로
```

**원인**: Copier의 3-way merge는 git 기계로 수행된다. 대상 파일이 추적되지 않으면 병합 기준이 없어 merge가 무력화되고 단순 덮어쓰기로 퇴화한다.

**함의 두 가지**:

1. cygnus `.gitignore` 173~175행이 현재 그 상태다. 통짜 무시를 남긴 채 Copier를 얹으면 선행 조사 §6.1의 44% 유실이 새 메커니즘 위에서 재현된다. 통짜 무시 제거는 부수적 정리가 아니라 **동작 전제조건**이다.
2. 추적만 되면 `UU` 충돌 마커가 "이 프로젝트가 core를 고쳤다"는 신호를 update마다 띄운다. 선행 권고 #17의 해시 매니페스트가 하려던 일을 별도 인프라 없이 얻는다.

### 4.3 `_tasks`는 `copier update`에서도 실행된다

마커 블록 재생성을 `_tasks`에 걸고, 프로젝트 섹션을 편집한 상태에서 새 규칙 파일이 추가된 버전으로 update했다.

```
$ uvx copier update --vcs-ref v2.0.0
Updating to template version 2.0.0
[sync-block] 블록 재생성 완료 (2개 규칙)
```

```markdown
# 프로젝트
이 프로젝트는 결제 서비스다. Node.js + Postgres.
LLM이 채운 내용.                          ← 보존

<!-- harness-rules:begin -->
@.tack/rules/coding-style.md
@.tack/rules/security.md                 ← 자동 추가
<!-- harness-rules:end -->

## 추가 메모
블록 바깥의 프로젝트 소유 영역.          ← 보존
```

새 규칙이 들어오면 import 라인이 자동으로 따라붙는다. 선행 조사 §2.3·§7.10.5가 반복 지적한 **"명시적 행위는 실행되지 않는다"는 실패 모드에 대응할 수 있는 단계**가 여기 있다.

### 4.4 `_tasks` 실행에 관한 관측

**update 1회당 3번 실행된다.** 그리고 첫 실행은 **update 이전 상태의 트리**를 본다 — 부록 A의 v1→v2 update 출력이 그것을 그대로 보여준다.

```
[sync-block] 블록 재생성 완료 (1개 규칙)   ← v1 상태 (coding-style.md만)
[sync-block] 블록 재생성 완료 (2개 규칙)   ← v2 상태 (+security.md)
[sync-block] 블록 재생성 완료 (2개 규칙)
```

Copier가 update 중 이전 버전을 재렌더하면서 **옛 템플릿의 태스크까지 중간 상태 트리에서 실행한다.**

| 관측 | 함의 |
|---|---|
| 태스크는 여러 번 실행된다 | 멱등하지 않으면 깨진다. `test -f` 방식은 안전, 누적·카운트·append는 위험 |
| 중간 상태 트리에서도 실행된다 | 태스크가 도는 실제 작업 디렉터리를 확인해야 한다 (`echo "[task] pwd=$PWD"` 한 줄이면 관측 가능) |
| 옛 스크립트가 먼저 돈다 | 태스크 스크립트 변경은 그것을 도입하는 update에서 즉시 반영되지 않는다 |

**태스크 실패 시 동작은 확인하지 못했다.** 스크립트 버그가 있던 실행에서 update가 중단되지 않고 `CLAUDE.md.tmp` 잔여물이 남는 것을 관측했으나, 격리 실험을 하지 않았으므로 단정하지 않는다.

### 4.5 무마커 상태는 조용한 no-op이다

자동 실행 태스크는 프롬프트를 띄울 수 없으므로 마커가 없으면 경고 후 통과하게 된다. 그러나 그 경고는 update 출력에 묻히고, 결과는 **규칙이 하나도 import되지 않는 프로젝트**인데 아무것도 그것을 드러내지 않는다.

즉 태스크 방식을 쓸 경우 **작업 수행과 수행 여부 검증이 분리되어야 한다.** 검증을 어디에 둘지는 미해결(§8).

---

## 5. 상시 로드 파일과 렌더 경로 — 관측된 위험

§4.2가 보여준 충돌 마커를 CLAUDE.md에 대입하면 위험이 분명해진다.

```markdown
<<<<<<< before updating
@.tack/rules/coding-style.md
=======
@.tack/rules/coding-style.md
@.tack/rules/security.md
>>>>>>> after updating
```

**Claude Code가 지시로 읽는 파일 안에 충돌 마커가 박힌다.** 프로젝트 섹션은 LLM이 쓰는 예측 불가한 영역이므로 충돌은 가설이 아니라 기대되는 경우이고, 그 상태는 누군가 해소할 때까지 매 세션 로드된다.

AGENTS.md는 더 나쁘다. Codex에 `@import`가 없어 managed 블록에 본문이 **인라인**되므로, 21KB 블록 안의 충돌은 사실상 해소 불가다.

> **선행 제안에 대한 함의**: Copier 제안의 "AGENTS.md는 init-once 제외 — managed 블록을 매 update 재생성"은 이 위험을 키운다. 렌더 대상이면 3-way merge 대상이 되기 때문이다. 상시 로드 파일을 렌더 경로에 둘지 여부가 별도 판단 지점이다.

### 5.1 블록의 원본은 렌더 경로 안에 남는다

상시 로드 파일 자체를 렌더 경로 밖에 두어도 구멍이 하나 남는다. **블록의 원본인 `.tack/rules/*.md`는 렌더 대상이고 3-way merge를 받는다.** 그리고 블록 재생성 스크립트는 merge **이후에** 그 파일들을 읽는다.

부록 A의 변형(로컬 수정 대상을 `.claude/core.md`가 아니라 `.tack/rules/coding-style.md`로 바꾸고, 템플릿 v2가 같은 파일을 수정)으로 재현했다.

```
$ git status --short
UU .tack/rules/coding-style.md

$ cat .tack/rules/coding-style.md
<<<<<<< before updating
coding style v1
로컬 규칙 추가
=======
coding style v2 — upstream 개선
>>>>>>> after updating
```

그런데 재생성 스크립트는 그대로 통과해 블록에 그 파일을 실었다.

```markdown
<!-- harness-rules:begin -->
@.tack/rules/coding-style.md      ← 충돌 마커가 든 파일
@.tack/rules/security.md
<!-- harness-rules:end -->
```

**상시 로드 컨텍스트가 오염된다.** §6.2의 concat 방식이면 마커 텍스트가 AGENTS.md 본문에 직접 인라인되므로 더 직접적이다.

완화 방향은 재생성 단계에서 원본의 충돌 마커를 검사하는 것이지만, §4.4에서 태스크 실패의 중단 여부를 확인하지 못했으므로 검사가 실제로 재생성을 막는지는 미확인이다(§8).

### 5.2 블록 재생성 로직이 두 곳에 존재하게 된다

기존 `/flow-init`이 이미 그 일을 한다 — `.harness/rules` glob → 마커 사이 치환 → SHA-256 비교를 변경 판정의 단일 권위자로 사용. `_tasks` 스크립트가 같은 도출을 다시 구현하면 정렬 순서·중첩 디렉터리·빈 목록 처리에서 갈라진다.

한편 두 진입점이 담당할 수 있는 범위는 다르다.

| 진입점 | 가능 | 불가능 |
|---|---|---|
| `_tasks` | 결정적 도출 (glob → 마커 사이 치환) | `AskUserQuestion`, 백업 후 재생성 판단 |
| `/flow-init` | 위 전부 + LLM 몫(프로젝트 정보 수집) + 상태 분기 | — |

즉 `/flow-init`의 4상태 분기(신규 생성 / 업데이트 / 일회 마이그레이션 / 경계 탐지 불가) 중 자동 실행이 담당할 수 있는 것은 업데이트 모드뿐이다.

---

## 6. AGENTS.md와 CLAUDE.md의 관계

출처: [AGENTS.md 표준화 — 요즘IT](https://yozm.wishket.com/magazine/detail/3874/)

### 6.1 이중화가 파생 문제의 원인이었다

현재 하네스는 두 파일이 **같은 내용을 두 벌로** 갖는다. Codex에 `@import`가 없어 AGENTS.md에 harness-guide를 21KB 인라인해 둔 구조다. "매 update 재생성해야 skew 방지", "21KB 블록의 충돌은 해소 불가" — 전부 이 이중화에서 파생된 문제다.

자료가 제시하는 표준 구조는 이중화 자체를 없앤다.

```
AGENTS.md    ← 공통 규칙의 유일한 원본 (Codex가 직접 읽음)
CLAUDE.md    ← @AGENTS.md + Claude 전용 규칙만
```

**원본이 하나면 skew가 정의상 발생하지 않는다.**

자료가 제시한 근거: AGENTS.md는 2025년 8월 OpenAI Codex 컨텍스트 파일로 도입되어 2025년 12월 Linux Foundation 산하 AAIF에 기부되며 표준화됐고, 6만 개 이상 저장소·30개 이상 도구가 채택했다. 저자는 Anthropic 5개 모델 210회 실험으로 import 방식의 오버헤드가 관측되지 않음을 보였다(저자 주장이며 재현하지 않았다).

### 6.2 규칙 파일 분리는 그대로 살아남지 못한다

Codex는 `@import`를 지원하지 않는다. `.tack/rules/*.md`를 별도 파일로 두고 `@`로 부르는 방식은 **AGENTS.md 쪽에서 성립하지 않으므로**, 규칙 본문이 AGENTS.md 안에 인라인되어야 한다.

두 방식의 성질이 다르다.

| | 경로 목록형 (`@.tack/rules/...`) | concat-인라인 |
|---|---|---|
| 적용 대상 | Claude (CLAUDE.md) | Codex (AGENTS.md) |
| 블록 크기 | 규칙 수만큼의 줄 | 규칙 본문 전체 |
| §4 실측 | **검증됨** | **미검증** |

**§4의 실측은 전부 경로 목록형 블록을 검증한 것이다.** concat-인라인 방식 — 출력 형태가 다르고 블록이 훨씬 크며 Codex에 실제로 필요한 바로 그 방식 — 은 실행해보지 않았다(§8).

한편 이 구조에서 CLAUDE.md가 하네스로부터 받는 것은 `@AGENTS.md` **한 줄**로 줄어든다.

### 6.3 별도 쟁점 — 상시 로드 예산

자료의 마이그레이션 5단계 마지막은 "사람이 다듬은 간결한 파일로 200줄 안쪽"이고, 근거로 ETH Zurich 연구(자동 생성 컨텍스트가 성공률을 낮춘다)를 든다.

> **2026-08-02 출처 감사 — 이 인용은 2차 인용이었고, 원문은 다른 것을 말한다.**
>
> 최초 작성 시 위 결론은 **블로그가 인용한 것을 다시 인용**한 것이었다(부록 B가 "위 자료의 인용"으로 표기). 원문을 찾아 확인했다 — [Gloaguen, Mündler, Müller, Raychev, Vechev, *Evaluating AGENTS.md: Are Repository-Level Context Files Helpful for Coding Agents?* (arXiv 2602.11988, ETH Zurich + LogicStar.ai)](https://arxiv.org/abs/2602.11988). AGENTbench(실제 저장소 기반 Python SWE 과제)로 컨텍스트 파일 유무를 대조했다.
>
> **차이가 두 군데다.**
>
> | | 2차 인용 (블로그 경유) | 원문 |
> |---|---|---|
> | 무엇이 문제인가 | **자동 생성** 컨텍스트가 성공률을 낮춘다 | *"providing context files does not generally improve task success rates"* — **자동 생성과 개발자 작성 양쪽 모두** |
> | 핵심 구분 | 생성 주체 (자동 vs 사람) | **내용 종류** — *"instructions in the context files are well followed by coding agents, repository overviews, although popular and recommended by model providers, are not helpful"* |
> | 비용 | 언급 없음 | *"increasing inference cost by over 20% on average"* |
>
> **원문의 결론이 이 절의 분류표를 오히려 강하게 지지한다.** 저자들은 *"context files are useful for specifying non-standard coding practices"* 라고 결론짓는다 — 아래 표의 "상시 = 코드를 읽어도 알 수 없는 것"과 같은 기준이다. 그리고 무용하다고 지목된 것은 **저장소 개요(repository overview)** 인데, 이는 정확히 "코드를 읽으면 알 수 있는 것"이다.
>
> 즉 **"길이를 줄여라"가 아니라 "종류를 가려라"가 원문의 주장이다.** 200줄이라는 수치는 원문에서 나온 것이 아니다. 저자들은 오히려 *"any attempts to improve performance should be rigorously evaluated before deployment"* 로 끝맺는다.
>
> 이 정정은 [지시 계층 조사 §6](instruction-layers.md)의 수렴표에도 반영했다.

현재 하네스는 22KB harness-guide + 규칙 6개를 상시 로드한다. **전부 인라인하면 수천 줄이 된다.**

이것은 **선행 조사 권고 #6("상시 로드 계층에 줄 수 예산을 건다", ACE의 context collapse)과 같은 결론**이다. 서로 다른 두 경로가 같은 지점을 가리킨다.

분류 기준은 두 자료가 일치한다.

| 부류 | 기준 | 가능한 배치 |
|---|---|---|
| 상시 | 코드를 읽어도 알 수 없는 것 — 금지 사항, 빌드 명령, 팀 규칙 | 상시 로드 파일 |
| 온디맨드 | 그 외 대부분 | Claude 스킬 / `.codex/` 스킬 |

**이 분류는 배포 방식과 독립적이며, 어느 메커니즘을 고르든 선행한다.** 분류 결과가 곧 블록 재생성의 입력 목록이 되므로, 순서가 뒤바뀌면 수천 줄짜리 블록을 다루는 배선을 먼저 만들게 된다.

### 6.4 심볼릭 링크 변형

자료가 언급한 `ln -s AGENTS.md CLAUDE.md`는 §2.2의 제약 대상이 **아니다.** 대상이 같은 저장소 안의 형제 파일이라 mode-120000 blob의 경로 문자열이 저장소 내부에서 해석되고 클론을 넘어간다. §2.2의 판정은 **저장소 밖을 가리키는 링크**에 한정된다.

다만 이 방식은 Claude 전용 규칙을 넣을 곳을 남기지 않는다.

### 6.5 관측된 실무 항목

1. **하네스 `.gitignore` 35행이 `AGENTS.md`를 무시하고 있다.** 이 구조에서 그것은 유일한 원본이 되므로, §4.2의 통짜 무시와 같은 성격의 장애물이다.
2. **이름 변경과 포인터 생성 사이에 세션을 열면 Claude Code가 읽을 컨텍스트 파일이 없다.** 자료의 지적이며 같은 커밋 처리를 권한다.
3. **`.harness/` → `.tack/` 개명은 기존 `@.harness/rules/...` 라인을 전부 낡게 만든다.** 신규 프로젝트는 무관하고, cygnus는 블록이 다시 쓰이기 전까지 import가 깨진 상태가 된다.

---

## 7. 이 문서가 정정하는 선행 조사 항목

| 선행 권고 | 정정 |
|---|---|
| #16 core/config/local 3계층 물리 분리 | 유효. Copier를 택할 경우 `_skip_if_exists`가 config 계층에 대응한다 |
| #17 배포 매니페스트에 파일별 해시 | **해시만으로는 부족하다.** 재현용 `sha`와 드리프트용 `contentHash`가 별개 필드다(§2.2). 3-way merge 기반 메커니즘에서는 충돌 마커가 드리프트 검출을 대신할 수 있다(§4.2) |
| #17 gitignore 통짜 무시 제거 | 유효하며 **우선순위가 올라간다.** 정리 항목이 아니라 3-way merge의 동작 전제조건이다 |
| §7.9.3 전파 전략 (a)/(b) 이분법 | 제3의 형태가 존재한다 — 드리프트를 없애는 대신 충돌로 노출하는 방식. (b)의 실패 모드가 완화된다 |
| §7.9.4 "3단계는 미룬다" | 미룰 근거가 약해졌다. 1·2단계(경계·검출)를 배포 메커니즘 안에 포함하는 선택지가 존재한다 |
| #18·#19 이슈 기반 지식 반영 | **유효하며 대체되지 않는다.** 어느 배포 메커니즘도 배포 방향만 다룬다. (C)/(D) 유형에는 diff가 존재하지 않으므로 이슈가 유일한 경로다 |

---

## 8. 미해결 사항

1. ~~**태스크 실패 시 update 중단 여부** — 격리 실험 미실시(§4.4).~~ **실험 B4(2026-08-03)에서 해소 — [§9.3](#93-b4--_tasks-실패는-update를-중단시키지-않는다).** **중단시키지 못한다.** 종료 코드만 1이고 파일 변경·핀 갱신이 모두 적용된 채 남는다. **§5.1이 상정한 구조가 `_tasks`로는 성립하지 않으며, 검사는 update 앞에 두어야 한다.**
2. **`_tasks`의 실제 실행 디렉터리** — 중간 렌더가 임시 디렉터리에서 도는지 미확인. 스캐폴드·seed 태스크가 엉뚱한 곳에서 먼저 실행될 수 있다.
3. ~~**concat-인라인 블록 미검증**~~ **실험 B3(2026-08-03)에서 해소 — [§9.1·§9.2](#91-b3--concat-인라인-블록은-정상-동작한다).** copier 쪽은 정상 동작한다(생성·재생성·로컬 편집 보존). **그런데 제약은 다른 곳에 있었다** — Codex의 `project_doc_max_bytes` 기본값이 **32 KiB**인데 인라인 대상이 **40,626바이트(1.24배)** 다. **"동작하지만 담기지 않는다."**
4. **심볼릭 링크를 통한 `@import` 해석** — 스킬 디렉터리 순회는 확인했으나(§2.2), `@.tack/rules/foo.md`가 심볼릭 링크된 `.tack/`를 통해 해석되는지는 미확인이다. 다른 코드 경로다.
5. **Codex의 심볼릭 링크된 AGENTS.md 읽기** — 미확인. 위와 같은 부류.
6. **Claude Code의 AGENTS.md 네이티브 지원 여부** — 로컬 changelog에서 언급을 찾지 못했고 §6의 출처는 미지원으로 서술한다. 바뀔 수 있는 사실이다.
7. **상시/온디맨드 분류의 실제 경계** — §6.3의 기준은 원칙이고, 22KB를 실제로 가르는 작업은 미착수다.
8. **블록 재생성의 검증 지점** — §4.5. 작업 수행과 수행 여부 확인을 분리해야 하는데 후자를 어디에 둘지 미정.
9. **충돌 해소 후의 복구 흐름** — 원본에 충돌이 있어 블록 재생성이 멈췄을 때, 사람이 해소한 뒤 다시 만드는 경로가 필요하다.

---

## 9. 실험 B3·B4 — concat-인라인과 태스크 실패 (2026-08-03 실시)

§8-3(concat-인라인 미검증)과 §8-1(태스크 실패 시 update 중단 여부)을 실행으로 닫는다. **부록 A의 템플릿을 concat-인라인 형태로 바꿔 재사용했다.** `uvx copier`, 격리 임시 디렉터리.

### 9.1 B3 — concat-인라인 블록은 정상 동작한다

경로 목록형(`@.tack/rules/...`)이 아니라 **규칙 본문을 마커 사이에 넣는** `_tasks` 스크립트로 바꿔 v1 생성 → 프로젝트 섹션 편집 → v2(규칙 추가) update를 돌렸다.

| 확인 | 결과 |
|---|---|
| 생성 시 본문 인라인 | **성공** — `<!-- from: .tack/rules/a.md -->` 주석과 함께 본문이 들어간다 |
| update 시 블록 재생성 | **성공** — 새 규칙이 블록에 추가된다 |
| **사람이 편집한 프로젝트 섹션** | **보존됨** |
| `_tasks` 실행 횟수 | **3회** (`233 → 340 → 288` 바이트) — §4.3·§4.4 관측 재현 |

**§8-3이 닫힌다 — copier 쪽에는 문제가 없다.** 경로 목록형과 같은 방식으로 동작한다.

### 9.2 그런데 진짜 제약은 copier가 아니라 Codex다

**§6.2의 전제(*"Codex는 `@import`를 지원하지 않는다"*)를 공식 문서로 재확인하는 과정에서 더 무거운 제약을 찾았다.**

[공식 AGENTS.md 가이드](https://learn.chatgpt.com/docs/agent-configuration/agents-md)가 규정한다.

- 임포트·인클루드 구문은 **없다** (§6.2의 전제 유효)
- 탐색은 전역(`~/.codex/AGENTS.override.md` → `~/.codex/AGENTS.md`) → 프로젝트 루트에서 현재 디렉터리까지 하향 순회
- 병합은 *"concatenated from the root down"*, 가까운 디렉터리가 우선
- **상한**: *"stops adding files once the combined size reaches the limit defined by `project_doc_max_bytes` (**32 KiB by default**)"*
- 권고: *"Raise the limit or split instructions across nested directories when you hit the cap."*

[설정 레퍼런스](https://learn.chatgpt.com/docs/config-file/config-reference)의 표현은 *"Maximum bytes read from `AGENTS.md` when building project instructions"* 다.

**하네스를 재료로 크기를 쟀다.**

| 항목 | 바이트 |
|---|---:|
| 현재 `AGENTS.md` | 21,714 (상한의 **66%**) |
| **인라인 대상 전량** (`harness-guide.md` + 규칙 7개) | **40,626** |
| `project_doc_max_bytes` 기본값 | 32,768 |

**40,626 / 32,768 = 1.24배 — 초과한다.**

**즉 §6.2가 검토한 "전부 인라인" 방식은 기본 설정에서 성립하지 않는다.** copier가 블록을 만들어 주더라도 Codex가 끝까지 읽지 않는다. **§8-3의 답은 "동작한다"가 아니라 "동작하지만 담기지 않는다"이다.**

**공식 문서가 주는 대응은 둘이다** — `project_doc_max_bytes`를 올리거나, **중첩 디렉터리로 쪼개는 것**. 후자가 §6.2가 찾던 "`@import` 없이 규칙을 나누는 방법"의 공식 답에 해당한다. 다만 그것은 **디렉터리 구조가 곧 규칙 구조가 된다**는 뜻이라 [지시 계층 조사](instruction-layers.md)의 상시 로드 예산 문제와 다시 만난다.

> **미검증**: 단일 파일이 상한을 넘을 때 **잘리는지 통째로 빠지는지** 확인하지 않았다. 가이드는 *"stops adding **files**"*, 설정 레퍼런스는 *"Maximum **bytes read**"* 로 표현이 갈린다. **어느 쪽이든 초과분이 조용히 사라진다는 결론은 같다.**

### 9.3 B4 — `_tasks` 실패는 update를 중단시키지 않는다

v3에서 규칙 하나를 추가하고 **동시에 `_tasks` 스크립트를 `exit 1`로 바꿔** update를 돌렸다(§5.1의 "충돌 마커 검사가 실패를 던지는" 상황을 모사).

```
$ copier update --vcs-ref v3
[sync-inline] 인라인 완료: 288 바이트          ← 1회차는 성공
[sync-inline] 의도적 실패 — 충돌 마커 검출을 가정
Task 'bash .tack/scripts/sync-inline.sh' returned non-zero exit status 1.
exit=1
```

**종료 코드는 1이다. 그런데 상태는 이미 바뀌어 있다.**

| 확인 | 결과 |
|---|---|
| 새 파일(`d.md`) 생성 | **적용됨** |
| 스크립트 파일 교체 | **적용됨** |
| **핀 `_commit`** | **`v2` → `v3`으로 갱신됨** |
| 롤백 | **없음** |

**§8-1이 닫힌다 — 그리고 답이 불리하다.**

**`_tasks`에 검사를 걸어 실패시켜도 재생성을 막지 못한다.** 파일 변경이 이미 적용되었고, **핀이 올라갔으므로 실패했다는 사실이 상태에 남지 않는다.** 다음 `copier update`는 v3을 기준선으로 시작한다.

**§5.1이 상정한 "충돌 마커 검사가 재생성을 막는다"는 구조가 `_tasks`로는 성립하지 않는다.** 검사를 두려면 **update 앞** — 별도 게이트 — 이어야 한다.

### 9.4 부수 관측 — dirty 저장소는 거부한다

실험 도중 프로젝트 디렉터리에 추적되지 않은 파일이 있을 때 update가 거부됐다.

> `Destination repository is dirty; cannot continue. Please commit or stash your local changes and retry.`

**§4.2가 "추적되어야 3-way merge가 산다"고 한 것과 짝이 되는 안전장치다.** copier가 **깨끗한 상태를 전제로만 동작한다.** [상태·연속성 조사](state-and-continuity.md) §6의 "매 세션이 깨끗한 상태를 남겨야 한다"와 같은 방향의 요구다.

### 9.5 이 실험이 답하지 않은 것

- **단일 파일이 32 KiB를 넘을 때의 정확한 동작**(§9.2 미검증 상자).
- **`_tasks` 3회 실행 중 어느 회차에서 실패하느냐에 따라 부분 적용이 달라지는지** 확인하지 않았다. 이번에는 1회차가 성공하고 2회차가 실패했다.
- **update 전 게이트를 어디에 둘 것인가**(§9.3의 결론이 요구하는 것). copier에 pre-update 훅이 있는지 확인하지 않았다.
- **중간 실행이 최종보다 큰 파일을 만든 이유**(340 → 288 바이트). §4.4의 "중간 상태 트리를 본다"와 관련 있어 보이나 추적하지 않았다.
- **copier를 쓸지 자체가 미정이다.** 배포 메커니즘 선택은 여전히 보류 상태이며, 이 실험은 그 선택지 하나의 성질을 잰 것이다.

---

## 부록 A. 재현 스크립트

§4의 결과를 재현한다. `uv` 필요. 임시 디렉터리에서 실행할 것.

```bash
set -euo pipefail
ROOT="$(mktemp -d)"; cd "$ROOT"

# ---------- 템플릿 저장소 ----------
mkdir -p tmpl/template/.claude tmpl/template/.tack/rules tmpl/template/.tack/scripts
cd tmpl

cat > copier.yml <<'YAML'
_subdirectory: template
_answers_file: .copier-answers.yml
_skip_if_exists:
  - CLAUDE.md
_tasks:
  - "bash .tack/scripts/sync-block.sh"
YAML

# 핀을 담는 파일 — 이것이 없으면 copier update 불가 (§4.1)
printf '{{ _copier_answers|to_nice_yaml }}\n' \
  > 'template/{{ _copier_conf.answers_file }}.jinja'

cat > template/.tack/scripts/sync-block.sh <<'SH'
#!/usr/bin/env bash
set -euo pipefail
f="CLAUDE.md"
[ -f "$f" ] || { echo "[sync-block] CLAUDE.md 없음 — 건너뜀"; exit 0; }
grep -q "<!-- harness-rules:begin -->" "$f" || { echo "[sync-block] 마커 없음 — 경고 후 건너뜀"; exit 0; }
tmp_list="$(mktemp)"; trap 'rm -f "$tmp_list" "$f.tmp"' EXIT
find .tack/rules -name '*.md' -type f 2>/dev/null | sort | sed 's|^|@|' > "$tmp_list"
awk -v listfile="$tmp_list" '
  /<!-- harness-rules:begin -->/ { print; while ((getline l < listfile) > 0) print l; close(listfile); skip=1; next }
  /<!-- harness-rules:end -->/   { skip=0 }
  !skip
' "$f" > "$f.tmp"
mv "$f.tmp" "$f"
echo "[sync-block] 블록 재생성 완료 ($(wc -l < "$tmp_list" | tr -d ' ')개 규칙)"
SH
chmod +x template/.tack/scripts/sync-block.sh

cat > template/CLAUDE.md <<'MD'
# 프로젝트

(프로젝트 섹션)

<!-- harness-rules:begin -->
<!-- harness-rules:end -->
MD

printf 'core rule v1\n'    > template/.claude/core.md
printf 'coding style v1\n' > template/.tack/rules/coding-style.md

git init -q . && git add -A
git -c user.email=t@t -c user.name=t commit -qm v1 && git tag v1.0.0

# v2: core 파일 변경 + 규칙 파일 추가
printf 'core rule v2 — upstream 개선\n' > template/.claude/core.md
printf 'security v1\n'                  > template/.tack/rules/security.md
git add -A && git -c user.email=t@t -c user.name=t commit -qm v2 && git tag v2.0.0

# ---------- A. gitignore된 프로젝트 (§4.2) ----------
cd "$ROOT"; mkdir projA; cd projA
git init -q .; printf '.claude\n.tack\n' > .gitignore
git add -A && git -c user.email=t@t -c user.name=t commit -qm init -q
uvx copier@latest copy --trust --vcs-ref v1.0.0 ../tmpl . >/dev/null 2>&1
git add -A && git -c user.email=t@t -c user.name=t commit -qm v1 -q
printf 'core rule v1\n로컬에서 추가한 규칙\n' > .claude/core.md   # 로컬 수정
uvx copier@latest update --trust --vcs-ref v2.0.0 2>&1 | tail -3
echo "--- A 결과 (로컬 수정이 남아 있는가) ---"; cat .claude/core.md

# ---------- B. 추적되는 프로젝트 (§4.2) ----------
cd "$ROOT"; mkdir projB; cd projB
git init -q .; printf 'node_modules/\n' > .gitignore
git add -A && git -c user.email=t@t -c user.name=t commit -qm init -q
uvx copier@latest copy --trust --vcs-ref v1.0.0 ../tmpl . >/dev/null 2>&1
git add -A && git -c user.email=t@t -c user.name=t commit -qm v1 -q
printf 'core rule v1\n로컬에서 추가한 규칙\n' > .claude/core.md
git add -A && git -c user.email=t@t -c user.name=t commit -qm "local tweak" -q
uvx copier@latest update --trust --vcs-ref v2.0.0 2>&1 | tail -5
echo "--- B 결과 (충돌 마커가 뜨는가) ---"; cat .claude/core.md; git status --short
echo "--- B: 블록 재생성 결과 (§4.3) ---"; cat CLAUDE.md
```

**기대 결과**

| | A (gitignore됨) | B (추적됨) |
|---|---|---|
| `.claude/core.md` | 로컬 수정 소실, `core rule v2`만 | `<<<<<<< before updating` 충돌 마커 |
| `git status` | 충돌 없음 (`.copier-answers.yml`·`CLAUDE.md`만 변경) | `UU .claude/core.md` |
| `CLAUDE.md` 블록 | `@.tack/rules/security.md` 자동 추가 | 좌동 |

**이 스크립트는 문서에 실린 그대로 실행해 위 결과를 확인했다.**

**변형 — §5.1 재현**: 로컬 수정 대상을 `.claude/core.md`에서 `.tack/rules/coding-style.md`로 바꾸고, v2 단계에서 `printf 'coding style v2 — upstream 개선\n' > template/.tack/rules/coding-style.md` 한 줄을 추가한다. `UU .tack/rules/coding-style.md`가 나고, 재생성된 블록이 충돌 마커가 든 그 파일을 그대로 싣는 것을 확인할 수 있다.

---

## 부록 B. 검증한 것과 검증하지 않은 것

**직접 확인 (1차 관측)**

- `.harness/.deploy-manifest.json`이 ignore 블록에 포함됨 — `harness:scripts/deploy-harness.sh:184`
- cygnus `.gitignore` 173~175행의 통짜 무시
- 하네스 `.gitignore` 35행의 `AGENTS.md` 무시
- 플러그인 마켓플레이스의 `ref`/`sha` 핀 — `~/.claude/plugins/marketplaces/claude-plugins-official/.claude-plugin/marketplace.json`
- `enabledPlugins` / `extraKnownMarketplaces` 실사용 — `~/Workspace/dotu/.claude/settings.json`, `~/.claude/settings.json`
- 플러그인 `SessionStart` 훅 — superpowers 5.0.6 `hooks/hooks.json`
- Claude Code가 심볼릭 링크된 스킬 디렉터리를 따라감 — `~/.claude/skills/cmux-*` → `~/.agents/skills/*`
- `.skill-lock.json`에 `ref`/`commit`이 없고 `skillFolderHash`만 있음
- §4·§5.1 전체 — 이 문서 작성 중 실행한 Copier 실험

**출처 인용 (재현하지 않음)**

- AGENTS.md 표준화 경위, 채택 규모, 210회 성능 실험 — §6 출처의 저자 주장

**출처 감사 (2026-08-02 보강)**

- ~~ETH Zurich 연구 결론 — 위 자료의 인용~~ → **원문 확인 완료**. [arXiv 2602.11988](https://arxiv.org/abs/2602.11988) 초록을 직접 읽어 §6.3에 정정을 실었다. **2차 인용이 원문을 잘못 특징지었음이 확인됐다** — 문제는 "자동 생성"이 아니라 "저장소 개요라는 내용 종류"이고, 개발자 작성 파일도 마찬가지였다. 초록까지만 확인했고 본문(AGENTbench 구성, 모델별 분해, 통계 처리)은 읽지 않았다.
- **이 건이 드러낸 것**: 최초 조사에서 이 결론은 판단의 입력이 아니라 부수 인용이었으므로 실질 피해는 없었다. 그러나 **2차 인용을 그대로 옮긴 것 자체가 결함**이며, 같은 방식으로 실린 §6의 다른 저자 주장(표준화 경위, 6만 저장소 채택, 210회 실험)은 여전히 미검증이다.


**2026-08-02 재구성**: 외부 자료를 「구현 참조 자료」 절로 앞당겨 모았고 1차 관측 절을 보조 근거로 재프레이밍했다. **절 번호는 유지했다** — 조사 문서 8건이 서로를 §번호로 참조하므로 재번호는 그 링크 그래프를 조용히 깨뜨린다.

**미확인** — §8 참조.
