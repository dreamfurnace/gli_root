# GLI 로컬 서비스 관리 가이드

> **목적**: 로컬 개발 환경에서 모든 GLI 서비스를 시작, 재시작, 중지하는 종합 가이드

---

## 📑 목차

1. [서비스 포트 구성](#1-서비스-포트-구성)
2. [빠른 시작](#2-빠른-시작)
3. [개별 서비스 관리](#3-개별-서비스-관리)
4. [상세 동작 원리](#4-상세-동작-원리)
5. [서비스 상태 확인](#5-서비스-상태-확인)
6. [문제 해결](#6-문제-해결)
7. [환경 설정](#7-환경-설정)
8. [요구사항](#8-요구사항)

---

## 1. 서비스 포트 구성

GLI 플랫폼은 8개의 독립적인 서비스로 구성됩니다.

| 서비스 | 포트 | URL/접근 방법 | 설명 |
|--------|------|---------------|------|
| **Redis** | 6379 | `redis://localhost:6379` | 캐시 서버 |
| **RabbitMQ** | 5672, 15672 | http://localhost:15672 (admin/admin) | 메시지 큐 |
| **PostgreSQL** | 5433 | `postgresql://localhost:5433` | 데이터베이스 |
| **Django API** | 8000 | http://localhost:8000/api/common/health/ | 백엔드 API |
| **WebSocket** | 8080 | `ws://localhost:8080` | 실시간 통신 |
| **User Frontend** | 3000 | http://localhost:3000 | 사용자 화면 |
| **Admin Frontend** | 3001 | http://localhost:3001 | 관리자 화면 |

---

## 2. 빠른 시작

### 2.1 모든 서비스 한번에 실행

#### 옵션 1: restart-all.sh (권장)

**백그라운드 실행 (터미널 종료 후에도 유지):**
```bash
cd /path/to/gli_root
./restart-all.sh --bf
```

**포그라운드 실행 (디버깅용):**
```bash
./restart-all.sh
```

**주요 옵션:**
```bash
# 실패해도 계속 진행
./restart-all.sh --bf --skip-failed

# 서비스 간 대기 시간 설정 (기본 5초)
./restart-all.sh --bf --wait 10

# 상세 로그 출력
./restart-all.sh --bf --verbose

# 특정 TAG 사용
./restart-all.sh --bf --tag custom_name
```

#### 옵션 2: start-all-services.sh

```bash
./start-all-services.sh
```

- 모든 서비스를 백그라운드에서 실행
- `Ctrl+C`로 모든 서비스 일괄 종료
- 로그는 `logs/` 디렉토리에 저장

---

### 2.2 모든 서비스 중지

```bash
./stop-all-services.sh
```

또는 개별 프로세스 종료:
```bash
# restart-all.sh로 실행한 경우
pkill -f "gli_"

# 강제 종료
pkill -9 -f "gli_"
```

---

## 3. 개별 서비스 관리

### 3.1 서비스 실행 순서

**의존성을 고려한 권장 순서:**

```
1. Docker Desktop 시작 (자동)
   ↓
2. Redis (캐시)
   ↓
3. RabbitMQ (메시지 큐)
   ↓
4. PostgreSQL (데이터베이스)
   ↓
5. Django API Server (백엔드)
   ↓
6. WebSocket Server (실시간 통신)
   ↓
7. User Frontend (프론트엔드)
   ↓
8. Admin Frontend (관리자)
```

### 3.2 개별 서비스 실행/재시작

#### Redis (캐시 서버)

```bash
# 재시작
./restart-redis.sh --bf

# 시작
./start-redis.sh

# 상태 확인
redis-cli ping  # 응답: PONG
```

#### RabbitMQ (메시지 큐)

```bash
# 재시작
./restart-rabbitmq.sh --bf

# 시작
cd gli_rabbitmq
docker-compose up -d

# 관리 UI 접속
# http://localhost:15672
# 로그인: admin / admin
```

#### PostgreSQL (데이터베이스)

**방법 1: restart-database.sh 사용 (권장)**:

```bash
# 프로젝트 루트에서 실행
./restart-database.sh --bf

# 상태 확인
./gli-cli-monitor.sh
```

**방법 2: docker-compose 직접 사용**:

```bash
# gli_database 폴더에서 실행
cd gli_database
docker-compose up -d

# 상태 확인
docker ps | grep gli_DB_local

# 로그 확인
docker logs gli_DB_local

# 연결 테스트
psql -h localhost -p 5433 -U gli -d gli
```

**데이터베이스 초기화**:

```bash
# Django 마이그레이션 실행
cd gli_api-server
export DJANGO_ENV=development
python manage.py migrate

# 슈퍼유저 생성
python manage.py createsuperuser
```

**연결 정보**:
- Host: localhost
- Port: 5433
- Database: gli
- User: gli
- Password: gli123!
- Container: gli_DB_local

#### Django API Server (백엔드)

```bash
# 재시작 (백그라운드)
./restart-api-server.sh --bf

# 재시작 (포그라운드)
./restart-api-server.sh

# 시작
./start-api-server.sh

# 다른 포트로 실행
PORT=8001 ./restart-api-server.sh --bf

# Health Check
curl http://localhost:8000/api/common/health/
# 응답: {"status": "ok", "message": "GLI API Server is running"}

# 로그 확인
tail -f gli_api-server/logs/gli_api-server.log

# PID 확인
cat gli_api-server/gli_api-server.pid
```

#### WebSocket Server (실시간 통신)

```bash
# 재시작
./restart-websocket.sh --bf

# 로그 확인
tail -f gli_websocket/logs/gli_websocket.log

# 포트 확인
lsof -i :8080
```

#### User Frontend (사용자 화면)

```bash
# 재시작
./restart-user-frontend.sh --bf

# 시작
./start-user-frontend.sh

# 브라우저 접속
open http://localhost:3000

# 로그 확인
tail -f gli_user-frontend/logs/gli_user-frontend.log
```

#### Admin Frontend (관리자 화면)

```bash
# 재시작
./restart-admin-frontend.sh --bf

# 시작
./start-admin-frontend.sh

# 브라우저 접속
open http://localhost:3001

# 로그 확인
tail -f gli_admin-frontend/logs/gli_admin-frontend.log
```

---

## 4. 상세 동작 원리

### 4.1 restart-all.sh 동작 흐름

```bash
#!/bin/bash

# 1. Docker Desktop 자동 시작
if ! docker info >/dev/null 2>&1; then
  open -a "Docker Desktop"
  # 최대 60초 대기
  for i in {1..60}; do
    if docker info >/dev/null 2>&1; then
      break
    fi
    sleep 1
  done
fi

# 2. 기존 서비스 정리
pkill -f "gli_" 2>/dev/null || true

# 3. 각 서비스 순차 실행
services=(
  "restart-redis.sh"
  "restart-rabbitmq.sh"
  "restart-database.sh"
  "restart-api-server.sh"
  "restart-websocket.sh"
  "restart-user-frontend.sh"
  "restart-admin-frontend.sh"
)

for service in "${services[@]}"; do
  ./$service --bf
  sleep 5  # 서비스 간 대기
done
```

### 4.2 Django API 환경 변수 로드 순서

**파일**: `gli_api-server/config/settings.py`

```python
from dotenv import load_dotenv

# 1. 기본 .env 로드
load_dotenv()

# 2. 환경별 .env 파일 로드 (오버라이드)
ENV = os.getenv('DJANGO_ENV', 'development')
load_dotenv(f'.env.{ENV}', override=True)
```

**로드되는 파일**:
- `.env` (공통 설정)
- `.env.development` (개발 환경 - 기본값)
- `.env.staging` (스테이징 환경)
- `.env.production` (프로덕션 환경)

### 4.3 백그라운드 실행 원리

```bash
# restart-api-server.sh의 핵심 명령
nohup bash -c "exec -a 'gli_api-server' \
  env DJANGO_ENV=development \
  uv run python manage.py runserver 0.0.0.0:8000" \
  >> ./logs/gli_api-server.log 2>&1 &

echo $! > ./gli_api-server.pid
```

**주요 옵션 설명**:
- `nohup ... &`: 백그라운드 실행, 터미널 종료 후에도 유지
- `exec -a 'gli_api-server'`: 프로세스 이름을 'gli_api-server'로 설정
- `env DJANGO_ENV=development`: 환경 변수 설정
- `>> ./logs/*.log 2>&1`: 표준 출력과 에러를 로그 파일로 리다이렉트
- `echo $! > *.pid`: 프로세스 ID를 파일에 저장

### 4.4 AWS 자격 증명 로드

**파일**: `gli_api-server/.env.development`

```bash
# GLI AWS 계정 자격 증명
AWS_ACCESS_KEY_ID=AKIA5LNU5WLWUA55GAOG
AWS_SECRET_ACCESS_KEY=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
AWS_STORAGE_BUCKET_NAME=gli-platform-media-dev
AWS_S3_REGION=ap-northeast-2
```

**자동 로드**:
- Django 서버 시작 시 자동으로 로드
- S3 버킷 접근 가능
- 별도 설정 불필요

---

## 5. 서비스 상태 확인

### 5.1 빠른 Health Check

```bash
# API Server
curl http://localhost:8000/api/common/health/

# User Frontend
curl http://localhost:3000

# Admin Frontend
curl http://localhost:3001

# Redis
redis-cli ping

# PostgreSQL
psql -h localhost -p 5433 -U postgres -c "SELECT 1;"
```

### 5.2 포트 사용 확인

```bash
# 모든 GLI 서비스 포트 확인
lsof -i :6379 -i :15672 -i :5433 -i :8000 -i :8080 -i :3000 -i :3001

# 개별 포트 확인
lsof -i :8000  # Django API
lsof -i :3000  # User Frontend
lsof -i :3001  # Admin Frontend
```

### 5.3 프로세스 확인

```bash
# GLI 관련 모든 프로세스
pgrep -f gli_

# 프로세스 상세 정보
ps aux | grep gli_

# 실행 중인 GLI 프로세스 수
pgrep -f gli_ | wc -l

# Docker 컨테이너 확인
docker ps

# Node.js 프로세스
ps aux | grep node

# Python 프로세스
ps aux | grep python
```

### 5.4 로그 모니터링

#### 실시간 로그 확인

```bash
# API Server
tail -f gli_api-server/logs/gli_api-server.log

# WebSocket
tail -f gli_websocket/logs/gli_websocket.log

# User Frontend
tail -f gli_user-frontend/logs/gli_user-frontend.log

# Admin Frontend
tail -f gli_admin-frontend/logs/gli_admin-frontend.log

# 모든 로그 동시 확인
tail -f gli_*/logs/gli_*.log
```

#### 로그 검색

```bash
# 에러 로그 검색
grep -i error gli_api-server/logs/gli_api-server.log

# 최근 50줄 확인
tail -50 gli_api-server/logs/gli_api-server.log

# 특정 시간대 로그 확인
grep "2025-10-15 14:" gli_api-server/logs/gli_api-server.log
```

---

## 6. 문제 해결

### 6.1 포트 충돌

**증상**: 서비스가 시작되지 않고 "Address already in use" 에러

**해결 방법**:
```bash
# 1. 포트를 사용하는 프로세스 확인
lsof -i :8000

# 2. 프로세스 종료
kill -9 <PID>

# 3. 또는 모든 서비스 중지 후 재시작
./stop-all-services.sh
./restart-all.sh --bf
```

### 6.2 서버가 시작되지 않는 경우

```bash
# 1. 로그 확인
tail -50 gli_api-server/logs/gli_api-server.log

# 2. 포트 점유 확인
lsof -i :8000

# 3. 프로세스 확인
ps aux | grep gli_api-server

# 4. 강제 재시작
pkill -9 -f gli_api-server
./restart-api-server.sh --bf
```

### 6.3 Docker Desktop 미실행

**증상**: "Cannot connect to the Docker daemon" 에러

**해결 방법**:
```bash
# 1. Docker Desktop 시작
open -a "Docker Desktop"

# 2. Docker 상태 확인 (최대 60초 대기)
for i in {1..60}; do
  if docker info >/dev/null 2>&1; then
    echo "Docker is ready!"
    break
  fi
  sleep 1
done

# 3. 서비스 재시작
./restart-all.sh --bf
```

### 6.4 데이터베이스 연결 실패

**증상**: "Connection refused" 또는 "could not connect to server"

**해결 방법**:
```bash
# 1. Docker 컨테이너 상태 확인
docker ps
cd gli_database
docker-compose ps

# 2. 데이터베이스 재시작
docker-compose down
docker-compose up -d

# 3. 연결 테스트
psql -h localhost -p 5433 -U postgres -d gli

# 4. 로그 확인
docker logs gli_DB_local
```

### 6.5 AWS S3 접근 오류

**증상**: "Access Denied" 또는 "Invalid credentials"

**해결 방법**:
```bash
# 1. 환경 변수 파일 확인
cat gli_api-server/.env.development | grep AWS

# 2. 필수 변수 존재 확인
# AWS_ACCESS_KEY_ID
# AWS_SECRET_ACCESS_KEY
# AWS_STORAGE_BUCKET_NAME
# AWS_S3_REGION

# 3. Django 서버 재시작 (환경 변수 재로드)
./restart-api-server.sh --bf
```

### 6.6 Redis 연결 실패

**증상**: "Error connecting to Redis"

**해결 방법**:
```bash
# 1. Redis 상태 확인
redis-cli ping  # 응답: PONG이어야 함

# 2. Redis 재시작
./restart-redis.sh --bf

# 3. 또는 Docker 재시작
cd gli_redis
docker-compose down
docker-compose up -d

# 4. 포트 확인
lsof -i :6379
```

### 6.7 Frontend 빌드 오류

**증상**: "Module not found" 또는 빌드 실패

**해결 방법**:
```bash
# 1. node_modules 재설치
cd gli_user-frontend
rm -rf node_modules package-lock.json
npm install

# 2. 캐시 삭제
npm cache clean --force

# 3. 재시작
cd ..
./restart-user-frontend.sh --bf
```

### 6.8 모든 서비스 강제 종료 및 재시작

```bash
# 1. 모든 GLI 프로세스 강제 종료
pkill -9 -f gli_

# 2. Docker 컨테이너 중지
cd gli_database && docker-compose down
cd ../gli_redis && docker-compose down
cd ../gli_rabbitmq && docker-compose down
cd ..

# 3. 포트 확인
lsof -i :6379 -i :15672 -i :5433 -i :8000 -i :8080 -i :3000 -i :3001

# 4. 필요시 남은 프로세스 종료
kill -9 <PID>

# 5. 전체 재시작
./restart-all.sh --bf
```

---

## 7. 환경 설정

### 7.1 포트 변경

#### User Frontend (3000 → 다른 포트)

**파일**: `gli_user-frontend/package.json`
```json
{
  "scripts": {
    "dev": "vite --port 3000"  // 변경: vite --port 3005
  }
}
```

#### Admin Frontend (3001 → 다른 포트)

**파일**: `gli_admin-frontend/package.json`
```json
{
  "scripts": {
    "dev": "vite --port 3001"  // 변경: vite --port 3006
  }
}
```

#### Django API (8000 → 다른 포트)

**파일**: `restart-api-server.sh`
```bash
# 방법 1: PORT 환경 변수 사용
PORT=8001 ./restart-api-server.sh --bf

# 방법 2: 스크립트 수정
# runserver 0.0.0.0:8000 → runserver 0.0.0.0:8001
```

#### PostgreSQL (5433 → 다른 포트)

**파일**: `gli_database/docker-compose.yml`
```yaml
services:
  postgres:
    ports:
      - "5433:5432"  # 변경: "5434:5432"
```

### 7.2 환경 변수 설정

각 프로젝트의 환경 변수 파일:

| 서비스 | 환경 변수 파일 | 주요 변수 |
|--------|---------------|----------|
| User Frontend | `gli_user-frontend/.env` | `VITE_API_URL`, `VITE_WS_URL` |
| Admin Frontend | `gli_admin-frontend/.env` | `VITE_API_URL`, `VITE_WS_URL` |
| Django API | `gli_api-server/.env.development` | `DATABASE_URL`, `REDIS_URL`, `AWS_*` |
| WebSocket | `gli_websocket/.env` | `REDIS_URL`, `PORT` |

### 7.3 Django 환경 전환

```bash
# 개발 환경 (기본값)
DJANGO_ENV=development ./restart-api-server.sh --bf

# 스테이징 환경
DJANGO_ENV=staging ./restart-api-server.sh --bf

# 프로덕션 환경
DJANGO_ENV=production ./restart-api-server.sh --bf
```

### 7.4 로그 레벨 변경

**Django API**:
```bash
# .env.development
LOG_LEVEL=DEBUG  # DEBUG, INFO, WARNING, ERROR, CRITICAL
```

**Frontend**:
```bash
# .env
VITE_LOG_LEVEL=debug  # debug, info, warn, error
```

---

## 8. 요구사항

### 8.1 필수 소프트웨어

| 소프트웨어 | 최소 버전 | 설치 확인 |
|-----------|----------|----------|
| Node.js | v18 이상 | `node --version` |
| Python | v3.11 이상 | `python --version` |
| Docker Desktop | 최신 | `docker --version` |
| Docker Compose | v2 이상 | `docker-compose --version` |
| uv | 최신 | `uv --version` |
| Redis CLI | 최신 (선택) | `redis-cli --version` |
| PostgreSQL Client | 최신 (선택) | `psql --version` |

### 8.2 설치 확인 스크립트

```bash
#!/bin/bash

echo "=== GLI Platform 요구사항 확인 ==="

# Node.js
if command -v node &> /dev/null; then
  echo "✅ Node.js: $(node --version)"
else
  echo "❌ Node.js: 미설치"
fi

# Python
if command -v python &> /dev/null; then
  echo "✅ Python: $(python --version)"
else
  echo "❌ Python: 미설치"
fi

# Docker
if command -v docker &> /dev/null; then
  echo "✅ Docker: $(docker --version)"
else
  echo "❌ Docker: 미설치"
fi

# Docker Compose
if command -v docker-compose &> /dev/null; then
  echo "✅ Docker Compose: $(docker-compose --version)"
else
  echo "❌ Docker Compose: 미설치"
fi

# uv
if command -v uv &> /dev/null; then
  echo "✅ uv: $(uv --version)"
else
  echo "❌ uv: 미설치"
fi
```

### 8.3 시스템 요구사항

**하드웨어**:
- CPU: 4코어 이상 (권장)
- RAM: 8GB 이상 (권장 16GB)
- 디스크: 20GB 이상 여유 공간

**운영체제**:
- macOS 11 (Big Sur) 이상
- Ubuntu 20.04 이상
- Windows 10/11 (WSL2 사용)

---

## 9. 추가 정보

### 9.1 스크립트 요약

#### start-*.sh 스크립트 (기본 시작)

```bash
./start-all-services.sh     # 모든 서비스
./start-database.sh         # PostgreSQL만
./start-api-server.sh       # Django API만
./start-user-frontend.sh    # User Frontend만
./start-admin-frontend.sh   # Admin Frontend만
```

#### restart-*.sh 스크립트 (재시작 + 옵션)

```bash
./restart-all.sh --bf                        # 모든 서비스 (백그라운드)
./restart-redis.sh --bf                      # Redis만
./restart-rabbitmq.sh --bf                   # RabbitMQ만
./restart-database.sh --bf                   # PostgreSQL만
./restart-api-server.sh --bf                 # Django API만
./restart-websocket.sh --bf                  # WebSocket만
./restart-user-frontend.sh --bf              # User Frontend만
./restart-admin-frontend.sh --bf             # Admin Frontend만
```

### 9.2 권장 개발 워크플로우

#### 일일 개발 시작

```bash
# 1. 루트 디렉토리로 이동
cd /path/to/gli_root

# 2. 모든 서비스 백그라운드 실행
./restart-all.sh --bf

# 3. 서비스 정상 동작 확인
curl http://localhost:8000/api/common/health/
open http://localhost:3000
open http://localhost:3001

# 4. 로그 모니터링 (필요시)
tail -f gli_api-server/logs/gli_api-server.log
```

#### 개별 서비스만 개발하는 경우

```bash
# 예: User Frontend만 작업하는 경우

# 1. 의존 서비스만 실행
./restart-database.sh --bf
./restart-api-server.sh --bf

# 2. Frontend는 포그라운드로 실행 (hot reload)
cd gli_user-frontend
npm run dev
```

#### 작업 종료 시

```bash
# 1. 모든 서비스 중지
./stop-all-services.sh

# 또는 백그라운드 프로세스만 종료
pkill -f gli_
```

### 9.3 주의사항

1. **포트 충돌**: 지정된 포트들이 이미 사용 중이지 않은지 확인
2. **Docker 실행**: Docker Desktop이 실행 중인지 확인
3. **권한**: 스크립트 실행 권한 확인 (`chmod +x *.sh`)
4. **로그 공간**: 로그 파일이 누적되므로 주기적으로 정리 필요
5. **환경 변수**: `.env` 파일이 올바르게 설정되어 있는지 확인
6. **의존성**: 서비스 실행 순서 준수 (특히 DB → API 순서)

### 9.4 성능 최적화 팁

```bash
# 1. 불필요한 서비스 제외
# 예: WebSocket이 필요 없는 경우
./restart-redis.sh --bf
./restart-database.sh --bf
./restart-api-server.sh --bf
./restart-user-frontend.sh --bf

# 2. 로그 레벨 낮추기 (프로덕션에서)
# .env에서 LOG_LEVEL=WARNING

# 3. 정기적인 로그 정리
find . -name "*.log" -type f -mtime +7 -delete  # 7일 이상 된 로그 삭제
```

---

## 10. 빠른 참조

### 자주 사용하는 명령어

```bash
# 전체 재시작
./restart-all.sh --bf

# 서비스 상태 확인
curl http://localhost:8000/api/common/health/
docker ps
pgrep -f gli_ | wc -l

# 로그 확인
tail -f gli_api-server/logs/gli_api-server.log

# 강제 종료
pkill -9 -f gli_

# 포트 확인
lsof -i :8000 -i :3000 -i :3001

# Django Admin 슈퍼유저 생성
cd gli_api-server
uv run python manage.py createsuperuser
```

### 트러블슈팅 체크리스트

- [ ] Docker Desktop 실행 중인가?
- [ ] 포트 충돌이 없는가? (`lsof -i :포트`)
- [ ] 로그에 에러 메시지가 있는가? (`tail -f logs/*.log`)
- [ ] 환경 변수가 올바른가? (`.env*` 파일)
- [ ] 의존성이 설치되어 있는가? (`npm install`, `uv sync`)
- [ ] 데이터베이스가 마이그레이션되었는가? (`python manage.py migrate`)

---

## 📞 지원 및 문의

문제가 지속되면:
1. 로그 파일 확인 (`logs/` 디렉토리)
2. GitHub Issues에 문제 등록
3. DevOps 팀에 문의

---

**최종 업데이트**: 2025-10-15
**작성자**: DevOps 팀
**버전**: 1.0

