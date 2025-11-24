/**
 * Adversarial Test Orchestrator - Main entry point for adversarial testing
 */

import { AdversarialTestConfig, ConversationResult, AdversarialBotConnector } from './types';
import { OllamaConnector } from './connectors/OllamaConnector';
import { OpenAIConnector } from './connectors/OpenAIConnector';
import { AnthropicConnector } from './connectors/AnthropicConnector';
import { createStrategy } from './strategies/PromptStrategy';
import { ConversationManager } from './ConversationManager';
import { ConversationLogger } from './ConversationLogger';
import { ProtocolAdapter, HTTPAdapter, WebSocketAdapter } from '../communication';

export class AdversarialTestOrchestrator {
  private config: AdversarialTestConfig;
  private adversarialBot!: AdversarialBotConnector;
  private targetBot!: ProtocolAdapter;

  constructor(config: AdversarialTestConfig) {
    this.config = config;
  }

  /**
   * Run adversarial tests
   */
  async run(): Promise<ConversationResult[]> {
    console.log('\n🚀 Starting Adversarial Testing');
    console.log('='.repeat(60));
    
    // Validate configuration
    this.validateConfig();

    // Initialize connectors
    await this.initializeConnectors();

    try {
      // Run conversations
      const results = await this.runConversations();

      // Save results
      await this.saveResults(results);

      // Print summary
      this.printSummary(results);

      return results;
    } finally {
      // Clean up
      await this.cleanup();
    }
  }

  /**
   * Validate configuration
   */
  private validateConfig(): void {
    const errors: string[] = [];

    // Validate target bot
    if (!this.config.targetBot.endpoint) {
      errors.push('Target bot endpoint is required');
    }

    // Validate adversarial bot
    if (!this.config.adversarialBot.provider) {
      errors.push('Adversarial bot provider is required');
    }

    // Validate conversation parameters
    if (this.config.conversation.maxTurns <= 0) {
      errors.push('Max turns must be greater than 0');
    }

    // Validate execution parameters
    if (this.config.execution.numConversations <= 0) {
      errors.push('Number of conversations must be greater than 0');
    }

    if (errors.length > 0) {
      throw new Error(`Configuration validation failed:\n${errors.join('\n')}`);
    }
  }

  /**
   * Initialize bot connectors
   */
  private async initializeConnectors(): Promise<void> {
    console.log('\n📡 Initializing connectors...');

    // Initialize adversarial bot
    this.adversarialBot = this.createAdversarialBotConnector();
    await this.adversarialBot.initialize(this.config.adversarialBot);
    console.log(`✓ Adversarial bot: ${this.adversarialBot.getName()}`);

    // Initialize target bot
    this.targetBot = this.createTargetBotConnector();
    const botConfig: any = {
      name: this.config.targetBot.name,
      protocol: this.config.targetBot.protocol,
      endpoint: this.config.targetBot.endpoint,
      authentication: this.config.targetBot.authentication,
      headers: this.config.targetBot.headers,
    };
    await this.targetBot.connect(botConfig);
    console.log(`✓ Target bot: ${this.config.targetBot.name}`);
  }

  /**
   * Create adversarial bot connector based on provider
   */
  private createAdversarialBotConnector(): AdversarialBotConnector {
    switch (this.config.adversarialBot.provider) {
      case 'ollama':
        return new OllamaConnector();
      case 'openai':
        return new OpenAIConnector();
      case 'anthropic':
        return new AnthropicConnector();
      case 'custom':
        throw new Error('Custom connector not yet implemented');
      default:
        throw new Error(`Unknown provider: ${this.config.adversarialBot.provider}`);
    }
  }

  /**
   * Create target bot connector based on protocol
   */
  private createTargetBotConnector(): ProtocolAdapter {
    switch (this.config.targetBot.protocol) {
      case 'http':
        return new HTTPAdapter();
      case 'websocket':
        return new WebSocketAdapter();
      default:
        throw new Error(`Unknown protocol: ${this.config.targetBot.protocol}`);
    }
  }

