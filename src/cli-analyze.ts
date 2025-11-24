#!/usr/bin/env node

/**
 * CLI for Chat Log Analysis
 */

import { AnalysisEngine } from './analysis/AnalysisEngine';
import { AnalysisReportGenerator } from './analysis/AnalysisReportGenerator';
import { AnalysisConfiguration } from './analysis/types';
import * as fs from 'fs/promises';
import * as path from 'path';

/**
 * Parse command line arguments for analyze command
 */
function parseAnalyzeArgs(): {
  logPath?: string;
  configPath?: string;
  format?: string;
  outputPath?: string;
  reportFormat?: string;
  help: boolean;
} {
  const args = process.argv.slice(3); // Skip node, script, and 'analyze'
  const result: any = {
    help: false,
    format: 'auto',
    outputPath: './analysis-reports',
    reportFormat: 'html'
  };

  for (let i = 0; i < args.length; i++) {
    const arg = args[i];

    if (arg === '--help' || arg === '-h') {
      result.help = true;
    } else if (arg === '--log' || arg === '-l') {
      result.logPath = args[++i];
    } else if (arg === '--config' || arg === '-c') {
      result.configPath = args[++i];
    } else if (arg === '--format' || arg === '-f') {
      result.format = args[++i];
    } else if (arg === '--output' || arg === '-o') {
      result.outputPath = args[++i];
    } else if (arg === '--report-format' || arg === '-r') {
      result.reportFormat = args[++i];
    } else if (!result.logPath) {
      result.logPath = arg;
    }
  }

  return result;
}

/**
 * Display help for analyze command
 */
function showAnalyzeHelp(): void {
  console.log(`
Patience - Chat Log Analysis

Usage:
  patience analyze [options] <log-file>

Options:
  -l, --log <file>           Path to log file to analyze
  -c, --config <file>        Path to analysis configuration file
  -f, --format <format>      Log format: json, csv, text, auto (default: auto)
  -o, --output <path>        Output directory for reports (default: ./analysis-reports)
  -r, --report-format <fmt>  Report format: json, html, markdown, csv (default: html)
  -h, --help                 Show this help message

Examples:
  # Analyze a JSON log file
  patience analyze conversations.json

  # Analyze with specific format
  patience analyze --format csv conversations.csv

  # Use configuration file
  patience analyze --config analysis-config.json

  # Generate markdown report
  patience analyze --report-format markdown conversations.json

Configuration File Format:
  {
    "logSource": {
      "path": "conversations.json",
      "format": "json"
    },
    "filters": {
      "dateRange": {
        "start": "2025-01-01T00:00:00Z",
        "end": "2025-01-31T23:59:59Z"
      },
      "minMessages": 3
    },
    "validation": {
      "rules": [
        {
          "type": "pattern",
          "expected": "thank|help|assist"
        }
      ]
    },
    "analysis": {
      "calculateMetrics": true,
      "detectPatterns": true,
      "checkContextRetention": true
    },
    "reporting": {
      "outputPath": "./reports",
      "formats": ["html", "json"],
      "includeDetailedResults": true
    }
  }
  `);
}

/**
 * Create default analysis configuration
 */
function createDefaultConfig(logPath: string, format: string): AnalysisConfiguration {
  return {
    logSource: {
      path: logPath,
      format: format as any
    },
    analysis: {
      calculateMetrics: true,
      detectPatterns: true,
      checkContextRetention: true
    },
    reporting: {
      outputPath: './analysis-reports',
      formats: ['html'],
      includeDetailedResults: true
    }
  };
}

/**
 * Main analyze function
 */
async function analyzeCommand(): Promise<void> {
  const args = parseAnalyzeArgs();

  if (args.help) {
    showAnalyzeHelp();
    process.exit(0);
  }

  // Determine configuration
  let config: AnalysisConfiguration;

  if (args.configPath) {
    // Load from config file
    console.log(`Loading configuration from: ${args.configPath}`);
    const configContent = await fs.readFile(args.configPath, 'utf-8');
    config = JSON.parse(configContent);
  } else if (args.logPath) {
    // Create default config
    config = createDefaultConfig(args.logPath, args.format!);
    config.reporting.outputPath = args.outputPath!;
    config.reporting.formats = [args.reportFormat as any];
  } else {
    console.error('Error: Log file path is required');
    console.error('Use --help for usage information');
    process.exit(1);
  }

  try {
    console.log('Chat Log Analysis');
    console.log('==================\n');

    // Validate configuration
    const engine = new AnalysisEngine();
    const validation = engine.validateConfiguration(config);
    
    if (!validation.valid) {
      console.error('Configuration validation failed:');
      validation.errors.forEach(err => console.error(`  - ${err}`));
      process.exit(1);
    }

    // Run analysis
    console.log('Starting analysis...\n');
    const results = await engine.analyze(config);

    // Generate reports
    console.log('\nGenerating reports...');
    const reportGenerator = new AnalysisReportGenerator();
    const report = reportGenerator.generateReport(results);

    // Create output directory
    await fs.mkdir(config.reporting.outputPath, { recursive: true });

    // Save reports in configured formats
    for (const format of config.reporting.formats) {
      const formatted = reportGenerator.formatReport(report, format);
      const extension = format === 'markdown' ? 'md' : format;
      const filename = `analysis-report-${Date.now()}.${extension}`;
      const filepath = path.join(config.reporting.outputPath, filename);
      
      await fs.writeFile(filepath, formatted, 'utf-8');
      console.log(`✓ Report saved: ${filepath}`);
    }

    // Display summary
    console.log('\n' + '='.repeat(50));
    console.log('Analysis Summary');
    console.log('='.repeat(50));
    console.log(`Total Conversations: ${results.summary.totalConversations}`);
    console.log(`Analyzed: ${results.summary.analyzedConversations}`);
    console.log(`Pass Rate: ${(results.summary.overallPassRate * 100).toFixed(1)}%`);
    console.log(`Processing Time: ${results.summary.processingTime}ms`);

    if (results.metrics) {
      console.log(`\nTotal Messages: ${results.metrics.totalMessages}`);
      console.log(`Avg Messages/Conv: ${results.metrics.averageMessagesPerConversation.toFixed(2)}`);
    }

    if (results.patterns && results.patterns.length > 0) {
      console.log(`\nPatterns Detected: ${results.patterns.length}`);
      results.patterns.slice(0, 3).forEach(p => {
        console.log(`  - ${p.type}: ${p.pattern} (${p.frequency}x)`);
      });
    }

    console.log('');
    process.exit(0);

  } catch (error) {
    console.error('\nError:', error instanceof Error ? error.message : 'Unknown error');
    if (error instanceof Error && error.stack) {
      console.error('\nStack trace:');
      console.error(error.stack);
    }
    process.exit(1);
  }
}

// Run if executed directly
if (require.main === module) {
  analyzeCommand();
}

export { analyzeCommand };
