/**
 * Context Analyzer - Analyzes context retention in multi-turn conversations
 */

import { ParsedConversation, ContextAnalysisResult, ContextBreak } from './types';

export class ContextAnalyzer {
  /**
   * Analyze context retention in a conversation
   */
  analyzeContext(conversation: ParsedConversation): ContextAnalysisResult {
    const hasMultipleTurns = conversation.messages.length >= 4; // At least 2 exchanges

    if (!hasMultipleTurns) {
      return {
        conversationId: conversation.id,
        hasMultipleTurns: false,
        contextRetentionScore: 0,
        contextBreaks: [],
        overallQuality: 'poor'
      };
    }

    const contextBreaks = this.detectContextBreaks(conversation);
    const contextRetentionScore = this.calculateContextScore(conversation, contextBreaks);
    const overallQuality = this.determineQuality(contextRetentionScore);

    return {
      conversationId: conversation.id,
      hasMultipleTurns,
      contextRetentionScore,
      contextBreaks,
      overallQuality
    };
  }

  /**
   * Analyze multiple conversations
   */
  analyzeContextBatch(conversations: ParsedConversation[]): ContextAnalysisResult[] {
    return conversations.map(conv => this.analyzeContext(conv));
  }

  /**
   * Detect context breaks in conversation
   */
  private detectContextBreaks(conversation: ParsedConversation): ContextBreak[] {
    const breaks: ContextBreak[] = [];
    const messages = conversation.messages;

    for (let i = 2; i < messages.length; i++) {
      const currentMsg = messages[i];
      
      // Only check bot messages
      if (currentMsg.sender !== 'bot') continue;

      const previousUserMsg = this.findPreviousUserMessage(messages, i);
      if (!previousUserMsg) continue;

      // Check if bot response references previous context
      const hasContextReference = this.hasContextReference(
        currentMsg.content,
        previousUserMsg.content
      );

      if (!hasContextReference) {
        // Check if this is a major break (completely unrelated)
        const isMajorBreak = this.isMajorContextBreak(
          currentMsg.content,
          messages.slice(0, i)
        );

        breaks.push({
          messageIndex: i,
          reason: isMajorBreak 
            ? 'Bot response does not reference previous user message'
            : 'Weak context reference',
          severity: isMajorBreak ? 'major' : 'minor'
        });
      }
    }

    return breaks;
  }

  /**
   * Find previous user message
   */
  private findPreviousUserMessage(messages: any[], currentIndex: number): any | null {
    for (let i = currentIndex - 1; i >= 0; i--) {
      if (messages[i].sender === 'user') {
        return messages[i];
      }
    }
    return null;
  }

  /**
   * Check if message has context reference
   */
  private hasContextReference(botMessage: string, userMessage: string): boolean {
    const botLower = botMessage.toLowerCase();
    const userLower = userMessage.toLowerCase();

    // Check for referential words
    const referentialWords = [
      'that', 'this', 'it', 'your', 'you mentioned', 'you said',
      'as you', 'regarding', 'about that', 'the issue', 'the problem'
    ];

    const hasReferential = referentialWords.some(word => botLower.includes(word));
    if (hasReferential) return true;

    // Check for word overlap (shared significant words)
    const userWords = this.extractSignificantWords(userLower);
    const botWords = this.extractSignificantWords(botLower);

    const overlap = userWords.filter(word => botWords.includes(word));
    return overlap.length >= 2; // At least 2 shared significant words
  }

  /**
   * Extract significant words (longer than 3 characters, not common words)
   */
  private extractSignificantWords(text: string): string[] {
    const stopWords = new Set([
      'the', 'and', 'for', 'are', 'but', 'not', 'you', 'all', 'can',
      'was', 'one', 'our', 'out', 'day', 'get', 'has', 'him', 'his',
      'how', 'that', 'this', 'with', 'have', 'from', 'they', 'will'
    ]);

    return text
      .split(/\s+/)
      .filter(word => word.length > 3 && !stopWords.has(word));
  }

  /**
   * Check if this is a major context break
   */
  private isMajorContextBreak(botMessage: string, previousMessages: any[]): boolean {
    // Get last 3 messages for context
    const recentMessages = previousMessages.slice(-3);
    const recentText = recentMessages.map(m => m.content).join(' ').toLowerCase();
    const botLower = botMessage.toLowerCase();

    // Extract significant words from recent context
    const contextWords = this.extractSignificantWords(recentText);
    const botWords = this.extractSignificantWords(botLower);

    // If no word overlap, it's a major break
    const overlap = contextWords.filter(word => botWords.includes(word));
    return overlap.length === 0;
  }

  /**
   * Calculate context retention score (0-1)
   */
  private calculateContextScore(
    conversation: ParsedConversation,
    breaks: ContextBreak[]
  ): number {
    const botMessages = conversation.messages.filter(m => m.sender === 'bot').length;
    
    if (botMessages <= 1) return 1; // Single response, no context needed

    const majorBreaks = breaks.filter(b => b.severity === 'major').length;
    const minorBreaks = breaks.filter(b => b.severity === 'minor').length;

    // Calculate penalty
    const penalty = (majorBreaks * 0.3) + (minorBreaks * 0.1);
    const score = Math.max(0, 1 - penalty);

    return score;
  }

  /**
   * Determine overall quality from score
   */
  private determineQuality(score: number): 'poor' | 'fair' | 'good' | 'excellent' {
    if (score >= 0.9) return 'excellent';
    if (score >= 0.7) return 'good';
    if (score >= 0.5) return 'fair';
    return 'poor';
  }

  /**
   * Get context analysis summary
   */
  getContextSummary(results: ContextAnalysisResult[]): {
    totalAnalyzed: number;
    multiTurnConversations: number;
    averageScore: number;
    qualityDistribution: Record<string, number>;
  } {
    const totalAnalyzed = results.length;
    const multiTurnConversations = results.filter(r => r.hasMultipleTurns).length;
    
    const scores = results
      .filter(r => r.hasMultipleTurns)
      .map(r => r.contextRetentionScore);
    
    const averageScore = scores.length > 0
      ? scores.reduce((sum, s) => sum + s, 0) / scores.length
      : 0;

    const qualityDistribution = {
      excellent: results.filter(r => r.overallQuality === 'excellent').length,
      good: results.filter(r => r.overallQuality === 'good').length,
      fair: results.filter(r => r.overallQuality === 'fair').length,
      poor: results.filter(r => r.overallQuality === 'poor').length
    };

    return {
      totalAnalyzed,
      multiTurnConversations,
      averageScore,
      qualityDistribution
    };
  }
}
