# Patience — TODO

Living list of next work. Update as items land or priorities shift. Order is rough priority.

## Done
- [x] **Full code + doc review and fixes.** Addressed the review findings in priority order:
  - **Credentials now Keychain-only (S1/S2/S3/S4).** `KeychainManager` rewritten with a generic
    string-account API + `kSecAttrAccessibleWhenUnlockedThisDeviceOnly`. Scenario target-bot
    credentials and the judge provider key are sanitized to the Keychain on save and
    re-hydrated at run time (previously plaintext in UserDefaults / exports). One-time
    `migrateInlineSecretsToKeychain()` moves legacy inline secrets out of UserDefaults on
    launch; imported configs are sanitized too. Fixed false "stored securely" UI/README/doc copy.
  - **Content filter is real & rate limit throttles (B1/B2).** `contentFilter` now flags (never
    alters) secret/PII-shaped target replies via the forensics `Redactor`; rate limit
    `Task.sleep`s instead of aborting the run. Docs corrected.
  - **Removed all `DEBUG` logging (S5)** across `TestExecutor` and the config-import path
    (the latter had printed credential-bearing JSON).
  - **Deleted dead `TestResultDetailView` + `ScenarioResultCard`** (~124 lines).
  - **Doc pass:** forensics JSON import example (valid `sender` values + `id`), HTTPS-not-enforced
    wording in `SECURITY.md`, `Redactor.defaultClosure` in the triage guide, unified Ollama
    default to `llama3.2`, 5-tier comments reconciled, authorized-use caveat added to the
    prompts guide, CHANGELOG filled in (adversarial features + Security section).
  - Fixed the `Redactor` sk-/sk-ant- rule-ordering shadow. Verified `xcodebuild` clean build +
    redactor logic. Retained write-only Codable schema fields (timeout/concurrency placeholders)
    and defensive enum cases by design.
- [x] **Safety Controls UI** — exposed `maxCostUSD` / `maxRequestsPerMinute` / `contentFilter`
  as per-field toggles in `AdversarialView`; wired into `buildConfiguration()`; doc restored
  in `docs/ADVERSARIAL_TESTING_GUIDE.md`.
- [x] **Scenario-test 405** — `TestExecutor` Ollama path switched from legacy `/api/generate`
  to `/api/chat`; endpoint resolution preserves any user-supplied `/api/...` path instead of
  smashing one on top; 405s now surface the URL, body, and an actionable hint; detection logic
  DRYed into `isOllamaBot` / `ollamaEndpointURL` helpers.
- [x] **Attack Library — tagging + import/export** — added optional `tags: [String]?` to
  `AttackLibraryEntry` (back-compat), seeded from the judge's vector at harvest time, with a
  chip-style editor in each row, a tag filter in the viewer header, and Import…/Export…
  panels backed by `AppState.exportAttackLibraryJSON()` / `importAttackLibraryJSON(_:)`.
  Promote-to-template intentionally deferred (see Later).
- [x] **Forensics redactor** — implemented the `redact: (Turn) -> Turn` scrubber referenced
  by `ForensicsRouter` and `EpisodeForensics`. Lives in `Core/Forensics/ForensicsTriage.swift`
  as `Redactor` / `Redactor.defaultClosure`. Covers email, phone, SSN, IPv4, OpenAI /
  Anthropic / AWS / Bearer / JWT / PEM secrets, and URL query strings. Verified 13/13 via a
  standalone `swift` script (PatienceTests/RedactorTests.swift covers the same cases for the
  future XCTest target).
- [x] **PatienceTests/ scaffolding** — wrote `RedactorTests.swift`, `AttackLibraryIOTests.swift`,
  `CodableBackCompatTests.swift`, and a README explaining the one-time Xcode-GUI step to add
  the test target. Files are on disk; user adds them to a new target via Xcode.
- [x] **Adversary Prompt shows strategy default** — editor is pre-filled with the selected
  strategy's built-in prompt (via new `AdversarialTestOrchestrator.defaultSystemPrompt(for:goals:)`
  helper). Strategy/goals changes auto-update the editor while it still matches the default;
  user edits are preserved across those changes. `buildConfiguration()` persists `nil` when
  the editor still equals the freshly-computed default, so the same strategy + goals reproduce
  identical behavior on any machine. Status pill ("Using X default" / "Modified") and "Reset
  to default" button replace the old "Clear". Doc updated.
