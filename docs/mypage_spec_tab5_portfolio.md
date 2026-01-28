# 탭 5: Portfolio (포트폴리오) - 상세 명세서

**작성일:** 2026-01-28
**연관 탭:** Dashboard와 연동

---

## 1. 화면 분석 및 요구사항

### 1.1 화면 구성

```
┌─────────────────────────────────────────────────────────────┐
│ 📈 포트폴리오 (Portfolio)                                    │
├─────────────────────────────────────────────────────────────┤
│ [구독 중인 자산 섹션]                                        │
│                                                             │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ 🏨 Khlaeng Meas 1 Hotel                                │ │
│ │ 📍 Sihanoukville, Cambodia                              │ │
│ │ Status: Operational | Risk: Low (Safe)                │ │
│ │                                                         │ │
│ │ Staking:                                               │ │
│ │ • Asset: 500,000 GLIB                                  │ │
│ │ • APR: 12.5%                                           │ │
│ │ • Daily Reward: USDT                                   │ │
│ │ • Pending Reward: 12.50 USDT                          │ │
│ │ • Start: 2025.02.15 → Renewal: 2026.02.15            │ │
│ │                                                         │ │
│ │ [💰 USDT 즉시 수령] [🚫 구독 해지 신청]                │ │
│ └─────────────────────────────────────────────────────────┘ │
│                                                             │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ 🏢 Star Bay Residences                                 │ │
│ │ 📍 Sihanoukville, Cambodia                              │ │
│ │ Status: Pre-Sale | Risk: Mid (Moderate)               │ │
│ │                                                         │ │
│ │ Staking:                                               │ │
│ │ • Asset: 250,000 GLIB                                  │ │
│ │ • APR: 8.0%                                            │ │
│ │ • Pending Reward: 4.50 USDT                           │ │
│ │                                                         │ │
│ │ [💰 USDT 즉시 수령] [🚫 구독 해지 신청]                │ │
│ └─────────────────────────────────────────────────────────┘ │
│                                                             │
│ [해지 진행 자산 섹션]                                        │
│                                                             │
│ ┌─────────────────────────────────────────────────────────┐ │
│ │ 🏖️ Glory Bay Resort (Basic)                            │ │
│ │                                                         │ │
│ │ 해지 신청: 2025.12.05                                  │ │
│ │ 쿨다운 기간: 30일                                       │ │
│ │ 남은 기간: 20일                                         │ │
│ │                                                         │ │
│ │ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ 33%              │ │
│ │                                                         │ │
│ │ 반환 예정: 100,000 GLIB                                │ │
│ │ (쿨다운 기간 중에도 이자 지급 중)                      │ │
│ │                                                         │ │
│ │ [↩️ 해지 취소 (구독 유지)]                              │ │
│ └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

### 1.2 기능 요구사항

#### 1.2.1 구독 중인 자산 관리
1. **프로젝트 정보 표시**
   - 프로젝트 이름, 위치
   - 운영 상태 (Operational, Pre-Sale, Construction 등)
   - 위험도 (Low/Mid/High)
   - 프로젝트 이미지

2. **스테이킹 정보**
   - 스테이킹 자산 (GLIB)
   - APR (연 이율)
   - Daily Reward 타입 (USDT)
   - 미수령 보상 (Pending Reward)
   - 구독 시작일 / 갱신일

3. **리워드 수령 기능**
   - "USDT 즉시 수령" 버튼
   - 미수령 보상을 즉시 지급
   - API 호출 후 잔액 업데이트
   - 성공 토스트 알림

4. **구독 해지 신청**
   - "구독 해지 신청" 버튼
   - 확인 모달 표시
   - 30일 쿨다운 기간 안내
   - 해지 신청 후 "해지 진행 자산" 섹션으로 이동

#### 1.2.2 해지 진행 자산 관리
1. **해지 프로세스 표시**
   - 해지 신청일
   - 쿨다운 기간 (기본 30일)
   - 남은 일수 계산
   - 진행 바 시각화 (%)

2. **반환 정보**
   - 반환 예정 GLIB 수량
   - 쿨다운 중에도 이자 지급 계속됨 안내

3. **해지 취소**
   - "해지 취소 (구독 유지)" 버튼
   - 취소 시 다시 "구독 중인 자산"으로 복귀
   - 확인 모달

#### 1.2.3 기존 기능 유지
- 투자 요약 통계 (총 투자액, 현재 가치, 수익률) - 현재 구현 유지
- 프로젝트 카드 레이아웃 - 기존 디자인 개선

### 1.3 비기능 요구사항
- 리워드 수령 후 실시간 잔액 업데이트
- 해지 신청 시 트랜잭션 처리
- 남은 일수는 매일 자동 갱신
- 쿨다운 완료 시 자동 정산

---

## 2. DB 모델

### 2.1 기존 Investment 모델 확장

```python
# gli_django/investments/models.py

