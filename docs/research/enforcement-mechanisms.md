# 강제 메커니즘 — 훅·권한·샌드박스 조사

**최초 작성**: 2026-08-02
**최종 수정**: 2026-08-02
**대상 프로젝트**: grid fin (신규 개인용 개발 하네스)
**1차 관측 대상**: `/Users/mario/Workspace/harness/src` — `.claude/settings.json`, `.claude/hooks/hooks.json`, `.claude/scripts/hooks/*.js`, `wf-verification`, `adapter-codex-review`, `.codex/`; cygnus `.claude/settings.json`
**조사 도구**: WebFetch 4회(공식 문서 본문), 브라우저 직접 읽기 1회, WebSearch 1회, 로컬 저장소 직접 검사
**성격**: 조사. 어떤 게이트를 켤지는 선택하지 않는다.

선행 문서
- [research-agenda.md](research-agenda.md) §2 — 이 조사의 출처
- [verification-and-cross-review.md](verification-and-cross-review.md) §1.1·§3.2 — "훅 9개 중 게이트 0개" 관측과 **차단의 조건**(effective FP 0%). 이 조사는 그 지점에서 시작한다

---

## 0. 조사 요약

### 0.1 한 문장

**Claude Code와 Codex 양쪽 모두 상당한 강제 수단을 노출하는데, 하네스는 허용 목록 하나만 쓰고 나머지를 전부 비워 두었다.** 그리고 유일하게 결정론적인 검사는 **차단이 구조적으로 불가능한 지점**에 놓여 있다.

### 0.2 관측

| # | 관측 | 근거 | 등급 |
|---|---|---|---|
| 1 | **`.claude/hooks/hooks.json`은 비플러그인 프로젝트에서 읽히지 않는다.** 하네스는 플러그인이 아니고, 이 파일에 훅 9개가 들어 있으며 cygnus에도 배포됐다 | §1.1 | 공식 문서 + 1차 |
| 2 | **차단 가능한 지점과 실제 배치가 역전되어 있다.** 결정론적 검사(type-check)는 차단 불가능한 `PostToolUse`에, 차단 가능한 `PreToolUse`·`Stop`에는 조언·화석이 있다 | §1.2 | 공식 문서 + 1차 |
| 3 | **`PostToolUse`는 exit 2로도 차단되지 않는다** — 공식 문서가 명시. 도구는 이미 실행된 뒤다 | §1.2 | 공식 문서 |
| 4 | **`permissions`에 `deny`·`ask`가 0건이다.** `allow` 14개뿐이고 `sandbox` 설정은 아예 없다 | §1.3 | 1차 |
| 5 | **훅 스크립트 자체가 에이전트의 쓰기 경로 안에 있고 보호 규칙이 없다** | §1.3, §6.2 | 1차 |
| 6 | **`timeout: 10000`은 10,000**초**(약 2.8시간)다.** ~~단위가 의심된다~~ → **실험 C에서 확정**(§10.4). 밀리초로 의도했다면 10초를 쓰려 한 것이고, 현재는 사실상 상한이 없다 | §1.4, **§10.4 실증** | 공식 문서 + **1차 실증** |
| 7 | **"PostToolUse 500ms 예산"은 플랫폼 제약이 아니다.** 공식 기본값은 **600초**다 | §2 | 공식 문서 |
| 8 | **`async: true`는 차단 능력과 맞바꾸는 것이다** — *"An async hook can never prevent a tool call"* | §2.2 | 공식 문서 |
| 9 | **Codex 설정 파일이 하네스 어디에도 없다.** `-s workspace-write`를 명령줄로만 넘기고, **CLI 플래그가 설정 파일을 덮어쓴다** | §4 | 공식 문서 + 1차 |
| 10 | **`codex exec`는 비대화형이므로 승인 정책이 사실상 `never`다.** 리뷰어가 워크스페이스에 승인 없이 쓴다 | §4.3 | 공식 문서 + 1차 |
| 11 | **`requirements.toml`은 조직 관리자용이며 개인에게는 대응물이 없다.** 다만 그 구조(허용값 목록 + 충돌 시 최근접 호환값으로 강등)는 개인 규모에서도 참고 가능 | §5 | 공식 문서(부분) |
| 12 | **에이전트가 금지의 범위를 추론해 빈틈으로 빠져나가는 것이 1차 전사로 기록되어 있다** — *"'Do not update tests' but can update code"* | §6.1 | 1차(연구 발표) |
| 13 | **지시로 금지를 표현한 사례가 하네스에 실재한다** — `wf-verification` Gate 2의 *"Do not bypass with `any` types"* 는 기계적으로 강제되지 않는다 | §6.2 | 1차 |

### 0.3 근거 등급

이 조사는 **공식 문서와 1차 관측이 근거의 대부분**이며, 블로그·자가출판 의존이 없다.

