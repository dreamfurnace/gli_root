#!/bin/bash

# GLI Platform - All Services Startup Script
# 모든 서비스를 고정 포트로 동시에 실행합니다

echo "🚀 Starting GLI Platform Services..."
echo "=========================================="

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 현재 디렉토리 저장
ROOT_DIR=$(pwd)

# 포트 설정
USER_FRONTEND_PORT=3000
ADMIN_FRONTEND_PORT=3001
API_SERVER_PORT=8000
DATABASE_PORT=5433

# 프로세스 ID 저장을 위한 배열
declare -a PIDS=()

# 시그널 핸들러 - Ctrl+C 감지 시 모든 프로세스 종료
cleanup() {
    echo -e "\n${YELLOW}🛑 Stopping all services...${NC}"
    
    # Database 중지
    echo -e "${BLUE}🔹 Stopping Database...${NC}"
    cd "$ROOT_DIR/gli_database"
    docker-compose down
    
    # 모든 백그라운드 프로세스 종료
    for pid in "${PIDS[@]}"; do
        if kill -0 "$pid" 2>/dev/null; then
            echo -e "${BLUE}🔹 Stopping process $pid...${NC}"
            kill -TERM "$pid" 2>/dev/null
        fi
    done
    
    # 잠시 대기 후 강제 종료
    sleep 2
    for pid in "${PIDS[@]}"; do
        if kill -0 "$pid" 2>/dev/null; then
            echo -e "${RED}🔹 Force killing process $pid...${NC}"
            kill -KILL "$pid" 2>/dev/null
        fi
    done
    
    echo -e "${GREEN}✅ All services stopped.${NC}"
    exit 0
}

# 종료 시그널 등록
trap cleanup SIGINT SIGTERM

# 포트 체크 함수
check_port() {
    local port=$1
    local service=$2
    if lsof -i :$port > /dev/null 2>&1; then
        echo -e "${RED}❌ Port $port is already in use (required for $service)${NC}"
        echo -e "${YELLOW}   Please stop the service using port $port and try again.${NC}"
        return 1
    fi
    return 0
}

# 필수 디렉토리 존재 확인
check_directory() {
    if [ ! -d "$1" ]; then
        echo -e "${RED}❌ Directory not found: $1${NC}"
        return 1
    fi
    return 0
}

# 포트 사용 여부 확인
echo -e "${BLUE}🔍 Checking port availability...${NC}"
check_port $USER_FRONTEND_PORT "User Frontend" || exit 1
check_port $ADMIN_FRONTEND_PORT "Admin Frontend" || exit 1
check_port $API_SERVER_PORT "Django API Server" || exit 1

# 필수 디렉토리 확인
echo -e "${BLUE}🔍 Checking project directories...${NC}"
check_directory "$ROOT_DIR/gli_user-frontend" || exit 1
check_directory "$ROOT_DIR/gli_admin-frontend" || exit 1
check_directory "$ROOT_DIR/gli_api-server" || exit 1
check_directory "$ROOT_DIR/gli_database" || exit 1

echo -e "${GREEN}✅ All checks passed!${NC}"
echo ""

# 1. Database 시작
echo -e "${BLUE}🔹 Starting Database (PostgreSQL + Redis)...${NC}"
cd "$ROOT_DIR/gli_database"
docker-compose up -d
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Database started on port $DATABASE_PORT${NC}"
else
    echo -e "${RED}❌ Failed to start database${NC}"
    exit 1
fi

# 데이터베이스 준비 대기
echo -e "${YELLOW}⏳ Waiting for database to be ready...${NC}"
sleep 5

# 2. Django API Server 시작
echo -e "${BLUE}🔹 Starting Django API Server...${NC}"
cd "$ROOT_DIR/gli_api-server"
/Users/ahndonghyun/.cargo/bin/uv run python manage.py runserver 0.0.0.0:$API_SERVER_PORT > ../logs/django.log 2>&1 &
DJANGO_PID=$!
PIDS+=($DJANGO_PID)
sleep 5

# Django 서버 헬스 체크
if kill -0 $DJANGO_PID 2>/dev/null; then
    echo -e "${GREEN}✅ Django API Server started on port $API_SERVER_PORT (PID: $DJANGO_PID)${NC}"
else
    echo -e "${RED}❌ Failed to start Django API Server${NC}"
    echo -e "${RED}   Check logs/django.log for details${NC}"
    cleanup
    exit 1
fi

# 3. User Frontend 시작
echo -e "${BLUE}🔹 Starting User Frontend...${NC}"
cd "$ROOT_DIR/gli_user-frontend"
/Users/ahndonghyun/.nvm/versions/node/v20.19.1/bin/npm run dev > ../logs/user-frontend.log 2>&1 &
USER_FRONTEND_PID=$!
PIDS+=($USER_FRONTEND_PID)
sleep 5

if kill -0 $USER_FRONTEND_PID 2>/dev/null; then
    echo -e "${GREEN}✅ User Frontend started on port $USER_FRONTEND_PORT (PID: $USER_FRONTEND_PID)${NC}"
else
    echo -e "${RED}❌ Failed to start User Frontend${NC}"
    echo -e "${RED}   Check logs/user-frontend.log for details${NC}"
    cleanup
    exit 1
fi

# 4. Admin Frontend 시작
echo -e "${BLUE}🔹 Starting Admin Frontend...${NC}"
cd "$ROOT_DIR/gli_admin-frontend"
/Users/ahndonghyun/.nvm/versions/node/v20.19.1/bin/npm run dev > ../logs/admin-frontend.log 2>&1 &
ADMIN_FRONTEND_PID=$!
PIDS+=($ADMIN_FRONTEND_PID)
sleep 5

if kill -0 $ADMIN_FRONTEND_PID 2>/dev/null; then
    echo -e "${GREEN}✅ Admin Frontend started on port $ADMIN_FRONTEND_PORT (PID: $ADMIN_FRONTEND_PID)${NC}"
else
    echo -e "${RED}❌ Failed to start Admin Frontend${NC}"
    echo -e "${RED}   Check logs/admin-frontend.log for details${NC}"
    cleanup
    exit 1
fi

# 서비스 시작 완료
echo ""
echo -e "${GREEN}🎉 All GLI Platform services are now running!${NC}"
echo "=========================================="
echo -e "${BLUE}📱 User Frontend:     ${GREEN}http://localhost:$USER_FRONTEND_PORT${NC}"
echo -e "${BLUE}⚙️  Admin Frontend:    ${GREEN}http://localhost:$ADMIN_FRONTEND_PORT${NC}"
echo -e "${BLUE}🔗 API Server:        ${GREEN}http://localhost:$API_SERVER_PORT${NC}"
echo -e "${BLUE}🗄️  Database:          ${GREEN}localhost:$DATABASE_PORT${NC}"
echo "=========================================="
echo -e "${YELLOW}📝 Logs are saved in: $ROOT_DIR/logs/${NC}"
echo -e "${YELLOW}🛑 Press Ctrl+C to stop all services${NC}"
echo ""

# 서비스 상태 모니터링 루프
while true; do
    sleep 10
    
    # 각 서비스 상태 확인
    for pid in "${PIDS[@]}"; do
        if ! kill -0 "$pid" 2>/dev/null; then
            echo -e "${RED}❌ Service with PID $pid has stopped unexpectedly${NC}"
            cleanup
            exit 1
        fi
    done
done