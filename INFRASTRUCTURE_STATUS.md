# GLI Platform 인프라 현황

**최종 업데이트**: 2025-10-13
**상태**: 배포 준비 완료

## 📋 도메인 구성

### 운영계 (Production)

#### Frontend
- `glibiz.com` → CloudFront → S3 (gli-user-frontend-production) ⏳
- `www.glibiz.com` → CloudFront → S3 (gli-user-frontend-production) ⏳
- `admin.glibiz.com` → CloudFront → S3 (gli-admin-frontend-production) ⏳

#### Backend
- `api.glibiz.com` → ALB (gli-production-alb) → ECS ✅
- `ws.glibiz.com` → ALB (gli-production-alb) → ECS ✅

### 스테이징계 (Staging)

#### Frontend
- `stg.glibiz.com` → CloudFront → S3 (gli-user-frontend-staging) ⏳
- `stg-admin.glibiz.com` → CloudFront → S3 (gli-admin-frontend-staging) ⏳

#### Backend
- `stg-api.glibiz.com` → ALB (gli-staging-alb) → ECS ✅
- `stg-ws.glibiz.com` → ALB (gli-staging-alb) → ECS ✅

**범례**:
- ✅ 생성 완료
- ⏳ CloudFront 생성 필요 (선택적)

---

## 🏗️ AWS 리소스 현황

### 1. Application Load Balancer (ALB)

#### Staging ALB
```
Name: gli-staging-alb
DNS: gli-staging-alb-461879350.ap-northeast-2.elb.amazonaws.com
ARN: arn:aws:elasticloadbalancing:ap-northeast-2:917891822317:loadbalancer/app/gli-staging-alb/4b919751696a2d9d

Listeners:
  - HTTP (80): Redirect to HTTPS
  - HTTPS (443): Host-based routing
    ├─ stg-api.glibiz.com → gli-stg-api-tg
    └─ stg-ws.glibiz.com → gli-stg-ws-tg

Security Group: sg-08d5c4c04594e5477
```

#### Production ALB
```
Name: gli-production-alb
DNS: gli-production-alb-1195676678.ap-northeast-2.elb.amazonaws.com
ARN: arn:aws:elasticloadbalancing:ap-northeast-2:917891822317:loadbalancer/app/gli-production-alb/4dd48a414b137281

Listeners:
  - HTTP (80): Redirect to HTTPS
  - HTTPS (443): Host-based routing
    ├─ api.glibiz.com → gli-prod-api-tg
    └─ ws.glibiz.com → gli-prod-ws-tg

Security Group: sg-08d5c4c04594e5477 (공유)
```

### 2. Target Groups

| Name | ARN | Port | Health Check |
|------|-----|------|--------------|
| gli-stg-api-tg | arn:aws:...targetgroup/gli-stg-api-tg/5f0499ae426668ca | 8000 | /health/ |
| gli-stg-ws-tg | arn:aws:...targetgroup/gli-stg-ws-tg/586551f254635e4a | 8080 | /health |
| gli-prod-api-tg | arn:aws:...targetgroup/gli-prod-api-tg/650e7e1476633a2f | 8000 | /health/ |
| gli-prod-ws-tg | arn:aws:...targetgroup/gli-prod-ws-tg/6619e0227a562cbc | 8080 | /health |

### 3. ECS Clusters

#### Staging
```
Cluster: staging-gli-cluster
ARN: arn:aws:ecs:ap-northeast-2:917891822317:cluster/staging-gli-cluster

Services (생성 예정):
  - staging-django-api-service (Task Definition: staging-gli-django-api)
  - staging-websocket-service (Task Definition: staging-gli-websocket)
```

#### Production
```
Cluster: production-gli-cluster
ARN: arn:aws:ecs:ap-northeast-2:917891822317:cluster/production-gli-cluster

Services (생성 예정):
  - production-django-api-service (Task Definition: production-gli-django-api)
  - production-websocket-service (Task Definition: production-gli-websocket)
```

### 4. ECR Repositories

| Repository | URI |
|------------|-----|
| gli-api-staging | 917891822317.dkr.ecr.ap-northeast-2.amazonaws.com/gli-api-staging |
| gli-api-production | 917891822317.dkr.ecr.ap-northeast-2.amazonaws.com/gli-api-production |
| gli-websocket-staging | 917891822317.dkr.ecr.ap-northeast-2.amazonaws.com/gli-websocket-staging |
| gli-websocket-production | 917891822317.dkr.ecr.ap-northeast-2.amazonaws.com/gli-websocket-production |

