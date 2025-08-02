import { test, expect } from '@playwright/test'

test.describe('Main User Flow Tests', () => {
  test.beforeEach(async ({ page }) => {
    // 각 테스트 전에 기본 URL로 이동
    await page.goto('http://localhost:5173')
  })

  test('사용자 등록 및 로그인 흐름', async ({ page }) => {
    // 1. 회원가입 페이지로 이동
    await page.click('text=회원가입')
    await expect(page).toHaveURL(/.*register/)

    // 2. 회원가입 폼 작성
    await page.fill('input[type="email"]', 'test@example.com')
    await page.fill('input[name="name"]', 'Test User')
    await page.fill('input[name="password"]', 'password123')
    await page.fill('input[name="password_confirm"]', 'password123')

    // 3. 회원가입 제출
    await page.click('button[type="submit"]')

    // 4. 로그인 페이지로 리다이렉트 확인
    await expect(page).toHaveURL(/.*login/)

    // 5. 로그인
    await page.fill('input[type="email"]', 'test@example.com')
    await page.fill('input[type="password"]', 'password123')
    await page.click('button[type="submit"]')

    // 6. 로그인 성공 후 대시보드로 이동 확인
    await expect(page).toHaveURL(/.*dashboard/)
    await expect(page.locator('text=Test User')).toBeVisible()
  })

  test('법률 검색 및 상세 조회 흐름', async ({ page }) => {
    // 1. 로그인
    await page.goto('http://localhost:5173/login')
    await page.fill('input[type="email"]', 'test@example.com')
    await page.fill('input[type="password"]', 'password123')
    await page.click('button[type="submit"]')

    // 2. 법률 검색 페이지로 이동
    await page.click('text=법률 검색')
    await expect(page).toHaveURL(/.*law-search/)

    // 3. 검색어 입력
    await page.fill('input[placeholder*="검색"]', '부동산')
    await page.click('button[type="submit"]')

    // 4. 검색 결과 확인
    await expect(page.locator('.search-results')).toBeVisible()
    await expect(page.locator('.law-item')).toHaveCount(1)

    // 5. 첫 번째 결과 클릭하여 상세 페이지로 이동
    await page.click('.law-item:first-child')
    await expect(page).toHaveURL(/.*case-detail/)

    // 6. 상세 정보 확인
    await expect(page.locator('.law-title')).toBeVisible()
    await expect(page.locator('.law-content')).toBeVisible()
  })

  test('케이스룸 생성 및 관리 흐름', async ({ page }) => {
    // 1. 로그인
    await page.goto('http://localhost:5173/login')
    await page.fill('input[type="email"]', 'test@example.com')
    await page.fill('input[type="password"]', 'password123')
    await page.click('button[type="submit"]')

    // 2. 케이스룸 목록 페이지로 이동
    await page.click('text=케이스룸')
    await expect(page).toHaveURL(/.*case-rooms/)

    // 3. 새 케이스룸 생성 버튼 클릭
    await page.click('text=새 케이스룸')
    await expect(page).toHaveURL(/.*case-room-create/)

    // 4. 케이스룸 정보 입력
    await page.fill('input[name="title"]', 'Test Case Room')
    await page.fill('textarea[name="address"]', 'Test Address, Seoul')
    await page.selectOption('select[name="status"]', 'in-progress')

    // 5. 케이스룸 생성
    await page.click('button[type="submit"]')

    // 6. 생성된 케이스룸 상세 페이지로 이동 확인
    await expect(page).toHaveURL(/.*case-room-detail/)
    await expect(page.locator('text=Test Case Room')).toBeVisible()

    // 7. 케이스룸 수정
    await page.click('text=수정')
    await page.fill('input[name="title"]', 'Updated Case Room')
    await page.click('button[type="submit"]')

    // 8. 수정된 내용 확인
    await expect(page.locator('text=Updated Case Room')).toBeVisible()
  })

  test('계약서 작성 및 협상 흐름', async ({ page }) => {
    // 1. 로그인
    await page.goto('http://localhost:5173/login')
    await page.fill('input[type="email"]', 'test@example.com')
    await page.fill('input[type="password"]', 'password123')
    await page.click('button[type="submit"]')

    // 2. 계약서 목록 페이지로 이동
    await page.click('text=계약서')
    await expect(page).toHaveURL(/.*contracts/)

    // 3. 새 계약서 생성
    await page.click('text=새 계약서')
    await expect(page).toHaveURL(/.*contract-create/)

    // 4. 계약서 정보 입력
    await page.fill('input[name="name"]', 'Test Contract')
    await page.selectOption('select[name="contract_type"]', '1') // 첫 번째 템플릿 선택

    // 5. 계약서 생성
    await page.click('button[type="submit"]')

    // 6. 계약서 편집 페이지로 이동 확인
    await expect(page).toHaveURL(/.*contract-edit/)
    await expect(page.locator('text=Test Contract')).toBeVisible()

    // 7. 계약서 내용 편집
    await page.fill('.contract-content', 'This is a test contract content.')
    await page.click('text=저장')

    // 8. 저장 완료 확인
    await expect(page.locator('text=저장되었습니다')).toBeVisible()
  })

  test('문서 업로드 및 관리 흐름', async ({ page }) => {
    // 1. 로그인
    await page.goto('http://localhost:5173/login')
    await page.fill('input[type="email"]', 'test@example.com')
    await page.fill('input[type="password"]', 'password123')
    await page.click('button[type="submit"]')

    // 2. 케이스룸으로 이동
    await page.click('text=케이스룸')
    await page.click('.case-room-item:first-child')

    // 3. 문서 탭 클릭
    await page.click('text=문서')

    // 4. 파일 업로드
    const fileInput = page.locator('input[type="file"]')
    await fileInput.setInputFiles('e2e/fixtures/test-document.pdf')

    // 5. 문서 타입 선택
    await page.selectOption('select[name="doc_type"]', '등기부등본')

    // 6. 업로드 버튼 클릭
    await page.click('text=업로드')

    // 7. 업로드 완료 확인
    await expect(page.locator('text=업로드 완료')).toBeVisible()
    await expect(page.locator('.document-item')).toBeVisible()

    // 8. 문서 다운로드 테스트
    await page.click('.document-item .download-button')
    // 다운로드 확인은 브라우저별로 다르므로 생략

    // 9. 문서 삭제 테스트
    await page.click('.document-item .delete-button')
    await page.click('text=확인')

    // 10. 삭제 완료 확인
    await expect(page.locator('.document-item')).not.toBeVisible()
  })

  test('실시간 채팅 흐름', async ({ page, context }) => {
    // 1. 로그인
    await page.goto('http://localhost:5173/login')
    await page.fill('input[type="email"]', 'test@example.com')
    await page.fill('input[type="password"]', 'password123')
    await page.click('button[type="submit"]')

    // 2. 계약서로 이동
    await page.click('text=계약서')
    await page.click('.contract-item:first-child')

    // 3. 채팅 탭 클릭
    await page.click('text=채팅')

    // 4. 채팅 인터페이스 확인
    await expect(page.locator('.chat-messages')).toBeVisible()
    await expect(page.locator('.chat-input')).toBeVisible()

    // 5. 메시지 전송
    await page.fill('.chat-input', 'Hello, this is a test message')
    await page.click('.send-button')

    // 6. 메시지 표시 확인
    await expect(page.locator('text=Hello, this is a test message')).toBeVisible()

    // 7. 파일 업로드 테스트
    const fileInput = page.locator('.chat-file-input')
    await fileInput.setInputFiles('e2e/fixtures/test-file.txt')

    // 8. 파일 메시지 표시 확인
    await expect(page.locator('.file-message')).toBeVisible()
  })

  test('검색 및 필터링 기능', async ({ page }) => {
    // 1. 로그인
    await page.goto('http://localhost:5173/login')
    await page.fill('input[type="email"]', 'test@example.com')
    await page.fill('input[type="password"]', 'password123')
    await page.click('button[type="submit"]')

    // 2. 전역 검색 사용
    await page.fill('.global-search input', 'test')
    await page.click('.global-search button')

    // 3. 검색 결과 확인
    await expect(page.locator('.search-results')).toBeVisible()

    // 4. 고급 검색 사용
    await page.click('text=고급 검색')
    await page.fill('input[name="query"]', 'contract')
    await page.check('input[name="models"][value="contract"]')
    await page.click('button[type="submit"]')

    // 5. 필터링된 결과 확인
    await expect(page.locator('.search-results')).toBeVisible()
  })

  test('반응형 디자인 테스트', async ({ page }) => {
    // 1. 모바일 뷰포트 설정
    await page.setViewportSize({ width: 375, height: 667 })

    // 2. 로그인
    await page.goto('http://localhost:5173/login')
    await page.fill('input[type="email"]', 'test@example.com')
    await page.fill('input[type="password"]', 'password123')
    await page.click('button[type="submit"]')

    // 3. 모바일 메뉴 확인
    await expect(page.locator('.mobile-menu-button')).toBeVisible()

    // 4. 모바일 메뉴 열기
    await page.click('.mobile-menu-button')
    await expect(page.locator('.mobile-menu')).toBeVisible()

    // 5. 태블릿 뷰포트로 변경
    await page.setViewportSize({ width: 768, height: 1024 })

    // 6. 태블릿 레이아웃 확인
    await expect(page.locator('.sidebar')).toBeVisible()

    // 7. 데스크톱 뷰포트로 복원
    await page.setViewportSize({ width: 1920, height: 1080 })
  })

  test('에러 처리 및 예외 상황', async ({ page }) => {
    // 1. 잘못된 URL 접근
    await page.goto('http://localhost:5173/nonexistent-page')
    await expect(page.locator('text=페이지를 찾을 수 없습니다')).toBeVisible()

    // 2. 로그인 실패
    await page.goto('http://localhost:5173/login')
    await page.fill('input[type="email"]', 'wrong@example.com')
    await page.fill('input[type="password"]', 'wrongpassword')
    await page.click('button[type="submit"]')

    await expect(page.locator('text=잘못된 이메일 또는 비밀번호')).toBeVisible()

    // 3. 네트워크 오류 시뮬레이션
    await page.route('**/api/**', (route) => route.abort())

    await page.goto('http://localhost:5173/login')
    await page.fill('input[type="email"]', 'test@example.com')
    await page.fill('input[type="password"]', 'password123')
    await page.click('button[type="submit"]')

    await expect(page.locator('text=네트워크 오류')).toBeVisible()
  })

  test('성능 및 로딩 테스트', async ({ page }) => {
    // 1. 페이지 로딩 시간 측정
    const startTime = Date.now()
    await page.goto('http://localhost:5173')
    const loadTime = Date.now() - startTime

    // 로딩 시간이 3초 이내여야 함
    expect(loadTime).toBeLessThan(3000)

    // 2. 로딩 스피너 확인
    await page.click('text=법률 검색')
    await expect(page.locator('.loading-spinner')).toBeVisible()
    await expect(page.locator('.loading-spinner')).not.toBeVisible()

    // 3. 무한 스크롤 테스트 (대량 데이터)
    await page.goto('http://localhost:5173/law-search')
    await page.fill('input[placeholder*="검색"]', 'test')
    await page.click('button[type="submit"]')

    // 스크롤하여 더 많은 결과 로드
    await page.evaluate(() => {
      window.scrollTo(0, document.body.scrollHeight)
    })

    await expect(page.locator('.law-item')).toHaveCount(20) // 페이지네이션 확인
  })
})
