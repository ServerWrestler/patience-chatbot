<div align="center">

# ⏳ Patience

### Automated red teaming & compliance validation for AI chatbots — purpose-built for regulated industries.

**Zero cloud dependencies.** Built for teams where data residency and auditability aren't optional.

[![Platform](https://img.shields.io/badge/platform-macOS%2013%2B-1a1a1a)](#requirements)
[![Swift](https://img.shields.io/badge/Swift-5.9-f05138)](#requirements)
[![Cloud](https://img.shields.io/badge/cloud-zero%20dependencies-2ea043)](#-built-for-security)
[![License](https://img.shields.io/badge/license-MIT-3b82f6)](LICENSE)

[**Download**](https://github.com/ServerWrestler/patience-chatbot/releases) ·
[**Website**](https://patience-chatbot.ai) ·
[**Documentation**](DOCUMENTATION.md) ·
[**Security**](SECURITY.md)

</div>

---

## Why Patience?

Patience is a native macOS app that red-teams and validates your AI chatbots **entirely on
your machine**. No attack traffic, transcripts, or test results leave the device — so you get
audit-ready evidence without breaking HIPAA, SOC 2, FedRAMP, or GDPR data-residency rules. It
runs fully air-gapped when you need it to.

|  |  |
|---|---|
| 🔒 **100% On-Device** | Zero cloud dependencies. Nothing is transmitted externally. |
| 🤖 **AI-Powered Red Teaming** | Autonomous probing for prompt injection, jailbreaks, and social engineering. |
| 📋 **Audit-Ready Evidence** | Findings mapped to the [OWASP LLM Top 10](docs/ADVERSARIAL_TESTING_PROMPTS.md) and MITRE ATLAS. |
| 🧩 **Works With Your Stack** | Test any HTTP/WebSocket endpoint — OpenAI, Anthropic, Ollama, or custom. |

## Three Testing Modes

### 🎬 [Scenario Testing](docs/SCENARIO_TESTING_GUIDE.md)
Script multi-turn conversation flows and run them against any endpoint; validate each response
against custom business rules in real time, and catch regressions before production.

### 🔎 [Conversation Forensics](docs/CONVERSATION_FORENSICS_GUIDE.md)
Import production logs in JSON, CSV, or plain text; surface failure patterns, policy
violations, and drift over time. A [guardrail-failure triage cascade](docs/CONVERSATION_FORENSICS_TRIAGE_GUIDE.md)
then classifies *where and how* a target's guardrails failed — per turn and across the whole
episode — staying on-device by default and reaching a frontier judge only when it changes the
answer (and only after redaction).

### ⚔️ [Adversarial Testing](docs/ADVERSARIAL_TESTING_GUIDE.md)
AI autonomously probes your chatbot — prompt injection, jailbreaks, social engineering, and
stress loads — then maps every finding to the [OWASP LLM Top 10 and MITRE ATLAS](docs/ADVERSARIAL_TESTING_PROMPTS.md).

## 🛡 Built for Security

Patience is designed for environments where data can't leave the building:

- **Fully on-device / air-gappable** — no attack traffic or test results transmitted externally.
- **Compliance-aligned** — supports HIPAA, SOC 2, FedRAMP, and GDPR data-residency requirements.
- **Secrets stay in the Keychain** — API keys are never written to configs or source.
- **Open-core forensics** — the architecture, [verdict schema](docs/forensics/forensics-schema.json),
  and [judge rubric](docs/forensics/judge-rubric.md) are public; trained judge models and
  calibration data remain a private asset (see the [contribution boundary](docs/FORENSICS_CONTRIBUTION_BOUNDARY.md)).

See [SECURITY.md](SECURITY.md) for the full policy and vulnerability reporting.

## Requirements

- macOS 13.0+
- Xcode 15.0+ *(to build from source)*

## Quick Start

```bash
git clone https://github.com/ServerWrestler/patience-chatbot.git
cd patience-chatbot
open Patience.xcodeproj
```

Then build and run with `⌘R`. Prefer a prebuilt binary? Grab the latest
[release](https://github.com/ServerWrestler/patience-chatbot/releases).

## Documentation

| Guide | What it covers |
|-------|----------------|
| [Scenario Testing](docs/SCENARIO_TESTING_GUIDE.md) | Scripted multi-turn conversation testing |
| [Conversation Forensics](docs/CONVERSATION_FORENSICS_GUIDE.md) | Log import, metrics, pattern & drift analysis |
| [Conversation Forensics — Triage](docs/CONVERSATION_FORENSICS_TRIAGE_GUIDE.md) | Guardrail-failure classification via a local→frontier cascade |
| [Adversarial Testing](docs/ADVERSARIAL_TESTING_GUIDE.md) | AI-powered automated red teaming |
| [Adversarial Prompts](docs/ADVERSARIAL_TESTING_PROMPTS.md) | OWASP / MITRE attack-pattern reference |

Full index: [DOCUMENTATION.md](DOCUMENTATION.md) · Version history: [CHANGELOG.md](CHANGELOG.md)

## Contributing

PRs welcome — see [CONTRIBUTING.md](CONTRIBUTING.md). Project conventions and architecture for
contributors (and AI assistants) live in [CLAUDE.md](CLAUDE.md).

## License

[MIT](LICENSE)
