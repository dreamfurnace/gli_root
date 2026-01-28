#!/usr/bin/env python3
"""
MyPage Vue 컴포넌트 자동 생성 스크립트
Phase 3: Frontend Component Generation
"""
import os

# 기본 경로
BASE_DIR = "gli_user-frontend/src"
COMPONENTS_DIR = f"{BASE_DIR}/components/mypage"
VIEWS_DIR = f"{BASE_DIR}/views"

# ============================================================================
# 1. BaseModal.vue - 공통 모달 컴포넌트
# ============================================================================
BASE_MODAL = '''<template>
  <Transition name="modal">
    <div v-if="show" class="modal-mask" @click.self="closeModal">
      <div class="modal-container glass-effect">
        <div class="modal-header">
          <h3>{{ title }}</h3>
          <button class="btn-close" @click="closeModal">
            <svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
              <line x1="18" y1="6" x2="6" y2="18"></line>
              <line x1="6" y1="6" x2="18" y2="18"></line>
            </svg>
          </button>
        </div>
        <div class="modal-body">
          <slot></slot>
        </div>
        <div class="modal-footer" v-if="$slots.footer">
          <slot name="footer"></slot>
        </div>
      </div>
    </div>
  </Transition>
</template>

<script setup>
import { defineProps, defineEmits } from 'vue'

const props = defineProps({
  show: Boolean,
  title: String
})

const emit = defineEmits(['close'])

const closeModal = () => {
  emit('close')
}
</script>

<style scoped>
.modal-mask {
  position: fixed;
  z-index: 9998;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  background-color: rgba(0, 0, 0, 0.7);
  display: flex;
  align-items: center;
  justify-content: center;
  transition: opacity 0.3s ease;
}

.modal-container {
  max-width: 500px;
  width: 90%;
  max-height: 90vh;
  overflow-y: auto;
  border-radius: 16px;
  box-shadow: 0 20px 60px rgba(0, 0, 0, 0.5);
  transition: all 0.3s ease;
}

.glass-effect {
  background: rgba(15, 23, 42, 0.95);
  backdrop-filter: blur(20px);
  border: 1px solid rgba(59, 130, 246, 0.2);
}

.modal-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  padding: 1.5rem;
  border-bottom: 1px solid rgba(59, 130, 246, 0.2);
}

.modal-header h3 {
  margin: 0;
  color: #fff;
  font-size: 1.25rem;
}

.btn-close {
  background: none;
  border: none;
  color: #94a3b8;
  cursor: pointer;
  padding: 0.25rem;
  transition: color 0.2s;
}

.btn-close:hover {
  color: #3b82f6;
}

.modal-body {
  padding: 1.5rem;
  color: #e2e8f0;
}

.modal-footer {
  padding: 1rem 1.5rem;
  border-top: 1px solid rgba(59, 130, 246, 0.2);
  display: flex;
  justify-content: flex-end;
  gap: 0.75rem;
}

.modal-enter-from,
.modal-leave-to {
  opacity: 0;
}

.modal-enter-active,
.modal-leave-active {
  transition: opacity 0.3s ease;
}

.modal-enter-from .modal-container,
.modal-leave-to .modal-container {
  transform: scale(0.9);
}
</style>
'''

