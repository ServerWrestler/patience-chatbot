/**
 * Base interface for format parsers
 */

import { RawLogData, ParsedConversation } from '../types';
import { ValidationResult } from '../../types';

export interface FormatParser {
  /**
   * Parse raw log data into structured conversations
   */
  parse(data: RawLogData): Promise<ParsedConversation[]>;

  /**
   * Validate that the raw data is in the expected format
   */
  validate(data: RawLogData): ValidationResult;

  /**
   * Get the format this parser handles
   */
  getFormat(): string;
}

/**
 * Base class for format parsers with common functionality
 */
export abstract class BaseFormatParser implements FormatParser {
  abstract parse(data: RawLogData): Promise<ParsedConversation[]>;
  abstract validate(data: RawLogData): ValidationResult;
  abstract getFormat(): string;

  /**
   * Generate a unique conversation ID
   */
  protected generateConversationId(index: number, prefix: string = 'conv'): string {
    return `${prefix}-${Date.now()}-${index}`;
  }

  /**
   * Parse a date string into a Date object
   */
  protected parseDate(dateStr: string): Date {
    const date = new Date(dateStr);
    if (isNaN(date.getTime())) {
      throw new Error(`Invalid date format: ${dateStr}`);
    }
    return date;
  }

  /**
   * Normalize sender to 'user' or 'bot'
   */
  protected normalizeSender(sender: string): 'user' | 'bot' {
    const normalized = sender.toLowerCase().trim();
    
    if (normalized === 'user' || normalized === 'human' || normalized === 'customer') {
      return 'user';
    }
    
    if (normalized === 'bot' || normalized === 'assistant' || normalized === 'agent') {
      return 'bot';
    }

    // Default to user if unclear
    return 'user';
  }

  /**
   * Create a validation error result
   */
  protected createValidationError(message: string, details?: any): ValidationResult {
    return {
      passed: false,
      actual: 'Invalid format',
      message,
      details
    };
  }

  /**
   * Create a validation success result
   */
  protected createValidationSuccess(): ValidationResult {
    return {
      passed: true,
      actual: 'Valid format',
      message: 'Format validation passed'
    };
  }
}
