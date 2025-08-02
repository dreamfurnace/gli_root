/// <reference types="vitest/config" />
import { defineConfig } from 'vitest/config'
import { resolve } from 'path'

export default defineConfig({
  test: {
    environment: 'jsdom',
    globals: true,
    setupFiles: ['../utils/setup/vitest.setup.ts'],
    include: [
      '../unit/**/*.test.ts',
      '../integration/**/*.test.ts',
      '../integration/**/*.test.js'
    ],
    exclude: [
      '../e2e/**/*',
      '../utils/**/*',
      '../config/**/*'
    ],
    coverage: {
      provider: 'v8',
      reporter: ['text', 'json', 'html'],
      include: [
        'gli_user-frontend/src/**/*',
        'gli_admin-frontend/src/**/*'
      ],
      exclude: [
        'node_modules/**',
        'tests/**',
        '**/*.d.ts',
        '**/*.config.*',
        '**/dist/**'
      ]
    }
  },
  resolve: {
    alias: {
      '@': resolve(__dirname, '../../gli_user-frontend/src'),
      '@admin': resolve(__dirname, '../../gli_admin-frontend/src'),
      '@tests': resolve(__dirname, '../')
    }
  }
})