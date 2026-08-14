# Orca (onorca.dev) — 단일 시스템 심층 조사

**최초 작성**: 2026-08-03
**최종 수정**: 2026-08-03
**대상 프로젝트**: grid fin (신규 개인용 개발 하네스)
**조사 계기**: *"https://www.onorca.dev/ 에 대해서 조사해"*
**조사 도구**: WebFetch 15회(공식 사이트·문서), WebSearch 1회, GitHub REST API 10회, `raw.githubusercontent.com` 5회, **로컬 실측**(설치된 Orca 1.4.158 + `orca` CLI + `orchestration.db` 스키마 + `~/.claude/skills/`)
**실패**: 1회 — `/docs/what-is-orca` 404. sitemap.xml로 확인하니 **그런 경로가 없다**(`/docs` 인덱스가 그 역할). 사이트 구조를 추측해 URL을 만든 것이 원인이었고, 이후 페이지는 전부 sitemap에서 골랐다
**성격**: 조사. grid fin의 설계 결정은 하지 않는다. §9는 관측을 기존 조사 축으로 재배열한 것이며 결정이 아니다.

**이 문서는 `docs/research/`에서 처음으로 문제 축이 아니라 *제품 하나*를 대상으로 한다.** 기존 24개 문서는 전부 축(조율·상태·관찰성·스킬 구조…)을 잡고 N개 시스템을 훑는 형태였다. 여기서는 반대로 시스템 하나를 잡고 기존 축들에 어디를 때리는지 표시한다. 따라서 §9가 이 문서의 실제 쓸모다.

**자매편**: [cmux.md](cmux.md) — 같은 제품 범주에서 **같은 문제에 반대 답**을 낸 시스템. 스킬 배포(스텁+바이너리 서빙 ↔ 전문 20종 설치), 라이선스(MIT ↔ GPL+유보), 무게중심(에이전트를 늘리기 ↔ 늘어난 에이전트를 사람이 감당하기)이 정면으로 갈린다. 그쪽 §0.5가 대조표다

관련 문서 (이 문서가 데이터를 보태는 축)
- [skill-architecture.md](skill-architecture.md) — §2가 관측 #17(본문 500줄 상한)에 **배포 층의 실물 답**을 보탠다
- [harness-distribution.md](harness-distribution.md) — §2·§3이 "가이드를 무엇에 묶어 배포하는가"의 사례
- [worktree-shared-state.md](worktree-shared-state.md) — §5가 관측 **#14 `.worktreeinclude` 사실상 표준**의 **세 번째 데이터포인트**다. 새 발견이 아니라 기존 관측의 연장
- [agent-orchestration.md](agent-orchestration.md) — §4. 그 문서의 결론(다중 에이전트 조율은 자료가 지지하지 않음)을 **뒤집지 않는다**. Orca는 기제를 출하할 뿐 효능 측정을 제시하지 않는다
- [state-and-continuity.md](state-and-continuity.md) — §6. 상태 소유자를 4가지 배치로 가르는 실물
- [observability.md](observability.md) — §7. OTel이 아닌 제품 텔레메트리 정책의 대조군
- [context-file-content.md](context-file-content.md) — §8. `CLAUDE.md`가 한 줄인 실물

---

## 0. 조사 요약

### 0.1 두 문장

**Orca는 "ADE(Agent Development Environment)"를 표방하는 MIT 라이선스 Electron 앱으로, 워크트리 하나당 에이전트 하나를 붙여 병렬로 돌리는 것을 제품의 중심에 둔 시스템이다.** grid fin에 실제로 유용한 부분은 UI가 아니라 **에이전트용 표면을 어떻게 배포하는가** 였다 — 스킬 파일에는 78줄짜리 스텁만 두고 331줄짜리 실제 가이드는 바이너리가 서빙하며, 그 이유를 *"바이너리와 절대 어긋나지 않게 하려고 일부러 뺐다"* 라고 파일 안에 적어 두었다.

### 0.2 관측

