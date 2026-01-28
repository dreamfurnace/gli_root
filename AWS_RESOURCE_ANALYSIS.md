# AWS 리소스 전체 분석 리포트
**생성일**: 2025-12-30
**AWS 계정**: 917891822317 (GLI)
**분석 기간**: 2025년 12월

---

## 🚨 긴급 조치 완료 사항

### 1. 해킹 탐지 및 제거 ✅
- **발견**: EC2 인스턴스 3개 (c5a.16xlarge, c5a.24xlarge x2)
  - 생성일: 2025-12-21
  - 생성 IP: 109.236.63.122 (유출된 액세스 키 사용)
  - CPU 사용률: 99% (비트코인 채굴 추정)
- **조치 완료**:
  - ✅ EC2 인스턴스 3개 삭제 완료 (terminated)
  - ✅ 유출된 액세스 키 (AKIA5LNU5WLWUA55GAOG) 삭제 완료
  - ✅ 새 액세스 키 (AKIA5LNU5WLW2J277U4O) 생성 및 적용
  - ✅ 해킹으로 인한 비용: 약 $769 (12월 EC2 비용의 대부분)

### 2. AWS 계정 블록 상태
- **현재 상태**: 계정 블록됨 ("your account is currently blocked")
- **영향**: ECS 태스크 생성 불가 → Staging/Production API 서비스 다운
- **원인**: 해킹으로 인한 비정상적인 리소스 사용
- **조치 필요**: AWS Support에 계정 블록 해제 요청 (진행 중)

---

## 📊 12월 비용 분석 (총 $1,310)

| 서비스 | 비용 | 비율 | 비고 |
|--------|------|------|------|
| **EC2** | **$769** | **59%** | 🚨 **해킹된 인스턴스 포함** |
| RDS | $194 | 15% | Production (t3.medium) + Staging (t3.small) |
| ECS | $141 | 11% | Fargate 컴퓨팅 비용 |
| Tax | $119 | 9% | VAT 10% |
| VPC | $42 | 3% | NAT Gateway 또는 VPC 엔드포인트 |
| ALB | $30 | 2% | Staging + Production |
| 기타 | $15 | 1% | Route53, Secrets Manager, ECR, S3 등 |

**정상 운영 예상 비용**: 약 $541/월 (해킹 비용 $769 제외)

---

## 🏗️ 프로젝트별 리소스 구분

### 1️⃣ **GLI Biz (gli_root) - 메인 프로젝트**

#### **Staging 환경**
| 리소스 유형 | 리소스명 | 상태 | 역할 |
|------------|---------|------|------|
| **ECS Cluster** | staging-gli-cluster | 🔴 블록됨 | 컨테이너 오케스트레이션 |
| **ECS Service** | staging-django-api-service | 🔴 다운 (0/1) | Django REST API |
| **RDS** | gli-db-staging | ✅ 정상 | PostgreSQL (t3.small, 20GB) |
| **ALB** | gli-staging-alb | ✅ 정상 | 로드 밸런서 |
| **S3** | gli-user-frontend-staging | ✅ 정상 | User 웹 프론트엔드 정적 파일 |
| **S3** | gli-admin-frontend-staging | ✅ 정상 | Admin 웹 프론트엔드 정적 파일 |
| **S3** | gli-platform-media-staging | ✅ 정상 | 미디어 파일 (238MB, 236 objects) |
| **CloudFront** | E2M2F8O36YCDX | ✅ 정상 | User Frontend CDN |
| **CloudFront** | E1UMP4GMPQCQ0G | ✅ 정상 | Admin Frontend CDN |

**Staging 주요 엔드포인트**:
- API: `https://stg-api.glibiz.com` (🔴 다운)
- User Frontend: `dzoq5270b79br.cloudfront.net`
- Admin Frontend: `d3aube30ngvtmc.cloudfront.net`

