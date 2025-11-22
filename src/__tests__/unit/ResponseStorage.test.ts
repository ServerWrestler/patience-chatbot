/**
 * Unit tests for ResponseStorage
 */

import { describe, test, expect } from 'vitest';
import { ResponseStorage } from '../../types/ResponseStorage';
import { createMockResponse } from '../helpers/testUtils';

describe('ResponseStorage', () => {
  test('should create conversation history', () => {
    const storage = new ResponseStorage();
    const sessionId = 'test-session';

    const history = storage.createHistory(sessionId);

    expect(history).toBeDefined();
    expect(history.sessionId).toBe(sessionId);
    expect(history.messages).toEqual([]);
  });

  test('should store and retrieve messages', () => {
    const storage = new ResponseStorage();
    const sessionId = 'test-session';

    storage.createHistory(sessionId);
    storage.storeMessage(sessionId, 'patience', 'Hello');
    storage.storeMessage(sessionId, 'target', 'Hi there');

    const messages = storage.getMessages(sessionId);

    expect(messages.length).toBe(2);
    expect(messages[0].sender).toBe('patience');
    expect(messages[0].content).toBe('Hello');
    expect(messages[1].sender).toBe('target');
    expect(messages[1].content).toBe('Hi there');
  });

  test('should store bot responses', () => {
    const storage = new ResponseStorage();
    const sessionId = 'test-session';

    storage.createHistory(sessionId);
    const response = createMockResponse('Response content');
    storage.storeResponse(sessionId, response);

    const messages = storage.getMessages(sessionId);

    expect(messages.length).toBe(1);
    expect(messages[0].sender).toBe('target');
    expect(messages[0].content).toBe('Response content');
  });

  test('should store Patience messages', () => {
    const storage = new ResponseStorage();
    const sessionId = 'test-session';

    storage.createHistory(sessionId);
    storage.storePatienceMessage(sessionId, 'Test message');

    const messages = storage.getMessages(sessionId);

    expect(messages.length).toBe(1);
    expect(messages[0].sender).toBe('patience');
    expect(messages[0].content).toBe('Test message');
  });

  test('should get recent messages', () => {
    const storage = new ResponseStorage();
    const sessionId = 'test-session';

    storage.createHistory(sessionId);
    storage.storeMessage(sessionId, 'patience', 'Message 1');
    storage.storeMessage(sessionId, 'target', 'Message 2');
    storage.storeMessage(sessionId, 'patience', 'Message 3');
    storage.storeMessage(sessionId, 'target', 'Message 4');

    const recent = storage.getRecentMessages(sessionId, 2);

    expect(recent.length).toBe(2);
    expect(recent[0].content).toBe('Message 3');
    expect(recent[1].content).toBe('Message 4');
  });

  test('should get messages by sender', () => {
    const storage = new ResponseStorage();
    const sessionId = 'test-session';

    storage.createHistory(sessionId);
    storage.storeMessage(sessionId, 'patience', 'Patience 1');
    storage.storeMessage(sessionId, 'target', 'Target 1');
    storage.storeMessage(sessionId, 'patience', 'Patience 2');

    const patienceMessages = storage.getMessagesBySender(sessionId, 'patience');
    const targetMessages = storage.getMessagesBySender(sessionId, 'target');

    expect(patienceMessages.length).toBe(2);
    expect(targetMessages.length).toBe(1);
  });

  test('should check if session exists', () => {
    const storage = new ResponseStorage();
    const sessionId = 'test-session';

    expect(storage.hasSession(sessionId)).toBe(false);

    storage.createHistory(sessionId);

    expect(storage.hasSession(sessionId)).toBe(true);
  });

  test('should clear specific session', () => {
    const storage = new ResponseStorage();
    const sessionId = 'test-session';

    storage.createHistory(sessionId);
    storage.storeMessage(sessionId, 'patience', 'Test');

    expect(storage.hasSession(sessionId)).toBe(true);

    storage.clearSession(sessionId);

    expect(storage.hasSession(sessionId)).toBe(false);
  });

  test('should clear all sessions', () => {
    const storage = new ResponseStorage();

    storage.createHistory('session-1');
    storage.createHistory('session-2');

    expect(storage.getAllSessionIds().length).toBe(2);

    storage.clearAll();

    expect(storage.getAllSessionIds().length).toBe(0);
  });

  test('should get all session IDs', () => {
    const storage = new ResponseStorage();

    storage.createHistory('session-1');
    storage.createHistory('session-2');
    storage.createHistory('session-3');

    const sessionIds = storage.getAllSessionIds();

    expect(sessionIds.length).toBe(3);
    expect(sessionIds).toContain('session-1');
    expect(sessionIds).toContain('session-2');
    expect(sessionIds).toContain('session-3');
  });

  test('should get message count', () => {
    const storage = new ResponseStorage();
    const sessionId = 'test-session';

    storage.createHistory(sessionId);
    storage.storeMessage(sessionId, 'patience', 'Message 1');
    storage.storeMessage(sessionId, 'target', 'Message 2');

    const count = storage.getMessageCount(sessionId);

    expect(count).toBe(2);
  });

  test('should finalize history with end time', () => {
    const storage = new ResponseStorage();
    const sessionId = 'test-session';

    const history = storage.createHistory(sessionId);
    const startTime = history.startTime;

    // Wait a bit
    setTimeout(() => {
      storage.finalizeHistory(sessionId);

      const finalizedHistory = storage.getHistory(sessionId);
      expect(finalizedHistory).toBeDefined();
      expect(finalizedHistory!.endTime.getTime()).toBeGreaterThanOrEqual(startTime.getTime());
    }, 10);
  });

  test('should isolate sessions from each other', () => {
    const storage = new ResponseStorage();

    storage.createHistory('session-1');
    storage.createHistory('session-2');

    storage.storeMessage('session-1', 'patience', 'Session 1 message');
    storage.storeMessage('session-2', 'patience', 'Session 2 message');

    const messages1 = storage.getMessages('session-1');
    const messages2 = storage.getMessages('session-2');

    expect(messages1.length).toBe(1);
    expect(messages2.length).toBe(1);
    expect(messages1[0].content).toBe('Session 1 message');
    expect(messages2[0].content).toBe('Session 2 message');
  });
});
