# MyPage 재개발 상세 작업 명세서

**작성일:** 2026-01-28
**목적:** 참고 파일(GLI mypageV0.1.html) 기반 마이페이지 전면 재개발
**원칙:** 쇼핑 기능(탭6)은 기존 유지, 나머지 8개 탭 재개발

---

## 작업 순서 원칙

각 탭마다 다음 순서로 진행:
1. **화면 분석 및 요구사항 명세**
2. **DB 모델 설계 및 마이그레이션**
3. **API 엔드포인트 개발 (Django Backend)**
4. **Admin Frontend 개발** (필요 시)
5. **User Frontend 개발** (Vue.js)

---

# 탭 1: Profile (회원 정보)

## 1.1 화면 분석 및 요구사항

### 화면 구성
```
┌─────────────────────────────────────────┐
│ 👤 회원 정보 (Profile)                   │
├─────────────────────────────────────────┤
│ [기본 정보 카드]                         │
│ - 이메일: user@gli.io                   │
│ - 전화번호: +82 10-****-5678            │
│ - 가입일: 2024.12.15                    │
│ - 최종 로그인: 2025.01.28 14:30        │
│                                         │
│ [로그인 세션 카드]                       │
│ - Chrome on Windows                     │
│   Seoul, KR | 121.134.xxx.xxx         │
│   2025.01.28 14:30 | [Active]         │
│                                         │
│ [보안 설정 카드]                         │
│ - 비밀번호 변경 [변경하기] 버튼          │
│ - 휴대전화 인증 [인증하기] 버튼          │
│ - 얼굴 인증 [관리하기] 버튼              │
│ - 로그아웃 [로그아웃] 버튼               │
└─────────────────────────────────────────┘
```

### 기능 요구사항
1. **기본 정보 표시**
   - 이메일, 전화번호, 가입일, 최종 로그인 시간 표시
   - 현재는 readonly, 향후 편집 기능 추가 가능

2. **로그인 세션 관리**
   - 최근 로그인 세션 목록 표시 (최대 5개)
   - 디바이스, 위치, IP, 시간, 상태 표시
   - 상태: Active (초록색), Expired (회색)

3. **보안 설정 바로가기**
   - 비밀번호 변경 → 모달 오픈
   - 휴대전화 인증 → 모달 오픈 (향후)
   - 얼굴 인증 → Face Verification 탭으로 이동
   - 로그아웃 → 로그아웃 처리

### 비기능 요구사항
- 응답 시간: 1초 이내
- 세션 정보는 실시간 갱신 불필요 (페이지 로드 시에만)

## 1.2 DB 모델

### 기존 User 모델 확인
```python
# gli_django/users/models.py
class User(AbstractUser):
    # 기존 필드 확인
    email = models.EmailField(unique=True)
    phone_number = models.CharField(max_length=20, null=True, blank=True)
    date_joined = models.DateTimeField(auto_now_add=True)
    last_login = models.DateTimeField(null=True, blank=True)
```

### 신규: LoginSession 모델
```python
# gli_django/users/models.py
class LoginSession(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='login_sessions')
    device = models.CharField(max_length=200)  # "Chrome on Windows"
    location = models.CharField(max_length=200)  # "Seoul, South Korea"
    ip_address = models.GenericIPAddressField()
    login_time = models.DateTimeField(auto_now_add=True)
    last_activity = models.DateTimeField(auto_now=True)
    is_active = models.BooleanField(default=True)
    session_key = models.CharField(max_length=40, unique=True)

    class Meta:
        ordering = ['-login_time']
        indexes = [
            models.Index(fields=['user', '-login_time']),
        ]

    def __str__(self):
        return f"{self.user.username} - {self.device} ({self.login_time})"
```

### 마이그레이션
```bash
python manage.py makemigrations users
python manage.py migrate users
```

## 1.3 API 엔드포인트

### 1.3.1 프로필 조회
```python
# GET /api/user/profile/
# Response:
{
    "email": "user@gli.io",
    "phone_number": "+82 10-1234-5678",
    "date_joined": "2024-12-15T10:30:00Z",
    "last_login": "2025-01-28T14:30:00Z",
    "username": "user123",
    "grade": "W"
}
```

**구현 위치:** `gli_django/users/views.py`
```python
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_user_profile(request):
    user = request.user
    return Response({
        'email': user.email,
        'phone_number': user.phone_number or '',
        'date_joined': user.date_joined,
        'last_login': user.last_login,
        'username': user.username,
        'grade': getattr(user, 'grade', 'R')
    })
```

### 1.3.2 로그인 세션 조회
```python
# GET /api/user/sessions/
# Response:
{
    "sessions": [
        {
            "id": 1,
            "device": "Chrome on Windows",
            "location": "Seoul, South Korea",
            "ip_address": "121.134.xxx.xxx",
            "login_time": "2025-01-28T14:30:00Z",
            "last_activity": "2025-01-28T15:00:00Z",
            "is_active": true
        },
        ...
    ]
}
```

**구현 위치:** `gli_django/users/views.py`
```python
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_login_sessions(request):
    sessions = LoginSession.objects.filter(user=request.user)[:5]
    return Response({
        'sessions': [
            {
                'id': s.id,
                'device': s.device,
                'location': s.location,
                'ip_address': s.ip_address,
                'login_time': s.login_time,
                'last_activity': s.last_activity,
                'is_active': s.is_active
            } for s in sessions
        ]
    })
```

### 1.3.3 URL 라우팅
```python
# gli_django/users/urls.py
urlpatterns = [
    path('profile/', get_user_profile, name='user-profile'),
    path('sessions/', get_login_sessions, name='login-sessions'),
]
```

## 1.4 User Frontend 개발

### 1.4.1 기존 코드 위치
`gli_user-frontend/src/views/MyPageView.vue` (55-201 라인)

### 1.4.2 수정 내용
1. **로그인 세션 데이터 로딩**
```typescript
import { ref, onMounted } from 'vue';
import { api } from '@/services/api';

const loginSessions = ref([]);

const fetchLoginSessions = async () => {
    try {
        const response = await api.get('/api/user/sessions/');
        loginSessions.value = response.data.sessions;
    } catch (error) {
        console.error('Failed to fetch login sessions:', error);
    }
};

onMounted(() => {
    fetchLoginSessions();
});
```

2. **UI 개선**
- 참고 파일의 카드 스타일 적용
- 세션 상태 표시 개선 (Active/Expired 배지)

### 1.4.3 컴포넌트 구조
```vue
<template>
  <section v-show="activeTab === 'profile'" class="tab-panel">
    <div class="panel-container">
      <!-- 기본 정보 카드 -->
      <div class="info-card">
        <h3>{{ $t('mypage.profile.basicInfo') }}</h3>
        <div class="info-list">
          <div class="info-item">
            <span>이메일</span>
            <span>{{ userInfo.email }}</span>
          </div>
          <!-- 나머지 정보 -->
        </div>
      </div>

      <!-- 로그인 세션 카드 -->
      <div class="info-card">
        <h3>{{ $t('mypage.profile.recentSessions') }}</h3>
        <div class="sessions-list">
          <div v-for="session in loginSessions" :key="session.id" class="session-item">
            <!-- 세션 정보 표시 -->
          </div>
        </div>
      </div>

      <!-- 보안 설정 카드 -->
      <div class="info-card">
        <!-- 기존 코드 유지 -->
      </div>
    </div>
  </section>
</template>
```

---

# 탭 2: Security (통합 보안 설정)

## 2.1 화면 분석 및 요구사항

### 화면 구성
```
┌─────────────────────────────────────────┐
│ 🛡️ 통합 보안 설정 (Security Center)      │
├─────────────────────────────────────────┤
│ [보안 등급 인디케이터]                    │
│ ━━━━━━━━━━━━━━━━━━ 2/3                 │
│ ⚠️ 보통 (Medium) - 1개 더 활성화하세요   │
│                                         │
│ [얼굴 인증 카드] ✅ Active               │
│ - 마지막 인증: 2024.12.20              │
│ - [인증하기] [해지]                     │
│                                         │
│ [2FA 인증 카드] ❌ Inactive             │
│ - Google Authenticator 연동            │
│ - [설정하기]                            │
│                                         │
│ [PIN 번호 카드] ❌ Inactive              │
│ - 6자리 숫자                            │
│ - [설정하기]                            │
└─────────────────────────────────────────┘
```

### 기능 요구사항

1. **보안 등급 시스템**
   - Level 1 (위험): 인증 0-1개 활성화
   - Level 2 (보통): 인증 2개 활성화
   - Level 3 (안전): 인증 3개 모두 활성화
   - 진행 바 시각화

2. **얼굴 인증 (Face Recognition)**
   - 현재 상태 표시 (Active/Inactive)
   - 마지막 인증일 표시
   - 인증하기 → 실시간 카메라 모달
   - 해지 → 비활성화

