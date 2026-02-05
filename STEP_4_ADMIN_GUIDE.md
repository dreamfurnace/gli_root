# Step 4: 관리자 화면 사용 가이드

## 📌 개요

RWA 자산 Tier 콘텐츠 관리는 **Django Admin 패널**을 통해 효율적으로 수행할 수 있습니다.

### 관리 페이지 접근 방법
- **Django Admin**: http://localhost:8000/admin/
- **Vue Admin 대시보드**: http://localhost:3001/rwa/assets

---

## 🎯 Django Admin 패널 (권장)

### 접속 방법
```bash
# 슈퍼유저 생성 (최초 1회)
cd gli_api-server
source .venv/bin/activate
python manage.py createsuperuser

# Django Admin 접속
# URL: http://localhost:8000/admin/
# ID: 생성한 슈퍼유저 계정
```

### 관리 가능한 Tier 콘텐츠 모델

#### 1. **RWA Asset (기본 자산 정보)**
경로: `GLI_CONTENT > RWA assets`

**🆕 신규 필드**:
- `latitude` (위도) - 지도 표시용
- `longitude` (경도) - 지도 표시용
- `map_embed_url` (지도 임베드 URL) - Google Maps 임베드 URL
- `funding_deadline` (펀딩 마감일) - 투자 모집 마감 날짜

**기존 필드**:
- 기본 정보: 이름, 설명, 카테고리
- 투자 정보: APY, 위험도, 최소/최대 투자금액
- 자산 정보: 위치, 유형, 면적, 운영 형태
- 펀딩 정보: 목표 금액, 현재 투자액, 투자자 수

#### 2. **RWA Asset Images (자산 이미지)**
경로: `GLI_CONTENT > RWA asset images`
- 자산당 최대 5개 이미지
- 메인 이미지 지정 가능
- 순서 지정 (order 필드)

#### 3. **RWA Asset Comments (댓글)**
경로: `GLI_CONTENT > RWA asset comments`
- 사용자 댓글 관리
- 답글(대댓글) 지원
- 삭제 표시 기능

---

## 📊 Tier별 콘텐츠 관리

### LV.1 FREE 티어

#### **RWA Asset Chart Data (차트 데이터)**
경로: `GLI_CONTENT > RWA asset chart data`

**필드**:
- `chart_type`: 차트 유형 (예: tourism_statistics)
- `data_points`: 데이터 포인트 배열 [60, 75, 55, 85, ...]
- `labels`: 라벨 배열 ["Q1", "Q2", "Q3", ...]
- `chart_config`: 차트 추가 설정 (JSON)

**예시**:
```json
{
  "chart_type": "tourism_statistics",
  "data_points": [60, 75, 55, 85, 70, 90, 65, 80],
  "labels": ["Q1 2023", "Q2 2023", "Q3 2023", "Q4 2023", "Q1 2024", "Q2 2024", "Q3 2024", "Q4 2024"]
}
```

#### **RWA Asset News (뉴스)**
경로: `GLI_CONTENT > RWA asset news`

**필드**:
- `tier_level`: **free** (FREE 등급 선택)
- `title`: 뉴스 제목
- `source`: 출처
- `description`: 요약 설명
- `thumbnail`: 썸네일 이미지 URL
- `views_text`: 조회수 텍스트 (예: "24K views")
- `published_at`: 발행일

---

### LV.2 BASIC 티어

#### **RWA Asset Risk Analysis (AI 리스크 분석)**
경로: `GLI_CONTENT > RWA asset risk analysis`

**필드**:
- `sentiment`: 감정 (Positive, Neutral, Negative)
- `volatility`: 변동성 (Low, Moderate, High)
- `liquidity`: 유동성 (High, Medium, Low)
- `overall_score`: 종합 점수 (0.0 ~ 10.0)
- `radar_data`: 레이더 차트 데이터 (JSON)

**레이더 차트 데이터 예시**:
```json
[
  {"label": "Market Risk", "value": 65},
  {"label": "Credit Risk", "value": 80},
  {"label": "Liquidity Risk", "value": 90},
  {"label": "Operational Risk", "value": 75},
  {"label": "Regulatory Risk", "value": 70}
]
```

