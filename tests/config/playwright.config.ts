import { defineConfig, devices } from '@playwright/test';
import * as path from 'path';

/**
 * GLI Platform Playwright Configuration
 * E2E, Accessibility, Cross-browser testing
 */
export default defineConfig({
  // 테스트 디렉토리
  testDir: path.resolve(__dirname, '..'),
  
  // 테스트 파일 패턴
  testMatch: [
    '**/e2e/**/*.e2e.test.{js,ts}',
    '**/accessibility/**/*.a11y.test.{js,ts}',
    '**/integration/**/*.browser.test.{js,ts}'
  ],
  
  /* 병렬 실행 설정 */
  fullyParallel: true,
  
  /* CI에서 실패한 테스트 재시도 */
  retries: process.env.CI ? 2 : 0,
  
  /* 병렬 워커 수 */
  workers: process.env.CI ? 1 : undefined,
  
  /* 리포터 설정 */
  reporter: [
    ['html', { outputFolder: 'reports/playwright-report' }],
    ['json', { outputFile: 'reports/playwright-results.json' }],
    ['junit', { outputFile: 'reports/playwright-junit.xml' }],
    ['allure-playwright', { outputFolder: 'reports/allure-results' }]
  ],
  
  /* 공통 테스트 설정 */
  use: {
    /* 베이스 URL */
    baseURL: process.env.TEST_BASE_URL || 'http://localhost:5173',
    
    /* 스크린샷 설정 */
    screenshot: 'only-on-failure',
    
    /* 비디오 녹화 */
    video: 'retain-on-failure',
    
    /* 트레이스 수집 */
    trace: 'on-first-retry',
    
    /* 테스트 타임아웃 */
    actionTimeout: 30000,
    navigationTimeout: 30000
  },

  /* 프로젝트별 설정 */
  projects: [
    {
      name: 'setup',
      testMatch: '**/scripts/setup/**/*.setup.ts',
      teardown: 'cleanup'
    },
    {
      name: 'cleanup',
      testMatch: '**/scripts/setup/**/*.cleanup.ts'
    },
    
    /* Desktop Browsers */
    {
      name: 'chromium',
      use: { 
        ...devices['Desktop Chrome'],
        // Web3 Extension 지원
        args: [
          '--disable-web-security',
          '--disable-features=VizDisplayCompositor',
          '--load-extension=./fixtures/phantom-wallet-mock'
        ]
      },
      dependencies: ['setup']
    },
    {
      name: 'firefox',
      use: { ...devices['Desktop Firefox'] },
      dependencies: ['setup']
    },
    {
      name: 'webkit',
      use: { ...devices['Desktop Safari'] },
      dependencies: ['setup']
    },

    /* Mobile Browsers */
    {
      name: 'Mobile Chrome',
      use: { ...devices['Pixel 5'] },
      dependencies: ['setup']
    },
    {
      name: 'Mobile Safari',
      use: { ...devices['iPhone 12'] },
      dependencies: ['setup']
    },

    /* Admin Dashboard Tests */
    {
      name: 'admin-desktop',
      use: { 
        ...devices['Desktop Chrome'],
        baseURL: process.env.ADMIN_BASE_URL || 'http://localhost:5174'
      },
      testMatch: '**/e2e/admin-flows/**/*.test.{js,ts}',
      dependencies: ['setup']
    },

    /* Web3 Integration Tests */
    {
      name: 'web3-integration',
      use: { 
        ...devices['Desktop Chrome'],
        // Solana Test Validator 환경
        baseURL: 'http://localhost:5173',
        extraHTTPHeaders: {
          'X-Test-Environment': 'solana-devnet'
        }
      },
      testMatch: '**/e2e/web3-integration/**/*.test.{js,ts}',
      dependencies: ['setup']
    },

    /* Accessibility Tests */
    {
      name: 'accessibility',
      use: { 
        ...devices['Desktop Chrome'],
        // 접근성 도구 활성화
        args: ['--force-prefers-reduced-motion', '--enable-accessibility-logging']
      },
      testMatch: '**/accessibility/**/*.test.{js,ts}',
      dependencies: ['setup']
    }
  ],

  /* 개발 서버 설정 */
  webServer: [
    {
      command: 'npm run dev',
      cwd: '../gli_user-frontend',
      port: 5173,
      reuseExistingServer: !process.env.CI,
      timeout: 120000
    },
    {
      command: 'npm run dev',
      cwd: '../gli_admin-frontend', 
      port: 5174,
      reuseExistingServer: !process.env.CI,
      timeout: 120000
    },
    {
      command: 'uv run python manage.py runserver 0.0.0.0:8000',
      cwd: '../gli_api-server',
      port: 8000,
      reuseExistingServer: !process.env.CI,
      timeout: 120000
    }
  ],

  /* 글로벌 설정 */
  globalSetup: './scripts/setup/global-setup.ts',
  globalTeardown: './scripts/setup/global-teardown.ts',
  
  /* 환경 변수 */
  metadata: {
    platform: process.platform,
    nodeVersion: process.version,
    testEnvironment: process.env.NODE_ENV || 'test'
  },

  /* 테스트 출력 디렉토리 */
  outputDir: 'test-results/',
  
  /* 실험적 기능 */
  experimental: {
    // 테스트 분할 기능
    testIdAttribute: 'data-testid'
  }
});