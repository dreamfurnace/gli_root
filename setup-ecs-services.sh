#!/bin/bash

# GLI Project - ECS Services Setup Script
# ECS 서비스 및 Task Definition을 생성합니다.
# ⚠️  이 스크립트 실행 전에 ALB와 Target Groups가 먼저 생성되어 있어야 합니다.

set -e

REGION="ap-northeast-2"
PROJECT="gli"

echo "================================================"
echo "GLI ECS Services Setup"
echo "================================================"
echo ""
echo "⚠️  주의사항:"
echo "  - ALB와 Target Groups가 먼저 생성되어 있어야 합니다"
echo "  - VPC와 Subnet이 설정되어 있어야 합니다"
echo "  - Security Groups가 생성되어 있어야 합니다"
echo ""
read -p "계속하시겠습니까? (yes 입력 필요): " -r
if [[ ! $REPLY == "yes" ]]; then
  echo "❌ 작업이 취소되었습니다"
  exit 1
fi

echo ""
echo "================================================"
echo "VPC 및 Subnet 정보 조회"
echo "================================================"

# Get default VPC
VPC_ID=$(aws ec2 describe-vpcs \
  --region $REGION \
  --filters "Name=is-default,Values=true" \
  --query 'Vpcs[0].VpcId' \
  --output text)

echo "  VPC ID: $VPC_ID"

# Get subnets
SUBNETS=$(aws ec2 describe-subnets \
  --region $REGION \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --query 'Subnets[*].SubnetId' \
  --output text | tr '\t' ',')

echo "  Subnets: $SUBNETS"

# Get default security group
SECURITY_GROUP=$(aws ec2 describe-security-groups \
  --region $REGION \
  --filters "Name=vpc-id,Values=$VPC_ID" "Name=group-name,Values=default" \
  --query 'SecurityGroups[0].GroupId' \
  --output text)

echo "  Security Group: $SECURITY_GROUP"

echo ""
echo "================================================"
echo "Step 1: Staging API Service 설정"
echo "================================================"

CLUSTER="staging-gli-cluster"
SERVICE_NAME="staging-api-service"
TASK_FAMILY="staging-gli-api"

echo "Checking if service exists: $SERVICE_NAME"

SERVICE_EXISTS=$(aws ecs describe-services \
  --region $REGION \
  --cluster $CLUSTER \
  --services $SERVICE_NAME \
  --query 'services[0].serviceName' \
  --output text 2>/dev/null || echo "")

if [ -z "$SERVICE_EXISTS" ] || [ "$SERVICE_EXISTS" = "None" ]; then
  echo "  ℹ️  서비스가 존재하지 않습니다."
  echo "  ⚠️  첫 배포는 GitHub Actions를 통해 수행됩니다."
  echo "  ⚠️  Task Definition이 생성되면 아래 명령어로 서비스를 생성하세요:"
  echo ""
  echo "  aws ecs create-service \\"
  echo "    --region $REGION \\"
  echo "    --cluster $CLUSTER \\"
  echo "    --service-name $SERVICE_NAME \\"
  echo "    --task-definition $TASK_FAMILY:1 \\"
  echo "    --desired-count 1 \\"
  echo "    --launch-type FARGATE \\"
  echo "    --network-configuration \"awsvpcConfiguration={subnets=[$SUBNETS],securityGroups=[$SECURITY_GROUP],assignPublicIp=ENABLED}\""
  echo ""
else
  echo "  ✅ Service already exists: $SERVICE_NAME"
fi

echo ""
echo "================================================"
echo "Step 2: Staging WebSocket Service 설정"
echo "================================================"

SERVICE_NAME="staging-websocket-service"
TASK_FAMILY="staging-gli-websocket"

echo "Checking if service exists: $SERVICE_NAME"

SERVICE_EXISTS=$(aws ecs describe-services \
  --region $REGION \
  --cluster $CLUSTER \
  --services $SERVICE_NAME \
  --query 'services[0].serviceName' \
  --output text 2>/dev/null || echo "")

if [ -z "$SERVICE_EXISTS" ] || [ "$SERVICE_EXISTS" = "None" ]; then
  echo "  ℹ️  서비스가 존재하지 않습니다."
  echo "  ⚠️  첫 배포는 GitHub Actions를 통해 수행됩니다."
  echo "  ⚠️  Task Definition이 생성되면 아래 명령어로 서비스를 생성하세요:"
  echo ""
  echo "  aws ecs create-service \\"
  echo "    --region $REGION \\"
  echo "    --cluster $CLUSTER \\"
  echo "    --service-name $SERVICE_NAME \\"
  echo "    --task-definition $TASK_FAMILY:1 \\"
  echo "    --desired-count 1 \\"
  echo "    --launch-type FARGATE \\"
  echo "    --network-configuration \"awsvpcConfiguration={subnets=[$SUBNETS],securityGroups=[$SECURITY_GROUP],assignPublicIp=ENABLED}\""
  echo ""
