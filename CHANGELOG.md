# Changelog

All notable changes to Patience will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0-beta.1] - 2025-11-24

### Added
- **OpenAI Connector** - Full GPT-4, GPT-4-turbo, and GPT-3.5 support for adversarial testing
- **Anthropic Connector** - Claude 3 models (Opus, Sonnet, Haiku) support for adversarial testing
- **Organized Examples Directory** - Restructured examples into three clear directories:
  - `examples/live-testing/` - Live testing configurations and guide
  - `examples/log-analysis/` - Log analysis configurations and sample data
  - `examples/adversarial-testing/` - Adversarial testing configurations for all providers
- **Progressive Configuration Examples** - Each mode now has simple, standard, and advanced configs
- **Comprehensive Documentation** - Each example directory has detailed README with:
  - Complete configuration options
  - CLI usage examples
  - Use cases and tips
  - Troubleshooting guides

### Changed
- **Expanded README** - Added detailed CLI options and configuration examples for all three modes
- **Improved Examples Structure** - Better organization for easier navigation and learning
- **Enhanced Live Testing Documentation** - Added comprehensive guide with all options explained

### Documentation
- Created detailed README for each testing mode
- Added configuration examples at three complexity levels
- Improved main README with expanded usage information
- Added examples/README.md as navigation hub

## [0.1.0-beta.1] - 2025-11-23

### Added
- **Adversarial Testing Feature** - Bot-to-bot automated testing
  - Ollama connector for local LLM models
  - OpenAI connector for GPT-4 and GPT-3.5
  - Anthropic connector for Claude 3 models
  - Five testing strategies: exploratory, adversarial, focused, stress, and custom
  - Real-time validation during conversations
  - Multi-format conversation logging (JSON, text, CSV)
  - Rate limiting and cost tracking for paid APIs
  - Comprehensive CLI integration with `patience adversarial` command
  - Complete documentation in `examples/ADVERSARIAL_TESTING.md`

- **Chat Log Analysis Feature** - Retrospective testing of historical logs
  - Multi-format log parsing (JSON, CSV, text)
  - Automatic format detection
  - Advanced conversation filtering (date range, message count, user ID, content)
  - Pattern detection for failures and successes
  - Context retention analysis with scoring
  - Comprehensive metrics calculation
  - Multi-format report generation (HTML, JSON, Markdown, CSV)
  - CLI integration with `patience analyze` command

### Changed
- Updated README.md with comprehensive documentation for all features
- Enhanced project structure to support modular architecture

### Documentation
- Added CONTRIBUTING.md with contribution guidelines
- Added CHANGELOG.md for tracking changes
- Added examples/ADVERSARIAL_TESTING.md with detailed guide
- Added examples/sample-logs/README.md and USAGE.md
- Updated README.md with all three major features

## [0.1.0-beta.0] - 2025-11-21

### Added
- Initial release of Patience
- Live bot testing with scenario-based approach
- HTTP and WebSocket protocol support
- Multiple validation types (exact, pattern, semantic, custom)
- Message generation capabilities
- Context handling for multi-turn conversations
- Timing control for realistic interactions
- Comprehensive reporting (JSON, HTML, Markdown)
- Configuration management with YAML/JSON support
- CLI interface for running tests
- TypeScript implementation with full type safety
- Unit and integration tests with Vitest
- Property-based testing with fast-check

### Documentation
- README.md with quick start guide
- LICENSE file (MIT)
- SECURITY.md with security policy
- Example configuration files

[Unreleased]: https://github.com/ServerWrestler/patience-chatbot/compare/v0.2.0-beta.1...HEAD
[0.2.0-beta.1]: https://github.com/ServerWrestler/patience-chatbot/releases/tag/v0.2.0-beta.1
[0.1.0-beta.1]: https://github.com/ServerWrestler/patience-chatbot/releases/tag/v0.1.0-beta.1
