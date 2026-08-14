# 컨텍스트 파일에 무엇을 쓰는가 — CLAUDE.md·AGENTS.md 내용 조사

**최초 작성**: 2026-08-03
**최종 수정**: 2026-08-03
**대상 프로젝트**: grid fin (신규 개인용 개발 하네스)
**조사 도구**: Claude Code 2.1.220 바이너리 문자열 추출, WebFetch 6회, WebSearch 3회, 로컬 저장소 직접 측정
**성격**: 조사. 내용 규격의 확정은 하지 않는다.

선행 문서
- [instruction-layers.md](instruction-layers.md) §6.1·§7-11 — **길이 축 vs 종류 축**을 열어둔 절. 이 조사가 그 종류 축을 잇는다
- [repository-hygiene.md](repository-hygiene.md) §1.3.1 — ETH 연구의 개요/지시 구분
- [harness-distribution.md](harness-distribution.md) §9.2 — Codex `project_doc_max_bytes` 32 KiB

> **이 문서가 새로 여는 축.** 선행 조사들은 *얼마나 / 어디에*(길이·위치·압축 생존)를 다뤘고 종류 축은 ETH 초록 한 줄에 기대고 있었다. 이 조사는 **내용의 종류**를 정면으로 다루되, 사용자 요청에 따라 **최신 고성능 모델을 쓰는 경우**를 중심에 둔다. 그 축에서 가장 날카로운 결과는 아래 5번이다 — **같은 문장이 모델 세대에 따라 도움에서 해가 되는 쪽으로 부호가 바뀌고, 인접 두 판본 사이에서 교정 방향이 반대로 뒤집힌다.**

---

## 0. 조사 요약

| # | 관측 | 근거 | 근거 등급 |
|---|---|---|---|
| 1 | **Claude Code에 신규 `/init` 프롬프트가 들어와 있다** (`CLAUDE_CODE_NEW_INIT` / `tengu_slate_harbor_experiment` 게이트). **선행 조사가 "없다"고 적은 *포함* 기준이 여기 명시되어 있다** — *"only include what Claude would get wrong without it"*. **다만 이 계정에서 기본값이 아니다**(§1.1.1 실행 확인) | §1 바이너리 추출 + 실행 | 1차(도구) |
| 2 | **신규 `/init`의 Include/Exclude 목록이 구식 `/init`과 정면으로 어긋나고, 그 차이가 산출물에 실제로 나타난다.** 같은 빈 저장소에서 구식은 테스트 명령·주의점을 적은 파일을, 신규는 ***"`npm test`는 manifest에서 자명하므로 명시적 제외 대상"*** 이라며 거의 빈 파일을 냈다 | §1.2 대조 실행 | 1차(도구) |
| 3 | **메모리 시스템은 CLAUDE.md를 권위 문서로 전제한다** — *"What NOT to save in memory: Anything already documented in CLAUDE.md files."* 계층 간 역할 분담이 도구 안에 규정되어 있다 | §1.3 | 1차(도구) |
| 4 | **Opus 5 공식 프롬프팅 문서가 특정 지시를 "지우라"고 명시한다** — 검증 지시는 *"remove them"*, 그리고 ***"The same applies to legacy harness scaffolding that adds separate verification steps."*** 하네스 스캐폴딩이 이름 대어 지목됐다 | §2.1 | 1차(벤더) |
| 5 | **교정 방향이 인접 판본 사이에서 뒤집힌다.** Opus 4.8은 서브에이전트·메모리·도구를 *덜* 쓰므로 "언제 쓰라"를 넣으라 하고, Opus 5는 *더* 쓰므로 **"4.8용으로 넣은 그 지시를 빼라"** 고 한다 | §2.2 | 1차(벤더) |
| 6 | **벤더는 1M 창 전 구간에서 지시 준수가 유지된다고 주장한다** — *"instruction following, tool calling, and reasoning stay consistent throughout the window"*. **§3.1·§3.2의 위치 효과·절벽과 정면으로 충돌하며, 이 조사는 판정하지 못한다** | §2.4 | **벤더 주장(미검증)** |
| 7 | **ETH 연구가 실제로 시험한 모델은 Sonnet-4.5·GPT-5.2·GPT-5.1-mini·Qwen3-30b-coder다.** 사용자가 묻는 세대(Opus 5·Sonnet 5)를 **하나도 포함하지 않는다** | §3.1 | 측정(초록·본문 일부) |
| 8 | **ETH의 모델별 분해는 "생성 측"이지 "소비 측"이 아니다** — *"stronger models don't generate better context files"*. **강한 모델이 컨텍스트 파일을 덜 필요로 하는가는 여전히 미측정이다** | §3.2 | 측정 |
| 9 | **AGENTS.md의 기제는 CLAUDE.md와 다르다** — 전역→프로젝트 루트→하위로 **연결(concatenate)** 되고, 디렉터리당 1개, `AGENTS.override.md` 우선, **32 KiB에서 조용히 끊긴다** | §4.1 | 1차(벤더 문서) |
| 10 | **Codex도 압축 후 AGENTS.md를 재주입한다**고 보고된다(`build_initial_context()`). 사실이면 §4.1의 Governance Decay는 AGENTS.md에도 해당하지 않는다 | §4.2 | **검색 요약 — 미확인** |
| 11 | **실측: 상시 로드 본문의 행동 하드 제약은 356줄 중 7줄(2%)이다.** 개요 26%, 튜토리얼·도구 walkthrough **55%** | §5.1 | 1차 관측 |
| 12 | **AGENTS.md는 harness-guide.md의 인라인 사본이며 이미 어긋났다** — 54줄 차이, 섹션 1개와 커맨드 2개 누락, 설정 권장값 불일치 | §5.2 | 1차 관측 |

### 근거 등급에 관하여

이 조사는 **1차(도구)와 1차(벤더)의 비중이 이 시리즈에서 가장 높다.** 대신 측정 근거는 오히려 얇다 — 사용자가 지정한 "최신 고성능 모델" 구간에는 독립 측정이 존재하지 않는다.

