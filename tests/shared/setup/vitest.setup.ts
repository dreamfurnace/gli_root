/**
 * GLI Platform Vitest Global Setup
 * Vue 3 컴포넌트 테스트 및 프론트엔드 단위 테스트 설정
 */

import { vi } from 'vitest';
import { config } from '@vue/test-utils';
import { createPinia } from 'pinia';

// 환경 변수 로드
import dotenv from 'dotenv';
dotenv.config({ path: '.env.test' });

// Vue Test Utils 글로벌 설정
config.global.plugins = [createPinia()];

// 글로벌 Mock 설정
Object.defineProperty(window, 'fetch', {
  value: vi.fn(),
  writable: true
});

Object.defineProperty(window, 'localStorage', {
  value: {
    getItem: vi.fn(),
    setItem: vi.fn(),
    removeItem: vi.fn(),
    clear: vi.fn(),
  },
  writable: true
});

Object.defineProperty(window, 'sessionStorage', {
  value: {
    getItem: vi.fn(),
    setItem: vi.fn(),
    removeItem: vi.fn(),
    clear: vi.fn(),
  },
  writable: true
});

// Web3 Provider Mocks
Object.defineProperty(window, 'ethereum', {
  value: {
    request: vi.fn(),
    on: vi.fn(),
    removeListener: vi.fn(),
    isMetaMask: true,
    selectedAddress: null,
    chainId: '0x1'
  },
  writable: true
});

Object.defineProperty(window, 'phantom', {
  value: {
    solana: {
      connect: vi.fn(),
      disconnect: vi.fn(),
      signMessage: vi.fn(),
      signTransaction: vi.fn(),
      isConnected: false,
      publicKey: null
    }
  },
  writable: true
});

// IntersectionObserver Mock
Object.defineProperty(window, 'IntersectionObserver', {
  value: vi.fn().mockImplementation(() => ({
    observe: vi.fn(),
    unobserve: vi.fn(),
    disconnect: vi.fn()
  }))
});

// ResizeObserver Mock
Object.defineProperty(window, 'ResizeObserver', {
  value: vi.fn().mockImplementation(() => ({
    observe: vi.fn(),
    unobserve: vi.fn(),
    disconnect: vi.fn()
  }))
});

// matchMedia Mock
Object.defineProperty(window, 'matchMedia', {
  value: vi.fn().mockImplementation(query => ({
    matches: false,
    media: query,
    onchange: null,
    addListener: vi.fn(),
    removeListener: vi.fn(),
    addEventListener: vi.fn(),
    removeEventListener: vi.fn(),
    dispatchEvent: vi.fn()
  }))
});

// 글로벌 테스트 유틸리티
declare global {
  var testUtils: {
    createMockUser: () => any;
    createMockAdmin: () => any;
    mockApiCall: (data: any, status?: number) => Promise<any>;
    delay: (ms: number) => Promise<void>;
    mockWalletConnect: () => void;
    mockWalletDisconnect: () => void;
  };
}

globalThis.testUtils = {
  // Mock 사용자 생성
  createMockUser: () => ({
    id: 'test-user-id',
    wallet_address: 'DjVE6JNiYqPL2QXyCUEwD9uKhAYpVy2xEf5jKNiVSB7U',
    username: 'test_user',
    email: 'test@gli-platform.com',
    membership_level: 'premium',
    created_at: new Date().toISOString()
  }),

  // Mock 관리자 생성
  createMockAdmin: () => ({
    id: 'test-admin-id',
    username: 'admin',
    role: 'super_admin',
    permissions: ['all'],
    created_at: new Date().toISOString()
  }),

  // API 호출 Mock
  mockApiCall: (data: any, status: number = 200) => {
    return Promise.resolve({
      ok: status >= 200 && status < 300,
      status,
      json: () => Promise.resolve(data),
      text: () => Promise.resolve(JSON.stringify(data))
    });
  },

  // 지연 함수
  delay: (ms: number) => new Promise(resolve => setTimeout(resolve, ms)),

  // 지갑 연결 Mock
  mockWalletConnect: () => {
    if (window.phantom?.solana) {
      window.phantom.solana.isConnected = true;
      window.phantom.solana.publicKey = {
        toString: () => 'DjVE6JNiYqPL2QXyCUEwD9uKhAYpVy2xEf5jKNiVSB7U'
      };
    }
  },

  // 지갑 연결 해제 Mock
  mockWalletDisconnect: () => {
    if (window.phantom?.solana) {
      window.phantom.solana.isConnected = false;
      window.phantom.solana.publicKey = null;
    }
  }
};

// 커스텀 매처 설정
expect.extend({
  toBeValidVueComponent(received: any) {
    const pass = received && typeof received === 'object' && received.render;
    
    if (pass) {
      return {
        message: () => `expected component not to be a valid Vue component`,
        pass: true,
      };
    } else {
      return {
        message: () => `expected component to be a valid Vue component`,
        pass: false,
      };
    }
  },

  toHaveBeenCalledWithWalletAddress(received: any, address?: string) {
    const expectedAddress = address || 'DjVE6JNiYqPL2QXyCUEwD9uKhAYpVy2xEf5jKNiVSB7U';
    const pass = received.mock.calls.some((call: any[]) => 
      call.some(arg => arg === expectedAddress || (arg?.wallet_address === expectedAddress))
    );

    if (pass) {
      return {
        message: () => `expected function not to have been called with wallet address ${expectedAddress}`,
        pass: true,
      };
    } else {
      return {
        message: () => `expected function to have been called with wallet address ${expectedAddress}`,
        pass: false,
      };
    }
  }
});

// Vue Router Mock
vi.mock('vue-router', () => ({
  useRouter: () => ({
    push: vi.fn(),
    replace: vi.fn(),
    go: vi.fn(),
    back: vi.fn(),
    forward: vi.fn()
  }),
  useRoute: () => ({
    params: {},
    query: {},
    path: '/',
    name: 'home'
  })
}));

// Pinia Mock 헬퍼
export const createMockStore = (initialState: any = {}) => {
  return {
    ...initialState,
    $patch: vi.fn(),
    $reset: vi.fn(),
    $subscribe: vi.fn(),
    $onAction: vi.fn()
  };
};