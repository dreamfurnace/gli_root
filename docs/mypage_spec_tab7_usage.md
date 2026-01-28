# 탭 7: Usage (이용 내역) - 상세 명세서

**작성일:** 2026-01-28
**특이사항:** 🆕 **완전히 새로운 기능 - 전체 개발 필요**

---

## 1. 화면 분석 및 요구사항

### 1.1 화면 구성

```
┌─────────────────────────────────────────────────────────────┐
│ 📋 이용 내역 (Usage History)                                 │
├─────────────────────────────────────────────────────────────┤
│ [필터 버튼]                                                  │
│ [전체] [골프] [호텔/리조트] [기타]                          │
│                                                             │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ [이미지]  🏌️ Angkor Golf Resort 18홀 이용권           │ │
│ │          Service: GOLF                                  │ │
│ │          Date: 2025.12.10                              │ │
│ │          Original: $150.00                             │ │
│ │          Paid: 1,500 GLIL                              │ │
│ │                                                         │ │
│ │          [📄 전자 영수증 보기]                          │ │
│ └─────────────────────────────────────────────────────────┘ │
│                                                             │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ [이미지]  🏨 Sokha Beach Resort 2박 3일                │ │
│ │          Service: HOTEL                                 │ │
│ │          Date: 2025.11.25                              │ │
│ │          Room: Ocean View Suite                        │ │
│ │          Original: $400.00                             │ │
│ │          Paid: 4,000 GLIL                              │ │
│ │                                                         │ │
│ │          [📄 전자 영수증 보기]                          │ │
│ └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

### 1.2 기능 요구사항

1. **레저 서비스 이용 기록**
   - 골프장 이용권
   - 호텔/리조트 숙박
   - 기타 레저 서비스

2. **이용 정보 표시**
   - 서비스 타입 (GOLF, HOTEL, OTHER)
   - 서비스 제목
   - 이용 일자
   - 원가 (USD)
   - 실제 결제 금액 (GLIL)
   - 이미지

3. **필터링**
   - 전체
   - 골프
   - 호텔/리조트
   - 기타

4. **전자 영수증**
   - 영수증 ID (GLI-YYMMDD-XXX)
   - 상세 이용 내역
   - PDF 다운로드 (선택사항)

---

## 2. DB 모델

### 2.1 UsageHistory 모델

```python
# gli_django/leisure/models.py

class UsageHistory(models.Model):
    SERVICE_TYPE_CHOICES = [
        ('GOLF', 'Golf'),
        ('HOTEL', 'Hotel/Resort'),
        ('OTHER', 'Other'),
    ]

    STATUS_CHOICES = [
        ('CONFIRMED', 'Confirmed'),
        ('USED', 'Used'),
        ('CANCELLED', 'Cancelled'),
    ]

    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='usage_history')

    # 서비스 정보
    service_type = models.CharField(max_length=20, choices=SERVICE_TYPE_CHOICES)
    title = models.CharField(max_length=200)
    description = models.TextField(blank=True)

    # 날짜
    usage_date = models.DateField()
    booking_date = models.DateTimeField(auto_now_add=True)

    # 가격
    original_price_usd = models.DecimalField(max_digits=10, decimal_places=2)
    paid_price_glil = models.DecimalField(max_digits=20, decimal_places=8)
    exchange_rate = models.DecimalField(max_digits=10, decimal_places=2, default=100)  # 1 USD = 100 GLIL

    # 추가 정보 (HOTEL의 경우)
    room_type = models.CharField(max_length=100, blank=True)
    nights = models.IntegerField(null=True, blank=True)

    # 영수증
    receipt_id = models.CharField(max_length=50, unique=True)  # GLI-251210-AGR
    receipt_url = models.URLField(null=True, blank=True)  # PDF URL

    # 이미지
    image = models.ImageField(upload_to='leisure/', null=True, blank=True)

    # 상태
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='CONFIRMED')

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-usage_date', '-created_at']
        verbose_name = 'Usage History'
        verbose_name_plural = 'Usage Histories'
        indexes = [
            models.Index(fields=['user', '-usage_date']),
            models.Index(fields=['service_type']),
            models.Index(fields=['receipt_id']),
        ]

    def save(self, *args, **kwargs):
        if not self.receipt_id:
            # Generate receipt ID: GLI-YYMMDD-XXX
            from datetime import datetime
            import random
            date_str = self.usage_date.strftime('%y%m%d')
            random_str = ''.join(random.choices('ABCDEFGHIJKLMNOPQRSTUVWXYZ', k=3))
            self.receipt_id = f"GLI-{date_str}-{random_str}"
        super().save(*args, **kwargs)

    def __str__(self):
        return f"{self.user.username} - {self.title} ({self.usage_date})"
