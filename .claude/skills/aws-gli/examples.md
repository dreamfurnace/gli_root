# AWS GLI 스킬 사용 예시

## 💡 일반적인 사용 패턴

### 1. EC2 관리
```bash
# 인스턴스 목록 조회
source AWS_switch-to-gli.sh && aws ec2 describe-instances

# 특정 인스턴스 상태 확인
source AWS_switch-to-gli.sh && aws ec2 describe-instances --instance-ids i-1234567890abcdef0

# 인스턴스 시작/정지
source AWS_switch-to-gli.sh && aws ec2 start-instances --instance-ids i-1234567890abcdef0
source AWS_switch-to-gli.sh && aws ec2 stop-instances --instance-ids i-1234567890abcdef0
```

### 2. S3 관리
```bash
# 버킷 목록
source AWS_switch-to-gli.sh && aws s3 ls

# 버킷 내용 조회
source AWS_switch-to-gli.sh && aws s3 ls s3://my-gli-bucket/

# 파일 업로드/다운로드
source AWS_switch-to-gli.sh && aws s3 cp file.txt s3://my-gli-bucket/
source AWS_switch-to-gli.sh && aws s3 cp s3://my-gli-bucket/file.txt ./
```

### 3. RDS 관리
```bash
# DB 인스턴스 목록
source AWS_switch-to-gli.sh && aws rds describe-db-instances

# DB 인스턴스 상태 확인
source AWS_switch-to-gli.sh && aws rds describe-db-instances --db-instance-identifier my-gli-db
```

### 4. ECS 관리
```bash
# 클러스터 목록
source AWS_switch-to-gli.sh && aws ecs list-clusters

# 서비스 목록
source AWS_switch-to-gli.sh && aws ecs list-services --cluster my-gli-cluster
```

### 5. CloudFormation 관리
```bash
# 스택 목록
source AWS_switch-to-gli.sh && aws cloudformation list-stacks

# 스택 상태 확인
source AWS_switch-to-gli.sh && aws cloudformation describe-stacks --stack-name my-gli-stack
```

### 6. Lambda 관리
```bash
# 함수 목록
source AWS_switch-to-gli.sh && aws lambda list-functions

# 함수 호출
source AWS_switch-to-gli.sh && aws lambda invoke --function-name my-gli-function output.json
```

## 🔒 안전성 체크

모든 명령어 실행 후 다음을 확인:
- 계정: 917891822317 (GLI)
- 리전: ap-northeast-2
- 리소스: gli 관련 네이밍

## ❌ 잘못된 사용법 (절대 금지)

```bash
# 잘못된 예시들
aws ec2 describe-instances                    # GLI 전환 없음
aws s3 ls                                     # GLI 전환 없음
export AWS_PROFILE=default; aws rds ...      # 다른 계정 사용
source AWS_switch-to-lawide.sh; aws ...      # 잘못된 계정 전환
```