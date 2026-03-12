# Shared Context Git Skill

여러 AI 에이전트가 Git 기반 원격 저장소를 통해 프로젝트 컨텍스트를 공유할 수 있도록 표준화된 워크플로를 제공하는 스킬입니다. 에이전트는 Markdown 파일로 구성된 공유 메모리를 읽고, 업데이트하며, Git 히스토리를 리뷰 트레일로 활용합니다.

## 주요 기능

- 표준 문서 템플릿으로 공유 컨텍스트 저장소 초기화
- 읽기/쓰기 전 로컬 클론 안전 동기화
- 안정적인 사실, 활성 컨텍스트, 의사결정, 미해결 질문 기록
- 브랜치 기반 컨텍스트 업데이트로 diff 리뷰 지원
- 로컬 상태가 오래되었거나 충돌 시 안전 중단

## 저장소 구조

```
├── SKILL.md                    # 스킬 정의 및 핵심 규칙
├── agents/
│   └── openai.yaml             # OpenAI 에이전트 연동 설정
├── scripts/                    # 자동화 Bash 스크립트
│   ├── bootstrap_repo.sh       # 템플릿으로 초기 문서 생성
│   ├── sync_context.sh         # 원격 변경 fetch 및 fast-forward
│   ├── prepare_branch.sh       # 컨텍스트 브랜치 생성
│   ├── validate_context.sh     # 문서 구조 검증
│   └── summarize_context.sh    # 상태 요약 및 압축 힌트 출력
├── assets/
│   └── templates/              # 문서 시작 템플릿
│       ├── CONTEXT.md           # 공유 상태 문서
│       ├── TIMELINE.md          # 변경 이력 (추가 전용)
│       ├── HANDOFF.md           # 인수인계 노트 (선택)
│       └── POLICY.md            # 협업 정책 (선택)
└── references/                 # 상세 참조 문서
    ├── schema.md               # 문서 구조 명세
    ├── update-rules.md         # 업데이트 규칙
    ├── git-workflows.md        # Git 워크플로 패턴
    ├── conflict-policy.md      # 충돌 처리 정책
    └── handoff-guidelines.md   # 인수인계 가이드라인
```

## 문서 구성

### 필수 문서

| 문서 | 설명 |
|------|------|
| `CONTEXT.md` | 현재 프로젝트 상태를 요약하는 핵심 문서. 개요, 안정적 사실, 활성 컨텍스트, 의사결정, 미해결 질문 섹션으로 구성 |
| `TIMELINE.md` | 의미 있는 컨텍스트 변경의 추가 전용(append-only) 이력 |

### 선택 문서

| 문서 | 설명 |
|------|------|
| `HANDOFF.md` | 다음 에이전트를 위한 인수인계 노트 |
| `POLICY.md` | 팀 협업 정책 및 가이드라인 |

## 핵심 규칙

1. **읽기 우선**: fetch 또는 sync 후 `CONTEXT.md`와 `TIMELINE.md`를 먼저 읽은 뒤 편집합니다.
2. **공유 메모리 활용**: 세션 로컬 노트가 아닌 저장소에 공유 메모리를 보관합니다.
3. **브랜치 기반 업데이트**: 기본 브랜치에 직접 push하지 않고 브랜치를 통해 업데이트합니다.
4. **충돌 자동 해결 금지**: 저장소가 dirty하거나 브랜치가 분기된 경우 중단하고 조정합니다.
5. **사실과 추론 분리**: 검증된 사실은 안정 섹션에, 불확실한 내용은 미해결 질문에 기록합니다.
6. **의미 있는 타임라인 항목**: 사소한 변경이 아닌 의미 있는 변경만 타임라인에 기록합니다.

## 사용 방법

### 워크플로

```bash
# 1. 저장소가 없으면 초기화
scripts/bootstrap_repo.sh

# 2. 로컬 클론에서 동기화
scripts/sync_context.sh

# 3. CONTEXT.md, TIMELINE.md, HANDOFF.md(있으면) 읽기

# 4. 업데이트 공유가 필요하면 브랜치 생성
scripts/prepare_branch.sh --actor <name> --slug <topic>

# 5. Markdown 파일 업데이트

# 6. 문서 구조 검증
scripts/validate_context.sh

# 7. diff 확인 및 상태 요약
scripts/summarize_context.sh

# 8. 변경이 의미 있고 정확하면 커밋 & 푸시
```

### 스크립트 가이드

| 스크립트 | 설명 |
|---------|------|
| `bootstrap_repo.sh` | 템플릿에서 초기 문서 세트를 생성합니다 |
| `sync_context.sh` | 원격 변경을 fetch하고 기본 브랜치를 안전하게 fast-forward합니다 |
| `prepare_branch.sh` | `context/<actor>/<YYYY-MM-DD>-<slug>` 형식의 브랜치를 생성하거나 전환합니다 |
| `validate_context.sh` | 필수 파일, 제목, 타임라인 항목 형식을 검사합니다 |
| `summarize_context.sh` | 간결한 상태 요약과 압축 힌트를 출력합니다 |

## 협업 모드

- **로컬 초안**: 동기화, 읽기, 로컬 편집, 검증 후 커밋 없이 중단
- **브랜치 커밋 & 푸시**: 컨텍스트 브랜치 생성, 문서 업데이트, 검증, 커밋, 푸시
- **PR 제안**: Git 작업 수행 후 PR 생성은 별도 도구에 위임

## 참조 문서

- [schema.md](references/schema.md) — 문서 구조 명세
- [update-rules.md](references/update-rules.md) — 업데이트 규칙
- [git-workflows.md](references/git-workflows.md) — Git 워크플로 패턴
- [conflict-policy.md](references/conflict-policy.md) — 충돌 처리 정책
- [handoff-guidelines.md](references/handoff-guidelines.md) — 인수인계 가이드라인

## 요구 사항

- Git CLI
- Bash 셸
- 표준 Unix 유틸리티 (grep, awk 등)

외부 패키지나 라이브러리 의존성은 없습니다.
