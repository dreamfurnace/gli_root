const { chromium } = require('@playwright/test')

async function globalSetup(config) {
  const browser = await chromium.launch()
  const page = await browser.newPage()

  // 테스트용 사용자 생성
  await page.goto('http://localhost:5173/register')
  await page.fill('input[type="email"]', 'test@example.com')
  await page.fill('input[name="name"]', 'Test User')
  await page.fill('input[name="password"]', 'password123')
  await page.fill('input[name="password_confirm"]', 'password123')
  await page.click('button[type="submit"]')

  // 로그인하여 토큰 저장
  await page.goto('http://localhost:5173/login')
  await page.fill('input[type="email"]', 'test@example.com')
  await page.fill('input[type="password"]', 'password123')
  await page.click('button[type="submit"]')

  // 로그인 성공 후 토큰을 저장
  await page.waitForURL('**/dashboard')

  // 로컬 스토리지에서 토큰 가져오기
  const token = await page.evaluate(() => {
    return localStorage.getItem('access_token')
  })

  // 환경 변수로 토큰 설정
  process.env.TEST_AUTH_TOKEN = token

  await browser.close()
}

module.exports = globalSetup
