const path = require('path');

module.exports = {
  // 테스트 환경 설정
  testEnvironment: 'jsdom',
  
  // 프로젝트 루트 디렉토리
  rootDir: path.resolve(__dirname, '..'),
  
  // 테스트 파일 패턴
  testMatch: [
    '<rootDir>/__tests__/**/*.test.{js,ts}',
    '<rootDir>/integration/**/*.test.{js,ts}',
    '<rootDir>/security/**/*.test.{js,ts}'
  ],
  
  // 변환 설정
  transform: {
    '^.+\\.(ts|tsx)$': 'ts-jest',
    '^.+\\.(js|jsx)$': 'babel-jest'
  },
  
  // 모듈 경로 매핑
  moduleNameMapper: {
    '^@/(.*)$': '<rootDir>/../gli_user-frontend/src/$1',
    '^@admin/(.*)$': '<rootDir>/../gli_admin-frontend/src/$1',
    '^@api/(.*)$': '<rootDir>/../gli_api-server/$1',
    '^@tests/(.*)$': '<rootDir>/$1',
    '^@fixtures/(.*)$': '<rootDir>/fixtures/$1',
    '^@shared/(.*)$': '<rootDir>/shared/$1',
    '^@utils/(.*)$': '<rootDir>/utils/$1'
  },
  
  // 설정 파일
  setupFilesAfterEnv: [
    '<rootDir>/shared/setup/jest.setup.js'
  ],
  
  // 커버리지 설정
  collectCoverage: false,
  collectCoverageFrom: [
    '../gli_user-frontend/src/**/*.{js,ts,vue}',
    '../gli_admin-frontend/src/**/*.{js,ts,vue}',
    '../gli_api-server/**/*.py',
    '!**/node_modules/**',
    '!**/coverage/**',
    '!**/*.d.ts'
  ],
  coverageDirectory: '<rootDir>/coverage',
  coverageReporters: ['text', 'lcov', 'html', 'json'],
  coverageThreshold: {
    global: {
      branches: 70,
      functions: 70,
      lines: 70,
      statements: 70
    }
  },
  
  // 테스트 환경 변수
  testEnvironmentOptions: {
    customExportConditions: ['node', 'node-addons']
  },
  
  // 모듈 파일 확장자
  moduleFileExtensions: [
    'js',
    'ts',
    'json',
    'vue',
    'py'
  ],
  
  // 무시할 패턴
  testPathIgnorePatterns: [
    '/node_modules/',
    '/coverage/',
    '/test-results/'
  ],
  
  // 글로벌 설정
  globals: {
    'ts-jest': {
      useESM: false
    }
  },
  
  // 타이머 Mock 설정
  fakeTimers: {
    enableGlobally: true
  },
  
  // 테스트 타임아웃
  testTimeout: 30000,
  
  // 병렬 실행 설정
  maxWorkers: '50%',
  
  // 리포터 설정
  reporters: ['default'],
  
  // 감시 모드 설정
  watchPathIgnorePatterns: [
    '/node_modules/',
    '/coverage/',
    '/reports/'
  ]
};