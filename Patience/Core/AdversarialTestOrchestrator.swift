import Foundation

/// Orchestrates adversarial testing sessions between an AI-powered adversarial bot and a target chatbot
/// This is the main engine for automated testing where one AI tries to find weaknesses in another bot
/// 
/// How it works:
/// 1. Connects to both the adversarial bot (OpenAI/Anthropic/Ollama) and target bot
/// 2. Uses a strategy (exploratory, adversarial, focused, stress) to guide the conversation
/// 3. Runs multiple conversation sessions with configurable turns
/// 4. Validates responses against configured rules
/// 5. Tracks metrics, costs, and safety limits
/// 
/// The adversarial bot generates challenging messages based on the selected strategy
/// The target bot responds, and responses are validated and analyzed
/// Results include conversation history, validation results, and performance metrics
class AdversarialTestOrchestrator {
    /// Manages HTTP/WebSocket communication with the target bot
    private let communicationManager = CommunicationManager()
    
    /// Connector for the adversarial AI bot (OpenAI, Anthropic, Ollama, or generic)
    /// Created based on config.adversarialBot.provider
    private var adversarialConnector: AdversarialBotConnector?
    
    /// Running total of estimated API costs in USD
    /// Used to enforce safety.maxCostUSD limit
    private var totalCost: Double = 0
    
    /// Number of API requests made to adversarial bot
    /// Used for tracking and rate limiting
    private var requestCount: Int = 0
    
    /// Timestamp of last API request to adversarial bot
    /// Used to enforce safety.maxRequestsPerMinute limit
    private var lastRequestTime: Date?
    
    /// Runs a complete adversarial testing session with multiple conversations
    /// This is the main entry point for adversarial testing
    /// 
    /// - Parameter config: Complete configuration including bots, strategy, validation, safety limits
    /// - Returns: Array of conversation results, one per conversation run
    /// - Throws: AdversarialError if connection fails, API errors occur, or safety limits are hit
    /// 
    /// Process:
    /// 1. Initialize adversarial bot connector (OpenAI/Anthropic/Ollama/Generic)
    /// 2. Connect to target bot
    /// 3. Run config.execution.numConversations separate conversations
    /// 4. Each conversation has up to config.conversation.maxTurns turns
    /// 5. Delay between conversations if configured
    /// 6. Disconnect both bots when done
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
    
    /// Runs a single conversation between the adversarial bot and target bot
    /// This is where the actual back-and-forth testing happens
    /// 
    /// - Parameters:
    ///   - config: Test configuration with strategy, validation rules, and limits
    ///   - conversationIndex: Which conversation this is (0-based index)
    /// - Returns: ConversationResult with messages, validations, metrics, and termination reason
    /// - Throws: AdversarialError if API calls fail or safety limits are exceeded
    /// 
    /// Conversation flow:
    /// 1. Get system prompt from strategy (tells adversarial bot how to behave)
    /// 2. For each turn up to maxTurns:
    ///    a. Check if adversarial bot wants to end (goal achieved)
    ///    b. Check safety controls (cost/rate limits)
    ///    c. Adversarial bot generates a message
    ///    d. Send message to target bot and get response
    ///    e. Validate target bot's response
    ///    f. Check if goals achieved
    ///    g. Delay before next turn if configured
    /// 3. Calculate metrics and return results
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
    
    /// Creates the appropriate connector based on the adversarial bot provider
    /// Each provider has different API formats and authentication
    /// 
    /// - Parameter config: Adversarial bot settings with provider type
    /// - Returns: Connector instance for the specified provider
    /// 
    /// Supported providers:
    /// - .openai: OpenAI GPT models (requires API key)
    /// - .anthropic: Anthropic Claude models (requires API key)
    /// - .ollama: Local Ollama models (free, no API key)
    /// - .generic: Custom API endpoint (flexible format)
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
    
    /// Creates the appropriate testing strategy based on configuration
    /// Strategy determines how the adversarial bot behaves and what it tries to achieve
    /// 
    /// - Parameter strategyType: Type of testing strategy to use
    /// - Returns: Strategy instance that provides system prompts and goal checking
    /// 
    /// Available strategies:
    /// - .exploratory: Broad exploration of capabilities with diverse questions
    /// - .adversarial: Actively tries to find weaknesses and edge cases
    /// - .focused: Deep dive into specific features defined in goals
    /// - .stress: Tests limits with complex, rapid, contradictory requests
    /// - .custom: User-defined strategy with custom system prompt
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
    
