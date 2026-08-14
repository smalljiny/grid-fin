# 워크트리 간 상태·설정 공유 — 실증 사례 조사

**최초 작성**: 2026-08-03
**최종 수정**: 2026-08-03
**대상 프로젝트**: grid fin (신규 개인용 개발 하네스)
**조사 계기**: *"워크트리 기반으로 동작하는 하네스가 세션 간 데이터/설정 공유를 위해 DB나 원격 저장소를 사용하는 케이스 또는 방법"* 의 실증 사례 확보
**조사 도구**: Exa `/search` 12회, Firecrawl `/v1/scrape` 13회 (skill-registry `[search-adapter]` 경유)
**성격**: 조사. grid fin의 저장 매체 선택은 하지 않는다. §9는 관측을 grid fin 축으로 재배열한 것이며 결정이 아니다.

[state-and-continuity.md](state-and-continuity.md) §1.3이 남긴 문제 — *"워크트리 N개를 돌리면 상태 보유자가 8 + N×2 종이 되고, 그중 어느 것도 git이 조율하지 않는다"* — 에 대한 **외부 실물의 답**을 모은다. 그 문서는 cygnus 내부만 봤고, 이 문서는 같은 문제를 이미 겪은 12개 외부 시스템이 무엇을 선택했는지를 본다.

관련 문서
- [state-and-continuity.md](state-and-continuity.md) §1.3 — 워크트리별 `dev-context.json`이 main hub와 stale 분기하는 문제
- [repository-layout.md](repository-layout.md) §8.3 — `.claude/settings.json` 비상속. 설정 배포 축에서 이 문서 §6과 맞물린다
- [harness-distribution.md](harness-distribution.md) — 배포 단위와 핀

---

## 0. 조사 요약

### 0.1 두 문장

**워크트리 기반 하네스 12종을 확인한 결과, "워크트리를 격리 단위로 쓰되 세션 상태는 워크트리 바깥의 단일 원장에 둔다"가 지배적 패턴이고, 그 원장의 매체는 로컬 SQLite(Crystal·Vibe Kanban), git refs/notes(container-use), 경로 규약 JSONL(Claude Code), 원격 서버(Amp·Vibe Kanban Cloud) 넷으로 갈린다.** 그리고 **매체 선택보다 더 큰 실패 요인은 "워크트리를 무엇으로 식별하는가"** 였다 — Claude Code의 실제 버그 3건이 전부 여기서 나왔다.

### 0.2 관측

| # | 관측 | 근거 등급 | 위치 |
|---|---|---|---|
| 1 | **워크트리 안에 세션 상태를 두는 시스템을 하나도 찾지 못했다.** 1차 자료로 확인한 7종 전부 상태를 워크트리 바깥(`~/.crystal`, `~/.claude/projects`, `~/.config/container-use`, 앱 데이터 디렉터리, 원격 서버)에 둔다 | **1차 (공식/코드)** | §1 |
| 2 | **Crystal은 13개 테이블의 SQLite 단일 원장을 두고, 워크트리는 `git worktree add`로 만든 실행 샌드박스로만 쓴다.** 대화 메시지·터미널 출력·diff까지 전부 DB (DB 파일 경로는 문서에 없음 — §2.1 주) | **1차 (레포 CLAUDE.md)** | §2.1 |
| 3 | **Vibe Kanban은 SQLite(`db.v2.sqlite`) + SQLx 컴파일타임 검증 + 자동 마이그레이션이고, workspace(=워크트리)는 DB의 한 레코드다** | 2차 (DeepWiki, 코드 라인 링크 동반) | §2.2 |
| 4 | **그런데 Vibe Kanban은 실행 로그를 SQLite에서 플랫 파일로 되돌렸다** — 성능 이유로 명시. 원장에 넣을 것과 넣지 말 것의 경계에 대한 실물 답 | 2차 (DeepWiki, 코드 라인 링크 동반) | §2.2 |
| 5 | **container-use는 DB를 쓰지 않는다.** 환경 = git 브랜치, 컨테이너 상태 스냅샷 = **git notes(`container-use-state` ref)**, 저장소 = `~/.config/container-use/`의 bare repo + 워크트리. 상태 공유 매체가 git 그 자체 | **1차 (레포 README)** | §3 |
| 6 | **Claude Code는 경로 규약 파일 저장소를 쓰면서 "레포의 모든 워크트리"를 1급 개념으로 인지한다** — 세션 피커 `Ctrl+W`로 전 워크트리 확대, 이름 기반 resume이 레포+워크트리 범위로 해석, 다른 워크트리 세션을 그 디렉터리에서 재개 | **1차 (공식 문서)** | §4.1 |
| 7 | **그 방식의 실패가 실물로 기록돼 있다 — issue #33665.** 서브시스템마다 프로젝트 키를 `cwd`에서 뽑는 쪽과 `git rev-parse --git-common-dir`에서 뽑는 쪽으로 갈려, 세션은 저장되는데 `/resume`이 못 찾는다. **워크트리 식별 키를 경로 문자열로 유도한 대가** | **1차 (공식 저장소 이슈, has-repro 라벨)** | §4.2 |
| 8 | 같은 축의 이슈가 둘 더 있다 — #14036(`/resume`이 디렉터리 필터를 안 해 워크트리 격리가 깨짐), #38089(`--resume`이 원래 cwd를 요구) | **1차 (공식 저장소 이슈)** | §4.2 |
| 9 | **Amp는 스레드를 전량 서버에 둔다.** 로컬 CLI가 워크트리에서 돌아도 대화 상태는 ampcode.com이 소유하고, `amp threads new/continue/fork/share`가 그 위의 어휘 | **1차 (공식 가이드 레포)** + 3자 진술 | §5.1 |
| 10 | **Vibe Kanban Cloud는 로컬 SQLite와 원격 PostgreSQL을 병존시키고 ElectricSQL로 동기화한다.** 로컬 project를 `set_remote_project_id`로 원격에 링크 — 로컬 우선 + 선택적 미러의 실물 | 2차 (DeepWiki, 코드 라인 링크 동반) | §5.2 |
| 11 | **git config는 기본적으로 모든 워크트리에 공유된다.** 워크트리별 설정은 `extensions.worktreeConfig`를 켠 뒤 `config.worktree`에만 들어간다 — **설정 공유는 DB 없이 이미 해결된 문제** | **1차 (git 공식 문서)** | §6 |
| 12 | **단 그 확장은 되돌리기 어렵다** — 켜면 `core.bare`/`core.worktree` 예외가 사라져 main worktree의 `config.worktree`로 옮겨야 하고, **구버전 git은 해당 저장소 접근을 거부한다** | **1차 (git 공식 문서)** | §6 |
| 13 | **진짜 안 따라오는 것은 gitignore된 것들이다**(`.env`, `.venv`, `node_modules`). 이를 위해 전용 도구가 최소 6종 존재 — 복사파·심볼릭파·렌더링파로 갈린다 | 다수 자가출판 + 레포 | §7 |
| 14 | **`.worktreeinclude`가 사실상 표준이 돼 있다.** Conductor는 자체 설정(`.conductor/settings.toml`의 `file_include_globs`)을 두고도 리터럴 `.worktreeinclude`를 함께 읽으며 **충돌 시 `.worktreeinclude`를 우선**시킨다. 이유도 명시 — *"이미 그 파일을 읽는 워크트리 도구를 쓰는 프로젝트를 위해"*. Claude Code도 같은 파일명을 쓴다 | **1차 (양쪽 공식 문서)** | §7.2 |
| 14b | 정책 수준의 수렴이 더 강하다 — 양쪽 다 **"git이 이미 무시하는 파일만" 복사**하고, 복사로 안 되는 것은 **setup script**로 넘긴다 | **1차 (양쪽 공식 문서)** | §7.2 |
| 15 | **여러 워크트리 세션이 한 SQLite를 칠 때의 실물 함정이 코드 주석으로 남아 있다** — Vibe Kanban은 SQLite update hook이 커밋 전에 발화해 다른 커넥션에서 조회가 깨지므로 **의도적으로 트랜잭션을 회피**한다 | **1차 (레포 코드 주석)** | §8.2 |
| 16 | **Claude Code는 워크트리 진입/이탈 시 트랜스크립트를 새 cwd 하위로 옮긴다**(`/cd`와 동일 규칙). 단 `WorktreeCreate` 훅으로 만든 워크트리는 트랜스크립트가 시작 디렉터리에 남는다 — **하네스가 만든 워크트리와 사용자가 만든 워크트리의 취급이 다르다** | **1차 (공식 문서)** | §4.1 |

