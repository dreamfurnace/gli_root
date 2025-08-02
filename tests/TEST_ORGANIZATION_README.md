# GLI Test Suite Organization

This directory contains all test files organized by test type and functionality.

## Directory Structure

```
tests/
├── unit/                     # Unit tests for individual components/functions
│   ├── components/           # Vue component unit tests
│   ├── services/            # Service layer unit tests
│   ├── stores/              # Store/state management unit tests
│   ├── utils/               # Utility function unit tests
│   └── views/               # View component unit tests
├── integration/             # Integration tests
│   ├── api-frontend/        # Frontend-API integration tests
│   ├── frontend-backend/    # Full frontend-backend integration
│   └── full-stack/          # Complete application integration
├── e2e/                     # End-to-end tests
│   ├── user-flows/          # User workflow E2E tests
│   ├── admin-flows/         # Admin workflow E2E tests
│   ├── accessibility/       # Accessibility E2E tests
│   └── performance/         # Performance E2E tests
├── utils/                   # Test utilities and helpers
│   ├── helpers/             # Test helper functions
│   ├── mocks/               # Mock objects and data
│   ├── fixtures/            # Test data fixtures
│   └── setup/               # Test setup configurations
└── config/                  # Test configuration files
    ├── vitest.config.ts     # Vitest configuration
    ├── playwright.config.ts # Playwright configuration
    └── jest.config.js       # Jest configuration (if needed)
```

## Test Types

### Unit Tests
- Test individual components, functions, or modules in isolation
- Use Vitest for Vue components and utilities
- Mock external dependencies
- Fast execution, focused on single units of code

### Integration Tests
- Test interactions between multiple components/services
- Verify API integrations and data flow
- Test store/component interactions
- Test routing and navigation

### End-to-End Tests
- Test complete user workflows
- Use Playwright for browser automation
- Test across different browsers and devices
- Verify real user scenarios

## Running Tests

```bash
# Run all tests
npm run test

# Run unit tests only
npm run test:unit

# Run integration tests
npm run test:integration

# Run E2E tests
npm run test:e2e

# Run with coverage
npm run test:coverage

# Run specific test file
npm run test path/to/test.spec.ts
```

## Test Naming Conventions

- Unit tests: `ComponentName.test.ts` or `functionName.test.ts`
- Integration tests: `feature.integration.test.ts`
- E2E tests: `workflow-name.spec.ts`

## Writing Tests

### Unit Test Example
```typescript
import { describe, it, expect } from 'vitest'
import { mount } from '@vue/test-utils'
import ComponentName from './ComponentName.vue'

describe('ComponentName', () => {
  it('should render correctly', () => {
    const wrapper = mount(ComponentName)
    expect(wrapper.text()).toContain('Expected text')
  })
})
```

### E2E Test Example
```typescript
import { test, expect } from '@playwright/test'

test('user login flow', async ({ page }) => {
  await page.goto('/')
  await page.click('text=Login')
  await page.fill('input[type="email"]', 'user@example.com')
  await page.fill('input[type="password"]', 'password')
  await page.click('button[type="submit"]')
  await expect(page).toHaveURL('/dashboard')
})
```

## Best Practices

1. **Arrange, Act, Assert**: Structure tests clearly
2. **Descriptive test names**: Use clear, descriptive test names
3. **Mock external dependencies**: Keep unit tests isolated
4. **Test user behavior**: Focus on what users actually do
5. **Maintain test data**: Keep fixtures and mocks up to date
6. **Clean up**: Ensure tests don't affect each other