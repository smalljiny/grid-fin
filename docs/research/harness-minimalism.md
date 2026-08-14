# 하네스 미니멀리즘 — "고성능 모델일수록 제약을 적게" 주장의 근거 조사

**최초 작성**: 2026-08-03
**최종 수정**: 2026-08-03
**대상 프로젝트**: grid fin (신규 개인용 개발 하네스)
**조사 계기**: *"최신 고성능 모델을 위한 하네스에는 최대한 제약을 적게 하는 것에 대한 스터디를 본 적이 있다"* 는 기억의 출처 확인과 검증
**조사 도구**: WebSearch 5회, WebFetch 9회 (arXiv 5, 벤더 공식 3, 실무 1)
**성격**: 조사. grid fin 설계 결정은 하지 않는다. 함의는 §8에 **관측으로만** 적는다.
**§11 추가 (2026-08-03)**: 사용자 요청으로 열린 질문 2(절차/인터페이스 분리)의 **검증 프로토콜**을 붙였다. 실험 설계이지 grid fin 스펙이 아니며, **실행하지 않았다.**

선행 조사 15건에 **"하네스를 얼마나 얇게 둘 것인가"라는 축이 없다.** 개별 문서가 각자의 영역에서 "덜 하라"는 결론에 도달했으나(§8-1), 그 결론들이 하나의 주장으로 묶인 적이 없다. 이 문서가 그 공백을 메운다.

관련 문서
- [instruction-layers.md](instruction-layers.md) — 상시 로드 1,044줄 / 라우팅 표면 10,185자 실측
- [agent-orchestration.md](agent-orchestration.md) — 다중 에이전트에 대한 부정형 결론
- [repository-hygiene.md](repository-hygiene.md) — 설명 문서의 비용 +20%
- [enforcement-mechanisms.md](enforcement-mechanisms.md) — 차단 가능한 지점과 실제 배치의 역전

---

## 0. 조사 요약

| # | 관측 | 근거 등급 |
|---|---|---|
| 1 | **"모델이 강해질수록 하네스 민감도가 낮아진다"는 실측이 존재한다.** Harness-Bench(5,088 궤적, 6 하네스 × 8 모델 완전요인)가 *"stronger model backends tend to achieve higher mean scores while exhibiting lower cross-harness variance"* 를 보고 | **1차 (프리프린트, 미피어리뷰)** — §1 |
| 2 | **같은 실험에서 가장 얇은 하네스가 1등이다.** NanoBot 76.2% / 평균 68,000 토큰 vs NullClaw 64.4% / 175,100 토큰 — **더 많이 쓰고 더 못한다** | **1차 (프리프린트)** — §1.2 |
| 2b | **비교 대상 6종의 실체를 확인했다** — Claw 생태계의 개인용 에이전트들이고, 1등 NanoBot은 **코어 약 4,000줄**(HKUDS, 46.5k★), 하위권 Moltis는 **약 150,000줄**이다. 다만 **NanoBot도 메모리·MCP·다중 에이전트 위임을 다 갖는다** — 얇은 것은 기능이 아니라 코어 루프다 | **1차 확인 (이 조사)** — §1.5 |
| 3 | **그러나 실패의 주범은 "모델이 못 해서"가 아니다.** 계약·형식 위반 36.4%, 도구 복구 실패 24.6%, 근거 정합성 결손 14.6% — 셋 다 **인터페이스 문제**다 | **1차 (프리프린트)** — §1.3 |
| 4 | **"강할수록 얇게"의 단순형은 반증이 있다.** Cho 2605.26731은 하네스 민감도가 티어에 대해 **비단조**라고 보고. 다만 이 논문의 "frontier" 라벨은 Gemini 2.5 Flash·Qwen3.5-122B로, **2026-08 기준 프런티어가 아니다** | **낮음. 반례로만 취급** — §2 |
| 5 | **반대 벡터가 실재한다** — 하네스를 정교하게 깎으면 **작은 모델**이 프런티어의 89.7%를 비용 4%로 따라잡는다. 즉 "얇은 하네스"는 성능이 아니라 **모델 비용을 지불했을 때만** 사는 선택지다 | **1차 (프리프린트)** — §3 |
| 6 | 같은 논문이 조건을 명시한다 — 태스크 **다양성이 높을수록 하네스 적응 효과가 사라진다**(Spearman ρ = −0.96, 89.1% → 68.0%). grid fin은 다양성이 높은 쪽이다 | **1차 (프리프린트)** — §3.1 |
| 7 | **벤더 3사의 공식 진술이 같은 방향으로 정렬한다** — Anthropic *"smarter models require less prescriptive engineering"*, OpenAI Codex *"if you rely on complex scaffolding … you aren't scaling you are coping"*, Cognition *"just use a single-threaded linear agent"* | **1차 (공식/실무 진술)** — §4 |
| 8 | **"제약을 적게"의 공식 정식화는 "없애라"가 아니라 "고도(altitude)를 맞춰라"다.** 실패 모드가 **둘**이고 한쪽 끝은 모호함이다 | **1차 (공식)** — §4.1 |
| 9 | **얇은 하네스의 실물 상한선이 공개돼 있다** — mini-SWE-agent: 에이전트 클래스 100줄, **도구는 bash 하나**, 도구 호출 인터페이스조차 안 씀, SWE-bench Verified **>74%** | **1차 (공식 README)** — §5.1 |
| 10 | 다만 그 74%에 **모델 귀속이 없다.** README는 모델 무관 설계임을 강조할 뿐 어떤 모델의 점수인지 적지 않는다 | **1차 확인 (이 조사)** — §5.1 |
| 11 | **13개 오픈소스 코딩 에이전트를 소스 수준에서 분해한 결과, 도구 수는 0~37개로 갈리는데 능력 범주는 read·search·edit·execute 넷으로 수렴한다** | **1차 (프리프린트)** — §5.3 |
| 12 | **지시를 많이 넣으면 왜 나빠지는지의 메커니즘이 측정돼 있다** — IFScale: 지시 500개에서 최고 모델도 68%. 강한 모델은 임계까지 완벽하다가 **급락**한다(threshold decay) | **1차 (프리프린트)** — §6 |
| 13 | **검색 스니펫이 준 "Mini-SWE-Agent + Claude-Opus-4.7 68.3%, Hermes 64.6%, Claude Code 62.2%" 수치는 1차 출처에서 확인되지 않았다.** 인용 금지 | **검증 실패 (이 조사)** — §9 |
| 14 | **§7.2 가설의 검증 설계를 붙였고, 그 결과 사용자의 원 질문이 개인 규모에서 직접 검정 불가임이 확정됐다.** 모델 강도 × 제약 종류 **상호작용**은 주효과 대비 약 4배 표본을 요구한다 | **설계 (§11, 미실행)** — §11.5 |

---

## 1. 1차 근거 — Harness-Bench (arXiv:2605.27922, 2026-05-27)

Peking University + Qiyuan Tech. **이 시리즈에서 사용자의 기억과 가장 직접적으로 대응하는 자료다.**

### 1.1 설계

- 오프라인 샌드박스 태스크 **106개** / 8개 워크플로우 범주(소프트웨어 엔지니어링, 데이터 분석, 오피스 등)
- **완전요인 설계**: 구성 가능한 하네스 6종 × API 모델 백엔드 8종 = **5,088 궤적** (+ Codex 106회 별도 참조)
- 태스크 환경·예산·타임아웃·평가자를 고정하고 각 하네스의 고유 동작은 보존
- 점수 = 완료 + 보안 + 프로세스 신호(견고성·도구 사용·일관성)

