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
| [Scenario Testing](docs/SCENARIO_TESTING_GUIDE.md) | ✅ Implemented | Scenario-based chatbot testing |
| [Adversarial Testing](docs/ADVERSARIAL_TESTING_GUIDE.md) | ✅ Implemented | AI-powered automated testing |
| [Adversarial Prompts](docs/ADVERSARIAL_TESTING_PROMPTS.md) | ✅ Reference | OWASP/MITRE attack patterns |
| [Conversation Forensics](docs/CONVERSATION_FORENSICS_GUIDE.md) | ✅ Implemented | Historical conversation analysis and pattern detection |
| [Conversation Forensics — Triage](docs/CONVERSATION_FORENSICS_TRIAGE_GUIDE.md) | ⚠️ Reference impl | Guardrail-failure classification via a local→frontier triage cascade (OWASP LLM Top 10) |
| [Forensics Contribution Boundary](docs/FORENSICS_CONTRIBUTION_BOUNDARY.md) | ✅ Reference | Open-core boundary: what's public vs. a private asset |

## Architecture Overview

```
Patience/
├── Models/          # Data structures (Codable, Sendable)
├── Core/            # Business logic (TestExecutor, AnalysisEngine, etc.)
│   └── Forensics/   # Guardrail-failure triage cascade (router, episode pass, flywheel)
├── Views/           # SwiftUI views
├── ContentView.swift
└── PatienceApp.swift
```

For detailed architecture and development patterns, see [CLAUDE.md](CLAUDE.md).

## Technology Stack

- Swift 5.9+ / SwiftUI
- macOS 13.0+
- Async/await concurrency
- Keychain Services for secure storage

## Support

- [GitHub Issues](https://github.com/ServerWrestler/patience-chatbot/issues)