class Investment(models.Model):
    STATUS_CHOICES = [
        ('ACTIVE', 'Active'),
        ('UNSTAKING', 'Unstaking'),
        ('COMPLETED', 'Completed'),
        ('CANCELLED', 'Cancelled'),
    ]

    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='investments')
    project = models.ForeignKey('projects.Project', on_delete=models.CASCADE, related_name='investments')

    # 기존 필드들
    amount = models.DecimalField(max_digits=20, decimal_places=8)  # GLIB
    investment_date = models.DateTimeField(auto_now_add=True)

    # 스테이킹 관련
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='ACTIVE')
    apr = models.DecimalField(max_digits=5, decimal_places=2)  # 12.5 -> 12.5%
    daily_reward_type = models.CharField(max_length=10, default='USDT')  # USDT, GLIB 등

    # 리워드 관련 (신규)
    pending_reward_usdt = models.DecimalField(max_digits=20, decimal_places=8, default=0)
    total_claimed_reward = models.DecimalField(max_digits=20, decimal_places=8, default=0)
    last_reward_calculated = models.DateTimeField(auto_now=True)

    # 구독 기간
    start_date = models.DateField()
    renewal_date = models.DateField()  # 1년 후

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-investment_date']
        indexes = [
            models.Index(fields=['user', 'status']),
            models.Index(fields=['status']),
        ]

    def calculate_pending_reward(self):
        """일일 보상 계산 (APR 기반)"""
        if self.status != 'ACTIVE':
            return

        from datetime import datetime, timedelta
        from decimal import Decimal

        # 마지막 계산 이후 경과 일수
        now = datetime.now()
        days_elapsed = (now - self.last_reward_calculated).days

        if days_elapsed > 0:
            # 일일 보상 = (투자액 * APR) / 365
            daily_reward = (self.amount * self.apr / 100) / 365
            new_reward = daily_reward * days_elapsed

            self.pending_reward_usdt += new_reward
            self.last_reward_calculated = now
            self.save()

    def __str__(self):
        return f"{self.user.username} - {self.project.name} ({self.amount} GLIB)"
```

### 2.2 신규: PortfolioUnstaking 모델

```python
# gli_django/investments/models.py

