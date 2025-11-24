# Design: Adversarial Chatbot Testing

## Architecture Overview

The adversarial testing system orchestrates conversations between two bots: an adversarial bot (powered by an LLM) and the target bot being tested. The system manages turn-taking, logs conversations, applies validation, and generates reports.

```
┌─────────────────────────────────────────────────────────────┐
│                  Adversarial Test Orchestrator              │
│  ┌─────────────────────────────────────────────────────┐   │
│  │         Conversation Manager                        │   │
│  │  - Turn management                                  │   │
│  │  - Context tracking                                 │   │
│  │  - Termination logic                                │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌──────────────────┐              ┌──────────────────┐   │
│  │ Adversarial Bot  │◄────────────►│   Target Bot     │   │
│  │   Connector      │              │   Connector      │   │
│  │                  │              │                  │   │
│  │ - OpenAI         │              │ - HTTP           │   │
│  │ - Anthropic      │              │ - WebSocket      │   │
│  │ - Ollama         │              │ - Custom         │   │
│  │ - Custom         │              │                  │   │
│  └──────────────────┘              └──────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │         Validation & Analysis                       │   │
│  │  - Real-time validation                             │   │
│  │  - Metrics tracking                                 │   │
│  │  - Pattern detection                                │   │
│  └─────────────────────────────────────────────────────┘   │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │         Logging & Reporting                         │   │
│  │  - Conversation logger                              │   │
│  │  - Report generator                                 │   │
│  │  - Real-time monitoring                             │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

## Core Components

### 1. Adversarial Bot Connectors

Abstract interface for different LLM providers:

```typescript
interface AdversarialBotConnector {
  // Initialize connection
  initialize(config: AdversarialBotConfig): Promise<void>;
  
  // Generate next message based on conversation history
  generateMessage(
    conversationHistory: Message[],
    systemPrompt: string,
    context?: ConversationContext
  ): Promise<string>;
  
  // Check if bot wants to end conversation
  shouldEndConversation(
    conversationHistory: Message[]
  ): Promise<boolean>;
  
  // Clean up resources
  disconnect(): Promise<void>;
}
```

**Implementations:**
- `OpenAIConnector`: Uses OpenAI API (GPT-4, GPT-3.5)
- `AnthropicConnector`: Uses Anthropic API (Claude)
- `OllamaConnector`: Connects to local Ollama instance
- `CustomConnector`: Generic HTTP/WebSocket connector

### 2. Conversation Manager

Orchestrates the bot-to-bot conversation:

```typescript
class ConversationManager {
  private adversarialBot: AdversarialBotConnector;
  private targetBot: BotConnector; // Reuse existing connector
  private conversationHistory: Message[];
  private validator: ResponseValidator;
  private logger: ConversationLogger;
  
  async startConversation(
    config: AdversarialTestConfig
  ): Promise<ConversationResult>;
  
  private async executeTurn(): Promise<TurnResult>;
  
  private shouldTerminate(): boolean;
  
  private async validateResponse(
    response: string
  ): Promise<ValidationResult>;
}
```

**Responsibilities:**
- Initialize both bot connectors
- Manage turn-taking loop
- Track conversation state
- Apply validation rules
- Log all interactions
- Handle errors and timeouts
- Determine conversation termination

### 3. Prompt Strategy System

Manages adversarial bot behavior:

```typescript
interface PromptStrategy {
  // Generate system prompt for adversarial bot
  getSystemPrompt(config: AdversarialBotConfig): string;
  
  // Generate instructions for next turn
  getNextTurnInstructions(
    conversationHistory: Message[],
    validationResults: ValidationResult[]
  ): string;
  
  // Determine if conversation goals are met
  isGoalAchieved(
    conversationHistory: Message[],
    validationResults: ValidationResult[]
  ): boolean;
}
```

**Strategy Implementations:**
- `ExploratoryStrategy`: Broad, diverse questions
- `AdversarialStrategy`: Edge cases, contradictions, confusion
- `FocusedStrategy`: Test specific features or domains
- `StressStrategy`: Rapid context switching, complex inputs
- `CustomStrategy`: User-defined behavior

### 4. Conversation Logger

Logs all conversation data:

```typescript
class ConversationLogger {
  private conversationId: string;
  private messages: LoggedMessage[];
  private metadata: ConversationMetadata;
  
  logMessage(
    role: 'adversarial' | 'target',
    content: string,
    metadata?: MessageMetadata
  ): void;
  
  logValidation(
    messageId: string,
    result: ValidationResult
  ): void;
  
  logMetric(
    name: string,
    value: number | string
  ): void;
  
