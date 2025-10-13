#!/bin/bash

# GLI Project - ECS Services Creation Script
# ALB Target Groups와 연결된 ECS 서비스 생성

set -e

REGION="ap-northeast-2"

echo "================================================"
echo "GLI ECS Services Creation"
echo "================================================"
echo ""
echo "이 스크립트는 ECS 서비스를 생성하고 ALB Target Groups에 연결합니다."
echo ""
read -p "계속하시겠습니까? (yes 입력 필요): " -r
if [[ ! $REPLY == "yes" ]]; then
  echo "❌ 작업이 취소되었습니다"
  exit 1
fi

# Get VPC and network config
VPC_ID=$(aws ec2 describe-vpcs \
  --region $REGION \
  --filters "Name=is-default,Values=true" \
  --query 'Vpcs[0].VpcId' \
  --output text)

SUBNETS=$(aws ec2 describe-subnets \
  --region $REGION \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --query 'Subnets[*].SubnetId' \
  --output text | tr '\t' ',')

# Get ALB Security Group
ALB_SG=$(aws ec2 describe-security-groups \
  --region $REGION \
  --filters "Name=group-name,Values=gli-alb-sg" \
  --query 'SecurityGroups[0].GroupId' \
  --output text)

# Create ECS Task Security Group if not exists
ECS_SG_NAME="gli-ecs-tasks-sg"
ECS_SG=$(aws ec2 describe-security-groups \
  --region $REGION \
  --filters "Name=group-name,Values=$ECS_SG_NAME" \
  --query 'SecurityGroups[0].GroupId' \
  --output text 2>/dev/null || echo "")

if [ -z "$ECS_SG" ] || [ "$ECS_SG" = "None" ]; then
  echo "Creating ECS Tasks Security Group..."

  ECS_SG=$(aws ec2 create-security-group \
    --region $REGION \
    --group-name "$ECS_SG_NAME" \
    --description "Security group for GLI ECS Tasks" \
    --vpc-id "$VPC_ID" \
    --query 'GroupId' \
    --output text)

  # Allow inbound from ALB
  aws ec2 authorize-security-group-ingress \
    --region $REGION \
    --group-id "$ECS_SG" \
    --protocol tcp \
    --port 8000 \
    --source-group "$ALB_SG"

  aws ec2 authorize-security-group-ingress \
    --region $REGION \
    --group-id "$ECS_SG" \
    --protocol tcp \
    --port 8080 \
    --source-group "$ALB_SG"

  # Allow all outbound
  echo "✅ Created ECS Security Group: $ECS_SG"
fi

echo ""
echo "Network Config:"
echo "  VPC: $VPC_ID"
echo "  Subnets: $SUBNETS"
echo "  ECS Security Group: $ECS_SG"
echo ""

echo "================================================"
echo "Staging API Service"
echo "================================================"

CLUSTER="staging-gli-cluster"
SERVICE_NAME="staging-django-api-service"
TG_ARN="arn:aws:elasticloadbalancing:ap-northeast-2:917891822317:targetgroup/gli-stg-api-tg/5f0499ae426668ca"

# Check if service exists
SERVICE_EXISTS=$(aws ecs describe-services \
  --region $REGION \
  --cluster $CLUSTER \
  --services $SERVICE_NAME \
  --query 'services[0].serviceName' \
  --output text 2>/dev/null || echo "")

if [ -z "$SERVICE_EXISTS" ] || [ "$SERVICE_EXISTS" = "None" ]; then
  echo "Creating service: $SERVICE_NAME"

  aws ecs create-service \
    --region $REGION \
    --cluster $CLUSTER \
    --service-name $SERVICE_NAME \
    --task-definition staging-gli-django-api:1 \
    --desired-count 1 \
    --launch-type FARGATE \
    --platform-version LATEST \
    --network-configuration "awsvpcConfiguration={subnets=[$SUBNETS],securityGroups=[$ECS_SG],assignPublicIp=ENABLED}" \
    --load-balancers "targetGroupArn=$TG_ARN,containerName=django-api,containerPort=8000" \
    --health-check-grace-period-seconds 60 \
    --tags key=Project,value=gli key=Environment,value=staging \
    --enable-execute-command > /dev/null

  echo "✅ Created service: $SERVICE_NAME"
else
  echo "✅ Service already exists: $SERVICE_NAME"
fi

echo ""
echo "================================================"
echo "Staging WebSocket Service"
echo "================================================"

SERVICE_NAME="staging-websocket-service"
TG_ARN="arn:aws:elasticloadbalancing:ap-northeast-2:917891822317:targetgroup/gli-stg-ws-tg/586551f254635e4a"

SERVICE_EXISTS=$(aws ecs describe-services \
  --region $REGION \
  --cluster $CLUSTER \
  --services $SERVICE_NAME \
  --query 'services[0].serviceName' \
  --output text 2>/dev/null || echo "")