```

### 2.2 마이그레이션

```bash
python manage.py makemigrations leisure
python manage.py migrate leisure
```

---

## 3. API 엔드포인트

### 3.1 이용 내역 조회

```python
# GET /api/usage-history/?service_type=GOLF
# Response:
{
    "count": 10,
    "results": [
        {
            "id": 1,
            "service_type": "GOLF",
            "title": "Angkor Golf Resort 18홀 이용권",
            "description": "캄보디아 앙코르 골프 리조트",
            "usage_date": "2025-12-10",
            "booking_date": "2025-12-05T10:00:00Z",
            "original_price_usd": 150.00,
            "paid_price_glil": 1500,
            "receipt_id": "GLI-251210-AGR",
            "image_url": "https://.../leisure/golf1.jpg",
            "status": "USED"
        },
        {
            "id": 2,
            "service_type": "HOTEL",
            "title": "Sokha Beach Resort 2박 3일",
            "description": "시아누크빌 소카 비치 리조트",
            "usage_date": "2025-11-25",
            "original_price_usd": 400.00,
            "paid_price_glil": 4000,
            "room_type": "Ocean View Suite",
            "nights": 2,
            "receipt_id": "GLI-251125-SBR",
            "image_url": "https://.../leisure/hotel1.jpg",
            "status": "USED"
        }
    ]
}
```

**구현:**

```python
# gli_django/leisure/views.py

from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework.pagination import PageNumberPagination
from .models import UsageHistory

class UsageHistoryPagination(PageNumberPagination):
    page_size = 10
    page_size_query_param = 'page_size'
    max_page_size = 50

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_usage_history(request):
    user = request.user
    service_type = request.query_params.get('service_type')

    queryset = UsageHistory.objects.filter(user=user)

    if service_type and service_type != 'ALL':
        queryset = queryset.filter(service_type=service_type)

    paginator = UsageHistoryPagination()
    page = paginator.paginate_queryset(queryset, request)

    results = [
        {
            'id': usage.id,
            'service_type': usage.service_type,
            'title': usage.title,
            'description': usage.description,
            'usage_date': usage.usage_date.isoformat(),
            'booking_date': usage.booking_date.isoformat(),
            'original_price_usd': float(usage.original_price_usd),
            'paid_price_glil': float(usage.paid_price_glil),
            'room_type': usage.room_type,
            'nights': usage.nights,
            'receipt_id': usage.receipt_id,
            'image_url': usage.image.url if usage.image else None,
            'status': usage.status
        } for usage in page
    ]

    return paginator.get_paginated_response(results)
