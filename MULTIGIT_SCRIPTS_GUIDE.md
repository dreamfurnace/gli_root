# GLI MultiGit Scripts 가이드

## 개요

GLI 프로젝트는 마이크로서비스 아키텍처를 채택하여 여러 개의 독립적인 Git 리포지토리로 구성되어 있습니다. 이 가이드는 모든 리포지토리를 동시에 관리하기 위한 **MultiGit 스크립트**의 사용법을 설명합니다.

### 주요 특징

- **일괄 작업**: 8개 리포지토리를 하나의 명령으로 동시 처리
- **브랜치 전략**: dev → stg → main 흐름과 역방향 핫픽스 지원
- **배포 자동화**: GitHub Actions와 연동된 자동 배포
- **가시적 히스토리**: `--no-ff` 플래그로 명확한 브랜치 머지 시각화
- **태그 관리**: 배포 시점을 태그로 기록하여 롤백 용이
- **커스텀 메시지**: 모든 스크립트에서 커밋 메시지 지정 가능

---

## 관리 대상 리포지토리

GLI 프로젝트는 다음 8개의 리포지토리로 구성되어 있습니다:

| 리포지토리 | 설명 | 기술 스택 |
|----------|------|----------|
| `gli_root` | 프로젝트 루트 (현재 디렉토리 `.`) | 인프라 스크립트, 문서 |
| `gli_user-frontend` | 사용자 웹 애플리케이션 | Next.js, React |
| `gli_admin-frontend` | 관리자 대시보드 | Next.js, React |
| `gli_api-server` | RESTful API 서버 | Node.js, Express |
| `gli_websocket` | 실시간 통신 서버 | Node.js, Socket.io |
| `gli_database` | 데이터베이스 마이그레이션 | PostgreSQL |
| `gli_redis` | 인메모리 캐시 | Redis (Docker) |
| `gli_rabbitmq` | 메시지 큐 | RabbitMQ (Docker) |

---

## 스크립트 분류

### 1. Pull 스크립트 (원격 → 로컬)

| 스크립트 | 브랜치 | 설명 |
|----------|--------|------|
| `multigit-pull-dev.sh` | dev | 개발 브랜치 최신화, 로컬 변경사항 자동 커밋 |
| `multigit-pull-stg.sh` | stg | 스테이징 브랜치 최신화 |
| `multigit-pull-main.sh` | main | 프로덕션 브랜치 최신화, clone 기능 포함 |

### 2. Push 스크립트 (로컬 → 원격)

| 스크립트 | 브랜치 | 설명 |
|----------|--------|------|
| `multigit-push-dev.sh` | dev | 개발 브랜치 푸시, 자동 커밋 |
| `multigit-push-stg.sh` | stg | 스테이징 브랜치 푸시, 자동 커밋 |
| `multigit-push-main.sh` | main | 프로덕션 브랜치 푸시 (커밋 메시지 필수) |

### 3. Merge 스크립트 (브랜치 간 병합)

| 스크립트 | 방향 | 설명 | TAG 생성 |
|----------|------|------|----------|
| `multigit-merge-dev-to-stg.sh` | dev → stg | 개발 완료 후 스테이징 배포 | ✅ `stg-deploy-*` |
| `multigit-merge-stg-to-main.sh` | stg → main | 스테이징 검증 후 프로덕션 배포 | ✅ `deploy-*` |
| `multigit-merge-stg-to-dev.sh` | stg → dev | 스테이징 수정사항을 개발에 동기화 | ❌ |
| `multigit-merge-main-to-stg.sh` | main → stg | 프로덕션 핫픽스를 스테이징에 반영 | ❌ |

### 4. 통합 워크플로우 스크립트

| 스크립트 | 동작 | 설명 |
|----------|------|------|
| `multigit-push-dev-merge-to-stg.sh` | dev 푸시 + stg 머지 | 개발 완료 후 스테이징까지 한 번에 배포 |

---

## Pull 스크립트 상세 가이드

### `multigit-pull-dev.sh`

**용도**: 모든 리포지토리의 dev 브랜치를 최신 상태로 업데이트합니다.

**특징**:
- 현재 브랜치의 로컬 변경사항을 자동으로 커밋한 후 dev로 전환
- 원격 dev 브랜치가 없으면 자동 생성
- `.DS_Store` 파일 자동 제거 및 `.gitignore` 추가

