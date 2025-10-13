# GLI MultiGit Scripts 가이드

8개 리포지토리를 동시에 관리하기 위한 자동화 스크립트 모음입니다.

## 📁 리포지토리 목록

스크립트가 관리하는 8개 리포지토리:
1. `gli_root` (메인 프로젝트 루트)
2. `gli_admin-frontend` (관리자 대시보드)
3. `gli_api-server` (Django REST API)
4. `gli_database` (데이터베이스 설정)
5. `gli_rabbitmq` (RabbitMQ 설정)
6. `gli_redis` (Redis 설정)
7. `gli_user-frontend` (사용자 프론트엔드)
8. `gli_websocket` (WebSocket 서버)

## 🔄 브랜치 흐름도

```
┌─────────────────────────────────────────────────────────┐
│                   GLI Branch Flow                        │
└─────────────────────────────────────────────────────────┘

    dev (개발)
     ↓ multigit-merge-dev-to-stg.sh
    stg (스테이징) ─────────┐
     ↓                      │ multigit-merge-stg-to-dev.sh
     ↓                      ↓
     ↓ multigit-merge-stg-to-main.sh
    main (프로덕션)
     ↓
     ↓ multigit-merge-main-to-stg.sh (핫픽스)
     └─────────→ stg (역방향)
```

## 📜 스크립트 목록 (총 9개)

### 1. 동기화 스크립트 (Pull)

#### `multigit-pull-dev.sh`
```bash
./multigit-pull-dev.sh
```
- **기능**: 모든 리포지토리의 dev 브랜치를 최신 상태로 업데이트
- **사용 시기**: 팀원들의 최신 개발 작업을 받아올 때
- **자동 실행**: 충돌 없으면 자동 완료

#### `multigit-pull-stg.sh`
```bash
./multigit-pull-stg.sh
```
- **기능**: 모든 리포지토리의 stg 브랜치를 최신 상태로 업데이트
- **사용 시기**: 스테이징 환경 작업 전 동기화
- **자동 실행**: 충돌 없으면 자동 완료

#### `multigit-pull-main.sh`
```bash
./multigit-pull-main.sh
```
- **기능**: 모든 리포지토리의 main 브랜치를 최신 상태로 업데이트
- **사용 시기**: 프로덕션 코드 확인 시

### 2. 푸시 스크립트 (Push)

#### `multigit-push-stg.sh`
```bash
./multigit-push-stg.sh
```
- **기능**: 로컬 stg 브랜치의 커밋을 원격에 푸시
- **사용 시기**: stg 브랜치에서 직접 작업 후 배포
- **확인 필요**: yes 입력 필요
- **자동 배포**: ✅ 스테이징 환경 자동 배포 트리거
- **특징**: 푸시할 커밋이 없으면 자동으로 건너뜀

#### `multigit-push-main.sh`
```bash
./multigit-push-main.sh
```
- **기능**: 로컬 main 브랜치의 커밋을 원격에 푸시
- **사용 시기**: 매우 제한적 (일반적으로 사용 안 함)
- **확인 필요**: DEPLOY 입력 필요

### 3. 머지 스크립트 (Merge)

#### `multigit-merge-dev-to-stg.sh`
```bash
./multigit-merge-dev-to-stg.sh
```
- **기능**: dev → stg 머지 (정방향)
- **사용 시기**: 개발 완료 후 스테이징 배포
- **확인 필요**: yes 입력 필요
- **자동 배포**: ✅ 스테이징 환경 자동 배포
- **충돌 처리**: 자동 감지 및 수동 해결 가이드 제공

#### `multigit-merge-stg-to-main.sh`
```bash
./multigit-merge-stg-to-main.sh
```
- **기능**: stg → main 머지 (정방향)
- **사용 시기**: 스테이징 검증 완료 후 프로덕션 배포
- **확인 필요**: yes + DEPLOY 입력 (이중 확인)
- **자동 배포**: ✅ 프로덕션 환경 자동 배포
- **특징**: 배포 태그 자동 생성 (deploy-YYYYMMDD-HHMMSS)
- **로깅**: deployment.log에 배포 기록 저장

#### `multigit-merge-stg-to-dev.sh` ⭐ NEW
```bash
./multigit-merge-stg-to-dev.sh
```
- **기능**: stg → dev 머지 (역방향)
- **사용 시기**:
  - 스테이징에서 추가 수정/검증이 이루어진 경우
  - 스테이징에서 핫픽스를 받아 dev에도 반영할 때
  - dev와 stg 브랜치를 동기화할 때
- **확인 필요**: yes 입력 필요
- **특징**: 커밋 차이 확인 후 동기화 필요 여부 판단

#### `multigit-merge-main-to-stg.sh`
```bash
./multigit-merge-main-to-stg.sh
```
- **기능**: main → stg 머지 (역방향)
- **사용 시기**: 프로덕션 핫픽스를 스테이징에 반영
- **확인 필요**: yes 입력 필요
- **자동 배포**: ✅ 스테이징 환경 자동 배포
- ⚠️ **주의**: 역방향 머지이므로 특별한 경우에만 사용

## 🎯 사용 시나리오

### 시나리오 1: 일반 개발 & 배포 흐름

