#!/usr/bin/env bash
set -euo pipefail

# 기본값
TAG="${TAG:-gli_database}"
NAME="${NAME:-gli_DB_local}"
NETWORK="${NETWORK:-gli_local}"
DB_PORT="${DB_PORT:-5433}"
IMAGE="${IMAGE:-postgres:15}"
DATA_DIR="${DATA_DIR:-./gli_database/data}"
INIT_DIR="${INIT_DIR:-./gli_database/init}"
WAIT_SEC="${WAIT_SEC:-10}"
BF=0
FORCE_PORT=0   # 1이면 점유 컨테이너 자동 정리

# PostgreSQL 설정
POSTGRES_USER="${POSTGRES_USER:-gli}"
POSTGRES_PASS="${POSTGRES_PASS:-gli123!}"
POSTGRES_DB="${POSTGRES_DB:-gli}"

usage() {
  cat <<EOF
사용법: $(basename "$0") [옵션]
  --tag         라벨 project.tag 값 (기본: ${TAG})
  --name        컨테이너 이름 (기본: ${NAME})
  --network     네트워크 이름 (기본: ${NETWORK})
  --db-port     PostgreSQL 호스트 포트 (기본: ${DB_PORT})
  --image       PostgreSQL 이미지 (기본: ${IMAGE})
  --data        로컬 데이터 디렉토리 (기본: ${DATA_DIR})
  --init        초기화 스크립트 디렉토리 (기본: ${INIT_DIR})
  --user        PostgreSQL 사용자 (기본: ${POSTGRES_USER})
  --pass        PostgreSQL 비밀번호 (기본: ${POSTGRES_PASS})
  --db          PostgreSQL 데이터베이스 (기본: ${POSTGRES_DB})
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
    --db-port)     DB_PORT="$2"; shift 2;;
    --image)       IMAGE="$2"; shift 2;;
    --data)        DATA_DIR="$2"; shift 2;;
    --init)        INIT_DIR="$2"; shift 2;;
    --user)        POSTGRES_USER="$2"; shift 2;;
    --pass)        POSTGRES_PASS="$2"; shift 2;;
    --db)          POSTGRES_DB="$2"; shift 2;;
    --bf)          BF=1; shift;;
    --force-port)  FORCE_PORT=1; shift;;
    -h|--help)     usage;;
    *) echo "알 수 없는 옵션: $1"; usage;;
  esac
done

echo "🐘 PostgreSQL Docker 컨테이너 재시작..."
echo "   name='${NAME}', network='${NETWORK}', tag='${TAG}'"
echo "   postgres_port=${DB_PORT}"
echo "   data='${DATA_DIR}', init='${INIT_DIR}'"

command -v docker >/dev/null || { echo "❌ docker가 필요합니다."; exit 1; }

# 컨테이너 이름 패턴으로 모든 변종 찾기
find_all_db_containers() {
  docker ps -a --format '{{.Names}}' | grep -E "(gli.*postgres|gli.*POSTGRES|gli.*database)" || true
}

# 포트 점유 감지 함수
find_container_using_port() {
  local PORT="$1"
  docker ps --format '{{.ID}} {{.Names}} {{.Ports}}' \
    | awk -v p=":${PORT}->" 'index($0,p){print $1" "$2}'
}

# 네트워크 준비
if ! docker network ls --format '{{.Name}}' | grep -q "^${NETWORK}\$"; then
  echo "🔧 네트워크 '${NETWORK}' 생성..."
  docker network create "${NETWORK}"
fi

# 기존 컨테이너 정리 (모든 변종 포함)
POSTGRES_CONTAINER="${NAME}"

echo "🔍 기존 DB 컨테이너 검색 중..."
ALL_DB_CONTAINERS=$(find_all_db_containers)

if [[ -n "$ALL_DB_CONTAINERS" ]]; then
  echo "🛑 발견된 컨테이너들을 정리합니다:"
  echo "$ALL_DB_CONTAINERS" | while read -r container; do
    if [[ -n "$container" ]]; then
      echo "   -> $container"
      docker stop "$container" >/dev/null 2>&1 || true
      docker rm "$container" >/dev/null 2>&1 || true
    fi
  done
  echo "✅ 기존 컨테이너 정리 완료"
