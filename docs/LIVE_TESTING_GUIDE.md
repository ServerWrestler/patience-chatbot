# Live Testing Guide

This guide explains how to use Patience's Live Testing feature to test your chatbot with predefined conversation scenarios.

## Overview

Live Testing allows you to create structured test scenarios that simulate real user conversations with your chatbot. You define the messages to send, the expected responses, and how to validate those responses. Patience then executes these scenarios and reports the results.

## Getting Started

### Step 1: Create a New Test Configuration

1. Open Patience and navigate to the **Testing** tab
2. Click the **"New Configuration"** button in the top right
3. The configuration editor will open

### Step 2: Configure Your Bot

In the **Bot Configuration** section:

| Field | Description | Example |
|-------|-------------|---------|
| **Bot Name** | A friendly name for your bot | "Customer Support Bot" |
| **Endpoint URL** | The HTTP endpoint where your bot receives messages | `http://localhost:3000/chat` or `https://api.mybot.com/message` |
| **Protocol** | Communication protocol | HTTP (most common) or WebSocket |
| **Provider** | Bot type for provider-specific handling | Generic, Ollama, OpenAI, or Anthropic |

### Step 3: Configure Authentication (Optional)

If your bot requires authentication:

1. Enable **"Enable Authentication"**
2. Select the **Auth Type**:
   - **Bearer**: Token sent as `Authorization: Bearer <token>`
   - **API Key**: Key sent as `X-API-Key: <key>`
   - **Basic**: Username:password encoded as Base64
3. Enter your credentials

> **Security Note**: Credentials are stored securely in macOS Keychain, never in plain text files.

---

## Creating Test Scenarios

Scenarios are the heart of Live Testing. Each scenario represents a conversation flow you want to test.

### Understanding Scenarios

A scenario consists of:
- **Name**: Descriptive name for the test
- **Description**: Optional explanation of what this scenario tests
- **Conversation Steps**: The messages you'll send and their expected responses
- **Expected Outcomes**: Overall goals for the entire conversation

### Adding a Scenario

1. In the configuration editor, find the **Scenarios** section
2. Click **"Add Scenario"**
3. Fill in the scenario details

### Conversation Steps vs Expected Outcomes

This is an important distinction:

#### Conversation Steps (Per-Message Validation)
Each step validates the bot's response to **one specific message**.

**Example**:
- Step 1: Send "Hi" → Expect response containing "hello" or "hi"
- Step 2: Send "What's your name?" → Expect response containing the bot's name
- Step 3: Send "Goodbye" → Expect response containing "bye" or "goodbye"

#### Expected Outcomes (Overall Conversation Validation)
These validate the **entire conversation** after all steps complete.

**Example**:
- "Conversation should maintain a friendly tone throughout"
- "Bot should not produce any error messages"
- "All responses should be under 500 characters"

### Adding Conversation Steps

1. Click **"Add Step"** in the Conversation Steps section
2. Enter the **Message** you want to send to the bot
3. Optionally add an **Expected Response**:
   - Click **"Add Expected Response"**
   - Enter the expected text or pattern
   - Select the validation type

---

## Validation Types Explained

Patience supports four validation types for checking bot responses:

### 1. Pattern (Regex)
Uses regular expressions to match response content.

**Best for**: Flexible matching where exact wording may vary

**Examples**:
| Pattern | Matches |
|---------|---------|
| `hello\|hi\|hey` | "hello", "hi", or "hey" anywhere in response |
| `order.*confirmed` | "order" followed by "confirmed" with anything between |
| `\d{5}` | Any 5-digit number (like a zip code) |
| `(?i)thank you` | "thank you" case-insensitive |

**Tips**:
- Use `|` for alternatives: `yes|yeah|yep`
- Use `.*` for "anything between": `hello.*world`
- Use `(?i)` at start for case-insensitive matching

### 2. Exact
Requires the response to exactly match the expected text (case-insensitive).

**Best for**: Responses that should be identical every time

**Example**:
- Expected: "I'm sorry, I don't understand."
- Matches: "I'm sorry, I don't understand." or "i'm sorry, i don't understand."
- Does NOT match: "I'm sorry, I don't understand that."

### 3. Semantic
Uses AI to compare the meaning of the response to the expected text.

**Best for**: Responses where the meaning matters more than exact wording

**What to enter in the text field**: The expected meaning in plain English

**Examples**:

| What you enter | Bot response that matches | Bot response that doesn't match |
|----------------|---------------------------|--------------------------------|
| "The weather is nice today" | "It's a beautiful day outside" | "I like pizza" |
| "I can help you with that" | "Sure, I'll assist you" | "I don't understand" |
| "Your order is being processed" | "We're working on your order now" | "Order not found" |
| "Thank you for contacting us" | "Thanks for reaching out!" | "What do you need?" |

