# GLI 프로젝트 배포 가이드 (Part 1 of 3)

> **문서 분할 안내**: 이 문서는 총 3개 파일로 구성되어 있습니다.
> - **[현재] Part 1**: 배포 시스템 개요, 환경 구성, 브랜치 전략, 사전 준비
> - **Part 2**: AWS 인프라, Secrets 및 환경 변수 관리
> - **Part 3**: 배포 프로세스, GitHub Actions, 모니터링, 트러블슈팅

---

## 📑 전체 목차

### Part 1 (현재 문서)
1. **배포 시스템 개요**
2. **환경 구성**
3. **브랜치 전략**
4. **사전 준비**

### Part 2
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

## 1. 배포 시스템 개요

GLI 프로젝트는 **마이크로서비스 아키텍처**와 **GitOps 방식의 자동 배포**를 채택하고 있습니다. 각 서비스는 독립적인 Git 리포지토리로 관리되며, 브랜치별로 해당하는 환경에 자동 배포됩니다.

### 1.1 핵심 원칙

1. **GitOps**: Git 브랜치가 환경 상태의 유일한 진실 공급원(Single Source of Truth)
2. **자동화**: GitHub Actions를 통한 CI/CD 자동화
3. **독립성**: 각 마이크로서비스는 독립적으로 배포 가능
4. **일관성**: 모든 서비스가 동일한 배포 파이프라인 사용
5. **추적성**: 배포 태그와 로그를 통한 완벽한 이력 관리

### 1.2 배포 흐름 요약

```
로컬 개발 → dev 브랜치 push → 개발 환경 자동 배포
         → stg 브랜치 merge → 스테이징 환경 자동 배포
         → main 브랜치 merge → 프로덕션 환경 자동 배포
```

### 1.3 아키텍처 다이어그램

#### Backend (Django API + WebSocket)

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

#### Frontend (Vue.js)

```
Internet
    ↓
Route53 (stg.glibiz.com, glibiz.com)
    ↓
CloudFront Distribution (CDN)
    ↓
S3 Bucket (Static Website Hosting)
    - gli-user-frontend-staging
    - gli-user-frontend-production
```

#### Secrets Management

```
┌─────────────────────────────────────────────────────────┐
│                     GLI Secrets                          │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌──────────────────┐      ┌────────────────────────┐  │
│  │  AWS Secrets     │      │   GitHub Secrets       │  │
│  │  Manager         │      │                        │  │
│  ├──────────────────┤      ├────────────────────────┤  │
│  │  • Database      │      │  • AWS Credentials     │  │
│  │  • API Keys      │      │  • S3 Buckets          │  │
│  │  • Credentials   │      │  • CloudFront IDs      │  │
│  └──────────────────┘      └────────────────────────┘  │
│           ▲                          ▲                  │
│           │                          │                  │
│           └──────────────────────────┘                  │
│                     │                                   │
│            ┌────────▼────────┐                          │
│            │ GitHub Actions  │                          │
│            │   Workflows     │                          │
│            └─────────────────┘                          │
│                     │                                   │
│       ┌─────────────┼─────────────┐                     │
│       ▼             ▼             ▼                     │
│  ┌────────┐   ┌──────────┐  ┌──────────┐               │
│  │  API   │   │ Frontend │  │WebSocket │               │
│  │ Server │   │   Apps   │  │  Server  │               │
│  └────────┘   └──────────┘  └──────────┘               │
└─────────────────────────────────────────────────────────┘
```

---

## 2. 환경 구성

GLI 프로젝트는 3개의 독립적인 환경을 운영합니다.

### 2.1 개발 환경 (Development)

**브랜치**: `dev`

**도메인**:
- User Frontend: `dev.glibiz.com`
- Admin Dashboard: `dev-admin.glibiz.com`
- API Server: `dev-api.glibiz.com`
- WebSocket: `dev-ws.glibiz.com`

**용도**:
- 개발자의 로컬 변경사항 통합 및 테스트
- 피처 브랜치 머지 후 통합 테스트
- 개발팀 내부 기능 확인

**자동 배포 트리거**:
- `dev` 브랜치에 push 발생 시

