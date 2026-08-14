# 훅이 스킬 frontmatter를 읽는 경로 — 실측

**최초 작성**: 2026-08-03
**최종 수정**: 2026-08-09
**대상 프로젝트**: grid fin (신규 개인용 개발 하네스)
**조사 계기**: [언어·플랫폼별 검사 분기 조사](per-language-check-divergence.md)가 *"층 A(서술자)는 스킬로 표현 가능하지만 층 B(판정·차단)는 훅이어야 한다"* 로 갈렸고, **그 두 층을 잇는 경로가 실제로 성립하는지** 사용자가 실측을 요청했다
**성격**: 실측. **설계 결정은 하지 않는다.**
**측정 환경**: Claude Code 2.1.220 / darwin 25.5.0 / 격리 프로브 저장소(스크래치패드). **사용자 저장소의 `.claude/`는 건드리지 않았다**

선행 문서
- [per-language-check-divergence.md](per-language-check-divergence.md) — 어댑터 5필드, 부재 3종, `project` 모드
- [repository-layout.md](repository-layout.md) §8.3·§9.1 — `settings.json` 비상속 실측
- [enforcement-mechanisms.md](enforcement-mechanisms.md) — `PostToolUse`는 exit 2로도 차단 불가

---

## 0. 결과 요약

**실세션 4회 + 합성 재생 14회.** 규격으로 이미 알던 것(입력 필드 존재, 종료 코드 의미, 600초 기본 타임아웃)은 지나가며 확인만 하고, **자료로 답이 나오지 않던 것만 쟀다.**

| # | 측정 | 결과 | 판정 |
|---|---|---|---|
| **M1** | `PreToolUse`·`PostToolUse`가 `Write`에 발화하는가 | **둘 다 발화**. Write 1회에 각 1회, 순서는 Pre → Post | ✅ |
| **M2** | 훅이 **대상 파일 경로**를 받는가 | **`tool_input.file_path`가 절대 경로로 온다.** 언어 라우팅의 전제가 성립한다 | ✅ |
| **M3** | 루트에서 세션 시작 시 `.claude/skills/*/SKILL.md` 상대 glob이 닿는가 | **닿는다** — 상대 4건 / `$CLAUDE_PROJECT_DIR` 기준 4건, `cwd`와 `CLAUDE_PROJECT_DIR`가 모두 루트 | ✅ |
| **M4** | 하위 디렉터리에서 세션 시작 (설정은 루트에만) | **훅이 발화하지 않는다 — 0회.** 파일은 정상적으로 쓰였다 | ❌ |
| **M5** | 하위 디렉터리에 자체 `settings.json`을 두면 | 발화하지만 **`CLAUDE_PROJECT_DIR`가 하위를 가리킨다.** 상대 glob 0건 / CPD glob 0건 — **레지스트리에 닿지 못한다** | ❌ |
| **M6** | YAML 의존성 없이 frontmatter를 파싱할 수 있는가 | **된다** — `awk`로 블록 추출 + `sed`로 `capabilities: [a, b]` 파싱 | ✅ |
| **M7** | block-style YAML(`- a` 줄바꿈 나열)은 | **조용히 누락된다.** `AMBIGUOUS`가 나와야 할 상황에서 `ROUTED`가 나왔다 | ⚠️ |
| **M8** | 부재 3종(ⓐ무의미·ⓑ미설치·ⓒ대상0)이 훅 층에서 갈리는가 | **셋 다 갈린다.** 단 **ⓐ가 다시 두 종류로 쪼개지고 그것은 갈리지 않는다**(§3.2) | ⚠️ |
| **M9** | 같은 확장자에 어댑터가 둘이면 | **`AMBIGUOUS n=2`로 감지된다.** 검색 어댑터에서는 이득인 상황이 검사에서는 오류다 | ✅ |
| **M10** | 라우팅 지연 | 스킬 4종에 **평균 85ms**(10회 859ms). 훅 기본 타임아웃 600초 대비 무시 가능 | ✅ |
| **M11** | `deny` + `additionalContext`가 모델에 도달하는가 | **완전히 도달한다.** 모델이 두 문자열을 모두 인용했고 파일은 생성되지 않았다 | ✅ |
| **M12** | `PostToolUse` exit 2가 쓰기를 되돌리는가 | **되돌리지 않는다.** stderr는 모델에 전달되는데 **파일은 디스크에 남아 있다** | ❌ |
| **M13** | 훅 스크립트가 **위로 탐색**해 루트를 찾을 수 있는가 (§6.1) | **찾는다** — 2홉, `CPD` 기준 0건 → `ROOT` 기준 4건. **단 M4를 고치지는 못하고, 스크립트 파일도 디렉터리마다 필요하다** | ⚠️ |
| **M14** | `command`가 가리키는 훅 스크립트가 없으면 (§6.1 T1) | **조용히 통과한다** — 로그·경고 없이 파일이 쓰인다. fail-open 계보 **여섯 번째** | ❌ |
| **M15** | 루트에 마커가 없으면 탐색이 (§6.1 T4-b) | **프로젝트 밖으로 샌다.** 상위 `.git`을 잡고 `skills_from_ROOT=0` → 라우터에는 **ⓐ 어댑터 없음**으로 보인다 | ❌ |
| **M16** | `bypassPermissions`에서 `deny`가 우회되는가 (§6.2) | **우회되지 않는다.** `default`·`acceptEdits` 포함 **3개 모드 전부 게이트 유지** | ✅ |
| **M17** | `additionalContext`의 지시를 모델이 따르는가 (§6.3) | **자율 판단에서 거부한 사례가 나왔다** — 훅의 주장을 저장소에 대조해 반증하고 **인젝션으로 의심**했다. **차단은 유효, 지시 수용은 별개** | ⚠️ |

