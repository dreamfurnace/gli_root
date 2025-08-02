import { FullConfig } from '@playwright/test';

async function globalTeardown(config: FullConfig) {
  console.log('🧹 Starting global teardown...');
  
  try {
    // Cleanup test environment
    console.log('🗑️ Cleaning up test environment...');
    
    // You can add any global cleanup here:
    // - Clean up test data
    // - Close test database connections
    // - Stop test services
    // - Clean up temporary files
    
    // Example: Clean up any global state
    delete process.env.GLOBAL_SETUP_COMPLETE;
    
    // Example: Clean up test artifacts if needed
    console.log('📁 Cleaning up test artifacts...');
    
    // Clean up any temporary test files
    // await fs.rmdir('./temp-test-files', { recursive: true }).catch(() => {});
    
    console.log('✅ Global teardown completed successfully!');
    
  } catch (error) {
    console.error('❌ Global teardown failed:', error);
    // Don't throw here as we don't want to fail the entire test run
    // just because cleanup failed
  }
}

export default globalTeardown;