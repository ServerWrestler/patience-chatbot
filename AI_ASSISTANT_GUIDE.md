# AI Assistant Development Guide

Quick reference for AI assistants (ChatGPT, Claude, etc.) working on Patience.

## Project Context

```
Project: Patience - macOS Chatbot Testing Framework
Language: Swift 5.9+ / SwiftUI
Platform: macOS 13.0+
Pattern: MVVM with async/await
```

## Key Files

| Category | Files |
|----------|-------|
| **State** | `Models/AppState.swift`, `Models/Types.swift` |
| **Core Logic** | `Core/TestExecutor.swift`, `Core/AdversarialTestOrchestrator.swift`, `Core/AnalysisEngine.swift` |
| **Views** | `Views/TestingView.swift`, `Views/AdversarialView.swift`, `Views/AnalysisView.swift` |

## Critical Rules

1. All types: `Codable` + `Sendable`
2. UI code: `@MainActor`
3. State changes: Call `saveConfigs()` after
4. API keys: Keychain only, never in configs
5. Errors: Show via `appState.showErrorMessage()`
6. Comments: Required on all code (see below)

## Code Patterns

### Adding a Model
```swift
struct NewConfig: Codable, Identifiable, Sendable {
    var id: UUID = UUID()
    // fields...
}
```

### Adding to AppState
```swift
@Published var newConfigs: [NewConfig] = []

func addNewConfig(_ config: NewConfig) {
    newConfigs.append(config)
    saveConfigs()
}
```

### Async Operations
```swift
@MainActor
func runOperation() async {
    isRunning = true
    do {
        let result = try await executor.execute()
        results.append(result)
    } catch {
        showErrorMessage(error.localizedDescription)
    }
    isRunning = false
}
```

### SwiftUI View
```swift
struct NewView: View {
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        // UI...
    }
}
```

## Code Documentation Standards

All code requires clear comments:

```swift
/// Manages application state
/// @MainActor ensures UI updates on main thread
@MainActor
class AppState: ObservableObject {
    /// Test configurations, persisted to UserDefaults
    @Published var testConfigs: [TestConfig] = []
    
    /// Saves all configs to persistent storage
    /// Called after any config modification
    func saveConfigs() {
        // implementation
    }
}
```

**Comment requirements:**
- File purpose at top
- Doc comments on types and public functions
- Explain `@State`, `@Published`, `@EnvironmentObject` usage
- Note side effects and error conditions

## Common Issues

| Issue | Solution |
|-------|----------|
| "Type does not conform to Sendable" | Add `Sendable` to type |
| "Publishing changes from background" | Add `@MainActor` or use `MainActor.run` |
| Config not persisting | Call `saveConfigs()` after changes |

## Related Docs

- [README.md](README.md) - Features and setup
- [CONTRIBUTING.md](CONTRIBUTING.md) - Contribution guidelines
- [DOCUMENTATION.md](DOCUMENTATION.md) - Doc index
