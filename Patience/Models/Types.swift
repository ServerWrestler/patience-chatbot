/// This file defines all data structures used throughout the Patience application
/// Includes configuration types, test scenarios, results, and analysis data
/// All types are Codable (for JSON serialization/persistence) and Sendable (for safe async/await usage)
/// Organized into sections: Configuration, Scenarios, Responses, Conversations, Results, Reports, Adversarial, Analysis

import Foundation

// MARK: - Configuration Types

/// Complete configuration for a live test run
/// Contains all settings needed to execute test scenarios against a target bot
/// Codable: Can be saved to/loaded from disk
/// Identifiable: Can be used in SwiftUI lists with unique ID
/// Sendable: Safe to pass between async contexts
struct TestConfig: Codable, Identifiable, Sendable {
    /// Unique identifier for this configuration
    /// Auto-generated when config is created
    var id: UUID = UUID()
    
    /// Configuration for the bot being tested
    var targetBot: BotConfig
    
    /// Array of test scenarios to execute
    var scenarios: [Scenario]
    
    /// Validation rules and settings
    var validation: ValidationConfig
    
    /// Timing and delay settings for realistic testing
    var timing: TimingConfig
    
    /// Report generation settings
    var reporting: ReportConfig
}

/// Configuration for a chatbot to be tested
/// Specifies connection details, authentication, and optional provider-specific settings
struct BotConfig: Codable, Sendable {
    /// Display name for the bot
    var name: String
    
    /// Communication protocol (HTTP or WebSocket)
    var botProtocol: BotProtocol
    
    /// URL endpoint for the bot API
    var endpoint: String
    
    /// Optional authentication configuration
    var authentication: AuthConfig?
    
    /// Optional custom HTTP headers
    var headers: [String: String]?
    
    /// Optional provider type (for provider-specific handling)
    var provider: BotProvider?
    
    /// Optional model name (e.g., "gpt-4", "claude-3-opus")
    var model: String?
    
    /// Custom coding keys to handle "protocol" keyword
    /// Swift reserves "protocol" so we map it to "botProtocol"
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

/// Communication protocol for bot connection
/// Determines how messages are sent and received
enum BotProtocol: String, Codable, CaseIterable, Sendable {
    case http = "http"              // Standard HTTP POST requests
    case websocket = "websocket"    // WebSocket for real-time bidirectional communication
}

/// Supported bot providers
/// Used for provider-specific handling and features
enum BotProvider: String, Codable, CaseIterable, Sendable {
    case ollama = "ollama"          // Local Ollama models
    case generic = "generic"        // Generic/custom endpoints
    case openai = "openai"          // OpenAI API (GPT models)
    case anthropic = "anthropic"    // Anthropic API (Claude models)
}

/// Authentication configuration for bot API
/// Stores credentials and authentication type
struct AuthConfig: Codable, Sendable {
    /// Type of authentication to use
    var type: AuthType
    
    /// Credentials (API key, token, or base64 encoded username:password)
    var credentials: String
}

/// Supported authentication types
/// Determines how credentials are sent in requests
enum AuthType: String, Codable, CaseIterable, Sendable {
    case bearer = "bearer"      // Bearer token in Authorization header
    case basic = "basic"        // Basic auth (base64 encoded username:password)
    case apikey = "apikey"      // API key in X-API-Key header
}

/// Configuration for response validation
/// Defines how bot responses should be validated
struct ValidationConfig: Codable, Sendable {
    /// Default validation type to use if not specified per-step
    var defaultType: ValidationType
    
    /// Threshold for semantic similarity validation (0.0-1.0)
    /// Higher values require closer semantic match
    var semanticSimilarityThreshold: Double?
    
    /// Map of custom validator names to their configurations
    var customValidators: [String: String]?
}

/// Types of validation that can be performed on bot responses
enum ValidationType: String, Codable, CaseIterable, Sendable {
    case exact = "exact"        // Exact string match (case-insensitive)
    case pattern = "pattern"    // Regex pattern matching
    case semantic = "semantic"  // Semantic similarity using NaturalLanguage framework
    case custom = "custom"      // Custom validator by name
}

/// Configuration for timing and delays during test execution
/// Simulates realistic user behavior with typing delays
struct TimingConfig: Codable, Sendable {
    /// Whether to enable delays between messages
    var enableDelays: Bool
    
