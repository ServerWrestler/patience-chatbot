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
patience config.json

# Analyze logs
patience analyze conversations.json

# Adversarial testing (local, free)
patience adversarial --target http://localhost:3000/chat --adversary ollama
```

See [examples/](examples/) for configuration files.

## CLI Commands

```bash
# Live testing
patience config.json
patience --help

# Log analysis
patience analyze conversations.json
patience analyze --config analysis-config.json

# Adversarial testing
patience adversarial --target <url> --adversary ollama
patience adversarial --config adversarial-config.json
```

Run `patience <command> --help` for detailed options.

## Configuration

See [examples/](examples/) for complete configuration files:
- Live testing: See README examples
- Log analysis: `examples/analysis-config.json`
- Adversarial testing: `examples/adversarial-*.json`

**Validation types:** exact, pattern, semantic, custom  
**Protocols:** HTTP, WebSocket  
**Report formats:** JSON, HTML, Markdown, CSV

## Log Analysis

Analyze historical conversations in JSON, CSV, or text format.

**Features:** Metrics calculation, pattern detection, context analysis, filtering

**Example:**
```bash
patience analyze conversations.json
```

See [examples/sample-logs/](examples/sample-logs/) for format specifications.

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
- **[examples/ADVERSARIAL_TESTING.md](examples/ADVERSARIAL_TESTING.md)** - Detailed adversarial guide
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

AI-powered bot-to-bot testing with multiple LLM providers.

**Providers:** Ollama (local/free), OpenAI (GPT-4), Anthropic (Claude)  
**Strategies:** Exploratory, adversarial, focused, stress

**Example:**
```bash
patience adversarial --target http://localhost:3000/chat --adversary ollama
```

See [examples/ADVERSARIAL_TESTING.md](examples/ADVERSARIAL_TESTING.md) for detailed guide.

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development setup and guidelines.

```bash
npm install && npm run build && npm test
```

## License

MIT License - See [LICENSE](LICENSE) for details.