**사용법**:
```bash
./multigit-pull-dev.sh
```

**동작 순서**:
1. 각 리포지토리 순회
2. 현재 브랜치에 uncommitted 변경사항 있으면 자동 커밋
3. dev 브랜치로 전환 (없으면 생성)
4. `git pull origin dev` 실행

**주의사항**:
- 현재 작업 중인 브랜치의 변경사항은 자동으로 커밋됩니다
- 커밋 메시지: `{현재브랜치}: auto commit before switching to dev`

---

### `multigit-pull-stg.sh`

**용도**: 모든 리포지토리의 stg 브랜치를 최신 상태로 업데이트합니다.

**특징**:
- 로컬 stg 브랜치가 없으면 `origin/stg`를 기준으로 생성
- 충돌 발생 시 상세한 해결 방법 제공

**사용법**:
```bash
./multigit-pull-stg.sh
```

**동작 순서**:
1. stg 브랜치 존재 여부 확인 (없으면 자동 생성)
2. stg 브랜치로 전환
3. `git pull origin stg` 실행

---

### `multigit-pull-main.sh`

**용도**: 모든 리포지토리의 main 브랜치를 최신 상태로 업데이트합니다.

**특징**:
- 리포지토리가 없으면 자동 clone
- `.git` 디렉토리가 없으면 삭제 후 재클론
- 로컬 변경사항이 있으면 pull 중단 (수동 처리 요구)

**사용법**:
```bash
./multigit-pull-main.sh
```

**동작 순서**:
1. 리포지토리 존재 여부 확인 (없으면 clone)
2. 로컬 변경사항 확인 (있으면 중단)
3. `git fetch origin` 실행
4. main 브랜치로 전환 또는 생성
5. `git pull origin main` 실행

**주의사항**:
- 로컬 변경사항이 있으면 "먼저 커밋하거나 스태시하세요" 메시지와 함께 중단됩니다

---

## Push 스크립트 상세 가이드

### 공통 특징

모든 push 스크립트는 다음 기능을 공통으로 제공합니다:
- 커밋 메시지를 명령줄 인자로 전달 가능
- `.DS_Store` 파일 자동 제거
- 변경사항이 없는 리포지토리는 자동 건너뜀
- yes 확인 절차

### `multigit-push-dev.sh`

**용도**: 모든 리포지토리의 dev 브랜치에 변경사항을 커밋하고 푸시합니다.

**사용법**:
```bash
# 기본 메시지 사용
./multigit-push-dev.sh

# 커스텀 메시지 사용
./multigit-push-dev.sh "feat: 사용자 인증 기능 추가"
```

**기본 커밋 메시지**: `dev: auto commit and deploy`

**배포 환경**: 개발 환경
- dev.glibiz.com
- dev-api.glibiz.com
- dev-admin.glibiz.com
- dev-ws.glibiz.com

---

### `multigit-push-stg.sh`

**용도**: 모든 리포지토리의 stg 브랜치에 변경사항을 커밋하고 푸시합니다.

**사용법**:
```bash
# 기본 메시지 사용
./multigit-push-stg.sh

# 커스텀 메시지 사용
./multigit-push-stg.sh "hotfix: API 타임아웃 수정"
```

**기본 커밋 메시지**: `stg: auto commit and deploy`

**배포 환경**: 스테이징 환경
- stg.glibiz.com
- stg-api.glibiz.com
- stg-admin.glibiz.com
- stg-ws.glibiz.com

---

### `multigit-push-main.sh`

**용도**: 모든 리포지토리의 main 브랜치에 변경사항을 커밋하고 푸시합니다.

**사용법**:
```bash
# 커밋 메시지는 필수입니다
./multigit-push-main.sh "release: v1.2.0 배포"
```

**특징**:
- 커밋 메시지 인자가 필수입니다 (기본값 없음)
- 프로덕션 배포이므로 신중하게 사용해야 합니다

**배포 환경**: 프로덕션 환경
- glibiz.com
- api.glibiz.com
- admin.glibiz.com
- ws.glibiz.com

---

## Merge 스크립트 상세 가이드

### 공통 특징