**AWS 리소스**:
- ECS Cluster: `gli-dev-cluster`
- RDS Instance: `gli-dev-db`
- S3 Bucket: `gli-dev-frontend-assets`
- CloudFront Distribution: Dev용 CDN

---

### 2.2 스테이징 환경 (Staging)

**브랜치**: `stg`

**도메인**:
- User Frontend: `stg.glibiz.com`
- Admin Dashboard: `stg-admin.glibiz.com`
- API Server: `stg-api.glibiz.com`
- WebSocket: `stg-ws.glibiz.com`

**용도**:
- QA 팀의 통합 테스트
- 프로덕션 배포 전 최종 검증
- 고객 데모 및 UAT (User Acceptance Test)

**자동 배포 트리거**:
- `stg` 브랜치에 push 발생 시
- `dev → stg` 머지 시 TAG 생성 (`stg-deploy-*`)

**AWS 리소스**:
- ECS Cluster: `staging-gli-cluster`
- RDS Instance: `gli-db-staging.cp4ems4wqez2.ap-northeast-2.rds.amazonaws.com`
- S3 Bucket: `gli-user-frontend-staging`, `gli-admin-frontend-staging`
- CloudFront Distribution: Staging용 CDN
- ALB: `gli-staging-alb-461879350.ap-northeast-2.elb.amazonaws.com`

---

### 2.3 프로덕션 환경 (Production)

**브랜치**: `main`

**도메인**:
- User Frontend: `glibiz.com` (또는 `www.glibiz.com`)
- Admin Dashboard: `admin.glibiz.com`
- API Server: `api.glibiz.com`
- WebSocket: `ws.glibiz.com`

**용도**:
- 실제 사용자 서비스
- 안정적이고 검증된 코드만 배포
- 24/7 모니터링 및 즉각 대응

**자동 배포 트리거**:
- `main` 브랜치에 push 발생 시
- `stg → main` 머지 시 TAG 생성 (`deploy-*`)

**AWS 리소스**:
- ECS Cluster: `production-gli-cluster` (고가용성 설정)
- RDS Instance: `gli-db-production.cp4ems4wqez2.ap-northeast-2.rds.amazonaws.com` (Multi-AZ, 자동 백업)
- S3 Bucket: `gli-user-frontend-production`, `gli-admin-frontend-production` (버전 관리 활성화)
- CloudFront Distribution: Production용 CDN (글로벌 캐싱)
- ALB: `gli-production-alb-1195676678.ap-northeast-2.elb.amazonaws.com`

---

### 2.4 도메인 구성

#### 운영계 (Production)

**Frontend**:
- `glibiz.com` → CloudFront → S3 (gli-user-frontend-production)
- `www.glibiz.com` → CloudFront → S3 (gli-user-frontend-production)
- `admin.glibiz.com` → CloudFront → S3 (gli-admin-frontend-production)

**Backend**:
- `api.glibiz.com` → ALB (gli-production-alb) → ECS ✅
- `ws.glibiz.com` → ALB (gli-production-alb) → ECS ✅

#### 스테이징계 (Staging)

**Frontend**:
- `stg.glibiz.com` → CloudFront → S3 (gli-user-frontend-staging)
- `stg-admin.glibiz.com` → CloudFront → S3 (gli-admin-frontend-staging)

**Backend**:
- `stg-api.glibiz.com` → ALB (gli-staging-alb) → ECS ✅
- `stg-ws.glibiz.com` → ALB (gli-staging-alb) → ECS ✅

**범례**:
- ✅ 생성 완료
- ⏳ CloudFront 생성 필요 (선택적)

---

## 3. 브랜치 전략

### 3.1 Git Flow 기반 브랜치 전략

GLI 프로젝트는 Git Flow를 단순화한 3-브랜치 전략을 사용합니다.

```
main (프로덕션)
  ↑
  └─── stg (스테이징)
         ↑
         └─── dev (개발)
                ↑
                └─── feature/* (피처 브랜치)
```

### 3.2 브랜치별 상세 규칙

#### 1. `main` 브랜치 (Production)

