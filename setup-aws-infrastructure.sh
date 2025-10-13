#!/bin/bash

# GLI Project - AWS Infrastructure Setup Script
# 이 스크립트는 GLI 프로젝트에 필요한 모든 AWS 리소스를 생성합니다.

set -e

REGION="ap-northeast-2"
PROJECT="gli"

echo "================================================"
echo "GLI AWS Infrastructure Setup"
echo "================================================"
echo ""
echo "이 스크립트는 다음 리소스를 생성합니다:"
echo "  - ECR Repositories (4개: API, WebSocket, Staging/Production)"
echo "  - ECS Cluster (Staging, Production)"
echo "  - S3 Buckets (Frontend hosting)"
echo "  - CloudFront Distributions"
echo "  - Application Load Balancer"
echo "  - Target Groups"
echo ""
read -p "계속하시겠습니까? (yes 입력 필요): " -r
if [[ ! $REPLY == "yes" ]]; then
  echo "❌ 작업이 취소되었습니다"
  exit 1
fi

echo ""
echo "================================================"
echo "Step 1: ECR Repositories 생성"
echo "================================================"

# ECR Repositories
ECR_REPOS=(
  "gli-api-staging"
  "gli-api-production"
  "gli-websocket-staging"
  "gli-websocket-production"
)

for repo in "${ECR_REPOS[@]}"; do
  echo "Creating ECR repository: $repo"

  # Check if repository already exists
  if aws ecr describe-repositories --region $REGION --repository-names "$repo" > /dev/null 2>&1; then
    echo "  ✅ Repository already exists: $repo"
  else
    aws ecr create-repository \
      --region $REGION \
      --repository-name "$repo" \
      --image-scanning-configuration scanOnPush=true \
      --encryption-configuration encryptionType=AES256 \
      --tags Key=Project,Value=$PROJECT Key=ManagedBy,Value=Script

    # Set lifecycle policy to keep only last 10 images
    aws ecr put-lifecycle-policy \
      --region $REGION \
      --repository-name "$repo" \
      --lifecycle-policy-text '{
        "rules": [{
          "rulePriority": 1,
          "description": "Keep last 10 images",
          "selection": {
            "tagStatus": "any",
            "countType": "imageCountMoreThan",
            "countNumber": 10
          },
          "action": {
            "type": "expire"
          }
        }]
      }'

    echo "  ✅ Created: $repo"
  fi
done

echo ""
echo "================================================"
echo "Step 2: ECS Clusters 생성"
echo "================================================"

# ECS Clusters
ECS_CLUSTERS=(
  "staging-gli-cluster"
  "production-gli-cluster"
)

for cluster in "${ECS_CLUSTERS[@]}"; do
  echo "Creating ECS cluster: $cluster"

  # Check if cluster already exists
  if aws ecs describe-clusters --region $REGION --clusters "$cluster" --query 'clusters[?status==`ACTIVE`].clusterName' --output text | grep -q "$cluster"; then
    echo "  ✅ Cluster already exists: $cluster"
  else
    aws ecs create-cluster \
      --region $REGION \
      --cluster-name "$cluster" \
      --tags key=Project,value=$PROJECT key=ManagedBy,value=Script \
      --capacity-providers FARGATE FARGATE_SPOT \
      --default-capacity-provider-strategy \
        capacityProvider=FARGATE,weight=1,base=0 \
        capacityProvider=FARGATE_SPOT,weight=4,base=0

    echo "  ✅ Created: $cluster"
  fi
done

echo ""
echo "================================================"
echo "Step 3: S3 Buckets 생성"
echo "================================================"

# S3 Buckets for Frontend
S3_BUCKETS=(
  "gli-user-frontend-staging"
  "gli-user-frontend-production"
  "gli-admin-frontend-staging"
  "gli-admin-frontend-production"
)

for bucket in "${S3_BUCKETS[@]}"; do
  echo "Creating S3 bucket: $bucket"

  # Check if bucket already exists
  if aws s3 ls "s3://$bucket" > /dev/null 2>&1; then
    echo "  ✅ Bucket already exists: $bucket"
  else
    # Create bucket
    aws s3 mb "s3://$bucket" --region $REGION

    # Enable versioning
    aws s3api put-bucket-versioning \
      --bucket "$bucket" \
      --versioning-configuration Status=Enabled

    # Block public access (CloudFront will access via OAI)
    aws s3api put-public-access-block \
      --bucket "$bucket" \
      --public-access-block-configuration \
        BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true

    # Configure as static website
    aws s3 website "s3://$bucket" \
      --index-document index.html \
      --error-document index.html

    # Add bucket policy for CloudFront OAI (will be updated later with actual OAI)

    # Add tags
    aws s3api put-bucket-tagging \
      --bucket "$bucket" \
      --tagging "TagSet=[{Key=Project,Value=$PROJECT},{Key=ManagedBy,Value=Script}]"

    echo "  ✅ Created: $bucket"
  fi
done

echo ""
echo "================================================"
echo "Step 4: CloudWatch Log Groups 생성"
echo "================================================"

# CloudWatch Log Groups
LOG_GROUPS=(
  "/ecs/staging-gli-api"
  "/ecs/staging-gli-websocket"
  "/ecs/production-gli-api"
  "/ecs/production-gli-websocket"
)

for log_group in "${LOG_GROUPS[@]}"; do
  echo "Creating CloudWatch Log Group: $log_group"

  # Check if log group already exists
  if aws logs describe-log-groups --region $REGION --log-group-name-prefix "$log_group" --query 'logGroups[?logGroupName==`'$log_group'`].logGroupName' --output text | grep -q "$log_group"; then
    echo "  ✅ Log group already exists: $log_group"
  else
    aws logs create-log-group \
      --region $REGION \
      --log-group-name "$log_group"

    # Set retention to 30 days
    aws logs put-retention-policy \
      --region $REGION \
      --log-group-name "$log_group" \
      --retention-in-days 30

    echo "  ✅ Created: $log_group"
  fi
done

echo ""
echo "================================================"
echo "Summary"
echo "================================================"
echo "✅ AWS 인프라 기본 리소스 생성 완료!"
echo ""
echo "생성된 리소스:"
echo "  - ECR Repositories: ${#ECR_REPOS[@]}개"
echo "  - ECS Clusters: ${#ECS_CLUSTERS[@]}개"
echo "  - S3 Buckets: ${#S3_BUCKETS[@]}개"
echo "  - CloudWatch Log Groups: ${#LOG_GROUPS[@]}개"
echo ""
echo "⚠️  다음 단계:"
echo "  1. VPC 및 네트워크 설정 (수동 또는 별도 스크립트)"
echo "  2. Application Load Balancer 생성"
echo "  3. Target Groups 생성"
echo "  4. CloudFront Distributions 생성 (setup-cloudfront.sh)"
echo "  5. ECS Services 생성 (setup-ecs-services.sh)"
echo "  6. Route53 레코드 추가"
echo "  7. GitHub Secrets 설정 (setup-github-secrets.sh)"
echo ""
echo "================================================"