3. **2FA 인증 (Google OTP)**
   - 현재 상태 표시
   - 설정하기 → QR 코드 스캔 모달
   - Secret Key 복사
   - 6자리 OTP 입력 확인

4. **PIN 번호**
   - 현재 상태 표시
   - 설정하기 → PIN 입력 모달 (3x4 숫자 패드)
   - 6자리 입력
   - 확인 입력

### 비기능 요구사항
- 2FA Secret은 암호화 저장
- PIN은 해시(bcrypt) 저장
- 보안 등급 변경 시 실시간 업데이트

## 2.2 DB 모델

### 신규: SecuritySetting 모델
```python
# gli_django/users/models.py
from django.contrib.auth.hashers import make_password, check_password

class SecuritySetting(models.Model):
    SECURITY_LEVEL_CHOICES = [
        (1, 'Danger'),
        (2, 'Medium'),
        (3, 'Safe'),
    ]

    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='security_setting')

    # 얼굴 인증
    face_auth_enabled = models.BooleanField(default=False)
    face_auth_last_verified = models.DateTimeField(null=True, blank=True)
    face_auth_data = models.TextField(null=True, blank=True)  # 얼굴 벡터 데이터 (암호화)

    # 2FA
    two_fa_enabled = models.BooleanField(default=False)
    two_fa_secret = models.CharField(max_length=32, null=True, blank=True)  # Base32 encoded
    two_fa_backup_codes = models.JSONField(default=list)  # 백업 코드 리스트

    # PIN
    pin_enabled = models.BooleanField(default=False)
    pin_hash = models.CharField(max_length=128, null=True, blank=True)

    # 보안 등급
    security_level = models.IntegerField(choices=SECURITY_LEVEL_CHOICES, default=1)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def calculate_security_level(self):
        """활성화된 인증 방법 개수에 따라 보안 등급 계산"""
        active_count = sum([
            self.face_auth_enabled,
            self.two_fa_enabled,
            self.pin_enabled
        ])
        if active_count == 0:
            return 1
        elif active_count <= 2:
            return 2
        else:
            return 3

    def set_pin(self, pin):
        """PIN 설정 (해시 저장)"""
        self.pin_hash = make_password(pin)
        self.pin_enabled = True

    def check_pin(self, pin):
        """PIN 검증"""
        return check_password(pin, self.pin_hash)

    def save(self, *args, **kwargs):
        self.security_level = self.calculate_security_level()
        super().save(*args, **kwargs)

    def __str__(self):
        return f"{self.user.username} - Level {self.security_level}"
```

### 마이그레이션
```bash
python manage.py makemigrations users
python manage.py migrate users
```

### 초기 데이터 생성 (Signal)
```python
# gli_django/users/signals.py
from django.db.models.signals import post_save
from django.dispatch import receiver
from .models import User, SecuritySetting

@receiver(post_save, sender=User)
def create_security_setting(sender, instance, created, **kwargs):
    if created:
        SecuritySetting.objects.create(user=instance)
```

## 2.3 API 엔드포인트

### 2.3.1 보안 설정 조회
```python
# GET /api/security/status/
# Response:
{
    "security_level": 2,
    "face_auth": {
        "enabled": true,
        "last_verified": "2024-12-20T10:00:00Z"
    },
    "two_fa": {
        "enabled": false
    },
    "pin": {
        "enabled": true
    }
}
```

### 2.3.2 2FA 설정 시작
```python
# POST /api/security/2fa/setup/
# Response:
{
    "secret": "JBSWY3DPEHPK3PXP",
    "qr_code": "data:image/png;base64,...",
    "backup_codes": ["12345678", "87654321", ...]
}
```

**구현:**
```python
import pyotp
import qrcode
import io
import base64

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def setup_2fa(request):
    user = request.user
    setting, _ = SecuritySetting.objects.get_or_create(user=user)

    # Secret Key 생성
    secret = pyotp.random_base32()
    setting.two_fa_secret = secret

    # 백업 코드 생성 (8자리 x 10개)
    backup_codes = [str(random.randint(10000000, 99999999)) for _ in range(10)]
    setting.two_fa_backup_codes = backup_codes
    setting.save()

    # QR 코드 생성
    totp_uri = pyotp.totp.TOTP(secret).provisioning_uri(
        name=user.email,
        issuer_name='GLI Platform'
    )
    qr = qrcode.make(totp_uri)
    buffer = io.BytesIO()
    qr.save(buffer, format='PNG')
    qr_base64 = base64.b64encode(buffer.getvalue()).decode()

    return Response({
        'secret': secret,
        'qr_code': f'data:image/png;base64,{qr_base64}',
        'backup_codes': backup_codes
    })
```

### 2.3.3 2FA 인증 확인
```python
# POST /api/security/2fa/verify/
# Request:
{
    "code": "123456"
}
# Response:
{
    "success": true
}
```

**구현:**
```python
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def verify_2fa(request):
    user = request.user
    code = request.data.get('code')

    try:
        setting = user.security_setting
        totp = pyotp.TOTP(setting.two_fa_secret)

        if totp.verify(code):
            setting.two_fa_enabled = True
            setting.save()
            return Response({'success': True})
        else:
            return Response({'success': False, 'error': 'Invalid code'}, status=400)
    except SecuritySetting.DoesNotExist:
        return Response({'error': 'Security setting not found'}, status=404)
```

### 2.3.4 PIN 설정
```python
# POST /api/security/pin/set/
# Request:
{
    "pin": "123456",
    "pin_confirm": "123456"
}
# Response:
{
    "success": true
}
```

**구현:**
```python
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def set_pin(request):
    pin = request.data.get('pin')
    pin_confirm = request.data.get('pin_confirm')

    if pin != pin_confirm:
        return Response({'error': 'PIN does not match'}, status=400)

    if len(pin) != 6 or not pin.isdigit():
        return Response({'error': 'PIN must be 6 digits'}, status=400)

    user = request.user
    setting, _ = SecuritySetting.objects.get_or_create(user=user)
    setting.set_pin(pin)
    setting.save()

    return Response({'success': True})
```

### 2.3.5 PIN 검증
```python
# POST /api/security/pin/verify/
# Request:
{
    "pin": "123456"
}
# Response:
{
    "success": true
}
```

### 2.3.6 얼굴 인증 관련
- 기존 Face Verification 탭의 API 활용
- 상태만 SecuritySetting에 동기화

### 2.3.7 URL 라우팅
```python
# gli_django/users/urls.py
from .views import (
    security_status,
    setup_2fa,
    verify_2fa,
    set_pin,
    verify_pin,
)

urlpatterns = [
    # ... 기존 URL들
    path('security/status/', security_status, name='security-status'),
    path('security/2fa/setup/', setup_2fa, name='2fa-setup'),
    path('security/2fa/verify/', verify_2fa, name='2fa-verify'),
    path('security/pin/set/', set_pin, name='set-pin'),
    path('security/pin/verify/', verify_pin, name='verify-pin'),
]
```

## 2.4 User Frontend 개발

### 2.4.1 신규 컴포넌트 생성
`gli_user-frontend/src/components/security/SecurityCenter.vue`

