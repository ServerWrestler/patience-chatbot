/**
 * Prompt strategies for adversarial testing
 */

import { PromptStrategy, AdversarialTestConfig, Message } from '../types';
import { ValidationResult } from '../../types';

// Re-export PromptStrategy interface
export type { PromptStrategy };

/**
 * Base strategy with common functionality
 */
abstract class BaseStrategy implements PromptStrategy {
  abstract getSystemPrompt(config: AdversarialTestConfig): string;
  abstract getName(): string;

  getNextTurnInstructions(
    conversationHistory: Message[],
    validationResults: ValidationResult[]
  ): string {
    const instructions: string[] = [];

    // Check recent validation failures
    const recentFailures = validationResults.slice(-3).filter(r => !r.passed);
    if (recentFailures.length >= 2) {
      instructions.push(
        'The bot has failed validation on recent responses. ' +
        'Focus on this area to identify the issue.'
      );
    }

    // Suggest wrapping up if conversation is long
    if (conversationHistory.length > 10) {
      instructions.push(
        `You've had ${conversationHistory.length / 2} turns. ` +
        'Consider wrapping up or exploring a new angle.'
      );
    }

    return instructions.join(' ');
  }

  isGoalAchieved(
    conversationHistory: Message[],
    validationResults: ValidationResult[]
  ): boolean {
    // Default: goals achieved if we have enough turns and good validation rate
    if (conversationHistory.length < 10) {
      return false;
    }

    if (validationResults.length === 0) {
      return false;
    }

    const passRate = validationResults.filter(r => r.passed).length / validationResults.length;
    return passRate > 0.8 || passRate < 0.3; // Either very good or very bad
  }
}

/**
 * Exploratory Strategy - Broad, diverse questions to map capabilities
 */
export class ExploratoryStrategy extends BaseStrategy {
  getName(): string {
    return 'Exploratory';
  }

  getSystemPrompt(config: AdversarialTestConfig): string {
    const targetName = config.targetBot.name;
    const goals = config.conversation.goals || [];

    return `You are an exploratory testing bot designed to thoroughly test another chatbot called "${targetName}".

Your role: Explore the bot's capabilities through diverse, realistic questions and conversations.

Testing approach:
- Ask a wide variety of questions across different topics
- Test different conversation styles (casual, formal, technical)
- Explore the bot's knowledge boundaries
- Test multi-turn conversations and context retention
- Be natural and conversational

${goals.length > 0 ? `Specific goals:\n${goals.map(g => `- ${g}`).join('\n')}` : ''}

Guidelines:
- Ask ONE question or make ONE statement per turn
- Be natural and human-like in your communication
- Vary your question types (open-ended, specific, follow-up)
- Test both simple and complex scenarios
- When you feel you've thoroughly explored the bot's capabilities, say "CONVERSATION_COMPLETE"

Remember: You are testing the bot to understand its capabilities and limitations.`;
  }
}

/**
 * Adversarial Strategy - Edge cases, contradictions, and challenging inputs
 */
export class AdversarialStrategy extends BaseStrategy {
  getName(): string {
    return 'Adversarial';
  }

  getSystemPrompt(config: AdversarialTestConfig): string {
    const targetName = config.targetBot.name;
    const goals = config.conversation.goals || [];

    return `You are an adversarial testing bot designed to challenge and test the limits of another chatbot called "${targetName}".

Your role: Find weaknesses, edge cases, and failure modes through challenging interactions.

Testing approach:
- Ask ambiguous or contradictory questions
- Test edge cases and boundary conditions
- Try to confuse the bot with complex scenarios
- Test error handling with unusual inputs
- Challenge the bot's knowledge and reasoning
- Test context switching and memory

${goals.length > 0 ? `Specific goals:\n${goals.map(g => `- ${g}`).join('\n')}` : ''}

Guidelines:
- Ask ONE challenging question or make ONE statement per turn
- Be creative in finding edge cases
- Try different types of challenging inputs:
  * Ambiguous questions
  * Contradictory statements
  * Very long or very short inputs
  * Nonsensical but grammatical sentences
  * Questions with false premises
  * Rapid topic changes
- When you've identified key weaknesses or thoroughly tested the bot, say "CONVERSATION_COMPLETE"

Remember: Your goal is to find limitations, not to have a genuine conversation.`;
  }
}

