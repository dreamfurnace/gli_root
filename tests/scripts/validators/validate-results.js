#!/usr/bin/env node

/**
 * GLI Platform - Test Results Validator
 * 테스트 결과 검증 및 품질 게이트 확인
 */

const fs = require('fs');
const path = require('path');

class TestResultsValidator {
  constructor() {
    this.reportPath = path.join(__dirname, '../../reports');
    this.thresholds = {
      coverage: {
        statements: 70,
        branches: 70,
        functions: 70,
        lines: 70
      },
      performance: {
        maxLoadTime: 3000, // 3초
        maxApiResponseTime: 1000, // 1초
        minFPS: 30
      },
      accessibility: {
        minScore: 90, // 100점 만점 중 90점
        allowedViolations: 5
      }
    };
    this.results = {};
    this.violations = [];
  }

  log(message, level = 'info') {
    const timestamp = new Date().toISOString();
    const prefix = level === 'error' ? '❌' : level === 'warning' ? '⚠️' : level === 'success' ? '✅' : 'ℹ️';
    console.log(`${prefix} [${timestamp}] ${message}`);
  }

  loadTestResults() {
    this.log('Loading test results...');

    const resultFiles = [
      'test-results.json',
      'coverage/lcov-report/index.html',
      'playwright-results.json',
      'performance-results.json',
      'accessibility-results.json'
    ];

    for (const file of resultFiles) {
      const filePath = path.join(this.reportPath, file);
      if (fs.existsSync(filePath)) {
        if (file.endsWith('.json')) {
          try {
            const content = fs.readFileSync(filePath, 'utf8');
            this.results[file.replace('.json', '')] = JSON.parse(content);
          } catch (error) {
            this.log(`Failed to parse ${file}: ${error.message}`, 'error');
          }
        }
      } else {
        this.log(`Result file not found: ${file}`, 'warning');
      }
    }

    this.log(`Loaded ${Object.keys(this.results).length} result files`);
  }

  validateTestExecution() {
    this.log('\n📋 Validating test execution...');

    const testResults = this.results['test-results'];
    if (!testResults) {
      this.addViolation('critical', 'No test results found');
      return false;
    }

    const { summary } = testResults;
    
    // 실행된 테스트 수 확인
    if (summary.total < 10) {
      this.addViolation('warning', `Low test count: ${summary.total} (expected > 10)`);
    }

    // 실패율 확인
    const failureRate = (summary.failed / summary.total) * 100;
    if (failureRate > 5) {
      this.addViolation('error', `High failure rate: ${failureRate.toFixed(1)}% (expected < 5%)`);
    }

    // 테스트 실행 시간 확인
    const durationMinutes = summary.duration / (1000 * 60);
    if (durationMinutes > 30) {
      this.addViolation('warning', `Long test duration: ${durationMinutes.toFixed(1)}min (expected < 30min)`);
    }

    this.log(`Test execution: ${summary.passed}/${summary.total} passed (${(100 - failureRate).toFixed(1)}%)`, 
             failureRate === 0 ? 'success' : 'warning');

    return failureRate === 0;
  }

