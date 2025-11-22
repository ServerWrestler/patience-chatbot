/**
 * Property-based tests for reporting
 * Tests Properties 18-20
 */

import { describe, test, expect } from 'vitest';
import * as fc from 'fast-check';
import { ReportGenerator } from '../../reporting/ReportGenerator';
import { TestResults, ScenarioResult } from '../../types';
import { createMockScenario } from '../helpers/testUtils';

describe('Reporting Properties', () => {
  /**
   * Property 18: Report completeness
   * For any completed test session, the generated report should contain
   * entries for all executed scenarios and all conversation interactions within those scenarios.
   */
  test('Property 18: Report completeness', () => {
    fc.assert(
      fc.property(
        fc.integer({ min: 1, max: 10 }),
        (scenarioCount) => {
          const scenarioResults: ScenarioResult[] = Array.from({ length: scenarioCount }, (_, i) => ({
            scenarioId: `scenario-${i}`,
            scenarioName: `Scenario ${i}`,
            passed: true,
            conversationHistory: {
              sessionId: `session-${i}`,
              messages: [
                {
                  sender: 'patience' as const,
                  content: 'Test message',
                  timestamp: new Date()
                },
                {
                  sender: 'target' as const,
                  content: 'Response',
                  timestamp: new Date()
                }
              ],
              startTime: new Date(),
              endTime: new Date()
            },
            validationResults: [],
            duration: 100
          }));

          const testResults: TestResults = {
            testRunId: 'test-run-1',
            startTime: new Date(),
            endTime: new Date(),
            scenarioResults,
            summary: {
              total: scenarioCount,
              passed: scenarioCount,
              failed: 0
            }
          };

          const generator = new ReportGenerator();
          const report = generator.generateReport(testResults);

          // Verify report contains all scenarios
          expect(report.scenarioResults.length).toBe(scenarioCount);
          expect(report.totalScenarios).toBe(scenarioCount);

          // Verify all scenarios are included
          for (let i = 0; i < scenarioCount; i++) {
            expect(report.scenarioResults[i].scenarioId).toBe(`scenario-${i}`);
          }

          return true;
        }
      ),
      { numRuns: 100 }
    );
  });

  /**
   * Property 19: Report accuracy for failures
   * For any test report containing validation failures, each failure entry
   * should include both the expected response criteria and the actual response received.
   */
  test('Property 19: Report accuracy for failures', () => {
    fc.assert(
      fc.property(
        fc.string({ minLength: 1, maxLength: 100 }),
        fc.string({ minLength: 1, maxLength: 100 }),
        (expected, actual) => {
          const scenarioResult: ScenarioResult = {
            scenarioId: 'scenario-1',
            scenarioName: 'Failed Scenario',
            passed: false,
            conversationHistory: {
              sessionId: 'session-1',
              messages: [],
              startTime: new Date(),
              endTime: new Date()
            },
            validationResults: [
              {
                passed: false,
                expected,
                actual,
                message: 'Validation failed'
              }
            ],
            duration: 100
          };

          const testResults: TestResults = {
            testRunId: 'test-run-1',
            startTime: new Date(),
            endTime: new Date(),
            scenarioResults: [scenarioResult],
            summary: {
              total: 1,
              passed: 0,
              failed: 1
            }
          };

          const generator = new ReportGenerator();
          const report = generator.generateReport(testResults);

          // Verify failure details are included
          expect(report.failedScenarios).toBe(1);
          expect(report.scenarioResults[0].validationResults.length).toBe(1);
          expect(report.scenarioResults[0].validationResults[0].expected).toBe(expected);
          expect(report.scenarioResults[0].validationResults[0].actual).toBe(actual);

          return true;
        }
      ),
      { numRuns: 100 }
    );
  });

  /**
   * Property 20: Multi-session aggregation correctness
   * For any set of test session results, the aggregated summary should have
   * total counts equal to the sum of individual session counts.
   */
  test('Property 20: Multi-session aggregation correctness', () => {
    fc.assert(
      fc.property(
        fc.array(
          fc.record({
            total: fc.integer({ min: 1, max: 10 }),
            passed: fc.integer({ min: 0, max: 10 })
          }),
          { minLength: 1, maxLength: 5 }
        ),
        (sessionSummaries) => {
          const testResultsArray: TestResults[] = sessionSummaries.map((summary, i) => ({
            testRunId: `test-run-${i}`,
            startTime: new Date(),
            endTime: new Date(),
            scenarioResults: [],
            summary: {
              total: summary.total,
              passed: Math.min(summary.passed, summary.total),
              failed: summary.total - Math.min(summary.passed, summary.total)
            }
          }));

          const generator = new ReportGenerator();
          const aggregated = generator.aggregateResults(testResultsArray);

          // Calculate expected totals
          const expectedTotal = sessionSummaries.reduce((sum, s) => sum + s.total, 0);
          const expectedPassed = sessionSummaries.reduce(
            (sum, s) => sum + Math.min(s.passed, s.total),
            0
          );
          const expectedFailed = expectedTotal - expectedPassed;

          // Verify aggregation
          expect(aggregated.aggregatedSummary.total).toBe(expectedTotal);
          expect(aggregated.aggregatedSummary.passed).toBe(expectedPassed);
          expect(aggregated.aggregatedSummary.failed).toBe(expectedFailed);

          return true;
        }
      ),
      { numRuns: 100 }
    );
  });
});
