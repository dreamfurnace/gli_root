# GLI 프로젝트 AWS 인프라 배포 구조

> **작성일**: 2026-03-06
> **AWS 계정**: 917891822317 (GLI)
> **리전**: ap-northeast-2 (서울)
> **목적**: 모든 비용 발생 리소스의 철저한 파악 및 보안 점검

---

## 📊 인프라 요약

### 총 리소스 현황

| 카테고리 | 개수 | 비용 발생 | 비고 |
|---------|------|----------|------|
| **컴퓨팅** | - | - | - |
| EC2 인스턴스 | 0개 | ❌ | Fargate로 대체 |
| ECS Fargate 태스크 | 5개 실행 중 | ✅ 높음 | 24/7 실행 |
| Lambda 함수 | 0개 | ❌ | 미사용 |
| **데이터베이스** | - | - | - |
| RDS PostgreSQL | 2개 | ✅ 높음 | Production Multi-AZ |
| ElastiCache | 0개 | ❌ | 미사용 |
| **네트워킹** | - | - | - |
| ALB | 2개 | ✅ 중간 | Staging/Production |
| NAT Gateway | 0개 | ❌ | 미사용 |
| Elastic IP | 4개 | ✅ 낮음 | 모두 연결됨 |
| **스토리지** | - | - | - |
| S3 버킷 | 10개 | ✅ 중간 | 프론트엔드 + 미디어 |
| CloudFront | 5개 | ✅ 중간 | CDN 배포 |
| **컨테이너** | - | - | - |
| ECR 리포지토리 | 4개 | ✅ 낮음 | Docker 이미지 저장 |
| **기타** | - | - | - |
| Route53 호스팅 영역 | 3개 | ✅ 낮음 | 도메인 관리 |
| ACM 인증서 | 1개 | ❌ | 무료 |
| MQ 브로커 | 0개 | ❌ | 미사용 |

---

## 🖥️ 컴퓨팅 리소스

### ECS 클러스터 및 서비스

#### Production 클러스터 (production-gli-cluster)

| 서비스명 | 상태 | 원하는 개수 | 실행 중 | Launch Type | 비고 |
|---------|------|------------|---------|-------------|------|
| production-django-api-service | ACTIVE | 1 | 1 | FARGATE | Django REST API |
| production-websocket-service | ACTIVE | 2 | **3** | FARGATE | ⚠️ 설정값보다 1개 더 실행 중 |

**⚠️ 주의사항**:
- WebSocket 서비스가 원하는 개수(2)보다 1개 더 실행 중(3)입니다.
- 불필요한 태스크가 실행 중일 가능성이 있으니 확인이 필요합니다.

#### Staging 클러스터 (staging-gli-cluster)

| 서비스명 | 상태 | 원하는 개수 | 실행 중 | Launch Type | 비고 |
|---------|------|------------|---------|-------------|------|
| staging-django-api-service | ACTIVE | 1 | 1 | FARGATE | Django REST API |

**주의**: Staging에는 WebSocket 서비스가 없습니다.

---

## 🗄️ 데이터베이스

### RDS PostgreSQL 인스턴스

| 식별자 | 인스턴스 타입 | 엔진 | Multi-AZ | 상태 | 월 예상 비용 |
|--------|-------------|------|----------|------|-------------|
| **gli-db-production** | db.t3.medium | PostgreSQL 15.14 | ✅ Yes | available | ~$110/월 |
| **gli-db-staging** | db.t3.small | PostgreSQL 15.14 | ❌ No | available | ~$35/월 |

**비용 최적화 제안**:
- Production: Multi-AZ 구성으로 높은 가용성 확보 (적절함)
- Staging: Single-AZ로 비용 절감 (적절함)
- ⚠️ 백업 보관 기간 확인 필요 (스냅샷 비용 발생 가능)

---

## 🌐 네트워킹

### VPC 구조

