#!/bin/bash

# gli-monitor.sh
# GLI Platform 실시간 통합 모니터링 툴
# RabbitMQ + PostgreSQL + Redis + Django + WebSocket + Frontend 전체 서비스 모니터링

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m'

# 커서 제어 상수
CURSOR_UP='\033[A'
CURSOR_DOWN='\033[B'
CURSOR_HOME='\033[H'
CLEAR_LINE='\033[2K'
SAVE_CURSOR='\033[s'
RESTORE_CURSOR='\033[u'
HIDE_CURSOR='\033[?25l'
SHOW_CURSOR='\033[?25h'

# 설정
INTERVAL=2
ROOT_DIR=$(pwd)
LOG_DIR="$ROOT_DIR/logs"
FULL_REFRESH_INTERVAL=30  # 전체 화면 새로고침 주기 (초)

# 상태 추적 변수
PREV_SYSTEM_INFO=""
FIRST_RUN=true
LAST_FULL_REFRESH=0
declare -a PREV_SERVICE_STATUS
TOTAL_SERVICES=${#SERVICES[@]}

# 서비스 정의 배열 (포트|서비스명|타입|경로|실행명령)
SERVICES=(
  "6379|Redis|DOCKER|gli_redis|docker run -d redis:7-alpine"
  "5672|RabbitMQ (AMQP)|DOCKER|gli_rabbitmq|./restart-rabbitmq.sh"
  "15672|RabbitMQ Mgmt.|DOCKER|gli_rabbitmq|./restart-rabbitmq.sh"
  "5433|PostgreSQL|DOCKER|gli_database|./restart-database.sh"
  "8000|Django API|APP|gli_api-server|uv run python manage.py runserver"
  "8080|WebSocket Server|APP|gli_websocket|npm start"
  "3000|User Frontend|APP|gli_user-frontend|npm run dev"
  "3001|Admin Frontend|APP|gli_admin-frontend|npm run dev"
)

# 키보드 입력 모드 설정
setup_keyboard() {
  # 원래 터미널 설정 저장
  OLD_STTY_CFG=$(stty -g 2>/dev/null || echo "")
  # 키 입력을 즉시 받도록 설정
  if [ -t 0 ]; then
    stty -icanon -echo min 0 time 1 2>/dev/null
  fi
  # 커서 숨기기
  echo -e "${HIDE_CURSOR}"
}

# 터미널 설정 복원
restore_keyboard() {
  if [ -n "$OLD_STTY_CFG" ] && [ -t 0 ]; then
    stty $OLD_STTY_CFG 2>/dev/null
  fi
  echo -e "${SHOW_CURSOR}"
}

# 시그널 핸들러
cleanup() {
  restore_keyboard
  clear
  echo -e "\n${GREEN}✅ GLI Monitor가 정상적으로 종료되었습니다.${NC}"
  exit 0
}

trap cleanup SIGINT SIGTERM

# 상태 체크 함수
check_service_status() {
  local port=$1
  local type=$2
  local service_path=$3

  if [ "$type" = "DOCKER" ]; then
    # Docker 컨테이너 상태 확인 - 포트 기반으로 정확히 매칭
    local container_name=""

    # 포트로 컨테이너 매핑
    case $port in
      6379)
        container_name="gli_redis"
        ;;
      5672|15672)
        container_name="gli_rabbitmq"
        ;;
      5433)
        container_name="gli_DB_local"
        ;;
    esac

    # 특정 컨테이너가 실행 중인지 확인
    if [ -n "$container_name" ]; then
      local container_status=$(docker ps --filter "name=$container_name" --format "{{.Status}}" 2>/dev/null)
      if [ -n "$container_status" ]; then
        echo -e "${GREEN}RUNNING${NC}|docker|0.0|0.0"
      else
        echo -e "${RED}STOPPED${NC}|-|-|-"
      fi
    else
      echo -e "${RED}STOPPED${NC}|-|-|-"
    fi
  else
    # 일반 프로세스 상태 확인
    local pid=$(lsof -i :$port -sTCP:LISTEN -t 2>/dev/null | head -n 1)
    if [ -n "$pid" ]; then
      local cpu=$(ps -p $pid -o %cpu= 2>/dev/null | awk '{print $1}' | head -n 1)
      local mem=$(ps -p $pid -o %mem= 2>/dev/null | awk '{print $1}' | head -n 1)
      local uptime=$(ps -p $pid -o etime= 2>/dev/null | awk '{print $1}' | head -n 1)
      [ -z "$cpu" ] && cpu="0.0"
      [ -z "$mem" ] && mem="0.0"
      [ -z "$uptime" ] && uptime="0:00"
      echo -e "${GREEN}RUNNING${NC}|$pid|$cpu|$mem|$uptime"
    else
      echo -e "${RED}STOPPED${NC}|-|-|-|-"
    fi
  fi
}

