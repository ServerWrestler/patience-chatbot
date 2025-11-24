/**
 * Text Log Parser - Parses plain text formatted conversation logs
 */

import { BaseFormatParser } from './FormatParser';
import { RawLogData, ParsedConversation, ConversationMessage } from '../types';
import { ValidationResult } from '../../types';

export class TextLogParser extends BaseFormatParser {
  // Common text log patterns
  private readonly patterns = {
    // [2025-01-15 10:30:00] User: Hello
    timestampSenderContent: /^\[([^\]]+)\]\s*(\w+):\s*(.+)$/,
    // 2025-01-15 10:30:00 | User | Hello
    pipeSeparated: /^([^\|]+)\|([^\|]+)\|(.+)$/,
    // User: Hello
    senderContent: /^(\w+):\s*(.+)$/,
    // === Conversation: conv-123 ===
    conversationMarker: /^===\s*Conversation:\s*(.+)\s*===$/,
    // === End Conversation ===
    endMarker: /^===\s*End\s+Conversation\s*===$/i
  };

  /**
   * Parse text log data into conversations
   */
  async parse(data: RawLogData): Promise<ParsedConversation[]> {
    if (typeof data.content !== 'string') {
      throw new Error('Text content must be a string');
    }

    const lines = data.content.split('\n');
    const conversations: ParsedConversation[] = [];
    
    let currentConversation: ConversationMessage[] = [];
    let currentConversationId: string | null = null;
    let conversationIndex = 0;

    for (let i = 0; i < lines.length; i++) {
      const line = lines[i].trim();
      
      if (line.length === 0) {
        continue;
      }

      // Check for conversation marker
      const markerMatch = line.match(this.patterns.conversationMarker);
      if (markerMatch) {
        // Save previous conversation if exists
        if (currentConversation.length > 0) {
          conversations.push(this.createConversation(
            currentConversationId || this.generateConversationId(conversationIndex++),
            currentConversation
          ));
        }
        
        // Start new conversation
        currentConversationId = markerMatch[1].trim();
        currentConversation = [];
        continue;
      }

      // Check for end marker
      if (this.patterns.endMarker.test(line)) {
        if (currentConversation.length > 0) {
          conversations.push(this.createConversation(
            currentConversationId || this.generateConversationId(conversationIndex++),
            currentConversation
          ));
          currentConversation = [];
          currentConversationId = null;
        }
        continue;
      }

      // Skip metadata lines (User ID:, Start:, etc.)
      if (line.includes(':') && !line.match(/^\[/)) {
        const beforeColon = line.split(':')[0].trim();
        if (beforeColon.length < 20 && !beforeColon.includes(' ')) {
          // Likely a metadata line like "User ID:" or "Start:"
          continue;
        }
      }

      // Try to parse message
      const message = this.parseMessage(line);
      if (message) {
        currentConversation.push(message);
      }
    }

    // Add final conversation if exists
    if (currentConversation.length > 0) {
      conversations.push(this.createConversation(
        currentConversationId || this.generateConversationId(conversationIndex),
        currentConversation
      ));
    }

    return conversations;
  }

  /**
   * Parse a single message line
   */
  private parseMessage(line: string): ConversationMessage | null {
    // Try timestamp + sender + content pattern
    let match = line.match(this.patterns.timestampSenderContent);
    if (match) {
      return {
        sender: this.normalizeSender(match[2]),
        content: match[3].trim(),
        timestamp: this.parseTimestamp(match[1]),
        metadata: {}
      };
    }

    // Try pipe-separated pattern
    match = line.match(this.patterns.pipeSeparated);
    if (match) {
      return {
        sender: this.normalizeSender(match[2].trim()),
        content: match[3].trim(),
        timestamp: this.parseTimestamp(match[1].trim()),
        metadata: {}
      };
    }

    // Try sender + content pattern (no timestamp)
    match = line.match(this.patterns.senderContent);
    if (match) {
      return {
        sender: this.normalizeSender(match[1]),
        content: match[2].trim(),
        timestamp: new Date(),
        metadata: {}
      };
    }

    return null;
  }

  /**
   * Parse timestamp that might be time-only or full date
   */
  private parseTimestamp(timestampStr: string): Date {
    // If it's just time (HH:MM:SS), use today's date
    if (/^\d{2}:\d{2}:\d{2}$/.test(timestampStr)) {
      const today = new Date();
      const [hours, minutes, seconds] = timestampStr.split(':').map(Number);
      today.setHours(hours, minutes, seconds, 0);
      return today;
    }

    // Otherwise try to parse as full date
    return this.parseDate(timestampStr);
  }

  /**
   * Create a parsed conversation from messages
   */
  private createConversation(
    id: string,
    messages: ConversationMessage[]
  ): ParsedConversation {
    return {
      id,
      messages,
      metadata: {
        startTime: messages[0]?.timestamp,
        endTime: messages[messages.length - 1]?.timestamp,
        source: 'text'
      }
    };
  }

  /**
   * Validate text log structure
   */
  validate(data: RawLogData): ValidationResult {
    if (typeof data.content !== 'string') {
      return this.createValidationError('Text content must be a string');
    }

    const lines = data.content.split('\n').filter(line => line.trim().length > 0);

    if (lines.length === 0) {
      return this.createValidationError('Text log is empty');
    }

    // Check if at least one line matches a known pattern
    let foundValidLine = false;
    for (const line of lines.slice(0, Math.min(10, lines.length))) {
      if (this.parseMessage(line) !== null) {
        foundValidLine = true;
        break;
      }
    }

    if (!foundValidLine) {
      return this.createValidationError(
        'No recognizable message patterns found in text log. ' +
        'Expected formats: "[timestamp] Sender: content" or "Sender: content"'
      );
    }

    return this.createValidationSuccess();
  }

  getFormat(): string {
    return 'text';
  }
}
