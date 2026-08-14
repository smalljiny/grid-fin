# 보안 — 구현 참조 자료

**최초 작성**: 2026-08-02
**최종 수정**: 2026-08-02
**대상 프로젝트**: grid fin (신규 개인용 개발 하네스)
**성격**: **자료 수집·정리.** grid fin 구현 시 참조할 외부 자료를 모으고 정돈한다. 통제 도입은 선택하지 않는다.
**조사 도구**: WebFetch 4회(본문), 브라우저 1회, WebSearch 2회, 하네스 실측(적용 대상 확인용)

선행 문서
- [research-agenda.md](research-agenda.md) §8 — 이 조사의 출처
- [harness-distribution.md](harness-distribution.md) §2.2 — 핀 필드 분리(재현용 `sha` vs 드리프트용 `contentHash`)
- [enforcement-mechanisms.md](enforcement-mechanisms.md) §1.3 — 사용 가능한 강제 원시 수단
- [error-recurrence-prevention.md](error-recurrence-prevention.md) §6.2 — komi-learn의 untrusted 취급

---

## 0. 이 문서의 쓰임

**grid fin을 구현할 때 "외부 컴포넌트와 신뢰할 수 없는 입력을 어떻게 다룰 것인가"에 답할 근거를 모았다.** 네 자료가 서로 다른 층을 덮는다.

