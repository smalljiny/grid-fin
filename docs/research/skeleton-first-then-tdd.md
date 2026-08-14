# "워크플로우 먼저 → 체인 목업으로 실증 → 함수 단위 TDD" — 근거 조사

**최초 작성**: 2026-08-03
**최종 수정**: 2026-08-03
**대상 프로젝트**: grid fin (신규 개인용 개발 하네스)
**조사 계기**: *"기능의 워크플로우를 먼저 설계하고, 워크플로우를 구성하는 함수 체인 또는 이벤트 체인의 목업을 구현하여 워크플로우를 실증한 뒤, 각 함수 단위로 TDD 방식으로 구현하는 것이 좋은 방법인가"*
**조사 도구**: 검색 어댑터 — `adapter-exa` `/search` 7회 · `/contents` 2회(6개 문서 전문), `adapter-firecrawl` `/v1/search` 7회. 어댑터 실패 0건
**성격**: 자료 수집. grid fin 설계 결정은 하지 않는다.

---

## 0. 조사 요약 — 세 단계에 세 개의 다른 판정이 나온다

제안된 방법은 **하나의 방법이 아니라 세 단계**이고, 자료가 각각에 다르게 답한다.

| 단계 | 판정 | 근거 |
|---|---|---|
| **① 워크플로우·체인을 먼저 설계한다** | **지지.** 두 계보가 독립적으로 도달 | Walking Skeleton / Steel Thread (§1), CodeSpec (§5) |
| **② 목업(mock)으로 실증한다** | **자료가 반대한다.** 이 조사의 핵심 발견 | §2 |
| **③ 각 함수를 TDD로 구현한다** | **지지. 다만 제시된 이유 때문은 아니다** | Fucci et al. TSE 2017 (§3) |

### 0.1 관측표

| # | 관측 | 근거 등급 |
|---|---|---|
| 1 | **①은 1990년대부터 이름이 붙어 있는 확립된 패턴이다** — Walking Skeleton(Cockburn), Tracer Bullet(Pragmatic Programmer), Steel Thread. *"A Walking Skeleton is a tiny implementation of the system that performs a small end-to-end function"* | **1차 (원저자 정의)** — §1 |
| 2 | **그런데 그 패턴의 정의가 "목업 금지"를 명시한다.** *"a real end-to-end test with **no stubs** against a system that's deployed in production"*, *"it's not a prototype and not a proof of concept — **it's production code**"* | **2차(실무 해설), 다수 독립 수렴** — §2.1 |
| 3 | **GOOS의 순서가 제안과 정반대다** — 스켈레톤을 **배포한 뒤에야** 첫 인수 테스트를 쓰고 TDD 사이클을 시작한다. 인프라가 먼저, 기능이 나중 ("first-feature paradox") | **1차 (서적 목차·인용)** — §2.2 |
| 4 | **에이전트 맥락에서 같은 결론이 20년 뒤 재확인된다** — CodeSpec: *"textual designs are difficult to verify and enforce"*. 실행 가능 명세 vs 텍스트 설계의 격차가 **71.8% vs 43.8%**(지시문 3,000~5,000단어), 200턴 초과에서 **+14.0·+15.1%p** | **프리프린트 (미검증, 저자 자체 평가)** — §5 |
| 5 | **③의 근거가 통념과 다르다.** Fucci et al.(TSE 2017, 전문직 39명·82 데이터포인트): *"**Sequencing, the order in which test and production code are written, had no important influence**"*. 효과는 **granularity(사이클 길이)와 uniformity(일정함)**가 냈다 | **피어리뷰 (IEEE TSE)** — §3.1 |
| 6 | 같은 논문 결론: *"The claimed benefits of TDD **may not be due to its distinctive test-first dynamic**"* | **피어리뷰** — §3.1 |
| 7 | **메타분석도 test-first 자체에 강한 효과를 주지 않는다.** Rafique & Mišić(TSE 2013, 27연구): 표준화 분석의 품질 요약 효과크기 **0.106(고정) / −0.0101(랜덤)** — *"very small to negligible"*, 0.05에서 유의하지 않음 | **피어리뷰** — §3.2 |
| 8 | **외부 재현도 무효과다.** Fucci et al. ESEM 2016 다지점 맹검: *"TDD does not affect testing effort, software external quality, and developers' productivity"* (반복적 test-last 대비) | **피어리뷰** — §3.3 |
| 9 | **목업 체인을 정당화하는 성숙한 규율이 하나 있다 — 소비자 주도 계약 테스트(Pact).** 목이 **계약 산출물**이 되어 제공자 측에서 검증되므로 드리프트가 막힌다 | **1차 (공식 문서)** — §4 |
| 10 | **그러나 "이벤트 체인"은 반쯤 비어 있다.** Pact CDCT는 이벤트 기반을 지원하나, **양방향 계약 테스트(BDCT)는 `Synchronous/HTTP`만 검증하고 `Asynchronous/Messages`는 무시한다**고 공식 문서가 명시 | **1차 (공식)** — §4.2 |
| 11 | **목 과다 사용에 대한 비판이 원저자 쪽에서도 나온다.** *"Mock Roles, not Objects"*(OOPSLA 2004)의 핵심 주장은 **인터페이스 발견**이지 테스트 격리가 아니며, *"only mock types you own"* — 외부 타입은 얇은 래퍼로 감싸라 | **피어리뷰 (OOPSLA)** — §6.1 |
| 12 | **Fucci의 granularity 발견이 선행 조사의 "립도" 축에 세 번째 독립 수렴이다** — [workflow-and-feature-list.md](workflow-and-feature-list.md)가 이미 피어리뷰 2편의 수렴을 기록했다 | 이 문서의 대조 — §7.2 |

> **한 문장 요약**: 제안된 방법은 **구조적으로 Walking Skeleton이고, 한 군데만 다르다** — 그 한 군데가 문헌이 명시적으로 경고하는 지점이다. 그리고 ③은 옳지만 "test-first라서"가 아니라 "사이클이 잘고 일정해서"다.

---

## 1. ① 워크플로우·체인 먼저 — 확립된 패턴이다

### 1.1 세 이름, 같은 것

| 이름 | 출처 | 정의 |
|---|---|---|
| **Walking Skeleton** | Cockburn (1994·1997·2004, *Crystal Clear*) | *"A Walking Skeleton is a tiny implementation of the system that performs a small end-to-end function. It need not use the final architecture, but it should link together the main architectural components. The architecture and the functionality can then evolve in parallel."* |
| **Tracer Bullet** | Hunt & Thomas, *The Pragmatic Programmer* | 같은 개념의 별칭으로 여러 해설이 명시 |
| **Steel Thread** | Journal of Computational Methods in Sciences and Engineering 12(s1) | *"identifies the most important execution paths, including software and hardware elements, through a computer system, while meeting business objectives and demonstrating executable architecture"* |

GOOS(Freeman & Pryce)의 정의는 더 강하다 — *"an implementation of the **thinnest possible slice of real functionality** that we can **automatically build, deploy and test end-to-end**."*

### 1.2 근거로 제시되는 것

- **통합 위험을 앞으로 당긴다** — *"Building components in isolation pushes integration risk to the end of the project. Data contracts, latency limits, output formats, and deployment constraints fail late, after teams have already optimized individual components."*
- **아키텍처 오류를 싸게 고친다** — *"Making changes to an architecture is harder and more expensive the longer it has been around"*
- **"simplest first, worst second"** — Cockburn은 "가장 어려운 것을 마지막에"라는 전략이 *"a surprisingly bad track record"*를 갖는다고 적고, 스켈레톤으로 첫 승리를 얻은 뒤 최악의 문제를 치라고 한다