모든 merge 스크립트는 다음 기능을 공통으로 제공합니다:
- **`--no-ff` 플래그**: Fast-forward를 방지하여 명확한 머지 커밋 생성
- **커스텀 커밋 메시지**: 명령줄 인자로 머지 메시지 지정 가능
- **충돌 감지 및 가이드**: 충돌 발생 시 상세한 해결 방법 제공
- **yes 확인 절차**: 실수로 인한 머지 방지

### `--no-ff` 플래그의 중요성

```bash
# 기본 merge (fast-forward 가능 시)
git merge dev
# 결과: main ---> commit1 ---> commit2 (일직선)

# --no-ff merge
git merge dev --no-ff
# 결과: main ----> merge commit
#                /              \
#       dev --> commit1 --> commit2
```

Fork, GitKraken 같은 GUI 도구에서 브랜치 병합을 시각적으로 확인하려면 `--no-ff` 플래그가 필수입니다.

---

### `multigit-merge-dev-to-stg.sh`

**용도**: 개발이 완료된 기능을 스테이징 환경에 배포합니다.

**사용법**:
```bash
# 기본 메시지 사용
./multigit-merge-dev-to-stg.sh

# 커스텀 메시지 사용
./multigit-merge-dev-to-stg.sh "feat: 결제 모듈 스테이징 배포"
```

**기본 커밋 메시지**: `Merge dev into stg`

**동작 순서**:
1. dev 브랜치로 전환 및 최신화 (`git pull origin dev`)
2. stg 브랜치로 전환 및 최신화 (`git pull origin stg`)
3. dev를 stg에 머지 (`git merge dev --no-ff -m "커밋 메시지"`)
4. 배포 태그 생성 (`stg-deploy-YYYYMMDD-HHMMSS`)
5. stg 브랜치와 태그를 원격에 푸시
6. GitHub Actions가 자동으로 스테이징 환경 배포 시작

**TAG 생성**:
```bash
stg-deploy-20250115-143022
```

**배포 환경**: 스테이징 환경 (stg.glibiz.com)

**사용 시나리오**:
- 개발 브랜치에서 새 기능 개발 완료
- 스테이징 환경에서 QA 테스트 필요
- 프로덕션 배포 전 최종 검증

---

### `multigit-merge-stg-to-main.sh`

**용도**: 스테이징에서 검증된 기능을 프로덕션 환경에 배포합니다.

**사용법**:
```bash
# 기본 메시지 사용
./multigit-merge-stg-to-main.sh

# 커스텀 메시지 사용
./multigit-merge-stg-to-main.sh "release: v2.3.0 프로덕션 배포"
```

**기본 커밋 메시지**: `Merge stg into main (production deployment)`

**동작 순서**:
1. stg 브랜치로 전환 및 최신화
2. main 브랜치로 전환 및 최신화
3. stg를 main에 머지 (`git merge stg --no-ff -m "커밋 메시지"`)
4. 프로덕션 배포 태그 생성 (`deploy-YYYYMMDD-HHMMSS`)
5. main 브랜치와 태그를 원격에 푸시
6. GitHub Actions가 자동으로 프로덕션 환경 배포 시작

**TAG 생성**:
```bash
deploy-20250115-150130
```

**배포 환경**: 프로덕션 환경 (glibiz.com)

**확인 절차**:
- ⚠️ yes 입력 필요 (이전에는 DEPLOY까지 2단계 확인이었으나, 현재는 yes만 입력)

**배포 전 체크리스트**:
- ✅ 스테이징 환경에서 모든 기능이 정상 동작하는가?
- ✅ 데이터베이스 마이그레이션이 필요한가?
- ✅ 중요 API 엔드포인트 테스트를 완료했는가?
- ✅ 사용자 프론트엔드와 관리자 대시보드를 테스트했는가?
- ✅ 배포 후 롤백 계획이 있는가?
- ✅ 팀원들에게 배포 일정을 공유했는가?

**롤백 방법**:
```bash
git checkout main
git reset --hard HEAD~1
git push origin main --force-with-lease
```

**배포 로그**:
- 스크립트는 자동으로 `deployment.log` 파일에 배포 기록을 남깁니다

---

### `multigit-merge-stg-to-dev.sh`

**용도**: 스테이징에서 추가 수정된 내용을 개발 브랜치에 동기화합니다.