# 로그 파일 크기 확인
get_log_size() {
  local service_name=$1
  local log_file=""

  case $service_name in
    "Django API") log_file="$LOG_DIR/gli_api-server.log" ;;
    "WebSocket Server") log_file="$LOG_DIR/gli_websocket.log" ;;
    "User Frontend") log_file="$LOG_DIR/gli_user-frontend.log" ;;
    "Admin Frontend") log_file="$LOG_DIR/gli_admin-frontend.log" ;;
    "RabbitMQ (AMQP)") log_file="$LOG_DIR/rabbitmq.log" ;;
    "PostgreSQL") log_file="$LOG_DIR/database.log" ;;
  esac

  if [ -f "$log_file" ]; then
    local size=$(du -h "$log_file" 2>/dev/null | cut -f1)
    echo "${size:-0B}"
  else
    echo "0B"
  fi
}

# 시스템 리소스 정보
get_system_info() {
  local cpu_usage=$(top -l 1 -n 0 | grep "CPU usage" | awk '{print $3}' | sed 's/%//' 2>/dev/null || echo "0")
  local mem_usage=$(vm_stat | grep "Pages active" | awk '{print $3}' | sed 's/\.//' 2>/dev/null || echo "0")
  local disk_usage=$(df -h . | tail -1 | awk '{print $5}' | sed 's/%//' 2>/dev/null || echo "0")
  local load_avg=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//' 2>/dev/null || echo "0.0")

  echo "$cpu_usage|$load_avg|$disk_usage"
}

# 특정 라인으로 커서 이동 후 라인 업데이트
update_line() {
  local line_num=$1
  local content="$2"
  echo -e "\033[${line_num};1H${CLEAR_LINE}${content}"
}

# 시스템 정보 라인 업데이트 (4번째 라인)
update_system_info() {
  local system_info=$(get_system_info)
  local network_conn=$(check_network_connections)
  local current_info="${system_info}|${network_conn}"

  if [ "$current_info" != "$PREV_SYSTEM_INFO" ]; then
    IFS='|' read -r sys_cpu sys_load sys_disk net_conn <<<"$current_info"
    local line_content="${WHITE}║ ${CYAN}System CPU: $(printf "%6s" "$sys_cpu")% ${WHITE}│ ${CYAN}Load: $(printf "%4s" "$sys_load") ${WHITE}│   ${CYAN}Disk: $(printf "%5s" "$sys_disk")% ${WHITE}│   ${CYAN}Network: $(printf "%3s" "$net_conn") conn ${WHITE}│ ${CYAN}Refresh: ${INTERVAL}s ${WHITE}║${NC}"

    update_line 4 "$line_content"
    PREV_SYSTEM_INFO="$current_info"
  fi
}