| # | 관측 | 등급 | 위치 |
|---|---|---|---|
| 1 | **스킬을 스텁(78줄)과 버전 매칭 가이드(331줄)로 쪼개고, 가이드는 파일이 아니라 `orca skills get <topic>` 으로 바이너리가 낸다.** 이유가 스텁 본문에 명시 — *"kept out of this file on purpose so it can never drift from the binary that will actually run your commands"* | **1차 (레포 원본 + 로컬 실측)** | §2 |
| 2 | **그 분할이 실제로 필요한 조건이 실측된다** — 이 머신의 앱은 1.4.158, 최신 stable은 1.4.164(2026-08-02). **6일에 6버전**. 릴리스 API로 확인 | **1차 (GitHub API + 로컬 plist)** | §2.3 |
| 3 | **CLI 전량을 문서로 옮기지 않고 기계 판독 스키마로 낸다** — `orca agent-context --json` 이 **206개 커맨드, 137KB**의 스키마(`schemaVersion`/`commandCount`/`commands[]`, 각 항목에 usage·flags·examples·notes)를 출력 | **1차 (로컬 실측)** | §3 |
| 4 | **스킬 배포 채널이 하네스 바깥의 범용 설치기다** — `npx skills add https://github.com/stablyai/orca --skill <name> --global`. 그리고 Orca는 Claude·Codex·Agent Skills·OMP(`~/.omp/agent/skills`)의 스킬 디렉터리를 **스캔**해 발견한다 | 1차 (공식 문서, 요약 경유) | §2.4 |
| 5 | **다중 에이전트 조율 원시요소가 CLI로 출하돼 있다** — Run / Task / Dispatch / Message / Decision gate. 태스크 상태 6종(`pending`→`ready`→`dispatched`→`completed`/`failed`/`blocked`), 그룹 주소(`@all`·`@idle`·`@codex`), 블로킹 질문(`orchestration ask`), 코디네이터 루프(`orchestration run`) | **1차 (로컬 `--help`)** + 공식 문서 | §4 |
| 5b | **그 조율 상태가 어디 있는지 실측했다 — `~/Library/Application Support/Orca/orchestration.db`, SQLite(WAL), 5테이블.** 워크트리 바깥이고 레포별도 아닌 **머신 전역 단일 원장**이다. [worktree-shared-state](worktree-shared-state.md) 관측 #1("워크트리 안에 세션 상태를 두는 시스템을 하나도 찾지 못했다")의 **여덟 번째 사례** | **1차 (로컬 DB 스키마 직접 확인)** | §4.4 |
| 5c | **그 스키마에 자료로만 봤을 때 안 보이던 것이 셋 있다** — `dispatch_contexts.status`에 **`circuit_broken`**(+ `failure_count`·`last_failure`·`last_heartbeat_at`), `decision_gates.status`에 **`timeout`**, `coordinator_runs.poll_interval_ms` **기본 2000** (코디네이터가 폴링 루프다) | **1차 (로컬 DB 스키마)** | §4.4 |
| 6 | **그러나 효능 근거는 어디에도 없다.** 벤치마크·측정·사례 수치가 사이트·README·문서 어디에도 제시되지 않는다. [agent-orchestration](agent-orchestration.md)의 결론을 흔드는 자료가 아니다 | **부재 확인** | §4.3 |
| 7 | **`.worktreeinclude` 표준의 세 번째 사례다.** Orca는 gitignore된 파일 복사를 `.worktreeinclude`로 받고, gitignore된 디렉터리 공유는 `orca.yaml`로, 그리고 나머지는 **setup script**로 넘긴다 — worktree-shared-state 관측 #14·#14b와 같은 정책 | 1차 (공식 문서, 요약 경유) + **1차 (레포 `orca.yaml`)** | §5 |
| 8 | **실행 위치가 4종으로 갈리고, 축은 "런타임을 누가 소유하는가"다** — 로컬 데스크톱 / SSH 타겟 / 원격 Orca 서버(`orca serve`) / 워크스페이스별 클라우드 VM. SSH는 노트북 Orca가 런타임 주인이라 **다중 클라이언트 불가**, 원격 서버는 가능 | 1차 (공식 문서, 요약 경유) | §6 |
| 9 | **에이전트 프로세스의 수명은 데몬에 묶인다** — 앱 종료(Cmd-Q·자동업데이트·크래시)에는 살아남고 재연결되지만, *"The daemon dies when the host does"*. 호스트가 죽으면 레이아웃과 스크롤백만 복원된다 | 1차 (공식 문서, 요약 경유) | §6.2 |
| 10 | **"Worktree checkpoints"는 git 체크포인트가 아니다** — 워크트리에 붙는 자유 형식 코멘트 필드 + 카드 상태(`todo`/`in-progress`/`in-review`/`completed`)다. 이름이 오해를 부른다 | 1차 (공식 문서, 요약 경유) | §5.3 |
| 11 | **텔레메트리가 OTel이 아니라 제품 애널리틱스(PostHog US)다.** 로컬 랜덤 ID 기준 익명, 이벤트 화이트리스트, 비수집 목록을 명시(경로·레포명·브랜치명·URL·커밋 메시지·프롬프트/응답·터미널 내용·원본 에러 메시지). 옵트아웃 3경로(`DO_NOT_TRACK=1`, `ORCA_TELEMETRY_DISABLED=1`, 설정 토글) | 1차 (공식 문서, 요약 경유) | §7 |
| 12 | **레포의 `CLAUDE.md`는 한 줄 `@AGENTS.md` 다.** 실제 내용은 60줄짜리 `AGENTS.md` 하나이고, 내용이 아키텍처 설명이 아니라 **금지 규칙 위주**(max-lines disable 금지, `utils`/`helpers` 명명 금지, 플랫폼 분기 강제) | **1차 (레포 원본)** | §8 |
| 13 | **레포는 실제 제품 소스다** — `src/`, `mobile/`, `native/`, `skills/`, `electron.vite.config.ts`, `pnpm-workspace.yaml` 존재. 문서·래퍼 저장소가 아니다. 라이선스 MIT | **1차 (GitHub API contents)** | §1.2 |
| 14 | **가격은 앱이 무료·오픈소스이고, 수익화는 Enterprise 문의 창구뿐이다** — Enterprise 페이지에 가격표·플랜 비교가 없고 이메일 문의로만 안내. SOC2·자체 호스팅을 문구로 주장 | 1차 (공식 페이지, 요약 경유) | §1.3 |
| 15 | **성장 속도가 이례적이다** — 저장소 생성 2026-03-17, 조사 시점(2026-08-03) ★35,992 / fork 2,531 / 열린 이슈·PR 합계 2,941. 약 4.5개월 | **1차 (GitHub API)** | §1.2 |
| 16 | **"any CLI agent" 가 실제 설계 주장이다** — README에 명명된 에이전트 **29종** + *"if it runs in a terminal, it runs in Orca"*. 즉 에이전트별 통합이 아니라 **터미널 기반 범용 수용**이 전략 | **1차 (레포 README)** | §1.4 |

