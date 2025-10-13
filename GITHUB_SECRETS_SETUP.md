# GitHub Secrets 설정 가이드

## 📋 개요

GLI 플랫폼 배포를 위해 각 GitHub 리포지토리에 Secrets를 설정해야 합니다.

## 🔐 필수 Secrets 목록

### 1. gli_api-server

#### 공통 AWS 자격 증명
```
AWS_ACCESS_KEY_ID: <AWS Access Key>
AWS_SECRET_ACCESS_KEY: <AWS Secret Key>
AWS_REGION: ap-northeast-2
```

#### ECR 리포지토리
```
STG_ECR_REPOSITORY: gli-api-staging
PROD_ECR_REPOSITORY: gli-api-production
```

#### Secrets Manager
```
DB_SECRET_NAME_STAGING: gli/db/staging
DB_SECRET_NAME_PRODUCTION: gli/db/production
```

#### Django 설정 (Staging)
```
SECRET_KEY_STAGING: <Django Secret Key - 생성 필요>
JWT_PRIVATE_KEY_STAGING: <JWT Private Key - 생성 필요>
JWT_PUBLIC_KEY_STAGING: <JWT Public Key - 생성 필요>
CORS_ALLOWED_ORIGINS_STAGING: https://stg.glibiz.com,https://stg-admin.glibiz.com
FRONTEND_BASE_URL_STAGING: https://stg.glibiz.com
AWS_STORAGE_BUCKET_NAME_STAGING: gli-platform-media-dev
```

#### Django 설정 (Production)
```
SECRET_KEY_PRODUCTION: <Django Secret Key - 생성 필요>
JWT_PRIVATE_KEY_PRODUCTION: <JWT Private Key - 생성 필요>
JWT_PUBLIC_KEY_PRODUCTION: <JWT Public Key - 생성 필요>
CORS_ALLOWED_ORIGINS_PRODUCTION: https://glibiz.com,https://www.glibiz.com,https://admin.glibiz.com
FRONTEND_BASE_URL_PRODUCTION: https://glibiz.com
AWS_STORAGE_BUCKET_NAME_PRODUCTION: gli-platform-media-prod
```

---

### 2. gli_websocket

#### AWS 자격 증명
```
AWS_ACCESS_KEY_ID: <AWS Access Key>
AWS_SECRET_ACCESS_KEY: <AWS Secret Key>
AWS_REGION: ap-northeast-2
```

#### ECR 리포지토리
```
STG_ECR_REPOSITORY: gli-websocket-staging
PROD_ECR_REPOSITORY: gli-websocket-production
```

---

### 3. gli_user-frontend

#### AWS 자격 증명
```
AWS_ACCESS_KEY_ID: <AWS Access Key>
AWS_SECRET_ACCESS_KEY: <AWS Secret Key>
AWS_REGION: ap-northeast-2
```

#### S3 Buckets
```
STG_S3_BUCKET: gli-user-frontend-staging
PROD_S3_BUCKET: gli-user-frontend-production
```

#### CloudFront Distribution IDs
```
STG_CLOUDFRONT_DISTRIBUTION_ID: E2M2F8O36YCDX
PROD_CLOUDFRONT_DISTRIBUTION_ID: EUY0BEWJK212R
```

---

### 4. gli_admin-frontend

#### AWS 자격 증명
```
AWS_ACCESS_KEY_ID: <AWS Access Key>
AWS_SECRET_ACCESS_KEY: <AWS Secret Key>
AWS_REGION: ap-northeast-2
```

#### S3 Buckets
```
STG_S3_BUCKET: gli-admin-frontend-staging
PROD_S3_BUCKET: gli-admin-frontend-production
```

#### CloudFront Distribution IDs
```
STG_CLOUDFRONT_DISTRIBUTION_ID: E1UMP4GMPQCQ0G
PROD_CLOUDFRONT_DISTRIBUTION_ID: E31LKUK6NABDLS
```

---

## 🔧 Secret 생성 방법

### 자동 생성 (권장)

모든 필수 Secret Keys를 자동으로 생성합니다:

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

### 수동 생성 (참고용)