### 0.3 근거 등급 표기

| 등급 | 의미 | 이 문서에서의 취급 |
|---|---|---|
| **1차 (공식/코드)** | 공식 문서, 저장소 README/CLAUDE.md, 소스 코드, 공식 저장소 이슈 | 그대로 인용 가능 |
| 2차 (DeepWiki) | AI 생성 위키. **단 문장마다 소스 코드 라인 링크가 붙어 있다** | 구조적 주장만 채택. 수치·성능 주장은 코드 확인 전까지 보류 |
| 자가출판 | 개인 블로그, 소규모 레포 README | 존재 증명으로만. 설계 근거로 인용 금지 |

---

## 1. 판별 축 — 무엇을 공유하는가 × 어디에 두는가

사례를 나열하면 일화가 되고, 두 축으로 배열하면 판단 재료가 된다.

### 1.1 공유 대상 5종

| 대상 | 워크트리를 넘어야 하는가 | 이유 |
|---|---|---|
| **세션/대화 트랜스크립트** | 넘어야 함 | 워크트리는 임시. 대화는 워크트리보다 오래 산다 |
| **설정·시크릿**(`.env`, 자격증명) | 넘어야 함 | gitignore돼 있어 `git worktree add`가 안 옮긴다 |
| **의존성 캐시**(`node_modules`, `.venv`) | 성능상 넘는 게 유리 | 정확성 문제는 아님. 워크트리마다 재설치는 동작은 한다 |
| **작업 큐·오케스트레이션 상태** | 넘어야 함 | 워크트리 N개를 조율하는 주체가 워크트리 안에 있을 수 없다 |
| **에이전트 메모리·규칙** | 넘어야 함 | 학습이 워크트리와 함께 삭제되면 안 된다 |

### 1.2 저장 매체 5종 × 실물 배치

| 시스템 | 트랜스크립트 | 설정·시크릿 | 의존성 | 오케스트레이션 |
|---|---|---|---|---|
| **Crystal** (Electron) | 로컬 SQLite (경로 미명시) | JSON `~/.crystal/config.json` | 세션 생성 스크립트 | 로컬 SQLite + Bull 큐(옵션 Redis) |
| **Vibe Kanban** (Rust) | 로컬 SQLite `db.v2.sqlite` (**로그는 플랫 파일**) | DB + setup script | setup script | 로컬 SQLite |
| **Vibe Kanban Cloud** | ↑ + **원격 PostgreSQL** | ↑ | ↑ | **PostgreSQL + ElectricSQL 동기화** |
| **container-use** | **git 브랜치 + git notes** | 컨테이너 이미지 | 컨테이너 이미지 | git refs (`container-use/` remote) |
| **Claude Code** | 경로 규약 JSONL `~/.claude/projects/<key>/` | 설정 파일 계층 + `.worktreeinclude` | 사용자 몫 | 없음(피커가 대신) |
| **Amp** | **원격 서버 (ampcode.com)** | 로컬 | 로컬 | 서버 스레드 |
| **Conductor** | 워크스페이스에 귀속(UI) | **Files to copy** + setup script | setup script | 앱 |
| **claude-squad** | — (tmux 세션이 보유) | — | — | **JSON 파일** `state.json` / `instances.json` |

**읽는 법**: 한 시스템도 단일 매체로 통일하지 않았다. 전부 혼합이고, **혼합의 경계가 "쓰기 빈도"와 "크기"에서 갈린다** — Vibe Kanban이 로그만 DB에서 빼낸 것(§2.2)이 그 경계를 가장 선명하게 보여준다.

---

## 2. 패턴 A — 로컬 SQLite 단일 원장

