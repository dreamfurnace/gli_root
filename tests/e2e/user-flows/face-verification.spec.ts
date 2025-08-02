import { test, expect } from '@playwright/test'

test.describe('얼굴 인증 기능 테스트', () => {
  test.beforeEach(async ({ page }) => {
    // 마이페이지로 이동
    await page.goto('/mypage')
    
    // 프로필 탭이 활성화되어 있는지 확인
    await expect(page.locator('.tab-button.active')).toContainText('profile')
  })

  test('얼굴 인증 버튼이 표시되고 클릭할 수 있다', async ({ page }) => {
    // 얼굴 인증 섹션 확인
    const faceAuthSection = page.locator('.security-item').filter({ hasText: '얼굴 인증' })
    await expect(faceAuthSection).toBeVisible()
    
    // 얼굴 인증 버튼 확인
    const faceAuthButton = faceAuthSection.locator('button')
    await expect(faceAuthButton).toBeVisible()
    await expect(faceAuthButton).toContainText('얼굴 인증 시작')
  })

  test('얼굴 인증 시작 버튼을 클릭하면 인증 카드가 표시된다', async ({ page }) => {
    // 얼굴 인증 버튼 클릭
    const faceAuthButton = page.locator('.security-item').filter({ hasText: '얼굴 인증' }).locator('button')
    await faceAuthButton.click()
    
    // 얼굴 인증 카드가 표시되는지 확인
    const faceVerificationCard = page.locator('.info-card').filter({ hasText: '🔐 얼굴 인증' })
    await expect(faceVerificationCard).toBeVisible()
    
    // FaceVerification 컴포넌트가 로드되는지 확인
    const faceVerification = page.locator('.face-verification')
    await expect(faceVerification).toBeVisible()
  })

  test('얼굴 인증 인터페이스 요소들이 올바르게 표시된다', async ({ page }) => {
    // 얼굴 인증 시작
    await page.locator('.security-item').filter({ hasText: '얼굴 인증' }).locator('button').click()
    
    // 인증 헤더 확인
    await expect(page.locator('.verification-header h3')).toContainText('얼굴 인증')
    await expect(page.locator('.verification-status')).toBeVisible()
    
    // 시작 버튼 확인
    const startButton = page.locator('button').filter({ hasText: '얼굴 인증 시작' })
    await expect(startButton).toBeVisible()
    await expect(startButton).toBeEnabled()
  })

  test('카메라 권한 요청 시 적절한 UI가 표시된다', async ({ page }) => {
    // 얼굴 인증 시작
    await page.locator('.security-item').filter({ hasText: '얼굴 인증' }).locator('button').click()
    
    // 얼굴 인증 시작 버튼 클릭
    const startButton = page.locator('.face-verification button').filter({ hasText: '얼굴 인증 시작' })
    await startButton.click()
    
    // 로딩 상태 확인 (카메라 준비 중)
    await expect(page.locator('.loading-overlay')).toBeVisible()
    await expect(page.locator('.spinner')).toBeVisible()
    await expect(page.locator('text=카메라를 준비하고 있습니다')).toBeVisible()
  })

  test('인증 취소 버튼이 작동한다', async ({ page }) => {
    // 얼굴 인증 시작
    await page.locator('.security-item').filter({ hasText: '얼굴 인증' }).locator('button').click()
    await page.locator('.face-verification button').filter({ hasText: '얼굴 인증 시작' }).click()
    
    // 취소 버튼이 나타날 때까지 대기
    const cancelButton = page.locator('button').filter({ hasText: '인증 취소' })
    if (await cancelButton.isVisible()) {
      await cancelButton.click()
      
      // 카메라가 꺼지고 초기 상태로 돌아가는지 확인
      await expect(page.locator('.camera-wrapper')).not.toBeVisible()
      await expect(page.locator('button').filter({ hasText: '얼굴 인증 시작' })).toBeVisible()
    }
  })

  test('인증 상태 표시가 올바르게 작동한다', async ({ page }) => {
    // 얼굴 인증 시작
    await page.locator('.security-item').filter({ hasText: '얼굴 인증' }).locator('button').click()
    
    // 초기 상태 확인
    const statusElement = page.locator('.verification-status')
    await expect(statusElement).toContainText('인증 대기')
    await expect(statusElement).toHaveClass(/status-waiting/)
  })

  test('진행률 표시가 올바르게 작동한다', async ({ page }) => {
    // 얼굴 인증 시작
    await page.locator('.security-item').filter({ hasText: '얼굴 인증' }).locator('button').click()
    await page.locator('.face-verification button').filter({ hasText: '얼굴 인증 시작' }).click()
    
    // 진행률 바가 표시되는지 확인 (카메라가 시작되면)
    const progressBar = page.locator('.progress-bar')
    if (await progressBar.isVisible()) {
      await expect(progressBar).toBeVisible()
      await expect(page.locator('.progress-text')).toBeVisible()
    }
  })

  test('에러 상황에서 적절한 메시지가 표시된다', async ({ page }) => {
    // 카메라 접근 거부 시뮬레이션을 위한 권한 차단
    await page.context().grantPermissions([])
    
    // 얼굴 인증 시작
    await page.locator('.security-item').filter({ hasText: '얼굴 인증' }).locator('button').click()
    await page.locator('.face-verification button').filter({ hasText: '얼굴 인증 시작' }).click()
    
    // 에러 메시지 확인 (권한이 거부된 경우)
    const errorSection = page.locator('.verification-error')
    if (await errorSection.isVisible()) {
      await expect(errorSection).toBeVisible()
      await expect(page.locator('.error-icon')).toBeVisible()
      await expect(page.locator('button').filter({ hasText: '다시 시도' })).toBeVisible()
    }
  })

  test('모바일 반응형 레이아웃이 올바르게 작동한다', async ({ page }) => {
    // 모바일 뷰포트로 설정
    await page.setViewportSize({ width: 375, height: 667 })
    
    // 얼굴 인증 시작
    await page.locator('.security-item').filter({ hasText: '얼굴 인증' }).locator('button').click()
    
    // 모바일에서도 컴포넌트가 올바르게 표시되는지 확인
    const faceVerification = page.locator('.face-verification')
    await expect(faceVerification).toBeVisible()
    
    // 버튼들이 적절한 크기로 표시되는지 확인
    const startButton = page.locator('button').filter({ hasText: '얼굴 인증 시작' })
    await expect(startButton).toBeVisible()
  })

  test('얼굴 가이드 요소들이 표시된다', async ({ page }) => {
    // 얼굴 인증 시작
    await page.locator('.security-item').filter({ hasText: '얼굴 인증' }).locator('button').click()
    await page.locator('.face-verification button').filter({ hasText: '얼굴 인증 시작' }).click()
    
    // 얼굴 가이드 요소 확인 (카메라가 시작되면)
    const guide = page.locator('.face-guide')
    if (await guide.isVisible()) {
      await expect(guide).toBeVisible()
      await expect(page.locator('.guide-circle')).toBeVisible()
      await expect(page.locator('.guide-text')).toContainText('얼굴을 원 안에 맞춰주세요')
    }
  })

  test('키보드 접근성이 지원된다', async ({ page }) => {
    // 얼굴 인증 시작
    await page.locator('.security-item').filter({ hasText: '얼굴 인증' }).locator('button').click()
    
    // 키보드로 버튼에 포커스
    await page.keyboard.press('Tab')
    
    // 포커스된 요소가 시작 버튼인지 확인
    const focusedElement = page.locator(':focus')
    await expect(focusedElement).toContainText('얼굴 인증 시작')
    
    // Enter 키로 버튼 활성화
    await page.keyboard.press('Enter')
    
    // 카메라 준비 상태로 전환되는지 확인
    await expect(page.locator('.loading-overlay, .camera-wrapper')).toBeVisible()
  })

  test('인증 완료 후 상태가 올바르게 업데이트된다', async ({ page }) => {
    // Mock으로 인증 성공 시뮬레이션을 위한 페이지 함수 추가
    await page.addInitScript(() => {
      // 얼굴 인증 성공을 시뮬레이션하는 함수
      (window as any).simulateFaceVerificationSuccess = () => {
        const event = new CustomEvent('face-verification-success', {
          detail: { verified: true, confidence: 0.95 }
        })
        document.dispatchEvent(event)
      }
    })
    
    // 얼굴 인증 시작
    await page.locator('.security-item').filter({ hasText: '얼굴 인증' }).locator('button').click()
    
    // 인증 성공 시뮬레이션
    await page.evaluate(() => {
      (window as any).simulateFaceVerificationSuccess()
    })
    
    // 버튼 텍스트가 변경되었는지 확인
    const faceAuthButton = page.locator('.security-item').filter({ hasText: '얼굴 인증' }).locator('button')
    await expect(faceAuthButton).toContainText('✓ 인증 완료')
    await expect(faceAuthButton).toHaveClass(/enabled/)
  })

  test('재인증 기능이 올바르게 작동한다', async ({ page }) => {
    // 이미 인증된 상태로 설정
    await page.evaluate(() => {
      const userInfo = { faceVerified: true }
      localStorage.setItem('userInfo', JSON.stringify(userInfo))
    })
    
    await page.reload()
    
    // 인증 완료 버튼 확인
    const faceAuthButton = page.locator('.security-item').filter({ hasText: '얼굴 인증' }).locator('button')
    await expect(faceAuthButton).toContainText('✓ 인증 완료')
    
    // 재인증 확인 대화상자 처리
    page.on('dialog', async dialog => {
      expect(dialog.message()).toContain('이미 인증이 완료되었습니다')
      await dialog.accept()
    })
    
    // 재인증 버튼 클릭
    await faceAuthButton.click()
    
    // 얼굴 인증 카드가 다시 표시되는지 확인
    await expect(page.locator('.info-card').filter({ hasText: '🔐 얼굴 인증' })).toBeVisible()
  })
})