# ============================================================================
# 2. ProfileSummary.vue - 프로필 요약 섹션
# ============================================================================
PROFILE_SUMMARY = '''<template>
  <div class="profile-summary glass-effect">
    <div class="profile-avatar">
      <img :src="profileData.avatar_url" :alt="profileData.username" />
    </div>
    <div class="profile-info">
      <h2>{{ profileData.username }}</h2>
      <p class="email">{{ profileData.email }}</p>
      <div class="membership-badge" :class="profileData.membership_tier">
        {{ profileData.membership_display }}
      </div>
    </div>
    <div class="profile-stats">
      <div class="stat-item">
        <span class="stat-label">레벨</span>
        <span class="stat-value">{{ profileData.level }}</span>
      </div>
      <div class="stat-item">
        <span class="stat-label">포인트</span>
        <span class="stat-value">{{ profileData.points?.toLocaleString() }}</span>
      </div>
      <div class="stat-item">
        <span class="stat-label">총 자산 (GLIB)</span>
        <span class="stat-value">{{ profileData.total_assets_glib?.toFixed(2) }}</span>
      </div>
    </div>
    <div class="kyc-status" v-if="profileData.kyc_verified">
      <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <polyline points="20 6 9 17 4 12"></polyline>
      </svg>
      KYC 인증 완료
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import axios from 'axios'

const profileData = ref({
  avatar_url: '',
  username: '',
  email: '',
  level: 1,
  points: 0,
  membership_tier: 'BASIC',
  membership_display: 'Basic',
  kyc_verified: false,
  total_assets_glib: 0
})

const fetchProfileSummary = async () => {
  try {
    const response = await axios.get('/api/user/profile-summary/')
    profileData.value = response.data
  } catch (error) {
    console.error('프로필 요약 조회 실패:', error)
  }
}

onMounted(() => {
  fetchProfileSummary()
})
</script>

<style scoped>
.profile-summary {
  padding: 2rem;
  border-radius: 16px;
  margin-bottom: 2rem;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 1rem;
}

.glass-effect {
  background: rgba(15, 23, 42, 0.8);
  backdrop-filter: blur(20px);
  border: 1px solid rgba(59, 130, 246, 0.2);
}

.profile-avatar img {
  width: 100px;
  height: 100px;
  border-radius: 50%;
  border: 3px solid #3b82f6;
}

.profile-info {
  text-align: center;
}

.profile-info h2 {
  margin: 0;
  color: #fff;
  font-size: 1.5rem;
}

.profile-info .email {
  color: #94a3b8;
  margin: 0.25rem 0 0.5rem;
}

.membership-badge {
  display: inline-block;
  padding: 0.25rem 1rem;
  border-radius: 20px;
  font-size: 0.875rem;
  font-weight: 600;
}

.membership-badge.BASIC {
  background: rgba(148, 163, 184, 0.2);
  color: #94a3b8;
}

.membership-badge.SILVER {
  background: rgba(192, 192, 192, 0.2);
  color: #c0c0c0;
}

.membership-badge.GOLD {
  background: rgba(255, 215, 0, 0.2);
  color: #ffd700;
}

.membership-badge.PLATINUM {
  background: rgba(229, 228, 226, 0.2);
  color: #e5e4e2;
}

.profile-stats {
  display: flex;
  gap: 2rem;
  margin-top: 1rem;
}

.stat-item {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 0.25rem;
}

.stat-label {
  color: #94a3b8;
  font-size: 0.875rem;
}

.stat-value {
  color: #3b82f6;
  font-size: 1.25rem;
  font-weight: 600;
}

.kyc-status {
  display: flex;
  align-items: center;
  gap: 0.5rem;
  color: #10b981;
  font-size: 0.875rem;
}
</style>
'''

