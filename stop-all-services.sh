#!/bin/bash

# GLI Platform - Stop All Services Script
echo "🛑 Stopping all GLI Platform services..."

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[94m'
NC='\033[0m' # No Color

# 인수 파싱
WAIT_SEC="${WAIT_SEC:-2}"
while [[ ${1:-} ]]; do
  case "$1" in
    --wait) WAIT_SEC="$2"; shift 2;;
    *) shift;;
  esac
done

ROOT_DIR=$(pwd)

# Docker 컨테이너 중지 함수
stop_docker_container() {
    local container_name=$1
    local service_name=$2

    echo -e "${BLUE}🔹 Stopping $service_name (Docker: $container_name)...${NC}"

    # 컨테이너가 존재하는지 확인 (실행 중이거나 stopped 상태 모두 포함)
    if docker ps -a --format '{{.Names}}' | grep -q "^${container_name}$"; then
        docker stop "$container_name" >/dev/null 2>&1
        docker rm "$container_name" >/dev/null 2>&1
        echo -e "${GREEN}✅ $service_name stopped${NC}"
    else
        echo -e "${YELLOW}⚠️  $service_name was not running${NC}"
    fi
}

# 포트로 프로세스 찾아서 종료
stop_process_on_port() {
    local port=$1
    local service_name=$2

    echo -e "${BLUE}🔹 Stopping $service_name (port $port)...${NC}"

    local pid=$(lsof -ti :$port 2>/dev/null)
    if [ ! -z "$pid" ]; then
        kill -TERM $pid 2>/dev/null
        sleep "$WAIT_SEC"

        # 여전히 실행 중이면 강제 종료
        if kill -0 $pid 2>/dev/null; then
            kill -KILL $pid 2>/dev/null
        fi
        echo -e "${GREEN}✅ $service_name stopped${NC}"
    else
        echo -e "${YELLOW}⚠️  $service_name was not running${NC}"
    fi
}

# 태그로 프로세스 찾아서 종료
stop_process_by_tag() {
    local tag=$1
    local service_name=$2

    echo -e "${BLUE}🔹 Stopping $service_name (tag: $tag)...${NC}"

    if pgrep -f "$tag" >/dev/null 2>&1; then
        pkill -TERM -f "$tag" 2>/dev/null
        sleep "$WAIT_SEC"

        # 여전히 실행 중이면 강제 종료
        if pgrep -f "$tag" >/dev/null 2>&1; then
            pkill -KILL -f "$tag" 2>/dev/null
        fi
        echo -e "${GREEN}✅ $service_name stopped${NC}"
    else
        echo -e "${YELLOW}⚠️  $service_name was not running${NC}"
    fi
}

# 1. Docker 컨테이너 중지 (Redis, RabbitMQ, PostgreSQL)
echo ""
echo -e "${BLUE}🐳 Stopping Docker containers...${NC}"
stop_docker_container "gli_redis" "Redis (standalone)"
stop_docker_container "gli_REDIS_local" "Redis (compose)"
stop_docker_container "gli_rabbitmq" "RabbitMQ"
stop_docker_container "gli_DB_local" "PostgreSQL"

# 2. Application 프로세스 중지
echo ""
echo -e "${BLUE}💻 Stopping Application processes...${NC}"
stop_process_on_port 8000 "Django API Server"
stop_process_on_port 8080 "WebSocket Server"
stop_process_on_port 3000 "User Frontend"
stop_process_on_port 3001 "Admin Frontend"

# 3. 태그로 남은 프로세스 정리 (안전장치)
echo ""
echo -e "${BLUE}🧹 Cleaning up remaining processes...${NC}"
stop_process_by_tag "gli_api-server" "Django (by tag)"
stop_process_by_tag "gli_websocket" "WebSocket (by tag)"
stop_process_by_tag "gli_user-frontend" "User Frontend (by tag)"
stop_process_by_tag "gli_admin-frontend" "Admin Frontend (by tag)"

echo ""
echo -e "${GREEN}🎉 All GLI Platform services have been stopped!${NC}"