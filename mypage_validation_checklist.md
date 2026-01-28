# MyPage 구현 최종 검증 체크리스트

## 📋 Phase 1: DB 모델 검증

### 테이블 생성 확인
- [ ] `security_settings` 테이블 존재 확인
  ```sql
  SELECT * FROM security_settings LIMIT 1;
  ```
- [ ] `usage_history` 테이블 존재 확인
  ```sql
  SELECT * FROM usage_history LIMIT 1;
  ```
- [ ] `swap_transactions` 테이블 존재 확인
  ```sql
  SELECT * FROM swap_transactions LIMIT 1;
  ```
- [ ] `token_balances` 테이블 존재 확인
  ```sql
  SELECT * FROM token_balances LIMIT 1;
  ```
- [ ] `exchange_rates` 테이블 존재 확인
  ```sql
  SELECT * FROM exchange_rates LIMIT 1;
  ```
- [ ] `projects` 테이블 존재 확인
  ```sql
  SELECT * FROM projects LIMIT 1;
  ```
- [ ] `wallet_address_book` 테이블 존재 확인
  ```sql
  SELECT * FROM wallet_address_book LIMIT 1;
  ```
- [ ] `portfolio_unstaking` 테이블 존재 확인
  ```sql
  SELECT * FROM portfolio_unstaking LIMIT 1;
  ```
- [ ] `investments` 테이블에 `pending_reward_usdt` 컬럼 추가 확인
  ```sql
  SELECT pending_reward_usdt FROM investments LIMIT 1;
  ```

### Django 마이그레이션 확인
- [ ] 마이그레이션 히스토리 확인
  ```bash
  cd gli_api-server
  python manage.py showmigrations solana_auth
  ```

---

## 📋 Phase 2: API 엔드포인트 검증

### 서버 실행 확인
- [ ] Django 서버 정상 실행
  ```bash
  cd gli_api-server
  source .venv/bin/activate
  python manage.py runserver 8000
  ```
- [ ] 패키지 설치 확인
  ```bash
  pip show pyotp
  pip show qrcode
  ```

### API 테스트 (인증 필요)

#### 공통 API
- [ ] **GET** `/api/user/profile-summary/`
  ```bash
  curl -H "Authorization: Bearer YOUR_TOKEN" \
       http://localhost:8000/api/user/profile-summary/
  ```

#### Tab 1: Profile
- [ ] **GET** `/api/user/profile/`
- [ ] **GET** `/api/user/sessions/`

#### Tab 2: Security
- [ ] **GET** `/api/user/security/status/`
- [ ] **POST** `/api/user/security/2fa/setup/`
- [ ] **POST** `/api/user/security/2fa/verify/`
  ```bash
  curl -X POST -H "Authorization: Bearer YOUR_TOKEN" \
       -H "Content-Type: application/json" \
       -d '{"code": "123456"}' \
       http://localhost:8000/api/user/security/2fa/verify/
  ```
- [ ] **POST** `/api/user/security/pin/set/`
  ```bash
  curl -X POST -H "Authorization: Bearer YOUR_TOKEN" \
       -H "Content-Type: application/json" \
       -d '{"pin": "123456"}' \
       http://localhost:8000/api/user/security/pin/set/
  ```
- [ ] **POST** `/api/user/security/pin/verify/`

#### Tab 3: Referral
- [ ] **GET** `/api/user/referral/qr-code/`
- [ ] **GET** `/api/user/referral/invitation-text/`

#### Tab 4: Dashboard
- [ ] **GET** `/api/user/dashboard/`
- [ ] **GET** `/api/user/swap/rate/?from=GLIB&to=GLID`
- [ ] **POST** `/api/user/swap/execute/`
  ```bash
  curl -X POST -H "Authorization: Bearer YOUR_TOKEN" \
       -H "Content-Type: application/json" \
       -d '{"from_token": "GLIB", "to_token": "GLID", "amount": 100}' \
       http://localhost:8000/api/user/swap/execute/
  ```

#### Tab 5: Portfolio
- [ ] **POST** `/api/user/portfolio/claim-reward/1/`
- [ ] **POST** `/api/user/portfolio/unsubscribe/1/`
- [ ] **POST** `/api/user/portfolio/cancel-unstaking/1/`

#### Tab 7: Usage
- [ ] **GET** `/api/user/usage-history/`
- [ ] **GET** `/api/user/usage-history/?type=GOLF`
- [ ] **GET** `/api/user/usage-history/receipt/RECEIPT-001/`

#### Tab 9: Wallet
- [ ] **GET** `/api/user/wallet/address-book/`
- [ ] **POST** `/api/user/wallet/address-book/add/`
  ```bash
  curl -X POST -H "Authorization: Bearer YOUR_TOKEN" \
       -H "Content-Type: application/json" \
       -d '{"name": "My Wallet", "address": "0x1234...abcd", "network": "SOLANA"}' \
       http://localhost:8000/api/user/wallet/address-book/add/
  ```
- [ ] **DELETE** `/api/user/wallet/address-book/1/`
- [ ] **PATCH** `/api/user/wallet/address-book/1/favorite/`

---

## 📋 Phase 3: Frontend 컴포넌트 검증

