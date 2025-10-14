# GLI 전체 배포 시스템 개요 (Deployment System Overview)

## 📋 목차
- [전체 아키텍처](#전체-아키텍처)
- [배포 워크플로우](#배포-워크플로우)
- [환경별 구성](#환경별-구성)
- [자동화 도구](#자동화-도구)
- [CI/CD 파이프라인](#cicd-파이프라인)
- [인프라 구성](#인프라-구성)
- [모니터링 및 로깅](#모니터링-및-로깅)
- [트러블슈팅](#트러블슈팅)

---

## 🏗️ 전체 아키텍처

### 시스템 구성
```
┌─────────────────┬─────────────────┬─────────────────┐
│   개발 환경      │   스테이징 환경   │   프로덕션 환경   │
│   (Development)  │   (Staging)      │   (Production)   │
├─────────────────┼─────────────────┼─────────────────┤
│ • 로컬 개발      │ • stg.glibiz.com│ • glibiz.com    │
│ • dev 브랜치     │ • stg 브랜치     │ • main 브랜치    │
│ • SQLite DB      │ • RDS Staging   │ • RDS Production│
└─────────────────┴─────────────────┴─────────────────┘
```

### 리포지토리 구성 (8개 서비스)
1. **gli_root** - 메인 설정 및 스크립트
2. **gli_api-server** - Django REST API 서버
3. **gli_user-frontend** - Vue.js 사용자 웹앱
4. **gli_admin-frontend** - Vue.js 관리자 대시보드
5. **gli_websocket** - WebSocket 실시간 통신 서버
6. **gli_database** - 데이터베이스 마이그레이션 및 스키마
7. **gli_redis** - Redis 캐시 및 세션 설정
8. **gli_rabbitmq** - 메시지 큐 설정

---

## 🔄 배포 워크플로우

### 1. 개발 → 스테이징 배포 (dev → stg)
```bash
# 1단계: multigit 머지 스크립트 실행
./multigit-merge-dev-to-stg.sh

# 처리 과정:
# ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
# │ dev 브랜치   │───▶│ stg 브랜치   │───▶│ 스테이징 배포 │
# │ (개발 완료)   │    │ (머지 완료)   │    │ (자동 시작)  │
# └─────────────┘    └─────────────┘    └─────────────┘
```

### 2. 스테이징 → 프로덕션 배포 (stg → main)
```bash
# 1단계: 사전 체크리스트 확인
# - 스테이징 환경 테스트 완료
# - 데이터베이스 마이그레이션 검토
# - API 엔드포인트 테스트
# - 프론트엔드 및 관리자 대시보드 테스트

# 2단계: 프로덕션 배포 실행
./multigit-merge-stg-to-main.sh

# 처리 과정:
# ┌─────────────┐    ┌─────────────┐    ┌─────────────┐
# │ stg 브랜치   │───▶│ main 브랜치  │───▶│ 프로덕션 배포 │
# │ (테스트 완료) │    │ (머지+태그)  │    │ (자동 시작)  │
# └─────────────┘    └─────────────┘    └─────────────┘
```

### 3. 배포 태그 시스템
- **자동 태그 생성**: `deploy-YYYYMMDD-HHMMSS` 형식
- **배포 로깅**: `deployment.log`에 모든 배포 기록
- **롤백 지원**: 태그 기반 빠른 롤백 가능

---

## 🌐 환경별 구성

### 개발 환경 (Development)
```yaml
브랜치: dev
데이터베이스: SQLite (로컬)
도메인: localhost:8000, localhost:3000
목적: 기능 개발 및 초기 테스트
```

### 스테이징 환경 (Staging)
```yaml
브랜치: stg
데이터베이스: RDS PostgreSQL (stg-gli-database)
도메인:
  - stg.glibiz.com (사용자 프론트엔드)
  - stg-api.glibiz.com (API 서버)
  - stg-admin.glibiz.com (관리자 대시보드)
  - stg-ws.glibiz.com (WebSocket 서버)
목적: 프로덕션 환경과 동일한 조건에서 최종 테스트
```

### 프로덕션 환경 (Production)
```yaml
브랜치: main
데이터베이스: RDS PostgreSQL (prod-gli-database)
도메인:
  - glibiz.com (사용자 프론트엔드)
  - api.glibiz.com (API 서버)
  - admin.glibiz.com (관리자 대시보드)
  - ws.glibiz.com (WebSocket 서버)
목적: 실제 서비스 운영
```

---

## 🔧 자동화 도구

### MultiGit 스크립트 시리즈

#### 브랜치 관리
- **`multigit-pull-dev.sh`** - 모든 리포지토리의 dev 브랜치 최신화
- **`multigit-pull-stg.sh`** - 모든 리포지토리의 stg 브랜치 최신화
- **`multigit-pull-main.sh`** - 모든 리포지토리의 main 브랜치 최신화

#### 브랜치 간 머지 (배포 트리거)
- **`multigit-merge-dev-to-stg.sh`** ⭐ - 스테이징 배포 실행
  - dev → stg 머지 및 푸시
  - 스테이징 환경 자동 배포 시작
  - 안전성 확인 프롬프트 포함

- **`multigit-merge-stg-to-main.sh`** ⭐ - 프로덕션 배포 실행
  - stg → main 머지 및 푸시
  - 배포 태그 자동 생성
  - 2중 안전 확인 프롬프트
  - 배포 후 체크리스트 제공

#### 직접 푸시 (긴급 배포)
- **`multigit-push-stg.sh`** - stg 브랜치 직접 푸시 (긴급 스테이징 배포)
- **`multigit-push-main.sh`** - main 브랜치 직접 푸시 (긴급 프로덕션 배포)

#### 역방향 머지 (핫픽스 반영)
- **`multigit-merge-main-to-stg.sh`** - 프로덕션 핫픽스를 스테이징에 반영
- **`multigit-merge-stg-to-dev.sh`** - 스테이징 변경사항을 개발 브랜치에 반영

---

## 🚀 CI/CD 파이프라인

### GitHub Actions 워크플로우

#### API 서버 배포 (`gli_api-server/.github/workflows/deploy-staging.yml`)
```yaml
트리거: stg/main 브랜치 push
단계:
  1. 코드 체크아웃
  2. Python 환경 설정
  3. 의존성 설치 및 테스트
  4. Docker 이미지 빌드
  5. ECR 업로드
  6. ECS 서비스 업데이트
  7. 데이터베이스 마이그레이션
  8. 헬스체크 실행
```

#### 프론트엔드 배포 (`gli_user-frontend/.github/workflows/deploy-staging.yml`)
```yaml
트리거: stg/main 브랜치 push
단계:
  1. 코드 체크아웃
  2. Node.js 환경 설정
  3. 의존성 설치 및 빌드
  4. S3 업로드
  5. CloudFront 캐시 무효화
  6. 배포 완료 확인
```

#### WebSocket 서버 배포 (`gli_websocket/.github/workflows/deploy-staging.yml`)
```yaml
트리거: stg/main 브랜치 push
단계:
  1. 코드 체크아웃
  2. Node.js 환경 설정
  3. Docker 이미지 빌드
  4. ECR 업로드
  5. ECS 서비스 업데이트
  6. 연결 테스트
```

### 배포 프로세스 흐름
```
Git Push → GitHub Actions → Docker Build → ECR → ECS/S3 → 배포 완료
     ↓           ↓             ↓          ↓       ↓         ↓
   트리거    빌드/테스트    이미지 생성   업로드   서비스 업데이트  검증
```

---

## ☁️ 인프라 구성

### AWS 서비스 활용

#### 컴퓨팅 리소스
- **Amazon ECS (Fargate)** - 컨테이너 오케스트레이션
  - gli-api-cluster (API 서버)
  - gli-websocket-cluster (WebSocket 서버)
- **Amazon EC2** - 필요시 직접 서버 관리

#### 스토리지 및 데이터베이스
- **Amazon RDS (PostgreSQL)** - 메인 데이터베이스
  - stg-gli-database (스테이징)
  - prod-gli-database (프로덕션)
- **Amazon S3** - 정적 파일 및 프론트엔드 호스팅
- **Amazon ElastiCache (Redis)** - 캐시 및 세션 관리

#### 네트워킹 및 배포
- **Amazon CloudFront** - CDN 및 프론트엔드 배포
- **Application Load Balancer** - 트래픽 분산
- **Amazon Route 53** - DNS 관리

#### 보안 및 모니터링
- **AWS Secrets Manager** - 민감 정보 관리
- **Amazon CloudWatch** - 로그 및 모니터링
- **AWS IAM** - 접근 권한 관리

### 인프라 프로비저닝
```bash
# AWS 인프라 자동 설정
./setup-aws-infrastructure.sh

# 생성되는 리소스:
# - ECR 리포지토리 (gli-api, gli-websocket, gli-admin)
# - ECS 클러스터 및 서비스
# - S3 버킷 (프론트엔드 호스팅)
# - CloudWatch 로그 그룹
# - 보안 그룹 및 IAM 역할
```

---

## 📊 모니터링 및 로깅

### CloudWatch 로깅
```
로그 그룹 구성:
├── /gli/api-server/staging
├── /gli/api-server/production
├── /gli/websocket/staging
├── /gli/websocket/production
├── /gli/user-frontend/staging
└── /gli/user-frontend/production
```

### 메트릭 수집
- **애플리케이션 성능**: 응답 시간, 에러율, 처리량
- **인프라 성능**: CPU, 메모리, 네트워크 사용량
- **사용자 메트릭**: 접속자 수, 페이지 뷰, API 호출량

### 알림 설정
- **에러 임계치 초과** → Slack/Email 알림
- **서비스 다운** → 즉시 알림
- **리소스 사용량 임계치** → 스케일링 트리거

---

## 🔧 트러블슈팅

### 배포 실패 대응

#### 1. 머지 충돌 해결
```bash
# 충돌 발생 시
cd 해당_리포지토리
git status
# 충돌 파일 수동 해결 후
git add .
git commit
git push origin 브랜치명
```

#### 2. GitHub Actions 실패
- **빌드 실패**: 로그 확인 후 코드 수정
- **테스트 실패**: 테스트 케이스 점검
- **배포 실패**: AWS 권한 및 리소스 상태 확인

#### 3. 롤백 실행
```bash
# 프로덕션 긴급 롤백
git checkout main
git reset --hard 이전_커밋_해시
git push origin main --force-with-lease

# 또는 태그 기반 롤백
git checkout main
git reset --hard deploy-YYYYMMDD-HHMMSS
git push origin main --force-with-lease
```

### 일반적인 문제 해결

#### 데이터베이스 연결 실패
- RDS 보안 그룹 설정 확인
- Secrets Manager 자격 증명 확인
- VPC 및 서브넷 설정 점검

#### 정적 파일 로딩 실패
- S3 버킷 정책 확인
- CloudFront 캐시 무효화
- CORS 설정 점검

#### WebSocket 연결 실패
- ECS 서비스 상태 확인
- 로드 밸런서 헬스체크
- 방화벽 및 보안 그룹 설정

---

## 📚 관련 문서

- [`DEPLOYMENT_GUIDE.md`](./DEPLOYMENT_GUIDE.md) - 기본 배포 가이드
- [`INFRASTRUCTURE_STATUS.md`](./INFRASTRUCTURE_STATUS.md) - 인프라 현황
- [`MULTIGIT_SCRIPTS.md`](./MULTIGIT_SCRIPTS.md) - MultiGit 스크립트 상세 사용법

---

## ⚡ 빠른 참조

### 일반적인 배포 시나리오

#### 📝 일반 기능 배포
```bash
# 1. 개발 완료 후 스테이징 배포
./multigit-merge-dev-to-stg.sh

# 2. 스테이징 테스트 완료 후 프로덕션 배포
./multigit-merge-stg-to-main.sh
```

#### 🚨 긴급 배포 (핫픽스)
```bash
# 스테이징 우회 긴급 배포
./multigit-push-main.sh "긴급 수정: 보안 패치 적용"

# 이후 다른 브랜치에 변경사항 반영
./multigit-merge-main-to-stg.sh
./multigit-merge-stg-to-dev.sh
```

#### 🔧 환경별 브랜치 최신화
```bash
# 작업 시작 전 브랜치 최신화
./multigit-pull-dev.sh    # 개발 환경
./multigit-pull-stg.sh    # 스테이징 환경
./multigit-pull-main.sh   # 프로덕션 환경
```

---

*이 문서는 GLI 프로젝트의 전체 배포 시스템을 개괄한 가이드입니다. 구체적인 설정 방법은 각 관련 문서를 참조하세요.*