- **보호 설정**: Force push 금지, 직접 커밋 금지
- **머지 방식**: `stg` 브랜치에서만 머지 가능 (`--no-ff` 필수)
- **권한**: 팀 리드, DevOps 담당자만 머지 권한
- **배포 TAG**: `deploy-YYYYMMDD-HHMMSS` (자동 생성)
- **커밋 메시지 규칙**: `release:` 또는 `hotfix:` 접두사

**예시 커밋 메시지**:
```
release: v2.3.0 - 사용자 프로필 기능 출시
hotfix: API 타임아웃 긴급 수정
```

#### 2. `stg` 브랜치 (Staging)

- **보호 설정**: Force push 금지
- **머지 방식**: 주로 `dev`에서 머지, 예외적으로 `main`에서도 가능 (핫픽스)
- **권한**: 개발팀 전체 머지 가능
- **배포 TAG**: `stg-deploy-YYYYMMDD-HHMMSS` (dev→stg 머지 시 자동 생성)
- **커밋 메시지 규칙**: `feat:`, `fix:`, `chore:` 등 Conventional Commits

**예시 커밋 메시지**:
```
feat: 결제 모듈 스테이징 배포
fix: 로그인 오류 수정
```

#### 3. `dev` 브랜치 (Development)

- **보호 설정**: 없음 (자유로운 개발)
- **머지 방식**: 피처 브랜치 또는 직접 커밋
- **권한**: 모든 개발자
- **배포 TAG**: 없음 (태그 미생성)
- **커밋 메시지 규칙**: 자유 형식, 권장사항은 Conventional Commits

**예시 커밋 메시지**:
```
dev: 사용자 인증 로직 개선
wip: 대시보드 UI 작업 중
```

#### 4. `feature/*` 브랜치 (Feature)

- **생성 기준**: `dev` 브랜치에서 분기
- **네이밍 규칙**: `feature/기능명` 또는 `feature/이슈번호-기능명`
- **생명 주기**: 기능 개발 완료 후 `dev`에 머지하고 삭제
- **커밋 메시지**: 자유 형식

**예시**:
```bash
git checkout dev
git pull origin dev
git checkout -b feature/user-profile
# ... 개발 작업 ...
git push origin feature/user-profile
# PR 생성 → 리뷰 → dev에 머지
git checkout dev
git branch -d feature/user-profile
```

### 3.3 Conventional Commits 가이드

GLI 프로젝트는 커밋 메시지에 다음 접두사를 권장합니다:

| 접두사 | 의미 | 사용 시점 |
|--------|------|----------|
| `feat:` | 새로운 기능 추가 | 새 API, UI 컴포넌트, 기능 추가 |
| `fix:` | 버그 수정 | 오류 수정, 핫픽스 |
| `docs:` | 문서 변경 | README, 가이드 작성 |
| `style:` | 코드 포맷팅 | Prettier, ESLint 적용 |
| `refactor:` | 리팩토링 | 동작은 동일하나 코드 개선 |
| `test:` | 테스트 코드 | 유닛 테스트, E2E 테스트 |
| `chore:` | 빌드/설정 | 패키지 업데이트, 설정 변경 |
| `perf:` | 성능 개선 | 최적화, 캐싱 |
| `ci:` | CI/CD 변경 | GitHub Actions 워크플로우 |
| `revert:` | 커밋 되돌리기 | 이전 커밋 취소 |
| `release:` | 버전 릴리스 | 프로덕션 배포 |
| `hotfix:` | 긴급 수정 | 프로덕션 긴급 패치 |

**예시**:
```
feat: 사용자 프로필 페이지 추가
fix: 로그인 API 타임아웃 수정
docs: 배포 가이드 업데이트
refactor: 인증 로직 개선
test: 결제 모듈 유닛 테스트 추가
chore: Next.js 14로 업그레이드
```

---

## 4. 사전 준비

배포를 시작하기 전에 다음 사항들을 준비해야 합니다.

### 4.1 AWS 인프라 현황 체크리스트

배포 전 다음 AWS 리소스가 생성되어 있는지 확인하세요:

