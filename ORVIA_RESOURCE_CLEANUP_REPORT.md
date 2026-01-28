# ORVIA 리소스 정리 리포트
**생성일**: 2025-12-30
**분석 대상**: GLI 계정 (917891822317) vs ORVIA 계정 (928102490965)

---

## 🔍 핵심 발견사항

### GLI 계정에 ORVIA 리소스가 존재한 이유
- **과거**: ORVIA 프로젝트가 초기에 GLI 계정에서 시작되었을 가능성
- **현재**: ORVIA 프로젝트가 독립 계정 (928102490965)으로 이전 완료
- **문제**: GLI 계정에 **유령 CloudFront**만 남아있음 (S3 버킷은 이미 삭제됨)

---

## 📊 GLI 계정 (917891822317) - ORVIA 리소스 상태

### 정리 전
| 리소스 유형 | 리소스명 | 상태 | 문제점 |
|------------|---------|------|--------|
| CloudFront | E165PI4XK3CAYE | Disabled | orvia-admin-frontend-stg 참조 (버킷 없음) |
| CloudFront | E19XNWKSZP3IW5 | Disabled | orvia-user-frontend-stg 참조 (버킷 없음) |
| CloudFront | E3GQMDTRW3NGVU | Enabled | orvia-admin-frontend-staging 참조 (버킷 없음) |
| CloudFront | ESKCQ7Z83HULV | Enabled | orvia-user-frontend-staging 참조 (버킷 없음) |
| S3 | orvia-admin-frontend-staging | ❌ **존재하지 않음** | - |
| S3 | orvia-user-frontend-staging | ❌ **존재하지 않음** | - |
| S3 | orvia-admin-frontend-stg | ❌ **존재하지 않음** | - |
| S3 | orvia-user-frontend-stg | ❌ **존재하지 않음** | - |

### 정리 작업
✅ **완료**:
- CloudFront E165PI4XK3CAYE (Disabled) → **삭제 완료**
- CloudFront E19XNWKSZP3IW5 (Disabled) → **삭제 완료**
- CloudFront E3GQMDTRW3NGVU (Enabled) → **비활성화 진행 중** (InProgress)
- CloudFront ESKCQ7Z83HULV (Enabled) → **비활성화 진행 중** (InProgress)

⏳ **대기 중**:
- CloudFront E3GQMDTRW3NGVU → 배포 완료 후 삭제 (5-15분 소요)
- CloudFront ESKCQ7Z83HULV → 배포 완료 후 삭제 (5-15분 소요)

### 정리 후 (예상)
- ✅ ORVIA 관련 리소스 **완전 제거**
- 💰 월 비용 절감: **약 $1-2** (CloudFront 요청 비용)

---

## 📊 ORVIA 계정 (928102490965) - 실제 운영 리소스

### 리소스 구성

#### Staging 환경
| 리소스 유형 | 리소스명 | 상태 | 역할 |
|------------|---------|------|------|
| **ECS Cluster** | staging-orvia-cluster | ✅ 정상 | 컨테이너 오케스트레이션 |
| **RDS** | orvia-db-staging | ✅ 정상 | PostgreSQL (db.t3.micro) |
| **ALB** | orvia-staging-alb | ✅ 정상 | 로드 밸런서 |
| **S3** | orvia-admin-frontend-2-stg | ✅ 정상 | Admin 프론트엔드 |
| **S3** | orvia-user-frontend-2-stg | ✅ 정상 | User 프론트엔드 |
| **S3** | orvia-platform-media-dev | ✅ 정상 | 개발 미디어 |
| **S3** | orvia-platform-media-staging | ✅ 정상 | 스테이징 미디어 |
| **CloudFront** | E3P79URG5FRBLE | ✅ 활성 | Admin Frontend CDN |
| **CloudFront** | E2HHM823ZTT1AB | ✅ 활성 | User Frontend CDN |

#### Production 환경
| 리소스 유형 | 리소스명 | 상태 | 역할 |
|------------|---------|------|------|
| **ECS Cluster** | production-orvia-cluster | ✅ 정상 | 컨테이너 오케스트레이션 |
| **RDS** | orvia-db-production | ✅ 정상 | PostgreSQL (db.t3.micro) |
| **S3** | orvia-admin-frontend-prod | ✅ 정상 | Admin 프론트엔드 |
| **S3** | orvia-user-frontend-prod | ✅ 정상 | User 프론트엔드 |
| **S3** | orvia-platform-media-production | ✅ 정상 | 프로덕션 미디어 |
| **CloudFront** | E2FU9ICU8NOJR2 | ✅ 활성 | User Frontend CDN |
| **CloudFront** | E1FG2ISDTHO6N8 | ✅ 활성 | Admin Frontend CDN |

