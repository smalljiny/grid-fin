# 코딩 아닌 작업 — 하네스가 무엇을 다뤄야 하고 어떻게 설계하는가

*Generated: 2026-08-03 | Sources: 7 심층 + 40여 검색 | Adapters: [adapter-exa] | Failed: 없음*

**최초 작성**: 2026-08-03
**최종 수정**: 2026-08-03

**대상 프로젝트**: grid fin (신규 개인용 개발 하네스)
**질문**: 소프트웨어 개발은 구현체 작성만이 아니다 — 설정·배포·테스트·마이그레이션·운영을 하네스가 어떻게 다루는가
**조사 도구**: `adapter-deep-research`(exa), WebFetch, 로컬 저장소 직접 측정
**성격**: 조사. 작업 분류나 게이트 규격의 확정은 하지 않는다.

선행 문서
- [research-agenda.md](research-agenda.md) §0 — 13개 Design Primitive 커버리지 표. **이 조사가 그 표의 성격 자체를 문제 삼는다**
- [workflow-and-feature-list.md](workflow-and-feature-list.md) §5 — *"검증 필드 문제 — 하네스는 웹앱이 아니다"*. 이 조사가 그것을 일반 문제의 한 사례로 재배치한다
- [enforcement-mechanisms.md](enforcement-mechanisms.md) — `deny`·`ask`·`sandbox` 실측 0건
- [workflow-and-feature-list.md](workflow-and-feature-list.md) §D — 코드 아닌 산출물의 완료 기준

---

## Executive Summary

**하네스 엔지니어링 문헌에는 "작업 종류" 축이 아예 없다.** `awesome-harness-engineering`의 13개 Design Primitive는 전부 **하네스 구성 기제**(루프·컨텍스트·도구·메모리·검증)이며, 배포·설정·마이그레이션 같은 **감독 대상 작업의 종류로 분류하는 절이 하나도 없다**(§1). **따라서 이 질문에는 찾아볼 정답이 없고, 인접 문헌에서 조립해야 한다.**

**조립할 재료는 세 벤치마크가 준다** — ExITBench의 **IT 자동화 7종**, DevOps-Gym의 **주기 4단계**, InfraBench의 **계층 × 생애주기 × 위험** 3차원(§2). 그리고 InfraBench의 비교표가 **SWE-Bench에는 생애주기와 위험 축이 둘 다 없다**고 명시한다 — 코딩 벤치마크가 이 영역을 덮지 않는다는 진술이 표로 있다.

**작업 이름이 아니라 되돌릴 수 있는가가 설계를 가른다**(§3). 되돌릴 수 있으면 센서를 **뒤에**, 없으면 게이트를 **앞에** 둔다. **하네스 전체가 전제하는 "쓰고 검증하고 고친다" 루프가 후자에서는 성립하지 않는다.** [강제 메커니즘 조사](enforcement-mechanisms.md)가 실측한 `deny`·`ask`·`sandbox` **0건**이 정확히 이 부분의 공백이다.

**실증은 일관되게 낮다** — Ansible 자동화 최고 pass@10 **23.9%**(ACL 2026, 피어리뷰), SRE 과제에서 프런티어 모델 **50% 미만**, 인프라 과제 56~91%. 그리고 실패의 형태가 공통이다 — **"보이는 목표는 달성하고 운영상 의무는 놓친다"**(§5).

**기존 하네스에는 이 영역이 통째로 비어 있다**(§6). 규칙 6개는 전부 TypeScript/Vitest이고, `배포`라는 단어는 **하네스 자신의 배포**를 가리킨다. 애플리케이션 배포·마이그레이션·설정 변경 규칙이 **0건**이다.

> ⚠️ **가장 중요한 단서를 요약에 올려 둔다 — 이 조사가 인용한 벤치마크는 전부 클러스터 규모를 전제한다.** InfraBench는 CloudLab 베어메탈 테스트베드, devops-bench는 GKE 프로비저닝, ITBench는 K8s/RHEL이다. **개인 개발자의 "배포"는 대개 L4 한 층과 CI 한 번이다.** §2의 3차원(계층 L1–L4 × 생애주기 4단계 × 위험)을 그대로 옮기면 **명백한 과설계**다. **이 문서는 축이 존재함을 보이는 것이지 전부 채우라고 말하지 않는다** — 실제로 옮길 만한 것은 §3의 판별자(되돌릴 수 있는가)와 §4.5의 게이트 배치 두 가지다.

---

## 0. 조사 요약

