# 탭 9: Wallet (입출금) - 상세 명세서

**작성일:** 2026-01-28
**특이사항:** 🔧 **기존 기능 + 신규 기능 추가**

---

## 1. 화면 분석 및 요구사항

### 1.1 기존 기능 (유지)
- ✅ 지갑 연결 상태
- ✅ 입금 섹션 (QR 코드, 주소 복사)
- ✅ 출금 섹션 (주소, 금액, 2FA)

### 1.2 신규 기능 (추가 필요)
- 🆕 **주소록 관리** (Address Book)
- 🆕 **네트워크 선택** (ERC-20, TRC-20)

---

## 2. DB 모델

### 2.1 WalletAddressBook 모델

```python
# gli_django/wallets/models.py

class WalletAddressBook(models.Model):
    NETWORK_CHOICES = [
        ('ERC20', 'ERC-20'),
        ('TRC20', 'TRC-20'),
        ('BEP20', 'BEP-20'),
    ]

    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='wallet_addresses')

    # 주소 정보
    name = models.CharField(max_length=100)  # "내 바이낸스 지갑"
    address = models.CharField(max_length=100)  # 0x... or T...
    network = models.CharField(max_length=20, choices=NETWORK_CHOICES)

    # 메타
    is_favorite = models.BooleanField(default=False)
    is_verified = models.BooleanField(default=False)  # 출금 테스트 성공 여부

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-is_favorite', '-created_at']
        unique_together = ['user', 'address', 'network']
        indexes = [
            models.Index(fields=['user', '-is_favorite']),
        ]

    def __str__(self):
        return f"{self.user.username} - {self.name} ({self.address[:8]}...)"
```

### 2.2 마이그레이션

```bash
python manage.py makemigrations wallets
python manage.py migrate wallets
```

---

## 3. API 엔드포인트

### 3.1 주소록 조회

```python
# GET /api/wallet/address-book/
# Response:
{
    "addresses": [
        {
            "id": 1,
            "name": "내 바이낸스 지갑",
            "address": "0x71C7656EC7ab88b098defB751B7401B5f6d8976F",
            "network": "ERC20",
            "is_favorite": true,
            "is_verified": true,
            "created_at": "2025-01-15T10:00:00Z"
        },
        {
            "id": 2,
            "name": "Tron 지갑",
            "address": "TRX7NqM77z1EYH7Epq67uP8b6P6D6mFtZF",
            "network": "TRC20",
            "is_favorite": false,
            "is_verified": false,
            "created_at": "2025-01-20T15:30:00Z"
        }
    ]
}
```

**구현:**

```python
# gli_django/wallets/views.py

from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from .models import WalletAddressBook

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_address_book(request):
    user = request.user

    addresses = WalletAddressBook.objects.filter(user=user)

    return Response({
        'addresses': [
            {
                'id': addr.id,
                'name': addr.name,
                'address': addr.address,
                'network': addr.network,
                'is_favorite': addr.is_favorite,
                'is_verified': addr.is_verified,
                'created_at': addr.created_at.isoformat()
            } for addr in addresses
        ]
    })
```

### 3.2 주소 추가

```python
# POST /api/wallet/address-book/
# Request:
{
    "name": "내 새 지갑",
    "address": "0x...",
    "network": "ERC20"
}
# Response:
{
    "success": true,
    "address_id": 3
}
```

**구현:**

```python
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def add_address(request):
    user = request.user
    name = request.data.get('name')
    address = request.data.get('address')
    network = request.data.get('network')

    # 유효성 검사
    if not name or not address or not network:
        return Response({'error': 'Missing fields'}, status=400)

    # 주소 형식 검증 (간단 버전)
    if network == 'ERC20' and not address.startswith('0x'):
        return Response({'error': 'Invalid ERC-20 address'}, status=400)
    if network == 'TRC20' and not address.startswith('T'):
        return Response({'error': 'Invalid TRC-20 address'}, status=400)

    # 중복 확인
    if WalletAddressBook.objects.filter(user=user, address=address, network=network).exists():
        return Response({'error': 'Address already exists'}, status=400)

    # 생성
    wallet_addr = WalletAddressBook.objects.create(
        user=user,
        name=name,
        address=address,
        network=network
    )

    return Response({
        'success': True,
        'address_id': wallet_addr.id
    })
```

### 3.3 주소 삭제

