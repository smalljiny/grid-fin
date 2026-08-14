# 평가(eval) — 구현 참조 자료

**최초 작성**: 2026-08-02
**최종 수정**: 2026-08-13
**대상 프로젝트**: grid fin (신규 개인용 개발 하네스)
**성격**: **자료 수집·정리.** grid fin 구현 시 참조할 외부 자료를 모으고 정돈한다. 평가 체계를 설계하지 않는다.
**조사 도구**: WebFetch 13회(대부분 1차 본문), GitHub API 1회(공식 구현 코드), WebSearch 2회(자료 위치 파악), 하네스 실측(적용 대상 확인용, eval 재실행 포함)

선행 문서
- [research-agenda.md](research-agenda.md) §6 — 이 조사의 출처
- [observability.md](observability.md) §1.2 — 귀속 축(`skill.name`·`agent.name` 등)이 측정 단위를 준다
- [verification-and-cross-review.md](verification-and-cross-review.md) §3.1 — Google의 effective false positive 임계
- [enforcement-mechanisms.md](enforcement-mechanisms.md) — "게이트 0개"

---

## 0. 이 문서의 쓰임

**grid fin을 구현할 때 "하네스 변경이 나아진 것인지 어떻게 아는가"에 답할 근거를 모았다.** 다섯 자료가 서로 다른 층을 덮는다.

