"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ResponseParser = void 0;
/**
 * Response parser utilities for extracting content from BotResponse objects
 */
class ResponseParser {
    /**
     * Extract plain text content from a BotResponse
     * Handles various text encodings and formats
     */
    static extractText(response) {
        if (response.error) {
            return '';
        }
        const { content } = response;
        // If content is already a string, return it
        if (typeof content === 'string') {
            return content;
        }
        // If content is an object, try to extract text fields
        if (typeof content === 'object' && content !== null) {
            // Common text field names
            const textFields = ['text', 'message', 'content', 'response', 'reply', 'output'];
            for (const field of textFields) {
                if (field in content && typeof content[field] === 'string') {
                    return content[field];
                }
            }
            // If no text field found, stringify the object
            return JSON.stringify(content);
        }
        return String(content);
    }
    /**
     * Check if response contains text content
     */
    static hasTextContent(response) {
        if (response.error) {
            return false;
        }
        const text = this.extractText(response);
        return text.length > 0;
    }
    /**
     * Normalize text content (trim whitespace, normalize line endings)
     */
    static normalizeText(text) {
        return text
            .trim()
            .replace(/\r\n/g, '\n')
            .replace(/\r/g, '\n');
    }
    /**
     * Parse structured data from response content
     * Attempts to parse JSON if content is a string
     */
    static parseStructuredData(response) {
        if (response.error) {
            throw new Error(`Cannot parse structured data from error response: ${response.error.message}`);
        }
        const { content } = response;
        // If content is already an object, return it
        if (typeof content === 'object' && content !== null) {
            return content;
        }
        // If content is a string, try to parse as JSON
        if (typeof content === 'string') {
            try {
                return JSON.parse(content);
            }
            catch (error) {
                throw new Error(`Failed to parse response content as JSON: ${error instanceof Error ? error.message : 'Unknown error'}`);
            }
        }
        throw new Error(`Cannot parse structured data from content type: ${typeof content}`);
    }
    /**
     * Extract a specific field from structured response data
     * Supports nested object paths using dot notation (e.g., "user.name")
     */
    static extractField(response, fieldPath) {
        const data = this.parseStructuredData(response);
        const parts = fieldPath.split('.');
        let current = data;
        for (const part of parts) {
            if (current === null || current === undefined) {
                return undefined;
            }
            if (typeof current === 'object' && part in current) {
                current = current[part];
            }
            else {
                return undefined;
            }
        }
        return current;
    }
    /**
     * Check if response contains structured data
     */
    static hasStructuredData(response) {
        if (response.error) {
            return false;
        }
        const { content } = response;
        // Already an object
        if (typeof content === 'object' && content !== null) {
            return true;
        }
        // Try to parse as JSON
        if (typeof content === 'string') {
            try {
                JSON.parse(content);
                return true;
            }
            catch {
                return false;
            }
        }
        return false;
    }
    /**
     * Extract multiple fields from structured response data
     */
    static extractFields(response, fieldPaths) {
        const result = {};
        for (const path of fieldPaths) {
            result[path] = this.extractField(response, path);
        }
        return result;
    }
    /**
     * Check if response contains an error
     */
    static isErrorResponse(response) {
        return response.error !== undefined;
    }
    /**
     * Extract error message from response
     */
    static getErrorMessage(response) {
        if (!response.error) {
            return null;
        }
        return response.error.message;
    }
    /**
     * Create a summary of the response for logging/reporting
     */
    static summarizeResponse(response) {
        if (response.error) {
            return `Error: ${response.error.message}`;
        }
        const text = this.extractText(response);
        const maxLength = 100;
        if (text.length <= maxLength) {
            return text;
        }
        return text.substring(0, maxLength) + '...';
    }
    /**
     * Check if response is valid (has content and no error)
     */
    static isValidResponse(response) {
        return !response.error && ((typeof response.content === 'string' && response.content.length > 0) ||
            (typeof response.content === 'object' && response.content !== null));
    }
    /**
     * Safely parse structured data with error detection
     * Returns an object with success flag and either data or error
     */
    static safeParseStructuredData(response) {
        try {
            const data = this.parseStructuredData(response);
            return { success: true, data };
        }
        catch (error) {
            return {
                success: false,
                error: error instanceof Error ? error : new Error('Unknown parsing error')
            };
        }
    }
    /**
     * Safely extract field with error detection
     */
    static safeExtractField(response, fieldPath) {
        try {
            const value = this.extractField(response, fieldPath);
            return { success: true, value };
        }
        catch (error) {
            return {
                success: false,
                error: error instanceof Error ? error : new Error('Unknown extraction error')
            };
        }
    }
    /**
     * Detect if parsing failed for a response
     * This checks if the response has an error or if parsing would fail
     */
    static hasParseFailure(response) {
        if (response.error) {
            return true;
        }
        // Try to parse and see if it fails
        const result = this.safeParseStructuredData(response);
        return !result.success;
    }
    /**
     * Get parse failure details
     */
    static getParseFailureDetails(response) {
        if (response.error) {
            return {
                failed: true,
                reason: `Response contains error: ${response.error.message}`,
                originalContent: response.content
            };
        }
        const result = this.safeParseStructuredData(response);
        if (!result.success) {
            return {
                failed: true,
                reason: result.error?.message || 'Unknown parse failure',
                originalContent: response.content
            };
        }
        return { failed: false };
    }
}
exports.ResponseParser = ResponseParser;
//# sourceMappingURL=ResponseParser.js.map