# ============================================================================
# 3. MenuNavigation.vue - 9그리드 메뉴
# ============================================================================
MENU_NAVIGATION = '''<template>
  <div class="menu-navigation">
    <div class="menu-grid">
      <div
        v-for="menu in menuItems"
        :key="menu.id"
        class="menu-item glass-effect"
        :class="{ active: currentTab === menu.id }"
        @click="selectMenu(menu.id)"
      >
        <div class="menu-icon">
          <component :is="menu.icon" />
        </div>
        <span class="menu-label">{{ menu.label }}</span>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, defineEmits } from 'vue'

const emit = defineEmits(['tab-change'])

const currentTab = ref('profile')

const menuItems = [
  { id: 'profile', label: 'Profile', icon: 'IconUser' },
  { id: 'security', label: 'Security', icon: 'IconShield' },
  { id: 'referral', label: 'Referral', icon: 'IconUsers' },
  { id: 'dashboard', label: 'Dashboard', icon: 'IconDashboard' },
  { id: 'portfolio', label: 'Portfolio', icon: 'IconBriefcase' },
  { id: 'service', label: 'Service', icon: 'IconSettings' },
  { id: 'usage', label: 'Usage', icon: 'IconHistory' },
  { id: 'notice', label: 'Notice', icon: 'IconBell' },
  { id: 'wallet', label: 'Wallet', icon: 'IconWallet' }
]

const selectMenu = (menuId) => {
  currentTab.value = menuId
  emit('tab-change', menuId)
}
</script>

<style scoped>
.menu-navigation {
  margin-bottom: 2rem;
}

.menu-grid {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 1rem;
}

.menu-item {
  padding: 1.5rem 1rem;
  border-radius: 12px;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 0.75rem;
  cursor: pointer;
  transition: all 0.3s ease;
  border: 2px solid transparent;
}

.glass-effect {
  background: rgba(15, 23, 42, 0.6);
  backdrop-filter: blur(10px);
}

.menu-item:hover {
  background: rgba(59, 130, 246, 0.1);
  border-color: rgba(59, 130, 246, 0.3);
  transform: translateY(-2px);
}

.menu-item.active {
  background: rgba(59, 130, 246, 0.2);
  border-color: #3b82f6;
}

.menu-icon {
  font-size: 2rem;
  color: #3b82f6;
}

.menu-label {
  color: #e2e8f0;
  font-size: 0.875rem;
  font-weight: 500;
}

@media (max-width: 768px) {
  .menu-grid {
    grid-template-columns: repeat(2, 1fr);
  }
}
</style>
'''

