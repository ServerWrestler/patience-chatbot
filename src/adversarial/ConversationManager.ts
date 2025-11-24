/**
 * Conversation Manager - Orchestrates bot-to-bot conversations
 */

import { v4 as uuidv4 } from 'uuid';
import {
  AdversarialBotConnector,
  AdversarialTestConfig,
  Message,
  ConversationResult,
  TurnResult,
  TerminationReason,
  ConversationContext,
} from './types';
import { PromptStrategy } from './strategies/PromptStrategy';
import { ProtocolAdapter } from '../communication';
import { ResponseValidator } from '../validation';
import { ValidationResult, ValidationCriteria, BotResponse } from '../types';

export class ConversationManager {
  private adversarialBot: AdversarialBotConnector;
  private targetBot: ProtocolAdapter;
  private strategy: PromptStrategy;
  private validationRules?: ValidationCriteria[];
  private config: AdversarialTestConfig;

  private conversationId: string;
  private conversationHistory: Message[] = [];
  private validationResults: ValidationResult[] = [];
  private startTime!: Date;

  constructor(
    adversarialBot: AdversarialBotConnector,
    targetBot: ProtocolAdapter,
    strategy: PromptStrategy,
    config: AdversarialTestConfig
  ) {
    this.adversarialBot = adversarialBot;
    this.targetBot = targetBot;
    this.strategy = strategy;
    this.config = config;
    this.conversationId = uuidv4();

    // Store validation rules if provided
    if (config.validation && config.validation.rules.length > 0) {
      this.validationRules = config.validation.rules;
    }
  }

  /**
   * Start and manage the conversation
   */
  async startConversation(): Promise<ConversationResult> {
    this.startTime = new Date();
    console.log(`\n${'='.repeat(60)}`);
    console.log(`Starting conversation: ${this.conversationId}`);
    console.log(`Strategy: ${this.strategy.getName()}`);
    console.log(`Max turns: ${this.config.conversation.maxTurns}`);
    console.log(`${'='.repeat(60)}\n`);

    let terminationReason: TerminationReason = 'max_turns';
    let terminationMessage: string | undefined;

    try {
      // Get starting prompt
      const startingPrompt = this.getStartingPrompt();
      
      // Main conversation loop
      for (let turn = 0; turn < this.config.conversation.maxTurns; turn++) {
        if (this.config.reporting.realTimeMonitoring) {
          console.log(`\n--- Turn ${turn + 1} ---`);
        }

        const turnResult = await this.executeTurn(turn);

        if (!turnResult.shouldContinue) {
          terminationReason = 'adversarial_ended';
          terminationMessage = 'Adversarial bot ended conversation';
          break;
        }

        // Check if goals are achieved
        if (this.strategy.isGoalAchieved(this.conversationHistory, this.validationResults)) {
          terminationReason = 'goal_achieved';
          terminationMessage = 'Conversation goals achieved';
          break;
        }

        // Delay between turns if configured
        if (this.config.execution.delayBetweenTurns) {
          await this.delay(this.config.execution.delayBetweenTurns);
        }
      }
    } catch (error: any) {
      terminationReason = 'error';
      terminationMessage = error.message;
      console.error(`\n❌ Conversation error: ${error.message}`);
    }

    const endTime = new Date();
    const duration = endTime.getTime() - this.startTime.getTime();

    console.log(`\n${'='.repeat(60)}`);
    console.log(`Conversation ended: ${terminationReason}`);
    if (terminationMessage) {
      console.log(`Reason: ${terminationMessage}`);
    }
    console.log(`Total turns: ${this.conversationHistory.length / 2}`);
    console.log(`Duration: ${(duration / 1000).toFixed(2)}s`);
    console.log(`${'='.repeat(60)}\n`);

    return this.buildResult(duration, terminationReason, terminationMessage);
  }

