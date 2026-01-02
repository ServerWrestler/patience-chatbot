/// This file manages the global application state for Patience
/// Contains all configurations, test results, and runtime state
/// Uses @MainActor to ensure all UI updates happen on the main thread
/// Conforms to ObservableObject so SwiftUI views can observe changes

// Import SwiftUI for @Published and ObservableObject
import SwiftUI
// Import Combine for reactive programming support
import Combine
// Import Security framework for Keychain access
import Security
// Import AppKit for file dialogs (NSSavePanel, NSOpenPanel)
import AppKit
// Import UniformTypeIdentifiers for file type handling
import UniformTypeIdentifiers

/// Central state manager for the entire application
/// Holds all test configurations, results, and runtime state
/// @MainActor ensures all property updates happen on main thread (required for UI)
/// ObservableObject allows SwiftUI views to automatically update when properties change
@MainActor
class AppState: ObservableObject {
    
    // MARK: - Configuration Storage
    
    /// Array of live test configurations created by the user
    /// @Published triggers UI updates when this array changes
    /// Automatically saved to UserDefaults when modified
    @Published var testConfigs: [TestConfig] = []
    
    /// Array of adversarial test configurations
    /// API keys are stored separately in Keychain for security
    /// This array never contains actual API key values (sanitized before save)
    @Published var adversarialConfigs: [AdversarialTestConfig] = []
    
    /// Array of log analysis configurations
    /// Defines which log files to analyze and how
    @Published var analysisConfigs: [AnalysisConfig] = []
    
    // MARK: - Results Storage
    
    /// Results from completed live tests
    /// Contains conversation history, validation results, and metrics
    @Published var testResults: [TestResults] = []
    
    /// Results from completed log analyses
    /// Contains metrics, patterns, and validation results
    @Published var analysisResults: [AnalysisResults] = []
    
    /// Results from completed adversarial tests
    /// Contains AI-generated conversations and their outcomes
    @Published var adversarialResults: [AdversarialTestResults] = []
    
    /// Generated reports from test results
    /// Can be exported in multiple formats (JSON, HTML, Markdown)
    @Published var reports: [TestReport] = []
    
    // MARK: - Runtime State
    
    /// Indicates if a live test is currently running
    /// Used to disable UI elements and show progress
    @Published var isRunningTest = false
    
    /// Indicates if a log analysis is currently running
    @Published var isRunningAnalysis = false
    
    /// Indicates if an adversarial test is currently running
    @Published var isRunningAdversarial = false
    
    /// Current progress of running test (0.0 to 1.0)
    /// Used to update progress bars in the UI
    @Published var currentTestProgress: Double = 0.0
    
    /// Status message for current test operation
    /// Displayed to user during test execution
    @Published var currentTestStatus: String = ""
    
    // MARK: - Error Handling
    
    /// Current error message to display to user
    /// nil when no error is present
    @Published var errorMessage: String?
    
    /// Controls whether error alert is shown
    /// Set to true to display error dialog
    @Published var showError: Bool = false
    
    // MARK: - User Settings
    
    /// Default directory path for saving reports
    /// Can be customized by user in settings
    @Published var defaultOutputPath: String = "~/Documents/Patience Reports"
    
    /// Whether to automatically save configs after changes
    /// If false, user must manually save
    @Published var autoSaveConfigs: Bool = true
    
    /// Whether to print detailed logs to console
    /// Useful for debugging
    @Published var showDetailedLogs: Bool = false
    
    /// Initializes the application state
    /// Loads saved configurations from UserDefaults
    /// Creates sample data if no configs exist (first launch)
    init() {
        loadConfigs()
        // Provide sample data for new users
        if testConfigs.isEmpty {
            loadSampleData()
        }
    }
    
    // MARK: - Test Configuration Management
    
    /// Adds a new live test configuration
    /// Automatically saves to persistent storage after adding
    /// - Parameter config: The test configuration to add
    func addTestConfig(_ config: TestConfig) {
        testConfigs.append(config)
        saveConfigs()
    }
    
    /// Updates an existing live test configuration
    /// Finds config by ID and replaces it with new version
    /// Automatically saves to persistent storage after updating
    /// - Parameter config: The updated test configuration
    func updateTestConfig(_ config: TestConfig) {
        // Find the config with matching ID
        if let index = testConfigs.firstIndex(where: { $0.id == config.id }) {
            testConfigs[index] = config
            saveConfigs()
        }
    }
    
    /// Deletes a live test configuration
    /// Removes all configs with matching ID
    /// Automatically saves to persistent storage after deletion
    /// - Parameter config: The test configuration to delete
    func deleteTestConfig(_ config: TestConfig) {
        testConfigs.removeAll { $0.id == config.id }
        saveConfigs()
    }
    
