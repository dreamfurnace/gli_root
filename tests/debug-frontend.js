const { chromium } = require('playwright');

async function debugFrontend() {
  const browser = await chromium.launch({ headless: false });
  const context = await browser.newContext();
  const page = await context.newPage();

  // 콘솔 에러 캐치
  page.on('console', msg => {
    if (msg.type() === 'error') {
      console.log('❌ Console Error:', msg.text());
    } else {
      console.log('💬 Console:', msg.type(), msg.text());
    }
  });

  // 페이지 에러 캐치
  page.on('pageerror', error => {
    console.log('🚨 Page Error:', error.message);
  });

  // 네트워크 요청 모니터링
  page.on('request', request => {
    console.log('📤 Request:', request.method(), request.url());
  });

  page.on('response', response => {
    if (!response.ok()) {
      console.log('❌ Failed Response:', response.status(), response.url());
    }
  });

  try {
    console.log('🔍 Checking User Frontend at http://localhost:3000...');
    await page.goto('http://localhost:3000', { waitUntil: 'networkidle' });
    
    // 페이지 제목 확인
    const title = await page.title();
    console.log('📄 Page Title:', title);
    
    // body 내용 확인
    const bodyText = await page.textContent('body');
    console.log('📝 Body Text Length:', bodyText.length);
    
    // #app div 확인
    const appDiv = await page.locator('#app');
    const appContent = await appDiv.textContent();
    console.log('🎯 #app Content:', appContent || 'EMPTY');
    
    // HTML 구조 확인
    const html = await page.content();
    console.log('📋 HTML Length:', html.length);
    
    // 스크린샷 찍기
    await page.screenshot({ path: 'debug-screenshot.png', fullPage: true });
    console.log('📸 Screenshot saved as debug-screenshot.png');
    
    // 잠시 대기 후 브라우저 닫기
    console.log('⏳ Waiting 5 seconds for manual inspection...');
    await page.waitForTimeout(5000);
    
  } catch (error) {
    console.log('💥 Error:', error.message);
  }

  await browser.close();
  console.log('✅ Debug complete');
}

debugFrontend();