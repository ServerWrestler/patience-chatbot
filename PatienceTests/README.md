# PatienceTests

Unit tests for the Patience harness. These files are intentionally **not**
registered in `Patience.xcodeproj` — the scheme has no test action yet, and
adding one requires creating an XCTest target through the Xcode GUI rather
than hand-editing the project file.

## One-time setup (per machine)

1. In Xcode: **File → New → Target… → macOS → Unit Testing Bundle**.
2. Name it `PatienceTests`. Target to test: `Patience`.
3. In the Project Navigator, right-click the new `PatienceTests` group →
   **Add Files to "Patience"…** and select the `.swift` files in this
   directory. Make sure **Target Membership** is `PatienceTests` only
   (not the app target).
4. The new scheme now has a Test action. Run with **⌘U** or
   `xcodebuild test -project Patience.xcodeproj -scheme Patience`.

## What's covered

- `RedactorTests.swift` — every default PII/secret pattern + determinism +
  a couple of "clean text must round-trip" negative checks. Guards the
  forensics privacy gate.
- `AttackLibraryIOTests.swift` — JSON export/import round-trip, dedup on
  re-import, and tag normalization rules (trim, dedup, drop empties).
- `CodableBackCompatTests.swift` — pins that the recent optional fields
  (adaptive, judge, safety, library tags) stay optional on the wire, so
  configs from older builds keep decoding.

## What's *not* covered (yet)

These need `internal`-visibility tweaks before they can be tested in-process:

- `TestExecutor.isOllamaBot(_:)` and `ollamaEndpointURL(for:)` — currently
  `private`. Worth dropping to `internal` so the `/api/chat` normalization
  doesn't regress silently.
- `AdversarialTestOrchestrator.parseJudgeVerdict(_:)` and
  `composeTurnPrompt(...)` — same story.

When that refactor happens, add an `OllamaEndpointTests.swift` and a
`JudgeParserTests.swift` here.
