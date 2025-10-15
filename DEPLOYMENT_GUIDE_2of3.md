# GLI 프로젝트 배포 가이드 (Part 2 of 3)

> **문서 분할 안내**: 이 문서는 총 3개 파일로 구성되어 있습니다.
> - **Part 1**: 배포 시스템 개요, 환경 구성, 브랜치 전략, 사전 준비
> - **[현재] Part 2**: AWS 인프라, Secrets 및 환경 변수 관리
> - **Part 3**: 배포 프로세스, GitHub Actions, 모니터링, 트러블슈팅

---

## 📑 전체 목차

### Part 1
1. **배포 시스템 개요**
2. **환경 구성**
3. **브랜치 전략**
4. **사전 준비**

### Part 2 (현재 문서)
5. **AWS 인프라**
6. **Secrets 및 환경 변수 관리**

### Part 3
7. **배포 프로세스**
8. **GitHub Actions 워크플로우**
9. **모니터링 및 롤백**
10. **트러블슈팅**
11. **체크리스트**
12. **부록**

---

## 5. AWS 인프라

### 5.1 인프라 구성도

```
                        [Route 53]
                            |
                  ┌─────────┴─────────┐
                  |                   |
            [CloudFront]          [ALB]
                  |                   |
            [S3 (정적)]         [ECS Fargate]
                                      |
                        ┌─────────────┼─────────────┐
                        |             |             |
                  [User Frontend] [Admin]      [API Server]
                        |             |             |
                        └─────────────┴─────────────┘
                                      |
                        ┌─────────────┼─────────────┐
                        |             |             |
                   [RDS PostgreSQL] [ElastiCache Redis]
                        |
                   [S3 Backup]
```

---

### 5.2 주요 AWS 서비스

#### 5.2.1 Amazon ECS (Elastic Container Service)

**용도**: 컨테이너 오케스트레이션

**구성**:
- **Cluster**: 환경별로 분리
  - `staging-gli-cluster`
  - `production-gli-cluster`
- **Service**: 각 마이크로서비스별로 ECS Service 생성
- **Task Definition**: Docker 컨테이너 실행 설정
- **Launch Type**: Fargate (서버리스)

**프로덕션 설정 예시**:
```json
{
  "family": "production-gli-django-api",
  "networkMode": "awsvpc",
  "requiresCompatibilities": ["FARGATE"],
  "cpu": "1024",
  "memory": "2048",
  "containerDefinitions": [
    {
      "name": "django-api",
      "image": "917891822317.dkr.ecr.ap-northeast-2.amazonaws.com/gli-api-production:latest",
      "portMappings": [
        {
          "containerPort": 8000,
          "protocol": "tcp"
        }
      ],
      "environment": [
        {
          "name": "DJANGO_ENV",
          "value": "production"
        }
      ],
      "secrets": [
        {
          "name": "DATABASE_URL",
          "valueFrom": "arn:aws:secretsmanager:ap-northeast-2:917891822317:secret:gli/db/production-u1ubhz"
        }
      ],
      "logConfiguration": {
        "logDriver": "awslogs",
        "options": {
          "awslogs-group": "/ecs/production-gli-api",
          "awslogs-region": "ap-northeast-2",
          "awslogs-stream-prefix": "ecs"
        }
      }
    }
  ]
}
```

**Auto Scaling 설정**:
- Target Tracking: CPU 사용률 70% 유지
- Min Tasks: 2 (프로덕션), 1 (스테이징)
- Max Tasks: 10 (프로덕션), 4 (스테이징)

---

#### 5.2.2 Amazon ECR (Elastic Container Registry)

**용도**: Docker 이미지 저장소

**리포지토리 목록**:
```
gli-api-staging
  URI: 917891822317.dkr.ecr.ap-northeast-2.amazonaws.com/gli-api-staging

gli-api-production
  URI: 917891822317.dkr.ecr.ap-northeast-2.amazonaws.com/gli-api-production

gli-websocket-staging
  URI: 917891822317.dkr.ecr.ap-northeast-2.amazonaws.com/gli-websocket-staging

gli-websocket-production
  URI: 917891822317.dkr.ecr.ap-northeast-2.amazonaws.com/gli-websocket-production
```