| 등급 | 무엇 | 신뢰 |
|---|---|---|
| **1차(도구)** | Claude Code 2.1.220 바이너리에서 추출한 `/init`·메모리 프롬프트 원문 | **사실** — 도구가 실행하는 문장 그 자체 |
| **1차(벤더)** | Anthropic 공식 Opus 5 프롬프팅 문서, OpenAI Codex AGENTS.md 문서 | 높음 — 다만 **자사 모델에 대한 자기 진술**이다 |
| 1차 관측 | 하네스 저장소 직접 측정 | 사실 |
| 측정 | Gloaguen et al. (arXiv 2602.11988) | 중간 — **v1 HTML까지 확인**, 판본 주의 |
| 규격 | agents.md 명세 | 사실이나 **근거 없는 권고** |
| **검색 요약** | Codex 압축 재주입 | **낮음 — §4.2 경고 참조** |

---

## 구현 참조 자료 — 외부 자료 정리

> **이 절의 쓰임.** 확인한 자료를 **구현 시 참조할 형태**로 모았다. 논증과 검증 상태는 괄호 안 절 번호에 있다.

### A. 도구 자신의 답 — 신규 `/init` (가장 신뢰도 높음)

**선행 조사가 *"제외 기준이지 포함 기준이 아니다"* 라고 적었던 빈 칸이 채워졌다** (§1). 판정 문장 두 개:

> *"CLAUDE.md is loaded into every Claude Code session, so it must be concise — **only include what Claude would get wrong without it**."*
> *"Every line must pass this test: **"Would removing this cause Claude to make mistakes?"** If no, cut it."*

**Include** (원문)

| 항목 |
|---|
| Build/test/lint commands Claude can't guess (non-standard scripts, flags, or sequences) |
| Code style rules that **DIFFER from language defaults** (e.g., "prefer type over interface") |
| Testing instructions and quirks (e.g., "run single test with: `pytest -k 'test_name'`") |
| Repo etiquette (branch naming, PR conventions, commit style) |
| Required env vars or setup steps |
| Non-obvious gotchas or architectural decisions |
| Important parts from existing AI coding tool configs (AGENTS.md, `.cursor/rules`, `.github/copilot-instructions.md`, …) |

**Exclude** (원문)

| 항목 | 지정된 처리 |
|---|---|
| File-by-file structure or component lists | *"Claude can discover these by reading the codebase"* |
| Standard language conventions Claude already knows | 삭제 |
| Generic advice ("write clean code", "handle errors") | 삭제 |
| Detailed API docs or long references | **`@path/to/import`** 로 이동 |
| Information that changes frequently | **`@path/to/import`** 로 참조 — *"so Claude always reads the current version"* |
| Long tutorials or walkthroughs | **별도 파일 + `@import`, 또는 스킬** |
| Commands obvious from manifest files | 삭제 |

그리고 **구체성 규정** — *"Be specific: "Use 2-space indentation in TypeScript" is better than "Format code properly.""*

**배치 규정 셋** (같은 프롬프트)

- 관심사가 여럿이면 **`.claude/rules/`** 로 쪼개고 `paths` frontmatter로 파일 경로에 스코프한다
- 모노레포·다중 모듈이면 **하위 디렉터리 CLAUDE.md** (작업 디렉터리 진입 시 자동 로드)
- 개인 설정은 **`CLAUDE.local.md`** (+ `.gitignore`), 내용은 *"the user's role and familiarity"*, sandbox URL, 워크플로우 선호 — 판정 기준은 *"only include what would make Claude's responses noticeably better for this user"*

### B. 계층 간 역할 분담 — 메모리 시스템 프롬프트

같은 바이너리의 메모리 서브시스템 (§1.3):

> *"## What NOT to save in memory — **Anything already documented in CLAUDE.md files.** / Ephemeral task details: in-progress work, temporary state, current conversation context."*

그리고 메모리의 `project` 타입 정의가 경계를 반대편에서 그린다:

> *"Information … that is **not otherwise derivable from the code or git history**."*

**즉 도구 안에 3계층 분업이 이미 규정되어 있다** — 코드/git에서 유도 가능 → 어디에도 안 씀 / 유도 불가한 프로젝트 규약 → **CLAUDE.md** / 유도 불가한 진행 맥락·사용자 피드백 → **메모리**.

### C. 최신 모델용 지시 — Anthropic 공식 (§2)

[Prompting Claude Opus 5](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-opus-5). **지워야 할 것과 넣어야 할 것이 둘 다 명시되어 있다.**

**지울 것**

> *"If your prompt contains explicit verification instructions ("include a final verification step for any non-trivial task," "use a subagent to verify"), **remove them**: instructions like these cause over-verification on Claude Opus 5, and removing them reduces wasted tokens with no loss in quality. **The same applies to legacy harness scaffolding that adds separate verification steps.**"*

> *"Avoid instructing re-checks it already performs ("double-check your answer," "re-verify before responding")"*

> (thinking 비활성 시) *"If your system prompt contains a rule instructing the model not to think or not to reason, **remove it**; that kind of instruction increases tag leakage."*

**넣을 것** — 네 축 모두 공식 문서가 예시 문장을 제공한다.

| 축 | 이유 | 형태 |
|---|---|---|
| **간결성** | 기본 응답이 길어졌고 **`effort`로는 안 줄어든다** | *"Keep responses focused, brief, and concise…"* + 긴 시스템 프롬프트 끝에 `<tone_preference>` 한 줄 재확인 |
| **산출물 길이** | 디스크에 쓰는 문서가 길어졌다 | *"Match the length of written documents to what the task needs… do not pad with filler sections"* |
| **범위 규율** | 요청하지 않은 단계를 추가한다 | *"Deliver what was asked, at the scope intended… stop short of actions clearly beyond what was asked"* |
| **위임 상한** | 서브에이전트를 과다 생성한다 | *"Delegate to a subagent only for large tasks that are genuinely independent… do not use subagents to verify"* |

**부수 규정 둘.** 내레이션 조절은 *"Positive examples … tend to be more effective than instructions about what not to do."* / 리뷰 프롬프트의 *"only report high-severity"* 는 **문자 그대로 지켜져 리콜을 떨어뜨린다**.

### D. 교정 방향이 뒤집힌다 — 판본 간 대조 (§2.2)

같은 벤더 문서군에서 **인접 두 판본의 처방이 반대**다.

| 대상 | Opus 4.8 | Claude Opus 5 |
|---|---|---|
| 서브에이전트 | **덜** 쓴다 → *"delegate to subagents rather than iterating serially"* 를 넣으라 | **더** 쓴다 → *"any 'delegate more' guidance you added for Opus 4.8 should come out"* + 상한을 걸라 |
| 자기 검증 | (해당 없음) | 검증 지시를 **삭제**하라 — *"a delete, not a rewrite"* |
| 내레이션 | 4.7보다 많이 한다 → 강제 스캐폴딩을 **제거**하라 | 더 많이 한다 → 침묵 기본값을 **넣으라** |
| 자기 교정 서술 | — | 과다 → 교정 범위 제한 지시를 **넣으라** |
| 도구 트리거 | 보수적 → 각 도구 `description`에 *"call this when…"* 을 넣으면 측정 가능한 향상 | (유지) |

