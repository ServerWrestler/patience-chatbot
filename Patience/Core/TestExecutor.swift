/// This file handles live test execution against target chatbots
/// Contains three main classes:
/// - TestExecutor: Orchestrates test execution and scenario management
/// - CommunicationManager: Handles HTTP and WebSocket communication with bots
/// - ResponseValidator: Validates bot responses using various strategies

import Foundation
import NaturalLanguage

/// Executes test scenarios against target chatbots
/// Manages the complete test lifecycle: connection, execution, validation, and result collection
/// Runs scenarios sequentially and reports progress via callback
class TestExecutor {
    /// Manages communication with the target bot
    /// Handles both HTTP and WebSocket protocols
    private let communicationManager = CommunicationManager()
    
    /// Validates bot responses against expected criteria
    /// Supports exact, pattern, semantic, and custom validation
    private let validator = ResponseValidator()
    
    /// Executes all scenarios in a test configuration
    /// Runs scenarios sequentially, collecting results for each
    /// Reports progress after each scenario via callback
    /// 
    /// - Parameters:
    ///   - config: Test configuration with scenarios and validation rules
    ///   - progressCallback: Async callback for progress updates (0.0-1.0) and status messages
    /// - Returns: TestResults containing all scenario results and summary statistics
    /// - Throws: TestError if connection fails or critical error occurs
    /// 
    /// Side effects:
    /// - Makes network requests to target bot
    /// - Calls progressCallback multiple times during execution
    /// - May take several minutes depending on number of scenarios
    func executeTests(
        config: TestConfig,
        progressCallback: @escaping (Double, String) async -> Void
    ) async throws -> TestResults {
        
        // Generate unique ID for this test run
        let testRunId = UUID().uuidString
        let startTime = Date()
        var scenarioResults: [ScenarioResult] = []
        
        await progressCallback(0.0, "Starting test execution...")
        
        // Execute each scenario sequentially
        for (index, scenario) in config.scenarios.enumerated() {
            // Calculate progress as percentage of scenarios completed
            let progress = Double(index) / Double(config.scenarios.count)
            await progressCallback(progress, "Running scenario: \(scenario.name)")
            
            do {
                let result = try await executeScenario(scenario, config: config)
                scenarioResults.append(result)
            } catch {
                // If scenario fails, create a failed result with error message
                let failedResult = ScenarioResult(
                    scenarioId: scenario.id,
                    scenarioName: scenario.name,
                    passed: false,
                    conversationHistory: ConversationHistory(
                        sessionId: UUID().uuidString,
                        messages: [],
                        startTime: Date()
                    ),
                    validationResults: [],
                    duration: 0,
                    error: error.localizedDescription
                )
                scenarioResults.append(failedResult)
            }
        }
        
        await progressCallback(1.0, "Test execution completed")
        
        // Calculate summary statistics
        let summary = TestSummary(
            total: scenarioResults.count,
            passed: scenarioResults.filter { $0.passed }.count,
            failed: scenarioResults.filter { !$0.passed }.count
        )
        
        return TestResults(
            testRunId: testRunId,
            startTime: startTime,
            endTime: Date(),
            scenarioResults: scenarioResults,
            summary: summary
        )
    }
    
    /// Executes a single test scenario
    /// Sends each message in the scenario, validates responses, and collects results
    /// 
    /// - Parameters:
    ///   - scenario: The scenario to execute
    ///   - config: Test configuration with bot endpoint and validation rules
    /// - Returns: ScenarioResult with conversation history and validation results
    /// - Throws: TestError if connection fails or timeout occurs
    /// 
    /// Side effects:
    /// - Connects to target bot
    /// - Sends multiple messages over network
    /// - Applies timing delays between messages
    /// - Disconnects from bot when complete (via defer)
    private func executeScenario(_ scenario: Scenario, config: TestConfig) async throws -> ScenarioResult {
        let sessionId = UUID().uuidString
        let startTime = Date()
        var messages: [ConversationMessage] = []
        var validationResults: [ValidationResult] = []
        
        // Connect to target bot
        try await communicationManager.connect(to: config.targetBot)
        
        // defer ensures disconnect happens even if function exits early (error or return)
        defer {
            Task {
                await communicationManager.disconnect()
            }
        }
        
        // Execute each conversation step in order
        for step in scenario.steps {
            // Record the message we're sending
            let userMessage = ConversationMessage(
                sender: .patience,
                content: step.message,
                timestamp: Date()
            )
            messages.append(userMessage)
            
            // Apply timing delays to simulate realistic user behavior
            if config.timing.enableDelays {
                let delay = calculateDelay(for: step.message, config: config.timing)
                // Convert milliseconds to nanoseconds for Task.sleep
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000))
            }
            