```vue
<template>
  <div class="security-center">
    <!-- 보안 등급 인디케이터 -->
    <div class="security-level-indicator">
      <div class="level-progress">
        <div class="progress-bar" :style="{ width: `${(securityLevel / 3) * 100}%` }"></div>
      </div>
      <p class="level-text">
        <span :class="`level-${securityLevel}`">
          {{ getLevelText(securityLevel) }}
        </span>
        <span v-if="securityLevel < 3"> - {{ 3 - securityLevel }}개 더 활성화하세요</span>
      </p>
    </div>

    <!-- 얼굴 인증 카드 -->
    <div class="security-card" :class="{ active: faceAuth.enabled }">
      <div class="card-header">
        <h3>얼굴 인증 (Face Recognition)</h3>
        <span class="status-badge">{{ faceAuth.enabled ? 'Active' : 'Inactive' }}</span>
      </div>
      <div class="card-body">
        <p v-if="faceAuth.enabled">마지막 인증: {{ formatDate(faceAuth.last_verified) }}</p>
        <div class="card-actions">
          <button v-if="!faceAuth.enabled" @click="setupFaceAuth" class="btn-primary">인증하기</button>
          <button v-else @click="disableFaceAuth" class="btn-secondary">해지</button>
        </div>
      </div>
    </div>

    <!-- 2FA 카드 -->
    <div class="security-card" :class="{ active: twoFA.enabled }">
      <div class="card-header">
        <h3>2FA 인증 (Google OTP)</h3>
        <span class="status-badge">{{ twoFA.enabled ? 'Active' : 'Inactive' }}</span>
      </div>
      <div class="card-body">
        <p>Google Authenticator 연동</p>
        <div class="card-actions">
          <button v-if="!twoFA.enabled" @click="setup2FA" class="btn-primary">설정하기</button>
          <button v-else @click="disable2FA" class="btn-secondary">해지</button>
        </div>
      </div>
    </div>

    <!-- PIN 카드 -->
    <div class="security-card" :class="{ active: pin.enabled }">
      <div class="card-header">
        <h3>PIN 번호</h3>
        <span class="status-badge">{{ pin.enabled ? 'Active' : 'Inactive' }}</span>
      </div>
      <div class="card-body">
        <p>6자리 숫자</p>
        <div class="card-actions">
          <button v-if="!pin.enabled" @click="setupPIN" class="btn-primary">설정하기</button>
          <button v-else @click="changePIN" class="btn-secondary">변경</button>
        </div>
      </div>
    </div>

    <!-- 2FA 설정 모달 -->
    <Modal2FASetup
      :show="show2FAModal"
      :qrCode="qrCode"
      :secret="secret"
      :backupCodes="backupCodes"
      @close="close2FAModal"
      @verify="verify2FA"
    />

    <!-- PIN 설정 모달 -->
    <ModalPINSetup
      :show="showPINModal"
      @close="closePINModal"
      @submit="submitPIN"
    />
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue';
import { api } from '@/services/api';
import Modal2FASetup from './Modal2FASetup.vue';
import ModalPINSetup from './ModalPINSetup.vue';

const securityLevel = ref(1);
const faceAuth = ref({ enabled: false, last_verified: null });
const twoFA = ref({ enabled: false });
const pin = ref({ enabled: false });

// 2FA 모달 관련
const show2FAModal = ref(false);
const qrCode = ref('');
const secret = ref('');
const backupCodes = ref([]);

// PIN 모달 관련
const showPINModal = ref(false);

const fetchSecurityStatus = async () => {
  try {
    const response = await api.get('/api/security/status/');
    securityLevel.value = response.data.security_level;
    faceAuth.value = response.data.face_auth;
    twoFA.value = response.data.two_fa;
    pin.value = response.data.pin;
  } catch (error) {
    console.error('Failed to fetch security status:', error);
  }
};

const setup2FA = async () => {
  try {
    const response = await api.post('/api/security/2fa/setup/');
    qrCode.value = response.data.qr_code;
    secret.value = response.data.secret;
    backupCodes.value = response.data.backup_codes;
    show2FAModal.value = true;
  } catch (error) {
    console.error('Failed to setup 2FA:', error);
  }
};

const verify2FA = async (code: string) => {
  try {
    await api.post('/api/security/2fa/verify/', { code });
    show2FAModal.value = false;
    await fetchSecurityStatus();
  } catch (error) {
    console.error('Failed to verify 2FA:', error);
  }
};

const setupPIN = () => {
  showPINModal.value = true;
};

const submitPIN = async (pin: string, pinConfirm: string) => {
  try {
    await api.post('/api/security/pin/set/', { pin, pin_confirm: pinConfirm });
    showPINModal.value = false;
    await fetchSecurityStatus();
  } catch (error) {
    console.error('Failed to set PIN:', error);
  }
};

const getLevelText = (level: number) => {
  const texts = { 1: '위험 (Danger)', 2: '보통 (Medium)', 3: '안전 (Safe)' };
  return texts[level] || '';
};

const formatDate = (date: string) => {
  if (!date) return '';
  return new Date(date).toLocaleDateString('ko-KR');
};

onMounted(() => {
  fetchSecurityStatus();
});
</script>
```

### 2.4.2 2FA 설정 모달 컴포넌트
`gli_user-frontend/src/components/security/Modal2FASetup.vue`

```vue
<template>
  <div v-if="show" class="modal-overlay" @click="$emit('close')">
    <div class="modal-content" @click.stop>
      <div class="modal-header">
        <h3>Google OTP 설정</h3>
        <button class="modal-close" @click="$emit('close')">×</button>
      </div>
      <div class="modal-body">
        <!-- Step 1: QR 코드 스캔 -->
        <div class="step">
          <h4>1. Google Authenticator 앱에서 QR 코드 스캔</h4>
          <img :src="qrCode" alt="QR Code" class="qr-code" />
        </div>

        <!-- Step 2: Secret Key (수동 입력용) -->
        <div class="step">
          <h4>2. 또는 Secret Key를 수동 입력</h4>
          <div class="secret-box">
            <code>{{ secret }}</code>
            <button @click="copySecret" class="btn-copy">복사</button>
          </div>
        </div>

        <!-- Step 3: OTP 입력 -->
        <div class="step">
          <h4>3. 앱에 표시된 6자리 코드 입력</h4>
          <input
            v-model="otpCode"
            type="text"
            maxlength="6"
            placeholder="123456"
            class="otp-input"
            @input="onOTPInput"
          />
        </div>

        <!-- Step 4: 백업 코드 -->
        <div class="step">
          <h4>4. 백업 코드 저장 (안전한 곳에 보관)</h4>
          <div class="backup-codes">
            <code v-for="(code, index) in backupCodes" :key="index">{{ code }}</code>
          </div>
          <button @click="downloadBackupCodes" class="btn-download">다운로드</button>
        </div>

        <button @click="verify" class="btn-verify" :disabled="otpCode.length !== 6">
          인증 완료
        </button>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref } from 'vue';

const props = defineProps<{
  show: boolean;
  qrCode: string;
  secret: string;
  backupCodes: string[];
}>();

const emit = defineEmits(['close', 'verify']);

const otpCode = ref('');

const onOTPInput = (e: Event) => {
  const target = e.target as HTMLInputElement;
  otpCode.value = target.value.replace(/\D/g, '').slice(0, 6);
};

const verify = () => {
  if (otpCode.value.length === 6) {
    emit('verify', otpCode.value);
  }
};

const copySecret = async () => {
  await navigator.clipboard.writeText(props.secret);
  alert('Secret Key가 복사되었습니다!');
};

const downloadBackupCodes = () => {
  const text = props.backupCodes.join('\n');
  const blob = new Blob([text], { type: 'text/plain' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = 'GLI-2FA-Backup-Codes.txt';
  a.click();
  URL.revokeObjectURL(url);
};
</script>
```

### 2.4.3 PIN 설정 모달 컴포넌트
`gli_user-frontend/src/components/security/ModalPINSetup.vue`

```vue
<template>
  <div v-if="show" class="modal-overlay" @click="$emit('close')">
    <div class="modal-content pin-modal" @click.stop>
      <div class="modal-header">
        <h3>PIN 번호 설정</h3>
        <button class="modal-close" @click="$emit('close')">×</button>
      </div>
      <div class="modal-body">
        <p class="instruction">6자리 숫자를 입력하세요</p>

        <!-- PIN 도트 표시 -->
        <div class="pin-dots">
          <div
            v-for="i in 6"
            :key="i"
            class="pin-dot"
            :class="{ filled: pin.length >= i }"
          ></div>
        </div>

        <!-- 숫자 패드 (3x4) -->
        <div class="number-pad">
          <button
            v-for="num in [1, 2, 3, 4, 5, 6, 7, 8, 9, null, 0, 'clear']"
            :key="num"
            class="num-btn"
            :class="{ empty: num === null }"
            @click="pressNumber(num)"
            :disabled="num === null"
          >
            <span v-if="num === 'clear'">⌫</span>
            <span v-else>{{ num }}</span>
          </button>
        </div>

        <p v-if="step === 2" class="confirm-text">PIN을 다시 입력하세요</p>
        <p v-if="error" class="error-text">{{ error }}</p>

        <button
          v-if="step === 2 && pinConfirm.length === 6"
          @click="submit"
          class="btn-submit"
        >
          설정 완료
        </button>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, watch } from 'vue';

const props = defineProps<{
  show: boolean;
}>();

const emit = defineEmits(['close', 'submit']);

const step = ref(1); // 1: 입력, 2: 확인
const pin = ref('');
const pinConfirm = ref('');
const error = ref('');

const pressNumber = (num: number | string | null) => {
  if (num === null) return;

  if (num === 'clear') {
    if (step.value === 1) {
      pin.value = pin.value.slice(0, -1);
    } else {
      pinConfirm.value = pinConfirm.value.slice(0, -1);
    }
    error.value = '';
    return;
  }

  if (step.value === 1) {
    if (pin.value.length < 6) {
      pin.value += num.toString();
    }
  } else {
    if (pinConfirm.value.length < 6) {
      pinConfirm.value += num.toString();
    }
  }
};

watch(() => pin.value, (newVal) => {
  if (newVal.length === 6 && step.value === 1) {
    setTimeout(() => {
      step.value = 2;
    }, 300);
  }
});

const submit = () => {
  if (pin.value !== pinConfirm.value) {
    error.value = 'PIN이 일치하지 않습니다.';
    pinConfirm.value = '';
    return;
  }

  emit('submit', pin.value, pinConfirm.value);
};

watch(() => props.show, (newVal) => {
  if (!newVal) {
    // 모달 닫힐 때 초기화
    step.value = 1;
    pin.value = '';
    pinConfirm.value = '';
    error.value = '';
  }
});
</script>
```