  /**
   * Run all conversations
   */
  private async runConversations(): Promise<ConversationResult[]> {
    const results: ConversationResult[] = [];
    const numConversations = this.config.execution.numConversations;
    const concurrent = this.config.execution.concurrent || 1;

    console.log(`\n💬 Running ${numConversations} conversation(s) with concurrency ${concurrent}`);

    for (let i = 0; i < numConversations; i += concurrent) {
      const batch: Promise<ConversationResult>[] = [];

      for (let j = 0; j < concurrent && i + j < numConversations; j++) {
        const conversationNum = i + j + 1;
        console.log(`\n--- Starting conversation ${conversationNum}/${numConversations} ---`);
        
        batch.push(this.runSingleConversation());
      }

      const batchResults = await Promise.all(batch);
      results.push(...batchResults);

      // Delay between batches if configured
      if (i + concurrent < numConversations && this.config.execution.delayBetweenConversations) {
        console.log(`\nWaiting ${this.config.execution.delayBetweenConversations}ms before next batch...`);
        await this.delay(this.config.execution.delayBetweenConversations);
      }
    }

    return results;
  }

  /**
   * Run a single conversation
   */
  private async runSingleConversation(): Promise<ConversationResult> {
    const strategy = createStrategy(this.config);
    
    const manager = new ConversationManager(
      this.adversarialBot,
      this.targetBot,
      strategy,
      this.config
    );

    return await manager.startConversation();
  }

  /**
   * Save conversation results
   */
  private async saveResults(results: ConversationResult[]): Promise<void> {
    console.log(`\n💾 Saving results...`);

    const outputPath = this.config.reporting.outputPath;
    const formats: Array<'json' | 'text' | 'csv'> = this.config.reporting.includeTranscripts 
      ? ['json', 'text', 'csv']
      : ['json'];

    for (const result of results) {
      const savedFiles = await ConversationLogger.saveAll(
        result,
        outputPath,
        formats
      );

      if (this.config.reporting.realTimeMonitoring) {
        console.log(`✓ Saved conversation ${result.conversationId}:`);
        savedFiles.forEach(file => console.log(`  - ${file}`));
      }
    }

    console.log(`✓ All results saved to ${outputPath}`);
  }

  /**
   * Print summary of results
   */
  private printSummary(results: ConversationResult[]): void {
    console.log('\n' + '='.repeat(60));
    console.log('📊 ADVERSARIAL TESTING SUMMARY');
    console.log('='.repeat(60));

    const totalConversations = results.length;
    const totalTurns = results.reduce((sum, r) => sum + r.turns, 0);
    const avgTurns = totalTurns / totalConversations;
    const totalDuration = results.reduce((sum, r) => sum + r.duration, 0);
    const avgDuration = totalDuration / totalConversations;

    const allValidations = results.flatMap(r => r.validationResults);
    const overallPassRate = allValidations.length > 0
      ? allValidations.filter(v => v.passed).length / allValidations.length
      : 1.0;

    const avgResponseTime = results.reduce((sum, r) => sum + r.metrics.avgResponseTime, 0) / totalConversations;
    const avgQuality = results.reduce((sum, r) => sum + r.metrics.conversationQuality, 0) / totalConversations;

    console.log(`\nTotal Conversations: ${totalConversations}`);
    console.log(`Total Turns: ${totalTurns}`);
    console.log(`Avg Turns/Conversation: ${avgTurns.toFixed(1)}`);
    console.log(`Total Duration: ${(totalDuration / 1000).toFixed(2)}s`);
    console.log(`Avg Duration/Conversation: ${(avgDuration / 1000).toFixed(2)}s`);
    console.log(`\nValidation Pass Rate: ${(overallPassRate * 100).toFixed(1)}%`);
    console.log(`Avg Response Time: ${avgResponseTime.toFixed(0)}ms`);
    console.log(`Avg Conversation Quality: ${(avgQuality * 100).toFixed(1)}%`);

    // Termination reasons
    console.log(`\nTermination Reasons:`);
    const reasons = results.reduce((acc, r) => {
      acc[r.terminationReason] = (acc[r.terminationReason] || 0) + 1;
      return acc;
    }, {} as Record<string, number>);

    Object.entries(reasons).forEach(([reason, count]) => {
      console.log(`  ${reason}: ${count}`);
    });

    console.log('\n' + '='.repeat(60));
    console.log('✅ Adversarial testing complete!');
    console.log('='.repeat(60) + '\n');
  }

  /**
   * Clean up resources
   */
  private async cleanup(): Promise<void> {
    if (this.adversarialBot) {
      await this.adversarialBot.disconnect();
    }
    if (this.targetBot) {
      await this.targetBot.disconnect();
    }
  }

  /**
   * Delay helper
   */
  private async delay(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }
}
