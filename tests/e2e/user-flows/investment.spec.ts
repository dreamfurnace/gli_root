import { test, expect } from '@playwright/test';

test.describe('RWA Investment Flow', () => {
  test.beforeEach(async ({ page }) => {
    // 로그인 상태로 설정 (실제 환경에서는 로그인 플로우 구현)
    await page.goto('/');
    
    // Mock API responses for testing
    await page.route('**/api/v1/rwa/assets/**', async (route) => {
      if (route.request().method() === 'GET') {
        await route.fulfill({
          status: 200,
          body: JSON.stringify({
            results: [
              {
                id: 'test-asset-1',
                name: '제주 프리미엄 리조트',
                short_description: '제주도 해안가에 위치한 프리미엄 리조트 투자',
                expected_apy: 8.5,
                risk_level: 'medium',
                risk_level_display: '보통',
                min_investment_gleb: 1000,
                max_investment_gleb: 50000,
                main_image_url: '/test-resort.jpg',
                funding_progress: 65.5,
                is_featured: true,
                status: 'active',
                category_name: '리조트 부동산'
              }
            ],
            count: 1
          })
        });
      }
    });

    await page.route('**/api/v1/rwa/categories/**', async (route) => {
      await route.fulfill({
        status: 200,
        body: JSON.stringify({
          results: [
            {
              id: 'category-1',
              name: '리조트 부동산',
              description: '리조트 및 호텔 부동산 투자',
              icon: '🏢',
              asset_count: 5
            }
          ]
        })
      });
    });
  });

  test('사용자가 RWA 투자 자산 목록을 조회할 수 있다', async ({ page }) => {
    await page.goto('/rwa-assets');
    
    // 페이지 제목 확인
    await expect(page.locator('h1')).toContainText('RWA 투자 자산 목록');
    
    // 자산 카드가 표시되는지 확인
    await expect(page.locator('.asset-card')).toBeVisible();
    await expect(page.locator('.asset-name')).toContainText('제주 프리미엄 리조트');
    
    // 투자 정보가 올바르게 표시되는지 확인
    await expect(page.locator('.metric-value.apy')).toContainText('8.5%');
    await expect(page.locator('.risk-badge.risk-medium')).toContainText('보통');
  });

  test('사용자가 자산을 필터링할 수 있다', async ({ page }) => {
    await page.goto('/rwa-assets');
    
    // 카테고리 필터 테스트
    await page.selectOption('select:has-text("전체 카테고리")', 'category-1');
    await expect(page.locator('.asset-card')).toBeVisible();
    
    // 위험도 필터 테스트
    await page.selectOption('select:has-text("전체 위험도")', 'medium');
    await expect(page.locator('.asset-card')).toBeVisible();
    
    // 빠른 필터 테스트
    await page.click('button:has-text("⭐ 추천 자산")');
    await expect(page.locator('.quick-filter.active')).toContainText('추천 자산');
  });

  test('사용자가 자산을 검색할 수 있다', async ({ page }) => {
    await page.goto('/rwa-assets');
    
    // 검색 입력
    await page.fill('input[placeholder*="검색"]', '제주');
    
    // 검색 결과 확인 (디바운스 대기)
    await page.waitForTimeout(600);
    await expect(page.locator('.asset-card')).toBeVisible();
    await expect(page.locator('.asset-name')).toContainText('제주');
  });

  test('사용자가 투자 모달을 열고 투자할 수 있다', async ({ page }) => {
    // 투자 API 모킹
    await page.route('**/api/v1/rwa/assets/test-asset-1/invest/', async (route) => {
      await route.fulfill({
        status: 201,
        body: JSON.stringify({
          id: 'investment-1',
          amount_gleb: 5000,
          status: 'confirmed',
          investment_date: new Date().toISOString()
        })
      });
    });

    await page.goto('/rwa-assets');
    
    // 투자하기 버튼 클릭
    await page.click('button:has-text("투자하기")');
    
    // 투자 모달이 열렸는지 확인
    await expect(page.locator('.modal-overlay')).toBeVisible();
    await expect(page.locator('.modal-content h2')).toContainText('투자하기');
    
    // 자산 정보가 표시되는지 확인
    await expect(page.locator('.asset-name')).toContainText('제주 프리미엄 리조트');
    await expect(page.locator('.value.apy')).toContainText('8.5%');
    
    // 투자 금액 입력
    await page.fill('input#investment-amount', '5000');
    
    // 예상 수익이 계산되는지 확인
    await expect(page.locator('.returns-preview')).toBeVisible();
    await expect(page.locator('.return-item .value')).toContainText('5000');
    
    // 약관 동의
    await page.check('input[type="checkbox"]:has-text("투자 약관")');
    await page.check('input[type="checkbox"]:has-text("투자 위험")');
    
    // 투자 버튼이 활성화되는지 확인
    await expect(page.locator('.btn-invest')).not.toBeDisabled();
    
    // 투자 실행
    await page.click('.btn-invest');
    
    // 성공 메시지 확인
    await expect(page.locator('.success-message')).toContainText('투자가 성공적으로 완료');
    
    // 모달이 자동으로 닫히는지 확인 (3초 대기)
    await page.waitForTimeout(3500);
    await expect(page.locator('.modal-overlay')).not.toBeVisible();
  });

  test('투자 금액 유효성 검사가 작동한다', async ({ page }) => {
    await page.goto('/rwa-assets');
    await page.click('button:has-text("투자하기")');
    
    // 최소 금액보다 적게 입력
    await page.fill('input#investment-amount', '500');
    await page.check('input[type="checkbox"]:has-text("투자 약관")');
    await page.check('input[type="checkbox"]:has-text("투자 위험")');
    
    // 투자 버튼이 비활성화되어야 함
    await expect(page.locator('.btn-invest')).toBeDisabled();
    
    // 올바른 금액 입력
    await page.fill('input#investment-amount', '2000');
    
    // 투자 버튼이 활성화되어야 함
    await expect(page.locator('.btn-invest')).not.toBeDisabled();
  });

  test('사용자가 모달을 닫을 수 있다', async ({ page }) => {
    await page.goto('/rwa-assets');
    await page.click('button:has-text("투자하기")');
    
    // 모달이 열렸는지 확인
    await expect(page.locator('.modal-overlay')).toBeVisible();
    
    // X 버튼으로 닫기
    await page.click('.close-btn');
    await expect(page.locator('.modal-overlay')).not.toBeVisible();
    
    // 다시 모달 열기
    await page.click('button:has-text("투자하기")');
    await expect(page.locator('.modal-overlay')).toBeVisible();
    
    // 취소 버튼으로 닫기
    await page.click('button:has-text("취소")');
    await expect(page.locator('.modal-overlay')).not.toBeVisible();
    
    // 다시 모달 열기
    await page.click('button:has-text("투자하기")');
    await expect(page.locator('.modal-overlay')).toBeVisible();
    
    // 오버레이 클릭으로 닫기
    await page.click('.modal-overlay', { position: { x: 10, y: 10 } });
    await expect(page.locator('.modal-overlay')).not.toBeVisible();
  });

  test('페이지네이션이 작동한다', async ({ page }) => {
    // 여러 페이지가 있는 상황을 모킹
    await page.route('**/api/v1/rwa/assets/**', async (route) => {
      const url = new URL(route.request().url());
      const page_param = url.searchParams.get('page') || '1';
      
      await route.fulfill({
        status: 200,
        body: JSON.stringify({
          results: Array.from({ length: 12 }, (_, i) => ({
            id: `asset-${page_param}-${i}`,
            name: `투자 자산 ${page_param}-${i + 1}`,
            short_description: '테스트 자산입니다',
            expected_apy: 7.5,
            risk_level: 'low',
            risk_level_display: '낮음',
            min_investment_gleb: 1000,
            status: 'active',
            category_name: '테스트 카테고리'
          })),
          count: 25 // 총 25개로 설정하여 3페이지 생성
        })
      });
    });

    await page.goto('/rwa-assets');
    
    // 첫 번째 페이지 확인
    await expect(page.locator('.page-btn.active')).toContainText('1');
    
    // 두 번째 페이지로 이동
    await page.click('button:has-text("2")');
    await expect(page.locator('.page-btn.active')).toContainText('2');
    
    // 다음 버튼 테스트  
    await page.click('button:has-text("다음")');
    await expect(page.locator('.page-btn.active')).toContainText('3');
    
    // 이전 버튼 테스트
    await page.click('button:has-text("이전")');
    await expect(page.locator('.page-btn.active')).toContainText('2');
  });

  test('로딩 상태가 표시된다', async ({ page }) => {
    // API 응답을 지연시켜 로딩 상태 테스트
    await page.route('**/api/v1/rwa/assets/**', async (route) => {
      await new Promise(resolve => setTimeout(resolve, 1000));
      await route.fulfill({
        status: 200,
        body: JSON.stringify({ results: [], count: 0 })
      });
    });

    await page.goto('/rwa-assets');
    
    // 로딩 스피너가 표시되는지 확인
    await expect(page.locator('.loading-spinner')).toBeVisible();
    await expect(page.locator('text="투자 자산을 불러오는 중"')).toBeVisible();
    
    // 로딩이 완료되면 스피너가 사라지는지 확인
    await expect(page.locator('.loading-spinner')).not.toBeVisible({ timeout: 2000 });
  });

  test('에러 상태가 처리된다', async ({ page }) => {
    // API 에러 모킹
    await page.route('**/api/v1/rwa/assets/**', async (route) => {
      await route.fulfill({
        status: 500,
        body: JSON.stringify({ error: '서버 오류가 발생했습니다.' })
      });
    });

    await page.goto('/rwa-assets');
    
    // 에러 메시지가 표시되는지 확인
    await expect(page.locator('.error-container')).toBeVisible();
    await expect(page.locator('h3:has-text("데이터를 불러올 수 없습니다")')).toBeVisible();
    
    // 다시 시도 버튼이 있는지 확인
    await expect(page.locator('button:has-text("다시 시도")')).toBeVisible();
  });

  test('빈 결과 상태가 표시된다', async ({ page }) => {
    // 빈 결과 모킹
    await page.route('**/api/v1/rwa/assets/**', async (route) => {
      await route.fulfill({
        status: 200,
        body: JSON.stringify({ results: [], count: 0 })
      });
    });

    await page.goto('/rwa-assets');
    
    // 빈 결과 메시지가 표시되는지 확인
    await expect(page.locator('.empty-results')).toBeVisible();
    await expect(page.locator('h3:has-text("검색 결과가 없습니다")')).toBeVisible();
    
    // 필터 초기화 버튼이 있는지 확인
    await expect(page.locator('button:has-text("필터 초기화")')).toBeVisible();
  });
});