```

### 3.2 영수증 조회

```python
# GET /api/usage-history/receipt/{receipt_id}/
# Response:
{
    "receipt_id": "GLI-251210-AGR",
    "user": {
        "name": "홍길동",
        "email": "user@gli.io"
    },
    "service": {
        "type": "GOLF",
        "title": "Angkor Golf Resort 18홀 이용권",
        "description": "캄보디아 앙코르 골프 리조트",
        "usage_date": "2025-12-10"
    },
    "payment": {
        "original_price_usd": 150.00,
        "paid_price_glil": 1500,
        "exchange_rate": 100,
        "discount": 0
    },
    "booking_date": "2025-12-05T10:00:00Z",
    "status": "USED"
}
```

**구현:**

```python
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_receipt(request, receipt_id):
    user = request.user

    try:
        usage = UsageHistory.objects.get(receipt_id=receipt_id, user=user)
    except UsageHistory.DoesNotExist:
        return Response({'error': 'Receipt not found'}, status=404)

    return Response({
        'receipt_id': usage.receipt_id,
        'user': {
            'name': user.get_full_name() or user.username,
            'email': user.email
        },
        'service': {
            'type': usage.service_type,
            'title': usage.title,
            'description': usage.description,
            'usage_date': usage.usage_date.isoformat(),
            'room_type': usage.room_type,
            'nights': usage.nights
        },
        'payment': {
            'original_price_usd': float(usage.original_price_usd),
            'paid_price_glil': float(usage.paid_price_glil),
            'exchange_rate': float(usage.exchange_rate),
            'discount': 0
        },
        'booking_date': usage.booking_date.isoformat(),
        'status': usage.status
    })
```

### 3.3 URL 라우팅

```python
# gli_django/leisure/urls.py

from django.urls import path
from .views import get_usage_history, get_receipt

urlpatterns = [
    path('usage-history/', get_usage_history, name='usage-history'),
    path('usage-history/receipt/<str:receipt_id>/', get_receipt, name='receipt'),
]
```

---

## 4. User Frontend 개발

### 4.1 UsageHistory 컴포넌트 생성

**파일:** `gli_user-frontend/src/components/leisure/UsageHistory.vue`

```vue
<template>
  <div class="usage-history">
    <!-- 필터 버튼 -->
    <div class="filter-buttons">
      <button
        v-for="filter in filters"
        :key="filter.value"
        class="filter-btn"
        :class="{ active: activeFilter === filter.value }"
        @click="setFilter(filter.value)"
      >
        <i :class="filter.icon"></i>
        {{ filter.label }}
      </button>
    </div>

    <!-- 이용 내역 카드 -->
    <div v-if="usageList.length > 0" class="usage-cards">
      <div
        v-for="usage in usageList"
        :key="usage.id"
        class="usage-card"
      >
        <!-- 이미지 -->
        <div class="usage-image" v-if="usage.image_url">
          <img :src="usage.image_url" :alt="usage.title" />
          <div class="service-badge" :class="usage.service_type.toLowerCase()">
            {{ getServiceIcon(usage.service_type) }}
            {{ getServiceLabel(usage.service_type) }}
          </div>
        </div>

        <!-- 정보 -->
        <div class="usage-info">
          <h3 class="usage-title">{{ usage.title }}</h3>
          <p class="usage-description">{{ usage.description }}</p>

          <div class="usage-details">
            <div class="detail-row">
              <span class="label">
                <i class="ph-duotone ph-calendar"></i>
                이용 일자
              </span>
              <span class="value">{{ formatDate(usage.usage_date) }}</span>
            </div>

            <div v-if="usage.room_type" class="detail-row">
              <span class="label">
                <i class="ph-duotone ph-bed"></i>
                객실 타입
              </span>
              <span class="value">{{ usage.room_type }} ({{ usage.nights }}박)</span>
            </div>

            <div class="detail-row price-row">
              <span class="label">원가</span>
              <span class="value original-price">${{ usage.original_price_usd.toFixed(2) }}</span>
            </div>

            <div class="detail-row price-row highlight">
              <span class="label">결제</span>
              <span class="value paid-price">{{ usage.paid_price_glil.toLocaleString() }} GLIL</span>
            </div>
          </div>

          <!-- 영수증 버튼 -->
          <button class="btn-receipt" @click="showReceipt(usage.receipt_id)">
            <i class="ph-bold ph-receipt"></i>
            전자 영수증 보기
          </button>
        </div>
      </div>
    </div>

    <!-- 빈 상태 -->
    <div v-else class="empty-state">
      <i class="ph-duotone ph-receipt text-6xl"></i>
      <h3>이용 내역이 없습니다</h3>
      <p>GLIL 토큰으로 레저 서비스를 이용해보세요</p>
    </div>

    <!-- 영수증 모달 -->
    <ReceiptModal
      :show="showReceiptModal"
      :receiptId="selectedReceiptId"
      @close="showReceiptModal = false"
    />
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue';
import { api } from '@/services/api';
import ReceiptModal from './ReceiptModal.vue';