### 2.4.4 MyPageView.vue에 통합
```vue
<template>
  <div class="my-page">
    <!-- ... 기존 코드 ... -->

    <!-- Security 탭 추가 -->
    <section v-show="activeTab === 'security'" class="tab-panel">
      <div class="panel-container">
        <h2 class="panel-title">
          <span class="panel-emoji">🛡️</span>
          통합 보안 설정
        </h2>
        <SecurityCenter />
      </div>
    </section>
  </div>
</template>

<script setup lang="ts">
import SecurityCenter from '@/components/security/SecurityCenter.vue';

// 탭 정의에 security 추가
const tabs = [
  { id: 'profile', icon: '👤', badge: null },
  { id: 'security', icon: '🛡️', badge: null }, // 새로 추가
  { id: 'face-verification', icon: '🔐', badge: null },
  // ... 나머지 탭들
];
</script>
```

---

# 탭 3: Referral (추천 코드)

## 3.1 화면 분석 및 요구사항

### 화면 구성
```
┌─────────────────────────────────────────┐
│ 🤝 추천 코드 (Referral)                  │
├─────────────────────────────────────────┤
│ [초대 코드 카드]                         │
│ Your Code: GLI-8829-XJ                 │
│ [복사] [QR 코드 보기]                   │
│                                         │
│ [초대 혜택 안내]                         │
│ 👤 피초대자: 가입 즉시 5,000P          │
│ 🎁 초대자: 2,000P + 커뮤니티 점수      │
│                                         │
│ [초대장 문구]                            │
│ "GLI 플랫폼에 초대합니다! 혜택..."      │
│ [문구 복사]                             │
│                                         │
│ [추천 내역 테이블]                       │
│ Date | User | Status | Reward         │
│ 2025.01.15 | User*** | ✅ | 2,000P   │
└─────────────────────────────────────────┘
```

### 기능 요구사항

1. **추천 코드 관리**
   - 고유 추천 코드 생성 (GLI-XXXX-YY 형식)
   - 코드 복사 버튼
   - QR 코드 생성 및 모달 표시

2. **초대장 문구**
   - 템플릿 문구 + 추천 코드 포함
   - 복사 버튼

3. **추천 내역**
   - 추천한 사용자 목록
   - 가입 상태, 보상 지급 여부 표시

4. **오버레이 제거**
   - 현재 "기능 개선 중" 오버레이 제거

## 3.2 DB 모델

### 기존 Referral 모델 확인
```python
# gli_django/referrals/models.py 확인 필요
# 없으면 신규 생성
```

### 신규/확장: Referral 모델
```python
# gli_django/referrals/models.py
import random
import string

class Referral(models.Model):
    STATUS_CHOICES = [
        ('PENDING', 'Pending'),
        ('REGISTERED', 'Registered'),
        ('VERIFIED', 'Verified'),
        ('REWARDED', 'Rewarded'),
    ]

    referrer = models.ForeignKey(User, on_delete=models.CASCADE, related_name='referrals_sent')
    referee = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, blank=True, related_name='referrals_received')

    code = models.CharField(max_length=20, unique=True, db_index=True)

    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='PENDING')

    # 보상
    referrer_reward = models.DecimalField(max_digits=10, decimal_places=2, default=2000)
    referee_reward = models.DecimalField(max_digits=10, decimal_places=2, default=5000)
    is_rewarded = models.BooleanField(default=False)

    created_at = models.DateTimeField(auto_now_add=True)
    registered_at = models.DateTimeField(null=True, blank=True)  # 피초대자 가입일

    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['referrer', '-created_at']),
            models.Index(fields=['code']),
        ]

    @staticmethod
    def generate_code():
        """GLI-XXXX-YY 형식의 코드 생성"""
        while True:
            numbers = ''.join(random.choices(string.digits, k=4))
            letters = ''.join(random.choices(string.ascii_uppercase, k=2))
            code = f"GLI-{numbers}-{letters}"
            if not Referral.objects.filter(code=code).exists():
                return code

    def __str__(self):
        return f"{self.referrer.username} -> {self.referee.username if self.referee else 'N/A'} ({self.code})"
```

### User 모델 확장 (추천 코드 필드 추가)
```python
# gli_django/users/models.py
class User(AbstractUser):
    # ... 기존 필드들
    referral_code = models.CharField(max_length=20, unique=True, null=True, blank=True)
    referred_by = models.ForeignKey('self', on_delete=models.SET_NULL, null=True, blank=True, related_name='referrals')

    def get_or_create_referral_code(self):
        """사용자의 추천 코드 생성 또는 반환"""
        if not self.referral_code:
            from referrals.models import Referral
            self.referral_code = Referral.generate_code()
            self.save()
        return self.referral_code
```

## 3.3 API 엔드포인트

### 3.3.1 추천 코드 조회
```python
# GET /api/referral/code/
# Response:
{
    "code": "GLI-8829-XJ",
    "referral_url": "https://gli-platform.com/signup?ref=GLI-8829-XJ",
    "total_referrals": 5,
    "total_rewards": 10000
}
```

**구현:**
```python
# gli_django/referrals/views.py
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from django.conf import settings

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_referral_code(request):
    user = request.user
    code = user.get_or_create_referral_code()

    referrals = Referral.objects.filter(referrer=user, status='REWARDED')
    total_rewards = sum(r.referrer_reward for r in referrals)

    return Response({
        'code': code,
        'referral_url': f"{settings.FRONTEND_URL}/signup?ref={code}",
        'total_referrals': referrals.count(),
        'total_rewards': total_rewards
    })
```

### 3.3.2 QR 코드 생성
```python
# GET /api/referral/qr-code/
# Response:
{
    "qr_code": "data:image/png;base64,..."
}
```

**구현:**
```python
import qrcode
import io
import base64

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def generate_qr_code(request):
    user = request.user
    code = user.get_or_create_referral_code()

    # QR 코드 생성
    referral_url = f"{settings.FRONTEND_URL}/signup?ref={code}"
    qr = qrcode.QRCode(version=1, box_size=10, border=2)
    qr.add_data(referral_url)
    qr.make(fit=True)

    img = qr.make_image(fill_color="black", back_color="white")
    buffer = io.BytesIO()
    img.save(buffer, format='PNG')
    qr_base64 = base64.b64encode(buffer.getvalue()).decode()

    return Response({
        'qr_code': f'data:image/png;base64,{qr_base64}'
    })
```

### 3.3.3 추천 내역 조회
```python
# GET /api/referral/history/
# Response:
{
    "referrals": [
        {
            "id": 1,
            "referee_username": "user123",
            "status": "REWARDED",
            "reward": 2000,
            "created_at": "2025-01-15T10:00:00Z",
            "registered_at": "2025-01-15T10:05:00Z"
        },
        ...
    ]
}
```

**구현:**
```python
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_referral_history(request):
    user = request.user
    referrals = Referral.objects.filter(referrer=user).select_related('referee')

    return Response({
        'referrals': [
            {
                'id': r.id,
                'referee_username': r.referee.username if r.referee else 'N/A',
                'status': r.status,
                'reward': r.referrer_reward,
                'created_at': r.created_at,
                'registered_at': r.registered_at
            } for r in referrals
        ]
    })
```

### 3.3.4 초대장 문구 생성
```python
# GET /api/referral/invitation-text/
# Response:
{
    "text": "GLI 플랫폼에 초대합니다! 가입하시면 즉시 5,000 포인트를 드립니다. 추천 코드: GLI-8829-XJ\nhttps://gli-platform.com/signup?ref=GLI-8829-XJ"
}
```

**구현:**
```python
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_invitation_text(request):
    user = request.user
    code = user.get_or_create_referral_code()
    referral_url = f"{settings.FRONTEND_URL}/signup?ref={code}"

    text = (
        f"GLI 플랫폼에 초대합니다! 🎁\n\n"
        f"가입하시면 즉시 5,000 포인트를 드리며, "
        f"저도 2,000 포인트를 받습니다.\n\n"
        f"추천 코드: {code}\n"
        f"{referral_url}"
    )

    return Response({'text': text})
```

### 3.3.5 URL 라우팅
```python
# gli_django/referrals/urls.py
from django.urls import path
from .views import (
    get_referral_code,
    generate_qr_code,
    get_referral_history,
    get_invitation_text,
)

urlpatterns = [
    path('code/', get_referral_code, name='referral-code'),
    path('qr-code/', generate_qr_code, name='referral-qr-code'),
    path('history/', get_referral_history, name='referral-history'),
    path('invitation-text/', get_invitation_text, name='invitation-text'),
]
```

