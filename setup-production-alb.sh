#!/bin/bash

# GLI Project - Production ALB Setup Script
# Production 환경의 ALB 생성

set -e

REGION="ap-northeast-2"
PROJECT="gli"
ACM_CERT_ARN="arn:aws:acm:ap-northeast-2:917891822317:certificate/8590e8e6-1e73-4754-983f-b77ed18e3a82"

echo "================================================"
echo "GLI Production ALB Setup"
echo "================================================"
echo ""
read -p "Production ALB를 생성하시겠습니까? (yes 입력 필요): " -r
if [[ ! $REPLY == "yes" ]]; then
  echo "❌ 작업이 취소되었습니다"
  exit 1
fi

echo ""
echo "================================================"
echo "Step 1: VPC 및 Security Group 확인"
echo "================================================"

# Get VPC
VPC_ID=$(aws ec2 describe-vpcs \
  --region $REGION \
  --filters "Name=is-default,Values=true" \
  --query 'Vpcs[0].VpcId' \
  --output text)

echo "VPC ID: $VPC_ID"

# Get existing Security Group (use same as staging)
SG_ID=$(aws ec2 describe-security-groups \
  --region $REGION \
  --filters "Name=group-name,Values=gli-alb-sg" "Name=vpc-id,Values=$VPC_ID" \
  --query 'SecurityGroups[0].GroupId' \
  --output text)

echo "Security Group: $SG_ID"

# Get subnets
SUBNETS=$(aws ec2 describe-subnets \
  --region $REGION \
  --filters "Name=vpc-id,Values=$VPC_ID" \
  --query 'Subnets[*].SubnetId' \
  --output text)

SUBNET_ARRAY=($SUBNETS)
echo "Subnets: ${SUBNET_ARRAY[@]:0:2}"

echo ""
echo "================================================"
echo "Step 2: Production ALB 생성"
echo "================================================"

ALB_NAME="gli-production-alb"
echo "Creating ALB: $ALB_NAME"

# Check if ALB already exists
ALB_ARN=$(aws elbv2 describe-load-balancers \
  --region $REGION \
  --query 'LoadBalancers[?LoadBalancerName==`'$ALB_NAME'`].LoadBalancerArn' \
  --output text 2>/dev/null || echo "")

if [ -z "$ALB_ARN" ]; then
  ALB_ARN=$(aws elbv2 create-load-balancer \
    --region $REGION \
    --name "$ALB_NAME" \
    --type application \
    --scheme internet-facing \
    --ip-address-type ipv4 \
    --subnets ${SUBNET_ARRAY[0]} ${SUBNET_ARRAY[1]} \
    --security-groups "$SG_ID" \
    --tags Key=Project,Value=$PROJECT Key=Environment,Value=production \
    --query 'LoadBalancers[0].LoadBalancerArn' \
    --output text)

  echo "✅ Created ALB: $ALB_ARN"
else
  echo "✅ ALB already exists: $ALB_ARN"
fi

# Get DNS name
ALB_DNS=$(aws elbv2 describe-load-balancers \
  --region $REGION \
  --load-balancer-arns "$ALB_ARN" \
  --query 'LoadBalancers[0].DNSName' \
  --output text)

echo "   DNS Name: $ALB_DNS"

echo ""
echo "================================================"
echo "Step 3: Production Target Groups 생성"
echo "================================================"

# Target Group for Production API
TG_API_NAME="gli-prod-api-tg"
echo "Creating Target Group: $TG_API_NAME"

TG_API_ARN=$(aws elbv2 describe-target-groups \
  --region $REGION \
  --query 'TargetGroups[?TargetGroupName==`'$TG_API_NAME'`].TargetGroupArn' \
  --output text 2>/dev/null || echo "")

if [ -z "$TG_API_ARN" ]; then
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
    --tags Key=Project,Value=$PROJECT Key=Environment,Value=production \
    --query 'TargetGroups[0].TargetGroupArn' \
    --output text)

  echo "✅ Created Target Group: $TG_API_ARN"
else
  echo "✅ Target Group already exists: $TG_API_ARN"
fi

# Target Group for Production WebSocket
TG_WS_NAME="gli-prod-ws-tg"
echo "Creating Target Group: $TG_WS_NAME"

TG_WS_ARN=$(aws elbv2 describe-target-groups \
  --region $REGION \
  --query 'TargetGroups[?TargetGroupName==`'$TG_WS_NAME'`].TargetGroupArn' \
  --output text 2>/dev/null || echo "")

if [ -z "$TG_WS_ARN" ]; then
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
    --tags Key=Project,Value=$PROJECT Key=Environment,Value=production \
    --query 'TargetGroups[0].TargetGroupArn' \
    --output text)

  echo "✅ Created Target Group: $TG_WS_ARN"
else
  echo "✅ Target Group already exists: $TG_WS_ARN"
fi

