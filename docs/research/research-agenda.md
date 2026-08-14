# 하네스 조사 아젠다 — 무엇을 더 조사해야 하는가

**최초 작성**: 2026-08-02
**최종 수정**: 2026-08-02
**대상 프로젝트**: grid fin (신규 개인용 개발 하네스, Claude Code + Codex 기반)
**조사 도구**: WebSearch 6회, WebFetch 4회
**성격**: 토픽 탐색. 각 항목은 조사 질문까지만 담고 설계·선택은 하지 않는다.

선행 문서
- [error-recurrence-prevention.md](error-recurrence-prevention.md) — 오류 검출·학습·원본 반영
- [harness-distribution.md](harness-distribution.md) — 배포 메커니즘

**진행 현황과 파생 문서 목록은 [§12](#12-진행-현황)에 있다.** 진행 상태를 적는 곳은 그곳 한 곳뿐이다.

---

## 0. 이 문서의 요지

2026년 들어 "하네스 엔지니어링"이 하나의 분야로 정리되면서, 산재한 실무 글보다 **분류 체계를 제시하는 자료**가 먼저 참조할 만한 상태가 됐다. 아래 세 가지가 서로 다른 축으로 같은 영역을 덮는다.

| 출처 | 축 | 쓸모 |
|---|---|---|
| [awesome-harness-engineering](https://github.com/ai-boost/awesome-harness-engineering) | 13개 Design Primitive | 토픽 인덱스 — 빠진 영역 점검용 |
| [Martin Fowler, Harness engineering for coding agent users](https://martinfowler.com/articles/harness-engineering.html) | 가이드(피드포워드) / 센서(피드백), 검증 3범주 | 개념 축 — 각 토픽이 무엇을 하는 것인지 가름 |
| [Learn Harness Engineering (13강)](https://walkinglabs.github.io/learn-harness-engineering/en/) | "왜 실패하는가" 문제 중심 | 조사 질문을 유도하는 형태 |

Fowler의 축이 특히 유용하다. 하네스를 **행동 전에 조종하는 가이드**와 **행동 후 관찰하는 센서**로 가르고, 검증을 다음 셋으로 나눈 뒤 마지막이 가장 미해결이라고 지목한다.

| 검증 범주 | 상태 |
|---|---|
| 유지보수성 (중복·복잡도·커버리지) | 가장 발전 |
| 아키텍처 적합성 (피트니스 함수) | 중간 |
| **행동 (기능이 실제로 동작하는가)** | **미해결** |

또 하나의 구분이 반복 등장한다 — **계산적(computational) 검증**(린터·타입체커, 빠르고 신뢰 가능) vs **추론적(inferential) 검증**(AI 리뷰, 느리고 비용 높음). 어떤 검사를 어느 쪽에 둘지가 반복되는 설계 질문이다.

`awesome-harness-engineering`의 13개 프리미티브 대비 이 문서의 커버리지:

> **정정 성격의 후속 (2026-08-03, [비코딩 작업 조사 §1](non-coding-work.md)).** 아래 표는 커버리지를 재는 데는 유효하나, **이 프레임워크에는 작업 종류 축이 아예 없다** — 13개가 전부 **하네스를 만드는 기제**이고, 하네스가 *감독하는 작업*(배포·설정·마이그레이션·인시던트 대응)으로 분류하는 절이 하나도 없다(원문 확인). **따라서 이 표의 빈 칸을 다 채워도 "코딩 외의 작업을 어떻게 다루는가"는 답이 나오지 않는다.** 그 축은 인접 문헌(ExITBench·DevOps-Gym·InfraBench)에서 조립해야 한다.

| 프리미티브 | 이 문서 | 비고 |
|---|---|---|
| Agent Loop | — | grid fin이 루프 자체를 만들지는 않음 |
| Planning & Task Decomposition | §10 | |
| Context Delivery & Compaction | §1 | |
| Tool Design | — | MCP 도입 시점에 필요 |
| Skills & MCP | §8 (보안 측면), §6 (평가 측면) | |
| Permissions & Authorization | §2 | |
| Memory & State | §9, **선행 조사 완료** | |
| Task Runners & Orchestration | §5 | |
| Verification & CI | §3, §4 | |
| Observability & Tracing | §7 | |
| Debugging & DX | — | 후순위 |
| Human-in-the-Loop | §2 (승인 게이트), §5 (계획 승인) | |
| Security & Sandbox | §2, §8 | |

---

## 1. 지시 계층과 컨텍스트 전달

**왜 필요한가** — 배포 조사 §6.3에서 열어둔 채 끝난 유일한 항목이다. 상시 로드 파일의 크기·구성이 다른 결정들의 입력이 된다.

**조사 질문**

1. 상시 로드와 온디맨드의 경계를 무엇으로 가르는가. "코드를 읽어도 알 수 없는 것"이라는 기준이 실제로 판별 가능한가
2. 파일 크기 임계의 실측 근거는 얼마나 단단한가 — 실무 보고는 "50줄 이상적, 150~200줄부터 성능 저하"라 하고, ETH Zurich 연구는 자동 생성 컨텍스트가 성공률을 낮춘다고 한다. 어느 쪽도 1차 확인을 하지 않았다
3. 포인터 설계(깨진 링크가 404처럼 드러나는 구조)가 `@import` 체계와 어떻게 맞물리는가
4. 컨텍스트 압축 / 세션 핸드오프 / 구조화된 eviction 셋의 트레이드오프
5. **압축이 하네스 규칙을 지우는 문제** — 압축 후에도 안전 제약이 살아남는지

**참고**
- [Context Compaction vs. Agent Handover](https://raggiecode.com/blog/context-compaction-vs-handover)
- [Beyond Compaction: Structured Context Eviction (arXiv 2606.11213)](https://arxiv.org/pdf/2606.11213)
- [Governance Decay: How Context Compaction Silently Erases Safety Constraints (arXiv 2606.22528)](https://arxiv.org/pdf/2606.22528)
- [Self-Compacting Language Model Agents (arXiv 2606.23525)](https://arxiv.org/pdf/2606.23525)
- 강의 4 "Why One Giant Instruction File Fails", 강의 5 "Why Long-Running Tasks Lose Continuity"

**기존 조사와의 관계** — 배포 조사 §6.3, 선행 조사 권고 #6(상시 로드 계층 줄 수 예산)이 같은 지점을 가리킨다.

---

## 2. 강제 메커니즘 — 훅·권한·샌드박스

**왜 필요한가** — Fowler의 "가이드" 축에 해당하며, 여러 자료가 공통으로 *"프롬프트로 부탁하지 말고 메커니즘으로 강제하라"*를 안티패턴 1번의 반대편에 둔다.

**조사 질문**

1. 훅 4유형의 실제 적용 범위 — Safety Gate(PreToolUse) / Quality Loop(PostToolUse) / Completion Gate(Stop) / Observability
2. **훅 성능 예산** — PostToolUse는 500ms 이하 권고가 반복 등장한다. 이 제약이 린터 선택을 규정하는가 (Oxlint·Biome·Ruff가 ESLint+Prettier보다 적합하다는 보고의 근거)
3. Codex의 `sandbox_mode` × `approval_policy` 조합과 프로파일 체계. Claude Code의 permissions와 개념이 어떻게 대응되는가
4. 조직 강제(`requirements.toml`)가 개인 하네스에 의미가 있는가
5. **에이전트가 린터 설정을 고쳐 규칙을 우회하는 것을 막는 법** — 여러 글이 공통 지적하나 구체적 방법은 제각각

**참고**
- [Codex Configuration Reference](https://developers.openai.com/codex/config-reference)
- [Harness Engineering Best Practices for Claude Code / Codex Users](https://nyosegawa.com/en/posts/harness-engineering-best-practices-2026/)
- [Codex CLI Deep Dive: Config, Profiles, Sandbox](https://www.digitalapplied.com/blog/codex-cli-deep-dive-config-profiles-sandbox-2026)

---

## 3. 검증 계층

**왜 필요한가** — Fowler가 **행동 하네스를 미해결로 지목**했다. 그리고 이 축이 없으면 "구현이 끝났다"는 판정이 에이전트의 자기 신고에 의존한다.

**조사 질문**

1. 행동 검증을 어떻게 자동화하는가 — 현재 실무는 "AI 생성 테스트 + 수동 테스트"에 의존한다는 것이 Fowler의 진단
2. 프로젝트 유형별 E2E 도구 선택. **토큰 비용 차이가 크다** — 웹의 경우 Playwright MCP 114K vs Playwright CLI 27K vs agent-browser 5.5K라는 보고
3. 완료 게이트 설계 — 에이전트가 조기에 승리 선언하는 문제
4. **센서 유효성 문제** — "센서가 한 번도 안 울리면 품질이 높은 것인가 검출이 부실한 것인가". 하네스 감사 지표의 근본 질문
5. 계산적 검증과 추론적 검증의 배치 — 어느 것을 커밋 전에, 어느 것을 파이프라인 뒤에

**참고**
- [Martin Fowler — Harness engineering](https://martinfowler.com/articles/harness-engineering.html)
- 강의 9 "Why Agents Declare Victory Too Early", 강의 10 "Why End-to-End Testing Changes Results"
- [Evaluate Coding Agents (Promptfoo)](https://www.promptfoo.dev/docs/guides/evaluate-coding-agents/)

**기존 조사와의 관계** — 선행 조사가 리뷰 산출물을 학습 입력으로 삼기로 했으므로, 검증 구조 자체의 품질이 학습 품질의 상한이 된다.

---

## 4. 다중 모델 교차 리뷰

**왜 필요한가** — 기존 하네스가 이미 Claude 작성 → Codex 리뷰 구조를 쓰고 있고, 선행 조사 §7의 귀속 판정((A)~(D))이 전부 이 구조 위에 서 있다. 구조 자체를 조사한 적은 없다.

**조사 질문**

1. **역할 비대칭** — "Claude 작성 → Codex 리뷰"와 그 반대는 같은 두 모델을 쓰지만 다른 워크플로우라는 관측. 어느 방향이 어떤 오류에 강한가
2. 적대적 디베이트 루프(양쪽이 서로의 지적을 반박하는 다중 라운드)가 단일 리뷰보다 나은가, 비용은 얼마인가
3. 리뷰어에게 read-only 샌드박스를 주는 것의 효과 — 선행 조사 §7.4의 (C) 유형(미병합 PR을 리뷰어가 "없음"으로 판정)이 이 설정과 관련 있다
4. "두 번째 리뷰어는 첫 번째가 놓친 것을 찾아라"식 프라이밍의 효과

**참고**
- [Cross-Model LLM Code Review (arXiv 2607.21656)](https://arxiv.org/html/2607.21656v1)
- [adversarial-review — Claude + Codex 적대적 디베이트 루프](https://github.com/alecnielsen/adversarial-review)
- [Adversarial Code Review: Why the Maker Shouldn't Grade the Checker](https://www.augmentcode.com/guides/adversarial-code-review)
- [Cross-Vendor AI Agent Review](https://www.mindstudio.ai/blog/cross-vendor-ai-agent-review-claude-codex)

---

## 5. 에이전트 조율

**조사 질문**

1. 서브에이전트 위임 경계 — "breadth는 fork, depth는 inline"이라는 판단 기준의 근거
2. 중첩 서브에이전트(2026 기준 5단계까지 가능)가 실익이 있는 지점

> **정정 (2026-08-02, [에이전트 조율 조사 §3.3·§3.2](agent-orchestration.md)).**
> **2번의 "5단계"가 틀렸다.** 공식 문서는 *"up to **three layers** below the main conversation"* 이고 `CLAUDE_CODE_MAX_SUBAGENT_SPAWN_DEPTH`(v2.1.217+)로 조절한다(`1`이면 중첩 해제).
> **1번의 축도 공식 기준과 다르다.** 규격이 가르는 것은 breadth/depth가 아니라 **출력의 폐기 가능성·컨텍스트 공유 여부·지연**이다. 그리고 `fork`는 서브에이전트 생성과 별개의 세 번째 기제로, 시스템 프롬프트·도구가 부모와 동일해 **부모의 프롬프트 캐시를 재사용**한다.
3. 오케스트레이터가 환경을 직접 만지지 않고 **압축된 요약만 받는** 패턴 — 컨텍스트 증가를 억제하는 효과와 정보 손실의 트레이드오프
4. 계획·실행 분리와 인간 승인 게이트의 배치
5. 범위 초과(overreach)와 미완(under-finish)의 동시 발생 — 강의 7이 한 묶음으로 다루는 이유

**참고**
- [Building AI Coding Agents for the Terminal (arXiv 2603.05344)](https://arxiv.org/html/2603.05344v1)
- [Agent Architecture: Building AI-Powered Development Harnesses](https://blakecrosley.com/guides/agent-architecture)
- 강의 7 "Why Agents Overreach and Under-Finish"

---

## 6. 평가(eval)

**왜 필요한가** — 하네스 변경의 효과를 재는 방법이 없으면 개선이 취향이 된다. [탐색적 연구](https://arxiv.org/abs/2602.14690)가 이 영역의 공백을 지적했다.

> **정정 (2026-08-02, [평가 조사 §4.1](evaluation.md)).** 여기에 원래 *"미해결 영역으로 '하네스 엔지니어링 효과를 정량화하는 방법 미개발'을 지목했다"* 고 적혀 있었다. **본문 확인 결과 논문이 말하는 것은 "방법 미개발"이 아니라 "증거 부족"이다** — *"there is little empirical evidence on which configuration strategies are most effective."* 방법으로는 **통제된 연구**를 이름 대어 권한다. 차이가 실질적이다: 방법이 없다면 발명해야 하고, 증거가 없다면 부족한 것은 표본이다.

**조사 질문**

1. **스킬 활성화 측정** — 스킬이 의도한 상황에서 실제로 발동하는지를 샌드박스 eval로 재는 방법
2. 회귀 스위트 구성 — 코드 기반 grader(파일 패턴·테스트·빌드) vs 모델 기반 grader의 역할 분담
3. pass@k와 베이스라인 체크포인팅(SHA)으로 모델 버전 변경의 영향을 분리하는 법
4. 단일 테스트 케이스에 스킬이 과적합되는 것을 막는 다중 config 방식
5. 하네스 변경 자체의 A/B — 개인 규모에서 표본이 모이는가

**참고**
- [Measuring Claude Code Skill Activation With Sandboxed Evals](https://scottspence.com/posts/measuring-claude-code-skill-activation-with-sandboxed-evals)
- [Testing and Refining Claude Code Skills with MLflow](https://mlflow.org/blog/evaluating-skills-mlflow/)
- ~~[SkillGenBench (arXiv 2605.18693)](https://arxiv.org/abs/2605.18693)~~ — **§6-1의 근거가 아니다.** 정식 제목이 *"Benchmarking Skill **Generation** Pipelines"* 이고 스킬을 **만들어 내는** 능력을 잰다. 활성화(triggering) 측정은 대상이 아니다 ([평가 조사 §5.3](evaluation.md))
- [What is an Eval Harness (DeepEval)](https://deepeval.com/blog/what-is-an-eval-harness)

**§6-1에 관한 결론** — 평가 조사가 벤더 공식 문서까지 확인했으나 **활성화 측정법을 주는 신뢰 가능한 자료를 찾지 못했다.** Anthropic 공식 문서는 기제(`name`·`description` → progressive disclosure)만 설명하고 *"Monitor how Claude uses your skill in real scenarios"* 로 끝난다. 남은 참고 둘은 개인·벤더 블로그다.

**착수 시점 주의** — 하네스 형태가 어느 정도 정해진 뒤라야 측정 대상이 생긴다. 조사 가치는 높으나 선행 의존이 있다.

---

## 7. 관찰성

**조사 질문**

1. Claude Code와 Codex 양쪽의 내장 OpenTelemetry 지원 범위와 차이
2. `gen_ai.*` 시맨틱 컨벤션으로 세션별 토큰·비용을 귀속시키는 방법
3. 병렬 세션 fleet 관찰 — 루프에 빠진 에이전트를 예산 소진 전에 잡는 stall 감지
4. **관찰성을 하네스 안에 두는 것과 밖에 두는 것의 차이** (강의 11)
5. 선행 조사가 지적한 문제 — `session-logger`로 기록은 이미 하고 있으나 **그것을 읽는 단계가 파이프라인에 없다.** 기록과 소비를 어떻게 잇는가

**참고**
- [Claude Code + OpenTelemetry: Per-Session Cost and Token Tracking](https://bindplane.com/blog/claude-code-opentelemetry-per-session-cost-and-token-tracking)
- [Codex CLI OpenTelemetry](https://codex.danielvaughan.com/2026/03/28/codex-cli-opentelemetry-observability/)
- [Fleet observability for parallel Claude Code](https://ocdevel.com/podcaster/claude-code/d771f3f4-600c-4dca-856f-78e695659d0d)

---

## 8. 보안

**왜 필요한가** — 하네스는 남의 컴포넌트(스킬·플러그인·MCP 서버)를 들여오는 구조다. 배포 조사에서 검토한 마켓플레이스·스토어 방식 전부가 이 문제를 안고 있다.

**조사 질문**

1. 프롬프트 인젝션이 여전히 agentic 실패의 최대 원인이라는 OWASP 보고의 구체 내용
2. MCP 도구 오염(tool poisoning) — 사용자에게 안 보이는 도구 메타데이터에 지시를 숨기는 공격
3. 스킬 인젝션 — 스킬 파일 자체가 공격 매개가 되는 경우
4. 공급망 — `postmark-mcp`는 **정상 버전 15개를 배포한 뒤 유출 코드 한 줄을 추가**했다. 버전 고정만으로는 못 막는 형태
5. **외부 컴포넌트 도입 시의 검증 절차** — 개인 하네스에서 현실적으로 가능한 수준은 어디까지인가
6. 선행 조사 §7.10.8이 남긴 문제 — 이슈 본문에 프로젝트 코드·경로가 실려 원본 저장소로 가는 정보 유출

**참고**
- [Prompt injection still drives most agentic AI security failures (OWASP)](https://www.helpnetsecurity.com/2026/06/11/owasp-prompt-injection-ai-security-failures/)
- [POISE: Position-Aware Undetectable Skill Injection (arXiv 2606.07943)](https://arxiv.org/pdf/2606.07943)
- [MCP Tool Poisoning](https://itecsonline.com/post/mcp-tool-poisoning-enterprise-ai-agent-security-2026)
- [New Prompt Injection Attack Vectors Through MCP Sampling (Unit 42)](https://unit42.paloaltonetworks.com/model-context-protocol-attack-vectors/)

---

## 9. 상태와 연속성

**조사 질문**

1. 세션 간 상태를 무엇에 담는가 — **진행 상태는 JSON이 Markdown보다 에이전트 오편집에 강하다**는 실무 보고의 근거
2. git 로그를 세션 간 신뢰 가능한 기록으로 쓰는 방식
3. **초기화를 독립 단계로 두는 이유** (강의 6) — 기존 하네스의 `/flow-init`이 이미 그 형태다
4. 매 세션이 깨끗한 상태를 남겨야 하는 이유와 그것을 강제하는 방법 (강의 12)
5. 체크포인트 기반 재개 — 크래시가 전체 재시작을 부르지 않게 하는 구조

**참고**
- [Long-Horizon Agent Goal Persistence](https://zylos.ai/research/2026-05-15-long-horizon-agent-goal-persistence/)
- 강의 6, 강의 12

**기존 조사와의 관계** — 선행 조사의 메모리·학습 축과 겹치나 다르다. 저쪽은 *무엇을 배우는가*, 이쪽은 *작업 상태를 어떻게 잇는가*.

---

## 10. 워크플로우 구조

**왜 필요한가** — grid fin의 다음 단계가 피쳐 목록 정의인데, **피쳐 목록을 하네스 프리미티브로 다루는 관점**이 이미 정리되어 있다(강의 8). 우선순위가 가장 높은 이유다.

**조사 질문**

1. 피쳐 목록이 하네스에서 무슨 역할을 하는가 — 산출물인가 통제 장치인가
2. 기존 spec-driven 구현체 비교 — Spec Kit / Spec Kit Agents / spec_driven_develop이 각각 어느 단계를 강제하는가
3. **Spec Kit Agents의 phase-level context-grounding hook** — 각 단계(Specify·Plan·Tasks·Implement)를 저장소 증거에 접지시키는 read-only 프로빙. 선행 조사의 "예방적 조회" 요구와 겹친다
4. 태스크 분해 단위 — 리뷰 가능한 크기의 기준
5. 좋은 스펙의 조건

**참고**
- [Spec Kit Agents (arXiv 2604.05278)](https://arxiv.org/pdf/2604.05278)
- [Spec-driven development with AI (GitHub Blog)](https://github.blog/ai-and-ml/generative-ai/spec-driven-development-with-ai-get-started-with-a-new-open-source-toolkit/)
- [spec_driven_develop](https://github.com/zhu1090093659/spec_driven_develop)
- [How to write a good spec for AI agents (Addy Osmani)](https://addyosmani.com/blog/good-spec/)
- 강의 8 "Why Feature Lists Are Harness Primitives"

---

## 11. 저장소 위생

**조사 질문**

1. "테스트는 문서보다 부패에 강하다" — 설명 문서를 테스트·ADR로 대체하는 실천의 실제 범위
2. ADR을 에이전트가 소비 가능한 형태로 두는 방법
3. **저장소가 기록 원천(system of record)이어야 하는 이유** (강의 3) — 배포 조사 §1.2의 "gitignore로 추적 파일 0건"이 정확히 이 원칙의 위반이었다
4. 커스텀 린트 규칙으로 "grep 가능성·구조 예측성·아키텍처 경계"를 강제하는 방식

> **정정 (2026-08-02, [저장소 위생 조사 §4](repository-hygiene.md)).** 위 3번의 *"정확히 이 원칙의 위반이었다"* 는 **배포 조사가 한 말이 아니라 이 아젠다가 붙인 해석이다.** 배포 §1.2가 실제로 측정한 것은 규범 위반이 아니라 **메커니즘 고장**이다 — 추적되지 않는 핀은 버전 식별을 못 하고, `copier update`의 3-way merge가 git 기계에 의존하므로 무력화되어 로컬 수정이 경고 없이 소실된다(실증). 같은 사실을 가리키나 논거가 다르고, **실증 쪽이 더 강하다.** "기록 원천" 원칙 자체의 1차 근거는 여전히 자가출판 강의 하나뿐이며 대체 자료를 찾지 못했다.
>
> **1번도 전제가 바뀐다.** 조사 결과 부패를 거치지 않고도 결론이 선다 — 저장소 개요형 문서는 **첫날부터** 성공률 개선 없이 비용만 20% 이상 늘린다. 부패는 두 번째 이유다.

**참고**
- [Harness Engineering Best Practices for Claude Code / Codex Users](https://nyosegawa.com/en/posts/harness-engineering-best-practices-2026/)
- 강의 3

---

## 12. 진행 현황

**선행 2건 + 우선순위 10건 — 전부 완료 (총 12건) · 아젠다 밖 파생 8건 · 후속 조사(사용자 요청) 6건** · 최종 갱신 2026-08-03

우선순위는 grid fin의 현재 상태(다음 단계는 피쳐 목록 정의) 기준으로 매겼다. 조사를 마치면 해당 항목을 **완료** 구획으로 옮기고 산출물 링크와 한 줄 요약을 붙인다.

### 완료 (12)

- [x] **선행 · 오류 검출·학습·원본 반영** — [error-recurrence-prevention.md](error-recurrence-prevention.md)
  - 리뷰 산출물 55건 1차 집계로 (A)~(D) 귀속 분류 도출. 권고 #1~#26 확정. 열린 질문 12건
- [x] **선행 · 배포 메커니즘** — [harness-distribution.md](harness-distribution.md)
  - Copier 3-way merge를 직접 실증(재현 스크립트 포함). 메커니즘 선택은 피쳐 목록 정의 이후로 보류. 미해결 9건
- [x] **1순위 · §10 워크플로우 구조 + 피쳐 목록** — [workflow-and-feature-list.md](workflow-and-feature-list.md)
  - 토픽 수준은 스크립트가 상태 전환을 막고 Story 수준은 막지 않는 비대칭을 식별. 열린 질문 10건
- [x] **2순위 · §1 지시 계층** — [instruction-layers.md](instruction-layers.md)
  - 상시 로드 1,044줄 / 라우팅 표면 10,185자 실측. 압축 생존 실험이 최우선 미해결. 열린 질문 10건

- [x] **3순위 · §3 검증 계층 + §4 다중 모델 교차 리뷰** — [verification-and-cross-review.md](verification-and-cross-review.md)
  - 신규 1차 데이터: 코드리뷰 산출물 21건(선행 조사 미분석). 훅 9개 중 게이트 0개, 지적 163건 중 78.5% 미조치. Google CACM 2018의 effective false positive 지표로 환산. 열린 질문 12건

- [x] **4순위 · §2 강제 메커니즘** — [enforcement-mechanisms.md](enforcement-mechanisms.md)
  - 공식 문서 3종 본문 확인. **차단 가능한 지점과 실제 배치가 역전**돼 있고(`PostToolUse`는 exit 2로도 차단 불가), `deny`·`ask`·`sandbox`가 전부 0건. "500ms 예산"은 플랫폼 규격이 아님(기본값 600초). 열린 질문 11건

- [x] **5순위 · §9 상태·연속성** — [state-and-continuity.md](state-and-continuity.md)
  - 상태 보유자 8종 중 추적되는 것 2종(워크트리를 쓰면 더 늘어남). **머지 커밋 21건 = 토픽 21개**로 git이 이미 토픽 단위 기록 원천이나 과정은 전부 비추적. `flow-checkpoint`는 기본값이 "log only"라 체크포인트가 아니라 마커이고, gitignore가 롤백 범위 밖이라 상태 발산이 확정적. 열린 질문 10건
  - **사용자 지적으로 §3.2 논증 철회** — `HANDOFF.md`를 지속 산출물로 오독했으나 병렬 워크트리 조율용 임시 노트였다

- [x] **6순위 · §8 보안** — [security.md](security.md)
  - **구현 참조 자료 4종 정리** — 설계 패턴 6종(각각 포기하는 효용 명시), OWASP ASI01–10과 ASI04 완화책 목록, SLSA L0–L3 채택 단계, POISE의 스캐닝 무력화 수치. 열린 질문 9건

- [x] **7순위 · §7 관찰성** — [observability.md](observability.md)
  - **구현 참조 자료 4종 정리** — Claude Code 공식 규격(메트릭 8·이벤트 15·스팬 6 전량), Codex 이슈 2건, OTel GenAI 규약(Development·릴리스 0건), ICML 2025 실패 귀속 논문
  - **관측 가능성이 비대칭이다** — `codex exec`는 메트릭을 방출하지 않는데(#33668, open·코멘트 0건) 하네스의 리뷰어 절반이 그 경로다. §4 교차 리뷰 구조에 직접 걸린다
  - **§7-2의 답은 부정형** — Claude Code는 `gen_ai.*`를 식별 필드 5개에만 쓰고 토큰·비용은 벤더 고유 이름이다. 게다가 그 5개 중 `gen_ai.system`은 **폐기된 이름**(→ `gen_ai.provider.name`)
  - 자동 실패 귀속의 상한이 **에이전트 53.5% / 단계 14.2%** — 추론적 소비를 먼저 놓을 근거가 약하다. 열린 질문 10건

- [x] **8순위 · §6 평가** — [evaluation.md](evaluation.md)
  - **구현 참조 자료 5종 정리** — Miller의 통계 요구(본문 공식 확인), LLM-판정자 편향 보정(**ICML 2026**, 이 시리즈 유일의 피어리뷰 자료), `pass@k` 추정량(공식 구현 코드), Galster et al. 실증 기준선(v5), Anthropic 공식 스킬 문서
  - **표본 바닥은 재려는 효과 크기에 달렸다** — `n ≈ 969`는 **3%p 차이(`δ=0.03`)** 기준이고 `n ∝ 1/δ²`이다(**2차 출처 감사에서 파라미터 확보 후 정정**). **그리고 효과 크기 조사(2026-08-03, §1.5)가 `δ`를 채웠다** — 하네스 전체 교체는 0.07~0.16(문항 40~200, **측정 가능**), 구성요소 하나 추가는 약 0.02(문항 약 2,000, **측정 불가**). **grid fin에서 실제로 할 변경은 대부분 후자다**
  - **모델 기반 grader는 무료가 아니다** — 사람 라벨 **약 200개**의 보정 부채. 코드 기반에는 없는 항목
  - 실측: eval이 스킬 **55종 중 2종**, grader **100% 코드 기반**, SHA 핀은 두 체계 병존, **100일 미실행**(재실행하면 4/4 통과). 열린 질문 11건
  - **아젠다 §6 참고문헌 2건 정정** — 아래 참조

- [x] **9순위 · §11 저장소 위생** — [repository-hygiene.md](repository-hygiene.md)
  - **구현 참조 자료 4종 정리** — AGENTS.md 실증 연구(본문 확인), MADR 4.0.0 명세, ADR 공식 도구 목록 전수, ArchUnit 공식 가이드
  - **§11-1의 전제가 바뀐다** — 설명 문서는 부패하기 전에 이미 손해다. 저장소 개요는 성공률 개선 없이 **비용 +20%**, 반면 지시는 따른다(`uv` 언급 시 인스턴스당 **1.6회 vs 0.01회 미만**). 저자 권고는 *"omitting LLM-generated context files … including only minimal requirements"*
  - **ADR은 형식만 표준이고 소비가 비어 있다** — MADR은 YAML front matter·연번으로 파싱 가능하나 공식 도구 20여 종 중 **기계 소비용 파서 0종**
  - `FreezingArchRule`(기존 위반 동결 후 신규만 차단)이 "게이트를 켜면 전부 실패한다" 문제의 형태를 준다
  - 실측: ADR **0건**, cygnus `docs/specs` 18개 2,553줄이 전부 **서술형**, 상시 로드 `harness-guide.md` 377줄 중 개요가 **약 26%**, 경계 강제 **0건**. 열린 질문 9건
  - **아젠다 §11-3의 규정 정정** — 아래 참조

- [x] **10순위 · §5 에이전트 조율** — [agent-orchestration.md](agent-orchestration.md)
  - **세 자료가 독립적으로 같은 방향을 가리킨다** — 벤더 실무(*"most coding tasks involve fewer truly parallelizable tasks than research"*), 피어리뷰 실증(다중 에이전트는 *"minimal performance gains"*, 실패율 **41~86.7%**, best-of-N과 대등), 저장소 실증(서브에이전트 채택 **4.6%**). **미착수 사유였던 "실익 판단이 어렵다"가 아니라 "이 영역에는 쓰지 말라"가 자료의 답이다**
  - **MAST(NeurIPS 2025 D&B) 실패 모드 14종** — 검증 범주 세 모드가 각각 6.2·8.2·9.1%로 고르게 높아 검증·교차리뷰의 실측과 같은 지점을 가리키고, 반복 수행 **15.7%**(범주 최다)와 종료 조건 미인지 **12.4%** 가 나란히 상위라는 점이 §5-5의 "범위 초과와 미완"이 왜 한 묶음인지 설명한다(같은 범주의 이웃). **다중 라벨이라 비율을 더할 수 없다**
  - **서브에이전트 ≠ 다중 에이전트 시스템** — 공식 규격상 목적이 조율이 아니라 **컨텍스트 격리**이고, 효용 목록에 병렬 성능이 없다. §5-3의 "압축된 요약만 받는 패턴"은 설계가 아니라 기본 동작
  - 실측: 정의 11종 전부 `tools` 명시(권한 경계가 서 있는 드문 층), **`Agent` 보유 0건 → 중첩 경로 자체가 없음**. 열린 질문 9건
  - **아젠다 §5-2 정정** — 아래 참조

### 아젠다 밖 파생 조사 (2026-08-03)

아래 8건은 §1~§11의 항목이 아니라 사용자 질문에서 파생된 축이다. 아젠다에 대응 항목이 없다.

- [x] **출처 감사 — 조사 시리즈의 신뢰도 검증** — [source-audit.md](source-audit.md)
  - **arXiv 인용 44편 전수 확인: 실재·제목 일치 44/44, 존재하지 않는 ID 0건. 초록까지 전수 대조**했고 문서에 **44편 각각의 요약·용도·대조 결과**를 실었다. 초록과 정합 확인 17편, 초록 밖이라 판정 보류 27편, **불일치 0건**
  - 비-arXiv 3건 실재 확인 — MNL(ACL 2026 Findings `2026.findings-acl.719`), CACM 2018(Sadowski, 61(4) pp.58–66, 인용문 축자 일치), MAST(NeurIPS 2025 D&B)
  - **본문 대조 2건.** MNL의 구성요소 5개를 논문 PDF에서 확인(GitHub README는 4개만 싣는 축약본). CodeCompass는 초록 99.4%와 조사 인용 99.5%가 **서로 다른 지표**였고 본문 표에서 *"1+ (tool used) 37 (42.0%) 99.5%"* 를 확인 — **조사 인용이 정확하다**
  - **확인된 오류 1건** — 2410.21819를 "피어리뷰(LLM)"로 표기했으나 실제는 NeurIPS 2024 **워크숍**. 정정함. 나머지 워크숍 2편은 실제보다 낮게 표기돼 있다
  - 자기 신고 35건 — 확인하지 못했다 17 · 인용 금지 7 · 본문 미확인 5 · 검증 실패 4 등
  - **출처 구성의 특성 셋** — ① 프리프린트 61건이며 결론에 큰 영향을 주는 자료(Harness-Bench·AGENTS.md·CodeCompass)가 여기 속하고 재현된 바 없다 ② 형식 규정 축(WIP=1·삼중 구조·상태 기계)은 단일 자가출판 출처에 의존한다 ③ 1차 실측 표본이 저장소 두 곳(cygnus·harness)이다
  - **범위 한계 명시** — 외부 URL 312개 중 약 15%만 접촉했고, arXiv 42편의 본문과 조사 문서 본문 15,395줄은 읽지 않았다. 남은 검증 단계와 비용을 §9에 표로 정리했다

- [x] **저장소 레이아웃** — [repository-layout.md](repository-layout.md)
- [x] **워크트리 공유 상태** — [worktree-shared-state.md](worktree-shared-state.md)
- [x] **워크플로우와 기술 스택의 분리** — [workflow-stack-separation.md](workflow-stack-separation.md)
  - **저장소 레이아웃 조사가 닫은 실행 층(이름 계약) 위층.** 이름이 통일돼도 TDD는 서지 않는다 — red 단계가 "돌아서 실패"와 "돌지 않음"을 갈라야 하는데 **종료 코드가 그 구분을 담지 못한다**
  - **실측(vitest × cargo-nextest, 조건 10개)**: 종료 코드는 정규화 안 됨(실패 1 vs **100**, 테스트 없음 1 vs **4**). **JUnit XML은 정규화됨** — 27줄 파서 하나가 두 런타임 6조건 전수 정답
  - **그러나 네 군데가 새고 전부 red를 겨냥한다** — (a) vitest 필터 불일치가 **exit 0**이고 `tests=1`이라 나이브 파서가 GREEN 오판(`executed = tests − skipped` 보정 후 10/10), (b) **컴파일 실패 시 nextest가 `junit.xml`을 갱신하지 않아 낡은 RED가 읽힌다 — TDD red의 정상 시작 상태가 곧 이 조건**, (c) **테스트 개별 식별자가 정규화되지 않는다**(`name="adds"` vs `"tests::adds"`), (d) 한 러너 안에서도 조건에 따라 `name` 의미가 바뀐다
  - **따라서 "결과 객체를 정규화한다"는 필요조건이지 충분조건이 아니다.** 공통인 것은 **실행 전체** 판정까지이고, TDD가 실제로 묻는 "방금 쓴 그 테스트가"는 **런타임당 어댑터를 다시 요구한다**
  - **기성 해법 4종 1차 확인** — Bazel `XML_OUTPUT_FILE`(러너가 XML을 대신 생성), Nx executor, pre-commit `language:`(20종 런타임), moon toolchain(**등급 상향: 마케팅 → 공식 개념 문서. 다만 버전 관리자이지 태스크 추상화가 아님**)
  - **이미 출하된 답** — SWE-bench Multilingual은 9개 언어에서 **언어별로 남긴 것이 도커 base 이미지·설치/테스트 명령·로그 파서 셋뿐**. 결과 정규화를 JUnit 요구가 아니라 **언어별 파서**로 풀었다
  - **하네스 층 비대칭** — AGENTS.md·CLAUDE.md는 중첩되는데 `settings.json`은 비상속. **"모듈이 각자 게이트를 선언한다"는 형태가 성립하지 않는다.** 열린 질문 8건
- [x] **"워크플로우 먼저 → 체인 목업 실증 → 함수 단위 TDD"의 근거** — [skeleton-first-then-tdd.md](skeleton-first-then-tdd.md) · **검색 어댑터(exa·firecrawl)로 수행**
  - **세 단계에 세 판정.** ① 워크플로우·체인 먼저 = **지지**(Walking Skeleton / Steel Thread / CodeSpec이 독립 도달) · ② **구성요소를 스텁으로 대체해 실증 = 자료가 반대**(**픽스처는 대상이 아니다 — 후속 1 참조**) · ③ 함수 단위 TDD = **지지하되 이유가 다름**
  - **②가 핵심 발견** — 같은 패턴의 정의가 스텁을 배제한다: *"a real end-to-end test with **no stubs**"*, *"not a prototype and not a proof of concept — **it's production code**"*. GOOS의 순서는 정반대로 **스켈레톤을 배포한 뒤에야** 첫 인수 테스트·TDD 사이클을 시작한다. 제안은 **구조적으로 Walking Skeleton인데 한 군데만 다르고, 그 한 군데가 문헌이 경고하는 지점이다**
  - **③의 근거 전환 (피어리뷰 3편 수렴)** — Fucci TSE 2017(전문직 39명·82 데이터포인트): *"**Sequencing … had no important influence**"*, 효과는 **granularity·uniformity**가 냈다. 결론 원문 *"may not be due to its distinctive test-first dynamic"*. Rafique & Mišić TSE 2013 표준화 분석 품질 **0.106/−0.0101(유의하지 않음)**, ESEM 2016 외부 재현 무효과
  - **[workflow-and-feature-list.md](workflow-and-feature-list.md)의 "립도" 축에 세 번째 독립 수렴** — 기존 2편에 피어리뷰 TSE 1편이 더해지고, 측정 단위가 작업 단위가 아니라 **사이클 시간**이라 각도가 다르다
  - **에이전트 맥락 재확인(프리프린트)** — CodeSpec: *"textual designs are difficult to verify and enforce"*. **행위 명세 제거 시 70.7% → 64.0%**("체인 연결만으로는 출력·경계·상태 전이를 보장 못 함"), 텍스트 설계 대체 시 지시문 3,000~5,000단어에서 **71.8% vs 43.8%**
  - **목업을 정당화하는 유일한 규율은 계약 테스트**(목이 계약 산출물이 되어 제공자 측에서 검증)
  - **후속 1 (2026-08-03, 사용자 지적) — 용어 정정 §2.3.1.** "목업"이 **목 데이터(픽스처)** 와 **목 구현체(스텁)** 를 한 단어로 덮고 있었다. **§2의 반대는 후자에만 걸리며 픽스처는 처음부터 대상이 아니었다** — Cockburn의 `timing token`이 바로 픽스처다. 판별선은 **반환값이 계산된 것인가 박힌 것인가**. 참고 하네스의 `testing.md`(*"Do not mock business logic"*)가 독립적으로 같은 선을 긋는다

- [x] **언어·플랫폼마다 제품이 달라지는 검사(순환참조·커버리지)** — [per-language-check-divergence.md](per-language-check-divergence.md) · **검색 어댑터(exa·firecrawl)로 수행**
  - **[워크플로우와 기술 스택의 분리](workflow-stack-separation.md)의 자매편이고 결론의 모양이 다르다.** 테스트는 **동사가 공통**이었지만 이 계열은 **동사부터 갈라진다** — ① 언어가 이미 흡수(Go·Rust는 순환이 툴체인 에러, **Java는 클래스 순환이 JLS상 합법**) ② 단위가 다름(모듈/패키지/크레이트/슬라이스) ③ **ArchUnit은 규칙이 설정이 아니라 Java 테스트 코드다**
  - **선행 열린 질문 2건을 닫는다.** §9-3(공통 포맷 vs 언어별 파서) → **검사 종류마다 답이 다르다**. 이슈는 **SARIF로 수렴**(OASIS 표준)했고 **커버리지는 수렴하지 않았다**(Codecov가 파서 20종 이상 유지, **`.xccov`는 미지원 명시**). 그리고 **제3의 답**이 출하돼 있다 — reviewdog `errorformat`은 파서를 코드가 아니라 **한 줄 선언**(`%f:%l:%c: %m`)으로 쓴다. §9-7(디스패처가 스택을 어디서 읽는가) → **탐지 진영**(MegaLinter 파일 내용 정규식·trunk `direct_configs`·mise idiomatic version file 표·Renovate manager)과 **선언 진영**(Nx·moon·pre-commit)으로 갈리고, 탐지 신호 목록이 공개돼 있다
  - **어댑터 계약의 실물 3종을 확보했다** — MegaLinter `descriptor` JSON 스키마(**`cli_lint_mode` = file/list_of_files/**project**, `cli_lint_errors_count` 5값 중 하나가 `sarif`, `can_output_sarif` 기본값 `false`**), trunk `lint.definitions`(`known_bad_versions`까지 어댑터가 흡수), Code Climate 엔진 명세(도커 + `/code` 읽기 전용 + **이슈 JSON을 `\0` 구분 스트리밍** + `fingerprint` + `--net=none`)
  - **커버리지는 포맷을 맞춰도 숫자가 비교 불가다** — JaCoCo는 **바이트코드 명령어**(합성 코드 경고를 문서가 스스로 명시), Go는 **문장**, coverage.py는 문장(분기 옵트인). **전역 `≥80%` 게이트는 하나의 게이트가 아니다.** 임계값을 강제하는 곳도 넷(설정/플래그/별도 태스크/**Go는 없음 → 서드파티**)이고, **JaCoCo Gradle의 `jacocoTestCoverageVerification`은 `check`의 의존이 아니다**(공식 문서 명시)
  - **fail-open이 세 번째 층에서 재현된다** — 검사 부재가 ⓐ이 언어엔 무의미 ⓑ도구 미설치 ⓒ대상 파일 0으로 갈리는데 **전부 통과처럼 보인다.** 실사례: MegaLinter #2943(필터가 0건 매칭 → project 모드만 실행, 요약표 전부 ✅). **반대 사례도 하나 있다** — Nx Conformance는 라이선스가 없으면 *"fail without checking any rules"*
  - **플랫폼 축 확인**: Xcode는 커버리지가 파일이 아니라 **`.xcresult` 번들**이고 경로가 생성 시점 기준으로 박혀 `--path-equivalence` 매핑이 필요하다. 열린 질문 7건

- [x] **훅이 스킬 frontmatter를 읽는 경로 — 실측** — [hook-skill-frontmatter-probe.md](hook-skill-frontmatter-probe.md) · **실세션 5회 + 합성 재생 14케이스**
  - **위 조사가 "층 A(서술자)는 스킬, 층 B(판정·차단)는 훅"으로 가른 뒤 그 접합부를 쟀다.** 규격이 이미 정한 것은 확인만 하고 자료가 답하지 않는 둘만 측정
  - **경로 자체는 성립한다** — `PreToolUse`가 **`tool_input.file_path`를 절대 경로로** 주고(언어 라우팅의 전제), **`tool_input.content`까지 준다**. frontmatter는 YAML 의존성 없이 `awk`+`sed`로 파싱되고, 부재 3종(ⓐ무의미/ⓑ미설치/ⓒ대상0)과 **모호성(`AMBIGUOUS n=2`)이 전부 갈린다. 스킬 4종에 평균 85ms**(훅 기본 타임아웃 600초)
  - **`deny` + `additionalContext`가 완전히 도달한다** — 모델이 두 문자열을 모두 인용했고 파일은 생성되지 않았다. [구조 항해 §4.4](structural-navigation.md)가 규격으로만 확인했던 *"막고 무엇을 먼저 하라고 알리는"* 형태의 첫 실증
  - **그러나 모노레포에서 무너진다** — 하위 디렉터리에서 세션을 시작하면 **훅이 아예 발화하지 않고**(설정 비상속의 훅 층 재현, 발화 0회), 하위에 자체 `settings.json`을 두면 발화하되 **`$CLAUDE_PROJECT_DIR`가 하위를 가리켜 레지스트리 glob이 상대·CPD 모두 0건**이다. **환경변수가 상대 glob 문제를 구해주지 않는다**
  - **타이밍 모순이 실증됐다** — `project` 모드 검사(순환·커버리지)는 쓰기 **후** 상태가 필요한데, **차단 가능한 `PreToolUse`는 너무 이르고 시점이 맞는 `PostToolUse`는 exit 2로도 되돌리지 못한다.** stderr는 모델에 전달되므로 **거부 메시지와 디스크 상태가 어긋난다** — 상태 발산의 재료. **다만 모델이 롤백을 가정하고 행동하는지는 재지 않았다**(억제 지시 아래 나온 응답이다)
  - **파싱 실패가 오류가 아니라 조용한 누락으로 나타난다** — block-style YAML(`- a` 나열) 어댑터가 존재하지 않는 것처럼 처리돼 `AMBIGUOUS`가 나와야 할 곳에 `ROUTED`가 나왔다. `skill-registry`의 *"capabilities 없으면 skip silently"* 규칙과 결합하면 **의도적 미태깅과 파싱 실패가 구분되지 않는다.** 이 시리즈의 fail-open 계보 **다섯 번째**
  - **`ⓐ 무의미`가 다시 둘로 갈리는데 그것은 구분되지 않는다** — `.go`(툴체인이 순환을 잡으므로 정상)와 `.rs`(모듈 순환은 안 잡히므로 진짜 공백)가 같은 출력. **위 조사 §10 열린 질문 1이 실측으로 재현됐다**
  - **후속 (사용자 요청, §6) — 열린 질문 2건을 닫았다.** ① **상향 탐색은 성립하나 단일 지점 수정이 아니다** — 마커 2홉으로 루트를 찾아 `skills` 0건 → 4건이 되지만, **M4(미발화)는 못 고치고 훅 스크립트 파일도 디렉터리마다 필요하며, 그 파일이 없으면 로그·경고 없이 통과한다**(fail-open 여섯 번째). 게다가 **루트에 마커가 없으면 탐색이 프로젝트 밖으로 새고 그 결과가 "어댑터 없음"으로 위장된다** ② **권한 모드는 게이트를 우회하지 못한다** — `bypassPermissions`·`default`·`acceptEdits` 세 모드 전부에서 `deny` 유효
  - **부수 발견**: `bypassPermissions` 실행에서 **모델이 훅의 주장을 저장소에 대조해 반증하고 후속 지시를 인젝션으로 의심해 거부했다.** 차단은 유효하되 **`additionalContext`의 지시 수용은 보장되지 않는다** — 게이트 메시지에 검증 가능한 근거를 실어야 한다는 뜻(표본 1건). 열린 질문 9건
  - **후속 2 (2026-08-03, 사용자 요청) — §8-3 해소, [§9 신설](skeleton-first-then-tdd.md).** **초판의 "이벤트 체인 자료 공백"이 검색 축의 문제였다** — 비동기 체인은 반환값이 없어 **테스트 문헌에 단언 방법이 없고, 답의 한 층이 관측성 문헌에 있다**. 세 층으로 갈린다: **계약**(Pact message pact — 표준 CDCT는 async 지원. **BDCT 제약을 초판이 과일반화했다**. 단 Pact는 브로커를 대체하므로 체인을 증명하지 않는다) / **실경로**(Testcontainers 진짜 브로커 + 픽스처 메시지 — `@EmbeddedKafka`는 *"different Kafka implementation than production"*) / **관측**(Tracetest·OTel **span 순서 단언**이 반환값의 역할을 대신한다). 열린 질문 7 → **4건**
- [x] **하네스 미니멀리즘 — "고성능 모델일수록 제약을 적게"** — [harness-minimalism.md](harness-minimalism.md)
  - **사용자 기억의 출처를 특정** — Harness-Bench(arXiv:2605.27922, 5,088궤적)의 *"stronger model backends … lower cross-harness variance"* 와 Anthropic의 *"smarter models require less prescriptive engineering"*
  - **다만 측정된 것은 "덜 흔들린다"이지 "줄이면 오른다"가 아니다.** 확실한 이득은 토큰·유지보수(68k vs 175k, 코어 4천줄 vs 15만줄)
  - **반대 벡터 확인** — 하네스를 깎으면 작은 모델이 프런티어의 89.7%를 비용 4%로 회수. 단 태스크 다양성과 ρ=−0.96이라 grid fin 조건에서는 약해진다
  - **가장 견고한 관측**: 결론이 반대인 두 실험이 **실패 귀속에서는 일치**한다 — 추론 실패가 아니라 계약·형식 준수 실패(36.4%+24.6%)
  - "절차적 제약 vs 인터페이스 계약" 구분은 **가설로 보류**(세 사례 전부 단서 필요). 열린 질문 8건
  - **§11 분리 검증 프로토콜 추가 (미실행)** — 종속변수를 태스크 성공률에서 **도구 호출당 계약 위반율**로 바꿔 §1.5.3의 `δ` 벽을 우회. 다만 궤적 내 클러스터링(`DEFF = 1+(m−1)ρ`)이 그 이득을 되돌릴 수 있어 **Stage 0의 `ρ̂` 추정이 go/no-go**. 그리고 **Stage 2(모델 강도 × 제약 종류 상호작용 = 사용자 원 질문)는 상호작용 검출에 약 4배 표본이 들어 개인 규모에서 검정 불가로 확정**
  - **검증 실패 1건 기록** — 검색 계층에 Harness-Bench 귀속 가짜 수치가 유통 중(§9)

### 후속 조사 (사용자 요청, 2026-08-03)

- [x] **§1 파생 · 컨텍스트 파일에 무엇을 쓰는가 (최신 고성능 모델 중심)** — [context-file-content.md](context-file-content.md)
  - **새 토픽이 아니라 [지시 계층 §7-11](instruction-layers.md)의 종류 축을 잇는 작업이다.** 부모 문서 둘([지시 계층 §7-11](instruction-layers.md), [저장소 위생 §6-1](repository-hygiene.md))에 상호참조를 삽입했고 **재번호는 하지 않았다**
  - **가장 강한 근거가 1차(도구)다** — Claude Code 2.1.220 바이너리에 **신규 `/init` 프롬프트**가 게이트(`CLAUDE_CODE_NEW_INIT`) 뒤에 들어 있고, 선행 조사가 *"없다"* 고 적은 **포함 기준**이 명시되어 있다: *"only include what Claude would get wrong without it"*. 구식 `/init`이 요구하던 **"High-level code architecture"가 신규에서는 Exclude로 내려갔다**
  - **대조 실행으로 두 가지를 확인했다(B 부류, 2026-08-03)** — ① **신규는 이 계정의 기본값이 아니다**(기본 실행에 Phase 구조가 없다). 따라서 신규 프롬프트는 *"지금 도구가 하는 일"* 이 아니라 **"도구 제작자가 다음으로 정한 기준"** 으로 읽어야 한다. ② **그럼에도 Exclude 목록은 실제로 발화한다** — 같은 빈 저장소에서 구식은 `npm test`를 적었고, 신규는 ***"manifest에서 자명하므로 명시적 제외 대상"*** 이라며 기각했다
  - **계층 간 역할 분담도 도구 안에 있었다** — 메모리 시스템 프롬프트의 *"What NOT to save in memory: Anything already documented in CLAUDE.md files"*
  - **모델 축의 결과가 예상과 달랐다.** "최신 모델은 지시가 덜 필요하다"는 서사를 **채택하지 않았다** — ETH의 모델별 분해는 **생성 측**(*"stronger models don't generate better context files"*)이고 소비 측 상호작용은 미측정이며, 시험 모델(Sonnet-4.5·GPT-5.2·GPT-5.1-mini·Qwen3)이 **사용자가 묻는 세대를 하나도 포함하지 않는다**
  - **대신 벤더 1차 자료가 더 날카로운 것을 준다 — 교정의 부호가 인접 판본에서 뒤집힌다.** Opus 4.8은 서브에이전트 지시를 넣으라 하고 Opus 5는 *"remove any 'delegate more' guidance you added for 4.8"* 라 한다. **내용 규격은 상수가 아니라 대상 모델의 함수다**
  - **검증·교차리뷰에 직접 걸린다** — Opus 5 문서가 *"The same applies to **legacy harness scaffolding** that adds separate verification steps"* 로 하네스 스캐폴딩을 이름 대어 지목한다. **단 "메커니즘 게이트 vs 프롬프트 지시"의 구분은 그 조사가 붙인 해석이며 벤더 문서가 명시하지 않았다**
  - **§7-8(Codex 쪽 계층)이 닫혔다** — AGENTS.md는 **하향 순회·근접 override·`@import` 없음·32 KiB 총합 상한**으로 CLAUDE.md와 기제가 다르다. **`@import`가 없으므로 "긴 것은 빼라"는 처방이 그대로 옮겨가지 않는다**
  - **실측: 상시 로드 본문의 행동 하드 제약은 356줄 중 7줄(2%).** 튜토리얼 55% + 개요 26% = **81%가 두 기준이 독립적으로 지목한 범주**이고, [저장소 위생 §5.2](repository-hygiene.md)의 26%를 독립 재현했다
  - **`AGENTS.md`가 `harness-guide.md`의 사본이며 이미 54줄 어긋났다** — 기제 고장이 아니라 **동기화 미실행**. 갈라진 쪽이 Codex 리뷰어가 읽는 문서다
  - **미해결 10건 중 1건은 즉시 닫았다**(신규 `/init` 기본값 여부 — 위 대조 실행). 남은 최대 미해결은 **1M 창에서 길이 축의 생존**(벤더 주장 vs [§3.1·§3.2](instruction-layers.md))이며, **그 조사의 유일한 처방(상시 로드 81% 삭제)은 이 질문에 걸려 있지 않다** — 근거가 길이가 아니라 종류이기 때문이다. 그 밖에 벤더 수치의 방법 미공개, Codex 압축 생존(검색 요약뿐)
  - **방법 기록** — `strings -n 20`이 `Include:`/`Exclude:` 헤더를 길이 임계로 잘라내 **두 목록이 하나로 보였다.** 목록의 논리적 경계가 어긋나는 것을 단서로 `-n 3` 재추출해 잡았다. [지시 계층 §10.5](instruction-layers.md)의 "출력을 잘라 읽기" 위험의 **세 번째 사례이며 형태가 새롭다 — 도구의 기본 필터가 내용의 구조를 자른다**

- [x] **§1·§6 파생 · 스킬의 타입·계층과 서브에이전트 조합** — [skill-architecture.md](skill-architecture.md) (사용자 요청, 검색 어댑터 사용)
  - **전제: 커스텀 커맨드 없이 스킬만으로 하네스를 구성한다.** 첫 확인 결과 **기능 손실이 없다** — 커맨드 고유 필드(`argument-hint`·`allowed-tools`·`disable-model-invocation`·`${}` 치환·인라인 `!` 셸)가 전부 스킬 frontmatter에 있고, 공식 문서가 `.claude/commands/*.md`를 **스킬의 배치 형태 중 하나**로 나열한다
  - **공식 타입 축은 접두어가 아니라 (호출 주체 × 실행 위치) 2×2다** — *"how you want the skill invoked (by you, by Claude, or both) and where you want it to run (inline or in a subagent)"*. `wf-`/`flow-` 같은 접두어는 규약이고 이 네 필드는 **강제**다
  - **수량에 실증이 생겼다** — [SkillsBench](https://arxiv.org/html/2602.12670v1)(84과제·7,308 trajectory): 과제당 **2–3개 최적(+18.6pp), 4개 이상 +5.9pp**로 급락, **comprehensive 스킬은 −2.9pp**. 그리고 **자가 생성 스킬은 효과 없거나 음수** — [ETH의 컨텍스트 파일 결과와 같은 방향](context-file-content.md)
  - **"계층 베스트 케이스"에 대한 답은 부정형이다** — 실제 스킬 238개 taxonomy에서 `Related Skills` **8.0%**, `Skill in a Skill` **1.7%**, `Agent Composition` **1.7%**. **133,149개 생태계에서 inter-skill 계층은 사실상 실천되지 않으며, 실제로 쓰이는 계층은 스킬 *안쪽*의 progressive disclosure다**
  - **서브에이전트×스킬은 양방향이고 문서가 서로의 역이라 부른다** — 에이전트 `skills:`(전문 프리로드) ↔ 스킬 `context: fork`+`agent:`. **제약: `disable-model-invocation: true` 스킬은 프리로드 불가**이므로, 예전 커맨드를 전부 그것으로 옮기면 자동화 경로에서 사라진다
  - **열린 질문 둘이 닫혔다** — **§7-4**(라우팅 표면 총합 예산): settings의 스킬별 listing override 3단계가 **장치로 존재한다**. **§7-5**(중첩 스킬 노출): **노출되며 경로로 네임스페이스된다**
  - **근거 등급 주의** — 측정 자료 3편이 전부 2026 프리프린트이고, [Anatomy 논문](https://arxiv.org/html/2607.01456v2)의 **"skill smell" 축은 구글 검색 상위 블로그 29건의 MLR을 뒤집어 만든 것**이다(논문이 자인). **같은 논문 안에서 taxonomy 축(실측 귀납)과 smell 축(자가출판 기반)의 등급이 갈리며, 섞어 쓰지 않았다**
  - **미해결 8건.** 최대는 **[아젠다 §6-1](evaluation.md)의 스킬 활성화 정확도 측정법** — 커맨드가 없는 구성에서 description이 **유일한 디스패치 기제**가 되므로 이번에는 더 아프다. 재검색에서도 신뢰 자료를 찾지 못했다
  - **방법 기록** — 어댑터 스킬이 하위 질문 4개 이상에서 서브에이전트 병렬을 지시하나, 세션의 *"Do not call the AgentTool unless the user requested it"* 제약이 우선한다고 판단해 **메인 세션 순차 실행**했다(API 호출 수 동일)

- [x] **§0 파생 · 코딩 아닌 작업 — 하네스가 무엇을 다뤄야 하는가** — [non-coding-work.md](non-coding-work.md) (사용자 요청, 검색 어댑터 사용)
  - **첫 결과가 프레임워크 자체에 대한 것이다** — `awesome-harness-engineering`의 13개 프리미티브에 **작업 종류 축이 없다**(§0에 정정 블록 삽입). 전부 하네스 구성 기제이고, 감독 대상 작업으로 분류하는 절이 없다. **찾아볼 정답이 없어 인접 문헌에서 조립했으며, 조립물임을 명시했다**
  - **재료 셋** — [ExITBench](https://aclanthology.org/2026.findings-acl.560.pdf)의 IT 자동화 **7종**(서버 설정/네트워킹/정책/템플릿/배포 파이프라인/변수 관리/파일 관리), DevOps-Gym의 주기 **4단계**(빌드·설정/모니터링/이슈 해결/테스트 생성), [InfraBench](https://hotinfra.org/2026/papers/hotinfra26-final71.pdf)의 **계층 L1–L4 × 생애주기 4단계 × 위험** 3차원
  - **InfraBench 비교표가 이 시리즈에 직접 걸린다 — SWE-Bench는 Lifecycle·Risk 축이 둘 다 `–`다.** [평가](evaluation.md)·효과 크기 조사가 인용한 수치는 전부 **되돌릴 수 있는 저장소 편집**에 대한 것이며 배포·마이그레이션으로 외삽할 근거가 없다
  - **판별자는 작업 이름이 아니라 되돌릴 수 있는가다** — 되돌릴 수 있으면 센서를 뒤에, 없으면 게이트를 앞에. **하네스 전체가 전제하는 쓰고-검증-수정 루프가 후자에서 성립하지 않으며**, [강제 메커니즘](enforcement-mechanisms.md)의 `deny`·`ask`·`sandbox` **0건**이 정확히 그 부분의 공백이다
  - **실증은 일관되게 낮고 실패 형태가 공통이다** — Ansible pass@10 **23.9%**(ACL, 피어리뷰), SRE **50% 미만**, 인프라 56~91%. 형태는 ***"보이는 목표는 달성하고 운영상 의무는 놓친다"*** 와 ***"표면 상태 신호를 믿고 멈춘다"*** — [워크플로우 §4.1](workflow-and-feature-list.md)의 조기 완료 선언과 같은 형태
  - **InfraBench의 Risk Monitor가 [§2-5](enforcement-mechanisms.md)(에이전트가 린터 설정을 고쳐 우회)에 부분 답을 준다** — 막지는 못하되 *disabled safety checks* 를 **관측 가능한 1차 신호**로 정의한다
  - **1차 관측: 참고 하네스에 비코딩 작업 규칙이 0건이다.** 규칙 6개 전부 TS/Vitest, `배포`는 **하네스 자신의 배포**. 개발환경 전제(세션 메모리)의 다중 런타임 모노레포와 어긋나며, **계승할 것이 없고 새로 만들어야 한다**
  - **모델 세대 지체가 세 번째로 반복됐다**(컨텍스트 파일·스킬에 이어). **이제 우연이 아니라 이 분야 문헌의 구조적 성질로 본다** — 낮은 절대 수치는 하한으로 읽고 **실패의 *형태*를 수치보다 신뢰한다**
  - **미해결 9건.** 세 축이 통합되지 않음, **개인 규모 전이 미확인**(전부 클러스터 전제), 에이전트가 카나리를 운영할 때의 실증 부재, 임의 명령에 위험 등급을 계산하는 방법 부재

- [x] **§7.4 파생 · 진단 ④의 개입 설계 + openwiki↔graphify 비교** — [structural-navigation.md](structural-navigation.md) (사용자 요청, 검색 어댑터)
  - **개입은 세 층이다** — ① 구조 인덱스 ② **에이전트용 질의 도구** ③ **도입 강제**. **초판 직관은 ①에 있었으나 자료는 ②·③에 무게를 둔다**
  - **피어리뷰 앵커 확보 — [LocAgent, ACL 2025](https://aclanthology.org/2025.acl-long.426/).** 관계 4종(`contain`·`import`·`invoke`·`inherit`), **도구 3종**(`SearchEntity`·`TraverseGraph`·`RetrieveEntity`), SWE-bench-Lite 전 수준 최고(파일 Acc@5 **94.16**, 함수 Acc@10 **77.37**). **저자들이 기존 IDE형 도구를 *"designed for human [reading]"* 이라 명시 기각한다** — 이 시리즈가 찾던 "에이전트용 도구 표면" 규격
  - **미세조정 32B 오픈 모델이 GPT-4o 기반 에이전트를 전부 앞선다**(비용 86% 절감 주장)
  - **가장 실무적인 발견은 도입률이다** — CodeCompass 효과 **99.5%** vs 도입 **42%**, 구조 과제 **0/30**. 완화책이 **체크리스트를 프롬프트 끝에** 두는 것으로, [§3.1의 U자 위치 효과를 열화가 아니라 배치 자원으로 쓴다](instruction-layers.md). [Opus 4.8 문서의 *"call this when…"*](skill-architecture.md)이 독립 확인
  - **재검색 (2026-08-03, 사용자 요청) — §4.4 신설. "자료 없음"이 틀렸다.** 초판 질의의 `adoption`이 **경영 어휘라** 기업 AI ROI 문서로 수렴한 것이었고, 기술 어휘로 바꾸자 **세 계열**이 나온다: **(A) 훅 게이트** — `PreToolUse`의 `deny`/`updatedInput`/**`additionalContext`**(v2.1.9+)와 `asyncRewake`로 *"막고 무엇을 먼저 하라고 알리는"* 것이 **규격상 완비**(1차 공식) · **(B) `tool_choice: required`** — 턴 단위라 이 조건에 안 맞고 **무한 루프 실패 모드**가 문서화돼 있다 · **(C) 그래프/상태기계** — LangGraph 실무가 설계 원칙 셋을 준다: ***"부작용 바로 옆에 강제를 둔다"***(라우팅으로 막으면 순서를 바꿔 뚫린다), 전제조건을 상태로 기록, **안내형 실패**
  - **공백의 형태가 바뀌었다** — *"기제가 없다"* 가 아니라 **"기제·설계 원칙은 있고 이 용도의 구현 사례와 효과 측정이 없다"**. grid fin이 만든다면 선행 사례 추종이 아니라 **§4.1의 42%를 자기 환경에서 재는 쪽**이다
  - **방법 기록**: 검색 실패를 자료 부재로 읽었다. [출력 절단](instruction-layers.md)·[상호참조 기억 인용](non-coding-work.md)에 이은 **세 번째 "확인 없이 결론" 계열이며 형태가 새롭다**
  - **도구 비교는 판정이 아니라 배치다** — openwiki=**산문 위키**(사람 탐색용, *"not explicit dependency graphs"*), graphify=**전역 그래프**(자기 문서가 "네비게이션 도구 아님" 명시), **serena=LSP-over-MCP `find_referencing_symbols` — §7.4.2가 이긴다고 한 형태와 정확히 일치**, LocAgent형=목적 그래프+다중 홉
  - **가장 중요한 관측: grid fin에 없는 것은 도구가 아니라 도입 장치일 가능성이 높다.** graphify 포지셔닝이 이미 네비게이션을 LSP에 넘겼고, serena가 그 빈 곳을 채운다
  - **openwiki는 ETH·SkillsBench 결과와 교차한다** — LLM 생성 저장소 문서를 `AGENTS.md`/`CLAUDE.md`로 연결. **단 경계를 그었다**: ETH가 잰 것은 컨텍스트에 앉은 정적 개요이고 openwiki는 가리키기만 한다. **전이 여부 미확인**
  - **1차 관측으로 §5.5를 정정했다** — `graphify-out/graph.json`(637노드·850링크)을 직접 열어보니 **`shares_data_with` 38건이 있다.** 넷 중 유일하게 데이터 흐름 관계를 갖고, **간선마다 `EXTRACTED`/`INFERRED` 출처 등급**과 `rationale_for`·`cites`(설계 의도↔코드)까지 있다. **다만 `directed: false`라 ToCS의 방향 있는 `data_flows_to`와는 다르다**
  - 열린 질문 7건. 최대는 **도입 강제 사례 부재**와 **의미 과제/구조 과제를 사전에 가르는 방법 부재**(§4.1의 0/30이 바로 그 실패다)

- [x] **제품 단일 심층 · Orca (onorca.dev)** — [orca-ade.md](orca-ade.md) (사용자 요청)
  - **이 시리즈에서 처음으로 축이 아니라 제품 하나를 대상으로 한다.** 따라서 §9(기존 축으로의 재배열)가 실제 쓸모다. 결정은 하지 않는다
  - **가장 옮길 만한 것은 스킬 배포 구조다** — 스킬 파일에는 **스텁 78줄**만 두고 **실제 가이드 331줄은 바이너리가 `orca skills get`으로 서빙**한다. 이유가 스텁 본문에 있다: *"kept out of this file on purpose so it can never drift from the binary that will actually run your commands"*. 그리고 *"this file **deliberately no longer** lists them"* — 설계가 아니라 겪은 뒤의 수정이다
  - **그 선택의 전제가 실측된다** — 이 머신 1.4.158 vs 최신 stable 1.4.164, **6일에 6버전**(릴리스 API). 전제가 다르면 결론이 따라오지 않는다는 단서를 같이 기록했다
  - **3층 분할** — 스텁 78줄(항상) / 가이드 331줄(발동 후) / `agent-context --json` **206커맨드 137KB**(기계용). [skill-architecture](skill-architecture.md) 관측 #17의 "본문 500줄 상한"을 **파일 밖으로 밀어** 푸는 형태
  - **[worktree-shared-state](worktree-shared-state.md)에 두 군데** — ① 관측 #14·#14b의 **세 번째 사례**(`.worktreeinclude` + `orca.yaml` + setup script, 레포 `orca.yaml` 실물이 마지막 칸을 증명) ② **관측 #1의 여덟 번째 사례** — 조율 원장이 `~/Library/Application Support/Orca/orchestration.db`(SQLite WAL, 5테이블) **머신 전역 하나**다. 워크트리 안도 레포별도 아니다
  - **조율은 기제만 있고 효능 근거가 없다(부재 확인).** Run/Task/Dispatch/Message/Gate 어휘와 DB 스키마는 1차로 확보했고 — **`circuit_broken`·게이트 `timeout`·`poll_interval_ms=2000`(코디네이터가 폴링 루프)은 문서에 없던 것** — 벤치마크·측정은 사이트·README·문서 어디에도 없다. **[agent-orchestration](agent-orchestration.md)의 결론은 흔들리지 않는다. 가용성은 효능의 증거가 아니다**
  - **부수 1차**: 레포 `CLAUDE.md`가 **한 줄 `@AGENTS.md`**(내용은 60줄 `AGENTS.md` 하나, 금지 규칙 위주) · 텔레메트리가 OTel이 아니라 PostHog이고 **원본 에러 메시지를 일부러 안 보낸다**(emit vs redact) · 런타임 소유권 4배치와 *"The daemon dies when the host does"* 경계
  - **요약기 경유 수집이 낸 오차를 §0.4에 대조표로 남겼다**(에이전트 수 "25+"/"40+" → 실물 **명명 29종 + any CLI agent**). 조사 실패 1건도 헤더에 기록(`/docs/what-is-orca` 404 — 사이트 구조를 추측해 URL을 만든 것이 원인, 이후 sitemap 기준으로 전환). 열린 질문 7건 중 1건은 조사 중 해소

- [x] **제품 단일 심층 · cmux (cmux.com / manaflow-ai)** — [cmux.md](cmux.md) (사용자 요청) · **Orca 조사의 자매편**
  - **이 시리즈에서 로컬 1차 데이터가 가장 두꺼운 조사다** — 이 머신의 `~/.cmuxterm/workstream.jsonl` **104,693건 / 174 MB / 34일**을 직접 집계했다. **n=1 머신·1 사용자 범위이며 로그에 grid fin 조사 작업 자체가 포함된다**
  - **[관찰성](observability.md)의 진단이 형태를 바꿔 재현된다.** 이름 문제는 **완전히 풀렸다** — `toolUse` 81,645건 전부 도구명 보유(Bash 41,763 / Read 17,134 / Edit 10,810), 이벤트마다 `permissionMode`까지. *"13,342건이 전부 `unknown`"* 의 정반대. **그런데 `permissionRequest` 328건이 전부 `status: {"pending": {}}` — Swift 열거형 인코딩이고 연관값이 빈 객체라 결정이 담길 칸 자체가 비어 있다**(열거형 내부를 다시 열어 확인). 328건 모두 `createdAt == updatedAt`·id 중복 0이고 `payload.permissionRequest`는 `{requestId, toolName, toolInputJSON}` 뿐 — 추가만 하고 결말을 갱신하지 않는다. **조인 키(`requestId`)는 있다. 끊긴 것은 키가 아니라 보존이다.** 결말을 찾아간 이벤트 스트림은 **18시간짜리**(`events.jsonl` + `.1`이 08-02T11:29 → 08-03T05:27)인데 **감사 로그는 34일치를 회전 없이 쌓는다. 요청은 영구, 결말은 18시간 — 조인이 구조적으로 끊긴다.** 그 이벤트 payload 키 전수에도 `decision`/`allow`/`deny` 계열이 없다(보존 창 안 PermissionRequest feed 이벤트 0건이라 부재 단정은 못 함)
  - **[강제 메커니즘](enforcement-mechanisms.md)의 "deny·ask·sandbox 0건"이라고 적은 곳에 도는 물건이 있다** — Feed. **게이트율은 모드가 정한다**: `default` 모드 **319/3,616 ≈ 8.8%**(모드 미상 10,826건 때문에 **상한값**), `auto`는 3/67,092. **집계치 0.40%는 게이트율이 아니다**(분모의 82%가 안 묻는 모드). 승인 대상의 **71%가 Bash**(233/328). **그리고 모드 미상 10,826건은 초기 스키마 탓이 아니다** — 월별 비율이 13.3%/12.0%로 유지되고, 그 정체는 **codex 3,886(전량) + claude 6,940**. [관찰성 §2.3](observability.md)의 "진입점별 계측 결손"이 여기서도 Codex 쪽에서 재현된다
  - **fail-open 계보에 성격 구분이 생겼다** — 기존 6건은 전부 사고였는데 Feed는 **의도된 fail-open**이다: *"Feed is advisory, not blocking"*, 120초 상한, 타임아웃 시 `{}` 반환 후 **에이전트 자체 프롬프트로 폴백**, 모델명까지 명시. **사고와 설계를 가르는 것은 fail-open 여부가 아니라 폴백 명시 여부다.** 대가도 숫자로 — 훅 per-event 타임아웃을 기본 **5,000 ms의 약 24배**(120~125초)로 올린다
  - **[스킬 구조](skill-architecture.md)에 Orca의 정반대 극** — 전문 **20종 1,949줄** 설치 + `references/` **34파일 2,704줄** + `agents/openai.yaml` 18/20(벤더별 서술자). **500줄 상한을 파일 옆(디렉터리)으로 밀어 지킨다**(Orca는 파일 밖=바이너리로). 그리고 **20종 중 11종이 "cmux를 개발하는 법"** — 제품이 자기 기여자 하네스를 스킬로 출하한다
  - **[배포](harness-distribution.md)의 세 번째 패턴** — `cmux docs`는 텍스트가 아니라 **`raw.githubusercontent.com/.../main/` URL + curl**을 출력한다. **버전 핀 없음.** 다만 릴리스 주기가 **약 2주**(Orca는 1~2일)라 덜 아프다 — 같은 문제의 두 답이 서로 다른 전제 위에 선다는 실물
  - **[훅 층](hook-skill-frontmatter-probe.md)에 벤더 17종 대응표** — 설치 파일 경로·세션 복원 명령·Feed 브리지 훅 이벤트. **가로채기 지점이 벤더마다 다르다**(Claude `PermissionRequest` / 다수 `PreToolUse` / Cursor **`beforeShellExecution`**). 단일 벤더의 타이밍 문제가 다중 벤더에서는 **지점 자체가 어긋나는 문제**로 바뀐다
  - **[보안](security.md) 축 1건** — cmux 래퍼가 Claude를 **`--allow-dangerously-skip-permissions`로 띄운다**(Feed의 Bypass 버튼을 살리려고). 통합 편의를 위해 권한 기본값을 내리는 형태
  - **라이선스·수익이 Orca와 갈린다** — **GPL-3.0-or-later + 상업 조건 유보**(유보 범위를 *"only for material for which it controls the necessary rights"* 로 스스로 좁힘, 그래서 GitHub은 `NOASSERTION`). 가격은 공개 — Free / **Pro $30(4 vCPU·16 GB VM 월 20 compute-hour + 모델 게이트웨이 + iOS)** / Team $35 / Enterprise. **앱을 GPL로 풀고 컴퓨트를 판다.** 열린 질문 8건(최대는 "승인 결정이 앱 내부에는 남는가" 미확인)

### 미착수 (0)

없다. 우선순위 10건이 모두 조사되었다.

### 출처 감사 (2026-08-02 실시)

**두 차례 실시했다. 1차는 초기 4개 문서, 2차는 나머지 5개 문서 대상이다.**

### 1차 — 초기 4개 문서

완료된 4개 문서에 대해 "신뢰도 높은 외부 자료가 충분한가"를 점검하고 보강했다. **문서를 재작성하지 않고 해당 절만 수술적으로 고쳤다** — 신규 문서들이 걸어둔 §번호 참조를 깨지 않기 위해서다.

| 문서 | 발견 | 조치 |
|---|---|---|
| 워크플로우·피쳐 목록 | **가장 취약.** 실행 가능한 규정이 전부 자가출판 단일 출처. 게다가 그 출처가 인용한 Guo et al.을 **검증 없이 재인용** | §4.3 신설(Rigby & Bird FSE 2013 + Sadowski ICSE-SEIP 2018 **본문**), §4.1 Guo 인용 오용 정정, §4.2 WIP=1 근거 부재 명시, §0 축별 근거 상태표 |
| 배포 메커니즘 | ETH Zurich 연구를 **블로그를 통해 2차 인용**했고, 그 특징 규정이 원문과 달랐다 | §6.3에 원문([arXiv 2602.11988](https://arxiv.org/abs/2602.11988)) 확인 결과와 정정표 삽입 |
| 지시 계층 | §6 수렴표 2행("코드에서 유도 가능한 것은 빼라")의 측정 근거 칸이 비어 있었다 | §6.1 신설 — 위 ETH 원문이 그 칸을 채우되 **1행(길이 축)은 오히려 흔든다.** §7-11 추가 |
| 오류 재발 방지 | ProactAgent 수치가 검색 요약 근거 | §4.3에 원문 초록 확인 결과 추가 — 수치는 정확하나 **평가 환경이 SWE 과제가 아님**이 드러남 |

**감사가 드러낸 공통 패턴 두 가지.**

1. **2차 인용이 실제 결함이었다.** 두 문서가 자가출판 출처의 *수치*는 경계하면서 그 출처가 *인용한 논문*은 검증 없이 옮겼다. 원문을 보니 한 건은 오용(Guo), 한 건은 잘못된 특징 규정(ETH)이었다.
2. **보강이 항상 기존 주장을 강화하지는 않는다.** ETH 원문은 "길이를 줄여라"가 아니라 "내용 종류를 가려라"를 말하므로 지시 계층 문서의 전제 하나를 약화시킨다. 이것을 숨기지 않고 열린 질문으로 승격했다.

**해소되지 않은 것** — 자가출판 출처(walkinglabs) 의존은 삼중 구조·상태 머신·WIP=1 축에서 그대로다. 대체할 신뢰 가능한 자료를 찾지 못했고, **없는 근거를 만들지 않기 위해 평판 좋은 미검증 출처로 바꾸는 것도 하지 않았다.** 오류 재발 문서의 2026 프리프린트 의존도 그대로다.

### 2차 — 나머지 5개 문서 (2026-08-02 실시)

보안·관찰성·평가·저장소 위생·에이전트 조율이 대상이다. **이 5건은 조사 단계에서 이미 1차 자료 확인을 원칙으로 삼았으므로, 감사는 각 문서가 스스로 "확인하지 못했다"고 적어 둔 공백을 겨냥했다.** 1차와 같이 문서를 재작성하지 않고 해당 절만 수술적으로 고쳤다.

| 문서 | 겨냥한 공백 | 발견 | 조치 |
|---|---|---|---|
| **평가** | `n ≈ 969`의 파라미터 (문서가 *"가장 약한 고리"* 로 명시) | **`δ=0.03`·`α=0.05`·`β=0.20`·`ω²=1/9`·`σ²=0`.** 1,000문항은 **3%p 차이**를 잡는 값이다. `n ∝ 1/δ²`이므로 20%p 효과는 **약 22문항**이면 된다 | §1.2.1 신설(원문 인용), **§6.4.1 신설 — 결론을 조건부로 약화**, §7-3·부록 갱신 |
| **관찰성** | PR #13083이 무엇을 고쳤나 (§6-5의 가설) | **가설 확인.** diff는 `build_provider`의 analytics 인자를 `false`→`true`로 바꾼 것이 전부이고, **회귀 테스트는 상수값만 검사해 보고된 버그를 잡을 수 없다.** 한편 `mcp-server`에는 컬렉터가 실제로 추가됐다(+92/−19) | §2.3.1 신설(diff 인용), §6-3·§6-5 갱신 |
| **보안** | 설계 패턴 논문의 사례 10번 (문서가 *"가장 값진 자료인데 가장 얕게 읽었다"* 로 명시) | 저자 권고는 **Dual LLM + 엄격한 데이터 포매팅**(격리 LLM 출력에 "메서드명 30자 이내" 같은 기계적 상한). **단 그 사례가 상정한 신뢰 불가 입력은 온라인 문서·제3자 패키지이고 저장소 콘텐츠·이슈 트래커는 범위 밖이다** | §1.2.1 신설, §6-1·부록 갱신 |
| **저장소 위생** | 지시/개요의 조작적 경계, v2 본문 | **개요 출현율은 논문이 집계한다** — 개발자 작성 12개 중 8개, **LLM 생성은 Sonnet-4.5 100%·GPT-5.2 99%·Qwen3 95%**. 그리고 **v1→v2에서 초록이 약해졌다**(*"reduce"* → *"does not generally improve"*), 비용 수치는 동일 | §1.3.1 신설, §6-1·부록 갱신 |
| **에이전트 조율** | MAST 판본 | v1·v2·v3이며 **인용한 v3이 최신**이다 | 부록 갱신 |

**1차가 명명한 두 패턴이 어떻게 되었는가.**

1. **2차 인용은 5개 문서 본문에서는 재현되지 않았다 — 그러나 후속 조사에서 두 번 발생했고 둘 다 1차 확인에서 잡혔다.**

   | 사례 | 검색 요약의 주장 | 1차 확인 결과 |
   |---|---|---|
   | [관찰성 §3.1 정정 1](observability.md) | `gen_ai.usage.input_tokens`가 **메트릭** | **스팬 속성**이다. 토큰 메트릭은 `gen_ai.client.token.usage` 하나뿐 |
   | [평가 §1.6.3.1](evaluation.md) | HAL이 **`pass^k`** 를 보고 | **본문 전수 검색 0건.** 게다가 HAL은 반복 실행 자체를 안 했다 |

   **패턴이 사라진 것이 아니라 규칙이 잡아내고 있다는 뜻이다.** 두 건 모두 검색 요약을 근거로 쓰지 않고 원문을 받아 확인하는 과정에서 드러났다. **두 번째 건은 다섯 번째 폴백(PDF 직접 추출)에서야 잡혔다** — 네 번째에서 멈췄다면 문서에 남았을 것이다.

   5개 문서 본문에 한정하면 감사에서 새로 발견된 2차 인용 결함은 없다. **대신 이 문서들은 집필 중에 스스로 아젠다 본문의 규정 4건을 정정했다** — §6(2602.14690 인용), §6 참고문헌(SkillGenBench), §11-3(기록 원천 규정), §5-2(중첩 5단계). 정정은 각 절에 인용 블록으로 붙어 있다.
2. **"보강이 항상 기존 주장을 강화하지는 않는다"는 재현되었다.** 평가 문서가 그 사례다. `δ=0.03`을 확보하자 **"개인 규모에서는 표본이 두 자릿수 부족하다"는 결론이 "작은 효과에 한해 그렇다"로 좁혀졌다.** 1차의 ETH 사례와 같이 숨기지 않고 §6.4.1로 승격했고, 해당 문서의 §0 요지도 함께 고쳤다.

**그리고 2차가 새 패턴 하나를 추가한다.**

3. **프리프린트는 판본 사이에 주장의 강도가 바뀐다 — 수치만이 아니다.** 두 번 걸렸다. **Galster et al.**은 v1→v5에서 스킬 리소스 집계가 501(83.3%)→514(85.5%)로 바뀌었고, **Gloaguen et al.**은 v1→v2에서 초록의 핵심 주장이 *"tend to **reduce** task success rates"* → *"**does not generally improve** task success rates"* 로 **약해졌다**(비용 수치는 동일). **이 시리즈가 인용한 자료의 상당수가 2026년 프리프린트이므로 일반화되는 교훈이다 — 인용 시 판본을 적고, 판본이 바뀌면 수치뿐 아니라 주장 자체를 다시 읽어야 한다.** 저장소 위생 문서 §1.5에 세 층(v2 초록 / v1 초록 / v1 본문 절)을 구분하는 블록을 넣어 대응했다.

### 후속 — 효과 크기 조사 (2026-08-03 실시)

2차 감사가 평가 문서의 결론을 `δ` 의존으로 바꾸면서 **"하네스 변경의 `δ`가 얼마인가"** 가 병목이 되었다. 새 토픽이 아니라 평가 §7-3을 닫는 작업이므로 **문서를 새로 만들지 않고 평가 문서에 §1.5를 신설했다.**

**자료**: [Zhang, Wang, Ge, Xu, Hamm, Reddy, *Stop Comparing LLM Agents Without Disclosing the Harness*](https://arxiv.org/abs/2605.23950) (2026-05-07). 저자들의 3×3 통제 실험(SWE-bench Verified subset100, 셀당 2회) + 제3자 인용.

| 발견 | 값 |
|---|---|
| **하네스만 바꿨을 때 점수 이동** | 13.0 / 8.5 / 8.5 pp |
| **모델만 바꿨을 때 점수 이동** | 3.0 / 2.5 / 5.0 pp |
| **하네스 분산 / 모델 분산** | **7.80×** |
| **순위 역전** | 9개 비교 중 **6개** |

**핵심 결과 — `δ`가 변경의 종류에 따라 두 부류로 갈린다.**

| 변경 | `δ` | 필요 문항 | 개인 규모 |
|---|---|---:|---|
| 하네스 전체 교체 | 0.07~0.16 | **34~178** | **측정 가능** |
| 구성요소 하나 추가 | 약 0.02 | **약 2,180** | **측정 불가** |

**그리고 순위 역전이 9개 비교 중 6개에서 나타났다는 결과가 §4 교차 리뷰에 직접 걸린다** — 작성 측과 리뷰 측이 서로 다른 하네스에서 도는 이상, 관측된 품질 차이를 모델 특성으로 귀속하기 전에 하네스를 고정해야 한다. 아래 실험 목록의 "교차 리뷰 발화율이 리뷰어 성향인가 코드 상태인가"가 열거하지 않은 **세 번째 가능성**이다.

**이것이 아래 "실험 9건" 목록의 성격도 바꾼다.** **`@import` 압축 생존이나 `hooks.json` 무시 확인처럼 예/아니오로 끝나는 동작 확인에는 `δ`가 아예 개입하지 않는다.** 반면 성능 개선을 주장하려는 항목은 대부분 두 번째 부류의 변경이므로 **통계적 A/B로 효과를 입증하는 경로가 열려 있지 않다.** 목록이 원래 사실 확인 형태로 쓰인 것은 그래서 적절했다 — **구성요소 단위 하네스 변경의 검증은 효과 측정이 아니라 동작 확인 쪽에 두어야 한다.** **이 판단을 2026-08-03에 목록 자체에 반영했다(A~D 재분류).**

**미해소** — "구성요소 하나 추가"의 실측치가 사례 하나뿐이다.

### 후속 2 — 잡음 바닥 조사 (2026-08-03 실시)

효과 크기 조사가 남긴 미해소 항목이다. **평가 문서 §1.6으로 산출했다.** 자료 넷, 각각 grid fin의 단위에서 다른 거리에 있다.

| 자료 | 반복 대상 | 핵심 수치 |
|---|---|---|
| [Yuan et al. (2506.09501v2)](https://arxiv.org/abs/2506.09501) | 하드웨어·배치 구성 12종 | **기제**: 부동소수점 비결합성 → greedy·동일 시드에서도 발산. BF16 SD 최대 **9.15%**, FP32는 거의 0 |
| [Zhou et al. (2606.00920v1)](https://arxiv.org/abs/2606.00920) | 동일 설정 5회 (LeetCode 100 × 16모델) | **1회 관측 vs 5회 전부 성공 격차 최대 17.8pp** |
| [Mehta (2602.11619v2)](https://arxiv.org/abs/2602.11619) | **SWE-bench 50 × 5회 포함, 8,000회** | 동일 입력에 **10회당 고유 행동 경로 2.3~4.2개**, **1회 실행 비교는 29.3%가 오순위** |
| [HAL (2510.11977)](https://arxiv.org/abs/2510.11977) · **ICLR 2026** | **반복 없음** — 21,730 rollouts 전부 단일 실행 | *"forced to rely on **single runs** without statistical validation"*. 추론 예산 증가는 **36개 조합 중 21개**에서 정확도가 같거나 하락 |

**핵심 결과 — 1회 관측으로는 비교가 성립하지 않는다.**

| 무엇 | 크기 | 성격 |
|---|---:|---|
| 구성요소 하나 추가의 효과 | 약 **2pp** | 재려는 신호 |
| 하네스 전체 교체의 효과 | **7~16pp** | 재려는 신호 |
| **1회 실행 비교의 오순위율** | **29.3%** | **판정의 신뢰도** |

> **Zhou et al.의 17.8pp를 변동폭으로 읽지 않는다.** RLPR과 PSR은 같은 데이터에 대한 서로 다른 두 추정량이고 구조상 `PSR ≤ RLPR`이다. 끌어낼 수 있는 것은 *"1회 통과율이 재시도 없는 신뢰도를 최대 17.8pp 과대평가하고, 그 폭이 모델마다 달라 순위가 뒤집힌다"* 까지다.

**그리고 순위가 뒤집히는 독립 원인이 셋으로 늘었다** — 하네스 선택(Zhang, 9개 중 6개), 재시도 정책(Zhou), **1회만 돌린 것(Mehta, 29.3%)**. 아래 실험 목록의 "교차 리뷰 발화율이 리뷰어 성향인가 코드 상태인가"는 **그 이분법 밖의 설명 셋을 먼저 배제해야 성립한다.** 실무 형태도 자료가 준다 — Mehta의 `k=3` 합의 규칙(커버리지 54~62%에 정확도 +6~14pp).

**추가 발견 — HAL 본문(PDF 전문)에서.** *"한 번으로는 안 되고, 여러 번은 비싸다"* 가 이 조사의 실제 도달점이다. HAL은 21,730 rollouts에 약 $40,000을 쓰고도 *"High evaluation costs prevent uncertainty estimation … forced to rely on single runs"* 이라 적는다. **가장 큰 표준화 평가 인프라조차 신뢰구간을 못 만든다.** 그리고 실무 잡음 경로를 열거하는데, 그중 둘이 이 시리즈에 직접 걸린다 — **OpenRouter가 호출마다 FP4/FP8을 섞어 라우팅해 *"hidden variance"* 를 만든다**(§1.6.1의 수치 정밀도 기제가 운영 층에서 발현되는 형태), 그리고 **제공사가 같은 엔드포인트 이름 뒤에서 가중치를 교체한다**(SHA 핀으로도 모델 쪽을 고정할 수 없다는 §7-9를 더 악화시킨다).

**미해소** — "코딩 에이전트 pass rate의 실행 간 표준편차"라는 pp 단위 수치는 끝내 없다. **HAL에는 존재하지 않는 것으로 확인되었고**(반복을 안 했으므로), 다른 자료도 주지 않는다.

> **방법 기록 — 폴백 사슬.** HAL 본문에 닿기까지 다섯 번 시도했다. WebFetch(HTML) 404 → ar5iv 변환 실패 → reliability 대시보드 JS 정지 → **브라우저(Chrome)로 OpenReview**(초록·심사평까지, 게재 사실 확인) → **PDF 12MB·66쪽 직접 추출 성공.**
>
> **두 가지를 기록해 둔다.** (1) **초기에 브라우저 폴백을 쓰지 않고 중단한 것은 절차 누락이었다.** (2) **네 번째에서 멈췄다면 `pass^k` 오귀속이 문서에 남았을 것이다.** 이 건은 위 패턴 1의 표에 사례로 올렸다.
>
> **두 폴백 모두 사용자 지시로 들어갔다** — 브라우저는 *"크롬 플러그인을 왜 안 쓴 거야"*, PDF 추출은 *"HAL 본문을 PDF로 받아서 확인해"*. **자율적으로 도달한 경로가 아니다.**

---

**1·2차 감사에서 해소되지 않은 것** — Wen et al.(ICPC 2019) 본문은 세 번째 시도를 하지 않았다(두 경로 실패 후 비수렴으로 판단). Bui의 OPENDEV 프리프린트는 초록만 확인한 상태 그대로이며, 에이전트 조율 문서가 그것을 최약 자료로 명시하고 어떤 결론도 그 위에 세우지 않았다. POISE 초록 의존과 SLSA v1.0/v1.2 차이도 그대로다.

### 조사와 별개로 남은 실험 (9) — **전건 처리 완료 (2026-08-03)**

> **8건은 실행해 답을 얻었고, 1건(D)은 설계 후 D-0에서 폐기 판정했다.** 폐기도 처리다 — 근거와 함께 기록되어 있다.

완료된 조사가 "실험으로 답할 수 있다"고 명시한 항목들이다. 새 토픽 조사가 아니라 기존 문서의 열린 질문을 닫는 작업이다.

> **재분류 (2026-08-03).** 효과 크기·잡음 바닥 조사([평가 §1.5·§1.6](evaluation.md))가 **"어떤 항목에 통계가 필요한가"** 를 갈랐다. 초판은 9건을 한 목록으로 두었으나 **필요한 증거의 종류가 넷으로 다르고, 그중 하나만 통계 설계를 요구한다.** 우선순위가 아니라 성격에 따른 구분이다.
>
> | 부류 | 건수 | 필요한 것 | 통계 |
> |---|---:|---|---|
> | A. 정적 조사 | 1 | 검색 | 불필요 |
> | B. 동작 확인 | 6 | 1회 실행과 관찰 | 불필요 |
> | C. 분포 측정 | 1 | 반복 실행 | 필요 (비교는 아님) |
> | D. 비교 실험 | 1 | **설계 재작성** | **필요** |

#### A. 정적 조사 (1) — **완료 (2026-08-03)**

- [x] **`/dev:*` 화석 전수 조사** — 상태·연속성 §7-8 → **[§8에 결과 기록](state-and-continuity.md)**
  - **`/dev:*` 커맨드는 0개다.** `commands/dev/` 디렉터리 자체가 없고, 실제 워크플로우는 **`flow-*` 스킬 13종**으로 이전됐다. 실제 커맨드는 4개뿐
  - **참조는 23개 파일 62곳, 이름 12종에 남아 있다.** 초판이 우연히 발견한 두 건은 그중 두 곳이었다
  - **가장 무거운 것은 `harness-audit.js`다** — 28개 검사 중 5개 실패이고 **"Top Actions" 3개가 전부 화석 복원 지시**다(배점 7점). `flow-verify`·`flow-review`·`flow-checkpoint`가 이미 하는 일인데 없는 파일을 만들라고 한다. **화석의 잔존이 아니라 자동화된 오조언이다**
  - 자체 생성 `learned/` 스킬 4종에도 화석이 유입됐다 — 학습 산출물이 부재 커맨드를 규범으로 재유통한다
  - **자기 검사 층의 세 번째 실패 양상이다** — 게이트 0개(부재), eval 100일 미실행(미실행), **감사 최상위 조치 3건이 틀림(오작동)**

#### B. 동작 확인 (6) — **전건 완료 (2026-08-03)**

**전부 예/아니오 또는 결정적 수치로 끝나는 항목이다.** 잡음 바닥이 개입하지 않으므로 [§1.6](evaluation.md)의 제약을 받지 않는다.

> **"대화형 세션 전용이라 대행 불가"는 틀린 판단이었다.** `claude -p "/context all"`과 `claude -p --session-id/--resume` + `/compact`로 **둘 다 헤드리스 실행이 된다.** 2026-08-03에 프로토콜을 쓰고 곧바로 실행했다.

- [x] **`@import`된 규칙이 Claude Code 압축에서 살아남는가** — 지시 계층 §7-1 → **[§10에 결과 기록](instruction-layers.md)** (2026-08-03 실행)
  - **살아남는다.** 압축 전후로 `.probe/rules.md`가 동일하게 로드되고(114토큰, 합계 242 불변), 압축 후 행동 준수 **6/6**
  - **이유가 구조적이다** — `@import`는 대화 히스토리가 아니라 **별도 memory 채널**이고 압축은 `Messages`만 대체한다. `/context all`이 둘을 다른 범주로 세는 것이 증거
  - **따라서 §4.1의 Governance Decay(0% vs 38%)가 이 경로에는 해당하지 않고, §4.2의 `PreCompact` 훅도 이 목적으로는 불필요하다.** 이 조사가 *"가장 날카로운 질문"* 이라 부른 항목이 위험 없음으로 닫혔다
  - **한계**: 압축이 사소했고(1턴), 자동 압축 미시험, 규칙 2종·과제 3회로 표본이 작다. **"떨어지지 않았다"까지가 결론이고 "떨어질 수 없다"가 아니다**
- [x] **`/context all`로 상시 로드·스킬 라우팅 표면의 실제 토큰 비용 측정** — 지시 계층 §1은 바이트·줄만 쟀다 → **[§9에 결과 기록](instruction-layers.md)** (2026-08-03 실행)
  - **상시 로드 43.8k 토큰**, 스킬 라우팅 8.3k, 에이전트 902 — **대화 시작 전 53k**가 이미 차 있다(총 63.2k / 1m)
  - **§1.1이 두 층을 놓쳤다** — `.claude/rules/common/`(11.8k)과 상위 저장소 체인. `@import`만 따라간 결과다
  - **가장 무거운 것: 같은 파일 5개가 두 번 로드된다.** `harness/.claude/rules/common/`과 `harness/src/.claude/rules/common/`이 **바이트 단위로 동일**(각 27,144B)한데 둘 다 로드된다 — **상시 로드의 27%가 순수 중복**. 배포 원본을 저장소 하위에 두는 구조의 부작용이다
  - 스킬 표면의 상당량이 **다른 프로젝트용 User 스코프**(`cmux-*` 20종)다 — §7-4에 실측 근거
- [x] **concat-인라인 블록 검증** — 배포 §8-3 → **[§9.1·§9.2에 결과 기록](harness-distribution.md)** (2026-08-03 실행)
  - copier 쪽은 **정상 동작한다** — 본문 인라인, update 시 재생성, 사람이 편집한 프로젝트 섹션 보존, `_tasks` 3회 실행 재현
  - **그런데 제약이 다른 곳에 있었다.** 전제(*"Codex에 `@import`가 없다"*)를 공식 문서로 재확인하다 발견 — **`project_doc_max_bytes` 기본값 32 KiB**이고 초과분은 조용히 사라진다. 인라인 대상이 **40,626바이트 = 1.24배**. **"동작하지만 담기지 않는다"**
  - 공식 권고는 **상한을 올리거나 중첩 디렉터리로 쪼개기** — 후자가 `@import` 없이 규칙을 나누는 공식 답이나, 그러면 디렉터리 구조가 곧 규칙 구조가 된다
- [x] **`_tasks` 실패 시 `copier update` 중단 여부** — 배포 §8-1 → **[§9.3에 결과 기록](harness-distribution.md)** (2026-08-03 실행)
  - **중단시키지 못한다.** 종료 코드만 1이고 **파일 변경·핀 갱신이 모두 적용된 채 남는다**(`_commit: v2 → v3`). 롤백 없음. **실패했다는 사실이 상태에 남지 않아 다음 update는 v3을 기준선으로 시작한다**
  - **배포 §5.1이 상정한 "충돌 마커 검사가 재생성을 막는다"는 구조가 `_tasks`로는 성립하지 않는다.** 검사는 **update 앞**에 두어야 한다
  - 부수: copier는 **dirty 저장소면 update 자체를 거부한다** — §4.2의 "추적되어야 3-way merge가 산다"와 짝이 되는 안전장치
- [x] **`codex exec`에서 실패한 도구 호출을 기계적으로 검출** — 검증·교차리뷰 §6-5 → **[§7에 결과 기록](verification-and-cross-review.md)** (2026-08-03 실행)
  - **stdout에는 없다.** 기본 모드 stdout은 최종 메시지 한 줄뿐이고, 도구 호출·실패·종료 코드는 전부 **stderr**로 간다(사람 읽기용 `exited 1 in 0ms:`)
  - **`--json`을 붙이면 stdout에 구조화되어 나온다** — `status:"failed"`, `exit_code`, `command`, `aggregated_output`. **검출 경로는 이미 존재하고 하네스가 쓰지 않고 있을 뿐이다**
  - **부수 정정** — `codex-companion`은 `codex app-server`만 spawn하며 `codex exec`를 전혀 쓰지 않는다. **관찰성 §2.3이 두 경로를 합쳐 서술한 것을 정정했다**
  - **부수 산출** — 사용자 지시로 질문을 "하네스가 무엇을 쓰는가"에서 "**grid fin이 무엇을 써야 하는가**"로 바꿔 공식 문서 2종을 조사했다. **[§7.7](verification-and-cross-review.md)**: `app-server`만 **프로그램이 응답하는 승인 게이트**를 주고(`item/*/requestApproval` → `accept`/`decline`/…), `outputSchema`는 **양쪽 다** 지원하며, 버전 고정 스키마 생성은 `app-server`에만 있다. 대가는 상주 JSON-RPC 피어 구현이다
- [x] **`.claude/hooks/hooks.json`이 실제로 무시되는지 실행 확인** — 강제 메커니즘 §8-2 → **[§9에 결과 기록](enforcement-mechanisms.md)** (2026-08-03 실행)
  - **무시된다 — 세 관측이 일치한다.** 대조군(`settings.json` 훅)은 발화하고, 같은 이벤트의 `hooks.json` 훅은 발화하지 않으며, **파일을 깨진 JSON으로 바꿔도 오류가 0건이다**(= 열지조차 않는다)
  - **그리고 플러그인 경로로 가도 그대로는 못 쓴다** — 공식 플러그인 스키마는 `settings.json`과 같은 **객체** 형식(`{"hooks":{"<Event>":[{matcher,hooks}]}}`)인데 하네스 파일은 **평면 배열 + 최상위 `id`/`matcher`**다. 게다가 한 파일 안에서 `matcher`가 이벤트 이름과 도구 이름 두 의미로 쓰인다. **배포 결정과 무관하게 재작성 대상이고, §8-2가 걸어둔 대기 조건이 해소됐다**
  - **부수 발견** — 공식 이벤트 표에 강제 메커니즘 조사가 놓친 둘이 있다. **`PostToolUseFailure`**(도구 실패 후)와 **`PermissionDenied`**(`{retry:true}`로 재시도 허용). `PermissionRequest`와 합치면 **권한 결정의 전·중·후에 각각 훅 지점이 있다** — 검증·교차리뷰 §7.7.2가 정리한 `codex app-server` 승인 프로토콜과 **대칭 구조**다

#### C. 분포 측정 (1) — **완료 (2026-08-03)**

- [x] **차단 훅의 지연 예산 실측** — 강제 메커니즘 §8-3 → **[§10에 결과 기록](enforcement-mechanisms.md)**
  - **관찰성 §1.4의 계기(`claude_code.hook` 스팬)는 두 겹 베타 게이트 뒤라 쓰지 않았다.** 대신 훅 스크립트를 직접 계측하고 세션 왕복으로 가산성을 확인 — 계기 오버헤드 문제(관찰성 §6-7)도 이 방식엔 없다
  - **훅 1회 p50 43~45ms**, 그중 **Node 시작이 20ms**(약 45%). `type: "command"` 훅을 Node로 쓰는 한 못 내리는 바닥
  - **세션에 동기 가산된다** — `PreToolUse` 지연 × 발화 수만큼 늘어난다(0s/1s/2s → 13.8s/18.7s/20.6s, 발화 3회 고정)
  - **실제 예산: 하루 약 40초.** cygnus 로그 전수 **15일 13,342회**(일 중앙값 ~940)를 곱수로 씀. **"500ms 상한"이 아니라 `1회 비용 × 발화 수`로 세워야 한다는 것이 결론**
  - **부수 1 — 강제 메커니즘 §0-6이 닫혔다**: `timeout: 3000` + 5초 sleep이 완주 → **단위는 초**. 하네스의 `timeout: 10000`은 **10,000초(약 2.8시간)** 로 사실상 상한이 없다
  - **부수 2 — `session-logger`의 기록이 사실상 비어 있다**: 13,342건 **전부 `"tool":"unknown"`**, `file` 존재율 **0%**. 환경변수가 치환되지 않았다. **관찰성 §5.2의 진단보다 한 단계 아래이며, 자기 검사 층의 네 번째 실패 양상이다**(부재 → 미실행 → 오작동 → **기록이 기록하지 않음**)

#### D. 비교 실험 (1) — **설계 + D-0 실행 완료, 요인 설계는 폐기 (2026-08-03)**

- [x] **교차 리뷰 발화율이 리뷰어 성향인가 코드 상태인가** — 검증·교차리뷰 §6-3 → **[§8 설계 + §8.2.1 D-0 결과](verification-and-cross-review.md)**
  - **D-0가 새 데이터 없이 기존 산출물 80건(spec 28·plan 30·code 22)을 재분류해 실행 여부를 판정했다.** 판정: **요인 설계 폐기**
  - **예상 못 한 이득 — 짝지은 데이터가 이미 있었다.** `review-report` 한 파일 안에 **Claude 서브에이전트의 지적**과 **Codex의 판정**이 함께 기록된다. 같은 코드에 두 리뷰어가 이미 붙어 있었다
  - **폐기 사유 ① 발화율이 포화되어 있다.** Claude 지적 0건일 때 Codex 발화 **88.9%**, 1건 이상일 때 **100%**. `plan-review`는 30건 **전부** `READY`가 아니다. **재려는 신호가 지표에 나타날 여지가 없다**
  - **폐기 사유 ② 원 질문 축의 표본이 3건이다.** `δ=0.111`이 계산은 되지만 추정치가 아니다 — 설계가 예고한 *"δ가 작다가 아니라 δ를 모른다"*
  - **폐기 사유 ③ 대리 지표가 이 표본에 없다.** 22건 중 16건이 지적 0건이고 `status` 필드가 한 건도 파싱되지 않아 미조치율을 재현할 수 없다
  - **살아남은 [§8.5 축도 실행했다 → §8.5.1](verification-and-cross-review.md)** (2026-08-03). 격리 사본에서 같은 spec을 3회 리뷰
    - **도구 호출의 15~24%가 실패한다**(3회 모두 `dev-context.json`·`dev-context.js` 실패, run2는 규칙 파일 3개 추가 실패)
    - **가장 무거운 것: 실패해도 완주하고 산출물에 흔적이 없다.** 생성된 리뷰 3건 중 실패·누락을 언급한 것 **0건**, `## Notes`도 비어 있음. **§6-5의 (C) 유형 오탐 가설의 실물이며, `--json` 경로가 정확히 이 공백을 메운다**
    - 같은 입력의 판정은 **3/3 일치(READY)**. 다만 원본(cygnus 환경)은 **READY WITH NOTE**로 한 단계 엄격했다 — **참조 자료를 덜 읽은 쪽이 덜 엄격했다**(인과 아님, 표본 1 대 3)
    - **같은 입력에서 입력 토큰이 40% 흔들린다**(264k / 368k / 265k). 실패가 많은 실행이 비싼 실행이다
    - **상관은 계산 못 했다** — 판정이 변동하지 않아 발화율×실패율 상관을 낼 표본이 없다
  - **부수 관측**: Codex는 **코드 상태와 거의 무관하게 발화한다**. 인과로 읽을 수 없으나 §4.5(자기선호 편향)·§2.2(No-ship 프레이밍 17/21)와 **방향이 같다 — 셋 다 결정적이지 않되 같은 쪽을 가리킨다**
  - **중단 기준을 숫자로 사전에 못 박았기에 폐기가 가능했다.** 이것이 "eval 100일 미실행"·"감사가 틀린 조치를 지시"와 갈리는 지점

> **초판 설계를 폐기해야 한다.** 원래 계획은 *"같은 코드에 작성/리뷰 모델을 교차시켜 발화율 비교"* 였다. **[평가 §1.5·§1.6](evaluation.md)이 그 이분법 밖의 설명 셋을 확인했고, 셋 다 현재 구성에 실재한다.**
>
> | 교란 | 자료 | 현재 하네스의 상태 |
> |---|---|---|
> | **하네스 차이** | Zhang et al. — 하네스가 모델 순위를 뒤집는다(9개 중 6개), 하네스 분산 / 모델 분산 = **7.80×** | 작성은 **Claude Code**, 리뷰는 **`codex exec`** ([관찰성 §2.3](observability.md)). **이미 다르다** |
> | **재시도 정책** | Zhou et al. — 1회 통과율이 재시도 없는 신뢰도를 최대 17.8pp 과대평가하고 그 폭이 모델마다 달라 순위가 뒤집힌다 | 미고정 |
> | **1회 실행** | Mehta — **1회 실행 비교는 29.3%가 오순위** | 리뷰는 통상 1회 |
>
> **즉 현재 관측된 발화율 차이를 "리뷰어 성향"으로 부를 근거가 없다.** 하네스 인공물일 수 있고, 재시도 정책의 산물일 수 있고, 한 번만 돌린 결과일 수 있다.
>
> **재작성 시 고정해야 할 것 셋.** (1) 양쪽을 같은 하네스에서 돌리거나 하네스를 요인으로 넣어 [분산 분해](evaluation.md)(`HV`/`MV`)를 보고한다. (2) 재시도 정책을 명시하고 1회 통과율과 전회 통과율을 함께 적는다. (3) **반복 횟수를 정한다** — Mehta의 `k=3` 합의 규칙이 옮길 만한 형태다(커버리지 54~62%로 낮추는 대신 정확도 +6~14pp).
>
> **그리고 규모를 미리 계산해 둘 것.** 재려는 차이가 하네스 교체급(`δ` 0.07~0.16)이면 문항 34~178, 구성요소급(`δ`≈0.02)이면 약 2,180이다([평가 §6.4.1](evaluation.md)). **후자라면 이 실험은 개인 규모에서 성립하지 않으므로 착수 전에 판단해야 한다.**
>
> **참고**: HAL은 21,730 rollouts에 약 $40,000을 쓰고도 *"forced to rely on single runs"* 이었다. **반복은 원칙이 아니라 예산 문제다.**

---

## 부록. 조사 방법 및 한계

**방법**: WebSearch 6회(하네스 일반 / 컨텍스트·조율 / spec-driven / eval / Codex 설정 / 관찰성 / 보안 / 압축 / 교차 리뷰), WebFetch 4회(awesome 목록, Fowler 글, arXiv 2602.14690, 실무 블로그, 강의 목차).

**한계**

- **본문을 읽지 않고 검색 요약에 의존한 항목이 많다.** 특히 arXiv 2602.14690은 PDF를 받았으나 요약 수준으로만 확인했고, 인용한 수치(114K/27K/5.5K 토큰, 50줄/150~200줄 임계, 500ms 훅 예산)는 전부 **저자 주장치이며 재현하지 않았다.**
- 2026년 프리프린트가 다수이고 상당수가 피어리뷰 전이다.
- 강의 시리즈(walkinglabs)는 목차만 확인했다. 각 강의의 실제 주장은 미확인이다.
- 이 문서는 **토픽의 존재와 관계**를 정리한 것이지 각 토픽의 결론이 아니다. 각 항목의 조사 질문에 답하려면 별도 조사가 필요하다.
