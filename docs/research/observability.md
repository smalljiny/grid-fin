# 관찰성 — 구현 참조 자료

**최초 작성**: 2026-08-02
**최종 수정**: 2026-08-02
**대상 프로젝트**: grid fin (신규 개인용 개발 하네스)
**성격**: **자료 수집·정리.** grid fin 구현 시 참조할 외부 자료를 모으고 정돈한다. 계측 설계는 선택하지 않는다.
**조사 도구**: WebFetch 5회(1차 문서 본문), GitHub API 12회(이슈·규약 저장소 원본), WebSearch 3회(자료 위치 파악), 하네스 실측(적용 대상 확인용)

선행 문서
- [research-agenda.md](research-agenda.md) §7 — 이 조사의 출처
- [error-recurrence-prevention.md](error-recurrence-prevention.md) — "기록은 있고 소비가 없다"는 진단의 출처
- [enforcement-mechanisms.md](enforcement-mechanisms.md) §1.3 — 훅 배치 실측
- [verification-and-cross-review.md](verification-and-cross-review.md) §4.1 — Codex 경로가 **둘**이라는 사실 (spec/plan은 `codex exec`, 코드 adversarial은 `codex app-server`). §7.5도 참고
- [security.md](security.md) §5.2 — `codex-companion.mjs` 실행 경로

---

## 0. 이 문서의 쓰임

**grid fin을 구현할 때 "무엇이 관측 가능한가, 그리고 무엇이 관측 불가능한가"에 답할 근거를 모았다.** 네 자료가 서로 다른 층을 덮는다.

