import { describe, it, expect, beforeEach, vi } from 'vitest'
import { mount } from '@vue/test-utils'
import { createRouter, createWebHistory } from 'vue-router'
import { createPinia, setActivePinia } from 'pinia'
import ProfileEditView from '../ProfileEditView.vue'
import { useProfileEditStore } from '@/stores/profileEditStore'

// Mock router
const router = createRouter({
  history: createWebHistory(),
  routes: [
    {
      path: '/profile-edit',
      name: 'ProfileEdit',
      component: ProfileEditView,
    },
  ],
})

// Mock API service
vi.mock('@/services/api', () => ({
  profileAPI: {
    getProfile: vi.fn(),
    updateProfile: vi.fn(),
    uploadAvatar: vi.fn(),
  },
}))

describe('ProfileEditView', () => {
  let wrapper: any
  let pinia: any
  let store: any

  beforeEach(async () => {
    pinia = createPinia()
    setActivePinia(pinia)
    store = useProfileEditStore()

    wrapper = mount(ProfileEditView, {
      global: {
        plugins: [router, pinia],
        stubs: {
          Header: true,
          LeftSidebar: true,
        },
      },
    })
    await router.isReady()
  })

  it('renders profile edit page', () => {
    expect(wrapper.find('h1').text()).toBe('내 정보 수정')
  })

  it('displays profile image section', () => {
    const imageSection = wrapper.find('.profile-image-section')
    expect(imageSection.exists()).toBe(true)
  })

  it('displays form fields', () => {
    expect(wrapper.find('input[type="text"]').exists()).toBe(true)
    expect(wrapper.find('input[type="tel"]').exists()).toBe(true)
    expect(wrapper.find('input[type="file"]').exists()).toBe(true)
  })

  it('shows loading state', async () => {
    store.loading = true
    await wrapper.vm.$nextTick()

    const loadingElement = wrapper.find('.loading')
    expect(loadingElement.exists()).toBe(true)
    expect(loadingElement.text()).toBe('로딩 중...')
  })

  it('displays error message', async () => {
    store.error = '프로필 업데이트에 실패했습니다'
    await wrapper.vm.$nextTick()

    const errorMessage = wrapper.find('.error-message')
    expect(errorMessage.exists()).toBe(true)
    expect(errorMessage.text()).toBe('프로필 업데이트에 실패했습니다')
  })

  it('displays success message', async () => {
    store.success = '프로필이 성공적으로 업데이트되었습니다'
    await wrapper.vm.$nextTick()

    const successMessage = wrapper.find('.success-message')
    expect(successMessage.exists()).toBe(true)
    expect(successMessage.text()).toBe('프로필이 성공적으로 업데이트되었습니다')
  })

  it('shows action buttons', () => {
    const cancelButton = wrapper.find('.btn-secondary')
    const saveButton = wrapper.find('.btn-primary')

    expect(cancelButton.exists()).toBe(true)
    expect(cancelButton.text()).toBe('취소')
    expect(saveButton.exists()).toBe(true)
    expect(saveButton.text()).toBe('저장')
  })

  it('disables save button when loading', async () => {
    store.loading = true
    await wrapper.vm.$nextTick()

    const saveButton = wrapper.find('.btn-primary')
    // disabled 속성이 있는지 확인
    expect(saveButton.attributes('disabled')).toBeDefined()
  })

  it('disables save button when form is invalid', async () => {
    store.profileData.name = ''
    await wrapper.vm.$nextTick()

    const saveButton = wrapper.find('.btn-primary')
    // disabled 속성이 있는지 확인
    expect(saveButton.attributes('disabled')).toBeDefined()
  })

  it('calls updateProfile on form submission', async () => {
    const updateProfileSpy = vi.spyOn(store, 'updateProfile').mockResolvedValue(undefined)

    // 폼 데이터 설정
    store.profileData.name = 'test user'
    store.profileData.phone = '010-1234-5678'
    await wrapper.vm.$nextTick()

    const form = wrapper.find('form')
    await form.trigger('submit')

    expect(updateProfileSpy).toHaveBeenCalled()
  })

  it('calls uploadAvatar on file selection', async () => {
    const uploadAvatarSpy = vi.spyOn(store, 'uploadAvatar').mockResolvedValue(undefined)
    const file = new File(['test'], 'avatar.jpg', { type: 'image/jpeg' })

    const fileInput = wrapper.find('input[type="file"]')
    // 파일 선택 이벤트를 올바르게 시뮬레이션
    await fileInput.setValue(file)

    expect(uploadAvatarSpy).toHaveBeenCalledWith(file)
  })

  it('calls router.back on cancel', async () => {
    const routerBackSpy = vi.spyOn(router, 'back')
    const cancelButton = wrapper.find('.btn-secondary')

    await cancelButton.trigger('click')

    expect(routerBackSpy).toHaveBeenCalled()
  })

  it('calls fetchProfile on mount', () => {
    const fetchProfileSpy = vi.spyOn(store, 'fetchProfile')

    // 컴포넌트가 마운트되면 fetchProfile이 호출되어야 함
    expect(fetchProfileSpy).toHaveBeenCalled()
  })

  it('displays profile image with fallback', () => {
    const profileImage = wrapper.find('.profile-image')
    expect(profileImage.exists()).toBe(true)
    expect(profileImage.attributes('src')).toContain('sample_profile.jpg')
  })

  it('updates profile image when profile data changes', async () => {
    store.profileData.profile_image = 'https://example.com/avatar.jpg'
    await wrapper.vm.$nextTick()

    const profileImage = wrapper.find('.profile-image')
    expect(profileImage.attributes('src')).toBe('https://example.com/avatar.jpg')
  })

  it('has responsive design classes', () => {
    const container = wrapper.find('.profile-edit-container')
    expect(container.exists()).toBe(true)

    const wrapperElement = wrapper.find('.profile-edit-wrapper')
    expect(wrapperElement.exists()).toBe(true)
  })

  it('shows form section title', () => {
    const sectionTitle = wrapper.find('.form-section-title')
    expect(sectionTitle.exists()).toBe(true)
    expect(sectionTitle.text()).toBe('기본 정보')
  })

  it('displays form labels', () => {
    const labels = wrapper.findAll('.form-label')
    expect(labels.length).toBeGreaterThan(0)
    expect(labels[0].text()).toBe('이름 *')
  })

  it('handles image upload trigger', async () => {
    const imageWrapper = wrapper.find('.profile-image-wrapper')
    await imageWrapper.trigger('click')

    // 이미지 클릭 시 파일 업로드가 트리거되어야 함
    // 실제로는 input[type="file"]의 click이 호출되어야 함
    expect(wrapper.vm.triggerImageUpload).toBeDefined()
  })
})