| # | 관측 | 근거 | 등급 |
|---|---|---|---|
| 1 | **13개 Design Primitive에 작업 종류 축이 없다** — 전부 하네스 구성 기제다 | §1 | 1차 확인 |
| 2 | **InfraBench 비교표: SWE-Bench는 Lifecycle·Risk 둘 다 `–`** | §2.3 | 피어리뷰(워크숍) |
| 3 | **ExITBench: IT 자동화 7종 분류** (서버 설정/네트워킹/정책/템플릿/배포 파이프라인/변수 관리/파일 관리) | §2.1 | **피어리뷰(ACL)** |
| 4 | **ExITBench: 최고 pass@10 = 23.9%.** 1,517건 실패 분석 → *"state reconciliation reasoning failures … across nearly all evaluated models"* | §5.1 | **피어리뷰(ACL)** |
| 5 | **DevOps-Gym: 주기 4단계** (빌드·설정 / 모니터링 / 이슈 해결 / 테스트 생성) + 4단계 연쇄 파이프라인 18개 | §2.2 | 벤치마크 사이트 |
| 6 | **InfraBench: 계층 L1–L4 × 생애주기 4단계 × 위험 3차원** | §2.3 | 피어리뷰(워크숍) |
| 7 | **InfraBench는 위험을 정확성과 **동급의 1차 평가 신호**로 둔다** — 파괴적 명령, **안전 검사 비활성화**, 권한 상승, 설정 드리프트, 자원 누수, 무관 서비스 간섭 | §4.1 | 피어리뷰(워크숍) |
| 8 | **공통 실패 형태: "성공했으나 운영상 불완전"** — *"agents often satisfy visible objectives while still missing deeper operational obligations"* | §5.2 | 피어리뷰(워크숍) |
| 9 | **표면 신호 신뢰 실패** — 상위 수준 "approved" 표시만 읽고 근거를 확인하지 않는다 | §5.2 | 피어리뷰(워크숍) |
| 10 | **ITBench-AA: SRE 과제에서 프런티어 모델 50% 미만** | §5.1 | 벤더+제3자 공동 |
| 11 | **위험 4등급 분류가 실무 도구에 구현되어 있다** — safe / review / dangerous / **irreversible** | §4.2 | 제품 문서 |
| 12 | **정책 코드화(OPA/Conftest)가 설정 변경에 대한 계산적 센서를 준다** | §4.3 | 공식 문서 |
| 13 | **기존 하네스에 비코딩 작업 규칙이 0건이다.** 규칙 6개 전부 TS/Vitest, `배포`는 하네스 자신의 배포 | §6 | 1차 관측 |
| 14 | **모델 세대 지체가 세 번째로 반복된다** — ExITBench는 GPT-4.1-Mini·Claude-3.5-Sonnet, InfraBench만 Opus 4.7 포함 | §5.3 | 1차 확인 |

### 근거 등급

| 등급 | 무엇 |
|---|---|
| **피어리뷰(ACL)** | ExITBench — ACL 2026 Findings. **이 시리즈에서 드문 정식 피어리뷰 자료** |
| **피어리뷰(워크숍)** | InfraBench — HotInfra '26. 워크숍 논문, NSF 지원, 실무자 인터뷰 기반 |
| 벤치마크 사이트 | DevOps-Gym, devops-bench — 방법은 공개, 논문 미확인 |
| 공식 문서 | OPA/Conftest, Google SRE Workbook |
| 제품 문서 | readtheplan — **제품 마케팅 페이지다. 분류 체계의 존재 증명으로만 쓴다** |
| **확립된 실무(비에이전트)** | Google SRE canarying, progressive delivery — **에이전트 근거가 아니라 적응 대상이다** |

---

## 1. 프레임워크에 작업 종류 축이 없다

[아젠다 §0](research-agenda.md)이 `awesome-harness-engineering`의 13개 Design Primitive에 이 시리즈의 커버리지를 매핑했다. **이 조사는 먼저 그 프레임워크가 애초에 답을 담고 있는지 확인했다.**

원문 확인 결과 13개는 이렇다 — Agent Loop / Planning & Task Decomposition / Context Delivery & Compaction / Tool Design / Skills & MCP / Permissions & Authorization / Memory & State / Task Runners & Orchestration / Verification & CI / Observability & Tracing / Debugging & DX / Human-in-the-Loop / Security & Sandbox.

**전부 하네스를 *만드는* 기제다.** 하네스가 *감독하는 작업*을 배포·설정·마이그레이션·인시던트 대응 같은 종류로 가르는 절은 없다. 작업 도메인은 응용 예시로만 등장한다.

> **이것이 이 조사의 첫 번째 결과다.** 사용자가 물은 *"하네스가 코딩 외에 어떤 작업을 해결해야 하는가"* 는 **하네스 엔지니어링 문헌이 조직화하지 않은 축**이다. 그래서 이 문서는 **남의 분류를 보고하는 것이 아니라 인접 문헌에서 조립한다.** 조립물의 신뢰도는 원자료보다 낮으며, 그 점을 명시해 둔다.

**그리고 이 공백은 [워크플로우 조사 §5](workflow-and-feature-list.md)가 *"하네스는 웹앱이 아니다"* 로 마주쳤던 것과 같은 뿌리다.** 그 절이 제기한 문제는 **산출물이 markdown·프롬프트·스킬 정의일 때 피쳐 목록의 `verification` 필드를 채울 `curl`이 없다**는 것이었다. 이 조사는 그것을 **일반 문제의 한 사례**로 재배치한다 — **작업(또는 산출물)의 종류마다 가능한 센서가 다른데 프레임워크가 종류를 안 가른다.** 그 절은 *산출물* 축에서, 이 조사는 *작업* 축에서 같은 벽에 부딪힌다.

---

## 2. 조립 재료 — 세 벤치마크의 분류 축

### 2.1 작업 종류 — ExITBench의 IT 자동화 7종

