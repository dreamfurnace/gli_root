# GLI Platform 배포 후 발견된 문제 분석 및 해결 계획

**작성일**: 2025-10-13
**상태**: 분석 완료, 해결 진행 중

## 🔍 발견된 문제 목록

### 1. ❌ 로컬 DB 데이터가 RDS로 이전되지 않음
**심각도**: HIGH
**현황**:
- 로컬 환경: SQLite (`db.sqlite3`, 512KB)
- RDS 환경: PostgreSQL (AWS Secrets Manager로 관리)
- 데이터 마이그레이션 미실행

**원인**:
- 로컬 개발 시 SQLite 사용
- RDS는 PostgreSQL로 설정
- 자동 마이그레이션 스크립트 부재

**해결 방법**:
1. SQLite 데이터를 덤프
2. PostgreSQL 호환 형식으로 변환
3. RDS로 데이터 import
4. Django 마이그레이션 실행

**관련 파일**:
- `gli_api-server/db.sqlite3`
- RDS 접속 정보: AWS Secrets Manager `gli/db/staging`

---

### 2. ❌ /business 페이지 DB 데이터 미표시
**심각도**: HIGH
**현황**:
- https://stg.glibiz.com/business 페이지에서 팀 구성원, 개발 일정 등 모든 데이터가 비어있음
- 로컬에서는 정상 표시

**원인**:
1. Backend API가 배포되지 않음 (stg-api.glibiz.com 미구동)
2. DB 데이터 부재 (문제 #1과 연관)
3. S3 미디어 파일 부재

**해결 방법**:
1. GitHub Secrets 설정 완료
2. Backend API 배포 (Django + WebSocket)
3. DB 데이터 마이그레이션
4. S3 미디어 파일 업로드

**확인 필요**:
```bash
# API 상태 확인
curl https://stg-api.glibiz.com/health/

# DB 연결 확인
curl https://stg-api.glibiz.com/api/business/
```

---

### 3. ❌ 다국어(i18n) 텍스트가 키로 표시됨
**심각도**: MEDIUM
**현황**:
- `business.team.title`, `business.team.empty` 등이 번역되지 않고 키로 표시
- 로컬(localhost:3000)에서는 정상 표시
- stg 배포에서만 문제 발생

**원인 분석**:
1. **Vite 빌드 설정 문제**: `.ts` locale 파일이 제대로 번들링되지 않음
2. **Dynamic import 문제**: locale 파일 로딩 실패
3. **환경변수 문제**: i18n fallback locale 설정 누락

**해결 방법**:
1. `vite.config.ts` 확인 및 수정
2. i18n 플러그인 설정 검증
3. locale 파일을 `.json`으로 변환 (필요시)
4. 빌드 시 locale 파일 포함 여부 확인

**관련 파일**:
- `gli_user-frontend/src/i18n/locales/ko.ts`
- `gli_user-frontend/src/i18n/locales/en.ts`
- `gli_user-frontend/src/i18n/index.ts`
- `gli_user-frontend/vite.config.ts`

---

### 4. ❌ 더미 계정 로그인 UI가 모든 환경에서 보임
**심각도**: HIGH (보안)
**현황**:
- 로컬/stg/production 모두에서 더미 계정 원클릭 로그인 버튼이 표시됨
- production에서는 절대 보이면 안 됨

**원인**:
- 환경 변수 기반 조건부 렌더링 미구현

**해결 방법**:
1. `.env.development`, `.env.staging`, `.env.production` 파일 생성
2. `VITE_APP_ENV` 환경 변수 추가
3. 로그인 컴포넌트에 조건부 렌더링 추가:
   ```vue
   <template>
     <div v-if="import.meta.env.VITE_APP_ENV !== 'production'">
       <!-- 더미 계정 버튼 -->
     </div>
   </template>
   ```

**적용 대상**:
- `gli_user-frontend/src/views/LoginView.vue`
- `gli_admin-frontend/src/views/LoginView.vue`

---

### 5. ⚠️ TypeScript 타입 에러
**심각도**: MEDIUM
**현황**:
- `TokenConversionView.vue`: Property 'status', 'connect' 등 타입 에러
- `profileEditStore.ts`: 'profile_image_url' vs 'profile_image' 불일치
- 현재 `npm run build-only`로 우회하여 빌드

**원인**:
1. 타입 정의 불일치
2. API 응답 타입과 프론트 타입 불일치
3. never 타입 추론 문제

**해결 방법**:
1. `TokenConversionView.vue`: 트랜잭션 타입 명시적 정의
2. `profileEditStore.ts`: API 스키마와 동기화
3. `useSolanaAuth.ts`: window.phantom 타입 확장

**우선순위**: LOW (기능 동작에 영향 없음)

---

## 📊 우선순위 및 작업 순서

### Phase 1: 긴급 (보안 및 기능)
1. ✅ **Task 14**: 더미 계정 UI 환경별 표시 (보안 이슈)
2. 🔄 **Task 12**: Backend API 배포 및 DB 연결
3. 🔄 **Task 11**: DB 데이터 마이그레이션

### Phase 2: 중요 (UX)
4. 🔄 **Task 13**: i18n 문제 해결

### Phase 3: 개선
5. 🔄 **Task 15**: TypeScript 타입 에러 수정

---

## 🎯 즉시 실행 가능한 액션

### A. Backend API 배포 (최우선)
```bash
# 1. GitHub Secrets 설정
cd /path/to/gli_root
./setup-github-secrets.sh

# 2. Backend 배포 트리거
./multigit-push-stg.sh
```

### B. 더미 계정 UI 숨김 (보안)
```bash
# 환경 변수 파일 생성 및 컴포넌트 수정
cd gli_user-frontend
# .env.production에 VITE_APP_ENV=production 추가
# LoginView.vue 수정
```

### C. i18n 문제 디버깅
```bash
# 빌드된 파일 확인
cd gli_user-frontend/dist
grep -r "business.team.title" .
# locale 파일이 번들에 포함되었는지 확인
```

---

## 📝 Task Master 등록 완료

- ✅ Task 11: Local Database Migration to AWS RDS
- ✅ Task 12: Frontend Database and S3 Connection Troubleshooting
- ✅ Task 13: Internationalization (i18n) Text Display Bug Fix
- ✅ Task 14: One-Click Dummy Account Login UI for Dev/Staging
- ✅ Task 15: Fix TypeScript Type Errors

---

## 🔗 관련 문서

- [INFRASTRUCTURE_STATUS.md](./INFRASTRUCTURE_STATUS.md)
- [GITHUB_SECRETS_SETUP.md](./GITHUB_SECRETS_SETUP.md)
- [DEPLOYMENT_GUIDE.md](./DEPLOYMENT_GUIDE.md)

---

**다음 업데이트**: 각 문제 해결 후 상태 업데이트