    /// Base delay before sending each message (milliseconds)
    var baseDelay: Int
    
    /// Additional delay per character in message (milliseconds)
    /// Simulates typing speed
    var delayPerCharacter: Int
    
    /// If true, sends messages as fast as possible (ignores delays)
    var rapidFire: Bool
    
    /// Maximum time to wait for bot response (milliseconds)
    var responseTimeout: Int
}

/// Configuration for report generation
/// Defines output format and content
struct ReportConfig: Codable, Sendable {
    /// Directory path where reports should be saved
    var outputPath: String
    
    /// List of report formats to generate
    var formats: [ReportFormat]
    
    /// Whether to include full conversation history in reports
    var includeConversationHistory: Bool
    
    /// Whether to include detailed error messages in reports
    var verboseErrors: Bool
}

/// Supported report output formats
enum ReportFormat: String, Codable, CaseIterable, Sendable {
    case json = "json"          // JSON format for programmatic access
    case html = "html"          // HTML format for web viewing
    case markdown = "markdown"  // Markdown format for documentation
}

// MARK: - Scenario Types

/// A test scenario containing a sequence of conversation steps
/// Represents a complete test case with expected outcomes
struct Scenario: Codable, Identifiable, Sendable {
    /// Unique identifier for this scenario
    let id: String
    
    /// Display name for the scenario
    var name: String
    
    /// Optional description explaining what this scenario tests
    var description: String?
    
    /// Ordered list of conversation steps to execute
    var steps: [ConversationStep]
    
    /// Expected outcomes to validate after all steps complete
    var expectedOutcomes: [ValidationCriteria]
}

/// A single step in a conversation scenario
/// Represents one message sent to the bot and its expected response
struct ConversationStep: Codable, Identifiable, Sendable {
    /// Unique identifier for this step
    var id: UUID = UUID()
    
    /// Message to send to the bot
    var message: String
    
    /// Optional criteria for validating the bot's response
    var expectedResponse: ResponseCriteria?
    
    /// Optional custom delay before sending this message (milliseconds)
    /// Overrides timing config if specified
    var delay: Int?
}

/// Criteria for validating a bot's response to a single message
/// Defines what kind of response is expected
struct ResponseCriteria: Codable, Sendable {
    /// Type of validation to perform
    var validationType: ValidationType
    
    /// Expected value (exact string, regex pattern, or semantic meaning)
    var expected: String
    
    /// Optional threshold for fuzzy matching (0.0-1.0)
    /// Used for semantic and pattern matching
    var threshold: Double?
}

/// Criteria for validating overall scenario outcomes
/// Used to check conversation-level expectations
struct ValidationCriteria: Codable, Identifiable, Sendable {
    /// Unique identifier for this criteria
    var id: UUID = UUID()
    
    /// Type of validation to perform
    var type: ValidationType
    
    /// Expected value to validate against
    var expected: String
    
    /// Optional threshold for fuzzy matching (0.0-1.0)
    var threshold: Double?
    
    /// Optional human-readable description of this validation
    var description: String?
}

// MARK: - Response Types

/// Response received from a bot
/// Contains the bot's message and metadata about the response
struct BotResponse: Codable, Sendable {
    /// The bot's response text
    let content: String
    
    /// When the response was received
    let timestamp: Date
    
    /// Optional metadata from the bot (custom headers, etc.)
    let metadata: [String: String]?
    
    /// Error message if the request failed
    let error: String?
    
    /// Time taken to receive response (seconds)
    let responseTime: Double?
}

/// Result of validating a bot response
/// Indicates whether validation passed and provides details
struct ValidationResult: Codable, Identifiable, Sendable {
    /// Unique identifier for this result
    var id: UUID = UUID()
    
    /// Whether the validation passed
    let passed: Bool
    
    /// What was expected (for reference)
    let expected: String?
    
    /// What was actually received
    var actual: String
    
    /// Human-readable message explaining the result
    let message: String?
    
