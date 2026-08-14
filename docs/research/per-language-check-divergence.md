# 언어·플랫폼마다 제품이 달라지는 검사를 어떻게 다루는가 — 사례 조사

*Generated: 2026-08-03 | Adapter: adapter-exa(검색 12회) + adapter-firecrawl(원문 3회) | Failed: 1회(import-linter 계약 페이지 404 → 다른 경로로 해소)*

**최초 작성**: 2026-08-03
**최종 수정**: 2026-08-03

**대상 프로젝트**: grid fin (신규 개인용 개발 하네스)
**조사 계기**: *"순환참조 검사, 테스트 커버리지 등 언어 또는 플랫폼에 따라 명령어(제품)가 달라지는 것들은 어떻게 대응하는가"*
**성격**: 사례 조사. **어느 방식을 채택할지 결정하지 않는다.**

선행 문서
- [workflow-stack-separation.md](workflow-stack-separation.md) — **테스트**에 대해 같은 질문을 이미 다뤘다. 이 문서는 그 결론을 다시 유도하지 않는다
- [repository-layout.md](repository-layout.md) §9·§10 — 태스크 이름 계약, 러너 4종의 fail-open 실측
- [enforcement-mechanisms.md](enforcement-mechanisms.md) — 훅 층의 차단 지점

**이 문서가 닫는 선행 열린 질문 2건**
| 선행 질문 | 이 문서 | 결과 |
|---|---|---|
| workflow-stack-separation §9-3 — *공통 포맷 요구 vs 언어별 파서, 무엇이 싼가* | §4 | **둘 다 아닌 제3의 답이 출하돼 있다** — 선언적 파서 명세(reviewdog `errorformat`). 그리고 **이슈는 수렴했고 커버리지는 수렴하지 않았다** |
| 같은 문서 §9-7 — *루트 훅 디스패처가 모듈의 스택을 어디서 읽는가* | §6 | **두 진영이 있다** — 탐지(MegaLinter·trunk·Renovate·mise)와 선언(Nx·moon·pre-commit). 탐지 쪽이 무엇을 신호로 쓰는지 목록이 공개돼 있다 |

---

## Executive Summary

**테스트와 결론의 모양이 다르다.** 선행 조사에서 `test`는 **동사가 정규화되고 결과가 부분적으로만 정규화**됐다. 순환참조·커버리지 계열은 **동사부터 정규화되지 않는다.** 이유가 셋인데 전부 자료로 확인된다(§1).

1. **언어가 검사를 이미 흡수했다** — Go는 패키지 순환을 컴파일 툴체인이 거부하고, Cargo는 크레이트 순환을 거부한다. 반대로 **Java는 클래스 간 순환 참조가 언어 명세상 합법**이고, Rust도 **같은 크레이트 안 모듈끼리는 순환이 합법**이다. 즉 `check-cycles`는 어떤 언어에서는 **할 일이 없고** 어떤 언어에서는 **필수**다
2. **단위가 다르다** — 파일/모듈/패키지/크레이트/슬라이스. 같은 "순환 검사"라는 이름이 서로 다른 그래프를 잰다
3. **규칙이 사용자 저작이고 형식이 번역되지 않는다** — dependency-cruiser는 JSON, import-linter는 INI/TOML, **ArchUnit은 규칙이 설정이 아니라 Java 테스트 코드다**(§1.3)

**그래서 업계가 수렴한 곳은 "공통 명령"이 아니라 어댑터 3요소다**(§3) — **① 도구 서술자 ② 호출 모드 ③ 결과 스키마.** MegaLinter의 `descriptor.json` 스키마가 이 계약을 필드 단위로 노출하고 있어서, "어댑터에 무엇을 담아야 하는가"의 가장 구체적인 참조가 된다(§3.1).

**결과 정규화는 종류에 따라 성패가 갈렸다**(§4) — **이슈/진단은 SARIF로 수렴했다**(OASIS 표준, 2020). **커버리지는 수렴하지 않았다** — Codecov가 오늘도 언어별 파서 20종 이상을 유지하고, **Xcode의 `.xccov`는 아예 미지원 목록에 있다**(§4.2). 이것이 사용자가 말한 "플랫폼" 축의 가장 뾰족한 증거다.

**그리고 커버리지는 숫자 자체가 언어 간 비교 불가다**(§5) — JaCoCo는 **바이트코드 명령어**를 세고(합성 코드 포함), Go는 **문장**을, coverage.py는 문장(분기는 옵트인)을 센다. **따라서 전역 `≥80%` 게이트는 하나의 게이트가 아니다.** 임계값을 강제하는 곳도 넷으로 갈린다(§5.2) — 설정 파일(jest) / CLI 플래그(cargo-llvm-cov) / 별도 태스크(JaCoCo Gradle, **`check`에 안 붙는다**) / **없음(Go — 서드파티 도구가 그 빈 곳을 메운다)**.

> **가장 실무적인 관측**: **검사 부재의 세 종류가 전부 "통과"처럼 보인다**(§7) — ⓐ 이 언어에는 무의미(Go 순환) ⓑ 도구 미설치 ⓒ 도구는 있는데 파일 매칭이 0. **선행 조사가 러너 층에서 실측한 fail-open이 검사 층에서 그대로 재현되며**, MegaLinter 이슈 #2943이 ⓒ의 실사례다.

---

## 0. 조사 요약

