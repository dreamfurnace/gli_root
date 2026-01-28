# 탭 8: Transaction (거래 내역) - 상세 명세서

**작성일:** 2026-01-28
**특이사항:** ✅ **기존 기능 유지 - UI 개선만**

---

## 1. 현황 분석

### 1.1 참고 파일 vs 현재 구현

| 항목 | 참고 파일 | 현재 구현 | 결정 |
|------|----------|----------|------|
| P2P 거래 표시 | ✅ | ✅ | ✅ 유지 |
| Swap 내역 | ✅ | ✅ | ✅ 유지 |
| 입출금 내역 | ✅ | ✅ | ✅ 유지 |
| 필터링 | ✅ | ✅ | ✅ 유지 |
| 트랜잭션 해시 | ✅ | ✅ | ✅ 유지 |

**결론:** 기능은 동일. UI만 참고 파일 스타일 적용.

---

## 2. 작업 범위

### 2.1 UI 개선사항

1. **필터 버튼 스타일**
   - 참고 파일의 버튼 디자인 적용
   - 아이콘 추가

2. **테이블 스타일**
   - 색상 코드 개선
   - 호버 효과

3. **트랜잭션 타입 배지**
   - 타입별 색상 구분 명확화
   - 아이콘 추가

---

## 3. Frontend 작업

### 3.1 TransactionHistory 컴포넌트 개선

**파일 위치:** `gli_user-frontend/src/components/TransactionHistory.vue`

**수정 사항:**

```vue
<style scoped>
/* 필터 버튼 스타일 개선 */
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
  transform: translateY(-2px);
}

.filter-btn.active {
  background: linear-gradient(135deg, var(--gli-blue), var(--gli-purple));
  color: white;
  border-color: transparent;
}

/* 테이블 스타일 개선 */
.transactions-table {
  background: var(--bg-primary);
  border-radius: 16px;
  border: 1px solid var(--border-color);
  overflow: hidden;
}

.table-row {
  transition: all 0.3s;
}

.table-row:hover {
  background: rgba(59, 130, 246, 0.05);
  transform: translateX(4px);
}

/* 트랜잭션 타입 배지 개선 */
.transaction-type {
  display: inline-flex;
  align-items: center;
  gap: 0.5rem;
  padding: 0.5rem 1rem;
  border-radius: 20px;
  font-weight: 600;
  font-size: 0.85rem;
}

.transaction-type.p2p {
  background: linear-gradient(135deg, #10b981, #059669);
  color: white;
}

.transaction-type.swap {
  background: linear-gradient(135deg, #3b82f6, #2563eb);
  color: white;
}

.transaction-type.deposit {
  background: linear-gradient(135deg, #8b5cf6, #7c3aed);
  color: white;
}

.transaction-type.withdrawal {
  background: linear-gradient(135deg, #f59e0b, #d97706);
  color: white;
}

/* From → To 화살표 개선 */
.transaction-details {
  display: flex;
  align-items: center;
  gap: 0.75rem;
}

.transaction-details .arrow {
  color: var(--gli-blue);
  font-weight: 700;
}

/* 금액 표시 개선 */
.amount {
  font-family: 'Courier New', monospace;
  font-weight: 700;
  font-size: 1.1rem;
}

.amount.positive {
  color: var(--gli-green);
}

.amount.negative {
  color: var(--gli-orange);
}

/* 해시 버튼 개선 */
.hash-btn {
  padding: 0.5rem 1rem;
  background: rgba(59, 130, 246, 0.1);
  border: 1px solid var(--gli-blue);
  color: var(--gli-blue);
  border-radius: 8px;
  cursor: pointer;
  font-family: 'Courier New', monospace;
  font-size: 0.85rem;
  transition: all 0.3s;
}

.hash-btn:hover {
  background: var(--gli-blue);
  color: white;
  transform: translateY(-2px);
}
</style>
```

---

## 4. 요약

- ✅ 기능 변경 없음
- ✅ UI 스타일만 개선
- ✅ 필터 버튼, 테이블, 배지 디자인
- ⏱️ 예상 시간: 2시간

---

**다음 문서:** [탭 9: Wallet](./mypage_spec_tab9_wallet.md)