  /**
   * Execute a single turn of conversation
   */
  private async executeTurn(turnNumber: number): Promise<TurnResult> {
    const context: ConversationContext = {
      conversationId: this.conversationId,
      turnNumber: turnNumber + 1,
      validationResults: this.validationResults,
      goals: this.config.conversation.goals,
    };

    // 1. Adversarial bot generates message
    const systemPrompt = this.strategy.getSystemPrompt(this.config);
    const adversarialContent = await this.adversarialBot.generateMessage(
      this.conversationHistory,
      systemPrompt,
      context
    );

    const adversarialMessage: Message = {
      id: uuidv4(),
      role: 'adversarial',
      content: adversarialContent,
      timestamp: new Date(),
    };

    this.conversationHistory.push(adversarialMessage);

    if (this.config.reporting.realTimeMonitoring) {
      console.log(`\n🤖 Adversarial: ${adversarialContent}`);
    }

    // Check if adversarial bot wants to end
    const shouldEnd = await this.adversarialBot.shouldEndConversation(
      this.conversationHistory
    );

    if (shouldEnd) {
      return {
        adversarialMessage,
        targetMessage: adversarialMessage, // Dummy
        shouldContinue: false,
      };
    }

    // 2. Send to target bot
    const targetStartTime = Date.now();
    let targetContent: string;
    
    try {
      const response = await this.targetBot.sendMessage(adversarialContent);
      // Extract content from BotResponse
      targetContent = typeof response.content === 'string' 
        ? response.content 
        : JSON.stringify(response.content);
    } catch (error: any) {
      targetContent = `[ERROR: ${error.message}]`;
    }

    const targetResponseTime = Date.now() - targetStartTime;

    const targetMessage: Message = {
      id: uuidv4(),
      role: 'target',
      content: targetContent,
      timestamp: new Date(),
      metadata: {
        responseTime: targetResponseTime,
      },
    };

    this.conversationHistory.push(targetMessage);

    if (this.config.reporting.realTimeMonitoring) {
      console.log(`🎯 Target: ${targetContent}`);
    }

    // 3. Validate target response if validation rules are configured
    let validationResult: ValidationResult | undefined;
    if (this.validationRules && this.config.validation?.realTime) {
      // Create a validator instance for this response
      const validator = new ResponseValidator();
      const botResponse: BotResponse = {
        content: targetContent,
        timestamp: new Date(),
        responseTime: targetResponseTime,
      };
      
      // Validate against each rule and use the first one
      validationResult = validator.validate(botResponse, this.validationRules[0]);
      this.validationResults.push(validationResult);

      if (this.config.reporting.realTimeMonitoring) {
        const status = validationResult.passed ? '✓' : '✗';
        console.log(`${status} Validation: ${validationResult.passed ? 'PASS' : 'FAIL'}`);
        if (!validationResult.passed && validationResult.message) {
          console.log(`  Reason: ${validationResult.message}`);
        }
      }
    }

    return {
      adversarialMessage,
      targetMessage,
      validationResult,
      shouldContinue: true,
    };
  }

  /**
   * Get starting prompt for the conversation
   */
  private getStartingPrompt(): string {
    if (this.config.conversation.startingPrompts && 
        this.config.conversation.startingPrompts.length > 0) {
      const prompts = this.config.conversation.startingPrompts;
      return prompts[Math.floor(Math.random() * prompts.length)];
    }
    return 'Hello! I would like to learn about your capabilities.';
  }

  /**
   * Build the final conversation result
   */
  private buildResult(
    duration: number,
    terminationReason: TerminationReason,
    terminationMessage?: string
  ): ConversationResult {
    const turns = Math.floor(this.conversationHistory.length / 2);
    
    // Calculate metrics
    const targetMessages = this.conversationHistory.filter(m => m.role === 'target');
    const avgResponseTime = targetMessages.length > 0
      ? targetMessages.reduce((sum, m) => sum + (m.metadata?.responseTime || 0), 0) / targetMessages.length
      : 0;

    const targetBotResponseRate = targetMessages.length / turns;

    const passRate = this.validationResults.length > 0
      ? this.validationResults.filter(r => r.passed).length / this.validationResults.length
      : 1.0;

    // Simple conversation quality score (0-1)
    const conversationQuality = (
      (targetBotResponseRate * 0.4) +
      (passRate * 0.4) +
      (Math.min(turns / 10, 1) * 0.2)
    );

    return {
      conversationId: this.conversationId,
      timestamp: this.startTime,
      config: this.config,
      messages: this.conversationHistory,
      turns,
      duration,
      validationResults: this.validationResults,
      passRate,
      metrics: {
        avgResponseTime,
        targetBotResponseRate,
        conversationQuality,
      },
      terminationReason,
      terminationMessage,
    };
  }

  /**
   * Delay helper
   */
  private async delay(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }
}
