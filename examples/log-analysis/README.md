# Log Analysis Examples

Analyze historical chat logs to validate bot performance retrospectively.

## Quick Start

```bash
# Analyze with default configuration
patience analyze examples/log-analysis/sample-logs/conversations.json

# Use configuration file
patience analyze -c examples/log-analysis/config.json

# Specify format and output
patience analyze conversations.json -f json -o ./my-analysis
```

## Configuration Files

- **[config.json](config.json)** - Complete configuration with all options
- **[simple-config.json](simple-config.json)** - Minimal configuration
- **[filtered-config.json](filtered-config.json)** - Advanced filtering examples

## Sample Data

The `sample-logs/` directory contains example log files in multiple formats:
- **conversations.json** - JSON format
- **conversations.csv** - CSV format
- **conversations.txt** - Text format

See [sample-logs/README.md](sample-logs/README.md) for format specifications.

## Configuration Options

### Log Source

Specify the log file to analyze:

```json
{
  "logSource": {
    "path": "conversations.json",
    "format": "json"
  }
}
```

**Supported formats:**
- `json` - Structured JSON logs
- `csv` - Comma-separated values
- `text` - Plain text logs
- `auto` - Automatic detection (default)

### Filters

Filter conversations before analysis:

```json
{
  "filters": {
    "dateRange": {
      "start": "2025-01-01T00:00:00Z",
      "end": "2025-01-31T23:59:59Z"
    },
    "minMessages": 3,
    "maxMessages": 50,
    "userIds": ["user-123", "user-456"],
    "textContains": "help"
  }
}
```

**Filter options:**
- `dateRange` - Filter by timestamp
- `minMessages` - Minimum messages per conversation
- `maxMessages` - Maximum messages per conversation
- `userIds` - Filter by specific users
- `textContains` - Search for text in messages

### Validation

Apply validation rules to historical data:

```json
{
  "validation": {
    "rules": [
      {
        "type": "pattern",
        "expected": "help|assist|support",
        "description": "Bot should offer assistance"
      }
    ]
  }
}
```

### Analysis Options

Configure what to analyze:

```json
{
  "analysis": {
    "calculateMetrics": true,
    "detectPatterns": true,
    "checkContextRetention": true
  }
}
```

**Analysis types:**
- `calculateMetrics` - Conversation statistics
- `detectPatterns` - Common patterns and anomalies
- `checkContextRetention` - Multi-turn context quality

### Reporting

Configure output:

```json
{
  "reporting": {
    "outputPath": "./analysis-reports",
    "formats": ["html", "json", "markdown", "csv"],
    "includeDetailedResults": true
  }
}
```

**Report formats:**
- `html` - Visual report with charts
- `json` - Structured data
- `markdown` - Documentation format
- `csv` - Spreadsheet-compatible

## CLI Options

```bash
# Specify log file
patience analyze -l conversations.json

# Use configuration file
patience analyze -c config.json

# Specify log format
patience analyze -f csv conversations.csv

# Set output directory
patience analyze conversations.json -o ./reports

# Choose report format
patience analyze conversations.json -r markdown

# Show help
patience analyze --help
```

## Analysis Features

### Metrics Calculated

- Total conversations and messages
- Average messages per conversation
- Bot response rate
- Validation pass rate
- Message length statistics (min, max, avg, median)
- Time distribution analysis
- Conversation duration

### Pattern Detection

- **Failure Patterns** - Common failure messages grouped by similarity
- **Success Patterns** - Frequently used successful phrases
- **Anomalies** - Very short/long conversations, missing responses

### Context Analysis

- **Context Retention Score** - 0-1 score for multi-turn quality
- **Context Breaks** - Identification of where context is lost
- **Quality Rating** - Poor/Fair/Good/Excellent assessment

## Log Format Examples

### JSON Format

```json
[
  {
    "conversationId": "conv-1",
    "timestamp": "2025-01-15T10:30:00Z",
    "userId": "user-123",
    "messages": [
      {
        "role": "user",
        "content": "Hello!",
        "timestamp": "2025-01-15T10:30:00Z"
      },
      {
        "role": "bot",
        "content": "Hi! How can I help?",
        "timestamp": "2025-01-15T10:30:05Z"
      }
    ]
  }
]
```

### CSV Format

```csv
conversationId,timestamp,userId,role,content
conv-1,2025-01-15T10:30:00Z,user-123,user,Hello!
conv-1,2025-01-15T10:30:05Z,user-123,bot,Hi! How can I help?
```

### Text Format

```
[2025-01-15 10:30:00] User: Hello!
[2025-01-15 10:30:05] Bot: Hi! How can I help?
---
```

## Use Cases

### Quality Assurance

Analyze production logs to validate bot performance:

```bash
patience analyze production-logs.json -c qa-config.json
```

### Regression Testing

Compare logs before and after changes:

```bash
patience analyze before-logs.json -o ./before
patience analyze after-logs.json -o ./after
```

### Pattern Discovery

Find common issues in conversations:

```json
{
  "analysis": {
    "detectPatterns": true
  }
}
```

### Context Validation

Verify multi-turn conversation quality:

```json
{
  "analysis": {
    "checkContextRetention": true
  },
  "filters": {
    "minMessages": 5
  }
}
```

## Tips

1. **Start with Metrics** - Get overview before diving into patterns
2. **Use Filters** - Focus on relevant conversations
3. **Check Context** - Multi-turn conversations reveal quality issues
4. **Compare Reports** - Track improvements over time
5. **Export CSV** - Use spreadsheets for custom analysis

## Troubleshooting

### File Not Found

- Verify file path is correct
- Use absolute paths if needed
- Check file permissions

### Parse Errors

- Verify log format matches specification
- Check for malformed JSON/CSV
- Use `--format` to specify format explicitly

### No Results

- Check filters aren't too restrictive
- Verify log file contains data
- Review date range filters

## Next Steps

- See [../../README.md](../../README.md) for overview
- Try [../live-testing/](../live-testing/) for real-time testing
- Explore [../adversarial-testing/](../adversarial-testing/) for AI-powered testing
