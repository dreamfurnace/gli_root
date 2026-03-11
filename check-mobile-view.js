const { chromium } = require('playwright');

(async () => {
  const browser = await chromium.launch({ headless: false });

  // 모바일 뷰포트 설정 (iPhone 12 Pro 기준)
  const context = await browser.newContext({
    viewport: { width: 390, height: 844 },
    userAgent: 'Mozilla/5.0 (iPhone; CPU iPhone OS 14_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/14.0 Mobile/15E148 Safari/604.1',
    deviceScaleFactor: 3,
    isMobile: true,
    hasTouch: true
  });

  const page = await context.newPage();

  console.log('모바일 뷰로 페이지 로딩 중...');

  // 캐시 비우기
  await context.clearCookies();

  await page.goto('http://localhost:3000/shopping/resort/36d0db85-dc1c-436c-b307-07bafb3b714c', {
    waitUntil: 'networkidle',
    timeout: 60000
  });

  console.log('현재 URL:', page.url());

  // 페이지 로딩 대기
  await page.waitForTimeout(3000);

  // 전체 페이지 스크린샷
  console.log('전체 페이지 스크린샷 저장 중...');
  await page.screenshot({
    path: 'mobile-view-full.png',
    fullPage: true
  });

  // 뷰포트 스크린샷 (현재 보이는 화면)
  console.log('뷰포트 스크린샷 저장 중...');
  await page.screenshot({
    path: 'mobile-view-viewport.png',
    fullPage: false
  });

  // 페이지 정보 수집
  const pageInfo = await page.evaluate(() => {
    // 모든 요소의 가시성 확인
    const elements = document.querySelectorAll('*');
    const hiddenElements = [];
    const overflowElements = [];

    elements.forEach((el, index) => {
      const rect = el.getBoundingClientRect();
      const style = window.getComputedStyle(el);

      // 숨겨진 요소
      if (style.display === 'none' || style.visibility === 'hidden' || style.opacity === '0') {
        if (el.id || el.className) {
          hiddenElements.push({
            tag: el.tagName,
            id: el.id,
            class: el.className,
            display: style.display,
            visibility: style.visibility,
            opacity: style.opacity
          });
        }
      }

      // 뷰포트 밖으로 넘어가는 요소
      if (rect.width > window.innerWidth || rect.right > window.innerWidth) {
        if (el.id || el.className) {
          overflowElements.push({
            tag: el.tagName,
            id: el.id,
            class: el.className,
            width: rect.width,
            right: rect.right,
            viewportWidth: window.innerWidth
          });
        }
      }
    });

    return {
      title: document.title,
      url: window.location.href,
      viewport: {
        width: window.innerWidth,
        height: window.innerHeight
      },
      documentSize: {
        width: document.documentElement.scrollWidth,
        height: document.documentElement.scrollHeight
      },
      hiddenElementsCount: hiddenElements.length,
      hiddenElements: hiddenElements.slice(0, 20), // 처음 20개만
      overflowElementsCount: overflowElements.length,
      overflowElements: overflowElements.slice(0, 20) // 처음 20개만
    };
  });

  console.log('\n===== 페이지 분석 결과 =====');
  console.log('제목:', pageInfo.title);
  console.log('뷰포트:', pageInfo.viewport);
  console.log('문서 크기:', pageInfo.documentSize);
  console.log('\n숨겨진 요소:', pageInfo.hiddenElementsCount, '개');
  console.log('넘치는 요소:', pageInfo.overflowElementsCount, '개');

  if (pageInfo.hiddenElements.length > 0) {
    console.log('\n주요 숨겨진 요소들:');
    pageInfo.hiddenElements.forEach((el, i) => {
      console.log(`${i+1}. ${el.tag}#${el.id}.${el.class}`);
      console.log(`   display: ${el.display}, visibility: ${el.visibility}, opacity: ${el.opacity}`);
    });
  }

  if (pageInfo.overflowElements.length > 0) {
    console.log('\n뷰포트 밖으로 넘어가는 요소들:');
    pageInfo.overflowElements.forEach((el, i) => {
      console.log(`${i+1}. ${el.tag}#${el.id}.${el.class}`);
      console.log(`   width: ${el.width}px, right: ${el.right}px (뷰포트: ${el.viewportWidth}px)`);
    });
  }

  // 결과를 JSON 파일로 저장
  const fs = require('fs');
  fs.writeFileSync('mobile-view-analysis.json', JSON.stringify(pageInfo, null, 2));
  console.log('\n상세 분석 결과가 mobile-view-analysis.json에 저장되었습니다.');

  console.log('\n브라우저를 30초간 열어둡니다. 직접 확인해보세요...');
  await page.waitForTimeout(30000);

  await browser.close();
})();
