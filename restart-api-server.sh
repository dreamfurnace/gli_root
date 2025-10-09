#!/usr/bin/env bash
set -euo pipefail

# 기본값
TAG="${TAG:-gli_api-server}"     # ps/pgrep에서 식별할 태그
PORT="${PORT:-8000}"           # Django 실행 포트
APP_DIR="${APP_DIR:-gli_api-server}" # Django 프로젝트 디렉토리
WAIT_STOP="${WAIT_STOP:-3}"    # 종료 대기 초
BF=0                           # 0=포그라운드, 1=백그라운드

usage() {
  cat <<EOF
사용법: $(basename "$0") [옵션]
  --tag     프로세스 태그 (기본: ${TAG})
  --port    Django 포트 (기본: ${PORT})
  --dir     앱 디렉토리 (기본: ${APP_DIR})
  --bf      백그라운드 실행 (기본 포그라운드)
  -h|--help 도움말
EOF
  exit 1
}

while [[ ${1:-} ]]; do
  case "$1" in
    --tag)   TAG="$2"; shift 2;;
    --port)  PORT="$2"; shift 2;;
    --dir)   APP_DIR="$2"; shift 2;;
    --bf)    BF=1; shift;;
    -h|--help) usage;;
    *) echo "알 수 없는 옵션: $1"; usage;;
  esac
done

echo "🔄 '${TAG}' Django API Server 재시작..."

# 1) 기존 프로세스 종료
if pgrep -f -- "$TAG" >/dev/null 2>&1; then
  echo "🛑 태그(${TAG})로 실행 중인 Django 종료..."
  pkill -f -- "$TAG" || true
  sleep "$WAIT_STOP"
  if pgrep -f -- "$TAG" >/dev/null 2>&1; then
    echo "💥 강제 종료..."
    pkill -9 -f -- "$TAG" || true
  fi
else
  echo "ℹ️ 실행 중인 '${TAG}' 프로세스 없음."
fi

# 2) 포트 점유 해제
if lsof -ti :"$PORT" >/dev/null 2>&1; then
  echo "🔓 포트 ${PORT} 점유 프로세스 강제 종료..."
  lsof -ti :"$PORT" | xargs kill -9 2>/dev/null || true
fi

sleep "$WAIT_STOP"

# 3) 서버 시작
echo "🚀 Django 시작: 디렉토리='${APP_DIR}', 포트=${PORT}, 태그='${TAG}'"

# 작업 디렉토리 이동
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}/${APP_DIR}" || { echo "❌ 디렉토리 없음: ${SCRIPT_DIR}/${APP_DIR}"; exit 1; }

mkdir -p ./logs
LOGFILE="./logs/${TAG}.log"

echo "📁 작업 디렉토리: $(pwd)"

if [[ $BF -eq 1 ]]; then
  # 백그라운드 실행
  nohup bash -c "exec -a '$TAG' env DJANGO_ENV=development uv run python manage.py runserver 0.0.0.0:${PORT}" >>"$LOGFILE" 2>&1 &
  PID=$!
  echo "$PID" > "./${TAG}.pid"
  disown || true

  # 프로세스가 실제로 살아있는지 확인 (2초 대기 후)
  sleep 2
  if kill -0 $PID 2>/dev/null; then
    echo "✅ 백그라운드 실행됨 (PID: $PID)"
    echo "🗒  로그: $LOGFILE"
  else
    echo "❌ 프로세스가 시작 직후 종료되었습니다"
    echo "📋 로그 확인:"
    tail -20 "$LOGFILE"
    exit 1
  fi
else
  # 포그라운드 실행
  exec -a "$TAG" env DJANGO_ENV=development uv run python manage.py runserver 0.0.0.0:${PORT}
fi
