# Patience Documentation

Comprehensive documentation for the Patience macOS application - a native Swift/SwiftUI chatbot testing framework.

## 📚 Documentation Index

### Core Documentation

- **[README.md](README.md)** - Start here! Installation, quick start, and overview
- **[CONTRIBUTING.md](CONTRIBUTING.md)** - Development setup and contribution guidelines
- **[CHANGELOG.md](CHANGELOG.md)** - Version history and release notes
- **[SECURITY.md](SECURITY.md)** - Security policies and vulnerability reporting

---

## 🎯 Features

### 1. Live Testing

**Purpose**: Test your chatbot in real-time with predefined conversation scenarios.

**Key Capabilities**:
- Multi-step conversation flows with expected responses
- Multiple validation types: exact match, regex patterns, semantic similarity
- Configurable timing to simulate human behavior
- Real-time progress monitoring
- Comprehensive test reports

**Configuration Structure**:
```swift
struct TestConfig {
    var targetBot: BotConfig           // Bot endpoint and authentication
    var scenarios: [Scenario]          // Test scenarios to execute
    var validation: ValidationConfig   // Validation rules
    var timing: TimingConfig          // Timing and delays
    var reporting: ReportConfig       // Report generation settings
}
```

**Validation Types**:
- **Exact**: Precise string matching
- **Pattern**: Regular expression matching
- **Semantic**: AI-powered similarity comparison
- **Custom**: User-defined validation logic

**Use Cases**:
- Regression testing after bot updates
- Validating specific conversation flows
- Performance testing with timing controls
- Quality assurance before deployment

---

### 2. Log Analysis

**Purpose**: Analyze historical conversation logs to identify patterns, issues, and metrics.

**Key Capabilities**:
- Multi-format support: JSON, CSV, plain text
- Automatic format detection
- Pattern recognition and anomaly detection
- Statistical metrics calculation
- Context retention analysis
- Advanced filtering options

**Configuration Structure**:
```swift
struct AnalysisConfig {
    var logSource: LogSource           // File path and format
    var filters: AnalysisFilters?      // Date ranges, message counts
    var validation: ValidationConfig?  // Optional validation rules
    var analysis: AnalysisSettings    // Analysis options
    var reporting: ReportConfig       // Report settings
}
```

**Supported Log Formats**:

**JSON**:
```json
[
  {
    "sender": "user",
    "content": "Hello",
    "timestamp": "2024-12-12T10:00:00Z"
  },
  {
    "sender": "bot",
    "content": "Hi there!",
    "timestamp": "2024-12-12T10:00:01Z"
  }
]
```

**CSV**:
```csv
timestamp,sender,content
2024-12-12T10:00:00Z,user,Hello
2024-12-12T10:00:01Z,bot,Hi there!
```

**Text** (alternating user/bot):
```
Hello
Hi there!
How are you?
I'm doing well, thanks!
```

**Metrics Calculated**:
- Total conversations and messages
- Average messages per conversation
- Response times (if available)
- Pass/fail rates
- Pattern frequencies

**Use Cases**:
- Post-mortem analysis of production logs
- Identifying common failure patterns
- Quality metrics over time
- Training data validation

---

### 3. Adversarial Testing

**Purpose**: Use AI models to automatically test your chatbot with realistic, challenging conversations.

**Key Capabilities**:
- Multiple AI provider support (Ollama, OpenAI, Anthropic)
- Various testing strategies
- Configurable conversation parameters
- Safety controls (cost limits, rate limiting)
- Real-time monitoring

**Configuration Structure**:
```swift
struct AdversarialTestConfig {
    var targetBot: AdversarialBotConfig      // Bot to test
    var adversarialBot: AdversarialBotSettings  // AI tester
    var conversation: ConversationSettings   // Strategy and parameters
    var validation: AdversarialValidationConfig?  // Validation rules
    var execution: ExecutionSettings        // Execution parameters
    var safety: SafetySettings?            // Safety controls
    var reporting: AdversarialReportConfig // Report settings
}
```