class PortfolioUnstaking(models.Model):
    STATUS_CHOICES = [
        ('IN_PROGRESS', 'In Progress'),
        ('COMPLETED', 'Completed'),
        ('CANCELLED', 'Cancelled'),
    ]

    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='unstaking_requests')
    investment = models.OneToOneField(Investment, on_delete=models.CASCADE, related_name='unstaking')

    # 해지 정보
    request_date = models.DateTimeField(auto_now_add=True)
    cooldown_days = models.IntegerField(default=30)
    expected_completion_date = models.DateField()

    # 반환 정보
    return_amount = models.DecimalField(max_digits=20, decimal_places=8)  # GLIB
    include_pending_reward = models.BooleanField(default=True)
    final_reward_usdt = models.DecimalField(max_digits=20, decimal_places=8, default=0)

    # 상태
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='IN_PROGRESS')

    # 완료 정보
    completed_at = models.DateTimeField(null=True, blank=True)
    returned_amount = models.DecimalField(max_digits=20, decimal_places=8, null=True, blank=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-request_date']
        indexes = [
            models.Index(fields=['user', 'status']),
            models.Index(fields=['status', 'expected_completion_date']),
        ]

    @property
    def remaining_days(self):
        """남은 일수 계산"""
        from datetime import date
        today = date.today()
        if self.status != 'IN_PROGRESS':
            return 0
        delta = self.expected_completion_date - today
        return max(0, delta.days)

    @property
    def progress_percentage(self):
        """진행률 계산 (%)"""
        if self.cooldown_days == 0:
            return 100
        elapsed = self.cooldown_days - self.remaining_days
        return int((elapsed / self.cooldown_days) * 100)

    def save(self, *args, **kwargs):
        if not self.expected_completion_date:
            from datetime import timedelta
            self.expected_completion_date = (self.request_date + timedelta(days=self.cooldown_days)).date()
        super().save(*args, **kwargs)

    def __str__(self):
        return f"{self.user.username} - Unstaking {self.investment.project.name} ({self.remaining_days} days left)"
```

### 2.3 마이그레이션

```bash
python manage.py makemigrations investments
python manage.py migrate investments
```

---

## 3. API 엔드포인트

### 3.1 포트폴리오 전체 조회

```python
# GET /api/portfolio/
# Response:
{
    "summary": {
        "total_invested": 750000,
        "total_current_value": 785000,
        "total_profit_loss": 35000,
        "profit_loss_percentage": 4.67,
        "active_investments_count": 2,
        "unstaking_count": 1
    },
    "active_investments": [
        {
            "id": 1,
            "project": {
                "id": 1,
                "name": "Khlaeng Meas 1 Hotel",
                "location": "Sihanoukville, Cambodia",
                "status": "Operational",
                "risk_level": "Low",
                "image_url": "https://..."
            },
            "amount": 500000,
            "apr": 12.5,
            "daily_reward_type": "USDT",
            "pending_reward_usdt": 12.50,
            "total_claimed_reward": 125.00,
            "start_date": "2025-02-15",
            "renewal_date": "2026-02-15"
        },
        {
            "id": 2,
            "project": {
                "id": 2,
                "name": "Star Bay Residences",
                "location": "Sihanoukville, Cambodia",
                "status": "Pre-Sale",
                "risk_level": "Mid"
            },
            "amount": 250000,
            "apr": 8.0,
            "pending_reward_usdt": 4.50,
            "start_date": "2025-03-01",
            "renewal_date": "2026-03-01"
        }
    ],
    "unstaking_list": [
        {
            "id": 1,
            "investment": {
                "project_name": "Glory Bay Resort (Basic)"
            },
            "request_date": "2025-12-05",
            "cooldown_days": 30,
            "remaining_days": 20,
            "progress_percentage": 33,
            "return_amount": 100000,
            "include_pending_reward": true,
            "status": "IN_PROGRESS"
        }
    ]
}
```

**구현:**

```python
# gli_django/investments/views.py

from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from .models import Investment, PortfolioUnstaking

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_portfolio(request):
    user = request.user

    # 활성 투자 조회
    active_investments = Investment.objects.filter(
        user=user,
        status='ACTIVE'
    ).select_related('project')

    # 각 투자에 대해 pending reward 계산
    for inv in active_investments:
        inv.calculate_pending_reward()

    # 해지 진행 중인 투자 조회
    unstaking_list = PortfolioUnstaking.objects.filter(
        user=user,
        status='IN_PROGRESS'
    ).select_related('investment__project')

    # 요약 통계 계산
    total_invested = sum(inv.amount for inv in active_investments)
    total_current_value = total_invested  # 실제로는 시세 반영 필요
    total_profit_loss = sum(inv.total_claimed_reward for inv in active_investments)
    profit_loss_percentage = (total_profit_loss / total_invested * 100) if total_invested > 0 else 0

    return Response({
        'summary': {
            'total_invested': float(total_invested),
            'total_current_value': float(total_current_value),
            'total_profit_loss': float(total_profit_loss),
            'profit_loss_percentage': round(profit_loss_percentage, 2),
            'active_investments_count': active_investments.count(),
            'unstaking_count': unstaking_list.count()
        },
        'active_investments': [
            {
                'id': inv.id,
                'project': {
                    'id': inv.project.id,
                    'name': inv.project.name,
                    'location': inv.project.location,
                    'status': inv.project.status,
                    'risk_level': getattr(inv.project, 'risk_level', 'Mid'),
                    'image_url': inv.project.image.url if inv.project.image else None
                },
                'amount': float(inv.amount),
                'apr': float(inv.apr),
                'daily_reward_type': inv.daily_reward_type,
                'pending_reward_usdt': float(inv.pending_reward_usdt),
                'total_claimed_reward': float(inv.total_claimed_reward),
                'start_date': inv.start_date.isoformat(),
                'renewal_date': inv.renewal_date.isoformat()
            } for inv in active_investments
        ],
        'unstaking_list': [
            {
                'id': uns.id,
                'investment': {
                    'project_name': uns.investment.project.name
                },
                'request_date': uns.request_date.isoformat(),
                'cooldown_days': uns.cooldown_days,
                'remaining_days': uns.remaining_days,
                'progress_percentage': uns.progress_percentage,
                'return_amount': float(uns.return_amount),
                'include_pending_reward': uns.include_pending_reward,
                'status': uns.status
            } for uns in unstaking_list
        ]
    })
```

### 3.2 리워드 즉시 수령

```python
# POST /api/portfolio/claim-reward/{investment_id}/
# Response:
{
    "success": true,
    "claimed_amount": 12.50,
    "new_balance": 112.50,
    "transaction_id": 456
}
```

**구현:**

```python
# gli_django/investments/views.py

from django.db import transaction as db_transaction
from decimal import Decimal

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def claim_reward(request, investment_id):
    user = request.user

    try:
        investment = Investment.objects.select_for_update().get(
            id=investment_id,
            user=user,
            status='ACTIVE'
        )
    except Investment.DoesNotExist:
        return Response({'error': 'Investment not found'}, status=404)

    # pending reward 최신화
    investment.calculate_pending_reward()

    if investment.pending_reward_usdt <= 0:
        return Response({'error': 'No reward to claim'}, status=400)

    with db_transaction.atomic():
        claimed_amount = investment.pending_reward_usdt

        # USDT 잔액에 추가
        from assets.models import TokenBalance
        usdt_balance, _ = TokenBalance.objects.get_or_create(
            user=user,
            token='USDT'
        )
        usdt_balance.balance += claimed_amount
        usdt_balance.save()

        # Investment 업데이트
        investment.total_claimed_reward += claimed_amount
        investment.pending_reward_usdt = Decimal('0')
        investment.save()

        # Transaction 기록 (옵션)
        # ...

    return Response({
        'success': True,
        'claimed_amount': float(claimed_amount),
        'new_balance': float(usdt_balance.balance),
        'transaction_id': None  # 필요 시 추가
    })
```

### 3.3 구독 해지 신청

```python
# POST /api/portfolio/unsubscribe/{investment_id}/
# Request:
{
    "confirm": true
}
# Response:
{
    "success": true,
    "unstaking_id": 1,
    "cooldown_days": 30,
    "expected_completion_date": "2025-02-28",
    "return_amount": 500000
}
```

**구현:**

```python
# gli_django/investments/views.py

from datetime import timedelta

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def unsubscribe(request, investment_id):
    user = request.user
    confirm = request.data.get('confirm', False)

    if not confirm:
        return Response({'error': 'Confirmation required'}, status=400)

    try:
        investment = Investment.objects.select_for_update().get(
            id=investment_id,
            user=user,
            status='ACTIVE'
        )
    except Investment.DoesNotExist:
        return Response({'error': 'Investment not found'}, status=404)

    # 이미 해지 신청 중인지 확인
    if hasattr(investment, 'unstaking'):
        return Response({'error': 'Already unstaking'}, status=400)

    with db_transaction.atomic():
        # Investment 상태 변경
        investment.status = 'UNSTAKING'
        investment.save()

        # PortfolioUnstaking 생성
        cooldown_days = 30
        unstaking = PortfolioUnstaking.objects.create(
            user=user,
            investment=investment,
            cooldown_days=cooldown_days,
            return_amount=investment.amount,
            include_pending_reward=True,
            final_reward_usdt=investment.pending_reward_usdt
        )

    return Response({
        'success': True,
        'unstaking_id': unstaking.id,
        'cooldown_days': cooldown_days,
        'expected_completion_date': unstaking.expected_completion_date.isoformat(),
        'return_amount': float(investment.amount)
    })
```

### 3.4 해지 취소

```python
# POST /api/portfolio/cancel-unstaking/{unstaking_id}/
# Response:
{
    "success": true,
    "investment_id": 1
}
```

**구현:**

```python
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def cancel_unstaking(request, unstaking_id):
    user = request.user

    try:
        unstaking = PortfolioUnstaking.objects.select_for_update().get(
            id=unstaking_id,
            user=user,
            status='IN_PROGRESS'
        )
    except PortfolioUnstaking.DoesNotExist:
        return Response({'error': 'Unstaking request not found'}, status=404)

    with db_transaction.atomic():
        # Investment 상태 복원
        investment = unstaking.investment
        investment.status = 'ACTIVE'
        investment.save()

        # Unstaking 취소
        unstaking.status = 'CANCELLED'
        unstaking.save()

    return Response({
        'success': True,
        'investment_id': investment.id
    })
```

### 3.5 URL 라우팅

```python
# gli_django/investments/urls.py

from django.urls import path
from .views import (
    get_portfolio,
    claim_reward,
    unsubscribe,
    cancel_unstaking,
)

urlpatterns = [
    path('portfolio/', get_portfolio, name='portfolio'),
    path('portfolio/claim-reward/<int:investment_id>/', claim_reward, name='claim-reward'),
    path('portfolio/unsubscribe/<int:investment_id>/', unsubscribe, name='unsubscribe'),
    path('portfolio/cancel-unstaking/<int:unstaking_id>/', cancel_unstaking, name='cancel-unstaking'),
]
```

---

## 4. User Frontend 개발

### 4.1 기존 InvestmentPortfolio 컴포넌트 확장

**파일 위치:** `gli_user-frontend/src/components/InvestmentPortfolio.vue`

```vue
<template>
  <div class="investment-portfolio">
    <!-- 요약 통계 (기존 유지) -->
    <div class="portfolio-summary">
      <div class="summary-card">
        <span class="summary-label">총 투자액</span>
        <span class="summary-value">{{ summary.total_invested.toLocaleString() }} GLIB</span>
      </div>
      <div class="summary-card">
        <span class="summary-label">현재 가치</span>
        <span class="summary-value">{{ summary.total_current_value.toLocaleString() }} GLIB</span>
      </div>
      <div class="summary-card profit">
        <span class="summary-label">수익률</span>
        <span class="summary-value">{{ summary.profit_loss_percentage }}%</span>
      </div>
    </div>

    <!-- 구독 중인 자산 -->
    <section class="active-investments">
      <h3 class="section-title">
        <i class="ph-duotone ph-chart-line-up"></i>
        구독 중인 자산 ({{ activeInvestments.length }})
      </h3>

      <div class="investment-cards">
        <div
          v-for="inv in activeInvestments"
          :key="inv.id"
          class="investment-card"
        >
          <!-- 프로젝트 정보 -->
          <div class="card-header">
            <div class="project-image" v-if="inv.project.image_url">
              <img :src="inv.project.image_url" :alt="inv.project.name" />
            </div>
            <div class="project-info">
              <h4 class="project-name">{{ inv.project.name }}</h4>
              <p class="project-location">
                <i class="ph-duotone ph-map-pin"></i>
                {{ inv.project.location }}
              </p>
              <div class="project-badges">
                <span class="status-badge" :class="inv.project.status.toLowerCase()">
                  {{ inv.project.status }}
                </span>
                <span class="risk-badge" :class="getRiskClass(inv.project.risk_level)">
                  Risk: {{ inv.project.risk_level }}
                </span>
              </div>
            </div>
          </div>

          <!-- 스테이킹 정보 -->
          <div class="card-body">
            <div class="staking-info">
              <div class="info-row">
                <span class="label">Asset</span>
                <span class="value">{{ inv.amount.toLocaleString() }} GLIB</span>
              </div>
              <div class="info-row">
                <span class="label">APR</span>
                <span class="value apr">{{ inv.apr }}%</span>
              </div>
              <div class="info-row">
                <span class="label">Daily Reward</span>
                <span class="value">{{ inv.daily_reward_type }}</span>
              </div>
              <div class="info-row highlight">
                <span class="label">Pending Reward</span>
                <span class="value reward">{{ inv.pending_reward_usdt.toFixed(2) }} USDT</span>
              </div>
              <div class="info-row">
                <span class="label">Period</span>
                <span class="value">
                  {{ formatDate(inv.start_date) }} → {{ formatDate(inv.renewal_date) }}
                </span>
              </div>
            </div>
          </div>

          <!-- 액션 버튼 -->
          <div class="card-actions">
            <button
              class="btn-claim"
              :disabled="inv.pending_reward_usdt <= 0"
              @click="claimReward(inv.id)"
            >
              <i class="ph-bold ph-coins"></i>
              USDT 즉시 수령
            </button>
            <button class="btn-unsubscribe" @click="openUnsubscribeModal(inv)">
              <i class="ph-bold ph-x-circle"></i>
              구독 해지 신청
            </button>
          </div>
        </div>

        <!-- 빈 상태 -->
        <div v-if="activeInvestments.length === 0" class="empty-state">
          <i class="ph-duotone ph-chart-line"></i>
          <p>아직 구독 중인 자산이 없습니다</p>
          <button @click="$router.push('/projects')" class="btn-browse">
            프로젝트 둘러보기
          </button>
        </div>
      </div>
    </section>

    <!-- 해지 진행 자산 -->
    <section v-if="unstakingList.length > 0" class="unstaking-section">
      <h3 class="section-title">
        <i class="ph-duotone ph-clock-countdown"></i>
        해지 진행 자산 ({{ unstakingList.length }})
      </h3>

      <div class="unstaking-cards">
        <div
          v-for="uns in unstakingList"
          :key="uns.id"
          class="unstaking-card"
        >
          <h4 class="project-name">{{ uns.investment.project_name }}</h4>

          <div class="unstaking-info">
            <div class="info-row">
              <span class="label">해지 신청</span>
              <span class="value">{{ formatDate(uns.request_date) }}</span>
            </div>
            <div class="info-row">
              <span class="label">쿨다운 기간</span>
              <span class="value">{{ uns.cooldown_days }}일</span>
            </div>
            <div class="info-row highlight">
              <span class="label">남은 기간</span>
              <span class="value">{{ uns.remaining_days }}일</span>
            </div>
          </div>

          <!-- 진행 바 -->
          <div class="progress-section">
            <div class="progress-bar">
              <div class="progress" :style="{ width: `${uns.progress_percentage}%` }"></div>
            </div>
            <span class="progress-text">{{ uns.progress_percentage }}%</span>
          </div>

          <div class="return-info">
            <p class="return-amount">
              반환 예정: <strong>{{ uns.return_amount.toLocaleString() }} GLIB</strong>
            </p>
            <p class="note">
              (쿨다운 기간 중에도 이자 지급 중)
            </p>
          </div>

          <button class="btn-cancel-unstaking" @click="cancelUnstaking(uns.id)">
            <i class="ph-bold ph-arrow-counter-clockwise"></i>
            해지 취소 (구독 유지)
          </button>
        </div>
      </div>
    </section>

    <!-- 해지 확인 모달 -->
    <UnsubscribeModal
      :show="showUnsubscribeModal"
      :investment="selectedInvestment"
      @close="showUnsubscribeModal = false"
      @confirm="confirmUnsubscribe"
    />
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue';
import { api } from '@/services/api';
import UnsubscribeModal from './portfolio/UnsubscribeModal.vue';

const summary = ref({
  total_invested: 0,
  total_current_value: 0,
  total_profit_loss: 0,
  profit_loss_percentage: 0,
  active_investments_count: 0,
  unstaking_count: 0
});

const activeInvestments = ref([]);
const unstakingList = ref([]);
const showUnsubscribeModal = ref(false);
const selectedInvestment = ref(null);

const fetchPortfolio = async () => {
  try {
    const response = await api.get('/api/portfolio/');
    summary.value = response.data.summary;
    activeInvestments.value = response.data.active_investments;
    unstakingList.value = response.data.unstaking_list;
  } catch (error) {
    console.error('Failed to fetch portfolio:', error);
  }
};

const claimReward = async (investmentId: number) => {
  if (!confirm('미수령 보상을 즉시 수령하시겠습니까?')) return;

  try {
    const response = await api.post(`/api/portfolio/claim-reward/${investmentId}/`);

    if (response.data.success) {
      alert(`${response.data.claimed_amount} USDT가 지급되었습니다!`);
      await fetchPortfolio();
    }
  } catch (error) {
    console.error('Failed to claim reward:', error);
    alert('보상 수령 실패: ' + (error.response?.data?.error || error.message));
  }
};

const openUnsubscribeModal = (investment: any) => {
  selectedInvestment.value = investment;
  showUnsubscribeModal.value = true;
};

const confirmUnsubscribe = async () => {
  if (!selectedInvestment.value) return;

  try {
    const response = await api.post(
      `/api/portfolio/unsubscribe/${selectedInvestment.value.id}/`,
      { confirm: true }
    );

    if (response.data.success) {
      alert(`해지 신청이 완료되었습니다.\n쿨다운 기간: ${response.data.cooldown_days}일`);
      showUnsubscribeModal.value = false;
      await fetchPortfolio();
    }
  } catch (error) {
    console.error('Failed to unsubscribe:', error);
    alert('해지 신청 실패: ' + (error.response?.data?.error || error.message));
  }
};

const cancelUnstaking = async (unstakingId: number) => {
  if (!confirm('해지를 취소하고 구독을 유지하시겠습니까?')) return;

  try {
    const response = await api.post(`/api/portfolio/cancel-unstaking/${unstakingId}/`);

    if (response.data.success) {
      alert('해지가 취소되었습니다. 구독이 계속됩니다.');
      await fetchPortfolio();
    }
  } catch (error) {
    console.error('Failed to cancel unstaking:', error);
    alert('취소 실패: ' + (error.response?.data?.error || error.message));
  }
};

const formatDate = (dateStr: string) => {
  return new Date(dateStr).toLocaleDateString('ko-KR');
};

const getRiskClass = (riskLevel: string) => {
  return riskLevel.toLowerCase();
};

onMounted(() => {
  fetchPortfolio();
});
</script>

<style scoped>
/* 스타일은 참고 파일 기반으로 작성 */
.investment-portfolio {
  width: 100%;
}

/* 요약 통계 */
.portfolio-summary {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 1.5rem;
  margin-bottom: 2rem;
}

.summary-card {
  padding: 1.5rem;
  background: var(--bg-secondary);
  border-radius: 12px;
  border: 1px solid var(--border-color);
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.summary-label {
  font-size: 0.9rem;
  color: var(--text-secondary);
}

.summary-value {
  font-size: 1.8rem;
  font-weight: 700;
  color: var(--text-primary);
}

.summary-card.profit .summary-value {
  color: var(--gli-green);
}

/* 섹션 */
.section-title {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  font-size: 1.5rem;
  font-weight: 600;
  margin-bottom: 1.5rem;
  color: var(--text-primary);
}

/* 투자 카드 */
.investment-cards {
  display: grid;
  gap: 1.5rem;
}

.investment-card {
  background: var(--bg-secondary);
  border-radius: 16px;
  border: 1px solid var(--border-color);
  overflow: hidden;
  transition: all 0.3s;
}

.investment-card:hover {
  border-color: var(--gli-blue);
  box-shadow: 0 4px 12px rgba(59, 130, 246, 0.2);
}

.card-header {
  display: flex;
  gap: 1.5rem;
  padding: 1.5rem;
  background: var(--bg-primary);
}

.project-image {
  width: 120px;
  height: 120px;
  border-radius: 12px;
  overflow: hidden;
}

.project-image img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.project-info {
  flex: 1;
}

.project-name {
  font-size: 1.3rem;
  font-weight: 600;
  margin-bottom: 0.5rem;
  color: var(--text-primary);
}

.project-location {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  color: var(--text-secondary);
  margin-bottom: 1rem;
}

.project-badges {
  display: flex;
  gap: 0.5rem;
}

.status-badge,
.risk-badge {
  padding: 0.25rem 0.75rem;
  border-radius: 12px;
  font-size: 0.85rem;
  font-weight: 500;
}

.status-badge.operational {
  background: var(--gli-green);
  color: white;
}

.risk-badge.low {
  background: var(--gli-green);
  color: white;
}

.risk-badge.mid {
  background: var(--gli-gold);
  color: white;
}

/* 스테이킹 정보 */
.card-body {
  padding: 1.5rem;
}

.staking-info {
  display: flex;
  flex-direction: column;
  gap: 0.75rem;
}

.info-row {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 0.5rem 0;
  border-bottom: 1px solid var(--border-color);
}

.info-row:last-child {
  border-bottom: none;
}

.info-row.highlight {
  background: rgba(59, 130, 246, 0.1);
  padding: 0.75rem;
  border-radius: 8px;
  border: none;
}

.label {
  font-size: 0.9rem;
  color: var(--text-secondary);
}

.value {
  font-weight: 600;
  color: var(--text-primary);
}

.value.apr {
  color: var(--gli-green);
  font-size: 1.1rem;
}

.value.reward {
  color: var(--gli-gold);
  font-size: 1.2rem;
}

/* 액션 버튼 */
.card-actions {
  display: flex;
  gap: 1rem;
  padding: 1.5rem;
  background: var(--bg-primary);
}

.btn-claim,
.btn-unsubscribe {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 0.5rem;
  padding: 1rem;
  border: none;
  border-radius: 8px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s;
}

.btn-claim {
  background: var(--gli-green);
  color: white;
}

.btn-claim:hover:not(:disabled) {
  background: #10b981;
  transform: translateY(-2px);
}

.btn-claim:disabled {
  background: var(--bg-secondary);
  color: var(--text-secondary);
  cursor: not-allowed;
}

.btn-unsubscribe {
  background: var(--gli-orange);
  color: white;
}

.btn-unsubscribe:hover {
  background: #e74c3c;
  transform: translateY(-2px);
}

/* 해지 진행 카드 */
.unstaking-section {
  margin-top: 3rem;
}

.unstaking-cards {
  display: grid;
  gap: 1.5rem;
}

.unstaking-card {
  padding: 1.5rem;
  background: var(--bg-secondary);
  border-radius: 16px;
  border: 1px solid var(--gli-orange);
}

.unstaking-info {
  margin: 1rem 0;
}

.progress-section {
  margin: 1.5rem 0;
}

.progress-bar {
  height: 8px;
  background: var(--bg-primary);
  border-radius: 4px;
  overflow: hidden;
  margin-bottom: 0.5rem;
}

.progress {
  height: 100%;
  background: linear-gradient(90deg, var(--gli-blue), var(--gli-purple));
  transition: width 0.3s;
}

.progress-text {
  font-size: 0.9rem;
  color: var(--text-secondary);
}

.return-info {
  margin: 1.5rem 0;
  padding: 1rem;
  background: rgba(59, 130, 246, 0.1);
  border-radius: 8px;
}

.return-amount {
  font-size: 1.1rem;
  margin-bottom: 0.5rem;
}

.note {
  font-size: 0.85rem;
  color: var(--text-secondary);
}

.btn-cancel-unstaking {
  width: 100%;
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
}

.btn-cancel-unstaking:hover {
  background: var(--gli-purple);
  transform: translateY(-2px);
}

/* 빈 상태 */
.empty-state {
  text-align: center;
  padding: 3rem;
  color: var(--text-secondary);
}

.empty-state i {
  font-size: 4rem;
  margin-bottom: 1rem;
  opacity: 0.5;
}

.btn-browse {
  margin-top: 1rem;
  padding: 0.75rem 1.5rem;
  background: var(--gli-blue);
  color: white;
  border: none;
  border-radius: 8px;
  font-weight: 600;
  cursor: pointer;
}
</style>
```

### 4.2 해지 확인 모달 컴포넌트

**파일:** `gli_user-frontend/src/components/portfolio/UnsubscribeModal.vue`

```vue
<template>
  <div v-if="show" class="modal-overlay" @click="$emit('close')">
    <div class="modal-content" @click.stop>
      <div class="modal-header">
        <h3>구독 해지 확인</h3>
        <button class="modal-close" @click="$emit('close')">×</button>
      </div>
      <div class="modal-body">
        <div class="warning-box">
          <i class="ph-fill ph-warning-circle"></i>
          <p>정말 구독을 해지하시겠습니까?</p>
        </div>

        <div v-if="investment" class="investment-summary">
          <h4>{{ investment.project.name }}</h4>
          <div class="summary-row">
            <span>투자 금액</span>
            <span>{{ investment.amount.toLocaleString() }} GLIB</span>
          </div>
          <div class="summary-row">
            <span>미수령 보상</span>
            <span>{{ investment.pending_reward_usdt.toFixed(2) }} USDT</span>
          </div>
        </div>

        <div class="cooldown-notice">
          <h4>⏱️ 쿨다운 기간: 30일</h4>
          <ul>
            <li>해지 신청 후 30일 후에 자산이 반환됩니다</li>
            <li>쿨다운 기간 중에도 이자는 계속 지급됩니다</li>
            <li>쿨다운 기간 중 언제든지 해지를 취소할 수 있습니다</li>
            <li>30일이 지나면 자동으로 GLIB가 반환됩니다</li>
          </ul>
        </div>

        <div class="modal-actions">
          <button class="btn-cancel" @click="$emit('close')">
            취소
          </button>
          <button class="btn-confirm" @click="$emit('confirm')">
            해지 신청
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
defineProps<{
  show: boolean;
  investment: any;
}>();

defineEmits(['close', 'confirm']);
</script>

<style scoped>
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  bottom: 0;
  background: rgba(0, 0, 0, 0.7);
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 1000;
}

.modal-content {
  background: var(--bg-primary);
  border-radius: 16px;
  max-width: 500px;
  width: 90%;
  max-height: 90vh;
  overflow-y: auto;
}

.modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1.5rem;
  border-bottom: 1px solid var(--border-color);
}

