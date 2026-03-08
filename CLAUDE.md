# Claude Code Instructions - GLI Platform

> **프로젝트 개요**: GLI (Global Liquidity Infrastructure) - 유동성 관리 플랫폼
> **아키텍처**: Django API + Vue.js (User/Admin) + WebSocket + PostgreSQL + Redis + RabbitMQ

---

## 📑 목차

1. [언어 설정](#-언어-설정)
2. [프로젝트 구조](#-프로젝트-구조)
3. [로컬 서비스 관리 규칙](#-로컬-서비스-관리-규칙)
4. [AWS 작업 규칙](#-aws-작업-규칙)
5. [개발 워크플로우](#-개발-워크플로우)
6. [데이터베이스 관리](#-데이터베이스-관리)
7. [멀티git 워크플로우](#-멀티git-워크플로우)
8. [참조 문서](#-참조-문서)
9. [Task Master AI](#-task-master-ai)

---

## 🌐 언어 설정

**항상 한국어로 응답하세요. Always respond in Korean.**

- 모든 설명, 답변, 코드 주석은 한국어로 작성
- 기술 용어는 필요시 영어 병기 가능 (예: "컴포넌트(Component)")
- 코드 자체는 영어로 작성하되, 주석과 설명은 한국어로 작성

---

## 📁 프로젝트 구조

```
gli_root/
├── gli_api-server/          # Django REST API (포트 8000)
├── gli_user-frontend/       # Vue.js 사용자 화면 (포트 3000)
├── gli_admin-frontend/      # Vue.js 관리자 화면 (포트 3001)
├── gli_websocket/           # WebSocket 서버 (포트 8080)
├── gli_database/            # PostgreSQL 설정 (포트 5433)
├── gli_redis/               # Redis 설정 (포트 6379)
├── gli_rabbitmq/            # RabbitMQ 설정 (포트 5672, 15672)
├── docs/                    # 프로젝트 문서
├── tests/                   # 통합 테스트
├── logs/                    # 서비스 로그
├── .taskmaster/             # Task Master AI 작업 관리
├── restart-*.sh             # 개별 서비스 재시작 스크립트
├── restart-all.sh           # 전체 서비스 재시작
├── stop-all-services.sh     # 전체 서비스 중지
├── multigit-*.sh            # Git 브랜치 관리 스크립트
├── dbMig_*.sh              # 데이터베이스 마이그레이션 스크립트
└── AWS_switch-to-gli.sh    # AWS 계정 전환 스크립트
```

### 주요 서비스 포트

| 서비스 | 포트 | URL | 용도 |
|--------|------|-----|------|
| Django API | 8000 | http://localhost:8000 | 백엔드 REST API |
| User Frontend | 3000 | http://localhost:3000 | 사용자 웹 인터페이스 |
| Admin Frontend | 3001 | http://localhost:3001 | 관리자 대시보드 |
| WebSocket | 8080 | ws://localhost:8080 | 실시간 통신 |
| PostgreSQL | 5433 | postgresql://localhost:5433 | 데이터베이스 |
| Redis | 6379 | redis://localhost:6379 | 캐시 & 세션 |
| RabbitMQ | 5672, 15672 | http://localhost:15672 | 메시지 큐 (admin/admin) |

---

## 🚨 로컬 서비스 관리 규칙

### **절대 준수사항 (MANDATORY RULES)**

#### 1. 서비스 실행 방법

**✅ 올바른 방법 (CORRECT)**
```bash
cd /Users/ahndonghyun/dongfiles/ADHcode/DreamFurnace/gli_root

# 전체 서비스 시작 (권장)
./restart-all.sh --bf

# 개별 서비스 시작
./restart-api-server.sh --bf          # Django API
./restart-user-frontend.sh --bf       # User Frontend
./restart-admin-frontend.sh --bf      # Admin Frontend
./restart-websocket.sh --bf           # WebSocket
./restart-database.sh --bf            # PostgreSQL
./restart-redis.sh --bf               # Redis
./restart-rabbitmq.sh --bf            # RabbitMQ
```

**❌ 잘못된 방법 (INCORRECT) - 절대 사용 금지**
```bash
npm run dev                           # 포트가 임의로 변경됨
python manage.py runserver           # 환경 변수 및 로깅 설정 누락
docker-compose up                    # 프로젝트에서 사용 안 함
```

#### 2. 서비스 상태 확인

```bash
# Health Check
curl http://localhost:8000/api/common/health/

# 실행 중인 GLI 프로세스 확인
pgrep -f gli_ | wc -l

# 포트 사용 확인
lsof -i :8000 -i :3000 -i :3001 -i :8080

# CLI 모니터링 도구 사용 (권장)
./gli-cli-monitor.sh
```

#### 3. 서비스 중지

```bash
# 전체 서비스 중지
./stop-all-services.sh

# 강제 종료
pkill -9 -f "gli_"

# 특정 서비스만 중지
pkill -f "gli_api-server"
```

#### 4. 트러블슈팅

**포트 충돌 문제**
```bash
# 포트 사용 프로세스 확인
lsof -ti:8000 -ti:3000 -ti:3001

# 강제 종료 후 재시작
pkill -9 -f gli_ && ./restart-all.sh --bf
```

**환경 변수 누락**
- 재시작 스크립트는 `.env` 파일을 자동으로 로드
- 직접 실행 시 환경 변수가 누락되어 오류 발생 가능

### **왜 이런 규칙이 필요한가?**

- 재시작 스크립트는 환경 변수, 로깅, PID 관리를 자동 처리
- 임의 실행 시 포트 충돌 및 설정 누락으로 디버깅 시간 낭비
- 팀 개발 환경의 일관성 유지
- 백그라운드 실행으로 터미널 세션 독립성 확보

### **상세 정보**

전체 서비스 관리에 대한 상세 내용은 `LOCAL_SERVICES_GUIDE.md` 참조

---

## 🚨 AWS 작업 규칙

### **MANDATORY: AWS CLI 명령어 실행 규칙**

**모든 AWS CLI 작업은 반드시 GLI 계정 전환 후 실행해야 합니다.**

#### 올바른 실행 방법

```bash
# 형식: source AWS_switch-to-gli.sh; aws [명령어]
source AWS_switch-to-gli.sh; aws ec2 describe-instances
source AWS_switch-to-gli.sh; aws s3 ls
source AWS_switch-to-gli.sh; aws rds describe-db-instances
source AWS_switch-to-gli.sh; aws ecs list-services --cluster gli-cluster
```

#### 계정 정보

- **GLI 계정 ID**: `917891822317` (운영 계정)
- **잘못된 계정 ID**: `424438300282` (절대 사용 금지)

#### 안전장치

- `AWS_switch-to-gli.sh` 스크립트는 계정 확인 후 작업 진행
- 잘못된 계정 감지 시 자동 중단
- aws-gli 스킬을 통한 자동 안전성 검증

#### ❌ 절대 금지

```bash
# 직접 실행 금지 - 계정 확인 없이 실행됨
aws [명령어]
```

#### AWS 리소스 분석

프로젝트 AWS 인프라 현황은 `AWS_RESOURCE_ANALYSIS.md` 참조

---

## 🔄 개발 워크플로우

### 코드 작성 시 주의사항

1. **파일 읽기 우선**: 코드 수정 전 항상 Read 도구로 파일 확인
2. **기존 패턴 준수**: 프로젝트의 기존 코딩 스타일 따르기
3. **보안 취약점 주의**: SQL Injection, XSS, CSRF 등 OWASP Top 10 취약점 방지
4. **과도한 엔지니어링 지양**: 요청된 기능만 구현, 불필요한 추상화 금지

### Git 커밋 메시지 규칙

```bash
# 커밋 메시지 형식
git commit -m "feat: 새로운 기능 추가 (task 1.2)"
git commit -m "fix: 로그인 버그 수정"
git commit -m "refactor: API 엔드포인트 리팩토링"
git commit -m "docs: README 업데이트"
git commit -m "test: 단위 테스트 추가"

# Task Master와 연동
git commit -m "feat: JWT 인증 시스템 구현 (task 1.2)"
```

### 브랜치 전략

- `main`: 프로덕션 배포 브랜치 (안정화 버전)
- `stg`: 스테이징 환경 브랜치 (현재 작업 중인 브랜치)
- `dev`: 개발 환경 브랜치 (실험적 기능)

---

## 🗄️ 데이터베이스 관리

### 마이그레이션 스크립트

#### 1. 스테이징 → 로컬 동기화

```bash
# 1단계: 스테이징 DB 덤프
./dbMig_stg-local_1_dump-staging-db.sh

# 2단계: 로컬 DB에 동기화
./dbMig_stg-local_2_sync-db-from-staging.sh
```

#### 2. 로컬 → 스테이징 동기화 (통합 스크립트)

```bash
# 로컬 변경사항을 스테이징으로 푸시
./dbMig_local-stg_unified.sh
```

### Django 마이그레이션

```bash
cd gli_api-server

# 마이그레이션 파일 생성
python manage.py makemigrations

# 마이그레이션 적용
python manage.py migrate

# 마이그레이션 상태 확인
python manage.py showmigrations
```

### 데이터베이스 가이드

자세한 내용은 `DB_SYNC_GUIDE.md` 참조

---

## 🌿 멀티git 워크플로우

GLI 프로젝트는 monorepo 구조로, 여러 서브모듈을 동시에 관리합니다.

### Pull 작업

```bash
./multigit-pull-main.sh    # main 브랜치 pull
./multigit-pull-stg.sh     # stg 브랜치 pull
./multigit-pull-dev.sh     # dev 브랜치 pull
```

### Push 작업

```bash
./multigit-push-main.sh    # main 브랜치 push
./multigit-push-stg.sh     # stg 브랜치 push
./multigit-push-dev.sh     # dev 브랜치 push
```

### 브랜치 병합

```bash
# dev → stg 병합
./multigit-merge-dev-to-stg.sh

# stg → main 병합
./multigit-merge-stg-to-main.sh

# main → stg 병합 (hotfix)
./multigit-merge-main-to-stg.sh

# stg → dev 병합
./multigit-merge-stg-to-dev.sh
```

### 개발 → 스테이징 푸시 및 병합 (자동화)

```bash
# dev에서 작업 후 stg로 자동 병합 및 푸시
./multigit-push-dev-merge-to-stg.sh
```

### 상세 가이드

전체 멀티git 워크플로우는 `MULTIGIT_SCRIPTS_GUIDE.md` 참조

---

## 📚 참조 문서

### 개발 가이드

- `LOCAL_SERVICES_GUIDE.md` - 로컬 서비스 관리 상세 가이드
- `DB_SYNC_GUIDE.md` - 데이터베이스 동기화 가이드
- `MULTIGIT_SCRIPTS_GUIDE.md` - Git 워크플로우 가이드

### 배포 가이드

- `DEPLOYMENT_GUIDE_1of3.md` - 배포 가이드 Part 1
- `DEPLOYMENT_GUIDE_2of3.md` - 배포 가이드 Part 2
- `DEPLOYMENT_GUIDE_3of3.md` - 배포 가이드 Part 3

### 테스트 가이드

- `TEST_COVERAGE_MATRIX.md` - 테스트 커버리지 매트릭스
- `TEST_EXECUTION_MANUAL.md` - 테스트 실행 매뉴얼

### AWS 인프라

- `AWS_RESOURCE_ANALYSIS.md` - AWS 리소스 현황 분석
- `ORVIA_RESOURCE_CLEANUP_REPORT.md` - Orvia 리소스 정리 보고서

### 기타 문서

- `CORS_SETUP_PLAN.md` - CORS 설정 계획
- `AXIOS_CENTRALIZATION.md` - Axios 중앙화 가이드
- `RWA_DATA_STRUCTURE_ANALYSIS.md` - RWA 데이터 구조 분석

---

## 🤖 Task Master AI

**Task Master의 개발 워크플로우 명령어 및 가이드라인을 가져옵니다. 메인 CLAUDE.md 파일에 포함된 것처럼 처리하세요.**

@./.taskmaster/CLAUDE.md

### Task Master 빠른 시작

```bash
# 다음 작업 가져오기
task-master next

# 작업 상세 정보
task-master show <id>

# 작업 완료 처리
task-master set-status --id=<id> --status=done

# 전체 작업 목록
task-master list
```

---

## 🔐 보안 및 인증

### 환경 변수 관리

- `.env` - 로컬 환경 변수 (절대 커밋 금지)
- `.env.example` - 환경 변수 템플릿
- `.secrets/` - 민감한 정보 (gitignore 처리됨)

### AWS 자격증명

- AWS CLI 자격증명은 `~/.aws/credentials`에서 관리
- `AWS_switch-to-gli.sh` 스크립트로 계정 전환

---

## 🐛 디버깅 및 로깅

### 로그 위치

```bash
# 서비스별 로그
logs/gli_api-server.log
logs/gli_user-frontend.log
logs/gli_admin-frontend.log
logs/gli_websocket.log

# 실시간 로그 확인
tail -f logs/gli_api-server.log
```

### 모니터링 도구

```bash
# CLI 기반 모니터링
./gli-cli-monitor.sh

# Health Check
curl http://localhost:8000/api/common/health/
```

---

## ⚡ 성능 최적화

- Redis 캐싱 활용
- DB 쿼리 최적화 (N+1 문제 주의)
- Frontend 빌드 최적화
- WebSocket 연결 풀링

---

## 📝 코드 리뷰 체크리스트

- [ ] 보안 취약점 검토 (OWASP Top 10)
- [ ] 코드 스타일 준수 (PEP 8, ESLint)
- [ ] 단위 테스트 작성
- [ ] API 문서 업데이트
- [ ] 환경 변수 확인
- [ ] 에러 핸들링 적절성
- [ ] 로깅 추가 여부

---

**마지막 업데이트**: 2026-03-06
**프로젝트 버전**: GLI v1.0
**Claude Code 버전**: Sonnet 4.5