#### **Production 환경**
| 리소스 유형 | 리소스명 | 상태 | 역할 |
|------------|---------|------|------|
| **ECS Cluster** | production-gli-cluster | 🔴 블록됨 | 컨테이너 오케스트레이션 |
| **ECS Service** | production-django-api-service | 🔴 다운 (0/1) | Django REST API |
| **ECS Service** | production-websocket-service | ✅ 정상 (2/2) | WebSocket 서버 |
| **RDS** | gli-db-production | ✅ 정상 | PostgreSQL (t3.medium, 20GB, Multi-AZ) |
| **ALB** | gli-production-alb | ✅ 정상 | 로드 밸런서 |
| **S3** | gli-user-frontend-production | ✅ 정상 | User 웹 프론트엔드 정적 파일 |
| **S3** | gli-admin-frontend-production | ✅ 정상 | Admin 웹 프론트엔드 정적 파일 |
| **S3** | gli-platform-media-production | ✅ 정상 | 미디어 파일 (0 objects) |
| **CloudFront** | EUY0BEWJK212R | ✅ 정상 | User Frontend CDN |
| **CloudFront** | E31LKUK6NABDLS | ✅ 정상 | Admin Frontend CDN |

**Production 주요 엔드포인트**:
- API: `https://api.glibiz.com` (🔴 다운)
- User Frontend: `d31cze49ndidb5.cloudfront.net`
- Admin Frontend: `dlpg7ekfx6ygm.cloudfront.net`

---

### 2️⃣ **GLI Gateway (gligateway) - 랜딩 페이지**

| 리소스 유형 | 리소스명 | 상태 | 역할 |
|------------|---------|------|------|
| **S3** | gligateway-user-frontend | ✅ 정상 | 정적 웹사이트 호스팅 (56MB, 72 objects) |
| **CloudFront** | E2BGSAPKUG20BY | ✅ 정상 | CDN 배포 |

**엔드포인트**:
- CloudFront: `d2p4dpu7oiyx5f.cloudfront.net`
- 도메인: `https://gligateway.com` (추정)

**역할**: GLI Biz 서비스 소개 및 마케팅 랜딩 페이지

---

### 3️⃣ **기타 프로젝트 (삭제 검토 대상)**

#### **ORVIA 프로젝트** (사용 여부 불명)
| 리소스 유형 | 리소스명 | 상태 | 조치 제안 |
|------------|---------|------|----------|
| **S3** | orvia-user-frontend-staging | ✅ 활성 | 🟡 사용 여부 확인 후 삭제 검토 |
| **S3** | orvia-admin-frontend-staging | ✅ 활성 | 🟡 사용 여부 확인 후 삭제 검토 |
| **S3** | orvia-user-frontend-stg | ✅ 활성 | 🟡 중복 버킷? 삭제 검토 |
| **S3** | orvia-admin-frontend-stg | ✅ 활성 | 🟡 중복 버킷? 삭제 검토 |
| **CloudFront** | E3GQMDTRW3NGVU | ✅ Enabled | 🟡 비활성화 검토 |
| **CloudFront** | ESKCQ7Z83HULV | ✅ Enabled | 🟡 비활성화 검토 |
| **CloudFront** | E165PI4XK3CAYE | ❌ Disabled | ✅ 삭제 가능 |
| **CloudFront** | E19XNWKSZP3IW5 | ❌ Disabled | ✅ 삭제 가능 |

#### **King2Do 프로젝트** (사용 여부 불명)
| 리소스 유형 | 리소스명 | 상태 | 조치 제안 |
|------------|---------|------|----------|
| **S3** | king2do-web-frontend-stg | ✅ 활성 | 🟡 사용 여부 확인 후 삭제 검토 |
| **CloudFront** | E3FUKLMF8LPLSQ | ✅ Enabled | 🟡 비활성화 검토 |

---

## 🔧 공통 인프라