> **핵심 결론 두 개.**
>
> **(1) 경로 자체는 성립한다.** 훅은 대상 파일 경로를 받고(M2), 스킬 frontmatter를 YAML 의존성 없이 읽고(M6), 어댑터를 고르고(M8·M9), 차단하며 이유를 모델에 전달한다(M11). **85ms다**(M10).
>
> **(2) 그러나 성립하는 조건이 좁고, 두 군데가 구조적으로 막힌다.**
> - **모노레포에서 무너진다**(M4·M5) — 하위에서 세션을 시작하면 훅이 없거나, 있어도 레지스트리를 못 찾는다. **상향 탐색이 후자를 고치지만 전자는 고치지 못한다**(M13)
> - **타이밍이 어긋난다**(M12·§4) — 차단할 수 있는 이벤트는 너무 이르고, 시점이 맞는 이벤트는 차단하지 못한다
>
> **(3) 반면 권한 모드는 위협이 아니다**(M16) — `bypassPermissions`에서도 `deny`가 이긴다. **차단력 자체는 튼튼하고, 약한 곳은 배선(M4·M14·M15)과 시점(M12)이다.**

---

## 1. 무엇을 재고 무엇을 재지 않았는가

[공식 훅 문서](https://code.claude.com/docs/en/hooks)가 이미 규정하는 것은 **재지 않고 캡처 페이로드에서 확인만 했다** — `cwd` 필드 존재, `permissionDecision` 값 집합, exit 0/2/기타의 의미, `command` 훅 기본 타임아웃 600초, `${CLAUDE_PROJECT_DIR}` 존재.

**잰 것은 자료가 답하지 않는 둘이다.**

1. **훅이 대상 파일을 아는가** — 문서의 `tool_input` 예시는 Bash(`{"command": ...}`) 하나뿐이라 `Write`/`Edit`의 모양이 나와 있지 않다. 이것이 실패하면 **언어별 라우팅이 훅 층에서 불가능**하고 층 B는 다른 기제를 찾아야 한다
2. **모노레포에서 레지스트리 경로가 유지되는가** — `skill-registry`의 Discovery Procedure는 `.claude/skills/*/SKILL.md`를 **상대 경로로** Glob한다. 문서의 `cwd` 정의는 *"현재 작업 디렉터리"* 이지 프로젝트 루트가 아니다

---

## 2. 실세션 측정

### 2.1 프로브 저장소

```
probe/
├── .claude/
│   ├── settings.json              # PreToolUse + PostToolUse, matcher "Write|Edit"
│   ├── hooks/capture.sh           # stdin 전량 + pwd + $CLAUDE_PROJECT_DIR + glob 히트수 기록
│   └── skills/
│       ├── adapter-cycles-ts/     # capabilities: [analysis, cycles, typescript]
│       ├── adapter-cycles-py/     # capabilities: [analysis, cycles, python]
│       ├── adapter-cov-go/        # capabilities: [coverage, go]
│       └── wf-something/          # capabilities 키 없음 (skip silently 검증용)
└── packages/{web,api,svc}/src/
```

어댑터 스킬의 frontmatter에 조사 §9의 5필드 중 넷을 넣었다 — `capabilities`(적용 대상) · `check_cmd` · `check_mode`(file/list_of_files/**project**) · `applies_to_ext`.

### 2.2 M1·M2·M3 — 루트에서 시작

`claude -p "packages/web/src/a.ts 파일을 만들고 …"` (모델 haiku, `--permission-mode acceptEdits`).

**훅이 2회 발화했다** — `PreToolUse`, 이어서 `PostToolUse`.

```json
{"session_id":"82423a26-…","transcript_path":"…","cwd":"…/probe",
 "prompt_id":"50ac369a-…","permission_mode":"acceptEdits",
 "hook_event_name":"PreToolUse","tool_name":"Write",
 "tool_input":{"file_path":"…/probe/packages/web/src/a.ts","content":"export const a = 1;"},
 "tool_use_id":"toolu_017n2E…"}
```

| 항목 | 값 |
|---|---|
| **`tool_input.file_path`** | **절대 경로.** 이것이 M2의 답이다 |
| `tool_input.content` | **쓰려는 내용이 통째로 온다** — 디스크에 반영되기 전에 |
| `pwd`(명령) / `$PWD` / `$CLAUDE_PROJECT_DIR` | **셋 다 `…/probe`** |
| 상대 glob `.claude/skills/*/SKILL.md` | **4건** |
| `$CLAUDE_PROJECT_DIR` 기준 glob | **4건** |

`PostToolUse` 페이로드는 여기에 **`tool_response`** 가 추가된다 — `{"type":"create","filePath":…,"content":…,"structuredPatch":[],"originalFile":null,"userModified":false}` 와 `duration_ms: 2`.

> **`content`가 `PreToolUse`에 온다는 점이 §4의 논의에 직접 걸린다.** 훅은 "쓰기 전 상태 + 쓰려는 내용"을 알 수 있다. **파일 하나의 내용에 대한 검사라면 사전 차단이 가능하다.**

### 2.3 M4 — 하위 디렉터리에서 시작, 설정은 루트에만

`packages/web`에서 세션을 시작해 `src/b.ts`를 쓰게 했다.

| 결과 | |
|---|---|
| 파일 생성 | **성공** |
| **훅 발화** | **0회** |

**[repository-layout §8.3·§9.1](repository-layout.md)의 `settings.json` 비상속이 훅 층에서 그대로 재현됐다.** 게이트가 조용히 사라지고 작업은 정상 완료된다 — [검사 분기 조사 §7](per-language-check-divergence.md)의 fail-open이 **네 번째 층에서** 나타난 것이다.

> **2026-08-09 보강 — 같은 조건에서 스킬은 상속된다. 그래서 M4는 생각보다 나쁘다.**
>
> 이 절은 **훅만** 쟀다. 같은 형태(루트에만 `.claude/`, 하위에서 세션 시작)로 **스킬 가시성**을 재니 **루트와 하위 모두에서 보였다** (**1차 실측**, 2026-08-09 · Claude Code 2.1.226 · `claude -p`로 스킬 목록 확인).
>
> **훅과 스킬의 로드 규칙이 다르다.** 그래서 하위 디렉터리 세션은 **「하네스가 없는 상태」가 아니라 「명령은 다 있고 강제만 없는 상태」**가 된다 — `permissions.deny`도 같은 파일에 실리므로 함께 사라진다. **바깥에서 보면 정상 동작과 구분되지 않는다.**
>
> **그리고 이것을 막을 훅이 바로 그 훅이다** — 「루트에서 시작하라」를 강제할 자연 기제가 없다. 이 저장소는 이 위험을 **규약으로 두고 대가를 명시하는 쪽**으로 정했다([미결 원장 S10](../draft/open-questions.md)).
>
> **`settings.local.json`도 M4를 고치지 못한다** — 공식 문서의 위치 독립성 서술이 실측으로 반증됐다([repository-layout §10.2 정정](repository-layout.md)).

### 2.4 M5 — 하위에 자체 `settings.json`을 두면

`packages/web/.claude/settings.json`에 훅을 등록하고(스크립트는 루트의 것을 절대 경로로 참조) 다시 실행했다.

| 항목 | 값 |
|---|---|
| 훅 발화 | **1회** ✅ |
| `pwd` | `…/probe/packages/web` |
| **`$CLAUDE_PROJECT_DIR`** | **`…/probe/packages/web`** ← 루트가 아니다 |
| 상대 glob | **0건** |
| **`$CLAUDE_PROJECT_DIR` 기준 glob** | **0건** |

> **`$CLAUDE_PROJECT_DIR`는 세션 시작 위치를 가리킨다.** 상대 glob 문제를 환경변수가 구해주지 않는다 — **둘 다 0이다.**
>
> **따라서 모노레포에서 레지스트리 패턴을 쓰려면 셋 중 하나를 해야 한다.**
>
> | | 방법 | 비용 |
> |---|---|---|
> | ① | 세션을 항상 루트에서 시작한다 | **강제 수단이 없다** |
> | ② | 하위 패키지마다 `settings.json`을 두고 루트 skills를 절대 경로로 참조한다 | **M4 때문에 "세션이 시작될 수 있는 모든 디렉터리마다" 파일이 필요하다** — 절대 경로로 인한 이식성 상실은 그다음 문제다 |
> | ③ | 훅 스크립트가 `.git`·워크스페이스 마커를 **위로 탐색**해 루트를 스스로 찾는다 | **§6.1에서 측정함** — 탐색은 성립하나 **②의 비용을 없애주지는 않는다** |
>
> **②의 비용을 M4가 결정한다** — 하위에 설정이 없으면 훅이 **아예 발화하지 않으므로**, 빠뜨린 디렉터리는 게이트가 없는 채로 조용히 통과한다.
>
> **③은 ②를 대체하지 않고 보완한다**(§6.1) — 설정 파일은 여전히 디렉터리마다 필요하고, **훅 스크립트 파일까지 필요하다.** ③이 없애는 것은 *경로 하드코딩*뿐이다.

### 2.5 M11 — 차단과 컨텍스트 전달

`PreToolUse`가 다음을 반환하도록 했다.

```json
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny",
 "permissionDecisionReason":"ADAPTER_GATE: adapter-cycles-ts가 순환 참조를 보고했다",
 "additionalContext":"… 순환 경로는 src/a.ts -> src/b.ts -> src/a.ts 이다. 먼저 이 순환을 끊어라."}}
