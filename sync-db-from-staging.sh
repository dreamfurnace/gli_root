#!/usr/bin/env bash
set -euo pipefail

# GLI Database Sync Script
# Staging RDS 데이터를 로컬 Docker PostgreSQL로 동기화

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
API_SERVER_DIR="${SCRIPT_DIR}/gli_api-server"

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║         GLI Database Sync from Staging RDS           ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

# 현재 환경 확인
if [ "${DJANGO_ENV:-}" != "development" ]; then
    export DJANGO_ENV=development
fi

echo -e "${YELLOW}⚠️  주의사항:${NC}"
echo "  - 현재 로컬 DB의 모든 데이터가 삭제됩니다"
echo "  - Staging RDS 데이터로 완전히 대체됩니다"
echo "  - 자동으로 로컬 DB 백업이 생성됩니다"
echo ""

# 확인
read -p "계속하시겠습니까? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    echo -e "${RED}❌ 취소되었습니다.${NC}"
    exit 1
fi

echo ""
echo -e "${GREEN}🚀 동기화 프로세스 시작...${NC}"
echo ""

# 1. 로컬 PostgreSQL 확인
echo -e "${BLUE}[1/5]${NC} 로컬 PostgreSQL 상태 확인..."
if ! docker ps | grep -q gli_DB_local; then
    echo -e "${YELLOW}  PostgreSQL이 실행 중이 아닙니다. 시작합니다...${NC}"
    "${SCRIPT_DIR}/restart-database.sh" --bf
    sleep 5
fi

if docker exec gli_DB_local pg_isready -U gli -d gli > /dev/null 2>&1; then
    echo -e "${GREEN}  ✅ PostgreSQL 실행 중${NC}"
else
    echo -e "${RED}  ❌ PostgreSQL 연결 실패${NC}"
    exit 1
fi
echo ""

# 2. Staging에서 덤프 확인 (S3)
echo -e "${BLUE}[2/5]${NC} S3에서 최신 덤프 확인..."
cd "${API_SERVER_DIR}"

if aws s3 ls "s3://gli-platform-media-staging/db-sync/latest-dump.json.gz" > /dev/null 2>&1; then
    # 메타데이터 확인
    DUMP_TIME=$(aws s3api head-object \
        --bucket gli-platform-media-staging \
        --key db-sync/latest-dump.json.gz \
        --query 'LastModified' \
        --output text 2>/dev/null || echo "Unknown")

    echo -e "${GREEN}  ✅ 최신 덤프 발견${NC}"
    echo -e "     생성 시간: ${DUMP_TIME}"
else
    echo -e "${YELLOW}  ⚠️  S3에 최신 덤프가 없습니다.${NC}"
    echo ""
    echo -e "${YELLOW}다음 명령으로 Staging 환경에서 덤프를 생성하세요:${NC}"
    echo -e "${BLUE}  aws ecs execute-command \\
    --cluster staging-gli-cluster \\
    --task <TASK_ID> \\
    --container django-api \\
    --interactive \\
    --command \"/bin/bash\"${NC}"
    echo ""
    echo -e "${BLUE}  # 컨테이너 안에서 실행:
  export DJANGO_ENV=staging
  python manage.py sync_db --dump${NC}"
    echo ""
    exit 1
fi
echo ""

# 3. 로컬 DB 백업
echo -e "${BLUE}[3/5]${NC} 로컬 DB 백업 생성..."
python manage.py sync_db --backup
echo ""

# 4. Staging 데이터 다운로드 및 복원
echo -e "${BLUE}[4/5]${NC} Staging 데이터 다운로드 및 복원..."
python manage.py sync_db --load --force
echo ""

# 5. 마이그레이션 실행
echo -e "${BLUE}[5/5]${NC} 마이그레이션 실행..."
python manage.py migrate
echo ""

echo -e "${GREEN}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║            ✅ 동기화 완료!                              ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}📊 동기화 정보:${NC}"
echo "  - 소스: Staging RDS"
echo "  - 대상: 로컬 Docker PostgreSQL (gli_DB_local)"
echo "  - 백업 위치: gli_api-server/backups/"
echo ""
echo -e "${YELLOW}💡 팁:${NC}"
echo "  - 로컬 DB 백업 복원: python manage.py loaddata backups/local_backup_<timestamp>.json"
echo "  - Django Admin 접속: http://localhost:8000/admin/"
echo ""