### 5. S3 Buckets (Frontend Hosting)

| Bucket | Purpose | Website Endpoint |
|--------|---------|------------------|
| gli-user-frontend-staging | Staging 유저 프론트엔드 | Enabled |
| gli-user-frontend-production | Production 유저 프론트엔드 | Enabled |
| gli-admin-frontend-staging | Staging 관리자 대시보드 | Enabled |
| gli-admin-frontend-production | Production 관리자 대시보드 | Enabled |

### 6. CloudWatch Log Groups

- `/ecs/staging-gli-api` (보존 기간: 30일)
- `/ecs/staging-gli-websocket` (보존 기간: 30일)
- `/ecs/production-gli-api` (보존 기간: 30일)
- `/ecs/production-gli-websocket` (보존 기간: 30일)

### 7. ACM Certificates

#### CloudFront용 (us-east-1)
```
ARN: arn:aws:acm:us-east-1:917891822317:certificate/8a143395-150a-40cf-b9e7-aacbbd3d2caf
Domain: *.glibiz.com, glibiz.com
Status: ISSUED
Valid Until: 2026-11-12
```

#### ALB용 (ap-northeast-2)
```
ARN: arn:aws:acm:ap-northeast-2:917891822317:certificate/8590e8e6-1e73-4754-983f-b77ed18e3a82
Domain: *.glibiz.com, glibiz.com
Status: ISSUED
Valid Until: 2026-11-12
```

### 8. Route53 (glibiz.com)

#### 현재 레코드
```
Hosted Zone ID: Z0419507IHNIDPFGXUPL

레코드:
  - glibiz.com (NS)
  - glibiz.com (SOA)
  - stg-api.glibiz.com (A - ALIAS to Staging ALB) ✅
  - stg-ws.glibiz.com (A - ALIAS to Staging ALB) ✅
  - api.glibiz.com (A - ALIAS to Production ALB) ✅
  - ws.glibiz.com (A - ALIAS to Production ALB) ✅
```

#### 필요한 레코드 (CloudFront 생성 후)
```
  - glibiz.com (A - ALIAS to CloudFront)
  - www.glibiz.com (A - ALIAS to CloudFront)
  - admin.glibiz.com (A - ALIAS to CloudFront)
  - stg.glibiz.com (A - ALIAS to CloudFront)
  - stg-admin.glibiz.com (A - ALIAS to CloudFront)
```

### 9. AWS Secrets Manager

| Secret Name | Description |
|-------------|-------------|
| gli/db/staging | Staging 데이터베이스 자격 증명 (host, dbname, username, password, port) |
| gli/db/production | Production 데이터베이스 자격 증명 (host, dbname, username, password, port) |

### 10. Security Groups

#### gli-alb-sg
```
ID: sg-08d5c4c04594e5477
Purpose: ALB 보안 그룹
Inbound:
  - 80 (HTTP) from 0.0.0.0/0
  - 443 (HTTPS) from 0.0.0.0/0
```

#### gli-ecs-tasks-sg (생성 예정)
```
Purpose: ECS Tasks 보안 그룹
Inbound:
  - 8000 from ALB Security Group
  - 8080 from ALB Security Group
```

---

## 📊 배포 아키텍처

### Backend (Django API + WebSocket)

```
Internet
    ↓
Route53 (stg-api.glibiz.com, api.glibiz.com)
    ↓
Application Load Balancer (ALB)
    ├─ HTTPS Listener (443)
    │   ├─ Host: stg-api.glibiz.com → Target Group (gli-stg-api-tg)
    │   └─ Host: api.glibiz.com → Target Group (gli-prod-api-tg)
    ↓
ECS Fargate Tasks (Django API - Port 8000)
    ↓
RDS PostgreSQL (Secrets Manager에서 자격 증명 로드)
```

### Frontend (Vue.js)

```
Internet
    ↓
Route53 (stg.glibiz.com, glibiz.com)
    ↓
CloudFront Distribution (CDN) [생성 필요]
    ↓
S3 Bucket (Static Website Hosting)
    - gli-user-frontend-staging
    - gli-user-frontend-production
```

---

## 🚀 배포 프로세스

### 1. 첫 배포 준비

#### Step 1: GitHub Secrets 설정
```bash
./setup-github-secrets.sh
```