## 3.4 User Frontend 개발

### 3.4.1 ReferralPanel 컴포넌트 수정
`gli_user-frontend/src/components/referral/ReferralPanel.vue`

**수정 사항:**
1. QR 코드 모달 추가
2. 초대장 문구 복사 기능 추가
3. 오버레이 제거

```vue
<template>
  <div class="referral-panel">
    <!-- 초대 코드 카드 -->
    <div class="referral-card">
      <h3>Your Referral Code</h3>
      <div class="code-display">
        <span class="code-text">{{ referralCode }}</span>
        <button @click="copyCode" class="btn-copy">복사</button>
        <button @click="showQRModal = true" class="btn-qr">QR 코드</button>
      </div>
    </div>

    <!-- 혜택 안내 -->
    <div class="benefits-card">
      <div class="benefit-item">
        <span class="benefit-icon">👤</span>
        <div>
          <strong>피초대자</strong>
          <p>가입 즉시 5,000 포인트</p>
        </div>
      </div>
      <div class="benefit-item">
        <span class="benefit-icon">🎁</span>
        <div>
          <strong>초대자 (나)</strong>
          <p>2,000 포인트 + 커뮤니티 점수</p>
        </div>
      </div>
    </div>

    <!-- 초대장 문구 -->
    <div class="invitation-card">
      <h3>초대장 문구</h3>
      <div class="invitation-text">
        <p>{{ invitationText }}</p>
        <button @click="copyInvitationText" class="btn-copy">문구 복사</button>
      </div>
    </div>

    <!-- 추천 내역 -->
    <div class="referral-history">
      <h3>추천 내역</h3>
      <table class="history-table">
        <thead>
          <tr>
            <th>날짜</th>
            <th>사용자</th>
            <th>상태</th>
            <th>보상</th>
          </tr>
        </thead>
        <tbody>
          <tr v-for="item in history" :key="item.id">
            <td>{{ formatDate(item.created_at) }}</td>
            <td>{{ item.referee_username }}</td>
            <td>
              <span class="status-badge" :class="item.status.toLowerCase()">
                {{ getStatusText(item.status) }}
              </span>
            </td>
            <td>{{ item.reward.toLocaleString() }}P</td>
          </tr>
          <tr v-if="history.length === 0">
            <td colspan="4" class="empty-row">아직 추천한 사용자가 없습니다</td>
          </tr>
        </tbody>
      </table>
    </div>

    <!-- QR 코드 모달 -->
    <div v-if="showQRModal" class="modal-overlay" @click="showQRModal = false">
      <div class="modal-content" @click.stop>
        <div class="modal-header">
          <h3>추천 QR 코드</h3>
          <button class="modal-close" @click="showQRModal = false">×</button>
        </div>
        <div class="modal-body">
          <img :src="qrCode" alt="QR Code" class="qr-image" />
          <p class="qr-description">
            이 QR 코드를 스캔하면 추천 코드가 자동 입력됩니다.
          </p>
          <button @click="downloadQR" class="btn-download">다운로드</button>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue';
import { api } from '@/services/api';

const referralCode = ref('');
const invitationText = ref('');
const qrCode = ref('');
const showQRModal = ref(false);
const history = ref([]);

const fetchReferralData = async () => {
  try {
    // 추천 코드 조회
    const codeResponse = await api.get('/api/referral/code/');
    referralCode.value = codeResponse.data.code;

    // 초대장 문구 조회
    const textResponse = await api.get('/api/referral/invitation-text/');
    invitationText.value = textResponse.data.text;

    // 추천 내역 조회
    const historyResponse = await api.get('/api/referral/history/');
    history.value = historyResponse.data.referrals;
  } catch (error) {
    console.error('Failed to fetch referral data:', error);
  }
};

const fetchQRCode = async () => {
  try {
    const response = await api.get('/api/referral/qr-code/');
    qrCode.value = response.data.qr_code;
  } catch (error) {
    console.error('Failed to fetch QR code:', error);
  }
};

const copyCode = async () => {
  await navigator.clipboard.writeText(referralCode.value);
  alert('추천 코드가 복사되었습니다!');
};

const copyInvitationText = async () => {
  await navigator.clipboard.writeText(invitationText.value);
  alert('초대장 문구가 복사되었습니다!');
};

const downloadQR = () => {
  const link = document.createElement('a');
  link.href = qrCode.value;
  link.download = `GLI-Referral-${referralCode.value}.png`;
  link.click();
};

const formatDate = (date: string) => {
  return new Date(date).toLocaleDateString('ko-KR');
};

const getStatusText = (status: string) => {
  const texts = {
    'PENDING': '대기',
    'REGISTERED': '가입',
    'VERIFIED': '인증',
    'REWARDED': '보상 지급'
  };
  return texts[status] || status;
};

onMounted(async () => {
  await fetchReferralData();
  await fetchQRCode();
});
</script>
```

### 3.4.2 MyPageView.vue 수정
```vue
<template>
  <div class="my-page">
    <!-- Referral 탭 - 오버레이 제거 -->
    <section v-show="activeTab === 'referral'" class="tab-panel">
      <div class="panel-container">
        <h2 class="panel-title">
          <span class="panel-emoji">🤝</span>
          추천 코드
        </h2>
        <ReferralPanel v-if="authStore.user?.id" :user-id="authStore.user.id" />
        <!-- 오버레이 제거됨 -->
      </div>
    </section>
  </div>
</template>
```

---

# 탭 4: Dashboard (대시보드)

## 4.1 화면 분석 및 요구사항

### 화면 구성
```
┌─────────────────────────────────────────┐
│ 📊 자산 현황 (Asset Overview)            │
├─────────────────────────────────────────┤
│ [총 자산 히어로 카드]                     │
│ Total Asset Value (Est.)               │
│ 1,250,000 GLIB                         │
│ (호버 시) $12,500.00 USD              │
│                                         │
│ [토큰 3종 카드]                          │
│ ┌──────┐ ┌──────┐ ┌──────┐           │
│ │ GLIB │ │ GLID │ │ GLIL │           │
│ │ 1.0M │ │  0   │ │ Gold │           │
│ │ 85%  │ │Locked│ │50,000│           │
│ │[업그 │ │[대기]│ │[카지노]          │
│ │레이드]│ │      │ │[쇼핑]│           │
│ └──────┘ └──────┘ └──────┘           │
│                                         │
│ [자산 교환 위젯 (Swap)]                  │
│ From: [USDT ▼] [1000]                 │
│   ⇅                                   │
│ To:   [GLID ▼] [1000]                 │
│ Rate: 1 USDT ≈ 1 GLID                 │
│ Fee: 0% (Promotion)                   │
│ [교환하기] 버튼                          │
│                                         │
│ [실행 프로젝트 테이블]                    │
│ Project | Location | Stage | Value    │
│ Khlaeng | Sihanouk  | 100% | $10,000 │
│ Star Bay| Sihanouk  |  35% | $2,500  │
└─────────────────────────────────────────┘
```

### 기능 요구사항

1. **총 자산 가치 히어로 카드**
   - GLIB 단위 표시 (기본)
   - 호버 시 USD 환산 표시
   - 실시간 토큰 시세 반영

2. **토큰 3종 상세 카드**

   **GLIB (Business/Staking):**
   - 총 잔액 표시
   - 스테이킹 비율 (Lock-up Ratio)
   - 진행 바 시각화
   - "구독 등급 업그레이드" 버튼

   **GLID (Dollar/Dividend):**
   - "상장 대기 중" 상태
   - 잔액 0 표시
   - 잠금 아이콘
   - 비활성화 상태

   **GLIL (Lifestyle/Leisure):**
   - Gold (게임용) 잔액
   - Sweeps (리딤용) 잔액
   - "소셜 카지노 이동" 버튼
   - "레저 쇼핑하러 가기" 버튼

3. **자산 교환 위젯 (Swap Widget)**
   - 지갑 연결 상태 확인
   - From/To 토큰 선택 (USDT, GLIB, GLID, GLIL)
   - 금액 입력
   - 실시간 환율 계산
   - 수수료 표시
   - 최소 교환 수량 검증 (10 이상)
   - "교환하기" 버튼 → 트랜잭션 실행

4. **실행 프로젝트 관리 테이블**
   - 프로젝트 이름, 위치
   - 진행 단계 (Structuring 35%, Operating 100%)
   - 진행 바 시각화
   - 예상 가치 표시

### 비기능 요구사항
- 환율은 5초마다 자동 갱신
- Swap 트랜잭션은 블록체인 컨펌 대기
- 지갑 연결 필수

## 4.2 DB 모델

