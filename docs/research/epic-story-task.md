# epic·story·task를 산업은 어떻게 다루는가 — 조사

*Generated: 2026-08-06 | Adapter: adapter-exa(검색 15회) + adapter-firecrawl(원문 14회) | Failed: 1회(Atlassian 컴포넌트 지원 문서가 JS 렌더라 본문 미확보 → 커뮤니티 2차로 대체)*

**최초 작성**: 2026-08-06
**최종 수정**: 2026-08-06
*2차 확장(2026-08-06): §8 추가 — **epic을 언제 등록하는가**와 story 분할 기준. 계기는 §8 서두에 적었다.*

**대상 프로젝트**: grid fin (신규 개인용 개발 하네스)
**조사 계기**: 사용자가 새 하네스의 작업 계층을 `epic > story > task > sub task`로 구상하면서, **epic의 수명이 경험상 둘로 갈렸다**고 밝힌 것 — 기능 대분류로 쓰면 폐기 전까지 살아 있었고, 프로토콜 마이그레이션 같은 큰 작업으로 쓰면 작업 종료와 함께 끝났다.
**성격**: 사례 조사. **설계 결정은 하지 않는다.**

관련 문서
- [워크플로우·피쳐 목록 조사](workflow-and-feature-list.md) §1.1~§1.3 — 참고 하네스의 topic/story/task 실측
- [워크플로우 설계 드래프트](../draft/overview.html) — 이 조사가 입력되는 곳

---

## 0. 조사 요약

| # | 관측 | 근거 | 등급 |
|---|---|---|---|
| 1 | **Scrum Guide 2020에 `epic`·`task`·`user story`가 한 번도 나오지 않는다.** 전문 검사 결과 각 **0회**, `story` 2회는 **전부 `history`의 부분 문자열**, `Product Backlog item`은 13회 | §1 | **1차(공식 전문 전수 검사)** |
| 2 | **Jira의 기본 계층은 3단이고 `Task`는 `Story`의 형제다** — Epic / 표준(Story·Task·Bug) / Subtask | §2.1 | **1차(벤더 공식)** |
| 3 | **Azure DevOps에서는 `Task`가 `User Story`의 자식이다** — *"Epics group Features, Features group Requirements(User Stories …), and Requirements group Tasks"* | §2.2 | **1차(벤더 공식)** |
| 4 | **Atlassian은 epic을 시간으로 정의한다** — *"an epic is something you might complete in a month or a quarter"*, 팀당 분기 2~3개 | §3.1 | **1차(벤더 공식)** |
| 5 | **SAFe의 epic은 승인·거부되는 투자 항목이다** — MVP + Lean business case + 비용 추정을 요구하고 포트폴리오 칸반에서 `Funnel → … → Done`으로 흐른다 | §3.2 | **1차(프레임워크 공식)** |
| 6 | **“끝나지 않는 epic”은 이름이 붙은 안티패턴이다** — catch-all / junk-drawer / infinite / zombie / eternal. **지목되는 대표 예시가 `Infrastructure`·`Admin` 같은 영역 이름** | §4 | **2차(독립 출처 6건 수렴)** |
| 7 | **지속하는 축은 작업 항목이 아니라 분류 필드다** — Azure DevOps는 Area Path와 Iteration Path를 **Classification Nodes**로 따로 두고, 작업 항목 계층은 그 위에서 별도로 흐른다 | §5.1 | **1차(벤더 공식)** |
| 8 | **Linear도 같은 갈래** — Team(지속 조직 단위) / Project(특정 결과의 실행 단위) / Initiative(목표로 프로젝트를 묶음) | §5.2 | 1차(벤더 공식) |
| 9 | **epic은 필수 부모가 아니다** — *"Not every user story needs to be part of an epic"* | §3.1 | **1차(벤더 공식)** |
| 10 | **story·task의 품질 기준은 XP가 준다** — INVEST(story) / SMART(task). **SMART의 `Measurable` 정의가 이미 `tests are included`를 done 조건으로 든다** | §6 | **1차(원저자 글)** |
| 11 | **대규모 마이그레이션은 계층이 아니라 슬라이스로 다룬다** — Strangler Fig | §7 | 1차(Fowler) + 2차 |
| **12** | **epic의 원 정의가 “큰 story에 붙이는 라벨”이다** — Mike Cohn, *User Stories Applied*(2004). 즉 **story는 크기를 재다가 epic으로 “발견”된다** | §8.1 | **1차(원저 인용)** |
| **13** | **그 뜻과 “묶음”이라는 뜻이 겸해지면 충돌한다** — *"it doesn't work very well when an epic (large user story) belongs to an epic (group of stories)"* | §8.2 | 1차(벤더 기술블로그) |
| **14** | **분해는 just-in-time이다** — *"There is usually no value to splitting a large user story up now … if we won't work on that item for quite awhile"*. 상세화 깊이를 백로그 위치가 정한다(PO Board 3단) | §8.4 | **1차(Cohn, Humanizing Work)** |
| **15** | **분할 축이 다섯으로 정리돼 있다** — SPIDR(Spike·Path·Interface·Data·Rules). 크기 기준은 *"fit 6 to 10 into a sprint"* | §8.5 | **1차(Cohn, Humanizing Work)** |

