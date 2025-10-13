#!/bin/bash

# GLI Project - GitHub Secrets Setup Script
# 모든 GitHub Secrets를 체계적으로 설정합니다.

set -e

echo "================================================"
echo "GLI GitHub Secrets 설정"
echo "================================================"
echo ""
echo "이 스크립트는 다음 리포지토리에 Secrets를 설정합니다:"
echo "  1. gli_api-server"
echo "  2. gli_websocket"
echo "  3. gli_user-frontend"
echo "  4. gli_admin-frontend"
echo ""
echo "⚠️  주의사항:"
echo "  - GitHub CLI (gh)가 인증되어 있어야 합니다"
echo "  - AWS 자격 증명이 필요합니다"
echo "  - .secrets/ 디렉토리에 생성된 키가 있어야 합니다"
echo ""

# Check if gh CLI is available and authenticated
if ! command -v gh &> /dev/null; then
  echo "❌ GitHub CLI (gh)가 설치되어 있지 않습니다"
  echo "   설치: brew install gh"
  exit 1
fi

if ! gh auth status &> /dev/null; then
  echo "❌ GitHub CLI가 인증되어 있지 않습니다"
  echo "   실행: gh auth login"
  exit 1
fi

# Check if secrets directory exists
if [ ! -d ".secrets" ]; then
  echo "❌ .secrets 디렉토리가 없습니다"
  echo "   먼저 ./generate-secrets.sh를 실행하세요"
  exit 1
fi

echo "✅ GitHub CLI 인증 확인 완료"
echo ""

# Prompt for AWS credentials (or use environment variables)
echo "================================================"
echo "AWS 자격 증명 확인"
echo "================================================"
echo ""

if [ -z "$AWS_ACCESS_KEY_ID" ]; then
  AWS_ACCESS_KEY_ID=$(aws configure get aws_access_key_id 2>/dev/null)
fi

if [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
  AWS_SECRET_ACCESS_KEY=$(aws configure get aws_secret_access_key 2>/dev/null)
fi

if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
  echo "⚠️  환경변수나 AWS 설정에서 자격 증명을 찾을 수 없습니다."
  echo ""
  read -p "AWS_ACCESS_KEY_ID: " AWS_ACCESS_KEY_ID
  read -sp "AWS_SECRET_ACCESS_KEY: " AWS_SECRET_ACCESS_KEY
  echo ""
  echo ""
fi

if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ]; then
  echo "❌ AWS 자격 증명이 입력되지 않았습니다"
  exit 1
fi

echo "✅ AWS 자격 증명 확인 완료"
echo ""

# Read generated secrets
DJANGO_SECRET_STAGING=$(cat .secrets/django_secret_staging.txt)
DJANGO_SECRET_PRODUCTION=$(cat .secrets/django_secret_production.txt)
JWT_PRIVATE_STAGING=$(cat .secrets/jwt_private_staging.pem)
JWT_PUBLIC_STAGING=$(cat .secrets/jwt_public_staging.pem)
JWT_PRIVATE_PRODUCTION=$(cat .secrets/jwt_private_production.pem)
JWT_PUBLIC_PRODUCTION=$(cat .secrets/jwt_public_production.pem)

AWS_REGION="ap-northeast-2"

echo "================================================"
echo "1. gli_api-server Secrets 설정"
echo "================================================"
echo ""

REPO="dreamfurnace/gli_api-server"

# Common AWS credentials
gh secret set AWS_ACCESS_KEY_ID -b"$AWS_ACCESS_KEY_ID" -R "$REPO"
echo "✅ AWS_ACCESS_KEY_ID 설정 완료"

gh secret set AWS_SECRET_ACCESS_KEY -b"$AWS_SECRET_ACCESS_KEY" -R "$REPO"
echo "✅ AWS_SECRET_ACCESS_KEY 설정 완료"

gh secret set AWS_REGION -b"$AWS_REGION" -R "$REPO"
echo "✅ AWS_REGION 설정 완료"

# ECR Repositories
gh secret set STG_ECR_REPOSITORY -b"gli-api-staging" -R "$REPO"
echo "✅ STG_ECR_REPOSITORY 설정 완료"

gh secret set PROD_ECR_REPOSITORY -b"gli-api-production" -R "$REPO"
echo "✅ PROD_ECR_REPOSITORY 설정 완료"

