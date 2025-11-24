# Sample Chat Log Files

This directory contains sample chat log files in different formats for testing the Chat Log Analysis feature.

## Files

### conversations.json
JSON format with structured conversation data. This format is ideal for:
- Programmatically generated logs
- Logs exported from APIs
- Rich metadata requirements

**Structure:**
```json
{
  "conversations": [
    {
      "id": "conv-001",
      "userId": "user-123",
      "messages": [
        {
          "sender": "user",
          "content": "message text",
          "timestamp": "ISO-8601 timestamp"
        }
      ]
    }
  ]
}
```

### conversations.csv
CSV format with tabular data. This format is ideal for:
- Spreadsheet exports
- Database query results
- Simple data analysis

**Columns:**
- `conversation_id`: Unique identifier for the conversation
- `timestamp`: ISO-8601 formatted timestamp
- `sender`: Either "user" or "bot"
- `content`: The message content
- `user_id`: User identifier

### conversations.txt
Plain text format with human-readable logs. This format is ideal for:
- Manual log files
- System logs
- Quick visual inspection

**Format:**
```
=== Conversation: conv-001 ===
[HH:MM:SS] Sender: Message content
=== End Conversation ===
```

## Usage

To analyze these logs with Patience:

```bash
# Analyze JSON log
patience analyze --log examples/sample-logs/conversations.json

# Analyze CSV log
patience analyze --log examples/sample-logs/conversations.csv --format csv

# Analyze text log
patience analyze --log examples/sample-logs/conversations.txt --format text
```

## Sample Data

All three files contain the same conversation data:
- **3 conversations** with different scenarios
- **16 total messages** (mix of user and bot messages)
- **Realistic timestamps** and conversation flow
- **Various conversation types**: support, inquiry, retention

### Conversation Scenarios

1. **conv-001**: Account login issue (6 messages)
2. **conv-002**: Business hours inquiry (4 messages)
3. **conv-003**: Subscription cancellation/retention (6 messages)
