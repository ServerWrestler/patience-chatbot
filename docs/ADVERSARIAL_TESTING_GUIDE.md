# Adversarial Testing Guide

Use AI models to automatically test your chatbot with challenging conversations.

## Why Adversarial Testing?

| Manual Testing | Adversarial Testing |
|----------------|---------------------|
| Limited by human creativity | AI generates unexpected inputs |
| Time-consuming | Automatic scenario generation |
| Tests what you expect | Finds what you don't expect |

## Quick Start

1. Open Patience → **Adversarial** tab
2. Click **"New Configuration"**
3. Configure your target bot endpoint
4. Choose an AI provider (Ollama recommended for starting)
5. Select a testing strategy
6. Click **"Run Test"**

## AI Providers

| Provider | Type | Cost | Setup |
|----------|------|------|-------|
| **Ollama** | Local | Free | Install from [ollama.ai](https://ollama.ai), run `ollama pull llama2` |
| **OpenAI** | Cloud | Paid | Get API key from [platform.openai.com](https://platform.openai.com) |
| **Anthropic** | Cloud | Paid | Get API key from [console.anthropic.com](https://console.anthropic.com) |

> API keys are stored securely in macOS Keychain.

## Testing Strategies

### Exploratory
Discovers bot capabilities with broad, diverse questions.
- Best for: Initial testing, feature discovery

### Adversarial
Finds weaknesses with edge cases and contradictions.
- Best for: Security testing, robustness validation

### Focused
Deep dives into specific features based on defined goals.
- Best for: Feature-specific testing, regression testing

### Stress
Tests limits with rapid context switching and complex scenarios.
- Best for: Performance testing, context retention

## Configuration

### Target Bot
- **Endpoint**: Your chatbot's HTTP endpoint
- **Protocol**: HTTP or WebSocket

### Conversation Settings
- **Strategy**: Testing approach (see above)
- **Max Turns**: Messages per conversation (default: 10)
- **Conversations**: Number of test conversations (default: 5)
- **Goals**: Specific testing objectives (optional)

### Safety Controls
- **Max Cost**: Stop when cost limit reached (default: $1.00)
- **Rate Limit**: Requests per minute (default: 10)
- **Content Filter**: Block inappropriate content

## Writing Effective Goals

**Good goals** (specific):
- "Test order cancellation with invalid order numbers"
- "Verify bot maintains context across 10+ turns"
- "Check handling of contradictory information"

**Poor goals** (vague):
- "Test the bot"
- "Find bugs"

## Understanding Results

Each test shows:
- **Conversations completed**: Total test conversations
- **Issues found**: Potential problems identified
- **Cost**: API cost (for paid providers)
- **Full transcripts**: Complete conversation histories

### Issue Categories

| Category | Severity |
|----------|----------|
| Error Response | High |
| Context Loss | Medium |
| Inconsistency | Medium |
| Unhelpful Response | Low |

## Attack Patterns

For comprehensive security testing prompts based on OWASP LLM Top 10 and MITRE ATLAS, see:

**[Adversarial Testing Prompts Guide](ADVERSARIAL_TESTING_PROMPTS.md)**

## Troubleshooting

| Problem | Solution |
|---------|----------|
| "Connection to AI Provider Failed" | Verify Ollama is running (`ollama serve`) or check API key |
| "Target Bot Not Responding" | Test endpoint manually with curl |
| "Cost Limit Reached" | Reduce conversations/turns or increase limit |

## Related Guides

- [Live Testing Guide](LIVE_TESTING_GUIDE.md) - Manual scenario testing
- [Adversarial Testing Prompts](ADVERSARIAL_TESTING_PROMPTS.md) - OWASP/MITRE attack patterns