**사용법**:
```bash
# 기본 메시지 사용
./multigit-merge-stg-to-dev.sh

# 커스텀 메시지 사용
./multigit-merge-stg-to-dev.sh "sync: 스테이징 수정사항 동기화"
```

**기본 커밋 메시지**: `Merge stg into dev (sync verified)`

**동작 순서**:
1. stg 브랜치로 전환 및 최신화
2. dev 브랜치로 전환 및 최신화
3. stg와 dev의 커밋 차이 확인 (`git rev-list dev..stg --count`)
4. 차이가 없으면 건너뜀
5. stg를 dev에 머지 (`git merge stg --no-ff -m "커밋 메시지"`)
6. dev 브랜치를 원격에 푸시

**사용 시나리오**:
- 스테이징에서 긴급 수정이 발생한 경우
- QA 과정에서 발견된 버그를 스테이징에서 직접 수정한 경우
- 스테이징과 개발 브랜치를 동기화하고 싶을 때

---

### `multigit-merge-main-to-stg.sh`

**용도**: 프로덕션의 핫픽스를 스테이징에 반영합니다 (역방향 머지).

**사용법**:
```bash
# 기본 메시지 사용
./multigit-merge-main-to-stg.sh

# 커스텀 메시지 사용
./multigit-merge-main-to-stg.sh "hotfix: 프로덕션 긴급 수정 반영"
```

**기본 커밋 메시지**: `Merge main into stg (hotfix sync)`

**동작 순서**:
1. main 브랜치로 전환 및 최신화
2. stg 브랜치로 전환 및 최신화
3. main과 stg의 커밋 차이 확인 (`git rev-list stg..main --count`)
4. 차이가 없으면 건너뜀
5. main을 stg에 머지 (`git merge main --no-ff -m "커밋 메시지"`)
6. stg 브랜치를 원격에 푸시 (스테이징 환경 배포 시작)

**사용 시나리오**:
- 프로덕션에서 긴급 버그 수정 (핫픽스)
- 핫픽스를 스테이징과 개발 환경에도 반영 필요
- 일반적인 흐름 (dev → stg → main)의 역방향

**주의사항**:
- 이 스크립트는 예외적인 상황에서만 사용해야 합니다
- 일반적인 개발 흐름은 dev → stg → main입니다
- 핫픽스 후에는 dev 브랜치도 동기화를 고려하세요

---

## 통합 워크플로우 스크립트

### `multigit-push-dev-merge-to-stg.sh`

**용도**: 개발 완료 후 dev 푸시와 stg 머지를 한 번에 처리합니다.

**사용법**:
```bash
# 기본 메시지 사용
./multigit-push-dev-merge-to-stg.sh

# 커스텀 메시지 사용
./multigit-push-dev-merge-to-stg.sh "feat: 대시보드 개선 완료"
```

**기본 커밋 메시지**: `dev: auto commit and merge to staging`

**동작 순서**:
1. dev 브랜치로 전환 및 최신화
2. 로컬 변경사항 확인
3. 변경사항이 있으면 staging, commit
4. dev 브랜치를 원격에 푸시
5. stg 브랜치로 전환 및 최신화
6. dev를 stg에 머지 (`--no-ff` 사용)
7. 스테이징 배포 태그 생성 (`stg-deploy-YYYYMMDD-HHMMSS`)
8. stg 브랜치와 태그를 원격에 푸시

**장점**:
- 두 개의 스크립트를 따로 실행할 필요 없음
- 일관된 커밋 메시지로 이력 관리 용이
- 개발 → 스테이징 배포 과정 자동화

**사용 시나리오**:
- 로컬에서 개발 완료
- dev에 푸시하면서 바로 스테이징 배포까지 진행
- 빠른 개발-테스트 사이클 필요

---

## 브랜치 전략

### 표준 개발 흐름

```
개발자 로컬
    ↓ (작업 완료)
dev 브랜치
    ↓ (multigit-merge-dev-to-stg.sh)
stg 브랜치 → [스테이징 환경 배포]
    ↓ (QA 검증 완료)
    ↓ (multigit-merge-stg-to-main.sh)
main 브랜치 → [프로덕션 환경 배포]
```

### 핫픽스 흐름 (역방향)

