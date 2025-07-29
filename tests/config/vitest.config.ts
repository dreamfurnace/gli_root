import { defineConfig } from 'vitest/config';
import vue from '@vitejs/plugin-vue';
import { resolve } from 'path';

/**
 * GLI Platform Vitest Configuration
 * Vue 3 Component Testing & Frontend Unit Tests
 */
export default defineConfig({
  plugins: [vue()],
  
  test: {
    // 테스트 환경
    environment: 'jsdom',
    
    // 글로벌 설정
    globals: true,
    
    // 설정 파일
    setupFiles: [
      resolve(__dirname, '../shared/setup/vitest.setup.ts')
    ],
    
    // 테스트 파일 패턴
    include: [
      '../gli_user-frontend/src/**/*.{test,spec}.{js,ts,vue}',
      '../gli_admin-frontend/src/**/*.{test,spec}.{js,ts,vue}',
      '__tests__/frontend/**/*.{test,spec}.{js,ts,vue}'
    ],
    
    // 제외 패턴
    exclude: [
      'node_modules',
      'coverage',
      'test-results',
      '**/*.e2e.test.{js,ts}'
    ],
    
    // 커버리지 설정
    coverage: {
      provider: 'c8',
      reporter: ['text', 'json', 'html', 'lcov'],
      reportsDirectory: './coverage/frontend',
      include: [
        '../gli_user-frontend/src/**/*.{js,ts,vue}',
        '../gli_admin-frontend/src/**/*.{js,ts,vue}'
      ],
      exclude: [
        '**/*.d.ts',
        '**/*.test.{js,ts,vue}',
        '**/*.spec.{js,ts,vue}',
        '**/node_modules/**',
        '**/dist/**'
      ],
      thresholds: {
        global: {
          branches: 70,
          functions: 70,
          lines: 70,
          statements: 70
        }
      }
    },
    
    // 테스트 타임아웃
    testTimeout: 10000,
    hookTimeout: 10000,
    
    // 리포터 설정
    reporters: [
      'default',
      'json',
      'html'
    ],
    
    // 출력 설정
    outputFiles: {
      json: './reports/vitest-results.json',
      html: './reports/vitest-report.html'
    },
    
    // 감시 모드 설정
    watch: false,
    
    // 병렬 실행
    threads: true,
    maxThreads: 4,
    minThreads: 1,
    
    // UI 설정
    ui: true,
    uiBase: '/vitest/'
  },
  
  // 경로 별칭
  resolve: {
    alias: {
      '@': resolve(__dirname, '../gli_user-frontend/src'),
      '@admin': resolve(__dirname, '../gli_admin-frontend/src'),
      '@tests': resolve(__dirname, '..'),
      '@fixtures': resolve(__dirname, '../fixtures'),
      '@shared': resolve(__dirname, '../shared'),
      '@utils': resolve(__dirname, '../utils')
    }
  },
  
  // 개발 서버 설정 (UI 모드용)
  server: {
    port: 51204,
    host: true
  },
  
  // 빌드 최적화
  optimizeDeps: {
    include: [
      '@vue/test-utils',
      '@testing-library/vue',
      'jsdom'
    ]
  },
  
  // 환경 변수
  define: {
    __VUE_PROD_DEVTOOLS__: false,
    __VUE_OPTIONS_API__: true
  }
});