# Secrets Manager
gh secret set DB_SECRET_NAME_STAGING -b"gli/db/staging" -R "$REPO"
echo "✅ DB_SECRET_NAME_STAGING 설정 완료"

gh secret set DB_SECRET_NAME_PRODUCTION -b"gli/db/production" -R "$REPO"
echo "✅ DB_SECRET_NAME_PRODUCTION 설정 완료"

# Django Staging
gh secret set SECRET_KEY_STAGING -b"$DJANGO_SECRET_STAGING" -R "$REPO"
echo "✅ SECRET_KEY_STAGING 설정 완료"

gh secret set JWT_PRIVATE_KEY_STAGING -b"$JWT_PRIVATE_STAGING" -R "$REPO"
echo "✅ JWT_PRIVATE_KEY_STAGING 설정 완료"

gh secret set JWT_PUBLIC_KEY_STAGING -b"$JWT_PUBLIC_STAGING" -R "$REPO"
echo "✅ JWT_PUBLIC_KEY_STAGING 설정 완료"

gh secret set CORS_ALLOWED_ORIGINS_STAGING -b"https://stg.glibiz.com,https://stg-admin.glibiz.com" -R "$REPO"
echo "✅ CORS_ALLOWED_ORIGINS_STAGING 설정 완료"

gh secret set FRONTEND_BASE_URL_STAGING -b"https://stg.glibiz.com" -R "$REPO"
echo "✅ FRONTEND_BASE_URL_STAGING 설정 완료"

gh secret set AWS_STORAGE_BUCKET_NAME_STAGING -b"gli-platform-media-dev" -R "$REPO"
echo "✅ AWS_STORAGE_BUCKET_NAME_STAGING 설정 완료"

# Django Production
gh secret set SECRET_KEY_PRODUCTION -b"$DJANGO_SECRET_PRODUCTION" -R "$REPO"
echo "✅ SECRET_KEY_PRODUCTION 설정 완료"

gh secret set JWT_PRIVATE_KEY_PRODUCTION -b"$JWT_PRIVATE_PRODUCTION" -R "$REPO"
echo "✅ JWT_PRIVATE_KEY_PRODUCTION 설정 완료"

gh secret set JWT_PUBLIC_KEY_PRODUCTION -b"$JWT_PUBLIC_PRODUCTION" -R "$REPO"
echo "✅ JWT_PUBLIC_KEY_PRODUCTION 설정 완료"

gh secret set CORS_ALLOWED_ORIGINS_PRODUCTION -b"https://glibiz.com,https://www.glibiz.com,https://admin.glibiz.com" -R "$REPO"
echo "✅ CORS_ALLOWED_ORIGINS_PRODUCTION 설정 완료"

gh secret set FRONTEND_BASE_URL_PRODUCTION -b"https://glibiz.com" -R "$REPO"
echo "✅ FRONTEND_BASE_URL_PRODUCTION 설정 완료"

gh secret set AWS_STORAGE_BUCKET_NAME_PRODUCTION -b"gli-platform-media-prod" -R "$REPO"
echo "✅ AWS_STORAGE_BUCKET_NAME_PRODUCTION 설정 완료"

echo ""
echo "================================================"
echo "2. gli_websocket Secrets 설정"
echo "================================================"
echo ""

REPO="dreamfurnace/gli_websocket"

gh secret set AWS_ACCESS_KEY_ID -b"$AWS_ACCESS_KEY_ID" -R "$REPO"
echo "✅ AWS_ACCESS_KEY_ID 설정 완료"

gh secret set AWS_SECRET_ACCESS_KEY -b"$AWS_SECRET_ACCESS_KEY" -R "$REPO"
echo "✅ AWS_SECRET_ACCESS_KEY 설정 완료"

gh secret set AWS_REGION -b"$AWS_REGION" -R "$REPO"
echo "✅ AWS_REGION 설정 완료"

gh secret set STG_ECR_REPOSITORY -b"gli-websocket-staging" -R "$REPO"
echo "✅ STG_ECR_REPOSITORY 설정 완료"

gh secret set PROD_ECR_REPOSITORY -b"gli-websocket-production" -R "$REPO"
echo "✅ PROD_ECR_REPOSITORY 설정 완료"

