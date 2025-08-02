import { test, expect } from '@playwright/test';

test.describe('GLI Admin Panel', () => {
  test('should load login page', async ({ page }) => {
    await page.goto('/');
    
    // 로그인 페이지가 로드되는지 확인
    await expect(page).toHaveTitle(/GLI/);
    await expect(page.locator('h2').first()).toContainText('GLI 관리자 로그인');
    
    // 환경 정보가 표시되는지 확인
    await expect(page.locator('text=ENV:')).toBeVisible();
    
    // 로그인 폼 요소들이 존재하는지 확인
    await expect(page.locator('input[id="username"]')).toBeVisible();
    await expect(page.locator('input[id="password"]')).toBeVisible();
    await expect(page.locator('button[type="submit"]')).toBeVisible();
  });

  test('should login with valid credentials', async ({ page }) => {
    await page.goto('/');
    
    // 로그인 폼 작성
    await page.fill('input[id="username"]', 'admin@gli.com');
    await page.fill('input[id="password"]', 'admin123!');
    
    // 로그인 버튼 클릭
    await page.click('button[type="submit"]');
    
    // 로그인 성공 후 대시보드로 리다이렉트되는지 확인
    await expect(page).toHaveURL(/.*\/admin/);
    
    // 대시보드 페이지가 로드될 때까지 대기 (최대 10초)
    await page.waitForTimeout(3000);
    
    // 대시보드 페이지 요소들이 로드되는지 확인 - 실제 컴포넌트 구조에 맞게 수정
    await expect(page.locator('.bg-slate-200, .bg-slate-800')).toBeVisible(); // 사이드바 확인
    await expect(page.locator('text=GLI 관리자 패널에 오신 것을 환영합니다')).toBeVisible();
    
    // 통계 카드들이 표시되는지 확인 (첫 번째 요소만 선택)
    await expect(page.locator('text=전체 멤버').first()).toBeVisible();
    await expect(page.locator('text=GLIB 토큰').first()).toBeVisible();
    await expect(page.locator('text=활성 거래').first()).toBeVisible();
    await expect(page.locator('text=플랫폼 성장률').first()).toBeVisible();
    
    // 사이드바가 표시되는지 확인 (첫 번째 요소만 선택)
    await expect(page.locator('text=멤버 관리').first()).toBeVisible();
    await expect(page.locator('text=토큰 관리').first()).toBeVisible();
  });

  test('should show error for invalid credentials', async ({ page }) => {
    await page.goto('/');
    
    // 잘못된 로그인 정보 입력
    await page.fill('input[id="username"]', 'invalid@gli.com');
    await page.fill('input[id="password"]', 'wrongpassword');
    
    // 로그인 버튼 클릭
    await page.click('button[type="submit"]');
    
    // 에러 메시지가 표시되는지 확인
    await expect(page.locator('.bg-red-50, .rounded-md.bg-red-50')).toBeVisible();
  });

  test('should navigate to different admin sections', async ({ page }) => {
    // 먼저 로그인
    await page.goto('/');
    await page.fill('input[id="username"]', 'admin@gli.com');
    await page.fill('input[id="password"]', 'admin123!');
    await page.click('button[type="submit"]');
    
    // 대시보드 로드 대기
    await page.waitForTimeout(3000);
    await expect(page.locator('.bg-slate-200, .bg-slate-800')).toBeVisible();
    
    // 사이드바 네비게이션 요소가 클릭 가능한지 확인
    const memberManagement = page.locator('text=멤버 관리').first();
    await expect(memberManagement).toBeVisible();
    await memberManagement.click();
    
    // 클릭 후 잠시 대기 (네비게이션 확인)
    await page.waitForTimeout(1000);
    
    // 토큰 관리도 확인
    const tokenManagement = page.locator('text=토큰 관리').first();
    await expect(tokenManagement).toBeVisible();
    await tokenManagement.click();
    
    // 네비게이션이 작동하는지 확인
    await page.waitForTimeout(1000);
  });
});