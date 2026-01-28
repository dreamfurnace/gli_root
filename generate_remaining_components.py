#!/usr/bin/env python3
"""
나머지 MyPage 컴포넌트 생성 스크립트
"""
import os

BASE_DIR = "gli_user-frontend/src"
COMPONENTS_DIR = f"{BASE_DIR}/components/mypage"

# ============================================================================
# 1. SecurityCenter.vue - 보안 설정
# ============================================================================
SECURITY_CENTER = '''<template>
  <div class="security-center">
    <h3 class="section-title">보안 설정</h3>

    <div class="security-items">
      <!-- 얼굴 인증 -->
      <div class="security-item glass-effect">
        <div class="item-info">
          <div class="item-icon">🔐</div>
          <div class="item-details">
            <h4>얼굴 인증</h4>
            <p>Face ID를 통한 생체 인증</p>
            <span class="status" :class="{ active: securityStatus.face_auth_enabled }">
              {{ securityStatus.face_auth_enabled ? '활성화됨' : '비활성화됨' }}
            </span>
          </div>
        </div>
        <button class="btn-toggle" @click="toggleFaceAuth">
          {{ securityStatus.face_auth_enabled ? '비활성화' : '활성화' }}
        </button>
      </div>

      <!-- 2FA -->
      <div class="security-item glass-effect">
        <div class="item-info">
          <div class="item-icon">📱</div>
          <div class="item-details">
            <h4>2단계 인증 (2FA)</h4>
            <p>OTP 앱을 통한 추가 보안</p>
            <span class="status" :class="{ active: securityStatus.two_fa_enabled }">
              {{ securityStatus.two_fa_enabled ? '활성화됨' : '비활성화됨' }}
            </span>
          </div>
        </div>
        <button class="btn-toggle" @click="show2FAModal = true">
          {{ securityStatus.two_fa_enabled ? '관리' : '설정' }}
        </button>
      </div>

      <!-- PIN -->
      <div class="security-item glass-effect">
        <div class="item-info">
          <div class="item-icon">🔢</div>
          <div class="item-details">
            <h4>PIN 번호</h4>
            <p>6자리 PIN을 통한 빠른 인증</p>
            <span class="status" :class="{ active: securityStatus.pin_enabled }">
              {{ securityStatus.pin_enabled ? '활성화됨' : '비활성화됨' }}
            </span>
          </div>
        </div>
        <button class="btn-toggle" @click="showPINModal = true">
          {{ securityStatus.pin_enabled ? '변경' : '설정' }}
        </button>
      </div>
    </div>

    <!-- 보안 레벨 -->
    <div class="security-level glass-effect">
      <h4>보안 레벨</h4>
      <div class="level-indicator">
        <div class="level-bar">
          <div class="level-fill" :style="{ width: (securityStatus.security_level / 3 * 100) + '%' }"></div>
        </div>
        <span class="level-text">레벨 {{ securityStatus.security_level }}/3</span>
      </div>
      <p class="level-description">
        {{ getSecurityLevelDescription() }}
      </p>
    </div>

    <!-- Modals -->
    <Modal2FASetup :show="show2FAModal" @close="show2FAModal = false" @success="fetchSecurityStatus" />
    <ModalPINSetup :show="showPINModal" @close="showPINModal = false" @success="fetchSecurityStatus" />
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import axios from 'axios'
import Modal2FASetup from '../modals/Modal2FASetup.vue'
import ModalPINSetup from '../modals/ModalPINSetup.vue'

const securityStatus = ref({
  face_auth_enabled: false,
  two_fa_enabled: false,
  pin_enabled: false,
  security_level: 1
})

const show2FAModal = ref(false)
const showPINModal = ref(false)

const fetchSecurityStatus = async () => {
  try {
    const response = await axios.get('/api/user/security/status/')
    securityStatus.value = response.data
  } catch (error) {
    console.error('보안 상태 조회 실패:', error)
  }
}

const toggleFaceAuth = () => {
  alert('얼굴 인증 기능은 향후 구현 예정입니다.')
}

const getSecurityLevelDescription = () => {
  const level = securityStatus.value.security_level
  if (level === 1) return '기본 보안: 추가 보안 설정을 권장합니다.'
  if (level === 2) return '중간 보안: 한 가지 추가 인증이 활성화되어 있습니다.'
  return '높은 보안: 여러 보안 인증이 활성화되어 있습니다.'
}

onMounted(() => {
  fetchSecurityStatus()
})
</script>

<style scoped>
.security-center {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
}

.section-title {
  color: #fff;
  font-size: 1.5rem;
  margin: 0;
}

.security-items {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.security-item {
  padding: 1.5rem;
  border-radius: 12px;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.glass-effect {
  background: rgba(15, 23, 42, 0.6);
  backdrop-filter: blur(10px);
  border: 1px solid rgba(59, 130, 246, 0.2);
}

.item-info {
  display: flex;
  align-items: center;
  gap: 1rem;
}

.item-icon {
  font-size: 2rem;
}

.item-details h4 {
  margin: 0 0 0.25rem 0;
  color: #fff;
  font-size: 1.125rem;
}

.item-details p {
  margin: 0 0 0.5rem 0;
  color: #94a3b8;
  font-size: 0.875rem;
}

.status {
  display: inline-block;
  padding: 0.25rem 0.75rem;
  border-radius: 12px;
  font-size: 0.75rem;
  background: rgba(148, 163, 184, 0.2);
  color: #94a3b8;
}

.status.active {
  background: rgba(16, 185, 129, 0.2);
  color: #10b981;
}

.btn-toggle {
  padding: 0.5rem 1.5rem;
  background: rgba(59, 130, 246, 0.2);
  color: #3b82f6;
  border: 1px solid rgba(59, 130, 246, 0.3);
  border-radius: 8px;
  cursor: pointer;
  font-weight: 600;
  transition: all 0.2s;
}

.btn-toggle:hover {
  background: rgba(59, 130, 246, 0.3);
}

.security-level {
  padding: 1.5rem;
  border-radius: 12px;
}

.security-level h4 {
  margin: 0 0 1rem 0;
  color: #fff;
}

.level-indicator {
  display: flex;
  align-items: center;
  gap: 1rem;
  margin-bottom: 0.75rem;
}

.level-bar {
  flex: 1;
  height: 8px;
  background: rgba(59, 130, 246, 0.2);
  border-radius: 4px;
  overflow: hidden;
}

.level-fill {
  height: 100%;
  background: linear-gradient(90deg, #3b82f6, #10b981);
  transition: width 0.3s ease;
}

.level-text {
  color: #3b82f6;
  font-weight: 600;
  white-space: nowrap;
}

.level-description {
  color: #94a3b8;
  font-size: 0.875rem;
  margin: 0;
}
</style>
'''

