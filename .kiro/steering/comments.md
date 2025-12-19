# Code Documentation Standards

## Purpose

All code in the Patience project must include comprehensive comments to help new Swift programmers understand the codebase. Comments should explain **what** the code does and **why**, not just **how**.

## Requirements

### 1. File-Level Documentation

Every Swift file must start with comments explaining:
- The file's purpose
- Main types/classes/structs defined
- How it fits into the overall architecture
- Any important dependencies

```swift
// Import statements...

/// This file defines all data structures used throughout the application
/// Includes configuration types, test scenarios, results, and analysis data
/// All types are Codable (for persistence) and Sendable (for concurrency safety)
```

### 2. Type Documentation

Every struct, class, enum, and protocol must have a doc comment:
- What it represents
- Its role in the application
- Protocol conformances and why
- Usage examples if complex

```swift
/// Configuration for a single test run
/// Contains target bot settings, test scenarios, validation rules, and timing
/// Codable: Can be saved/loaded from disk
/// Identifiable: Can be used in SwiftUI lists
/// Sendable: Safe to pass between async contexts
struct TestConfig: Codable, Identifiable, Sendable {
    // Properties...
}
```

### 3. Property Documentation

Document properties when:
- Purpose isn't obvious from the name
- It has special behavior (computed, observed)
- It uses property wrappers (@State, @Published, etc.)
- Default values have significance

```swift
/// Unique identifier for this configuration
/// Auto-generated when config is created
/// Used by SwiftUI to track items in lists
var id: UUID = UUID()

/// Array of test configurations created by the user
/// @Published triggers UI updates when this array changes
/// Automatically persisted via saveConfigs() after modifications
@Published var testConfigs: [TestConfig] = []
```

### 4. Function Documentation

Every function must have comments explaining:
- What it does (high-level purpose)
- Parameters and their meaning
- Return value and what it represents
- Errors it can throw
- Side effects (state changes, network calls, etc.)
- When it should be called

```swift
/// Executes a test scenario against the target bot
/// Sends each message in the scenario, validates responses, and collects results
/// 
/// - Parameter scenario: The test scenario to execute
/// - Parameter config: Configuration containing bot endpoint and validation rules
/// - Returns: ScenarioResult containing conversation history and validation results
/// - Throws: TestError if connection fails or timeout occurs
/// 
/// Side effects:
/// - Makes network requests to target bot
/// - Updates UI progress via callback
/// - May take several seconds to complete
private func executeScenario(_ scenario: Scenario, config: TestConfig) async throws -> ScenarioResult {
    // Implementation...
}
```

### 5. Complex Logic Documentation

Add inline comments for:
- Non-obvious algorithms
- Workarounds for bugs or limitations
- Performance optimizations
- Business logic decisions

```swift
// Calculate semantic similarity using NaturalLanguage framework
// Falls back to simple word overlap if embeddings unavailable
let similarity = calculateSemanticSimilarity(text1, text2)

// Must check on main thread because this accesses UI state
await MainActor.run {
    self.isRunning = false
}
```

### 6. Property Wrapper Documentation

Always explain property wrappers:

```swift
/// @State means this view owns and manages this value
/// Changes trigger view re-renders
/// Private because only this view needs it
@State private var selectedTab: TabSelection = .testing

/// @EnvironmentObject means this is injected from parent
/// Shared across multiple views
/// Must be provided by parent or app will crash
@EnvironmentObject var appState: AppState

/// @Published triggers UI updates when value changes
/// Part of ObservableObject protocol
/// Observed by views using @ObservedObject or @EnvironmentObject
@Published var testResults: [TestResults] = []
```

## Comment Style Guidelines

### Use Doc Comments (///) for Public API

```swift
/// This is a doc comment
/// Used for types, functions, properties that are part of the API
/// Shows up in Xcode's Quick Help
func publicFunction() { }
```

### Use Regular Comments (//) for Implementation Details

```swift
// This is a regular comment
// Used for explaining implementation details
// Doesn't show in Quick Help
let result = complexCalculation() // Inline comment
```

### Use MARK for Organization

```swift
// MARK: - Configuration Types
// Groups related code sections
// Shows up in Xcode's jump bar

// MARK: Public Methods
// Can be used without the dash for subsections
```

## What NOT to Comment

Don't add comments that just repeat the code:

```swift
// BAD: Comment just repeats what code says
// Set name to "Test"
name = "Test"

// GOOD: Comment explains why
// Use default name if user hasn't provided one
name = "Test"
```

Don't comment obvious code:

```swift
// BAD: Obvious from code
// Increment counter
counter += 1

// GOOD: Explains purpose
// Track number of failed validations for reporting
failureCount += 1
```

## When to Add Comments

### Always Comment:
- File purpose
- Type definitions
- Public functions
- Complex algorithms
- Property wrappers
- Non-obvious code
- Workarounds
- Business logic

### Consider Commenting:
- Private functions (if complex)
- Simple properties (if behavior is special)
- Obvious code (if context helps)

### Don't Comment:
- Trivial getters/setters
- Self-explanatory code
- Temporary debug code (remove instead)

## Examples from Patience

### Good Example - PatienceApp.swift

```swift
/// Main entry point for the Patience application
/// The @main attribute tells Swift this is where the app starts
@main
struct PatienceApp: App {
    /// Creates and manages the application's global state
    /// @StateObject ensures this persists for the lifetime of the app
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        // Main application window
        WindowGroup {
            ContentView()
                // Makes appState available to all child views
                .environmentObject(appState)
        }
    }
}
```

### Good Example - TestExecutor.swift

```swift
/// Executes test scenarios against target chatbots
/// Manages communication, timing, validation, and result collection
class TestExecutor {
    /// Executes all scenarios in a test configuration
    /// Runs scenarios sequentially, collecting results for each
    /// 
    /// - Parameters:
    ///   - config: Test configuration with scenarios and validation rules
    ///   - progressCallback: Called after each scenario with progress (0.0-1.0) and status message
    /// - Returns: TestResults containing all scenario results and summary
    /// - Throws: TestError if connection fails or critical error occurs
    func executeTests(
        config: TestConfig,
        progressCallback: @escaping (Double, String) async -> Void
    ) async throws -> TestResults {
        // Implementation...
    }
}
```

## Enforcement

- All new code must include comprehensive comments
- Code reviews should check for adequate documentation
- AI assistants should add comments when generating code
- When modifying existing code, add comments if missing

## Benefits

- Helps new Swift programmers learn the codebase
- Makes code review easier
- Reduces onboarding time for new contributors
- Serves as inline documentation
- Explains design decisions for future maintainers

## Resources

- [Swift Documentation Guidelines](https://swift.org/documentation/api-design-guidelines/)
- [Apple's Code Documentation](https://developer.apple.com/library/archive/documentation/Xcode/Reference/xcode_markup_formatting_ref/)
- See `AI_ASSISTANT_GUIDE.md` for more examples
