import { BotResponse, ValidationCriteria, ValidationResult } from '../types';
/**
 * Response validation class
 */
export declare class ResponseValidator {
    /**
     * Validate a bot response against criteria
     * Returns a ValidationResult with pass/fail status and details
     */
    validate(response: BotResponse, criteria: ValidationCriteria): ValidationResult;
    /**
     * Validate exact match
     */
    private validateExact;
    /**
     * Validate pattern match
     */
    private validatePattern;
    /**
     * Validate semantic similarity
     */
    private validateSemantic;
    /**
     * Validate using custom validator
     */
    private validateCustom;
    /**
     * Get expected value as string for display
     */
    private getExpectedString;
    /**
     * Validate exact string match
     * Compares response and expected strings for exact equality
     */
    validateExactMatch(response: string, expected: string): boolean;
    /**
     * Validate pattern match using regex
     * Tests if the response matches the given regular expression
     */
    validatePatternMatch(response: string, pattern: RegExp): boolean;
    /**
     * Validate semantic similarity
     * Uses simple similarity metrics (Levenshtein distance and word overlap)
     */
    validateSemanticSimilarity(response: string, expected: string, threshold: number): boolean;
    /**
     * Calculate Levenshtein distance-based similarity
     * Returns a value between 0 and 1, where 1 is identical
     */
    private calculateLevenshteinSimilarity;
    /**
     * Calculate Levenshtein distance between two strings
     */
    private levenshteinDistance;
    /**
     * Calculate word overlap similarity
     * Returns a value between 0 and 1 based on common words
     */
    private calculateWordOverlapSimilarity;
    /**
     * Validate multiple responses against multiple criteria
     * Returns an array of validation results
     */
    validateMultiple(responses: BotResponse[], criteriaList: ValidationCriteria[]): ValidationResult[];
    /**
     * Validate a response against multiple criteria
     * Returns true only if all criteria pass
     */
    validateAll(response: BotResponse, criteriaList: ValidationCriteria[]): ValidationResult;
    /**
     * Validate a response against multiple criteria
     * Returns true if any criteria passes
     */
    validateAny(response: BotResponse, criteriaList: ValidationCriteria[]): ValidationResult;
    /**
     * Create a detailed failure report for a validation result
     */
    createFailureReport(result: ValidationResult): string;
    /**
     * Get failure summary from multiple validation results
     */
    getFailureSummary(results: ValidationResult[]): {
        totalCount: number;
        failedCount: number;
        passedCount: number;
        failures: Array<{
            index: number;
            result: ValidationResult;
        }>;
    };
    /**
     * Check if validation result indicates a failure
     */
    static isFailure(result: ValidationResult): boolean;
    /**
     * Extract failure details from validation result
     */
    static getFailureDetails(result: ValidationResult): {
        expected?: string;
        actual: string;
        message?: string;
    };
}
//# sourceMappingURL=ResponseValidator.d.ts.map