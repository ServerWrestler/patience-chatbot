/**
 * Ollama connector for local LLM models
 */

import axios, { AxiosInstance } from 'axios';
import { BaseConnector, ExponentialBackoff } from './BaseConnector';
import { Message, ConversationContext, AdversarialTestConfig } from '../types';

export class OllamaConnector extends BaseConnector {
  private client!: AxiosInstance;
  private model!: string;
  private temperature!: number;
  private backoff: ExponentialBackoff;

  constructor() {
    super();
    this.backoff = new ExponentialBackoff(3, 1000, 10000);
  }

  async initialize(config: AdversarialTestConfig['adversarialBot']): Promise<void> {
    this.config = config;
    
    // Default to localhost:11434 (Ollama default)
    const endpoint = config.endpoint || 'http://localhost:11434';
    this.model = config.model || 'llama2';
    this.temperature = config.temperature ?? 0.7;

    this.client = axios.create({
      baseURL: endpoint,
      timeout: 60000, // 60 second timeout
      headers: {
        'Content-Type': 'application/json',
      },
    });

    // Test connection
    try {
      await this.testConnection();
      this.initialized = true;
      console.log(`✓ Connected to Ollama at ${endpoint} with model ${this.model}`);
    } catch (error) {
      throw new Error(`Failed to connect to Ollama: ${error}`);
    }
  }

  async generateMessage(
    conversationHistory: Message[],
    systemPrompt: string,
    context?: ConversationContext
  ): Promise<string> {
    this.ensureInitialized();

    const messages = this.buildMessages(conversationHistory, systemPrompt, context);

    try {
      const response = await this.backoff.execute(async () => {
        const result = await this.client.post('/api/chat', {
          model: this.model,
          messages,
          stream: false,
          options: {
            temperature: this.temperature,
          },
        });
        return result;
      });

      const content = response.data.message?.content;
      if (!content) {
        throw new Error('No content in Ollama response');
      }

      return content.trim();
    } catch (error: any) {
      if (error.response?.status === 404) {
        throw new Error(
          `Model '${this.model}' not found. Pull it with: ollama pull ${this.model}`
        );
      }
      throw new Error(`Ollama API error: ${error.message}`);
    }
  }

  async disconnect(): Promise<void> {
    // Ollama doesn't require explicit disconnection
    this.initialized = false;
  }

  getName(): string {
    return `Ollama (${this.model})`;
  }

  /**
   * Test connection to Ollama
   */
  private async testConnection(): Promise<void> {
    try {
      // Check if Ollama is running
      await this.client.get('/api/tags');
      
      // Check if model is available
      const modelsResponse = await this.client.get('/api/tags');
      const models = modelsResponse.data.models || [];
      const modelExists = models.some((m: any) => m.name.includes(this.model));
      
      if (!modelExists) {
        console.warn(
          `⚠ Model '${this.model}' not found locally. It will be pulled on first use.`
        );
      }
    } catch (error: any) {
      if (error.code === 'ECONNREFUSED') {
        throw new Error(
          'Cannot connect to Ollama. Make sure Ollama is running (ollama serve)'
        );
      }
      throw error;
    }
  }

  /**
   * Build messages array for Ollama API
   */
  private buildMessages(
    conversationHistory: Message[],
    systemPrompt: string,
    context?: ConversationContext
  ): any[] {
    const messages: any[] = [];

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
    const recentFailures = context.validationResults
      .slice(-3)
      .filter(r => !r.passed);
    
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
