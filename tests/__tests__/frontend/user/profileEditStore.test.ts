// Jest globals - no import needed
import { setActivePinia, createPinia } from 'pinia'
import { useProfileEditStore } from '../profileEditStore'
import { profileAPI } from '@/services/api'
import type { AxiosResponse } from 'axios'

// Mock API service
jest.mock('@/services/api', () => ({
  profileAPI: {
    getProfile: jest.fn(),
    updateProfile: jest.fn(),
    uploadAvatar: jest.fn(),
  },
}))

// Mock AxiosResponse 생성 함수
const createMockResponse = <T>(data: T): AxiosResponse<T> => ({
  data,
  status: 200,
  statusText: 'OK',
  headers: {},
  config: {} as any,
})

describe('ProfileEditStore', () => {
  let store: any

  beforeEach(() => {
    setActivePinia(createPinia())
    store = useProfileEditStore()
    jest.clearAllMocks()
  })

  describe('initial state', () => {
    it('has correct initial state', () => {
      expect(store.profileData).toEqual({
        name: '',
        phone: '',
        profile_image: '',
      })
      expect(store.loading).toBe(false)
      expect(store.error).toBe(null)
      expect(store.success).toBe(null)
    })
  })

  describe('fetchProfile', () => {
    it('fetches profile successfully', async () => {
      const mockProfile = {
        name: 'testuser',
        phone: '010-1234-5678',
        profile_image: 'https://example.com/avatar.jpg',
      }
      const mockResponse = createMockResponse(mockProfile)

      jest.mocked(profileAPI.getProfile).mockResolvedValue(mockResponse)

      await store.fetchProfile()

      expect(profileAPI.getProfile).toHaveBeenCalled()
      expect(store.profileData).toEqual(mockProfile)
      expect(store.error).toBe(null)
    })

    it('handles fetch error', async () => {
      const errorMessage = 'Failed to fetch profile'
      jest.mocked(profileAPI.getProfile).mockRejectedValue(new Error(errorMessage))

      await store.fetchProfile()

      expect(store.error).toBe(errorMessage)
      expect(store.profileData).toEqual({
        name: '',
        phone: '',
        profile_image: '',
      })
    })

    it('sets loading state during fetch', async () => {
      jest.mocked(profileAPI.getProfile).mockImplementation(
        () => new Promise((resolve) => setTimeout(resolve, 100)),
      )

      const fetchPromise = store.fetchProfile()

      expect(store.loading).toBe(true)

      await fetchPromise

      expect(store.loading).toBe(false)
    })
  })

  describe('updateProfile', () => {
    it('updates profile successfully', async () => {
      // 유효한 데이터로 설정
      store.profileData.name = 'testuser'
      store.profileData.phone = '010-1234-5678'

      const profileData = {
        name: 'newuser',
        phone: '010-9876-5432',
      }
      const mockResponse = createMockResponse(profileData)

      jest.mocked(profileAPI.updateProfile).mockResolvedValue(mockResponse)

      await store.updateProfile()

      expect(profileAPI.updateProfile).toHaveBeenCalledWith(store.profileData)
      expect(store.success).toBe('프로필이 성공적으로 업데이트되었습니다.')
      expect(store.error).toBe(null)
    })

    it('handles update error', async () => {
      // 유효한 데이터로 설정
      store.profileData.name = 'testuser'

      const errorMessage = 'Failed to update profile'
      jest.mocked(profileAPI.updateProfile).mockRejectedValue(new Error(errorMessage))

      await store.updateProfile()

      expect(store.error).toBe(errorMessage)
      expect(store.success).toBe(null)
    })

    it('validates form before update', async () => {
      store.profileData.name = ''

      await store.updateProfile()

      expect(store.error).toBe('이름을 입력해주세요.')
      expect(profileAPI.updateProfile).not.toHaveBeenCalled()
    })

    it('sets loading state during update', async () => {
      // 유효한 데이터로 설정
      store.profileData.name = 'testuser'

      jest.mocked(profileAPI.updateProfile).mockImplementation(
        () => new Promise((resolve) => setTimeout(resolve, 100)),
      )

      const updatePromise = store.updateProfile()

      expect(store.loading).toBe(true)

      await updatePromise

      expect(store.loading).toBe(false)
    })
  })

  describe('uploadAvatar', () => {
    it('uploads avatar successfully', async () => {
      const file = new File(['test'], 'avatar.jpg', { type: 'image/jpeg' })
      const mockResponse = createMockResponse({
        profile: { profile_image: 'https://example.com/new-avatar.jpg' },
      })

      jest.mocked(profileAPI.uploadAvatar).mockResolvedValue(mockResponse)

      await store.uploadAvatar(file)

      expect(profileAPI.uploadAvatar).toHaveBeenCalledWith(file)
      expect(store.profileData.profile_image).toBe('https://example.com/new-avatar.jpg')
      expect(store.success).toBe('아바타가 성공적으로 업로드되었습니다.')
      expect(store.error).toBe(null)
    })

    it('handles upload error', async () => {
      const file = new File(['test'], 'avatar.jpg', { type: 'image/jpeg' })
      const errorMessage = 'Failed to upload avatar'
      jest.mocked(profileAPI.uploadAvatar).mockRejectedValue(new Error(errorMessage))

      await store.uploadAvatar(file)

      expect(store.error).toBe(errorMessage)
      expect(store.success).toBe(null)
    })

    it('sets loading state during upload', async () => {
      const file = new File(['test'], 'avatar.jpg', { type: 'image/jpeg' })
      const mockResponse = createMockResponse({
        profile: { profile_image: 'https://example.com/new-avatar.jpg' },
      })

      jest.mocked(profileAPI.uploadAvatar).mockImplementation(
        () => new Promise((resolve) => setTimeout(() => resolve(mockResponse), 100)),
      )

      const uploadPromise = store.uploadAvatar(file)

      expect(store.loading).toBe(true)

      await uploadPromise

      expect(store.loading).toBe(false)
    })
  })

  describe('updateProfileImage', () => {
    it('updates profile image URL', () => {
      const imageUrl = 'https://example.com/new-image.jpg'

      store.updateProfileImage(imageUrl)

      expect(store.profileData.profile_image).toBe(imageUrl)
    })
  })

  describe('clearMessages', () => {
    it('clears error and success messages', () => {
      store.error = 'Some error'
      store.success = 'Some success'

      store.clearMessages()

      expect(store.error).toBe(null)
      expect(store.success).toBe(null)
    })
  })

  describe('isFormValid computed', () => {
    it('returns true when name is not empty', () => {
      store.profileData.name = 'test user'
      expect(store.isFormValid).toBe(true)
    })

    it('returns false when name is empty', () => {
      store.profileData.name = ''
      expect(store.isFormValid).toBe(false)
    })

    it('returns false when name is only whitespace', () => {
      store.profileData.name = '   '
      expect(store.isFormValid).toBe(false)
    })
  })
})