**이미지 태깅 전략**:
```
<repository>:latest                    # 최신 이미지
<repository>:<git-sha>                 # 커밋 SHA로 태그
<repository>:deploy-20250115-150130   # 배포 TAG
```

**이미지 라이프사이클 정책**:
```json
{
  "rules": [
    {
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
    }
  ]
}
```

---

#### 5.2.3 Amazon RDS (Relational Database Service)

**용도**: PostgreSQL 데이터베이스

**프로덕션 설정**:
- **Engine**: PostgreSQL 15
- **Endpoint**: `gli-db-production.cp4ems4wqez2.ap-northeast-2.rds.amazonaws.com`
- **Instance Class**: db.t3.medium
- **Multi-AZ**: 활성화 (고가용성)
- **Storage**: 100GB (자동 증가 활성화)
- **Backup**: 자동 백업 (7일 보관)
- **Encryption**: 활성화 (AWS KMS)

**스테이징 설정**:
- **Endpoint**: `gli-db-staging.cp4ems4wqez2.ap-northeast-2.rds.amazonaws.com`
- Single-AZ
- db.t3.small
- 백업 보관: 3일

**접근 제어**:
- Security Group으로 ECS Task에서만 접근 허용
- Secrets Manager로 자격증명 관리

---

#### 5.2.4 Amazon ElastiCache (Redis)

**용도**: 세션 관리, 캐싱

**프로덕션 설정**:
- **Engine**: Redis 7.0
- **Node Type**: cache.t3.medium
- **Cluster Mode**: 활성화 (고가용성)
- **Replicas**: 2개 (Multi-AZ)

**사용 사례**:
- 사용자 세션 저장
- API 응답 캐싱
- Rate Limiting
- Real-time 데이터 (Socket.io 세션)

---

#### 5.2.5 Amazon S3

**Bucket 목록 및 용도**:

| Bucket | 용도 | 버전 관리 | 라이프사이클 |
|--------|------|----------|-------------|
| `gli-user-frontend-production` | 프론트엔드 정적 파일 | ✅ | 90일 후 IA |
| `gli-user-frontend-staging` | 스테이징 정적 파일 | ❌ | 30일 후 삭제 |
| `gli-admin-frontend-production` | 관리자 대시보드 | ✅ | 90일 후 IA |
| `gli-admin-frontend-staging` | 스테이징 관리자 | ❌ | 30일 후 삭제 |
| `gli-platform-media-prod` | 사용자 업로드 파일 | ✅ | 1년 후 Glacier |
| `gli-platform-media-dev` | 개발 미디어 | ❌ | 30일 후 삭제 |

**CloudFront 연동**:
- 정적 파일은 CloudFront를 통해 글로벌 캐싱
- HTTPS 강제 (ACM 인증서)
- Gzip/Brotli 압축

---

#### 5.2.6 Application Load Balancer (ALB)

**용도**: HTTP/HTTPS 트래픽 분산

**Staging ALB 상세**:
```
Name: gli-staging-alb
DNS: gli-staging-alb-461879350.ap-northeast-2.elb.amazonaws.com
ARN: arn:aws:elasticloadbalancing:ap-northeast-2:917891822317:loadbalancer/app/gli-staging-alb/4b919751696a2d9d

Listeners:
  - HTTP (80): Redirect to HTTPS
  - HTTPS (443):
      Certificate: arn:aws:acm:ap-northeast-2:917891822317:certificate/8590e8e6-1e73-4754-983f-b77ed18e3a82
      Rules:
        ├─ Host: stg-api.glibiz.com → Target Group: gli-stg-api-tg
        └─ Host: stg-ws.glibiz.com → Target Group: gli-stg-ws-tg

Security Group: sg-08d5c4c04594e5477
```

