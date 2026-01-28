# MyPage 비교 분석 보고서

**작성일:** 2026-01-28
**목적:** 참고 파일(GLI mypageV0.1.html)과 현재 구현(MyPageView.vue) 비교

---

## 1. 전체 구조 비교

### 참고 파일 (HTML)
- **9개 탭 구조:**
  1. Profile (회원 정보)
  2. Security (보안 설정)
  3. Referral (추천 코드)
  4. Dashboard (대시보드) ⭐ 기본 활성
  5. Portfolio (포트폴리오)
  6. Shopping (GLIL 쇼핑) - 개발 중
  7. Usage (이용 내역)
  8. Transaction (거래 내역)
  9. Wallet (입출금)

### 현재 구현 (Vue)
- **9개 탭 구조:**
  1. profile (회원 정보)
  2. face-verification (얼굴 인증)
  3. referral (추천인 코드)
  4. glib-tokens (GLI-B 토큰)
  5. portfolio (투자 포트폴리오)
  6. gli-l-shopping (GLI-L 쇼핑)
  7. tokens (통합 거래 내역)
  8. transactions (거래 내역)
  9. wallet (입출금)

---

## 2. 탭별 상세 비교

### 탭 1: Profile (회원 정보)
| 항목 | 참고 파일 | 현재 구현 | 격차 |
|------|----------|----------|------|
| 기본 정보 표시 | ✅ 이메일, 전화, 가입일, 최종 로그인 | ✅ 동일 | ✅ 일치 |
| 로그인 세션 | ✅ 디바이스, 위치, IP 표시 | ✅ 디바이스, 위치, 시간, 상태 | ✅ 일치 |
| 보안 설정 | ✅ 보안 탭으로 이동 버튼 | ✅ 비밀번호 변경, 전화 인증, 얼굴 인증 | ⚠️ 참고 파일에는 통합 보안 탭 별도 존재 |
| 로그아웃 | ✅ 로그아웃 버튼 | ✅ 로그아웃 버튼 | ✅ 일치 |

**결론:** 현재 구현이 더 세분화되어 있음. 참고 파일은 보안을 별도 탭으로 분리.

---

### 탭 2: Security (보안 설정) vs Face Verification (얼굴 인증)

| 항목 | 참고 파일 | 현재 구현 | 격차 |
|------|----------|----------|------|
| 얼굴 인증 | ✅ 보안 탭 내 카드 형태 | ✅ 독립 탭으로 구현 | ⚠️ 구조 차이 |
| 2FA (OTP) | ✅ Google Authenticator | ❌ 없음 | 🔴 **신규 개발 필요** |
| PIN 번호 | ✅ 6자리 숫자 패드 | ❌ 없음 | 🔴 **신규 개발 필요** |
| 보안 등급 시스템 | ✅ 3단계 진행 바 | ❌ 없음 | 🔴 **신규 개발 필요** |

**결론:** 참고 파일의 통합 보안 설정 탭을 새로 개발해야 함.

---

### 탭 3: Referral (추천 코드)

| 항목 | 참고 파일 | 현재 구현 | 격차 |
|------|----------|----------|------|
| 추천 코드 표시 | ✅ GLI-8829-XJ | ✅ 코드 표시 | ✅ 일치 |
| 코드 복사 | ✅ 복사 버튼 | ✅ 복사 버튼 | ✅ 일치 |
| QR 코드 | ✅ 모달로 표시 | ❌ 없음 | 🔴 **신규 개발 필요** |
| 초대장 문구 | ✅ 복사 버튼 | ❌ 없음 | 🔴 **신규 개발 필요** |
| 보상 안내 | ✅ 초대자/피초대자 포인트 | ✅ 유사 | ✅ 일치 |
| 추천 내역 | ✅ 테이블 (빈 상태) | ✅ 최근 추천인 목록 | ⚠️ 차이 있음 |
| 오버레이 | ❌ 없음 | ✅ "기능 개선 중" 오버레이 | ⚠️ 현재 구현이 임시 차단 |

**결론:** 현재 구현에서 오버레이 제거하고 QR/초대장 기능 추가 필요.

---

### 탭 4: Dashboard (대시보드) vs GLIB Tokens

