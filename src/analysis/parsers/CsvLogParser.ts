/**
 * CSV Log Parser - Parses CSV formatted conversation logs
 */

import { BaseFormatParser } from './FormatParser';
import { RawLogData, ParsedConversation, ConversationMessage } from '../types';
import { ValidationResult } from '../../types';

export class CsvLogParser extends BaseFormatParser {
  /**
   * Parse CSV log data into conversations
   */
  async parse(data: RawLogData): Promise<ParsedConversation[]> {
    if (typeof data.content !== 'string') {
      throw new Error('CSV content must be a string');
    }

    const lines = data.content.split('\n').filter(line => line.trim().length > 0);
    
    if (lines.length < 2) {
      throw new Error('CSV must have at least a header row and one data row');
    }

    // Parse header
    const header = this.parseCsvLine(lines[0]);
    const columnMap = this.mapColumns(header);

    // Group messages by conversation
    const conversationMap = new Map<string, ConversationMessage[]>();

    for (let i = 1; i < lines.length; i++) {
      try {
        const values = this.parseCsvLine(lines[i]);
        
        if (values.length !== header.length) {
          console.warn(`Line ${i + 1}: Column count mismatch, skipping`);
          continue;
        }

        const conversationId = values[columnMap.conversationId] || `conv-${i}`;
        const sender = this.normalizeSender(values[columnMap.sender] || 'user');
        const content = values[columnMap.content] || '';
        const timestamp = values[columnMap.timestamp] 
          ? this.parseDate(values[columnMap.timestamp])
          : new Date();

        if (!conversationMap.has(conversationId)) {
          conversationMap.set(conversationId, []);
        }

        conversationMap.get(conversationId)!.push({
          sender,
          content,
          timestamp,
          metadata: {
            userId: values[columnMap.userId]
          }
        });
      } catch (error) {
        console.warn(`Failed to parse line ${i + 1}:`, error);
      }
    }

    // Convert map to array of conversations
    const conversations: ParsedConversation[] = [];
    let index = 0;

    for (const [id, messages] of conversationMap.entries()) {
      // Sort messages by timestamp
      messages.sort((a, b) => a.timestamp.getTime() - b.timestamp.getTime());

      conversations.push({
        id,
        messages,
        metadata: {
          startTime: messages[0]?.timestamp,
          endTime: messages[messages.length - 1]?.timestamp,
          userId: messages[0]?.metadata?.userId,
          source: 'csv'
        }
      });
      index++;
    }

    return conversations;
  }

  /**
   * Parse a CSV line handling quoted fields
   */
  private parseCsvLine(line: string): string[] {
    const result: string[] = [];
    let current = '';
    let inQuotes = false;

    for (let i = 0; i < line.length; i++) {
      const char = line[i];

      if (char === '"') {
        // Handle escaped quotes
        if (inQuotes && line[i + 1] === '"') {
          current += '"';
          i++; // Skip next quote
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char === ',' && !inQuotes) {
        result.push(current.trim());
        current = '';
      } else {
        current += char;
      }
    }

    // Add last field
    result.push(current.trim());

    return result;
  }

  /**
   * Map column names to indices
   */
  private mapColumns(header: string[]): {
    conversationId: number;
    timestamp: number;
    sender: number;
    content: number;
    userId: number;
  } {
    const map = {
      conversationId: -1,
      timestamp: -1,
      sender: -1,
      content: -1,
      userId: -1
    };

    for (let i = 0; i < header.length; i++) {
      const col = header[i].toLowerCase().trim();

      if (col.includes('conversation') && col.includes('id')) {
        map.conversationId = i;
      } else if (col.includes('timestamp') || col.includes('time') || col.includes('date')) {
        map.timestamp = i;
      } else if (col.includes('sender') || col.includes('role') || col.includes('from')) {
        map.sender = i;
      } else if (col.includes('content') || col.includes('message') || col.includes('text')) {
        map.content = i;
      } else if (col.includes('user') && col.includes('id')) {
        map.userId = i;
      }
    }

    // Validate required columns
    if (map.sender === -1) {
      throw new Error('CSV must have a sender/role column');
    }
    if (map.content === -1) {
      throw new Error('CSV must have a content/message column');
    }

    return map;
  }

  /**
   * Validate CSV structure
   */
  validate(data: RawLogData): ValidationResult {
    if (typeof data.content !== 'string') {
      return this.createValidationError('CSV content must be a string');
    }

    const lines = data.content.split('\n').filter(line => line.trim().length > 0);

    if (lines.length < 2) {
      return this.createValidationError('CSV must have at least a header row and one data row');
    }

    // Check header
    const header = this.parseCsvLine(lines[0]);
    
    try {
      this.mapColumns(header);
    } catch (error) {
      return this.createValidationError(
        error instanceof Error ? error.message : 'Invalid CSV structure'
      );
    }

    return this.createValidationSuccess();
  }

  getFormat(): string {
    return 'csv';
  }
}