```

**모델의 응답이 둘 다 인용했다:**

> **오류 메시지:** `ADAPTER_GATE: adapter-cycles-ts가 순환 참조를 보고했다`
> **추가 지시:** `순환 경로는 src/a.ts -> src/b.ts -> src/a.ts 이다. 먼저 이 순환을 끊어라.`

**그리고 파일은 생성되지 않았다.**

> **[구조 항해 조사 §4.4](structural-navigation.md)가 규격으로만 확인했던 *"막고 무엇을 먼저 하라고 알리는"* 형태가 실제로 동작한다.** 어댑터 이름·검사 결과·다음 행동을 한 번에 전달할 수 있다.

---

## 3. 합성 재생 — 라우터 판정

캡처한 페이로드의 `file_path`만 바꿔 라우터 스크립트에 파이프했다. **추가 API 호출 없이 14케이스.**

라우터는 ① `file_path` → 확장자 ② 스킬 frontmatter 전수 파싱 ③ `capabilities` AND 필터(`analysis` + `cycles`) + `applies_to_ext` 매칭 ④ 부재 판별 순으로 동작한다.

### 3.1 판정 결과

| 입력 | 출력 |
|---|---|
| `.ts` (도구 없음) | `ABSENT_B_tool_missing adapter=adapter-cycles-ts bin=depcruise` |
| `.py` (도구 없음) | `ABSENT_B_tool_missing adapter=adapter-cycles-py bin=lint-imports` |
| `.go` | `ABSENT_A_no_adapter ext=.go` |
| `.rs` | `ABSENT_A_no_adapter ext=.rs` |
| `.ts` (도구 있음, 대상 3개) | **`ROUTED adapter=adapter-cycles-ts mode=project cmd=[depcruise …] targets=3`** |
| `.tsx` (어댑터 매칭, 대상 0) | `ABSENT_C_no_targets adapter=adapter-cycles-ts` |
| `.ts` + 같은 확장자 어댑터 2개 | **`AMBIGUOUS n=2 [adapter-cycles-ts adapter-cycles-ts2]`** |

**`capabilities` 키가 없는 `wf-something`은 전 케이스에서 조용히 건너뛰어졌다** — `skill-registry`의 Missing Capabilities Handling 규칙대로다.

### 3.2 ⓐ가 다시 갈리고, 그것은 구분되지 않는다

`.go`와 `.rs`가 **같은 `ABSENT_A_no_adapter`** 를 냈다. **그런데 의미가 다르다.**

| | 의미 | 올바른 처리 |
|---|---|---|
| `.go` | **Go는 패키지 순환을 툴체인이 거부한다**([검사 분기 §1.1](per-language-check-divergence.md)) — 어댑터가 없는 것이 **정상**이다 | 통과 |
| `.rs` | 크레이트 순환은 Cargo가 잡지만 **모듈 순환은 잡지 않는다** — 어댑터가 **아직 없는** 것일 수 있다 | 결손 보고 |

**라우터는 둘을 구분할 수 없다. 부재를 선언하는 칸이 어디에도 없기 때문이다.** [검사 분기 조사 §10 열린 질문 1](per-language-check-divergence.md)이 *"이 조사가 찾은 어느 제품도 '이 언어에는 이 검사가 존재하지 않는다'를 명시적으로 선언하는 필드를 갖지 않는다"* 로 남긴 것이 **실측에서 그대로 재현됐다.**

> **해소 방향은 단순하다** — "검사 불필요"를 선언하는 어댑터(`capabilities: [analysis, cycles, go]` + `absent_reason: enforced-by-toolchain`)를 두면 ⓐ가 갈린다. **이 조사는 그것을 검증하지 않았다.**

### 3.3 M7 — 파싱 실패가 오류가 아니라 누락으로 나타난다

`capabilities`를 block sequence로 쓴 어댑터를 추가했다.

```yaml
capabilities:
  - analysis
  - cycles
  - typescript
