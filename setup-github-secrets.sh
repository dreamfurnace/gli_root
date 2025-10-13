#!/bin/bash

# GLI Project - GitHub Secrets Setup Helper Script
# GitHub Secrets 설정을 위한 가이드 및 자동화 스크립트
# ⚠️  gh CLI가 설치되어 있어야 합니다: brew install gh

set -e

REGION="ap-northeast-2"
GITHUB_ORG="your-github-org"  # TODO: 실제 조직명으로 변경

echo "================================================"
echo "GLI GitHub Secrets Setup Helper"
echo "================================================"
echo ""
echo "이 스크립트는 GitHub Secrets 설정을 도와줍니다."
echo "gh CLI를 사용하여 자동으로 설정할 수 있습니다."
echo ""

# Check if gh is installed
if ! command -v gh &> /dev/null; then
  echo "❌ gh CLI가 설치되어 있지 않습니다."
  echo "   설치: brew install gh"
  echo "   또는: https://cli.github.com"
  exit 1
fi

# Check if authenticated
if ! gh auth status &> /dev/null; then
  echo "⚠️  GitHub에 로그인이 필요합니다."
  echo "   실행: gh auth login"
  exit 1
fi

echo "✅ gh CLI 인증 확인 완료"
echo ""

# Get AWS Account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "AWS Account ID: $AWS_ACCOUNT_ID"
echo ""

# Get ECR Registry
ECR_REGISTRY="${AWS_ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com"
echo "ECR Registry: $ECR_REGISTRY"
echo ""

echo "================================================"
echo "공통 Secrets (모든 리포지토리)"
echo "================================================"
echo ""
echo "다음 Secrets를 설정해야 합니다:"
echo "  1. AWS_ACCESS_KEY_ID"
echo "  2. AWS_SECRET_ACCESS_KEY"
echo "  3. AWS_REGION"
echo ""

# Function to set secret
set_secret() {
  local repo=$1
  local secret_name=$2
  local secret_value=$3

  echo "  Setting $secret_name in $repo..."

  if gh secret set "$secret_name" -b"$secret_value" -R "$GITHUB_ORG/$repo" 2>/dev/null; then
    echo "    ✅ Set: $secret_name"
  else
    echo "    ⚠️  Failed to set: $secret_name"
  fi
}

# Common secrets for all repos
REPOS=(
  "gli_api-server"
  "gli_websocket"
  "gli_user-frontend"
  "gli_admin-frontend"
)

echo ""
read -p "공통 Secrets를 설정하시겠습니까? (yes/no): " -r
if [[ $REPLY == "yes" ]]; then
  echo ""
  read -p "AWS_ACCESS_KEY_ID를 입력하세요: " AWS_ACCESS_KEY
  read -sp "AWS_SECRET_ACCESS_KEY를 입력하세요: " AWS_SECRET_KEY
  echo ""

  for repo in "${REPOS[@]}"; do
    echo "Configuring $repo..."
    set_secret "$repo" "AWS_ACCESS_KEY_ID" "$AWS_ACCESS_KEY"
    set_secret "$repo" "AWS_SECRET_ACCESS_KEY" "$AWS_SECRET_KEY"
    set_secret "$repo" "AWS_REGION" "$REGION"
    echo ""
  done
fi

echo ""
echo "================================================"
echo "API Server Secrets"
echo "================================================"
echo ""
echo "gli_api-server 리포지토리에 다음 Secrets를 설정해야 합니다:"
echo "  - STG_ECR_REPOSITORY: gli-api-staging"
echo "  - PROD_ECR_REPOSITORY: gli-api-production"
echo "  - DB_SECRET_NAME_STAGING: gli/db/staging"
echo "  - DB_SECRET_NAME_PRODUCTION: gli/db/production"
echo ""

read -p "API Server Secrets를 설정하시겠습니까? (yes/no): " -r
if [[ $REPLY == "yes" ]]; then
  REPO="gli_api-server"
  set_secret "$REPO" "STG_ECR_REPOSITORY" "gli-api-staging"
  set_secret "$REPO" "PROD_ECR_REPOSITORY" "gli-api-production"
  set_secret "$REPO" "DB_SECRET_NAME_STAGING" "gli/db/staging"
  set_secret "$REPO" "DB_SECRET_NAME_PRODUCTION" "gli/db/production"
fi