```python
# DELETE /api/wallet/address-book/{address_id}/
# Response:
{
    "success": true
}
```

**구현:**

```python
@api_view(['DELETE'])
@permission_classes([IsAuthenticated])
def delete_address(request, address_id):
    user = request.user

    try:
        address = WalletAddressBook.objects.get(id=address_id, user=user)
        address.delete()
        return Response({'success': True})
    except WalletAddressBook.DoesNotExist:
        return Response({'error': 'Address not found'}, status=404)
```

### 3.4 즐겨찾기 토글

```python
# PATCH /api/wallet/address-book/{address_id}/favorite/
# Response:
{
    "success": true,
    "is_favorite": true
}
```

### 3.5 URL 라우팅

```python
# gli_django/wallets/urls.py

from django.urls import path
from .views import (
    get_address_book,
    add_address,
    delete_address,
    toggle_favorite,
)

urlpatterns = [
    path('address-book/', get_address_book, name='address-book'),
    path('address-book/add/', add_address, name='add-address'),
    path('address-book/<int:address_id>/', delete_address, name='delete-address'),
    path('address-book/<int:address_id>/favorite/', toggle_favorite, name='toggle-favorite'),
]
```

---

## 4. Frontend 개발

### 4.1 기존 Wallet 섹션 확장

**파일 위치:** `gli_user-frontend/src/views/MyPageView.vue` (566-684 라인)

**추가 사항:**