```bash
# Django Secret Key 생성
python -c "from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())"

# JWT Keys 생성
openssl genrsa -out jwt-private.pem 2048
openssl rsa -in jwt-private.pem -pubout -out jwt-public.pem
```

---

## 📝 설정 방법

### 방법 1: 자동화 스크립트 (권장) ⭐

**모든 리포지토리의 Secrets를 한 번에 설정:**

```bash
cd /path/to/gli_root

# Step 1: Secret Keys 생성 (아직 안 했다면)
./generate-secrets.sh

# Step 2: GitHub Secrets 자동 설정
chmod +x setup-github-secrets.sh
./setup-github-secrets.sh
# AWS Access Key와 Secret Key 입력 필요
```

**설정되는 내용:**
- **gli_api-server**: 18개 secrets (AWS, ECR, DB, Django, JWT, CORS 등)
- **gli_websocket**: 5개 secrets (AWS, ECR)
- **gli_user-frontend**: 7개 secrets (AWS, S3, CloudFront)
- **gli_admin-frontend**: 7개 secrets (AWS, S3, CloudFront)

**총 37개 secrets 자동 설정!**

### 방법 2: GitHub UI에서 수동 설정

각 리포지토리에서 수동으로 설정하려면:

1. GitHub Repository 페이지로 이동
2. **Settings** 클릭
3. 왼쪽 메뉴에서 **Secrets and variables** > **Actions** 클릭
4. **New repository secret** 버튼 클릭
5. Name과 Value 입력 후 **Add secret** 클릭

**Repository URLs:**
- https://github.com/dreamfurnace/gli_api-server/settings/secrets/actions
- https://github.com/dreamfurnace/gli_websocket/settings/secrets/actions
- https://github.com/dreamfurnace/gli_user-frontend/settings/secrets/actions
- https://github.com/dreamfurnace/gli_admin-frontend/settings/secrets/actions

설정할 Secret 값은 `.secrets/SECRETS_SUMMARY.md` 파일 참고

### 방법 3: gh CLI로 개별 설정

```bash
# 예시: gli_api-server에 AWS 자격 증명 설정
gh secret set AWS_ACCESS_KEY_ID -b"<your-access-key>" -R dreamfurnace/gli_api-server
gh secret set AWS_SECRET_ACCESS_KEY -b"<your-secret-key>" -R dreamfurnace/gli_api-server
gh secret set AWS_REGION -b"ap-northeast-2" -R dreamfurnace/gli_api-server
```

---

## ✅ 설정 확인

Secrets가 제대로 설정되었는지 확인:

```bash
# 특정 리포지토리의 Secrets 목록 확인 (값은 보이지 않음)
gh secret list -R dreamfurnace/gli_api-server
```

---

## 🚀 설정 완료 후

모든 Secrets 설정이 완료되면:

```bash
# 1. 코드 변경 후 stg 브랜치에 push
cd gli_api-server
# ... 코드 수정 ...
git add .
git commit -m "feat: update api"
git push origin stg

# 2. GitHub Actions 자동 트리거
# Repository > Actions 탭에서 워크플로우 실행 확인

# 3. 배포 완료 확인
curl https://stg-api.glibiz.com/health/
```

---

## ⚠️ 보안 주의사항

1. **절대 커밋하지 마세요**
   - Secret keys를 코드에 직접 입력하지 말 것
   - .env 파일을 git에 커밋하지 말 것

2. **정기적으로 로테이션**
   - AWS Access Keys는 정기적으로 갱신
   - Django Secret Keys는 변경 시 모든 세션 무효화됨

3. **최소 권한 원칙**
   - GitHub Actions용 AWS 사용자는 필요한 권한만 부여
   - ECR, ECS, S3, CloudFront, Secrets Manager 접근만

---

## 📚 관련 문서

- [AWS Secrets Manager](./SECRETS_MANAGEMENT.md)
- [Deployment Guide](./DEPLOYMENT_GUIDE.md)
- [Infrastructure Status](./INFRASTRUCTURE_STATUS.md)

---

**최종 업데이트**: 2025-10-13
**작성자**: DevOps Team