가장 흔한 패턴. 워크트리는 실행 샌드박스일 뿐이고, "무슨 세션이 있고 어디까지 진행됐나"는 전부 DB가 안다.

### 2.1 Crystal — 13개 테이블

> *"Crystal is a fully-implemented Electron desktop application for managing multiple AI code assistant instances (Claude Code and Codex) against a single directory using git worktrees."*
> — [stravu/crystal CLAUDE.md](https://github.com/stravu/crystal/blob/main/CLAUDE.md) (Firecrawl `/v1/scrape`)

**전제 하나**: Crystal은 이미 후속 제품 **Nimbalyst**로 승계됐다(레포 설명이 *"(Crystal is now Nimbalyst)"*). 아래 스키마는 **선행 제품의 것**이고, **Nimbalyst의 저장 방식은 이 조사에서 확인하지 않았다.** 설계 참조로는 유효하나 "현재 이렇게 하고 있다"로 읽으면 안 된다.

레포 CLAUDE.md의 Data Persistence 절이 스키마를 그대로 적어둔다.

| 테이블 | 내용 |
|---|---|
| `projects` | 프로젝트 설정, 경로, 커밋 설정 |
| `sessions` | 세션 메타 — `active_panel_id`, `folder_id`, `tool_type`(`claude`\|`codex`\|`none`), 상태 |
| `session_outputs` | 터미널 출력 이력 (panel_id 링크) |
| `conversation_messages` | 대화 이력 + 툴 호출/결과 (panel_id 링크) |
| `execution_diffs` | 실행별 git diff |
| `prompt_markers` | 프롬프트 내비게이션 마커 + 완료 타임스탬프 |
| `tool_panels` | 패널 설정·상태·메타·설정(JSON) |
| `folders` | 세션 조직용 계층 폴더(`parent_folder_id` 중첩) |
| `project_run_commands` | 프로젝트당 복수 실행 명령 |
| `claude_panel_settings` | Claude 전용 패널 설정 (**legacy** — `tool_panels.settings`로 이관 중) |
| `ui_state` / `user_preferences` / `app_opens` | UI 상태, 사용자 설정, 실행 추적 |

부속 사실:
- **`~/.crystal`이 최초 실행 시 자동 생성**되고 설정은 `~/.crystal/config.json`(JSON), 세션 데이터는 SQLite로 **매체가 갈린다**. 단 **DB 파일의 경로는 CLAUDE.md에 명시되지 않았다** — 소스 트리에 `database/migrations/`가 있다는 것까지가 확인된 사실이고, DB가 `~/.crystal` 안에 있다는 것은 **추론이다**
- **이중 마이그레이션 시스템**(TypeScript + SQL)을 스키마 진화용으로 운영
- 엔진은 Better-SQLite3 — **동기 API**. Electron 메인 프로세스에서 이벤트 루프를 막지 않기 위한 통상적 선택이 아니라, 반대로 동기성을 선택한 것
- 워크플로 순서가 문서에 명시: ① 프롬프트+템플릿 → ② `git worktree add` → ③ node-pty로 워크트리에서 Claude Code 프로세스 기동 → ④ **세션 메타·출력을 SQLite에 저장** → ⑤ IPC 스트리밍

> **grid fin 축 함의**: 대화 메시지와 터미널 출력까지 DB에 넣은 사례다. §2.2의 Vibe Kanban은 정확히 그 부분을 DB에서 빼냈다. **같은 문제에 반대 답을 낸 두 실물이 있다.**

### 2.2 Vibe Kanban — SQLite + SQLx, 그리고 로그를 되돌린 결정

> *"The database service initializes a connection pool to `db.v2.sqlite` located in the application asset directory. It automatically runs migrations defined in `crates/db/migrations` upon startup."*
> — [DeepWiki: Database Models and Queries](https://deepwiki.com/BloopAI/vibe-kanban/4.5-database-models-and-queries) (Firecrawl `/v1/scrape`)

구조:
- Rust 구조체(`crates/db/src/models/`)로 모델 정의 → **`ts-rs`로 TypeScript 타입 자동 노출**. 백엔드 스키마가 프런트 타입의 단일 원천
- `query_as!` / `query_scalar!` 매크로로 **컴파일타임에 SQL↔구조체 일치 검증**
- **workspace = 한 태스크 시도의 격리 실행 환경**(git 워크트리 + 자체 브랜치)이고, 그 자체가 DB 레코드

**되돌린 결정 — 이 조사에서 가장 값나가는 관측:**

> *"Vibe Kanban uses a high-performance logging system where logs were historically in SQLite but are migrated to flat files for performance."*

즉 **실행 로그를 SQLite에 넣었다가 성능 문제로 플랫 파일로 옮겼다.** 부수 관측 둘:
- 로그 삭제 후 공간 회수를 위해 **주요 마이그레이션 시 `VACUUM`** 을 돌린다 — DB에 대용량 append를 하면 운영 부담이 생긴다는 증거
- 마이그레이션 스트리밍 전용 코드(`stream_distinct_processes`, `stream_log_lines_by_execution_id`)를 별도로 두어야 했다

**운영 함정 하나 더**: Windows에서 줄바꿈 차이로 **마이그레이션 체크섬 불일치**가 나서 이를 처리하는 로직이 따로 있다. 크로스 플랫폼 SQLite 마이그레이션의 실물 비용.

### 2.3 경량 대안 — claude-squad는 JSON 파일이다

```go
const (
    StateFileName     = "state.json"
    InstancesFileName = "instances.json"
)
```
— [smtg-ai/claude-squad `config/state.go`](https://github.com/smtg-ai/claude-squad/blob/a4ab6988/config/state.go) (Exa `/search`, 코드 본문 반환)

`InstanceData`를 JSON 직렬화해 설정 디렉터리에 저장한다. tmux 세션 + git 워크트리 이중 격리를 쓰면서도 **DB를 도입하지 않았다.** 상태가 "인스턴스 목록"뿐이면 SQLite가 필요 없다는 반례.

> **판별선**: Crystal/Vibe Kanban은 **대화·출력·diff 이력**을 보관하고, claude-squad는 **살아있는 인스턴스 목록**만 보관한다. 전자는 시계열 append가 있고 후자는 없다. **append가 있으면 DB, 없으면 JSON** 이 12종에서 관측된 경계다.

---

## 3. 패턴 B — git 자체를 저장소로: container-use

DB를 안 쓰는 유일한 진지한 사례. dagger가 만들었고 별 3.9k.

> *"An environment is an isolated, containerized development workspace that combines Docker containers with Git branches to provide agents with safe, persistent workspaces."*
> — [dagger/container-use `environment/README.md`](https://github.com/dagger/container-use/blob/main/environment/README.md) (Firecrawl `/v1/scrape`)

환경 생성 시 벌어지는 일 (README 원문 순서):

1. 소스 레포에 **새 git 브랜치** 생성 (예: `env-name/adverb-animal`)
2. `~/.config/container-use/repos/<project>/` 안에 **container-use 리모트 브랜치** 구성
3. `~/.config/container-use/worktrees/<project>/` 에 **그 브랜치의 워크트리 사본** 구성

상태 저장:

> *"Container state snapshots are stored as Git notes using `container-use-state` ref"*
> *"State Recovery: Container states stored in Git notes for reconstruction"*

즉 **git notes가 곧 상태 DB**다. 컨테이너의 LLB 정의(Dagger)가 브랜치 히스토리 + notes로부터 재구성된다. README가 이 성질을 명시적으로 주장한다:

> *"Each environment is just a Git branch that your source repo tracks on the container-use/ remote. You can inspect any environment's work using standard Git commands, and the container state can always be reconstructed from an environment branch's Git history and notes."*

구조 요약: **브랜치**(논리적 환경) → **워크트리**(파일시스템 구현) → **컨테이너**(실제 실행). 그리고 `~/.config/container-use/` 아래의 bare 리포·워크트리는 README가 스스로 *"plumbing to make the Git operations work with minimal modifications to your source repository"* 라고 부른다 — **사용자 레포를 오염시키지 않기 위한 별도 git 저장 공간**.

> **grid fin 축 함의**: 워크트리 상태를 워크트리 밖에 두되 새 저장 기술을 도입하지 않는 경로가 실재한다. 대가는 (a) git notes는 기본적으로 push/fetch되지 않아 refspec을 직접 다뤄야 하고, (b) 질의가 불가능하다 — "실패한 세션만 골라줘"를 git notes로 하려면 전부 순회해야 한다. **감사·재현에는 강하고 조회에는 약하다.**

---

## 4. 패턴 C — 경로 규약 파일 저장소: Claude Code, 그리고 그 실패

### 4.1 규약과 워크트리 인지

> *"By default, transcripts are stored as JSONL at `~/.claude/projects/<project>/<session-id>.jsonl`, where `<project>` is your working directory path with non-alphanumeric characters replaced by `-`."*
> — [Claude Code Docs: Manage sessions](https://code.claude.com/docs/en/sessions) (Firecrawl `/v1/scrape`)

DB가 없고 **경로 문자열을 키로 mangle한 디렉터리**가 원장이다. 그런데 하네스가 워크트리를 1급으로 인지한다:

| 장치 | 동작 | 출처 |
|---|---|---|
| 세션 피커 기본 | 현재 **워크트리**의 세션 (백그라운드 세션 포함, `bg` 표시) | sessions 문서 |
| `Ctrl+W` | **레포의 모든 워크트리**로 확대. 다시 누르면 복귀. 다중 워크트리 레포에서만 표시 | sessions 문서 |
| `Ctrl+A` | 머신의 모든 프로젝트로 확대 | sessions 문서 |
| 이름 기반 resume | *"resolves across the current repository and its worktrees"* — 다른 워크트리에 있어도 직접 재개 | sessions 문서 |
| 다른 워크트리 세션 선택 | **그 디렉터리에서 재개**(in place). 무관한 프로젝트면 대신 `cd`+resume 명령을 클립보드에 복사 | sessions 문서 |
| 세션 ID로 resume | *"session ID lookup is scoped to the current project directory **and its git worktrees**"* | sessions 문서 |
| 워크트리 진입/이탈 | 트랜스크립트를 새 cwd 하위로 **이동**(`/cd`와 동일). v2.1.198+ | worktrees 문서 |
| `WorktreeCreate` 훅 산 워크트리 | 트랜스크립트가 **시작 디렉터리에 남는다** — 취급이 다르다 | worktrees 문서 |
| 저장 위치 이동 | `CLAUDE_CONFIG_DIR` 환경변수 | sessions 문서 |

**즉 "워크트리 집합"이 조회 단위로 승격돼 있다.** 경로 키가 워크트리마다 다름에도 불구하고 레포 단위로 묶어 보여주는 계층이 위에 얹혀 있다.

부수 사실 (재개 시 복원되지 않는 것 — 설정 공유 축과 직결):
> *"If the session depended on `--mcp-config`, `--settings`, `--plugin-dir`, `--fallback-model`, or directories added with `--add-dir`, pass them again when you resume."*
> 반면 *"The standard settings files, such as `settings.json` and `settings.local.json`, are re-read at launch."*

**런치 플래그로 준 설정은 세션에 저장되지 않고, 파일로 둔 설정만 재개 시 살아난다.** 설정을 파일에 두어야 하는 직접적 근거.

### 4.2 그 방식이 깨진 실물 — issue #33665

경로 유도 키의 대가가 공식 저장소에 has-repro 라벨로 기록돼 있다.

> *"When running Claude Code CLI inside a devcontainer that checks out a git worktree (not created by Claude Code), the internal project path key used for session storage differs from the key used for memory storage and `/resume` lookups. Sessions are written to one `~/.claude/projects/` subdirectory, while `/resume` and the memory system look in a different one. Result: `/resume` reports "No conversations found to resume" despite hundreds of valid session `.jsonl` files on disk."*
>
> *"This appears to be a path resolution inconsistency — some subsystems derive the project key from `cwd`, others from `git rev-parse --git-common-dir` (which follows the worktree pointer to the main repo). When these resolve to different filesystem paths (common in containers where mount points differ from host paths), the keys diverge."*
> — [anthropics/claude-code#33665](https://github.com/anthropics/claude-code/issues/33665) (Firecrawl `/v1/scrape`), Claude Code v2.1.74, 2026-03-12

재현 조건이 특수해 보이지만 원인은 일반적이다: **워크트리는 "cwd"와 "레포 공통 디렉터리"라는 두 개의 정체성을 갖는데, 서브시스템마다 어느 쪽을 키로 쓸지 합의가 안 되면 원장이 조용히 갈라진다.** 데이터는 멀쩡히 디스크에 있는데 조회가 실패한다 — **가장 나쁜 실패 형태**(사용자는 유실로 인지한다).

같은 축의 이슈 둘 더 (Exa `/search`로 발견):
- [#14036](https://github.com/anthropics/claude-code/issues/14036) — *"`/resume` shows sessions from all directories globally instead of filtering to the current working directory"* → **워크트리 격리가 반대 방향으로 깨진 사례**
- [#38089](https://github.com/anthropics/claude-code/issues/38089) — *"`--resume` should not require matching working directory"* → 세션 ID는 전역 고유인데 조회는 디렉터리 스코프

> **grid fin 축 함의**: 세 이슈가 전부 **"워크트리를 무엇으로 식별하는가"** 하나의 축에서 나왔다. 저장 매체(SQLite냐 JSONL이냐)를 정하기 **전에** 식별 키를 정해야 한다. 관측된 안정 키는 `git rev-parse --git-common-dir`(레포 단위)이고, 워크트리는 그 아래 별도 축(워크트리 이름 또는 `$GIT_DIR/worktrees/<name>`)으로 두는 형태다. cwd 문자열을 mangle한 키는 컨테이너·심볼릭·마운트 경로 차이에서 깨진다.

---

## 5. 패턴 D — 원격 저장소를 1급으로

### 5.1 Amp — 스레드가 서버에 산다

> *"Threads are persistent conversations that maintain context across interactions. Your threads sync to ampcode.com, allowing you to continue conversations across devices."*
> — [sourcegraph/amp-examples-and-guides `guides/cli/README.md`](https://github.com/sourcegraph/amp-examples-and-guides/blob/main/guides/cli/README.md) (Firecrawl `/v1/scrape`)

CLI 어휘가 그 위에 얹혀 있다:

```bash
amp threads new              # 새 스레드
amp threads continue [id]    # 이어가기
amp threads list             # 목록
amp threads fork [id]        # 분기
amp threads share [id]       # 공유
amp threads compact [id]     # 토큰 압축
```

인증은 `AMP_API_KEY`. 3자 진술(coder/registry #748)은 *"Amp stores threads entirely server-side"* 라고 더 강하게 말하지만 이는 **공식 문서로 확인하지 못했다 — 미검증으로 표시한다.** 공식 문서가 보장하는 것은 "동기화되어 기기 간 이어서 작업 가능"까지다.

**워크트리 축의 의미**: 워크트리를 몇 개 만들든, 지우든, 다른 머신으로 옮기든 **스레드는 영향을 받지 않는다.** 상태 보유자를 워크트리 수명에서 완전히 분리한 극단.

**대가**: 오프라인 불가, 벤더 종속, 코드 대화 내용이 외부로 나간다. grid fin이 개인용 하네스인 점을 감안하면 세 번째가 결정적일 수 있다.

### 5.2 Vibe Kanban Cloud — 로컬 SQLite와 원격 PostgreSQL 병존

> *"The Cloud architecture bridges the frontend application with a PostgreSQL backend, utilizing ElectricSQL for real-time data propagation. ... The backend is implemented in the `remote` crate, which leverages `sqlx` for database interactions and `axum` for the web server."*
> — [DeepWiki: Cloud and Team Collaboration](https://deepwiki.com/BloopAI/vibe-kanban/9-cloud-and-team-collaboration) (Firecrawl `/v1/scrape`)

- 로컬은 §2.2의 SQLite를 그대로 유지하고, **클라우드는 별도 크레이트(`crates/remote`)로 분리**
- 계층: Organization → Project → Issue → Remote Workspace
- **연결 고리는 `Project::set_remote_project_id`** — 로컬 프로젝트가 원격 식별자를 들고 있는 형태. 로컬이 정본이고 원격은 링크
- 동기화 엔진은 ElectricSQL (Postgres → 클라이언트 실시간 shape 동기화)

> **grid fin 축 함의**: "로컬 우선, 원격은 선택적 계층"의 실물 배치. 원격 도입이 로컬 스키마를 바꾸도록 강제하지 않는다 — 컬럼 하나(`remote_project_id`)만 늘었다. 나중에 원격을 붙일 여지를 남기는 최소 비용의 형태.

---

## 6. DB 없이 이미 공유되는 것 — git 플러밍 계층

이 계층을 먼저 확인하지 않으면 git이 이미 해주는 일을 DB로 다시 구현하게 된다.

**기본적으로 공유되는 것** (Conductor 문서가 요약을 잘 한다):
> *"Worktrees share the same Git repository data. They use the same history, refs, remotes, and object database, while each workspace has its own checkout on disk."*
> — [Conductor: Git worktrees](https://www.conductor.build/docs/concepts/git-worktrees) (Firecrawl `/v1/scrape`)

**설정도 기본은 공유다:**
> *"By default, the repository `config` file is shared across all worktrees."*
> — [git-worktree(1)](https://git-scm.com/docs/git-worktree) CONFIGURATION FILE 절 (Firecrawl `/v1/scrape`)

워크트리별 설정이 필요하면:
```
git config extensions.worktreeConfig true
git config --worktree <key> <value>   # → $GIT_DIR/config.worktree 에 기록
```

**그런데 이 확장은 켜는 순간 되돌리기 어렵다.** 공식 문서가 직접 경고한다:

> *"Note that in this file, the exception for `core.bare` and `core.worktree` is gone. If they exist in `$GIT_DIR/config`, you must move them to the `config.worktree` of the main worktree."*
> *"Older Git versions will refuse to access repositories with this extension."*

그리고 공유하면 안 되는 키 목록을 명시한다:
- `core.worktree` — **절대 공유 금지**
- `core.bare` — 값이 `true`면 공유 금지
- `core.sparseCheckout` — 모든 워크트리에서 항상 sparse를 쓸 것이 확실하지 않으면 공유 금지

> **grid fin 축 함의**: 워크트리별 설정 분기가 필요하면 **매체는 이미 있다.** 다만 (a) 구버전 git 호환성을 깨고, (b) 켜기 전 `core.*` 키를 직접 옮겨야 하며, (c) 이 파일은 gitignore 대상이 아니라 `$GIT_DIR` 안에 있어 **배포·백업 대상이 아니다.** 하네스 설정을 여기 두면 팀/머신 간 이동이 불가능하다. [repository-layout §8.3](repository-layout.md)의 `.claude/settings.json` 비상속 문제와는 다른 층이다.

---

## 7. 실제 아픈 지점 — gitignore된 것들

git이 공유해주는 것 밖의 영역. 여기가 도구 생태계가 생긴 곳이다.

### 7.1 문제 진술

> *"`git worktree add` doesn't copy untracked files. `.env*` files are untracked by design — they hold secrets — so every new worktree ..."*
> — [DaniAkash/worktree-env-copy](https://github.com/daniakash/worktree-env-copy) (Exa `/search`)

Claude Code 공식 문서도 같은 지점을 인정한다:
> *"A worktree is a fresh checkout, so initialize your development environment there... To carry gitignored files such as `.env` into every new worktree automatically, add a `.worktreeinclude` file."*
> — [Claude Code Docs: Worktrees](https://code.claude.com/docs/en/worktrees)

### 7.2 접근 3파

| 접근 | 대표 | 성질 |
|---|---|---|
| **복사** | Conductor "Files to copy", Claude Code `.worktreeinclude`, `worktree-env-copy`(전역 git hook), `alxwrd/git-env` | 단순. 원본 변경이 전파되지 않음 |
| **심볼릭** | `km-tr/worktree-link`(`.worktreelinks` 글롭), `worktree-env-sync`(npm) | 원본 변경 즉시 반영. `node_modules` 공유로 디스크·설치시간 절약. 단 한쪽 손상이 전 워크트리에 전파 |
| **렌더링/생성** | `direnv` + `sops`, `gfouillet/wt-helper`(`.envrc` 렌더링), `worktree-env-sync`(템플릿 보간) | 워크트리별로 값이 달라야 할 때(포트 번호 등) 유일하게 성립 |

### 7.3 `.worktreeinclude`는 사실상 표준이다

Conductor의 레퍼런스 문서가 이를 명시적으로 말한다 — 우연한 수렴이 아니라 **의도된 상호운용**이다.

Conductor는 설정 경로를 둘 둔다:
- 자체 형식: `.conductor/settings.toml`의 `file_include_globs` (**커밋 가능** — 팀 전체가 같은 gitignore 파일을 받게 하려면 이쪽)
- 사실상 표준: 저장소 루트의 `.worktreeinclude`

> *"Use `.worktreeinclude` when your project already uses worktree tools that read that file, or when you want a small pattern-only project file. **If both `.worktreeinclude` and `file_include_globs` exist, `.worktreeinclude` wins.**"*
> — [Conductor: Files to copy](https://www.conductor.build/docs/reference/files-to-copy) (Firecrawl `/v1/scrape`)

**자체 형식보다 외부 규약을 우선시킨다.** 그리고 복사 자격 조건을 두 개로 못박는다:

> *"Conductor copies a gitignored file into a new local workspace when both of these are true: 1. The file is gitignored. 2. The file matches a Files to copy or `.worktreeinclude` pattern."*
> *"Untracked files that are not gitignored are not eligible."*

**gitignore되지 않은 미추적 파일은 복사 대상에서 의도적으로 배제된다** — 실수로 만들어진 파일이 워크트리로 번지는 것을 막는 장치.

그리고 복사로 안 되는 경우를 위한 두 번째 장치가 양쪽 제품에 다 있다 — setup script:
> *"Use a setup script when the workspace needs commands instead of copied files, such as dependency installation, code generation, symlinks, or database setup."*
> *"Generated files, dependency folders, and files that need commands to create them usually belong in a setup script instead."*

**즉 판별선이 문서화돼 있다 — 복사할 것은 "직접 만든 gitignore 파일"(주로 `.env` 계열)이고, 생성물·의존성 폴더는 스크립트 몫이다.**

**포트 충돌**은 렌더링파가 존재하는 이유다 — 워크트리 3개에서 dev 서버를 동시에 띄우면 `.env`를 그대로 복사한 순간 깨진다. `wt-helper`는 `.envrc`에서 `[8080] = ? SECRET [default]` 형태로 워크트리별 값을 묻는 방식을 취한다.

---

## 8. 여러 워크트리가 한 원장을 칠 때 — 동시성

패턴 A를 택하면 반드시 마주치는 층.

### 8.1 SQLite가 보장하는 것

- **WAL 모드**: 쓰기 중 읽기 동시 진행. rollback journal의 reader/writer 상호 차단이 사라진다
- **다중 writer는 기본적으로 불가**. `BEGIN CONCURRENT`(wal/wal2 모드)가 예외지만 *"the system still serializes COMMIT commands"* — [sqlite/sqlite `doc/begin_concurrent.md`](https://github.com/sqlite/sqlite/blob/9077e4652fd0691f45463e9a5c46560856e9be36/doc/begin_concurrent.md)
- 별도 커넥션 간에는 공유 캐시가 없으면 **커밋된 것만 보인다** — [Isolation In SQLite](https://www.sqlite.org/isolation.html)

즉 워크트리 세션이 3~5개 수준이면 WAL로 충분하고, **동시 쓰기 처리량이 문제가 되는 규모는 개인용 하네스에서 오지 않는다.**

### 8.2 실물 함정 — Vibe Kanban의 트랜잭션 회피

교과서보다 값나가는 건 이 코드 주석이다.

> *"Note: We intentionally avoid using a transaction here. SQLite update hooks fire during transactions (before commit), and the hook spawns an async task that queries `find_by_rowid` on a different connection."*
> — [BloopAI/vibe-kanban `crates/db/src/models/execution_process.rs`](https://github.com/BloopAI/vibe-kanban/blob/4deb7eca/crates/db/src/models/execution_process.rs) (Exa `/search`, 코드 본문 반환)

**실시간 UI 갱신을 위해 SQLite update hook을 쓰면, 훅이 커밋 전에 발화하므로 다른 커넥션에서 그 행을 조회하면 아직 없다.** 결과적으로 트랜잭션을 포기했다 — 원자성을 실시간성과 맞바꾼 것.

> **grid fin 축 함의**: "DB를 쓰면 트랜잭션으로 정합성이 보장된다"가 자동으로 성립하지 않는다. 실시간 알림 계층을 붙이는 순간 트랜잭션 경계와 충돌한다. §2.2의 로그 이관과 함께, **Vibe Kanban은 SQLite 채택의 대가를 두 번 지불한 사례**다.

---

## 9. grid fin 축으로 재배열

**결정이 아니라 관측의 재배열이다.** [state-and-continuity §1.3](state-and-continuity.md)이 남긴 문제에 외부 실물을 대응시킨다.

### 9.1 cygnus의 문제 ↔ 외부의 답

| cygnus에서 관측된 것 | 외부 실물의 대응 |
|---|---|
| 워크트리마다 별도 `dev-context.json` → main hub와 **stale 분기** | 확인한 7종 전부 **워크트리 밖 단일 원장**. 워크트리 안에 정본을 두는 사례를 못 찾았다 (§1) |
| 정본 위치가 시점에 따라 바뀜 (worktree → teardown 시 main) | container-use는 정본을 항상 git 브랜치에 둔다. 워크트리는 그 브랜치의 체크아웃일 뿐 (§3) |
| 보유자 8 + N×2 종, git이 조율 안 함 | Crystal/Vibe Kanban은 N을 DB 레코드로 흡수 — 보유자 수가 N에 비례해 늘지 않는다 (§2) |
| `docs/_local` 아래 비추적 파일이 상태 매체 | Conductor·Claude Code의 답: **비추적 파일은 상태 매체가 아니라 "복사 대상"으로 격하**하고, 상태는 별도 원장으로 (§7.2) |

### 9.2 매체 선택 전에 답해야 하는 것

§4.2의 세 이슈가 보여준 순서:

1. **워크트리 식별 키를 무엇으로 하는가** — `git rev-parse --git-common-dir`(레포) + 워크트리 이름의 2축이 관측된 안정 형태. cwd 문자열 mangle은 컨테이너·마운트에서 깨진다
2. **조회 단위를 무엇으로 하는가** — Claude Code는 "현재 워크트리 / 레포 전체 워크트리 / 전 프로젝트" 3단으로 두고 `Ctrl+W`·`Ctrl+A`로 전환한다. 기본값은 좁게, 확대는 명시적으로
3. **그 다음에 매체** — append 이력이 있으면 DB, 인스턴스 목록뿐이면 JSON (§2.3)

### 9.3 매체별 대가 요약

| 매체 | 강점 | 실물로 확인된 대가 |
|---|---|---|
| 로컬 SQLite | 질의 가능, N 흡수, 마이그레이션 체계 | 대용량 append는 빼야 함(§2.2), 실시간 훅과 트랜잭션 충돌(§8.2), 크로스플랫폼 마이그레이션 체크섬(§2.2) |
| git refs/notes | 새 기술 0, 감사·재현 강함 | 질의 불가(전수 순회), notes는 기본 push/fetch 안 됨 |
| 경로 규약 파일 | 구현 단순, 도구 없이 읽힘 | **키 유도 불일치로 조용히 갈라짐**(§4.2) — 관측된 실패 중 가장 나쁜 형태 |
| 원격 서버 | 워크트리·머신 수명에서 완전 분리 | 오프라인 불가, 벤더 종속, 코드 대화 외부 유출 |
| git config(`worktreeConfig`) | 설정 전용으로는 이미 존재 | 구버전 git 거부, `core.*` 수동 이관 필요, **배포·백업 불가**(§6) |

### 9.4 열린 질문

1. **grid fin의 동시 워크트리 상한은 몇인가?** cygnus 실적은 최대 2였다([state-and-continuity §1.3](state-and-continuity.md)). 2~3이면 §8의 동시성 논의는 대부분 무의미하고 매체 선택 기준이 "질의 필요성"만 남는다
2. **워크트리를 넘어야 하는 대상이 §1.1의 5종 중 실제로 몇 종인가?** 트랜스크립트를 넘길 필요가 없다면(워크트리=토픽=수명 일치) 문제가 훨씬 작아진다
3. **`git rev-parse --git-common-dir` 기반 키가 이 환경에서 실제로 안정적인가** — 미검증. 심볼릭 링크된 워크스페이스 경로에서 실측이 필요하다
4. **`.worktreeinclude`의 패턴 문법이 두 제품에서 동일한가** — Conductor 쪽은 글롭 패턴임을 확인했으나(§7.3), Claude Code 문서는 파일 존재만 언급했다. 같은 파일명을 쓰는 두 구현이 같은 문법을 받는지는 미검증
5. Amp의 *"entirely server-side"* 주장 — 3자 진술만 확보. 공식 확인 필요

---

## 부록 A. 조사 방법 및 한계

### A.1 어댑터별 호출

| 어댑터 | 연산 | 횟수 | 용도 |
|---|---|---|---|
| Exa | `/search` (type: auto, numResults 6~10) | 12 | 후보 발굴 + 코드 파일 본문 확보 |
| Firecrawl | `/v1/scrape` (markdown, onlyMainContent) | 13 | 1차 자료 전문 확보 |

**2단계 진행**: 후보명 단위 `/search` → 그 결과에서 나온 **특정 아티팩트 URL**(레포 README/CLAUDE.md, 공식 문서 페이지, 이슈)을 `/v1/scrape`. 스니펫 수준 주장은 채택하지 않았다.

Exa `/search`가 GitHub 코드 파일 본문을 그대로 반환하는 경우가 있어(claude-squad `config/state.go`, vibe-kanban `execution_process.rs`) 그 둘은 **검색 결과가 곧 1차 코드**다.

### A.2 실패한 수집

| 대상 | 결과 |
|---|---|
| `docs.imbue.com/core-concepts/core-concepts/containers` (Sculptor) | 스크랩 18바이트 — 본문 미획득. **Sculptor의 상태 저장 방식은 이 문서에 반영되지 않았다** |

Sculptor는 컨테이너 기반(워크트리가 아님)이라 이 조사의 축과 부분적으로만 겹친다. 필요하면 [메모리의 Chrome 폴백 규칙](../../../.claude/projects/-Users-mario-Workspace-grid-fin/memory/web-reading-fallback-chrome.md)대로 브라우저로 재수집한다.

### A.3 한계

- **DeepWiki 출처 4건은 AI 생성 위키다.** 문장마다 코드 라인 링크가 붙어 있어 구조적 주장은 채택했으나, **성능 주장("for performance")의 실제 벤치마크는 확인하지 않았다.** §2.2 관측 4는 "그런 결정을 내렸다"까지가 근거이고 "SQLite가 느리다"는 이 문서의 주장이 아니다
- **1차 자료로 확인한 것은 7종**(Crystal, Vibe Kanban[+Cloud], container-use, Claude Code, Amp, Conductor, claude-squad)이고, **그중 코드를 직접 읽은 것은 3종**(claude-squad, vibe-kanban 일부, container-use README)이다. 나머지는 공식 문서 기반. **§0.2의 "7종 전부" 류 주장은 이 7종에 한정된다**
- 발굴 단계에서 소규모 레포가 다수 나왔으나(Legio, Tusk, Solo, Cortex, fulcrum, agentd, hyve, lanes, AZUREAL, verun, git-stint 등) **검증하지 않았다.** 이들은 "워크트리 격리 + 외부 원장 패턴이 흔하다"는 빈도 관측에만 기여하고 개별 설계 근거로는 쓰지 않았다
- **부정 결과 하나**: "워크트리 안에 세션 상태를 두는 시스템"을 찾으려 했으나 못 찾았다. 다만 이는 검색 실패일 수 있다 — 그런 설계는 문서화될 이유가 없기 때문이다. **관측 1은 "없다"가 아니라 "찾지 못했다"로 읽어야 한다**

## 부록 B. 출처 목록

**1차 (공식 문서)**
- [git-worktree(1) — CONFIGURATION FILE](https://git-scm.com/docs/git-worktree) — Firecrawl
- [Claude Code Docs — Manage sessions](https://code.claude.com/docs/en/sessions) — Firecrawl
- [Claude Code Docs — Worktrees](https://code.claude.com/docs/en/worktrees) — Firecrawl
- [Conductor — Git worktrees](https://www.conductor.build/docs/concepts/git-worktrees) — Firecrawl
- [Conductor — Files to copy](https://www.conductor.build/docs/reference/files-to-copy) — Firecrawl
- [SQLite — Isolation](https://www.sqlite.org/isolation.html) / [File Locking And Concurrency](https://www.sqlite.org/lockingv3.html) — Exa

**1차 (저장소/코드)**
- [stravu/crystal — CLAUDE.md](https://github.com/stravu/crystal/blob/main/CLAUDE.md) — Firecrawl
- [dagger/container-use — environment/README.md](https://github.com/dagger/container-use/blob/main/environment/README.md) — Firecrawl
- [sourcegraph/amp-examples-and-guides — guides/cli/README.md](https://github.com/sourcegraph/amp-examples-and-guides/blob/main/guides/cli/README.md) — Firecrawl
- [smtg-ai/claude-squad — config/state.go](https://github.com/smtg-ai/claude-squad/blob/a4ab6988/config/state.go) — Exa
- [BloopAI/vibe-kanban — crates/db/src/models/execution_process.rs](https://github.com/BloopAI/vibe-kanban/blob/4deb7eca/crates/db/src/models/execution_process.rs) — Exa
- [sqlite/sqlite — doc/begin_concurrent.md](https://github.com/sqlite/sqlite/blob/9077e4652fd0691f45463e9a5c46560856e9be36/doc/begin_concurrent.md) — Exa
- [git/git — Documentation/config/extensions.adoc](https://github.com/git/git/blob/94f05775/Documentation/config/extensions.adoc) — Exa

**1차 (공식 저장소 이슈)**
- [anthropics/claude-code#33665](https://github.com/anthropics/claude-code/issues/33665) — Firecrawl
- [anthropics/claude-code#14036](https://github.com/anthropics/claude-code/issues/14036) — Exa
- [anthropics/claude-code#38089](https://github.com/anthropics/claude-code/issues/38089) — Exa

**2차 (DeepWiki — 코드 라인 링크 동반)**
- [Database Models and Queries](https://deepwiki.com/BloopAI/vibe-kanban/4.5-database-models-and-queries) — Firecrawl
- [Git Worktree Management](https://deepwiki.com/BloopAI/vibe-kanban/2.4-git-worktree-management) — Firecrawl
- [Cloud and Team Collaboration](https://deepwiki.com/BloopAI/vibe-kanban/9-cloud-and-team-collaboration) — Firecrawl
- [Session Management (claude-squad)](https://deepwiki.com/smtg-ai/claude-squad/4-session-management) — Exa

**자가출판 (존재 증명용)**
- [Direnv is All You Need to Parallelize Agentic Programming with Git Worktrees](https://waldencui.com/post/direnv_is_all_you_need_to_parallelize_claude_code_with_git_worktrees/) — Exa
- [Make working with git worktrees easier using direnv and sops](https://blog.thoughtsre.com/p/make-working-with-git-worktrees-easier) — Exa
- [km-tr/worktree-link](https://github.com/km-tr/worktree-link), [DaniAkash/worktree-env-copy](https://github.com/daniakash/worktree-env-copy), [alxwrd/git-env](https://github.com/alxwrd/git-env), [gfouillet/wt-helper](https://github.com/gfouillet/wt-helper), [worktree-env-sync](https://www.npmjs.com/package/worktree-env-sync) — Exa

**미검증 (3자 진술)**
- [coder/registry#748](https://github.com/coder/registry/issues/748) — *"Amp stores threads entirely server-side"*
