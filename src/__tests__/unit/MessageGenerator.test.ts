/**
 * Unit tests for MessageGenerator
 */

import { describe, test, expect } from 'vitest';
import { MessageGenerator } from '../../execution/MessageGenerator';

describe('MessageGenerator', () => {
  test('should generate question ending with question mark', () => {
    const generator = new MessageGenerator();
    const message = generator.generateMessage('question');

    expect(message.length).toBeGreaterThan(0);
    expect(MessageGenerator.isQuestion(message)).toBe(true);
  });

  test('should generate statement ending with period', () => {
    const generator = new MessageGenerator();
    const message = generator.generateMessage('statement');

    expect(message.length).toBeGreaterThan(0);
    expect(MessageGenerator.isStatement(message)).toBe(true);
  });

  test('should generate command with imperative verb', () => {
    const generator = new MessageGenerator();
    const message = generator.generateMessage('command');

    expect(message.length).toBeGreaterThan(0);
    expect(MessageGenerator.isCommand(message)).toBe(true);
  });

  test('should generate diverse messages', () => {
    const generator = new MessageGenerator();
    const messages = generator.generateDiverseMessages(10);

    expect(messages.length).toBe(10);

    // Check for diversity
    const uniqueMessages = new Set(messages);
    expect(uniqueMessages.size).toBeGreaterThan(1);
  });

  test('should generate edge cases', () => {
    const generator = new MessageGenerator();
    const edgeCases = generator.generateEdgeCases();

    expect(edgeCases.length).toBeGreaterThan(0);

    // Should include empty string
    expect(edgeCases).toContain('');

    // Should include special characters
    const hasSpecialChars = edgeCases.some(msg => /[!@#$%^&*()]/.test(msg));
    expect(hasSpecialChars).toBe(true);
  });

  test('should generate very long message', () => {
    const generator = new MessageGenerator();
    const longMessage = generator.generateVeryLongMessage(1000);

    expect(longMessage.length).toBe(1000);
  });

  test('should generate message with special characters', () => {
    const generator = new MessageGenerator();
    const message = generator.generateSpecialCharacterMessage();

    expect(message).toContain('special chars');
    expect(/[!@#$%^&*()]/.test(message)).toBe(true);
  });

  test('should generate empty message', () => {
    const generator = new MessageGenerator();
    const message = generator.generateEmptyMessage();

    expect(message.trim().length).toBe(0);
  });

  test('should apply length constraints', () => {
    const generator = new MessageGenerator();
    const message = generator.generateMessage('statement', {
      minLength: 50,
      maxLength: 100
    });

    expect(message.length).toBeGreaterThanOrEqual(50);
    expect(message.length).toBeLessThanOrEqual(100);
  });

  test('should generate coherent sequence with topic', () => {
    const generator = new MessageGenerator();
    const topic = 'weather';
    const messages = generator.generateCoherentSequence(5, topic);

    expect(messages.length).toBe(5);

    // Check that at least some messages mention the topic
    const topicMentions = messages.filter(msg => 
      msg.toLowerCase().includes(topic.toLowerCase())
    ).length;
    
    expect(topicMentions).toBeGreaterThan(0);
  });

  test('should validate message type appropriateness', () => {
    expect(MessageGenerator.validateMessageType('What is this?', 'question')).toBe(true);
    expect(MessageGenerator.validateMessageType('This is a statement.', 'statement')).toBe(true);
    expect(MessageGenerator.validateMessageType('Show me the results.', 'command')).toBe(true);
  });

  test('should detect questions correctly', () => {
    expect(MessageGenerator.isQuestion('What is your name?')).toBe(true);
    expect(MessageGenerator.isQuestion('How are you?')).toBe(true);
    expect(MessageGenerator.isQuestion('This is not a question.')).toBe(false);
  });

  test('should detect commands correctly', () => {
    expect(MessageGenerator.isCommand('Show me the data.')).toBe(true);
    expect(MessageGenerator.isCommand('List all items.')).toBe(true);
    expect(MessageGenerator.isCommand('This is not a command.')).toBe(false);
  });

  test('should generate varying length messages', () => {
    const generator = new MessageGenerator();
    const messages = generator.generateVaryingLengthMessages(5);

    expect(messages.length).toBe(5);

    // Check for length variation
    const lengths = messages.map(m => m.length);
    const uniqueLengths = new Set(lengths);
    expect(uniqueLengths.size).toBeGreaterThan(1);
  });

  test('should generate varying content messages', () => {
    const generator = new MessageGenerator();
    const messages = generator.generateVaryingContentMessages(6);

    expect(messages.length).toBe(6);

    // Should have different types
    const hasQuestion = messages.some(m => MessageGenerator.isQuestion(m));
    const hasCommand = messages.some(m => MessageGenerator.isCommand(m));

    expect(hasQuestion || hasCommand).toBe(true);
  });
});
