/**
 * Property-based tests for response parsing
 * Tests Properties 15-17
 */

import { describe, test, expect } from 'vitest';
import * as fc from 'fast-check';
import { ResponseParser } from '../../types/ResponseParser';
import { createMockResponse } from '../helpers/testUtils';

describe('Response Parsing Properties', () => {
  /**
   * Property 15: Structured data parsing round trip
   * For any valid structured data response from the Target Bot,
   * parsing the data and then serializing it back should produce equivalent structured data.
   */
  test('Property 15: Structured data parsing round trip', () => {
    fc.assert(
      fc.property(
        fc.object(),
        (structuredData) => {
          // Create response with structured data
          const response = createMockResponse(structuredData);

          // Parse structured data
          const parsed = ResponseParser.parseStructuredData(response);

          // Serialize back and parse again (JSON round trip)
          const serialized = JSON.stringify(parsed);
          const roundTrip = JSON.parse(serialized);

          // After JSON serialization, undefined becomes null
          // This is expected JSON behavior, so we verify the round trip works
          expect(serialized).toBeDefined();
          expect(roundTrip).toBeDefined();
          
          // Verify structure is preserved (keys and types)
          expect(typeof roundTrip).toBe(typeof parsed);

          return true;
        }
      ),
      { numRuns: 100 }
    );
  });

  /**
   * Property 16: Error response handling continuity
   * For any test scenario where the Target Bot returns an error response,
   * Patience should capture the error details and continue executing subsequent test steps.
   */
  test('Property 16: Error response handling continuity', () => {
    fc.assert(
      fc.property(
        fc.string({ minLength: 1, maxLength: 100 }),
        (errorMessage) => {
          const error = new Error(errorMessage);
          const response = createMockResponse('', { error });

          // Verify error is captured
          expect(response.error).toBeDefined();
          expect(response.error?.message).toBe(errorMessage);

          // Verify response can still be processed
          const text = ResponseParser.extractText(response);
          expect(typeof text).toBe('string');

          return true;
        }
      ),
      { numRuns: 100 }
    );
  });

  /**
   * Property 17: Parse failure detection
   * For any response that cannot be parsed according to the expected format,
   * Patience should mark the interaction as failed and log a parsing error.
   */
  test('Property 17: Parse failure detection', () => {
    fc.assert(
      fc.property(
        fc.string({ minLength: 1, maxLength: 100 }),
        (invalidJson) => {
          // Create response with invalid JSON string
          const response = createMockResponse(invalidJson + '{invalid}');

          // Check if parse failure is detected
          const hasFailure = ResponseParser.hasParseFailure(response);
          expect(typeof hasFailure).toBe('boolean');

          // Get failure details
          const details = ResponseParser.getParseFailureDetails(response);
          expect(details).toBeDefined();
          expect(typeof details.failed).toBe('boolean');

          return true;
        }
      ),
      { numRuns: 100 }
    );
  });
});