#### ✅ ECR Repositories (생성 완료)
```
917891822317.dkr.ecr.ap-northeast-2.amazonaws.com/gli-api-staging
917891822317.dkr.ecr.ap-northeast-2.amazonaws.com/gli-api-production
917891822317.dkr.ecr.ap-northeast-2.amazonaws.com/gli-websocket-staging
917891822317.dkr.ecr.ap-northeast-2.amazonaws.com/gli-websocket-production
```

#### ✅ ECS Clusters (생성 완료)
```
Staging: staging-gli-cluster
  ARN: arn:aws:ecs:ap-northeast-2:917891822317:cluster/staging-gli-cluster

Production: production-gli-cluster
  ARN: arn:aws:ecs:ap-northeast-2:917891822317:cluster/production-gli-cluster
```

#### ✅ S3 Buckets (생성 완료)
```
gli-user-frontend-staging (Static Website Hosting 활성화)
gli-user-frontend-production (Static Website Hosting 활성화)
gli-admin-frontend-staging (Static Website Hosting 활성화)
gli-admin-frontend-production (Static Website Hosting 활성화)
```

#### ✅ CloudWatch Log Groups (생성 완료)
```
/ecs/staging-gli-api (보존 기간: 30일)
/ecs/staging-gli-websocket (보존 기간: 30일)
/ecs/production-gli-api (보존 기간: 30일)
/ecs/production-gli-websocket (보존 기간: 30일)
```

#### ✅ AWS Secrets Manager (생성 완료)
```
Secret Name: gli/db/staging
  ARN: arn:aws:secretsmanager:ap-northeast-2:917891822317:secret:gli/db/staging-jnPMCP
  Endpoint: gli-db-staging.cp4ems4wqez2.ap-northeast-2.rds.amazonaws.com

Secret Name: gli/db/production
  ARN: arn:aws:secretsmanager:ap-northeast-2:917891822317:secret:gli/db/production-u1ubhz
  Endpoint: gli-db-production.cp4ems4wqez2.ap-northeast-2.rds.amazonaws.com
```

#### ✅ Application Load Balancer (생성 완료)

**Staging ALB**:
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

**Production ALB**:
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

#### ✅ ACM Certificates (생성 완료)

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

#### ✅ Route53 (생성 완료)
```
Hosted Zone ID: Z0419507IHNIDPFGXUPL

현재 레코드:
  - glibiz.com (NS)
  - glibiz.com (SOA)
  - stg-api.glibiz.com (A - ALIAS to Staging ALB) ✅
  - stg-ws.glibiz.com (A - ALIAS to Staging ALB) ✅
  - api.glibiz.com (A - ALIAS to Production ALB) ✅
  - ws.glibiz.com (A - ALIAS to Production ALB) ✅
```

---

### 4.2 GitHub Secrets 설정

모든 GitHub 리포지토리에 필요한 Secrets을 설정해야 합니다.

#### 4.2.1 필수 Secrets 목록

##### 1. gli_api-server

**공통 AWS 자격 증명**:
```
AWS_ACCESS_KEY_ID: <AWS Access Key>
AWS_SECRET_ACCESS_KEY: <AWS Secret Key>
AWS_REGION: ap-northeast-2
```

**ECR 리포지토리**:
```
STG_ECR_REPOSITORY: gli-api-staging
PROD_ECR_REPOSITORY: gli-api-production
```

**Secrets Manager**:
```
DB_SECRET_NAME_STAGING: gli/db/staging
DB_SECRET_NAME_PRODUCTION: gli/db/production
```

**Django 설정 (Staging)**:
```
SECRET_KEY_STAGING: <Django Secret Key - 생성 필요>
JWT_PRIVATE_KEY_STAGING: <JWT Private Key - 생성 필요>
JWT_PUBLIC_KEY_STAGING: <JWT Public Key - 생성 필요>
CORS_ALLOWED_ORIGINS_STAGING: https://stg.glibiz.com,https://stg-admin.glibiz.com
FRONTEND_BASE_URL_STAGING: https://stg.glibiz.com
AWS_STORAGE_BUCKET_NAME_STAGING: gli-platform-media-dev
```