필요한 Secrets (각 리포지토리):
- AWS_ACCESS_KEY_ID
- AWS_SECRET_ACCESS_KEY
- AWS_REGION
- STG_ECR_REPOSITORY / PROD_ECR_REPOSITORY
- STG_S3_BUCKET / PROD_S3_BUCKET
- DB_SECRET_NAME_STAGING / DB_SECRET_NAME_PRODUCTION
- (기타 환경 변수)

#### Step 2: ECS Security Group 생성
```bash
# create-ecs-services.sh 스크립트가 자동으로 생성
```

#### Step 3: 첫 배포 실행
```bash
# Staging 배포
./multigit-merge-dev-to-stg.sh
```

이 명령은 다음을 수행합니다:
1. dev → stg 머지
2. GitHub Actions 워크플로우 트리거
3. Docker 이미지 빌드 및 ECR 푸시
4. ECS Task Definition 생성
5. Django 마이그레이션 실행
6. ECS 서비스 업데이트 (또는 생성)
7. ALB Target Group에 자동 등록

### 2. 배포 확인

#### Backend 확인
```bash
# ALB 헬스 체크 확인
aws elbv2 describe-target-health \
  --target-group-arn <TARGET_GROUP_ARN> \
  --region ap-northeast-2

# ECS 서비스 상태 확인
aws ecs describe-services \
  --cluster staging-gli-cluster \
  --services staging-django-api-service \
  --region ap-northeast-2

# 로그 확인
aws logs tail /ecs/staging-gli-api --follow --region ap-northeast-2

# API 테스트
curl https://stg-api.glibiz.com/health/
```

#### Frontend 확인
```bash
# S3 파일 업로드 확인
aws s3 ls s3://gli-user-frontend-staging/ --recursive

# Static Website 접속 (CloudFront 전)
# http://gli-user-frontend-staging.s3-website.ap-northeast-2.amazonaws.com
```

### 3. Production 배포

```bash
# Production 배포 (신중하게!)
./multigit-merge-stg-to-main.sh
```

---

## ⚠️ 중요 사항

### 배포 순서
1. ✅ AWS 인프라 생성 (ECR, ECS, ALB, S3) - **완료**
2. ✅ Route53 Backend 레코드 추가 - **완료**
3. ⏳ GitHub Secrets 설정 - **필요**
4. ⏳ 첫 배포 실행 (Task Definition 생성) - **대기 중**
5. ⏳ ECS 서비스 생성 (자동 또는 수동) - **대기 중**
6. 🔜 CloudFront 생성 (선택적)
7. 🔜 Route53 Frontend 레코드 추가

### 배포 흐름
```
개발 (dev) → 스테이징 (stg) → 프로덕션 (main)
    ↓              ↓                ↓
  로컬 테스트    stg.glibiz.com   glibiz.com
```

### 주의사항
- ⚠️ Production 배포는 스테이징 검증 후에만 수행
- ⚠️ ECS 서비스는 Task Definition이 있어야 시작됨
- ⚠️ 첫 배포 시 마이그레이션이 실행되므로 DB 연결 확인 필요
- ⚠️ ALB Security Group과 ECS Task Security Group 연결 필수

---

## 📖 관련 문서

- [DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md) - 배포 가이드
- [BRANCHING.md](./BRANCHING.md) - 브랜치 전략
- [MULTIGIT_SCRIPTS.md](./MULTIGIT_SCRIPTS.md) - MultiGit 스크립트
- [SECRETS_MANAGEMENT.md](./SECRETS_MANAGEMENT.md) - Secrets 관리

## 📞 유용한 명령어

```bash
# ALB 상태 확인
aws elbv2 describe-load-balancers --region ap-northeast-2 --query 'LoadBalancers[?contains(LoadBalancerName, `gli`)]'

# Target Group 헬스 확인
aws elbv2 describe-target-health --target-group-arn <ARN> --region ap-northeast-2

# ECS 서비스 목록
aws ecs list-services --cluster staging-gli-cluster --region ap-northeast-2

# Route53 레코드 확인
aws route53 list-resource-record-sets --hosted-zone-id Z0419507IHNIDPFGXUPL

# 로그 스트림
aws logs tail /ecs/staging-gli-api --follow --region ap-northeast-2
```

---

**마지막 업데이트**: 2025-10-13 19:00 KST
**작성자**: DevOps Team
