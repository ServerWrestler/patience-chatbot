/**
 * Unit tests for ReportGenerator
 */

import { describe, test, expect } from 'vitest';
import { ReportGenerator } from '../../reporting/ReportGenerator';
import { TestResults, ScenarioResult } from '../../types';

describe('ReportGenerator', () => {
  function createTestResults(passed: number, failed: number): TestResults {
    const scenarioResults: ScenarioResult[] = [];

    for (let i = 0; i < passed; i++) {
      scenarioResults.push({
        scenarioId: `passed-${i}`,
        scenarioName: `Passed Scenario ${i}`,
        passed: true,
        conversationHistory: {
          sessionId: `session-${i}`,
          messages: [],
          startTime: new Date(),
          endTime: new Date()
        },
        validationResults: [],
        duration: 100
      });
    }

    for (let i = 0; i < failed; i++) {
      scenarioResults.push({
        scenarioId: `failed-${i}`,
        scenarioName: `Failed Scenario ${i}`,
        passed: false,
        conversationHistory: {
          sessionId: `session-${i}`,
          messages: [],
          startTime: new Date(),
          endTime: new Date()
        },
        validationResults: [
          {
            passed: false,
            expected: 'Expected',
            actual: 'Actual',
            message: 'Mismatch'
          }
        ],
        duration: 100
      });
    }

    return {
      testRunId: 'test-run-1',
      startTime: new Date(),
      endTime: new Date(),
      scenarioResults,
      summary: {
        total: passed + failed,
        passed,
        failed
      }
    };
  }

  test('should generate report with correct counts', () => {
    const generator = new ReportGenerator();
    const results = createTestResults(3, 2);

    const report = generator.generateReport(results);

    expect(report.totalScenarios).toBe(5);
    expect(report.passedScenarios).toBe(3);
    expect(report.failedScenarios).toBe(2);
  });

  test('should include all scenario results', () => {
    const generator = new ReportGenerator();
    const results = createTestResults(2, 1);

    const report = generator.generateReport(results);

    expect(report.scenarioResults.length).toBe(3);
  });

  test('should generate summary text', () => {
    const generator = new ReportGenerator();
    const results = createTestResults(3, 1);

    const report = generator.generateReport(results);

    expect(report.summary).toContain('Total Scenarios: 4');
    expect(report.summary).toContain('Passed: 3');
    expect(report.summary).toContain('Failed: 1');
  });

  test('should format report as JSON', () => {
    const generator = new ReportGenerator();
    const results = createTestResults(1, 0);
    const report = generator.generateReport(results);

    const formatted = generator.formatReport(report, 'json');

    expect(() => JSON.parse(formatted)).not.toThrow();
    const parsed = JSON.parse(formatted);
    expect(parsed.totalScenarios).toBe(1);
  });

  test('should format report as HTML', () => {
    const generator = new ReportGenerator();
    const results = createTestResults(1, 0);
    const report = generator.generateReport(results);

    const formatted = generator.formatReport(report, 'html');

    expect(formatted).toContain('<!DOCTYPE html>');
    expect(formatted).toContain('<html>');
    expect(formatted).toContain('</html>');
  });

  test('should format report as Markdown', () => {
    const generator = new ReportGenerator();
    const results = createTestResults(1, 0);
    const report = generator.generateReport(results);

    const formatted = generator.formatReport(report, 'markdown');

    expect(formatted).toContain('# Patience Test Report');
    expect(formatted).toContain('## Summary');
  });

  test('should aggregate multiple test results', () => {
    const generator = new ReportGenerator();
    const results1 = createTestResults(2, 1);
    const results2 = createTestResults(3, 0);

    const aggregated = generator.aggregateResults([results1, results2]);

    expect(aggregated.aggregatedSummary.total).toBe(6);
    expect(aggregated.aggregatedSummary.passed).toBe(5);
    expect(aggregated.aggregatedSummary.failed).toBe(1);
  });

  test('should include failure details in report', () => {
    const generator = new ReportGenerator();
    const results = createTestResults(0, 1);

    const report = generator.generateReport(results);

    expect(report.failedScenarios).toBe(1);
    expect(report.scenarioResults[0].validationResults.length).toBeGreaterThan(0);
    expect(report.scenarioResults[0].validationResults[0].expected).toBe('Expected');
    expect(report.scenarioResults[0].validationResults[0].actual).toBe('Actual');
  });

  test('should calculate success rate', () => {
    const generator = new ReportGenerator();
    const results = createTestResults(3, 1);

    const report = generator.generateReport(results);

    expect(report.summary).toContain('75.0%');
  });

  test('should handle zero scenarios', () => {
    const generator = new ReportGenerator();
    const results = createTestResults(0, 0);

    const report = generator.generateReport(results);

    expect(report.totalScenarios).toBe(0);
    expect(report.summary).toContain('0%');
  });

  test('should include timestamp in report', () => {
    const generator = new ReportGenerator();
    const results = createTestResults(1, 0);

    const report = generator.generateReport(results);

    expect(report.timestamp).toBeInstanceOf(Date);
  });

  test('should aggregate empty results array', () => {
    const generator = new ReportGenerator();

    const aggregated = generator.aggregateResults([]);

    expect(aggregated.aggregatedSummary.total).toBe(0);
    expect(aggregated.aggregatedSummary.passed).toBe(0);
    expect(aggregated.aggregatedSummary.failed).toBe(0);
  });
});
