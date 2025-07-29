# GLI Platform Service Startup Guide

GLI 플랫폼의 모든 서비스를 고정 포트로 실행할 수 있는 스크립트 모음입니다.

## 🚀 서비스 포트 구성

| 서비스 | 포트 | URL |
|--------|------|-----|
| User Frontend | 3000 | http://localhost:3000 |
| Admin Frontend | 3001 | http://localhost:3001 |
| Django API Server | 8000 | http://localhost:8000 |
| PostgreSQL Database | 5433 | localhost:5433 |
| Redis | 6379 | localhost:6379 |

## 📝 실행 스크립트

### 1. 모든 서비스 한번에 실행
```bash
./start-all-services.sh
```
- 모든 서비스를 백그라운드에서 동시에 실행
- 서비스 상태 모니터링
- Ctrl+C로 모든 서비스 일괄 종료
- 로그는 `logs/` 디렉토리에 저장

### 2. 개별 서비스 실행
```bash
# 데이터베이스만 실행
./start-database.sh

# Django API 서버만 실행  
./start-api-server.sh

# 사용자 프론트엔드만 실행
./start-user-frontend.sh

# 관리자 프론트엔드만 실행
./start-admin-frontend.sh
```

### 3. 모든 서비스 중지
```bash
./stop-all-services.sh
```

## 🔧 사용법

### 전체 서비스 실행
```bash
# 1. 루트 디렉토리로 이동
cd /path/to/gli_root

# 2. 모든 서비스 실행
./start-all-services.sh

# 3. 브라우저에서 접속
# User Frontend: http://localhost:3000
# Admin Frontend: http://localhost:3001
```

### 개발 시 권장 워크플로우
```bash
# 1. 데이터베이스 먼저 실행
./start-database.sh

# 2. API 서버 실행 (새 터미널)
./start-api-server.sh

# 3. 프론트엔드 실행 (새 터미널)
./start-user-frontend.sh    # 또는
./start-admin-frontend.sh   # 또는 둘 다
```

## 📊 서비스 상태 확인

### 포트 사용 확인
```bash
# 모든 포트 확인
lsof -i :3000 -i :3001 -i :8000 -i :5433

# 개별 포트 확인
lsof -i :3000  # User Frontend
lsof -i :3001  # Admin Frontend  
lsof -i :8000  # Django API
lsof -i :5433  # PostgreSQL
```

### 프로세스 확인
```bash
# Node.js 프로세스 확인
ps aux | grep node

# Python/Django 프로세스 확인
ps aux | grep python

# Docker 컨테이너 확인
docker ps
```

## 🐛 문제 해결

### 포트 충돌 시
```bash
# 포트를 사용하는 프로세스 확인
lsof -i :포트번호

# 프로세스 강제 종료
kill -9 PID번호

# 또는 모든 서비스 중지 스크립트 실행
./stop-all-services.sh
```

### 로그 확인
```bash
# 실시간 로그 확인
tail -f logs/django.log
tail -f logs/user-frontend.log  
tail -f logs/admin-frontend.log

# 전체 로그 확인
cat logs/django.log
cat logs/user-frontend.log
cat logs/admin-frontend.log
```

### 데이터베이스 연결 문제
```bash
# Docker 컨테이너 상태 확인
docker ps
docker-compose ps

# 데이터베이스 재시작
cd gli_database
docker-compose down
docker-compose up -d
```

## ⚙️ 설정 커스터마이징

### 포트 변경
각 서비스의 포트를 변경하려면:

1. **User Frontend**: `gli_user-frontend/package.json`의 `"dev": "vite --port 3000"` 수정
2. **Admin Frontend**: `gli_admin-frontend/package.json`의 `"dev": "vite --port 3001"` 수정  
3. **Django API**: `start-api-server.sh`의 `runserver 0.0.0.0:8000` 수정
4. **Database**: `gli_database/docker_compose.yml`의 포트 매핑 수정

### 환경 변수
각 프로젝트의 환경 변수 파일:
- User Frontend: `gli_user-frontend/.env`
- Admin Frontend: `gli_admin-frontend/.env` 
- Django API: `gli_api-server/.env`

## 📋 요구사항

### 필수 소프트웨어
- Node.js (v18 이상)
- Python (v3.11 이상)  
- Docker & Docker Compose
- uv (Python 패키지 매니저)

### 설치 확인
```bash
node --version
python --version
docker --version
docker-compose --version
uv --version
```

## 🚨 주의사항

1. **포트 충돌**: 지정된 포트들이 이미 사용 중이지 않은지 확인
2. **Docker 실행**: Docker Desktop이 실행 중인지 확인
3. **권한**: 스크립트 실행 권한 확인 (`chmod +x *.sh`)
4. **로그 공간**: 로그 파일이 누적되므로 주기적으로 정리 필요

## 📞 지원

문제가 발생하면 다음을 확인해주세요:
1. 모든 요구사항이 설치되어 있는지 확인
2. 포트 충돌이 없는지 확인  
3. 로그 파일에서 에러 메시지 확인
4. Docker 컨테이너가 정상적으로 실행되고 있는지 확인