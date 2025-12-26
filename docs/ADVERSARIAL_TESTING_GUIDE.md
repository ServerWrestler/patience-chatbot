# Adversarial Testing Guide

This guide explains how to use Patience's Adversarial Testing feature to automatically test your chatbot using AI-powered conversations.

## Overview

Adversarial Testing uses AI models to automatically generate challenging conversations with your chatbot. Instead of manually writing test scenarios, an AI "tester" engages your bot in realistic conversations, probing for weaknesses, edge cases, and unexpected behaviors.

## Why Adversarial Testing?

| Manual Testing | Adversarial Testing |
|----------------|---------------------|
| Limited by human creativity | AI generates unexpected inputs |
| Time-consuming to write scenarios | Automatic scenario generation |
| Tests what you expect | Finds what you don't expect |
| Predictable patterns | Varied, realistic conversations |

## Getting Started

### Step 1: Navigate to Adversarial Testing

1. Open Patience
2. Click the **"Adversarial"** tab in the sidebar

### Step 2: Choose Your AI Provider

Patience supports three AI providers for adversarial testing:

| Provider | Type | Cost | Privacy | Best For |
|----------|------|------|---------|----------|
| **Ollama** | Local | Free | Private | Development, privacy-sensitive |
| **OpenAI** | Cloud | Paid | API | Production testing, GPT models |
| **Anthropic** | Cloud | Paid | API | Production testing, Claude models |

### Step 3: Set Up Your Provider

#### Ollama (Local - Recommended for Starting)

