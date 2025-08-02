import { FullConfig, chromium } from '@playwright/test';

async function globalSetup(config: FullConfig) {
  console.log('🚀 Starting global setup...');
  
  // Launch browser for pre-test setup
  const browser = await chromium.launch();
  const page = await browser.newPage();
  
  try {
    // Setup test environment
    console.log('📝 Setting up test environment...');
    
    // You can add any global setup here:
    // - Create test data
    // - Setup test database
    // - Initialize test services
    // - Authenticate test users
    
    // Example: Check if dev server is ready
    const baseURL = config.use?.baseURL || 'http://localhost:5173';
    console.log(`🌐 Checking if dev server is ready at ${baseURL}...`);
    
    try {
      await page.goto(baseURL, { waitUntil: 'networkidle' });
      console.log('✅ Dev server is ready!');
    } catch (error) {
      console.error('❌ Dev server is not ready:', error);
      throw error;
    }
    
    // Example: Setup mock API endpoints for consistent testing
    console.log('🔧 Setting up mock data...');
    
    // Store any global state if needed
    process.env.GLOBAL_SETUP_COMPLETE = 'true';
    
    console.log('✅ Global setup completed successfully!');
    
  } catch (error) {
    console.error('❌ Global setup failed:', error);
    throw error;
  } finally {
    await browser.close();
  }
}

export default globalSetup;