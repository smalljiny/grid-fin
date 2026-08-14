# 상태와 연속성 — 조사

**최초 작성**: 2026-08-02
**최종 수정**: 2026-08-02
**대상 프로젝트**: grid fin (신규 개인용 개발 하네스)
**1차 관측 대상**: cygnus `docs/_local/{dev-context.json,HANDOFF.md}`, `.claude/sessions/*.jsonl`, git 이력 208커밋; `/Users/mario/Workspace/harness` — `.harness/scripts/dev-context.js`, `flow-checkpoint`, `flow-init`, `wf-compact`, `session-start.js`, `memory-persist.js`
**조사 도구**: WebFetch 1회(피어리뷰 서베이 본문), 로컬 저장소 직접 검사
**성격**: 조사. 상태 매체와 체크포인트 구조의 선택은 하지 않는다.

선행 문서
- [research-agenda.md](research-agenda.md) §9 — 이 조사의 출처
- [workflow-and-feature-list.md](workflow-and-feature-list.md) §1.1·§3.2 — 토픽 상태 기계, "프로젝트 수준 지속 산출물이 없다"
- [harness-distribution.md](harness-distribution.md) §1.2 — gitignore 통짜 무시
- [error-recurrence-prevention.md](error-recurrence-prevention.md) §6.1·§8 — 학습 44% 유실, "기록은 있고 소비가 없다"

---

## 0. 조사 요약

### 0.1 두 문장

**상태가 여덟 곳에 나뉘어 있고 쓰기 경로의 보호 수준이 제각각이다.** 그리고 연속성을 위해 만들어진 장치 넷이 전부 죽어 있는데, 죽은 이유가 서로 달라 대응도 달라진다.

### 0.2 관측

| # | 관측 | 근거 | 등급 |
|---|---|---|---|
| 1 | **상태 보유자가 8종이고 그중 추적되는 것은 2종뿐이다** | §1.1 | 1차 |
| 2 | **worktree와 main hub의 `dev-context.json`이 갈라진다** — `flow-worktree` 스킬 자신이 main hub 쪽이 stale하게 남는다고 명시한다. 상태 보유자가 워크트리 수만큼 늘어난다 | §1.3 | 1차 |
| 3 | **`flow-checkpoint` 스킬은 존재하는데 `checkpoints.log`가 생성된 적이 없다** | §1.2 | 1차 |
| 4 | **`memory-persist` Stop 훅은 이름과 달리 `updatedAt` 한 줄만 갱신한다** | §1.2 | 1차 |
| 5 | **세션 시작 안내 문구가 존재하지 않는 `/dev:impl`을 가리킨다.** 복원 자체(phase·currentStory·plan 출력)는 정상 동작한다 | §1.2 | 1차 |
| 6 | **아젠다 §9-1의 "JSON이 Markdown보다 오편집에 강하다"는 형식 문제가 아니다.** 변수는 **쓰기 경로**이며, 같은 JSON 안에서도 보호 수준이 세 단계로 갈린다 | §2 | 1차 |
| 7 | **git이 이미 신뢰 가능한 토픽 기록이다** — 머지 커밋 **21건**이 리뷰된 21개 토픽과 1:1 대응하고 브랜치명이 토픽명이다 | §3.1 | 1차 |
| 8 | **git이 담는 것은 토픽 단위까지다.** Story 완료·리뷰 처리·결정 근거는 전부 비추적 `docs/_local/`에 있다 | §3.2 | 1차 |
| 9 | **`flow-checkpoint`는 체크포인트가 아니라 마커다.** 기본 옵션이 "log only"라 SHA만 적고 작업 트리를 잡지 않는다 | §4.2 | 1차 + 문헌 |
| 10 | **상태 보유자가 여럿인데 체크포인트가 하나만 잡으므로 조율되지 않은(uncoordinated) 체크포인트다** — 복원 시 고아 상태가 생긴다 | §4.3 | 1차 + 문헌 |
| 11 | **`/flow-pr`·`gh issue create`가 output commit 지점이다** — 되돌릴 수 없는 외부 출력이 복구 보장 없이 나간다 | §4.4 | 1차 + 문헌 |
| 12 | **`force-state`는 상태 어휘는 검증하고 전이 순서는 검증하지 않는다** | §2.2 | 1차 |

### 0.3 출처