            // Send message and wait for bot response
            let response = try await communicationManager.sendMessage(step.message)
            
            // Record the bot's response
            let botMessage = ConversationMessage(
                sender: .target,
                content: response.content,
                timestamp: response.timestamp
            )
            messages.append(botMessage)
            
            // Validate response if this step has expected response criteria
            if let expectedResponse = step.expectedResponse {
                let validation = validator.validate(
                    response: response,
                    criteria: expectedResponse,
                    config: config.validation
                )
                validationResults.append(validation)
            }
        }
        
        // After all steps complete, validate overall scenario outcomes
        // These check the entire conversation, not just individual responses
        for outcome in scenario.expectedOutcomes {
            let validation = validator.validateOutcome(
                messages: messages,
                criteria: outcome,
                config: config.validation
            )
            validationResults.append(validation)
        }
        
        // Package conversation history
        let conversationHistory = ConversationHistory(
            sessionId: sessionId,
            messages: messages,
            startTime: startTime,
            endTime: Date()
        )
        
        // Scenario passes only if ALL validations pass
        let passed = validationResults.allSatisfy { $0.passed }
        let duration = Date().timeIntervalSince(startTime)
        
        return ScenarioResult(
            scenarioId: scenario.id,
            scenarioName: scenario.name,
            passed: passed,
            conversationHistory: conversationHistory,
            validationResults: validationResults,
            duration: duration,
            error: nil
        )
    }
    
    /// Calculates delay before sending a message
    /// Simulates realistic typing speed based on message length
    /// 
    /// - Parameters:
    ///   - message: The message to send
    ///   - config: Timing configuration
    /// - Returns: Delay in milliseconds
    private func calculateDelay(for message: String, config: TimingConfig) -> Int {
        // Rapid fire mode: no delay
        if config.rapidFire {
            return 0
        }
        
        // Base delay + per-character delay (simulates typing)
        return config.baseDelay + (message.count * config.delayPerCharacter)
    }
}

/// Manages communication with target bots
/// Supports both HTTP and WebSocket protocols
/// Handles connection lifecycle and message sending
class CommunicationManager {
    /// Currently connected bot configuration
    /// nil if not connected
    private var currentBot: BotConfig?
    
    /// Connects to a target bot
    /// Initializes connection based on protocol type (HTTP or WebSocket)
    /// 
    /// - Parameter bot: Bot configuration with endpoint and protocol
    /// - Throws: TestError if connection fails
    func connect(to bot: BotConfig) async throws {
        currentBot = bot
        // Store bot config for later use
        // Actual connection happens on first message send
        switch bot.botProtocol {
        case .http:
            // HTTP is stateless - no persistent connection needed
            break
        case .websocket:
            // WebSocket connection established per message (see sendWebSocketMessage)
            break
        }
    }
    
    /// Sends a message to the connected bot
    /// Routes to appropriate protocol handler (HTTP or WebSocket)
    /// 
    /// - Parameter message: The message to send
    /// - Returns: BotResponse containing the bot's reply and metadata
    /// - Throws: TestError.notConnected if not connected, or network errors
    func sendMessage(_ message: String) async throws -> BotResponse {
        guard let bot = currentBot else {
            throw TestError.notConnected
        }
        
        // Route to appropriate protocol handler
        switch bot.botProtocol {
        case .http:
            return try await sendHTTPMessage(message, to: bot)
        case .websocket:
            return try await sendWebSocketMessage(message, to: bot)
        }
    }
    
