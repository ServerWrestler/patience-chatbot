# Changelog

All notable changes to Patience for macOS will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **Adversarial testing — real attack prompts & editable adversary prompt.** Strategy prompts
  are now first-class data: a `RedTeam` strategy carrying the full OWASP LLM Top 10 + MITRE
  ATLAS arsenal, an editable Adversary Prompt box pre-filled with the selected strategy's
  built-in prompt (persisted as an override only when changed), and 16 load-in templates
  grouped as Full Arsenals / OWASP LLM Top 10 (LLM01–LLM10) / Tactics.
- **Adaptive probing.** Auto-escalate (per-strategy turn ladder), adapt-on-refusal, and
  best-of-N candidate selection, with a live per-strategy caption explaining what
  Auto-escalate does for the current strategy.
- **Judge / critic pass.** An optional second model scores each target reply for a breach
  (severity + rationale), shown as a badge in a new adversarial transcript viewer.
- **Attack-library flywheel.** Harvests breached probes and re-injects them as few-shot
  examples; viewer with tags, tag filtering, and JSON import/export.
- **Safety controls.** Cost cap (hard stop), request-rate throttle (waits, doesn't abort),
  and a non-destructive content filter that flags secret/PII-shaped replies.
- **Conversation Forensics — guardrail-failure triage.** A cost-aware triage cascade that
  classifies where and how a target chatbot's guardrails failed, per turn and across the
  episode, mapped to the OWASP LLM Top 10:2025.
  - `Core/Forensics/ForensicsTriage.swift` — per-turn router (deterministic validators →
    local judge with self-consistency → redacted frontier escalation).
  - `Core/Forensics/EpisodeForensics.swift` — trajectory pass that catches multi-turn
    attacks (crescendo, incremental exfiltration) invisible turn-by-turn.
  - `Core/Forensics/FlywheelStore.swift` — verdict provenance + curated, redacted, deduped
    JSONL export for fine-tuning the local judge.
  - Verdict contract (`docs/forensics/forensics-schema.json`) and judge rubric
    (`docs/forensics/judge-rubric.md`), version `1.0.0-owasp2025`.
  - Guides: [Conversation Forensics — Triage](docs/CONVERSATION_FORENSICS_TRIAGE_GUIDE.md)
    and [Forensics Contribution Boundary](docs/FORENSICS_CONTRIBUTION_BOUNDARY.md).
  - Implementation plan: [docs/forensics/IMPLEMENTATION_PLAN.md](docs/forensics/IMPLEMENTATION_PLAN.md).

> Note: the shipped forensics code is a reference implementation — interfaces and routing
> logic. Judge models, the calibration dataset, and validator/store internals are tracked as
> follow-up work (and, where applicable, a private asset).

### Changed
- Scenario testing now uses the Ollama `/api/chat` endpoint (was legacy `/api/generate`),
  with smarter endpoint normalization and actionable 405 diagnostics.

### Security
- **All secrets now live in the Keychain only.** Scenario target-bot credentials and the
  judge provider key are moved to the macOS Keychain (device-only,
  `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`) and blanked from persisted configs and
  exports; keys are re-hydrated from the Keychain at run time. A one-time migration moves any
  previously inline-stored secrets out of UserDefaults on first launch.
- Removed debug logging that could write endpoints, request bodies, and imported config JSON
  (including credentials) to the system log.

---

## Development Information

### Build Requirements
- Xcode 15.0 or later
- Swift 5.9 or later
- macOS 13.0 SDK or later

### Dependencies
- No external dependencies - uses only native Swift and SwiftUI frameworks
- Leverages Foundation, Network, and Security frameworks
- Uses Combine for reactive programming

### Installation
1. Download from releases page or build from source
2. Drag to Applications folder
3. Launch and grant necessary permissions
4. Begin testing with sample configurations

---

## Version History Notes

This changelog follows semantic versioning:
- **Major version** (1.x.x) - Breaking changes or major new features
- **Minor version** (x.1.x) - New features, backward compatible
- **Patch version** (x.x.1) - Bug fixes, backward compatible

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines on:
- Setting up development environment
- Code style and standards
- Testing requirements
- Pull request process

## Support

For issues, questions, or feature requests:
1. Check existing documentation
2. Search closed issues
3. Open a new issue with detailed information
