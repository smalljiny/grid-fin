# 검증 계층과 다중 모델 교차 리뷰 — 조사

**최초 작성**: 2026-08-02
**최종 수정**: 2026-08-02
**대상 프로젝트**: grid fin (신규 개인용 개발 하네스)
**1차 관측 대상**: cygnus `docs/_local/**/review-report-*.md` **21건 (신규·미분석)**, `/Users/mario/Workspace/harness` — `.claude/hooks/hooks.json`, `wf-verification`, `flow-review`, `adapter-codex-review`, `stack-e2e-testing`, `.harness/contracts/review-report.md`
**조사 도구**: WebFetch 3회(본문), WebSearch 4회, 브라우저 직접 읽기 1회, 로컬 저장소 직접 집계
**성격**: 조사. 검증 계층의 형태와 리뷰 방향의 선택은 하지 않는다.

선행 문서
- [research-agenda.md](research-agenda.md) §3·§4 — 이 조사의 출처
- [error-recurrence-prevention.md](error-recurrence-prevention.md) §7 — spec/plan 리뷰 55건 분석. 이 문서는 그것이 다루지 않은 코드리뷰 층을 본다
- [workflow-and-feature-list.md](workflow-and-feature-list.md) §1.3·§4.1 — 완료 판정 주체 문제

---

## 0. 조사 요약

### 0.1 이 조사가 도달한 지점

**1차 관측 3건이 확립된 소프트웨어공학 문헌의 세 결론에 각각 대응한다.** 이것이 이 문서의 뼈대다. 관측만으로는 "우리 하네스가 이렇더라"에 그치고, 문헌만으로는 적용 여부를 모른다. 둘이 맞물리는 지점이 판단 근거가 된다.

| 이 조사의 1차 관측 | 대응하는 문헌 | 문헌 등급 |
|---|---|---|
| 훅 9개 중 **차단 0개**, 명시적 `exit 0` | Google: 경고는 무시되므로 **컴파일 에러로 승격**했다 | CACM 2018 |
| 리뷰 지적 163건 중 **128건(78.5%) 미조치** | Google의 **"effective false positive"** 정의 = 그것. 코드리뷰 분석기 허용 상한 **10%**, 초과 시 분석기 비활성화 | CACM 2018 |
| 뮤테이션 RED 게이트가 **21건 중 4건**에서 즉흥적으로 등장 | Google은 뮤턴트의 **99%를 억제**하고 리뷰당 노출량에 상한을 걸어 productive 비율을 **15%→89%**로 올렸다 | ICSE-SEIP 2018 / TSE |

### 0.2 관측 요약

| # | 관측 | 근거 | 등급 |
|---|---|---|---|
| 1 | **하네스의 훅 9개 중 차단하는 것이 0개다.** 전부 센서이며 게이트가 아니다 | §1.1 | 1차 |
| 2 | **`git-push-review.js`는 주석으로 "막지 않음"을 명시하고, 존재하지 않는 `/dev:review`를 참조한다** | §1.1 | 1차 |
| 3 | **Fowler의 3계층 중 계층 3(행동·E2E)이 비어 있다.** 유일한 E2E 스킬은 Playwright(웹)인데 대상은 Flutter다 | §1.3 | 1차 |
| 4 | **코드리뷰 21건에서 `adversarial-review`(Codex)가 21/21 실행됐다** | §2.1 | 1차 |
| 5 | **그 리뷰어 판정은 19/21(90.5%)이 `needs-attention`, 17/21이 "No-ship" 프레이밍이다** | §2.2 | 1차 |
| 6 | **이슈 163건 중 128건(78.5%)이 `deferred`이고 재리뷰가 없어 종착 상태다** | §2.3 | 1차 |
| 7 | **`status` 필드가 계약의 도출식과 어긋나고, 계약에 없는 값 4종이 쓰인다** | §2.4 | 1차 |
| 8 | **뮤테이션 기반 RED 게이트가 4/21에서 관측된다 — 계약 어디에도 없다** | §2.5 | 1차 |
| 9 | **적대적 디베이트 1건 관측 + 오탐의 기계적 원인 기록** — 리뷰어의 `rg`가 exit 2로 실패해 스펙 미독 상태로 판정 | §4.3 | 1차 |
| 10 | **리뷰어는 읽기 전용이 아니다** — `codex exec -s workspace-write`, 120초 타임아웃 | §4.2 | 1차 |
| 11 | **Google은 "개발자가 조치하지 않은 지적"을 effective false positive로 정의하고 10%를 상한으로 둔다.** cygnus 환산치는 78.5% | §3.1 | CACM 2018 |
| 12 | **경고(warning)는 무시되므로 컴파일 에러로 올렸다는 것이 Google의 명시적 설계 결정이다** | §3.2 | CACM 2018 |
| 13 | **노출 위치가 판정 품질을 가른다** — 컴파일 시점 지적은 74%가 "진짜 문제", 체크인 후는 21% | §3.3 | CACM 2018 |
| 14 | **뮤테이션 테스팅의 실용화 핵심은 생성이 아니라 억제였다** — 변경당 820개 → 7개 | §3.4 | ICSE-SEIP 2018 / TSE |
| 15 | **통제 실험에서 "Codex가 Claude 산출물을 리뷰"하는 방향은 통과율을 91.4% → 82.8%로 떨어뜨렸다** | §4.4 | 2026 프리프린트 |
| 16 | **LLM 판정자의 자기선호는 perplexity 기반 친숙도에서 온다** — 교차 리뷰에 대한 함의가 대칭적으로 나온다 | §4.5 | 피어리뷰 |

### 0.3 출처와 근거 등급

**이 문서는 walkinglabs에 의존하지 않는다.** 아젠다 §3은 강의 9·10을 참고 자료로 들었다. [지시 계층 조사 §0](instruction-layers.md)이 경고했듯 앞선 두 문서가 같은 자가출판 출처에 의존했고, 이 문서가 따라가면 세 번째가 된다. 대신 개념 축은 Fowler 원문에서, 정량 기준은 **산업 규모에서 재현된 피어리뷰 문헌**에서 가져왔다.

| 등급 | 자료 | 신뢰 근거 |
|---|---|---|
| **1차 관측** | cygnus 리뷰 산출물 21건 전수 집계, 하네스 파일 직접 읽기 | 사실 |
| **확립된 문헌** | Sadowski et al., *Lessons from Building Static Analysis Tools at Google*, **CACM 61(4), 2018** | 피어리뷰 저널. 12년간의 산업 운영 경험. Facebook Infer 등에서 독립 재현 |
| **확립된 문헌** | Petrović & Ivanković, *State of Mutation Testing at Google*, **ICSE-SEIP 2018** + *Practical Mutation Testing at Scale* | 피어리뷰. 776,740 변경 · 1,690만 뮤턴트 규모 |
| **확립된 문헌** | Johnson et al., *Why don't software developers use static analysis tools to find bugs?*, **ICSE 2013** | 피어리뷰. 이 분야 표준 인용 |
| **문헌 (본문 확인)** | Fowler, *Harness engineering for coding agent users* | 저자의 명시적 진술. 실증 아님 |
| **워크숍 피어리뷰 (LLM)** | *Self-Preference Bias in LLM-as-a-Judge* (arXiv 2410.21819) | **NeurIPS 2024 Safe Generative AI Workshop 채택** — 본회의가 아니다([출처 감사 §2.2](source-audit.md)에서 정정) |
| **프리프린트** | arXiv 2607.21656 (본문 확인), 2603.16244·2604.19049 (요약만) | 2026 프리프린트. 피어리뷰 전 |

**핵심 유의 — Google 문헌의 전이 범위.** 규모가 다르다(일 5만 리뷰 vs 3개월 21건). **전이되는 것은 지표의 정의와 임계값의 존재이지 수치의 절대값이 아니다.** "effective false positive"라는 개념과 "10%를 넘으면 분석기를 끈다"는 규칙은 규모와 무관한 설계 원칙이고, "일 250건의 not-useful 클릭" 같은 운영치는 전이되지 않는다. 이 구분을 §3에서 매번 명시한다.

**두 번째 유의 — §2와 §4.4의 관계.** 두 데이터가 같은 방향을 가리키지만 **설정이 다르다.** 논문은 저장소 없는 자족 프로그램의 정적 리뷰, cygnus는 실저장소 패치 리뷰다. 일치를 확증으로 읽으면 안 된다(§6-1).

---

## 구현 참조 자료 — 외부 자료 정리

> **이 절의 쓰임.** 이 조사가 확인한 외부 자료를 **구현 시 그대로 참조할 수 있는 형태**로 모았다. 논증과 검증 상태는 괄호 안 절 번호에 있다.

### A. 지표와 임계값 — Google, CACM 61(4) 2018

