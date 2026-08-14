# 저장소 위생 — 구현 참조 자료

**최초 작성**: 2026-08-02
**최종 수정**: 2026-08-02
**대상 프로젝트**: grid fin (신규 개인용 개발 하네스)
**성격**: **자료 수집·정리.** grid fin 구현 시 참조할 외부 자료를 모으고 정돈한다. 문서 정책을 선택하지 않는다.
**조사 도구**: WebFetch 7회(1차 본문·공식 명세), WebSearch 2회(자료 위치 파악), 하네스·적용 프로젝트 실측(보조)

선행 문서
- [research-agenda.md](research-agenda.md) §11 — 이 조사의 출처
- [instruction-layers.md](instruction-layers.md) §1.1 — 상시 로드 1,044줄 실측
- [harness-distribution.md](harness-distribution.md) §1.2·§6.3 — gitignore 추적 문제, 그리고 이 논문의 1차 확인
- [evaluation.md](evaluation.md) §4 — 설정 기제 채택률의 실증 기준선

---

## 0. 이 문서의 쓰임

**grid fin을 구현할 때 "저장소에 무엇을 남기고 무엇을 남기지 않을 것인가"에 답할 근거를 모았다.**

| 자료 | 층 | 무엇을 주는가 | 등급 |
|---|---|---|---|
| [Gloaguen, Mündler, Müller, Raychev, Vechev, *Evaluating AGENTS.md*](https://arxiv.org/abs/2602.11988) | **문서의 효용** | 설명 문서가 에이전트에게 **효과 없이 비용만 20% 이상** 늘린다는 실측. 지시는 반대 | 프리프린트 (v1·v2, 소속 미기재) |
| [MADR 4.0.0](https://adr.github.io/madr/) · [adr.github.io](https://adr.github.io/) | **결정 기록 명세** | ADR의 공식 정의, 필드 전량, 파일 배치 규약 | 명세 (커뮤니티 표준) |
| [adr.github.io/adr-tooling](https://adr.github.io/adr-tooling/) | **소비 쪽 공백** | 도구 20여 종 전수 — **기계 소비용 파서 0종** | 공식 목록 |
| [ArchUnit 사용자 가이드](https://www.archunit.org/userguide/html/000_Index.html) | **경계 강제** | 아키텍처 규칙을 테스트 코드로 쓰는 API, **기존 위반 동결** 기제 | 1차 (공식 문서) |

**§1~§3이 자료다. §4는 아젠다의 규정 하나를 점검하고, §5는 실측이며 보조 목적이다.**

**이 문서의 결론 형태를 미리 적어 둔다.** 아젠다 §11이 물은 것은 *"문서가 부패하니 테스트·ADR로 바꿔야 하는가"* 였다. **가장 강한 자료가 답하는 것은 부패가 아니다** — 설명 문서 한 범주는 **부패하기 전에, 첫날부터 순효용이 음수다**: 성공률을 개선하지 않으면서 비용을 20% 이상 늘린다(§1). 부패는 그 위에 얹히는 문제다.

---

## 1. 설명 문서의 효용이 음수라는 실측

[Thibaud Gloaguen, Niels Mündler, Mark Müller, Veselin Raychev, Martin Vechev, *Evaluating AGENTS.md: Are Repository-Level Context Files Helpful for Coding Agents?*](https://arxiv.org/abs/2602.11988) (arXiv 2602.11988, v1 2026-02-12 / v2 2026-06-23).

[배포 조사 §6.3](harness-distribution.md)이 이 논문을 블로그 2차 인용으로 잘못 규정했다가 정정한 바 있다. **이 조사는 arXiv HTML 본문에서 직접 읽었다**(판본 주의는 §6 참고).

### 1.1 실험 규모

| 축 | 내용 |
|---|---|
| 벤치마크 | **SWE-bench Lite** (300 태스크 / 인기 Python 저장소 11개), **AGENTbench** (138 인스턴스 / 비주류 Python 저장소 12개) |
| 에이전트·모델 | Claude Code + Sonnet-4.5 / Codex + GPT-5.2 · GPT-5.1-mini / Qwen Code + Qwen3-30b-coder |
| 비교 대상 | **LLM이 생성한** 컨텍스트 파일과 **개발자가 쓴** 컨텍스트 파일 양쪽 |

**두 벤치마크의 대비가 설계상 중요하다** — 인기 저장소(모델이 이미 알 가능성)와 비주류 저장소(모를 가능성)를 갈랐다.

### 1.2 결과

> *"providing context files does not generally improve task success rates, while increasing inference cost by over 20% on average."*

**"over 20% on average"는 전 설정을 아우른 총계다.** 벤치마크별로 갈라 보면 이렇다.

> *"LLM-generated context files cause performance drops in **5 out of 8 settings** across SWE-bench Lite and AGENTbench… the context files increase the # steps in every setting on average by **2.45 and 3.92 steps**, respectively, which leads to a **cost increase of 20% and 23%** on average, respectively"*

| 컨텍스트 파일 종류 | 성공률 | 단계 증가 | 비용 증가 |
|---|---|---|---|
| LLM 생성 — SWE-bench Lite | 8개 설정 중 **5개에서 하락** | +2.45 | **+20%** |
| LLM 생성 — AGENTbench | 〃 | +3.92 | **+23%** |
| 개발자 작성 | 유의한 개선 없음 | — | 최대 **+19%** |

**비용 단위가 토큰이 아니라 인스턴스당 USD다.** [관찰성 조사 §1.2](observability.md)의 `claude_code.cost.usage`(단위 USD)가 같은 양을 로컬에서 재는 계기다. **그리고 비용 증가의 경로가 "단계 수 증가"로 특정되어 있다** — 컨텍스트 파일이 프롬프트를 키워서가 아니라 에이전트가 더 많이 돌아서 비싸진다는 뜻이다.

### 1.3 갈리는 지점 — 지시는 따르고 개요는 안 듣는다

**이것이 이 문서 전체에서 가장 실용적인 자료다.**

**지시(instruction)는 실제로 행동을 바꾼다.** 논문이 든 수치:

> 컨텍스트 파일에 `uv`가 언급되면 인스턴스당 평균 **1.6회** 사용된다. 언급되지 않으면 **0.01회 미만**이다.

**두 자릿수 배율이 아니라 백 배 이상의 차이다.**

**반면 저장소 개요(repository overview)는 효과가 없다.**

> *"Context files, even developer-provided ones, are not effective at providing a repository overview."*

관련 파일을 찾는 지표에서 *"presence of context files does not meaningfully reduce this metric"* 이다.

### 1.3.1 출처 감사에서 확보한 것 두 가지 (2026-08-02 추가)

**(1) 개요는 얼마나 흔한가 — 논문이 세었다.**

초판은 §6-1에서 "지시와 개요를 가르는 조작적 기준이 없다"고 적었다. **전면적 분류 체계는 여전히 없으나, 개요의 출현율은 논문이 집계한다.**

| 출처 | 개요를 포함한 비율 |
|---|---|
| 개발자 작성 (AGENTbench 12개) | **8개** — 그중 4개는 디렉터리를 명시적으로 열거 |
| LLM 생성 — Sonnet-4.5 | **100%** |
| LLM 생성 — GPT-5.2 | **99%** |
| LLM 생성 — Qwen3-30b-coder | **95%** |
| LLM 생성 — GPT-5.1 mini | 36% |

**"컨텍스트 파일을 LLM에게 쓰게 하면 거의 항상 개요가 들어간다"** — §1.4의 권고(LLM 생성 파일 배제)가 왜 그 형태인지 설명된다. 효과 없는 범주가 자동 생성물의 기본값이다.

**(2) v1과 v2의 초록이 강도가 다르다.**

| 판본 | 초록의 표현 |
|---|---|
| **v1** (2026-02-12) | *"context files tend to **reduce** task success rates compared to providing no repository context"* |
| **v2** (2026-06-23) | *"providing context files **does not generally improve** task success rates"* |

**v2에서 주장이 약해졌다.** "낮춘다"에서 "일반적으로 개선하지 않는다"로 바뀌었다. **비용 수치(over 20%)는 양쪽 동일하다.** 이 문서는 §1.2에서 v2 표현을 인용하며, 절 단위 수치(20%/23%, 2.45/3.92단계)는 v1 본문 값이다.

### 1.4 저자들의 권고 (원문)

> *"We therefore suggest omitting LLM-generated context files for the time being, contrary to agent developers' recommendations, and including only minimal requirements (e.g., specific tooling to use with this repository)."*

**"에이전트 개발사의 권고에 반한다(contrary to agent developers' recommendations)"** 를 명시한다. 그리고 남기라고 한 유일한 범주가 **"이 저장소에서 쓸 특정 도구"** 다.

### 1.5 아젠다 §11-1을 다시 쓰면

아젠다는 *"테스트는 문서보다 부패에 강하다"* 는 명제의 실천 범위를 물었다. **자료는 그보다 앞선 질문에 답한다.**

| 문서 범주 | 자료가 말하는 것 |
|---|---|
| **도구·명령 등 지시** | 실제로 따른다 (100배 차이) — **남긴다** |
| **저장소 구조·개요 서술** | 성공률 개선 없음, 비용 +20% — **부패 이전에 이미 손해** |
| LLM이 생성한 문서 전반 | 저자가 명시적으로 배제를 권고 |

> **주장 강도를 정확히 적어 둔다 (2026-08-02 출처 감사).** 세 층이 다르다.
> - **v2 초록(최신) 수준**: *"does not generally improve task success rates"* + 비용 20% 초과 — **개선 없음 + 비용**이다.
> - **v1 초록**: *"tend to **reduce** task success rates"* — 더 강했고 **v2에서 철회되었다**(§1.3.1-2).
> - **v1 본문 §4.2**: LLM 생성 파일이 *"performance drops in **5 out of 8 settings**"* — 이것은 절 단위 관측이지 전체 주장이 아니다.
>
> **따라서 "성능이 낮아진다"를 이 문서의 주장으로 쓰지 않는다. 쓰는 것은 "개선하지 않으면서 비용을 늘린다"이고, 그것만으로 §1.5의 결론이 선다.**

**부패 논거를 동원하지 않아도 결론이 선다.** 부패는 두 번째 이유이지 첫 번째가 아니다.

> **전이 범위 주의.** 논문의 대상은 **컨텍스트 파일**(상시 로드되는 `AGENTS.md`류)이다. 온디맨드로 읽히는 설계 문서·스펙에 그대로 적용된다는 근거는 논문에 없다. §5.2가 이 구분에 걸린다.

---

## 2. 결정 기록 — 형식은 표준화되어 있고 소비는 비어 있다

아젠다 §11-2가 "ADR을 에이전트가 소비 가능한 형태로 두는 방법"을 물었다. **형식 쪽과 소비 쪽을 따로 확인했고 결과가 갈린다.**

### 2.1 형식은 표준이 있다

[adr.github.io](https://adr.github.io/)의 공식 정의다.

> **Architectural Decision (AD)**: *"A justified design choice that addresses a functional or non-functional requirement that is architecturally significant."*
> **Architecturally Significant Requirement (ASR)**: *"A requirement that has a measurable effect on the architecture and quality of a software and/or hardware system."*
> **Architectural Decision Record (ADR)**: *"Captures a single AD and its rationale."*

[MADR 4.0.0](https://adr.github.io/madr/)(2024-09-17)이 구조를 준다.

| 층 | 내용 |
|---|---|
| 파일 배치 | `docs/decisions/NNNN-title-with-dashes.md` (`NNNN`은 연번, 최대 9,999) |
| YAML front matter | `parent`, `nav_order`, `title`, **`status`**, `date`, `decision-makers`, `consulted`, `informed` |
| 본문 절 | Context and Problem Statement / Decision Drivers / **Considered Options** / **Decision Outcome** / Consequences / Confirmation / Pros and Cons of the Options / More Information |

**§1.5의 분류에 비추면 ADR은 "개요"가 아니다.** 저장소가 무엇인지 서술하지 않고 **왜 그렇게 되었는지와 무엇을 버렸는지**를 적는다. `Considered Options`가 코드에서 유도 불가능한 정보의 전형이다 — 채택되지 않은 안은 코드에 남지 않는다.

**형식이 기계 친화적이라는 점도 확인된다** — YAML front matter, 연번 파일명, 열거형 `status`. 파싱에 필요한 것이 갖춰져 있다.

### 2.2 그런데 소비하는 도구가 없다

[공식 도구 목록](https://adr.github.io/adr-tooling/)을 전수 확인했다. 20여 종이 있다.

| 부류 | 예 |
|---|---|
| 생성·관리 CLI | `adr-tools`(bash + 8개 언어 재구현), `pyadr`, `dotnet-adr`, ADG, Talo, Hugo Markdown ADR Tools |
| 색인·렌더링 | `adr-log`(*"CLI to keep an `index.md` file updated with all ADRs"*), `adr-viewer`, Log4brains, Backstage ADR plugin |
| 편집 UI | ADR Manager (웹 / VS Code), ReflectRally, adr.zone, Loqbooq |
| 코드 내장 | `architectural-decision`(PHP 애트리뷰트), e-adr(Java) |

**전부 생성·관리·시각화다. 프로그램이 ADR을 읽어 쓰는 도구가 목록에 없다.** 그리고 목록 어디에도 **기계 소비·에이전트/LLM 연동·코드 연결**에 관한 언급이 없다.

### 2.3 §11-2의 답은 반쪽이다

**형식은 준비되어 있다(§2.1). 소비 경로는 자료에 없다(§2.2).** 그리고 §1.3의 구분이 여기 걸린다 — ADR을 **상시 로드**하면 "개요" 쪽 위험을 안고, **온디맨드**로 두면 언제 읽힐지가 라우팅 문제가 된다. 어느 쪽이 나은지 말하는 자료를 찾지 못했다. §6-2로 넘긴다.

---

## 3. 경계를 코드로 강제하기 — ArchUnit

아젠다 §11-4가 "커스텀 린트 규칙으로 grep 가능성·구조 예측성·아키텍처 경계를 강제하는 방식"을 물었다. **셋 중 아키텍처 경계에 대해서만 1차 자료를 찾았다.**

[ArchUnit 사용자 가이드](https://www.archunit.org/userguide/html/000_Index.html) — *"a free, simple and extensible library for checking the architecture of your Java code."* 바이트코드를 분석한다.

### 3.1 규칙이 테스트다

`@AnalyzeClasses`로 대상 패키지를 지정하고 `@ArchTest` 필드로 규칙을 선언한다. JUnit 4·5에 통합된다. **즉 아키텍처 규칙이 별도 도구가 아니라 테스트 스위트의 일부로 돈다.**

공식 문서가 드는 규칙 형태:

| API | 강제하는 것 |
|---|---|
| `classes().that().resideInAPackage("..service..").should().onlyBeAccessed().byAnyPackage(...)` | 접근 방향 |
| `noClasses().that().resideInAPackage("..source..").should().dependOnClassesThat().resideInAPackage("..foo..")` | 금지 의존 |
| `layeredArchitecture().layer("Controller").definedBy("..controller..")` | 계층 |
| `onionArchitecture().domainModels("com.myapp.domain.model..")` | 오니온 |
| `slices().matching("com.myapp.(*)..").should().beFreeOfCycles()` | 순환 |
| `methods().that().arePublic().should().beAnnotatedWith(Secured.class)` | 표기 규약 |

**마지막 항목이 §11-4의 "구조 예측성" 축에 가장 가깝다** — 이름·표기 규약을 실행 가능한 단언으로 만든다.

### 3.2 도입 곡선을 위한 기제 — 위반 동결

`FreezingArchRule`이 기존 위반 전량을 `ViolationStore`에 기록해 두고, *"consecutive runs will only report new violations and ignore known violations."*

**이것이 하네스 관점에서 가장 옮길 만한 아이디어다.** [강제 메커니즘 조사](enforcement-mechanisms.md)가 "차단 게이트 0개"를 실측했는데, 게이트를 새로 놓지 못하는 흔한 이유가 **켜는 순간 기존 자산이 전부 실패하는 것**이다. 동결은 그 문제를 정면으로 다룬다 — **기준선을 고정하고 신규 위반만 막는다.**

[평가 조사 §6.3](evaluation.md)이 확인한 `baseline.json`의 SHA 핀이 개념적으로 같은 역할이다. 저쪽은 "언제 마지막으로 통과했나", 이쪽은 "무엇을 이미 봐줬나"다.

### 3.3 자료의 한계

**ArchUnit은 Java 바이트코드 전용이다.** 참조 프로젝트가 Dart·TypeScript이므로 도구가 그대로 쓰이지 않는다. **이 절이 주는 것은 도구가 아니라 형태다** — 규칙을 테스트로 표현하고, 기존 위반을 동결하고, 계층·의존·표기를 단언으로 쓴다.

**"grep 가능성"에 대한 1차 자료는 찾지 못했다.** §6-4로 넘긴다.

---

## 4. 아젠다 §11-3의 규정을 점검한다

아젠다 §11-3은 *"저장소가 기록 원천이어야 하는 이유(강의 3) — 배포 조사 §1.2의 '**gitignore로 추적 파일 0건**'이 정확히 이 원칙의 위반이었다"* 고 적었다. **두 부분을 나눠 확인했다.**

### 4.1 배포 §1.2가 실제로 측정한 것

[배포 조사](harness-distribution.md) 본문을 다시 읽었다. 그 절의 관측은 이렇다.

> *"현행 배포의 핀은 gitignore 안에 있다. 추적되지 않는 핀은 버전 식별 기능을 하지 못한다"*
> *"`.gitignore` 통짜 무시 하에서는 `copier update`가 로컬 수정을 경고 없이 삭제한다"* — 실증. *"Copier의 3-way merge는 git 기계로 수행된다. 대상이 추적되지 않으면 병합 기준이 없어 단순 덮어쓰기로 퇴화한다."*

**측정된 것은 배포 메커니즘의 고장이다** — 버전 식별 불가, 3-way merge 무력화. 그리고 그 절의 결론이 *"gitignore 통짜 무시 제거는 정리 항목이 아니라 **동작 전제조건**"* 이다.

**"기록 원천 원칙의 위반"이라는 규범적 규정은 배포 조사가 한 말이 아니라 아젠다가 붙인 해석이다.** 두 진술이 같은 사실을 가리키지만 논거가 다르다 — 하나는 도구가 깨진다는 실증, 하나는 원칙에 어긋난다는 규범이다.

**실증 쪽이 더 강하다.** 원칙은 출처가 자가출판 강의(§4.2)이고, 실증은 재현된 실험이다.

### 4.2 "기록 원천" 원칙 자체의 출처

아젠다가 이 원칙의 근거로 든 것은 **강의 3(walkinglabs)** 하나다. [아젠다 §12 출처 감사](research-agenda.md)가 이미 *"자가출판 출처(walkinglabs) 의존은 … 그대로다"* 로 미해소를 명시했고, 부록이 *"강의 시리즈는 목차만 확인했다. 각 강의의 실제 주장은 미확인이다"* 라고 적었다.

**이 조사도 대체 자료를 찾지 못했다.** 다만 §1의 논문이 인접한 사실 하나를 준다 — 컨텍스트 파일이 **저장소 안 버전 관리 대상**이라는 전제 위에서 실험이 설계되어 있다. 이것은 "저장소가 기록 원천"을 지지하는 증거가 아니라 그 관행이 보편적이라는 관찰이다. **[평가 조사 §4.2](evaluation.md)가 인용한 Galster et al.의 90.6% 채택률이 같은 성격의 관찰이다.**

**즉 "저장소에 둔다"는 관행은 널리 확인되지만, "왜 그래야 하는가"의 1차 논거는 이 시리즈가 아직 확보하지 못했다.**

---

## 5. 적용 대상 확인 — 지금 무엇이 저장소에 있는가 (보조)

### 5.1 ADR은 0건이다

| 대상 | 결과 |
|---|---|
| 하네스 원본(`src/`) | `docs/` 자체가 없음. ADR 0 |
| 적용 프로젝트(cygnus) | `docs/` 아래 `_local`·`design`·`research`·`roadmap`·`specs`. **`decisions` 없음. ADR 0** |

`docs/specs/`에 18개 파일 **2,553줄**이 있다. 그런데 **결정 기록이 아니라 서술이다.** 대표 파일의 절 구성이 이렇다.

```
## 개요   ## 구조 / 스키마   ## 동작   ## 제약사항   ## 관련 문서
```

**§2.1의 MADR 필드와 대조하면 겹치는 것이 없다** — `Considered Options`도 `Decision Outcome`도 `status`도 없다. 즉 **"무엇인가"를 적고 "왜 그렇게 정했는가"를 적지 않는다.** §1.5의 분류로는 전부 **개요** 쪽이다.

> **단 이들은 상시 로드가 아니다.** §1의 실험 대상은 컨텍스트 파일이므로 이 2,553줄에 그 결과를 그대로 적용할 수 없다(§1.5 전이 범위 주의). **확인된 것은 "결정이 아니라 서술"이라는 종류의 문제이지 비용 손해가 아니다.**

### 5.2 상시 로드 계층의 내용 종류 — §1.3의 축으로 갈라 본다

[지시 계층 조사 §1.1](instruction-layers.md)이 상시 로드 **1,044줄 / 41,900바이트**를 실측했고, 그중 `harness-guide.md` 하나가 **377줄로 바이트의 55%**다. **이 조사는 그 377줄을 §1.3의 축(지시 vs 개요)으로 갈랐다.**

절별 줄 수 전량이다.

| 절 | 줄 | 분류(이 조사의 판단) |
|---|---:|---|
| `## graphify 사용 가이드` | 123 | **도구 지시** |
| `## Codex 스킬` | 72 | 혼합 (목록 + 호출법) |
| `## .claude/ 구조` | 45 | **개요** |
| `## dev-context.json 설정 키` | 21 | 도구 지시 |
| `## 개발 워크플로우` | 20 | 지시 |
| `## 에이전트` | 12 | **개요** |
| `## 문서 버전 관리` | 11 | 지시 |
| `## .harness/ 디렉토리` | 11 | **개요** |
| `## 컴포넌트 추가 방법` | 9 | 지시 |
| `## 자동화 훅` | 9 | **개요** |
| `## references/ 디렉토리` | 8 | **개요** |
| `## Codex CLI와의 차이점` | 8 | **개요** |
| `## 질문 처리 규칙` | 7 | 지시 |

**개요로 분류된 것이 93줄, 절 본문 합계의 약 26%다.**

**이 93줄이 상시 로드 체인 1,044줄의 약 9%에 해당한다.** [지시 계층 조사](instruction-layers.md)가 상시 로드 예산을 열린 질문으로 남겼는데, **§1이 이 부분에 관해서는 예산 논쟁 없이 답을 준다** — 개요형 서술은 줄여야 할 후보가 아니라 **효용이 확인되지 않은 항목**이다. 남은 판단은 크기가 아니라 종류다.

**그리고 단일 최대 절(123줄)이 `graphify 사용 가이드`인데, 이것은 §1.4에서 저자들이 유일하게 남기라고 한 범주다** — *"specific tooling to use with this repository."* **가장 큰 덩어리가 자료 기준으로는 정당화되는 종류라는 뜻이다.**

> **분류는 이 조사의 판단이다.** 논문이 절 단위 분류 기준을 주지 않는다(§6-1). `## Codex 스킬` 72줄처럼 목록과 호출법이 섞인 절이 있어 경계가 깔끔하지 않다. **26%라는 수치는 근사이지 측정값이 아니다.**

### 5.3 경계 강제는 없다

| 확인 | 결과 |
|---|---|
| 린트 설정 | Dart `analysis_options.yaml` 3개 (`apps/parent_app`, `apps/child_app`, `packages/app_core`) |
| import 제한·경계 규칙 | `no-restricted-imports`·`boundaries` 류 **0건** |
| ArchUnit류 아키텍처 테스트 | 없음 |

**§3의 형태에 해당하는 강제가 하나도 없다.** [강제 메커니즘 조사](enforcement-mechanisms.md)의 "차단 게이트 0개", [평가 조사 §6.2](evaluation.md)의 "grader 100% 코드 기반이나 대상 2종"과 같은 방향의 관측이다 — **검사 수단은 있고 경계는 선언되어 있지 않다.**

`.harness/contracts/` 5개(515줄)가 산출물 형식을 규정하지만, 이것은 **문서 형식 계약**이지 코드 경계가 아니다.

---

## 6. 자료가 답하지 않는 것

1. **"지시"와 "개요"의 조작적 경계**(§1.3, §5.2). **출처 감사(2026-08-02)에서 부분 해소 — §1.3.1 참고.** 논문이 **개요의 출현율은 집계한다**(개발자 작성 12개 중 8개, LLM 생성은 36~100%). **다만 전면적 분류 체계나 절·문단 단위 판정 기준은 여전히 없고, §5.2의 26%는 그 공백 위에 있다.**

   > **후속 (2026-08-03) — [컨텍스트 파일 내용 조사 §1.2·§5.1](context-file-content.md).** 판정 기준의 공백이 **논문 밖에서** 부분적으로 메워졌다. Claude Code 2.1.220의 **신규 `/init` 프롬프트**가 Include/Exclude를 항목 단위로 열거하며, Exclude에 *"File-by-file structure or component lists"* 와 **"Long tutorials or walkthroughs"** 가 함께 들어 있다. 이는 논문의 개요/지시 이분법보다 **한 칸 더 나눈 것**이다.
   > **그리고 §5.2의 26%가 독립적으로 재현되었다** — 그 조사가 같은 파일을 다섯 종류로 재분류해 개요 **26%**(93/356줄)를 얻었다. 다른 방법·다른 시점에 같은 값이므로 **26%는 그 조사가 말한 "공백 위"에 있으되 재현 가능한 값이다.**
   > **더 큰 발견은 개요가 최대 범주가 아니라는 것이다** — 튜토리얼·도구 walkthrough가 **55%(195줄)** 로 개요의 두 배이고, 행동 하드 제약은 **2%(7줄)** 에 불과하다.
2. **ADR을 상시 로드할 것인가 온디맨드로 둘 것인가**(§2.3). 형식은 표준이 있고 소비 도구는 없으며, 어느 쪽 배치가 나은지 말하는 자료가 없다.
3. **온디맨드 설명 문서에 §1의 결과가 전이되는가**(§1.5, §5.1). cygnus의 2,553줄이 여기 걸린다. 논문 대상이 컨텍스트 파일이라 직접 근거가 없다.
4. **"grep 가능성"을 강제하는 방법**(§3.3). 아젠다 §11-4의 세 축 중 하나인데 1차 자료를 찾지 못했다.
5. **"테스트가 문서보다 부패에 강하다"의 실증.** 코드-주석 불일치 대규모 연구(Wen et al., ICPC 2019)를 두 경로로 시도했으나 본문을 얻지 못했다(§부록). **§1이 부패를 거치지 않고 결론에 도달하므로 이 자료 없이 문서를 썼으나, 명제 자체는 미검증으로 남는다.**
6. **`FreezingArchRule` 방식이 하네스 규칙에 옮겨지는가**(§3.2). ArchUnit은 코드 대상이고 하네스 규칙은 산문이다. 동결할 "위반"을 무엇으로 셀지가 자료에 없다.
7. **저장소가 기록 원천이어야 하는 1차 논거**(§4.2). 관행의 보편성은 두 논문으로 확인되지만 원칙의 근거는 자가출판 출처 하나뿐이다.
8. **`docs/specs/` 같은 서술 문서를 무엇으로 대체하는가.** §2가 ADR을 결정 축의 대안으로 주지만, "이 모듈이 무엇을 하는가"를 대체하는 것은 자료가 말하지 않는다. **§1이 "빼라"고 하고 §2가 "다른 것을 넣어라"고 하지 않는다.**
9. **판본 차이.** §1은 v1 HTML을 읽었고 v2가 존재한다(§부록).

---

## 부록. 조사 방법 및 한계

**방법**

- WebFetch 10회 — Gloaguen et al. abs·**v2 abs**·**v1 HTML 본문 2회**(전체·§4.2 표적, v2 HTML은 404), adr.github.io, MADR, adr-tooling, ArchUnit 사용자 가이드, **Wen et al. 접근 시도 2회(둘 다 실패)**
- WebSearch 2회 — 자료 위치 파악용. **본문 근거로 쓰지 않았다**
- 실측(§5, 보조) — 하네스 `src/`와 cygnus의 `docs/` 구조, `docs/specs/` 규모와 절 구성, `harness-guide.md`의 절별 줄 수 집계, 린트 설정과 경계 규칙 문자열 검색

**한계**

- **§1의 세부 수치는 v1 HTML 본문에서 읽었다**(HTML 헤더가 `arXiv:2602.11988v1 [cs.SE] 12 Feb 2026`으로 확인된다). v2 HTML은 404다. **출처 감사에서 두 판본의 초록을 대조한 결과 비용 수치는 같고 성공률 표현이 약해졌다(§1.3.1-2).** 20%/23%·2.45/3.92단계·1.6회는 v1 본문 값이며 v2 본문에서 바뀌었는지는 확인하지 못했다. [평가 조사 §4.2](evaluation.md)에서 같은 종류의 프리프린트가 v1→v5로 세부 수치가 바뀐 사례를 확인했다.
- **Gloaguen et al.은 프리프린트다.** 벤치마크·에이전트·모델 조합이 명시되어 있으나 피어리뷰를 거치지 않았고 재현하지 않았다. **저자 소속은 arXiv 페이지에 기재가 없어 쓰지 않는다.**
- **`uv` 1.6회 vs 0.01회 미만은 단일 도구 사례다.** "지시는 따른다"의 일반화는 논문 문장(*"agents generally follow instructions"*)에 근거하고, 수치는 그 한 사례의 것이다.
- **Wen et al.(ICPC 2019)의 본문을 얻지 못했다.** 저자 배포본 URL이 404였고 Semantic Scholar 경로도 실패했다. **검색 요약에 "~75%" 라는 수치가 있었으나 무엇을 가리키는지 확인되지 않아 인용하지 않았다.** §6-5로 남겼다.
- **§5.2의 지시/개요 분류는 이 조사의 판단이며 논문 기준이 아니다**(§6-1). 절 단위로 갈랐고 혼합 절이 있다. **26%는 근사다.**
- **ArchUnit은 Java 전용이고 참조 프로젝트는 Dart·TypeScript다**(§3.3). 도구 자체가 아니라 형태를 인용했다.
- **ADR 도구 목록은 공식 페이지의 열거를 그대로 확인한 것이다.** "기계 소비용 파서가 없다"는 진술은 **그 목록 안에 없다**는 뜻이지 세상에 없다는 뜻이 아니다.
- **§4는 아젠다의 해석을 정정했지 배포 조사의 관측을 뒤집지 않았다.** 사실관계는 그대로이고, 그것을 "원칙 위반"으로 부를 근거가 배포 조사 안에 없다는 점만 짚었다.
- **§5는 결손이 아니라 종류를 확인했다.** ADR 0건은 결함이 아니다 — ADR을 쓰지 않기로 한 것일 수 있다. 관측된 것은 **결정과 근거를 담는 칸이 저장소에 없다**는 사실이며, 그것이 문제인지는 이 문서가 판정하지 않는다.
