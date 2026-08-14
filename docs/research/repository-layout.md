# 저장소 레이아웃 — 모노레포 고정 가정에 대한 조사

**최초 작성**: 2026-08-03
**최종 수정**: 2026-08-09
**대상 프로젝트**: grid fin (신규 개인용 개발 하네스)
**조사 계기**: *"개발환경을 프론트엔드와 백엔드를 모두 포함하는 모노레포로 구성하고, 단일 프로젝트도 모노레포로 구성해 하네스가 다루는 케이스를 단순화한다"* 는 가정의 근거 확인
**조사 도구**: Exa `/search` 6회, Firecrawl `/v1/scrape` 4회, GitHub API 1차 검증 1회
**성격**: 조사. 레이아웃 결정은 하지 않는다. 사용자 답변으로 확정된 전제는 §6-2·§6-3에 **입력으로** 기록한다.

선행 조사 13건에 **저장소 레이아웃 축이 없다.** `grep -i "모노레포\|monorepo\|workspace"` 결과는 전부 Codex 샌드박스 모드(`workspace-write`)의 오탐이었다. 이 문서가 그 공백을 메운다.

관련 문서
- [verification-and-cross-review.md](verification-and-cross-review.md) §1.2 — 완료 게이트 5종의 `pnpm` 하드코딩
- [instruction-layers.md](instruction-layers.md) — 상시/온디맨드 지시 계층
- [harness-distribution.md](harness-distribution.md) — Copier 핀과 배포 단위

---

## 0. 조사 요약

| # | 관측 | 근거 등급 |
|---|---|---|
| 1 | **Claude Code 공식 문서가 모노레포를 명명된 케이스로 다룬다.** 하위 디렉터리 `CLAUDE.md`는 온디맨드 로드되고, `claudeMdExcludes`가 모노레포용으로 문서화되어 있다 | **1차 (공식)** — §1 |
| 2 | **Turborepo는 single-package workspace를 1급 지원한다.** 못 쓰는 것은 패키지 태스크 문법(`app#build`)뿐이다 | **1차 (공식)** — §2.1 |
| 3 | **Nx는 standalone을 1급 모드로 두고 `convert-to-monorepo` 생성기를 제공한다** — 생태계가 "처음부터 워크스페이스" 전제를 공유하지 않는다는 반대 신호 | **1차 (공식)** — §2.2 |
| 4 | **그러나 수동 변환은 14단계다.** 나중에 옮기는 비용이 0이 아님을 같은 문서가 보인다 | **1차 (공식)** — §2.2 |
| 5 | **게이트 스코핑의 실물 답이 존재한다** — `turbo run --affected`(기본값 `--filter=...[main...HEAD]`), `nx affected` | **1차 (공식)** — §3 |
| 6 | **Nx 문서가 `build`/`test`/`lint`/`serve`를 "모든 프로젝트가 갖는 태스크"로 전제하고 `package.json` scripts를 자동 인식한다** | **1차 (공식)** — §4 |
| 7 | 에이전트가 모노레포에서 겪는 실패 모드는 "요청받지 않은 형제 패키지 수정"과 "소유 패키지 오인"으로 서술된다 | 자가출판. 구조적 주장만 | §5.1 |
| 8 | **"OpenAI 모노레포가 약 88개의 중첩 AGENTS.md를 갖는다"는 주장은 공개 저장소에서 확인되지 않는다** — `openai/codex`는 2개다 | **1차 검증 (이 조사)** — §5.2 |
| 9 | 솔로 개발자 모노레포 실패담이 드는 비용은 CI 시간 증가·연쇄 실패·프레임워크 일괄 업그레이드다 | **신뢰도 낮음. 수치 인용 금지** | §5.3 |

### 2026-08-03 보강 — §6 해소 과정에서 나온 관측

| # | 관측 | 근거 등급 |
|---|---|---|
| 10 | **`pnpm -r <script>`는 워크스페이스 저장소와 단일 패키지 저장소 양쪽에서 동작한다.** 게이트를 이 형태로 쓰면 저하가 우아하다. 반면 `--filter <name>`은 이름 규약에 의존해 저하되지 않는다 | **1차 실측** — §7.1 |
| 10b | **그러나 `pnpm -r`는 부분 부재에서 종료 코드 0으로 통과한다** — 스크립트 없는 패키지가 섞여 있으면 검증 없이 성공을 보고한다. 전면 부재는 exit 1로 잡힌다 | **1차 실측** — §7.1.1 |
| 11 | **워크스페이스 형태에서는 루트에 도구 바이너리가 생기지 않는다.** 루트에서 바이너리를 직접 부르는 게이트는 깨진다 | **1차 실측** — §7.1 |
| 12 | **`--affected`의 퇴화 경로가 둘이고 성질이 다르다.** shallow는 **경고를 낸다**(최초 기술 정정). 무증상인 쪽은 루트 `package.json`·lockfile 등 전역 의존성 변경이다 | **1차 실측** — §7.2 |
| 13 | **`.claude/settings.json`은 상위 디렉터리에서 상속되지 않는다** — CLAUDE.md와 규칙이 다르다. 루트에만 배포하면 하위에서 시작한 세션에 훅·권한이 적용되지 않는다 | **1차 (공식)** — §8.3 |
| 14 | **Nx `project.json`의 `targets`는 비JS 프로젝트를 위한 것이라고 공식 문서가 명시한다** — 다중 런타임에서 이름 계약을 유지할 경로 | **1차 (공식)** — §8.1 |
| 15 | 루트에서 세션을 시작하면 스킬이 *"수백 개로 누적될 수 있고"* 예산(컨텍스트의 1%)을 넘으면 **description이 최소 사용 순으로 드롭된다** — 절삭이 아니다 | **1차 (공식)** — §9.3 |

### 2026-08-03 2차 보강 — 열린 질문 8~10 해소 과정

| # | 관측 | 근거 등급 |
|---|---|---|
| 16 | **`settings.json` 비상속을 `claude -p`로 직접 확인했다.** 루트 설정은 하위 디렉터리 세션에 들어오지 않고, 하위 설정은 위로 새지 않는다 | **1차 실측** — §9.1 |
| 17 | **`settings.local.json`은 저장소 어디서 시작해도 로드된다** — 위치 독립적인 유일한 파일인데 **gitignore되어 유일하게 배포 불가**다. **그 위치 독립성은 git 저장소 경계에 묶인다** — `git init` 없는 디렉터리에서는 로드되지 않는다 | **1차 실측** — §9.1 |
| 18 | **Nx는 `package.json` 없는 Python·셸 프로젝트를 인식하고 `run-many -t test` 하나로 디스패치한다** — 이름 계약이 다중 런타임에서 성립 | **1차 실측** — §9.2 |
| 19 | **그러나 Nx는 전면 부재까지 exit 0으로 통과한다** (`No tasks were run`). `pnpm -r`은 그 경우 exit 1이다 | **1차 실측** — §9.2 |

### 2026-08-03 3차 보강 — 열린 질문 11~13

| # | 관측 | 근거 등급 |
|---|---|---|
| 20 | **"언어 중립 러너는 구조적으로 fail-open"은 틀렸다** — mise·moon은 전면 부재를 exit 1로 잡는다. **Nx만 예외**다 (관측 19의 일반화 정정) | **1차 실측** — §10.1 |
| 21 | **부분 부재는 네 러너 모두 exit 0이다** (`pnpm -r`·Nx·mise·moon). **러너를 바꿔서는 해결되지 않는 공통 결손**이며, §7.1.1의 run-count 단언 요구가 러너 무관하게 유효하다 | **1차 실측** — §10.1 |
| 22 | **mise는 신뢰하지 않은 설정 파일의 실행을 거부한다**(`mise trust` 필요). 배포 자동화에 마찰이 되는 방어 | **1차 실측** — §10.1 |
| 23 | **`settings.local.json`은 `~/.config/git/ignore`의 한 줄로 무시된다.** **그 줄이 없는 머신에서는 같은 파일이 추적된다** — 우회의 동작이 머신마다 갈린다 | **1차 실측** (그 줄의 생성 주체는 추론) — §10.2 |
| 24 | **실패 전파는 네 러너 모두 정상이나 종료 코드 의미가 갈린다** — `pnpm -r`·mise는 하위 코드를 그대로, Nx·moon은 1로 정규화한다 | **1차 실측** — §10.1 |

### 용어 충돌 경고

**Turborepo의 "single-package workspace"와 이 조사의 계기가 된 가정은 다른 것을 가리킨다.**

| 용어 | 형태 | 예 |
|---|---|---|
| Turborepo **single-package workspace** | 루트 자체가 패키지. 워크스페이스 선언 없음 | `create-next-app` 출력물 |
| Turborepo **multi-package workspace** | `pnpm-workspace.yaml` + `apps/`·`packages/` | 통상의 모노레포 |
| **가정이 말하는 "단일 프로젝트도 모노레포로"** | multi-package workspace인데 패키지가 하나 | `apps/web` 하나만 있는 워크스페이스 |

**세 번째 형태를 직접 다루는 1차 문서는 찾지 못했다.** §2.1의 Turborepo 문서는 첫 번째 형태를, §2.2의 Nx 문서는 첫 번째에서 두 번째로 가는 경로를 다룬다. 세 번째는 두 도구 모두 문법적으로 허용하지만 권장 대상으로 언급하지 않는다. **이 조사가 확인한 가장 중요한 한계다.**

---

## 구현 참조 자료 — 외부 자료 정리

### A. 플랫폼이 이미 아는 모노레포 사실 셋 — 1차, 공식

