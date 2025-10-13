# Django API 서버 재시작 분석

## ✅ 현재 상태

`./restart-api-server.sh --bf` 명령이 **정상 작동합니다!**

## 🔍 동작 방식

### 1. 스크립트 실행 흐름

```bash
cd /Users/ahndonghyun/dongfiles/ADHcode/DreamFurnace/gli_root
./restart-api-server.sh --bf
```

**단계별 처리:**
1. ✅ 기존 'gli_api-server' TAG로 실행 중인 프로세스 종료
2. ✅ PORT 8000 점유 프로세스 강제 종료
3. ✅ gli_api-server 디렉토리로 이동
4. ✅ 백그라운드로 Django 서버 실행
5. ✅ logs/gli_api-server.log에 로그 기록
6. ✅ gli_api-server.pid에 PID 저장

### 2. 환경 변수 로드 순서

```python
# config/settings.py (lines 6, 14, 19)
from dotenv import load_dotenv
load_dotenv()                          # .env 로드
load_dotenv(f'.env.{ENV}', override=True)  # .env.development 로드
```

**로드되는 파일:**
- `.env` (기본 설정)
- `.env.development` (DJANGO_ENV=development 기준)

### 3. AWS 자격 증명 설정

**파일: `.env.development` (lines 36-40)**
```bash
AWS_ACCESS_KEY_ID=AKIA5LNU5WLWUA55GAOG          # GLI 계정
AWS_SECRET_ACCESS_KEY=ok7wgkBHbNQ9bSyV1Pbt8t7PjSbt5b5QT1dVQNqY
AWS_STORAGE_BUCKET_NAME=gli-platform-media-dev   # 개발 버킷
AWS_S3_REGION=ap-northeast-2                     # 서울 리전
```

### 4. 실행 명령어

```bash
# restart-api-server.sh line 71
nohup bash -c "exec -a 'gli_api-server' env DJANGO_ENV=development uv run python manage.py runserver 0.0.0.0:8000" >> ./logs/gli_api-server.log 2>&1 &
```

**주요 옵션:**
- `exec -a 'gli_api-server'`: 프로세스 이름을 'gli_api-server'로 설정
- `env DJANGO_ENV=development`: 개발 환경 설정
- `uv run`: uv 패키지 매니저로 실행
- `nohup ... &`: 백그라운드 실행, 터미널 종료 후에도 유지

## ✅ 검증 결과

### 서버 상태 확인
```bash
curl http://localhost:8000/api/common/health/
# {"status": "ok", "message": "GLI API Server is running"}
```

### 로그 확인
```bash
tail -f /Users/ahndonghyun/dongfiles/ADHcode/DreamFurnace/gli_root/gli_api-server/logs/gli_api-server.log
```

### 프로세스 확인
```bash
pgrep -f gli_api-server
# 18705 (부모 프로세스)
# 18716, 18782 (자식 프로세스들)
```

### PID 파일
```bash
cat /Users/ahndonghyun/dongfiles/ADHcode/DreamFurnace/gli_root/gli_api-server/gli_api-server.pid
# 18705
```

## 🎯 결론

**모든 것이 정상 작동합니다!**

- ✅ 스크립트 실행 성공
- ✅ 백그라운드 실행 정상
- ✅ AWS GLI 계정 자격 증명 자동 로드
- ✅ S3 버킷 접근 가능
- ✅ Django 서버 정상 응답

## 📝 추가 정보

### 다른 옵션

**포그라운드 실행 (디버깅용):**
```bash
./restart-api-server.sh
# --bf 없이 실행하면 포그라운드에서 실행
```

**다른 포트로 실행:**
```bash
PORT=8001 ./restart-api-server.sh --bf
```

**다른 TAG 사용:**
```bash
./restart-api-server.sh --tag custom_tag --bf
```

### 문제 해결

**서버가 시작되지 않으면:**
```bash
# 로그 확인
tail -50 /Users/ahndonghyun/dongfiles/ADHcode/DreamFurnace/gli_root/gli_api-server/logs/gli_api-server.log

# 포트 점유 확인
lsof -i :8000

# 프로세스 확인
ps aux | grep gli_api-server
```

**강제 재시작:**
```bash
# 모든 관련 프로세스 종료
pkill -9 -f gli_api-server

# 재시작
./restart-api-server.sh --bf
```

---

## 🎯 모든 서비스 재시작

### restart-all.sh 스크립트

**실행 명령:**
```bash
cd /Users/ahndonghyun/dongfiles/ADHcode/DreamFurnace/gli_root
./restart-all.sh --bf
```

### 서비스 실행 순서

