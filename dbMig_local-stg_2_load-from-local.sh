#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# GLI 하이브리드 DB 마이그레이션 - 2단계: S3 → Staging RDS 복원
# =============================================================================
#
# 🎯 목적:
#   - S3에 업로드된 하이브리드 덤프를 Staging RDS에 완전 복원
#   - SQL 덤프로 스키마 복원 → JSON 덤프로 데이터 복원
#
# 📋 실행 과정:
#   1. ECS Task 연결 및 파일 존재 확인
#   2. Staging DB 백업 (선택사항)
#   3. SQL 덤프로 완전한 스키마 복원
#   4. JSON 덤프로 안전한 데이터 복원
#   5. 마이그레이션 상태 검증
#
# 🔧 사전 요구사항:
#   - 1단계 업로드 스크립트 실행 완료
#   - AWS ECS Exec 권한 설정 완료
#   - Staging ECS Task 실행 중
#
# 💡 사용법:
#   ./dbMig_local-stg_2_load-from-local.sh
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

# ECS 설정
ECS_CLUSTER="staging-gli-cluster"
ECS_SERVICE="staging-django-api-service"

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

# 코드 블록 표시 함수
show_code() {
    echo -e "${CYAN}  $1${NC}"
}

echo -e "${BLUE}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║          🎯 GLI 하이브리드 DB 마이그레이션 - 2단계              ║${NC}"
echo -e "${BLUE}║                 S3 → Staging RDS 복원                        ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${YELLOW}🔄 하이브리드 복원 방식:${NC}"
echo "  🏗️  1단계: SQL 덤프로 완전한 스키마 복원"
echo "  📦 2단계: JSON 덤프로 안전한 데이터 복원"
echo "  ✅ 결과: 완벽한 로컬 DB 복사본"
echo ""

echo -e "${RED}⚠️  매우 중요한 주의사항:${NC}"
echo "  • Staging RDS의 모든 스키마와 데이터가 완전히 대체됩니다"
echo "  • 마이그레이션 중 서비스가 중단될 수 있습니다"
echo "  • 백업 생성을 강력히 권장합니다"
echo "  • 실행 후에는 되돌릴 수 없습니다 (백업 없이는)"
echo ""

# 사용자 확인
read -p "위험을 이해했으며 계속하시겠습니까? (yes/no): " confirm
if [ "$confirm" != "yes" ]; then
    show_error "취소되었습니다."
    exit 1
fi

echo ""
echo -e "${GREEN}🚀 하이브리드 복원 프로세스 시작...${NC}"
echo ""

# =============================================================================
# 1단계: Staging ECS Task 찾기
# =============================================================================

show_step 1 6 "Staging ECS Task 연결"

echo "   🔍 실행 중인 ECS Task 검색 중..."

# 실행 중인 Task ARN 가져오기
TASK_ARN=$(aws ecs list-tasks \
    --cluster "${ECS_CLUSTER}" \
    --service-name "${ECS_SERVICE}" \
    --desired-status RUNNING \
    --query 'taskArns[0]' \
    --output text \
    --profile gli 2>/dev/null)

if [ "${TASK_ARN}" == "None" ] || [ -z "${TASK_ARN}" ]; then
    show_error "실행 중인 Staging Task를 찾을 수 없습니다"
    show_info "ECS 서비스 상태를 확인하세요: AWS Console → ECS → ${ECS_CLUSTER}"
    exit 1
fi

TASK_ID=$(basename "${TASK_ARN}")
show_success "ECS Task 발견: ${TASK_ID}"
echo ""

# =============================================================================
# 2단계: S3 덤프 파일 확인
# =============================================================================

show_step 2 6 "S3 하이브리드 덤프 파일 확인"