### 12월 비용 분석 (ORVIA 계정)
**총 비용**: 약 **$128**

| 서비스 | 비용 | 비율 |
|--------|------|------|
| RDS | $42 | 33% |
| ECS (Fargate) | $38 | 30% |
| VPC (NAT Gateway) | $20 | 16% |
| ALB | $15 | 12% |
| Tax | $12 | 9% |
| 기타 (Route53, Secrets, ECR, S3, CloudFront) | $1 | <1% |

---

## 🔄 리소스 이전 타임라인 (추정)

### 과거 (2025년 초반?)
```
GLI 계정 (917891822317)
├── ORVIA CloudFront 배포
├── ORVIA S3 버킷
└── ORVIA 프로젝트 운영
```

### 이전 작업 (2025년 중반?)
```
1. ORVIA 독립 계정 생성 (928102490965)
2. ORVIA 리소스를 새 계정으로 이전
   - S3 버킷 생성 및 데이터 마이그레이션
   - CloudFront 재생성
   - RDS, ECS 등 인프라 재구축
3. GLI 계정의 ORVIA S3 버킷 삭제
4. ❌ **실수**: GLI 계정의 CloudFront는 삭제하지 않음
```

### 현재 (2025-12-30)
```
GLI 계정: 유령 CloudFront만 남음 (S3 없음)
ORVIA 계정: 모든 리소스 정상 운영 중
```

---

## ✅ 완료된 정리 작업

### GLI 계정 ORVIA 리소스 제거
1. ✅ **Disabled CloudFront 2개 삭제**
   - E165PI4XK3CAYE (ORVIA Admin Frontend Staging)
   - E19XNWKSZP3IW5 (ORVIA User Frontend Staging)

2. ✅ **Enabled CloudFront 2개 비활성화**
   - E3GQMDTRW3NGVU → InProgress (배포 후 삭제 예정)
   - ESKCQ7Z83HULV → InProgress (배포 후 삭제 예정)

3. ✅ **S3 버킷 확인**
   - orvia-* 버킷들이 GLI 계정에 존재하지 않음을 확인
   - 이미 삭제되었거나 ORVIA 계정으로 이전 완료

---

## 📋 남은 작업

### GLI 계정 (즉시)
- ⏳ CloudFront E3GQMDTRW3NGVU 배포 완료 대기 → 삭제
- ⏳ CloudFront ESKCQ7Z83HULV 배포 완료 대기 → 삭제

**삭제 명령어 (배포 완료 후 실행)**:
```bash
cd /Users/ahndonghyun/dongfiles/ADHcode/DreamFurnace/gli_root
source ./AWS_switch-to-gli.sh

# E3GQMDTRW3NGVU 삭제
ETAG=$(aws cloudfront get-distribution --id E3GQMDTRW3NGVU --query 'ETag' --output text)
aws cloudfront delete-distribution --id E3GQMDTRW3NGVU --if-match "$ETAG"

# ESKCQ7Z83HULV 삭제
ETAG=$(aws cloudfront get-distribution --id ESKCQ7Z83HULV --query 'ETag' --output text)
aws cloudfront delete-distribution --id ESKCQ7Z83HULV --if-match "$ETAG"
```

### ORVIA 계정 (검토 필요)
- ✅ 모든 리소스 정상 운영 중
- ❌ 정리 필요 없음

---

## 💰 비용 영향

### GLI 계정
- **절감 예상**: 월 $1-2 (CloudFront 요청 비용 제거)
- **중요도**: 낮음 (이미 S3 버킷이 없어 실제 요청 거의 없음)

### ORVIA 계정
- **영향 없음**: 정상 운영 유지
- **월 비용**: 약 $128 (정상 범위)

---

## 🎯 권장사항

### 단기 (24시간 내)
1. ✅ GLI 계정의 나머지 ORVIA CloudFront 2개 삭제 완료

### 중기 (1주일 내)
1. ORVIA 계정 비용 최적화 검토
   - VPC NAT Gateway ($20/월) → NAT Instance로 변경 검토
   - RDS db.t3.micro 사용량 모니터링

### 장기
1. AWS 계정 분리 정책 문서화
   - 프로젝트별 독립 계정 운영 기준
   - 리소스 이전 시 체크리스트 작성

---

## 📞 계정 정보

### GLI 계정
- **계정 ID**: 917891822317
- **IAM User**: gli
- **리전**: ap-northeast-2 (Seoul)

### ORVIA 계정
- **계정 ID**: 928102490965
- **IAM User**: nddmt
- **리전**: ap-northeast-2 (Seoul)

---

**작성자**: Claude Code
**마지막 업데이트**: 2025-12-30 01:00 KST
