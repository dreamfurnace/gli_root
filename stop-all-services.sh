#!/bin/bash

# GLI Platform - Stop All Services Script
echo "🛑 Stopping all GLI Platform services..."

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

ROOT_DIR=$(pwd)

# Database 중지
echo -e "${BLUE}🔹 Stopping Database...${NC}"
cd "$ROOT_DIR/gli_database"
docker-compose down

# 포트로 프로세스 찾아서 종료
stop_process_on_port() {
    local port=$1
    local service_name=$2
    
    echo -e "${BLUE}🔹 Stopping $service_name (port $port)...${NC}"
    
    local pid=$(lsof -ti :$port)
    if [ ! -z "$pid" ]; then
        kill -TERM $pid 2>/dev/null
        sleep 2
        
        # 여전히 실행 중이면 강제 종료
        if kill -0 $pid 2>/dev/null; then
            kill -KILL $pid 2>/dev/null
        fi
        echo -e "${GREEN}✅ $service_name stopped${NC}"
    else
        echo -e "${YELLOW}⚠️  $service_name was not running${NC}"
    fi
}

# 각 서비스 중지
stop_process_on_port 3000 "User Frontend"
stop_process_on_port 3001 "Admin Frontend" 
stop_process_on_port 8000 "Django API Server"

echo ""
echo -e "${GREEN}🎉 All GLI Platform services have been stopped!${NC}"