**How it works**: Patience uses Apple's NaturalLanguage framework to compare meanings, not exact words.

**Threshold**: Set between 0.0 and 1.0
- 0.8 = Requires 80% semantic similarity (recommended)
- 0.9 = Very strict, nearly identical meaning required
- 0.6 = Loose matching, general topic similarity

**Note**: You don't need to provide any API keys or endpoints - semantic analysis is built into Patience.

### 4. Custom
Uses custom validation logic you define.

**Best for**: Complex validation rules not covered by other types

---

## Default Validation Type

In the main configuration, you'll see a **Validation** section with **Default Type**.

**Purpose**: This sets the fallback validation type used when a conversation step doesn't specify its own type.

**Example**:
- Default Type: Pattern
- Step 1: No validation type specified → Uses Pattern
- Step 2: Explicitly set to Semantic → Uses Semantic
- Step 3: No validation type specified → Uses Pattern

This saves time when most of your validations use the same type.

---

## Timing Configuration

The **Timing** section controls how fast messages are sent:

| Setting | Description | Default |
|---------|-------------|---------|
| **Enable Delays** | Add realistic delays between messages | On |
| **Base Delay (ms)** | Minimum delay before each message | 1000ms |
| **Delay per Character (ms)** | Additional delay based on message length | 50ms |
| **Response Timeout (ms)** | Maximum time to wait for bot response | 30000ms |

### Why Use Delays?

1. **Realistic Testing**: Simulates actual user typing speed
2. **Rate Limiting**: Prevents overwhelming your bot
3. **Debugging**: Easier to follow test execution

### Calculating Total Delay

```
Total Delay = Base Delay + (Message Length × Delay per Character)
```

**Example**: Message "Hello, how are you?" (19 characters)
- Base Delay: 1000ms
- Per Character: 50ms × 19 = 950ms
- Total: 1950ms (about 2 seconds)

---

## Running Tests

### Starting a Test

1. Select a configuration from the list on the left
2. Review the configuration details on the right
3. Click **"Run Tests"**

### During Execution

- Progress bar shows completion percentage
- Status text shows current scenario and step
- **Cancel** button stops execution (partial results are saved)

### After Completion

- Results appear in the **Recent Results** section
- Click **"View All"** to see detailed results
- Results are automatically saved for later review

---

## Understanding Results

### Summary View

Shows high-level statistics:
- **Total Scenarios**: Number of scenarios executed
- **Passed**: Scenarios where all validations passed
- **Failed**: Scenarios with at least one failed validation
- **Pass Rate**: Percentage of passed scenarios

### Scenario Details

For each scenario:
- **Status**: ✅ Passed or ❌ Failed
- **Duration**: How long the scenario took
- **Conversation History**: All messages exchanged
- **Validation Results**: Each validation with pass/fail status

### Validation Results

Each validation shows:
- **Expected**: What you expected to see
- **Actual**: What the bot actually responded
- **Status**: Whether it passed or failed
- **Details**: Additional context for failures

---

## Best Practices

### Scenario Design

1. **Start Simple**: Begin with basic greeting tests
2. **Build Complexity**: Add multi-turn conversations gradually
3. **Test Edge Cases**: Include unusual inputs and error conditions
4. **Group Related Tests**: Create scenarios for specific features

### Validation Strategy

1. **Use Pattern for Flexibility**: Most responses vary slightly
2. **Use Exact for Critical Messages**: Error messages, confirmations
3. **Use Semantic for Natural Language**: Open-ended responses
4. **Set Appropriate Thresholds**: Start at 0.8, adjust as needed

### Timing Considerations

1. **Match Production Conditions**: Use similar delays to real users
2. **Account for Bot Speed**: Increase timeout for slow bots
3. **Disable Delays for Speed**: Turn off for rapid regression testing

---

## Troubleshooting

### "Connection Failed"

**Causes**:
- Bot endpoint is not running
- Incorrect URL
- Network/firewall issues
- Wrong protocol (HTTP vs HTTPS)

**Solutions**:
1. Verify bot is running: `curl http://your-bot-endpoint`
2. Check URL spelling and port number
3. Try accessing from a browser
4. Check firewall settings

### "Timeout" Errors

**Causes**:
- Bot is slow to respond
- Network latency
- Bot crashed during processing

**Solutions**:
1. Increase Response Timeout in Timing settings
2. Check bot logs for errors
3. Test bot manually to verify it's working

### Validation Failures

**Causes**:
- Pattern doesn't match response format
- Semantic threshold too high
- Bot response changed

**Solutions**:
1. Review actual response in results
2. Adjust pattern or expected text
3. Lower semantic threshold
4. Update test to match new bot behavior