| 자료 | 층 | 무엇을 주는가 | 등급 |
|---|---|---|---|
| [Miller, *Adding Error Bars to Evals*](https://arxiv.org/abs/2411.00640) | **통계 요구** | 권고 5개, 클러스터 SE·재표집·짝지음 공식, **표본 수 공식과 그 파라미터**(`n≈969`는 `δ=0.03` 기준) | 프리프린트 (v1 단일 판본) |
| [Lee et al., *How to Correctly Report LLM-as-a-Judge Evaluations*](https://arxiv.org/abs/2511.21140) | **모델 기반 grader** | 불완전 판정자의 편향과 그 보정식, 필요 보정 표본 수 | **피어리뷰 (ICML 2026)** |
| [Chen et al., *Evaluating LLMs Trained on Code*](https://arxiv.org/abs/2107.03374) + [`openai/human-eval`](https://github.com/openai/human-eval) | **지표 정의** | `pass@k`의 편향 없는 추정량 (공식 구현 코드로 확인) | 논문 + 공식 구현 |
| [Galster et al., *Harness Engineering for Agentic AI Coding Tools*](https://arxiv.org/abs/2602.14690) | **실증 기준선** | 2,853개 저장소의 설정 채택률, 그리고 **효과 증거의 공백** | 프리프린트 (v5) |
| [Anthropic, *Equipping agents for the real world with Agent Skills*](https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills) | **활성화 기제** | 스킬이 언제 로드되는지의 공식 설명 — **그리고 측정법의 부재** | 1차 (벤더 공식) |
| [Zhang et al., *Stop Comparing LLM Agents Without Disclosing the Harness*](https://arxiv.org/abs/2605.23950) **(2026-08-03 추가)** | **효과 크기** | 하네스만 바꿨을 때의 실측 이동 폭, 하네스 분산 / 모델 분산 = **7.80×**, 분산 분해 프로토콜 | 프리프린트 (자체 통제 실험 + 제3자 인용) |

**§1~§5가 자료다. §6은 이 자료가 grid fin에 해당하는지 확인하는 실측이며 보조 목적이다.**

이 문서의 결론 형태를 미리 적어 둔다. **평가의 어려움은 "무엇을 잴 것인가"가 아니라 "얼마나 큰 것을 잴 것인가"에 있다.**

> **초판 정정 (2026-08-02 출처 감사 → 2026-08-03 효과 크기 조사).** 여기에 원래 *"통계 쪽 자료가 요구하는 표본 규모와 개인 하네스가 생산하는 표본 규모가 두 자릿수 차이다"* 라고 적혀 있었다. **그 대조는 검출 목표 `δ=0.03`에서만 성립한다**(§1.2.1). 필요 표본은 `δ²`에 반비례한다.
>
> **그리고 §1.5가 `δ`의 실측 범위를 채웠다. 바뀐 결론은 이렇다.**
>
> | 무엇을 바꾸는가 | `δ` | 필요 문항 | 개인 규모 |
> |---|---|---:|---|
> | 하네스 전체를 교체한다 | 0.07~0.16 | **34~178** | **측정 가능** |
> | 구성요소 하나를 더한다 | 약 0.02 | **약 2,180** | **측정 불가** |
>
> **개인 규모 A/B는 불가능하지 않다. 다만 grid fin에서 실제로 하게 될 변경은 대부분 아래쪽이다.**
>
> **그리고 §1.6이 판정 쪽을 확인했다 — 1회 실행 비교는 29.3%가 오순위다.** 문항 수를 채워도 **각 문항을 몇 번 돌릴 것인가**가 따로 필요하다.

---

## 1. 통계적 요구 — 표본 바닥이 어디인가

[Evan Miller, *Adding Error Bars to Evals: A Statistical Approach to Language Model Evaluations*](https://arxiv.org/abs/2411.00640) (arXiv 2411.00640, 2024-11-01). **arXiv HTML 본문에서 공식과 문장을 직접 확인했다.**

### 1.1 권고 5개 (원문)

> 1. Computing standard errors of the mean using the Central Limit Theorem
> 2. When questions are drawn in related groups, computing clustered standard errors
> 3. Reducing variance by resampling answers and by analyzing next-token probabilities
> 4. When two models are being compared, conducting statistical inference on the question-level **paired differences**, rather than the population-level summary statistics
> 5. Using **power analysis** to determine whether an eval (or a random subsample) is capable of testing a hypothesis of interest

**출발 전제가 하네스 평가에 그대로 옮겨진다** — 평가 문항을 "가능한 문항들의 상위 모집단에서 뽑은 표본"으로 본다. 이 전제를 받아들이면 "eval 20개를 통과했다"는 진술은 점추정치일 뿐이고 구간이 없다.

### 1.2 네 개의 공식과 그 크기

| 항목 | 원문 | 크기 |
|---|---|---|
| **클러스터 SE** | `SE_clustered = (SE²_C.L.T. + 1/n² ∑_c ∑_i ∑_{j≠i} (s_{i,c} − s̄)(s_{j,c} − s̄))^{1/2}` | *"clustered standard errors can be over **3X** larger than naive standard errors"* |
| **재표집(K회)** | `Var(μ̂|K>1) = Var(μ̂|K=1) × (1+2/K)/3` | K=2 → 분산 **1/3** 감소, K=4 → **1/2**, K=6 → **5/9** |
| **짝지은 차이** | `SE_{A−B,paired} = √(Var(s_{A−B})/n)` | *"reduce the variance of the estimator by **1/3** in relative terms"* (균등 점수 분포·상관 0.5 가정) |
| **표본 수** | `n = (z_{α/2} + z_β)² (ω² + σ²_A/K_A + σ²_B/K_B) / δ²` | 예시 조건에서 *"the eval will need to contain at least **n ≈ 969** independent questions"* |

그리고 결론 문장이 이렇다.

> *"new evals should contain at least **1,000 questions** in order to have good signaling ability."*

### 1.2.1 969의 전제 — 출처 감사에서 확보 (2026-08-02 추가)

**초판에서 "가장 약한 고리"로 남겼던 파라미터를 원문에서 확인했다.**

> *"suppose σ<sub>A</sub>²=σ<sub>B</sub>²=0 and ω²=1/9 … Suppose we wish to detect an **absolute difference of δ=0.03** at least 80% of the time (β=0.20) with a false-positive rate of 5% (α=0.05). Then the eval will need to contain at least n=(z<sub>0.025</sub>+z<sub>0.20</sub>)²(1/9)/(0.03)²≈**969** independent questions."*

| 파라미터 | 값 |
|---|---|
| 검출 목표 효과 `δ` | **0.03 (절대 3%p 차이)** |
| 유의수준 `α` | 0.05 |
| 검정력 `1−β` | 0.80 |
| 문항 간 분산 `ω²` | 1/9 |
| 문항 내 분산 `σ²_A`, `σ²_B` | **0** |

**두 가지가 드러난다.**

1. **1,000문항은 "3%p 차이를 잡으려면"의 값이다.** `n ∝ 1/δ²`이므로 더 큰 효과는 훨씬 적은 표본으로 잡힌다(§6.4 재계산).
2. **이 예시는 `σ²_A=σ²_B=0`을 가정한다.** §1.3이 "재표집 `K`가 문항 수를 대체 못 한다"고 읽은 근거가 이 예시에서는 **증명된 것이 아니라 가정으로 소거된 것**이다. 공식의 항 구성에서 읽은 §1.3의 논지는 유지되나, 이 워크드 예시가 그 논지를 보여 주지는 않는다.

### 1.3 형태에서 읽히는 제약 하나

**표본 수 공식에서 `K`(문항당 재표집 횟수)가 줄여 주는 것은 `σ²_A/K_A`·`σ²_B/K_B` 항뿐이고 `ω²` 항은 건드리지 못한다.** `ω²`는 문항 간 이질성에 해당하는 항이므로, **같은 문항을 여러 번 돌리는 것으로 문항 수를 대체할 수 없다**는 뜻이 된다.

이것이 §6.4의 계산에 직접 걸린다. 개인 하네스에서 부족한 것은 실행 횟수가 아니라 **서로 다른 과제의 수**이고, 공식의 형태가 그쪽을 대체 불가로 만든다.

> **한계 표시.** 위 해석은 공식의 항 구성에서 읽은 것이고, `ω²`의 정의를 본문에서 별도로 확인하지 않았다. **유도 과정을 읽지 않았다.**

### 1.4 클러스터가 하네스에서 무엇인가

권고 2가 "관련된 묶음으로 뽑힌 문항"을 대상으로 한다. 하네스 평가에서 이것이 실재할 가능성이 높다 — **한 스킬에 붙은 여러 eval 항목은 서로 독립이 아니다.** §6.2에서 보듯 실제 eval 파일 하나가 같은 `SKILL.md` 한 파일을 네 번 검사한다. 그 넷은 한 클러스터다.

*"over 3X larger"* 가 여기 걸리면, 나이브하게 센 통과율의 불확실성이 3배로 커진다.

---

### 1.5 하네스 변경의 효과 크기 — `δ`의 실측 범위 (2026-08-03 추가)

§1.2.1이 `n`을 `δ`의 함수로 만들었고, §7-3이 *"`δ`를 하네스에서 얼마로 잡아야 하는가"* 를 미해결로 남겼다. **그 질문을 정면으로 다루는 자료를 찾았다.**

[Yunbei Zhang, Janet Wang, Yingqiang Ge, Weijie Xu, Jihun Hamm, Chandan K. Reddy, *Stop Comparing LLM Agents Without Disclosing the Harness*](https://arxiv.org/abs/2605.23950) (arXiv 2605.23950v1, 2026-05-07). **HTML 본문 확인.**

#### 1.5.1 저자들의 통제 실험 — 가장 신뢰할 수 있는 부분

**모델과 하네스를 교차시킨 3×3 요인 설계다.**

| 축 | 값 |
|---|---|
| 과제 | **SWE-bench Verified subset100** — 난이도 층화 100문항 |
| 모델 | GPT-5.4 / Kimi K2.6 / GLM-5.1 |
| 하네스 | H₁ Minimal / H₂ Improved / H₃ Full |
| 반복 | **셀당 독립 실행 2회** (과제 순서 공유) |

**결과 — 하네스를 바꿀 때와 모델을 바꿀 때의 이동 폭이다.**

| 고정한 것 | 바뀐 것 | 점수 이동 |
|---|---|---|
| 모델 GLM-5.1 | 하네스 | **13.0pp** |
| 모델 GPT-5.4 | 하네스 | **8.5pp** |
| 모델 Kimi K2.6 | 하네스 | **8.5pp** |
| 하네스 고정 | 모델 | **3.0 / 2.5 / 5.0pp** |

> 하네스 분산 대 모델 분산의 비가 **7.80×**. 실행별로는 1회차 `HV/MV = 8.72×`, 2회차 `6.76×`.

**그리고 순위가 뒤집힌다** — 평균 그리드에서 *"6 out of 9 model-pair/harness-pair comparisons"* 에 순위 역전이 있었다. **어느 모델이 더 나은지가 어떤 하네스를 쓰느냐에 따라 바뀐다는 뜻이다.**

**이 결과가 7.80×보다 더 무겁고, 이 시리즈의 다른 조사에 직접 걸린다.** [검증·교차리뷰 조사 §6-3](verification-and-cross-review.md)이 *"교차 리뷰 발화율이 리뷰어 성향인가 코드 상태인가"* 를 실험으로 갈라야 할 열린 질문으로 남겼다. **순위 역전은 그 실험이 열거하지 않은 세 번째 가능성을 가리킨다 — 하네스 인공물일 수 있다.** [관찰성 조사 §2.3](observability.md)이 확인한 대로 작성 측과 리뷰 측이 서로 다른 하네스(Claude Code / `codex exec`)에서 도는 이상, 관측된 차이를 모델 특성으로 귀속하기 전에 하네스를 고정해야 한다는 뜻이 된다.

#### 1.5.2 논문이 인용한 제3자 수치 (2차)

**아래는 논문이 다른 출처에서 끌어온 값이며, 이 문서 기준으로는 2차다.** 범위 감각을 위해 적되 등급을 구분한다.

| 벤치마크 | 모델 | 하네스 대비 | Δ |
|---|---|---|---:|
| SWE-bench Pro | Claude Opus 4.5 | SEAL 45.9% → Claude Code 55.4% | **9.5pp** |
| SWE-bench Verified | Grok 4 | SWE-agent → xAI 스캐폴드 | **14~16pp** |
| TerminalBench 2.0 | (고정) | 기본 → 최적화 | **13.7pp** |
| TerminalBench 2 | GPT-5.4 | 표준 → AHE (Lin et al. 2026, 제3자) | **7.3pp** |
| SWE-bench Verified Mini | Claude Sonnet 4.5 | HAL: SWE-Agent 68% → Generalist 34% | **34pp** |
| 〃 | GPT-5 Medium | 46% → 12% | **34pp** |
| 〃 | o4-mini | — | **약 48pp** |
| SWE-bench Pro | 여러 모델 | WarpGrep 검색 **추가** | **2.1~2.2pp** |

**마지막 행이 나머지와 다르다.** 하네스 전체를 갈아 끼운 것이 아니라 **구성요소 하나를 더한** 변경이고, 효과가 한 자릿수 앞자리다.

#### 1.5.3 `δ`가 두 부류로 갈린다 — 이 조사의 핵심 결과

§1.2.1의 `n ∝ 1/δ²`에 위 값을 넣는다.

| 변경의 종류 | 실측 `δ` | 필요 문항 `n` | 개인 규모에서 |
|---|---|---:|---|
| **하네스 전체 교체** (스캐폴드 A → B) | `δ = 0.16` | **34** | **도달 가능** |
| 〃 | `δ = 0.07` | **178** | **도달 가능** |
| **구성요소 하나 추가** (검색 도구·규칙 하나) | `δ = 0.02` | **2,180** | **도달 불가** |

**`n`은 `δ`에 반비례하므로 위 표는 `δ`가 클수록 아래가 아니라 위다.** 하네스 교체 구간(0.07~0.16)의 필요 문항은 **34~178**이고, 작은 쪽 `δ`가 큰 쪽 `n`에 대응한다.

> **외삽에 딸린 가정.** 위 `n`은 Miller의 워크드 예시 값 `ω²=1/9`·`σ²_A=σ²_B=0`을 그대로 유지한 계산이다(§1.2.1). **`ω²`는 문항 집합의 성질이지 상수가 아니다** — Zhang et al.의 subset100은 난이도 층화 표본이라 `ω²`가 다를 수 있다. **자릿수 감각으로 읽어야 하고 정확한 문항 수로 읽으면 안 된다.**

**논문 자신의 설계가 이 계산과 맞물린다.** 저자들은 100문항을 썼는데, `δ ≈ 0.13`을 검출하는 데 필요한 값이 `969 × (0.03/0.13)² ≈ 52`다. **100문항은 그들이 재려던 크기의 효과에 충분하고, 2.1pp짜리 효과에는 한참 부족하다.** 즉 Miller의 공식과 이 논문의 실험 설계가 서로를 검증한다.

**grid fin에 걸리는 방향이 불리하다.** 개인 하네스에서 실제로 하게 될 변경은 대개 두 번째 부류다 — 규칙 하나 추가, 훅 하나 배치, 스킬 하나 도입. **§1.5.2의 마지막 행이 그 부류의 유일한 실측치이고, 그 크기에서는 표본이 원리적으로 모이지 않는다.**

#### 1.5.4 논문의 방법론 권고

측정을 하겠다면 형식이 있다.

1. **Harness Card** — 7개 층(ETCSOVG: Execution, Tool, Context, Scheduling, Observability, Verification, Governance)을 공개
2. **분산 분해 프로토콜** — 최소 2×2 모델×하네스 그리드에서 `HV`, `MV`, `HV/MV` 비, 순위 역전, partial η² 보고
3. **궤적 수준 지표** — Recovery Rate, Context Retention, Control Lag

저자들의 결론: 그런 공개 없이는 *"leaderboard comparisons for long-horizon agents should be treated as incomplete and potentially misleading."*

**[관찰성 조사 §1.2](observability.md)의 귀속 축이 3번의 재료를 일부 준다** — `agent.name`·`skill.name`·`query_source`로 궤적을 가를 수 있다. 다만 Recovery Rate 같은 지표의 정의는 논문에 있고 계기는 없다.

> **전이 한계.** 위 `δ`는 전부 **SWE-bench·TerminalBench에서 과제별 통과/실패로 채점한 값**이다. grid fin의 단위는 머지 커밋이고 정답 라벨이 없다. **크기의 자릿수는 옮겨 오되 측정 장치는 옮겨 오지 않는다.** §1.2.1의 Miller 전이와 같은 종류의 유보다.

---

### 1.6 잡음 바닥 — 같은 것을 두 번 재면 얼마나 다른가 (2026-08-03 추가)

§1.5가 `δ`(재려는 신호)를 채웠다. **신호만으로는 판정할 수 없다 — 같은 조건에서 반복했을 때의 흔들림이 신호보다 크면 아무것도 보이지 않는다.** 세 자료를 찾았고, **셋 다 grid fin의 단위에서 한 걸음씩 떨어져 있다.** 그 거리를 먼저 적는다.

| 자료 | 무엇을 반복했나 | 거리 |
|---|---|---|
| Yuan et al. (§1.6.1) | **하드웨어·배치 구성 12종** | 동일 환경 반복이 아니다 — **기제 설명용** |
| Zhou et al. (§1.6.2) | 동일 설정 **5회** | **단발 코드 생성**이고 에이전트 다중 턴이 아니다 |
| **Mehta (§1.6.3)** | **SWE-bench 50과제 × 5회 포함, 총 8,000회** | **가장 가깝다.** 1인 저자 프리프린트 |
| HAL (§1.6.3.1) | **반복 안 함** — 21,730 rollouts 전부 단일 실행 | ICLR 2026. **반복이 불가능했던 이유가 자료다** |

#### 1.6.1 기제 — 온도 0에서도 결정적이지 않다 (수치는 전이되지 않는다)

[Jiayi Yuan, Hao Li, Xinheng Ding 외, *Understanding and Mitigating Numerical Sources of Nondeterminism in LLM Inference*](https://arxiv.org/abs/2506.09501) (arXiv 2506.09501v2). **HTML 본문 확인.**

원인은 **부동소수점 덧셈의 비결합성**이다 — *"the order in which numbers are added can affect the final result due to accumulated rounding errors."* 하드웨어·배치 크기·GPU 수가 다르면 연산 순서가 달라지고, **같은 시드와 greedy decoding으로도 결과가 갈린다.**

> *"Even small numerical variations in the logit values can affect the final token selection when the top probabilities are close."*

**구성 12종 간 정확도 표준편차** (BF16, greedy):

| 모델 · 과제 | SD |
|---|---:|
| DeepSeek-R1-Distill-Qwen-7B · AIME'24 | **9.15%** |
| 〃 · MATH500 | 1.04% |
| Qwen2.5-7B · AIME'24 | 1.71% |
| Llama-3.1-8B · AIME'24 | 1.92% |

**FP32에서는 거의 사라진다**(MATH500 발산 표본 2.2%). 저자 권고는 셋이다 — FP32, LayerCast(BF16 저장 + FP32 연산, 메모리 34% 절감), 또는 **비영 온도로 여러 번 돌리고 오차 막대와 함께 평균을 보고**(AIME'24 기준 16회 이상).

**추론 과제일수록 흔들림이 크다는 점이 눈에 띈다** — 상위 두 토큰의 확률 차가 작아 반올림에 뒤집히기 쉽다는 설명이다.

> **이 절에서 가져갈 것은 기제이지 수치가 아니다.** 9.15%는 **7B 증류 추론 모델**을 **AIME'24**에서 **하드웨어·배치 구성 12종에 걸쳐** 잰 값이다. grid fin은 고정된 로컬 환경에서 API를 호출하므로 구성이 바뀌지 않는다 — **다만 서버 측 배치 구성은 통제 밖이라 기제 자체는 살아 있다.** **크기는 옮겨 오지 않는다.**

#### 1.6.2 수치 — 한 번 재는 것과 다섯 번 재는 것의 차이

[Yongxi Zhou, Lai Yun Choi, Jiaxi Wen, Wenbo Ye, *Accuracy, Stability, and Repeated-Run Reliability of Large Language Models on Deterministic Programming Tasks*](https://arxiv.org/abs/2606.00920) (arXiv 2606.00920v1, 2026-05-30). **HTML 본문 확인**(PDF는 접근 실패).

| 항목 | 값 |
|---|---|
| 과제 | LeetCode 100문항 (Easy 20 / Medium 50 / Hard 30) |
| 모델 | 5개 제공사 계열 16종 |
| 반복 | **문항·프롬프트당 5회** |
| 총 실행 | **16,000** |
| 설정 | T=0.3, top-p=0.9 |

**세 지표를 가른다.**

| 지표 | 정의 |
|---|---|
| **RLPR** (Run-Level Pass Rate) | 임의의 1회 호출이 성공할 확률 |
| **PSR** (Perfect Stability Rate) | **5회 전부** 성공한 과제의 비율 |
| AV (Average Variance) | 문항별 불안정성 |

**핵심 수치**: 두 지표의 격차가 **최대 17.8pp**에 이르고, 초록이 *"overstates retry-free coverage by up to 17.8 percentage points—the gap widest for mid-performing systems"* 라고 적는다. 그리고 그 격차가 *"reverses model rankings even among closely matched systems."*

**상관은 높다(r=0.985). 문제는 격차의 크기가 모델마다 다르다는 것이다** — 일률적 보정이 안 된다.

> **이 17.8pp를 오독하지 않도록 적어 둔다.** RLPR과 PSR은 **같은 양을 두 번 잰 값이 아니라 같은 데이터에 대한 서로 다른 두 추정량**이다. 구조상 항상 `PSR ≤ RLPR`이고, 과제 수가 많을수록·통과율이 중간대일수록 격차가 벌어진다 — 논문이 *"widest for mid-performing systems"* 라고 적는 이유다. **따라서 17.8pp는 "실행할 때마다 점수가 ±18pp 흔들린다"가 아니다.**
>
> **이 자료에서 안전하게 끌어낼 수 있는 것은 하나다** — 1회 통과율은 재시도 없는 신뢰도를 **최대 17.8pp만큼 과대평가**하고, 그 과대평가 폭이 모델마다 달라서 **1회 기준 비교가 순위를 뒤집는다.**

#### 1.6.3 에이전트 단위 — SWE-bench를 포함한 반복 실행

[Aman Mehta, *When Agents Disagree With Themselves: Behavioral Consistency as an Uncertainty Signal for LLM Agents*](https://arxiv.org/abs/2602.11619) (arXiv 2602.11619v2, 2026-07-15). **§1.6의 세 자료 중 유일하게 에이전트 다중 턴 실행을 반복한다.**

| 항목 | 값 |
|---|---|
| 총 실행 | **8,000회** (모델 4종) |
| 주 실험 | HotpotQA 200문항 × **10회** |
| **교차 검증** | **SWE-bench 50과제 × 5회 = 1,000회** |
| 온도 | 0.7 |

**동일 입력에 대한 행동 경로의 분기** — *"Running the same LLM agent on identical inputs yields **2.3–4.2 distinct action sequences per 10 runs**."*

| 모델 | 10회당 고유 경로 |
|---|---:|
| Claude Sonnet 4.5 | 2.3 |
| GPT-5 | 2.4 |
| Gemini 3 Pro | 3.2 |
| Llama 3.1 70B | 4.2 |

**일관성과 정확도가 붙어 있다** — *"Consistent tasks (≤2 unique paths) achieve **82–87%** accuracy while inconsistent tasks (≥4 paths) achieve **41–65%**"* (p<0.001).

**그리고 이 조사에 가장 직접적인 문장이 이것이다.**

> ***"single-run evaluations misrank models 29.3% of the time"***

**1회 실행 비교는 열 번 중 세 번 틀린 순위를 낸다.** 저자가 제시하는 대응은 선택적 예측이다 — *"answering only when k=3 runs agree"* 하면 정확도 87~88%에 커버리지 54~62%, 단일 실행 대비 **6~14pp** 개선. 일관성 지표의 실패 검출 성능은 AUROC 0.62~0.78로, 모델이 말로 표현한 확신도(0.48~0.55)를 앞선다.

> **등급 주의: 1인 저자 프리프린트다.** SWE-bench 부분은 50과제 × 5회로 주 실험(HotpotQA)보다 작다. **29.3%는 초록 기재값이며 재현하지 않았다.**

#### 1.6.3.1 HAL — 본문 확인 결과 (2026-08-03, PDF 전문)

[Kapoor, Stroebl, Kirgis 외 30여 명, *Holistic Agent Leaderboard*](https://arxiv.org/abs/2510.11977) (arXiv 2510.11977v1, 2025-10-13). **ICLR 2026 Poster** — §1.6에서 인용하는 자료 중 유일한 피어리뷰다. **PDF 66쪽 전문을 추출해 확인했다.**

> **`pass^k`·`pass@k`는 이 논문에 나오지 않는다.** 문자열 전수 검색 결과 0건이다. **이 조사가 처음에 참고한 검색 요약이 그 지표를 HAL에 귀속시킨 것은 오귀속이다.** 아젠다 §12가 반복 지목한 2차 인용 결함의 형태이며, **본문을 받지 않았다면 그대로 실릴 뻔했다.**

**본문이 주는 것이 그 수치보다 강하다.**

**(1) HAL은 반복 실행을 하지 못했다 — 그 이유를 명시한다.**

> *"**High evaluation costs prevent uncertainty estimation.** Some benchmarks cost thousands of dollars per model to evaluate. At these prices, running multiple trials to construct confidence intervals becomes prohibitively expensive. **For HAL, we were forced to rely on single runs without statistical validation for most evaluations.**"*

**21,730 rollouts와 약 $40,000을 쓴 팀이, 신뢰구간을 만들 반복을 감당하지 못했다.** §1.6.4가 "1회 관측으로는 비교가 성립하지 않는다"고 결론짓는데, **이 분야에서 가장 큰 표준화 평가 인프라조차 그 조건을 못 맞춘다는 뜻이다.** 개인 규모의 상한을 가늠하는 데 이만한 근거가 없다.

**(2) 실무에서 잡음이 들어오는 경로를 열거한다** — §1.6.1의 기제가 운영 층에서 어떻게 나타나는지의 목록이다.

| 경로 | 원문 |
|---|---|
| **양자화가 호출마다 바뀐다** | OpenRouter가 기본 설정에서 *"could serve a model with FP4 for one call and FP8 for another"* → *"**introducing hidden variance into benchmarks**"* |
| **엔드포인트 뒤에서 가중치가 교체된다** | Together AI가 출시일에 DeepSeek R1 엔드포인트를 R1 0528로 바꾸면서 *"keeping the same API endpoint name"* → *"Evaluations run before and after this switch cannot be compared"* |
| **레이트 리밋이 오답으로 기록된다** | 조용히 실패하면 평가 프레임워크가 *"marks these as incorrect answers when they are actually infrastructure failures"* |
| **추론 예산의 정의가 제공사마다 다르다** | *"low," "medium," "high"* 를 서로 다르게 매핑 |

**첫 행이 §1.6.1과 정확히 이어진다.** Yuan et al.이 수치 정밀도(BF16 vs FP32)가 결과를 가른다고 보였고, **HAL은 그 정밀도가 사용자 모르게 호출마다 바뀌는 경로가 실재함을 보고한다.** 기제와 노출이 각각 다른 논문에서 나왔다.

> **범위 주의.** 이 경로는 **집합기(OpenRouter)를 거칠 때의 것**이다. grid fin은 Anthropic·OpenAI API를 직접 호출하므로 현재 노출이 아니라 **집합기를 도입하지 말아야 할 이유**로 읽는 것이 정확하다. 다만 제공사 자체의 서버 측 배치 구성은 여전히 통제 밖이다(§1.6.1).

**두 번째 행은 [§6.3의 SHA 핀](#63-sha-고정은-두-체계가-병존한다--그리고-100일-멈춰-있다)과 §7-9에 직접 걸린다** — 하네스 쪽을 SHA로 고정해도 **모델 쪽은 이름이 같은 채로 바뀔 수 있다.**

**(3) 추론 예산을 늘리는 것이 개선이 아니다 — 수치가 있다.**

> 추론 비교가 가능한 모델 4종(Claude Opus 4.1, Claude Sonnet 4, Claude-3.7 Sonnet, o4-mini)에서 ***"in 21 of 36 model-agent-benchmark combinations, increased reasoning effort produces equal or lower accuracy."***

**36개 조합 중 21개다.** 다만 원문이 *"equal or lower"* 이므로 **동률이 21개 안에 포함된다** — "58%에서 하락했다"로 읽으면 과장이다. 정확히는 **58%에서 추론 예산을 늘려도 나아지지 않았다.** 초록의 *"higher reasoning effort reducing accuracy in the majority of runs"* 가 이 수치를 가리킨다.

#### 1.6.4 결론 — 1회 관측으로는 비교가 성립하지 않는다

**이 절이 확보한 것은 "잡음의 폭(pp)"이 아니라 "1회 비교가 틀리는 빈도"다.** 그 구분을 지켜 결론을 적는다.

**직접적 근거는 Mehta의 한 문장이다** — ***1회 실행 비교는 29.3%가 오순위다***(§1.6.3). 에이전트 다중 턴 실행에서, SWE-bench를 포함해 측정된 값이다. **열 번 비교하면 세 번은 틀린 답을 얻는다.**

**Zhou et al.이 다른 각도에서 같은 결론을 준다**(§1.6.2) — 1회 통과율은 재시도 없는 신뢰도를 최대 17.8pp 과대평가하고, **그 과대평가 폭이 모델마다 달라 1회 기준 비교가 순위를 뒤집는다.** (이 17.8pp는 변동폭이 아니다 — §1.6.2의 주의 참고.)

**§1.5의 `δ`와 나란히 놓으면 이렇게 된다.**

| 무엇 | 크기 | 성격 |
|---|---:|---|
| 구성요소 하나 추가의 효과 (`δ`) | 약 2pp | 재려는 신호 |
| 하네스 전체 교체의 효과 (`δ`) | 7~16pp | 재려는 신호 |
| **1회 비교의 오순위율** | **29.3%** | **판정의 신뢰도** |

**두 줄은 "얼마나 큰 차이인가", 마지막 줄은 "한 번 재서 판정할 수 있는가"다. 후자의 답이 아니오다.**

**그런데 반복이 정답인 것도 아니다.** §1.6.3.1이 확인한 대로 **HAL은 21,730 rollouts에 약 $40,000을 쓰고도 반복을 포기했다** — *"forced to rely on single runs without statistical validation."* **"한 번으로는 안 되고, 여러 번은 비싸다"가 이 절이 도달한 실제 지점이다.** 개인 규모에서는 그 긴장이 더 심하다. 그리고 §1.5.2의 실측 `δ` 중 가장 작은 것(약 2pp)은 §1.5.1이 보인 모델 간 이동 폭(2.5~5.0pp)보다도 작다 — **1회 관측에서 구성요소 하나의 효과를 분리해 낼 근거가 어느 자료에도 없다.**

**이것이 §6.4.1의 결론을 한 번 더 조인다.** 거기서 "하네스 전체 교체는 문항 34~178이면 측정 가능"이라 했는데, **그 문항들을 각각 몇 번씩 돌릴 것인가가 빠져 있었다.** §1.2의 재표집 공식(`Var(μ̂|K>1) = Var(μ̂|K=1) × (1+2/K)/3`)이 그 빈 곳을 채우는 도구이고, 실무 범위는 자료가 준다 — §1.6.1은 16회 이상을 권하고, §1.6.2는 5회로 설계했으며, §1.6.3은 **`k=3` 합의**로 커버리지를 절반가량 포기하는 대신 정확도 6~14pp를 얻는다.

**그리고 순위가 뒤집히는 원인이 세 가지로 늘었다 — 서로 독립이다.**

| 출처 | 무엇이 순위를 뒤집는가 | 크기 |
|---|---|---|
| [Zhang et al. (§1.5.1)](https://arxiv.org/abs/2605.23950) | **하네스 선택** | 9개 비교 중 **6개** |
| [Zhou et al. (§1.6.2)](https://arxiv.org/abs/2606.00920) | **재시도 정책** (RLPR로 보느냐 PSR로 보느냐) | 격차 최대 17.8pp |
| [Mehta (§1.6.3)](https://arxiv.org/abs/2602.11619) | **1회만 돌린 것** | **29.3%** |

**기제가 셋 다 다르고 결론이 같다.** 리더보드형 비교가 세 방향에서 무너진다.

**[검증·교차리뷰 §6-3](verification-and-cross-review.md)의 열린 실험이 이 셋을 전부 통과해야 한다.** 그 실험은 *"교차 리뷰 발화율이 리뷰어 성향인가 코드 상태인가"* 를 두 갈래로만 놓았다. **세 자료가 가리키는 것은 그 이분법 밖의 설명들이다** — 하네스가 다르거나(작성은 Claude Code, 리뷰는 `codex exec`), 재시도 정책이 다르거나, **그냥 한 번만 돌렸거나.** 관측된 차이를 모델 특성으로 귀속하려면 셋을 먼저 고정해야 한다.

**실무 형태도 자료가 준다** — Mehta의 `k=3` 합의 규칙(§1.6.3)은 세 번 돌려 일치할 때만 판정하는 것이고, 커버리지를 54~62%로 낮추는 대신 정확도를 6~14pp 올린다. **교차 리뷰에 그대로 옮길 수 있는 모양이다.**

#### 1.6.5 이 절이 답하지 못한 것

1. **"코딩 에이전트 pass rate의 실행 간 표준편차"라는 형태의 수치는 여전히 없다.** §1.6.2의 17.8pp는 단발 코드 생성에서 **1회 관측과 5회 전부 성공 사이의 격차**이고, §1.6.3의 29.3%는 **순위 오판율**이다. 둘 다 pp 단위 표준편차가 아니다. **자릿수 감각으로만 쓴다.**
2. ~~**HAL의 셀당 반복 횟수와 `pass^k` 수치를 얻지 못했다.**~~ **PDF 전문 확인으로 해소 — §1.6.3.1.** 답은 **`pass^k`가 논문에 없고, 반복 실행 자체를 하지 못했다**는 것이다(*"forced to rely on single runs"*). **즉 얻지 못한 수치가 아니라 존재하지 않는 수치였다.**
3. **§1.6.3이 이 절의 결론을 지탱하는데 1인 저자 프리프린트다.** SWE-bench 부분은 50과제 × 5회로 작다.
4. **온도 설정이 자료마다 다르다** — Yuan et al.은 greedy, Zhou et al.은 T=0.3, Mehta는 T=0.7. **잡음 바닥이 설정에 크게 좌우되는데**(§1.6.1이 FP32에서 거의 0이 된다고 보인다) **grid fin이 어느 설정에서 도는지와 대조하지 않았다.**

---

## 2. 모델 기반 grader — 판정자가 불완전할 때

[Chungpa Lee, Thomas Zeng, Jongwon Jeong, Jy-yong Sohn, Kangwook Lee, *How to Correctly Report LLM-as-a-Judge Evaluations*](https://arxiv.org/abs/2511.21140) (arXiv 2511.21140, v1 2025-11-26 / v4 2026-05-31). **ICML 2026** — 이 문서가 확보한 자료 중 유일하게 피어리뷰를 거쳤다.

아젠다 §6-2가 "코드 기반 grader vs 모델 기반 grader의 역할 분담"을 물었다. 이 논문은 **모델 기반 쪽에만 존재하는 비용**을 정량화한다.

### 2.1 편향은 판정자 정확도에서 나온다

판정자의 민감도 `q₁`과 특이도 `q₀`가 1보다 작으면 원시 통과율 `p̂`의 기댓값이 참값 `θ`에서 벗어난다. **낮은 참값에서는 양의 편향, 높은 참값에서는 음의 편향**이 생긴다 — 즉 **편향의 방향이 측정 대상에 따라 뒤집힌다.** 상수 오프셋이 아니라서 "어차피 상대 비교니까 상쇄된다"가 성립하지 않는다.

### 2.2 보정식과 그 대가

보정 추정량은 단순하다.

> `θ̂ = (p̂ + q̂₀ − 1) / (q̂₀ + q̂₁ − 1)`

**대가는 `q̂₀`·`q̂₁`을 어디서 얻느냐다 — 사람이 라벨링한 보정 데이터셋이 필요하다.** 논문이 제시하는 규모: 판정자 `(q₀, q₁) = (0.7, 0.9)`일 때 신뢰구간 폭을 0.1 아래로 내리려면 **보정 예제 `m ≈ 200`개**가 필요하다. 판정자가 좋을수록 이 수는 준다.

### 2.3 LLM 판정이 사람 판정보다 나은 구간이 따로 있다

논문은 조건을 명시한다 — 판정자 오류율에 따라 정해지는 구간에서만 LLM 판정이 사람 전용 평가를 이긴다. 그리고 실측으로 **현행 최상위 판정자들이 Chatbot Arena에서는 그 임계에 도달하지 못한다**고 보고한다(AlpacaEval 같은 더 쉬운 과제에서는 근접).

**하네스 관점의 함의가 분명하다.** 모델 기반 grader를 도입하는 것은 "무료로 판정을 얻는" 일이 아니라 **사람 라벨 200개 규모의 보정 부채를 지는** 일이다. 코드 기반 grader에는 이 항목이 없다 — `test -f`의 민감도·특이도는 1이다.

**[검증·교차리뷰 조사 §3.1](verification-and-cross-review.md)이 확보한 Google의 운용 규칙(effective FP 10% 초과 시 분석기 비활성화)과 축이 같다.** 저쪽은 오탐이 사용자 신뢰를 깎는다는 운용 논거, 이쪽은 오탐·미탐이 추정치를 편향시킨다는 통계 논거다.

---

## 3. `pass@k` — 정의와 편향 없는 추정량

아젠다 §6-3이 "pass@k와 베이스라인 체크포인팅으로 모델 버전 변경의 영향을 분리하는 법"을 물었다. 지표 쪽 정의를 1차로 확인했다.

[Chen et al., *Evaluating Large Language Models Trained on Code*](https://arxiv.org/abs/2107.03374)의 abs 페이지에는 본문이 없어 **공식 구현 저장소 [`openai/human-eval`](https://github.com/openai/human-eval)의 `human_eval/evaluation.py`를 GitHub API로 받아 확인했다.**

```python
def estimator(n: int, c: int, k: int) -> float:
    """
    Calculates 1 - comb(n - c, k) / comb(n, k).
    """
    if n - c < k:
        return 1.0
    return 1.0 - np.prod(1.0 - k / np.arange(n - c + 1, n + 1))
```

**읽히는 것 셋.**

1. **추정량은 `1 − C(n−c, k) / C(n, k)`다** — `n`개를 뽑아 `c`개가 통과했을 때, `k`개를 뽑아 하나도 안 통과할 확률의 여집합. 나이브한 `1 − (1−ĉ/n)^k`가 아니다.
2. **`n ≥ k`가 전제다.** 시행 횟수가 `k`보다 커야 한다. 즉 `pass@10`을 보고하려면 문항당 최소 10회 이상 돌려야 한다.
3. **구현이 곱셈 형태를 쓰는 것은 수치 안정성 때문이다** — 이항계수를 직접 계산하지 않는다.

**이 지표가 §1.2의 재표집과 같은 대상을 다룬다.** `pass@k`의 `n`이 Miller의 `K`다. 그리고 §1.3에서 본 대로 **`K`를 늘려도 문항 수가 필요한 것은 남는다.**

> **한계.** 논문 본문의 pass@k 정의 문장과 편향 논거를 직접 인용하지 못했다. abs 페이지에 본문이 없고 2021년 논문이라 arXiv HTML 렌더링이 없다. **확인한 것은 공식 구현의 코드이며, 그것이 논문의 정의를 구현한다고 전제했다.**

---

## 4. 하네스 설정의 효과 — 실증 기준선, 그리고 증거의 공백

[Matthias Galster, Seyedmoein Mohsenimofidi, Jai Lal Lulla, Muhammad Auwal Abubakar, Christoph Treude, Sebastian Baltes, *Harness Engineering for Agentic AI Coding Tools: An Exploratory Study*](https://arxiv.org/abs/2602.14690) (arXiv 2602.14690, v1 2026-02-16 / **v5 2026-06-30**).

### 4.1 아젠다의 인용을 정정한다

아젠다 §6은 이 논문이 *"미해결 영역으로 '하네스 엔지니어링 효과를 정량화하는 방법 미개발'을 지목했다"* 고 적었다. **본문 확인 결과 논문이 말하는 것은 그것과 다르다.**

> *"At present, there is little empirical evidence on which configuration strategies are most effective or under which conditions they yield measurable improvements."*
> *"Future work should assess whether deeper configuration leads to measurable performance gains, extending early evidence on the impact of Context Files."*
> *"controlled studies should determine whether richer configuration improves outcomes over Context Files alone"*

**"방법이 미개발"이 아니라 "증거가 적다"이다.** 방법은 있다 — 논문이 이름을 대는 것이 **통제된 연구(controlled studies)** 이고, 선행 사례로 Lulla et al. 2026 한 건(AGENTS.md 사용 시 런타임·토큰 소비 감소)을 든다.

**차이가 실질적이다.** "방법이 없다"면 grid fin은 방법을 발명해야 한다. "증거가 적다"면 방법은 표준적이고(§1의 통계 설계), 부족한 것은 표본이다 — 그리고 표본 부족이야말로 §6.4가 확인하는 개인 규모의 실제 제약이다.

**아젠다 §12 출처 감사가 지목한 "2차 인용이 실제 결함" 패턴의 세 번째 사례다.** 앞의 둘(Guo, ETH)과 형태가 같다.

### 4.2 실증 기준선 — grid fin이 어디에 서는가

37,249개 저장소를 걸러 **2,853개**를 분석했다(README 필터 → GPT-5.2로 "engineered project" 분류, "unsure" 2,204건 제외).

설정 기제 8종: **Context Files, Settings, Skills, Subagents, Commands, Hooks, Rules, MCP servers.**

| 기제 | 저장소 | 채택률 |
|---|---:|---:|
| Context Files | 2,586 | **90.6%** |
| Skills | 158 | **5.5%** |
| Subagents | 131 | **4.6%** |

스킬 601개의 리소스 구성:

| 구성 | 개수 | 비율 |
|---|---:|---:|
| **추가 리소스 없음** | **514** | **85.5%** |
| `references/`만 | 35 | 5.8% |
| `scripts/`만 | 35 | 5.8% |
| 둘 다 | 11 | 1.8% |
| `assets/`만 | 4 | 0.7% |

**논문의 결론 문장이 "스킬이 실행 가능한 스크립트보다 정적 지시에 의존한다"이고, 수치가 그것을 받친다 — 실행 코드를 가진 스킬은 601개 중 46개(7.6%)다.**

**이 표가 grid fin에 주는 것은 위치 감각이다.** 기존 하네스는 스킬 55종·서브에이전트·훅·규칙을 모두 쓰므로 상위 5% 안쪽의 구성이다. **그리고 그 구성이 효과가 있다는 증거는 논문에 따르면 존재하지 않는다.**

> **버전 고정.** 이 절의 수치는 **v5** 기준이다. v1 본문을 먼저 읽었을 때 리소스 구성이 501개(83.3%)로 나와 v5의 514개(85.5%)와 달랐다. **판본에 따라 수치가 바뀌므로 인용 시 판본을 함께 적어야 한다.**

---

## 5. 스킬 활성화 측정 — 1차 자료가 주지 않는 것

아젠다 §6-1이 "스킬이 의도한 상황에서 실제로 발동하는지를 샌드박스 eval로 재는 방법"을 물었다. **두 방향으로 1차 자료를 찾았고, 어느 쪽도 측정법을 주지 않는다.**

### 5.1 기제는 공식 문서가 명확히 설명한다

[Anthropic 공학 문서](https://www.anthropic.com/engineering/equipping-agents-for-the-real-world-with-agent-skills)가 3단 progressive disclosure를 규정한다.

> *"At startup, the agent pre-loads the `name` and `description` of every installed skill into its system prompt."*
> *"This metadata is the **first level** of progressive disclosure: it provides just enough information for Claude to know when each skill should be used without loading all of it into context."*
> *"If Claude thinks the skill is relevant to the current task, it will load the skill by reading its full `SKILL.md` into context."*

**즉 활성화 여부를 정하는 입력은 `name`과 `description` 두 필드다.** 이것이 [지시 계층 조사](instruction-layers.md)가 "라우팅 표면 10,185자"로 실측한 그 표면이고, [보안 조사 §3.1](security.md)이 "description은 항상 로드되지만 작고 검사 가능하다"고 적은 그 필드다. **세 조사가 같은 두 필드에 수렴한다.**

### 5.2 그런데 측정법은 없다

**같은 문서가 제시하는 것은 측정이 아니라 관찰이다.**

> *"Monitor how Claude uses your skill in real scenarios and iterate based on observations: watch for unexpected trajectories or overreliance on certain contexts."*

**공식 지침이 "실사용을 관찰하고 반복하라"에서 끝난다.** 활성화율·오발동률에 해당하는 지표도, 그것을 재는 절차도 제시하지 않는다.

### 5.3 SkillGenBench는 이 질문에 답하지 않는다 — 아젠다 참고문헌 정정

아젠다 §6이 참고로 든 [SkillGenBench (arXiv 2605.18693)](https://arxiv.org/abs/2605.18693)를 확인했다. 정식 제목은 ***"SkillGenBench: Benchmarking Skill Generation Pipelines for LLM Agents"*** (2026-05-18)이고, 다루는 것은 **스킬 생성**이다 — 저장소·문서에서 *"correct, reusable, and executable skills"* 를 합성해 내는 능력의 벤치마크다.

초록의 문제 설정이 명시적이다 — *"a central challenge is no longer only whether agents can use provided skills, but whether they can generate … skills from repositories and documents."*

**즉 "주어진 스킬을 쓰는가"가 아니라 "스킬을 만들 수 있는가"를 잰다. 활성화(triggering) 측정은 대상이 아니다.** 아젠다 §6-1의 근거로 걸려 있으나 그 질문에 답하지 않는다.

다만 **`fixed execution harnesses`와 `deterministic execution-based checks`를 쓴다**는 점은 §6-2의 grader 축과 관련이 있다 — 이 벤치마크도 코드 기반 판정을 택했다. (**초록만 확인했다.** 데이터셋 규모와 수치는 초록에 없다.)

### 5.4 남는 것

**활성화 측정에 관해 이 문서가 확보한 신뢰 가능한 자료는 "기제의 설명"까지이고 "측정법"은 없다.** 아젠다가 든 나머지 참고 둘은 개인 블로그와 벤더 블로그다. **없는 근거를 만들지 않기 위해 §7-1로 넘긴다.**

> **⚠ 2026-08-13 보강 — 1차 자료가 생겼다.** 위 판단은 **작성 시점(2026-08-02)에 맞았고 지금은 아니다.** [프롬프트·스킬 평가 조사](prompt-evaluation.md) §1이 확보한 **OpenAI 공식 문서**가 *"에이전트가 스킬을 발동했는가"*를 **process 검사 항목으로 명시**하고, eval을 **`프롬프트 → 캡처된 실행(트레이스·산출물) → 검사 묶음 → 점수`**로 정의한다.
>
> **그 정의가 §6.2의 뜻을 바꾼다.** 참고 하네스의 grader가 *"100% 코드 기반"*인 것은 **문제가 아니다**(공식 문서도 결정적 검사를 권한다). 문제는 **에이전트를 실행하지 않아 캡처된 실행이 없다**는 것이다. **활성화를 재려면 발동시켜 봐야 한다.**

---

## 6. 적용 대상 확인 — 지금 무엇이 측정되는가 (보조)

**이 절은 위 자료가 이 프로젝트에 해당하는지 확인하는 용도다.** grid fin은 아직 코드가 없으므로 참조 원본인 기존 하네스를 실측했다.

### 6.1 eval 자산은 5개 파일, 스킬 2종

`src/.claude/evals/`의 전부다.

| 파일 | 줄 |
|---|---:|
| `adapter-exa.md` | 20 |
| `adapter-firecrawl.md` | 20 |
| `baseline.json` | 10 |
| `adapter-exa.log` | 53 |
| `adapter-firecrawl.log` | 87 |

**스킬 55종 중 eval을 가진 것이 2종(3.6%)이다.** 둘 다 `adapter-*` 계열이고, [보안 조사 §5.1](security.md)이 분류한 제3자 도입 스킬 쪽이다.

> **분모 근거.** `55`는 `src/` 아래 `origin:` frontmatter를 가진 `SKILL.md` 전수이며 [보안 조사 §5.1](security.md)이 쓴 것과 같은 기준이다. 같은 대상을 다르게 세면 `.claude/skills/` 디렉터리 항목 **47**, `SKILL.md` 파일 전수 **58**(`.codex/skills/` 3종과 중첩분 포함)이 된다. **셋 다 맞고 기준이 다르다.** 이 문서는 시리즈 일관성을 위해 55를 쓴다.

### 6.2 grader는 100% 코드 기반이다

`adapter-exa.md`의 항목 4개 전부가 셸 한 줄이다.

| 종류 | 항목 | 판정 방식 |
|---|---|---|
| CAPABILITY | `SKILL.md` 존재 | `test -f` |
| CAPABILITY | `capabilities` 필드 선언 | `grep -q` |
| CAPABILITY | operation 4종 기술 | `grep -q` × 4 |
| REGRESSION | 응답 스키마 필드 4종 유지 | `grep -q` × 4 |

**모델 기반 grader 0건.** §2가 정량화한 보정 부채가 현재는 없다는 뜻이고, 동시에 §2가 다루는 종류의 판정(응답이 실제로 쓸 만한가)은 하나도 하지 않는다는 뜻이다.

**그리고 4항목이 전부 같은 파일 하나를 검사한다.** §1.4의 클러스터가 여기 해당한다 — 이 넷은 독립 표본 4개가 아니다.

**측정 대상도 좁다.** 넷 다 `SKILL.md`의 **텍스트 존재 여부**를 본다. 스킬이 발동하는지(§5), 발동해서 옳은 결과를 내는지는 어느 항목도 보지 않는다.

### 6.3 SHA 고정은 두 체계가 병존한다 — 그리고 100일 멈춰 있다

아젠다 §6-3의 "베이스라인 체크포인팅(SHA)"이 이미 구현되어 있다. **다만 두 곳에 서로 다른 SHA가 있다.**

| 위치 | 값 | 커밋 | 성격 |
|---|---|---|---|
| `baseline.json`의 `gitSHA` | `1b180bc` | *"fix(skill): fix regression eval commands to match JSON-quoted field format"* | **마지막 통과 시점** (`lastPass`와 짝) |
| `adapter-exa.md`의 `Baseline:` | `1cd2cfb` | *"fix: adversarial review — contents 파라미터 추가 및 /answer 계약 명시"* | **회귀 비교 기준** |

둘 다 유효한 커밋이고 같은 날(2026-04-24)이다. **스테일이 아니라 목적이 다른 두 핀이다** — 하나는 "언제 마지막으로 통과했나", 하나는 "무엇과 비교해 회귀를 판정하나".

**멈춰 있는 쪽은 실행이다.** `마지막 실행: 2026-04-24`, `lastPass: 2026-04-24T11:45:34Z` — 조사 시점(2026-08-02) 기준 **100일**이다. 그 사이 해당 스킬을 건드린 커밋이 있다(`19b11fe` *"refactor(skill): verify Q3 platform and rename 5 adapter skills"*).

**문서에 적힌 명령을 그대로 재실행했다. 4개 항목 전부 통과한다.** 즉 깨져 있지 않다. **깨져 있지 않다는 것을 100일 동안 아무도 몰랐다는 것이 관측 결과다.** [강제 메커니즘 조사](enforcement-mechanisms.md)의 "게이트 0개"와 같은 형태다 — 실행되지 않는 검사는 게이트가 아니다.

### 6.4 표본 규모 — §1이 요구하는 것과 하네스가 생산하는 것

**§1.2의 바닥이 문항 1,000개다. 하네스가 3개월 동안 생산한 것을 센다.**

**두 저장소를 따로 셌다** — 하네스 자신의 개발과, 그 하네스를 적용받은 프로젝트(cygnus)의 개발이다.

| | harness | cygnus |
|---|---:|---:|
| 기간 | 2026-04-15 ~ 07-15 (3개월) | 2026-07-15 ~ 08-02 (약 19일) |
| 전체 커밋 | 388 | 210 |
| **머지 커밋** | **41** | **21** |
| **월 환산** | **약 13.7** | **약 33** |

머지 커밋을 토픽 단위로 보면([상태·연속성 조사](state-and-continuity.md)가 세운 대응) **월 14~33개의 "실제 과제"가 생긴다.** 1,000개를 유기적으로 모으려면 각각 **약 73개월 / 30개월** — 어느 쪽도 년 단위다.

### 6.4.1 재계산 — 출처 감사가 이 절의 결론을 약화시켰다 (2026-08-02 추가)

**§1.2.1이 확보한 `δ=0.03`을 넣으면 위 대조가 조건부가 된다.** `n ∝ 1/δ²`이므로:

| 검출 목표 `δ` | 필요 문항 `n` | 하네스가 모으는 데 걸리는 시간 (월 14~33건 기준) |
|---|---:|---|
| **0.03** (3%p) | **969** | 30~73개월 |
| 0.10 (10%p) | 약 **87** | 3~6개월 |
| 0.15 (15%p) | 약 **39** | 1~3개월 |
| 0.20 (20%p) | 약 **22** | **1개월 미만** |

**즉 "두 자릿수 부족"은 `δ=0.03`에서만 성립한다.** 20%p 규모의 효과를 재는 것이라면 유기적 표본으로도 한 달 안에 도달한다.

**그리고 §1.5(2026-08-03 추가)가 `δ`의 실측 범위를 채웠다.** 위 표에 변경의 종류를 붙이면 이렇게 된다.

| 변경의 종류 | 실측 `δ` | 필요 `n` | 판정 |
|---|---|---:|---|
| 하네스 전체 교체 | **0.07~0.16** | **178 ~ 34** (δ 순서와 역방향) | **개인 규모에서 측정 가능** |
| 구성요소 하나 추가 | **약 0.02** | **약 2,180** | **측정 불가** |

**답이 "얼마인지 모른다"에서 "무엇을 바꾸느냐에 달렸고 둘 다 실측치가 있다"로 바뀌었다.**

**이 발견이 초판의 주장을 강화하지 않고 약화시킨다.** [아젠다 §12 출처 감사](research-agenda.md)가 1차 감사에서 명명한 두 번째 패턴 — *"보강이 항상 기존 주장을 강화하지는 않는다"* — 가 재현된 사례다. 숨기지 않고 여기 적는다.

**바뀐 결론.** 개인 규모에서 하네스 A/B가 불가능한 것이 아니다. **어느 크기의 효과를 재려는지에 달려 있고, 작은 개선은 원리적으로 측정 범위 밖이다.** 그리고 아젠다 §6이 인용한 논문(§4.1)이 확인한 대로 **하네스 변경의 전형적 효과 크기를 아는 자료가 없으므로**, `δ`를 얼마로 잡을지가 여전히 미해결이다(§7-3).

---

**아래는 초판 서술이며 유지한다. 세 가지가 다르다.**

1. **Miller의 `n`은 "평가 문항 수"이지 "완료한 과제 수"가 아니다.** 문항은 합성할 수 있다 — 유기적 생산율이 상한이 아니다.
2. **`n ≈ 969`는 특정 파라미터(효과 크기 `δ`, 유의수준, 검정력) 아래의 값이다.** 더 큰 효과를 재려면 더 적은 표본으로 된다. `δ`가 커지면 `n`은 `δ²`에 반비례해 준다.
3. **Miller의 대상은 정적 QA 벤치마크다.** 코딩 하네스로의 전이는 이 문서의 추론이지 저자의 주장이 아니다.

**그래서 §1이 실제로 제약하는 것은 이렇게 좁혀 적는 것이 정확하다.** — 유기적으로 쌓이는 과제로 하네스 A/B를 하려는 설계는 통계가 요구하는 규모에 두 자릿수 못 미친다. 합성 문항으로 규모를 만들거나, 크기가 큰 효과만 재는 것을 받아들이거나, 둘 중 하나를 골라야 한다. **자료가 셋째 길을 주지 않는다.**

---

## 7. 자료가 답하지 않는 것

1. **스킬 활성화를 재는 방법**(§5.4). 벤더 공식 문서는 기제만 설명하고 관찰을 권한다. SkillGenBench는 다른 것을 잰다. **이 문서가 유지하는 등급의 자료를 찾지 못했다.**
2. **합성 문항이 유효한가.** §6.4의 갈림길에서 첫째 길을 택하려면 필요한데, 합성된 하네스 평가 과제가 실제 과제를 대표하는지에 관한 자료가 없다. §4가 든 통제 연구(Lulla et al. 2026)가 어떤 과제 집합을 썼는지 확인하지 않았다.
3. ~~**`δ`를 하네스에서 얼마로 잡아야 하는가.**~~ **효과 크기 조사(2026-08-03)에서 해소 — §1.5 참고.** 하네스 전체 교체는 `δ ≈ 0.07~0.16`, 구성요소 하나 추가는 `δ ≈ 0.02`다. **남는 것 둘.** (가) 그 값들은 SWE-bench류 벤치마크에서 통과/실패로 잰 것이고 머지 커밋 단위로 옮기는 방법이 없다(§1.5 전이 한계). (나) **"구성요소 하나 추가"의 실측치가 WarpGrep 사례 하나뿐이다** — 규칙·훅·스킬 추가가 같은 크기인지 근거가 없다.
4. **`ω²`의 정확한 정의와 유도**(§1.3). 문항 수를 재표집으로 대체할 수 없다는 결론이 여기 걸려 있는데 항 구성에서 읽었을 뿐이다.
5. **클러스터 보정이 실제로 몇 배인가**(§1.4). *"over 3X"* 는 저자가 든 사례의 값이고, §6.2 형태(한 파일을 4번 검사)에서 얼마인지는 재 봐야 안다.
6. **보정 표본 200개를 개인이 만들 수 있는가**(§2.2). 사람 라벨이 필요하고, 그 사람이 사용자 본인이다. 라벨링 부하와 그것이 만드는 편향을 자료가 다루지 않는다.
7. **`pass@k`를 하네스 평가에 쓰는 것이 맞는가**(§3). 정의는 확인했으나, 대상이 "동일 문제의 k회 시행"이라 **비결정적 하네스 실행에 그대로 적용되는지**는 자료가 말하지 않는다.
8. **Chen et al. 본문의 pass@k 논거**(§3 한계). 공식 구현 코드로 대체했다.
9. **모델 버전 변경의 영향을 분리하는 법**(아젠다 §6-3의 뒷부분). SHA 핀은 하네스 쪽 변경을 고정하지만 **모델 쪽은 고정되지 않는다.** [관찰성 조사 §1.2](observability.md)의 `model` 속성이 사후 층화의 재료는 되나 통제는 아니다. **그리고 §1.6.3.1이 이 문제를 더 나쁘게 만든다** — 제공사가 같은 엔드포인트 이름 뒤에서 가중치를 바꾸므로 `model` 속성값조차 불변량이 아니다. **대응책을 어느 자료도 주지 않는다.**
10. **eval을 언제 돌릴 것인가.** §6.3이 확인한 100일 공백의 반대편 — 매 커밋마다 돌리는 비용과 그렇지 않을 때의 위험을 비교한 자료를 찾지 못했다.
11. **다중 config로 과적합을 막는 법**(아젠다 §6-4). 이 조사에서 다루는 자료 중 어느 것도 이 질문을 다루지 않는다. §1.1의 권고 1(문항을 상위 모집단의 표본으로 본다)이 개념적 답의 방향이지만 절차는 아니다.

---

## 부록. 조사 방법 및 한계

**방법**

- WebFetch 13회 — Miller abs(판본·저자)와 **arXiv HTML 본문**, LLM-judge abs와 **HTML 본문**, Chen et al. abs, Galster et al. abs·판본 목록·**v1 HTML**·**v5 HTML**, SkillGenBench abs, Anthropic 공학 문서, MLflow 공식 문서, **그리고 `alphaxiv.org`의 Miller 요약 페이지 1회**
- GitHub API 1회 — `openai/human-eval`의 `evaluation.py`(pass@k 추정량 구현)
- WebSearch 2회 — 자료 위치 파악용
- 하네스 실측(§6, 보조) — eval 자산 전수, 스킬 수를 세 기준으로 집계, `baseline.json`·eval 파일의 SHA를 `git log`로 해석, **문서에 적힌 eval 명령 4개를 직접 재실행**, harness·cygnus 두 저장소의 기간·머지 커밋 집계

**출처 교체 기록** — §1의 공식과 수치를 처음에는 `alphaxiv.org/overview/2411.00640`(제3자 요약 페이지)에서 얻었다. **arXiv HTML 본문으로 전량 교체했고 요약 페이지는 근거로 쓰지 않는다.** 저자 소속만은 교체 과정에서 1차 확인이 안 되어 아예 뺐다(아래 한계 참조). 이 문서가 §4.1·§5.3에서 남의 인용 정확도를 정정하므로 자기 경로도 적어 둔다.

**추가 조사 (2026-08-03) — 효과 크기와 잡음 바닥**

- WebFetch 8회 — `arxiv.org/html/2605.23950v1` 2회(전반·표적), `arxiv.org/html/2506.09501v2`, `arxiv.org/html/2606.00920v1`, `arxiv.org/html/2602.11619`, `arxiv.org/abs/2510.11977`, `arxiv.org/pdf/2606.00920`(실패), `hal.cs.princeton.edu/reliability`(타임아웃)
- **브라우저(Chrome) 도구 호출 12회** — WebFetch가 실패한 뒤의 폴백. 탭 컨텍스트 2, 네비게이션 6, 텍스트 추출 4(그중 2회는 로딩 정지로 실패). 경로: arXiv abs → HAL reliability 대시보드(**JS 로딩 정지**) → ar5iv 변환(**실패**) → OpenReview. **OpenReview에서 HAL이 ICLR 2026 Poster임을 확인했으나 얻은 것은 초록과 심사평이고 본문이 아니다.** 봇 검증 화면은 우회하지 않았다
- **PDF 전문 추출 1건** — 브라우저까지 실패한 뒤의 마지막 폴백. `arxiv.org/pdf/2510.11977`(12MB, 66쪽)을 내려받아 스크래치패드의 격리 venv에 `pypdf`를 설치해 171,955자를 추출했다. **시스템에는 아무것도 설치하지 않았다.** 이 경로에서 §1.6.3.1의 세 발견이 나왔고, **`pass^k` 오귀속도 여기서 잡혔다**
- WebSearch 3회 — 위치 파악용
- 산출: **§1.5·§1.6 신설**, §0 요지·§0 자료표·§6.4.1·§7-3·§7-9 갱신

**경로 기록** — HAL 본문에 닿기까지 다섯 번 시도했다. WebFetch(HTML) 404 → ar5iv 변환 실패 → reliability 대시보드 JS 정지 → OpenReview(초록·심사평까지) → **PDF 직접 추출 성공.** **앞의 네 번에서 멈췄다면 §1.6.3.1이 통째로 없었을 것이고, `pass^k` 오귀속이 문서에 남았을 것이다.**

**한계**

- **§1.5의 제3자 수치(§1.5.2)는 논문이 인용한 값이며 이 문서 기준 2차다.** 각 원출처(SEAL·HAL·xAI·WarpGrep·Lin et al.)를 직접 확인하지 않았다. **§1.5.3의 결론은 저자들 자신의 통제 실험(§1.5.1)만으로도 성립하도록 썼다.**
- **§1.5.1의 통제 실험은 셀당 2회 실행이다.** 그리고 `HV/MV` 비가 회차 간 8.72×↔6.76×로 흔들린다. 논문이 실행 간 표준편차를 별도로 보고하지 않는다. **잡음 바닥은 §1.6에서 별도 자료로 다뤘고, 그 절도 pp 단위 표준편차에는 닿지 못했다(§1.6.5).**
- **"구성요소 하나 추가 → `δ ≈ 0.02`"의 근거가 사례 하나뿐이다**(WarpGrep). §7-3 참고.
- **`δ` 값은 벤치마크 통과율 기준이고 grid fin의 단위와 다르다**(§1.5 전이 한계).
- **가장 중요한 수치(1,000문항)의 출처가 프리프린트다.** Miller의 글은 arXiv 프리프린트이며 **피어리뷰를 거치지 않았다.** 판본은 **v1(2024-11-01) 하나뿐**이라 §4.2 같은 판본 간 수치 변동은 없다. **저자 소속은 확인하지 못했다** — abs 페이지에 기재가 없다(검색 요약이 Anthropic이라 했으나 1차 확인이 안 되어 쓰지 않는다).
- ~~**`n ≈ 969`의 파라미터를 확인하지 못했다.**~~ **출처 감사(2026-08-02)에서 원문 확인 — §1.2.1 참고.** `δ=0.03`·`α=0.05`·`β=0.20`·`ω²=1/9`·`σ²=0`이다. **그 결과 §6.4의 결론이 조건부로 약화되었다(§6.4.1).**
- **Miller의 하네스 전이는 이 문서의 추론이다.** 대상이 정적 QA 벤치마크이고 저자가 코딩 에이전트를 말하지 않았다(§6.4-3에 명시).
- **Chen et al.의 본문을 읽지 못했다.** abs에 본문이 없고 2021년 논문이라 arXiv HTML 렌더링이 없다. **공식 구현 코드로 대체했으며, 그것이 논문 정의를 구현한다고 전제했다.**
- **SkillGenBench는 초록만 확인했다.** §5.3의 "생성을 잰다"는 판정은 제목과 초록 근거이며 본문 미확인이다.
- **Galster et al.은 v5를 인용했고 v1과 수치가 다르다**(§4.2 버전 고정 참고). 프리프린트이고 판본이 5개다.
- **MLflow 공식 문서는 얻은 것이 얇아 본문에 쓰지 않았다.** 스코어러가 코드 기반과 LLM 판정 둘로 갈리고 회귀 테스트 항목이 있다는 것까지만 확인했다. §6-2의 "역할 분담"에 대한 규범적 답은 주지 않는다.
- **§6.4의 41건과 [상태·연속성 조사](state-and-continuity.md)의 21건은 서로 다른 저장소다** — 그쪽 부록이 근거를 `cygnus 직접 검사 … git 이력 208커밋(머지 21건)`으로 명시한다. **조정했다.** 두 저장소를 모두 다시 세어 §6.4에 나란히 실었고(cygnus는 확인 시점 210커밋·머지 21건), 기간이 짧아 월 환산이 오히려 harness보다 높다. **격차의 방향은 어느 기준이든 같다.**
- **월 환산은 짧은 관측 구간의 외삽이다.** cygnus는 19일치이고 초기 개발 구간이라 정상 상태 속도가 아닐 수 있다.
- **§6은 측정의 부재가 아니라 측정 범위의 협소함을 확인했다.** eval은 존재하고 재실행하면 통과한다. 문제라 부를 수 있는 것은 셋이다 — 대상이 47종 중 2종이고, 판정이 텍스트 존재 여부까지이며, 100일 동안 실행되지 않았다.
