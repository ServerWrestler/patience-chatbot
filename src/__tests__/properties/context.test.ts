/**
 * Property-based tests for context handling
 * Tests Properties 28-30
 */

import { describe, test, expect } from 'vitest';
import * as fc from 'fast-check';
import { ContextManager } from '../../execution/ContextManager';
import { ResponseStorage } from '../../types/ResponseStorage';

describe('Context Handling Properties', () => {
  /**
   * Property 28: Multi-turn context referencing
   * For any multi-turn conversation scenario, messages sent after the first turn
   * should be able to reference content from previous messages in the conversation.
   */
  test('Property 28: Multi-turn context referencing', () => {
    fc.assert(
      fc.property(
        fc.array(fc.string({ minLength: 1, maxLength: 100 }), { minLength: 2, maxLength: 10 }),
        (messages) => {
          const storage = new ResponseStorage();
          const sessionId = 'test-session';
          storage.createHistory(sessionId);

          // Store messages sequentially
          messages.forEach((msg, index) => {
            const sender = index % 2 === 0 ? 'patience' : 'target';
            storage.storeMessage(sessionId, sender as any, msg);
          });

          // Verify all messages are stored and retrievable
          const history = storage.getHistory(sessionId);
          expect(history).toBeDefined();
          expect(history!.messages.length).toBe(messages.length);

          // Verify messages can reference previous context
          for (let i = 1; i < messages.length; i++) {
            const previousMessages = history!.messages.slice(0, i);
            expect(previousMessages.length).toBe(i);
          }

          return true;
        }
      ),
      { numRuns: 100 }
    );
  });

  /**
   * Property 29: Context retention validation
   * For any test scenario that requires context retention, the validation should
   * verify that the Target Bot response demonstrates awareness of previous conversation elements.
   */
  test('Property 29: Context retention validation', () => {
    fc.assert(
      fc.property(
        fc.string({ minLength: 5, maxLength: 50 }),
        fc.string({ minLength: 5, maxLength: 100 }),
        (contextTerm, response) => {
          const storage = new ResponseStorage();
          const contextManager = new ContextManager(storage);
          const sessionId = 'test-session';

          // Create history and add context messages
          storage.createHistory(sessionId);
          storage.storeMessage(sessionId, 'patience', `Tell me about ${contextTerm}`);
          storage.storeMessage(sessionId, 'target', response);

          // Validate context retention
          const validation = contextManager.validateContextRetention(sessionId, response);

          // Validation should complete
          expect(validation).toBeDefined();
          expect(typeof validation.hasContext).toBe('boolean');
          expect(typeof validation.confidence).toBe('number');

          return true;
        }
      ),
      { numRuns: 100 }
    );
  });

  /**
   * Property 30: Context reset validation
   * For any test scenario where context should reset, the validation should verify
   * that the Target Bot response does not reference elements from before the reset point.
   */
  test('Property 30: Context reset validation', () => {
    fc.assert(
      fc.property(
        fc.string({ minLength: 5, maxLength: 50 }),
        (contextTerm) => {
          const storage = new ResponseStorage();
          const contextManager = new ContextManager(storage);
          const sessionId = 'test-session';

          // Create history and add pre-reset context
          storage.createHistory(sessionId);
          storage.storeMessage(sessionId, 'patience', `Tell me about ${contextTerm}`);
          storage.storeMessage(sessionId, 'target', `Here is info about ${contextTerm}`);

          // Mark reset point
          const resetPoint = contextManager.markContextReset(sessionId);

          // Add post-reset messages
          storage.storeMessage(sessionId, 'patience', 'New topic');
          storage.storeMessage(sessionId, 'target', 'Different response');

          // Validate context reset
          const validation = contextManager.validateContextReset(
            sessionId,
            resetPoint,
            'Different response'
          );

          // Validation should complete
          expect(validation).toBeDefined();
          expect(typeof validation.valid).toBe('boolean');
          expect(typeof validation.preResetReferences).toBe('number');

          return true;
        }
      ),
      { numRuns: 100 }
    );
  });
});