```

`.ts`로 라우팅하면 **`AMBIGUOUS n=2`가 나와야 한다**(기존 ts 어댑터 + 이것). 실제 출력:

```
ROUTED adapter=adapter-cycles-ts mode=project cmd=[depcruise …] targets=3
```

**block-style 어댑터가 존재하지 않는 것처럼 처리됐다.** 정규식 파서가 flow-style(`[a, b]`)만 인식하기 때문이다.

> **이것이 이 실측에서 가장 걱정스러운 결과다.** 파싱 실패가 **에러가 아니라 조용한 누락**이고, `skill-registry`의 *"capabilities 키가 없으면 skip silently"* 규칙과 **결합하면 구분이 불가능해진다** — 의도적 미태깅과 파싱 실패가 훅 층에서 같은 모양이다. 그리고 이 문서 §0의 fail-open 계보에 **다섯 번째 항목**이 된다.
>
> **완화는 둘이다**: 파서를 block sequence까지 지원하게 하거나(간단하다), **`capabilities` 키는 있는데 파싱이 실패한 경우를 별도 신호로 낸다.** 후자가 본질적이다 — 어떤 파서를 쓰든 미지원 문법은 남는다.

### 3.4 M10 — 지연

스킬 4종 전수 파싱 + 매칭 + 부재 판별을 **10회 돌려 859ms, 평균 85ms.**

`command` 훅의 기본 타임아웃은 600초이므로 여유가 크다. **다만 이것은 라우팅까지의 비용이고, 실제 검사(`depcruise` 등) 실행 시간은 포함하지 않는다** — `project` 모드 검사는 그보다 훨씬 비싸다.

---

## 4. 타이밍 모순 — 이 실측의 구조적 발견

**`project` 모드 검사는 파일이 새 상태여야 한다.** 순환 그래프도 커버리지도 저장소 전체를 본다([검사 분기 §3.1](per-language-check-divergence.md)).

| 이벤트 | 시점 | 차단 가능 |
|---|---|---|
| **`PreToolUse`** | 쓰기 **전** — 검사 대상이 아직 옛 상태 | **가능**(M11 실증) |
| **`PostToolUse`** | 쓰기 **후** — 검사에 맞는 시점 | **불가**(M12 실증) |

### 4.1 M12 — `PostToolUse` exit 2의 실제 동작

`PostToolUse`가 stderr에 메시지를 쓰고 **exit 2**로 종료하게 했다.

**모델의 보고:**
> *"쓰기 후 검사에서 순환이 감지되어 변경이 거부됐습니다."*

**디스크 상태:**
```
파일 존재: 남아 있음 → 되돌려지지 않았다
export const p = 5;
```

> **잰 것은 둘이다** — stderr가 모델에 전달되고(규격대로다), **파일은 되돌려지지 않는다.** [강제 메커니즘 조사](enforcement-mechanisms.md)가 *"`PostToolUse`는 exit 2로도 차단 불가"* 로 규격에서 읽은 것의 실측 확인이다.
>
> **재지 않은 것을 분명히 해 둔다.** 위 응답은 *"결과만 한 줄로 보고하고 재시도하지 마라"* 라는 지시 아래 나온 것이므로, **모델이 롤백을 실제로 가정하고 다음 행동을 정하는지는 이 실측이 보이지 않는다.** 다만 **거부 메시지와 디스크 상태가 어긋난다는 사실 자체는 [상태·연속성 조사](state-and-continuity.md)가 다룬 상태 발산의 재료이며**, 게이트를 여기에 두면 감수해야 할 위험으로 기록해 둔다.

### 4.2 `PreToolUse`로 흉내낼 수 있는가 — 부분적으로만

`PreToolUse`는 **`tool_input.content`를 받는다**(§2.2). 즉 "현재 디스크 상태 + 쓰려는 내용"으로 검사를 **미리 돌릴 수는 있다.**

**단일 파일 내부 검사에는 충분하다.** 그러나 `project` 모드에는 두 군데가 막힌다.

1. **검사 도구는 디스크를 읽는다.** 제안된 내용을 반영하려면 **임시 오버레이 트리를 만들어 거기서 도구를 돌려야 한다.** 워크스페이스 전체를 복제하는 비용이고, 상대 경로·설정 파일 탐색이 전부 그 트리를 기준으로 다시 풀려야 한다
2. **`Write` 하나가 순환을 만드는 경우가 전부가 아니다.** 순환은 대개 **여러 파일의 조합**으로 생기고, 마지막 쓰기 직전 상태에서는 아직 순환이 없을 수 있다

> **따라서 세 선택지만 남는다.** ① `PreToolUse`에서 오버레이를 만들어 사전 검사(비싸고 부분적) ② `PostToolUse`에서 검사하고 **차단 대신 `additionalContext`로 알린다**(게이트가 아니라 지시가 된다 — [강제 메커니즘 조사](enforcement-mechanisms.md)의 지적 163건 중 78.5% 미조치가 여기 걸린다) ③ **파일 단위가 아닌 다른 경계에 건다** — `Stop` 훅이나 커밋 훅. **[평가 조사](evaluation.md)가 확인한 대로 이 하네스의 검증 단위는 이미 머지 커밋이다.**
>
> **이 조사는 세 선택지의 비용을 재지 않았다.**

---

## 5. 검색 어댑터 패턴과의 대조 — 실측이 확인한 것

| 요소 | search-adapter | 검사 어댑터 (실측) |
|---|---|---|
| 어댑터 선택 | 아무거나 / 여럿이면 **전부 쓰고 병합** | **target이 결정**. 여럿이면 **오류**(M9의 `AMBIGUOUS`) |
| 활성 조건 | 환경변수 유무 | **파일 확장자 매칭** — 훅에서 성립(M2·M8) |
| 소비자 | 모델이 절차를 읽고 실행 | **훅이 frontmatter를 파싱** — 성립하되 파서 한계가 조용하다(M7) |
| 실패 처리 | 키 없으면 abort 1종 | **부재 3종 + ⓐ의 하위 2종** — 마지막이 구분 안 됨(§3.2) |
| 성립 범위 | 어디서 실행하든 동일 | **세션 시작 위치에 종속**(M4·M5) |
| 결과 | 검색은 실패해도 "못 찾음" | **차단이 목적인데 시점이 어긋난다**(§4) |

> **패턴 자체는 옮겨진다.** 레지스트리의 AND 필터, `capabilities` 태그, skip-silently 규칙이 전부 훅 층에서 동작했다.
>
> **옮겨지지 않는 것은 "교환 가능성"이라는 전제 하나다.** 그리고 그 하나가 선택 정책·실패 처리·모호성 판정을 전부 다시 쓰게 만든다.

### 5.1 기록해 둘 것 — 스킬 파일의 이중 역할

훅이 `SKILL.md` frontmatter를 읽는 순간, 그 파일은 **두 가지 일을 동시에 한다**: 모델이 읽는 산문이고, 결정론적 코드가 파싱하는 설정이다.

**그리고 둘이 일치하는지 검증하는 것은 아무것도 없다.** frontmatter의 `check_cmd`가 바뀌어도 본문의 서술은 그대로일 수 있고, 그 반대도 마찬가지다. [저장소 위생 조사](repository-hygiene.md)가 확인한 *"ADR은 형식만 표준이고 기계 소비용 파서가 0종"* 과 정확히 반대 방향의 문제다 — 여기서는 **기계가 소비하는데 사람용 서술과의 정합을 아무도 안 본다.**

이것이 이 패턴의 우아한 지점인지 실패 모드인지는 이 실측이 판정하지 않는다. **다만 결정 시점에 반드시 다뤄야 할 축이다.**

---

## 6. 후속 실측 — 열린 질문 1·8을 닫는다

사용자 요청으로 두 질문을 추가 측정했다. **실세션 4회 + 합성 2케이스.**

### 6.1 상향 탐색(§2.4 ③)은 성립하지만 단일 지점 수정이 아니다

| # | 조건 | 결과 |
|---|---|---|
| **T1** | 하위에 `settings.json`은 두되 **훅 스크립트 파일은 두지 않음**(`command`가 `${CLAUDE_PROJECT_DIR}/.claude/hooks/resolve.sh`) | **로그 0건, 파일 생성됨, 출력에 경고 없음** |
| **T2** | 하위에 스크립트까지 복사 | **탐색 성공** — `MARKER=pnpm-workspace.yaml`, `HOPS=2`, `skills_from_CPD=0` → **`skills_from_ROOT=4`** |
| **T4-a** | 루트에 마커 있음(합성) | 위와 동일, 루트를 정확히 찾음 |
| **T4-b** | **루트의 마커를 전부 제거**하고 프로젝트 **밖**에 `.git`을 심음(합성) | **`ROOT`가 프로젝트 밖으로 새고** `MARKER=.git`, `HOPS=3`, **`skills_from_ROOT=0`** |

**T2가 §2.4 ③의 핵심을 확인한다** — `$CLAUDE_PROJECT_DIR`가 하위를 가리켜도 훅 스크립트가 마커를 위로 찾으면 루트 레지스트리에 닿는다. **글로벌 경로를 하드코딩하지 않아도 된다.**

**그러나 나머지 셋이 "단일 지점 수정"이라는 기대를 깎는다.**

1. **M4는 고쳐지지 않는다.** 상향 탐색은 훅이 *발화한 뒤*의 문제만 푼다. 세션이 시작될 수 있는 디렉터리마다 `settings.json`은 여전히 필요하다
2. **T1 — 스크립트 파일도 디렉터리마다 필요하고, 없으면 조용히 통과한다.** `command`가 `$CLAUDE_PROJECT_DIR` 기준이므로 하위에서 시작하면 하위에서 스크립트를 찾는다. 없으면 훅은 non-blocking error로 처리되고 **로그도 경고도 남지 않은 채 쓰기가 완료된다.** 이 시리즈 fail-open 계보의 **여섯 번째**이며, 앞선 다섯과 달리 **설정을 옳게 해도 파일 하나를 빠뜨리면 발생한다**
3. **T4-b — 탐색이 프로젝트 밖으로 샌다.** 루트에 마커가 없으면 상위의 아무 `.git`이나 잡고, **틀린 루트를 자신 있게 반환한다.** 그 결과는 `skills_from_ROOT=0`, 즉 라우터에게 **"어댑터 없음"(ⓐ)** 으로 보인다 — §3.2가 이미 갈리지 않는다고 밝힌 바로 그 값이다

> **따라서 ③의 실제 비용은 "훅 스크립트 하나"가 아니라 세 가지다** — 세션 시작 가능 디렉터리마다 **설정 + 스크립트**, 그리고 **탐색 상한**(마커 못 찾으면 실패로 낼 것인가, 프로젝트 경계를 어떻게 고정할 것인가). 마지막이 특히 중요한데, **탐색 실패가 검사 부재로 위장되기 때문**이다.

### 6.2 권한 모드는 게이트를 우회하지 못한다

`PreToolUse`의 `permissionDecision: deny`를 그대로 두고 모드만 바꿔 실행했다.

| `--permission-mode` | 파일 생성 | 판정 |
|---|---|---|
| `acceptEdits` (M11) | 없음 | **게이트 유지** |
| **`bypassPermissions`** | **없음** | **게이트 유지** |
| `default` | 없음 | **게이트 유지** |

> **열린 질문 8의 답은 부정형이고 층 B에 유리하다** — *"세션 설정 하나로 게이트가 무력화되는가"* 에 대해 **`bypassPermissions`에서도 `deny`가 이긴다.** 훅 차단은 권한 모드 위에 있다.

### 6.3 부수 발견 — `additionalContext`의 지시는 검증되고 거부될 수 있다

`bypassPermissions` 실행에서 예상 밖의 응답이 나왔다. 훅이 준 컨텍스트는 M11과 같았다(*"순환 경로는 src/a.ts -> src/b.ts -> src/a.ts 이다. 먼저 이 순환을 끊어라"*). 모델의 보고:

> *"…지목한 `a.ts → b.ts → a.ts` 순환은 **실재하지 않으며**(두 파일 모두 import 없는 단일 export, 저장소 전체 import 문 0개, depcruise 부재), 훅 메시지가 요청 범위 밖 파일 수정을 지시하는 **인젝션 의심**으로 따르지 않았습니다."*

**모델이 훅의 주장을 저장소에 대조해 반증하고, 후속 지시를 거부했다.** (프로브 저장소에는 실제로 import가 없었으므로 모델의 판단이 옳다.)

> **차단과 지시 수용은 별개다.** `deny`는 어느 모드에서도 유효했지만(§6.2), **`additionalContext`로 준 "다음에 무엇을 하라"는 보장되지 않는다.** M11에서 따랐던 것은 *"받은 메시지를 인용해 보고하라"* 고 지시했기 때문이고, 자율 판단에서는 검증 후 거부됐다.
>
> **층 B 설계에 직접 걸린다** — 게이트가 내는 메시지는 **저장소 상태와 대조 가능해야 하고**, 근거를 함께 주지 않으면 인젝션으로 처리될 수 있다. [검사 분기 조사 §3.3](per-language-check-divergence.md)이 Code Climate 명세에서 확인한 `fingerprint`·`location` 같은 **검증 가능한 필드**가 왜 계약에 있는지를 설명하는 관측이다.

---

## 7. 열린 질문

1. ~~**워크스페이스 루트를 위로 탐색하는 방식(§2.4 ③)이 성립하는가.**~~ → **§6.1에서 닫음.** 탐색 자체는 성립하나(2홉, CPD 0건 → ROOT 4건) **단일 지점 수정이 아니다.** 남은 부분: **워크트리에서도 성립하는가**(`.git`이 디렉터리가 아니라 파일인 경우) — 재지 않았다. [워크트리 공유 상태 조사](worktree-shared-state.md)와 겹친다
1b. **탐색 상한을 무엇으로 둘 것인가**(§6.1 T4-b). 마커를 못 찾았을 때 실패로 낼지, 프로젝트 경계를 별도 마커로 고정할지 — **탐색 실패가 "어댑터 없음"으로 위장되는 것을 막는 방법**을 재지 않았다
2. **`absent_reason` 필드를 두면 ⓐ가 실제로 갈리는가**(§3.2). 방향만 적었고 검증하지 않았다
3. **`PreToolUse` 오버레이 사전 검사의 비용**(§4.2 ①). 워크스페이스 복제 시간과 도구의 상대 경로 해석이 실제로 성립하는지 미측정
4. **`Stop` 훅 또는 커밋 경계에 거는 방식**(§4.2 ③)의 지연과 차단력. 이 조사는 `Write` 경계만 봤다
5. **여러 훅이 동시에 걸릴 때의 상호작용.** 이 프로브는 훅이 하나뿐이었다. 전역 설정에 이미 다른 훅들이 있는 실환경에서 판정이 어떻게 합쳐지는지 재지 않았다
6. **`Edit` 툴의 페이로드 모양.** `matcher`에 포함시켰으나 이번 세션들은 전부 `Write`만 발화했다 — `Edit`은 `content` 대신 `old_string`/`new_string`이 올 것이고, **그러면 §4.2의 "제안된 내용으로 검사"가 더 어려워진다**
7. **스킬 본문과 frontmatter의 정합 검증**(§5.1)
8. ~~**권한 모드에 따라 게이트가 우회되는가.**~~ → **§6.2에서 닫음.** `bypassPermissions`·`default`·`acceptEdits` **세 모드 모두에서 `deny`가 유효**했다
9. **`PostToolUse` 거부 메시지를 받은 모델이 실제로 어떻게 행동하는가**(§4.1). 롤백을 가정하는지, 재시도하는지, 무시하는지 — **지시로 억제하지 않은 조건에서 재지 않았다**
10. **게이트 메시지에 어떤 근거를 실어야 인젝션으로 처리되지 않는가**(§6.3). 모델이 훅의 주장을 저장소에 대조해 반증하고 거부한 사례가 1건 나왔다. **`fingerprint`·`location` 같은 검증 가능한 필드를 실으면 수용률이 달라지는지 재지 않았다** — 표본 1건이므로 재현성도 미확인

---

## 부록 A — 재현

**사용자 저장소에는 아무것도 만들지 않는다.** 전부 스크래치패드에서 돈다.

```bash
P=$(mktemp -d)/probe
mkdir -p "$P"/.claude/{hooks,skills/adapter-cycles-ts} "$P"/packages/web/src

