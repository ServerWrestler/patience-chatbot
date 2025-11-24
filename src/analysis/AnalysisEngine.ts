/**
 * Analysis Engine - Orchestrates the complete analysis pipeline
 */

import { LogLoader } from './LogLoader';
import { JsonLogParser, CsvLogParser, TextLogParser } from './parsers';
import { ConversationFilter } from './ConversationFilter';
import { ValidationAnalyzer } from './ValidationAnalyzer';
import { MetricsCalculator } from './MetricsCalculator';
import { PatternDetector } from './PatternDetector';
import { ContextAnalyzer } from './ContextAnalyzer';
import { AnalysisConfiguration, AnalysisResults, AnalysisSummary, ParsedConversation } from './types';

export class AnalysisEngine {
  private logLoader: LogLoader;
  private filter: ConversationFilter;
  private validationAnalyzer: ValidationAnalyzer;
  private metricsCalculator: MetricsCalculator;
  private patternDetector: PatternDetector;
  private contextAnalyzer: ContextAnalyzer;

  constructor() {
    this.logLoader = new LogLoader();
    this.filter = new ConversationFilter();
    this.validationAnalyzer = new ValidationAnalyzer();
    this.metricsCalculator = new MetricsCalculator();
    this.patternDetector = new PatternDetector();
    this.contextAnalyzer = new ContextAnalyzer();
  }

  /**
   * Run complete analysis pipeline
   */
  async analyze(config: AnalysisConfiguration): Promise<AnalysisResults> {
    const startTime = Date.now();

    try {
      // Step 1: Load log file
      console.log(`Loading log file: ${config.logSource.path}`);
      const rawData = await this.logLoader.loadLog(
        config.logSource.path,
        config.logSource.format
      );

      // Step 2: Parse conversations
      console.log(`Parsing ${rawData.format} format...`);
      const parser = this.getParser(rawData.format);
      const allConversations = await parser.parse(rawData);
      console.log(`Parsed ${allConversations.length} conversations`);

      // Step 3: Filter conversations
      let conversations = allConversations;
      if (config.filters) {
        console.log('Applying filters...');
        conversations = this.filter.filter(allConversations, config.filters);
        console.log(`${conversations.length} conversations after filtering`);
      }

      // Step 4: Run validation if configured
      let validationResults = undefined;
      if (config.validation && config.validation.rules.length > 0) {
        console.log('Running validation analysis...');
        validationResults = this.validationAnalyzer.validateConversations(
          conversations,
          config.validation.rules
        );
      }

      // Step 5: Calculate metrics if configured
      let metrics = undefined;
      if (config.analysis.calculateMetrics) {
        console.log('Calculating metrics...');
        metrics = this.metricsCalculator.calculateMetrics(
          conversations,
          validationResults
        );
      }

      // Step 6: Detect patterns if configured
      let patterns = undefined;
      if (config.analysis.detectPatterns && validationResults) {
        console.log('Detecting patterns...');
        patterns = this.patternDetector.detectPatterns(
          conversations,
          validationResults
        );
      }

      // Step 7: Analyze context if configured
      let contextAnalysis = undefined;
      if (config.analysis.checkContextRetention) {
        console.log('Analyzing context retention...');
        contextAnalysis = this.contextAnalyzer.analyzeContextBatch(conversations);
      }

      // Step 8: Generate summary
      const processingTime = Date.now() - startTime;
      const summary = this.generateSummary(
        allConversations.length,
        conversations.length,
        validationResults,
        processingTime
      );

      console.log(`Analysis complete in ${processingTime}ms`);

      return {
        summary,
        validationResults: validationResults || [],
        metrics,
        patterns,
        contextAnalysis
      };
    } catch (error) {
      throw new Error(
        `Analysis failed: ${error instanceof Error ? error.message : 'Unknown error'}`
      );
    }
  }

  /**
   * Get appropriate parser for format
   */
  private getParser(format: string) {
    switch (format) {
      case 'json':
        return new JsonLogParser();
      case 'csv':
        return new CsvLogParser();
      case 'text':
        return new TextLogParser();
      default:
        throw new Error(`Unsupported format: ${format}`);
    }
  }

  /**
   * Generate analysis summary
   */
  private generateSummary(
    totalConversations: number,
    analyzedConversations: number,
    validationResults: any[] | undefined,
    processingTime: number
  ): AnalysisSummary {
    let overallPassRate = 0;

    if (validationResults && validationResults.length > 0) {
      const summary = this.validationAnalyzer.getValidationSummary(validationResults);
      overallPassRate = summary.passRate;
    }

    return {
      totalConversations,
      analyzedConversations,
      filteredOut: totalConversations - analyzedConversations,
      overallPassRate,
      processingTime
    };
  }

  /**
   * Validate configuration before analysis
   */
  validateConfiguration(config: AnalysisConfiguration): { valid: boolean; errors: string[] } {
    const errors: string[] = [];

    // Check log source
    if (!config.logSource.path) {
      errors.push('Log source path is required');
    }

    if (!config.logSource.format) {
      errors.push('Log source format is required');
    }

    // Check validation rules
    if (config.validation && config.validation.rules.length === 0) {
      errors.push('Validation is enabled but no rules provided');
    }

    // Check reporting
    if (!config.reporting.outputPath) {
      errors.push('Reporting output path is required');
    }

    if (config.reporting.formats.length === 0) {
      errors.push('At least one report format is required');
    }

    return {
      valid: errors.length === 0,
      errors
    };
  }
}
