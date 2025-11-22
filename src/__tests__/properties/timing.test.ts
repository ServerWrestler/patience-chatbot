/**
 * Property-based tests for timing management
 * Tests Properties 21-23
 */

import { describe, test, expect } from 'vitest';
import * as fc from 'fast-check';
import { TimingManager } from '../../execution/TimingManager';

describe('Timing Management Properties', () => {
  /**
   * Property 21: Message delay correlation
   * For any two messages with timing enabled where message A is longer than message B,
   * the delay before sending message A should be greater than or equal to the delay before sending message B.
   */
  test('Property 21: Message delay correlation', () => {
    fc.assert(
      fc.property(
        fc.string({ minLength: 1, maxLength: 50 }),
        fc.string({ minLength: 51, maxLength: 200 }),
        (shortMessage, longMessage) => {
          const timingManager = new TimingManager({
            enableDelays: true,
            baseDelay: 100,
            delayPerCharacter: 10,
            rapidFire: false,
            responseTimeout: 5000
          });

          const shortDelay = timingManager.calculateMessageDelay(shortMessage);
          const longDelay = timingManager.calculateMessageDelay(longMessage);

          // Longer message should have longer or equal delay
          expect(longDelay).toBeGreaterThanOrEqual(shortDelay);

          return true;
        }
      ),
      { numRuns: 100 }
    );
  });

  /**
   * Property 22: Rapid-fire mode timing
   * For any test session with rapid-fire mode enabled, the time between
   * consecutive message sends should be minimal (less than a small threshold like 10ms).
   */
  test('Property 22: Rapid-fire mode timing', () => {
    fc.assert(
      fc.property(
        fc.string({ minLength: 1, maxLength: 200 }),
        (message) => {
          const timingManager = new TimingManager({
            enableDelays: false,
            baseDelay: 0,
            delayPerCharacter: 0,
            rapidFire: true,
            responseTimeout: 5000
          });

          const delay = timingManager.calculateMessageDelay(message);

          // In rapid-fire mode, delay should be minimal or zero
          expect(delay).toBeLessThanOrEqual(10);

          return true;
        }
      ),
      { numRuns: 100 }
    );
  });

  /**
   * Property 23: Timeout enforcement
   * For any interaction with a configured timeout threshold, if the Target Bot
   * response time exceeds the threshold, the interaction should be marked as failed.
   */
  test('Property 23: Timeout enforcement', async () => {
    await fc.assert(
      fc.asyncProperty(
        fc.integer({ min: 100, max: 1000 }),
        fc.integer({ min: 50, max: 500 }),
        async (timeout, responseTime) => {
          const timingManager = new TimingManager({
            enableDelays: false,
            baseDelay: 0,
            delayPerCharacter: 0,
            rapidFire: true,
            responseTimeout: timeout
          });

          const isTimeout = timingManager.isTimeout(responseTime);

          // Should timeout if response time exceeds configured timeout
          if (responseTime > timeout) {
            expect(isTimeout).toBe(true);
          } else {
            expect(isTimeout).toBe(false);
          }

          return true;
        }
      ),
      { numRuns: 100 }
    );
  });
});
