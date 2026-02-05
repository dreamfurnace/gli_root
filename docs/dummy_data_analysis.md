# GLI 더미 데이터 분석 보고서

## 📊 데이터 구조 요약

### 1. RWA 투자 자산 (30개)

#### 카테고리별 분포:
- **Casino (카지노)**: 6개 (gc-001 ~ gc-006)
- **Leisure (레저)**: 6개 (ls-001 ~ ls-006)
  - GOLF: 2개
  - TOUR: 2개
  - HOPPING: 2개
- **Commercial (상업)**: 6개 (cm-001 ~ cm-006)
  - OFFICE: 2개
  - RETAIL: 2개
  - MULTI: 2개
- **Residential (주거)**: 6개 (rs-001 ~ rs-006)
  - APARTMENT: 2개
  - VILLA: 2개
  - HOUSE: 2개
- **Project (프로젝트)**: 6개 (pj-001 ~ pj-006)
  - LUXURY: 2개
  - F&B: 2개
  - TECH: 2개

#### 국가별 분포:
- **Cambodia (캄보디아)**: 4개 자산
  - Sihanoukville: gc-006, gc-001, ls-002
  - Phnom Penh: pj-002
- **Vietnam (베트남)**: 5개 자산
  - Ho Chi Minh: gc-002, cm-001
  - Danang: gc-005, ls-004
  - Dak Lak: pj-005
- **Philippines (필리핀)**: 5개 자산
  - Manila: gc-003, gc-004, ls-001, cm-003, rs-003
  - Cebu: ls-003
- **Thailand (태국)**: 6개 자산
  - Phuket: ls-005, rs-002
  - Bangkok: cm-002, rs-004, pj-006
- **Malaysia (말레이시아)**: 2개 자산
  - Kuala Lumpur: cm-005
  - Penang: rs-006
- **Singapore (싱가포르)**: 3개 자산
  - cm-006, rs-001, pj-003
- **Indonesia**: 1개 자산
  - Bali: rs-005
- **South Korea (대한민국)**: 1개 자산
  - Seoul: pj-004
- **China (중국)**: 1개 자산
  - Guizhou: pj-001
- **Laos, Myanmar**: 0개 (국가만 등록)

#### APY 분포:
- **HIGH (>15%)**: 13개 자산
- **MID (10-15%)**: 11개 자산
- **LOW (<10%)**: 6개 자산

#### RISK 등급:
- **HIGH**: Casino (6) + Project (6) = 12개
- **MID**: Leisure (6) + Residential (6) = 12개
- **LOW**: Commercial (6) = 6개

### 2. Tier별 콘텐츠 데이터

#### FREE Tier (Level 1):
- **News Items**: 4개
  1. "Cambodia Tourism Growth 2025 Report" (비디오)
  2. "Sihanoukville Investment Guide & Regulations" (기사)
  3. "SE Asia Casino Market Outlook 2025" (분석)
  4. "Global Leisure Investment Trend Analysis" (GLI 리서치)

#### BASIC Tier (Level 2):
- **AI 리스크 분석 데이터**:
  - Sentiment: Positive
  - Risk Index: Moderate
  - Operation: A- Tier
- **AI Insights**: 5개
  1. Infrastructure Growth Matrix
  2. Currency Volatility Monitor
  3. Predictive ROI Analysis
  4. Competitor Footfall Tracking
  5. Environmental Audit

#### STANDARD Tier (Level 3):
- **Secret Documents**: 7개
  1. "FY2024 Internal Audit Report (Final)" - PDF
  2. "Q3 2024 Raw Financial Statement_V2" - XLS
  3. "Due Diligence Opinion: Land Title Verification" - TXT
  4. "Executive Compensation Structure 2025" - PDF
  5. "Operational Risk Assessment (Non-Public)" - PDF
  6. "Monthly Cash Flow Projection (2025-2027)" - XLS
  7. "Partnership Agreement with Hotel Chain A" - TXT

#### PREMIUM Tier (Level 4):
- **VIP Packages**: 3개
  1. "3D2N Sihanoukville Private Tour (Cambodia)" - 1,500 GLIB ($2,000)
  2. "4D3N Manila High-Roller Course (Philippines)" - 2,200 GLIB ($3,000)
  3. "3D2N Danang Golf & Heritage Tour (Vietnam)" - 1,800 GLIB ($2,500)

