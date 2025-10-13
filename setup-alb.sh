#!/bin/bash

# GLI Project - Application Load Balancer Setup Script
# API와 WebSocket용 ALB 생성

set -e

REGION="ap-northeast-2"
PROJECT="gli"
DOMAIN="glibiz.com"

echo "================================================"
echo "GLI Application Load Balancer Setup"
echo "================================================"
echo ""
echo "이 스크립트는 다음을 생성합니다:"
echo "  - Application Load Balancer (2개: Staging, Production)"
echo "  - Target Groups (4개: API/WebSocket x Staging/Production)"
echo "  - Security Groups"
echo "  - Listeners (HTTP:80, HTTPS:443)"
echo ""
read -p "계속하시겠습니까? (yes 입력 필요): " -r
if [[ ! $REPLY == "yes" ]]; then
  echo "❌ 작업이 취소되었습니다"
  exit 1
fi

echo ""
echo "================================================"
echo "Step 1: VPC 및 Subnet 정보 조회"
echo "================================================"

# Get default VPC
VPC_ID=$(aws ec2 describe-vpcs \
  --region $REGION \
  --filters "Name=is-default,Values=true" \
  --query 'Vpcs[0].VpcId' \
  --output text)

echo "VPC ID: $VPC_ID"

# Get public subnets (at least 2 for ALB)
SUBNETS=$(aws ec2 describe-subnets \
  --region $REGION \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --query 'Subnets[*].SubnetId' \
  --output text)

SUBNET_ARRAY=($SUBNETS)
echo "Subnets: ${SUBNET_ARRAY[@]}"