### 파일 존재 확인
- [ ] `gli_user-frontend/src/components/mypage/modals/BaseModal.vue`
- [ ] `gli_user-frontend/src/components/mypage/modals/Modal2FASetup.vue`
- [ ] `gli_user-frontend/src/components/mypage/modals/ModalPINSetup.vue`
- [ ] `gli_user-frontend/src/components/mypage/modals/ModalQRCode.vue`
- [ ] `gli_user-frontend/src/components/mypage/sections/ProfileSummary.vue`
- [ ] `gli_user-frontend/src/components/mypage/sections/MenuNavigation.vue`
- [ ] `gli_user-frontend/src/components/mypage/sections/SecurityCenter.vue`
- [ ] `gli_user-frontend/src/components/mypage/sections/DashboardOverview.vue`
- [ ] `gli_user-frontend/src/components/mypage/sections/SwapWidget.vue`
- [ ] `gli_user-frontend/src/components/mypage/sections/UsageHistory.vue`

### 컴포넌트 문법 검증
- [ ] Vue 파일 구문 오류 없음
  ```bash
  cd gli_user-frontend
  npm run build
  ```

### 컴포넌트 기능 테스트
- [ ] BaseModal 열기/닫기 동작
- [ ] ProfileSummary API 연동 확인
- [ ] MenuNavigation 탭 변경 이벤트
- [ ] SecurityCenter 모달 호출
- [ ] DashboardOverview 데이터 로드
- [ ] SwapWidget 환율 조회 및 교환
- [ ] UsageHistory 필터링
- [ ] Modal2FASetup QR 코드 표시
- [ ] ModalPINSetup PIN 입력
- [ ] ModalQRCode QR 코드 및 복사 기능

---

## 📋 Phase 4: 통합 테스트

### E2E 시나리오

#### 시나리오 1: 보안 설정 완전 플로우
1. [ ] MyPage 접속
2. [ ] Security 탭 클릭
3. [ ] 2FA 설정 버튼 클릭
4. [ ] QR 코드 표시 확인
5. [ ] OTP 앱으로 스캔
6. [ ] 인증 코드 입력
7. [ ] 2FA 활성화 확인

#### 시나리오 2: 토큰 교환 플로우
1. [ ] Dashboard 탭 접속
2. [ ] 현재 토큰 잔액 확인
3. [ ] SwapWidget에서 From/To 선택
4. [ ] 금액 입력
5. [ ] 환율 및 수수료 확인
6. [ ] 교환 실행
7. [ ] 잔액 업데이트 확인

#### 시나리오 3: 추천 코드 공유
1. [ ] Referral 탭 접속
2. [ ] QR 코드 보기 버튼 클릭
3. [ ] QR 코드 표시 확인
4. [ ] 추천 코드 복사
5. [ ] 초대장 문구 복사

#### 시나리오 4: 주소록 관리
1. [ ] Wallet 탭 접속
2. [ ] 주소 추가 버튼 클릭
3. [ ] 주소 정보 입력 및 저장
4. [ ] 주소록 목록에 표시 확인
5. [ ] 즐겨찾기 토글
6. [ ] 주소 삭제

---

## 📋 성능 및 보안 검증

### 성능
- [ ] API 응답 시간 < 500ms
- [ ] Frontend 초기 로딩 < 3초
- [ ] QR 코드 생성 < 1초
- [ ] Swap 실행 < 2초

### 보안
- [ ] 모든 API가 JWT 인증 필수
- [ ] PIN이 해싱되어 저장됨 확인
- [ ] 2FA 시크릿이 암호화됨 확인
- [ ] XSS 방지 (Vue의 자동 이스케이핑)
- [ ] CSRF 토큰 확인 (Django REST Framework)

---

## 📋 문서화 확인

- [ ] `mypage_implementation_summary.md` 생성
- [ ] `mypage_validation_checklist.md` 생성 (이 파일)
- [ ] API 명세서 업데이트 필요 확인
- [ ] 기존 명세서 문서 위치 확인

---

## 🚨 알려진 이슈 및 TODO

### 알려진 이슈
- [ ] 기존 MyPageView.vue와의 통합 방법 결정 필요
- [ ] Tab 6 (Service), Tab 8 (Notice) 미구현
- [ ] Portfolio 모델과의 연동 필요

### 향후 작업
- [ ] Postman 컬렉션 생성
- [ ] 단위 테스트 작성 (pytest)
- [ ] Frontend 단위 테스트 (Vitest)
- [ ] Swagger/OpenAPI 문서 자동 생성
- [ ] 실제 데이터로 테스트

---

## ✅ 최종 승인

### 체크리스트 요약
- [ ] Phase 1: DB 모델 (8개 테이블) - **완료**
- [ ] Phase 2: API 엔드포인트 (30+ 개) - **완료**
- [ ] Phase 3: Frontend 컴포넌트 (10개) - **완료**
- [ ] Phase 4: 통합 테스트 - **검증 필요**

### 다음 단계
1. 서버 재시작하여 API 정상 동작 확인
2. Frontend 개발 서버 실행
3. 각 API 엔드포인트 수동 테스트
4. Frontend 컴포넌트 통합 테스트
5. 프로덕션 배포 준비

---

**검증 일시**: 2026-01-28
**검증자**: Development Team
**상태**: ✅ 구현 완료 / ⏳ 검증 대기 중