### 0.3 근거 등급

| 등급 | 무엇 | 취급 |
|---|---|---|
| **1차 (레포 원본)** | `raw.githubusercontent.com` 원문, GitHub REST API 응답 | 그대로 인용 |
| **1차 (로컬 실측)** | 이 머신의 Orca 1.4.158, `orca --help`, `orca agent-context --json`, `~/.claude/skills/` | 그대로 인용, 버전 명시 |
| **1차 (공식 문서, 요약 경유)** | onorca.dev 문서 페이지. 단 **WebFetch 요약기를 거쳤다** — 인용부호 안의 영문만 원문으로 취급 | 수치는 재확인 없이 인용하지 않는다 |
| **부재 확인** | 찾았으나 없었다 | §4.3 |

### 0.4 마케팅 문구와 실물의 대조

요약기를 거친 첫 수집에서 랜딩 페이지와 README가 어긋난 지점이 있었다. 1차로 되돌려 정리한다.

| 항목 | 첫 수집 | 1차 확인 | 판정 |
|---|---|---|---|
| 사전 설정 에이전트 수 | "25+" (랜딩) / "40개 이상"(요약) | README에 **명명 29종** + "any CLI agent" | 둘 다 부정확. **29 + 범용 수용**이 실물 |
| 이슈 수 | "1.4k 이슈, 1.6k PR" | API `open_issues_count` = **2,941** | 모순 아님. API 값은 PR 포함 합계 |
| ★ / fork | 36k / 2.5k | **35,992 / 2,531** | 일치 |
| 라이선스 | "무료 및 오픈소스 MIT" | LICENSE = MIT, `src/` 실물 존재 | **성립** (§1.2) |
| 가격 | (랜딩에 없음) | Enterprise 페이지도 가격 미기재 | §1.3 |

---

## 1. 제품의 실체

### 1.1 무엇이라고 주장하는가

랜딩의 정의는 *"IDEs were built for you. An ADE is built for you and your agents"* 이고, README의 한 줄은 **"The AI Orchestrator for 100x builders"** 다. 즉 자기 규정이 "에이전트용 IDE"가 아니라 **"사람과 에이전트가 공유하는 작업 환경"** 이다.

제품의 중심 문장은 README에 있다.

> "Run Codex, ClaudeCode, OpenCode or Pi side-by-side — each in its own worktree, tracked in one place."

**워크트리 = 격리 단위**, **에이전트 = 워크트리의 거주자**, **앱 = 그 전체의 추적기**. 이 세 줄이 나머지 기능 전부의 배치를 결정한다.

### 1.2 저장소 실측

`GET /repos/stablyai/orca` (2026-08-03):

| 항목 | 값 |
|---|---|
| 라이선스 | MIT |
| 주 언어 | TypeScript |
| 생성 | 2026-03-17 |
| 최종 푸시 | 2026-08-03 |
| ★ / fork | 35,992 / 2,531 |
| 열린 이슈+PR | 2,941 |
| topics | `ade`, `agent-ide`, `parallel-agents`, `worktrees`, `ghostty`, `orchestration`, `yc-backed` … |

루트 디렉터리에 `src/`, `mobile/`, `native/`, `skills/`, `skill-guides/`, `skill-stubs/`, `tests/`, `electron.vite.config.ts`, `pnpm-workspace.yaml`, `Casks/` 가 있다. **문서 저장소나 얇은 래퍼가 아니라 출하되는 앱의 소스다.** "무료 및 오픈소스"라는 랜딩 주장은 이 층에서 성립한다.

개발사는 Stably Inc.(YC 지원). Windows 코드 서명은 SignPath.io 후원.

### 1.3 수익 모델 — 확인된 것과 확인 안 된 것

`/enterprise` 페이지에 **가격표도, 플랜별 비교도 없다.** 문구로 주장하는 것은 로컬 우선 워크스페이스, 격리 워크트리 기반 리뷰 가능한 변경, 승인된 에이전트·통합의 롤아웃 가이드, SOC2, git 히스토리 기반 감사 추적, 역할 기반 배포 경로, 자체 호스팅 옵션이고, 구체 사항은 이메일 문의로 넘긴다.

**따라서 "무료"의 범위는 앱 전체이고, 유료 경계가 어디인지는 공개되어 있지 않다.** SOC2 인증 여부를 1차로 확인하지 않았다(§10).

### 1.4 지원 에이전트 — 전략이 통합이 아니라 수용이다

README가 먼저 못을 박는다.

> "Works with **any CLI agent** — if it runs in a terminal, it runs in Orca."

