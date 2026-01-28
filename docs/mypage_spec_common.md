# MyPage 공통 작업 명세서

**작성일:** 2026-01-28
**목적:** 탭별 명세서 외 공통 요소 정의 (프로필 요약, 메뉴, 모달, 디자인)

---

## 1. 프로필 요약 섹션 (Profile Summary)

### 1.1 화면 분석

참고 파일의 상단 섹션은 다음 요소로 구성:

```
┌────────────────────────────────────────────────────────────┐
│  [아바타+레벨]  [이름+이메일]  [배지]  │  [자산/포인트]   │
└────────────────────────────────────────────────────────────┘
```

**구성 요소:**
1. **아바타 영역**
   - 128px 원형 아바타
   - 그라데이션 테두리 (blue → purple)
   - 레벨 배지 (우하단)
   - 호버 시 업그레이드 아이콘 표시
   - 클릭 시 등급 업그레이드 모달

2. **사용자 정보**
   - 이름 + 편집 버튼
   - 이메일 주소
   - 회원 등급 배지 ("Basic Access" / "Premium" / "VIP")
   - KYC 인증 상태 배지

3. **Quick Stats**
   - Total Assets (GLIB)
   - Points (P)

### 1.2 DB 모델 확장

**User 모델 확장 필요:**

```python
# gli_django/accounts/models.py

from django.contrib.auth.models import AbstractUser
from django.db import models

class User(AbstractUser):
    # 기존 필드들...

    # 추가 필드
    level = models.IntegerField(default=1, verbose_name="회원 레벨")
    points = models.IntegerField(default=0, verbose_name="보유 포인트")

    MEMBERSHIP_CHOICES = [
        ('BASIC', 'Basic Access'),
        ('PREMIUM', 'Premium'),
        ('VIP', 'VIP'),
    ]
    membership_tier = models.CharField(
        max_length=10,
        choices=MEMBERSHIP_CHOICES,
        default='BASIC',
        verbose_name="회원 등급"
    )

    kyc_verified = models.BooleanField(
        default=False,
        verbose_name="KYC 인증 완료"
    )

    avatar_url = models.URLField(
        null=True,
        blank=True,
        verbose_name="프로필 사진 URL"
    )

    def get_total_assets_glib(self):
        """총 자산 (GLIB 기준)"""
        # TODO: TokenBalance 모델에서 계산
        pass

    class Meta:
        verbose_name = "사용자"
        verbose_name_plural = "사용자"
```

**마이그레이션 생성:**

```bash
python manage.py makemigrations accounts
python manage.py migrate accounts
```

### 1.3 API 엔드포인트

