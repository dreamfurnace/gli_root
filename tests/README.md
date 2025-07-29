# GLI Platform - Integrated Testing Environment

## 📋 개요

GLI Platform의 통합 테스트 환경입니다. 모든 컴포넌트(Frontend, Backend, Database)에 대한 테스트를 중앙집중식으로 관리합니다.

## 🏗️ 테스트 구조

```
tests/
├── __tests__/                    # 단위 테스트
│   ├── frontend/                 # 프론트엔드 단위 테스트
│   │   ├── user/                 # User Frontend 테스트
│   │   └── admin/                # Admin Frontend 테스트
│   ├── backend/                  # 백엔드 단위 테스트
│   │   ├── api/                  # API 엔드포인트 테스트
│   │   ├── models/               # 데이터베이스 모델 테스트
│   │   └── services/             # 비즈니스 로직 테스트
│   └── shared/                   # 공통 컴포넌트 테스트
├── e2e/                          # End-to-End 테스트
│   ├── user-flows/               # 사용자 플로우 테스트
│   ├── admin-flows/              # 관리자 플로우 테스트
│   ├── web3-integration/         # Web3 통합 테스트
│   └── cross-platform/           # 플랫폼 간 테스트
├── integration/                  # 통합 테스트
│   ├── api-database/             # API-DB 통합 테스트
│   ├── frontend-backend/         # Frontend-Backend 통합
│   ├── web3-backend/             # Web3-Backend 통합
│   └── full-stack/               # 전체 스택 통합 테스트
├── performance/                  # 성능 테스트
│   ├── load-testing/             # 부하 테스트
│   ├── stress-testing/           # 스트레스 테스트
│   ├── web3-performance/         # Web3 성능 테스트
│   └── database-performance/     # 데이터베이스 성능 테스트
├── security/                     # 보안 테스트
│   ├── authentication/           # 인증 보안 테스트
│   ├── authorization/            # 권한 보안 테스트
│   ├── web3-security/            # Web3 보안 테스트
│   └── vulnerability-scanning/   # 취약점 스캔
├── accessibility/                # 접근성 테스트
│   ├── wcag-compliance/          # WCAG 준수 테스트
│   ├── screen-reader/            # 스크린 리더 테스트
│   └── keyboard-navigation/      # 키보드 내비게이션 테스트
├── scripts/                      # 테스트 스크립트
│   ├── setup/                    # 테스트 환경 설정
│   ├── runners/                  # 테스트 실행기
│   ├── validators/               # 테스트 검증기
│   └── reporters/                # 테스트 리포터
├── config/                       # 테스트 설정
│   ├── jest.config.js            # Jest 설정
│   ├── playwright.config.ts      # Playwright 설정
│   ├── vitest.config.ts          # Vitest 설정
│   └── environments/             # 환경별 설정
├── fixtures/                     # 테스트 데이터
│   ├── users/                    # 사용자 테스트 데이터
│   ├── contracts/                # 계약서 테스트 데이터
│   ├── transactions/             # 거래 테스트 데이터
│   └── mock-data/                # Mock 데이터
├── shared/                       # 공통 테스트 유틸리티
│   ├── helpers/                  # 테스트 헬퍼 함수
│   ├── mocks/                    # Mock 객체
│   ├── matchers/                 # 커스텀 매처
│   └── setup/                    # 공통 설정
├── utils/                        # 테스트 유틸리티
│   ├── database-utils.ts         # 데이터베이스 유틸리티
│   ├── web3-utils.ts             # Web3 테스트 유틸리티
│   ├── api-utils.ts              # API 테스트 유틸리티
│   └── browser-utils.ts          # 브라우저 테스트 유틸리티
├── coverage/                     # 커버리지 리포트
├── reports/                      # 테스트 결과 리포트
├── test-results/                 # 테스트 아티팩트
└── docker/                       # 테스트용 Docker 설정
    ├── test-database/            # 테스트 데이터베이스
    └── test-services/            # 테스트 서비스
```

## 🚀 테스트 실행 방법

### 전체 테스트 실행
```bash
# 모든 테스트 실행
npm run test:all

# 특정 유형별 테스트 실행
npm run test:unit          # 단위 테스트
npm run test:integration   # 통합 테스트
npm run test:e2e          # E2E 테스트
npm run test:performance  # 성능 테스트
npm run test:security     # 보안 테스트
npm run test:accessibility # 접근성 테스트
```

### 컴포넌트별 테스트 실행
```bash
# Frontend 테스트
npm run test:frontend:user     # User Frontend
npm run test:frontend:admin    # Admin Frontend

# Backend 테스트
npm run test:backend:api       # API 테스트
npm run test:backend:models    # 모델 테스트

# Web3 테스트
npm run test:web3:solana       # Solana 통합 테스트
npm run test:web3:ethereum     # Ethereum 테스트
```

