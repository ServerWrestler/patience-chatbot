/**
 * Analysis Report Generator - Generates reports from analysis results
 */

import { AnalysisResults, AnalysisReport, ReportFormat } from './types';

export class AnalysisReportGenerator {
  /**
   * Generate report from analysis results
   */
  generateReport(results: AnalysisResults): AnalysisReport {
    return {
      timestamp: new Date(),
      summary: results.summary,
      metrics: results.metrics || {
        totalConversations: 0,
        totalMessages: 0,
        averageMessagesPerConversation: 0,
        validationPassRate: 0,
        botResponseRate: 0,
        messageLengthStats: { min: 0, max: 0, average: 0, median: 0 }
      },
      patterns: results.patterns || [],
      detailedResults: results.validationResults
    };
  }

  /**
   * Format report in specified format
   */
  formatReport(report: AnalysisReport, format: ReportFormat): string {
    switch (format) {
      case 'json':
        return this.formatJSON(report);
      case 'html':
        return this.formatHTML(report);
      case 'markdown':
        return this.formatMarkdown(report);
      case 'csv':
        return this.formatCSV(report);
      default:
        return this.formatJSON(report);
    }
  }

  /**
   * Format as JSON
   */
  private formatJSON(report: AnalysisReport): string {
    return JSON.stringify(report, null, 2);
  }

  /**
   * Format as HTML
   */
  private formatHTML(report: AnalysisReport): string {
    const lines: string[] = [
      '<!DOCTYPE html>',
      '<html>',
      '<head>',
      '  <title>Chat Log Analysis Report</title>',
      '  <style>',
      '    body { font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }',
      '    .container { max-width: 1200px; margin: 0 auto; background: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }',
      '    h1 { color: #333; border-bottom: 3px solid #4CAF50; padding-bottom: 10px; }',
      '    h2 { color: #555; margin-top: 30px; }',
      '    .summary { background: #e8f5e9; padding: 20px; border-radius: 5px; margin: 20px 0; }',
      '    .metric { display: inline-block; margin: 10px 20px 10px 0; }',
      '    .metric-label { font-weight: bold; color: #666; }',
      '    .metric-value { font-size: 24px; color: #4CAF50; }',
      '    .pattern { background: #fff3e0; padding: 15px; margin: 10px 0; border-left: 4px solid #ff9800; border-radius: 4px; }',
      '    .pattern-failure { border-left-color: #f44336; background: #ffebee; }',
      '    .pattern-success { border-left-color: #4CAF50; background: #e8f5e9; }',
      '    .severity-high { color: #f44336; font-weight: bold; }',
      '    .severity-medium { color: #ff9800; font-weight: bold; }',
      '    .severity-low { color: #4CAF50; }',
      '    table { width: 100%; border-collapse: collapse; margin: 20px 0; }',
      '    th, td { padding: 12px; text-align: left; border-bottom: 1px solid #ddd; }',
      '    th { background: #4CAF50; color: white; }',
      '    tr:hover { background: #f5f5f5; }',
      '    .pass { color: #4CAF50; font-weight: bold; }',
      '    .fail { color: #f44336; font-weight: bold; }',
      '  </style>',
      '</head>',
      '<body>',
      '  <div class="container">',
      '    <h1>📊 Chat Log Analysis Report</h1>',
      `    <p><strong>Generated:</strong> ${report.timestamp.toLocaleString()}</p>`,
      '',
      '    <div class="summary">',
      '      <h2>Summary</h2>',
      `      <div class="metric"><span class="metric-label">Total Conversations:</span> <span class="metric-value">${report.summary.totalConversations}</span></div>`,
      `      <div class="metric"><span class="metric-label">Analyzed:</span> <span class="metric-value">${report.summary.analyzedConversations}</span></div>`,
      `      <div class="metric"><span class="metric-label">Pass Rate:</span> <span class="metric-value">${(report.summary.overallPassRate * 100).toFixed(1)}%</span></div>`,
      `      <div class="metric"><span class="metric-label">Processing Time:</span> <span class="metric-value">${report.summary.processingTime}ms</span></div>`,
      '    </div>',
      ''
    ];

    // Add metrics section
    if (report.metrics) {
      lines.push('    <h2>📈 Metrics</h2>');
      lines.push('    <table>');
      lines.push('      <tr><th>Metric</th><th>Value</th></tr>');
      lines.push(`      <tr><td>Total Messages</td><td>${report.metrics.totalMessages}</td></tr>`);
      lines.push(`      <tr><td>Average Messages per Conversation</td><td>${report.metrics.averageMessagesPerConversation.toFixed(2)}</td></tr>`);
      lines.push(`      <tr><td>Bot Response Rate</td><td>${(report.metrics.botResponseRate * 100).toFixed(1)}%</td></tr>`);
      lines.push(`      <tr><td>Validation Pass Rate</td><td>${(report.metrics.validationPassRate * 100).toFixed(1)}%</td></tr>`);
      lines.push(`      <tr><td>Avg Message Length</td><td>${report.metrics.messageLengthStats.average.toFixed(0)} chars</td></tr>`);
      lines.push('    </table>');
    }

    // Add patterns section
    if (report.patterns.length > 0) {
      lines.push('    <h2>🔍 Detected Patterns</h2>');
      for (const pattern of report.patterns) {
        const patternClass = pattern.type === 'failure' ? 'pattern-failure' : 
                           pattern.type === 'success' ? 'pattern-success' : 'pattern';
        const severityClass = pattern.severity ? `severity-${pattern.severity}` : '';
        
        lines.push(`    <div class="pattern ${patternClass}">`);
        lines.push(`      <strong>${pattern.type.toUpperCase()}: ${pattern.pattern}</strong>`);
        if (pattern.severity) {
          lines.push(`      <span class="${severityClass}"> [${pattern.severity}]</span>`);
        }
        lines.push(`      <p>${pattern.description}</p>`);
        lines.push(`      <p><em>Frequency: ${pattern.frequency}</em></p>`);
        lines.push('    </div>');
      }
    }

    lines.push('  </div>');
    lines.push('</body>');
    lines.push('</html>');

    return lines.join('\n');
  }

