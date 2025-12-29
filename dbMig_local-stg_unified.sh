#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# GLI 통합 마이그레이션 스크립트 (대화형)
# =============================================================================
#
# 🎯 목적: 로컬 → 스테이징 완전 자동 마이그레이션
#
# 📋 통합 단계:
#   1단계: 로컬 하이브리드 덤프 생성 및 S3 업로드
#   2단계: 로컬에서 스테이징 RDS 직접 접속하여 SQL 스키마 복원
#   3단계: 로컬 Django에서 스테이징 DB 연결하여 JSON 데이터 복원
#
# 🔧 사전 요구사항:
#   - 스테이징 RDS 보안 그룹에 로컬 IP 추가
#   - AWS CLI 설정 (gli 프로필)
#   - PostgreSQL 클라이언트 설치
#
# 💡 사용법:
#   ./dbMig_local-stg_unified.sh
#
# =============================================================================

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[94m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 설정값
LOCAL_CONTAINER="gli_DB_local"
LOCAL_DB_USER="gli"
LOCAL_DB_NAME="gli"
STAGING_RDS_HOST="gli-db-staging.cp4ems4wqez2.ap-northeast-2.rds.amazonaws.com"
STAGING_DB_USER="glidbadmin"
STAGING_DB_NAME="gli"
STAGING_DB_PASSWORD="GliStage2025SecureDB!"
STAGING_SECURITY_GROUP="sg-045dc068414a4e99b"
S3_BUCKET="gli-platform-media-staging"
TIMESTAMP=$(date +'%Y%m%d_%H%M%S')

# 진행 상황 표시 함수
show_step() {
    local step=$1
    local total=$2
    local desc=$3
    echo -e "\n${BLUE}[${step}/${total}]${NC} ${desc}..."
}

show_success() {
    echo -e "${GREEN}  ✅ $1${NC}"
}

show_warning() {
    echo -e "${YELLOW}  ⚠️  $1${NC}"
}

show_error() {
    echo -e "${RED}  ❌ $1${NC}"
}

show_info() {
    echo -e "${PURPLE}  💡 $1${NC}"
}

# 대화형 확인 함수
ask_user() {
    local question=$1
    local default=${2:-""}
    if [ -n "$default" ]; then
        echo -e "${CYAN}$question [기본값: $default]${NC}"
        read -p "입력: " response
        echo ${response:-$default}
    else
        echo -e "${CYAN}$question${NC}"
        read -p "입력: " response
        echo $response
    fi
}

confirm_action() {
    local message=$1
    echo -e "${YELLOW}$message${NC}"
    read -p "계속하시겠습니까? (yes/no): " confirm
    [[ "$confirm" == "yes" ]]
}

# 환경 검증 함수
check_prerequisites() {
    echo -e "${BLUE}🔍 환경 검증 중...${NC}"

    # Docker 컨테이너 확인
    if ! docker ps --format "{{.Names}}" | grep -q "^${LOCAL_CONTAINER}$"; then
        show_error "로컬 DB 컨테이너 '$LOCAL_CONTAINER'가 실행되지 않음"
        show_info "다음 명령어로 DB를 시작하세요: docker-compose up -d db"
        exit 1
    fi
    show_success "로컬 DB 컨테이너 확인"

    # AWS CLI 확인
    if ! aws s3 ls s3://$S3_BUCKET --profile gli > /dev/null 2>&1; then
        show_error "AWS CLI 설정 또는 S3 접근 권한 문제"
        show_info "AWS CLI 설정을 확인하세요: aws configure --profile gli"
        exit 1
    fi
    show_success "AWS S3 접근 권한 확인"

    # PostgreSQL 클라이언트 확인
    if ! command -v psql > /dev/null; then
        show_error "psql (PostgreSQL 클라이언트)가 설치되지 않음"
        show_info "다음 명령어로 설치하세요: brew install postgresql"
        exit 1
    fi
    show_success "PostgreSQL 클라이언트 확인"

    # Python/Django 환경 확인 및 자동 이동
    if [ ! -f "manage.py" ]; then
        if [ -f "gli_api-server/manage.py" ]; then
            show_info "Django 프로젝트 디렉토리로 이동 중..."
            cd gli_api-server
            show_success "Django 프로젝트 디렉토리로 이동 완료"
        else
            show_error "Django 프로젝트를 찾을 수 없습니다"
            show_info "gli_root 또는 gli_api-server 디렉토리에서 실행하세요"
            exit 1
        fi
    fi
    show_success "Django 프로젝트 확인"

    echo ""
}

# 현재 IP를 RDS 보안 그룹에 자동 추가
add_current_ip_to_rds() {
    echo -e "${BLUE}🔒 RDS 접근을 위한 보안 그룹 설정...${NC}"

    # 현재 공인 IP 확인
    CURRENT_IP=$(curl -s https://ipinfo.io/ip)
    show_info "현재 공인 IP: $CURRENT_IP"

    # 보안 그룹에 현재 IP가 이미 있는지 확인
    EXISTING_RULE=$(aws ec2 describe-security-groups \
        --group-ids "$STAGING_SECURITY_GROUP" \
        --profile gli \
        --query "SecurityGroups[0].IpPermissions[?FromPort==\`5432\`].IpRanges[?CidrIp==\`${CURRENT_IP}/32\`].CidrIp" \
        --output text)

    if [ "$EXISTING_RULE" == "$CURRENT_IP/32" ]; then
        show_success "현재 IP가 이미 RDS 보안 그룹에 등록됨"
    else
        show_info "현재 IP를 RDS 보안 그룹에 추가 중..."
        if aws ec2 authorize-security-group-ingress \
            --group-id "$STAGING_SECURITY_GROUP" \
            --protocol tcp \
            --port 5432 \
            --cidr "${CURRENT_IP}/32" \
            --profile gli 2>/dev/null; then
            show_success "현재 IP가 RDS 보안 그룹에 추가됨"
        else
            # 실패한 경우, 다시 확인해보기 (중복일 가능성)
            RECHECK_RULE=$(aws ec2 describe-security-groups \
                --group-ids "$STAGING_SECURITY_GROUP" \
                --profile gli \
                --query "SecurityGroups[0].IpPermissions[?FromPort==\`5432\`].IpRanges[?CidrIp==\`${CURRENT_IP}/32\`].CidrIp" \
                --output text 2>/dev/null)

            if [ "$RECHECK_RULE" == "$CURRENT_IP/32" ]; then
                show_success "현재 IP가 이미 RDS 보안 그룹에 등록됨"
            else
                show_warning "보안 그룹 추가 실패 (권한 부족 또는 기타 오류)"
            fi
        fi
    fi

    # 몇 초 대기 (보안 그룹 변경사항 적용 시간)
    echo "   ⏳ 보안 그룹 변경사항 적용 대기 중..."
    sleep 3
    echo ""
}

# RDS 연결 테스트
test_rds_connection() {
    echo -e "${BLUE}🔗 스테이징 RDS 연결 테스트...${NC}"

    # 환경변수에 비밀번호 설정
    export PGPASSWORD="$STAGING_DB_PASSWORD"

    # 연결 테스트
    echo "   📡 연결 테스트 중: $STAGING_DB_USER@$STAGING_RDS_HOST"
    if psql -h "$STAGING_RDS_HOST" -U "$STAGING_DB_USER" -d "$STAGING_DB_NAME" \
        -c "SELECT version();" > /dev/null 2>&1; then
        show_success "스테이징 RDS 연결 성공"
        return 0
    else
        show_error "스테이징 RDS 연결 실패"
        show_info "다음을 확인하세요:"
        show_info "  1. 비밀번호: $STAGING_DB_PASSWORD"
        show_info "  2. 엔드포인트: $STAGING_RDS_HOST"
        show_info "  3. 보안 그룹 설정"

        # 비밀번호 재입력 옵션 제공
        if confirm_action "다른 비밀번호를 시도해보시겠습니까?"; then
            echo -e "${CYAN}새로운 RDS 비밀번호를 입력하세요:${NC}"
            read -s NEW_PASSWORD
            export PGPASSWORD="$NEW_PASSWORD"
            STAGING_DB_PASSWORD="$NEW_PASSWORD"

            if psql -h "$STAGING_RDS_HOST" -U "$STAGING_DB_USER" -d "$STAGING_DB_NAME" \
                -c "SELECT version();" > /dev/null 2>&1; then
                show_success "새로운 비밀번호로 연결 성공"
                return 0
            else
                show_error "새로운 비밀번호로도 연결 실패"
            fi
        fi

        return 1
    fi
}

# 1단계: 하이브리드 덤프 생성 및 업로드
step1_hybrid_dump() {
    show_step 1 3 "로컬 하이브리드 덤프 생성 및 S3 업로드"

    # SQL 덤프 생성
    echo "   🏗️  SQL 스키마 덤프 생성 중..."
    SQL_DUMP_FILE="/tmp/local-to-staging-schema_${TIMESTAMP}.sql"
    docker exec $LOCAL_CONTAINER pg_dump -U $LOCAL_DB_USER -d $LOCAL_DB_NAME \
        --no-owner --no-privileges --clean --if-exists > "$SQL_DUMP_FILE"
    gzip "$SQL_DUMP_FILE"
    show_success "SQL 덤프 생성 완료: ${SQL_DUMP_FILE}.gz"

    # JSON 덤프 생성
    echo "   📦 JSON 데이터 덤프 생성 중..."
    python manage.py sync_db --dump --s3-key "db-sync/local-to-staging-dump_${TIMESTAMP}.json.gz"
    show_success "JSON 덤프 생성 및 S3 업로드 완료"

    # SQL 덤프 S3 업로드
    echo "   ☁️  SQL 덤프 S3 업로드 중..."
    aws s3 cp "${SQL_DUMP_FILE}.gz" "s3://$S3_BUCKET/db-sync/local-to-staging-schema_${TIMESTAMP}.sql.gz" --profile gli
    show_success "SQL 덤프 S3 업로드 완료"

    # S3 키 저장
    SCHEMA_S3_KEY="db-sync/local-to-staging-schema_${TIMESTAMP}.sql.gz"
    DATA_S3_KEY="db-sync/local-to-staging-dump_${TIMESTAMP}.json.gz"

    # 임시 파일 정리
    rm -f "${SQL_DUMP_FILE}.gz"

    echo ""
}

# 2단계: 스테이징 RDS 스키마 복원
step2_schema_restore() {
    show_step 2 3 "스테이징 RDS 스키마 복원"

    # 백업 확인 (옵션)
    if confirm_action "🛡️  스테이징 DB를 백업하시겠습니까? (선택사항)"; then
        echo "   💾 스테이징 DB 백업 중..."
        BACKUP_FILE="/tmp/staging_backup_${TIMESTAMP}.sql"
        if docker exec -e PGPASSWORD="$STAGING_DB_PASSWORD" -e PGSSLMODE=require \
            $LOCAL_CONTAINER pg_dump -h "$STAGING_RDS_HOST" -U "$STAGING_DB_USER" -d "$STAGING_DB_NAME" \
            --no-owner --no-privileges > "$BACKUP_FILE" 2>/dev/null; then
            show_success "백업 완료: $BACKUP_FILE"
        else
            show_warning "백업 실패 (PostgreSQL 버전 불일치 가능성) - 마이그레이션 계속 진행"
        fi
    else
        show_info "백업을 건너뛰고 마이그레이션 진행"
    fi

    # S3에서 SQL 덤프 다운로드
    echo "   📥 S3에서 SQL 덤프 다운로드 중..."
    LOCAL_SQL_FILE="/tmp/schema_restore_${TIMESTAMP}.sql"
    aws s3 cp "s3://$S3_BUCKET/$SCHEMA_S3_KEY" - --profile gli | gunzip > "$LOCAL_SQL_FILE"
    show_success "SQL 덤프 다운로드 완료"

    # 스키마 복원 실행
    echo "   🏗️  스테이징 RDS 스키마 복원 중..."
    if confirm_action "⚠️  스테이징 RDS의 모든 스키마가 교체됩니다. 계속하시겠습니까?"; then
        psql -h "$STAGING_RDS_HOST" -U "$STAGING_DB_USER" -d "$STAGING_DB_NAME" \
            -f "$LOCAL_SQL_FILE" > /dev/null 2>&1
        show_success "스키마 복원 완료"
    else
        show_warning "스키마 복원이 취소되었습니다"
        exit 1
    fi

    # 임시 파일 정리
    rm -f "$LOCAL_SQL_FILE"

    echo ""
}

# 3단계: JSON 데이터 복원
step3_data_restore() {
    show_step 3 3 "Django를 통한 데이터 복원"

    echo "   🔧 Django 스테이징 DB 연결 설정 중..."

    # 임시 settings 파일 생성
    TEMP_SETTINGS="/tmp/staging_settings_${TIMESTAMP}.py"
    cat > "$TEMP_SETTINGS" << EOF
from config.settings import *

# 스테이징 DB 연결 오버라이드
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': '${STAGING_DB_NAME}',
        'USER': '${STAGING_DB_USER}',
        'PASSWORD': '${STAGING_DB_PASSWORD}',
        'HOST': '${STAGING_RDS_HOST}',
        'PORT': '5432',
        'OPTIONS': {
            'sslmode': 'require',
        },
    }
}

# S3 settings for data loading
AWS_S3_REGION_NAME = 'ap-northeast-2'
AWS_STORAGE_BUCKET_NAME = '${S3_BUCKET}'
EOF

    # Django 데이터 복원
    echo "   📦 JSON 데이터 복원 중..."
    DJANGO_SETTINGS_MODULE="staging_settings_${TIMESTAMP}" \
    PYTHONPATH="/tmp:${PYTHONPATH:-}" \
    python manage.py sync_db --load --s3-key "$DATA_S3_KEY" --force

    show_success "데이터 복원 완료"

    # 임시 파일 정리
    rm -f "$TEMP_SETTINGS"

    echo ""
}

