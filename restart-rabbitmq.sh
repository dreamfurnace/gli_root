#!/usr/bin/env bash
set -euo pipefail

# 기본값
TAG="${TAG:-gli_rabbitmq}"
NAME="${NAME:-gli_rabbitmq}"
NETWORK="${NETWORK:-gli_local}"
AMQP_PORT="${AMQP_PORT:-5672}"
UI_PORT="${UI_PORT:-15672}"
IMAGE="${IMAGE:-rabbitmq:3-management}"
DATA_DIR="${DATA_DIR:-./gli_rabbitmq/data}"
WAIT_SEC="${WAIT_SEC:-8}"
BF=0
FORCE_PORT=0   # 1이면 점유 컨테이너 자동 정리

# RabbitMQ 설정
RABBITMQ_USER="${RABBITMQ_USER:-admin}"
RABBITMQ_PASS="${RABBITMQ_PASS:-admin}"

usage() {
  cat <<EOF
사용법: $(basename "$0") [옵션]
  --tag         라벨 project.tag 값 (기본: ${TAG})
  --name        컨테이너 이름 (기본: ${NAME})
  --network     네트워크 이름 (기본: ${NETWORK})
  --amqp        AMQP 호스트 포트 (기본: ${AMQP_PORT})
  --ui          UI 호스트 포트 (기본: ${UI_PORT})
  --image       이미지 (기본: ${IMAGE})
  --data        로컬 데이터 디렉토리 (기본: ${DATA_DIR})
  --user        RabbitMQ 사용자 (기본: ${RABBITMQ_USER})
  --pass        RabbitMQ 비밀번호 (기본: ${RABBITMQ_PASS})
  --bf          백그라운드 실행 (기본 포그라운드)
  --force-port  포트 점유 중인 컨테이너 자동 정리
  -h|--help     도움말
EOF
  exit 1
}

while [[ ${1:-} ]]; do
  case "$1" in
    --tag)         TAG="$2"; shift 2;;
    --name)        NAME="$2"; shift 2;;
    --network)     NETWORK="$2"; shift 2;;
    --amqp)        AMQP_PORT="$2"; shift 2;;
    --ui)          UI_PORT="$2"; shift 2;;
    --image)       IMAGE="$2"; shift 2;;
    --data)        DATA_DIR="$2"; shift 2;;
    --user)        RABBITMQ_USER="$2"; shift 2;;
    --pass)        RABBITMQ_PASS="$2"; shift 2;;
    --bf)          BF=1; shift;;
    --force-port)  FORCE_PORT=1; shift;;
    -h|--help)     usage;;
    *) echo "알 수 없는 옵션: $1"; usage;;
  esac
done

echo "🐰 RabbitMQ Docker 컨테이너 재시작..."
echo "   name='${NAME}', network='${NETWORK}', tag='${TAG}', ports=${AMQP_PORT}/${UI_PORT}"
echo "   user='${RABBITMQ_USER}', data='${DATA_DIR}'"

command -v docker >/dev/null || { echo "❌ docker가 필요합니다."; exit 1; }

# 네트워크 준비
if ! docker network ls --format '{{.Name}}' | grep -q "^${NETWORK}\$"; then
  echo "🔧 네트워크 '${NETWORK}' 생성..."
  docker network create "${NETWORK}"
fi

# 기존 컨테이너 정리 (다른 이름의 RabbitMQ 컨테이너도 확인)
EXIST_ID=$(docker ps -aq --filter "name=^/${NAME}\$")
OTHER_RABBITMQ=$(docker ps --filter "ancestor=rabbitmq" --filter "status=running" --format '{{.Names}}' | head -1)

if [[ -n "${EXIST_ID}" ]]; then
  echo "🛑 기존 컨테이너 종료/삭제..."
  docker stop "${NAME}" >/dev/null 2>&1 || true
  docker rm   "${NAME}" >/dev/null 2>&1 || true
elif [[ -n "${OTHER_RABBITMQ}" ]]; then
  echo "✅ 다른 RabbitMQ 컨테이너 '${OTHER_RABBITMQ}'가 이미 실행 중입니다"
  echo "🔗 Management UI: http://localhost:${UI_PORT}"
  echo "🔑 기본 로그인: admin/admin"
  exit 0
fi

# 포트 점유 감지 함수
find_container_using_port() {
  local PORT="$1"
  docker ps --format '{{.ID}} {{.Names}} {{.Ports}}' \
    | awk -v p=":${PORT}->" 'index($0,p){print $1" "$2}'
}

AMQP_HITS="$(find_container_using_port "${AMQP_PORT}")" || true
UI_HITS="$(find_container_using_port "${UI_PORT}")" || true