그 아래 명명된 것이 29종이다: Claude Code, Codex, Grok, Cursor, GitHub Copilot, OpenCode, MiMo Code, Amp, OpenClaude, Antigravity, Pi, oh-my-pi, Hermes Agent, Devin, Goose, Auggie, Autohand Code, Charm, Cline, Codebuff, Command Code, Continue, Droid, Kilocode, Kimi, Kiro, Mistral Vibe, Qwen Code, Rovo Dev.

**이 전략의 대가가 문서에 드러난다** — 에이전트별 통합(계정 전환, 사용량 추적)은 Claude Code와 Codex 두 종에만 별도 페이지가 있다. 즉 **수용은 보편적이고 통합은 선택적**이다.

---

## 2. 스킬 배포 — 이 조사에서 가장 쓸모 있는 부분

### 2.1 구조

레포에 병렬로 세 디렉터리가 있다.

| 디렉터리 | 내용 |
|---|---|
| `skill-stubs/` | 8개 `.md` — frontmatter 없는 스텁 본문 |
| `skills/` | 8개 디렉터리 — 각각 `SKILL.md` 하나 (orca-cli의 경우 3,835 bytes) |
| `skill-guides/` | 8개 `.md` — 전체 가이드 (바이너리가 서빙하는 원본) |

이 머신에 설치된 `~/.claude/skills/orca-cli/SKILL.md`는 **78줄**이고, 그중 본문은 `skill-stubs/orca-cli.md`와 동일하다. 반면 `orca skills get orca-cli`가 내는 실제 가이드는 **331줄**이다(`orchestration`은 254줄).

### 2.2 이유가 파일 안에 적혀 있다

스텁 첫 문단이 원문 그대로:

> "This file is a discovery stub, not the usage guide. The full, version-matched Orca CLI reference is served by the `orca` binary itself — kept out of this file on purpose so it can never drift from the binary that will actually run your commands."

그리고 마지막에 금지가 붙는다:

> "Don't guess subcommands or flags from memory or from a cached copy of this stub. They change between Orca releases, and this file deliberately no longer lists them."

*"no longer"* 라는 표현이 중요하다. **한 번은 스텁에 플래그를 적었다가 뺐다는 뜻이다.** 설계가 아니라 겪은 뒤의 수정이다.

스텁은 추가로 **실행 파일 해석 순서**까지 규정한다 — `ORCA_CLI_COMMAND` → (dev 체크아웃이면) `orca-dev` → (Orca 터미널 밖 Linux면) `orca-ide` → `orca`. 세 번째 항목의 이유가 실물이다: Linux에서 맨 `orca`는 보통 **GNOME Orca 스크린 리더**로 잡혀 사용자 머신에서 음성이 시작된다. 그리고 *"If the selected executable cannot run, report its exact error and stop"* — **폴백 금지**를 명시한다(다른 빌드를 조용히 때릴 위험).

구버전 대비 폴백도 있다. `skills get`이 없는 바이너리로 확인된 경우에만, 읽기 전용 3개 명령(`status --json`, `worktree ps --json`, `terminal list --json`)으로만 방향을 잡으라고 범위를 잘라 둔다.

### 2.3 그 분할이 필요한 조건이 실측된다

| 항목 | 값 | 출처 |
|---|---|---|
| 이 머신의 앱 | **1.4.158** (`/Applications/Orca.app` Info.plist, 파일 mtime 7월 27) | 로컬 실측 |
| 최신 stable | **v1.4.164** (2026-08-02T08:56Z) | GitHub releases API |
| 그 사이 stable | 1.4.162(07-30), 1.4.163(07-31), 1.4.164(08-02) | 〃 |
| rc 채널 | v1.4.165-rc.0 (08-02) 등 rc가 stable마다 여러 개 | 〃 |

**약 1~2일에 한 번 stable이 나간다.** 스킬 파일에 플래그를 적어 배포하면 사용자의 로컬 사본은 구조적으로 뒤처진다. 스텁의 주장은 수사가 아니라 이 릴리스 속도의 직접 결과다.

### 2.4 배포 채널

설치는 하네스 전용 경로가 아니라 범용 설치기를 쓴다.

```
npx skills add https://github.com/stablyai/orca --skill <name> --global
```

그리고 Orca 쪽에서도 **역방향 발견**을 한다 — Claude·Codex·Agent Skills·OMP(`~/.omp/agent/skills`)의 스킬 디렉터리를 스캔한다. 즉 스킬은 Orca의 자산이 아니라 **머신 공용 자산**으로 취급된다.

기본 에이전트 설정에 번들되는 것은 셋: `orca-cli`, `orchestration`, `computer-use`. 나머지(Linear, iOS/Android 에뮬레이터, per-workspace env)는 선택이다. — [skill-architecture](skill-architecture.md) 관측 #5(과제당 2–3개 최적)와 **우연히 같은 수**이지만, Orca가 그 근거를 대는 것은 아니다.

---

## 3. CLI 표면 — 206 커맨드를 문서로 옮기지 않는 방법

`orca agent-context`의 존재 자체가 관측 대상이다. 헬프의 분류가 **"Agent Discovery"** 다.

```
$ orca agent-context
206 commands (schema v1).
Run `orca agent-context --json` for the full machine-readable command schema.
```

`--json`은 **137,050 bytes**이고 구조는 `{schemaVersion, commandCount, commands[]}`. 각 항목의 실물:

```json
{"command": "agent hooks off", "path": ["agent","hooks","off"], "aliases": [],
 "argumentMode": "parsed",
 "summary": "Disable Orca-managed agent status hooks and remove local hook entries",
 "usage": "orca agent hooks off [--json]",
 "flags": ["help","json","pairing-code","environment","page"],
 "positionalArgs": [], "examples": ["orca agent hooks off"], "notes": []}
```

**세 층으로 갈라져 있다는 점이 요지다.**

| 층 | 크기 | 언제 읽히는가 |
|---|---|---|
| 스텁(`SKILL.md`) | 78줄 | 항상 (라우팅 표면) |
| 가이드(`skills get`) | 331줄 | 스킬 발동 후 1회 |
| 스키마(`agent-context --json`) | 137KB / 206커맨드 | 기계가 필요할 때만 |

[skill-architecture](skill-architecture.md) 관측 #17의 "본문 500줄 상한"은 **한 파일 안의 문제**였다. Orca는 같은 문제를 **파일 밖으로 밀어** 푼다 — 상한을 지키는 게 아니라, 상한에 걸릴 내용을 애초에 파일에 두지 않는다.

명령군은 다음과 같다(로컬 1.4.158 `--help` 기준): Startup(`open`/`serve`/`status`), Diagnostics, Agent Discovery, Skills, Environments, Environment Recipes(`vm recipe doctor`), Automations, Projects, Repos, Worktrees, Files, Terminals, **Orchestration**, **Computer Use**, Linear, Mobile Emulator(iOS Simulator), Browser Automation(`tab`/`snapshot`/`click`/`fill`/`goto`/`keypress`/`eval`).

---

## 4. 오케스트레이션 — 기제는 출하됐고 근거는 없다

### 4.1 모델

공식 문서가 다섯 요소로 정의한다.

| 요소 | 역할 |
|---|---|
| **Run** | *"지속적인 네임스페이스이자 홈 인박스"*. **배치나 스케줄링은 하지 않는다** |
| **Task** | 명세·의존성·상태를 가진 작업 항목 |
| **Dispatch** | 터미널에서의 시도. 워커 완료와 하트비트의 생명주기 권한 |
| **Message** | 인박스 메일 (상태·발송·worker_done·에스컬레이션·질문·하트비트) |
| **Decision gate** | 코디네이터 소유. 해결 전까지 태스크를 차단 |

태스크 상태: `pending` → `ready` → `dispatched` → `completed` / `failed` / `blocked`.

### 4.2 CLI 표면 (로컬 1.4.158 실측)

```
orchestration send / check / reply / inbox
orchestration task-create / task-list / task-update
orchestration dispatch / dispatch-show
orchestration ask            # 코디네이터에게 묻고 답이 올 때까지 블록
orchestration run / run-stop # 코디네이터 루프
orchestration gate-create / gate-resolve / gate-list
orchestration reset
```

그룹 주소(`@all`, `@idle`, `@codex`)로 방송이 되고, 워커는 종료 시 `worker_done`으로 *"작업 완료, 발견 사항, 남은 부분"* 을 요약해 올린다.

**설계상 눈에 띄는 두 가지.** 첫째, Run이 스케줄러가 아니라 **네임스페이스 + 인박스**로만 정의된다 — 배치 권한이 Dispatch로 내려가 있다. 둘째, `ask`가 **블로킹**이다. 워커가 막히면 추측하지 않고 멈춘다.

### 4.3 그러나 — 부재 확인

랜딩·README·문서·changelog 어디에도 **다중 에이전트 조율의 효능 수치가 없다.** 벤치마크도, A/B도, 사례 측정도 제시되지 않는다. 있는 것은 기능 서술과 GIF다.

**따라서 [agent-orchestration](agent-orchestration.md)의 결론은 이 문서로 흔들리지 않는다.** 그 문서의 근거는 벤더 실무 경험·NeurIPS 2025 실패율 41~86.7%·저장소 채택률 4.6%였고, Orca가 반대편에 놓는 것은 **"기제가 존재하고 출하된다"** 뿐이다. *가용성은 효능의 증거가 아니다.* Orca를 인용할 수 있는 대목은 "다중 에이전트가 낫다"가 아니라 **"조율을 CLI 원시요소로 노출하면 이런 어휘가 된다"** 쪽이다.

### 4.4 상태 저장 매체 — 실측

문서에 없어서 로컬에서 직접 열었다. `orca orchestration inbox --json` 응답에 `_meta.runtimeId`가 붙는 것이 단서였고(상태가 워크트리가 아니라 **런타임**에 매달려 있다), 실물은 여기 있다.

```
~/Library/Application Support/Orca/orchestration.db      (94 KB)
~/Library/Application Support/Orca/orchestration.db-shm
~/Library/Application Support/Orca/orchestration.db-wal
```

**SQLite, `journal_mode=wal`, 테이블 5개.** 읽기 전용으로 스키마만 확인했다(이 머신은 조율을 쓴 적이 없어 전 테이블 0행).