[Claude Code — Memory](https://code.claude.com/docs/en/memory) 원문 확인.

| 사실 | 원문 | 하네스에 주는 함의 |
|---|---|---|
| **로드 시점이 위치에 따라 다르다** | *"CLAUDE.md and CLAUDE.local.md files in the directory hierarchy **above** the working directory are loaded in full at launch. Files in **subdirectories load on demand** when Claude reads files in those directories."* | 패키지별 `CLAUDE.md`는 상시 예산을 먹지 않는다. 모노레포에서 지시를 패키지에 붙이는 것이 비용상 성립한다 |
| **모노레포 전용 설정이 있다** | *"In monorepos, use `claudeMdExcludes` to skip CLAUDE.md files from other teams that aren't relevant to your work."* | 플랫폼이 모노레포를 **명명된 케이스**로 인정하고 탈출구를 제공한다 |
| **경로 스코핑 기제가 별도로 있다** | `.claude/rules/` — *"scope instructions to specific file types or subdirectories"* | 패키지 경계와 규칙 경계를 정렬시킬 수 있다 |

부수 확인 — **파일당 200줄 목표**가 공식 권고다. [지시 계층 조사](instruction-layers.md)가 다룬 상시 로드 예산 문제와 같은 축이며, 그 문서의 200줄 권고와 일치한다.

> **이것이 이 조사의 가장 강한 발견이다.** 선행 조사 13건에 레이아웃 축이 없었지만, **플랫폼 문서에는 이미 모노레포 분기가 존재한다.** 하네스가 모노레포를 전제하든 안 하든 이 세 기제는 그대로 쓸 수 있다.

### B. 단일 패키지에 대한 도구별 공식 입장

| | Turborepo | Nx |
|---|---|---|
| 단일 프로젝트 지원 | **1급.** [전용 가이드 존재](https://turborepo.dev/docs/guides/single-package-workspaces) | **1급.** "Standalone Application — A repository with a single application" |
| 잃는 기능 | *"Features that don't work are ones that don't make sense in the context of a single package, like package tasks (`app#build`)"* | 미확인 |
| 유지되는 기능 | *"local and Remote Caching and task parallelization"* | 미확인 |
| 나중에 모노레포로 | 문서 없음 | **[`nx g convert-to-monorepo` 생성기 + 14단계 수동 절차](https://nx.dev/docs/guides/tips-n-tricks/standalone-to-monorepo)** |

**두 방향으로 읽힌다.**

- **가정에 반하는 쪽**: 두 도구 다 단일 프로젝트를 1급으로 지원한다. 워크스페이스 형태를 강제할 도구상의 이유가 없다. 캐시·병렬화 같은 주요 효용은 단일 패키지에서도 유지된다
- **가정을 지지하는 쪽**: Nx의 수동 변환 절차가 **14단계**다 — 설정 파일을 루트/프로젝트로 갈라 옮기고, `project.json`·`tsconfig`·`jest.config`·`vite.config`의 경로 속성을 전수 수정하고, e2e 프로젝트의 `implicitDependencies`까지 고친다. **지연 비용은 실재하고 작지 않다**

### C. 게이트 스코핑 — 실물 답이 있다

[Turborepo `run` 레퍼런스](https://turborepo.dev/docs/reference/run) 원문 확인.

```bash
turbo run build lint test --affected
```

| 항목 | 값 |
|---|---|
| 기본 동작 | `--filter=...[main...HEAD]` 와 동등 |
| 기본 립도 | **패키지 단위** — 패키지 내 파일 하나만 바뀌어도 그 패키지의 태스크 전부 선택 |
| 태스크 단위로 낮추기 | `futureFlags.affectedUsingTaskInputs` — 각 태스크의 `inputs` glob으로 필터 |
| 조합 | `--affected --filter=web` 은 **양쪽을 다 만족**하는 패키지만 |
| 베이스 재정의 | `TURBO_SCM_BASE` / `TURBO_SCM_HEAD` |
| **함정** | *"If the checkout is too shallow, then **all packages will be considered changed**"* — `--filter=blob:none --depth=0` 필요. **실측으로 두 개의 서로 다른 퇴화 경로를 분리했다 — §7.2** |

Nx 쪽 대응은 `nx affected -t build test`이며, **파일 변경이 아니라 실제 의존성 그래프를 읽는다**고 §5.1의 출처가 서술한다(자가출판, 미검증).

> **[검증·교차리뷰 §1.2](verification-and-cross-review.md)의 5게이트가 `pnpm` 하드코딩이라는 관측과 직결된다.** 모노레포를 전제하면 게이트는 `pnpm test`가 아니라 "무엇에 대해 test인가"를 답해야 한다. `--affected`가 그 답의 후보이고, 그 후보가 무력화되는 조건은 §7.2에서 실측했다.

### D. 스크립트 이름 계약 — 도구가 이미 전제하는 것

[Nx — Configuring tasks](https://nx.dev/docs/getting-started/tutorials/configuring-tasks) 원문:

> *"Every project needs tasks: `build`, `test`, `lint`, `serve`."*

그리고 **`package.json` scripts를 자동 인식한다** — *"The simplest way to define tasks is with `package.json` scripts. Nx picks these up automatically."* 비JS 프로젝트나 scripts를 퍼블리시하고 싶지 않은 경우에만 `project.json`의 `targets`로 뺀다.

의존 순서는 `nx.json`의 `targetDefaults`에서 선언한다.

```jsonc
{ "targetDefaults": { "build": { "dependsOn": ["^build"] } } }
```

[agents.md 공식 예시](https://agents.md/)도 같은 계약을 전제로 쓰여 있다 — `pnpm turbo run test --filter <project_name>`, 그리고 *"From the package root you can just call `pnpm test`."*

> **레이아웃보다 이쪽이 하네스의 케이스 수를 줄이는 축이다.** 모노레포 고정은 *배치*를 표준화하지만 *디스패치*(`pnpm -r test` / `pnpm --filter x test` / `turbo run test`)를 표준화하지 않는다. **"모든 작업 단위가 알려진 경로의 패키지이고 고정된 스크립트 집합을 노출한다"** 는 불변식이 케이스를 접는다. 모노레포는 그 불변식을 얻는 좋은 수단이지 불변식 자체가 아니다.

### E. 에이전트 × 모노레포 — 자가출판, 구조적 주장만

[AI Coding in a Monorepo](https://aitoolsguidebook.com/en/articles/ai-monorepo-coding-workflow/). **자가출판이며 수치·귀속은 §5.2에서 하나가 반증됐다.** 아래는 구조적 주장만 옮긴 것이다.

서술하는 실패 모드: 에이전트가 대상 패키지를 오인하거나, 요청받지 않은 형제 패키지를 "개선"한다. 근거로 드는 이유는 *"a dependency graph it cannot infer from folder names"* — **폴더 이름으로부터 의존 관계를 추론할 수 없다**는 것.

제시하는 대응 다섯 (전부 저자 주장):

1. 패키지마다 `AGENTS.md`, 각 항목에 **"의존해서는 안 되는 대상"** 을 명시 — 저자는 이쪽이 "의존하는 대상"보다 유용하다고 주장
2. 프롬프트에 대상과 **제외 목록**을 함께 명시
3. 검색 범위를 대상 패키지로 제한
4. 크로스 패키지 변경은 2단계 커밋 — 소비 측을 먼저 쓰고(빌드 실패 상태로 커밋) 제공 측을 나중에
5. 공개 API 변경 후 하위 소비자를 **명시적으로 되묻기**

**A와 겹치는 지점**: 1번의 nearest-file-wins 전제는 §A의 1차 문서가 확인해준다(하위 디렉터리 온디맨드 로드). **구조적 주장은 공식 문서와 정합한다.**

### F. 근거가 약하거나 반증된 것

| 주장 | 상태 |
|---|---|
| "OpenAI 모노레포가 약 88개 중첩 `AGENTS.md`를 갖는다" | **공개 저장소에서 확인 불가.** §5.2 — `openai/codex`는 **2개** |
| "솔로 개발자 모노레포 ROI는 0~10 서비스에서 최대" | **신뢰도 낮음.** 방법론 없음. §5.3 |
| "CI 2분 → 20분", "1분으로 복구" | **수치 인용 금지.** 출처 §5.3 |
| `nx affected`가 파일 변경이 아니라 그래프를 읽는다 | 자가출판 서술. Nx 공식 문서로 미검증 |

---

## 1. Claude Code의 모노레포 취급 — 1차 확인

§A가 요약한 세 사실은 [공식 memory 문서](https://code.claude.com/docs/en/memory) 원문에서 직접 확인했다.

로드 규칙이 **방향에 따라 비대칭**이라는 점이 설계상 중요하다.

| 위치 | 로드 |
|---|---|
| 작업 디렉터리 **상위** 계층 | 시작 시 **전문 로드** |
| **하위** 디렉터리 | 그 디렉터리 파일을 읽을 때 **온디맨드** |

모노레포 루트에서 세션을 열면 루트 `CLAUDE.md`만 상시 비용이고, `apps/web/CLAUDE.md`는 그 안의 파일을 건드릴 때만 들어온다. **패키지 수가 늘어도 상시 예산이 선형으로 늘지 않는다.** 반대로 `apps/web`에서 세션을 열면 루트가 전문 로드된다.

`claudeMdExcludes`의 존재는 별개 신호다 — 플랫폼이 **모노레포에서 남의 팀 `CLAUDE.md`가 섞여 들어오는 것**을 알려진 문제로 인정하고 탈출구를 뒀다는 뜻이다. 다중 사용자 환경을 염두에 둔 설정이며, 이 프로젝트의 "개발환경을 공유하는 사람" 조건과 같은 방향이다.

## 2. 도구들의 단일 프로젝트 입장

### 2.1 Turborepo — single-package workspace가 1급

> *"While Turborepo is highly effective in multi-package workspaces (commonly referred to as monorepos), it can also be used to make single-package workspaces faster. Turborepo's most important features work in single-package workspaces including local and Remote Caching and task parallelization. Features that don't work are ones that don't make sense in the context of a single package, like package tasks (`app#build`)."*

예로 드는 것이 `create-next-app`·`npm create vite` 출력물이다. 즉 **평범한 단일 앱 저장소**를 뜻하며, 워크스페이스 선언이 없는 형태다.

**함의**: 캐싱·병렬화를 얻으려고 워크스페이스 형태를 만들 필요는 없다. `turbo`는 루트 `package.json` scripts에 그대로 붙는다.

### 2.2 Nx — standalone과 monorepo가 별개 모드

[deprecated 페이지의 용어 정의](https://nx.dev/docs/reference/deprecated/integrated-vs-package-based)가 명시한다 — *"Standalone Application — A repository with a single application"*.

그리고 [standalone → monorepo 전환 가이드](https://nx.dev/docs/guides/tips-n-tricks/standalone-to-monorepo)가 별도로 존재한다. 전환 계기를 문서가 이렇게 쓴다 — *"at some point, you may want to move the primary app out of the root of your repo because the repo is no longer primarily focused on that one app."*

`nx g convert-to-monorepo` 생성기가 있고, **수동 절차는 14단계**다. 요지만 옮기면:

- 루트 `tsconfig.json`을 `tsconfig.old.json`으로 밀어내 `tsconfig.base.json` 생성을 유도
- `apps/temp`에 새 앱을 만들고 소스를 옮긴 뒤 이름을 바꾸는 우회 경로
- 설정 파일을 **루트 레벨/프로젝트 레벨로 분류** (문서가 "구분하기 어렵다"고 명시하고 비망라 목록을 제공)
- `project.json`의 `$schema`·`sourceRoot`·`root`·`outputPath`·`cypressConfig`·`lintFilePatterns`… 경로 속성 전수 수정
- e2e 프로젝트의 `implicitDependencies` 수정

**두 관측이 서로를 상쇄하지 않는다.** standalone이 1급이라는 사실은 "처음부터 워크스페이스"가 필수가 아님을 뜻하고, 14단계는 "나중에 옮기면 된다"가 공짜가 아님을 뜻한다. **가정을 지지하는 근거와 반대하는 근거가 같은 문서에서 나온다.**

## 3. 게이트 스코핑

§C 참조. 이 조사에서 유일하게 **비용 축**에 대한 1차 답을 준 부분이다.

모노레포를 전제하면 검증 게이트는 "전체를 돌 것인가, 바뀐 것만 돌 것인가"를 답해야 한다. `--affected`가 후보이고, 세 가지가 딸려 온다.

1. **기본 립도가 패키지 단위다** — 패키지 내 아무 파일이나 바뀌면 그 패키지 태스크 전부가 선택된다. 태스크 단위로 낮추려면 future flag가 필요하다
2. **퇴화 경로가 둘이고 성질이 다르다** — **§7.2에서 실측했다.** shallow 쪽은 경고를 내고, 전역 의존성 쪽은 무증상이다. [배포 조사](harness-distribution.md) §B의 "gitignore 하에서 3-way merge가 덮어쓰기로 퇴화"에 대응하는 것은 **후자**다
3. **base/head를 환경변수로 덮을 수 있다** — 하네스가 토픽 브랜치 기준을 주입할 여지

## 4. 스크립트 이름 계약

§D 참조.

## 5. 자가출판 출처들

### 5.1 에이전트 × 모노레포 실패 모드

§E 참조. **구조적 주장만 사용 가능하다.**

### 5.2 1차 검증 — "88개 AGENTS.md" 주장

§5.1의 출처가 이렇게 쓴다.

> *"OpenAI's own monorepo ships roughly 88 nested `AGENTS.md` files — one per significant package."*

**저장소 이름을 밝히지 않았다.** 공개 `openai/codex`의 트리를 GitHub API로 직접 조회했다.

```
GET /repos/openai/codex               → default_branch: "main"
GET /repos/openai/codex/git/trees/main?recursive=1
→ truncated: false, 트리 엔트리 6,723개
→ AGENTS.md: ["AGENTS.md", "codex-rs/tui/src/bottom_pane/AGENTS.md"]
```

**2개다.** `truncated: false`를 함께 확인했다 — GitHub 트리 API는 응답이 한계를 넘으면 조용히 잘린 목록을 돌려주므로, 이 확인 없이는 "2개"라는 수치 자체가 §5.3에서 경계한 것과 같은 종류의 미검증 수치가 된다.

**"거짓"이 아니라 "확인 불가 / 귀속 불명"으로 분류한다.** OpenAI의 내부 모노레포는 공개되어 있지 않으므로 그 저장소를 가리켰다면 반증할 수단이 없다. 그러나 **공개 저장소로 확인 가능한 형태로 쓰이지 않았고, 이름을 밝히지 않은 채 수치만 제시했다.** [워크플로우 조사 §4.1](workflow-and-feature-list.md)의 Guo et al. 정정과 같은 처리다 — 2차 인용의 수치는 원문 확인 전까지 쓰지 않는다.

**nearest-file-wins라는 구조적 주장 자체는 §1의 1차 문서가 지지한다.** 반증된 것은 규모의 근거다.

### 5.3 솔로 개발자 모노레포 회고 — 신뢰도 낮음

[graxel.ai 회고](https://graxel.ai/en/blog/monorepo-vs-multirepo-solo-dev-retro)가 pnpm workspaces + Turborepo로 전 프로젝트를 통합했다가 일부를 되돌린 경험을 서술한다.

**이 출처를 낮게 잡는 이유**: 문체가 기계 생성/SEO 산출물의 특징을 보인다("traumatizing", "excruciating", "blazing fast", 형용사 중첩). 제시하는 수치("2분 → 20분", "0~10 서비스")에 방법론·측정 조건이 없다. **수치는 인용하지 않는다.**

**실패 유형만** 다른 근거와 대조 가능한 형태로 남긴다.

| 서술된 유형 | 이 프로젝트에 걸리는가 |
|---|---|
| 말단 패키지의 오류가 루트 빌드를 깨뜨림 | **걸린다.** §3의 `--affected` 스코핑이 완화책 |
| CI 시간 증가 | **걸린다.** 같은 완화책 |
| 프레임워크 일괄 업그레이드 강제 | **걸린다.** 잠금 단계가 하나면 회피 불가 |
| 이질 스택(Python)을 Node 중심 워크스페이스에 욱여넣음 | **조건부.** FE+BE가 같은 런타임이면 미해당 |

마지막 항목은 검토할 값어치가 있다 — **가정이 "FE와 BE를 모두 포함"이라고만 하고 BE의 런타임을 특정하지 않았다.** BE가 Node가 아니면 pnpm 워크스페이스가 BE를 패키지로 인식할 근거가 사라진다.

---

## 6. 열린 질문

> **2026-08-03 갱신.** 항목 번호는 유지한다 — 이 문서를 §번호로 참조하는 곳이 생기면 재번호가 그 링크를 조용히 깨뜨린다. 해소된 항목은 그대로 두고 표시만 붙인다.

1. ~~**패키지가 하나인 multi-package workspace의 실비용이 얼마인가.**~~ **해소 — §7.1.** 실측 결과 비용은 셋이다: 루트에서 `pnpm test`가 실패하고(`-r` 필요), 루트에 도구 바이너리가 생기지 않으며, 추적 설정 파일이 3개에서 5개로 는다. **`pnpm -r`는 두 형태 모두에서 동작하므로 게이트를 그 형태로 쓰면 저하가 우아하다.** 남은 미측정: 패키지가 여럿일 때의 호이스팅 동작, `tsconfig` 경로 매핑.
2. ~~**모노레포는 하네스가 강제하는 전제조건인가, 선호하는 기본값인가.**~~ **해소 — 2026-08-03 사용자 결정: 선호하는 기본값(우아한 저하).** §2.2가 보인 생태계 표준(Nx standalone, Turborepo single-package가 각각 1급)과 정렬되고, §7.1이 `pnpm -r` 수준에서 그 저하가 실제로 성립함을 보였다.
3. ~~**BE의 런타임이 무엇인가.**~~ **해소 — 2026-08-03 사용자 답: Node/TypeScript 주력, Python·Rust 배제 안 함.** 따라서 **단일 런타임 가정을 쓸 수 없다.** §7.1의 우아한 저하는 JS/TS 서브트리에만 적용되고, §5.3이 인용한 "이질 스택을 Node 중심 워크스페이스에 욱여넣는" 실패 유형이 **조건부가 아니라 실제 가능 조건**이 된다. 항목 5가 이 답에 직접 걸린다.
4. ~~**`--affected`의 조용한 퇴화를 어떻게 검출하는가.**~~ **해소 — §7.2.** 퇴화 경로가 둘이고 성질이 다르다. **shallow는 경고를 내므로 "조용한 퇴화"라는 최초 기술이 틀렸다**(정정 완료). 경고가 없는 쪽은 전역 의존성(루트 `package.json`·lockfile) 변경이며, 그쪽은 **선택된 패키지 목록을 게이트가 직접 읽고 대조하는 것 말고 검출 수단이 없다.**
5. ~~**스크립트 이름 계약을 하네스가 강제할 수 있는가.**~~ **해소 — §8.1.** Q3의 다중 런타임 답 때문에 `package.json` scripts는 계약 지점이 될 수 없다. **Nx `project.json`의 `targets`가 비JS 프로젝트용이라고 공식 문서가 명시**하므로 이름 계약을 유지하며 실행 주체만 언어별로 바꾸는 경로가 있다. mise·moon이 대안 후보다. **셋 다 실행해보지 않았으므로 후보 목록까지가 결론이다.**
6. ~~**패키지 경계를 립도 기준으로 쓸 수 있는가.**~~ **부분 해소 — §8.2.** 조작 가능성 축에서는 확실히 낫다(`--affected`가 이미 답을 낸다). 그러나 **크기 기준을 대체하지 못한다** — 패키지는 실측 중심값 24~44줄보다 훨씬 크고, §7.2가 루트 파일 한 줄 변경으로 전 패키지가 잡히는 구간을 보였다. 둘은 직교하는 제약이다. **남는 질문: 범위 제약과 크기 제약이 충돌할 때 무엇이 우선인가.**
7. ~~**`claudeMdExcludes`가 하네스 배포와 어떻게 상호작용하는가.**~~ **해소 — §8.3, 범위가 예상보다 넓다.** 배포한 CLAUDE.md는 프로젝트가 exclude로 무력화할 수 있고 이를 막는 계층(managed policy)은 저장소 배포 대상 밖이다. **그리고 더 근본적으로 `.claude/settings.json`은 상위 디렉터리에서 상속되지 않는다** — 루트에만 배포하면 하위 디렉터리에서 시작한 세션에 훅·권한이 적용되지 않는다.

**2026-08-03 시점에 새로 열린 질문**

8. ~~**배포 단위가 저장소인가 세션 시작 지점인가.**~~ **해소 — §9.1, 실측.** `claude -p`로 4행을 측정해 문서 서술을 확인했다. **위치 독립적으로 로드되는 유일한 파일(`settings.local.json`)이 유일하게 배포 불가인 파일**이라는 딜레마가 드러났다. 선택지 셋(루트 전용+규약 / 패키지별 자기완결 사본 / 사용자 수준)과 각각이 포기하는 것을 정리했고, **고르지는 않았다.**
9. ~~**§8.1의 후보 셋 중 무엇이 실제로 동작하는가.**~~ **부분 해소 — §9.2.** **Nx만 실측했다.** `package.json` 없는 Python·셸 프로젝트를 인식하고 `run-many -t test` 하나로 디스패치한다 — 이름 계약이 다중 런타임에서 성립한다. 다만 **전면 부재까지 exit 0으로 통과**해 `pnpm -r`보다 fail-open이 넓다. **mise·moon은 바이너리 미설치로 재지 않았다.**
10. ~~**스킬 description 절삭이 실제로 언제 시작되는가.**~~ **해소 — §9.3.** 예산은 **컨텍스트 윈도우의 1%**, 항목당 상한 **1,536자**. **절삭이 아니라 최소 사용 순 드롭**이며(§8.3 기술 정정), `skillListingBudgetFraction`·`skillOverrides` 등으로 조정한다.

**2026-08-03 2차 보강 시점에 새로 열린 질문**

11. ~~**`settings.local.json`의 위치 독립성을 배포에 쓸 수 있는가.**~~ **해소 — §10.2. 순이득이 아니고, 2026-08-09 정정으로 「위치 독립성」 자체가 실측 반증됐다.** 생성물이 전역 gitignore로 무시되어 3-way merge가 덮어쓰기로 퇴화하고 핀이 붙지 않는다. **게다가 그 무시 줄은 Claude Code가 그 머신에서 설정을 저장한 적이 있어야 생기므로, 공유자 머신에서는 같은 파일이 추적될 수 있다** — 환경에 따라 동작이 갈리는 배포물이 된다.
12. ~~**mise·moon의 실측.**~~ **해소 — §10.1.** 셋 다 언어 중립 디스패치가 성립한다. **그리고 §9.2의 일반화가 틀렸음이 확인됐다** — mise·moon은 전면 부재를 exit 1로 잡고 **Nx만 놓친다.** 부분 부재는 넷 모두 exit 0이므로 §7.1.1의 요구는 러너 선택으로 해결되지 않는다.
13. **하네스가 배포하는 스킬 수가 예산 구간에 드는가.** **보류 — §10.3.** 예산이 "컨텍스트 윈도우의 1%"인데 **문자↔토큰 환산 규칙이 문서에 없고**, grid fin에 셀 스킬이 아직 없다. 이 머신을 재는 것은 §9.3에서 하지 않기로 한 것과 같은 이유로 하지 않는다. **grid fin이 스킬을 배포하기 시작한 뒤에 측정 가능해진다.**

---

## 7. 실측 — 2026-08-03 보강

> **이 절은 최초 작성 시 없었다.** §6의 열린 질문을 해소하려고 직접 실행한 실험이며, 재현 스크립트는 부록 B에 있다. **§3 항목 2의 기술 하나를 정정한다.**
>
> 환경: pnpm 10.33.0 / node v24.13.0 / git 2.50.1 / turbo 2.5.6 / macOS(darwin 25.5.0)

### 7.1 단일 패키지 워크스페이스의 실비용 — §6-1 해소

**baseline**(`pnpm-workspace.yaml` 없는 단일 패키지) 대 **variant**(엔트리 하나짜리 워크스페이스, `apps/web` 단독)를 만들어 비교했다. 양쪽 다 `typescript@5.9.2` 하나를 devDependency로 두고 `build`/`test`/`lint` 스크립트를 같게 뒀다.

| 측정 | baseline | variant |
|---|---|---|
| `cd <루트> && pnpm test` | **exit 0** | **exit 1** — 루트 `package.json`에 스크립트가 없다 |
| `pnpm -r test` | **exit 0** | **exit 0** |
| `pnpm --filter web test` | **exit 0** | **exit 0** |
| 루트 `node_modules/.bin/tsc` | **있음** | **없음** |
| 도구 바이너리 위치 | 루트 | `apps/web/node_modules/`(심볼릭 링크) |
| 추적 대상 설정 파일 | 3개 | 5개 (`pnpm-workspace.yaml` + 루트 `package.json` 분리) |

**결론 셋.**

1. **`pnpm -r <script>` 는 두 형태 모두에서 동작한다.** baseline에 워크스페이스 선언이 없어도 pnpm이 루트 패키지 자신을 대상으로 재귀 실행한다. **Q2의 "우아한 저하"가 pnpm 레벨에서 공짜로 성립한다** — 하네스 게이트를 `pnpm -r test` 형태로 쓰면 워크스페이스 여부를 몰라도 된다. **단 아래 §7.1.1의 단서가 붙는다.**
2. **`--filter <name>` 은 우아하게 저하되지 않는다.** baseline에서 통한 것은 **루트 패키지 이름이 우연히 `web`이었기 때문**이다. 이름 규약에 의존하므로 게이트의 기반으로 삼을 수 없다. **`-r` 는 이름에 의존하지 않는다.**
3. **variant는 루트에 도구 바이너리가 없다.** `node_modules/.bin/tsc`가 루트에 생기지 않고 패키지 안에만 심볼릭 링크된다. **저장소 루트에서 바이너리를 직접 호출하는 게이트는 워크스페이스 형태에서 깨진다.** [검증·교차리뷰 §1.2](verification-and-cross-review.md)가 지적한 `pnpm` 하드코딩 문제의 구체적 실례를 측정한 것이다.

#### 7.1.1 `pnpm -r`는 부분 부재에서 조용히 통과한다

결론 1을 게이트의 근거로 쓰려면 **스크립트가 없는 패키지를 어떻게 다루는지**를 알아야 한다. 워크스페이스에 `test`를 가진 패키지(`web`)와 갖지 않은 패키지(`api`)를 두고 측정했다.

| 상황 | 종료 코드 | 출력 |
|---|---|---|
| 일부 패키지에만 스크립트 있음 | **0** | `Scope: 2 of 3 workspace projects` — 있는 것만 실행 |
| **어느 패키지에도 없음** | **1** | `ERR_PNPM_RECURSIVE_RUN_NO_SCRIPT  None of the selected packages has a "typecheck" script` |
| 단일 패키지 저장소에서 없음 | **1** | 같은 에러 |
| 스크립트가 실제로 실패 | **3** | 하위 종료 코드가 그대로 전파된다 |

**두 성질이 갈린다.**

- **전면 부재는 잡힌다** — 완전한 fail-open이 아니다. 계약을 아무도 지키지 않으면 게이트가 즉시 실패한다
- **부분 부재는 통과한다** — `api`가 `test`를 갖지 않아도 종료 코드는 0이다. **검증되지 않은 패키지가 있는 상태에서 게이트가 성공을 보고한다**

**§7.2 경로 B와 같은 성질의 결손이다** — 신호 없이 결과만 달라진다. 다만 방향이 반대다. 경로 B는 필요 이상으로 많이 실행하고(과잉), 이쪽은 필요한 것을 실행하지 않고 통과한다(누락).

**따라서 `pnpm -r <script>` 단독은 완료 게이트로 불충분하다.** 종료 코드 위에 **"몇 개 패키지에서 실제로 돌았는가"를 기대값과 대조하는 단언**이 필요하다. pnpm이 `Scope: N of M workspace projects`를 출력하므로 재료는 있다. 이것이 §8.1의 스크립트 이름 계약이 **선언만으로 부족하고 검증까지 있어야 하는** 이유다.

**적용 범위 한계**: `pnpm -r`가 닿는 것은 **JS/TS 서브트리뿐**이다. Q3의 답이 "Node 주력, Python·Rust 배제 안 함"이므로 이 우아한 저하는 저장소의 일부에만 적용된다. §6-5가 `package.json` scripts에 안착할 수 없는 이유가 여기서 나온다.

### 7.2 `--affected`의 퇴화 경로는 둘이고 성질이 다르다 — §6-4 해소, §3 정정

2패키지 워크스페이스(`apps/a`, `apps/b`)에 git 이력을 만들고, `apps/a`만 수정한 `feat` 브랜치에서 `turbo run test --affected`가 무엇을 선택하는지 관측했다.

**정상 동작 확인** — 전체 이력 클론에서 `apps/a`만 선택된다(`Packages in scope: //, a`). `TURBO_SCM_BASE=main`을 명시하거나 `--filter='...[main...HEAD]'`로 쓴 경우와 결과가 같다. **문서가 기술한 기본값이 실제와 일치한다.**

**퇴화 경로 A — base 도달 불가.** `git clone --depth=1 --branch feat --single-branch`로 받아 로컬에 `main`도 `origin/main`도 없는 상태:

```
WARNING  unable to detect git range, assuming all files have changed:
         Unable to resolve base branch. Please set with `TURBO_SCM_BASE`.
• Packages in scope: //, a, b
 Tasks:    2 successful, 2 total     ← 전량 실행
```

**경고가 나온다. 조용하지 않다.** 최초 작성 시 §3 항목 2를 "조용한 퇴화"로 기술했으나 **틀렸다.** 다만 **종료 코드는 0**이므로 종료 코드만 읽는 게이트는 이를 구분할 수 없다.

**퇴화 경로 B — 전역 의존성 변경.** 경고가 전혀 없는 쪽은 이쪽이다.

| 변경 대상 | 선택 결과 | 경고 |
|---|---|---|
| 변경 없음 (기준선) | `a` | — |
| 미추적 파일 (루트) | `a` | — |
| 미추적 파일 (`apps/b` 안) | `a, b` | 없음 |
| 추적 파일 수정 (`apps/b`, 미커밋) | `a, b` | 없음 |
| **추적된 루트 `.gitignore` 수정** | **`a`** | — |
| **추적된 루트 `package.json` 수정** | **`a, b`** | **없음** |
| **미추적 `pnpm-lock.yaml` 노출** | **`a, b`** | **없음** |

**읽는 법 둘.**

- `--affected`는 **커밋되지 않은 변경도 포함한다** — 미커밋 수정과 패키지 내 미추적 파일이 그 패키지를 선택시킨다. 합리적 동작이며 함정이 아니다
- 루트 파일은 **전부가 아니라 일부만** 전역 의존성으로 취급된다. `package.json`·lockfile은 전량을 유발하고 `.gitignore`는 유발하지 않는다. **전량 유발 시 아무 신호도 없다**

> **교란 제거 기록.** 최초 관측에서 미추적 lockfile 노출과 `.gitignore` 수정이 동시에 걸려 있어 어느 쪽이 원인인지 갈리지 않았다. `.gitignore` 단독 수정(→`a`)과 루트 `package.json` 단독 수정(→`a, b`)을 각각 돌려 lockfile·`package.json` 쪽이 원인임을 분리했다.

**§3 항목 2의 유비를 재지정한다.** [배포 조사 §B](harness-distribution.md)의 "gitignore 하에서 3-way merge가 경고 없이 덮어쓰기로 퇴화"에 대응하는 것은 **shallow가 아니라 경로 B**다. 두 경우 모두 **신호가 전혀 없고 결과만 조용히 달라진다.** shallow 쪽은 경고가 나오므로 성질이 다르다.

**검출 가능성**: 경로 A는 stderr에 문자열이 나오므로 게이트가 잡을 수 있으나 종료 코드로는 불가능하다. 경로 B는 stderr에도 나오지 않으므로 **선택된 패키지 목록 자체를 게이트가 읽고 기대와 대조하는 방법 말고는 검출 수단이 없다.**

---

## 8. 문헌·분석 — 2026-08-03 보강

> §7이 직접 실행한 실험이라면 이 절은 **문서 조사와 분석**이다. §6의 남은 항목 셋을 다룬다.

### 8.1 스크립트 이름 계약을 어디에 세울 수 있는가 — §6-5 해소

**Q3의 답(Node 주력, Python·Rust 배제 안 함)이 `package.json` scripts를 계약 지점에서 탈락시킨다.** §7.1이 측정한 `pnpm -r`의 우아한 저하는 JS/TS 서브트리에만 닿는다.

선택지를 계약이 걸리는 지점 기준으로 정리한다.

| 지점 | 언어 중립 | 모노레포 인식 | 확인 수준 |
|---|---|---|---|
| `package.json` scripts | ✗ JS/TS만 | pnpm/turbo/Nx가 인식 | **1차** — Nx가 자동 인식(§D) |
| **Nx `project.json` targets** | **✓ 명시 지원** | ✓ | **1차** — *"or for non-JavaScript projects, define tasks in a `project.json` file using the `targets` property"* |
| **mise `mise.toml` tasks** | **✓ 설계 목적** | ✓ `monorepo_root` + `//`·`:` 경로 문법 | 벤더 문서 |
| moon | ✓ (JS·TS·Rust·Go·Ruby 표방) | ✓ | 벤더 마케팅 페이지만 |
| Make / just / Taskfile | ✓ | **✗** | 벤더 비교 서술 |

**두 가지가 확인된다.**

1. **Nx는 이 문제를 이미 공식적으로 인정하고 탈출구를 뒀다.** `project.json`의 `targets`가 비JS 프로젝트를 위한 것이라고 문서가 직접 밝힌다. 즉 **`build`/`test`/`lint` 라는 이름 계약은 유지하면서 실행 주체만 언어별로 바꿀 수 있다.** §D의 불변식이 다중 런타임에서도 성립할 경로가 있다는 뜻이다
2. **mise는 언어 중립을 설계 목적으로 내세운다.** `monorepo_root`를 켜면 하위 `mise.toml`을 자동 발견해 경로 접두어를 붙인 통합 태스크 네임스페이스를 만든다

> **출처 주의**: mise 문서의 비교표(`Multi-language support` 축에서 JS 도구들이 ✗)는 **mise 자신이 작성한 경쟁 제품 비교**다. 자기 제품이 모든 축에서 우위인 표이므로 **선택 근거가 아니라 후보 목록으로만** 쓴다. moon은 마케팅 페이지의 표방만 봤고 실제 다언어 지원 범위를 확인하지 않았다.

**Make/just/Taskfile 계열이 탈락하는 이유**는 언어 때문이 아니라 **모노레포를 위해 설계되지 않았다**는 쪽이다 — 통합 태스크 발견, 교차 프로젝트 와일드카드, 도구·환경 계층화가 없다. 이 서술 역시 mise 문서 것이므로 등급을 낮춰 읽는다.

**남는 것**: 셋 중 무엇도 실행해보지 않았다. §7.1이 pnpm에 한 수준의 실측을 하지 않았으므로 **후보 목록까지가 이 조사의 결론**이다.

### 8.2 패키지 경계를 립도 기준으로 쓸 수 있는가 — §6-6 부분 해소

[워크플로우 조사 §8-10](workflow-and-feature-list.md)이 남긴 질문은 *"한 세션에 완료 가능한"* 이 조작 불가능하다는 것이었고, 실측 중심값은 **24~44줄 / 1~5파일**(Rigby & Bird 2013, Sadowski et al. 2018)이었다.

**"어느 패키지를 건드리는가"는 조작 가능성 축에서 확실히 낫다.**

| 기준 | 기계 판정 | 판정 시점 |
|---|---|---|
| "한 세션에 완료 가능한" | **불가** — 컨텍스트 크기·모델·작업 종류에 따라 달라진다 | 사후에만 |
| "몇 개 패키지를 건드리는가" | **가능** — `git diff --name-only`, `turbo run --affected`가 이미 답을 낸다 | **작업 중 상시** |

**그러나 크기 기준을 대체하지는 못한다.** 두 근거가 있다.

1. **패키지는 24~44줄보다 훨씬 크다.** Sadowski et al.의 표본에서 **35%가 단일 파일**이고 90%가 10파일 미만이었다. 패키지 하나는 보통 그보다 크므로, "1개 패키지 안에서"는 실측 중심값을 **한참 초과하는 상한**이다
2. **§7.2가 이 기준의 불안정성을 보였다.** 루트 `package.json` 한 줄만 바꿔도 전 패키지가 affected로 잡힌다. **건드린 패키지 수가 작업 크기에 비례하지 않는 구간이 실재한다**

**결론**: 패키지 경계는 **크기 기준과 직교하는 별개의 제약**이다. 크기 기준을 대체하는 것이 아니라 그 위에 얹히는 것이다.

- "N개 패키지 이내" → **범위 제약**. 크로스 패키지 변경을 억제하고, §E가 서술한 "요청받지 않은 형제 패키지 수정" 실패 모드에 직접 대응한다
- "N줄 / N파일 이내" → **크기 제약**. 리뷰 가능성에 대한 실측 근거가 있는 쪽이다

**남는 질문**: 둘이 충돌할 때 무엇이 우선인가. 3개 패키지에 걸친 10줄 변경과 1개 패키지 안의 300줄 변경 중 어느 쪽이 더 나쁜지에 대한 근거를 찾지 못했다. 워크플로우 조사 §8-10의 (c)와 같은 형태의 미해결이다.

### 8.3 `claudeMdExcludes`와 배포의 상호작용 — §6-7 해소, 범위가 예상보다 넓다

이 항목을 확인하는 과정에서 **모노레포 전용 공식 가이드**([Monorepos and large repos](https://code.claude.com/docs/en/large-codebases))를 발견했다. §A가 memory 문서 한 줄로 잡았던 것이 전용 페이지로 존재한다.

**먼저 원래 질문의 답.**

| 항목 | 확인된 값 |
|---|---|
| 형식 | 글롭 패턴 **또는** 절대 경로. **절대 파일 경로에 매칭**되므로 상대형 패턴은 `**/`로 시작해야 한다 |
| 설정 가능 스코프 | user / project / local / managed **전부** |
| 스코프 간 동작 | **배열이 병합된다** — 프로젝트가 기본값을 두고 개인이 로컬에서 **추가**할 수 있다 |
| 제외 불가 대상 | **managed policy CLAUDE.md** |
| 성격 | *"The exclusion list is static, not a per-task switch"* — 작업별 전환용이 아니다 |

**배포와 어긋나는 지점**: Copier로 배포한 core의 `CLAUDE.md`는 **프로젝트가 `claudeMdExcludes`로 무력화할 수 있다.** 배열이 병합만 되므로 core가 심은 exclude를 프로젝트가 **제거**할 수는 없지만, core가 심은 **CLAUDE.md 자체를 제외**하는 것은 가능하다. 이를 막는 유일한 계층이 managed policy인데, 그 파일은 시스템 경로(`/Library/Application Support/ClaudeCode/CLAUDE.md` 등)에 있어 **저장소 배포 대상 밖**이다. [배포 조사](harness-distribution.md)가 다룬 Copier 경로로는 도달할 수 없다.

**그런데 더 큰 사실이 같은 문서에 있다.**

> *"Project settings in `.claude/settings.json` load only from your starting directory and are not inherited from parent directories the way CLAUDE.md files are."*
>
> *"each subdirectory's `.claude/settings.json` must be self-contained rather than layered on a root file."*

**`CLAUDE.md`와 `.claude/settings.json`의 상속 규칙이 다르다.** CLAUDE.md는 상위 계층이 전부 로드되지만 `settings.json`은 **시작 디렉터리 것만** 로드된다.

**하네스 배포에 직접 걸린다** — 루트에만 `.claude/settings.json`을 배포하면, 개발자가 `apps/web/`에서 세션을 시작하는 순간 **훅·권한 규칙·검증 게이트가 전부 적용되지 않는다.** [강제 메커니즘 조사](enforcement-mechanisms.md)가 다룬 훅 기반 강제가 통째로 무력화되는 경로이며, 그 조사에는 이 조건이 없다.

예외가 하나 있다 — **`.claude/settings.local.json`은 v2.1.211 이상에서 저장소 내 어디서 시작하든 로드된다.** 다만 이름 그대로 로컬 파일이고 Claude Code가 전역 gitignore에 넣으므로 **배포 대상으로 삼을 수 없다.**

**부수 확인 넷** (같은 문서, 전부 1차):

1. **스킬 스코프가 시작 위치에 따라 갈린다** — 루트에서 시작하면 *"skills from every subdirectory Claude touches during the session, which can accumulate into the hundreds"*. 그리고 개수가 많아지면 description이 소실돼 라우팅 키워드가 사라진다. [지시 계층 조사 §1.2](instruction-layers.md)가 열린 질문으로 남긴 *"`learned/` 중첩 스킬이 목록에 노출되는가"* 와 같은 축이며, **노출되고 비용이 든다**는 쪽으로 답이 기운다. **소실 방식은 §9.3에서 정정했다 — 절삭이 아니라 최소 사용 순 드롭이다**
2. **스킬에 `paths` frontmatter 글롭 스코핑이 있다** — 배치가 아니라 파일 패턴으로 스코프를 정할 수 있다
3. **`worktree.sparsePaths`** — 워크트리에 특정 디렉터리만 체크아웃한다. **`.claude`를 목록에 넣지 않으면 워크트리 안에서 루트 `.claude/`가 통째로 사라진다.** `symlinkDirectories`로 `node_modules` 중복을 피한다. 서브에이전트 워크트리 격리와 직결된다
4. **`additionalDirectories`와 `--add-dir`의 로드 규칙이 다르다** — 전자는 CLAUDE.md·규칙·스킬을 **절대 로드하지 않고** 파일 접근만 준다. 후자는 스킬을 로드하고, CLAUDE.md는 `CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=1` 이 있어야 로드한다

> **이 절이 이 조사에서 가장 넓게 파급된다.** 원래 질문은 "exclude가 배포와 어긋나는가"였는데, 답은 **"어긋난다. 그리고 더 근본적으로 `settings.json`의 상속 규칙 자체가 배포 단위를 저장소가 아니라 세션 시작 지점으로 만든다"** 이다.

---

## 9. 열린 질문 8~10 해소 — 2026-08-03 2차 보강

### 9.1 배포 단위는 무엇인가 — §6-8 해소, 실측

§8.3이 공식 문서 한 문장에 기대어 제기한 문제다. **`claude -p`로 직접 측정했다.** 저장소에 `.claude/settings.json`을 두고 `env`로 표식을 심은 뒤, 시작 위치를 바꿔가며 그 값이 세션에 들어오는지 확인했다.

| 설정 파일 | 루트에서 시작 | `apps/web/`에서 시작 |
|---|---|---|
| 루트 `.claude/settings.json` | **로드됨** | **로드 안 됨** |
| 루트 `.claude/settings.local.json` | **로드됨** | **로드됨** — 단 아래 조건 |
| `apps/web/.claude/settings.json` | 로드 안 됨 (루트 것이 이긴다) | **로드됨** |

**공식 문서의 서술이 실측으로 확인된다.** `settings.json`은 시작 디렉터리 것만 로드되고 상위에서 상속되지 않는다. 하위 것이 위로 새지도 않는다.

> **조건 — `settings.local.json`의 위치 독립성은 git 저장소 경계에 묶인다.** 같은 디렉터리 구조를 **`git init` 없이** 만들면 `apps/web/`에서 `settings.local.json`도 로드되지 않는다(`PROBE=`). 공식 문서의 *"loads in every CLI session **inside the repository**"* 에서 "repository"가 문자 그대로 git 저장소다. **부록 B.3의 재현 스크립트를 작성하며 `git init`을 빠뜨렸다가 발견했다.**
>
> 하네스 관점에서는 대체로 무해하다 — 배포 대상이 git 저장소일 것이기 때문이다. 다만 **저장소가 아닌 디렉터리에서는 위치 독립 경로 자체가 존재하지 않는다**는 뜻이므로, 아래 선택지 A·B가 유일한 후보가 된다.

**그리고 여기에 이 조사에서 가장 곤란한 딜레마가 있다.**

> **저장소 안에서 위치 독립적으로 로드되는 유일한 파일이 `settings.local.json`인데, 그 파일이 유일하게 배포할 수 없는 파일이다.**

Claude Code가 `settings.local.json`을 전역 gitignore에 넣으므로 [배포 조사](harness-distribution.md)의 Copier 경로로 실어 보낼 수 없다. 실어 보낼 수 있는 `settings.json`은 위치에 묶인다.

**선택지 셋과 각각이 포기하는 것.**

| 방식 | 성립하나 | 포기하는 것 |
|---|---|---|
| **A. 루트에만 배포 + "항상 루트에서 세션 시작" 규약** | 규약이 지켜지는 한 성립 | **규약은 강제가 아니다.** 하위에서 한 번 시작하면 훅·권한이 통째로 빠지고, 빠졌다는 신호가 없다 |
| **B. 패키지마다 자기완결 사본 배포** | 실측상 동작 | 사본이 N벌. [배포 조사 §A](harness-distribution.md)의 핀이 N개로 늘고 드리프트가 N갈래가 된다 |
| **C. 사용자 수준(`~/.claude/settings.json`)에 강제 계층을 둔다** | 위치 독립 | 저장소별 차등이 불가능하고, 배포 대상이 저장소가 아니라 **머신**이 된다. 공유자에게 설치를 요구해야 한다 |

**A의 구멍이 §8.3의 워크트리 발견과 겹친다.** `worktree.sparsePaths`는 `.claude`를 명시적으로 나열해야 워크트리 안에 루트 `.claude/`가 들어온다. 즉 "항상 루트에서 시작한다"를 지켜도 **서브에이전트 워크트리에서는 다시 빠질 수 있다.** A는 규약 하나가 아니라 규약 둘을 요구한다.

**이 조사는 셋 중 고르지 않는다.** 다만 §6-8이 물었던 "무엇이 싼가"에 답할 재료는 나왔다 — **B의 비용은 핀 N개이고, A의 비용은 무증상 실패 가능성이다.** [배포 조사](harness-distribution.md)가 "추적되지 않는 핀은 버전 식별 기능을 하지 못한다"를 결론으로 삼았던 것과 같은 축에서, A는 **강제되지 않는 규약은 강제 기능을 하지 못한다**는 형태다.

### 9.2 태스크 러너 후보 실측 — §6-9 부분 해소

§8.1이 후보 셋(Nx `project.json` / mise / moon)을 나열하고 "셋 다 실행해보지 않았다"로 끝났다. **Nx만 실측했다.**

**설계**: `package.json`이 **없는** 프로젝트 둘을 두고 `project.json`의 `targets`만으로 태스크를 정의했다. `pyapp`은 `python3`을, `shapp`은 `sh`를 실행한다.

```jsonc
// packages/pyapp/project.json — package.json 없음
{ "name": "pyapp", "root": "packages/pyapp",
  "targets": { "test": { "command": "python3 -c \"print('pyapp test ok')\"" } } }
```

**결과** (nx 23.1.1):

| 확인 | 결과 |
|---|---|
| `nx show projects` | `["pyapp","shapp"]` — **`package.json` 없이 인식된다** |
| `nx run pyapp:test` | `Successfully ran target test for project pyapp`, python3 실행됨 |
| `nx run-many -t test` | `Successfully ran target test for 2 projects` — **런타임이 다른 둘을 이름 하나로 디스패치** |

**§8.1의 경로가 실증됐다.** `build`/`test`/`lint` 라는 **이름 계약을 유지한 채 실행 주체만 언어별로 바꿀 수 있다.** Q3의 다중 런타임 답에 대한 실물 답이다.

**그러나 계약 위반 검출은 `pnpm -r`보다 약하다.** §7.1.1과 같은 조건으로 비교했다.

| 상황 | `pnpm -r <script>` | `nx run-many -t <target>` |
|---|---|---|
| 일부 프로젝트에만 있음 | exit **0** (조용히 통과) | exit **0** (조용히 통과) |
| **어느 프로젝트에도 없음** | exit **1** — `ERR_PNPM_RECURSIVE_RUN_NO_SCRIPT` | **exit 0** — `NX No tasks were run` |
| 태스크가 실제로 실패 | exit 3 (하위 코드 전파) | exit 1 |

**Nx는 전면 부재까지 exit 0으로 통과한다.** 메시지(`No tasks were run`)는 나오지만 종료 코드가 성공이다. **`pnpm -r`이 잡아주던 최소한의 방어선마저 없다.**

> **2026-08-03 2차 보강 정정.** 이 절은 최초 작성 시 *"런타임 중립성을 얻는 대가로 fail-open 폭이 넓어진다"* 고 일반화했다. **§10.1에서 mise·moon을 실측한 결과 그 일반화는 틀렸다** — 둘 다 전면 부재를 exit 1로 잡는다. **Nx가 예외**다.

**미측정으로 남긴 것**: **mise와 moon은 실행하지 않았다.** 둘 다 별도 바이너리 설치가 필요하고, 이 환경에 없다(`mise`·`moon` 모두 미설치). §8.1의 표에서 그 두 행은 여전히 벤더 문서 등급이다. 후보에서 제외한 것이 아니라 **재지 않은 것**이다.

### 9.3 스킬 목록 예산과 절삭 — §6-10 해소, §8.3 정정

[공식 skills 문서](https://code.claude.com/docs/en/skills)가 임계값과 메커니즘을 모두 준다. 이 환경을 재지 않았다 — 값이 설정과 모델에 따라 정해지므로 이 머신의 현재 스킬 수는 하네스 설계에 근거가 되지 않는다.

| 항목 | 값 |
|---|---|
| 목록 예산 | **모델 컨텍스트 윈도우의 1%** |
| 항목당 상한 | `description` + `when_to_use` 합계 **1,536자**. 예산과 무관하게 적용 |
| 항상 로드되는 것 | **스킬 이름은 전부** |
| 예산 초과 시 동작 | **가장 적게 호출한 스킬부터 description을 통째로 버린다** |
| 초과 신호 | 디버그 로그에 경고(`--debug`), `/doctor`가 추정치와 최대 기여자 표시 |
| 조정 수단 | `skillListingBudgetFraction`(예: `0.02`), `SLASH_COMMAND_TOOL_CHAR_BUDGET`(고정 문자수), `skillListingMaxDescChars`(항목 상한), `skillOverrides`에 `"name-only"` |

**§8.3 부수 확인 1을 정정한다.** 거기서 *"개수가 많아지면 description이 잘려"* 라고 썼는데 **실패 방식이 다르다.** 절삭이 아니라 **드롭**이다 — 스킬은 전문을 유지하거나 description을 통째로 잃거나 둘 중 하나다. 그리고 순서가 **최소 사용 순**이므로 **새로 추가한 스킬이 가장 먼저 설명을 잃는다.**

**하네스 설계에 걸리는 지점 둘.**

1. **드롭이 사용 빈도순이라는 것은 신규 스킬이 구조적으로 불리하다는 뜻이다.** 방금 배포한 스킬이 아직 호출된 적 없으므로 예산이 빠듯하면 이름만 남는다. [지시 계층 조사](instruction-layers.md)가 잰 온디맨드 스킬 55개가 이 구간에 드는지는 이 조사가 재지 않았다
2. **`skillOverrides`의 `"name-only"`가 예산 관리의 명시적 손잡이다.** 배포하는 스킬이 많아질수록 무엇을 `name-only`로 내릴지가 배포 결정의 일부가 된다

---

## 10. 열린 질문 11~13 — 2026-08-03 3차 보강

### 10.1 mise·moon 실측 — §6-12 해소, §9.2 정정

§9.2가 Nx만 재고 둘을 미측정으로 남겼다. **바이너리를 스크래치패드에 받아 같은 조건으로 쟀다** (mise 2026.8.0, moon 2.4.6, 둘 다 arm64). 사용자 머신에는 설치하지 않았다.

설계는 §9.2와 동일하다 — `python3`을 쓰는 프로젝트와 `sh`/`echo`를 쓰는 프로젝트를 두고, 양쪽 다 `test`를 갖되 `build`는 한쪽만 갖는다.

**언어 중립 디스패치는 셋 다 성립한다.**

| 도구 | 전 프로젝트 `test` | 출력 |
|---|---|---|
| Nx | exit 0 | `Successfully ran target test for 2 projects` |
| mise (`//...:test`) | exit 0 | `[//packages/shapp:test] shapp test ok` / `[//packages/pyapp:test] pyapp test ok` |
| moon (`:test`) | exit 0 | `shapp:test \| shapp test ok` / `pyapp:test \| pyapp test ok`, `Tasks: 2 completed` |

**계약 위반 검출에서 갈린다 — 그리고 §9.2의 일반화가 틀렸다.**

| 러너 | 부분 부재 | **전면 부재** | 실패 전파 (`exit 4`인 태스크) |
|---|---|---|---|
| `pnpm -r <script>` | **0** | **1** — `ERR_PNPM_RECURSIVE_RUN_NO_SCRIPT` | **4** — 하위 코드 그대로 |
| `nx run-many -t` | **0** | **0** ← **유일하게 놓친다** | **1** |
| `mise run //...:<task>` | **0** | **1** | **4** — 하위 코드 그대로 |
| `moon run :<task>` | **0** | **1** — `No tasks found. Unable to execute action pipeline.` | **1** |

**실패 전파는 넷 모두 정상이다.** 실제로 실패하는 태스크를 놓치는 러너는 없다. 다만 종료 코드 의미가 갈린다 — `pnpm -r`·mise는 하위 코드를 그대로 올리고, Nx·moon은 1로 정규화한다. **게이트가 종료 코드 값 자체로 실패 유형을 구분하려 한다면 러너에 따라 달라진다.**

**두 가지가 뒤집힌다.**

1. **"언어 중립 러너는 구조적으로 fail-open"이 아니다.** mise·moon은 `pnpm -r`과 같은 수준으로 전면 부재를 잡는다. **Nx만 예외**이며, 이는 런타임 중립성의 대가가 아니라 그 도구의 선택이다
2. **그러나 부분 부재는 넷 모두 exit 0이다.** 이쪽이 진짜 공통 결손이다. **§7.1.1이 요구한 "몇 개에서 실제로 돌았는가"를 게이트가 직접 대조하라는 결론은 러너 선택과 무관하게 유효하다** — 오히려 러너를 바꿔서는 해결되지 않는다는 것이 확인됐다

**부수 관측 넷** (전부 이 실험에서 직접 확인):

| 관측 | 내용 |
|---|---|
| **mise는 설정 파일 신뢰를 요구한다** | 신뢰하지 않은 `mise.toml`은 실행을 거부한다 — `Config files ... are not trusted. Trust them with 'mise trust'`. **하네스가 설정을 배포하면 각 머신에서 신뢰 단계가 추가로 필요하다.** [보안 조사](security.md)가 다룬 공급망 축과 같은 방향의 방어이며, 배포 자동화에는 마찰이다 |
| **moon은 커밋이 있는 git 저장소를 요구한다** | 커밋 0개인 저장소에서 `git ... HEAD` 실패로 전체가 죽는다(`process::failed`). §9.1의 `settings.local.json`이 git 저장소를 요구한 것과 같은 종류의 숨은 전제다 |
| mise `monorepo_root`는 **최상위 필드**다 | `[settings]` 아래에 두면 `unknown field` 경고만 내고 **모노레포 모드가 켜지지 않는다.** 경고가 나오되 실행은 계속되므로 조용한 오설정에 가깝다 |
| moon 2.4.6은 `type`이 아니라 `layer` | 프로젝트 설정 필드명이 바뀌었다. 구버전 예제를 그대로 쓰면 `config::parse::failed` |

### 10.2 `settings.local.json` 우회 — §6-11 해소

§9.1이 남긴 질문이다. 배포된 `settings.json`이 `settings.local.json`을 생성하게 하는 우회가 순이득인가.

**측정 가능한 부분만 쟀다** — 그 파일이 실제로 추적되는지.

```
새 git 저장소 + 직접 만든 .claude/settings.local.json
→ git status: (비어 있음)
→ git check-ignore -v: ~/.config/git/ignore:1: **/.claude/settings.local.json
```

**이 머신에는 `~/.config/git/ignore`가 있고 그 한 줄만 들어 있다** (2026-04-09 생성). `core.excludesfile`은 미설정이지만 git이 `$XDG_CONFIG_HOME/git/ignore`를 기본 전역 무시 파일로 읽으므로 동작한다.

> **귀속에 관한 주의.** 그 파일에 해당 한 줄만 들어 있다는 점에서 **Claude Code가 만든 것으로 보이나, 생성 순간을 관측한 것은 아니다.** 공식 문서의 *"Claude Code adds that file to your global gitignore when it saves a setting there"* 와 부합하지만, 이 조사가 확인한 것은 **결과 상태**이지 인과가 아니다. §5.2에서 남의 수치에 적용한 기준을 이쪽에도 적용한다.

**따라서 우회는 순이득이 아니다.**

1. **생성물이 추적되지 않는다.** [배포 조사 §B](harness-distribution.md)가 실증한 결론이 그대로 적용된다 — Copier의 3-way merge는 git 기계로 수행되므로 **추적되지 않는 대상에서는 단순 덮어쓰기로 퇴화**한다. 로컬 수정이 경고 없이 사라진다
2. **핀이 없다.** [배포 조사 §A](harness-distribution.md)의 두 필드(`sha`·`contentHash`) 중 어느 것도 이 파일에 붙지 않는다. 드리프트 검출 수단이 사라진다
3. **그리고 동작이 머신마다 다르다.** 전역 무시 줄은 **Claude Code가 그 머신에서 설정을 저장한 적이 있을 때** 생긴다. 공유자의 새 머신에는 없을 수 있고, 그러면 같은 파일이 **추적된다.** 즉 이 우회는 **환경에 따라 추적 여부가 갈리는 배포물**을 만든다 — 하네스가 공유자 머신에서 다르게 동작하는 경로다

**결론**: §9.1의 선택지 A(루트 전용 + 규약)와 B(패키지별 자기완결 사본)가 남는다.

> **⚠ 2026-08-09 정정 — 「위치 독립성을 얻는 대신」이 과했다. 그 이점 자체가 없다.**
>
> 이 절은 우회를 *"위치 독립성을 얻는 대신 두 요구를 포기한다"*는 **거래**로 서술했다. **얻는 쪽을 재지 않고 공식 문서 서술을 그대로 받은 것이고, 그 서술이 실측으로 반증됐다.**
>
> 공식 문서(`code.claude.com/docs/en/settings`)는 `settings.local.json`에 대해 *"Claude Code reads and writes this file at the root of the git repository, resolved through worktrees to the main checkout, **so one file covers sessions started in any subdirectory or worktree of the repository**"* 라고 적는다. **세 곳에서 재니 루트에서만 발화했다** — 메인 루트 ✅ · 메인 하위 ✗(2회 재현) · 워크트리 루트 ✗ (**1차 실측**, 2026-08-09 · Claude Code 2.1.226 · `claude -p` · `SessionStart` 훅).
>
> **직접 둔 파일에 대해서는 저장소 루트 해석이 읽기 쪽에 아예 없다.** 하위 디렉터리에 그 파일을 직접 두자 발화했고 `CLAUDE_PROJECT_DIR`이 **저장소 루트가 아니라 그 하위 디렉터리**를 가리켰다. **`settings.local.json`은 `settings.json`과 같은 규칙(시작 디렉터리)으로 동작한다.**
>
> **전제 확인** — `settings.json`은 `{}`로 비워 발화원을 하나로 두었고, 파일은 유효 JSON이며 루트에서는 발화했고, 하위에서 `git rev-parse --show-toplevel`이 저장소 루트를 정상 해석했다.
>
> **잰 범위는 읽기 쪽이고, 잰 파일은 전부 직접 만든 것이다.** 쓰기 쪽(Claude Code가 스스로 그 파일을 만들 때 어디에 두는가)은 재지 않았다 — 문서 문장의 *reads and writes* 중 **reads만, 그것도 직접 둔 파일에 대해서만 반증됐다.** **자신이 프로비저닝한 파일은 저장소 루트에 두고 그 경로로 찾을 가능성이 남아 있다.** 기각 결론은 이 한정어와 무관하다 — 위 세 근거 중 핀 부재와 3-way merge 퇴화는 그 경우에도 그대로다.
>
> **기각 결론은 바뀌지 않고 근거가 하나 늘었다.** 이제 이 경로는 *두 요구를 포기하고 아무것도 얻지 못한다*. 인용하는 문서: [미결 원장 S11](../draft/open-questions.md) · [드래프트 §6-1](../draft/flow.html#6-1).

### 10.3 스킬 예산 — §6-13 보류

**측정하지 않는다.** 두 가지가 막는다.

1. **예산이 "모델 컨텍스트 윈도우의 1%"인데 문자↔토큰 환산 규칙이 문서에 없다.** `SLASH_COMMAND_TOOL_CHAR_BUDGET`이 문자 수를 받으므로 예산 단위는 문자인데, 컨텍스트 윈도우는 토큰 단위다. 1%가 어떤 값이 되는지 계산할 근거가 없다
2. **grid fin에는 아직 하네스 스킬이 없다.** 셀 대상이 존재하지 않는다

**이 머신의 현재 스킬 목록을 재는 것은 §9.3에서 하지 않기로 한 것과 같은 이유로 하지 않는다** — 결과가 이 랩톱의 오늘 상태에 대한 값이지 하네스 설계에 대한 값이 아니다. 합성 스킬 N개로 임계값을 찾는 것도 같은 문제다. 그 수치는 시험용 픽스처에 대한 값이 된다.

**언제 측정 가능해지는가**: grid fin이 스킬을 실제로 배포하기 시작한 뒤, 그리고 문자 예산의 해석이 확인된 뒤다. 그때는 `/doctor`가 추정치와 최대 기여자를 주고 `--debug`가 초과 경고를 낸다(§9.3). **지금 답할 수 없는 질문으로 남긴다.**

---

## 부록. 조사 방법 및 한계

**방법**
- Exa `/search` 8회 — 단일 패키지 모노레포, 솔로 개발자 트레이드오프, 에이전트×저장소 구조, Nx/Turborepo 태스크 규약, Nx standalone, affected 스코핑, 언어 중립 태스크 러너, moon
- Firecrawl `/v1/scrape` 7회 — Claude Code memory·settings·large-codebases, agents.md, Turborepo single-package workspaces, pnpm workspaces, Nx standalone→monorepo(안정 도메인 대조)
- GitHub API 2회 — `openai/codex` 트리 전수 조회 + 기본 브랜치/truncation 확인 (§5.2)
- **직접 실행한 실험 7건** — §7.1(워크스페이스 비용), §7.1.1(`pnpm -r` fail-open), §7.2(`--affected` 퇴화), §9.1(`settings.json` 비상속, `claude -p`), §9.2(Nx 비JS 디스패치), §10.1(mise·moon), §10.2(`settings.local.json` 추적 여부). 재현 스크립트는 부록 B

**1차 확인**
- 하위 디렉터리 `CLAUDE.md` 온디맨드 로드, `claudeMdExcludes`, `.claude/rules/`, 200줄 목표 — Claude Code 공식 memory 문서 원문
- single-package workspace에서 동작/미동작하는 기능 — Turborepo 공식 가이드 원문
- standalone 정의와 14단계 변환 절차 — Nx 공식 문서 원문
- `--affected` 기본값·립도·shallow checkout 함정·환경변수 — Turborepo `run` 레퍼런스 원문
- *"Every project needs tasks: build, test, lint, serve"* 와 scripts 자동 인식 — Nx 튜토리얼 원문
- `openai/codex`의 `AGENTS.md` 2개 — GitHub API 직접 조회. `default_branch: main`과 `truncated: false`(엔트리 6,723개)를 함께 확인해 잘린 트리로 인한 과소 계수를 배제했다
- **2026-08-03 추가** — `settings.json` 비상속, `claudeMdExcludes` 형식·병합 규칙, 스킬 스코프·description 절삭, `worktree.sparsePaths`, `additionalDirectories`/`--add-dir` 차이 — Claude Code 공식 `large-codebases`·`settings` 문서 원문
- **2026-08-03 추가** — Nx `project.json` `targets`의 비JS 용도 명시 — Nx 튜토리얼 원문

**출처 등급**

| 등급 | 출처 |
|---|---|
| **1차 (공식)** | Claude Code(memory·settings·**large-codebases**), Turborepo(single-package·run), Nx(standalone·configuring-tasks·standalone-to-monorepo), agents.md |
| **1차 실측 (이 조사)** | `openai/codex` 트리 조회, **§7·§9·§10의 실험 7건** — pnpm·turbo·Nx·**mise·moon**·`claude -p` |
| **벤더 문서 (자기 비교 편향)** | mise의 경쟁 제품 비교표(§8.1). **도구 동작 자체는 §10.1에서 실측으로 대체했다** |
| **자가출판 — 구조적 주장만** | aitoolsguidebook, zero8.dev, smitparekh.co.in |
| **신뢰도 낮음 — 수치 인용 금지** | graxel.ai |

**한계**
- ~~가정의 핵심 형태를 직접 다루는 1차 문서를 찾지 못했다~~ — **문서는 여전히 없으나 §7.1에서 직접 측정해 대체했다**
- Nx 쪽은 standalone에서 **잃는 기능** 목록을 확인하지 못했다. Turborepo는 명시(`app#build`)하지만 Nx 문서에서 대응 서술을 찾지 못했다
- `nx affected`의 동작(그래프 기반)은 **자가출판 서술로만 확인**했고 Nx 공식 문서로 대조하지 않았다
- **§7.1은 패키지가 1개일 때만 쟀다.** 패키지가 여럿일 때의 호이스팅·`tsconfig` 경로 매핑은 미측정이다
- **§7.2는 turbo 2.5.6·2패키지·로컬 `file://` 원격에서만 관측했다.** 실제 CI(GitHub Actions 등)의 체크아웃 형태, `nx affected`의 동일 조건 동작은 확인하지 않았다
- ~~§8.1의 후보 셋을 실행해보지 않았다~~ — **셋 다 실측했다**(§9.2 Nx, §10.1 mise·moon). 다만 **잰 것은 디스패치와 종료 코드뿐**이다. 캐싱·의존 그래프·원격 캐시 등 각 도구의 나머지 기능은 재지 않았다
- **§10.1은 프로젝트 2개·태스크 2종의 최소 형태다.** 실제 규모에서의 동작, 특히 의존 순서(`dependsOn`)가 있을 때의 부분 부재 처리는 확인하지 않았다
- **§10.2는 이 머신 한 대의 상태를 관측한 것이다.** `~/.config/git/ignore`의 그 줄이 다른 머신에 있는지는 확인할 수 없고, **없을 수 있다는 것 자체가 §10.2의 결론**이다
- ~~**§9.1은 `env` 주입 하나로만 쟀다.**~~ **부분 해소(2026-08-09) — 훅이 같은 로드 규칙을 따르는 것을 실측했다.** 루트에만 `settings.json`을 두고 하위 디렉터리에서 세션을 열자 `SessionStart` 훅이 발화하지 않았고, `settings.local.json`도 같았다(§10.2 정정). **권한 규칙과 `worktree` 설정은 여전히 문서 서술에 기대고 있다.** 그리고 **새로 갈린 것 하나 — 스킬은 상속된다**: 같은 조건에서 상위의 스킬이 하위 세션에 보였다. **훅과 스킬의 로드 규칙이 다르다**([미결 원장 S10](../draft/open-questions.md))
- **§9.3은 문서만 읽었다.** 이 머신의 스킬 목록이 실제로 예산을 넘는지 재지 않았다 — 값이 모델·설정에 좌우되므로 이 환경의 수치가 하네스 설계 근거가 되지 않는다고 판단했다(§6-13)
- 이 조사는 **JS/TS 생태계 도구에 편중**되어 있다. Q3의 답이 다중 런타임이므로 이 편중이 그대로 남는다(§6-9)
- 에이전트가 모노레포에서 실제로 어떤 오류를 내는지에 대한 **피어리뷰 자료를 찾지 못했다.** §5.1은 전부 저자 관찰이다

**변경 이력**

| 일자 | 내용 |
|---|---|
| 2026-08-09 (정정) | **§10.2의 「위치 독립성을 얻는 대신」을 정정했다** — 공식 문서의 *"one file covers sessions started in any subdirectory or worktree"* 가 실측으로 반증됐다(루트에서만 발화. 하위 ✗ 2회 재현 · 워크트리 ✗). 기각 결론은 유지되고 근거가 하나 늘었다. 관측 11과 「재지 않은 것」의 §9.1 항목도 함께 갱신 |
| 2026-08-03 (최초) | 문헌 조사 + `openai/codex` 트리 검증. §6에 열린 질문 7개 |
| 2026-08-03 (보강) | §6 전 항목 해소. §7 실험 2건 신설, §8 문헌·분석 신설, §0에 관측 10~15 추가. **§3 항목 2의 "조용한 퇴화" 기술 정정**(§7.2). 열린 질문 8~10 신규 |
| 2026-08-03 (2차 보강) | 열린 질문 8~10 해소. §9 신설(실험 2건 추가), §0에 관측 16~19 추가. **§8.3 부수 확인 1의 "description 절삭" 기술 정정**(§9.3 — 절삭이 아니라 최소 사용 순 드롭). 열린 질문 11~13 신규 |
| 2026-08-03 (부록 검증) | **부록 B의 네 스크립트를 게시본 그대로 실행해 검증했다.** B.2에서 `git checkout -q main` 누락, B.3에서 `git init` 누락을 발견해 고쳤다. 후자는 스크립트 결함에 그치지 않고 **`settings.local.json`의 위치 독립성이 git 저장소 경계에 묶인다**는 조건을 드러냈다(§9.1 각주, 관측 17) |
| 2026-08-03 (3차 보강) | 열린 질문 11~12 해소, 13은 측정 불가로 보류. §10 신설(실험 2건 추가), 부록 B.5 추가·검증, §0에 관측 20~23. **§9.2의 "언어 중립 러너는 fail-open" 일반화 정정**(§10.1 — mise·moon은 잡는다, Nx만 예외) |

**출처 등급 변경**: mise·moon이 **벤더 문서**에서 **1차 실측**으로 올라갔다(§10.1). §8.1 표의 그 두 행은 이제 실행 결과에 근거한다.

---

## 부록 B. 재현 스크립트

환경: pnpm 10.33.0 / node v24.13.0 / git 2.50.1 / turbo 2.5.6 / macOS(darwin 25.5.0). 전문은 세션 스크래치패드의 `q1-workspace-cost.sh`·`q4b-affected-shallow.sh`에 있다. 아래는 결론을 낳은 최소 형태다.

### B.1 §7.1 — 워크스페이스 비용

```bash
set -u
ROOT="$(mktemp -d)"

# baseline: 워크스페이스 선언 없는 단일 패키지
mkdir -p "$ROOT/baseline/src"
cat > "$ROOT/baseline/package.json" <<'JSON'
{ "name": "web", "private": true,
  "scripts": { "test": "node -e \"console.log('ok', process.cwd())\"" },
  "devDependencies": { "typescript": "5.9.2" } }
JSON

# variant: 엔트리 하나짜리 워크스페이스
mkdir -p "$ROOT/variant/apps/web/src"
echo '{ "name": "root", "private": true }' > "$ROOT/variant/package.json"
printf 'packages:\n  - "apps/*"\n' > "$ROOT/variant/pnpm-workspace.yaml"
cp "$ROOT/baseline/package.json" "$ROOT/variant/apps/web/package.json"

for V in baseline variant; do
  ( cd "$ROOT/$V" && pnpm install --silent
    echo "--- $V ---"
    echo "pnpm test      : $(pnpm test        >/dev/null 2>&1 && echo 0 || echo 1)"
    echo "pnpm -r test   : $(pnpm -r test     >/dev/null 2>&1 && echo 0 || echo 1)"
    echo "루트 .bin/tsc  : $([ -e node_modules/.bin/tsc ] && echo 있음 || echo 없음)" )
done
# 기대: baseline = 0/0/있음,  variant = 1/0/없음
```

§7.1.1의 부분 부재는 워크스페이스에 스크립트 없는 패키지를 하나 더 두면 재현된다.

```bash
# apps/api 는 test 를 갖지 않는다
echo '{"name":"api","private":true,"scripts":{"build":"node -e 1"}}' > apps/api/package.json
pnpm -r test;      echo "exit=$?"   # → 0.  "Scope: 2 of 3" 만 남기고 통과
pnpm -r typecheck; echo "exit=$?"   # → 1.  ERR_PNPM_RECURSIVE_RUN_NO_SCRIPT
```

### B.2 §7.2 — `--affected` 퇴화 경로 둘

```bash
set -u
ROOT="$(mktemp -d)"; O="$ROOT/origin"
mkdir -p "$O/apps/a/src" "$O/apps/b/src"
cat > "$O/package.json" <<'JSON'
{ "name": "root", "private": true, "packageManager": "pnpm@10.33.0",
  "devDependencies": { "turbo": "2.5.6" } }
JSON
printf 'packages:\n  - "apps/*"\n' > "$O/pnpm-workspace.yaml"
echo '{ "tasks": { "test": { "cache": false } } }' > "$O/turbo.json"
for P in a b; do
  printf '{"name":"%s","private":true,"scripts":{"test":"node -e \\"console.log(0)\\""}}\n' "$P" \
    > "$O/apps/$P/package.json"
  echo "export const v = 1" > "$O/apps/$P/src/index.ts"
done
printf 'node_modules\n.turbo\npnpm-lock.yaml\n' > "$O/.gitignore"

cd "$O" && git init -q -b main && git add -A && git commit -qm c1
git checkout -q -b feat && echo "export const v = 2" > apps/a/src/index.ts && git commit -qam c2
git checkout -q main   # ★ 필수. origin의 HEAD가 feat이면 클론에 로컬 main이 생기지 않아
                       #   전체 이력 클론까지 경로 A(경고+전량)로 빠진다

# 경로 A: base 도달 불가 → 경고가 나오고 전량 선택, exit 0
git clone -q --depth=1 --branch feat --single-branch "file://$O" "$ROOT/shallow"
( cd "$ROOT/shallow" && pnpm install --silent \
  && ./node_modules/.bin/turbo run test --affected 2>&1 | grep -E "WARNING|scope" )
# → WARNING unable to detect git range... / Packages in scope: //, a, b

# 경로 B: 전역 의존성 변경 → 경고 없이 전량 선택
git clone -q "file://$O" "$ROOT/full"
( cd "$ROOT/full" && git checkout -q feat && pnpm install --silent
  echo "-- 기준선 --"
  ./node_modules/.bin/turbo run test --affected 2>&1 | grep -E "WARNING|scope"   # → a
  echo "-- 루트 package.json 수정 --"
  printf '\n' >> package.json
  ./node_modules/.bin/turbo run test --affected 2>&1 | grep -E "WARNING|scope"   # → a, b (경고 없음)
  git checkout -q package.json
  echo "-- .gitignore 수정 (대조군) --"
  printf '\n#c\n' >> .gitignore
  ./node_modules/.bin/turbo run test --affected 2>&1 | grep -E "WARNING|scope" ) # → a (영향 없음)
```

`.gitignore` 대조군이 교란 변수 제거의 핵심이다 — 이것 없이는 "루트 파일 변경이 전량을 유발한다"와 "특정 루트 파일만 전역 의존성이다"를 구분할 수 없다.

### B.3 §9.1 — `settings.json` 비상속

`claude` CLI가 인증된 상태여야 한다. `env`로 표식을 심고 시작 위치를 바꿔가며 세션에 들어오는지 본다.

```bash
set -u
R="$(mktemp -d)"; mkdir -p "$R/repo/.claude" "$R/repo/apps/web"
( cd "$R/repo" && git init -q -b main )   # ★ 필수. 아래 대안 A가 git 저장소 경계에 묶인다
echo '{ "env": { "ARTISAN_PROBE": "ROOT_SETTINGS_LOADED" } }' > "$R/repo/.claude/settings.json"

probe() { ( cd "$R/repo/$1" && claude -p \
  'Run exactly: echo "PROBE=$ARTISAN_PROBE" — then reply with only that line.' \
  --allowedTools 'Bash(echo:*)' < /dev/null 2>&1 | tail -1 ); }

probe "."          # → PROBE=ROOT_SETTINGS_LOADED
probe "apps/web"   # → PROBE=            ★ 루트 설정이 로드되지 않는다

# 대안 A: settings.local.json 은 저장소 안이면 어디서 시작해도 로드된다 (v2.1.211+)
echo '{ "env": { "ARTISAN_PROBE": "ROOT_LOCAL_SETTINGS_LOADED" } }' \
  > "$R/repo/.claude/settings.local.json"
probe "apps/web"   # → PROBE=ROOT_LOCAL_SETTINGS_LOADED
                   #   git init 을 빼면 이 줄이 PROBE= 로 나온다 — §9.1의 각주 참조
rm "$R/repo/.claude/settings.local.json"

# 대안 B: 패키지별 자기완결 사본
mkdir -p "$R/repo/apps/web/.claude"
echo '{ "env": { "ARTISAN_PROBE": "PACKAGE_SETTINGS_LOADED" } }' \
  > "$R/repo/apps/web/.claude/settings.json"
probe "apps/web"   # → PROBE=PACKAGE_SETTINGS_LOADED
probe "."          # → PROBE=ROOT_SETTINGS_LOADED   (하위 설정은 위로 새지 않는다)
```

### B.4 §9.2 — Nx의 비JS 디스패치와 fail-open

```bash
set -u
R="$(mktemp -d)"; cd "$R"; mkdir -p packages/pyapp packages/shapp
echo '{ "name": "root", "private": true, "devDependencies": { "nx": "23.1.1" } }' > package.json
echo '{ "targetDefaults": { "test": { "cache": false }, "build": { "cache": false } } }' > nx.json

# 두 프로젝트 모두 package.json 이 없다
cat > packages/pyapp/project.json <<'JSON'
{ "name": "pyapp", "root": "packages/pyapp", "targets": {
  "build": { "command": "python3 -c \"print('build ok')\"" },
  "test":  { "command": "python3 -c \"print('test ok')\""  } } }
JSON
cat > packages/shapp/project.json <<'JSON'
{ "name": "shapp", "root": "packages/shapp", "targets": {
  "test": { "command": "sh -c \"echo test ok\"" } } }
JSON

pnpm install --silent
./node_modules/.bin/nx show projects            # → ["pyapp","shapp"]
./node_modules/.bin/nx run-many -t test         # → 2 projects. 런타임이 달라도 이름 하나로
./node_modules/.bin/nx run-many -t build;     echo "부분 부재 exit=$?"   # → 0
./node_modules/.bin/nx run-many -t typecheck; echo "전면 부재 exit=$?"   # → 0 ★ No tasks were run
```

마지막 줄이 §9.2의 핵심 대조다 — 같은 조건에서 `pnpm -r typecheck`는 **exit 1**(`ERR_PNPM_RECURSIVE_RUN_NO_SCRIPT`)이다.

### B.5 §10.1 — mise·moon

바이너리를 스크래치패드에만 받는다. 시스템에 설치하지 않는다.

```bash
set -u
B="$(mktemp -d)"; cd "$B"
curl -sL -o mise.tar.gz \
  "https://github.com/jdx/mise/releases/download/v2026.8.0/mise-v2026.8.0-macos-arm64.tar.gz"
tar xzf mise.tar.gz          # → ./mise/bin/mise
curl -sL -o moon.tar.xz \
  "https://github.com/moonrepo/moon/releases/download/v2.4.6/moon_cli-aarch64-apple-darwin.tar.xz"
tar xJf moon.tar.xz          # → ./moon_cli-aarch64-apple-darwin/moon
MISE="$B/mise/bin/mise"; MOON="$B/moon_cli-aarch64-apple-darwin/moon"

# ---------- mise ----------
M="$(mktemp -d)"; mkdir -p "$M/packages/pyapp" "$M/packages/shapp"; cd "$M"
printf 'monorepo_root = true\n' > mise.toml     # ★ 최상위 필드. [settings] 아래에 두면
                                                #   unknown field 경고만 내고 켜지지 않는다
printf '[tasks.test]\nrun = "python3 -c \\"print(1)\\""\n[tasks.build]\nrun = "python3 -c \\"print(2)\\""\n' \
  > packages/pyapp/mise.toml
printf '[tasks.test]\nrun = "sh -c \x27echo ok\x27"\n' > packages/shapp/mise.toml
"$MISE" trust --all >/dev/null 2>&1              # ★ 신뢰하지 않으면 실행을 거부한다
"$MISE" run '//...:test';      echo "mise 전체     exit=$?"   # → 0, 두 프로젝트 실행
"$MISE" run '//...:build';     echo "mise 부분부재 exit=$?"   # → 0
"$MISE" run '//...:typecheck'; echo "mise 전면부재 exit=$?"   # → 1

# ---------- moon ----------
N="$(mktemp -d)"; mkdir -p "$N/.moon" "$N/packages/pyapp" "$N/packages/shapp"; cd "$N"
git init -q -b main                              # ★ moon 은 커밋이 있는 git 저장소를 요구한다
printf "projects:\n  - 'packages/*'\n" > .moon/workspace.yml
cat > packages/pyapp/moon.yml <<'YAML'
layer: application                               # ★ 2.4.6 에서 type → layer
language: python
tasks:
  test:  { command: 'python3 -c "print(1)"', options: { cache: false } }
  build: { command: 'python3 -c "print(2)"', options: { cache: false } }
YAML
cat > packages/shapp/moon.yml <<'YAML'
layer: application
language: bash
tasks:
  test: { command: 'echo ok', options: { cache: false } }
YAML
printf '.moon/cache\n' > .gitignore
git add -A && git -c user.email=t@t -c user.name=t commit -qm init
"$MOON" run ':test';      echo "moon 전체     exit=$?"   # → 0, Tasks: 2 completed
"$MOON" run ':build';     echo "moon 부분부재 exit=$?"   # → 0
"$MOON" run ':typecheck'; echo "moon 전면부재 exit=$?"   # → 1, No tasks found
```

★ 표시 넷은 전부 이 스크립트를 쓰면서 실제로 걸린 것들이다. 넷 중 하나라도 빠지면 실행이 실패하거나(신뢰·git) 조용히 다른 것을 재게 된다(`monorepo_root` 위치).