- [x] **Expanded attack templates (6 → 16)** — added LLM03 (Supply Chain), LLM04 (Data &
  Model Poisoning), LLM05 (Improper Output Handling), LLM08 (Vector & Embedding Weaknesses),
  LLM09 (Misinformation), LLM10 (Unbounded Consumption) for full OWASP LLM Top 10 coverage,
  plus four cross-cutting tactical templates: Persona/Role-play Jailbreak, Authority
  Impersonation, Translation Round-trip, Unicode/Homoglyph Tricks. Templates now grouped
  into three submenus (Full Arsenals / OWASP LLM Top 10 / Tactics) via a new
  `AdversarialPromptTemplate.Category` enum. Doc updated with the full table.
- [x] **Per-strategy Auto-escalate caption** — Adaptive Probing GroupBox now shows a live
  one-line note under the Auto-escalate toggle explaining what the toggle actually does for
  the currently-selected strategy (Red Team: tier ladder; Stress: load escalation;
  Exploratory/Focused: minor diversity nudge; Custom: no-op; etc.). Backed by a new
  `ConversationStrategy.autoEscalateCaption` extension, alongside `humanDescription` which
  consolidates the previous duplicated copy. Doc updated with a strategy-by-strategy table.
- [x] **Full Red Team template ↔ doc parity** — the in-app `fullRedTeamPrompt` had drifted
  to roughly half the content of the doc's "Comprehensive Testing Prompt" (5 OWASP categories
  vs 7, 2 MITRE tactics vs 5, obfuscation as one inline paragraph vs 9 broken-out techniques,
  no severity rubric). Rewrote it to mirror the doc verbatim, with two intentional deltas:
  prepended `operatingRules` for consistency with the focused templates, and dropped the
  doc's "Output Format" section (the orchestrator captures everything; AI-authored reports
  would just pollute the transcript). Added a note at the top of
  `docs/ADVERSARIAL_TESTING_PROMPTS.md` pinning the two-way sync contract.

## In progress
- [ ] **Live smoke test** — end-to-end run against a real Ollama target + second judge instance
  (`OLLAMA_HOST=127.0.0.1:11435 ollama serve`). Adaptive probing, judge, flywheel harvest,
  Safety Controls, attack-library import/export, and the new `/api/chat` scenario path are
  logic-verified but never run live. Work through the **Manual GUI Test Plan** below.

## Manual GUI Test Plan

Work through top-to-bottom. Stop at the first ❌ — earlier failures usually cascade. This
checklist covers everything changed in the recent sessions: Safety Controls, the `/api/chat`
scenario fix, Attack Library tagging + import/export, plus a regression sweep over the prior
session's Adversarial UI work.

### Prep (5 min)
- [ ] Start primary Ollama: `ollama serve` (default port 11434)
- [ ] In a second terminal, start the judge Ollama: `OLLAMA_HOST=127.0.0.1:11435 ollama serve`
- [ ] Pull a model on each: `ollama pull llama3.2` (and the same with `OLLAMA_HOST=127.0.0.1:11435`)
- [ ] Launch Patience from Xcode (⌘R)

### 1. Scenario Testing — `/api/chat` switch (Task #3)
- [ ] Scenario Testing tab → New Config
- [ ] Bot endpoint = `http://localhost:11434`, Protocol = HTTP, Provider = **Ollama**, Model = `llama3.2`
- [ ] Add a trivial step (e.g. message: "Say hello in one word") → Save → Run
- [ ] **Pass criteria**: response comes back (no 405). Xcode console shows
  `DEBUG: Using Ollama /api/chat request format with model: llama3.2`
- [ ] **Negative test for 405 message**: edit the config, change endpoint to
  `http://localhost:11434/api/tags` (a GET-only path). Re-run.
- [ ] **Pass criteria**: error message contains
  `"HTTP error: 405 — the endpoint rejected POST… URL: …"` instead of a bare status code
- [ ] **Already-pathed endpoint**: set endpoint to `http://localhost:11434/api/chat`. Re-run →
  still works; no double-`/api/chat` segment in the URL (check console)