### CI/CD 테스트
```bash
# CI용 빠른 테스트
npm run test:ci

# 프로덕션 배포 전 테스트
npm run test:production
```

## 🛠️ 테스트 도구 및 기술 스택

### Frontend 테스트
- **Vitest**: Vue 3 컴포넌트 단위 테스트
- **Vue Test Utils**: Vue 컴포넌트 테스트 유틸리티
- **Playwright**: E2E 테스트 및 브라우저 자동화

### Backend 테스트
- **Jest**: Django REST API 테스트
- **Django Test Client**: Django 내장 테스트 클라이언트
- **Factory Boy**: 테스트 데이터 생성

### Web3 테스트
- **Solana Test Validator**: Solana 로컬 테스트 환경
- **Phantom Wallet Mock**: 지갑 연동 테스트
- **Web3.py**: Python Web3 테스트 도구

### 통합 및 성능 테스트
- **Docker Compose**: 테스트 환경 격리
- **Locust**: 부하 테스트
- **Artillery**: API 성능 테스트

## 📊 테스트 커버리지 목표

| 컴포넌트 | 단위 테스트 | 통합 테스트 | E2E 테스트 |
|----------|-------------|-------------|------------|
| User Frontend | 80%+ | 70%+ | 90%+ |
| Admin Frontend | 80%+ | 70%+ | 90%+ |
| Backend API | 90%+ | 85%+ | 95%+ |
| Web3 Integration | 85%+ | 80%+ | 95%+ |
| Database Models | 95%+ | 90%+ | N/A |

## 🔄 CI/CD 통합

### GitHub Actions 워크플로우
```yaml
# .github/workflows/test.yml
name: GLI Platform Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Run integrated tests
        run: |
          cd tests
          npm install
          npm run test:ci
```

### 테스트 단계별 실행
1. **PR 생성 시**: 빠른 단위 테스트 + 린트
2. **main 브랜치 머지 시**: 전체 통합 테스트
3. **배포 전**: 성능 + 보안 + 접근성 테스트

## 📈 테스트 메트릭 및 리포팅

### 자동 생성 리포트
- **커버리지 리포트**: `coverage/index.html`
- **성능 테스트 리포트**: `reports/performance/`
- **접근성 테스트 리포트**: `reports/accessibility/`
- **보안 스캔 리포트**: `reports/security/`

### 대시보드 통합
- **SonarQube**: 코드 품질 및 커버리지
- **Allure**: 통합 테스트 리포팅
- **Grafana**: 성능 메트릭 모니터링

## 🚨 테스트 실패 시 대응

### 자동화된 알림
- Slack 채널 알림
- 이메일 리포트
- GitHub 이슈 자동 생성

### 디버깅 지원
- 실패한 테스트 스크린샷 자동 저장
- 로그 파일 자동 수집
- 재현 가능한 테스트 환경 제공

## 📝 테스트 작성 가이드

### 테스트 네이밍 컨벤션
```javascript
// 단위 테스트
describe('UserAuth', () => {
  it('should authenticate user with valid wallet signature', () => {
    // 테스트 코드
  })
})

// E2E 테스트
test('User can complete contract creation workflow', async ({ page }) => {
  // 테스트 코드
})
```

### 테스트 데이터 관리
- Fixture 파일 사용으로 테스트 데이터 중앙화
- 환경별 테스트 데이터 분리
- 민감 정보 제외 원칙

## 🔧 개발자 가이드

### 새로운 기능 개발 시
1. 단위 테스트 먼저 작성 (TDD)
2. 통합 테스트 추가
3. E2E 테스트로 사용자 시나리오 검증

### 테스트 디버깅
```bash
# 특정 테스트 디버그 모드 실행
npm run test:debug -- --testNamePattern="user authentication"

# 브라우저에서 E2E 테스트 디버깅
npm run test:e2e:debug
```

## 📚 참고 문서

- [Jest 테스트 가이드](https://jestjs.io/docs/getting-started)
- [Playwright 사용법](https://playwright.dev/docs/intro)
- [Vue Test Utils](https://test-utils.vuejs.org/)
- [Django Testing](https://docs.djangoproject.com/en/stable/topics/testing/)
- [Web3 테스팅 Best Practices](https://docs.soliditylang.org/en/latest/testing.html)

---

이 통합 테스트 환경을 통해 GLI Platform의 품질과 안정성을 보장하고, 지속적인 개선을 통해 사용자 경험을 향상시킵니다.