# Patience - The Chat Bot Testing System

Comprehensive testing framework for conversational AI with three powerful modes: live testing, log analysis, and AI-powered adversarial testing.

## Features

- **Live Testing** - Scenario-based testing with HTTP/WebSocket support
- **Log Analysis** - Retrospective testing of historical conversations
- **Adversarial Testing** - AI-powered bot-to-bot testing with Ollama, OpenAI, and Anthropic
- **Multi-format Reports** - JSON, HTML, Markdown, and CSV outputs
- **Pattern Detection** - Identify failures and anomalies automatically
- **Context Analysis** - Evaluate multi-turn conversation quality

## Installation

```bash
npm install
npm run build
```

## Quick Start

```bash
# Install
npm install && npm run build

# Live testing
patience examples/live-testing/config.json

# Analyze logs
patience analyze examples/log-analysis/sample-logs/conversations.json

# Adversarial testing (local, free)
patience adversarial --config examples/adversarial-testing/simple-config.json
```

See [examples/](examples/) for all configuration files and detailed guides.

## CLI Commands

### Live Testing

```bash
# Run with configuration file
patience examples/live-testing/config.json

# Specify output directory
patience config.json -o ./my-reports

# Choose report format
patience config.json -f html

# Show help
patience --help
```

**Options:**
- `-c, --config <file>` - Configuration file path
- `-o, --output <path>` - Output directory (default: ./reports)
- `-f, --format <format>` - Report format: json, html, markdown

See [examples/live-testing/](examples/live-testing/) for configuration examples.

### Log Analysis

```bash
# Analyze a log file
patience analyze examples/log-analysis/sample-logs/conversations.json

# Use configuration file
patience analyze -c examples/log-analysis/config.json

# Specify format and output
patience analyze logs.csv -f csv -o ./analysis -r markdown
```

**Options:**
- `-l, --log <file>` - Log file to analyze
- `-c, --config <file>` - Configuration file
- `-f, --format <format>` - Log format: json, csv, text, auto
- `-o, --output <path>` - Output directory (default: ./analysis-reports)
- `-r, --report-format <fmt>` - Report format: json, html, markdown, csv

See [examples/log-analysis/](examples/log-analysis/) for configuration examples.

### Adversarial Testing

```bash
# Quick start with Ollama
patience adversarial --target http://localhost:3000/chat --adversary ollama

# Use configuration file
patience adversarial --config examples/adversarial-testing/simple-config.json

# Specify parameters
patience adversarial \
  --target http://localhost:3000/chat \
  --adversary ollama \
  --model llama2 \
  --strategy exploratory \
  --turns 15 \
  --conversations 5
```

**Options:**
- `-c, --config <file>` - Configuration file
- `-t, --target <url>` - Target bot endpoint
- `-a, --adversary <provider>` - Provider: ollama, openai, anthropic
- `-m, --model <model>` - Model name (e.g., llama2, gpt-4)
- `-s, --strategy <strategy>` - Strategy: exploratory, adversarial, focused, stress
- `--turns <number>` - Max turns per conversation
- `--conversations <number>` - Number of conversations
- `-o, --output <path>` - Output directory

See [examples/adversarial-testing/](examples/adversarial-testing/) for configuration examples.

## Configuration

### Live Testing