| VPC ID | CIDR | 용도 | 타입 |
|--------|------|------|------|
| vpc-0f6b6085ab788e70e | 172.31.0.0/16 | 전체 인프라 | ⚠️ Default VPC |

**⚠️ 보안 경고**:
- **Default VPC를 사용 중입니다!**
- 프로덕션 환경에서는 Custom VPC 사용을 강력히 권장합니다.
- Default VPC는 보안 그룹 설정이 느슨할 수 있습니다.

### 서브넷 구조

| 서브넷 ID | CIDR | AZ | Public IP 자동 할당 |
|----------|------|-----|-------------------|
| subnet-0758222ee4b5ad2ad | 172.31.0.0/20 | ap-northeast-2a | ✅ Yes |
| subnet-023bfef05bbb2bf22 | 172.31.16.0/20 | ap-northeast-2b | ✅ Yes |
| subnet-06a560dd7aee5cb38 | 172.31.32.0/20 | ap-northeast-2c | ✅ Yes |
| subnet-00d832e84322dfdf1 | 172.31.48.0/20 | ap-northeast-2d | ✅ Yes |

**특징**:
- 4개의 Public 서브넷만 존재
- Private 서브넷 없음
- NAT Gateway 없음 (Private 서브넷이 없어서 불필요)

### Application Load Balancer (ALB)

| 이름 | 타입 | 접근 방식 | VPC | DNS 이름 |
|------|------|----------|-----|---------|
| **gli-staging-alb** | application | internet-facing | vpc-0f6b6085ab788e70e | gli-staging-alb-461879350.ap-northeast-2.elb.amazonaws.com |
| **gli-production-alb** | application | internet-facing | vpc-0f6b6085ab788e70e | gli-production-alb-1195676678.ap-northeast-2.elb.amazonaws.com |

**월 예상 비용**: ~$32/월 (2개 ALB x $16)

### Elastic IP

| Public IP | Allocation ID | Association ID | 상태 |
|-----------|--------------|----------------|------|
| 13.124.252.109 | eipalloc-0a2cfb15547c12055 | eipassoc-0a3719e8dd73d8225 | ✅ 연결됨 |
| 3.34.110.114 | eipalloc-09230a8a296779a36 | eipassoc-0803a44ce50ca57a3 | ✅ 연결됨 |
| 43.201.74.202 | eipalloc-01cd15470278b897c | eipassoc-0318f8ce9309295d9 | ✅ 연결됨 |
| 52.78.50.81 | eipalloc-05c37aedcfffd947f | eipassoc-0c15fb5830ad7aabf | ✅ 연결됨 |

**상태**: 모두 연결되어 있어 추가 비용 없음 (연결 안 된 EIP는 과금됨)

---

## 📦 스토리지 및 CDN

### S3 버킷 (10개)

#### 프론트엔드 버킷

| 버킷 이름 | 용도 | 생성일 |
|----------|------|--------|
| gli-admin-frontend-production | Admin 프로덕션 | 2025-11-07 |
| gli-admin-frontend-staging | Admin 스테이징 | 2025-11-07 |
| gli-user-frontend-production | User 프로덕션 | 2025-11-07 |
| gli-user-frontend-staging | User 스테이징 | 2025-11-07 |
| gligateway-user-frontend | Gateway User | 2025-11-27 |

#### 미디어 버킷

| 버킷 이름 | 용도 | 생성일 |
|----------|------|--------|
| gli-platform-media-production | 미디어 프로덕션 | 2025-10-16 |
| gli-platform-media-staging | 미디어 스테이징 | 2025-10-20 |
| gli-platform-media-prod | 미디어 (구버전?) | 2025-10-13 |
| gli-platform-media-dev | 미디어 개발 | 2025-10-13 |

#### 기타 버킷

| 버킷 이름 | 용도 | 생성일 |
|----------|------|--------|
| gli-staging-data-sync | 데이터 동기화 | 2026-02-06 |