echo ""
echo "================================================"
echo "Step 4: Production ALB Listeners 생성"
echo "================================================"

# HTTP Listener (port 80)
echo "Creating HTTP Listener (port 80)..."

LISTENER_HTTP=$(aws elbv2 describe-listeners \
  --region $REGION \
  --load-balancer-arn "$ALB_ARN" \
  --query 'Listeners[?Port==`80`].ListenerArn' \
  --output text 2>/dev/null || echo "")

if [ -z "$LISTENER_HTTP" ]; then
  aws elbv2 create-listener \
    --region $REGION \
    --load-balancer-arn "$ALB_ARN" \
    --protocol HTTP \
    --port 80 \
    --default-actions Type=redirect,RedirectConfig="{Protocol=HTTPS,Port=443,StatusCode=HTTP_301}" \
    --tags Key=Project,Value=$PROJECT > /dev/null

  echo "✅ Created HTTP Listener (redirects to HTTPS)"
else
  echo "✅ HTTP Listener already exists"
fi

# HTTPS Listener (port 443) with host-based routing
echo "Creating HTTPS Listener (port 443)..."

LISTENER_HTTPS=$(aws elbv2 describe-listeners \
  --region $REGION \
  --load-balancer-arn "$ALB_ARN" \
  --query 'Listeners[?Port==`443`].ListenerArn' \
  --output text 2>/dev/null || echo "")

if [ -z "$LISTENER_HTTPS" ]; then
  LISTENER_HTTPS=$(aws elbv2 create-listener \
    --region $REGION \
    --load-balancer-arn "$ALB_ARN" \
    --protocol HTTPS \
    --port 443 \
    --certificates CertificateArn="$ACM_CERT_ARN" \
    --default-actions Type=fixed-response,FixedResponseConfig="{MessageBody='GLI API',StatusCode='200',ContentType='text/plain'}" \
    --query 'Listeners[0].ListenerArn' \
    --output text)

  echo "✅ Created HTTPS Listener: $LISTENER_HTTPS"

  # Add rule for api.glibiz.com
  echo "Adding listener rule for api.glibiz.com..."
  aws elbv2 create-rule \
    --region $REGION \
    --listener-arn "$LISTENER_HTTPS" \
    --priority 10 \
    --conditions Field=host-header,Values=api.glibiz.com \
    --actions Type=forward,TargetGroupArn="$TG_API_ARN" > /dev/null

  # Add rule for ws.glibiz.com
  echo "Adding listener rule for ws.glibiz.com..."
  aws elbv2 create-rule \
    --region $REGION \
    --listener-arn "$LISTENER_HTTPS" \
    --priority 20 \
    --conditions Field=host-header,Values=ws.glibiz.com \
    --actions Type=forward,TargetGroupArn="$TG_WS_ARN" > /dev/null

  echo "✅ Created listener rules"
else
  echo "✅ HTTPS Listener already exists"
fi

echo ""
echo "================================================"
echo "Step 5: Route53 레코드 생성"
echo "================================================"

HOSTED_ZONE_ID="Z0419507IHNIDPFGXUPL"
ALB_HOSTED_ZONE="ZWKZPGTI48KDX"  # ap-northeast-2 ALB

cat > /tmp/route53-prod-backend.json << EOF
{
  "Comment": "Create production API and WebSocket DNS records",
  "Changes": [
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "api.glibiz.com",
        "Type": "A",
        "AliasTarget": {
          "HostedZoneId": "$ALB_HOSTED_ZONE",
          "DNSName": "$ALB_DNS",
          "EvaluateTargetHealth": true
        }
      }
    },
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "ws.glibiz.com",
        "Type": "A",
        "AliasTarget": {
          "HostedZoneId": "$ALB_HOSTED_ZONE",
          "DNSName": "$ALB_DNS",
          "EvaluateTargetHealth": true
        }
      }
    }
  ]
}
EOF

echo "Creating Route53 records..."
aws route53 change-resource-record-sets \
  --hosted-zone-id "$HOSTED_ZONE_ID" \
  --change-batch file:///tmp/route53-prod-backend.json > /dev/null

echo "✅ Route53 레코드 생성 완료"
echo "   api.glibiz.com → ALB"
echo "   ws.glibiz.com → ALB"

echo ""
echo "================================================"
echo "Summary"
echo "================================================"
echo "✅ Production ALB 설정 완료!"
echo ""
echo "생성된 리소스:"
echo "  - ALB: $ALB_DNS"
echo "  - Target Group (API): $TG_API_ARN"
echo "  - Target Group (WebSocket): $TG_WS_ARN"
echo "  - DNS: api.glibiz.com, ws.glibiz.com"
echo ""
echo "다음 단계:"
echo "  1. CloudFront Distributions 생성"
echo "  2. Frontend Route53 레코드 추가"
echo "  3. GitHub Secrets 설정"
echo "  4. Production 배포"
echo ""
echo "================================================"
