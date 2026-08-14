# 진단 ④의 개입 설계 — 구조 항해와 도입 강제, 그리고 도구 비교

*Generated: 2026-08-03 (§4.4·§5.5 갱신) | Sources: 8 심층 + 40여 검색 | Adapter: adapter-exa | Failed: 1회 → 재검색으로 해소(§4.4)*

**최초 작성**: 2026-08-03
**최종 수정**: 2026-08-03

**대상 프로젝트**: grid fin (신규 개인용 개발 하네스)
**조사 계기**: [스켈레톤 조사 §7.4](skeleton-first-then-tdd.md)가 **진단 ④(기존 체인 미획득)** 를 확정했고, 그 개입 설계와 `langchain-ai/openwiki` ↔ graphify 비교를 요청받았다
**성격**: 조사. **어느 도구를 채택할지 결정하지 않는다.**

선행 문서
- [skeleton-first-then-tdd.md](skeleton-first-then-tdd.md) §7.4 — 진단 ④의 정의와 실측
- [context-file-content.md](context-file-content.md) — ETH의 "저장소 개요는 도움이 안 된다"
- [enforcement-mechanisms.md](enforcement-mechanisms.md) — `PreToolUse`가 유일한 차단 지점
- [skill-architecture.md](skill-architecture.md) §2.3 — 도구 `description`의 트리거 조건 명시가 발동률을 올린다

---

## Executive Summary

**개입의 형태는 자료가 수렴한다 — ① 구조 인덱스를 만들고 ② 에이전트용 질의 도구로 노출하고 ③ 쓰게 만든다.** ③이 가장 어렵고 이 시리즈에서 가장 자료가 얇다(§4).