| 항목 | 참고 파일 | 현재 구현 | 격차 |
|------|----------|----------|------|
| 총 자산 가치 | ✅ GLIB/USD 전환 표시 | ❌ 없음 | 🔴 **신규 개발 필요** |
| GLIB 토큰 정보 | ✅ 카드 형태, 스테이킹 비율 | ✅ 잔액 표시만 | ⚠️ 참고 파일이 더 상세 |
| GLID 토큰 | ✅ "상장 대기" 상태 | ❌ 없음 | 🔴 **신규 개발 필요** |
| GLIL 토큰 | ✅ Gold/Sweeps 구분 | ❌ 별도 관리 안 됨 | 🔴 **신규 개발 필요** |
| **자산 교환 위젯** | ✅ **완전히 새로운 기능** | ❌ 없음 | 🔴 **신규 개발 필요** |
| **실행 프로젝트 테이블** | ✅ **진행 상황 추적** | ❌ 없음 | 🔴 **신규 개발 필요** |

**결론:** 대시보드는 거의 전체를 새로 개발해야 함. 자산 교환 위젯과 프로젝트 테이블이 핵심.

---

### 탭 5: Portfolio (포트폴리오)

| 항목 | 참고 파일 | 현재 구현 | 격차 |
|------|----------|----------|------|
| 투자 요약 | ❌ 없음 | ✅ 총 투자액, 현재 가치, 수익률 | ⚠️ 현재 구현이 더 나음 |
| 프로젝트 목록 | ✅ 스테이킹 상태 표시 | ✅ 투자 프로젝트 카드 | ✅ 유사 |
| **리워드 수령 기능** | ✅ **USDT 즉시 수령 버튼** | ❌ 없음 | 🔴 **신규 개발 필요** |
| **해지 프로세스** | ✅ **쿨다운 기간 시각화** | ❌ 없음 | 🔴 **신규 개발 필요** |
| APR 표시 | ✅ 프로젝트별 APR | ✅ 연 이율 표시 | ✅ 일치 |

**결론:** 현재 구현이 기본은 갖췄으나, 리워드 수령과 해지 프로세스 추가 필요.

---

### 탭 6: Shopping (GLIL 쇼핑)

| 항목 | 참고 파일 | 현재 구현 | 격차 |
|------|----------|----------|------|
| 개발 상태 | ⚠️ "Dev" 배지, 준비 중 | ✅ 장바구니/구매 내역 기능 | ⚠️ **현재 구현이 앞섬** |
| 장바구니 | ❌ 없음 | ✅ 완전 구현 | ✅ 현재 구현 유지 |
| 구매 내역 | ❌ 없음 | ✅ OrderHistory 컴포넌트 | ✅ 현재 구현 유지 |

**결론:** 현재 구현을 유지하고, 참고 파일의 UI 디자인만 적용.

---

### 탭 7: Usage (이용 내역) vs Tokens (통합 거래 내역)

| 항목 | 참고 파일 | 현재 구현 | 격차 |
|------|----------|----------|------|
| 레저 이용 내역 | ✅ 골프, 호텔 등 | ❌ 없음 | 🔴 **신규 개발 필요** |
| 영수증 보기 | ✅ 전자 영수증 버튼 | ❌ 없음 | 🔴 **신규 개발 필요** |
| 토큰 거래 내역 | ❌ 없음 | ✅ TransactionHistory 컴포넌트 | ✅ 현재 구현 유지 |

**결론:** 참고 파일의 "이용 내역"은 완전히 새로운 기능. 별도 개발 필요.

---

### 탭 8: Transaction (거래 내역)

| 항목 | 참고 파일 | 현재 구현 | 격차 |
|------|----------|----------|------|
| P2P 거래 | ✅ 표시 | ⚠️ 통합 표시 | ✅ 유사 |
| Swap 내역 | ✅ 표시 | ⚠️ 통합 표시 | ✅ 유사 |
| 입출금 내역 | ✅ 표시 | ⚠️ 통합 표시 | ✅ 유사 |
| 필터 버튼 | ✅ 전체/Swap/P2P/입출금 | ✅ 토큰별/타입별 필터 | ✅ 일치 |
| 트랜잭션 해시 | ✅ 블록체인 탐색기 링크 | ✅ 복사 버튼 | ✅ 일치 |

