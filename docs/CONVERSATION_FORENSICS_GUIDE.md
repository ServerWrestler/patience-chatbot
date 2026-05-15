# Conversation Forensics Guide

Import production logs to surface failure patterns, policy violations, and conversation drift.

## Quick Start

1. Open Patience → **Conversation Forensics** tab
2. Drag a log file onto the drop zone, or click **Import Log File**
3. Analysis runs automatically — results appear in the right panel

## Supported Log Formats

| Format | Description | Example |
|--------|-------------|---------|
| **JSON** | Structured conversation data | Array of `ConversationHistory` or `ConversationMessage` objects |
| **CSV** | Tabular log data | `timestamp, sender, content` columns |
| **Plain Text** | Alternating user/bot lines | One message per line |
| **Auto** | Format detected from file extension | `.json`, `.csv`, `.txt`, `.log` |

### JSON Format (Recommended)

```json
[
  {
    "sender": "user",
    "content": "Hello, I need help with my order",
    "timestamp": "2025-01-15T10:00:00Z"
  },
  {
    "sender": "bot",
    "content": "Hi! I'd be happy to help. What's your order number?",
    "timestamp": "2025-01-15T10:00:02Z"
  }
]
```

### CSV Format

```csv
timestamp,sender,content
2025-01-15T10:00:00Z,user,Hello I need help with my order
2025-01-15T10:00:02Z,bot,Hi! I'd be happy to help. What's your order number?
```

### Plain Text Format

```
Hello, I need help with my order
Hi! I'd be happy to help. What's your order number?
12345
Let me look that up for you.
```

## Analysis Options

| Option | Description |
|--------|-------------|
| **Calculate Metrics** | Message counts, average conversation length, response times |
| **Detect Patterns** | Recurring greetings, questions, and error responses |
| **Check Context Retention** | How well the bot references earlier messages |

## Understanding Results

### Metrics

- **Total Messages** — Sum of all messages across all conversations
- **Avg Messages/Conversation** — Mean conversation length
- **Avg Response Time** — Mean bot response time (if timestamps available)

### Detected Patterns

| Pattern Type | What It Detects |
|-------------|-----------------|
| `greeting` | Conversations starting with common greeting words |
| `question` | Messages containing question marks |
| `error` | Bot responses containing error-related words (sorry, can't, failed, etc.) |

Each pattern includes a **confidence score** (0–100%) and **frequency count**.

### Context Retention

- **Context Score** — Word overlap between consecutive messages (higher = better coherence)
- **Topic Switches** — Abrupt topic changes detected
- **Context Breaks** — Times the bot showed confusion about earlier context

## Creating Configurations Manually

For more control, click **New Analysis** to configure:

- **Log File Path** — Browse to select a file
- **Format** — Override auto-detection
- **Analysis Options** — Enable/disable individual analysis types

## Troubleshooting

| Problem | Solution |
|---------|----------|
| "File not found" | Verify the file path is correct and accessible |
| "Invalid format" | Check that JSON is valid, or try switching to a specific format |
| No patterns detected | Normal for short logs — patterns require multiple conversations |
| Low context score | Expected for topic-switching bots; not necessarily a problem |

## Related Guides

- [Scenario Testing Guide](SCENARIO_TESTING_GUIDE.md) — Scripted scenario testing
- [Adversarial Testing Guide](ADVERSARIAL_TESTING_GUIDE.md) — AI-powered red teaming