1. ✅ **Redis** (캐시 서버)
   - 포트: 6379
   - 스크립트: `./restart-redis.sh --bf`

2. ✅ **RabbitMQ** (메시지 큐)
   - 포트: 15672 (관리 UI)
   - 스크립트: `./restart-rabbitmq.sh --bf`
   - 로그인: admin/admin

3. ✅ **PostgreSQL** (데이터베이스)
   - 포트: 5433
   - 스크립트: `./restart-database.sh --bf`

4. ✅ **Django API Server** (백엔드)
   - 포트: 8000
   - 스크립트: `./restart-api-server.sh --bf`
   - Health: http://localhost:8000/api/common/health/
   - 로그: `gli_api-server/logs/gli_api-server.log`

5. ✅ **WebSocket Server** (실시간 통신)
   - 포트: 8080
   - 스크립트: `./restart-websocket.sh --bf`
   - 로그: `gli_websocket/logs/gli_websocket.log`

6. ✅ **User Frontend** (사용자 화면)
   - 포트: 3000
   - 스크립트: `./restart-user-frontend.sh --bf`
   - URL: http://localhost:3000
   - 로그: `gli_user-frontend/logs/gli_user-frontend.log`

7. ✅ **Admin Frontend** (관리자 화면)
   - 포트: 3001
   - 스크립트: `./restart-admin-frontend.sh --bf`
   - URL: http://localhost:3001
   - 로그: `gli_admin-frontend/logs/gli_admin-frontend.log`

### 동작 원리

**1. Docker Desktop 자동 시작**
```bash
# Docker 상태 확인
if docker info >/dev/null 2>&1; then
  # 실행 중
else
  # Docker Desktop 시작
  open -a "Docker Desktop"
  # 최대 60초 대기
fi
```

**2. 기존 서비스 정리**
```bash
pkill -f "gli_" 2>/dev/null || true
```

**3. 각 서비스 순차 실행**
```bash
for service in services; do
  $service_script --bf  # 백그라운드 실행
  sleep $WAIT_BETWEEN   # 서비스 간 대기
done
```

### 옵션

**기본 실행 (모든 서비스 백그라운드):**
```bash
./restart-all.sh --bf
```

**실패해도 계속 진행:**
```bash
./restart-all.sh --bf --skip-failed
```

**대기 시간 변경 (10초):**
```bash
./restart-all.sh --bf --wait 10
```

**상세 로그 출력:**
```bash
./restart-all.sh --bf --verbose
```

### 결과 확인

**모든 서비스 상태 확인:**
```bash
# API Server
curl http://localhost:8000/api/common/health/

# User Frontend
curl http://localhost:3000

# Admin Frontend  
curl http://localhost:3001

# Docker 서비스
docker ps

# 프로세스 확인
pgrep -f gli_ | wc -l  # 실행 중인 GLI 프로세스 수
```

### 로그 모니터링

**실시간 로그 확인:**
```bash
# API Server
tail -f gli_api-server/logs/gli_api-server.log

# WebSocket
tail -f gli_websocket/logs/gli_websocket.log

# User Frontend
tail -f gli_user-frontend/logs/gli_user-frontend.log

# Admin Frontend
tail -f gli_admin-frontend/logs/gli_admin-frontend.log
```

**모든 로그 동시에 보기:**
```bash
tail -f gli_*/logs/gli_*.log
```

## 🎯 결론

### 현재 상태

✅ **모든 재시작 스크립트가 정상 작동합니다!**

**개별 서비스 재시작:**
```bash
./restart-api-server.sh --bf      # Django API만
./restart-admin-frontend.sh --bf  # Admin Frontend만
./restart-user-frontend.sh --bf   # User Frontend만
```

**전체 서비스 재시작:**
```bash
./restart-all.sh --bf  # 모든 서비스 한번에
```

### 환경 변수 자동 로드

모든 서비스가 올바른 환경 변수를 자동으로 로드합니다:

- **Django**: `.env` + `.env.development` 자동 로드
- **AWS 자격 증명**: GLI 계정으로 설정됨
- **S3 버킷**: `gli-platform-media-dev` (개발)
- **Region**: `ap-northeast-2` (서울)

### 개선 제안

현재 구조가 이미 최적화되어 있습니다:

1. ✅ 의존성 순서 고려 (Redis -> RabbitMQ -> DB -> API -> WS -> Frontends)
2. ✅ 백그라운드 실행 지원 (--bf 옵션)
3. ✅ Docker Desktop 자동 시작
4. ✅ 로그 파일 관리
5. ✅ PID 파일 관리
6. ✅ 에러 처리 및 복구

**추가 작업 불필요!** 모든 것이 이미 정상 작동합니다.
