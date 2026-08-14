# 에이전트 조율 — 구현 참조 자료

**최초 작성**: 2026-08-02
**최종 수정**: 2026-08-02
**대상 프로젝트**: grid fin (신규 개인용 개발 하네스)
**성격**: **자료 수집·정리.** grid fin 구현 시 참조할 외부 자료를 모으고 정돈한다. 조율 구조를 선택하지 않는다.
**조사 도구**: WebFetch 4회(1차 본문·공식 규격), WebSearch 1회(자료 위치 파악), 하네스 실측(보조)

선행 문서
- [research-agenda.md](research-agenda.md) §5 — 이 조사의 출처
- [verification-and-cross-review.md](verification-and-cross-review.md) §4.1 — 교차 리뷰 경로
- [observability.md](observability.md) §2.3 — 리뷰어 절반이 `codex exec`다
- [evaluation.md](evaluation.md) §4.2 — 서브에이전트 채택률 4.6%

---

## 0. 이 문서의 쓰임 — 그리고 결론

**세 자료가 서로 다른 방법으로 같은 방향을 가리킨다. 이 시리즈에서 이만큼 수렴한 사례가 없다.**

| 자료 | 층 | 무엇을 주는가 | 등급 |
|---|---|---|---|
| [Anthropic, *How we built our multi-agent research system*](https://www.anthropic.com/engineering/multi-agent-research-system) | **벤더 실무** | 토큰 15배, 적합·부적합 영역 구분, 초기 실패 양상 | 1차 (벤더 공식) |
| [Cemri et al., *Why Do Multi-Agent LLM Systems Fail?*](https://arxiv.org/abs/2503.13657) | **실패 분류** | 실패 모드 14종과 비율, 실패율 41~86.7%, 개입 상한 | **피어리뷰 ([NeurIPS 2025 D&B Track](https://proceedings.neurips.cc/paper_files/paper/2025/hash/b1041e52d3be19f0a9bc491657488e4a-Abstract-Datasets_and_Benchmarks_Track.html))** |
| [Claude Code — Subagents](https://code.claude.com/docs/en/sub-agents) | **플랫폼 규격** | 중첩 깊이, 선택 기준, fork의 캐시 재사용 | 1차 문서 (공식) |
| [Bui, *Building Effective AI Coding Agents for the Terminal*](https://arxiv.org/abs/2603.05344) | 설계 서술 | 계획·실행 분리 아키텍처의 명명 | 프리프린트 (WIP, 수치 없음) |

**§1~§4가 자료다. §5는 실측이며 보조 목적이다.**

### 결론의 형태

**개인용 코딩 하네스에서 다중 에이전트 조율은 자료가 지지하지 않는다.** 세 갈래의 근거가 독립적이다.

| 출처 | 근거 유형 | 진술 |
|---|---|---|
| 벤더 실무 | 경험 | *"most coding tasks involve fewer truly parallelizable tasks than research"* |
| 피어리뷰 실증 | 측정 | 다중 에이전트는 *"minimal performance gains"*, 7개 구현에서 실패율 **41~86.7%** |
| 저장소 실증 | 채택률 | 2,853개 저장소 중 서브에이전트 사용 **4.6%** ([평가 조사 §4.2](evaluation.md)) |

아젠다 §5의 미착수 사유가 *"단일 사용자 규모에서 실익 판단이 어려움"* 이었다. **자료는 판단이 어렵다고 하지 않는다 — 이 영역에서는 쓰지 말라고 한다.** 다만 §3이 보이듯 "서브에이전트"와 "다중 에이전트 시스템"은 같은 것이 아니며, 그 구분이 이 문서의 실제 쓸모다.

---

## 1. 벤더 실무 — 어디에 맞고 어디에 안 맞는가

[Anthropic 공학 문서](https://www.anthropic.com/engineering/multi-agent-research-system). 자사 Research 기능의 구축 경험을 적은 1차 자료다.

### 1.1 비용

> *"agents typically use about **4×** more tokens than chat interactions, and multi-agent systems use about **15×** more tokens than chats"*

그리고 성능 변량의 설명력:

> *"token usage by itself explains **80%** of the variance"*

**이 두 문장이 함께 오는 것이 중요하다.** 다중 에이전트가 잘하는 이유의 상당 부분이 구조가 아니라 **토큰을 더 쓴 것**이라는 뜻이 된다. [평가 조사 §1](evaluation.md)의 관점에서 보면, 구조 효과와 예산 효과가 분리되지 않은 비교다.

성능 수치도 있다. **원문 그대로 적는다.**

> *"We found that a multi-agent system with Claude Opus 4 as the lead agent and Claude Sonnet 4 subagents outperformed single-agent Claude Opus 4 by 90.2% **on our internal research eval**."*

**"내부 리서치 eval에서의 90.2% 개선"이지 90.2점 차이가 아니다.** 평가 구성·표본 수는 공개되지 않았다(§6-1). 복잡한 질의의 소요 시간은 최대 **90%** 줄었다고 한다. **셋 다 리서치 과제 기준이며 코딩 과제가 아니다.**

### 1.2 적합 영역과 부적합 영역

| 맞는다 | 안 맞는다 |
|---|---|
| *"breadth-first queries that involve pursuing multiple independent directions simultaneously"* | ***"most coding tasks involve fewer truly parallelizable tasks than research"*** |
| *"heavy parallelization, information that exceeds single context windows, and interfacing with numerous complex tools"* | *"domains that require all agents to share the same context or involve many dependencies"* |
| *"open-ended problems where it's very difficult to predict the required steps in advance"* | *"LLM agents are not yet great at coordinating and delegating to other agents in real time"* |

**벤더가 자기 제품의 구조를 설명하면서 코딩을 부적합 쪽에 명시적으로 놓았다.** grid fin이 코딩 하네스이므로 이 문장이 이 문서에서 가장 직접적인 자료다.

### 1.3 초기 실패 양상

> 에이전트가 *"spawning **50 subagents** for simple queries, scouring the web endlessly for nonexistent sources"*, 서로를 *"distracting each other with excessive updates"*

**아젠다 §5-5가 물은 "범위 초과(overreach)"의 구체 사례다.** 그리고 §2가 이것을 분류와 비율로 받는다.

---

## 2. 피어리뷰 실증 — 실패 모드 14종

[Mert Cemri, Melissa Z. Pan, Shuyi Yang 외, *Why Do Multi-Agent LLM Systems Fail?*](https://arxiv.org/abs/2503.13657) (arXiv 2503.13657, **v3 HTML 본문 확인**). [NeurIPS 2025 Datasets & Benchmarks Track](https://proceedings.neurips.cc/paper_files/paper/2025/hash/b1041e52d3be19f0a9bc491657488e4a-Abstract-Datasets_and_Benchmarks_Track.html) 채택. **이 시리즈에서 [평가 조사 §2](evaluation.md)의 ICML 논문에 이은 두 번째 피어리뷰 자료다.**

### 2.1 방법과 규모

| 항목 | 값 |
|---|---|
| 주석 트레이스 | **1,642건** |
| MAS 프레임워크 | **7종** |
| 모델 계열 | GPT-4, Claude 3, Qwen2.5, CodeLlama |
| 주석자 | 근거이론 단계 6명, IAA 검증 3명 |
| 주석자 간 일치도 | **κ = 0.88** (사람), κ = 0.77 (LLM 주석기) |

**κ 0.88은 분류 체계 자체가 재현 가능하다는 뜻이다.** 실패 분류를 다루는 자료에서 이 수치가 있는 경우가 드물다.

### 2.2 실패 모드 14종과 비율

| 범주 | ID | 모드 | 비율 |
|---|---|---|---:|
| **FC1 시스템 설계** | FM-1.1 | Disobey task specification | 11.8% |
| | FM-1.2 | Disobey role specification | 1.5% |
| | FM-1.3 | **Step repetition** | **15.7%** |
| | FM-1.4 | Loss of conversation history | 2.80% |
| | FM-1.5 | **Unaware of termination conditions** | **12.4%** |
| **FC2 에이전트 간 어긋남** | FM-2.1 | Conversation reset | 2.20% |
| | FM-2.2 | Fail to ask for clarification | 6.80% |
| | FM-2.3 | Task derailment | 7.40% |
| | FM-2.4 | Information withholding | 0.85% |
| | FM-2.5 | Ignored other agent's input | 1.90% |
| | FM-2.6 | **Reasoning-action mismatch** | **13.2%** |
| **FC3 과제 검증** | FM-3.1 | Premature termination | 6.20% |
| | FM-3.2 | No or incomplete verification | 8.20% |
| | FM-3.3 | Incorrect verification | 9.10% |

> **비율을 더하면 안 된다.** MAST는 **다중 라벨**이다 — 한 트레이스가 여러 모드를 동시에 갖는다(부록에 세 모드가 함께 붙은 예가 있다). 위 비율은 1,642 트레이스 전체에서의 **출현율**이며 **합이 100%가 되지 않는다.** 아래 서술에서 범주를 묶어 말할 때도 산술 합이 아니라 **모드들이 같은 범주에 몰려 있다**는 뜻이다.

**아젠다 §5-5가 "범위 초과와 미완이 왜 한 묶음인가"를 물었다. 분류가 답을 준다 — 둘은 다른 범주가 아니라 같은 범주(FC1 시스템 설계)의 이웃이다.** 반복 수행(**15.7%**, 범주 최다)과 종료 조건 미인지(**12.4%**)가 나란히 상위에 있고, 둘 다 "언제 멈출지가 정의되지 않았다"는 하나의 결손에서 나온다. **다중 라벨이므로 같은 트레이스가 둘 다 가질 수 있고, 그 사실 자체가 두 증상의 동반 출현을 뒷받침한다.**

**그리고 FC3 검증 범주 세 모드가 각각 6.2% · 8.2% · 9.1%로 고르게 높다.** [검증·교차리뷰 조사](verification-and-cross-review.md)가 이 하네스에서 실측한 것이 정확히 그 범주다 — 훅 9개 중 게이트 0개, 지적 163건 중 78.5% 미조치. **저쪽은 한 하네스의 관측, 이쪽은 7개 프레임워크 1,642 트레이스의 분포다.**

### 2.3 다중 에이전트가 단일보다 낫지 않다

> 다중 에이전트 시스템은 단일 에이전트 대비 *"minimal performance gains"* 를 보이고, 7개 최신 구현에서 **41%~86.7%** 의 실패율을 기록한다. 성능은 종종 *"best-of-N sampling"* 같은 단순 접근과 비슷하다.

**best-of-N과 비슷하다는 진술이 특히 값지다.** [평가 조사 §3](evaluation.md)의 `pass@k`가 바로 그 형태다 — **같은 예산으로 여러 번 시도하는 것**이 조율 구조의 대안이고, 자료에 따르면 대등하다.

### 2.4 개입은 듣지만 천장이 낮다

**한쪽**: ChatDev에서 역할 경계를 제대로 지키게 하는 개입만으로 **모델 변경 없이 전체 성공률 +9.4%** 를 얻었다. **조율 설계가 실제로 중요하다는 가장 강한 증거다.**

**다른 쪽**: 프롬프트 조정과 워크플로우 변경으로 얻은 최대 개선이 **15.6%** 이고, 그래도 *"task completion rates still remain low."* 논문의 결론은 이렇다.

> *"achieving robust MAS reliability often requires more than isolated fixes, pointing towards the need for more complex solutions and fundamental MAS redesigns."*

**두 절반을 함께 읽어야 한다.** 개입이 듣는다는 것은 권고가 아니고, 천장이 있다는 것이 권고의 이유다.

---

## 3. 플랫폼 규격 — 서브에이전트는 다중 에이전트 시스템이 아니다

[Claude Code 공식 문서](https://code.claude.com/docs/en/sub-agents) 본문을 확인했다. **§1·§2가 다루는 "다중 에이전트 시스템"과 이 문서가 규정하는 "서브에이전트"의 목적이 다르다.**

### 3.1 목적은 조율이 아니라 컨텍스트 격리다

> *"Use one when a side task would flood your main conversation with search results, logs, or file contents you won't reference again: the subagent does that work in its own context and **returns only the summary**."*

문서가 드는 효용 다섯 가지가 **컨텍스트 보존 / 도구 제약 강제 / 설정 재사용 / 행동 특화 / 비용 통제**다. **"병렬화로 더 잘한다"가 목록에 없다.**

**아젠다 §5-3이 물은 "오케스트레이터가 압축된 요약만 받는 패턴"이 곧 이 기제의 기본 동작이다.** 별도 설계가 아니라 규격이다.

### 3.2 선택 기준 (원문)

| **본 대화**를 쓸 때 | **서브에이전트**를 쓸 때 |
|---|---|
| 잦은 왕복·반복 개선이 필요할 때 | 본 컨텍스트에 필요 없는 장황한 출력이 나올 때 |
| 계획·구현·테스트처럼 **여러 단계가 상당한 컨텍스트를 공유**할 때 | 특정 도구 제약·권한을 강제하고 싶을 때 |
| 빠르고 국소적인 변경일 때 | 작업이 자족적이고 요약을 반환할 수 있을 때 |
| **지연이 중요할 때** — *"Subagents start fresh and may need time to gather context"* | |

**아젠다 §5-1의 "breadth는 fork, depth는 inline"과 축이 다르다.** 공식 기준은 breadth/depth가 아니라 **출력의 폐기 가능성·컨텍스트 공유 여부·지연**이다. 그리고 문서는 재사용 가능한 프롬프트가 필요할 뿐이면 **서브에이전트 대신 스킬**을 쓰라고 한다.

**게다가 아젠다의 표현이 두 가지를 뒤섞고 있다** — `fork`는 서브에이전트 생성과 다른 세 번째 것이다(§3.4).

### 3.3 중첩 깊이 — 아젠다의 "5단계"를 정정한다

아젠다 §5-2는 *"중첩 서브에이전트(2026 기준 5단계까지 가능)"* 라고 적었다. **공식 문서의 값이 다르다.**

> *"By default, a subagent can spawn subagents of its own, up to **three layers** below the main conversation. At the depth limit, Claude Code withholds the `Agent` tool from every subagent except a fork."*

그리고 조정 가능하다 — `CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH`. *"Set `1` to turn nesting off."* 문서가 이 환경변수를 **v2.1.217 이상**으로 표시하고, **설치본이 2.1.220이므로 적용 범위 안이다**(§5.3).

문서가 드는 유일한 적합 사례가 좁다.

> *"Nested subagents suit a delegated task that itself splits into parallel subtasks, such as **a reviewer subagent that dispatches a verifier per finding**, so the intermediate output never reaches your main conversation."*

**리뷰어가 지적마다 검증자를 붙이는 형태다.** [검증·교차리뷰 조사](verification-and-cross-review.md)가 다루는 구조와 정확히 같은 모양이라 기록해 둔다.

### 3.4 fork — 세 번째 선택지

> *"Because a fork's system prompt and tool definitions are identical to the parent, its first request **reuses the parent's prompt cache**. This makes forking cheaper than spawning a fresh subagent for tasks that need the same context."*

**§3.2가 "서브에이전트는 처음부터 시작해 컨텍스트 수집에 시간이 든다"고 한 비용을 fork가 피한다.** 제약도 명시된다 — *"A fork can't spawn further forks."* 그리고 깊이 한계에서 fork는 `Agent` 도구를 목록에 유지하되 호출하면 오류를 낸다.

---

## 4. 계획·실행 분리 — 명명은 있고 증거는 없다

아젠다 §5-4가 "계획·실행 분리와 인간 승인 게이트의 배치"를 물었다. 아젠다가 참고로 든 [Nghi D. Q. Bui, *Building Effective AI Coding Agents for the Terminal*](https://arxiv.org/abs/2603.05344) (arXiv 2603.05344, v1 2026-03-05 / **v3 2026-03-13**)을 확인했다.

OPENDEV라는 Rust 기반 CLI 에이전트를 서술하며, 구성 요소로 *"a **dual-agent architecture separating planning from execution**"*, workload-specialized model routing, lazy tool discovery, adaptive context compaction, 세션 간 메모리, event-driven system reminders를 든다.

**한계가 크다.**

- **초록에 수치가 하나도 없다.** 비교 실험이나 평가 결과가 초록 수준에서 제시되지 않는다.
- 저자 1인이고 *"Work in progress, new versions will be updated continuously"* 로 표시되어 있다.
- **본문을 읽지 않았다.**

**그래서 이 자료가 주는 것은 "계획·실행 분리"라는 설계가 실재한다는 사실까지다.** 효과의 근거는 아니다.

**그리고 §3.2의 공식 기준과 긴장이 있다** — 공식 문서는 *"계획·구현·테스트처럼 여러 단계가 상당한 컨텍스트를 공유할 때"* 본 대화를 쓰라고 한다. 계획과 실행을 다른 에이전트로 가르는 것은 그 기준의 반대편이다. **어느 쪽이 옳은지 판단할 자료가 없다. §6-3으로 넘긴다.**

---

## 5. 적용 대상 확인 — 지금 조율이 어떻게 되어 있는가 (보조)

### 5.1 서브에이전트 정의 11종, 전부 도구가 명시되어 있다

| 서브에이전트 | `tools` |
|---|---|
| `architect` | Read, Grep, Glob |
| `code-reviewer` | Read, Grep, Glob, Bash |
| `security-reviewer` | Read, Grep, Glob, Bash |
| `planner` | Read, Grep, Glob, TaskCreate, TaskUpdate, Write |
| `doc-updater` | Read, Write, Edit, Grep, Glob |
| `build-error-resolver` | Read, Write, Edit, Bash, Grep, Glob |
| `database-reviewer` | Read, Write, Edit, Bash, Grep, Glob |
| `harness-optimizer` | Read, Grep, Glob, Bash, Edit |
| `prompt-engineer` | Read, Write, Edit, Grep, Glob, TaskCreate, TaskUpdate |
| `refactor-cleaner` | Read, Write, Edit, Bash, Grep, Glob, TaskCreate, TaskUpdate |
| `tdd-specialist` | Read, Write, Edit, Bash, Grep, TaskCreate, TaskUpdate |

**11종 전부가 `tools`를 명시한다.** 생략 시 전체 상속인데 그렇게 둔 것이 하나도 없다. [보안 조사 §5.4](security.md)가 *"`Skill(*)` 전체 허용, `deny` 0건"* 으로 권한 경계의 부재를 지적했는데, **서브에이전트 층은 그 지적의 예외다** — 여기는 경계가 서 있다.

**그리고 `architect`·`code-reviewer`·`security-reviewer` 셋이 `Edit`·`Write` 없이 read-only다.** §2.2의 **FM-1.2 Disobey role specification**(1.5%)에 해당하는 구조적 방지책이고, 공식 문서의 모범 사례(*"Limit tool access"*)와도 일치한다.

### 5.2 중첩은 구조적으로 불가능하다

**11종 중 `tools`에 `Agent`를 포함한 것이 0건이다.**

공식 문서: *"To keep one subagent from spawning while nesting is on, … omit `Agent` from its `tools` list."* **즉 의도했든 아니든 §3.3의 3단 중첩이 이 하네스에서는 도달 불가능하다.** §3.3이 든 유일한 적합 사례(리뷰어가 지적마다 검증자를 붙이는 형태)가 현재 구조로는 성립하지 않는다.

**아젠다 §5-2("중첩이 실익이 있는 지점")는 따라서 가정법 질문이다** — 현재 실익을 잃고 있는 것이 아니라 애초에 경로가 없다.

### 5.3 버전 경계

설치본은 **Claude Code 2.1.220**이다. §3.3의 `CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH`가 문서상 **v2.1.217 이상**이므로 **이 환경에 적용된다.** 즉 중첩 깊이는 설정으로 조절 가능한 상태다.

### 5.4 실제 조율은 서브에이전트 밖에서 일어난다

[검증·교차리뷰 §4.1](verification-and-cross-review.md)이 확인한 대로, 하네스의 핵심 조율은 **외부 프로세스 호출**이며 경로가 둘이다 — spec/plan 리뷰는 `codex exec`, 코드 adversarial 리뷰는 `codex app-server`다(**2026-08-03 실험 B5에서 정정**, [§7.5](verification-and-cross-review.md)). 어느 쪽도 §3의 서브에이전트 기제가 아니다 — 컨텍스트 격리도, 요약 반환도, 도구 제약도 **Claude Code 플랫폼이** 보장하지 않는다.

> **다만 `app-server` 쪽은 자체 규격이 그 셋을 제공한다** — Thread/Turn/Item 격리, `item/completed` 요약, 그리고 **승인 요청·응답 프로토콜**. [검증·교차리뷰 §7.7](verification-and-cross-review.md)에 공식 문서 근거를 정리했다. §5.4의 *"플랫폼이 보장하지 않는다"* 는 **Claude Code 기준**의 진술이지 Codex 쪽 규격의 부재가 아니다.

**§1.2가 든 부적합 조건 중 하나가 여기 걸린다** — *"LLM agents are not yet great at coordinating and delegating to other agents in real time."* 그리고 [관찰성 §2.3](observability.md)이 그 경로의 메트릭이 방출되지 않음을 확인했다. **조율의 실체가 있는 곳에 관측이 없다.**

---

## 6. 자료가 답하지 않는 것

1. **§1.1의 90.2%가 어떤 평가에서의 개선인가.** 원문이 *"on our internal research eval"* 이라 밝히지만 **그 eval의 구성·과제 수·채점 방식을 공개하지 않는다.** [평가 조사 §1](evaluation.md)의 기준(표본 수·신뢰구간·짝지은 비교)으로는 검증 불가다.
2. **구조 효과와 예산 효과의 분리.** *"token usage by itself explains 80% of the variance"* 와 90.2% 우위를 함께 놓으면, 우위의 얼마가 구조에서 왔는지 알 수 없다. **자료가 이 분해를 하지 않는다.**
3. **계획·실행 분리가 옳은가**(§4). 공식 기준과 OPENDEV의 설계가 반대 방향이고, 후자에 증거가 없다.
4. **MAST의 대상이 코딩 하네스인가.** 7개 프레임워크에 코딩 과제가 포함되지만(CodeLlama가 모델 목록에 있다), 단일 사용자 하네스 형태와 같은지 확인하지 않았다.
5. **`+9.4%`와 `15.6%` 천장이 개인 규모에도 적용되는가**(§2.4). 개입 대상이 ChatDev 같은 프레임워크이고, 서브에이전트 11종 규모의 구성에서 같은 크기인지 자료가 말하지 않는다.
6. **중첩을 켰을 때의 비용.** §3.3이 깊이를 규정하지만 층마다 드는 토큰·지연을 문서가 수치로 주지 않는다. §1.1의 15배가 참고치이나 대상이 다르다.
7. **fork의 캐시 재사용이 실제로 얼마나 싼가**(§3.4). *"cheaper"* 라는 정성 진술까지다.
8. **`codex exec` 경유 조율의 실패 모드**(§5.4). §2.2의 14종은 한 프레임워크 안의 에이전트 간 상호작용을 대상으로 하고, 프로세스 경계를 넘는 호출에 그대로 적용되는지 불명이다.
9. **인간 승인 게이트의 배치**(아젠다 §5-4의 뒷부분). 어느 자료도 다루지 않았다. [강제 메커니즘 조사](enforcement-mechanisms.md)의 `ask` 권한이 수단이지만 배치 기준은 없다.

---

## 부록. 조사 방법 및 한계

**방법**

- WebFetch 6회 — `anthropic.com` 공학 문서 **2회**(전반·90.2% 문장 표적), `arxiv.org/html/2503.13657v3` 본문 **2회**(전반·다중 라벨 여부 표적), `code.claude.com`의 서브에이전트 공식 문서(92.7KB 전문, 절 단위로 재확인), `arxiv.org/abs/2603.05344`
- WebSearch 1회 — MAST 논문 위치와 게재처 확인용
- 실측(§5, 보조) — `.claude/agents/` 정의 11종의 `tools` 전수, `Agent` 도구 포함 여부, 설치 버전

**한계**

- **§1은 벤더가 자사 시스템을 설명한 글이다.** 재현 절차·평가 구성이 공개되지 않았고, 15배·90.2%·80%는 저자 주장치다. **다만 이 문서가 그중 가장 무겁게 쓰는 문장은 수치가 아니라 부적합 영역 진술이며, 그것은 자사에 불리한 방향의 진술이다.**
- **§2는 v3 HTML을 읽었다.** **출처 감사(2026-08-02)에서 abs 페이지의 판본 목록을 확인 — v1·v2·v3이며 v3이 최신이다.** 즉 이 문서는 최신 판본을 인용한다. NeurIPS 2025 Datasets & Benchmarks Track 채택은 proceedings URL로 확인했고, **저자 소속은 확인하지 않았다.**
- **MAST의 비율은 다중 라벨 출현율이며 합이 100%가 아니다.** 한 트레이스가 여러 모드를 동시에 가지므로 **모드별 비율을 더할 수 없다.** 초고에서 범주 합(23.5%·28.1%)을 계산했다가 논문 본문 확인 후 철회했다. 그리고 이 비율은 1,642 트레이스 안에서의 분포이지 "전체 실행 중 몇 %가 이 모드로 실패하는가"가 아니다.
- **§4는 초록만 확인했다.** WIP 표시가 있는 1인 저자 프리프린트이고 수치가 없다. **아젠다가 §5의 주 참고로 들었으나 이 조사에서 가장 약한 자료다.**
- **공식 문서의 동작을 실행으로 확인하지 않았다.** 3단 중첩도, `CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH`도, fork의 캐시 재사용도 문서 기재값이다. [관찰성 조사](observability.md)와 같은 한계다.
- **§5.2의 "중첩 불가능"은 정의 파일 기준이다.** `tools`에 `Agent`가 없으면 못 부른다는 것은 공식 문서 근거이나, 실제로 시도해 막히는지 실행 확인하지 않았다.
- **§0의 수렴이 세 자료의 독립성을 전제한다.** 벤더 실무·피어리뷰·저장소 실증이 서로 다른 방법이지만, **셋 다 "다중 에이전트가 덜 쓰인다/덜 듣는다"는 같은 시기의 관찰이다.** 시간이 지나면 함께 바뀔 수 있다.
- **§5는 결손이 아니라 구조를 확인했다.** 서브에이전트 층은 이 하네스에서 권한 경계가 서 있는 드문 층다. 관측된 문제는 중첩 경로가 없다는 것뿐이고, 그것이 문제인지는 §2·§3에 비추면 오히려 자료와 어긋나지 않는다.
