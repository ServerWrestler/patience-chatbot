/**
 * Metrics Calculator - Calculates statistical metrics from conversations
 */

import { ParsedConversation, ConversationValidationResult, AnalysisMetrics } from './types';

export class MetricsCalculator {
  /**
   * Calculate comprehensive metrics from conversations
   */
  calculateMetrics(
    conversations: ParsedConversation[],
    validationResults?: ConversationValidationResult[]
  ): AnalysisMetrics {
    const totalConversations = conversations.length;
    const totalMessages = this.calculateTotalMessages(conversations);
    const averageMessagesPerConversation = totalConversations > 0
      ? totalMessages / totalConversations
      : 0;

    const averageConversationDuration = this.calculateAverageDuration(conversations);
    const botResponseRate = this.calculateBotResponseRate(conversations);
    const validationPassRate = validationResults
      ? this.calculateValidationPassRate(validationResults)
      : 0;

    const timeDistribution = this.calculateTimeDistribution(conversations);
    const messageLengthStats = this.calculateMessageLengthStats(conversations);

    return {
      totalConversations,
      totalMessages,
      averageMessagesPerConversation,
      averageConversationDuration,
      validationPassRate,
      botResponseRate,
      timeDistribution,
      messageLengthStats
    };
  }

  /**
   * Calculate total messages across all conversations
   */
  private calculateTotalMessages(conversations: ParsedConversation[]): number {
    return conversations.reduce((sum, conv) => sum + conv.messages.length, 0);
  }

  /**
   * Calculate average conversation duration in seconds
   */
  private calculateAverageDuration(conversations: ParsedConversation[]): number | undefined {
    const durations: number[] = [];

    for (const conv of conversations) {
      if (conv.metadata.startTime && conv.metadata.endTime) {
        const duration = (conv.metadata.endTime.getTime() - conv.metadata.startTime.getTime()) / 1000;
        durations.push(duration);
      }
    }

    if (durations.length === 0) return undefined;

    return durations.reduce((sum, d) => sum + d, 0) / durations.length;
  }

  /**
   * Calculate bot response rate (bot messages / total messages)
   */
  private calculateBotResponseRate(conversations: ParsedConversation[]): number {
    let totalMessages = 0;
    let botMessages = 0;

    for (const conv of conversations) {
      totalMessages += conv.messages.length;
      botMessages += conv.messages.filter(m => m.sender === 'bot').length;
    }

    return totalMessages > 0 ? botMessages / totalMessages : 0;
  }

  /**
   * Calculate validation pass rate
   */
  private calculateValidationPassRate(results: ConversationValidationResult[]): number {
    const totalValidated = results.reduce((sum, r) => sum + r.validatedMessages, 0);
    const totalPassed = results.reduce((sum, r) => sum + r.passedValidations, 0);

    return totalValidated > 0 ? totalPassed / totalValidated : 0;
  }

  /**
   * Calculate time distribution (hour of day, day of week)
   */
  private calculateTimeDistribution(conversations: ParsedConversation[]): {
    hourOfDay: Record<number, number>;
    dayOfWeek: Record<string, number>;
  } | undefined {
    const hourOfDay: Record<number, number> = {};
    const dayOfWeek: Record<string, number> = {
      'Sunday': 0,
      'Monday': 0,
      'Tuesday': 0,
      'Wednesday': 0,
      'Thursday': 0,
      'Friday': 0,
      'Saturday': 0
    };

    let hasTimestamps = false;

    for (const conv of conversations) {
      if (conv.metadata.startTime) {
        hasTimestamps = true;
        const date = conv.metadata.startTime;
        const hour = date.getHours();
        const day = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'][date.getDay()];

        hourOfDay[hour] = (hourOfDay[hour] || 0) + 1;
        dayOfWeek[day]++;
      }
    }

    return hasTimestamps ? { hourOfDay, dayOfWeek } : undefined;
  }

  /**
   * Calculate message length statistics
   */
  private calculateMessageLengthStats(conversations: ParsedConversation[]): {
    min: number;
    max: number;
    average: number;
    median: number;
  } {
    const lengths: number[] = [];

    for (const conv of conversations) {
      for (const msg of conv.messages) {
        lengths.push(msg.content.length);
      }
    }

    if (lengths.length === 0) {
      return { min: 0, max: 0, average: 0, median: 0 };
    }

    lengths.sort((a, b) => a - b);

    const min = lengths[0];
    const max = lengths[lengths.length - 1];
    const average = lengths.reduce((sum, l) => sum + l, 0) / lengths.length;
    const median = lengths.length % 2 === 0
      ? (lengths[lengths.length / 2 - 1] + lengths[lengths.length / 2]) / 2
      : lengths[Math.floor(lengths.length / 2)];

    return { min, max, average, median };
  }
}