.modal-header h3 {
  font-size: 1.3rem;
  color: var(--text-primary);
}

.modal-close {
  background: none;
  border: none;
  font-size: 1.5rem;
  cursor: pointer;
  color: var(--text-secondary);
}

.modal-body {
  padding: 1.5rem;
}

.warning-box {
  display: flex;
  align-items: center;
  gap: 1rem;
  padding: 1rem;
  background: rgba(251, 146, 60, 0.1);
  border: 1px solid var(--gli-orange);
  border-radius: 8px;
  margin-bottom: 1.5rem;
}

.warning-box i {
  font-size: 2rem;
  color: var(--gli-orange);
}

.investment-summary {
  padding: 1rem;
  background: var(--bg-secondary);
  border-radius: 8px;
  margin-bottom: 1.5rem;
}

.investment-summary h4 {
  margin-bottom: 1rem;
  color: var(--text-primary);
}

.summary-row {
  display: flex;
  justify-content: space-between;
  padding: 0.5rem 0;
  border-bottom: 1px solid var(--border-color);
}

.cooldown-notice {
  padding: 1rem;
  background: rgba(59, 130, 246, 0.1);
  border-radius: 8px;
  margin-bottom: 1.5rem;
}

.cooldown-notice h4 {
  margin-bottom: 0.75rem;
  color: var(--gli-blue);
}