**GET /api/user/profile-summary/**

```python
# gli_django/accounts/views.py

from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def profile_summary(request):
    """프로필 요약 데이터"""
    user = request.user

    # 총 자산 계산 (TokenBalance 모델 활용)
    total_assets = user.get_total_assets_glib() or 0

    return Response({
        'avatar_url': user.avatar_url or f"https://ui-avatars.com/api/?name={user.username}&background=0f172a&color=3b82f6&bold=true",
        'username': user.username,
        'email': user.email,
        'level': user.level,
        'points': user.points,
        'membership_tier': user.membership_tier,
        'membership_display': user.get_membership_tier_display(),
        'kyc_verified': user.kyc_verified,
        'total_assets_glib': total_assets,
    })
```

**URLconf:**

```python
# gli_django/accounts/urls.py

urlpatterns = [
    # ...
    path('profile-summary/', views.profile_summary, name='profile-summary'),
]
```

### 1.4 Frontend 구현

**MyPageView.vue 상단 섹션:**

```vue
<template>
  <!-- Profile Summary Section -->
  <section class="glass-panel rounded-3xl p-8 relative overflow-hidden profile-glow max-w-5xl mx-auto mb-8">
    <!-- Background Glow -->
    <div class="absolute top-0 right-0 w-64 h-64 bg-blue-500/10 rounded-full blur-[80px] -translate-y-1/2 translate-x-1/2 pointer-events-none"></div>

    <div class="relative z-10 flex flex-col md:flex-row items-center md:items-start gap-8">
      <!-- Avatar -->
      <div class="relative group cursor-pointer" @click="openUpgradeModal">
        <div class="w-28 h-28 rounded-full p-[2px] bg-gradient-to-br from-blue-400 via-purple-500 to-slate-800">
          <div class="w-full h-full rounded-full overflow-hidden border-4 border-navy-900 bg-navy-800 relative">
            <img :src="profileSummary.avatar_url" :alt="profileSummary.username" class="w-full h-full object-cover">
            <div class="absolute inset-0 bg-black/50 flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity">
              <i class="ph-bold ph-arrow-circle-up text-white text-2xl"></i>
            </div>
          </div>
        </div>
        <div class="absolute bottom-1 right-1 bg-gradient-to-r from-blue-600 to-cyan-500 text-white text-[10px] font-black px-2 py-0.5 rounded-full border border-navy-900 shadow-lg font-mono">
          Lv.{{ profileSummary.level }}
        </div>
      </div>

      <!-- User Info -->
      <div class="flex-grow text-center md:text-left space-y-4">
        <div>
          <div class="flex items-center justify-center md:justify-start gap-3 mb-1">
            <h1 class="text-3xl font-bold text-white tracking-tight">{{ profileSummary.username }}</h1>
            <button class="text-gray-500 hover:text-blue-400 transition">
              <i class="ph-bold ph-pencil-simple"></i>
            </button>
          </div>
          <p class="text-gray-400 font-medium tracking-wide">{{ profileSummary.email }}</p>
        </div>

        <div class="flex flex-wrap justify-center md:justify-start gap-3">
          <!-- Membership Badge -->
          <div
            class="px-4 py-1.5 border rounded-lg text-xs font-bold uppercase tracking-wider flex items-center gap-2 cursor-pointer transition"
            :class="membershipBadgeClass"
            @click="openUpgradeModal"
          >
            <i class="ph-fill ph-crown"></i> {{ profileSummary.membership_display }}
          </div>

          <!-- KYC Badge -->
          <div
            v-if="profileSummary.kyc_verified"
            class="px-4 py-1.5 bg-green-500/10 border border-green-500/20 rounded-lg text-green-400 text-xs font-bold uppercase tracking-wider flex items-center gap-2"
          >
            <i class="ph-fill ph-check-circle"></i> KYC Verified
          </div>
        </div>
      </div>

      <!-- Quick Stats -->
      <div class="hidden md:flex gap-8 border-l border-white/10 pl-8">
        <div class="text-center">
          <div class="text-gray-500 text-xs font-bold uppercase mb-1">Total Assets</div>
          <div class="text-xl font-mono font-bold text-white">
            {{ formatNumber(profileSummary.total_assets_glib) }}
            <span class="text-xs text-gray-500">GLIB</span>
          </div>
        </div>
        <div class="text-center">
          <div class="text-gray-500 text-xs font-bold uppercase mb-1">Points</div>
          <div class="text-xl font-mono font-bold text-white">
            {{ formatNumber(profileSummary.points) }}
            <span class="text-xs text-gray-500">P</span>
          </div>
        </div>
      </div>
    </div>
  </section>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue';
import axios from 'axios';

const profileSummary = ref({
  avatar_url: '',
  username: 'Guest User',
  email: '',
  level: 1,
  points: 0,
  membership_tier: 'BASIC',
  membership_display: 'Basic Access',
  kyc_verified: false,
  total_assets_glib: 0,
});

const membershipBadgeClass = computed(() => {
  const tier = profileSummary.value.membership_tier;
  if (tier === 'VIP') {
    return 'bg-purple-500/10 border-purple-500/20 text-purple-400 hover:bg-purple-500/20';
  } else if (tier === 'PREMIUM') {
    return 'bg-blue-500/10 border-blue-500/20 text-blue-400 hover:bg-blue-500/20';
  } else {
    return 'bg-blue-500/10 border-blue-500/20 text-blue-400 hover:bg-blue-500/20';
  }
});

const fetchProfileSummary = async () => {
  try {
    const response = await axios.get('/api/user/profile-summary/');
    profileSummary.value = response.data;
  } catch (error) {
    console.error('프로필 요약 로드 실패:', error);
  }
};

const formatNumber = (num) => {
  return new Intl.NumberFormat('en-US').format(num);
};

const openUpgradeModal = () => {
  // TODO: 등급 업그레이드 모달 열기
  console.log('등급 업그레이드 모달');
};

onMounted(() => {
  fetchProfileSummary();
});
</script>

<style scoped>
.profile-glow {
  box-shadow: 0 0 40px rgba(59, 130, 246, 0.15);
}
</style>
```

---

## 2. 9-그리드 메뉴 네비게이션

### 2.1 화면 분석

참고 파일의 메뉴는 9개 버튼을 3x3 그리드 (데스크톱) 또는 가로 스크롤 (모바일)로 표시:

**탭 구성:**

| 순서 | ID | 제목 | 아이콘 | 색상 | 설명 |
|------|-----|------|--------|------|------|
| 1 | profile | 회원 정보 | ph-user-gear | Blue | 개인정보 |
| 2 | security | 보안 설정 | ph-shield-check | Purple | 계정 보호 |
| 3 | referral | 추천 코드 | ph-users-three | Cyan | 친구 초대 |
| 4 | dashboard | 대시보드 | ph-chart-pie-slice | Emerald | 자산 현황 |
| 5 | portfolio | 포트폴리오 | ph-buildings | Indigo | 구독 관리 |
| 6 | shopping | GLIL 쇼핑 | ph-shopping-bag | Gray | 준비중 |
| 7 | usage | 이용 내역 | ph-receipt | Orange | 사용 기록 |
| 8 | transaction | 거래 내역 | ph-scroll | Pink | P2P 기록 |
| 9 | wallet | 입출금 | ph-arrows-left-right | Teal | 지갑 전송 |

### 2.2 Frontend 구현

**MyPageView.vue 메뉴 섹션:**

```vue
<template>
  <!-- 9-Grid Menu -->
  <section class="flex flex-nowrap lg:grid lg:grid-cols-9 gap-2 overflow-x-auto pb-4 lg:pb-0 scrollbar-hide snap-x w-full mb-8">

    <!-- Tab 1: Profile -->
    <button
      @click="switchTab('profile')"
      class="menu-card rounded-xl p-3 group flex flex-col items-center text-center gap-3 min-w-[100px] lg:min-w-0 flex-1 snap-start"
      :class="{ active: activeTab === 'profile' }"
    >
      <div class="w-10 h-10 rounded-xl bg-blue-500/10 flex items-center justify-center text-blue-400 group-hover:scale-110 group-hover:bg-blue-500 group-hover:text-white transition-all duration-300">
        <i class="ph-duotone ph-user-gear text-xl"></i>
      </div>
      <div>
        <h3 class="text-xs font-bold text-gray-200 group-hover:text-white mb-0.5 whitespace-nowrap">회원 정보</h3>
        <p class="text-[9px] text-gray-500 font-medium hidden xl:block">개인정보</p>
      </div>
    </button>

    <!-- Tab 2: Security -->
    <button
      @click="switchTab('security')"
      class="menu-card rounded-xl p-3 group flex flex-col items-center text-center gap-3 min-w-[100px] lg:min-w-0 flex-1 snap-start"
      :class="{ active: activeTab === 'security' }"
    >
      <div class="w-10 h-10 rounded-xl bg-purple-500/10 flex items-center justify-center text-purple-400 group-hover:scale-110 group-hover:bg-purple-500 group-hover:text-white transition-all duration-300">
        <i class="ph-duotone ph-shield-check text-xl"></i>
      </div>
      <div>
        <h3 class="text-xs font-bold text-gray-200 group-hover:text-white mb-0.5 whitespace-nowrap">보안 설정</h3>
        <p class="text-[9px] text-gray-500 font-medium hidden xl:block">계정 보호</p>
      </div>
    </button>

    <!-- Tab 3: Referral -->
    <button
      @click="switchTab('referral')"
      class="menu-card rounded-xl p-3 group flex flex-col items-center text-center gap-3 min-w-[100px] lg:min-w-0 flex-1 snap-start"
      :class="{ active: activeTab === 'referral' }"
    >
      <div class="w-10 h-10 rounded-xl bg-cyan-500/10 flex items-center justify-center text-cyan-400 group-hover:scale-110 group-hover:bg-cyan-500 group-hover:text-white transition-all duration-300">
        <i class="ph-duotone ph-users-three text-xl"></i>
      </div>
      <div>
        <h3 class="text-xs font-bold text-gray-200 group-hover:text-white mb-0.5 whitespace-nowrap">추천 코드</h3>
        <p class="text-[9px] text-gray-500 font-medium hidden xl:block">친구 초대</p>
      </div>
    </button>

    <!-- Tab 4: Dashboard (Default Active) -->
    <button
      @click="switchTab('dashboard')"
      class="menu-card rounded-xl p-3 group flex flex-col items-center text-center gap-3 min-w-[100px] lg:min-w-0 flex-1 snap-start"
      :class="{ active: activeTab === 'dashboard' }"
    >
      <div class="w-10 h-10 rounded-xl bg-emerald-500/10 flex items-center justify-center text-emerald-400 group-hover:scale-110 group-hover:bg-emerald-500 group-hover:text-white transition-all duration-300">
        <i class="ph-duotone ph-chart-pie-slice text-xl"></i>
      </div>
      <div>
        <h3 class="text-xs font-bold text-gray-200 group-hover:text-white mb-0.5 whitespace-nowrap">대시 보드</h3>
        <p class="text-[9px] text-gray-500 font-medium hidden xl:block">자산 현황</p>
      </div>
    </button>

    <!-- Tab 5: Portfolio -->
    <button
      @click="switchTab('portfolio')"
      class="menu-card rounded-xl p-3 group flex flex-col items-center text-center gap-3 min-w-[100px] lg:min-w-0 flex-1 snap-start"
      :class="{ active: activeTab === 'portfolio' }"
    >
      <div class="w-10 h-10 rounded-xl bg-indigo-500/10 flex items-center justify-center text-indigo-400 group-hover:scale-110 group-hover:bg-indigo-500 group-hover:text-white transition-all duration-300">
        <i class="ph-duotone ph-buildings text-xl"></i>
      </div>
      <div>
        <h3 class="text-xs font-bold text-gray-200 group-hover:text-white mb-0.5 whitespace-nowrap">포트폴리오</h3>
        <p class="text-[9px] text-gray-500 font-medium hidden xl:block">구독 관리</p>
      </div>
    </button>

    <!-- Tab 6: Shopping -->
    <button
      @click="switchTab('shopping')"
      class="menu-card rounded-xl p-3 group flex flex-col items-center text-center gap-3 relative min-w-[100px] lg:min-w-0 flex-1 snap-start"
      :class="{ active: activeTab === 'shopping' }"
    >
      <div class="w-10 h-10 rounded-xl bg-white/5 flex items-center justify-center text-gray-400 group-hover:text-blue-400 transition-all duration-300">
        <i class="ph-duotone ph-shopping-bag text-xl"></i>
      </div>
      <div>
        <h3 class="text-xs font-bold text-gray-200 group-hover:text-white mb-0.5 whitespace-nowrap">GLIL 쇼핑</h3>
        <p class="text-[9px] text-gray-500 font-medium hidden xl:block">이용 가능</p>
      </div>
    </button>

    <!-- Tab 7: Usage -->
    <button
      @click="switchTab('usage')"
      class="menu-card rounded-xl p-3 group flex flex-col items-center text-center gap-3 min-w-[100px] lg:min-w-0 flex-1 snap-start"
      :class="{ active: activeTab === 'usage' }"
    >
      <div class="w-10 h-10 rounded-xl bg-orange-500/10 flex items-center justify-center text-orange-400 group-hover:scale-110 group-hover:bg-orange-500 group-hover:text-white transition-all duration-300">
        <i class="ph-duotone ph-receipt text-xl"></i>
      </div>
      <div>
        <h3 class="text-xs font-bold text-gray-200 group-hover:text-white mb-0.5 whitespace-nowrap">이용 내역</h3>
        <p class="text-[9px] text-gray-500 font-medium hidden xl:block">사용 기록</p>
      </div>
    </button>

    <!-- Tab 8: Transaction -->
    <button
      @click="switchTab('transaction')"
      class="menu-card rounded-xl p-3 group flex flex-col items-center text-center gap-3 min-w-[100px] lg:min-w-0 flex-1 snap-start"
      :class="{ active: activeTab === 'transaction' }"
    >
      <div class="w-10 h-10 rounded-xl bg-pink-500/10 flex items-center justify-center text-pink-400 group-hover:scale-110 group-hover:bg-pink-500 group-hover:text-white transition-all duration-300">
        <i class="ph-duotone ph-scroll text-xl"></i>
      </div>
      <div>
        <h3 class="text-xs font-bold text-gray-200 group-hover:text-white mb-0.5 whitespace-nowrap">거래 내역</h3>
        <p class="text-[9px] text-gray-500 font-medium hidden xl:block">P2P 기록</p>
      </div>
    </button>

    <!-- Tab 9: Wallet -->
    <button
      @click="switchTab('wallet')"
      class="menu-card rounded-xl p-3 group flex flex-col items-center text-center gap-3 min-w-[100px] lg:min-w-0 flex-1 snap-start"
      :class="{ active: activeTab === 'wallet' }"
    >
      <div class="w-10 h-10 rounded-xl bg-teal-500/10 flex items-center justify-center text-teal-400 group-hover:scale-110 group-hover:bg-teal-500 group-hover:text-white transition-all duration-300">
        <i class="ph-duotone ph-arrows-left-right text-xl"></i>
      </div>
      <div>
        <h3 class="text-xs font-bold text-gray-200 group-hover:text-white mb-0.5 whitespace-nowrap">입출금</h3>
        <p class="text-[9px] text-gray-500 font-medium hidden xl:block">지갑 전송</p>
      </div>
    </button>

  </section>
</template>

<script setup>
import { ref } from 'vue';

const activeTab = ref('dashboard');

const switchTab = (tab) => {
  activeTab.value = tab;
};
</script>

<style scoped>
.menu-card {
  background: linear-gradient(145deg, rgba(30, 41, 59, 0.4) 0%, rgba(15, 23, 42, 0.4) 100%);
  border: 1px solid rgba(255, 255, 255, 0.05);
  transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
  position: relative;
  overflow: hidden;
  cursor: pointer;
}

.menu-card:hover {
  transform: translateY(-3px);
  border-color: rgba(59, 130, 246, 0.3);
  background: linear-gradient(145deg, rgba(30, 41, 59, 0.7) 0%, rgba(15, 23, 42, 0.8) 100%);
  box-shadow: 0 5px 15px -3px rgba(59, 130, 246, 0.15);
}

.menu-card.active {
  border-color: #3b82f6;
  background: linear-gradient(145deg, rgba(59, 130, 246, 0.2) 0%, rgba(15, 23, 42, 0.8) 100%);
  box-shadow: 0 0 20px rgba(59, 130, 246, 0.3);
}

.menu-card::before {
  content: '';
  position: absolute;
  top: 0;
  left: 0;
  right: 0;
  height: 1px;
  background: linear-gradient(90deg, transparent, rgba(59, 130, 246, 0.5), transparent);
  opacity: 0;
  transition: opacity 0.3s ease;
}

.menu-card:hover::before,
.menu-card.active::before {
  opacity: 1;
}

.scrollbar-hide::-webkit-scrollbar {
  display: none;
}

.scrollbar-hide {
  -ms-overflow-style: none;
  scrollbar-width: none;
}
</style>
```

---

## 3. 모달 시스템

### 3.1 모달 목록

참고 파일에 정의된 8개의 모달:

1. **비밀번호 변경 모달** - `ModalPasswordChange.vue`
2. **휴대전화 인증 모달** - `ModalPhoneVerification.vue`
3. **얼굴 인증 모달** - `ModalFaceAuth.vue`
4. **QR 코드 모달 (추천)** - `ModalQRCode.vue`
5. **Google OTP 설정 모달** - `Modal2FASetup.vue`
6. **PIN 번호 설정 모달** - `ModalPINSetup.vue`
7. **등급 업그레이드 모달** - `ModalUpgrade.vue`
8. **주소 추가 모달 (지갑)** - `ModalAddAddress.vue`

### 3.2 공통 모달 컴포넌트

**BaseModal.vue** (재사용 가능한 베이스 모달)

```vue
<template>
  <Teleport to="body">
    <div
      class="modal-overlay"
      :class="{ active: isOpen }"
      @click.self="closeModal"
    >
      <div class="modal-content glass-panel rounded-3xl p-8 max-w-lg w-full mx-4 relative">
        <!-- Close Button -->
        <button
          @click="closeModal"
          class="absolute top-6 right-6 text-gray-400 hover:text-white transition"
        >
          <i class="ph-bold ph-x text-2xl"></i>
        </button>

        <!-- Header Slot -->
        <div v-if="$slots.header" class="mb-6">
          <slot name="header"></slot>
        </div>

        <!-- Body Slot -->
        <div>
          <slot></slot>
        </div>

        <!-- Footer Slot -->
        <div v-if="$slots.footer" class="mt-6">
          <slot name="footer"></slot>
        </div>
      </div>
    </div>
  </Teleport>
</template>

<script setup>
import { defineProps, defineEmits, watch } from 'vue';

const props = defineProps({
  isOpen: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['close']);

const closeModal = () => {
  emit('close');
};

// Prevent body scroll when modal is open
watch(() => props.isOpen, (newVal) => {
  if (newVal) {
    document.body.style.overflow = 'hidden';
  } else {
    document.body.style.overflow = '';
  }
});
</script>

<style scoped>
.modal-overlay {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background: rgba(0, 0, 0, 0.8);
  backdrop-filter: blur(5px);
  z-index: 100;
  display: flex;
  align-items: center;
  justify-content: center;
  opacity: 0;
  pointer-events: none;
  transition: opacity 0.3s ease;
}

.modal-overlay.active {
  opacity: 1;
  pointer-events: auto;
}

.modal-content {
  transform: scale(0.95);
  transition: transform 0.3s cubic-bezier(0.34, 1.56, 0.64, 1);
}

.modal-overlay.active .modal-content {
  transform: scale(1);
}
</style>
```

### 3.3 등급 업그레이드 모달 예시

**ModalUpgrade.vue**

```vue
<template>
  <BaseModal :is-open="isOpen" @close="closeModal">
    <template #header>
      <div class="flex items-center gap-3">
        <div class="w-12 h-12 rounded-xl bg-gradient-to-br from-blue-500 to-purple-600 flex items-center justify-center">
          <i class="ph-bold ph-crown text-white text-2xl"></i>
        </div>
        <div>
          <h2 class="text-2xl font-bold text-white">멤버십 업그레이드</h2>
          <p class="text-sm text-gray-400">더 많은 혜택을 누리세요</p>
        </div>
      </div>
    </template>

    <!-- Body -->
    <div class="space-y-4">
      <!-- Current Tier -->
      <div class="bg-navy-950 border border-white/10 rounded-xl p-4">
        <p class="text-xs text-gray-500 mb-2">현재 등급</p>
        <div class="flex items-center gap-3">
          <div class="px-4 py-2 bg-blue-500/10 border border-blue-500/20 rounded-lg text-blue-400 text-sm font-bold">
            Basic Access
          </div>
          <span class="text-gray-400">→</span>
          <div class="px-4 py-2 bg-gradient-to-r from-purple-600 to-blue-600 rounded-lg text-white text-sm font-bold">
            Premium
          </div>
        </div>
      </div>

      <!-- Benefits -->
      <div class="space-y-3">
        <h3 class="text-sm font-bold text-gray-300">Premium 혜택</h3>
        <ul class="space-y-2">
          <li class="flex items-start gap-3">
            <i class="ph-fill ph-check-circle text-green-400 mt-0.5"></i>
            <span class="text-sm text-gray-300">높은 APR 스테이킹 이자율</span>
          </li>
          <li class="flex items-start gap-3">
            <i class="ph-fill ph-check-circle text-green-400 mt-0.5"></i>
            <span class="text-sm text-gray-300">우선 프로젝트 참여 권한</span>
          </li>
          <li class="flex items-start gap-3">
            <i class="ph-fill ph-check-circle text-green-400 mt-0.5"></i>
            <span class="text-sm text-gray-300">전용 고객 지원</span>
          </li>
        </ul>
      </div>

      <!-- Price -->
      <div class="bg-gradient-to-r from-purple-900/30 to-blue-900/30 border border-purple-500/20 rounded-xl p-4">
        <div class="flex justify-between items-center">
          <span class="text-gray-300">업그레이드 비용</span>
          <div class="text-right">
            <p class="text-2xl font-bold text-white">500,000 GLIB</p>
            <p class="text-xs text-gray-400">≈ $5,000 USD</p>
          </div>
        </div>
      </div>
    </div>

    <template #footer>
      <div class="flex gap-3">
        <button
          @click="closeModal"
          class="flex-1 py-3 bg-white/5 hover:bg-white/10 border border-white/10 rounded-xl text-gray-300 font-bold transition"
        >
          취소
        </button>
        <button
          @click="handleUpgrade"
          class="flex-1 py-3 bg-gradient-to-r from-purple-600 to-blue-600 hover:from-purple-500 hover:to-blue-500 rounded-xl text-white font-bold transition"
        >
          업그레이드
        </button>
      </div>
    </template>
  </BaseModal>
</template>

<script setup>
import BaseModal from './BaseModal.vue';
import { defineProps, defineEmits } from 'vue';

defineProps({
  isOpen: {
    type: Boolean,
    default: false,
  },
});

const emit = defineEmits(['close', 'upgrade']);

const closeModal = () => {
  emit('close');
};

const handleUpgrade = () => {
  emit('upgrade');
  closeModal();
};
</script>
```

---

## 4. 디자인 시스템

### 4.1 색상 팔레트

```css
:root {
  /* GLI Brand Colors */
  --gli-blue: #3b82f6;
  --gli-purple: #a855f7;
  --gli-cyan: #06b6d4;
  --gli-green: #10b981;
  --gli-orange: #f97316;
  --gli-gold: #fbbf24;

  /* Backgrounds */
  --bg-primary: #020617;
  --bg-secondary: #0f172a;
  --bg-tertiary: #1e293b;

  /* Text */
  --text-primary: #e2e8f0;
  --text-secondary: #94a3b8;
  --text-muted: #64748b;

  /* Borders */
  --border-color: rgba(255, 255, 255, 0.1);
  --border-hover: rgba(59, 130, 246, 0.3);
}
```

### 4.2 Glass-panel 효과

```css
.glass-panel {
  background: rgba(15, 23, 42, 0.6);
  backdrop-filter: blur(20px);
  border: 1px solid rgba(255, 255, 255, 0.08);
  box-shadow: 0 25px 50px -12px rgba(0, 0, 0, 0.5);
}
```

### 4.3 애니메이션

```css
/* Fade In */
@keyframes fadeIn {
  0% {
    opacity: 0;
    transform: translateY(10px);
  }
  100% {
    opacity: 1;
    transform: translateY(0);
  }
}