1. Install Ollama from [ollama.ai](https://ollama.ai)
2. Pull a model: `ollama pull llama2` or `ollama pull mistral`
3. Ensure Ollama is running: `ollama serve`
4. In Patience, select "Ollama" as provider
5. Enter endpoint: `http://localhost:11434` (default)
6. Select your model from the dropdown

#### OpenAI

1. Get API key from [platform.openai.com](https://platform.openai.com)
2. In Patience, select "OpenAI" as provider
3. Enter your API key (stored securely in Keychain)
4. Select model: gpt-4, gpt-4-turbo, or gpt-3.5-turbo

#### Anthropic

1. Get API key from [console.anthropic.com](https://console.anthropic.com)
2. In Patience, select "Anthropic" as provider
3. Enter your API key (stored securely in Keychain)
4. Select model: claude-3-opus, claude-3-sonnet, or claude-3-haiku

---

## Creating an Adversarial Test Configuration

### Step 1: Click "New Configuration"

In the Adversarial tab, click **"New Configuration"**.

### Step 2: Configure Target Bot

This is the chatbot you want to test:

| Field | Description | Example |
|-------|-------------|---------|
| **Name** | Friendly name | "My Support Bot" |
| **Endpoint** | Bot's HTTP endpoint | `http://localhost:3000/chat` |
| **Protocol** | HTTP or WebSocket | HTTP |

### Step 3: Configure Adversarial Bot (AI Tester)

| Field | Description |
|-------|-------------|
| **Provider** | Ollama, OpenAI, or Anthropic |
| **Model** | Specific model to use |
| **Endpoint** | API endpoint (auto-filled for cloud providers) |
| **API Key** | Required for OpenAI/Anthropic |

### Step 4: Configure Conversation Settings

| Setting | Description | Default |
|---------|-------------|---------|
| **Strategy** | Testing approach (see below) | Exploratory |
| **Max Turns** | Maximum messages per conversation | 10 |
| **Conversations** | Number of conversations to run | 5 |
| **Goals** | Specific testing objectives | (optional) |

### Step 5: Configure Safety Settings

| Setting | Description | Default |
|---------|-------------|---------|
| **Max Cost (USD)** | Stop if cost exceeds limit | $1.00 |
| **Rate Limit** | Max requests per minute | 10 |
| **Content Filter** | Block inappropriate content | On |

---

## Testing Strategies Explained

### 1. Exploratory Strategy

**Purpose**: Discover what your bot can do

**Behavior**:
- Asks broad, diverse questions
- Explores different topics
- Maps bot capabilities
- Identifies supported features

**Best For**:
- Initial testing of new bots
- Feature discovery
- Documentation validation
- Understanding bot scope

**Example Conversation**:
```
AI: What can you help me with?
Bot: I can help with orders, returns, and product questions.
AI: Tell me about your return policy.
Bot: You can return items within 30 days...
AI: Can you check my order status?
Bot: Sure! What's your order number?
AI: What about technical support?
Bot: I can help with basic troubleshooting...
```

### 2. Adversarial Strategy

**Purpose**: Find weaknesses and edge cases

**Behavior**:
- Sends contradictory information
- Tests boundary conditions
- Attempts to confuse the bot
- Probes for errors

**Best For**:
- Security testing
- Robustness validation
- Error handling verification
- Edge case discovery

**Example Conversation**:
```
AI: My order number is ABC123
Bot: I found your order...
AI: Actually, my order number is XYZ789
Bot: Let me look up XYZ789...
AI: No wait, it was ABC123 but for a different account
Bot: I'm sorry, I'm getting confused...
AI: Can you delete my account and also place a new order?
Bot: I can only help with one request at a time...
```

### 3. Focused Strategy

**Purpose**: Deep dive into specific features

**Behavior**:
- Concentrates on defined goals
- Tests specific functionality thoroughly
- Validates particular use cases
- Follows goal-oriented paths

**Best For**:
- Feature-specific testing
- Regression testing
- Compliance validation
- Targeted quality assurance

**Configuration**: Add specific goals like:
- "Test the order cancellation flow"
- "Verify refund policy explanations"
- "Check multi-language support"

**Example Conversation** (Goal: Test order cancellation):
```
AI: I want to cancel my order
Bot: I can help with that. What's your order number?
AI: Order 12345
Bot: I found order 12345. Are you sure you want to cancel?
AI: Yes, cancel it
Bot: Your order has been cancelled...
AI: Can I un-cancel it?
Bot: Unfortunately, cancelled orders cannot be restored...
```

### 4. Stress Strategy

**Purpose**: Test bot limits and performance

**Behavior**:
- Rapid context switching
- Long, complex messages
- Many conversation turns
- Tests memory and consistency

**Best For**:
- Performance testing
- Context retention validation
- Scalability assessment
- Consistency checking

**Example Conversation**:
```
AI: I have three questions: about orders, returns, and shipping
Bot: I'll help with all three...
AI: First, my order 111 is late. Second, I want to return item from order 222. Third, what's shipping cost to Alaska?
Bot: Let me address each...
AI: Actually, forget the return. But add a question about gift wrapping for order 333.
Bot: Okay, so we're discussing orders 111 and 333...
```

---

## Goals Configuration

Goals guide the AI tester toward specific testing objectives.

### Adding Goals

1. In the configuration editor, find **"Goals"** section
2. Click **"Add Goal"**
3. Enter a clear, specific objective

### Writing Effective Goals

**Good Goals** (Specific, actionable):
- "Test how the bot handles order cancellation requests"
- "Verify the bot correctly explains the return policy"
- "Check if the bot maintains context across 10+ turns"
- "Test error handling when invalid order numbers are provided"

**Poor Goals** (Vague, unclear):
- "Test the bot" (too vague)
- "Make sure it works" (not specific)
- "Find bugs" (not actionable)

### Goal Examples by Use Case

**Customer Support Bot**:
- "Test order status inquiries with valid and invalid order numbers"
- "Verify escalation to human agent when bot cannot help"
- "Check handling of angry or frustrated customer messages"

**FAQ Bot**:
- "Test responses to questions not in the FAQ"
- "Verify accuracy of pricing information"
- "Check handling of ambiguous questions"

**Technical Support Bot**:
- "Test troubleshooting flow for common issues"
- "Verify bot asks clarifying questions when needed"
- "Check handling of technical jargon"

---

## Running Adversarial Tests

### Starting a Test

1. Select your configuration from the list
2. Review settings in the detail panel
3. Click **"Run Test"**

### During Execution

The test panel shows:
- **Progress**: Current conversation / total
- **Live Conversation**: Real-time message exchange
- **Status**: Current operation
- **Cost Tracker**: Running cost (for paid providers)

### Monitoring

Watch for:
- Unexpected bot responses
- Error messages
- Long response times
- Context loss indicators

### Stopping Early

Click **"Stop"** to end testing early. Partial results are saved.

---

## Understanding Results

### Summary View

| Metric | Description |
|--------|-------------|
| **Conversations** | Total conversations completed |
| **Total Turns** | Total messages exchanged |
| **Issues Found** | Potential problems identified |
| **Cost** | Total API cost (paid providers) |

### Conversation Review

Each conversation shows:
- Full message history
- Timestamps
- Any issues flagged
- AI tester's observations

### Issue Categories

| Category | Description | Severity |
|----------|-------------|----------|
| **Error Response** | Bot returned an error | High |
| **Context Loss** | Bot forgot earlier information | Medium |
| **Inconsistency** | Bot contradicted itself | Medium |
| **Unhelpful** | Bot didn't address the question | Low |
| **Timeout** | Bot took too long to respond | Medium |

### AI Observations

The AI tester provides observations like:
- "Bot struggled with multi-part questions"
- "Context was lost after turn 7"
- "Bot handled edge case well"
- "Inconsistent information about return policy"

---

## Safety Controls

### Cost Limits

**Purpose**: Prevent unexpected API charges

**Configuration**:
```
Max Cost: $5.00
```

**Behavior**: Test stops when cost limit is reached. Partial results are saved.

**Recommendations**:
| Use Case | Suggested Limit |
|----------|-----------------|
| Quick test | $0.50 |
| Standard test | $2.00 |
| Comprehensive test | $10.00 |

### Rate Limiting

**Purpose**: Prevent overwhelming your bot or hitting API limits

**Configuration**:
```
Rate Limit: 10 requests/minute
```

**Behavior**: Pauses between requests to stay under limit.

### Content Filtering

**Purpose**: Prevent inappropriate content generation

**Configuration**: Toggle on/off

**Behavior**: Filters potentially harmful or inappropriate messages from the AI tester.

---

## Best Practices

### Test Configuration

1. **Start with Exploratory**: Understand your bot first
2. **Then Adversarial**: Find weaknesses
3. **Finally Focused**: Validate specific features
4. **Use Stress Sparingly**: Only when needed

### Goal Setting

1. **Be Specific**: Clear goals get better results
2. **Prioritize**: Test critical features first
3. **Iterate**: Refine goals based on findings
4. **Document**: Keep track of what you've tested

### Cost Management

1. **Start Small**: Use low limits initially
2. **Use Ollama**: Free local testing for development
3. **Cloud for Production**: Use paid APIs for final validation
4. **Monitor Costs**: Check running total during tests

### Interpreting Results

1. **Review All Conversations**: Don't just look at summaries
2. **Prioritize Issues**: Focus on high-severity first
3. **Verify Findings**: Some "issues" may be false positives
4. **Track Trends**: Compare results over time

---

## Troubleshooting

### "Connection to AI Provider Failed"

**Ollama**:
1. Verify Ollama is running: `ollama serve`
2. Check endpoint: `http://localhost:11434`
3. Verify model is pulled: `ollama list`

**OpenAI/Anthropic**:
1. Verify API key is correct
2. Check account has credits
3. Verify network connectivity

### "Target Bot Not Responding"

1. Verify bot endpoint is correct
2. Test bot manually with curl
3. Check bot logs for errors
4. Verify authentication settings

### "Cost Limit Reached Too Quickly"

1. Reduce max turns per conversation
2. Reduce number of conversations
3. Use smaller/cheaper model
4. Use Ollama for development testing

### "AI Tester Generating Irrelevant Messages"

1. Add more specific goals
2. Try different strategy
3. Use more capable model
4. Provide better context in goals

### "Results Don't Show Issues I Know Exist"

1. Increase number of conversations
2. Use adversarial strategy
3. Add goals targeting known issues
4. Try stress strategy for edge cases

---

## Example: Complete Adversarial Test

### Scenario: Pre-Release Validation

**Goal**: Validate customer support bot before production release

### Configuration

**Target Bot**:
- Name: "Support Bot v2.0"
- Endpoint: `https://staging.example.com/chat`
- Protocol: HTTP

**Adversarial Bot**:
- Provider: OpenAI
- Model: gpt-4
- API Key: (stored in Keychain)

**Conversation Settings**:
- Strategy: Adversarial
- Max Turns: 15
- Conversations: 20

**Goals**:
1. "Test order status with invalid order numbers"
2. "Attempt to get bot to reveal internal information"
3. "Test handling of abusive language"
4. "Verify bot stays on topic"
5. "Test multi-language inputs"

**Safety**:
- Max Cost: $5.00
- Rate Limit: 10/min
- Content Filter: On

### Execution

Run test and monitor:
- 20 conversations completed
- Total cost: $3.47
- 4 issues identified

### Results Analysis

**Issues Found**:
1. Bot revealed internal error codes (High severity)
2. Context lost after 12 turns (Medium severity)
3. Bot didn't handle Spanish input gracefully (Low severity)
4. Inconsistent refund policy information (Medium severity)

### Action Items

1. Fix error message exposure
2. Improve context retention
3. Add multi-language support message
4. Standardize refund policy responses

### Re-Test

After fixes, run focused tests on each issue to verify resolution.

---

## Provider Comparison

### Ollama (Local)

**Pros**:
- Free to use
- Complete privacy
- No internet required
- Fast for local testing

**Cons**:
- Requires local setup
- Limited model selection
- May be less capable than cloud models

**Best Models**: llama2, mistral, codellama

### OpenAI

**Pros**:
- Highly capable models
- Easy setup
- Reliable service
- Good documentation

**Cons**:
- Costs money
- Data sent to cloud
- Rate limits apply

**Best Models**: gpt-4 (most capable), gpt-3.5-turbo (cost-effective)

### Anthropic

**Pros**:
- Very capable models
- Strong safety features
- Good at following instructions
- Excellent for adversarial testing

**Cons**:
- Costs money
- Data sent to cloud
- Newer service

**Best Models**: claude-3-opus (most capable), claude-3-sonnet (balanced)

---

## Next Steps

- **[Live Testing Guide](LIVE_TESTING_GUIDE.md)**: Manual scenario testing
- **[Log Analysis Guide](LOG_ANALYSIS_GUIDE.md)**: Analyze historical logs
- **[DOCUMENTATION.md](../DOCUMENTATION.md)**: Complete technical reference
