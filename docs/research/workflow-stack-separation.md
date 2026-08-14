# 워크플로우와 기술 스택의 분리 — 자료 수집과 실측

**최초 작성**: 2026-08-03
**최종 수정**: 2026-08-03
**대상 프로젝트**: grid fin (신규 개인용 개발 하네스)
**조사 계기**: *"TDD 방식으로 개발하는 것은 같지만 A모듈은 TS를 쓰고 B모듈은 Rust를 쓰는 경우"* — 워크플로우를 스택에서 떼어내는 방법
**조사 도구**: WebFetch 6회(1차 문서), WebSearch 3회, **직접 실험 1건**(vitest × cargo-nextest, 조건 10개)
**성격**: 자료 수집 + 실측. grid fin 설계 결정은 하지 않는다.

---

## 0. 먼저 — 실행 층은 이미 답이 나와 있다

[repository-layout.md](repository-layout.md)가 **태스크 이름 계약**을 이미 실측으로 닫았다. **이 문서는 그것을 다시 유도하지 않는다.**

| 이미 확정된 것 | 출처 |
|---|---|
| `build`/`test`/`lint` **이름 계약을 유지한 채 실행 주체만 언어별로 바꿀 수 있다.** Nx `project.json` `targets`가 `package.json` 없는 Python·셸 프로젝트를 인식하고 `run-many -t test` 하나로 디스패치 | repository-layout §9.2 (실측) |
| 언어 중립 러너 4종(`pnpm -r`·Nx·mise·moon) 모두 **부분 부재를 exit 0으로 통과**시킨다. **러너를 바꿔서 해결되지 않는 공통 결손** | 같은 문서 §10.1 (실측) |
| `pnpm -r`가 닿는 것은 **JS/TS 서브트리뿐**. BE가 Node가 아니면 우아한 저하가 적용되지 않는다 | 같은 문서 §7.1 |
| **`.claude/settings.json`은 상위 디렉터리에서 상속되지 않는다.** CLAUDE.md와 규칙이 다르다 | 같은 문서 §8.3·§9.1 (실측) |

**이 문서가 다루는 것은 그 위층이다** — 명령 이름이 통일돼도 **TDD 워크플로우는 아직 성립하지 않는다.** §1이 그 이유다.

### 0.1 조사 요약

| # | 관측 | 근거 등급 |
|---|---|---|
| 1 | **TDD의 red 단계는 종료 코드로 표현할 수 없다.** "테스트가 돌아서 실패했다"와 "테스트가 돌지 않았다"를 갈라야 하는데, 종료 코드는 그 구분을 담지 않는다 | 구조적 논증 — §1 |
| 2 | **종료 코드는 런타임 간에 정규화되지 않는다.** 같은 "테스트 실패"가 vitest 1 / nextest **100**, 같은 "테스트 없음"이 vitest 1 / nextest **4** | **1차 실측** — §2 |
| 3 | **JUnit XML의 카운터는 정규화된다.** 두 러너의 `tests`·`failures`·`errors` 속성 의미가 일치하고, **27줄 파서 하나가 두 런타임 10개 조건을 전부 옳게 판정**했다 — **단 실행 전체 수준에서만이다**(관측 5b·5c) | **1차 실측** — §3 |
| 4 | **그러나 나이브한 파서는 fail-open이다.** `tests=` 만 읽으면 **vitest의 "필터가 아무것도 못 잡음"을 GREEN으로 오판**한다. `executed = tests − skipped`로 보정해야 10/10이 된다 | **1차 실측** — §4.2 |
| 5 | **테스트 선택 문법은 정규화되지 않고, 불일치 시 동작도 갈린다.** vitest `-t 'NOPE'`는 **exit 0**(fail-open), nextest `-E 'test(NOPE)'`는 exit 4 | **1차 실측** — §4.1 |
| 5b | **코드가 빌드되지 않으면 낡은 리포트가 읽힌다.** nextest는 컴파일 실패 시 `junit.xml`을 **갱신하지 않고**(mtime 불변) 파서는 직전 실행의 `RED`를 그대로 낸다. **TDD red 단계의 정상 시작 상태가 곧 이 조건이다** | **1차 실측** — §4.3 |
| 5c | **테스트 개별 식별자는 정규화되지 않는다.** 같은 테스트가 vitest `classname="fail/a.test.ts" name="adds"` / nextest `classname="xp_fail" name="tests::adds"`. **한 러너 안에서도 조건에 따라 `name`의 의미가 바뀐다** | **1차 실측** — §4.4 |
| 6 | **Bazel이 이 분리의 가장 완성된 기성 답이다** — `XML_OUTPUT_FILE` 규약으로 *"XML schema is based on the JUnit test result schema"*, 테스트가 XML을 안 쓰면 Bazel이 `bazel-testlogs`에 대신 생성 | **1차 (공식)** — §5.1 |
| 7 | **Nx executor가 "워크플로우가 의도를 선언하고 플러그인이 스택을 공급한다"의 정확한 형태다** — *"you always run `nx build cart` regardless of whether it uses webpack, esbuild"* | **1차 (공식)** — §5.2 |
| 8 | **pre-commit의 `language:` 키가 20종 이상 런타임에 대해 같은 훅 워크플로우를 돌리는 성숙한 선례다.** 훅마다 격리 환경을 만들고 **런타임이 없으면 받아서 빌드한다** | **1차 (공식)** — §5.3 |
| 9 | **moon의 다중 언어 주장은 "toolchain"이 뒷받침한다 — 다만 그것은 버전·설치 관리자이지 태스크 추상화가 아니다.** 공식 문서가 지원 언어 목록을 이 페이지에 싣지 않는다 | **1차 (공식), 부분 확인** — §5.4 |
| 10 | **이 분리를 실제로 출하한 하네스가 있다** — SWE-bench Multilingual: 9개 언어 42개 저장소 300태스크를 *"the same collection strategy, dataset format and evaluation protocol"* 로 돌린다. **언어별로 남긴 것은 도커 base 이미지·설치/테스트 명령·로그 파서 셋뿐** | **1차 (공식)** — §6 |
| 11 | **AGENTS.md 규격이 중첩을 명시 지원한다** — *"Large monorepo? Use nested AGENTS.md files for subprojects"*, 가장 가까운 파일이 우선 | **1차 (공식)** — §7.2 |
| 12 | **그러나 지시는 중첩되는데 훅·권한은 안 된다.** `settings.json` 비상속(선행 실측)과 겹쳐 **"모듈이 각자 게이트를 선언한다"는 형태는 성립하지 않는다** | 선행 실측 + 이 문서의 종합 — §7.1 |