```
프로덕션 긴급 수정
    ↓
main 브랜치 (직접 수정)
    ↓ (multigit-merge-main-to-stg.sh)
stg 브랜치 (동기화)
    ↓ (multigit-merge-stg-to-dev.sh)
dev 브랜치 (동기화)
```

### 브랜치별 역할

| 브랜치 | 용도 | 자동 배포 환경 |
|--------|------|----------------|
| `dev` | 개발 작업, 피처 브랜치 통합 | dev.glibiz.com |
| `stg` | QA 테스트, 프로덕션 배포 전 검증 | stg.glibiz.com |
| `main` | 프로덕션 운영 코드 | glibiz.com |

---

## 일반적인 워크플로우 시나리오

### 시나리오 1: 새 기능 개발 및 배포

```bash
# 1단계: 로컬에서 개발 작업
cd gli_user-frontend
git checkout dev
# ... 코드 작성 ...

# 2단계: 모든 리포지토리의 dev 브랜치 푸시 (개발 환경 배포)
cd ~/gli_root
./multigit-push-dev.sh "feat: 사용자 프로필 페이지 추가"

# 3단계: 개발 환경에서 테스트 (dev.glibiz.com)

# 4단계: dev → stg 머지 (스테이징 배포)
./multigit-merge-dev-to-stg.sh "feat: 사용자 프로필 기능 스테이징 배포"

# 5단계: 스테이징 환경에서 QA 테스트 (stg.glibiz.com)

# 6단계: stg → main 머지 (프로덕션 배포)
./multigit-merge-stg-to-main.sh "release: v1.5.0 - 사용자 프로필 기능 출시"

# 7단계: 프로덕션 모니터링 (glibiz.com)
```

---

### 시나리오 2: 빠른 개발-스테이징 배포

```bash
# 로컬에서 개발 완료 후
cd ~/gli_root

# dev 푸시 + stg 머지를 한 번에
./multigit-push-dev-merge-to-stg.sh "feat: 알림 기능 개선"

# 스테이징 환경에서 테스트 (stg.glibiz.com)
# 문제 없으면 프로덕션 배포
./multigit-merge-stg-to-main.sh "release: 알림 기능 개선 배포"
```

---

### 시나리오 3: 프로덕션 긴급 핫픽스

```bash
# 1단계: 프로덕션에서 긴급 버그 발견
# 2단계: main 브랜치에 직접 수정
cd gli_api-server
git checkout main
# ... 버그 수정 ...
git add .
git commit -m "hotfix: API 타임아웃 수정"
git push origin main  # 프로덕션 즉시 배포

# 3단계: 모든 리포지토리 main 푸시
cd ~/gli_root
./multigit-push-main.sh "hotfix: 긴급 API 타임아웃 수정"

# 4단계: main → stg 동기화 (스테이징에 핫픽스 반영)
./multigit-merge-main-to-stg.sh "hotfix: 프로덕션 긴급 수정 동기화"

# 5단계: stg → dev 동기화 (개발 브랜치에도 반영)
./multigit-merge-stg-to-dev.sh "hotfix: 프로덕션 긴급 수정 동기화"
```

---

### 시나리오 4: 새 개발자 온보딩 (초기 셋업)

```bash
# 1단계: 리포지토리 클론
cd ~/workspaces
mkdir gli_root && cd gli_root

# 2단계: 모든 리포지토리를 main 브랜치로 클론
./multigit-pull-main.sh

# 3단계: dev 브랜치로 전환
./multigit-pull-dev.sh

# 4단계: 개발 환경 확인
# - dev.glibiz.com 접속 테스트
# - 로컬 개발 서버 실행 테스트

# 5단계: 개발 시작
cd gli_user-frontend
git checkout -b feature/my-feature dev
# ... 개발 작업 ...
```

---

### 시나리오 5: 스테이징에서 발견된 버그 수정

```bash
# 1단계: 스테이징 환경에서 버그 발견 (stg.glibiz.com)

# 2단계: stg 브랜치에서 직접 수정
cd gli_api-server
git checkout stg
# ... 버그 수정 ...
git add .
git commit -m "fix: 스테이징 버그 수정"
git push origin stg

# 3단계: 모든 리포지토리 stg 푸시
cd ~/gli_root
./multigit-push-stg.sh "fix: 스테이징 버그 수정"

# 4단계: stg → dev 동기화 (개발 브랜치에 반영)
./multigit-merge-stg-to-dev.sh "fix: 스테이징 버그 수정 반영"

# 5단계: 스테이징 재테스트 후 프로덕션 배포
./multigit-merge-stg-to-main.sh "fix: 버그 수정 프로덕션 배포"
```

