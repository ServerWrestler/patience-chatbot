/**
 * Unit tests for ScenarioRunner
 */

import { describe, test, expect } from 'vitest';
import { ScenarioRunner } from '../../execution/ScenarioRunner';
import { ResponseStorage } from '../../types/ResponseStorage';
import { MockProtocolAdapter, createMockScenario, createMockResponse } from '../helpers/testUtils';

describe('ScenarioRunner', () => {
  test('should execute scenario steps in order', async () => {
    const storage = new ResponseStorage();
    const scenario = createMockScenario({
      steps: [
        { message: 'Step 1' },
        { message: 'Step 2' },
        { message: 'Step 3' }
      ]
    });

    const adapter = new MockProtocolAdapter([
      createMockResponse('Response 1'),
      createMockResponse('Response 2'),
      createMockResponse('Response 3')
    ]);

    const runner = new ScenarioRunner(storage);
    await runner.runScenario(scenario, adapter);

    const sentMessages = adapter.getSentMessages();
    expect(sentMessages).toEqual(['Step 1', 'Step 2', 'Step 3']);
  });

  test('should evaluate conditional branches', async () => {
    const storage = new ResponseStorage();
    const scenario = createMockScenario({
      steps: [
        {
          message: 'Initial',
          conditionalBranches: [
            {
              condition: {
                type: 'contains',
                value: 'yes'
              },
              nextStep: {
                message: 'Branch taken'
              }
            }
          ]
        }
      ]
    });

    const adapter = new MockProtocolAdapter([
      createMockResponse('yes, proceed'),
      createMockResponse('Final response')
    ]);

    const runner = new ScenarioRunner(storage);
    await runner.runScenario(scenario, adapter);

    const sentMessages = adapter.getSentMessages();
    expect(sentMessages).toContain('Branch taken');
  });

  test('should generate completion report', async () => {
    const storage = new ResponseStorage();
    const scenario = createMockScenario({
      steps: [
        { message: 'Test message' }
      ]
    });

    const adapter = new MockProtocolAdapter([
      createMockResponse('Response')
    ]);

    const runner = new ScenarioRunner(storage);
    const history = await runner.runScenario(scenario, adapter);
    const report = runner.generateCompletionReport(history);

    expect(report.completed).toBe(true);
    expect(report.executedSteps).toBeGreaterThan(0);
    expect(report.success).toBe(true);
  });

  test('should track current step index', async () => {
    const storage = new ResponseStorage();
    const scenario = createMockScenario({
      steps: [
        { message: 'Step 1' },
        { message: 'Step 2' }
      ]
    });

    const adapter = new MockProtocolAdapter([
      createMockResponse('Response 1'),
      createMockResponse('Response 2')
    ]);

    const runner = new ScenarioRunner(storage);
    await runner.runScenario(scenario, adapter);

    // After completion, should be at the end
    expect(runner.hasMoreSteps()).toBe(false);
  });

  test('should select correct conditional branch', () => {
    const storage = new ResponseStorage();
    const runner = new ScenarioRunner(storage);

    const branches = [
      {
        condition: { type: 'contains' as const, value: 'yes' },
        nextStep: { message: 'Branch 1' }
      },
      {
        condition: { type: 'contains' as const, value: 'no' },
        nextStep: { message: 'Branch 2' }
      }
    ];

    const response = createMockResponse('yes, proceed');
    const selectedIndex = runner.selectBranch(branches, response);

    expect(selectedIndex).toBe(0);
  });

  test('should return -1 when no branch matches', () => {
    const storage = new ResponseStorage();
    const runner = new ScenarioRunner(storage);

    const branches = [
      {
        condition: { type: 'contains' as const, value: 'yes' },
        nextStep: { message: 'Branch 1' }
      }
    ];

    const response = createMockResponse('maybe');
    const selectedIndex = runner.selectBranch(branches, response);

    expect(selectedIndex).toBe(-1);
  });

  test('should check scenario success', async () => {
    const storage = new ResponseStorage();
    const scenario = createMockScenario({
      steps: [
        { message: 'Test message' }
      ]
    });

    const adapter = new MockProtocolAdapter([
      createMockResponse('Success response')
    ]);

    const runner = new ScenarioRunner(storage);
    const history = await runner.runScenario(scenario, adapter);
    
    // Check if scenario has any error messages
    const hasErrors = history.messages.some(msg => 
      msg.content.toLowerCase().includes('error')
    );

    expect(hasErrors).toBe(false);
  });

  test('should get execution summary', async () => {
    const storage = new ResponseStorage();
    const scenario = createMockScenario({
      steps: [
        { message: 'Message 1' },
        { message: 'Message 2' }
      ]
    });

    const adapter = new MockProtocolAdapter([
      createMockResponse('Response 1'),
      createMockResponse('Response 2')
    ]);

    const runner = new ScenarioRunner(storage);
    const history = await runner.runScenario(scenario, adapter);
    const summary = runner.getExecutionSummary(history);

    expect(summary.totalMessages).toBeGreaterThan(0);
    expect(summary.patienceMessages).toBeGreaterThan(0);
    expect(summary.targetMessages).toBeGreaterThan(0);
  });

  test('should handle errors gracefully', async () => {
    const storage = new ResponseStorage();
    const scenario = createMockScenario();

    const adapter = new MockProtocolAdapter([
      createMockResponse('', { error: new Error('Test error') })
    ]);

    const runner = new ScenarioRunner(storage);
    const history = await runner.runScenario(scenario, adapter);

    expect(history).toBeDefined();
    expect(history.messages.length).toBeGreaterThan(0);
  });
});