**Production ALB 상세**:
```
Name: gli-production-alb
DNS: gli-production-alb-1195676678.ap-northeast-2.elb.amazonaws.com
ARN: arn:aws:elasticloadbalancing:ap-northeast-2:917891822317:loadbalancer/app/gli-production-alb/4dd48a414b137281

Listeners:
  - HTTP (80): Redirect to HTTPS
  - HTTPS (443):
      Certificate: arn:aws:acm:ap-northeast-2:917891822317:certificate/8590e8e6-1e73-4754-983f-b77ed18e3a82
      Rules:
        ├─ Host: api.glibiz.com → Target Group: gli-prod-api-tg
        └─ Host: ws.glibiz.com → Target Group: gli-prod-ws-tg

Security Group: sg-08d5c4c04594e5477 (공유)
```

**헬스체크 설정**:
- Path: `/health/` (API), `/health` (WebSocket)
- Interval: 30초
- Timeout: 5초
- Healthy Threshold: 2
- Unhealthy Threshold: 3

---

#### 5.2.7 AWS Secrets Manager

**용도**: 민감한 환경 변수 암호화 저장

**생성된 Secrets 목록**:

**Production Database**:
```
Secret Name: gli/db/production
ARN: arn:aws:secretsmanager:ap-northeast-2:917891822317:secret:gli/db/production-u1ubhz
Endpoint: gli-db-production.cp4ems4wqez2.ap-northeast-2.rds.amazonaws.com

Contents:
{
  "username": "glidbadmin",
  "password": "<password>",
  "engine": "postgres",
  "host": "gli-db-production.cp4ems4wqez2.ap-northeast-2.rds.amazonaws.com",
  "port": 5432,
  "dbname": "gli"
}
```

**Staging Database**:
```
Secret Name: gli/db/staging
ARN: arn:aws:secretsmanager:ap-northeast-2:917891822317:secret:gli/db/staging-jnPMCP
Endpoint: gli-db-staging.cp4ems4wqez2.ap-northeast-2.rds.amazonaws.com

Contents: (Same structure as production)
```

**Secret Rotation**:
Database credentials should be rotated periodically:

```bash
# Enable automatic rotation (30 days)
aws secretsmanager rotate-secret \
  --secret-id gli/db/production \
  --rotation-lambda-arn arn:aws:lambda:ap-northeast-2:917891822317:function:SecretsManagerRotation \
  --rotation-rules AutomaticallyAfterDays=30
```

---

#### 5.2.8 Route53 및 ACM Certificates

**Route53 Hosted Zone**:
```
Hosted Zone ID: Z0419507IHNIDPFGXUPL
Domain: glibiz.com

현재 레코드:
  - glibiz.com (NS, SOA)
  - stg-api.glibiz.com (A - ALIAS to Staging ALB) ✅
  - stg-ws.glibiz.com (A - ALIAS to Staging ALB) ✅
  - api.glibiz.com (A - ALIAS to Production ALB) ✅
  - ws.glibiz.com (A - ALIAS to Production ALB) ✅

필요한 레코드 (CloudFront 생성 후):
  - glibiz.com (A - ALIAS to CloudFront)
  - www.glibiz.com (A - ALIAS to CloudFront)
  - admin.glibiz.com (A - ALIAS to CloudFront)
  - stg.glibiz.com (A - ALIAS to CloudFront)
  - stg-admin.glibiz.com (A - ALIAS to CloudFront)
```

**ACM Certificates**:

**CloudFront용 (us-east-1)**:
```
ARN: arn:aws:acm:us-east-1:917891822317:certificate/8a143395-150a-40cf-b9e7-aacbbd3d2caf
Domain: *.glibiz.com, glibiz.com
Status: ISSUED
Valid Until: 2026-11-12
```

**ALB용 (ap-northeast-2)**:
```
ARN: arn:aws:acm:ap-northeast-2:917891822317:certificate/8590e8e6-1e73-4754-983f-b77ed18e3a82
Domain: *.glibiz.com, glibiz.com
Status: ISSUED
Valid Until: 2026-11-12
```

---

#### 5.2.9 Security Groups

**gli-alb-sg**:
```
ID: sg-08d5c4c04594e5477
Purpose: ALB 보안 그룹
Inbound:
  - 80 (HTTP) from 0.0.0.0/0
  - 443 (HTTPS) from 0.0.0.0/0
Outbound:
  - All traffic
```