else
  echo "ℹ️  정리할 기존 컨테이너가 없습니다"
fi

# PostgreSQL 포트 확인
PORT_HITS="$(find_container_using_port "${DB_PORT}")" || true

if [[ -n "${PORT_HITS}" ]]; then
  echo "⚠️  포트 점유 감지 (${DB_PORT}): ${PORT_HITS}"

  if [[ ${FORCE_PORT} -eq 1 ]]; then
    echo "🧹 --force-port 지정: 점유 컨테이너 정리 시도..."
    echo "${PORT_HITS}" | while read -r ID NAME; do
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
  mkdir -p "${DATA_DIR}/postgres"
  echo "📁 데이터 디렉토리 준비: ${DATA_DIR}"
fi

# 초기화 디렉토리 확인
if [[ -n "${INIT_DIR}" ]] && [[ -d "${INIT_DIR}" ]]; then
  echo "📝 초기화 스크립트 디렉토리 확인: ${INIT_DIR}"
  INIT_VOLUME="-v ${INIT_DIR}:/docker-entrypoint-initdb.d"
else
  INIT_VOLUME=""
fi

# PostgreSQL 실행 인자
PG_RUN_ARGS=(
  --name "${POSTGRES_CONTAINER}"
  --network "${NETWORK}"
  -p "${DB_PORT}:5432"
  -e POSTGRES_DB="${POSTGRES_DB}"
  -e POSTGRES_USER="${POSTGRES_USER}"
  -e POSTGRES_PASSWORD="${POSTGRES_PASS}"
  -e TZ=Asia/Seoul
  --label "project.tag=${TAG}"
  --restart unless-stopped
)

if [[ -n "${DATA_DIR}" ]]; then
  PG_RUN_ARGS+=(-v "${DATA_DIR}/postgres:/var/lib/postgresql/data")
fi

if [[ -n "${INIT_VOLUME}" ]]; then
  PG_RUN_ARGS+=(${INIT_VOLUME})
fi

# PostgreSQL 시작
echo "🚀 PostgreSQL 시작..."
if [[ ${BF} -eq 1 ]]; then
  docker run -d "${PG_RUN_ARGS[@]}" "${IMAGE}" >/dev/null
  echo "✅ PostgreSQL 백그라운드 실행"
else
  docker run "${PG_RUN_ARGS[@]}" "${IMAGE}" &
  echo "✅ PostgreSQL 포그라운드 실행"
  sleep 2
fi

# 대기 + 확인
if [[ ${BF} -eq 1 ]]; then
  echo "✅ 백그라운드 실행 완료"

  echo "⏳ 초기화 대기 ${WAIT_SEC}s..."
  sleep "${WAIT_SEC}"

  # 연결 테스트
  echo "🔍 연결 테스트..."

  # PostgreSQL 테스트
  if docker exec "${POSTGRES_CONTAINER}" pg_isready -U "${POSTGRES_USER}" -d "${POSTGRES_DB}" >/dev/null 2>&1; then
    echo "✅ PostgreSQL 연결 성공"
  else
    echo "⚠️  PostgreSQL 연결 실패 (아직 초기화 중일 수 있음)"
  fi

  echo ""
  echo "🔗 연결 정보:"
  echo "🐘 PostgreSQL: localhost:${DB_PORT}"
  echo "   - Database: ${POSTGRES_DB}"
  echo "   - Username: ${POSTGRES_USER}"
  echo "   - Password: ${POSTGRES_PASS}"

  echo ""
  echo "📊 컨테이너 상태:"
  docker ps --filter "label=project.tag=${TAG}"
else
  echo "⏳ 초기화 대기 ${WAIT_SEC}s..."
  sleep "${WAIT_SEC}"

  echo "🔗 연결 정보:"
  echo "🐘 PostgreSQL: localhost:${DB_PORT} (${POSTGRES_USER}/${POSTGRES_DB})"
  echo ""
  echo "📊 포그라운드 실행 중... (종료: Ctrl+C)"

  # 포그라운드에서는 무한 대기
  wait
fi