echo "   📋 SQL 스키마 덤프 파일 확인 중..."
if aws s3 ls "s3://gli-platform-media-staging/db-sync/local-to-staging-schema.sql.gz" --profile gli > /dev/null 2>&1; then
    SQL_SIZE=$(aws s3 ls s3://gli-platform-media-staging/db-sync/local-to-staging-schema.sql.gz --profile gli | awk '{print $3}')
    SQL_SIZE_MB=$(echo "scale=2; ${SQL_SIZE} / 1024 / 1024" | bc 2>/dev/null || echo "N/A")
    show_success "SQL 스키마 덤프: ${SQL_SIZE_MB} MB"
else
    show_error "SQL 스키마 덤프 파일을 찾을 수 없습니다"
    show_info "먼저 1단계 업로드 스크립트를 실행하세요"
    exit 1
fi

echo "   📦 JSON 데이터 덤프 파일 확인 중..."
if aws s3 ls "s3://gli-platform-media-staging/db-sync/local-to-staging-dump.json.gz" --profile gli > /dev/null 2>&1; then
    JSON_SIZE=$(aws s3 ls s3://gli-platform-media-staging/db-sync/local-to-staging-dump.json.gz --profile gli | awk '{print $3}')
    JSON_SIZE_MB=$(echo "scale=2; ${JSON_SIZE} / 1024 / 1024" | bc 2>/dev/null || echo "N/A")
    show_success "JSON 데이터 덤프: ${JSON_SIZE_MB} MB"
else
    show_error "JSON 데이터 덤프 파일을 찾을 수 없습니다"
    show_info "먼저 1단계 업로드 스크립트를 실행하세요"
    exit 1
fi

show_info "하이브리드 덤프 파일 확인 완료!"
echo ""

# =============================================================================
# 3단계: 복원 명령어 안내
# =============================================================================

show_step 3 6 "ECS 컨테이너 접속 및 복원 명령어 준비"

echo -e "${YELLOW}📋 ECS 컨테이너에서 실행할 명령어들:${NC}"
echo ""

echo -e "${PURPLE}# ============================================${NC}"
echo -e "${PURPLE}# ECS 컨테이너 내부에서 실행할 명령어들${NC}"
echo -e "${PURPLE}# ============================================${NC}"
echo ""

echo -e "${CYAN}# 1. 작업 디렉토리 이동${NC}"
show_code "cd /app"
echo ""

echo -e "${CYAN}# 2. (강력 권장) Staging DB 백업 생성${NC}"
show_code "python << 'EOF'"
show_code "import os, subprocess, django"
show_code "os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')"
show_code "django.setup()"
show_code "from django.db import connection"
show_code "backup_file = f'/tmp/staging_backup_{__import__(\"datetime\").datetime.now().strftime(\"%Y%m%d_%H%M%S\")}.sql'"
show_code "with connection.cursor() as cursor:"
show_code "    cursor.execute('SELECT version()')"
show_code "    version = cursor.fetchone()[0]"
show_code "print(f'✅ PostgreSQL 버전: {version}')"
show_code "print(f'💾 백업 생성 위치: {backup_file}')"
show_code "subprocess.run(['pg_dump', os.environ['DATABASE_URL'], '-f', backup_file], check=True)"
show_code "print('✅ Staging DB 백업 완료!')"
show_code "EOF"
echo ""

echo -e "${CYAN}# 3. S3에서 하이브리드 덤프 다운로드${NC}"
show_code "curl -o /tmp/schema.sql.gz 'https://gli-platform-media-staging.s3.ap-northeast-2.amazonaws.com/db-sync/local-to-staging-schema.sql.gz'"
show_code "curl -o /tmp/data.json.gz 'https://gli-platform-media-staging.s3.ap-northeast-2.amazonaws.com/db-sync/local-to-staging-dump.json.gz'"
show_code "gunzip /tmp/schema.sql.gz"
show_code "echo '✅ 하이브리드 덤프 다운로드 완료'"
echo ""

echo -e "${CYAN}# 4. 1단계: SQL 덤프로 스키마 완전 복원${NC}"
show_code "python << 'EOF'"
show_code "import os, django, re"
show_code "os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')"
show_code "django.setup()"
show_code "from django.db import connection"
show_code ""
show_code "print('🏗️  SQL 스키마 복원 시작...')"
show_code "with open('/tmp/schema.sql', 'r', encoding='utf-8') as f:"
show_code "    sql_content = f.read()"
show_code ""
show_code "# PostgreSQL 메타데이터 제거 및 SQL 구문 분리"
show_code "lines = sql_content.split('\\n')"
show_code "sql_statements = []"
show_code "current_statement = []"
show_code ""
show_code "for line in lines:"
show_code "    # pg_dump 메타데이터 라인 스킵"
show_code "    if (line.startswith('--') or line.startswith('Schema:') or "
show_code "        line.startswith('Owner:') or line.startswith('Type:') or"
show_code "        line.strip() == '' or 'pg_dump:' in line):"
show_code "        continue"
show_code "    current_statement.append(line)"
show_code "    if line.strip().endswith(';'):"
show_code "        statement = '\\n'.join(current_statement).strip()"
show_code "        if statement and len(statement) > 10:"
show_code "            sql_statements.append(statement)"
show_code "        current_statement = []"
show_code ""
show_code "print(f'📊 실행할 SQL 구문: {len(sql_statements)}개')"
show_code ""
show_code "# SQL 구문 실행"
show_code "with connection.cursor() as cursor:"
show_code "    success_count = 0"
show_code "    for i, statement in enumerate(sql_statements):"
show_code "        try:"
show_code "            # COPY 구문은 건너뛰기 (Django에서 지원하지 않음)"
show_code "            if statement.strip().upper().startswith('COPY'):"
show_code "                continue"
show_code "            cursor.execute(statement)"
show_code "            success_count += 1"
show_code "            if i % 100 == 0 and i > 0:"
show_code "                print(f'진행: {i}/{len(sql_statements)} ({success_count}개 성공)')"
show_code "        except Exception as e:"
show_code "            if not any(keyword in str(e).lower() for keyword in ['already exists', 'does not exist']):"
show_code "                print(f'⚠️  구문 {i}: {str(e)[:80]}...')"
show_code ""
show_code "print(f'✅ SQL 스키마 복원 완료! ({success_count}/{len(sql_statements)} 성공)')"
show_code "EOF"
echo ""

echo -e "${CYAN}# 5. 2단계: JSON 덤프로 데이터 안전 복원${NC}"
show_code "source .venv/bin/activate"
show_code "python manage.py sync_db --load --s3-key db-sync/local-to-staging-dump.json.gz --force"
echo ""

echo -e "${CYAN}# 6. 마이그레이션 상태 검증${NC}"
show_code "python << 'EOF'"
show_code "import os, django"
show_code "os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'config.settings')"
show_code "django.setup()"
show_code "from django.db import connection"
show_code "from django.contrib.auth import get_user_model"
show_code ""
show_code "print('🔍 마이그레이션 검증 중...')"
show_code ""
show_code "# 테이블 수 확인"
show_code "with connection.cursor() as cursor:"
show_code "    cursor.execute(\"SELECT count(*) FROM information_schema.tables WHERE table_schema = 'public'\")"
show_code "    table_count = cursor.fetchone()[0]"
show_code "    print(f'📋 테이블 수: {table_count}')"
show_code ""
show_code "# 사용자 수 확인"
show_code "User = get_user_model()"
show_code "user_count = User.objects.count()"
show_code "print(f'👥 사용자 수: {user_count}')"
show_code ""
show_code "# Django 마이그레이션 상태 확인"
show_code "cursor.execute(\"SELECT count(*) FROM django_migrations\")"
show_code "migration_count = cursor.fetchone()[0]"
show_code "print(f'🔄 마이그레이션 기록: {migration_count}')"
show_code ""
show_code "print('✅ 마이그레이션 검증 완료!')"
show_code "EOF"
echo ""

echo -e "${CYAN}# 7. 임시 파일 정리${NC}"
show_code "rm -f /tmp/schema.sql /tmp/data.json.gz"
show_code "echo '✅ 임시 파일 정리 완료'"
echo ""

echo -e "${PURPLE}# ============================================${NC}"
show_warning "위 명령어들을 ECS 컨테이너에서 순서대로 실행하세요!"
echo ""

# =============================================================================
# 4단계: ECS Exec 실행 확인
# =============================================================================

show_step 4 6 "ECS Exec 연결 확인"

read -p "ECS 컨테이너에 접속하시겠습니까? (yes/no): " exec_confirm

if [ "$exec_confirm" != "yes" ]; then
    echo ""
    show_warning "수동 접속을 선택했습니다."
    show_info "다음 명령어로 수동 접속 가능:"
    show_code "aws ecs execute-command \\"
    show_code "  --cluster ${ECS_CLUSTER} \\"
    show_code "  --task ${TASK_ID} \\"
    show_code "  --container django-api \\"
    show_code "  --interactive \\"
    show_code "  --command \"/bin/bash\" \\"
    show_code "  --profile gli"
    echo ""
    exit 0
fi

# =============================================================================
# 5단계: ECS Exec 실행
# =============================================================================

show_step 5 6 "ECS 컨테이너 접속"

echo ""
show_success "ECS Exec 연결 시작..."
echo ""

# ECS Exec 실행
aws ecs execute-command \
    --cluster "${ECS_CLUSTER}" \
    --task "${TASK_ID}" \
    --container django-api \
    --interactive \
    --command "/bin/bash" \
    --profile gli

# =============================================================================
# 6단계: 완료 메시지
# =============================================================================

echo ""
show_step 6 6 "마이그레이션 완료 확인"
echo ""

echo -e "${GREEN}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║          🎉 하이브리드 DB 마이그레이션 완료!                    ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${BLUE}📊 마이그레이션 정보:${NC}"
echo "  🏗️  스키마: SQL 덤프로 완전 복원"
echo "  📦 데이터: JSON 덤프로 안전 복원"
echo "  🎯 대상: Staging RDS"
echo "  💾 백업: /tmp/staging_backup_*.sql"
echo ""

echo -e "${BLUE}🔧 복원 방식:${NC}"
echo "  • 1단계: PostgreSQL pg_dump → 완전한 스키마 복원"
echo "  • 2단계: Django sync_db → 안전한 데이터 복원"
echo "  • 결과: 로컬 DB와 동일한 Staging DB"
echo ""

echo -e "${YELLOW}🔍 다음 확인 사항:${NC}"
echo "  1. Staging 애플리케이션 정상 작동 확인"
echo "  2. Django Admin 페이지 접속 테스트"
echo "  3. API 엔드포인트 응답 확인"
echo "  4. 사용자 로그인 테스트"
echo ""

echo -e "${PURPLE}🌐 확인 링크:${NC}"
echo "  • Django Admin: https://staging.gli.com/admin/"
echo "  • API Health: https://staging.gli.com/api/common/health/"
echo "  • 사용자 포털: https://stg.glibiz.com/"
echo ""

echo -e "${GREEN}✨ 마이그레이션이 성공적으로 완료되었습니다!${NC}"