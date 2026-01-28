---
name: aws-gli
description: AWS GLI 계정(917891822317)의 EC2, S3, RDS, ECS, Lambda, CloudFormation 등 모든 AWS 리소스를 관리합니다. AWS CLI 명령어를 실행할 때 자동으로 GLI 계정으로 전환하여 안전한 작업을 보장합니다.
triggers:
  - AWS 관련 키워드 감지 시 (aws, ec2, s3, rds, ecs, lambda, cloudformation, ecr)
  - AWS 계정 정보 조회 요청
  - AWS 리소스 조회/수정 작업
  - GLI 인프라 관련 작업
auto_invoke: true
priority: critical
---

# AWS GLI 스킬

## 🎯 스킬 목적
모든 AWS CLI 명령을 GLI 계정(917891822317)에서 안전하게 실행하도록 자동 전환합니다.

## 🚨 자동 호출 트리거

**다음 키워드 감지 시 이 스킬을 반드시 먼저 호출:**
- `aws`, `AWS`, `아마존`
- `ec2`, `s3`, `rds`, `ecs`, `lambda`, `ecr`, `cloudformation`
- `계정 정보`, `연락처`, `전화번호` (AWS 관련)
- `ECS 서비스`, `컨테이너`, `태스크`
- `인스턴스`, `버킷`, `데이터베이스`

## ✅ 사용 전제 조건

### 필수 요구사항
- 로컬에 `aws` CLI 도구 설치
- 현재 터미널에서 AWS 계정 권한 확인

### 실행 전 자동 체크
- 반드시 GLI 계정 전환 스크립트 실행
- 모든 AWS CLI 명령어 앞에 `source AWS_switch-to-gli.sh &&` 자동 추가

## 📋 주요 기능

### 1. EC2 관리
- 인스턴스 조회/시작/중지
- 보안 그룹 관리
- 키페어 관리

### 2. S3 버킷
- 버킷 목록 조회
- 파일 업로드/다운로드
- 권한 및 정책 관리

### 3. RDS 관리
- 데이터베이스 인스턴스 조회
- 백업 관리
- 성능 모니터링

### 4. ECS/컨테이너 배포
- 클러스터 관리
- 서비스 배포
- 로그 조회

### 5. 기타 AWS 리소스
- Lambda 함수 관리
- CloudFormation 스택 관리
- IAM 사용자/역할 조회

## 🔧 명령어 실행 패턴

**⚠️ CRITICAL: 반드시 `source` 방식으로 실행하고 `&&` 연산자 사용**

모든 AWS CLI 명령어를 다음 형식으로 자동 래핑:

```bash
source AWS_switch-to-gli.sh && aws [명령어]
```

**중요:**
- ✅ `&&` 사용 (환경변수 유지 보장)
- ❌ `;` 사용 금지 (환경변수 전달 안 될 수 있음)
- ✅ `source` 명령 필수 (export된 환경변수를 현재 쉘에 적용)
- ❌ `./AWS_switch-to-gli.sh` 방식 금지 (서브쉘에서 실행되어 환경변수 소실)

## 📚 주요 예제

### EC2 인스턴스 목록 조회
```bash
source AWS_switch-to-gli.sh && aws ec2 describe-instances --query 'Reservations[*].Instances[*].[InstanceId,State.Name,InstanceType,Tags[?Key==`Name`].Value|[0]]' --output table
```

### S3 버킷 목록
```bash
source AWS_switch-to-gli.sh && aws s3 ls
```

### RDS 인스턴스 조회
```bash
source AWS_switch-to-gli.sh && aws rds describe-db-instances --query 'DBInstances[*].[DBInstanceIdentifier,DBInstanceStatus,Engine,DBInstanceClass]' --output table
```

### ECS 서비스 상태 확인
```bash
source AWS_switch-to-gli.sh && aws ecs list-clusters
source AWS_switch-to-gli.sh && aws ecs list-services --cluster [클러스터명]
```

### Lambda 함수 목록
```bash
source AWS_switch-to-gli.sh && aws lambda list-functions --query 'Functions[*].[FunctionName,Runtime,LastModified]' --output table
```

### AWS 계정 연락처 정보 조회
```bash
source AWS_switch-to-gli.sh && aws account get-contact-information
```

## ⚠️ 안전 규칙

1. **계정 확인**: 명령 실행 전 GLI 계정(917891822317) 전환 여부 자동 검증
2. **운영환경 보호**: 조회 명령만 허용, GLI 프로덕션 리소스 직접 수정 금지
3. **프로필 관리**: 안전한 터미널 세션 내에서만 명령 실행

## 🛠️ 실전 작업 예제

### 서비스 상태 진단
```bash
# 1. EC2 인스턴스 확인
source AWS_switch-to-gli.sh && aws ec2 describe-instances --filters "Name=instance-state-name,Values=running"

# 2. RDS 상태 확인
source AWS_switch-to-gli.sh && aws rds describe-db-instances

# 3. ECS 서비스 상태 확인
source AWS_switch-to-gli.sh && aws ecs describe-services --cluster [클러스터명] --services [서비스명]
```

### 배포 및 롤백 작업
```bash
# 1. ECR 이미지 확인
source AWS_switch-to-gli.sh && aws ecr describe-images --repository-name [레포지토리명]

# 2. ECS 서비스 강제 재배포
source AWS_switch-to-gli.sh && aws ecs update-service --cluster [클러스터명] --service [서비스명] --force-new-deployment

# 3. 배포 상태 모니터링
source AWS_switch-to-gli.sh && aws ecs describe-services --cluster [클러스터명] --services [서비스명]
```

## 🔍 트러블슈팅

만약 AWS CLI 명령 실행 시 다음 절차를 자동 수행:

1. **계정 확인**: `aws sts get-caller-identity`로 현재 계정 검증
2. **계정 전환**: `source AWS_switch-to-gli.sh` 스크립트 실행
3. **명령 재실행**: 계정 전환 후 원래 명령 실행

## 📌 중요사항

- **CRITICAL**: 모든 명령어 실행 시 `source AWS_switch-to-gli.sh &&` 접두사 자동 추가
- **CRITICAL**: 반드시 `&&` 연산자 사용 (`;` 사용 금지)
- **CRITICAL**: `source` 방식 필수 (`./` 실행 방식 금지)
- 다른 계정 전환 방지 - 항상 GLI 전용
- 운영 환경 보호
- 위험한 작업 실행 전 사용자 승인 요청
- 계정 불일치 시 즉시 사용자에게 경고

## 🚨 올바른 실행 패턴

✅ **CORRECT**:
```bash
source AWS_switch-to-gli.sh && aws s3 ls
```

❌ **WRONG**:
```bash
# 세미콜론 사용 (환경변수 소실 가능)
source AWS_switch-to-gli.sh; aws s3 ls

# 서브쉘 실행 (환경변수 소실)
./AWS_switch-to-gli.sh && aws s3 ls

# source 없이 직접 실행
aws s3 ls
```