# 검증 단계
verify_migration() {
    echo -e "${BLUE}🔍 마이그레이션 검증 중...${NC}"

    # 테이블 수 확인
    TABLE_COUNT=$(psql -h "$STAGING_RDS_HOST" -U "$STAGING_DB_USER" -d "$STAGING_DB_NAME" \
        -t -c "SELECT count(*) FROM information_schema.tables WHERE table_schema = 'public';" | tr -d ' ')
    show_success "테이블 수: $TABLE_COUNT"

    # 마이그레이션 기록 확인
    MIGRATION_COUNT=$(psql -h "$STAGING_RDS_HOST" -U "$STAGING_DB_USER" -d "$STAGING_DB_NAME" \
        -t -c "SELECT count(*) FROM django_migrations;" | tr -d ' ')
    show_success "마이그레이션 기록: $MIGRATION_COUNT"

    # 특정 테이블/컬럼 확인 (예: is_consumed 필드)
    if psql -h "$STAGING_RDS_HOST" -U "$STAGING_DB_USER" -d "$STAGING_DB_NAME" \
        -t -c "SELECT column_name FROM information_schema.columns WHERE table_name = 'solana_auth_authnonce' AND column_name = 'is_consumed';" | grep -q "is_consumed"; then
        show_success "AuthNonce.is_consumed 필드 확인됨"
    else
        show_warning "AuthNonce.is_consumed 필드 없음"
    fi

    echo ""
}

