#!/usr/bin/env bash
set -uo pipefail

# GLI Platform - 모든 서비스 재시작 통합 스크립트

# 기본값
WAIT_BETWEEN="${WAIT_BETWEEN:-1}"    # 서비스 간 대기 시간
SKIP_FAILED="${SKIP_FAILED:-0}"      # 1이면 실패해도 계속 진행
BF_MODE="${BF_MODE:-1}"              # 1이면 모든 서비스를 백그라운드로 실행
VERBOSE="${VERBOSE:-0}"              # 1이면 상세 로그 출력

# 서비스 목록 (순서 중요: 의존성 고려)
# 각 서비스에 --bf 옵션을 강제로 추가하여 백그라운드 실행 보장
SERVICES=(
  "redis:./restart-redis.sh"
  "rabbitmq:./restart-rabbitmq.sh"
  "database:./restart-database.sh"
  "api-server:./restart-api-server.sh"
  "websocket:./restart-websocket.sh"
  "user-frontend:./restart-user-frontend.sh"
  "admin-frontend:./restart-admin-frontend.sh"
)

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 로그 함수
log_info() {
  echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
  echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
  echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

# 사용법
usage() {
  cat <<EOF
사용법: $(basename "$0") [옵션]

옵션:
  --wait N           서비스 간 대기 시간 (초, 기본: ${WAIT_BETWEEN})
  --skip-failed      실패해도 다음 서비스 계속 진행
  --bf               모든 서비스를 백그라운드로 실행
  --verbose          상세 로그 출력
  --help, -h         도움말

환경변수:
  WAIT_BETWEEN       서비스 간 대기 시간
  SKIP_FAILED        1이면 실패해도 계속 진행
  BF_MODE           1이면 백그라운드 실행
  VERBOSE           1이면 상세 로그

예시:
  $(basename "$0")                    # 기본 실행
  $(basename "$0") --bf              # 백그라운드 실행
  $(basename "$0") --skip-failed     # 실패해도 계속
  $(basename "$0") --wait 10         # 10초 대기
EOF
  exit 1
}

# 인수 파싱
while [[ ${1:-} ]]; do
  case "$1" in
    --wait)         WAIT_BETWEEN="$2"; shift 2;;
    --skip-failed)  SKIP_FAILED=1; shift;;
    --bf)           BF_MODE=1; shift;;
    --verbose)      VERBOSE=1; shift;;
    -h|--help)      usage;;
    *)              log_error "알 수 없는 옵션: $1"; usage;;
  esac
done

# 스크립트 디렉토리 확인
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# 전체 서비스 종료 함수 (기존 프로세스 정리)
stop_all_existing_services() {
  log_info "기존 서비스 종료 중..."

  if [[ -f "./stop-all-services.sh" && -x "./stop-all-services.sh" ]]; then
    echo "🛑 기존 서비스 정리 실행..."
    ./stop-all-services.sh --wait 2 2>/dev/null || {
      log_warning "전체 서비스 종료 스크립트 실패. 개별 정리 진행..."
      # 개별 서비스 정리
      pkill -f "gli_" 2>/dev/null || true
    }
  else
    log_warning "stop-all-services.sh 를 찾을 수 없음. 간단한 정리만 수행..."
    pkill -f "gli_" 2>/dev/null || true
  fi

  echo "✅ 기존 서비스 정리 완료"
  sleep 2
}

# Docker Desktop 상태 확인 및 시작 함수
check_and_start_docker() {
  log_info "Docker Desktop 상태 확인 중..."

  # Docker daemon 연결 확인
  if docker info >/dev/null 2>&1; then
    log_success "Docker Desktop 실행 중 ✅"
    return 0
  fi

  # Docker Desktop이 실행 중인지 프로세스로 확인
  if pgrep -f "Docker Desktop" >/dev/null 2>&1; then
    log_info "Docker Desktop 프로세스는 있지만 daemon 연결 대기 중..."

    # 최대 30초간 대기
    local wait_count=0
    while [[ $wait_count -lt 30 ]]; do
      if docker info >/dev/null 2>&1; then
        log_success "Docker daemon 연결됨 ✅"
        return 0
      fi
      echo -n "."
      sleep 1
      ((wait_count++))
    done
    echo ""
    log_warning "Docker daemon 연결 시간 초과"
  fi

  # Docker Desktop 시작
  log_info "Docker Desktop 시작 중..."
  if open -a "Docker Desktop" >/dev/null 2>&1; then
    log_info "Docker Desktop 시작됨. daemon 연결 대기 중..."

    # 최대 60초간 대기
    local wait_count=0
    while [[ $wait_count -lt 60 ]]; do
      if docker info >/dev/null 2>&1; then
        log_success "Docker Desktop 시작 완료 ✅"
        return 0
      fi
      echo -n "."
      sleep 1
      ((wait_count++))
    done
    echo ""
    log_error "Docker Desktop 시작 실패 또는 시간 초과"
    return 1
  else
    log_error "Docker Desktop 시작에 실패했습니다"
    return 1
  fi
}

# 로그 디렉토리 생성
mkdir -p logs

# 1단계: 기존 서비스 정리
stop_all_existing_services

