# cmux (cmux.com / manaflow-ai) — 단일 시스템 심층 조사

**최초 작성**: 2026-08-03
**최종 수정**: 2026-08-03
**대상 프로젝트**: grid fin (신규 개인용 개발 하네스)
**조사 계기**: *"cmux에 대해서도 조사해"* — [Orca 조사](orca-ade.md)의 자매편
**조사 도구**: WebSearch 1회, WebFetch 2회(cmux.com·pricing), GitHub REST API 5회, `raw.githubusercontent.com` 4회, **로컬 실측 비중이 크다**(설치된 cmux 0.64.21 + `cmux` CLI + `capabilities` 소켓 응답 + `~/.claude/skills/cmux-*` 20종 + **`~/.cmuxterm/workstream.jsonl` 104,693건 / `events.jsonl` 2종 직접 집계**)
**성격**: 조사. grid fin의 설계 결정은 하지 않는다. §8은 관측을 기존 조사 축으로 재배열한 것이며 결정이 아니다.

**이 문서는 [Orca 조사](orca-ade.md)와 짝이다.** 같은 제품 범주(에이전트용 작업 환경)에서 **같은 문제에 반대 답을 낸 두 시스템**이라, 단독으로 읽는 것보다 대조로 읽는 편이 값이 크다. §0.5가 그 대조표다.

**그리고 이 문서는 이 시리즈에서 로컬 1차 데이터가 가장 두꺼운 조사다.** cmux가 이 머신에서 34일간 남긴 감사 로그 104,693건을 직접 집계했다(§5). 다만 **n=1 머신·1 사용자**이고 그 로그에는 grid fin 조사 작업 자체가 포함돼 있다 — cmux의 성질이 아니라 **이 환경의 실측**으로 읽어야 한다.

