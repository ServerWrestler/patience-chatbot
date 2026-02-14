# Log Analysis Guide

> ⚠️ **This feature is not yet fully implemented.**
> 
> Currently available: Basic context retention analysis via `AnalysisEngine.analyzeContextRetention()`
> 
> Planned features: Multi-format log import, pattern detection, comprehensive metrics, advanced filtering.

## Current Functionality

The Analysis tab provides basic context analysis for multi-turn conversations:

```swift
// Available now
AnalysisEngine.analyzeContextRetention(messages: [ConversationMessage]) -> ContextAnalysisResult
```

## Planned Features

When fully implemented, Log Analysis will support:

| Feature | Description |
|---------|-------------|
| **Multi-format Import** | JSON, CSV, plain text logs |
| **Pattern Detection** | Identify recurring phrases and topics |
| **Metrics** | Response times, message lengths, conversation flows |
| **Anomaly Detection** | Flag unusual conversations |
| **Filtering** | Date ranges, message counts, content search |
| **Validation** | Apply validation rules to historical data |

## Planned Log Formats

**JSON (Recommended):**
```json
[
  {"sender": "user", "content": "Hello", "timestamp": "2024-12-12T10:00:00Z"},
  {"sender": "bot", "content": "Hi! How can I help?", "timestamp": "2024-12-12T10:00:01Z"}
]
```

**CSV:**
```csv
timestamp,sender,content
2024-12-12T10:00:00Z,user,Hello
2024-12-12T10:00:01Z,bot,Hi! How can I help?
```

**Plain Text** (alternating user/bot):
```
Hello
Hi! How can I help?
```

## Related Guides

- [Live Testing Guide](LIVE_TESTING_GUIDE.md) - Real-time scenario testing ✅
- [Adversarial Testing Guide](ADVERSARIAL_TESTING_GUIDE.md) - AI-powered testing ✅