  async save(
    format: 'json' | 'text' | 'csv'
  ): Promise<string>;
}
```

### 5. Adversarial Report Generator

Generates comprehensive reports:

```typescript
class AdversarialReportGenerator {
  generateReport(
    conversations: ConversationResult[],
    config: ReportConfig
  ): AdversarialReport;
  
  formatReport(
    report: AdversarialReport,
    format: 'html' | 'json' | 'markdown' | 'csv'
  ): string;
  
  private generateSummary(
    conversations: ConversationResult[]
  ): ReportSummary;
  
  private analyzePatterns(
    conversations: ConversationResult[]
  ): PatternAnalysis;
  
  private generateRecommendations(
    conversations: ConversationResult[]
  ): string[];
}
```

## Data Models

### Configuration

```typescript
interface AdversarialTestConfig {
  // Target bot configuration
  targetBot: {
    name: string;
    protocol: 'http' | 'websocket';
    endpoint: string;
    authentication?: AuthConfig;
  };
  
  // Adversarial bot configuration
  adversarialBot: {
    provider: 'openai' | 'anthropic' | 'ollama' | 'custom';
    model?: string; // e.g., 'gpt-4', 'claude-3', 'llama2'
    apiKey?: string;
    endpoint?: string; // For Ollama or custom
    temperature?: number;
    maxTokens?: number;
  };
  
  // Conversation parameters
  conversation: {
    strategy: 'exploratory' | 'adversarial' | 'focused' | 'stress' | 'custom';
    maxTurns: number;
    startingPrompts?: string[];
    systemPrompt?: string;
    goals?: string[];
    timeout?: number;
  };
  
  // Validation rules
  validation?: {
    rules: ValidationRule[];
    realTime: boolean;
  };
  
  // Execution parameters
  execution: {
    numConversations: number;
    concurrent?: number;
    delayBetweenTurns?: number;
    delayBetweenConversations?: number;
  };
  
  // Rate limiting and safety
  safety?: {
    maxCostUSD?: number;
    maxRequestsPerMinute?: number;
    contentFilter?: boolean;
  };
  
  // Reporting
  reporting: {
    outputPath: string;
    formats: ('html' | 'json' | 'markdown' | 'csv')[];
    includeTranscripts: boolean;
    realTimeMonitoring: boolean;
  };
}
```

### Conversation Result

```typescript
interface ConversationResult {
  conversationId: string;
  timestamp: Date;
  config: AdversarialTestConfig;
  
  // Conversation data
  messages: Message[];
  turns: number;
  duration: number; // milliseconds
  
  // Validation results
  validationResults: ValidationResult[];
  passRate: number;
  
  // Metrics
  metrics: {
    avgResponseTime: number;
    targetBotResponseRate: number;
    conversationQuality: number;
  };
  
  // Termination info
  terminationReason: 'max_turns' | 'goal_achieved' | 'timeout' | 'error' | 'manual';
  