**등급 주의**: §1.2의 근거는 대부분 **경험 기반 서술**이다. Walking Skeleton의 효과를 통제 실험으로 잰 자료를 찾지 못했다 — §8 열린 질문 1.

---

## 2. ② 목업으로 실증 — **여기서 자료가 반대한다**

### 2.1 정의 자체가 목업을 배제한다

**같은 문장이 여러 독립 출처에서 반복된다.**

> *"The best way to do this is to have **a real end-to-end test with no stubs** against a system that's deployed in production."*
> — Henrico Dolfing, Code Climate (동일 문장, 독립 게시)

> *"It's **not a prototype and not a proof of concept — it's production code**, so you should definitely write tests as you work on it."*
> — Code Climate

> *"It only provides useful signal **if it uses the real production path**. A throwaway prototype that bypasses actual data flow, serving, or monitoring **misses the failure modes that matter**."*
> — DistilledPatterns

**논리가 일관된다** — 스켈레톤의 효용은 "설계가 말이 되는지"가 아니라 **"구성 요소 경계에서 무엇이 깨지는지"**를 앞당겨 보는 데 있다. 목업은 바로 그 경계를 제거한다. 목업으로 통과한 체인은 **목업이 성립한다는 사실만 증명한다.**

### 2.2 그리고 순서가 제안과 정반대다

GOOS 4장·10장 구성이 이렇다 — *"Chapter 4: Kick-Starting the Test-Driven Cycle — **First, Test a Walking Skeleton** / Deciding the Shape of the Walking Skeleton / Build Sources of Feedback / Expose Uncertainty Early"*, *"Chapter 10. The Walking Skeleton — in which we set up our development environment and write our first end-to-end test."*

해설이 순서를 명시한다:

> *"**Only after you have your walking skeleton** should you write your first acceptance test and begin the TDD cycle."*
> *"It's important to stress that **until the walking skeleton is deployed to production** … you are not ready to write the first acceptance test."*
> *"The focus is **the infrastructure, not the features**."*

그 이유로 **"first-feature paradox"**를 든다 — 인프라와 첫 기능을 동시에 만들려 하면 서로가 서로를 바꾸므로, 인프라를 먼저 끝낸다.

> **제안과의 차이가 여기서 분명해진다.** 제안은 *"체인을 목업으로 만들어 워크플로우를 실증한 뒤 각 함수를 TDD로 채운다"* 이다. 문헌은 *"체인을 **얇지만 진짜로** 끝까지 이어 배포한 뒤, 그 위에서 기능을 TDD로 늘린다"* 이다. **①과 ③은 같고 ②만 다르다.**

### 2.3 목업이 필요해 보이는 이유와 그 대응

목업을 쓰고 싶어지는 상황은 실재한다 — 하위 구성 요소가 아직 없거나, 외부 시스템에 붙을 수 없거나. 문헌의 대응은 **목업이 아니라 슬라이스를 더 얇게 만드는 것**이다. Cockburn의 원 예시가 *"a ring of computers passing just a timing token"* — 기능이 거의 없지만 **경로는 진짜**다.

#### 2.3.1 용어 정정 — "목업"이 두 가지를 덮고 있었다 (2026-08-03 추가)

> **사용자 지적으로 추가한다.** 이 절과 §2.1이 쓴 "목업"은 **원 질문의 표현을 그대로 받은 것**이며, 실제로는 **성격이 다른 둘**을 한 단어로 덮고 있었다. **그 탓에 "목업 실증 금지"가 픽스처까지 금지하는 것처럼 읽힌다. 그것은 이 조사의 결론이 아니다.**
>
> **그리고 사용자는 처음부터 픽스처를 뜻했다.** 초판이 그것을 "질문자가 둘을 혼동했다"는 쪽으로 읽었는데 **그 읽기가 틀렸다** — 모호했던 것은 문서의 용어이지 질문이 아니었다.

| | 무엇 | 자료의 입장 |
|---|---|---|
| **목 데이터 (픽스처)** | 진짜 경로에 **가짜 입력**을 흘린다 | **반대하지 않는다. 오히려 표준형이다** — Cockburn의 `timing token`이 정확히 이것이다. 의미 없는 데이터가 **진짜 링**을 돈다 |
| **목 구현체 (스텁)** | 체인의 **구성 요소를 가짜 응답기로 대체**한다 | **이것이 §2.1의 `no stubs` 대상이다** |

**§2의 결론은 후자에만 걸린다.** 전자는 처음부터 대상이 아니었고, 이 정정은 **결론의 철회가 아니라 범위의 명확화**다.

**그리고 판별선은 "반환값이 계산된 것인가 미리 박힌 것인가"다.**

- 진짜 핸들러가 **빈 200을 계산해서** 반환한다 → 스켈레톤
- 다음 단계가 `201`을 읽으니까 `{status: 201}`을 **박아서** 반환한다 → 스텁

**독립 출처가 같은 선을 긋는다.** 참고 하네스의 `.harness/rules/testing.md`가 *"Only mock **external services, I/O, and time dependencies** / **Do not mock business logic**"* 이라 적는다 — Cockburn·GOOS와 무관한 출처인데 **경계(외부·I/O·시간)와 내부(비즈니스 로직)를 같은 기준으로 자른다.**

**같은 문서의 「다층 Guard 테스트 원칙」이 그 이유를 실패 모드로 설명한다** — *"선행 guard를 우회하거나 mock으로 제거하면, Guard 3 자체가 실패해야 할 입력에서 실패가 선행 guard에서 발생해 테스트가 의도를 검증하지 못한다"*, 체크리스트 항목은 *"mock 제거 없이 통합 경로로 실행되는가?"*. **내부 구성 요소를 빼면 실패 지점이 이동해 테스트가 이름과 다른 것을 재게 된다.** §2.1의 *"목업으로 통과한 체인은 목업이 성립한다는 사실만 증명한다"* 와 같은 말이다.

**그리고 목업을 정당하게 쓰는 길이 하나 있다 — §4.**

---

## 3. ③ 함수 단위 TDD — 지지된다. 다만 이유가 다르다

### 3.1 test-first 순서 자체는 효과가 없다 (피어리뷰, 이 조사에서 가장 강한 자료)

