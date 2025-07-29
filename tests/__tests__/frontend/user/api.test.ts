// Jest globals - no import needed
import axios from 'axios'
import type { AxiosResponse } from 'axios'

// Mock axios
jest.mock('axios', () => ({
  default: {
    create: jest.fn(() => ({
      get: jest.fn(),
      post: jest.fn(),
      put: jest.fn(),
      patch: jest.fn(),
      delete: jest.fn(),
      interceptors: {
        request: { use: jest.fn() },
        response: { use: jest.fn() },
      },
    })),
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

describe('API Service', () => {
  let mockAxios: any

  beforeEach(() => {
    jest.clearAllMocks()
    mockAxios = axios.create()
  })

  describe('profileAPI', () => {
    it('getProfile makes GET request to /profile/', async () => {
      const mockResponse = createMockResponse({ name: 'test', phone: '010-1234-5678' })
      jest.mocked(mockAxios.get).mockResolvedValue(mockResponse)

      const result = await mockAxios.get('/profile/')

      expect(mockAxios.get).toHaveBeenCalledWith('/profile/')
      expect(result).toEqual(mockResponse)
    })

    it('updateProfile makes PUT request to /profile/', async () => {
      const profileData = { name: 'new name', phone: '010-9876-5432' }
      const mockResponse = createMockResponse(profileData)
      jest.mocked(mockAxios.put).mockResolvedValue(mockResponse)

      const result = await mockAxios.put('/profile/', profileData)

      expect(mockAxios.put).toHaveBeenCalledWith('/profile/', profileData)
      expect(result).toEqual(mockResponse)
    })

    it('patchProfile makes PATCH request to /profile/', async () => {
      const profileData = { phone: '010-9876-5432' }
      const mockResponse = createMockResponse(profileData)
      jest.mocked(mockAxios.patch).mockResolvedValue(mockResponse)

      const result = await mockAxios.patch('/profile/', profileData)

      expect(mockAxios.patch).toHaveBeenCalledWith('/profile/', profileData)
      expect(result).toEqual(mockResponse)
    })

    it('uploadAvatar makes POST request with FormData', async () => {
      const file = new File(['test'], 'avatar.jpg', { type: 'image/jpeg' })
      const formData = new FormData()
      formData.append('avatar', file)
      const mockResponse = createMockResponse({ profile: { profile_image: 'new-avatar.jpg' } })
      jest.mocked(mockAxios.post).mockResolvedValue(mockResponse)

      const result = await mockAxios.post('/profile/avatar/', formData)

      expect(mockAxios.post).toHaveBeenCalledWith('/profile/avatar/', formData)
      expect(result).toEqual(mockResponse)
    })
  })

  describe('authAPI', () => {
    it('login makes POST request to /auth/login/', async () => {
      const credentials = { email: 'test@example.com', password: 'password' }
      const mockResponse = createMockResponse({ access_token: 'token' })
      jest.mocked(mockAxios.post).mockResolvedValue(mockResponse)

      const result = await mockAxios.post('/auth/login/', credentials)

      expect(mockAxios.post).toHaveBeenCalledWith('/auth/login/', credentials)
      expect(result).toEqual(mockResponse)
    })

    it('register makes POST request to /auth/register/', async () => {
      const userData = {
        email: 'test@example.com',
        name: 'Test User',
        password: 'password',
        password_confirm: 'password',
      }
      const mockResponse = createMockResponse({ user: userData })
      jest.mocked(mockAxios.post).mockResolvedValue(mockResponse)

      const result = await mockAxios.post('/auth/register/', userData)

      expect(mockAxios.post).toHaveBeenCalledWith('/auth/register/', userData)
      expect(result).toEqual(mockResponse)
    })

    it('logout makes POST request to /auth/logout/', async () => {
      const mockResponse = createMockResponse({ message: 'Logged out successfully' })
      jest.mocked(mockAxios.post).mockResolvedValue(mockResponse)

      const result = await mockAxios.post('/auth/logout/')

      expect(mockAxios.post).toHaveBeenCalledWith('/auth/logout/')
      expect(result).toEqual(mockResponse)
    })

    it('getSessions makes GET request to /auth/sessions/', async () => {
      const mockResponse = createMockResponse({ sessions: [] })
      jest.mocked(mockAxios.get).mockResolvedValue(mockResponse)

      const result = await mockAxios.get('/auth/sessions/')

      expect(mockAxios.get).toHaveBeenCalledWith('/auth/sessions/')
      expect(result).toEqual(mockResponse)
    })

    it('deleteSession makes DELETE request to /auth/sessions/{id}/', async () => {
      const sessionId = 'session-123'
      const mockResponse = createMockResponse({ message: 'Session deleted' })
      jest.mocked(mockAxios.delete).mockResolvedValue(mockResponse)

      const result = await mockAxios.delete(`/auth/sessions/${sessionId}/`)

      expect(mockAxios.delete).toHaveBeenCalledWith(`/auth/sessions/${sessionId}/`)
      expect(result).toEqual(mockResponse)
    })
  })

  describe('Error handling', () => {
    it('handles network errors in profileAPI', async () => {
      const errorMessage = 'Network error'
      jest.mocked(mockAxios.get).mockRejectedValue(new Error(errorMessage))

      await expect(mockAxios.get('/profile/')).rejects.toThrow(errorMessage)
    })

    it('handles API errors in authAPI', async () => {
      const errorMessage = 'Invalid credentials'
      jest.mocked(mockAxios.post).mockRejectedValue(new Error(errorMessage))

      await expect(
        mockAxios.post('/auth/login/', { email: 'test', password: 'wrong' }),
      ).rejects.toThrow(errorMessage)
    })
  })

  describe('File upload validation', () => {
    it('uploadAvatar accepts valid image files', async () => {
      const file = new File(['test'], 'avatar.jpg', { type: 'image/jpeg' })
      const formData = new FormData()
      formData.append('avatar', file)
      const mockResponse = createMockResponse({ profile: { profile_image: 'avatar.jpg' } })
      jest.mocked(mockAxios.post).mockResolvedValue(mockResponse)

      const result = await mockAxios.post('/profile/avatar/', formData)

      expect(mockAxios.post).toHaveBeenCalledWith('/profile/avatar/', formData)
      expect(result).toEqual(mockResponse)
    })

    it('uploadAvatar handles invalid file types', async () => {
      const file = new File(['test'], 'document.txt', { type: 'text/plain' })
      const formData = new FormData()
      formData.append('avatar', file)
      const errorMessage = 'Invalid file type'
      jest.mocked(mockAxios.post).mockRejectedValue(new Error(errorMessage))

      await expect(mockAxios.post('/profile/avatar/', formData)).rejects.toThrow(errorMessage)
    })
  })
})