**gli-ecs-tasks-sg** (생성 필요):
```
Purpose: ECS Tasks 보안 그룹
Inbound:
  - 8000 from ALB Security Group (sg-08d5c4c04594e5477)
  - 8080 from ALB Security Group (sg-08d5c4c04594e5477)
Outbound:
  - All traffic
```

---

### 5.3 현재 인프라 현황

#### 5.3.1 Target Groups

| Name | ARN | Port | Health Check |
|------|-----|------|--------------|
| gli-stg-api-tg | arn:aws:elasticloadbalancing:ap-northeast-2:917891822317:targetgroup/gli-stg-api-tg/5f0499ae426668ca | 8000 | /health/ |
| gli-stg-ws-tg | arn:aws:elasticloadbalancing:ap-northeast-2:917891822317:targetgroup/gli-stg-ws-tg/586551f254635e4a | 8080 | /health |
| gli-prod-api-tg | arn:aws:elasticloadbalancing:ap-northeast-2:917891822317:targetgroup/gli-prod-api-tg/650e7e1476633a2f | 8000 | /health/ |
| gli-prod-ws-tg | arn:aws:elasticloadbalancing:ap-northeast-2:917891822317:targetgroup/gli-prod-ws-tg/6619e0227a562cbc | 8080 | /health |

#### 5.3.2 ECS Clusters

**Staging Cluster**:
```
Cluster: staging-gli-cluster
ARN: arn:aws:ecs:ap-northeast-2:917891822317:cluster/staging-gli-cluster

Services (생성 예정):
  - staging-django-api-service (Task Definition: staging-gli-django-api)
  - staging-websocket-service (Task Definition: staging-gli-websocket)
```

**Production Cluster**:
```
Cluster: production-gli-cluster
ARN: arn:aws:ecs:ap-northeast-2:917891822317:cluster/production-gli-cluster

Services (생성 예정):
  - production-django-api-service (Task Definition: production-gli-django-api)
  - production-websocket-service (Task Definition: production-gli-websocket)
```

#### 5.3.3 CloudWatch Log Groups

| Log Group | 보존 기간 | 용도 |
|-----------|----------|------|
| `/ecs/staging-gli-api` | 30일 | Staging API 로그 |
| `/ecs/staging-gli-websocket` | 30일 | Staging WebSocket 로그 |
| `/ecs/production-gli-api` | 90일 | Production API 로그 |
| `/ecs/production-gli-websocket` | 90일 | Production WebSocket 로그 |

---

## 6. Secrets 및 환경 변수 관리

### 6.1 환경 변수 계층 구조

GLI 프로젝트는 다음과 같은 계층으로 환경 변수를 관리합니다:

```
1. 코드 내 기본값 (config/defaults.py)
   ↓
2. .env.example (템플릿, Git 추적)
   ↓
3. .env.development / .env.staging / .env.production (로컬, Git 무시)
   ↓
4. GitHub Secrets (CI/CD)
   ↓
5. AWS Secrets Manager (ECS Runtime)
```

---

### 6.2 AWS Secrets Manager

#### 6.2.1 생성된 Secrets 목록

이미 Section 5.2.7에서 다룬 내용:
- `gli/db/production` (프로덕션 데이터베이스)
- `gli/db/staging` (스테이징 데이터베이스)

#### 6.2.2 애플리케이션에서 접근 방법

**From GitHub Actions**:
```yaml
- name: Get DB credentials from Secrets Manager
  run: |
    SECRET_JSON=$(aws secretsmanager get-secret-value \
      --secret-id gli/db/production \
      --query SecretString \
      --output text)

    echo "DB_HOST=$(echo $SECRET_JSON | jq -r .host)" >> $GITHUB_ENV
    echo "DB_USER=$(echo $SECRET_JSON | jq -r .username)" >> $GITHUB_ENV
```

