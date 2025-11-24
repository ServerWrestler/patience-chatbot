/**
 * Pattern Detector - Identifies common patterns in failures and conversations
 */

import { ParsedConversation, ConversationValidationResult, DetectedPattern } from './types';

export class PatternDetector {
  /**
   * Detect patterns in conversations and validation results
   */
  detectPatterns(
    conversations: ParsedConversation[],
    validationResults: ConversationValidationResult[]
  ): DetectedPattern[] {
    const patterns: DetectedPattern[] = [];

    // Detect failure patterns
    const failurePatterns = this.detectFailurePatterns(validationResults);
    patterns.push(...failurePatterns);

    // Detect success patterns
    const successPatterns = this.detectSuccessPatterns(validationResults);
    patterns.push(...successPatterns);

    // Detect anomalies
    const anomalies = this.detectAnomalies(conversations);
    patterns.push(...anomalies);

    return patterns;
  }

  /**
   * Detect common failure patterns
   */
  private detectFailurePatterns(results: ConversationValidationResult[]): DetectedPattern[] {
    const failureMessages: string[] = [];

    // Collect all failed messages
    for (const result of results) {
      for (const detail of result.validationDetails) {
        if (!detail.overallPassed) {
          failureMessages.push(detail.content);
        }
      }
    }

    if (failureMessages.length === 0) {
      return [];
    }

    // Group similar failures
    const groups = this.groupSimilarMessages(failureMessages);
    const patterns: DetectedPattern[] = [];

    for (const [pattern, messages] of groups.entries()) {
      if (messages.length >= 2) { // Only report patterns that occur multiple times
        patterns.push({
          type: 'failure',
          pattern,
          frequency: messages.length,
          examples: messages.slice(0, 3), // Include up to 3 examples
          severity: this.calculateSeverity(messages.length, failureMessages.length),
          description: `Common failure pattern found in ${messages.length} messages`
        });
      }
    }

    return patterns.sort((a, b) => b.frequency - a.frequency);
  }

  /**
   * Detect success patterns
   */
  private detectSuccessPatterns(results: ConversationValidationResult[]): DetectedPattern[] {
    const successMessages: string[] = [];

    // Collect all successful messages
    for (const result of results) {
      for (const detail of result.validationDetails) {
        if (detail.overallPassed) {
          successMessages.push(detail.content);
        }
      }
    }

    if (successMessages.length === 0) {
      return [];
    }

    // Find common phrases in successful responses
    const commonPhrases = this.findCommonPhrases(successMessages);
    const patterns: DetectedPattern[] = [];

    for (const [phrase, count] of commonPhrases.entries()) {
      if (count >= 3) { // Report phrases that appear at least 3 times
        patterns.push({
          type: 'success',
          pattern: phrase,
          frequency: count,
          examples: successMessages.filter(m => m.includes(phrase)).slice(0, 3),
          description: `Common success phrase found in ${count} messages`
        });
      }
    }

    return patterns.sort((a, b) => b.frequency - a.frequency).slice(0, 5); // Top 5 success patterns
  }

  /**
   * Detect anomalies in conversations
   */
  private detectAnomalies(conversations: ParsedConversation[]): DetectedPattern[] {
    const patterns: DetectedPattern[] = [];

    // Detect very short conversations
    const shortConvs = conversations.filter(c => c.messages.length <= 2);
    if (shortConvs.length > conversations.length * 0.1) {
      patterns.push({
        type: 'anomaly',
        pattern: 'Very short conversations',
        frequency: shortConvs.length,
        examples: shortConvs.slice(0, 3).map(c => `${c.id}: ${c.messages.length} messages`),
        severity: 'medium',
        description: `${shortConvs.length} conversations have 2 or fewer messages`
      });
    }

    // Detect very long conversations
    const longConvs = conversations.filter(c => c.messages.length >= 20);
    if (longConvs.length > 0) {
      patterns.push({
        type: 'anomaly',
        pattern: 'Very long conversations',
        frequency: longConvs.length,
        examples: longConvs.slice(0, 3).map(c => `${c.id}: ${c.messages.length} messages`),
        severity: 'low',
        description: `${longConvs.length} conversations have 20 or more messages`
      });
    }

    // Detect conversations with no bot responses
    const noBotConvs = conversations.filter(c => 
      !c.messages.some(m => m.sender === 'bot')
    );
    if (noBotConvs.length > 0) {
      patterns.push({
        type: 'anomaly',
        pattern: 'No bot responses',
        frequency: noBotConvs.length,
        examples: noBotConvs.slice(0, 3).map(c => c.id),
        severity: 'high',
        description: `${noBotConvs.length} conversations have no bot responses`
      });
    }

    return patterns;
  }

  /**
   * Group similar messages by extracting key phrases
   */
  private groupSimilarMessages(messages: string[]): Map<string, string[]> {
    const groups = new Map<string, string[]>();

    for (const message of messages) {
      // Extract key phrase (first 50 chars or first sentence)
      const keyPhrase = this.extractKeyPhrase(message);
      
      if (!groups.has(keyPhrase)) {
        groups.set(keyPhrase, []);
      }
      groups.get(keyPhrase)!.push(message);
    }

    return groups;
  }

  /**
   * Extract key phrase from message
   */
  private extractKeyPhrase(message: string): string {
    // Take first sentence or first 50 characters
    const firstSentence = message.split(/[.!?]/)[0];
    const phrase = firstSentence.length <= 50 
      ? firstSentence 
      : message.substring(0, 50);
    
    return phrase.trim().toLowerCase();
  }

  /**
   * Find common phrases in messages
   */
  private findCommonPhrases(messages: string[]): Map<string, number> {
    const phrases = new Map<string, number>();

    for (const message of messages) {
      // Extract 3-5 word phrases
      const words = message.toLowerCase().split(/\s+/);
      
      for (let i = 0; i < words.length - 2; i++) {
        const phrase = words.slice(i, i + 3).join(' ');
        if (phrase.length >= 10) { // Only meaningful phrases
          phrases.set(phrase, (phrases.get(phrase) || 0) + 1);
        }
      }
    }

    return phrases;
  }

  /**
   * Calculate severity based on frequency
   */
  private calculateSeverity(frequency: number, total: number): 'low' | 'medium' | 'high' {
    const ratio = frequency / total;
    
    if (ratio >= 0.5) return 'high';
    if (ratio >= 0.2) return 'medium';
    return 'low';
  }
}
