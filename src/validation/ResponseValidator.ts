import { BotResponse, ValidationCriteria, ValidationResult, ResponseParser } from '../types';

/**
 * Response validation class
 */
export class ResponseValidator {
  /**
   * Validate a bot response against criteria
   * Returns a ValidationResult with pass/fail status and details
   */
  validate(response: BotResponse, criteria: ValidationCriteria): ValidationResult {
    // If response has an error, validation fails
    if (response.error) {
      return {
        passed: false,
        expected: this.getExpectedString(criteria),
        actual: `Error: ${response.error.message}`,
        message: `Response contains error: ${response.error.message}`
      };
    }

    // Extract text content from response
    const actualText = ResponseParser.extractText(response);

    // Validate based on criteria type
    try {
      switch (criteria.type) {
        case 'exact':
          return this.validateExact(actualText, criteria);
        case 'pattern':
          return this.validatePattern(actualText, criteria);
        case 'semantic':
          return this.validateSemantic(actualText, criteria);
        case 'custom':
          return this.validateCustom(response, criteria);
        default:
          return {
            passed: false,
            actual: actualText,
            message: `Unknown validation type: ${criteria.type}`
          };
      }
    } catch (error) {
      return {
        passed: false,
        actual: actualText,
        message: `Validation error: ${error instanceof Error ? error.message : 'Unknown error'}`
      };
    }
  }

  /**
   * Validate exact match
   */
  private validateExact(actual: string, criteria: ValidationCriteria): ValidationResult {
    const expected = String(criteria.expected);
    const passed = this.validateExactMatch(actual, expected);

    return {
      passed,
      expected,
      actual,
      message: passed ? 'Exact match successful' : 'Response does not match expected value exactly'
    };
  }

  /**
   * Validate pattern match
   */
  private validatePattern(actual: string, criteria: ValidationCriteria): ValidationResult {
    const pattern = criteria.expected instanceof RegExp 
      ? criteria.expected 
      : new RegExp(String(criteria.expected), 'i'); // Case-insensitive by default
    
    const passed = this.validatePatternMatch(actual, pattern);

    return {
      passed,
      expected: pattern.toString(),
      actual,
      message: passed ? 'Pattern match successful' : 'Response does not match expected pattern'
    };
  }

  /**
   * Validate semantic similarity
   */
  private validateSemantic(actual: string, criteria: ValidationCriteria): ValidationResult {
    const expected = String(criteria.expected);
    const threshold = criteria.threshold || 0.7;
    const passed = this.validateSemanticSimilarity(actual, expected, threshold);

    return {
      passed,
      expected,
      actual,
      message: passed 
        ? `Semantic similarity above threshold (${threshold})` 
        : `Semantic similarity below threshold (${threshold})`
    };
  }

  /**
   * Validate using custom validator
   */
  private validateCustom(response: BotResponse, criteria: ValidationCriteria): ValidationResult {
    if (typeof criteria.expected === 'function') {
      return criteria.expected(response);
    }

    return {
      passed: false,
      actual: ResponseParser.extractText(response),
      message: 'Custom validator is not a function'
    };
  }

  /**
   * Get expected value as string for display
   */
  private getExpectedString(criteria: ValidationCriteria): string {
    if (criteria.expected instanceof RegExp) {
      return criteria.expected.toString();
    }
    if (typeof criteria.expected === 'function') {
      return 'Custom validation function';
    }
    return String(criteria.expected);
  }

  /**
   * Validate exact string match
   * Compares response and expected strings for exact equality
   */
  validateExactMatch(response: string, expected: string): boolean {
    return response === expected;
  }

  /**
   * Validate pattern match using regex
   * Tests if the response matches the given regular expression
   */
  validatePatternMatch(response: string, pattern: RegExp): boolean {
    return pattern.test(response);
  }

  /**
   * Validate semantic similarity
   * Uses simple similarity metrics (Levenshtein distance and word overlap)
   */
  validateSemanticSimilarity(response: string, expected: string, threshold: number): boolean {
    // Normalize strings
    const normalizedResponse = response.toLowerCase().trim();
    const normalizedExpected = expected.toLowerCase().trim();

    // Calculate multiple similarity metrics
    const levenshteinSimilarity = this.calculateLevenshteinSimilarity(normalizedResponse, normalizedExpected);
    const wordOverlapSimilarity = this.calculateWordOverlapSimilarity(normalizedResponse, normalizedExpected);

    // Use average of both metrics
    const averageSimilarity = (levenshteinSimilarity + wordOverlapSimilarity) / 2;

    return averageSimilarity >= threshold;
  }

  /**
   * Calculate Levenshtein distance-based similarity
   * Returns a value between 0 and 1, where 1 is identical
   */
  private calculateLevenshteinSimilarity(str1: string, str2: string): number {
    const distance = this.levenshteinDistance(str1, str2);
    const maxLength = Math.max(str1.length, str2.length);
    
    if (maxLength === 0) {
      return 1;
    }

    return 1 - (distance / maxLength);
  }

