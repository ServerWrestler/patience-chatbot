/**
 * Unit tests for log parsers
 */

import { describe, test, expect } from 'vitest';
import { LogLoader } from '../../analysis/LogLoader';
import { JsonLogParser, CsvLogParser, TextLogParser } from '../../analysis/parsers';
import * as path from 'path';

describe('Log Parsers', () => {
  const loader = new LogLoader();
  const samplesDir = path.join(process.cwd(), 'examples', 'log-analysis', 'sample-logs');

  describe('JsonLogParser', () => {
    const parser = new JsonLogParser();

    test('should parse JSON log file', async () => {
      const logPath = path.join(samplesDir, 'conversations.json');
      const data = await loader.loadLog(logPath, 'json');
      
      const conversations = await parser.parse(data);

      expect(conversations.length).toBe(3);
      expect(conversations[0].id).toBe('conv-001');
      expect(conversations[0].messages.length).toBe(6);
      expect(conversations[0].messages[0].sender).toBe('user');
      expect(conversations[0].messages[1].sender).toBe('bot');
    });

    test('should validate JSON structure', async () => {
      const logPath = path.join(samplesDir, 'conversations.json');
      const data = await loader.loadLog(logPath, 'json');
      
      const result = parser.validate(data);

      expect(result.passed).toBe(true);
    });

    test('should extract metadata', async () => {
      const logPath = path.join(samplesDir, 'conversations.json');
      const data = await loader.loadLog(logPath, 'json');
      
      const conversations = await parser.parse(data);
      const conv = conversations[0];

      expect(conv.metadata.userId).toBe('user-123');
      expect(conv.metadata.sessionId).toBe('session-abc');
      expect(conv.metadata.startTime).toBeInstanceOf(Date);
      expect(conv.metadata.endTime).toBeInstanceOf(Date);
    });
  });

  describe('CsvLogParser', () => {
    const parser = new CsvLogParser();

    test('should parse CSV log file', async () => {
      const logPath = path.join(samplesDir, 'conversations.csv');
      const data = await loader.loadLog(logPath, 'csv');
      
      const conversations = await parser.parse(data);

      expect(conversations.length).toBe(3);
      expect(conversations[0].id).toBe('conv-001');
      expect(conversations[0].messages.length).toBe(6);
    });

    test('should validate CSV structure', async () => {
      const logPath = path.join(samplesDir, 'conversations.csv');
      const data = await loader.loadLog(logPath, 'csv');
      
      const result = parser.validate(data);

      expect(result.passed).toBe(true);
    });

    test('should group messages by conversation', async () => {
      const logPath = path.join(samplesDir, 'conversations.csv');
      const data = await loader.loadLog(logPath, 'csv');
      
      const conversations = await parser.parse(data);

      // Check that messages are grouped correctly
      const conv1 = conversations.find(c => c.id === 'conv-001');
      const conv2 = conversations.find(c => c.id === 'conv-002');
      const conv3 = conversations.find(c => c.id === 'conv-003');

      expect(conv1?.messages.length).toBe(6);
      expect(conv2?.messages.length).toBe(4);
      expect(conv3?.messages.length).toBe(6);
    });

    test('should sort messages by timestamp', async () => {
      const logPath = path.join(samplesDir, 'conversations.csv');
      const data = await loader.loadLog(logPath, 'csv');
      
      const conversations = await parser.parse(data);
      const conv = conversations[0];

      // Verify messages are in chronological order
      for (let i = 1; i < conv.messages.length; i++) {
        expect(conv.messages[i].timestamp.getTime()).toBeGreaterThanOrEqual(
          conv.messages[i - 1].timestamp.getTime()
        );
      }
    });
  });

  describe('TextLogParser', () => {
    const parser = new TextLogParser();

    test('should parse text log file', async () => {
      const logPath = path.join(samplesDir, 'conversations.txt');
      const data = await loader.loadLog(logPath, 'text');
      
      const conversations = await parser.parse(data);

      expect(conversations.length).toBe(3);
      expect(conversations[0].id).toBe('conv-001');
      expect(conversations[0].messages.length).toBe(6);
    });

    test('should validate text structure', async () => {
      const logPath = path.join(samplesDir, 'conversations.txt');
      const data = await loader.loadLog(logPath, 'text');
      
      const result = parser.validate(data);

      expect(result.passed).toBe(true);
    });

    test('should parse conversation markers', async () => {
      const logPath = path.join(samplesDir, 'conversations.txt');
      const data = await loader.loadLog(logPath, 'text');
      
      const conversations = await parser.parse(data);

      expect(conversations[0].id).toBe('conv-001');
      expect(conversations[1].id).toBe('conv-002');
      expect(conversations[2].id).toBe('conv-003');
    });

    test('should parse message patterns', async () => {
      const logPath = path.join(samplesDir, 'conversations.txt');
      const data = await loader.loadLog(logPath, 'text');
      
      const conversations = await parser.parse(data);
      const firstMessage = conversations[0].messages[0];

      expect(firstMessage.sender).toBe('user');
      expect(firstMessage.content).toContain('Hello');
    });
  });

  describe('Parser Consistency', () => {
    test('all parsers should extract same conversation count', async () => {
      const jsonPath = path.join(samplesDir, 'conversations.json');
      const csvPath = path.join(samplesDir, 'conversations.csv');
      const txtPath = path.join(samplesDir, 'conversations.txt');

      const jsonData = await loader.loadLog(jsonPath, 'json');
      const csvData = await loader.loadLog(csvPath, 'csv');
      const txtData = await loader.loadLog(txtPath, 'text');

      const jsonConvs = await new JsonLogParser().parse(jsonData);
      const csvConvs = await new CsvLogParser().parse(csvData);
      const txtConvs = await new TextLogParser().parse(txtData);

      expect(jsonConvs.length).toBe(3);
      expect(csvConvs.length).toBe(3);
      expect(txtConvs.length).toBe(3);
    });

    test('all parsers should extract same message counts', async () => {
      const jsonPath = path.join(samplesDir, 'conversations.json');
      const csvPath = path.join(samplesDir, 'conversations.csv');
      const txtPath = path.join(samplesDir, 'conversations.txt');

      const jsonData = await loader.loadLog(jsonPath, 'json');
      const csvData = await loader.loadLog(csvPath, 'csv');
      const txtData = await loader.loadLog(txtPath, 'text');

      const jsonConvs = await new JsonLogParser().parse(jsonData);
      const csvConvs = await new CsvLogParser().parse(csvData);
      const txtConvs = await new TextLogParser().parse(txtData);

      // Total messages should be the same
      const jsonTotal = jsonConvs.reduce((sum, c) => sum + c.messages.length, 0);
      const csvTotal = csvConvs.reduce((sum, c) => sum + c.messages.length, 0);
      const txtTotal = txtConvs.reduce((sum, c) => sum + c.messages.length, 0);

      expect(jsonTotal).toBe(16);
      expect(csvTotal).toBe(16);
      expect(txtTotal).toBe(16);
    });
  });
});
