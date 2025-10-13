# GLI Platform 배포 가이드

## 📋 목차
1. [사전 준비](#사전-준비)
2. [GitHub Secrets 설정](#github-secrets-설정)
3. [첫 배포 실행](#첫-배포-실행)
4. [배포 확인](#배포-확인)
5. [트러블슈팅](#트러블슈팅)

## 🎯 사전 준비

### 완료된 AWS 인프라

다음 리소스들이 이미 생성되어 있습니다:

#### ✅ ECR Repositories
- `gli-api-staging` (917891822317.dkr.ecr.ap-northeast-2.amazonaws.com/gli-api-staging)
- `gli-api-production` (917891822317.dkr.ecr.ap-northeast-2.amazonaws.com/gli-api-production)
- `gli-websocket-staging` (917891822317.dkr.ecr.ap-northeast-2.amazonaws.com/gli-websocket-staging)
- `gli-websocket-production` (917891822317.dkr.ecr.ap-northeast-2.amazonaws.com/gli-websocket-production)

#### ✅ ECS Clusters
- `staging-gli-cluster`
- `production-gli-cluster`

#### ✅ S3 Buckets
- `gli-user-frontend-staging`
- `gli-user-frontend-production`
- `gli-admin-frontend-staging`
- `gli-admin-frontend-production`

#### ✅ CloudWatch Log Groups
- `/ecs/staging-gli-api`
- `/ecs/staging-gli-websocket`
- `/ecs/production-gli-api`
- `/ecs/production-gli-websocket`

#### ✅ AWS Secrets Manager
- `gli/db/staging` - Staging 데이터베이스 정보
- `gli/db/production` - Production 데이터베이스 정보

### 필요한 도구

```bash
# gh CLI 설치 (GitHub Secrets 설정용)
brew install gh

# gh CLI 로그인
gh auth login
```

## 🔐 GitHub Secrets 설정

### 1. 자동 설정 (권장)

```bash
# setup-github-secrets.sh 실행
./setup-github-secrets.sh
```

스크립트가 대화형으로 다음을 설정합니다:
- AWS 자격 증명 (모든 리포지토리)
- ECR 리포지토리 이름
- S3 버킷 이름

### 2. 수동 설정

각 리포지토리의 `Settings > Secrets and variables > Actions`에서 설정:

#### gli_api-server
```
AWS_ACCESS_KEY_ID: <AWS Access Key>
AWS_SECRET_ACCESS_KEY: <AWS Secret Key>
AWS_REGION: ap-northeast-2
STG_ECR_REPOSITORY: gli-api-staging
PROD_ECR_REPOSITORY: gli-api-production
DB_SECRET_NAME_STAGING: gli/db/staging
DB_SECRET_NAME_PRODUCTION: gli/db/production
```

#### gli_websocket
```
AWS_ACCESS_KEY_ID: <AWS Access Key>
AWS_SECRET_ACCESS_KEY: <AWS Secret Key>
AWS_REGION: ap-northeast-2
STG_ECR_REPOSITORY: gli-websocket-staging
PROD_ECR_REPOSITORY: gli-websocket-production
```

#### gli_user-frontend
```
AWS_ACCESS_KEY_ID: <AWS Access Key>
AWS_SECRET_ACCESS_KEY: <AWS Secret Key>
AWS_REGION: ap-northeast-2
STG_S3_BUCKET: gli-user-frontend-staging
PROD_S3_BUCKET: gli-user-frontend-production
STG_CLOUDFRONT_DISTRIBUTION_ID: <나중에 설정>
PROD_CLOUDFRONT_DISTRIBUTION_ID: <나중에 설정>
```

#### gli_admin-frontend
```
AWS_ACCESS_KEY_ID: <AWS Access Key>
AWS_SECRET_ACCESS_KEY: <AWS Secret Key>
AWS_REGION: ap-northeast-2
STG_S3_BUCKET: gli-admin-frontend-staging
PROD_S3_BUCKET: gli-admin-frontend-production
STG_CLOUDFRONT_DISTRIBUTION_ID: <나중에 설정>
PROD_CLOUDFRONT_DISTRIBUTION_ID: <나중에 설정>
```

## 🚀 첫 배포 실행

### Step 1: 현재 브랜치 확인

```bash
# 모든 리포지토리 현재 브랜치 확인
for repo in . gli_admin-frontend gli_api-server gli_database gli_rabbitmq gli_redis gli_user-frontend gli_websocket; do
  echo "=== $repo ==="
  cd "$repo"
  git branch --show-current
  cd - > /dev/null
done
```

### Step 2: dev 브랜치 최신화

```bash
# dev 브랜치로 이동하고 최신화
./multigit-pull-dev.sh
```

### Step 3: Staging 배포

```bash
# dev → stg 머지 및 배포
./multigit-merge-dev-to-stg.sh
```

이 명령은 다음을 수행합니다:
1. 모든 리포지토리에서 dev → stg 머지
2. stg 브랜치를 원격에 푸시
3. GitHub Actions가 자동으로 트리거됨
4. ECS Task Definition 생성 및 등록
5. ECS 서비스 업데이트 (첫 배포 시 서비스 생성)
6. Frontend는 S3에 업로드

### Step 4: 배포 상태 확인

#### GitHub Actions 확인
각 리포지토리의 `Actions` 탭에서 워크플로우 실행 확인:
- `gli_api-server` → "Deploy API Server to Staging"
- `gli_websocket` → "Deploy WebSocket Server to Staging"
- `gli_user-frontend` → "Deploy User Frontend to Staging"
- `gli_admin-frontend` → "Deploy Admin Frontend to Staging"

#### ECS 서비스 확인
```bash
# ECS 서비스 상태 확인
aws ecs list-services --cluster staging-gli-cluster --region ap-northeast-2

# 특정 서비스 상세 확인
aws ecs describe-services \
  --cluster staging-gli-cluster \
  --services staging-api-service \
  --region ap-northeast-2
```

#### S3 확인
```bash
# Frontend 파일 업로드 확인
aws s3 ls s3://gli-user-frontend-staging/
aws s3 ls s3://gli-admin-frontend-staging/
```

## 🔍 배포 확인

### API Server 확인

```bash
# ECS Task 로그 확인
aws logs tail /ecs/staging-gli-api --follow --region ap-northeast-2

# API Health Check (ECS Task의 Public IP 필요)
# Task의 Public IP 확인
aws ecs list-tasks --cluster staging-gli-cluster --region ap-northeast-2
aws ecs describe-tasks \
  --cluster staging-gli-cluster \
  --tasks <task-arn> \
  --region ap-northeast-2
```

### WebSocket Server 확인

```bash
# WebSocket 로그 확인
aws logs tail /ecs/staging-gli-websocket --follow --region ap-northeast-2
```

### Frontend 확인

```bash
# S3 Static Website Endpoint
aws s3api get-bucket-website \
  --bucket gli-user-frontend-staging \
  --region ap-northeast-2

# 브라우저에서 접속 (임시)
# http://gli-user-frontend-staging.s3-website.ap-northeast-2.amazonaws.com
```

## 🔄 Production 배포

### Step 1: Staging 검증 완료

Staging 환경에서 충분한 테스트를 수행한 후:
- 기능 동작 확인
- 에러 로그 확인
- 성능 테스트

### Step 2: Production 배포 실행

```bash
# stg → main 머지 및 배포
./multigit-merge-stg-to-main.sh
```

⚠️ **주의사항**:
- 이 명령은 이중 확인 (yes + DEPLOY)을 요구합니다
- 프로덕션 배포는 신중하게 진행하세요
- 배포 태그가 자동으로 생성됩니다 (deploy-YYYYMMDD-HHMMSS)

### Step 3: Production 배포 확인

```bash
# Production ECS 서비스 확인
aws ecs list-services --cluster production-gli-cluster --region ap-northeast-2

# Production 로그 확인
aws logs tail /ecs/production-gli-api --follow --region ap-northeast-2
aws logs tail /ecs/production-gli-websocket --follow --region ap-northeast-2
```

## 🐛 트러블슈팅

### 1. GitHub Actions 실패

#### ECR 로그인 실패
```bash
# AWS 자격 증명 확인
aws sts get-caller-identity

# GitHub Secrets 재설정
./setup-github-secrets.sh
```

#### Docker 빌드 실패
- Dockerfile 문법 확인
- 빌드 로그에서 에러 메시지 확인
- 로컬에서 Docker 빌드 테스트

#### ECS 배포 실패
```bash
# ECS 서비스 이벤트 확인
aws ecs describe-services \
  --cluster staging-gli-cluster \
  --services staging-api-service \
  --region ap-northeast-2 \
  --query 'services[0].events[0:10]'

# Task Definition 확인
aws ecs describe-task-definition \
  --task-definition staging-gli-api \
  --region ap-northeast-2
```

### 2. ECS 서비스가 생성되지 않음

첫 배포 시 ECS 서비스가 자동으로 생성되지 않았다면 수동으로 생성:

```bash
# setup-ecs-services.sh 실행하여 명령어 확인
./setup-ecs-services.sh

# 또는 직접 생성
aws ecs create-service \
  --region ap-northeast-2 \
  --cluster staging-gli-cluster \
  --service-name staging-api-service \
  --task-definition staging-gli-api:1 \
  --desired-count 1 \
  --launch-type FARGATE \
  --network-configuration "awsvpcConfiguration={subnets=[subnet-xxx],securityGroups=[sg-xxx],assignPublicIp=ENABLED}"
```

### 3. Frontend 접속 불가

#### S3 업로드 확인
```bash
# 파일 업로드 확인
aws s3 ls s3://gli-user-frontend-staging/ --recursive

# index.html 존재 확인
aws s3 ls s3://gli-user-frontend-staging/index.html
```

#### 버킷 정책 확인
```bash
# 버킷 정책 조회
aws s3api get-bucket-policy --bucket gli-user-frontend-staging --region ap-northeast-2

# 정책이 없다면 추가 (Public Read 허용)
aws s3api put-bucket-policy --bucket gli-user-frontend-staging --policy '{
  "Version": "2012-10-17",
  "Statement": [{
    "Sid": "PublicReadGetObject",
    "Effect": "Allow",
    "Principal": "*",
    "Action": "s3:GetObject",
    "Resource": "arn:aws:s3:::gli-user-frontend-staging/*"
  }]
}'
```

### 4. Database 연결 실패

```bash
# Secrets Manager에서 DB 정보 확인
aws secretsmanager get-secret-value \
  --secret-id gli/db/staging \
  --region ap-northeast-2 \
  --query SecretString \
  --output text | jq .

# DB 보안 그룹 확인 - ECS Task의 Security Group이 허용되어 있는지 확인
```

### 5. 로그 확인

```bash
# 최근 로그 확인 (실시간)
aws logs tail /ecs/staging-gli-api --follow --region ap-northeast-2

# 특정 시간대 로그 조회
aws logs tail /ecs/staging-gli-api \
  --since 1h \
  --format short \
  --region ap-northeast-2
```

## 📚 추가 리소스

- [BRANCHING.md](./BRANCHING.md) - 브랜치 전략 및 워크플로우
- [MULTIGIT_SCRIPTS.md](./MULTIGIT_SCRIPTS.md) - MultiGit 스크립트 가이드
- [SECRETS_MANAGEMENT.md](./SECRETS_MANAGEMENT.md) - Secrets 관리 가이드
- [gli_api-server/README.md](./gli_api-server/README.md) - API Server 배포 가이드
- [gli_websocket/README.md](./gli_websocket/README.md) - WebSocket Server 배포 가이드

## 🔄 일반적인 워크플로우

### 일상적인 개발 → 배포

```bash
# 1. 개발 작업 (각 리포지토리에서)
cd gli_api-server
git checkout dev
# ... 개발 ...
git commit -m "feat: add new feature"
git push origin dev

# 2. 스테이징 배포
cd ..
./multigit-merge-dev-to-stg.sh

# 3. 스테이징 검증
# - https://stg-api.glibiz.com 테스트
# - https://stg.glibiz.com 테스트

# 4. 프로덕션 배포
./multigit-merge-stg-to-main.sh
```

### 긴급 핫픽스

```bash
# 1. main에서 hotfix 브랜치 생성
cd gli_api-server
git checkout main
git checkout -b hotfix/critical-bug
# ... 수정 ...
git commit -m "hotfix: fix critical bug"

# 2. main으로 PR 생성 및 머지 (GitHub)

# 3. 핫픽스를 스테이징에 반영
cd ..
./multigit-merge-main-to-stg.sh

# 4. 핫픽스를 dev에도 반영
./multigit-merge-stg-to-dev.sh
```

---

**문서 버전**: 1.0
**최종 업데이트**: 2025-10-13
**관리**: DevOps Team