# 서비스 라인 업데이트
update_service_line() {
  local line_num=$1
  local service_index=$2
  local entry="${SERVICES[$service_index]}"

  IFS='|' read -r port name type path command <<<"$entry"
  IFS='|' read -r status pid cpu mem uptime <<<"$(check_service_status $port $type $path)"
  local log_size=$(get_log_size "$name")
  local current_state="${status}|${pid}|${cpu}|${mem}|${log_size}"
  local prev_state="${PREV_SERVICE_STATUS[$service_index]:-}"

  # 상태 문자열 (컬러 없이 먼저 정의)
  local status_text=""
  if [[ "$status" == *"RUNNING"* ]]; then
    status_text="RUNNING"
  else
    status_text="STOPPED"
  fi

  # 고정 폭 패딩 (8자 폭)
  local padded_status=$(printf '%-8s' "$status_text")

  # 컬러 적용
  if [[ "$status_text" == "RUNNING" ]]; then
    status_colored="${GREEN}${padded_status}${WHITE}"
  else
    status_colored="${RED}${padded_status}${WHITE}"
  fi

  local line_content=$(printf "${WHITE}║ ${YELLOW}%-6s${WHITE} │ %-17s │ %b │ %-7s │ %-7s │ %-7s │ %-8s │ %-9s ║${NC}" \
  "$port" "$name" "$status_colored" "$pid" "$cpu" "$mem" "${uptime:-N/A}" "$log_size")

  # 항상 업데이트 (상태 변경 여부와 관계없이)
  update_line $line_num "$line_content"
  PREV_SERVICE_STATUS[$service_index]="$current_state"
}

# 네트워크 연결 상태 확인
check_network_connections() {
  local connections=$(netstat -an 2>/dev/null | grep ESTABLISHED | wc -l)
  echo "${connections:-0}"
}

# 초기 전체 테이블 출력 (최초 1회만)
print_initial_table() {
  clear
  local system_info=$(get_system_info)
  IFS='|' read -r sys_cpu sys_load sys_disk <<<"$system_info"
  local network_conn=$(check_network_connections)

  # 헤더
  echo -e "${WHITE}╔════════════════════════════════════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${WHITE}║                               ${BLUE}🚀 GLI PLATFORM MONITOR${WHITE}                                      ║${NC}"
  echo -e "${WHITE}╠════════════════════════════════════════════════════════════════════════════════════════════╣${NC}"
  printf "${WHITE}║ ${CYAN}System CPU: %6s%% ${WHITE}│ ${CYAN}Load: %4s ${WHITE}│   ${CYAN}Disk: %5s%% ${WHITE}│   ${CYAN}Network: %3s conn ${WHITE}│ ${CYAN}Refresh: %1ss ${WHITE}║${NC}\n" "$sys_cpu" "$sys_load" "$sys_disk" "$network_conn" "$INTERVAL"
  echo -e "${WHITE}╠════════╤═══════════════════╤══════════╤═════════╤═════════╤═════════╤══════════╤═══════════╣${NC}"
  printf "${WHITE}║ %-6s │ %-17s │ %-8s │ %-7s │ %-7s │ %-7s │ %-8s │ %-9s ║${NC}\n" \
    "PORT" "SERVICE" "STATUS" "PID" "CPU%" "MEM%" "UPTIME" "LOG SIZE"
  echo -e "${WHITE}╠════════╪═══════════════════╪══════════╪═════════╪═════════╪═════════╪══════════╪═══════════╣${NC}"

  # 서비스 상태 초기 출력
  local line_num=8
  for i in "${!SERVICES[@]}"; do
    local entry="${SERVICES[$i]}"
    IFS='|' read -r port name type path command <<<"$entry"
    IFS='|' read -r status pid cpu mem uptime <<<"$(check_service_status $port $type $path)"
    local log_size=$(get_log_size "$name")

    # 1. 상태 텍스트 → 패딩
    local status_text=""
    if [[ "$status" == *"RUNNING"* ]]; then
      status_text="RUNNING"
    else
      status_text="STOPPED"
    fi
    local padded_status=$(printf '%-8s' "$status_text")

    # 2. 컬러 적용
    if [[ "$status_text" == "RUNNING" ]]; then
      status_colored="${GREEN}${padded_status}${WHITE}"
    else
      status_colored="${RED}${padded_status}${WHITE}"
    fi

    printf "${WHITE}║ ${YELLOW}%-6s${WHITE} │ %-17s │ %b │ %-7s │ %-7s │ %-7s │ %-8s │ %-9s ║${NC}\n" \
      "$port" "$name" "$status_colored" "$pid" "$cpu" "$mem" "${uptime:-N/A}" "$log_size"

    # 상태 저장
    PREV_SERVICE_STATUS[$i]="${status}|${pid}|${cpu}|${mem}|${log_size}"
    ((line_num++))
  done

  echo -e "${WHITE}╚════════╧═══════════════════╧══════════╧═════════╧═════════╧═════════╧══════════╧═══════════╝${NC}"

  # 시스템 정보 저장
  PREV_SYSTEM_INFO="${sys_cpu}|${sys_load}|${sys_disk}|${network_conn}"
}

