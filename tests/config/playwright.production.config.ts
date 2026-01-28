import { defineConfig, devices } from '@playwright/test'

/**
 * GLI 운영/스테이징 환경 테스트 설정
 *
 * 실행 방법:
 * npx playwright test --config=config/playwright.production.config.ts
 */
export default defineConfig({
  testDir: '../e2e/production',
  fullyParallel: false,  // 운영 환경에서는 순차 실행
  forbidOnly: true,
  retries: 2,  // 네트워크 이슈 대비
  workers: 1,  // 순차 실행
  reporter: [
    ['html', { outputFolder: '../reports/production-html-report' }],
    ['json', { outputFile: '../reports/production-results.json' }],
    ['junit', { outputFile: '../reports/production-results.xml' }],
    ['list']
  ],
  use: {
    baseURL: process.env.BASE_URL || 'https://glibiz.com',
    trace: 'retain-on-failure',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
    actionTimeout: 15000,
    navigationTimeout: 30000,
    // 운영 환경 접근
    ignoreHTTPSErrors: false,
    acceptDownloads: true,
    locale: 'ko-KR',
    timezoneId: 'Asia/Seoul',
  },
  projects: [
    {
      name: 'production-chromium',
      use: {
        ...devices['Desktop Chrome'],
        viewport: { width: 1920, height: 1080 },
      },
    },
  ],
  timeout: 60000,  // 운영 환경 타임아웃
  expect: {
    timeout: 10000,
  },
  outputDir: '../reports/production-artifacts',
})