  // Analysis
  patterns?: DetectedPattern[];
  contextAnalysis?: ContextAnalysis;
}
```

### Message

```typescript
interface Message {
  id: string;
  role: 'adversarial' | 'target';
  content: string;
  timestamp: Date;
  metadata?: {
    responseTime?: number;
    tokenCount?: number;
    cost?: number;
  };
}
```

## Conversation Flow

### Standard Flow

1. **Initialization**
   - Load configuration
   - Initialize adversarial bot connector
   - Initialize target bot connector
   - Set up logging and monitoring

2. **Conversation Loop**
   ```
   For each turn (up to maxTurns):
     1. Adversarial bot generates message
        - Include conversation history
        - Apply strategy-specific instructions
        - Check for termination intent
     
     2. Send message to target bot
        - Use existing BotConnector
        - Track response time
        - Handle errors/timeouts
     
     3. Receive target bot response
        - Log response
        - Apply validation rules
        - Update metrics
     
     4. Check termination conditions
        - Max turns reached?
        - Goal achieved?
        - Error occurred?
        - Adversarial bot wants to end?
     
     5. If not terminating, continue to next turn
   ```

3. **Completion**
   - Save conversation log
   - Generate validation report
   - Update aggregate metrics
   - Clean up resources

### Parallel Conversations

For multiple concurrent conversations:

```typescript
async function runParallelConversations(
  config: AdversarialTestConfig
): Promise<ConversationResult[]> {
  const conversations = [];
  const concurrency = config.execution.concurrent || 1;
  
  for (let i = 0; i < config.execution.numConversations; i += concurrency) {
    const batch = [];
    for (let j = 0; j < concurrency && i + j < config.execution.numConversations; j++) {
      batch.push(runSingleConversation(config));
    }
    const results = await Promise.all(batch);
    conversations.push(...results);
    
    // Delay between batches
    if (config.execution.delayBetweenConversations) {
      await delay(config.execution.delayBetweenConversations);
    }
  }
  
  return conversations;
}
```

## Prompt Engineering

### System Prompt Template

```typescript
function generateSystemPrompt(config: AdversarialTestConfig): string {
  const basePrompt = `You are an adversarial testing bot designed to test another chatbot.

Your role: ${config.conversation.strategy === 'adversarial' 
  ? 'Challenge the bot with edge cases, ambiguous questions, and contradictions'
  : 'Explore the bot\'s capabilities through diverse, realistic questions'}

Target bot: ${config.targetBot.name}

Conversation goals:
${config.conversation.goals?.map(g => `- ${g}`).join('\n') || '- Thoroughly test the bot\'s capabilities'}

Guidelines:
- Ask one question or make one statement per turn
- Be natural and conversational
- ${config.conversation.strategy === 'adversarial' 
    ? 'Try to find weaknesses, edge cases, and limitations'
    : 'Explore different topics and conversation styles'}
- When you feel the conversation has achieved its goals, say "CONVERSATION_COMPLETE"

Remember: You are testing the bot, not having a genuine conversation.`;

  if (config.conversation.systemPrompt) {
    return config.conversation.systemPrompt + '\n\n' + basePrompt;
  }
  
  return basePrompt;
}
```

### Adaptive Prompting

```typescript
function generateTurnInstructions(
  conversationHistory: Message[],
  validationResults: ValidationResult[]
): string {
  const recentFailures = validationResults.slice(-3).filter(r => !r.passed);
  
  if (recentFailures.length >= 2) {
    return `The bot has failed validation on recent responses. Focus on this area to identify the issue.`;
  }
  
  if (conversationHistory.length > 5) {
    return `You've had ${conversationHistory.length} turns. Consider wrapping up or exploring a new angle.`;
  }
  
  return `Continue testing the bot's capabilities.`;
}
```

## Integration Points

### Reuse Existing Components

- **BotConnector**: Reuse for target bot communication
- **ResponseValidator**: Apply validation rules
- **ReportGenerator**: Extend for adversarial reports
- **ConversationFilter**: Filter adversarial logs for analysis
- **AnalysisEngine**: Analyze adversarial conversation logs

### New Components

- **AdversarialBotConnector**: New abstraction for LLM providers
- **ConversationManager**: New orchestration layer
- **PromptStrategy**: New strategy system
- **AdversarialReportGenerator**: Extends existing reporting

## CLI Design

```bash
# Basic usage
patience adversarial --config adversarial-config.json

# Quick start with defaults
patience adversarial --target http://localhost:3000/chat --adversary openai

# Specify parameters
patience adversarial \
  --target http://localhost:3000/chat \
  --adversary ollama \
  --model llama2 \
  --strategy adversarial \
  --turns 20 \
  --conversations 10

# Interactive mode
patience adversarial --config config.json --interactive

# Batch mode with specific output
patience adversarial --config config.json --output ./results --format html
```

## Error Handling

### Adversarial Bot Errors
- API rate limits → Backoff and retry
- Invalid API key → Fail fast with clear error
- Network errors → Retry with exponential backoff
- Timeout → Log and continue to next turn

### Target Bot Errors
- No response → Log failure, continue conversation
- Invalid response → Log and validate as failure
- Connection lost → Attempt reconnection, then fail conversation

### System Errors
- Out of memory → Reduce concurrent conversations
- Disk full → Fail with clear error
- Cost limit reached → Stop gracefully, generate reports

## Performance Considerations

- **Rate Limiting**: Respect API limits for external LLMs
- **Concurrency**: Limit parallel conversations to avoid overwhelming target bot
- **Memory**: Stream logs to disk for long conversations
- **Cost**: Track and limit API usage costs
- **Timeouts**: Set reasonable timeouts for both bots

## Security Considerations

- **API Keys**: Store securely, never log
- **Content Filtering**: Prevent inappropriate content generation
- **Data Privacy**: Option to redact sensitive information from logs
- **Access Control**: Validate target bot endpoints
- **Cost Protection**: Hard limits on API spending

## Testing Strategy

1. **Unit Tests**: Test each connector independently
2. **Integration Tests**: Test conversation flow with mock bots
3. **End-to-End Tests**: Test with real Ollama instance (local)
4. **Manual Tests**: Verify with OpenAI/Anthropic (with test API keys)

## Success Metrics

- Successfully complete bot-to-bot conversations
- Generate diverse, realistic test scenarios
- Identify target bot weaknesses
- Produce actionable reports
- Handle errors gracefully
- Respect rate limits and cost constraints
