/**
 * Unit tests for ResponseValidator
 */

import { describe, test, expect } from 'vitest';
import { ResponseValidator } from '../../validation/ResponseValidator';
import { createMockResponse, createValidationCriteria } from '../helpers/testUtils';

describe('ResponseValidator', () => {
  test('should validate exact match correctly', () => {
    const validator = new ResponseValidator();
    const response = createMockResponse('Hello World');
    const criteria = createValidationCriteria('exact', 'Hello World');

    const result = validator.validate(response, criteria);

    expect(result.passed).toBe(true);
    expect(result.actual).toBe('Hello World');
  });

  test('should fail exact match when content differs', () => {
    const validator = new ResponseValidator();
    const response = createMockResponse('Hello World');
    const criteria = createValidationCriteria('exact', 'Goodbye World');

    const result = validator.validate(response, criteria);

    expect(result.passed).toBe(false);
    expect(result.expected).toBe('Goodbye World');
    expect(result.actual).toBe('Hello World');
  });

  test('should validate pattern match with regex', () => {
    const validator = new ResponseValidator();
    const response = createMockResponse('Hello World 123');
    const criteria = createValidationCriteria('pattern', /\d+/);

    const result = validator.validate(response, criteria);

    expect(result.passed).toBe(true);
  });

  test('should fail pattern match when pattern does not match', () => {
    const validator = new ResponseValidator();
    const response = createMockResponse('Hello World');
    const criteria = createValidationCriteria('pattern', /\d+/);

    const result = validator.validate(response, criteria);

    expect(result.passed).toBe(false);
  });

  test('should validate semantic similarity above threshold', () => {
    const validator = new ResponseValidator();
    const response = createMockResponse('Hello there friend');
    const criteria = createValidationCriteria('semantic', 'Hello there buddy', 0.5);

    const result = validator.validate(response, criteria);

    expect(result.passed).toBe(true);
  });

  test('should fail semantic similarity below threshold', () => {
    const validator = new ResponseValidator();
    const response = createMockResponse('Completely different text');
    const criteria = createValidationCriteria('semantic', 'Hello World', 0.9);

    const result = validator.validate(response, criteria);

    expect(result.passed).toBe(false);
  });

  test('should include failure details in result', () => {
    const validator = new ResponseValidator();
    const response = createMockResponse('Actual');
    const criteria = createValidationCriteria('exact', 'Expected');

    const result = validator.validate(response, criteria);

    expect(result.passed).toBe(false);
    expect(result.expected).toBe('Expected');
    expect(result.actual).toBe('Actual');
    expect(result.message).toBeDefined();
  });

  test('should handle error responses', () => {
    const validator = new ResponseValidator();
    const error = new Error('Connection failed');
    const response = createMockResponse('', { error });
    const criteria = createValidationCriteria('exact', 'Hello');

    const result = validator.validate(response, criteria);

    expect(result.passed).toBe(false);
    expect(result.message).toContain('error');
  });

  test('should validate multiple criteria with validateAll', () => {
    const validator = new ResponseValidator();
    const response = createMockResponse('Hello World 123');
    const criteriaList = [
      createValidationCriteria('pattern', /Hello/),
      createValidationCriteria('pattern', /\d+/)
    ];

    const result = validator.validateAll(response, criteriaList);

    expect(result.passed).toBe(true);
  });

  test('should fail validateAll if any criteria fails', () => {
    const validator = new ResponseValidator();
    const response = createMockResponse('Hello World');
    const criteriaList = [
      createValidationCriteria('pattern', /Hello/),
      createValidationCriteria('pattern', /\d+/)
    ];

    const result = validator.validateAll(response, criteriaList);

    expect(result.passed).toBe(false);
    expect(result.details?.failedCount).toBe(1);
  });

  test('should pass validateAny if any criteria passes', () => {
    const validator = new ResponseValidator();
    const response = createMockResponse('Hello World');
    const criteriaList = [
      createValidationCriteria('pattern', /Hello/),
      createValidationCriteria('pattern', /\d+/)
    ];

    const result = validator.validateAny(response, criteriaList);

    expect(result.passed).toBe(true);
    expect(result.details?.passedCount).toBe(1);
  });
});
