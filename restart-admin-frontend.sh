#!/usr/bin/env bash
set -euo pipefail

# 기본값
TAG="${TAG:-gli_admin-frontend}"  # ps/pgrep에서 보일 태그
PORT="${PORT:-3001}"                 # Admin Frontend 포트
APP_DIR="${APP_DIR:-gli_admin-frontend}" # 앱 디렉토리
WAIT_STOP="${WAIT_STOP:-3}"          # 종료 대기 초
BF=0                                 # 0=포그라운드, 1=백그라운드

usage() {
  cat <<EOF
사용법: $(basename "$0") [--tag TAG] [--port PORT] [--dir DIR] [--bf]
  --tag   ps/pgrep에서 보일 프로세스 태그 (기본: ${TAG})
  --port  강제 종료할 포트 (기본: ${PORT})
  --dir   앱 디렉토리 (기본: ${APP_DIR})
  --bf    백그라운드 실행 모드 (기본은 포그라운드 실행)
환경변수로도 설정 가능: TAG, PORT, APP_DIR, WAIT_STOP
EOF
  exit 1
}

while [[ ${1:-} ]]; do
  case "$1" in
    --tag)  TAG="$2"; shift 2;;
    --port) PORT="$2"; shift 2;;
    --dir)  APP_DIR="$2"; shift 2;;
    --bf)   BF=1; shift;;
    -h|--help) usage;;
    *) echo "알 수 없는 옵션: $1"; usage;;
  esac
done

echo "🔄 '${TAG}' Admin Frontend 재시작..."

# 1) 태그로 기존 프로세스 종료
if pgrep -f -- "$TAG" >/dev/null 2>&1; then
  echo "🛑 태그(${TAG})로 기존 프로세스 종료 시도..."
  pkill -f -- "$TAG" || true
  sleep "$WAIT_STOP"
  if pgrep -f -- "$TAG" >/dev/null 2>&1; then
    echo "💥 잔존 프로세스 강제 종료..."
    pkill -9 -f -- "$TAG" || true
  fi
else
  echo "ℹ️  태그(${TAG})로 실행 중인 프로세스 없음."
fi

# 2) 포트 점유 프로세스 강제 종료 (안전장치)
if lsof -ti :"$PORT" >/dev/null 2>&1; then
  echo "🔓 포트 ${PORT} 점유 프로세스 강제 종료..."
  lsof -ti :"$PORT" | xargs kill -9 2>/dev/null || true
fi

sleep "$WAIT_STOP"

# 3) 서버 시작
echo "🚀 서버 시작: 디렉토리='${APP_DIR}', 태그='${TAG}'"

# 작업 디렉토리 이동
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}/${APP_DIR}" || { echo "❌ 디렉토리 없음: ${SCRIPT_DIR}/${APP_DIR}"; exit 1; }

echo "📁 작업 디렉토리: $(pwd)"

# package.json 존재 여부 확인
if [[ ! -f "package.json" ]]; then
  echo "❌ Admin Frontend가 아직 설정되지 않았습니다 (package.json 없음)"
  echo "ℹ️  Admin Frontend 개발이 완료되면 이 스크립트가 정상 동작합니다"
  exit 1
fi

# 캐시 및 컴파일된 파일 정리
echo "🧹 캐시 및 컴파일된 파일 정리 중..."
rm -rf node_modules/.vite 2>/dev/null || true
find src -name "*.js" -type f -delete 2>/dev/null || true
find src -name "*.js.map" -type f -delete 2>/dev/null || true
echo "✅ 캐시 정리 완료"

mkdir -p ./logs
LOGFILE="./logs/${TAG}.log"

if [[ $BF -eq 1 ]]; then
  # 백그라운드 실행
  nohup bash -lc "exec -a '$TAG' env NODE_ENV=development npm run dev -- -- --exec 'exec -a $TAG node'" >>"$LOGFILE" 2>&1 &
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
  exec -a "$TAG" env NODE_ENV=development npm run dev -- -- --exec "exec -a $TAG node"
fi
