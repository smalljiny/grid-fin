# 스킬의 타입과 계층, 그리고 서브에이전트와의 조합 — 조사

*Generated: 2026-08-03 | Sources: 12 심층 + 40여 검색 | Adapters: [adapter-exa, adapter-firecrawl] | Failed: 없음*

**최초 작성**: 2026-08-03
**최종 수정**: 2026-08-03

**대상 프로젝트**: grid fin (신규 개인용 개발 하네스)
**전제**: **커스텀 슬래시 커맨드 없이 스킬만으로 하네스를 구성한다**
**조사 도구**: `adapter-deep-research`(exa + firecrawl), Claude Code 2.1.220 바이너리 문자열 추출
**성격**: 조사. 타입 체계의 확정은 하지 않는다.

선행 문서
- [context-file-content.md](context-file-content.md) — 신규 `/init`의 *"Long tutorials or walkthroughs → put in a skill"* 이 이 조사로 넘어오는 지점
- [instruction-layers.md](instruction-layers.md) §1.2·§7-4·§7-5 — 라우팅 표면 예산, 중첩 스킬 노출
- [agent-orchestration.md](agent-orchestration.md) — 서브에이전트는 조율이 아니라 **컨텍스트 격리** 도구
- [evaluation.md](evaluation.md) §6-1 — 스킬 활성화 측정법 부재

---

## Executive Summary

**"커맨드 없이 스킬만"은 기능 손실이 없다.** 공식 문서상 커맨드의 고유 기능(인자 힌트, 도구 사전승인, 모델 호출 차단)이 전부 스킬 frontmatter로 흡수됐고, `.claude/commands/*.md`는 같은 표에서 **스킬의 한 가지 배치 형태**로 취급된다(§1.1). 따라서 이 조사의 질문은 "무엇을 포기하는가"가 아니라 **"하나의 타입 안에서 무엇으로 가르는가"** 가 된다.