echo ""
echo "================================================"
echo "3. gli_user-frontend Secrets 설정"
echo "================================================"
echo ""

REPO="dreamfurnace/gli_user-frontend"

gh secret set AWS_ACCESS_KEY_ID -b"$AWS_ACCESS_KEY_ID" -R "$REPO"
echo "✅ AWS_ACCESS_KEY_ID 설정 완료"

gh secret set AWS_SECRET_ACCESS_KEY -b"$AWS_SECRET_ACCESS_KEY" -R "$REPO"
echo "✅ AWS_SECRET_ACCESS_KEY 설정 완료"

gh secret set AWS_REGION -b"$AWS_REGION" -R "$REPO"
echo "✅ AWS_REGION 설정 완료"

gh secret set STG_S3_BUCKET -b"gli-user-frontend-staging" -R "$REPO"
echo "✅ STG_S3_BUCKET 설정 완료"

gh secret set PROD_S3_BUCKET -b"gli-user-frontend-production" -R "$REPO"
echo "✅ PROD_S3_BUCKET 설정 완료"

gh secret set STG_CLOUDFRONT_DISTRIBUTION_ID -b"E2M2F8O36YCDX" -R "$REPO"
echo "✅ STG_CLOUDFRONT_DISTRIBUTION_ID 설정 완료"

gh secret set PROD_CLOUDFRONT_DISTRIBUTION_ID -b"EUY0BEWJK212R" -R "$REPO"
echo "✅ PROD_CLOUDFRONT_DISTRIBUTION_ID 설정 완료"

echo ""
echo "================================================"
echo "4. gli_admin-frontend Secrets 설정"
echo "================================================"
echo ""

REPO="dreamfurnace/gli_admin-frontend"

gh secret set AWS_ACCESS_KEY_ID -b"$AWS_ACCESS_KEY_ID" -R "$REPO"
echo "✅ AWS_ACCESS_KEY_ID 설정 완료"

gh secret set AWS_SECRET_ACCESS_KEY -b"$AWS_SECRET_ACCESS_KEY" -R "$REPO"
echo "✅ AWS_SECRET_ACCESS_KEY 설정 완료"

gh secret set AWS_REGION -b"$AWS_REGION" -R "$REPO"
echo "✅ AWS_REGION 설정 완료"

gh secret set STG_S3_BUCKET -b"gli-admin-frontend-staging" -R "$REPO"
echo "✅ STG_S3_BUCKET 설정 완료"

gh secret set PROD_S3_BUCKET -b"gli-admin-frontend-production" -R "$REPO"
echo "✅ PROD_S3_BUCKET 설정 완료"

gh secret set STG_CLOUDFRONT_DISTRIBUTION_ID -b"E1UMP4GMPQCQ0G" -R "$REPO"
echo "✅ STG_CLOUDFRONT_DISTRIBUTION_ID 설정 완료"

gh secret set PROD_CLOUDFRONT_DISTRIBUTION_ID -b"E31LKUK6NABDLS" -R "$REPO"
echo "✅ PROD_CLOUDFRONT_DISTRIBUTION_ID 설정 완료"

echo ""
echo "================================================"
echo "Summary"
echo "================================================"
echo "✅ 모든 GitHub Secrets 설정 완료!"
echo ""
echo "설정된 리포지토리:"
echo "  - dreamfurnace/gli_api-server (18개 secrets)"
echo "  - dreamfurnace/gli_websocket (5개 secrets)"
echo "  - dreamfurnace/gli_user-frontend (7개 secrets)"
echo "  - dreamfurnace/gli_admin-frontend (7개 secrets)"
echo ""
echo "확인 방법:"
echo "  gh secret list -R dreamfurnace/gli_api-server"
echo "  gh secret list -R dreamfurnace/gli_websocket"
echo "  gh secret list -R dreamfurnace/gli_user-frontend"
echo "  gh secret list -R dreamfurnace/gli_admin-frontend"
echo ""
echo "다음 단계:"
echo "  1. 각 리포지토리의 Secrets 목록 확인"
echo "  2. 첫 배포 실행 (./multigit-push-stg.sh)"
echo "  3. GitHub Actions 워크플로우 실행 확인"
echo ""
echo "================================================"
