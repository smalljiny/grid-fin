# 워크플로우 구조와 피쳐 목록 — 조사

**최초 작성**: 2026-08-02
**최종 수정**: 2026-08-06
**대상 프로젝트**: grid fin (신규 개인용 개발 하네스)
**1차 관측 대상**: `/Users/mario/Workspace/harness` — `.harness/contracts/`, `.harness/scripts/dev-context.js`, `docs/specs/topic-lifecycle.md`, `src/.claude/skills/flow-*/SKILL.md`
**조사 도구**: WebSearch 3회, WebFetch 6회, 로컬 저장소 직접 읽기
**성격**: 조사. 형식·구조의 선택은 하지 않는다.

선행 문서
- [research-agenda.md](research-agenda.md) §10 — 이 조사의 출처
- [error-recurrence-prevention.md](error-recurrence-prevention.md) — 오류 검출·학습·원본 반영
- [harness-distribution.md](harness-distribution.md) — 배포 메커니즘

---

## 0. 조사 요약

| # | 관측 | 근거 |
|---|---|---|
| 1 | **기존 하네스의 상태 기계는 토픽 수준에서 스크립트로 강제된다.** `dev-context.js`가 `phase`/`status`를 보호 필드로 두고 전환표로 검증한다 | §1.1 — `PROTECTED_FIELDS = new Set(['phase','status'])` |
| 2 | **그러나 Story·Criterion 수준의 완료는 에이전트가 직접 markdown 체크박스를 Edit한다.** ⚠ **관측은 유효하나 함의가 과했다 — [§1.3 정정](#13-그러나-완료-표시는-에이전트가-한다) 참조** | §1.3 — `flow-impl` Step 7·9 |
| 3 | **이 비대칭이 출처가 규정하는 원칙과 충돌한다** — 검증 명령의 성공만이 상태를 전환시켜야 한다는 요구. ⚠ **§1.3 정정으로 범위가 좁아진다** | §2.3 vs §1.3 |
| 4 | **기존 상태 기계는 워크플로우 진행을 추적할 뿐 기능 동작을 추적하지 않는다.** 종착 상태가 `pr:created`이지 "동작이 검증됨"이 아니다 | §3.1 |
| 5 | **프로젝트 수준의 지속적 피쳐 목록에 해당하는 산출물이 없다.** spec·plan은 토픽 단위로 생성되고 토픽이 끝나면 역할이 끝난다 | §3.2 |
| 6 | **출처가 요구하는 "실행 가능한 검증 명령"이 하네스 자신에는 대부분 적용되지 않는다** — 하네스는 markdown·프롬프트·스킬로 이뤄져 있다 | §5 |
| 7 | **그런데 하네스가 그 문제를 이미 국소적으로 풀어놨다** — `prompt` Story 타입의 Eval 스키마(`direct`/`rubric`/`judge` + `Acceptance: N/M`) | §5.2 |
| 8 | Spec Kit은 7단계 + 보조 커맨드 3종으로 이 워크플로우를 구현하며, 기존 하네스에 없는 단계가 셋 있다 (`constitution`, `analyze`, `converge`) | §6.1 |

### 출처 신뢰도에 관한 경고

> **2026-08-02 보강.** 이 절은 최초 작성 시 "실행 가능한 규정이 전부 단일 자가출판 출처에서 나왔다"고 경고했다. 이후 출처 감사에서 **립도 축에는 피어리뷰된 재현 데이터가 존재함**이 확인되어 §4.3을 추가했고, **강의가 Guo et al.(ICML 2017)을 그 논문이 하지 않는 주장에 끌어다 썼음**이 확인되어 §4.1을 정정했다. 아래 경고는 나머지 축(삼중 구조·상태 머신·WIP=1)에 대해 여전히 유효하다.

**형식 규정(삼중 구조, 상태 머신, WIP=1)은 단일 출처에서 나왔다** — [Learn Harness Engineering](https://walkinglabs.github.io/learn-harness-engineering/en/) 강의 7·8·9. 자가 출판이며 피어리뷰가 없고, 인용된 수치("45% 높은 완성률", "37% 높음", "800줄 20% vs 1200줄 100%", "중복 구현 0건")에 방법론·표본 설명이 없고 다른 자료에서 독립 재현을 찾지 못했다.

**구조적 주장**(삼중 구조, 상태 전환을 하네스가 통제해야 한다)은 논리로 방어 가능하다. **수치는 아니다.** 우선순위 판단을 저 숫자에 근거해서는 안 된다.

축별로 근거 상태가 갈린다.

| 축 | 근거 상태 |
|---|---|
| **립도 (작업 단위 크기)** | **피어리뷰 2편이 독립 수렴 — §4.3** |
| 조기 완료 선언 | 현상 서술은 타당하나 인용된 근거는 오용 — §4.1 |
| 삼중 구조 (`behavior`/`verification`/`evidence`) | 단일 자가출판. 다만 `evidence` 필드의 필요성은 선행 조사 §7.2가 독립적으로 도달 |
| 상태 머신 (검증 명령만이 전이 허용) | 단일 자가출판. 구조적 주장으로는 방어 가능 |
| **WIP=1** | **단일 자가출판. 수치에 대한 신뢰 가능한 뒷받침을 찾지 못했다 — §4.2** |

Spec Kit Agents의 효과도 작다 — 1~5 복합 LLM-as-judge 점수에서 **+0.15**, SWE-bench Lite Pass@1 **58.2%(+1.7%p)**. grounding hook을 검증된 기법으로 취급하면 안 된다.

---

## 구현 참조 자료 — 외부 자료 정리

> **이 절의 쓰임.** 이 조사가 확인한 외부 자료를 **구현 시 참조할 형태**로 모았다. **이 문서는 근거 등급이 축마다 크게 갈리므로** 각 항목에 그 상태를 함께 적었다(§0의 경고 참조).

### A. 작업 단위의 크기 — 이 문서에서 유일하게 재현된 축

**피어리뷰 2편이 서로 다른 조직·시기·방법으로 수렴한다** (§4.3, 본문 확인).

| | [Rigby & Bird, FSE 2013](https://www.microsoft.com/en-us/research/wp-content/uploads/2016/02/rigby2013convergent.pdf) | [Sadowski et al., ICSE-SEIP 2018](https://sback.it/publications/icse2018seip.pdf) |
|---|---|---|
| 표본 | Android·Chromium OS·Bing·Office·MS SQL·AMD + OSS + Lucent | **리뷰된 변경 900만 건** |
| **변경 크기 중앙값** | Apache 25줄 · Linux 32줄 · Android/AMD **44줄** · Chrome **78줄/5파일** · Lucent(1998) 263줄 | **24줄** |
| 파일 수 | Chrome 5파일 | **35%가 단일 파일**, 90%가 10파일 미만 |
| **리뷰어 수** | 중앙값 **2명**, 수확 체감 측정됨 | 중앙값 **1명**, 25% 미만이 2명 초과 |
| 리뷰 소요 | 중앙값 14.7~20.8시간 | 전체 중앙값 **4시간 미만** |

Rigby & Bird의 결론은 **수렴 자체**다 — 조직·문화·인센티브가 전혀 다른데도 *"their similarities outweighed their differences."* 리뷰어 증가의 효과는 *"only a minimal increase in the number of comments"*.

Sadowski et al.은 작은 변경이 **의도된 실천**임을 명시 — *"developers are strongly encouraged to make small, incremental changes"*, 근거는 *"the number of useful comments decreases and the review latency increases as the size of the change increases."*

> **전이 한계**: 둘 다 **사람 리뷰어** 대상이다. 에이전트 리뷰어에 같은 곡선이 적용된다는 근거는 없다(§8-10).

### B. 단계 구조 — GitHub Spec Kit

7단계 + 보조 커맨드 3종 (§6.1, **README 수준만 확인**).

| 단계 | 커맨드 | 산출물 |
|---|---|---|
| Constitution | `/speckit.constitution` | `specs/constitution.md` — 프로젝트 통제 원칙 |
| Specify | `/speckit.specify` | `specs/spec.md` |
| Plan | `/speckit.plan` | `specs/plan.md` |
| Tasks | `/speckit.tasks` | `specs/tasks.md` (별도 파일) |
| Tasks→Issues | `/speckit.taskstoissues` | GitHub Issues |
| Implement | `/speckit.implement` | 코드 |
| **Converge** | `/speckit.converge` | **스펙 대비 평가** |

보조: `/speckit.clarify`(불명확 영역 명확화), **`/speckit.analyze`(산출물 간 일관성 분석)**, `/speckit.checklist`(품질 체크리스트 생성).

**템플릿 해석에 4단계 우선순위** — overrides → presets → extensions → core. [배포 조사](harness-distribution.md)의 core/config 계층과 같은 구조다.

[Spec Kit Agents (arXiv 2604.05278)](https://arxiv.org/pdf/2604.05278)는 4단계에 **read-only probing hook**을 붙여 각 단계를 저장소 증거에 접지시킨다. **효과는 작다** — LLM-as-judge 복합 점수 **+0.15 (+3.0%)**, SWE-bench Lite Pass@1 **58.2% (+1.7%p)**. **초록만 확인했다.**

### C. 완료 판정의 3계층

| 계층 | 내용 |
|---|---|
| 1 | 문법·정적 분석 |
| 2 | 실행 동작 (단위·통합 테스트, 애플리케이션 기동) |
| 3 | 시스템 수준 (E2E, 사용자 시나리오) |

**완료 우선순위 제약**: 기능적 정확성 → 성능 → 스타일. *"리팩터링하면서 할 수 있습니다"* 는 검증된 코드와 미검증 코드의 경계를 흐린다.

단위 테스트 통과가 완료가 아닌 이유 셋 — 인터페이스 불일치(목 환경에서 안 잡힘), 상태 전파 오류, 환경 의존성.

> **출처 등급 주의**: 이 3계층 규정은 **자가출판 단일 출처**(walkinglabs 강의 9)다. 다만 [검증·교차리뷰 C](verification-and-cross-review.md)의 Fowler가 같은 3범주를 독립적으로 제시하고 **행동(계층 3)이 가장 미해결**이라고 진단한다.

### D. 코드 아닌 산출물의 완료 기준 — 기존 하네스의 Eval 스키마

**§5.2에서 확인한 것으로, 외부 자료가 아니라 기존 하네스 계약이다.** 그러나 *"스킬·프롬프트에 대응하는 `curl`이 없다"* 는 문제에 대한 실물 답이므로 여기 함께 둔다.

| 전략 | 적용 기준 | 필수 필드 |
|---|---|---|
| `direct` | 정확한 텍스트·구조 일치 | Input, Expected |
| `rubric` | 주관적 품질(어조·간결성·준수) | Input, Criteria, Rubric, Pass |
| `judge` | 복잡한 추론·정확성 (별도 평가자) | Input, Expected, Pass, Judge Criteria |

**`Acceptance: N/M`** 이 종료 코드에 대응하는 이진 판정을 준다. 현재 `prompt` Story 타입에만 적용된다.

### E. 스펙 문서의 구성 요소

[Addy Osmani](https://addyosmani.com/blog/good-spec/) (§7, **저자 주장이며 원 데이터 미확인**). 6요소 — Commands(실행 가능한 전체 명령어), Testing(프레임워크·위치·커버리지), Project Structure, **Code Style(텍스트 설명보다 코드 예시)**, Git Workflow, Boundaries.

**3단계 경계 체계**: ✅ Always Do(승인 불필요) / ⚠️ Ask First(인간 검토) / 🚫 Never Do. Codex의 `approval_policy`와 개념적으로 대응한다([강제 메커니즘 C](enforcement-mechanisms.md)).

**"지시의 저주"** — 지시가 많을수록 준수율 하락. 대응 셋: 단계별 피드, 서브에이전트(2~3개가 관리 한계), **확장 목차**(각 섹션 500단어를 2~3줄로 요약, 필요 시에만 전문).

> **용어 충돌 주의**: 이 출처의 "스펙"은 **어떻게 작업할 것인가**에 가깝고, 기존 하네스의 `spec.md`는 **무엇을 만들 것인가**다. 전자는 CLAUDE.md/`.harness/rules/` 영역이다.

### F. 근거가 약한 축 — 그대로 쓰면 안 되는 것들

| 규정 | 출처 상태 |
|---|---|
| 삼중 구조 (`behavior`/`verification`/`evidence`) | 자가출판 단일. 단 `evidence`의 필요성은 [오류 재발 §7.2](error-recurrence-prevention.md)가 독립 도달 |
| 상태 머신 (검증 명령 성공만이 전이 허용, `passing` 불가역) | 자가출판 단일. 구조적 주장으로는 방어 가능 |
| **WIP=1** | **자가출판 단일. 뒷받침 자료를 찾지 못했다**(§4.2). 대기행렬 이론은 방향만 주고 결과 품질 주장을 주지 않는다 |
| 조기 완료 선언의 원인 | 현상은 타당하나 **인용된 Guo et al.은 오용**(§4.1 정정) |
| 인용 수치 전반 | "45% 높은 완성률", "800줄 20% vs 1200줄 100%" 등 **방법론·표본 설명 없음** |

### G. 다른 조사와 맞물리는 지점

| 지점 | 연결 |
|---|---|
| A의 리뷰어 수확 체감 | [검증·교차리뷰 §2.1](verification-and-cross-review.md) — cygnus는 코드리뷰에 3종을 돌린다 |
| A의 크기 상한 | [검증·교차리뷰 B](verification-and-cross-review.md)의 뮤테이션 노출량 상한(파일 수×7)과 같은 인지 부담 축 |
| C의 계층 3 | 같은 문서 Fowler — 행동 검증이 가장 미해결 |
| B의 `analyze`(산출물 간 일관성) | [오류 재발 §2.1](error-recurrence-prevention.md)의 "오류 = 상위 산출물과의 델타"와 같은 대상 |

---

## 1. 1차 관측 — 기존 하네스의 현재 구조

> **이 절부터 §7까지는 기존 하네스 실측이며, 위 자료가 이 프로젝트에 해당하는지 확인하는 보조 근거다.**

### 1.1 토픽 상태 기계는 스크립트가 강제한다

`dev-context.json`이 토픽별로 `phase:status` 쌍을 갖고, `dev-context.js`가 전환을 검증한다.

```javascript
// .harness/scripts/dev-context.js
const PROTECTED_FIELDS = new Set(['phase', 'status'])
```

`set` 서브커맨드로는 `phase`/`status`를 바꿀 수 없고, `update-state`만이 전환표를 거쳐 바꾼다.

| From | Allowed Next |
|------|-------------|
| spec:drafting | spec:reviewing |
| spec:reviewing | spec:confirmed, spec:drafting |
| spec:confirmed | plan:ready |
| plan:ready | plan:reviewing |
| plan:reviewing | plan:confirmed, plan:ready |
| plan:confirmed | impl:in-progress |
| impl:in-progress | review:in-progress |
| review:in-progress | impl:in-progress, docs:generated |
| docs:generated | pr:created, review:in-progress |
| pr:created | docs:generated |

**에이전트가 임의로 상태를 옮길 수 없다는 원칙이 이미 구현되어 있다.** 이것은 §2.3이 요구하는 것과 같은 성질이다.

### 1.2 산출물 계약

`.harness/contracts/`에 5개 형식 계약이 있다.

| 계약 | 생산자 | 소비자 |
|---|---|---|
| `spec.md` | brainstorming 스킬 + `/flow-spec` | `/flow-spec` 분할 분석, Codex `spec-review` |
| `implementation-plan.md` | planner 에이전트 | Codex `plan-review`, `/flow-impl` |
| `spec-review.md` / `plan-review.md` | Codex | Claude |
| `review-report.md` | code-reviewer | Claude |

`implementation-plan.md` 계약의 Story 구조:

```markdown
### [ ] Story 1: <title>
- **Type**: tdd | config | infra | refactor | prompt
- **Goal**: [한 문장]
- **Tasks**:
  - [ ] T1.1 — <명령형 subject>
- **Completion Criteria**:
  - [ ] 검증 가능한 기준 1
- **Commit**: `<type>(<scope>): <subject>`
```

계약의 Key Constraints가 명시한다 — *"Completion Criteria must be verifiable (runnable command, observable output, or checkable file)"*. **요구는 이미 있다.**

### 1.3 그러나 완료 표시는 에이전트가 한다

`flow-impl` SKILL.md에서 확인된 것:

| 위치 | 동작 |
|---|---|
| Step 7 (235행) | "각 Completion Criterion을 단위 점검하고, **통과한 Criterion의 markdown 체크박스를 `[x]`로 갱신**한 뒤 PASS/FAIL 근거를 출력" |
| Step 7 (265행) | "통과한 Criterion → markdown `- [ ]` → `- [x]` Edit" |
| Step 9 (353행) | "Story checkbox: `### [ ] Story N` → `### [x] Story N`" |
| 182행 | "plan markdown 체크박스가 **단일 진실 원천**이므로…" |

즉 **판정자와 기록자가 같고, 기록 매체가 에이전트가 자유롭게 편집 가능한 markdown이다.** 토픽 수준(§1.1)에서는 스크립트가 막는 것을 Story 수준에서는 막지 않는다.

> **정정 (2026-08-06) — 관측은 유효하고 함의가 과했다.**
>
> 위 두 문장 중 **관측**(판정자=기록자, 매체가 자유 편집 가능)은 그대로다. **과한 것은 마지막 문장이 결손처럼 읽히게 만든 점이다** — 이 조사는 **Story 수준이 강제가 필요한지를 묻지 않았다.** 실제로 §8의 열린 질문 2가 *"이 비대칭이 의도적인지, 비용 때문인지, 단순 누락인지 확인되지 않았다"* 로 그것을 열어 뒀는데, **본문과 §0 요약표에는 그 한정어가 실리지 않았다.**
>
> **하네스 작성자의 진술로 해소됐다(2026-08-06, 1차 — 측정이 아니라 증언이다).** 이 체크박스는 `/flow-impl`의 **로컬 구현 루프에서 진행도를 기록·유지하는 용도**였고, 완료의 권위를 부여하려는 것이 아니었다. **계층 간 신호(토픽의 `phase`·`status`)는 §1.1의 스크립트가 이미 강제하고 있었다.**
>
> **따라서 이 절이 보이는 것은 "강제가 빠진 곳"가 아니라 "강제가 필요한 곳과 아닌 곳이 갈려 있는 모습"으로도 읽힌다.** 판별선은 **그 체크박스가 계층의 종료를 적는가**이다 — 로컬 진행이면 자기신고여도 손해가 재작업뿐이고, 계층 종료면 게이트가 무력화된다.
>
> **남는 것**: `Step 9`의 Story 체크박스가 그 선의 어느 쪽인지는 이 정정으로도 갈리지 않는다. 그리고 §3.1의 별개 지적 — **종착이 `pr:created`이지 "동작이 검증됨"이 아니다** — 은 이 정정의 영향을 받지 않는다.
>
> 후속: [설계 드래프트 §5-4](../draft/judgment.html#5-4)

---

## 2. 피쳐 목록이라는 프리미티브

출처: [Lecture 08 — Why Feature Lists Are Harness Primitives](https://walkinglabs.github.io/learn-harness-engineering/en/lectures/lecture-08-why-feature-lists-are-harness-primitives/) (§0의 신뢰도 경고 적용)

### 2.1 문서와 프리미티브의 구분

출처의 정의 — **문서는 인간이 무시할 수 있고, 프리미티브는 시스템이 우회할 수 없다.** 데이터베이스 제약 조건에 비유한다.

피쳐 목록이 프리미티브가 되려면 하네스의 4개 컴포넌트가 그것을 소비해야 한다고 규정한다.

| 컴포넌트 | 역할 |
|---|---|
| 스케줄러 | 상태를 읽어 다음 작업 선택 |
| 검증기 | 검증 명령 실행, 상태 전환 허가 |
| 핸드오프 리포터 | 진행 상황 요약 자동 생성 |
| 진행률 추적기 | 상태 분포 집계 |

### 2.2 규정하는 형식 — 삼중 구조

```json
{
  "id": "F03",
  "behavior": "POST /cart/items with {product_id, quantity} returns 201",
  "verification": "curl -X POST http://localhost:3000/api/cart/items...",
  "state": "passing",
  "evidence": "commit abc123, test output log"
}
```

| 필드 | 역할 |
|---|---|
| `behavior` | 무엇을 구현할지 |
| `verification` | **완료를 판단하는 객관적 기준** |
| `state` | 현재 상태 |
| `evidence` | 판정의 근거 |

### 2.3 규정하는 상태 머신

```
not_started → active → passing (불가역)
                 ↑ 검증 실패 시 active 유지
blocked
```

**핵심 규정**: *"에이전트는 상태를 임의로 변경할 수 없다. 검증 명령 성공만이 `active` → `passing` 전환을 허용한다."*

그리고 `passing`은 **불가역**이다.

### 2.4 규정하는 원칙

- **단일 진실 공급원** — "무엇을 해야 하는가"는 피쳐 목록에서만 유래하며, 대화 기록이나 코드 TODO와 모순이 없어야 한다
- **립도(granularity)** — "한 세션에 완료 가능한" 수준
- **동시 활성 제한** — CLAUDE.md에 "단일 피쳐만 활성화" 같은 규칙 명시

---

## 3. 기존 구조와의 대조

이 절이 이 조사의 핵심이다.

### 3.1 상태 기계는 있으나 추적 대상이 다르다

| | 기존 `dev-context.json` | 출처의 피쳐 목록 |
|---|---|---|
| 단위 | 토픽 (작업 단위) | 피쳐 (기능 단위) |
| 상태의 의미 | **워크플로우 어디까지 진행됐나** | **기능이 동작하는가** |
| 종착 상태 | `pr:created` | `passing` |
| 전환 근거 | 단계 완료 (사람·에이전트 판단) | **검증 명령 성공** |
| 강제 주체 | 스크립트 (전환표) | 하네스 (검증기) |
| 수명 | 토픽 종료 시 역할 종료 | 프로젝트 전체에 걸쳐 지속 |
| `verification` 필드 | 없음 | 필수 |
| `evidence` 필드 | 없음 | 필수 |

**`pr:created`는 "PR을 만들었다"이지 "기능이 동작한다"가 아니다.** 두 상태 기계는 서로 다른 것을 추적하며, 하나가 다른 하나를 대체하지 않는다.

### 3.2 프로젝트 수준의 지속 산출물이 없다

기존 구조의 산출물은 전부 토픽 단위다.

```
docs/_local/
├── backlog/<topic>/spec.md
├── active/<topic>/implementation-plan.md
└── done/<topic>/...
```

토픽이 `done`으로 가면 그 산출물은 아카이브가 된다. **"이 프로젝트가 가진 기능의 현재 상태"를 한곳에서 답하는 것이 없다.** `dev-context.json`의 `topics`가 가장 가깝지만 진행 중인 작업만 담고, 완료된 기능이 여전히 동작하는지는 담지 않는다.

### 3.3 요구는 있으나 강제가 없다

`implementation-plan.md` 계약은 이미 *"Completion Criteria must be verifiable (runnable command, observable output, or checkable file)"*를 요구한다. 출처의 `verification` 필드와 같은 취지다.

차이는 **누가 실행하고 누가 판정하는가**다.

| | 기존 | 출처 규정 |
|---|---|---|
| 검증 실행 | 에이전트 | 하네스(검증기) |
| 판정 | 에이전트 | 검증 명령의 종료 코드 |
| 기록 | 에이전트가 markdown Edit | 하네스가 상태 갱신 |
| 기록 매체 | 에이전트가 자유 편집 가능 | 에이전트 쓰기 불가 |

선행 조사와 이어지는 지점이 있다 — [오류 재발 방지 조사 §7.2](error-recurrence-prevention.md)가 "리뷰 지적의 **해소 결과가 어디에도 기록되지 않는다**"를 결정적 결직접 지목했다. `evidence` 필드는 같은 결손의 다른 얼굴이다.

---

## 4. 완료 판정과 범위 제약

### 4.1 조기 완료 선언 (강의 9)

출처가 제시하는 원인:

- **국소적 신뢰도로 전역적 정확성을 판단한다** — "코드가 작성되었다"에서 "기능이 동작한다"로 건너뛴다
- **신경망의 체계적 과신** (Guo et al., ICML 2017 인용) — **아래 정정 참조**
- **자기평가의 한계** — 같은 모델이 생성과 평가를 모두 하면 자신에게 관대해진다

> **정정 (2026-08-02 출처 감사).** 위 두 번째 항목의 인용을 원문으로 확인한 결과 **출처가 논문을 오용했다.** [Guo et al., *On Calibration of Modern Neural Networks*, ICML 2017](https://arxiv.org/abs/1706.04599)이 실제로 주장하는 것은 *"Modern neural networks, unlike those from a decade ago, are poorly calibrated"* 이며, 대상은 **이미지 분류기의 softmax 확률**이고 원인으로 *"Depth, width, weight decay, and Batch Normalization"* 을 들며 해법은 **temperature scaling**이다.
>
> 이는 **분류기가 출력하는 확률값이 실제 정확도와 어긋난다**는 주장이지, **에이전트가 작업 완료를 조기에 선언한다**는 주장이 아니다. 두 현상은 다르다 — 전자는 보정 문제이고 후자는 자기 상태 판단 문제다. 논문은 후자를 다루지 않는다.
>
> **현상 자체(조기 완료 선언)는 이 조사 범위 밖에서도 관측된다** — [검증·교차리뷰 조사 §2.4](verification-and-cross-review.md)가 계약의 도출식과 어긋나는 `status` 기입을, §1.2가 에이전트가 자기 검증을 실행하고 판정하는 구조를 1차 관측했다. **현상은 유효하고, 인용된 근거만 무효다.**

단위 테스트 통과가 완료가 아닌 이유로 셋을 든다: 인터페이스 불일치(목 환경에서 안 잡힘), 상태 전파 오류, 환경 의존성.

규정하는 3계층 종료 검증:

| 계층 | 내용 |
|---|---|
| 1 | 문법·정적 분석 |
| 2 | 실행 동작 (단위·통합 테스트, 애플리케이션 기동) |
| 3 | 시스템 수준 (E2E, 사용자 시나리오) |

그리고 **완료 우선순위 제약** — 기능적 정확성 → 성능 → 스타일 순. *"리팩터링하면서 할 수 있습니다"는 검증된 코드와 미검증 코드의 경계를 흐린다*고 규정한다.

**기존 하네스와의 관계**: `/flow-impl`이 Story마다 code-reviewer를 부르고 `/flow-verify`가 빌드·테스트·보안을 돌리므로 계층 1~2는 있다. 계층 3(E2E)은 하네스 자신에 적용할 형태가 불분명하다(§5).

### 4.2 범위 초과와 미완 (강의 7)

출처는 둘을 **상호 증폭 관계**로 본다 — 범위 초과가 주의를 분산시키고, 분산이 미완을 낳고, 남은 미완 코드가 복잡도를 올려 다음 작업의 범위 초과를 유발한다.

규정하는 메커니즘 셋:

1. **완료 증거의 명시화** — 실행 가능한 검증 명령
2. **범위 표면의 외부화** — JSON/markdown의 기계 가독 상태
3. **VCR(검증 완료율) 모니터링** — `검증된 작업 / 활성화된 작업`. **VCR < 1.0이면 새 작업 활성화를 차단**

WIP=1을 안전한 기본값으로 제시한다.

**기존 하네스와의 관계**: `/flow-impl`은 기본적으로 Story 하나만 실행하고 멈춘다(WIP=1에 해당). 그러나 `--all`과 `config.dev_impl.batch_mode`로 연속 실행이 가능하고, **관측된 실제 설정에서 `batch_mode: true`다**. VCR에 해당하는 지표는 없다.

> **WIP=1 수치의 근거 상태 (2026-08-02 출처 감사).** 출처의 "WIP 제한이 완료율을 높인다"는 주장을 뒷받침할 신뢰 가능한 자료를 **찾지 못했다.** 대기행렬 이론(Little's Law)은 WIP과 처리량·리드타임의 관계를 주지만 **"완성률 45% 향상" 같은 결과 품질 주장을 주지 않는다** — 다른 양에 대한 정리다. 제조·제품개발 쪽 실무서(Reinertsen 등)가 방향은 지지하나 그 역시 피어리뷰 문헌이 아니므로, 인용해봐야 **미검증 출처를 평판 좋은 미검증 출처로 바꾸는 것**에 그친다.
>
> 따라서 이 문서는 다음까지만 말한다 — **WIP 축소의 방향성은 대기행렬 이론상 그럴듯하고, 구체적 수치는 근거가 없다.** §8-6의 판단 보류는 유지된다.

### 4.3 립도 — 이 축에는 재현된 수치가 있다

> 이 절은 최초 작성 시 없었고 **2026-08-02 출처 감사에서 추가**됐다. §8-10이 "립도 기준의 조작적 정의"를 열린 질문으로 남겼는데, 그 축에는 **피어리뷰된 데이터가 이미 존재한다.**

출처가 제시하는 립도 기준은 *"한 세션에 완료 가능한"* 이다. 이 정의는 컨텍스트 크기·모델·작업 종류에 따라 달라져 조작 불가능하다. 그런데 **"리뷰 가능한 변경의 크기"** 라는 인접 질문에는 20년치 실증이 있다.

**두 편이 서로 다른 조직·시기·방법으로 수렴한다.**

| | [Rigby & Bird, FSE 2013](https://www.microsoft.com/en-us/research/wp-content/uploads/2016/02/rigby2013convergent.pdf) | [Sadowski et al., ICSE-SEIP 2018](https://sback.it/publications/icse2018seip.pdf) |
|---|---|---|
| 대상 | Android, Chromium OS, Bing, Office, MS SQL, AMD + OSS(Apache·Linux·KDE) + Lucent | Google 전체 |
| 표본 | 다중 조직 비교 | **리뷰된 변경 900만 건** + 인터뷰 12 + 설문 44 |
| **변경 크기 중앙값** | Apache 25줄 · Linux 32줄 · **Android/AMD 44줄** · Chrome **78줄 / 5파일** · Lucent(1998) 263줄 | **24줄** |
| 파일 수 | Chrome 5파일 | **35%가 단일 파일**, **90%가 10파일 미만** |
| **리뷰어 수** | 중앙값 **2명** | 중앙값 **1명**, 25% 미만이 2명 초과 |
| 리뷰 소요 | 중앙값 14.7~20.8시간 | 전체 중앙값 **4시간 미만**, 70%가 24시간 내 커밋 |

Rigby & Bird의 결론은 **수렴 자체**다 — 조직·문화·인센티브·시간압력이 전혀 다른데도 *"their similarities outweighed their differences"* 였다. 그리고 리뷰어 수에 대해 **수확 체감을 직접 측정**했다: 리뷰어를 늘려도 *"only a minimal increase in the number of comments about the change"* 였고 제출된 change set 수는 늘지 않았다.

Sadowski et al.은 작은 변경이 **의도된 실천**임을 명시한다.

> *"developers are strongly encouraged to make small, incremental changes"*
> 근거: *"Previous studies have found that the number of useful comments decreases and the review latency increases as the size of the change increases."*

**이것이 §8-10에 주는 답의 형태.** "한 세션"이 아니라 **24~44줄 / 1~5파일**이 실측된 중심값이다. 다만 그대로 이식하면 안 되는 이유가 둘 있다.

1. **대상이 사람 리뷰어다.** 에이전트 리뷰어의 유효 처리 용량이 사람과 같다는 근거는 없다. 다만 [검증·교차리뷰 조사 §3.1](verification-and-cross-review.md)이 인용한 Google의 "인지 부담" 상한(뮤턴트 노출량 = 파일 수 × 7)은 같은 방향의 제약이 자동화 도구에도 걸린다는 것을 보여준다.
2. **Story ≠ 커밋.** 기존 하네스의 Story는 여러 Task와 하나의 커밋으로 구성되므로 위 수치와 단위가 정확히 대응하지 않는다.

**그럼에도 방향은 분명하다 — 실증된 리뷰 단위는 이 하네스가 Story에 담는 양보다 훨씬 작다.** 그리고 리뷰어 수에서도 대조점이 나온다: 실증된 중앙값은 1~2명이고 수확 체감이 측정되었는데, **cygnus는 코드리뷰에 3종을 돌린다**([검증·교차리뷰 §2.1](verification-and-cross-review.md)). 사람과 에이전트가 같은 곡선을 따르는지는 미확인이다.

---

## 5. 검증 필드 문제 — 하네스는 웹앱이 아니다

### 5.1 문제

출처의 `verification` 예시는 전부 실행 가능한 명령이다.

```
curl -X POST http://localhost:3000/api/cart/items ... 
curl -X POST /api/register -d '...' | jq .status == 201
```

**grid fin이 만드는 것의 상당 부분은 markdown, 프롬프트, 스킬 정의다.** "이 스킬이 의도한 상황에서 발동한다", "이 규칙이 지켜진다"에 대응하는 `curl`이 없다.

이것은 아젠다 §6(평가)이 다루는 "스킬 활성화 측정"과 같은 문제이며, 여기서는 **피쳐 목록의 필수 필드를 채울 수 있는가**라는 형태로 나타난다.

### 5.2 기존 하네스가 이미 국소적으로 푼 부분

`implementation-plan.md` 계약의 `prompt` Story 타입에 **Eval 스키마**가 있다.

| 전략 | 적용 기준 | 필수 필드 |
|---|---|---|
| `direct` | 정확한 텍스트·구조 일치 | Input, Expected |
| `rubric` | 주관적 품질 (어조, 간결성, 준수) | Input, Criteria, Rubric, Pass |
| `judge` | 복잡한 추론·정확성 (Claude-as-judge 별도 평가) | Input, Expected, Pass, Judge Criteria |

```markdown
- [ ] Eval 2 [rubric]: Input: "<시나리오>"
    Criteria: "<평가 기준>"
    Rubric: "1=<나쁜 예>, 5=<좋은 예>"
    Pass: score >= 4
- [ ] Acceptance: 2/2 eval 통과   ← 필수
```

**이것이 코드가 아닌 산출물에 대한 기계 판정 가능한 완료 기준이다.** `Acceptance: N/M`은 종료 코드에 대응하는 이진 판정을 준다.

세 가지가 걸린다.

1. **적용 범위가 `prompt` Story 타입 하나로 한정되어 있다.** 다른 타입(`config`, `infra`)의 Completion Criteria는 자유 형식이다.
2. **`judge` 전략은 판정자가 다시 LLM이다.** §4.1이 지적한 자기평가 문제가 재귀한다 — 다만 별도 에이전트라는 점에서 §4.1의 "독립 평가자" 요구에는 부합한다.
3. **실행 주체가 여전히 에이전트다.** §1.3의 문제가 여기에도 걸린다.

**조사 질문**: 이 Eval 스키마가 `prompt` 타입을 넘어 일반화되는가. 일반화된다면 §5.1의 문제가 상당 부분 해소된다.

---

## 6. 기존 구현체 비교

### 6.1 GitHub Spec Kit

7단계 워크플로우 + 보조 커맨드 3종.

| 단계 | 커맨드 | 산출물 | 기존 하네스 대응 |
|---|---|---|---|
| Constitution | `/speckit.constitution` | `specs/constitution.md` | **없음** |
| Specify | `/speckit.specify` | `specs/spec.md` | `/flow-spec` |
| Plan | `/speckit.plan` | `specs/plan.md` | `/flow-plan` |
| Tasks | `/speckit.tasks` | `specs/tasks.md` | plan 안의 Story 목록 |
| Tasks→Issues | `/speckit.taskstoissues` | GitHub Issues | 없음 (선택) |
| Implement | `/speckit.implement` | 코드 | `/flow-impl` |
| Converge | `/speckit.converge` | 스펙 대비 평가 | **없음** |

보조 커맨드:

| 커맨드 | 역할 | 기존 하네스 대응 |
|---|---|---|
| `/speckit.clarify` | 불명확한 영역 명확화 | spec의 Open Questions 섹션 (수동) |
| `/speckit.analyze` | **산출물 간 일관성 분석** | **없음** — Codex review가 부분적으로 대행 |
| `/speckit.checklist` | 품질 검증 체크리스트 생성 | Codex review의 고정 8항목 체크리스트 |

**기존 하네스에 없는 세 가지가 눈에 띈다.**

- **Constitution** — 프로젝트 통제 원칙. 모든 후속 결정의 기초. 기존 하네스에서는 `.harness/rules/`와 CLAUDE.md가 나눠 갖고 있으나 "프로젝트별 원칙"이라는 계층은 없다
- **Analyze** — 스펙·계획·태스크 사이의 일관성 검사. 선행 조사가 지적한 "상위 산출물과의 델타 = 오류"와 정확히 같은 대상이다
- **Converge** — 구현 완료 후 코드베이스를 스펙에 대조. §3.1의 "종착 상태가 `pr:created`" 문제와 이어진다

Spec Kit은 템플릿 해석에 4단계 우선순위(overrides → presets → extensions → core)를 두는데, 이는 [배포 조사](harness-distribution.md)의 core/config 계층 문제와 같은 구조다.

### 6.2 Spec Kit Agents (arXiv 2604.05278)

Pardis Taghavi, Santosh Bhavani (2026-04-07). Spec Kit의 4단계(Specify, Plan, Tasks, Implement)에 **read-only probing hook**을 붙여 각 단계를 저장소 증거에 접지시킨다. validation hook이 중간 산출물을 환경과 대조한다.

**평가**: 5개 저장소 32개 기능 128회 실행. LLM-as-judge 1~5 복합 점수 **+0.15 (+3.0%)**, 저장소 수준 테스트 호환성 99.7~100%, SWE-bench Lite Pass@1 **58.2% (+1.7%p)**.

**해석 주의** — 효과 크기가 작다. 다만 *"각 단계를 저장소 증거에 접지시킨다"*는 발상 자체는 선행 조사의 권고 #2("단계 진입 시 조회를 필수 스텝으로 박는다")와 같은 방향이며, 그쪽은 다른 근거에서 도출됐다.

### 6.3 세 구현체의 단계 대응

| | Spec Kit | Spec Kit Agents | 기존 하네스 |
|---|---|---|---|
| 원칙 계층 | constitution | 상동 | `.harness/rules/` (프로젝트별 아님) |
| 스펙 | specify | + grounding hook | `/flow-spec` + Codex 8항목 리뷰 |
| 계획 | plan | + grounding hook | `/flow-plan` + Codex 8항목 리뷰 |
| 태스크 | tasks (별도 파일) | + grounding hook | plan 내부 Story 목록 |
| 구현 | implement | + validation hook | `/flow-impl` (Story 단위, code-reviewer 자동) |
| 일관성 검사 | analyze | — | 없음 |
| 사후 수렴 | converge | — | 없음 |
| 독립 리뷰어 | 없음 | 없음 | **Codex (다른 모델 패밀리)** |

**기존 하네스가 두 구현체보다 앞선 지점이 하나 있다** — 스펙·계획 단계에 다른 모델 패밀리의 독립 리뷰어를 둔 것. 아젠다 §4(다중 모델 교차 리뷰)가 다룰 주제이며, 선행 조사 §7이 그 산출물 55건을 이미 분석했다.

---

## 7. 좋은 스펙의 조건

출처: [How to write a good spec for AI agents — Addy Osmani](https://addyosmani.com/blog/good-spec/). GitHub의 2,500개 이상 에이전트 설정 파일 분석에 근거한다고 밝힌다(수치는 저자 주장이며 재현하지 않았다).

### 7.1 6가지 필수 요소

| 요소 | 내용 |
|---|---|
| Commands | 실행 가능한 전체 명령어 |
| Testing | 프레임워크, 파일 위치, 커버리지 기준 |
| Project Structure | 소스·테스트·문서 위치 |
| Code Style | **텍스트 설명보다 코드 예시** |
| Git Workflow | 브랜치명, 커밋 형식, PR 요구사항 |
| Boundaries | 금지·권장·조건부 |

**기존 하네스의 `spec.md` 계약과 대조하면 성격이 다르다.** 기존 계약은 개요·목표·아키텍처·의사결정·범위 밖·Open Questions로, **무엇을 만들 것인가**에 집중한다. 위 6가지는 **어떻게 작업할 것인가**에 가깝고, 기존 하네스에서는 CLAUDE.md/AGENTS.md와 `.harness/rules/`가 담당하는 영역이다.

즉 이 출처의 "스펙"은 기존 하네스의 "스펙"과 다른 것을 가리킨다. 용어 충돌에 주의가 필요하다.

### 7.2 3단계 경계 체계

```
✅ Always Do    항상 수행 (승인 불필요)
⚠️ Ask First    인간 검토 필요
🚫 Never Do     절대 금지
```

기존 하네스의 `.harness/rules/`는 이 3분류를 명시적으로 쓰지 않는다. Codex의 `approval_policy`와 개념적으로 대응한다(아젠다 §2).

### 7.3 "지시의 저주"와 모듈화

*"지시가 많을수록 모델의 준수율은 하락"* — 제시하는 대응 셋:

1. 단계별 피드 — 해당 단계의 스펙 섹션만 제공
2. 서브에이전트 — 각자 자기 섹션만 소유 (2~3개가 관리 한계)
3. 확장 목차 — 각 섹션 500단어를 2~3줄로 요약, 필요 시에만 전문

**3번이 [배포 조사 §6.3](harness-distribution.md)의 상시/온디맨드 분류와 같은 구조다.** 아젠다 §1이 다룰 주제와 직접 겹친다.

### 7.4 안티패턴

| 안티패턴 | 문제 |
|---|---|
| 모호한 지시 | "멋진 걸 만들어" |
| 요약 없는 초장문 | 50페이지를 통째로 |
| 인간 리뷰 생략 | 테스트 통과 ≠ 정확한 코드 |
| 6요소 누락 | 에이전트가 필요 정보 부족 |
| 한 번에 모두 담기 | 컨텍스트 오버로드 |

---

## 8. 열린 질문

1. **피쳐 목록은 새 산출물인가, `dev-context.json`의 확장인가.** §3.1이 보인 대로 둘은 다른 것을 추적한다. 하나로 합칠 수 있는지, 합치면 무엇을 잃는지 미확인.
2. ~~**누가 상태 전환을 통제해야 하는가.** 토픽 수준은 스크립트가 막고 Story 수준은 안 막는 현재 비대칭이 의도적인지, 비용 때문인지, 단순 누락인지 확인되지 않았다.~~ **해소됨 (2026-08-06, [§1.3 정정](#13-그러나-완료-표시는-에이전트가-한다)) — 의도적이었다.** 하네스 작성자의 진술: Story·Criterion 체크박스는 **로컬 구현 루프의 진행 기록**이고 계층 간 신호는 토픽 상태 기계가 담당했다. **등급은 1차이되 증언이지 측정이 아니다.** 그리고 **남은 질문 하나** — `Step 9`의 Story 체크박스가 로컬 진행인지 계층 종료인지는 갈리지 않았다.
3. **`prompt` Story의 Eval 스키마가 일반화되는가** (§5.2). 일반화되면 §5.1의 검증 필드 문제가 상당 부분 해소된다.
4. **`judge` 전략의 재귀 문제.** LLM이 LLM을 판정하는 구조에서 §4.1의 과신 문제가 어떻게 완화되는지 근거 미확인.
5. **VCR 같은 지표가 개인 규모에서 의미가 있는가.** 동시 활성 토픽이 1~2개인 환경에서 `검증된/활성화된` 비율이 신호를 주는지.
6. **`batch_mode: true`가 WIP=1 원칙과 충돌하는가.** 관측된 설정은 batch 연속 실행이다. 출처의 주장(WIP=1이 완료율을 높인다)이 단일 출처·미검증이므로 판단 근거가 부족하다.
7. **Constitution 계층이 필요한가.** 기존 하네스는 `.harness/rules/`(하네스 소유)와 CLAUDE.md(프로젝트 소유)로 갈라져 있고, "프로젝트별 원칙"이라는 중간 계층이 없다. 배포 조사의 core/config 경계 문제와 얽힌다.
8. **`analyze`(산출물 간 일관성)를 Codex review가 이미 대행하는가.** 선행 조사가 분석한 리뷰 체크리스트 16항목이 이 역할을 어디까지 덮는지 대조되지 않았다.
9. **`converge`(사후 스펙 대조)가 도는 단계.** `/flow-review`·`/flow-verify`가 코드 품질을 보지만 스펙 대비 완전성을 보지는 않는다.
10. **립도 기준의 조작적 정의.** ~~"한 세션에 완료 가능"은 컨텍스트 크기·모델·작업 종류에 따라 달라진다.~~ **부분적으로 해소됨 (§4.3).** 사람 리뷰 기준으로는 중앙값 24~44줄 / 1~5파일이 두 편의 피어리뷰 문헌에서 수렴한다. **남은 질문은 셋이다** — (a) 에이전트 리뷰어에게 같은 곡선이 적용되는가, (b) Story 단위를 이 수치에 맞추면 Story 수가 늘어나는데 그 오버헤드가 이득을 상쇄하는가, (c) 기존 `spec.md` 계약의 분할 기준(독립 배포·독립 롤백·비의존)과 크기 기준이 충돌할 때 무엇이 우선인가.

---

## 부록. 조사 방법 및 한계

**방법**
- WebFetch 6회 — walkinglabs 강의 7·8·9, arXiv 2604.05278(초록), GitHub Spec Kit, Addy Osmani
- WebSearch 3회 — spec-driven 워크플로우, 태스크 분해 립도, 하네스 일반
- 로컬 직접 읽기 — `.harness/contracts/spec.md`·`implementation-plan.md` 전문, `dev-context.js`, `docs/specs/topic-lifecycle.md`, `flow-spec`/`flow-plan`/`flow-impl`/`flow-topic` SKILL.md, 실제 `dev-context.json`

**직접 확인 (1차 관측)**
- `PROTECTED_FIELDS = new Set(['phase','status'])` — `.harness/scripts/dev-context.js:28`
- 상태 전환표 — `docs/specs/topic-lifecycle.md`
- 에이전트의 체크박스 Edit — `src/.claude/skills/flow-impl/SKILL.md` 182·235·265·353행
- Story 형식·Eval 스키마 — `.harness/contracts/implementation-plan.md` 전문
- 스펙 섹션 구조·분할 기준 — `.harness/contracts/spec.md` 전문
- 관측 시점의 `config.dev_impl.batch_mode: true` — `docs/_local/dev-context.json`


**2026-08-02 재구성**: 외부 자료를 「구현 참조 자료」 절로 앞당겨 모았고 1차 관측 절을 보조 근거로 재프레이밍했다. **절 번호는 유지했다** — 조사 문서 8건이 서로를 §번호로 참조하므로 재번호는 그 링크 그래프를 조용히 깨뜨린다.

**한계**
- **§2·§4의 형식 규정과 모든 수치는 단일 자가출판 출처에서 나왔다.** §0의 경고 참조. 구조적 주장과 수치를 분리해 읽어야 한다.
- arXiv 2604.05278은 **초록만 확인**했다. 본문 PDF 추출에 실패해 grounding hook의 구체 메커니즘, 실험 설정, 베이스라인 구성을 확인하지 못했다. 인용한 수치는 초록 기재값이다.
- Spec Kit은 저장소 README 수준에서만 확인했다. 각 커맨드의 실제 프롬프트와 템플릿 내용은 읽지 않았다.
- Addy Osmani 글의 "GitHub 2,500개 설정 파일 분석"은 저자 주장이며 원 데이터를 확인하지 않았다.
- ~~태스크 분해 립도에 관한 학술 자료(RSTD 등)는 검색 요약 수준으로만 확인했다.~~ **2026-08-02 보강** — §4.3에서 Rigby & Bird(FSE 2013)와 Sadowski et al.(ICSE-SEIP 2018) **본문**을 확인해 립도 축을 피어리뷰 근거로 교체했다. 다만 두 편 모두 **사람 리뷰어 대상**이고, 에이전트에 대한 전이는 미검증이다.
- **Guo et al. 인용은 오용이었다** (§4.1 정정). 최초 작성 시 강의를 통한 2차 인용을 그대로 실었고, 원문 확인 없이 "신경망의 체계적 과신"으로 요약했다. **2차 인용을 검증 없이 옮긴 것이 이 문서의 실제 결함이다** — 강의의 수치를 경계하면서 강의가 인용한 논문은 경계하지 않았다.
- WIP=1 수치에 대해 **뒷받침 자료를 찾지 못했음을 확인했다**(§4.2). 없는 근거를 만들지 않기 위해 대기행렬 이론이나 실무서로 대체 인용하지 않았다.

**출처 감사 이력**

| 일자 | 내용 |
|---|---|
| 2026-08-02 (최초) | 강의 7·8·9 + Spec Kit README + Addy Osmani + arXiv 2604.05278 초록 |
| 2026-08-02 (보강) | §4.3 신설 (Rigby & Bird FSE 2013, Sadowski et al. ICSE-SEIP 2018 본문), §4.1 Guo et al. 정정 (arXiv 1706.04599 원문), §4.2 WIP 근거 부재 명시, §0 축별 근거 상태표 추가 |
- **cygnus에서 이 워크플로우가 실제로 어떻게 돌았는지는 이 조사에서 보지 않았다.** 선행 조사가 리뷰 산출물 55건을 분석했으나, Story 완료율·재작업률·범위 초과 빈도 같은 실행 지표는 미측정이다.