**피어리뷰 앵커가 있다.** [LocAgent (ACL 2025)](https://aclanthology.org/2025.acl-long.426/)가 이종 방향 그래프(`contain`·`import`·`invoke`·`inherit`)를 만들고 **에이전트용 도구 3종**(`SearchEntity`·`TraverseGraph`·`RetrieveEntity`)으로 노출해, SWE-bench-Lite 전 수준에서 최고 성능을 낸다(§2). **핵심은 그래프가 아니라 도구 설계다** — 저자들이 기존 도구를 *"initially designed for human [reading]"* 이라 지적하고 다시 만들었다.

**그리고 이 조사에서 가장 실무적인 발견은 도구가 아니라 도구를 안 쓴다는 것이다** — CodeCompass 실측 **효과 99.5% vs 도입률 42%**, 구조 과제군에서는 **30회 중 0회**(§4.1).

**그 강제 기제는 이미 규격으로 존재한다**(§4.4) — `PreToolUse`가 `deny` + `additionalContext`로 *"막고 무엇을 먼저 하라고 알리는"* 것을 지원한다. **남은 공백은 기제가 아니라 이 용도의 사례와 효과 측정이다.** 그리고 LangGraph 실무가 설계 원칙을 준다 — ***"부작용 바로 옆에 강제를 두어라, 라우팅으로 막으면 순서를 바꿔 뚫린다."***

**도구 비교의 결론은 "어느 것이 더 낫다"가 아니라 "서로 다른 진단을 겨눈다"이다**(§5).

| 도구 | 산출물 | 겨누는 진단 |
|---|---|---|
| **openwiki** | LLM 합성 **산문 위키** + Mermaid | 사람의 탐색·온보딩. **진단 ④가 아니다** |
| **graphify** | **전역 그래프** (god nodes·community) | 리팩터링 전 아키텍처 점검. **자기 문서가 "네비게이션 도구가 아니다"라고 명시한다** |
| **serena (LSP·MCP)** | **심볼 단위 질의** (`find_referencing_symbols`) | **진단 ④ — 형태가 정확히 일치한다** |
| **LocAgent 형** | 목적 그래프 + 다중 홉 도구 | 진단 ④ (다중 홉까지) |

> **가장 중요한 관측**: **§7.4.2가 이긴다고 말한 형태(과제별 1-hop 구조 이웃 질의)를 serena가 이미 제공한다.** 그리고 graphify의 자체 포지셔닝이 *"일상 네비게이션은 LSP가 처리한다"* 고 이미 그쪽에 넘기고 있다. **grid fin에 없는 것은 도구가 아니라 도입 장치일 가능성이 높다.**

---

## 0. 조사 요약

| # | 관측 | 근거 | 등급 |
|---|---|---|---|
| 1 | **LocAgent의 그래프 관계 4종: `contain`·`import`·`invoke`·`inherit`** | §2.1 | **피어리뷰(ACL 2025)** |
| 2 | **도구는 3종뿐이다** — `SearchEntity` / `TraverseGraph`(타입 인지 BFS, 방향·홉 수 제어) / `RetrieveEntity` | §2.2 | 피어리뷰 |
| 3 | **저자들이 기존 도구를 "사람용으로 설계됐다"고 명시적으로 기각한다** | §2.2 | 피어리뷰 |
| 4 | **결과: 파일 Acc@5 94.16 / 함수 Acc@10 77.37** — 전 수준 최고. Openhands+Claude-3.5(90.15 / 70.07)를 앞선다 | §2.3 | 피어리뷰 |
| 5 | **미세조정 7B/32B 오픈 모델이 GPT-4o 기반 베이스라인을 전부 앞선다.** 비용 **86% 절감** 주장 | §2.3 | 피어리뷰 |
| 6 | **도입률이 진짜 병목이다** — 효과 99.5% / 도입 42%, 구조 과제 **0/30** | §4.1 | 프리프린트 |
| 7 | **완화책이 위치 효과를 자원으로 쓴다** — 체크리스트를 프롬프트 **끝**에 둔다 | §4.1 | 프리프린트 |
| 8 | **독립 출처가 같은 레버를 가리킨다** — Opus 4.8 공식 문서의 *"call this when…"* 서술이 발동률을 올린다 | §4.2 | 1차(벤더) |
| 9 | **serena는 LSP-over-MCP로 40개 언어에서 `find_symbol`·`find_referencing_symbols`를 제공한다** | §5.3 | 1차(저장소) |
| 10 | **openwiki는 명시적으로 산문이다** — *"produces prose documentation with diagrams, not explicit dependency graphs"* | §5.1 | 1차(README) |
| 11 | **openwiki가 `AGENTS.md`·`CLAUDE.md`를 유지해 위키를 가리킨다** — ETH·SkillsBench 결과와 교차하는 지점 | §5.1 | 1차(README) |
| 12 | **graphify는 자기 문서에서 네비게이션 도구가 아님을 명시한다** | §5.2 | 1차(저장소) |
| 13 | **데이터 흐름 관계를 가진 것은 graphify뿐이다**(`shares_data_with` 38건). **다만 그래프가 `directed: false`라 ToCS의 방향 있는 `data_flows_to`와 다르다** | §5.5 | **1차 관측**(`graph.json` 직접 확인) |
| 14 | **graphify만 간선에 출처 등급을 붙인다** — `EXTRACTED` vs `INFERRED`. CodeCompass가 경고한 *"semantically unvalidated"* 를 스키마로 구분한다 | §5.5 | 1차 관측 |
| 15 | **graphify만 `rationale_for`·`cites`를 갖는다** — 설계 의도를 코드에 잇는 관계. 코드 그래프 도구 셋에는 없다 | §5.5 | 1차 관측 |

### 근거 등급

| 등급 | 무엇 |
|---|---|
| **피어리뷰(ACL 2025)** | LocAgent — **이 조사의 앵커** |
| 프리프린트 | CodeCompass(2602.20048), ToCS(2603.00601v2) — [§7.4](skeleton-first-then-tdd.md)의 소규모 단서 |
| 1차(벤더) | Anthropic Opus 4.8 프롬프팅 문서 |
| 1차(저장소·README) | serena, openwiki, graphify 가이드 |
| 1차(공식) | **Claude Code Hooks 규격** — `PreToolUse` 결정·주입 필드(§4.4-A) |
| 자가출판 | LangGraph 포럼 스레드·이슈, 훅 실무 구현 글 — **설계 원칙 추출용**(§4.4-C) |

---

## 1. 개입의 세 층

자료가 서로 다른 각도에서 같은 셋으로 수렴한다.

| 층 | 무엇 | 근거 |
|---|---|---|
| **① 구조 인덱스** | 코드 관계를 그래프로 만든다 | LocAgent(§2.1), CodeCompass |
| **② 에이전트용 질의 도구** | 사람용 IDE 도구가 아니라 **에이전트가 쓰기 좋은 소수 도구** | LocAgent(§2.2) |
| **③ 도입 강제** | 도구가 있어도 안 쓴다 | CodeCompass(§4.1), Opus 4.8 문서(§4.2) |

> **초판 직관은 ①에 있었다. 자료는 ②와 ③에 무게를 둔다.** LocAgent 논문의 절반이 도구 설계이고, CodeCompass 논문은 *"The bottleneck is not the graph"* 라고 못박는다.

---

## 2. 피어리뷰 앵커 — LocAgent

[Chen et al., *LocAgent: Graph-Guided LLM Agents for Code Localization*, ACL 2025](https://aclanthology.org/2025.acl-long.426/)

### 2.1 인덱스 — 관계 4종

디렉터리·파일·클래스·함수를 노드로 두고 이종 방향 그래프를 만든다. 관계는 **`contain` / `import` / `invoke` / `inherit`** 넷이다.

`contain`만으로도 전 노드가 하나의 트리로 이어져 *"standard codebase-navigation operations"* 를 지원하고, 나머지 셋이 그 위에 얹힌다. 설계 의도가 명시적이다:

> *"Rather than relying solely on directory structures or hierarchical module indexing, our approach captures **module dependencies that transcend directory boundaries**. Two modules in distant directories (A and B) may appear unrelated in traditional [navigation]"*

> **[§7.4.1](skeleton-first-then-tdd.md)의 ToCS 실측과 맞춰 읽어야 한다.** ToCS에서 에이전트가 못 찾은 것은 `calls_api`(0.15)와 `data_flows_to`(0.00)였다. **LocAgent의 `invoke`가 전자를 인덱싱한다. 후자는 인덱싱하지 않는다**(§5.5).

### 2.2 도구 — 셋뿐이고, 사람용이 아니다

**이 논문에서 grid fin에 가장 값진 부분이다.**

> *"Recent works … inspired by GUI-based IDEs, have developed **numerous specialized tools** for agents to explore codebases. However, **these tools are initially designed for human** [reading]"*

그 대안으로 도구를 셋으로 줄인다.

| 도구 | 입력 | 출력 |
|---|---|---|
| **`SearchEntity`** | 키워드 | 관련 엔티티 + 코드 조각 |
| **`TraverseGraph`** | 시작 엔티티 ID | **순회된 부분그래프**(엔티티 + 관계) |
| **`RetrieveEntity`** | 엔티티 ID | 해당 엔티티의 전체 코드 |

`TraverseGraph`의 규격이 §7.4.2의 "1-hop 구조 이웃"을 일반화한 것이다:

> *"performs a **type-aware breadth-first search (BFS)** on the code graph, starting from input entities and allowing **control over both traversal direction and number of hops**"*

그리고 에이전트 진행은 CoT로 **키워드 추출 → 탐색 → 순회 → 회수** 순서를 밟는다.

> **설계 교훈 둘.** ① **도구를 늘리지 않는다** — 셋이다. [스킬 조사 §2.1](skill-architecture.md)의 *"과제당 2–3개가 최적, 4개 이상 급락"* 과 방향이 같다. ② **출력이 "파일 목록"이 아니라 "부분그래프"다** — 에이전트가 관계를 그대로 받는다.

### 2.3 결과

SWE-bench-Lite, 파일/모듈/함수 세 수준.

| 방법 | 모델 | 파일 Acc@5 | 모듈 Acc@10 | 함수 Acc@10 |
|---|---|---:|---:|---:|
| BM25 | — | 61.68 | 52.92 | 36.86 |
| CodeRankEmbed | — | 84.67 | 78.83 | 58.76 |
| Openhands | Claude-3.5 | 90.15 | 83.58 | 70.07 |
| SWE-agent | Claude-3.5 | 90.15 | 78.10 | 64.60 |
| **LocAgent** | Qwen2.5-32B(ft) | 92.70 | 87.23 | 77.01 |
| **LocAgent** | Claude-3.5 | **94.16** | **87.59** | **77.37** |

**두 가지가 눈에 띈다.**

1. **BM25가 함수 수준에서 36.86으로 무너진다.** [§7.4.2](skeleton-first-then-tdd.md)의 G1(의미 과제)에서 BM25가 최적이었던 것과 대비된다 — **과제 종류가 갈린다는 그 관측을 다른 데이터가 지지한다.**
2. **미세조정 32B 오픈 모델(92.70/87.23/77.01)이 GPT-4o 기반 에이전트 전부를 앞지르고 Claude-3.5 LocAgent에 근접한다.** 저자 주장으로 **비용 86% 절감**.

> **등급 주의**: SWE-bench-Lite 기반이고, 저자들이 그 오염 위험을 인정해 `Loc-Bench`를 따로 만들었다. **위 표는 SWE-bench-Lite 수치다.** 그리고 모델이 GPT-4o·Claude-3.5 세대다 — **[이 시리즈가 네 번째로 만나는 세대 지체](non-coding-work.md)**.

---

## 3. 인덱스 신선도 — 정적 그래프의 구조적 약점

LocAgent·CodeCompass·graphify 모두 **오프라인 빌드**다. 코드가 바뀌면 그래프가 낡는다.

CodeCompass 저자들이 별도 한계를 적는다:

> *"The automated AST pipeline produces a **structurally complete but semantically unvalidated** graph. In production deployments, graph construction is not a purely automated activity: **an SME familiar with the codebase's architectural intent must review** [it]"*

> **이 축에서 LSP 기반 도구가 구조적으로 유리하다.** 참고 하네스의 graphify 포지셔닝이 이미 같은 논거를 쓴다 — *"LSP 기반 도구가 라이브로 처리한다 — **항상 최신·타입 인지·정확**하며, precomputed 그래프보다 신선도·정확도에서 우위"*. **이 조사는 그 판단을 뒤집는 근거를 찾지 못했다.**

---

## 4. 도입 강제 — 진짜 병목

### 4.1 실측 — 도구를 안 쓴다

[CodeCompass](https://arxiv.org/html/2602.20048), 270회 시행:

> *"**tool effectiveness (99.5% when used) vs tool discoverability (42% overall adoption rate)**. The bottleneck is not the graph; it is ensuring consistent agent adoption."*
> *"**zero trials out of 30** used the graph tool on structural tasks, **despite structural dependencies being the tool's primary** [purpose]"*

**구조 과제에서 0/30이다.** 도구가 정확히 그 용도인데도 쓰지 않았다.

**완화책:**

> *"we developed an improved prompt with a **mandatory checklist positioned at the END of the prompt (to avoid Lost in the Middle suppression effects)**"*

> **[지시 계층 §3.1](instruction-layers.md)의 U자 위치 효과를 완화 대상이 아니라 배치 자원으로 쓴다.** 이 시리즈가 위치 효과를 계속 "피해야 할 열화"로 다뤄왔는데, **끝이 살아남는다는 성질은 설계에 쓸 수 있다.**

### 4.2 독립 출처가 같은 레버를 가리킨다

[스킬 조사 §2.3](skill-architecture.md)이 기록한 Opus 4.8 공식 문서:

> *"**prescriptive descriptions that state *when* to call a tool** (e.g. "Call this when the user asks about current prices or recent events") **give meaningful lift** on 4.8 over descriptions that only state what the tool does"*

**그리고 같은 문서가 4.8의 도구 과소사용을 명시한다** — *"under-reaches for [subagents, file-based memory, custom tools] by default"*.

> **서로 무관한 두 출처(학술 프리프린트 / 벤더 문서)가 같은 결론에 온다 — 도구를 붙이는 것과 쓰이게 하는 것은 별개 작업이다.**

### 4.3 하네스 층의 선택지 — 프롬프트인가 메커니즘인가

§4.1·§4.2의 완화책은 **전부 프롬프트 층**이다. 그리고 [강제 메커니즘 조사](enforcement-mechanisms.md)가 확인한 대로 **결정적 강제는 `PreToolUse`에만 있다.**

| 층 | 형태 | 근거 |
|---|---|---|
| 프롬프트 | 체크리스트를 **끝**에 배치 | §4.1 (프리프린트) |
| 프롬프트 | 도구 `description`에 **"언제 부르는지"** 명시 | §4.2 (1차 벤더) |
| 스킬 | `disable-model-invocation`·`allowed-tools`로 진입점 고정 | [스킬 §1.2](skill-architecture.md) |
| **메커니즘** | **편집 전에 구조 조회를 했는지 검사하고 미조회면 차단** | **§4.4 — 재검색으로 해소** |

### 4.4 재검색 — 공백이 아니라 검색 어휘 문제였다 (2026-08-03)

> **초판이 *"자료 없음"* 이라 적었다. 사용자 요청으로 재검색했고 틀렸다.** 초판 질의(`forcing agent tool adoption` 계열)가 **`adoption`이라는 경영 어휘 때문에** 기업 AI 도입률·ROI 문서로 수렴했다. **기술 어휘(`PreToolUse hook block`, `tool_choice required`, `enforce tool call order`)로 바꾸자 세 계열이 나온다.**
>
> **이 시리즈의 [출력 절단](instruction-layers.md)·[상호참조 기억 인용](non-coding-work.md)에 이은 세 번째 "확인 없이 결론" 계열 오류이며, 형태가 새롭다 — 검색 실패를 자료 부재로 읽었다.**

#### A. 훅 게이트 — 규격이 이미 완비되어 있다 (1차, 공식)

[Claude Code Hooks 공식 문서](https://code.claude.com/docs/en/hooks.md)의 `PreToolUse` 출력 필드가 필요한 것을 전부 준다.

| 필드 | 규격 |
|---|---|
| `permissionDecision` | `"allow"` / **`"deny"`**(도구 호출 차단) / `"ask"` / `"defer"` |
| `permissionDecisionReason` | 차단 사유 |
| **`updatedInput`** | *"Modifies the tool's input parameters **before execution**"* — 입력 객체를 통째로 교체 |
| **`additionalContext`** | *"String added to Claude's context **alongside the tool result**"* |

**즉 "편집 전 구조 조회 강제"는 규격상 완전히 표현 가능하다** — `Edit`/`Write` 매처에 `PreToolUse`를 걸고, 이번 턴에 구조 조회 기록이 없으면 `deny` + 사유, 그리고 `additionalContext`로 무엇을 먼저 하라고 알린다.

> **버전 주의**: `additionalContext`는 **Claude Code v2.1.9(2026-01-16) 이상**이다([실무 구현 사례](https://dev.to/mikelane/building-guardrails-for-ai-coding-assistants-a-pretooluse-hook-system-for-claude-code-ilj)). 그 이전 버전은 *"supported blocking hooks but not context injection"* — **차단만 되고 안내가 안 된다.**

그리고 비동기 경로도 있다 — `asyncRewake`: *"runs in the background and **wakes Claude on exit code 2**. The hook's stderr … is shown to Claude as a system reminder"*. **인덱스 조회처럼 느린 검사를 턴을 막지 않고 거는 형태다.**

#### B. API 층 강제 — `tool_choice`, 그리고 그 실패 모드

`tool_choice: "required"` 또는 특정 도구 지정으로 **모델에게서 선택권을 뺏는다.**

**그러나 문서화된 실패 모드가 있다** ([openai-agents-python #263](https://github.com/openai/openai-agents-python/pull/263)):

> *"setting `tool_choice` to "required" or a specific function name could cause models to get stuck in an **infinite tool call loop**. When `tool_choice` is set to force tool usage, **this setting persists across model invocations**."*

수정은 **도구 실행 후 `auto`로 되돌리는 것**(`reset_tool_choice`)이다.

> **진단 ④에 이 레버는 잘 안 맞는다.** 필요한 것은 *"매 턴 구조 도구를 불러라"* 가 아니라 *"편집하기 전에 한 번은 불렀어야 한다"* 인데, `tool_choice`는 **턴 단위 강제**라 그 조건을 표현하지 못한다. **A가 조건부라서 더 맞는다.**

#### C. 그래프/상태 기계 — 부작용 옆에 강제를 둔다

[LangGraph 포럼의 "Best Practices for Enforcing Tool Call Order"](https://forum.langchain.com/t/best-practices-for-enforcing-tool-call-order-in-langgraph/3862) 스레드가 이 조사가 찾던 **설계 원칙**을 준다. 질문자의 요구가 형태상 동일하다 — *"enrollment can only happen **after** the user has been shown the available plans"*.

답변의 핵심:

> *"The enforcement lives **inside the `enroll_in_plan` tool, right next to the side effect, so it cannot be bypassed regardless of what order the model calls tools in.** Prerequisites are tracked as plain state props that the upstream tools fill in"*
> *"structure (edges/subgraphs) for the happy path, **in-tool validation … for the actual guarantee**, `interrupt()` for irreversible steps"*
> *"**Fail helpfully: return a guiding ToolMessage instead of raising**"*

> **설계 원칙 셋이 추출된다.**
> 1. **경로(라우팅)가 아니라 부작용 옆에 강제를 둔다** — 라우팅으로 막으면 모델이 다른 순서로 부르면 뚫린다.
> 2. **전제조건을 상태로 기록하고 그 기록에서 읽는다** — 상류 도구가 채우고 하류 도구가 검사한다.
> 3. **막을 때 안내한다** — 예외를 던지지 말고 **다음에 무엇을 하라는 메시지**를 돌려준다. §A의 `additionalContext`가 하네스 층의 같은 것이다.

그리고 [관련 이슈](https://github.com/langchain-ai/langgraph/issues/7855)가 이 방식의 함정을 적는다:

> *"A deterministic subflow should not mean **"trust the initial context forever"**. It should mean "the execution path is fixed, but **the entry conditions and intermediate assumptions are explicit**"."*

> **진단 ④에 직접 걸린다** — 구조 조회를 한 번 했다고 그 결과가 세션 내내 유효하다고 볼 수 없다. **코드가 바뀌면 무효화되어야 한다**(§3의 신선도 문제와 같은 축).

#### D. 그래서 실제 공백은 어디인가

| 층 | 상태 |
|---|---|
| 기제 규격 | **완비** — `PreToolUse` 4필드 + `asyncRewake`(1차 공식) |
| 설계 원칙 | **있다** — 부작용 옆 강제 / 전제조건 상태화 / 안내형 실패 (C) |
| 실무 구현 사례 | **있다** — 파괴적 명령 차단·컨텍스트 주입형 훅 시스템 (자가출판) |
| **이 목적의 사례** | **여전히 없다** — *"편집 전 구조 조회 강제"* 를 구현·측정한 발표물 |
| **효과 측정** | **없다** — 위 어느 것도 진단 ④에 대해 재지 않았다 |

> **공백의 정확한 형태가 바뀌었다.** *"기제가 없다"* 가 아니라 **"기제는 완비이고 설계 원칙도 있으나, 이 용도로 쓴 사례와 그 효과 측정이 없다"** 이다. **grid fin이 만든다면 선행 사례를 따르는 것이 아니라 §4.1의 42%를 자기 환경에서 재는 쪽에 가깝다.**

---

## 5. 도구 비교 — 무엇이 어느 진단을 겨누는가

> **판정이 아니라 배치다.** 각 도구가 자기 목적에서 실패한다는 뜻이 아니며, **진단 ④를 기준으로 줄을 세우면 그 목적이 아닌 도구가 불리하게 보인다는 점을 먼저 적어 둔다.**

### 5.1 openwiki (langchain-ai)

**자기 규정**: *"a CLI that writes and maintains agent documentation for your codebase"*, *"The self-maintaining wiki. **Built for agents, explored by humans.**"*

| 축 | 내용 |
|---|---|
| 산출물 | **plain Markdown 위키** (OKF v0.1), YAML frontmatter, 문서 간 표준 링크, **Mermaid 다이어그램** |
| 생성 방식 | **Deep Agents 문서화 에이전트가 합성** |
| 갱신 | GitHub Actions·GitLab CI·Bitbucket 파이프라인으로 증분. *"No-op runs are free"* |
| 에이전트 연결 | ***"maintains an `AGENTS.md` and `CLAUDE.md` at the repo root that point your coding agent at the wiki"*** |
| 명시적 성격 | ***"prose documentation with diagrams, not explicit dependency graphs"*** |

**진단 ④ 관점**: **겨누지 않는다.** 질의 가능한 구조 인덱스가 아니라 **읽는 산문**이고, 자기 규정이 *"explored by humans"* 다.

> ⚠️ **그리고 이 시리즈의 두 결과와 교차하는 지점이 있다.**
>
> | 결과 | 내용 |
> |---|---|
> | [ETH (2602.11988)](context-file-content.md) | 저장소 개요는 *"not helpful"*, 비용 **+20%**. **LLM 생성** 컨텍스트 파일은 **−0.5 ~ −2%** |
> | [SkillsBench](skill-architecture.md) | **자가 생성** 스킬은 *"negligible or negative"* |
>
> **openwiki는 "LLM이 생성한 저장소 문서를 `AGENTS.md`/`CLAUDE.md`로 연결"하는 구성이라 두 결과의 교집합에 놓인다.**
>
> **다만 경계를 정확히 그어야 한다.** ETH가 잰 것은 **컨텍스트에 들어앉은 정적 산문 개요**다. openwiki의 본문은 디스크에 있고 `AGENTS.md`는 **가리키기만** 한다 — 구조상 [신규 `/init`이 권장한 `@import` 방식](context-file-content.md)에 가깝다. **가리키는 파일이 매 세션 끌려오는가, 과제별로 읽히는가에 따라 전이 여부가 갈리며, 이 조사는 그것을 확인하지 않았다**(§6-2).

### 5.2 graphify

**자기 규정**(참고 하네스 `harness-guide.md`): *"코드베이스·문서·연구 자료를 지식 그래프로 변환해 **god nodes·surprising connections·community 구조**를 시각화하는 Stage 1 평가 도구"*.

| 축 | 내용 |
|---|---|
| 산출물 | `GRAPH_REPORT.md`(사람용 요약), `graph.json`/`graph.html`, `manifest.json`, `cost.json` |
| 생성 방식 | **AST 채널 + LLM 추출**. 마크다운 중심 디렉터리는 LLM 추출 의존이 커져 **비용이 급증**한다고 가이드가 경고 |
| 갱신 | **on-demand 1회성 빌드.** 상시 자동 갱신은 하네스 기본값이 아님 |
| 명시적 성격 | **"graphify는 코드 네비게이션 도구가 아니다"** |

**진단 ④ 관점**: **자기 문서가 이미 아니라고 말한다.** 그리고 그 문서가 네비게이션을 **LSP에 넘긴다**.

> **따라서 "graphify가 진단 ④에 안 맞는다"는 비판이 아니라 자기 규정의 확인이다.** graphify가 겨누는 것은 **리팩터링 전 아키텍처 점검**이고, 그 목적에서 이 조사는 반증을 찾지 못했다.
>
> **다만 §7.4.2의 결과가 한 칸을 더한다** — 승부처는 "전역 조감"도 "일상 심볼 이동"도 아닌 **과제에 걸린 1-hop 구조 이웃**이며, 그 칸은 두 도구 사이에 있다.

### 5.3 serena (LSP-over-MCP)

**자기 규정**: *"The IDE for Your Coding Agent"*, *"semantic code retrieval, editing, refactoring and debugging tools that are akin to an IDE's"*.

| 축 | 내용 |
|---|---|
| 기반 | **언어 서버 프로토콜(LSP)**, **40개 이상 언어** |
| 조회 도구 | `find symbol` · `symbol overview (file outline)` · **`find referencing symbols`** |
| 편집 도구 | `replace symbol body` · `insert after symbol` · `rename` |
| 성격 | **라이브** — 인덱스 빌드가 아니라 언어 서버 질의 |

> **`find_referencing_symbols`가 §7.4.2의 "1-hop 구조 이웃 질의" 그 자체다.** 그리고 **라이브라서 §3의 신선도 문제가 없다.**
>
> **한계 둘.** ① 표에 *"Only available for some languages, limited by the language server functionality"* 주석이 붙는다 — [다중 런타임 모노레포](non-coding-work.md) 전제에서 언어별 편차가 실제 제약이 된다. ② **LSP는 참조·정의를 주지 데이터 흐름을 주지 않는다**(§5.5).

### 5.4 대조표

| | openwiki | graphify | serena / LSP | LocAgent 형 |
|---|---|---|---|---|
| 산출물 | 산문 + Mermaid | 전역 그래프 | **라이브 심볼 질의** | 목적 그래프 + 도구 3종 |
| 생성 비용 | LLM 합성 (증분) | AST+LLM (1회성) | **빌드 없음** | 오프라인 인덱스 |
| 신선도 | CI 갱신 시점 | 빌드 시점 | **항상 최신** | 인덱스 시점 |
| 질의 단위 | 문서 | 전역 구조 | **심볼** | **엔티티 + N-hop** |
| 다중 홉 | ✗ | (전역이라 해당 없음) | 반복 호출로 근사 | **✅ 방향·홉 수 제어** |
| 주 소비자 | **사람** | 사람 + 에이전트 | **에이전트** | **에이전트** |
| **겨누는 진단** | 온보딩·탐색 | 아키텍처 점검 | **④** | **④** |
| 근거 등급 | README | 하네스 가이드 | 저장소 문서 | **피어리뷰 ACL** |

### 5.5 넷 다 못 하는 것 — `data_flows_to`

> **초판은 이 절을 "넷 다 못 한다"로 썼다. 참고 하네스의 `graphify-out/graph.json`을 직접 열어 정정한다** — **graphify에는 데이터 흐름 관계가 있다. 넷 중 유일하다.**

| 도구 | 인덱싱하는 관계 |
|---|---|
| LocAgent | `contain`, `import`, `invoke`, `inherit` |
| CodeCompass | `IMPORTS`, `INHERITS`, `INSTANTIATES` |
| serena / LSP | 정의·참조·심볼 계층 |
| **graphify** | `references` 368, `implements` 125, `contains` 124, `calls` 101, **`shares_data_with` 38**, `semantically_similar_to` 35, `conceptually_related_to` 30, `rationale_for` 16, `cites` 13 |

**1차 관측** (`/Users/mario/Workspace/harness/graphify-out/graph.json`, 2026-05-19 빌드): 노드 637 · 링크 850 · 하이퍼엣지 3.

**graphify가 다른 셋과 다른 점 셋.**

1. **`shares_data_with`가 있다** — [ToCS의 `data_flows_to`](skeleton-first-then-tdd.md)에 대응하는 유일한 관계다.
2. **`rationale_for`·`cites`가 있다** — **설계 의도를 코드에 잇는 관계**로, 코드 그래프 도구 셋 중 어느 것도 갖지 않는다. [ToCS가 "design intent"를 신념 대상에 넣은 것](skeleton-first-then-tdd.md)과 같은 축이다.
3. **간선마다 출처 등급이 붙는다** — `confidence: EXTRACTED | INFERRED`. `calls`·`contains`는 100% EXTRACTED이고, `conceptually_related_to`는 30건 중 **24건이 INFERRED**다. **[CodeCompass가 경고한 *"structurally complete but semantically unvalidated"*](https://arxiv.org/html/2602.20048) 를 스키마 층에서 구분한다** — 다른 셋에는 이 축이 없다.

**그러나 `shares_data_with`를 `data_flows_to`로 읽으면 안 된다. 셋이 다르다.**

| | ToCS `data_flows_to` | graphify `shares_data_with` |
|---|---|---|
| 방향성 | **방향 있음** (A의 출력 → B의 입력) | **`"directed": false`** — 그래프 전체가 무방향이다 |
| 출처 | 오케스트레이션 **코드** | 이 빌드에서는 **`docs/specs/*.md` 산문** (표본 2건 모두) |
| 규모 | — | **38건** (전체 850의 4.5%) |

> **따라서 정정의 정확한 형태는 이렇다** — **"어느 도구도 못 한다"는 틀렸고, "graphify만 관계를 갖되 그것이 방향 있는 데이터 흐름은 아니다"가 맞다.** 무방향이면 *"A의 출력이 B의 입력"* 과 *"둘이 같은 데이터를 만진다"* 를 구분하지 못하는데, **진단 ④가 필요로 하는 것은 전자다.**
>
> **그리고 이 빌드는 산문 중심 저장소에서 나왔다.** graphify 가이드 자신이 마크다운 중심 디렉터리를 targets에서 빼라고 권하므로, **실코드 저장소에서 `shares_data_with`가 어떤 비중·출처로 나오는지는 이 관측이 답하지 않는다**(§6-3').

---

## 6. 이 조사가 답하지 않은 것

1. ~~**"편집 전 구조 조회 강제"의 사례를 찾지 못했다**~~ **재검색으로 형태가 바뀌었다 — §4.4.** 기제 규격은 **완비**(`PreToolUse`의 `deny`/`updatedInput`/`additionalContext`, `asyncRewake`)이고 설계 원칙도 있다(부작용 옆 강제 / 전제조건 상태화 / 안내형 실패). **남은 공백은 좁다 — 이 용도로 구현한 발표 사례와 그 효과 측정이 없다.**
2. **openwiki 산출물이 매 세션 컨텍스트로 끌려오는가**(§5.1). `AGENTS.md`가 가리키기만 하는지, 본문이 인라인되는지에 따라 ETH 결과의 전이가 갈린다. **README만 읽었고 실제 생성물을 만들어 보지 않았다.**
3. ~~**graphify의 관계 스키마를 확인하지 않았다**~~ **해소 — §5.5에서 `graph.json` 직접 확인. `shares_data_with`가 존재하나 무방향이다.**
3'. **실코드 저장소에서 graphify의 데이터 흐름 간선이 어떻게 나오는가**(§5.5). 확인한 빌드는 **산문 중심 저장소**이고 표본 2건이 모두 `docs/specs/*.md` 출처였다. **가이드 자신이 마크다운 디렉터리를 targets에서 빼라고 권하므로, 권장 구성(실코드 대상)에서의 산출을 보지 못했다.**
3''. **`"directed": false`가 graphify의 설계 선택인지 이 빌드의 산물인지 모른다.** 방향성이 있으면 `shares_data_with`가 진단 ④에 훨씬 유용해진다.
4. **serena의 언어별 커버리지 편차**(§5.3). *"limited by the language server functionality"* 가 Node·Python·Rust 각각에 무엇을 의미하는지 확인하지 않았다.
5. **LocAgent가 `Loc-Bench`에서 낸 수치를 읽지 않았다.** §2.3은 SWE-bench-Lite 표이고, 저자들이 오염 위험 때문에 별도 벤치마크를 만들었다.
6. **§7.4.2의 G1/G2/G3 과제 분류를 실제 개발 작업에 어떻게 매핑하는가.** "의미 과제 vs 구조 과제"를 사전에 가를 수 있어야 도구 선택이 성립하는데, **가르는 방법이 자료에 없다.** 그리고 §4.1의 0/30이 바로 이 실패다 — **에이전트가 구조 과제임을 인지하지 못했다.**
7. **개인 규모 전이.** LocAgent는 SWE-bench 저장소, CodeCompass는 71노드/255간선이다. **grid fin이 감독할 프로젝트 규모에서 인덱스 구축 비용이 정당화되는지 모른다.**

---

## Sources

**피어리뷰**
1. [Chen et al., *LocAgent: Graph-Guided LLM Agents for Code Localization*, ACL 2025](https://aclanthology.org/2025.acl-long.426/) · [arXiv](https://arxiv.org/html/2503.09089v2) · [코드](https://github.com/gersteinlab/LocAgent) — 관계 4종, 도구 3종, Acc 표, 미세조정 86% 절감

**프리프린트** ([스켈레톤 조사 §7.4](skeleton-first-then-tdd.md)에서 이미 등급 부여)
2. [The Navigation Paradox / CodeCompass (2602.20048)](https://arxiv.org/html/2602.20048) — 도입률 42%, 구조 과제 0/30, 체크리스트-끝 배치
3. [Theory of Code Space (2603.00601v2)](https://arxiv.org/abs/2603.00601v2) — 간선 종류별 재현율, `data_flows_to` 0.00

**도구 1차**
4. [langchain-ai/openwiki](https://github.com/langchain-ai/openwiki) — README 확인
5. [oraios/serena](https://github.com/oraios/serena) · [문서](https://oraios.github.io/serena/01-about/000_intro.html) — 도구 표, LSP 40개 언어
6. graphify — 참고 하네스 `harness-guide.md` §graphify 사용 가이드 (로컬 1차 관측)

**미확인 (후속 대상)**
7. [ARISE (2605.03117)](https://arxiv.org/html/2605.03117) · [SHERLOC (2606.24820v1)](https://arxiv.org/html/2606.24820v1) — 저장소 그래프 기반 결함 위치 특정. **검색 결과에만 있고 읽지 않았다.** SHERLOC의 *"utilize half their budget on locating faults before editing"* 은 스니펫 인용이다
8. [Serena vs Graphify 비교 글](https://spark-note.com/en/blog/serena-vs-graphify-search-comparison/) — **자가출판. 이 문서의 §5 대조는 각 도구의 1차 문서에서 직접 작성했고 이 글을 근거로 쓰지 않았다**

---

## Methodology

**검색**: exa `/search` 3회(LocAgent / serena·LSP / 도구 도입 강제). **세 번째가 실패했다** — "forcing agent tool adoption" 계열 질의가 기업 AI 도입률·ROI 문서로 수렴해 관련 결과가 0건이었다. §4의 도입 강제 근거는 **이미 코퍼스에 있던 둘**(CodeCompass, Opus 4.8 문서)에서 왔다.
**정독**: exa `/contents` 1회 배치로 3개 문서(약 88 KB).
**병행 1차 관측**: 참고 하네스 `harness-guide.md`의 graphify 절 직접 읽기, openwiki README WebFetch.

> 어댑터 스킬의 서브에이전트 지침 대신 **메인 세션 순차 실행**했고(세션의 AgentTool 제약), 저장 경로도 기존 조사 코퍼스 규약을 따랐다 — 앞선 세 조사와 동일.

**한계**

- **§5의 대조표는 이 문서가 만든 것이다.** 각 칸의 근거는 각 도구의 1차 문서이나, **네 도구를 같은 축에 놓고 비교한 출처는 없다.**
- **openwiki와 serena를 실제로 돌려보지 않았다.** README·문서 기반 대조다.
- **graphify는 참고 하네스의 가이드 문서로만 봤다.** 상류 프로젝트 문서를 확인하지 않았고, 산출물(`graph.json`)도 열지 않았다(§6-3).
- **LocAgent의 모델 세대가 GPT-4o·Claude-3.5다** — [이 시리즈가 네 번째로 만나는 세대 지체](non-coding-work.md). 상대 순위는 전이 가능성이 높고 절대 수치는 아니다.
- **도입 강제 층에 자료가 없다**(§6-1). §4.3 표의 마지막 행은 **빈칸으로 남겨 두었고, 채우지 않았다.**