    // MARK: - Adversarial Configuration Management
    
    /// Adds a new adversarial test configuration
    /// Extracts and securely stores API key in Keychain before saving
    /// The config is sanitized (API key removed) before being stored in UserDefaults
    /// - Parameter config: The adversarial test configuration to add
    func addAdversarialConfig(_ config: AdversarialTestConfig) {
        var sanitized = config
        // If config contains an API key, save it securely to Keychain
        if let key = sanitized.adversarialBot.apiKey {
            let success = KeychainManager.shared.saveAPIKey(for: sanitized.id, key: key)
            if !success {
                showErrorMessage("Failed to securely save API key. The configuration will be saved without the API key.")
            }
            // Remove API key from config before saving to UserDefaults (security)
            sanitized.adversarialBot.apiKey = nil
        }
        adversarialConfigs.append(sanitized)
        saveConfigs()
    }
    
    /// Updates an existing adversarial test configuration
    /// Handles API key storage securely in Keychain
    /// - Parameter config: The updated adversarial test configuration
    func updateAdversarialConfig(_ config: AdversarialTestConfig) {
        if let index = adversarialConfigs.firstIndex(where: { $0.id == config.id }) {
            var sanitized = config
            // If config contains an API key, update it in Keychain
            if let key = sanitized.adversarialBot.apiKey {
                let success = KeychainManager.shared.saveAPIKey(for: sanitized.id, key: key)
                if !success {
                    showErrorMessage("Failed to securely update API key. The configuration will be saved without the API key.")
                }
                // Remove API key from config before saving to UserDefaults (security)
                sanitized.adversarialBot.apiKey = nil
            }
            adversarialConfigs[index] = sanitized
            saveConfigs()
        }
    }
    
    /// Deletes an adversarial test configuration
    /// Also removes associated API key from Keychain
    /// - Parameter config: The adversarial test configuration to delete
    func deleteAdversarialConfig(_ config: AdversarialTestConfig) {
        // Try to delete API key from Keychain
        let success = KeychainManager.shared.deleteAPIKey(for: config.id)
        if !success {
            showErrorMessage("Failed to delete API key from secure storage. The configuration will still be removed.")
        }
        adversarialConfigs.removeAll { $0.id == config.id }
        saveConfigs()
    }
    
    // MARK: - Analysis Configuration Management
    
    /// Adds a new log analysis configuration
    /// Automatically saves to persistent storage after adding
    /// - Parameter config: The analysis configuration to add
    func addAnalysisConfig(_ config: AnalysisConfig) {
        analysisConfigs.append(config)
        saveConfigs()
    }
    
    /// Updates an existing log analysis configuration
    /// Finds config by ID and replaces it with new version
    /// - Parameter config: The updated analysis configuration
    func updateAnalysisConfig(_ config: AnalysisConfig) {
        if let index = analysisConfigs.firstIndex(where: { $0.id == config.id }) {
            analysisConfigs[index] = config
            saveConfigs()
        }
    }
    
    /// Deletes a log analysis configuration
    /// Removes all configs with matching ID
    /// - Parameter config: The analysis configuration to delete
    func deleteAnalysisConfig(_ config: AnalysisConfig) {
        analysisConfigs.removeAll { $0.id == config.id }
        saveConfigs()
    }
    
    // MARK: - Test Execution
    
    /// Executes a live test with the given configuration
    /// Runs asynchronously, updating progress and status during execution
    /// Automatically generates a report when test completes
    /// 
    /// - Parameter config: The test configuration to execute
    /// 
    /// Side effects:
    /// - Sets isRunningTest to true during execution
    /// - Updates currentTestProgress and currentTestStatus
    /// - Appends results to testResults array
    /// - Generates and appends report to reports array
    /// - Shows error message if test fails
    func runTest(config: TestConfig) async {
        isRunningTest = true
        currentTestProgress = 0.0
        currentTestStatus = "Initializing test..."
        
        // defer ensures cleanup happens even if function exits early
        defer {
            isRunningTest = false
            currentTestProgress = 0.0
            currentTestStatus = ""
        }
        
        do {
            let executor = TestExecutor()
            // Execute test with progress callback
            let results = try await executor.executeTests(config: config) { progress, status in
                // Update UI on main thread
                await MainActor.run {
                    self.currentTestProgress = progress
                    self.currentTestStatus = status
                }
            }
            
            // Store results
            testResults.append(results)
            
            // Generate and store report
            let reportGenerator = ReportGenerator()
            let report = reportGenerator.generateReport(from: results)
            reports.append(report)
            
        } catch {
            showErrorMessage("Test execution failed: \(error.localizedDescription)")
        }
    }
    