---

## 1. 문제 정의 — 이름 계약만으로 TDD가 서지 않는 이유

TDD 사이클이 하네스에게 요구하는 술어는 셋이다.

| 단계 | 필요한 판정 |
|---|---|
| **red** | 방금 쓴 테스트가 **돌았고 그리고 실패했다** |
| **green** | 그 테스트가 **돌았고 그리고 통과했다** |
| refactor | 기존 테스트 전체가 여전히 통과 |

**red가 결정적이다.** "테스트가 실행되어 실패함"과 "테스트가 실행되지 않음"을 갈라야 한다. 후자를 red로 오인하면 **존재하지 않는 테스트를 통과시키는 구현으로 진행한다.**

그런데 [repository-layout §7.1.1·§10.1](repository-layout.md)의 실측이 이미 답을 준다 — **부분 부재는 네 러너 모두 exit 0**이고, Nx는 전면 부재도 exit 0이다. **종료 코드는 이 구분을 담지 못한다.**

> **따라서 분리선은 "명령을 정규화한다"가 아니라 "결과 객체를 정규화한다"에 그어진다.** 이 문서의 나머지는 그 명제를 실측하고 기성 해법을 대조한다.

---

## 2. 실측 (1) — 종료 코드는 정규화되지 않는다

**환경**: node v24.13.0 / vitest 3.2.7 / cargo 1.97.1 / cargo-nextest 0.9.140 (arm64 macOS). Rust 툴체인과 nextest는 **스크래치패드에 설치했고 사용자 머신에는 설치하지 않았다** — [repository-layout §10.1](repository-layout.md)의 mise·moon 실측과 같은 방식이다. 재현 스크립트는 부록 A.

| 조건 | vitest 종료 코드 | cargo-nextest 종료 코드 |
|---|---:|---:|
| 전부 통과 | **0** | **0** |
| 테스트 실패 | 1 | **100** |
| 테스트 파일 없음 | 1 | **4** |
| 필터 적중 (실패하는 테스트 지정) | 1 | **100** |
| **필터 불일치 (없는 이름 지정)** | **0** | **4** |

**세 가지가 드러난다.**

1. **성공만 공통이다.** 0 = 통과는 양쪽 같지만 실패 코드가 1과 100으로 갈린다
2. **"테스트 없음"에 고유 코드를 주는 쪽이 있다** — nextest의 4. vitest는 실패와 같은 1이라 종료 코드만으로는 구분 불가
3. **필터 불일치에서 방향이 반대다** — vitest는 **0(성공)**, nextest는 4. §4.1에서 다시 다룬다

**[repository-layout §10.1](repository-layout.md)의 관측 24와 같은 계열이다** — 그 조사는 러너 층에서 *"`pnpm -r`·mise는 하위 코드를 그대로, Nx·moon은 1로 정규화한다"* 를 쟀다. 이 조사는 그 아래 **테스트 프레임워크 층에서 하위 코드 자체가 서로 다름**을 확인한다. 러너가 코드를 그대로 올리든 1로 정규화하든, **올라오는 값의 의미가 애초에 공통이 아니다.**

---

## 3. 실측 (2) — JUnit XML은 정규화된다

### 3.1 두 런타임에서 같은 모양이 나온다

| 런타임 | 설정 | 출력 |
|---|---|---|
| TS | `vitest run --reporter=junit --outputFile=out.xml` | `<testsuites tests= failures= errors=>` |
| Rust | `.config/nextest.toml`에 `[profile.ci.junit] path = "junit.xml"` → `target/nextest/ci/junit.xml` | 같은 구조 |

`nextest` 공식 문서가 *"adheres to the Jenkins XML format"* 라고 밝히고, 테스트 바이너리 하나가 `<testsuite>` 하나, 테스트 하나가 `<testcase>` 하나가 된다.

**"테스트 없음" 조건에서 양쪽 모두 `tests="0"` 을 담은 빈 `<testsuites>` 를 낸다.** 종료 코드가 갈렸던 바로 그 상태가 XML에서는 같은 모양이다.

### 3.2 파서 하나로 두 런타임을 판정 — 성립

27줄 파이썬(stdlib `xml.etree`)으로 6개 조건 전수:

