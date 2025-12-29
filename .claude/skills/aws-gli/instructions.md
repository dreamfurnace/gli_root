# AWS GLI 스킬 실행 지침

## 🚨 핵심 규칙 (절대 준수)

사용자가 AWS CLI 작업을 요청하면 **반드시** 다음 형식으로 실행:

```bash
source AWS_switch-to-gli.sh; aws [명령어]
```

## ❌ 절대 금지 사항
- `aws [명령어]` (직접 실행)
- 다른 계정에서 AWS 작업
- GLI 계정 전환 없이 AWS 리소스 접근

## ✅ 올바른 실행 예시

### EC2 인스턴스 조회
```bash
source AWS_switch-to-gli.sh; aws ec2 describe-instances
```

### S3 버킷 목록 조회
```bash
source AWS_switch-to-gli.sh; aws s3 ls
```

### RDS 인스턴스 조회
```bash
source AWS_switch-to-gli.sh; aws rds describe-db-instances
```

## 🔍 안전 확인 절차

1. **계정 확인**: GLI 계정(917891822317) 사용 중인지 확인
2. **리소스 확인**: 올바른 GLI 리소스에 접근하는지 확인
3. **작업 실행**: 안전하게 확인된 후 작업 진행

## ⚠️ 경고 사항

만약 lawide 계정(424438300282)이 표시되면:
- 즉시 작업 중단
- GLI 계정 전환 재시도
- 안전 확인 후 재진행

## 🎯 목표

**GLI 프로젝트의 AWS 리소스만 안전하게 관리하여 다른 계정의 리소스 손상 방지**