**Django 설정 (Production)**:
```
SECRET_KEY_PRODUCTION: <Django Secret Key - 생성 필요>
JWT_PRIVATE_KEY_PRODUCTION: <JWT Private Key - 생성 필요>
JWT_PUBLIC_KEY_PRODUCTION: <JWT Public Key - 생성 필요>
CORS_ALLOWED_ORIGINS_PRODUCTION: https://glibiz.com,https://www.glibiz.com,https://admin.glibiz.com
FRONTEND_BASE_URL_PRODUCTION: https://glibiz.com
AWS_STORAGE_BUCKET_NAME_PRODUCTION: gli-platform-media-prod
```

##### 2. gli_websocket

```
AWS_ACCESS_KEY_ID: <AWS Access Key>
AWS_SECRET_ACCESS_KEY: <AWS Secret Key>
AWS_REGION: ap-northeast-2

STG_ECR_REPOSITORY: gli-websocket-staging
PROD_ECR_REPOSITORY: gli-websocket-production
```

##### 3. gli_user-frontend

```
AWS_ACCESS_KEY_ID: <AWS Access Key>
AWS_SECRET_ACCESS_KEY: <AWS Secret Key>
AWS_REGION: ap-northeast-2

STG_S3_BUCKET: gli-user-frontend-staging
PROD_S3_BUCKET: gli-user-frontend-production

STG_CLOUDFRONT_DISTRIBUTION_ID: E2M2F8O36YCDX
PROD_CLOUDFRONT_DISTRIBUTION_ID: EUY0BEWJK212R
```

##### 4. gli_admin-frontend

```
AWS_ACCESS_KEY_ID: <AWS Access Key>
AWS_SECRET_ACCESS_KEY: <AWS Secret Key>
AWS_REGION: ap-northeast-2

STG_S3_BUCKET: gli-admin-frontend-staging
PROD_S3_BUCKET: gli-admin-frontend-production

STG_CLOUDFRONT_DISTRIBUTION_ID: E1UMP4GMPQCQ0G
PROD_CLOUDFRONT_DISTRIBUTION_ID: E31LKUK6NABDLS
```

---

#### 4.2.2 Secret 자동 생성 스크립트

Django Secret Key와 JWT Keys를 자동으로 생성하는 스크립트를 사용하세요.

**Step 1: Secret Keys 생성**
```bash
cd /path/to/gli_root
chmod +x generate-secrets.sh
./generate-secrets.sh
```

생성되는 파일:
- `.secrets/django_secret_staging.txt`
- `.secrets/django_secret_production.txt`
- `.secrets/jwt_private_staging.pem`
- `.secrets/jwt_public_staging.pem`
- `.secrets/jwt_private_production.pem`
- `.secrets/jwt_public_production.pem`
- `.secrets/SECRETS_SUMMARY.md` (모든 키 요약)

**수동 생성 방법 (참고용)**:
```bash
# Django Secret Key 생성
python -c "from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())"

# JWT Keys 생성 (RS256)
ssh-keygen -t rsa -b 4096 -m PEM -f jwt-key
openssl rsa -in jwt-key -pubout -outform PEM -out jwt-key.pub

# Private key (JWT_PRIVATE_KEY_*)
cat jwt-key

# Public key (JWT_PUBLIC_KEY_*)
cat jwt-key.pub

# Clean up
rm jwt-key jwt-key.pub
```

---

#### 4.2.3 설정 방법

##### 방법 1: 자동화 스크립트 (권장) ⭐

**모든 리포지토리의 Secrets를 한 번에 설정**:

```bash
cd /path/to/gli_root

# Step 1: Secret Keys 생성 (아직 안 했다면)
./generate-secrets.sh

# Step 2: GitHub Secrets 자동 설정
chmod +x setup-github-secrets.sh
./setup-github-secrets.sh
# AWS Access Key와 Secret Key 입력 필요
```

**설정되는 내용**:
- **gli_api-server**: 18개 secrets (AWS, ECR, DB, Django, JWT, CORS 등)
- **gli_websocket**: 5개 secrets (AWS, ECR)
- **gli_user-frontend**: 7개 secrets (AWS, S3, CloudFront)
- **gli_admin-frontend**: 7개 secrets (AWS, S3, CloudFront)

