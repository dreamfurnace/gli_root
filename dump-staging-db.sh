#!/usr/bin/env bash
set -euo pipefail

# GLI Staging Database Dump Script
# Staging RDS 데이터를 덤프하여 S3에 업로드

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[94m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║        GLI Staging Database Dump to S3               ║${NC}"
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

echo -e "${BLUE}[2/4]${NC} ECS Exec으로 Task에 접속 중..."
echo -e "${YELLOW}💡 컨테이너 안에서 다음 명령을 실행하세요:${NC}"
echo ""
echo -e "${GREEN}cd /app${NC}"
echo -e "${GREEN}source .venv/bin/activate${NC}"
echo -e "${GREEN}python manage.py sync_db --dump${NC}"
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
    --command \"/bin/bash\"${NC}"
    exit 1
fi

echo ""
echo -e "${BLUE}[3/4]${NC} ECS Exec 실행 중..."
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
echo -e "${BLUE}[4/4]${NC} 덤프 확인..."

# S3에 덤프 파일이 생성되었는지 확인
if aws s3 ls "s3://gli-platform-media-staging/db-sync/latest-dump.json.gz" --profile gli > /dev/null 2>&1; then
    DUMP_SIZE=$(aws s3 ls s3://gli-platform-media-staging/db-sync/latest-dump.json.gz --profile gli | awk '{print $3}')
    DUMP_SIZE_MB=$(echo "scale=2; ${DUMP_SIZE} / 1024 / 1024" | bc)

    echo -e "${GREEN}✅ 덤프 파일 생성 완료!${NC}"
    echo "   위치: s3://gli-platform-media-staging/db-sync/latest-dump.json.gz"
    echo "   크기: ${DUMP_SIZE_MB} MB"
else
    echo -e "${YELLOW}⚠️  덤프 파일을 확인할 수 없습니다.${NC}"
    echo "   명령이 성공적으로 실행되었는지 확인하세요."
fi

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║          다음 단계: 로컬 DB 동기화                       ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${YELLOW}로컬 환경에서 다음 명령을 실행하세요:${NC}"
echo -e "${BLUE}./sync-db-from-staging.sh${NC}"
echo ""