cat > "$P"/.claude/skills/adapter-cycles-ts/SKILL.md <<'EOF'
---
name: adapter-cycles-ts
capabilities: [analysis, cycles, typescript]
check_cmd: depcruise --config .dependency-cruiser.json --output-type err src
check_mode: project
applies_to_ext: .ts,.tsx,.js,.jsx
---
# adapter-cycles-ts
EOF

cat > "$P"/.claude/hooks/capture.sh <<'EOF'
#!/bin/bash
PAYLOAD=$(cat)
{ echo "PWD=$(pwd)"; echo "CPD=${CLAUDE_PROJECT_DIR:-<UNSET>}"
  echo "rel_glob=$(ls .claude/skills/*/SKILL.md 2>/dev/null | wc -l)"
  echo "cpd_glob=$(ls "${CLAUDE_PROJECT_DIR}"/.claude/skills/*/SKILL.md 2>/dev/null | wc -l)"
  echo "$PAYLOAD"; } >> /tmp/probe-capture.log
exit 0
EOF
chmod +x "$P"/.claude/hooks/capture.sh

cat > "$P"/.claude/settings.json <<'EOF'
{ "hooks": {
  "PreToolUse":  [{ "matcher": "Write|Edit", "hooks": [{ "type": "command",
     "command": "${CLAUDE_PROJECT_DIR}/.claude/hooks/capture.sh", "timeout": 20 }] }],
  "PostToolUse": [{ "matcher": "Write|Edit", "hooks": [{ "type": "command",
     "command": "${CLAUDE_PROJECT_DIR}/.claude/hooks/capture.sh", "timeout": 20 }] }] } }
