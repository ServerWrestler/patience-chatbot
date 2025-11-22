# Patience - The Chat Bot Testing System

A comprehensive testing framework for automated validation of conversational AI systems. Patience simulates realistic user interactions to validate chat bot behavior, responses, and edge case handling.

## Features

- **Multi-Protocol Support**: Test bots via HTTP and WebSocket protocols
- **Scenario-Based Testing**: Define complex conversation flows with conditional branching
- **Message Generation**: Generate diverse test inputs including edge cases
- **Response Validation**: Multiple validation types (exact match, pattern, semantic similarity)
- **Context Handling**: Test multi-turn conversations and context retention
- **Timing Control**: Simulate human-like typing delays or rapid-fire testing
- **Comprehensive Reporting**: Generate reports in JSON, HTML, and Markdown formats
- **Configuration Management**: YAML/JSON configuration with hot-reload support

## Installation

```bash
npm install
npm run build
```

## Quick Start

1. Create a configuration file (`config.json`):

```json
{
  "targetBot": {
    "name": "My Bot",
    "protocol": "http",
    "endpoint": "http://localhost:3000/chat"
  },
  "scenarios": [
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
      ],
      "expectedOutcomes": []
    }
  ],
  "validation": {
    "defaultType": "semantic",
    "semanticSimilarityThreshold": 0.7
  },
  "timing": {
    "enableDelays": false,
    "baseDelay": 100,
    "delayPerCharacter": 10,
    "rapidFire": true,
    "responseTimeout": 30000
  },
  "reporting": {
    "outputPath": "./reports",
    "formats": ["json", "html", "markdown"],
    "includeConversationHistory": true,
    "verboseErrors": true
  }
}
```

2. Run tests:

```bash
npm start -- config.json
# or after building:
node dist/cli.js config.json
```

## CLI Usage

```
Usage:
  patience [options] <config-file>

Options:
  -c, --config <file>    Path to configuration file (JSON or YAML)
  -o, --output <path>    Output directory for reports (default: ./reports)
  -f, --format <format>  Report format: json, html, markdown (default: json)
  -h, --help             Show this help message
```

## Configuration

### Target Bot

```json
{
  "targetBot": {
    "name": "Bot Name",
    "protocol": "http",
    "endpoint": "http://localhost:3000/chat",
    "authentication": {
      "type": "bearer",
      "credentials": "your-token"
    },
    "headers": {
      "Custom-Header": "value"
    }
  }
}
```

### Scenarios

Define conversation flows with steps and validation:

```json
{
  "scenarios": [
    {
      "id": "scenario-1",
      "name": "Test Scenario",
      "description": "Description of the test",
      "steps": [
        {
          "message": "User message",
          "expectedResponse": {
            "validationType": "exact",
            "expected": "Expected bot response"
          },
          "delay": 1000
        }
      ],
      "expectedOutcomes": []
    }
  ]
}
```

### Validation Types

- **exact**: Exact string match
- **pattern**: Regular expression match
- **semantic**: Semantic similarity (configurable threshold)
- **custom**: Custom validation function

### Timing Configuration

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

## Programmatic Usage

```typescript
import { TestExecutor, ConfigurationManager, ReportGenerator } from 'patience-chatbot';

async function runTests() {
  // Load configuration
  const configManager = new ConfigurationManager();
  const config = await configManager.loadConfig('config.json');

  // Execute tests
  const executor = new TestExecutor();
  const results = await executor.executeTests(config);

  // Generate report
  const reportGenerator = new ReportGenerator();
  const report = reportGenerator.generateReport(results);
  const html = reportGenerator.formatReport(report, 'html');

  console.log(html);
}
```

## Architecture

Patience follows a modular architecture:

- **Configuration Layer**: Loads and validates test scenarios
- **Execution Layer**: Orchestrates test sessions and manages conversation flow
- **Communication Layer**: Handles protocol-specific interactions (HTTP/WebSocket)
- **Validation Layer**: Evaluates bot responses against expected criteria
- **Reporting Layer**: Generates comprehensive test reports

## Project Structure

```
src/
├── types/           # Core TypeScript type definitions
├── config/          # Configuration management
├── execution/       # Test execution and orchestration
├── communication/   # Protocol adapters (HTTP, WebSocket)
├── validation/      # Response validation logic
└── reporting/       # Report generation
```

## Development

```bash
# Install dependencies
npm install

# Build
npm run build

# Run tests
npm test
```

## Technology Stack

- **TypeScript** for type safety
- **fast-check** for property-based testing
- **axios** for HTTP communication
- **ws** for WebSocket communication
- **js-yaml** for YAML configuration support
- **vitest** for unit testing

## License

MIT License - Copyright (c) 2025 Patience Contributors

See [LICENSE](LICENSE) file for details.