**From Application (Django)**:
```python
import boto3
import json
import os

def get_db_secret(environment='production'):
    client = boto3.client('secretsmanager', region_name='ap-northeast-2')
    secret = client.get_secret_value(SecretId=f'gli/db/{environment}')
    return json.loads(secret['SecretString'])

# Usage in settings.py
DJANGO_ENV = os.environ.get('DJANGO_ENV', 'production')
db_secret = get_db_secret(DJANGO_ENV)

DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': db_secret['dbname'],
        'USER': db_secret['username'],
        'PASSWORD': db_secret['password'],
        'HOST': db_secret['host'],
        'PORT': db_secret['port'],
    }
}
```

---

### 6.3 GitHub Secrets

#### 6.3.1 Organization-Level Secrets

다음 Secrets는 Organization 레벨에서 설정 가능:
- `AWS_ACCESS_KEY_ID` - IAM user for GitHub Actions
- `AWS_SECRET_ACCESS_KEY` - Corresponding secret key

설정 위치: `https://github.com/organizations/dreamfurnace/settings/secrets`

#### 6.3.2 Repository-Specific Secrets

각 리포지토리별 필수 Secrets는 Section 4.2.1에서 상세히 다룸.

#### 6.3.3 JWT Keys 생성 방법

**For API Server (RS256 키페어 생성)**:
```bash
# Generate RS256 key pair
ssh-keygen -t rsa -b 4096 -m PEM -f jwt-key
openssl rsa -in jwt-key -pubout -outform PEM -out jwt-key.pub

# Private key (add to GitHub Secrets as JWT_PRIVATE_KEY_*)
cat jwt-key

# Public key (add to GitHub Secrets as JWT_PUBLIC_KEY_*)
cat jwt-key.pub

# Clean up
rm jwt-key jwt-key.pub
```

**또는 OpenSSL 사용**:
```bash
# Generate private key
openssl genrsa -out jwt-private.pem 2048

# Generate public key
openssl rsa -in jwt-private.pem -pubout -out jwt-public.pem

# Display keys
cat jwt-private.pem
cat jwt-public.pem
```

---

### 6.4 환경별 필수 환경 변수

#### 공통 변수

```bash
# 애플리케이션
DJANGO_ENV=production                   # development, staging, production
PORT=8000

# 로깅
LOG_LEVEL=info                          # debug, info, warn, error
LOG_FORMAT=json                         # json, text
```

#### API Server (Django)

```bash
# Django Core
SECRET_KEY=<django-secret-key>
DEBUG=False
ALLOWED_HOSTS=api.glibiz.com,stg-api.glibiz.com

# Database (from Secrets Manager)
DATABASE_URL=postgresql://user:pass@host:5432/gli

# CORS
CORS_ALLOWED_ORIGINS=https://glibiz.com,https://admin.glibiz.com

# Frontend Base URL
FRONTEND_BASE_URL=https://glibiz.com

# JWT
JWT_PRIVATE_KEY=<rsa-private-key>
JWT_PUBLIC_KEY=<rsa-public-key>

# AWS S3 (Media Files)
AWS_STORAGE_BUCKET_NAME=gli-platform-media-prod
AWS_S3_REGION_NAME=ap-northeast-2

# Email (SendGrid)
SENDGRID_API_KEY=SG.xxxxx

# Monitoring
SENTRY_DSN=https://xxx@sentry.io/xxx
```

#### WebSocket Server

```bash
# Socket.io
SOCKET_IO_PORT=8080
SOCKET_IO_PATH=/socket.io
SOCKET_IO_CORS_ORIGINS=https://glibiz.com,https://admin.glibiz.com

# Redis Adapter (for scaling)
REDIS_HOST=gli-prod-redis.xxxxx.ng.0001.apn2.cache.amazonaws.com
REDIS_PORT=6379
REDIS_PASSWORD=<password>
```

#### Frontend (Vue.js)

```bash
# API 엔드포인트
VUE_APP_API_URL=https://api.glibiz.com
VUE_APP_WS_URL=https://ws.glibiz.com

# 외부 서비스
VUE_APP_GOOGLE_ANALYTICS_ID=G-XXXXXXXXXX
VUE_APP_SENTRY_DSN=https://xxx@sentry.io/xxx
```

---

### 6.5 AWS IAM Permissions

#### 6.5.1 GitHub Actions IAM User

GitHub Actions용 전용 IAM 사용자를 생성하세요.

