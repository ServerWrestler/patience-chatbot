# AI Assistant Development Guide

This guide helps developers using ChatGPT, Claude, or other AI assistants to work effectively on the Patience project.

## 📋 Quick Context for AI Assistants

Copy and paste this section when starting a new conversation with an AI assistant:

---

**Project**: Patience - macOS Chatbot Testing Framework
**Language**: Swift 5.9+
**Framework**: SwiftUI
**Platform**: macOS 12.0+

**Purpose**: Native macOS application for testing chatbot resilience and performance with three modes:
1. Live Testing - Real-time scenario-based testing
2. Log Analysis - Historical conversation analysis
3. Adversarial Testing - AI-powered automated testing

**Architecture**:
- MVVM pattern with SwiftUI
- AppState (@MainActor, ObservableObject) for state management
- Async/await for concurrency
- Codable + Sendable for all data types
- UserDefaults for persistence, Keychain for API keys

**Key Components**:
- `Models/` - Data structures (must be Codable, Sendable)
- `Core/` - Business logic (TestExecutor, AnalysisEngine, AdversarialTestOrchestrator)
- `Views/` - SwiftUI views (suffix with "View")

**Naming Conventions**:
- Files: PascalCase (e.g., `TestExecutor.swift`)
- Views: Suffix with "View" (e.g., `TestingView`)
- Models: Descriptive nouns (e.g., `TestConfig`)

**Important Rules**:
- All async functions must handle errors with try/catch
- Show user-facing errors via `appState.showErrorMessage()`
- Mark UI code with @MainActor
- Use @Published for state that triggers UI updates
- Never store API keys in configs (use Keychain)

---

## 🎯 Common Development Tasks

### Adding a New Feature

**Context to provide**:
```
I'm adding [feature name] to Patience. 

Current implementation: [describe current state]
Desired behavior: [describe what you want]

Relevant files:
- [list files that might be affected]

Please help me implement this following the project's patterns.
```

### Fixing a Bug

**Context to provide**:
```
I'm fixing a bug in Patience where [describe bug].

Error message: [paste error]
Affected file: [file path]
Current code: [paste relevant code]

Please help me fix this while maintaining the project's architecture.
```

### Adding a New View

**Context to provide**:
```
I'm creating a new view called [ViewName] in Patience.

Purpose: [what the view does]
Data needed: [what data it displays/modifies]
Parent view: [where it's used]

Please create a SwiftUI view following the project's patterns:
- Use @EnvironmentObject for AppState
- Follow MVVM pattern
- Include proper error handling
```

### Adding a New Model

**Context to provide**:
```
I'm adding a new data model to Patience.

Model name: [name]
Purpose: [what it represents]
Fields: [list fields and types]

Please create a model that is:
- Codable (for persistence)
- Sendable (for concurrency)
- Identifiable (if used in lists)
- Follows project naming conventions
```

## 📚 Reference Documentation

### Key Files to Reference

When asking for help, mention these files if relevant:

**Core Logic**:
- `Patience/Core/TestExecutor.swift` - Live test execution
- `Patience/Core/AnalysisEngine.swift` - Log analysis
- `Patience/Core/AdversarialTestOrchestrator.swift` - AI testing
- `Patience/Core/ReportGenerator.swift` - Report generation
- `Patience/Core/CustomValidators.swift` - Validation rules

**Models**:
- `Patience/Models/AppState.swift` - Application state
- `Patience/Models/Types.swift` - All data structures

**Views**:
- `Patience/Views/TestingView.swift` - Live testing UI
- `Patience/Views/AnalysisView.swift` - Log analysis UI
- `Patience/Views/AdversarialView.swift` - Adversarial testing UI
- `Patience/Views/ReportsView.swift` - Reports UI

### Documentation Files

Share these with AI assistants for context:
- `README.md` - Project overview and features
- `DOCUMENTATION.md` - Comprehensive feature documentation
- `CHANGELOG.md` - Version history
- `IMPLEMENTATION_STATUS.md` - Current implementation status

## 🔧 Development Patterns

### Pattern 1: Adding a New Test Type

```swift
// 1. Add enum case to Types.swift
enum TestType: String, Codable, CaseIterable, Sendable {
    case existing = "existing"
    case newType = "newType"  // Add this
}

// 2. Add configuration to Types.swift
struct NewTestConfig: Codable, Identifiable, Sendable {
    var id: UUID = UUID()
    // Add fields
}

// 3. Add to AppState.swift
@Published var newTestConfigs: [NewTestConfig] = []

// 4. Add CRUD methods to AppState.swift
func addNewTestConfig(_ config: NewTestConfig) { }
func updateNewTestConfig(_ config: NewTestConfig) { }
func deleteNewTestConfig(_ config: NewTestConfig) { }

// 5. Create executor in Core/
class NewTestExecutor {
    func execute(config: NewTestConfig) async throws -> Results { }
}

// 6. Create view in Views/
struct NewTestView: View {
    @EnvironmentObject var appState: AppState
    var body: some View { }
}
```

