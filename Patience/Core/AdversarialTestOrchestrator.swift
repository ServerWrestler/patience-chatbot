import Foundation

class AdversarialTestOrchestrator {
    private let communicationManager = CommunicationManager()
    private var adversarialConnector: AdversarialBotConnector?
    private var totalCost: Double = 0
    private var requestCount: Int = 0
    private var lastRequestTime: Date?
    
    func run(config: AdversarialTestConfig) async throws -> [ConversationResult] {
        var results: [ConversationResult] = []
        
        // Initialize adversarial bot connector
        adversarialConnector = createConnector(for: config.adversarialBot)
        try await adversarialConnector?.initialize(config: config.adversarialBot)
        
        defer {
            Task {
                await adversarialConnector?.disconnect()
            }
        }
        
        // Connect to target bot
        let targetBotConfig = BotConfig(
            name: config.targetBot.name,
            botProtocol: config.targetBot.botProtocol,
            endpoint: config.targetBot.endpoint,
            authentication: config.targetBot.authentication.map { auth in
                AuthConfig(type: AuthType(rawValue: auth.type.rawValue) ?? .bearer, credentials: auth.credentials)
            },
            headers: config.targetBot.headers,
            provider: .generic,
            model: nil
        )
        
        try await communicationManager.connect(to: targetBotConfig)
        
        defer {
            Task {
                await communicationManager.disconnect()
            }
        }
        
        // Run conversations
        for conversationIndex in 0..<config.execution.numConversations {
            let result = try await runSingleConversation(
                config: config,
                conversationIndex: conversationIndex
            )
            results.append(result)
            
            // Delay between conversations if configured
            if let delay = config.execution.delayBetweenConversations, delay > 0 {
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000))
            }
        }
        
        return results
    }
    
    private func runSingleConversation(
        config: AdversarialTestConfig,
        conversationIndex: Int
    ) async throws -> ConversationResult {
        
        let conversationId = UUID().uuidString
        let startTime = Date()
        var messages: [AdversarialMessage] = []
        var validationResults: [ValidationResult] = []
        var terminationReason: TerminationReason = .max_turns
        
        // Get system prompt from strategy
        let strategy = createStrategy(for: config.conversation.strategy)
        let systemPrompt = strategy.getSystemPrompt(config: config)
        
        // Run conversation turns
        for turnNumber in 0..<config.conversation.maxTurns {
            // Check if adversarial bot wants to end conversation
            if let connector = adversarialConnector {
                let shouldEnd = try await connector.shouldEndConversation(messages: messages)
                if shouldEnd {
                    terminationReason = .adversarial_ended
                    break
                }
            }
            
            // Generate adversarial message
            guard let connector = adversarialConnector else {
                throw AdversarialError.connectorNotInitialized
            }
            
            let context = ConversationContext(
                conversationId: conversationId,
                turnNumber: turnNumber,
                validationResults: validationResults,
                goals: config.conversation.goals
            )
            
            // Check safety controls before making request
            try checkSafetyControls(config: config)
            
            let adversarialContent = try await connector.generateMessage(
                conversationHistory: messages,
                systemPrompt: systemPrompt,
                context: context
            )
            
            // Update safety tracking
            updateSafetyTracking(config: config)
            
            let adversarialMessage = AdversarialMessage(
                role: .adversarial,
                content: adversarialContent,
                timestamp: Date(),
                metadata: nil
            )
            messages.append(adversarialMessage)
            
            // Send to target bot and get response
            let targetResponse = try await communicationManager.sendMessage(adversarialContent)
            
            let targetMessage = AdversarialMessage(
                role: .target,
                content: targetResponse.content,
                timestamp: targetResponse.timestamp,
                metadata: [
                    "responseTime": String(targetResponse.responseTime ?? 0)
                ]
            )
            messages.append(targetMessage)
            
            // Validate response if rules are configured
            if let validationConfig = config.validation {
                for rule in validationConfig.rules {
                    let validation = validateResponse(
                        response: targetResponse,
                        criteria: rule
                    )
                    validationResults.append(validation)
                }
            }
            
            // Check if goals are achieved
            if strategy.isGoalAchieved(
                conversationHistory: messages,
                validationResults: validationResults
            ) {
                terminationReason = .goal_achieved
                break
            }
            
            // Delay between turns if configured
            if let delay = config.execution.delayBetweenTurns, delay > 0 {
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000))
            }
        }
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime) * 1000 // Convert to milliseconds
        
        // Calculate metrics
        let responseTimes = messages.compactMap { message -> Double? in
            guard message.role == .target,
                  let responseTimeString = message.metadata?["responseTime"],
                  let responseTime = Double(responseTimeString) else {
                return nil
            }
            return responseTime
        }
        
        let avgResponseTime = responseTimes.isEmpty ? 0.0 : responseTimes.reduce(0, +) / Double(responseTimes.count)
        let targetBotResponseRate = Double(messages.filter { $0.role == .target }.count) / Double(messages.filter { $0.role == .adversarial }.count)
        
        let passRate = validationResults.isEmpty ? 1.0 : Double(validationResults.filter { $0.passed }.count) / Double(validationResults.count)
        
        let metrics = ConversationMetrics(
            avgResponseTime: avgResponseTime,
            targetBotResponseRate: targetBotResponseRate,
            conversationQuality: passRate
        )
        
        return ConversationResult(
            conversationId: conversationId,
            timestamp: startTime,
            messages: messages,
            turns: messages.filter { $0.role == .adversarial }.count,
            duration: duration,
            validationResults: validationResults,
            passRate: passRate,
            metrics: metrics,
            terminationReason: terminationReason,
            terminationMessage: nil
        )
    }
    
    private func createConnector(for config: AdversarialBotSettings) -> AdversarialBotConnector {
        switch config.provider {
        case .openai:
            return OpenAIConnector()
        case .anthropic:
            return AnthropicConnector()
        case .ollama:
            return OllamaConnector()
        case .generic:
            return GenericConnector()
        }
    }
    
    private func createStrategy(for strategyType: ConversationStrategy) -> PromptStrategy {
        switch strategyType {
        case .exploratory:
            return ExploratoryStrategy()
        case .adversarial:
            return AdversarialStrategy()
        case .focused:
            return FocusedStrategy()
        case .stress:
            return StressStrategy()
        case .custom:
            return CustomStrategy()
        }
    }
    
    private func checkSafetyControls(config: AdversarialTestConfig) throws {
        guard let safety = config.safety else { return }
        
        // Check cost limit
        if let maxCost = safety.maxCostUSD, totalCost >= maxCost {
            throw AdversarialError.apiError("Cost limit reached: $\(totalCost) >= $\(maxCost)")
        }
        
        // Check rate limit
        if let maxRate = safety.maxRequestsPerMinute {
            if let lastTime = lastRequestTime {
                let timeSinceLastRequest = Date().timeIntervalSince(lastTime)
                let minInterval = 60.0 / Double(maxRate)
                
                if timeSinceLastRequest < minInterval {
                    let waitTime = minInterval - timeSinceLastRequest
                    throw AdversarialError.apiError("Rate limit: wait \(String(format: "%.1f", waitTime))s")
                }
            }
        }
    }
    
    private func updateSafetyTracking(config: AdversarialTestConfig) {
        requestCount += 1
        lastRequestTime = Date()
        
        // Estimate cost based on provider
        let estimatedCost: Double
        switch config.adversarialBot.provider {
        case .openai:
            // Rough estimate: $0.002 per request for GPT-3.5
            estimatedCost = 0.002
        case .anthropic:
            // Rough estimate: $0.003 per request for Claude
            estimatedCost = 0.003
        case .ollama, .generic:
            estimatedCost = 0.0 // Free/local
        }
        
        totalCost += estimatedCost
    }
    
    private func validateResponse(response: BotResponse, criteria: ValidationCriteria) -> ValidationResult {
        let validator = ResponseValidator()
        let responseCriteria = ResponseCriteria(
            validationType: criteria.type,
            expected: criteria.expected,
            threshold: criteria.threshold
        )
        
        let validationConfig = ValidationConfig(
            defaultType: criteria.type,
            semanticSimilarityThreshold: criteria.threshold,
            customValidators: nil
        )
        
        return validator.validate(response: response, criteria: responseCriteria, config: validationConfig)
    }
}