**사용자 이름**: `gli-github-actions`

#### 6.5.2 필요한 정책

**Policy 1: GitHubActionsECRPolicy**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:PutImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload"
      ],
      "Resource": "*"
    }
  ]
}
```

**Policy 2: GitHubActionsECSPolicy**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecs:RegisterTaskDefinition",
        "ecs:DescribeTaskDefinition",
        "ecs:DescribeClusters",
        "ecs:DescribeServices",
        "ecs:UpdateService",
        "ecs:RunTask",
        "ecs:DescribeTasks"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "iam:PassRole"
      ],
      "Resource": "arn:aws:iam::917891822317:role/ecsTaskExecutionRole"
    }
  ]
}
```

**Policy 3: GitHubActionsS3CloudFrontPolicy**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject",
        "s3:ListBucket",
        "s3:DeleteObject"
      ],
      "Resource": [
        "arn:aws:s3:::*gli*frontend*",
        "arn:aws:s3:::*gli*frontend*/*"
      ]
    },
    {
      "Effect": "Allow",
      "Action": [
        "cloudfront:CreateInvalidation",
        "cloudfront:GetInvalidation",
        "cloudfront:ListInvalidations"
      ],
      "Resource": "*"
    }
  ]
}
```

**Policy 4: GitHubActionsSecretsManagerPolicy**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ],
      "Resource": "arn:aws:secretsmanager:ap-northeast-2:917891822317:secret:gli/*"
    }
  ]
}
```

**IAM User 생성 및 설정**:
```bash
# Create IAM user
aws iam create-user --user-name gli-github-actions

# Attach policies
aws iam attach-user-policy \
  --user-name gli-github-actions \
  --policy-arn arn:aws:iam::917891822317:policy/GitHubActionsECRPolicy

aws iam attach-user-policy \
  --user-name gli-github-actions \
  --policy-arn arn:aws:iam::917891822317:policy/GitHubActionsECSPolicy

aws iam attach-user-policy \
  --user-name gli-github-actions \
  --policy-arn arn:aws:iam::917891822317:policy/GitHubActionsS3CloudFrontPolicy

aws iam attach-user-policy \
  --user-name gli-github-actions \
  --policy-arn arn:aws:iam::917891822317:policy/GitHubActionsSecretsManagerPolicy

# Create access key
aws iam create-access-key --user-name gli-github-actions
```

---

### 6.6 보안 Best Practices

#### 1. 절대 커밋하지 마세요
- Secret keys를 코드에 직접 입력하지 말 것
- `.env` 파일을 git에 커밋하지 말 것
- `.gitignore`에 다음 추가:
  ```
  .env
  .env.*
  !.env.example
  .secrets/
  *.pem
  *.key
  ```

#### 2. 정기적으로 로테이션
- Database passwords: 매 90일
- API keys: 매 180일
- AWS access keys: 매 180일
- JWT keys: 매 1년

#### 3. 최소 권한 원칙
- 필요한 권한만 부여
- 용도별로 별도 IAM 사용자/역할 생성
- Production과 Staging은 별도 자격증명 사용

#### 4. 모니터링
- AWS CloudTrail로 Secrets Manager 접근 로그 확인
- 정기적으로 액세스 로그 검토
- 비정상 접근 시 알림 설정

#### 5. 암호화
- AWS Secrets Manager는 AWS KMS로 자동 암호화
- EBS 볼륨 암호화 활성화
- S3 버킷 암호화 활성화

#### 6. 환경 분리
- Production secrets를 절대 staging/dev에서 사용 금지
- 환경별로 완전히 격리된 자격증명 사용

---

## 다음 단계

이제 [**DEPLOYMENT_GUIDE_3of3.md**](./DEPLOYMENT_GUIDE_3of3.md)에서 다음 내용을 확인하세요:
- 배포 프로세스 (표준 및 핫픽스)
- GitHub Actions 워크플로우
- 모니터링 및 롤백
- 트러블슈팅
- 체크리스트

---

**문서 버전**: 3.0
**최종 업데이트**: 2025-01-15
**작성자**: DevOps 팀