### Pattern 2: Adding Validation

```swift
// 1. Add to CustomValidators.swift
static func validateNewRule(_ response: BotResponse) -> ValidationResult {
    // Implementation
    return ValidationResult(
        passed: passed,
        expected: "Expected behavior",
        actual: response.content,
        message: "Validation message",
        details: ["key": "value"]
    )
}

// 2. Add case to validate() switch
case "new_rule":
    return validateNewRule(response)
```

### Pattern 3: Adding AI Provider

```swift
// 1. Add to BotProvider enum in Types.swift
enum BotProvider: String, Codable, CaseIterable, Sendable {
    case newProvider = "newProvider"
}

// 2. Create connector in AdversarialTestOrchestrator.swift
class NewProviderConnector: AdversarialBotConnector {
    func initialize(config: AdversarialBotSettings) async throws { }
    func generateMessage(...) async throws -> String { }
    func shouldEndConversation(...) async throws -> Bool { }
    func disconnect() async { }
    func getName() -> String { return "New Provider" }
}

// 3. Add to createConnector() switch
case .newProvider:
    return NewProviderConnector()
```

## 🐛 Common Issues and Solutions

### Issue: "Type does not conform to Sendable"
**Solution**: Add `Sendable` to the type declaration
```swift
struct MyType: Codable, Sendable { }
```

### Issue: "Publishing changes from background threads"
**Solution**: Mark function with `@MainActor` or wrap in `MainActor.run`
```swift
@MainActor
func updateUI() { }

// Or
Task { @MainActor in
    self.property = value
}
```

### Issue: "Cannot find type in scope"
**Solution**: Import the module or check file is in Xcode project
```swift
import Foundation
import NaturalLanguage
```

### Issue: Configuration not persisting
**Solution**: Ensure type is Codable and saveConfigs() is called
```swift
struct Config: Codable { }

func addConfig(_ config: Config) {
    configs.append(config)
    saveConfigs()  // Don't forget this!
}
```

### Issue: "Cannot find [ClassName] in scope"
**Solution**: Ensure the file is added to the Xcode project
1. Check the file exists in the filesystem
2. Verify it's listed in `Patience.xcodeproj/project.pbxproj`
3. Confirm it's in the Sources build phase
4. Clean build folder (`⌘+Shift+K`) and rebuild

### Issue: Duplicate property/extension errors
**Solution**: Check for conflicting property declarations
- Stored properties and computed properties can't have the same name
- Extensions can't redeclare existing properties
- Remove duplicate or conflicting declarations

## 📝 Code Review Checklist

When asking AI to review code, request checks for:

- [ ] All types are Codable and Sendable
- [ ] UI updates are on @MainActor
- [ ] Errors are caught and shown to user
- [ ] API keys never stored in configs
- [ ] Async functions use proper error handling
- [ ] State changes call saveConfigs()
- [ ] Views use @EnvironmentObject for AppState
- [ ] Naming follows conventions
- [ ] No force unwraps (use guard/if let)
- [ ] Proper memory management (no retain cycles)

## 🚀 Testing Prompts

### For ChatGPT/Claude

**Unit Test Generation**:
```
Generate unit tests for [function name] in Patience.

Function:
[paste function code]

Test cases needed:
- Happy path
- Error cases
- Edge cases
- Async behavior

Use XCTest framework and follow Swift testing best practices.
```

**Code Review**:
```
Review this code from Patience for:
- Swift best practices
- SwiftUI patterns
- Concurrency safety
- Error handling
- Memory leaks

Code:
[paste code]
```

**Refactoring**:
```
Refactor this code from Patience to:
- Improve readability
- Follow MVVM pattern
- Use async/await properly
- Add error handling

Current code:
[paste code]
```

## 🔗 Useful Resources

- [Swift Documentation](https://swift.org/documentation/)
- [SwiftUI Tutorials](https://developer.apple.com/tutorials/swiftui)
- [Swift Concurrency](https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html)
- [Keychain Services](https://developer.apple.com/documentation/security/keychain_services)

## 💡 Tips for AI-Assisted Development

1. **Be Specific**: Provide exact file paths and function names
2. **Share Context**: Include relevant code snippets
3. **Mention Patterns**: Reference the project's architecture
4. **Request Tests**: Ask for test cases with implementations
5. **Iterate**: Start simple, then add complexity
6. **Verify**: Always test AI-generated code in Xcode

## 📞 Getting Help

If AI assistants can't help:
1. Check `DOCUMENTATION.md` for feature details
2. Look at similar implementations in the codebase
3. Open an issue on GitHub with specific questions

---

**Last Updated**: December 13, 2025
**For**: Patience v1.0.1
**Compatible With**: ChatGPT, Claude, GitHub Copilot, and other AI assistants