// MARK: - Supporting Types

struct ConversationContext: Sendable {
    let conversationId: String
    let turnNumber: Int
    let validationResults: [ValidationResult]
    let goals: [String]?
}

// MARK: - Connector Protocols

protocol AdversarialBotConnector {
    func initialize(config: AdversarialBotSettings) async throws
    func generateMessage(conversationHistory: [AdversarialMessage], systemPrompt: String, context: ConversationContext?) async throws -> String
    func shouldEndConversation(messages: [AdversarialMessage]) async throws -> Bool
    func disconnect() async
    func getName() -> String
}

// MARK: - Strategy Protocols

protocol PromptStrategy {
    func getSystemPrompt(config: AdversarialTestConfig) -> String
    func getNextTurnInstructions(conversationHistory: [AdversarialMessage], validationResults: [ValidationResult]) -> String
    func isGoalAchieved(conversationHistory: [AdversarialMessage], validationResults: [ValidationResult]) -> Bool
    func getName() -> String
}

// MARK: - Connector Implementations

class OpenAIConnector: AdversarialBotConnector {
    private var config: AdversarialBotSettings?
    
    func initialize(config: AdversarialBotSettings) async throws {
        self.config = config
        guard config.apiKey != nil else {
            throw AdversarialError.invalidConfiguration("OpenAI API key required")
        }
    }
    