### 2. Adversarial — Safety Controls (Task #1)
- [ ] Adversarial tab → New Config
- [ ] Scroll until you see **"Safety Controls"** GroupBox (between "Judge / Critic" and "Goals")
- [ ] **Pass criteria**: three toggles visible — Limit total cost (USD), Rate limit (req/min),
  Enable content filter
- [ ] Toggle "Limit total cost" → USD field appears with default `5.00`. Toggle off → field hides
- [ ] Toggle "Rate limit" → Stepper appears with default `60`. Confirm bounds (1–600)
- [ ] Toggle "Enable content filter"
- [ ] Set all three on, hit Save. Reopen the config in edit mode.
- [ ] **Pass criteria**: all three toggle states + values restored exactly (proves `init`
  hydration from `SafetySettings` works)
- [ ] Edit again, turn all three off, Save, reopen → all toggles off (proves `nil` round-trip)
- [ ] **Functional check** (optional): set rate limit to 6 req/min, run multi-conversation test,
  observe pacing in console

### 3. Adversarial — Attack Library QoL (Task #5)

#### Pre-populate the library
- [ ] Create adversarial config: provider Ollama, model `llama3.2`, endpoint
  `http://localhost:11434`, target = your favorite test bot
- [ ] Enable **Judge / Critic**; judge endpoint `http://localhost:11435/api/chat`, model `llama3.2`
- [ ] Enable **Use attack-library flywheel** under Adaptive Probing
- [ ] Run for a few turns. Need at least 1 breach for the rest of this section. Try the
  "Red Team" strategy if no breaches.

#### Tagging
- [ ] Click toolbar **Attack Library (N)** button
- [ ] **Pass criteria**: each harvested entry shows a chip with the vector
  (e.g. `LLM01_prompt_injection`) auto-seeded
- [ ] Click pencil icon on a row → text field appears prefilled with comma-separated tags
- [ ] Edit to `OWASP-LLM01, prompt-injection, demo` → click Save (or hit Return)
- [ ] **Pass criteria**: chips re-render with three new tags
- [ ] Edit again, enter `  ,  ,  alpha , alpha , ` → Save
- [ ] **Pass criteria**: only one chip "alpha" appears (trim + dedup + drop-empties)
- [ ] Edit, clear all text, Save → chips disappear; pencil tooltip becomes "Add tags"

#### Filter
- [ ] Tag filter dropdown appears above list when any tag exists
- [ ] Pick a tag → list filters; counter at right shows "X of Y"
- [ ] Pick "All" → all entries back

#### Import / Export
- [ ] Click **Export…** → save as `~/Desktop/attack-library.json`
- [ ] Open file in text editor → **Pass criteria**: pretty-printed, sortedKeys, ISO8601 dates
- [ ] Delete one entry from the viewer
- [ ] Click **Import…** → select same JSON file
- [ ] **Pass criteria**: toast says "Imported 1 new entry. Duplicates skipped." and the deleted
  entry is back
- [ ] Click Import again → "Imported 0 new entries" (idempotent)
- [ ] **Negative test**: try importing malformed JSON (e.g. `~/.bashrc`) → orange inline banner
  with "Import failed: …", banner is dismissible
- [ ] Empty the library entirely → **Pass criteria**: Export button disables; empty-state helper
  mentions Import

### 4. Adversarial — Pre-session UI smoke (regression sweep)
- [ ] **Adversary Prompt** GroupBox visible; editor is **pre-filled** with the selected
  strategy's prompt (not empty); status pill reads "Using \<strategy\> strategy default";
  switching strategy auto-updates the editor; making an edit flips pill to "Modified" and
  reveals "Reset to default"; clicking Reset restores the default
- [ ] **Load template** menu opens into three submenus (Full Arsenals / OWASP LLM Top 10 /
  Tactics); OWASP submenu lists all of LLM01–LLM10; Tactics submenu lists 5 entries;
  picking any template replaces the editor text and flips the pill to "Modified"
- [ ] **Full Red Team template completeness** — pick strategy "Red Team" (editor pre-fills
  with `fullRedTeamPrompt`) OR Load template → Full Arsenals → Full Red Team. Scroll the
  editor and confirm presence of: all 7 OWASP categories (LLM01, 02, 05, 06, 07, 09, 10),
  all 5 MITRE ATLAS tactics (Reconnaissance, Resource Development, Initial Access,
  Exfiltration, Impact), 9 broken-out Obfuscation Techniques, Testing Methodology,
  Severity Guidance. Should look ~5× longer than the previous version.