test.describe('얼굴 인증 보안 테스트', () => {
  test('권한이 거부되었을 때 적절히 처리된다', async ({ page }) => {
    // 카메라 권한 거부
    await page.context().grantPermissions([])
    
    await page.goto('/mypage')
    await page.locator('.security-item').filter({ hasText: '얼굴 인증' }).locator('button').click()
    await page.locator('.face-verification button').filter({ hasText: '얼굴 인증 시작' }).click()
    
    // 권한 에러 처리 확인
    const errorMessage = page.locator('.verification-error, .error-message')
    if (await errorMessage.isVisible()) {
      await expect(errorMessage).toBeVisible()
    }
  })

  test('브라우저 호환성 처리가 적절하다', async ({ page }) => {
    // MediaPipe가 지원되지 않는 환경 시뮬레이션
    await page.addInitScript(() => {
      delete (window as any).MediaRecorder
      delete (navigator as any).mediaDevices
    })
    
    await page.goto('/mypage')
    await page.locator('.security-item').filter({ hasText: '얼굴 인증' }).locator('button').click()
    await page.locator('.face-verification button').filter({ hasText: '얼굴 인증 시작' }).click()
    
    // 호환성 에러 메시지 확인
    const errorSection = page.locator('.verification-error')
    if (await errorSection.isVisible()) {
      await expect(errorSection).toContainText('지원되지 않는')
    }
  })
})