### 근거 등급

| 등급 | 자료 |
|---|---|
| **1차(공식 전문)** | Scrum Guide 2020 (scrumguides.org 전문 확보 후 단어 전수 검사) |
| **1차(벤더 공식)** | Atlassian 지원·에이자일 코치 문서, Microsoft Learn, Linear Docs |
| **1차(프레임워크 공식)** | Scaled Agile Framework `/epic` |
| **1차(원저자)** | Bill Wake, *INVEST in Good Stories, and SMART Tasks* |
| 2차 | 안티패턴 계열 블로그·커뮤니티 6건. **측정된 결과가 아니라 독립 출처의 수렴이다** |

---

## 1. 규범이 없다 — Scrum Guide에 이 어휘가 아예 없다

[Scrum Guide 2020](https://scrumguides.org/scrum-guide.html) 전문(약 25KB)을 받아 단어를 전수 검사했다.

| 단어 | 출현 |
|---|---:|
| `epic` | **0** |
| `task` | **0** |
| `user story` | **0** |
| `story` | 2 — **`history`/`History` 각 1회. 독립 출현 0** |
| `Product Backlog item` | 13 |

가이드가 규정하는 것은 **Product Backlog item**과 **Sprint Backlog**뿐이고, 하위 분해에 대해서는 *"is often done by decomposing Product Backlog items into smaller work"* 라고만 쓴다 — **이름도 크기도 규정하지 않는다.**

> **따라서 “산업 표준 계층”이라는 단일 규범은 존재하지 않는다.** `user story`는 XP에서 왔고, `epic`·`task` 계층은 도구 벤더가 만들었다. 사실상의 표준은 Jira와 Azure DevOps이며, **그 둘이 서로 다르다**(§2).

---

## 2. 사실상의 표준 둘 — `task`의 위치가 뒤집힌다

### 2.1 Jira — 3계층, `Task`는 `Story`의 형제

[Atlassian 공식 지원 문서](https://support.atlassian.com/jira-cloud-administration/docs/what-are-issue-types/) 원문:

> *"By default, Jira supports three levels of hierarchy"* — **Epic work items / 표준 작업 항목(Story·Task·Bug) / Subtask**

> *"As a parent work item, an epic can have stories, tasks, and bugs as child work items. As a parent work item, a task can have subtasks as child work items. A subtask can't have any child work items."*

**`Task`는 `Story`와 같은 레벨(Level 0)에 있고 `Subtask`의 부모다.** 레벨을 중간에 끼워 넣을 수 없으며, Advanced Roadmaps(Premium)가 추가해 주는 것은 **Epic 위쪽**이다(Atlassian 지원 KB, 요약 경유).

### 2.2 Azure DevOps — 4계층, `Task`는 `User Story`의 자식

[Microsoft Learn](https://learn.microsoft.com/en-us/azure/devops/boards/work-items/about-work-items?view=azure-devops) 원문:

> *"Work item types form a hierarchy: **Epics group Features, Features group Requirements (User Stories, Product Backlog Items, Issues, or Requirements), and Requirements group Tasks.**"*

즉 `Epic → Feature → User Story → Task`.

> **같은 단어가 두 도구에서 다른 층에 산다.** 계층 형태를 “표준을 따른다”로 정당화할 수 없다는 뜻이다.

---

## 3. epic의 수명 — 산업은 유한한 것으로 다룬다

### 3.1 Atlassian — 시간으로 정의한다

[Epics, stories, and initiatives](https://www.atlassian.com/agile/project-management/epics-stories-themes) 원문:

> *"While an epic is something you might complete in a month or a quarter, initiatives are often completed in **multiple quarters to a year**."*
> *"Teams often have **two or three epics** they work to complete each quarter."*
> *"**Not every user story needs to be part of an epic**; some stories are small enough to stand alone and deliver value independently."*

실무 가이드 다수(2차)가 같은 방향으로 수렴한다 — 분기(3개월) 권고, 3~6개월 상한, *"9개월 이상이면 추적 불가"*, 넘치면 **Phase 2 epic으로 분리**.

### 3.2 SAFe — 승인되거나 거부되는 투자 항목

[Scaled Agile `/epic`](https://framework.scaledagile.com/epic) 원문:

> *"Epics also differ from traditional projects in that they are not merely financial allocations. Instead, they're managed through a portfolio's Kanban system. This enables visibility and tracking of their development **until they are approved or rejected**."*
> *"Each epic requires an MVP, a Lean business case, and an estimate of costs."*

포트폴리오 칸반의 흐름은 `Funnel → Reviewing → Analyzing → Portfolio Backlog → Implementing → **Done**`이다.

> **두 출처가 서로 다른 규모에서 같은 결론에 온다 — epic에는 끝이 있다.**

---

## 4. “끝나지 않는 epic”은 이름이 붙은 안티패턴이다

독립된 출처 6건이 같은 것을 지목한다 — **catch-all / junk-drawer / infinite / zombie / eternal epic**. 서술되는 증상이 일관된다:

- 종료 조건이 없어 **진척을 판정할 수 없다**
- 다른 작업과 **우선순위 비교가 불가능**해진다
- **무관한 작업이 흘러든다**

> **지목되는 대표 예시가 `Infrastructure`·`Admin`·`Product Listing Page`다** — 전부 **영역 이름을 epic으로 만든 것**이다. 이 조사의 계기가 된 현상과 같은 모양이다.

**등급 주의**: 이 절은 전부 2차다. 여러 출처가 독립적으로 같은 것을 지목한다는 뜻이지 측정된 결과가 아니다.

---

## 5. 지속하는 축은 작업 항목이 아니다 — 분류 필드다

### 5.1 Azure DevOps — 두 축을 처음부터 분리한다

[Area and iteration paths](https://learn.microsoft.com/en-us/azure/devops/organizations/settings/about-areas-iterations?view=azure-devops) 원문:

> *"**Area paths group work items by team, product, or feature area. Iteration paths group work into sprints, milestones, or other time-related periods.**"*
> *"Area paths and iteration paths are also known as **Classification Nodes**."*

**둘 다 작업 항목이 아니라 분류 노드다.** Epic/Feature/Story/Task 계층은 그 위에서 별도로 흐르고, 하나의 작업 항목이 두 축의 값을 각각 갖는다.

### 5.2 Linear — Team / Project / Initiative

[Linear Docs — Concepts](https://linear.app/docs/conceptual-model) 원문:

> *"**Teams are the primary organizational unit** in Linear. Each team owns its own workflow, triage process, and planning cadence."*

Team은 지속하는 조직 단위이고 자체 워크플로·라벨·사이클을 소유한다. **Project**는 특정 결과를 떠받치는 실행 단위, **Initiative**는 목표 중심으로 프로젝트를 묶는 상위 개념이다.

### 5.3 Jira — Component vs Epic

Atlassian 공식 문서는 initiative 외의 수단으로 *"custom fields or labels to categorize by team, strategic pillar, or timeframe"* 를 명시한다(1차). Component가 **프로젝트 수준의 고정 분류이며 소유자를 지정할 수 있고**, Epic이 **시작과 끝이 있는 작업**이라는 대조는 커뮤니티 다수 답변에서 수렴한다(2차 — 공식 지원 문서는 JS 렌더로 본문 미확보).

> **세 도구가 이름은 다르나 같은 것을 한다 — 지속하는 분류를 작업 항목 밖에 둔다.** §4의 안티패턴은 그 둘을 한 필드에 담았을 때 나타나는 증상으로 읽힌다.

---

## 6. 품질 기준 — XP가 story와 task에 각각 준다

[Bill Wake, *INVEST in Good Stories, and SMART Tasks*](https://xp123.com/invest-in-good-stories-and-smart-tasks/) 원문.

**story = INVEST**: **I**ndependent · **N**egotiable · **V**aluable · **E**stimable · **S**mall · **T**estable

> `Independent`: *"we'd like them to not overlap in concept, and we'd like to be able to **schedule and implement them in any order**."* 그리고 저자가 스스로 단서를 단다 — *"We can't always achieve this."*

**task = SMART**: **S**pecific · **M**easurable · **A**chievable · **R**elevant · **T**ime-boxed

> `Measurable`의 정의가 이 조사에서 가장 실무적이다 — *"The key measure is, 'can we mark it as done?' … it should include **'does what it is intended to,' 'tests are included,' and 'the code has been refactored.'**"*

같은 글이 Ron Jeffries의 **3C**도 인용한다 — Card / Conversation / **Confirmation**, 여기서 Confirmation은 *"tests that verify them"* 이다.

> **즉 “task가 끝났다”의 산업 기준에 테스트 포함이 이미 들어 있다.** 크기를 시간으로 잴 뿐, 완료 판정은 산출물로 한다.

---

## 7. 대규모 마이그레이션 — 계층이 아니라 슬라이스

[Martin Fowler, Strangler Fig](https://martinfowler.com/bliki/StranglerFigApplication.html)(1차) — 점진 대체. 새 기능을 레거시 위에 얹고 동작을 조금씩 옮긴 뒤 옛 구성요소를 퇴역시킨다. 슬라이스마다 독립 배포·롤백이 가능해 위험이 국소화된다.

실무 가이드(2차)가 이를 *"단일 순차 프로젝트가 아니라 **동시 슬라이스의 포트폴리오**로 다뤄라"* 로 정리한다.

> **§6의 `Independent`와 맞물린다** — 마이그레이션을 story로 쪼개면 순서 의존이 생기는데, **슬라이스마다 독립 배포·롤백이 되게 자르면 Independent가 회복된다.** story 분할 기준으로 쓸 수 있다.

---

## 8. epic은 언제 등록되는가 — 등록이 아니라 발견이다

**조사 계기(2차 확장)**: 사용자가 <i>“이전 워크플로우에서는 토픽 기준으로 스펙을 쓰고 **스펙 확정 시점에 분할을 판단**했는데, 새 계층에서는 epic을 언제 어떻게 등록할지가 애매하다”</i>고 밝혔다.

### 8.1 원 정의가 이미 “발견”이다

[Thoughtworks, *User stories: A tale of epic confusion*](https://www.thoughtworks.com/insights/blog/user-stories-tale-epic-confusion)이 Mike Cohn의 원저를 인용한다.

> Mike Cohn, *User Stories Applied*(2004): epic은 ***"just a label we apply to a large story"***
> 그리고 글의 요약 문장 — ***"User stories are discovered to be epics through sizing."***

> *"Generally speaking, a user story we consider 'large', or 'too large' means **we lack confidence in developing in its current form**. … **Calling these out as epics helps to emphasise the need for story splitting.**"*

**즉 “범위를 넘으면 epic으로 승격하고 분할한다”는 것은 새 규칙이 아니라 원 정의다.**

### 8.2 그런데 두 뜻을 겸하면 충돌한다

같은 글이 문제를 정확히 짚는다.

> *"it doesn't work very well when **an epic (large user story) belongs to an epic (group of stories)**."*

그리고 “묶음” 용법이 분할 신호를 잡아먹는다고 본다 — *"Using epics to group stories deprives us of a concise term that could otherwise be used to emphasise the need for story splitting."* 대안으로 묶음 쪽에 `feature`나 `milestone`을 쓰라고 제안한다.

> **다만 승격으로 만들어진 epic에서는 두 뜻이 일치한다** — 종료 조건이 원래 story의 목표 문장이 되므로, 묶음이면서 동시에 끝이 있는 것이 된다. 이 조사는 그 관측만 적고 채택은 하지 않는다.

### 8.3 “모든 story에 epic을 달게 만드는” 압력이 안티패턴의 경로다

> *"The appeal of **Jira** influences the grouping of stories into epics for reporting purposes and **fuels a need to have every story assigned to one**. Have you ever wondered what drives the questions, **'what epic does this story belong to'**, or **'should we create an epic for that'**?"*

§3.1의 Atlassian 공식 문장(*"Not every user story needs to be part of an epic"*)과 §4의 catch-all 안티패턴이 같은 지점에서 만난다.

### 8.4 분해 시점 — just-in-time, 상위 1~2 스프린트만

[Mike Cohn, *Writing the Product Backlog Just in Time and Just Enough*](https://www.mountaingoatsoftware.com/articles/writing-the-product-backlog-just-in-time-and-just-enough) 원문:

> *"**There is usually no value to splitting a large user story up now** or stapling a document to it **if we won't work on that product backlog item for quite awhile.** … those doing so should strive to add just-enough detail that **no individual item will take more than one sprint** to complete."*

[Humanizing Work, *Backlog Refinement: Avoiding the Detail Trap*](https://www.humanizingwork.com/avoiding-the-detail-trap/)의 **PO Board 3단** — 상세화 깊이를 백로그 위치가 정한다:

| 위치 | 내용 | 상세도 |
|---|---|---|
| **Top** | 다음 **1~2 스프린트**용 user story | 착수 가능한 수준 |
| **Middle** | 다음 분기의 **MMF**(Minimum Marketable Feature) | 넓은 서술, **아직 story로 쪼개지 않음** |
| **Bottom** | 고수준 옵션, 만들지 않을 수도 있음 | 아이디어 수준 |

같은 글이 실패 모드를 **Detail Trap**으로 이름 붙인다 — **너무 일찍 상세화**(만들 때쯤 낡았거나 재작업) 또는 **너무 늦게 상세화**(계획 시점에 허둥댐).

> **이것이 “스펙 확정 시점에 한 번 전부 분할 판단”의 대안이다** — 관행은 항목이 Top으로 올라올 때마다 판단한다.

### 8.5 분할 축과 크기 기준

[Mike Cohn, SPIDR](https://www.mountaingoatsoftware.com/blog/five-simple-but-powerful-ways-to-split-user-stories) — 다섯 축:

| | |
|---|---|
| **S**pike | 모르는 것을 시간 제한 조사로 떼어낸다 |
| **P**ath | 경로가 여럿이면 happy path 먼저, 예외는 별도 |
| **I**nterface | 표면(브라우저·기기·최소 UI)으로 자른다 |
| **D**ata | 데이터 종류·범위로 자른다 |
| **R**ules | 비즈니스 규칙 변형으로 자른다 |

[Humanizing Work 분할 가이드](https://www.humanizingwork.com/the-humanizing-work-guide-to-splitting-user-stories/)(Richard Lawrence)는 **플로우차트 3단계**(입력 story 준비 → 패턴 적용 → 분할 평가)와 크기 기준을 준다:

> *"Our rule of thumb for small enough is, by the time a story makes it to the top of your backlog, **you should be able to fit 6 to 10 into a sprint**."*
> 그리고 **수직 슬라이스** 정의 — *"a work item that delivers a valuable change in system behavior such that you'll probably have to touch multiple architectural layers."*

**수평 분할에 대한 경고가 반복된다** — Thoughtworks는 `Front-end`/`Back-end`/`Security` 같은 **계층별 epic 묶음이 vertical slicing을 방해**한다고 지목한다.

### 8.6 도구 층의 승격 비용

Jira에서 issue type 변경은 Move/Edit로 가능하나(2차, 커뮤니티), **Epic ↔ Story 변환 시 자식이 자동 재매핑되지 않고** 먼저 재배치를 요구하며, 팀관리 프로젝트에서는 parent link가 남아 **중복 epic이 생기는 사례**가 이슈로 보고돼 있다(Atlassian 커뮤니티·이슈 트래커, 2차).

> **승격을 워크플로우에 넣으면 “자식 재부모화가 원자적이어야 한다”는 요구가 따라온다.**

---

## 9. 이 조사가 재지 않은 것

- **직접 실측 없음.** 전부 문헌이고, 어떤 계층 형태가 실제로 더 잘 작동하는지는 재지 않았다
- **Atlassian Component 공식 문서 본문 미확보** — JS 렌더로 스크레이프 실패. §5.3의 Component 서술은 2차다
- **Jira Premium/Advanced Roadmaps가 Epic **아래**에 레벨을 추가할 수 있는지** — 지원 KB 요약에서 “위쪽”만 확인했고 본문을 읽지 않았다
- **Atlassian의 “분기당 epic 2~3개” 같은 수치의 근거** — 벤더 문서에 방법론이 없다. 관행의 진술로만 읽어야 한다
- **§4 안티패턴의 빈도·심각도** — 전부 서술이고 측정치가 없다
- **SAFe 포트폴리오 칸반을 개인 규모로 축소한 사례** — 찾지 않았다
- **`sub task` 계층에 대한 산업 논의** — Jira의 Subtask 정의 외에 별도 자료를 보지 않았다
- **Humanizing Work 플로우차트의 본문**(§8.5) — 목차와 크기 기준·수직 슬라이스 정의까지만 확보했고, **Step 1~3의 판정 조건 본문은 읽지 못했다**(PDF 별도 배포)
- **SPIDR 다섯 축의 상세 설명** — 축 이름과 요지까지만 확인했고 각 축의 적용 조건은 본문에서 확인하지 않았다
- **“6~10개가 한 스프린트”와 “24~44줄”의 관계** — 두 수치가 같은 것을 재는지 재지 않았다. 전자는 개수 비율이고 후자는 변경 크기다
- **승격 트리거를 산출물(“하나의 PR로 닫히지 않는다”)로 잡은 선례** — 찾지 못했다. 자료의 트리거는 전부 **추정 기반**(스프린트에 안 들어감 / 포인트가 큼)이다

---

## 부록 — 출처

| 등급 | 출처 |
|---|---|
| **1차(공식 전문)** | [Scrum Guide 2020](https://scrumguides.org/scrum-guide.html) |
| **1차(벤더 공식)** | [Jira 작업 유형·계층](https://support.atlassian.com/jira-cloud-administration/docs/what-are-issue-types/) · [Atlassian Epics, stories, initiatives](https://www.atlassian.com/agile/project-management/epics-stories-themes) · [Azure Boards 작업 항목](https://learn.microsoft.com/en-us/azure/devops/boards/work-items/about-work-items?view=azure-devops) · [Area·Iteration paths](https://learn.microsoft.com/en-us/azure/devops/organizations/settings/about-areas-iterations?view=azure-devops) · [Linear Concepts](https://linear.app/docs/conceptual-model) |
| **1차(프레임워크 공식)** | [SAFe Epic](https://framework.scaledagile.com/epic) · [SAFe Portfolio Backlog](https://framework.scaledagile.com/portfolio-backlog) |
| **1차(원저자·문헌)** | [Bill Wake, INVEST / SMART](https://xp123.com/invest-in-good-stories-and-smart-tasks/) · [Fowler, Strangler Fig](https://martinfowler.com/bliki/StranglerFigApplication.html) · [Cohn, SPIDR](https://www.mountaingoatsoftware.com/blog/five-simple-but-powerful-ways-to-split-user-stories) · [Cohn, Just in Time and Just Enough](https://www.mountaingoatsoftware.com/articles/writing-the-product-backlog-just-in-time-and-just-enough) · [Humanizing Work 분할 가이드](https://www.humanizingwork.com/the-humanizing-work-guide-to-splitting-user-stories/) · [Humanizing Work, Detail Trap](https://www.humanizingwork.com/avoiding-the-detail-trap/) |
| **1차(벤더 기술블로그)** | [Thoughtworks, A tale of epic confusion](https://www.thoughtworks.com/insights/blog/user-stories-tale-epic-confusion) — Cohn 원저를 인용해 epic의 원 정의를 복원한다 |
| 2차 | 안티패턴 6건(thoughtbot, sorryengineering, Atlassian Community 기고, Medium 2건, Jeremy Jarrell) · Jira Component 대조(커뮤니티 다수) · epic 기간 실무 가이드 4건 · Jira issue type 변환의 부작용(커뮤니티·이슈 트래커) · 백로그 상세화 깊이 가이드 3건 |
