# Axios 중앙화 가이드

## 📋 개요

GLI 프로젝트의 모든 프론트엔드에서 axios는 **단 한 번만 생성**되고, **모든 API 호출은 이 중앙 인스턴스를 통해** 이루어집니다.

## 🎯 핵심 원칙

1. **단일 axios 인스턴스**: 각 프론트엔드는 하나의 중앙화된 axios 인스턴스만 사용
2. **환경 변수 한 곳 주입**: API 엔드포인트는 환경 변수에서 한 번만 읽어서 주입
3. **raw axios 금지**: `axios.get()`, `axios.post()` 등 직접 호출 금지
4. **중앙 인스턴스 사용**: 모든 API 호출은 설정된 인스턴스를 통해서만

## 📁 프로젝트별 구조

### 1. User Frontend (`gli_user-frontend`)

#### 중앙 axios 파일
```
src/services/api.ts
```

#### 주요 구성
```typescript
// 환경 변수에서 API 베이스 URL 읽기 (단 한 번)
const API_BASE_URL = getApiBaseUrl();

// 메인 axios 인스턴스 (interceptor 포함)
const apiClient = axios.create({
    baseURL: API_BASE_URL,
    timeout: 10000,
    headers: { "Content-Type": "application/json" }
});

// refresh 전용 axios 인스턴스 (interceptor 없음, 무한 루프 방지)
const refreshClient = axios.create({
    baseURL: API_BASE_URL,
    timeout: 10000,
    headers: { "Content-Type": "application/json" }
});
```

#### 환경 변수
```env
# .env.development
VITE_API_BASE_URL=http://localhost:8000

# .env.staging
VITE_API_BASE_URL=https://stg-api.glibiz.com

# .env.production
VITE_API_BASE_URL=https://api.glibiz.com
```

#### 사용 예시
```typescript
import { authAPI, profileAPI } from '@/services/api';

// ✅ 올바른 사용
const response = await authAPI.login(credentials);
const profile = await profileAPI.getProfile();

// ❌ 잘못된 사용
import axios from 'axios';
const response = await axios.post('https://api.com/login', data);
```

---

### 2. Admin Frontend (`gli_admin-frontend`)

#### 중앙 axios 파일
```
src/utils/axios.ts  (메인 axios 인스턴스)
src/services/api.ts (API Service 레이어)
```

#### 주요 구성
```typescript
// src/utils/axios.ts - 중앙 axios 인스턴스
const api = axios.create({
    baseURL: import.meta.env.VITE_API_BASE,
    withCredentials: true,
    timeout: 5000,
    headers: { 'Content-Type': 'application/json' }
});

// src/services/api.ts - API Service가 중앙 인스턴스 사용
import api from '@/utils/axios';

class ApiService {
    private client: AxiosInstance;

    constructor() {
        this.client = api;  // ✅ 중앙 인스턴스 사용
    }
}
```

#### 환경 변수
```env
# .env.development
VITE_API_BASE=http://localhost:8000

# .env.staging
VITE_API_BASE=https://stg-api.glibiz.com

# .env.production
VITE_API_BASE=https://api.glibiz.com
```

#### 사용 예시
```typescript
import { apiService } from '@/services/api';

// ✅ 올바른 사용
const members = await apiService.getMembers();
const news = await apiService.getNews();

// ❌ 잘못된 사용
import axios from 'axios';
const members = await axios.get('https://api.com/members');
```

---

## 🔧 Interceptor 설정

### Request Interceptor (요청 전)
- ✅ 자동 토큰 추가 (`Bearer ${token}`)
- ✅ 보안 헤더 추가
- ✅ CSRF 토큰 추가 (non-GET 요청)
- ✅ Rate limiting 체크

### Response Interceptor (응답 후)
- ✅ 401 에러 시 자동 토큰 갱신
- ✅ 토큰 갱신 실패 시 자동 로그아웃
- ✅ 에러 로깅 및 보안 모니터링

---

## ⚠️ 주의사항

### 1. Token Refresh 무한 루프 방지

**문제**: Token refresh API 호출 시 같은 interceptor를 타면 무한 루프 발생

**해결** (user-frontend):
```typescript
// ❌ 잘못된 방법 - 무한 루프 발생
const response = await axios.post(`${API_BASE_URL}/auth/refresh/`, data);

// ✅ 올바른 방법 - refresh 전용 클라이언트 사용
const response = await refreshClient.post('/auth/refresh/', data);
```

**해결** (admin-frontend):
```typescript
// ✅ utils/axios.ts의 interceptor에서 처리
// token refresh 시 _retry 플래그로 중복 방지
if (originalRequest._retry) return Promise.reject(error);
originalRequest._retry = true;
```

### 2. API Base URL 통일

현재 **불일치 발견**:
- User Frontend: `VITE_API_BASE_URL`
- Admin Frontend: `VITE_API_BASE`

**권장 사항**: 향후 `VITE_API_BASE_URL`로 통일 권장

### 3. `/api` 경로 처리

**user-frontend**: 자동으로 `/api` 추가
```typescript
const getApiBaseUrl = (): string => {
    const baseUrl = import.meta.env.VITE_API_BASE_URL;
    if (baseUrl.endsWith("/api")) return baseUrl;
    return `${baseUrl}/api`;
};
```

**admin-frontend**: 환경 변수에 `/api` 포함 여부 확인 필요

---

## 📝 체크리스트

새로운 API 호출 추가 시:

- [ ] raw `axios.get()`, `axios.post()` 사용하지 않았는가?
- [ ] 중앙 인스턴스 (`apiClient`, `api`) 또는 API 함수 사용했는가?
- [ ] 토큰이 자동으로 추가되는가? (interceptor 확인)
- [ ] 401 에러 시 자동 refresh가 동작하는가?
- [ ] 환경 변수에서 API URL을 직접 읽지 않았는가?

---

## 🚀 마이그레이션 완료 상태

### User Frontend ✅
- [x] 중앙 axios 인스턴스 생성 완료
- [x] raw axios 사용 제거 완료
- [x] refresh 전용 클라이언트 분리 완료
- [x] API 함수들 중앙 인스턴스 사용

### Admin Frontend ✅
- [x] 중앙 axios 인스턴스 생성 완료
- [x] ApiService가 중앙 인스턴스 사용하도록 수정
- [x] 중복 interceptor 제거 완료
- [x] raw axios 사용 제거 완료

---

## 📚 관련 파일

### User Frontend
- `src/services/api.ts` - 중앙 axios 인스턴스 및 모든 API 함수
- `src/utils/security.ts` - 보안 관련 유틸리티

### Admin Frontend
- `src/utils/axios.ts` - 중앙 axios 인스턴스
- `src/services/api.ts` - API Service 레이어

---

## 🔍 검증 방법

```bash
# raw axios 사용 검색 (user-frontend)
cd gli_user-frontend
grep -rn "axios\." src/ --include="*.ts" --include="*.tsx" --include="*.vue" | \
  grep -v "import axios" | \
  grep -E "(axios\.get|axios\.post|axios\.put|axios\.delete)"

# raw axios 사용 검색 (admin-frontend)
cd gli_admin-frontend
grep -rn "axios\." src/ --include="*.ts" --include="*.tsx" --include="*.vue" | \
  grep -v "import axios" | \
  grep -E "(axios\.get|axios\.post|axios\.put|axios\.delete)"
```

결과가 없거나 `axios.create()` 부분만 나와야 정상입니다.

---

**작성일**: 2026-01-29
**작성자**: Claude Code
**버전**: 1.0
