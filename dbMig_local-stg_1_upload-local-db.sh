#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# GLI 하이브리드 DB 마이그레이션 - 1단계: 로컬 → S3 업로드
# =============================================================================
#
# 🎯 목적:
#   - 로컬 PostgreSQL DB를 Staging RDS로 완전 마이그레이션
#   - 하이브리드 방식: SQL 덤프(스키마) + JSON 덤프(데이터)
#
# 📋 실행 과정:
#   1. SQL 덤프: 완전한 스키마 (테이블, 인덱스, 제약조건) 생성 및 업로드
#   2. JSON 덤프: 안전한 데이터 추출 및 업로드
#   3. S3에 두 개 파일 모두 업로드
#
# 🔧 사전 요구사항:
#   - 로컬 PostgreSQL 컨테이너 실행 중 (gli_DB_local)
#   - Python 가상환경 활성화 가능
#   - AWS CLI 설정 완료 (gli profile)
#
# 💡 사용법:
#   ./dbMig_local-stg_1_upload-local-db.sh
#
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
API_SERVER_DIR="${SCRIPT_DIR}/gli_api-server"

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[94m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

# 진행 상황 표시 함수
show_step() {
    local step=$1
    local total=$2
    local desc=$3
    echo -e "${BLUE}[${step}/${total}]${NC} ${desc}..."
}

# 성공 메시지 함수
show_success() {
    echo -e "${GREEN}  ✅ $1${NC}"
}

# 경고 메시지 함수
show_warning() {
    echo -e "${YELLOW}  ⚠️  $1${NC}"
}

# 오류 메시지 함수
show_error() {
    echo -e "${RED}  ❌ $1${NC}"
}

# 정보 메시지 함수
show_info() {
    echo -e "${PURPLE}  💡 $1${NC}"
}

echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║          🚀 GLI 하이브리드 DB 마이그레이션 - 1단계              ║${NC}"
echo -e "${BLUE}║                  로컬 → S3 업로드                             ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${YELLOW}📋 하이브리드 마이그레이션 방식:${NC}"
echo "  🔧 SQL 덤프  → 완전한 스키마 복원 (테이블, 인덱스, 제약조건)"
echo "  📦 JSON 덤프 → 안전한 데이터 복원 (Django ORM 호환)"
echo ""

echo -e "${YELLOW}📤 업로드될 파일들:${NC}"
echo "  - s3://gli-platform-media-staging/db-sync/local-to-staging-schema.sql.gz"
echo "  - s3://gli-platform-media-staging/db-sync/local-to-staging-dump.json.gz"
echo ""

echo -e "${RED}⚠️  주의사항:${NC}"
echo "  - Staging RDS의 모든 스키마와 데이터가 대체됩니다"
echo "  - 실행 전 Staging DB 백업을 권장합니다"
echo "  - 마이그레이션 중 서비스 중단이 발생할 수 있습니다"
echo ""

# 사용자 확인
read -p "계속하시겠습니까? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    show_error "취소되었습니다."
    exit 1
fi

echo ""
echo -e "${GREEN}🚀 하이브리드 마이그레이션 시작...${NC}"
echo ""

# =============================================================================
# 1단계: 환경 검증
# =============================================================================

show_step 1 5 "환경 검증 및 준비"

# 로컬 PostgreSQL 상태 확인
echo "   🔍 로컬 PostgreSQL 상태 확인..."
if docker exec gli_DB_local pg_isready -U gli -d gli > /dev/null 2>&1; then
    show_success "PostgreSQL 컨테이너 실행 중"
else
    show_error "PostgreSQL 연결 실패"
    show_info "다음 명령어로 시작하세요: ./restart-database.sh --bf"
    exit 1
fi

# Django 환경 확인
echo "   🐍 Django 환경 설정 확인..."
cd "${API_SERVER_DIR}"
if [ -f ".venv/bin/activate" ]; then
    source .venv/bin/activate
    show_success "가상환경 활성화"
else
    show_error "가상환경을 찾을 수 없습니다: ${API_SERVER_DIR}/.venv"
    exit 1
fi

# 환경 변수 설정
export DJANGO_ENV=development
show_success "Django 환경: ${DJANGO_ENV}"
echo ""

# =============================================================================
# 2단계: SQL 스키마 덤프 생성
# =============================================================================

show_step 2 5 "SQL 스키마 덤프 생성"

echo "   🏗️  PostgreSQL pg_dump로 완전한 스키마 덤프 생성 중..."

# 임시 SQL 덤프 파일 경로
SQL_DUMP_FILE="/tmp/gli_schema_dump_$(date +%Y%m%d_%H%M%S).sql"

# pg_dump로 스키마+데이터 덤프
docker exec gli_DB_local pg_dump -U gli -d gli \
    --no-owner \
    --no-privileges \
    --clean \
    --if-exists \
    --verbose > "${SQL_DUMP_FILE}" 2>/dev/null

if [ ! -f "${SQL_DUMP_FILE}" ] || [ ! -s "${SQL_DUMP_FILE}" ]; then
    show_error "SQL 덤프 파일 생성 실패"
    exit 1
fi

# 파일 크기 확인
SQL_SIZE=$(ls -lah "${SQL_DUMP_FILE}" | awk '{print $5}')
show_success "SQL 덤프 생성 완료 (${SQL_SIZE})"

# SQL 덤프 압축
echo "   🗜️  SQL 덤프 압축 중..."
gzip "${SQL_DUMP_FILE}"
SQL_COMPRESSED="${SQL_DUMP_FILE}.gz"
COMPRESSED_SIZE=$(ls -lah "${SQL_COMPRESSED}" | awk '{print $5}')
show_success "SQL 덤프 압축 완료 (${COMPRESSED_SIZE})"
echo ""

# =============================================================================
# 3단계: JSON 데이터 덤프 생성
# =============================================================================

show_step 3 5 "JSON 데이터 덤프 생성"

echo "   📦 Django sync_db로 JSON 데이터 덤프 생성 중..."
echo "   (Django ORM 호환 방식으로 안전한 데이터 추출)"

# JSON 덤프 생성 (임시 로컬 파일로)
JSON_DUMP_FILE="/tmp/gli_data_dump_$(date +%Y%m%d_%H%M%S).json.gz"

python manage.py sync_db --dump --s3-key "temp/local-data-dump.json.gz" > /dev/null 2>&1

# S3에서 임시 파일 다운로드 (로컬에서 크기 확인용)
aws s3 cp "s3://gli-platform-media-staging/temp/local-data-dump.json.gz" "${JSON_DUMP_FILE}" --profile gli > /dev/null 2>&1

if [ ! -f "${JSON_DUMP_FILE}" ] || [ ! -s "${JSON_DUMP_FILE}" ]; then
    show_error "JSON 덤프 파일 생성 실패"
    exit 1
fi

JSON_SIZE=$(ls -lah "${JSON_DUMP_FILE}" | awk '{print $5}')
show_success "JSON 데이터 덤프 생성 완료 (${JSON_SIZE})"

# 임시 S3 파일 정리
aws s3 rm "s3://gli-platform-media-staging/temp/local-data-dump.json.gz" --profile gli > /dev/null 2>&1
echo ""

# =============================================================================
# 4단계: S3 업로드
# =============================================================================

show_step 4 5 "S3에 하이브리드 덤프 업로드"

echo "   ☁️  SQL 스키마 덤프 S3 업로드 중..."
aws s3 cp "${SQL_COMPRESSED}" "s3://gli-platform-media-staging/db-sync/local-to-staging-schema.sql.gz" --profile gli
show_success "SQL 스키마 덤프 업로드 완료"

echo "   ☁️  JSON 데이터 덤프 S3 업로드 중..."
aws s3 cp "${JSON_DUMP_FILE}" "s3://gli-platform-media-staging/db-sync/local-to-staging-dump.json.gz" --profile gli
show_success "JSON 데이터 덤프 업로드 완료"

# S3에 백업 복사본도 생성
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
echo "   📋 백업 복사본 생성 중..."
aws s3 cp "${SQL_COMPRESSED}" "s3://gli-platform-media-staging/db-sync/backups/schema_${TIMESTAMP}.sql.gz" --profile gli > /dev/null 2>&1
aws s3 cp "${JSON_DUMP_FILE}" "s3://gli-platform-media-staging/db-sync/backups/data_${TIMESTAMP}.json.gz" --profile gli > /dev/null 2>&1
show_success "백업 복사본 생성 완료"
echo ""

# =============================================================================
# 5단계: 정리 및 완료
# =============================================================================

show_step 5 5 "임시 파일 정리 및 완료"

# 임시 파일 정리
rm -f "${SQL_COMPRESSED}" "${JSON_DUMP_FILE}"
show_success "임시 파일 정리 완료"

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║               🎉 하이브리드 DB 업로드 완료!                     ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${BLUE}📊 업로드 완료 정보:${NC}"
echo "  🏗️  SQL 스키마 : s3://gli-platform-media-staging/db-sync/local-to-staging-schema.sql.gz"
echo "  📦 JSON 데이터 : s3://gli-platform-media-staging/db-sync/local-to-staging-dump.json.gz"
echo "  💾 백업본     : s3://gli-platform-media-staging/db-sync/backups/*_${TIMESTAMP}.*"
echo ""

echo -e "${BLUE}🔧 마이그레이션 방식:${NC}"
echo "  • SQL 덤프  → 완전한 스키마 복원 (DROP + CREATE)"
echo "  • JSON 덤프 → 안전한 데이터 복원 (Django ORM)"
echo "  • 하이브리드 → 최고의 안정성과 완전성 보장"
echo ""

echo -e "${YELLOW}💡 다음 단계:${NC}"
echo -e "  ${BLUE}./dbMig_local-stg_2_load-from-local.sh${NC}"
echo ""

echo -e "${YELLOW}📋 2단계에서 실행될 작업:${NC}"
echo "  1. ECS Task 연결"
echo "  2. Staging DB 백업 (선택사항)"
echo "  3. SQL 덤프로 스키마 완전 복원"
echo "  4. JSON 덤프로 데이터 안전 복원"
echo "  5. 마이그레이션 상태 동기화"
echo ""

echo -e "${GREEN}✨ 준비 완료! 이제 2단계 스크립트를 실행하세요!${NC}"