if [ ${#SUBNET_ARRAY[@]} -lt 2 ]; then
  echo "❌ ALB는 최소 2개의 서브넷이 필요합니다"
  exit 1
fi

echo ""
echo "================================================"
echo "Step 2: Security Group 생성"
echo "================================================"

# Create Security Group for ALB
SG_NAME="gli-alb-sg"
echo "Creating Security Group: $SG_NAME"

# Check if security group already exists
SG_ID=$(aws ec2 describe-security-groups \
  --region $REGION \
  --filters "Name=group-name,Values=$SG_NAME" "Name=vpc-id,Values=$VPC_ID" \
  --query 'SecurityGroups[0].GroupId' \
  --output text 2>/dev/null || echo "")

if [ -z "$SG_ID" ] || [ "$SG_ID" = "None" ]; then
  SG_ID=$(aws ec2 create-security-group \
    --region $REGION \
    --group-name "$SG_NAME" \
    --description "Security group for GLI Application Load Balancer" \
    --vpc-id "$VPC_ID" \
    --query 'GroupId' \
    --output text)

  # Add inbound rules
  aws ec2 authorize-security-group-ingress \
    --region $REGION \
    --group-id "$SG_ID" \
    --protocol tcp \
    --port 80 \
    --cidr 0.0.0.0/0

  aws ec2 authorize-security-group-ingress \
    --region $REGION \
    --group-id "$SG_ID" \
    --protocol tcp \
    --port 443 \
    --cidr 0.0.0.0/0

  # Tag security group
  aws ec2 create-tags \
    --region $REGION \
    --resources "$SG_ID" \
    --tags Key=Name,Value=$SG_NAME Key=Project,Value=$PROJECT

  echo "✅ Created Security Group: $SG_ID"
else
  echo "✅ Security Group already exists: $SG_ID"
fi

echo ""
echo "================================================"
echo "Step 3: Staging ALB 생성"
echo "================================================"

ALB_NAME="gli-staging-alb"
echo "Creating ALB: $ALB_NAME"

# Check if ALB already exists
ALB_ARN=$(aws elbv2 describe-load-balancers \
  --region $REGION \
  --names "$ALB_NAME" \
  --query 'LoadBalancers[0].LoadBalancerArn' \
  --output text 2>/dev/null || echo "")

if [ -z "$ALB_ARN" ] || [ "$ALB_ARN" = "None" ]; then
  ALB_ARN=$(aws elbv2 create-load-balancer \
    --region $REGION \
    --name "$ALB_NAME" \
    --type application \
    --scheme internet-facing \
    --ip-address-type ipv4 \
    --subnets ${SUBNET_ARRAY[0]} ${SUBNET_ARRAY[1]} \
    --security-groups "$SG_ID" \
    --tags Key=Project,Value=$PROJECT Key=Environment,Value=staging \
    --query 'LoadBalancers[0].LoadBalancerArn' \
    --output text)

  echo "✅ Created ALB: $ALB_ARN"

  # Get DNS name
  ALB_DNS=$(aws elbv2 describe-load-balancers \
    --region $REGION \
    --load-balancer-arns "$ALB_ARN" \
    --query 'LoadBalancers[0].DNSName' \
    --output text)

  echo "   DNS Name: $ALB_DNS"
else
  echo "✅ ALB already exists: $ALB_ARN"

  ALB_DNS=$(aws elbv2 describe-load-balancers \
    --region $REGION \
    --load-balancer-arns "$ALB_ARN" \
    --query 'LoadBalancers[0].DNSName' \
    --output text)

  echo "   DNS Name: $ALB_DNS"
fi

echo ""
echo "================================================"
echo "Step 4: Staging Target Groups 생성"
echo "================================================"

# Target Group for Staging API
TG_API_NAME="gli-stg-api-tg"
echo "Creating Target Group: $TG_API_NAME"

TG_API_ARN=$(aws elbv2 describe-target-groups \
  --region $REGION \
  --names "$TG_API_NAME" \
  --query 'TargetGroups[0].TargetGroupArn' \
  --output text 2>/dev/null || echo "")

if [ -z "$TG_API_ARN" ] || [ "$TG_API_ARN" = "None" ]; then
  TG_API_ARN=$(aws elbv2 create-target-group \
    --region $REGION \
    --name "$TG_API_NAME" \
    --protocol HTTP \
    --port 8000 \
    --vpc-id "$VPC_ID" \
    --target-type ip \
    --health-check-path /health/ \
    --health-check-interval-seconds 30 \
    --health-check-timeout-seconds 5 \
    --healthy-threshold-count 2 \
    --unhealthy-threshold-count 3 \
    --tags Key=Project,Value=$PROJECT Key=Environment,Value=staging \
    --query 'TargetGroups[0].TargetGroupArn' \
    --output text)

  echo "✅ Created Target Group: $TG_API_ARN"
else
  echo "✅ Target Group already exists: $TG_API_ARN"
fi

# Target Group for Staging WebSocket
TG_WS_NAME="gli-stg-ws-tg"
echo "Creating Target Group: $TG_WS_NAME"

TG_WS_ARN=$(aws elbv2 describe-target-groups \
  --region $REGION \
  --names "$TG_WS_NAME" \
  --query 'TargetGroups[0].TargetGroupArn' \
  --output text 2>/dev/null || echo "")

if [ -z "$TG_WS_ARN" ] || [ "$TG_WS_ARN" = "None" ]; then
  TG_WS_ARN=$(aws elbv2 create-target-group \
    --region $REGION \
    --name "$TG_WS_NAME" \
    --protocol HTTP \
    --port 8080 \
    --vpc-id "$VPC_ID" \
    --target-type ip \
    --health-check-path /health \
    --health-check-interval-seconds 30 \
    --health-check-timeout-seconds 5 \
    --healthy-threshold-count 2 \
    --unhealthy-threshold-count 3 \
    --tags Key=Project,Value=$PROJECT Key=Environment,Value=staging \
    --query 'TargetGroups[0].TargetGroupArn' \
    --output text)

  echo "✅ Created Target Group: $TG_WS_ARN"
else
  echo "✅ Target Group already exists: $TG_WS_ARN"
fi

echo ""
echo "================================================"
echo "Step 5: Staging ALB Listeners 생성"
echo "================================================"

# HTTP Listener (port 80) - redirect to HTTPS
echo "Creating HTTP Listener (port 80)..."

LISTENER_HTTP=$(aws elbv2 describe-listeners \
  --region $REGION \
  --load-balancer-arn "$ALB_ARN" \
  --query 'Listeners[?Port==`80`].ListenerArn' \
  --output text 2>/dev/null || echo "")

if [ -z "$LISTENER_HTTP" ] || [ "$LISTENER_HTTP" = "None" ]; then
  aws elbv2 create-listener \
    --region $REGION \
    --load-balancer-arn "$ALB_ARN" \
    --protocol HTTP \
    --port 80 \
    --default-actions Type=fixed-response,FixedResponseConfig="{MessageBody='OK',StatusCode='200',ContentType='text/plain'}" \
    --tags Key=Project,Value=$PROJECT > /dev/null

  echo "✅ Created HTTP Listener"
else
  echo "✅ HTTP Listener already exists"
fi

echo ""
echo "⚠️  HTTPS Listener는 ACM 인증서가 필요합니다."
echo "   ACM 인증서 ARN을 확인한 후 수동으로 생성하세요:"
echo ""
echo "aws elbv2 create-listener \\"
echo "  --region $REGION \\"
echo "  --load-balancer-arn $ALB_ARN \\"
echo "  --protocol HTTPS \\"
echo "  --port 443 \\"
echo "  --certificates CertificateArn=<ACM_CERTIFICATE_ARN> \\"
echo "  --default-actions Type=forward,TargetGroupArn=$TG_API_ARN"

echo ""
echo "================================================"
echo "Step 6: Production ALB 생성 (선택 사항)"
echo "================================================"

read -p "Production ALB도 생성하시겠습니까? (yes/no): " -r
if [[ $REPLY == "yes" ]]; then
  ALB_NAME="gli-production-alb"
  echo "Creating ALB: $ALB_NAME"

  # (동일한 로직 반복)
  echo "⚠️  Production ALB 생성은 수동으로 진행하거나 이 스크립트를 확장하세요."
fi

echo ""
echo "================================================"
echo "Summary"
echo "================================================"
echo "✅ ALB 설정 완료!"
echo ""
echo "생성된 리소스:"
echo "  - Security Group: $SG_ID"
echo "  - Staging ALB: $ALB_DNS"
echo "  - Target Group (API): $TG_API_ARN"
echo "  - Target Group (WebSocket): $TG_WS_ARN"
echo ""
echo "⚠️  다음 단계:"
echo "  1. ACM 인증서 확인 및 HTTPS Listener 생성"
echo "  2. Route53에 A 레코드 추가 (ALB를 가리킴)"
echo "  3. ECS 서비스에 Target Group 연결"
echo ""
echo "Route53 레코드 예시:"
echo "  stg-api.glibiz.com → ALIAS → $ALB_DNS"
echo "  stg-ws.glibiz.com → ALIAS → $ALB_DNS"
echo ""
echo "================================================"