| # | 관측 | 근거 | 등급 |
|---|---|---|---|
| 1 | **Go는 순환 import를 툴체인이 거부한다.** 명세가 처음엔 이를 명시하지 않아 구현만 강제하던 것을 이슈로 보강했다 | §1.1 | 1차(공식 이슈, golang/go#4976) |
| 2 | **Java는 정반대다** — JLS: *"Classes and interfaces declared in different ordinary compilation units can refer to each other, **circularly**. A Java compiler must arrange to compile all such classes at the same time."* | §1.1 | **1차(언어 명세)** |
| 3 | **같은 언어 안에서도 층에 따라 갈린다** — Rust는 **크레이트 순환 불가 / 모듈 순환 가능**, Java는 **클래스 순환 가능 / JPMS `requires` 순환은 resolution 에러** | §1.2 | 1차(공식 문서·포럼) |
| 4 | **ArchUnit은 규칙이 설정 파일이 아니라 Java 코드다** — `slices().matching("..myapp.(*)..").should().beFreeOfCycles()` 를 **단위 테스트로 실행**한다 | §1.3 | 1차(공식 User Guide) |
| 5 | **import-linter는 정반대로 순수 선언이다** — `setup.cfg`/`.importlinter`(INI) 또는 `pyproject.toml`(TOML)에 `[importlinter:contract:*]` 블록으로 계약을 적는다. **계약 타입의 이름 목록은 확인하지 못했다**(§8) | §1.3 | 1차(공식 설정 문서) |
| 6 | **dependency-cruiser는 JSON 규칙이고 순환이 조건 한 개다** — `"to": { "circular": true }`. **기본 severity가 `warn`이라 종료 코드가 0이다** | §1.3 | 1차(공식 rules-reference) |
| 7 | **Nx는 스스로 한계를 명시한다** — `@nx/enforce-module-boundaries`는 *"requires ESLint and only works for JavaScript/TypeScript projects"*. **언어 중립판은 별도 플러그인이고 Nx Enterprise 유료다** | §2.2 | **1차(공식)** |
| 8 | **MegaLinter의 descriptor 스키마가 어댑터 계약을 필드로 노출한다** — `cli_lint_mode`(file/list_of_files/project), `cli_lint_errors_count`(regex_number·regex_count·regex_sum·total_lines·**sarif**), `can_output_sarif`, `supported_platforms` | §3.1 | **1차(공식 JSON 스키마)** |
| 9 | **trunk.io도 같은 층에 같은 필드를 둔다** — `commands`(**필드 존재만 확인, 내부 규격 미확인**)·`direct_configs`(자동 활성화 신호)·`batch`·`runtime`/`download`·`known_bad_versions` | §3.2 | 1차(공식 필드 목록) |
| 10 | **Code Climate 엔진 명세가 가장 오래된 완성형 계약이다** — 도커 이미지 하나, `/code` 읽기 전용 마운트, `/config.json` 입력, **이슈 JSON을 STDOUT에 널 문자로 구분해 스트리밍**. 이미지 512MB·RSS 1GB 제한까지 규정 | §3.3 | 1차(공식 SPEC.md) |
| 11 | **reviewdog가 "언어별 파서를 코드로 짜지 않는" 제3의 답이다** — Vim `errorformat` 이식으로 **파서를 한 줄 선언(`%f:%l:%c: %m`)** 하고, 주요 도구는 사전 정의돼 있다. 자체 형식 RDFormat과 **SARIF·checkstyle 입력도 받는다** | §4.1 | 1차(공식 README) |
| 12 | **SonarQube는 "플러그인 없이 외부 도구를 받는" 경로를 규격화했다** — Generic issue import(JSON: `rules[]`+`issues[]`). **다만 그 규칙은 Rules 페이지에 뜨지 않고 품질 프로파일에도 안 잡힌다** | §4.1 | 1차(공식) |
| 13 | **이슈는 수렴했다** — SARIF 2.1.0은 OASIS 표준(2020-03-27)이고 명세가 스스로 *"an effective interchange format into which the output of any analysis tool can be converted"* 를 목표로 든다. Microsoft SARIF Multitool이 컨버터 15종을 내장 | §4.1 | **1차(OASIS 표준)** |
| 14 | **커버리지는 수렴하지 않았다** — Codecov가 xml/txt/json 계열 **파서 20종 이상**을 유지한다. **미지원 명시: `.xccov`(Xcode)·`.ec`/`.exec`·`.coverage`(Python)·`.html`** | §4.2 | **1차(벤더 공식)** |
| 15 | **커버리지 지표는 언어 간 비교 불가다** — JaCoCo는 **바이트코드 명령어**(C0)와 분기(C1)를 세고 *"synthetic code sometimes results in unexpected code coverage results"* 를 스스로 경고한다. Go는 **문장**, coverage.py는 문장(분기는 `--branch` 옵트인) | §5.1 | **1차(공식 3종)** |
| 16 | **임계값 강제 지점이 넷으로 갈린다** — jest `coverageThreshold`(설정), cargo-llvm-cov `--fail-under-lines`(플래그), JaCoCo Gradle `jacocoTestCoverageVerification`(**별도 태스크, `check`의 의존이 아님**), **Go: 공식 경로 없음 → 서드파티** | §5.2 | 1차(공식 4종) |
| 17 | **Xcode는 툴 자체가 다른 세계다** — 커버리지가 `.xcresult` 번들 안의 `xccovreport`/`xccovarchive`이고 `xccov`로만 읽는다. **텍스트 리포트가 아니라 번들이다** | §5.3 | 1차(man page) |
| 18 | **탐지 진영의 신호가 공개돼 있다** — MegaLinter: 확장자·파일명 정규식·**파일 내용 정규식**·설정파일 존재. trunk: `direct_configs`. mise: 언어별 idiomatic version file 표(`.nvmrc`, `go.mod`, `rust-toolchain.toml` …). Renovate: manager가 package file을 매칭 | §6.1 | 1차(공식 4종) |
| 19 | **Renovate가 이 문제의 가장 큰 규모 사례다** — manager(추출) / datasource(버전 질의) / versioning(비교)의 3분할로 **90+ 생태계·80+ 데이터소스**를 하나의 워크플로우로 돌린다 | §6.2 | 2차(DeepWiki) + 1차(기여 문서) |
| 20 | **파일 매칭 0이 조용한 통과로 나타난 실사례가 있다** — MegaLinter #2943: 필터가 아무 파일도 못 잡아 **project 모드 린터만 실행**되고 요약표는 전부 ✅ | §7.2 | 1차(공식 이슈) |

### 근거 등급

| 등급 | 뜻 |
|---|---|
| **1차(표준·언어 명세)** | OASIS SARIF, Go spec/이슈, JLS |
| **1차(공식 문서)** | 도구 벤더의 문서·JSON 스키마·man page |
| 2차 | DeepWiki 등 유도 문서. 이 조사에서는 Renovate 아키텍처 서술 1건뿐이고 기여 문서로 교차 확인함 |
| **미확인** | §8에 따로 적는다 |

---

## 1. 왜 이 계열은 동사부터 갈라지는가

선행 조사에서 `test`는 **모든 언어에 존재하는 동사**였다. 순환참조는 그렇지 않다.

### 1.1 언어가 이미 흡수한 경우 — 검사가 할 일이 없다

| 언어 | 패키지/크레이트 수준 순환 | 근거 |
|---|---|---|
| **Go** | **불가** — 툴체인이 거부 | [golang/go#4976](https://github.com/golang/go/issues/4976) |
| **Rust** | **불가** — Cargo가 거부 | 공식 포럼: *"Cyclic dependencies between crates are not supported"* |
| **Java (JPMS)** | **불가** — resolution이 *"a cycle in the 'requires' directives"* 로 에러 | `java.lang.module` 패키지 명세 |
| **Java (클래스·패키지)** | **가능** | JLS §7 |

Go의 경위가 흥미롭다. `#4976`에서 Rob Pike가 *"The spec doesn't say this, although the implementations enforce it"* 로 이슈를 열었고, 결론은 **명세 문구 보강**이었다(Go 1.1 마일스톤, 2014 종료). 스레드에는 *"gc 컴파일러가 아니라 링커가 잡는다"* 는 재현도 남아 있으나 **2013년 `6g`/`6l` 기준이고 현행 `go build`에서 어느 단계가 잡는지는 이 조사에서 확인하지 않았다.** 하네스 관점에서 중요한 것은 단계가 아니라 **빌드가 거부된다는 사실**이다.

> **여기서 이미 하네스 함의가 하나 나온다** — Go 저장소에 `check-cycles` 태스크를 두면 **정상 동작이 no-op이다.** 그리고 §7의 관점에서 그 no-op은 **"도구가 없어서 건너뛴 것"과 구분되지 않는다.**

### 1.2 층에 따라 답이 뒤집힌다

**Rust**: 크레이트 순환은 불가, **같은 크레이트 안의 모듈 순환은 정상이다.** 공식 포럼 답변이 이 대비를 명시적으로 설계 의도로 설명한다.

> *"If you want to have cyclic dependencies, you put the entire cycle in a single crate. If you don't need cyclic dependencies, then you can put your code into different crates and enjoy the benefits of separate compilation."*

**Java**: JLS §7이 클래스 간 순환을 명시적으로 허용한다.

> *"Classes and interfaces declared in different ordinary compilation units can refer to each other, circularly. A Java compiler must arrange to compile all such classes and interfaces at the same time."*

그런데 **같은 언어의 JPMS 층에서는 `requires` 순환이 resolution 실패다.** 즉 "Java에서 순환이 허용되는가"라는 질문에 층을 명시하지 않으면 답이 없다.

**JS/TS**: 순환이 런타임까지 허용되고, 그래서 **검사 도구가 가장 많이 발달한 언어**가 됐다(madge, dependency-cruiser).

> **따라서 `check-cycles`라는 이름 하나가 최소 다섯 개의 서로 다른 술어를 덮는다** — 파일 순환 / 모듈 순환 / 패키지 순환 / 크레이트 순환 / 아키텍처 슬라이스 순환. **선행 조사의 "이름 계약"이 여기서는 성립하지 않는다.** 이름이 같아도 같은 것을 재지 않기 때문이다.

### 1.3 규칙 표현 형식이 번역되지 않는다 — 그리고 한쪽은 아예 코드다

| 도구 | 언어 | 규칙을 어디에 쓰는가 | 순환 검사 표현 |
|---|---|---|---|
| **madge** | JS/TS/CSS 전처리기 | 없음(CLI 플래그) | `madge --circular src/app.js` |
| **dependency-cruiser** | JS/TS/CoffeeScript | **JSON 또는 JS 객체** | `{"name":"no-circular","severity":"warn","from":{...},"to":{"circular":true}}` |
| **import-linter** | Python | **INI(`setup.cfg`·`.importlinter`) 또는 TOML(`pyproject.toml`)** | `[importlinter:contract:one]` + `type = ...` |
| **ArchUnit** | Java(바이트코드) | **Java 테스트 코드** | `slices().matching("..myapp.(*)..").should().beFreeOfCycles()` |
| **Nx ESLint 규칙** | JS/TS **전용** | ESLint 설정 | `@nx/enforce-module-boundaries` |

**ArchUnit이 이 표에서 가장 중요하다.** 공식 User Guide가 *"using any plain Java unit testing framework"* 로 소개하고, 규칙 문법이 fluent API다. 사이클 탐지 파라미터만 `archunit.properties`로 뺐다.

> **이것은 "검사를 선언적 설정으로 끌어올린다"는 접근의 가장 강한 반례다.** ArchUnit 규칙을 하네스가 설정으로 표현하려면 **자바 코드 생성기를 갖는 수밖에 없다.** 그리고 그 규칙은 `test` 태스크 안에서 실행되므로, **선행 조사가 정규화한 JUnit XML 판정 3값 안으로 자동으로 들어온다** — 하네스 입장에서는 순환 검사가 아니라 그냥 테스트다.
>
> **역으로 dependency-cruiser는 기본 severity가 `warn`이라 종료 코드가 0이다**(공식 문서: *"The 'error' severity will make some reporters … return a non-zero exit code"*). **게이트로 쓰려면 규칙마다 `severity: error`를 명시해야 한다.** 같은 "순환 검사"가 한쪽은 테스트 실패로, 한쪽은 침묵으로 나타난다.

---

## 2. 그래서 실제 제품들은 무엇을 포기했는가

### 2.1 세 가지 전략

| 전략 | 무엇을 통일하는가 | 사례 |
|---|---|---|
| **A. 기반을 통일한다** | 코드를 공통 표현으로 바꾸고 규칙 엔진을 하나 둔다 | CodeQL, Semgrep(언어별 파서 + 공통 규칙 문법) |
| **B. 결과만 통일한다** | 도구는 그대로 두고 출력 스키마만 맞춘다 | SARIF, reviewdog RDFormat, Code Climate 이슈 JSON, SonarQube generic import |
| **C. 호출을 통일한다** | 도구별 서술자를 두고 러너가 디스패치한다 | MegaLinter, trunk.io, pre-commit, Nx executor, Renovate manager |

**실제로 출하된 애그리게이터는 전부 B+C의 조합이다.** A는 도구 자체를 새로 만드는 길이고, 이 조사에서 개인 하네스가 지불할 수 있는 값이 아니다.

### 2.2 Nx가 자기 한계를 문서에 적어 뒀다

`@nx/enforce-module-boundaries` 공식 페이지의 주석이 이 조사 전체를 요약한다.

> *"This rule requires ESLint and **only works for JavaScript/TypeScript projects**. For **language-agnostic** boundary enforcement across all project dependencies, see the Conformance plugin's Enforce Project Boundaries rule."*

그리고 [Conformance 페이지](https://nx.dev/docs/enterprise/conformance)를 받아 확인한 결과:

- 규칙을 **TypeScript로 작성**하고 *"enforce your organization's standards across **any language or technology**"* 를 표방한다
- 사전 제공 규칙에 **Enforce Project Boundaries**가 있고, ESLint판과 달리 *"enforces the boundaries on **every project dependency**, not just those created from TypeScript imports or `package.json` dependencies"*
- **`@nx/conformance` 플러그인은 Nx Enterprise 플랜을 요구한다.** 문서 원문: *"If a valid license is not available to the workspace … the `conformance` and `conformance:check` commands will **fail without checking any rules**"*

> **두 가지가 동시에 읽힌다.** ① 언어 중립 경계 검사를 하려면 **소스 import가 아니라 프로젝트 그래프**를 봐야 한다는 설계 답이 있다. ② 그런데 **성숙한 상용 제품조차 그것을 무료 계층에 두지 않았다.** 이 조사가 찾은 "언어 중립 순환/경계 검사"의 유일한 완성형이 유료 라이선스 뒤에 있다는 사실 자체가, 이 문제의 난이도에 대한 간접 증거다.
>
> **그리고 마지막 인용문이 §7의 실패 모드와 반대 방향이라는 점이 중요하다** — 라이선스가 없으면 **조용히 통과하는 게 아니라 실패한다.** 검사 부재를 통과로 처리하지 않는 설계가 실재한다는 뜻이다.

---

## 3. 어댑터 계약의 실물 — 세 제품이 무엇을 필드로 뒀는가

### 3.1 MegaLinter `descriptor` 스키마 — 가장 상세한 공개 계약

[공식 JSON 스키마](https://megalinter.io/latest/json-schemas/descriptor.html) 원문 확인(2,700여 줄). 이 조사에 직접 쓸 필드만 추린다.

**(가) 무엇에 대한 어댑터인가**

| 필드 | 값 |
|---|---|
| `descriptor_type` (필수) | `language` / `format` / `tooling_format` / `other` |

> **"언어"가 축의 전부가 아니라는 것을 스키마가 인정하고 있다.** 사용자 질문의 "언어 또는 플랫폼"과 같은 문제의식이다.

**(나) 언제 활성화되는가** — §6.1에서 다시 다룬다

`file_extensions` / `file_names_regex` / `file_names_not_ends_with` / **`file_contains_regex`** / `active_only_if_file_found` / `activation_rules`

**(다) 어떻게 부르는가**

| 필드 | 뜻 |
|---|---|
| **`cli_lint_mode`** | **`file` / `list_of_files` / `project`** (기본 `file`) |
| `files_separator` | 파일 목록을 넘길 때의 구분자 |
| `cli_config_arg_name`, `cli_lint_extra_args`, `cli_lint_fix_arg_name`, `cli_lint_ignore_arg_name` | 인자 이름의 도구별 차이를 흡수 |
| `cli_lint_mode_{file,list_of_files,project}_extra_args_after` | **같은 도구도 모드마다 인자가 다르다** |

> **`cli_lint_mode` 3값이 이 조사의 핵심 발견 중 하나다.** 순환참조 검사는 본질적으로 `project` 모드다(그래프 전체를 봐야 한다). 커버리지도 `project`다. 반면 포매터·린터 다수는 `file`이다. **"변경된 파일만 검사"라는 흔한 최적화가 이 계열에는 적용되지 않는다**는 뜻이고, 이는 하네스의 훅 설계(변경 파일 기준 `PostToolUse`)와 직접 충돌한다.

**(라) 결과를 어떻게 읽는가**

| 필드 | 값 |
|---|---|
| **`cli_lint_errors_count`** | **`regex_number` / `regex_count` / `regex_sum` / `total_lines` / `sarif`** |
| `cli_lint_errors_regex` | 예: `"Issues found: (.*) in .* files"` |
| `can_output_sarif` | 기본 `false` |
| `cli_sarif_args` | 예: `["--format","sarif","--output","{{SARIF_OUTPUT_FILE}}"]` |

> **성숙한 애그리게이터가 오늘도 정규식으로 에러 개수를 센다.** SARIF는 **선택지 다섯 개 중 하나**이고 `can_output_sarif`의 기본값이 `false`다. §4의 "이슈는 수렴했다"를 여기서 한 번 깎아야 한다 — **표준은 존재하지만 채택은 도구별이고, 애그리게이터는 미채택 도구를 위한 정규식 경로를 계속 유지한다.**

**(마) 설치와 플랫폼**

`install`이 `apk`/`cargo`/`dockerfile`/`gem`/`npm`/`pip`로 나뉘고, **`supported_platforms`가 `linux/amd64`·`linux/arm64` 등 도커 아키텍처 표기를 쓰며 플랫폼별 `install_override`까지 받는다.**

> **pre-commit의 `language:`(선행 조사 §5.3)와 같은 성격인데 더 나아갔다** — 설치 방법이 6종으로 나뉘고, **CPU 아키텍처마다 설치 절차가 달라질 수 있음을 스키마가 인정한다**(실제 예시가 arm64용 shellcheck 별도 설치다).

### 3.2 trunk.io `lint.definitions` — 같은 층, 다른 강조

[공식 문서](https://docs.trunk.io/code-quality/overview/getting-started/configuration/lint/definitions.md) 확인. MegaLinter와 겹치지 않는 필드만.

| 필드 | 뜻 | 이 조사에서의 의미 |
|---|---|---|
| **`direct_configs`** | *"config files used to auto-enable the linter"* | **탐지 신호를 명시적 필드로 뒀다**(§6.1) |
| `batch` | 여러 파일을 한 번에 실행 | `cli_lint_mode`와 같은 축 |
| `runtime` + `package` **또는** `download` | *"You must provide either runtime + packages or download, not both"* | 설치 경로가 배타적 |
| **`known_bad_versions`** / `known_good_version` | 깨진 버전 목록, 폴백 | **어댑터가 버전 회귀까지 흡수한다** |
| `affects_cache` | 캐시 무효화 파일 목록 | |
| `formatter` | `trunk fmt`에 포함할지 | 검사/수정의 분리 |
| `hold_the_line` | 기존 위반 동결 | 선행 조사의 ArchUnit `FreezingArchRule`과 같은 발상 |

### 3.3 Code Climate 엔진 명세 — 가장 오래된 완성형

[codeclimate/platform `spec/analyzers/SPEC.md`](https://github.com/codeclimate/platform/blob/master/spec/analyzers/SPEC.md). 지금은 qlty로 이어졌지만 **계약이 문서로 고정돼 있다는 점에서 참조 가치가 크다.**

> *"A Code Climate engine is a standalone program which accepts a configuration and source code, and returns static analysis results. It can be implemented in **any programming language**, and is distributed as a Docker image."*

| 축 | 규정 |
|---|---|
| 입력 | `/code`(읽기 전용 마운트) + `/config.json`(읽기 전용) |
| **출력** | **이슈 JSON을 STDOUT에 스트리밍, 각 이슈를 널 문자(`\0`)로 종료** |
| 메타데이터 | `/engine.json` — `name`·`description`·`maintainer`·**`languages[]`**·`version`·`spec_version` |
| 이슈 스키마 | `type`·`check_name`·`description`·`categories[]`·`location`·`remediation_points`·`severity`(info/minor/major/critical/blocker)·**`fingerprint`** |
| 자원 한도 | 이미지 512MB, RSS 1GB, **네트워크 차단(`--net=none`)** |
| 패키징 | UID/GID 9000의 `app` 유저, `WORKDIR /code`, `EXPOSE`·`ONBUILD` 금지 |

> **두 가지가 하네스 설계에 직접 쓰인다.** ① **`fingerprint`** — 같은 이슈를 실행 간에 동일 식별하는 필드. [선행 오류 재발 방지 조사](error-recurrence-prevention.md)가 다룬 "같은 지적이 반복되는가"를 재려면 필요한 바로 그 필드다. ② **네트워크 차단이 계약에 들어 있다** — [보안 조사](security.md)의 설계 패턴이 검사 도구 계약 층에 이미 반영된 사례다.

---

## 4. 결과 정규화 — 이슈는 수렴했고 커버리지는 수렴하지 않았다

### 4.1 이슈/진단: 표준이 있고, 표준으로 가는 우회로도 있다

**(가) SARIF 2.1.0 — OASIS 표준(2020-03-27)**

명세 서문이 목표를 두 갈래로 적는다.

> *"Be a useful format for analysis tools to **emit directly**, and also an effective **interchange format into which the output of any analysis tool can be converted**."*

이 이중 목표가 생태계 모양을 설명한다. 직접 방출하는 도구가 늘었지만, **변환기 계층이 계속 필요하다.** Microsoft SARIF Multitool이 내장 컨버터 15종을 유지한다(AndroidStudio, ClangTidy, CppCheck, Fortify, FxCop, Pylint, TSLint …).

**(나) reviewdog `errorformat` — 선행 조사 §9-3에 대한 제3의 답**

선행 조사는 결과 정규화의 선택지를 둘로 봤다: **(가) 공통 포맷을 요구**하거나 **(나) 언어별 파서를 코드로 짜거나**(SWE-bench). **reviewdog는 셋째를 보여준다 — 파서를 코드가 아니라 한 줄 선언으로 쓴다.**

> *"reviewdog accepts any compiler or linter result from stdin and parses it with scan-f like **'errorformat'**, which is the port of Vim's errorformat feature."*
> *"if the result format is `{file}:{line number}:{column number}: {message}`, errorformat should be `%f:%l:%c: %m`"*

그리고 **주요 도구는 사전 정의돼 있어 대개 쓸 필요조차 없다**(`reviewdog -list`). 설정은 도구별 한 블록이다:

```yaml
runner:
  golint:
    cmd: golint ./...
    errorformat: ["%f:%l:%c: %m"]
    level: warning
  your-awesome-linter:
    cmd: awesome-linter run
    format: rdjson
```

**입력 형식은 넷을 받는다** — `errorformat` / RDFormat(`rdjson`·`rdjsonl`) / checkstyle / **SARIF**.

> **비용 구조가 SWE-bench의 언어별 파서와 다르다.** 파서가 **저장소의 코드가 아니라 설정 한 줄**이 되고, 그 한 줄조차 흔한 도구에는 이미 있다. **다만 이것은 "파일:줄:열: 메시지" 형태로 출력하는 도구에만 통한다** — §5의 커버리지처럼 **집계 수치**를 내는 도구에는 적용되지 않는다.

**(다) SonarQube generic issue import — "플러그인 없이 받는다"**

`sonar.externalIssuesReportPaths`에 JSON(`rules[]` + `issues[]`)을 넘기면 플러그인 없이 외부 도구 결과를 받는다. **대가가 문서에 명시돼 있다:**

> *"the rules corresponding to these issues **will not be visible on the Rules page nor reflected in quality profiles**. This means that the rules that raise external issues **must be managed in your third-party tool**."*

> **어댑터 경로는 일급 시민이 아니다.** 결과는 들어오지만 거버넌스(규칙 관리)는 밖에 남는다. 하네스가 "외부 도구 결과를 받는 창구"를 만들 때 같은 비대칭이 생길 것을 예고한다.

### 4.2 커버리지: 표준이 없고, 벤더가 파서 20종을 유지한다

[Codecov 공식 문서](https://docs.codecov.com/docs/supported-report-formats) 원문.

> *"Codecov centrally ingests `.xml`, `.json` and `.txt` type coverage report formats. **If your language / test suite does not generate one of these format coverage reports, you may need to add a conversion step to your build process.**"*

문서가 프로세서 목록을 **소스 코드 그대로** 공개한다:

| 계열 | 프로세서 |
|---|---|
| XML | Bullseye(C++, **함수 커버리지만**), Clover(PHP), Cobertura, CSharp, **Jacoco**, JetBrains, Mono, SCoverage(Scala), Vb, VbTwo |
| TXT | DLST, Gap, **Gcov**, **Go**, **Lcov**, Lua, **XCode** |
| JSON | Coveralls, Elm, Flowcover, Gap, Node, Rlang, Rspec, Salesforce, Scala, VOne |

**그리고 미지원 목록이 명시돼 있다** — **`.xccov`(Xcode)**, `.ec`/`.exec`(JaCoCo 실행 데이터), `.coverage`(Python), `.html`.

> **이것이 "플랫폼" 축의 가장 뾰족한 증거다.** iOS 프로젝트는 `xccov`가 내는 네이티브 산출물을 그대로 올릴 수 없고, **변환 단계를 하나 더 끼워야 한다**(§5.3).
>
> **그리고 미지원 목록의 나머지가 같은 방향을 가리킨다** — `.ec`/`.exec`와 `.coverage`는 **바이너리 중간 산출물**이다. 커버리지 도구들은 대개 ⓐ 실행 데이터(바이너리) → ⓑ 리포트(XML/텍스트) 2단계를 거치는데, **정규화가 가능한 지점은 ⓑ뿐이다.** 즉 커버리지는 테스트와 달리 **리포트 생성 명령이 한 단계 더 있고, 그 단계가 도구마다 따로 있다.**

**변환기 생태계도 그만큼 크다** — `gocover-cobertura`(Go→Cobertura), `simplecov-lcov`/`simplecov-cobertura`(Ruby: Codecov가 **SimpleCov JSON 대신 이쪽을 권장**한다), `cargo-llvm-cov --lcov|--cobertura`, `gcovr --cobertura`.

> **선행 조사 §9-3의 질문("공통 포맷 요구 vs 언어별 파서")에 대한 답이 검사 종류마다 다르다.** 이슈는 표준이 생겼고(SARIF), **커버리지는 표준화 시도 자체가 없다** — LCOV·Cobertura·JaCoCo XML이 사실상 표준 셋으로 공존하고 벤더가 전부 받는 쪽을 택했다.

---

## 5. 커버리지의 더 깊은 문제 — 숫자가 같은 것을 재지 않는다

포맷을 통일해도 남는 문제다.

### 5.1 무엇을 세는가가 다르다

| 런타임 | 기본 단위 | 근거 |
|---|---|---|
| **JaCoCo** | **바이트코드 명령어**(C0). 추가로 분기(C1)·라인·메서드·클래스·순환 복잡도 | 공식 counters 문서 |
| **Go** | **문장(statements)** — `go tool covdata percent` 출력이 `coverage: 78.4% **of statements**` | 공식 build-cover 문서 |
| **coverage.py** | **문장**. 분기는 `--branch` **옵트인** | 공식 FAQ·branch 문서 |
| **cargo-llvm-cov** | 라인·리전·함수. **분기는 unstable** | 공식 README |

**JaCoCo 문서가 스스로 경고한다:**

> *"Not all Java language constructs can be directly compiled to corresponding byte code. In such cases the Java compiler creates so called **synthetic code** which sometimes results in **unexpected code coverage results**."*

그래서 필터 목록이 따로 관리되고(0.8.0부터 무조건 적용), *"tools that directly read exec files … will provide filtering functionality only after they updated to this version"* 라는 단서까지 붙는다 — **같은 JaCoCo 데이터라도 읽는 도구의 버전에 따라 숫자가 달라진다.**

**coverage.py는 분기 켜면 계산식이 바뀐다는 것을 명시한다:**

> *"Each line in the file is an execution opportunity, as is each branch destination."*
> 그리고 *"A branch line that wasn't executed at all is counted **once as a missing statement** … instead of as two missing branches"*

> **결론: 전역 `≥80%` 게이트는 하나의 게이트가 아니다.** Java 80%(바이트코드 명령어, 합성 코드 필터 적용 후) · Go 80%(문장) · Python 80%(문장, 분기 미포함)는 서로 다른 엄격도다. **[평가 조사](evaluation.md)가 지적한 "무엇을 재는지 정하지 않으면 수치가 비교 불가"가 커버리지에서 그대로 재현된다.**
>
> **더 나아가 Go에는 커버리지가 아예 사라지는 조건이 문서화돼 있다** — *"If a program terminates in an unrecovered panic … profile data from statements executed during the run **will be lost**."* 선행 조사 §4.3의 "낡은 리포트를 읽는다"와 같은 계열의 결손이다.

### 5.2 임계값을 강제하는 곳이 넷이다

| 런타임 | 강제 수단 | 형태 |
|---|---|---|
| **jest** | `coverageThreshold` | **설정 파일**. `global` + glob/경로별. 음수는 "미커버 허용 개수" |
| **cargo-llvm-cov** | `--fail-under-lines` / `-functions` / `-regions`, `--fail-uncovered-lines` 등 | **CLI 플래그**(6종) |
| **coverage.py / pytest-cov** | `fail_under` / `--cov-fail-under` | 설정 또는 플래그 |
| **JaCoCo (Gradle)** | `jacocoTestCoverageVerification` + `violationRules` | **별도 태스크** |
| **Go** | **공식 경로 없음** | 서드파티(`go-test-coverage`: `threshold.file`/`package`/`total` + 경로별 override + **base 브랜치 대비 diff 임계값**) |

**JaCoCo Gradle의 단서가 특히 중요하다:**

> *"The `JacocoCoverageVerification` task is **not a task dependency of the `check` task** provided by the Java plugin. There is a good reason for it. The task is currently not incremental…"*
> *"JaCoCo only reports the **first violated rule**."*

> **`check`를 돌려도 커버리지 게이트가 안 돈다.** 선행 조사가 실측한 "러너가 부분 부재를 exit 0으로 통과시킨다"와 **정확히 같은 형태의 fail-open이 프레임워크 기본값에 박혀 있다.** 그리고 위반을 하나만 보고한다 — 반복 수정 루프를 도는 에이전트에게는 **한 번에 하나씩만 알려주는** 피드백이다.
>
> **Go의 빈칸이 그 반대편 사례다** — 공식 도구가 임계값을 제공하지 않으니 서드파티가 그 빈 곳을 채웠고, 그 서드파티가 **jest에도 JaCoCo에도 없는 기능(base 브랜치 대비 diff 임계값)을 갖는다.** 즉 "언어마다 도구가 다르다"는 단순히 이름 차이가 아니라 **기능 집합이 서로 포함관계가 아니라는** 뜻이다.

### 5.3 플랫폼 축 — Xcode는 파일이 아니라 번들이다

[`xccov(1)` man page](https://keith.github.io/xcode-man-pages/xccov.1.html) 확인.

| 축 | Xcode |
|---|---|
| 산출물 | **`.xcresult` 번들** 안의 `xccovreport`(퍼센트) + `xccovarchive`(원시 실행 횟수) |
| 읽는 법 | `xccov view --report [--json] result_bundle.xcresult` |
| 경로 | UI 실행 시 DerivedData의 `Logs/Test`, `xcodebuild`는 `-resultBundlePath` |
| 고유 연산 | **`xccov diff`**(두 리포트 비교), **`xccov merge`**(집계) |
| 주의 | 병합 시 *"the aggregate report **may be inaccurate** for source files that changed in between"* |
| 경로 처리 | **`--path-equivalence`** — 리포트 생성 시점의 경로와 현재 경로가 다를 수 있어 매핑 옵션이 필요 |

> **세 가지가 언어 축에서는 나오지 않는 문제다.** ① 산출물이 **디렉터리 번들**이라 "리포트 파일 하나"를 전제한 하네스가 안 맞는다. ② **경로가 생성 시점 기준으로 박혀 있어** 워크트리를 옮기면 매핑이 필요하다 — [워크트리 공유 상태 조사](worktree-shared-state.md)와 직접 겹친다. ③ **Codecov 미지원 형식이다**(§4.2). 변환기(`slather`·`xcov` 등)가 별도 생태계로 존재하는 이유다.

---

## 6. 탐지인가 선언인가 — 선행 §9-7의 답

선행 조사가 *"루트 훅 디스패처가 모듈의 스택을 어디서 읽는가"* 를 열어 뒀다. **실제 제품은 두 진영으로 갈리고, 탐지 진영은 신호 목록을 공개해 뒀다.**

### 6.1 탐지 진영 — 무엇을 보고 판단하는가

| 제품 | 탐지 신호 |
|---|---|
| **MegaLinter** | `file_extensions` · `file_names_regex` · `file_names_not_ends_with` · **`file_contains_regex`**(+ 적용 확장자) · `active_only_if_file_found`(*"Search in workspace, linter rules path, and files sub directory"*) · `activation_rules` |
| **trunk.io** | **`direct_configs`** — *"config files used to auto-enable the linter"* |
| **mise** | **언어별 idiomatic version file 표** — `node: .nvmrc/.node-version/package.json`, `go: .go-version/go.mod`, `rust: rust-toolchain.toml`, `java: .java-version/.sdkmanrc`, `python: .python-version`, `ruby: .ruby-version/Gemfile`, `swift: .swift-version` … |
| **Renovate** | manager가 package file을 매칭 (`package.json`, `pom.xml`, `Dockerfile` …) |
| **super-linter** | *"super-linter runs **all supported linters by default**"* — 탐지라기보다 전량 실행 후 파일 필터 |

**mise의 표가 특히 실무적이다.** *"These are ideal for setting the runtime version of a project **without forcing other developers to use a specific tool** like mise or asdf"* — **탐지 신호를 자기 형식이 아니라 생태계의 기존 관습 파일로 잡는다.** 그리고 대가도 문서에 있다: *"There is a performance cost to discovering and [parsing them]"*, 그래서 **기본 비활성이고 `idiomatic_version_file_enable_tools`로 켠다.**

`go.mod`의 해석 규칙도 적혀 있다 — `toolchain goX.Y.Z`가 있으면 정확 핀, 없으면 `go X.Y`를 **최소 버전으로 보고 최신 패치로 해소**한다. **같은 파일에서 두 종류의 의미를 읽는다.**

### 6.2 선언 진영과 Renovate의 3분할

선언 진영은 선행 조사가 이미 다뤘다 — Nx `project.json` `targets`, `moon.yml`, `.pre-commit-config.yaml`의 `language:`.

**Renovate가 이 문제의 최대 규모 사례다.** manager(추출) / datasource(버전 질의) / versioning(비교 규칙: SemVer, PEP 440 …)의 **3분할로 90+ 생태계·80+ 데이터소스**를 하나의 워크플로우로 돌린다.

기여 문서에서 확인되는 계약:

| 인터페이스 | 메서드 | 역할 |
|---|---|---|
| `ManagerApi` | `extractPackageFile()` | 파일 내용을 파싱해 의존성 추출 |
| `ManagerApi` | `updateDependency()` | 새 버전을 반영해 파일 수정 |
| `DatasourceApi` | `getReleases()` | 레지스트리 질의 |
| `DatasourceApi` | `getDigest()` | 콘텐츠 해시 |

**그리고 예외 처리가 흥미롭다** — 대부분의 manager는 파일을 **병렬로** 처리하지만, npm/Yarn처럼 `package.json`과 락파일을 **함께 봐야 하는** 경우를 위해 `extractAllPackageFiles()`(직렬)를 따로 뒀다.

> **어댑터 인터페이스가 하나로 안 끝난다는 사례다.** 개별 처리 가능한 도구와 전역 처리가 필요한 도구가 섞이면 **인터페이스를 두 개 둬야 한다.** MegaLinter의 `cli_lint_mode`(file / list_of_files / project) 3값이 같은 문제의 다른 표현이다.
>
> **그리고 이 조사의 두 계열이 정확히 그 경계 양쪽에 있다** — 린터·포매터는 `file`, **순환참조와 커버리지는 `project`다.**

---

## 7. 검사 부재는 세 종류이고 전부 통과처럼 보인다

### 7.1 세 종류

| 종류 | 예 | 하네스가 받는 신호 |
|---|---|---|
| **ⓐ 이 언어/층에서 무의미** | Go 패키지 순환(§1.1) | 검사 자체가 없음 |
| **ⓑ 도구 미설치** | 저장소에 dependency-cruiser 미설치 | 명령 없음 / 스킵 |
| **ⓒ 도구는 있는데 대상이 0** | 필터가 아무 파일도 못 잡음 | **exit 0 + "성공"** |

**ⓐ와 ⓑ의 구분이 특히 중요하다.** ⓐ는 정상이고 ⓑ는 결손인데, **명령의 부재로는 둘이 같다.**

> **주의 — 여기서 하나의 전제를 쓴다.** *"강제하지 않고 우아하게 저하한다"* 는 **사용자가 구두로 밝힌 개발환경 전제**이고 이 저장소의 문서에는 아직 없다. 그 전제에서 보면 ⓑ는 통과시켜도 되지만, **그것이 ⓑ와 ⓐ를 구분하지 말자는 뜻은 아니다** — ⓐ는 검사할 것이 없는 상태이고 ⓑ는 검사하지 못한 상태다.

### 7.2 ⓒ의 실사례

MegaLinter 이슈 [#2943](https://github.com/oxsecurity/megalinter/issues/2943) — v6→v7 마이그레이션에서 **파일 필터가 아무것도 못 잡아 `project` 모드 린터만 실행**됐다. 요약표는 이랬다:

```
| ✅ COPYPASTE  | jscpd      | project |   n/a |  ...  |      0 |
| ✅ REPOSITORY | gitleaks   | project |   n/a |  ...  |      0 |
```

**전부 ✅이고 에러 0이다.** 파일 기반 린터는 표에 아예 나타나지 않았다. 보고자가 알아챈 것은 **로그의 `[Filters]` 줄을 읽었기 때문**이다.

> **선행 조사가 러너 층(§7.1.1·§10.1)과 테스트 프레임워크 층(§4.1 vitest 필터 불일치)에서 각각 실측한 fail-open이, 검사 애그리게이터 층에서 세 번째로 나타난다.** 층을 바꿔도 같은 결손이 반복된다는 것이 이 시리즈에서 가장 자주 재확인되는 패턴이다.
>
> **대응 형태도 선행 조사와 같다** — 종료 코드가 아니라 **"무엇이 몇 개 검사됐는가"를 기대값과 대조**한다. MegaLinter 요약표의 `Files` 열이 바로 그 수치이고, **`n/a`(project 모드)와 `0`(대상 없음)은 다른 값이다.**

### 7.3 반대 사례 — 부재를 실패로 처리하는 설계

§2.2에서 인용한 Nx Conformance의 문장이 이 절의 대척점이다.

> *"If a valid license is not available … the commands will **fail without checking any rules**."*

**"검사할 수 없음"을 통과가 아니라 실패로 낸다.** 이 조사에서 그렇게 하는 것을 명시한 유일한 사례다.

---

## 8. 이 조사가 재지 않은 것

- **직접 실측 없음.** 이 문서는 전부 문헌이다. 순환 검사 도구들의 **실제 종료 코드**(dependency-cruiser의 `warn` 기본값이 실제로 exit 0인지, madge `--circular`가 순환 발견 시 무엇을 내는지)는 재지 않았다
- **import-linter의 계약 타입 목록**(`forbidden`·`layers`·`independence` 등으로 알려진 것들). 계약 페이지가 404였고 설정 페이지의 `type = some_contract_type` 자리표시자까지만 확인했다
- **trunk `commands` 필드의 내부 규격.** 필드 목록에는 있으나 Linter Command Definition 페이지를 받지 못했다 — 출력 파싱을 어떻게 선언하는지가 그 안에 있을 가능성이 높고, **§4.1의 `errorformat` 방식과 대조할 대목이다**
- **현행 Go 툴체인이 순환 import를 어느 단계에서 거부하는지**(§1.1)
- **SARIF가 커버리지를 담을 수 있는지** 명세 본문에서 확인하지 않았다. 서문이 "정적 분석 결과"를 대상으로 한다는 것만 확인했고, 커버리지 미지원은 **부재 증명이라 주장하지 않는다**
- **Semgrep·CodeQL(전략 A)** 은 검색 결과에만 등장했고 본문 미확인이다. 인용하지 않았다
- **qlty의 현행 플러그인 규격** — Code Climate 엔진 명세는 확인했으나 후속 제품의 규격은 확인하지 못했다
- **Android/Gradle 축** — 플랫폼 축은 Xcode 하나만 봤다
- **MegaLinter가 도구 미설치(ⓑ)를 어떻게 처리하는지** — 도커 이미지에 전부 넣는 구조라 이 조사의 ⓑ가 해당되지 않을 가능성이 높으나 확인하지 못했다

---

## 9. 종합 — 분리선이 테스트와 다른 기준으로 그어진다

선행 조사의 표와 나란히 놓는다.

| 층 | 테스트(선행 조사) | 순환참조·커버리지(이 조사) |
|---|---|---|
| **의도(동사)** | **공통** — `test` | **공통이 아니다** — 언어가 흡수했거나(Go 순환), 단위가 다르거나(모듈 vs 크레이트), 규칙이 사용자 저작 |
| **활성 여부** | 항상 있다고 가정 | **탐지 또는 선언이 필요**(§6). 부재가 3종이고 전부 통과처럼 보인다(§7) |
| **호출** | 스택별 명령 | 스택별 명령 **+ 호출 모드**(file/list_of_files/project) — 이 계열은 대부분 `project`(§3.1) |
| **결과** | JUnit XML로 **부분 정규화** | **이슈는 SARIF로 수렴, 커버리지는 미수렴**(§4) |
| **판정 기준** | 3값(GREEN/RED/NO_TESTS_RAN) | **수치이고 언어 간 비교 불가**(§5.1) |
| **게이트 강제** | 루트 훅(비상속) | **프레임워크마다 위치가 다르고 기본값이 fail-open인 것도 있다**(§5.2 JaCoCo Gradle) |

**한 문장으로**: 테스트에서는 하네스가 **동사를 소유하고 결과를 부분적으로 정규화**했지만, 이 계열에서는 **하네스가 소유할 수 있는 것이 "어댑터 레지스트리"뿐이고 동사조차 어댑터가 공급한다.**

**그리고 이 조사가 확인한 어댑터의 최소 필드는 다섯이다** — 세 제품(MegaLinter·trunk·Code Climate)이 이름은 달라도 같은 다섯을 갖는다.

| # | 필드 | MegaLinter | trunk | Code Climate |
|---|---|---|---|---|
| 1 | **적용 대상** | `descriptor_type` + 파일 매칭 규칙 | `direct_configs` + 파일 타입 | `engine.json`의 `languages[]` |
| 2 | **설치** | `install.{apk,cargo,npm,pip,gem,dockerfile}` + `supported_platforms` | `runtime`+`package` **또는** `download` | 도커 이미지 |
| 3 | **호출 모드** | `cli_lint_mode` 3값 | `batch` | *(대응 필드 없음 — 컨테이너 1회 실행 고정으로 읽힌다. **이 칸만 인용이 아니라 해석이다**)* |
| 4 | **결과 읽기** | `cli_lint_errors_count` 5값 | (커맨드 정의) | **STDOUT 이슈 JSON, `\0` 구분** |
| 5 | **버전 관리** | `linter_version_cache`, `downgraded_version` | `known_good_version`/`known_bad_versions` | `version`/`spec_version` |

---

## 10. 열린 질문

1. **ⓐ(무의미)와 ⓑ(미설치)를 무엇으로 구분해 선언할 것인가.** 이 조사가 찾은 어느 제품도 "이 언어에는 이 검사가 존재하지 않는다"를 **명시적으로 선언하는 필드를 갖지 않는다.** MegaLinter의 `descriptor_type`·`languages[]`는 "적용 대상"이지 "비적용의 이유"가 아니다
   - **후속 (2026-08-03, [훅–스킬 접합부 실측 §3.2](hook-skill-frontmatter-probe.md)) — 재현됐고 한 겹 더 깊다.** 라우터를 실제로 짜서 돌리니 **ⓐ 자체가 둘로 갈렸다** — `.go`(툴체인이 잡으므로 어댑터 부재가 정상)와 `.rs`(모듈 순환은 안 잡히므로 진짜 공백)가 **같은 `ABSENT_A` 출력**을 냈다. **부재를 선언하는 칸이 없기 때문**이며, `absent_reason` 같은 필드를 두면 갈릴 것으로 보이나 **검증하지 않았다**
2. **`project` 모드 검사와 변경 파일 기반 훅이 충돌한다**(§3.1). 순환·커버리지는 전체를 봐야 하는데 `PostToolUse`는 파일 단위로 걸린다. **어느 주기에 어디서 돌릴 것인가**를 이 조사는 다루지 않았다
3. **커버리지 임계값을 언어 간에 어떻게 표현할 것인가.** §5.1이 비교 불가를 확정했으므로 전역 단일 값은 성립하지 않는다. **언어별 값을 두는가, 절대값 대신 델타(`go-test-coverage`의 base 대비 diff)를 쓰는가**가 갈림길이다
4. **`errorformat` 방식(§4.1)이 이 계열에 얼마나 적용되는가.** 순환 검사 도구들의 출력이 "파일:줄:열: 메시지" 형태인지 재지 않았다. **커버리지에는 적용되지 않는다**는 것만 확정
5. **어댑터 레지스트리를 어디에 두는가.** 선행 조사가 확정한 `settings.json` 비상속(모듈별 게이트 선언 불가)이 여기에도 걸린다. MegaLinter·trunk는 **루트 단일 설정**이고, 그것이 우연이 아닐 수 있다
6. **`fingerprint`(§3.3)를 이 하네스가 쓸 수 있는가.** [오류 재발 방지 조사](error-recurrence-prevention.md)의 "같은 지적이 반복되는가" 측정에 필요한 필드인데, SARIF에도 대응 개념(`partialFingerprints`)이 있는지 확인하지 않았다
7. **검사 결과를 머지 커밋 단위로 올리는 방법.** [평가 조사 §1.5.4](evaluation.md)의 전이 한계가 그대로 남는다 — 선행 조사의 열린 질문 8과 동일

---

## 부록 — 출처

| 등급 | 출처 |
|---|---|
| **1차(표준·명세)** | [SARIF 2.1.0 (OASIS)](https://docs.oasis-open.org/sarif/sarif/v2.1.0/os/sarif-v2.1.0-os.html), [Go spec](https://go.dev/ref/spec) + [golang/go#4976](https://github.com/golang/go/issues/4976), [JLS §7](https://docs.oracle.com/en/java/javase/26/docs/specs/jls/jls-7.html), [java.lang.module](https://docs.oracle.com/en/java/javase/22/docs/api/java.base/java/lang/module/package-summary.html) |
| **1차(공식 문서)** | [MegaLinter descriptor 스키마](https://megalinter.io/latest/json-schemas/descriptor.html), [trunk lint definitions](https://docs.trunk.io/code-quality/overview/getting-started/configuration/lint/definitions.md), [Code Climate 엔진 명세](https://github.com/codeclimate/platform/blob/master/spec/analyzers/SPEC.md), [reviewdog](https://github.com/reviewdog/reviewdog), [SonarQube generic issue import](https://docs.sonarsource.com/sonarqube-server/analyzing-source-code/importing-external-issues/generic-issue-import-format), [Codecov 지원 형식](https://docs.codecov.com/docs/supported-report-formats), [JaCoCo counters](https://www.jacoco.org/jacoco/trunk/doc/counters.html), [JaCoCo Gradle plugin](https://docs.gradle.org/current/userguide/jacoco_plugin.html), [coverage.py FAQ·branch](https://coverage.readthedocs.io/en/latest/faq.html), [Go build-cover](https://go.dev/doc/build-cover), [cargo-llvm-cov](https://github.com/taiki-e/cargo-llvm-cov), [Jest 설정](https://jestjs.io/docs/configuration), [xccov(1)](https://keith.github.io/xcode-man-pages/xccov.1.html), [ArchUnit User Guide](https://www.archunit.org/userguide/html/000_Index.html), [import-linter 설정](https://import-linter.readthedocs.io/en/stable/get_started/configure/), [dependency-cruiser rules-reference](https://github.com/sverweij/dependency-cruiser/blob/main/doc/rules-reference.md), [madge](https://github.com/pahen/madge/), [Nx enforce-module-boundaries](https://nx.dev/docs/technologies/eslint/eslint-plugin/guides/enforce-module-boundaries), [Nx Conformance](https://nx.dev/docs/enterprise/conformance), [mise configuration](https://mise.jdx.dev/configuration), [Renovate 기여 문서](https://github.com/renovatebot/renovate/blob/main/docs/development/adding-a-package-manager.md), [SARIF Multitool](https://github.com/microsoft/sarif-sdk/blob/main/docs/multitool-usage.md), [super-linter](https://github.com/super-linter/super-linter), [go-test-coverage](https://github.com/vladopajic/go-test-coverage) |
| **1차(이슈·포럼)** | [MegaLinter #2943](https://github.com/oxsecurity/megalinter/issues/2943), [Rust 사용자 포럼 — 모듈 수준 순환](https://users.rust-lang.org/t/resolving-cyclic-dependency-at-module-level/116990) |
| 2차 | [DeepWiki — Renovate manager/datasource](https://deepwiki.com/renovatebot/renovate/6-manager-and-datasource-system) (기여 문서로 교차 확인) |
| **인용하지 않음** | Semgrep·CodeQL(본문 미확인), qlty 현행 규격(미확인), sarif-exporter 등 서드파티 변환기(존재만 확인) |
