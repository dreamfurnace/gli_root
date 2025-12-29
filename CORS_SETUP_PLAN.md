# 🚀 GLI 뉴스 API → gligateway.com CORS 연동 계획서

## 📋 목차
1. [작업 완료 내역](#작업-완료-내역)
2. [배포 및 테스트 계획](#배포-및-테스트-계획)
3. [gligateway 프론트엔드 개발](#gligateway-프론트엔드-개발)
4. [최종 검증 체크리스트](#최종-검증-체크리스트)
5. [오류 대응 가이드](#오류-대응-가이드)

---

## ✅ 작업 완료 내역

### 1. CORS 설정 수정 완료
**파일**: `/Users/ahndonghyun/dongfiles/ADHcode/DreamFurnace/gli_root/gli_api-server/config/settings.py`

#### 변경 내용:
```python
# Staging 환경 (146-154줄)
elif ENV == "staging":
    CORS_ALLOW_ALL_ORIGINS = False
    CORS_ALLOWED_ORIGINS += [
        "http://localhost:5173",
        "https://staging-gli-frontend.com",
        "https://gligateway.com",  # ✅ 추가
        "http://localhost:5174",  # ✅ 추가 (로컬 개발용)
    ]

# Production 환경 (155-162줄)
elif ENV == "production":
    CORS_ALLOW_ALL_ORIGINS = False
    CORS_ALLOWED_ORIGINS += [
        "https://gli-user-frontend.com",
        "https://gli-admin-frontend.com",
        "https://gligateway.com",  # ✅ 추가
    ]
```

### 2. 테스트 도구 생성 완료
1. **Bash 스크립트**: `test-cors-gligateway.sh` (curl 기반)
2. **HTML 테스트 페이지**: `test-cors-browser.html` (브라우저 기반)

---

## 🚢 배포 및 테스트 계획

### Phase 1: 로컬 환경 테스트

#### 1-1. Django 서버 재시작 (설정 반영)
```bash
cd /Users/ahndonghyun/dongfiles/ADHcode/DreamFurnace/gli_root

# 기존 서버 종료
pkill -9 -f gli_

# 서버 재시작
./restart-api-server.sh --bf
```

#### 1-2. CORS 설정 확인
```bash
# 서버 재시작 후 로그 확인
tail -f logs/api-server-*.log | grep CORS
```

**예상 출력**:
```
✅ CORS 설정 (development): ALLOW_ALL=True, ORIGINS=[...]
```

#### 1-3. 브라우저 테스트
1. `test-cors-browser.html` 파일을 브라우저로 열기
2. "로컬 환경" 섹션에서 "뉴스 목록 조회" 클릭
3. ✅ 성공: CORS 헤더 확인
4. ❌ 실패: 브라우저 개발자 도구 → Console/Network 탭에서 오류 확인

---

### Phase 2: 스테이징 환경 배포

#### 2-1. Git 커밋 및 푸시
```bash
cd /Users/ahndonghyun/dongfiles/ADHcode/DreamFurnace/gli_root

git add gli_api-server/config/settings.py
git commit -m "feat: Add gligateway.com to CORS allowed origins

- 스테이징 환경에 https://gligateway.com 추가
- 운영 환경에 https://gligateway.com 추가
- 로컬 개발용 http://localhost:5174 추가

Related: gligateway 홈페이지 뉴스 API 연동"

git push origin stg
```

#### 2-2. 스테이징 서버 배포 대기
- AWS Elastic Beanstalk 또는 배포 파이프라인이 자동으로 배포
- 배포 완료 시간: 약 5-10분

#### 2-3. 스테이징 CORS 테스트
```bash
# curl로 간단 테스트
curl -I "https://stg-api.glibiz.com/api/news/" \
  -H "Origin: https://gligateway.com" | grep -i "access-control"
```

**예상 출력**:
```
Access-Control-Allow-Origin: https://gligateway.com
Access-Control-Allow-Credentials: true
```

또는 브라우저에서 `test-cors-browser.html` 열어서 "스테이징 환경" 테스트

---

### Phase 3: 운영 환경 배포

#### 3-1. main 브랜치 머지
```bash
# stg → main 머지
git checkout main
git merge stg
git push origin main
```

#### 3-2. 운영 서버 배포 확인
- 배포 완료 후 약 5-10분 대기

#### 3-3. 운영 CORS 테스트
```bash
curl -I "https://api.glibiz.com/api/news/" \
  -H "Origin: https://gligateway.com" | grep -i "access-control"
```

---

## 🎨 gligateway 프론트엔드 개발

### Step 1: 환경 변수 설정

#### 로컬 개발용 `.env.local` 생성
**경로**: `/Users/ahndonghyun/dongfiles/ADHcode/DreamFurnace/gligateway/gligatew_user-frontend/.env.local`

```env
VITE_API_BASE_URL=https://stg-api.glibiz.com
VITE_ENV=development
```

#### 운영 배포용 `.env.production` 확인 (이미 올바름)
```env
VITE_API_BASE_URL=https://api.glibiz.com
VITE_ENV=production
```

---

### Step 2: TypeScript 타입 정의

**파일**: `src/types/index.ts`

```typescript
// 기존 NewsItem 인터페이스 수정
export interface NewsItem {
  id: string; // ✅ number → string으로 변경 (UUID)
  title: string;
  badge: 'NEWS IN GLI' | 'PRODUCT UPDATES' | 'PARTNERSHIPS' | 'CLIENTS';
  summary: string;
  content: string;
  image: string;
  date: string;
  link?: string;
}

// ✅ 신규 추가: API 응답 타입
export interface NewsArticleAPI {
  id: string;
  title_ko: string;
  title_en: string;
  content_ko: string;
  content_en: string;
  image_url: string;
  external_url: string | null;
  publication_date: string;
  status: 'draft' | 'published' | 'archived';
  order: number;
  is_active: boolean;
  created_at: string;
  updated_at: string;
}
```

---

### Step 3: API 유틸리티 함수 생성

**파일**: `src/utils/api.ts` (신규 생성)

```typescript
import axios from 'axios';
import { NewsItem, NewsArticleAPI } from '../types';

const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || 'https://stg-api.glibiz.com';

// API 응답을 NewsItem으로 변환
export const transformNewsArticle = (article: NewsArticleAPI): NewsItem => {
  return {
    id: article.id,
    title: article.title_ko || article.title_en,
    badge: 'NEWS IN GLI', // 기본값 (추후 API에 필드 추가 시 수정)
    summary: article.content_ko.substring(0, 150) + (article.content_ko.length > 150 ? '...' : ''),
    content: article.content_ko || article.content_en,
    image: article.image_url,
    date: formatDate(article.publication_date),
    link: article.external_url || undefined,
  };
};

// 날짜 포맷 변환
const formatDate = (dateString: string): string => {
  const date = new Date(dateString);
  return date.toISOString().split('T')[0].replace(/-/g, '.');
};

// 뉴스 목록 가져오기
export const fetchNewsList = async (): Promise<NewsItem[]> => {
  try {
    const response = await axios.get<NewsArticleAPI[]>(`${API_BASE_URL}/api/news/`);
    return response.data.map(transformNewsArticle);
  } catch (error) {
    console.error('뉴스 목록 조회 실패:', error);
    throw error;
  }
};

// 뉴스 상세 가져오기
export const fetchNewsDetail = async (id: string): Promise<NewsItem> => {
  try {
    const response = await axios.get<NewsArticleAPI>(`${API_BASE_URL}/api/news/${id}/`);
    return transformNewsArticle(response.data);
  } catch (error) {
    console.error('뉴스 상세 조회 실패:', error);
    throw error;
  }
};
```

---

### Step 4: 컴포넌트 수정

#### `src/pages/NewsListPage.tsx` 수정

```typescript
// 기존 코드 (19-30줄)
const fetchNews = async () => {
  try {
    const response = await axios.get("/data/news.json");
    setNews(response.data);
    setFilteredNews(response.data);
  } catch (error) {
    console.error("Error fetching news:", error);
  }
};

// ↓ 변경 후
import { fetchNewsList } from "../utils/api";

const fetchNews = async () => {
  try {
    const data = await fetchNewsList();
    setNews(data);
    setFilteredNews(data);
  } catch (error) {
    console.error("Error fetching news:", error);
    // 폴백: 기존 JSON 파일 사용
    try {
      const response = await axios.get("/data/news.json");
      setNews(response.data);
      setFilteredNews(response.data);
    } catch (fallbackError) {
      console.error("Fallback also failed:", fallbackError);
    }
  }
};
```

#### `src/pages/NewsDetailPage.tsx` 수정

```typescript
// 기존 코드 (18-32줄)
const fetchNews = async () => {
  try {
    const response = await axios.get("/data/news.json");
    const newsItem = response.data.find(
      (item: NewsItem) => item.id === Number(id) // ❌ Number(id) 제거
    );
    setNews(newsItem || null);
  } catch (error) {
    console.error("Error fetching news:", error);
  } finally {
    setLoading(false);
  }
};

// ↓ 변경 후
import { fetchNewsDetail } from "../utils/api";

const fetchNews = async () => {
  try {
    if (id) {
      const data = await fetchNewsDetail(id); // ✅ UUID 문자열 직접 전달
      setNews(data);
    }
  } catch (error) {
    console.error("Error fetching news:", error);
    // 폴백: 기존 JSON 파일 사용
    try {
      const response = await axios.get("/data/news.json");
      const newsItem = response.data.find(
        (item: NewsItem) => item.id === id // ✅ Number() 제거
      );
      setNews(newsItem || null);
    } catch (fallbackError) {
      console.error("Fallback also failed:", fallbackError);
    }
  } finally {
    setLoading(false);
  }
};
```

---

### Step 5: 로컬 테스트

```bash
cd /Users/ahndonghyun/dongfiles/ADHcode/DreamFurnace/gligateway/gligatew_user-frontend

# 의존성 설치 (필요시)
npm install

# 로컬 개발 서버 실행
npm run dev
```

**테스트 항목**:
1. http://localhost:5173/news 접속
2. 뉴스 목록이 API에서 조회되는지 확인
3. 뉴스 카드 클릭 → 상세 페이지 이동
4. 이미지, 제목, 내용, 날짜가 정상 표시되는지 확인
5. 브라우저 개발자 도구 → Network 탭에서 API 요청 확인

---

## ✅ 최종 검증 체크리스트

### 로컬 환경
- [ ] Django 서버 재시작 완료
- [ ] `test-cors-browser.html` 로컬 테스트 성공
- [ ] gligateway `npm run dev` 실행 성공
- [ ] 뉴스 목록 페이지 정상 작동
- [ ] 뉴스 상세 페이지 정상 작동
- [ ] 이미지 로딩 정상
- [ ] 날짜 포맷 정상

### 스테이징 환경
- [ ] settings.py 변경사항 stg 브랜치에 커밋/푸시
- [ ] 스테이징 서버 배포 완료
- [ ] curl CORS 테스트 통과
- [ ] `test-cors-browser.html` 스테이징 테스트 성공
- [ ] https://stg-admin.glibiz.com/admin/ 에서 뉴스 관리 정상
- [ ] 뉴스 추가/수정 시 즉시 반영 확인

### 운영 환경
- [ ] main 브랜치 머지 및 푸시
- [ ] 운영 서버 배포 완료
- [ ] curl CORS 테스트 통과
- [ ] `test-cors-browser.html` 운영 테스트 성공
- [ ] gligateway를 운영 환경에 배포 (`npm run build`)
- [ ] https://gligateway.com/news 접속 성공
- [ ] https://admin.glibiz.com/admin/ 에서 뉴스 관리 → gligateway에 즉시 반영

---

## 🚨 오류 대응 가이드

### 오류 1: CORS 헤더 없음
**증상**: 브라우저 콘솔에 `Access-Control-Allow-Origin` 오류

**원인**:
- Django 서버가 재시작되지 않음
- 설정이 배포되지 않음
- CORS 미들웨어 미작동

**해결**:
```bash
# 1. Django 서버 재시작
pkill -9 -f gli_
./restart-api-server.sh --bf

# 2. 로그 확인
tail -f logs/api-server-*.log | grep CORS

# 3. curl로 직접 확인
curl -I "http://localhost:8000/api/news/" -H "Origin: https://gligateway.com"
```

---

### 오류 2: 빈 뉴스 목록
**증상**: API 호출은 성공하지만 `[]` 빈 배열 반환

**원인**: published 상태의 뉴스가 없음

**해결**:
1. 관리자 페이지 접속: https://stg-admin.glibiz.com/admin/
2. News articles 메뉴 클릭
3. 최소 1개 이상의 뉴스를:
   - status: `published`
   - is_active: ✅ 체크
   - publication_date: 과거 날짜

---

### 오류 3: 이미지 로딩 실패
**증상**: 뉴스는 표시되지만 이미지가 깨짐

**원인**:
- image_url이 잘못되었거나 null
- S3 이미지 CORS 설정 문제

**해결**:
```bash
# 1. API 응답에서 image_url 확인
curl -s "https://stg-api.glibiz.com/api/news/" | python3 -m json.tool | grep image_url

# 2. S3 CORS 설정 확인 (필요시 AWS 콘솔에서 수정)
```

---

### 오류 4: UUID 파싱 오류
**증상**: `item.id === Number(id)` 에서 TypeError

**원인**: UUID를 숫자로 변환 시도

**해결**:
```typescript
// ❌ 잘못된 코드
const newsItem = data.find(item => item.id === Number(id));

// ✅ 올바른 코드
const newsItem = data.find(item => item.id === id);
```

---

### 오류 5: 환경 변수 미적용
**증상**: 로컬에서 `api.glibiz.com`을 호출

**원인**: `.env.local` 파일이 없거나 잘못됨

**해결**:
```bash
# 1. .env.local 파일 확인
cat .env.local

# 2. Vite 서버 재시작
npm run dev

# 3. 브라우저 콘솔에서 확인
console.log(import.meta.env.VITE_API_BASE_URL)
```

---

## 📞 지원 및 연락처

**문제 발생 시**:
1. 브라우저 개발자 도구 → Console/Network 탭 스크린샷
2. Django 서버 로그 (`logs/api-server-*.log`)
3. 실행한 명령어 및 오류 메시지

**테스트 파일**:
- Bash 스크립트: `./test-cors-gligateway.sh`
- HTML 테스트: `./test-cors-browser.html`

---

**작성일**: 2025-12-29
**작성자**: Claude Code
**버전**: 1.0