  /**
   * Format as Markdown
   */
  private formatMarkdown(report: AnalysisReport): string {
    const lines: string[] = [
      '# Chat Log Analysis Report',
      '',
      `**Generated:** ${report.timestamp.toISOString()}`,
      '',
      '## Summary',
      '',
      `- **Total Conversations:** ${report.summary.totalConversations}`,
      `- **Analyzed:** ${report.summary.analyzedConversations}`,
      `- **Filtered Out:** ${report.summary.filteredOut}`,
      `- **Overall Pass Rate:** ${(report.summary.overallPassRate * 100).toFixed(1)}%`,
      `- **Processing Time:** ${report.summary.processingTime}ms`,
      ''
    ];

    // Add metrics
    if (report.metrics) {
      lines.push('## Metrics');
      lines.push('');
      lines.push('| Metric | Value |');
      lines.push('|--------|-------|');
      lines.push(`| Total Messages | ${report.metrics.totalMessages} |`);
      lines.push(`| Avg Messages/Conversation | ${report.metrics.averageMessagesPerConversation.toFixed(2)} |`);
      lines.push(`| Bot Response Rate | ${(report.metrics.botResponseRate * 100).toFixed(1)}% |`);
      lines.push(`| Validation Pass Rate | ${(report.metrics.validationPassRate * 100).toFixed(1)}% |`);
      lines.push(`| Avg Message Length | ${report.metrics.messageLengthStats.average.toFixed(0)} chars |`);
      lines.push('');
    }

    // Add patterns
    if (report.patterns.length > 0) {
      lines.push('## Detected Patterns');
      lines.push('');
      for (const pattern of report.patterns) {
        const emoji = pattern.type === 'failure' ? '❌' : pattern.type === 'success' ? '✅' : '⚠️';
        lines.push(`### ${emoji} ${pattern.pattern}`);
        lines.push('');
        lines.push(`**Type:** ${pattern.type}`);
        if (pattern.severity) {
          lines.push(`**Severity:** ${pattern.severity}`);
        }
        lines.push(`**Frequency:** ${pattern.frequency}`);
        lines.push('');
        lines.push(pattern.description);
        lines.push('');
      }
    }

    return lines.join('\n');
  }

  /**
   * Format as CSV
   */
  private formatCSV(report: AnalysisReport): string {
    const lines: string[] = [
      'conversation_id,total_messages,bot_messages,passed_validations,failed_validations,pass_rate'
    ];

    for (const result of report.detailedResults) {
      const passRate = result.validatedMessages > 0
        ? (result.passedValidations / result.validatedMessages * 100).toFixed(1)
        : '0';

      lines.push([
        result.conversationId,
        result.totalMessages,
        result.botMessages,
        result.passedValidations,
        result.failedValidations,
        passRate
      ].join(','));
    }

    return lines.join('\n');
  }
}