# ============================================================================
# 4. Modal2FASetup.vue - 2FA 설정 모달
# ============================================================================
MODAL_2FA_SETUP = '''<template>
  <BaseModal :show="show" title="2단계 인증 (2FA) 설정" @close="closeModal">
    <div class="modal-2fa-setup">
      <div v-if="step === 1" class="setup-step">
        <p class="instruction">
          Google Authenticator 또는 Authy 앱을 사용하여<br>
          아래 QR 코드를 스캔하세요.
        </p>
        <div class="qr-code-container">
          <img v-if="qrCode" :src="qrCode" alt="2FA QR Code" />
          <div v-else class="loading">QR 코드 생성 중...</div>
        </div>
        <div class="secret-key">
          <p class="label">수동 입력 키:</p>
          <code>{{ secret }}</code>
        </div>
        <button class="btn-primary" @click="step = 2">다음</button>
      </div>

      <div v-if="step === 2" class="setup-step">
        <p class="instruction">
          앱에 표시된 6자리 인증 코드를 입력하세요.
        </p>
        <input
          v-model="verificationCode"
          type="text"
          maxlength="6"
          placeholder="000000"
          class="input-code"
          @keyup.enter="verify2FA"
        />
        <div class="error-message" v-if="errorMessage">
          {{ errorMessage }}
        </div>
        <div class="button-group">
          <button class="btn-secondary" @click="step = 1">이전</button>
          <button class="btn-primary" @click="verify2FA">확인</button>
        </div>
      </div>

      <div v-if="step === 3" class="setup-step success">
        <svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"></path>
          <polyline points="22 4 12 14.01 9 11.01"></polyline>
        </svg>
        <h3>2FA 설정 완료!</h3>
        <p>이제 로그인 시 2단계 인증이 요구됩니다.</p>
        <button class="btn-primary" @click="closeModal">확인</button>
      </div>
    </div>
  </BaseModal>
</template>

<script setup>
import { ref, watch, defineProps, defineEmits } from 'vue'
import axios from 'axios'
import BaseModal from './BaseModal.vue'

const props = defineProps({
  show: Boolean
})

const emit = defineEmits(['close', 'success'])

const step = ref(1)
const qrCode = ref('')
const secret = ref('')
const verificationCode = ref('')
const errorMessage = ref('')

const setup2FA = async () => {
  try {
    const response = await axios.post('/api/user/security/2fa/setup/')
    qrCode.value = response.data.qr_code
    secret.value = response.data.secret
  } catch (error) {
    console.error('2FA 설정 실패:', error)
  }
}

const verify2FA = async () => {
  errorMessage.value = ''
  try {
    const response = await axios.post('/api/user/security/2fa/verify/', {
      code: verificationCode.value
    })
    if (response.data.success) {
      step.value = 3
      setTimeout(() => {
        emit('success')
        closeModal()
      }, 2000)
    }
  } catch (error) {
    errorMessage.value = error.response?.data?.error || '인증 코드가 올바르지 않습니다.'
  }
}

const closeModal = () => {
  step.value = 1
  verificationCode.value = ''
  errorMessage.value = ''
  emit('close')
}

watch(() => props.show, (newVal) => {
  if (newVal && step.value === 1) {
    setup2FA()
  }
})
</script>

<style scoped>
.modal-2fa-setup {
  min-height: 300px;
}

.setup-step {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 1.5rem;
}

.instruction {
  text-align: center;
  color: #94a3b8;
  line-height: 1.6;
}

.qr-code-container {
  background: white;
  padding: 1rem;
  border-radius: 12px;
}

.qr-code-container img {
  display: block;
  max-width: 200px;
}

.loading {
  width: 200px;
  height: 200px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #64748b;
}

.secret-key {
  text-align: center;
}

.secret-key .label {
  color: #94a3b8;
  font-size: 0.875rem;
  margin-bottom: 0.5rem;
}

.secret-key code {
  background: rgba(59, 130, 246, 0.1);
  color: #3b82f6;
  padding: 0.5rem 1rem;
  border-radius: 8px;
  font-family: monospace;
  font-size: 1rem;
  letter-spacing: 0.1em;
}

.input-code {
  width: 200px;
  padding: 1rem;
  font-size: 1.5rem;
  text-align: center;
  letter-spacing: 0.5em;
  background: rgba(15, 23, 42, 0.6);
  border: 2px solid rgba(59, 130, 246, 0.3);
  border-radius: 8px;
  color: #fff;
  font-family: monospace;
}

.input-code:focus {
  outline: none;
  border-color: #3b82f6;
}

.error-message {
  color: #ef4444;
  font-size: 0.875rem;
}

.button-group {
  display: flex;
  gap: 1rem;
}

.btn-primary, .btn-secondary {
  padding: 0.75rem 2rem;
  border-radius: 8px;
  border: none;
  cursor: pointer;
  font-weight: 600;
  transition: all 0.2s;
}

.btn-primary {
  background: #3b82f6;
  color: white;
}

.btn-primary:hover {
  background: #2563eb;
}

.btn-secondary {
  background: rgba(148, 163, 184, 0.2);
  color: #94a3b8;
}

.btn-secondary:hover {
  background: rgba(148, 163, 184, 0.3);
}

.setup-step.success {
  padding: 2rem 0;
}

.setup-step.success svg {
  color: #10b981;
}

.setup-step.success h3 {
  color: #fff;
  margin: 0;
}

.setup-step.success p {
  color: #94a3b8;
  margin: 0;
}
</style>
'''

