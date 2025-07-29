#!/usr/bin/env node

/**
 * GLI Platform - Test Environment Setup
 * 테스트 실행을 위한 환경 구성 스크립트
 */

const { spawn } = require('child_process');
const fs = require('fs');
const path = require('path');

class TestEnvironmentSetup {
  constructor() {
    this.projectRoot = path.resolve(__dirname, '../../..');
    this.verbose = process.argv.includes('--verbose') || process.argv.includes('-v');
  }

  log(message, level = 'info') {
    const timestamp = new Date().toISOString();
    const prefix = level === 'error' ? '❌' : level === 'success' ? '✅' : '🔧';
    console.log(`${prefix} [${timestamp}] ${message}`);
  }

  async runCommand(command, args, options = {}) {
    return new Promise((resolve, reject) => {
      this.log(`Running: ${command} ${args.join(' ')}`);
      
      const child = spawn(command, args, {
        stdio: this.verbose ? 'inherit' : 'pipe',
        cwd: options.cwd || process.cwd(),
        ...options
      });

      let stdout = '';
      let stderr = '';

      if (!this.verbose) {
        child.stdout?.on('data', (data) => stdout += data);
        child.stderr?.on('data', (data) => stderr += data);
      }

      child.on('close', (code) => {
        if (code === 0) {
          resolve({ stdout, stderr, code });
        } else {
          reject({ stdout, stderr, code, command: `${command} ${args.join(' ')}` });
        }
      });
    });
  }

  async checkSystemRequirements() {
    this.log('Checking system requirements...');

    // Node.js 버전 확인
    const nodeVersion = process.version;
    const majorVersion = parseInt(nodeVersion.slice(1).split('.')[0]);
    
    if (majorVersion < 18) {
      throw new Error(`Node.js 18+ required, current: ${nodeVersion}`);
    }
    this.log(`Node.js version: ${nodeVersion} ✓`);

    // Python 확인 (Django 백엔드용)
    try {
      const result = await this.runCommand('python3', ['--version']);
      this.log(`Python version: ${result.stdout.trim()} ✓`);
    } catch (error) {
      this.log('Python3 not found, some backend tests may fail', 'error');
    }

    // Docker 확인 (데이터베이스용)
    try {
      await this.runCommand('docker', ['--version']);
      this.log('Docker available ✓');
    } catch (error) {
      this.log('Docker not found, database tests may fail', 'error');
    }

    this.log('System requirements check completed', 'success');
  }

  async setupEnvironmentFiles() {
    this.log('Setting up environment files...');

    const envFiles = [
      {
        source: path.join(__dirname, '../../../.env.test.example'),
        target: path.join(__dirname, '../../.env.test'),
        required: false
      },
      {
        source: path.join(this.projectRoot, 'gli_api-server/.env.development'),
        target: path.join(this.projectRoot, 'gli_api-server/.env.test'),
        required: true
      },
      {
        source: path.join(this.projectRoot, 'gli_user-frontend/.env.development'),
        target: path.join(this.projectRoot, 'gli_user-frontend/.env.test'),
        required: false
      },
      {
        source: path.join(this.projectRoot, 'gli_admin-frontend/.env.local.example'),
        target: path.join(this.projectRoot, 'gli_admin-frontend/.env.test'),
        required: false
      }
    ];

    for (const { source, target, required } of envFiles) {
      if (fs.existsSync(target)) {
        this.log(`Environment file already exists: ${path.basename(target)}`);
        continue;
      }

      if (fs.existsSync(source)) {
        fs.copyFileSync(source, target);
        this.log(`Created: ${path.basename(target)}`);
      } else if (required) {
        throw new Error(`Required environment file not found: ${source}`);
      } else {
        this.log(`Optional environment file not found: ${source}`, 'error');
      }
    }

    // 테스트용 환경 변수 설정
    const testEnvContent = `
# GLI Platform Test Environment
NODE_ENV=test
DJANGO_ENV=test

# Test Database
TEST_DATABASE_URL=sqlite:///test.db

# Test API URLs  
VITE_API_BASE_URL=http://localhost:8000
ADMIN_BASE_URL=http://localhost:5174

# Test Solana Settings  
SOLANA_NETWORK=devnet
VITE_SOLANA_NETWORK=devnet
VITE_SOLANA_RPC_URL=https://api.devnet.solana.com

# Test JWT Settings
JWT_ACCESS_TOKEN_LIFETIME=5
JWT_REFRESH_TOKEN_LIFETIME=60

# Test Feature Flags
VITE_ENABLE_DEBUG_MODE=true
VITE_ENABLE_CONSOLE_LOGS=true
VITE_ENABLE_ERROR_REPORTING=false

# Test Ports
USER_FRONTEND_PORT=5173
ADMIN_FRONTEND_PORT=5174
API_SERVER_PORT=8000
`;

    const testEnvPath = path.join(__dirname, '../../.env.test');
    if (!fs.existsSync(testEnvPath)) {
      fs.writeFileSync(testEnvPath, testEnvContent);
      this.log('Created master test environment file');
    }

    this.log('Environment files setup completed', 'success');
  }