EOF

# M1~M3 (루트에서)
(cd "$P" && claude -p "packages/web/src/a.ts 파일을 만들고 'export const a = 1;' 한 줄만 써라." \
   --permission-mode acceptEdits --model haiku)

# M4 (하위에서, 설정은 루트에만)  → 훅 발화 0회
(cd "$P/packages/web" && claude -p "src/b.ts 를 만들어라." --permission-mode acceptEdits --model haiku)
```

**M11 (`deny` + `additionalContext`)** — `PreToolUse` 훅을 아래로 바꾸고 실행:

```bash
cat >/dev/null
cat <<'JSON'
{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny",
"permissionDecisionReason":"ADAPTER_GATE: adapter-cycles-ts가 순환 참조를 보고했다",
"additionalContext":"순환 경로는 src/a.ts -> src/b.ts -> src/a.ts 이다. 먼저 이 순환을 끊어라."}}
JSON
exit 0
```

**M12 (`PostToolUse` exit 2)** — `PostToolUse` 훅을 `echo "..." >&2; exit 2` 로 두고 실행한 뒤 **파일이 남아 있는지 확인**한다.

---

## 부록 B — 라우터 스크립트

frontmatter를 YAML 의존성 없이 파싱하고 부재 3종을 가른다. **§3.3의 한계(block sequence 미지원)를 그대로 갖고 있다** — 실측한 그대로를 싣는다.

```bash
#!/bin/bash
PAYLOAD=$(cat)
ROOT="${CLAUDE_PROJECT_DIR:-$PWD}"
FP=$(printf '%s' "$PAYLOAD" | python3 -c 'import sys,json;print(json.load(sys.stdin).get("tool_input",{}).get("file_path",""))')
[ -z "$FP" ] && { echo "NO_FILE_PATH"; exit 0; }
EXT=".${FP##*.}"