    /// Additional details about the validation (e.g., similarity score)
    let details: [String: String]?
}

// MARK: - Conversation Types

/// Complete history of a conversation session
/// Contains all messages exchanged between user/tester and bot
struct ConversationHistory: Codable, Identifiable, Sendable {
    /// Unique identifier for this conversation
    var id: UUID = UUID()
    
    /// Session ID for grouping related conversations
    let sessionId: String
    
    /// All messages in chronological order
    var messages: [ConversationMessage]
    
    /// When the conversation started
    let startTime: Date
    
    /// When the conversation ended (nil if still ongoing)
    var endTime: Date?
}

/// A single message in a conversation
/// Can be from the tester, target bot, or adversarial bot
struct ConversationMessage: Codable, Identifiable, Sendable {
    /// Unique identifier for this message
    var id: UUID = UUID()
    
    /// Who sent this message
    let sender: MessageSender
    
    /// The message content
    var content: String
    
    /// When the message was sent
    let timestamp: Date
    
    /// Optional validation result if this message was validated
    var validationResult: ValidationResult?
}

/// Identifies who sent a message in a conversation
enum MessageSender: String, Codable, Sendable {
    case patience = "patience"          // Message from Patience (the tester)
    case target = "target"              // Message from the bot being tested
    case adversarial = "adversarial"    // Message from the adversarial AI bot
}

// MARK: - Test Results

/// Complete results from a test run
/// Contains results for all scenarios and overall summary
struct TestResults: Codable, Identifiable, Sendable {
    /// Unique identifier for these results
    var id: UUID = UUID()
    
    /// Unique ID for this test run
    let testRunId: String
    
    /// When the test run started
    let startTime: Date
    
    /// When the test run ended (nil if still running)
    var endTime: Date?
    
    /// Results for each scenario that was executed
    var scenarioResults: [ScenarioResult]
    
    /// Summary statistics for the entire test run
    var summary: TestSummary
}

/// Results from executing a single scenario
/// Contains conversation history, validation results, and outcome
struct ScenarioResult: Codable, Identifiable, Sendable {
    /// Unique identifier for this result
    var id: UUID = UUID()
    
    /// ID of the scenario that was executed
    let scenarioId: String
    
    /// Name of the scenario for display
    let scenarioName: String
    
    /// Whether the scenario passed all validations
    var passed: Bool
    
    /// Complete conversation history for this scenario
    var conversationHistory: ConversationHistory
    
    /// All validation results from this scenario
    var validationResults: [ValidationResult]
    
    /// How long the scenario took to execute (seconds)
    var duration: Double
    
    /// Error message if scenario failed to execute
    var error: String?
}

/// Summary statistics for a test run
/// Provides high-level pass/fail counts and rates
struct TestSummary: Codable, Sendable {
    /// Total number of scenarios executed
    var total: Int
    
    /// Number of scenarios that passed
    var passed: Int
    
    /// Number of scenarios that failed
    var failed: Int
    
    /// Calculated pass rate (0.0-1.0)
    /// Returns 0 if no scenarios were run
    var passRate: Double {
        guard total > 0 else { return 0 }
        return Double(passed) / Double(total)
    }
}

// MARK: - Report Types

/// Generated report from test results
/// Can be exported in multiple formats (JSON, HTML, Markdown)
struct TestReport: Codable, Identifiable, Sendable {
    /// Unique identifier for this report
    var id: UUID = UUID()
    
    /// When the report was generated
    let timestamp: Date
    
    /// Total number of scenarios in the report
    let totalScenarios: Int
    
    /// Number of scenarios that passed
    let passedScenarios: Int
    
    /// Number of scenarios that failed
    let failedScenarios: Int
    
    /// Detailed results for each scenario
    var scenarioResults: [ScenarioResult]
    
    /// Human-readable summary text
    let summary: String
}

// MARK: - Adversarial Types

/// Complete configuration for an adversarial test
/// Uses AI to automatically generate challenging conversations with the target bot
struct AdversarialTestConfig: Codable, Identifiable, Sendable {
    /// Unique identifier for this configuration
    var id: UUID = UUID()
    
    /// Configuration for the bot being tested
    var targetBot: AdversarialBotConfig
    
    /// Settings for the AI bot that generates test conversations
    var adversarialBot: AdversarialBotSettings
    