    /// Checks safety limits before making an API request to the adversarial bot
    /// Prevents runaway costs and respects rate limits
    /// 
    /// - Parameter config: Test configuration with safety settings
    /// - Throws: AdversarialError.apiError if limits are exceeded
    /// 
    /// Safety checks:
    /// - maxCostUSD: Stops if estimated total cost exceeds limit
    /// - maxRequestsPerMinute: Enforces minimum delay between requests
    /// 
    /// Call this before every API request to adversarial bot
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
    
    /// Updates safety tracking after making an API request
    /// Increments request count, updates timestamp, and estimates cost
    /// 
    /// - Parameter config: Test configuration with provider info for cost estimation
    /// 
    /// Cost estimates (rough approximations):
    /// - OpenAI GPT-3.5: $0.002 per request
    /// - Anthropic Claude: $0.003 per request
    /// - Ollama/Generic: $0.00 (free/local)
    /// 
    /// Call this after every successful API request to adversarial bot
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
    
    /// Validates a target bot's response against configured criteria
    /// Uses ResponseValidator to check if response meets expectations
    /// 
    /// - Parameters:
    ///   - response: The target bot's response to validate
    ///   - criteria: Validation criteria (pattern, semantic, custom, etc.)
    /// - Returns: ValidationResult indicating pass/fail with details
    /// 
    /// Validation types supported:
    /// - pattern: Regex matching
    /// - semantic: Meaning similarity using NLP
    /// - custom: User-defined validation functions
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

/// Context information passed to adversarial bot when generating messages
/// Helps the bot understand where it is in the conversation and what it's trying to achieve
/// Sendable: Safe to pass between async contexts
struct ConversationContext: Sendable {
    /// Unique identifier for this conversation session
    let conversationId: String
    
    /// Current turn number (0-based)
    /// Helps adversarial bot adjust strategy as conversation progresses
    let turnNumber: Int
    
    /// All validation results so far in this conversation
    /// Adversarial bot can use this to see what's working/failing
    let validationResults: [ValidationResult]
    
    /// Testing goals from configuration
    /// What the adversarial bot is trying to achieve or test
    let goals: [String]?
}

// MARK: - Connector Protocols

/// Protocol that all adversarial bot connectors must implement
/// Defines how to communicate with different AI providers (OpenAI, Anthropic, Ollama, etc.)
/// Each provider has different API formats, so connectors handle the translation
protocol AdversarialBotConnector {
    /// Initialize the connector with configuration (API keys, endpoints, etc.)
    /// - Parameter config: Settings for this adversarial bot
    /// - Throws: AdversarialError if configuration is invalid or connection fails
    func initialize(config: AdversarialBotSettings) async throws
    
    /// Generate the next message from the adversarial bot
    /// - Parameters:
    ///   - conversationHistory: All messages exchanged so far
    ///   - systemPrompt: Instructions for how the bot should behave (from strategy)
    ///   - context: Additional context (turn number, validation results, goals)
    /// - Returns: The generated message content
    /// - Throws: AdversarialError if API call fails
    func generateMessage(conversationHistory: [AdversarialMessage], systemPrompt: String, context: ConversationContext?) async throws -> String
    
    /// Check if the adversarial bot wants to end the conversation early
    /// - Parameter messages: Current conversation history
    /// - Returns: true if conversation should end, false to continue
    /// - Throws: AdversarialError if check fails
    func shouldEndConversation(messages: [AdversarialMessage]) async throws -> Bool
    
    /// Clean up and disconnect from the adversarial bot
    func disconnect() async
    
    /// Get human-readable name of this connector
    /// - Returns: Name like "OpenAI Connector" or "Anthropic Connector"
    func getName() -> String
}

// MARK: - Strategy Protocols

/// Protocol that all testing strategies must implement
/// Strategies define how the adversarial bot behaves and what it tries to achieve
/// Different strategies are useful for different testing goals
protocol PromptStrategy {
    /// Get the system prompt that tells the adversarial bot how to behave
    /// This is sent at the start of each conversation
    /// - Parameter config: Test configuration with goals and settings
    /// - Returns: System prompt text (instructions for the adversarial bot)
    func getSystemPrompt(config: AdversarialTestConfig) -> String
    
    /// Get instructions for the next turn (optional, for dynamic strategies)
    /// - Parameters:
    ///   - conversationHistory: Messages exchanged so far
    ///   - validationResults: Validation results so far
    /// - Returns: Additional instructions for next turn
    func getNextTurnInstructions(conversationHistory: [AdversarialMessage], validationResults: [ValidationResult]) -> String
    
