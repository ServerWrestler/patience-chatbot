import { TestResults, TestReport, SummaryReport } from '../types';

/**
 * Report generation class
 */
export class ReportGenerator {
  /**
   * Generate a test report from results
   */
  generateReport(results: TestResults): TestReport {
    const passedScenarios = results.scenarioResults.filter(r => r.passed).length;
    const failedScenarios = results.scenarioResults.length - passedScenarios;

    const summary = this.generateSummaryText(results);

    return {
      timestamp: results.endTime,
      totalScenarios: results.scenarioResults.length,
      passedScenarios,
      failedScenarios,
      scenarioResults: results.scenarioResults,
      summary
    };
  }

  /**
   * Generate summary text
   */
  private generateSummaryText(results: TestResults): string {
    const { total, passed, failed } = results.summary;
    const duration = results.endTime.getTime() - results.startTime.getTime();
    const durationSec = (duration / 1000).toFixed(2);

    const lines: string[] = [
      `Test Run: ${results.testRunId}`,
      `Duration: ${durationSec}s`,
      `Total Scenarios: ${total}`,
      `Passed: ${passed}`,
      `Failed: ${failed}`,
      `Success Rate: ${total > 0 ? ((passed / total) * 100).toFixed(1) : 0}%`
    ];

    return lines.join('\n');
  }

  /**
   * Aggregate multiple test results
   */
  aggregateResults(results: TestResults[]): SummaryReport {
    const testRuns: TestReport[] = results.map(r => this.generateReport(r));

    const aggregatedSummary = {
      total: results.reduce((sum, r) => sum + r.summary.total, 0),
      passed: results.reduce((sum, r) => sum + r.summary.passed, 0),
      failed: results.reduce((sum, r) => sum + r.summary.failed, 0)
    };

    return {
      testRuns,
      aggregatedSummary,
      generatedAt: new Date()
    };
  }

  /**
   * Format report in specified format
   */
  formatReport(report: TestReport, format: 'json' | 'html' | 'markdown'): string {
    switch (format) {
      case 'json':
        return this.formatJSON(report);
      case 'html':
        return this.formatHTML(report);
      case 'markdown':
        return this.formatMarkdown(report);
      default:
        return this.formatJSON(report);
    }
  }

  /**
   * Format as JSON
   */
  private formatJSON(report: TestReport): string {
    return JSON.stringify(report, null, 2);
  }

