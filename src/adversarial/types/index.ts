/**
 * Type definitions for adversarial chatbot testing
 */

import { ValidationCriteria, ValidationResult } from '../../types';

// ============================================================================
// Configuration Types
// ============================================================================

export interface AdversarialTestConfig {
  // Target bot configuration
  targetBot: {
    name: string;
    protocol: 'http' | 'websocket';
    endpoint: string;
    authentication?: {
      type: 'bearer' | 'basic' | 'custom';
      credentials: string;
    };
    headers?: Record<string, string>;
  };

  // Adversarial bot configuration
  adversarialBot: {
    provider: 'openai' | 'anthropic' | 'ollama' | 'custom';
    model?: string; // e.g., 'gpt-4', 'claude-3', 'llama2'
    apiKey?: string;
    endpoint?: string; // For Ollama or custom
    temperature?: number;
    maxTokens?: number;
  };

  // Conversation parameters
  conversation: {
    strategy: 'exploratory' | 'adversarial' | 'focused' | 'stress' | 'custom';
    maxTurns: number;
    startingPrompts?: string[];
    systemPrompt?: string;
    goals?: string[];
    timeout?: number; // milliseconds
  };

  // Validation rules (optional)
  validation?: {
    rules: ValidationCriteria[];
    realTime: boolean;
  };

  // Execution parameters
  execution: {
    numConversations: number;
    concurrent?: number;
    delayBetweenTurns?: number; // milliseconds
    delayBetweenConversations?: number; // milliseconds
  };

  // Rate limiting and safety
  safety?: {
    maxCostUSD?: number;
    maxRequestsPerMinute?: number;
    contentFilter?: boolean;
  };

  // Reporting
  reporting: {
    outputPath: string;
    formats: ('html' | 'json' | 'markdown' | 'csv')[];
    includeTranscripts: boolean;
    realTimeMonitoring: boolean;
  };
}

// ============================================================================
// Message and Conversation Types
// ============================================================================

export interface Message {
  id: string;
  role: 'adversarial' | 'target';
  content: string;
  timestamp: Date;
  metadata?: {
    responseTime?: number;
    tokenCount?: number;
    cost?: number;
  };
}

export interface ConversationContext {
  conversationId: string;
  turnNumber: number;
  validationResults: ValidationResult[];
  goals?: string[];
}

export interface TurnResult {
  adversarialMessage: Message;
  targetMessage: Message;
  validationResult?: ValidationResult;
  shouldContinue: boolean;
}

export type TerminationReason = 
  | 'max_turns' 
  | 'goal_achieved' 
  | 'timeout' 
  | 'error' 
  | 'manual'
  | 'adversarial_ended';

export interface ConversationResult {
  conversationId: string;
  timestamp: Date;
  config: AdversarialTestConfig;

  // Conversation data
  messages: Message[];
  turns: number;
  duration: number; // milliseconds

  // Validation results
  validationResults: ValidationResult[];
  passRate: number;

  // Metrics
  metrics: {
    avgResponseTime: number;
    targetBotResponseRate: number;
    conversationQuality: number;
  };

  // Termination info
  terminationReason: TerminationReason;
  terminationMessage?: string;

  // Analysis (optional)
  patterns?: any[];
  contextAnalysis?: any;
}

// ============================================================================
// Connector Interfaces
// ============================================================================

export interface AdversarialBotConnector {
  /**
   * Initialize the connector with configuration
   */
  initialize(config: AdversarialTestConfig['adversarialBot']): Promise<void>;

  /**
   * Generate the next message based on conversation history
   */
  generateMessage(
    conversationHistory: Message[],
    systemPrompt: string,
    context?: ConversationContext
  ): Promise<string>;

  /**
   * Check if the bot wants to end the conversation
   */
  shouldEndConversation(conversationHistory: Message[]): Promise<boolean>;

  /**
   * Clean up resources
   */
  disconnect(): Promise<void>;

  /**
   * Get connector name for logging
   */
  getName(): string;
}

// ============================================================================
// Strategy Interfaces
// ============================================================================

export interface PromptStrategy {
  /**
   * Generate system prompt for the adversarial bot
   */
  getSystemPrompt(config: AdversarialTestConfig): string;

  /**
   * Generate instructions for the next turn
   */
  getNextTurnInstructions(
    conversationHistory: Message[],
    validationResults: ValidationResult[]
  ): string;

  /**
   * Determine if conversation goals are met
   */
  isGoalAchieved(
    conversationHistory: Message[],
    validationResults: ValidationResult[]
  ): boolean;

  /**
   * Get strategy name
   */
  getName(): string;
}

// ============================================================================
// Logging Types
// ============================================================================

export interface LoggedMessage extends Message {
  validationResult?: ValidationResult;
}

export interface ConversationMetadata {
  conversationId: string;
  startTime: Date;
  endTime?: Date;
  config: AdversarialTestConfig;
  terminationReason?: TerminationReason;
}

// ============================================================================
// Report Types
// ============================================================================

export interface AdversarialReport {
  summary: {
    totalConversations: number;
    totalTurns: number;
    avgTurnsPerConversation: number;
    totalDuration: number;
    overallPassRate: number;
  };

  conversations: ConversationResult[];

  aggregateMetrics: {
    avgResponseTime: number;
    targetBotResponseRate: number;
    avgConversationQuality: number;
  };

  patterns?: {
    commonFailures: string[];
    successPatterns: string[];
  };

  recommendations?: string[];
}