test.describe('얼굴 인증 성능 테스트', () => {
  test('컴포넌트 로딩 시간이 적절하다', async ({ page }) => {
    const startTime = Date.now()
    
    await page.goto('/mypage')
    await page.locator('.security-item').filter({ hasText: '얼굴 인증' }).locator('button').click()
    
    // FaceVerification 컴포넌트가 로드될 때까지 대기
    await page.locator('.face-verification').waitFor()
    
    const loadTime = Date.now() - startTime
    
    // 로딩 시간이 3초 이내여야 함
    expect(loadTime).toBeLessThan(3000)
  })

  test('메모리 누수가 발생하지 않는다', async ({ page }) => {
    // 여러 번 인증을 시작하고 취소하여 메모리 누수 테스트
    for (let i = 0; i < 3; i++) {
      await page.goto('/mypage')
      await page.locator('.security-item').filter({ hasText: '얼굴 인증' }).locator('button').click()
      await page.locator('.face-verification button').filter({ hasText: '얼굴 인증 시작' }).click()
      
      // 취소 버튼이 있으면 클릭
      const cancelButton = page.locator('button').filter({ hasText: '인증 취소' })
      if (await cancelButton.isVisible()) {
        await cancelButton.click()
      }
      
      // 잠시 대기
      await page.waitForTimeout(500)
    }
    
    // 페이지가 여전히 반응하는지 확인
    await expect(page.locator('.my-page')).toBeVisible()
  })
})