    /// Disconnects from the current bot
    /// Cleans up any persistent connections
    func disconnect() async {
        currentBot = nil
        // Clean up any persistent connections
        // HTTP is stateless, WebSocket connections are per-message
    }
    
    /// Sends a message via HTTP POST request
    /// Constructs JSON request, adds authentication, and parses response
    /// 
    /// - Parameters:
    ///   - message: The message to send
    ///   - bot: Bot configuration with endpoint and auth
    /// - Returns: BotResponse with content and timing
    /// - Throws: TestError if URL invalid, HTTP error, or parsing fails
    private func sendHTTPMessage(_ message: String, to bot: BotConfig) async throws -> BotResponse {
        // Validate endpoint URL
        guard let url = URL(string: bot.endpoint) else {
            throw TestError.invalidEndpoint
        }
        
        // Create HTTP POST request
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add authentication based on type
        if let auth = bot.authentication {
            switch auth.type {
            case .bearer:
                // Bearer token authentication (most common for APIs)
                request.setValue("Bearer \(auth.credentials)", forHTTPHeaderField: "Authorization")
            case .basic:
                // Basic authentication (base64 encoded username:password)
                let encoded = Data(auth.credentials.utf8).base64EncodedString()
                request.setValue("Basic \(encoded)", forHTTPHeaderField: "Authorization")
            case .apikey:
                // API key in custom header
                request.setValue(auth.credentials, forHTTPHeaderField: "X-API-Key")
            }
        }
        
        // Add any custom headers from config
        bot.headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // Create JSON request body
        let requestBody = ["message": message]
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        // Send request and measure response time
        let startTime = Date()
        let (data, response) = try await URLSession.shared.data(for: request)
        let responseTime = Date().timeIntervalSince(startTime)
        
        // Check for HTTP errors
        guard let httpResponse = response as? HTTPURLResponse,
              200...299 ~= httpResponse.statusCode else {
            throw TestError.httpError(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0)
        }
        
        // Parse JSON response
        // Expects {"response": "bot message"} format
        // Falls back to raw data if JSON parsing fails
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let content = json?["response"] as? String ?? String(data: data, encoding: .utf8) ?? ""
        
        return BotResponse(
            content: content,
            timestamp: Date(),
            metadata: nil,
            error: nil,
            responseTime: responseTime
        )
    }
    
    /// Sends a message via WebSocket connection
    /// Creates ephemeral connection for each message
    /// 
    /// - Parameters:
    ///   - message: The message to send
    ///   - bot: Bot configuration with endpoint
    /// - Returns: BotResponse with content and timing
    /// - Throws: TestError if URL invalid or WebSocket error
    private func sendWebSocketMessage(_ message: String, to bot: BotConfig) async throws -> BotResponse {
        // Validate endpoint URL
        guard let url = URL(string: bot.endpoint) else {
            throw TestError.invalidEndpoint
        }
        
        // Create WebSocket connection
        let webSocketTask = URLSession.shared.webSocketTask(with: url)
        webSocketTask.resume()
        
        // Send message as string
        let wsMessage = URLSessionWebSocketTask.Message.string(message)
        try await webSocketTask.send(wsMessage)
        
        // Measure response time
        let startTime = Date()
        
        // Wait for response
        let response = try await webSocketTask.receive()
        let responseTime = Date().timeIntervalSince(startTime)
        
        // Extract content from response (can be string or binary data)
        let content: String
        switch response {
        case .string(let text):
            content = text
        case .data(let data):
            // Convert binary data to string
            content = String(data: data, encoding: .utf8) ?? ""
        @unknown default:
            // Handle future WebSocket message types
            content = ""
        }
        
        // Close WebSocket connection
        webSocketTask.cancel(with: .goingAway, reason: nil)
        
        return BotResponse(
            content: content,
            timestamp: Date(),
            metadata: nil,
            error: nil,
            responseTime: responseTime
        )
    }
}