| 테이블 | 핵심 컬럼 |
|---|---|
| `messages` | `from_handle`/`to_handle`, `thread_id`, `sequence`(AUTOINCREMENT PK), `read`, `sender_pane_key`, `payload` |
| `tasks` | `parent_id`, `deps`(기본 `'[]'`), `spec`, `status`, `result` |
| `dispatch_contexts` | `task_id`, `assignee_handle`/`assignee_pane_key`, `failure_count`, `last_failure`, `last_heartbeat_at` |
| `decision_gates` | `task_id`, `question`, `options`(기본 `'[]'`), `resolution` |
| `coordinator_runs` | `spec`, `coordinator_handle`, `poll_interval_ms` |

CHECK 제약이 §4.1의 문서 서술보다 정확한 열거를 준다.

| 열거 | 값 |
|---|---|
| `messages.type` | `status`, `dispatch`, `worker_done`, **`merge_ready`**, `escalation`, **`handoff`**, `decision_gate`, `heartbeat` (**8종**) |
| `messages.priority` | `normal`, `high`, `urgent` |
| `tasks.status` | `pending`, `ready`, `dispatched`, `completed`, `failed`, `blocked` (문서와 일치) |
| `dispatch_contexts.status` | `pending`, `dispatched`, `completed`, `failed`, **`circuit_broken`** |
| `decision_gates.status` | `pending`, `resolved`, **`timeout`** |
| `coordinator_runs.status` | `idle`, `running`, `completed`, `failed` |

**자료로만 읽었을 때 안 보이던 것 셋.**

1. **디스패치에 서킷 브레이커가 있다** — `circuit_broken` + `failure_count` + `last_failure`. 즉 "워커에 태스크를 다시 던지는 것"이 무한 재시도가 아니라 **차단 상태를 갖는 상태기계**다.
2. **게이트가 `timeout`으로 끝날 수 있다** — 코디네이터가 답하지 않는 경우가 상태로 모델링돼 있다. 사람이 없는 상황을 실패가 아니라 별도 종결로 처리한다.
3. **코디네이터 루프는 폴링이다** — `poll_interval_ms` 기본 **2000**. 이벤트 구독이 아니라 2초 폴이고, 그 값이 런당 컬럼이라 조정 가능하다.

**위치가 요지다.** 이 원장은 워크트리 안이 아니고, 레포별도 아니고, **머신 전역 하나**다. [worktree-shared-state](worktree-shared-state.md)가 7종에서 확인한 패턴 — *"워크트리를 격리 단위로 쓰되 상태는 워크트리 바깥의 단일 원장에 둔다"* — 의 **여덟 번째 사례이고, 매체는 그 문서의 네 갈래 중 "로컬 SQLite"(Crystal·Vibe Kanban과 같은 칸)다.** 다만 Crystal이 대화·터미널 출력·diff까지 DB에 넣은 것과 달리, Orca는 **조율만** 여기 두고 터미널 스크롤백은 별도(`terminal-history/`), 세션 파싱 캐시도 별도(`ai-vault/`)로 갈라 놓았다.

같은 디렉터리에서 함께 관측된 것: `daemon/daemon-v28.{pid,sock,token}`(§6.2의 데몬 실물, 버전 번호가 파일명에 박혀 있다), `agent-hooks/`, `codex-runtime-home/`(+`trust-grant-ledger.json`), `terminal-history/`, `orca-e2ee-keypair.json`, `orca-runtime.json`.

---

## 5. 워크트리 모델과 공유 상태

### 5.1 생성과 격리

각 작업이 자기 워크트리를 받고, 생성은 백그라운드 `git fetch` + `git worktree add`다. 시작 지점은 기본 브랜치 / 로컬 브랜치(PR 위에 쌓기) / 커밋 SHA / 원격 브랜치 중 선택. 브랜치명은 워크트리 이름에서 유도하되 GitHub PR·Linear·Jira가 연결되면 그쪽을 쓰고, **이모지는 git 브랜치명에서 읽을 수 있는 shortcode로 변환**한다.

문서가 명시하는 성질 하나가 중요하다 — *"모든 워크트리는 실제 git 워크트리이므로 CLI에서도 표준 git 명령어를 쓸 수 있다"*. 즉 **탈출구가 막혀 있지 않다.**

### 5.2 gitignore된 것들 — 관측 #14의 세 번째 사례

[worktree-shared-state](worktree-shared-state.md) 관측 #14는 `.worktreeinclude`가 Conductor + Claude Code에서 사실상 표준이 됐다는 것이었다. **Orca가 세 번째다.** 그리고 #14b(정책 수렴)도 같이 성립한다.

| 수단 | 대상 |
|---|---|
| Worktree Shared Paths (설정) | 기본 체크아웃에서 경로 공유 |
| `orca.yaml` | gitignored 디렉터리 공유 |
| `.worktreeinclude` | gitignored 파일/디렉터리 복사 |
| **setup script** | 나머지 전부 |

레포 루트의 `orca.yaml` 실물이 마지막 칸을 증명한다 — 전체 내용이 이것뿐이다:

```yaml
scripts:
  setup: |
    node config/scripts/run-internal-dev-setup.mjs
    pnpm install
```

**복사로 되는 것은 복사하고, 안 되는 것은 스크립트로 넘긴다** — Conductor·Claude Code와 동일한 경계다. 새 관측이 아니라 기존 관측의 강화다.

