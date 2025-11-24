/**
 * Type definitions for Chat Log Analysis
 */

// ============================================================================
// Log Format Types
// ============================================================================

export type LogFormat = 'json' | 'csv' | 'text' | 'auto';

export interface RawLogData {
  content: string | object;
  format: LogFormat;
  metadata: {
    fileSize: number;
    lineCount?: number;
    encoding: string;
  };
}

// ============================================================================
// Parsed Conversation Types
// ============================================================================

export interface ParsedConversation {
  id: string;
  messages: ConversationMessage[];
  metadata: {
    startTime?: Date;
    endTime?: Date;
    userId?: string;
    sessionId?: string;
    source?: string;
  };
}

export interface ConversationMessage {
  sender: 'user' | 'bot';
  content: string;
  timestamp: Date;
  metadata?: Record<string, any>;
}

// ============================================================================
// Filter Types
// ============================================================================

export interface FilterCriteria {
  dateRange?: {
    start: Date;
    end: Date;
  };
  minMessages?: number;
  maxMessages?: number;
  userIds?: string[];
  sessionIds?: string[];
  containsText?: string;
  customFilter?: (conv: ParsedConversation) => boolean;
}

// ============================================================================
// Analysis Configuration Types
// ============================================================================

export interface AnalysisConfiguration {
  logSource: {
    path: string;
    format: LogFormat;
  };
  filters?: FilterCriteria;
  validation?: {
    rules: import('../../types').ValidationCriteria[];
    stopOnFirstFailure?: boolean;
  };
  analysis: {
    calculateMetrics: boolean;
    detectPatterns: boolean;
    checkContextRetention: boolean;
  };
  reporting: {
    outputPath: string;
    formats: ReportFormat[];
    includeDetailedResults: boolean;
  };
  performance?: {
    streamingMode: boolean;
    batchSize?: number;
    maxMemoryMB?: number;
  };
}

// ============================================================================
// Analysis Results Types
// ============================================================================

export interface AnalysisResults {
  summary: AnalysisSummary;
  validationResults: ConversationValidationResult[];
  metrics?: AnalysisMetrics;
  patterns?: DetectedPattern[];
  contextAnalysis?: ContextAnalysisResult[];
}

export interface AnalysisSummary {
  totalConversations: number;
  analyzedConversations: number;
  filteredOut: number;
  overallPassRate: number;
  processingTime: number;
}

export interface ConversationValidationResult {
  conversationId: string;
  totalMessages: number;
  botMessages: number;
  validatedMessages: number;
  passedValidations: number;
  failedValidations: number;
  validationDetails: MessageValidationResult[];
}

export interface MessageValidationResult {
  messageIndex: number;
  content: string;
  validationResults: import('../../types').ValidationResult[];
  overallPassed: boolean;
}

// ============================================================================
// Metrics Types
// ============================================================================

export interface AnalysisMetrics {
  totalConversations: number;
  totalMessages: number;
  averageMessagesPerConversation: number;
  averageConversationDuration?: number;
  validationPassRate: number;
  botResponseRate: number;
  timeDistribution?: {
    hourOfDay: Record<number, number>;
    dayOfWeek: Record<string, number>;
  };
  messageLengthStats: {
    min: number;
    max: number;
    average: number;
    median: number;
  };
}

// ============================================================================
// Pattern Detection Types
// ============================================================================

export interface DetectedPattern {
  type: 'failure' | 'success' | 'anomaly';
  pattern: string;
  frequency: number;
  examples: string[];
  severity?: 'low' | 'medium' | 'high';
  description: string;
}

// ============================================================================
// Context Analysis Types
// ============================================================================

export interface ContextAnalysisResult {
  conversationId: string;
  hasMultipleTurns: boolean;
  contextRetentionScore: number;
  contextBreaks: ContextBreak[];
  overallQuality: 'poor' | 'fair' | 'good' | 'excellent';
}

export interface ContextBreak {
  messageIndex: number;
  reason: string;
  severity: 'minor' | 'major';
}

// ============================================================================
// Report Types
// ============================================================================

export type ReportFormat = 'json' | 'html' | 'markdown' | 'csv';

export interface AnalysisReport {
  timestamp: Date;
  summary: AnalysisSummary;
  metrics: AnalysisMetrics;
  patterns: DetectedPattern[];
  detailedResults: ConversationValidationResult[];
}