    func generateMessage(conversationHistory: [AdversarialMessage], systemPrompt: String, context: ConversationContext?) async throws -> String {
        guard let config = config, let apiKey = config.apiKey else {
            throw AdversarialError.invalidConfiguration("OpenAI not configured")
        }
        
        let endpoint = config.endpoint ?? "https://api.openai.com/v1/chat/completions"
        guard let url = URL(string: endpoint) else {
            throw AdversarialError.invalidConfiguration("Invalid OpenAI endpoint")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Build messages array
        var messages: [[String: String]] = [["role": "system", "content": systemPrompt]]
        for msg in conversationHistory {
            let role = msg.role == .adversarial ? "assistant" : "user"
            messages.append(["role": role, "content": msg.content])
        }
        
        let body: [String: Any] = [
            "model": config.model ?? "gpt-3.5-turbo",
            "messages": messages,
            "temperature": config.temperature ?? 0.7,
            "max_tokens": config.maxTokens ?? 500
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AdversarialError.apiError("Invalid response")
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            let errorText = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw AdversarialError.apiError("OpenAI API error (\(httpResponse.statusCode)): \(errorText)")
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw AdversarialError.apiError("Invalid OpenAI response format")
        }
        
        return content
    }
    
    func shouldEndConversation(messages: [AdversarialMessage]) async throws -> Bool {
        return messages.count > 40 // End after 20 turns (40 messages)
    }
    
    func disconnect() async {
        config = nil
    }
    
    func getName() -> String {
        return "OpenAI Connector"
    }
}

class AnthropicConnector: AdversarialBotConnector {
    private var config: AdversarialBotSettings?
    
    func initialize(config: AdversarialBotSettings) async throws {
        self.config = config
        guard config.apiKey != nil else {
            throw AdversarialError.invalidConfiguration("Anthropic API key required")
        }
    }
    
    func generateMessage(conversationHistory: [AdversarialMessage], systemPrompt: String, context: ConversationContext?) async throws -> String {
        guard let config = config, let apiKey = config.apiKey else {
            throw AdversarialError.invalidConfiguration("Anthropic not configured")
        }
        
        let endpoint = config.endpoint ?? "https://api.anthropic.com/v1/messages"
        guard let url = URL(string: endpoint) else {
            throw AdversarialError.invalidConfiguration("Invalid Anthropic endpoint")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        
        // Build messages array
        var messages: [[String: String]] = []
        for msg in conversationHistory {
            let role = msg.role == .adversarial ? "assistant" : "user"
            messages.append(["role": role, "content": msg.content])
        }
        
        let body: [String: Any] = [
            "model": config.model ?? "claude-3-sonnet-20240229",
            "messages": messages,
            "system": systemPrompt,
            "max_tokens": config.maxTokens ?? 500,
            "temperature": config.temperature ?? 0.7
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AdversarialError.apiError("Invalid response")
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            let errorText = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw AdversarialError.apiError("Anthropic API error (\(httpResponse.statusCode)): \(errorText)")
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]],
              let firstContent = content.first,
              let text = firstContent["text"] as? String else {
            throw AdversarialError.apiError("Invalid Anthropic response format")
        }
        
        return text
    }
    
    func shouldEndConversation(messages: [AdversarialMessage]) async throws -> Bool {
        return messages.count > 40
    }
    
    func disconnect() async {
        config = nil
    }
    
    func getName() -> String {
        return "Anthropic Connector"
    }
}

class OllamaConnector: AdversarialBotConnector {
    private var config: AdversarialBotSettings?
    
    func initialize(config: AdversarialBotSettings) async throws {
        self.config = config
    }
    
