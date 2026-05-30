# CLAUDE.md

Guidance for Claude Code (and other AI assistants) working in the Patience repository.
This file is the source of truth for project conventions — keep it current as rules change.

## Project

Patience — a native **macOS** application (Swift / SwiftUI, MVVM) for chatbot testing and
validation. Three testing modes plus reporting:

- **Scenario Testing** — scripted multi-turn conversation flows (✅ implemented)
- **Conversation Forensics** — import production logs; basic metrics/pattern/context analysis
  (✅), plus a guardrail-failure **triage cascade** (⚠️ reference implementation)
- **Adversarial Testing** — AI autonomously probes the target; maps findings to OWASP LLM
  Top 10 and MITRE ATLAS (✅ implemented)
- **Reporting** — HTML / JSON / Markdown export (✅)

Open-core, MIT. The *harness* is open; the fine-tuned forensics judge, its training data, and
customer transcripts are a **private asset** — see `docs/FORENSICS_CONTRIBUTION_BOUNDARY.md`.

## Tech stack

- Swift 5.9+ language features / SwiftUI, async/await concurrency, Combine
- macOS 13.0+ deployment target; Xcode 15+ (project format objectVersion 70)
- No external dependencies — Foundation, Network, Security (Keychain), CryptoKit, NaturalLanguage
- App sandbox enabled; outgoing network + user-selected files entitlements

## Build & test (MANDATORY after any code change)

After **any** change to `.swift` files, files added/removed, or project-structure changes,
you MUST build and confirm success before considering the task complete:

```bash
xcodebuild -project Patience.xcodeproj -scheme Patience build
# tests:
xcodebuild test -project Patience.xcodeproj -scheme Patience
```

If the build fails: read the error, fix the immediate compile error first, rebuild, and don't
make further changes until it's green. Exception: doc/asset/config-only changes don't require a
build.

## Documentation changes require approval (MANDATORY)

Before modifying **any** documentation file, STOP and ask the user for explicit permission,
naming exactly what you'll change and why. Covered: `README.md`, `CHANGELOG.md`,
`CONTRIBUTING.md`, `DOCUMENTATION.md`, `SECURITY.md`, this `CLAUDE.md`, and any `.md` in
`docs/`. Exceptions: source-code comments and non-documentation config.

Do **not** add "Last Updated" dates to docs — git tracks that.

## Project structure

```
Patience/                       # Swift source
├── Models/      AppState.swift, Types.swift        # data models (Codable + Sendable)
├── Core/        TestExecutor, AdversarialTestOrchestrator, AnalysisEngine,
│   │            ReportGenerator, KeychainManager, CustomValidators
│   └── Forensics/  ForensicsTriage, EpisodeForensics, FlywheelStore  # triage cascade
├── Views/       SwiftUI views, one per feature (suffix "View")
├── ContentView.swift, PatienceApp.swift
└── Patience.entitlements
docs/            Feature guides (+ docs/forensics/ schema, rubric, implementation plan)
```

The Xcode project uses **explicit file references** (not file-system-synchronized groups,
except `docs/`). New Swift files must be registered in `Patience.xcodeproj/project.pbxproj`
(PBXFileReference + PBXBuildFile + group membership + Sources build phase) or they won't compile.
Likewise, deleting a file means removing its four pbxproj entries.

Naming: PascalCase for Swift files and module dirs; views end in `View`; models are nouns.

## Code conventions

1. All data types are `Codable` **and** `Sendable`.
2. UI code is `@MainActor`; never publish state changes from a background thread.
3. After any change to persisted state, call `saveConfigs()`.
4. API keys live in the **Keychain only** (`KeychainManager`) — never in configs or source.
5. Surface errors via `appState.showErrorMessage(...)`.
6. **Comment everything** (see below).

### Comments (MANDATORY)

Every file opens with a purpose comment. Every type/protocol and every public function gets a
`///` doc comment (params, return, throws, side effects). Explain property wrappers
(`@State`/`@Published`/`@EnvironmentObject`) and non-obvious logic. Use `// MARK: -` to group.
Explain **what and why**, not **how**; don't comment trivial/obvious code.

Common patterns:

```swift
// New Codable+Sendable model
struct NewConfig: Codable, Identifiable, Sendable { var id: UUID = UUID() /* fields… */ }

// AppState mutation persists immediately
@Published var newConfigs: [NewConfig] = []
func addNewConfig(_ c: NewConfig) { newConfigs.append(c); saveConfigs() }

// Async work on the main actor with error surfacing
@MainActor func runOperation() async {
    isRunning = true
    do { results.append(try await executor.execute()) }
    catch { showErrorMessage(error.localizedDescription) }
    isRunning = false
}
```

## Security

Never commit secrets, real transcripts, or PII (including in test fixtures — use synthetic
data). Before any push, scan staged files for API keys (`sk-`, `api_`, `token`, `key=`), AWS
creds (`AKIA`), private keys (`BEGIN PRIVATE`, `ssh-`), PII, and internal IPs (`192.168.`,
`10.`, `172.`); verify `.gitignore` covers sensitive file types. See `SECURITY.md`.

## Forensics specifics

- Verdict contract: `docs/forensics/forensics-schema.json`; judge rubric:
  `docs/forensics/judge-rubric.md`. Both keyed by `rubricVersion` (`1.0.0-owasp2025`).
- The local judge, frontier judge, and fine-tune targets must share the same `rubricVersion`.
- **Always `redact` before any frontier (cloud) call or JSONL export** — no transcript PII
  leaves the device or reaches a training set.
- Keep fine-tuned weights, calibration data, customer transcripts, and client-specific
  detector tuning **out of this repo**. Schema changes bump `rubricVersion`.
- Open TODO / implementation plan: `docs/forensics/IMPLEMENTATION_PLAN.md`.

## Related docs

`DOCUMENTATION.md` (doc index) · `CONTRIBUTING.md` · `docs/` feature guides.
