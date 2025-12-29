/**
 * GLI Platform Jest Global Setup
 * 모든 Jest 테스트에서 공통으로 사용되는 설정
 */

// 환경 변수 로드
require('dotenv').config({ path: '.env.test' });

// Jest 타임아웃 설정
jest.setTimeout(30000);

// 글로벌 Mock 설정
global.fetch = require('jest-fetch-mock');

// 콘솔 에러 필터링 (개발 중 노이즈 제거)
const originalError = console.error;
beforeAll(() => {
  console.error = (...args) => {
    if (
      typeof args[0] === 'string' &&
      args[0].includes('Warning: ReactDOM.render is deprecated')
    ) {
      return;
    }
    originalError.call(console, ...args);
  };
});

afterAll(() => {
  console.error = originalError;
});

// Solana Phantom Wallet Mock
global.window = global.window || {};
global.window.phantom = {
  solana: {
    connect: jest.fn(),
    disconnect: jest.fn(),
    signMessage: jest.fn(),
    signTransaction: jest.fn(),
    isConnected: false,
    publicKey: null
  }
};

// DOM 환경 설정
if (typeof window !== 'undefined') {
  // localStorage Mock
  const localStorageMock = {
    getItem: jest.fn(),
    setItem: jest.fn(),
    removeItem: jest.fn(),
    clear: jest.fn(),
  };
  global.localStorage = localStorageMock;

  // sessionStorage Mock
  const sessionStorageMock = {
    getItem: jest.fn(),
    setItem: jest.fn(),
    removeItem: jest.fn(),
    clear: jest.fn(),
  };
  global.sessionStorage = sessionStorageMock;

  // IntersectionObserver Mock
  global.IntersectionObserver = class IntersectionObserver {
    constructor() {}
    observe() {
      return null;
    }
    disconnect() {
      return null;
    }
    unobserve() {
      return null;
    }
  };

  // ResizeObserver Mock
  global.ResizeObserver = class ResizeObserver {
    constructor() {}
    observe() {
      return null;
    }
    disconnect() {
      return null;
    }
    unobserve() {
      return null;
    }
  };
}

// API Mock 설정
const mockApiResponse = (data, status = 200) => {
  return Promise.resolve({
    ok: status >= 200 && status < 300,
    status,
    json: () => Promise.resolve(data),
    text: () => Promise.resolve(JSON.stringify(data))
  });
};

// 글로벌 테스트 헬퍼
global.testHelpers = {
  mockApiResponse,
  
  // 지연 함수
  delay: (ms) => new Promise(resolve => setTimeout(resolve, ms)),
  
  // 테스트 사용자 데이터
  testUser: {
    id: 'test-user-id',
    wallet_address: 'DjVE6JNiYqPL2QXyCUEwD9uKhAYpVy2xEf5jKNiVSB7U',
    username: 'test_user',
    email: 'test@gli-platform.com',
    membership_level: 'premium'
  },
  
  // 테스트 관리자 데이터
  testAdmin: {
    id: 'test-admin-id',
    username: 'admin',
    role: 'super_admin',
    permissions: ['all']
  }
};

// 커스텀 매처 설정
expect.extend({
  toBeWithinRange(received, floor, ceiling) {
    const pass = received >= floor && received <= ceiling;
    if (pass) {
      return {
        message: () =>
          `expected ${received} not to be within range ${floor} - ${ceiling}`,
        pass: true,
      };
    } else {
      return {
        message: () =>
          `expected ${received} to be within range ${floor} - ${ceiling}`,
        pass: false,
      };
    }
  },
  
  toBeValidWalletAddress(received) {
    const pass = typeof received === 'string' && received.length >= 32 && received.length <= 44;
    if (pass) {
      return {
        message: () => `expected ${received} not to be a valid wallet address`,
        pass: true,
      };
    } else {
      return {
        message: () => `expected ${received} to be a valid wallet address`,
        pass: false,
      };
    }
  }
});

// 테스트 시작 전 정리
beforeEach(() => {
  // Mock 함수들 초기화
  jest.clearAllMocks();
  
  // localStorage 초기화
  if (global.localStorage) {
    global.localStorage.clear();
  }
  
  // sessionStorage 초기화
  if (global.sessionStorage) {
    global.sessionStorage.clear();
  }
  
  // fetch mock 초기화
  if (global.fetch) {
    global.fetch.resetMocks();
  }
});

// 테스트 완료 후 정리
afterEach(() => {
  // 타이머 정리 (fake timers가 활성화된 경우에만)
  if (jest.isMockFunction(setTimeout)) {
    jest.runOnlyPendingTimers();
    jest.useRealTimers();
  }
});