  /**
   * Calculate Levenshtein distance between two strings
   */
  private levenshteinDistance(str1: string, str2: string): number {
    const len1 = str1.length;
    const len2 = str2.length;
    const matrix: number[][] = [];

    // Initialize matrix
    for (let i = 0; i <= len1; i++) {
      matrix[i] = [i];
    }
    for (let j = 0; j <= len2; j++) {
      matrix[0][j] = j;
    }

    // Fill matrix
    for (let i = 1; i <= len1; i++) {
      for (let j = 1; j <= len2; j++) {
        const cost = str1[i - 1] === str2[j - 1] ? 0 : 1;
        matrix[i][j] = Math.min(
          matrix[i - 1][j] + 1,      // deletion
          matrix[i][j - 1] + 1,      // insertion
          matrix[i - 1][j - 1] + cost // substitution
        );
      }
    }

    return matrix[len1][len2];
  }

  /**
   * Calculate word overlap similarity
   * Returns a value between 0 and 1 based on common words
   */
  private calculateWordOverlapSimilarity(str1: string, str2: string): number {
    const words1 = new Set(str1.split(/\s+/).filter(w => w.length > 0));
    const words2 = new Set(str2.split(/\s+/).filter(w => w.length > 0));

    if (words1.size === 0 && words2.size === 0) {
      return 1;
    }

    if (words1.size === 0 || words2.size === 0) {
      return 0;
    }

    // Count common words
    let commonWords = 0;
    for (const word of words1) {
      if (words2.has(word)) {
        commonWords++;
      }
    }

    // Calculate Jaccard similarity
    const totalWords = words1.size + words2.size - commonWords;
    return commonWords / totalWords;
  }

  /**
   * Validate multiple responses against multiple criteria
   * Returns an array of validation results
   */
  validateMultiple(
    responses: BotResponse[],
    criteriaList: ValidationCriteria[]
  ): ValidationResult[] {
    const results: ValidationResult[] = [];

    for (let i = 0; i < Math.min(responses.length, criteriaList.length); i++) {
      results.push(this.validate(responses[i], criteriaList[i]));
    }

    return results;
  }

  /**
   * Validate a response against multiple criteria
   * Returns true only if all criteria pass
   */
  validateAll(response: BotResponse, criteriaList: ValidationCriteria[]): ValidationResult {
    const results = criteriaList.map(criteria => this.validate(response, criteria));
    const allPassed = results.every(result => result.passed);

    const failedResults = results.filter(result => !result.passed);

    return {
      passed: allPassed,
      actual: ResponseParser.extractText(response),
      message: allPassed
        ? 'All validation criteria passed'
        : `${failedResults.length} validation(s) failed`,
      details: {
        results,
        failedCount: failedResults.length,
        totalCount: results.length
      }
    };
  }

  /**
   * Validate a response against multiple criteria
   * Returns true if any criteria passes
   */
  validateAny(response: BotResponse, criteriaList: ValidationCriteria[]): ValidationResult {
    const results = criteriaList.map(criteria => this.validate(response, criteria));
    const anyPassed = results.some(result => result.passed);

    const passedResults = results.filter(result => result.passed);

    return {
      passed: anyPassed,
      actual: ResponseParser.extractText(response),
      message: anyPassed
        ? `${passedResults.length} validation(s) passed`
        : 'All validations failed',
      details: {
        results,
        passedCount: passedResults.length,
        totalCount: results.length
      }
    };
  }

  /**
   * Create a detailed failure report for a validation result
   */
  createFailureReport(result: ValidationResult): string {
    if (result.passed) {
      return 'Validation passed';
    }

    const lines: string[] = [
      'Validation Failed',
      '=================',
      ''
    ];

    if (result.expected) {
      lines.push(`Expected: ${result.expected}`);
    }

    lines.push(`Actual: ${result.actual}`);

    if (result.message) {
      lines.push('');
      lines.push(`Reason: ${result.message}`);
    }

    if (result.details) {
      lines.push('');
      lines.push('Details:');
      lines.push(JSON.stringify(result.details, null, 2));
    }

    return lines.join('\n');
  }

  /**
   * Get failure summary from multiple validation results
   */
  getFailureSummary(results: ValidationResult[]): {
    totalCount: number;
    failedCount: number;
    passedCount: number;
    failures: Array<{ index: number; result: ValidationResult }>;
  } {
    const failures: Array<{ index: number; result: ValidationResult }> = [];

    results.forEach((result, index) => {
      if (!result.passed) {
        failures.push({ index, result });
      }
    });

    return {
      totalCount: results.length,
      failedCount: failures.length,
      passedCount: results.length - failures.length,
      failures
    };
  }

  /**
   * Check if validation result indicates a failure
   */
  static isFailure(result: ValidationResult): boolean {
    return !result.passed;
  }

  /**
   * Extract failure details from validation result
   */
  static getFailureDetails(result: ValidationResult): {
    expected?: string;
    actual: string;
    message?: string;
  } {
    return {
      expected: result.expected,
      actual: result.actual,
      message: result.message
    };
  }
}