---

## 트러블슈팅

### 문제 1: 머지 충돌 발생

**증상**:
```
❌ 머지 충돌 발생! 수동으로 해결이 필요합니다.
```

**해결 방법**:
```bash
# 1. 해당 리포지토리로 이동
cd gli_api-server

# 2. 충돌 파일 확인
git status

# 3. 충돌 파일 수정 (VS Code 등 에디터 사용)
# <<<<<<< HEAD
# =======
# >>>>>>> 마커를 찾아서 수동으로 해결

# 4. 충돌 해결 후 스테이징
git add .

# 5. 머지 커밋 완료
git commit

# 6. 푸시
git push origin stg

# 7. 필요시 TAG도 푸시
git tag -a "stg-deploy-20250115-143022" -m "Staging deployment"
git push origin --tags
```

---

### 문제 2: Push 실패 (원격에 새 커밋 존재)

**증상**:
```
❌ 푸시 실패
해결 방법:
  cd gli_api-server
  git pull origin dev  # 원격 변경사항 먼저 가져오기
  git push origin dev
```

**해결 방법**:
```bash
# 1. 해당 리포지토리로 이동
cd gli_api-server

# 2. 원격 변경사항 먼저 가져오기
git pull origin dev

# 3. 충돌이 없으면 자동 머지
# 4. 충돌이 있으면 위의 "머지 충돌 발생" 해결 방법 참고

# 5. 다시 푸시
git push origin dev
```

---

### 문제 3: 로컬 변경사항 감지로 Pull 중단

**증상**:
```
⚠️ [gli_api-server] 로컬 변경사항이 존재합니다. 먼저 커밋하거나 스태시하세요.
```

**해결 방법 A (커밋)**:
```bash
cd gli_api-server
git add .
git commit -m "WIP: 작업 중 임시 커밋"
cd ~/gli_root
./multigit-pull-dev.sh
```

**해결 방법 B (스태시)**:
```bash
cd gli_api-server
git stash save "임시 저장"
cd ~/gli_root
./multigit-pull-dev.sh

# 나중에 스태시 복원
cd gli_api-server
git stash pop
```

---

### 문제 4: 리포지토리가 존재하지 않음

**증상**:
```
⚠️ dev 브랜치가 존재하지 않습니다. 건너뜁니다.
```

**해결 방법**:
```bash
# 해당 리포지토리만 수동 클론
cd ~/gli_root
git clone git@github.com:dreamfurnace/gli_api-server.git gli_api-server

# 또는 main pull 스크립트로 모든 리포지토리 클론
./multigit-pull-main.sh
```

---

### 문제 5: TAG 푸시 실패

**증상**:
```
❌ 태그 푸시 실패
```

**해결 방법**:
```bash
# 1. 리포지토리로 이동
cd gli_api-server

# 2. 로컬 태그 확인
git tag

# 3. 특정 태그만 푸시
git push origin stg-deploy-20250115-143022

# 4. 모든 태그 푸시
git push origin --tags

# 5. 태그 삭제 후 재생성 (잘못 생성된 경우)
git tag -d stg-deploy-20250115-143022
git tag -a "stg-deploy-20250115-143022" -m "Staging deployment"
git push origin --tags
```

---

### 문제 6: .DS_Store 파일 문제 (macOS)

**증상**:
```
modified:   .DS_Store
```

**해결 방법**:
모든 multigit 스크립트는 자동으로 `.DS_Store` 파일을 처리하지만, 수동으로 처리하려면:

```bash
# 1. 현재 추적 중인 .DS_Store 제거
git rm --cached .DS_Store
git rm --cached **/.DS_Store

# 2. .gitignore에 추가
echo ".DS_Store" >> .gitignore

# 3. 전역 gitignore 설정 (모든 프로젝트에 적용)
echo ".DS_Store" >> ~/.gitignore_global
git config --global core.excludesfile ~/.gitignore_global

# 4. 시스템 전체에서 .DS_Store 생성 비활성화
defaults write com.apple.desktopservices DSDontWriteNetworkStores true
```