# ============================================================================
# 2. DashboardOverview.vue - 대시보드
# ============================================================================
DASHBOARD_OVERVIEW = '''<template>
  <div class="dashboard-overview">
    <h3 class="section-title">대시보드</h3>

    <!-- 토큰 잔액 -->
    <div class="token-balances">
      <div v-for="(balance, token) in balances" :key="token" class="balance-card glass-effect">
        <div class="token-icon">{{ getTokenIcon(token) }}</div>
        <div class="token-info">
          <h4>{{ token }}</h4>
          <p class="balance">{{ balance.balance.toFixed(2) }}</p>
          <p class="locked" v-if="balance.locked_balance > 0">
            잠김: {{ balance.locked_balance.toFixed(2) }}
          </p>
        </div>
      </div>
    </div>

    <!-- 프로젝트 목록 -->
    <div class="projects-section">
      <h4>활성 프로젝트</h4>
      <div class="projects-list">
        <div v-for="project in projects" :key="project.id" class="project-card glass-effect">
          <div class="project-header">
            <h5>{{ project.name }}</h5>
            <span class="project-status" :class="project.status">{{ project.status }}</span>
          </div>
          <div class="project-progress">
            <div class="progress-bar">
              <div class="progress-fill" :style="{ width: project.progress + '%' }"></div>
            </div>
            <span class="progress-text">{{ project.progress }}%</span>
          </div>
        </div>
      </div>
    </div>

    <!-- 토큰 교환 위젯 -->
    <SwapWidget @swap-success="fetchDashboardData" />
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import axios from 'axios'
import SwapWidget from './SwapWidget.vue'

const balances = ref({
  GLIB: { balance: 0, locked_balance: 0 },
  GLID: { balance: 0, locked_balance: 0 },
  GLIL: { balance: 0, locked_balance: 0 }
})

const projects = ref([])

const fetchDashboardData = async () => {
  try {
    const response = await axios.get('/api/user/dashboard/')
    balances.value = response.data.balances
    projects.value = response.data.projects
  } catch (error) {
    console.error('대시보드 데이터 조회 실패:', error)
  }
}

const getTokenIcon = (token) => {
  const icons = {
    GLIB: '💼',
    GLID: '💰',
    GLIL: '🎯'
  }
  return icons[token] || '🪙'
}

onMounted(() => {
  fetchDashboardData()
})
</script>

<style scoped>
.dashboard-overview {
  display: flex;
  flex-direction: column;
  gap: 2rem;
}

.section-title {
  color: #fff;
  font-size: 1.5rem;
  margin: 0;
}

.token-balances {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 1rem;
}

.balance-card {
  padding: 1.5rem;
  border-radius: 12px;
  display: flex;
  align-items: center;
  gap: 1rem;
}

.glass-effect {
  background: rgba(15, 23, 42, 0.6);
  backdrop-filter: blur(10px);
  border: 1px solid rgba(59, 130, 246, 0.2);
}

.token-icon {
  font-size: 2.5rem;
}

.token-info h4 {
  margin: 0;
  color: #fff;
  font-size: 1rem;
}

.token-info .balance {
  margin: 0.25rem 0 0 0;
  color: #3b82f6;
  font-size: 1.5rem;
  font-weight: 600;
}

.token-info .locked {
  margin: 0.25rem 0 0 0;
  color: #94a3b8;
  font-size: 0.75rem;
}

.projects-section h4 {
  color: #fff;
  margin: 0 0 1rem 0;
}

.projects-list {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.project-card {
  padding: 1rem;
  border-radius: 12px;
}

.project-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 0.75rem;
}

.project-header h5 {
  margin: 0;
  color: #fff;
  font-size: 1rem;
}

.project-status {
  padding: 0.25rem 0.75rem;
  border-radius: 12px;
  font-size: 0.75rem;
  background: rgba(59, 130, 246, 0.2);
  color: #3b82f6;
}

.project-progress {
  display: flex;
  align-items: center;
  gap: 1rem;
}

.progress-bar {
  flex: 1;
  height: 6px;
  background: rgba(59, 130, 246, 0.2);
  border-radius: 3px;
  overflow: hidden;
}

.progress-fill {
  height: 100%;
  background: linear-gradient(90deg, #3b82f6, #10b981);
  transition: width 0.3s ease;
}

.progress-text {
  color: #94a3b8;
  font-size: 0.875rem;
  white-space: nowrap;
}
</style>
'''

