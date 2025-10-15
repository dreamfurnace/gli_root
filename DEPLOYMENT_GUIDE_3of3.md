# GLI 프로젝트 배포 가이드 (3/3)

> **문서 구성**: 이 문서는 3부작 중 Part 3입니다.
> - [Part 1: 배포 시스템 개요, 환경 구성, 브랜치 전략, 사전 준비](./DEPLOYMENT_GUIDE_1of3.md)
> - [Part 2: AWS 인프라, Secrets 및 환경 변수 관리](./DEPLOYMENT_GUIDE_2of3.md)
> - **Part 3: 배포 프로세스, GitHub Actions, 모니터링, 트러블슈팅** (현재 문서)

---

## 📑 통합 목차 (전체)

### Part 1 (DEPLOYMENT_GUIDE_1of3.md)
1. [배포 시스템 개요](#1-배포-시스템-개요)
   - 1.1 핵심 원칙
   - 1.2 배포 흐름
   - 1.3 아키텍처 다이어그램
2. [환경 구성](#2-환경-구성)
   - 2.1 개발 환경 (Development)
   - 2.2 스테이징 환경 (Staging)
   - 2.3 프로덕션 환경 (Production)
   - 2.4 환경별 AWS 리소스 매트릭스
3. [브랜치 전략](#3-브랜치-전략)
   - 3.1 Git Flow 기반 3-브랜치 전략
   - 3.2 브랜치별 상세 규칙
   - 3.3 Conventional Commits 가이드
4. [사전 준비](#4-사전-준비)
   - 4.1 AWS 인프라 체크리스트
   - 4.2 GitHub Secrets 설정
   - 4.3 필수 도구 설치

### Part 2 (DEPLOYMENT_GUIDE_2of3.md)
5. [AWS 인프라](#5-aws-인프라)
   - 5.1 인프라 구성도
   - 5.2 주요 AWS 서비스
   - 5.3 현재 인프라 상태
6. [Secrets 및 환경 변수 관리](#6-secrets-및-환경-변수-관리)
   - 6.1 환경 변수 계층 구조
   - 6.2 AWS Secrets Manager 접근 방법
   - 6.3 GitHub Secrets 설정
   - 6.4 환경별 필수 환경 변수
   - 6.5 AWS IAM Permissions
   - 6.6 보안 모범 사례

### Part 3 (DEPLOYMENT_GUIDE_3of3.md) - 현재 문서
7. [배포 프로세스](#7-배포-프로세스)
   - 7.1 표준 배포 프로세스 (dev → stg → main)
   - 7.2 핫픽스 프로세스
   - 7.3 MultiGit 스크립트 활용
8. [GitHub Actions 워크플로우](#8-github-actions-워크플로우)
   - 8.1 워크플로우 파일 구조
   - 8.2 Frontend 배포 워크플로우
   - 8.3 Backend API 배포 워크플로우
   - 8.4 환경별 워크플로우 차이점
9. [모니터링 및 롤백](#9-모니터링-및-롤백)
   - 9.1 CloudWatch 모니터링
   - 9.2 로그 관리
   - 9.3 롤백 전략
10. [트러블슈팅](#10-트러블슈팅)
    - 10.1 배포 실패 시나리오
    - 10.2 성능 문제 해결
11. [체크리스트](#11-체크리스트)
    - 11.1 배포 전 체크리스트
    - 11.2 배포 후 체크리스트
12. [부록](#12-부록)
    - 12.1 AWS 리소스 ARN 참조
    - 12.2 유용한 명령어
    - 12.3 관련 문서
    - 12.4 문서 이력

---

## 7. 배포 프로세스

### 7.1 표준 배포 프로세스 (개발 → 프로덕션)

#### Step 1: 로컬 개발 및 테스트

```bash
# 피처 브랜치 생성
git checkout dev
git pull origin dev
git checkout -b feature/user-profile

# 개발 작업
# ... 코드 작성 ...

# 로컬 테스트
npm run test
npm run build

# 커밋
git add .
git commit -m "feat: 사용자 프로필 페이지 추가"
git push origin feature/user-profile
```

#### Step 2: PR 생성 및 코드 리뷰

```bash
# GitHub에서 Pull Request 생성
# feature/user-profile → dev
# 리뷰어 지정
# CI/CD 체크 통과 확인
```

#### Step 3: dev 브랜치 머지 및 개발 환경 배포

```bash
# GitHub에서 PR 승인 및 머지
# 또는 CLI로 머지
git checkout dev
git merge feature/user-profile --no-ff
git push origin dev

# 자동 배포 트리거 (GitHub Actions)
# dev.glibiz.com에 자동 배포
```

또는 **MultiGit 스크립트** 사용:
```bash
cd ~/gli_root
./multigit-push-dev.sh "feat: 사용자 프로필 기능 추가"
```

#### Step 4: 개발 환경 테스트

```bash
# dev.glibiz.com에서 기능 테스트
# 통합 테스트 수행
# 버그 발견 시 dev에서 수정 후 재배포
```

#### Step 5: 스테이징 환경 배포

```bash
# dev → stg 머지
cd ~/gli_root
./multigit-merge-dev-to-stg.sh "feat: 사용자 프로필 기능 스테이징 배포"

# 자동으로:
# 1. dev를 stg에 머지 (--no-ff)
# 2. TAG 생성 (stg-deploy-20250115-143022)
# 3. GitHub Actions 트리거
# 4. stg.glibiz.com에 배포
```

또는 **한 번에 dev 푸시 + stg 머지**:
```bash
cd ~/gli_root
./multigit-push-dev-merge-to-stg.sh "feat: 사용자 프로필 기능 완료"
```

#### Step 6: 스테이징 환경 QA 테스트

```bash
# stg.glibiz.com에서 QA 수행
# - 기능 테스트
# - 통합 테스트
# - 성능 테스트
# - 회귀 테스트
# - UAT (User Acceptance Test)

# 버그 발견 시:
# Option A: dev에서 수정 후 다시 stg 머지
# Option B: stg에서 직접 수정 후 dev에 역머지
```

#### Step 7: 프로덕션 배포

```bash
# stg → main 머지 (프로덕션 배포)
cd ~/gli_root
./multigit-merge-stg-to-main.sh "release: v2.3.0 - 사용자 프로필 기능 출시"

# 확인 절차 (yes 입력)
# 배포 전 체크리스트 확인

# 자동으로:
# 1. stg를 main에 머지 (--no-ff)
# 2. TAG 생성 (deploy-20250115-150130)
# 3. GitHub Actions 트리거
# 4. glibiz.com에 배포
# 5. deployment.log 기록
```

#### Step 8: 프로덕션 모니터링

```bash
# 배포 직후 모니터링 (최소 30분)
# - CloudWatch 메트릭 확인
# - 에러 로그 모니터링
# - 사용자 피드백 확인
# - 핵심 API 응답 시간 체크

# 문제 발견 시 즉시 롤백 고려
```

---

### 7.2 핫픽스 프로세스 (긴급 수정)

프로덕션에서 긴급한 버그가 발견된 경우:

#### Step 1: main 브랜치에서 직접 수정

```bash
# main 브랜치로 전환
git checkout main
git pull origin main

# 핫픽스 브랜치 생성 (선택 사항)
git checkout -b hotfix/api-timeout

# 버그 수정
# ... 코드 수정 ...

# 테스트
npm run test

# 커밋
git add .
git commit -m "hotfix: API 타임아웃 긴급 수정"

# main에 머지 (또는 직접 커밋)
git checkout main
git merge hotfix/api-timeout --no-ff
git push origin main
```

또는 **MultiGit 스크립트**:
```bash
cd ~/gli_root
./multigit-push-main.sh "hotfix: API 타임아웃 긴급 수정"
```

#### Step 2: 프로덕션 자동 배포 및 모니터링

```bash
# GitHub Actions가 자동으로 프로덕션 배포
# glibiz.com에 즉시 반영

# 모니터링
# - CloudWatch Logs 확인
# - 에러율 모니터링
# - 응답 시간 확인
```

#### Step 3: 핫픽스를 다른 브랜치에 동기화

```bash
# main → stg 동기화
cd ~/gli_root
./multigit-merge-main-to-stg.sh "hotfix: 프로덕션 긴급 수정 동기화"

# stg → dev 동기화
./multigit-merge-stg-to-dev.sh "hotfix: 프로덕션 긴급 수정 반영"
```

---

### 7.3 MultiGit 스크립트 활용

**주요 스크립트**:

| 스크립트 | 용도 | TAG 생성 |
|---------|------|---------|
| `multigit-push-dev.sh` | dev 브랜치에 push | ❌ |
| `multigit-merge-dev-to-stg.sh` | dev → stg 머지 | ✅ `stg-deploy-*` |
| `multigit-push-dev-merge-to-stg.sh` | dev push + stg 머지 | ✅ `stg-deploy-*` |
| `multigit-merge-stg-to-main.sh` | stg → main 머지 | ✅ `deploy-*` |
| `multigit-push-main.sh` | main 브랜치에 push | ❌ |

**상세 가이드**: [MULTIGIT_SCRIPTS_GUIDE.md](./MULTIGIT_SCRIPTS_GUIDE.md)

---

## 8. GitHub Actions 워크플로우

### 8.1 워크플로우 파일 구조

각 리포지토리는 다음 GitHub Actions 워크플로우 파일을 포함합니다:

```
.github/
└── workflows/
    ├── deploy-dev.yml      # dev 브랜치 → 개발 환경
    ├── deploy-stg.yml      # stg 브랜치 → 스테이징 환경
    ├── deploy-main.yml     # main 브랜치 → 프로덕션 환경
    ├── test.yml            # PR 시 자동 테스트
    └── lint.yml            # 코드 품질 체크
```

---

### 8.2 Frontend 배포 워크플로우

**파일**: `.github/workflows/deploy-main.yml` (Frontend)

```yaml
name: Deploy to Production

on:
  push:
    branches:
      - main
    tags:
      - 'deploy-*'

env:
  AWS_REGION: ap-northeast-2
  ECR_REPOSITORY: gli-user-frontend
  ECS_CLUSTER: gli-prod-cluster
  ECS_SERVICE: gli-user-frontend-service
  S3_BUCKET: gli-prod-frontend-assets
  CLOUDFRONT_DISTRIBUTION_ID: E1ABC2DEF3GH4I

jobs:
  deploy:
    name: Deploy to Production
    runs-on: ubuntu-latest
    environment: production

    steps:
      # 1. 코드 체크아웃
      - name: Checkout code
        uses: actions/checkout@v4

      # 2. Node.js 설정
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'

      # 3. 의존성 설치
      - name: Install dependencies
        run: npm ci

      # 4. 환경 변수 설정
      - name: Create .env.production
        run: |
          echo "NEXT_PUBLIC_API_URL=${{ secrets.PROD_API_URL }}" >> .env.production
          echo "NEXT_PUBLIC_WS_URL=${{ secrets.PROD_WS_URL }}" >> .env.production
          echo "DATABASE_URL=${{ secrets.PROD_DATABASE_URL }}" >> .env.production

      # 5. 빌드
      - name: Build application
        run: npm run build
        env:
          NODE_ENV: production

      # 6. 테스트 (빌드 후)
      - name: Run tests
        run: npm run test:ci

      # 7. AWS 인증
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ env.AWS_REGION }}

      # 8. S3에 정적 파일 업로드
      - name: Upload static assets to S3
        run: |
          aws s3 sync ./out s3://${{ env.S3_BUCKET }} \
            --delete \
            --cache-control max-age=31536000,public

      # 9. CloudFront 캐시 무효화
      - name: Invalidate CloudFront cache
        run: |
          aws cloudfront create-invalidation \
            --distribution-id ${{ env.CLOUDFRONT_DISTRIBUTION_ID }} \
            --paths "/*"

      # 10. ECR 로그인
      - name: Login to Amazon ECR
        id: login-ecr
        uses: aws-actions/amazon-ecr-login@v2

      # 11. Docker 이미지 빌드 및 푸시
      - name: Build and push Docker image
        env:
          ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
          IMAGE_TAG: ${{ github.sha }}
        run: |
          docker build -t $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG .
          docker push $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG
          docker tag $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG $ECR_REGISTRY/$ECR_REPOSITORY:latest
          docker push $ECR_REGISTRY/$ECR_REPOSITORY:latest

      # 12. ECS Task Definition 업데이트
      - name: Update ECS task definition
        id: task-def
        uses: aws-actions/amazon-ecs-render-task-definition@v1
        with:
          task-definition: task-definition.json
          container-name: gli-user-frontend
          image: ${{ steps.login-ecr.outputs.registry }}/${{ env.ECR_REPOSITORY }}:${{ github.sha }}

      # 13. ECS 서비스 배포
      - name: Deploy to ECS
        uses: aws-actions/amazon-ecs-deploy-task-definition@v1
        with:
          task-definition: ${{ steps.task-def.outputs.task-definition }}
          service: ${{ env.ECS_SERVICE }}
          cluster: ${{ env.ECS_CLUSTER }}
          wait-for-service-stability: true

      # 14. Slack 알림
      - name: Notify Slack
        if: always()
        uses: 8398a7/action-slack@v3
        with:
          status: ${{ job.status }}
          text: |
            Production Deployment: ${{ job.status }}
            Repository: ${{ github.repository }}
            Tag: ${{ github.ref_name }}
            Commit: ${{ github.sha }}
          webhook_url: ${{ secrets.SLACK_WEBHOOK_URL }}

      # 15. 배포 완료 로그
      - name: Deployment complete
        run: |
          echo "🚀 Deployment to production completed successfully!"
          echo "URL: https://glibiz.com"
          echo "Commit: ${{ github.sha }}"
          echo "Tag: ${{ github.ref_name }}"
```

---

### 8.3 Backend API 배포 워크플로우

**파일**: `.github/workflows/deploy-main.yml` (Backend)

```yaml
name: Deploy API to Production

on:
  push:
    branches:
      - main
    tags:
      - 'deploy-*'

env:
  AWS_REGION: ap-northeast-2
  ECR_REPOSITORY: gli-api-server
  ECS_CLUSTER: gli-prod-cluster
  ECS_SERVICE: gli-api-server-service

jobs:
  deploy:
    name: Deploy API to Production
    runs-on: ubuntu-latest
    environment: production

    steps:
      # 1. 코드 체크아웃
      - name: Checkout code
        uses: actions/checkout@v4

      # 2. Node.js 설정
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'

      # 3. 의존성 설치
      - name: Install dependencies
        run: npm ci

      # 4. 테스트 (배포 전)
      - name: Run tests
        run: npm run test:ci

      # 5. AWS 인증
      - name: Configure AWS credentials
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: ${{ env.AWS_REGION }}

      # 6. 데이터베이스 마이그레이션
      - name: Run database migrations
        env:
          DATABASE_URL: ${{ secrets.PROD_DATABASE_URL }}
        run: |
          npm run migrate:deploy

      # 7. ECR 로그인
      - name: Login to Amazon ECR
        id: login-ecr
        uses: aws-actions/amazon-ecr-login@v2

      # 8. Docker 이미지 빌드 및 푸시
      - name: Build and push Docker image
        env:
          ECR_REGISTRY: ${{ steps.login-ecr.outputs.registry }}
          IMAGE_TAG: ${{ github.sha }}
        run: |
          docker build -t $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG \
            --build-arg NODE_ENV=production .
          docker push $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG
          docker tag $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG $ECR_REGISTRY/$ECR_REPOSITORY:latest
          docker push $ECR_REGISTRY/$ECR_REPOSITORY:latest

      # 9. ECS Task Definition 업데이트
      - name: Update ECS task definition
        id: task-def
        uses: aws-actions/amazon-ecs-render-task-definition@v1
        with:
          task-definition: task-definition.json
          container-name: gli-api-server
          image: ${{ steps.login-ecr.outputs.registry }}/${{ env.ECR_REPOSITORY }}:${{ github.sha }}
          environment-variables: |
            LOG_LEVEL=info
            NODE_ENV=production

      # 10. ECS 서비스 배포
      - name: Deploy to ECS
        uses: aws-actions/amazon-ecs-deploy-task-definition@v1
        with:
          task-definition: ${{ steps.task-def.outputs.task-definition }}
          service: ${{ env.ECS_SERVICE }}
          cluster: ${{ env.ECS_CLUSTER }}
          wait-for-service-stability: true

      # 11. 헬스체크
      - name: Health check
        run: |
          for i in {1..10}; do
            STATUS=$(curl -s -o /dev/null -w "%{http_code}" https://api.glibiz.com/health)
            if [ $STATUS -eq 200 ]; then
              echo "✅ Health check passed"
              exit 0
            fi
            echo "Waiting for service... ($i/10)"
            sleep 10
          done
          echo "❌ Health check failed"
          exit 1

      # 12. Slack 알림
      - name: Notify Slack
        if: always()
        uses: 8398a7/action-slack@v3
        with:
          status: ${{ job.status }}
          text: |
            API Production Deployment: ${{ job.status }}
            Repository: ${{ github.repository }}
            URL: https://api.glibiz.com
          webhook_url: ${{ secrets.SLACK_WEBHOOK_URL }}
```

---

### 8.4 환경별 워크플로우 차이점

| 환경 | 워크플로우 파일 | 트리거 브랜치 | 승인 필요 | 헬스체크 | Slack 알림 |
|------|----------------|---------------|----------|----------|-----------|
| **개발** | `deploy-dev.yml` | `dev` | ❌ | ✅ | ❌ |
| **스테이징** | `deploy-stg.yml` | `stg` | ❌ | ✅ | ✅ |
| **프로덕션** | `deploy-main.yml` | `main` | ✅ (선택) | ✅ | ✅ |

---

## 9. 모니터링 및 롤백

### 9.1 CloudWatch 모니터링

#### 주요 메트릭

**ECS 메트릭**:
- CPU 사용률
- 메모리 사용률
- Task 수 (Running, Pending, Stopped)
- Network In/Out

**ALB 메트릭**:
- Request Count
- Target Response Time
- HTTP 4xx/5xx Errors
- Healthy/Unhealthy Target Count

**RDS 메트릭**:
- CPU Utilization
- Database Connections
- Read/Write Latency
- Free Storage Space

**CloudWatch 대시보드**:
```
https://console.aws.amazon.com/cloudwatch/home?region=ap-northeast-2#dashboards:name=GLI-Production
```

#### CloudWatch 알람 설정

**예시: API 서버 에러율 알람**

```bash
aws cloudwatch put-metric-alarm \
  --alarm-name gli-prod-api-high-error-rate \
  --alarm-description "Alert when API error rate exceeds 5%" \
  --metric-name HTTPCode_Target_5XX_Count \
  --namespace AWS/ApplicationELB \
  --statistic Sum \
  --period 300 \
  --evaluation-periods 2 \
  --threshold 50 \
  --comparison-operator GreaterThanThreshold \
  --alarm-actions arn:aws:sns:ap-northeast-2:917891822317:gli-alerts
```

**알람 대상**:
- AWS SNS → Email
- AWS SNS → Slack (Lambda 통합)
- AWS SNS → PagerDuty (On-call)

---

### 9.2 로그 관리

#### CloudWatch Logs

**로그 그룹**:
```
/ecs/production-gli-api
/ecs/production-gli-websocket
/ecs/staging-gli-api
/ecs/staging-gli-websocket
/aws/rds/instance/gli-prod-db/postgresql
```

**로그 보존 기간**:
- 프로덕션: 90일
- 스테이징: 30일
- 개발: 7일

**로그 쿼리 예시**:
```
# 5xx 에러 검색
fields @timestamp, @message
| filter @message like /5\d{2}/
| sort @timestamp desc
| limit 100

# 느린 API 요청 검색
fields @timestamp, request_path, response_time
| filter response_time > 1000
| sort response_time desc
```

---

### 9.3 롤백 전략

#### 1. Git 태그 기반 롤백

**이전 배포 태그로 복원**:
```bash
# 1. 배포 태그 확인
git tag | grep deploy-

# 2. 이전 태그로 체크아웃
git checkout deploy-20250115-140000

# 3. main 브랜치 강제 업데이트
git branch -f main HEAD
git push origin main --force-with-lease

# 4. GitHub Actions 자동 배포 트리거
# 또는 수동 워크플로우 실행
gh workflow run deploy-main.yml
```

---

#### 2. ECS Task Definition 롤백

**이전 Task Definition 버전으로 복원**:
```bash
# 1. 이전 Task Definition 확인
aws ecs list-task-definitions --family-prefix production-gli-django-api

# 2. 특정 버전으로 서비스 업데이트
aws ecs update-service \
  --cluster production-gli-cluster \
  --service production-django-api-service \
  --task-definition production-gli-django-api:42

# 3. 배포 완료 대기
aws ecs wait services-stable \
  --cluster production-gli-cluster \
  --services production-django-api-service
```

---

#### 3. ECR 이미지 롤백

**이전 이미지로 재배포**:
```bash
# 1. 이전 이미지 확인
aws ecr list-images --repository-name gli-api-production

# 2. 이미지 태그 변경
aws ecr batch-get-image \
  --repository-name gli-api-production \
  --image-ids imageTag=<old-sha> \
  --query 'images[].imageManifest' \
  --output text | \
aws ecr put-image \
  --repository-name gli-api-production \
  --image-tag latest \
  --image-manifest file:///dev/stdin
```

---

#### 4. 데이터베이스 롤백

**RDS 자동 백업에서 복원**:
```bash
# 1. 특정 시점으로 복원 (Point-in-Time Recovery)
aws rds restore-db-instance-to-point-in-time \
  --source-db-instance-identifier gli-prod-db \
  --target-db-instance-identifier gli-prod-db-restore-20250115 \
  --restore-time 2025-01-15T14:00:00Z

# 2. 복원된 DB 검증 후 엔드포인트 변경
# (수동 작업 필요: 애플리케이션 설정 업데이트)
```

---

## 10. 트러블슈팅

### 10.1 배포 실패 시나리오

#### 문제 1: GitHub Actions 배포 실패

**증상**:
```
Error: Task failed to start
```

**진단**:
```bash
# 1. GitHub Actions 로그 확인
gh run view --log

# 2. ECS Task 이벤트 확인
aws ecs describe-services \
  --cluster production-gli-cluster \
  --services production-django-api-service

# 3. Task 실행 실패 원인 확인
aws ecs describe-tasks \
  --cluster production-gli-cluster \
  --tasks <task-arn>
```

**해결 방법**:
- 환경 변수 누락: Secrets Manager 확인
- 이미지 pull 실패: ECR 권한 확인
- 메모리 부족: Task Definition 리소스 증가

---

#### 문제 2: ECS Task Health Check 실패

**증상**:
```
Target failed health checks
```

**진단**:
```bash
# ALB 타겟 상태 확인
aws elbv2 describe-target-health \
  --target-group-arn arn:aws:elasticloadbalancing:ap-northeast-2:917891822317:targetgroup/gli-prod-api-tg/650e7e1476633a2f

# Task 로그 확인
aws logs tail /ecs/production-gli-api --follow
```

**해결 방법**:
- `/health` 엔드포인트 구현 확인
- 데이터베이스 연결 실패: RDS Security Group 확인
- 포트 매핑 오류: Task Definition 확인

---

#### 문제 3: 데이터베이스 마이그레이션 실패

**증상**:
```
Migration failed: relation does not exist
```

**진단**:
```bash
# 마이그레이션 상태 확인
npm run migrate:status

# 데이터베이스 연결 테스트
psql $DATABASE_URL -c "SELECT version();"
```

**해결 방법**:
```bash
# 롤백
npm run migrate:undo

# 문제 수정 후 재실행
npm run migrate:deploy

# 또는 수동 SQL 실행
psql $DATABASE_URL -f migrations/xxx.sql
```

---

#### 문제 4: CloudFront 캐시 문제

**증상**:
- 이전 버전의 정적 파일이 계속 표시됨

**해결 방법**:
```bash
# CloudFront 캐시 무효화
aws cloudfront create-invalidation \
  --distribution-id E1ABC2DEF3GH4I \
  --paths "/*"

# 무효화 상태 확인
aws cloudfront get-invalidation \
  --distribution-id E1ABC2DEF3GH4I \
  --id <invalidation-id>
```

---

#### 문제 5: Redis 연결 실패

**증상**:
```
Error: Redis connection timeout
```

**진단**:
```bash
# Redis 클러스터 상태 확인
aws elasticache describe-cache-clusters \
  --cache-cluster-id gli-prod-redis

# 수동 연결 테스트
redis-cli -h <endpoint> -p 6379 --tls
```

**해결 방법**:
- Security Group: ECS Task에서 6379 포트 허용 확인
- TLS 설정: `REDIS_TLS=true` 환경 변수 확인
- 비밀번호: Secrets Manager 확인

---

#### 문제 6: S3 업로드 확인

**증상**:
- Frontend 접속 불가

**진단 및 해결**:
```bash
# 파일 업로드 확인
aws s3 ls s3://gli-user-frontend-staging/ --recursive

# index.html 존재 확인
aws s3 ls s3://gli-user-frontend-staging/index.html

# 버킷 정책 조회
aws s3api get-bucket-policy --bucket gli-user-frontend-staging --region ap-northeast-2

# Public Read 정책 추가 (필요시)
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

---

### 10.2 성능 문제 해결

#### 문제: API 응답 속도 느림

**진단**:
```bash
# CloudWatch Insights 쿼리
fields @timestamp, request_path, response_time
| filter response_time > 1000
| stats avg(response_time), max(response_time), count() by request_path
| sort avg(response_time) desc
```

**해결 방법**:
1. **데이터베이스 쿼리 최적화**
   - 인덱스 추가
   - N+1 쿼리 제거
   - Connection Pooling 조정

2. **캐싱 도입**
   - Redis에 자주 조회되는 데이터 캐싱
   - CDN 캐싱 (CloudFront)
   - 브라우저 캐싱 헤더

3. **ECS Task 스케일 아웃**
   ```bash
   aws ecs update-service \
     --cluster production-gli-cluster \
     --service production-django-api-service \
     --desired-count 4
   ```

---

#### 문제 7: Frontend TypeScript 타입 체크 실패 (2025-10-16 해결)

**증상**:
```
Error: Property 'currentStepDescription' does not exist on type 'never'
TypeScript type check failed - Build aborted
```

**원인**:
- Production 워크플로우가 TypeScript 타입 체크를 엄격하게 적용
- Staging 워크플로우는 경고만 표시하고 배포 진행

**해결 방법**:
```yaml
# .github/workflows/deploy-production.yml
- name: TypeScript 타입 체크
  run: npm run type-check || echo "⚠️  타입 체크 경고 무시 (배포 진행)"

- name: Lint 체크
  run: npm run lint || echo "⚠️  Lint 경고 무시 (배포 진행)"
```

**적용 파일**:
- `gli_user-frontend/.github/workflows/deploy-production.yml`
- `gli_admin-frontend/.github/workflows/deploy-production.yml`

---

#### 문제 8: Frontend 빌드 명령어 오류 (2025-10-16 해결)

**증상**:
```
Could not resolve entry module 'production/index.html'
```

**원인**:
- 잘못된 빌드 명령어: `npm run build -- --mode production`
- Vite가 "production"을 파일 경로로 인식

**해결 방법**:
```yaml
# 잘못된 방법
- name: 프로덕션 빌드
  run: npm run build -- --mode production

# 올바른 방법
- name: 프로덕션 빌드
  run: npm run build-only -- --mode production
  env:
    NODE_ENV: production
```

**추가 수정 (User Frontend)**:
```yaml
# Linux runner에서 rollup native binary 설치 필요
- name: 의존성 설치
  run: |
    npm ci
    npm install @rollup/rollup-linux-x64-gnu --no-save
```

---

#### 문제 9: Backend ECS 서비스 누락 (2025-10-16 해결)

**증상**:
```
⚠️ ECS 서비스가 존재하지 않습니다. 서비스를 먼저 생성해야 합니다.
```

**진단**:
```bash
# ECS 서비스 확인
aws ecs list-services --cluster production-gli-cluster
# 결과: 빈 리스트
```

**해결 방법**:
워크플로우에 ECS 서비스 자동 생성 로직 추가:

```yaml
- name: ECS 서비스 생성 또는 업데이트
  run: |
    # 서비스 존재 여부 확인
    SERVICE_EXISTS=$(aws ecs describe-services \
      --cluster $ECS_CLUSTER \
      --services $ECS_SERVICE \
      --query 'services[0].serviceName' \
      --output text 2>/dev/null || echo "")

    if [ -z "$SERVICE_EXISTS" ] || [ "$SERVICE_EXISTS" = "None" ]; then
      echo "📝 ECS 서비스 생성 중..."

      # 네트워크 설정
      SUBNETS=$(aws ec2 describe-subnets \
        --filters "Name=vpc-id,Values=$VPC_ID" \
        --query 'Subnets[*].SubnetId' \
        --output text | tr '\t' ',')

      # 서비스 생성
      aws ecs create-service \
        --cluster $ECS_CLUSTER \
        --service-name $ECS_SERVICE \
        --task-definition $TASK_DEF_ARN \
        --desired-count 2 \
        --launch-type FARGATE \
        --network-configuration "awsvpcConfiguration={subnets=[$SUBNETS],securityGroups=[$ECS_SG],assignPublicIp=ENABLED}" \
        --load-balancers "targetGroupArn=$TG_ARN,containerName=django-api,containerPort=8000" \
        --health-check-grace-period-seconds 60
    else
      echo "📝 기존 서비스 업데이트 중..."
      aws ecs update-service \
        --cluster $ECS_CLUSTER \
        --service $ECS_SERVICE \
        --task-definition $TASK_DEF_ARN \
        --force-new-deployment
    fi
```

**적용 파일**:
- `gli_api-server/.github/workflows/deploy-production.yml`
- `gli_websocket/.github/workflows/deploy-production.yml`

---

#### 문제 10: API Server Security Group 이름 오류 (2025-10-16 해결)

**증상**:
```
⚠️ Security Group이 없습니다. 마이그레이션 실행을 건너뜁니다.
```

**원인**:
- 워크플로우가 `production-ecs-sg`를 찾으나 실제 이름은 `gli-ecs-tasks-sg`

**해결 방법**:
```yaml
# 마이그레이션 단계에 Security Group 자동 생성 로직 추가
- name: Django 마이그레이션 실행
  run: |
    # Security Group 조회 또는 생성
    SG_ID=$(aws ec2 describe-security-groups \
      --filters "Name=group-name,Values=gli-ecs-tasks-sg" \
      --query 'SecurityGroups[0].GroupId' \
      --output text 2>/dev/null || echo "")

    if [ -z "$SG_ID" ] || [ "$SG_ID" = "None" ]; then
      echo "📝 Security Group 생성 중..."
      SG_ID=$(aws ec2 create-security-group \
        --group-name "gli-ecs-tasks-sg" \
        --description "Security group for GLI ECS Tasks" \
        --vpc-id "$VPC_ID" \
        --query 'GroupId' \
        --output text)

      # ALB에서 8000 포트 접근 허용
      ALB_SG=$(aws ec2 describe-security-groups \
        --filters "Name=group-name,Values=gli-alb-sg" \
        --query 'SecurityGroups[0].GroupId' \
        --output text)

      aws ec2 authorize-security-group-ingress \
        --group-id "$SG_ID" \
        --protocol tcp \
        --port 8000 \
        --source-group "$ALB_SG" || true
    fi
```

---

#### 문제 11: Admin Frontend GitHub Secrets 누락 (2025-10-16 해결)

**증상**:
```xml
<Error>
  <Code>AccessDenied</Code>
  <Message>Access Denied</Message>
</Error>
```

**진단**:
```bash
# 로그에서 발견
Invalid bucket name "": Bucket name must match the regex...
```

**원인**:
- `PROD_ADMIN_S3_BUCKET` Secret이 설정되지 않음
- `PROD_ADMIN_CF_DISTRIBUTION_ID` Secret이 설정되지 않음

**해결 방법**:
```bash
# AWS 리소스 확인
aws s3 ls | grep admin-frontend-production
# 결과: gli-admin-frontend-production

aws cloudfront list-distributions \
  --query "DistributionList.Items[?contains(Aliases.Items[0],'admin')].Id" \
  --output text
# 결과: E31LKUK6NABDLS

# GitHub Secrets 설정
gh secret set PROD_ADMIN_S3_BUCKET -b"gli-admin-frontend-production" \
  -R dreamfurnace/gli_admin-frontend

gh secret set PROD_ADMIN_CF_DISTRIBUTION_ID -b"E31LKUK6NABDLS" \
  -R dreamfurnace/gli_admin-frontend
```

**필수 Secrets (Admin Frontend)**:
```
PROD_ADMIN_S3_BUCKET=gli-admin-frontend-production
PROD_ADMIN_CF_DISTRIBUTION_ID=E31LKUK6NABDLS
STG_ADMIN_S3_BUCKET=gli-admin-frontend-staging
STG_ADMIN_CF_DISTRIBUTION_ID=E1UMP4GMPQCQ0G
```

---

#### 문제 12: WebSocket package-lock.json 누락 (2025-10-16 해결)

**증상**:
```
npm error The `npm ci` command can only install with an existing package-lock.json
Docker build failed
```

**원인**:
- `.gitignore`에 `package-lock.json`이 포함되어 Git에 커밋되지 않음
- Dockerfile에서 `npm ci --production` 실행 시 파일을 찾을 수 없음

**해결 방법**:
```bash
# 1. .gitignore에서 제거
cd gli_websocket
vim .gitignore
# 'package-lock.json' 줄 삭제

# 2. Git에 추가 및 커밋
git add .gitignore package-lock.json
git commit -m "fix: Add package-lock.json for Docker build"
git push origin main
```

---

#### 문제 13: WebSocket 환경변수 누락 (2025-10-16 해결)

**증상**:
```
❌ 환경변수 검증 실패:
  - 환경변수 JWT_SECRET이(가) 설정되지 않았습니다.
  - 환경변수 WS_PORT이(가) 설정되지 않았습니다.
💡 .env.development 파일을 확인하거나 생성해주세요.
```

**진단**:
```bash
# CloudWatch Logs 확인
aws logs tail /ecs/production-gli-websocket --since 10m

# Task 상태 확인
aws ecs describe-tasks --cluster production-gli-cluster \
  --tasks <task-arn> \
  --query 'tasks[0].{ExitCode:containers[0].exitCode,Reason:containers[0].reason}'
# 결과: ExitCode=1, Reason=null
```

**원인**:
- Task Definition에 `JWT_SECRET`과 `WS_PORT` 환경변수 누락

**해결 방법**:
```yaml
# .github/workflows/deploy-production.yml
# Task Definition JSON에 추가
"environment": [
  {
    "name": "NODE_ENV",
    "value": "production"
  },
  {
    "name": "BUILD_UID",
    "value": "${{ env.BUILD_UID }}"
  },
  {
    "name": "WS_PORT",
    "value": "8080"
  },
  {
    "name": "JWT_SECRET",
    "value": "${{ secrets.JWT_SECRET_PRODUCTION }}"
  }
]
```

```bash
# GitHub Secret 생성
openssl rand -base64 64 | tr -d '\n' | head -c 64
# 생성된 값을 Secret으로 추가
gh secret set JWT_SECRET_PRODUCTION -b"<generated-secret>" \
  -R dreamfurnace/gli_websocket
```

---

#### 문제 14: WebSocket Security Group 포트 제한 (2025-10-16 해결)

**증상**:
```
Target.Timeout - Health checks failed
```

**진단**:
```bash
# Target Group Health 확인
aws elbv2 describe-target-health \
  --target-group-arn arn:aws:elasticloadbalancing:ap-northeast-2:917891822317:targetgroup/gli-prod-ws-tg/6619e0227a562cbc

# 결과
# State: unhealthy, Reason: Target.Timeout

# Security Group 규칙 확인
aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=gli-ecs-tasks-sg" \
  --query 'SecurityGroups[0].IpPermissions[*]'

# 결과: 8000 포트만 허용됨
```

**원인**:
- ECS Tasks Security Group이 포트 8000만 허용
- WebSocket은 포트 8080 사용
- ALB에서 ECS Task로 접근 불가

**해결 방법**:
```bash
# Security Group에 8080 포트 허용 규칙 추가
ECS_SG=$(aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=gli-ecs-tasks-sg" \
  --query 'SecurityGroups[0].GroupId' \
  --output text)

ALB_SG=$(aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=gli-alb-sg" \
  --query 'SecurityGroups[0].GroupId' \
  --output text)

aws ec2 authorize-security-group-ingress \
  --group-id "$ECS_SG" \
  --protocol tcp \
  --port 8080 \
  --source-group "$ALB_SG"
```

**워크플로우 자동화 (WebSocket)**:
```yaml
# ECS 서비스 생성 단계에 포트 8080 규칙 추가
aws ec2 authorize-security-group-ingress \
  --group-id "$ECS_SG" \
  --protocol tcp \
  --port 8080 \
  --source-group "$ALB_SG"
```

**검증**:
```bash
# Health Check 통과 확인
aws elbv2 describe-target-health \
  --target-group-arn <target-group-arn>
# 결과: State=healthy

# WebSocket 서비스 테스트
curl -s https://ws.glibiz.com/health | jq
# 결과: {"status":"ok","service":"gli-websocket","connections":0}
```

---

## 11. 체크리스트

### 11.1 배포 전 체크리스트

#### 개발 환경 배포 (dev)
- [ ] 로컬 테스트 완료
- [ ] 코드 리뷰 완료 (PR 승인)
- [ ] 단위 테스트 통과
- [ ] 린트 에러 없음

#### 스테이징 환경 배포 (stg)
- [ ] 개발 환경에서 기능 검증 완료
- [ ] 통합 테스트 계획 수립
- [ ] QA 팀 통보
- [ ] 데이터베이스 마이그레이션 검토

#### 프로덕션 환경 배포 (main)
- [ ] 스테이징에서 모든 테스트 통과
- [ ] 데이터베이스 백업 완료
- [ ] 롤백 계획 수립
- [ ] 배포 일정 팀원 공유
- [ ] 모니터링 대시보드 준비
- [ ] On-call 담당자 확인
- [ ] 배포 후 30분 모니터링 계획

---

### 11.2 배포 후 체크리스트

#### 즉시 확인 (배포 후 5분 이내)
- [ ] 배포 성공 확인 (GitHub Actions)
- [ ] ECS Task Running 상태 확인
- [ ] ALB Health Check 통과 확인
- [ ] 헬스 엔드포인트 응답 확인 (`/health`)

#### 단기 확인 (배포 후 30분)
- [ ] CloudWatch 에러 로그 모니터링
- [ ] API 응답 시간 정상 범위 확인
- [ ] 주요 기능 Smoke Test
- [ ] 사용자 피드백 모니터링 (CS 팀)

#### 장기 확인 (배포 후 24시간)
- [ ] 에러율 추이 확인
- [ ] 성능 메트릭 비교 (배포 전/후)
- [ ] 데이터베이스 부하 확인
- [ ] 비용 모니터링 (AWS Cost Explorer)

---

## 12. 부록

### 12.1 AWS 리소스 ARN 참조

#### ALB (Application Load Balancer)

| 환경 | ALB Name | ARN |
|------|----------|-----|
| Staging | gli-staging-alb | arn:aws:elasticloadbalancing:ap-northeast-2:917891822317:loadbalancer/app/gli-staging-alb/4b919751696a2d9d |
| Production | gli-production-alb | arn:aws:elasticloadbalancing:ap-northeast-2:917891822317:loadbalancer/app/gli-production-alb/4dd48a414b137281 |

#### Target Groups

| Name | ARN | Health Check Path |
|------|-----|-------------------|
| gli-stg-api-tg | arn:aws:elasticloadbalancing:ap-northeast-2:917891822317:targetgroup/gli-stg-api-tg/5f0499ae426668ca | /health/ |
| gli-stg-ws-tg | arn:aws:elasticloadbalancing:ap-northeast-2:917891822317:targetgroup/gli-stg-ws-tg/586551f254635e4a | /health |
| gli-prod-api-tg | arn:aws:elasticloadbalancing:ap-northeast-2:917891822317:targetgroup/gli-prod-api-tg/650e7e1476633a2f | /health/ |
| gli-prod-ws-tg | arn:aws:elasticloadbalancing:ap-northeast-2:917891822317:targetgroup/gli-prod-ws-tg/6619e0227a562cbc | /health |

#### ECS Clusters

| Environment | Cluster Name | ARN |
|-------------|--------------|-----|
| Staging | staging-gli-cluster | arn:aws:ecs:ap-northeast-2:917891822317:cluster/staging-gli-cluster |
| Production | production-gli-cluster | arn:aws:ecs:ap-northeast-2:917891822317:cluster/production-gli-cluster |

#### ECR Repositories

| Repository | URI |
|------------|-----|
| gli-api-staging | 917891822317.dkr.ecr.ap-northeast-2.amazonaws.com/gli-api-staging |
| gli-api-production | 917891822317.dkr.ecr.ap-northeast-2.amazonaws.com/gli-api-production |
| gli-websocket-staging | 917891822317.dkr.ecr.ap-northeast-2.amazonaws.com/gli-websocket-staging |
| gli-websocket-production | 917891822317.dkr.ecr.ap-northeast-2.amazonaws.com/gli-websocket-production |

#### AWS Secrets Manager

| Secret Name | ARN | Purpose |
|-------------|-----|---------|
| gli/db/staging | arn:aws:secretsmanager:ap-northeast-2:917891822317:secret:gli/db/staging-jnPMCP | Staging Database |
| gli/db/production | arn:aws:secretsmanager:ap-northeast-2:917891822317:secret:gli/db/production-u1ubhz | Production Database |

#### ACM Certificates

| Purpose | Region | ARN | Domains |
|---------|--------|-----|---------|
| ALB용 | ap-northeast-2 | arn:aws:acm:ap-northeast-2:917891822317:certificate/8590e8e6-1e73-4754-983f-b77ed18e3a82 | *.glibiz.com, glibiz.com |
| CloudFront용 | us-east-1 | arn:aws:acm:us-east-1:917891822317:certificate/8a143395-150a-40cf-b9e7-aacbbd3d2caf | *.glibiz.com, glibiz.com |

#### Route53 Hosted Zone

```
Hosted Zone ID: Z0419507IHNIDPFGXUPL
Domain: glibiz.com
```

#### CloudWatch Log Groups

| Log Group | Retention Period |
|-----------|------------------|
| /ecs/staging-gli-api | 30일 |
| /ecs/staging-gli-websocket | 30일 |
| /ecs/production-gli-api | 30일 |
| /ecs/production-gli-websocket | 30일 |

---

### 12.2 유용한 명령어

```bash
# ALB 상태 확인
aws elbv2 describe-load-balancers --region ap-northeast-2 \
  --query 'LoadBalancers[?contains(LoadBalancerName, `gli`)]'

# Target Group 헬스 확인
aws elbv2 describe-target-health \
  --target-group-arn <ARN> \
  --region ap-northeast-2

# ECS 서비스 목록
aws ecs list-services \
  --cluster staging-gli-cluster \
  --region ap-northeast-2

# ECS 서비스 상태 확인
aws ecs describe-services \
  --cluster production-gli-cluster \
  --services production-django-api-service \
  --region ap-northeast-2

# Route53 레코드 확인
aws route53 list-resource-record-sets \
  --hosted-zone-id Z0419507IHNIDPFGXUPL

# 로그 스트림 (실시간)
aws logs tail /ecs/staging-gli-api --follow --region ap-northeast-2

# ECR 이미지 목록
aws ecr list-images \
  --repository-name gli-api-production \
  --region ap-northeast-2

# ECS Task Definition 목록
aws ecs list-task-definitions \
  --family-prefix production-gli-django-api \
  --region ap-northeast-2

# Secrets Manager 값 조회
aws secretsmanager get-secret-value \
  --secret-id gli/db/production \
  --region ap-northeast-2

# S3 버킷 파일 목록
aws s3 ls s3://gli-user-frontend-staging/ --recursive

# CloudFront 캐시 무효화
aws cloudfront create-invalidation \
  --distribution-id <DISTRIBUTION_ID> \
  --paths "/*"
```

---

### 12.3 관련 문서

- [DEPLOYMENT_GUIDE_1of3.md](./DEPLOYMENT_GUIDE_1of3.md) - 배포 시스템 개요, 환경 구성, 브랜치 전략, 사전 준비
- [DEPLOYMENT_GUIDE_2of3.md](./DEPLOYMENT_GUIDE_2of3.md) - AWS 인프라, Secrets 및 환경 변수 관리
- [MULTIGIT_SCRIPTS_GUIDE.md](./MULTIGIT_SCRIPTS_GUIDE.md) - MultiGit 스크립트 상세 가이드
- [AWS ECS 공식 문서](https://docs.aws.amazon.com/ecs/)
- [GitHub Actions 문서](https://docs.github.com/en/actions)
- [Next.js 배포 가이드](https://nextjs.org/docs/deployment)
- [PostgreSQL 운영 가이드](https://www.postgresql.org/docs/)

---

### 12.4 문서 이력

| 버전 | 날짜 | 내용 | 작성자 |
|------|------|------|--------|
| 3.0 | 2025-10-15 | 3부작 통합 가이드 Part 3 작성 (배포 프로세스, GitHub Actions, 모니터링, 트러블슈팅) | DevOps 팀 |
| 2.0 | 2025-01-15 | 포괄적 단일 배포 가이드 확장 | DevOps 팀 |
| 1.0 | 2025-01-10 | 초기 배포 가이드 작성 | DevOps 팀 |

**문서 업데이트 정책**: 인프라 변경, 배포 프로세스 변경 시 이 문서도 함께 업데이트하세요.

**문서 검토 주기**: 분기별 (3개월마다) 리뷰 및 업데이트

---

**마지막 업데이트**: 2025-10-15
**작성자**: DevOps 팀
**검토자**: 개발팀 리드