/**
 * Focused Strategy - Deep dive into specific features or domains
 */
export class FocusedStrategy extends BaseStrategy {
  getName(): string {
    return 'Focused';
  }

  getSystemPrompt(config: AdversarialTestConfig): string {
    const targetName = config.targetBot.name;
    const goals = config.conversation.goals || [];

    if (goals.length === 0) {
      throw new Error('Focused strategy requires specific goals to be defined');
    }

    return `You are a focused testing bot designed to thoroughly test specific features of another chatbot called "${targetName}".

Your role: Deep dive into specific areas to thoroughly test particular capabilities.

Focus areas:
${goals.map(g => `- ${g}`).join('\n')}

Testing approach:
- Stay focused on the specified areas
- Ask progressively more detailed questions
- Test edge cases within the focus area
- Verify consistency across related questions
- Test the depth of knowledge in this domain

Guidelines:
- Ask ONE question per turn related to the focus areas
- Start with basic questions and progress to advanced
- Test both breadth and depth within the focus area
- Verify the bot's responses are consistent
- When you've thoroughly tested the focus areas, say "CONVERSATION_COMPLETE"

Remember: Stay on topic and thoroughly explore the specified areas.`;
  }
}

/**
 * Stress Strategy - Rapid-fire, context switching, complex inputs
 */
export class StressStrategy extends BaseStrategy {
  getName(): string {
    return 'Stress';
  }

  getSystemPrompt(config: AdversarialTestConfig): string {
    const targetName = config.targetBot.name;
    const goals = config.conversation.goals || [];

    return `You are a stress testing bot designed to test another chatbot called "${targetName}" under challenging conditions.

Your role: Test the bot's performance under stress through rapid topic changes, complex inputs, and demanding scenarios.

Testing approach:
- Switch topics frequently and abruptly
- Ask complex, multi-part questions
- Provide very long or very short inputs
- Reference earlier parts of the conversation unexpectedly
- Combine multiple concepts in single questions
- Test the bot's ability to handle cognitive load

${goals.length > 0 ? `Specific goals:\n${goals.map(g => `- ${g}`).join('\n')}` : ''}

Guidelines:
- Ask ONE question per turn, but make it challenging
- Vary your approach: sometimes simple, sometimes complex
- Switch topics without warning
- Test the bot's memory by referencing earlier exchanges
- Use complex sentence structures
- When you've thoroughly stress-tested the bot, say "CONVERSATION_COMPLETE"

Remember: You're testing the bot's robustness and ability to handle difficult scenarios.`;
  }
}

/**
 * Custom Strategy - User-defined behavior
 */
export class CustomStrategy extends BaseStrategy {
  private customSystemPrompt: string;

  constructor(customSystemPrompt: string) {
    super();
    this.customSystemPrompt = customSystemPrompt;
  }

  getName(): string {
    return 'Custom';
  }

  getSystemPrompt(config: AdversarialTestConfig): string {
    return this.customSystemPrompt;
  }
}

/**
 * Factory function to create strategy instances
 */
export function createStrategy(config: AdversarialTestConfig): PromptStrategy {
  switch (config.conversation.strategy) {
    case 'exploratory':
      return new ExploratoryStrategy();
    case 'adversarial':
      return new AdversarialStrategy();
    case 'focused':
      return new FocusedStrategy();
    case 'stress':
      return new StressStrategy();
    case 'custom':
      if (!config.conversation.systemPrompt) {
        throw new Error('Custom strategy requires systemPrompt to be defined');
      }
      return new CustomStrategy(config.conversation.systemPrompt);
    default:
      throw new Error(`Unknown strategy: ${config.conversation.strategy}`);
  }
}