**결론:** 현재 구현이 충분. UI만 개선 필요.

---

### 탭 9: Wallet (입출금)

| 항목 | 참고 파일 | 현재 구현 | 격차 |
|------|----------|----------|------|
| 지갑 연결 | ✅ 상태 표시 | ✅ PhantomWalletButton | ✅ 일치 |
| 입금 섹션 | ✅ QR 코드, 주소 복사 | ✅ 유사 | ✅ 일치 |
| 출금 섹션 | ✅ 주소, 금액, 2FA | ✅ 유사 | ✅ 일치 |
| **주소록 기능** | ✅ **저장된 주소 관리** | ❌ 없음 | 🔴 **신규 개발 필요** |
| 네트워크 선택 | ✅ ERC-20/TRC-20 | ❌ 없음 | 🔴 **신규 개발 필요** |

**결론:** 주소록과 네트워크 선택 기능 추가 필요.

---

## 3. 모달 시스템 비교

### 참고 파일의 8개 모달
1. ✅ 비밀번호 변경 - **현재 구현에 있음**
2. ✅ 휴대전화 인증 - **현재 구현에 미흡**
3. ✅ 얼굴 인증 - **현재 구현에 있음**
4. 🔴 QR 코드 (추천) - **신규 개발 필요**
5. 🔴 Google OTP 설정 - **신규 개발 필요**
6. 🔴 PIN 번호 설정 - **신규 개발 필요**
7. 🔴 등급 업그레이드 - **신규 개발 필요**

---

## 4. 신규 개발 필요 기능 우선순위

### 🔴 High Priority (핵심 기능)

1. **대시보드 전면 재개발**
   - 총 자산 가치 히어로 카드
   - 토큰 3종 상세 카드 (GLIB/GLID/GLIL)
   - 자산 교환 위젯 (Swap Widget)
   - 실행 프로젝트 관리 테이블
   - **API 필요:** `/api/assets/dashboard`, `/api/swap/*`

2. **통합 보안 설정 탭**
   - 보안 등급 시스템
   - 2FA (Google OTP) 설정
   - PIN 번호 설정
   - **API 필요:** `/api/security/*`

3. **포트폴리오 기능 강화**
   - 리워드 즉시 수령 기능
   - 해지 프로세스 관리 (쿨다운 기간)
   - **API 필요:** `/api/portfolio/claim-reward`, `/api/portfolio/unsubscribe`

### 🟡 Medium Priority (편의 기능)

4. **레퍼럴 기능 완성**
   - QR 코드 생성 모달
   - 초대장 문구 복사
   - 오버레이 제거
   - **API 필요:** `/api/referral/qr-code`

5. **이용 내역 탭 신규 개발**
   - 레저 서비스 이용 기록 (골프, 호텔 등)
   - 전자 영수증 보기
   - **API 필요:** `/api/usage-history`

6. **지갑 기능 강화**
   - 주소록 관리
   - 네트워크 선택 (ERC-20/TRC-20)
   - **API 필요:** `/api/wallet/address-book`

### 🟢 Low Priority (부가 기능)

7. **등급 업그레이드 모달**
8. **프로필 요약 섹션 개선** (레벨, 포인트 표시)
9. **애니메이션 및 인터랙션 강화**

---

## 5. DB 모델 설계 필요 항목

### 신규 테이블

1. **SecuritySettings** (보안 설정)
   ```python
   class SecuritySetting(models.Model):
       user = models.OneToOneField(User)
       face_auth_enabled = models.BooleanField(default=False)
       face_auth_last_verified = models.DateTimeField(null=True)
       two_fa_enabled = models.BooleanField(default=False)
       two_fa_secret = models.CharField(max_length=32, null=True)
       pin_enabled = models.BooleanField(default=False)
       pin_hash = models.CharField(max_length=128, null=True)
       security_level = models.IntegerField(default=1)  # 1-3
   ```

2. **UsageHistory** (이용 내역)
   ```python
   class UsageHistory(models.Model):
       user = models.ForeignKey(User)
       service_type = models.CharField(choices=['GOLF', 'HOTEL', 'OTHER'])
       title = models.CharField(max_length=200)
       date = models.DateTimeField()
       original_price_usd = models.DecimalField()
       paid_price_glil = models.DecimalField()
       receipt_url = models.URLField(null=True)
       image = models.ImageField(null=True)
   ```

