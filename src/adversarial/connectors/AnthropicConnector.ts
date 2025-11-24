/**
 * Anthropic connector for Claude models
 */

import Anthropic from '@anthropic-ai/sdk';
import { BaseConnector, ExponentialBackoff, RateLimiter } from './BaseConnector';
import { Message, ConversationContext, AdversarialTestConfig } from '../types';

export class AnthropicConnector extends BaseConnector {
  private client!: Anthropic;
  private model!: string;
  private temperature!: number;
  private maxTokens!: number;
  private backoff: ExponentialBackoff;
  private rateLimiter: RateLimiter;

  constructor() {
    super();
    this.backoff = new ExponentialBackoff(3, 1000, 10000);
    this.rateLimiter = new RateLimiter(50, 60000); // 50 requests per minute
  }

  async initialize(config: AdversarialTestConfig['adversarialBot']): Promise<void> {
    this.config = config;

    if (!config.apiKey) {
      throw new Error('Anthropic API key is required. Set it in config.adversarialBot.apiKey');
    }

    this.model = config.model || 'claude-3-sonnet-20240229';
    this.temperature = config.temperature ?? 0.7;
    this.maxTokens = config.maxTokens || 1024;

    this.client = new Anthropic({
      apiKey: config.apiKey,
    });

    // Test connection
    try {
      await this.testConnection();
      this.initialized = true;
      console.log(`✓ Connected to Anthropic with model ${this.model}`);
    } catch (error) {
      throw new Error(`Failed to connect to Anthropic: ${error}`);
    }
  }

  async generateMessage(
    conversationHistory: Message[],
    systemPrompt: string,
    context?: ConversationContext
  ): Promise<string> {
    this.ensureInitialized();

    // Wait for rate limiter
    await this.rateLimiter.waitIfNeeded();

    const messages = this.buildMessages(conversationHistory, context);
    const systemPromptWithContext = this.buildSystemPrompt(systemPrompt, context);

    try {
      const response = await this.backoff.execute(async () => {
        const message = await this.client.messages.create({
          model: this.model,
          max_tokens: this.maxTokens,
          temperature: this.temperature,
          system: systemPromptWithContext,
          messages,
        });
        return message;
      });

      // Extract text content from response
      const textContent = response.content.find((block) => block.type === 'text');
      if (!textContent || textContent.type !== 'text') {
        throw new Error('No text content in Anthropic response');
      }

      return textContent.text.trim();
    } catch (error: any) {
      if (error.status === 401) {
        throw new Error('Invalid Anthropic API key');
      }
      if (error.status === 429) {
        throw new Error('Anthropic rate limit exceeded. Please wait and try again.');
      }
      if (error.status === 404) {
        throw new Error(`Model '${this.model}' not found or not accessible with your API key`);
      }
      throw new Error(`Anthropic API error: ${error.message}`);
    }
  }

  async disconnect(): Promise<void> {
    // Anthropic client doesn't require explicit disconnection
    this.initialized = false;
  }

  getName(): string {
    return `Anthropic (${this.model})`;
  }

  /**
   * Test connection to Anthropic
   */
  private async testConnection(): Promise<void> {
    try {
      // Make a minimal test request
      await this.client.messages.create({
        model: this.model,
        max_tokens: 10,
        messages: [{ role: 'user', content: 'test' }],
      });
    } catch (error: any) {
      if (error.status === 401) {
        throw new Error('Invalid API key');
      }
      if (error.status === 404) {
        throw new Error(`Model '${this.model}' not found or not accessible`);
      }
      throw error;
    }
  }

  /**
   * Build messages array for Anthropic API
   * Note: Anthropic requires alternating user/assistant messages
   */
  private buildMessages(
    conversationHistory: Message[],
    context?: ConversationContext
  ): Anthropic.MessageParam[] {
    const messages: Anthropic.MessageParam[] = [];

    // Add conversation history
    // Anthropic requires messages to alternate between user and assistant
    for (const msg of conversationHistory) {
      messages.push({
        role: msg.role === 'adversarial' ? 'assistant' : 'user',
        content: msg.content,
      });
    }

    return messages;
  }

  /**
   * Build system prompt with context
   */
  private buildSystemPrompt(systemPrompt: string, context?: ConversationContext): string {
    if (!context) {
      return systemPrompt;
    }

    const instructions: string[] = [systemPrompt];

    // Add turn information
    instructions.push(`\nTurn ${context.turnNumber}`);

    // Add validation feedback
    const recentFailures = context.validationResults.slice(-3).filter((r) => !r.passed);

    if (recentFailures.length >= 2) {
      instructions.push(
        '\nNote: The bot has failed validation on recent responses. ' +
          'Consider exploring this area further or trying a different approach.'
      );
    }

    // Add goal reminders
    if (context.goals && context.goals.length > 0) {
      instructions.push(`\nRemember your goals: ${context.goals.join(', ')}`);
    }

    return instructions.join('\n');
  }
}
