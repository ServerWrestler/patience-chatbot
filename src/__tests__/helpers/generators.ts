/**
 * Fast-check generators for property-based testing
 */

import * as fc from 'fast-check';
import { 
  BotConfig, 
  Scenario, 
  ConversationStep, 
  BotResponse,
  TestConfig,
  MessageType,
  ValidationType
} from '../../types';

/**
 * Generate a valid bot config
 */
export const botConfigGenerator = (): fc.Arbitrary<BotConfig> => {
  return fc.record({
    name: fc.string({ minLength: 1, maxLength: 50 }),
    protocol: fc.constantFrom('http' as const, 'websocket' as const),
    endpoint: fc.webUrl(),
    headers: fc.option(fc.dictionary(fc.string(), fc.string()), { nil: undefined })
  });
};

/**
 * Generate a conversation step
 */
export const conversationStepGenerator = (): fc.Arbitrary<ConversationStep> => {
  return fc.record({
    message: fc.string({ minLength: 1, maxLength: 200 }),
    delay: fc.option(fc.nat(5000), { nil: undefined })
  });
};

/**
 * Generate a scenario
 */
export const scenarioGenerator = (): fc.Arbitrary<Scenario> => {
  return fc.record({
    id: fc.uuid(),
    name: fc.string({ minLength: 1, maxLength: 100 }),
    steps: fc.array(conversationStepGenerator(), { minLength: 1, maxLength: 10 }),
    expectedOutcomes: fc.constant([])
  });
};

/**
 * Generate a bot response
 */
export const botResponseGenerator = (): fc.Arbitrary<BotResponse> => {
  return fc.record({
    content: fc.oneof(
      fc.string({ minLength: 0, maxLength: 500 }),
      fc.object() as fc.Arbitrary<object>
    ),
    timestamp: fc.date(),
    metadata: fc.option(fc.dictionary(fc.string(), fc.anything()), { nil: undefined })
  });
};

/**
 * Generate a message type
 */
export const messageTypeGenerator = (): fc.Arbitrary<MessageType> => {
  return fc.constantFrom('question' as const, 'statement' as const, 'command' as const, 'random' as const);
};

/**
 * Generate a validation type
 */
export const validationTypeGenerator = (): fc.Arbitrary<ValidationType> => {
  return fc.constantFrom('exact' as const, 'pattern' as const, 'semantic' as const);
};

/**
 * Generate a test config
 */
export const testConfigGenerator = (): fc.Arbitrary<TestConfig> => {
  return fc.record({
    targetBot: botConfigGenerator(),
    scenarios: fc.array(scenarioGenerator(), { minLength: 1, maxLength: 5 }),
    validation: fc.record({
      defaultType: validationTypeGenerator(),
      semanticSimilarityThreshold: fc.option(fc.double({ min: 0, max: 1 }), { nil: undefined })
    }),
    timing: fc.record({
      enableDelays: fc.boolean(),
      baseDelay: fc.nat(1000),
      delayPerCharacter: fc.nat(100),
      rapidFire: fc.boolean(),
      responseTimeout: fc.integer({ min: 1000, max: 30000 })
    }),
    reporting: fc.record({
      outputPath: fc.string({ minLength: 1 }),
      formats: fc.array(fc.constantFrom('json' as const, 'html' as const, 'markdown' as const), { minLength: 1 }),
      includeConversationHistory: fc.boolean(),
      verboseErrors: fc.boolean()
    })
  });
};

/**
 * Generate a string message
 */
export const messageGenerator = (): fc.Arbitrary<string> => {
  return fc.string({ minLength: 1, maxLength: 200 });
};

/**
 * Generate varying length messages
 */
export const varyingLengthMessageGenerator = (): fc.Arbitrary<string[]> => {
  return fc.array(
    fc.string({ minLength: 1, maxLength: 500 }),
    { minLength: 2, maxLength: 10 }
  );
};
