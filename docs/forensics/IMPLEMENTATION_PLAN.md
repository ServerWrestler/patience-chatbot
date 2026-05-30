# Implementation Plan: Conversation Forensics Triage

The actionable TODO for the guardrail-failure triage cascade. See
[Conversation Forensics — Triage Guide](../CONVERSATION_FORENSICS_TRIAGE_GUIDE.md) for the
design and [Forensics Contribution Boundary](../FORENSICS_CONTRIBUTION_BOUNDARY.md) for what's
public vs. a private asset.

## Phase 1: Contract & Scaffolding ✅

- [x] 1. Define the verdict contract
  - [x] 1.1 Author `docs/forensics/forensics-schema.json` (TurnVerdict + EpisodeVerdict)
    - Closed OWASP LLM Top 10:2025 technique list; severity 0–4; evidence spans
  - [x] 1.2 Author `docs/forensics/judge-rubric.md` (system prompt + few-shot examples)
    - Stamp `rubricVersion: 1.0.0-owasp2025`

- [x] 2. Add the reference implementation to the source tree
  - [x] 2.1 `Core/Forensics/ForensicsTriage.swift` — core types, stage protocols, router
  - [x] 2.2 `Core/Forensics/EpisodeForensics.swift` — trajectory pass + cheap signals
  - [x] 2.3 `Core/Forensics/FlywheelStore.swift` — provenance, store protocol, exporter
  - [x] 2.4 Register all three files in the Xcode project and confirm the app builds

## Phase 2: Stage 0 — Deterministic Validators ⚠️

- [ ] 3. Wire the generic validators (currently interface-only)
  - [ ] 3.1 Implement `RefusalDetector` (`DeterministicPass`)
    - High-confidence refusal classification; emits `outcome: refused`, `severity: none`
  - [ ] 3.2 Implement `SignatureMatcher` (`DeterministicPass`)
    - Match known leak/payload signatures to a technique + evidence span
  - [ ] 3.3 Implement `PIIScanner` (`DeterministicPass`)
    - Detect PII/PHI spans; feed both Stage 0 verdicts and the redactor
  - [ ] 3.4 Implement the `redact: (Turn) -> Turn` scrubber used before frontier/export

## Phase 3: Stage 1 — Local Judge

- [ ] 4. Self-consistency voting (replace router stubs)
  - [ ] 4.1 Implement `consensus(of:)` — majority outcome + aggregated confidence
  - [ ] 4.2 Implement `disagreement(_:)` — detect sample contradiction → escalate
- [ ] 5. Implement a local `Judge` (Ollama, constrained decoding)
  - [ ] 5.1 Drive Ollama with `format=json` / GBNF against the schema
    - Reuse provider plumbing from the adversarial layer where possible
  - [ ] 5.2 Validate model output against `forensics-schema.json` before use

## Phase 4: Stage 2 — Frontier Escalation

- [ ] 6. Implement a frontier `Judge` (Claude)
  - [ ] 6.1 Send redacted turn + context; validate output against the schema
  - [ ] 6.2 Honor `frontierEnabled = false` → flag low-confidence cases for human review
  - [ ] 6.3 Implement calibration sampling at `calibrationSampleRate` (non-blocking)

## Phase 5: Episode (Trajectory) Analysis

- [ ] 7. Implement `aggregateLeak` (cross-turn fragment recombination)
  - Highest-value detector: do the pieces together form PII / a full secret?
- [ ] 8. Implement episode `EpisodeJudge`s (local + frontier)
  - [ ] 8.1 Trajectory prompt that judges the arc, sets `pivotTurn` + `contributingTurns`
  - [ ] 8.2 Add `personaDrift` / `trustThenPayload` semantic detection (judge-only)

## Phase 6: Flywheel & Fine-Tuning

- [ ] 9. Implement a concrete `FlywheelStore`
  - [ ] 9.1 Persist `LabeledTurn` + episode verdicts with provenance (local on-device store)
  - [ ] 9.2 Wire `recordCalibrationPair` from the router into the store
- [ ] 10. Build the human-labeling path for the holdout set
  - [ ] 10.1 `markHoldout` / `isHoldout` UI + a partly-human-labeled calibration set
- [ ] 11. Verify `FineTuneExporter` end-to-end
  - [ ] 11.1 Dedup, disagreement oversampling, holdout exclusion, redaction-before-export

## Phase 7: UI Integration

- [ ] 12. Surface verdicts in the Conversation Forensics tab
  - [ ] 12.1 Findings panel: per-turn verdicts with evidence highlight + severity badges
  - [ ] 12.2 Episode summary: pattern, pivot turn, contributing turns
  - [ ] 12.3 Mode toggle for `frontierEnabled` (local-only vs. frontier-augmented)
  - [ ] 12.4 "Turn incident into test case" — export a verdict as a Scenario/Adversarial config

## Phase 8: Testing

- [ ] 13. Unit tests with **synthetic** transcripts only (no real/customer data)
  - [ ] 13.1 Router escalation logic (each `shouldEscalate` trigger)
  - [ ] 13.2 Episode cheap signals (`refuseThenComply`, `severityIsClimbing`)
  - [ ] 13.3 Exporter: dedup, oversampling, holdout exclusion
  - [ ] 13.4 Schema-conformance round-trip for `Verdict` / `EpisodeVerdict`

## Notes / Contribution Boundary

- Keep fine-tuned judge weights, the calibration dataset, customer transcripts, and
  client-specific detector tuning **out of this repo** (see
  [FORENSICS_CONTRIBUTION_BOUNDARY.md](../FORENSICS_CONTRIBUTION_BOUNDARY.md)).
- Any schema change bumps `rubricVersion` and notes backward-compat impact.
- New detectors must be generic, not client-specific. Test fixtures must be synthetic.