---

### 문제 7: GitHub Actions 배포 실패

**증상**:
- 스크립트는 성공했지만 실제 환경에 배포되지 않음
- GitHub Actions 워크플로우 실패

**해결 방법**:
```bash
# 1. GitHub Actions 상태 확인
gh run list --repo dreamfurnace/gli_api-server

# 2. 최근 실패한 워크플로우 확인
gh run view

# 3. 워크플로우 로그 확인
gh run view [run-id] --log

# 4. 배포 재시도 (GitHub Actions 수동 트리거)
# GitHub 웹사이트에서 Actions 탭 → 해당 워크플로우 → Re-run failed jobs

# 5. 롤백이 필요한 경우
git checkout main
git reset --hard deploy-20250115-140000  # 이전 정상 태그로 복원
git push origin main --force-with-lease
```

---

## 스크립트 커스터마이징

### 리포지토리 추가/제거

모든 스크립트의 `REPOS` 배열을 수정하면 됩니다:

```bash
REPOS=(
  .
  gli_admin-frontend
  gli_api-server
  gli_database
  gli_rabbitmq
  gli_redis
  gli_user-frontend
  gli_websocket
  # 새 리포지토리 추가
  # gli_new-service
)
```

### 기본 커밋 메시지 변경

각 스크립트의 `COMMIT_MSG` 변수를 수정합니다:

```bash
# 기존
COMMIT_MSG="${1:-dev: auto commit and deploy}"

# 변경 후
COMMIT_MSG="${1:-feat: 자동 배포}"
```

### 확인 절차 비활성화 (자동화용)

yes 확인을 건너뛰려면 (CI/CD 환경):

```bash
# 기존
read -p "계속하시겠습니까? (yes 입력 필요): " -r
if [[ ! $REPLY == "yes" ]]; then
  echo "❌ 작업이 취소되었습니다"
  exit 1
fi

# 자동화 버전 (주석 처리 또는 삭제)
# read -p "계속하시겠습니까? (yes 입력 필요): " -r
# if [[ ! $REPLY == "yes" ]]; then
#   echo "❌ 작업이 취소되었습니다"
#   exit 1
# fi
```

---

## 참고 자료

- [DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md) - 배포 시스템 전체 가이드
- [BRANCHING.md](./BRANCHING.md) - Git 브랜치 전략 상세
- [GitHub Actions 문서](https://docs.github.com/en/actions)
- [Git 공식 문서 - merge](https://git-scm.com/docs/git-merge)
- [Pro Git Book](https://git-scm.com/book/en/v2)

---

## 요약

### Pull 스크립트
```bash
./multigit-pull-dev.sh   # dev 브랜치 최신화
./multigit-pull-stg.sh   # stg 브랜치 최신화
./multigit-pull-main.sh  # main 브랜치 최신화 (clone 기능 포함)
```

### Push 스크립트
```bash
./multigit-push-dev.sh "커밋 메시지"   # dev 푸시
./multigit-push-stg.sh "커밋 메시지"   # stg 푸시
./multigit-push-main.sh "커밋 메시지"  # main 푸시 (메시지 필수)
```

### Merge 스크립트
```bash
./multigit-merge-dev-to-stg.sh "메시지"  # dev → stg (TAG 생성)
./multigit-merge-stg-to-main.sh "메시지" # stg → main (TAG 생성)
./multigit-merge-stg-to-dev.sh "메시지"  # stg → dev (역방향)
./multigit-merge-main-to-stg.sh "메시지" # main → stg (핫픽스)
```

### 통합 워크플로우
```bash
./multigit-push-dev-merge-to-stg.sh "메시지"  # dev 푸시 + stg 머지
```

### 일반적인 개발 흐름
```bash
# 개발 → 스테이징 → 프로덕션
./multigit-push-dev.sh "feat: 기능 개발"
./multigit-merge-dev-to-stg.sh "feat: 스테이징 배포"
./multigit-merge-stg-to-main.sh "release: 프로덕션 배포"
```

---

**작성일**: 2025-01-15
**버전**: 1.0
**문서 유지보수**: 스크립트 수정 시 이 문서도 함께 업데이트하세요.
