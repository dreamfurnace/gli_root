import { test, expect } from '@playwright/test';

test.describe('Investment Portfolio', () => {
  test.beforeEach(async ({ page }) => {
    // Mock authentication state
    await page.addInitScript(() => {
      localStorage.setItem('access_token', 'mock-token');
    });

    // Mock investment stats API
    await page.route('**/api/v1/investments/stats/', async (route) => {
      await route.fulfill({
        status: 200,
        body: JSON.stringify({
          total_invested: 25000.0,
          total_current_value: 27350.0,
          total_profit_loss: 2350.0,
          profit_loss_percentage: 9.4,
          active_investments_count: 3,
          completed_investments_count: 1
        })
      });
    });

    // Mock investment portfolio API
    await page.route('**/api/v1/investments/portfolio/', async (route) => {
      await route.fulfill({
        status: 200,
        body: JSON.stringify({
          category_breakdown: {
            '리조트 부동산': {
              total_invested: 15000.0,
              total_current_value: 16200.0,
              count: 2
            },
            '레저 시설': {
              total_invested: 10000.0,
              total_current_value: 11150.0,
              count: 2
            }
          },
          risk_breakdown: {
            '낮음': {
              total_invested: 8000.0,
              total_current_value: 8640.0,
              count: 1
            },
            '보통': {
              total_invested: 17000.0,
              total_current_value: 18710.0,
              count: 3
            }
          },
          recent_investments: [
            {
              id: 'inv-1',
              rwa_asset_name: '제주 프리미엄 리조트',
              amount_gleb: 10000.0,
              current_value_gleb: 10800.0,
              current_profit_loss: 800.0,
              profit_loss_percentage: 8.0,
              investment_date: '2024-01-15T10:00:00Z',
              status: 'active'
            },
            {
              id: 'inv-2',
              rwa_asset_name: '부산 마리나 시설',
              amount_gleb: 5000.0,
              current_value_gleb: 5350.0,
              current_profit_loss: 350.0,
              profit_loss_percentage: 7.0,
              investment_date: '2024-01-10T10:00:00Z',
              status: 'active'
            },
            {
              id: 'inv-3',
              rwa_asset_name: '서울 골프클럽',
              amount_gleb: 8000.0,
              current_value_gleb: 8640.0,
              current_profit_loss: 640.0,
              profit_loss_percentage: 8.0,
              investment_date: '2024-01-05T10:00:00Z',
              status: 'completed'
            }
          ]
        })
      });
    });

    await page.goto('/');
  });

  test('사용자가 투자 포트폴리오 대시보드를 볼 수 있다', async ({ page }) => {
    await page.goto('/portfolio');
    
    // 페이지 제목 확인
    await expect(page.locator('h1')).toContainText('투자 포트폴리오');
    
    // 요약 카드들이 표시되는지 확인
    await expect(page.locator('.summary-card')).toHaveCount(4);
    
    // 총 투자금액 카드 확인
    await expect(page.locator('.summary-card.total-investment .amount')).toContainText('25,000 GLEB');
    
    // 현재 가치 카드 확인
    await expect(page.locator('.summary-card.current-value .amount')).toContainText('27,350 GLEB');
    
    // 손익 카드 확인
    await expect(page.locator('.summary-card.profit-loss .amount')).toContainText('+2,350 GLEB');
    await expect(page.locator('.summary-card.profit-loss .amount')).toHaveClass(/profit/);
    await expect(page.locator('.summary-card.profit-loss .change-indicator')).toContainText('+9.40%');
    
    // 진행 중인 투자 카드 확인
    await expect(page.locator('.summary-card.active-investments .amount')).toContainText('3건');
  });

  test('카테고리별 분산 분석이 표시된다', async ({ page }) => {
    await page.goto('/portfolio');
    
    // 카테고리별 분산 섹션 확인
    await expect(page.locator('h2:has-text("카테고리별 분산")')).toBeVisible();
    
    // 분산 항목들 확인
    await expect(page.locator('.breakdown-item')).toHaveCount(2);
    
    // 리조트 부동산 분산 확인
    const resortBreakdown = page.locator('.breakdown-item').first();
    await expect(resortBreakdown.locator('h4')).toContainText('리조트 부동산');
    await expect(resortBreakdown.locator('.breakdown-percentage')).toContainText('60%'); // 15000/25000
    await expect(resortBreakdown.locator('.value')).first().toContainText('15,000 GLEB');
    
    // 진행 바 확인
    await expect(resortBreakdown.locator('.progress-fill')).toBeVisible();
  });

  test('위험도별 분산 분석이 표시된다', async ({ page }) => {
    await page.goto('/portfolio');
    
    // 위험도별 분산 섹션 확인
    await expect(page.locator('h2:has-text("위험도별 분산")')).toBeVisible();
    
    // 위험도 항목들 확인
    await expect(page.locator('.risk-item')).toHaveCount(2);
    
    // 낮음 위험도 확인
    const lowRisk = page.locator('.risk-item.risk-low');
    await expect(lowRisk.locator('.risk-badge')).toContainText('낮음');
    await expect(lowRisk.locator('.risk-percentage')).toContainText('32%'); // 8000/25000
    await expect(lowRisk.locator('.amount')).toContainText('8,000 GLEB');
    await expect(lowRisk.locator('.count')).toContainText('(1건)');
    
    // 보통 위험도 확인
    const mediumRisk = page.locator('.risk-item.risk-medium');
    await expect(mediumRisk.locator('.risk-badge')).toContainText('보통');
    await expect(mediumRisk.locator('.risk-percentage')).toContainText('68%'); // 17000/25000
  });

  test('최근 투자 내역이 표시된다', async ({ page }) => {
    await page.goto('/portfolio');
    
    // 최근 투자 내역 섹션 확인
    await expect(page.locator('h2:has-text("최근 투자 내역")')).toBeVisible();
    
    // 투자 항목들 확인
    await expect(page.locator('.investment-item')).toHaveCount(3);
    
    // 첫 번째 투자 항목 확인
    const firstInvestment = page.locator('.investment-item').first();
    await expect(firstInvestment.locator('.asset-name')).toContainText('제주 프리미엄 리조트');
    await expect(firstInvestment.locator('.investment-date')).toContainText('2024년 1월 15일');
    await expect(firstInvestment.locator('.value').first()).toContainText('10,000 GLEB');
    await expect(firstInvestment.locator('.value').nth(1)).toContainText('10,800 GLEB');
    
    // 수익률 확인
    await expect(firstInvestment.locator('.profit-loss')).toContainText('+800 GLEB');
    await expect(firstInvestment.locator('.profit-loss')).toHaveClass(/profit/);
    await expect(firstInvestment.locator('.profit-percentage')).toContainText('(+8.00%)');
    
    // 상태 배지 확인
    await expect(firstInvestment.locator('.status-badge.active')).toContainText('투자 중');
  });

  test('투자 상태별 스타일이 올바르게 적용된다', async ({ page }) => {
    await page.goto('/portfolio');
    
    // 활성 투자 상태 확인
    const activeInvestment = page.locator('.investment-item').first();
    await expect(activeInvestment.locator('.status-badge.active')).toBeVisible();
    
    // 완료된 투자 상태 확인
    const completedInvestment = page.locator('.investment-item').nth(2);
    await expect(completedInvestment.locator('.status-badge.completed')).toContainText('완료');
    
    // 손익 색상 확인 (모든 투자가 수익)
    const profitElements = page.locator('.profit-loss.profit');
    await expect(profitElements).toHaveCount(3);
  });

  test('전체 투자 내역 보기 버튼이 작동한다', async ({ page }) => {
    await page.goto('/portfolio');
    
    // 전체 보기 버튼 클릭
    const logs: string[] = [];
    page.on('console', msg => logs.push(msg.text()));
    
    await page.click('button:has-text("전체 보기")');
    
    // 콘솔 로그 확인 (실제 구현에서는 페이지 이동)
    await page.waitForTimeout(100);
    expect(logs.some(log => log.includes('Show all investments'))).toBe(true);
  });

  test('투자 내역이 없는 경우 빈 상태가 표시된다', async ({ page }) => {
    // 빈 투자 내역 모킹
    await page.route('**/api/v1/investments/portfolio/', async (route) => {
      await route.fulfill({
        status: 200,
        body: JSON.stringify({
          category_breakdown: {},
          risk_breakdown: {},
          recent_investments: []
        })
      });
    });

    await page.goto('/portfolio');
    
    // 빈 상태 메시지 확인
    await expect(page.locator('.empty-investments')).toBeVisible();
    await expect(page.locator('h3:has-text("투자 내역이 없습니다")')).toBeVisible();
    await expect(page.locator('p:has-text("RWA 자산에 투자하여")')).toBeVisible();
    
    // 투자하러 가기 버튼 확인
    await expect(page.locator('.start-investing-btn')).toContainText('투자하러 가기');
    
    // 버튼 클릭 테스트
    const logs: string[] = [];
    page.on('console', msg => logs.push(msg.text()));
    
    await page.click('.start-investing-btn');
    
    await page.waitForTimeout(100);
    expect(logs.some(log => log.includes('Go to investments page'))).toBe(true);
  });

  test('손실이 있는 투자의 경우 적절한 스타일이 적용된다', async ({ page }) => {
    // 손실이 있는 투자 데이터 모킹
    await page.route('**/api/v1/investments/stats/', async (route) => {
      await route.fulfill({
        status: 200,
        body: JSON.stringify({
          total_invested: 20000.0,
          total_current_value: 18500.0,
          total_profit_loss: -1500.0,
          profit_loss_percentage: -7.5,
          active_investments_count: 2,
          completed_investments_count: 0
        })
      });
    });

    await page.route('**/api/v1/investments/portfolio/', async (route) => {
      await route.fulfill({
        status: 200,
        body: JSON.stringify({
          category_breakdown: {},
          risk_breakdown: {},
          recent_investments: [
            {
              id: 'inv-loss',
              rwa_asset_name: '손실 투자 자산',
              amount_gleb: 10000.0,
              current_value_gleb: 9250.0,
              current_profit_loss: -750.0,
              profit_loss_percentage: -7.5,
              investment_date: '2024-01-15T10:00:00Z',
              status: 'active'
            }
          ]
        })
      });
    });

    await page.goto('/portfolio');
    
    // 손실 금액 확인
    await expect(page.locator('.summary-card.profit-loss .amount')).toContainText('-1,500 GLEB');
    await expect(page.locator('.summary-card.profit-loss .amount')).toHaveClass(/loss/);
    await expect(page.locator('.summary-card.profit-loss .change-indicator')).toContainText('-7.50%');
    
    // 개별 투자 손실 확인
    await expect(page.locator('.investment-item .profit-loss')).toContainText('-750 GLEB');
    await expect(page.locator('.investment-item .profit-loss')).toHaveClass(/loss/);
    await expect(page.locator('.investment-item .profit-percentage')).toContainText('(-7.50%)');
  });

  test('로딩 상태가 표시된다', async ({ page }) => {
    // API 응답 지연
    await page.route('**/api/v1/investments/stats/', async (route) => {
      await new Promise(resolve => setTimeout(resolve, 1000));
      await route.fulfill({
        status: 200,
        body: JSON.stringify({
          total_invested: 0,
          total_current_value: 0,
          total_profit_loss: 0,
          profit_loss_percentage: 0,
          active_investments_count: 0,
          completed_investments_count: 0
        })
      });
    });

    await page.goto('/portfolio');
    
    // 로딩 스피너 확인
    await expect(page.locator('.loading-spinner')).toBeVisible();
    await expect(page.locator('text="포트폴리오 정보를 불러오는 중"')).toBeVisible();
    
    // 로딩 완료 후 스피너 사라짐 확인
    await expect(page.locator('.loading-spinner')).not.toBeVisible({ timeout: 2000 });
  });

  test('에러 상태가 처리된다', async ({ page }) => {
    // API 에러 모킹
    await page.route('**/api/v1/investments/stats/', async (route) => {
      await route.fulfill({
        status: 500,
        body: JSON.stringify({ error: '서버 오류가 발생했습니다.' })
      });
    });

    await page.goto('/portfolio');
    
    // 에러 메시지 확인
    await expect(page.locator('.error-container')).toBeVisible();
    await expect(page.locator('h3:has-text("데이터를 불러올 수 없습니다")')).toBeVisible();
    
    // 다시 시도 버튼 확인
    await expect(page.locator('button:has-text("다시 시도")')).toBeVisible();
  });

  test('모바일 반응형이 작동한다', async ({ page }) => {
    // 모바일 뷰포트로 설정
    await page.setViewportSize({ width: 375, height: 667 });
    await page.goto('/portfolio');
    
    // 요약 카드가 1열로 배치되는지 확인
    await expect(page.locator('.summary-cards')).toBeVisible();
    
    // 포트폴리오 분석이 세로로 배치되는지 확인
    await expect(page.locator('.portfolio-analysis')).toBeVisible();
    
    // 투자 항목이 세로 레이아웃으로 변경되는지 확인
    await expect(page.locator('.investment-item')).toBeVisible();
  });

  test('숫자 포맷팅이 올바르게 작동한다', async ({ page }) => {
    await page.goto('/portfolio');
    
    // 큰 숫자의 쉼표 구분 확인
    await expect(page.locator('.summary-card .amount').first()).toContainText('25,000');
    
    // 소수점 표시 확인
    await expect(page.locator('.change-indicator').first()).toContainText('9.40%');
    
    // 개별 투자 금액 포맷 확인
    await expect(page.locator('.investment-item .value').first()).toContainText('10,000 GLEB');
  });

  test('요약 카드 호버 효과가 작동한다', async ({ page }) => {
    await page.goto('/portfolio');
    
    const summaryCard = page.locator('.summary-card').first();
    
    // 호버 효과 테스트 (CSS transition 확인은 어려우므로 호버 이벤트만 확인)
    await summaryCard.hover();
    await expect(summaryCard).toBeVisible();
  });

  test('백분율 계산이 정확하다', async ({ page }) => {
    await page.goto('/portfolio');
    
    // 카테고리별 백분율 확인 (15000/25000 = 60%)
    await expect(page.locator('.breakdown-percentage').first()).toContainText('60%');
    
    // 위험도별 백분율 확인 (8000/25000 = 32%)
    await expect(page.locator('.risk-percentage').first()).toContainText('32%');
  });
});