관련 문서 (이 문서가 데이터를 보태는 축)
- [orca-ade.md](orca-ade.md) — 자매편. §2·§0.5가 정면 대조
- [observability.md](observability.md) — **§5가 이 문서의 중심.** *"기록은 있고 소비가 없다"* 와 *"로그 13,342건이 전부 `tool":"unknown"`"* 에 대한 반대 사례이자, **같은 병의 다른 형태**
- [enforcement-mechanisms.md](enforcement-mechanisms.md) — §4. 참고 하네스에서 `deny`·`ask`·`sandbox`가 **0건**이었던 곳에, 실제로 도는 사람 승인 게이트의 실물
- [skill-architecture.md](skill-architecture.md) — §2. 관측 #17(500줄 상한)·#5(과제당 2–3개)에 **정반대 방향의 데이터포인트**
- [harness-distribution.md](harness-distribution.md) — §2.4. 라이선스·배포 채널·버전 핀 부재
- [hook-skill-frontmatter-probe.md](hook-skill-frontmatter-probe.md) — §6. 훅 층의 벤더별 실물 경로 16종

---

## 0. 조사 요약

### 0.1 두 문장

**cmux는 Ghostty(libghostty) 기반 네이티브 macOS 터미널(Swift/AppKit)에 워크스페이스·소켓 API·내장 브라우저·에이전트 훅 통합을 얹은 시스템으로, 라이선스는 GPL-3.0-or-later에 상업 조건 유보를 붙인 형태고 수익은 클라우드 VM 구독에서 낸다.** 이 조사의 값은 제품 소개가 아니라 **이 머신에 34일치 실물 감사 로그가 있었다는 것**이다 — 도구 이름이 전부 살아 있는 104,693건이 남아 있는데(참고 하네스의 `"tool":"unknown"` 문제의 정반대), **정작 사람의 승인 요청 328건은 전부 `status: {"pending": {}}` 으로 얼어 있고 — 결정이 담길 칸이 빈 객체다 — 결말을 찾아갈 이벤트 스트림은 18시간치만 남는다.**

### 0.2 관측

| # | 관측 | 등급 | 위치 |
|---|---|---|---|
| 1 | **감사 로그가 실물로 있고 도구 이름이 전부 살아 있다** — `~/.cmuxterm/workstream.jsonl` **104,693건 / 174 MB / 34일**(2026-06-30 → 2026-08-03). `toolUse` 81,645건 **전부** 도구명 보유(Bash 41,763 / Read 17,134 / Edit 10,810). [observability](observability.md)의 *"13,342건이 전부 `tool":"unknown"`"* 의 **정반대 사례** | **1차 (로컬 로그 직접 집계)** | §5.1 |
| 2 | **그런데 같은 로그가 다른 곳에서 같은 병을 앓는다** — `permissionRequest` **328건이 전부 `status: {"pending": {}}`** 이다(Swift 열거형 인코딩이고 **연관값이 빈 객체** — 결정이 담길 칸 자체가 비어 있다). 328건 모두 `createdAt == updatedAt`, id 중복 0, `payload.permissionRequest`는 `{requestId, toolName, toolInputJSON}` 뿐. **추가 기록(append)만 하고 결말을 갱신하지 않는다** | **1차 (로컬 로그 직접 집계)** | §5.3 |
| 3 | **결말을 찾으러 간 이벤트 스트림은 18시간짜리다** — `events.jsonl` + `.1` 두 파일이 **2026-08-02T11:29 → 2026-08-03T05:27**만 담는다(회전). 반면 `workstream.jsonl`은 34일치를 회전 없이 쌓는다. **요청은 영구, 결말은 18시간** → 34일 전 요청은 구조적으로 짝을 잃는다 | **1차 (로컬 로그 직접 집계)** | §5.3 |
| 4 | **그리고 그 이벤트에도 결정 필드가 없다.** feed 이벤트 payload 키 전수: `hook_event_name`, `phase`, `tool_name`, `tool_input`, `tool_input_length`, `context`, `context_length`, `result`, `is_error`, `redacted_fields`, `session_id`, `cwd`, `workspace_id` … **`decision`/`allow`/`deny` 계열이 없다**(`result`는 도구 결과지 승인 결정이 아니다). 보존된 두 파일에서 `hook_event_name`이 PermissionRequest인 feed 이벤트 **0건** | **1차 (로컬 로그 직접 집계)** | §5.3 |
| 5 | **게이트율은 모드가 정한다 — 집계치 하나로 말하면 안 된다.** `toolUse`의 `permissionMode`는 **auto 67,092 / (없음) 10,826 / default 3,616 / plan 60 / acceptEdits 31 / bypassPermissions 22**. 그리고 328건의 승인 요청은 **default 319 · acceptEdits 6 · auto 3**. 즉 **default 모드에서 319/3,616 ≈ 8.8%**(모드 미상 10,826건 때문에 **상한값**), auto에서는 사실상 0. 집계치 328/81,645 = 0.40%는 **게이트율이 아니다** — 분모의 82%가 애초에 안 묻는 모드다 | **1차 (로컬 로그 직접 집계)** | §5.2 |
| 6 | **Feed의 fail-open은 설계이고 문서에 적혀 있다** — *"Feed is advisory, not blocking. The hook waits at most 120 seconds … On timeout the bridge emits `{}` (no decision) and the agent falls through to its own in-TUI prompt."* 모델 이름까지 명시(*"Vibe Island's 'soft wait' model"*). **이 시리즈의 fail-open 계보 6건은 전부 사고였다. 이것이 첫 의도된 fail-open이다** | **1차 (레포 docs 원문)** | §4.2 |
| 7 | **그 대가로 훅 타임아웃을 규격 기본값의 24배로 올린다** — 블로킹 Feed 항목의 per-event 타임아웃을 **약 120~125초**(Claude PermissionRequest는 125초)로 올려 **기본 5,000 ms 훅 타임아웃**을 피한다. 사람이 30초 고민하는 것이 훅 실패가 되지 않게 하려는 조치 | **1차 (레포 docs 원문)** | §4.2 |
| 8 | **에이전트 훅 통합이 벤더별 실물 경로 표로 공개돼 있다 — 17종.** 각 행이 *바이너리 / 설치 파일 경로 / 세션 복원 명령 / Feed 브리지에 쓰는 훅 이벤트* 넷을 짚는다(`~/.codex/hooks.json`, `~/.cursor/hooks.json`(`beforeShellExecution`), `~/.gemini/settings.json`(`PreToolUse`) …). **훅 층의 벤더 간 대응표로는 이 시리즈에서 본 것 중 가장 구체적이다** | **1차 (레포 docs 원문)** | §6 |
| 9 | **스킬 배포가 Orca와 정반대다.** cmux는 **전문(全文) 스킬 20종을 설치한다** — `SKILL.md` 합계 **1,949줄**, 추가로 `references/` **34파일 2,704줄**, 18/20에 `agents/openai.yaml`. Orca는 같은 문제를 **스텁 78줄 + 바이너리 서빙**으로 풀었다 | **1차 (로컬 설치본 + 레포)** | §2 |
| 10 | **그 20종 중 절반 이상이 "cmux를 개발하는 법"이다** — architecture·backend·billing·dev-workflow·ghostty·localization·release·testing·shared-behavior·socket-policy·debugging. **제품이 자기 기여자 하네스를 스킬로 출하한다** | **1차 (로컬 설치본)** | §2.2 |
| 11 | **버전 핀이 없다.** `cmux docs <topic>`은 텍스트를 서빙하지 않고 **`raw.githubusercontent.com/.../main/` URL과 `curl` 명령을 출력**한다. Orca가 바이너리에 묶은 부분을 cmux는 **`main` 브랜치에 위임**한다 — 항상 최신이지만 **설치된 앱 버전과 일치한다는 보장이 없다** | **1차 (로컬 CLI 출력)** | §2.3 |
| 12 | **소켓 API가 협상 가능한 표면으로 노출된다** — `cmux capabilities`가 `protocol: "cmux-socket"`, `version: 2`, **capabilities 35종**(`terminal.render_grid.verified_replay.v1` 같은 버전 접미사), **methods 303종**(browser 92 · workspace 50 · simulator 30 · surface 28 · mobile 25 …), `access_mode: "cmuxOnly"` | **1차 (로컬 소켓 응답)** | §3.1 |
| 13 | **tmux 호환 명령을 별도 구획으로 출하한다** — `capture-pane`·`swap-pane`·`join-pane`·`break-pane`·`respawn-pane`·`set-hook`·`bind-key`·`copy-mode`·`set-buffer`·`wait-for`·`display-message` 등. **새 어휘를 강요하지 않고 기존 손버릇을 받는다** | **1차 (로컬 `--help`)** | §7 |
| 14 | **라이선스가 Orca와 갈린다 — GPL-3.0-or-later + 상업 조건 유보.** LICENSE 서문이 *"Manaflow may separately offer commercial terms **only for material for which it controls the necessary rights**"* 라고 범위를 스스로 좁히고, 제3자 자료·외부 기여는 재라이선스되지 않는다고 명시. GitHub API는 이 서문 때문에 **`NOASSERTION`** 으로 잡는다 | **1차 (LICENSE 원문 + API)** | §1.2 |
| 15 | **가격이 공개돼 있고 유료의 실체가 클라우드 컴퓨트다** — Free $0 / **Pro $30/월**(4 vCPU·16 GB VM에서 **월 20 활성 compute-hour** + 모델 게이트웨이 + iOS 앱) / Team $35/user/월 / Enterprise(자체 호스팅·에어갭·SSO/SAML·감사 로그). **앱은 GPL로 풀고 컴퓨트를 판다** | 1차 (공식 가격 페이지, 요약 경유) | §1.3 |
| 16 | **릴리스 주기가 Orca의 10분의 1이다** — v0.64.19(07-14) → v0.64.20(07-19) → v0.64.21(**08-03**). **약 2주**. Orca는 1~2일이었다. §2.3의 "버전 핀 없음"이 덜 아픈 이유이자, 같은 선택이 서로 다른 전제 위에 선다는 근거 | **1차 (GitHub releases API)** | §2.3 |
| 17 | **Claude Code 통합을 위해 기본 권한을 약화시킨다** — cmux 래퍼가 Claude를 **`--allow-dangerously-skip-permissions`로 실행**한다. 문서 설명은 *"This does not enable bypass by default, but it lets a later `PermissionRequest` response switch the current session into `bypassPermissions`"* — **Feed의 Bypass 버튼을 살리기 위해 플래그를 미리 켠다** | **1차 (레포 docs 원문)** | §4.3 |
| 18 | **텔레메트리 정황이 PostHog이다** — 앱 지원 디렉터리에 `phc_`로 시작하는 파일(PostHog 프로젝트 키 접두어). **Orca와 같은 백엔드.** 다만 **cmux 쪽 텔레메트리 정책 문서는 확인하지 못했다**(§9) | 정황 (파일명) | §9 |

### 0.3 근거 등급