| 파일 | 판정 |
|---|---|
| ts/pass | `GREEN (ran=1)` |
| ts/fail | `RED (ran=1 fail=1)` |
| ts/empty | `NO_TESTS_RAN` |
| rs/pass | `GREEN (ran=1)` |
| rs/fail | `RED (ran=1 fail=1)` |
| rs/empty | `NO_TESTS_RAN` |

**§1이 요구한 세 술어가 런타임 무관하게 나온다.** 이것이 이 조사의 핵심 실측이다.

---

## 4. 실측 (3) — 그런데 두 군데가 새고, 둘 다 red 단계를 겨냥한다

### 4.1 테스트 선택 문법은 정규화되지 않는다 — 그리고 불일치가 조용하다

TDD는 *"방금 쓴 그 테스트"* 를 지목해야 한다. 문법이 전부 다르다:

| 런타임 | 선택 문법 |
|---|---|
| vitest | `-t '<이름 패턴>'` |
| cargo-nextest | `-E 'test(<이름>)'` 또는 위치 인자 |
| pytest | `-k '<식>'` |

**문법 차이는 어댑터로 흡수할 수 있다. 문제는 그다음이다.**

| 필터가 아무것도 못 잡았을 때 | vitest | cargo-nextest |
|---|---|---|
| 종료 코드 | **0 (성공)** | 4 |
| JUnit `tests=` | **1** | **0** |
| 그 testcase | `<skipped/>`, `skipped="1"` | 아예 없음 |

**vitest는 필터로 걸러진 테스트를 `tests=` 에 계속 센다.** 오타 난 테스트 이름으로 red를 확인하려 하면 **종료 코드 0을 받는다.** TDD 관점에서 최악의 실패 모드다 — 아무것도 안 돌았는데 성공 신호가 온다.

**이것은 [repository-layout §7.1.1](repository-layout.md)이 러너 층에서 찾은 fail-open과 같은 형태의 결손이 테스트 프레임워크 층에도 있다는 뜻이다.** 그 조사의 대응(*"몇 개 패키지에서 실제로 돌았는가를 기대값과 대조하는 단언"*)이 여기서도 그대로 필요하다 — 단위만 패키지에서 테스트로 바뀐다.

### 4.2 그래서 나이브한 XML 파서도 fail-open이다

§3.2의 파서를 필터 조건까지 넓히면 **오판이 나온다.**

| 파일 | 나이브(`tests`만) | 보정(`tests − skipped`) |
|---|---|---|
| ts/필터 불일치 | **`GREEN` ← 오판** | `NO_TESTS_RAN (tests=1 skipped=1)` |
| rs/필터 불일치 | `NO_TESTS_RAN` | `NO_TESTS_RAN (tests=0 skipped=0)` |

**보정식은 한 줄이다.**

```python
executed = tests - skipped
if executed == 0:      return 'NO_TESTS_RAN'
if failures + errors:  return 'RED'
return 'GREEN'
```

**보정 후 10개 조건 전수(통과·실패·없음·필터적중·필터불일치 × 2런타임)에서 10/10 정확했다.**

> **다만 이 보정은 러너별 규약에 의존한다.** vitest는 걸러진 테스트를 `skipped`로 세고 nextest는 아예 안 센다. 두 규약이 우연히 같은 식으로 정규화될 뿐이며, **세 번째 런타임이 또 다른 규약을 쓸 수 있다.** 새 런타임을 붙일 때마다 §4의 5개 조건을 다시 재야 한다는 뜻이고, 그것이 이 접근의 실제 비용이다.
>
> **측정 실패 1건**: nextest의 `report-skipped` 옵션(`none`/`ignored`/`all`)이 `#[ignore]` 테스트의 XML 노출을 바꾼다고 문서가 서술하나, **세 값 모두에서 출력이 동일했다**(`tests=1 skipped=0`). 문서와 관측이 어긋나며 원인을 규명하지 못했다. 위 결론은 이 옵션과 무관하게 성립한다(필터 제외 테스트는 어느 값에서도 세지 않는다).

### 4.3 세 번째 구멍 — 낡은 XML을 읽는다 (실측)

**JUnit XML은 디스크의 파일이고, 실행이 리포트를 쓰기 전에 죽으면 직전 실행의 결과가 그대로 읽힌다.** 파서는 이것을 구분할 수 없다.

**그리고 이것은 예외 상황이 아니라 TDD red 단계의 정상 시작 상태다** — 아직 존재하지 않는 함수를 호출하는 테스트를 먼저 쓰면 크레이트가 컴파일되지 않는다.

| 단계 | exit | `junit.xml` mtime | 파서 판정 |
|---|---:|---|---|
| 정상 실행 (테스트 실패) | 100 | `1785720730` | `RED (ran=1 fail=1)` |
| 3초 후, **컴파일 실패** | **101** | `1785720730` — **바뀌지 않음** | **`RED (ran=1 fail=1)` ← 낡은 결과** |

**하네스가 red를 기다리고 있을 때 정확히 red를 받는다.** 종료 코드(101)에는 정보가 있지만 §2가 보인 대로 그 값의 의미는 런타임마다 다르고, **결과 객체 층만 보는 설계는 이 상태를 통과시킨다.**

**vitest는 다르게 새고 방향은 같다.** import 오류 조건에서 XML을 **쓰기는 쓴다** — 그런데 `tests="1" failures="1"` 이고 testcase의 `name` 이 테스트 이름이 아니라 **파일 경로**(`broken/a.test.ts`)다.

