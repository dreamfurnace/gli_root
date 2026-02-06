# GLI Database Synchronization Manual
## 로컬 → 스테이징 DB 데이터 동기화 가이드

이 문서는 로컬 개발 환경에서 작업한 데이터를 스테이징 DB로 동기화하는 절차를 설명합니다.

---

## 📋 목차
1. [개요](#개요)
2. [사전 준비](#사전-준비)
3. [동기화 방법](#동기화-방법)
4. [검증 절차](#검증-절차)
5. [트러블슈팅](#트러블슈팅)

---

## 개요

### 환경 정보
| 환경 | DB 호스트 | 포트 | 데이터베이스명 | 사용자 |
|------|----------|------|---------------|--------|
| **로컬** | localhost | 5433 | gli | gli |
| **스테이징** | gli-db-staging.cp4ems4wqez2.ap-northeast-2.rds.amazonaws.com | 5432 | gli | glidbadmin |

### 동기화 대상 데이터
- RWA 자산 (RWAAsset)
- 자산 뉴스 (RWAAssetNews)
- 리스크 분석 (RWAAssetRiskAnalysis)
- 문서 (RWAAssetDocument)
- VIP 패키지 (RWAAssetVIPPackage)
- DAO 투표 안건 (DAOVotingAgenda)
- DAO 참여자 (DAOParticipant)
- 스타트업 중개 (StartupBrokerage)

---

## 사전 준비

### 1. AWS 인증 정보 확인
스테이징 DB는 AWS RDS에 위치하므로, AWS Secrets Manager에서 인증 정보를 가져옵니다.

```bash
# GLI AWS 계정으로 전환
cd /Users/ahndonghyun/dongfiles/ADHcode/DreamFurnace/gli_root
source AWS_switch-to-gli.sh

# 스테이징 DB 인증 정보 확인
aws secretsmanager get-secret-value \
  --secret-id gli/db/staging \
  --query SecretString \
  --output text
```

**응답 예시:**
```json
{
  "engine": "postgres",
  "host": "gli-db-staging.cp4ems4wqez2.ap-northeast-2.rds.amazonaws.com",
  "port": 5432,
  "dbname": "gli",
  "username": "glidbadmin",
  "password": "GliStage2025SecureDB"
}
```

### 2. Management Command 준비
Django management command를 사용하여 데이터를 추가합니다.

현재 사용 가능한 명령어:
- `add_tier_data.py` - Tier별 샘플 데이터 추가
- `add_dao_participants.py` - DAO 참여자 데이터 추가 (별도 스크립트)

---

## 동기화 방법

### 방법 1: Management Command 사용 (권장)

#### Step 1: 로컬 DB에서 데이터 추가/수정
```bash
cd /Users/ahndonghyun/dongfiles/ADHcode/DreamFurnace/gli_root/gli_api-server

# 로컬 DB에 데이터 추가
uv run python manage.py add_tier_data
```

#### Step 2: 스테이징 DB에 동일한 데이터 추가
```bash
cd /Users/ahndonghyun/dongfiles/ADHcode/DreamFurnace/gli_root/gli_api-server

# 환경 변수로 스테이징 DB 지정
DATABASE_HOST=gli-db-staging.cp4ems4wqez2.ap-northeast-2.rds.amazonaws.com \
DATABASE_PORT=5432 \
DATABASE_NAME=gli \
DATABASE_USER=glidbadmin \
DATABASE_PASSWORD=GliStage2025SecureDB \
uv run python manage.py add_tier_data
```

#### Step 3: 결과 확인
두 환경 모두에서 다음 항목이 동일하게 표시되어야 합니다:
```
=== 최종 데이터 확인 ===
News: X개 (FREE: X, BASIC: X)
Risk Analysis: 있음 (Score: X.X)
Documents: X개 (STANDARD: X, PREMIUM: X)
VIP Packages: X개
DAO Agendas: X개
Startup Brokerages: X개
```

### 방법 2: 커스텀 Python 스크립트 사용

특정 모델만 동기화해야 할 경우, 별도 스크립트를 작성합니다.

**예시: DAO Participants 추가**
```bash
cd /Users/ahndonghyun/dongfiles/ADHcode/DreamFurnace/gli_root/gli_api-server

# 로컬 DB
uv run python add_dao_participants.py

# 스테이징 DB
DATABASE_HOST=gli-db-staging.cp4ems4wqez2.ap-northeast-2.rds.amazonaws.com \
DATABASE_PORT=5432 \
DATABASE_NAME=gli \
DATABASE_USER=glidbadmin \
DATABASE_PASSWORD=GliStage2025SecureDB \
uv run python add_dao_participants.py
```

### 방법 3: pg_dump/pg_restore 사용 (데이터 완전 복제)

⚠️ **주의**: 이 방법은 스테이징 DB의 기존 데이터를 완전히 덮어씁니다!

```bash
# 1. 로컬 DB 덤프
pg_dump -h localhost -p 5433 -U gli -d gli \
  --data-only \
  --table=rwa_assets \
  --table=rwa_asset_news \
  --table=rwa_asset_risk_analysis \
  > local_data_dump.sql

# 2. 스테이징 DB로 복원
psql -h gli-db-staging.cp4ems4wqez2.ap-northeast-2.rds.amazonaws.com \
  -p 5432 -U glidbadmin -d gli \
  < local_data_dump.sql
```

---

## 검증 절차

### 1. Django Shell로 데이터 확인

**로컬 DB:**
```bash
cd /Users/ahndonghyun/dongfiles/ADHcode/DreamFurnace/gli_root/gli_api-server
uv run python manage.py shell
```

**스테이징 DB:**
```bash
DATABASE_HOST=gli-db-staging.cp4ems4wqez2.ap-northeast-2.rds.amazonaws.com \
DATABASE_PORT=5432 \
DATABASE_USER=glidbadmin \
DATABASE_PASSWORD=GliStage2025SecureDB \
uv run python manage.py shell
```

**Shell 명령어:**
```python
from apps.gli_content.models import RWAAsset, StartupBrokerage, DAOParticipant

# 자산 확인
asset = RWAAsset.objects.get(id='96ca1b1f-97bb-4c5e-ada7-847e317814b3')
print(f"Asset: {asset.name}")

# 관련 데이터 개수 확인
print(f"News: {asset.news.count()}")
print(f"Documents: {asset.documents.count()}")
print(f"VIP Packages: {asset.vip_packages.count()}")
print(f"DAO Agendas: {asset.dao_agendas.count()}")
print(f"DAO Participants: {asset.dao_participants.count()}")
print(f"Startup Brokerages: {asset.startup_brokerages.count()}")
```

### 2. API 엔드포인트로 검증

**로컬:**
```bash
curl http://localhost:8000/api/rwa-assets/96ca1b1f-97bb-4c5e-ada7-847e317814b3/ | jq
```

**스테이징:**
```bash
curl https://api-staging.gli.io/api/rwa-assets/96ca1b1f-97bb-4c5e-ada7-847e317814b3/ | jq
```

### 3. 프론트엔드에서 확인

**로컬:**
- http://localhost:3000/rwa-assets/96ca1b1f-97bb-4c5e-ada7-847e317814b3

**스테이징:**
- https://staging.gli.io/rwa-assets/96ca1b1f-97bb-4c5e-ada7-847e317814b3

---

## 트러블슈팅

### 문제 1: 환경 변수가 적용되지 않음

**증상:**
```
[settings.py] DATABASE_HOST: localhost
```
스테이징 DB 접속 명령을 실행했는데도 localhost가 표시됨.

**해결:**
Django settings.py가 .env.development 파일을 먼저 로드하기 때문입니다.
환경 변수는 런타임에 전달되지만, settings.py가 이미 로드된 후라 영향을 주지 못합니다.

**올바른 방법:**
```bash
# settings.py 로드 전에 환경 변수 전달
env DATABASE_HOST=gli-db-staging... python manage.py ...
```

또는 임시로 `.env.development` 파일을 백업하고 스테이징 설정으로 변경합니다.

### 문제 2: "already exists" 오류

**증상:**
```
IntegrityError: duplicate key value violates unique constraint
```

**해결:**
- Management command에 `--force` 플래그 추가 (구현된 경우)
- 기존 데이터 삭제 후 재추가
- `update_or_create()` 메서드 사용으로 스크립트 수정

### 문제 3: 스테이징 DB 접속 불가

**증상:**
```
psycopg2.OperationalError: could not connect to server
```

**해결:**
1. VPN 연결 확인 (필요한 경우)
2. AWS Security Group 확인 (5432 포트 개방 여부)
3. DB 인증 정보 재확인 (Secrets Manager)

### 문제 4: 로컬과 스테이징 데이터 불일치

**해결:**
1. 각 환경에서 `add_tier_data.py` 실행 시 출력 비교
2. Django shell로 직접 데이터 개수 확인
3. 필요시 불일치 데이터 수동 삭제 후 재추가

---

## 자동화 스크립트

편의를 위한 자동화 스크립트:

```bash
#!/usr/bin/env bash
# sync_db_to_staging.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR/gli_api-server"

echo "🔄 로컬 DB에 데이터 추가..."
uv run python manage.py add_tier_data

echo "🔄 스테이징 DB에 데이터 추가..."
DATABASE_HOST=gli-db-staging.cp4ems4wqez2.ap-northeast-2.rds.amazonaws.com \
DATABASE_PORT=5432 \
DATABASE_NAME=gli \
DATABASE_USER=glidbadmin \
DATABASE_PASSWORD=GliStage2025SecureDB \
uv run python manage.py add_tier_data

echo "✅ DB 동기화 완료!"
```

**사용법:**
```bash
cd /Users/ahndonghyun/dongfiles/ADHcode/DreamFurnace/gli_root
./sync_db_to_staging.sh
```

---

## 참고 문서

- [LOCAL_SERVICES_GUIDE.md](./LOCAL_SERVICES_GUIDE.md) - 로컬 서비스 실행 가이드
- [AWS_switch-to-gli.sh](../AWS_switch-to-gli.sh) - AWS 계정 전환 스크립트
- Django Management Commands: `gli_api-server/apps/gli_content/management/commands/`

---

**작성일:** 2026-02-06
**최종 업데이트:** 2026-02-06
**작성자:** Claude Sonnet 4.5