const filters = [
  { value: 'ALL', label: '전체', icon: 'ph-duotone ph-list' },
  { value: 'GOLF', label: '골프', icon: 'ph-duotone ph-golf' },
  { value: 'HOTEL', label: '호텔/리조트', icon: 'ph-duotone ph-bed' },
  { value: 'OTHER', label: '기타', icon: 'ph-duotone ph-dots-three' },
];

const activeFilter = ref('ALL');
const usageList = ref([]);
const showReceiptModal = ref(false);
const selectedReceiptId = ref('');

const fetchUsageHistory = async () => {
  try {
    const params: any = {};
    if (activeFilter.value !== 'ALL') {
      params.service_type = activeFilter.value;
    }

    const response = await api.get('/api/usage-history/', { params });
    usageList.value = response.data.results;
  } catch (error) {
    console.error('Failed to fetch usage history:', error);
  }
};

const setFilter = (filterValue: string) => {
  activeFilter.value = filterValue;
  fetchUsageHistory();
};

const showReceipt = (receiptId: string) => {
  selectedReceiptId.value = receiptId;
  showReceiptModal.value = true;
};

const formatDate = (dateStr: string) => {
  return new Date(dateStr).toLocaleDateString('ko-KR', {
    year: 'numeric',
    month: 'long',
    day: 'numeric'
  });
};

const getServiceIcon = (type: string) => {
  const icons = { GOLF: '⛳', HOTEL: '🏨', OTHER: '🎯' };
  return icons[type] || '📋';
};

const getServiceLabel = (type: string) => {
  const labels = { GOLF: '골프', HOTEL: '호텔', OTHER: '기타' };
  return labels[type] || type;
};

onMounted(() => {
  fetchUsageHistory();
});
</script>

<style scoped>
.usage-history {
  width: 100%;
}

/* 필터 버튼 */
.filter-buttons {
  display: flex;
  gap: 1rem;
  margin-bottom: 2rem;
  flex-wrap: wrap;
}

.filter-btn {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.75rem 1.5rem;
  border: 1px solid var(--border-color);
  background: var(--bg-secondary);
  color: var(--text-secondary);
  border-radius: 8px;
  cursor: pointer;
  font-weight: 500;
  transition: all 0.3s;
}

.filter-btn:hover {
  border-color: var(--gli-blue);
  color: var(--text-primary);
}

.filter-btn.active {
  background: var(--gli-blue);
  color: white;
  border-color: var(--gli-blue);
}

/* 이용 내역 카드 */
.usage-cards {
  display: grid;
  gap: 1.5rem;
}

.usage-card {
  display: flex;
  gap: 1.5rem;
  background: var(--bg-secondary);
  border-radius: 16px;
  border: 1px solid var(--border-color);
  overflow: hidden;
  transition: all 0.3s;
}

.usage-card:hover {
  border-color: var(--gli-purple);
  box-shadow: 0 4px 12px rgba(168, 85, 247, 0.2);
  transform: translateY(-2px);
}

.usage-image {
  position: relative;
  width: 200px;
  flex-shrink: 0;
}

.usage-image img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.service-badge {
  position: absolute;
  top: 1rem;
  left: 1rem;
  padding: 0.5rem 1rem;
  border-radius: 20px;
  font-size: 0.85rem;
  font-weight: 600;
  backdrop-filter: blur(10px);
}

.service-badge.golf {
  background: rgba(16, 185, 129, 0.9);
  color: white;
}

.service-badge.hotel {
  background: rgba(59, 130, 246, 0.9);
  color: white;
}

.usage-info {
  flex: 1;
  padding: 1.5rem;
  display: flex;
  flex-direction: column;
}