else
  echo "  ✅ Service already exists: $SERVICE_NAME"
fi

echo ""
echo "================================================"
echo "Step 3: Production API Service 설정"
echo "================================================"

CLUSTER="production-gli-cluster"
SERVICE_NAME="production-api-service"
TASK_FAMILY="production-gli-api"

echo "Checking if service exists: $SERVICE_NAME"

SERVICE_EXISTS=$(aws ecs describe-services \
  --region $REGION \
  --cluster $CLUSTER \
  --services $SERVICE_NAME \
  --query 'services[0].serviceName' \
  --output text 2>/dev/null || echo "")

if [ -z "$SERVICE_EXISTS" ] || [ "$SERVICE_EXISTS" = "None" ]; then
  echo "  ℹ️  서비스가 존재하지 않습니다."
  echo "  ⚠️  첫 배포는 GitHub Actions를 통해 수행됩니다."
  echo "  ⚠️  Task Definition이 생성되면 아래 명령어로 서비스를 생성하세요:"
  echo ""
  echo "  aws ecs create-service \\"
  echo "    --region $REGION \\"
  echo "    --cluster $CLUSTER \\"
  echo "    --service-name $SERVICE_NAME \\"
  echo "    --task-definition $TASK_FAMILY:1 \\"
  echo "    --desired-count 2 \\"
  echo "    --launch-type FARGATE \\"
  echo "    --network-configuration \"awsvpcConfiguration={subnets=[$SUBNETS],securityGroups=[$SECURITY_GROUP],assignPublicIp=ENABLED}\""
  echo ""
else
  echo "  ✅ Service already exists: $SERVICE_NAME"
fi

echo ""
echo "================================================"
echo "Step 4: Production WebSocket Service 설정"
echo "================================================"

SERVICE_NAME="production-websocket-service"
TASK_FAMILY="production-gli-websocket"

echo "Checking if service exists: $SERVICE_NAME"

SERVICE_EXISTS=$(aws ecs describe-services \
  --region $REGION \
  --cluster $CLUSTER \
  --services $SERVICE_NAME \
  --query 'services[0].serviceName' \
  --output text 2>/dev/null || echo "")

if [ -z "$SERVICE_EXISTS" ] || [ "$SERVICE_EXISTS" = "None" ]; then
  echo "  ℹ️  서비스가 존재하지 않습니다."
  echo "  ⚠️  첫 배포는 GitHub Actions를 통해 수행됩니다."
  echo "  ⚠️  Task Definition이 생성되면 아래 명령어로 서비스를 생성하세요:"
  echo ""
  echo "  aws ecs create-service \\"
  echo "    --region $REGION \\"
  echo "    --cluster $CLUSTER \\"
  echo "    --service-name $SERVICE_NAME \\"
  echo "    --task-definition $TASK_FAMILY:1 \\"
  echo "    --desired-count 2 \\"
  echo "    --launch-type FARGATE \\"
  echo "    --network-configuration \"awsvpcConfiguration={subnets=[$SUBNETS],securityGroups=[$SECURITY_GROUP],assignPublicIp=ENABLED}\""
  echo ""
else
  echo "  ✅ Service already exists: $SERVICE_NAME"
fi

echo ""
echo "================================================"
echo "Summary"
echo "================================================"
echo "ℹ️  ECS 서비스 설정 가이드 제공 완료"
echo ""
echo "⚠️  중요:"
echo "  - ECS 서비스는 첫 배포 시 GitHub Actions에서 자동으로 생성됩니다"
echo "  - 또는 위에 출력된 명령어를 사용하여 수동으로 생성할 수 있습니다"
echo "  - ALB Target Groups 연결이 필요한 경우 --load-balancers 옵션을 추가하세요"
echo ""
echo "다음 단계:"
echo "  1. CloudFront Distributions 생성 (setup-cloudfront.sh)"
echo "  2. GitHub Secrets 설정 (setup-github-secrets.sh)"
echo "  3. 첫 배포 실행 (./multigit-merge-dev-to-stg.sh)"
echo ""
echo "================================================"