echo ""
echo "================================================"
echo "WebSocket Server Secrets"
echo "================================================"
echo ""
echo "gli_websocket 리포지토리에 다음 Secrets를 설정해야 합니다:"
echo "  - STG_ECR_REPOSITORY: gli-websocket-staging"
echo "  - PROD_ECR_REPOSITORY: gli-websocket-production"
echo ""

read -p "WebSocket Secrets를 설정하시겠습니까? (yes/no): " -r
if [[ $REPLY == "yes" ]]; then
  REPO="gli_websocket"
  set_secret "$REPO" "STG_ECR_REPOSITORY" "gli-websocket-staging"
  set_secret "$REPO" "PROD_ECR_REPOSITORY" "gli-websocket-production"
fi

echo ""
echo "================================================"
echo "Frontend Secrets"
echo "================================================"
echo ""
echo "⚠️  Frontend 리포지토리에는 다음 Secrets를 수동으로 설정해야 합니다:"
echo ""
echo "gli_user-frontend:"
echo "  - STG_S3_BUCKET: gli-user-frontend-staging"
echo "  - PROD_S3_BUCKET: gli-user-frontend-production"
echo "  - STG_CLOUDFRONT_DISTRIBUTION_ID: (CloudFront 생성 후)"
echo "  - PROD_CLOUDFRONT_DISTRIBUTION_ID: (CloudFront 생성 후)"
echo ""
echo "gli_admin-frontend:"
echo "  - STG_S3_BUCKET: gli-admin-frontend-staging"
echo "  - PROD_S3_BUCKET: gli-admin-frontend-production"
echo "  - STG_CLOUDFRONT_DISTRIBUTION_ID: (CloudFront 생성 후)"
echo "  - PROD_CLOUDFRONT_DISTRIBUTION_ID: (CloudFront 생성 후)"
echo ""

read -p "Frontend S3 Bucket Secrets를 설정하시겠습니까? (yes/no): " -r
if [[ $REPLY == "yes" ]]; then
  # User Frontend
  REPO="gli_user-frontend"
  set_secret "$REPO" "STG_S3_BUCKET" "gli-user-frontend-staging"
  set_secret "$REPO" "PROD_S3_BUCKET" "gli-user-frontend-production"

  echo ""
  echo "CloudFront Distribution ID를 입력하세요 (나중에 설정하려면 Enter):"
  read -p "  Staging Distribution ID: " STG_CF_ID
  read -p "  Production Distribution ID: " PROD_CF_ID

  if [ -n "$STG_CF_ID" ]; then
    set_secret "$REPO" "STG_CLOUDFRONT_DISTRIBUTION_ID" "$STG_CF_ID"
  fi

  if [ -n "$PROD_CF_ID" ]; then
    set_secret "$REPO" "PROD_CLOUDFRONT_DISTRIBUTION_ID" "$PROD_CF_ID"
  fi

  echo ""

  # Admin Frontend
  REPO="gli_admin-frontend"
  set_secret "$REPO" "STG_S3_BUCKET" "gli-admin-frontend-staging"
  set_secret "$REPO" "PROD_S3_BUCKET" "gli-admin-frontend-production"

  echo ""
  echo "CloudFront Distribution ID를 입력하세요 (나중에 설정하려면 Enter):"
  read -p "  Staging Distribution ID: " STG_CF_ID
  read -p "  Production Distribution ID: " PROD_CF_ID

  if [ -n "$STG_CF_ID" ]; then
    set_secret "$REPO" "STG_CLOUDFRONT_DISTRIBUTION_ID" "$STG_CF_ID"
  fi

  if [ -n "$PROD_CF_ID" ]; then
    set_secret "$REPO" "PROD_CLOUDFRONT_DISTRIBUTION_ID" "$PROD_CF_ID"
  fi
fi

echo ""
echo "================================================"
echo "Summary"
echo "================================================"
echo "✅ GitHub Secrets 설정 도움말 완료!"
echo ""
echo "⚠️  확인사항:"
echo "  1. 각 리포지토리의 Settings > Secrets and variables > Actions에서 설정 확인"
echo "  2. CloudFront Distribution ID는 CloudFront 생성 후 추가 설정 필요"
echo "  3. 환경별 변수는 SECRETS_MANAGEMENT.md 문서 참고"
echo ""
echo "다음 단계:"
echo "  1. CloudFront Distributions 생성"
echo "  2. Frontend 리포지토리에 CloudFront Distribution ID 추가"
echo "  3. 첫 배포 테스트 (./multigit-merge-dev-to-stg.sh)"
echo ""
echo "================================================"
