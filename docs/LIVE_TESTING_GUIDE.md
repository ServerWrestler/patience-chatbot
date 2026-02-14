# Live Testing Guide

Test your chatbot with predefined conversation scenarios.

## Quick Start

1. Open Patience → **Testing** tab
2. Click **"New Configuration"**
3. Enter your bot's endpoint URL
4. Add scenarios with expected responses
5. Click **"Run Tests"**

## Bot Configuration

| Field | Description | Example |
|-------|-------------|---------|
| **Bot Name** | Friendly identifier | "Customer Support Bot" |
| **Endpoint URL** | HTTP endpoint | `http://localhost:3000/chat` |
| **Protocol** | HTTP or WebSocket | HTTP |
| **Provider** | Generic, Ollama, OpenAI, Anthropic | Generic |

### Authentication (Optional)
- **Bearer**: `Authorization: Bearer <token>`
- **API Key**: `X-API-Key: <key>`
- **Basic**: Base64 encoded credentials

> Credentials stored securely in macOS Keychain.

## Creating Scenarios

A scenario contains:
- **Name**: Descriptive test name
- **Steps**: Messages to send with expected responses
- **Expected Outcomes**: Overall conversation validations

### Conversation Steps vs Expected Outcomes

**Steps**: Validate each individual bot response
```
Step 1: Send "Hi" → Expect "hello|hi|hey"
Step 2: Send "Help" → Expect "assist|help"
```

**Outcomes**: Validate the entire conversation
```
"Bot should maintain friendly tone throughout"
```

## Validation Types

| Type | Use Case | Example |
|------|----------|---------|
| **Pattern** | Flexible matching | `hello\|hi\|hey` |
| **Exact** | Precise matching | `I don't understand.` |
| **Semantic** | Meaning comparison | `helpful response` |
| **Custom** | Custom logic | Validator name |

### Pattern (Regex) Tips
- Alternatives: `yes|yeah|yep`
- Anything between: `order.*confirmed`
- Case-insensitive: `(?i)thank you`

### Semantic Validation
Enter the expected meaning in plain English. Set threshold (0.0-1.0):
- 0.9 = Very strict
- 0.8 = Recommended
- 0.6 = Loose matching

## Timing Configuration

| Setting | Description | Default |
|---------|-------------|---------|
| **Enable Delays** | Simulate typing speed | On |
| **Base Delay** | Minimum delay (ms) | 1000 |
| **Delay per Character** | Additional delay | 50ms |
| **Response Timeout** | Max wait time | 30000ms |

## Running Tests

1. Select configuration from list
2. Click **"Run Tests"**
3. View progress and results
4. Results saved automatically

## Understanding Results

- **Pass Rate**: Percentage of passed scenarios
- **Conversation History**: All messages exchanged
- **Validation Results**: Each validation with pass/fail

## Sharing Configurations

### Export
- Right-click → **"Export..."** (single config)
- **Export** menu → **"Export All..."** (all configs)

### Import
- **Import** menu → **"Import Configuration..."**
- Configs get new IDs to avoid conflicts

> API keys are never included in exports.

## Troubleshooting

| Problem | Solution |
|---------|----------|
| Connection Failed | Verify endpoint is running, check URL |
| Timeout | Increase Response Timeout in settings |
| Validation Failures | Review actual response, adjust pattern/threshold |
| Auth Failed | Verify credentials, check auth type |

## Related Guides

- [Adversarial Testing Guide](ADVERSARIAL_TESTING_GUIDE.md) - AI-powered testing
- [Log Analysis Guide](LOG_ANALYSIS_GUIDE.md) - Historical analysis (planned)
