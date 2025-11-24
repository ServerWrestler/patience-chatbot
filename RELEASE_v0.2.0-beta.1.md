# Release v0.2.0-beta.1

## 🎉 What's New

### All Three LLM Providers Now Supported!

v0.2.0 adds full support for OpenAI and Anthropic, completing the adversarial testing feature:

- ✅ **Ollama** - Local models (llama2, mistral, etc.) - Free
- ✅ **OpenAI** - GPT-4, GPT-4-turbo, GPT-3.5 - NEW!
- ✅ **Anthropic** - Claude 3 (Opus, Sonnet, Haiku) - NEW!

### Reorganized Examples Directory

The examples directory is now beautifully organized by testing mode:

```
examples/
├── live-testing/          # Live scenario-based testing
├── log-analysis/          # Historical log analysis
└── adversarial-testing/   # AI-powered bot-to-bot testing
```

Each directory includes:
- Comprehensive README with all options
- Simple, standard, and advanced configuration examples
- Use cases, tips, and troubleshooting

### Enhanced Documentation

- **Expanded README** - Detailed CLI options and configuration examples for all modes
- **Progressive Examples** - Start simple, progress to advanced
- **Better Navigation** - Clear structure with guides in each directory

## 📦 Installation

```bash
git clone https://github.com/ServerWrestler/patience-chatbot.git
cd patience-chatbot
npm install && npm run build
```

## 🚀 Quick Start

### Live Testing
```bash
patience examples/live-testing/simple-config.json
```

### Log Analysis
```bash
patience analyze examples/log-analysis/sample-logs/conversations.json
```

### Adversarial Testing

**With Ollama (local/free):**
```bash
patience adversarial --config examples/adversarial-testing/simple-config.json
```

**With OpenAI:**
```bash
patience adversarial --config examples/adversarial-testing/adversarial-openai-config.json
```

**With Anthropic:**
```bash
patience adversarial --config examples/adversarial-testing/adversarial-anthropic-config.json
```

## 🆕 New Features

### OpenAI Integration
- Full GPT-4 and GPT-3.5 support
- Rate limiting and cost tracking
- Exponential backoff with retries
- Context-aware prompting

### Anthropic Integration
- Claude 3 models (Opus, Sonnet, Haiku)
- Rate limiting and error handling
- System prompt with context injection
- Proper message formatting

### Organized Examples
- **live-testing/** - 3 configuration levels with complete guide
- **log-analysis/** - 3 configuration levels with sample data
- **adversarial-testing/** - Configurations for all 3 providers

### Enhanced Documentation
- Detailed README in each example directory
- Expanded main README with CLI options
- Configuration examples for all modes
- Progressive complexity (simple → advanced)

## 📚 Documentation

- [README.md](README.md) - Main documentation
- [examples/](examples/) - All examples and guides
- [examples/live-testing/README.md](examples/live-testing/README.md) - Live testing guide
- [examples/log-analysis/README.md](examples/log-analysis/README.md) - Log analysis guide
- [examples/adversarial-testing/README.md](examples/adversarial-testing/README.md) - Adversarial testing guide
- [CHANGELOG.md](CHANGELOG.md) - Complete changelog

## 🔄 Changes from v0.1.0

### Added
- OpenAI connector with full GPT support
- Anthropic connector with Claude 3 support
- Organized examples directory structure
- Progressive configuration examples (simple/standard/advanced)
- Comprehensive guides for each testing mode
- Expanded CLI documentation in README

### Improved
- Better examples organization
- Enhanced documentation structure
- Clearer navigation between modes
- More detailed configuration explanations

## ⚠️ Beta Notice

This is a beta release. Core functionality is stable and tested, but feedback is welcome!

## 🐛 Known Issues

None currently. Please report any issues you find!

## 🙏 Feedback

Try it out and let us know what you think!

- Report issues: https://github.com/ServerWrestler/patience-chatbot/issues
- Discussions: https://github.com/ServerWrestler/patience-chatbot/discussions

## 📝 Full Changelog

See [CHANGELOG.md](CHANGELOG.md) for complete details.

---

**Previous Release:** [v0.1.0-beta.1](https://github.com/ServerWrestler/patience-chatbot/releases/tag/v0.1.0-beta.1)