| 자료 | 층 | 무엇을 주는가 | 등급 |
|---|---|---|---|
| [Beurer-Kellner et al., *Design Patterns for Securing LLM Agents against Prompt Injection*](https://arxiv.org/abs/2506.08837) | **설계** | 이름 붙은 패턴 6종 + 각각이 포기하는 효용, **그리고 코딩 에이전트 사례에 저자들이 고른 패턴**(§1.2.1) | 프리프린트 (ETH·Google·Microsoft·IBM·EPFL 공동) |
| [OWASP Top 10 for Agentic Applications 2026](https://genai.owasp.org/resource/owasp-top-10-for-agentic-applications-for-2026/) | **위협 분류** | ASI01–ASI10, ASI04의 공급망 완화책 목록 | 1차 문서 (100명 이상 peer review) |
| [SLSA v1.0 Build Levels](https://slsa.dev/spec/v1.0/levels) | **공급망 채택 단계** | L0–L3 레벨과 각 레벨이 막는 것 | 표준 (OpenSSF) |
| [POISE (arXiv 2606.07943)](https://arxiv.org/abs/2606.07943) | **공격 실증** | 실효 공격 위치, 스캐닝 무력화 수치 | 프리프린트 (초록만) |

**§1~§4가 자료다. §5는 이 자료가 grid fin에 해당하는지 확인하는 실측이며 보조 목적이다.**

> **범위**: 방어적 참조 자료 정리다. 공격 기법은 분류와 공개 연구 인용까지만 다루고 재현 절차는 쓰지 않는다.

---

## 1. 설계 패턴 — 가장 직접 쓸 수 있는 자료

[Beurer-Kellner, Buesser, Crețu, Debenedetti, Dobos, Fabian, Fischer, Froelicher, Grosse, Naeff, Ozoani, Paverd, Volhejn, Tramèr](https://arxiv.org/abs/2506.08837) (ETH Zurich, Invariant Labs, IBM, EPFL, Swisscom, Google, Microsoft, Kyutai 외). **사례 연구 10건 중 10번이 "Software Engineering Agent"** — grid fin의 영역이다.

### 1.1 핵심 원칙

> *"Once an LLM agent ingests untrusted input, it must be constrained so that it is impossible for that input to trigger any consequential actions—that is, actions with negative side effects on the system or its environment."*

**"신뢰할 수 없는 입력을 읽었다면, 그 입력이 결과를 낳는 행동을 촉발할 수 없어야 한다."** 이 원칙이 아래 패턴 전부의 뿌리다.

원칙의 형태에 주목할 만하다 — **탐지가 아니라 능력 제한**이다. "나쁜 입력을 알아본다"가 아니라 "나쁜 입력이 무엇을 하든 결과가 없게 만든다"이다.

### 1.2 패턴 6종

각 패턴은 **무엇을 제약하고 그 대가로 어떤 효용을 포기하는지**가 명시되어 있다. 이 대가 항목이 실제 선택 시 판단 근거가 된다.

| # | 패턴 | 제약하는 것 | **포기하는 효용** |
|---|---|---|---|
| 1 | **Action-Selector** | 에이전트를 미리 정의된 도구 호출 중 하나를 고르는 스위치로 만든다. 행동 결과가 판단으로 되돌아오지 못한다 | LLM의 퍼지 매칭·일반화. 허용 행동을 하드코딩해야 한다 |
| 2 | **Plan-Then-Execute** | 실행 전에 계획을 확정한다. 도구 출력은 **인자**만 바꿀 수 있고 **어떤 행동을 할지**는 못 바꾼다 | 중간 결과에 따라 행동을 바꿔야 하는 작업이 어렵거나 불가능해진다 |
| 3 | **LLM Map-Reduce** | 신뢰할 수 없는 데이터 조각마다 격리된 LLM 인스턴스를 붙인다. 악성 입력의 영향이 자기 처리 단위에 갇힌다 | 분해 가능한 작업이어야 한다. 데이터 간 교차 추론이 제약된다 |
| 4 | **Dual LLM** | 도구 권한을 가진 특권 LLM은 신뢰할 수 없는 데이터를 **아예 만지지 않는다**. 격리된 LLM이 그것을 처리하되 도구가 없고, 결과는 심볼릭 참조로만 전달된다 | 오케스트레이션 복잡도. 격리 LLM 출력이 안전 제약을 만족해야 해서 표현력이 준다 |
| 5 | **Code-Then-Execute** | 도구 호출과 비특권 LLM 호출을 **형식 코드로 먼저 쓴 뒤** 실행한다. 코드가 신뢰할 수 없는 데이터를 상대한다 | LLM이 형식적으로 추론해야 한다. 프로그램으로 표현하기 어려운 작업이 있다 |
| 6 | **Context-Minimization** | 신뢰할 수 없는 사용자 프롬프트가 초기 행동을 정한 뒤 **컨텍스트에서 제거**한다 | 원 프롬프트에 담긴 사용자 선호를 반영한 응답을 못 한다 |

### 1.2.1 사례 연구 10번 — 출처 감사에서 확보 (2026-08-02 추가)

**초판이 "이 문서에서 가장 값진 자료인데 가장 얕게 읽었다"고 적은 부분이다. 본문에서 확인했다.**

**대상**: *"a coding assistant with tool access to read online documentation, install software packages, write and push commits, etc."* — grid fin의 영역과 겹친다.

**저자들이 든 위협 셋** (원문):

| 위협 | 이 시리즈의 대응 관측 |
|---|---|
| *"Writing insecure code"* | — |
| *"Importing malicious packages (which can lead to remote code execution in some cases)"* | §2.1의 ASI05, §5.2의 플러그인 실행 경로 |
| ***"Exfiltrating sensitive data through commits or other web requests"*** | **§5.5의 이슈 본문 유출과 같은 축** |

**저자들의 권고는 패턴 4(Dual LLM)이며, 조건이 붙는다 — "엄격한 데이터 포매팅을 동반한(with strict data formatting)".** 신뢰할 수 없는 문서를

> *"a quarantined LLM that is instructed to convert the data into an API description with **strict formatting requirements** to minimize the risk of prompt injections (e.g., **method names limited to 30 characters**)"*

로 처리한다.

**두 가지가 §1.2의 표를 구체화한다.**

1. **패턴 6종 중 코딩 에이전트에 저자들이 고른 것은 Dual LLM이다**(§6-1의 질문에 대한 답). 표에서 이 패턴의 대가로 적힌 것이 *"오케스트레이션 복잡도"* 였고, 개인 규모에서 그것이 감당 가능한지는 여전히 미해결이다(§6-2).
2. **격리 LLM의 출력에 형식 제약을 거는 것이 핵심이다.** "30자 이내 메서드명" 같은 **기계적 상한**이 예로 제시된다 — 탐지가 아니라 표현력 제한이며, §1.1의 원칙(능력 제한)이 구현 층위에서 어떤 모습인지 보여 준다.

**다만 사례 연구가 다루는 신뢰할 수 없는 입력은 온라인 문서와 제3자 패키지다.** 저장소 콘텐츠·이슈 트래커를 읽는 에이전트는 이 사례가 명시적으로 다루지 않는다. **[오류 재발 조사 §7.10.8](error-recurrence-prevention.md)이 남긴 위험과 §5.5의 관측이 그 범위 밖이라는 뜻이다.**

### 1.3 탐지 기반 방어가 불충분한 이유

논문은 탐지·필터링을 **휴리스틱**으로 분류하고 보장을 주지 않는다고 못 박는다.

> 입출력 탐지는 *"raise the bar for attackers"* 하지만 *"cannot guarantee prevention of all attacks"*
> 적대적 학습을 통한 LLM 수준 방어는 근본적으로 취약하다
> 탐지에 의존하는 범용 에이전트는 *"likely to remain heuristic in nature—and thus inherently brittle"*

핵심 논지: 방어가 현재 LLM의 능력에 의존하는 한 *"it is unlikely that general-purpose agents can provide meaningful and reliable safety guarantees."*

**§3의 실측(스캐너 오탐률 74.6%)이 이 주장에 수치를 준다.**

---

## 2. 위협 분류와 공급망 요구 — OWASP

[OWASP Top 10 for Agentic Applications 2026](https://genai.owasp.org/resource/owasp-top-10-for-agentic-applications-for-2026/) (2025-12-09). 배포본 본문을 확인했다.

### 2.1 ASI01–ASI10

| ID | 이름 |
|---|---|
| ASI01 | Agent Goal Hijack |
| ASI02 | Tool Misuse and Exploitation |
| ASI03 | Identity and Privilege Abuse |
| **ASI04** | **Agentic Supply Chain Vulnerabilities** |
| ASI05 | Unexpected Code Execution (RCE) |
| ASI06 | Memory & Context Poisoning |
| ASI07 | Insecure Inter-Agent Communication |
| ASI08 | Cascading Failures |
| ASI09 | Human-Agent Trust Exploitation |
| ASI10 | Rogue Agents |

**ASI01이 §1.1의 원칙과 같은 전제에서 출발한다.** 에이전트는 *"untyped natural-language inputs and loosely governed orchestration logic"* 에 의존하므로 *"cannot reliably distinguish legitimate instructions from attacker-controlled content."*

그리고 LLM 단독 대비 차이를 명시한다 — *"Unlike LLM01:2025, which focuses on altering a single model response, ASI01 captures the broader agentic impact where manipulated inputs redirect goals, planning and multi-step behavior."*

**ASI02가 도구 메타데이터를 신뢰 대상에서 뺀다** — *"Tool Poisoning"*: 공격자가 *"MCP tool descriptors, schemas, metadata, or routing information"* 을 조작해 *"causing the agent to invoke a tool based on falsified or malicious capabilities."* ASI04도 같은 것을 다른 이름으로 든다 — *"Tool-descriptor injection: An attacker embeds hidden instructions or malicious payloads into a tool's metadata or MCP/agent-card, which the host agent interprets as trusted guidance."*

**메타데이터가 "신뢰된 지침으로 해석된다"는 것이 요지다.** 스킬 description·MCP 도구 설명·에이전트 카드가 전부 같은 범주다.

### 2.2 ASI04의 완화책 목록 — 구현 체크리스트로 쓸 수 있는 형태

ASI04는 정적 의존성과의 차이를 이렇게 규정한다. 에이전트 생태계는 *"compose capabilities at runtime—loading external tools"* 하므로 **"live supply chain"** 이 되고, *"distributed run-time coordination"* 과 자율 행동이 결합해 위험이 에이전트 간에 전파된다.

권고 완화책 전부다.

| 완화책 | 성격 |
|---|---|
| **Provenance and SBOMs/AIBOMs with signed attestations and curated registries** | 출처 증명 |
| **Dependency gatekeeping: allowlist, pin, scan for typosquats, verify before activation** | 도입 게이트 |
| **Containment in sandboxed containers with strict network/syscall limits** | 격리 |
| **Secure prompts and memory under version control with peer review** | 변경 추적 |
| **Inter-agent security: mutual authentication via PKI and mTLS; no open registration** | 에이전트 간 |
| **Continuous validation: re-check signatures and hashes at runtime; monitor behavior and lineage** | 지속 검증 |
| **Pinning by content hash *and* commit ID, with staged rollout and auto-rollback** | 핀 |
| **Supply chain kill switch for emergency revocation** | 회수 |

**"content hash **와** commit ID"** 가 특히 쓸모 있다. 아젠다 §8-4가 든 `postmark-mcp` 패턴 — 정상 버전 15개 뒤 유출 코드 한 줄 — 은 **content hash만으로는 못 막는다.** 설치 시점 해시는 그 시점 내용을 고정할 뿐이고, 업스트림이 새 버전을 내면 새 해시가 정당해 보인다. commit ID 핀이 있어야 "내가 승인한 리비전"과 "지금 받는 리비전"이 구분된다.

**[배포 조사 §2.2](harness-distribution.md)가 재현성 축에서 독립적으로 같은 분리에 도달해 있었다** — *"`sha`(해석된 리비전) = 재현 가능한 핀, `contentHash` = 드리프트 검출"*. **서로 다른 두 요구가 같은 두 필드를 부른다.**

---

## 3. 공격 실증 — 실효 위치와 스캐닝의 한계

[POISE: Position-Aware Undetectable Skill Injection (arXiv 2606.07943)](https://arxiv.org/abs/2606.07943). **초록만 확인했다.**

### 3.1 메타데이터가 아니라 본문이 실효 위치다

> *"YAML-header injections are reliably loaded but easily inspected, whereas stealthier body injections…are less reliable because out-of-context commands invite the agent's own suspicion."*

POISE는 트리거를 **본문의 적절한 위치에 문맥에 녹여** 배치해 양쪽 단점을 피한다. **codex+gpt-5.2에서 ASR 89.3%** — 무작위 배치 대비 +28.0포인트, YAML 전용 대비 +2.6포인트.

**이것이 스킬 자산의 어느 부분을 더 경계해야 하는지 뒤집는다.** description은 항상 로드되지만 작고 검사 가능하다. 본문은 온디맨드지만 크고 검사되지 않는다.

### 3.2 스캐닝 오탐률이 운용 임계값의 7배다

> 현행 LLM 스캐너는 **정상 스킬의 74.6%를 오탐**한다 — *"legitimate skill bodies naturally require privileged tool operations."* POISE는 이 잡음에 섞여 **오염된 변형의 5.6%만이 새 high-risk 경보를 얻는다.**

**[검증·교차리뷰 조사 §3.1](verification-and-cross-review.md)이 확보한 Google의 운용 규칙이 이 수치를 판정한다** — 코드리뷰 층 분석기는 effective false positive **10%** 를 넘으면 **비활성화**한다.

| | effective FP |
|---|---:|
| Google이 분석기를 끄는 임계 | 10% |
| LLM 스킬 스캐너 | **74.6%** |

**7배 이상이다.** 그리고 성능 문제가 아니라 범주 문제로 보인다 — 정상 스킬이 원래 특권 도구 조작을 요구하므로 "특권 조작이 있다"가 신호가 되지 못한다.

**§1.3(탐지 기반 방어는 휴리스틱)과 결론이 같고 근거가 다르다** — 저쪽은 원리, 이쪽은 수치다.

---

## 4. 공급망 채택 단계 — SLSA

ASI04의 완화책 목록은 규범적이라 "어디부터"를 말하지 않는다. [SLSA v1.0 Build Levels](https://slsa.dev/spec/v1.0/levels)(OpenSSF)가 그 축을 준다.

| 레벨 | 요구 | 막는 위협 |
|---|---|---|
| **L0** | 없음 | 없음 |
| **L1 — Provenance Exists** | 일관된 빌드 과정, **플랫폼·과정·입력을 기술한 provenance**, 소비자에게 배포 | *"Prevents mistakes during the release process, such as building from a commit not present in upstream repo"* |
| **L2 — Hosted Build Platform** | L1 + 전용 인프라(워크스테이션 아님), **서명된 provenance**, 하류 검증 | *"Prevents tampering after the build through digital signatures"* |
| **L3 — Hardened Builds** | L2 + 실행 간 상호 영향 차단, 빌드 단계에서 비밀 접근 불가 | *"Prevents tampering during the build—by insider threats, compromised credentials, or other tenants"* |

**채택 시작점을 문서가 명시한다** — *"Projects and organizations wanting to easily and quickly gain some benefits of SLSA—other than tamper protection—without changing their build workflows"* 는 **L1**을 목표로 하라. L2는 L3 인프라를 기다리는 동안의 중간 단계로 위치시킨다.

**개인 하네스 관점에서 유용한 이유가 둘이다.**

1. **L1이 "워크플로우를 바꾸지 않고 얻는 것"으로 정의되어 있다.** 아젠다 §8-5("개인 하네스에서 현실적으로 가능한 수준")에 대한 답의 형태를 준다 — 서명도 전용 인프라도 없이 시작할 수 있는 지점이 표준 안에 있다.
2. **L1이 막는 것이 명시적이다** — "업스트림에 없는 커밋에서 빌드하는" 부류의 실수. §2.2의 commit ID 핀과 같은 대상이다.

**한계도 명시해 둔다.** L1의 provenance는 서명이 없어 *"trivial to bypass or forge"* 이고, L2까지 가야 위조 저항이 생긴다. 그리고 v1.0은 **Build track만** 다루며 소스 무결성은 범위 밖이다(*"For version 1.0 the Source aspects were removed"*). **이 문서가 확인한 것은 v1.0이며 현재 최신은 v1.2다.**

---

## 5. 적용 대상 확인 — grid fin이 물려받을 노출면 (보조)

**이 절은 위 자료가 이 프로젝트에 해당하는지 확인하는 용도다.** grid fin은 아직 코드가 없으므로, 참조 원본인 기존 하네스를 실측해 규모를 가늠했다.

### 5.1 외부 저작 비중

하네스 스킬 55종의 `origin:` frontmatter 전수 집계다.

| 구분 | 스킬 | description | 본문 |
|---|---:|---:|---:|
| 하네스 자체 | 27 | 4,927자 | 199,475바이트 |
| **제3자 도입** | **19 (34%)** | 3,844자 (40%) | **173,669바이트 (45%)** |
| `learned` (자체 생성) | 9 | 699자 | 9,724바이트 |

**§3.1이 본문을 실효 위치로 지목했으므로 45%가 관련 수치다.** 그리고 본문이 description의 약 40배다.

`origin:` 값은 `ECC`·`SCE`·`sample-claude-env` 같은 **자유 문자열**이고 URL·리비전·해시가 없다. **§2.2의 핀 요구를 만족하는 필드가 하나도 없다.**

### 5.2 실행 코드 경로

| 마켓플레이스 | 플러그인 | `source` 구조 |
|---|---:|---|
| `claude-plugins-official` | 276 | `{source, url, path, ref, sha}` |
| **`openai-codex`** | 1 | **평문 문자열 (핀 없음)** |
| `supabase-agent-skills` | 1 | 평문 문자열 |

하네스가 실제로 의존하는 것이 `openai-codex`다 — [검증·교차리뷰 §4.1](verification-and-cross-review.md)의 adversarial review가 이 플러그인의 `codex-companion.mjs`를 쓴다. 캐시에 실행 파일 36개, 버전 2종(1.0.2·1.0.3)이 있고, `SessionStart`·`SessionEnd`·`Stop` 훅을 등록하며 `~/.claude/settings.json`에서 **사용자 수준 활성화**되어 있다.

**즉 ASI05(Unexpected Code Execution)와 ASI04가 동시에 걸리는 경로가 실재한다.**

### 5.3 MCP는 현재 0개

프로젝트·사용자 스코프 4곳 모두 `mcpServers` 0이고 `.mcp.json`도 없다. **ASI02의 도구 오염은 현재 노출이 아니라 예정 위험이다.**

**단 구분이 필요하다** — 이 조사를 수행한 세션에는 MCP 도구가 있고, 그것은 하네스 설정이 아니라 claude.ai 통합으로 들어온다. **하네스는 자신이 실행되는 세션의 MCP 표면을 통제하지 못한다.** grid fin 설계에 직접 걸리는 제약이다.

### 5.4 신뢰 경계가 현재 없다

[강제 메커니즘 조사 §1.3](enforcement-mechanisms.md)이 확인한 것 그대로다 — `permissions.deny` 0건, `ask` 0건, `sandbox` 설정 없음, `Skill(*)` 전체 허용. **제3자 스킬 19종과 자체 저작 27종이 동일 권한으로 동작한다.**

§1.2의 패턴 6종이 전부 **능력 제한**을 전제하므로, 그 수단이 비어 있다는 사실이 패턴 적용의 선행 조건이 된다.

### 5.5 정보 유출 — 이슈 본문

[오류 재발 조사 §7.10.8](error-recurrence-prevention.md)이 남긴 위험(이슈 본문에 프로젝트 정보가 실려 원본 저장소로 감)의 재료를 실측했다. `review-report-*.md`는 파일 경로·코드 스니펫·도메인 용어·커밋 SHA를 담고, `spec.md`는 아키텍처 결정과 비즈니스 규칙을 담는다.

**원본 저장소가 공개면 결정론적 사전 필터가 필수가 되고, 비공개면 선택이 된다.** komi-learn 선례([오류 재발 §6.2](error-recurrence-prevention.md))가 그 형태를 준다 — 비밀값·머신 고유 경로·일회성 실패를 LLM에 닿기 전에 기계적으로 거른다.

---

## 6. 자료가 답하지 않는 것

1. ~~**패턴 6종 중 코딩 하네스에 무엇이 맞는가.**~~ **출처 감사(2026-08-02)에서 해소 — §1.2.1 참고.** 저자들의 선택은 **Dual LLM + 엄격한 데이터 포매팅**이다. **남는 것은 범위다** — 그 사례가 상정한 신뢰할 수 없는 입력은 온라인 문서와 제3자 패키지이고, **저장소 콘텐츠·이슈 트래커는 다루지 않는다.**
2. **패턴의 비용이 개인 규모에서 감당 가능한가.** Dual LLM·Code-Then-Execute는 오케스트레이션 복잡도를 요구한다. 논문은 효용 손실을 정성적으로만 기술한다.
3. **SLSA L1을 스킬·플러그인에 어떻게 사상하는가.** SLSA는 빌드 아티팩트 대상이고 스킬은 소스 텍스트다. provenance의 "빌드 플랫폼·과정·입력"에 대응하는 것이 무엇인지 자료가 답하지 않는다.
4. **`ECC`·`SCE`가 무엇인가**(§5.1). 라벨의 실체를 추적하지 못했다. **제3자 분류의 근거가 라벨 자체이므로 라벨이 틀리면 분류도 틀린다.**
5. **소급 핀이 가능한가.** 이미 도입된 19종에 "승인된 리비전"이 무엇인지 알 방법이 없다. 현재 내용을 기준선으로 삼는 것 외의 방법을 자료에서 찾지 못했다.
6. **`Skill(*)` 대신 스킬 단위 권한이 가능한가**(§5.4). 제3자와 자체 저작을 다른 권한으로 돌리려면 필요한데 `permissions`의 입도를 확인하지 않았다.
7. **세션의 MCP 표면을 하네스가 열거·제한할 수 있는가**(§5.3). 못 한다면 "MCP를 안 쓴다"는 전제가 성립하지 않는다.
8. **POISE 저자들의 방어 제안.** 초록만 봐서 §3.2의 "스캐닝은 안 된다"가 최종 결론인지 중간 단계인지 모른다.
9. **`learned` 항목의 처우.** 지금은 자체 생성이라 공급망 밖이지만 공용 저장소 도입 시 들어온다. komi-learn이 **회상된 커뮤니티 항목을 untrusted로 라벨링**한 선례가 있으나 그 표기 체계를 조사하지 않았다.

---

## 부록. 조사 방법 및 한계

**방법**
- WebFetch 4회 — 설계 패턴 논문 HTML 전문, OWASP 배포본, SLSA v1.0 levels, POISE 초록
- 브라우저 1회 — OWASP 랜딩 페이지(목록이 다운로드 게이트 뒤에 있음을 확인)
- WebSearch 2회 — OWASP 1차 자료 위치 파악
- 하네스 실측(§5, 보조) — 스킬 55종의 `origin`·크기 전수 집계, 마켓플레이스 3종의 `source` 필드, 플러그인 캐시와 훅 등록, MCP 설정 4곳

**한계**

- **§1의 설계 패턴 논문은 HTML 본문에서 패턴 목록과 대가를 추출했다.** 초판은 사례 연구 본문을 읽지 않아 *"가장 값진 자료인데 가장 얕게 읽었다"* 고 적었다. **출처 감사(2026-08-02)에서 사례 10번(Software Engineering Agent)을 확인해 §1.2.1로 보강했다.** 나머지 사례 9건과 각 패턴의 구현 세부는 여전히 읽지 않았다.
- **POISE는 초록만 확인했다.** 2026 프리프린트이며 피어리뷰 전이다. 89.3%·74.6%·5.6%는 초록 기재값이고 재현하지 않았다.
- **OWASP는 순위 방법론을 공개하지 않는다.** 근거로 드는 것은 전문가 합의와 사건 추적기(Appendix D)이며 가중치는 밝히지 않는다. **아젠다 §8-1이 인용한 "프롬프트 인젝션이 최대 원인"이라는 정량 표현은 OWASP가 아니라 [2차 커버리지](https://www.helpnetsecurity.com/2026/06/11/owasp-prompt-injection-ai-security-failures/)의 것이다.** ASI01이 목록 1번인 것은 사실이다.
- **SLSA는 v1.0을 확인했고 현재 최신은 v1.2다.** 그리고 v1.0은 Build track만 다루며 소스 무결성은 범위 밖이다.
- **§5는 위험의 실현이 아니라 검증 수단의 부재를 확인했다.** 제3자 컴포넌트 19종과 플러그인 실행 파일 36개 중 **어느 것도 악성이라는 근거를 찾지 않았고 찾으려 하지도 않았다.** 결론은 "오염되어 있다"가 아니라 "오염되었는지 확인할 방법이 없다"이다.
- **제3자 스킬 본문 173,669바이트와 플러그인 훅 코드를 읽지 않았다.** §3.1이 본문을 실효 위치로 지목했는데 §5의 관측은 크기와 라벨까지다.
- **하네스 원본을 셌고 cygnus 배포본을 세지 않았다.** 배포 시 일부 스킬이 제외될 수 있어 실제 프로젝트 노출면은 다를 수 있다.