### 4.2.1 SwapTransaction 모델
```python
# gli_django/assets/models.py
class SwapTransaction(models.Model):
    STATUS_CHOICES = [
        ('PENDING', 'Pending'),
        ('PROCESSING', 'Processing'),
        ('COMPLETED', 'Completed'),
        ('FAILED', 'Failed'),
    ]

    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='swap_transactions')

    from_token = models.CharField(max_length=10)  # USDT, GLIB, GLID, GLIL
    to_token = models.CharField(max_length=10)

    from_amount = models.DecimalField(max_digits=20, decimal_places=8)
    to_amount = models.DecimalField(max_digits=20, decimal_places=8)

    exchange_rate = models.DecimalField(max_digits=20, decimal_places=8)
    fee_amount = models.DecimalField(max_digits=20, decimal_places=8, default=0)
    fee_percentage = models.DecimalField(max_digits=5, decimal_places=2, default=0)  # 0.5% -> 0.5

    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='PENDING')

    # 블록체인 관련
    tx_hash = models.CharField(max_length=66, null=True, blank=True)  # 0x...
    wallet_address = models.CharField(max_length=42)  # 0x...

    created_at = models.DateTimeField(auto_now_add=True)
    completed_at = models.DateTimeField(null=True, blank=True)

    error_message = models.TextField(null=True, blank=True)

    class Meta:
        ordering = ['-created_at']
        indexes = [
            models.Index(fields=['user', '-created_at']),
            models.Index(fields=['status']),
        ]

    def __str__(self):
        return f"{self.user.username}: {self.from_amount} {self.from_token} -> {self.to_amount} {self.to_token}"
```

### 4.2.2 TokenBalance 모델 (사용자 토큰 잔액)
```python
# gli_django/assets/models.py
class TokenBalance(models.Model):
    TOKEN_CHOICES = [
        ('GLIB', 'GLI Business Token'),
        ('GLID', 'GLI Dollar Token'),
        ('GLIL_GOLD', 'GLI Leisure - Gold'),
        ('GLIL_SWEEPS', 'GLI Leisure - Sweeps'),
        ('USDT', 'Tether USD'),
    ]

    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='token_balances')
    token = models.CharField(max_length=20, choices=TOKEN_CHOICES)
    balance = models.DecimalField(max_digits=20, decimal_places=8, default=0)

    # GLIB 전용 (스테이킹)
    staked_amount = models.DecimalField(max_digits=20, decimal_places=8, default=0)

    last_updated = models.DateTimeField(auto_now=True)

    class Meta:
        unique_together = ['user', 'token']
        indexes = [
            models.Index(fields=['user', 'token']),
        ]

    @property
    def total_balance(self):
        """총 잔액 (일반 + 스테이킹)"""
        return self.balance + self.staked_amount

    @property
    def lockup_ratio(self):
        """스테이킹 비율 (%)"""
        if self.total_balance == 0:
            return 0
        return (self.staked_amount / self.total_balance) * 100

    def __str__(self):
        return f"{self.user.username} - {self.token}: {self.balance}"
```

### 4.2.3 ExchangeRate 모델 (환율 정보)
```python
# gli_django/assets/models.py
class ExchangeRate(models.Model):
    from_token = models.CharField(max_length=10)
    to_token = models.CharField(max_length=10)
    rate = models.DecimalField(max_digits=20, decimal_places=8)

    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        unique_together = ['from_token', 'to_token']
        indexes = [
            models.Index(fields=['from_token', 'to_token']),
        ]

    def __str__(self):
        return f"1 {self.from_token} = {self.rate} {self.to_token}"
```

### 4.2.4 Project 모델 (실행 프로젝트)
```python
# gli_django/projects/models.py
class Project(models.Model):
    STAGE_CHOICES = [
        ('STRUCTURING', 'Structuring'),
        ('CONSTRUCTION', 'Construction'),
        ('OPERATING', 'Operating'),
        ('COMPLETED', 'Completed'),
    ]

    name = models.CharField(max_length=200)
    location = models.CharField(max_length=200)
    description = models.TextField()

    stage = models.CharField(max_length=20, choices=STAGE_CHOICES)
    progress_percentage = models.IntegerField(default=0)  # 0-100

    estimated_value = models.DecimalField(max_digits=15, decimal_places=2)  # USD

    image = models.ImageField(upload_to='projects/', null=True, blank=True)

    is_active = models.BooleanField(default=True)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['-progress_percentage', 'name']

    def __str__(self):
        return f"{self.name} ({self.progress_percentage}%)"
```

### 마이그레이션
```bash
python manage.py makemigrations assets projects
python manage.py migrate assets projects
```

## 4.3 API 엔드포인트

### 4.3.1 대시보드 전체 데이터 조회
```python
# GET /api/assets/dashboard/
# Response:
{
    "total_asset_value": {
        "glib": 1250000,
        "usd": 12500.00
    },
    "tokens": {
        "glib": {
            "balance": 1000000,
            "staked": 850000,
            "lockup_ratio": 85
        },
        "glid": {
            "balance": 0,
            "is_locked": true
        },
        "glil": {
            "gold": 50000,
            "sweeps": 1200
        }
    },
    "wallet": {
        "is_connected": true,
        "address": "0x71...976F",
        "balances": {
            "USDT": 1450.00,
            "GLIB": 0,
            "GLID": 2500.00,
            "GLIL": 0
        }
    },
    "projects": [
        {
            "id": 1,
            "name": "Khlaeng Meas 1 Hotel",
            "location": "Sihanoukville, Cambodia",
            "stage": "OPERATING",
            "progress_percentage": 100,
            "estimated_value": 10000.00
        },
        ...
    ]
}
```

**구현:**
```python
# gli_django/assets/views.py
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from .models import TokenBalance, Project
from projects.models import Investment

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_dashboard(request):
    user = request.user

    # 토큰 잔액 조회
    glib_balance = TokenBalance.objects.get_or_create(user=user, token='GLIB')[0]
    glid_balance = TokenBalance.objects.get_or_create(user=user, token='GLID')[0]
    gold_balance = TokenBalance.objects.get_or_create(user=user, token='GLIL_GOLD')[0]
    sweeps_balance = TokenBalance.objects.get_or_create(user=user, token='GLIL_SWEEPS')[0]

    # 총 자산 가치 계산 (GLIB 기준)
    total_glib = glib_balance.total_balance
    total_usd = float(total_glib) * 0.01  # 1 GLIB = $0.01 (가정)

    # 프로젝트 조회 (사용자가 투자한 프로젝트만)
    investments = Investment.objects.filter(user=user).select_related('project')
    projects_data = [
        {
            'id': inv.project.id,
            'name': inv.project.name,
            'location': inv.project.location,
            'stage': inv.project.stage,
            'progress_percentage': inv.project.progress_percentage,
            'estimated_value': float(inv.amount)  # 사용자의 투자 금액
        } for inv in investments
    ]

    return Response({
        'total_asset_value': {
            'glib': float(total_glib),
            'usd': total_usd
        },
        'tokens': {
            'glib': {
                'balance': float(glib_balance.total_balance),
                'staked': float(glib_balance.staked_amount),
                'lockup_ratio': glib_balance.lockup_ratio
            },
            'glid': {
                'balance': float(glid_balance.balance),
                'is_locked': True  # 상장 전까지 잠금
            },
            'glil': {
                'gold': float(gold_balance.balance),
                'sweeps': float(sweeps_balance.balance)
            }
        },
        'wallet': {
            'is_connected': False,  # 프론트엔드에서 관리
            'address': '',
            'balances': {}
        },
        'projects': projects_data
    })
```

### 4.3.2 환율 조회
```python
# GET /api/swap/rate/?from=USDT&to=GLID
# Response:
{
    "from_token": "USDT",
    "to_token": "GLID",
    "rate": 1.0,
    "inverse_rate": 1.0,
    "fee_percentage": 0,
    "last_updated": "2025-01-28T15:00:00Z"
}
```

**구현:**
```python
# gli_django/assets/views.py
from .models import ExchangeRate

@api_view(['GET'])
def get_exchange_rate(request):
    from_token = request.query_params.get('from')
    to_token = request.query_params.get('to')

    if not from_token or not to_token:
        return Response({'error': 'Missing parameters'}, status=400)

    try:
        rate_obj = ExchangeRate.objects.get(from_token=from_token, to_token=to_token)
        rate = rate_obj.rate
    except ExchangeRate.DoesNotExist:
        # 기본 환율 (1:1)
        rate = Decimal('1.0')

    return Response({
        'from_token': from_token,
        'to_token': to_token,
        'rate': float(rate),
        'inverse_rate': float(1 / rate) if rate != 0 else 0,
        'fee_percentage': 0,  # 프로모션 기간
        'last_updated': timezone.now()
    })
```