**Testing Strategies**:

1. **Exploratory**
   - Broad, diverse questions
   - Maps bot capabilities
   - Discovers functionality
   - Best for: Initial testing, feature discovery

2. **Adversarial**
   - Edge cases and contradictions
   - Challenging inputs
   - Finds weaknesses
   - Best for: Security testing, robustness validation

3. **Focused**
   - Deep dive into specific features
   - Goal-oriented testing
   - Targeted validation
   - Best for: Feature-specific testing

4. **Stress**
   - Rapid context switching
   - Complex multi-turn conversations
   - Tests limits
   - Best for: Performance testing, context retention

**AI Providers**:

| Provider | Type | Cost | Privacy | Setup |
|----------|------|------|---------|-------|
| Ollama | Local | Free | Private | Install Ollama, pull model |
| OpenAI | Cloud | Paid | API | Get API key from platform.openai.com |
| Anthropic | Cloud | Paid | API | Get API key from console.anthropic.com |

**Safety Controls**:
- Maximum cost limits (USD)
- Rate limiting (requests per minute)
- Content filtering
- Conversation turn limits

**Use Cases**:
- Automated regression testing
- Finding edge cases
- Stress testing
- Security validation

---

## 🔒 Security

### API Key Storage

Patience uses macOS Keychain Services for secure API key storage:

**Features**:
- Keys encrypted by macOS
- Never stored in configuration files
- Never logged or exported
- Automatic cleanup on config deletion

**Implementation**:
```swift
// Keys are stored with unique identifiers
KeychainManager.shared.saveAPIKey(for: configID, key: apiKey)

// Retrieved only when needed
let apiKey = KeychainManager.shared.apiKey(for: configID)

// Deleted with configuration
KeychainManager.shared.deleteAPIKey(for: configID)
```

**User Feedback**:
- Clear notifications if keychain access fails
- Explanations of what was/wasn't saved
- Graceful degradation (config saved without key)

### App Sandbox

Patience runs in macOS App Sandbox with:
- Network access for bot communication
- File access for log import/export
- Keychain access for API keys
- No unnecessary permissions

---

## 🏗️ Architecture

### Application Structure

```
Patience/
├── Models/                    # Data layer
│   ├── AppState.swift        # @MainActor state management
│   └── Types.swift           # Codable, Sendable types
├── Core/                     # Business logic
│   ├── TestExecutor.swift           # Test execution engine
│   ├── AnalysisEngine.swift         # Log analysis
│   ├── ReportGenerator.swift        # Report generation
│   ├── AdversarialTestOrchestrator.swift  # AI testing
│   └── KeychainManager.swift        # Secure storage
├── Views/                    # UI layer (SwiftUI)
│   ├── TestingView.swift
│   ├── AnalysisView.swift
│   ├── AdversarialView.swift
│   ├── ReportsView.swift
│   └── SettingsView.swift
├── ContentView.swift         # Main navigation
└── PatienceApp.swift         # App entry point
```

### Design Patterns

**MVVM (Model-View-ViewModel)**:
- Models: Pure data structures (Codable, Sendable)
- Views: SwiftUI views (declarative UI)
- ViewModel: AppState (ObservableObject)

**Async/Await**:
- All network operations use Swift concurrency
- Proper error propagation
- Cancellation support

**Dependency Injection**:
- AppState injected via @EnvironmentObject
- Testable architecture
- Loose coupling

### Concurrency

**Thread Safety**:
- AppState marked @MainActor
- All UI updates on main thread
- Background work in async tasks
- Sendable types for data passing

**Example**:
```swift
@MainActor
class AppState: ObservableObject {
    func runTest(config: TestConfig) async {
        // Automatically on main thread
        isRunningTest = true
        
        do {
            // Background work
            let results = try await executor.executeTests(config: config)
            
            // UI update (already on main thread)
            testResults.append(results)
        } catch {
            showErrorMessage(error.localizedDescription)
        }
    }
}
```