**⚠️ 주의사항**:
- `gli-platform-media-prod`와 `gli-platform-media-production`이 중복될 가능성
- 구버전 버킷인지 확인 필요
- 불필요한 버킷 정리 권장

### CloudFront 배포 (5개)

| Distribution ID | CloudFront 도메인 | Origin (S3 버킷) | 상태 |
|----------------|------------------|-----------------|------|
| E2M2F8O36YCDX | dzoq5270b79br.cloudfront.net | gli-user-frontend-staging | Deployed |
| E1UMP4GMPQCQ0G | d3aube30ngvtmc.cloudfront.net | gli-admin-frontend-staging | Deployed |
| EUY0BEWJK212R | d31cze49ndidb5.cloudfront.net | gli-user-frontend-production | Deployed |
| E31LKUK6NABDLS | dlpg7ekfx6ygm.cloudfront.net | gli-admin-frontend-production | Deployed |
| E2BGSAPKUG20BY | d2p4dpu7oiyx5f.cloudfront.net | gligateway-user-frontend | Deployed |

**월 예상 비용**: 트래픽에 따라 변동 (최소 ~$10/월)

---

## 🐳 컨테이너 레지스트리

### ECR 리포지토리 (4개)

| 리포지토리 이름 | URI |
|---------------|-----|
| gli-api-staging | 917891822317.dkr.ecr.ap-northeast-2.amazonaws.com/gli-api-staging |
| gli-api-production | 917891822317.dkr.ecr.ap-northeast-2.amazonaws.com/gli-api-production |
| gli-websocket-staging | 917891822317.dkr.ecr.ap-northeast-2.amazonaws.com/gli-websocket-staging |
| gli-websocket-production | 917891822317.dkr.ecr.ap-northeast-2.amazonaws.com/gli-websocket-production |

**월 예상 비용**: ~$3-5/월 (이미지 스토리지 비용)

**최적화 제안**:
- 오래된 이미지 자동 삭제 라이프사이클 정책 설정 권장
- 최근 10개 이미지만 보관하도록 설정

---

## 🌍 도메인 및 DNS

### Route53 호스팅 영역 (3개)

| 도메인 | Hosted Zone ID | 레코드 개수 |
|--------|---------------|-----------|
| **glibiz.com** | /hostedzone/Z0419507IHNIDPFGXUPL | - |
| **dreamfurnace.im** | /hostedzone/Z085293812BRD5KW4Z3BO | - |
| **gligateway.com** | /hostedzone/Z07179351Q3GR4D9ET6RB | - |

**월 예상 비용**: ~$1.50/월 (3개 x $0.50)

### ACM 인증서 (1개)

| 도메인 | Certificate ARN |
|--------|----------------|
| glibiz.com | arn:aws:acm:ap-northeast-2:917891822317:certificate/8590e8e6-1e73-4754-983f-b77ed18e3a82 |

**비용**: 무료 (ACM 인증서는 무료)

**⚠️ 확인 필요**:
- dreamfurnace.im과 gligateway.com 도메인의 SSL 인증서 확인
- 추가 ACM 인증서가 필요한지 검토

---

## 💰 월별 예상 비용 분석

### 고정 비용 리소스

| 리소스 | 개수 | 단가 | 월 예상 비용 |
|--------|------|------|-------------|
| **RDS db.t3.medium (Multi-AZ)** | 1 | ~$110 | $110 |
| **RDS db.t3.small (Single-AZ)** | 1 | ~$35 | $35 |
| **ECS Fargate (Production API)** | 1 태스크 | ~$30 | $30 |
| **ECS Fargate (Production WebSocket)** | 3 태스크 | ~$30 x 3 | $90 |
| **ECS Fargate (Staging API)** | 1 태스크 | ~$30 | $30 |
| **ALB** | 2개 | $16 x 2 | $32 |
| **Route53 호스팅 영역** | 3개 | $0.50 x 3 | $1.50 |
| **Elastic IP (연결됨)** | 4개 | $0 | $0 |
| **ECR 스토리지** | - | - | $3-5 |

