import Foundation
import NaturalLanguage

class TestExecutor {
    private let communicationManager = CommunicationManager()
    private let validator = ResponseValidator()
    
    func executeTests(
        config: TestConfig,
        progressCallback: @escaping (Double, String) async -> Void
    ) async throws -> TestResults {
        
        let testRunId = UUID().uuidString
        let startTime = Date()
        var scenarioResults: [ScenarioResult] = []
        
        await progressCallback(0.0, "Starting test execution...")
        
        for (index, scenario) in config.scenarios.enumerated() {
            let progress = Double(index) / Double(config.scenarios.count)
            await progressCallback(progress, "Running scenario: \(scenario.name)")
            
            do {
                let result = try await executeScenario(scenario, config: config)
                scenarioResults.append(result)
            } catch {
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
    
    private func executeScenario(_ scenario: Scenario, config: TestConfig) async throws -> ScenarioResult {
        let sessionId = UUID().uuidString
        let startTime = Date()
        var messages: [ConversationMessage] = []
        var validationResults: [ValidationResult] = []
        
        // Initialize communication
        try await communicationManager.connect(to: config.targetBot)
        
        defer {
            Task {
                await communicationManager.disconnect()
            }
        }
        
        // Execute conversation steps
        for step in scenario.steps {
            // Send message
            let userMessage = ConversationMessage(
                sender: .patience,
                content: step.message,
                timestamp: Date()
            )
            messages.append(userMessage)
            
            // Apply timing delays
            if config.timing.enableDelays {
                let delay = calculateDelay(for: step.message, config: config.timing)
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000))
            }
            
            // Get bot response
            let response = try await communicationManager.sendMessage(step.message)
            
            let botMessage = ConversationMessage(
                sender: .target,
                content: response.content,
                timestamp: response.timestamp
            )
            messages.append(botMessage)
            
            // Validate response if criteria provided
            if let expectedResponse = step.expectedResponse {
                let validation = validator.validate(
                    response: response,
                    criteria: expectedResponse,
                    config: config.validation
                )
                validationResults.append(validation)
            }
        }
        
        // Validate overall scenario outcomes
        for outcome in scenario.expectedOutcomes {
            let validation = validator.validateOutcome(
                messages: messages,
                criteria: outcome,
                config: config.validation
            )
            validationResults.append(validation)
        }
        
        let conversationHistory = ConversationHistory(
            sessionId: sessionId,
            messages: messages,
            startTime: startTime,
            endTime: Date()
        )
        
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
    
    private func calculateDelay(for message: String, config: TimingConfig) -> Int {
        if config.rapidFire {
            return 0
        }
        
        return config.baseDelay + (message.count * config.delayPerCharacter)
    }
}

class CommunicationManager {
    private var currentBot: BotConfig?
    
    func connect(to bot: BotConfig) async throws {
        currentBot = bot
        // Initialize connection based on botProtocol
        switch bot.botProtocol {
        case .http:
            // HTTP connection setup
            break
        case .websocket:
            // WebSocket connection setup
            break
        }
    }
    
    func sendMessage(_ message: String) async throws -> BotResponse {
        guard let bot = currentBot else {
            throw TestError.notConnected
        }
        
        switch bot.botProtocol {
        case .http:
            return try await sendHTTPMessage(message, to: bot)
        case .websocket:
            return try await sendWebSocketMessage(message, to: bot)
        }
    }
    
    func disconnect() async {
        currentBot = nil
        // Clean up connections
    }
    
    private func sendHTTPMessage(_ message: String, to bot: BotConfig) async throws -> BotResponse {
        guard let url = URL(string: bot.endpoint) else {
            throw TestError.invalidEndpoint
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add authentication headers
        if let auth = bot.authentication {
            switch auth.type {
            case .bearer:
                request.setValue("Bearer \(auth.credentials)", forHTTPHeaderField: "Authorization")
            case .basic:
                let encoded = Data(auth.credentials.utf8).base64EncodedString()
                request.setValue("Basic \(encoded)", forHTTPHeaderField: "Authorization")
            case .apikey:
                request.setValue(auth.credentials, forHTTPHeaderField: "X-API-Key")
            }
        }
        
        // Add custom headers
        bot.headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        let requestBody = ["message": message]
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        let startTime = Date()
        let (data, response) = try await URLSession.shared.data(for: request)
        let responseTime = Date().timeIntervalSince(startTime)
        
        guard let httpResponse = response as? HTTPURLResponse,
              200...299 ~= httpResponse.statusCode else {
            throw TestError.httpError(statusCode: (response as? HTTPURLResponse)?.statusCode ?? 0)
        }
        
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
    
    private func sendWebSocketMessage(_ message: String, to bot: BotConfig) async throws -> BotResponse {
        guard let url = URL(string: bot.endpoint) else {
            throw TestError.invalidEndpoint
        }
        
        let webSocketTask = URLSession.shared.webSocketTask(with: url)
        webSocketTask.resume()
        
        // Send message
        let wsMessage = URLSessionWebSocketTask.Message.string(message)
        try await webSocketTask.send(wsMessage)
        
        let startTime = Date()
        
        // Receive response
        let response = try await webSocketTask.receive()
        let responseTime = Date().timeIntervalSince(startTime)
        
        let content: String
        switch response {
        case .string(let text):
            content = text
        case .data(let data):
            content = String(data: data, encoding: .utf8) ?? ""
        @unknown default:
            content = ""
        }
        
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

class ResponseValidator {
    func validate(response: BotResponse, criteria: ResponseCriteria, config: ValidationConfig) -> ValidationResult {
        switch criteria.validationType {
        case .exact:
            return validateExact(response: response, expected: criteria.expected)
        case .pattern:
            return validatePattern(response: response, pattern: criteria.expected)
        case .semantic:
            return validateSemantic(response: response, expected: criteria.expected, threshold: criteria.threshold ?? config.semanticSimilarityThreshold ?? 0.8)
        case .custom:
            return validateCustom(response: response, validator: criteria.expected)
        }
    }
    
    func validateOutcome(messages: [ConversationMessage], criteria: ValidationCriteria, config: ValidationConfig) -> ValidationResult {
        // Validate overall conversation outcome
        let conversationText = messages.map { $0.content }.joined(separator: " ")
        
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
    
    private func validateExact(response: BotResponse, expected: String) -> ValidationResult {
        let passed = response.content.trimmingCharacters(in: .whitespacesAndNewlines) == expected.trimmingCharacters(in: .whitespacesAndNewlines)
        
        return ValidationResult(
            passed: passed,
            expected: expected,
            actual: response.content,
            message: passed ? "Exact match successful" : "Content does not match exactly",
            details: nil
        )
    }
    
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
    
    private func validateSemantic(response: BotResponse, expected: String, threshold: Double) -> ValidationResult {
        // Use NaturalLanguage framework for semantic similarity
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
    
    private func calculateSemanticSimilarity(_ text1: String, _ text2: String) -> Double {
        // Use NaturalLanguage framework for better semantic analysis
        let embedding = NLEmbedding.wordEmbedding(for: .english)
        
        // Get embeddings for both texts
        guard let vector1 = embedding?.vector(for: text1.lowercased()),
              let vector2 = embedding?.vector(for: text2.lowercased()) else {
            // Fallback to simple similarity if embeddings not available
            return calculateSimpleSimilarity(text1, text2)
        }
        
        // Calculate cosine similarity
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
        
        guard magnitude1 > 0 && magnitude2 > 0 else {
            return calculateSimpleSimilarity(text1, text2)
        }
        
        let cosineSimilarity = dotProduct / (magnitude1 * magnitude2)
        
        // Normalize to 0-1 range (cosine similarity is -1 to 1)
        return (cosineSimilarity + 1) / 2
    }
    
    private func validateCustom(response: BotResponse, validator: String) -> ValidationResult {
        // Custom validation using predefined validators
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
    
    private func calculateSimpleSimilarity(_ text1: String, _ text2: String) -> Double {
        let separators = CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters)
        let words1 = Set(text1.lowercased().components(separatedBy: separators).filter { !$0.isEmpty })
        let words2 = Set(text2.lowercased().components(separatedBy: separators).filter { !$0.isEmpty })
        
        let intersection = words1.intersection(words2)
        let union = words1.union(words2)
        
        guard !union.isEmpty else { return 0.0 }
        
        return Double(intersection.count) / Double(union.count)
    }
}

enum TestError: Error, LocalizedError {
    case notConnected
    case invalidEndpoint
    case httpError(statusCode: Int)
    case notImplemented(String)
    case timeout
    case validationFailed(String)
    
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