| 자료 | 층 | 무엇을 주는가 | 등급 |
|---|---|---|---|
| [Claude Code — Monitoring](https://code.claude.com/docs/en/monitoring-usage) | **벤더 규격 A** | 메트릭 8종·이벤트 15종·스팬 6종의 전체 이름과 속성, 환경변수 전량, 전파 제약 | 1차 문서 (공식) |
| [openai/codex 이슈 #12913](https://github.com/openai/codex/issues/12913) · [#33668](https://github.com/openai/codex/issues/33668) · [PR #13083](https://github.com/openai/codex/pull/13083) | **벤더 규격 B** | 공식 레퍼런스가 안 적은 이벤트 이름, 진입점별 방출 결손, **그리고 수정이 왜 덮지 못했는지의 diff 근거**(§2.3.1) | 1차 관측 (재현 절차·소스 diff) |
| [OpenTelemetry GenAI Semantic Conventions](https://github.com/open-telemetry/semantic-conventions-genai) | **중립 규격** | 메트릭 12종·에이전트 스팬 6종의 표준 이름, 안정성 등급 | 표준 초안 (Development) |
| [Zhang et al., *Which Agent Causes Task Failures and When?* (ICML 2025)](https://arxiv.org/abs/2505.00212) | **소비 한계** | 로그에서 실패 원인을 자동으로 짚는 작업의 현재 정확도 상한 | 피어리뷰 (ICML 2025) |

**§1~§4가 자료다. §5는 이 자료가 grid fin에 해당하는지 확인하는 실측이며 보조 목적이다.**

이 문서가 반복해서 부딪히는 구분이 하나 있다. **무엇을 방출하는가(emit)와 무엇을 표준 이름으로 방출하는가(conform)는 다른 문제다.** 두 도구 모두 풍부하게 방출하지만, 같은 것을 세 가지 다른 이름으로 부른다(§3.3).

---

## 1. Claude Code의 텔레메트리 표면 — 가장 완전한 1차 규격

[공식 Monitoring 문서](https://code.claude.com/docs/en/monitoring-usage) 본문을 확인했다. 세 신호를 모두 다루며, 이름·속성·기본값·제약이 전부 명시되어 있다.

### 1.1 활성화와 신호별 게이트

| 신호 | 활성화 | 기본 export 간격 |
|---|---|---|
| 메트릭 | `CLAUDE_CODE_ENABLE_TELEMETRY=1` + `OTEL_METRICS_EXPORTER` (`otlp`/`prometheus`/`console`/`none`) | 60,000 ms |
| 이벤트(로그) | + `OTEL_LOGS_EXPORTER` (`otlp`/`console`/`none`) | 5,000 ms |
| **트레이스** | + `OTEL_TRACES_EXPORTER` **및 `CLAUDE_CODE_ENHANCED_TELEMETRY_BETA=1`** | 5,000 ms |

**트레이스만 베타 플래그 뒤에 있다.** 그리고 §1.5에서 보듯 두 벤더를 잇는 유일한 수단이 트레이스 컨텍스트이므로, **하네스 차원의 상관 관측은 베타 기능에 의존한다.**

### 1.2 메트릭 8종

| 이름 | 단위 | 주요 속성 |
|---|---|---|
| `claude_code.session.count` | — | `start_type`: `fresh`/`resume`/`continue`/`agents_view` |
| `claude_code.lines_of_code.count` | — | `type`: `added`/`removed`, `model` |
| `claude_code.pull_request.count` | — | 표준 속성만 |
| `claude_code.commit.count` | — | 표준 속성만 |
| `claude_code.cost.usage` | USD | `model`, `query_source`, `speed`, `effort`, 귀속 6종 |
| `claude_code.token.usage` | tokens | `type`: `input`/`output`/`cacheRead`/`cacheCreation`, `model`, `query_source`, `speed`, `effort`, 귀속 6종 |
| `claude_code.code_edit_tool.decision` | — | `tool_name`, `decision`: `accept`/`reject`, `source`, `language` |
| `claude_code.active_time.total` | s | `type`: `user`(키보드) / `cli`(도구 실행·응답) |

**귀속 6종**이 반복 등장한다 — `agent.name`, `skill.name`, `plugin.name`, `marketplace.name`, `mcp_server.name`, `mcp_tool.name`. 여기에 `query_source`(`main`/`subagent`/`auxiliary`)가 붙는다.

**이 귀속 축이 이 문서에서 가장 실용적인 자료다.** 스킬 단위·플러그인 단위·서브에이전트 단위로 토큰과 비용이 갈린다는 것은, 아젠다 §6(평가)이 요구한 "하네스 변경의 효과를 재는" 축이 **벤더 쪽에 이미 있다**는 뜻이다. 단 §3.2가 보이듯 이 축은 표준이 아니다.

### 1.3 이벤트 15종

`claude_code.` 접두사로: `user_prompt`, `assistant_response`, `tool_result`, `api_request`, `api_error`, `api_refusal`, `api_request_body`, `api_response_body`, `tool_decision`, `permission_mode_changed`, `auth`, `mcp_server_connection`, `internal_error`, `plugin_installed`, `plugin_loaded`.

모든 이벤트가 `event.name`·`event.timestamp`·**`event.sequence`(단조 증가 카운터)**를 갖고, `prompt.id`(하나의 사용자 프롬프트 처리 중 생성된 모든 이벤트를 잇는 UUID)를 공유한다.

강제 메커니즘·검증 조사와 직접 맞물리는 것 셋을 따로 적는다.

- **`tool_result`** — `success`(`true`/`false`), `duration_ms`, `error_type`(예: `Error:ENOENT`, `ShellError`), `tool_use_id`, `tool_input_size_bytes`, `tool_result_size_bytes`. **실패한 도구 호출이 이벤트 층에 이미 구조화되어 있다.**
- **`tool_decision`** — `decision`(`accept`/`reject`)과 `source`(`config`/`hook`/`user_permanent`/`user_temporary`/`user_abort`/`user_reject`). **결정의 원천이 훅인지 설정인지 사람인지가 구분된다.** [강제 메커니즘 조사](enforcement-mechanisms.md)가 "차단 게이트 0개"를 실측했는데, 게이트를 놓았을 때 그것이 실제로 발동했는지를 보는 단계가 여기다.
- **`permission_mode_changed`** — `from_mode`, `to_mode`, `trigger`(`shift_tab`/`exit_plan_mode`/`auto_gate_denied`/`auto_opt_in`).

### 1.4 스팬 6종 (베타)

```
claude_code.interaction (root)
├── claude_code.llm_request
├── claude_code.hook            (detailed beta only)
└── claude_code.tool
    ├── claude_code.tool.blocked_on_user
    ├── claude_code.tool.execution
    └── (Agent 도구) 서브에이전트 스팬이 여기 중첩
```

- `claude_code.interaction` — `interaction.sequence`(세션 내 1-based), `interaction.duration_ms`
- `claude_code.llm_request` — `ttft_ms`, `duration_ms`(재시도 포함), `attempt`, `stop_reason`, `response.has_tool_call`, `agent_id`/`parent_agent_id`, `workflow.run_id`/`workflow.name`
- `claude_code.tool` — `duration_ms`(권한 대기 + 실행), `result_tokens`
- `claude_code.tool.blocked_on_user` — **권한 대기 시간이 별도 스팬으로 분리되어 있다**
- `claude_code.hook` — `hook_event`, `hook_name`(예: `PreToolUse:Write`), `num_hooks`, `duration_ms`, **`num_success`·`num_blocking`·`num_non_blocking_error`·`num_cancelled`**

**`claude_code.hook`의 존재가 강제 메커니즘 조사의 남은 실험 하나에 직접 걸린다.** 아젠다가 "차단 훅의 지연 예산 실측"을 미해결로 남겼는데(§8-3), `duration_ms`가 그 값을 준다. 다만 이 스팬은 **detailed beta 전용**이고 `ENABLE_BETA_TRACING_DETAILED=1` + `BETA_TRACING_ENDPOINT`를 요구한다. 즉 **훅 비용 관측은 두 겹의 베타 게이트 뒤에 있다.**

### 1.5 하네스 설계에 직접 걸리는 제약

문서가 명시한 것 중 grid fin 설계를 실제로 제약하는 것들이다.

1. **`OTEL_*` 환경변수는 서브프로세스로 전파되지 않는다.** 원문: *"Claude Code does **not** pass `OTEL_*` variables to subprocesses (Bash tool, hooks, MCP servers, language servers)."* → **훅과 Bash로 실행되는 모든 것은 자기 계측을 스스로 설정해야 한다.**
2. **그러나 `TRACEPARENT`는 전파된다.** 트레이싱이 활성일 때 Bash·PowerShell이 `TRACEPARENT`를 상속하고, `-p`/Agent SDK 세션은 inbound `TRACEPARENT`/`TRACESTATE`를 읽는다.
3. **따라서 두 벤더를 잇는 경로는 트레이스 컨텍스트 하나뿐이고, 그것은 베타 게이트 뒤에 있다**(§1.1). 이것이 아젠다 §7-4("관찰성을 하네스 안에 두는 것과 밖에 두는 것")에 대한 1차 자료 기반 답이다 — **밖에 두려면 컨텍스트 전파가 필요한데, 그 수단이 하나이고 베타다.**
4. **레코드는 트레이스 exporter 없이도 `trace_id`/`span_id`를 실어 나른다** (Agent SDK·`-p` 세션). 상관은 exporter 설정과 별개다.
5. **재작성 기본값은 전부 "감춤"이다** — 프롬프트·응답·도구 상세·도구 내용·API 본문 모두 opt-in(`OTEL_LOG_USER_PROMPTS`, `OTEL_LOG_ASSISTANT_RESPONSES`, `OTEL_LOG_TOOL_DETAILS`, `OTEL_LOG_TOOL_CONTENT`, `OTEL_LOG_RAW_API_BODIES`). 제3자 플러그인 이름은 `"third-party"`로, 사용자 작성 워크플로우 이름은 `"custom"`으로 치환된다.
6. **`internal_error`는 에러 클래스명과 errno만 담는다** — 메시지·스택은 절대 포함되지 않는다.
7. **카디널리티 제어가 환경변수로 노출된다** — `OTEL_METRICS_INCLUDE_SESSION_ID`(기본 true), `_VERSION`(false), `_ACCOUNT_UUID`(true), `_ENTRYPOINT`(false).
8. **콘텐츠 상한 60 KB** (`CLAUDE_CODE_OTEL_CONTENT_MAX_LENGTH`, 61440 UTF-16 코드 단위), 초과 시 `[TRUNCATED ...]`.

**5번이 [보안 조사 §5.5](security.md)의 정보 유출 축과 만난다.** 텔레메트리를 켜는 것은 그 자체로 유출 결정이 아니지만, `OTEL_LOG_TOOL_DETAILS=1`은 파일 경로와 Bash 명령 전문을 수집기로 보낸다. **재작성 플래그가 전부 기본 off라는 사실이, 켜는 행위를 명시적 선택으로 만든다.**

---

## 2. Codex의 텔레메트리 표면 — 그리고 비대칭이 어디에 떨어지는가

### 2.1 공식 레퍼런스가 주는 것과 주지 않는 것

[Codex 설정 레퍼런스](https://learn.chatgpt.com/docs/config-file/config-reference)(구 `developers.openai.com/codex/config-reference`, 308 리다이렉트) 본문을 확인했다. `[otel]` 절에 있는 것:

| 키 | 값 | 기본 |
|---|---|---|
| `otel.environment` | 문자열 | `dev` |
| `otel.exporter` | `none` \| `otlp-http` \| `otlp-grpc` | — |
| `otel.metrics_exporter` | `none` \| **`statsig`** \| `otlp-http` \| `otlp-grpc` | **`statsig`** |
| `otel.trace_exporter` | `none` \| `otlp-http` \| `otlp-grpc` | — |
| `otel.log_user_prompt` | boolean | `false` |

exporter 하위 키: `.endpoint`, `.headers`, `.protocol`(`binary`/`json`), `.tls.*`. 인접 키로 `log_dir`(기본 `$CODEX_HOME/log`), `history.persistence`(`save-all`/`none`), `analytics.enabled`.

**`metrics_exporter`의 기본값이 `statsig`라는 점이 Claude Code와 다르다.** Claude Code는 전 신호가 opt-in이고 기본 exporter가 없다.

**그리고 레퍼런스는 이벤트 이름과 필드 스키마를 적지 않는다.** 저장소 쪽 `docs/config.md`도 온라인 문서로 넘기는 15줄 스텁이다(GitHub API로 확인). **즉 Claude Code 쪽에 있는 종류의 규격 문서가 Codex 쪽에는 없다.** 이것이 §1과 §2의 분량 차이의 이유이고, 그 자체가 관측 결과다.

### 2.2 이벤트 이름의 실제 출처는 이슈다

[이슈 #33668](https://github.com/openai/codex/issues/33668)의 재현 로그가 공식 문서에 없는 이름들을 담고 있다.

**방출되는 로그/트레이스**: `codex.startup_phase`, `codex.api_request`, `codex.sse_event`, `codex.websocket_request` / `codex.websocket_connect`, `codex.user_prompt`, `codex.turn_ttft`, `codex.conversation_starts`

**토큰 필드 (스팬/로그 속성으로만)**: `input_token_count`, `output_token_count`, `cached_token_count`, `reasoning_token_count`, **`tool_token_count`**

**메트릭**: `codex.turn.token_usage` (히스토그램, `token_type`: input / cached_input / output / reasoning_output)

`tool_token_count`는 Claude Code 쪽에 대응물이 없다(Claude Code는 스팬에 `result_tokens`를 두지만 이벤트 층 토큰 분해에는 도구 항목이 없다).

### 2.3 결손이 하네스의 리뷰어 절반에 정확히 떨어진다

두 이슈가 같은 지점을 8개월 간격으로 가리킨다.

| | #12913 | #33668 |
|---|---|---|
| 개설 | 2026-02-26 | 2026-07-16 |
| 상태 | **closed as completed** (2026-02-28, `etraut-openai`) | **open, 코멘트 0건** (확인 시점 2026-08-02) |
| 버전 | codex-cli 0.105.0 | codex-cli **0.144.3** |
| 주장 | `codex exec`는 메트릭 0건, `codex mcp-server`는 트레이스·로그·메트릭 전부 0건 | `codex exec`가 여전히 `codex.turn.token_usage`를 방출하지 않음 |

#12913의 관측표:

| 모드 | 트레이스 | 로그 | 메트릭 |
|---|:---:|:---:|:---:|
| `codex` (대화형) | ✅ | ✅ | ✅ |
| `codex exec` | ✅ | ✅ | ❌ |
| `codex mcp-server` | ❌ | ❌ | ❌ |

닫힐 때 메인테이너 코멘트는 *"Thanks for the bug report and the great analysis. This will be fixed in the next release."* 이고, 연결된 PR은 **#13083 "Enable analytics in codex exec and codex mcp-server"** 다.

**#33668은 개설 이후 반응이 없다.** GitHub API 기준 `comments: 0`이고 `updated_at`이 개설 시각(2026-07-16T18:53Z)에서 움직이지 않았다. **확인 시점까지 2주 반 동안 메인테이너 확인도 반박도 없다.** #12913이 이틀 만에 응답을 받은 것과 대조된다.

### 2.3.1 왜 수정이 덮지 못했는가 — 출처 감사에서 diff 확인 (2026-08-02 추가)

**초판은 §6-5에서 "수정이 analytics 경로만 건드린 것 아닌가"를 확인 불가한 가설로 남겼다. PR #13083의 diff를 읽어 확인했다.**

PR 본문: *"`codex exec` was not correctly defaulting to Otel metrics to enabled"* / *"default to **enabling analytics** when `codex exec` initializes OpenTelemetry."* 병합 2026-02-28.

변경 파일이 둘이고 `codex exec` 쪽 변경의 실체는 이렇다(`codex-rs/exec/src/lib.rs`, +13/−1).

```rust
+const DEFAULT_ANALYTICS_ENABLED: bool = true;
...
-        codex_core::otel_init::build_provider(&config, env!("CARGO_PKG_VERSION"), None, false)
+        codex_core::otel_init::build_provider(
+            &config, env!("CARGO_PKG_VERSION"), None,
+            DEFAULT_ANALYTICS_ENABLED,
+        )
```

**`build_provider`의 네 번째 인자를 `false`에서 `true`로 바꾼 것이 전부다.** 그리고 함께 추가된 회귀 테스트가 이렇다.

```rust
+    #[test]
+    fn exec_defaults_analytics_to_enabled() {
+        assert_eq!(DEFAULT_ANALYTICS_ENABLED, true);
+    }
```

**테스트가 검사하는 것은 상수의 값이지 메트릭이 실제로 export되는지가 아니다.** 즉 **보고된 버그를 이 회귀 테스트가 잡을 수 없다.** #33668이 5개월 뒤 같은 증상을 재현한 이유가 여기서 설명된다 — 플래그는 켜졌고 `codex.turn.token_usage`의 방출 경로는 손대지 않았다.

**`codex mcp-server` 쪽은 다르다.** `codex-rs/mcp-server/src/lib.rs`가 +92/−19로, PR 본문이 *"added Otel collector to `codex mcp-server`"* 라고 적는다. **컬렉터가 실제로 추가되었다** — 초판 §6-3이 "현재 상태 미확인"으로 남긴 항목이 여기까지는 답을 얻는다(동작 확인은 아니다).

---

**#33668이 "Not a duplicate" 절을 따로 두어 그 수정이 이 지점을 덮지 못했다고 명시한다.** 원문: *"#12913 reported this and was closed via #13083 … Per the repro above, the OTLP `token_usage` metric is still not exported under `codex exec`."* 그리고 대안 경로를 이렇게 적는다 — *"forcing out-of-band parsing of `~/.codex/sessions/**/rollout-*.jsonl` (or scraping the log attributes) to recover per-run token counts."*

> **정정 (2026-08-03, 실험 B5 — [검증·교차리뷰 §7.5](verification-and-cross-review.md)).** 아래 문단은 원래 *"교차 리뷰는 `codex-companion.mjs`를 통해 `codex exec`로 실행된다"* 고 적어 **서로 다른 두 경로를 하나로 합쳤다.** 플러그인 캐시를 직접 읽어 확인한 결과 **`codex-companion`은 `codex app-server`만 spawn하며 `codex exec`를 전혀 호출하지 않는다**(1.0.2·1.0.3 모두, 스크립트 전체에서 `"exec"` 0건). [검증·교차리뷰 §4.1](verification-and-cross-review.md)의 두 경로 구분이 옳았다.
>
> | 경로 | 진입 | 호출 |
> |---|---|---|
> | spec/plan 리뷰 | `adapter-codex-review` (하네스 소유) | **`codex exec -s workspace-write`** |
> | 코드 adversarial 리뷰 | `codex-companion` (외부 플러그인) | **`codex app-server`** |
>
> **따라서 아래 비대칭 논증은 첫 번째 경로에만 적용된다.** #12913의 표는 `codex`(대화형)·`codex exec`·`codex mcp-server` 셋을 다뤘고 **`app-server`는 다루지 않았다** — 두 번째 경로의 텔레메트리 상태는 어느 자료도 말하지 않는다(§6-10에 추가).

**이 결손이 grid fin에 걸리는 이유가 구체적이다.** 기존 하네스의 **spec/plan 리뷰**는 `adapter-codex-review` 스킬을 통해 **`codex exec`** 로 실행된다([검증·교차리뷰 §4.1](verification-and-cross-review.md)). 즉:

- **작성 측(Claude Code)은 메트릭 8종·이벤트 15종·스팬 6종을 방출한다.**
- **spec/plan 리뷰 측(`codex exec`)은 메트릭을 방출하지 않는다.** 토큰 수치는 로그/스팬 속성 안에만 있다. **다만 프로세스 출력에는 있다 — [실험 B5](verification-and-cross-review.md)가 기본 모드 stderr의 `tokens used`와 `--json`의 `turn.completed.usage`를 실증했다.** OTLP 메트릭 결손과 별개의 경로다.

**"Claude 작성 → Codex 리뷰"라는 아젠다 §4의 구조가 관측 가능성 면에서 비대칭이라는 뜻이다.** 리뷰 측 비용을 메트릭 대시보드에서 볼 수 없고, 세션 롤아웃 파일을 out-of-band로 파싱해야 한다.

**그리고 이것이 아젠다가 이미 열어둔 실험 하나에 근거를 준다** — "`codex exec` stdout에서 실패한 도구 호출을 기계적으로 검출"(검증·교차리뷰 §6-5). 그 실험이 stdout 파싱을 상정한 이유가 여기서 설명된다. 다만 #33668은 **로그와 트레이스는 정상 export된다**고 하므로, stdout 파싱보다 OTLP 로그 속성 쪽이 먼저 검토할 경로일 수 있다. 자료가 여기까지만 말한다.

---

## 3. gen_ai 규약 — 무엇을 표준화하고 무엇을 표준화하지 않는가

### 3.1 상태: Development, 릴리스 0건

**저장소가 분리되었다는 사실을 1차 확인했다.** [opentelemetry.io의 gen-ai 페이지](https://opentelemetry.io/docs/specs/semconv/gen-ai/) 본문이 *"GenAI semantic conventions have moved to the OpenTelemetry GenAI semantic conventions repository"* 이고 *"This page has moved and is no longer maintained in this repository"* 라고 적는다.

새 저장소의 [`docs/gen-ai/README.md`](https://github.com/open-telemetry/semantic-conventions-genai) 첫 줄이 **`**Status**: [Development][DocumentStatus]`** 다. GitHub Releases API는 **빈 배열**을 반환한다 — 태그된 릴리스가 아직 없다.

개별 항목도 마찬가지다. 메트릭 12종, 속성 대부분이 `![Development]` 뱃지를 단다. 예외는 다른 규약에서 빌려온 `server.address`·`server.port`·`error.type`으로, 이들만 `![Stable]`이다.

> **2차 자료 정정 1.** 이 조사의 첫 WebSearch 요약은 *"메트릭 like `gen_ai.usage.input_tokens` and `gen_ai.usage.output_tokens`"* 라고 했다. **틀렸다.** 원문 대조 결과 그 둘은 **스팬 속성**이다 — [`docs/gen-ai/gen-ai-spans.md`](https://github.com/open-telemetry/semantic-conventions-genai/blob/main/docs/gen-ai/gen-ai-spans.md)가 추론 스팬의 속성 표에 `Recommended` 등급으로 싣는다. 반면 `docs/gen-ai/gen-ai-metrics.md`의 메트릭 12종 중 토큰 계기는 `gen_ai.client.token.usage` **하나뿐**이다. 아젠다 §12 출처 감사가 지목한 "2차 인용이 실제 결함"의 같은 형태라 여기 적어 둔다.

### 3.2 표준이 정의하는 것

**메트릭 12종** (전부 Histogram):

| 층 | 이름 | 단위 |
|---|---|---|
| 클라이언트 | `gen_ai.client.token.usage` | `{token}` |
| | `gen_ai.client.operation.duration` | `s` |
| | `gen_ai.client.operation.time_to_first_chunk` | `s` |
| | `gen_ai.client.operation.time_per_output_chunk` | `s` |
| 모델 서버 | `gen_ai.server.request.duration` / `time_per_output_token` / `time_to_first_token` | `s` |
| 워크플로우 | `gen_ai.workflow.duration` | `s` |
| **에이전트** | **`gen_ai.invoke_agent.duration`** | `s` |
| | **`gen_ai.invoke_agent.inference_calls`** | `{inference_call}` |
| | **`gen_ai.invoke_agent.tool_calls`** | `{tool_call}` |
| 도구 | `gen_ai.execute_tool.duration` | `s` |

**에이전트 스팬 6종**: Create agent / Invoke agent client / Invoke agent internal / Invoke workflow / **Plan** / Execute tool.

`gen_ai.client.token.usage`의 필수 속성은 `gen_ai.operation.name`, `gen_ai.provider.name`, `gen_ai.token.type`이다. [Anthropic 전용 규약](https://github.com/open-telemetry/semantic-conventions-genai/blob/main/docs/gen-ai/anthropic.md)이 따로 있고, *"`gen_ai.provider.name` MUST be set to `"anthropic"` and SHOULD be provided **at span creation time**"* 를 요구한다.

**표준이 정의하지 않는 것 하나가 중요하다 — 비용 메트릭이 없다.** `claude_code.cost.usage`(USD)에 대응하는 표준 이름이 없으므로, 비용 축은 어느 쪽으로 가든 벤더 고유다.

### 3.3 세 이름 체계 — 이 문서의 핵심 대조

같은 값을 세 곳이 다르게 부른다.

| 개념 | OTel GenAI (표준) | Claude Code | Codex |
|---|---|---|---|
| 입력 토큰 | `gen_ai.usage.input_tokens` | `input_tokens` | `input_token_count` |
| 출력 토큰 | `gen_ai.usage.output_tokens` | `output_tokens` | `output_token_count` |
| 캐시 읽기 | `gen_ai.usage.cache_read.input_tokens` | `cache_read_tokens` | `cached_token_count` |
| 캐시 생성 | `gen_ai.usage.cache_creation.input_tokens` | `cache_creation_tokens` | — |
| 추론 토큰 | `gen_ai.usage.reasoning.output_tokens` | — | `reasoning_token_count` |
| 토큰 메트릭 | `gen_ai.client.token.usage` | `claude_code.token.usage` | `codex.turn.token_usage` |
| 도구 호출 ID | `gen_ai.tool.call.id` | `gen_ai.tool.call.id` ✅ + `tool_use_id` | — |
| 종료 사유 | `gen_ai.response.finish_reasons` | `gen_ai.response.finish_reasons` ✅ + `stop_reason` | — |
| 제공자 | `gen_ai.provider.name` | **`gen_ai.system`** ⚠️ | — |
| 비용 | *(표준 없음)* | `claude_code.cost.usage` | — |

**Claude Code가 gen_ai 규약을 채택한 범위가 정확히 다섯 개다** — `gen_ai.system`, `gen_ai.request.model`, `gen_ai.response.id`, `gen_ai.response.finish_reasons`, `gen_ai.tool.call.id`. 전부 **식별용 필드**이고, **토큰·비용 어느 것도 표준 이름을 쓰지 않는다.**

> **2차 자료 정정 2 — 그리고 더 중요한 것.** 그 다섯 중 `gen_ai.system`은 **폐기된 이름이다.** 메인 semantic-conventions 저장소 레지스트리가 명시한다: *"`gen_ai.system` … ![Deprecated] Replaced by `gen_ai.provider.name`, which has moved to the OpenTelemetry GenAI semantic conventions repository."* 새 GenAI 레지스트리에는 `gen_ai.system`이 없다(`gen_ai.system_instructions`는 별개 속성이다). **즉 Claude Code가 방출하는 유일한 제공자 식별자가 현행 규약에서 폐기된 이름이다.**

**아젠다 §7-2("`gen_ai.*` 시맨틱 컨벤션으로 세션별 토큰·비용을 귀속시키는 방법")에 대한 답은 따라서 부정형이다 — 규약을 경유해서는 안 된다.** 토큰과 비용의 귀속은 벤더 고유 축(`query_source`, `agent.name`, `skill.name`, `plugin.name`, `mcp_server.name`, `mcp_tool.name`)으로만 가능하고, 그 축은 표준에 대응물이 없다. 규약 쪽의 대응 후보는 `gen_ai.agent.name`·`gen_ai.agent.id`·`gen_ai.conversation.id` 정도인데 Claude Code는 이들을 쓰지 않는다(`agent_id`·`parent_agent_id`·`session.id`라는 자체 이름을 쓴다).

**그리고 규약 쪽이 갖고 있고 두 도구 모두 없는 축이 하나 있다** — `gen_ai.invoke_agent.inference_calls`와 `gen_ai.invoke_agent.tool_calls`. **한 번의 에이전트 호출이 몇 번의 추론·도구 호출을 소비했는지를 히스토그램으로 잡는 계기다.** 아젠다 §7-3의 stall 감지가 정확히 이 모양의 신호를 요구한다. 자료 대조 결과는 §6-2에 적는다.

---

## 4. 기록의 소비 — 자동 실패 귀속의 정확도 상한

아젠다 §7-5가 남긴 문제("기록은 이미 하고 있으나 그것을 읽는 단계가 파이프라인에 없다")의 **소비 쪽**에 관한 유일한 피어리뷰 자료다.

[Zhang, Yin, Zhang 외 8인, *Which Agent Causes Task Failures and When? On Automated Failure Attribution of LLM Multi-Agent Systems*](https://arxiv.org/abs/2505.00212) (arXiv 2505.00212, 2025-04-30 제출, ICML 2025).

### 4.1 수치

논문은 **Who&When** 데이터셋을 만든다 — *"extensive failure logs from 127 LLM multi-agent systems with fine-grained annotations linking failures to specific agents and decisive error steps."* 그 위에서 자동 귀속 방법 세 가지를 평가한 결과:

| 과제 | 최고 정확도 |
|---|---:|
| 실패 책임 **에이전트** 식별 | **53.5%** |
| 실패 **단계** 특정 | **14.2%** |

그리고 두 가지 단서가 붙는다 — *"with some methods performing below random"*, *"Even SOTA reasoning models, such as OpenAI o1 and DeepSeek R1, fail to achieve practical usability."*

### 4.2 이 수치가 무엇을 제약하는가

**"로그를 모델에 넘겨 원인을 짚게 한다"는 형태의 소비 설계에 상한이 있다는 뜻이다.** 특히 **단계 특정 14.2%** 가 낮다. 하네스에서 유용한 소비는 대개 "어느 단계에서 어긋났는가"를 요구하는데, 그것이 가장 안 되는 항목이다.

**아젠다 §0이 든 계산적/추론적 구분이 여기서도 갈린다.**

| 소비 유형 | 예 | 상한 |
|---|---|---|
| **계산적** | `tool_result.success=false` 집계, `duration_ms` 분포, `tool_decision.source=hook` 빈도 | 정의상 정확 |
| **추론적** | 로그를 읽혀 "왜 실패했는가"를 얻기 | **53.5% / 14.2%** |

**§1.3에서 본 대로 계산적 소비의 재료는 이미 구조화되어 방출된다.** `success`, `duration_ms`, `error_type`, `decision`, `source` 전부 열거형이거나 수치다. **선행 조사가 "소비가 없다"고 진단한 지점에서, 자료가 가리키는 것은 추론적 소비를 먼저 놓을 이유가 약하다는 것이다.**

### 4.3 한계

- **다중 에이전트 시스템이 대상이고 코딩 하네스가 대상이 아니다.** 127개 시스템의 구성이 grid fin과 같다는 근거는 없다.
- 2025년 4월 제출이다. §4.1의 수치는 그 시점 방법과 모델 기준이다.
- **초록만 확인했다.** 세 방법의 구체 내용과 비용은 읽지 않았다.

---

## 5. 적용 대상 확인 — 지금 무엇이 관측되는가 (보조)

**이 절은 위 자료가 이 프로젝트에 해당하는지 확인하는 용도다.** grid fin은 아직 코드가 없으므로 참조 원본인 기존 하네스를 실측했다.

### 5.1 텔레메트리는 어디에도 켜져 있지 않다

| 확인 대상 | 결과 |
|---|---|
| `CLAUDE_CODE_ENABLE_TELEMETRY` | `~/.claude/settings.json`·하네스 `src/` 어디에도 없음 |
| `OTEL_EXPORTER_*` | 동일하게 없음 |
| `~/.codex/config.toml`의 `[otel]` | 절 자체가 없음 |
| 저장소 내 `otel` 문자열 | `references/` 아래 제3자 자료에만 존재 |

설치 버전은 **Claude Code 2.1.220**, **codex-cli 0.142.4** 다. 후자는 §2.3의 두 이슈가 각각 결손을 확인한 **0.105.0과 0.144.3 사이**에 있다. 두 확인 사이에 결손이 사라졌다 되살아났다고 볼 근거가 없으므로 해당 버전으로 추정하되, **직접 재현하지는 않았다.**

**즉 §1~§3의 자료 전부가 아직 미사용 표면을 기술한다.** 관측 부재는 결손이 아니라 미착수다.

### 5.2 자체 기록은 있으나 실패·지연을 담지 않는다

`session-logger.js`가 유일한 자체 관찰성 자산이다. **60줄**, `PostToolUse` 훅으로 등록되어 `sessions/<date>.jsonl`에 append한다. (`src/.claude/`와 저장소 루트 `.claude/`에 바이트 단위로 동일한 사본이 있다. 전자가 배포 원본이고 후자가 하네스 자신에게 적용된 사본으로 보이나 확인하지 않았다.)

기록 필드는 넷이다 — `ts`, `tool`, 그리고 조건부로 `file`, `topic`.

**같은 사건에 대해 Claude Code의 `claude_code.tool_result`가 방출하는 것과 대조하면:**

| 필드 | `session-logger` | `claude_code.tool_result` |
|---|:---:|:---:|
| 타임스탬프 | ✅ `ts` | ✅ `event.timestamp` |
| 도구 이름 | ✅ `tool` | ✅ `tool_name` |
| 파일 경로 | ✅ `file` | `OTEL_LOG_TOOL_DETAILS=1` 필요 |
| 토픽 | ✅ `topic` (하네스 고유) | — |
| **성공 여부** | ❌ | ✅ `success` |
| **소요 시간** | ❌ | ✅ `duration_ms` |
| **오류 종류** | ❌ | ✅ `error_type` |
| **호출 ID** | ❌ | ✅ `tool_use_id` |
| 입출력 크기 | ❌ | ✅ `tool_input_size_bytes` / `tool_result_size_bytes` |
| 상관 키 | ❌ | ✅ `prompt.id`, `event.sequence` |

**§4.2가 "계산적 소비의 재료는 이미 있다"고 했는데, 그 재료 넷(`success`·`duration_ms`·`error_type`·`tool_use_id`)이 자체 기록에는 전부 없다.** 그리고 기록에 상관 키가 없어 항목 간 연결이 불가능하다.

> **정정 — 실제로는 더 나쁘다 (2026-08-03, [실험 C §10.5](enforcement-mechanisms.md)).** 위 표는 `tool`·`file`이 **기록된다**고 적었으나, cygnus의 실측 로그 **13,342건 전수**를 확인한 결과 **`tool` 값이 전부 `"unknown"`이고 `file`은 존재율 0%다.**
>
> ```json
> {"ts":"2026-07-21T01:01:35.253Z","tool":"unknown","topic":"missions-crud"}
> ```
>
> `${CLAUDE_TOOL_NAME}`·`${CLAUDE_TOOL_INPUT_FILE_PATH}`가 치환되지 않아 스크립트 기본값만 남았다. **실제로 남은 것은 타임스탬프와 토픽(94.4%)뿐이며, 이 기록으로 할 수 있는 것은 호출 횟수를 세는 것이 거의 전부다.** 즉 이 절의 진단("성공·지연·오류가 없다")보다 한 단계 아래다 — **무엇을 했는지도 없다.**

`topic`은 반대 방향이다 — 벤더 텔레메트리에 없는 하네스 고유 축이고, [상태·연속성 조사](state-and-continuity.md)가 "머지 커밋 21건 = 토픽 21개"로 확인한 그 단위다. **`OTEL_RESOURCE_ATTRIBUTES`에 그 축을 실을 수 있다**(§1.5-7의 카디널리티 제어 대상이며, 공백 불가·퍼센트 인코딩 필요라는 형식 제약이 문서에 명시되어 있다).

### 5.3 훅은 등록되어 있고 관측되지 않는다

하네스 `settings.json`이 `SessionStart`·`PostToolUse`·`Stop`을 등록한다. [강제 메커니즘 조사](enforcement-mechanisms.md)가 훅 9개 중 차단 게이트 0개를 실측한 그 배치다. **훅의 실행 결과(`num_blocking`·`num_cancelled`·`duration_ms`)를 볼 수 있는 곳은 §1.4의 `claude_code.hook` 스팬뿐이고, 그것은 두 겹 베타 게이트 뒤에 있으며 지금 꺼져 있다.**

---

## 6. 자료가 답하지 않는 것

1. **stall 감지 규칙.** §3.2가 보인 대로 규약에는 `gen_ai.invoke_agent.inference_calls`·`tool_calls`가 있지만 **두 도구 모두 방출하지 않는다.** 두 도구에서 얻을 수 있는 재료는 `claude_code.active_time.total`(`type`: `user`/`cli`), `event.sequence`, `interaction.duration_ms`, 도구별 `duration_ms`, `claude_code.tool.blocked_on_user`, `codex.turn_ttft` 정도다. **이 재료로 "루프에 빠졌다"를 판정하는 임계나 규칙을 주는 신뢰 가능한 자료를 찾지 못했다.** 아젠다 §7-3이 든 유일한 참고는 팟캐스트다.
2. **병렬 세션 fleet 관찰.** 위와 같은 이유로 미해결이다. `session.id`가 기본 포함되고 카디널리티 제어가 노출되어 있다는 것까지가 자료가 주는 전부다.
3. **`codex mcp-server`의 현재 상태.** ~~어느 자료도 말하지 않는다.~~ **출처 감사(2026-08-02)에서 부분 해소 — §2.3.1 참고.** PR #13083이 `mcp-server`에 Otel 컬렉터를 실제로 추가했다(+92/−19). **다만 그것이 동작하는지, 어떤 신호를 방출하는지는 여전히 미확인이다.** #33668은 `codex exec`만 재검증했다.
4. **Codex의 이벤트 필드 전량.** §2.2는 이슈 재현 로그에서 추출한 것이라 **관측된 것의 목록이지 규격의 목록이 아니다.** 방출되지만 그 재현에 안 나타난 이벤트가 있을 수 있다.
5. **`statsig` 기본값이 무엇을 어디로 보내는가.** ~~그리고 #12913의 수정이 그쪽만 고친 것인가.~~ **뒷부분은 출처 감사(2026-08-02)에서 확인됨 — §2.3.1.** PR diff가 `build_provider`의 analytics 인자를 `false`→`true`로 바꾼 것이 전부임을 보인다. **남는 것은 앞부분이다** — `otel.metrics_exporter`의 기본값 `statsig`가 무엇을 어디로 보내는지 레퍼런스가 설명하지 않는다. [보안 조사 §5](security.md)의 유출 축에 걸린다.
6. **베타 게이트의 안정성.** `CLAUDE_CODE_ENHANCED_TELEMETRY_BETA`·`ENABLE_BETA_TRACING_DETAILED`가 언제 정식이 되는지, 이름이 유지되는지 문서가 말하지 않는다. **§1.5-3의 결론(두 벤더를 잇는 유일한 경로가 베타)이 여기 걸려 있다.**
7. **`claude_code.hook` 스팬의 비용.** detailed beta가 매 훅마다 스팬을 만든다면 그 자체가 오버헤드다. 아젠다의 "차단 훅 지연 예산 실측" 실험이 이 스팬을 쓴다면 **관측 도구가 관측 대상을 바꾸는지**를 먼저 확인해야 하는데 자료가 없다.
8. **로그와 트레이스의 이중 수집 비용.** Codex는 `exporter`(로그)와 `trace_exporter`를 따로 두고 엔드포인트도 따로다. 둘 다 켜는 것의 비용을 자료가 말하지 않는다.
9. **`rollout-*.jsonl` 파싱 경로의 안정성.** #33668이 대안으로 든 것인데, 그 파일 형식이 규격인지 내부 구현인지 확인하지 못했다. **다만 [실험 B5](verification-and-cross-review.md)가 더 간단한 경로를 실증했다** — `codex exec --json`의 `turn.completed.usage`.
10. **`codex app-server`의 텔레메트리 상태.** §2.3의 정정 참고. **코드 adversarial 리뷰 경로가 이 표면인데 #12913·#33668 어느 쪽도 다루지 않는다.** 대화형 CLI와 같은 프로세스 계열인지, `exec`처럼 결손이 있는지 불명이다.
10. **실패 귀속 논문의 세 방법.** §4가 초록만 확인했으므로, 53.5%/14.2%를 낸 방법이 로그 전량을 넣는 것인지 구조화 입력을 쓰는 것인지 모른다. **구조화된 텔레메트리(§1.3)를 입력으로 쓰면 수치가 달라지는지가 정확히 미확인 지점이다.**

---

## 부록. 조사 방법 및 한계

**방법**

- WebFetch 5회 — Claude Code Monitoring 공식 문서 전문, Codex 설정 레퍼런스(308 리다이렉트 추적), opentelemetry.io gen-ai 페이지, GenAI 규약 저장소 README, arXiv 2505.00212 초록
- GitHub API 15회 — `openai/codex` 이슈 #12913·#33668의 본문·코멘트·타임라인, `docs/` 목록과 `config.md` 원본, `open-telemetry/semantic-conventions-genai`의 README·메트릭·**모델 스팬**·에이전트 스팬·Anthropic 규약·속성 레지스트리·릴리스 목록, `open-telemetry/semantic-conventions`의 속성 레지스트리(`gen_ai.system` 폐기 확인)
- WebSearch 3회 — 자료 위치 파악용. **본문 근거로 쓰지 않았다**(§3.1의 정정 참고)
- 하네스 실측(§5, 보조) — 텔레메트리 설정 4곳, `session-logger.js` 전문, 훅 등록, 설치 버전 2종

**한계**

- **Codex 쪽 자료의 등급이 Claude Code 쪽보다 낮다.** §2.2의 이벤트 이름은 공식 규격이 아니라 **공개 이슈의 재현 로그**에서 나왔다. 재현 절차와 환경이 적혀 있어 검증 가능한 형태이지만, 벤더가 보증한 목록이 아니다. **§2의 결론(비대칭)은 이 등급 차이 자체에도 부분적으로 근거한다** — 문서가 없다는 것이 관측의 일부다.
- **#33668은 열린 이슈이고 코멘트가 0건이다.** 재현 절차와 환경이 적힌 1인 보고이며, **메인테이너의 확인도 반박도 없다** — 즉 "미해결로 확인됨"이 아니라 "반박되지 않음"이다. 로컬 설치본(0.142.4)에서 직접 재현하지 않았다.
- **#12913을 닫은 PR #13083의 본문과 diff를 읽지 않았다.** §6-5가 그 공백 위에 서 있다. 무엇이 실제로 고쳐졌는지 확인하면 §2.3의 비대칭 서술이 더 정확해지거나 뒤집힐 수 있다.
- **어느 텔레메트리도 실제로 켜서 관측하지 않았다.** §1~§3은 전부 문서·규격·타인의 재현 로그다. **§1.2~§1.4의 이름과 속성이 설치본 2.1.220에서 실제로 방출되는지 확인하지 않았다.**
- **GenAI 규약은 `main` 브랜치를 읽었다.** 태그된 릴리스가 없어 고정 참조점이 없고, 규약 자체가 Development 등급이라 **이름이 바뀔 수 있다.** §3.3의 표는 확인 시점 스냅샷이다.
- **arXiv 2505.00212는 초록만 확인했다.** 피어리뷰(ICML 2025)를 거친 자료이나 53.5%·14.2%는 초록 기재값이고 재현하지 않았다.
- **§7-3(stall 감지)과 §7-4의 fleet 축에 답을 주는 자료를 찾지 못했다.** 아젠다가 든 참고(팟캐스트, walkinglabs 강의 11)는 이 문서가 유지하는 등급에 미치지 못해 쓰지 않았다. **없는 근거를 만들지 않기 위해 §6-1·§6-2로 남겼다.**
- **§5는 관측의 부재가 아니라 미착수를 확인했다.** 텔레메트리가 꺼져 있는 것은 결함이 아니다. 결함이라 부를 수 있는 것은 §5.2의 대조 — 자체 기록이 있는데 성공·지연·오류를 담지 않는다는 점 하나다.