# 2단계: Docker Desktop 확인 및 시작
if ! check_and_start_docker; then
  log_error "Docker Desktop을 시작할 수 없어 중단합니다"
  log_info "수동으로 Docker Desktop을 실행한 후 다시 시도해주세요"
  exit 1
fi

# 시작 메시지
echo ""
echo "🔄 GLI Platform - 모든 서비스 재시작 시작"
echo "=============================================="
log_info "스크립트 디렉토리: $SCRIPT_DIR"
log_info "서비스 간 대기: ${WAIT_BETWEEN}초"
log_info "백그라운드 모드: $([ "$BF_MODE" -eq 1 ] && echo "예" || echo "아니오")"
log_info "실패 시 계속: $([ "$SKIP_FAILED" -eq 1 ] && echo "예" || echo "아니오")"
echo ""

# 실행 결과 추적
total_services=${#SERVICES[@]}
success_count=0
failed_count=0
results_success=""
results_failed=""

for i in "${!SERVICES[@]}"; do
  IFS=':' read -r service_name script_path <<< "${SERVICES[$i]}"

  echo "🔄 [$((i+1))/${total_services}] ${service_name} 재시작 중..."

  # 스크립트 존재 확인
  if [[ ! -f "$script_path" ]]; then
    log_error "스크립트 파일을 찾을 수 없습니다: $script_path"
    ((failed_count++))
    results_failed="$results_failed $service_name"

    if [[ "$SKIP_FAILED" -eq 0 ]]; then
      exit 1
    fi
    continue
  fi

  # 스크립트 실행 (항상 백그라운드 모드로 강제)
  # 임시 로그 파일 생성
  temp_log="/tmp/gli_restart_${service_name}_$$.log"

  if "$script_path" --bf >"$temp_log" 2>&1; then
    log_success "${service_name} 실행 성공"
    ((success_count++))
    results_success="$results_success $service_name"
    rm -f "$temp_log"
  else
    exit_code=$?
    log_error "${service_name} 실행 실패 (exit code: $exit_code)"

    # 에러 상세 정보 출력
    if [[ -f "$temp_log" ]] && [[ $VERBOSE -eq 1 ]]; then
      log_warning "에러 로그:"
      cat "$temp_log" | tail -20
    fi

    ((failed_count++))
    results_failed="$results_failed $service_name"

    if [[ "$SKIP_FAILED" -eq 0 ]]; then
      echo "🚨 ${service_name} 실패로 인해 중단됩니다."
      echo ""
      echo "💡 상세 로그 확인:"
      [[ -f "$temp_log" ]] && cat "$temp_log"
      rm -f "$temp_log"
      exit 1
    fi

    rm -f "$temp_log"
  fi

  # 서비스 간 대기 (마지막 서비스 제외)
  if [[ $i -lt $((total_services-1)) ]]; then
    echo "⏳ ${WAIT_BETWEEN}초 대기 중..."
    sleep "$WAIT_BETWEEN"
    echo "✅ 대기 완료"
  fi

  echo ""
done

# 결과 요약
echo "=============================================="
echo "📊 재시작 결과 요약"
echo "=============================================="

# 성공한 서비스들
if [[ -n "$results_success" ]]; then
  for service_name in $results_success; do
    echo -e "✅ ${service_name}: ${GREEN}성공${NC}"
  done
fi

# 실패한 서비스들
if [[ -n "$results_failed" ]]; then
  for service_name in $results_failed; do
    echo -e "❌ ${service_name}: ${RED}실패${NC}"
  done
fi

echo ""
echo "📈 통계:"
echo "   전체 서비스: $total_services"
echo "   성공: $success_count"
echo "   실패: $failed_count"

# 최종 상태 확인
echo ""
echo "🔍 서비스 상태 확인 완료"

# 서비스 정보
echo ""
echo "📋 서비스 정보:"
echo "🗂  Redis: localhost:6379"
echo "🐰 RabbitMQ: http://localhost:15672 (admin/admin)"
echo "🗄️  PostgreSQL: localhost:5433"
echo "🐍 Django API: http://localhost:8000"
echo "📱 User Frontend: http://localhost:3000"
echo "👨‍💼 Admin Frontend: http://localhost:3001"
echo "🔌 WebSocket: ws://localhost:8080"

# 로그 파일 정보
echo ""
echo "📄 로그 파일:"
echo "   API Server: tail -f gli_api-server/logs/gli_api-server.log"
echo "   WebSocket: tail -f gli_websocket/logs/gli_websocket.log"
echo "   User Frontend: tail -f gli_user-frontend/logs/gli_user-frontend.log"
echo "   Admin Frontend: tail -f gli_admin-frontend/logs/gli_admin-frontend.log"

# 최종 메시지
if [[ $failed_count -eq 0 ]]; then
  echo ""
  log_success "🎉 모든 서비스가 성공적으로 재시작되었습니다!"
  exit 0
else
  echo ""
  log_warning "⚠️  일부 서비스 재시작에 실패했습니다. (실패: $failed_count)"
  if [[ "$SKIP_FAILED" -eq 1 ]]; then
    log_info "실패한 서비스를 수동으로 확인해주세요."
  fi
  exit 1
fi
