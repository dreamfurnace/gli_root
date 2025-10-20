#!/usr/bin/env bash
set -euo pipefail

# GLI Local to Staging Database Migration Script - Step 1
# 로컬 DB 데이터를 덤프하여 S3에 업로드 (Staging으로 마이그레이션용)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
API_SERVER_DIR="${SCRIPT_DIR}/gli_api-server"

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[94m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║        GLI Local DB Upload to S3 for Staging         ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

# 현재 환경 확인
if [ "${DJANGO_ENV:-}" != "development" ]; then
    export DJANGO_ENV=development
fi

echo -e "${YELLOW}⚠️  주의사항:${NC}"
echo "  - 현재 로컬 DB의 데이터를 S3에 업로드합니다"
echo "  - Staging 환경에서 이 덤프를 사용하여 데이터를 복원할 수 있습니다"
echo "  - 업로드 위치: s3://gli-platform-media-staging/db-sync/local-to-staging-dump.json.gz"
echo ""

# 확인
read -p "계속하시겠습니까? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo -e "${RED}❌ 취소되었습니다.${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}🚀 로컬 DB 업로드 프로세스 시작...${NC}"
echo ""

# 로컬 PostgreSQL 상태 확인
echo -e "${BLUE}[1/3]${NC} 로컬 PostgreSQL 상태 확인..."
if docker exec gli_DB_local pg_isready -U gli -d gli > /dev/null 2>&1; then
    echo -e "${GREEN}  ✅ PostgreSQL 실행 중${NC}"
else
    echo -e "${RED}  ❌ PostgreSQL 연결 실패${NC}"
    echo "  PostgreSQL을 먼저 시작하세요: ./restart-database.sh --bf"
    exit 1
fi
echo ""

# API Server 디렉토리로 이동 및 가상환경 활성화
echo -e "${BLUE}[2/3]${NC} Django 환경 설정..."
cd "${API_SERVER_DIR}"

if [ -f ".venv/bin/activate" ]; then
    source .venv/bin/activate
    echo -e "${GREEN}  ✅ 가상환경 활성화${NC}"
else
    echo -e "${RED}  ❌ 가상환경을 찾을 수 없습니다: ${API_SERVER_DIR}/.venv${NC}"
    exit 1
fi
echo ""

# 로컬 DB 덤프 및 S3 업로드
echo -e "${BLUE}[3/3]${NC} 로컬 DB 덤프 및 S3 업로드..."
echo -e "${YELLOW}  📤 로컬 DB 데이터를 S3에 업로드 중...${NC}"

# Django sync_db 명령어 실행
export DJANGO_ENV=development
python manage.py sync_db --dump --s3-key db-sync/local-to-staging-dump.json.gz

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║            ✅ 로컬 DB 업로드 완료!                      ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}📊 업로드 정보:${NC}"
echo "  - 소스: 로컬 Docker PostgreSQL (gli_DB_local)"
echo "  - 대상: S3 버킷 (gli-platform-media-staging)"
echo "  - S3 키: db-sync/local-to-staging-dump.json.gz"
echo ""
echo -e "${YELLOW}💡 다음 단계:${NC}"
echo -e "${BLUE}  ./dbMig_local-stg_2_load-from-local.sh${NC}"
echo ""
echo -e "${YELLOW}또는 Staging 환경에서 수동으로:${NC}"
echo -e "${BLUE}  aws ecs execute-command --cluster staging-gli-cluster --task <TASK_ID> --container django-api --interactive --command \"/bin/bash\"${NC}"
echo ""
echo -e "${GREEN}  # 컨테이너 안에서 실행:${NC}"
echo -e "${BLUE}  cd /app && source .venv/bin/activate${NC}"
echo -e "${BLUE}  python manage.py sync_db --load --s3-key db-sync/local-to-staging-dump.json.gz --force${NC}"
echo ""