    func generateMessage(conversationHistory: [AdversarialMessage], systemPrompt: String, context: ConversationContext?) async throws -> String {
        guard let config = config else {
            throw AdversarialError.invalidConfiguration("Ollama not configured")
        }
        
        let endpoint = config.endpoint ?? "http://localhost:11434/api/chat"
        guard let url = URL(string: endpoint) else {
            throw AdversarialError.invalidConfiguration("Invalid Ollama endpoint")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Build messages array
        var messages: [[String: String]] = [["role": "system", "content": systemPrompt]]
        for msg in conversationHistory {
            let role = msg.role == .adversarial ? "assistant" : "user"
            messages.append(["role": role, "content": msg.content])
        }
        
        let body: [String: Any] = [
            "model": config.model ?? "llama2",
            "messages": messages,
            "stream": false,
            "options": [
                "temperature": config.temperature ?? 0.7,
                "num_predict": config.maxTokens ?? 500
            ]
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AdversarialError.apiError("Invalid response")
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            let errorText = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw AdversarialError.apiError("Ollama API error (\(httpResponse.statusCode)): \(errorText)")
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let message = json["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw AdversarialError.apiError("Invalid Ollama response format")
        }
        
        return content
    }
    
    func shouldEndConversation(messages: [AdversarialMessage]) async throws -> Bool {
        return messages.count > 30
    }
    
    func disconnect() async {
        config = nil
    }
    
    func getName() -> String {
        return "Ollama Connector"
    }
}

class GenericConnector: AdversarialBotConnector {
    private var config: AdversarialBotSettings?
    
    func initialize(config: AdversarialBotSettings) async throws {
        self.config = config
        guard config.endpoint != nil else {
            throw AdversarialError.invalidConfiguration("Generic connector requires endpoint")
        }
    }
    
    func generateMessage(conversationHistory: [AdversarialMessage], systemPrompt: String, context: ConversationContext?) async throws -> String {
        guard let config = config, let endpoint = config.endpoint else {
            throw AdversarialError.invalidConfiguration("Generic connector not configured")
        }
        
        guard let url = URL(string: endpoint) else {
            throw AdversarialError.invalidConfiguration("Invalid endpoint URL")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        if let apiKey = config.apiKey {
            request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        }
        
        // Build simple request body
        let lastMessage = conversationHistory.last?.content ?? ""
        let body: [String: Any] = [
            "message": lastMessage,
            "system": systemPrompt,
            "history": conversationHistory.map { ["role": $0.role.rawValue, "content": $0.content] }
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AdversarialError.apiError("Invalid response")
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            let errorText = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw AdversarialError.apiError("Generic API error (\(httpResponse.statusCode)): \(errorText)")
        }
        
        // Try to parse response
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let content = json["response"] as? String {
                return content
            } else if let content = json["message"] as? String {
                return content
            } else if let content = json["content"] as? String {
                return content
            }
        }
        
        // Fallback to raw text
        if let text = String(data: data, encoding: .utf8), !text.isEmpty {
            return text
        }
        
        throw AdversarialError.apiError("Could not parse response")
    }
    
    func shouldEndConversation(messages: [AdversarialMessage]) async throws -> Bool {
        return messages.count > 20
    }
    
    func disconnect() async {
        config = nil
    }
    
    func getName() -> String {
        return "Generic Connector"
    }
}

// MARK: - Strategy Implementations

class ExploratoryStrategy: PromptStrategy {
    func getSystemPrompt(config: AdversarialTestConfig) -> String {
        let goals = config.conversation.goals?.joined(separator: ", ") ?? "general capabilities"
        return """
        You are an exploratory testing bot. Your goal is to understand the target bot's capabilities through diverse questions.
        
        Focus areas: \(goals)
        
        Ask varied questions covering:
        - Basic functionality and features
        - Different topics and domains
        - Edge cases and boundaries
        - Error handling
        
        Be curious and thorough. Each question should explore a different aspect.
        """
    }
    
    func getNextTurnInstructions(conversationHistory: [AdversarialMessage], validationResults: [ValidationResult]) -> String {
        return "Ask a different type of question to explore new capabilities."
    }
    
    func isGoalAchieved(conversationHistory: [AdversarialMessage], validationResults: [ValidationResult]) -> Bool {
        return false // Continue until max turns
    }
    
    func getName() -> String {
        return "Exploratory Strategy"
    }
}

class AdversarialStrategy: PromptStrategy {
    func getSystemPrompt(config: AdversarialTestConfig) -> String {
        return """
        You are an adversarial testing bot. Your goal is to find edge cases, weaknesses, and potential failures.
        
        Testing tactics:
        - Ask ambiguous or contradictory questions
        - Test boundary conditions and limits
        - Try unusual input patterns
        - Challenge assumptions
        - Test error handling with invalid inputs
        - Use edge cases and corner cases
        
        Be creative and challenging. Try to make the bot fail or produce unexpected results.
        """
    }
    
    func getNextTurnInstructions(conversationHistory: [AdversarialMessage], validationResults: [ValidationResult]) -> String {
        let failedCount = validationResults.filter { !$0.passed }.count
        if failedCount > 0 {
            return "You found \(failedCount) issue(s). Continue probing for more weaknesses."
        }
        return "Try to find weaknesses or edge cases in the bot's responses."
    }
    
    func isGoalAchieved(conversationHistory: [AdversarialMessage], validationResults: [ValidationResult]) -> Bool {
        // Goal achieved if we found at least 3 failures
        return validationResults.filter { !$0.passed }.count >= 3
    }
    
    func getName() -> String {
        return "Adversarial Strategy"
    }
}

class FocusedStrategy: PromptStrategy {
    func getSystemPrompt(config: AdversarialTestConfig) -> String {
        let goals = config.conversation.goals?.joined(separator: "\n- ") ?? "general functionality"
        return """
        You are a focused testing bot. Deep dive into specific features and capabilities.
        
        Testing goals:
        - \(goals)
        
        For each goal:
        1. Test basic functionality
        2. Test variations and parameters
        3. Test edge cases
        4. Verify error handling
        5. Check consistency
        
        Stay focused on these specific areas. Go deep rather than broad.
        """
    }
    
    func getNextTurnInstructions(conversationHistory: [AdversarialMessage], validationResults: [ValidationResult]) -> String {
        let passedCount = validationResults.filter { $0.passed }.count
        return "Continue testing the specific goals. Progress: \(passedCount) validations passed."
    }
    
    func isGoalAchieved(conversationHistory: [AdversarialMessage], validationResults: [ValidationResult]) -> Bool {
        // Goal achieved if we have at least 5 passed validations
        return validationResults.filter { $0.passed }.count >= 5
    }
    
    func getName() -> String {
        return "Focused Strategy"
    }
}

class StressStrategy: PromptStrategy {
    func getSystemPrompt(config: AdversarialTestConfig) -> String {
        return """
        You are a stress testing bot. Your goal is to test the bot's limits and performance under pressure.
        
        Stress testing tactics:
        - Rapid context switching between topics
        - Long, complex multi-part questions
        - Requests with many constraints
        - Contradictory requirements
        - High information density
        - Nested or recursive scenarios
        
        Push the bot to its limits. Test how it handles complexity and rapid changes.
        """
    }
    
    func getNextTurnInstructions(conversationHistory: [AdversarialMessage], validationResults: [ValidationResult]) -> String {
        let turnCount = conversationHistory.filter { $0.role == .adversarial }.count
        return "Turn \(turnCount): Increase complexity and challenge level."
    }
    
    func isGoalAchieved(conversationHistory: [AdversarialMessage], validationResults: [ValidationResult]) -> Bool {
        // Continue until max turns or we see degradation
        let recentFailures = validationResults.suffix(3).filter { !$0.passed }.count
        return recentFailures >= 2 // Stop if 2 of last 3 validations failed
    }
    
    func getName() -> String {
        return "Stress Strategy"
    }
}

class CustomStrategy: PromptStrategy {
    func getSystemPrompt(config: AdversarialTestConfig) -> String {
        if let customPrompt = config.conversation.systemPrompt {
            return customPrompt
        }
        
        let goals = config.conversation.goals?.joined(separator: "\n- ") ?? "test the bot"
        return """
        You are a custom testing bot following user-defined strategy.
        
        Goals:
        - \(goals)
        
        Follow the testing approach defined by the user.
        """
    }
    
    func getNextTurnInstructions(conversationHistory: [AdversarialMessage], validationResults: [ValidationResult]) -> String {
        return "Follow the custom strategy defined in the configuration."
    }
    
    func isGoalAchieved(conversationHistory: [AdversarialMessage], validationResults: [ValidationResult]) -> Bool {
        // For custom strategy, check if all validations pass
        guard !validationResults.isEmpty else { return false }
        return validationResults.allSatisfy { $0.passed }
    }
    
    func getName() -> String {
        return "Custom Strategy"
    }
}

enum AdversarialError: Error, LocalizedError, Sendable {
    case connectorNotInitialized
    case invalidConfiguration(String)
    case apiError(String)
    case timeout
    
    var errorDescription: String? {
        switch self {
        case .connectorNotInitialized:
            return "Adversarial bot connector not initialized"
        case .invalidConfiguration(let message):
            return "Invalid configuration: \(message)"
        case .apiError(let message):
            return "API error: \(message)"
        case .timeout:
            return "Request timeout"
        }
    }
}