.usage-title {
  font-size: 1.5rem;
  font-weight: 600;
  margin-bottom: 0.5rem;
  color: var(--text-primary);
}

.usage-description {
  color: var(--text-secondary);
  margin-bottom: 1.5rem;
}

.usage-details {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
  margin-bottom: 1.5rem;
}

.detail-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 0.5rem 0;
  border-bottom: 1px solid var(--border-color);
}

.detail-row:last-child {
  border-bottom: none;
}

.detail-row.highlight {
  background: rgba(251, 146, 60, 0.1);
  padding: 0.75rem;
  border-radius: 8px;
  border: none;
}

.label {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  color: var(--text-secondary);
  font-size: 0.9rem;
}

.value {
  font-weight: 600;
  color: var(--text-primary);
}

.original-price {
  text-decoration: line-through;
  color: var(--text-secondary);
}

.paid-price {
  color: var(--gli-gold);
  font-size: 1.1rem;
}

.btn-receipt {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 0.5rem;
  padding: 1rem;
  background: var(--gli-blue);
  color: white;
  border: none;
  border-radius: 8px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s;
  margin-top: auto;
}

.btn-receipt:hover {
  background: var(--gli-purple);
  transform: translateY(-2px);
}

/* 빈 상태 */
.empty-state {
  text-align: center;
  padding: 4rem 2rem;
  color: var(--text-secondary);
}

.empty-state i {
  opacity: 0.3;
  margin-bottom: 1rem;
}

.empty-state h3 {
  font-size: 1.5rem;
  margin-bottom: 0.5rem;
  color: var(--text-primary);
}

/* 반응형 */
@media (max-width: 768px) {
  .usage-card {
    flex-direction: column;
  }

  .usage-image {
    width: 100%;
    height: 200px;
  }
}
</style>
```

### 4.2 ReceiptModal 컴포넌트

**파일:** `gli_user-frontend/src/components/leisure/ReceiptModal.vue`

```vue
<template>
  <div v-if="show" class="modal-overlay" @click="$emit('close')">
    <div class="modal-content receipt-modal" @click.stop>
      <div class="modal-header">
        <h3>전자 영수증</h3>
        <button class="modal-close" @click="$emit('close')">×</button>
      </div>
      <div class="modal-body">
        <div v-if="receipt" class="receipt-content">
          <!-- 영수증 ID -->
          <div class="receipt-id">
            <i class="ph-fill ph-barcode"></i>
            <span>{{ receipt.receipt_id }}</span>
          </div>

          <!-- 사용자 정보 -->
          <div class="receipt-section">
            <h4>고객 정보</h4>
            <p>이름: {{ receipt.user.name }}</p>
            <p>이메일: {{ receipt.user.email }}</p>
          </div>

          <!-- 서비스 정보 -->
          <div class="receipt-section">
            <h4>서비스 정보</h4>
            <p><strong>{{ receipt.service.title }}</strong></p>
            <p>{{ receipt.service.description }}</p>
            <p>이용일: {{ formatDate(receipt.service.usage_date) }}</p>
            <p v-if="receipt.service.room_type">
              객실: {{ receipt.service.room_type }} ({{ receipt.service.nights }}박)
            </p>
          </div>

          <!-- 결제 정보 -->
          <div class="receipt-section payment-section">
            <h4>결제 정보</h4>
            <div class="payment-row">
              <span>원가</span>
              <span>${{ receipt.payment.original_price_usd.toFixed(2) }}</span>
            </div>
            <div class="payment-row">
              <span>환율</span>
              <span>1 USD = {{ receipt.payment.exchange_rate }} GLIL</span>
            </div>
            <div class="payment-row total">
              <span>결제 금액</span>
              <span>{{ receipt.payment.paid_price_glil.toLocaleString() }} GLIL</span>
            </div>
          </div>

          <!-- 예약 정보 -->
          <div class="receipt-footer">
            <p>예약일: {{ formatDate(receipt.booking_date) }}</p>
            <p>상태: {{ getStatusLabel(receipt.status) }}</p>
          </div>
        </div>

        <div v-else class="loading">
          <i class="ph-duotone ph-spinner"></i>
          로딩 중...
        </div>

        <!-- 다운로드 버튼 (선택사항) -->
        <button v-if="receipt" class="btn-download" @click="downloadPDF">
          <i class="ph-bold ph-download"></i>
          PDF 다운로드
        </button>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, watch } from 'vue';