| | 코드가 빌드되지 않을 때 |
|---|---|
| cargo-nextest | XML 미갱신 → **낡은 판정** |
| vitest | XML 갱신 → **RED, 단 testcase 이름이 파일 경로** |

**양쪽 모두 "내가 방금 쓴 테스트가 돌아서 실패했다"와 "코드가 빌드되지 않는다"를 판정 3값으로 구분하지 못한다.**

**대응은 [repository-layout §7.1.1](repository-layout.md)이 러너 층에서 요구한 것과 같은 형태다** — 종료 코드나 파일 존재가 아니라 **"실제로 무엇이 돌았는가"를 기대값과 대조**한다. 최소 형태는 둘이다: **실행 전 리포트 파일 삭제**, 그리고 **mtime을 실행 시작 시각과 대조**. 어느 쪽도 무료가 아니며 하네스가 러너를 감싸야 성립한다.

### 4.4 네 번째 구멍 — 테스트 **식별자**는 정규화되지 않는다

§3.2의 파서는 **실행 전체**에 대해 3값을 낸다. 그런데 §1이 요구한 술어는 *"방금 쓴 **그** 테스트가 돌았고 실패했다"* 다. **둘은 다르다** — 다른 곳의 기존 실패가 있으면 새 테스트가 한 번도 안 돌아도 `RED`가 나온다.

테스트 단위로 내려가려면 `<testcase>` 를 식별해야 하는데, **거기서 정규화가 깨진다.**

| 런타임 | 같은 테스트의 `<testcase>` 속성 |
|---|---|
| vitest | `classname="fail/a.test.ts"` `name="adds"` |
| cargo-nextest | `classname="xp_fail"` `name="tests::adds"` |
| vitest (import 오류 시) | `classname="broken/a.test.ts"` `name="broken/a.test.ts"` — **이름이 파일 경로로 바뀐다** |

**`name`은 한쪽이 모듈 경로로 수식돼 있고, `classname`은 한쪽이 파일 경로 다른 쪽이 크레이트 이름이다.** 게다가 **한 러너 안에서도 조건에 따라 `name`의 의미가 바뀐다**(마지막 행).

> **카운터는 정규화되는데 식별자는 안 된다.** 따라서 §4.1의 **선택 어댑터**와 결과 층의 **식별 어댑터**는 별개 문제가 아니라 **같은 문제의 양끝**이다 — 하네스가 "이 테스트"를 지목하는 문자열과 리포트에서 그것을 되찾는 문자열이 런타임마다 각각 다르고, 둘을 잇는 매핑이 런타임당 하나씩 필요하다.

---

## 5. 기성 해법 넷 — 같은 분리를 어디에 그었는가

### 5.1 Bazel — 가장 완성된 형태