```bash
# 1. 최신 dev 브랜치 받아오기
./multigit-pull-dev.sh

# 2. 각 리포지토리에서 개발 작업
cd gli_api-server
git checkout -b feature/new-api
# ... 개발 ...
git commit -m "feat: add new API endpoint"
git checkout dev
git merge feature/new-api
cd ..

# 3. 스테이징 배포
./multigit-merge-dev-to-stg.sh

# 4. 스테이징 환경에서 테스트
# (https://stg.glibiz.com, https://stg-api.glibiz.com 등)

# 5. 프로덕션 배포
./multigit-merge-stg-to-main.sh
```

### 시나리오 2: 스테이징에서 추가 수정 후 dev 동기화

```bash
# 1. 스테이징 배포 후 버그 발견
./multigit-pull-stg.sh

# 2. stg 브랜치에서 직접 수정
cd gli_api-server
git checkout stg
# ... 버그 수정 ...
git commit -m "fix: resolve staging bug"
cd ..

# 3. 수정사항 스테이징에 배포
./multigit-push-stg.sh

# 4. 검증 완료 후 dev에 반영
./multigit-merge-stg-to-dev.sh

# 5. 필요시 프로덕션 배포
./multigit-merge-stg-to-main.sh
```

### 시나리오 3: 프로덕션 긴급 핫픽스

```bash
# 1. main에서 hotfix 브랜치 생성
cd gli_api-server
git checkout main
git pull origin main
git checkout -b hotfix/critical-security-fix
# ... 긴급 수정 ...
git commit -m "hotfix: patch security vulnerability"

# 2. main으로 PR 생성 및 머지
# (GitHub에서 PR 생성 → 리뷰 → 머지)

# 3. 핫픽스를 스테이징에 반영
./multigit-merge-main-to-stg.sh

# 4. 핫픽스를 dev에도 반영
./multigit-merge-stg-to-dev.sh
# 또는 각 리포지토리에서 수동으로
cd gli_api-server
git checkout dev
git merge main
git push origin dev
```

### 시나리오 4: 팀 협업 - 동료 작업 받아오기

```bash
# stg 브랜치에서 팀원들의 작업 받아오기
./multigit-pull-stg.sh

# dev 브랜치에서 팀원들의 작업 받아오기
./multigit-pull-dev.sh
```

## ⚠️ 주의사항

### DO ✅

1. **머지 전 항상 pull 먼저**
   ```bash
   ./multigit-pull-stg.sh  # 머지 전에 최신 상태 확인
   ./multigit-merge-dev-to-stg.sh
   ```

2. **충돌 발생 시 즉시 해결**
   - 스크립트가 중단되면 안내된 명령어로 해결
   - 해결 후 수동으로 push

3. **배포 전 확인 사항 체크**
   - 스테이징: 기능 동작 확인
   - 프로덕션: 사용자 영향 최소화 시간대 선택

### DON'T ❌

1. **절대 force push 금지**
   ```bash
   # 이렇게 하지 마세요!
   git push -f origin main
   git push --force origin stg
   ```

2. **충돌 무시하고 진행 금지**
   - 충돌이 발생하면 반드시 해결 후 진행

3. **프로덕션 배포를 가볍게 생각하지 않기**
   - `multigit-merge-stg-to-main.sh`는 신중하게 실행

## 🔧 트러블슈팅

### 문제 1: 머지 충돌 발생

```bash
# 스크립트가 알려준 리포지토리로 이동
cd gli_api-server
git status

# 충돌 파일 확인
git diff

# 충돌 해결 후
git add .
git commit
git push origin stg  # 또는 해당 브랜치
```

### 문제 2: 일부 리포지토리만 실패

```bash
# 실패한 리포지토리만 수동으로 처리
cd failed-repo
git checkout target-branch
git merge source-branch
# 충돌 해결
git push origin target-branch
```

### 문제 3: 브랜치가 없다는 에러

```bash
# 해당 리포지토리에 브랜치 생성
cd problematic-repo
git checkout -b stg
git push -u origin stg
```

### 문제 4: 스크립트 실행 권한 없음

```bash
chmod +x multigit-*.sh
```

## 📊 스크립트 실행 결과 이해하기

### 성공 출력 예시
```
================================================
Summary
================================================
✅ 성공한 리포지토리 (8):
  - gli_root
  - gli_admin-frontend
  - gli_api-server
  - gli_database
  - gli_rabbitmq
  - gli_redis
  - gli_user-frontend
  - gli_websocket
```

### 부분 실패 출력 예시
```
================================================
Summary
================================================
✅ 성공한 리포지토리 (6):
  - gli_root
  - ...

⏭️  건너뛴 리포지토리 (1):
  - gli_database (no new commits)

❌ 실패한 리포지토리 (1):
  - gli_api-server

⚠️  실패한 리포지토리의 충돌을 해결한 후 수동으로 푸시하세요.
```

## 🔗 관련 문서

- `BRANCHING.md` - 브랜치 전략 상세 가이드
- `SECRETS_MANAGEMENT.md` - Secrets 관리 가이드
- 각 리포지토리의 `.github/workflows/README.md` - CI/CD 설정

## 📞 도움말

스크립트 사용 중 문제가 발생하면:
1. 에러 메시지를 주의 깊게 읽기
2. 제안된 해결 방법 시도
3. 해결 안 되면 팀원에게 문의

---

**문서 버전**: 1.0
**최종 업데이트**: 2025-10-13
**관리**: DevOps Team