if [[ -n "${AMQP_HITS}${UI_HITS}" ]]; then
  # RabbitMQ 컨테이너가 이미 실행 중인지 확인
  EXISTING_RABBITMQ=$(echo -e "${AMQP_HITS}\n${UI_HITS}" | awk 'NF' | grep -E "(rabbitmq|gli)" | head -1 | awk '{print $2}')

  if [[ -n "${EXISTING_RABBITMQ}" ]]; then
    echo "✅ RabbitMQ 컨테이너 '${EXISTING_RABBITMQ}'가 이미 실행 중입니다"
    echo "🔗 Management UI: http://localhost:${UI_PORT}"
    echo "🔑 기본 로그인: admin/admin"
    exit 0
  fi

  echo "⚠️  포트 점유 감지:"
  [[ -n "${AMQP_HITS}" ]] && echo "   - ${AMQP_PORT}: ${AMQP_HITS}"
  [[ -n "${UI_HITS}"   ]] && echo "   - ${UI_PORT}: ${UI_HITS}"

  if [[ ${FORCE_PORT} -eq 1 ]]; then
    echo "🧹 --force-port 지정: 점유 컨테이너 정리 시도..."
    printf "%s\n%s\n" "${AMQP_HITS}" "${UI_HITS}" | awk 'NF' | sort -u \
    | while read -r ID NAME; do
        echo "   -> stop/rm ${NAME} (${ID})"
        docker stop "${ID}" >/dev/null 2>&1 || true
        docker rm   "${ID}" >/dev/null 2>&1 || true
      done
  else
    echo "❌ 포트가 사용 중입니다. --force-port 옵션을 사용하세요."
    exit 1
  fi
fi

# 데이터 디렉토리 준비
if [[ -n "${DATA_DIR}" ]]; then
  mkdir -p "${DATA_DIR}"
  echo "📁 데이터 디렉토리 준비: ${DATA_DIR}"
fi

# 실행 인자
RUN_ARGS=(
  --name "${NAME}"
  --network "${NETWORK}"
  -p "${AMQP_PORT}:5672"
  -p "${UI_PORT}:15672"
  -e RABBITMQ_DEFAULT_USER="${RABBITMQ_USER}"
  -e RABBITMQ_DEFAULT_PASS="${RABBITMQ_PASS}"
  -e RABBITMQ_DEFAULT_VHOST=/
  -e TZ=Asia/Seoul
  --label "project.tag=${TAG}"
  --restart unless-stopped
)

if [[ -n "${DATA_DIR}" ]]; then
  RUN_ARGS+=(-v "${DATA_DIR}:/var/lib/rabbitmq")
fi

# 실행
if [[ ${BF} -eq 1 ]]; then
  echo "🚀 백그라운드 실행..."
  docker run -d "${RUN_ARGS[@]}" "${IMAGE}" >/dev/null
  echo "✅ 백그라운드 실행 완료"
else
  echo "🚀 백그라운드 실행 (로그 출력 최소화)..."
  CONTAINER_ID=$(docker run -d "${RUN_ARGS[@]}" "${IMAGE}")
  echo "   컨테이너 ID: ${CONTAINER_ID:0:12}"
  echo "   로그 확인: docker logs ${NAME}"
  echo "   종료 방법: docker stop ${NAME}"
fi

# 대기 + 확인
if [[ ${BF} -eq 1 ]]; then
  echo "✅ 백그라운드 실행 완료 (확인 건너뜀)"
  exit 0
fi

echo "⏳ 초기화 대기 ${WAIT_SEC}s..."
sleep "${WAIT_SEC}"

if docker ps --filter "name=^/${NAME}\$" --format '{{.Names}}' | grep -q "^${NAME}$"; then
  echo "✅ 실행 확인"
  echo "🔗 Management UI: http://localhost:${UI_PORT}"
  echo "🔑 로그인: ${RABBITMQ_USER}/${RABBITMQ_PASS}"
  echo "🔌 AMQP 포트: ${AMQP_PORT}"

  echo ""
  echo "📊 컨테이너 상태:"
  docker ps --filter "name=^/${NAME}\$"

  # 초기화 완료 여부 간단 체크
  echo ""
  echo "🔍 초기화 상태 체크..."
  if docker logs "${NAME}" 2>/dev/null | grep -q "Server startup complete"; then
    echo "✅ RabbitMQ 초기화 완료!"
  else
    echo "⏳ 아직 초기화 중... (docker logs ${NAME} 로 확인 가능)"
  fi
else
  echo "❌ 실행 실패. 최근 로그:"
  docker logs "${NAME}" 2>/dev/null | tail -10 || true
  echo "📋 전체 로그: docker logs ${NAME}"
  exit 1
fi