[Fucci, Erdogmus, Turhan, Oivo, Juristo, *A Dissection of the Test-Driven Development Process: Does It Really Matter to Test-First or to Test-Last?*](https://doi.org/10.1109/TSE.2016.2616877), IEEE TSE 43(7), 2017. **PDF 전문 확인.**

TDD 과정을 네 차원으로 분해했다.

| 차원 | 정의 | 측정 |
|---|---|---|
| **Granularity (GRA)** | 사이클 길이 | 사이클 지속시간의 **중앙값** |
| **Uniformity (UNI)** | 사이클 길이의 일정함 | 지속시간의 **중앙값 절대편차(MAD)** |
| **Sequencing (SEQ)** | 테스트를 먼저 쓰는가 | test-first 사이클의 우세도 |
| Refactoring effort (REF) | 리팩터링에 쓴 시간 비중 | — |

**표본**: 전문 개발자 **39명**에게서 수집한 **82개 데이터포인트**. 품질은 기능적 정확성으로 측정.

**결과 (초록 원문)**:

> *"Quality and productivity improvements were **primarily positively associated with the granularity and uniformity**. **Sequencing, the order in which test and production code are written, had no important influence.** Refactoring effort was negatively associated with both outcomes."*

**결론 (원문)**:

> *"The claimed benefits of TDD **may not be due to its distinctive test-first dynamic**, but rather due to the fact that TDD-like processes encourage [잘고 일정한 반복]"*

본문이 모델 선택 결과를 명시한다 — *"the final optimal models include the factors for **granularity, uniformity, and refactoring effort, but not sequencing**."* 그리고 상관: 사이클이 짧을수록 품질이 높다(ρ = −0.25, p = .02), GRA와 UNI는 양의 상관(ρ = .49, p = .0001) — **짧은 사이클과 일정한 리듬은 같이 간다.**

> **REF의 음의 계수는 조심해서 읽어야 한다.** 저자들이 직접 단서를 단다 — 검출된 리팩터링 사이클에 **해로운 종류(mixed refactoring)가 섞였을 가능성**이 있고, 리팩터링 구성 자체가 *"difficult to capture, or even define clearly"* 라 근사로 측정했다. **"리팩터링을 줄여라"로 읽으면 안 된다.**

### 3.2 메타분석 — 효과는 작고, 맥락이 지배한다

[Rafique & Mišić, *The Effects of Test-Driven Development on External Quality and Productivity: A Meta-Analysis*](https://dl.acm.org/doi/10.1109/TSE.2012.28), IEEE TSE 39(6), 2013. 27개 연구. **PDF 전문 확인.**

| 층위 | 값 |
|---|---|
| 초록의 결론 | TDD는 품질에 *"a small positive effect"*, 생산성에는 *"little to no discernible effect"* |
| **표준화 분석(품질)** — 효과크기 11개 / 실험 12개 / 피험자 743명 | **0.106 (고정효과) / −0.0101 (랜덤효과)** — *"very small to negligible impact on quality"*, 0.05에서 **유의하지 않음** |
| 하위집단 | 품질 개선과 생산성 하락 **둘 다 산업 연구에서 학계 연구보다 훨씬 크다** |
| 조절변수 | TDD군과 대조군의 **테스트 노력 차이**가 클수록 생산성 하락이 크다 |

> **초록과 표준화 분석 표가 같은 크기를 말하지 않는다.** 초록은 "작은 양의 효과", 본문 표준화 분석은 "무시할 만하고 유의하지 않음"이다. 두 값은 서로 다른 하위 집합에 대한 것으로 보이나 **이 조사에서 그 관계를 확정하지 못했다.** 수치를 인용할 때 반드시 어느 쪽인지 밝혀야 한다 — §8 열린 질문 5.
>
> **grid fin에 더 쓸모 있는 것은 하위집단 결과다** — 효과 크기가 맥락에 따라 갈린다는 사실 자체가, [evaluation.md §1.5.3](evaluation.md)이 확인한 "구성요소 하나 변경은 측정 불가"와 같은 방향을 가리킨다.

### 3.3 외부 재현 — 무효과

[Fucci et al., *An External Replication on the Effects of Test-driven Development Using a Multi-site Blind Analysis Approach*](https://people.brunel.ac.uk/~csstmms/FucciEtAl_ESEM2016.pdf), ESEM 2016. **PDF 전문 확인.**

> *"…we confirmed the baseline results: **TDD does not affect testing effort, software external quality, and developers' productivity**."*
> *"it appears that TDD does not improve, nor deteriorate the participants' performance **with respect to an iterative development technique in which unit tests are written after production code**."*

**대조군이 중요하다** — 비교 대상이 waterfall이 아니라 **반복적 test-last(ITL)**다. 저자들이 무효과의 원인 후보로 *"Control treatment: the baseline experiment and its replication compared TDD to a really similar approach"* 를 든다.

> **§3의 종합**: 세 자료가 같은 방향이다. **"테스트를 먼저 쓰느냐"는 측정 가능한 효과를 내지 못했고, "잘게 자르고 일정한 리듬으로 가느냐"는 냈다.** 제안의 ③은 유지되지만 **강조점이 옮겨간다** — 함수 단위로 쪼개는 것이 이득의 원천이고 test-first는 그것을 강제하는 수단 중 하나다.

---

## 4. 목업 체인을 정당화하는 유일한 규율 — 계약 테스트

§2가 목업을 반대했지만, **목업이 드리프트하지 않도록 묶는 성숙한 방법이 하나 있다.**

### 4.1 소비자 주도 계약 테스트 (CDCT)

[Pact 공식 문서](https://docs.pact.io/implementation_guides/javascript/docs/consumer):

> *"Pact is a consumer-driven contract testing tool … the API `Consumer` writes a test to set out its assumptions and needs of its API `Provider`(s). By unit testing our API client with Pact, **it will produce a `contract` that we can share to our `Provider` to confirm these assumptions and prevent breaking changes**."*

**핵심 차이**: 소비자 측 목이 **산출물(계약)**이 되어 제공자 측에서 실제로 검증된다. 목이 현실과 어긋나면 **제공자 검증이 깨진다.** §2가 경고한 "목업만 성립한다"는 실패 모드를 구조적으로 막는다.

**§6.1의 David Tanzer 지적이 정확히 이 문제였다** — outside-in에서 A의 테스트가 쓰는 목과 B·C의 테스트가 **항상 동기화돼 있어야만** 작동하는데, *"I know of no [automatic way to ensure this]"*. 계약 테스트가 그 자동 수단이다.

### 4.2 그러나 "이벤트 체인"은 반쯤 비어 있다

| | 동기 HTTP | 비동기 메시지 |
|---|---|---|
| Pact CDCT | 지원 | *"Supports HTTP/REST **and event-driven systems**"* |
| **양방향 계약 테스트(BDCT)** | 검증함 | **검증하지 않음** |

BDCT 공식 문서가 명시한다 — *"When using Pact specification V4 note that **only interactions with type "Synchronous/HTTP" are validated**. Bi-directional Contract validation **ignores other interaction types such as "Asynchronous/Messages"**."*

> **사용자 질문이 "함수 체인 **또는 이벤트 체인**"이었다. 이 조사가 찾은 자료는 압도적으로 호출 체인 쪽이다.** Walking Skeleton·Steel Thread·CodeSpec 전부 호출 경로를 다루고, 계약 테스트조차 비동기 쪽은 도구 지원이 좁다. **이벤트 체인의 목업 실증에 대한 자료를 찾지 못했다** — §8 열린 질문 3.

---

## 5. 에이전트 맥락 — 20년 뒤의 재확인 (프리프린트)

[Wang, Zhang, Liu, Li, Zhu, *CodeSpec: Dual Executable Specifications for Agentic Long-Horizon Feature Development*](https://arxiv.org/html/2607.26777) (arXiv 2607.26777). **HTML 전문 확인.**

**문제 정의가 사용자의 제안과 같다:**

> *"feature development requires integrating new behaviors into existing architectures through **coherent cross-component functional chains**. Existing agents typically derive such chains through free-form reasoning, often producing unreliable feature designs with **incomplete functional chains**."*
> *"Moreover, **textual designs are difficult to verify and enforce**, making it challenging to maintain design–implementation consistency throughout long-horizon development."*

**해법**: 기능 체인을 **실행 가능한 명세 두 종**(아키텍처 명세 + 행위 명세)으로 컴파일해, 체인의 **완전성과 정확성**을 검사하고 긴 상호작용 동안 설계–구현 일치를 유지한다.

**결과 (FeatureBench, DeepSeek-V4-Pro 백본)**: Lite/Fast/Full 각각 **70.7% / 55.0% / 49.9% %Passed**. Lite에서 최강 베이스라인(RTADev) 대비 **+5.4%p**. GPT-5.4-mini에서도 Codex를 앞섰다.

**이 조사에 가장 중요한 것은 헤드라인이 아니라 절제(ablation) 둘이다.**

| 절제 | 결과 |
|---|---|
| **행위 명세 제거** | 70.7% → **64.0%** — *"architecture connectivity alone cannot ensure correct outputs, boundary handling, or state transitions"* |
| 아키텍처 명세 제거 | 하락 |
| **명세를 텍스트로 대체**(CodeSpec Text) | 지시문 3,000~5,000단어에서 **71.8% vs 43.8%**. 200턴 초과에서 **65.2%**, 텍스트 방식 대비 **+14.0·+15.1%p** |

> **"체인 연결만으로는 부족하다"가 §2와 정확히 같은 말이다.** 아키텍처 연결(= 체인이 이어짐)을 확인해도 **출력·경계·상태 전이의 정확성은 보장되지 않는다.** 목업 체인이 증명하는 것이 딱 전자까지다.
>
> **그리고 텍스트 vs 실행 가능의 격차가 과제가 커질수록 벌어진다** — 짧은 과제에서는 세 방식이 비슷하다(*"below 3,000 words or interactions under 120 turns"*). **설계를 문서로 두는 것의 비용은 긴 작업에서만 드러난다.**

**등급 주의**: **단일 미검증 프리프린트이고 저자 자체 평가다.** 베이스라인에 Claude Code가 포함돼 있어 [harness-minimalism §1.6](harness-minimalism.md)이 적용한 것과 같은 할인이 필요하다. **절제 결과가 헤드라인 통과율보다 전이 가능성이 높다.**

---

## 6. 비판 축 — 목을 언제 쓰지 말아야 하는가

### 6.1 원저자들의 제한 (피어리뷰)

[Freeman, Mackinnon, Pryce, Walsh, *Mock Roles, not Objects*](https://jmock.org/oopsla2004.pdf), OOPSLA 2004.

- **목의 주된 효용은 테스트 격리가 아니라 설계 발견이다** — *"the most important benefit of Mock Objects is what we originally called **'interface discovery'**"*
- **자기 것이 아닌 타입을 목하지 말라** — 런타임·외부 라이브러리의 고정 타입 대신 *"thin wrappers to implement the application abstractions in terms of the underlying infrastructure"* 를 쓰고, **그 래퍼는 need-driven 테스트에서 정의된다**
- 저자들은 *"mock concrete classes"* 요청을 *"politely declined"* 했다고 적는다

**즉 목은 "아직 없는 것을 대신하는 껍데기"가 아니라 "필요가 발견한 역할의 정의"다.** 제안의 ②가 목을 쓴다면 이 구분이 결정적이다 — **체인을 그리기 위한 목이면 원저자들이 배제한 용법이고, 협력자의 역할을 발견하기 위한 목이면 원저자들의 용법이다.**

### 6.2 목 과다의 비용 (자가출판 / 벤더)

| 출처 | 지적 |
|---|---|
| Google Testing Blog, *Don't Overuse Mocks* | 의존이 여럿이면 목이 늘고, *"you'll probably be adding complexity if you add lots of new classes just to make your mocks happy"* |
| Ian Cooper, *TDD, Where Did It All Go Wrong* (NDC, 2013~) | 구현 세부를 목하면 테스트가 취약해진다. *"When we refactored something all these tests with mocks broke and we had to rewrite all the mocks."* 테스트 단위는 클래스·메서드가 아니라 **행위** |
| DHH, *Test-induced design damage* (2014) | *"changes to your code that either facilitates a) easier test-first, b) speedy tests, or c) unit tests, but does so by harming the clarity of the code — usually through needless indirection and conceptual overhead"* |
| David Tanzer, *The Mock Objects Trap* | outside-in은 A의 목과 B·C의 테스트가 동기화돼 있을 때만 작동하는데 자동 보장 수단이 없다 → §4가 그 답 |

**등급**: 이 절은 전부 자가출판·벤더 블로그·강연이다. **구조적 지적으로만 취급하고 수치는 없다.**

### 6.3 반대편도 있다

Jason Gorman의 정리 — *"London School vs. Classic TDD? Nope. It's London School AND Classic"*, 실제 시스템의 TDD는 두 스타일 요소를 다 요구한다. Enterprise Craftsmanship의 권고 — *"a combination of outside-in and middle-out TDD: start with a bit of domain modeling, then do outside-in TDD **without mocks**."*

---

## 7. grid fin에 대한 관측 (설계 아님)

### 7.1 제안을 자료에 맞추면 무엇이 바뀌는가

| 제안 | 자료가 가리키는 형태 | 근거 |
|---|---|---|
| 워크플로우·체인을 먼저 설계 | **그대로** | §1, §5 |
| **함수/이벤트 체인의 목업으로 실증** | **가장 얇은 진짜 경로를 끝까지 실행한다.** 목을 쓴다면 **계약 산출물**로 묶는다 | §2, §4 |
| 각 함수를 TDD로 구현 | **그대로. 단 test-first보다 사이클의 잘음·일정함을 지표로 둔다** | §3 |
| (제안에 없음) | **체인 연결 확인과 행위 정확성 확인을 분리한다** — 전자만으로는 64.0% | §5 절제 |

### 7.2 선행 조사와의 연결

**Fucci의 granularity 발견은 이 시리즈에 새 축이 아니라 기존 축의 보강이다.**

[workflow-and-feature-list.md](workflow-and-feature-list.md)가 축별 근거 상태를 정리하며 **립도(작업 단위 크기)**만 *"피어리뷰 2편이 독립 수렴"*으로 등급을 매겼고, 나머지(삼중 구조·상태 머신·WIP=1)는 단일 자가출판이었다. **Fucci TSE 2017이 세 번째 독립 수렴이고, 측정 단위가 "작업 단위"가 아니라 "사이클 시간"이라는 점에서 각도가 다르다.**

다른 연결:

| 선행 문서 | 이 조사와의 접점 |
|---|---|
| [workflow-stack-separation.md](workflow-stack-separation.md) §1 | **TDD red 단계가 "돌아서 실패"와 "돌지 않음"을 갈라야 한다**는 요구가, §3의 "잘은 사이클"을 다중 런타임에서 실제로 돌릴 수 있는가와 직결 |
| [harness-minimalism.md](harness-minimalism.md) §7.2 | 제안의 ①·②는 **절차적 제약**을 늘리는 방향이다. 그 문서가 그 축을 가설로 보류했으므로 여기서도 결론을 내지 않는다 |
| [evaluation.md](evaluation.md) §1.5.3 | §3.2의 하위집단 격차가 "맥락이 효과 크기를 지배한다"는 같은 관측 |

---

### 7.3 실제 동기 — "에이전트가 전체 흐름을 놓친다" (2026-08-03 추가)

> **사용자가 조사 동기를 명확히 했다** — *"개발 프로젝트에서 기존 하네스가 **현재 함수에 집중하다가 전체 흐름을 놓치는 경우가 너무 많다**"*. **초판은 이것을 "좋은 개발 방법인가"라는 일반 질문으로 받았다. 실제 질문은 "이 실패 모드에 스켈레톤 우선이 듣는가"다.** 판정 대상이 바뀌므로 따로 적는다.

#### 7.3.1 이것은 명명된 실패 모드다

[CodeSpec](https://arxiv.org/html/2607.26777)(§5)의 문제 정의가 **같은 관측의 학술 표현이다.**

> *"Existing agents typically derive such chains through **free-form reasoning**, often producing unreliable feature designs with **incomplete functional chains**."*
> *"**textual designs are difficult to verify and enforce**, making it challenging to maintain design–implementation consistency **throughout long-horizon development**."*

**즉 사용자가 본 것은 이 구성의 특이현상이 아니라 측정된 개입이 존재하는 실패 모드다.**

#### 7.3.2 활성 성분은 "스켈레톤"이 아니다

§5의 절제가 기제를 준다 — **텍스트 명세 43.8% vs 실행 가능 명세 71.8%**(지시문 3,000~5,000단어), 200턴 초과에서 **+14.0·+15.1%p**.

> **활성 성분: 컨텍스트에 든 흐름은 열화하고, 검사 가능한 산출물이 된 흐름은 열화하지 않는다.**

| 개입 | 흐름을 어디에 두는가 |
|---|---|
| 설계 문서 / 계획을 프롬프트에 서술 | **컨텍스트** — [§3.1 위치 효과·§3.2 절벽](instruction-layers.md)이 정확히 이 내용을 갉는다 |
| **Walking Skeleton** | **도는 코드** |
| **CodeSpec 실행 가능 명세** | **검사되는 명세** |

**스켈레톤 우선은 이 성분의 한 가지 배달 방식이지 성분 자체가 아니다.** 같은 성분을 더 싸게 배달하는 선택지가 있다 — 체인 완전성 검사, 하네스가 매 턴 다시 읽는 지속 계획 파일. **[워크플로우 조사 §3.2](workflow-and-feature-list.md)가 실측한 *"프로젝트 수준의 지속 산출물이 없다"* 가 그 부분의 공백이다.**

#### 7.3.3 임계가 있다 — 짧은 과제에는 안 듣는다

CodeSpec이 세 방식이 **수렴하는 구간**을 명시한다 — *"below 3,000 words or interactions under 120 turns"*.

> **검증 가능한 예측이 나온다: 이 문제는 긴 피쳐에서 나타나고 짧은 작업에서는 안 나타나야 한다.** 관측이 그렇지 않다면(짧은 작업에서도 흐름을 놓친다면) **원인이 §7.3.4의 다른 진단일 가능성이 높다.**

#### 7.3.4 진단이 셋이고 스켈레톤은 둘만 다룬다

**"전체 흐름을 놓친다"는 서로 다른 원인 셋을 덮는다. 이 시리즈가 셋을 다 측정했다.**

| 진단 | 증상 | 근거 | 스켈레톤 우선이 듣는가 |
|---|---|---|---|
| **① 컨텍스트 열화** | 초반에 말한 흐름이 뒤로 갈수록 안 지켜진다 | [§3.1·§3.2](instruction-layers.md), CodeSpec 절제 | **✅ 듣는다** — 흐름을 코드로 외부화 |
| **② 범위 이탈** | 요청하지 않은 것을 더 한다 / 국소 목표만 달성 | Opus 5 *"can expand the scope of a task"*([§2](context-file-content.md)), InfraBench *"satisfy visible objectives while missing deeper operational obligations"*([§5.2](non-coding-work.md)) | **❌ 안 듣는다** — 프롬프트 층의 범위 규율이 답이다 |
| **③ 지속 산출물 부재** | 세션이 바뀌면 흐름이 사라진다 | [워크플로우 §3.2](workflow-and-feature-list.md) 실측 | **✅ 듣는다** — 저장소가 기록 원천이 된다 |

> **②를 스켈레톤으로 고치려 하면 안 듣는다.** [컨텍스트 파일 조사 §2](context-file-content.md)가 확인한 대로 Opus 5의 범위 이탈에는 **공식 문서가 예시 문장까지 주는 프롬프트 처방**이 따로 있다. **먼저 어느 진단인지 갈라야 한다.**

#### 7.3.5 §8-2가 이 질문을 막지 않는다

§8-2는 *"grid fin은 markdown·프롬프트·스킬로 이뤄져 있어 '배포된 경로'의 대응물이 불분명하다"* 였다. **그것은 grid fin **자신**을 개발할 때의 문제이고, 사용자가 묻는 것은 하네스가 **감독하는 개발 프로젝트**다.** 감독 대상이 일반 소프트웨어라면 §1·§2의 "가장 얇은 진짜 경로"가 그대로 성립한다. **두 질문을 갈라 두어야 §8-2가 잘못된 차단 사유로 쓰이지 않는다.**

#### 7.3.6 근거의 세기 — 과장하지 않는다

**이 절의 재구성은 강한데 근거는 그만큼 강하지 않다.**

- **CodeSpec은 단일 미검증 프리프린트이고 저자 자체 평가이며 베이스라인에 Claude Code가 있다**(§5의 등급 주의). **절제가 통과율보다 전이 가능성이 높다는 판단은 유지한다.**
- **§8-1이 여전히 열려 있다** — Walking Skeleton 자체를 잰 통제 실험이 없다. §1의 근거는 전부 경험 서술이다.
- **따라서 "스켈레톤 우선이 이 문제를 고친다"는 실증이 아니라 *기제 일치*다.** 프리프린트 한 편(인접 개입)과 경험 서술 위에 선다.

---

### 7.4 진단 ④ — 기존 체인을 애초에 획득하지 못한다 (2026-08-03 추가)

> **사용자 관측 보강** — *"긴 피쳐 쪽에 주로 발생하지만, **짧은 피쳐도 기존 구현 흐름과 연동할 때** 간헐적으로 나타난다"*.
>
> **앞쪽은 §7.3.3의 예측과 맞는다(진단 ①). 뒤쪽은 §7.3.4의 셋 중 어디에도 안 들어간다** — 짧은 과제는 §7.3.3의 임계 아래라 컨텍스트 열화로 설명되지 않고, 요청 범위를 넘는 것도 아니다. **잃어버린 흐름이 "말해줬는데 잊은 것"이 아니라 "코드베이스에 이미 있는데 획득하지 못한 것"이다. 별도 진단이며, 따로 측정되어 있다.**

#### 7.4.1 실측 — 의미적 의존 간선을 못 찾는다

[Theory of Code Space (arXiv 2603.00601v2)](https://arxiv.org/abs/2603.00601v2). 절차적으로 생성한 중간 복잡도 Python 프로젝트에서 **부분 관측 하에** 에이전트가 아키텍처 신념을 구축하게 하고, 정답 의존 그래프와 대조한다. 간선 4종은 **발견 방법이 다르다.**

| 간선 | 비중 | 발견에 필요한 것 |
|---|---:|---|
| `imports` | ~67% | AST 파싱 |
| `calls_api` | ~17% | **함수 본문 읽기** |
| `registry_wires` | ~9% | 설정 파일 + 레지스트리 로딩 로직 |
| `data_flows_to` | ~7% | **오케스트레이션 로직 이해** — 한 모듈의 출력이 다른 모듈의 입력이 됨 |

**Table 3 (간선 종류별 재현율)**

| 방법 | imports | calls_api | data_flows | reg._wires |
|---|---:|---:|---:|---:|
| GPT-5.3-Codex | 0.69 | 0.15 | **0.31** | 1.00 |
| **Claude Sonnet 4.6** | 0.56 | **0.15** | **0.00** | 1.00 |
| Gemini 3.1 Pro | 0.27 | 0.00 | 0.50 | 0.00 |

**그리고 전체 지표의 형태가 이 조사에 중요하다** — Claude Sonnet 4.6의 Dep F1 0.664 = **정밀도 0.983 / 재현율 0.502**.

> **찾은 것은 거의 다 맞고, 절반을 못 찾는다.** 그리고 못 찾는 쪽이 **의미적 간선**(호출·데이터 흐름)이다. **AST로 잡히는 `imports`와 설정에 적힌 `registry_wires`는 잘 찾는다.**
>
> **이것이 "기존 구현 흐름과 연동할 때"의 정확한 형태다.** 새 코드를 붙일 곳은 대개 `calls_api`·`data_flows_to`로 이어져 있는데, 그 두 종이 재현율 0.15와 0.00이다. **에이전트는 자기가 본 것에 대해 틀리지 않는다 — 체인의 나머지 절반을 못 본 채로 옳게 작업한다.**

**등급 주의**: **미검증 프리프린트, 파일럿 실험, 절차 생성 코드베이스 3개, 탐색 예산 B=20.** 실제 저장소가 아니다. **그리고 모든 에이전트가 약하다** — 최고가 `data_flows` 0.31이다. Claude 고유 결함이 아니라 **현재 세대 공통**으로 읽어야 한다.

#### 7.4.2 기제 — 검색 용량이 아니라 "항해 현저성"

[The Navigation Paradox in Large-Context Agentic Coding (arXiv 2602.20048)](https://arxiv.org/html/2602.20048)가 원인을 다르게 짚는다.

> *"as context windows expand, the bottleneck shifts from **retrieval capacity to navigational salience**. The model does not fail because it lacks the token budget to read the relevant file — it fails because it [does not prioritize it]."*
> *"**Fitting a codebase in context does not guarantee that an LLM attends to the architecturally critical files** for a given task. This is not merely a lost-in-the-middle failure — it is a deeper [problem]."*

**개입**: `CodeCompass` — AST 의존 그래프를 Neo4j에 넣고 **1-hop 구조 이웃**을 반환하는 MCP 서버. 270회 시행.

| 과제 군 | 결과 |
|---|---|
| G1 (의미 과제) | **BM25가 최적** — 완전 커버리지, 분산 0 |
| G3 (숨은 의존) | **그래프 항해가 ACS +20%p** |

> **[지시 계층 §3.1·§3.2](instruction-layers.md)와의 관계를 정확히 읽어야 한다.** 이 논문은 자기 발견을 *"not merely a lost-in-the-middle failure"* 라고 명시한다 — **컨텍스트를 키워도 안 풀리는 별개 축**이라는 주장이다. **진단 ①과 ④가 다른 이유가 여기 있다.**

#### 7.4.3 그런데 개입이 실패하는 지점이 도입률이다

**이 논문에서 grid fin에 가장 값진 것은 +20%p가 아니다.**

> *"tool effectiveness (**99.5% when used**) vs tool discoverability (**42% overall adoption rate**). **The bottleneck is not the graph; it is ensuring consistent agent adoption.**"*
> G2(구조 과제): *"**zero trials out of 30 used the graph tool** on structural tasks, despite structural dependencies being the tool's primary [purpose]"*

**해결책이 구체적이고 이 시리즈와 맞물린다:**

> *"we developed an improved prompt with a **mandatory checklist positioned at the END of the prompt (to avoid Lost in the Middle suppression effects)**"*

> **[§3.1의 U자 위치 효과를 완화 대상이 아니라 배치 도구로 쓴 사례다.** 끝이 살아남는다는 성질을 이용해 체크리스트를 끝에 둔다. **이 시리즈가 위치 효과를 "피해야 할 열화"로만 다뤄 왔는데, 여기서는 설계 자원이다.**
>
> **그리고 [스킬 조사 §2.3](skill-architecture.md)의 관측과 같은 형태다** — Opus 4.8 문서가 *"prescriptive descriptions that state **when** to call a tool … give meaningful lift"* 라 했다. **도구가 있어도 안 쓰는 문제는 이 시리즈에서 반복 확인된다.**

#### 7.4.4 진단 ④에 스켈레톤 우선은 부분적으로만 듣는다

| | 신규 시스템 | **기존 시스템 연동** |
|---|---|---|
| 흐름의 소재 | 아직 없다 — **만들면서 정한다** | **이미 코드에 있다 — 찾아내야 한다** |
| Walking Skeleton | ✅ 정확히 이 용도 | **부분적** — 새로 놓는 얇은 경로는 만들 수 있으나 **기존 체인 획득을 대신하지 못한다** |
| 맞는 개입 | 스켈레톤 | **구조 그래프 항해**(§7.4.2) + 그것을 **쓰게 만드는 장치**(§7.4.3) |

> **참고 하네스에 이미 도구가 있다.** `AGENTS.md`의 graphify 포지셔닝 절이 *"graphify의 고유 가치는 LSP가 못 하는 **전체 코드베이스 조감** — god nodes, community 구조, 의외의 결합"* 이라 적고, 일상 네비게이션은 LSP에 맡긴다고 선을 긋는다.
>
> **§7.4.2는 그 분업에 한 칸을 더한다** — 승부처는 "조감"도 "일상 네비게이션"도 아니라 **특정 과제에 걸린 1-hop 구조 이웃**이고, **의미 검색(BM25)이 이기는 과제군과 그래프가 이기는 과제군이 갈린다**(G1 vs G3). **어느 쪽 도구를 언제 쓰는가가 설계 문제로 남으며, §7.4.3이 그것을 "쓰게 만드는" 쪽이 진짜 병목이라고 말한다.**

#### 7.4.5 정리 — 진단 넷

| 진단 | 사용자 관측과의 대응 | 맞는 개입 |
|---|---|---|
| ① 컨텍스트 열화 | **긴 피쳐 (주 발생)** | 스켈레톤 / 실행 가능 명세 |
| ② 범위 이탈 | (해당 없음으로 보임) | 프롬프트 층 범위 규율 |
| ③ 지속 산출물 부재 | 세션 간이면 해당 | 저장소를 기록 원천으로 |
| **④ 기존 체인 미획득** | **짧은 피쳐 + 기존 흐름 연동 (간헐)** | **구조 그래프 항해 + 도입 강제** |

**①과 ④는 개입이 다르다.** 하나는 흐름을 **외부화**하는 것이고 다른 하나는 흐름을 **획득**하는 것이다. **둘 다 있다면 둘 다 필요하며, 스켈레톤만으로는 ④가 남는다.**

---

## 8. 열린 질문

1. **Walking Skeleton 자체의 효과를 잰 통제 실험이 있는가.** §1의 근거는 전부 경험 서술이다. Steel Thread 논문(JCMSE 2012)이 사례 연구 하나를 담고 있으나 본문을 받지 못했다
2. **"가장 얇은 진짜 경로"를 개인 하네스 규모에서 어떻게 정의하는가.** 문헌의 예시는 배포 파이프라인·CI·모니터링까지 포함한다. grid fin은 markdown·프롬프트·스킬로 이뤄져 있어([workflow-and-feature-list.md](workflow-and-feature-list.md) 관측 6) "배포된 경로"의 대응물이 불분명하다
3. ~~**이벤트 체인의 목업 실증 자료를 찾지 못했다.**~~ **해소 (2026-08-03) — [§9](#9-이벤트-체인--8-3-후속-2026-08-03).** **도구 한계도 방법론 공백도 아니었다. 초판이 "테스트" 문헌만 뒤졌고 답의 절반이 "관측성" 문헌에 있었다.** 그리고 **§4.2의 BDCT 공백은 *양방향* 검증에만 걸리는 좁은 사실인데 이 절이 과일반화했다** — 표준 Pact는 async를 지원한다(§9.1)
4. **CodeSpec의 "실행 가능 명세"를 하네스 층에서 무엇으로 표현하는가.** 논문은 자체 컴파일러를 쓴다. grid fin은 거기에 무엇을 둘지 모른다
5. **Rafique & Mišić의 초록 결론과 표준화 분석 표(0.106 / −0.0101)의 관계**(§3.2 유보)
5b. ~~**진단 ④의 개입을 grid fin에서 무엇으로 두는가**~~ **후속 조사 완료 (2026-08-03) — [구조 항해 조사](structural-navigation.md).** 개입은 **세 층**(구조 인덱스 / 에이전트용 질의 도구 / 도입 강제)이고 **피어리뷰 앵커([LocAgent, ACL 2025](https://aclanthology.org/2025.acl-long.426/))가 도구 규격을 준다** — `SearchEntity`·`TraverseGraph`·`RetrieveEntity` 셋뿐이며 저자들이 기존 IDE형 도구를 *"designed for human [reading]"* 이라 기각한다. **그리고 §7.4.3의 예측이 맞았다** — 자료가 가장 얇은 곳이 도입 강제 층이고, **"편집 전 구조 조회 강제"에 해당하는 발표 사례를 찾지 못했다.** 도구 대조는 그 문서 §5.
5c. **ToCS의 실측이 실제 저장소로 전이되는가**(§7.4.1). 절차 생성 코드베이스 3개·예산 B=20의 파일럿이다. **`data_flows_to` 재현율 0.00을 실제 프로젝트 수치로 읽으면 안 된다**
6. **Fucci의 granularity가 에이전트에게도 성립하는가.** 82 데이터포인트는 전부 사람이고, "5분 사이클"이 에이전트 턴에 어떻게 대응하는지 다룬 자료를 찾지 못했다
7. **§3의 무효과 결과가 "TDD를 하지 말라"인가.** 세 자료 모두 대조군이 **반복적 test-last**다. 대조군이 "테스트 없음"이었을 때의 비교는 이 조사에서 다루지 않았다

---

## 9. 이벤트 체인 — §8-3 후속 (2026-08-03)

**조사 계기**: 사용자가 *"내가 의미한 것은 목 데이터(픽스처)였다"* 고 명확히 하고 이벤트 체인 자료를 추가 요청했다. **§8-3이 이 조사의 유일한 "자료를 못 찾았다" 항목이었으므로 그것부터 닫는다.**

### 9.0 왜 초판이 못 찾았는가

**동기 체인과 비동기 체인의 차이는 입력이 아니라 단언 지점이다.**

| | 동기 호출 체인 | 비동기 이벤트 체인 |
|---|---|---|
| 픽스처 주입 | 인자로 | 메시지로 — **똑같이 된다** |
| **단언 지점** | **반환값** | **없다** |

**초판은 "테스트" 문헌만 뒤졌고, 비동기 체인에는 반환값이 없어서 테스트 문헌에 단언 방법이 안 나온다.** 답의 한 층이 **관측성 문헌**에 있었다(§9.3). **도구 한계도 방법론 공백도 아니라 검색 축의 문제였다.**

### 9.1 계약 층 — 표준 Pact는 async를 지원한다 (§4.2 정정)

[Pact 공식 문서 — Event Driven Systems](https://docs.pact.io/implementation_guides/javascript/docs/messages):

> *"Pact has support for these use cases, by **abstracting away the protocol and focussing on the messages passing between them**."*

JS·Go·Python([2.2.1부터 async 메시지 검증 지원](https://pact-foundation.github.io/pact-python/blog/2024/07/26/asynchronous-message-support/)) 모두 구현 가이드가 있고, [Kafka 레시피](https://docs.pact.io/recipes/kafka)가 별도로 존재한다.

> **§4.2를 정정한다.** 그 절이 인용한 *"only interactions with type `Synchronous/HTTP` are validated"* 는 **양방향 계약 테스트(BDCT)에만** 걸리는 제약인데, §4.2가 그것을 "이벤트 체인 쪽은 자료 공백"으로 넓혔다. **소비자 주도 계약 테스트(CDCT) 본류는 async를 정면으로 다룬다.**

**그러나 Pact의 범위를 정확히 읽어야 한다.**

> *"**Pact takes the place of the intermediary (MQ/broker etc.)** and confirms whether or not the consumer is able to handle a request."*

**브로커가 없다.** Pact가 검증하는 것은 **메시지 모양의 계약**이지 **체인이 도는가**가 아니다. Kafka 레시피가 그것을 자인한다 — *"Given that we're **not actually running Kafka**, we're also not running the Schema Registry"*(`MockSchemaRegistryClient`, `mock://` URL 사용).

**그래서 레시피가 규율을 하나 강조한다** — 소비자 테스트가 **프로덕션 역직렬화기**를 끌어다 써야 한다:

> *"The `getProductionKafkaDeserializer` method is intended to **reach into your production code** (otherwise **we're just testing the test code**, and not a lot of point in that!)"*

> **§2.1의 *"목업으로 통과한 체인은 목업이 성립한다는 사실만 증명한다"* 를 Pact 저자들이 같은 말로 반복한다.** 계약 테스트는 그 함정을 **제공자 측 검증**으로 막지, 목을 정당화해서 막지 않는다.

### 9.2 실경로 층 — 진짜 브로커 + 픽스처 메시지

**사용자가 말한 "목 데이터로 진짜 경로"의 이벤트 체인 판이 여기다.** Testcontainers로 **진짜 Kafka 브로커**를 띄우고 픽스처 메시지를 흘린다 ([Docker 공식 가이드](https://docs.docker.com/guides/testcontainers-java-spring-boot-kafka/write-tests/), [Testcontainers 가이드](https://testcontainers.com/guides/testing-spring-boot-kafka-listener-using-testcontainers/)).

**그리고 "진짜"의 정의가 여기서 갈린다.** [Conduktor](https://www.conduktor.io/blog/testing-kafka-testcontainers-embedded-mocks)가 세 방식을 비교하며 지적한다 — `@EmbeddedKafka`는 *"runs a **different Kafka implementation than production** — one that can accept messages and serialize records in ways that a real Kafka broker would [not]"*.

> **Cockburn의 `timing token`과 같은 구조다** — 데이터는 가짜, **링은 진짜**. `@EmbeddedKafka`는 링을 가짜로 바꾼다.

**대가도 측정치가 있다.**

| 층 | 도구 | 시간 | 적합 |
|---|---|---:|---|
| 단위 | `MockProducer` | 밀리초 | 비즈니스 로직 |
| 통합 | **Testcontainers** | ~5–10초 | **End-to-end, Schema Registry** |
| 통합 | `@EmbeddedKafka` | ~3–5초 | Spring Boot(단, 구현이 다름) |

> **같은 글이 *"We cut our CI time from 18 minutes to 3 by replacing Testcontainers with MockProducer for business logic tests. **Integration tests stayed for the wiring**"* 라 적는다.** **자가출판이며 수치는 미검증이다.** 다만 **분업의 형태는 §2와 정확히 일치한다** — 배선(체인)은 진짜 경로로, 로직은 목으로.

### 9.3 단언 층 — 반환값이 없을 때 trace가 그 역할을 대신한다

**§9.0이 지목한 빈 칸을 채우는 것이 trace 기반 테스트다.** [Tracetest](https://docs.tracetest.io/)는 *"trace-based testing tool for integration and end-to-end testing using OpenTelemetry traces. **Verify end-to-end transactions and side-effects across microservices**"*.

[이벤트 주도 시스템 사례](https://tracetest.io/blog/testing-event-driven-systems-with-opentelemetry)가 문제를 정확히 진술한다:

> *"since the 'Payment Order API' just receives the order quickly and forwards it to Kafka, **we don't have so much information about the process**, as can be seen on this HTTP Response … With this limitation in mind, **how can I validate if the other workers have performed their tasks correctly?** A good way is to **make the entire process observable**."*

**그리고 단언은 span에 건다.** [span 순서 단언](https://tracetest.io/blog/tracetest-tip-testing-span-order-with-assertions)이 이 조사에 가장 직접적이다 — *"testing if Service B is called **after** Service A"*:

```yaml
specs:
  - selector: span[service.name="service-a"] span[service.name="service-b"]
    assertions:
      - attr:tracetest.selected_spans.count >= 1
```

> *"Declaring the selector in this order means that it will only select spans from `service-b` that come **after** spans from `service-a`."*
> *"you can validate if the **dependencies are organized as intended**, and even use it to validate if a **trace is being propagated** between services."*

> **이것이 "체인이 실제로 끝까지 이어졌는가"에 대한 단언이다.** 동기 체인에서 반환값이 하던 역할을 span 순서가 한다. **그리고 픽스처는 그대로 쓴다** — 트리거는 진짜 HTTP POST에 가짜 주문 데이터다.

### 9.4 세 층은 서로를 대체하지 않는다

| 층 | 증명하는 것 | 브로커 | 단언 지점 |
|---|---|---|---|
| **계약** (Pact message) | 메시지 **모양**이 소비자 기대와 맞는가 | **없음**(Pact가 대체) | 소비자 핸들러 + 제공자 검증 |
| **실경로** (Testcontainers) | 체인이 **진짜 브로커에서 도는가** | **진짜** | 최종 상태(DB 등) |
| **관측** (Tracetest/OTel) | **어느 구간까지 갔는가**, 순서가 맞는가 | 진짜(실행 환경) | **span** |

**§8-3의 판정**: **(b) 도구 공백이되 좁다.** 방법은 셋 다 존재하고 도구도 있다. **비어 있는 것은 BDCT의 async 검증 하나뿐이며, 그것은 CDCT로 대체된다**(§9.1).

> ⚠️ **한 가지 함정을 분리해 둔다.** 비동기 테스트 자료의 상당수가 "eventual consistency 때문에 폴링·타임아웃이 필요하다"를 다룬다. **그것은 *기다리는* 방법이지 *단언하는* 방법이 아니다.** 둘을 섞으면 "sleep을 넣어라"로 읽힌다. §9.3이 답하는 것은 단언 쪽이다.

### 9.5 이 후속이 답하지 않은 것

1. **grid fin 규모에 이것이 옮겨지는가.** 세 층 전부 마이크로서비스·Kafka·OTel 수집기를 전제한다. **[비코딩 작업 조사 §7-2](non-coding-work.md)가 지적한 것과 같은 규모 격차다.**
2. **하네스 자신의 "이벤트 체인"이 무엇인가.** 훅(`PreToolUse`→`PostToolUse`)과 스킬 포크(`context: fork`)가 비동기 체인의 형태를 갖는다. **[관찰성 조사](observability.md)가 확인한 Claude Code의 OTel 스팬 6종이 §9.3의 단언 대상이 될 수 있으나, 그 연결을 시험하지 않았다.**
3. **Testcontainers CI 수치(18분→3분)는 자가출판 단일 출처다**(§9.2).
4. **Pact의 async 지원 범위를 언어별로 확인하지 않았다.** JS 문서와 Kafka 레시피(Java)만 읽었다.

---

## 참고문헌

**피어리뷰**
- [Fucci, Erdogmus, Turhan, Oivo, Juristo, *A Dissection of the Test-Driven Development Process*](https://doi.org/10.1109/TSE.2016.2616877) — IEEE TSE 43(7), 2017 ([PDF](https://oa.upm.es/50842/1/INVE_MEM_2018_276502.pdf), [arXiv](https://arxiv.org/abs/1611.05994))
- [Rafique & Mišić, *The Effects of TDD on External Quality and Productivity: A Meta-Analysis*](https://dl.acm.org/doi/10.1109/TSE.2012.28) — IEEE TSE 39(6), 2013 ([PDF](https://raidoninc.com/assets/research/tddMetaAnalysis.pdf))
- [Fucci et al., *An External Replication on the Effects of TDD Using a Multi-site Blind Analysis Approach*](https://people.brunel.ac.uk/~csstmms/FucciEtAl_ESEM2016.pdf) — ESEM 2016
- [Freeman, Mackinnon, Pryce, Walsh, *Mock Roles, not Objects*](https://jmock.org/oopsla2004.pdf) — OOPSLA 2004
- [*Steel threads: Software engineering constructs for defining, designing and developing software system architecture*](https://dl.acm.org/doi/10.5555/2608547.2608553) — JCMSE 12(s1) — **초록만 확인, 본문 미입수**

**프리프린트 (미검증)**
- [Wang et al., *CodeSpec: Dual Executable Specifications for Agentic Long-Horizon Feature Development*](https://arxiv.org/html/2607.26777) — arXiv 2607.26777

**1차 (서적·공식 문서)**
- Freeman & Pryce, *Growing Object-Oriented Software, Guided by Tests* — [4장·10장 구성](https://www.oreilly.com/library/view/growing-object-oriented-software/9780321574442/ch10.html), [ACCU 2012 발표 자료](https://accu.org/conf-docs/PDFs_2012/Walking_skeleton.pdf)
- Cockburn — Walking Skeleton 정의 ([원저자 재확인](https://www.linkedin.com/posts/alistaircockburn_what-is-a-walking-skeleton-and-why-do-i-need-activity-7419086703577071616-D8Cs))
- [Pact — Consumer Tests](https://docs.pact.io/implementation_guides/javascript/docs/consumer) · [BDCT 지원 계약](https://support.smartbear.com/pactflow-on-premises/docs/en/user-guide/contract-testing/bi-directional-contract-testing/supported-contracts/pact.html)

**자가출판 (구조적 주장만, 수치 인용 금지)**
- [Code Climate — Kickstart Your Next Project with a Walking Skeleton](https://codeclimate.com/legacy/kickstart-your-next-project-with-a-walking-skeleton) · [Henrico Dolfing](https://www.henricodolfing.ch/en/start-your-project-with-a-walking-skeleton/) · [DistilledPatterns](https://distilledpatterns.org/patterns/walking-skeleton/)
- [DHH — Test-induced design damage](https://dhh.dk/2014/test-induced-design-damage.html) · [Ian Cooper — TDD, Where Did It All Go Wrong (InfoQ)](https://www.infoq.com/presentations/tdd-original/) · [Google Testing Blog — Don't Overuse Mocks](https://testing.googleblog.com/2013/05/testing-on-toilet-dont-overuse-mocks.html) · [David Tanzer — The Mock Objects Trap](https://www.davidtanzer.net/david's%20blog/2016/06/03/the-mock-objects-trap.html) · [Enterprise Craftsmanship — GOOS Without Mocks](https://enterprisecraftsmanship.com/posts/growing-object-oriented-software-guided-by-tests-without-mocks/)

---

## 방법론

검색 어댑터 스킬로 수행했다. `skill-registry` 질의 `[search-adapter]` → `adapter-exa`, `adapter-firecrawl` 2건 발견, **둘 다 정상 동작(실패 0건)**.

| 어댑터 | 연산 | 호출 |
|---|---|---|
| adapter-exa | `/search` (type=auto, numResults=8) | 7 |
| adapter-exa | `/contents` (배치) | 2 — 문서 6건 전문 |
| adapter-firecrawl | `/v1/search` (limit=8) | 7 |

**하위 질문 5개**: ① 워크플로우 우선 패턴의 정의와 근거 ② outside-in / London school TDD와 GOOS ③ 목 과다·설계 손상 비판 ④ test-first 순서 자체의 실증 근거 ⑤ 에이전트·SDD 맥락.

**심층 판독 6건**: Fucci TSE 2017, Rafique & Mišić 2013, Fucci ESEM 2016, CodeSpec, Mock Roles not Objects, DHH.

**이 조사가 하지 않은 것**: Steel Thread 논문 본문 미입수, GOOS 서적 본문 미입수(목차·인용문만), Ian Cooper 강연 전사 미확인, 이벤트 체인 관련 1차 자료 미발견.