### 4.3.3 Swap 실행
```python
# POST /api/swap/execute/
# Request:
{
    "from_token": "USDT",
    "to_token": "GLID",
    "from_amount": 1000,
    "wallet_address": "0x71...976F"
}
# Response:
{
    "success": true,
    "transaction_id": 123,
    "tx_hash": "0x...",
    "from_amount": 1000,
    "to_amount": 1000,
    "fee": 0
}
```

**구현:**
```python
from decimal import Decimal
from django.db import transaction as db_transaction

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def execute_swap(request):
    user = request.user
    from_token = request.data.get('from_token')
    to_token = request.data.get('to_token')
    from_amount = Decimal(str(request.data.get('from_amount')))
    wallet_address = request.data.get('wallet_address')

    # 최소 수량 검증
    if from_amount < 10:
        return Response({'error': 'Minimum swap amount is 10'}, status=400)

    # 환율 조회
    try:
        rate_obj = ExchangeRate.objects.get(from_token=from_token, to_token=to_token)
        rate = rate_obj.rate
    except ExchangeRate.DoesNotExist:
        rate = Decimal('1.0')

    to_amount = from_amount * rate
    fee = Decimal('0')  # 프로모션 기간

    # 트랜잭션 생성
    with db_transaction.atomic():
        # From 토큰 차감
        from_balance = TokenBalance.objects.get(user=user, token=from_token)
        if from_balance.balance < from_amount:
            return Response({'error': 'Insufficient balance'}, status=400)
        from_balance.balance -= from_amount
        from_balance.save()

        # To 토큰 증가
        to_balance, _ = TokenBalance.objects.get_or_create(user=user, token=to_token)
        to_balance.balance += to_amount
        to_balance.save()

        # SwapTransaction 기록
        swap_tx = SwapTransaction.objects.create(
            user=user,
            from_token=from_token,
            to_token=to_token,
            from_amount=from_amount,
            to_amount=to_amount,
            exchange_rate=rate,
            fee_amount=fee,
            wallet_address=wallet_address,
            status='COMPLETED',
            tx_hash=f"0x{'0' * 64}"  # 임시 (실제는 블록체인에서 받음)
        )

    return Response({
        'success': True,
        'transaction_id': swap_tx.id,
        'tx_hash': swap_tx.tx_hash,
        'from_amount': float(from_amount),
        'to_amount': float(to_amount),
        'fee': float(fee)
    })
```

### 4.3.4 URL 라우팅
```python
# gli_django/assets/urls.py
from django.urls import path
from .views import (
    get_dashboard,
    get_exchange_rate,
    execute_swap,
)

urlpatterns = [
    path('dashboard/', get_dashboard, name='dashboard'),
    path('swap/rate/', get_exchange_rate, name='swap-rate'),
    path('swap/execute/', execute_swap, name='swap-execute'),
]
```

## 4.4 User Frontend 개발

### 4.4.1 Dashboard 컴포넌트 생성
`gli_user-frontend/src/components/dashboard/DashboardOverview.vue`

```vue
<template>
  <div class="dashboard-overview">
    <!-- 1. 총 자산 히어로 카드 -->
    <div class="hero-card" @mouseenter="showUSD = true" @mouseleave="showUSD = false">
      <p class="hero-label">
        Total Asset Value (Est.)
        <i class="ph-fill ph-arrows-left-right"></i>
      </p>
      <div v-if="!showUSD" class="hero-value">
        {{ totalAsset.glib.toLocaleString() }}
        <span class="unit">GLIB</span>
      </div>
      <div v-else class="hero-value usd">
        ${{ totalAsset.usd.toLocaleString() }}
        <span class="unit">USD</span>
      </div>
      <p class="hero-note">* 실시간 토큰 시세 및 스테이킹 가치 합산 기준</p>
    </div>

    <!-- 2. 토큰 3종 카드 -->
    <div class="token-cards">
      <!-- GLIB 카드 -->
      <div class="token-card glib">
        <div class="card-header">
          <div class="token-icon">B</div>
          <div class="token-info">
            <h3>GLIB</h3>
            <p>Business / Staking</p>
          </div>
          <span class="badge premium">PREMIUM</span>
        </div>
        <div class="card-body">
          <p class="description">
            스테이킹 이자 및 세일즈 보상 토큰.<br />
            <span class="highlight">GLID와 1:1 가치 연동</span>
          </p>
          <div class="balance">
            <span class="label">Total Balance</span>
            <span class="value">{{ tokens.glib.balance.toLocaleString() }}</span>
          </div>
          <div class="lockup-section">
            <div class="lockup-header">
              <span>Lock-up Ratio</span>
              <span class="ratio">{{ tokens.glib.lockup_ratio }}%</span>
            </div>
            <div class="progress-bar">
              <div class="progress" :style="{ width: `${tokens.glib.lockup_ratio}%` }"></div>
            </div>
            <div class="staked-amount">
              <span>My Staked</span>
              <span>{{ tokens.glib.staked.toLocaleString() }}</span>
            </div>
          </div>
        </div>
        <div class="card-actions">
          <button class="btn-upgrade" @click="$emit('upgrade')">
            <i class="ph-bold ph-arrow-circle-up"></i>
            구독 등급 업그레이드
          </button>
        </div>
      </div>

      <!-- GLID 카드 -->
      <div class="token-card glid disabled">
        <div class="card-header">
          <div class="token-icon">D</div>
          <div class="token-info">
            <h3>GLID</h3>
            <p>Dollar / Dividend</p>
          </div>
          <span class="badge listing">Listing Soon</span>
        </div>
        <div class="card-body">
          <p class="description">
            상장 예정 핵심 자산.<br />
            거래소 상장 후 자유로운 거래가 가능합니다.
          </p>
          <div class="balance">
            <span class="label">Platform Balance</span>
            <span class="value">0.00 <span class="currency">($)</span></span>
          </div>
          <div class="locked-section">
            <i class="ph-duotone ph-lock-key"></i>
            <p>상장 대기 중 (Locked)</p>
          </div>
        </div>
        <div class="card-actions">
          <button class="btn-disabled" disabled>상장 후 활성화됩니다</button>
        </div>
      </div>

      <!-- GLIL 카드 -->
      <div class="token-card glil">
        <div class="card-header">
          <div class="token-icon">L</div>
          <div class="token-info">
            <h3>GLIL</h3>
            <p>Lifestyle / Leisure</p>
          </div>
        </div>
        <div class="card-body">
          <p class="description">
            여행, 골프 등 <span class="highlight">실물 레저 서비스 이용</span> 토큰.
          </p>
          <div class="glil-balances">
            <div class="glil-item gold">
              <i class="ph-fill ph-coins"></i>
              <div>
                <span class="label">Gold (Game)</span>
                <span class="value">{{ tokens.glil.gold.toLocaleString() }} G</span>
              </div>
            </div>
            <div class="glil-item sweeps">
              <i class="ph-fill ph-ticket"></i>
              <div>
                <span class="label">Sweeps (Redeem)</span>
                <span class="value">{{ tokens.glil.sweeps.toLocaleString() }} S</span>
              </div>
            </div>
          </div>
        </div>
        <div class="card-actions">
          <button class="btn-casino" @click="goToCasino">
            <i class="ph-bold ph-game-controller"></i>
            소셜 카지노 이동
          </button>
          <button class="btn-shopping" @click="goToShopping">
            <i class="ph-bold ph-shopping-bag"></i>
            레저 쇼핑하러 가기
          </button>
        </div>
      </div>
    </div>

    <!-- 3. 자산 교환 위젯 -->
    <SwapWidget />

    <!-- 4. 실행 프로젝트 테이블 -->
    <ProjectsTable :projects="projects" />
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue';
import { useRouter } from 'vue-router';
import { api } from '@/services/api';
import SwapWidget from './SwapWidget.vue';
import ProjectsTable from './ProjectsTable.vue';

const router = useRouter();

const showUSD = ref(false);
const totalAsset = ref({ glib: 0, usd: 0 });
const tokens = ref({
  glib: { balance: 0, staked: 0, lockup_ratio: 0 },
  glid: { balance: 0, is_locked: true },
  glil: { gold: 0, sweeps: 0 }
});
const projects = ref([]);

const fetchDashboard = async () => {
  try {
    const response = await api.get('/api/assets/dashboard/');
    totalAsset.value = response.data.total_asset_value;
    tokens.value = response.data.tokens;
    projects.value = response.data.projects;
  } catch (error) {
    console.error('Failed to fetch dashboard:', error);
  }
};

const goToCasino = () => {
  window.open('https://casino.gli-platform.com', '_blank');
};

const goToShopping = () => {
  router.push('/shopping');
};

onMounted(() => {
  fetchDashboard();
});
</script>
```

### 4.4.2 Swap Widget 컴포넌트
`gli_user-frontend/src/components/dashboard/SwapWidget.vue`