.cooldown-notice ul {
  list-style: none;
  padding: 0;
}

.cooldown-notice li {
  padding: 0.5rem 0;
  padding-left: 1.5rem;
  position: relative;
  color: var(--text-secondary);
}

.cooldown-notice li::before {
  content: "•";
  position: absolute;
  left: 0;
  color: var(--gli-blue);
}

.modal-actions {
  display: flex;
  gap: 1rem;
}

.btn-cancel,
.btn-confirm {
  flex: 1;
  padding: 1rem;
  border: none;
  border-radius: 8px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s;
}

.btn-cancel {
  background: var(--bg-secondary);
  color: var(--text-primary);
}

.btn-cancel:hover {
  background: var(--bg-primary);
}

.btn-confirm {
  background: var(--gli-orange);
  color: white;
}

.btn-confirm:hover {
  background: #e74c3c;
}
</style>
```

---

## 5. 요약 및 체크리스트

### 5.1 개발 항목

- [x] DB 모델 설계
  - [x] Investment 모델 확장 (pending_reward_usdt 등)
  - [x] PortfolioUnstaking 모델 신규 생성

- [x] API 엔드포인트
  - [x] GET /api/portfolio/ - 전체 조회
  - [x] POST /api/portfolio/claim-reward/{id}/ - 리워드 수령
  - [x] POST /api/portfolio/unsubscribe/{id}/ - 해지 신청
  - [x] POST /api/portfolio/cancel-unstaking/{id}/ - 해지 취소

- [x] User Frontend
  - [x] InvestmentPortfolio 컴포넌트 확장
  - [x] UnsubscribeModal 컴포넌트 신규 생성
  - [x] 리워드 수령 기능
  - [x] 해지 프로세스 UI

### 5.2 테스트 시나리오

1. **리워드 수령 테스트**
   - pending_reward가 있는 투자에서 수령 버튼 클릭
   - USDT 잔액 증가 확인
   - pending_reward 0으로 초기화 확인

2. **해지 신청 테스트**
   - 활성 투자에서 해지 신청
   - 모달 확인 후 신청
   - "해지 진행 자산" 섹션으로 이동 확인

3. **해지 취소 테스트**
   - 해지 진행 중인 자산에서 취소
   - 다시 "구독 중인 자산"으로 복귀 확인

4. **쿨다운 진행률 테스트**
   - 남은 일수 계산 확인
   - 진행 바 % 확인

### 5.3 주의사항

- 쿨다운 기간 중에도 일일 보상 계산 계속 실행
- 해지 완료 시 자동 정산 로직 필요 (Celery Task)
- 리워드 수령 시 트랜잭션 기록 (선택사항)

---

**다음 문서:** [탭 6: Shopping](./mypage_spec_tab6_shopping.md)