| 리소스 유형 | 리소스명 | 역할 |
|------------|---------|------|
| **VPC** | vpc-0f6b6085ab788e70e | Default VPC (172.31.0.0/16) |
| **IAM User** | gli | AdministratorAccess |
| **Route 53** | (도메인 정보 필요) | DNS 관리 |
| **Secrets Manager** | gli/db/staging, gli/db/production | DB 자격증명 저장 |
| **ECR** | gli-api-staging, gli-api-production | Docker 이미지 저장소 |

---

## 💰 비용 절감 제안

### 즉시 실행 가능 (월 $5-10 절감)
1. ✅ **해킹된 EC2 인스턴스 삭제** - 완료
2. ✅ **유출된 액세스 키 삭제** - 완료
3. ❌ **ORVIA Disabled CloudFront 배포 2개 삭제**
   - E165PI4XK3CAYE, E19XNWKSZP3IW5
4. ❌ **사용하지 않는 S3 버킷 삭제**
   - orvia-*, king2do-* (사용 여부 확인 필요)

### 중기 검토 사항 (월 $50-100 절감 가능)
1. **RDS Production t3.medium → t3.small 다운그레이드** (월 $50 절감)
   - 현재 사용량 확인 후 결정
2. **ECS Fargate 리소스 최적화**
   - CPU/메모리 사용률 분석 후 적정 크기 조정
3. **S3 Lifecycle 정책 적용**
   - 오래된 미디어 파일 Glacier로 이동
4. **CloudWatch Logs 보존 기간 단축**
   - 90일 → 30일

---

## ⚠️ 현재 긴급 이슈

### 🔴 Critical - 서비스 다운
1. **Staging Django API**: `stg-api.glibiz.com` - 503 Error
   - 원인: AWS 계정 블록으로 ECS 태스크 생성 불가
   - 조치: AWS Support 계정 블록 해제 대기 중

2. **Production Django API**: `api.glibiz.com` - 503 Error (추정)
   - 원인: AWS 계정 블록으로 ECS 태스크 생성 불가
   - 조치: AWS Support 계정 블록 해제 대기 중

### 🟡 Warning - 보안
1. **액세스 키 유출 사후 조치**
   - ✅ 유출된 키 삭제 완료
   - ✅ 새 키 생성 및 적용 완료
   - ❌ GitHub Secrets 업데이트 필요 (CI/CD)
   - ❌ 로컬 환경 키 업데이트 확인

2. **보안 강화 권장사항**
   - MFA 활성화 (IAM User)
   - IAM Role 기반 권한 전환 (액세스 키 대신)
   - CloudTrail 활성화 (감사 로그)
   - GuardDuty 활성화 (위협 탐지)

---

## 📋 다음 조치 사항

### 긴급 (24시간 내)
1. ⏳ **AWS Support에 계정 블록 해제 요청** - 진행 중
2. ❌ **GitHub Actions Secrets 업데이트**
   - AWS_ACCESS_KEY_ID: AKIA5LNU5WLW2J277U4O
   - AWS_SECRET_ACCESS_KEY: (새로 생성된 키)
3. ❌ **계정 블록 해제 후 서비스 복구 확인**
   - Staging/Production Django API
   - ECS 태스크 정상 실행 확인

### 단기 (1주일 내)
1. ❌ **ORVIA/King2Do 리소스 사용 여부 확인**
2. ❌ **미사용 리소스 삭제**
3. ❌ **보안 강화 (MFA, CloudTrail, GuardDuty)**
4. ❌ **비용 알림 설정** (월 $600 초과 시)

### 중기 (1개월 내)
1. ❌ **RDS 크기 최적화 검토**
2. ❌ **ECS Fargate 리소스 최적화**
3. ❌ **S3 Lifecycle 정책 적용**
4. ❌ **IAM Role 기반 권한 전환**

---

## 📞 지원 연락처

- **AWS Support**: https://console.aws.amazon.com/support
- **계정 블록 해제 케이스**: (케이스 번호 추가 필요)
- **긴급 연락처**: ahn+gli@dreamfurnace.im

---

**작성자**: Claude Code
**마지막 업데이트**: 2025-12-30 00:30 KST
