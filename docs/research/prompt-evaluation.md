# 프롬프트·스킬 평가 — 다른 프로젝트들은 어떻게 하고 있나

**최초 작성**: 2026-08-13
**최종 수정**: 2026-08-13
**대상 프로젝트**: grid fin (신규 개인용 개발 하네스)
**조사 계기**: grid fin 자신이 **스킬 프롬프트와 파이썬 스크립트로 이루어져 있어** 첫 실행에서 `prompt` 종류 작업이 실제로 발생한다(D1). 그런데 **`prompt` 어댑터의 기준선이 무엇인지가 정해져 있지 않다.** 참고 하네스에 `evals/`가 실물로 있으나 **넉 달 멈춰 있고 검사가 전부 파일 구조 확인**이었다. 바깥의 관행을 확인한다.
**조사 도구**: Exa `/search` 5회 (**실패 0**). 본문은 같은 응답의 `contents.text`(2,500자 상한)로 확인했고, **초록을 넘어선 본문은 읽지 않았다**(§7).
**성격**: 조사. **설계 결정은 하지 않는다.** 결정은 [미결 원장](../draft/open-questions.md)이 받는다.

관련 문서 — [평가 조사](evaluation.md)(**통계 요구·`pass@k`·판정자 보정·참고 하네스 실측은 그 문서에 있다. 이 문서는 반복하지 않는다**) · [스킬 구조 조사](skill-architecture.md) · [드래프트 §5-1 어댑터 표](../draft/judgment.html#5-1) · [드래프트 §7-4 배포 단위](../draft/storage.html#7-4) · [미결 원장 D5·Q12](../draft/open-questions.md)

---

## 0. 이 조사가 새로 준 것

[평가 조사 §5.4](evaluation.md)는 **"활성화 측정에 관해 확보한 자료는 「기제의 설명」까지이고 「측정법」은 없다"**로 닫고 §7-1로 넘겼다. **그 판단은 2026-08-02 시점에 맞았다.** 이번 조사에서 **1차(공식 문서) 둘이 나왔고, 그중 하나는 「스킬을 발동시켰는가」를 검사 항목으로 명시한다.**

| # | 관측 | 등급 |
|---|---|---|
| 1 | **eval의 정의에 「캡처된 실행」이 들어간다** — 프롬프트 → 트레이스·산출물 → 검사 묶음 → 점수 | 1차(공식 문서) |
| 2 | **검사를 outcome · process · style 셋으로 나눈다.** *"에이전트가 스킬을 발동했는가"*는 process 검사다 | 1차(공식 문서) |
| 3 | **에이전트 채점은 단위 테스트·환경 변화·완수 확인에 의존한다** | 1차(공식 문서) |
| 4 | **스킬이 두 종류이고 위험이 다르다** — 능력 보강(모델이 좋아지면 낡음) / 절차 고정(절차가 바뀌면 어긋남) | 2차 |
| 5 | **능력 보강 스킬에는 은퇴 검사가 있다** — 스킬을 빼고 돌려서 통과하면 그 스킬은 필요 없다 | 2차 |
| 6 | **판정자를 두 번 돌리면 답이 달라진다** — 같은 질문에 대한 선호가 평균 13.6% 뒤집힌다 | 프리프린트 |
| 7 | **채점 기준을 목록으로 주면 그 목록의 순서가 점수를 바꾼다** | 프리프린트 |
| 8 | **골든셋 크기 권고가 출처마다 다르다** — 10~20 / 20~50 / 50~200 / 100~300 | **2차 넷** |
| 9 | **실패 원인 1위가 「CI에서 안 돌린다」** — 참고 하네스에서 실측한 것과 같다 | 2차 + 1차 실측 |

---

## 1. eval의 정의 — 「캡처된 실행」이 빠지면 eval이 아니다

**OpenAI 공식 문서**가 에이전트 스킬 평가를 정면으로 다룬다([Testing Agent Skills Systematically with Evals](https://developers.openai.com/blog/eval-skills), 2026-01-22, **1차(공식 문서)**).

> *"At its core, a skill is an organized collection of prompts and instructions for an LLM. The most reliable way to improve a skill over time is to evaluate it the same way you would any other prompt."*

**정의가 네 부분이다.**

> *"Concretely, an eval is: a prompt → a captured run (trace + artifacts) → a small set of checks → a score you can compare over time."*

그리고 **무엇이 회귀인지를 구체적으로 든다** — *"the skill doesn't trigger, it skips a required step, or it leaves extra files behind."*

### 1.1 참고 하네스의 `evals/`는 이 정의를 만족하지 않는다

**1차 실측**(2026-08-13, `src/.claude/evals/adapter-exa.md` 직접 확인). 검사 항목 넷이 전부 셸 한 줄이다.

```
[CAPABILITY] SKILL.md 파일이 존재한다          →  test -f …/SKILL.md
[CAPABILITY] capabilities 필드가 올바르다       →  grep -q "capabilities: [search-adapter, exa]"
[CAPABILITY] operation 섹션 4개가 기술돼 있다    →  grep -q "### /search" …
[REGRESSION]  응답 스키마 표준 필드가 유지된다    →  grep -q "query" "results" "source" "operation"
```

**에이전트를 실행하지 않는다.** 그러므로 캡처된 실행이 없고, 검사는 **`SKILL.md`라는 파일의 내용**을 본다. **스킬이 발동했는지도, 의도한 명령을 돌렸는지도, 결과가 관습을 지켰는지도 보지 않는다.**

이것은 [평가 조사 §6.2](evaluation.md)가 *"grader는 100% 코드 기반이다"*로 적은 것과 같은 관측인데, **이번 조사가 그 뜻을 바꾼다** — 코드 기반이라 문제가 아니라(공식 문서도 결정적 검사를 권한다) **실행이 없어서** 문제다.

**그리고 로그가 그 성격을 드러낸다.** `adapter-exa.log`는 `Trial 1 / Trial 2 / Trial 3`과 `pass@3: 1.00 | pass^3: YES | 판정: PASS (기준: pass@3 ≥ 0.9)`를 적는다. **`grep`은 세 번 돌려도 같은 답을 준다.** 반복 시행의 형식만 있고 **반복이 의미를 갖는 대상이 없다.**

> **보강 대상.** [평가 조사 §5.4](evaluation.md)가 *"측정법은 없다"*로 닫은 항목에 **1차 자료가 생겼다.** 그 문서의 §5.4를 이 절로 잇는다.

### 1.2 검사를 셋으로 나눈다

같은 문서가 **성공을 스킬 작성 전에 정의하라**고 하면서 축 셋을 준다.

| 축 | 무엇을 보나 | grid fin에서 무엇이 되나 |
|---|---|---|
| **outcome** | 과제가 끝났나. 앱이 도나 | 계산적 게이트가 이미 하는 일 |
| **process** | **스킬을 발동했나. 의도한 도구와 단계를 밟았나** | **훅이 실제로 막았나 · 단계를 건너뛰지 않았나** |
| **style** | 결과가 관습을 지켰나 | 커밋 메시지 형식 · 이슈 번호 · 기록의 모양 |

**process 축이 이 설계에 가장 값지다.** 하네스의 목적이 *지시가 아니라 기제*(S4)이므로, **검증해야 할 것이 정확히 "기제가 작동했는가"**다. 그리고 **grid fin은 그 트레이스를 이미 만든다** — 커밋·PR·리뷰 기록·판정 기록이 산출물로 남는다(S12는 상태를 그 산출물에서 계산한다). **골든셋을 따로 만들지 않아도 캡처된 실행이 저장소에 쌓인다.**

### 1.3 Anthropic 공식은 채점 쪽을 말한다

[Demystifying evals for AI agents](https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents) (2026-01-09, **1차(공식 문서)**).

> *"In production-relevant evals, grading often relies on unit tests, environment updates, and end-to-end task completion checks."*

**에이전트 평가에서 채점의 주력이 LLM 판정자가 아니라 단위 테스트와 환경 상태 확인**이라는 뜻이다. 같은 문서가 **왜 어려운지**도 적는다 — *"agents use tools across many turns, modifying state in the environment and adapting as they go—which means mistakes can propagate and compound."*

**한정어를 붙여 둔다.** 이 문서는 **다회전 에이전트 시스템**을 대상으로 쓰였고, 개인용 하네스 규모를 대상으로 하지 않는다.

---

## 2. 스킬 두 종류 — 그리고 은퇴 검사

[Evaluating and Refining Agent Skills](https://www.agent-engineering.ch/articles/agent-skill-evaluation-and-refinement/) (2026-03-04, **2차 — 개인 기술 블로그**).

**2차 출처이므로 수치는 인용하지 않는다. 인용하는 것은 분류와 그로부터 나오는 절차 하나다.**

| 종류 | 무엇을 하나 | 고유 위험 |
|---|---|---|
| **능력 보강**(capability uplift) | 모델이 혼자서는 잘 못 하는 기법을 가르친다 | **낡는다** — 기반 모델이 좋아지면 그 기법이 기본 동작이 되어 스킬이 불필요해지거나 방해가 된다 |
| **절차 고정**(encoded preference) | 어떤 모델이든 할 수 있는 단계를 **우리가 원하는 순서와 방식으로** 묶는다 | **어긋난다** — 실제 절차가 바뀌었는데 스킬이 옛 절차를 강제한다 |

### 2.1 은퇴 검사 — 기준선이 「스킬 없이 돌린 것」이다

> *"For capability uplift skills, a passing eval without the skill loaded is a signal that the skill has been subsumed by model improvement and can be retired."*

**스킬을 빼고 같은 과제를 돌려서 통과하면, 그 스킬은 이제 필요 없다.**

**이 절차가 `prompt` 어댑터의 `baseline()`을 채울 수 있다.** [드래프트 §5-1](../draft/judgment.html#5-1)은 `prompt`의 기준선을 *"eval 세트 점수"*로 적어 두었는데, 은퇴 검사는 **점수를 저장하지 않는다** — **스킬을 넣고 한 번, 빼고 한 번 돌려 통과 여부 둘을 비교**하고 결과가 **참·거짓**이다.

**그래서 §3의 통계 문제를 통째로 비껴간다** — 비교하는 것이 두 점수가 아니라 두 판정이다.

**다만 이 절차는 두 종류 중 한쪽에만 성립한다.** 절차 고정 스킬은 **없이 돌려도 통과할 수 있다**(모델이 능력은 있으니까) — 그런데도 필요하다. 우리가 원하는 순서를 강제하는 것이 목적이기 때문이다. **grid fin의 스킬 대부분이 절차 고정 쪽**이므로(워크플로 강제가 설계의 전부다) **은퇴 검사가 적용되는 범위는 좁다.**

---

## 3. LLM 판정자 — 두 번 돌리면 답이 달라진다

[평가 조사 §2](evaluation.md)가 **판정자 정확도와 보정식**을 다뤘다. **이 절은 다른 축이다 — 같은 판정자를 반복해서 돌렸을 때의 재현성.**

### 3.1 재현성

**[The Coin Flip Judge?](https://doi.org/10.48550/arxiv.2606.13685)** (arXiv 2606.13685, 2026-04-23, **프리프린트 · 인용 0 · 저자 1인**). 초록에서 직접 확인한 수치다.

**측정 조건을 먼저 적는다** — 과제 29개(10개 범주), **판정 모델은 GPT-4o-mini와 GPT-4.1-mini 둘**, 질문마다 **쌍 비교 50회 + 단독 채점 50회**, 온도·프롬프트 민감도 절제 실험 포함.

> *"Across judges, pairwise preferences flip on average 13.6% of the time, with 28% of questions exceeding a 20% flip rate and one question reaching 56%. GPT-4o-mini also exhibits a significant first-position bias (72% A-majority, p = 0.024). … mean pointwise score gaps are small (0.19–0.36 on a 10-point scale) and not statistically significant in aggregate."*

**한정어 셋을 떨어뜨리지 않는다.** ① **판정 모델이 mini 둘뿐이다** — 프런티어 모델에 같은 값이 나온다는 근거가 아니다. ② **프리프린트이고 인용이 없다.** ③ **13.6%는 29개 과제의 평균**이고 질문마다 편차가 크다(최대 56%).

**그럼에도 방향은 다른 출처와 일치한다.** [Judging the Judges](https://aclanthology.org/2025.ijcnlp-long.18/) (ACL IJCNLP 2025 long paper, **피어리뷰**)는 판정자 15개 · 과제 22개 · 생성 모델 약 40개 · **평가 인스턴스 150,000건 이상**으로 *"position bias is not due to random chance and varies significantly across judges and tasks"*를 확인했다. **그 논문이 붙인 한정어가 중요하다** — *"weakly influenced by the length of prompt components, it is strongly affected by the quality gap between solutions."* **두 후보의 품질 차이가 클수록 편향이 줄어든다.**

### 3.2 채점 기준 목록의 순서가 점수를 바꾼다

**[Am I More Pointwise or Pairwise?](https://arxiv.org/html/2602.02219v2)** (arXiv 2602.02219, **프리프린트**).

> *"rubric-based evaluation implicitly resembles a multiple-choice setting and therefore exhibits position bias: LLMs tend to prefer score options that appear at specific positions within the rubric list. Its direction, however, is model-specific… We further identify a second, orthogonal axis of bias: when a prompt scores several criteria simultaneously, the ordering of the criteria itself shifts the resulting scores."*

**채점 기준을 목록으로 적어 주는 방식**(rubric)에도 위치 편향이 있고, **방향이 모델마다 반대**다. 그리고 **여러 기준을 한 번에 채점시키면 기준을 나열한 순서가 결과를 바꾼다.** 완화책으로 **순서 섞기**를 제시한다.

**이 설계와 직접 닿는다** — [S16](../draft/open-questions.md)의 커밋 경계 리뷰가 **심각도 셋으로 판정**하고, `⑤′`가 **사람이 셋 중 고르는 단계**다. 판정 기준을 목록으로 주는 형태라면 **그 목록의 순서가 결과에 영향을 준다.**

### 3.3 프롬프트를 조금만 바꿔도 결과가 흔들린다

**[RELIABLEEVAL](https://aclanthology.org/2025.findings-emnlp.594.pdf)** (ACL Findings EMNLP 2025, **피어리뷰**).

> *"we stochastically evaluate five frontier LLMs and find that even top-performing models like GPT-4o and Claude-3.7-Sonnet exhibit substantial prompt sensitivity."*

**뜻이 같은 프롬프트로 바꿔 쓰기만 해도** 성능이 흔들리며, 표준 벤치마크가 **단일 프롬프트 하나로 결과를 보고하는 것**이 문제라고 지적한다. **최상위 모델도 예외가 아니다.**

### 3.4 이것이 D5를 바깥에서 뒷받침한다

[D5](../draft/open-questions.md)는 **"측정하지 않는다. 회귀만 막는다. eval은 통과/실패 게이트로만 쓰고 점수 비교를 하지 않는다"**로 정했고, 근거는 [평가 조사 §1.5](evaluation.md)의 **효과 크기 δ≈0.02 → 문항 2,000개**였다.

**이번 조사가 다른 경로로 같은 결론에 닿는다.** 점수를 비교하려면 **판정자가 재현 가능해야** 하는데(§3.1), **기준 목록의 순서에도 흔들리고**(§3.2), **프롬프트 표현에도 흔들린다**(§3.3). 그리고 표본이 작으면 **겉보기 승자가 통계적으로 의미 없다**([Statistics for LLM Evals](https://statsforevals.com/investigations/best-prompt.html), **2차** — N=20·40에서 쌍별 차이가 신뢰구간 안에 묻힌다고 서술).

**즉 D5는 「비용이 없어서」만이 아니라 「측정 도구 자체가 그만큼 안 흔들리지 않아서」도 옳다.** 결정을 바꿀 이유는 없고, **근거가 하나 늘었다.**

---

## 4. 골든셋 — 크기 권고가 출처마다 다르다

**2차 출처 넷이 서로 다른 값을 말한다. 평균 내지 않고 그대로 적는다.**

| 권고 | 출처 | 단서 |
|---|---|---|
| **10~20** | llmtest.io | "30줄 Node 스크립트" 수준의 최소 구성 |
| **20~50** | thepromptbench.com | 합성이 아니라 실제 입력이어야 한다 |
| **50~200** | llmbestpractices.com | 실제 트래픽 분포를 덮어야 한다 |
| **100~300** | futureagi.com | **경로(route)마다**. 의도·페르소나·경계로 층화 |

**넷 다 SEO성 2차 콘텐츠이고 측정 근거를 제시하지 않는다.** 한 자릿수 배 차이가 나는 것은 **덮으려는 대상이 다르기** 때문으로 보이지만 **확인하지 않았다.**

**공통되는 서술 셋은 출처가 갈려도 일치한다.**
- **정확한 출력 문자열을 기대하지 않는다** — 채점이지 단언이 아니다
- **골든셋 자체를 버전 관리하고, 바꾸면 같은 PR 안에서 이유를 적는다**
- **지표를 둘 쓴다** — 구조(파싱·형식)와 의미(정확성)

**마지막 항목이 이 설계와 맞는다** — 구조 쪽은 계산적 게이트가 이미 하고, 의미 쪽만 남는다.

---

## 5. 실패 원인 1위가 우리가 실측한 것과 같다

[Eval Harnesses Compared](https://pondero.ai/enterprise/guides/eval-harnesses-braintrust-vs-langsmith-vs-promptfoo-vs-arize-2026/) (2026-07-28, **2차**)가 피해야 할 것 셋을 든다.

| 실패 | 서술 |
|---|---|
| **CI 공백** | **eval이 CI에서 돌지 않는다** |
| **데이터셋 표류** | 골든셋이 실제 사용과 어긋난다 |
| **느슨한 임계** | 임계값이 헐거워 아무것도 못 막는다 |

**첫째가 이 프로젝트의 실측과 같다.** `baseline.json`의 `lastPass`가 **2026-04-24**이고 오늘이 8월이니 **넉 달 안 돌았다**(1차 실측). [평가 조사 §6.3](evaluation.md)이 *"100일 멈춰 있다"*로 적은 것과 같은 상태가 그 뒤로도 이어졌다.

**바깥이 이름 붙인 실패와 이 저장소가 잰 결손이 같은 것이므로, 관측은 하나로 센다.** 그리고 **결과가 분명하다 — eval은 단계나 훅에 매달려야 하고, 사람이 기억해서 치는 명령이면 안 된다.** 이는 이 설계가 세 번 확인한 형태(`checkpoints.log` · `memory-persist` · `/dev:impl`)와 같은 교훈이다.

**도구 지형도 하나만 적어 둔다** — Promptfoo가 CLI 우선·오픈소스(MIT)로 CI 게이트에 쓰이고, **2026-03-09 OpenAI가 인수했으며 오픈소스 유지를 밝혔다**(**2차** — 여러 비교 글이 같은 날짜를 적는다. **1차 공지는 확인하지 않았다**). Braintrust·LangSmith는 관측·데이터셋 관리 쪽이다. **이 프로젝트가 도구를 도입할지는 이 조사가 답하지 않는다.**

---

## 6. grid fin에 무엇을 뜻하는가 — 결정이 아니라 정리

**결정은 하지 않는다.** 다만 이 조사가 **원장의 어느 항목에 입력을 주는지**만 적는다.

**하나 — 「구조로 볼 것인가 동작으로 볼 것인가」는 물어볼 필요가 없어졌다.** 이 대화에서 원장에 올리려던 갈림인데, **1차(공식 문서)가 동작 쪽으로 정의를 못박는다**(§1). 구조 검사만 하면 **eval의 정의를 만족하지 않는다.** 남는 물음은 *"동작을 어떻게 캡처하고 무엇을 검사하나"*다.

**둘 — `prompt` 어댑터의 `baseline()` 후보가 생겼다.** 은퇴 검사(§2-1)는 **점수를 저장하지 않고 참·거짓을 준다.** 다만 **절차 고정 스킬에는 적용되지 않고, grid fin의 스킬 대부분이 그쪽**이다. **절차 고정 스킬의 기준선은 이 조사가 주지 않는다.**

**셋 — [Q12](../draft/open-questions.md)는 이것으로 닫히지 않는다.** Q12는 *"환경 부재를 결직접 세는 비용"*이고 **`config`·`infra` 둘의 문제로 이미 좁혀져 있다.** `prompt`은 그 괄호 안에서 *"eval 세트라 다른 종류의 전제다"*로 따로 언급될 뿐이다. **은퇴 검사가 `prompt`의 전제를 가볍게 만들어도 `config`·`infra`의 환경 문제는 그대로 남는다.** 다만 *"평가 세트가 없으면 설계상 부재인가 결손인가"*라는 하위 물음은 **은퇴 검사를 쓰는 범위에서는 사라진다** — 세트가 없어도 기준선을 만들 수 있기 때문이다.

**넷 — process 검사가 이 설계에 잘 맞는다.** 워크플로가 커밋·PR·기록을 남기므로 **캡처된 실행이 부산물로 생긴다**(§1-2). **다만 이것을 실제로 해 본 적이 없다.**

---

## 7. 이 조사가 재지 않은 것

- **어느 형식도 실제로 돌려보지 않았다.** OpenAI의 정의도, 은퇴 검사도, 이 저장소에서 한 번도 실행되지 않았다. **전부 문헌이다.**
- **본문을 초록·서두까지만 읽었다.** Exa 응답의 `contents.text`가 2,500자 상한이라 **논문 본문·방법론·한계 절을 읽지 않았다.** §3의 수치는 **전부 초록에서 직접 확인한 것**이고, 초록에 없던 것(kappa 감쇠 폭, 판정자 순위 변동, 판정자 간 일치도, MT-Bench의 인간 일치율)은 **검색 요약에만 있어 이 문서에 싣지 않았다.**
- **도구 넷을 비교하지 않았다.** Promptfoo·Braintrust·LangSmith·Phoenix의 실측 비교는 하지 않았고 **2차 비교 글의 서술만 봤다.**
- **개인 규모의 비용을 재지 않았다.** eval 한 번 돌리는 데 드는 토큰·시간·돈이 얼마인지 **이 조사에 없다.** [평가 조사 §1](evaluation.md)이 요구하는 표본 크기와 곱하면 실행 가능성이 갈리는데, **그 곱셈을 하지 않았다.**
- **절차 고정 스킬의 기준선을 찾지 못했다.** 은퇴 검사가 능력 보강 쪽에만 성립하는데, **grid fin의 스킬 대부분이 반대쪽**이다. **이 조사의 가장 큰 공백이다.**
- **골든셋 크기 권고의 근거를 확인하지 않았다.** 넷 다 2차이고 **어느 것도 측정으로 뒷받침되지 않았다.**