  async installDependencies() {
    this.log('Installing dependencies...');

    const projects = [
      { name: 'Test Suite', path: path.join(__dirname, '../..') },
      { name: 'User Frontend', path: path.join(this.projectRoot, 'gli_user-frontend') },
      { name: 'Admin Frontend', path: path.join(this.projectRoot, 'gli_admin-frontend') }
    ];

    for (const project of projects) {
      if (fs.existsSync(path.join(project.path, 'package.json'))) {
        if (!fs.existsSync(path.join(project.path, 'node_modules'))) {
          this.log(`Installing dependencies for ${project.name}...`);
          await this.runCommand('npm', ['install'], { cwd: project.path });
          this.log(`Dependencies installed for ${project.name} ✓`);
        } else {
          this.log(`Dependencies already installed for ${project.name}`);
        }
      }
    }

    // Python 의존성 (백엔드)
    const backendPath = path.join(this.projectRoot, 'gli_api-server');
    if (fs.existsSync(path.join(backendPath, 'pyproject.toml'))) {
      try {
        this.log('Installing Python dependencies...');
        await this.runCommand('uv', ['sync'], { cwd: backendPath });
        this.log('Python dependencies installed ✓');
      } catch (error) {
        this.log('Failed to install Python dependencies, some tests may fail', 'error');
      }
    }

    this.log('Dependencies installation completed', 'success');
  }

  async setupTestDatabase() {
    this.log('Setting up test database...');

    try {
      // Docker 컨테이너 시작
      const dbPath = path.join(this.projectRoot, 'gli_database');
      if (fs.existsSync(path.join(dbPath, 'docker-compose.yml'))) {
        await this.runCommand('docker-compose', ['up', '-d'], { cwd: dbPath });
        this.log('Test database container started ✓');
        
        // 데이터베이스 준비 대기
        await this.delay(5000);
      }

      // Django 마이그레이션
      const backendPath = path.join(this.projectRoot, 'gli_api-server');
      if (fs.existsSync(path.join(backendPath, 'manage.py'))) {
        await this.runCommand('uv', ['run', 'python', 'manage.py', 'migrate'], { cwd: backendPath });
        this.log('Database migrations applied ✓');
      }

    } catch (error) {
      this.log(`Database setup failed: ${error.message}`, 'error');
      this.log('Some database-related tests may fail', 'error');
    }

    this.log('Test database setup completed', 'success');
  }

  async setupPlaywright() {
    this.log('Setting up Playwright browsers...');

    try {
      await this.runCommand('npx', ['playwright', 'install'], { cwd: path.join(__dirname, '../..') });
      this.log('Playwright browsers installed ✓');
    } catch (error) {
      this.log(`Playwright setup failed: ${error.message}`, 'error');
      this.log('E2E tests may fail', 'error');
    }

    this.log('Playwright setup completed', 'success');
  }

  async setupTestData() {
    this.log('Setting up test data...');

    // 테스트 Fixture 데이터 생성
    const fixturesPath = path.join(__dirname, '../../fixtures');
    
    // 사용자 테스트 데이터
    const testUsers = [
      {
        id: 'test-user-1',
        wallet_address: 'DjVE6JNiYqPL2QXyCUEwD9uKhAYpVy2xEf5jKNiVSB7U',
        username: 'test_user_1',
        email: 'user1@gli-test.com',
        membership_level: 'premium'
      },
      {
        id: 'test-admin-1',
        wallet_address: 'HN7cABqLq46Es1jh92dQQisAq662SmxELLLsHHe4YWrH',  
        username: 'test_admin_1',
        email: 'admin1@gli-test.com',
        role: 'admin'
      }
    ];

    fs.writeFileSync(
      path.join(fixturesPath, 'users/test-users.json'),
      JSON.stringify(testUsers, null, 2)
    );

    // 계약서 테스트 데이터
    const testContracts = [
      {
        id: 'contract-1',
        type: 'real_estate_sale',
        title: '테스트 부동산 매매계약서',
        status: 'draft',
        created_by: 'test-user-1'
      }
    ];

    fs.writeFileSync(
      path.join(fixturesPath, 'contracts/test-contracts.json'),
      JSON.stringify(testContracts, null, 2)
    );

    // Mock 트랜잭션 데이터
    const testTransactions = [
      {
        id: 'tx-1',
        user_id: 'test-user-1',
        transaction_hash: '5VfYKa7nUGfGqiAELvG2fS4aVnm2MxSoWKYnq1cNjMhP3pMx2aVnKqUNnNcJfN',
        type: 'airdrop',
        amount: '2.0',
        status: 'confirmed'
      }
    ];

    fs.writeFileSync(
      path.join(fixturesPath, 'transactions/test-transactions.json'),
      JSON.stringify(testTransactions, null, 2)
    );

    this.log('Test data setup completed', 'success');
  }

  async createTestDirectories() {
    this.log('Creating test directories...');

    const directories = [
      'reports',
      'coverage',
      'test-results',
      'fixtures/users',
      'fixtures/contracts', 
      'fixtures/transactions',
      'fixtures/mock-data'
    ];

    const testsRoot = path.join(__dirname, '../..');
    
    for (const dir of directories) {
      const fullPath = path.join(testsRoot, dir);
      if (!fs.existsSync(fullPath)) {
        fs.mkdirSync(fullPath, { recursive: true });
        this.log(`Created directory: ${dir}`);
      }
    }

    this.log('Test directories created', 'success');
  }

  delay(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  async setup() {
    try {
      this.log('🚀 Starting GLI Platform Test Environment Setup');

      await this.checkSystemRequirements();
      await this.createTestDirectories();
      await this.setupEnvironmentFiles();
      await this.installDependencies();
      await this.setupTestDatabase();
      await this.setupPlaywright();
      await this.setupTestData();

      this.log('🎉 Test environment setup completed successfully!', 'success');
      this.log('You can now run tests with: npm run test:all');

    } catch (error) {
      this.log(`Setup failed: ${error.message}`, 'error');
      if (this.verbose && error.stderr) {
        console.error(error.stderr);
      }
      process.exit(1);
    }
  }
}

// 실행
if (require.main === module) {
  const setup = new TestEnvironmentSetup();
  setup.setup();
}

module.exports = TestEnvironmentSetup;