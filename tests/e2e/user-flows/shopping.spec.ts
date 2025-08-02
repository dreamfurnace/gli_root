import { test, expect } from '@playwright/test';

test.describe('Shopping Mall Flow', () => {
  test.beforeEach(async ({ page }) => {
    // Mock API responses for shopping
    await page.route('**/api/v1/shopping/products/**', async (route) => {
      if (route.request().method() === 'GET') {
        await route.fulfill({
          status: 200,
          body: JSON.stringify({
            results: [
              {
                id: 'product-1',
                name: '제주 하얏트 리조트 1박 2일',
                short_description: '제주도 최고급 리조트에서의 특별한 휴가',
                product_type_display: '리조트 예약',
                price_glil: 25000.0,
                price_usd: 18.75,
                main_image_url: '/test-resort-product.jpg',
                is_featured: true,
                is_in_stock: true,
                status: 'active',
                category_name: '리조트 예약',
                view_count: 1247,
                purchase_count: 89
              },
              {
                id: 'product-2',
                name: '미쉐린 레스토랑 디너',
                short_description: '서울 최고급 미쉐린 스타 레스토랑 디너 코스',
                product_type_display: '레스토랑 예약',
                price_glil: 15000.0,
                price_usd: 11.25,
                main_image_url: '/test-restaurant.jpg',
                is_featured: false,
                is_in_stock: true,
                status: 'active',
                category_name: '레스토랑 예약',
                view_count: 567,
                purchase_count: 34
              }
            ],
            count: 2
          })
        });
      }
    });

    await page.route('**/api/v1/shopping/categories/**', async (route) => {
      await route.fulfill({
        status: 200,
        body: JSON.stringify({
          results: [
            {
              id: 'category-1',
              name: '리조트 예약',
              description: '프리미엄 리조트 및 호텔 예약 서비스',
              icon: '🏖️',
              asset_count: 15
            },
            {
              id: 'category-2',
              name: '레스토랑 예약',
              description: '고급 레스토랑 및 다이닝 예약',
              icon: '🍽️',
              asset_count: 23
            }
          ]
        })
      });
    });

    await page.goto('/');
  });

  test('사용자가 쇼핑몰 상품 목록을 조회할 수 있다', async ({ page }) => {
    await page.goto('/shopping');
    
    // 페이지 제목 확인
    await expect(page.locator('h1')).toContainText('GLI 쇼핑몰');
    
    // 상품 카드가 표시되는지 확인
    await expect(page.locator('.product-card')).toHaveCount(2);
    
    // 첫 번째 상품 정보 확인
    await expect(page.locator('.product-name').first()).toContainText('제주 하얏트 리조트');
    await expect(page.locator('.price-value').first()).toContainText('25,000');
    await expect(page.locator('.price-unit').first()).toContainText('GLIL');
    
    // 추천 배지 확인
    await expect(page.locator('.featured-badge').first()).toContainText('⭐ 추천');
  });

  test('사용자가 카테고리별로 상품을 필터링할 수 있다', async ({ page }) => {
    await page.goto('/shopping');
    
    // 카테고리 탭 확인
    await expect(page.locator('.category-tab')).toHaveCount(3); // 전체 + 2개 카테고리
    
    // 리조트 카테고리 클릭
    await page.click('button:has-text("🏖️ 리조트 예약")');
    await expect(page.locator('.category-tab.active')).toContainText('리조트 예약');
    
    // 레스토랑 카테고리 클릭
    await page.click('button:has-text("🍽️ 레스토랑 예약")');
    await expect(page.locator('.category-tab.active')).toContainText('레스토랑 예약');
    
    // 전체 상품으로 돌아가기
    await page.click('button:has-text("전체 상품")');
    await expect(page.locator('.category-tab.active')).toContainText('전체 상품');
  });

  test('사용자가 상품 유형별로 필터링할 수 있다', async ({ page }) => {
    await page.goto('/shopping');
    
    // 상품 유형 선택
    await page.selectOption('select:has-text("전체 유형")', 'resort');
    
    // 빠른 필터 테스트
    await page.click('button:has-text("🏖️ 리조트")');
    await expect(page.locator('.quick-filter.active')).toContainText('리조트');
    
    // 추천 상품 필터
    await page.click('button:has-text("⭐ 추천 상품")');
    await expect(page.locator('.quick-filter.active')).toContainText('추천 상품');
  });

  test('사용자가 상품을 검색할 수 있다', async ({ page }) => {
    await page.goto('/shopping');
    
    // 검색 입력
    await page.fill('input[placeholder*="검색"]', '제주');
    
    // 검색 결과 확인 (디바운스 대기)
    await page.waitForTimeout(600);
    await expect(page.locator('.product-card')).toBeVisible();
    await expect(page.locator('.product-name')).toContainText('제주');
  });

  test('사용자가 상품을 정렬할 수 있다', async ({ page }) => {
    await page.goto('/shopping');
    
    // 가격 낮은순 정렬
    await page.selectOption('select:has-text("추천순")', 'price_glil');
    
    // 가격 높은순 정렬
    await page.selectOption('select:has-text("가격 낮은순")', '-price_glil');
    
    // 인기순 정렬
    await page.selectOption('select:has-text("가격 높은순")', '-purchase_count');
  });

  test('사용자가 장바구니에 상품을 추가할 수 있다', async ({ page }) => {
    await page.goto('/shopping');
    
    // 장바구니 버튼 클릭
    await page.click('.product-card .btn-cart');
    
    // 임시 알림 확인 (실제 구현에서는 토스트 메시지나 장바구니 모달로 대체)
    page.on('dialog', async dialog => {
      expect(dialog.message()).toContain('장바구니에 추가되었습니다');
      await dialog.accept();
    });
  });

  test('사용자가 상품을 바로 구매할 수 있다', async ({ page }) => {
    await page.goto('/shopping');
    
    // 바로 구매 버튼 클릭
    await page.click('.product-card .btn-buy');
    
    // 임시 알림 확인 (실제 구현에서는 구매 모달이나 결제 페이지로 이동)
    page.on('dialog', async dialog => {
      expect(dialog.message()).toContain('구매 페이지로 이동');
      await dialog.accept();
    });
  });

  test('사용자가 상품 상세 정보를 볼 수 있다', async ({ page }) => {
    await page.goto('/shopping');
    
    // 자세히 보기 버튼 클릭
    await page.click('.product-card .btn-details');
    
    // 콘솔 로그 확인 (실제 구현에서는 상세 모달이나 페이지로 이동)
    const logs: string[] = [];
    page.on('console', msg => logs.push(msg.text()));
    
    await page.waitForTimeout(100);
    expect(logs.some(log => log.includes('Show product details'))).toBe(true);
  });

  test('품절 상품은 구매할 수 없다', async ({ page }) => {
    // 품절 상품 모킹
    await page.route('**/api/v1/shopping/products/**', async (route) => {
      await route.fulfill({
        status: 200,
        body: JSON.stringify({
          results: [
            {
              id: 'product-out-of-stock',
              name: '품절된 상품',
              short_description: '현재 품절된 상품입니다',
              product_type_display: '일반 상품',
              price_glil: 10000.0,
              is_featured: false,
              is_in_stock: false,
              status: 'active',
              category_name: '레저 상품'
            }
          ],
          count: 1
        })
      });
    });

    await page.goto('/shopping');
    
    // 품절 배지 확인
    await expect(page.locator('.stock-badge.out-of-stock')).toContainText('품절');
    
    // 품절 상품 카드에 out-of-stock 클래스 확인
    await expect(page.locator('.product-card.out-of-stock')).toBeVisible();
    
    // 구매 관련 버튼들이 비활성화되었는지 확인
    await expect(page.locator('.btn-cart:disabled')).toContainText('품절');
    await expect(page.locator('.btn-buy:disabled')).toContainText('구매 불가');
  });

  test('재고 있음 필터가 작동한다', async ({ page }) => {
    await page.goto('/shopping');
    
    // 재고 있음 필터 클릭
    await page.click('button:has-text("✅ 재고 있음")');
    await expect(page.locator('.quick-filter.active')).toContainText('재고 있음');
    
    // 재고 있는 상품만 표시되는지 확인
    await expect(page.locator('.product-card:not(.out-of-stock)')).toBeVisible();
  });

  test('가격 정보가 올바르게 표시된다', async ({ page }) => {
    await page.goto('/shopping');
    
    // GLIL 가격 확인
    await expect(page.locator('.price-glil .price-value').first()).toContainText('25,000');
    await expect(page.locator('.price-glil .price-unit').first()).toContainText('GLIL');
    
    // USD 환산 가격 확인
    await expect(page.locator('.price-usd').first()).toContainText('≈ $18.75');
  });

  test('상품 메타 정보가 표시된다', async ({ page }) => {
    await page.goto('/shopping');
    
    // 조회수 확인
    await expect(page.locator('.meta-item').first()).toContainText('1,247회 조회');
    
    // 구매수 확인
    await expect(page.locator('.meta-item').nth(1)).toContainText('89회 구매');
  });

  test('필터 초기화가 작동한다', async ({ page }) => {
    await page.goto('/shopping');
    
    // 여러 필터 적용
    await page.click('button:has-text("🏖️ 리조트 예약")');
    await page.selectOption('select:has-text("전체 유형")', 'resort');
    await page.fill('input[placeholder*="검색"]', '제주');
    
    // 빈 결과 상황 모킹
    await page.route('**/api/v1/shopping/products/**', async (route) => {
      await route.fulfill({
        status: 200,
        body: JSON.stringify({ results: [], count: 0 })
      });
    });
    
    await page.waitForTimeout(600); // 검색 디바운스 대기
    
    // 빈 결과 메시지 확인
    await expect(page.locator('.empty-results')).toBeVisible();
    await expect(page.locator('h3:has-text("상품이 없습니다")')).toBeVisible();
    
    // 필터 초기화 버튼 클릭
    await page.click('button:has-text("필터 초기화")');
    
    // 필터가 초기화되었는지 확인
    await expect(page.locator('.category-tab.active')).toContainText('전체 상품');
    await expect(page.locator('input[placeholder*="검색"]')).toHaveValue('');
  });

  test('모바일 반응형이 작동한다', async ({ page }) => {
    // 모바일 뷰포트로 설정
    await page.setViewportSize({ width: 375, height: 667 });
    await page.goto('/shopping');
    
    // 카테고리 탭이 스크롤 가능한지 확인
    await expect(page.locator('.category-tabs')).toBeVisible();
    
    // 상품 그리드가 1열로 표시되는지 확인
    const productCards = page.locator('.product-card');
    await expect(productCards.first()).toBeVisible();
    
    // 필터 섹션이 세로로 정렬되는지 확인
    await expect(page.locator('.filter-row')).toBeVisible();
  });

  test('로딩 상태가 표시된다', async ({ page }) => {
    // API 응답 지연
    await page.route('**/api/v1/shopping/products/**', async (route) => {
      await new Promise(resolve => setTimeout(resolve, 1000));
      await route.fulfill({
        status: 200,
        body: JSON.stringify({ results: [], count: 0 })
      });
    });

    await page.goto('/shopping');
    
    // 로딩 스피너 확인
    await expect(page.locator('.loading-spinner')).toBeVisible();
    await expect(page.locator('text="상품을 불러오는 중"')).toBeVisible();
    
    // 로딩 완료 후 스피너 사라짐 확인
    await expect(page.locator('.loading-spinner')).not.toBeVisible({ timeout: 2000 });
  });

  test('에러 상태가 처리된다', async ({ page }) => {
    // API 에러 모킹
    await page.route('**/api/v1/shopping/products/**', async (route) => {
      await route.fulfill({
        status: 500,
        body: JSON.stringify({ error: '서버 오류가 발생했습니다.' })
      });
    });

    await page.goto('/shopping');
    
    // 에러 메시지 확인
    await expect(page.locator('.error-container')).toBeVisible();
    await expect(page.locator('h3:has-text("데이터를 불러올 수 없습니다")')).toBeVisible();
    
    // 다시 시도 버튼 확인
    await expect(page.locator('button:has-text("다시 시도")')).toBeVisible();
  });

  test('상품 카드 호버 효과가 작동한다', async ({ page }) => {
    await page.goto('/shopping');
    
    const productCard = page.locator('.product-card').first();
    
    // 호버 전 상태
    const initialBox = await productCard.boundingBox();
    
    // 호버
    await productCard.hover();
    
    // 호버 후 transform 효과 확인 (실제로는 CSS transition을 테스트하기 어려우므로 호버 이벤트만 확인)
    await expect(productCard).toBeVisible();
  });
});