#!/usr/bin/env node

/**
 * GLI Platform - Master Test Runner
 * 모든 테스트 유형을 순차적으로 실행하는 마스터 스크립트
 */

const { spawn } = require('child_process');
const path = require('path');
const fs = require('fs');

class TestRunner {
  constructor() {
    this.testResults = {};
    this.startTime = Date.now();
    this.verbose = process.argv.includes('--verbose');
    this.failFast = process.argv.includes('--fail-fast');
  }

  log(message, level = 'info') {
    const timestamp = new Date().toISOString();
    const prefix = level === 'error' ? '❌' : level === 'success' ? '✅' : 'ℹ️';
    console.log(`${prefix} [${timestamp}] ${message}`);
  }

  async runCommand(command, args, options = {}) {
    return new Promise((resolve, reject) => {
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
          reject({ stdout, stderr, code });
        }
      });
    });
  }

  async runTestSuite(name, command, args, options = {}) {
    this.log(`Starting ${name}...`);
    const startTime = Date.now();

    try {
      const result = await this.runCommand(command, args, options);
      const duration = Date.now() - startTime;
      
      this.testResults[name] = {
        status: 'passed',
        duration,
        output: result.stdout
      };

      this.log(`${name} completed successfully (${duration}ms)`, 'success');
      return true;
    } catch (error) {
      const duration = Date.now() - startTime;
      
      this.testResults[name] = {
        status: 'failed',
        duration,
        error: error.stderr || error.message,
        code: error.code
      };

      this.log(`${name} failed (${duration}ms)`, 'error');
      if (this.verbose) {
        console.error(error.stderr);
      }

      if (this.failFast) {
        throw new Error(`Test suite ${name} failed, stopping execution`);
      }

      return false;
    }
  }

  async checkPrerequisites() {
    this.log('Checking prerequisites...');

    // Node.js 버전 확인
    const nodeVersion = process.version;
    this.log(`Node.js version: ${nodeVersion}`);

    // 패키지 설치 확인
    if (!fs.existsSync('node_modules')) {
      this.log('Installing dependencies...');
      await this.runCommand('npm', ['install']);
    }

    // 테스트 환경 설정
    if (!fs.existsSync('.env.test')) {
      this.log('Creating test environment file...');
      fs.copyFileSync('.env.test.example', '.env.test');
    }

    this.log('Prerequisites check completed', 'success');
  }

  async runUnitTests() {
    const suites = [
      {
        name: 'Frontend Unit Tests (User)',
        command: 'npm',
        args: ['run', 'test:frontend:user'],
        cwd: process.cwd()
      },
      {
        name: 'Frontend Unit Tests (Admin)', 
        command: 'npm',
        args: ['run', 'test:frontend:admin'],
        cwd: process.cwd()
      },
      {
        name: 'Backend API Tests',
        command: 'npm',
        args: ['run', 'test:backend:api'],
        cwd: process.cwd()
      },
      {
        name: 'Backend Model Tests',
        command: 'npm',
        args: ['run', 'test:backend:models'],
        cwd: process.cwd()
      }
    ];

    let allPassed = true;
    for (const suite of suites) {
      const passed = await this.runTestSuite(suite.name, suite.command, suite.args, { cwd: suite.cwd });
      if (!passed) allPassed = false;
    }

    return allPassed;
  }

  async runIntegrationTests() {
    const suites = [
      {
        name: 'API-Database Integration',
        command: 'npm',
        args: ['run', 'test:integration:api-database']
      },
      {
        name: 'Frontend-Backend Integration',
        command: 'npm', 
        args: ['run', 'test:integration:frontend-backend']
      },
      {
        name: 'Web3 Integration',
        command: 'npm',
        args: ['run', 'test:integration:web3']
      }
    ];

    let allPassed = true;
    for (const suite of suites) {
      const passed = await this.runTestSuite(suite.name, suite.command, suite.args);
      if (!passed) allPassed = false;
    }

    return allPassed;
  }

  async runE2ETests() {
    this.log('Starting services for E2E tests...');
    
    // 서비스 시작 (background)
    const services = [
      { name: 'Database', command: '../gli_database/docker-compose', args: ['up', '-d'] },
      { name: 'API Server', command: 'npm', args: ['run', 'start:api'], cwd: '../gli_api-server' },
      { name: 'User Frontend', command: 'npm', args: ['run', 'dev'], cwd: '../gli_user-frontend' },
      { name: 'Admin Frontend', command: 'npm', args: ['run', 'dev'], cwd: '../gli_admin-frontend' }
    ];

    // 서비스 준비 대기
    await this.delay(10000);

    const suites = [
      {
        name: 'User Flow E2E Tests',
        command: 'npx',
        args: ['playwright', 'test', 'e2e/user-flows/']
      },
      {
        name: 'Admin Flow E2E Tests', 
        command: 'npx',
        args: ['playwright', 'test', 'e2e/admin-flows/']
      },
      {
        name: 'Web3 Integration E2E Tests',
        command: 'npx', 
        args: ['playwright', 'test', 'e2e/web3-integration/']
      },
      {
        name: 'Cross-Platform E2E Tests',
        command: 'npx',
        args: ['playwright', 'test', 'e2e/cross-platform/']
      }
    ];

    let allPassed = true;
    for (const suite of suites) {
      const passed = await this.runTestSuite(suite.name, suite.command, suite.args);
      if (!passed) allPassed = false;
    }

    return allPassed;
  }

  async runSpecialTests() {
    const suites = [
      {
        name: 'Performance Tests',
        command: 'npm',
        args: ['run', 'test:performance']
      },
      {
        name: 'Security Tests',
        command: 'npm',
        args: ['run', 'test:security']
      },
      {
        name: 'Accessibility Tests',
        command: 'npm',
        args: ['run', 'test:accessibility']
      }
    ];

    let allPassed = true;
    for (const suite of suites) {
      const passed = await this.runTestSuite(suite.name, suite.command, suite.args);
      if (!passed) allPassed = false;
    }

    return allPassed;
  }

  delay(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  generateReport() {
    const totalDuration = Date.now() - this.startTime;
    const passedTests = Object.values(this.testResults).filter(r => r.status === 'passed').length;
    const failedTests = Object.values(this.testResults).filter(r => r.status === 'failed').length;
    const totalTests = passedTests + failedTests;

    const report = {
      summary: {
        total: totalTests,
        passed: passedTests,
        failed: failedTests,
        duration: totalDuration,
        timestamp: new Date().toISOString()
      },
      results: this.testResults
    };

    // JSON 리포트 저장
    fs.writeFileSync('reports/test-results.json', JSON.stringify(report, null, 2));

    // 콘솔 요약
    console.log('\n' + '='.repeat(60));
    console.log('GLI PLATFORM TEST SUMMARY');
    console.log('='.repeat(60));
    console.log(`Total Tests: ${totalTests}`);
    console.log(`Passed: ${passedTests} ✅`);
    console.log(`Failed: ${failedTests} ❌`);
    console.log(`Duration: ${(totalDuration / 1000).toFixed(2)}s`);
    console.log('='.repeat(60));

    if (failedTests > 0) {
      console.log('\nFAILED TESTS:');
      Object.entries(this.testResults)
        .filter(([_, result]) => result.status === 'failed')
        .forEach(([name, result]) => {
          console.log(`❌ ${name} (${result.duration}ms)`);
          if (result.error && this.verbose) {
            console.log(`   Error: ${result.error.substring(0, 100)}...`);
          }
        });
    }

    return failedTests === 0;
  }

  async run() {
    try {
      this.log('🚀 Starting GLI Platform Test Suite');
      
      await this.checkPrerequisites();

      const testPhases = [
        { name: 'Unit Tests', fn: () => this.runUnitTests() },
        { name: 'Integration Tests', fn: () => this.runIntegrationTests() },
        { name: 'E2E Tests', fn: () => this.runE2ETests() },
        { name: 'Special Tests', fn: () => this.runSpecialTests() }
      ];

      for (const phase of testPhases) {
        this.log(`\n📋 Running ${phase.name}...`);
        await phase.fn();
      }

      const success = this.generateReport();
      
      if (success) {
        this.log('🎉 All tests completed successfully!', 'success');
        process.exit(0);
      } else {
        this.log('💥 Some tests failed. Check the report for details.', 'error');
        process.exit(1);
      }

    } catch (error) {
      this.log(`Fatal error: ${error.message}`, 'error');
      process.exit(1);
    }
  }
}

// 실행
if (require.main === module) {
  const runner = new TestRunner();
  runner.run();
}

module.exports = TestRunner;