  /**
   * Format as HTML
   */
  private formatHTML(report: TestReport): string {
    const lines: string[] = [
      '<!DOCTYPE html>',
      '<html>',
      '<head>',
      '  <meta charset="UTF-8">',
      '  <title>Patience Test Report</title>',
      '  <style>',
      '    body { font-family: Arial, sans-serif; margin: 20px; }',
      '    h1 { color: #333; }',
      '    .summary { background: #f5f5f5; padding: 15px; border-radius: 5px; }',
      '    .passed { color: green; }',
      '    .failed { color: red; }',
      '    .scenario { margin: 20px 0; padding: 15px; border: 1px solid #ddd; }',
      '    .message { margin: 5px 0; padding: 10px; background: #fafafa; white-space: pre-wrap; word-wrap: break-word; }',
      '    .validation { margin: 5px 0 5px 20px; padding: 8px; background: #fff3cd; border-left: 3px solid #ffc107; white-space: pre-wrap; word-wrap: break-word; }',
      '    .validation.passed { background: #d4edda; border-left-color: #28a745; }',
      '    .validation.failed { background: #f8d7da; border-left-color: #dc3545; }',
      '  </style>',
      '</head>',
      '<body>',
      '  <h1>Patience Test Report</h1>',
      '  <div class="summary">',
      `    <p><strong>Generated:</strong> ${report.timestamp.toISOString()}</p>`,
      `    <p><strong>Total Scenarios:</strong> ${report.totalScenarios}</p>`,
      `    <p class="passed"><strong>Passed:</strong> ${report.passedScenarios}</p>`,
      `    <p class="failed"><strong>Failed:</strong> ${report.failedScenarios}</p>`,
      '  </div>',
      '  <h2>Scenarios</h2>'
    ];

    for (const scenario of report.scenarioResults) {
      const statusClass = scenario.passed ? 'passed' : 'failed';
      lines.push(`  <div class="scenario ${statusClass}">`);
      lines.push(`    <h3>${scenario.scenarioName} (${scenario.scenarioId})</h3>`);
      lines.push(`    <p><strong>Status:</strong> ${scenario.passed ? 'PASSED' : 'FAILED'}</p>`);
      lines.push(`    <p><strong>Duration:</strong> ${scenario.duration}ms</p>`);

      if (scenario.error) {
        lines.push(`    <p class="failed"><strong>Error:</strong> ${this.escapeHtml(scenario.error.message)}</p>`);
      }

      if (scenario.conversationHistory.messages.length > 0) {
        lines.push('    <h4>Conversation:</h4>');
        for (const msg of scenario.conversationHistory.messages) {
          const content = msg.content || '(empty response)';
          lines.push(`    <div class="message"><strong>${msg.sender}:</strong> ${this.escapeHtml(content)}</div>`);
          
          // Show validation results if present
          if (msg.validationResult) {
            const valClass = msg.validationResult.passed ? 'passed' : 'failed';
            lines.push(`    <div class="validation ${valClass}">`);
            lines.push(`      <strong>Validation:</strong> ${msg.validationResult.passed ? '✓ PASSED' : '✗ FAILED'}<br>`);
            
            if (msg.validationResult.expected) {
              lines.push(`      <strong>Expected:</strong> ${this.escapeHtml(msg.validationResult.expected)}<br>`);
            }
            
            if (msg.validationResult.actual) {
              lines.push(`      <strong>Actual:</strong> ${this.escapeHtml(msg.validationResult.actual)}<br>`);
            }
            
            if (msg.validationResult.message) {
              lines.push(`      <strong>Message:</strong> ${this.escapeHtml(msg.validationResult.message)}`);
            }
            
            lines.push('    </div>');
          }
        }
      }

      lines.push('  </div>');
    }

    lines.push('</body>');
    lines.push('</html>');

    return lines.join('\n');
  }

  /**
   * Escape HTML special characters and format for display
   */
  private escapeHtml(text: string): string {
    // Only escape the truly dangerous characters for XSS
    const map: Record<string, string> = {
      '&': '&amp;',
      '<': '&lt;',
      '>': '&gt;',
      '"': '&quot;'
    };
    
    // Escape HTML special characters (but not apostrophes - they're safe in content)
    let escaped = text.replace(/[&<>"]/g, m => map[m]);
    
    // Convert newlines to <br> tags
    escaped = escaped.replace(/\n/g, '<br>');
    
    return escaped;
  }

  /**
   * Format as Markdown
   */
  private formatMarkdown(report: TestReport): string {
    const lines: string[] = [
      '# Patience Test Report',
      '',
      '## Summary',
      '',
      `- **Generated:** ${report.timestamp.toISOString()}`,
      `- **Total Scenarios:** ${report.totalScenarios}`,
      `- **Passed:** ${report.passedScenarios} ✅`,
      `- **Failed:** ${report.failedScenarios} ❌`,
      '',
      '## Scenarios',
      ''
    ];

    for (const scenario of report.scenarioResults) {
      const status = scenario.passed ? '✅ PASSED' : '❌ FAILED';
      lines.push(`### ${scenario.scenarioName} - ${status}`);
      lines.push('');
      lines.push(`- **ID:** ${scenario.scenarioId}`);
      lines.push(`- **Duration:** ${scenario.duration}ms`);

      if (scenario.error) {
        lines.push(`- **Error:** ${scenario.error.message}`);
      }

      if (scenario.conversationHistory.messages.length > 0) {
        lines.push('');
        lines.push('#### Conversation:');
        lines.push('');
        for (const msg of scenario.conversationHistory.messages) {
          lines.push(`- **${msg.sender}:** ${msg.content}`);
        }
      }

      lines.push('');
    }

    return lines.join('\n');
  }
}
