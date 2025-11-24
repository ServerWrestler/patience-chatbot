/**
 * Base utilities for adversarial bot connectors
 */

import { AdversarialBotConnector, Message } from '../types';

export abstract class BaseConnector implements AdversarialBotConnector {
  protected config: any;
  protected initialized: boolean = false;

  abstract initialize(config: any): Promise<void>;
  abstract generateMessage(
    conversationHistory: Message[],
    systemPrompt: string,
    context?: any
  ): Promise<string>;
  abstract disconnect(): Promise<void>;
  abstract getName(): string;

  /**
   * Check if the bot wants to end the conversation
   * Default implementation looks for termination keywords
   */
  async shouldEndConversation(conversationHistory: Message[]): Promise<boolean> {
    if (conversationHistory.length === 0) {
      return false;
    }

    const lastMessage = conversationHistory[conversationHistory.length - 1];
    if (lastMessage.role !== 'adversarial') {
      return false;
    }

    const content = lastMessage.content.toLowerCase();
    const terminationKeywords = [
      'conversation_complete',
      'test_complete',
      'ending conversation',
      'goodbye',
    ];

    return terminationKeywords.some(keyword => content.includes(keyword));
  }

  /**
   * Format conversation history for LLM context
   */
  protected formatConversationHistory(messages: Message[]): string {
    return messages
      .map(msg => {
        const role = msg.role === 'adversarial' ? 'You' : 'Bot';
        return `${role}: ${msg.content}`;
      })
      .join('\n');
  }

  /**
   * Ensure connector is initialized
   */
  protected ensureInitialized(): void {
    if (!this.initialized) {
      throw new Error(`${this.getName()} connector not initialized. Call initialize() first.`);
    }
  }

  /**
   * Delay helper for rate limiting
   */
  protected async delay(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }
}

/**
 * Rate limiter utility
 */
export class RateLimiter {
  private requests: number[] = [];
  private maxRequests: number;
  private windowMs: number;

  constructor(maxRequests: number, windowMs: number = 60000) {
    this.maxRequests = maxRequests;
    this.windowMs = windowMs;
  }

  async waitIfNeeded(): Promise<void> {
    const now = Date.now();
    
    // Remove old requests outside the window
    this.requests = this.requests.filter(time => now - time < this.windowMs);

    if (this.requests.length >= this.maxRequests) {
      // Calculate wait time
      const oldestRequest = this.requests[0];
      const waitTime = this.windowMs - (now - oldestRequest) + 100; // Add 100ms buffer
      
      if (waitTime > 0) {
        console.log(`Rate limit reached. Waiting ${waitTime}ms...`);
        await new Promise(resolve => setTimeout(resolve, waitTime));
      }
    }

    this.requests.push(Date.now());
  }
}

/**
 * Exponential backoff utility
 */
export class ExponentialBackoff {
  private attempt: number = 0;
  private maxAttempts: number;
  private baseDelay: number;
  private maxDelay: number;

  constructor(maxAttempts: number = 5, baseDelay: number = 1000, maxDelay: number = 30000) {
    this.maxAttempts = maxAttempts;
    this.baseDelay = baseDelay;
    this.maxDelay = maxDelay;
  }

  async execute<T>(fn: () => Promise<T>): Promise<T> {
    while (true) {
      try {
        const result = await fn();
        this.attempt = 0; // Reset on success
        return result;
      } catch (error) {
        this.attempt++;
        
        if (this.attempt >= this.maxAttempts) {
          throw new Error(`Failed after ${this.maxAttempts} attempts: ${error}`);
        }

        const delay = Math.min(
          this.baseDelay * Math.pow(2, this.attempt - 1),
          this.maxDelay
        );

        console.log(`Attempt ${this.attempt} failed. Retrying in ${delay}ms...`);
        await new Promise(resolve => setTimeout(resolve, delay));
      }
    }
  }

  reset(): void {
    this.attempt = 0;
  }
}