.animate-fade-in {
  animation: fadeIn 0.3s ease-out forwards;
}

/* Hover Effects */
.hover-lift {
  transition: transform 0.3s ease, box-shadow 0.3s ease;
}

.hover-lift:hover {
  transform: translateY(-3px);
  box-shadow: 0 8px 16px rgba(0, 0, 0, 0.3);
}
```

### 4.4 타이포그래피

```css
/* Font Families */
body {
  font-family: 'Pretendard', 'Noto Sans KR', sans-serif;
}

.font-mono {
  font-family: 'Rajdhani', monospace;
}

/* Font Sizes */
.text-hero {
  font-size: 3rem; /* 48px */
  font-weight: 900;
}

.text-display {
  font-size: 2rem; /* 32px */
  font-weight: 700;
}

.text-heading {
  font-size: 1.5rem; /* 24px */
  font-weight: 600;
}

.text-body {
  font-size: 1rem; /* 16px */
  font-weight: 400;
}

.text-caption {
  font-size: 0.875rem; /* 14px */
  font-weight: 500;
}

.text-tiny {
  font-size: 0.75rem; /* 12px */
  font-weight: 400;
}
```

### 4.5 반응형 레이아웃

```css
/* Breakpoints */
/* Mobile: < 640px */
/* Tablet: 640px - 1024px */
/* Desktop: > 1024px */