모델 백엔드 8종: `claude-opus-4.6`, `claude-sonnet-4.6`, `gemini-3.1-pro-preview`, `qwen3.6-plus`, `glm-5.1`, `kimi-k2.5`, `gpt-5.4`, `deepseek-v4-flash`.

### 1.2 하네스 순위 — 얇은 쪽이 이긴다

| 하네스 | 종합 점수 | 평균 토큰 |
|---|---|---|
| **NanoBot** (초경량) | **76.2%** | **68,000** |
| Hermes | 71.2% | 139,700 |
| Moltis | 68.8% | — |
| NullClaw | 64.4% | 175,100 |
| ZeroClaw | 61.4% | 133,200 |
| OpenClaw | 52.4% | — |

최상·최하 격차 **23.8%p**. 동일 태스크·동일 모델에서 나온 숫자다. **하네스가 모델만큼 중요하다**는 것이 이 표의 1차 결론이고, **그 중요함의 방향이 "두껍게"가 아니다**는 것이 2차 결론이다. NanoBot은 Hermes의 절반, NullClaw의 39% 토큰으로 12%p 앞선다.

참조로 돌린 Codex(모델 결속형 전용 코딩 에이전트)는 80.4%로 최고였다. **모델과 하네스를 함께 훈련한 경우가 조립형 최고보다 높다** — §4.2의 Codex 팀 진술("모델 수준에서 푼다")과 같은 방향이다.

### 1.3 그런데 실패는 인터페이스에서 난다

| 실패 유형 | 비중 |
|---|---|
| 계약/형식 위반 | 36.4% |
| 도구 복구 실패 | 24.6% |
| 근거 정합성 결손 | 14.6% |

**모델의 추론 실패가 아니다.** 논문은 에이전트 능력을 모델이 아니라 **"model–harness configuration"** 단위로 보고해야 한다고 주장하며, 결정적 요인으로 *execution alignment*(추론·워크스페이스 상태·도구·평가 기준의 대응 유지)를 든다.

### 1.4 사용자 기억과 대응하는 문장

> "stronger model backends tend to achieve higher mean scores while exhibiting lower cross-harness variance"
> → *"stronger models may be more tolerant of differences in prompting, tool interfaces, state management, and recovery behavior."*

**주의**: 이것은 "강한 모델에는 제약을 줄여야 성능이 오른다"가 아니라 **"강한 모델은 하네스 차이에 덜 흔들린다"** 는 진술이다. 전자는 처방, 후자는 관측이다. 후자가 참이면 따라오는 것은 "제약을 줄여도 손해가 작다"이지 "줄이면 이득이다"가 아니다. **비용·토큰 측면의 이득(§1.2)은 별개 근거로 성립한다.**

### 1.5 하네스 6종의 실체 — 확인됨 (이 조사)

비교 대상 6종은 실재하는 오픈소스 프로젝트다. **2026-01-30 OpenClaw 공개 이후 6주 만에 형성된 "Claw 생태계"의 개인용 에이전트 프레임워크들**이고, 코딩 전용 하네스가 아니다.

| 하네스 | 실체 | 규모 |
|---|---|---|
| **NanoBot** | HKUDS(홍콩대 데이터사이언스랩), Python. WebUI·터미널·챗앱, 도구·장기 메모리·MCP·모델 라우팅·다중 에이전트 위임·스케줄 자동화 포함 | **코어 약 4,000줄**, GitHub 46.5k★ |
| OpenClaw | 로컬 우선 에이전트 플랫폼, 다채널 통합·영속 메모리 | 생태계의 원본 |
| ZeroClaw | 에이전트 런타임을 **Rust로 재작성**, 작은 바이너리·저의존 | — |
| NullClaw | **Zig**, 최대한 컴팩트, 무시할 만한 런타임 오버헤드 | — |
| **Moltis** | 엔터프라이즈 지향. Prometheus 메트릭, OTel 트레이싱, **라이프사이클 훅 15종**, TTS 8·STT 7 제공자 | **약 150,000줄** |
| Hermes | Claw 생태계 셸 8종 중 하나 | — |

**이 확인이 §1.2를 크게 강화한다.** "얇은 하네스가 이겼다"는 추상이 아니라 **약 4,000줄이 약 150,000줄을 이겼다**는 구체다.

**동시에 중요한 단서를 준다** — NanoBot은 기능이 없는 하네스가 아니다. 메모리·MCP·다중 에이전트 위임·모델 라우팅을 다 갖고 있다. 얇은 것은 **코어 에이전트 루프 경로**이지 기능 목록이 아니다. 프로젝트 설명이 명시한다 — 메모리와 스킬은 *"오케스트레이션 레이어가 되는 대신 컨텍스트로만 끌어온다."*

> **"제약을 적게"가 "기능을 적게"가 아니다.** 1등 하네스는 기능이 빠진 쪽이 아니라 **기능이 제어 흐름에 개입하지 않는 쪽**이었다.

### 1.6 등급 한계

미피어리뷰 프리프린트이고 **재현 검증이 없는 단일 출처**다. 하네스 6종의 실체는 위에서 확인했으나 논문의 점수표 자체는 독립 검증되지 않았다. 게다가 §9에서 보듯 이 논문에 귀속된 **가짜 수치 세트가 검색 계층에 유통되고 있다.** 이 문서의 관측 #1·#2·#5는 이 한 출처에 의존한다 — 실증 척추로 취급하지 않는다.

**적용 범위 주의**: 106개 태스크가 8개 워크플로우 범주(SW 엔지니어링·데이터 분석·오피스 등)에 걸쳐 있고 비교 대상이 **범용 개인 에이전트**다. grid fin은 코딩 하네스이므로 대상이 완전히 겹치지 않는다.

---

## 2. 반례 — 비단조 주장 (arXiv:2605.26731, 2026-05-26)

"It's Not the Capability: Harness Sensitivity Is Non-Monotone Across LLM Agent Tiers" (Yong-eun Cho, KailosLab). **"강할수록 얇게"의 단순형을 정면으로 반박하는 유일한 자료라 실었다.**

HEAT-24(합성 24태스크, git 기반 워크스페이스 검증) 위에서 모델 6종 × 하네스 3조건(light / balanced / strict) × 432회.

| 모델 (논문 라벨) | 결과 |
|---|---|
| Gemini 2.5 Flash ("frontier chat") | light 95.8% → **strict에서 29~38%p 하락**해 58~67% |
| Qwen3.5-122B ("frontier reasoning") | **strict 91.7% > balanced 75.0%** — 방향이 반대 |
| GPT-OSS-120B | light·balanced 95.8%, strict 87.5% |
| Gemma4:e2B (2B) | 세 조건 모두 91.7% — 하네스 무관 |

즉 **강한 추론 모델이 오히려 엄격한 하네스에서 더 잘한 사례가 있다.**

### 2.1 이 반례를 어디까지 믿을지

- 저자 1인, 소속 "KailosLab", 미피어리뷰
- 태스크 24개 **합성**, 총 432회 — Harness-Bench의 1/12 규모
- **결정적 한계: "frontier" 라벨이 Gemini 2.5 Flash와 Qwen3.5-122B다.** 2026-08 기준 이들은 프런티어 티어가 아니다. 따라서 이 논문은 **중상위 티어에 대한 증거이지 사용자가 물은 "최신 고성능 모델"에 대한 증거가 아니다.**

**취급**: Harness-Bench와 대등하게 놓지 않는다. "티어를 가로지르면 단조가 아닐 수 있다"는 **가설의 존재**만 기록한다.

### 2.2 그런데 실패 유형은 Harness-Bench와 같다

Cho의 지배적 실패 패턴은 *"format violations rather than task incomprehension"* — **모델이 태스크를 이해 못 한 게 아니라 복잡한 프롬프트 아래서 출력 형식을 못 맞춘다.**