- **DAO 거버넌스**:
  - **Agendas**: 1개
    - "Q1 Dividend Payout Adjustment" (URGENT, 종료 2시간 전)
    - 찬성: 65%, 반대: 35%

  - **Participants**: 3명
    1. WHALE_VVIP_01 - 1,240,000 GLIB (29.7% Power) - BUSINESS ACCESS
    2. ALPHA_STAKER - 850,000 GLIB (20.2% Power) - PREMIUM ACCESS
    3. MEMBER_4812 - 512,000 GLIB (12.1% Power) - STANDARD ACCESS

  - **Staking Stats**:
    - Total Staked: 4.2M GLIB
    - Governance: Active
    - Quorum: Reached

#### BUSINESS Tier (Level 5):
- **Startup Brokerages**: 4개
  1. "Global Leisure Tech (Series A)" - AI-driven Casino Analytics
  2. "Gangdao PropTech (Pre-IPO)" - RWA Tokenization Platform
  3. "Vietnam Eco-Resorts (Seed)" - Sustainable Tourism Dev
  4. "Manila Fintech Solutions (Series B)" - Cross-border Payments

### 3. 댓글 데이터
- **샘플 댓글**: 1개
  - User: Whale_Investor
  - Date: 2025.01.10
  - Content: "The projected yield for this project looks quite attractive."

### 4. 이미지 데이터
모든 자산은 Unsplash 이미지 URL 사용:
- 총 30개의 고유 이미지 URL (asset별)
- 8개의 국가 대표 이미지 (geoData)
- 3개의 VIP 패키지 이미지

---

## 📋 Django 모델 매핑

### 필요한 모델:
1. **투자 자산 (InvestmentAsset)**: 30개
2. **자산 이미지 (AssetImage)**: 30개 (메인 이미지)
3. **문서 (Document)**: 7개 (STANDARD tier)
4. **VIP 패키지 (VIPPackage)**: 3개
5. **DAO 안건 (DAOAgenda)**: 1개
6. **DAO 참여자 (DAOParticipant)**: 3개
7. **스타트업 브로커리지 (StartupBrokerage)**: 4개
8. **뉴스 아이템 (News)**: 4개
9. **댓글 (Comment)**: 1개
10. **파트너 (Partner)**: 필요시 추가

---

## 🎯 다음 단계

### 1단계: 이미지 다운로드 및 S3 업로드
- Unsplash에서 30개 자산 이미지 다운로드
- AWS S3 gli-assets 버킷에 업로드
- URL 패턴: `https://gli-assets.s3.amazonaws.com/assets/{asset-id}.jpg`

### 2단계: Django Fixture 생성
- `investment_assets.json` (30개 자산)
- `asset_images.json` (30개 이미지)
- `documents.json` (7개 문서)
- `vip_packages.json` (3개 패키지)
- `dao_agendas.json` (1개 안건)
- `dao_participants.json` (3개 참여자)
- `startup_brokerages.json` (4개 스타트업)
- `news_items.json` (4개 뉴스)
- `comments.json` (1개 댓글)

### 3단계: 데이터 로드
```bash
python manage.py loaddata investment_assets.json
python manage.py loaddata asset_images.json
python manage.py loaddata documents.json
python manage.py loaddata vip_packages.json
python manage.py loaddata dao_agendas.json
python manage.py loaddata dao_participants.json
python manage.py loaddata startup_brokerages.json
python manage.py loaddata news_items.json
python manage.py loaddata comments.json
```

---

## 📝 참고사항

1. **Tier 레벨 매핑**:
   - FREE: 0-999 GLIB
   - BASIC: 1000-4999 GLIB
   - STANDARD: 5000-9999 GLIB
   - PREMIUM: 10000-99999 GLIB
   - BUSINESS: 100000+ GLIB

2. **HOT TRENDING 순위 알고리즘**:
   ```
   score = likes × 5 + views × 1 + (total_subscribed_glib / 1000) × 10
   ```

3. **이미지 출처**:
   - 모든 이미지는 Unsplash 무료 라이선스
   - 상업적 사용 가능
   - 출처 표기 권장사항

4. **국가 코드 매핑**:
   - KH: Cambodia
   - VN: Vietnam
   - PH: Philippines
   - MY: Malaysia
   - TH: Thailand
   - LA: Laos
   - MM: Myanmar
   - SG: Singapore
   - ID: Indonesia
   - KR: South Korea
   - CN: China
