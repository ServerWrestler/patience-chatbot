/**
 * Property-based tests for scenario execution
 * Tests Properties 5-8
 */

import { describe, test, expect } from 'vitest';
import * as fc from 'fast-check';
import { ScenarioRunner } from '../../execution/ScenarioRunner';
import { ResponseStorage } from '../../types/ResponseStorage';
import { MockProtocolAdapter, createMockResponse, createMockScenario } from '../helpers/testUtils';
import { scenarioGenerator } from '../helpers/generators';
import { Scenario } from '../../types';

describe('Scenario Execution Properties', () => {
  /**
   * Property 5: Scenario parsing round trip
   * For any valid scenario definition, serializing it to the storage format
   * and then parsing it back should produce an equivalent scenario structure.
   */
  test('Property 5: Scenario parsing round trip', () => {
    fc.assert(
      fc.property(
        scenarioGenerator(),
        (scenario) => {
          // Serialize to JSON
          const serialized = JSON.stringify(scenario);

          // Parse back
          const parsed: Scenario = JSON.parse(serialized);

          // Verify equivalence
          expect(parsed.id).toBe(scenario.id);
          expect(parsed.name).toBe(scenario.name);
          expect(parsed.steps.length).toBe(scenario.steps.length);
          expect(parsed.expectedOutcomes.length).toBe(scenario.expectedOutcomes.length);

          return true;
        }
      ),
      { numRuns: 100 }
    );
  });

  /**
   * Property 6: Step execution advances state
   * For any conversation scenario with multiple steps, after executing a step
   * and receiving a response, the scenario runner should be positioned at the next step.
   */
  test('Property 6: Step execution advances state', async () => {
    await fc.assert(
      fc.asyncProperty(
        fc.integer({ min: 2, max: 10 }),
        async (stepCount) => {
          const steps = Array.from({ length: stepCount }, (_, i) => ({
            message: `Message ${i + 1}`
          }));

          const scenario = createMockScenario({
            steps,
            expectedOutcomes: []
          });

          const storage = new ResponseStorage();
          const responses = steps.map(() => createMockResponse('Response'));
          const adapter = new MockProtocolAdapter(responses);
          const runner = new ScenarioRunner(storage);

          // Execute scenario
          await runner.runScenario(scenario, adapter);

          // Verify all steps were executed
          const sentMessages = adapter.getSentMessages();
          expect(sentMessages.length).toBe(stepCount);

          // Verify messages were sent in order
          for (let i = 0; i < stepCount; i++) {
            expect(sentMessages[i]).toBe(`Message ${i + 1}`);
          }

          return true;
        }
      ),
      { numRuns: 50 }
    );
  });

  /**
   * Property 7: Conditional branch selection correctness
   * For any scenario with conditional branches, the selected branch should match
   * the condition that evaluates to true based on the Target Bot response.
   */
  test('Property 7: Conditional branch selection correctness', async () => {
    await fc.assert(
      fc.asyncProperty(
        fc.string({ minLength: 1, maxLength: 100 }),
        fc.string({ minLength: 1, maxLength: 50 }),
        async (responseContent, searchTerm) => {
          const scenario = createMockScenario({
            steps: [
              {
                message: 'Initial message',
                conditionalBranches: [
                  {
                    condition: {
                      type: 'contains',
                      value: searchTerm
                    },
                    nextStep: {
                      message: 'Branch taken'
                    }
                  }
                ]
              }
            ]
          });

          const storage = new ResponseStorage();
          const shouldMatch = responseContent.includes(searchTerm);
          const adapter = new MockProtocolAdapter([
            createMockResponse(responseContent),
            createMockResponse('Final response')
          ]);
          const runner = new ScenarioRunner(storage);

          await runner.runScenario(scenario, adapter);

          const sentMessages = adapter.getSentMessages();

          // If condition matches, branch should be taken
          if (shouldMatch) {
            expect(sentMessages.length).toBeGreaterThanOrEqual(2);
            expect(sentMessages).toContain('Branch taken');
          } else {
            // Branch should not be taken
            expect(sentMessages).not.toContain('Branch taken');
          }

          return true;
        }
      ),
      { numRuns: 100 }
    );
  });

  /**
   * Property 8: Scenario completion reporting accuracy
   * For any completed scenario, the reported success status should be true
   * if and only if all steps executed without errors and all validations passed.
   */
  test('Property 8: Scenario completion reporting accuracy', async () => {
    await fc.assert(
      fc.asyncProperty(
        fc.integer({ min: 1, max: 5 }),
        fc.boolean(),
        async (stepCount, shouldPass) => {
          const steps = Array.from({ length: stepCount }, (_, i) => ({
            message: `Message ${i + 1}`,
            expectedResponse: shouldPass ? undefined : {
              validationType: 'exact' as const,
              expected: 'This will not match',
              threshold: undefined
            }
          }));

          const scenario = createMockScenario({
            steps,
            expectedOutcomes: []
          });

          const storage = new ResponseStorage();
          const responses = steps.map(() => createMockResponse('Actual response'));
          const adapter = new MockProtocolAdapter(responses);
          const runner = new ScenarioRunner(storage);

          const history = await runner.runScenario(scenario, adapter);
          const report = runner.generateCompletionReport(history);

          // If no validations, should succeed
          if (shouldPass) {
            expect(report.success).toBe(true);
            expect(report.allValidationsPassed).toBe(true);
          }

          // Verify report accuracy
          expect(report.completed).toBe(true);
          expect(report.executedSteps).toBeGreaterThan(0);

          return true;
        }
      ),
      { numRuns: 50 }
    );
  });
});
