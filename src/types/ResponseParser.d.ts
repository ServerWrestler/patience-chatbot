import { BotResponse } from './index';
/**
 * Response parser utilities for extracting content from BotResponse objects
 */
export declare class ResponseParser {
    /**
     * Extract plain text content from a BotResponse
     * Handles various text encodings and formats
     */
    static extractText(response: BotResponse): string;
    /**
     * Check if response contains text content
     */
    static hasTextContent(response: BotResponse): boolean;
    /**
     * Normalize text content (trim whitespace, normalize line endings)
     */
    static normalizeText(text: string): string;
    /**
     * Parse structured data from response content
     * Attempts to parse JSON if content is a string
     */
    static parseStructuredData(response: BotResponse): any;
    /**
     * Extract a specific field from structured response data
     * Supports nested object paths using dot notation (e.g., "user.name")
     */
    static extractField(response: BotResponse, fieldPath: string): any;
    /**
     * Check if response contains structured data
     */
    static hasStructuredData(response: BotResponse): boolean;
    /**
     * Extract multiple fields from structured response data
     */
    static extractFields(response: BotResponse, fieldPaths: string[]): Record<string, any>;
    /**
     * Check if response contains an error
     */
    static isErrorResponse(response: BotResponse): boolean;
    /**
     * Extract error message from response
     */
    static getErrorMessage(response: BotResponse): string | null;
    /**
     * Create a summary of the response for logging/reporting
     */
    static summarizeResponse(response: BotResponse): string;
    /**
     * Check if response is valid (has content and no error)
     */
    static isValidResponse(response: BotResponse): boolean;
    /**
     * Safely parse structured data with error detection
     * Returns an object with success flag and either data or error
     */
    static safeParseStructuredData(response: BotResponse): {
        success: boolean;
        data?: any;
        error?: Error;
    };
    /**
     * Safely extract field with error detection
     */
    static safeExtractField(response: BotResponse, fieldPath: string): {
        success: boolean;
        value?: any;
        error?: Error;
    };
    /**
     * Detect if parsing failed for a response
     * This checks if the response has an error or if parsing would fail
     */
    static hasParseFailure(response: BotResponse): boolean;
    /**
     * Get parse failure details
     */
    static getParseFailureDetails(response: BotResponse): {
        failed: boolean;
        reason?: string;
        originalContent?: string | object;
    };
}
//# sourceMappingURL=ResponseParser.d.ts.map