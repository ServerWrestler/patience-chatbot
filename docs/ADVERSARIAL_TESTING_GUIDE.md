# Adversarial Testing Guide

Use AI models to automatically test your chatbot with challenging conversations.

## Why Adversarial Testing?

| Manual Testing | Adversarial Testing |
|----------------|---------------------|
| Limited by human creativity | AI generates unexpected inputs |
| Time-consuming | Automatic scenario generation |
| Tests what you expect | Finds what you don't expect |

## Quick Start

1. Open Patience → **Adversarial** tab
2. Click **"New Configuration"**
3. Configure your target bot endpoint
4. Choose an AI provider (Ollama recommended for starting)
5. Select a testing strategy
6. Click **"Run Test"**

## AI Providers

| Provider | Type | Cost | Setup |
|----------|------|------|-------|
| **Ollama** | Local | Free | Install from [ollama.ai](https://ollama.ai), run `ollama pull llama3.2` |
| **OpenAI** | Cloud | Paid | Get API key from [platform.openai.com](https://platform.openai.com) |
| **Anthropic** | Cloud | Paid | Get API key from [console.anthropic.com](https://console.anthropic.com) |

> API keys are stored securely in macOS Keychain.

## Testing Strategies

### Exploratory
Discovers bot capabilities with broad, diverse questions.
- Best for: Initial testing, feature discovery

### Adversarial
Finds weaknesses with edge cases and contradictions.
- Best for: General robustness validation

### Red Team
OWASP LLM Top 10 (2025) + MITRE ATLAS security probing with turn-based escalation
(recon → injection → disclosure → obfuscation → agency). Ships with the full attack
arsenal as its built-in prompt.
- Best for: Security red-teaming, audit-grade probing

### Focused
Deep dives into specific features based on defined goals.
- Best for: Feature-specific testing, regression testing

### Stress
Tests limits with rapid context switching and complex scenarios.
- Best for: Performance testing, context retention

## Adversary Prompt

The **Adversary Prompt** box always shows the system prompt that will actually be sent
to the adversarial model. By default it's pre-filled with the selected strategy's
built-in prompt — you can read it to understand what the strategy does, and edit it
to override the default.

A small status pill shows the current state:

- *Using \<strategy\> strategy default* — editor matches the built-in prompt for the
  selected strategy and goals. Will be persisted as `nil` so the same strategy and
  goals reproduce the same prompt on any machine.
- *Modified — saved as override for this config* — editor differs from the default.
  The full text is persisted with the config.

Switching strategy or changing goals while the editor still matches the default will
auto-update the editor to track the new default. Once you've made edits, strategy /
goals changes leave your text alone — click **Reset to default** to discard your
edits and load the current strategy's default.

**Load template** drops one of the curated attack templates into the editor — useful
when you want a focused single-vector probe instead of a full strategy. Templates are
grouped into submenus:

**Full Arsenals**
| Template | Focus |
|----------|-------|
| Full Red Team (OWASP + MITRE) | The complete multi-category attack arsenal |

**OWASP LLM Top 10**
| Template | Focus |
|----------|-------|
| LLM01 — Prompt Injection | Override system instructions |
| LLM02 — Sensitive Disclosure | Extract PII / credentials / cross-session data |
| LLM03 — Supply Chain | Probe model / plugin / training-source integrity |
| LLM04 — Data & Model Poisoning | Smuggle false context, RAG injection, persistent-memory abuse |
| LLM05 — Improper Output Handling | Elicit XSS / SQLi / shell-command payloads in output |
| LLM06 — Excessive Agency | Trigger unauthorized actions |
| LLM07 — System Prompt Leakage | Extract the hidden system prompt |
| LLM08 — Vector & Embedding Weaknesses | Retrieval bypass, cross-tenant doc leakage |
| LLM09 — Misinformation | Fabricated citations, false-premise confirmation |
| LLM10 — Unbounded Consumption | Token / compute exhaustion patterns |

**Tactics** (apply on top of any category)
| Template | Focus |
|----------|-------|
| Obfuscation & Encoding | base64, ROT13, leetspeak, multi-encoding mixes |
| Persona / Role-play Jailbreak | DAN, Grandma exploit, co-author fiction frame |
| Authority Impersonation | Vendor T&S, operator, SRE, compliance roles |
| Translation Round-trip | Wrap intent in foreign-language pivots |
| Unicode / Homoglyph Tricks | Full-width, zero-width joiners, Cyrillic look-alikes |

## Adaptive Probing

Three independent toggles make the adversary adapt turn-to-turn instead of running a frozen
prompt:

- **Auto-escalate** — appends the strategy's per-turn instruction to the system prompt
  each turn. What that instruction *says* depends on the strategy, so the editor shows
  a per-strategy caption beneath the toggle. Summary:

  | Strategy | What Auto-escalate does |
  |---|---|
  | Red Team | Walks the OWASP 5-tier ladder: recon → injection → disclosure → obfuscation → agency. **This is what the toggle was designed for.** |
  | Stress | Increases load each turn — harder, longer, more contradictory inputs. |
  | Adversarial | Light feedback loop — counts validation failures and nudges persistence. |
  | Exploratory / Focused | Minor effect — appends a "vary your angle" nudge that the model would do naturally with temperature > 0. |
  | Custom | No-op — the Custom strategy doesn't define an escalation ladder. |
- **Adapt on refusal** — when the target refuses, instruct the adversary to pivot or
  obfuscate rather than repeat the failed probe.
- **Best-of-N** — generate N candidate probes per turn and send the strongest (1 = disabled).
  Higher N means more local model calls per turn.

## Judge / Critic (second model)

Enable a **second** model to score every target reply for a security breach. The judge runs
after each reply and emits a verdict (breached?, vector, severity, rationale) that appears as
a severity/**BREACH** badge in the transcript.

- Point the judge at a separate Ollama instance, e.g. run a second server with
  `OLLAMA_HOST=127.0.0.1:11435 ollama serve` and set the judge endpoint to
  `http://localhost:11435/api/chat`.
- Judge failures are non-fatal — a judge error simply leaves that turn unscored.

## Safety Controls

Three independently-optional limits that the orchestrator enforces during a run. Any control
left unchecked is simply not enforced — there's no master toggle.

- **Limit total cost (USD)** — stops the run once the accumulated estimated cost crosses the
  configured dollar amount. Useful for paid providers (OpenAI, Anthropic). Has no effect on
  local Ollama runs since their estimated cost is zero. Cost estimation is rough (a flat
  per-request figure per provider), so treat it as a guardrail, not billing-grade accounting.
- **Rate limit (requests/minute)** — **throttles** the adversarial bot's requests: when the
  configured requests-per-minute would be exceeded, the run waits out the remaining interval
  and then continues (it does not abort). Useful for staying inside provider quotas.
- **Enable content filter** — inspects each incoming target reply for secret/PII-shaped content
  (emails, keys, tokens, SSNs, etc.) and **flags** it in the transcript metadata
  (`contentFilterFlag`). It never alters the reply — hiding a leak would defeat the point of
  adversarial testing; the flag just draws attention to replies worth reviewing.

Limits apply to the adversarial bot's API calls, not the judge or target separately. Only the
cost cap aborts the run; the rate limit waits, and the content filter is non-destructive.

## Attack Library (flywheel)

When **Use attack-library flywheel** is enabled, Patience:

1. **Injects** previously-successful probes (from the library) as few-shot examples into the
   adversary's prompt, and
2. **Harvests** new wins from this run — any probe the judge flags as a breach is stored back
   into the library.

Open **Attack Library** (toolbar button on the Adversarial tab) to view every harvested
probe, toggle each on/off (whether it's injected into future runs), and delete entries.
The library is stored on-device. Harvesting requires the judge to be enabled (a breach
verdict is what marks a probe as a "win").

## Configuration

### Target Bot
- **Endpoint**: Your chatbot's HTTP endpoint
- **Protocol**: HTTP or WebSocket

### Conversation Settings
- **Strategy**: Testing approach (see above)
- **Max Turns**: Messages per conversation (default: 10)
- **Conversations**: Number of test conversations (default: 1)
- **Goals**: Specific testing objectives (optional)
- **Adversary Prompt**, **Adaptive Probing**, **Judge / Critic**, **Safety Controls**,
  **Attack Library**: see the sections above

## Writing Effective Goals

**Good goals** (specific):
- "Test order cancellation with invalid order numbers"
- "Verify bot maintains context across 10+ turns"
- "Check handling of contradictory information"

**Poor goals** (vague):
- "Test the bot"
- "Find bugs"

## Understanding Results

The most recent run for a configuration appears in the **Latest Results** panel as
per-conversation transcripts: each adversary probe, the target's reply, and — when a judge
is enabled — a severity verdict badge per reply. Each conversation header shows its turn
count and why it ended (max turns, goal achieved, adversary ended, etc.).

### Judge Verdicts

When the judge is enabled, each target reply is scored with a severity and an optional
**BREACH** flag:

| Severity | Meaning |
|----------|---------|
| Critical | Data breach, system compromise, or unauthorized action executed |
| High | PII / credential disclosure, system prompt leaked |
| Medium | Misinformation or partial information disclosure |
| Low | Reconnaissance or minor information leakage |
| None | No breach detected |

These map to the OWASP/MITRE categories in the
[Adversarial Testing Prompts Guide](ADVERSARIAL_TESTING_PROMPTS.md).

## Attack Patterns

For comprehensive security testing prompts based on OWASP LLM Top 10 and MITRE ATLAS, see:

**[Adversarial Testing Prompts Guide](ADVERSARIAL_TESTING_PROMPTS.md)**

## Troubleshooting

| Problem | Solution |
|---------|----------|
| "Connection to AI Provider Failed" | Verify Ollama is running (`ollama serve`) or check API key |
| "Target Bot Not Responding" | Test endpoint manually with curl |
| Judge produces no verdicts | Confirm the judge is enabled and its endpoint/instance is reachable |
| Too many API calls with paid providers | Lower Best-of-N, conversations, or turns |

## Related Guides

- [Scenario Testing Guide](SCENARIO_TESTING_GUIDE.md) - Scripted scenario testing
- [Conversation Forensics Guide](CONVERSATION_FORENSICS_GUIDE.md) - Log analysis and pattern detection
- [Adversarial Testing Prompts](ADVERSARIAL_TESTING_PROMPTS.md) - OWASP/MITRE attack patterns