Configure scenarios, validation rules, timing, and reporting:

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
      ]
    }
  ],
  "validation": {
    "defaultType": "pattern"
  },
  "timing": {
    "rapidFire": true,
    "responseTimeout": 30000
  },
  "reporting": {
    "outputPath": "./reports",
    "formats": ["html", "json"]
  }
}
```

**Validation types:** exact, pattern, semantic, custom  
**Protocols:** HTTP, WebSocket  
**Report formats:** JSON, HTML, Markdown

See [examples/live-testing/](examples/live-testing/) for complete examples.

### Log Analysis

Configure log source, filters, analysis options, and reporting:

```json
{
  "logSource": {
    "path": "conversations.json",
    "format": "auto"
  },
  "filters": {
    "minMessages": 3,
    "dateRange": {
      "start": "2025-01-01T00:00:00Z",
      "end": "2025-12-31T23:59:59Z"
    }
  },
  "analysis": {
    "calculateMetrics": true,
    "detectPatterns": true,
    "checkContextRetention": true
  },
  "reporting": {
    "outputPath": "./analysis-reports",
    "formats": ["html", "json", "csv"]
  }
}
```

**Log formats:** JSON, CSV, text (auto-detected)  
**Report formats:** JSON, HTML, Markdown, CSV

See [examples/log-analysis/](examples/log-analysis/) for complete examples.

### Adversarial Testing

Configure target bot, adversarial bot, strategy, and execution:

```json
{
  "targetBot": {
    "name": "My Bot",
    "protocol": "http",
    "endpoint": "http://localhost:3000/chat"
  },
  "adversarialBot": {
    "provider": "ollama",
    "model": "llama2"
  },
  "conversation": {
    "strategy": "exploratory",
    "maxTurns": 10
  },
  "execution": {
    "numConversations": 5
  },
  "reporting": {
    "outputPath": "./adversarial-reports",
    "formats": ["json", "text"]
  }
}
```

**Providers:** Ollama (local/free), OpenAI, Anthropic  
**Strategies:** exploratory, adversarial, focused, stress  
**Report formats:** JSON, text, CSV

See [examples/adversarial-testing/](examples/adversarial-testing/) for complete examples.

## Log Analysis

Analyze historical conversations to validate bot performance retrospectively.

**Features:**
- Multi-format support (JSON, CSV, text)
- Metrics calculation (response rates, message stats, timing)
- Pattern detection (failures, successes, anomalies)
- Context analysis (multi-turn quality scoring)
- Advanced filtering (date range, message count, content)

**Example:**
```bash
patience analyze examples/log-analysis/sample-logs/conversations.json
```

See [examples/log-analysis/](examples/log-analysis/) for detailed guide and examples.

## Programmatic Usage

```typescript
import { TestExecutor, AnalysisEngine, AdversarialTestOrchestrator } from 'patience-chatbot';

// Live testing
const executor = new TestExecutor();
const results = await executor.executeTests(config);

// Log analysis
const engine = new AnalysisEngine();
const analysis = await engine.analyze(config);

// Adversarial testing
const orchestrator = new AdversarialTestOrchestrator(config);
const adversarial = await orchestrator.run();
```

## Architecture

Modular design with three main systems:

1. **Live Testing** - Configuration → Execution → Communication → Validation → Reporting
2. **Log Analysis** - Loading → Parsing → Filtering → Analysis → Reporting
3. **Adversarial** - LLM Connectors → Strategy → Conversation Manager → Validation → Logging

## Documentation

- **[README.md](README.md)** - This file (overview and quick start)
- **[DOCUMENTATION.md](DOCUMENTATION.md)** - Complete documentation guide
- **[CONTRIBUTING.md](CONTRIBUTING.md)** - Contribution guidelines
- **[CHANGELOG.md](CHANGELOG.md)** - Version history
- **[examples/adversarial-testing/README.md](examples/adversarial-testing/README.md)** - Detailed adversarial guide
- **[examples/](examples/)** - Configuration examples and sample data

## Development

```bash
# Install dependencies
npm install

# Build
npm run build

# Run tests
npm test
```

## Adversarial Testing

AI-powered bot-to-bot testing where an LLM tests your chatbot through realistic conversations.

**Providers:**
- Ollama - Local models (llama2, mistral) - Free
- OpenAI - GPT-4, GPT-3.5 - Requires API key
- Anthropic - Claude 3 models - Requires API key

**Strategies:**
- Exploratory - Broad questions to map capabilities
- Adversarial - Edge cases and challenging inputs
- Focused - Deep dive into specific features
- Stress - Rapid context switching and complex scenarios

**Example:**
```bash
patience adversarial --config examples/adversarial-testing/simple-config.json
```

See [examples/adversarial-testing/](examples/adversarial-testing/) for detailed guide and examples.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development setup and guidelines.

```bash
npm install && npm run build && npm test
```

## License

MIT License - See [LICENSE](LICENSE) for details.