### 5.3 "Worktree checkpoints"는 체크포인트가 아니다

이름과 실물이 어긋난다. 문서상 이것은 **워크트리에 붙는 자유 형식 코멘트 필드**이고, 선택적으로 카드 상태(`todo`/`in-progress`/`in-review`/`completed`)를 함께 세팅한다.

```
orca worktree set --worktree active --comment "waiting on review" \
                  --workspace-status in-progress --json
```

git 스냅샷도, 복원 지점도 아니다. 용도는 *"사람 협업자를 채팅 없이 루프에 유지"* 다. **에이전트가 자기 상태를 사람이 보는 곳에 쓰는 채널**이라고 읽는 편이 정확하다.

---

## 6. 실행 위치 4종 — 축은 "런타임을 누가 소유하는가"

### 6.1 네 배치

| 모드 | 런타임 주인 | 특징 |
|---|---|---|
| **로컬 데스크톱** | 노트북 | 기본 경로. *"Day-to-day coding, fast iteration"* |
| **SSH 타겟** | **노트북의 Orca** | 에이전트·워크트리는 원격, 에디터/diff/UI는 로컬. **다중 클라이언트 불가** |
| **원격 Orca 서버** | **원격 머신** | `orca serve` 또는 Tailscale 페어링. 노트북·웹·모바일·자동화가 **같은 런타임 공유** |
| **워크스페이스별 클라우드 VM** | 사용자의 클라우드 계정 | 워크트리마다 일회용 샌드박스. `orca vm recipe doctor`로 레시피 검증 |

SSH와 원격 서버의 차이가 이 축을 가장 잘 드러낸다. **둘 다 원격에서 돌지만, 세션의 소유자가 다르다.** SSH는 노트북이 죽으면 세션이 흩어지고, 원격 서버는 세션이 서버에 남아 다른 클라이언트가 이어받는다.

### 6.2 무엇이 죽으면 무엇이 사라지는가

세션 복원이 보존하는 것: 열린 워크트리, 워크트리별 페인 레이아웃(중첩 분할·포커스 탭 포함), 실행 중 에이전트, 터미널 스크롤백(앱이 닫혀 있던 동안의 출력 포함), 포커스 상태.

경계가 명확하다.

| 죽는 것 | 결과 |
|---|---|
| 앱 (Cmd-Q, 자동 업데이트, 크래시) | 데몬이 PTY를 계속 들고 있음 → 재시작 시 **재연결** |
| **호스트** (재부팅, 커널 패닉) | *"The daemon dies when the host does"* → 레이아웃·마지막 스크롤백만 복원, 에이전트는 초기화 |

훅 엔드포인트는 디스크에 저장돼 앱 재시작 후에도 장기 세션이 서버에 붙어 있는다.

---

## 7. 텔레메트리 — OTel이 아니라 제품 애널리틱스

[observability](observability.md)가 다룬 것은 Claude Code의 OTel 규격(메트릭 8종·이벤트 15종·스팬 6종)이었다. **Orca는 다른 층에 있다** — 목적이 하네스 내부 진단이 아니라 제품 사용 통계다.

| 항목 | 내용 |
|---|---|
| 백엔드 | PostHog Cloud (US), PostHog 기본 보관 정책 |
| 식별 | *"Events are keyed by a random ID stored locally on your machine. No account, email, IP address, or user name is collected."* |
| 수집 | 앱 실행(라이프사이클), 레포·워크스페이스 추가 시 **방법(how)**, 에이전트 시작 시 **종류**, 에이전트 에러의 **거친 분류**, 화이트리스트된 설정 토글, 빌드·플랫폼 정보(버전·OS·CPU 아키텍처·릴리스 채널) |
| **비수집(명시)** | 파일 경로, 저장소 이름, 브랜치명, URL, 커밋 메시지, 에이전트 프롬프트·응답, 터미널 내용, **원본 에러 메시지**, 계정 정보, 정확한 지리정보 |
| 옵트아웃 | 설정 토글 / `DO_NOT_TRACK=1` / `ORCA_TELEMETRY_DISABLED=1` |

**관측할 가치가 있는 설계 결정 둘.** 첫째, *"어떻게 추가했는가"* 는 보내고 *"무엇을 추가했는가"* 는 안 보낸다 — 경로·레포명을 지우고 방법만 남기는 분리. 둘째, **원본 에러 메시지를 안 보내고 거친 분류만 보낸다** — 진단 능력을 자발적으로 낮춘 대가로 프라이버시 경계를 지킨다. observability 문서가 반복한 구분(emit vs conform)과는 다른 축이고, 여기 축은 **emit vs redact**다.

`DO_NOT_TRACK` 이라는 **생태계 공용 규약**을 함께 받는 점도 기록해 둔다.

---

## 8. 컨텍스트 파일 — 한 줄짜리 `CLAUDE.md`

레포 루트 `CLAUDE.md` 전체:

```
@AGENTS.md
```

**한 줄, import 하나다.** 실제 내용은 `AGENTS.md` 60줄에 있다. [context-file-content](context-file-content.md) 축에 대한 1차 실물로, **두 벤더용 파일을 두되 내용은 하나만 유지하는** 처리다.

`AGENTS.md`의 내용 성격도 관측 대상이다 — 아키텍처 설명이 아니라 **금지와 명명 규칙 위주**다.

