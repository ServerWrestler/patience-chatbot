/**
 * Validation Analyzer - Applies validation rules to bot responses
 */

import { ParsedConversation, ConversationValidationResult, MessageValidationResult } from './types';
import { ValidationCriteria, BotResponse } from '../types';
import { ResponseValidator } from '../validation/ResponseValidator';

export class ValidationAnalyzer {
  private validator: ResponseValidator;

  constructor() {
    this.validator = new ResponseValidator();
  }

  /**
   * Validate a single conversation
   */
  validateConversation(
    conversation: ParsedConversation,
    rules: ValidationCriteria[]
  ): ConversationValidationResult {
    const validationDetails: MessageValidationResult[] = [];
    let passedValidations = 0;
    let failedValidations = 0;

    // Get bot messages
    const botMessages = conversation.messages.filter(msg => msg.sender === 'bot');

    for (let i = 0; i < botMessages.length; i++) {
      const message = botMessages[i];
      const messageIndex = conversation.messages.indexOf(message);

      // Create BotResponse from message
      const botResponse: BotResponse = {
        content: message.content,
        timestamp: message.timestamp,
        metadata: message.metadata
      };

      // Apply all validation rules
      const validationResults = rules.map(rule =>
        this.validator.validate(botResponse, rule)
      );

      const overallPassed = validationResults.every(r => r.passed);

      if (overallPassed) {
        passedValidations++;
      } else {
        failedValidations++;
      }

      validationDetails.push({
        messageIndex,
        content: message.content,
        validationResults,
        overallPassed
      });
    }

    return {
      conversationId: conversation.id,
      totalMessages: conversation.messages.length,
      botMessages: botMessages.length,
      validatedMessages: botMessages.length,
      passedValidations,
      failedValidations,
      validationDetails
    };
  }

  /**
   * Validate multiple conversations
   */
  validateConversations(
    conversations: ParsedConversation[],
    rules: ValidationCriteria[]
  ): ConversationValidationResult[] {
    return conversations.map(conv => this.validateConversation(conv, rules));
  }

  /**
   * Get validation summary across all conversations
   */
  getValidationSummary(results: ConversationValidationResult[]): {
    totalConversations: number;
    totalBotMessages: number;
    totalPassed: number;
    totalFailed: number;
    passRate: number;
  } {
    const totalConversations = results.length;
    const totalBotMessages = results.reduce((sum, r) => sum + r.botMessages, 0);
    const totalPassed = results.reduce((sum, r) => sum + r.passedValidations, 0);
    const totalFailed = results.reduce((sum, r) => sum + r.failedValidations, 0);
    const passRate = totalBotMessages > 0 ? totalPassed / totalBotMessages : 0;

    return {
      totalConversations,
      totalBotMessages,
      totalPassed,
      totalFailed,
      passRate
    };
  }
}