# ============================================================================
# 5. ModalPINSetup.vue - PIN 설정 모달
# ============================================================================
MODAL_PIN_SETUP = '''<template>
  <BaseModal :show="show" title="PIN 번호 설정" @close="closeModal">
    <div class="modal-pin-setup">
      <p class="instruction">6자리 PIN 번호를 입력하세요</p>

      <input
        v-model="pin"
        type="password"
        maxlength="6"
        placeholder="000000"
        class="input-pin"
        @input="validatePIN"
      />

      <div class="error-message" v-if="errorMessage">
        {{ errorMessage }}
      </div>

      <div class="success-message" v-if="successMessage">
        {{ successMessage }}
      </div>

      <button
        class="btn-primary"
        @click="setPIN"
        :disabled="pin.length !== 6"
      >
        설정 완료
      </button>
    </div>
  </BaseModal>
</template>

<script setup>
import { ref, defineProps, defineEmits } from 'vue'
import axios from 'axios'
import BaseModal from './BaseModal.vue'

const props = defineProps({
  show: Boolean
})

const emit = defineEmits(['close', 'success'])

const pin = ref('')
const errorMessage = ref('')
const successMessage = ref('')

const validatePIN = () => {
  errorMessage.value = ''
  if (pin.value && !/^\d+$/.test(pin.value)) {
    errorMessage.value = '숫자만 입력 가능합니다.'
  }
}

const setPIN = async () => {
  if (pin.value.length !== 6) {
    errorMessage.value = 'PIN은 6자리여야 합니다.'
    return
  }

  try {
    const response = await axios.post('/api/user/security/pin/set/', {
      pin: pin.value
    })
    if (response.data.success) {
      successMessage.value = 'PIN 설정이 완료되었습니다.'
      setTimeout(() => {
        emit('success')
        closeModal()
      }, 1500)
    }
  } catch (error) {
    errorMessage.value = error.response?.data?.error || 'PIN 설정에 실패했습니다.'
  }
}

const closeModal = () => {
  pin.value = ''
  errorMessage.value = ''
  successMessage.value = ''
  emit('close')
}
</script>

<style scoped>
.modal-pin-setup {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 1.5rem;
  padding: 1rem 0;
}

.instruction {
  color: #94a3b8;
  text-align: center;
}

.input-pin {
  width: 200px;
  padding: 1rem;
  font-size: 1.5rem;
  text-align: center;
  letter-spacing: 0.5em;
  background: rgba(15, 23, 42, 0.6);
  border: 2px solid rgba(59, 130, 246, 0.3);
  border-radius: 8px;
  color: #fff;
  font-family: monospace;
}

.input-pin:focus {
  outline: none;
  border-color: #3b82f6;
}

.error-message {
  color: #ef4444;
  font-size: 0.875rem;
}

.success-message {
  color: #10b981;
  font-size: 0.875rem;
}

.btn-primary {
  padding: 0.75rem 2rem;
  background: #3b82f6;
  color: white;
  border: none;
  border-radius: 8px;
  cursor: pointer;
  font-weight: 600;
  transition: all 0.2s;
}

.btn-primary:hover:not(:disabled) {
  background: #2563eb;
}

.btn-primary:disabled {
  opacity: 0.5;
  cursor: not-allowed;
}
</style>
'''