**두 논문은 헤드라인이 충돌하는데 실패 데이터는 일치한다.** 이것이 §7의 종합 근거다.

---

## 3. 반대 벡터 — 하네스를 깎아 작은 모델을 살린다 (arXiv:2607.08938, 2026-07-09)

"Better Harnesses, Smaller Models: Building 90% Cheaper Agents via Automated Harness Adaptation" (Chenyang Yang, Xinran Zhao, Tongshuang Wu, Christian Kästner — CMU 계열).

Gemini 3.1 Pro 기반 메타 에이전트가 궤적에서 실패를 진단하고 하네스 편집을 제안하는 루프. 업무 태스크 7종 × SLM 3계열.

| 결과 | 수치 |
|---|---|
| 최고 SLM(Gemma-4-26B)이 회수한 LLM 정확도 | **89.7%**, 비용 **4%** |
| 격차를 완전히 메운 태스크·모델 쌍 | 21쌍 중 **7쌍** |
| 유의한 개선 | 21쌍 중 **16쌍** |
| 강한 SLM vs 약한 SLM 개선폭 | **+48.8%p vs +15.5%p** |

**이 논문은 "제약을 적게"의 반대를 실증한다** — 하네스를 두껍게 깎으면 싼 모델로 비싼 모델을 대체할 수 있다.

### 3.1 다만 조건이 명시돼 있다

- **태스크 다양성과 적응 효과의 상관이 ρ = −0.96.** 통제 실험에서 다양성을 낮음→높음으로 옮기자 89.1% → 68.0%. **반복적이고 좁은 업무일수록 하네스 튜닝이 산다.**
- 하네스는 **없는 능력을 대체하지 못한다**(+48.8 vs +15.5의 해석).
- 논문 자체 결론: *"frontier models need less architectural support for identical tasks."*

### 3.2 grid fin에 대한 함의 방향

grid fin은 **다양성이 높은 쪽**(개인 개발 하네스, 태스크가 반복적이지 않음)이고 **프런티어 모델을 쓰는 쪽**이다. 두 축 모두 §3의 반대 벡터가 약해지는 조건이다. **즉 이 논문은 사용자의 전제를 뒤집기보다 그 적용 범위를 확정해준다.**

---

## 4. 벤더·실무의 1차 진술

### 4.1 Anthropic — 정식화는 "제거"가 아니라 "고도"

[Effective context engineering for AI agents](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents) — 시스템 프롬프트를 **"right altitude"** 에 두라고 하고, 실패 모드를 **둘** 든다.

| 실패 모드 | 서술 |
|---|---|
| 너무 낮은 고도 | 정확한 에이전트 동작을 끌어내려 **하드코딩된 복잡하고 부서지기 쉬운 로직**을 프롬프트에 박는다 → 취약성과 유지보수 부담 |
| 너무 높은 고도 | 모호한 고수준 지침 → 구체적 신호가 없고 공유 맥락을 잘못 가정 |

목표: *"specific enough to guide behavior effectively, yet flexible enough to provide the model with strong heuristics."*

그리고 사용자 기억과 가장 가까운 문장이 결론부에 있다:

> **"smarter models require less prescriptive engineering, allowing agents to operate with more autonomy."**

**단, 같은 결론이 단서를 단다** — 능력이 올라도 **컨텍스트를 유한 자원으로 다루는 것은 여전히 필수**다.

도구에 대해서는: *"a human engineer can't definitively say which tool should be used in a given situation, an AI agent can't be expected to do better"* — 최소 실행 가능 도구 집합을 큐레이션하라.