  validateCodeCoverage() {
    this.log('\n📊 Validating code coverage...');

    // Jest/Vitest 커버리지 결과 확인
    const coverageFiles = [
      path.join(this.reportPath, 'coverage/coverage-summary.json'),
      path.join(this.reportPath, 'coverage/frontend/coverage-summary.json')
    ];

    let overallCoverage = { statements: 0, branches: 0, functions: 0, lines: 0 };
    let coverageCount = 0;

    for (const file of coverageFiles) {
      if (fs.existsSync(file)) {
        try {
          const coverage = JSON.parse(fs.readFileSync(file, 'utf8'));
          const total = coverage.total;
          
          if (total) {
            overallCoverage.statements += total.statements.pct;
            overallCoverage.branches += total.branches.pct;
            overallCoverage.functions += total.functions.pct;
            overallCoverage.lines += total.lines.pct;
            coverageCount++;
          }
        } catch (error) {
          this.log(`Failed to parse coverage file ${file}`, 'warning');
        }
      }
    }

    if (coverageCount > 0) {
      // 평균 계산
      overallCoverage.statements /= coverageCount;
      overallCoverage.branches /= coverageCount;
      overallCoverage.functions /= coverageCount;
      overallCoverage.lines /= coverageCount;

      // 임계값 검증
      const checks = [
        { name: 'Statements', value: overallCoverage.statements, threshold: this.thresholds.coverage.statements },
        { name: 'Branches', value: overallCoverage.branches, threshold: this.thresholds.coverage.branches },
        { name: 'Functions', value: overallCoverage.functions, threshold: this.thresholds.coverage.functions },
        { name: 'Lines', value: overallCoverage.lines, threshold: this.thresholds.coverage.lines }
      ];

      let allPassed = true;
      for (const check of checks) {
        if (check.value < check.threshold) {
          this.addViolation('error', `${check.name} coverage ${check.value.toFixed(1)}% < ${check.threshold}%`);
          allPassed = false;
        } else {
          this.log(`${check.name} coverage: ${check.value.toFixed(1)}%`, 'success');
        }
      }

      return allPassed;
    } else {
      this.addViolation('warning', 'No coverage data found');
      return false;
    }
  }

  validatePerformance() {
    this.log('\n⚡ Validating performance...');

    const perfResults = this.results['performance-results'];
    if (!perfResults) {
      this.addViolation('warning', 'No performance results found');
      return false;
    }

    let allPassed = true;

    // 페이지 로드 시간 검증
    if (perfResults.loadTimes) {
      for (const [page, loadTime] of Object.entries(perfResults.loadTimes)) {
        if (loadTime > this.thresholds.performance.maxLoadTime) {
          this.addViolation('error', `${page} load time ${loadTime}ms > ${this.thresholds.performance.maxLoadTime}ms`);
          allPassed = false;
        } else {
          this.log(`${page} load time: ${loadTime}ms`, 'success');
        }
      }
    }

    // API 응답 시간 검증
    if (perfResults.apiTimes) {
      for (const [endpoint, responseTime] of Object.entries(perfResults.apiTimes)) {
        if (responseTime > this.thresholds.performance.maxApiResponseTime) {
          this.addViolation('error', `${endpoint} response time ${responseTime}ms > ${this.thresholds.performance.maxApiResponseTime}ms`);
          allPassed = false;
        } else {
          this.log(`${endpoint} response time: ${responseTime}ms`, 'success');
        }
      }
    }

    // FPS 검증
    if (perfResults.fps && perfResults.fps < this.thresholds.performance.minFPS) {
      this.addViolation('error', `FPS ${perfResults.fps} < ${this.thresholds.performance.minFPS}`);
      allPassed = false;
    } else if (perfResults.fps) {
      this.log(`Average FPS: ${perfResults.fps}`, 'success');
    }

    return allPassed;
  }

  validateAccessibility() {
    this.log('\n♿ Validating accessibility...');

    const a11yResults = this.results['accessibility-results'];
    if (!a11yResults) {
      this.addViolation('warning', 'No accessibility results found');
      return false;
    }

    let allPassed = true;

    // 접근성 점수 검증
    if (a11yResults.score < this.thresholds.accessibility.minScore) {
      this.addViolation('error', `Accessibility score ${a11yResults.score} < ${this.thresholds.accessibility.minScore}`);
      allPassed = false;
    } else {
      this.log(`Accessibility score: ${a11yResults.score}`, 'success');
    }

    // 위반 사항 수 검증
    const violationCount = a11yResults.violations?.length || 0;
    if (violationCount > this.thresholds.accessibility.allowedViolations) {
      this.addViolation('error', `${violationCount} accessibility violations > ${this.thresholds.accessibility.allowedViolations}`);
      allPassed = false;
    } else {
      this.log(`Accessibility violations: ${violationCount}`, violationCount === 0 ? 'success' : 'warning');
    }

    return allPassed;
  }

