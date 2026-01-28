# 탭 6: Shopping (GLIL 쇼핑) - 상세 명세서

**작성일:** 2026-01-28
**특이사항:** ⚠️ **기존 기능 유지 - UI 개선만 수행**

---

## 1. 현황 분석

### 1.1 참고 파일 vs 현재 구현

| 항목 | 참고 파일 | 현재 구현 | 결정 |
|------|----------|----------|------|
| 개발 상태 | "Dev" 배지, 준비 중 | ✅ 완전 구현 | **현재 구현 유지** |
| 장바구니 | ❌ 없음 | ✅ 완전 구현 | ✅ 유지 |
| 구매 내역 | ❌ 없음 | ✅ OrderHistory | ✅ 유지 |
| 상품 카탈로그 | ❌ 미정의 | ✅ 쇼핑몰 페이지 | ✅ 유지 |

**결론:** 현재 구현이 참고 파일보다 앞서 있음. 기능은 그대로 유지하고 UI 스타일만 참고 파일 기반으로 개선.

---

## 2. 작업 범위

### 2.1 UI 개선만 수행

1. **탭 네비게이션 스타일**
   - 참고 파일의 버튼 스타일 적용
   - 아이콘 추가

2. **장바구니 카드 스타일**
   - Glass-panel 효과
   - 호버 효과 개선

3. **구매 내역 카드**
   - 참고 파일의 레이아웃 참조
   - 애니메이션 추가

### 2.2 기능 변경 없음

- ✅ 장바구니 CRUD - 현재 구현 유지
- ✅ 구매 내역 조회 - 현재 구현 유지
- ✅ GLIL 잔액 표시 - 현재 구현 유지
- ✅ 결제 프로세스 - 현재 구현 유지

---

## 3. DB & API

### 3.1 기존 모델 확인

**확인 필요:**
- `gli_django/shopping/models.py` - Product, Cart, Order 모델
- 이미 완전히 구현되어 있다고 가정

**추가 작업:** 없음

### 3.2 기존 API 확인

**확인 필요:**
- `/api/shopping/products/` - 상품 목록
- `/api/shopping/cart/` - 장바구니 CRUD
- `/api/shopping/orders/` - 주문 내역
- `/api/shopping/checkout/` - 결제

**추가 작업:** 없음

---

## 4. Frontend 작업

### 4.1 MyPageView.vue 수정

**파일 위치:** `gli_user-frontend/src/views/MyPageView.vue` (254-391 라인)

**수정 사항:**
1. **Shopping 탭 버튼 스타일 개선**
```vue
<button
  onclick="switchTab('shopping')"
  class="shopping-tab-btn"
  :class="{ active: shoppingActiveTab === 'cart' }"
  @click="shoppingActiveTab = 'cart'"
>
  <i class="ph-duotone ph-shopping-cart"></i>
  🛒 장바구니 보기
</button>
```

2. **장바구니 섹션 스타일 개선**
```vue
<style scoped>
/* 참고 파일 기반 스타일 추가 */
.shopping-tabs {
  display: flex;
  gap: 1rem;
  margin-bottom: 2rem;
  border-bottom: 2px solid var(--border-color);
}

.shopping-tab-btn {
  padding: 1rem 2rem;
  border: none;
  background: transparent;
  color: var(--text-secondary);
  cursor: pointer;
  font-size: 1rem;
  font-weight: 500;
  transition: all 0.3s ease;
  border-bottom: 3px solid transparent;
  margin-bottom: -2px;
}

.shopping-tab-btn:hover {
  color: var(--text-primary);
  background: rgba(255, 255, 255, 0.05);
}

.shopping-tab-btn.active {
  color: var(--gli-blue);
  border-bottom-color: var(--gli-blue);
}

/* 장바구니 카드 개선 */
.cart-item {
  display: flex;
  gap: 1.5rem;
  padding: 1.5rem;
  background: var(--bg-secondary);
  border-radius: 12px;
  border: 1px solid var(--border-color);
  transition: all 0.3s ease;
}

.cart-item:hover {
  border-color: var(--gli-blue);
  box-shadow: 0 2px 8px rgba(59, 130, 246, 0.2);
  transform: translateY(-2px);
}

/* Glass-panel 효과 */
.cart-summary {
  background: rgba(15, 23, 42, 0.6);
  backdrop-filter: blur(10px);
  border: 1px solid rgba(255, 255, 255, 0.1);
}
</style>
```

