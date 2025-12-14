import SwiftUI
import Combine
import Security

@MainActor
class AppState: ObservableObject {
    @Published var testConfigs: [TestConfig] = []
    // API keys are stored in Keychain; this array never persists apiKey values.
    @Published var adversarialConfigs: [AdversarialTestConfig] = []
    @Published var analysisConfigs: [AnalysisConfig] = []
    @Published var testResults: [TestResults] = []
    @Published var analysisResults: [AnalysisResults] = []
    @Published var adversarialResults: [AdversarialTestResults] = []
    @Published var reports: [TestReport] = []
    
    @Published var isRunningTest = false
    @Published var isRunningAnalysis = false
    @Published var isRunningAdversarial = false
    
    @Published var currentTestProgress: Double = 0.0
    @Published var currentTestStatus: String = ""
    
    // Error handling
    @Published var errorMessage: String?
    @Published var showError: Bool = false
    
    // Settings
    @Published var defaultOutputPath: String = "~/Documents/Patience Reports"
    @Published var autoSaveConfigs: Bool = true
    @Published var showDetailedLogs: Bool = false
    
    init() {
        loadConfigs()
        if testConfigs.isEmpty {
            loadSampleData()
        }
    }
    
    // MARK: - Test Configuration Management
    
    func addTestConfig(_ config: TestConfig) {
        testConfigs.append(config)
        saveConfigs()
    }
    
    func updateTestConfig(_ config: TestConfig) {
        if let index = testConfigs.firstIndex(where: { $0.id == config.id }) {
            testConfigs[index] = config
            saveConfigs()
        }
    }
    
    func deleteTestConfig(_ config: TestConfig) {
        testConfigs.removeAll { $0.id == config.id }
        saveConfigs()
    }
    
    // MARK: - Adversarial Configuration Management
    
    func addAdversarialConfig(_ config: AdversarialTestConfig) {
        var sanitized = config
        if let key = sanitized.adversarialBot.apiKey {
            let success = KeychainManager.shared.saveAPIKey(for: sanitized.id, key: key)
            if !success {
                showErrorMessage("Failed to securely save API key. The configuration will be saved without the API key.")
            }
            sanitized.adversarialBot.apiKey = nil
        }
        adversarialConfigs.append(sanitized)
        saveConfigs()
    }
    
    func updateAdversarialConfig(_ config: AdversarialTestConfig) {
        if let index = adversarialConfigs.firstIndex(where: { $0.id == config.id }) {
            var sanitized = config
            if let key = sanitized.adversarialBot.apiKey {
                let success = KeychainManager.shared.saveAPIKey(for: sanitized.id, key: key)
                if !success {
                    showErrorMessage("Failed to securely update API key. The configuration will be saved without the API key.")
                }
                sanitized.adversarialBot.apiKey = nil
            }
            adversarialConfigs[index] = sanitized
            saveConfigs()
        }
    }
    
    func deleteAdversarialConfig(_ config: AdversarialTestConfig) {
        let success = KeychainManager.shared.deleteAPIKey(for: config.id)
        if !success {
            showErrorMessage("Failed to delete API key from secure storage. The configuration will still be removed.")
        }
        adversarialConfigs.removeAll { $0.id == config.id }
        saveConfigs()
    }
    
    // MARK: - Analysis Configuration Management
    
    func addAnalysisConfig(_ config: AnalysisConfig) {
        analysisConfigs.append(config)
        saveConfigs()
    }
    
    func updateAnalysisConfig(_ config: AnalysisConfig) {
        if let index = analysisConfigs.firstIndex(where: { $0.id == config.id }) {
            analysisConfigs[index] = config
            saveConfigs()
        }
    }
    
    func deleteAnalysisConfig(_ config: AnalysisConfig) {
        analysisConfigs.removeAll { $0.id == config.id }
        saveConfigs()
    }
    
    // MARK: - Test Execution
    
    func runTest(config: TestConfig) async {
        isRunningTest = true
        currentTestProgress = 0.0
        currentTestStatus = "Initializing test..."
        
        defer {
            isRunningTest = false
            currentTestProgress = 0.0
            currentTestStatus = ""
        }
        
        do {
            let executor = TestExecutor()
            let results = try await executor.executeTests(config: config) { progress, status in
                await MainActor.run {
                    self.currentTestProgress = progress
                    self.currentTestStatus = status
                }
            }
            
            testResults.append(results)
            
            // Generate report
            let reportGenerator = ReportGenerator()
            let report = reportGenerator.generateReport(from: results)
            reports.append(report)
            
        } catch {
            showErrorMessage("Test execution failed: \(error.localizedDescription)")
        }
    }
    