**월 고정 비용 합계**: **약 $331.50 - $333.50**

### 변동 비용 리소스

| 리소스 | 예상 비용 |
|--------|----------|
| **S3 스토리지** | $5-20/월 (저장량에 따라) |
| **S3 데이터 전송** | $5-30/월 (트래픽에 따라) |
| **CloudFront** | $10-50/월 (트래픽에 따라) |
| **데이터 전송 (ALB, RDS 등)** | $10-30/월 |

**월 변동 비용 합계**: **약 $30 - $130**

### 총 월 예상 비용

**총합**: **$361.50 - $463.50 / 월**

---

## 🚨 보안 및 최적화 권고사항

### 긴급 (High Priority)

1. **⚠️ Default VPC 사용 중단**
   - 현재 Default VPC (172.31.0.0/16)를 사용 중입니다.
   - Custom VPC로 마이그레이션하여 보안 강화 필요
   - Public/Private 서브넷 분리 권장

2. **⚠️ ECS WebSocket 태스크 개수 불일치**
   - Production WebSocket 서비스가 원하는 개수(2)보다 1개 더 실행 중(3)
   - 즉시 확인 및 조정 필요 (불필요한 비용 발생 중)

3. **⚠️ SSL 인증서 누락 확인**
   - glibiz.com만 ACM 인증서가 있음
   - dreamfurnace.im, gligateway.com의 SSL 인증서 확인 필요

### 중요 (Medium Priority)

4. **S3 버킷 중복 의심**
   - `gli-platform-media-prod`와 `gli-platform-media-production` 중복 가능성
   - 사용하지 않는 버킷 정리 권장

5. **ECR 라이프사이클 정책 미설정**
   - 오래된 Docker 이미지 자동 삭제 정책 설정 권장
   - 최근 10-20개 이미지만 보관하도록 설정

6. **RDS 백업 정책 확인**
   - 자동 백업 보관 기간 확인
   - 불필요한 스냅샷 정리 (비용 절감)

### 권장 (Low Priority)

7. **CloudWatch 로그 보관 기간 설정**
   - ECS 태스크 로그의 보관 기간 확인
   - 30일 이상 보관 시 비용 증가

8. **비용 알림 설정**
   - CloudWatch + SNS를 통한 비용 임계값 알림 설정
   - 월 $500 이상 시 알림 권장

9. **태그 정책 수립**
   - 모든 리소스에 일관된 태그 적용
   - Environment, Project, Owner 태그 필수

---

## 📋 미사용 리소스 확인

### 현재 사용하지 않는 AWS 서비스

다음 서비스들은 현재 GLI 프로젝트에서 사용하지 않습니다:

- ❌ EC2 인스턴스
- ❌ Lambda 함수
- ❌ ElastiCache (Redis/Memcached)
- ❌ Amazon MQ (RabbitMQ)
- ❌ NAT Gateway
- ❌ Elastic Beanstalk
- ❌ EBS 볼륨 (Fargate 사용)
- ❌ EBS 스냅샷

**확인 완료**: 위 서비스들로 인한 비용 발생 없음

---

## 🔍 해킹 리소스 점검 결과

### 의심스러운 리소스 없음

다음 항목들을 철저히 점검한 결과 의심스러운 리소스가 없습니다:

✅ **EC2 인스턴스**: 없음 (Fargate 사용)
✅ **Lambda 함수**: 없음
✅ **예상치 못한 ECS 태스크**: 없음 (WebSocket 1개 추가 실행 중 - 설정 확인 필요)
✅ **연결되지 않은 EIP**: 없음 (모두 연결됨)
✅ **NAT Gateway**: 없음
✅ **의심스러운 S3 버킷**: 없음 (모두 GLI 관련)
✅ **비정상적인 데이터 전송**: 확인 필요 (CloudWatch 모니터링)