[Test Encyclopedia](https://bazel.build/reference/test-encyclopedia) 본문 확인.

| 요소 | 규약 |
|---|---|
| **종료 코드** | *"If a test process runs to completion and terminates normally with an exit code of zero, the test has passed. Any other result is considered a test failure."* — **모든 언어에 동일** |
| stdout 무시 | *"writing any of the strings `PASS` or `FAIL` to stdout has no significance to the test runner"* |
| **결과 객체** | `XML_OUTPUT_FILE` 환경변수. *"XML schema is based on the JUnit test result schema"* |
| **미작성 시 대체** | 테스트가 XML을 안 쓰면 **Bazel이 `bazel-testlogs`에 생성해 준다** |
| 테스트 룰 요구사항 | *"yield an executable program"* — 네이티브 바이너리든 언어별 하네스든 |

**§1의 명제가 여기서 제도화돼 있다.** 종료 코드는 통과/실패 이진값으로만 쓰고, **판정에 필요한 구조는 XML로 뺐다.** 그리고 프레임워크가 XML을 안 내면 러너가 대신 만든다 — §4.2가 발견한 "런타임마다 규약이 다르다"를 러너 층에서 흡수하는 설계다.

**대가**: 모든 테스트 타깃이 Bazel 룰로 표현돼야 한다. 개인 하네스가 지불하기 어려운 값이다.

### 5.2 Nx executor — 포트/어댑터

[Executors and configurations](https://nx.dev/docs/concepts/executors-and-configurations) 본문 확인.

> *"Executors are pre-packaged node scripts that can be used to run tasks in a consistent way."*
> *"you always run `nx build cart` regardless of whether it uses webpack, esbuild, or another bundler."*

형식은 `[package name]:[executor name]`이고, 프로젝트가 `project.json`의 `targets`에서 어느 executor를 쓸지 선언한다.

**"워크플로우가 이름으로 의도를 선언하고, 프로젝트가 구현을 공급한다"의 정확한 형태다.** [repository-layout §9.2](repository-layout.md)가 실측한 `targets` + `command` 조합은 이 메커니즘의 가장 단순한 사용이고, executor는 거기에 재사용 가능한 어댑터를 꽂는 것이다.

**한계**: executor는 **node 스크립트**다. 언어 중립인 것은 *실행 대상*이지 *어댑터 자신*이 아니다. 그리고 [repository-layout §10.1](repository-layout.md)이 잰 대로 **Nx는 전면 부재를 exit 0으로 통과시키는 유일한 러너**다.

### 5.3 pre-commit `language:` — 성숙한 선례

[pre-commit.com](https://pre-commit.com/) 본문 확인. 훅 정의가 `language:` 키로 런타임을 선언한다.

> 지원 목록: *"conda, coursier, dart, docker, docker_image, dotnet, fail, golang, haskell, julia, lua, node, perl, python, r, ruby, rust, swift, pygrep, unsupported, unsupported_script"*
> *"Each hook is initialized in a separate environment appropriate to the language the hook is written in."*
> *"If one of your developers doesn't have node installed but modifies a JavaScript file, pre-commit automatically handles downloading and building node to run eslint without root."*

**이 조사에 직접 쓸 관측 셋:**

1. **분리 지점이 "훅이 무엇을 하는가"(공통)와 "무엇으로 쓰였는가"(`language:`)다.** 워크플로우 정의에서 런타임을 한 필드로 격리했다
2. **환경 격리가 프레임워크 책임이다** — 훅마다 별도 환경을 만들고 없으면 받아서 빌드한다. 사용자가 다중 런타임을 미리 갖출 필요가 없다
3. **탈출구가 있다** — `unsupported`(구 `system`)는 가상환경 없이 설치된 실행파일을 그대로 부르고, `unsupported_script`는 셸 스크립트를 허용한다. **다만 의존성 관리 부담이 저장소 관리자에게 넘어간다**고 문서가 명시한다

### 5.4 moon toolchain — 주장의 근거는 확인, 범위는 미확인

[repository-layout §8.1](repository-layout.md)이 moon의 다국어 표방을 *"벤더 마케팅 페이지만"* 으로 등급 매겼다. [공식 toolchain 문서](https://moonrepo.dev/docs/concepts/toolchain)를 받아 확인한 결과:

> *"an internal layer for downloading, installing, and managing tools (languages, dependency managers, libraries, and binaries)"*
> *"Tools within the toolchain are managed by version for consistency across machines"*
> moon은 *"piggybacks of proto's toolchain"* — proto는 *"our stand-alone multi-language version manager"*

**등급 조정: 마케팅 페이지 → 공식 개념 문서.** 다만 **이 페이지는 지원 언어 목록을 싣지 않고, 태스크 정의와 언어 도구를 어떻게 분리하는지도 다루지 않는다.**

> **결론: moon의 toolchain은 pre-commit의 `language:`와 같은 층이 아니다.** 버전·설치 관리자이며, [repository-layout §10.1](repository-layout.md)이 실측한 것은 그 위의 태스크 디스패치다. **둘을 합쳐야 pre-commit 한 개 분량이 된다.**

---

## 6. 이미 출하된 답 — 다국어 SWE-bench

**하나의 워크플로우를 9개 언어에 걸쳐 돌려야 하는 하네스가 실재하고, 그 설계가 공개돼 있다.**

[SWE-bench Multilingual](https://www.swebench.com/multilingual.html) — **300태스크 / 42저장소 / 9개 언어**(C, C++, Go, Java, JavaScript, TypeScript, PHP, Ruby, Rust).

| 층 | 공통인가 | 내용 |
|---|---|---|
| 수집 전략·데이터 형식·평가 프로토콜 | **공통** | *"the same collection strategy, dataset format and evaluation protocol"* |
| 판정 기준 | **공통** | fail-to-pass / pass-to-pass 테스트 집합 |
| 도커 base 이미지 | 언어별 | 런타임·OS 패키지 |
| **설치·빌드·테스트 명령** | 언어별 | 기여 가이드와 GitHub 워크플로우를 보고 **수작업으로 결정** |
| **로그 파서** | **언어별** | 통과/실패 테스트 추출 |

**중간층(environment 이미지)을 뺐다** — *"Multilingual's 300 tasks across 42 repositories rarely share dependencies"*. 원본 파이썬 벤치마크에서 유효했던 캐시가 다국어에서는 값을 못 한다.

**그리고 이 조사에 가장 중요한 문장이 남는다** — *"The design minimizes language-specific tooling elsewhere, enabling the shared evaluation harness to run consistently across all nine languages."* **언어별로 남긴 것은 셋뿐이고 나머지는 공통이다.**

> **그 셋 중 하나가 로그 파서라는 점이 §3·§4와 정확히 겹친다.** SWE-bench는 JUnit XML을 요구하지 않고 **언어별 로그 파서**를 짰다. [Multi-SWE-bench](https://github.com/multi-swe-bench/multi-swe-bench)도 같은 형태(Python: conda/pip, JS: npm/yarn, Java: maven/gradle, Rust: cargo + 프레임워크별 로그 파서)다.
>
> **즉 결과 정규화 지점에 선택지가 둘 있다** — **(가) JUnit XML을 요구**(§3, 비용은 각 프레임워크가 낼 수 있어야 함)와 **(나) 언어별 파서를 짠다**(SWE-bench, 비용은 언어당 한 번). §3.2의 실측은 (가)가 TS·Rust에서 성립함을 보였을 뿐 **(가)가 (나)보다 낫다는 것을 보이지 않았다.**

**등급 주의**: SWE-Bench++의 *"constrained neural synthesis"* 로 파서를 LLM 생성한다는 서술은 검색 요약에서 왔고 본문 미확인이다. 인용하지 않는다.

---

## 7. 하네스 층의 제약 — 지시는 중첩되는데 강제는 안 된다

### 7.1 비대칭

| 층 | 모듈별로 다르게 둘 수 있는가 | 근거 |
|---|---|---|
| `CLAUDE.md` | **가능** — 하위 디렉터리 파일이 온디맨드 로드 | repository-layout §1 (공식) |
| `AGENTS.md` | **가능** — 규격이 중첩을 명시 지원 | §7.2 (공식) |
| **`.claude/settings.json` (훅·권한)** | **불가** — 상위에서 상속되지 않고, 루트에만 두면 하위 시작 세션에 적용 안 됨 | repository-layout §8.3·§9.1 (**실측**) |

> **"각 모듈이 자기 게이트를 선언한다"는 형태는 이 비대칭 때문에 성립하지 않는다.** 스택 지식은 모듈 옆에 둘 수 있지만, **그것을 강제하는 훅은 루트에 있어야 하고 따라서 루트가 스택을 알아야 한다.** 루트 훅이 디스패처가 되고 모듈이 선언만 하는 형태만 남는다 — §3의 결과 객체 정규화가 바로 그 디스패처의 반환 규격이 된다.

### 7.2 AGENTS.md 규격이 말하는 것

[agents.md](https://agents.md/) 본문 확인.

> *"Large monorepo? Use nested AGENTS.md files for subprojects"* — *"Agents automatically read the nearest file in the directory tree, so the closest one takes precedence."*
> 권장 섹션에 *"Build and test commands"* 가 포함된다.
> FAQ: 나열한 명령을 에이전트가 실행하는가 — *"Yes—if you list them. The agent will attempt to execute relevant programmatic checks and fix failures before finishing the task."*

**즉 "모듈별 스택 명령"의 배치 위치는 규격이 이미 정해 뒀다.** 다만 그것은 **지시**이고, [repository-hygiene 조사](repository-hygiene.md)가 확인한 대로 지시는 따르되(`uv` 언급 시 인스턴스당 1.6회 vs 0.01회 미만) **강제는 아니다.**

### 7.3 스킬 층의 비용

[repository-layout §9.3](repository-layout.md)의 공식 확인 — 루트에서 세션을 시작하면 스킬 description이 예산(컨텍스트의 1%)을 넘을 때 **최소 사용 순으로 드롭된다**(절삭이 아니다).

**"스택마다 스킬 하나"는 이 예산을 스택 수만큼 곱한다.** 반대로 "워크플로우마다 스킬 하나 + 스택은 파라미터"는 곱하지 않는다. **분리를 하면 라우팅 표면이 줄어든다는 뜻이고, 이것이 §5·§6의 논의와 별개로 성립하는 하네스 고유 근거다.**

---

## 8. 종합 — 분리선이 어디에 그어지는가

자료 넷과 실측이 같은 층 구조를 가리킨다.

| 층 | 공통(워크플로우) | 스택별 | 이 조사의 근거 |
|---|---|---|---|
| **의도** | `test` / `build` / `lint` 이름 계약 | — | repository-layout §9.2 (실측), Nx §5.2 |
| **실행** | — | 명령·러너·환경 | pre-commit `language:` §5.3, SWE-bench base 이미지 §6 |
| **선택** | "이 테스트를 지목한다"는 의도 | `-t` / `-E` / `-k` 문법 **+ 이름 표기법** | **§4.1·§4.4 — 어댑터 필요, fail-open 위험** |
| **결과 (실행 전체)** | **판정 3값**(GREEN / RED / NO_TESTS_RAN) | 출력 형식 | **§3·§4.2 (실측)**, Bazel `XML_OUTPUT_FILE` §5.1 |
| **결과 (테스트 단위)** | **정규화 안 됨** | `<testcase>` `name`·`classname` 표기 | **§4.4 (실측)** |
| **결과의 신선도** | **보장 없음** | 리포트 미갱신 / 대체 형식 | **§4.3 (실측)** — 하네스가 러너를 감싸야 함 |
| **강제** | 루트 훅 (비상속) | — | repository-layout §9.1 (실측), §7.1 |

**한 문장으로**: 워크플로우가 소유하는 것은 **동사(`test`)와 실행 전체에 대한 판정(3값)**이고, 스택이 소유하는 것은 **그 사이의 전부 + 테스트 개별 식별자**다.

**이 조사가 실측으로 확인한 것은 셋이다.**

1. **실행 전체 판정의 경계는 TS·Rust에서 실제로 성립한다** — 27줄 파서가 10/10 (§3·§4.2)
2. **선택 경계에 조용한 구멍이 있다** — vitest 필터 불일치가 exit 0 (§4.1)
3. **그러나 그 판정만으로는 TDD red가 서지 않는다** — 테스트 단위로 내려가면 식별자가 정규화되지 않고(§4.4), 코드가 빌드되지 않는 상태에서 낡은 판정이 읽힌다(§4.3)

> **3번이 §1의 전제를 되돌려 놓는다.** "종료 코드가 아니라 결과 객체를 정규화한다"는 명제는 **필요조건이지 충분조건이 아니다.** 결과 객체 층은 *"이번 실행에서 무엇이 몇 개 돌았고 몇 개 실패했나"* 까지만 공통이고, TDD가 실제로 묻는 *"내가 방금 쓴 그 테스트가"* 는 **런타임당 어댑터 하나씩을 다시 요구한다.** 이 조사가 처음에 기대했던 "파서 하나로 끝난다"는 결론은 성립하지 않는다.

**그리고 §6이 대안을 남긴다** — 결과 정규화를 프레임워크에 요구할지(JUnit XML) 하네스가 흡수할지(언어별 파서)는 열려 있다. 실제로 출하된 다국어 하네스는 후자를 택했다.

---

## 9. 열린 질문

1. **세 번째 런타임에서 §4의 5개 조건이 어떻게 나오는가.** pytest는 `--junitxml`을 갖고 `-k`로 선택하지만, **필터 불일치 시 종료 코드와 `tests=` 를 재지 않았다.** 이 조사는 TS·Rust 둘만 쟀다
2. **`executed = tests − skipped` 보정이 세 번째 런타임에서도 성립하는가.** vitest와 nextest가 우연히 같은 식으로 정규화될 뿐일 수 있다(§4.2)
3. **JUnit XML 요구(§3) vs 언어별 파서(§6) 중 무엇이 싼가.** 언어당 한 번의 파서 작성 비용과, 프레임워크가 JUnit 리포터를 갖지 않을 때의 비용을 대조하지 않았다
   - **후속 (2026-08-03, [언어·플랫폼별 검사 분기 조사 §4](per-language-check-divergence.md)) — 부분 해소.** **검사 종류마다 답이 다르다.** 이슈·진단은 **SARIF(OASIS 표준)로 수렴**했고, **커버리지는 수렴하지 않았다**(Codecov가 파서 20종 이상 유지). 그리고 **이 이분법 밖의 제3의 답이 출하돼 있다** — reviewdog의 `errorformat`은 파서를 **코드가 아니라 한 줄 선언**으로 쓰고 주요 도구는 사전 정의돼 있다. **다만 "파일:줄:열: 메시지" 형태에만 통하며 집계 수치(커버리지)에는 적용되지 않는다.** 테스트 결과에 적용 가능한지는 여전히 미확인
4. **Bazel의 "러너가 XML을 대신 생성한다"(§5.1)를 경량으로 흉내낼 수 있는가.** JUnit 리포터가 없는 프레임워크를 위한 폴백이 필요하다
5. **`#[ignore]`·`test.skip`·`@pytest.mark.skip` 등 의도적 스킵과 필터 제외를 판정에서 갈라야 하는가.** §4.2의 보정식은 둘을 같게 취급한다 — TDD refactor 단계에서 문제가 될 수 있다
6. **nextest `report-skipped`의 문서-관측 불일치**(§4.2 측정 실패)
6b. **§4.4의 식별자 매핑을 런타임당 무엇으로 표현할 것인가.** 선택 문법(`-t`/`-E`/`-k`)과 리포트 표기(`name`/`classname`)를 잇는 왕복 함수가 필요한데, 그 규격을 다룬 자료를 찾지 못했다. **Bazel·SWE-bench 어느 쪽도 이 문제를 다루지 않는다** — 둘 다 실행 전체 단위로 판정하기 때문이다
6c. **§4.3의 완화책 둘(실행 전 삭제 / mtime 대조) 중 무엇이 러너 4종 위에서 성립하는가.** 리포트 경로가 러너·프레임워크마다 다르고, [repository-layout §10.1](repository-layout.md)이 잰 대로 워크스페이스 전체 실행에서는 리포트가 여러 개 나온다
7. **루트 훅 디스패처가 모듈의 스택을 어디서 읽는가.** AGENTS.md는 지시이고 파싱 규격이 없다. `project.json`·`moon.yml` 같은 기계 판독 파일이 후보이나 대조하지 않았다
   - **후속 (2026-08-03, [언어·플랫폼별 검사 분기 조사 §6](per-language-check-divergence.md)) — 부분 해소.** **두 진영이 있고 탐지 쪽은 신호 목록을 공개해 뒀다.** 탐지: MegaLinter(확장자·파일명 정규식·**파일 내용 정규식**·설정파일 존재), trunk(`direct_configs`), mise(**언어별 idiomatic version file 표** — `.nvmrc`·`go.mod`·`rust-toolchain.toml` …, 다만 파싱 비용 때문에 **기본 비활성**), Renovate(manager가 package file 매칭). 선언: Nx `targets`·`moon.yml`·`.pre-commit-config.yaml`. **이 조사가 추정 후보로 든 기계 판독 파일이 실제로 쓰이고 있으나, 도구 자신의 설정 파일을 신호로 삼는 방식이 더 흔하다**
8. **grid fin의 검증 단위는 테스트가 아니라 머지 커밋이다**([evaluation.md §1.5.4](evaluation.md)의 전이 한계). 이 조사의 3값 판정이 그 단위로 어떻게 올라가는지 다루지 않았다

---

## 부록 A — 재현 스크립트

**사용자 머신에 아무것도 설치하지 않는다.** Rust 툴체인과 nextest는 스크래치패드에 받는다.

```bash
SP=$(mktemp -d)
# --- Rust 툴체인 (스크래치패드 격리) ---
export RUSTUP_HOME=$SP/rust/rustup CARGO_HOME=$SP/rust/cargo
curl -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path --profile minimal
curl -sSL https://get.nexte.st/latest/mac | tar xz -C $CARGO_HOME/bin
export PATH=$CARGO_HOME/bin:$PATH

# --- TS 쪽 ---
mkdir -p $SP/ts/{pass,fail,empty} && cd $SP/ts
echo '{"name":"xp","private":true,"type":"module","devDependencies":{"vitest":"^3.2.4"}}' > package.json
npm install --silent
printf "import {expect,test} from 'vitest'\ntest('adds',()=>{expect(1+1).toBe(2)})\n" > pass/a.test.ts
printf "import {expect,test} from 'vitest'\ntest('adds',()=>{expect(1+1).toBe(3)})\n" > fail/a.test.ts
echo '// no tests' > empty/placeholder.ts
for c in pass fail empty; do
  npx vitest run --dir $c --reporter=junit --outputFile=out-$c.xml >/dev/null 2>&1
  echo "[$c] exit=$?"
done
npx vitest run --dir fail -t 'adds' --reporter=junit --outputFile=f-hit.xml  >/dev/null 2>&1; echo "[hit]  exit=$?"
npx vitest run --dir fail -t 'NOPE' --reporter=junit --outputFile=f-miss.xml >/dev/null 2>&1; echo "[miss] exit=$?"

# --- Rust 쪽 ---
for c in pass fail empty; do
  D=$SP/rs-$c; mkdir -p $D/src $D/.config
  printf '[package]\nname = "xp_%s"\nversion = "0.1.0"\nedition = "2021"\n' $c > $D/Cargo.toml
  printf '[profile.ci.junit]\npath = "junit.xml"\n' > $D/.config/nextest.toml
  echo 'pub fn add(a: i32, b: i32) -> i32 { a + b }' > $D/src/lib.rs
done
printf '#[cfg(test)]\nmod t { #[test] fn adds() { assert_eq!(super::add(1,1), 2); } }\n' >> $SP/rs-pass/src/lib.rs
printf '#[cfg(test)]\nmod t { #[test] fn adds() { assert_eq!(super::add(1,1), 3); } }\n' >> $SP/rs-fail/src/lib.rs
for c in pass fail empty; do
  (cd $SP/rs-$c && cargo nextest run --profile ci >/dev/null 2>&1; echo "[rs-$c] exit=$?")
done
(cd $SP/rs-fail && cargo nextest run --profile ci -E 'test(NOPE)' >/dev/null 2>&1; echo "[rs-miss] exit=$?")
```

**공통 파서** (`verdict.py`):

```python
import sys, xml.etree.ElementTree as ET
def verdict(path):
    r = ET.parse(path).getroot()
    suites = r.findall('.//testsuite') if r.tag == 'testsuites' else [r]
    g = lambda k: sum(int(s.get(k, 0)) for s in suites)
    tests, skipped, fails, errs = g('tests'), g('skipped'), g('failures'), g('errors')
    executed = tests - skipped                      # ← 이 보정이 없으면 fail-open
    if executed == 0:    return f'NO_TESTS_RAN (tests={tests} skipped={skipped})'
    if fails + errs > 0: return f'RED   (ran={executed} fail={fails} err={errs})'
    return f'GREEN (ran={executed})'
for p in sys.argv[1:]:
    print(f'{verdict(p):42s} <- {p}')
```

**§4.3 낡은 리포트 재현** (별도 실행):

```bash
cd $SP/rs-fail
cargo nextest run --profile ci; stat -f %m target/nextest/ci/junit.xml   # 정상 실행, mtime 기록
python3 -c "import time; time.sleep(3)"
# 아직 없는 함수를 호출하도록 바꿔 컴파일을 깨뜨린다 (TDD red 의 정상 시작 상태)
sed -i '' 's/super::add/super::subtract/' src/lib.rs
cargo nextest run --profile ci; echo "exit=$?"                            # → 101
stat -f %m target/nextest/ci/junit.xml                                    # → mtime 불변
python3 verdict.py target/nextest/ci/junit.xml                            # → 낡은 RED
```

**실측 환경**: node v24.13.0 / vitest 3.2.7 / npm 11.6.2 / cargo 1.97.1 (2026-06-30) / cargo-nextest 0.9.140 (2026-07-05) / aarch64-apple-darwin.

**실행 기록 (정확히)**:
- **단일 스윕 1회, 조건 10개**(pass·fail·empty·filter-hit·filter-miss × TS·Rust)를 **각각 별도 파일로 보존**한 뒤 파서를 한 번에 돌려 **10/10 일치**를 확인했다
- **§4.3·§4.4의 조건(컴파일 실패, import 오류)은 그 스윕에 포함되지 않는다** — 별도 실행이며 위 10건과 합산하지 않는다
- 초기 탐색 과정에서 같은 크레이트를 재사용해 `junit.xml`이 덮어써진 적이 있다. **위 10/10은 그 상태가 아니라 보존 사본에 대한 재실행 결과다** — 그리고 그 덮어쓰기 사고 자체가 §4.3의 발견 계기였다

---

## 부록 B — 출처 등급

| 등급 | 출처 |
|---|---|
| **1차 실측 (이 조사)** | vitest × cargo-nextest 종료 코드·JUnit XML·필터 동작, 조건 10개 (부록 A) |
| **1차 (공식)** | [Bazel Test Encyclopedia](https://bazel.build/reference/test-encyclopedia), [Nx Executors](https://nx.dev/docs/concepts/executors-and-configurations), [pre-commit](https://pre-commit.com/), [moon toolchain](https://moonrepo.dev/docs/concepts/toolchain), [cargo-nextest JUnit](https://nexte.st/docs/machine-readable/junit/), [SWE-bench Multilingual](https://www.swebench.com/multilingual.html), [agents.md](https://agents.md/) |
| **1차 (저장소)** | [multi-swe-bench](https://github.com/multi-swe-bench/multi-swe-bench) |
| **선행 실측 (이 시리즈)** | [repository-layout](repository-layout.md) §7·§9·§10 |
| **인용하지 않음** | JUnit XSD 세부(2차 요약만 확보), SWE-Bench++의 파서 LLM 생성 서술(본문 미확인), Trunk·Mergify 등 벤더 블로그 |

**이 조사가 재지 않은 것**: pytest(§9-1), Bazel 실행, moon 태스크 정의 문법, JUnit XML 스키마 원문, 언어별 로그 파서 작성 비용.