**공식 문서가 이미 두 축을 명시한다** — *"how you want the skill invoked (by you, by Claude, or both) and where you want it to run (inline or in a subagent)"* ([Claude Code Skills](https://code.claude.com/docs/en/skills)). 이 2×2가 접두어 규약보다 **먼저 서야 할 타입 체계**다(§1.2).

**서브에이전트와 스킬은 양방향으로 맞물리고, 문서가 그것을 서로의 역이라고 부른다** — 에이전트의 `skills:`(스킬을 에이전트에 프리로드) ↔ 스킬의 `context: fork` + `agent:`(스킬을 에이전트로 포크)(§3.1).

**수량에 실증 근거가 생겼다.** SkillsBench(84과제·7,308 trajectory)는 **과제당 2–3개가 최적(+18.6pp)이고 4개 이상은 +5.9pp로 급락**한다고 보고한다. 그리고 **"comprehensive" 스킬은 −2.9pp로 해가 된다**(§2.1).

**계층은 실무에서 거의 쓰이지 않는다.** 실제 스킬 238개 분석에서 다른 스킬을 참조하는 컴포넌트는 `Related Skills` **8.0%**, `Skill in a Skill` **1.7%** 뿐이다(§2.2). **계층 설계의 "베스트 케이스"를 찾는 질문에 대한 답은 "코퍼스에는 사실상 없다"이며, 있는 것은 도구 기제와 제안 수준의 시스템 둘이다**(§4).

---

## 0. 조사 요약

| # | 관측 | 근거 | 등급 |
|---|---|---|---|
| 1 | **커맨드의 고유 기능이 전부 스킬로 흡수됐다** — `argument-hint`, `allowed-tools`, `disable-model-invocation`, `${...}` 치환, 인라인 `!` 셸이 모두 스킬 frontmatter에 있다 | §1.1 | 1차(벤더+도구) |
| 2 | **공식 타입 축은 접두어가 아니라 (호출 주체 × 실행 위치) 2×2다** | §1.2 | 1차(벤더) |
| 3 | **내용 유형은 둘로 갈린다** — *Reference content*(지식, 인라인) vs *Task content*(절차, `/name` 호출) | §1.3 | 1차(벤더) |
| 4 | **스킬 본문은 호출 후 세션 내내 컨텍스트에 남는다.** 압축 시 각 스킬의 최근 1회분을 **5,000토큰까지** 재부착 | §1.4 | 1차(벤더) |
| 5 | **SkillsBench: 과제당 2–3개가 최적(+18.6pp), 4개 이상은 +5.9pp** | §2.1 | 측정(프리프린트) |
| 6 | **SkillsBench: comprehensive 스킬은 −2.9pp.** detailed(+18.8)·compact(+17.1)가 낫다 | §2.1 | 측정 |
| 7 | **SkillsBench: 자가 생성 스킬은 효과가 없거나 음수다** — ETH의 컨텍스트 파일 결과와 같은 방향 | §2.1 | 측정 |
| 8 | **SkillsBench: Haiku+스킬(27.7%) > Opus 4.5 무스킬(22.0%)** — 스킬이 모델 용량을 부분 보상한다 | §2.1 | 측정 |
| 9 | **스킬 *안쪽* 구성의 실측 taxonomy: 13개 상위 / 44개 하위 semantic component** (실제 스킬 238개). **이것은 스킬 *사이*의 타입 체계가 아니다 — §1.2와 직교한다** | §2.2 | 측정 |
| 10 | **계층·합성 컴포넌트는 희소하다** — Related Skills 8.0%, Skill in a Skill 1.7%, Agent Composition 1.7%, Instruction Hierarchy 1.3% | §2.2 | 측정 |
| 11 | **"skill smell" 26종·파일당 평균 10.5개. 그러나 그 기준이 블로그 29건 MLR이다** — 논문이 *"no systematic literature review or substantial body of scientific work exists"* 라고 자인 | §2.3 | **측정 + 자가출판 기반** |
| 12 | **스킬↔서브에이전트는 양방향이며 문서가 서로의 역이라고 명시한다** | §3.1 | 1차(벤더) |
| 13 | **`disable-model-invocation: true` 스킬은 서브에이전트에 프리로드할 수 없다** | §3.2 | 1차(벤더) |
| 14 | **서브에이전트는 이미 호출된 스킬을 보지 못한다** (fresh context) | §3.3 | 1차(벤더) |
| 15 | **§7-5가 닫힌다 — 중첩 스킬은 노출되며, 이름 충돌 시 경로로 네임스페이스된다**(`/apps/web:deploy`) | §5.1 | 1차(벤더) |
| 16 | **§7-4가 닫힌다 — 라우팅 표면 총합 제어 장치가 있다.** settings의 스킬별 listing override(`name-only`/`user-invocable-only`/`off`) | §5.2 | 1차(도구) |
| 17 | **공식 권고 상한: 본문 500줄**, description은 `when_to_use` 포함 **1,536자 캡** | §5.3 | 1차(벤더) |
| 18 | **`paths` glob으로 스킬 자동 활성화를 파일 경로에 스코프할 수 있다** | §5.3 | 1차(벤더) |

### 근거 등급

| 등급 | 무엇 |
|---|---|
| **1차(벤더)** | code.claude.com / platform.claude.com 공식 문서 |
| **1차(도구)** | Claude Code 2.1.220 바이너리 추출 문자열 |
| **측정** | SkillsBench(2602.12670), Anatomy-to-Smells(2607.01456v2), Skilldex(2604.16911) — **전부 2026 프리프린트** |
| **자가출판 기반** | Anatomy 논문의 "best practice"는 **구글 검색 상위 블로그 29건**의 MLR이다 |

---

## 1. 도구 규격 — 타입은 이미 정의되어 있다

### 1.1 커맨드는 스킬에 흡수됐다

**사용자 전제("커맨드 없이 스킬만")가 기능적으로 무엇을 포기하는지 먼저 확인했다. 답은 "아무것도"다.**

공식 커맨드 이름 결정 표가 `.claude/commands/*.md`를 **스킬의 배치 형태 중 하나로** 나열한다 ([Skills](https://code.claude.com/docs/en/skills)):

| 스킬 위치 | 커맨드 이름 |
|---|---|
| `.claude/skills/deploy-staging/SKILL.md` | `/deploy-staging` |
| **`.claude/commands/deploy.md`** | `/deploy` |
| `apps/web/.claude/skills/deploy/SKILL.md` (충돌 시) | `/apps/web:deploy` |
| `my-plugin/skills/review/SKILL.md` | `/my-plugin:review` |

그리고 **커맨드 전용이라 여겨지던 필드가 전부 스킬 frontmatter에 있다.** 바이너리에서 추출한 필드 집합(§부록)과 공식 frontmatter 표가 일치한다:

`name` · `description` · `when_to_use` · `model` · `effort` · `allowed-tools` · `disallowed-tools` · `argument-hint` · `arguments` · `disable-model-invocation` · `user-invocable` · `context` · `agent` · `background` · `hooks` · `paths` · `shell` · `version`

바이너리의 다음 문장이 이를 반대편에서 확인한다 — 공유 메모리 스킬 로드 시 *"capability frontmatter (`allowed-tools`, `hooks`, `model`, `shell`) is ignored, **inline shell (`!` commands) does not run**"*. **예외를 명시한다는 것은 정상 경로에서는 동작한다는 뜻이다.**

> **결론: "스킬만"은 축소가 아니라 통합이다.** 남는 설계 문제는 *잃은 기능을 무엇으로 대체할까*가 아니라 **하나가 된 타입 안에서 무엇으로 가를까**다.

### 1.2 공식이 제시하는 두 축

> *"Your `SKILL.md` can contain anything, but thinking through **how you want the skill invoked** (by you, by Claude, or both) and **where you want it to run** (inline or in a subagent) helps guide what to include."* ([Skills](https://code.claude.com/docs/en/skills))

**축 1 — 호출 주체**

| 설정 | 의미 | 공식 용례 |
|---|---|---|
| (기본) | 사용자·모델 둘 다 | 일반 |
| `disable-model-invocation: true` | **사용자만** | *"workflows with side effects or that you want to control timing, like `/commit`, `/deploy`, or `/send-slack-message`"* |
| `user-invocable: false` | **모델만** | *"background knowledge that isn't actionable as a command. A `legacy-system-context` skill explains how an old system works"* |

**축 2 — 실행 위치**

| 설정 | 의미 |
|---|---|
| (기본) | 인라인 — 메인 대화 컨텍스트 |
| `context: fork` | **포크된 서브에이전트 컨텍스트** |
| `+ agent: <type>` | 어느 서브에이전트 타입으로 포크할지 |
| `+ background: false` | 백그라운드가 아니라 **해당 턴에서 결과를 기다린다** (v2.1.218+) |

> **이 2×2가 접두어 규약보다 먼저다.** `wf-`/`flow-`/`adapter-` 같은 접두어는 사람이 읽는 라벨이고, 위 네 필드는 **도구가 실제로 다르게 취급하는 축**이다. 접두어로 타입을 표현하면 규약이고, 이 필드로 표현하면 **강제**다 — [강제 메커니즘 조사](enforcement-mechanisms.md)가 반복해 지적한 구분이 여기에도 걸린다.

### 1.3 내용 유형 둘

공식 문서가 SKILL.md 내용을 두 갈래로 나눈다:

| 유형 | 정의(원문) | 귀결 |
|---|---|---|
| **Reference content** | *"adds knowledge Claude applies to your current work. Conventions, patterns, style guides, domain knowledge. This content **runs inline** so Claude can use it alongside your conversation context."* | 인라인 + 모델 호출 |
| **Task content** | *"step-by-step instructions for a specific action, like deployments, commits, or code generation. These are often actions you want to **invoke directly with `/skill-name`**"* | `disable-model-invocation` + 흔히 `context: fork` |

**§1.2의 2×2와 겹친다** — Reference는 (모델 호출 × 인라인), Task는 (사용자 호출 × 포크)로 자연스럽게 떨어진다. **다만 나머지 두 칸이 비어 있고, 문서는 그 칸을 규정하지 않는다.**

### 1.4 비용 모델 — 스킬은 "온디맨드"이되 "일회성"이 아니다

> *"When you or Claude invoke a skill, the rendered `SKILL.md` content enters the conversation as a single message and **stays there for the rest of the session**."*
> *"Auto-compaction carries invoked skills forward within a token budget … re-attaches the most recent invocation of each skill after the summary, **keeping the first 5,000 tokens of each**."*

**세 가지 함의.**

1. **본문은 반복 토큰 비용이다** — 공식 문구가 *"every line is a recurring token cost"*. [지시 계층 조사](instruction-layers.md)가 상시 로드 계층에 적용한 예산 논리가 **호출된 스킬에도 그대로 적용된다.**
2. **압축이 스킬을 지우지 않는다** — [§10](instruction-layers.md)이 `@import`에 대해 확인한 생존이 스킬에도 성립하되, **기제가 다르다**(별도 채널이 아니라 명시적 재부착). 그리고 **5,000토큰에서 잘린다** — `@import`에는 없는 절단이다.
3. **"스킬이 안 듣는다"의 공식 진단이 있다** — *"the content is usually still present and the model is choosing other tools … Strengthen the skill's `description` … or **use hooks to enforce behavior deterministically**."* 벤더가 프롬프트의 한계와 훅으로의 승격을 인정한다.

---

## 2. 측정 근거 — 수량·구조·품질

### 2.1 SkillsBench — 개수와 분량에 숫자가 있다

[SkillsBench (arXiv 2602.12670)](https://arxiv.org/html/2602.12670v1). 84과제 / 11도메인 / 7개 에이전트-모델 조합 / **7,308 trajectory**. 조건 셋(무스킬 / 큐레이션 스킬 / 자가생성 스킬) + 결정적 검증기.

**Table 5 — 과제당 스킬 개수**

| 개수 | 스킬 있음 | 스킬 없음 | Δ |
|---|---:|---:|---:|
| 1개 | 42.2% | 24.4% | **+17.8** |
| **2–3개** | 42.0% | 23.4% | **+18.6** |
| **4개 이상** | 32.7% | 26.9% | **+5.9** |

> *"This non-monotonic relationship suggests that excessive Skills content creates **cognitive overhead or conflicting guidance**."*

**Table 6 — 분량/복잡도**

| 복잡도 | Pass | Δ | N |
|---|---:|---:|---:|
| Detailed | 42.7% | **+18.8** | 1,165 |
| Compact | 37.6% | **+17.1** | 845 |
| Standard | 37.1% | +10.1 | 773 |
| **Comprehensive** | 39.9% | **−2.9** | 140 |

**그리고 둘.**

- *"Curated Skills improve performance by **+16.2pp on average**; **self-generated Skills provide negligible or negative benefit**."* — **[ETH의 컨텍스트 파일 결과와 같은 방향이다**(LLM 생성 −0.5~−2%, 개발자 작성 +4%). 서로 다른 팀·다른 벤치마크·다른 산출물이 같은 쪽을 가리킨다.**
- Finding 7 — *"Claude Haiku 4.5 with Skills (27.7%) outperforms Haiku without Skills (11.0%) … Meanwhile, Claude Opus 4.5 without Skills achieves 22.0%."*

> **주의 넷.** ① "개수"는 **과제당 제공된 스킬 수**이지 저장소의 총 스킬 수가 아니다 — 라이브러리 크기 상한으로 읽으면 안 된다. ② `Comprehensive` 셀은 **N=140**으로 다른 행의 1/8이다. ③ 2026 프리프린트, 피어리뷰 전. ④ **시험 모델이 Opus 4.5·Sonnet·Haiku 4.5로 [선행 조사](context-file-content.md)가 지적한 것과 같은 세대 지체가 있다** — Opus 5는 없다.

### 2.2 실측 taxonomy — 스킬은 실제로 무엇으로 구성되는가

> **먼저 축을 갈라 둔다. 이 절은 §1.2와 다른 질문에 답한다.**
>
> | | 질문 | 단위 | 답 |
> |---|---|---|---|
> | **§1.2** | 스킬을 **서로에 대해** 어떻게 가르는가 | 스킬 1개 | 호출 주체 × 실행 위치 2×2 |
> | **§2.2 (이 절)** | 스킬 **안쪽**을 무엇으로 구성하는가 | SKILL.md의 H2 절 | 13개 상위 / 44개 하위 컴포넌트 |
>
> **두 축은 직교한다.** 사용자 질문의 "타입"은 §1.2 쪽이고, 이 절은 "각 타입의 스킬을 어떻게 쓰는가"에 해당한다. **그리고 이 절의 진짜 발견은 두 축의 비대칭이다** — 코퍼스는 **안쪽 어휘는 풍부하고(44종) 바깥쪽 어휘는 거의 비어 있다**(§2.2 말미).

[From Anatomy to Smells (arXiv 2607.01456v2)](https://arxiv.org/html/2607.01456v2). skills.sh 마켓플레이스 덤프(**133,149 스킬 / 8,808 퍼블리셔 / 13,460 저장소**)에서 표본 238개, H2 헤딩 1,615개를 두 명이 독립 코딩.

**13개 상위 컴포넌트** (출현율)

| 상위 | % | 주요 하위 |
|---|---:|---|
| **Task** | 74.4 | Steps Instruction 49.2, Subtask 24.0, Error Handling 18.5, Environmental Variation 10.1 |
| **Introduction** | 63.5 | Prerequisites 31.1, **Skill Trigger 23.1**, Skill Summary 21.0, Quick Start 8.8 |
| **References** | 57.1 | Reference Files 31.1, Commands 15.1, Domain Knowledge 13.9, Tips 13.5, **Related Skills 8.0** |
| **Principles** | 42.0 | Rules 39.1, Generation Quality 5.5, **Instruction Hierarchy 1.3** |
| **Usecase** | 32.8 | Common Patterns 20.2, Examples 17.7 |
| **Context** | 28.2 | Ambiguity Handling 10.5, Decision Tree 8.8, Guardrail Condition 4.2 |
| **Output Format** | 23.5 | Return Artifact 21.9, Lessons Learned 1.3 |
| **Practice** | 23.1 | Best Practices 11.8, Anti-Patterns 11.3 |
| **Evaluation** | 21.4 | Review Checklist 12.6, Running Tests 9.2 |
| **Tools** | 4.6 | 사전승인 도구 목록 |
| **MCP Integration** | 3.8 | |
| **Agent Architecture** | 2.1 | **Agent Composition 1.7**, Model Choice 0.8 |
| **Other** | 5.9 | **Skill in a Skill 1.7**, Metadata 1.7 |

> *"Task, Introduction, and References form the backbone of most skills, defining **what** the agent should do, **when** to do it, and **where** to find additional guidance."*

**계층에 대해 이 표가 말하는 것이 이 조사의 가장 중요한 발견이다.**

| 계층·합성을 표현하는 컴포넌트 | 출현율 |
|---|---:|
| Related Skills (다른 스킬 참조) | **8.0%** |
| Skill in a Skill (중첩 스킬 참조) | **1.7%** |
| Agent Composition (다중 에이전트 구성 지침) | **1.7%** |
| Instruction Hierarchy (충돌 시 우선순위) | **1.3%** |

**133,149개 규모의 생태계에서 스킬 간 계층은 사실상 실천되지 않는다.** 실제로 쓰이는 계층은 **스킬 *안쪽*의 progressive disclosure**(Reference Files 31.1%)이지 스킬 *사이*의 구조가 아니다.

> **"연구사 베스트 케이스"를 찾는 질문에 대한 정직한 답**: **inter-skill 계층의 검증된 사례는 코퍼스에 없다.** 있는 것은 (a) 도구가 제공하는 기제(§5), (b) 제안 수준의 시스템 둘(§4)이며, **어느 쪽도 성능 개선을 측정하지 않았다.**

### 2.3 "skill smell" — 숫자는 크지만 기준이 약하다

같은 논문이 26종의 smell을 정의하고 238개에 자동 검출기를 돌렸다. 결과: **11/26이 절반 이상 파일에 출현**, 파일당 **평균 10.5개**, 완전 무결한 파일 **1개**. 최다는 Rationalization Loophole **94%**. 그리고 *"skill smells rarely disappear once introduced"*.

**그러나 등급을 낮춰 읽어야 한다.** 논문 스스로 방법을 이렇게 적는다:

> *"To the best of our knowledge, **no systematic literature review or substantial body of scientific work exists on best practices for SKILL.md authoring.** Therefore, we conducted a Multivocal Literature Review … using **Google Search** to retrieve the top 50 online sources"*

그리고 smell은 그 best practice를 **뒤집어 만든 것**이다. 저자들은 *"We observed cases where recommendations conflicted across sources"* 도 기록한다.

> **따라서 "평균 10.5개의 smell"은 품질 결함의 수가 아니라 블로그 권고에 대한 불일치 수다.** 성능과의 연결은 이 논문이 재지 않았다. **이 시리즈가 반복해 경계해온 자가출판 의존이 논문의 방법론 안에 들어가 있는 형태이며, 인용할 때 이 층을 통과시켜서는 안 된다.**
>
> **다만 RQ1의 taxonomy(§2.2)는 다르다** — 실제 파일에서 귀납한 것이라 블로그에 의존하지 않는다. **같은 논문 안에서 근거 등급이 갈린다.**

---

## 3. 서브에이전트와 스킬 — 양방향으로 맞물린다

### 3.1 두 방향이 서로의 역이다

공식 문서가 명시한다 ([Subagents](https://code.claude.com/docs/en/subagents)):

> *"This is the **inverse** of running a skill in a subagent. With `skills` in a subagent, **the subagent controls the system prompt and loads skill content**. With `context: fork` in a skill, **the skill content is injected into the agent you specify**."*

| 방향 | 설정 위치 | 누가 주도 | 쓰임 |
|---|---|---|---|
| **에이전트 ← 스킬** | 에이전트 `skills: [...]` | 서브에이전트 | 도메인 지식을 **시작 시점에** 주입 |
| **스킬 → 에이전트** | 스킬 `context: fork` + `agent:` | 스킬 | 절차를 **격리 컨텍스트에서** 실행 |

> ⚠️ **`context: fork`의 기본값은 `background: true`다 — 호출한 턴이 결과를 기다리지 않는다.** 기다리게 하려면 `background: false`를 명시해야 하고, 그 필드는 **v2.1.218+** 다.
>
> **하네스 설계에 직접 걸린다.** 리뷰·검증 스킬을 `context: fork`로 돌리면 **기본 설정에서는 메인 스레드가 결과 없이 진행한다.** 그리고 [에이전트 조율 조사](agent-orchestration.md)가 확인한 대로 **서브에이전트의 산출은 부모에게 압축된 요약으로만 도달한다** — 두 성질이 겹치면 "포크했는데 아무것도 안 돌아온 것처럼 보이는" 경로가 된다. **표의 한 줄이 아니라 설계 제약이다.**

에이전트 `skills:` 필드 규격:

> *"The **full skill content** is injected, not only the description. … This field controls **which skills are preloaded, not which skills the subagent can access**: without it, the subagent can still discover and invoke project, user, and plugin skills through the Skill tool during execution."*

### 3.2 제약 — 두 축이 서로를 막는다

> *"You **can't preload skills that set `disable-model-invocation: true`**, since preloading draws from the same set of skills Claude can invoke. This includes the bundled `/verify` and `/code-review` skills."*

**§1.2의 축 1(호출 주체)이 축 2(서브에이전트 조합)를 제약한다.** 사용자 전용으로 잠근 스킬은 서브에이전트에 프리로드할 수 없다. 그리고 바이너리에서 확인한 대응 문장:

> *"…is user-invocable only (disable-model-invocation) and **cannot run in coordinator mode**: the coordinator does not load skill content, and workers cannot invoke it via the [Skill tool]"*

> **설계 함의**: `disable-model-invocation`을 부작용 방지용으로 넓게 쓰면 **그 스킬은 자동화 경로 전체에서 사라진다.** 사용자 요청의 "커맨드 없이 스킬만" 구성에서 예전 커맨드를 전부 `disable-model-invocation`으로 옮기면 이 벽에 부딪힌다.

### 3.3 서브에이전트는 상속하지 않는다

> *"Each subagent starts with a fresh, isolated context window. It doesn't see your conversation history, **the skills you've already invoked**, or the files Claude has already read."*
> *"**Preloaded skills**: full content of any skill named in the agent's `skills` field. **Built-in agents don't preload skills.**"*

**즉 스킬은 서브에이전트 경계를 자동으로 넘지 않는다.** 넘기려면 명시적으로 `skills:`에 적거나, 서브에이전트가 Skill 도구로 다시 호출해야 한다(그러면 그 컨텍스트에서 다시 토큰을 낸다).

**그리고 공식 문서가 위임 대신 스킬을 쓰라고 말하는 지점이 있다**:

> *"Consider **Skills instead** when you want reusable prompts or workflows that run in the main conversation context rather than isolated subagent context."*

### 3.4 언제 위임하는가 — 세 자료가 같은 방향

| 자료 | 진술 |
|---|---|
| **바이너리(도구)** | *"Delegate for work that is genuinely independent, large enough to justify a fresh context, or naturally parallel. **Otherwise, do it yourself.**"* |
| **Opus 5 공식 프롬프팅** ([선행 조사 §2](context-file-content.md)) | *"Delegate to a subagent only for large tasks that are genuinely independent and parallelizable … **do not use subagents to verify or double-check your own work**"* |
| **[에이전트 조율 조사](agent-orchestration.md)** | 서브에이전트의 공식 목적은 조율이 아니라 **컨텍스트 격리**. 실측 채택률 4.6%, 다중 에이전트는 *"minimal performance gains"* |

**세 자료가 독립적으로 "기본은 인라인, 위임은 예외"를 말한다.** 그리고 [선행 조사 §2.2](context-file-content.md)가 기록한 대로 **Opus 5는 위임을 과다하게 하므로 상한을 거는 쪽이 필요하다** — 4.8용으로 쓴 "더 위임하라"는 지시는 빼야 한다.

> **스킬 설계로 번역하면**: `context: fork`는 **기본값이 아니라 소수 스킬의 선택**이어야 한다. 판단 기준 셋 — 독립적인가 / 새 컨텍스트를 정당화할 만큼 큰가 / 병렬인가.

---

## 4. 계층 — 제안된 시스템 둘

§2.2가 보인 대로 **코퍼스에는 계층이 없다.** 대신 그 공백을 메우겠다고 나온 시스템이 둘 있다. **둘 다 성능 개선을 측정하지 않았으므로 설계 아이디어로만 읽는다.**

### 4.1 Skilldex — 3단계 스코프 + 적합성 점수

[Skilldex (arXiv 2604.16911)](https://ar5iv.labs.arxiv.org/html/2604.16911). 에이전트 스킬용 패키지 매니저·레지스트리.

| 기여 | 내용 |
|---|---|
| **계층 스코프** | **global / shared / project** 3단계. `shared`는 *"cross-project team conventions that should not pollute every project's scope"* — [§9.4](instruction-layers.md)가 실측한 `cmux-*` 20종의 타 프로젝트 오염 문제를 정확히 겨냥한다 |
| **local-first precedence** | *"lower scope always overrides higher scope for the same skill name"* — 프로젝트가 전역을 가린다 |
| **적합성 점수** | Anthropic 스킬 명세 대비 **0–100점**, 컴파일러식 라인 단위 진단. *"A skill whose description is too short to trigger reliably"* 를 잡는다 |
| **자기 한계 명시** | *"It is explicitly **not** a measure of functional quality: a syntactically perfect skill can be useless"* |

> **Claude Code의 실제 스코프는 user / project / plugin 3단계이고**, Skilldex의 `shared`에 정확히 대응하는 층이 없다. **[§9.4](instruction-layers.md)의 오염 문제에 대한 도구 쪽 답은 스코프가 아니라 §5.2의 listing override다.**

### 4.2 카테고리 라우터 — 지연 로딩 계층

[agent-skill-router](https://github.com/AnamKwon/agent-skill-router) — *"organizes large local skill libraries into **category routers** and loads **leaf skills on demand**."*

**스킬 안쪽의 progressive disclosure(description → SKILL.md → `references/`)를 스킬 *사이*로 한 층 올린 형태다.** 라우터 스킬만 라우팅 표면에 올리고, 잎 스킬은 라우터가 지목할 때 로드한다.

> **9 stars의 개인 저장소다.** 근거가 아니라 **패턴의 존재 증명**으로만 쓴다. 그리고 grid fin에는 이미 같은 형태가 있다 — **`skill-registry`의 태그 기반 디스커버리**가 이 조사에서 쓴 `adapter-deep-research` → `[search-adapter]` 조회 경로 그 자체다.

### 4.3 네임스페이스는 표준에 없다

[agentskills/agentskills #312](https://github.com/agentskills/agentskills/issues/312): *"The spec defines skill names as **flat strings** — lowercase, hyphens, max 64 characters. There is **no namespace, scope, or collision-prevention mechanism**."*

**표준이 평면이므로 계층은 전부 도구·규약 층에서 만들어진다.** Claude Code는 두 가지로 대응한다 — 플러그인 네임스페이스(`/plugin:skill`)와 **중첩 디렉터리 충돌 시 경로 접두**(§5.1).

---

## 5. 선행 조사의 열린 질문 둘이 닫힌다

### 5.1 §7-5 — 중첩 스킬은 노출된다

[지시 계층 §7-5](instruction-layers.md)가 *"`learned/` 중첩 스킬이 목록에 노출되는가. 노출된다면 학습이 쌓일수록 라우팅 표면이 자동 증가한다"* 고 물었다.

공식 커맨드 이름 표가 답한다:

> `apps/web/.claude/skills/deploy/SKILL.md` → **`/apps/web:deploy`** (*"Nested `.claude/skills/` directory, **when the name clashes with another skill**"* → 경로 접두)

그리고 프로젝트 스킬 로딩 규칙:

> *"Project skills load from `.claude/skills/` in the directory where you start Claude Code **and in every parent directory up to the repository root**."*

**노출된다. 그리고 충돌 시 자동 네임스페이스가 붙는다.** §7-5의 우려는 확인됐다 — **학습 산출물이 쌓이면 라우팅 표면이 자동 증가한다.** 다만 §5.2가 그 상한 장치를 준다.

### 5.2 §7-4 — 라우팅 표면 총합 제어 장치가 있다

[§7-4](instruction-layers.md)가 *"개별 description에 1,536자 상한이 있으나 총합 제어 장치가 없다"* 고 적었다. **바이너리에서 그 장치를 찾았다** — settings의 스킬별 listing override:

> *"Per-skill listing overrides keyed by skill name. **`name-only`** lists the skill without its description; **`user-invocable-only`** hides it from the model but keeps `/name`; **`off`** hides it from both. Absent = on."*

**세 단계가 곧 라우팅 비용의 세 단계다.**

| 값 | 라우팅 표면 비용 | 남는 것 |
|---|---|---|
| (기본) | 이름 + description(≤1,536자) | 자동 발동 + `/name` |
| `name-only` | **이름만** | 자동 발동 약화 + `/name` |
| `user-invocable-only` | **0** | `/name` 만 |
| `off` | **0** | 없음 |

그리고 별도로 번들 스킬 전체를 끄는 스위치가 있다 — *"Disable the skills and workflows that ship with Claude Code … Equivalent to `CLAUDE_CODE_DISABLE_BUNDLED_SKILLS=1`."*

> **"커맨드 없이 스킬만" 구성에 이것이 직접 걸린다.** 예전 커맨드에 해당하는 스킬(사용자가 타이핑해서만 쓰는 것)은 **`user-invocable-only`로 라우팅 표면에서 완전히 빼면서 `/name`은 유지**할 수 있다. **즉 커맨드의 "모델에게 안 보임" 성질을 스킬에서 재현하는 경로가 두 개다** — frontmatter `disable-model-invocation`(모델 호출 차단, 단 목록에는 남음)과 settings `user-invocable-only`(목록에서도 제거). **전자는 스킬 작성자가, 후자는 저장소 소유자가 통제한다.**

> ⚠️ **이름이 거의 같고 효과가 반대인 쌍이 있다. 설계 시 가장 헷갈릴 지점이다.**
>
> | 설정 | 위치 | 숨기는 대상 | 남는 경로 |
> |---|---|---|---|
> | **`user-invocable: false`** | 스킬 frontmatter | **사용자** (`/` 메뉴에서 제거) | **모델 자동 호출** |
> | **`user-invocable-only`** | settings listing override | **모델** | **사용자 `/name`** |
>
> **`user-invocable`이 `false`면 사용자가 못 쓰고, `user-invocable-only`면 사용자만 쓴다.** 위 권고(예전 커맨드 → `user-invocable-only`)를 따르면서 frontmatter 쪽을 함께 켜면 **정확히 반대 결과**가 나온다.

### 5.3 공식 상한과 스코프 장치

| 항목 | 규격 |
|---|---|
| SKILL.md 본문 | *"Keep SKILL.md body **under 500 lines** for optimal performance"* ([Best practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices)) |
| description | 1,536자 캡, **`when_to_use`가 여기 포함된다** |
| description 문체 | *"**Always write in third person**. The description is injected into the system prompt, and inconsistent point-of-view can cause discovery problems"* |
| 이름 규약 | *"Consider using **gerund form** (verb + -ing) for Skill names"* |
| 선택 압력 | *"Claude uses it to choose the right Skill from potentially **100+ available Skills**"* |
| 경로 스코프 | `paths` glob — *"Claude loads the skill automatically only when working with files matching the patterns"* |

> **`paths`가 §2.1의 "4개 이상에서 급락"에 대한 도구 쪽 완화책일 *가능성*이 있다** — 동시에 후보로 오르는 스킬 수를 파일 경로로 줄이기 때문이다. **그러나 이것은 추론이다**: SkillsBench의 변수는 **하네스가 과제에 제공한 스킬 수**이고 `paths`가 줄이는 것은 **자동 활성화 후보 수**다. 두 양이 같다는 근거는 없다(§6-1과 같은 종류의 미해결). 그리고 `paths`는 **자동 활성화만 제한하고 `/name` 호출은 막지 않는다.**

---

## 6. 이 조사가 답하지 않은 것

1. **§2.1의 "2–3개"가 라이브러리 크기에 전이되는가.** 측정된 것은 **과제당 제공 수**다. 저장소에 50개를 두고 매 과제 2–3개만 발동하는 구성이 최적인지, 아니면 총량도 문제인지 **이 자료로는 못 가른다.** [§9.1](instruction-layers.md)의 라우팅 표면 8.3k는 총량 쪽 비용이다.
2. **스킬 활성화 정확도 측정법.** [아젠다 §6-1](research-agenda.md)이 *"신뢰 가능한 자료를 찾지 못했다"* 로 닫은 항목이 **커맨드 없는 구성에서 유일한 디스패치 기제가 된다.** 이번 검색에서도 벤치마크(SkillsBench는 *효과*를 재지 *선택 정확도*를 재지 않는다)와 블로그·유튜브뿐이었다. **여전히 미해결이며, 이번에는 더 아프다.**
3. **`context: fork` 스킬의 실제 비용·효과.** 공식 규격은 있으나 측정 자료를 찾지 못했다. §3.4의 위임 판단 기준은 전부 진술이지 측정이 아니다.
4. **카테고리 라우터(§4.2)가 성능을 개선하는가.** 라우터 스킬 자체가 라우팅 표면과 한 번의 왕복을 추가한다. **순이득인지 미측정.**
5. **`user-invocable-only`가 실제로 라우팅 표면에서 토큰을 빼는가**(§5.2). 문자열은 *"hides it from the model"* 이라고 하나 **`/context all`로 실측하지 않았다.** 확인 경로가 있다(B 부류, 1회 실행).
6. **Anatomy 논문의 smell과 실제 성능의 관계**(§2.3). 아무도 재지 않았다.
7. **`shared` 스코프의 부재를 무엇으로 대신하는가**(§4.1). Claude Code에 대응 층이 없다.
8. **접두어 규약의 근거.** `wf-`/`flow-`/`adapter-` 같은 실무 관행의 효과를 재는 자료를 찾지 못했다. §2.2의 taxonomy에도 이름 규약 항목이 없다.
9. **`.claude/rules/`와 "모델 전용 스킬"의 경계가 없다. — 커맨드를 버린 구성에서 즉시 부딪히는 질문이다.**

   [선행 조사 A](context-file-content.md)가 확인한 대로 신규 `/init`은 관심사가 여럿이면 **`.claude/rules/` + `paths` frontmatter**로 쪼개라고 한다. 그런데 이 조사가 확인한 대로 **스킬도 `paths`를 받고**, `user-invocable: false`면 **모델 전용**이 된다. **즉 "경로로 스코프되고 사용자 진입점이 없는 모델 전용 지시"를 담는 그릇이 둘이고, 어느 것을 쓸지 말하는 자료가 없다.**

   | | `.claude/rules/*.md` | 스킬 (`user-invocable: false` + `paths`) |
   |---|---|---|
   | 경로 스코프 | ✅ `paths` frontmatter | ✅ `paths` frontmatter |
   | 사용자 진입점 | 없음 | 없음 |
   | **로드 시점 (가설)** | 경로 일치 시 **본문이** 로드 | **description 먼저**, 본문은 호출 시 |

   **로드 시점이 판별자일 가능성이 높으나 확인하지 않았다.** 확인 경로: `/context all`에서 `.claude/rules/*.md` 본문이 **Memory files**에 잡히는지, `paths` 스킬이 **Skills**에 잡히는지 대조([§9.1](instruction-layers.md)과 같은 B 부류 측정). **이것이 갈리면 "상시 로드 vs 온디맨드"라는 이 시리즈의 중심 축이 그대로 적용되고, 안 갈리면 둘 중 하나가 중복이다.**

---

## Sources

**1차(벤더) — 공식 문서**
1. [Claude Code — Skills](https://code.claude.com/docs/en/skills) — frontmatter 전체 규격, 내용 유형 둘, 호출/실행 축, 커맨드 이름 표, 스킬 생애주기
2. [Claude Code — Subagents](https://code.claude.com/docs/en/subagents) — `skills:` 프리로드, 격리 규칙, 스킬↔에이전트 역관계
3. [Skill authoring best practices — Claude Platform Docs](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices) — 500줄, 3인칭, gerund 명명, 100+ 선택 압력
4. [Agent Skills overview — Claude Platform Docs](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview) — progressive disclosure 3단계
5. [Equipping agents for the real world with Agent Skills — Anthropic Engineering](https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills)
6. [anthropics/claude-code — plugin-dev/skills/skill-development/SKILL.md](https://github.com/anthropics/claude-code/blob/b7339920b69f4a395c28727a1e2305dc5b122cb2/plugins/plugin-dev/skills/skill-development/SKILL.md) — Anthropic 자체 스킬 작성 스킬

**측정 — arXiv 프리프린트 (전부 2026, 피어리뷰 전)**
7. [SkillsBench: Benchmarking How Well Agent Skills Work Across Diverse Tasks (2602.12670)](https://arxiv.org/html/2602.12670v1) — 84과제·7,308 trajectory. 개수·분량·모델 규모 효과
8. [From Anatomy to Smells: An Empirical Study of SKILL.md (2607.01456v2)](https://arxiv.org/html/2607.01456v2) — 238개 실측 taxonomy 13/44, smell 26종
9. [Skilldex: A Package Manager and Registry … Hierarchical Scope-Based Distribution (2604.16911)](https://ar5iv.labs.arxiv.org/html/2604.16911) — 3단계 스코프, 적합성 점수
10. [SkillCorpus: Consolidating and Evaluating the Open Skill Ecosystem (2607.15557)](https://arxiv.org/html/2607.15557) — **초록만 확인**
11. [How Well Do Agentic Skills Work in the Wild (2604.04323)](https://doi.org/10.48550/arxiv.2604.04323) — **미확인, 후속 대상**
12. [Context Matters: Repository-Aware Security Analysis of the Agent Skill Ecosystem (2603.16572)](https://arxiv.org/html/2603.16572) / [Malicious Agent Skills in the Wild (2602.06547)](https://arxiv.org/html/2602.06547v1) — **보안축, 미확인.** [보안 조사](security.md)의 후속 대상

**규약·구현 (근거 아님, 패턴 참고)**
13. [agentskills/agentskills #312 — 네임스페이스 RFC](https://github.com/agentskills/agentskills/issues/312) — 표준에 네임스페이스 없음
14. [agent-skill-router](https://github.com/AnamKwon/agent-skill-router) — 카테고리 라우터 + 지연 로딩
15. [openai/skills — skill-creator](https://github.com/openai/skills/blob/b0401f07/skills/.system/skill-creator/SKILL.md) — 교차 벤더 비교용
16. [LangChain deepagents — Skills](https://docs.langchain.com/oss/python/deepagents/skills) — 타 프레임워크의 같은 개념

---

## Methodology

**검색**: exa `/search` 5회(auto, numResults 8), firecrawl `/v1/search` 1회. 하위 질문 5개 — 스킬 작성 규범 / 스킬 vs 커맨드 / 서브에이전트×스킬 / 코퍼스 실증 연구 / 대규모 스킬 조직화·명명.
**정독**: exa `/contents` 1회 배치로 7개 문서 전문 취득(합계 약 409 KB), 절 단위 추출.
**병행 1차(도구)**: Claude Code 2.1.220 바이너리 `strings -n 3` — skill frontmatter 필드 집합, listing override 설정 설명, coordinator 모드 제약, 위임 판단 문장.

> **어댑터 스킬의 서브에이전트 지침을 따르지 않았다.** `adapter-deep-research`는 하위 질문 4개 이상이면 서브에이전트 병렬 실행을 지시하나, 이 세션에는 *"Do not call the AgentTool unless the user requested it"* 라는 상위 제약이 있다. 사용자가 요청한 것은 **어댑터 스킬**이지 서브에이전트가 아니므로 **메인 세션에서 순차 실행했다.** 결과 품질에 영향은 없다(검색 API 호출 수가 같다).

**한계**

- **핵심 측정 자료 3편이 전부 2026 프리프린트다.** 피어리뷰 전이며, [이 시리즈가 두 번 확인한](research-agenda.md) *판본 간 주장 강도 변화* 위험이 그대로 있다. 판본을 명기했다(2607.01456**v2**, 2602.12670**v1**).
- **Anatomy 논문의 smell 축은 블로그 29건 MLR 기반이다**(§2.3). taxonomy 축과 등급이 다르며, 섞어 쓰지 않았다.
- **SkillsBench의 `Comprehensive` 셀은 N=140**으로 얇다. −2.9pp를 단독 근거로 쓰지 않았다.
- **`context: fork`의 효과를 재는 자료가 없다**(§6-3). §3.4의 위임 기준은 전부 진술이다.
- **SkillCorpus는 초록만, 보안 논문 2편과 "in the Wild" 1편은 미확인이다.** 후자 셋은 이 조사의 범위(타입·계층) 밖이나 [보안 조사](security.md)의 후속 대상이다.
- **`user-invocable-only`의 토큰 절감 효과를 `/context all`로 실측하지 않았다**(§6-5).
- **grid fin에는 아직 스킬이 6종뿐이다**(adapter 3, registry, meta-skill-creator, wf-brainstorming). 이 조사의 실측 대상은 전부 외부 코퍼스와 도구 규격이다.