MATCHED=""
for f in "$ROOT"/.claude/skills/*/SKILL.md; do
  [ -f "$f" ] || continue
  FM=$(awk 'NR==1&&/^---/{p=1;next} p&&/^---/{exit} p' "$f")
  CAPS=$(printf '%s' "$FM" | sed -n 's/^capabilities:[[:space:]]*\[\(.*\)\].*/\1/p' | tr -d ' ')
  [ -z "$CAPS" ] && continue                       # ← 미태깅과 파싱 실패가 여기서 같아진다 (§3.3)
  case ",$CAPS," in *",analysis,"*) ;; *) continue ;; esac
  case ",$CAPS," in *",cycles,"*)   ;; *) continue ;; esac
  EXTS=$(printf '%s' "$FM" | sed -n 's/^applies_to_ext:[[:space:]]*//p' | tr -d ' ')
  case ",$EXTS," in *",$EXT,"*) MATCHED="$MATCHED $(basename "$(dirname "$f")")" ;; esac
done
MATCHED=$(echo $MATCHED)

[ -z "$MATCHED" ] && { echo "ABSENT_A_no_adapter ext=$EXT"; exit 0; }
N=$(echo "$MATCHED" | wc -w | tr -d ' ')
[ "$N" -gt 1 ] && { echo "AMBIGUOUS n=$N [$MATCHED]"; exit 0; }

