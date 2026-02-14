# Patience Documentation

## Quick Links

| Document | Purpose |
|----------|---------|
| [README.md](README.md) | Installation, features, quick start |
| [CONTRIBUTING.md](CONTRIBUTING.md) | Development setup, contribution guidelines |
| [CHANGELOG.md](CHANGELOG.md) | Version history |
| [SECURITY.md](SECURITY.md) | Security policies, vulnerability reporting |

## Feature Guides

| Guide | Status | Description |
|-------|--------|-------------|
| [Live Testing](docs/LIVE_TESTING_GUIDE.md) | ✅ Implemented | Scenario-based chatbot testing |
| [Adversarial Testing](docs/ADVERSARIAL_TESTING_GUIDE.md) | ✅ Implemented | AI-powered automated testing |
| [Adversarial Prompts](docs/ADVERSARIAL_TESTING_PROMPTS.md) | ✅ Reference | OWASP/MITRE attack patterns |
| [Log Analysis](docs/LOG_ANALYSIS_GUIDE.md) | ⚠️ Planned | Historical conversation analysis |

## Architecture Overview

```
Patience/
├── Models/          # Data structures (Codable, Sendable)
├── Core/            # Business logic (TestExecutor, AnalysisEngine, etc.)
├── Views/           # SwiftUI views
├── ContentView.swift
└── PatienceApp.swift
```

For detailed architecture and development patterns, see [AI_ASSISTANT_GUIDE.md](AI_ASSISTANT_GUIDE.md).

## Technology Stack

- Swift 5.9+ / SwiftUI
- macOS 13.0+
- Async/await concurrency
- Keychain Services for secure storage

## Support

- [GitHub Issues](https://github.com/ServerWrestler/patience-chatbot/issues)
- [GitHub Discussions](https://github.com/ServerWrestler/patience-chatbot/discussions)
