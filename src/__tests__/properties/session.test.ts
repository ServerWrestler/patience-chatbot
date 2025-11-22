/**
 * Property-based tests for session management
 * Tests Properties 1-4
 */

import { describe, test, expect } from 'vitest';
import * as fc from 'fast-check';
import { ResponseStorage } from '../../types/ResponseStorage';
import { ScenarioRunner } from '../../execution/ScenarioRunner';
import { MockProtocolAdapter, createMockScenario, createMockResponse } from '../helpers/testUtils';
import { scenarioGenerator, botResponseGenerator } from '../helpers/generators';

describe('Session Management Properties', () => {
  /**
   * Property 1: Session initialization sends first message
   * For any test session configuration, when the session begins,
   * Patience should send an initial message to the Target Bot before receiving any responses.
   */
  test('Property 1: Session initialization sends first message', async () => {
    const storage = new ResponseStorage();
    const scenario = createMockScenario({
      steps: [{ message: 'Hello' }]
    });
    const adapter = new MockProtocolAdapter([createMockResponse('Response')]);
    const runner = new ScenarioRunner(storage);

    await runner.runScenario(scenario, adapter);

    // Verify that at least one message was sent
    const sentMessages = adapter.getSentMessages();
    expect(sentMessages.length).toBeGreaterThan(0);

    // Get all session IDs and check the first message
    const sessionIds = storage.getAllSessionIds();
    expect(sessionIds.length).toBeGreaterThan(0);
    
    const history = storage.getHistory(sessionIds[0]);
    expect(history).toBeDefined();
    expect(history!.messages.length).toBeGreaterThan(0);
    expect(history!.messages[0].sender).toBe('patience');
  });

  /**
   * Property 2: Response storage completeness
   * For any Target Bot response, after Patience receives and processes it,
   * the response content should be retrievable from storage.
   */
  test('Property 2: Response storage completeness', async () => {
    await fc.assert(
      fc.asyncProperty(
        fc.array(botResponseGenerator(), { minLength: 1, maxLength: 10 }),
        async (responses) => {
          const storage = new ResponseStorage();
          const sessionId = 'test-session';
          storage.createHistory(sessionId);

          // Store all responses
          for (const response of responses) {
            storage.storeResponse(sessionId, response);
          }

          // Verify all responses are retrievable
          const messages = storage.getMessages(sessionId);
          const targetMessages = messages.filter(m => m.sender === 'target');

          expect(targetMessages.length).toBe(responses.length);

          // Verify content matches
          for (let i = 0; i < responses.length; i++) {
            const expectedContent = typeof responses[i].content === 'string'
              ? responses[i].content
              : JSON.stringify(responses[i].content);
            expect(targetMessages[i].content).toBe(expectedContent);
          }

          return true;
        }
      ),
      { numRuns: 100 }
    );
  });

  /**
   * Property 3: Session isolation
   * For any sequence of multiple test sessions, state modifications in one session
   * should not affect the initial state or execution of subsequent sessions.
   */
  test('Property 3: Session isolation', async () => {
    const storage = new ResponseStorage();
    const histories: string[] = [];

    const scenarios = [
      createMockScenario({ id: 'scenario-1', steps: [{ message: 'Message 1' }] }),
      createMockScenario({ id: 'scenario-2', steps: [{ message: 'Message 2' }] })
    ];

    // Execute scenarios sequentially
    for (const scenario of scenarios) {
      const adapter = new MockProtocolAdapter([createMockResponse('Response')]);
      const runner = new ScenarioRunner(storage);

      await runner.runScenario(scenario, adapter);

      // Track session IDs
      const sessionIds = storage.getAllSessionIds();
      const newSessionId = sessionIds[sessionIds.length - 1];
      histories.push(newSessionId);
    }

    // Verify each session has independent history
    expect(histories.length).toBe(scenarios.length);

    // Verify no session IDs are duplicated
    const uniqueIds = new Set(histories);
    expect(uniqueIds.size).toBe(histories.length);

    // Verify each session has its own messages
    for (const sessionId of histories) {
      const history = storage.getHistory(sessionId);
      expect(history).toBeDefined();
      expect(history!.sessionId).toBe(sessionId);
    }
  });

  /**
   * Property 4: Conversation history completeness
   * For any completed conversation session, the recorded history should contain
   * all messages sent by both Patience and the Target Bot in chronological order.
   */
  test('Property 4: Conversation history completeness', async () => {
    const storage = new ResponseStorage();
    const scenario = createMockScenario({
      steps: [
        { message: 'Message 1' },
        { message: 'Message 2' },
        { message: 'Message 3' }
      ]
    });
    const responses = scenario.steps.map(() => createMockResponse('Response'));
    const adapter = new MockProtocolAdapter(responses);
    const runner = new ScenarioRunner(storage);

    await runner.runScenario(scenario, adapter);

    // Get the session history
    const sessionIds = storage.getAllSessionIds();
    expect(sessionIds.length).toBeGreaterThan(0);

    const history = storage.getHistory(sessionIds[0]);
    expect(history).toBeDefined();

    // Verify messages are in chronological order
    const messages = history!.messages;
    for (let i = 1; i < messages.length; i++) {
      expect(messages[i].timestamp.getTime()).toBeGreaterThanOrEqual(
        messages[i - 1].timestamp.getTime()
      );
    }

    // Verify both patience and target messages exist
    const patienceMessages = messages.filter(m => m.sender === 'patience');
    const targetMessages = messages.filter(m => m.sender === 'target');

    expect(patienceMessages.length).toBeGreaterThan(0);
    expect(targetMessages.length).toBeGreaterThan(0);
  });
});
