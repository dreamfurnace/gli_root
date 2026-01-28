import { test, expect } from '@playwright/test';

/**
 * GLI 운영 환경 로그인 테스트
 *
 * 테스트 대상:
 * - https://glibiz.com/login (사용자 프론트엔드)
 * - https://admin.glibiz.com/login (관리자 프론트엔드)
 * - https://stg-api.glibiz.com/admin/login/ (스테이징 Django Admin)
 */

test.describe('GLI Production - User Frontend Login', () => {
  test('should load production user login page', async ({ page }) => {
    await page.goto('https://glibiz.com/login');

    // 페이지 타이틀 확인
    await expect(page).toHaveTitle(/GLI/);

    // 로그인 페이지 요소 확인
    await expect(page.locator('h1, h2').filter({ hasText: /로그인|Login/i })).toBeVisible({ timeout: 10000 });
  });

  test('should login to production user frontend with valid credentials', async ({ page }) => {
    await page.goto('https://glibiz.com/login');

    // 로그인 폼이 로드될 때까지 대기
    await page.waitForLoadState('networkidle');

    // 로그인 폼 요소 찾기 (다양한 선택자 시도)
    const emailInput = page.locator('input[type="email"], input[name="email"], input[id*="email"], input[placeholder*="이메일"]').first();
    const passwordInput = page.locator('input[type="password"], input[name="password"], input[id*="password"]').first();
    const loginButton = page.locator('button[type="submit"], button:has-text("로그인"), button:has-text("Login")').first();

    // 폼 요소가 보이는지 확인
    await expect(emailInput).toBeVisible({ timeout: 10000 });
    await expect(passwordInput).toBeVisible({ timeout: 10000 });
    await expect(loginButton).toBeVisible({ timeout: 10000 });

    // 테스트 계정으로 로그인 (환경 변수에서 가져오기)
    const testEmail = process.env.TEST_USER_EMAIL || 'ahndong@user.gli.com';
    const testPassword = process.env.TEST_USER_PASSWORD || 'test123!';

    await emailInput.fill(testEmail);
    await passwordInput.fill(testPassword);
    await loginButton.click();

    // 로그인 성공 후 리다이렉트 확인 (대시보드 또는 홈페이지)
    await page.waitForURL(/.*\/(?:dashboard|home|)/, { timeout: 15000 });

    // 로그인 후 페이지 확인
    await expect(page.locator('text=/환영|Welcome|대시보드|Dashboard/i').first()).toBeVisible({ timeout: 10000 });
  });
});

test.describe('GLI Production - Admin Frontend Login', () => {
  test('should load production admin login page', async ({ page }) => {
    await page.goto('https://admin.glibiz.com/login');

    // 페이지 타이틀 확인
    await expect(page).toHaveTitle(/GLI/);

    // 관리자 로그인 페이지 요소 확인
    await expect(page.locator('text=/관리자|Admin/i')).toBeVisible({ timeout: 10000 });
  });

  test('should login to production admin frontend with valid credentials', async ({ page }) => {
    await page.goto('https://admin.glibiz.com/login');

    // 로그인 폼이 로드될 때까지 대기
    await page.waitForLoadState('networkidle');

    // 로그인 폼 요소 찾기
    const usernameInput = page.locator('input[id="username"], input[name="username"], input[type="text"]').first();
    const passwordInput = page.locator('input[id="password"], input[type="password"]').first();
    const loginButton = page.locator('button[type="submit"]').first();

    // 폼 요소가 보이는지 확인
    await expect(usernameInput).toBeVisible({ timeout: 10000 });
    await expect(passwordInput).toBeVisible({ timeout: 10000 });
    await expect(loginButton).toBeVisible({ timeout: 10000 });

    // 테스트 관리자 계정으로 로그인
    const testAdmin = process.env.TEST_ADMIN_EMAIL || 'ahndong@admin.gli.com';
    const testAdminPassword = process.env.TEST_ADMIN_PASSWORD || 'admin123!';

    await usernameInput.fill(testAdmin);
    await passwordInput.fill(testAdminPassword);
    await loginButton.click();

    // 로그인 성공 확인 - 관리자 대시보드로 리다이렉트
    await page.waitForURL(/.*\/admin/, { timeout: 15000 });

    // 관리자 대시보드 요소 확인
    await expect(page.locator('text=/GLI 관리자|Admin Panel|Dashboard/i').first()).toBeVisible({ timeout: 10000 });
  });
});

test.describe('GLI Staging - Django Admin Login', () => {
  test('should load staging Django admin login page', async ({ page }) => {
    await page.goto('https://stg-api.glibiz.com/admin/login/');

    // Django Admin 페이지 확인
    await expect(page).toHaveTitle(/Log in | Django/);

    // 로그인 폼 요소 확인
    await expect(page.locator('input[name="username"]')).toBeVisible();
    await expect(page.locator('input[name="password"]')).toBeVisible();
  });

  test('should login to staging Django admin with valid credentials', async ({ page }) => {
    await page.goto('https://stg-api.glibiz.com/admin/login/');

    // 로그인 폼 요소
    const usernameInput = page.locator('input[name="username"]');
    const passwordInput = page.locator('input[name="password"]');
    const loginButton = page.locator('input[type="submit"]');

    // Django 슈퍼유저 계정으로 로그인
    const testSuperuser = process.env.TEST_SUPERUSER_USERNAME || 'ahndong';
    const testSuperuserPassword = process.env.TEST_SUPERUSER_PASSWORD || 'admin123!';

    await usernameInput.fill(testSuperuser);
    await passwordInput.fill(testSuperuserPassword);
    await loginButton.click();

    // 로그인 성공 후 Django Admin 페이지 확인
    await expect(page).toHaveURL(/.*\/admin\//);
    await expect(page.locator('text=Site administration')).toBeVisible({ timeout: 10000 });
  });
});

test.describe('GLI Production - Error Handling', () => {
  test('should show error for invalid user credentials', async ({ page }) => {
    await page.goto('https://glibiz.com/login');

    await page.waitForLoadState('networkidle');

    const emailInput = page.locator('input[type="email"], input[name="email"]').first();
    const passwordInput = page.locator('input[type="password"]').first();
    const loginButton = page.locator('button[type="submit"]').first();

    // 잘못된 자격 증명
    await emailInput.fill('invalid@user.com');
    await passwordInput.fill('wrongpassword');
    await loginButton.click();

    // 에러 메시지 확인
    await expect(page.locator('text=/오류|Error|실패|Failed|잘못|Invalid/i').first()).toBeVisible({ timeout: 10000 });
  });

  test('should show error for invalid admin credentials', async ({ page }) => {
    await page.goto('https://admin.glibiz.com/login');

    await page.waitForLoadState('networkidle');

    const usernameInput = page.locator('input[id="username"]').first();
    const passwordInput = page.locator('input[id="password"]').first();
    const loginButton = page.locator('button[type="submit"]').first();

    // 잘못된 자격 증명
    await usernameInput.fill('invalidadmin');
    await passwordInput.fill('wrongpassword');
    await loginButton.click();

    // 에러 메시지 확인
    await expect(page.locator('.bg-red-50, .text-red-500, [class*="error"]').first()).toBeVisible({ timeout: 10000 });
  });
});
