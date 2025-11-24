# Live Testing Examples

Live testing allows you to run scenario-based tests against your chatbot in real-time.

## Quick Start

```bash
# Run with default configuration
patience examples/live-testing/config.json

# Or use the CLI directly
node dist/cli.js examples/live-testing/config.json
```

## Configuration Files

- **[config.json](config.json)** - Complete example with all options
- **[simple-config.json](simple-config.json)** - Minimal configuration to get started
- **[advanced-config.json](advanced-config.json)** - Advanced features and options

## Configuration Options

### Target Bot

Define your bot's connection details:

```json
{
  "targetBot": {
    "name": "My Bot",
    "protocol": "http",
    "endpoint": "http://localhost:3000/chat",
    "authentication": {
      "type": "bearer",
      "credentials": "your-token-here"
    },
    "headers": {
      "X-Custom-Header": "value"
    }
  }
}
```

**Protocols:**
- `http` - REST API endpoint
- `websocket` - WebSocket connection

**Authentication types:**
- `bearer` - Bearer token
- `basic` - Basic auth
- `apikey` - API key

### Scenarios

Define conversation flows to test:

```json
{
  "scenarios": [
    {
      "id": "greeting",
      "name": "Greeting Test",
      "description": "Test bot greeting responses",
      "steps": [
        {
          "message": "Hello!",
          "expectedResponse": {
            "validationType": "pattern",
            "expected": "hi|hello|hey"
          }
        }
      ]
    }
  ]
}
```

**Validation types:**
- `exact` - Exact string match
- `pattern` - Regular expression match
- `semantic` - Semantic similarity (requires threshold)
- `custom` - Custom validation function

### Timing

Control conversation pacing:

```json
{
  "timing": {
    "enableDelays": true,
    "baseDelay": 100,
    "delayPerCharacter": 10,
    "rapidFire": false,
    "responseTimeout": 30000
  }
}
```

- `enableDelays` - Enable human-like typing delays
- `baseDelay` - Base delay in milliseconds
- `delayPerCharacter` - Additional delay per character
- `rapidFire` - Send messages immediately
- `responseTimeout` - Maximum wait time for response

### Reporting

Configure output format and location:

```json
{
  "reporting": {
    "outputPath": "./reports",
    "formats": ["json", "html", "markdown"],
    "includeConversationHistory": true,
    "verboseErrors": true
  }
}
```

**Available formats:**
- `json` - Structured data
- `html` - Visual report with styling
- `markdown` - Documentation-friendly format

## CLI Options

```bash
# Specify configuration file
patience -c examples/live-testing/config.json

# Override output directory
patience config.json -o ./my-reports

# Specify report format
patience config.json -f html

# Show help
patience --help
```

## Example Scenarios

### Basic Greeting Test

```json
{
  "id": "greeting",
  "name": "Greeting Test",
  "steps": [
    {
      "message": "Hello!",
      "expectedResponse": {
        "validationType": "pattern",
        "expected": "hi|hello|hey"
      }
    }
  ]
}
```

### Multi-Turn Conversation

```json
{
  "id": "help-flow",
  "name": "Help Request Flow",
  "steps": [
    {
      "message": "I need help",
      "expectedResponse": {
        "validationType": "pattern",
        "expected": "help|assist"
      }
    },
    {
      "message": "How do I reset my password?",
      "expectedResponse": {
        "validationType": "pattern",
        "expected": "password|reset|email"
      }
    }
  ]
}
```

### Semantic Validation

```json
{
  "id": "semantic-test",
  "name": "Semantic Similarity Test",
  "steps": [
    {
      "message": "What are your business hours?",
      "expectedResponse": {
        "validationType": "semantic",
        "expected": "We are open Monday through Friday from 9am to 5pm",
        "threshold": 0.7
      }
    }
  ]
}
```

## Tips

1. **Start Simple** - Begin with basic scenarios and add complexity
2. **Use Patterns** - Regular expressions provide flexibility
3. **Test Edge Cases** - Include error scenarios and unusual inputs
4. **Adjust Timing** - Use `rapidFire` for quick tests, delays for realistic simulation
5. **Review Reports** - HTML reports provide the best visualization

## Troubleshooting

### Connection Issues

- Verify endpoint URL is correct
- Check authentication credentials
- Ensure bot is running and accessible

### Validation Failures

- Review expected patterns for accuracy
- Check semantic similarity threshold (0.7 is typical)
- Use verbose errors for detailed information

### Timeout Errors

- Increase `responseTimeout` for slow bots
- Check network connectivity
- Verify bot is responding

## Next Steps

- See [../../README.md](../../README.md) for overview
- Try [../log-analysis/](../log-analysis/) for retrospective testing
- Explore [../adversarial-testing/](../adversarial-testing/) for AI-powered testing