| 섹션 | 성격 |
|---|---|
| Design System | 위임 — `docs/STYLEGUIDE.md`와 `main.css` 토큰으로. *"Don't invent new color values…"* |
| Style | *"BE CONCISE. 1 LINE if possible"*, 주석은 WHY not HOW |
| Lint Rules | **NEVER** `max-lines` disable 추가 금지 |
| File and Module Naming | `helpers`/`utils`/`common`/`misc` 금지. *"they carry zero info and tend to become dumping grounds"* |
| Worktree Safety | *"Never follow absolute paths from subagent results that point to the main repo"* |
| Cross-Platform | `e.metaKey` 하드코딩 금지, `CmdOrCtrl` 사용 |

마지막에서 두 번째 항목이 특히 이 시리즈와 맞물린다 — **서브에이전트 결과에 담긴 절대 경로가 메인 레포를 가리켜 워크트리 격리가 깨지는 실패**를 컨텍스트 파일 규칙으로 막고 있다. worktree-shared-state 관측 #7(경로 문자열로 워크트리를 식별한 대가)과 같은 실패 계열이며, Orca는 그 대응을 **모델에게 거는 규칙**으로 두었다.

---

## 9. grid fin 축으로의 재배열

**결정이 아니다.** 위 관측을 기존 조사 축에 붙여 두는 것뿐이다.

| grid fin 축 | Orca가 보태는 것 | 성격 |
|---|---|---|
| [skill-architecture](skill-architecture.md) | 스텁(78) / 가이드(331) / 스키마(206커맨드) **3층 분할**. 500줄 상한을 파일 밖으로 밀어 푸는 방식 | **새 데이터포인트** |
| [harness-distribution](harness-distribution.md) | 가이드를 git이 아니라 **바이너리에 묶어** 배포. 이유가 릴리스 속도(1~2일)로 실측됨. 설치는 `npx skills add`(범용 채널) | **새 데이터포인트** |
| [worktree-shared-state](worktree-shared-state.md) | ① 관측 #14·#14b의 **세 번째 사례** (`.worktreeinclude` + `orca.yaml` + setup script) ② **관측 #1의 여덟 번째 사례** — 조율 원장이 머신 전역 SQLite 하나(§4.4) | **기존 관측 연장 + 1차 실측 추가** |
| [agent-orchestration](agent-orchestration.md) | Run/Task/Dispatch/Message/Gate **어휘** + 스키마 실물(서킷 브레이커·게이트 timeout·2초 폴링). 효능 근거는 **없음** | **어휘·기제만. 결론 불변** |
| [state-and-continuity](state-and-continuity.md) | 런타임 소유권 4배치와, 앱 사망 ≠ 호스트 사망의 경계 | **새 데이터포인트** |
| [observability](observability.md) | OTel 밖의 대조군. **emit vs redact** 축(원본 에러 메시지 비수집) | **대조군** |
| [context-file-content](context-file-content.md) | `CLAUDE.md` = `@AGENTS.md` 한 줄. 내용은 금지 규칙 위주 60줄 | **새 데이터포인트** |
| [enforcement-mechanisms](enforcement-mechanisms.md) | 저장소별 `.claude/`·`.codex/` 훅을 워크트리 실행 시 **그대로 태운다** — 하네스가 훅을 대체하지 않고 통과시키는 배치 | 관련 |

**가장 옮길 만한 하나를 꼽으면 §2다.** grid fin은 copier로 배포되고([harness-distribution](harness-distribution.md)) `gridfin` 바이너리를 갖는다(). 그러면 **"스킬 본문을 템플릿으로 배포할 것인가, 바이너리가 서빙할 것인가"** 가 실제 갈림길이 된다. Orca는 후자를 골랐고 그 이유를 파일에 적어 두었다 — 다만 Orca의 릴리스 속도(1~2일)가 그 선택의 전제였다는 점도 같이 기록한다. **전제가 다르면 결론이 따라오지 않는다.**

---

## 10. 확인하지 않은 것 / 열린 질문

| 항목 | 왜 미확인 |
|---|---|
| SOC2 인증의 실물 | Enterprise 페이지 문구만 확인. 인증서·감사 보고서를 보지 않았다 |
| 유료 경계 | 공개돼 있지 않다. Enterprise가 앱 기능을 게이팅하는지 여부 불명 |
| ~~`orchestration`의 상태 저장 매체~~ | **해소됨 — §4.4.** 머신 전역 SQLite(WAL) 단일 파일, 5테이블. 다만 **운영 중 데이터는 못 봤다**(전 테이블 0행) — 실제 부하에서 어떻게 쓰이는지, `sender_pane_key`/`assignee_pane_key`가 워크트리 재생성 후에도 유효한지는 미확인 |
| 다중 에이전트 효능 | 부재 확인(§4.3). Orca 쪽에 자료가 없다 |
| 열린 이슈 2,941건의 성격 | 수만 봤다. 안정성 신호인지 성장 신호인지 판별 안 함 |
| 모바일 앱의 권한·데이터 경계 | 문서 미확인 |
| `skills/` 8종 각각의 내용 | `orca-cli`·`orchestration`만 실측. 나머지 6종은 description만 봤다 |
