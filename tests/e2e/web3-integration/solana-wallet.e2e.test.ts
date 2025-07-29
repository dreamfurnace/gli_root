/**
 * GLI Platform - Solana Wallet Integration E2E Tests
 * Web3 지갑 연동 및 인증 테스트
 */

import { test, expect, Page } from '@playwright/test';

test.describe('Solana Wallet Integration', () => {
  let page: Page;

  test.beforeEach(async ({ browser }) => {
    // 새 브라우저 컨텍스트 생성 (Phantom 지갑 Mock 포함)
    const context = await browser.newContext();
    
    // Phantom 지갑 Mock 주입
    await context.addInitScript(() => {
      // @ts-ignore
      window.phantom = {
        solana: {
          isPhantom: true,
          isConnected: false,
          publicKey: null,
          connect: async () => {
            return new Promise((resolve) => {
              // @ts-ignore
              window.phantom.solana.isConnected = true;
              // @ts-ignore  
              window.phantom.solana.publicKey = {
                toString: () => 'DjVE6JNiYqPL2QXyCUEwD9uKhAYpVy2xEf5jKNiVSB7U'
              };
              resolve({ publicKey: window.phantom.solana.publicKey });
            });
          },
          disconnect: async () => {
            // @ts-ignore
            window.phantom.solana.isConnected = false;
            // @ts-ignore
            window.phantom.solana.publicKey = null;
          },
          signMessage: async (message: Uint8Array) => {
            // Mock 서명 생성
            const signature = new Uint8Array(64).fill(0);
            return {
              signature,
              publicKey: window.phantom.solana.publicKey
            };
          }
        }
      };
    });

    page = await context.newPage();
  });

  test('should detect Phantom wallet', async () => {
    await page.goto('/');
    
    // Phantom 지갑 감지 확인
    const isPhantomDetected = await page.evaluate(() => {
      return typeof window.phantom?.solana !== 'undefined';
    });
    
    expect(isPhantomDetected).toBe(true);
  });

  test('should display wallet connection button', async () => {
    await page.goto('/');
    
    // 지갑 연결 버튼 확인
    const walletButton = page.locator('[data-testid="phantom-wallet-button"]');
    await expect(walletButton).toBeVisible();
    await expect(walletButton).toContainText('팬텀으로 GLI 로그인');
  });

  test('should connect wallet successfully', async () => {
    await page.goto('/');
    
    // 지갑 연결 버튼 클릭
    const walletButton = page.locator('[data-testid="phantom-wallet-button"]');
    await walletButton.click();
    
    // 연결 중 상태 확인
    await expect(walletButton).toContainText('지갑 연결 중...');
    
    // 연결 완료 후 상태 확인
    await expect(page.locator('[data-testid="wallet-address"]')).toBeVisible();
    await expect(page.locator('[data-testid="wallet-address"]')).toContainText('DjVE6JNi');
  });

  test('should authenticate with wallet signature', async () => {
    await page.goto('/');
    
    // API 호출 Mock 설정
    await page.route('**/api/auth/nonce/', async route => {
      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          nonce: 'test-nonce-12345',
          expires_in: 300,
          message: 'GLI Platform 로그인을 위한 nonce가 발급되었습니다. 🎉'
        })
      });
    });

    await page.route('**/api/auth/verify/', async route => {
      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          access_token: 'test-jwt-token',
          refresh_token: 'test-refresh-token',
          user: {
            id: 'test-user-id',
            wallet_address: 'DjVE6JNiYqPL2QXyCUEwD9uKhAYpVy2xEf5jKNiVSB7U',
            username: 'test_user',
            membership_level: 'premium'
          },
          message: '🎉 GLI Platform 인증이 완료되었습니다!'
        })
      });
    });

    // 지갑 연결 및 인증
    const walletButton = page.locator('[data-testid="phantom-wallet-button"]');
    await walletButton.click();
    
    // 인증 중 상태 확인
    await expect(walletButton).toContainText('GLI 인증 중...');
    
    // 인증 완료 후 드롭다운 메뉴 표시 확인
    await expect(page.locator('[data-testid="wallet-dropdown"]')).toBeVisible();
    await expect(page.locator('[data-testid="auth-status"]')).toContainText('GLI 회원 인증 완료');
  });

  test('should display wallet balance', async () => {
    await page.goto('/');
    
    // Solana RPC Mock 설정
    await page.route('**/api/devnet.solana.com', async route => {
      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          result: {
            value: 2500000000 // 2.5 SOL in lamports
          }
        })
      });
    });

    // 지갑 연결
    const walletButton = page.locator('[data-testid="phantom-wallet-button"]');
    await walletButton.click();
    
    // 드롭다운 열기
    const dropdown = page.locator('[data-testid="wallet-dropdown"]');
    await dropdown.click();
    
    // 잔액 표시 확인
    await expect(page.locator('[data-testid="sol-balance"]')).toContainText('2.5000 SOL');
    await expect(page.locator('[data-testid="network-info"]')).toContainText('Devnet 테스트넷');
  });

  test('should request airdrop successfully', async () => {
    await page.goto('/');
    
    // Airdrop API Mock 설정
    await page.route('**/requestAirdrop', async route => {
      await route.fulfill({
        status: 200,
        contentType: 'application/json',
        body: JSON.stringify({
          signature: '5VfYKa7nUGfGqiAELvG2fS4aVnm2MxSoWKYnq1cNjMhP3pMx2aVnKqUNnNcJfN'
        })
      });
    });

    // 지갑 연결 및 드롭다운 열기
    const walletButton = page.locator('[data-testid="phantom-wallet-button"]');
    await walletButton.click();
    
    const dropdown = page.locator('[data-testid="wallet-dropdown"]');
    await dropdown.click();
    
    // 에어드랍 버튼 클릭
    const airdropButton = page.locator('[data-testid="airdrop-button"]');
    await airdropButton.click();
    
    // 에어드랍 진행 중 상태 확인
    await expect(airdropButton).toContainText('에어드랍 중...');
    
    // 에어드랍 완료 후 상태 확인
    await expect(airdropButton).toContainText('테스트 SOL 받기 🎁');
  });

  test('should disconnect wallet properly', async () => {
    await page.goto('/');
    
    // 지갑 연결
    const walletButton = page.locator('[data-testid="phantom-wallet-button"]');
    await walletButton.click();
    
    // 드롭다운 열기
    const dropdown = page.locator('[data-testid="wallet-dropdown"]');
    await dropdown.click();
    
    // 연결 해제 버튼 클릭
    const disconnectButton = page.locator('[data-testid="disconnect-button"]');
    await disconnectButton.click();
    
    // 원래 상태로 돌아간 것 확인
    await expect(page.locator('[data-testid="phantom-wallet-button"]')).toContainText('팬텀으로 GLI 로그인');
    await expect(page.locator('[data-testid="wallet-dropdown"]')).not.toBeVisible();
  });

  test('should handle wallet connection errors', async () => {
    await page.goto('/');
    
    // 지갑 에러 Mock 설정
    await page.addInitScript(() => {
      // @ts-ignore
      window.phantom.solana.connect = async () => {
        throw new Error('User rejected the request');
      };
    });

    // 지갑 연결 시도
    const walletButton = page.locator('[data-testid="phantom-wallet-button"]');
    await walletButton.click();
    
    // 에러 메시지 확인
    await expect(page.locator('[data-testid="error-message"]')).toContainText('지갑 연결을 거부했습니다');
    
    // 버튼이 원래 상태로 돌아간 것 확인
    await expect(walletButton).toContainText('팬텀으로 GLI 로그인');
  });

  test('should handle authentication errors', async () => {
    await page.goto('/');
    
    // API 에러 Mock 설정
    await page.route('**/api/auth/verify/', async route => {
      await route.fulfill({
        status: 401,
        contentType: 'application/json',
        body: JSON.stringify({
          error: 'Invalid signature',
          message: '서명 검증에 실패했습니다'
        })
      });
    });

    // 지갑 연결 시도
    const walletButton = page.locator('[data-testid="phantom-wallet-button"]');
    await walletButton.click();
    
    // 인증 에러 메시지 확인
    await expect(page.locator('[data-testid="auth-error"]')).toContainText('서명 검증에 실패했습니다');
  });

  test('should persist authentication state', async () => {
    await page.goto('/');
    
    // localStorage에 인증 정보 설정
    await page.evaluate(() => {
      localStorage.setItem('gli_auth_token', 'test-jwt-token');
      localStorage.setItem('gli_user_profile', JSON.stringify({
        id: 'test-user-id',
        wallet_address: 'DjVE6JNiYqPL2QXyCUEwD9uKhAYpVy2xEf5jKNiVSB7U',
        username: 'test_user',
        membership_level: 'premium'
      }));
    });

    // 페이지 새로고침
    await page.reload();
    
    // 인증 상태가 복원된 것 확인
    await expect(page.locator('[data-testid="wallet-dropdown"]')).toBeVisible();
    await expect(page.locator('[data-testid="wallet-address"]')).toContainText('DjVE6JNi');
  });

  test('should handle network changes', async () => {
    await page.goto('/');
    
    // 네트워크 변경 이벤트 Mock
    await page.evaluate(() => {
      // @ts-ignore
      window.phantom.solana.on = (event: string, callback: Function) => {
        if (event === 'networkChanged') {
          setTimeout(() => callback('mainnet-beta'), 1000);
        }
      };
    });

    // 지갑 연결
    const walletButton = page.locator('[data-testid="phantom-wallet-button"]');
    await walletButton.click();
    
    // 네트워크 변경 감지 확인
    await expect(page.locator('[data-testid="network-warning"]')).toContainText('네트워크가 변경되었습니다');
  });

  test.afterEach(async () => {
    await page.close();
  });
});