```vue
<template>
  <section v-show="activeTab === 'wallet'" class="tab-panel">
    <div class="panel-container">
      <h2 class="panel-title">
        <span class="panel-emoji">💳</span>
        {{ $t("mypage.wallet.title") }}
      </h2>

      <div class="wallet-actions">
        <!-- 지갑 연결 상태 (기존) -->
        <div class="wallet-status">
          <!-- 기존 코드 유지 -->
        </div>

        <!-- 네트워크 선택 (신규) -->
        <div v-if="isWalletConnected" class="network-selection">
          <label>네트워크 선택</label>
          <select v-model="selectedNetwork" class="network-select">
            <option value="ERC20">ERC-20 (Ethereum)</option>
            <option value="TRC20">TRC-20 (Tron)</option>
            <option value="BEP20">BEP-20 (Binance)</option>
          </select>
        </div>

        <!-- 입출금 폼 (기존) -->
        <div v-if="isWalletConnected" class="wallet-forms">
          <!-- 입금 폼 (기존 유지) -->
          <div class="wallet-form">
            <!-- ... -->
          </div>

          <!-- 출금 폼 (확장) -->
          <div class="wallet-form">
            <h3 class="form-title">{{ $t("mypage.wallet.withdrawal") }}</h3>

            <!-- 주소록에서 선택 (신규) -->
            <div class="form-group">
              <label class="form-label">저장된 주소</label>
              <select v-model="selectedAddress" class="form-select" @change="onAddressSelect">
                <option value="">직접 입력</option>
                <option v-for="addr in addressBook" :key="addr.id" :value="addr.address">
                  {{ addr.name }} ({{ formatAddress(addr.address) }})
                  <span v-if="addr.is_favorite">⭐</span>
                </option>
              </select>
            </div>

            <!-- 주소 입력 (기존) -->
            <div class="form-group">
              <label class="form-label">{{ $t("mypage.wallet.toAddress") }}</label>
              <input
                v-model="withdrawalForm.toAddress"
                type="text"
                class="form-input"
                :placeholder="$t('mypage.wallet.enterAddress')"
              />
              <button
                v-if="withdrawalForm.toAddress && !isAddressInBook(withdrawalForm.toAddress)"
                class="btn-add-to-book"
                @click="openAddAddressModal"
              >
                <i class="ph-bold ph-bookmark"></i>
                주소록에 추가
              </button>
            </div>

            <!-- 나머지 출금 폼 (기존 유지) -->
            <!-- ... -->
          </div>
        </div>

        <!-- 주소록 관리 섹션 (신규) -->
        <div v-if="isWalletConnected" class="address-book-section">
          <h3 class="section-title">
            <i class="ph-duotone ph-address-book"></i>
            주소록 관리
          </h3>

          <button class="btn-add-address" @click="openAddAddressModal">
            <i class="ph-bold ph-plus"></i>
            새 주소 추가
          </button>

          <div class="address-list">
            <div
              v-for="addr in addressBook"
              :key="addr.id"
              class="address-item"
            >
              <div class="address-info">
                <div class="address-header">
                  <span class="address-name">{{ addr.name }}</span>
                  <span class="network-badge" :class="addr.network.toLowerCase()">
                    {{ addr.network }}
                  </span>
                  <button
                    class="btn-favorite"
                    :class="{ active: addr.is_favorite }"
                    @click="toggleFavorite(addr.id)"
                  >
                    <i :class="addr.is_favorite ? 'ph-fill' : 'ph-bold'" class="ph-star"></i>
                  </button>
                </div>
                <div class="address-value">
                  <code>{{ addr.address }}</code>
                  <button class="btn-copy-sm" @click="copyAddress(addr.address)">
                    <i class="ph-bold ph-copy"></i>
                  </button>
                </div>
              </div>
              <div class="address-actions">
                <button class="btn-use" @click="useAddress(addr.address)">
                  사용
                </button>
                <button class="btn-delete" @click="deleteAddress(addr.id)">
                  삭제
                </button>
              </div>
            </div>

            <div v-if="addressBook.length === 0" class="empty-address-book">
              <i class="ph-duotone ph-address-book"></i>
              <p>저장된 주소가 없습니다</p>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- 주소 추가 모달 -->
    <AddAddressModal
      :show="showAddAddressModal"
      :initialAddress="withdrawalForm.toAddress"
      @close="showAddAddressModal = false"
      @add="handleAddAddress"
    />
  </section>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue';
import { api } from '@/services/api';
import AddAddressModal from '@/components/wallet/AddAddressModal.vue';

const selectedNetwork = ref('ERC20');
const addressBook = ref([]);
const selectedAddress = ref('');
const showAddAddressModal = ref(false);

const fetchAddressBook = async () => {
  try {
    const response = await api.get('/api/wallet/address-book/');
    addressBook.value = response.data.addresses;
  } catch (error) {
    console.error('Failed to fetch address book:', error);
  }
};

const onAddressSelect = () => {
  if (selectedAddress.value) {
    withdrawalForm.value.toAddress = selectedAddress.value;
  }
};

const isAddressInBook = (address: string) => {
  return addressBook.value.some(addr => addr.address === address);
};

const openAddAddressModal = () => {
  showAddAddressModal.value = true;
};

const handleAddAddress = async (name: string, address: string, network: string) => {
  try {
    await api.post('/api/wallet/address-book/add/', { name, address, network });
    await fetchAddressBook();
    showAddAddressModal.value = false;
    alert('주소가 추가되었습니다!');
  } catch (error) {
    console.error('Failed to add address:', error);
    alert('주소 추가 실패: ' + (error.response?.data?.error || error.message));
  }
};

const deleteAddress = async (addressId: number) => {
  if (!confirm('이 주소를 삭제하시겠습니까?')) return;

  try {
    await api.delete(`/api/wallet/address-book/${addressId}/`);
    await fetchAddressBook();
    alert('주소가 삭제되었습니다.');
  } catch (error) {
    console.error('Failed to delete address:', error);
  }
};

const toggleFavorite = async (addressId: number) => {
  try {
    await api.patch(`/api/wallet/address-book/${addressId}/favorite/`);
    await fetchAddressBook();
  } catch (error) {
    console.error('Failed to toggle favorite:', error);
  }
};

const useAddress = (address: string) => {
  withdrawalForm.value.toAddress = address;
  alert('주소가 적용되었습니다!');
};

const copyAddress = async (address: string) => {
  await navigator.clipboard.writeText(address);
  alert('주소가 복사되었습니다!');
};

const formatAddress = (address: string) => {
  return `${address.slice(0, 6)}...${address.slice(-4)}`;
};

onMounted(() => {
  if (isWalletConnected.value) {
    fetchAddressBook();
  }
});
</script>

<style scoped>
/* 네트워크 선택 */
.network-selection {
  padding: 1.5rem;
  background: var(--bg-secondary);
  border-radius: 12px;
  margin-bottom: 2rem;
}

.network-select {
  width: 100%;
  padding: 0.75rem;
  border: 1px solid var(--border-color);
  border-radius: 8px;
  background: var(--bg-primary);
  color: var(--text-primary);
}

/* 주소록 섹션 */
.address-book-section {
  margin-top: 3rem;
  padding: 2rem;
  background: var(--bg-secondary);
  border-radius: 16px;
}

.section-title {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  font-size: 1.3rem;
  margin-bottom: 1.5rem;
}

.btn-add-address {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.75rem 1.5rem;
  background: var(--gli-blue);
  color: white;
  border: none;
  border-radius: 8px;
  font-weight: 600;
  cursor: pointer;
  margin-bottom: 1.5rem;
}

/* 주소 리스트 */
.address-list {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.address-item {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1.5rem;
  background: var(--bg-primary);
  border-radius: 12px;
  border: 1px solid var(--border-color);
  transition: all 0.3s;
}

.address-item:hover {
  border-color: var(--gli-blue);
  box-shadow: 0 2px 8px rgba(59, 130, 246, 0.2);
}

.address-info {
  flex: 1;
}

.address-header {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  margin-bottom: 0.75rem;
}

.address-name {
  font-weight: 600;
  color: var(--text-primary);
}

.network-badge {
  padding: 0.25rem 0.75rem;
  border-radius: 12px;
  font-size: 0.75rem;
  font-weight: 600;
}

.network-badge.erc20 {
  background: var(--gli-blue);
  color: white;
}

.network-badge.trc20 {
  background: var(--gli-orange);
  color: white;
}

.btn-favorite {
  background: none;
  border: none;
  font-size: 1.2rem;
  cursor: pointer;
  color: var(--text-secondary);
}

.btn-favorite.active {
  color: var(--gli-gold);
}

.address-value {
  display: flex;
  align-items: center;
  gap: 0.5rem;
}

.address-value code {
  font-family: 'Courier New', monospace;
  color: var(--text-secondary);
  font-size: 0.9rem;
}

.address-actions {
  display: flex;
  gap: 0.5rem;
}

.btn-use,
.btn-delete {
  padding: 0.5rem 1rem;
  border: none;
  border-radius: 8px;
  font-weight: 600;
  cursor: pointer;
  transition: all 0.3s;
}

.btn-use {
  background: var(--gli-green);
  color: white;
}

.btn-delete {
  background: var(--gli-orange);
  color: white;
}

.empty-address-book {
  text-align: center;
  padding: 2rem;
  color: var(--text-secondary);
}
</style>
```

