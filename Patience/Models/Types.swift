import Foundation

// MARK: - Configuration Types

struct TestConfig: Codable, Identifiable, Sendable {
    var id: UUID = UUID()
    var targetBot: BotConfig
    var scenarios: [Scenario]
    var validation: ValidationConfig
    var timing: TimingConfig
    var reporting: ReportConfig
}

struct BotConfig: Codable, Sendable {
    var name: String
    var botProtocol: BotProtocol
    var endpoint: String
    var authentication: AuthConfig?
    var headers: [String: String]?
    var provider: BotProvider?
    var model: String?
    
    private enum CodingKeys: String, CodingKey {
        case name
        case botProtocol = "protocol"
        case endpoint
        case authentication
        case headers
        case provider
        case model
    }
}

enum BotProtocol: String, Codable, CaseIterable, Sendable {
    case http = "http"
    case websocket = "websocket"
}

enum BotProvider: String, Codable, CaseIterable, Sendable {
    case ollama = "ollama"
    case generic = "generic"
    case openai = "openai"
    case anthropic = "anthropic"
}

struct AuthConfig: Codable, Sendable {
    var type: AuthType
    var credentials: String
}

enum AuthType: String, Codable, CaseIterable, Sendable {
    case bearer = "bearer"
    case basic = "basic"
    case apikey = "apikey"
}

struct ValidationConfig: Codable, Sendable {
    var defaultType: ValidationType
    var semanticSimilarityThreshold: Double?
    var customValidators: [String: String]?
}

enum ValidationType: String, Codable, CaseIterable, Sendable {
    case exact = "exact"
    case pattern = "pattern"
    case semantic = "semantic"
    case custom = "custom"
}

struct TimingConfig: Codable, Sendable {
    var enableDelays: Bool
    var baseDelay: Int
    var delayPerCharacter: Int
    var rapidFire: Bool
    var responseTimeout: Int
}

struct ReportConfig: Codable, Sendable {
    var outputPath: String
    var formats: [ReportFormat]
    var includeConversationHistory: Bool
    var verboseErrors: Bool
}

enum ReportFormat: String, Codable, CaseIterable, Sendable {
    case json = "json"
    case html = "html"
    case markdown = "markdown"
}

// MARK: - Scenario Types

struct Scenario: Codable, Identifiable, Sendable {
    let id: String
    var name: String
    var description: String?
    var steps: [ConversationStep]
    var expectedOutcomes: [ValidationCriteria]
}

struct ConversationStep: Codable, Identifiable, Sendable {
    var id: UUID = UUID()
    var message: String
    var expectedResponse: ResponseCriteria?
    var delay: Int?
}

struct ResponseCriteria: Codable, Sendable {
    var validationType: ValidationType
    var expected: String
    var threshold: Double?
}

struct ValidationCriteria: Codable, Identifiable, Sendable {
    var id: UUID = UUID()
    var type: ValidationType
    var expected: String
    var threshold: Double?
    var description: String?
}

// MARK: - Response Types

struct BotResponse: Codable, Sendable {
    let content: String
    let timestamp: Date
    let metadata: [String: String]?
    let error: String?
    let responseTime: Double?
}

struct ValidationResult: Codable, Identifiable, Sendable {
    var id: UUID = UUID()
    let passed: Bool
    let expected: String?
    var actual: String
    let message: String?
    let details: [String: String]?
}

// MARK: - Conversation Types

struct ConversationHistory: Codable, Identifiable, Sendable {
    var id: UUID = UUID()
    let sessionId: String
    var messages: [ConversationMessage]
    let startTime: Date
    var endTime: Date?
}

struct ConversationMessage: Codable, Identifiable, Sendable {
    var id: UUID = UUID()
    let sender: MessageSender
    var content: String
    let timestamp: Date
    var validationResult: ValidationResult?
}

enum MessageSender: String, Codable, Sendable {
    case patience = "patience"
    case target = "target"
    case adversarial = "adversarial"
}

// MARK: - Test Results

struct TestResults: Codable, Identifiable, Sendable {
    var id: UUID = UUID()
    let testRunId: String
    let startTime: Date
    var endTime: Date?
    var scenarioResults: [ScenarioResult]
    var summary: TestSummary
}

struct ScenarioResult: Codable, Identifiable, Sendable {
    var id: UUID = UUID()
    let scenarioId: String
    let scenarioName: String
    var passed: Bool
    var conversationHistory: ConversationHistory
    var validationResults: [ValidationResult]
    var duration: Double
    var error: String?
}

struct TestSummary: Codable, Sendable {
    var total: Int
    var passed: Int
    var failed: Int
    
    var passRate: Double {
        guard total > 0 else { return 0 }
        return Double(passed) / Double(total)
    }
}

// MARK: - Report Types

struct TestReport: Codable, Identifiable, Sendable {
    var id: UUID = UUID()
    let timestamp: Date
    let totalScenarios: Int
    let passedScenarios: Int
    let failedScenarios: Int
    var scenarioResults: [ScenarioResult]
    let summary: String
}

// MARK: - Adversarial Types

struct AdversarialTestConfig: Codable, Identifiable, Sendable {
    var id: UUID = UUID()
    var targetBot: AdversarialBotConfig
    var adversarialBot: AdversarialBotSettings
    var conversation: ConversationSettings
    var validation: AdversarialValidationConfig?
    var execution: ExecutionSettings
    var safety: SafetySettings?
    var reporting: AdversarialReportConfig
}

