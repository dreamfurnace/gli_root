import { test, expect } from '@playwright/test';

test.describe('Debug Admin Login', () => {
  test('debug login page elements', async ({ page }) => {
    await page.goto('/login');
    
    // 페이지 스크린샷 찍기
    await page.screenshot({ path: 'debug-login-page.png' });
    
    // 페이지 소스 확인
    const content = await page.content();
    console.log('Page content:', content.substring(0, 500));
    
    // 모든 input 요소 찾기
    const inputs = await page.locator('input').all();
    console.log('Number of inputs found:', inputs.length);
    
    for (let i = 0; i < inputs.length; i++) {
      const input = inputs[i];
      const id = await input.getAttribute('id');
      const type = await input.getAttribute('type');
      const placeholder = await input.getAttribute('placeholder');
      console.log(`Input ${i}: id=${id}, type=${type}, placeholder=${placeholder}`);
    }
    
    // 페이지 제목 확인
    const title = await page.title();
    console.log('Page title:', title);
    
    // 모든 h2 요소 찾기  
    const h2Elements = await page.locator('h2').all();
    console.log('Number of h2 elements:', h2Elements.length);
    
    for (let i = 0; i < h2Elements.length; i++) {
      const text = await h2Elements[i].textContent();
      console.log(`H2 ${i}: "${text}"`);
    }
  });

  test('debug login attempt', async ({ page }) => {
    await page.goto('/login');
    
    // 콘솔 로그 수집
    page.on('console', msg => {
      console.log('Browser console:', msg.text());
    });
    
    // 로그인 시도
    await page.fill('input[id="username"]', 'admin@gli.com');
    await page.fill('input[id="password"]', 'admin123!');
    
    // 로그인 버튼 클릭 전 스크린샷
    await page.screenshot({ path: 'before-login-click.png' });
    
    // 네트워크 요청 감시
    page.on('request', request => {
      console.log('Request:', request.method(), request.url());
    });
    
    page.on('response', response => {
      console.log('Response:', response.status(), response.url());
    });
    
    await page.click('button[type="submit"]');
    
    // 5초 대기 (로그인 처리 시간)
    await page.waitForTimeout(5000);
    
    // 로그인 후 스크린샷
    await page.screenshot({ path: 'after-login-click.png' });
    
    // 현재 URL 출력
    console.log('Current URL:', page.url());
    
    // 페이지 에러 확인
    const errorElements = await page.locator('.bg-red-50, .text-red-500, .error').all();
    console.log('Number of error elements:', errorElements.length);
    
    for (let i = 0; i < errorElements.length; i++) {
      const text = await errorElements[i].textContent();
      console.log(`Error ${i}: "${text}"`);
    }
    
    // localStorage 확인
    const token = await page.evaluate(() => localStorage.getItem('token'));
    console.log('Token in localStorage:', token ? 'EXISTS' : 'NULL');
  });
});