    func runAnalysis(config: AnalysisConfig) async {
        isRunningAnalysis = true
        
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
    
    func runAdversarialTest(config: AdversarialTestConfig) async {
        isRunningAdversarial = true
        
        defer {
            isRunningAdversarial = false
        }
        
        do {
            let orchestrator = AdversarialTestOrchestrator()
            let conversations = try await orchestrator.run(config: config)
            
            // Store adversarial results
            let result = AdversarialTestResults(
                configId: config.id,
                configName: config.targetBot.name,
                timestamp: Date(),
                conversations: conversations,
                summary: AdversarialTestSummary(
                    totalConversations: conversations.count,
                    totalTurns: conversations.reduce(0) { $0 + $1.turns },
                    averagePassRate: conversations.isEmpty ? 0 : conversations.map { $0.passRate }.reduce(0, +) / Double(conversations.count),
                    averageDuration: conversations.isEmpty ? 0 : conversations.map { $0.duration }.reduce(0, +) / Double(conversations.count)
                )
            )
            adversarialResults.append(result)
            saveConfigs()
            
            showErrorMessage("Adversarial test completed with \(conversations.count) conversation(s).", isError: false)
        } catch {
            showErrorMessage("Adversarial test failed: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Error Handling
    
    func showErrorMessage(_ message: String, isError: Bool = true) {
        errorMessage = message
        showError = true
        
        if showDetailedLogs {
            print(isError ? "❌ Error: \(message)" : "ℹ️ Info: \(message)")
        }
    }
    
    func clearError() {
        errorMessage = nil
        showError = false
    }
    
    // MARK: - Data Persistence
    
    private func loadConfigs() {
        // Load test configs
        if let data = UserDefaults.standard.data(forKey: "testConfigs"),
           let decoded = try? JSONDecoder().decode([TestConfig].self, from: data) {
            testConfigs = decoded
        }
        
        // Load adversarial configs
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
    
    private func saveConfigs() {
        guard autoSaveConfigs else { return }
        
        // Save to UserDefaults or file system
        if let encoded = try? JSONEncoder().encode(testConfigs) {
            UserDefaults.standard.set(encoded, forKey: "testConfigs")
        }
        
        if let encoded = try? JSONEncoder().encode(adversarialConfigs) {
            // apiKey is nil for all adversarialConfigs here due to sanitization before save
            UserDefaults.standard.set(encoded, forKey: "adversarialConfigs")
        }
        
        if let encoded = try? JSONEncoder().encode(analysisConfigs) {
            UserDefaults.standard.set(encoded, forKey: "analysisConfigs")
        }
        
        // Save results and reports
        if let encoded = try? JSONEncoder().encode(testResults) {
            UserDefaults.standard.set(encoded, forKey: "testResults")
        }
        
        if let encoded = try? JSONEncoder().encode(analysisResults) {
            UserDefaults.standard.set(encoded, forKey: "analysisResults")
        }
        
        if let encoded = try? JSONEncoder().encode(reports) {
            UserDefaults.standard.set(encoded, forKey: "reports")
        }
        
        if let encoded = try? JSONEncoder().encode(adversarialResults) {
            UserDefaults.standard.set(encoded, forKey: "adversarialResults")
        }
    }
    
    // MARK: - Sample Data
    
    private func loadSampleData() {
        // Add sample test configuration
        let sampleBot = BotConfig(
            name: "Sample Bot",
            botProtocol: .http,
            endpoint: "http://localhost:3000/chat",
            authentication: nil,
            headers: nil,
            provider: .generic,
            model: nil
        )
        
        let sampleScenario = Scenario(
            id: "greeting-test",
            name: "Greeting Test",
            description: "Test basic greeting functionality",
            steps: [
                ConversationStep(
                    message: "Hello",
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
                baseDelay: 1000,
                delayPerCharacter: 50,
                rapidFire: false,
                responseTimeout: 30000
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
