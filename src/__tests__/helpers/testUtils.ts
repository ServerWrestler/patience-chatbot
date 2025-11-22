/**
 * Test utilities and helpers
 */

import { BotConfig, BotResponse, Scenario, TestConfig, ConversationStep, ValidationCriteria } from '../../types';
import { ProtocolAdapter } from '../../communication/ProtocolAdapter';

/**
 * Create a mock bot config for testing
 */
export function createMockBotConfig(overrides?: Partial<BotConfig>): BotConfig {
  return {
    name: 'TestBot',
    protocol: 'http',
    endpoint: 'http://localhost:3000',
    ...overrides
  };
}

/**
 * Create a mock test config for testing
 */
export function createMockTestConfig(overrides?: Partial<TestConfig>): TestConfig {
  return {
    targetBot: createMockBotConfig(),
    scenarios: [],
    validation: {
      defaultType: 'exact',
      semanticSimilarityThreshold: 0.7
    },
    timing: {
      enableDelays: false,
      baseDelay: 0,
      delayPerCharacter: 0,
      rapidFire: true,
      responseTimeout: 5000
    },
    reporting: {
      outputPath: './test-reports',
      formats: ['json'],
      includeConversationHistory: true,
      verboseErrors: true
    },
    ...overrides
  };
}

/**
 * Create a mock scenario for testing
 */
export function createMockScenario(overrides?: Partial<Scenario>): Scenario {
  return {
    id: 'test-scenario-1',
    name: 'Test Scenario',
    steps: [
      {
        message: 'Hello',
        expectedResponse: {
          validationType: 'exact',
          expected: 'Hi there!'
        }
      }
    ],
    expectedOutcomes: [],
    ...overrides
  };
}

/**
 * Create a mock bot response
 */
export function createMockResponse(content: string | object, overrides?: Partial<BotResponse>): BotResponse {
  return {
    content,
    timestamp: new Date(),
    ...overrides
  };
}

/**
 * Mock protocol adapter for testing
 */
export class MockProtocolAdapter implements ProtocolAdapter {
  private _connected: boolean = false;
  private responses: BotResponse[] = [];
  private currentResponseIndex: number = 0;
  public sentMessages: string[] = [];

  constructor(responses?: BotResponse[]) {
    if (responses) {
      this.responses = responses;
    }
  }

  async connect(config: BotConfig): Promise<void> {
    this._connected = true;
  }

  async sendMessage(message: string): Promise<BotResponse> {
    this.sentMessages.push(message);
    
    if (this.responses.length > 0) {
      const response = this.responses[this.currentResponseIndex % this.responses.length];
      this.currentResponseIndex++;
      return response;
    }

    return createMockResponse(`Echo: ${message}`);
  }

  async disconnect(): Promise<void> {
    this._connected = false;
  }

  isConnected(): boolean {
    return this._connected;
  }

  setResponses(responses: BotResponse[]): void {
    this.responses = responses;
    this.currentResponseIndex = 0;
  }

  addResponse(response: BotResponse): void {
    this.responses.push(response);
  }

  getSentMessages(): string[] {
    return [...this.sentMessages];
  }

  reset(): void {
    this.sentMessages = [];
    this.currentResponseIndex = 0;
  }
}

/**
 * Delay helper for testing
 */
export function delay(ms: number): Promise<void> {
  return new Promise(resolve => setTimeout(resolve, ms));
}

/**
 * Create a validation criteria
 */
export function createValidationCriteria(
  type: 'exact' | 'pattern' | 'semantic' | 'custom',
  expected: string | RegExp,
  threshold?: number
): ValidationCriteria {
  return {
    type,
    expected,
    threshold
  };
}