import { api } from '@/services/api';

const props = defineProps<{
  show: boolean;
  receiptId: string;
}>();

defineEmits(['close']);

const receipt = ref(null);

const fetchReceipt = async () => {
  if (!props.receiptId) return;

  try {
    const response = await api.get(`/api/usage-history/receipt/${props.receiptId}/`);
    receipt.value = response.data;
  } catch (error) {
    console.error('Failed to fetch receipt:', error);
  }
};

const formatDate = (dateStr: string) => {
  return new Date(dateStr).toLocaleDateString('ko-KR', {
    year: 'numeric',
    month: 'long',
    day: 'numeric'
  });
};

const getStatusLabel = (status: string) => {
  const labels = {
    CONFIRMED: '예약 확정',
    USED: '이용 완료',
    CANCELLED: '취소됨'
  };
  return labels[status] || status;
};

const downloadPDF = () => {
  // PDF 생성 및 다운로드 (선택사항)
  alert('PDF 다운로드 기능은 준비 중입니다.');
};

watch(() => props.show, (newVal) => {
  if (newVal) {
    fetchReceipt();
  } else {
    receipt.value = null;
  }
});
</script>

<style scoped>
.receipt-modal {
  max-width: 600px;
}

.receipt-content {
  padding: 1rem 0;
}

.receipt-id {
  text-align: center;
  padding: 1rem;
  background: var(--bg-secondary);
  border-radius: 8px;
  margin-bottom: 2rem;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 1rem;
}

.receipt-id i {
  font-size: 2rem;
  color: var(--gli-blue);
}

.receipt-id span {
  font-size: 1.3rem;
  font-weight: 600;
  font-family: monospace;
}

.receipt-section {
  margin-bottom: 2rem;
  padding-bottom: 1rem;
  border-bottom: 1px solid var(--border-color);
}

.receipt-section h4 {
  margin-bottom: 0.75rem;
  color: var(--text-primary);
}

.receipt-section p {
  color: var(--text-secondary);
  margin: 0.5rem 0;
}

.payment-section {
  background: rgba(59, 130, 246, 0.05);
  padding: 1rem;
  border-radius: 8px;
}

.payment-row {
  display: flex;
  justify-content: space-between;
  padding: 0.5rem 0;
}

.payment-row.total {
  border-top: 2px solid var(--border-color);
  margin-top: 0.5rem;
  padding-top: 1rem;
  font-weight: 700;
  font-size: 1.2rem;
  color: var(--gli-gold);
}

.receipt-footer {
  text-align: center;
  color: var(--text-secondary);
  font-size: 0.9rem;
}

.btn-download {
  width: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 0.5rem;
  padding: 1rem;
  background: var(--gli-green);
  color: white;
  border: none;
  border-radius: 8px;
  font-weight: 600;
  cursor: pointer;
  margin-top: 1rem;
}

.loading {
  text-align: center;
  padding: 3rem;
  color: var(--text-secondary);
}
</style>
```

---

## 5. Admin Frontend (선택사항)

### 5.1 이용 내역 관리

**필요 시 Admin 페이지에서:**
- 이용 내역 조회
- 수동 등록
- 영수증 생성
- 상태 변경

---

## 6. 요약

- ✅ 완전히 새로운 기능
- ✅ DB 모델: UsageHistory
- ✅ API 2개: 목록 조회, 영수증 조회
- ✅ Frontend: UsageHistory + ReceiptModal
- ⏳ Admin: 선택사항

---

**다음 문서:** [탭 8: Transaction](./mypage_spec_tab8_transaction.md)
