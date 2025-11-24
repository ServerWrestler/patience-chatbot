/**
 * Conversation Logger - Logs adversarial conversations
 */

import * as fs from 'fs/promises';
import * as path from 'path';
import { ConversationResult, Message } from './types';

export class ConversationLogger {
  /**
   * Save conversation in JSON format
   */
  static async saveJSON(
    result: ConversationResult,
    outputPath: string
  ): Promise<string> {
    const filename = `conversation-${result.conversationId}.json`;
    const filepath = path.join(outputPath, filename);

    await fs.mkdir(outputPath, { recursive: true });
    await fs.writeFile(filepath, JSON.stringify(result, null, 2), 'utf-8');

    return filepath;
  }

  /**
   * Save conversation in human-readable text format
   */
  static async saveText(
    result: ConversationResult,
    outputPath: string
  ): Promise<string> {
    const filename = `conversation-${result.conversationId}.txt`;
    const filepath = path.join(outputPath, filename);

    const lines: string[] = [];

    // Header
    lines.push('='.repeat(70));
    lines.push(`Adversarial Conversation Log`);
    lines.push('='.repeat(70));
    lines.push('');
    lines.push(`Conversation ID: ${result.conversationId}`);
    lines.push(`Timestamp: ${result.timestamp.toISOString()}`);
    lines.push(`Strategy: ${result.config.conversation.strategy}`);
    lines.push(`Target Bot: ${result.config.targetBot.name}`);
    lines.push(`Adversarial Bot: ${result.config.adversarialBot.provider} (${result.config.adversarialBot.model || 'default'})`);
    lines.push('');
    lines.push(`Total Turns: ${result.turns}`);
    lines.push(`Duration: ${(result.duration / 1000).toFixed(2)}s`);
    lines.push(`Termination: ${result.terminationReason}`);
    if (result.terminationMessage) {
      lines.push(`Reason: ${result.terminationMessage}`);
    }
    lines.push('');

    // Metrics
    lines.push('Metrics:');
    lines.push(`  Validation Pass Rate: ${(result.passRate * 100).toFixed(1)}%`);
    lines.push(`  Avg Response Time: ${result.metrics.avgResponseTime.toFixed(0)}ms`);
    lines.push(`  Target Bot Response Rate: ${(result.metrics.targetBotResponseRate * 100).toFixed(1)}%`);
    lines.push(`  Conversation Quality: ${(result.metrics.conversationQuality * 100).toFixed(1)}%`);
    lines.push('');

    // Conversation
    lines.push('='.repeat(70));
    lines.push('Conversation Transcript');
    lines.push('='.repeat(70));
    lines.push('');

    for (let i = 0; i < result.messages.length; i++) {
      const msg = result.messages[i];
      const role = msg.role === 'adversarial' ? '🤖 Adversarial' : '🎯 Target';
      const time = msg.timestamp.toISOString().split('T')[1].split('.')[0];
      
      lines.push(`[${time}] ${role}:`);
      lines.push(msg.content);
      
      // Add validation result if available
      if (msg.role === 'target' && i < result.validationResults.length * 2) {
        const validationIndex = Math.floor(i / 2);
        const validation = result.validationResults[validationIndex];
        if (validation) {
          const status = validation.passed ? '✓ PASS' : '✗ FAIL';
          lines.push(`  [Validation: ${status}]`);
          if (!validation.passed && validation.message) {
            lines.push(`  [Reason: ${validation.message}]`);
          }
        }
      }
      
      lines.push('');
    }

    lines.push('='.repeat(70));
    lines.push('End of Conversation');
    lines.push('='.repeat(70));

    await fs.mkdir(outputPath, { recursive: true });
    await fs.writeFile(filepath, lines.join('\n'), 'utf-8');

    return filepath;
  }

  /**
   * Save conversation in CSV format
   */
  static async saveCSV(
    result: ConversationResult,
    outputPath: string
  ): Promise<string> {
    const filename = `conversation-${result.conversationId}.csv`;
    const filepath = path.join(outputPath, filename);

    const lines: string[] = [];

    // Header
    lines.push('turn,role,timestamp,content,response_time_ms,validation_passed,validation_reason');

    // Data rows
    let turnNumber = 0;
    for (let i = 0; i < result.messages.length; i++) {
      const msg = result.messages[i];
      
      if (msg.role === 'adversarial') {
        turnNumber++;
      }

      const responseTime = msg.metadata?.responseTime || '';
      
      // Get validation result for target messages
      let validationPassed = '';
      let validationReason = '';
      if (msg.role === 'target' && i < result.validationResults.length * 2) {
        const validationIndex = Math.floor(i / 2);
        const validation = result.validationResults[validationIndex];
        if (validation) {
          validationPassed = validation.passed ? 'true' : 'false';
          validationReason = validation.message || '';
        }
      }

      // Escape content for CSV
      const content = this.escapeCSV(msg.content);
      const reason = this.escapeCSV(validationReason);

      lines.push(
        `${turnNumber},${msg.role},${msg.timestamp.toISOString()},${content},${responseTime},${validationPassed},${reason}`
      );
    }

    await fs.mkdir(outputPath, { recursive: true });
    await fs.writeFile(filepath, lines.join('\n'), 'utf-8');

    return filepath;
  }

  /**
   * Escape CSV field
   */
  private static escapeCSV(field: string): string {
    if (field.includes(',') || field.includes('"') || field.includes('\n')) {
      return `"${field.replace(/"/g, '""')}"`;
    }
    return field;
  }

  /**
   * Save conversation in all requested formats
   */
  static async saveAll(
    result: ConversationResult,
    outputPath: string,
    formats: ('json' | 'text' | 'csv')[]
  ): Promise<string[]> {
    const savedFiles: string[] = [];

    for (const format of formats) {
      let filepath: string;
      
      switch (format) {
        case 'json':
          filepath = await this.saveJSON(result, outputPath);
          break;
        case 'text':
          filepath = await this.saveText(result, outputPath);
          break;
        case 'csv':
          filepath = await this.saveCSV(result, outputPath);
          break;
        default:
          continue;
      }

      savedFiles.push(filepath);
    }

    return savedFiles;
  }
}