@media (max-width: 640px) {
  .profile-summary {
    flex-direction: column;
    text-align: center;
  }

  .quick-stats {
    display: none;
  }

  .menu-grid {
    display: flex;
    overflow-x: auto;
    scroll-snap-type: x mandatory;
  }
}

@media (min-width: 1024px) {
  .menu-grid {
    display: grid;
    grid-template-columns: repeat(9, 1fr);
  }
}
```

---

## 5. 작업 체크리스트

### 5.1 Backend

- [ ] User 모델 확장 (level, points, membership_tier, kyc_verified, avatar_url)
- [ ] 마이그레이션 생성 및 적용
- [ ] GET /api/user/profile-summary/ 엔드포인트 개발
- [ ] 모달 관련 API 엔드포인트 개발

### 5.2 Frontend

- [ ] 프로필 요약 섹션 구현
- [ ] 9-그리드 메뉴 네비게이션 구현
- [ ] BaseModal.vue 공통 컴포넌트 생성
- [ ] 8개 모달 컴포넌트 개발
  - [ ] ModalPasswordChange.vue
  - [ ] ModalPhoneVerification.vue
  - [ ] ModalFaceAuth.vue
  - [ ] ModalQRCode.vue
  - [ ] Modal2FASetup.vue
  - [ ] ModalPINSetup.vue
  - [ ] ModalUpgrade.vue
  - [ ] ModalAddAddress.vue

### 5.3 디자인 시스템

- [ ] CSS 변수 정의 (색상, 폰트, 스페이싱)
- [ ] Glass-panel 믹스인 생성
- [ ] 애니메이션 키프레임 정의
- [ ] 반응형 브레이크포인트 설정

### 5.4 통합

- [ ] 탭별 컴포넌트와 메뉴 연동
- [ ] 모달 이벤트 핸들링
- [ ] 프로필 요약 데이터 실시간 업데이트
- [ ] 반응형 레이아웃 테스트 (모바일/태블릿/데스크톱)

---

## 6. 예상 작업 시간

- **Backend (User 모델 확장 + API):** 1-2시간
- **프로필 요약 섹션:** 2시간
- **9-그리드 메뉴 네비게이션:** 1시간
- **BaseModal + 8개 모달:** 4-6시간
- **디자인 시스템 정리:** 2시간
- **통합 및 테스트:** 2시간
- **총 예상:** 12-15시간

---

## 7. 완료 기준

1. ✅ 프로필 요약 섹션이 API 데이터 기반으로 표시
2. ✅ 9-그리드 메뉴가 반응형으로 동작 (모바일 가로 스크롤)
3. ✅ 모든 모달이 정상 작동 (열기/닫기/제출)
4. ✅ Glass-panel 및 애니메이션 효과 적용
5. ✅ 모바일/태블릿/데스크톱에서 레이아웃 확인

---

**다음 문서:** [최종 검증 체크리스트](./mypage_final_checklist.md)