[Large Language Models for IT Automation Tasks: Are We There Yet? (ACL 2026 Findings)](https://aclanthology.org/2026.findings-acl.560.pdf). Ansible 플레이북 126개 과제.

> *"seven key IT automation tasks: (1) **Server Configuration**, (2) **Networking**, (3) **Policy Configuration**, (4) **Templating**, (5) **Deployment Pipelines**, (6) **Variable Management**, (7) **File Management**"*

**이 분류의 성격**: 실무자가 Ansible로 실제 하는 일을 선행 연구(Begoug et al. 2023)에서 가져온 것이다. **grid fin에 그대로 옮길 목록이 아니다** — Ansible 중심이고, 빌드·릴리스·관측이 빠져 있다. **그러나 "설정"이 하나가 아니라 서버 설정 / 정책 설정 / 변수 관리 / 템플릿으로 갈린다**는 점은 옮길 만하다.

### 2.2 작업 단계 — DevOps-Gym의 주기 4단계

[DevOps-Gym](https://www.devops-gym.com/): *"the whole DevOps cycle: **build and configuration, monitoring, issue resolving, and test generation**"*.

| 단계 | 입력 / 출력 | 채점 |
|---|---|---|
| **Build & Config** | 빌드 설정이 깨진 저장소 → 수정 | 빌드 성공. 오류 5종 — 의존성 버전 충돌, 빌드 설정 오류, 컴파일 오류, 툴체인 불일치, 의존성 자원 미가용 |
| **Monitoring** | **소스·설정·트리거 접근 없이** 실행 중 컨테이너 → 이상 탐지 | 성능·자원 이상 검출 |
| **Issue Resolving** | 버그 설명 + 저장소 → 패치 | fail-to-pass 전이 |
| **Test Generation** | 버그 설명 → 회귀 테스트 | 실패를 재현하고 패치를 검증해야 함 |

**그리고 개별 능력과 별개로 4단계 연쇄 파이프라인 18개를 둔다** — *"test agents' ability to maintain context and solve problems across multiple stages"*.

> **`Monitoring` 항목이 특히 값지다** — *"terminal access (top, free, ps, netstat) with **no access to source code, configuration files, or trigger scripts**"*. **코드를 못 보는 작업이 명시적 범주로 존재한다.** 하네스가 코드 편집 도구만 준다면 이 범주는 수행 불가다.

### 2.3 3차원 — InfraBench의 계층 × 생애주기 × 위험

[Beyond Pass/Fail: Evaluating Infrastructure Agents Across Layers, Lifecycle, and Risk (HotInfra '26)](https://hotinfra.org/2026/papers/hotinfra26-final71.pdf). 실무자 인터뷰 + 오픈소스 이슈 트래커 + 상용 클라우드 문서 + 연구 프로토타입 4중 삼각측량.

**차원 1 — 계층**

| | 내용 |
|---|---|
| **L1 Hardware** | BMC/IPMI 제어, 전원 사이클, RAID 설정 |
| **L2 Local Systems** | OS, 컴파일러, 컨테이너 런타임 |
| **L3 Distributed Systems** | Ceph, Slurm 등 노드 간 시스템 |
| **L4 User Applications** | 로컬·분산 위에서 도는 사용자 대면 서비스 |

**차원 2 — 생애주기**: *"deployment, runtime usage, maintenance, **decommissioning**"*. 각 단계에 고유 검증이 붙는다 — *"Decommission verifies that the infrastructure can be restored to initial states, and/or requested resources are torn down cleanly **with no leakage**"*.

**차원 3 — 위험**: §4.1에서 별도로 다룬다.

**그리고 이 논문의 비교표가 이 조사에 필요한 진술을 준다.**

| 벤치마크 | 환경 | Lifecycle | Risk |
|---|---|---|---|
| SREGym | Cloud-native | △ | ✓ |
| ITBench | K8s/RHEL | △ | △ |
| DevOps-Gym | Project env. | – | △ |
| **SWE-Bench** | Repo/Docker | **–** | **–** |
| Terminal-Bench | Container | △ | – |
| **InfraBench** | Full | ✓ | ✓ |

> **SWE-Bench에 생애주기 축도 위험 축도 없다.** [평가 조사](evaluation.md)와 [효과 크기 조사](research-agenda.md)가 전부 SWE-bench 계열 위에 서 있었으므로, **이 시리즈가 지금까지 인용한 성능 수치는 전부 "되돌릴 수 있는 저장소 편집"에 대한 것이다.** 배포·마이그레이션으로 외삽할 근거가 없다.

---

## 3. 판별자는 작업 이름이 아니라 검증 가능성이다

§2가 준 세 분류는 **이름으로 가른 목록**이다. 이름은 하네스 설계를 결정하지 않는다. **결정하는 것은 "센서를 무엇으로 둘 수 있는가"이며, 그 앞에 "되돌릴 수 있는가"가 있다.**

[Fowler](https://martinfowler.com/articles/harness-engineering.html)의 축을 [아젠다 §0](research-agenda.md)이 이미 정리해 두었다 — **계산적 검증**(린터·타입체커: 빠르고 신뢰 가능) vs **추론적 검증**(AI 리뷰: 느리고 비쌈), 그리고 검증 3범주 중 **행동 검증이 미해결**.

**비코딩 작업이 그 미해결 칸을 각기 다르게 압박한다.**

| 작업 종류 | 되돌릴 수 있나 | 센서 | 센서 위치 | 주된 실패 |
|---|---|---|---|---|
| **설정 파일 편집** (선언적) | ✅ | **스키마·정책 검증**(계산적, 값싸다) | 행동 **전** 또는 후 | 스키마는 통과하고 의미가 틀림 |
| **활성 시스템 설정 변경** | **❌ (효과가)** | 정책 검증 + **위험 등급**(§4.2) | **행동 전 게이트** | IAM·보안그룹·DNS·플래그 100% 노출 |
| **테스트 작성** | ✅ | **산출물 자체가 센서다** | — | **에이전트가 테스트를 고쳐 통과시킨다** |
| **빌드·의존성** | ✅ | 빌드 성공/실패(계산적) | 행동 후 | 툴체인 불일치 |
| **모니터링·진단** | ✅ (읽기) | **없음 — 정답이 관측 대상에 있다** | — | 표면 신호 신뢰(§5.2) |
| **배포·마이그레이션·인프라** | ❌ | **사후 센서 없음** | **행동 전 게이트만** | 되돌릴 수 없는 손실 |

> **"설정"을 한 줄로 두면 안 된다.** §4.2가 인용한 실무 도구의 등급 예시 중 `aws_security_group` ingress 변경은 **review**, `aws_iam_role_policy` 교체는 **dangerous** 다 — **둘 다 설정 변경이다.** **파일 편집은 되돌릴 수 있고 그 효과는 아니다.** git revert는 IAM 정책이 이미 부여한 접근을 회수하지 못한다. 이 구분 없이 "설정 = 값싼 계산적 센서"로 읽으면 IAM 변경이 스키마 검사만 통과하고 나간다.

**네 줄이 중요하다.**

1. **테스트 작성은 센서와 산출물이 같다.** [검증·교차리뷰 조사](verification-and-cross-review.md)가 실측한 **훅 9개 중 게이트 0개**가 여기 걸린다 — 게이트가 없으면 에이전트가 테스트를 수정해 통과시키는 경로를 막을 수 없다. DevOps-Gym이 테스트 생성 채점을 *"must precisely reproduce the described failure and validate patch correctness"* 로 이중화한 이유다.
2. **모니터링에는 오라클이 없다.** 정답이 저장소가 아니라 실행 중인 시스템에 있고, DevOps-Gym은 소스 접근을 **차단**한다.
3. **배포·마이그레이션은 쓰고-검증-수정 루프를 깬다.** 이 시리즈의 모든 선행 문서가 그 루프를 전제한다.

> **[워크플로우 조사 §5](workflow-and-feature-list.md)의 *"하네스는 웹앱이 아니다"* 는 이 표에 새 행을 하나 더한다** — **하네스 자신의 산출물**(markdown·프롬프트·스킬 정의). 되돌릴 수 있고, **계산적 센서가 없으며**(실행 가능한 `curl`이 없다), 그 절이 지목한 대로 [아젠다 §6의 스킬 활성화 측정](research-agenda.md)과 같은 미해결에 걸린다. **[스킬 조사 §6-2](skill-architecture.md)가 재검색에서도 못 찾았다고 기록한 바로 그 항목이다.**

---

## 4. 되돌릴 수 없는 작업 — 게이트를 앞에 둔다

### 4.1 위험을 정확성과 동급 신호로 둔다

InfraBench의 **Risk Monitor**가 이 조사에서 가장 옮길 만한 설계다.

> *"InfraBench treats operational risk and side effects as **first-class evaluation signals alongside lifecycle correctness**. The Monitor observes both agent actions and environment states, and records suspicious operations throughout the lifecycle (e.g., **destructive commands, disabled safety checks, unnecessary privilege escalation, configuration drift, resource leaks, interference with unrelated services**). These signals flag cases where an agent reaches an immediate objective by relying on **unsafe shortcuts** or leaves collateral damage that pass/fail checks would miss."*

**여섯 신호 중 둘이 하네스 자신을 겨눈다** — *disabled safety checks*(안전 검사 비활성화)와 *unnecessary privilege escalation*. [아젠다 §2-5](research-agenda.md)가 *"에이전트가 린터 설정을 고쳐 규칙을 우회하는 것을 막는 법"* 을 조사 질문으로 열어두고 [강제 메커니즘 조사](enforcement-mechanisms.md)가 구체적 방법을 못 찾았던 그 문제다. **InfraBench는 막지는 못하되 관측 가능한 신호로 정의한다 — 이것만으로도 진전이다.**

> **저자들이 남긴 한계도 실무적이다** — *"the current risk assessment is parallel: it records destructive commands and other side effects **equally**, even though a fix that takes down a peer node may be more harmful"*. **위험에 등급이 필요하다.** §4.2가 그 등급의 실무 형태를 준다.

### 4.2 위험 4등급 — 실무 도구의 형태

[readtheplan](https://readtheplan.dev/)이 Terraform/OpenTofu plan을 네 등급으로 분류한다:

| 등급 | 예시 |
|---|---|
| **safe** | `aws_s3_bucket.logs` 태그 수정 |
| **review** | `aws_security_group.web` ingress 규칙 변경 |
| **dangerous** | `aws_iam_role_policy.app` 정책 교체 |
| **irreversible** | `aws_kms_key.primary` 키 삭제 예약 |

그리고 결정적 출력(`proceed`/`warn`/`block`)을 내며, **MCP 서버로 노출해 에이전트가 조회하도록 한다** — *"guide an MCP-compatible coding agent"*, *"Block unsafe AI auto-approvals"*.

> **제품 마케팅 페이지다. 등급 체계가 옳다는 근거가 아니라 "이런 형태가 실재한다"는 존재 증명으로만 쓴다.** 다만 **`safe`/`review`가 아니라 `dangerous`/`irreversible`을 가른 것**은 §3의 판별자와 정확히 같은 선이며, 두 출처가 독립적으로 같은 곳을 자른다.
>
> **grid fin에 옮길 형태는 "4등급 그 자체"가 아니라 "행동 전에 등급을 계산해 게이트에 먹인다"는 구조다.** 그리고 [강제 메커니즘 조사](enforcement-mechanisms.md)가 확인한 대로 **`PreToolUse`가 유일하게 차단 가능한 지점**이다.

### 4.3 계산적 센서 — 정책 코드화

설정 변경은 §3에서 **되돌릴 수 있고 계산적 센서가 값싼** 유일한 칸이었다. 그 센서의 확립된 형태가 정책 코드화다.

[OPA CI/CD 공식 문서](https://openpolicyagent.org/docs/cicd): *"OPA supports implementing policy-as-code guardrails in CI/CD pipelines … automatically verify configurations, validate outputs, and enforce organizational policies"*. [Conftest](https://www.conftest.dev/)가 *"write tests against structured configuration data"* — Kubernetes, Terraform, Serverless, 임의 구조 설정에 적용된다.

> **하네스 관점의 함의**: 설정 변경에는 **AI 리뷰(추론적)를 붙일 이유가 없다.** Fowler의 축에서 계산적 검증이 가능한 단계이고, [검증·교차리뷰 조사](verification-and-cross-review.md)가 실측한 **추론적 리뷰 지적의 78.5% 미조치**를 감안하면 값싼 결정적 게이트가 명백히 낫다.

### 4.4 확립된 실무 — 되돌릴 수 없음을 되돌릴 수 있게 바꾼다

[Google SRE Workbook 16장](https://sre.google/workbook/canarying-releases/): *"canarying as a **partial and time-limited** deployment of a change in a service and its evaluation. This evaluation helps us decide whether or not to proceed with the rollout."*

**카나리·점진적 배포·기능 플래그의 공통 기제는 "되돌릴 수 없는 행동을 되돌릴 수 있는 부분 행동으로 쪼개는 것"이다.** §3의 표에서 마지막 줄을 위쪽 줄로 옮기는 변환이다.

> ⚠️ **이 문헌은 에이전트 근거가 아니다.** 2010년대 SRE 실무이며 사람이 배포하는 것을 전제한다. **에이전트가 카나리를 운영할 때의 실증은 이 조사에서 찾지 못했다**(§7-3). **적응 대상으로 인용하되 근거로 쓰지 않는다.**

### 4.5 게이트를 어느 컴포넌트가 지는가 — 선행 조사와의 합성

> **사용자 질문의 후반부("하네스에서 어떻게 설계하고 진행하는가")에 답하려면 §4.1~§4.4의 산업 기제를 *이 하네스의 컴포넌트*로 내려야 한다.** 아래는 새 조사가 아니라 [스킬 조사](skill-architecture.md)·[강제 메커니즘 조사](enforcement-mechanisms.md)와의 합성이며, **근거는 그 문서들에 있다.**

| 작업 유형 | 게이트 위치 | 담는 컴포넌트 | 근거 |
|---|---|---|---|
| 설정 파일 편집 | 행동 후(값싸므로 매번) | **`PostToolUse` 훅**에서 Conftest/OPA | §4.3 + [강제 메커니즘](enforcement-mechanisms.md) |
| 활성 설정·배포·마이그레이션 | **행동 전 차단** | **`PreToolUse` 훅** — [강제 메커니즘 조사](enforcement-mechanisms.md)가 확인한 **유일하게 차단 가능한 지점** | 위 동일 |
| 되돌릴 수 없는 절차 전체 | **모델이 스스로 못 켬** | **`disable-model-invocation: true` 스킬** | [스킬 §1.2](skill-architecture.md) |
| 도구 권한 최소화 | 스킬 단위 | `allowed-tools` / `disallowed-tools` (**다음 메시지에 만료**) | [스킬 §1.2](skill-architecture.md) |

**공식 문서가 이 대응을 직접 말한다.** `disable-model-invocation: true`의 공식 용례가 *"workflows with **side effects** or that you want to **control timing**, like `/commit`, `/deploy`, or `/send-slack-message`"* 다 — **§3이 되돌릴 수 없다고 분류한 바로 그 부류가 이 필드의 문서화된 쓰임이다.**

**그리고 실제 구현 사례가 둘 다 이 형태다** — [db-migration-safe](https://github.com/alexbobkovv/db-migration-safe)는 **Agent Skill**로(squawk·eugene을 감싸 락 위험 탐지·롤백 생성·실행 게이트), [agent_db_guard](https://github.com/andrewjpyle/agent_db_guard)는 **Claude Code 훅**으로 프로덕션 DB 파괴 명령을 막는다. **§4의 산업 기제가 grid fin이 채택한 컴포넌트 모델 안에서 이미 두 가지로 구현되어 있다.**

> ⚠️ **그런데 상충이 있다.** [스킬 §3.2](skill-architecture.md)가 확인한 대로 **`disable-model-invocation: true` 스킬은 서브에이전트에 프리로드할 수 없고 coordinator 모드에서 실행되지 않는다.** 되돌릴 수 없는 작업을 전부 이 필드로 잠그면 **자동화 경로 전체에서 그 작업이 사라진다.** 안전 관점에서는 의도한 결과일 수 있고 자동화 관점에서는 결함이다. **어느 쪽인지는 이 조사가 판정하지 않는다**(§7-10).

---

## 5. 실증 — 에이전트는 비코딩 작업을 얼마나 하는가

### 5.1 세 벤치마크가 전부 낮다

| 벤치마크 | 영역 | 결과 |
|---|---|---|
| **ExITBench** (ACL 2026) | Ansible IT 자동화 126과제 | **최고 pass@10 = 23.9%** (GPT-4.1-Mini). Claude-3.5-Sonnet pass@1 = 18.8% |
| **ITBench-AA** (IBM + Artificial Analysis) | SRE 인시던트 근본 원인 분석 | **프런티어 모델 50% 미만** |
| **InfraBench** (HotInfra '26) | 인프라 12과제 4계층 | 평균 **56.1% ~ 90.8%**. Claude Code + Opus 4.7 = 90.8%, Codex + GPT-5.5 = 86.0% |

**세 자리 수가 크게 다른 이유는 과제 난이도와 채점 방식이다.** ExITBench는 **실행 후 기능적 정확성**을 이분 채점하고, InfraBench는 과제별 검증기가 [0,1] 연속 점수를 준다. **직접 비교하면 안 된다.**

**ExITBench의 실패 분석이 가장 구체적이다** — 1,517건 실행 실패를 질적 분석해 오류 분류 체계를 만들었고, 결론이 이렇다:

> *"widespread **state reconciliation reasoning failures** are a defining challenge across nearly all evaluated models. These include variable and path handling errors, reflecting challenges in tracking state"*
> *"a critical gap between **syntactic validity** and **reliable execution** for complex, state-based IT automation"*

> **"문법은 맞는데 상태 추론이 틀린다"가 코딩과 비코딩을 가르는 실패선이다.** 코드 생성 벤치마크는 문법·단위 동작을 재고, IT 자동화는 **시스템의 현재 상태와 목표 상태의 조정**을 요구한다.

### 5.2 실패의 형태가 공통이다 — "성공했으나 운영상 불완전"

InfraBench:

> *"the mean scores range from 58.6% to 90.5%, suggesting that the benchmark is not saturated even by the strongest agent/model. The imperfect scores indicate that **agents often satisfy visible objectives while still missing deeper operational obligations, such as durable state, distributed consistency, peer safety, and cleanup**."*
> *"successful but operationally incomplete: agents make the data plane available but **miss cleanup or drift obligations** such as incident markers and stale configuration."*

**실제 인시던트에서 유도한 과제(Pelican)의 실패 패턴 첫 번째가 특히 날카롭다:**

> *"**Trusting a surface status signal.** Some agents read a high-level "approved" indicator and stop, **without checking the underlying key material that the indicator is supposed to summarize.** They report success while the registry still [fails]"*

> **이 시리즈가 반복해 만난 형태다.** [워크플로우 조사 §4.1](workflow-and-feature-list.md)의 *"조기 완료 선언"*, [검증 조사](verification-and-cross-review.md)의 *"에이전트 자기 신고 의존"*, 그리고 [지시 계층 §10.5](instruction-layers.md)에서 **이 조사자 자신이** 출력을 잘라 읽고 정반대 결론에 도달할 뻔한 일까지 같은 형태다 — **요약 신호를 근거로 착각한다.**
>
> **비코딩 작업에서 이것이 더 위험한 이유는 §3이다** — 되돌릴 수 없는 작업에서는 잘못된 완료 판정이 재시도로 회복되지 않는다.

### 5.3 모델 세대 지체 — 세 번째 반복

| 벤치마크 | 시험 모델 |
|---|---|
| ExITBench (ACL 2026) | GPT-4.1-Mini, Claude-3.5-Sonnet, Gemini-2.5-Flash-Lite, 오픈 7종 |
| InfraBench (HotInfra '26) | **Claude Opus 4.7**, GPT-5.5, Gemini 3.5 Flash, Sonnet 4.6, DeepSeek V4 |

**ExITBench의 23.9%는 Claude-3.5-Sonnet 세대 수치다.** 최신 모델로 얼마나 오르는지 이 논문은 답하지 않는다. **InfraBench만 현세대를 포함하고, 거기서 Claude Code+Opus 4.7이 90.8%로 최고다.**

> **[컨텍스트 파일 조사 §3.1](context-file-content.md)과 [스킬 조사 §2.1](skill-architecture.md)에 이어 세 번째다.** 서로 무관한 세 문헌에서 **측정 자료가 사용자가 쓰는 모델 세대보다 한두 세대 뒤처진다.** **이제 우연이 아니라 이 분야 문헌의 구조적 성질로 봐야 한다** — 벤치마크 구축·실행 주기가 모델 출시 주기보다 길다.
>
> **실무적 귀결**: 낮은 절대 수치는 **하한으로만** 읽고, **실패의 *형태*(§5.2)를 수치보다 신뢰한다.** 형태는 세대가 바뀌어도 잘 안 변한다 — InfraBench의 현세대 결과에서도 같은 형태가 나온다.

### 5.4 하네스가 모델보다 크게 흔든다 — 여기서도

InfraBench: *"the same agent may vary by **more than 30 points** across underlying models"*.

그리고 [평가 조사 §1.5](evaluation.md)가 인용한 Zhang et al.의 **하네스 분산 / 모델 분산 = 7.80×** 와 방향이 맞는다. **다만 InfraBench의 문장은 *모델* 간 30점 차이이므로 그 자체로는 하네스 효과의 증거가 아니다** — 저자들도 *"the mean score metric may conflate capability with cost"* 라 적는다.

---

## 6. 1차 관측 — 기존 하네스에 이 영역이 없다

`/Users/mario/Workspace/harness/src` 상시 로드 계층 전체(`AGENTS.md`, `harness-guide.md`, `.harness/rules/*`)에서 비코딩 작업 관련 문자열을 검색했다.

| 찾은 것 | 실제 내용 |
|---|---|
| `배포` (AGENTS.md·guide 다수) | **하네스 자신의 배포** — `scripts/deploy-harness.sh`, `src/` → 루트 자기 동기화 |
| `uv` / Python (10여 곳) | **graphify CLI 설치·호출** — 분석 도구 의존성이지 프로젝트 런타임이 아님 |
| 빌드·테스트 명령 | `.harness/rules/testing.md`의 **Vitest 패턴뿐** |
| 마이그레이션 / 인프라 / 설정 변경 / 릴리스 | **0건** |

**규칙 6개의 구성**: `coding-style` / `git-workflow` / `security` / `testing` / `typescript/patterns` / `typescript/testing`. **여섯 중 둘이 TypeScript 전용이고, 나머지도 코드 작성과 git을 다룬다.**

> **개발환경 전제(세션 메모리 기록)가 *"모노레포는 기본값, 런타임은 다중 — Node 주력이되 Python·Rust 배제 안 함"* 인데, 기존 하네스의 규칙은 단일 런타임·단일 작업 종류를 가정한다.** 그리고 [컨텍스트 파일 조사 A](context-file-content.md)가 확인한 신규 `/init` Include 목록의 첫 항목이 *"Build/test/lint commands Claude can't guess (**non-standard scripts, flags, or sequences**)"* 다 — **다중 런타임 모노레포에서 이 항목이 가장 커지는데, 참고 하네스에는 그 부분이 비어 있다.**
>
> **이것은 참고 하네스의 결함 지적이 아니라 범위 확인이다.** 그 하네스는 자신을 개발하는 용도로 만들어졌고 자신은 Node/TS 프로젝트다. **grid fin이 다중 런타임을 전제로 한다면 이 영역은 계승할 것이 없고 새로 만들어야 한다.**

---

## 7. 이 조사가 답하지 않은 것

1. **작업 분류의 정본이 없다**(§1). §2의 세 축(ExITBench 7종 / DevOps-Gym 4단계 / InfraBench 3차원)은 **서로 다른 것을 자르며 통합되지 않는다.** 어느 것이 하네스 설계에 옳은 단위인지 자료가 말하지 않는다.
2. **개인 규모에 이 축들이 전이되는가.** 세 벤치마크 전부 **클러스터·베어메탈·분산 시스템**을 전제한다(InfraBench는 CloudLab 테스트베드). **개인 개발자의 "배포"는 대개 L4 한 층이고 CI 한 번이다.** 축을 그대로 옮기면 과설계다.
3. **에이전트가 카나리·점진적 배포를 운영할 때의 실증**(§4.4). SRE 문헌은 사람 전제, 에이전트 문헌은 이 기제를 다루지 않는다. **두 문헌 사이가 비어 있다.**
4. **위험 등급을 무엇이 계산하는가.** §4.2는 Terraform plan이라는 **정형 입력**이 있어 가능하다. 임의의 Bash 명령이나 앱 배포 스크립트에 같은 분류를 붙이는 방법을 찾지 못했다. **[강제 메커니즘 조사](enforcement-mechanisms.md)의 `PreToolUse`가 받는 것은 도구 호출이지 plan이 아니다.**
5. **Terraform MCP의 `ENABLE_TF_OPERATIONS` 기본값 `false`** — 검색 요약에서 나왔고 **개인 블로그 출처다. 공식 문서로 확인하지 않았다.** 사실이면 "쓰기는 명시적 opt-in"이라는 벤더 규격 사례가 되므로 확인 가치가 있다.
6. **테스트를 고쳐 통과시키는 문제의 실제 해법**(§3의 2행). DevOps-Gym의 이중 채점은 **벤치마크 설계**이지 하네스가 쓸 수 있는 게이트가 아니다.
7. **모니터링·진단 작업에 하네스가 무엇을 주어야 하는가**(§2.2). 소스 접근 없이 `top`/`ps`/`netstat`로 판단하는 작업은 [도구 설계](research-agenda.md) 프리미티브에 속하는데, 이 시리즈가 아직 안 다룬 영역이다.
8. ~~**`decommissioning` 단계에 대응하는 것이 개발 하네스에 있는가**~~ **부분 해소 — 있고, 이미 새고 있다.** InfraBench가 *"resources are torn down cleanly **with no leakage**"* 로 채점하는 단계에 대응하는 것이 **워크트리 teardown과 세션 종료**다. 그리고 [상태·연속성 조사](state-and-continuity.md)가 이미 실측했다 — **상태 보유자 8종 중 추적되는 것은 2종이고, gitignore 대상이 롤백 범위 밖이라 상태 발산이 확정적**이며, [지시 계층 §9.5](instruction-layers.md)는 **세션을 열기만 해도 `dev-context.json`이 생겨 저장소가 dirty해진다**고 기록했다. **즉 InfraBench의 채점 항목을 그대로 적용하면 기존 하네스는 decommission에서 감점된다.** **남는 질문은 "있는가"가 아니라 "무엇을 leakage로 셀 것인가"** — [상태·연속성 조사](state-and-continuity.md)의 8종 목록이 후보다.
9. **SREGym(arXiv 2605.07161), ITBench 원 논문, Harness Bench를 읽지 않았다.** InfraBench 비교표를 통한 2차 정보다.
10. **되돌릴 수 없는 작업을 `disable-model-invocation`으로 잠그는 것이 옳은가**(§4.5). 그러면 [스킬 §3.2](skill-architecture.md)에 따라 **서브에이전트·coordinator 경로에서 그 작업이 사라진다.** 안전 측면의 의도된 결과인지 자동화 측면의 결함인지 자료가 없다. **"커맨드 없이 스킬만" 구성에서 즉시 부딪히는 선택이다.**

---

## Sources

**피어리뷰**
1. [Large Language Models for IT Automation Tasks: Are We There Yet? — ACL 2026 Findings](https://aclanthology.org/2026.findings-acl.560.pdf) — ExITBench 126과제, IT 자동화 7종, pass@10 23.9%, 실패 1,517건 분류
2. [Beyond Pass/Fail: Evaluating Infrastructure Agents Across Layers, Lifecycle, and Risk — HotInfra '26](https://hotinfra.org/2026/papers/hotinfra26-final71.pdf) — InfraBench 3차원, Risk Monitor, "operationally incomplete"

**벤치마크**
3. [DevOps-Gym](https://www.devops-gym.com/) — 주기 4단계 + 연쇄 파이프라인 18개
4. [gke-labs/devops-bench](https://github.com/gke-labs/devops-bench) — K8s 중심, `chaos_spec` × `verification_spec` 쌍, 정리(cleanup) 요구
5. [ITBench-AA — Artificial Analysis + IBM](https://artificialanalysis.ai/articles/itbench-aa-launch) — SRE 과제, 프런티어 모델 50% 미만

**확립된 실무 / 공식 문서**
6. [Google SRE Workbook Ch.16 — Canarying Releases](https://sre.google/workbook/canarying-releases/) — 부분·시간 한정 배포
7. [OPA — Using OPA in CI/CD Pipelines](https://openpolicyagent.org/docs/cicd) / [Conftest](https://www.conftest.dev/) — 설정에 대한 계산적 센서
8. [awesome-harness-engineering](https://github.com/ai-boost/awesome-harness-engineering) — 13 프리미티브 원문 확인(§1)

**제품 문서 (존재 증명용)**
9. [readtheplan](https://readtheplan.dev/) — safe/review/dangerous/irreversible 4등급 + MCP 노출
10. [prodgate](https://github.com/prodgate-dev/prodgate) — CI에서 파괴적 Terraform 변경 차단
11. [alexbobkovv/db-migration-safe](https://github.com/alexbobkovv/db-migration-safe) · [andrewjpyle/agent_db_guard](https://github.com/andrewjpyle/agent_db_guard) — **DB 마이그레이션 안전을 Agent Skill / Claude Code 훅으로 구현한 사례.** [스킬 조사](skill-architecture.md)의 타입 체계와 맞물린다
12. [Atlas — AI-safe migrations](https://atlasgo.io/use-cases/ai-safe-migrations) · [Liquibase — AI agents as insider threat](https://www.liquibase.com/blog/the-new-insider-threat-how-to-stop-ai-agents-from-nuking-your-database) — 벤더 관점

**미확인 (후속 대상)**
13. [SREGym (arXiv 2605.07161)](https://arxiv.org/abs/2605.07161) · ITBench 원 논문 · [Harness Bench](https://www.harness-bench.ai/) — **InfraBench 비교표를 통한 2차 정보만 있다**

---

## Methodology

**검색**: exa `/search` 5회(auto, 8건). 하위 질문 — 코드 생성 밖의 에이전트 벤치마크 / IaC 승인 게이트 / DB 마이그레이션 안전 / 정책 코드화 / SRE 변경 위험 분류.
**정독**: exa `/contents` 1회 배치로 7개 문서(약 222 KB) 취득 후 절 단위 추출.
**병행 1차 확인**: `awesome-harness-engineering` 원문 WebFetch(13 프리미티브에 작업 종류 축이 있는지), 참고 하네스 상시 로드 계층 grep(비코딩 작업 인코딩 유무).

> **어댑터 스킬의 서브에이전트 지침 대신 메인 세션 순차 실행했다** — [스킬 조사](skill-architecture.md)와 같은 이유(세션의 AgentTool 제약).
> **저장 경로도 어댑터 기본값(`./`) 대신 기존 조사 코퍼스 규약을 따랐다.**

**방법 기록 — 상호참조를 기억으로 썼다가 틀렸다**

초판이 *"하네스는 웹앱이 아니다"* 절을 **검증·교차리뷰 조사**로 세 곳에서 지목했으나 실제로는 **워크플로우 조사 §5**다. 그리고 그 절의 문제도 잘못 요약했다 — *"웹앱이 아니면 E2E 도구가 안 맞는다"* 가 아니라 **"산출물이 markdown·프롬프트·스킬 정의일 때 `verification` 필드를 채울 `curl`이 없다"** 이다. `grep -l` 한 번으로 잡혔다.

> **[§10.5](instruction-layers.md)의 "출력을 잘라 읽지 말 것"과 같은 등급의 규율이 상호참조에도 필요하다** — 문서가 여섯 편을 넘어가면 기억으로 인용하면 안 되고, **새 상호참조마다 `grep -l`로 확인해야 한다.** 이 시리즈에서 네 번째로 겪는 "확인 없이 옮겨 적기" 계열 오류이며, **이번에는 외부 자료가 아니라 자기 문서를 잘못 인용했다.**

**한계**

- **§1의 결론(작업 종류 축 부재)이 문서 하나에 대한 확인이다.** `awesome-harness-engineering`은 이 시리즈가 인덱스로 쓴 목록이지 분야의 정본이 아니다. **다른 프레임워크에 그 축이 있을 가능성을 배제하지 못한다.**
- **§2의 세 축은 통합되지 않은 채 병렬 제시했다**(§7-1). 조립물이며 원자료보다 신뢰도가 낮다.
- **§3의 표는 이 조사가 만든 것이다.** 각 행의 근거는 §2·§4·§5에 있으나 **표 자체를 지지하는 출처는 없다.**
- **에이전트가 카나리·점진 배포를 운영하는 실증이 없다**(§7-3). §4.4는 비에이전트 문헌이다.
- **벤치마크 전부 클러스터 규모를 전제한다**(§7-2). 개인 규모 전이가 미확인이다.
- **세 수치(23.9% / 50% 미만 / 56~91%)는 서로 다른 채점 방식이라 비교 불가다.** 각각의 문맥에서만 읽었다.
- **Terraform MCP의 기본값 주장은 개인 블로그 출처이며 인용하지 않았다**(§7-5).
- **SREGym·ITBench 원 논문·Harness Bench 미확인**(§7-9).