#### **RWA Asset News (AI 요약 뉴스)**
**추가 필드**:
- `tier_level`: **basic** (BASIC 등급 선택)
- `ai_summary`: AI 요약 텍스트
- `ai_confidence`: AI 신뢰도 (0-100)
- `sentiment_indicator`: 감정 지표 (positive, neutral, warning, negative)

---

### LV.3 STANDARD 티어

#### **RWA Asset Documents (문서/파일)**
경로: `GLI_CONTENT > RWA asset documents`

**필드**:
- `tier_level`: **standard** (STANDARD 등급 선택)
- `title`: 문서 제목
- `file_name`: 파일명
- `file_type`: 파일 유형 (PDF, Excel, Word, Image)
- `file_url`: 파일 URL (S3 등)
- `file_size`: 파일 크기 (bytes)
- `document_type`: 문서 유형 (audit_report, financial_statement, legal_doc, environmental, other)
- `is_confidential`: 기밀 문서 여부
- `requires_nda`: NDA 필요 여부

**문서 유형**:
- `audit_report`: 감사 보고서
- `financial_statement`: 재무제표
- `legal_doc`: 법률 문서
- `environmental`: 환경 보고서
- `other`: 기타

---

### LV.4 PREMIUM 티어

#### **RWA Asset VIP Packages (VIP 패키지)**
경로: `GLI_CONTENT > RWA asset VIP packages`

**필드**:
- `title`: 패키지 제목
- `description`: 패키지 설명
- `location`: 장소
- `duration_days`: 기간(일)
- `price_glib`: 가격 (GLIB)
- `price_usd`: 가격 (USD)
- `includes`: 포함 사항 (JSON 배열)
- `image_url`: 패키지 이미지 URL
- `is_available`: 예약 가능 여부
- `max_participants`: 최대 참가 인원
- `current_bookings`: 현재 예약 수

**포함 사항 예시**:
```json
["5성급 호텔", "전용 차량", "통역", "VIP 라운지"]
```

#### **DAO Voting Agendas (DAO 투표 안건)**
경로: `GLI_CONTENT > DAO voting agendas`

**필드**:
- `title`: 안건 제목
- `description`: 안건 설명
- `agenda_type`: 안건 유형 (dividend, strategy, operation, other)
- `start_date`: 투표 시작일
- `end_date`: 투표 종료일
- `total_votes`: 총 투표 수
- `approve_votes`: 찬성 투표 수
- `reject_votes`: 반대 투표 수
- `status`: 상태 (active, completed, cancelled)

#### **DAO Participants (DAO 참여자)**
경로: `GLI_CONTENT > DAO participants`

**필드**:
- `user`: 사용자
- `staked_amount`: 스테이킹 수량 (GLIB)
- `total_votes_participated`: 참여한 투표 수
- `last_vote_date`: 마지막 투표 날짜

#### **DAO Broadcasts (DAO 공지사항)**
경로: `GLI_CONTENT > DAO broadcasts`

**필드**:
- `message`: 공지 내용
- `target_tier`: 대상 등급 (bronze+, premium+ 등)

---

### LV.5 BUSINESS 티어

#### **Startup Brokerages (스타트업 브로커리지)**
경로: `GLI_CONTENT > Startup brokerages`

**필드**:
- `startup_name`: 스타트업 이름
- `category`: 카테고리
- `description`: 설명
- `investment_stage`: 투자 단계 (seed, series_a, series_b, series_c, series_d+)
- `target_amount_usd`: 목표 투자액 (USD)
- `current_valuation_usd`: 현재 밸류에이션 (USD)
- `ir_contact_name`: IR 담당자 이름
- `ir_contact_email`: IR 담당자 이메일
- `ir_deck_url`: IR 자료 URL
- `business_plan_url`: 사업 계획서 URL
- `is_available`: IR 연결 가능 여부

---

## 🔧 더미 데이터 삽입 명령어

더미 데이터를 DB에 삽입하거나 재생성하려면:

```bash
cd gli_api-server
source .venv/bin/activate

# 더미 데이터 삽입
python manage.py seed_rwa_tier_data

# 기존 데이터 삭제 후 재삽입
python manage.py seed_rwa_tier_data --force
```

