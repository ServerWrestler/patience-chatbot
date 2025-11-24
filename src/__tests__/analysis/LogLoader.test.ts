/**
 * Unit tests for LogLoader
 */

import { describe, test, expect } from 'vitest';
import { LogLoader } from '../../analysis/LogLoader';
import * as path from 'path';

describe('LogLoader', () => {
  const loader = new LogLoader();
  const samplesDir = path.join(process.cwd(), 'examples', 'sample-logs');

  test('should load JSON log file', async () => {
    const logPath = path.join(samplesDir, 'conversations.json');
    const data = await loader.loadLog(logPath, 'json');

    expect(data.format).toBe('json');
    expect(data.content).toBeDefined();
    expect(typeof data.content).toBe('object');
    expect(data.metadata.fileSize).toBeGreaterThan(0);
  });

  test('should load CSV log file', async () => {
    const logPath = path.join(samplesDir, 'conversations.csv');
    const data = await loader.loadLog(logPath, 'csv');

    expect(data.format).toBe('csv');
    expect(typeof data.content).toBe('string');
    expect(data.metadata.lineCount).toBeGreaterThan(0);
  });

  test('should load text log file', async () => {
    const logPath = path.join(samplesDir, 'conversations.txt');
    const data = await loader.loadLog(logPath, 'text');

    expect(data.format).toBe('text');
    expect(typeof data.content).toBe('string');
    expect(data.metadata.lineCount).toBeGreaterThan(0);
  });

  test('should auto-detect JSON format', async () => {
    const logPath = path.join(samplesDir, 'conversations.json');
    const format = await loader.detectFormat(logPath);

    expect(format).toBe('json');
  });

  test('should auto-detect CSV format', async () => {
    const logPath = path.join(samplesDir, 'conversations.csv');
    const format = await loader.detectFormat(logPath);

    expect(format).toBe('csv');
  });

  test('should auto-detect text format', async () => {
    const logPath = path.join(samplesDir, 'conversations.txt');
    const format = await loader.detectFormat(logPath);

    expect(format).toBe('text');
  });

  test('should throw error for non-existent file', async () => {
    await expect(
      loader.loadLog('non-existent-file.json')
    ).rejects.toThrow('Log file not found');
  });

  test('should list supported formats', () => {
    const formats = loader.supportedFormats();

    expect(formats).toContain('json');
    expect(formats).toContain('csv');
    expect(formats).toContain('text');
    expect(formats).toContain('auto');
  });

  test('should validate file path', () => {
    expect(loader.validateFilePath('valid/path.json')).toBe(true);
    expect(loader.validateFilePath('../../../etc/passwd')).toBe(false);
  });

  test('should get file info', async () => {
    const logPath = path.join(samplesDir, 'conversations.json');
    const info = await loader.getFileInfo(logPath);

    expect(info.exists).toBe(true);
    expect(info.isFile).toBe(true);
    expect(info.extension).toBe('.json');
    expect(info.size).toBeGreaterThan(0);
  });
});
