/**
 * JSON Log Parser - Parses JSON formatted conversation logs
 */

import { BaseFormatParser } from './FormatParser';
import { RawLogData, ParsedConversation, ConversationMessage } from '../types';
import { ValidationResult } from '../../types';

export class JsonLogParser extends BaseFormatParser {
  /**
   * Parse JSON log data into conversations
   */
  async parse(data: RawLogData): Promise<ParsedConversation[]> {
    if (typeof data.content === 'string') {
      throw new Error('Expected parsed JSON object, got string');
    }

    const jsonData = data.content as any;
    const conversations: ParsedConversation[] = [];

    // Support different JSON structures
    let conversationArray: any[];

    if (Array.isArray(jsonData)) {
      // Direct array of conversations
      conversationArray = jsonData;
    } else if (jsonData.conversations && Array.isArray(jsonData.conversations)) {
      // Wrapped in conversations property
      conversationArray = jsonData.conversations;
    } else if (jsonData.data && Array.isArray(jsonData.data)) {
      // Wrapped in data property
      conversationArray = jsonData.data;
    } else {
      throw new Error('Unable to find conversation array in JSON structure');
    }

    for (let i = 0; i < conversationArray.length; i++) {
      const conv = conversationArray[i];
      
      try {
        const parsed = this.parseConversation(conv, i);
        conversations.push(parsed);
      } catch (error) {
        console.warn(`Failed to parse conversation at index ${i}:`, error);
        // Continue with other conversations
      }
    }

    return conversations;
  }

  /**
   * Parse a single conversation object
   */
  private parseConversation(conv: any, index: number): ParsedConversation {
    // Extract messages
    const messages: ConversationMessage[] = [];
    const messageArray = conv.messages || conv.turns || conv.exchanges || [];

    if (!Array.isArray(messageArray)) {
      throw new Error('Messages must be an array');
    }

    for (const msg of messageArray) {
      messages.push({
        sender: this.normalizeSender(msg.sender || msg.role || msg.from || 'user'),
        content: msg.content || msg.text || msg.message || '',
        timestamp: msg.timestamp ? this.parseDate(msg.timestamp) : new Date(),
        metadata: msg.metadata || {}
      });
    }

    // Build parsed conversation
    return {
      id: conv.id || conv.conversationId || this.generateConversationId(index),
      messages,
      metadata: {
        startTime: conv.startTime ? this.parseDate(conv.startTime) : undefined,
        endTime: conv.endTime ? this.parseDate(conv.endTime) : undefined,
        userId: conv.userId || conv.user_id || conv.customerId,
        sessionId: conv.sessionId || conv.session_id,
        source: conv.source || 'json'
      }
    };
  }

  /**
   * Validate JSON structure
   */
  validate(data: RawLogData): ValidationResult {
    if (typeof data.content === 'string') {
      return this.createValidationError('Content should be parsed JSON object, not string');
    }

    const jsonData = data.content as any;

    // Check for conversation array
    let conversationArray: any[];

    if (Array.isArray(jsonData)) {
      conversationArray = jsonData;
    } else if (jsonData.conversations && Array.isArray(jsonData.conversations)) {
      conversationArray = jsonData.conversations;
    } else if (jsonData.data && Array.isArray(jsonData.data)) {
      conversationArray = jsonData.data;
    } else {
      return this.createValidationError(
        'JSON must contain an array of conversations or have a "conversations" or "data" property'
      );
    }

    if (conversationArray.length === 0) {
      return this.createValidationError('Conversation array is empty');
    }

    // Validate first conversation structure
    const firstConv = conversationArray[0];
    
    if (!firstConv.messages && !firstConv.turns && !firstConv.exchanges) {
      return this.createValidationError(
        'Conversations must have a "messages", "turns", or "exchanges" property'
      );
    }

    return this.createValidationSuccess();
  }

  getFormat(): string {
    return 'json';
  }
}