# ============================================================================
# 6. ModalQRCode.vue - QR 코드 표시 모달
# ============================================================================
MODAL_QR_CODE = '''<template>
  <BaseModal :show="show" title="추천 QR 코드" @close="closeModal">
    <div class="modal-qr-code">
      <p class="instruction">
        아래 QR 코드를 스캔하여 친구를 초대하세요
      </p>

      <div class="qr-code-container">
        <img v-if="qrCodeData" :src="qrCodeData" alt="Referral QR Code" />
        <div v-else class="loading">QR 코드 생성 중...</div>
      </div>

      <div class="referral-info">
        <div class="info-item">
          <span class="label">추천 코드:</span>
          <span class="value">{{ referralCode }}</span>
          <button class="btn-copy" @click="copyToClipboard(referralCode)">
            복사
          </button>
        </div>
        <div class="info-item">
          <span class="label">추천 링크:</span>
          <span class="value small">{{ referralUrl }}</span>
          <button class="btn-copy" @click="copyToClipboard(referralUrl)">
            복사
          </button>
        </div>
      </div>

      <button class="btn-primary" @click="closeModal">닫기</button>
    </div>
  </BaseModal>
</template>

<script setup>
import { ref, watch, defineProps, defineEmits } from 'vue'
import axios from 'axios'
import BaseModal from './BaseModal.vue'

const props = defineProps({
  show: Boolean
})

const emit = defineEmits(['close'])

const qrCodeData = ref('')
const referralCode = ref('')
const referralUrl = ref('')

const fetchQRCode = async () => {
  try {
    const response = await axios.get('/api/user/referral/qr-code/')
    qrCodeData.value = response.data.qr_code
    referralCode.value = response.data.referral_code
    referralUrl.value = response.data.referral_url
  } catch (error) {
    console.error('QR 코드 조회 실패:', error)
  }
}

const copyToClipboard = async (text) => {
  try {
    await navigator.clipboard.writeText(text)
    alert('클립보드에 복사되었습니다.')
  } catch (error) {
    console.error('복사 실패:', error)
  }
}

const closeModal = () => {
  emit('close')
}

watch(() => props.show, (newVal) => {
  if (newVal) {
    fetchQRCode()
  }
})
</script>

<style scoped>
.modal-qr-code {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 1.5rem;
}

.instruction {
  color: #94a3b8;
  text-align: center;
}

.qr-code-container {
  background: white;
  padding: 1.5rem;
  border-radius: 12px;
}

.qr-code-container img {
  display: block;
  max-width: 250px;
}

.loading {
  width: 250px;
  height: 250px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: #64748b;
}

.referral-info {
  width: 100%;
  display: flex;
  flex-direction: column;
  gap: 1rem;
}

.info-item {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 0.75rem;
  background: rgba(59, 130, 246, 0.1);
  border-radius: 8px;
}

.info-item .label {
  color: #94a3b8;
  font-size: 0.875rem;
  white-space: nowrap;
}

.info-item .value {
  flex: 1;
  color: #3b82f6;
  font-weight: 600;
  overflow: hidden;
  text-overflow: ellipsis;
}

.info-item .value.small {
  font-size: 0.75rem;
}

.btn-copy {
  padding: 0.25rem 0.75rem;
  background: rgba(59, 130, 246, 0.2);
  color: #3b82f6;
  border: 1px solid rgba(59, 130, 246, 0.3);
  border-radius: 6px;
  cursor: pointer;
  font-size: 0.75rem;
  transition: all 0.2s;
  white-space: nowrap;
}

.btn-copy:hover {
  background: rgba(59, 130, 246, 0.3);
}

.btn-primary {
  padding: 0.75rem 2rem;
  background: #3b82f6;
  color: white;
  border: none;
  border-radius: 8px;
  cursor: pointer;
  font-weight: 600;
  transition: all 0.2s;
}

.btn-primary:hover {
  background: #2563eb;
}
</style>
'''

# ============================================================================
# 파일 생성 함수
# ============================================================================

def create_component_file(path, content):
    """컴포넌트 파일 생성"""
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
    print(f"✅ Created: {path}")

def main():
    print("=" * 60)
    print("MyPage Vue 컴포넌트 자동 생성 시작")
    print("=" * 60)
    print()

    components = [
        (f"{COMPONENTS_DIR}/modals/BaseModal.vue", BASE_MODAL),
        (f"{COMPONENTS_DIR}/sections/ProfileSummary.vue", PROFILE_SUMMARY),
        (f"{COMPONENTS_DIR}/sections/MenuNavigation.vue", MENU_NAVIGATION),
        (f"{COMPONENTS_DIR}/modals/Modal2FASetup.vue", MODAL_2FA_SETUP),
        (f"{COMPONENTS_DIR}/modals/ModalPINSetup.vue", MODAL_PIN_SETUP),
        (f"{COMPONENTS_DIR}/modals/ModalQRCode.vue", MODAL_QR_CODE),
    ]

    for path, content in components:
        create_component_file(path, content)

    print()
    print("=" * 60)
    print("✅ Vue 컴포넌트 생성 완료")
    print("=" * 60)
    print()
    print("생성된 컴포넌트:")
    print("  [공통]")
    print("  - BaseModal.vue")
    print()
    print("  [섹션]")
    print("  - ProfileSummary.vue")
    print("  - MenuNavigation.vue")
    print()
    print("  [모달]")
    print("  - Modal2FASetup.vue")
    print("  - ModalPINSetup.vue")
    print("  - ModalQRCode.vue")
    print()
    print("=" * 60)
    print("다음 단계:")
    print("=" * 60)
    print("1. 나머지 컴포넌트 생성 (SecurityCenter, DashboardOverview 등)")
    print("2. MyPageView.vue 메인 페이지 구현")
    print("3. API 연동 테스트")
    print("4. 스타일 최적화")
    print()

if __name__ == "__main__":
    main()