**아젠다 §9는 참고 자료로 강의 6·12(walkinglabs)를 들었다. 이 조사는 쓰지 않았다.** [출처 감사](research-agenda.md#출처-감사-2026-08-02-실시)가 같은 자가출판 출처에 세 문서가 의존한 것을 문제로 지목했고, 이 문서가 따라가면 네 번째가 된다.

대신 두 축으로 대체했다.

| 등급 | 자료 | 쓰임 |
|---|---|---|
| **공식 문서** | [Claude Code — Checkpointing](https://code.claude.com/docs/en/checkpointing) | **§4.0** — 플랫폼이 이미 제공하는 체크포인트의 범위와 **한계 목록**. 자체 구현 여부를 가르는 1차 자료 |
| **피어리뷰 서베이** | [Elnozahy, Alvisi, Wang, Johnson, *A Survey of Rollback-Recovery Protocols in Message-Passing Systems*, **ACM Computing Surveys 34(3), 2002**](https://www.cs.utexas.edu/~lorenzo/papers/SurveyFinal.pdf) | §4.1~4.4 — 어휘와 판별 기준 |
| **1차 관측 (보조)** | cygnus·하네스 저장소 직접 검사, git 이력 208커밋 집계 | 위 자료가 이 프로젝트에 해당하는지 확인 |

> **2026-08-02 보강 경위.** 초판은 외부 자료가 Elnozahy 하나뿐이었고 나머지가 전부 기존 하네스 관측이었다. **자체 `flow-checkpoint`를 분석하면서 플랫폼이 이미 무엇을 주는지 확인하지 않은 것**이 그 불균형의 구체적 형태였다. §4.0을 추가해 순서를 바로잡았다 — **무엇을 만들지 정하기 전에 무엇이 공짜인지가 먼저다.**

> **서베이를 쓰는 방식에 유의.** 이 문헌은 메시지 전달 분산 시스템의 장애 복구 프로토콜을 다루고, 하네스는 그런 시스템이 아니다. **정리(theorem)를 빌리는 것이 아니라 판별 어휘를 빌린다** — 무엇이 일관된 체크포인트인가, 고아 상태란 무엇인가, 도미노 효과는 어떤 조건에서 생기는가. 이 개념들은 **독립적으로 갱신되는 상태 보유자가 여럿**일 때 성립하며, 그 조건은 하네스에 실재한다(§1.1). 성능·확장성 논의는 전이시키지 않았다.

---

## 구현 참조 자료 — 외부 자료 정리

> **이 절의 쓰임.** 구현 시 참조할 형태로 모았다. **§4.0(플랫폼 네이티브 체크포인팅)이 이 문서에서 가장 직접 쓸 자료이므로 여기에 요약하고 상세는 그 절에 둔다.**

### A. 플랫폼이 이미 주는 것 — Claude Code 체크포인팅

[공식 문서](https://code.claude.com/docs/en/checkpointing) (본문 확인). **자체 체크포인트를 만들기 전에 확인할 것.**

| 항목 | 내용 |
|---|---|
| 생성 | **매 사용자 프롬프트마다 자동** |
| 대상 | Claude의 **파일 편집 도구**가 만든 변경의 스냅샷 |
| 보존 | 세션당 최근 **100개**, 대화와 함께 저장되어 resume 후에도 유효 |
| 만료 | **30일** (`cleanupPeriodDays`) |
| 복원 | 코드+대화 / 대화만 / 코드만 / 요약(앞·뒤) |

**추적하지 않는 것 — 이 목록이 자체 구현 여부를 가른다**:

| 미추적 | 원문 |
|---|---|
| **Bash 명령이 바꾼 파일** | *"Checkpointing does not track files modified by bash commands"* |
| **서브에이전트 편집** | *"rewinding doesn't restore them… Use git to revert those edits."* |
| 세션 밖·동시 세션 변경 | *"normally not captured"* |
| 심볼릭·하드 링크 경로 | 건너뛰고 경고 |

**위치 규정**: *"Think of checkpoints as 'local undo' and Git as 'permanent history.'"* — *"complement but don't replace proper version control."*

### B. 복구 어휘 — Elnozahy et al., ACM Computing Surveys 34(3) 2002

[서베이](https://www.cs.utexas.edu/~lorenzo/papers/SurveyFinal.pdf) (본문 확인). **정리가 아니라 판별 어휘를 빌린다.**

| 개념 | 정의 (원문) |
|---|---|
| **일관된 상태** | *"if a process's state reflects a message receipt, then the state of the corresponding sender reflects sending that message"* |
| **고아(orphan)** | 대응하는 발신 없이 수신만 반영된 상태 |
| **도미노 효과** | *"rollback propagation may extend back to the initial state of the computation, losing all the work performed before a failure"* — **조율되지 않은(uncoordinated) 체크포인팅에서 발생** |
| **output commit** | *"before sending a message (output) to OWP, the system must ensure that the state from which the message is sent will be recovered despite any future failure"* |

**두 갈래 해법**:

| 전략 | 성질 |
|---|---|
| **조율된 체크포인팅** | 모든 상태 보유자를 같은 시점에 함께 저장. 도미노 없음. 가비지 컬렉션 단순 |
| **메시지 로깅** | 체크포인트 + 결정 로그로 재생. ***"log-based recovery generally is not susceptible to the domino effect"*** |

> **적용 조건**: 이 개념들은 **독립적으로 갱신되는 상태 보유자가 여럿**일 때 성립한다. 하네스에 그 조건이 실재한다(§1.1의 8종, §1.3의 워크트리 배수). **다만 로그 기반 복구는 piecewise-deterministic 가정에 기대고 LLM 호출은 그것을 만족하지 않는다**(§7-4).

### C. 상태 매체에 관한 판별 — 이 문서의 1차 도출

아젠다 §9-1은 *"JSON이 Markdown보다 오편집에 강하다"* 를 물었으나 **§2가 형식 가설을 반증한다.** 같은 JSON 파일 안에서 보호가 세 단계로 갈리므로 형식이 변수일 수 없다.

**변수는 쓰기 경로다** — 검증하는 단일 경로를 두고 직접 편집을 막는 것. 형식 중립적이며, 강제 수단은 [강제 메커니즘 B](enforcement-mechanisms.md)의 `permissions.deny`다.

> **그리고 이 선택에 상충이 있다**(§4.0) — 스크립트로 쓰면 오편집에 강해지지만 **바로 그 때문에 네이티브 체크포인팅이 추적하지 못한다.** 보호와 복구 가능성이 같은 결정에 묶여 있다(§7-10).

### D. 다른 조사와 맞물리는 지점

| 지점 | 연결 |
|---|---|
| A의 Bash 미추적 | [배포 B](harness-distribution.md)의 gitignore와 **독립적으로 같은 상태 보유자를 놓친다**(§4.0) |
| A의 서브에이전트 미복원 | [검증·교차리뷰 §2.1](verification-and-cross-review.md) — 코드리뷰 21건 전부에서 서브에이전트가 실행됐다 |
| B의 output commit | [오류 재발 §7.10.5](error-recurrence-prevention.md)가 `/flow-pr`을 이슈 생성 강제 지점으로 제안 — **같은 지점에 두 요구가 겹친다** |
| C의 쓰기 경로 | [워크플로우 §1.3](workflow-and-feature-list.md)의 "판정자와 기록자가 같다"와 같은 사실의 다른 각도 |

---

## 1. 1차 관측 — 상태는 어디에 있나

> **이 절부터 §6까지는 기존 하네스 실측이며, 위 자료가 이 프로젝트에 어떤 규모로 해당하는지 확인하는 보조 근거다.**

### 1.1 상태 보유자 8종

| # | 보유자 | 매체 | 쓰기 경로 | 추적 | 담는 것 |
|---|---|---|---|---|---|
| 1 | `docs/_local/dev-context.json` | JSON | **`dev-context.js` (검증 있음)** + `memory-persist` 훅 | ✗ | 활성 토픽의 phase·status·산출물 경로·currentStory |
| 2 | `implementation-plan.md` 체크박스 | Markdown | **에이전트 `Edit` (검증 없음)** | ✗ | Story·Task·Criterion 완료 |
| 3 | **git 커밋·머지** | git | git (사후 불변) | **✓** | 토픽 완료, 변경 내용 |
| 4 | `spec-review-*` · `plan-review-*` · `review-report-*` | Markdown | Codex / 에이전트 | ✗ | 지적과 처리 내역 |
| 5 | `docs/_local/HANDOFF.md` | Markdown | **사람 수동 (하네스 밖)** | ✗ | **병렬 워크트리 조율** — 활성 트랙, 다음 착수 후보, 파일 충돌 주의 |
| 6 | `docs/roadmap/roadmap.html` | HTML | 사람 | **✓** | 로드맵 |
| 7 | `.claude/sessions/*.jsonl` (14건) | JSONL | `session-logger` 훅 (`async`) | ✗ | 도구 호출 이력 |
| 8 | `.claude/checkpoints.log` | 텍스트 | `flow-checkpoint` 스킬 | ✗ | **미생성** |

**8종 중 추적되는 것은 2종(git, roadmap)뿐이다.** 나머지는 `docs/_local/`(`.gitignore` 171행)와 `.claude/`(통짜 무시, [배포 조사 §1.2](harness-distribution.md)) 아래에 있다.

`dev-context.json`의 실측 내용도 짚어둘 만하다 — 토픽이 **1건**뿐이고 상태는 `plan:confirmed`다. 그런데 같은 프로젝트에 완료된 토픽이 21개 있다(리뷰 산출물 기준). **완료 토픽은 이 파일에서 제거된다.** [워크플로우 조사 §3.2](workflow-and-feature-list.md)가 "완료된 기능이 여전히 동작하는지는 담지 않는다"고 한 것의 실물 확인이다.

### 1.2 하네스가 만든 연속성 장치 3종이 죽어 있다 — 그런데 이유가 각각 다르다

> **`HANDOFF.md`는 이 표에서 제외한다.** 초판은 이 파일을 "소유자 없이 방치된 연속성 장치"로 분류했으나 **오독이었다.** 이 파일은 하네스 산출물이 아니라 **사용자가 병렬 워크트리를 조율하려고 직접 쓰는 임시 운영 노트**이고, 헤더가 스스로 성격을 밝힌다 — *"세션마다 이 파일 하나를 최신 상태로 덮어쓴다"*, *"`docs/_local`은 git-ignored — main hub 로컬 코디네이션 전용"*. 정정 내용은 §3.2에 정리했다.

| 장치 | 상태 | 죽은 이유 | 대응이 달라지는 지점 |
|---|---|---|---|
| `checkpoints.log` | **미생성** | **미호출** — `flow-checkpoint` 스킬(124줄)은 완비되어 있으나 실행 이력이 없다 | 만들어졌으나 파이프라인에 걸려 있지 않다. 선행 조사가 학습 루프에서 관측한 것과 같은 실패 |
| `memory-persist` (Stop 훅) | 동작하나 무의미 | **범위 축소** — 이름은 상태 영속화인데 구현은 `updatedAt` 한 줄 갱신 | 코드가 도는데 아무것도 보존하지 않는다 |
| `session-start` 안내 문구 | 복원은 동작, 안내는 오도 | **화석** — 존재하지 않는 `/dev:impl`을 가리킨다 | 셋 중 유일하게 **고치기 쉽다**(문자열 한 줄). 다만 세션 첫 화면이라 눈에 띈다 |

**`memory-persist.js` 전문의 실질은 세 줄이다.**

```javascript
// Stop 훅: 세션 종료 시 현재 상태를 dev-context.json에 저장한다.
context.topics[topic].updatedAt = new Date().toISOString()
writeFileSync(contextPath, JSON.stringify(context, null, 2) + '\n', 'utf-8')
```

주석은 *"현재 상태를 저장한다"* 고 하는데 저장되는 것은 타임스탬프뿐이다. **세션 종료 시점의 진행 상황을 담는 장치가 이름만 있고 실체가 없다.**

**`session-start.js`가 더 뾰족하다.** 매 세션 첫 출력이다.

```javascript
console.log(`[컨텍스트 복원] 주제: ${topic} | phase: ${topicData.phase}`)
console.log(`[컨텍스트 복원] 다음 Story: ${topicData.currentStory}`)
console.log(`  → /dev:impl 로 계속하세요.`)
```

**앞 두 줄은 정상 동작한다** — `phase`·`currentStory`·`plan` 경로가 `dev-context.json`에서 제대로 읽혀 출력된다. 깨진 것은 세 번째 줄의 안내 문구뿐이고 `/dev:impl`은 존재하지 않는다. [강제 메커니즘 조사 §1.2](enforcement-mechanisms.md)가 `git-push-review.js`에서 찾은 `/dev:review`와 같은 부류다.

**즉 복원이 깨진 것이 아니라 다음 행동 안내가 깨졌다.** 피해는 제한적이지만 세션 첫 화면이라 매번 보이고, 고치는 비용은 문자열 한 줄이다.

### 1.3 워크트리를 쓰면 상태 보유자가 더 늘어난다

§1.1의 8종은 **단일 작업 트리 기준**이다. 하네스에는 워크트리 격리 체계가 있고(`flow-worktree`, `wf-worktree-context`), 그 설계는 **워크트리마다 별도 `docs/_local`과 별도 `dev-context.json`을 주입**한다.

그리고 `flow-worktree` SKILL.md가 그 귀결을 스스로 기록한다.

> *"worktree 의 `/flow-done` 은 worktree dev-context 에서만 토픽을 제거한다. **main hub 의 dev-context 에는 프로비저닝 시점 상태(예: plan:confirmed)로 stale 하게 남는다.**"*

**같은 토픽에 대해 두 개의 `dev-context.json`이 서로 다른 상태를 말하는 구간이 설계상 존재한다.** 스킬은 이를 인지하고 수동 정리 절차를 제시한다(main hub에서 토픽 제거).

또 하나:

> *"`docs/_local/done/<topic>/`(git-ignored, worktree 에만 존재) → **sync-back**(teardown.sh). 이후 main 의 stale 원본 backlog/active 핸드오프본은 폐기된다."*

즉 산출물도 워크트리 쪽이 정본이 되었다가 teardown 시 main으로 되돌아온다. **정본의 위치가 시점에 따라 바뀐다.**

이것이 §4.3의 다중 보유자 문제를 확대한다 — 워크트리 N개를 돌리면 보유자가 8종이 아니라 **8 + N×2 종**이 되고, 그중 어느 것도 git이 조율하지 않는다(전부 `docs/_local` 아래, 비추적).

> 관측된 cygnus 실적으로는 동시 활성 워크트리가 최대 2개였고(`child-pairing`·`weekly-payout`), 현재는 0이다. **규모가 작아 아직 문제가 드러나지 않았을 수 있다**(§7-10).

---

## 2. §9-1 재구성 — 변수는 형식이 아니라 쓰기 경로다

아젠다 §9-1은 *"진행 상태는 JSON이 Markdown보다 에이전트 오편집에 강하다는 실무 보고의 근거"* 를 물었다. **이 조사의 1차 관측은 그 인과가 형식에 있지 않음을 보인다.**

### 2.1 같은 저장소에 대조군이 있다

| | `dev-context.json` | `implementation-plan.md` 체크박스 |
|---|---|---|
| 형식 | JSON | Markdown |
| 쓰기 경로 | **`dev-context.js` 서브커맨드** | **에이전트의 `Edit` 도구** |
| 검증 | `PROTECTED_FIELDS`, `VALID_TRANSITIONS`, 예약어 거부 | 없음 |
| 오편집 저항 | 높음 | 없음 |

**JSON이 강한 것이 아니라 스크립트를 거치는 것이 강하다.** 반례를 만들어 보면 분명하다 — `dev-context.json`을 `Edit` 도구에 노출하면 보호가 사라지고, 같은 상태를 Markdown에 담아 같은 스크립트 뒤에 두면 보호가 유지된다. **형식은 검증의 구현 난이도에 영향을 줄 뿐이고**(JSON 스키마 검증이 Markdown 파싱보다 쉽다), 저항의 원천이 아니다.

이는 [워크플로우 조사 §1.3](workflow-and-feature-list.md)이 발견한 비대칭 — 토픽 수준은 스크립트가 막고 Story 수준은 안 막는다 — 과 **같은 사실의 다른 각도**다. 그쪽은 "누가 막는가"를 물었고 이쪽은 "무엇이 막아주는가"를 묻는다. 답은 같다.

### 2.2 같은 JSON 안에서도 보호가 세 단계로 갈린다

이 관측이 형식 가설을 결정적으로 반증한다. **하나의 `dev-context.json`인데 필드마다 보호 수준이 다르다.**

| 보호 단계 | 대상 | 경로 | 검증 내용 |
|---|---|---|---|
| **강** | `phase` · `status` | `update-state` | `VALID_TRANSITIONS` 전이표 대조. `set-field`로는 아예 불가(`PROTECTED_FIELDS`) |
| **중** | `phase` · `status` (강제 경로) | **`force-state`** | 상태가 `KNOWN_STATES`에 있는지만 확인. **전이 순서는 검증하지 않는다** |
| **약** | `currentStory` · `spec` · `plan` 등 | `set-field` | 필드명 예약어만 거부. **값은 검증하지 않는다** |

`force-state`는 구멍이라기보다 **설계된 탈출구**다. 상태 기계가 막힐 때 사람이 풀 수단이 필요하다. 다만 어휘는 지키고 순서는 안 지키므로, **`spec:drafting`에서 `pr:created`로 한 번에 건너뛰는 것이 허용된다.**

**따라서 §9-1의 실무 보고를 채택하려면 근거를 바꿔야 한다** — "JSON을 써라"가 아니라 **"상태 변경을 검증하는 단일 쓰기 경로를 두고 직접 편집을 막아라"** 다. 후자는 형식 중립적이고, 강제 수단도 이미 확인되어 있다([강제 메커니즘 §1.3](enforcement-mechanisms.md)의 `permissions.deny` — 현재 0건).

---

## 3. §9-2 — git은 이미 기록 원천이고, 그 사실이 실측된다

### 3.1 머지 커밋 21건 = 토픽 21개

cygnus git 이력 실측이다.

| 항목 | 값 |
|---|---|
| 총 커밋 | 208 |
| **머지 커밋** | **21** |
| 리뷰 산출물이 존재하는 토픽 수 | **21** |
| 머지 커밋 형식 | `Merge pull request #NN from smalljiny/feature/<토픽명>` |

**정확히 일치한다.** 그리고 브랜치명이 토픽명이므로 **토픽 단위 완료 기록이 이미 git 안에 있다.** 개별 토픽명으로 커밋을 검색해도 잡힌다(`weekly-payout` 7건, `child-pairing` 3건 등).

이것이 §9-2의 답이다 — **git 로그를 세션 간 기록으로 "쓰는 방식"을 새로 설계할 필요가 없다. 이미 그렇게 되어 있고 비용은 0이다.** 필요한 것은 그것을 읽는 쪽이다.

**다만 담기는 것은 토픽 단위까지다.** Story 완료, 리뷰 지적의 처리, 왜 그 결정을 했는지는 git에 없다 — 그것들은 전부 `docs/_local/`(비추적)에 있다. **git은 "무엇이 언제 끝났는가"에 답하고 "어떻게 거기 도달했는가"에는 답하지 않는다.**

### 3.2 git이 담는 것과 담지 않는 것

머지 21건이 주는 것은 **토픽 단위 완료 사실**이다. 그 이상은 없다.

| 질문 | git이 답하는가 | 어디에 있는가 |
|---|---|---|
| 어떤 토픽이 언제 끝났는가 | **✓** | 머지 커밋 |
| 무엇이 바뀌었는가 | **✓** | diff |
| Story·Criterion이 어디까지 갔는가 | ✗ | `implementation-plan.md` (비추적) |
| 리뷰 지적이 어떻게 처리됐는가 | ✗ | `review-report-*.md` (비추적) |
| 왜 그 설계를 골랐는가 | ✗ | `spec.md` §4 의사결정 (비추적) |
| 지금 무엇이 진행 중인가 | ✗ | `dev-context.json` (비추적) |

**추적/비추적 경계가 곧 "결과/과정" 경계와 겹친다.** 결과는 git에 남고 과정은 `docs/_local/` 안에서 사라진다.

이 방향은 선행 조사 둘이 독립적으로 도달한 지점과 같다 — [배포 §1.2](harness-distribution.md)의 추적 파일 0건, [오류 재발 §6.1](error-recurrence-prevention.md)의 학습 44% 유실. 그리고 아젠다 §11(저장소 위생)이 다룰 주제다.

> **초판 정정 — `HANDOFF.md`를 근거로 쓴 논증을 철회한다.**
>
> 초판은 여기서 "추적되는 `roadmap.html`은 최신(7/31)이고 비추적 `HANDOFF.md`는 낡았다(7/21)"는 대조를 **자연 실험**으로 제시하며 추적 여부가 신선도를 갈랐다고 썼다. **이 논증은 성립하지 않는다.**
>
> `HANDOFF.md`는 지속 산출물이 아니라 **병렬 워크트리 조율용 임시 노트**다. 파일 자신이 그렇게 규정한다 — *"세션마다 이 파일 하나를 최신 상태로 덮어쓴다(새 파일 만들지 않음)"*, *"`docs/_local`은 git-ignored — main hub 로컬 코디네이션 전용"*. **비추적은 사고가 아니라 설계 의도다.**
>
> 그리고 7/21자 내용이 *"활성 워크트리: **없음** (child-pairing·weekly-payout 두 트랙 teardown 완료)"* 다. **조율할 대상이 0이 됐으므로 갱신할 것이 없다. 낡은 것이 아니라 비활성이다.** 수명이 설계상 다른 두 문서를 신선도로 비교한 것이 오류였다.
>
> 함께 철회하는 것 둘.
>
> - **"하네스 컴포넌트 참조 0건"을 결함으로 읽은 것.** 애초에 하네스 산출물이 아니므로 참조가 없는 것이 정상이다.
> - **"워크플로우 조사가 없다고 한 프로젝트 수준 지속 산출물이 자생했다"는 해석.** 이 파일은 그것이 아니다. [워크플로우 §3.2](workflow-and-feature-list.md)가 지목한 공백은 **여전히 비어 있다.**
>
> **남는 관측은 하나다** — 하네스는 워크트리의 프로비저닝·teardown을 자동화하면서 **동시에 도는 워크트리들을 가로질러 보는 조율 산출물은 제공하지 않는다.** 사용자가 그 빈 곳을 직접 메웠다. 이는 상태·연속성(§9)보다 **에이전트 조율(아젠다 §5)** 축의 관측이며, 그 조사에서 다루는 편이 맞다.

---

## 4. §9-5 체크포인트 — 이론 어휘로 보면 이것은 체크포인트가 아니다

> **2026-08-02 보강.** 초판은 하네스의 자체 `flow-checkpoint`만 분석하고 **플랫폼이 이미 제공하는 것을 확인하지 않았다.** 구현 참조 자료로서는 그쪽이 먼저이므로 §4.0을 앞에 붙인다.

### 4.0 플랫폼이 이미 주는 것 — Claude Code 네이티브 체크포인팅

[공식 문서](https://code.claude.com/docs/en/checkpointing) 기준이다. **자체 체크포인트를 만들기 전에 무엇이 공짜인지가 먼저다.**

| 항목 | 내용 |
|---|---|
| 생성 시점 | **매 사용자 프롬프트마다 자동** |
| 저장 대상 | Claude의 **파일 편집 도구가 만든 변경의 스냅샷** |
| 보존 | 세션당 최근 **100개** 체크포인트의 파일 스냅샷 |
| 세션 재개 | 대화와 함께 저장되어 **resume 후에도 `/rewind` 가능** |
| 만료 | 세션과 함께 **30일** (`cleanupPeriodDays`로 조정) |
| 호출 | `/rewind` 또는 빈 프롬프트에서 `Esc` 두 번 |

복원 선택지가 **코드와 대화를 분리**한다.

| 선택지 | 효과 |
|---|---|
| Restore code and conversation | 둘 다 되돌림 |
| Restore conversation | 대화만 되돌리고 코드는 유지 |
| Restore code | 코드만 되돌리고 대화는 유지 |
| Summarize from here / up to here | 대화를 요약해 컨텍스트 확보 (파일 불변) |

**한계 목록이 grid fin 설계에 직결된다.** 공식 문서가 명시하는 것들이다.

| 추적되지 않는 것 | 원문 |
|---|---|
| **Bash 명령이 바꾼 파일** | *"Checkpointing does not track files modified by bash commands… Only direct file edits made through Claude's file editing tools are tracked."* |
| **서브에이전트 편집** | 포그라운드 `context: fork` 스킬을 빼면 *"rewinding doesn't restore them… Use git to revert those edits."* |
| 세션 밖·동시 세션의 변경 | *"Manual changes you make to files outside of Claude Code and edits from other concurrent sessions are normally not captured"* |
| 심볼릭·하드 링크 경로 | 복원 시 건너뛰고 `Restored the code, but skipped N files` 경고 |

그리고 위치를 스스로 규정한다.

> *"Checkpoints are designed for quick, session-level recovery… Think of checkpoints as 'local undo' and Git as 'permanent history.'"*
> *"Checkpoints complement but don't replace proper version control."*

**첫 번째 한계가 §4.3의 결론을 두 번째 경로로 확증한다.** `dev-context.json`은 `dev-context.js`(Bash로 실행되는 Node 스크립트)와 `memory-persist` 훅이 쓴다 — **둘 다 Claude의 파일 편집 도구가 아니다.** 따라서 **`/rewind`로 코드를 되돌려도 `dev-context.json`은 최신 상태로 남는다.**

| 롤백 경로 | `dev-context.json`이 되돌아가는가 | 이유 |
|---|---|---|
| `git reset` (flow-checkpoint SHA) | **아니오** | `docs/_local/`이 gitignore |
| **`/rewind` (네이티브)** | **아니오** | **Bash가 쓴 파일은 미추적** |

**서로 독립적인 두 복구 메커니즘이 같은 상태 보유자를 똑같이 놓친다.** §4.3의 고아 상태는 한 메커니즘의 결함이 아니라 **상태를 스크립트로 쓰기 때문에 생기는 구조적 결과**다. 그리고 §2가 보였듯 **스크립트로 쓰는 것이 오편집 저항의 원천**이기도 하다 — **같은 설계 선택이 보호를 주고 복구 가능성을 뺏는다.** 이 상충은 이 조사에서 해소하지 않는다(§7-11).

**두 번째 한계(서브에이전트 편집)도 하네스에 걸린다.** `/flow-impl`이 code-reviewer·security-reviewer 등 서브에이전트를 부르고, [검증·교차리뷰 §2.1](verification-and-cross-review.md) 기준 코드리뷰 21건 전부에서 실행됐다. 그 편집은 `/rewind`로 복원되지 않으며 공식 문서가 **git으로 되돌리라**고 지시한다.

### 4.1 빌려오는 개념 넷

[Elnozahy et al. (ACM Computing Surveys, 2002)](https://www.cs.utexas.edu/~lorenzo/papers/SurveyFinal.pdf)에서 판별 어휘만 가져온다.

| 개념 | 정의 (원문) |
|---|---|
| **일관된 상태** | *"a consistent system state is one in which if a process's state reflects a message receipt, then the state of the corresponding sender reflects sending that message."* |
| **고아(orphan)** | 대응하는 발신 없이 수신만 반영된 상태. 무장애 실행에서는 불가능한 상태 |
| **도미노 효과** | *"rollback propagation may extend back to the initial state of the computation, losing all the work performed before a failure."* 조율되지 않은(uncoordinated) 체크포인팅에서 발생 |
| **output commit** | *"before sending a message (output) to OWP, the system must ensure that the state from which the message is sent will be recovered despite any future failure."* |

일반화하면 — **일관성은 서로 의존하는 상태 보유자들이 같은 시점을 반영할 때 성립한다.** §1.1이 보인 8종 보유자가 바로 그 조건이다.

### 4.2 기본 옵션이 상태를 잡지 않는다

`flow-checkpoint`가 하는 일이다.

```bash
echo "$(date -u +...) | <name> | $(git rev-parse --short HEAD)" >> .claude/checkpoints.log
```

그리고 4단계에서 `AskUserQuestion`으로 셋 중 하나를 고른다.

| 옵션 | 잡히는 것 |
|---|---|
| Commit | 사용자가 지명한 파일만 커밋 |
| Stash | `git stash push` |
| **None: log only (기본값)** | **아무것도 잡지 않음 — SHA 문자열만 기록** |

**기본값에서 이것은 마커이지 체크포인트가 아니다.** `git rev-parse HEAD`는 *이미 커밋된* 지점을 가리키므로, 체크포인트 시점의 미커밋 작업은 어디에도 보존되지 않는다. 나중에 그 SHA로 되돌리면 **체크포인트가 지키려던 바로 그 작업이 사라진다.**

스킬의 `verify` 단계가 이를 우회적으로 드러낸다 — 하는 일이 `git diff <sha> --stat`이다. **현재와 SHA의 차이를 보여줄 뿐 복원 능력을 주지 않는다.**

### 4.3 상태 보유자가 여럿인데 하나만 잡는다 — 조율되지 않은 체크포인트

Commit이나 Stash를 골라도 문제가 남는다. **잡히는 것은 git 작업 트리뿐이고, §1.1의 다른 7종은 그 시점에 고정되지 않는다.**

체크포인트 이후 작업을 계속하다 되돌린다고 하자.

| 보유자 | 롤백되는가 | 결과 |
|---|---|---|
| git 작업 트리 | ✓ (SHA로 복원) | 코드가 과거로 |
| `dev-context.json` | ✗ | **`currentStory`가 존재하지 않는 진행을 가리킨다** |
| plan 체크박스 | ✗ | **되돌려진 작업이 `[x]`로 남는다** |
| review 산출물 | ✗ | 사라진 코드에 대한 리뷰가 남는다 |

**이것이 정확히 고아 상태다** — 상태가 "수신"(완료)을 반영하는데 대응하는 "발신"(실제 작업)이 롤백으로 사라졌다. 서베이의 표현대로 무장애 실행에서는 나올 수 없는 조합이다.

**그리고 이 발산은 가능성이 아니라 확정이다.** `docs/_local/`이 `.gitignore` 171행에 걸려 있으므로(§1.1) **`git reset`이 `dev-context.json`을 애초에 건드릴 수 없다.** git 기반 롤백은 추적되는 것만 되돌리고, 상태 보유자 8종 중 7종이 추적되지 않는다. 실제 롤백을 실행해 볼 필요도 없다 — 무시 규칙이 결과를 정한다.

**같은 gitignore가 두 곳에서 서로 다른 손상을 낸다.** [오류 재발 §6.1](error-recurrence-prevention.md)에서는 학습 44% 유실의 기계적 원인이었고, 여기서는 체크포인트 불일치의 보장 조건이다.

그리고 서베이가 이 구조의 귀결을 명시한다. 조율되지 않은 체크포인팅은 **도미노 효과**에 노출되며, *"rollback propagation may extend back to the initial state of the computation."* **아젠다 §9-5가 물은 "크래시가 전체 재시작을 부르지 않게 하는 구조"는 바로 이 도미노를 피하는 문제이고, 현재 구조는 그것을 피하지 못한다.**

서베이가 제시하는 두 갈래도 그대로 대응된다.

| 서베이의 해법 | 하네스에서의 형태 | 현재 |
|---|---|---|
| **조율된(coordinated) 체크포인팅** — 모든 보유자가 같은 시점에 함께 저장 | `flow-checkpoint`가 git + `dev-context.json` + plan 체크박스를 원자적으로 함께 잡는다 | 미구현 |
| **메시지 로깅** — 체크포인트 + 결정 로그로 재생. *"log-based recovery generally is not susceptible to the domino effect"* | `.claude/sessions/*.jsonl` 14건이 이미 도구 호출 로그다 | **기록만 되고 재생 경로 없음** |

**두 번째가 흥미롭다.** 세션 로그는 이미 존재하고, 서베이 기준으로 로그 기반 복구는 도미노에 노출되지 않는다. [오류 재발 조사 §8](error-recurrence-prevention.md)이 *"문제는 기록이 아니라 그것을 읽는 단계가 파이프라인에 없다"* 고 한 것이 여기서 두 번째 용도를 얻는다 — 그 조사는 로그를 **학습 입력**으로 봤고, 여기서는 **복구 입력**이 될 수 있다.

> **전이 한계**: 세션 로그가 재생 가능한 결정 로그인지는 확인하지 않았다. 서베이의 로그 기반 복구는 **piecewise-deterministic 가정**(비결정적 사건의 정보를 충분히 포착하면 재생 가능)에 기댄다. LLM 호출은 결정적이지 않고 도구 호출 로그가 그것을 포착하는지 미확인이다. **개념적 대응이지 적용 가능성 판정이 아니다**(§5-4).

### 4.4 되돌릴 수 없는 출력이 이미 나가고 있다

**output commit 문제**는 하네스에 그대로 있다. 외부로 나가는 출력은 되돌릴 수 없으므로, 나가기 전에 그 시점 상태의 복구가 보장되어야 한다.

| 출력 | 되돌릴 수 있는가 |
|---|---|
| `gh pr create` (`/flow-pr`) | 닫을 수는 있으나 이력은 남는다 |
| `gh issue create` ([오류 재발 §7.10](error-recurrence-prevention.md)의 지식의 원본 반영 제안) | 좌동 |
| `git push` | 강제 푸시 외에는 불가 |

**현재 이 지점들 앞에 복구 보장이 없다.** `/flow-pr` 시점에 `dev-context.json`·plan 체크박스·git이 일관됨을 확인하는 단계가 없다.

여기서 선행 조사와 이어지는 지점이 하나 나온다 — [오류 재발 §7.10.5](error-recurrence-prevention.md)는 `/flow-pr`·`/flow-done`을 **이슈 생성 강제 지점**으로 제안했다. 서베이의 어휘로 보면 그 지점은 **output commit 지점**이기도 하다. **같은 지점에 두 요구가 겹친다** — 나가기 전에 강제할 것이 있고, 나가기 전에 보장할 것이 있다.

---

## 5. §9-3 초기화를 독립 단계로 두는 이유 — 실물이 답한다

아젠다는 이 질문의 근거로 강의 6을 들었으나, **기존 하네스의 `/flow-init`(302줄)이 이미 그 형태이므로 1차 관측으로 답할 수 있다.**

`flow-init`이 하는 일은 CLAUDE.md·AGENTS.md의 프로젝트 섹션 생성·갱신이고, **핵심은 Step 1의 4상태 분기**다.

| 상태 | 모드 |
|---|---|
| `CLAUDE.md` 없음 | 신규 생성 |
| `<!-- harness-rules:begin -->` 마커 있음 | 업데이트 (마커 사이만 재생성, 바깥은 불가침) |
| 마커 없음 + `@.harness/harness-guide.md` 라인 있음 | 일회 마이그레이션 (in-place 변환) |
| 그 라인도 없음 | **경계 탐지 불가** → 경고 + `AskUserQuestion`(백업 후 재생성 / 중단) |

**초기화가 독립 단계여야 하는 이유가 이 표에 있다.** 초기화는 "없으면 만든다"가 아니라 **기존 상태를 판별하고 그에 따라 다른 일을 하는 작업**이다. 네 갈래 중 하나는 판별 실패이고, 그 경우 자동 진행하지 않고 사람에게 넘긴다.

이 분기를 매 세션에 녹여 넣을 수 없는 이유도 분명하다 — **마이그레이션은 일회성이고, 경계 탐지 불가는 사람 개입을 요구한다.** 둘 다 상시 실행에 부적합하다.

부수 관측 둘.

- **판정 권위자가 분리되어 있다.** Step 1은 흐름 분기만 정하고, "변경 없음" 판정은 Step 3의 **SHA-256 해시 비교가 단일 권위자**다. 판별과 판정을 나눈 설계다.
- **자동화 가능 범위가 제한된다.** [배포 조사 §5.2](harness-distribution.md)가 이미 지적했다 — `_tasks` 같은 자동 실행이 담당할 수 있는 것은 4상태 중 **업데이트 모드뿐**이다. 나머지 셋은 LLM 판단이나 사람 확인을 요구한다.

---

## 6. §9-4 깨끗한 상태를 강제하는 방법

아젠다는 *"매 세션이 깨끗한 상태를 남겨야 하는 이유와 그것을 강제하는 방법"* 을 물었다.

**현재 강제는 없다.** 세션 종료 시점의 장치는 Stop 훅 둘이고 둘 다 강제하지 않는다.

| Stop 훅 | 하는 일 | 차단하는가 |
|---|---|---|
| `console-log-audit` | `console.log` 잔여 경고 | **아니오** (`exit 0`, 주석으로 명시) |
| `memory-persist` | `updatedAt` 갱신 | 아니오 |

그런데 [강제 메커니즘 조사 §1.2](enforcement-mechanisms.md)가 확인했듯 **`Stop` 이벤트는 exit 2로 차단 가능하다** — *"Prevents Claude from stopping; continues conversation."* 즉 "깨끗한 상태를 남길 때까지 세션을 끝내지 못하게 하는" 수단이 플랫폼에 있고 하네스는 쓰지 않는다.

**다만 "깨끗함"의 정의가 먼저다.** 이 조사가 확인한 것으로 후보를 좁히면 이렇게 된다.

| 후보 판정 | 기계 검증 가능? | 근거 |
|---|---|---|
| `dev-context.json`의 상태와 git 상태가 모순되지 않는가 | 가능 | §4.3의 고아 상태 판정 |
| plan 체크박스와 실제 커밋이 대응하는가 | 어려움 | 체크박스는 자유 편집(§2.1) |
| 미커밋 변경이 남아 있지 않은가 | 가능 (`git status`) | — |
| 세션이 남긴 지적이 처리되었는가 | 어려움 | [검증 조사 §2.3](verification-and-cross-review.md)의 `deferred` 128건 |

**그리고 차단으로 올릴 조건은 이미 걸려 있다** — [검증·교차리뷰 §3.2](verification-and-cross-review.md)의 Google 기준, 차단은 effective false positive 0%일 때만. 위 표에서 "가능" 두 항목만 그 기준을 통과할 후보다.

---

## 7. 열린 질문

1. **8종 보유자를 줄일 수 있는가, 아니면 조율해야 하는가.** §4.3의 고아 상태는 보유자가 여럿이라서 생긴다. 줄이는 쪽(단일 상태 저장소)과 조율하는 쪽(원자적 체크포인트)의 비용을 비교하지 않았다.
2. **과정 기록을 추적 대상으로 올릴 것인가.** §3.2가 보였듯 결과(git)와 과정(`docs/_local/`)이 추적 경계로 갈린다. 그러나 **비추적에는 정당한 이유가 있는 경우가 있다** — `HANDOFF.md`처럼 설계상 로컬·임시인 것, 워크트리별 격리 컨텍스트(§1.3)가 그렇다. **무엇이 "무시되어야 마땅한 로컬"이고 무엇이 "실수로 무시된 기록"인지 가르는 기준**이 없다. [배포 조사 §7.9.3](harness-distribution.md)의 core/config/local 3계층이 이 구분의 후보다.
3. **워크트리 간 조율 산출물이 필요한가.** §3.2 말미의 관측 — 하네스가 프로비저닝·teardown은 자동화하면서 동시 워크트리를 가로지르는 조율은 제공하지 않는다. **다만 이는 아젠다 §5(에이전트 조율) 축이므로 그 조사로 넘긴다.**
4. **세션 로그가 재생 가능한 결정 로그인가**(§4.3 전이 한계). 서베이의 로그 기반 복구는 piecewise-deterministic 가정에 기대는데, LLM 호출이 그 가정을 만족하지 않는다. **부분 재생**(도구 호출 순서와 파일 변경만)이 의미 있는지 미확인이다.
5. **`force-state`가 전이 순서를 검증하지 않는 것이 옳은가**(§2.2). 탈출구는 필요하나, 현재는 어떤 건너뛰기든 허용된다. 로그를 남기는 것만으로 충분한지 미확인.
6. **체크포인트의 기본값을 바꿀 것인가.** "log only"가 기본인 이유가 비용(매번 커밋·스태시)일 수 있다. `git stash create`(작업 트리를 커밋 없이 객체로 저장)가 절충안이 될 수 있으나 검증하지 않았다.
7. **`Stop` 훅 차단을 켤 것인가**(§6). 수단은 있고 판정 후보도 좁혀졌으나, 오탐 시 세션이 끝나지 않는 실패 모드가 있다. effective FP 0% 요구가 특히 엄격하게 적용되어야 하는 대목이다.
8. ~~**화석 정리의 우선순위.** … **전수 조사를 하지 않았다.**~~ **실험 A1(2026-08-03)에서 전수 조사를 실시해 해소 — §8 참고.** 결과는 예상보다 무겁다. **`/dev:*` 커맨드는 하나도 존재하지 않고**(`commands/dev/` 디렉터리 자체가 없음), **참조는 23개 파일 62곳에 남아 있으며**, 그중 **감사 도구가 화석을 되살리라고 지시한다.**
9. **`memory-persist`가 무엇을 저장해야 하는가**(§1.2). 이름이 약속하는 것과 구현의 간극은 명확하나, Stop 시점에 무엇을 남기면 다음 세션이 이어받는 데 충분한지는 §7-1(보유자 정리)에 달려 있다.
10. **보호와 복구 가능성의 상충**(§4.0). 상태를 스크립트로 쓰면 오편집에 강해지지만(§2), 바로 그 때문에 네이티브 체크포인팅이 추적하지 못한다. 둘을 동시에 얻는 방법 — 예컨대 스크립트가 아니라 검증된 편집 도구 경로를 쓰는 것 — 이 가능한지 자료에서 확인하지 못했다.
11. **자체 체크포인트가 필요한가**(§4.0). 플랫폼이 매 프롬프트 자동 스냅샷·100개 보존·30일 만료를 준다. 하네스가 더해야 할 것이 있다면 **플랫폼이 못 잡는 것**(Bash 산출물·서브에이전트 편집·`docs/_local` 상태)에 한정되는데, 그 범위가 자체 구현 비용을 정당화하는지 미판정이다.
12. **워크트리 수가 늘면 상태 발산이 실제로 문제가 되는가**(§1.3). `flow-worktree`가 main hub dev-context의 stale 상태를 스스로 기록하고 수동 정리를 제시한다. 관측된 동시 활성 워크트리는 최대 2개였고 현재 0이므로 **규모가 작아 드러나지 않았을 가능성**이 있다. 몇 개부터 수동 정리가 감당 불가해지는지 미측정이다.

---

## 8. 실험 A1 — `/dev:*` 화석 전수 조사 (2026-08-03 실시)

§7-8이 *"전수 조사를 하지 않았다"* 로 남긴 항목이다. **아젠다의 실험 목록에서 A 부류(정적 조사)로 분류되었고, 검색만으로 완결됐다.**

### 8.1 존재하는 것과 참조되는 것

| | 값 |
|---|---|
| **실제 `/dev:*` 커맨드** | **0개.** `src/.claude/commands/dev/` **디렉터리 자체가 없다** |
| 실제 커맨드 전부 | 4개 — `add-language-rules`, `codex/setup`, `harness/audit`, `harness/learn` |
| **실제 워크플로우** | **`flow-*` 스킬 13종** (`flow-setup`·`spec`·`plan`·`impl`·`review`·`verify`·`docs`·`pr`·`done`·`topic`·`checkpoint`·`init`·`worktree`) |
| **`/dev:*` 참조** | **23개 파일, 62곳** |
| 참조된 커맨드 이름 | **12종** — 전부 부재 |

참조 빈도순: `/dev:review` 12, `/dev:impl` 11, `/dev:plan` 10, `/dev:verify` 6, `/dev:spec` 6, `/dev:docs` 6, `/dev:pr` 3, `/dev:done` 2, `/dev:topic`·`/dev:setup`·`/dev:checkpoint`·`/dev:build-fix` 각 1.

**대부분 `flow-*`에 1:1 대응물이 있다**(`/dev:review` → `flow-review` 등). 예외가 `/dev:build-fix` 하나로 대응물이 없고, 반대로 `flow-init`·`flow-worktree`는 `/dev:*` 시절에 없던 것이다. **즉 이름만 바뀐 것이 아니라 워크플로우가 재편됐고, 참조만 남았다.**

### 8.2 화석의 다섯 층 — 피해가 다르다

| 층 | 파일 | 왜 다른가 |
|---|---|---|
| **① 감사 도구** | `harness-audit.js` (3곳) | **화석을 되살리라고 지시한다** — §8.3 |
| **② 사용자 진입점** | `README.md` (10곳) | 워크플로우 안내 전체가 없는 커맨드를 가리킨다 |
| **③ 라우팅 표면** | 에이전트 7종의 `description` | **상시 로드된다**([지시 계층 §1.2](instruction-layers.md)). 부재 커맨드가 라우팅 신호에 섞인다 |
| **④ 실행 코드** | `session-start.js`, `git-push-review.js` | 출력 문구가 오도한다(§1.2에서 이미 확인) |
| **⑤ 자체 생성 학습** | `learned/` 스킬 4종 | **학습 항목 자체에 화석이 유입됐다** |

⑤가 특히 눈에 띈다. `learned/ask-user-question-final-review`는 **description 첫 줄에** *"…`/dev:review` 전체 스캔이…"* 를 담는다. [오류 재발 조사](error-recurrence-prevention.md)의 학습 축이 만든 산출물이 부재 커맨드를 규범으로 굳혀 재유통하는 형태다.

### 8.3 가장 무거운 발견 — 감사 도구가 틀린 조치를 지시한다

`harness-audit.js`를 실행했다. **28개 검사 중 5개 실패, 그리고 "Top Actions" 3개가 전부 화석 복원 지시다.**

```
1. [Quality Gates] Add .claude/commands/dev/verify.md as a pre-PR gate.
2. [Quality Gates] Add .claude/commands/dev/review.md for code review workflow.
3. [Quality Gates] Add .claude/commands/dev/checkpoint.md for mid-session state snapshots.
```

세 항목 모두 `Quality Gates` 범주에 배점(3+2+2 = 7점)까지 걸려 있다. **`flow-verify`·`flow-review`·`flow-checkpoint`가 이미 그 일을 하는데, 감사는 그것을 보지 못하고 없는 파일을 만들라고 한다.**

**이것은 화석의 잔존이 아니라 자동화된 오조언이다.** 지시를 따르면 워크플로우가 이중화되고, 따르지 않으면 감사 점수가 영구히 깎인 채로 남는다. **어느 쪽도 정상 상태가 아니다.**

**이 시리즈가 확인해 온 자기 검사 층의 문제에 세 번째 사례가 추가된다.**

| 조사 | 관측 |
|---|---|
| [강제 메커니즘](enforcement-mechanisms.md) | 훅 9개 중 **차단 게이트 0개** — 검사가 막지 않는다 |
| [평가 §6.3](evaluation.md) | eval **100일 미실행** — 검사가 돌지 않는다 |
| **본 실험** | 감사 도구의 최상위 조치 3건이 **틀렸다** — 검사가 잘못 가리킨다 |

**부재·미실행에 이어 오작동이다.** grid fin 설계 시 "검사 층을 어떻게 유지할 것인가"가 별도 문제로 서야 하는 근거다.

### 8.4 이 실험이 답하지 않은 것

- **`flow-*`로의 이전이 언제 일어났는지 추적하지 않았다.** git 이력으로 확인 가능하나 이 실험의 범위 밖이다.
- **`references/` 아래 제3자 자료는 집계에서 제외했다.** 하네스 자신의 화석만 셌다.
- **화석을 고치지 않았다.** 이 실험은 관측이며, 정리는 grid fin 설계 시점의 판단이다. **특히 `harness-audit.js`의 세 검사는 삭제인지 `flow-*` 기준으로 교체인지가 감사 도구의 목적에 달려 있다.**

---

## 부록. 조사 방법 및 한계

**방법**
- cygnus 직접 검사 — `dev-context.json` 구조·토픽 수·상태, `HANDOFF.md` 내용과 mtime, `.claude/sessions/` 14건, git 이력 208커밋(머지 21건, 토픽명별 커밋 수), `git check-ignore`로 `docs/_local/` 무시 확인, 추적 문서 38건 목록과 roadmap 최종 커밋일
- 하네스 직접 검사 — `dev-context.js` 서브커맨드 6종과 `PROTECTED_FIELDS`·`force-state` 검증 로직, `flow-checkpoint`(124줄) 전문, `flow-init`(302줄) Step 1 분기, `memory-persist.js`·`session-start.js` 전문, `HANDOFF`·`checkpoints.log`·세션 로그 참조처 `grep -rl`
- WebFetch 1회 **본문** — Elnozahy et al., ACM Computing Surveys 2002

**직접 확인 (1차 관측)**
- 상태 보유자 8종과 추적 여부, `docs/_local/` gitignore 171행
- `HANDOFF.md`의 헤더가 밝힌 목적(병렬 워크트리 조율)·갱신 규칙(세션마다 덮어쓰기)·로컬 전용 선언, 7/21 시점 활성 트랙 0
- `flow-worktree` SKILL.md의 자기 기록 — worktree `/flow-done` 후 main hub dev-context가 stale하게 남음, `docs/_local/done/` sync-back으로 정본 위치가 이동
- `checkpoints.log` 부재 (`flow-checkpoint` 스킬은 존재)
- `memory-persist.js`가 `updatedAt`만 갱신
- `session-start.js`의 `/dev:impl` 참조
- 머지 커밋 21건 = 리뷰 산출물 토픽 21개, 브랜치명 = 토픽명
- roadmap.html 최종 커밋 2026-07-31 = 저장소 최신 커밋일
- `force-state`가 `KNOWN_STATES`만 확인하고 `VALID_TRANSITIONS`를 거치지 않음
- `flow-checkpoint` 4단계의 기본 옵션이 "None: log only"


**2026-08-02 재구성**: 외부 자료를 「구현 참조 자료」 절로 앞당겨 모았고 1차 관측 절을 보조 근거로 재프레이밍했다. **절 번호는 유지했다** — 조사 문서 8건이 서로를 §번호로 참조하므로 재번호는 그 링크 그래프를 조용히 깨뜨린다.

**한계**

- **`flow-checkpoint`가 한 번도 실행되지 않았다는 것은 로그 파일 부재에 근거한 추론이다.** 스킬이 실행됐으나 사용자가 매번 중단했을 가능성을 배제하지 못한다. 세션 로그를 뒤져 호출 이력을 확인하지 않았다.
- **초판의 §3.2 논증을 철회했다.** `HANDOFF.md`(비추적, 7/21)와 `roadmap.html`(추적, 7/31)의 신선도 대조를 "추적 여부가 갈랐다"는 자연 실험으로 제시했으나, **두 문서의 수명이 설계상 다르므로 비교가 성립하지 않는다.** `HANDOFF.md`는 병렬 워크트리 조율용 임시 노트이고 파일 헤더가 "세션마다 덮어쓴다 / 로컬 전용"을 명시하며, 7/21 시점에 활성 트랙이 0이라 갱신 대상 자체가 없었다. **낡은 것이 아니라 비활성이다.**
- **이 오류의 성격**: 파일의 위치(`docs/_local/`)와 mtime만 보고 용도를 추정했고, **파일 자신이 헤더에 밝혀둔 목적과 갱신 규칙을 읽고도 지속 산출물로 분류했다.** 사용자 지적으로 정정했다. 같은 방식의 추정이 남아 있을 수 있는 곳은 §1.1의 보유자 분류이며, 나머지 7종은 하네스 컴포넌트가 쓰기 경로를 소유하므로 용도가 코드로 확인된다.
- **Elnozahy et al.은 메시지 전달 분산 시스템 문헌이다**(§0.3). 어휘와 판별 기준만 빌렸고 정리·성능 논의는 전이시키지 않았다. 특히 §4.3의 "도미노 효과" 대응은 **구조적 유비이지 증명이 아니다.**
- **고아 상태를 실제 롤백으로 재현하지는 않았다.** 다만 §4.3의 발산은 관측이 아니라 **무시 규칙에서 연역된다** — `docs/_local/`이 gitignore되어 있으므로 git 기반 롤백이 `dev-context.json`을 건드릴 수 없다. 재현 실험이 바꿀 수 있는 것은 "얼마나 나쁜가"이지 "일어나는가"가 아니다.
- **세션 로그의 내용을 열어보지 않았다.** 14개 파일의 존재와 참조처만 확인했고, 무엇이 기록되는지·재생에 충분한지 검사하지 않았다(§7-4).
- **`wf-compact`(86줄)를 목차 수준에서만 봤다.** "What Survives Compaction" 절이 [지시 계층 §7-1](instruction-layers.md)의 압축 생존 질문과 겹치는데 대조하지 않았다.
- ~~**`/dev:*` 화석의 전수 조사를 하지 않았다**(§7-8).~~ **실험 A1(2026-08-03)에서 실시했다 — §8.** 초판이 우연히 발견한 두 건은 62곳 중 두 곳이었다.
- **cygnus 단일 프로젝트 표본이다.** 머지 21건 = 토픽 21개라는 대응이 다른 프로젝트에서도 성립하는지는 이 워크플로우를 쓰는 다른 저장소가 없어 확인 불가다.