**이 조사에서 얻은 가장 이식성 높은 자료다.** [Sadowski, Aftandilian, Eagle, Miller-Cushon, Jaspan](https://cacm.acm.org/research/lessons-from-building-static-analysis-tools-at-google/) — 피어리뷰 저널, 12년 산업 운영.

**지표 정의** (§3.1, 원문 확인):

> *"We consider an issue to be an **'effective false positive' if developers did not take positive action after seeing the issue.** If an analysis incorrectly reports an issue, but developers make the fix anyway (…), that is not an effective false positive. If an analysis reports an actual fault, but the developer did not understand the fault and therefore took no action, that **is** an effective false positive."*
>
> *"Developers, not tool authors, will determine and act on a tool's perceived false-positive rate."*

**지적의 참·거짓이 아니라 조치 여부로 정의된다.** 어떤 검사에도 적용 가능하다.

**운영 임계값**:

| 층 | 허용 effective FP | 규칙 |
|---|---|---|
| **차단** (컴파일 에러) | **0%** | *"the analysis should never stop the build for correct code."* 추가 조건 — 이해하기 쉬울 것, 고치기 쉬울 것(가능하면 기계 적용 가능한 수정 제시), **정확성 문제만** 다룰 것 |
| **비차단** (코드리뷰) | **≤10%** | *"Developers should feel the check is pointing out an actual issue at least 90% of the time."* **초과 시 분석기 비활성화** — Tricorder는 not-useful 클릭 비율이 10%를 넘으면 저자가 고칠 때까지 끈다 |

> 저자 각주가 10%의 성격을 밝힌다 — *"initially chosen by the first author somewhat arbitrarily"* 이나 경험적으로 유지됐다. **임계값의 존재와 초과 시 규칙이 전이되는 것이지 숫자가 아니다.**

**배치 규정** (§3.2·§3.3):

- *"the Clang team enabled the new diagnostic as a **compiler error (not a warning, which the Clang team found Google developers ignored)** to break the build"* — 경고는 무시된다는 관측에 근거한 설계 결정
- 노출 시점별 개발자 인식: **컴파일 시점 지적은 74%가 "진짜 문제", 체크인 후는 21%.** critical은 6% vs 0%. 원인은 **survivor effect** — 늦은 지점일수록 비싼 수단이 이미 걸러냈다
- 실패 선례: 2009년 사내 FindBugs Fixit — 9,473건 중 3,954건 검토(42%), **실제 수정은 640건(16%)**. 그 앞 단계(대시보드)는 *"outside the developers' usual workflow"* 라 아예 안 봤다
- *"Google developers have a strong bias to ignore static analysis, and any false positives or poor reporting give them a justification for inaction."*

### B. 신호 억제 — 뮤테이션 테스팅 at Google

[Petrović & Ivanković, ICSE-SEIP 2018](https://dl.acm.org/doi/10.1145/3183519.3183521) / [확장판](https://arxiv.org/abs/2102.11378). 776,740 변경 · 1,690만 뮤턴트 규모 (§3.4).

**정의**:

| 구분 | 정의 |
|---|---|
| **productive** | *"elicits an effective test, or otherwise advances code quality."* |
| **unproductive (arid)** | *"trivially equivalent to the original program, or it is detectable, but adding a test for it would not improve the test suite."* 예: 로깅, 메모리 사전할당, 시간 연산 |

**실용화의 본체는 생성이 아니라 억제였다**:

| 항목 | 값 |
|---|---|
| 변경당 뮤턴트 (전통) | 중앙값 **820개** |
| 변경당 뮤턴트 (억제 후) | 중앙값 **7개** (≈99% 억제) |
| 전체 생성 → 노출 | 1,690만 → **210만 (12.5%)** |
| **노출량 상한** | **변경 파일 수 × 7** — *"to ensure that the cognitive overhead of understanding the reported mutants is not too high"* |
| 초기 개발자 판정 | **85%가 unproductive** |
| productive 비율 추이 | **15% → 89%** (6년) |
| 비용 | *"Evaluating and resolving a single mutant takes several minutes"* |

**노출 위치와 집계 지표에 대한 규정**:

- *"We display mutation analysis results during the code review process because this maximizes the probability that the results will be considered by the developers."*
- 절대 뮤테이션 점수는 *"neither concrete nor actionable, and does not guide testing"* — **집계 지표를 거부한다**

### C. 개념 축 — Fowler

[Harness engineering for coding agent users](https://martinfowler.com/articles/harness-engineering.html) (원문 확인).

| 구분 | 정의 |
|---|---|
| **가이드 (feedforward)** | *"anticipate the agent's behaviour and aim to steer it **before** it acts"* |
| **센서 (feedback)** | *"observe **after** the agent acts and help it self-correct"* |
| 계산적 검증 | *"Run in milliseconds to seconds; results are reliable."* → **통합 전** |
| 추론적 검증 | *"Slower and more expensive; results are more non-deterministic."* → **통합 후, 비싼 분석용** |

**검증 3범주 중 행동이 가장 미해결**이라고 명시 — *"we still have a lot to do to figure out good harnesses for functional behaviour that increase our confidence enough to reduce supervision and manual testing."* AI 생성 테스트에 대해서는 *"puts a lot of faith into the AI-generated tests, that's not good enough yet."*

**미해결로 남긴 질문**: *"If sensors never fire, is that a sign of high quality or inadequate detection mechanisms?"* — §3이 그 거울상(90% 발화)에 답한다.

### D. 리뷰 방향의 비대칭 — 통제 실험

[Cross-Model LLM Code Review (arXiv 2607.21656)](https://arxiv.org/html/2607.21656v1), 본문 확인. LiveCodeBench hard·medium 116과제, Claude Opus 4.7 × Codex GPT-5.5, 6조건 (§4.4).

| 조건 | 통과율 [95% CI] |
|---|---|
| Claude 단독 | 91.4% [.862, .957] |
| Codex 단독 | 71.6% [.629, .793] |
| **OA — Codex 작성 → Claude 리뷰** | **89.7%** (pBH=.001) |
| **AO — Claude 작성 → Codex 리뷰** | **82.8%** (pBH=.046) — **단독보다 낮다** |
| Codex 자기리뷰 | 84.5% |

> *"AO does the opposite, fixing only 3 of Claude Opus 4.7's failures but breaking 13 of its successes (net −10)."* 회귀율 AO 11.2%로 최고.
>
> 메커니즘: *"the O reviewer tends to discard the writer's data structure and start over"* vs *"Claude Opus 4.7 as reviewer tends to keep the writer's interface and repair one local invariant."*
>
> 비용: OA는 과제당 $0.25 추가, 순수정당 약 $1.40.

**전이 조건이 중요하다** — 논문은 *"The reviewer cannot run the code, query a test runner, see hidden tests, or inspect execution traces. This is the **static review** setting"* 이고 대상이 *"self contained Python programs (…), not patches inside a live repository"* 다. **실저장소 패치 리뷰에 그대로 옮기면 안 된다.**

### E. 다중 라운드에 대한 반대 증거

| 자료 | 주장 | 확인 상태 |
|---|---|---|
| [More Rounds, More Noise (arXiv 2603.16244)](https://arxiv.org/pdf/2603.16244) | *"Additional rounds increase recall modestly but generate false positives at a much higher rate, destroying precision."* **최적 라운드 수 1** | **검색 요약만** |
| [Refute-or-Promote (arXiv 2604.19049)](https://arxiv.org/pdf/2604.19049) | 오탐 억제를 정면 목표로 — adversarial kill mandate, **context asymmetry**, Cross-Model Critic | **검색 요약만** |

**§4.6이 구분을 제시한다** — "한 번 더 묻는다"와 **"빠진 근거를 주고 다시 묻는다"** 는 다른 조작이다. 위 논문이 부정하는 것은 전자다.

### F. 판정자 편향의 메커니즘

[Self-Preference Bias in LLM-as-a-Judge (arXiv 2410.21819)](https://arxiv.org/abs/2410.21819) — LLM은 **perplexity가 낮은(친숙한) 출력에 인간 평가자보다 높은 점수**를 주며 이는 자기 생성 여부와 무관하다. family bias(같은 계열 선호)도 보고된다.

> **대칭항은 이 문서의 추론이다** — 친숙도가 원인이라면 교차 모델 리뷰어에게 작성자 출력은 정의상 덜 친숙하므로 체계적으로 박하게 평가할 것으로 예측된다. **어느 출처도 그렇게 주장하지 않는다**(§4.5).

### G. 다른 조사와 맞물리는 지점

| 지점 | 연결 |
|---|---|
| A의 effective FP 정의 | [오류 재발 §7.5](error-recurrence-prevention.md)가 1차 관측으로 도달한 "NOTE 26회 미소비"에 지표 이름과 임계값을 준다 |
| A의 차단 조건(FP 0%) | [강제 메커니즘 §7](enforcement-mechanisms.md)이 이 조건으로 하네스 검사들의 차단 적격성을 분류 |
| B의 노출량 상한 | [워크플로우 §4.3](workflow-and-feature-list.md)의 리뷰 크기 실증(중앙값 24~44줄)과 같은 방향 — 인지 부담 상한 |
| A의 10% 임계 | [보안 §3.2](security.md) — LLM 스킬 스캐너 오탐률 74.6%가 이 임계의 7배 |

---

## 1. 1차 관측 — 검증 계층은 실제로 어떻게 배치되어 있나

> **이 절부터 §5까지는 기존 하네스(cygnus) 실측이며, 위 자료가 이 프로젝트에 해당하는지 확인하는 보조 근거다.** 다만 §2의 코드리뷰 산출물 21건 집계는 선행 조사가 다루지 않은 신규 1차 데이터이고, §3은 Fowler가 미해결로 남긴 질문의 거울상에 답한다.

### 1.1 훅 9개, 게이트 0개

`.claude/hooks/hooks.json` 전체다.

> **정정 (2026-08-02, [강제 메커니즘 조사](enforcement-mechanisms.md) §1.1).** 인용해야 할 파일은 `.claude/settings.json`의 `hooks` 블록이었다. 공식 문서가 *"`.claude/hooks/hooks.json` is NOT read for non-plugin projects"* 로 명시하고, 하네스에는 `.claude-plugin`이 없다 — **저 파일은 로드되지 않는다.**
>
> **아래 표와 "게이트 0개" 결론은 그대로 유효하다.** `settings.json`에 같은 훅 9개가 같은 스크립트를 가리키며 정의되어 있고, 차단 경로 검사는 스크립트를 직접 본 것이기 때문이다. 다만 **결정론적 검사가 차단 불가능한 이벤트에 놓여 있다**는 사실은 그 조사에서 보지 못했다 — `PostToolUse`는 exit 2로도 차단되지 않는다. 강제 메커니즘 조사 §1.2가 그 배치를 다룬다.

| id | matcher | 성격 |
|---|---|---|
| `session:start:load-context` | SessionStart | 컨텍스트 주입 |
| `pre:edit:suggest-compact` | Edit | 제안 |
| `pre:write:suggest-compact` | Write | 제안 |
| `post:edit:typescript-check` | Edit | **계산적 검증** |
| `post:edit:prettier-format` | Edit | **계산적 검증** |
| `post:tool:session-logger` | `*` | 관찰 |
| `pre:bash:git-push-review` | Bash | 체크리스트 출력 |
| `stop:console-log-audit` | Stop | **계산적 검증** |
| `stop:memory-persist` | Stop | 기록 |

계산적 검증은 세 곳에 있다. 그러나 **차단 경로가 존재하지 않는다.** 스크립트 8개의 종료 경로를 전수 검사한 결과:

- `process.exit()` 호출 **18개 전부가 `exit(0)`** 이다
- 비-0 종료, 미포착 `throw`, catch 블록의 재throw가 **0건**
- `{"decision":"block"}` 등 stdout JSON 제어 출력 **0건**

그리고 **비차단이 사고가 아니라 의도임을 주석이 명시한다.** 세 파일에서 각각:

```javascript
console-log-audit.js:59   process.exit(0)  // 경고만 출력, 세션 종료를 막지 않음
type-check.js:53          process.exit(0)  // 훅 실패로 Claude Code를 막지 않음
git-push-review.js:27     process.exit(0)  // exit 0: push를 막지 않음 (정보 제공만)
```

`git-push-review.js`는 여기에 더해 **존재하지 않는 커맨드를 참조한다.**

```javascript
console.log('  □ /dev:review 를 완료했는가?')
```

`/dev:review`는 없다(선행 조사 §5.2의 `/dev:*` 화석과 같은 부류). 체크리스트가 가리키는 대상이 없고, 답이 무엇이든 push는 진행된다.

Fowler의 축으로 옮기면 — **이 하네스는 거의 전부 센서이고 가이드가 없다.** 이 배치가 왜 문제인지는 §3.2에서 문헌과 대조한다.

### 1.2 완료 게이트는 에이전트가 실행한다

`/flow-verify`는 19줄이며 전량 위임한다.

```markdown
Load `.claude/skills/wf-verification/SKILL.md` and follow its process.
```

`wf-verification`(106줄)이 5개 게이트를 순차 정의한다.

```
[1] build → [2] type-check → [3] lint → [4] test → [5] security
```

전부 계산적 검증이고 명령이 구체적이다(`pnpm build`, `pnpm tsc --noEmit`, `pnpm lint`, `pnpm test`, `pnpm audit`, 커버리지 80%). 아젠다 §3-3이 물은 "완료 게이트 설계"에 대한 실물 답이다.

그러나 **이 명령들을 실행하고 결과를 판정하는 주체가 에이전트다.** 스크립트가 아니고 종료 코드를 읽는 게이트도 아니다. [워크플로우 조사 §1.3](workflow-and-feature-list.md)이 Story 체크박스에서 발견한 구조 — 판정자와 기록자가 같음 — 가 완료 게이트에도 그대로 있다.

부수 관측: 5개 게이트가 전부 `pnpm` 하드코딩이다. 선행 조사가 (D) 유형(참조 데이터 낡음)으로 분류한 `commit-scopes.md`와 같은 성격의 **core 안에 있는 프로젝트 config**다.

### 1.3 계층 3(행동)은 비어 있다

Fowler의 3계층에 하네스 자산을 대응시키면 이렇다.

| 계층 | 하네스 자산 | 상태 |
|---|---|---|
| 1. 문법·정적 | `type-check.js` 훅, `wf-verification` gate 2·3 | 있음 |
| 2. 실행 동작 | `wf-verification` gate 1·4, Firestore 에뮬레이터 테스트 | 있음 |
| 3. 시스템·E2E | `stack-e2e-testing` | **적용 불가** |

`stack-e2e-testing`(336줄)은 전량 Playwright다 — `npx playwright test`, `playwright.config.ts`, Page Object Model, CI 워크플로우. frontmatter는 `origin: ECC`로 하네스 자산도 아닌 외부 도입 컴포넌트다.

**대상 프로젝트는 Flutter + Firebase다.** cygnus 확인 결과: `playwright.config.*` 없음, `integration_test/`·`e2e/` 없음, 테스트는 Dart 34 + TypeScript 49개(전부 단위·통합 수준).

즉 **아젠다 §3-2가 물은 "프로젝트 유형별 E2E 도구 선택"은 이 하네스에서 선택된 적이 없다.**

> **아젠다 §3-2의 토큰 수치(Playwright MCP 114K / CLI 27K / agent-browser 5.5K)는 재현하지 않았다.** 확인한 것은 **하네스가 이미 CLI 방식을 채택했다**는 사실이다(MCP 언급 0건). 선택 근거는 문서화되어 있지 않다.

---

## 2. 신규 1차 데이터 — 코드리뷰 산출물 21건

선행 조사 §7은 `spec-review` 27건 + `plan-review` 28건 = 55건을 집계했다. **`review-report` 21건은 손대지 않았다.**

계약(`.harness/contracts/review-report.md`)은 리뷰어 3종(`code-reviewer` / `security-reviewer` / `adversarial-review`)과 `처리 내역` 표(`issue` / `severity` / `reviewer` / `status`)를 규정한다.

**주목할 점**: 선행 조사 §7.2가 spec/plan 리뷰의 **결정적 결손**으로 "지적의 해소 결과가 어디에도 기록되지 않는다"를 들었는데, **코드리뷰 층에는 그 필드가 있다.** `status: fixed | deferred`가 그것이다. 문제는 그 필드가 무엇을 담고 있느냐다(§2.4).

### 2.1 교차 리뷰는 100% 실행된다

| reviewer | run | skipped |
|---|---:|---:|
| code-reviewer | 21 | 0 |
| security-reviewer | 21 | 0 |
| **adversarial-review** | **21** | **0** |

계약은 `adversarial-review`에 skip 사유 5종을 정의해 두었으나 **한 번도 쓰이지 않았다.**

[워크플로우 조사 §6.3](workflow-and-feature-list.md)이 "기존 하네스가 Spec Kit 계열보다 앞선 유일한 지점"으로 지목한 다른 모델 패밀리 독립 리뷰어가, **스펙·계획 단계뿐 아니라 코드 단계에서도 예외 없이 돌고 있다.**

### 2.2 그 리뷰어는 거의 항상 문제를 찾는다

| Verdict | 건수 |
|---|---:|
| `needs-attention` | **19** |
| `approve` | 2 |

2건의 `approve` 중 1건은 **1차 `needs-attention`을 뒤집은 2차 재판정**이다(§4.3). 즉 **1차 통과는 21건 중 1건(4.8%)** 이다.

"No-ship" 또는 "Do not ship" 프레이밍이 **17/21**에 등장한다.

> *"No-ship: this breaks idempotency across deploy/version skew and can duplicate ledger mutations."*
> *"Do not ship: the Firestore rule widens the trust boundary too far…"*

**발화율이 특히 문제인 이유는 실행 순서 때문이다.** `flow-review` SKILL.md 129행:

> *"CRITICAL·HIGH 수정이 완료된 후 실행한다 (정제된 상태를 대상으로 해야 adversarial 피드백이 유효)."*

`adversarial-review`는 code-reviewer와 security-reviewer가 이미 돌고 그들의 CRITICAL·HIGH가 이미 수정된 코드를 본다. **두 리뷰어를 통과한 코드에 대해 90%가 "출시 불가"다.**

### 2.3 그리고 그 지적은 대부분 처리되지 않는다

처리 내역 표 전수 집계 — 이슈 **163건**.

| severity | fixed | deferred | withdrawn | 계 |
|---|---:|---:|---:|---:|
| CRITICAL | 2 | 0 | 0 | 2 |
| HIGH | 13 | 9 | 1 | 23 |
| MEDIUM | 16 | 36 | 0 | 52 |
| LOW | 3 | 83 | 0 | 86 |
| **계** | **34** | **128** | **1** | **163** |

> HIGH 23건에는 계약 밖 표기인 `HIGH (latent)` 1건을 포함해 셌다. 같은 항목을 §2.4에서는 계약 enum 위반 사례로도 든다 — 집계에서는 HIGH로 취급하고, 형식 검사 관점에서는 위반으로 취급한다.

**`deferred` 128건 = 78.5%.** LOW는 83/86(96.5%)이 deferred다.

출처별로는 code-reviewer 88, security-reviewer 39, adversarial-review 33, 공동 3건이다. 교차 리뷰어가 전체 지적의 **20%**를 단독 생산한다 — 실행률뿐 아니라 산출량에서도 실질적이다.

**그리고 `deferred`는 종착 상태다.** 21개 보고서가 21개 토픽에 1건씩 대응한다. 재리뷰가 없으므로 **연기된 128건을 다시 보는 단계가 파이프라인에 존재하지 않는다.**

선행 조사 §7.5가 spec/plan 층에서 발견한 것과 같은 구조다 — 거기서는 차단하지 않는 NOTE가 26회 반복되며 아무것도 학습되지 않았고, 여기서는 차단하지 않는 `deferred`가 128건 쌓이며 아무도 읽지 않는다. **층은 다른데 실패 모드가 같다.** 이 실패 모드에는 이름이 있다(§3.1).

### 2.4 `status`는 계약과 어긋나고, 계약 준수를 검사하는 것이 없다

계약이 규정한 산출 알고리즘은 기계적이다.

> 3. 신규 commit **있음** → CRITICAL·HIGH: `fixed`, MEDIUM·LOW: `deferred`
> 4. 신규 commit **없음** → 모든 이슈: `deferred`

이 규칙이 지켜졌다면 **한 보고서 안에서 같은 severity는 같은 status를 가져야 한다.** 실제는 그렇지 않다.

```
core-ledger-authority   :: HIGH:fixed HIGH:deferred MEDIUM:fixed … LOW:fixed LOW:deferred
mission-report-approve  :: HIGH:fixed HIGH:deferred HIGH:deferred … LOW:fixed LOW:deferred
dashboard-readonly      :: HIGH (latent):fixed HIGH:deferred MEDIUM:deferred MEDIUM:fixed …
project-create          :: HIGH:fixed CRITICAL:fixed HIGH:deferred …
```

알고리즘상 불가능한 조합이 5개 보고서에 있고, 알고리즘이 금지하는 `LOW:fixed`가 3건 있다.

**해석은 두 갈래이며 둘 다 같은 결론으로 간다.** 에이전트가 도출식을 무시하고 이슈별 실제 판단을 썼거나(품질은 계약보다 낫다), 일관성 없이 썼거나. **어느 쪽이든 계약 준수를 검사하는 것이 없다는 사실은 같다.**

계약에 없는 값이 실제로 쓰였다는 점이 이를 확증한다.

| 관측된 값 | 계약 enum |
|---|---|
| `withdrawn (2차 재판정에서 철회 — …)` | `fixed \| deferred` |
| ``fixed (`61d1a52`)`` | `fixed \| deferred` |
| `HIGH (latent)` | `CRITICAL \| HIGH \| MEDIUM \| LOW` |
| `code-reviewer · security-reviewer` | 단일 리뷰어 식별자 |

**계약은 기계 판정 가능한 형식을 규정하면서 그것을 판정하는 계산적 검증을 붙이지 않았다.** 선행 조사 §7.8.2의 판별 축("이 규칙 위반을 코드로 판정할 수 있는가")에 정확히 걸린다 — 판정 가능한데 지식으로만 두었다.

### 2.5 계층 3의 공백을 메운 것은 계약 밖의 즉흥 기법이었다

§1.3에서 E2E가 비어 있음을 봤다. 그런데 리뷰 산출물에는 **뮤테이션 기반 판별력 검증**이 나온다. 4/21에서 관측된다.

code-reviewer가 테스트의 판별력을 논증하는 방식:

| 뮤테이션 | 감지 테스트 |
|---|---|
| `payouts.ts`가 `'events'`를 전달 | cross-route 1 → RED |
| **`payouts.ts`가 projectId 세그먼트 누락** | **없음 — 전부 GREEN** |

그리고 수정 후 검증:

> **뮤테이션 검증(RED 게이트)**: `idempotencyDocId(identity.projectId, ...)` 인자를 상수 `'MUTANT'`로 치환한 상태에서 실행 → `tests 8 / pass 6 / fail 2`, 실패 2건이 정확히 신규 테스트 (…) 뮤테이션 복구 후 전체 스위트 371/371 통과.

**Fowler가 미해결이라 한 행동 검증의 실물 근사다.** "테스트가 통과한다"가 아니라 "이 테스트만이 이 결함을 잡는다"를 실험으로 보인다. AI 생성 테스트를 그냥 믿는 문제(Fowler의 지적)에 대한 직접 대응이기도 하다.

**그런데 계약 어디에도 없다.** `implementation-plan.md`의 Completion Criteria에도, `review-report.md` 계약에도, `wf-verification`의 5게이트에도 없다. 4/21에서만 나타나므로 **하네스의 기능이 아니라 그때그때의 재량**이다. 이 기법을 제도화하려 할 때 무엇이 문제가 되는지는 §3.4가 다룬다.

---

## 3. 확립된 문헌과의 대조 — 이 실패 모드에는 이름이 있다

이 절이 이 조사에서 가장 중요하다. §1·§2의 관측이 새로운 현상이 아니라 **20년간 측정되고 해법까지 나온 현상**임을 보인다.

### 3.1 `deferred` 128건의 정확한 이름 — effective false positive

[Sadowski et al., CACM 61(4), 2018](https://cacm.acm.org/research/lessons-from-building-static-analysis-tools-at-google/)이 용어를 정의한다.

> *"We consider an issue to be an 'effective false positive' if developers did not take positive action after seeing the issue. If an analysis incorrectly reports an issue, but developers make the fix anyway to improve code readability or maintainability, that is not an effective false positive. If an analysis reports an actual fault, but the developer did not understand the fault and therefore took no action, that is an effective false positive."*

**정의가 지적의 참·거짓이 아니라 조치 여부에 걸려 있다.** 그리고 그 이유를 명시한다.

> *"Developers, not tool authors, will determine and act on a tool's perceived false-positive rate."*

이 정의로 §2.3을 환산하면 **cygnus의 effective false positive rate는 78.5%다.** 지적이 옳았는지는 무관하다 — 조치되지 않았으므로 정의상 그렇다.

Google이 이 지표에 건 임계값이 있다.

> *"Unlike compile-time checks, analysis results shown during code review are allowed to include up to 10% effective false positives. (…) Produce less than 10% effective false positives. Developers should feel the check is pointing out an actual issue at least 90% of the time."*

그리고 임계 초과 시의 조치가 규칙으로 박혀 있다.

> *"The Tricorder team tracks such not-useful clicks, computing the ratio of 'Please fix' vs. 'Not useful' clicks. If the ratio for an analyzer goes above 10%, the Tricorder team disables the analyzer until the author(s) improve it."*

**대조하면 이렇다.**

| | Google Tricorder (2018-01) | cygnus (2026-05~07) |
|---|---|---|
| 허용 상한 | **10%** | 없음 |
| 초과 시 조치 | **분석기 비활성화** | 없음 |
| 자체 실측 | 78.5% (deferred / 전체 이슈) | |

**전이되는 것은 임계값의 존재와 초과 시 규칙이지 Google의 운영 수치가 아니다.**

한 가지를 명시해 둔다. Tricorder의 공개 운영치(일 Please-Fix 5,000회 / Not-useful 250회, 비율 약 4.8%)를 78.5%와 나란히 놓고 싶어지지만 **두 수는 같은 측정이 아니다.** Tricorder 쪽은 **리뷰어가 굳이 반응한 클릭들 사이의 비율**이고 — 반응하지 않은 지적은 분모에도 분자에도 들어가지 않는다 — cygnus 쪽은 **모든 지적에 대한 전수 집계**다. 분모의 성격이 다르므로 두 값의 직접 비교는 성립하지 않으며, 비교하면 cygnus 쪽이 실제보다 나빠 보인다. 위 표에서 Google의 실측 행을 뺀 이유다.

비교 가능한 것은 이것뿐이다 — **Google은 이 지표에 상한과 초과 시 조치를 정해 두었고 cygnus에는 둘 다 없다.** "리뷰어를 끄자"는 결론이 아니다. §3.4가 실제로 쓰인 해법을 보여준다.

**동일 현상의 선행 실증**도 같은 논문에 있다. 2009년 Google 사내 FindBugs Fixit:

> *"They reviewed a total of 3,954 such warnings (42% of 9,473 total), but only 16% (640) were actually fixed, despite the fact that 44% of reviewed issues (1,746) resulted in a bug report being filed. Although the Fixit validated that many issues found by FindBugs were actual bugs, a significant fraction were not important enough to fix in practice."*

**검토된 것의 16%만 고쳐졌다.** cygnus의 21%(34/163)와 같은 자릿수다. 그리고 논문이 그 앞 단계에서 실패한 것을 기록한다.

> *"the dashboard saw little use because a bug dashboard was outside the developers' usual workflow"*

**§2.3의 "`deferred` 128건에 소비자가 없다"가 정확히 이 실패다.** 지적을 쌓아두는 곳이 워크플로우 밖에 있으면 아무도 안 본다. 2006년에 관측되고 2018년에 문서화됐다.

[Johnson et al., ICSE 2013](https://dl.acm.org/doi/10.1145/2486788.2486877)이 개발자 쪽 메커니즘을 준다 — 오탐, 빈약한 제시, **경고 포화(alert saturation)**, 워크플로우 부적합이 도입을 막는다. 그리고 **개발자는 처음 몇 개만 보고, 그것이 오탐이면 나머지를 보지 않는다.** LOW 86건 중 83건이 deferred인 §2.3의 분포가 이 서술과 부합한다.

> **적용 한계**: 위 문헌은 정적 분석 도구를 대상으로 한다. LLM 리뷰어는 오탐의 성격이 다를 수 있다(규칙 위반이 아니라 추론 오류). **effective false positive라는 지표의 정의는 도구 종류와 무관하지만, 10%라는 값이 LLM 리뷰어에도 맞는지는 근거가 없다.** 논문 자신도 이 값을 *"initially chosen by the first author somewhat arbitrarily"* 라고 각주에 밝힌다.

### 3.2 훅에 게이트가 없는 것 — Google은 반대 결론에 도달했다

§1.1에서 훅 9개 중 차단이 0개임을 봤다. 같은 논문이 정반대 경로를 기록한다.

> *"the Clang team enabled the new diagnostic as a compiler error (not a warning, which the Clang team found Google developers ignored) to break the build, a report difficult to disregard."*

**"경고는 무시되므로 빌드를 깨는 에러로 올렸다"** — 관측에 근거한 설계 결정이다. 그리고 결론부에서 일반화한다.

> *"Google developers have a strong bias to ignore static analysis, and any false positives or poor reporting give them a justification for inaction."*

다만 **아무거나 차단으로 올리지는 않는다.** 컴파일 에러 승격 기준이 별도로 있다.

> *"A compiler check at Google should be easily understood; actionable and easy to fix (…); produce no effective false positives (the analysis should never stop the build for correct code); and report issues affecting only correctness rather than style or best practices."*

**차단으로 올리려면 effective false positive가 0이어야 한다.** 10%가 허용되는 것은 차단하지 않는 코드리뷰 층이다. 즉 문헌이 주는 것은 "차단을 늘려라"가 아니라 **두 층을 다른 기준으로 운영하라**는 구조다.

| 층 | 허용 오탐 | 성격 |
|---|---|---|
| 차단 (컴파일 에러) | **0%** | 자동 수정 가능·정확성 한정 |
| 비차단 (코드리뷰) | **≤10%** | 판단 필요·초과 시 비활성화 |

cygnus에는 첫 행이 비어 있고(§1.1) 둘째 행에 임계값이 없다(§3.1).

### 3.3 노출 위치가 판정 품질을 가른다 — 측정된 수치가 있다

같은 논문이 노출 시점별로 개발자 인식을 측정했다.

> *"survey participants deemed 74% of the issues flagged at compile time as 'real problems,' compared to 21% of those found in checked-in code. In addition, survey participants deemed 6% of the issues found at compile-time (vs. 0% in checked-in code) 'critical.'"*

원인으로 **survivor effect**를 든다 — 커밋 시점에는 비싼 수단(테스트·코드리뷰)이 이미 걸러냈으므로 남은 것은 덜 중요한 것들이다.

**이것이 §2.2의 순서 문제에 직접 대응한다.** `adversarial-review`는 code-reviewer·security-reviewer가 이미 훑고 CRITICAL·HIGH가 수정된 코드를 본다 — survivor effect의 정의 그대로다. **그런데도 90%가 needs-attention이다.** 문헌이 예측하는 방향(뒤로 갈수록 진짜 문제 비율 하락)과 관측된 발화율(뒤에서도 90%)이 어긋난다.

이 어긋남은 두 가설 중 하나를 시사한다 — 리뷰어가 앞선 두 리뷰어가 못 잡는 종류를 잡고 있거나(그렇다면 상보적이고 가치 있다), 리뷰어가 남은 코드에서도 무언가를 찾도록 프레이밍되어 있거나. **이 조사는 둘을 가르지 못한다**(§6-3). 다만 §4.5가 후자에 대한 메커니즘 후보를 준다.

Fowler의 배치 규정도 이 지점에서 의미가 있다.

> 계산적: *"Run in milliseconds to seconds; results are reliable."* → 통합 전
> 추론적: *"Slower and more expensive; results are more non-deterministic."* → 통합 후

cygnus는 **추론적 검증 3종을 전부 PR 이전에** 둔다. 비결정적이고 비싼 리뷰어가 임계 경로 위에 있으므로 그 오탐이 곧바로 작성자의 처분 부담이 된다. **다만 개인 하네스에 "통합 후" 파이프라인이 존재하는지가 별개 문제다**(§6-4).

### 3.4 뮤테이션 테스팅 — 실용화의 핵심은 생성이 아니라 억제였다

§2.5에서 뮤테이션 RED 게이트가 4/21에서 즉흥적으로 등장함을 봤다. 이 기법에는 **산업 규모의 피어리뷰 선행 사례**가 있다 — [Petrović & Ivanković, ICSE-SEIP 2018](https://dl.acm.org/doi/10.1145/3183519.3183521) 및 확장판 *Practical Mutation Testing at Scale* ([arXiv 2102.11378](https://arxiv.org/abs/2102.11378)).

핵심 구분:

> **productive mutant** — *"elicits an effective test, or otherwise advances code quality."*
> **unproductive (arid) mutant** — *"Either trivially equivalent to the original program or it is detectable, but adding a test for it would not improve the test suite."*

그리고 **초기 상태가 §2.2·§2.3과 똑같았다.**

> 개발자들이 초기에 보고된 뮤턴트의 **85%를 unproductive로 분류**했다.

해법은 신호를 더 만드는 것이 아니라 **억제**였다.

| 항목 | 수치 |
|---|---|
| 변경당 뮤턴트 (전통적 방식) | 중앙값 **820개** |
| 변경당 뮤턴트 (억제 후) | 중앙값 **7개** (≈99% 억제) |
| 전체 생성 / 실제 노출 | 1,690만 → **210만 (12.5%)**, 776,740 변경 |
| 노출량 상한 | **변경 파일 수 × 7** — *"to ensure that the cognitive overhead of understanding the reported mutants is not too high"* |
| productive 비율 추이 | **15% → 89%** (6년) |

노출 위치도 명시적으로 골랐다.

> *"We display mutation analysis results during the code review process because this maximizes the probability that the results will be considered by the developers."*

그리고 집계 지표를 거부한다 — 절대 뮤테이션 점수는 *"neither concrete nor actionable, and does not guide testing."*

**이것이 §2.5의 제도화 질문에 주는 답의 형태다.** 뮤테이션 RED 게이트를 계약에 넣는 것은 기법의 도입이 아니라 **억제 정책의 설계**다. 억제 없이 켜면 §2.3의 128건이 몇 배로 늘어난다. 그리고 비용도 명시되어 있다 — *"Evaluating and resolving a single mutant takes several minutes."*

> **전이 한계**: Google의 억제는 arid node 정적 분석(로깅·메모리 사전할당·시간 연산 등)에 근거한다. 개인 하네스에서 그 분류기를 만드는 비용은 미측정이다. 그리고 cygnus에서 관측된 4건은 **자동 생성이 아니라 리뷰어가 직접 고른 뮤턴트**다 — 이미 선별된 것이므로 productive 비율이 높을 수밖에 없고, 자동화하면 그 이점이 사라진다.

---

## 4. 다중 모델 교차 리뷰

### 4.1 두 개의 Codex 경로가 있다

하네스에는 **성격이 다른 Codex 연동이 둘** 있고 서로를 명시적으로 배제한다. `adapter-codex-review`의 Non-Goals:

> *"Using `codex-companion.mjs` or adversarial-review infrastructure"* — 명시적 out of scope

| | spec/plan 리뷰 | 코드 adversarial 리뷰 |
|---|---|---|
| 진입 | `adapter-codex-review` 스킬 | `flow-review` Step 7 |
| 호출 | `codex exec -s workspace-write "<스킬>로 <경로>를 리뷰해줘"` | `node <companion> adversarial-review --wait --base <branch>` |
| 리뷰어 정의 | `.codex/skills/{spec,plan}-review` (하네스 소유) | **codex 플러그인 캐시 (외부 컴포넌트)** |
| 산출물 | `spec-review-<TS>.md` (Codex가 직접 작성) | stdout → Claude가 보고서에 인용 |
| 형식 계약 | 8항목 체크리스트 고정 | **없음 — 자유 서술** |

**두 번째 경로에는 형식 계약이 없다.** §2.2의 verdict 표기가 보고서마다 다른 이유가 이것이다. `.codex/skills/`에는 `spec-review`, `plan-review`, `eval-harness` 셋뿐 — **코드리뷰용 Codex 스킬은 하네스 자산이 아니라 외부 플러그인이다.**

### 4.2 리뷰어는 읽기 전용이 아니다

아젠다 §4-3은 "리뷰어에게 read-only 샌드박스를 주는 것의 효과"를 물었다. **관측된 설정은 read-only가 아니다.**

```bash
"$TIMEOUT_BIN" 120 codex exec -s workspace-write "spec-review 스킬로 ${CANON_PATH}를 리뷰해줘" < /dev/null
```

주석이 이유를 밝힌다 — *"리뷰 파일을 workdir 내에 쓸 수 있도록 명시적으로 허용."*

**아키텍처가 쓰기 권한을 강제한다.** 리뷰 산출물의 영속화를 Codex 스킬이 소유하기 때문이다(*"Bridge is read-only: The bridge skill never writes review files"*). read-only 리뷰어를 쓰려면 전달 경로를 파일 쓰기에서 stdout으로 바꿔야 한다 — 코드리뷰 경로가 이미 그 방식이다.

**120초 타임아웃**도 함께 봐야 한다. 리뷰어는 저장소 탐색·판정·파일 쓰기를 2분 안에 끝내야 한다. §4.3의 사고가 이 제약과 무관하지 않을 수 있다(미확인).

### 4.3 적대적 디베이트가 1건 관측됐다 — 오탐 원인까지 기록되어 있다

아젠다 §4-2는 다중 라운드 디베이트 루프를 문헌 조사 대상으로 놓았다. **실물이 하나 있다.** `idempotency-key-namespacing` 토픽이다.

**1차 — `verdict: needs-attention`**

> *"No-ship: this breaks idempotency across deploy/version skew and can duplicate ledger mutations. (…) A request that committed before or during a rolling deploy, then retries after hitting new code, will miss the prior record and execute the balance/event transaction again."*

**작성자가 기록한 원인 분석**

> *"1차 판정의 맥락 결손: 실행 로그상 `rg -n "legacy|migration|migrate|idempotencyKeys|idempotency" docs apps scripts …` 명령이 exit 2로 실패했다. 즉 스펙 문서를 읽지 못한 상태에서 나온 판정이다."*

**2차 — 근거 제시 후 재판정, `verdict: approve`**

> *"브랜치 diff 기준으로 이전 high finding은 철회한다. spec.md §3.4/§4는 (…) 명시 수용했고, 현재 근거만으로 no-ship으로 반박할 수 없다."*

이 한 사례가 셋을 동시에 보여준다.

1. **선행 조사의 (C) 유형(리뷰어 오독)이 코드리뷰 층에도 있으며, 여기서는 기계적 원인까지 특정됐다.** 리뷰어의 검색 명령이 실패했고 리뷰어는 그 사실을 판정에 반영하지 않았다. **도구 실패가 조용히 오탐으로 변환된다.**
2. **같은 보고서에 두 번째 오보고가 있다.** Codex가 `test:unit` 실패를 보고했으나 원인은 호출 방식이었다. 전체 스위트는 371/371 통과했다.
3. **디베이트가 실제로 오탐을 제거했다.** 근거를 제시하자 리뷰어가 자기 지적을 철회했다.

**그러나 셋 다 21건 중 1건에서만 일어났다.** 재판정 1/21, 리뷰어 도구 실패 문서화 1/21.

**여기서 이 조사의 가장 날카로운 미해결 질문이 나온다** — 리뷰어의 컨텍스트 획득 실패가 드문 것인지, **한 번만 발각된 것**인지 알 방법이 없다. 발각된 그 한 번도 하네스가 잡은 게 아니라 작성자가 실행 로그를 읽어서 잡았다. `codex exec`의 실패한 도구 호출을 하네스가 관측하는 경로는 없다.

부수 관측: `severity 재조정(HIGH→LOW) 후 defer`가 2건 있다. **수신자가 리뷰어의 severity를 하향 조정한다** — "the maker shouldn't grade the checker" 문제가 발생하는 지점이다.

### 4.4 통제 실험 — 역할 비대칭은 크고, 관측된 방향이 불리한 쪽이다

[Cross-Model LLM Code Review (arXiv 2607.21656)](https://arxiv.org/html/2607.21656v1) 본문을 확인했다. LiveCodeBench hard·medium 116과제, Claude Opus 4.7 × Codex GPT-5.5, 6개 조건.

| 조건 | 통과율 [95% CI] |
|---|---|
| Claude 단독 | 91.4% [.862, .957] |
| Codex 단독 | 71.6% [.629, .793] |
| **OA — Codex 작성 → Claude 리뷰** | **89.7%** [.836, .948] (pBH=.001) |
| **AO — Claude 작성 → Codex 리뷰** | **82.8%** [.759, .897] (pBH=.046) |
| Codex 자기리뷰 | 84.5% [.776, .905] |
| Claude 자기리뷰 | 91.4% |

**핵심은 AO 행이다.** Claude 단독 91.4%가 Codex 리뷰를 거치면 82.8%로 **떨어진다.**

> *"AO does the opposite, fixing only 3 of Claude Opus 4.7's failures but breaking 13 of its successes (net −10)."*

회귀율은 AO 11.2%로 최고다. 그리고 메커니즘 서술이 §2.2의 관측과 맞물린다.

> *"the O reviewer tends to discard the writer's data structure and start over"* / *"Claude Opus 4.7 as reviewer tends to keep the writer's interface and repair one local invariant."*

**"버리고 다시 시작하라"는 성향은 "No-ship" 프레이밍 17/21과 같은 얼굴로 보인다.** 그리고 **cygnus가 쓰는 방향이 AO다.**

**전이를 단정하면 안 된다.** 논문 설정이 명시되어 있다.

> *"The reviewer cannot run the code, query a test runner, see hidden tests, or inspect execution traces. This is the static review setting."*
> 벤치마크는 *"self contained Python programs with hidden tests, not patches inside a live repository."*

cygnus의 리뷰어는 **실저장소에 workspace-write로 접근하고 명령을 실행한다**(§4.2 — 실행 실패 사례까지 있다). 서로 다른 두 설정이다. 논문은 **"AO 방향은 회귀 위험이 크다"는 가설을 강하게 제기**하지만 cygnus에서의 성립 여부는 별도 측정이 필요하다(§6-1).

역방향 비용도 논문이 준다 — OA는 과제당 $0.25 추가, 순수정당 약 $1.40.

### 4.5 메커니즘 후보 — 자기선호 편향의 대칭항

[Self-Preference Bias in LLM-as-a-Judge (arXiv 2410.21819)](https://arxiv.org/abs/2410.21819)는 LLM 판정자가 자기 생성물에 높은 점수를 주는 현상을 정의하고 여러 모델·과제에서 광범위함을 보였다. 중요한 것은 **원인 규명**이다.

> LLM은 **perplexity가 낮은 출력에 인간 평가자보다 유의하게 높은 점수**를 주며, 이는 자기 생성 여부와 무관하다. 편향의 본질은 perplexity에 있고 **LLM은 자신에게 친숙한 텍스트를 선호한다.**

관련 연구는 **family bias**(같은 계열 모델의 출력에 높은 점수)도 보고한다.

**이 메커니즘의 대칭항이 교차 리뷰에 직접 걸린다.** 자기선호가 친숙도(낮은 perplexity)에서 온다면, **교차 모델 리뷰어에게 작성자의 출력은 정의상 덜 친숙하다** — 따라서 체계적으로 박하게 평가할 것으로 예측된다. §2.2의 90% 발화율과 §4.4의 AO 회귀가 이 예측과 방향이 같다.

> **이 연결은 이 문서의 추론이며 어느 출처도 명시하지 않았다.** 자기선호 문헌은 판정(scoring) 과제를 다루고 코드리뷰를 다루지 않으며, §4.4 논문은 편향을 원인으로 지목하지 않는다. **가설로만 취급해야 한다.** 다만 검증 가능한 형태를 갖는다 — 같은 코드에 대해 작성 모델과 리뷰 모델을 바꿔가며 발화율을 재면 된다(§6-3).

### 4.6 다중 라운드에 대한 반대 증거

아젠다 §4-2의 전제("적대적 디베이트가 단일 리뷰보다 나은가")를 정면 부정하는 보고가 있다. [More Rounds, More Noise (arXiv 2603.16244)](https://arxiv.org/pdf/2603.16244) — *"Additional rounds increase recall modestly but generate false positives at a much higher rate, destroying precision."* 단일 패스가 모든 다중 턴 변형을 상회했고 **최적 라운드 수는 1**이라고 보고한다.

**§4.3의 관측과 표면적으로 충돌한다.** 거기서는 2라운드가 오탐을 제거했다. 다만 성격이 다르다 — 관측된 사례는 라운드를 늘린 게 아니라 **누락된 컨텍스트(스펙 §3.4)를 주입하고 재판정**한 것이다. 논문이 부정하는 것은 같은 정보로 반복 심의하는 구조다.

**"한 번 더 묻는다"와 "빠진 근거를 주고 다시 묻는다"는 다른 조작이다.** 후자는 §4.3의 원인 분석(리뷰어가 스펙을 못 읽음)에 대한 직접 대응이고, 전자는 노이즈를 늘린다.

[Refute-or-Promote (arXiv 2604.19049)](https://arxiv.org/pdf/2604.19049)는 오탐 억제를 정면 목표로 삼아 adversarial kill mandate, **context asymmetry**, Cross-Model Critic을 조합한다. 검색 요약 수준으로만 확인했다(§6-6).

> 이 두 편은 **2026 프리프린트이고 본문을 읽지 않았다.** §3의 확립된 문헌과 같은 무게로 읽으면 안 된다.

---

## 5. 두 층의 대조 — 선행 조사와의 접합

선행 조사가 본 spec/plan 층과 이 조사가 본 코드 층을 나란히 놓으면 같은 구조가 두 번 나타난다.

| | spec/plan 층 (선행 §7) | 코드 층 (이 조사) |
|---|---|---|
| 표본 | 55건 | 21건 |
| 리뷰 형식 | 계약 고정 (8+8 체크리스트) | code/security는 자유, adversarial은 **계약 없음** |
| 차단 신호 | `NOT READY` 13건 | `CRITICAL`·`HIGH` 25건 |
| 비차단 신호 | `NOTE` 56건 | **`deferred` 128건** |
| 비차단 신호의 운명 | 소비 0건 | **소비 0건 (재리뷰 없음)** |
| effective FP 환산 | 미산출 | **78.5%** |
| 해소 결과 기록 | **없음** (§7.2 결정적 결손) | 필드는 있으나 계약과 불일치 (§2.4) |
| 리뷰어 오독 (C) | 1건 실증 (미병합 PR) | 1건 실증 + **원인 특정** (§4.3) |
| 라운드 관측 | 최대 3라운드 | 1라운드 (재판정 1건 예외) |

**두 층이 독립적으로 같은 결론을 준다** — 차단하지 않는 신호가 대량으로 생산되고 아무도 소비하지 않는다. 선행 조사 권고 #11("NOTE를 폐기하지 않고 토픽 간 교차 집계")은 이 조사의 `deferred` 128건에 그대로 적용되며, **§3.1의 문헌은 여기에 임계값과 초과 시 조치라는 요소를 추가한다.**

한편 **코드 층에만 있는 것**이 둘 있다. `status` 필드(불완전한 해소 기록)와 뮤테이션 RED 게이트(행동 검증 근사)다. 둘 다 계약이 강제하지 않는다.

---

## 6. 열린 질문

1. **AO 방향의 회귀가 cygnus에서도 성립하는가.** §4.4의 논문은 정적 리뷰·자족 프로그램 설정이다. 실저장소 패치 리뷰에서 "Codex 리뷰가 Claude 산출물을 오히려 악화시키는가"는 측정된 바 없다.
2. **역방향(Codex 작성 → Claude 리뷰)을 시험할 수 있는가.** 논문 기준 유리한 방향이지만 하네스 전체가 Claude 작성을 전제로 배선되어 있다. 전환 비용이 미측정이다.
3. **90% 발화율이 리뷰어의 성향인가 코드의 상태인가.** §4.5의 자기선호 가설이 검증 가능한 형태를 준다 — 같은 코드에 작성/리뷰 모델을 교차시켜 발화율을 비교. 개인 규모에서 표본이 모이는지는 별개다.
4. **추론적 검증을 통합 후로 옮길 여지가 있는가.** Fowler의 배치와 §3.3의 survivor effect는 둘 다 CI 파이프라인을 전제한다. 개인 하네스에서 "PR 이후"에 해당하는 실행 지점이 무엇인지 불분명하다.
5. ~~**리뷰어의 도구 실패를 관측할 수 있는가.**~~ **실험 B5(2026-08-03)에서 해소 — [§7](#7-실험-b5--리뷰어의-도구-실패를-관측할-수-있는가-2026-08-03-실시).** 기본 모드 stdout에는 **없고**(stderr에 사람 읽기용으로만), **`--json`을 붙이면 `status:"failed"`·`exit_code`로 구조화되어 나온다.** 검출 경로는 이미 존재하고 하네스가 쓰지 않고 있을 뿐이다. **다만 (C) 유형 오탐이 실제로 도구 실패에서 왔는지는 여전히 미확인이다** — 이 실험은 관측 수단의 존재만 보였다(§7.6).
6. **Refute-or-Promote의 context asymmetry가 무엇인가.** 본문 미독. 오탐 억제를 정면 목표로 한 유일한 설계다.
7. **뮤테이션 RED 게이트의 억제 정책.** §3.4가 보였듯 도입의 본체는 기법이 아니라 억제다. Google은 arid node 정적 분석으로 99%를 걸렀다. 개인 하네스에서 그에 해당하는 것이 무엇인지, 혹은 **리뷰어가 직접 고르는 현재 방식(4/21)이 오히려 옳은 것인지** 미확인이다.
8. **effective false positive 임계값을 얼마로 둘 것인가.** Google의 10%는 저자 각주가 밝히듯 임의로 정해진 뒤 경험적으로 유지된 값이고, 대상도 정적 분석기다. LLM 리뷰어에 맞는 값은 근거가 없다. 다만 **임계값을 두고 초과 시 조치를 정하는 구조 자체**는 근거가 있다.
9. **계약 준수를 계산적으로 검사할 것인가.** §2.4의 위반은 전부 스크립트로 잡힌다. 선행 조사 §7.8.2의 축으로는 "기계 검증 가능"인데 하지 않고 있다. 다만 **위반이 개선인 경우**가 있어, 계약을 조일지 고칠지가 먼저다.
10. **`deferred` 128건의 소비 지점.** §3.1의 문헌은 "워크플로우 밖 대시보드는 안 본다"를 실증했다. 그렇다면 소비 지점은 별도 큐가 아니라 **다음 리뷰의 입력**이어야 하는데, 21토픽 1리뷰 구조에서 그럴 단계가 없다.
11. **E2E 계층을 프로젝트 유형별로 어떻게 갖추는가.** §1.3에서 Playwright 하나뿐이고 Flutter에 적용 불가임을 봤다. 배포 조사의 core/config 경계 문제와 같은 구조다.
12. **훅에 차단을 넣을 것인가.** §3.2의 문헌은 "차단은 effective FP 0%일 때만"이라는 조건을 준다. 아젠다 §2(강제 메커니즘, 4순위)가 다룰 주제이며 PostToolUse 500ms 예산과 얽힌다.

---

## 7. 실험 B5 — 리뷰어의 도구 실패를 관측할 수 있는가 (2026-08-03 실시)

§6-5가 *"`codex exec` stdout에서 실패한 도구 호출을 기계적으로 검출하는 방법이 미확인"* 으로 남긴 항목이다. **아젠다의 B 부류(동작 확인)로 분류되었고, 격리된 임시 저장소에서 실패하는 도구 호출을 유도해 실행 확인했다.**

### 7.1 방법

스크래치패드에 빈 git 저장소를 만들고 존재하지 않는 파일을 `cat` 하게 시켰다. 설치본은 **codex-cli 0.142.4**, `~/.codex/config.toml`은 **건드리지 않았다**.

```
codex exec [--json] --sandbox read-only -C <dir> \
  'Run the shell command `cat ./missing-file.txt` exactly once, …' < /dev/null
```

> **부수 확인 하나.** `< /dev/null` 없이 실행하면 `codex exec`가 *"Reading additional input from stdin…"* 에서 **무한 대기**한다. 하네스의 `adapter-codex-review`가 모든 호출에 `< /dev/null`을 붙이는 이유가 이것이다 — 이미 겪고 대응해 둔 항목이다.

### 7.2 결과 — 답은 "stdout에는 없다"

**기본 모드(하네스가 쓰는 방식)의 stdout 전문이 이것이다.**

```
The command failed because `./missing-file.txt` does not exist.
```

**한 줄뿐이다. 도구 호출도, 실패도, 종료 코드도 없다.** 전부 **stderr**로 간다.

```
exec
/bin/zsh -lc 'cat ./missing-file.txt' in /private/tmp/…
 exited 1 in 0ms:
cat: ./missing-file.txt: No such file or directory
```

**§6-5의 질문에 대한 직접적 답: `codex exec`의 stdout에서는 검출할 수 없다.** 재료는 stderr에 있고, 그것도 사람이 읽는 형식이다(`exited 1 in 0ms:`).

### 7.3 그런데 구조화된 경로가 이미 존재한다 — `--json`

`--json`(*"Print events to stdout as JSONL"*)을 붙이면 **같은 실패가 stdout에 구조화되어 나온다.**

```json
{"type":"item.completed","item":{
  "id":"item_0","type":"command_execution",
  "command":"/bin/zsh -lc 'cat ./missing-file.txt'",
  "aggregated_output":"cat: ./missing-file.txt: No such file or directory\n",
  "exit_code":1,"status":"failed"}}
```

| 필드 | 값 |
|---|---|
| `status` | **`"failed"`** — 열거형 |
| `exit_code` | **1** |
| `command` | 실행된 명령 원문 |
| `aggregated_output` | 출력 전문 |
| `id` | 호출 식별자 (`item_0`) |

이벤트 6줄이 `thread.started` → `turn.started` → `item.started` → **`item.completed`(도구)** → `item.completed`(에이전트 메시지) → `turn.completed` 순으로 나온다. 마지막 이벤트에 토큰 사용량도 들어 있다.

**결론: 검출 경로는 이미 존재하고, 하네스가 쓰지 않고 있다.** `adapter-codex-review`의 호출 형태에 `--json`이 없다. **없는 기능을 만들어야 하는 문제가 아니라 플래그 하나의 문제다.**

> **단 산출물 경로가 바뀐다.** 하네스의 spec/plan 리뷰는 Codex가 **직접 파일을 쓰는** 방식이다(§4.1). `--json`은 이벤트 스트림을 stdout으로 바꾸므로, 도입하려면 파일 산출물과 이벤트 스트림을 함께 다루는 형태가 된다. **이 실험이 확인한 것은 신호의 존재이지 통합 방법이 아니다.**

### 7.4 부수 관측 셋

1. **stderr 헤더가 승인·샌드박스 설정을 명시한다** — `approval: never`, `sandbox: read-only`, `model`, `reasoning effort`, `session id`. [강제 메커니즘 §4.3](enforcement-mechanisms.md)이 *"`codex exec`는 비대화형이므로 승인 정책이 사실상 `never`"* 라고 추론한 것이 **헤더에 문자 그대로 찍힌다.** 하네스는 `-s workspace-write`로 돌리므로 그 조합이 매 실행 헤더에 남는다.
2. **훅 발화가 stderr에 보인다** — `hook: SessionStart` / `UserPromptSubmit` / `PreToolUse` / `PostToolUse` / `Stop`과 각 `Completed`. Codex 쪽 훅 관측 경로이며 [관찰성 조사](observability.md)가 다루지 않은 표면이다.
3. **토큰 수치가 양쪽 모드에 다 있다** — 기본 모드는 stderr에 `tokens used 1,440`, `--json`은 `turn.completed`의 `usage` 객체. **[관찰성 §2.3](observability.md)이 확인한 "OTLP 메트릭 결손"과 모순되지 않는다** — 그것은 OTLP 경로의 이야기이고, 이쪽은 프로세스 출력이다. **#33668이 대안으로 든 `rollout-*.jsonl` 파싱보다 간단한 경로가 있다는 뜻이다.**

### 7.5 이 실험이 촉발한 정정 — 두 Codex 경로를 다시 확인했다

실험 중 플러그인 캐시를 읽어 **`codex-companion`이 실제로 무엇을 spawn하는지** 확인했다.

```js
// scripts/lib/app-server.mjs:189  (1.0.2·1.0.3 동일)
this.proc = spawn("codex", ["app-server"], { … })
```

**플러그인은 `codex app-server`만 spawn한다. `codex exec`를 전혀 호출하지 않는다**(플러그인 스크립트 전체에서 `"exec"` 문자열 0건).

**§4.1의 구분이 옳았다.** `codex exec`는 하네스 자신의 `adapter-codex-review`(spec/plan 리뷰) 경로이고, 플러그인(코드 adversarial 리뷰)은 `app-server` 경로다.

> **정정 대상은 이 문서가 아니라 [관찰성 조사 §2.3](observability.md)이다.** 그 절이 *"교차 리뷰는 `codex-companion.mjs`를 통해 `codex exec`로 실행된다"* 고 적어 **두 경로를 하나로 합쳤다.** 해당 문서에서 정정했다.
>
> **그리고 이것이 관찰성 §2.3의 비대칭 논증 범위를 좁힌다.** #12913의 표는 `codex`(대화형)·`codex exec`·`codex mcp-server` 셋을 다뤘고 **`app-server`는 다루지 않았다.** 즉 메트릭 결손이 확인된 것은 **spec/plan 리뷰 경로뿐**이고, 코드 adversarial 리뷰 경로의 텔레메트리 상태는 **어느 이슈도 말하지 않는다.**

### 7.6 이 실험이 답하지 않은 것

- **`--json`을 하네스에 실제로 붙여 보지 않았다.** §7.3의 유보 참고.
- **`app-server` 경로에서 도구 실패가 어떻게 노출되는지 확인하지 않았다.** JSONL RPC이므로 유사할 가능성이 높으나 실행하지 않았다.
- **(C) 유형 오탐이 실제로 도구 실패에서 왔는지는 여전히 미확인이다.** §6-5의 가설은 그것이었고, 이 실험은 **관측 수단이 있음**을 보였을 뿐 **원인을 확인하지 않았다.**
- 프롬프트 1건·실패 유형 1종(존재하지 않는 파일)만 시험했다. 타임아웃·권한 거부·샌드박스 차단에서도 같은 형태인지 모른다.

### 7.7 규범적 질문 — grid fin은 어느 표면을 써야 하는가 (2026-08-03)

**§7.1~§7.6은 기존 하네스가 무엇을 하는지의 서술이다. 이 절은 다른 질문이다** — 기존 하네스는 참고일 뿐이므로, **공식 문서를 근거로 grid fin이 무엇을 써야 하는지**를 따로 정리한다. 두 질문을 섞은 것이 [관찰성 §2.3](observability.md) 오류의 원인이었으므로 절을 나눈다.

**1차 자료 둘.**

| 자료 | 성격 |
|---|---|
| [`codex-rs/app-server/README.md`](https://github.com/openai/codex/blob/main/codex-rs/app-server/README.md) | 공식 저장소 규격 문서 (2,469줄) |
| [Non-interactive mode](https://learn.chatgpt.com/docs/non-interactive-mode) | 공식 제품 문서 (`codex exec`) |

#### 7.7.1 공식 문서가 규정하는 용도

**`codex exec`** — 비대화형 자동화용이다. 공식 문서가 드는 상황:

> *"Run as part of a pipeline (CI, pre-merge checks, scheduled jobs)"* / *"Produce output you can pipe into other tools"* / **"Run with explicit, pre-set sandbox and approval settings"**

**`codex app-server`** — *"the interface Codex uses to power rich interfaces such as the Codex VS Code extension."* JSON-RPC 2.0(stdio JSONL 기본), Thread/Turn/Item 원시 타입.

**세 번째 문장이 결정적이다** — `exec`는 승인 설정을 **미리 고정**하는 것이 설계 의도다. §7.4-1이 실증한 `approval: never` 헤더가 그 결과다.

#### 7.7.2 결정적 차이 — 프로그램이 응답하는 승인 게이트

**`app-server`만 승인을 런타임에 위임한다.** 서버가 클라이언트에게 JSON-RPC **요청**을 보내고 클라이언트가 결정한다.

| 요청 | 응답 가능한 결정 |
|---|---|
| `item/commandExecution/requestApproval` | `accept` · `acceptForSession` · **`acceptWithExecpolicyAmendment`** · **`applyNetworkPolicyAmendment`** · `decline` · `cancel` |
| `item/fileChange/requestApproval` | `accept` · `acceptForSession` · `decline` · `cancel` |

요청에는 `command`, `cwd`, `reason`, 파일 변경의 경우 `changes`(diff 요약)가 실린다. 종료는 `item/completed`의 `status: "completed" | "failed" | "declined"` 로 확정된다.

**이것이 이 시리즈가 세 곳에서 비어 있다고 적은 부분을 정확히 채운다.**

| 조사 | 남긴 공백 | `app-server` 승인 프로토콜이 주는 것 |
|---|---|---|
| [강제 메커니즘 §1.3·§4.3](enforcement-mechanisms.md) | **차단 게이트 0건**, 그리고 `workspace-write` + 사실상 `never`는 **프리셋 어디에도 없는 조합** | 명령 단위 차단 지점. 승인 정책을 미리 고정하지 않아도 된다 |
| [보안 §1.2.1](security.md) | 저자 권고가 **Dual LLM + 엄격한 포매팅**인데 "능력 제한" 수단이 비어 있었다 | 신뢰할 수 없는 입력이 촉발한 행동을 **실행 직전에** 거를 수 있다 |
| §4.2 (이 문서) | *"리뷰어는 읽기 전용이 아니다"* — 아키텍처가 쓰기 권한을 강제 | `fileChange` 승인으로 쓰기를 건별 판정 |

**`approvalsReviewer` 옵션이 하나 더 있다** — 기본값 `"user"` 외에 `"auto_review"`가 *"route approval requests to a carefully prompted subagent, which gathers relevant context and applies a risk-based decision framework"* 다. **승인 판정 자체를 위임하는 경로가 규격에 있다.**

#### 7.7.3 결과 계약 — 둘 다 지원한다

`exec`에 `--output-schema <FILE>`이 있고, 공식 문서가 *"automated workflows that need stable fields"* 용도로 규정한다.

**그리고 `app-server`의 `turn/start`도 `outputSchema`를 받는다** — *"Optional JSON Schema to constrain the final assistant message for this turn"*, *"`outputSchema` applies only to the current turn."*

**따라서 "게이트냐 계약이냐"는 배타 선택이 아니다. `app-server`가 둘 다 준다.**

**이것이 §4.1이 측정한 결함에 직접 걸린다** — 코드 adversarial 경로는 **형식 계약이 없어** verdict 표기가 보고서마다 달랐다. `.harness/contracts/*.md`는 산문 체크리스트이고 리뷰어가 따르기를 **부탁**하는 형태다. `outputSchema`는 같은 것을 **강제**한다.

#### 7.7.4 그 밖의 비교

| 축 | `codex exec` | `codex app-server` |
|---|---|---|
| 도구 실패 검출 | `--json`의 `status:"failed"`·`exit_code` (§7.3 실증) | `item/completed`의 `status` |
| 결과 계약 | `--output-schema` | `turn/start.outputSchema` |
| **승인 게이트** | **없음** (사전 고정) | **있음** |
| 타입 스키마 | 문서화된 이벤트 종류 | **`generate-ts` / `generate-json-schema`** — *"guaranteed to match that version"* |
| 세션 | 1회 실행, `resume`로 이어붙임 | Thread/Turn, `thread/fork`, `ephemeral` |
| 토큰 사용량 | `turn.completed` (§7.4-3) | `turn/completed` |
| 흐름 제어 | 없음 | 백프레셔 (`-32001`, 지수 백오프 권고) |

**버전 고정 스키마가 특히 크다.** [배포 조사](harness-distribution.md)와 [보안 §2.2](security.md)가 핀 문제를 반복해 지적했는데, `app-server`는 **설치된 버전에서 스키마를 생성**할 수 있다. 통합 코드와 CLI 버전의 드리프트를 기계적으로 검출할 수 있다는 뜻이다.

#### 7.7.5 대가 — 값을 매기지 않고 권하지 않는다

**`app-server`는 프로세스 1회 호출이 아니라 상주 JSON-RPC 피어다.** 하네스가 구현해야 하는 것:

1. `initialize` 핸드셰이크 + `initialized` 통지 (연결마다 1회, 누락 시 모든 요청이 `"Not initialized"`)
2. Thread/Turn 생명주기 관리
3. **승인 요청에 응답하는 루프** — 이것이 없으면 턴이 진행되지 않는다
4. 백프레셔 처리 — `-32001` 수신 시 지터를 둔 지수 백오프
5. 알림 스트림 소비 (`thread/*`, `turn/*`, `item/*`)

**[보안 §1.2](security.md)가 Dual LLM의 대가로 적은 "오케스트레이션 복잡도"가 여기서 구체적 형태를 갖는다.** 단일 사용자 하네스에서 이 비용이 정당한지는 자료가 답하지 않는다.

**그리고 안정성 표시를 함께 옮긴다.** README가 명시적으로 붙인 것들 — websocket 전송은 *"experimental / unsupported … Do not rely on it for production workloads"*, realtime·fuzzy file search 이벤트는 experimental, `grantRoot`는 unstable, 일부 기능은 `experimentalApi` opt-in. **stdio 전송과 핵심 Thread/Turn/Item API는 그런 표시가 없다.**

**유출 축 하나** — `clientInfo.name`이 *"used to identify the client for the OpenAI Compliance Logs Platform"* 이고, 기업용 통합은 알려진 클라이언트 목록에 등록하라고 안내한다. [보안 §5.5](security.md)의 정보 유출 축에 새 항목이다.

#### 7.7.6 자료가 답하지 않는 것

1. **`app-server`의 텔레메트리 상태.** #12913·#33668이 `exec`·`mcp-server`·대화형만 다뤘다([관찰성 §6-10](observability.md)).
2. **승인 루프의 지연 비용.** 명령마다 왕복이 생기는데 규격이 성능을 말하지 않는다. [강제 메커니즘 §8-3](enforcement-mechanisms.md)의 "차단 훅 지연 예산"과 같은 종류의 미지수다.
3. **`auto_review` 서브에이전트의 판정 품질.** 규격이 존재를 말할 뿐 정확도·오탐률을 주지 않는다. [§3.1](#31-deferred-128건의-정확한-이름--effective-false-positive)의 effective FP 축으로 재야 할 대상인데 자료가 없다.
4. **둘을 섞을 수 있는가.** spec/plan 리뷰는 `exec`, 코드 리뷰는 `app-server`처럼 나누는 것이 합리적인지, 아니면 하나로 통일하는 것이 나은지 자료가 말하지 않는다.
5. **실행으로 확인하지 않았다.** §7.7 전체가 문서 근거이며, `app-server`를 띄워 승인 요청을 실제로 받아보지 않았다. **§7.1~§7.6은 실증이고 이 절은 아니다.**

---

## 8. 실험 D 설계 — 교차 리뷰 발화율의 원인 (2026-08-03 작성)

> **§8.1~§8.8은 설계다. §8.2.1은 그 첫 단계(D-0)를 실행한 결과이며, 요인 설계를 폐기시킨다.**
>
> **설계가 예고한 대로 첫 단계가 실험을 끝냈다.** 새 데이터를 한 건도 쓰지 않았다. **§8.4·§8.6은 실행되지 않으며 기록으로만 남긴다** — 조건이 바뀌면(발화율 포화가 풀리면) 다시 꺼낼 수 있다.
>
> **살아남은 것은 §8.5(리뷰어 도구 실패율)뿐이고, [그것도 실행했다(§8.5.1)](#851-실행-결과-2026-08-03--도구-실패가-21이고-산출물에-남지-않는다).**
>
> **가장 무거운 결과: 리뷰어가 참조 자료를 못 읽고도 판정을 내며, 그 사실이 산출물에 남지 않는다.**

### 8.1 원 질문과 그것이 무너진 이유

§6-3의 원안: *"같은 코드에 작성/리뷰 모델을 교차시켜 발화율 비교. 관측된 90% needs-attention의 원인을 가른다."*

**[평가 조사 §1.5~§1.6](evaluation.md)이 그 이분법 밖의 설명 셋을 확인했고, 셋 다 현재 구성에 실재한다.**

| 교란 | 자료 | 현재 상태 |
|---|---|---|
| 하네스 차이 | Zhang et al. — 하네스가 모델 순위를 뒤집는다(9개 중 6개), 하네스 분산 / 모델 분산 **7.80×** | 작성 **Claude Code**, 리뷰 **`codex exec`** 또는 **`app-server`**(§4.1) |
| 재시도 정책 | Zhou et al. — 1회 통과율이 최대 **17.8pp** 과대평가, 폭이 모델마다 달라 순위 역전 | 미고정 |
| 1회 실행 | Mehta — **1회 실행 비교는 29.3%가 오순위** | 리뷰는 통상 1회 |

**즉 지금 관측된 90%를 "리뷰어 성향"이라 부를 근거가 없다.**

### 8.2 D-0. 중단 판정 — 실행 전에 한다

**가장 중요한 단계다. 그리고 새 데이터를 쓰지 않는다.**

**이미 집계된 산출물이 파일럿이다** — 코드리뷰 **21건**(§2), 선행 조사의 리뷰 산출물 **55건**, 지적 **163건**과 미조치 78.5%(§3.1).

**할 일**: 그 산출물을 **이미 변동하는 요인**으로 다시 가른다 — 리뷰 경로(spec/plan vs 코드), 토픽, 시기, 작성 맥락. **요인별 발화율의 관측 폭이 곧 `δ` 추정치다.**

**그리고 [평가 §6.4.1](evaluation.md)의 `n ∝ 1/δ²`로 필요 표본을 계산해 아래 표에 대조한다.**

| 파일럿 관측 폭 | 필요 `n` | 판정 |
|---|---:|---|
| **δ ≥ 0.40** (예: 90% → 50%) | 약 **6** | **즉시 실행 가능** |
| δ ≈ 0.20 | 약 **22** | 실행 가능 (1~2개월) |
| δ ≈ 0.10 | 약 **87** | **보류** — 월 14~33건 기준 3~6개월 |
| **δ < 0.05** | **350 이상** | **폐기** — 개인 규모에서 성립하지 않는다 |

> **이 표를 사전에 못 박는 이유.** [평가 §6.3](evaluation.md)이 확인한 "eval 100일 미실행"과 [상태·연속성 §8.3](state-and-continuity.md)의 "감사가 틀린 조치를 지시" 는 **버릴 수 없게 만들어진 검사**의 결과다. **중단 기준이 숫자로 없는 설계는 같은 상태로 간다.**

### 8.2.1 D-0 실행 결과 (2026-08-03) — **요인 설계를 폐기한다**

**설계대로 새 데이터 없이 기존 산출물 80건(spec-review 28 · plan-review 30 · review-report 22)을 재분류했다.** 결과가 §8.6의 요인 설계를 실행 불가로 만든다.

#### (1) 예상치 못한 이득 — 짝지은 데이터가 이미 있었다

`review-report` 파일 안에 **두 리뷰어의 판정이 함께 기록되어 있다.**

| 구획 | 주체 |
|---|---|
| `## Code Review` · `## Security Review` | **Claude 서브에이전트**(code-reviewer, security-reviewer)의 지적 |
| `## Adversarial Review` → `Verdict:` | **Codex**의 판정 |

**같은 코드에 대한 두 리뷰어의 판정이 22건 존재한다.** §8.8-3이 *"역방향 표본이 0"* 이라 적었는데, **교차 자체는 이미 일어나고 있었다** — 다만 방향이 아니라 **역할**이 다르다(Claude=지적 열거, Codex=판정).

#### (2) 발화율이 포화되어 있다 — 지표로 못 쓴다

| Claude 측 CRITICAL/HIGH | n | **Codex 발화(FIRE)** |
|---|---:|---:|
| **0건** | 18 | **16 (88.9%)** |
| **1건 이상** | 3 | **3 (100%)** |

**코드 상태로 갈라도 Codex 발화율이 88.9% → 100%로 거의 움직이지 않는다.**

**그리고 다른 리뷰 종류는 더 심하다.**

| 종류 | n | 무결점 통과 | 발화(무결점 아님) |
|---|---:|---:|---:|
| spec-review | 28 | 5 (17.9%) | **82.1%** |
| **plan-review** | 30 | **0 (0%)** | **100%** |
| review-report (Codex verdict) | 21 파싱 | 2 | **90.5%** |

**`plan-review`는 30건 전부가 `READY`가 아니다. 완전 포화다.**

**결론: "발화했는가"는 변동이 거의 없어 원인을 가를 수 없다.** 천장 효과이며, 어떤 요인을 넣어도 차이가 나올 여지가 없다.

#### (3) `δ` 판정 — §8.2 표에 대입

| 축 | 대비 | `δ` | 필요 `n` |
|---|---|---:|---:|
| **코드 상태 → Codex 발화** (원 질문) | 88.9% → 100% | **0.111** | 약 **71** |
| 리뷰 종류 (spec vs plan 무결점율) | 17.9% → 0% | 0.179 | 약 30 |

**원 질문 축의 `δ`가 0.111 — §8.2 표의 "보류" 구간(월 14~33건 기준 3~6개월)이다.**

**그러나 그보다 앞서는 결격 사유가 있다. 표본이 18 대 3이다.** "Claude 지적 1건 이상" 칸이 **3건뿐**이라 88.9% vs 100%라는 대비 자체가 추정치가 아니다. **`δ = 0.111`은 계산은 되지만 신뢰할 수 없다.**

#### (4) 대안 지표도 변동이 없다

지적 수를 지표로 바꿔 보았다.

```
보고서 22건의 지적 수: [0×16, 2, 2, 4, 4, 5, 7]   중앙값 0, 합계 24
severity: LOW 11 · MEDIUM 7 · HIGH 5 · CRITICAL 1
```

**22건 중 16건이 지적 0건이다.** 구조화된 지적은 6개 보고서에 몰려 있고, 나머지는 판정만 있다. **[§3.1](#31-deferred-128건의-정확한-이름--effective-false-positive)이 집계한 163건은 이 22건이 아니라 더 넓은 범위(선행 조사 55건)의 값이다** — 이 부분집합에서는 지적이 24건뿐이다.

**`status` 필드는 정규식으로 한 건도 잡히지 않았다.** §3.1의 미조치율 78.5%를 이 22건에서 재현할 수 없다. **§8.3이 대리 지표로 삼으려던 것이 이 표본에는 없다.**

#### (5) D-0의 판정

**§8.6의 요인 설계(2×2 모델 교차)를 폐기한다.** 근거 셋.

1. **발화율이 포화되어 있다**(88.9~100%, plan-review는 100%). **재려는 신호가 지표에 나타나지 않는다.**
2. **원 질문 축의 표본이 3건이다.** `δ` 추정이 성립하지 않는다 — §8.8-4가 예고한 *"δ가 작다가 아니라 δ를 모른다"* 에 해당한다.
3. **대리 지표(미조치율)가 이 표본에 없다**(§4). 정답 라벨 없이 판정할 수단이 사라진다.

> **폐기가 실패가 아니다.** §8.2가 *"중단 기준이 숫자로 없는 설계는 [eval 100일 미실행]과 같은 상태로 간다"* 며 임계를 사전에 못 박은 이유가 이것이다. **새 데이터를 한 건도 쓰지 않고 실행 여부를 판정했다.**

#### (6) 살아남는 것 — 그리고 관측 하나

**§8.5의 도구 실패율 축은 유효하다.** 모델 간 비교가 아니라 리뷰어 내부 상관이므로 포화된 발화율에 의존하지 않는다. **D에서 유일하게 실행할 만한 부분이다.**

**그리고 이 재분류가 독립적인 관측 하나를 준다.** Codex는 **코드 상태와 거의 무관하게 발화한다**(Claude 지적 0건에서도 88.9%). 표본 불균형 때문에 인과로 읽을 수 없지만, **[§4.5의 자기선호 편향 가설](#45-메커니즘-후보--자기선호-편향의-대칭항)과 방향이 같고 §2.2의 "No-ship 프레이밍 17/21"과도 일관된다.** **세 관측이 같은 쪽을 가리키되 어느 것도 결정적이지 않다.**

### 8.3 D-1. 정답 라벨이 없다는 것을 먼저 인정한다

**"발화율"은 비율이지만 "그 발화가 옳았는가"는 라벨을 요구한다.**

[§2의 LLM-판정자 논문](evaluation.md)이 이 문제 자체다 — 판정자가 불완전하면 추정치가 편향되고, **편향의 방향이 참값에 따라 뒤집히므로 비교에서 상쇄되지 않는다.** 보정에는 사람 라벨 **약 200개**가 필요하다.

**개인 규모에서 200개는 무리다. 대신 이미 측정된 대리 지표를 쓴다** — **미조치율 78.5%**(§3.1), Google의 effective FP 10% 비활성화 임계와 대조 가능하다.

> **대리 지표의 한계를 명시한다. 미조치 ≠ 오탐이다.** 정당하게 보류한 지적, 다른 방식으로 해결된 지적, 아직 처리 전인 지적이 모두 미조치에 들어간다. **따라서 이 지표는 오탐률을 *측정*하지 않고 *상한을 두른다*.** 이 구분 없이 쓰면 설계가 갖지 못한 정밀도를 주장하게 된다.

### 8.4 D-2. 교란을 없애지 말고 고정한다

**"양쪽을 같은 표면에서 돌린다"는 비싸다.** §7.7이 확인한 대로 `codex exec`와 `app-server`는 종류가 다르다 — 전자는 승인이 사전 고정된 1회 실행, 후자는 승인 루프를 구현해야 하는 상주 피어다. **통일하려면 승인 게이트를 포기하거나 JSON-RPC 클라이언트를 만들어야 한다.**

**파일럿에서는 더 싼 방법을 쓴다 — 리뷰 경로를 하나로 고정하고 모델만 바꾼다.**

| 축 | 파일럿에서 | 이유 |
|---|---|---|
| 리뷰 표면 | **`codex exec --json` 하나로 고정** | 통일이 아니라 고정이면 교란이 사라진다 |
| 리뷰 종류 | **하나만** (spec/plan **또는** 코드) | §4.1 — 코드 adversarial 경로는 **형식 계약이 없어** 발화율이 비교 불가다 |
| 재시도 | 명시 후 **1회 통과율과 k회 합의율을 함께 보고** | Zhou et al. |
| 반복 | **k=3 합의** | Mehta — 커버리지 54~62%로 낮추는 대신 정확도 +6~14pp |
| 모델 | **유일한 변동 요인** | 이것이 재려는 것 |

### 8.5 D-3. 세 번째 측정량 — 리뷰어의 도구 실패율

**§6-5는 리뷰어 오탐이 *리뷰어 자신의 도구 호출 실패*에서 온다고 가설을 세웠고, [실험 B5](#7-실험-b5--리뷰어의-도구-실패를-관측할-수-있는가-2026-08-03-실시)가 그것을 관측 가능하게 만들었다** — `codex exec --json`의 `status:"failed"`·`exit_code`.

**따라서 리뷰 1건마다 셋을 함께 기록한다.**

| 측정량 | 출처 |
|---|---|
| 발화율 (needs-attention 비율) | 리뷰 산출물 |
| 미조치율 (오탐 상한 대리) | 후속 커밋 대조 |
| **리뷰어 도구 실패율** | **`--json` 이벤트 스트림** |

**이 축이 이 설계에서 가장 값싸고 값지다.**

- **모델 간 비교가 아니라 리뷰어 내부의 상관이다.** 따라서 Mehta의 29.3% 오순위가 걸리지 않는다.
- **발화가 코드 상태가 아니라 도구 실패를 따라간다면, 원 질문이 다른 경로로 답해진다** — "리뷰어 성향도 코드 상태도 아니고 관측 실패다."
- **필요 표본이 훨씬 적다.** 상관을 보는 것이라 두 조건의 차이를 검출할 필요가 없다.

> **D-0에서 δ가 작게 나와 8.6의 요인 설계를 폐기하더라도 이 축은 살아남는다.** 실제로 **먼저 할 것은 이쪽이다.**

### 8.5.1 실행 결과 (2026-08-03) — 도구 실패가 21%이고, 산출물에 남지 않는다

**D-0가 요인 설계를 폐기한 뒤 살아남은 유일한 축을 실행했다.**

#### 방법

cygnus를 건드리지 않도록 **격리 사본**을 만들었다 — `AGENTS.md`, `.codex/skills/`, `.harness/{scripts,contracts}`, 그리고 대상 spec 1건(`mission-report-approve`, 22,327바이트). **같은 입력으로 3회** 반복했다.

```
codex exec --json -s workspace-write -C <ws> "spec-review 스킬로 <spec>을 리뷰해줘"
```

#### 결과 1 — 도구 호출의 약 21%가 실패한다

| 실행 | 성공 | **실패** | 실패율 | 입력 토큰 |
|---|---:|---:|---:|---:|
| run1 | 17 | **5** | 22.7% | 263,174 |
| run2 | 19 | **6** | 24.0% | 368,355 |
| run3 | 17 | **3** | 15.0% | 264,682 |

**3회 모두에서 실패한 것 셋** — `docs/_local/dev-context.json` 읽기, `dev-context.js read --topic=…`, `dev-context.js set-field --topic=…`.
**run2는 추가로** `.claude/rules/common/development-workflow.md`·`.harness/rules/coding-style.md`·`.harness/rules/security.md` 읽기에 실패했다.

> **실패의 상당수는 격리 환경의 인공물이다** — 사본에 `dev-context.json`과 일부 규칙 파일을 넣지 않았다. **실제 cygnus에서의 실패율은 이보다 낮을 것이다.** 그러나 **아래 두 결과는 그 사실과 무관하게 성립한다.**

#### 결과 2 — 실패해도 완주하고, 산출물에 흔적이 없다

**리뷰어는 규칙 파일을 읽으려 시도했다가 실패한 뒤에도 판정을 냈다.** 그리고 생성된 `spec-review-*.md` 3건을 검사한 결과:

> **실패·누락·접근 불가를 언급한 파일: 0건. `## Notes` 절도 비어 있다.**

**§6-5가 세운 (C) 유형 오탐 가설의 실물이다** — 리뷰어가 참조 자료를 못 읽고도 판정을 내고, **그 사실이 산출물 어디에도 남지 않는다.** 사람이 보고서만 읽으면 리뷰어가 무엇을 못 봤는지 알 방법이 없다.

**[실험 B5](#7-실험-b5--리뷰어의-도구-실패를-관측할-수-있는가-2026-08-03-실시)가 확보한 `--json` 경로가 이 공백을 정확히 메운다.** 실패는 `status:"failed"`로 이벤트 스트림에 있고, 보고서에만 없다.

#### 결과 3 — 같은 입력의 판정은 안정적이었다

| | 판정 |
|---|---|
| run1 · run2 · run3 | **READY · READY · READY** |

**3/3 일치.** [평가 §1.6.3](evaluation.md)의 *"10회당 고유 경로 2.3~4.2개"* 에 비하면 이 과제는 안정적이다 — 다만 **3회는 불안정을 검출하기에 너무 적다.**

**그런데 원본과는 다르다.** 같은 spec 최종본에 대해:

| | 판정 |
|---|---|
| 원본 (2026-07-30, cygnus 환경) | **READY WITH NOTE** |
| 재실행 (2026-08-03, 격리 환경) | **READY** ×3 |

**한 단계 차이다.** 격리 환경에서 규칙 파일 접근이 실패한 것과 관련 있을 수 있으나 — **표본이 1 대 3이고 시점·환경·모델 버전이 모두 다르다. 인과로 읽을 수 없다.**

**다만 방향은 기록해 둘 만하다: 참조 자료를 덜 읽은 쪽이 덜 엄격했다.**

#### 결과 4 — 같은 입력에서 토큰이 40% 흔들린다

run2가 368k, run1·run3이 264k다. **동일 입력·동일 프롬프트인데 입력 토큰이 40% 차이 난다.** 실패한 도구 호출이 많았던 실행이 곧 비싼 실행이다(run2가 실패 6건으로 최다).

**[평가 §1.5.2](evaluation.md)가 인용한 *"컨텍스트 파일이 단계 수를 늘려 비용이 오른다"* 와 같은 형태다** — 여기서는 실패한 탐색이 단계를 늘린다.

#### 이 실행이 답하지 않은 것

1. **실제 cygnus 환경의 실패율.** 격리 사본이 파일 일부를 빠뜨려 실패율이 부풀려졌다. **실환경 측정이 후속으로 남는다.**
2. **실패율과 발화율의 상관.** 판정이 3/3 READY로 변동이 없어 **상관을 계산할 수 없다.** 원 가설(발화가 도구 실패를 따라가는가)은 **발화가 변동하는 표본에서만 검증 가능하다.**
3. **`review-report`(코드 adversarial) 경로는 시험하지 않았다.** §4.1의 발화율 90%는 그쪽이고, 이 실행은 `spec-review`다.
4. **3회는 [평가 §6.4.1](evaluation.md) 기준으로 큰 효과만 본다.** 판정 일치 3/3은 "불안정하지 않다"를 뜻하지 않는다.

### 8.6 D-4. 요인 설계 — δ가 충분할 때만

D-0이 `δ ≥ 0.20`을 지지할 때만 착수한다.

**2×2**: {작성 모델} × {리뷰 모델}. 같은 산출물에 두 리뷰어, 두 작성자의 산출물에 같은 리뷰어.

**보고 항목** — §7.7.4가 인용한 Zhang et al.의 분산 분해 프로토콜을 따른다.

- 요인별 발화율과 **신뢰구간** (점추정치만 보고하지 않는다 — [평가 §1.1](evaluation.md) 권고 1·2)
- **짝지은 차이**로 검정 (권고 4) — 같은 산출물에 대한 리뷰어 간 차이를 문항 단위로 짝짓는다
- 순위 역전 발생 여부
- k=1 결과와 k=3 합의 결과를 **모두**

> **클러스터 주의**([평가 §1.4](evaluation.md)) — 한 리뷰 산출물 안의 여러 지적은 독립 표본이 아니다. 산출물을 클러스터로 잡아야 하며, 나이브하게 지적 수를 세면 표준오차가 최대 3배 과소평가된다.

### 8.7 사전 등록할 것

**실행 전에 문서로 고정한다.** 사후에 기준을 고르면 이 설계의 목적이 사라진다.

1. D-0의 판정 임계 (§8.2 표)
2. "발화"의 조작적 정의 — verdict 표기가 보고서마다 다르므로(§2.2) **판정 규칙을 먼저 쓴다**
3. "미조치"의 판정 창 — 며칠 안에 손대지 않으면 미조치인가
4. 리뷰 종류와 표면 (§8.4)
5. k와 합의 규칙
6. **중단 조건** — δ가 임계 미만이면 폐기하고 그 사실을 기록한다

### 8.8 이 설계가 답하지 않는 것

1. **`app-server` 경로는 범위 밖이다.** 파일럿이 `codex exec`로 고정하므로, 코드 adversarial 리뷰(형식 계약 없음)의 발화율은 이 설계로 못 잰다. §4.1의 비대칭이 그대로 남는다.
2. **미조치율이 오탐률의 상한일 뿐이다**(§8.3). 진짜 오탐률을 알려면 사람 라벨 200개가 필요하고, 그 비용을 감당할지는 이 설계가 답하지 않는다.
3. **역방향 표본이 여전히 0이다.** §부록이 적은 대로 관측 21건이 전부 AO(Claude 작성 → Codex 리뷰)다. 2×2를 채우려면 **없는 방향을 새로 만들어야 하고, 그것 자체가 비용이다.**
4. **D-0의 재분류가 δ를 준다는 보장이 없다.** 기존 산출물에서 요인이 충분히 변동하지 않으면 폭을 못 읽는다. **그때는 "δ를 모른다"이지 "δ가 작다"가 아니며, 판정을 미뤄야 한다.**
5. **이 설계를 실행하지 않았다.** D-0조차 돌리지 않았다.

---

## 부록. 조사 방법 및 한계

**방법**
- cygnus `docs/_local/**/review-report-*.md` **21건 전수 집계** — 리뷰어 실행 상태, verdict, severity × status 교차표, 리뷰어별 이슈 수, 보고서별 status 균일성, 뮤테이션·재판정·도구실패 언급 빈도
- 하네스 직접 읽기 — `hooks/hooks.json` 전체, 훅 스크립트 8개의 차단 경로 전수 검사, `flow-verify`·`wf-verification`·`adapter-codex-review`·`flow-review`·`stack-e2e-testing` SKILL.md, `.harness/contracts/review-report.md` 전문
- cygnus 테스트 자산 확인 — Playwright 설정·E2E 디렉터리 부재, Dart 34 / TS 49 테스트 파일
- WebFetch 3회 **본문** — arXiv 2607.21656, Fowler, arXiv 2102.11378(ar5iv HTML)
- 브라우저 직접 읽기 1회 — CACM 2018 (WebFetch 403 → Chrome으로 전문 확보)
- WebSearch 4회 — 정적 분석 오탐, Google 정적 분석, 뮤테이션 테스팅, LLM 판정자 자기선호

**직접 확인 (1차 관측)**
- 훅 9개의 matcher와 **차단 경로 0건** — 스크립트 8개의 `process.exit()` 호출 18개가 전부 `exit(0)`, 비-0 종료·미포착 throw·catch 재throw 0건, stdout JSON 제어 출력 0건
- 비차단이 의도임을 밝힌 주석 3건 (`console-log-audit.js:59`, `type-check.js:53`, `git-push-review.js:27`)
- `git-push-review.js`의 `/dev:review` 참조 (존재하지 않는 커맨드)
- `flow-verify` 19줄 → `wf-verification` 5게이트 (전부 `pnpm` 하드코딩)
- `stack-e2e-testing`의 `origin: ECC`, Playwright 전용, MCP 언급 0건
- 리뷰어 21/21 run, verdict 19 needs-attention / 2 approve, No-ship 프레이밍 17/21
- 이슈 163건의 severity × status 교차표, 계약 알고리즘 위반 5개 보고서
- 계약 밖 값 4종 (`withdrawn`, ``fixed (`sha`)``, `HIGH (latent)`, 공동 리뷰어)
- `adapter-codex-review`의 `-s workspace-write`·120초 타임아웃·Non-Goals
- `.codex/skills/` 3종에 코드리뷰 스킬 부재

**문헌에서 직접 인용한 것 (본문 확인)**
- CACM 2018 — effective false positive 정의, 코드리뷰 10% 상한, 10% 초과 시 분석기 비활성화, 컴파일 에러 승격 기준(effective FP 0%), "경고는 무시된다", FindBugs Fixit 2009 수치(9,473 / 3,954 / 640 / 1,746), 대시보드 실패, 74% vs 21% survivor effect, Tricorder 운영치(일 5만 리뷰 / Please-Fix 5,000 / Not-useful 250)
- 뮤테이션 — productive/arid 정의, 820→7, 1,690만→210만, 85% 초기 unproductive, 15%→89%, 파일수×7 상한, 코드리뷰 노출 근거, 뮤턴트당 수 분
- Fowler — guide/sensor 정의, 3범주와 행동 미해결, 계산적/추론적 배치, "센서가 안 울리면?" 미해결 질문
- arXiv 2607.21656 — 6개 조건 통과율, AO 순 −10, 정적 리뷰 설정 명시

**2026-08-02 재구성**: 외부 자료를 「구현 참조 자료」 절로 앞당겨 모았고 §1~§5를 보조 근거로 재프레이밍했다. **절 번호는 유지했다** — 조사 문서 8건이 서로를 §번호로 참조하므로 재번호는 그 링크 그래프를 조용히 깨뜨린다.

**한계**

- **표본이 단일 프로젝트·단일 사용자·단일 방향이다.** 21건 전부 AO(Claude 작성 → Codex 리뷰)다. 역방향 표본이 0이므로 §4-1(역할 비대칭)에 대해 이 데이터가 답할 수 있는 것은 없다.
- **`deferred` 128건의 정오를 판정하지 않았다.** 78.5%가 연기됐다는 것은 사실이나 그것이 과발화 때문인지 규율 부족인지 가르지 못한다. **effective false positive라는 지표는 의도적으로 그 구분을 하지 않는다** — 조치 여부만 본다. 지표 선택 자체가 이 한계를 흡수하지만, 개선 방향을 정할 때는 구분이 필요하다.
- **Google 문헌의 규모 차이가 크다.** 일 5만 리뷰 vs 3개월 21건. 전이시킨 것은 지표 정의와 임계값의 존재이며, 운영 수치는 대조용으로만 실었다. 10%라는 값이 LLM 리뷰어에 맞는다는 근거는 없다(논문 각주가 그 값의 임의성을 인정한다).
- **§4.5의 자기선호 → 교차 리뷰 과발화 연결은 이 문서의 추론이다.** 어느 출처도 그렇게 주장하지 않는다.
- **verdict 집계는 자유 서술에서 정규식으로 추출했다.** adversarial 섹션에 고정 형식이 없으므로 표기 변형을 놓쳤을 수 있다.
- **뮤테이션 언급 4/21은 키워드 검색 결과다.** 다른 표현으로 같은 기법을 쓴 사례를 놓쳤을 수 있다.
- **arXiv 2603.16244·2604.19049는 검색 요약에만 근거한다.** 본문 미독. 인용한 결론("최적 라운드 수 1")은 검증되지 않았다.
- **arXiv 2607.21656은 본문을 확인했으나 재현하지 않았고 피어리뷰 전이다.** 설정이 cygnus와 다르다는 점(§4.4)이 이 문서에서 가장 오독되기 쉬운 지점이다.
- **`codex-companion.mjs` 자체를 읽지 않았다.** 외부 플러그인 캐시에 있고, 리뷰어 프롬프트 구성 — 특히 "No-ship" 프레이밍이 프롬프트에서 유도된 것인지 — 확인하지 못했다. §2.2와 §4.5 해석에 직접 걸리는 공백이다.
- **선행 조사 §7의 55건과 이 조사의 21건을 대조하지 않았다.** 같은 토픽에서 두 층의 지적 강도가 상관되는지 미측정이다.