# ============================================================================
# 3. SwapWidget.vue - 토큰 교환
# ============================================================================
SWAP_WIDGET = '''<template>
  <div class="swap-widget glass-effect">
    <h4>토큰 교환</h4>

    <div class="swap-form">
      <!-- From Token -->
      <div class="swap-input-group">
        <label>보내는 토큰</label>
        <div class="input-container">
          <select v-model="fromToken" class="token-select">
            <option value="GLIB">GLIB</option>
            <option value="GLID">GLID</option>
            <option value="GLIL">GLIL</option>
          </select>
          <input
            v-model.number="amount"
            type="number"
            placeholder="0.00"
            class="amount-input"
            @input="calculateSwap"
          />
        </div>
      </div>

      <!-- Swap Icon -->
      <div class="swap-icon-container">
        <button class="btn-swap-direction" @click="swapDirection">
          <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <line x1="12" y1="5" x2="12" y2="19"></line>
            <polyline points="19 12 12 19 5 12"></polyline>
          </svg>
        </button>
      </div>

      <!-- To Token -->
      <div class="swap-input-group">
        <label>받는 토큰</label>
        <div class="input-container">
          <select v-model="toToken" class="token-select">
            <option value="GLIB">GLIB</option>
            <option value="GLID">GLID</option>
            <option value="GLIL">GLIL</option>
          </select>
          <input
            :value="estimatedAmount.toFixed(2)"
            type="text"
            readonly
            class="amount-input"
            placeholder="0.00"
          />
        </div>
      </div>

      <!-- Rate & Fee Info -->
      <div class="swap-info">
        <div class="info-row">
          <span>환율</span>
          <span class="value">1 {{ fromToken }} = {{ rate.toFixed(4) }} {{ toToken }}</span>
        </div>
        <div class="info-row">
          <span>수수료 (0.1%)</span>
          <span class="value">{{ fee.toFixed(4) }} {{ fromToken }}</span>
        </div>
      </div>

      <!-- Execute Button -->
      <button
        class="btn-execute"
        @click="executeSwap"
        :disabled="!canSwap"
      >
        {{ canSwap ? '교환하기' : '금액을 입력하세요' }}
      </button>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, watch, defineEmits } from 'vue'
import axios from 'axios'

const emit = defineEmits(['swap-success'])

const fromToken = ref('GLIB')
const toToken = ref('GLID')
const amount = ref(0)
const rate = ref(1.0)
const estimatedAmount = ref(0)
const fee = ref(0)

const canSwap = computed(() => {
  return amount.value > 0 && fromToken.value !== toToken.value
})

const fetchRate = async () => {
  try {
    const response = await axios.get('/api/user/swap/rate/', {
      params: {
        from: fromToken.value,
        to: toToken.value
      }
    })
    rate.value = response.data.rate
    calculateSwap()
  } catch (error) {
    console.error('환율 조회 실패:', error)
  }
}

const calculateSwap = () => {
  if (amount.value > 0) {
    fee.value = amount.value * 0.001
    estimatedAmount.value = (amount.value - fee.value) * rate.value
  } else {
    fee.value = 0
    estimatedAmount.value = 0
  }
}

const swapDirection = () => {
  const temp = fromToken.value
  fromToken.value = toToken.value
  toToken.value = temp
  fetchRate()
}

const executeSwap = async () => {
  if (!canSwap.value) return

  try {
    const response = await axios.post('/api/user/swap/execute/', {
      from_token: fromToken.value,
      to_token: toToken.value,
      amount: amount.value
    })

    if (response.data.success) {
      alert(`교환 완료! ${response.data.to_amount.toFixed(2)} ${toToken.value}를 받았습니다.`)
      amount.value = 0
      estimatedAmount.value = 0
      emit('swap-success')
    }
  } catch (error) {
    console.error('토큰 교환 실패:', error)
    alert('토큰 교환에 실패했습니다.')
  }
}

watch([fromToken, toToken], () => {
  fetchRate()
})

watch(amount, () => {
  calculateSwap()
})

// Initial fetch
fetchRate()
</script>

<style scoped>
.swap-widget {
  padding: 1.5rem;
  border-radius: 12px;
}

.glass-effect {
  background: rgba(15, 23, 42, 0.6);
  backdrop-filter: blur(10px);
  border: 1px solid rgba(59, 130, 246, 0.2);
}

.swap-widget h4 {
  margin: 0 0 1.5rem 0;
  color: #fff;
}

.swap-form {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.swap-input-group label {
  display: block;
  color: #94a3b8;
  font-size: 0.875rem;
  margin-bottom: 0.5rem;
}

.input-container {
  display: flex;
  gap: 0.75rem;
}

.token-select {
  padding: 0.75rem;
  background: rgba(15, 23, 42, 0.8);
  border: 1px solid rgba(59, 130, 246, 0.3);
  border-radius: 8px;
  color: #fff;
  font-weight: 600;
  cursor: pointer;
}

.amount-input {
  flex: 1;
  padding: 0.75rem;
  background: rgba(15, 23, 42, 0.8);
  border: 1px solid rgba(59, 130, 246, 0.3);
  border-radius: 8px;
  color: #fff;
  font-size: 1rem;
}

.amount-input:focus {
  outline: none;
  border-color: #3b82f6;
}

.amount-input[readonly] {
  background: rgba(15, 23, 42, 0.4);
  cursor: not-allowed;
}

.swap-icon-container {
  display: flex;
  justify-content: center;
  margin: 0.5rem 0;
}

.btn-swap-direction {
  width: 40px;
  height: 40px;
  background: rgba(59, 130, 246, 0.2);
  border: 1px solid rgba(59, 130, 246, 0.3);
  border-radius: 50%;
  color: #3b82f6;
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  transition: all 0.2s;
}

.btn-swap-direction:hover {
  background: rgba(59, 130, 246, 0.3);
  transform: rotate(180deg);
}

.swap-info {
  padding: 1rem;
  background: rgba(59, 130, 246, 0.1);
  border-radius: 8px;
  display: flex;
  flex-direction: column;
  gap: 0.5rem;
}

.info-row {
  display: flex;
  justify-content: space-between;
  color: #94a3b8;
  font-size: 0.875rem;
}

.info-row .value {
  color: #3b82f6;
  font-weight: 600;
}

.btn-execute {
  padding: 1rem;
  background: #3b82f6;
  color: white;
  border: none;
  border-radius: 8px;
  font-weight: 600;
  font-size: 1rem;
  cursor: pointer;
  transition: all 0.2s;
}

.btn-execute:hover:not(:disabled) {
  background: #2563eb;
}

.btn-execute:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}
</style>
'''

