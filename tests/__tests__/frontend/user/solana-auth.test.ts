/**
 * GLI Platform - Solana Authentication Unit Tests
 * useSolanaAuth composable 단위 테스트
 */

// Jest는 globals로 제공되므로 import 불필요
import { useSolanaAuth } from '@/composables/useSolanaAuth';
import axios from 'axios';

// axios Mock
jest.mock('axios');
const mockedAxios = jest.mocked(axios);

// useSolanaWallet Mock
jest.mock('@/composables/useSolanaWallet', () => ({
  useSolanaWallet: () => ({
    publicKey: { value: { toString: () => 'DjVE6JNiYqPL2QXyCUEwD9uKhAYpVy2xEf5jKNiVSB7U' } },
    isConnected: { value: true },
    fullAddress: { value: 'DjVE6JNiYqPL2QXyCUEwD9uKhAYpVy2xEf5jKNiVSB7U' }
  })
}));

describe('useSolanaAuth', () => {
  let auth: ReturnType<typeof useSolanaAuth>;

  beforeEach(() => {
    // localStorage Mock 초기화
    globalThis.testUtils.mockWalletConnect();
    
    // Phantom 지갑 Mock 설정
    global.window.phantom = {
      solana: {
        signMessage: jest.fn().mockResolvedValue({
          signature: new Uint8Array(64),
          publicKey: { toString: () => 'DjVE6JNiYqPL2QXyCUEwD9uKhAYpVy2xEf5jKNiVSB7U' }
        })
      }
    };

    auth = useSolanaAuth();
  });

  afterEach(() => {
    jest.clearAllMocks();
    localStorage.clear();
  });

  describe('authenticateWithWallet', () => {
    it('should authenticate successfully with valid wallet', async () => {
      // Mock API responses
      mockedAxios.post
        .mockResolvedValueOnce({
          data: { nonce: 'test-nonce-12345' }
        })
        .mockResolvedValueOnce({
          data: {
            access_token: 'test-jwt-token', 
            user: globalThis.testUtils.createMockUser()
          }
        });

      const result = await auth.authenticateWithWallet();

      expect(result.success).toBe(true);
      expect(result.user).toBeDefined();
      expect(auth.isAuthenticated.value).toBe(true);
      expect(auth.authToken.value).toBe('test-jwt-token');
    });

    it('should throw error when wallet is not connected', async () => {
      // 지갑 연결 해제 Mock
      globalThis.testUtils.mockWalletDisconnect();
      
      const authDisconnected = useSolanaAuth();

      await expect(authDisconnected.authenticateWithWallet()).rejects.toThrow('지갑이 연결되지 않았습니다');
    });

    it('should handle nonce request failure', async () => {
      mockedAxios.post.mockRejectedValueOnce({
        response: { data: { message: 'Nonce generation failed' } }
      });

      await expect(auth.authenticateWithWallet()).rejects.toThrow('Nonce generation failed');
    });

    it('should handle signature verification failure', async () => {
      mockedAxios.post
        .mockResolvedValueOnce({
          data: { nonce: 'test-nonce-12345' }
        })
        .mockRejectedValueOnce({
          response: { data: { message: 'Invalid signature' } }
        });

      await expect(auth.authenticateWithWallet()).rejects.toThrow('Invalid signature');
    });

    it('should store auth data in localStorage', async () => {
      const mockUser = globalThis.testUtils.createMockUser();
      
      mockedAxios.post
        .mockResolvedValueOnce({
          data: { nonce: 'test-nonce-12345' }
        })
        .mockResolvedValueOnce({
          data: {
            access_token: 'test-jwt-token',
            user: mockUser
          }
        });

      await auth.authenticateWithWallet();

      expect(localStorage.setItem).toHaveBeenCalledWith('gli_auth_token', 'test-jwt-token');
      expect(localStorage.setItem).toHaveBeenCalledWith('gli_user_profile', JSON.stringify(mockUser));
    });

    it('should handle phantom wallet signing error', async () => {
      global.window.phantom.solana.signMessage.mockRejectedValue(new Error('User rejected signing'));

      mockedAxios.post.mockResolvedValueOnce({
        data: { nonce: 'test-nonce-12345' }
      });

      await expect(auth.authenticateWithWallet()).rejects.toThrow('User rejected signing');
    });
  });

  describe('logout', () => {
    beforeEach(async () => {
      // 인증 상태 설정
      localStorage.setItem('gli_auth_token', 'test-token');
      localStorage.setItem('gli_user_profile', JSON.stringify(globalThis.testUtils.createMockUser()));
    });

    it('should logout successfully', async () => {
      mockedAxios.post.mockResolvedValueOnce({ data: { message: 'Logged out' } });

      await auth.logout();

      expect(auth.isAuthenticated.value).toBe(false);
      expect(auth.authToken.value).toBeNull();
      expect(auth.userProfile.value).toBeNull();
      expect(localStorage.removeItem).toHaveBeenCalledWith('gli_auth_token');
      expect(localStorage.removeItem).toHaveBeenCalledWith('gli_user_profile');
    });

    it('should logout even when API call fails', async () => {
      mockedAxios.post.mockRejectedValueOnce(new Error('Network error'));

      await auth.logout();

      expect(auth.isAuthenticated.value).toBe(false);
      expect(localStorage.removeItem).toHaveBeenCalledWith('gli_auth_token');
    });
  });

  describe('refreshToken', () => {
    it('should refresh token successfully', async () => {
      localStorage.setItem('gli_auth_token', 'old-token');
      
      mockedAxios.post.mockResolvedValueOnce({
        data: { access_token: 'new-token' }
      });

      const result = await auth.refreshToken();

      expect(result).toBe(true);
      expect(auth.authToken.value).toBe('new-token');
      expect(localStorage.setItem).toHaveBeenCalledWith('gli_auth_token', 'new-token');
    });

    it('should logout on refresh token failure', async () => {
      localStorage.setItem('gli_auth_token', 'invalid-token');
      
      mockedAxios.post.mockRejectedValueOnce(new Error('Token expired'));

      const result = await auth.refreshToken();

      expect(result).toBe(false);
      expect(auth.isAuthenticated.value).toBe(false);
    });

    it('should return false when no token exists', async () => {
      const result = await auth.refreshToken();

      expect(result).toBe(false);
      expect(mockedAxios.post).not.toHaveBeenCalled();
    });
  });

  describe('updateProfile', () => {
    beforeEach(() => {
      auth.authToken.value = 'test-token';
    });

    it('should update profile successfully', async () => {
      const updatedProfile = { ...globalThis.testUtils.createMockUser(), email: 'updated@test.com' };
      
      mockedAxios.put.mockResolvedValueOnce({
        data: updatedProfile
      });

      const result = await auth.updateProfile({ email: 'updated@test.com' });

      expect(result.email).toBe('updated@test.com');
      expect(auth.userProfile.value).toEqual(updatedProfile);
      expect(localStorage.setItem).toHaveBeenCalledWith('gli_user_profile', JSON.stringify(updatedProfile));
    });

    it('should throw error when not authenticated', async () => {
      auth.authToken.value = null;

      await expect(auth.updateProfile({ email: 'test@test.com' })).rejects.toThrow('로그인이 필요합니다');
    });

    it('should handle update failure', async () => {
      mockedAxios.put.mockRejectedValueOnce({
        response: { data: { message: 'Update failed' } }
      });

      await expect(auth.updateProfile({ email: 'invalid' })).rejects.toThrow('Update failed');
    });
  });

  describe('initializeAuth', () => {
    it('should restore auth state from localStorage', () => {
      const mockUser = globalThis.testUtils.createMockUser();
      localStorage.setItem('gli_auth_token', 'stored-token');
      localStorage.setItem('gli_user_profile', JSON.stringify(mockUser));

      // refreshToken Mock (성공)
      mockedAxios.post.mockResolvedValueOnce({
        data: { access_token: 'refreshed-token' }
      });

      const newAuth = useSolanaAuth();

      expect(newAuth.isAuthenticated.value).toBe(true);
      expect(newAuth.authToken.value).toBe('stored-token');
      expect(newAuth.userProfile.value).toEqual(mockUser);
    });

    it('should logout when stored token is invalid', async () => {
      localStorage.setItem('gli_auth_token', 'invalid-token');
      localStorage.setItem('gli_user_profile', JSON.stringify(globalThis.testUtils.createMockUser()));

      // refreshToken Mock (실패)
      mockedAxios.post.mockRejectedValueOnce(new Error('Invalid token'));

      const newAuth = useSolanaAuth();

      // 비동기 작업 완료 대기
      await globalThis.testUtils.delay(100);

      expect(newAuth.isAuthenticated.value).toBe(false);
      expect(localStorage.removeItem).toHaveBeenCalledWith('gli_auth_token');
    });
  });

  describe('computed properties', () => {
    it('should return correct authentication state', () => {
      expect(auth.isAuthenticated.value).toBe(false);
      expect(auth.isAuthenticating.value).toBe(false);
      expect(auth.authToken.value).toBeNull();
      expect(auth.userProfile.value).toBeNull();
    });

    it('should update authentication state reactively', async () => {
      const mockUser = globalThis.testUtils.createMockUser();
      
      mockedAxios.post
        .mockResolvedValueOnce({ data: { nonce: 'test-nonce' } })
        .mockResolvedValueOnce({
          data: { access_token: 'test-token', user: mockUser }
        });

      await auth.authenticateWithWallet();

      expect(auth.isAuthenticated.value).toBe(true);
      expect(auth.authToken.value).toBe('test-token');
      expect(auth.userProfile.value).toEqual(mockUser);
    });
  });

  describe('error handling', () => {
    it('should handle network errors gracefully', async () => {
      mockedAxios.post.mockRejectedValueOnce(new Error('Network Error'));

      await expect(auth.authenticateWithWallet()).rejects.toThrow('인증에 실패했습니다');
    });

    it('should handle malformed API responses', async () => {
      mockedAxios.post.mockResolvedValueOnce({ data: {} }); // nonce 없음

      await expect(auth.authenticateWithWallet()).rejects.toThrow();
    });

    it('should handle missing phantom wallet', async () => {
      global.window.phantom = undefined;

      await expect(auth.authenticateWithWallet()).rejects.toThrow('메시지 서명에 실패했습니다');
    });
  });

  describe('message signing', () => {
    it('should create correct message format', async () => {
      mockedAxios.post.mockResolvedValueOnce({ data: { nonce: 'test-nonce-123' } });

      try {
        await auth.authenticateWithWallet();
      } catch {
        // 에러 무시, 메시지 생성 확인만
      }

      expect(global.window.phantom.solana.signMessage).toHaveBeenCalledWith(
        expect.any(Uint8Array),
        'utf8'
      );

      // 메시지 형식 검증
      const messageCall = global.window.phantom.solana.signMessage.mock.calls[0];
      const messageBytes = messageCall[0];
      const message = new TextDecoder().decode(messageBytes);
      
      expect(message).toContain('GLI Platform 로그인 인증');
      expect(message).toContain('지갑 주소: DjVE6JNiYqPL2QXyCUEwD9uKhAYpVy2xEf5jKNiVSB7U');
      expect(message).toContain('Nonce: test-nonce-123');
    });
  });
});