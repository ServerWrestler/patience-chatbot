/**
 * Core type definitions for the Patience chat bot testing system
 */

// ============================================================================
// Configuration Types
// ============================================================================

export interface TestConfig {
  targetBot: BotConfig;
  scenarios: Scenario[];
  validation: ValidationConfig;
  timing: TimingConfig;
  reporting: ReportConfig;
}

export interface BotConfig {
  name: string;
  protocol: 'http' | 'websocket';
  endpoint: string;
  authentication?: AuthConfig;
  headers?: Record<string, string>;
  provider?: 'ollama' | 'generic';
  model?: string;
}

export interface AuthConfig {
  type: 'bearer' | 'basic' | 'apikey';
  credentials: string | { username: string; password: string };
}

export interface ValidationConfig {
  defaultType: ValidationType;
  semanticSimilarityThreshold?: number;
  customValidators?: Record<string, CustomValidator>;
}

export interface TimingConfig {
  enableDelays: boolean;
  baseDelay: number;
  delayPerCharacter: number;
  rapidFire: boolean;
  responseTimeout: number;
}

export interface ReportConfig {
  outputPath: string;
  formats: Array<'json' | 'html' | 'markdown'>;
  includeConversationHistory: boolean;
  verboseErrors: boolean;
}

// ============================================================================
// Scenario Types
// ============================================================================

export interface Scenario {
  id: string;
  name: string;
  description?: string;
  steps: ConversationStep[];
  expectedOutcomes: ValidationCriteria[];
}

export interface ConversationStep {
  message: string | MessageGeneratorConfig;
  expectedResponse?: ResponseCriteria;
  conditionalBranches?: ConditionalBranch[];
  delay?: number;
}

export interface ConditionalBranch {
  condition: Condition;
  nextStep: ConversationStep;
}

export interface Condition {
  type: 'contains' | 'matches' | 'equals' | 'custom';
  value: string | RegExp;
  customEvaluator?: (response: BotResponse) => boolean;
}

export interface MessageGeneratorConfig {
  type: MessageType;
  constraints?: GenerationConstraints;
}

export type MessageType = 'question' | 'statement' | 'command' | 'random';

export interface GenerationConstraints {
  minLength?: number;
  maxLength?: number;
  includeSpecialChars?: boolean;
  topic?: string;
}

// ============================================================================
// Response Types
// ============================================================================

export interface BotResponse {
  content: string | object;
  timestamp: Date;
  metadata?: Record<string, any>;
  error?: Error;
  responseTime?: number;
}

export interface ResponseCriteria {
  validationType: ValidationType;
  expected: string | RegExp;
  threshold?: number;
}

export type ValidationType = 'exact' | 'pattern' | 'semantic' | 'custom';

// ============================================================================
// Validation Types
// ============================================================================

export interface ValidationCriteria {
  type: ValidationType;
  expected: string | RegExp | CustomValidator;
  threshold?: number;
  description?: string;
}

export interface ValidationResult {
  passed: boolean;
  expected?: string;
  actual: string;
  message?: string;
  details?: Record<string, any>;
}

export type CustomValidator = (response: BotResponse) => ValidationResult;

// ============================================================================
// Conversation History Types
// ============================================================================

export interface ConversationHistory {
  sessionId: string;
  messages: ConversationMessage[];
  startTime: Date;
  endTime: Date;
}

export interface ConversationMessage {
  sender: 'patience' | 'target';
  content: string;
  timestamp: Date;
  validationResult?: ValidationResult;
}

// ============================================================================
// Test Results Types
// ============================================================================

export interface TestResults {
  testRunId: string;
  startTime: Date;
  endTime: Date;
  scenarioResults: ScenarioResult[];
  summary: TestSummary;
}

export interface ScenarioResult {
  scenarioId: string;
  scenarioName: string;
  passed: boolean;
  conversationHistory: ConversationHistory;
  validationResults: ValidationResult[];
  duration: number;
  error?: Error;
}

export interface TestSummary {
  total: number;
  passed: number;
  failed: number;
}

// ============================================================================
// Report Types
// ============================================================================

export interface TestReport {
  timestamp: Date;
  totalScenarios: number;
  passedScenarios: number;
  failedScenarios: number;
  scenarioResults: ScenarioResult[];
  summary: string;
}

export interface SummaryReport {
  testRuns: TestReport[];
  aggregatedSummary: TestSummary;
  generatedAt: Date;
}

// ============================================================================
// Context Types
// ============================================================================

export interface TestContext {
  sessionId: string;
  scenarioId: string;
  currentStep: number;
  conversationHistory: ConversationHistory;
  state: Record<string, any>;
}

// Export response builder utilities
export * from './ResponseBuilder';
export * from './ResponseParser';
export * from './ResponseStorage';
