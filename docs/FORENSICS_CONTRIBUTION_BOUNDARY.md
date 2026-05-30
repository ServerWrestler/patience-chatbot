# Forensics Contribution Boundary — Open vs. Private

Patience is **open-core**. The forensics layer is split deliberately between what ships in
the open-source repo and what stays a private asset. This note makes that line explicit so
contributors know what belongs where, and so the project's compliance and commercial
positioning stay intact.

---

## The principle

The value of Patience forensics is **not** the architecture — it's the trained judge and
the data behind it. The architecture is adoption fuel: the more tools that speak the
Patience forensics format, the more valuable the ecosystem (and the private asset) becomes.
So we publish the *how it works* and keep the *model trained on operational output*.

> Publishing the open half increases the worth of the closed half. They are not in tension.

---

## Open source (this repo, MIT)

Contributions welcome here. This is the public standard.

- **Verdict schema** (`docs/forensics/forensics-schema.json`) — the output contract. We *want*
  other tools to emit Patience-format verdicts. Treat it like a spec: changes are versioned
  (`rubricVersion`) and backward compatibility matters.
- **Judge rubric** (`docs/forensics/judge-rubric.md`) — taxonomy, severity scale, few-shot
  examples. PRs that improve examples or sharpen definitions are high-value.
- **Triage architecture** (`Patience/Core/Forensics/*.swift` reference implementation) — router,
  episode pass, flywheel store interfaces. The *interfaces* and *routing logic* are public.
- **Deterministic validators** — refusal detection, signature matching, PII scanning.
  Generic detectors belong here.
- **Docs** — guides, this note, integration docs.

## Private (separate repo, not published)

Do **not** contribute these here, and do not include them in PRs to this repo:

- **Fine-tuned judge weights** — the model trained on accumulated calibration data.
- **Calibration / training dataset** — the curated local-vs-authoritative disagreement
  pairs. This is the proprietary asset the flywheel produces.
- **Customer transcripts** — any real red-team output, redacted or not. Never in the public repo.
- **Domain-specific detector tuning** — e.g. client-specific `aggregateLeak` recombination
  rules or vertical-specific signature sets that encode paid engagement knowledge.

---

## The line in one sentence

If it describes **how forensics works**, it's public. If it's **a model, the data that
trained it, or client-derived knowledge**, it's private.

---

## Contributor checklist

Before opening a PR that touches the forensics layer:

- [ ] No real transcripts, customer data, or PII — including in test fixtures (use synthetic).
- [ ] Schema changes bump `rubricVersion` and note backward-compat impact.
- [ ] No fine-tuned weights or training data committed.
- [ ] New detectors are generic, not client-specific.
- [ ] License-compatible: any model or dataset a feature *depends on* must permit the use
      the docs imply. Flag non-commercial / restricted licenses (some community GGUFs carry
      unusual terms) before merging — the public docs must not imply usage a dependency forbids.

---

## A note on the license boundary

Patience is MIT, which permits commercial use of the harness. That does **not** automatically
extend to models or datasets the forensics layer runs on. Keep the distinction clear in docs:
the *harness* is MIT; the *judge model you fine-tune* is yours under whatever terms you choose;
a *third-party base model* is bound by its own license. Conflating these is the easiest way to
create a liability you didn't intend.

---

## Related

- [Conversation Forensics Triage Guide](CONVERSATION_FORENSICS_TRIAGE_GUIDE.md)
- [CONTRIBUTING.md](../CONTRIBUTING.md)
