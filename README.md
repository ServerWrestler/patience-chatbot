## ⏳ PATIENCE

Automated red teaming · Compliance validation

[Download](https://github.com/ServerWrestler/patience-chatbot/releases) · [patience-chatbot.ai](https://patience-chatbot.ai)

---

## Three Testing Modes

**Scenario Testing** — Script multi-turn conversation flows, validate responses against custom rules, catch regressions before production.

**Conversation Forensics** — Import production logs, surface failure patterns and policy violations, turn incidents into test cases. A guardrail-failure triage cascade classifies *where and how* a target's guardrails failed — per turn and across the whole episode — mapping findings to the OWASP LLM Top 10, staying on-device by default and reaching a frontier judge only when it changes the answer (and only after redaction).

**Adversarial Testing** — AI autonomously probes your chatbot for prompt injection, jailbreaks, and social engineering. Maps findings to OWASP LLM Top 10 and MITRE ATLAS.

## Requirements

- macOS 13.0+
- Xcode 15.0+ (to build from source)

## Quick Start

```bash
git clone https://github.com/ServerWrestler/patience-chatbot.git
open Patience.xcodeproj
```

## Docs

[Documentation](DOCUMENTATION.md) · [Contributing](CONTRIBUTING.md) · [Security](SECURITY.md) · [Changelog](CHANGELOG.md)

## License

MIT
