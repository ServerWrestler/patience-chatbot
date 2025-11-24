/**
 * Conversation Filter - Filters conversations based on criteria
 */

import { ParsedConversation, FilterCriteria } from './types';

export class ConversationFilter {
  /**
   * Filter conversations based on criteria
   */
  filter(
    conversations: ParsedConversation[],
    criteria: FilterCriteria
  ): ParsedConversation[] {
    let filtered = conversations;

    // Apply date range filter
    if (criteria.dateRange) {
      filtered = this.filterByDateRange(filtered, criteria.dateRange);
    }

    // Apply message count filters
    if (criteria.minMessages !== undefined) {
      filtered = filtered.filter(conv => conv.messages.length >= criteria.minMessages!);
    }

    if (criteria.maxMessages !== undefined) {
      filtered = filtered.filter(conv => conv.messages.length <= criteria.maxMessages!);
    }

    // Apply user ID filter
    if (criteria.userIds && criteria.userIds.length > 0) {
      filtered = filtered.filter(conv => 
        conv.metadata.userId && criteria.userIds!.includes(conv.metadata.userId)
      );
    }

    // Apply session ID filter
    if (criteria.sessionIds && criteria.sessionIds.length > 0) {
      filtered = filtered.filter(conv =>
        conv.metadata.sessionId && criteria.sessionIds!.includes(conv.metadata.sessionId)
      );
    }

    // Apply text content filter
    if (criteria.containsText) {
      filtered = this.filterByTextContent(filtered, criteria.containsText);
    }

    // Apply custom filter
    if (criteria.customFilter) {
      filtered = filtered.filter(criteria.customFilter);
    }

    return filtered;
  }

  /**
   * Filter by date range
   */
  private filterByDateRange(
    conversations: ParsedConversation[],
    dateRange: { start: Date; end: Date }
  ): ParsedConversation[] {
    return conversations.filter(conv => {
      const startTime = conv.metadata.startTime;
      if (!startTime) return false;

      return startTime >= dateRange.start && startTime <= dateRange.end;
    });
  }

  /**
   * Filter by text content
   */
  private filterByTextContent(
    conversations: ParsedConversation[],
    searchText: string
  ): ParsedConversation[] {
    const lowerSearch = searchText.toLowerCase();

    return conversations.filter(conv =>
      conv.messages.some(msg =>
        msg.content.toLowerCase().includes(lowerSearch)
      )
    );
  }

  /**
   * Get filter statistics
   */
  getFilterStats(
    original: ParsedConversation[],
    filtered: ParsedConversation[]
  ): {
    originalCount: number;
    filteredCount: number;
    removedCount: number;
    retentionRate: number;
  } {
    const originalCount = original.length;
    const filteredCount = filtered.length;
    const removedCount = originalCount - filteredCount;
    const retentionRate = originalCount > 0 ? filteredCount / originalCount : 0;

    return {
      originalCount,
      filteredCount,
      removedCount,
      retentionRate
    };
  }
}
