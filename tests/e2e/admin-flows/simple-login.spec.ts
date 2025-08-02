import { test, expect } from '@playwright/test';

test.describe('Simple Login Test', () => {
  test('verify login and dashboard content', async ({ page }) => {
    // 콘솔 로그 수집 (처음부터)
    page.on('console', msg => {
      console.log('Browser console:', msg.text());
    });
    
    await page.goto('/login');
    
    // 로그인
    await page.fill('input[id="username"]', 'admin@gli.com');
    await page.fill('input[id="password"]', 'admin123!');
    await page.click('button[type="submit"]');
    
    // URL 변경 확인
    await expect(page).toHaveURL(/.*\/admin/);
    
    // 페이지 로딩 대기
    await page.waitForTimeout(5000);
    
    // 현재 페이지 스크린샷
    await page.screenshot({ path: 'admin-dashboard-final.png' });
    
    // localStorage에서 토큰 확인
    const token = await page.evaluate(() => localStorage.getItem('token'));
    console.log('Token in localStorage:', token ? 'EXISTS' : 'NULL');
    
    // 인증 상태 확인
    const authStatus = await page.evaluate(() => {
      return {
        hasToken: !!localStorage.getItem('token'),
        tokenValue: localStorage.getItem('token')?.substring(0, 20) + '...',
        url: window.location.href
      };
    });
    console.log('Auth status:', authStatus);
    
    // 실제 DOM 구조 확인
    const bodyContent = await page.locator('body').innerHTML();
    console.log('Dashboard body content (first 500 chars):', bodyContent.substring(0, 500));
    
    // Vue 앱이 마운트되었는지 확인
    const vueApp = await page.locator('#app').count();
    console.log('Vue app elements found:', vueApp);
    
    // 인증 관련 요소 확인
    const authLayout = await page.locator('text=Authentication Layout').count();
    const sidebarExists = await page.locator('.bg-slate-200, .bg-slate-800').count();
    console.log('Authentication Layout found:', authLayout);
    console.log('Sidebar elements found:', sidebarExists);
  });
});