---

## 🛠️ Development

### Technology Stack

- **Language**: Swift 5.9+
- **Framework**: SwiftUI
- **Platform**: macOS 13.0+
- **Concurrency**: async/await, Sendable
- **Storage**: UserDefaults, Keychain Services
- **Networking**: URLSession

### Project Setup

1. **Requirements**:
   - Xcode 15.0+
   - macOS 13.0+
   - Swift 5.9+

2. **Clone and Build**:
   ```bash
   git clone https://github.com/ServerWrestler/patience-chatbot.git
   cd patience-chatbot
   open Patience.xcodeproj
   ```

3. **Configuration**:
   - Update `repositoryURL` in `PatienceApp.swift`
   - Update `repositoryURL` in `HelpView.swift`

4. **Build**:
   - Press ⌘+B to build
   - Press ⌘+R to run

### Code Organization

**Models** (Data structures):
- Must be `Codable` for persistence
- Must be `Sendable` for concurrency
- Immutable where possible
- Use `UUID` for identifiers

**Core** (Business logic):
- Pure Swift classes
- No UI dependencies
- Async/await for operations
- Proper error handling

**Views** (UI):
- SwiftUI views
- Declarative syntax
- @EnvironmentObject for state
- Previews for development

### Error Handling

**User-Facing Errors**:
```swift
// Show error to user
appState.showErrorMessage("Operation failed: \(error.localizedDescription)")

// Show info message
appState.showErrorMessage("Test completed successfully", isError: false)

// Clear error
appState.clearError()
```

**Error Display**:
- Native macOS alerts
- Clear, actionable messages
- No technical jargon
- Suggestions for resolution

---

## 📊 Reporting

### Report Formats

**HTML**:
- Interactive, styled reports
- Charts and visualizations
- Conversation transcripts
- Validation details

**JSON**:
- Machine-readable
- Complete data export
- Easy to parse
- Integration-friendly

**Markdown**:
- Human-readable
- Version control friendly
- Documentation-ready
- GitHub-compatible

### Report Contents

All reports include:
- Test/analysis summary
- Pass/fail statistics
- Conversation transcripts
- Validation results
- Timing information
- Error details

### Export Options

- Single report export
- Batch export (all reports)
- Custom output directory
- Automatic timestamping

---

## 🔧 Troubleshooting

### Common Issues

**"Connection Failed"**
- Verify bot endpoint is accessible
- Check network connectivity
- Ensure correct protocol (http/https)
- Review firewall settings

**"Keychain Access Denied"**
- Grant Patience access in System Settings
- Navigate to Privacy & Security → Keychain
- API key will be requested again

**"Analysis Failed"**
- Verify log file format
- Check file permissions
- Ensure file is not corrupted
- Try different format detection

**"Adversarial Test Error"**
- Verify AI provider is running (Ollama)
- Check API key validity (OpenAI/Anthropic)
- Review network connectivity
- Check safety limits

### Debug Mode

Enable detailed logging in Settings:
- Shows all operations
- Logs errors to console
- Displays timing information
- Helps diagnose issues

---

## 📖 Additional Resources

### External Documentation

- [Swift Documentation](https://swift.org/documentation/)
- [SwiftUI Tutorials](https://developer.apple.com/tutorials/swiftui)
- [Ollama Documentation](https://ollama.ai/docs)
- [OpenAI API Reference](https://platform.openai.com/docs)
- [Anthropic API Reference](https://docs.anthropic.com)

### Community

- [GitHub Issues](https://github.com/ServerWrestler/patience-chatbot/issues)
- [GitHub Discussions](https://github.com/ServerWrestler/patience-chatbot/discussions)
- [Project Wiki](https://github.com/ServerWrestler/patience-chatbot/wiki)

---

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

**Last Updated**: December 21, 2025  
**Version**: 1.0.0  
**Platform**: macOS 13.0+
