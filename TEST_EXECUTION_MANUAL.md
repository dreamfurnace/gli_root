# GLI Test Execution Manual

## Overview

This manual provides comprehensive instructions for executing tests across the GLI platform, including environment setup, test execution procedures, troubleshooting, and best practices.

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Environment Setup](#environment-setup)
3. [Test Types and Execution](#test-types-and-execution)
4. [Test Commands Reference](#test-commands-reference)
5. [Configuration Management](#configuration-management)
6. [Test Data and Fixtures](#test-data-and-fixtures)
7. [Continuous Integration](#continuous-integration)
8. [Troubleshooting](#troubleshooting)
9. [Best Practices](#best-practices)
10. [Writing New Tests](#writing-new-tests)

## Prerequisites

### Required Software
- Node.js (v18 or higher)
- npm or yarn package manager
- Docker (for backend services)
- Git

### Browser Requirements
- Chrome/Chromium (latest)
- Firefox (latest)
- Safari (for macOS)

### System Requirements
- Minimum 8GB RAM
- 2GB free disk space for test artifacts
- Network access for API testing

## Environment Setup

### 1. Clone and Install Dependencies

```bash
# Clone the repository
git clone <repository-url>
cd gli_root

# Install frontend dependencies
cd gli_user-frontend
npm install

cd ../gli_admin-frontend
npm install

# Install test dependencies
cd ../tests
npm install
```

### 2. Environment Variables

Create a `.env.test` file in the project root:

```bash
# API Configuration
API_BASE_URL=http://localhost:8000
ADMIN_API_BASE_URL=http://localhost:8001

# Database Configuration
DATABASE_URL=postgresql://test_user:test_pass@localhost:5432/gli_test

# Web3 Configuration
SOLANA_RPC_URL=https://api.devnet.solana.com
PHANTOM_WALLET_ADAPTER_NETWORK=devnet

# Test Configuration
E2E_BASE_URL=http://localhost:5173
ADMIN_E2E_BASE_URL=http://localhost:5174
TEST_TIMEOUT=30000
BROWSER_HEADLESS=true

# Test Data
TEST_USER_EMAIL=test@gli.com
TEST_USER_PASSWORD=TestPassword123
TEST_ADMIN_EMAIL=admin@gli.com
TEST_ADMIN_PASSWORD=AdminPassword123
```

### 3. Database Setup

```bash
# Start test database
cd gli_database
docker-compose -f docker-compose.test.yml up -d

# Run migrations
cd ../gli_api-server
python manage.py migrate --settings=config.settings.test
```

### 4. Start Services

```bash
# Start all services for testing
./start-all-services.sh --test-mode

# Or start individual services
./start-api-server.sh --test-mode
./start-user-frontend.sh --test-mode
./start-admin-frontend.sh --test-mode
```

## Test Types and Execution

### Unit Tests

**Purpose**: Test individual components, functions, and modules in isolation.

**Technology**: Vitest with Vue Test Utils

**Location**: `tests/unit/`

```bash
# Run all unit tests
npm run test:unit

# Run specific component tests
npm run test:unit -- components/Button.test.ts

# Run with coverage
npm run test:unit:coverage

# Watch mode
npm run test:unit:watch
```

**Example Unit Test Structure**:
```typescript
import { describe, it, expect, beforeEach } from 'vitest'
import { mount } from '@vue/test-utils'
import ComponentName from '@/components/ComponentName.vue'

describe('ComponentName', () => {
  it('should render correctly', () => {
    const wrapper = mount(ComponentName, {
      props: { title: 'Test Title' }
    })
    expect(wrapper.text()).toContain('Test Title')
  })
})
```

### Integration Tests

**Purpose**: Test interactions between components, services, and APIs.

**Technology**: Vitest with mocked services

**Location**: `tests/integration/`

```bash
# Run all integration tests
npm run test:integration

# Run API integration tests
npm run test:integration -- api-frontend

# Run frontend-backend integration
npm run test:integration -- frontend-backend
```

**Example Integration Test**:
```typescript
import { describe, it, expect, beforeEach, vi } from 'vitest'
import { createApp } from 'vue'
import { createPinia } from 'pinia'
import { useAuthStore } from '@/stores/auth'

describe('Authentication Integration', () => {
  let app, pinia

  beforeEach(() => {
    app = createApp({})
    pinia = createPinia()
    app.use(pinia)
  })

  it('should authenticate user and update store', async () => {
    const authStore = useAuthStore()
    await authStore.login('test@gli.com', 'password')
    expect(authStore.isAuthenticated).toBe(true)
  })
})
```

### End-to-End Tests

**Purpose**: Test complete user workflows in real browsers.

**Technology**: Playwright

**Location**: `tests/e2e/`

```bash
# Run all E2E tests
npm run test:e2e

# Run specific test suite
npm run test:e2e -- user-flows/

# Run in headed mode (visible browser)
npm run test:e2e:headed

# Run with UI mode
npm run test:e2e:ui

# Generate test report
npm run test:e2e:report

# Debug mode
npm run test:e2e:debug
```

**Example E2E Test**:
```typescript
import { test, expect } from '@playwright/test'

test('user registration and login flow', async ({ page }) => {
  // Navigate to registration
  await page.goto('/')
  await page.click('text=Sign Up')
  
  // Fill registration form
  await page.fill('input[type="email"]', 'newuser@gli.com')
  await page.fill('input[name="name"]', 'New User')
  await page.fill('input[type="password"]', 'Password123')
  await page.fill('input[name="confirmPassword"]', 'Password123')
  
  // Submit registration
  await page.click('button[type="submit"]')
  
  // Verify redirect to login
  await expect(page).toHaveURL(/.*login/)
  
  // Login with new credentials
  await page.fill('input[type="email"]', 'newuser@gli.com')
  await page.fill('input[type="password"]', 'Password123')
  await page.click('button[type="submit"]')
  
  // Verify successful login
  await expect(page).toHaveURL(/.*dashboard/)
  await expect(page.locator('text=New User')).toBeVisible()
})
```

## Test Commands Reference

### Core Commands

```bash
# Run all tests
npm run test:all

# Run tests by type
npm run test:unit
npm run test:integration  
npm run test:e2e

# Run with coverage
npm run test:coverage

# Clean test artifacts
npm run test:clean
```

### Frontend-Specific Commands

```bash
# User frontend tests
cd gli_user-frontend
npm run test:unit          # Component tests
npm run test:e2e          # User flow E2E tests
npm run test:storybook    # Storybook component tests

# Admin frontend tests  
cd gli_admin-frontend
npm run test:unit          # Admin component tests
npm run test:e2e          # Admin flow E2E tests
```

### Backend Tests

```bash
# API server tests
cd gli_api-server
python manage.py test                    # Django unit tests
python manage.py test --keepdb          # Reuse test database
python manage.py test --parallel        # Parallel execution
```

### Docker-based Testing

```bash
# Run tests in containers
docker-compose -f docker-compose.test.yml up --build
docker-compose -f docker-compose.test.yml run test-runner

# Clean up test containers
docker-compose -f docker-compose.test.yml down -v
```

## Configuration Management

### Test Configuration Files

- `tests/config/vitest.config.ts` - Unit/integration test configuration
- `tests/config/playwright.config.ts` - E2E test configuration
- `tests/config/jest.config.js` - Legacy Jest configuration (if needed)

### Environment-Specific Configurations

```bash
# Development environment
NODE_ENV=development npm run test

# Staging environment  
NODE_ENV=staging npm run test:e2e

# Production-like testing
NODE_ENV=production npm run test:e2e:prod
```

### Browser Configuration

Playwright supports multiple browsers and devices:

```bash
# Run on specific browser
npm run test:e2e -- --project=chromium
npm run test:e2e -- --project=firefox
npm run test:e2e -- --project=webkit

# Run on mobile devices
npm run test:e2e -- --project="Mobile Chrome"
npm run test:e2e -- --project="Mobile Safari"
```

## Test Data and Fixtures

### Test Fixtures Location
- `tests/utils/fixtures/` - Static test data files
- `tests/utils/mocks/` - Mock objects and responses
- `tests/utils/helpers/` - Test helper functions

### Using Test Data

```typescript
import { testUsers } from '@tests/utils/fixtures/users.json'
import { mockApiResponse } from '@tests/utils/mocks/api.ts'

test('user profile update', async ({ page }) => {
  const testUser = testUsers.validUser
  await mockApiResponse('/api/profile', testUser)
  // ... test implementation
})
```

### Dynamic Test Data Generation

```typescript
import { faker } from '@faker-js/faker'

const generateTestUser = () => ({
  email: faker.internet.email(),
  name: faker.person.fullName(),
  phone: faker.phone.number()
})
```

## Continuous Integration

### GitHub Actions Configuration

`.github/workflows/test.yml`:

```yaml
name: Test Suite

on: [push, pull_request]

jobs:
  unit-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '18'
      - run: npm ci
      - run: npm run test:unit

  integration-tests:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:13
        env:
          POSTGRES_PASSWORD: postgres
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '18'
      - run: npm ci
      - run: npm run test:integration

  e2e-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with:
          node-version: '18'
      - run: npm ci
      - run: npx playwright install
      - run: npm run test:e2e
      - uses: actions/upload-artifact@v3
        if: failure()
        with:
          name: playwright-report
          path: tests/reports/
```

### Test Result Reporting

```bash
# Generate comprehensive test report
npm run test:report

# Upload coverage to Codecov
bash <(curl -s https://codecov.io/bash)

# Generate performance benchmarks
npm run test:performance
```

## Troubleshooting

### Common Issues and Solutions

#### 1. Test Environment Setup

**Issue**: Tests fail with "Cannot connect to database"
```bash
# Solution: Ensure test database is running
docker-compose -f docker-compose.test.yml up -d postgres
```

**Issue**: Frontend tests fail with "Port already in use"
```bash
# Solution: Kill existing processes
npx kill-port 5173 5174
```

#### 2. Browser Issues

**Issue**: Playwright tests timeout
```bash
# Solution: Increase timeout or run in headed mode
npm run test:e2e:headed
```

**Issue**: Browser download fails
```bash
# Solution: Reinstall Playwright browsers
npx playwright install
```

#### 3. Test Data Issues

**Issue**: Test data conflicts between tests
```bash
# Solution: Use isolated test databases
npm run test:db:reset
```

**Issue**: Mock data out of sync
```bash
# Solution: Update fixtures
npm run test:fixtures:update
```

#### 4. Network and API Issues

**Issue**: API calls fail in tests
```bash
# Solution: Check service status
./start-all-services.sh --test-mode --verbose
```

**Issue**: CORS errors in E2E tests
```bash
# Solution: Configure test CORS settings
export TEST_CORS_ORIGINS="http://localhost:5173,http://localhost:5174"
```

### Debug Mode

```bash
# Enable debug logging
DEBUG=true npm run test

# Run single test with debug
npm run test:e2e:debug -- --grep "user login"

# Use browser dev tools
npm run test:e2e:headed -- --debug
```

### Performance Issues

```bash
# Profile test execution
npm run test:profile

# Run tests in parallel
npm run test:parallel

# Optimize test database
npm run test:db:optimize
```

## Best Practices

### 1. Test Organization

- **Arrange-Act-Assert**: Structure tests clearly
- **Descriptive names**: Use clear, descriptive test names
- **Single responsibility**: One assertion per test when possible
- **Test isolation**: Ensure tests don't depend on each other

### 2. Test Data Management

- **Use factories**: Generate test data dynamically
- **Clean up**: Remove test data after tests
- **Realistic data**: Use data that matches production patterns
- **Version fixtures**: Keep test fixtures up to date

### 3. Mocking and Stubbing

- **Mock external services**: Don't rely on external APIs
- **Stub network calls**: Use predictable responses
- **Mock time**: Use fixed dates for consistent results
- **Selective mocking**: Only mock what's necessary

### 4. Error Handling

- **Test error cases**: Include negative test scenarios
- **Verify error messages**: Check user-facing error text
- **Test recovery**: Verify error recovery mechanisms
- **Log failures**: Capture detailed failure information

### 5. Performance

- **Parallel execution**: Run tests concurrently when possible
- **Selective running**: Only run relevant tests in development
- **Cache dependencies**: Reuse installed packages
- **Optimize setup**: Minimize test setup time

## Writing New Tests

### 1. Choosing Test Type

**Unit Test** when:
- Testing individual functions/components
- Logic can be isolated
- Fast feedback is needed

**Integration Test** when:
- Testing component interactions
- API integrations need verification
- Store/service interactions are complex

**E2E Test** when:
- Testing user workflows
- Cross-browser compatibility is important
- Real user scenarios need validation

### 2. Test Structure Template

```typescript
// Unit Test Template
describe('ComponentName', () => {
  beforeEach(() => {
    // Setup
  })

  afterEach(() => {
    // Cleanup
  })

  describe('when condition X', () => {
    it('should do Y', () => {
      // Arrange
      const input = 'test'
      
      // Act
      const result = functionUnderTest(input)
      
      // Assert
      expect(result).toBe('expected')
    })
  })
})
```

### 3. E2E Test Template

```typescript
// E2E Test Template
test.describe('Feature Name', () => {
  test.beforeEach(async ({ page }) => {
    // Setup common state
    await page.goto('/login')
    await login(page, 'test@gli.com', 'password')
  })

  test('should complete user workflow', async ({ page }) => {
    // Test implementation
    await page.click('text=Start Workflow')
    await expect(page.locator('.success')).toBeVisible()
  })
})
```

### 4. Adding New Test Files

1. Create test file in appropriate directory
2. Follow naming conventions (`*.test.ts`, `*.spec.ts`)
3. Add to relevant test suite configuration
4. Update documentation if needed

### 5. Test Coverage Guidelines

- Aim for 80%+ coverage on critical paths
- 100% coverage on utility functions
- Focus on edge cases and error conditions
- Don't chase coverage metrics at expense of quality

## Conclusion

This manual provides comprehensive guidance for test execution across the GLI platform. For additional support:

- Check the project README files
- Review existing test examples
- Consult team documentation
- Ask questions in team channels

Remember to keep tests maintainable, reliable, and focused on user value.