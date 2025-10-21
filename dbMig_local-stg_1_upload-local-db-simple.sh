#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# GLI 하이브리드 DB 마이그레이션 - 1단계 (간단 버전)
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
API_SERVER_DIR="${SCRIPT_DIR}/gli_api-server"

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[94m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 GLI 하이브리드 DB 마이그레이션 - 1단계 (간단 버전)${NC}"
echo ""

# 확인
read -p "로컬 DB를 S3에 업로드하시겠습니까? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo -e "${RED}❌ 취소되었습니다.${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}🚀 마이그레이션 시작...${NC}"

# 1. PostgreSQL 상태 확인
echo -e "${BLUE}[1/4]${NC} 로컬 PostgreSQL 상태 확인..."
if docker exec gli_DB_local pg_isready -U gli -d gli > /dev/null 2>&1; then
    echo -e "${GREEN}  ✅ PostgreSQL 실행 중${NC}"
else
    echo -e "${RED}  ❌ PostgreSQL 연결 실패${NC}"
    exit 1
fi

# 2. Django 환경 설정
echo -e "${BLUE}[2/4]${NC} Django 환경 설정..."
cd "${API_SERVER_DIR}"
source .venv/bin/activate
export DJANGO_ENV=development
echo -e "${GREEN}  ✅ 환경 설정 완료${NC}"

# 3. SQL 덤프 생성 및 업로드
echo -e "${BLUE}[3/4]${NC} SQL 스키마 덤프 생성 및 업로드..."
SQL_DUMP_FILE="/tmp/gli_schema_$(date +%Y%m%d_%H%M%S).sql"

docker exec gli_DB_local pg_dump -U gli -d gli \
    --no-owner --no-privileges --clean --if-exists > "${SQL_DUMP_FILE}"

gzip "${SQL_DUMP_FILE}"
aws s3 cp "${SQL_DUMP_FILE}.gz" "s3://gli-platform-media-staging/db-sync/local-to-staging-schema.sql.gz" --profile gli
rm -f "${SQL_DUMP_FILE}.gz"
echo -e "${GREEN}  ✅ SQL 스키마 덤프 업로드 완료${NC}"

# 4. JSON 데이터 덤프 업로드
echo -e "${BLUE}[4/4]${NC} JSON 데이터 덤프 업로드..."
python manage.py sync_db --dump --s3-key db-sync/local-to-staging-dump.json.gz > /dev/null 2>&1
echo -e "${GREEN}  ✅ JSON 데이터 덤프 업로드 완료${NC}"

echo ""
echo -e "${GREEN}🎉 하이브리드 업로드 완료!${NC}"
echo ""
echo -e "${BLUE}📋 업로드된 파일:${NC}"
echo "  • SQL 스키마: s3://gli-platform-media-staging/db-sync/local-to-staging-schema.sql.gz"
echo "  • JSON 데이터: s3://gli-platform-media-staging/db-sync/local-to-staging-dump.json.gz"
echo ""
echo -e "${YELLOW}💡 다음 단계: ./dbMig_local-stg_2_load-from-local.sh${NC}"