```vue
<template>
  <div class="swap-widget">
    <div class="widget-header">
      <h3>자산 교환 (Swap)</h3>
      <span class="widget-status" :class="{ connected: isWalletConnected }">
        <i class="ph-fill ph-circle"></i>
        {{ isWalletConnected ? 'Wallet Connected' : 'Wallet Not Connected' }}
      </span>
    </div>

    <div v-if="!isWalletConnected" class="connect-wallet-section">
      <p>자산 교환을 하려면 지갑을 연결하세요.</p>
      <button @click="connectWallet" class="btn-connect">
        <i class="ph-bold ph-wallet"></i>
        지갑 연결하기
      </button>
    </div>

    <div v-else class="swap-form">
      <!-- From -->
      <div class="swap-input-group">
        <label>From</label>
        <div class="input-row">
          <select v-model="fromToken" class="token-select" @change="updateRate">
            <option value="USDT">USDT</option>
            <option value="GLIB">GLIB</option>
            <option value="GLID">GLID</option>
            <option value="GLIL">GLIL</option>
          </select>
          <input
            v-model.number="fromAmount"
            type="number"
            class="amount-input"
            placeholder="0.00"
            @input="calculateToAmount"
          />
        </div>
        <div class="balance-info">
          Balance: {{ getBalance(fromToken).toLocaleString() }} {{ fromToken }}
        </div>
      </div>

      <!-- Swap 아이콘 -->
      <button class="btn-swap-direction" @click="swapDirection">
        <i class="ph-bold ph-arrows-down-up"></i>
      </button>

      <!-- To -->
      <div class="swap-input-group">
        <label>To</label>
        <div class="input-row">
          <select v-model="toToken" class="token-select" @change="updateRate">
            <option value="USDT">USDT</option>
            <option value="GLIB">GLIB</option>
            <option value="GLID">GLID</option>
            <option value="GLIL">GLIL</option>
          </select>
          <input
            v-model.number="toAmount"
            type="number"
            class="amount-input"
            placeholder="0.00"
            readonly
          />
        </div>
      </div>

      <!-- 환율 정보 -->
      <div class="rate-info">
        <div class="rate-row">
          <span>환율:</span>
          <span>1 {{ fromToken }} ≈ {{ rate }} {{ toToken }}</span>
        </div>
        <div class="rate-row">
          <span>수수료:</span>
          <span class="fee">{{ feePercentage }}% (Promotion)</span>
        </div>
      </div>

      <!-- 주의사항 -->
      <p v-if="fromAmount < 10 && fromAmount > 0" class="warning">
        최소 교환 수량은 10 {{ fromToken }}입니다.
      </p>

      <!-- 교환 버튼 -->
      <button
        class="btn-execute"
        :disabled="!canExecute"
        @click="executeSwap"
      >
        <i class="ph-bold ph-arrows-left-right"></i>
        교환하기
      </button>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, watch } from 'vue';
import { api } from '@/services/api';
import { useSolanaWallet } from '@/composables/useSolanaWallet';

const { isConnected: isWalletConnected, publicKey, connectWallet } = useSolanaWallet();

const fromToken = ref('USDT');
const toToken = ref('GLID');
const fromAmount = ref(0);
const toAmount = ref(0);
const rate = ref(1.0);
const feePercentage = ref(0);

const walletBalances = ref({
  USDT: 1450,
  GLIB: 0,
  GLID: 2500,
  GLIL: 0
});

const canExecute = computed(() => {
  return isWalletConnected.value && fromAmount.value >= 10 && fromAmount.value <= getBalance(fromToken.value);
});

const getBalance = (token: string) => {
  return walletBalances.value[token] || 0;
};

const updateRate = async () => {
  if (fromToken.value === toToken.value) {
    // 같은 토큰이면 to를 변경
    const tokens = ['USDT', 'GLIB', 'GLID', 'GLIL'];
    const currentIndex = tokens.indexOf(toToken.value);
    toToken.value = tokens[(currentIndex + 1) % tokens.length];
  }

  try {
    const response = await api.get('/api/swap/rate/', {
      params: { from: fromToken.value, to: toToken.value }
    });
    rate.value = response.data.rate;
    feePercentage.value = response.data.fee_percentage;
    calculateToAmount();
  } catch (error) {
    console.error('Failed to fetch rate:', error);
  }
};

const calculateToAmount = () => {
  toAmount.value = fromAmount.value * rate.value;
};

const swapDirection = () => {
  [fromToken.value, toToken.value] = [toToken.value, fromToken.value];
  [fromAmount.value, toAmount.value] = [toAmount.value, fromAmount.value];
  updateRate();
};

const executeSwap = async () => {
  if (!canExecute.value) return;

  try {
    const response = await api.post('/api/swap/execute/', {
      from_token: fromToken.value,
      to_token: toToken.value,
      from_amount: fromAmount.value,
      wallet_address: publicKey.value
    });

    if (response.data.success) {
      alert(`교환 성공!\n${fromAmount.value} ${fromToken.value} → ${toAmount.value} ${toToken.value}`);

      // 잔액 업데이트
      walletBalances.value[fromToken.value] -= fromAmount.value;
      walletBalances.value[toToken.value] += toAmount.value;

      // 폼 초기화
      fromAmount.value = 0;
      toAmount.value = 0;
    }
  } catch (error) {
    console.error('Swap failed:', error);
    alert('교환 실패: ' + error.response?.data?.error || error.message);
  }
};

watch([fromToken, toToken], () => {
  updateRate();
});

onMounted(() => {
  updateRate();
});
</script>
```

### 4.4.3 Projects Table 컴포넌트
`gli_user-frontend/src/components/dashboard/ProjectsTable.vue`

```vue
<template>
  <div class="projects-table">
    <h3>실행 프로젝트 관리</h3>
    <table>
      <thead>
        <tr>
          <th>Project Name</th>
          <th>Location</th>
          <th>Stage</th>
          <th>Progress</th>
          <th>Est. Value</th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="project in projects" :key="project.id">
          <td class="project-name">{{ project.name }}</td>
          <td>{{ project.location }}</td>
          <td>
            <span class="stage-badge" :class="project.stage.toLowerCase()">
              {{ getStageText(project.stage) }}
            </span>
          </td>
          <td>
            <div class="progress-cell">
              <div class="progress-bar">
                <div class="progress" :style="{ width: `${project.progress_percentage}%` }"></div>
              </div>
              <span class="progress-text">{{ project.progress_percentage }}%</span>
            </div>
          </td>
          <td class="value">${{ project.estimated_value.toLocaleString() }}</td>
        </tr>
        <tr v-if="projects.length === 0">
          <td colspan="5" class="empty-row">투자한 프로젝트가 없습니다</td>
        </tr>
      </tbody>
    </table>
  </div>
</template>

<script setup lang="ts">
defineProps<{
  projects: Array<any>;
}>();

const getStageText = (stage: string) => {
  const stages = {
    'STRUCTURING': 'Structuring',
    'CONSTRUCTION': 'Construction',
    'OPERATING': 'Operating',
    'COMPLETED': 'Completed'
  };
  return stages[stage] || stage;
};
</script>
```

### 4.4.4 MyPageView.vue에 통합
```vue
<template>
  <div class="my-page">
    <!-- Dashboard 탭 추가 -->
    <section v-show="activeTab === 'dashboard'" class="tab-panel">
      <div class="panel-container">
        <h2 class="panel-title">
          <span class="panel-emoji">📊</span>
          자산 현황 (Asset Overview)
        </h2>
        <DashboardOverview />
      </div>
    </section>
  </div>
</template>

<script setup lang="ts">
import DashboardOverview from '@/components/dashboard/DashboardOverview.vue';

// 탭 정의에 dashboard 추가
const tabs = [
  { id: 'profile', icon: '👤', badge: null },
  { id: 'security', icon: '🛡️', badge: null },
  { id: 'face-verification', icon: '🔐', badge: null },
  { id: 'referral', icon: '🤝', badge: null },
  { id: 'dashboard', icon: '📊', badge: null }, // 새로 추가
  { id: 'glib-tokens', icon: '💰', badge: null },
  // ... 나머지 탭들
];
</script>
```

---

**(계속됩니다 - 다음 메시지에서 탭 5-9, 공통 작업, 최종 검증 내용 작성)**

---

## 작성 중단점

현재까지 작성된 내용:
- ✅ 탭 1: Profile (완료)
- ✅ 탭 2: Security (완료)
- ✅ 탭 3: Referral (완료)
- ✅ 탭 4: Dashboard (완료)

다음에 작성할 내용:
- ⏳ 탭 5: Portfolio
- ⏳ 탭 6: Shopping
- ⏳ 탭 7: Usage
- ⏳ 탭 8: Transaction
- ⏳ 탭 9: Wallet
- ⏳ 공통 작업 (프로필 요약, 메뉴, 모달 시스템, 디자인)
- ⏳ 최종 검증

문서가 너무 길어지고 있으므로, 계속 작성할까요?