if [ -z "$SERVICE_EXISTS" ] || [ "$SERVICE_EXISTS" = "None" ]; then
  echo "Creating service: $SERVICE_NAME"

  aws ecs create-service \
    --region $REGION \
    --cluster $CLUSTER \
    --service-name $SERVICE_NAME \
    --task-definition staging-gli-websocket:1 \
    --desired-count 1 \
    --launch-type FARGATE \
    --platform-version LATEST \
    --network-configuration "awsvpcConfiguration={subnets=[$SUBNETS],securityGroups=[$ECS_SG],assignPublicIp=ENABLED}" \
    --load-balancers "targetGroupArn=$TG_ARN,containerName=websocket-server,containerPort=8080" \
    --health-check-grace-period-seconds 60 \
    --tags key=Project,value=gli key=Environment,value=staging \
    --enable-execute-command > /dev/null

  echo "✅ Created service: $SERVICE_NAME"
else
  echo "✅ Service already exists: $SERVICE_NAME"
fi

echo ""
echo "================================================"
echo "Production API Service"
echo "================================================"

CLUSTER="production-gli-cluster"
SERVICE_NAME="production-django-api-service"
TG_ARN="arn:aws:elasticloadbalancing:ap-northeast-2:917891822317:targetgroup/gli-prod-api-tg/650e7e1476633a2f"

SERVICE_EXISTS=$(aws ecs describe-services \
  --region $REGION \
  --cluster $CLUSTER \
  --services $SERVICE_NAME \
  --query 'services[0].serviceName' \
  --output text 2>/dev/null || echo "")

if [ -z "$SERVICE_EXISTS" ] || [ "$SERVICE_EXISTS" = "None" ]; then
  echo "Creating service: $SERVICE_NAME"

  aws ecs create-service \
    --region $REGION \
    --cluster $CLUSTER \
    --service-name $SERVICE_NAME \
    --task-definition production-gli-django-api:1 \
    --desired-count 2 \
    --launch-type FARGATE \
    --platform-version LATEST \
    --network-configuration "awsvpcConfiguration={subnets=[$SUBNETS],securityGroups=[$ECS_SG],assignPublicIp=ENABLED}" \
    --load-balancers "targetGroupArn=$TG_ARN,containerName=django-api,containerPort=8000" \
    --health-check-grace-period-seconds 60 \
    --tags key=Project,value=gli key=Environment,value=production \
    --enable-execute-command > /dev/null

  echo "✅ Created service: $SERVICE_NAME"
else
  echo "✅ Service already exists: $SERVICE_NAME"
fi

echo ""
echo "================================================"
echo "Production WebSocket Service"
echo "================================================"

SERVICE_NAME="production-websocket-service"
TG_ARN="arn:aws:elasticloadbalancing:ap-northeast-2:917891822317:targetgroup/gli-prod-ws-tg/6619e0227a562cbc"

SERVICE_EXISTS=$(aws ecs describe-services \
  --region $REGION \
  --cluster $CLUSTER \
  --services $SERVICE_NAME \
  --query 'services[0].serviceName' \
  --output text 2>/dev/null || echo "")

if [ -z "$SERVICE_EXISTS" ] || [ "$SERVICE_EXISTS" = "None" ]; then
  echo "Creating service: $SERVICE_NAME"

  aws ecs create-service \
    --region $REGION \
    --cluster $CLUSTER \
    --service-name $SERVICE_NAME \
    --task-definition production-gli-websocket:1 \
    --desired-count 2 \
    --launch-type FARGATE \
    --platform-version LATEST \
    --network-configuration "awsvpcConfiguration={subnets=[$SUBNETS],securityGroups=[$ECS_SG],assignPublicIp=ENABLED}" \
    --load-balancers "targetGroupArn=$TG_ARN,containerName=websocket-server,containerPort=8080" \
    --health-check-grace-period-seconds 60 \
    --tags key=Project,value=gli key=Environment,value=production \
    --enable-execute-command > /dev/null

  echo "✅ Created service: $SERVICE_NAME"
else
  echo "✅ Service already exists: $SERVICE_NAME"
fi

echo ""
echo "================================================"
echo "Summary"
echo "================================================"
echo "✅ ECS 서비스 설정 완료!"
echo ""
echo "⚠️  주의사항:"
echo "  - 서비스는 Task Definition이 있어야 시작됩니다"
echo "  - 첫 배포는 GitHub Actions를 통해 Task Definition을 생성합니다"
echo "  - 배포 후 ALB Target Group에 자동으로 등록됩니다"
echo ""
echo "다음 단계:"
echo "  1. GitHub Secrets 설정"
echo "  2. 첫 배포 실행 (./multigit-merge-dev-to-stg.sh)"
echo ""
echo "================================================"