### 4.2 AddAddressModal 컴포넌트

**파일:** `gli_user-frontend/src/components/wallet/AddAddressModal.vue`

```vue
<template>
  <div v-if="show" class="modal-overlay" @click="$emit('close')">
    <div class="modal-content" @click.stop>
      <div class="modal-header">
        <h3>주소 추가</h3>
        <button class="modal-close" @click="$emit('close')">×</button>
      </div>
      <div class="modal-body">
        <div class="form-group">
          <label>이름</label>
          <input
            v-model="name"
            type="text"
            placeholder="예: 내 바이낸스 지갑"
            class="form-input"
          />
        </div>

        <div class="form-group">
          <label>주소</label>
          <input
            v-model="address"
            type="text"
            placeholder="0x... 또는 T..."
            class="form-input"
          />
        </div>

        <div class="form-group">
          <label>네트워크</label>
          <select v-model="network" class="form-select">
            <option value="ERC20">ERC-20 (Ethereum)</option>
            <option value="TRC20">TRC-20 (Tron)</option>
            <option value="BEP20">BEP-20 (Binance)</option>
          </select>
        </div>

        <div class="modal-actions">
          <button class="btn-cancel" @click="$emit('close')">취소</button>
          <button class="btn-submit" @click="submit" :disabled="!isValid">추가</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed } from 'vue';

const props = defineProps<{
  show: boolean;
  initialAddress?: string;
}>();

const emit = defineEmits(['close', 'add']);

const name = ref('');
const address = ref(props.initialAddress || '');
const network = ref('ERC20');

const isValid = computed(() => {
  return name.value.trim() && address.value.trim();
});

const submit = () => {
  if (isValid.value) {
    emit('add', name.value, address.value, network.value);
  }
};
</script>
```

---

## 5. 요약

- ✅ 기존 입출금 기능 유지
- ✅ 주소록 관리 추가 (CRUD)
- ✅ 네트워크 선택 추가
- ✅ DB 모델: WalletAddressBook
- ✅ API 4개: 조회, 추가, 삭제, 즐겨찾기
- ⏱️ 예상 시간: 4-5시간

---

**다음 문서:** [공통 작업](./mypage_spec_common.md)