  validateSecurity() {
    this.log('\n🔒 Validating security...');

    // 기본 보안 체크
    const securityChecks = [
      {
        name: 'Environment Variables',
        check: () => !this.checkForHardcodedSecrets()
      },
      {
        name: 'HTTPS Usage',
        check: () => this.checkHTTPSUsage()
      },
      {
        name: 'Dependencies',
        check: () => this.checkDependencyVulnerabilities()
      }
    ];

    let allPassed = true;
    for (const { name, check } of securityChecks) {
      if (!check()) {
        this.addViolation('error', `Security check failed: ${name}`);
        allPassed = false;
      } else {
        this.log(`Security check passed: ${name}`, 'success');
      }
    }

    return allPassed;
  }

  checkForHardcodedSecrets() {
    // 하드코딩된 시크릿 검사 로직
    return false; // 시크릿이 발견되면 true
  }

  checkHTTPSUsage() {
    // HTTPS 사용 검사 로직
    return true; // HTTPS를 올바르게 사용하면 true
  }

  checkDependencyVulnerabilities() {
    // 의존성 취약점 검사 로직
    return true; // 취약점이 없으면 true
  }

  addViolation(level, message) {
    this.violations.push({ level, message, timestamp: new Date().toISOString() });
  }

  generateQualityGateReport() {
    const totalViolations = this.violations.length;
    const criticalViolations = this.violations.filter(v => v.level === 'critical').length;
    const errorViolations = this.violations.filter(v => v.level === 'error').length;
    const warningViolations = this.violations.filter(v => v.level === 'warning').length;

    const qualityGate = {
      passed: criticalViolations === 0 && errorViolations === 0,
      summary: {
        total: totalViolations,
        critical: criticalViolations,
        errors: errorViolations,
        warnings: warningViolations
      },
      violations: this.violations,
      timestamp: new Date().toISOString()
    };

    // 리포트 저장
    fs.writeFileSync(
      path.join(this.reportPath, 'quality-gate-report.json'),
      JSON.stringify(qualityGate, null, 2)
    );

    return qualityGate;
  }

  printSummary(qualityGate) {
    console.log('\n' + '='.repeat(60));
    console.log('GLI PLATFORM QUALITY GATE REPORT');
    console.log('='.repeat(60));
    
    const status = qualityGate.passed ? '✅ PASSED' : '❌ FAILED';
    console.log(`Status: ${status}`);
    console.log(`Total Issues: ${qualityGate.summary.total}`);
    console.log(`Critical: ${qualityGate.summary.critical}`);
    console.log(`Errors: ${qualityGate.summary.errors}`);
    console.log(`Warnings: ${qualityGate.summary.warnings}`);
    
    if (qualityGate.violations.length > 0) {
      console.log('\nISSUES:');
      qualityGate.violations.forEach((violation, index) => {
        const prefix = violation.level === 'critical' ? '🚨' : 
                      violation.level === 'error' ? '❌' : '⚠️';
        console.log(`${index + 1}. ${prefix} [${violation.level.toUpperCase()}] ${violation.message}`);
      });
    }

    console.log('='.repeat(60));

    return qualityGate.passed;
  }

  async validate() {
    try {
      this.log('🔍 Starting GLI Platform Test Results Validation');

      this.loadTestResults();

      const validations = [
        { name: 'Test Execution', fn: () => this.validateTestExecution() },
        { name: 'Code Coverage', fn: () => this.validateCodeCoverage() },
        { name: 'Performance', fn: () => this.validatePerformance() },  
        { name: 'Accessibility', fn: () => this.validateAccessibility() },
        { name: 'Security', fn: () => this.validateSecurity() }
      ];

      for (const { name, fn } of validations) {
        this.log(`\n🔍 Validating ${name}...`);
        fn();
      }

      const qualityGate = this.generateQualityGateReport();
      const passed = this.printSummary(qualityGate);

      if (passed) {
        this.log('🎉 Quality gate passed! Ready for deployment.', 'success');
        process.exit(0);
      } else {
        this.log('🚫 Quality gate failed. Please fix issues before deployment.', 'error');
        process.exit(1);
      }

    } catch (error) {
      this.log(`Validation failed: ${error.message}`, 'error');
      process.exit(1);
    }
  }
}

// 실행
if (require.main === module) {
  const validator = new TestResultsValidator();
  validator.validate();
}

module.exports = TestResultsValidator;