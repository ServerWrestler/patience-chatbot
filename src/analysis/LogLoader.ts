/**
 * Log Loader - Loads log files from disk and detects format
 */

import * as fs from 'fs/promises';
import * as path from 'path';
import { LogFormat, RawLogData } from './types';

export class LogLoader {
  /**
   * Load a log file from disk
   */
  async loadLog(filePath: string, format?: LogFormat): Promise<RawLogData> {
    try {
      // Check if file exists
      await fs.access(filePath);

      // Get file stats
      const stats = await fs.stat(filePath);
      
      if (!stats.isFile()) {
        throw new Error(`Path is not a file: ${filePath}`);
      }

      // Read file content
      const content = await fs.readFile(filePath, 'utf-8');

      // Detect or use provided format
      const detectedFormat = format === 'auto' || !format 
        ? await this.detectFormat(filePath, content)
        : format;

      // Count lines for text-based formats
      const lineCount = this.countLines(content);

      return {
        content: detectedFormat === 'json' ? JSON.parse(content) : content,
        format: detectedFormat,
        metadata: {
          fileSize: stats.size,
          lineCount,
          encoding: 'utf-8'
        }
      };
    } catch (error) {
      if (error instanceof Error) {
        if ((error as any).code === 'ENOENT') {
          throw new Error(`Log file not found: ${filePath}`);
        }
        if ((error as any).code === 'EACCES') {
          throw new Error(`Permission denied reading file: ${filePath}`);
        }
        throw new Error(`Failed to load log file: ${error.message}`);
      }
      throw error;
    }
  }

  /**
   * Detect the format of a log file
   */
  async detectFormat(filePath: string, content?: string): Promise<LogFormat> {
    const ext = path.extname(filePath).toLowerCase();

    // Try extension-based detection first
    if (ext === '.json') {
      return 'json';
    }
    if (ext === '.csv') {
      return 'csv';
    }
    if (ext === '.txt' || ext === '.log') {
      return 'text';
    }

    // If no content provided, read it
    if (!content) {
      content = await fs.readFile(filePath, 'utf-8');
    }

    // Try content-based detection
    const trimmed = content.trim();

    // Check for JSON
    if (trimmed.startsWith('{') || trimmed.startsWith('[')) {
      try {
        JSON.parse(trimmed);
        return 'json';
      } catch {
        // Not valid JSON
      }
    }

    // Check for CSV (look for comma-separated values in first line)
    const firstLine = trimmed.split('\n')[0];
    if (firstLine && firstLine.includes(',') && firstLine.split(',').length >= 3) {
      return 'csv';
    }

    // Default to text format
    return 'text';
  }

  /**
   * Get list of supported formats
   */
  supportedFormats(): LogFormat[] {
    return ['json', 'csv', 'text', 'auto'];
  }

  /**
   * Count lines in content
   */
  private countLines(content: string): number {
    return content.split('\n').length;
  }

  /**
   * Validate that a file path is safe (no directory traversal)
   */
  validateFilePath(filePath: string): boolean {
    const normalized = path.normalize(filePath);
    const resolved = path.resolve(filePath);
    
    // Check for directory traversal attempts
    if (normalized.includes('..')) {
      return false;
    }

    return true;
  }

  /**
   * Get file information without loading content
   */
  async getFileInfo(filePath: string): Promise<{
    exists: boolean;
    size: number;
    isFile: boolean;
    extension: string;
  }> {
    try {
      const stats = await fs.stat(filePath);
      return {
        exists: true,
        size: stats.size,
        isFile: stats.isFile(),
        extension: path.extname(filePath)
      };
    } catch (error) {
      return {
        exists: false,
        size: 0,
        isFile: false,
        extension: ''
      };
    }
  }
}