/// Validates bot responses using various strategies
/// Supports exact matching, regex patterns, semantic similarity, and custom validators
class ResponseValidator {
    /// Validates a bot response against criteria
    /// Routes to appropriate validation method based on type
    /// 
    /// - Parameters:
    ///   - response: The bot's response to validate
    ///   - criteria: Expected response criteria
    ///   - config: Validation configuration with thresholds
    /// - Returns: ValidationResult indicating pass/fail and details
    func validate(response: BotResponse, criteria: ResponseCriteria, config: ValidationConfig) -> ValidationResult {
        // Route to appropriate validation method
        switch criteria.validationType {
        case .exact:
            return validateExact(response: response, expected: criteria.expected)
        case .pattern:
            return validatePattern(response: response, pattern: criteria.expected)
        case .semantic:
            // Use threshold from criteria, or config, or default to 0.8
            return validateSemantic(response: response, expected: criteria.expected, threshold: criteria.threshold ?? config.semanticSimilarityThreshold ?? 0.8)
        case .custom:
            return validateCustom(response: response, validator: criteria.expected)
        }
    }
    
    /// Validates overall conversation outcome
    /// Checks if expected text/pattern appears anywhere in the conversation
    /// 
    /// - Parameters:
    ///   - messages: All messages in the conversation
    ///   - criteria: Expected outcome criteria
    ///   - config: Validation configuration
    /// - Returns: ValidationResult for the outcome
    func validateOutcome(messages: [ConversationMessage], criteria: ValidationCriteria, config: ValidationConfig) -> ValidationResult {
        // Combine all messages into single text for validation
        let conversationText = messages.map { $0.content }.joined(separator: " ")
        
        // Route to appropriate validation method
        switch criteria.type {
        case .exact:
            return validateExactInText(text: conversationText, expected: criteria.expected)
        case .pattern:
            return validatePatternInText(text: conversationText, pattern: criteria.expected)
        case .semantic:
            return validateSemanticInText(text: conversationText, expected: criteria.expected, threshold: criteria.threshold ?? 0.8)
        case .custom:
            return validateCustomInText(text: conversationText, validator: criteria.expected)
        }
    }
    
    private func validateExactInText(text: String, expected: String) -> ValidationResult {
        let passed = text.lowercased().contains(expected.lowercased())
        
        return ValidationResult(
            passed: passed,
            expected: expected,
            actual: text,
            message: passed ? "Expected text found in conversation" : "Expected text not found in conversation",
            details: nil
        )
    }
    
    private func validateCustomInText(text: String, validator: String) -> ValidationResult {
        // Create a mock response for custom validation
        let mockResponse = BotResponse(
            content: text,
            timestamp: Date(),
            metadata: nil,
            error: nil,
            responseTime: nil
        )
        return CustomValidators.validate(response: mockResponse, validatorName: validator)
    }
    
    /// Validates exact string match (case-insensitive, whitespace-trimmed)
    /// - Parameters:
    ///   - response: Bot response to validate
    ///   - expected: Expected exact text
    /// - Returns: ValidationResult with pass/fail
    private func validateExact(response: BotResponse, expected: String) -> ValidationResult {
        // Trim whitespace and compare (case-sensitive after trim)
        let passed = response.content.trimmingCharacters(in: .whitespacesAndNewlines) == expected.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return ValidationResult(
            passed: passed,
            expected: expected,
            actual: response.content,
            message: passed ? "Exact match successful" : "Content does not match exactly",
            details: nil
        )
    }
    