3. **Empty State 개선**
```vue
<div class="empty-state">
  <div class="empty-icon">
    <i class="ph-duotone ph-shopping-cart text-6xl"></i>
  </div>
  <h3 class="empty-title">장바구니가 비어있습니다</h3>
  <p class="empty-description">GLI-L 쇼핑몰에서 상품을 담아보세요</p>
  <button class="btn-shop" @click="$router.push('/shopping')">
    <i class="ph-bold ph-storefront"></i>
    쇼핑몰 바로가기
  </button>
</div>
```

### 4.2 OrderHistory 컴포넌트 스타일 개선

**파일 위치:** `gli_user-frontend/src/components/shopping/OrderHistory.vue`

**수정 사항:**
```vue
<style scoped>
/* 주문 카드 스타일 개선 */
.order-card {
  background: var(--bg-secondary);
  border-radius: 16px;
  border: 1px solid var(--border-color);
  overflow: hidden;
  transition: all 0.3s ease;
}

.order-card:hover {
  border-color: var(--gli-purple);
  box-shadow: 0 4px 12px rgba(168, 85, 247, 0.2);
}

/* 주문 헤더에 그라데이션 추가 */
.order-header {
  background: linear-gradient(135deg, var(--gli-blue) 0%, var(--gli-purple) 100%);
  padding: 1.5rem;
  color: white;
}

/* 상품 이미지 호버 효과 */
.product-image {
  overflow: hidden;
  border-radius: 8px;
  transition: transform 0.3s;
}

.product-image:hover img {
  transform: scale(1.05);
}

/* 상태 배지 애니메이션 */
.status-badge {
  display: inline-flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.5rem 1rem;
  border-radius: 20px;
  font-weight: 600;
  animation: pulse 2s infinite;
}

.status-badge.completed {
  background: var(--gli-green);
}

.status-badge.pending {
  background: var(--gli-gold);
}

@keyframes pulse {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.8; }
}
</style>
```

---

## 5. 작업 체크리스트

### 5.1 Frontend 작업

- [ ] MyPageView.vue 스타일 개선
  - [ ] Shopping 탭 버튼 아이콘 추가
  - [ ] 장바구니 카드 호버 효과
  - [ ] Glass-panel 효과 추가
  - [ ] Empty State UI 개선

- [ ] OrderHistory 컴포넌트 스타일 개선
  - [ ] 주문 카드 레이아웃 개선
  - [ ] 상태 배지 애니메이션
  - [ ] 이미지 호버 효과

### 5.2 테스트

- [ ] 장바구니 추가/수정/삭제 동작 확인
- [ ] 구매 내역 조회 확인
- [ ] 결제 프로세스 확인
- [ ] 반응형 레이아웃 확인

### 5.3 주의사항

- ⚠️ 기존 기능 로직 변경 금지
- ⚠️ API 호출 코드 수정 금지
- ⚠️ 상태 관리 (Pinia store) 수정 금지
- ✅ CSS/스타일만 수정

---

## 6. 예상 작업 시간

- **Frontend 스타일 개선:** 2-3시간
- **테스트:** 1시간
- **총 예상:** 3-4시간

---

## 7. 완료 기준

1. ✅ 참고 파일의 UI 스타일 적용
2. ✅ 모든 기존 기능 정상 동작
3. ✅ 호버/애니메이션 효과 적용
4. ✅ 반응형 레이아웃 확인

---

**다음 문서:** [탭 7: Usage (이용 내역)](./mypage_spec_tab7_usage.md)
