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

    /// Attack-library flywheel: probes that previously breached/failed a target,
    /// re-injected as few-shot examples in later runs. Persisted to UserDefaults.
    @Published var attackLibrary: [AttackLibraryEntry] = []
    
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

    /// Moves a scenario target-bot credential into the Keychain and blanks it in the returned
    /// copy, so the persisted/exported config never carries the secret. Returns the sanitized
    /// config to store. If no credential is present, the config is returned unchanged.
    ///
    /// The credential is re-hydrated from the Keychain at run time by `hydrated(_:)`.
    private func sanitizeForStorage(_ config: TestConfig) -> TestConfig {
        var sanitized = config
        if let auth = sanitized.targetBot.authentication, !auth.credentials.isEmpty {
            let account = KeychainManager.Account.scenarioBot(sanitized.id)
            if !KeychainManager.shared.save(auth.credentials, account: account) {
                showErrorMessage("Failed to securely store target-bot credentials. The configuration will be saved without them.")
            }
            // Blank the credential in the stored copy; the auth type is preserved.
            sanitized.targetBot.authentication?.credentials = ""
        }
        return sanitized
    }

    /// Returns a copy of `config` with its target-bot credential re-populated from the Keychain.
    /// Used immediately before a run so the executor has the real credential without it ever
    /// living in the persisted config.
    private func hydrated(_ config: TestConfig) -> TestConfig {
        guard config.targetBot.authentication != nil else { return config }
        guard let secret = KeychainManager.shared.secret(account: KeychainManager.Account.scenarioBot(config.id)) else {
            return config
        }
        var hydrated = config
        hydrated.targetBot.authentication?.credentials = secret
        return hydrated
    }

    /// Adds a new live test configuration. The target-bot credential (if any) is moved to the
    /// Keychain before the config is persisted.
    /// - Parameter config: The test configuration to add
    func addTestConfig(_ config: TestConfig) {
        testConfigs.append(sanitizeForStorage(config))
        saveConfigs()
    }

    /// Updates an existing live test configuration. Credentials are re-sanitized to the Keychain.
    /// - Parameter config: The updated test configuration
    func updateTestConfig(_ config: TestConfig) {
        // Find the config with matching ID
        if let index = testConfigs.firstIndex(where: { $0.id == config.id }) {
            testConfigs[index] = sanitizeForStorage(config)
            saveConfigs()
        }
    }

    /// Deletes a live test configuration
    /// Removes all configs with matching ID, and its Keychain credential
    /// Automatically saves to persistent storage after deletion
    /// - Parameter config: The test configuration to delete
    func deleteTestConfig(_ config: TestConfig) {
        KeychainManager.shared.delete(account: KeychainManager.Account.scenarioBot(config.id))
        testConfigs.removeAll { $0.id == config.id }
        saveConfigs()
    }
    
    // MARK: - Adversarial Configuration Management
    
    /// Moves both provider keys (adversarial bot AND judge) into the Keychain and nils them in
    /// the returned copy, so the persisted config never carries a secret. Returns the sanitized
    /// config to store. Keys are re-hydrated at run time by `hydrated(_:)`.
    private func sanitizeForStorage(_ config: AdversarialTestConfig) -> AdversarialTestConfig {
        var sanitized = config
        if let key = sanitized.adversarialBot.apiKey {
            if !KeychainManager.shared.save(key, account: KeychainManager.Account.adversarialBot(sanitized.id)) {
                showErrorMessage("Failed to securely save the adversarial API key. The configuration will be saved without it.")
            }
            sanitized.adversarialBot.apiKey = nil
        }
        if let judgeKey = sanitized.judge?.apiKey {
            if !KeychainManager.shared.save(judgeKey, account: KeychainManager.Account.judge(sanitized.id)) {
                showErrorMessage("Failed to securely save the judge API key. The configuration will be saved without it.")
            }
            sanitized.judge?.apiKey = nil
        }
        return sanitized
    }

    /// Returns a copy of `config` with both provider keys re-populated from the Keychain, used
    /// immediately before a run so the orchestrator can authenticate without the keys ever
    /// living in the persisted config.
    private func hydrated(_ config: AdversarialTestConfig) -> AdversarialTestConfig {
        var hydrated = config
        if hydrated.adversarialBot.apiKey == nil {
            hydrated.adversarialBot.apiKey = KeychainManager.shared.apiKey(for: config.id)
        }
        if hydrated.judge != nil, hydrated.judge?.apiKey == nil {
            hydrated.judge?.apiKey = KeychainManager.shared.secret(account: KeychainManager.Account.judge(config.id))
        }
        return hydrated
    }

    /// Adds a new adversarial test configuration. Provider keys are moved to the Keychain before
    /// the config is persisted.
    /// - Parameter config: The adversarial test configuration to add
    func addAdversarialConfig(_ config: AdversarialTestConfig) {
        adversarialConfigs.append(sanitizeForStorage(config))
        saveConfigs()
    }

    /// Updates an existing adversarial test configuration. Provider keys are re-sanitized to the
    /// Keychain.
    /// - Parameter config: The updated adversarial test configuration
    func updateAdversarialConfig(_ config: AdversarialTestConfig) {
        if let index = adversarialConfigs.firstIndex(where: { $0.id == config.id }) {
            adversarialConfigs[index] = sanitizeForStorage(config)
            saveConfigs()
        }
    }

    /// Deletes an adversarial test configuration
    /// Also removes both associated provider keys (adversarial bot + judge) from Keychain
    /// - Parameter config: The adversarial test configuration to delete
    func deleteAdversarialConfig(_ config: AdversarialTestConfig) {
        KeychainManager.shared.deleteAPIKey(for: config.id)
        KeychainManager.shared.delete(account: KeychainManager.Account.judge(config.id))
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
            // Re-populate the target-bot credential from the Keychain just before running;
            // the persisted config carries a blank credential (see sanitizeForStorage).
            let runConfig = hydrated(config)
            // Execute test with progress callback
            let results = try await executor.executeTests(config: runConfig) { progress, status in
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

            // Re-populate provider keys from the Keychain just before running; the persisted
            // config carries nil keys (see sanitizeForStorage).
            let runConfig = hydrated(config)

            // FLYWHEEL: feed enabled attack-library probes as few-shot examples when enabled.
            let useFlywheel = runConfig.conversation.adaptive?.useFlywheel ?? false
            let flywheelExamples = useFlywheel
                ? attackLibrary.filter { $0.enabled }.map { $0.probe }
                : []

            let conversations = try await orchestrator.run(config: runConfig, flywheelExamples: flywheelExamples)
            
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

            // FLYWHEEL HARVEST: store winning probes from this run for future injection.
            if useFlywheel {
                harvestAttackLibrary(from: result)
            }

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

                    // Accept either an array of configs or a single config.
                    var importedConfigs: [TestConfig] = []
                    if let configArray = try? decoder.decode([TestConfig].self, from: data) {
                        importedConfigs = configArray
                    } else if let singleConfig = try? decoder.decode(TestConfig.self, from: data) {
                        importedConfigs = [singleConfig]
                    } else {
                        throw NSError(domain: "ImportError", code: 1, userInfo: [NSLocalizedDescriptionKey: "File does not contain a valid test configuration or array of configurations."])
                    }

                    // Generate new IDs for imported configs to avoid conflicts
                    let configsWithNewIds = importedConfigs.map { config in
                        var newConfig = config
                        newConfig.id = UUID()
                        return newConfig
                    }

                    Task { @MainActor in
                        // Route each imported config through sanitizeForStorage so any inline
                        // credentials in the file are moved to the Keychain, never persisted.
                        for config in configsWithNewIds {
                            self.testConfigs.append(self.sanitizeForStorage(config))
                        }
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

        // Load attack-library flywheel
        if let data = UserDefaults.standard.data(forKey: "attackLibrary"),
           let decoded = try? JSONDecoder().decode([AttackLibraryEntry].self, from: data) {
            attackLibrary = decoded
        }

        migrateInlineSecretsToKeychain()
    }

    /// One-time migration for configs saved by builds that stored secrets inline in UserDefaults.
    /// Any config still carrying an inline credential/key has it moved to the Keychain and blanked
    /// in memory, then everything is re-persisted. Idempotent: once migrated there's nothing to do.
    private func migrateInlineSecretsToKeychain() {
        var migrated = false

        for i in testConfigs.indices {
            if let auth = testConfigs[i].targetBot.authentication, !auth.credentials.isEmpty {
                KeychainManager.shared.save(auth.credentials, account: KeychainManager.Account.scenarioBot(testConfigs[i].id))
                testConfigs[i].targetBot.authentication?.credentials = ""
                migrated = true
            }
        }
        for i in adversarialConfigs.indices {
            if let key = adversarialConfigs[i].adversarialBot.apiKey {
                KeychainManager.shared.save(key, account: KeychainManager.Account.adversarialBot(adversarialConfigs[i].id))
                adversarialConfigs[i].adversarialBot.apiKey = nil
                migrated = true
            }
            if let judgeKey = adversarialConfigs[i].judge?.apiKey {
                KeychainManager.shared.save(judgeKey, account: KeychainManager.Account.judge(adversarialConfigs[i].id))
                adversarialConfigs[i].judge?.apiKey = nil
                migrated = true
            }
        }

        if migrated { saveConfigs() }
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
        
        // Save adversarial configs. Both provider keys (adversarial bot + judge) are already
        // nil here — sanitizeForStorage(_:) moved them to the Keychain before the config
        // reached this array — so nothing secret is written to UserDefaults.
        if let encoded = try? JSONEncoder().encode(adversarialConfigs) {
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

        // Save attack-library flywheel
        if let encoded = try? JSONEncoder().encode(attackLibrary) {
            UserDefaults.standard.set(encoded, forKey: "attackLibrary")
        }
    }

    // MARK: - Attack Library (Flywheel)

    /// Adds an attack-library entry and persists. Deduplicates on identical probe text.
    func addAttackLibraryEntry(_ entry: AttackLibraryEntry) {
        guard !attackLibrary.contains(where: { $0.probe == entry.probe }) else { return }
        attackLibrary.append(entry)
        saveConfigs()
    }

    /// Deletes an attack-library entry and persists.
    func deleteAttackLibraryEntry(_ entry: AttackLibraryEntry) {
        attackLibrary.removeAll { $0.id == entry.id }
        saveConfigs()
    }

    /// Toggles whether an entry is injected into future runs, and persists.
    func setAttackLibraryEntryEnabled(_ entry: AttackLibraryEntry, enabled: Bool) {
        guard let idx = attackLibrary.firstIndex(where: { $0.id == entry.id }) else { return }
        attackLibrary[idx].enabled = enabled
        saveConfigs()
    }

    /// Replaces an entry's tag list (after de-dup + trim) and persists.
    /// Empty / whitespace-only tags are dropped so the viewer's chip list stays clean.
    func setAttackLibraryEntryTags(_ entry: AttackLibraryEntry, tags: [String]) {
        guard let idx = attackLibrary.firstIndex(where: { $0.id == entry.id }) else { return }
        let cleaned = tags
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        var seen = Set<String>()
        let deduped = cleaned.filter { seen.insert($0).inserted }
        attackLibrary[idx].tags = deduped.isEmpty ? nil : deduped
        saveConfigs()
    }

    /// Encodes the attack library as pretty-printed JSON for export to disk.
    /// The serialized shape is a JSON array of `AttackLibraryEntry` — same wire
    /// format used internally so a re-import is lossless. IDs are preserved so
    /// re-importing the same file is idempotent (dedup keys on probe text).
    func exportAttackLibraryJSON() throws -> Data {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        return try encoder.encode(attackLibrary)
    }

    /// Imports a previously-exported attack-library JSON file. Entries with a probe
    /// already in the library are skipped (existing `addAttackLibraryEntry` dedup
    /// rule), so re-importing a partly-overlapping export is safe.
    ///
    /// - Parameter data: Raw JSON bytes; expected shape is `[AttackLibraryEntry]`.
    /// - Returns: Count of entries actually added (skipping duplicates).
    /// - Throws: Decoding errors propagate so the caller can surface them.
    @discardableResult
    func importAttackLibraryJSON(_ data: Data) throws -> Int {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let entries = try decoder.decode([AttackLibraryEntry].self, from: data)
        let before = attackLibrary.count
        for entry in entries {
            // addAttackLibraryEntry handles dedup-by-probe and persists each insert.
            addAttackLibraryEntry(entry)
        }
        return attackLibrary.count - before
    }

    /// Harvests winning probes from a completed run into the attack library.
    /// A "win" = the judge flagged a breach, or (absent a judge) a validation failed.
    /// Called after an adversarial run when the flywheel is enabled.
    ///
    /// - Parameter result: The completed adversarial test results to harvest from.
    func harvestAttackLibrary(from result: AdversarialTestResults) {
        for convo in result.conversations {
            // Pair each target reply with the probe that preceded it.
            for (idx, message) in convo.messages.enumerated() where message.role == .target {
                let breached = message.metadata?[JudgeVerdict.MetaKey.breached] == "true"
                guard breached else { continue }
                // The preceding adversarial message is the probe that caused this.
                guard idx > 0, convo.messages[idx - 1].role == .adversarial else { continue }
                let probe = convo.messages[idx - 1].content
                let vector = message.metadata?[JudgeVerdict.MetaKey.vector] ?? ""
                // Seed tags from the judge's vector so the entry is filterable
                // immediately; user can edit tags later in the viewer.
                let seededTags = vector.isEmpty ? nil : [vector]
                let entry = AttackLibraryEntry(
                    probe: probe,
                    replySnippet: String(message.content.prefix(160)),
                    vector: vector,
                    severity: message.metadata?[JudgeVerdict.MetaKey.severity] ?? "unknown",
                    tags: seededTags
                )
                addAttackLibraryEntry(entry)
            }
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