### "Authentication Failed"

**Causes**:
- Invalid credentials
- Expired token
- Wrong auth type

**Solutions**:
1. Verify credentials are correct
2. Generate new API key/token
3. Check auth type matches bot requirements

---

## Example: Complete Test Configuration

Here's a complete example testing a customer support bot:

### Configuration

**Bot Configuration**:
- Name: "Support Bot"
- Endpoint: `https://api.example.com/support/chat`
- Protocol: HTTP
- Provider: Generic

**Authentication**:
- Type: Bearer
- Credentials: `your-api-token`

### Scenario: "Order Status Inquiry"

**Steps**:

1. **Message**: "Hi, I need help with my order"
   - Expected Response: `help|assist|order`
   - Type: Pattern

2. **Message**: "My order number is 12345"
   - Expected Response: `order.*12345|received|looking`
   - Type: Pattern

3. **Message**: "When will it arrive?"
   - Expected Response: "shipping information"
   - Type: Semantic
   - Threshold: 0.7

**Expected Outcomes**:

1. "Bot should acknowledge the order number"
   - Type: Pattern
   - Expected: `12345`

2. "Conversation should be helpful"
   - Type: Semantic
   - Expected: "helpful customer service interaction"
   - Threshold: 0.6

---

## Sharing and Managing Configurations

### Exporting Configurations

Patience provides several ways to export and share your test configurations:

#### Export Single Configuration
1. **Right-click** on any configuration in the list
2. Select **"Export..."**
3. Choose a location and filename
4. The configuration is saved as a JSON file

#### Export All Configurations
1. Click the **"Export"** menu in the top toolbar
2. Select **"Export All Configurations..."**
3. Choose a location for the combined JSON file
4. All configurations are saved in a single file

#### Copy to Clipboard
1. **Right-click** on any configuration
2. Select **"Copy to Clipboard"**
3. The configuration JSON is copied for easy sharing via chat/email

### Importing Configurations

#### Import from File
1. Click the **"Import"** menu in the top toolbar
2. Select **"Import Configuration..."**
3. Choose a JSON file containing configurations
4. Configurations are added to your existing list

**Supported Import Formats:**
- Single configuration JSON file
- Multiple configurations in an array
- Files exported from other Patience installations

#### Import Behavior
- **New IDs**: Imported configurations get new unique IDs to avoid conflicts
- **Merge**: Imported configs are added to existing ones (doesn't replace)
- **Validation**: Invalid configurations are rejected with error messages

### Sharing with Team Members

**Best Practices for Team Sharing:**

1. **Version Control**: Store exported JSON files in your project repository
   ```
   tests/
   ├── patience-configs/
   │   ├── api-tests.json
   │   ├── regression-tests.json
   │   └── smoke-tests.json
   ```

2. **Documentation**: Include setup instructions in your README
   ```markdown
   ## Test Setup
   1. Install Patience
   2. Import configurations: `tests/patience-configs/api-tests.json`
   3. Update bot endpoints for your environment
   ```

3. **Environment-Specific**: Export base configurations, team members update endpoints
   - Development: `http://localhost:3000`
   - Staging: `https://staging-api.example.com`
   - Production: `https://api.example.com`

### Configuration File Format

Exported configurations use this JSON structure:

```json
{
  "id": "550e8400-e29b-41d4-a716-446655440000",
  "targetBot": {
    "name": "Customer Support Bot",
    "protocol": "http",
    "endpoint": "https://api.example.com/chat",
    "provider": "generic"
  },
  "scenarios": [
    {
      "id": "greeting-test",
      "name": "Greeting Test",
      "steps": [
        {
          "message": "Hello",
          "expectedResponse": {
            "validationType": "pattern",
            "expected": "hello|hi|greetings",
            "threshold": 0.8
          }
        }
      ]
    }
  ],
  "validation": {
    "defaultType": "pattern",
    "semanticSimilarityThreshold": 0.8
  },
  "timing": {
    "enableDelays": true,
    "baseDelay": 1000,
    "delayPerCharacter": 50,
    "responseTimeout": 30000
  },
  "reporting": {
    "outputPath": "~/Documents/Patience Reports",
    "formats": ["json", "html"],
    "includeConversationHistory": true,
    "verboseErrors": true
  }
}
```

**Security Note**: API keys and authentication tokens are never included in exported configurations for security reasons.

---

## Next Steps

- **[Log Analysis Guide](LOG_ANALYSIS_GUIDE.md)**: Analyze historical conversation logs
- **[Adversarial Testing Guide](ADVERSARIAL_TESTING_GUIDE.md)**: Use AI to find edge cases
- **[DOCUMENTATION.md](../DOCUMENTATION.md)**: Complete technical reference