    /// Conversation strategy and parameters
    var conversation: ConversationSettings
    
    /// Optional validation rules to apply during testing
    var validation: AdversarialValidationConfig?
    
    /// Execution settings (number of conversations, parallelism, etc.)
    var execution: ExecutionSettings
    
    /// Optional safety limits (cost, rate limiting)
    var safety: SafetySettings?
    
    /// Report generation settings
    var reporting: AdversarialReportConfig
}

/// Configuration for the target bot in adversarial testing
/// Similar to BotConfig but specific to adversarial testing context
struct AdversarialBotConfig: Codable, Sendable {
    /// Display name for the target bot
    var name: String
    
    /// Communication protocol
    var botProtocol: BotProtocol
    
    /// URL endpoint for the bot API
    var endpoint: String
    
    /// Optional authentication
    var authentication: AuthConfig?
    
    /// Optional custom headers
    var headers: [String: String]?
    
    /// Custom coding keys to handle "protocol" keyword
    private enum CodingKeys: String, CodingKey {
        case name
        case botProtocol = "protocol"
        case endpoint
        case authentication
        case headers
    }
}

/// Settings for the adversarial AI bot
/// Configures which AI provider to use and its parameters
struct AdversarialBotSettings: Codable, Sendable {
    /// AI provider (OpenAI, Anthropic, Ollama, etc.)
    var provider: BotProvider
    
    /// Model name (e.g., "gpt-4", "claude-3-opus")
    var model: String?
    
    /// API key for the provider (stored in Keychain, not persisted here)
    var apiKey: String?
    
    /// Optional custom endpoint (for self-hosted models)
    var endpoint: String?
    
    /// Temperature for response generation (0.0-2.0)
    /// Higher values = more creative/random responses
    var temperature: Double?
    
    /// Maximum tokens to generate per response
    var maxTokens: Int?
}

/// Settings for conversation behavior
/// Defines strategy, goals, and constraints for the conversation
struct ConversationSettings: Codable, Sendable {
    /// Testing strategy to use (exploratory, adversarial, focused, stress, custom)
    var strategy: ConversationStrategy
    
    /// Maximum number of back-and-forth turns
    var maxTurns: Int
    
    /// Optional initial prompts to start conversations
    var startingPrompts: [String]?
    
    /// Optional custom system prompt for the adversarial bot
    /// Only used with custom strategy
    var systemPrompt: String?
    
    /// Optional testing goals to focus on
    var goals: [String]?
    
    /// Optional timeout for entire conversation (milliseconds)
    var timeout: Int?
}

/// Available conversation strategies for adversarial testing
/// Each strategy uses different tactics to test the bot
enum ConversationStrategy: String, Codable, CaseIterable, Sendable {
    case exploratory = "exploratory"    // Broad exploration of capabilities
    case adversarial = "adversarial"    // Tries to find failures and edge cases
    case focused = "focused"            // Deep dive into specific features
    case stress = "stress"              // Tests under pressure and complexity
    case custom = "custom"              // User-defined strategy
}

/// Validation configuration for adversarial testing
/// Defines rules to apply during conversations
struct AdversarialValidationConfig: Codable, Sendable {
    /// Validation rules to apply to bot responses
    var rules: [ValidationCriteria]
    
    /// Whether to validate in real-time during conversation
    var realTime: Bool
}

/// Execution settings for adversarial tests
/// Controls parallelism and timing
struct ExecutionSettings: Codable, Sendable {
    /// Number of conversations to run
    var numConversations: Int
    
    /// Optional number of conversations to run concurrently
    var concurrent: Int?
    
    /// Optional delay between turns in a conversation (milliseconds)
    var delayBetweenTurns: Int?
    
    /// Optional delay between separate conversations (milliseconds)
    var delayBetweenConversations: Int?
}

/// Safety limits for adversarial testing
/// Prevents runaway costs and rate limit violations
struct SafetySettings: Codable, Sendable {
    /// Maximum cost in USD before stopping
    var maxCostUSD: Double?
    
    /// Maximum API requests per minute
    var maxRequestsPerMinute: Int?
    