# 메인 함수
main() {
    echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║          🎯 GLI 통합 마이그레이션 스크립트                      ║${NC}"
    echo -e "${BLUE}║                 로컬 → 스테이징 완전 자동화                     ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    echo -e "${YELLOW}📋 실행 과정:${NC}"
    echo "  1️⃣  로컬 하이브리드 덤프 생성 및 S3 업로드"
    echo "  2️⃣  로컬에서 스테이징 RDS 직접 스키마 복원"
    echo "  3️⃣  Django를 통한 데이터 복원"
    echo "  ✅ 마이그레이션 검증"
    echo ""

    echo -e "${GREEN}🚀 통합 마이그레이션을 시작합니다...${NC}"
    echo ""

    # 환경 검증
    check_prerequisites

    # RDS 보안 그룹에 현재 IP 자동 추가
    add_current_ip_to_rds

    # RDS 연결 테스트
    if ! test_rds_connection; then
        show_error "RDS 연결 실패로 마이그레이션을 중단합니다"
        exit 1
    fi

    # 단계별 실행
    step1_hybrid_dump
    step2_schema_restore
    step3_data_restore

    # 검증
    verify_migration

    # 완료 메시지
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║          🎉 통합 마이그레이션 완료!                             ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    echo -e "${BLUE}📊 마이그레이션 정보:${NC}"
    echo "  🏗️  스키마: PostgreSQL 네이티브 복원"
    echo "  📦 데이터: Django ORM 안전 복원"
    echo "  🎯 대상: 스테이징 RDS"
    echo "  💾 S3 백업: $SCHEMA_S3_KEY, $DATA_S3_KEY"
    echo ""

    echo -e "${PURPLE}🌐 확인 링크:${NC}"
    echo "  • API Health: https://stg-api.glibiz.com/api/common/health/"
    echo "  • Admin: https://stg-admin.glibiz.com/admin/"
    echo "  • User Portal: https://stg.glibiz.com/"
    echo ""

    echo -e "${GREEN}✨ 다음부터는 이 스크립트 하나로 간편하게 마이그레이션하세요!${NC}"
}

# 스크립트 실행
main "$@"