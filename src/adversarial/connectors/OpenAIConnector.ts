/**
 * OpenAI connector for GPT models
 */

import OpenAI from 'openai';
import { BaseConnector, ExponentialBackoff, RateLimiter } from './BaseConnector';
import { Message, ConversationContext, AdversarialTestConfig } from '../types';

export class OpenAIConnector extends BaseConnector {
  private client!: OpenAI;
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
      throw new Error('OpenAI API key is required. Set it in config.adversarialBot.apiKey');
    }

    this.model = config.model || 'gpt-4';
    this.temperature = config.temperature ?? 0.7;
    this.maxTokens = config.maxTokens || 500;

    this.client = new OpenAI({
      apiKey: config.apiKey,
    });

    // Test connection
    try {
      await this.testConnection();
      this.initialized = true;
      console.log(`✓ Connected to OpenAI with model ${this.model}`);
    } catch (error) {
      throw new Error(`Failed to connect to OpenAI: ${error}`);
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

    const messages = this.buildMessages(conversationHistory, systemPrompt, context);

    try {
      const response = await this.backoff.execute(async () => {
        const completion = await this.client.chat.completions.create({
          model: this.model,
          messages,
          temperature: this.temperature,
          max_tokens: this.maxTokens,
        });
        return completion;
      });

      const content = response.choices[0]?.message?.content;
      if (!content) {
        throw new Error('No content in OpenAI response');
      }

      return content.trim();
    } catch (error: any) {
      if (error.status === 401) {
        throw new Error('Invalid OpenAI API key');
      }
      if (error.status === 429) {
        throw new Error('OpenAI rate limit exceeded. Please wait and try again.');
      }
      if (error.status === 404) {
        throw new Error(`Model '${this.model}' not found or not accessible with your API key`);
      }
      throw new Error(`OpenAI API error: ${error.message}`);
    }
  }

  async disconnect(): Promise<void> {
    // OpenAI client doesn't require explicit disconnection
    this.initialized = false;
  }

  getName(): string {
    return `OpenAI (${this.model})`;
  }

  /**
   * Test connection to OpenAI
   */
  private async testConnection(): Promise<void> {
    try {
      // Make a minimal test request
      await this.client.chat.completions.create({
        model: this.model,
        messages: [{ role: 'user', content: 'test' }],
        max_tokens: 5,
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
   * Build messages array for OpenAI API
   */
  private buildMessages(
    conversationHistory: Message[],
    systemPrompt: string,
    context?: ConversationContext
  ): OpenAI.Chat.ChatCompletionMessageParam[] {
    const messages: OpenAI.Chat.ChatCompletionMessageParam[] = [];

    // Add system prompt
    messages.push({
      role: 'system',
      content: systemPrompt,
    });

    // Add conversation history
    for (const msg of conversationHistory) {
      messages.push({
        role: msg.role === 'adversarial' ? 'assistant' : 'user',
        content: msg.content,
      });
    }

    // Add context-specific instructions if provided
    if (context) {
      const instructions = this.buildContextInstructions(context);
      if (instructions) {
        messages.push({
          role: 'system',
          content: instructions,
        });
      }
    }

    return messages;
  }

  /**
   * Build additional instructions based on context
   */
  private buildContextInstructions(context: ConversationContext): string | null {
    const instructions: string[] = [];

    // Add turn information
    instructions.push(`Turn ${context.turnNumber}`);

    // Add validation feedback
    const recentFailures = context.validationResults.slice(-3).filter((r) => !r.passed);

    if (recentFailures.length >= 2) {
      instructions.push(
        'Note: The bot has failed validation on recent responses. ' +
          'Consider exploring this area further or trying a different approach.'
      );
    }

    // Add goal reminders
    if (context.goals && context.goals.length > 0) {
      instructions.push(`Remember your goals: ${context.goals.join(', ')}`);
    }

    return instructions.length > 0 ? instructions.join('\n') : null;
  }
}