    /// Check if the strategy's goals have been achieved
    /// If true, conversation can end early
    /// - Parameters:
    ///   - conversationHistory: Messages exchanged so far
    ///   - validationResults: Validation results so far
    /// - Returns: true if goals achieved, false to continue
    func isGoalAchieved(conversationHistory: [AdversarialMessage], validationResults: [ValidationResult]) -> Bool
    
    /// Get human-readable name of this strategy
    /// - Returns: Name like "Exploratory Strategy" or "Adversarial Strategy"
    func getName() -> String
}

// MARK: - Connector Implementations

/// Connector for OpenAI's GPT models (GPT-3.5, GPT-4, etc.)
/// Uses OpenAI's Chat Completions API
/// Requires API key from https://platform.openai.com/api-keys
/// 
/// API format: POST to /v1/chat/completions with messages array
/// Authentication: Bearer token in Authorization header
/// Response: JSON with choices array containing generated message
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

/// Connector for Anthropic's Claude models (Claude 3 Sonnet, Opus, etc.)
/// Uses Anthropic's Messages API
/// Requires API key from https://console.anthropic.com/
/// 
/// API format: POST to /v1/messages with messages array and system prompt
/// Authentication: x-api-key header
/// Response: JSON with content array containing generated text
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

/// Connector for Ollama local AI models
/// Ollama runs models locally on your machine (free, no API key needed)
/// Download from https://ollama.ai/
/// 
/// API format: POST to /api/chat with messages array
/// Authentication: None (local)
/// Response: JSON with message.content containing generated text
/// 
/// Popular models: llama2, mistral, codellama, phi
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

/// Connector for custom/generic API endpoints
/// Flexible connector that tries multiple response formats
/// Use this for custom chatbot APIs that don't match OpenAI/Anthropic/Ollama formats
/// 
/// Tries to parse response as JSON with keys: "response", "message", or "content"
/// Falls back to raw text if JSON parsing fails
/// Supports optional Bearer token authentication
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

/// Exploratory testing strategy
/// Goal: Understand the target bot's capabilities through diverse, varied questions
/// 
/// Behavior:
/// - Asks questions covering different topics and domains
/// - Tests basic functionality and features
/// - Explores edge cases and boundaries
/// - Checks error handling
/// 
/// Best for: Initial testing, discovering what a bot can do, broad coverage
/// Termination: Runs until maxTurns (doesn't end early)
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

/// Adversarial testing strategy
/// Goal: Find weaknesses, edge cases, and potential failures in the target bot
/// 
/// Behavior:
/// - Asks ambiguous or contradictory questions
/// - Tests boundary conditions and limits
/// - Uses unusual input patterns
/// - Challenges assumptions
/// - Tests error handling with invalid inputs
/// 
/// Best for: Security testing, finding bugs, stress testing edge cases
/// Termination: Ends early if 3+ failures found (goal achieved)
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

/// Focused testing strategy
/// Goal: Deep dive into specific features and capabilities defined in goals
/// 
/// Behavior:
/// - Tests basic functionality of specific features
/// - Tests variations and parameters
/// - Tests edge cases for those features
/// - Verifies error handling
/// - Checks consistency
/// 
/// Best for: Feature-specific testing, regression testing, detailed validation
/// Termination: Ends early if 5+ validations pass (thorough coverage achieved)
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

/// Stress testing strategy
/// Goal: Test the bot's limits and performance under pressure
/// 
/// Behavior:
/// - Rapid context switching between topics
/// - Long, complex multi-part questions
/// - Requests with many constraints
/// - Contradictory requirements
/// - High information density
/// - Nested or recursive scenarios
/// 
/// Best for: Performance testing, finding breaking points, testing under load
/// Termination: Ends early if 2 of last 3 validations fail (degradation detected)
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

/// Custom testing strategy
/// Goal: User-defined testing approach with custom system prompt
/// 
/// Behavior:
/// - Uses config.conversation.systemPrompt if provided
/// - Falls back to generic prompt with goals if no custom prompt
/// - Follows user-defined testing approach
/// 
/// Best for: Specialized testing scenarios, custom validation logic
/// Termination: Ends early if all validations pass (perfect score)
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

/// Errors that can occur during adversarial testing
/// Sendable: Safe to pass between async contexts
/// LocalizedError: Provides user-friendly error messages
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