SKILL="$ROOT/.claude/skills/$MATCHED/SKILL.md"
CMD=$(awk 'NR==1&&/^---/{p=1;next} p&&/^---/{exit} p' "$SKILL" | sed -n 's/^check_cmd:[[:space:]]*//p')
command -v "${CMD%% *}" >/dev/null 2>&1 || { echo "ABSENT_B_tool_missing adapter=$MATCHED bin=${CMD%% *}"; exit 0; }
NFILES=$(find "$ROOT" -name "*$EXT" -not -path '*/node_modules/*' 2>/dev/null | wc -l | tr -d ' ')
[ "$NFILES" -eq 0 ] && { echo "ABSENT_C_no_targets adapter=$MATCHED"; exit 0; }
echo "ROUTED adapter=$MATCHED cmd=[$CMD] targets=$NFILES"
```

---

## 부록 C — 실행 기록

- **실세션 9회** — ① 루트 시작(M1·M2·M3) ② 하위 시작·설정 루트에만(M4) ③ 하위 시작·자체 설정(M5) ④ `deny`(M11) ⑤ `PostToolUse` exit 2(M12) ⑥ T1 스크립트 부재(M14) ⑦ T2 상향 탐색(M13) ⑧ `bypassPermissions`(M16·M17) ⑨ `default`(M16)
- **합성 재생 16케이스** — 확장자 4종 + ⓑ해소 + ⓒ + AMBIGUOUS + block-style + 지연 측정 10회(중복 포함) + T4-a·T4-b 경계 탐색 2건
- **§6의 후속 측정은 사용자 요청으로 추가된 것**이며, 그 전까지의 결론을 바꾼 곳은 §2.4 하나다(③이 단일 지점 수정이라는 서술을 정정했다)
- **모델**: 전 세션 haiku, `--permission-mode acceptEdits`
- **사용자 저장소 변경 없음** — 프로브 트리는 전부 스크래치패드에 있고, `/Users/mario/Workspace/grid-fin/.claude/`에는 `settings.json`을 만들지 않았다
- **측정 실패 없음.** 다만 `timeout` 명령이 macOS 기본 환경에 없어 첫 실행이 한 번 실패했고(재실행으로 해소), 헤드리스 실행마다 *"no stdin data received in 3s"* 경고가 났다 — 판정에는 영향 없다
