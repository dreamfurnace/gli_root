#!/usr/bin/env bash
set -euo pipefail

# GLI Local to Staging Database Migration Script - Step 2
# Staging RDS에 로컬에서 업로드된 데이터 복원

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[94m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║       GLI Staging RDS Restore from Local Dump        ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

ECS_CLUSTER="staging-gli-cluster"
ECS_SERVICE="staging-django-api-service"

echo -e "${BLUE}[1/4]${NC} Staging ECS Task 찾기..."

# 실행 중인 Task ARN 가져오기
TASK_ARN=$(aws ecs list-tasks \
    --cluster "${ECS_CLUSTER}" \
    --service-name "${ECS_SERVICE}" \
    --desired-status RUNNING \
    --query 'taskArns[0]' \
    --output text \
    --profile gli)

if [ "${TASK_ARN}" == "None" ] || [ -z "${TASK_ARN}" ]; then
    echo -e "${RED}❌ 실행 중인 Staging Task를 찾을 수 없습니다.${NC}"
    exit 1
fi

TASK_ID=$(basename "${TASK_ARN}")
echo -e "${GREEN}✅ Task 발견: ${TASK_ID}${NC}"
echo ""

echo -e "${BLUE}[2/4]${NC} S3에서 로컬 덤프 파일 확인..."

# S3에 로컬 덤프 파일이 있는지 확인
if aws s3 ls "s3://gli-platform-media-staging/db-sync/local-to-staging-dump.json.gz" --profile gli > /dev/null 2>&1; then
    DUMP_SIZE=$(aws s3 ls s3://gli-platform-media-staging/db-sync/local-to-staging-dump.json.gz --profile gli | awk '{print $3}')
    DUMP_SIZE_MB=$(echo "scale=2; ${DUMP_SIZE} / 1024 / 1024" | bc)

    echo -e "${GREEN}✅ 로컬 덤프 파일 발견!${NC}"
    echo "   위치: s3://gli-platform-media-staging/db-sync/local-to-staging-dump.json.gz"
    echo "   크기: ${DUMP_SIZE_MB} MB"
else
    echo -e "${RED}❌ 로컬 덤프 파일을 찾을 수 없습니다.${NC}"
    echo ""
    echo -e "${YELLOW}먼저 로컬에서 다음 명령을 실행하세요:${NC}"
    echo -e "${BLUE}./dbMig_local-stg_1_upload-local-db.sh${NC}"
    exit 1
fi
echo ""

echo -e "${BLUE}[3/4]${NC} ECS Exec으로 Task에 접속 중..."
echo -e "${RED}⚠️  경고: Staging RDS의 모든 데이터가 삭제되고 로컬 데이터로 대체됩니다!${NC}"
echo ""
echo -e "${YELLOW}💡 컨테이너 안에서 다음 명령을 실행하세요:${NC}"
echo ""
echo -e "${GREEN}cd /app${NC}"
echo -e "${GREEN}source .venv/bin/activate${NC}"
echo ""
echo -e "${YELLOW}# 1. Staging DB 백업 (권장)${NC}"
echo -e "${GREEN}python manage.py sync_db --backup${NC}"
echo ""
echo -e "${YELLOW}# 2. 로컬 덤프 복원${NC}"
echo -e "${GREEN}python manage.py sync_db --load --s3-key db-sync/local-to-staging-dump.json.gz --force${NC}"
echo ""
echo -e "${YELLOW}# 3. 마이그레이션 실행${NC}"
echo -e "${GREEN}python manage.py migrate${NC}"
echo ""
echo -e "${YELLOW}⚠️  완료 후 'exit'를 입력하여 종료하세요.${NC}"
echo ""
read -p "ECS Exec을 시작하시겠습니까? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo -e "${RED}❌ 취소되었습니다.${NC}"
    echo ""
    echo -e "${YELLOW}수동으로 실행하려면:${NC}"
    echo -e "${BLUE}aws ecs execute-command \\
    --cluster ${ECS_CLUSTER} \\
    --task ${TASK_ID} \\
    --container django-api \\
    --interactive \\
    --command \"/bin/bash\" \\
    --profile gli${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}[4/4]${NC} ECS Exec 실행 중..."
echo ""

# ECS Exec 실행
aws ecs execute-command \
    --cluster "${ECS_CLUSTER}" \
    --task "${TASK_ID}" \
    --container django-api \
    --interactive \
    --command "/bin/bash" \
    --profile gli

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║        ✅ 로컬 → Staging 마이그레이션 완료!              ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}📊 마이그레이션 정보:${NC}"
echo "  - 소스: 로컬 Docker PostgreSQL (gli_DB_local)"
echo "  - 대상: Staging RDS"
echo "  - 덤프 위치: s3://gli-platform-media-staging/db-sync/local-to-staging-dump.json.gz"
echo ""
echo -e "${YELLOW}💡 참고:${NC}"
echo "  - Staging DB 백업: ECS Task 내부의 backups/ 디렉토리"
echo "  - 복원 실패 시: 백업에서 복원 가능"
echo "  - Django Admin: https://staging.gli.com/admin/"
echo ""