    /// Whether to enable content filtering
    var contentFilter: Bool?
}

/// Report configuration for adversarial tests
/// Defines output format and monitoring
struct AdversarialReportConfig: Codable, Sendable {
    /// Directory path for saving reports
    var outputPath: String
    
    /// Report formats to generate
    var formats: [ReportFormat]
    
    /// Whether to include full conversation transcripts
    var includeTranscripts: Bool
    
    /// Whether to show real-time progress during execution
    var realTimeMonitoring: Bool
}

// MARK: - Analysis Types

/// Configuration for log analysis
/// Defines which logs to analyze and what analysis to perform
struct AnalysisConfig: Codable, Identifiable, Sendable {
    /// Unique identifier for this configuration
    var id: UUID = UUID()
    
    /// Source log file to analyze
    var logSource: LogSource
    
    /// Optional filters to apply before analysis
    var filters: AnalysisFilters?
    
    /// Optional validation rules to apply to conversations
    var validation: ValidationConfig?
    
    /// Which types of analysis to perform
    var analysis: AnalysisSettings
    
    /// Report generation settings
    var reporting: ReportConfig
}

/// Source of log data for analysis
/// Specifies file path and format
struct LogSource: Codable, Sendable {
    /// Path to the log file
    var path: String
    
    /// Format of the log file
    var format: LogFormat
}

/// Supported log file formats
enum LogFormat: String, Codable, CaseIterable, Sendable {
    case json = "json"      // JSON format with structured data
    case csv = "csv"        // CSV format with columns
    case text = "text"      // Plain text with patterns
    case auto = "auto"      // Auto-detect format
}

/// Filters to apply before analyzing logs
/// Reduces data to relevant subset
struct AnalysisFilters: Codable, Sendable {
    /// Optional date range to filter by
    var dateRange: DateRange?
    
    /// Optional minimum number of messages per conversation
    var minMessages: Int?
}

/// Date range for filtering
struct DateRange: Codable, Sendable {
    /// Start date (inclusive)
    let start: Date
    
    /// End date (inclusive)
    let end: Date
}

/// Settings for what analysis to perform
/// Each can be enabled/disabled independently
struct AnalysisSettings: Codable, Sendable {
    /// Whether to calculate conversation metrics
    var calculateMetrics: Bool
    
    /// Whether to detect failure patterns
    var detectPatterns: Bool
    
    /// Whether to analyze context retention
    var checkContextRetention: Bool
}

/// Complete results from log analysis
/// Contains all requested analysis outputs
struct AnalysisResults: Codable, Identifiable, Sendable {
    /// Unique identifier for these results
    var id: UUID = UUID()
    
    /// High-level summary of analysis
    let summary: AnalysisSummary
    
    /// Optional conversation metrics
    let metrics: AnalysisMetrics?
    
    /// Optional detected patterns
    let patterns: [DetectedPattern]?
    
    /// Optional validation results
    let validationResults: [ValidationResult]?
    
    /// Optional context retention analysis
    let contextAnalysis: ContextRetentionAnalysis?
}

/// Analysis of how well the bot maintains conversation context
/// Measures ability to reference previous messages and maintain topic
struct ContextRetentionAnalysis: Codable, Sendable {
    /// Average context retention score (0.0-1.0)
    let averageContextScore: Double
    
    /// Number of conversations analyzed
    let conversationsAnalyzed: Int
    
    /// Number of times topic switched
    let topicSwitches: Int
    
    /// Average distance between references (in messages)
    let averageReferenceDistance: Double
    
    /// Number of times context was lost
    let contextBreaks: Int
}

/// High-level summary of analysis results
struct AnalysisSummary: Codable, Sendable {
    /// Total conversations in the log
    let totalConversations: Int
    
    /// Number of conversations that were analyzed
    let analyzedConversations: Int
    
    /// Overall validation pass rate (0.0-1.0)
    let overallPassRate: Double
    
    /// Time taken to process analysis (seconds)
    let processingTime: Double
}

/// Metrics calculated from conversations
struct AnalysisMetrics: Codable, Sendable {
    /// Total number of messages across all conversations
    let totalMessages: Int
    
    /// Average messages per conversation
    let averageMessagesPerConversation: Double
    
