/**
 * Property-based tests for response validation
 * Tests Properties 12-14
 */

import { describe, test, expect } from 'vitest';
import * as fc from 'fast-check';
import { ResponseValidator } from '../../validation/ResponseValidator';
import { createMockResponse, createValidationCriteria } from '../helpers/testUtils';
import { validationTypeGenerator } from '../helpers/generators';

describe('Response Validation Properties', () => {
  /**
   * Property 12: Validation execution completeness
   * For any Target Bot response with associated validation criteria,
   * Patience should execute the validation and produce a result indicating pass or fail.
   */
  test('Property 12: Validation execution completeness', () => {
    fc.assert(
      fc.property(
        fc.string({ minLength: 0, maxLength: 200 }),
        fc.string({ minLength: 0, maxLength: 200 }),
        validationTypeGenerator(),
        (responseContent, expectedContent, validationType) => {
          const validator = new ResponseValidator();
          const response = createMockResponse(responseContent);
          const criteria = createValidationCriteria(validationType, expectedContent);

          const result = validator.validate(response, criteria);

          // Validation should always produce a result
          expect(result).toBeDefined();
          expect(typeof result.passed).toBe('boolean');
          expect(typeof result.actual).toBe('string');

          return true;
        }
      ),
      { numRuns: 100 }
    );
  });

  /**
   * Property 13: Validation failure recording
   * For any validation that fails, the recorded result should include
   * both the expected value and the actual value received.
   */
  test('Property 13: Validation failure recording', () => {
    fc.assert(
      fc.property(
        fc.string({ minLength: 1, maxLength: 100 }),
        fc.string({ minLength: 1, maxLength: 100 }),
        (responseContent, expectedContent) => {
          // Ensure they're different to guarantee failure
          const actualContent = responseContent + '_different';
          const validator = new ResponseValidator();
          const response = createMockResponse(actualContent);
          const criteria = createValidationCriteria('exact', expectedContent);

          const result = validator.validate(response, criteria);

          // If validation fails, should have both expected and actual
          if (!result.passed) {
            expect(result.expected).toBeDefined();
            expect(result.actual).toBeDefined();
            expect(result.expected).toBe(expectedContent);
            expect(result.actual).toBe(actualContent);
          }

          return true;
        }
      ),
      { numRuns: 100 }
    );
  });

  /**
   * Property 14: Multi-type validation support
   * For any validation type (exact match, pattern match, semantic similarity),
   * Patience should correctly evaluate responses according to that validation type's rules.
   */
  test('Property 14: Multi-type validation support', () => {
    fc.assert(
      fc.property(
        fc.string({ minLength: 1, maxLength: 100 }),
        (content) => {
          const validator = new ResponseValidator();
          const response = createMockResponse(content);

          // Test exact match
          const exactCriteria = createValidationCriteria('exact', content);
          const exactResult = validator.validate(response, exactCriteria);
          expect(exactResult.passed).toBe(true);

          // Test pattern match
          const patternCriteria = createValidationCriteria('pattern', /.*/, 0);
          const patternResult = validator.validate(response, patternCriteria);
          expect(patternResult.passed).toBe(true);

          // Test semantic similarity (with itself should be 1.0)
          const semanticCriteria = createValidationCriteria('semantic', content, 0.9);
          const semanticResult = validator.validate(response, semanticCriteria);
          expect(semanticResult.passed).toBe(true);

          return true;
        }
      ),
      { numRuns: 100 }
    );
  });
});