그리고 Fable 5·Sonnet 5 문서가 같은 방향을 더 강하게 말한다 — *"Prompts and skills written for prior models are often **too prescriptive** … and **reduce** output quality. After migrating, A/B the workload with older step-by-step scaffolding removed."*

> **이것이 이 조사의 핵심 함의다. 컨텍스트 파일의 내용에는 모델 판본 단위의 반감기가 있고, 교정의 부호가 뒤집힌다.** "무엇을 쓰는가"는 상수가 아니라 대상 모델의 함수다.

### E. 무엇이 도움이 되는가 — ETH 측정 (§3)

[Gloaguen, Mündler, Müller, Raychev, Vechev, *Evaluating AGENTS.md* (arXiv 2602.11988)](https://arxiv.org/abs/2602.11988). **v1 HTML 확인.**

| 확인 항목 | 값 |
|---|---|
| 시험 대상 | Claude Code + **Sonnet-4.5** / Codex + **GPT-5.2**, **GPT-5.1-mini** / Qwen Code + **Qwen3-30b-coder** |
| LLM 생성 파일 | SWE-bench Lite 약 **−0.5%**, AGENTbench 약 **−2%** |
| 개발자 작성 파일 | AGENTbench 약 **+4%** |
| 비용 | 전 유형 **+20~23%** |
| 개요 출현율 | 개발자 작성 12개 중 **8개**, LLM 생성 **95~100%** |
| 저자 권고 | *"human-written context files should describe only **minimal requirements**"* |

**두 가지를 정확히 읽어야 한다.**

1. **모델별 분해는 있으나 "생성 측"이다** — *"stronger models don't generate better context files."* **강한 모델이 컨텍스트 파일을 덜 필요로 하는가**라는 소비 측 상호작용은 이 논문이 답하지 않는다(§3.2).
2. **시험 모델이 전부 사용자가 묻는 세대 이전이다.** Opus 5·Sonnet 5·GPT-5.4는 없다.

### F. AGENTS.md 쪽 기제 — OpenAI 공식 (§4)

[Custom instructions with AGENTS.md](https://learn.chatgpt.com/docs/agent-configuration/agents-md.md) · [Config reference](https://learn.chatgpt.com/docs/config-file/config-reference)

| 항목 | 규격 |
|---|---|
| 탐색 순서 | ① 전역 `~/.codex/AGENTS.override.md` → `~/.codex/AGENTS.md` ② 프로젝트: **git 루트에서 현재 디렉터리까지 하향 순회**, 각 층에서 `AGENTS.override.md` → `AGENTS.md` → `project_doc_fallback_filenames` |
| 병합 | *"Codex concatenates files from the root down, joining them with blank lines. **Files closer to your current directory override earlier guidance.**"* 디렉터리당 최대 1개 |
| 상한 | *"stops adding files once the combined size reaches … `project_doc_max_bytes` (**32 KiB by default**)"* — **초과분은 조용히 사라진다** |
| 초과 시 공식 답 | 상한을 올리거나 **중첩 디렉터리로 분할** |
| 대체 | `model_instructions_file` — 내장 지시 **자체를 교체** |
| 내용 권고 | working agreements, 코드리뷰 규칙(플래그할 행동 + safe path), 프로젝트 셋업·테스트 절차. *"Keep rules concise … **reserve formatting and lint checks for CI**"* |

**CLAUDE.md와의 기제 차이 넷** — ① `@import` 없음(인라인 또는 디렉터리 분할) ② 총합 바이트 상한이 **있음**(Claude Code는 개별 항목 상한만) ③ 근접 파일이 **override** (Claude Code는 병합) ④ 압축 생존 경로가 **확인되지 않음**(§4.2).

### G. 규격의 권고는 측정과 어긋난다 — agents.md

[agents.md](https://agents.md/): *"a README for agents"*. 권장 섹션에 **"Project overview"** 가 첫 항목으로 들어 있다.

**E가 무용하다고 지목한 바로 그 범주다.** 그리고 ETH 원문이 *"repository overviews, although popular and **recommended by model providers**, are not helpful"* 이라 적을 때 가리키는 것이 이 규격이다. 모노레포 규정은 *"the closest one takes precedence"* 로 F와 일치한다.

### H. 다른 조사와 맞물리는 지점

| 지점 | 연결 |
|---|---|
| A의 *"@import로 옮겨라"* | [지시 계층 §10](instruction-layers.md) — `@import`는 별도 memory 채널이라 압축에서 생존한다. **비용은 옮겨도 생존은 유지된다** |
| A의 `.claude/rules/` + `paths` | [지시 계층 §9.2](instruction-layers.md)가 실측에서 놓쳤던 층. 도구 자신이 권장 배치로 지목한다 |
| F의 32 KiB | [배포 §9.2](harness-distribution.md)가 실증한 값. 이 조사는 **왜 그것이 규격인지**(내용 분할 유도)를 채운다 |
| C의 "검증 지시를 지워라" | [검증·교차리뷰](verification-and-cross-review.md)의 훅 9개·게이트 0개 구조에 직접 걸린다 |
| D의 서브에이전트 상한 | [에이전트 조율](agent-orchestration.md)의 *"이 영역에는 쓰지 말라"* 와 **같은 방향** — 벤더 프롬프팅 문서가 독립적으로 상한을 권한다 |

---

## 1. 1차(도구) — Claude Code가 스스로 규정하는 내용

**방법**: `~/.local/share/claude/versions/2.1.220` (256 MB 단일 바이너리)에서 `strings`로 프롬프트 원문을 추출했다. `strings -n 20`은 `Include:` 같은 짧은 헤더를 놓치므로 **`-n 3`으로 재추출해 목록 구획을 복원했다**(§부록 방법 기록).

### 1.1 `/init`이 두 벌 있다

```
function Vcy(){ return Yt(process.env.CLAUDE_CODE_NEW_INIT) || Ke("tengu_slate_harbor_experiment", !1) }
getPromptForCommand(){ return [{ type:"text", text: Vcy() ? Kcy() : zcy() }] }
```

`zcy()`가 기존 `/init`, `Kcy()`가 신규다. 커맨드 설명도 갈린다 — 기존 *"Initialize a new CLAUDE.md file with codebase documentation"*, 신규 *"Initialize new CLAUDE.md file(s) and optional skills/hooks with codebase documentation"*.

> **게이트 뒤에 있다.** 환경변수 또는 statsig 실험 플래그로 켜진다.

#### 1.1.1 실행 확인 — 신규는 기본값이 아니다 (2026-08-03)

**초판은 이것을 §6-1의 열린 질문으로 남겼으나, 1분짜리 동작 확인이라 실행했다.** 동일한 빈 저장소(`a.ts` 한 줄 + `package.json`, 커밋 0개)를 두 벌 만들고 `claude -p "/init"`을 환경변수 유무로 각각 돌렸다.

| 조건 | 관측 |
|---|---|
| 기본 | Phase 언급 없음, 스킬·훅 제안 없음, **CLAUDE.md를 바로 작성** |
| `CLAUDE_CODE_NEW_INIT=1` | **판정 기준을 인용** (*"빼면 Claude가 실수하게 되는 내용만"*), 스킬·훅을 각각 이유를 대며 기각, **`AskUserQuestion`을 못 써 Phase 3을 건너뛴다고 명시** |

**기본 경로에서 신규 프롬프트의 Phase 구조가 전혀 나타나지 않는다. 이 계정에서 `/init`이 실행하는 것은 구식 프롬프트다.**

> **한계 둘.** (1) statsig 게이트는 계정·롤아웃 단위이므로 **"이 계정에서 꺼져 있다"까지가 결론**이고 전역 기본값이 아니다. (2) 헤드리스 `-p`는 `AskUserQuestion`이 없어 신규 경로가 열화된다 — 신규 실행이 그 사실을 스스로 보고했다. **그럼에도 판정은 선다**: 열화되더라도 Phase 2·4의 탐색·제안 구조는 남아야 하는데 기본 실행에는 그 흔적이 없다.

### 1.2 두 프롬프트가 정면으로 어긋난다 — 그리고 산출물이 갈린다

| | 기존 `/init` (`zcy`) | 신규 `/init` (`Kcy`) |
|---|---|---|
| **판정 기준** | *(없음)* — 항목 나열만 | *"only include what Claude would get wrong without it"* / *"Would removing this cause Claude to make mistakes?"* |
| **아키텍처** | *"2. **High-level code architecture and structure** so that future instances can be productive more quickly."* | **Exclude**: *"File-by-file structure or component lists (Claude can discover these by reading the codebase)"* |
| **길이** | 언급 없음 | *"must be concise"* |
| **긴 내용** | 언급 없음 | `@import` 또는 스킬로 이동 |
| **자주 바뀌는 정보** | 언급 없음 | `@import`로 참조 |

**두 프롬프트는 "쉽게 발견 가능한 구조 나열 금지"라는 조항을 공유한다** — 기존에도 *"Avoid listing every component or file structure that can be easily discovered"* 가 있다. 어긋나는 것은 그 위 층이다: 기존은 *"big picture architecture that requires reading multiple files to understand"* 를 **요구 항목 2번**으로 두고, 신규는 개요 자체를 Exclude로 내린다. 남긴 것은 *"Non-obvious gotchas or **architectural decisions**"* 뿐이다 — **구조가 아니라 결정**이다.

**§1.1.1의 대조 실행이 이 차이가 장식이 아님을 보인다.** 같은 저장소, 같은 모델, 프롬프트만 다르다.

| | 구식 (기본) | 신규 (`CLAUDE_CODE_NEW_INIT=1`) |
|---|---|---|
| 산출 | `## Testing` + 4개 명령 + `## Repository state` | *"3줄 헤더 + 한 줄 사실"* |
| `npm test` | **적었다** | ***"manifest에서 자명하므로 명시적 제외 대상"*** — Exclude 목록의 마지막 항목을 그대로 적용 |
| 없는 내용 | *"구조가 생기면 갱신하라"* 안내를 스스로 추가 | *"내용을 지어내는 대신 앵커 역할의 최소 파일만"* |

> **Exclude 목록이 실제로 발화한다.** 구식 실행이 적은 `npm test`·`npx vitest run`은 신규 판정 기준의 *"Commands obvious from manifest files"* 에 정확히 걸리고, 신규 실행이 그것을 **이름 대어 기각했다.** 종류 기준이 산출물 크기를 좌우한다는 직접 증거다 — 다만 **표본 1회, 저장소 1개다.**

> **[지시 계층 §6.1](instruction-layers.md)의 §7-11이 여기서 한 칸 움직인다.** 그 절은 `/doctor`의 *제외* 기준(코드에서 유도 가능한 것)과 ETH의 *종류* 기준(개요 vs 비표준 관행)이 독립적으로 같은 경계를 그린다고 적고, **포함 기준은 비어 있다**고 했다. 신규 `/init`의 *"Claude가 이것 없이는 틀릴 내용만"* 이 거기에 들어간다. **그리고 이것은 제외 기준의 단순한 뒤집기가 아니다** — "유도 가능한가"는 코드의 속성이고, "이것 없이 틀리는가"는 **모델의 속성**이다. 모델이 바뀌면 답이 바뀐다. §2가 그 함의다.

### 1.3 계층 간 역할 분담이 도구 안에 있다

메모리 서브시스템 프롬프트(구획 B)가 **CLAUDE.md를 상위 권위로 전제한다.** 이 시리즈가 계층 문제를 다루면서 한 번도 확인하지 못했던 규정이다.

```
## What NOT to save in memory
- Anything already documented in CLAUDE.md files.
- Ephemeral task details: in-progress work, temporary state, current conversation context.
```

그리고 `project` 타입: *"not otherwise derivable from the code or git history"*, `reference` 타입: 외부 시스템 포인터, `feedback` 타입: *"so that the user … do not need to offer the same guidance twice"*.

**세 계층의 경계가 서로 다른 술어로 정의된다.**

| 계층 | 배제 술어 | 남는 것 |
|---|---|---|
| (어디에도 안 씀) | 코드·git에서 유도 가능 | — |
| **CLAUDE.md** | *이것 없이도 안 틀림* | 비표준 관행·명령·gotcha·아키텍처 결정 |
| **메모리** | *CLAUDE.md에 이미 문서화됨* / 일시적 | 진행 맥락·반복 피드백·외부 포인터 |

> **grid fin에 주는 구조적 함의**: 이 분업은 grid fin이 만들 것이 아니라 **이미 도구에 있다.** 하네스가 자체 규정을 얹으면 도구의 규정과 경쟁한다.

---

## 2. 최신 고성능 모델 — 무엇이 달라지는가

> **이 절이 사용자 요청의 중심이다.** 근거는 전부 **1차(벤더)** 이고, **자기 진술이라는 한계가 그대로 있다**(§6-3).

### 2.1 하네스 스캐폴딩이 이름 대어 지목됐다

Opus 5 프롬프팅 문서의 이 문장이 이 조사에서 가장 실행 가능한 항목이다.

> *"Claude Opus 5 verifies its own work without being told to. If your prompt contains explicit verification instructions … **remove them** … **The same applies to legacy harness scaffolding that adds separate verification steps.**"*

**그리고 "다시 쓰라"가 아니라 "지우라"다** — 마이그레이션 가이드가 *"this is a delete, not a rewrite"* 라고 못박는다. 나아가 **일반 프롬프팅 모범관행을 명시적으로 뒤집는다**: *"자기 점검을 시켜라"는 통상 타당한 조언이며 이 모델에서는 틀렸다.*

> **[검증·교차리뷰 조사](verification-and-cross-review.md)에 직접 걸린다.** 그 조사는 훅 9개 중 게이트가 0개이고 지적 163건 중 78.5%가 미조치라고 실측했다. **그 구조의 결함은 "검증이 부족하다"였는데, 지금 벤더는 "검증 지시가 과하다"고 말한다.** 두 진단이 충돌하는 것은 아니다 — *메커니즘으로 강제하는 게이트*(훅·CI)와 *모델에게 검증하라고 부탁하는 프롬프트*는 다른 층이고, 지목된 것은 후자다. **하지만 이 구분은 벤더 문서가 명시하지 않았고, 이 조사가 붙인 해석이다**(§6-4).

### 2.2 교정의 부호가 판본 사이에서 뒤집힌다

구획 D의 표가 요지다. 형태를 하나만 인용하면:

- **Opus 4.8 처방**: *"add explicit triggering guidance for subagents, file-based memory, and custom tools (4.8 under-reaches for these by default)"*
- **Opus 5 처방**: *"this model delegates **more** readily than Opus 4.8 — **remove any 'delegate more' guidance you added for 4.8** and add an explicit cap"*

**인접한 두 판본이다.** 4.7→4.8→5의 세 판본에서 내레이션은 적음→많음→더 많음으로 단조 증가하고, 위임은 많음(4.6)→적음(4.7·4.8)→많음(5)으로 **왕복한다.**

> **이것이 "무엇을 쓰는가"에 대한 답의 형태를 바꾼다.** 항목 목록이 아니라 **대상 모델에 대한 함수**이며, 값이 단조도 아니다. 상수 목록을 문서에 적어두면 다음 판본에서 부호가 뒤집힌 채 남는다.

### 2.3 그럼에도 안정적인 축

세 판본에 걸쳐 방향이 바뀌지 않은 것도 있다. **이쪽이 컨텍스트 파일에 적기 안전한 후보다.**

| 안정적 축 | 근거 |
|---|---|
| **문자 그대로의 지시 준수가 강해진다** (4.7 이후 일관) | *"interprets prompts more literally"*, *"does not silently generalize an instruction from one item to another"* |
| **따라서 심각도 필터는 실제로 리콜을 깎는다** (4.7·4.8·5·Sonnet 5 전부 동일 경고) | *"only report high-severity issues" → 문자 그대로 따름* |
| **부정 예시보다 긍정 예시가 낫다** (4.7·5) | *"Positive examples … more effective than instructions about what not to do"* |
| **도구 `description`에 트리거 조건을 넣으면 효과가 있다** | *"prescriptive descriptions that state *when* to call a tool … give meaningful lift"* |
| **과잉 처방은 품질을 낮춘다** (Fable 5·Sonnet 5) | *"too prescriptive … reduce output quality"* |

### 2.4 1M 창 — 벤더 주장과 문헌이 충돌한다

> *"Claude Opus 5 has a 1M token context window as both the default and the maximum, and its **instruction following, tool calling, and reasoning stay consistent throughout the window**."*

**[지시 계층 §9.1](instruction-layers.md)의 실측이 상시 로드 43.8k = 1M의 4.4%** 이므로, 이 문장을 곧이 받으면 **길이 축은 사실상 죽고 종류 축이 무혈입성한다.**

**그렇게 쓰지 않는다.**

| 반대편 | 내용 |
|---|---|
| [§3.1 Liu et al.](instruction-layers.md) | 위치 U자 효과. **비율이 아니라 절대 위치**의 문제다 |
| [§3.2 context rot](instruction-layers.md) | 절벽은 **문서상 한계 훨씬 전**에 온다. "창의 몇 %"는 애초에 잘못된 지표다 |
| [§3.3 Compliance Gap](instruction-layers.md) | 준수율은 **동시 제약 수**에도 걸린다 — 길이와 독립 |
| 자기 진술 | 벤더가 자사 모델의 강점으로 광고하는 축이다 |

**무엇이 이 충돌을 닫는가**: 상시 로드 계층을 그대로 두고 규칙 준수를 재는 대조 실험 — **§10(B1)이 이미 준 골격**을 길이 요인으로 확장한다. 규칙 파일 뒤에 무해한 패딩을 16k/64k/256k로 넣고 준수율을 잰다. **1회 실행 비교는 [29.3%가 오순위](evaluation.md)이므로 반복이 필요하고, 그 비용이 이 실험의 실제 장벽이다.**

> **이 조사는 이 축을 판정하지 않는다.** §6-2에 열린 질문으로 남긴다.

---

## 3. 측정 근거 — ETH 연구를 모델 축으로 다시 읽기

### 3.1 시험된 모델과 그 함의

| 에이전트 | 모델 | 온도 |
|---|---|---|
| Claude Code | **Sonnet-4.5** | 0 |
| Codex | **GPT-5.2**, **GPT-5.1-mini** | 0 |
| Qwen Code | **Qwen3-30b-coder** | 0.7 / top-p 0.8 |

**사용자가 지정한 세대가 하나도 없다.** Opus 5·Sonnet 5·Opus 4.8은 물론 Opus 4.6도 없다. §2가 보인 대로 **4.7→4.8→5 사이에서 지시 반응 특성이 크게 움직였으므로, 이 측정 결과를 최신 세대로 외삽할 근거가 없다.**

> **그런데 방향은 §2와 어긋나지 않는다.** ETH가 *"unnecessary requirements from context files make tasks harder"* 라 하고, 벤더가 *"too prescriptive … reduce output quality"* 라 한다. 서로 다른 방법으로 같은 쪽을 가리킨다 — **일치가 진리를 보장하지는 않으나 단일 출처 의존은 아니다.**

### 3.2 모델별 분해는 "생성 측"이다

논문이 보고하는 모델 차이는 *"stronger models don't generate better context files"* 이며, GPT-5.2가 생성한 파일이 SWE-bench Lite +2%, AGENTbench −3%로 갈린다는 예를 든다.

**이것은 "누가 파일을 잘 쓰는가"이지 "누가 파일을 덜 필요로 하는가"가 아니다.** 사용자 요청의 핵심 — *최신 고성능 모델은 컨텍스트 파일이 덜 필요한가* — 에 대한 **모델 × 컨텍스트파일 상호작용은 이 논문에서 확인하지 못했다.**

| 축 | 상태 |
|---|---|
| 생성 측 모델 차이 | **측정됨** — 강한 모델이 더 나은 파일을 쓰지는 않는다 |
| **소비 측 모델 차이** | **미확인** — 그리고 이 조사가 대체 자료를 찾지 못했다 |

**그러므로 "최신 모델은 지시가 덜 필요하다"는 서사를 이 문서는 채택하지 않는다.** 벤더 문서가 말하는 것은 그보다 좁다 — *특정 종류의 지시(검증·재확인·스캐폴딩)가 역효과를 낸다*이고, **동시에 다른 종류(범위·간결성·위임 상한)는 새로 필요해졌다.** 총량이 준다는 주장은 어디에도 없다.

### 3.3 판본 주의

이 문서는 **v1 HTML**을 확인했다. [아젠다의 2차 감사](research-agenda.md)가 기록한 대로 v1→v2에서 초록의 주장 강도가 *"tend to reduce"* → *"does not generally improve"* 로 **약해졌고**, 비용 수치는 동일하다. **모델 목록과 per-model 수치가 v2에서 바뀌었는지는 확인하지 않았다**(§6-5).

---

## 4. AGENTS.md 쪽 — 기제가 다르다

> **[지시 계층 §7-8](instruction-layers.md)이 *"Codex 쪽 계층은 조사하지 않았다"* 고 남긴 공백이다.** CLAUDE.md의 답을 AGENTS.md로 옮길 수 있는지는 기제에 달려 있다.

### 4.1 규격 대조

| 축 | CLAUDE.md (Claude Code) | AGENTS.md (Codex) |
|---|---|---|
| 탐색 | 작업 디렉터리에서 **상향** 순회, 각 층 병합 | 전역 → **git 루트에서 하향** 순회 |
| 우선순위 | 병합(모두 로드) | **근접 파일이 override**, 디렉터리당 1개 |
| override 파일 | 없음 | **`AGENTS.override.md`** — 각 스코프에서 우선 |
| 포함 기제 | **`@import`** (별도 memory 채널) | **없음** — 인라인 또는 디렉터리 분할 |
| 총합 상한 | **없음** (개별 스킬 description 1,536자 상한만) | **`project_doc_max_bytes` 32 KiB** — 초과분 조용히 소실 |
| 지시 대체 | 없음 | **`model_instructions_file`** — 내장 지시 자체 교체 |
| 압축 생존 | **확인됨** (별도 채널, [§10](instruction-layers.md)) | §4.2 — **미확인** |

**세 가지가 grid fin 설계에 직접 걸린다.**

1. **`@import`가 없으므로 A의 처방("긴 것은 `@import`로 빼라")이 그대로 옮겨가지 않는다.** Codex 쪽 등가물은 **디렉터리 분할**이며, 그러면 **디렉터리 구조가 곧 규칙 구조가 된다** — [배포 §9.2](harness-distribution.md)가 이미 지적한 결론이다.
2. **총합 상한이 있으므로 "무엇을 쓰는가"가 강제된다.** Claude Code는 비대해져도 조용히 느려지고, Codex는 **조용히 잘린다.** 후자가 더 위험하다 — 잘림이 오류로 드러나지 않는다.
3. **override 층이 개인 설정의 등가물을 준다** — `CLAUDE.local.md` ↔ `~/.codex/AGENTS.override.md`. 다만 전자는 프로젝트 로컬, 후자는 **전역**이다. 정확한 대응이 아니다.

### 4.2 압축 생존 — 미확인

검색 요약이 이렇게 보고한다:

> 압축 후 `build_initial_context()`로 base instructions / AGENTS.md / permissions / skills를 재구성하고 `insert_initial_context_before_last_real_user_or_summary()`로 압축된 히스토리에 재주입한다.

**사실이면 [§10.4](instruction-layers.md)의 결론이 AGENTS.md에도 확장되고, Governance Decay는 이 경로에도 해당하지 않는다.** 그러면 CLAUDE.md/AGENTS.md 양쪽 모두 압축이 규칙을 지우지 않는다.

**그러나 이것은 검색 요약이다.** 이 시리즈가 [두 번 데인 형태](research-agenda.md)와 정확히 같다 — 구체적이고 그럴듯하며 함수명까지 있다. **함수명이 있다는 것은 검증 가능하다는 뜻이지 검증되었다는 뜻이 아니다.**

**확인 경로 둘**: (a) `codex-rust` 소스에서 두 함수명 grep — 이 조사는 fossies 미러가 401을 반환해 실패했다. (b) **동작 확인** — [§8.2](instruction-layers.md) 프로토콜을 Codex에서 재현. B1이 이미 형태를 준다. **후자가 (a)보다 강하다** — 소스에 함수가 있어도 호출 경로가 실제로 타는지는 별개다.

> **이 조사는 §4.2를 근거로 어떤 결론도 세우지 않았다.**

---

## 5. 실측 — 지금 무엇이 실려 있는가, 종류별로

> **[§9.5](instruction-layers.md)가 *"`/context all`은 파일 단위로만 준다. 종류별로 가르려면 파일 내부를 분류해야 한다"* 고 적고, [저장소 위생 §5.2](repository-hygiene.md)의 절 단위 분류를 유일한 선례로 들었다. 이 절이 그 작업이다.**

### 5.1 harness-guide.md 종류별 분류

`harness-guide.md`는 상시 로드 바이트의 55%이자 **AGENTS.md 본문 전체**다. `## ` 섹션 단위로 줄 수를 세고 종류를 붙였다.

| 종류 | 섹션 | 줄 | 비중 |
|---|---|---:|---:|
| **튜토리얼 / 도구 walkthrough** | graphify 사용 가이드 123, Codex 스킬 72 | **195** | **55%** |
| **저장소·구조 개요** | `.claude/` 구조 45, 에이전트 12, `.harness/` 11, 자동화 훅 9, references/ 8, Codex 차이점 8 | **93** | **26%** |
| **절차 / 규약** | 개발 워크플로우 20, 문서 버전 관리 11, 컴포넌트 추가 9 | 40 | 11% |
| **참조표** | dev-context.json 설정 키 | 21 | 6% |
| **행동 하드 제약** | 질문 처리 규칙 | **7** | **2%** |
| **합계** | | **356** | |

**세 가지를 읽는다.**

1. **개요 26%는 [저장소 위생 §5.2](repository-hygiene.md)의 "약 26%"와 일치한다.** 다른 사람이 다른 시점에 같은 파일을 다른 방법으로 분류해 같은 값이 나왔다 — **분류 자체의 재현성 증거**다.
2. **가장 큰 덩어리는 개요가 아니라 튜토리얼 55%다.** 그리고 신규 `/init`의 Exclude 목록에 *"Long tutorials or walkthroughs (move to a separate file and reference with `@path/to/import`, or put in a skill)"* 가 **명시되어 있다.** `graphify 사용 가이드` 123줄은 그 규정의 교과서적 사례다 — 외부 CLI 도구의 설치·설정·호출·출력 위치 설명이다.
3. **행동을 규정하는 하드 제약은 7줄, 2%다.** [§1.3](instruction-layers.md)이 *"6개 규칙 파일 중 3개가 강제형 마커 0"* 이라 실측한 것의 상위 파일 판이다.

> **§7-11(길이 축 vs 종류 축)에 대해 이 측정이 말하는 것.** 두 축의 상대적 크기는 여전히 못 가른다 — 그러려면 대조 실험이 필요하다(§2.4). **그러나 무엇을 먼저 지울지는 이제 정해진다** — 튜토리얼 55% + 개요 26% = **81%가 신규 `/init`과 ETH가 독립적으로 지목한 범주에 들어가고, 그것을 지우면 길이도 함께 준다.** 두 축의 처방이 **이 파일에서는 갈리지 않는다.**
>
> **그리고 이 결론은 §6-2(1M 창에서 길이 축이 살아 있는가)에 걸려 있지 않다.** 벤더 주장(#6)이 사실로 판명되어 **길이 축이 완전히 죽어도 81%는 그대로 삭제 대상이다** — 근거가 "길어서"가 아니라 "종류가 틀려서"이기 때문이다. **역도 성립한다**: 길이 축이 살아 있으면 같은 삭제가 두 이유로 정당화될 뿐이다. **이 조사의 최대 미해결이 이 조사의 유일한 처방을 게이트하지 않는다.**
>
> **다만 읽는 방향에 주의가 필요하다.** 55%/26%라는 표현은 *분량* 지표라 길이 축을 근거로 삼는 것처럼 읽히기 쉽다. 실제 논거는 **범주 소속**이고, 줄 수는 그 범주가 얼마나 큰지를 보여주는 보조 수치일 뿐이다.

### 5.2 AGENTS.md는 사본이고 이미 어긋났다

`AGENTS.md` 384줄 = Codex용 헤더 21줄 + `<!-- harness-guide:begin -->` 인라인.

```
$ diff <(sed -n '22,384p' AGENTS.md) <(sed -n '5,377p' .harness/harness-guide.md) | wc -l
54
```

| 누락·불일치 | 내용 |
|---|---|
| 섹션 1개 누락 | `### 포지셔닝: 네비게이션은 LSP, graphify는 on-demand 아키텍처 조감` (6줄) |
| 커맨드 2개 누락 | `/flow-worktree` 진입점, `wf-worktree-context` 위임 |
| 설정 권장값 불일치 | `graphify.targets`: AGENTS.md `["./src", "./docs"]` vs guide `["./src", "./docs/specs", "scripts"]` |

**[배포 §9.1](harness-distribution.md)이 concat-인라인 기제가 *"정상 동작한다"* 고 실증했다. 이 관측은 그것과 모순되지 않는다** — **재생성 시점 불일치로 보인다.**

> **원인은 diff로 확인하지 않았다.** 유력한 경쟁 가설이 하나 있다 — [배포 §9.2](harness-distribution.md)가 인라인 대상이 **32 KiB 상한의 1.24배**라고 실증했으므로 **잘림**도 같은 증상을 낼 수 있다. **다만 이 diff는 그 가설과 잘 맞지 않는다**: 누락이 파일 **중간**(`250a254` 구간)에 있고 꼬리는 온전하며, 잘림이면 꼬리부터 사라져야 한다. 게다가 설정 권장값은 누락이 아니라 **다른 값**이라 잘림으로 설명되지 않는다. **그래서 시점 불일치 쪽이 유력하나, 배포 스크립트 실행 이력을 확인하지 않았으므로 확정이 아니다.**

> **grid fin에 주는 함의가 §4.1과 맞물린다.** `@import`가 없는 쪽에 같은 내용을 인라인으로 복제하는 구조는 **동기화 실행을 강제하지 않으면 조용히 갈라진다.** 그리고 갈라진 쪽이 Codex 리뷰어가 읽는 문서다 — [교차 리뷰 구조](verification-and-cross-review.md)에서 작성 측과 리뷰 측이 **서로 다른 규칙을 보게 된다.** [평가 §1.5](evaluation.md)가 하네스 분산/모델 분산 = 7.80×라고 보고한 그 교란의 국소 사례다.

---

## 6. 이 조사가 답하지 않은 것 / 열린 질문

1. ~~**신규 `/init`이 기본값인가.**~~ **해소 — §1.1.1에서 실행 확인. 이 계정에서는 기본값이 아니다.** 남는 것은 **롤아웃 범위**다 — statsig 게이트이므로 다른 계정·다른 버전에서 켜져 있을 수 있고, 확인할 경로가 없다. **그래서 §1의 신규 프롬프트는 "지금 도구가 하는 일"이 아니라 "도구 제작자가 다음으로 정한 기준"으로 읽어야 한다.** 근거로서의 값어치는 오히려 이쪽이 명확하다 — **구식이 무엇을 잘못했다고 보는지가 신규 Exclude 목록에 그대로 적혀 있다.**
2. **1M 창에서 길이 축이 살아 있는가.** §2.4. **이 문서의 가장 큰 미해결이며, 벤더 주장과 피어리뷰 문헌이 정면 충돌하는 유일한 지점이다.**
3. **벤더 프롬프팅 문서의 근거.** *"removing them reduces wasted tokens with no loss in quality"*, *"cut ask-rate by ~12 percentage points"* 같은 수치가 나오지만 **방법·표본·평가셋이 공개되지 않았다.** 자사 모델에 대한 자기 진술이다. 반증 자료도 찾지 못했다.
4. **"메커니즘 게이트"와 "프롬프트 검증 지시"의 구분은 이 조사가 붙인 해석이다**(§2.1). 벤더 문서는 *"legacy harness scaffolding that adds separate verification steps"* 라고만 하며, 훅·CI가 그 범위인지 명시하지 않는다. **틀리면 [검증 조사](verification-and-cross-review.md)의 권고 방향이 반대로 뒤집힌다.**
5. **ETH v2에서 모델 목록·수치가 바뀌었는지 미확인**(§3.3).
6. **Codex의 AGENTS.md 압축 생존 미확인**(§4.2). 검색 요약뿐이다.
7. **소비 측 모델 상호작용의 대체 자료를 찾지 못했다**(§3.2). "강한 모델이 컨텍스트 파일을 덜 필요로 하는가"를 재는 연구가 있는지 조사가 수렴하지 않았다.
8. **`model_instructions_file`(내장 지시 교체)의 실제 효과.** F에 규격만 있고 사용 사례를 확인하지 않았다. 하네스가 지시 전체를 갈아끼우는 경로이므로 잠재적으로 큰 축이다.
9. **`.claude/rules/`의 `paths` frontmatter 스코핑 동작 미확인.** 신규 `/init`이 권장 배치로 지목했으나([§9.2](instruction-layers.md)가 실측에서 놓친 층이기도 하다) 실제 스코핑 규칙·로드 시점을 확인하지 않았다.
10. **`learned/` 중첩 스킬 노출 여부**([§7-5](instruction-layers.md))는 이 조사에서도 열린 채다.

---

## 부록. 조사 방법 및 한계

**방법**

- **바이너리 문자열 추출** — `~/.local/share/claude/versions/2.1.220`(256,908,272 B)에 `strings`. `/init` 두 판본(`zcy`/`Kcy`), 메모리 시스템 프롬프트, `/doctor` 관련 문자열
- WebFetch 6회 — arXiv 2602.11988 초록·PDF·v1 HTML, agents.md 명세, learn.chatgpt.com AGENTS.md 가이드·config reference, platform.claude.com Opus 5 프롬프팅
- WebSearch 3회 — Codex AGENTS.md 탐색 순서, Opus 5 프롬프팅, Codex 압축·AGENTS.md 지속
- `claude-api` 스킬 로드 — Opus 5/Sonnet 5/Fable 5 마이그레이션 가이드의 행동 변화 절
- 로컬 직접 측정 — `harness-guide.md` 섹션별 줄 수(awk), `AGENTS.md` ↔ `harness-guide.md` diff
- **대조 실행 2회** — 동일한 빈 저장소 두 벌에서 `claude -p "/init"`을 기본값과 `CLAUDE_CODE_NEW_INIT=1`로 각각 실행(§1.1.1)

**직접 확인 (1차 관측)**

- 신규 `/init` 프롬프트 전문(Phase 0~8), Include/Exclude 목록 원문
- 메모리 시스템 프롬프트의 `What NOT to save` 구획
- `harness-guide.md` 13개 섹션 356줄의 종류별 분류
- `AGENTS.md`(384줄) = 헤더 21줄 + `harness-guide.md` 인라인, **diff 54줄**

**방법 기록 — 짧은 문자열을 놓칠 뻔했다**

`strings -n 20`으로 먼저 추출했더니 **`Include:` / `Exclude:` 헤더가 임계값 미만이라 사라졌고, 두 목록이 하나로 이어져 보였다.** 그 상태로 읽으면 "Exclude 항목을 Include로 오독"하는 정반대 결론이 나온다. **목록의 논리적 경계가 어긋나는 것을 단서로 `-n 3`으로 재추출해 잡았다.**

> **[§10.5](instruction-layers.md)가 *"출력을 잘라 읽는 것이 2차 인용과 같은 등급의 위험"* 이라 적은 것의 세 번째 사례다.** 그때는 30줄 절단, 이번은 문자열 길이 임계. **형태가 다르고 위험이 같다 — 도구의 기본 필터가 내용의 구조를 자른다.**

**한계**

- **§2의 근거가 전부 벤더 자기 진술이다.** 수치의 방법·표본이 공개되지 않았고 독립 재현이 없다(§6-3).
- **ETH 논문은 v1 HTML까지다.** AGENTbench 구성, 통계 처리, v2 변경분을 읽지 않았다.
- **Codex 압축 생존은 검색 요약 근거다**(§4.2). 소스 확인 실패(fossies 401), 동작 확인 미실시.
- **`/init` 대조 실행은 표본 1회, 저장소 1개, 헤드리스 모드다.** 신규 경로가 `AskUserQuestion` 부재로 열화된 상태였고(그 사실을 실행이 스스로 보고했다), 대화형 세션의 산출물은 다를 수 있다. **"기본값이 아니다"는 판정은 견디지만, 두 산출물의 크기 차이를 효과 크기로 읽으면 안 된다** — [1회 실행 비교는 29.3%가 오순위](evaluation.md)다.
- **statsig 게이트의 롤아웃 범위를 확인할 경로가 없다**(§6-1). 이 계정 밖의 상태는 모른다.
- **종류별 분류는 1인 판단이다.** 섹션을 단일 종류에 배정했으나 실제로는 섞인 섹션이 있다(예: `Codex 스킬` 72줄에 절차와 참조가 공존). 경계 사례의 배정이 바뀌면 비중이 몇 %p 움직인다. **다만 "튜토리얼+개요가 8할"이라는 결론은 그 정도 흔들림에 견딘다.**
- **grid fin에 아직 CLAUDE.md·AGENTS.md가 없다.** 이 조사의 실측 대상은 전부 기존 하네스이며, [메모리 기록](../../../.claude/)대로 그것은 참고 자료이지 계승 대상이 아니다.