# ============================================================================
# 4. UsageHistory.vue - 이용 내역
# ============================================================================
USAGE_HISTORY = '''<template>
  <div class="usage-history">
    <h3 class="section-title">이용 내역</h3>

    <!-- 필터 -->
    <div class="filter-tabs">
      <button
        v-for="type in serviceTypes"
        :key="type.value"
        class="filter-tab"
        :class="{ active: selectedType === type.value }"
        @click="selectType(type.value)"
      >
        {{ type.label }}
      </button>
    </div>

    <!-- 내역 목록 -->
    <div class="history-list">
      <div v-if="loading" class="loading">로딩 중...</div>
      <div v-else-if="historyList.length === 0" class="empty">
        이용 내역이 없습니다.
      </div>
      <div
        v-else
        v-for="item in historyList"
        :key="item.id"
        class="history-item glass-effect"
        @click="viewReceipt(item.receipt_id)"
      >
        <div class="item-image" v-if="item.image_url">
          <img :src="item.image_url" :alt="item.title" />
        </div>
        <div class="item-content">
          <div class="item-header">
            <h4>{{ item.title }}</h4>
            <span class="service-badge">{{ item.service_type }}</span>
          </div>
          <p class="item-date">{{ formatDate(item.usage_date) }}</p>
          <div class="item-price">
            <span class="original">원가: ${{ item.original_price_usd.toFixed(2) }}</span>
            <span class="paid">결제: {{ item.paid_price_glil.toFixed(2) }} GLIL</span>
          </div>
        </div>
        <div class="item-arrow">›</div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import axios from 'axios'

const serviceTypes = [
  { value: 'ALL', label: '전체' },
  { value: 'GOLF', label: '골프' },
  { value: 'HOTEL', label: '호텔' },
  { value: 'OTHER', label: '기타' }
]

const selectedType = ref('ALL')
const historyList = ref([])
const loading = ref(false)

const fetchHistory = async () => {
  loading.value = true
  try {
    const response = await axios.get('/api/user/usage-history/', {
      params: { type: selectedType.value }
    })
    historyList.value = response.data
  } catch (error) {
    console.error('이용 내역 조회 실패:', error)
  } finally {
    loading.value = false
  }
}

const selectType = (type) => {
  selectedType.value = type
  fetchHistory()
}

const formatDate = (dateString) => {
  const date = new Date(dateString)
  return date.toLocaleDateString('ko-KR', {
    year: 'numeric',
    month: 'long',
    day: 'numeric'
  })
}

const viewReceipt = (receiptId) => {
  // TODO: 영수증 상세 모달 표시
  alert(`영수증 ID: ${receiptId}`)
}

onMounted(() => {
  fetchHistory()
})
</script>

<style scoped>
.usage-history {
  display: flex;
  flex-direction: column;
  gap: 1.5rem;
}

.section-title {
  color: #fff;
  font-size: 1.5rem;
  margin: 0;
}

.filter-tabs {
  display: flex;
  gap: 0.5rem;
  flex-wrap: wrap;
}

.filter-tab {
  padding: 0.5rem 1rem;
  background: rgba(15, 23, 42, 0.6);
  border: 1px solid rgba(59, 130, 246, 0.2);
  border-radius: 20px;
  color: #94a3b8;
  cursor: pointer;
  transition: all 0.2s;
}

.filter-tab:hover {
  background: rgba(59, 130, 246, 0.1);
  border-color: rgba(59, 130, 246, 0.3);
}

.filter-tab.active {
  background: rgba(59, 130, 246, 0.2);
  border-color: #3b82f6;
  color: #3b82f6;
  font-weight: 600;
}

.history-list {
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.loading, .empty {
  padding: 3rem;
  text-align: center;
  color: #94a3b8;
}

.history-item {
  padding: 1rem;
  border-radius: 12px;
  display: flex;
  align-items: center;
  gap: 1rem;
  cursor: pointer;
  transition: all 0.2s;
}

.glass-effect {
  background: rgba(15, 23, 42, 0.6);
  backdrop-filter: blur(10px);
  border: 1px solid rgba(59, 130, 246, 0.2);
}

.history-item:hover {
  background: rgba(59, 130, 246, 0.1);
  border-color: rgba(59, 130, 246, 0.3);
  transform: translateX(4px);
}

.item-image {
  width: 80px;
  height: 80px;
  border-radius: 8px;
  overflow: hidden;
  flex-shrink: 0;
}

.item-image img {
  width: 100%;
  height: 100%;
  object-fit: cover;
}

.item-content {
  flex: 1;
}

.item-header {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  margin-bottom: 0.5rem;
}

.item-header h4 {
  margin: 0;
  color: #fff;
  font-size: 1rem;
}

.service-badge {
  padding: 0.25rem 0.75rem;
  background: rgba(59, 130, 246, 0.2);
  color: #3b82f6;
  border-radius: 12px;
  font-size: 0.75rem;
  font-weight: 600;
}

.item-date {
  margin: 0 0 0.5rem 0;
  color: #94a3b8;
  font-size: 0.875rem;
}

.item-price {
  display: flex;
  gap: 1rem;
  font-size: 0.875rem;
}

.item-price .original {
  color: #64748b;
  text-decoration: line-through;
}

.item-price .paid {
  color: #10b981;
  font-weight: 600;
}

.item-arrow {
  color: #94a3b8;
  font-size: 1.5rem;
}
</style>
'''