**삽입되는 데이터**:
- ✅ RWA 자산 1개 (Sihanoukville Premium Casino Resort)
- ✅ 이미지 5개
- ✅ FREE 차트 데이터 1개
- ✅ FREE 뉴스 2개
- ✅ BASIC AI 리스크 분석 1개
- ✅ BASIC 뉴스 3개 (AI 요약 포함)
- ✅ STANDARD 문서 5개
- ✅ PREMIUM VIP 패키지 3개
- ✅ PREMIUM DAO 투표 안건 1개
- ✅ PREMIUM DAO 참여자 3명
- ✅ PREMIUM DAO 공지사항 1개
- ✅ BUSINESS 스타트업 브로커리지 4개
- ✅ 댓글 3개

---

## 📝 Vue Admin 대시보드 (참고)

Vue Admin 대시보드(http://localhost:3001)에서는 **RWA 자산의 기본 정보**만 관리할 수 있습니다.

**기능**:
- 자산 목록 조회
- 자산 생성/수정/삭제
- 자산 순서 변경
- 자산 활성화/비활성화

**Tier 콘텐츠 관리**는 **Django Admin**을 사용하세요.

---

## 🎨 S3 이미지 업로드

### 방법 1: Django Admin을 통한 URL 입력
Django Admin에서 이미지 URL을 직접 입력합니다.

**추천 무료 이미지 소스**:
- Unsplash: https://unsplash.com/
- Pexels: https://www.pexels.com/
- 예시 URL: `https://images.unsplash.com/photo-xxxxx?w=800`

### 방법 2: AWS S3 직접 업로드
```bash
# AWS CLI 설정
source AWS_switch-to-gli.sh

# 이미지 업로드
aws s3 cp image.jpg s3://gli-assets/rwa-images/image.jpg --acl public-read

# URL 확인
# https://gli-assets.s3.amazonaws.com/rwa-images/image.jpg
```

---

## 🚀 API 엔드포인트 (자동 생성됨)

신규 모델들에 대한 API 엔드포인트가 필요한 경우, Django REST Framework의 ViewSet을 추가하세요.

**예시 (apps/gli_content/views.py)**:
```python
from rest_framework import viewsets
from .models import RWAAssetNews, RWAAssetDocument
from .serializers import RWAAssetNewsSerializer, RWAAssetDocumentSerializer

class RWAAssetNewsViewSet(viewsets.ModelViewSet):
    queryset = RWAAssetNews.objects.all()
    serializer_class = RWAAssetNewsSerializer
    filterset_fields = ['asset', 'tier_level', 'is_active']
```

---

## ✅ 완료 체크리스트

### Step 1: 데이터 구조 분석
- [x] 메인 화면 필드 분석
- [x] LV.1~LV.5 Tier 데이터 요구사항 분석
- [x] 통합 데이터 구조 문서 작성 (`RWA_DATA_STRUCTURE_ANALYSIS.md`)

### Step 2: Django 모델 개선
- [x] RWAAsset 모델 필드 추가 (latitude, longitude, map_embed_url, funding_deadline)
- [x] 신규 모델 10개 생성
- [x] Django Migration 생성 및 적용
- [x] Admin 페이지 설정

### Step 3: 더미 데이터 DB 삽입
- [x] 더미 데이터 management command 작성
- [x] 더미 데이터 실행 완료
- [x] DB 검증 완료

### Step 4: 관리자 화면 가이드
- [x] Django Admin 사용 가이드 작성
- [x] Tier별 콘텐츠 관리 방법 문서화
- [x] 더미 데이터 명령어 정리

---

## 📚 참고 문서

1. **데이터 구조 분석**: `/gli_root/RWA_DATA_STRUCTURE_ANALYSIS.md`
2. **Django 모델**: `/gli_api-server/apps/gli_content/models.py`
3. **더미 데이터 명령어**: `/gli_api-server/apps/gli_content/management/commands/seed_rwa_tier_data.py`
4. **Admin 설정**: `/gli_api-server/apps/gli_content/admin.py`

---

**작성일**: 2026-02-06
**작성자**: Claude Code
**문서 버전**: 1.0