- [ ] **Adaptive Probing**: two toggles + Best-of-N stepper + flywheel toggle all interactive
- [ ] **Auto-escalate per-strategy caption** — the blue info line under the Auto-escalate
  toggle changes as you switch strategy in the picker. Spot-check: "Red Team" mentions the
  5-tier ladder; "Custom" reads "No-op for Custom"; "Exploratory" reads "minor effect"
- [ ] **Judge / Critic**: enabling shows provider/model/endpoint fields; default endpoint
  is `http://localhost:11435/api/chat`
- [ ] Run any adversarial test → **AdversarialResultsView** shows the transcript with
  severity/BREACH badges on judged turns
- [ ] Strategy picker includes "Red Team" option

### 5. Persistence sanity
- [ ] Quit Patience (⌘Q)
- [ ] Relaunch
- [ ] **Pass criteria**: scenario configs, adversarial configs (with Safety Controls + Judge +
  Adaptive + Tags all preserved), and attack library all survived

### Not covered by GUI (verify separately)
- **Redactor** — no GUI yet (forensics triage isn't wired into the UI). Functional verification
  was the 13/13 standalone `swift` script run during build.
- **PatienceTests/*.swift** — won't run until the XCTest target exists in Xcode
  (see [PatienceTests/README.md](PatienceTests/README.md)).

### If anything fails
- 405 still happening on scenario test → check `Xcode → View → Debug Area → Activate Console`
  for the `DEBUG: Constructed endpointURL` line; share that.
- Judge verdicts never appear → confirm second Ollama instance is serving
  (`curl http://localhost:11435/api/tags`).
- Tags don't render → confirm persisted entry has a `tags` array in the sandbox prefs plist
  under `~/Library/Containers/<bundle-id>/Data/Library/Preferences/`.

### Code that changed this session (for reference while testing)
- [TestExecutor.swift](Patience/Core/TestExecutor.swift) — Ollama `/api/chat` switch, endpoint
  normalization, 405 error message with URL + body
- [AdversarialView.swift](Patience/Views/AdversarialView.swift) — Safety Controls GroupBox,
  Attack Library tag chips, tag filter, import/export panels
- [AppState.swift](Patience/Models/AppState.swift) — tag mutation, JSON import/export, harvest
  tag seeding from judge vector
- [Types.swift](Patience/Models/Types.swift) — `AttackLibraryEntry.tags`
- [ForensicsTriage.swift](Patience/Core/Forensics/ForensicsTriage.swift) — `Redactor` +
  `Redactor.defaultClosure`
- [PatienceTests/](PatienceTests/) — three test files + README (not yet wired into Xcode;
  see Later → "XCTest target wiring")
- [docs/ADVERSARIAL_TESTING_GUIDE.md](docs/ADVERSARIAL_TESTING_GUIDE.md) — restored
  Safety Controls section

## Later
- [ ] **XCTest target wiring** — add the bundle via Xcode GUI per `PatienceTests/README.md`.
  Cannot be done by hand-editing `project.pbxproj` reliably; CLAUDE.md only documents 4-entry
  file additions, not target additions.
- [ ] **Promote attack-library entry to template** — `AdversarialPromptTemplate` is currently
  a hardcoded `enum` in `AdversarialTestOrchestrator.swift`. Letting users promote a library
  entry to a first-class template requires turning the enum into a struct-based registry (or
  a protocol). Architectural, not a quick add.
- [ ] **Drop `private` on `TestExecutor.isOllamaBot` / `ollamaEndpointURL`** — minor, so
  `OllamaEndpointTests.swift` can pin URL normalization once the XCTest target exists.
- [ ] **Forensics triage finish-out** — 11 remaining numbered items in
  `docs/forensics/IMPLEMENTATION_PLAN.md` (Stage 0 validators, local judge, frontier judge,
  episode aggregation, flywheel store, holdout UI, schema-conformance tests, full UI
  integration). Weeks of work — not session-scope. The redactor (3.4) is the only piece
  landed so far.