# 업데이트된 부분만 다시 그리기
update_display() {
  # 시스템 정보 업데이트
  update_system_info

  # 서비스 상태 업데이트 (라인 8부터 시작)
  local line_num=8
  for i in "${!SERVICES[@]}"; do
    update_service_line $line_num $i
    ((line_num++))
  done
}

# 컨트롤 메뉴
print_controls() {
  echo ""
  echo -e "${WHITE}╔════════════════════════════════════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${WHITE}║                                  ${YELLOW}🎮 INTERACTIVE CONTROLS${WHITE}                                   ║${NC}"
  echo -e "${WHITE}╠════════════════════════════════════════════════════════════════════════════════════════════╣${NC}"
  echo -e "${WHITE}║   ${GREEN}[r]${WHITE} Restart Service    ${GREEN}[l]${WHITE} View Logs        ${GREEN}[s]${WHITE} Start Service      ${GREEN}[q]${WHITE} Quit Monitor      ║${NC}"
  echo -e "${WHITE}║   ${GREEN}[k]${WHITE} Kill Service       ${GREEN}[c]${WHITE} Clear Logs       ${GREEN}[d]${WHITE} Docker Status      ${GREEN}[h]${WHITE} Show Help         ║${NC}"
  echo -e "${WHITE}╚════════════════════════════════════════════════════════════════════════════════════════════╝${NC}"
  echo ""
}

# 로그 뷰어
show_logs() {
  local service=$1
  local log_file=""

  case $service in
    "django" | "api") log_file="$LOG_DIR/gli_api-server.log" ;;
    "websocket" | "ws") log_file="$LOG_DIR/gli_websocket.log" ;;
    "frontend" | "web" | "user") log_file="$LOG_DIR/gli_user-frontend.log" ;;
    "admin") log_file="$LOG_DIR/gli_admin-frontend.log" ;;
    "rabbitmq") log_file="$LOG_DIR/rabbitmq.log" ;;
    "database" | "db") log_file="$LOG_DIR/database.log" ;;
    *)
      echo -e "${RED}❌ Unknown service: $service${NC}"
      echo -e "${YELLOW}Available: django, websocket, frontend, admin, rabbitmq, database${NC}"
      read -p "Press Enter to continue..."
      return
      ;;
  esac

  if [ -f "$log_file" ]; then
    clear
    echo -e "${BLUE}📋 Viewing last 50 lines of $log_file${NC}"
    echo -e "${BLUE}Press 'q' to quit log view${NC}"
    echo "----------------------------------------"
    tail -50 "$log_file"
    echo "----------------------------------------"
    read -p "Press Enter to continue..."
  else
    echo -e "${RED}❌ Log file not found: $log_file${NC}"
    read -p "Press Enter to continue..."
  fi
}

