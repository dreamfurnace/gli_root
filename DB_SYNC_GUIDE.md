# GLI Database Sync Guide

Staging RDS와 로컬 Docker PostgreSQL 간의 데이터 동기화 가이드

---

## 📋 목차

1. [개요](#개요)
2. [빠른 시작](#빠른-시작)
3. [상세 사용법](#상세-사용법)
4. [Django 관리 명령어](#django-관리-명령어)
5. [문제 해결](#문제-해결)

---

## 개요

### 목적

- 로컬 개발 환경에서 Staging과 동일한 데이터로 테스트
- 로컬 DB 초기화 후 Staging 데이터 복원
- 로컬 DB 백업 및 복원

### 구조

```
Staging RDS (AWS)
    ↓ (1) dump
S3 Bucket (gli-platform-media-staging)
    ↓ (2) download
Local Docker PostgreSQL (gli_DB_local)
```

### 주요 기능

1. **Staging → S3**: Staging RDS 데이터를 덤프하여 S3에 업로드
2. **S3 → Local**: S3에서 다운로드하여 로컬 DB에 복원
3. **Local Backup**: 로컬 DB 백업 생성

---

## 빠른 시작

### 전체 프로세스 (2단계)

#### 1단계: Staging에서 덤프 생성

```bash
# Staging ECS Task에 접속하여 덤프 생성
./dump-staging-db.sh
```

ECS Exec 실행 후 컨테이너 안에서:
```bash
export DJANGO_ENV=staging
cd /var/app/current
python manage.py sync_db --dump
exit
```

#### 2단계: 로컬에서 복원

```bash
# S3에서 다운로드하여 로컬 DB 복원
./sync-db-from-staging.sh
```

완료! 🎉

---

## 상세 사용법

### 1. Staging DB 덤프

#### 방법 1: Helper 스크립트 사용 (권장)

```bash
./dump-staging-db.sh
```

스크립트가 자동으로:
- Staging ECS Task 찾기
- ECS Exec으로 접속
- 덤프 명령 안내
- S3 업로드 확인

#### 방법 2: 수동 실행

```bash
# 1. Staging Task ID 찾기
aws ecs list-tasks \
    --cluster staging-gli-cluster \
    --service-name staging-django-api-service \
    --desired-status RUNNING

# 2. ECS Exec으로 접속
aws ecs execute-command \
    --cluster staging-gli-cluster \
    --task <TASK_ID> \
    --container django-api \
    --interactive \
    --command "/bin/bash"

# 3. 컨테이너 안에서 덤프
export DJANGO_ENV=staging
cd /var/app/current
python manage.py sync_db --dump
exit
```

#### 덤프 파일 위치

- **Latest**: `s3://gli-platform-media-staging/db-sync/latest-dump.json.gz`
- **Backup**: `s3://gli-platform-media-staging/db-sync/backups/dump_<timestamp>.json.gz`

---

### 2. 로컬 DB 복원

#### 방법 1: Helper 스크립트 사용 (권장)

```bash
./sync-db-from-staging.sh
```

스크립트가 자동으로:
1. 로컬 PostgreSQL 상태 확인 및 시작
2. S3에서 최신 덤프 확인
3. 로컬 DB 백업 생성
4. Staging 데이터 다운로드 및 복원
5. 마이그레이션 실행

#### 방법 2: Django 명령어 직접 사용

```bash
cd gli_api-server

# 로컬 DB 백업 (선택)
export DJANGO_ENV=development
python manage.py sync_db --backup

# Staging 데이터 복원
python manage.py sync_db --load

# 마이그레이션
python manage.py migrate
```

---

### 3. 로컬 DB 백업

#### 백업 생성

```bash
cd gli_api-server
export DJANGO_ENV=development
python manage.py sync_db --backup
```

백업 파일 위치: `gli_api-server/backups/local_backup_<timestamp>.json`

#### 백업 복원

```bash
python manage.py loaddata backups/local_backup_20251016_025500.json
```

---

## Django 관리 명령어

### sync_db 명령어

위치: `gli_api-server/apps/common/management/commands/sync_db.py`

#### 옵션

| 옵션 | 설명 | 환경 |
|------|------|------|
| `--dump` | 현재 DB를 덤프하여 S3에 업로드 | staging |
| `--load` | S3에서 다운로드하여 현재 DB에 복원 | development |
| `--backup` | 현재 로컬 DB 백업 | development |
| `--s3-key` | S3 객체 키 지정 (기본: db-sync/latest-dump.json.gz) | 모두 |
| `--exclude` | 제외할 앱/모델 (기본: contenttypes, auth.permission, sessions.session) | 모두 |
| `--force` | 확인 없이 실행 | 모두 |

#### 사용 예제

```bash
# Staging: DB 덤프
DJANGO_ENV=staging python manage.py sync_db --dump

# Local: DB 복원 (확인 프롬프트 표시)
DJANGO_ENV=development python manage.py sync_db --load

# Local: DB 복원 (확인 없이 실행)
DJANGO_ENV=development python manage.py sync_db --load --force

# Local: 백업 생성
python manage.py sync_db --backup

# 특정 S3 키 사용
python manage.py sync_db --dump --s3-key=db-sync/custom-dump.json.gz
```

---

## 문제 해결

### 1. S3에 덤프 파일이 없음

**증상**:
```
S3에 덤프 파일이 없습니다: s3://gli-platform-media-staging/db-sync/latest-dump.json.gz
Staging 환경에서 먼저 --dump를 실행하세요.
```

**해결**:
```bash
# Staging에서 덤프 생성
./dump-staging-db.sh
```

---

### 2. ECS Exec 권한 오류

**증상**:
```
An error occurred (AccessDeniedException) when calling the ExecuteCommand operation
```

**해결**:

1. ECS Task Definition에서 `enableExecuteCommand: true` 확인
2. IAM 권한 확인:
   - `ecs:ExecuteCommand`
   - `ssmmessages:CreateControlChannel`
   - `ssmmessages:CreateDataChannel`
   - `ssmmessages:OpenControlChannel`
   - `ssmmessages:OpenDataChannel`

3. ECS Service 재배포:
```bash
aws ecs update-service \
    --cluster staging-gli-cluster \
    --service staging-django-api-service \
    --enable-execute-command \
    --force-new-deployment
```

---

### 3. 로컬 PostgreSQL 연결 실패

**증상**:
```
PostgreSQL 연결 실패
```

**해결**:
```bash
# PostgreSQL 상태 확인
docker ps | grep gli_DB_local

# PostgreSQL 시작
./restart-database.sh --bf

# 헬스 체크
docker exec gli_database_postgres pg_isready -U gli -d gli
```

---

### 4. 마이그레이션 오류

**증상**:
```
django.db.utils.OperationalError: relation "xxx" does not exist
```

**해결**:
```bash
# 마이그레이션 재실행
cd gli_api-server
export DJANGO_ENV=development
python manage.py migrate

# 마이그레이션 상태 확인
python manage.py showmigrations
```

---

### 5. 데이터 복원 실패

**증상**:
```
복원 실패: ...
```

**해결**:

1. 로컬 DB 초기화:
```bash
# 데이터 볼륨 삭제
cd gli_database
docker-compose down -v

# PostgreSQL 재시작
cd ..
./restart-database.sh --bf

# 마이그레이션
cd gli_api-server
python manage.py migrate
```

2. 복원 재시도:
```bash
python manage.py sync_db --load
```

---

## 보안 주의사항

### 1. 백업 파일 관리

- 로컬 백업 파일 (`gli_api-server/backups/`)에는 **민감한 데이터**가 포함됩니다
- `.gitignore`에 추가되어 있는지 확인
- 정기적으로 오래된 백업 파일 삭제

### 2. S3 버킷 권한

- `gli-platform-media-staging` 버킷은 개발 팀만 접근 가능
- 덤프 파일은 암호화되지 않으므로 주의

### 3. Production 데이터

- **절대 Production RDS 데이터를 로컬로 동기화하지 마세요**
- Production 데이터는 별도의 보안 프로토콜 필요

---

## 자동화

### Cron Job 설정 (Staging 덤프 자동화)

Staging ECS Task에서 매일 자동으로 덤프를 생성하려면:

```bash
# ECS Scheduled Task 생성
# EventBridge Rule: 매일 오전 3시 (KST)
# Target: ECS Task (staging-django-api-service)
# Command Override: ["python", "manage.py", "sync_db", "--dump"]
```

---

## 참고 자료

- [Django dumpdata 문서](https://docs.djangoproject.com/en/5.0/ref/django-admin/#dumpdata)
- [Django loaddata 문서](https://docs.djangoproject.com/en/5.0/ref/django-admin/#loaddata)
- [AWS ECS Exec 문서](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/ecs-exec.html)
- [boto3 S3 문서](https://boto3.amazonaws.com/v1/documentation/api/latest/reference/services/s3.html)

---

**최종 업데이트**: 2025-10-16
**작성자**: DevOps 팀