# ============================================================================
# 파일 생성
# ============================================================================

def create_component_file(path, content):
    """컴포넌트 파일 생성"""
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f"✅ Created: {path}")

def main():
    print("=" * 60)
    print("나머지 MyPage 컴포넌트 생성 시작")
    print("=" * 60)
    print()

    components = [
        (f"{COMPONENTS_DIR}/sections/SecurityCenter.vue", SECURITY_CENTER),
        (f"{COMPONENTS_DIR}/sections/DashboardOverview.vue", DASHBOARD_OVERVIEW),
        (f"{COMPONENTS_DIR}/sections/SwapWidget.vue", SWAP_WIDGET),
        (f"{COMPONENTS_DIR}/sections/UsageHistory.vue", USAGE_HISTORY),
    ]

    for path, content in components:
        create_component_file(path, content)

    print()
    print("=" * 60)
    print("✅ 나머지 컴포넌트 생성 완료")
    print("=" * 60)
    print()
    print("생성된 컴포넌트:")
    print("  - SecurityCenter.vue (보안 설정)")
    print("  - DashboardOverview.vue (대시보드)")
    print("  - SwapWidget.vue (토큰 교환)")
    print("  - UsageHistory.vue (이용 내역)")
    print()

if __name__ == "__main__":
    main()