# 서비스 재시작
restart_service() {
  local service=$1
  echo -e "${YELLOW}🔄 Restarting $service...${NC}"

  case $service in
    "all") ./restart_all.sh ;;
    "django" | "api") ./restart-api-server.sh --bf ;;
    "websocket" | "ws") ./restart-websocket.sh --bf ;;
    "frontend" | "web" | "user") ./restart-user-frontend.sh --bf ;;
    "admin") ./restart-admin-frontend.sh --bf ;;
    "rabbitmq") ./restart-rabbitmq.sh --bf ;;
    "database" | "db") ./restart-database.sh --bf ;;
    "redis") ./restart-redis.sh --bf ;;
    *)
      echo -e "${RED}❌ Unknown service: $service${NC}"
      echo -e "${YELLOW}Available: all, django, websocket, frontend, admin, rabbitmq, database, redis${NC}"
      ;;
  esac

  echo -e "${GREEN}✅ Service restart command executed${NC}"
  sleep 2
  read -p "Press Enter to continue..."
}

# 키보드 입력 처리
handle_input() {
  local key=""
  read -n 1 key

  case $key in
    'q' | 'Q') cleanup ;;
    'r' | 'R')
      echo -e "\n${YELLOW}Enter service to restart: ${NC}"
      read -p "> " service
      restart_service "$service"
      ;;
    'l' | 'L')
      echo -e "\n${YELLOW}Enter service to view logs: ${NC}"
      read -p "> " service
      show_logs "$service"
      ;;
    's' | 'S')
      echo -e "\n${YELLOW}Enter service to start: ${NC}"
      read -p "> " service
      restart_service "$service"
      ;;
    'k' | 'K')
      echo -e "\n${YELLOW}Stopping all services...${NC}"
      if [ -f "./stop-all-services.sh" ]; then
        ./stop-all-services.sh --wait 2
        echo -e "${GREEN}✅ All services stopped${NC}"
      else
        echo -e "${RED}❌ stop-all-services.sh not found${NC}"
      fi
      sleep 1
      read -p "Press Enter to continue..."
      ;;
    'c' | 'C')
      echo -e "\n${YELLOW}Clearing all log files...${NC}"
      rm -f "$LOG_DIR"/*.log
      echo -e "${GREEN}✅ Log files cleared${NC}"
      read -p "Press Enter to continue..."
      ;;
    'd' | 'D')
      clear
      echo -e "${BLUE}🐳 Docker Container Status:${NC}\n"
      docker ps -a
      echo ""
      read -p "Press Enter to continue..."
      ;;
    'h' | 'H')
      clear
      echo -e "${BLUE}📚 GLI Monitor Help:${NC}\n"
      echo -e "${YELLOW}Commands:${NC}"
      echo -e "  r - Restart service (all, django, websocket, frontend, admin, rabbitmq, database, redis)"
      echo -e "  l - View logs (django, websocket, frontend, admin, rabbitmq, database)"
      echo -e "  s - Start service (same options as restart)"
      echo -e "  k - Stop all services"
      echo -e "  c - Clear all log files"
      echo -e "  d - Show Docker container status"
      echo -e "  q - Quit monitor"
      echo ""
      read -p "Press Enter to continue..."
      ;;
  esac
}

# 메인 실행 함수
main() {
  setup_keyboard

  echo -e "${GREEN}🚀 Starting GLI Platform Monitor...${NC}"
  sleep 1

  while true; do
    local current_time=$(date +%s)

    # 첫 실행이거나 30초마다 전체 화면 새로고침
    if [ "$FIRST_RUN" = true ] || [ $((current_time - LAST_FULL_REFRESH)) -ge $FULL_REFRESH_INTERVAL ]; then
      print_initial_table
      if [ "$FIRST_RUN" = true ]; then
        print_controls
        FIRST_RUN=false
      fi
      LAST_FULL_REFRESH=$current_time
      # 상태 배열 초기화 (새로고침 시 모든 상태를 새로 가져오기 위함)
      unset PREV_SERVICE_STATUS
      declare -a PREV_SERVICE_STATUS
      PREV_SYSTEM_INFO=""
    else
      update_display
    fi

    # 비차단 키 입력 확인
    if read -t 0; then
      handle_input
    fi

    sleep $INTERVAL
  done
}

# 스크립트 시작
main