struct AdversarialBotConfig: Codable, Sendable {
    var name: String
    var botProtocol: BotProtocol
    var endpoint: String
    var authentication: AuthConfig?
    var headers: [String: String]?
    
    private enum CodingKeys: String, CodingKey {
        case name
        case botProtocol = "protocol"
        case endpoint
        case authentication
        case headers
    }
}

struct AdversarialBotSettings: Codable, Sendable {
    var provider: BotProvider
    var model: String?
    var apiKey: String?
    var endpoint: String?
    var temperature: Double?
    var maxTokens: Int?
}

struct ConversationSettings: Codable, Sendable {
    var strategy: ConversationStrategy
    var maxTurns: Int
    var startingPrompts: [String]?
    var systemPrompt: String?
    var goals: [String]?
    var timeout: Int?
}

enum ConversationStrategy: String, Codable, CaseIterable, Sendable {
    case exploratory = "exploratory"
    case adversarial = "adversarial"
    case focused = "focused"
    case stress = "stress"
    case custom = "custom"
}

struct AdversarialValidationConfig: Codable, Sendable {
    var rules: [ValidationCriteria]
    var realTime: Bool
}

struct ExecutionSettings: Codable, Sendable {
    var numConversations: Int
    var concurrent: Int?
    var delayBetweenTurns: Int?
    var delayBetweenConversations: Int?
}

struct SafetySettings: Codable, Sendable {
    var maxCostUSD: Double?
    var maxRequestsPerMinute: Int?
    var contentFilter: Bool?
}

struct AdversarialReportConfig: Codable, Sendable {
    var outputPath: String
    var formats: [ReportFormat]
    var includeTranscripts: Bool
    var realTimeMonitoring: Bool
}

// MARK: - Analysis Types

struct AnalysisConfig: Codable, Identifiable, Sendable {
    var id: UUID = UUID()
    var logSource: LogSource
    var filters: AnalysisFilters?
    var validation: ValidationConfig?
    var analysis: AnalysisSettings
    var reporting: ReportConfig
}

struct LogSource: Codable, Sendable {
    var path: String
    var format: LogFormat
}

enum LogFormat: String, Codable, CaseIterable, Sendable {
    case json = "json"
    case csv = "csv"
    case text = "text"
    case auto = "auto"
}

struct AnalysisFilters: Codable, Sendable {
    var dateRange: DateRange?
    var minMessages: Int?
}

struct DateRange: Codable, Sendable {
    let start: Date
    let end: Date
}

struct AnalysisSettings: Codable, Sendable {
    var calculateMetrics: Bool
    var detectPatterns: Bool
    var checkContextRetention: Bool
}

struct AnalysisResults: Codable, Identifiable, Sendable {
    var id: UUID = UUID()
    let summary: AnalysisSummary
    let metrics: AnalysisMetrics?
    let patterns: [DetectedPattern]?
    let validationResults: [ValidationResult]?
    let contextAnalysis: ContextRetentionAnalysis?
}

struct ContextRetentionAnalysis: Codable, Sendable {
    let averageContextScore: Double
    let conversationsAnalyzed: Int
    let topicSwitches: Int
    let averageReferenceDistance: Double
    let contextBreaks: Int
}

struct AnalysisSummary: Codable, Sendable {
    let totalConversations: Int
    let analyzedConversations: Int
    let overallPassRate: Double
    let processingTime: Double
}

struct AnalysisMetrics: Codable, Sendable {
    let totalMessages: Int
    let averageMessagesPerConversation: Double
    let averageResponseTime: Double?
}

struct DetectedPattern: Codable, Identifiable, Sendable {
    var id: UUID = UUID()
    let type: String
    let pattern: String
    let frequency: Int
    let confidence: Double
}

// MARK: - Adversarial Test Results

struct AdversarialTestResults: Codable, Identifiable, Sendable {
    var id: UUID = UUID()
    let configId: UUID
    let configName: String
    let timestamp: Date
    let conversations: [ConversationResult]
    let summary: AdversarialTestSummary
}

struct AdversarialTestSummary: Codable, Sendable {
    let totalConversations: Int
    let totalTurns: Int
    let averagePassRate: Double
    let averageDuration: Double
}

struct ConversationResult: Codable, Identifiable, Sendable {
    var id: UUID = UUID()
    let conversationId: String
    let timestamp: Date
    let messages: [AdversarialMessage]
    let turns: Int
    let duration: Double
    let validationResults: [ValidationResult]
    let passRate: Double
    let metrics: ConversationMetrics
    let terminationReason: TerminationReason
    let terminationMessage: String?
}

struct AdversarialMessage: Codable, Identifiable, Sendable {
    var id: UUID = UUID()
    let role: MessageRole
    let content: String
    let timestamp: Date
    let metadata: [String: String]?
}

enum MessageRole: String, Codable, Sendable {
    case adversarial = "adversarial"
    case target = "target"
}

struct ConversationMetrics: Codable, Sendable {
    let avgResponseTime: Double
    let targetBotResponseRate: Double
    let conversationQuality: Double
}

enum TerminationReason: String, Codable, Sendable {
    case max_turns = "max_turns"
    case goal_achieved = "goal_achieved"
    case timeout = "timeout"
    case error = "error"
    case manual = "manual"
    case adversarial_ended = "adversarial_ended"
}