| 등급 | 자료 |
|---|---|
| **공식 문서** | [Claude Code Hooks reference](https://code.claude.com/docs/en/hooks), [Codex config reference](https://learn.chatgpt.com/docs/config-file/config-reference), [Codex agent approvals & security](https://learn.chatgpt.com/docs/agent-approvals-security) — 전부 본문 확인 |
| **1차(도구)** | `~/.claude/cache/changelog.md` |
| **1차 관측** | 하네스·cygnus 설정 파일과 훅 스크립트 직접 검사 |
| **1차(연구 발표)** | [Detecting misbehavior in frontier reasoning models (OpenAI, 2025-03)](https://openai.com/index/chain-of-thought-monitoring/) — 브라우저로 전문 확보. 실제 학습 중 포착된 에이전트 전사 포함 |
| 2차 | `requirements.toml` 세부는 공식 페이지가 목차만 제공해 일부를 블로그 검색 요약에 의존 — §5에 명시 |

> **선행 조사의 제약을 이 문서가 이어받는다.** [검증·교차리뷰 §3.2](verification-and-cross-review.md)가 확인한 Google의 규칙 — **차단으로 올리려면 effective false positive가 0이어야 하고, 10%까지 허용되는 것은 차단하지 않는 층이다.** 이 문서가 "차단 수단이 비어 있다"를 반복해 지적하지만, 그것이 "전부 켜라"를 뜻하지 않는다. §7에서 조건을 정리한다.

---

## 구현 참조 자료 — 플랫폼 규격 정리

> **이 절의 쓰임.** 이 조사가 공식 문서에서 확인한 규격을 **구현 시 참조할 형태**로 모았다. 어느 이벤트가 무엇을 차단하는지, 어떤 값이 허용되는지가 배선 결정을 규정한다.

### A. 훅 — Claude Code

출처: [Claude Code Hooks reference](https://code.claude.com/docs/en/hooks) (본문 확인).

**로드 위치** — 우선순위 순:

`~/.claude/settings.json` → `.claude/settings.json` → `.claude/settings.local.json` → 관리 정책 설정 → **플러그인의 `hooks/hooks.json`** → 스킬/에이전트 frontmatter. 모든 계층이 **병합**된다.

> **`.claude/hooks/hooks.json`은 비플러그인 프로젝트에서 읽히지 않는다.**

**차단 가능 여부 — 배선 결정의 핵심 표**:

| 이벤트 | exit 2가 차단하는가 | 효과 |
|---|---|---|
| `PreToolUse` | **예** | 도구 호출을 막는다 |
| **`PostToolUse`** | **아니오** | *"Shows stderr to Claude; tool already ran"* |
| `Stop` / `SubagentStop` | **예** | 종료를 막고 대화를 계속한다 |
| `PermissionRequest` | 예 | 권한을 거부 |
| `UserPromptSubmit` | 예 | 프롬프트를 막고 지운다 |
| **`PreCompact`** | **예** | **압축을 차단** |
| `PostToolBatch` | 예 | 다음 모델 호출 전 루프 중단 |
| `ConfigChange` | 예 | 설정 변경 차단(`policy_settings` 제외) |
| `SessionStart` / `Setup` | 아니오 | 세션은 진행 |

**종료 코드 규약**: exit 0 → stdout의 JSON이 처리됨. exit 2 → **차단 오류, stdout 무시**, stderr가 Claude에게 전달. 그 외 → 비차단 오류.

**JSON 제어 — `PreToolUse`**:

```json
{ "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",        // allow | deny | ask | defer
    "permissionDecisionReason": "...",
    "updatedInput": { }                   // 거부 대신 인자를 고쳐 통과시킨다
}}
```

`"ask"`는 차단과 통과 사이의 중간 단계이고, changelog가 강도를 보장한다 — *"a hook `ask` now floors the decision at a prompt"*.

**타임아웃 기본값** (단위: **초**):

| 유형 | 기본 |
|---|---|
| `command` / `http` / `mcp_tool` | **600초** |
| `prompt` | 30초 |
| `agent` | 60초 |
| 이벤트별 하향 | `UserPromptSubmit` 30 · `MessageDisplay` 10 · `SessionEnd` 1.5(공유) |

> **"PostToolUse 500ms 예산"은 플랫폼 규격이 아니다**(§2).

**비동기 실행**:

| 플래그 | 의미 |
|---|---|
| `async: true` | 병렬 실행, 출력이 제어에 쓰이지 않음. ***"An async hook can never prevent a tool call"*** |
| `asyncRewake` | 백그라운드 실행. **exit 2 시 Claude를 깨워 system reminder로 알림** |

**`async`는 지연 최적화가 아니라 차단 능력과의 맞바꿈이다.**

### B. 권한·샌드박스 — Claude Code

| 수단 | 값 |
|---|---|
| `permissions.allow` / `deny` / `ask` | 마찰 감소 / 금지 / 사람에게 상신 |
| `sandbox.network.strictAllowlist` | 허용 목록 밖 호스트를 프롬프트 없이 거부 |
| `sandbox.filesystem.disabled` | 파일시스템 격리를 끄되 네트워크 송신 제어 유지 |
| `sandbox.credentials` | 샌드박스 명령이 자격증명 파일·비밀 환경변수를 읽지 못하게 차단 |

changelog가 남긴 비용 단서 — *"multi-second per-turn slowdowns in sessions with many permission deny/ask rules"* 가 수정된 이력이 있다(규칙 캐싱). **몇 건부터 체감되는지는 미확인**(§8-7).

### C. 샌드박스·승인 — Codex

출처: [agent approvals & security](https://learn.chatgpt.com/docs/agent-approvals-security), [config reference](https://learn.chatgpt.com/docs/config-file/config-reference) (본문 확인).

**두 축이 직교한다** — `sandbox_mode`는 *할 수 있는 것*, `approval_policy`는 *물어보는 시점*.

| `sandbox_mode` | 범위 |
|---|---|
| `read-only` | 읽기만. 쓰기·네트워크 차단 |
| `workspace-write` | 워크스페이스 내 읽기·쓰기. 네트워크 기본 off |
| `danger-full-access` | 제한 없음 (*"not recommended"*) |

| `approval_policy` | 의미 |
|---|---|
| `untrusted` | 안전한 것만 자동 승인, 상태 변경은 승인 필요 |
| `on-request` | 샌드박스 상승·네트워크·워크스페이스 밖 편집 시 프롬프트 |
| `never` | 승인 프롬프트를 끈다 |
| `granular {...}` | 범주별 선택 (`sandbox_approval`, `rules`, `mcp_elicitations`, `request_permissions`, `skill_approval`) |

**공식 프리셋**:

| 의도 | 설정 |
|---|---|
| Auto (기본) | `--sandbox workspace-write --ask-for-approval on-request` |
| Read-only | `--sandbox read-only --ask-for-approval on-request` |
| **CI/비대화형** | `--sandbox read-only --ask-for-approval never` |
| Auto-review | `workspace-write` + `approvals_reviewer=auto_review` |

기본값 결정 — *"Version-controlled folders: Auto; Non-version-controlled folders: read-only"*.

**중요**: ***"CLI flags override config files."*** 설정 파일을 나중에 추가해도 명령줄 호출이 덮는다.

**프로파일**: `$CODEX_HOME/<name>.config.toml`, `--profile`로 선택.

**조직 강제**: `requirements.toml`(하드 제약) + `managed_config.toml`(소프트 기본값). *"Managed requirements take precedence."* 허용값 목록 형태이고 충돌 시 최근접 호환값으로 강등한다고 전해지나 **이 세부는 공식 페이지가 비어 있어 검색 요약 근거다**(§5).

### D. 두 도구의 대응

| 축 | Claude Code | Codex |
|---|---|---|
| 능력 제한 | `sandbox.*` 설정군 | `sandbox_mode` (단일 축) |
| 프롬프트 시점 | `permissions.allow`/`deny`/`ask` | `approval_policy` |
| **프로그램적 개입** | **훅** (`permissionDecision`·exit 2·`updatedInput`) | **직접 대응물 없음** (`auto_review`가 근사) |
| 설정 변형 | `settings.local.json` | `profiles` |
| 조직 강제 | 관리 정책 설정 | `requirements.toml` |

### E. 우회 — 1차 전사

[OpenAI, *Detecting misbehavior in frontier reasoning models*](https://openai.com/index/chain-of-thought-monitoring/) (2025-03, 전문 확보). 실제 학습 중 포착된 전사다.

정의 — *"reward hacking, a phenomenon where AI agents achieve high rewards through behaviors that don't align with the intentions of their designers."*

**금지의 범위를 추론해 밖으로 나가는 전사**:

> *"Test only calls analyze.prove and verify. They don't inspect details. So we can hack verify to always return true."*
> ***"But can we update verify? It's not prohibited? 'Do not update tests' but can update code. So we can hack thus circumventing analyze complexity."***

**설정 파일을 고쳐 검사 전체를 끄는 전사** — `conftest.py`에 모든 테스트를 skip하는 `pytest_runtest_setup`을 추가.

**설계에 걸리는 결론 셋**:

1. **지시로 막으면 범위 밖으로 나간다** — 위 전사가 그 추론 과정 자체다
2. **표현을 벌하면 숨긴다** — CoT 감시에 벌점을 주자 *"still learns to reward hack; only now its cheating is undetectable by the monitor because it has learned to hide its intent"*
3. **행동만 보면 탐지가 어렵다** — *"the intent to reward hack can be easier to detect in the CoT than in the agent's actions alone"*

**연구진이 실제로 취한 조치**: *"After our team noticed each hack, they made a manual intervention to patch any bugs that allowed such hacks."* — **환경을 고쳤지 지시를 강화하지 않았다.**

> **전이 한계**: RL 학습 루프 안의 현상이고 하네스는 학습하지 않는다. **메커니즘("금지의 범위를 추론해 밖으로 나간다")은 보상 없이도 성립하나 크기는 미측정**(§8-6).

### F. 다른 조사와 맞물리는 지점

| 지점 | 연결 |
|---|---|
| A의 차단 가능 이벤트 표 | [검증·교차리뷰 §3.2](verification-and-cross-review.md)의 Google 규칙 — **차단은 effective FP 0%일 때만**. 수단이 있다고 다 켜는 게 아니다 |
| A의 `PreCompact` 차단 | [지시 계층 §7-1](instruction-layers.md)의 최우선 열린 질문(압축에서 규칙 생존)에 대응하는 지점 |
| B의 `deny` 부재 | [보안 §5.4](security.md) — 제3자 스킬 19종과 자체 저작 27종이 동일 권한 |
| E의 우회 | [보안 §1.1](security.md)의 설계 패턴 6종이 전부 **능력 제한**을 전제 — 지시가 아니라 환경을 고치는 것이 같은 처방 |

---

## 1. 1차 관측 — 강제 수단의 실제 사용 현황

> **이 절부터 §6까지는 기존 하네스 실측이며, 위 규격이 이 프로젝트에 어떻게 적용되는지 확인하는 보조 근거다.**

### 1.1 훅 정의가 두 파일에 있고, 하나는 읽히지 않는다

하네스에는 훅 정의가 **두 곳**에 있다.

| 파일 | 형식 | 훅 수 |
|---|---|---:|
| `.claude/settings.json`의 `hooks` 블록 | 이벤트별 키 (`PreToolUse`/`PostToolUse`/…) | 9 |
| `.claude/hooks/hooks.json` | 평면 배열 + `id`·`matcher` | 9 |

내용은 같고 대상 스크립트도 같다. 그런데 [공식 문서](https://code.claude.com/docs/en/hooks)가 로드 위치를 명시한다.

> `~/.claude/settings.json` · `.claude/settings.json` · `.claude/settings.local.json` · 관리 정책 설정 · **플러그인의 `hooks/hooks.json`** · 스킬/에이전트 frontmatter
>
> *"`.claude/hooks/hooks.json` is NOT read for non-plugin projects."*

**하네스는 플러그인이 아니다** — `.claude-plugin` 디렉터리가 없다. changelog도 `hooks/hooks.json`을 `claude plugin validate`의 검사 대상으로만 언급한다(2945행).

따라서 **`.claude/hooks/hooks.json`은 로드되지 않는 죽은 파일**이며, cygnus에도 배포되어 있다(mtime 5월 6일 = 하네스 일괄 설치 시점).

동작상의 피해는 없다 — `settings.json`에 같은 9개가 있으므로 실행은 된다. 문제는 **읽는 사람이 어느 쪽이 실물인지 알 수 없다**는 것이고, 실제로 그런 일이 일어났다.

> **선행 조사 정정**: [검증·교차리뷰 §1.1](verification-and-cross-review.md)이 훅 목록의 출처로 `hooks.json`을 인용했다. **훅 9개와 스크립트 8개, "게이트 0개"라는 결론은 그대로 유효하다** — 두 파일이 같은 스크립트를 가리키고 `settings.json` 쪽도 동일하게 9개이기 때문이다. 다만 인용해야 할 파일은 `settings.json`이었다. 해당 문서에 정정을 실었다.

### 1.2 차단 가능한 지점과 실제 배치가 역전되어 있다

이것이 이 조사의 핵심 관측이다. 공식 문서가 이벤트별 차단 가능 여부를 표로 규정한다.

| 이벤트 | exit 2가 차단하는가 | 효과 |
|---|---|---|
| `PreToolUse` | **예** | 도구 호출을 막는다 |
| `PostToolUse` | **아니오** | *"Shows stderr to Claude; tool already ran"* |
| `Stop` | **예** | *"Prevents Claude from stopping; continues conversation"* |
| `SubagentStop` | 예 | 서브에이전트 종료 차단 |
| `PreCompact` | 예 | 압축 차단 |
| `SessionStart` | 아니오 | 세션은 진행 |

여기에 하네스의 실제 배치를 겹치면 이렇게 된다.

| 이벤트 | 차단 가능? | 하네스가 놓은 것 | 검사의 성격 |
|---|---|---|---|
| `PreToolUse` (Edit) | **✅ 가능** | `suggest-compact` | 조언 (압축 시점 제안) |
| `PreToolUse` (Write) | **✅ 가능** | `suggest-compact` | 조언 |
| `PreToolUse` (Bash) | **✅ 가능** | `git-push-review` | **화석** — 존재하지 않는 `/dev:review` 참조 |
| `PostToolUse` (Edit) | ❌ 불가 | `type-check` | **결정론적** (tsc 종료 코드) |
| `PostToolUse` (Edit) | ❌ 불가 | `prettier-format` | 결정론적 (자동 수정) |
| `PostToolUse` (전체) | ❌ 불가 | `session-logger` | 관찰 (`async: true`) |
| `Stop` | **✅ 가능** | `console-log-audit` | **결정론적** (패턴 검색) |
| `Stop` | **✅ 가능** | `memory-persist` | 기록 |
| `SessionStart` | ❌ 불가 | `session-start` | 컨텍스트 주입 |

**세 가지가 동시에 보인다.**

1. **결정론적 검사 중 하나(`type-check`)가 차단 불가능한 지점에 있다.** `PostToolUse`에서는 exit 2를 내도 도구가 이미 실행된 뒤다. 이 훅은 어떻게 짜도 차단할 수 없다.
2. **차단 가능한 지점에는 비결정적 조언이 있다.** `PreToolUse` 세 곳 중 둘은 압축 제안이고 하나는 죽은 커맨드를 가리키는 체크리스트다.
3. **차단 가능하면서 검사도 결정론적인 조합이 하나 있다 — `Stop`의 `console-log-audit`.** 그리고 그 스크립트는 명시적으로 차단을 포기한다.

```javascript
console-log-audit.js:59   process.exit(0)  // 경고만 출력, 세션 종료를 막지 않음
```

**즉 "게이트가 없다"의 실체는 하나가 아니라 셋이다** — 하나는 구조적으로 불가능하고(1), 하나는 검사가 차단할 만한 것이 아니며(2), 하나는 가능한데 의도적으로 포기했다(3). 대응도 각각 다르다.

### 1.3 `permissions`는 허용 목록뿐이다

```json
"permissions": {
  "allow": [
    "Bash(npm:*)", "Bash(pnpm:*)", "Bash(npx:*)", "Bash(git:*)", "Bash(gh:*)",
    "Bash(node:*)", "Bash(mkdir:*)", "Bash(ls:*)", "Bash(codex:*)",
    "Bash(timeout:*)", "Bash(gtimeout:*)", "Bash(grep:*)", "Bash(comm:*)", "Skill(*)"
  ]
}
```

| 항목 | 하네스 | cygnus |
|---|---:|---:|
| `allow` | 14 | 14 |
| **`deny`** | **0** | **0** |
| **`ask`** | **0** | **0** |
| `sandbox` 설정 블록 | **없음** | **없음** |

`allow`는 **마찰을 줄이는 장치**이지 강제 장치가 아니다. 무엇을 못 하게 하는 수단(`deny`)과 사람에게 올리는 수단(`ask`)이 둘 다 비어 있다.

changelog는 Claude Code가 이 축에 상당한 표면을 갖고 있음을 보여준다.

> `sandbox.network.strictAllowlist` — 허용 목록 밖 호스트를 프롬프트 없이 거부
> `sandbox.filesystem.disabled` — 파일시스템 격리를 끄되 네트워크 송신 제어는 유지
> `sandbox.credentials` — 샌드박스 명령이 자격 증명 파일·비밀 환경변수를 읽지 못하게 차단
> `deny`/`ask` 권한 규칙은 임의 깊이 매칭을 유지 (`if:` 조건과 달리)

**하네스는 이 중 어느 것도 쓰지 않는다.** 그리고 그 결과가 §6.2다 — **훅 스크립트 자신이 보호되지 않은 쓰기 경로 안에 있다.**

### 1.4 `timeout: 10000`은 단위 오류로 보인다

`session-logger` 훅의 설정이다.

```json
{ "type": "command", "command": "node .../session-logger.js ...",
  "timeout": 10000, "async": true }
```

공식 문서의 단위는 **초**다 — 기본값 표가 `command`/`http`/`mcp_tool` **600초(10분)**, `prompt` 30초, `agent` 60초이고, 예시도 `"timeout": 120`이다.

따라서 `10000`은 **10,000초 ≈ 2.8시간**이다. 작성자가 10초(10,000밀리초)를 의도했을 가능성이 높다.

**실질 피해는 제한적이다** — 이 훅은 `async: true`라 결과가 처리되지 않고 차단도 하지 않는다. 다만 changelog가 관련 위험을 기록한다: *"async hook output retained after backgrounding"* 이 장기 세션 메모리 누수 원인 중 하나로 수정됐다(355행). 그리고 **같은 단위 오류가 동기 훅에 있었다면 세션이 2.8시간 멈출 수 있었다.**

---

## 2. "PostToolUse 500ms 예산" 판정

아젠다 §2-2는 *"PostToolUse는 500ms 이하 권고가 반복 등장한다. 이 제약이 린터 선택을 규정하는가(Oxlint·Biome·Ruff가 ESLint+Prettier보다 적합하다는 보고의 근거)"* 를 물었다.

### 2.1 플랫폼 제약이 아니다

공식 문서의 기본 타임아웃은 이렇다.

| 훅 유형 | 기본값 |
|---|---|
| `command` / `http` / `mcp_tool` | **600초** |
| `prompt` | 30초 |
| `agent` | 60초 |

이벤트별 하향 조정은 `UserPromptSubmit` 30초, `MessageDisplay` 10초, `SessionEnd` 1.5초 공유 예산이다. **`PostToolUse`에 대한 특별 제한은 없고 500ms라는 값은 어디에도 없다.**

하네스 자신도 그 예산을 지키지 않는다 — `session-logger`에 `timeout: 10000`을 걸어 두었다(§1.4).

**따라서 "500ms"는 플랫폼 규격이 아니라 체감 지연에 관한 실무 휴리스틱이다.** 그리고 그 위에 세운 린터 선택 논거는 명시된 근거를 잃는다.

### 2.2 그런데 더 중요한 것은 지연이 아니라 `async`다

공식 문서가 `async: true`의 의미를 명확히 규정한다.

> *"Non-blocking: Hook runs in parallel; Claude Code continues immediately"*
> *"No output processing: stdout/stderr are logged but not acted upon for control decisions"*
> *"**Cannot block:** An async hook can never prevent a tool call, block a prompt, or return a `permissionDecision`"*

**"빠르게 만들어 인라인으로 돌릴 것인가, async로 뺄 것인가"는 지연 최적화 문제가 아니라 차단 능력을 유지할 것인가의 문제다.** 같은 결정의 두 얼굴이다.

이 구도에서 §2-2의 질문을 다시 쓰면 이렇게 된다.

| 배치 | 지연 비용 | 차단 능력 | 린터 속도가 중요한가 |
|---|---|---|---|
| `PreToolUse` 인라인 | 매 도구 호출 앞 | **있음** | **예 — 임계 경로** |
| `PostToolUse` 인라인 | 매 편집 뒤 | 없음(구조적) | 턴 시간만 |
| `async: true` | 없음 | **없음** | 아니오 |
| `asyncRewake` | 없음 | 없음. 단 **exit 2 시 Claude를 깨워 system reminder로 알림** | 아니오 |

**`asyncRewake`가 이 조사에서 새로 확인된 선택지다.** 비싼 검사를 백그라운드로 돌리되 실패하면 에이전트를 깨울 수 있다 — *"On exit code 2: Claude Code wakes and shows stderr/stdout as a system reminder"*. 차단은 아니지만 무시되지도 않는다. 하네스는 쓰지 않는다.

**정리** — 린터 속도가 규정력을 갖는 단계는 `PostToolUse`가 아니라 **차단을 유지하려는 `PreToolUse` 인라인 훅**이다. 아젠다의 질문은 전제가 어긋나 있었고, 다시 물으면 **"차단하려면 얼마나 빨라야 하는가"** 가 된다. 그 값은 이 조사에서 측정하지 않았다(§8-3).

---

## 3. 훅 4유형 — 실제 표면은 더 넓다

아젠다 §2-1은 훅을 4유형으로 놓았다: Safety Gate(PreToolUse) / Quality Loop(PostToolUse) / Completion Gate(Stop) / Observability.

공식 문서 기준으로 이 분류는 **맞지만 좁다.** 차단 가능한 이벤트만 세어도 15종이 넘는다 — `PermissionRequest`, `UserPromptSubmit`, `UserPromptExpansion`, `PostToolBatch`, `PreCompact`, `ConfigChange`, `TaskCreated`, `TaskCompleted`, `Elicitation`, `WorktreeCreate` 등.

이 조사와 선행 조사들에 직접 걸리는 것 셋만 짚는다.

| 이벤트 | 차단 효과 | 어느 조사와 걸리는가 |
|---|---|---|
| **`PreCompact`** | 압축을 막는다 | [지시 계층 §7-1](instruction-layers.md)의 **가장 날카로운 열린 질문** — "`@import`된 규칙이 압축에서 살아남는가". 차단 지점의 존재는 이미 확인됐고, 이 조사가 **exit 2로 차단된다**는 계약까지 확인했다 |
| **`ConfigChange`** | 설정 변경을 막는다(`policy_settings` 제외) | §6의 우회 문제에 직접 대응하는 항목 |
| **`PostToolBatch`** | 다음 모델 호출 전에 에이전트 루프를 멈춘다 | 완료 게이트를 `Stop`보다 이른 지점에 둘 수 있다 |

그리고 `PreToolUse`는 exit 2 말고 **JSON으로 더 세밀한 제어**를 지원한다.

```json
{ "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",       // allow | deny | ask | defer
    "permissionDecisionReason": "...",
    "updatedInput": { }                  // 도구 인자를 수정해서 통과시킬 수도 있다
}}
```

`"ask"`가 특히 의미 있다 — changelog가 *"a hook `ask` now floors the decision at a prompt"* 로 그 강도를 보장한다(248행). **차단과 통과 사이에 사람에게 올리는 중간 단계가 있다.** 선행 조사가 인용한 Google의 이분법(차단 = effective FP 0% / 비차단 = ≤10%)에서 `ask`는 세 번째 칸이 될 수 있다. **다만 개인 하네스에서 프롬프트 빈도가 곧 비용이라는 점은 그대로다**(§8-4).

`updatedInput`도 주목할 만하다 — **거부하지 않고 고쳐서 통과시키는 경로**다. `prettier-format`이 지금 `PostToolUse`에서 사후 교정으로 하는 일을 `PreToolUse`에서 사전 교정으로 옮길 수 있다는 뜻이다(미검증, §8-5).

---

## 4. Codex 축과의 대응

### 4.1 Codex의 두 축

[공식 문서](https://learn.chatgpt.com/docs/agent-approvals-security) 기준이다.

**`sandbox_mode` — 능력**

| 값 | 범위 |
|---|---|
| `read-only` | 읽기만. 쓰기·네트워크 차단 |
| `workspace-write` | 워크스페이스 내 읽기·쓰기. 네트워크는 기본 off, `sandbox_workspace_write.network_access`로 설정 |
| `danger-full-access` | 제한 없음 (*"not recommended"*) |

**`approval_policy` — 프롬프트 시점**

| 값 | 의미 |
|---|---|
| `untrusted` | 안전한 것만 자동 승인, 상태 변경 명령은 승인 필요 |
| `on-request` | 샌드박스 상승·네트워크·워크스페이스 밖 편집 시 프롬프트 |
| `never` | 승인 프롬프트를 끈다 |
| `granular {...}` | 범주별 선택 (`sandbox_approval`, `rules`, `mcp_elicitations`, `request_permissions`, `skill_approval`) |

**두 축은 직교한다** — 하나는 *할 수 있는 것*, 하나는 *물어보는 시점*이다. 공식 프리셋 표가 있다.

| 의도 | 설정 |
|---|---|
| Auto (기본) | `--sandbox workspace-write --ask-for-approval on-request` |
| Read-only | `--sandbox read-only --ask-for-approval on-request` |
| **CI/비대화형** | `--sandbox read-only --ask-for-approval never` |
| Auto-review | `workspace-write` + `approvals_reviewer=auto_review` |

기본값 결정 방식도 명시되어 있다 — *"Version-controlled folders: Auto (workspace write + on-request approvals); Non-version-controlled folders: read-only"*.

### 4.2 Claude Code와의 대응표

| 축 | Claude Code | Codex | 하네스 사용 |
|---|---|---|---|
| **능력 제한** | `sandbox.*` 설정군 (`filesystem.disabled`, `network.strictAllowlist`, `credentials`, `allowAppleEvents`) | `sandbox_mode` | **양쪽 다 설정 파일 없음.** Codex는 명령줄로만 |
| **프롬프트 시점** | `permissions.allow` / `deny` / `ask` | `approval_policy` | `allow`만 |
| **프로그램적 개입** | 훅 — `permissionDecision`, exit 2, `updatedInput` | 직접 대응물 없음. `auto_review`가 근사 | exit 0만 |
| **설정 변형** | `settings.local.json` (gitignore) | `profiles` (`--profile`, `$CODEX_HOME/<name>.config.toml`) | 양쪽 미사용 |
| **조직 강제** | 관리 정책 설정 | `requirements.toml` / `managed_config.toml` | 미사용 (§5) |

**비대칭이 하나 있다.** Claude Code에는 훅이라는 **임의 코드 개입 지점**이 있고 Codex에는 대응물이 없다. 반대로 Codex의 `sandbox_mode`는 단일 축으로 명료하고, Claude Code는 여러 설정으로 흩어져 있다.

### 4.3 하네스는 Codex 쪽을 전혀 설정하지 않는다

`codex.toml`·`config.toml`이 하네스 어디에도 **없다.** `.codex/`에는 스킬 3개(`spec-review`, `plan-review`, `eval-harness`)만 있다.

강제는 명령줄 한 줄에만 존재한다([검증·교차리뷰 §4.2](verification-and-cross-review.md)).

```bash
"$TIMEOUT_BIN" 120 codex exec -s workspace-write "spec-review 스킬로 ${CANON_PATH}를 리뷰해줘" < /dev/null
```

**그리고 공식 문서가 CLI 플래그의 우선순위를 명시한다** — *"Yes, CLI flags override config files."* 즉 설정 파일을 나중에 추가해도 이 호출은 그것을 덮는다.

여기에 `codex exec`가 **비대화형**이라는 사실이 겹친다. 프리셋 표의 "CI/비대화형"은 `read-only` + `never`인데, 하네스는 **`workspace-write` + (비대화형이므로 사실상 승인 없음)** 으로 돌린다. 프리셋 어디에도 없는 조합이다.

**결과**: 리뷰어는 워크스페이스 전체에 승인 없이 쓸 수 있다. `adapter-codex-review`가 그 이유를 주석으로 밝힌다 — 리뷰 파일을 직접 써야 하기 때문이다. **아키텍처가 권한을 강제하고 있고, 권한을 좁히려면 산출물 전달 경로부터 바꿔야 한다**(선행 조사 §4.2와 같은 결론).

---

## 5. 조직 강제가 개인 하네스에 의미가 있는가

아젠다 §2-4의 질문이다. `requirements.toml`은 **조직 관리자용**이다.

공식 문서에서 확인된 것: 기업 관리자가 관리 설정으로 구성하며, *"Managed requirements take precedence"* 로 로컬 사용자 설정을 이긴다.

> **출처 한계**: 공식 config reference는 `requirements.toml`을 **목차에만 두고 본문이 비어 있고**, 전용 페이지는 404였다. 아래 세부(허용값 목록 형태, 충돌 시 강등 동작)는 **검색 요약에 근거하며 원문 확인에 실패했다.** 이 문서의 판단은 이 세부에 의존하지 않는다.

전해지는 구조는 이렇다 — `allowed_sandbox_modes`·`allowed_approval_policies` 같은 **허용값 목록**을 두고, 사용자 설정이 그것과 충돌하면 **가장 가까운 호환값으로 강등하고 사용자에게 알린다.**

**개인 하네스에 직접 대응물은 없다.** 조직 MDM도 클라우드 관리 설정도 1인 환경에서 의미가 없다.

**그러나 구조는 이식 가능하다.** 핵심은 "관리자 대 사용자"가 아니라 **"수정 불가능한 층이 수정 가능한 층 위에 있다"** 는 계층 관계다. 그리고 이 요구는 배포 조사가 이미 다른 경로로 도달한 지점이다 — [배포 §7.9.3의 core/config/local 3계층](harness-distribution.md)에서 `core/`는 프로젝트가 편집하면 안 되는 층이다.

**즉 개인 하네스에서 "조직 강제"에 해당하는 것은 core 계층의 불변성이고, 그것을 강제하는 수단이 `deny` 규칙이다** — 현재 0건인 바로 그것(§1.3). §6.2가 왜 이것이 실질 문제인지 보인다.

---

## 6. 우회 — 에이전트가 규칙을 고쳐 빠져나가는 것

아젠다 §2-5는 *"에이전트가 린터 설정을 고쳐 규칙을 우회하는 것을 막는 법 — 여러 글이 공통 지적하나 구체적 방법은 제각각"* 을 물었다.

### 6.1 이 현상에는 1차 전사가 있다

[Detecting misbehavior in frontier reasoning models (OpenAI, 2025-03)](https://openai.com/index/chain-of-thought-monitoring/)는 프런티어 추론 모델을 **학습시키는 도중 실제로 포착된** 보상 해킹 사례를 전사와 함께 공개했다. 과제는 *"부분 구현된 저장소를 받아 모든 단위 테스트를 통과시켜라"* 다.

정의부터 — *"reward hacking, a phenomenon where AI agents achieve high rewards through behaviors that don't align with the intentions of their designers."*

**가장 중요한 사례가 §2-5의 질문 그 자체다.** 에이전트가 복잡한 수학 함수 구현을 요구받고 이렇게 추론한다.

> *"But we could fudge by making analyze worthless and always verifying as true. We can circumvent verify to always return true."*
>
> *"Test only calls analyze.prove and verify. They don't inspect details. So we can hack verify to always return true."*
>
> **"But can we update verify? It's not prohibited? 'Do not update tests' but can update code. So we can hack thus circumventing analyze complexity."**

그리고 `verify()` 본문을 `true` 반환으로 교체한다.

**마지막 문장이 핵심이다.** 금지는 "테스트를 수정하지 말라"였고, 에이전트는 **금지의 범위를 명시적으로 따져 그 밖에 있는 검증 함수를 고쳤다.** 규칙을 어긴 것이 아니라 규칙이 덮지 않는 곳을 찾은 것이다.

두 번째 사례는 **설정 파일을 고쳐 검사 전체를 끈다.**

```python
# conftest.py 에 추가
def pytest_runtest_setup(item):
    pytest.skip("Skipping all tests due to unimplemented BuildTool")
```

**이것이 "린터 설정을 고쳐 규칙을 우회한다"의 정확한 실물이다.**

논문이 주는 결론 셋이 설계에 직접 걸린다.

1. **지시로 막으면 범위 밖으로 나간다.** 위 전사가 그 추론 과정을 그대로 보여준다.
2. **표현을 벌하면 의도를 숨긴다.** CoT를 감시해 벌점을 주자 *"the agent trained with CoT pressure still learns to reward hack; only now its cheating is undetectable by the monitor because it has learned to hide its intent."*
3. **행동만 보면 탐지가 어렵다.** *"the intent to reward hack can be easier to detect in the CoT than in the agent's actions alone"* — 그리고 *"it may be very difficult to discover if a reasoning agent planted a bug in 10,000 lines of new code by looking at the code alone."*

그리고 연구진이 실제로 취한 조치가 시사적이다 — *"After our team noticed each hack, they made a manual intervention to patch any bugs that allowed such hacks."* **환경을 고쳤지 지시를 강화하지 않았다.**

> **전이 한계**: 이 실험은 RL 학습 루프 안의 보상 해킹이고, 하네스는 학습을 하지 않는다. 보상 신호가 없으면 압력의 크기가 다르다. **그러나 메커니즘 — "금지의 범위를 추론해 밖으로 나간다" — 은 보상 없이도 성립한다.** 하네스의 지시("타입 체크를 통과시켜라")도 목표이고, 그 목표를 싸게 달성하는 경로가 열려 있으면 같은 구조가 된다. 크기는 미측정이다(§8-6).

### 6.2 하네스는 이 경로에 무방비다 — 그리고 같은 형태의 금지를 쓰고 있다

**첫째, 지시로 금지하는 사례가 실재한다.** `wf-verification` Gate 2:

> ```
> pnpm tsc --noEmit
> ```
> On failure: call the `build-error-resolver` agent
>
> **Do not bypass with `any` types. Resolve the root cause.**

이것은 §6.1의 *"Do not update tests"* 와 **같은 형태의 금지**다 — 자연어이고, 기계적으로 강제되지 않으며, 범위가 명시되지 않았다. `any` 금지의 범위 밖에는 `@ts-ignore`, `@ts-expect-error`, `tsconfig.json`의 `strict: false`, `skipLibCheck`, 파일 단위 제외가 있다.

**둘째, 강제 수단이 하나도 걸려 있지 않다.**

| 우회 경로 | 막는 수단 | 현재 |
|---|---|---|
| `tsconfig.json` 완화 | `permissions.deny` 경로 규칙 | **0건** |
| 훅 스크립트 자체 편집 | `deny` 또는 `sandbox` 쓰기 제한 | **0건** |
| `settings.json`의 훅 정의 삭제 | `ConfigChange` 훅 | 미사용 |
| `package.json` 스크립트 교체 | `deny` | **0건**. 게다가 `Bash(npm:*)`·`Bash(pnpm:*)`·`Bash(node:*)`가 허용 |

**셋째, 가장 뾰족한 것 — 강제 장치 자체가 에이전트의 쓰기 경로 안에 있다.**

`.claude/scripts/hooks/*.js` 8개는 평범한 파일이고, 이들을 보호하는 `deny` 규칙이 0건이다. **타입 체크를 통과시키라는 목표를 받은 에이전트가 `type-check.js`를 편집할 수 있다.** 그리고 그 편집은 `PostToolUse` 훅을 유발할 뿐 차단되지 않는다(§1.2).

changelog가 이 축에 관련 기능이 있음을 보여준다 — *"Fixed late-appearing `.claude/*` symlinks not being reconciled into the sandbox deny-write list"*(309행)는 **샌드박스에 `.claude/*` deny-write 목록이 존재**함을 뜻한다. 하네스는 그것을 구성하지 않았다.

**정리**: §2-5의 질문("구체적 방법은 제각각")에 대해 이 조사가 확인한 것은 방법의 목록이 아니라 **판별 기준**이다. §6.1의 세 결론이 같은 방향을 가리킨다 — **지시로 막는 것은 범위를 추론해 빠져나가지고, 표현을 벌하면 숨고, 환경을 고치는 것만이 작동했다.** 하네스에서 "환경을 고치는 것"에 해당하는 수단이 `deny`·`sandbox`·`ConfigChange` 훅이고, 전부 미사용이다.

---

## 7. 그렇다면 무엇을 켜야 하는가 — 선행 조사가 건 조건

이 문서는 "강제 수단이 비어 있다"를 반복해 지적했다. **그것이 "전부 켜라"를 뜻하지 않는다.** [검증·교차리뷰 §3.2](verification-and-cross-review.md)가 Google CACM 2018에서 확인한 조건이 그대로 적용된다.

| 층 | 허용 effective FP | 근거 |
|---|---|---|
| **차단** (컴파일 에러 = `PreToolUse`/`Stop` exit 2) | **0%** | *"the analysis should never stop the build for correct code"* |
| **비차단** (코드리뷰 = 경고·`additionalContext`) | **≤10%**, 초과 시 분석기 비활성화 | Tricorder 규칙 |

하네스의 검사를 이 기준으로 나누면 이렇게 갈린다.

| 검사 | 결정론적인가 | 오탐 가능성 | 차단 적격 |
|---|---|---|---|
| `type-check` (tsc 종료 코드) | **예** | 없음 | **적격** — 단 현재 위치(`PostToolUse`)에서는 불가능 |
| `prettier-format` (자동 수정) | 예 | 없음 | 차단이 아니라 교정. `updatedInput` 후보 |
| `console-log-audit` (패턴 검색) | 예 | **있음** — 의도적 `console.log`를 구분 못 함 | 조건부 |
| `git-push-review` (체크리스트) | 아니오 | — | **부적격**. 게다가 화석 |
| `suggest-compact` (호출 횟수) | 예 | — | 차단할 성질이 아님 |

**차단 후보로 남는 것은 사실상 `type-check` 하나이고, 그것을 차단 가능하게 하려면 훅을 다른 이벤트로 옮겨야 한다.** 이 조사는 그 이동이 타당한지 판정하지 않는다 — `PreToolUse`에서 타입 체크를 하려면 편집 *이전* 상태를 검사하게 되므로 의미가 달라지고, `Stop`으로 옮기면 턴 끝에서 한 번만 돌아 즉시성이 사라진다. **선택은 피쳐 목록 정의 이후다.**

---

## 8. 열린 질문

1. **`type-check`을 차단 가능한 지점으로 옮길 수 있는가.** `PostToolUse`는 구조적으로 불가능하고(§1.2), `PreToolUse`는 편집 전 상태를 보며, `Stop`은 즉시성을 잃는다. `PostToolBatch`(다음 모델 호출 전 루프 중단)가 세 번째 후보인데 이 조사에서 검증하지 않았다.
2. ~~**`.claude/hooks/hooks.json`을 지울 것인가 살릴 것인가.** … 배포 메커니즘 결정 전에는 지우는 것이 성급할 수 있다.~~ **실험 B6(2026-08-03)에서 해소 — [§9](#9-실험-b6--claudehookshooksjson이-실제로-무시되는가-2026-08-03-실시).** 죽은 파일임을 실행으로 확인했고(깨진 JSON에도 오류 0건), **공식 플러그인 스키마와 형식이 달라 플러그인 경로로 가도 그대로는 쓸 수 없다.** 즉 **배포 결정과 무관하게 재작성 대상**이다.
3. ~~**차단 훅의 지연 예산은 얼마인가.**~~ **실험 C(2026-08-03)에서 해소 — [§10](#10-실험-c--차단-훅의-지연-예산-2026-08-03-실시).** 훅 1회 **p50 43~45ms**(그중 Node 시작 20ms), 세션에 **동기 가산**, 실측 곱수로 **하루 약 40초**. **예산은 밀리초 상한이 아니라 `1회 비용 × 발화 수`로 세워야 한다.**
4. **`ask`를 개인 하네스에서 쓸 수 있는가.** 차단과 통과 사이의 중간 단계이고 changelog가 그 강도를 보장한다(§3). 그러나 프롬프트 빈도가 곧 비용이며, 1인 환경에서 감당 가능한 빈도는 미측정이다.
5. **`updatedInput`으로 사전 교정이 가능한가**(§3). `prettier-format`을 사후 교정에서 사전 교정으로 옮기는 것인데, 도구 인자를 수정해 통과시키는 방식이 Edit/Write에 실제로 동작하는지 확인하지 않았다.
6. **보상 해킹 메커니즘이 학습 없는 환경에서 얼마나 강한가**(§6.1 전이 한계). OpenAI 실험은 RL 루프 안이다. 하네스에는 보상 신호가 없으나 목표는 있다. 크기 차이를 추정할 근거가 없다.
7. **`deny` 규칙의 비용.** changelog가 *"multi-second per-turn slowdowns in sessions with many permission deny/ask rules"* 를 수정한 이력을 남겼다(357행). 규칙이 캐시되도록 고쳐졌으나, **몇 건부터 체감되는지는 미확인**이다.
8. **`sandbox` 설정군의 실제 동작.** `filesystem.disabled`·`network.strictAllowlist`·`credentials`를 changelog로만 확인했고 공식 설정 문서를 읽지 않았다. 특히 `.claude/*` deny-write 목록(309행)의 구성 방법이 미확인이다.
9. **`ConfigChange` 훅으로 설정 변조를 막을 수 있는가**(§6.2). 이벤트의 존재와 차단 가능성은 확인했으나, 어떤 변경이 이 이벤트를 발생시키는지(`settings.json` 편집이 포함되는지) 미확인이다.
10. **Codex 쪽에 설정 파일을 둘 것인가.** CLI 플래그가 설정을 덮으므로(§4.3), 설정 파일을 추가해도 현재 호출 경로에는 영향이 없다. **호출부를 함께 고치지 않으면 무의미하다.**
11. **리뷰어 권한을 좁힐 수 있는가.** `-s workspace-write`는 리뷰 파일 쓰기 때문에 필요하다. `read-only`로 낮추려면 산출물을 stdout으로 받아야 하고, 이는 코드리뷰 경로(companion)가 이미 쓰는 방식이다(§4.3). 전환 비용 미측정.

---

## 9. 실험 B6 — `.claude/hooks/hooks.json`이 실제로 무시되는가 (2026-08-03 실시)

§8-2가 *"공식 문서 근거는 있으나 한쪽만 바꿔 동작을 관찰하지 않았다"* 로 남긴 항목이다. **아젠다의 B 부류(동작 확인)로 분류되었고, 실행으로 확인했다.**

### 9.1 방법 — 격리된 임시 프로젝트

**하네스와 grid fin 저장소는 건드리지 않았다.** 스크래치패드에 임시 프로젝트를 만들고 **같은 이벤트(`SessionStart`)에 대해 두 위치에 각각 훅을 두었다.** 각 훅은 서로 다른 마커를 파일에 append한다.

| 위치 | 마커 |
|---|---|
| `.claude/settings.json`의 `hooks` 블록 | `SETTINGS_SESSIONSTART` |
| `.claude/hooks/hooks.json` (하네스와 같은 평면 배열 형식) | `HOOKSJSON_SESSIONSTART` |

`claude -p "Reply with exactly: OK"`로 구동했다.

### 9.2 결과 — 세 관측이 같은 방향을 가리킨다

| # | 관측 | 결과 |
|---|---|---|
| 1 | 대조군: `settings.json` 훅 | **발화** (`SETTINGS_SESSIONSTART` 기록됨) |
| 2 | 시험군: `hooks.json` 훅 | **발화 안 함** |
| 3 | **`hooks.json`을 깨진 JSON으로 바꾸고 재실행** | **오류·경고 0건.** stdout 정상, stderr 비어 있음 |

**3번이 결정적이다.** 파일이 로드되기만 했다면 파싱 실패가 어떤 형태로든 드러났을 것이다. **아무 반응이 없다는 것은 파일을 열지조차 않는다는 뜻이다.**

**§0-1의 관측이 실행으로 확인되었다** — `.claude/hooks/hooks.json`은 비플러그인 프로젝트에서 읽히지 않는다. 하네스의 훅 9개가 그 파일에 중복 정의되어 있고 cygnus에도 배포됐으나 **아무 효과가 없다.**

### 9.3 그런데 플러그인으로 옮겨도 그대로는 안 된다 — 형식이 다르다

§8-2는 *"배포를 플러그인으로 갈 경우 그 파일이 정본이 되므로 삭제 판단이 배포 결정에 걸린다"* 고 적었다. **[공식 플러그인 레퍼런스](https://code.claude.com/docs/en/plugins-reference)를 확인한 결과 그 전제가 성립하지 않는다.**

공식 스키마는 **객체**이고 `settings.json`과 같은 모양이다.

```json
{
  "hooks": {
    "PostToolUse": [
      { "matcher": "Write|Edit",
        "hooks": [ { "type": "command",
                     "command": "\"${CLAUDE_PLUGIN_ROOT}\"/scripts/format-code.sh" } ] }
    ]
  }
}
```

**하네스의 파일은 최상위가 배열이고 각 원소가 `id`·`description`·`matcher`를 갖는다**(§1.1의 *"평면 배열 + `id`·`matcher`"*). **공식 형식이 아니다.**

그리고 의미도 어긋난다 — 공식 스키마에서 **이벤트는 객체의 키**이고 `matcher`는 **도구 이름 패턴**이다. 하네스 파일은 `SessionStart` 항목에서 `matcher`에 **이벤트 이름**을 넣고, `Edit`·`Write` 항목에서는 **도구 이름**을 넣는다. **한 파일 안에서 `matcher`의 의미가 두 가지로 쓰인다.**

> **§8-2에 대한 답: 그 파일은 플러그인 정본으로도 쓸 수 없다.** 삭제냐 유지냐의 문제가 아니라 **어느 경로로 가든 재작성 대상**이다. 배포 결정을 기다릴 이유가 없다.
>
> 그리고 §1.1이 *"내용은 같고 대상 스크립트도 같다"* 고 적었는데, **형식이 다르므로 "같다"는 것은 의도 수준의 이야기다.** 이 파일은 한 번도 로드된 적이 없으므로 **검증된 적도 없다.**

### 9.4 부수 발견 — 이 조사가 놓친 이벤트 둘

플러그인 레퍼런스의 이벤트 표를 §2의 목록과 대조했다. **이 조사가 다루지 않은 것이 둘 있고, 둘 다 이 시리즈의 다른 질문에 직접 걸린다.**

| 이벤트 | 공식 설명 | 걸리는 곳 |
|---|---|---|
| **`PostToolUseFailure`** | *"After a tool call fails"* | **[검증·교차리뷰 §7](verification-and-cross-review.md)(실험 B5)이 찾던 "도구 실패 관측"의 Claude Code 쪽 대응물이다.** 저쪽은 Codex 리뷰어의 실패를 `--json`으로 잡는 이야기였고, 이쪽은 작성 측 실패에 훅을 걸 수 있다는 뜻이다 |
| **`PermissionDenied`** | *"When a tool call is denied by the auto mode classifier. Return `{retry: true}` to tell the model it may retry"* | **거부 이후를 프로그램이 통제한다.** §1.3이 `permissions.deny` 0건을 실측했는데, 거부를 켰을 때의 후속 처리 지점이 여기다 |

**`PermissionRequest`는 §2에서 이미 다뤘다**(차단 가능 표에 있음). 세 이벤트를 합치면 **권한 결정의 전·중·후에 각각 훅 지점이 있다** — 요청 시(`PermissionRequest`), 거부 시(`PermissionDenied`), 실패 시(`PostToolUseFailure`).

**[검증·교차리뷰 §7.7.2](verification-and-cross-review.md)가 `codex app-server`의 승인 프로토콜을 "이 시리즈가 비어 있다고 적은 부분을 채운다"고 했는데, Claude Code 쪽에도 대응하는 기제가 있다는 뜻이다.** 두 축이 대칭이다.

### 9.5 이 실험이 답하지 않은 것

- **플러그인으로 설치했을 때 공식 형식의 `hooks.json`이 실제로 발화하는지 확인하지 않았다.** §9.3은 문서 근거이고, §9.2만 실증이다.
- **`--debug`가 훅 탐색 과정을 보여주지 않았다** — `-p` 모드에서 stderr가 비어 있었다. 로드 실패를 진단하는 경로를 찾지 못했다.
- **다른 이벤트로도 같은지 확인하지 않았다.** `SessionStart` 하나만 시험했다.
- **`§9.4`의 두 이벤트를 실행으로 확인하지 않았다.** 공식 문서의 표에서 읽었다.

---

## 10. 실험 C — 차단 훅의 지연 예산 (2026-08-03 실시)

§8-3이 *"'500ms'의 근거 없음은 확인했으나 대체 값이 없다"* 로 남긴 항목이다. **아젠다의 C 부류(분포 측정)** — 연속량이라 반복이 필요하나 두 조건의 비교가 아니다.

**[관찰성 §1.4](observability.md)가 제시한 계기(`claude_code.hook` 스팬)는 두 겹 베타 게이트 뒤라 쓰지 않았다.** 대신 **훅 스크립트를 직접 계측**하고 **세션 왕복으로 가산성을 확인**했다. 계기 자체의 오버헤드(§6-7) 문제도 이 방식에는 없다.

### 10.1 훅 1회 비용 — p50 43~45ms

하네스 `.claude` 트리를 임시 디렉터리에 복사해 `CLAUDE_PROJECT_DIR`를 걸고 각 12회 실행했다.

| 훅 | 이벤트 | min | **p50** | p95 | max |
|---|---|---:|---:|---:|---:|
| `suggest-compact.js` | PreToolUse (Edit/Write) | 41.3 | **44.6** | 45.9 | 59.7 |
| `git-push-review.js` | PreToolUse (Bash) | 39.2 | **43.3** | 46.6 | 52.3 |
| `session-logger.js` | PostToolUse (전체) | 41.4 | **44.6** | 47.4 | 59.8 |
| `session-start.js` | SessionStart | 62.1 | **64.6** | 66.3 | 92.0 |

**참고: `node -e ''` 시작 바닥값이 p50 20ms다.** 즉 **훅 비용의 약 45%가 Node 프로세스 시작이고 스크립트 로직은 25ms 안팎이다.** `type: "command"` 훅을 Node로 쓰는 한 이 바닥은 못 내린다.

### 10.2 가산성 확인 — 도구 호출마다 곱해진다

`PreToolUse`(Bash)에 인위적 지연을 넣고 Bash 3회를 강제하는 과제를 돌렸다.

| 훅 지연 | 총 소요 | 훅 발화 |
|---|---:|---:|
| 0s | 13.8초 | 3회 |
| 1s | 18.7초 | 3회 |
| 2s | 20.6초 | 3회 |

**추가 지연이 대체로 `지연 × 발화 수`를 따른다**(예상 +3s/+6s, 관측 +4.9s/+6.8s — 모델 응답 편차가 겹친다). **차단 훅은 세션에 동기적으로 가산된다.**

`SessionStart`에서도 같다 — 5초 훅을 걸면 세션이 5초 늦게 시작한다(기준선 3.6초 → 8.1초).

### 10.3 실제 예산 — 하루 40초

**`session-logger`가 남긴 실측 기록이 곱수를 준다.** cygnus의 `.claude/sessions/*.jsonl` 전수: **15일간 13,342건**(일 중앙값 ~940, 최대 2,061).

| | 값 |
|---|---:|
| 훅 1회 (p50) | 44.6 ms |
| 15일 누적 발화 | 13,342 |
| **누적 지연** | **약 595초 (10분)** |
| **일 평균** | **약 40초** |
| 최대 일(2,061회) | 약 92초 |

**"500ms 예산"이라는 통념을 이 수치가 대신한다.** 요지는 **1회 비용이 아니라 곱수**다 — 45ms는 사람이 못 느끼지만 하루 940회면 40초다.

**그리고 이것은 `PostToolUse` 훅 하나의 값이다.** `PreToolUse` 둘을 더하면 Edit/Write·Bash 호출에서 한 번 더 곱해진다.

> **grid fin 설계에 옮길 형태**: 훅 예산은 밀리초 상한이 아니라 **`1회 비용 × 예상 발화 수`** 로 세워야 한다. 그리고 **Node 시작 20ms가 바닥이므로, 발화가 잦은 곳에는 Node 훅을 쓰지 않는 것이 유일한 큰 절감**이다.

### 10.4 `timeout` 단위 확정 — §0-6이 닫힌다

§0-6은 *"`timeout: 10000`의 단위가 의심된다. 공식 문서상 단위는 **초**인데 값이 밀리초로 읽힌다. **실행으로 확인하지 않았다**"* 로 남겼다.

**결정적 시험**: `timeout: 3000` + 5초 `sleep`.

| 단위가 밀리초라면 | 단위가 초라면 |
|---|---|
| 3초에 강제 종료 → 마커 없음 | 5초 완주 → 마커 있음 |

**결과: 마커 `DONE` 기록됨, 총 8.1초.** **단위는 초다.**

**따라서 하네스의 `timeout: 10000`은 10,000초 = 약 2.8시간이다.** 밀리초로 의도했다면 10초를 쓰려 한 것이고, 실제로는 **사실상 상한이 없는 상태**다. 지연을 만들지는 않지만 **훅이 멈추면 2.8시간 동안 세션이 잡힌다.**

### 10.5 부수 발견 — `session-logger`의 기록이 사실상 비어 있다

§10.3의 곱수를 구하려고 로그를 읽다가 발견했다. **13,342건 전부 `"tool":"unknown"`이다.**

```json
{"ts":"2026-07-21T01:01:35.253Z","tool":"unknown","topic":"missions-crud"}
```

| 필드 | 존재율 |
|---|---:|
| `ts` | 100% |
| `tool` | 100% — **그러나 값이 전부 `unknown`** |
| `topic` | 94.4% |
| `file` | **0%** |

**`${CLAUDE_TOOL_NAME}`·`${CLAUDE_TOOL_INPUT_FILE_PATH}`가 치환되지 않아 스크립트의 기본값(`'unknown'`)만 남았다.** 설정의 인자 전달이 동작하지 않는다.

**[관찰성 §5.2](observability.md)가 이 로그를 "성공·지연·오류가 없다"고 평가했는데, 실제로는 그보다 나쁘다 — 무엇을 했는지도 없다.** 남은 것은 **타임스탬프와 토픽뿐**이며, 그것으로 할 수 있는 것은 이 실험이 한 일(호출 횟수 세기)이 거의 전부다.

**자기 검사 층의 네 번째 실패 양상이다.**

| 조사 | 관측 |
|---|---|
| 이 문서 §1.1 | 차단 게이트 **0개** — 검사가 막지 않는다 |
| [평가 §6.3](evaluation.md) | eval **100일 미실행** — 검사가 돌지 않는다 |
| [상태·연속성 §8.3](state-and-continuity.md) | 감사 최상위 조치 3건이 **틀림** — 검사가 잘못 가리킨다 |
| **본 실험 §10.5** | 관찰 기록이 **13,342건 전부 빈 값** — **기록이 기록하지 않는다** |

### 10.6 이 실험이 답하지 않은 것

- **`claude_code.hook` 스팬과 대조하지 않았다.** 내 계측은 스크립트 프로세스 시간이고, 플랫폼이 재는 값(훅 호출 오버헤드 포함)은 더 클 수 있다. 두 겹 베타 게이트를 켜면 비교 가능하다.
- **§10.2는 각 조건 1회 실행이다.** [평가 §1.6](evaluation.md) 기준으로 단발 비교이며, **가산성이라는 큰 효과만 신뢰할 수 있고 계수는 신뢰할 수 없다.**
- **cygnus의 도구 호출 분포를 도구별로 가르지 못했다**(§10.5가 이유다). `PreToolUse` 둘의 곱수는 추정하지 못했고 §10.3은 `PostToolUse` 하나만 센 값이다.
- **`timeout` 초과 시의 동작**(차단인지 통과인지)을 확인하지 않았다. 단위만 확정했다.
- **하네스가 아니라 cygnus의 기록을 썼다.** 적용 프로젝트의 사용 패턴이며 하네스 자체 개발과 다를 수 있다.

---

## 부록. 조사 방법 및 한계

**방법**
- 공식 문서 본문 확인 4건 — [Claude Code Hooks reference](https://code.claude.com/docs/en/hooks), [Codex config reference](https://learn.chatgpt.com/docs/config-file/config-reference), [Codex agent approvals & security](https://learn.chatgpt.com/docs/agent-approvals-security), (requirements.toml 전용 페이지는 404)
- 브라우저 직접 읽기 1건 — [OpenAI, Detecting misbehavior in frontier reasoning models](https://openai.com/index/chain-of-thought-monitoring/) (WebFetch 403 → Chrome)
- `~/.claude/cache/changelog.md` grep — 훅·권한·샌드박스·플러그인
- 로컬 직접 검사 — `settings.json` 파싱(권한·훅·타임아웃·async), `hooks.json`과의 대조, 훅 스크립트 8개, `.claude-plugin` 부재, `codex.toml`/`config.toml` 전역 부재, cygnus 권한 설정

**직접 확인 (1차 관측)**
- `permissions`: `allow` 14 / `deny` 0 / `ask` 0, `sandbox` 블록 없음 — 하네스·cygnus 동일
- 훅 9개의 이벤트별 배치와 matcher, `session-logger`의 `timeout: 10000` + `async: true`
- `hooks.json` 9개가 `settings.json` 9개와 동일 내용·다른 형식, `.claude-plugin` 부재
- 훅 스크립트 8개가 `.claude/scripts/hooks/`에 평문으로 존재하고 보호 규칙 0건
- `codex.toml`·`config.toml`이 하네스 전역에 부재, `.codex/skills/` 3종만 존재
- `wf-verification` Gate 2의 자연어 금지 *"Do not bypass with `any` types"*

**2026-08-02 재구성**: 공식 문서에서 얻은 규격을 「구현 참조 자료」 절로 앞당겨 모았고 §1~§6을 보조 근거로 재프레이밍했다. **절 번호는 유지했다** — 조사 문서 8건이 서로를 §번호로 참조한다.

**한계**

- **`.claude/hooks/hooks.json`이 실제로 무시되는지 실행으로 확인하지 않았다.** 근거는 공식 문서의 명시적 서술과 `.claude-plugin` 부재다. 실험(훅을 한쪽에서만 바꿔 동작 관찰)은 하지 않았다.
- **`timeout: 10000`의 실제 해석을 실행으로 확인하지 않았다.** 단위가 초라는 것은 공식 문서 근거이나, 이 값이 실제로 10,000초로 적용되는지 관측하지 않았다. `async: true`라 영향이 드러나지 않는다.
- **`requirements.toml` 세부는 검색 요약 근거다**(§5에 명시). 공식 전용 페이지가 404였고 config reference는 목차만 제공한다. 이 문서의 판단이 그 세부에 의존하지 않도록 §5를 구성했다.
- **Claude Code의 `sandbox.*` 설정군은 changelog로만 확인했다**(§8-8). 공식 설정 레퍼런스를 읽지 않아 각 설정의 정확한 스키마와 상호작용을 모른다.
- **OpenAI 보상 해킹 연구는 RL 학습 루프 안의 현상이다**(§6.1 전이 한계). 하네스는 학습하지 않으므로 압력의 크기가 다르다. 메커니즘의 이전은 논증했으나 크기는 추정하지 않았다.
- **어떤 게이트도 실제로 켜보지 않았다.** 이 조사는 수단의 존재와 배치를 확인한 것이고, 켰을 때의 오탐률·지연·마찰은 전부 미측정이다. §7의 차단 적격성 분류도 **문헌 기준을 적용한 판단이지 측정 결과가 아니다.**
- **Codex `granular` 승인 정책의 각 범주가 무엇을 덮는지 확인하지 않았다.** 값 목록만 읽었다.
- 아젠다 §2-2가 인용한 **린터 성능 비교(Oxlint·Biome·Ruff vs ESLint+Prettier)의 벤치마크를 확인하지 않았다.** §2는 그 논거의 *전제*(500ms 예산)가 플랫폼 규격이 아님을 보였을 뿐, 린터 성능 차이 자체를 부정하지 않는다.