3. **SwapTransaction** (토큰 교환)
   ```python
   class SwapTransaction(models.Model):
       user = models.ForeignKey(User)
       from_token = models.CharField(max_length=10)
       to_token = models.CharField(max_length=10)
       from_amount = models.DecimalField()
       to_amount = models.DecimalField()
       rate = models.DecimalField()
       fee = models.DecimalField()
       status = models.CharField(choices=['PENDING', 'COMPLETED', 'FAILED'])
       created_at = models.DateTimeField(auto_now_add=True)
   ```

4. **WalletAddressBook** (주소록)
   ```python
   class WalletAddressBook(models.Model):
       user = models.ForeignKey(User)
       name = models.CharField(max_length=50)
       address = models.CharField(max_length=100)
       is_favorite = models.BooleanField(default=False)
       created_at = models.DateTimeField(auto_now_add=True)
   ```

5. **PortfolioUnstaking** (해지 진행)
   ```python
   class PortfolioUnstaking(models.Model):
       user = models.ForeignKey(User)
       investment = models.ForeignKey(Investment)
       request_date = models.DateTimeField(auto_now_add=True)
       cooldown_days = models.IntegerField(default=30)
       return_amount = models.DecimalField()
       status = models.CharField(choices=['IN_PROGRESS', 'COMPLETED', 'CANCELLED'])
   ```

### 기존 테이블 확장

- **User:** `level`, `points` 필드 추가
- **Investment:** `pending_reward_usdt` 필드 추가

---

## 6. API 엔드포인트 목록

### 신규 개발 필요

```
# 보안
POST   /api/security/2fa/setup
POST   /api/security/2fa/verify
POST   /api/security/pin/set
POST   /api/security/pin/verify
GET    /api/security/status

# 대시보드
GET    /api/assets/dashboard
GET    /api/assets/total-value

# 자산 교환
POST   /api/swap/execute
GET    /api/swap/rate
GET    /api/wallet/balances

# 포트폴리오
POST   /api/portfolio/claim-reward/{investment_id}
POST   /api/portfolio/unsubscribe/{investment_id}
POST   /api/portfolio/cancel-unstaking/{unstaking_id}
GET    /api/portfolio/unstaking-list

# 이용 내역
GET    /api/usage-history
GET    /api/usage-history/receipt/{id}

# 주소록
GET    /api/wallet/address-book
POST   /api/wallet/address-book
DELETE /api/wallet/address-book/{id}

# 레퍼럴
GET    /api/referral/qr-code
```

---

## 7. 다음 단계 액션 플랜

### Phase 1: DB 및 API 개발 (백엔드)
1. Django 모델 생성 및 마이그레이션
2. API 엔드포인트 개발
3. API 테스트 (Postman/pytest)

### Phase 2: 컴포넌트 개발 (프론트엔드)
1. 대시보드 컴포넌트 개발
2. 보안 설정 컴포넌트 개발
3. 모달 컴포넌트 개발
4. 포트폴리오 기능 강화
5. 이용 내역 컴포넌트 개발

### Phase 3: 통합 및 테스트
1. API 연동
2. 기존 기능과의 통합 테스트
3. UI/UX 최종 점검

---

## 8. 예상 개발 기간

- **백엔드 (DB + API):** 3-5일
- **프론트엔드 (컴포넌트):** 5-7일
- **통합 테스트:** 2-3일
- **총 예상:** 10-15일

---

## 9. 결론

참고 파일은 **매우 포괄적이고 세련된 마이페이지 디자인**을 제시하고 있으며, 현재 구현은 **기본 기능은 대부분 갖췄으나** 다음이 부족합니다:

1. **대시보드의 자산 관리 기능** (자산 교환, 프로젝트 관리)
2. **통합 보안 설정 시스템** (2FA, PIN)
3. **포트폴리오 고급 기능** (리워드 수령, 해지 관리)
4. **이용 내역 추적** (레저 서비스)

우선순위에 따라 단계적으로 개발을 진행하는 것을 권장합니다.
