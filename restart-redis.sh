#!/usr/bin/env bash
set -euo pipefail

# 기본값
TAG="${TAG:-gli_redis}"
NAME="${NAME:-gli_redis}"
NETWORK="${NETWORK:-gli_local}"
REDIS_PORT="${REDIS_PORT:-6379}"
IMAGE="${IMAGE:-redis:7-alpine}"
DATA_DIR="${DATA_DIR:-./gli_redis/data}"
WAIT_SEC="${WAIT_SEC:-5}"
BF=0
FORCE_PORT=0   # 1이면 점유 컨테이너 자동 정리

usage() {
  cat <<EOF
사용법: $(basename "$0") [옵션]
  --tag         라벨 project.tag 값 (기본: ${TAG})
  --name        컨테이너 이름 (기본: ${NAME})
  --network     네트워크 이름 (기본: ${NETWORK})
  --port        Redis 호스트 포트 (기본: ${REDIS_PORT})
  --image       이미지 (기본: ${IMAGE})
  --data        로컬 데이터 디렉토리 (기본: ${DATA_DIR})
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
    --port)        REDIS_PORT="$2"; shift 2;;
    --image)       IMAGE="$2"; shift 2;;
    --data)        DATA_DIR="$2"; shift 2;;
    --bf)          BF=1; shift;;
    --force-port)  FORCE_PORT=1; shift;;
    -h|--help)     usage;;
    *) echo "알 수 없는 옵션: $1"; usage;;
  esac
done

echo "🗂  Redis Docker 컨테이너 재시작..."
echo "   name='${NAME}', network='${NETWORK}', tag='${TAG}', port=${REDIS_PORT}"
echo "   data='${DATA_DIR}'"

command -v docker >/dev/null || { echo "❌ docker가 필요합니다."; exit 1; }

# 네트워크 준비
if ! docker network ls --format '{{.Name}}' | grep -q "^${NETWORK}\$"; then
  echo "🔧 네트워크 '${NETWORK}' 생성..."
  docker network create "${NETWORK}"
fi

# 기존 컨테이너 정리
EXIST_ID=$(docker ps -aq --filter "name=^/${NAME}\$")
if [[ -n "${EXIST_ID}" ]]; then
  echo "🛑 기존 컨테이너 종료/삭제..."
  docker stop "${NAME}" >/dev/null 2>&1 || true
  docker rm   "${NAME}" >/dev/null 2>&1 || true
fi

# 포트 점유 감지 함수
find_container_using_port() {
  local PORT="$1"
  docker ps --format '{{.ID}} {{.Names}} {{.Ports}}' \
    | awk -v p=":${PORT}->" 'index($0,p){print $1" "$2}'
}

REDIS_HITS="$(find_container_using_port "${REDIS_PORT}")" || true

if [[ -n "${REDIS_HITS}" ]]; then
  echo "⚠️  포트 점유 감지 (${REDIS_PORT}): ${REDIS_HITS}"

  if [[ ${FORCE_PORT} -eq 1 ]]; then
    echo "🧹 --force-port 지정: 점유 컨테이너 정리 시도..."
    echo "${REDIS_HITS}" | while read -r ID NAME_PORT; do
        echo "   -> stop/rm ${NAME_PORT} (${ID})"
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
  -p "${REDIS_PORT}:6379"
  -e TZ=Asia/Seoul
  --label "project.tag=${TAG}"
  --restart unless-stopped
)

if [[ -n "${DATA_DIR}" ]]; then
  RUN_ARGS+=(-v "${DATA_DIR}:/data")
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
  echo "🔗 Redis 포트: ${REDIS_PORT}"

  # 연결 테스트
  echo ""
  echo "🔍 연결 테스트..."
  if docker exec "${NAME}" redis-cli ping >/dev/null 2>&1; then
    echo "✅ Redis 연결 성공"
  else
    echo "⚠️  Redis 연결 실패"
  fi

  echo ""
  echo "📊 컨테이너 상태:"
  docker ps --filter "name=^/${NAME}\$"
else
  echo "❌ 실행 실패. 최근 로그:"
  docker logs "${NAME}" 2>/dev/null | tail -10 || true
  echo "📋 전체 로그: docker logs ${NAME}"
  exit 1
fi