    /// Validates response against regex pattern
    /// - Parameters:
    ///   - response: Bot response to validate
    ///   - pattern: Regex pattern to match
    /// - Returns: ValidationResult with match count in details
    private func validatePattern(response: BotResponse, pattern: String) -> ValidationResult {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
            let range = NSRange(location: 0, length: response.content.utf16.count)
            let matches = regex.matches(in: response.content, options: [], range: range)
            
            let passed = !matches.isEmpty
            
            return ValidationResult(
                passed: passed,
                expected: pattern,
                actual: response.content,
                message: passed ? "Pattern match successful" : "No pattern matches found",
                details: ["matches": String(matches.count)]
            )
        } catch {
            return ValidationResult(
                passed: false,
                expected: pattern,
                actual: response.content,
                message: "Invalid regex pattern: \(error.localizedDescription)",
                details: nil
            )
        }
    }
    
    /// Validates semantic similarity using NaturalLanguage framework
    /// Checks if response has similar meaning to expected text
    /// - Parameters:
    ///   - response: Bot response to validate
    ///   - expected: Expected semantic meaning
    ///   - threshold: Minimum similarity score (0.0-1.0)
    /// - Returns: ValidationResult with similarity score in details
    private func validateSemantic(response: BotResponse, expected: String, threshold: Double) -> ValidationResult {
        // Calculate semantic similarity using NaturalLanguage framework
        let similarity = calculateSemanticSimilarity(response.content, expected)
        let passed = similarity >= threshold
        
        return ValidationResult(
            passed: passed,
            expected: expected,
            actual: response.content,
            message: passed ? "Semantic similarity above threshold" : "Semantic similarity below threshold",
            details: ["similarity": String(format: "%.3f", similarity), "threshold": String(threshold)]
        )
    }
    
    /// Calculates semantic similarity between two texts
    /// Uses NaturalLanguage word embeddings for vector comparison
    /// Falls back to simple word overlap if embeddings unavailable
    /// - Parameters:
    ///   - text1: First text
    ///   - text2: Second text
    /// - Returns: Similarity score (0.0-1.0)
    private func calculateSemanticSimilarity(_ text1: String, _ text2: String) -> Double {
        // Try to use NaturalLanguage framework for semantic analysis
        let embedding = NLEmbedding.wordEmbedding(for: .english)
        
        // Get word embedding vectors for both texts
        guard let vector1 = embedding?.vector(for: text1.lowercased()),
              let vector2 = embedding?.vector(for: text2.lowercased()) else {
            // Fallback to simple word overlap if embeddings not available
            return calculateSimpleSimilarity(text1, text2)
        }
        
        // Calculate cosine similarity between vectors
        // Cosine similarity measures angle between vectors (0 = orthogonal, 1 = same direction)
        var dotProduct: Double = 0
        var magnitude1: Double = 0
        var magnitude2: Double = 0
        
        for i in 0..<min(vector1.count, vector2.count) {
            dotProduct += Double(vector1[i]) * Double(vector2[i])
            magnitude1 += Double(vector1[i]) * Double(vector1[i])
            magnitude2 += Double(vector2[i]) * Double(vector2[i])
        }
        
        magnitude1 = sqrt(magnitude1)
        magnitude2 = sqrt(magnitude2)
        
        // Check for zero vectors
        guard magnitude1 > 0 && magnitude2 > 0 else {
            return calculateSimpleSimilarity(text1, text2)
        }
        
        let cosineSimilarity = dotProduct / (magnitude1 * magnitude2)
        
        // Normalize to 0-1 range (cosine similarity ranges from -1 to 1)
        return (cosineSimilarity + 1) / 2
    }
    
    /// Validates using custom validator by name
    /// Delegates to CustomValidators class
    /// - Parameters:
    ///   - response: Bot response to validate
    ///   - validator: Name of custom validator to use
    /// - Returns: ValidationResult from custom validator
    private func validateCustom(response: BotResponse, validator: String) -> ValidationResult {
        // Delegate to CustomValidators class
        let result = CustomValidators.validate(response: response, validatorName: validator)
        return result
    }
    
    private func validatePatternInText(text: String, pattern: String) -> ValidationResult {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
            let range = NSRange(location: 0, length: text.utf16.count)
            let matches = regex.matches(in: text, options: [], range: range)
            
            let passed = !matches.isEmpty
            
            return ValidationResult(
                passed: passed,
                expected: pattern,
                actual: text,
                message: passed ? "Pattern found in conversation" : "Pattern not found in conversation",
                details: ["matches": String(matches.count)]
            )
        } catch {
            return ValidationResult(
                passed: false,
                expected: pattern,
                actual: text,
                message: "Invalid regex pattern: \(error.localizedDescription)",
                details: nil
            )
        }
    }
    
    private func validateSemanticInText(text: String, expected: String, threshold: Double) -> ValidationResult {
        let similarity = calculateSemanticSimilarity(text, expected)
        let passed = similarity >= threshold
        
        return ValidationResult(
            passed: passed,
            expected: expected,
            actual: text,
            message: passed ? "Semantic similarity above threshold" : "Semantic similarity below threshold",
            details: ["similarity": String(format: "%.3f", similarity), "threshold": String(threshold)]
        )
    }
    
    /// Calculates simple word overlap similarity (Jaccard index)
    /// Fallback when NaturalLanguage embeddings unavailable
    /// - Parameters:
    ///   - text1: First text
    ///   - text2: Second text
    /// - Returns: Jaccard similarity (0.0-1.0)
    private func calculateSimpleSimilarity(_ text1: String, _ text2: String) -> Double {
        // Split texts into words, removing punctuation
        let separators = CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters)
        let words1 = Set(text1.lowercased().components(separatedBy: separators).filter { !$0.isEmpty })
        let words2 = Set(text2.lowercased().components(separatedBy: separators).filter { !$0.isEmpty })
        
        // Calculate Jaccard similarity: |intersection| / |union|
        let intersection = words1.intersection(words2)
        let union = words1.union(words2)
        
        guard !union.isEmpty else { return 0.0 }
        
        return Double(intersection.count) / Double(union.count)
    }
    
    // Additional validation methods for conversation-level outcomes
    // These mirror the single-response validators but work on full conversation text
    
    /// Validates exact text appears in conversation
    private func validateExactInText(text: String, expected: String) -> ValidationResult {
        let passed = text.lowercased().contains(expected.lowercased())
        
        return ValidationResult(
            passed: passed,
            expected: expected,
            actual: text,
            message: passed ? "Expected text found in conversation" : "Expected text not found in conversation",
            details: nil
        )
    }
    
    /// Validates pattern appears in conversation
    private func validatePatternInText(text: String, pattern: String) -> ValidationResult {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
            let range = NSRange(location: 0, length: text.utf16.count)
            let matches = regex.matches(in: text, options: [], range: range)
            
            let passed = !matches.isEmpty
            
            return ValidationResult(
                passed: passed,
                expected: pattern,
                actual: text,
                message: passed ? "Pattern found in conversation" : "Pattern not found in conversation",
                details: ["matches": String(matches.count)]
            )
        } catch {
            return ValidationResult(
                passed: false,
                expected: pattern,
                actual: text,
                message: "Invalid regex pattern: \(error.localizedDescription)",
                details: nil
            )
        }
    }
    
    /// Validates semantic similarity of conversation
    private func validateSemanticInText(text: String, expected: String, threshold: Double) -> ValidationResult {
        let similarity = calculateSemanticSimilarity(text, expected)
        let passed = similarity >= threshold
        
        return ValidationResult(
            passed: passed,
            expected: expected,
            actual: text,
            message: passed ? "Semantic similarity above threshold" : "Semantic similarity below threshold",
            details: ["similarity": String(format: "%.3f", similarity), "threshold": String(threshold)]
        )
    }
    
    /// Validates conversation using custom validator
    private func validateCustomInText(text: String, validator: String) -> ValidationResult {
        // Create mock response for custom validation
        let mockResponse = BotResponse(
            content: text,
            timestamp: Date(),
            metadata: nil,
            error: nil,
            responseTime: nil
        )
        return CustomValidators.validate(response: mockResponse, validatorName: validator)
    }
}

/// Errors that can occur during test execution
/// Provides localized error messages for user display
enum TestError: Error, LocalizedError {
    case notConnected                   // Not connected to bot
    case invalidEndpoint                // Invalid URL
    case httpError(statusCode: Int)     // HTTP error with status code
    case notImplemented(String)         // Feature not yet implemented
    case timeout                        // Request timed out
    case validationFailed(String)       // Validation failed with reason
    
    /// Human-readable error description
    var errorDescription: String? {
        switch self {
        case .notConnected:
            return "Not connected to bot"
        case .invalidEndpoint:
            return "Invalid bot endpoint"
        case .httpError(let statusCode):
            return "HTTP error: \(statusCode)"
        case .notImplemented(let feature):
            return "Feature not implemented: \(feature)"
        case .timeout:
            return "Request timeout"
        case .validationFailed(let message):
            return "Validation failed: \(message)"
        }
    }
}

