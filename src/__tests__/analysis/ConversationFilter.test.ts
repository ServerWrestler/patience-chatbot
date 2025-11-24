/**
 * Unit tests for ConversationFilter
 */

import { describe, test, expect } from 'vitest';
import { ConversationFilter } from '../../analysis/ConversationFilter';
import { ParsedConversation } from '../../analysis/types';

describe('ConversationFilter', () => {
  const filter = new ConversationFilter();

  const createMockConversation = (
    id: string,
    messageCount: number,
    userId?: string,
    startTime?: Date
  ): ParsedConversation => ({
    id,
    messages: Array.from({ length: messageCount }, (_, i) => ({
      sender: i % 2 === 0 ? 'user' : 'bot',
      content: `Message ${i}`,
      timestamp: new Date()
    })),
    metadata: {
      userId,
      startTime,
      source: 'test'
    }
  });

  test('should filter by minimum messages', () => {
    const conversations = [
      createMockConversation('conv-1', 2),
      createMockConversation('conv-2', 5),
      createMockConversation('conv-3', 10)
    ];

    const filtered = filter.filter(conversations, { minMessages: 5 });

    expect(filtered.length).toBe(2);
    expect(filtered[0].id).toBe('conv-2');
    expect(filtered[1].id).toBe('conv-3');
  });

  test('should filter by maximum messages', () => {
    const conversations = [
      createMockConversation('conv-1', 2),
      createMockConversation('conv-2', 5),
      createMockConversation('conv-3', 10)
    ];

    const filtered = filter.filter(conversations, { maxMessages: 5 });

    expect(filtered.length).toBe(2);
    expect(filtered[0].id).toBe('conv-1');
    expect(filtered[1].id).toBe('conv-2');
  });

  test('should filter by user IDs', () => {
    const conversations = [
      createMockConversation('conv-1', 3, 'user-123'),
      createMockConversation('conv-2', 3, 'user-456'),
      createMockConversation('conv-3', 3, 'user-789')
    ];

    const filtered = filter.filter(conversations, { 
      userIds: ['user-123', 'user-789'] 
    });

    expect(filtered.length).toBe(2);
    expect(filtered[0].metadata.userId).toBe('user-123');
    expect(filtered[1].metadata.userId).toBe('user-789');
  });

  test('should filter by date range', () => {
    const conversations = [
      createMockConversation('conv-1', 3, undefined, new Date('2025-01-10')),
      createMockConversation('conv-2', 3, undefined, new Date('2025-01-15')),
      createMockConversation('conv-3', 3, undefined, new Date('2025-01-20'))
    ];

    const filtered = filter.filter(conversations, {
      dateRange: {
        start: new Date('2025-01-12'),
        end: new Date('2025-01-18')
      }
    });

    expect(filtered.length).toBe(1);
    expect(filtered[0].id).toBe('conv-2');
  });

  test('should filter by text content', () => {
    const conversations: ParsedConversation[] = [
      {
        id: 'conv-1',
        messages: [
          { sender: 'user', content: 'Hello world', timestamp: new Date() }
        ],
        metadata: {}
      },
      {
        id: 'conv-2',
        messages: [
          { sender: 'user', content: 'Goodbye', timestamp: new Date() }
        ],
        metadata: {}
      }
    ];

    const filtered = filter.filter(conversations, { containsText: 'hello' });

    expect(filtered.length).toBe(1);
    expect(filtered[0].id).toBe('conv-1');
  });

  test('should apply multiple filters', () => {
    const conversations = [
      createMockConversation('conv-1', 2, 'user-123'),
      createMockConversation('conv-2', 5, 'user-123'),
      createMockConversation('conv-3', 10, 'user-456')
    ];

    const filtered = filter.filter(conversations, {
      minMessages: 3,
      userIds: ['user-123']
    });

    expect(filtered.length).toBe(1);
    expect(filtered[0].id).toBe('conv-2');
  });

  test('should get filter statistics', () => {
    const original = [
      createMockConversation('conv-1', 2),
      createMockConversation('conv-2', 5),
      createMockConversation('conv-3', 10)
    ];

    const filtered = filter.filter(original, { minMessages: 5 });
    const stats = filter.getFilterStats(original, filtered);

    expect(stats.originalCount).toBe(3);
    expect(stats.filteredCount).toBe(2);
    expect(stats.removedCount).toBe(1);
    expect(stats.retentionRate).toBeCloseTo(0.667, 2);
  });
});