    /// Optional average response time (seconds)
    let averageResponseTime: Double?
}

/// A detected pattern in the logs
/// Represents a recurring issue or behavior
struct DetectedPattern: Codable, Identifiable, Sendable {
    /// Unique identifier for this pattern
    var id: UUID = UUID()
    
    /// Type of pattern (e.g., "error", "timeout", "validation_failure")
    let type: String
    
    /// The pattern itself (error message, behavior description)
    let pattern: String
    
    /// How many times this pattern occurred
    let frequency: Int
    
    /// Confidence in this pattern (0.0-1.0)
    let confidence: Double
}

// MARK: - Adversarial Test Results

/// Complete results from an adversarial test run
/// Contains all conversations and summary statistics
struct AdversarialTestResults: Codable, Identifiable, Sendable {
    /// Unique identifier for these results
    var id: UUID = UUID()
    
    /// ID of the configuration that was used
    let configId: UUID
    
    /// Name of the configuration for display
    let configName: String
    
    /// When the test was run
    let timestamp: Date
    
    /// Results from each conversation
    let conversations: [ConversationResult]
    
    /// Summary statistics across all conversations
    let summary: AdversarialTestSummary
}

/// Summary statistics for an adversarial test run
/// Aggregates metrics across all conversations
struct AdversarialTestSummary: Codable, Sendable {
    /// Total number of conversations executed
    let totalConversations: Int
    
    /// Total number of turns across all conversations
    let totalTurns: Int
    
    /// Average validation pass rate (0.0-1.0)
    let averagePassRate: Double
    
    /// Average conversation duration (milliseconds)
    let averageDuration: Double
}

/// Results from a single adversarial conversation
/// Contains the full conversation and its outcomes
struct ConversationResult: Codable, Identifiable, Sendable {
    /// Unique identifier for this conversation
    var id: UUID = UUID()
    
    /// String ID for this conversation
    let conversationId: String
    
    /// When the conversation started
    let timestamp: Date
    
    /// All messages in the conversation
    let messages: [AdversarialMessage]
    
    /// Number of back-and-forth turns
    let turns: Int
    
    /// How long the conversation took (milliseconds)
    let duration: Double
    
    /// Validation results for bot responses
    let validationResults: [ValidationResult]
    
    /// Percentage of validations that passed (0.0-1.0)
    let passRate: Double
    
    /// Calculated metrics for this conversation
    let metrics: ConversationMetrics
    
    /// Why the conversation ended
    let terminationReason: TerminationReason
    
    /// Optional message explaining termination
    let terminationMessage: String?
}

/// A single message in an adversarial conversation
/// Can be from the adversarial AI or the target bot
struct AdversarialMessage: Codable, Identifiable, Sendable {
    /// Unique identifier for this message
    var id: UUID = UUID()
    
    /// Who sent this message (adversarial AI or target bot)
    let role: MessageRole
    
    /// The message content
    let content: String
    
    /// When the message was sent
    let timestamp: Date
    
    /// Optional metadata (response time, token count, etc.)
    let metadata: [String: String]?
}

/// Role of the sender in an adversarial conversation
enum MessageRole: String, Codable, Sendable {
    case adversarial = "adversarial"    // Message from the adversarial AI bot
    case target = "target"              // Message from the target bot being tested
}

/// Metrics calculated for a conversation
/// Provides quantitative measures of conversation quality
struct ConversationMetrics: Codable, Sendable {
    /// Average response time from target bot (seconds)
    let avgResponseTime: Double
    
    /// Percentage of turns where target bot responded (0.0-1.0)
    let targetBotResponseRate: Double
    
    /// Overall conversation quality score (0.0-1.0)
    /// Based on validation pass rate and response quality
    let conversationQuality: Double
}

/// Reason why a conversation ended
/// Helps understand test outcomes
enum TerminationReason: String, Codable, Sendable {
    case max_turns = "max_turns"                    // Reached maximum turn limit
    case goal_achieved = "goal_achieved"            // Strategy's goal was achieved
    case timeout = "timeout"                        // Conversation timed out
    case error = "error"                            // Error occurred
    case manual = "manual"                          // Manually stopped by user
    case adversarial_ended = "adversarial_ended"    // Adversarial bot decided to end
}