### 추가 보안 점검 권장사항

1. **CloudTrail 로그 검토**
   - 최근 90일간의 API 호출 기록 검토
   - 승인되지 않은 계정의 활동 확인

2. **IAM 사용자 및 권한 검토**
   - 불필요한 IAM 사용자 제거
   - 과도한 권한 부여 여부 확인
   - MFA 설정 확인

3. **보안 그룹 규칙 검토**
   - 0.0.0.0/0로 열려 있는 포트 확인
   - 불필요한 인바운드 규칙 제거

4. **Cost Explorer 분석**
   - 최근 3개월 비용 추이 확인
   - 급격한 비용 증가 구간 분석

---

## 📊 비교: lawide 프로젝트 vs GLI 프로젝트

### 아키텍처 차이점

| 구분 | lawide | GLI |
|------|--------|-----|
| **VPC 구조** | Custom VPC (staging-lawide-vpc) | ⚠️ Default VPC |
| **서브넷 분리** | Public/Private 분리 | ❌ Public만 존재 |
| **NAT Gateway** | 있음 (Private 통신용) | ❌ 없음 |
| **베스천 호스트** | 있음 (EC2) | ❌ 없음 |
| **컴퓨팅** | ECS Fargate + EC2 혼합 | ECS Fargate만 사용 |
| **캐시** | ElastiCache Redis | ❌ 없음 (로컬 Redis?) |
| **메시지 큐** | Amazon MQ (RabbitMQ) | ❌ 없음 |
| **추가 서비스** | Milvus, Neo4j (EC2) | ❌ 없음 |
| **RAG API** | 별도 Internal ALB | ❌ 없음 |
| **Tax Frontend** | Elastic Beanstalk | ❌ 없음 |

### GLI 프로젝트의 특징

**장점**:
- ✅ 심플한 아키텍처 (관리 용이)
- ✅ Fargate만 사용하여 서버 관리 불필요
- ✅ 불필요한 서비스 미사용으로 비용 절감

**단점**:
- ⚠️ Default VPC 사용 (보안 취약)
- ⚠️ Private 서브넷 없음 (데이터베이스가 Public 서브넷에 노출될 위험)
- ⚠️ 캐시 서버 없음 (성능 저하 가능)
- ⚠️ 메시지 큐 없음 (비동기 처리 제한)

---

## ✅ 다음 단계 (Action Items)

### 즉시 실행 (이번 주)

1. ✅ AWS 인프라 현황 문서화 완료
2. ⬜ ECS WebSocket 서비스 태스크 개수 조정 (3개 → 2개)
3. ⬜ dreamfurnace.im, gligateway.com SSL 인증서 확인
4. ⬜ IAM 사용자 및 권한 검토

### 단기 실행 (이번 달)

5. ⬜ Custom VPC 마이그레이션 계획 수립
6. ⬜ S3 버킷 정리 (중복 버킷 제거)
7. ⬜ ECR 라이프사이클 정책 설정
8. ⬜ 비용 알림 설정 (CloudWatch + SNS)

### 중기 실행 (다음 달)

9. ⬜ Custom VPC로 마이그레이션
10. ⬜ Private 서브넷 구성
11. ⬜ RDS를 Private 서브넷으로 이동
12. ⬜ ElastiCache Redis 도입 검토

---

## 📝 참고 문서

- `CLAUDE.md` - GLI 프로젝트 메인 가이드
- `LOCAL_SERVICES_GUIDE.md` - 로컬 서비스 관리
- `DB_SYNC_GUIDE.md` - 데이터베이스 동기화
- `DEPLOYMENT_GUIDE_*.md` - 배포 가이드 시리즈

---

**작성자**: Claude Code (Sonnet 4.5)
**최종 수정**: 2026-03-06
