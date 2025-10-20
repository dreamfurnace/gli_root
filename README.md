# GLI Root Repository

이 저장소는 GLI 프로젝트의 루트 디렉토리로, 여러 하위 레포지토리들의 공통된 스크립트 및 설정 파일들을 포함합니다.

## ⚠️ 중요: 서비스 재시작 방법

**모든 서비스는 반드시 프로젝트 루트에서 제공된 스크립트를 사용해야 합니다.**

### 🔄 개별 서비스 재시작

```bash
# 프로젝트 루트로 이동
cd /Users/ahndonghyun/dongfiles/ADHcode/DreamFurnace/gli_root

# API 서버 재시작 (백그라운드)
./restart-api-server.sh --bf

# Admin Frontend 재시작 (백그라운드)
./restart-admin-frontend.sh --bf

# User Frontend 재시작 (백그라운드)
./restart-user-frontend.sh --bf

# WebSocket 서버 재시작 (백그라운드)
./restart-websocket.sh --bf

# 데이터베이스 재시작
./restart-database.sh --bf

# Redis 재시작
./restart-redis.sh --bf

# RabbitMQ 재시작
./restart-rabbitmq.sh --bf
```

### 🚀 전체 서비스 재시작

```bash
# 모든 서비스를 한 번에 재시작
./restart-all.sh --bf
```

### 📋 서비스별 포트 정보

| 서비스 | 포트 | 태그 |
|--------|------|------|
| API Server | 8000 | `gli_api-server` |
| Admin Frontend | 3001 | `gli_admin-frontend` |
| User Frontend | 3000 | `gli_user-frontend` |
| WebSocket | 8080 | `gli_websocket` |
| Database | 5433 | `gli_database` |
| Redis | 6379 | `gli_redis` |
| RabbitMQ | 5672, 15672 | `gli_rabbitmq` |

### 💡 주요 옵션

- `--bf`: 백그라운드 실행
- `--port`: 사용자 지정 포트
- `--tag`: 프로세스 태그 지정

### 📊 서비스 상태 확인

```bash
# 특정 서비스 프로세스 확인
pgrep -f "gli_api-server"

# 포트 사용 상태 확인
lsof -i :8000

# 로그 확인
tail -f ./gli_api-server/logs/gli_api-server.log
```

## 포함된 스크립트

### Git 관리 스크립트
- `init_repos.sh` : 모든 리포지토리를 GitHub에 생성하고 초기화
- `sync_repos.sh` : 루트만 clone했을 때 하위 레포 자동 clone
- `git-multi-pull.sh` : 모든 하위 레포 최신 pull
- `git-multi-push.sh` : 모든 하위 레포 푸시

### 서비스 관리 스크립트
- `restart-api-server.sh` : Django API 서버 재시작
- `restart-admin-frontend.sh` : Vue.js Admin Frontend 재시작
- `restart-user-frontend.sh` : React User Frontend 재시작
- `restart-websocket.sh` : WebSocket 서버 재시작
- `restart-database.sh` : PostgreSQL 데이터베이스 재시작
- `restart-redis.sh` : Redis 캐시 서버 재시작
- `restart-rabbitmq.sh` : RabbitMQ 메시지 브로커 재시작
- `restart-all.sh` : 모든 서비스 일괄 재시작

### 배포 및 인프라 스크립트
- `multigit-*.sh` : Git 멀티 레포 관리
- `setup-*.sh` : AWS 인프라 설정
- `dump-staging-db.sh` : 스테이징 DB 덤프
- `sync-db-from-staging.sh` : 스테이징에서 DB 동기화

## 하위 레포 목록

- `gli_database` - PostgreSQL 데이터베이스
- `gli_redis` - Redis 캐시 서버
- `gli_rabbitmq` - RabbitMQ 메시지 브로커
- `gli_websocket` - WebSocket 서버
- `gli_api-server` - Django REST API 백엔드
- `gli_user-frontend` - React 사용자 프론트엔드
- `gli_admin-frontend` - Vue.js 관리자 프론트엔드