**총 37개 secrets 자동 설정!**

##### 방법 2: GitHub UI에서 수동 설정

각 리포지토리에서 수동으로 설정하려면:

1. GitHub Repository 페이지로 이동
2. **Settings** 클릭
3. 왼쪽 메뉴에서 **Secrets and variables** > **Actions** 클릭
4. **New repository secret** 버튼 클릭
5. Name과 Value 입력 후 **Add secret** 클릭

**Repository URLs**:
- https://github.com/dreamfurnace/gli_api-server/settings/secrets/actions
- https://github.com/dreamfurnace/gli_websocket/settings/secrets/actions
- https://github.com/dreamfurnace/gli_user-frontend/settings/secrets/actions
- https://github.com/dreamfurnace/gli_admin-frontend/settings/secrets/actions

설정할 Secret 값은 `.secrets/SECRETS_SUMMARY.md` 파일 참고

##### 방법 3: gh CLI로 개별 설정

```bash
# gh CLI 설치
brew install gh

# 인증
gh auth login

# 예시: gli_api-server에 AWS 자격 증명 설정
gh secret set AWS_ACCESS_KEY_ID -b"<your-access-key>" -R dreamfurnace/gli_api-server
gh secret set AWS_SECRET_ACCESS_KEY -b"<your-secret-key>" -R dreamfurnace/gli_api-server
gh secret set AWS_REGION -b"ap-northeast-2" -R dreamfurnace/gli_api-server

# 여러 리포지토리에 동일한 Secret 설정
REPOS=(
  "gli_api-server"
  "gli_user-frontend"
  "gli_admin-frontend"
  "gli_websocket"
)

for repo in "${REPOS[@]}"; do
  gh secret set AWS_ACCESS_KEY_ID -b"<your-access-key>" -R dreamfurnace/$repo
  gh secret set AWS_SECRET_ACCESS_KEY -b"<your-secret-key>" -R dreamfurnace/$repo
done
```

---

#### 4.2.4 설정 확인

Secrets가 제대로 설정되었는지 확인:

```bash
# 특정 리포지토리의 Secrets 목록 확인 (값은 보이지 않음)
gh secret list -R dreamfurnace/gli_api-server
gh secret list -R dreamfurnace/gli_websocket
gh secret list -R dreamfurnace/gli_user-frontend
gh secret list -R dreamfurnace/gli_admin-frontend
```

---

### 4.3 첫 배포 준비사항

#### 배포 순서
1. ✅ AWS 인프라 생성 (ECR, ECS, ALB, S3) - **완료**
2. ✅ Route53 Backend 레코드 추가 - **완료**
3. ⏳ GitHub Secrets 설정 - **필요**
4. ⏳ 첫 배포 실행 (Task Definition 생성) - **대기 중**
5. ⏳ ECS 서비스 생성 (자동 또는 수동) - **대기 중**
6. 🔜 CloudFront 생성 (선택적)
7. 🔜 Route53 Frontend 레코드 추가

#### 배포 흐름
```
개발 (dev) → 스테이징 (stg) → 프로덕션 (main)
    ↓              ↓                ↓
  로컬 테스트    stg.glibiz.com   glibiz.com
```

#### 주의사항
- ⚠️ Production 배포는 스테이징 검증 후에만 수행
- ⚠️ ECS 서비스는 Task Definition이 있어야 시작됨
- ⚠️ 첫 배포 시 마이그레이션이 실행되므로 DB 연결 확인 필요
- ⚠️ ALB Security Group과 ECS Task Security Group 연결 필수

---

## 다음 단계

이제 [**DEPLOYMENT_GUIDE_2of3.md**](./DEPLOYMENT_GUIDE_2of3.md)에서 다음 내용을 확인하세요:
- AWS 인프라 상세
- Secrets 및 환경 변수 관리

---

**문서 버전**: 3.0
**최종 업데이트**: 2025-01-15
**작성자**: DevOps 팀