| 등급 | 무엇 | 취급 |
|---|---|---|
| **1차 (로컬 로그 직접 집계)** | 이 머신 `~/.cmuxterm/*.jsonl`을 Python으로 직접 집계. **집계만 하고 본문·인자는 읽지 않았다** | 수치 그대로. **단 n=1 머신·1 사용자 범위를 항상 함께 적는다** |
| **1차 (로컬 CLI/소켓)** | cmux 0.64.21 `--help`, `capabilities`, `docs` 출력 | 버전 명시 후 인용 |
| **1차 (레포 원문)** | `raw.githubusercontent.com` 원문(LICENSE·docs/*.md·skills.sh), GitHub REST API | 그대로 인용 |
| **1차 (로컬 설치본)** | `~/.claude/skills/cmux-*` 20종 실측 | 그대로 인용 |
| 1차 (공식 페이지, 요약 경유) | cmux.com · /pricing. **WebFetch 요약기를 거쳤다** | 인용부호 안 영문만 원문 취급 |
| 정황 | 파일명·경로에서 유추 | 단정하지 않는다 |

### 0.4 마케팅 문구와 실물의 대조

| 항목 | 표기 | 1차 확인 | 판정 |
|---|---|---|---|
| "무료 오픈소스 (GPL 라이선스)" | 랜딩 | LICENSE = **GPL-3.0-or-later + 상업 조건 유보 서문**. GitHub은 `NOASSERTION` | **성립하되 단순 GPL이 아니다.** 유보 범위가 서문에 명시(§1.2) |
| "Founders Edition" | 랜딩(요약 경유) | /pricing에는 **없다.** Free/Pro/Team/Enterprise 4종 | 요약기 아티팩트이거나 별도 표기. **가격표를 1차로 취급** |
| ★ / fork | — | **25,509 / 2,136** (API) | — |
| 열린 이슈+PR | — | **3,949** (API, PR 포함) | Orca(2,941)보다 많다 |
| "Electron 없음, 네이티브 Swift" | 랜딩 | 레포 주 언어 **Swift**, `cmux.xcodeproj`·`Packages/`·`Native/` 실재 | **성립** |

### 0.5 Orca와의 대조 — 같은 문제, 반대 답

| 축 | **Orca** | **cmux** |
|---|---|---|
| 구현 | TypeScript / Electron | **Swift / AppKit + libghostty** |
| 라이선스 | **MIT** | **GPL-3.0-or-later + 상업 유보** |
| 수익 | Enterprise 문의(가격 비공개) | **공개 가격표. 유료의 실체 = 클라우드 VM 시간** |
| 격리 단위 | **git 워크트리**(제품의 중심) | **워크스페이스**(디렉터리·SSH·VM). 워크트리는 **1급 개념이 아니다** — CLI `--help` 전체에 `worktree` 0회, 대신 `cmux.json`의 `commands`로 *"이미 있는 워크트리들을 레이아웃으로 여는"* 프리셋(`worktree-agents`)이 있다. **만들지 않고 열어 준다** |
| 에이전트용 문서 | **스텁 78줄 + 바이너리가 331줄 서빙** | **전문 스킬 20종 1,949줄 설치 + `references/` 2,704줄** |
| 문서 버전 정합 | **바이너리에 묶음**(드리프트 불가) | **`main`에 위임**(핀 없음) |
| 기계 판독 표면 | `agent-context --json` 206커맨드 | `capabilities` 35종 + **methods 303종**, 소켓 프로토콜 v2 |
| 릴리스 주기 | **1~2일** | **약 2주** |
| 조율 | Run/Task/Dispatch/Gate **원장(SQLite)** | **없음.** 대신 **사람 승인(Feed)** 과 알림 |
| 사람 개입 | 없음(코디네이터가 에이전트) | **Feed = 사람이 Allow/Deny를 누르는 단계** |
| 감사 기록 | 조율 DB(빈 상태로 확인) | **34일 104,693건 실물** |
| ★ / 생성 | 35,992 / 2026-03-17 | 25,509 / **2026-01-28** |

**한 줄로 줄이면 — Orca는 "에이전트를 병렬로 늘리는" 쪽에, cmux는 "늘어난 에이전트를 사람이 감당하는" 쪽에 무게를 뒀다.** Orca의 중심 기능이 워크트리 팬아웃과 조율 원장이고, cmux의 중심 기능이 알림·Feed 승인·감사 로그·tmux 호환이다.

---

## 1. 제품의 실체

### 1.1 무엇이라고 주장하는가

랜딩 문구는 *"The terminal built for multitasking, organization, and programmability"*, 저장소 설명은 *"Open source Ghostty-based macOS terminal with vertical tabs and notifications for AI coding agents"* 다.

**자기 규정이 "IDE"도 "ADE"도 아니라 터미널이다.** Orca가 *"IDEs were built for you. An ADE is built for you and your agents"* 로 새 범주를 주장한 것과 대비된다. cmux는 기존 범주(터미널)에 머물면서 **프로그래머빌리티**를 축으로 잡는다 — 그 선택이 §7의 tmux 호환 표면과 §3의 소켓 API로 일관되게 이어진다.

### 1.2 저장소와 라이선스

`GET /repos/manaflow-ai/cmux` (2026-08-03):

| 항목 | 값 |
|---|---|
| 주 언어 | **Swift** |
| 라이선스(API) | **NOASSERTION** |
| 생성 | 2026-01-28 |
| 최종 푸시 | 2026-08-03 |
| ★ / fork | 25,509 / 2,136 |
| 열린 이슈+PR | 3,949 |
| topics | `ghostty`, `macos`, `multiplexer`, `tmux`, `parallel-agents`, `programmability`, `workspace-manager` … |

**라이선스가 이 조사에서 가장 손이 많이 간 항목이다.** LICENSE 파일 692줄 중 앞 15줄이 서문이고, 본문은 GPL-3.0 전문이다. 서문의 요지:

> "Except where a file or accompanying notice states otherwise, material contributed under the cmux project license is licensed under the GNU General Public License v3.0 or later (GPL-3.0-or-later)."

그리고 상업 조건에 **스스로 범위를 좁히는 문장**이 붙는다.

> "Manaflow may separately offer commercial terms **only for material for which it controls the necessary rights**. Those terms do not relicense third-party material or outside contributions for which Manaflow lacks a separate grant."

**즉 전형적인 CLA 기반 전면 듀얼 라이선스가 아니다.** 외부 기여와 제3자 자료(libghostty 등)는 유보 대상에서 빠진다고 명시한다. GitHub API가 `NOASSERTION`을 내는 것도 이 서문 때문이다 — 파일이 순수 GPL 전문이 아니라 전제가 붙은 형태라서다.

레포 구조에서 확인되는 실체: `Sources/`, `Packages/`, `Native/`, `cmux.xcodeproj`, `cmux-browser/`, `cmux-tui/`, `daemon/`, `web/`, `services/`, `workers/`, `ios/`, `vault/`, `ghostty`(서브모듈), `THIRD_PARTY_LICENSES.md`. **앱·데몬·브라우저·백엔드·iOS가 한 저장소에 있다.**

### 1.3 가격 — 유료의 실체가 컴퓨트다

| 플랜 | 가격 | 내용 |
|---|---|---|
| Free | $0 | 네이티브 터미널 전부. 로컬 CLI 에이전트(사용자 자기 키) |
| **Pro** | **$30/월** | 클라우드 VM 실행 — **4 vCPU / 16 GB에서 월 20 활성 compute-hour**, 모델 게이트웨이(라우팅·비용 분석), iOS 앱 |
| Team | $35/user/월 | Pro + 통합 청구 + 풀링된 VM 시간 |
| Enterprise | 문의 | 자체 호스팅·에어갭, SSO/SAML, 감사 로그 |

**GPL로 풀 수 있는 이유가 여기 있다.** 파는 것이 앱이 아니라 **컴퓨트와 게이트웨이**다. Orca가 MIT로 풀고 Enterprise 문의만 둔 것과 수익 구조가 다르고, 그 차이가 라이선스 선택(MIT vs GPL+유보)과 정합한다. 로컬 CLI 서브커맨드에도 그 흔적이 있다 — `vm <base|new|ls|status|snapshot|fork|restore|rm|exec|shell|ssh>`(별칭 `cloud`), `ai-accounts`, `auth`, `remotes`.

---

## 2. 스킬 배포 — Orca와 정반대

### 2.1 규모

이 머신에 설치된 것을 전수 실측했다(`~/.claude/skills/cmux-*`).

| 항목 | 값 |
|---|---|
| 스킬 수 | **20종** |
| `SKILL.md` 합계 | **1,949줄** |
| 최대 | `cmux-customization` 234줄 · `cmux-workspace` 225줄 · `cmux-keyboard-shortcuts` 220줄 |
| 최소 | `cmux-socket-policy` 27줄 · `cmux-localization` 37줄 |
| `references/` | **34파일 2,704줄** (20종 중 15종이 보유) |
| `agents/openai.yaml` | **18/20** |
| `templates/` | `cmux-browser`만 3파일 |

**[skill-architecture](skill-architecture.md) 관측과 정면으로 어긋나는 곳이 둘이다.**

1. **관측 #5(SkillsBench: 과제당 2–3개 최적, 4개 이상 +5.9pp로 급락)** — cmux는 20종을 한 번에 설치한다. 다만 SkillsBench가 잰 것은 *한 과제에 붙는* 스킬 수이고 cmux의 20종은 라우팅으로 갈리므로, **직접 반증은 아니다.** 라우팅 표면 예산([instruction-layers](instruction-layers.md))에는 그대로 얹힌다.
2. **관측 #17(공식 권고 본문 500줄)** — 모든 `SKILL.md`가 234줄 이하로 **상한을 지킨다.** 대신 넘치는 분량을 `references/`로 뺐다. **Orca가 파일 밖(바이너리)으로 밀었다면 cmux는 파일 옆(디렉터리)으로 밀었다.**

`references/`의 실제 배치가 그 구조를 보여준다.

```
cmux-browser/references/   authentication.md  proxy-support.md  commands.md
                           video-recording.md  snapshot-refs.md  session-management.md
cmux-testing/references/   swift-testing-migration.md  remote-tmux-sizing-e2e.md
                           regression-and-quality.md   local-vs-ci-validation.md
cmux/references/           windows-workspaces.md  handles-and-identify.md
                           panes-surfaces.md      trigger-flash-and-health.md
```

### 2.2 절반 이상이 "이 제품을 개발하는 법"이다

20종을 용도로 가르면 갈린다.

| 부류 | 스킬 |
|---|---|
| **최종 사용자용** (9) | `cmux`, `cmux-browser`, `cmux-workspace`, `cmux-customization`, `cmux-settings`, `cmux-keyboard-shortcuts`, `cmux-markdown`, `cmux-diagnostics`, `cmux-custom-sidebar` |
| **기여자용** (11) | `cmux-architecture`, `cmux-backend`, `cmux-billing`, `cmux-dev-workflow`, `cmux-ghostty`, `cmux-localization`, `cmux-release`, `cmux-testing`, `cmux-shared-behavior`, `cmux-socket-policy`, `cmux-debugging` |

기여자용의 내용이 실제로 하네스 규칙이다. `cmux-architecture`(159줄, 24 KB — 줄당 152자, 산문이 길다)의 서두:

> "We are migrating cmux from a single app target into Swift Packages under `Packages/`. Every new package must satisfy three rules: **Ergonomic.** … Default to internal access; expose `public` only for types and functions that downstream consumers actually use."

`cmux-socket-policy`는 27줄로 *"소켓 커맨드가 앱 포커스를 훔치지 않게"* 라는 단일 규칙만 담는다. **[shared-behavior 스킬]의 발동 조건이 특히 눈에 띈다** — *"tests that previously missed a bug"*, 즉 **재발 방지 규칙을 스킬로 굳혔다**([error-recurrence-prevention](error-recurrence-prevention.md) 축).

**grid fin 관점에서 이것이 §2.1의 규모보다 중요할 수 있다.** "제품이 자기 기여자 하네스를 스킬로 출하하고, 그것이 사용자 스킬과 같은 디렉터리에 깔린다"는 배치는 [repository-layout](repository-layout.md)·[harness-distribution](harness-distribution.md)이 다룬 "하네스를 무엇과 함께 배포하는가"의 한 답이다.

### 2.3 버전 핀이 없다 — 그리고 그것이 덜 아픈 이유

Orca는 `orca skills get`으로 **바이너리가 텍스트를 서빙**했다. cmux는 다르다.

```
$ cmux docs settings
Web:
  https://cmux.com/docs/configuration#cmux-json
Raw resources:
  settings schema: https://raw.githubusercontent.com/manaflow-ai/cmux/main/web/data/cmux.schema.json
  cmux skill:      https://raw.githubusercontent.com/manaflow-ai/cmux/main/skills/cmux/SKILL.md
Fetch:
  curl -fsSL https://raw.githubusercontent.com/manaflow-ai/cmux/main/web/data/cmux.schema.json
```

**텍스트가 아니라 URL과 `curl` 명령을 낸다. 그리고 그 URL이 `main`이다.** 설치는 `skills.sh`가 맡는데, 기본 목적지가 `${CODEX_HOME:-$HOME/.codex}/skills`이고 파이프 설치를 공식 예시로 제시한다.

```bash
curl -fsSL https://raw.githubusercontent.com/manaflow-ai/cmux/main/skills.sh | bash
./skills.sh --skill cmux --skill cmux-browser      # 선택 설치
CMUX_SKILLS_REF=<ref> ./skills.sh                  # ref 지정은 가능
```

**따라서 세 번째 패턴이다.**

| 패턴 | 내용이 있는 곳 | 신선도 보장 | 앱 버전과의 정합 |
|---|---|---|---|
| 정적 파일 (일반) | 스킬 파일 | 설치 시점 | **없음** |
| **Orca** | **바이너리** | 항상 | **구조적으로 보장** |
| **cmux** | 레포(`main`) + 로컬 사본 | `curl` 시점 | **없음**(핀 가능하나 기본이 `main`) |

**그런데 cmux 쪽에서 이 선택이 덜 아픈 이유가 실측된다.** 릴리스 API 기준 v0.64.19(07-14) → v0.64.20(07-19) → v0.64.21(08-03)로 **약 2주 주기**다. Orca는 6일에 6버전이었다. **같은 문제에 대한 두 답이 서로 다른 릴리스 속도 위에 서 있고, 그 속도가 답을 정당화한다** — [Orca 조사 §9](orca-ade.md)에 적은 *"전제가 다르면 결론이 따라오지 않는다"* 의 반대편 실물이다.

`agents/openai.yaml`(18/20 보유)도 배포 축의 관측이다.

```yaml
interface:
  display_name: "cmux Core"
  short_description: "Control windows/workspaces/panes/surfaces and routing with cmux CLI."
  default_prompt: "Use this skill to inspect and manipulate cmux topology: ..."
```

**벤더 중립 `SKILL.md` 옆에 벤더별 인터페이스 서술자를 따로 둔다.** 한 벌의 스킬을 Claude·Codex 양쪽에 내는 방식의 실물이다.

---

## 3. 제어 표면 — 소켓이 1급이다

### 3.1 협상 가능한 능력 목록

`cmux capabilities`(로컬 0.64.21)가 내는 것:

| 필드 | 값 |
|---|---|
| `protocol` | `cmux-socket` |
| `version` | **2** |
| `access_mode` | `cmuxOnly` |
| `socket_path` | `~/.local/state/cmux/cmux-501.sock` (uid 포함) |
| `capabilities` | **35종** — `terminal` 9 · `workspace` 14 · `notification` 4 · `browser` 3 · `chat` 3 · `events` 1 · `dogfood` 1 |
| `methods` | **303종** — `browser` 92 · `workspace` 50 · `simulator` 30 · `surface` 28 · `mobile` 25 · `notification` 10 · `pane` 9 · `remote` 8 · `window` 7 · `vm` 6 … |

**능력 이름에 버전 접미사가 붙는다** — `terminal.render_grid.v1`, `terminal.render_grid.**verified_replay**.v1`, `terminal.render_grid.screen_anchor.v1`, `terminal.input.**ordered**.v1`. 즉 **클라이언트가 "이 앱이 무엇을 할 수 있는지" 실행 시점에 물어보게 설계돼 있다.** Orca의 `agent-context --json`(커맨드 스키마 덤프)과 목적이 다르다 — 저쪽은 *어떻게 부르는가*를, 이쪽은 *무엇이 되는가*를 낸다.

### 3.2 CLI의 형태

핸들 모델이 문서화돼 있다 — 윈도우/워크스페이스/페인/서피스를 **UUID, 짧은 ref(`workspace:2`), 인덱스** 셋 중 하나로 지목한다. `--id-format uuids|both`로 출력 형식을 바꾼다.

에이전트에게 유용한 축만 뽑으면: `read-screen [--scrollback]`, `send` / `send-key`, `new-workspace --command`, `new-split`, `tree`, `top --processes`, `surface-health`, `wait-for`, `identify`, `notify`, `set-status` / `set-progress` / `log`, `events --after <seq> --cursor-file --reconnect`, `browser <92 methods>`.

**`--help` 안에 에이전트용 지시가 직접 박혀 있는 점**도 관측 대상이다.

> "Before editing, back up any existing cmux.json file to a timestamped .bak copy."
> "prefer Ghostty config for terminal behavior Ghostty already supports."

**도움말이 사람용 레퍼런스이자 에이전트용 규칙 전달 경로를 겸한다.**

---

## 4. Feed — 사람 승인 게이트의 실물

[enforcement-mechanisms](enforcement-mechanisms.md)가 참고 하네스에서 `deny`·`ask`·`sandbox` **0건**을 실측했다. cmux의 Feed는 거기에 실제로 도는 물건이다.

### 4.1 무엇을 가로채는가

Feed가 사람 응답을 요구하는 것은 셋이다.

| 종류 | 선택지 |
|---|---|
| **Permission request** (도구 실행·파일 편집·셸 명령) | Once / Always / All tools / **Bypass** / Deny |
| **ExitPlanMode** (계획 끝, 편집 시작 직전) | Ultraplan / Manual / Auto |
| **AskUserQuestion** | 객관식 선택 후 Submit |

나머지(도구 사용, 어시스턴트 메시지, 세션 시작·종료, `TodoWrite`)는 **정보성 활동**으로 타임라인에만 쌓인다.

경로는 문서에 다이어그램으로 있다: 에이전트 훅 → `cmux hooks feed --source <agent>` → 소켓 `feed.push`(V2 프레임) → `FeedCoordinator`가 `@MainActor WorkstreamStore`에 기록하고 사이드바 표시(+창이 비활성이면 네이티브 알림) → **`request_id`로 키를 잡은 세마포어에 훅을 재운다** → 사람이 누르면 `feed.permission.reply` 등이 훅을 깨우고, **훅이 에이전트가 기대하는 결정 JSON을 stdout으로 뱉는다.**

### 4.2 fail-open이 설계다 — 이 시리즈에서 처음

문서에 절이 따로 있다(*Timeout behavior*).

> "Feed is advisory, not blocking. The hook waits at most 120 seconds for a user decision. On timeout the bridge emits `{}` (no decision) and the agent falls through to its own in-TUI prompt. This matches Vibe Island's 'soft wait' model, it never freezes a workflow forever."

**이 시리즈는 fail-open 사례를 여섯 건 세었고 전부 사고였다** — 검사 부재가 통과로 보이는 것, 파싱 실패가 조용한 누락이 되는 것, 훅 스크립트 부재가 로그 없이 통과하는 것 등([per-language-check-divergence](per-language-check-divergence.md), [hook-skill-frontmatter-probe](hook-skill-frontmatter-probe.md)). **이것이 첫 의도된 fail-open이고, 근거·상한·대체 경로가 함께 적혀 있다** — 120초, `{}`, 그리고 *에이전트 자신의 프롬프트로 떨어진다*는 폴백. 사고와 설계를 가르는 것은 fail-open 여부가 아니라 **폴백이 명시돼 있는가**다.

대가도 숫자로 적혀 있다.

> "Per-event timeout inside agent hook configs is raised to roughly 120 to 125 seconds for blocking Feed bridge entries (Claude uses 125 seconds for PermissionRequest), so a user taking 30 seconds to approve something does not trip default 5 000 ms hook timeouts."

**기본 5,000 ms의 약 24배.** 그리고 Codex는 자기 승인 UI를 갖고 있으므로 **Feed 훅을 비블로킹·짧은 타임아웃으로 둔다**고 명시한다 — 벤더마다 게이트를 다르게 건다.

### 4.3 통합을 위해 기본 권한을 약화시킨다

> "For Claude Code, the cmux wrapper launches Claude with `--allow-dangerously-skip-permissions`. This does not enable bypass by default, but it lets a later `PermissionRequest` response switch the current session into `bypassPermissions`. Without that launch flag, Claude ignores `setMode: bypassPermissions`."

**Feed의 Bypass 버튼을 살리기 위해 플래그를 미리 켠 상태로 띄운다.** 문서가 "기본으로 bypass가 되는 것은 아니다"라고 부연하지만, **런타임 상태가 UI 한 번의 클릭으로 bypass로 전환 가능해진다.** [security](security.md)·[enforcement-mechanisms](enforcement-mechanisms.md) 축에서 기록해 둘 형태다 — *편의 기능을 위해 권한 기본값을 내리는 통합*.

---

## 5. 관찰성 — 34일치 실물 로그 집계

**이 절의 모든 수치는 이 머신 한 대, 사용자 한 명, 2026-06-30T22:24Z ~ 2026-08-03T05:26Z(34일)의 기록이다.** cmux의 성질이 아니라 이 환경의 실측이며, 로그에는 grid fin 조사 작업 자체가 포함돼 있다. 집계만 했고 프롬프트·도구 인자·결과 본문은 읽지 않았다.

### 5.1 기록은 두껍고, 도구 이름이 살아 있다

`~/.cmuxterm/workstream.jsonl` — **174 MB, 104,693줄, 회전 없음.**

**집계 중에도 파일이 계속 추가되고 있었다** — `toolUse` 집계가 세 번의 패스에서 81,643 → 81,644 → 81,645로 늘었다. 아래 수치는 **읽은 시점 기준**이고 한두 건의 오차가 있다.

| kind | 건수 |
|---|---|
| `toolUse` | **81,645** |
| `toolResult` | 10,604 |
| `stop` | 6,411 |
| `userPrompt` | 3,444 |
| `question` | 1,131 |
| `sessionStart` / `sessionEnd` | 588 / 544 |
| **`permissionRequest`** | **328** |

레코드 필드: `id`, `kind`, `title`, `cwd`, `source`, `ppid`, `workstreamId`, `status`, `context`, `payload`, `createdAt`, `updatedAt`.

**`toolUse` 81,645건 전부 도구 이름이 있다**(`title`의 첫 토큰). 상위: `Bash` 41,763 · `Read` 17,134 · `Edit` 10,810 · `Write` 2,191 · `Agent` 2,019 · `TaskUpdate` 1,878 · `TaskCreate` 1,718 · `AskUserQuestion` 1,162 · `Skill` 417 · `Grep` 412 · MCP 도구들(`mcp__claude-in-chrome__computer` 343 …). `source`는 `claude` 77,758 / `codex` 3,886.

**[observability](observability.md)가 진단한 *"로그 13,342건이 전부 `"tool":"unknown"`"* 의 정반대다.** 그리고 각 `toolUse`의 `context`에 `lastUserMessage`·`allowedPrompts`·`assistantPreamble`·`toolSummary`·**`permissionMode`** 가 붙는다 — 즉 **"어떤 권한 상태에서 이 도구가 돌았는가"가 이벤트마다 기록된다.**

### 5.2 게이트율은 모드가 정한다 — 집계치 하나로 말하면 안 된다

`toolUse` 81,645건의 `permissionMode` 분포:

| 모드 | 건수 | 비중 |
|---|---|---|
| `auto` | 67,092 | 82.2% |
| (없음) | 10,826 | 13.3% |
| `default` | 3,616 | 4.4% |
| `plan` | 60 | 0.07% |
| `acceptEdits` | 31 | 0.04% |
| `bypassPermissions` | 22 | 0.03% |

그리고 `permissionRequest` 328건의 모드: **`default` 319 · `acceptEdits` 6 · `auto` 3.**

**따라서 "328/81,645 = 0.40%"는 게이트율이 아니다.** 분모의 82%가 애초에 묻지 않는 모드다. 의미 있는 수는 이쪽이다.

| 모드 | 도구 사용 | 승인 요청 | 요청률 |
|---|---|---|---|
| `default` | 3,616 | 319 | **약 8.8% (상한)** |
| `auto` | 67,092 | 3 | 약 0.004% |

**"상한"이라고 적은 이유가 있다 — 모드가 기록되지 않은 10,826건(13.3%)의 정체를 확인했고, 초기 스키마 탓이 아니었다.** 월별로 보면 2026-07이 10,392/77,978(13.3%), 2026-08이 434/3,623(12.0%)로 **비율이 그대로 유지된다**(2026-06은 표본 72건). 그리고 그 10,826건의 `source`는 **codex 3,886(전량) + claude 6,940** 이다. 즉 Codex 경로는 이 필드를 아예 안 주고, **Claude 쪽에서도 6,940건이 모드 없이 기록된다.** 그중 얼마가 실제로 `default`였는지 알 수 없으므로 **분모 3,616은 하한이고 8.8%는 상한**이다.

이 결손 자체가 [observability](observability.md) §2.3(*"`codex exec`는 메트릭을 방출하지 않는데 하네스의 리뷰어 절반이 그 경로다"*)와 같은 계열이다 — **진입점별 계측 결손이 여기서도 Codex 쪽에서 나타난다.**

**사람이 실제로 무엇에 대해 불려 나왔는가**도 갈린다 — `Bash` 233 / `Edit` 58 / `Write` 21 / `Read` 9, 나머지는 한 자릿수. **셸 명령이 승인 요청의 71%** 다.

이 수치를 [enforcement-mechanisms](enforcement-mechanisms.md)의 *"deny·ask·sandbox 0건"* 옆에 놓으면 **"게이트가 없다"와 "게이트가 있는데 모드가 꺼 놓았다"가 다른 상태**임이 보인다. 다만 **어느 모드로 도는지는 하네스가 아니라 사용자·세션이 정한다** — 이 표는 그 선택의 결과이지 cmux의 정책이 아니다.

### 5.3 그런데 결말이 없다 — 같은 병의 다른 형태

**`permissionRequest` 328건이 전부 `status: {"pending": {}}` 이다.** 바깥 키가 하나(`pending`)이고 **그 연관값이 빈 객체**다 — Swift `Codable`의 연관값 열거형 인코딩이고, **결정이 들어갈 칸이 통째로 비어 있다.** 처음 집계에서 값이 안 보여 열거형 내부를 다시 열어 확인한 결과다.

그리고

- 328건 모두 **`createdAt == updatedAt`**
- **고유 id 328개, 중복 0** → 같은 요청이 다시 기록되지 않는다
- `payload.permissionRequest`의 키는 **`requestId` · `toolName` · `toolInputJSON` 셋뿐** — 요청 내용만 있고 결과가 없다

즉 **`workstream.jsonl`은 추가 전용이고 요청의 결말을 갱신하지 않는다.** 이 파일만 보면 *사람이 무엇을 허용하고 무엇을 거부했는지 알 수 없다.*

**조인 키는 있다** — `requestId`가 §4.1의 세마포어 키(`request_id`)와 같은 것으로 보이고, feed 이벤트 payload에도 `_opencode_request_id`가 있다. **끊긴 것은 키가 아니라 보존이다.**

결말을 찾아 이벤트 스트림으로 갔다. `cmux events`가 읽는 `~/.cmuxterm/events.jsonl`(+ `.1`)에는 `feed.item.received` / `feed.item.completed` 쌍이 실제로 있다. **그러나 두 문제가 겹친다.**

**(1) 보존 창이 18시간이다.**

| 파일 | 건수 | 범위 |
|---|---|---|
| `events.jsonl` | 2,535 | 2026-08-03T02:50Z → 05:27Z |
| `events.jsonl.1` | 21,240 | 2026-08-02T11:29Z → 08-03T02:50Z |

**요청은 34일 남고 결말은 18시간 남는다.** 두 파일의 회전 정책이 다르므로, 하루 전 승인 결정은 이미 조인 불가다.

**(2) 그 이벤트에도 결정 필드가 없다.** 보존된 두 파일의 `category: feed` 이벤트 payload 키 **전수**는 다음과 같다.

```
hook_event_name  phase  tool_name  tool_input  tool_input_length
context  context_length  result  is_error  redacted_fields
session_id  cwd  workspace_id  surface_id  _source  _ppid  _received_at  _opencode_request_id
```

`decision`·`allow`·`deny`·`approved` 계열이 **없다**(`result`는 도구 실행 결과이고 `is_error`도 마찬가지다). 그리고 보존 창 안에서 `hook_event_name`이 `PermissionRequest`인 feed 이벤트는 **0건**이다 — 이 18시간 동안 승인 요청 자체가 없었다는 뜻이므로 결정 필드의 부재를 이 표본만으로 단정할 수는 없다. **확실한 것은 "보존된 기록에서 결정을 복원할 수 없다"이지 "cmux가 결정을 어디에도 안 남긴다"가 아니다**(§9).

**정리하면 [observability](observability.md)의 진단이 형태를 바꿔 재현된다.** 그 문서의 문장은 *"기록은 있고 소비가 없다"* 였다. cmux는 **이름 문제는 완전히 풀었고**(관측 #1) **보존·조인 문제는 남겼다**(관측 #2–#4).

| 층 | 참고 하네스(선행 조사) | cmux(이 실측) |
|---|---|---|
| 이벤트 발생 | 있음 | 있음 |
| **도구 식별** | **전부 `unknown`** | **전부 이름 있음** |
| 권한 맥락 | 없음 | **이벤트마다 `permissionMode`** |
| **사람 결정의 결말** | — | **기록되지 않음(요청은 `pending`으로 고정)** |
| 보존 | — | **감사 34일 / 이벤트 18시간(비대칭)** |

그리고 `redacted_fields` 키의 존재가 별도 관측이다 — **이벤트 스트림이 필드 단위 편집(redaction)을 상정하고 만들어졌다.** [security](security.md)·[observability](observability.md) 축의 *emit vs redact*([Orca 조사 §7](orca-ade.md))가 여기서는 **필드 단위**로 나타난다.

### 5.4 스트림의 재개 가능성

`cmux events`는 `--after <seq>`, `--cursor-file <path>`, `--reconnect`, `--no-ack`, `--no-heartbeat`를 받는다. 이벤트 레코드에 `seq`와 **`boot_id`** 가 있고 id가 `<boot_id>-<seq>` 형태다 — **재시작 경계를 명시적으로 표현한다.** 소비자가 커서를 들고 끊긴 지점부터 다시 붙는 형태이고, [observability](observability.md)가 다룬 OTel 계열과는 다른(로컬 파일 + 시퀀스) 접근이다.

---

## 6. 에이전트 훅 통합 — 벤더별 실물 경로 17종

**출처가 두 파일이다** — `docs/agent-hooks.md`의 표 **16행**(Claude Code, Codex, Grok, OpenCode, Pi, OMP, Campfire, Amp, Cursor CLI, Gemini, Kiro CLI, Rovo Dev, Copilot, CodeBuddy, Factory, Qoder)에 `docs/feed.md`의 표에만 있는 **Kimi Code**를 더해 17종이다. **이 시리즈에서 본 훅 층 대응표 중 가장 구체적이다** — 각 행이 *바이너리 / 설치 파일 / 세션 복원 명령 / Feed 브리지 훅 이벤트* 넷을 짚는다.

| 에이전트 | 설치 파일 | 세션 복원 | Feed 브리지 훅 |
|---|---|---|---|
| Claude Code | 래퍼 주입 설정 | `claude --resume <id>` | **PermissionRequest** |
| Codex | `~/.codex/hooks.json`, `~/.codex/config.toml` | `codex resume <id>` | PreToolUse / PermissionRequest 텔레메트리 |
| Grok | `~/.grok/hooks/cmux-session.json` | `grok -r <id>` | PreToolUse |
| OpenCode | `~/.config/opencode/plugins/cmux-{session,feed}.js` | `opencode --session <id>` | **플러그인 이벤트 버스** |
| Pi | `~/.pi/agent/extensions/cmux-session.ts` | `pi --session <id>` | tool_execution_start/end 텔레메트리 |
| OMP / Campfire | `~/.omp/…`, `~/.campfire/…` (환경변수 경로 대안 있음) | `--session <id>` | 라이프사이클만 |
| Amp | `~/.config/amp/plugins/cmux-session.ts` | `amp threads continue <id>` | 없음 |
| **Cursor CLI** | `~/.cursor/hooks.json` | `cursor-agent --resume <id>` | **beforeShellExecution** |
| Gemini | `~/.gemini/settings.json` | `gemini --resume <id>` | PreToolUse |
| Kiro CLI | `~/.kiro/agents/cmux.json` | `kiro-cli chat --resume-id <id>` | preToolUse, postToolUse |
| Rovo Dev | `~/.rovodev/config.yml` | `acli rovodev run --restore <id>` | 없음 |
| Copilot / CodeBuddy / Factory / Qoder | `~/.copilot/config.json` 등 | `--resume <id>` | PreToolUse |
| Kimi Code | `~/.kimi/config.toml` | — | PreToolUse / PostToolUse |

**세 가지가 눈에 띈다.**

1. **훅 이름이 벤더마다 다르고 의미도 다르다** — Claude는 `PermissionRequest`(승인 전용), 대부분은 `PreToolUse`(도구 전), Cursor는 **`beforeShellExecution`(셸 전용)**. 즉 **같은 "가로채기"가 벤더마다 다른 지점에 걸린다.** [hook-skill-frontmatter-probe](hook-skill-frontmatter-probe.md)가 Claude 한 벤더에서 잰 `PreToolUse`/`PostToolUse` 타이밍 문제가, 다중 벤더로 가면 **지점 자체가 어긋나는 문제**로 바뀐다.
2. **설치 형태가 셋으로 갈린다** — 설정 파일 주입(`hooks.json`/`settings.json`/`config.toml`), 플러그인/확장 스크립트 배치(`.js`/`.ts`), **래퍼로 감싸기**(Claude). 마지막이 §4.3의 플래그 주입을 가능하게 하는 형태다.
3. **`cmux hooks setup`은 PATH에 바이너리가 없는 에이전트를 건너뛰고 요약을 출력한다** — 조용히 넘어가지 않고 **무엇을 안 했는지 말한다.** 이 시리즈가 여섯 번 세었던 fail-open의 반대 처리다.

---

## 7. tmux 호환 — 새 어휘를 강요하지 않는다

`--help`에 `# tmux compatibility commands` 구획이 따로 있다.

```
capture-pane   resize-pane   pipe-pane   wait-for   swap-pane   break-pane
join-pane      next-window   previous-window   last-window   last-pane
find-window    clear-history   set-hook   popup   bind-key   unbind-key
copy-mode      set-buffer   list-buffers   paste-buffer   respawn-pane
display-message
```

**이것이 설계 주장이다.** cmux는 워크스페이스·서피스·페인이라는 자체 모델을 갖고 있으면서도(§3.2), **tmux를 쓰던 스크립트와 손버릇이 그대로 도는 표면을 병렬로 낸다.** `capture-pane`은 `read-screen`의 별칭에 가깝고, `set-hook`·`bind-key`도 있다.

**grid fin 축에서 이것을 옮길 만한 형태로 읽으면 — 새 도구가 기존 어휘를 흡수하는 비용을 지불하면 도입 장벽이 내려간다**는 사례다. [structural-navigation](structural-navigation.md)이 *"grid fin에 없는 것은 도구가 아니라 도입 장치일 가능성이 높다"*(도입률 42%, 구조 과제 0/30)로 끝났던 사례와 같은 문제를 다른 방식으로 친다.

---

## 8. grid fin 축으로의 재배열

**결정이 아니다.** 위 관측을 기존 조사 축에 붙여 두는 것뿐이다.

| grid fin 축 | cmux가 보태는 것 | 성격 |
|---|---|---|
| [observability](observability.md) | **34일 104,693건 실물 집계.** 도구명 100% 보존(선행 진단의 정반대) + **결말 미기록·보존 비대칭(34일 vs 18시간)** + `redacted_fields`(필드 단위 편집) + `boot_id`/`seq` 커서 재개 | **이 시리즈 최대의 1차 실측** |
| [enforcement-mechanisms](enforcement-mechanisms.md) | **도는 사람 승인 게이트의 실물.** `default` 모드 요청률 **8.8%**(319/3,616), 승인 대상의 71%가 Bash. 그리고 **통합을 위해 권한 기본값을 낮추는 형태**(§4.3) | **새 데이터포인트** |
| 같은 축의 fail-open 계보 | **첫 "설계된" fail-open** — 120초 상한, `{}` 반환, 에이전트 자체 프롬프트로 폴백, 근거 명시. **사고와 설계를 가르는 것은 폴백 명시 여부다** | **계보의 성격 구분** |
| [skill-architecture](skill-architecture.md) | **Orca의 정반대 극.** 전문 20종 1,949줄 + `references/` 2,704줄 + `agents/openai.yaml`(벤더별 서술자). 500줄 상한은 **파일 옆(디렉터리)으로** 밀어 지킨다 | **대극 데이터포인트** |
| [harness-distribution](harness-distribution.md) | **세 번째 배포 패턴** — 레포 `main`에 위임(핀 없음), `curl \| bash`, 기본 목적지가 `~/.codex/skills`. 그리고 **릴리스 주기 2주가 그 선택을 떠받친다** | **새 데이터포인트** |
| [hook-skill-frontmatter-probe](hook-skill-frontmatter-probe.md) | **벤더 17종의 훅 파일 경로·이벤트 대응표.** 가로채기 지점이 벤더마다 다르다는 것(PermissionRequest / PreToolUse / beforeShellExecution) | **새 데이터포인트** |
| [repository-layout](repository-layout.md) | **제품이 자기 기여자 하네스를 스킬 11종으로 출하한다** — 사용자 스킬과 같은 디렉터리에 | **새 데이터포인트** |
| [structural-navigation](structural-navigation.md) | tmux 호환 표면 = **도입 장벽을 도구가 흡수하는** 형태 | 관련 |
| [worktree-shared-state](worktree-shared-state.md) | **보태지 않는다 — 확인한 부재다.** cmux는 워크트리를 1급 개념으로 두지 않는다(CLI `worktree` 0회). 관측 #1의 9번째 사례가 아니다. **Orca와 갈리는 지점이므로 부재 자체를 기록한다** | **부재 확인** |

**가장 옮길 만한 하나를 꼽으면 §5.3이다.** grid fin이 관찰성을 만들 때 잡을 실패는 "이름이 없다"가 아니라 **"요청과 결말의 보존 정책이 달라 조인이 끊긴다"** 쪽일 수 있다. cmux는 앞의 문제를 완전히 풀고도 뒤의 문제를 남겼고, **그 사실이 로그 파일 두 개의 시간 범위를 비교하는 것만으로 드러났다.**

---

## 9. 확인하지 않은 것 / 열린 질문

| 항목 | 왜 미확인 |
|---|---|
| **승인 결정이 정말 어디에도 안 남는가** | `workstream.jsonl`·`events.jsonl`(+`.1`)만 확인했다. **앱 내부 저장소는 확인 못 했다** — `com.cmuxterm.app` 지원 디렉터리에서 SQLite/DB 파일을 못 찾았지만, 메모리 링(최근 2000건)·별도 저장 경로 가능성이 남는다. **§5.3의 결론은 "보존된 파일에서 복원 불가"까지다** |
| 보존 창 18시간의 정책 | 관측치다. 회전 기준(크기? 개수? 시간?)을 문서로 확인하지 않았다. `events.jsonl.1`이 16 MB인 것으로 보아 크기 기반으로 보이지만 **추정이다** |
| 텔레메트리 정책 | `phc_` 파일로 PostHog **정황**만 잡았다. 수집 항목·옵트아웃 경로를 문서로 확인 못 했다 — Orca(§7)와 달리 전용 문서 페이지를 찾지 않았다 |
| GPL 유보 조항의 실효 범위 | LICENSE 서문 원문은 확인했으나, CLA 유무·`THIRD_PARTY_LICENSES.md` 내용을 보지 않았다 |
| 클라우드 VM 계층 | `cmux vm` 서브커맨드와 가격표만 봤다. 격리 모델·보안 경계 미확인 |
| 세션 복원의 실제 동작 | 표만 봤다. `--resume <id>` 경로가 실제로 이어지는지 실측하지 않았다 |
| `~/.claude/skills/cmux-*` 20종의 본문 | 크기·구조·frontmatter·일부 서두만 봤다. 전문 정독은 하지 않았다 |
| 이 로그가 얼마나 대표적인가 | **n=1 머신·1 사용자·34일.** `auto` 모드 82%가 이 사용자의 설정이지 cmux 기본값인지 확인 안 했다 |