    /// Executes a log analysis with the given configuration
    /// Runs asynchronously, parsing and analyzing log files
    /// 
    /// - Parameter config: The analysis configuration to execute
    /// 
    /// Side effects:
    /// - Sets isRunningAnalysis to true during execution
    /// - Appends results to analysisResults array
    /// - Shows error message if analysis fails
    func runAnalysis(config: AnalysisConfig) async {
        isRunningAnalysis = true
        
        // defer ensures cleanup happens even if function exits early
        defer {
            isRunningAnalysis = false
        }
        
        do {
            let analyzer = AnalysisEngine()
            let results = try await analyzer.analyze(config: config)
            analysisResults.append(results)
        } catch {
            showErrorMessage("Analysis failed: \(error.localizedDescription)")
        }
    }
    
    /// Executes an adversarial test with the given configuration
    /// Uses AI to generate challenging conversations with the target bot
    /// Runs asynchronously, may take several minutes depending on configuration
    /// 
    /// - Parameter config: The adversarial test configuration to execute
    /// 
    /// Side effects:
    /// - Sets isRunningAdversarial to true during execution
    /// - Appends results to adversarialResults array
    /// - Saves configs (to persist results)
    /// - Shows completion or error message
    func runAdversarialTest(config: AdversarialTestConfig) async {
        isRunningAdversarial = true
        
        // defer ensures cleanup happens even if function exits early
        defer {
            isRunningAdversarial = false
        }
        
        do {
            let orchestrator = AdversarialTestOrchestrator()
            let conversations = try await orchestrator.run(config: config)
            
            // Package results with summary statistics
            let result = AdversarialTestResults(
                configId: config.id,
                configName: config.targetBot.name,
                timestamp: Date(),
                conversations: conversations,
                summary: AdversarialTestSummary(
                    totalConversations: conversations.count,
                    // Sum up all turns across conversations
                    totalTurns: conversations.reduce(0) { $0 + $1.turns },
                    // Calculate average pass rate across all conversations
                    averagePassRate: conversations.isEmpty ? 0 : conversations.map { $0.passRate }.reduce(0, +) / Double(conversations.count),
                    // Calculate average duration across all conversations
                    averageDuration: conversations.isEmpty ? 0 : conversations.map { $0.duration }.reduce(0, +) / Double(conversations.count)
                )
            )
            adversarialResults.append(result)
            saveConfigs()
            
            // Show success message (isError: false means it's informational)
            showErrorMessage("Adversarial test completed with \(conversations.count) conversation(s).", isError: false)
        } catch {
            showErrorMessage("Adversarial test failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Configuration Export/Import
    
    /// Exports a single test configuration to a JSON file
    /// Opens a save dialog for the user to choose location and filename
    /// 
    /// - Parameter config: The test configuration to export
    /// 
    /// Side effects:
    /// - Opens NSSavePanel for file selection
    /// - Writes JSON file to selected location
    /// - Shows success/error message to user
    func exportTestConfig(_ config: TestConfig) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "\(config.targetBot.name.replacingOccurrences(of: " ", with: "-").lowercased())-config.json"
        panel.title = "Export Test Configuration"
        panel.message = "Choose where to save the test configuration"
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                do {
                    let encoder = JSONEncoder()
                    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                    let data = try encoder.encode(config)
                    try data.write(to: url)
                    
                    Task { @MainActor in
                        self.showErrorMessage("Configuration exported successfully to \(url.lastPathComponent)", isError: false)
                    }
                } catch {
                    Task { @MainActor in
                        self.showErrorMessage("Failed to export configuration: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    /// Exports all test configurations to a JSON file
    /// Creates a single file containing an array of all configurations
    /// 
    /// Side effects:
    /// - Opens NSSavePanel for file selection
    /// - Writes JSON file with all configurations
    /// - Shows success/error message to user
    func exportAllTestConfigs() {
        guard !testConfigs.isEmpty else {
            showErrorMessage("No configurations to export", isError: false)
            return
        }
        
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "patience-test-configs.json"
        panel.title = "Export All Test Configurations"
        panel.message = "Choose where to save all test configurations"
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                do {
                    let encoder = JSONEncoder()
                    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                    let data = try encoder.encode(self.testConfigs)
                    try data.write(to: url)
                    
                    Task { @MainActor in
                        self.showErrorMessage("Exported \(self.testConfigs.count) configuration(s) successfully to \(url.lastPathComponent)", isError: false)
                    }
                } catch {
                    Task { @MainActor in
                        self.showErrorMessage("Failed to export configurations: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    /// Imports test configurations from a JSON file
    /// Supports both single configuration and array of configurations
    /// Merges with existing configurations (doesn't replace)
    /// 
    /// Side effects:
    /// - Opens NSOpenPanel for file selection
    /// - Reads and parses JSON file
    /// - Adds configurations to testConfigs array
    /// - Automatically saves configurations
    /// - Shows success/error message to user
    func importTestConfigs() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        panel.title = "Import Test Configurations"
        panel.message = "Choose a JSON file containing test configurations"
        
        panel.begin { response in
            if response == .OK, let url = panel.urls.first {
                do {
                    let data = try Data(contentsOf: url)
                    let decoder = JSONDecoder()
                    
                    var importedConfigs: [TestConfig] = []
                    
                    // Try to decode as array of configurations first
                    if let configArray = try? decoder.decode([TestConfig].self, from: data) {
                        importedConfigs = configArray
                    }
                    // If that fails, try to decode as single configuration
                    else if let singleConfig = try? decoder.decode(TestConfig.self, from: data) {
                        importedConfigs = [singleConfig]
                    }
                    else {
                        throw NSError(domain: "ImportError", code: 1, userInfo: [NSLocalizedDescriptionKey: "File does not contain valid test configuration(s)"])
                    }
                    
                    // Generate new IDs for imported configs to avoid conflicts
                    let configsWithNewIds = importedConfigs.map { config in
                        var newConfig = config
                        newConfig.id = UUID()
                        return newConfig
                    }
                    
                    Task { @MainActor in
                        // Add to existing configurations
                        self.testConfigs.append(contentsOf: configsWithNewIds)
                        self.saveConfigs()
                        
                        self.showErrorMessage("Successfully imported \(configsWithNewIds.count) configuration(s) from \(url.lastPathComponent)", isError: false)
                    }
                } catch {
                    Task { @MainActor in
                        self.showErrorMessage("Failed to import configurations: \(error.localizedDescription)")
                    }
                }
            }
        }
    }
    
    /// Copies a test configuration to the system clipboard as JSON
    /// Useful for quick sharing via chat, email, etc.
    /// 
    /// - Parameter config: The test configuration to copy
    /// 
    /// Side effects:
    /// - Copies JSON to system clipboard
    /// - Shows success/error message to user
    func copyConfigToClipboard(_ config: TestConfig) {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(config)
            
            if let jsonString = String(data: data, encoding: .utf8) {
                let pasteboard = NSPasteboard.general
                pasteboard.clearContents()
                pasteboard.setString(jsonString, forType: .string)
                
                showErrorMessage("Configuration copied to clipboard", isError: false)
            } else {
                showErrorMessage("Failed to convert configuration to text")
            }
        } catch {
            showErrorMessage("Failed to copy configuration: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Error Handling
    
    /// Displays an error or informational message to the user
    /// Sets errorMessage and showError to trigger alert dialog
    /// Optionally prints to console if detailed logging is enabled
    /// 
    /// - Parameters:
    ///   - message: The message to display
    ///   - isError: Whether this is an error (true) or info message (false)
    func showErrorMessage(_ message: String, isError: Bool = true) {
        errorMessage = message
        showError = true
        
        // Print to console if detailed logging enabled
        if showDetailedLogs {
            print(isError ? "❌ Error: \(message)" : "ℹ️ Info: \(message)")
        }
    }
    
    /// Clears the current error message and hides the alert
    /// Called when user dismisses the error dialog
    func clearError() {
        errorMessage = nil
        showError = false
    }
    
    // MARK: - Data Persistence
    
    /// Loads all configurations and results from UserDefaults
    /// Called during initialization to restore previous session
    /// Uses JSONDecoder to deserialize saved data
    /// Silently fails if data doesn't exist or can't be decoded
    private func loadConfigs() {
        // Load test configs from UserDefaults
        if let data = UserDefaults.standard.data(forKey: "testConfigs"),
           let decoded = try? JSONDecoder().decode([TestConfig].self, from: data) {
            testConfigs = decoded
        }
        
        // Load adversarial configs (API keys loaded separately from Keychain)
        if let data = UserDefaults.standard.data(forKey: "adversarialConfigs"),
           let decoded = try? JSONDecoder().decode([AdversarialTestConfig].self, from: data) {
            adversarialConfigs = decoded
        }
        
        // Load analysis configs
        if let data = UserDefaults.standard.data(forKey: "analysisConfigs"),
           let decoded = try? JSONDecoder().decode([AnalysisConfig].self, from: data) {
            analysisConfigs = decoded
        }
        
        // Load test results
        if let data = UserDefaults.standard.data(forKey: "testResults"),
           let decoded = try? JSONDecoder().decode([TestResults].self, from: data) {
            testResults = decoded
        }
        
        // Load analysis results
        if let data = UserDefaults.standard.data(forKey: "analysisResults"),
           let decoded = try? JSONDecoder().decode([AnalysisResults].self, from: data) {
            analysisResults = decoded
        }
        
        // Load reports
        if let data = UserDefaults.standard.data(forKey: "reports"),
           let decoded = try? JSONDecoder().decode([TestReport].self, from: data) {
            reports = decoded
        }
        
        // Load adversarial results
        if let data = UserDefaults.standard.data(forKey: "adversarialResults"),
           let decoded = try? JSONDecoder().decode([AdversarialTestResults].self, from: data) {
            adversarialResults = decoded
        }
    }
    
    /// Saves all configurations and results to UserDefaults
    /// Called automatically after any config changes (if autoSaveConfigs is true)
    /// Uses JSONEncoder to serialize data
    /// API keys are NOT saved here (stored separately in Keychain)
    private func saveConfigs() {
        // Check if auto-save is enabled
        guard autoSaveConfigs else { return }
        
        // Save test configs to UserDefaults
        if let encoded = try? JSONEncoder().encode(testConfigs) {
            UserDefaults.standard.set(encoded, forKey: "testConfigs")
        }
        
        // Save adversarial configs (without API keys - those are in Keychain)
        if let encoded = try? JSONEncoder().encode(adversarialConfigs) {
            // Note: apiKey is nil for all adversarialConfigs due to sanitization before save
            UserDefaults.standard.set(encoded, forKey: "adversarialConfigs")
        }
        
        // Save analysis configs
        if let encoded = try? JSONEncoder().encode(analysisConfigs) {
            UserDefaults.standard.set(encoded, forKey: "analysisConfigs")
        }
        
        // Save test results
        if let encoded = try? JSONEncoder().encode(testResults) {
            UserDefaults.standard.set(encoded, forKey: "testResults")
        }
        
        // Save analysis results
        if let encoded = try? JSONEncoder().encode(analysisResults) {
            UserDefaults.standard.set(encoded, forKey: "analysisResults")
        }
        
        // Save reports
        if let encoded = try? JSONEncoder().encode(reports) {
            UserDefaults.standard.set(encoded, forKey: "reports")
        }
        
        // Save adversarial results
        if let encoded = try? JSONEncoder().encode(adversarialResults) {
            UserDefaults.standard.set(encoded, forKey: "adversarialResults")
        }
    }
    
    // MARK: - Sample Data
    
    /// Creates sample test configuration for new users
    /// Called during initialization if no configs exist
    /// Provides a working example to help users get started
    /// Sample tests a basic greeting scenario against a local bot
    private func loadSampleData() {
        // Create sample bot configuration pointing to localhost
        let sampleBot = BotConfig(
            name: "Sample Bot",
            botProtocol: .http,
            endpoint: "http://localhost:3000/chat",
            authentication: nil,
            headers: nil,
            provider: .generic,
            model: nil
        )
        
        // Create sample scenario testing greeting functionality
        let sampleScenario = Scenario(
            id: "greeting-test",
            name: "Greeting Test",
            description: "Test basic greeting functionality",
            steps: [
                ConversationStep(
                    message: "Hello",
                    // Expects response containing hello, hi, or greetings
                    expectedResponse: ResponseCriteria(
                        validationType: .pattern,
                        expected: "hello|hi|greetings",
                        threshold: 0.8
                    )
                )
            ],
            expectedOutcomes: [
                ValidationCriteria(
                    type: .pattern,
                    expected: "friendly response",
                    threshold: 0.7,
                    description: "Bot should respond in a friendly manner"
                )
            ]
        )
        
        // Create complete test configuration with all settings
        let sampleConfig = TestConfig(
            targetBot: sampleBot,
            scenarios: [sampleScenario],
            validation: ValidationConfig(
                defaultType: .pattern,
                semanticSimilarityThreshold: 0.8,
                customValidators: nil
            ),
            timing: TimingConfig(
                enableDelays: true,
                baseDelay: 1000,              // 1 second base delay
                delayPerCharacter: 50,         // 50ms per character (simulates typing)
                rapidFire: false,
                responseTimeout: 30000         // 30 second timeout
            ),
            reporting: ReportConfig(
                outputPath: "~/Documents/Patience Reports",
                formats: [.json, .html],
                includeConversationHistory: true,
                verboseErrors: true
            )
        )
        
        testConfigs.append(sampleConfig)
    }
}