[Building effective agents](https://www.anthropic.com/engineering/building-effective-agents):
- *"find the simplest solution possible, and only increasing complexity when needed"*
- *"you should consider adding complexity only when it demonstrably improves outcomes"*
- 프레임워크에 대해: *"they often create extra layers of abstraction that can obscure the underlying prompts and responses, making them harder to debug"* → *"don't hesitate to reduce abstraction layers and build with basic components"*

[Writing tools for agents](https://www.anthropic.com/engineering/writing-tools-for-agents):
- *"More tools don't always lead to better outcomes."* 고임팩트 워크플로우를 겨냥한 소수의 도구
- 오류 응답을 **프롬프트 엔지니어링하라** — 불투명한 에러 코드가 아니라 구체적·실행 가능한 개선 지시로
- 도구는 여러 연산을 내부에서 묶어 **통합**하라(`list_users`+`list_events`+`create_event` → `schedule_event`)

**주목**: 마지막 두 항목은 "제약을 줄여라"가 아니다. **인터페이스 쪽은 오히려 더 깎으라는 지시다.** §7 참조.

### 4.2 OpenAI Codex — "scaffolding is coping, not scaling"

Thibault Sottiaux(Codex) 인터뷰 [Dev Interrupted](https://linearb.io/dev-interrupted/podcast/openai-codex-thibault-sottiaux-agentic-autonomy):

> **"If you rely on complex scaffolding to build AI agents you aren't scaling you are coping."**

> "it's all about figuring out, like, you know, when is the right time to remove like, pieces of the scaffold"

구체 사례로 **컨텍스트 압축**을 든다 — 휴리스틱 요약(하네스 층)을 쓰는 대신 **여러 컨텍스트 윈도우에 걸친 장기 세션을 모델에 직접 훈련**시켰고, 그 결과 정보 소실 불만이 사라졌다. *"we decided to solve this like, you know, at the model level and, you know, we train on this like end to end."*

**이 진술의 성격**: 모델을 소유한 팀의 전략이다. **grid fin은 모델을 훈련할 수 없으므로 "모델 수준으로 옮긴다"는 선택지가 없다.** 이 팀에게 참인 것이 하네스 사용자에게 그대로 참은 아니다 — 사용자 입장의 대응 동작은 "모델이 이미 그것을 하게 되면 하네스에서 걷어낸다"이다.

### 4.3 Cognition — 단일 스레드

[Don't Build Multi-Agents](https://cognition.com/blog/dont-build-multi-agents):
- 원칙 1: *"Share context, and share full agent traces, not just individual messages"*
- 원칙 2: *"Actions carry implicit decisions, and conflicting decisions carry bad results"*
- 권고: *"The simplest way to follow the principles is to just use a single-threaded linear agent"*
- 다중 에이전트 협업은 *"only results in fragile systems"*

**[agent-orchestration.md](agent-orchestration.md)의 결론과 독립적으로 일치한다** — 그 문서는 피어리뷰 실증(다중 에이전트 "minimal performance gains", 실패율 41~86.7%)과 저장소 실측(서브에이전트 채택 4.6%)으로 같은 결론에 도달했다.

---

## 5. 얇은 하네스의 실물

### 5.1 mini-SWE-agent — 상한선의 실측

[README](https://github.com/SWE-agent/mini-swe-agent/blob/main/README.md) 본문 확인:

| 항목 | 내용 |
|---|---|
| 코드량 | *"Just some 100 lines of python for the agent class"* (환경·모델·런스크립트는 별도) |
| 도구 | *"Does not have any tools other than bash — it doesn't even need to use the tool-calling interface of the LMs."* |
| 점수 | *"Scores >74% on the SWE-bench verified benchmark"* |
| 채택 | Meta, NVIDIA, IBM, Nebius, Anyscale, Princeton, Stanford 등 |

**결정적 데이터포인트**: 도구가 bash 하나뿐이고 도구 호출 API조차 쓰지 않는 100줄 에이전트가 SWE-bench Verified 74%를 넘는다.

**단, 이 조사에서 확인한 한계** — README는 **그 74%가 어떤 모델의 점수인지 적지 않는다.** litellm 등으로 모든 모델을 지원한다는 설명뿐이다. **모델 귀속 없는 74%는 "얇은 하네스로 충분하다"의 근거로는 쓰되 "어떤 모델에서든 74%"로 읽으면 안 된다.**

설계 근거로 README가 드는 것은 성능이 아니라 셋이다 — 한눈에 이해 가능, 일상에서 쓸 만함, 확장 용이. 그리고 서브프로세스 독립 실행이 *"a big deal for the stability of the agent"* 라고 적는다.

### 5.2 Agentless — 2024년의 선례

[arXiv:2407.01489](https://arxiv.org/abs/2407.01489) (Xia, Deng, Dunn, Zhang / 2024-07 제출, 2024-10 개정). 자율 에이전트 없이 **localization → repair → patch validation** 3단 고정 파이프라인으로 SWE-bench Lite **32.00%**(96건), 이슈당 **$0.70**. 저자 질문: *"do we really have to employ complex autonomous software agents?"* — 에이전트 의사결정도 정교한 도구 사용도 **없이** 당시 에이전트 시스템들을 앞섰다.

**등급 주의**: 2024년 자료다. 32%는 GPT-4o 시대의 수치이고 현재 기준으로는 낮다. **수치가 아니라 "복잡한 스캐폴드가 필연이 아니다"라는 구조적 주장의 선례로만 쓴다.** 그리고 Agentless는 "제약이 적은" 시스템이 아니라 **고정된 절차**다 — §7에서 다시 다룬다.

### 5.3 소스 수준 분해 — 무엇이 수렴하고 무엇이 갈리는가

"Inside the Scaffold: A Source-Code Taxonomy of Coding Agent Architectures" ([arXiv:2604.03515v2](https://arxiv.org/html/2604.03515v2), Benjamin Rombaut, 2026-04-10). 오픈소스 코딩 에이전트 **13종**을 소스 코드 수준에서 3계층 12차원으로 분해.

| 관측 | 내용 |
|---|---|
| 제어 전략의 폭 | 고정 파이프라인(Agentless) ~ 완전 MCTS(Moatless Tools) |
| **도구 수의 폭** | **0개**(Aider, 사용자 주도) ~ **37개 액션 클래스**(Moatless Tools) |
| 컨텍스트 검색 패러다임 | 7종 |
| **수렴 지점** | 도구 수가 제각각인데 **능력 범주는 read·search·edit·execute 넷으로 일관** |
| 또 다른 수렴 | 5개 에이전트가 **독립적으로 `str_replace_editor` 인터페이스에 도달** |
| 분류 불가 | *"scaffold architectures resist discrete classification"* — 13종 중 11종이 여러 제어 루프 원시요소를 조합 |

**저자가 성능 주장을 하지 않는다는 점이 중요하다** — 논문은 파일 경로와 줄 번호를 증거로 제시할 뿐이고, **모델 능력과 스캐폴드 설계가 기존 벤치마크에서 교란(confounded)돼 있음을 명시적으로 인정한다.** §1·§2의 프리프린트들을 읽을 때 걸어야 할 할인율이 여기 적혀 있다.

**grid fin에 직접 쓸 관측**: 도구 개수는 0~37로 갈려도 **덮는 능력은 넷**이다. 도구 수는 자유도이지 필요조건이 아니다.

---

## 6. 왜 제약이 성능을 깎는가 — 메커니즘

"How Many Instructions Can LLMs Follow at Once?" ([arXiv:2507.11538](https://arxiv.org/pdf/2507.11538), Jaroslawicz et al., IFScale). 지시 밀도를 10 → 500까지 10단위로 올리며 20개 SOTA 모델(7개 제공사)을 측정.

| 관측 | 수치 |
|---|---|
| 지시 500개에서 **최고 프런티어 모델**의 정확도 | **68%** |
| 열화 패턴 | 3가지로 갈림 |
| 위치 편향 | **앞쪽 지시로 편향** |

열화 패턴 3종이 이 조사에 중요하다:

| 패턴 | 해당 모델(논문 시점) |
|---|---|
| **임계 붕괴**(threshold decay) — 임계 밀도까지 거의 완벽하다가 분산 급증·준수 급락 | **추론 모델** (o3, gemini-2.5-pro) |
| 선형 감소 | gpt-4.1, claude-sonnet-4 |
| 지수 감소 | gpt-4o, llama-4-scout |

**강한 모델일수록 "임계 붕괴" 쪽이다.** 이것은 사용자의 전제를 지지하면서 동시에 위험을 준다 — 지시를 늘려도 한동안 아무 손해가 안 보이다가 **어느 지점에서 갑자기 무너진다.** 점진적 열화가 아니므로 **"지금까지 괜찮았다"가 안전 근거가 되지 않는다.**

[instruction-layers.md](instruction-layers.md)의 실측(상시 로드 1,044줄, 라우팅 표면 10,185자)이 이 축 위 어디쯤인지는 미측정이다 — §10 열린 질문 1.

---

## 7. 실패가 몰리는 곳 — 관측 하나와 가설 하나

### 7.1 관측 — 헤드라인은 충돌하는데 실패 데이터는 일치한다

§1과 §2는 결론이 반대다. 그런데 **어디서 실패하는지는 같다.**

| 출처 | 지배적 실패 |
|---|---|
| Harness-Bench | 계약/형식 위반 **36.4%** + 도구 복구 실패 **24.6%** |
| Cho 2605.26731 | *"format violations rather than task incomprehension"* |

두 실패 모두 **모델이 무엇을 할지 몰라서**가 아니라 **하네스와 대화하는 방법을 못 지켜서** 생긴다. 서로 반대 결론을 낸 두 실험이 실패 귀속에서는 일치한다는 점에서, **이것이 이 조사에서 가장 견고한 관측이다.**

여기까지가 자료가 말한 것이다. 아래는 아니다.

### 7.2 가설 (이 문서가 붙인 것) — 절차적 제약 / 인터페이스 계약

§7.1이 사실이라면 "제약을 많이 두느냐 적게 두느냐"보다 **어떤 종류의 제약인가**가 갈림축일 수 있다.

| 구분 | 성격 | 관련 자료 |
|---|---|---|
| **절차적 제약** — 단계별 워크플로우 규정, 라우팅, 특수 케이스 분기, 예외 처리 계층 | 모델의 의사결정을 대신함 | Sottiaux "coping", Anthropic "less prescriptive", NanoBot이 토큰 39%로 이김 |
| **인터페이스 계약** — 출력 형식, 도구 스키마, 오류 응답 형태, 복구 경로, 권한 게이트 | 의사결정을 대신하지 않고 **표현할 칸을 정함** | §7.1의 실패 61%가 여기. Anthropic 도구 지침(오류 응답 프롬프트 엔지니어링, 도구 통합) |

### 7.3 이 가설을 아직 믿으면 안 되는 이유

**어느 자료도 두 축을 독립적으로 움직이지 않았다.** Cho의 light/balanced/strict조차 절차와 형식을 함께 움직였으므로 어느 쪽이 효과를 냈는지 분리되지 않는다.

그리고 **이 조사가 든 세 사례 모두 이 렌즈에 깔끔히 들어맞지 않는다:**

- **mini-SWE-agent** — 절차적 제약은 거의 0(도구 하나, 100줄)이라 앞쪽 칸에는 맞는다. 그러나 **도구 호출 인터페이스 자체를 쓰지 않는다**(§5.1). 이는 인터페이스 계약을 조인 게 아니라 **가장 느슨하게 둔 것**이다. 얇은 하네스가 인터페이스를 조여서 이겼다는 근거로 쓸 수 없다.
- **Agentless** — 3단 고정 파이프라인은 절차적 제약의 극단인데도 당시 에이전트들을 이겼다. 2024년 자료라는 시점 차이로 설명할 여지는 있으나(§3의 "약한 모델일수록 하네스 적응이 산다"와 같은 방향), 그 설명 자체가 가설이다.
- **Cho의 "strict가 이긴" 추론 모델** — 위의 미분리 문제로 판정 불가.

**세 사례 전부에 단서를 달아야 성립하는 구분은 발견이 아니다.** §7.2는 이 문서가 제안하는 가설로만 기록하고, 검증 설계는 §10 열린 질문 2에 남긴다. **grid fin 설계에서 이 구분을 근거로 쓰지 않는다.**

---

## 8. grid fin에 대한 관측 (설계 아님)

### 8.1 선행 조사 4건이 이미 같은 방향에 도달해 있었다

이 조사의 새로움은 근거가 아니라 **묶임**이다.

| 선행 문서 | 도달한 결론 |
|---|---|
| [agent-orchestration](agent-orchestration.md) | "이 영역에는 쓰지 말라" (다중 에이전트) — Cognition §4.3과 독립 일치 |
| [repository-hygiene](repository-hygiene.md) | 저장소 개요는 성공률 개선 없이 **비용 +20%**, 저자 권고는 *"including only minimal requirements"* |
| [repository-hygiene](repository-hygiene.md) | 반면 **지시는 따른다** (`uv` 언급 시 인스턴스당 1.6회 vs 0.01회 미만) — 서술과 지시의 효과가 갈린다 |
| [instruction-layers](instruction-layers.md) | 상시 로드 1,044줄 / 라우팅 10,185자 — §6의 지시 밀도 축에 미매핑 |
| [enforcement-mechanisms](enforcement-mechanisms.md) | `deny`·`ask`·`sandbox` **전부 0건**, 차단 가능한 지점과 실제 배치가 역전 |
| [verification-and-cross-review](verification-and-cross-review.md) | 훅 9개 중 게이트 0개, 지적 163건 중 **78.5% 미조치** |

**추론 (이 문서, 자료의 주장 아님)** — 마지막 세 줄을 §7.2의 가설에 대입하면 grid fin(및 참조 원본 cygnus)은 서술 문서·절차는 있는데 강제 가능한 계약이 0에 가깝다는 그림이 된다. **다만 §7.3에서 그 가설을 보류했으므로 이 대입도 함께 보류한다.** 세 문서의 실측 자체(게이트 0건, 78.5% 미조치)는 이 문서와 무관하게 각자 성립한다.

### 8.2 §3이 걸어주는 제동

grid fin은 태스크 다양성이 높고 프런티어 모델을 쓴다 → §3의 "하네스를 깎아 싼 모델을 살린다"는 경로가 약하다. **다만 이것은 "얇게 가도 된다"는 허가이지 "얇을수록 좋다"는 증명이 아니다.** §1.4에서 구분한 대로, 관측된 것은 *덜 흔들린다*이지 *줄이면 오른다*가 아니다. 줄여서 얻는 확실한 것은 **토큰과 유지보수 비용**이다(§1.2: 68k vs 175k).

### 8.3 Bitter Lesson 논지의 실무적 판정 기준

실무 담론에서 반복 등장하는 형태 — **모델을 올렸을 때 하네스가 어느 쪽으로 움직이는가**로 판정한다.

- 새 모델이 라우팅·특수 케이스를 **걷어내게** 해준다 → 방향이 맞다
- 모델 업그레이드마다 예외 처리와 전용 도구를 **덧붙이게** 된다 → 사람이 설계한 스캐폴드에 과의존하고 있다

**등급**: 이것은 자가출판 실무 담론(Substack/X/Medium)에서 온 형태다. 검증된 명제가 아니라 **점검 질문의 형태로만** 쓴다.

---

## 9. 검증 실패 — 인용 금지 항목

| 주장 | 상태 |
|---|---|
| "Mini-SWE-Agent + Claude-Opus-4.7 68.3%, Hermes Agent 64.6%, Claude Code 62.2%" | **1차 출처 확인 실패.** 검색 요약이 제시했으나 Harness-Bench 본문에는 이 수치도 이 하네스 조합도 없다(본문은 NanoBot 76.2 / OpenClaw 52.4 / Codex 80.4). arXiv:2606.07462도 확인했으나 없음. **출처 불명** |
| mini-SWE-agent의 74%가 특정 모델의 점수라는 서술 | README에 모델 귀속 없음 (§5.1) |
| Cho 2605.26731의 "frontier" 결과를 프런티어 모델 증거로 사용 | 라벨된 모델이 프런티어가 아님 (§2.1) |
| Agentless의 32.00%를 현재 성능 근거로 사용 | 2024년 수치 (§5.2) |

**부수 관측**: 이 조사에서 검색 스니펫 합성이 **1차 본문과 다른 수치 세트를 만들어냈다.** 이 시리즈의 다른 문서에서도 2차 출처 수치가 정정된 전례가 있다([evaluation.md](evaluation.md)의 `n ≈ 969`). **하네스 조사에서 스니펫 수치를 그대로 옮기지 않는다**는 규칙이 다시 확인됐다.

블로그 계층(MindStudio, dev.to, Medium/Cobus Greyling 등)은 대부분 위 논문들을 재서술한 것이라 **실무 담론의 존재 증거로만** 취급하고 수치는 인용하지 않았다.

---

## 10. 열린 질문

1. **grid fin의 현재 지시 밀도가 IFScale 축 어디인가.** 상시 로드 1,044줄이 "지시" 몇 개에 해당하는지 환산 방법이 없다. 임계 붕괴 패턴이 사실이면 이 측정 없이는 안전 여부를 알 수 없다
2. ~~§7.2의 절차/인터페이스 분리가 실험으로 성립하는가~~ → **§11에 설계를 붙였다(미실행).** 남는 질문은 셋으로 갈라졌다:
   - **2a.** Stage 0의 `ρ̂`(궤적 내 급내상관)와 호출당 위반 기저율이 얼마인가. **이 두 값이 실험의 성립 여부를 결정한다** — §11.4의 go/no-go
   - **2b.** 얇은 하네스에 절차를 **더하는** 방향과 두꺼운 하네스에서 **빼는** 방향이 대칭인가. §11.3 요인 A가 전자만 조작 가능하다
   - **2c.** 계약 위반율(매개변수)이 움직이면 태스크 성공률(성과)도 움직이는가. §11.2.2 — 이 설계로는 답이 안 나온다
   - **2d.** **절차적 제약이 계약 위반율 말고 무엇에 닿는가.** §11.3.1에서 A의 경로가 IFScale 하나뿐임이 드러났다. "절차가 모델의 판단을 대신하는 것이 해로운가"를 재려면 **다른 종속변수가 필요하고, 그것이 무엇인지 아직 모른다** — §11.3.1의 부차 DV 둘이 후보일 뿐이다
3. ~~Harness-Bench의 6개 하네스가 무엇인지~~ → **§1.5에서 해소.** 남는 질문: **NanoBot의 4,000줄이 Moltis의 150,000줄에 비해 정확히 무엇을 뺐는가.** 소스 수준 비교는 하지 않았다. §5.3의 Rombaut 분해 방법론이 그대로 적용할 수 있는 대목이다
4. **Codex의 80.4%(모델 결속형)와 조립형 최고 76.2%의 격차 4.2%p를 하네스 사용자가 메울 수 있는가.** §4.2의 "모델 수준에서 푼다"가 닫아버린 경로다
5. **"제거"의 되돌림 비용.** 제약을 걷어냈다가 모델을 바꿨을 때 되돌리는 비용을 다룬 자료를 못 찾았다. §8.3의 판정 기준은 방향만 주고 가역성은 말하지 않는다
6. **얇은 하네스와 [verification-and-cross-review](verification-and-cross-review.md)의 게이트 요구가 충돌하는가.** 게이트는 인터페이스 계약인가 절차적 제약인가 — §7.2 분류가 이 경계에서 애매하다(이 애매함 자체가 §7.3의 보류 근거 중 하나다)
7. **다중 런타임(Node/Python/Rust)에서 "도구 4범주 수렴"(§5.3)이 유지되는가.** 13종 분해는 대부분 Python 코딩 에이전트다
8. **`str_replace_editor`로의 독립 수렴(§5.3)이 시사하는 것** — 편집 인터페이스는 자유도가 아니라 사실상 표준일 가능성. grid fin이 이걸 재발명할 이유가 있는지

---

## 11. 분리 검증 설계 (열린 질문 2)

**성격**: 프로토콜. **실행하지 않았다.** grid fin 스펙이 아니라 §7.2 가설을 반증 가능하게 만드는 실험 설계이며, 이 문서와 함께 `docs/research/`에 둔다.

이 설계의 산출물은 두 가지다 — **(가) 실행 가능한 프로토콜**과 **(나) 실행 불가능한 부분이 어디인지에 대한 확정.** §11.5가 후자이고, 그쪽이 더 중요할 수 있다.

### 11.1 벽 — 이 실험은 기본형으로는 측정 불가다

[evaluation.md §1.5.3](evaluation.md)이 이미 답을 갖고 있다.

| 변경의 종류 | 실측 `δ` | 필요 문항 |
|---|---:|---:|
| 하네스 전체 교체 | 0.07~0.16 | 34~178 |
| **구성요소 하나 추가/제거** | **약 0.02** | **약 2,180** |

**절차적 제약만 걷어내거나 인터페이스 계약만 조이는 것은 정의상 아래쪽이다.** 태스크 성공률을 종속변수로 두는 한 이 실험은 개인 규모에서 성립하지 않는다. 설계의 출발점은 그 사실이지 그것을 우회할 아이디어가 아니다.

### 11.2 탈출구와 그 대가 — 종속변수를 성공률에서 계약 위반율로

§7.1의 관측이 그대로 종속변수를 준다. **실패가 계약·형식 준수에 몰려 있다면, 재야 할 것은 태스크 성공이 아니라 그 위반 자체다.**

| | 태스크 성공률 | **도구 호출당 계약 위반율** |
|---|---|---|
| 표본 단위 | 태스크 (수십) | **도구 호출 (수천)** |
| 채점 | 정답 라벨 필요 | **코드 기반** — 파서 거부, 비영 종료코드, 형식 불일치 |
| 재는 것 | 최종 성과 | **기제** |

채점 장치는 이미 있다 — mini-SWE-agent는 형식에 맞지 않는 출력을 파서에서 거부하므로 **파서 거부 횟수가 곧 계약 위반 카운트**다. 도구 복구 실패는 비영 종료 이후의 재시도 궤적으로 센다. [evaluation.md §6](evaluation.md)의 실측(grader 100% 코드 기반)과 같은 계열이고 모델 판정자의 보정 부채가 없다.

#### 11.2.1 그런데 표본이 호출 수만큼 늘지 않는다 — 이것이 이 설계의 핵심 제약

**위반은 궤적 안에서 강하게 뭉친다.** 형식을 한 번 어긋내는 하네스는 같은 실행에서 반복해서 어긋낸다. 이것이 Miller 권고 2(클러스터 SE, *"over 3X larger"*)가 말하는 바로 그 상황이다.

유효 표본은 호출 수가 아니라 이렇게 줄어든다:

```
n_eff ≈ n_calls / DEFF ,  DEFF = 1 + (m − 1)ρ
        m = 태스크당 호출 수,  ρ = 궤적 내 급내상관(ICC)
```

`ρ`가 크면 **수천 호출이 다시 수십 단위로 붕괴하고 §11.1의 벽으로 되돌아간다.** 단계를 늘렸을 뿐 아무것도 못 잰다.

**그리고 지금 `ρ`도 기저율도 모른다.** Harness-Bench의 36.4%는 **실패 중 비중**이지 호출당 위반율이 아니다. `n`은 기저율에 의존하므로 이 값 없이는 표본 계산 자체가 불가능하다. → §11.4 Stage 0가 존재하는 이유다.

#### 11.2.2 대가 — 매개변수를 재는 것이지 성과를 재는 것이 아니다

계약 위반율이 움직였다고 태스크 성공률이 움직였다는 뜻이 아니다. **이 설계는 §7.2의 기제 가설을 검정하지 "그래서 하네스가 나아졌는가"에 답하지 않는다.** 후자는 §11.1의 벽 뒤에 그대로 남는다. 이 구분을 결과 보고에 반드시 남긴다.

### 11.3 요인 정의 — 2×2

#### 요인 A · 절차적 제약 (2수준)

| 수준 | 조작 |
|---|---|
| A0 (기준) | mini-SWE-agent 기본 프롬프트 |
| A1 | **단계 규정 추가** — 탐색→재현→수정→검증 순서 명시, 각 단계 진입 조건, 특수 케이스 분기 |

**비대칭 한계 (명시)**: mini-SWE-agent는 절차적 제약의 최소점에 있으므로 **더할 수만 있고 뺄 수 없다.** 따라서 이 실험이 답하는 것은 *"얇은 하네스에 절차를 얹으면 어떻게 되는가"*이지 *"두꺼운 하네스에서 절차를 걷어내면 어떻게 되는가"*가 아니다. **두 방향이 대칭이라는 보장이 없다** — §8.3의 판정 기준(모델 업그레이드 시 하네스가 어느 쪽으로 움직이는가)이 실제로 요구하는 것은 후자다.

#### 요인 B · 인터페이스 계약 (2수준) — 존재/부재로 나눌 수 없다

**"인터페이스 계약 없음"은 조작 불가능하다.** 무언가는 출력을 파싱해야 하고, mini-SWE-agent에서는 bash 블록 형식이 곧 인터페이스다. 형식 엄격도를 건드리면 파서와 뒤엉킨다.

**따라서 실제로 조작 가능하고 자료 지침과도 맞는 축을 쓴다 — 오류 응답의 품질과 복구 경로.**

| 수준 | 조작 |
|---|---|
| B0 | 원시 오류 — 종료코드·stderr 트레이스백을 그대로 전달 |
| B1 | **Anthropic 지침 적용** — *"prompt-engineer your error responses to clearly communicate specific and actionable improvements"*. 무엇이 틀렸는지 + 다음에 무엇을 하라는지를 오류 문자열에 담는다 |

**이 축의 장점**: 에이전트에게 *무엇을 할지*를 한 마디도 더 말하지 않는다. 순수하게 인터페이스 쪽만 움직이므로 요인 A와 개념적으로 직교한다.

#### 11.3.1 예측 방향과 기제 — 사전에 못박는다

**두 요인이 종속변수에 닿는 경로가 대칭이 아니다.** 이것을 적어 두지 않으면 A의 귀무 결과를 잘못 읽게 된다.

| 요인 | 예측 | 기제 |
|---|---|---|
| **B** (오류 응답) | B1에서 **위반율 감소** | 직접적이다. 실행 가능한 오류가 복구 재시도의 반복 실패를 줄인다 — Harness-Bench 실패 분류의 **도구 복구 실패 24.6%** 버킷이 그대로 대상이다 |
| **A** (절차 규정) | A1에서 **위반율 증가** | **간접적이다. 유일한 경로가 §6(IFScale)이다** — 단계 규정은 bash 블록 형식 준수와 직접 관계가 없고, 지시 밀도를 올려 형식 준수를 떨어뜨리는 경로로만 이 종속변수에 닿는다 |
| **A×B** | A1의 증가분 일부를 B1이 흡수 | 위 둘의 합성 |

> **A의 귀무 결과를 "절차적 제약은 무관하다"로 읽으면 안 된다.** 그것은 **이 종속변수가 A가 하는 일에 애초에 민감하지 않았다**는 뜻일 수 있다. A에 대한 귀무는 정확히 이렇게만 읽는다 — *"이 지시 밀도 구간에서 IFScale 경로가 계약 위반율을 유의하게 움직이지 않았다."*

**따라서 A에 대해 부차 종속변수를 사전 선언한다** (검정력 계산 대상 아님, 기술 통계로만 보고):

| 부차 DV | 정의 | 왜 A에 민감한가 |
|---|---|---|
| 계획 외·중복 행동 수 | 궤적당, 동일 명령 재실행 및 규정 단계와 무관한 호출 | 절차 규정이 실제로 행동 순서를 바꿨는지를 직접 본다 |
| 첫 편집까지의 호출 수 | 궤적당 | 탐색 단계 규정의 직접 표적 |

**부차 DV는 다중비교 보정 대상이 아니며 가설 생성용이다.** 여기서 신호가 보이면 그것이 다음 실험의 주 DV 후보다.

#### 셀 4개

| | B0 원시 오류 | B1 실행 가능 오류 |
|---|---|---|
| **A0 절차 없음** | 기준선 (= 순정 mini-SWE-agent) | |
| **A1 절차 추가** | | |

### 11.4 단계 — Stage 0가 go/no-go를 결정한다

#### Stage 0 · 기저율·`ρ` 추정과 조작 점검

| 항목 | 값 |
|---|---|
| 조건 | A0B0 (기준선) 단일 |
| 태스크 | SWE-bench Verified 층화 표본 **20** |
| 반복 | 태스크당 **3회** |
| 계측 | 모든 도구 호출에 대해 파서 거부 / 비영 종료 / 형식 불일치 기록 |
| 산출 | 호출당 위반율 `p̂`, 태스크당 호출 수 `m̂`, 궤적 내 ICC `ρ̂`, 조건별 프롬프트 토큰 수 |

**사전에 못박는 go/no-go 규칙** (사후 조정 금지):

`α=0.05`, `1−β=0.80`, `ω² ≈ p(1−p)`로 두고 `n_ind = (z_{α/2}+z_β)² ω² / δ²`, 필요 호출 수 `= n_ind × DEFF`.

`p̂ = 0.10` 가정 시 자릿수 감각:

| 검출 목표 `δ` (호출당 절대) | 독립 호출 `n_ind` | `ρ=0.3, m=40` → DEFF 12.7 | 필요 태스크 (× 3회) |
|---:|---:|---:|---:|
| 0.05 (위반율 절반) | 약 282 | 약 3,580 호출 | **약 30** |
| 0.03 | 약 784 | 약 9,950 호출 | 약 83 |
| 0.02 | 약 1,764 | 약 22,400 호출 | 약 187 |

| `ρ` (δ=0.05 고정) | DEFF | 필요 태스크 |
|---:|---:|---:|
| 0.1 | 4.9 | **약 12** |
| 0.3 | 12.7 | **약 30** |
| 0.6 | 24.4 | 약 57 |
| 0.9 | 36.1 | 약 85 |

> **`ω² ≈ p(1−p)`는 근사다.** [evaluation.md §1.5.3](evaluation.md)이 단 유보와 같은 종류다 — **자릿수 감각으로 읽고 정확한 표본 수로 읽지 않는다.** `ω²`는 문항 집합의 성질이지 상수가 아니다.

**진행 조건 — MDES 형식으로 못박는다.**

Stage 0는 기준선 셀만 돌리므로 **효과 크기 `δ`를 추정하지 못한다.** `p̂`·`m̂`·`ρ̂`만 나온다. 따라서 게이트를 "조작이 얼마나 움직일 것 같은가"로 쓰면 **Stage 0가 생산할 수 없는 값을 요구하는 것이고, 결국 사후에 정하게 된다.** (파일럿 셀을 하나 더 돌려 예비 `δ`를 얻는 우회로가 있으나, 파일럿 효과 크기는 상향 편향되고 잡음이 커서 그것으로 검정력을 계산하는 것은 알려진 함정이다.)

**대신 순서를 뒤집는다 — `δ`를 추정하지 말고 사전에 선언한다.**

1. **MDES 선언 (Stage 0 실행 전).** *"호출당 계약 위반율이 절대 몇 %p 움직이면 grid fin에서 실제로 다르게 하겠는가"* 에 답하고 그 값을 `δ_min`으로 고정한다. 이것은 통계량이 아니라 **실무적 판단**이며, 그래서 데이터를 보기 전에 정할 수 있다
2. **Stage 0 실행** → `p̂`, `m̂`, `ρ̂`
3. **게이트**: 태스크 예산 상한(예: 40개)에서 `δ_min`을 `α=0.05, 1−β=0.80`으로 검출 가능한가?

| 게이트 결과 | 결론 |
|---|---|
| 검출 가능 | Stage 1 진행 |
| **검출 불가** | **"개인 규모에서 이 가설은 검정 불가"가 결론이다.** "더 돌린다"가 아니다 — §11.1의 벽으로 되돌아왔다는 뜻이며, 그 확정 자체가 산출물이다 |

**게이트를 통과하든 못하든 `δ_min`은 수정하지 않는다.** 못 통과했을 때 `δ_min`을 키워 통과시키는 것이 이 설계가 막으려는 바로 그 동작이다.

위 표를 이 형식으로 다시 읽으면 — `p̂=0.10`, `m̂=40`, 태스크당 3회 반복, **예산 40태스크** 기준으로:

| `δ_min` | `ρ̂` | 필요 태스크 | 게이트 |
|---:|---:|---:|---|
| 0.05 | 0.1 | 약 12 | **통과** |
| 0.05 | 0.3 | 약 30 | **통과** |
| 0.05 | 0.6 | 약 57 | 불통과 |
| 0.03 | 0.1 | 약 32 | **통과** |
| 0.03 | 0.3 | 약 83 | 불통과 |
| 0.02 | 0.1 | 약 72 | 불통과 |

**`δ_min=0.02`는 `ρ̂`가 가장 낙관적인 0.1이어도 예산을 넘는다.** 즉 [evaluation.md §1.5.3](evaluation.md)의 "구성요소 하나 = δ 약 0.02 = 측정 불가"가 종속변수를 바꾼 뒤에도 **같은 지점에 그대로 서 있다.** 이 설계가 사는 것은 조작이 위반율을 크게 움직일 때뿐이다.

#### Stage 1 · 2×2 주효과 (단일 모델)

| 항목 | 값 |
|---|---|
| 셀 | 4 |
| 태스크 | Stage 0가 정한 수, 4셀 **공통 태스크** |
| 반복 | 셀·태스크당 **k ≥ 3** |
| 모델 | 1종 고정 |
| 분석 | **태스크 수준 짝지은 차이** (Miller 권고 4) + 클러스터 SE (권고 2) + 2요인 분산분석의 A·B 주효과 |

`k ≥ 3`의 근거는 둘이다 — [evaluation.md §1.6.3](evaluation.md)의 *"single-run evaluations misrank models 29.3% of the time"*, 그리고 Miller의 재표집 `Var(μ̂|K>1) = Var(μ̂|K=1) × (1+2/K)/3`. 다만 §1.3이 지적한 대로 **`K`는 `σ²` 항만 줄이고 `ω²`는 못 줄인다** — 반복으로 태스크 수를 대체할 수 없다.

**4셀 공통 태스크**가 중요하다. 짝지은 차이가 분산을 상대적으로 1/3 줄이고, 이 설계에서는 그것이 여유가 아니라 성립 조건에 가깝다.

### 11.5 Stage 2는 도달 불가 — 이것이 설계 연습의 결과다

사용자의 원래 질문은 **"최신 고성능 모델일수록"** 이다. 그것을 검정하려면 **모델 강도 × 제약 종류 상호작용**이 필요하다.

**상호작용 검출에는 같은 크기의 주효과 대비 약 4배의 표본이 든다.** Stage 1이 태스크 30개로 겨우 성립하는 조건이라면 Stage 2는 120개 이상이고, 그것도 `ρ̂ = 0.3`·`δ = 0.05`라는 가장 낙관적인 가정에서다. 셀은 8개로 늘고 모델 하나가 더 붙는다.

> **결론: 개인 규모에서 사용자의 원 질문은 직접 검정할 수 없다.** 이것을 "나중에 할 단계"로 적어 두었다가 조용히 포기하지 않기 위해 여기 명시한다. [evaluation.md §1.5.3](evaluation.md)이 "구성요소 하나 추가는 측정 불가"를 결론으로 적은 것과 같은 종류의 확정이다.

**남는 경로는 셋이고 전부 열등하다:**

1. **2차 인용에 의존** — Harness-Bench의 교차 하네스 분산(§1.4)을 그대로 받는다. 단일 미검증 출처다(§1.6)
2. **`δ`를 키운다** — 제약을 극단으로 조작해 효과를 크게 만든다. 대신 결과가 현실적 설정에 전이되지 않는다
3. **방향만 본다** — 검정력을 포기하고 부호와 크기만 기록해 다른 근거와 대조한다. **가설 생성이지 검정이 아니다**

### 11.6 교란 통제

| 교란 | 처리 |
|---|---|
| **프롬프트 길이** | A1은 A0보다 길다. **패딩으로 맞추지 않는다** — 패딩은 지시 밀도를 바꿔 §6(IFScale)의 축과 새로 교란시킨다. **조건별 토큰 수를 조작 점검으로 보고하고 공변량으로 다룬다** |
| 모델 비결정성 | [evaluation.md §1.6.1](evaluation.md) — 서버 측 배치 구성은 통제 밖이다. `k` 반복과 오차 막대로 흡수하고, 조건 간 실행을 **시간적으로 교차**해 드리프트가 특정 조건에 몰리지 않게 한다 |
| 태스크 난이도 | 층화 표본 + 4셀 공통 태스크 + 짝지은 분석 |
| 조작 점검 | A1이 실제로 절차를 규정했는지, B1이 실제로 실행 가능한 오류를 냈는지 — 궤적 표본을 사람이 확인한다 |

### 11.7 보고 형식 — 새로 만들지 않는다

[evaluation.md §1.5.4](evaluation.md)에 기록된 [Zhang et al.](https://arxiv.org/abs/2605.23950)의 템플릿을 그대로 인스턴스화한다.

| 요소 | 이 설계에서 |
|---|---|
| **Harness Card** (ETCSOVG 7층) | 4셀 각각에 대해. 요인 A는 Context/Scheduling 층, 요인 B는 Tool/Verification 층에 해당 |
| **분산 분해** | 2×2 그리드에서 `HV`(하네스 분산)·`MV`·순위 역전·partial η². Stage 1은 단일 모델이라 `MV`가 비고, 그 공백 자체가 §11.5의 기록이 된다 |
| **궤적 지표** | **Recovery Rate가 요인 B의 종속변수와 거의 같다.** 논문에 정의가 있고 계기는 없다 — 계기를 만드는 것이 Stage 0의 부수 산출물이다. Context Retention·Control Lag도 함께 |

### 11.8 이 설계가 답하지 않는 것

1. 성과(태스크 성공률)에 대한 효과 — §11.2.2
2. **두꺼운 하네스에서 절차를 걷어내는 방향** — §11.3 요인 A의 비대칭
3. **모델 강도와의 상호작용** = 사용자의 원 질문 — §11.5
4. grid fin 고유 단위(머지 커밋, 정답 라벨 없음)로의 전이 — 대리 과제는 SWE-bench Verified다. [evaluation.md §1.5.4](evaluation.md)의 전이 한계가 그대로 적용된다
5. 인터페이스 계약의 다른 차원(형식 엄격도, 도구 스키마, 권한 게이트) — 요인 B는 오류 응답 한 축만 조작한다
6. **요인 A가 절차적 제약으로서 하는 일 대부분** — §11.3.1대로 A는 IFScale 경로로만 주 종속변수에 닿는다. **즉 이 설계는 A에 대해서는 사실상 "지시 밀도 실험"이고, "절차가 모델의 판단을 대신하는 것이 해로운가"는 건드리지 못한다.** 부차 DV가 그쪽을 겨냥하지만 검정력이 없다

---

## 참고문헌

**1차 — 프리프린트 (전부 미피어리뷰)**
- [Harness-Bench: Measuring Harness Effects across Models in Realistic Agent Workflows](https://arxiv.org/html/2605.27922v1) — arXiv:2605.27922, 2026-05-27, PKU + Qiyuan Tech
- [It's Not the Capability: Harness Sensitivity Is Non-Monotone Across LLM Agent Tiers](https://arxiv.org/html/2605.26731) — arXiv:2605.26731, 2026-05-26, Yong-eun Cho
- [Better Harnesses, Smaller Models](https://arxiv.org/html/2607.08938) — arXiv:2607.08938, 2026-07-09, Yang·Zhao·Wu·Kästner
- [Inside the Scaffold: A Source-Code Taxonomy of Coding Agent Architectures](https://arxiv.org/html/2604.03515v2) — arXiv:2604.03515v2, 2026-04-10, Benjamin Rombaut
- [How Many Instructions Can LLMs Follow at Once?](https://arxiv.org/pdf/2507.11538) — arXiv:2507.11538, Jaroslawicz et al. (IFScale)
- [Agentless: Demystifying LLM-based Software Engineering Agents](https://arxiv.org/abs/2407.01489) — arXiv:2407.01489, 2024-07 / 2024-10 rev., Xia·Deng·Dunn·Zhang

**1차 — 벤더 공식**
- [Effective context engineering for AI agents](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents) — Anthropic
- [Building effective agents](https://www.anthropic.com/engineering/building-effective-agents) — Anthropic
- [Writing tools for agents](https://www.anthropic.com/engineering/writing-tools-for-agents) — Anthropic
- [mini-SWE-agent README](https://github.com/SWE-agent/mini-swe-agent/blob/main/README.md) — SWE-agent

**1차 — 실무 진술**
- [Thibault Sottiaux (OpenAI Codex) — Dev Interrupted](https://linearb.io/dev-interrupted/podcast/openai-codex-thibault-sottiaux-agentic-autonomy)
- [Don't Build Multi-Agents](https://cognition.com/blog/dont-build-multi-agents) — Cognition

**1차 — 하네스 실체 확인 (§1.5)**
- [HKUDS/nanobot](https://github.com/HKUDS/nanobot) — 코어 약 4,000줄, 46.5k★

**참조하되 인용하지 않음** — MindStudio, dev.to, Medium/Cobus Greyling, Substack 계열. §1.5의 ZeroClaw·NullClaw·Moltis 서술은 Claw 생태계 비교 글에서 왔고 저장소 직접 확인은 하지 않았다(규모 수치는 참고용). 위 자료의 재서술이며 §9의 미확인 수치가 이 계층에서 나왔을 가능성이 높다.
