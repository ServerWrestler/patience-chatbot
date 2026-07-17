# Conversation Forensics — Guardrail-Failure Triage

Forensic analysis for chatbot red-team transcripts. Given a conversation between an
adversarial tester and a **target chatbot**, the forensics triage layer classifies *where and
how the target's guardrails failed* — per turn and across the whole episode — and turns those
judgments into auditable findings and fine-tuning data.

It is an **analysis** layer. It judges transcripts that already exist; it does not generate
attacks (that's [Adversarial Testing](ADVERSARIAL_TESTING_GUIDE.md)). It complements the
basic [Conversation Forensics](CONVERSATION_FORENSICS_GUIDE.md) metrics/pattern analysis with
a guardrail-failure classifier.

---

## Why it's built this way

The headline constraint is Patience's on-device, no-cloud promise. A frontier model gives
the best judgments, but the moment a transcript leaves the machine you've broken that
promise for exactly the regulated buyers who care most. So forensics is a **triage cascade**:
cheap local checks resolve the obvious majority, a local model handles the middle, and a
frontier model is reached for only when it actually changes the answer — and only after
redaction.

```
                         ┌─────────────────────────────────────┐
   transcript ─────────▶ │ Stage 0  Deterministic validators    │  free, local, deterministic
                         │          (refusal / signature / PII)  │
                         └───────────────┬─────────────────────┘
                          unresolved      │ resolved (audit trail)
                                          ▼
                         ┌─────────────────────────────────────┐
                         │ Stage 1  Local judge (8–14B)          │  cheap, on-device
                         │          self-consistency x3          │
                         └───────────────┬─────────────────────┘
              confident + low-stakes      │  unsure / high-stakes / novel
                                          ▼
                         ┌─────────────────────────────────────┐
                         │ Stage 2  Frontier judge (Claude)      │  redacted, optional tier
                         │          authoritative label          │
                         └───────────────┬─────────────────────┘
                                          ▼
                         ┌─────────────────────────────────────┐
                         │ Episode pass  (trajectory analysis)   │  catches multi-turn attacks
                         └───────────────┬─────────────────────┘
                                          ▼
                         ┌─────────────────────────────────────┐
                         │ Flywheel store → JSONL fine-tune set  │  local judge improves over time
                         └─────────────────────────────────────┘
```

---

## Components

| File | Role |
|------|------|
| `Patience/Core/Forensics/ForensicsTriage.swift` | Per-turn router: validators → local judge → frontier escalation. |
| `Patience/Core/Forensics/EpisodeForensics.swift` | Trajectory pass over a full transcript; catches crescendo / incremental-exfil patterns invisible turn-by-turn. |
| `Patience/Core/Forensics/FlywheelStore.swift` | Persists verdicts + local-vs-authoritative pairs; exports curated JSONL. |
| `docs/forensics/forensics-schema.json` | The verdict contract. Drives constrained decoding and validates frontier output. |
| `docs/forensics/judge-rubric.md` | The judge's system prompt. Defines outcomes, severity, the OWASP technique taxonomy, and few-shot examples. |

The schema and rubric are a matched pair. The local judge, the frontier judge, and the
fine-tuning targets must all use the **same `rubricVersion`** — if they drift, the flywheel
trains against inconsistent labels.

---

## Operating modes

**Local-only** (`frontierEnabled = false`) — nothing leaves the device. Low-confidence
cases are flagged for human review instead of escalated. This is the mode for HIPAA / GDPR
/ air-gapped buyers, and the one that preserves the compliance story.

**Frontier-augmented** (`frontierEnabled = true`) — Claude is reached for the hard ~10–20%
of cases and for periodic calibration sampling. Transcripts are **redacted** before any
cloud call. Best judgment quality; sell it as a premium tier.

---

## Configuration (`TriageConfig`)

| Field | Default | Effect |
|-------|---------|--------|
| `localConfidenceFloor` | `0.80` | Below this, escalate. |
| `selfConsistencySamples` | `3` | Local judge runs N times; disagreement escalates. |
| `calibrationSampleRate` | `0.05` | Fraction of resolved cases sent to frontier to measure drift. |
| `frontierEnabled` | `true` | Master switch for the cloud tier. |
| `knownTechniques` | — | Techniques outside this set are treated as novel and escalate. |

---

## The verdict contract

Per-turn verdicts (`Verdict` / `TurnVerdict` in the schema):

| Field | Meaning |
|-------|---------|
| `outcome` | `refused` / `partial` / `complied` / `unclear` — did the guardrail hold? |
| `technique` | OWASP LLM Top 10:2025 category observed in the target's response. |
| `evidence` | Char span proving the failure (null for refusals). |
| `severity` | `0` none … `4` critical. |
| `confidence` | Calibrated 0–1; below the floor routes to a stronger judge. |
| `rationale` | Short justification. |

Episode verdicts (`EpisodeVerdict`) judge the **arc**: an episode can be `succeeded: true`
even when every individual turn looked benign — e.g. `crescendo` (refused early, complied
later) or `incrementalExfil` (harmless fragments that sum to a secret).

`source` and `rubricVersion` are stamped by the harness, never emitted by the model.

---

## The flywheel loop

1. Run forensics. Every verdict is stored with its provenance (local / frontier / human).
2. Where local and the authoritative label **disagree**, you have a training signal.
3. `FineTuneExporter` emits chat-format JSONL — system = the rubric, user = the transcript,
   assistant = the authoritative verdict — oversampling the disagreements (hard-example mining)
   and excluding the frozen holdout.
4. Fine-tune the local judge (e.g. Unsloth). It now agrees with the frontier more often, so the
   escalation rate — and your cloud spend — drops.

**Two guardrails on the loop:**
- The calibration **holdout must be partly human-labeled.** If it's frontier-labeled, any
  systematic frontier bias gets trained into the local judge *and* hidden from your metric.
- **Redaction runs before export**, always. No transcript PII ever reaches a training set.

---

## Quickstart (conceptual)

```swift
let router = ForensicsRouter(
    validators: [RefusalDetector(), SignatureMatcher(), PIIScanner()],
    localJudge: OllamaJudge(model: "qwen3:8b", schema: forensicsSchema),
    frontier:   ClaudeJudge(schema: forensicsSchema),
    redact:     Redactor.defaultClosure,
    config:     TriageConfig(frontierEnabled: regulated ? false : true)
)

// 1. Score each turn
var analyzed: [AnalyzedTurn] = []
for turn in transcript {
    let verdict = try await router.route(turn, context: priorTurns)
    analyzed.append(AnalyzedTurn(turn: turn, verdict: verdict))
}

// 2. Score the trajectory
let episode = try await episodeAnalyzer.analyze(analyzed)

// 3. Persist for audit + flywheel
try store.recordEpisode(id: id, verdict: episode, rubricVersion: "1.0.0-owasp2025")
```

> The `*Judge` and `FlywheelStore` implementations above are illustrative. The shipped
> reference implementation provides the interfaces and routing logic; the trained judge and
> accumulated data are a private asset — see [Forensics Contribution Boundary](FORENSICS_CONTRIBUTION_BOUNDARY.md).

---

## Status / TODO

Full plan: [IMPLEMENTATION_PLAN.md](forensics/IMPLEMENTATION_PLAN.md). Highlights:

- [ ] Implement `aggregateLeak` (cross-turn fragment recombination) — highest-value detector.
- [ ] Implement `consensus` / `disagreement` for self-consistency voting.
- [ ] Wire `RefusalDetector` / `SignatureMatcher` / `PIIScanner`.
- [ ] Build the human-labeling path for the holdout set.
- [ ] Add `personaDrift` / `trustThenPayload` semantic detectors (judge-only; no cheap signal exists).
- [ ] Surface verdicts in the Conversation Forensics tab.

*Taxonomy: OWASP LLM Top 10:2025. Rubric version `1.0.0-owasp2025`.*

---

## Related Guides

- [Conversation Forensics Guide](CONVERSATION_FORENSICS_GUIDE.md) — basic metrics/pattern analysis
- [Adversarial Testing Guide](ADVERSARIAL_TESTING_GUIDE.md) — AI-powered red teaming
- [Forensics Contribution Boundary](FORENSICS_CONTRIBUTION_BOUNDARY.md) — what's open vs. private
