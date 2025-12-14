import Foundation

class AnalysisEngine {
    private let logLoader = LogLoader()
    private let metricsCalculator = MetricsCalculator()
    private let patternDetector = PatternDetector()
    
    func analyze(config: AnalysisConfig) async throws -> AnalysisResults {
        let startTime = Date()
        
        // Load conversation data
        let conversations = try await logLoader.loadConversations(from: config.logSource)
        
        // Apply filters
        let filteredConversations = applyFilters(conversations, filters: config.filters)
        
        // Calculate metrics
        var metrics: AnalysisMetrics?
        if config.analysis.calculateMetrics {
            metrics = metricsCalculator.calculate(from: filteredConversations)
        }
        
        // Detect patterns
        var patterns: [DetectedPattern]?
        if config.analysis.detectPatterns {
            patterns = patternDetector.detectPatterns(in: filteredConversations)
        }
        
        // Run validation if configured
        var validationResults: [ValidationResult]?
        if let validationConfig = config.validation {
            validationResults = validateConversations(filteredConversations, config: validationConfig)
        }
        
        // Check context retention if configured
        var contextAnalysis: ContextRetentionAnalysis?
        if config.analysis.checkContextRetention {
            contextAnalysis = analyzeContextRetention(filteredConversations)
        }
        
        let processingTime = Date().timeIntervalSince(startTime) * 1000 // Convert to milliseconds
        
        let summary = AnalysisSummary(
            totalConversations: conversations.count,
            analyzedConversations: filteredConversations.count,
            overallPassRate: calculatePassRate(validationResults),
            processingTime: processingTime
        )
        
        return AnalysisResults(
            summary: summary,
            metrics: metrics,
            patterns: patterns,
            validationResults: validationResults,
            contextAnalysis: contextAnalysis
        )
    }
    
    private func applyFilters(_ conversations: [ConversationHistory], filters: AnalysisFilters?) -> [ConversationHistory] {
        guard let filters = filters else { return conversations }
        
        var filtered = conversations
        
        // Apply date range filter
        if let dateRange = filters.dateRange {
            filtered = filtered.filter { conversation in
                conversation.startTime >= dateRange.start && conversation.startTime <= dateRange.end
            }
        }
        
        // Apply minimum messages filter
        if let minMessages = filters.minMessages {
            filtered = filtered.filter { $0.messages.count >= minMessages }
        }
        
        return filtered
    }
    
    private func validateConversations(_ conversations: [ConversationHistory], config: ValidationConfig) -> [ValidationResult] {
        var results: [ValidationResult] = []
        
        for conversation in conversations {
            // Validate each conversation based on configured rules
            let conversationText = conversation.messages.map { $0.content }.joined(separator: " ")
            
            // For now, just validate that conversations have meaningful content
            let hasContent = !conversationText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            
            let result = ValidationResult(
                passed: hasContent,
                expected: "Non-empty conversation",
                actual: conversationText.prefix(100) + (conversationText.count > 100 ? "..." : ""),
                message: hasContent ? "Conversation has content" : "Empty conversation",
                details: ["messageCount": String(conversation.messages.count)]
            )
            
            results.append(result)
        }
        
        return results
    }
    
    private func calculatePassRate(_ validationResults: [ValidationResult]?) -> Double {
        guard let results = validationResults, !results.isEmpty else { return 1.0 }
        
        let passedCount = results.filter { $0.passed }.count
        return Double(passedCount) / Double(results.count)
    }
    
    private func analyzeContextRetention(_ conversations: [ConversationHistory]) -> ContextRetentionAnalysis {
        var totalScore: Double = 0
        var topicSwitches = 0
        var totalReferenceDistance: Double = 0
        var referenceCount = 0
        var contextBreaks = 0
        
        for conversation in conversations {
            let messages = conversation.messages
            guard messages.count > 2 else { continue }
            
            var conversationScore: Double = 0
            
            for i in 1..<messages.count {
                let currentMessage = messages[i]
                let previousMessage = messages[i - 1]
                
                // Extract key words from messages
                let currentWords = extractKeyWords(from: currentMessage.content)
                let previousWords = extractKeyWords(from: previousMessage.content)
                
                // Check for topic continuity
                let overlap = currentWords.intersection(previousWords)
                let continuityScore = Double(overlap.count) / Double(max(currentWords.count, 1))
                conversationScore += continuityScore
                
                // Detect topic switches
                if continuityScore < 0.2 && i > 1 {
                    topicSwitches += 1
                }
                
                // Check for references to earlier messages
                for j in 0..<i-1 {
                    let earlierMessage = messages[j]
                    let earlierWords = extractKeyWords(from: earlierMessage.content)
                    let referenceOverlap = currentWords.intersection(earlierWords)
                    
                    if !referenceOverlap.isEmpty {
                        let distance = Double(i - j)
                        totalReferenceDistance += distance
                        referenceCount += 1
                    }
                }
                
                // Detect context breaks (bot doesn't understand reference)
                if currentMessage.sender == .target {
                    let confusionWords = ["what", "don't understand", "unclear", "repeat", "clarify"]
                    let lowercased = currentMessage.content.lowercased()
                    if confusionWords.contains(where: { lowercased.contains($0) }) {
                        contextBreaks += 1
                    }
                }
            }
            
            totalScore += conversationScore / Double(messages.count - 1)
        }
        
        let averageScore = conversations.isEmpty ? 0 : totalScore / Double(conversations.count)
        let averageDistance = referenceCount > 0 ? totalReferenceDistance / Double(referenceCount) : 0
        
        return ContextRetentionAnalysis(
            averageContextScore: averageScore,
            conversationsAnalyzed: conversations.count,
            topicSwitches: topicSwitches,
            averageReferenceDistance: averageDistance,
            contextBreaks: contextBreaks
        )
    }
    
    private func extractKeyWords(from text: String) -> Set<String> {
        let stopWords = Set(["the", "a", "an", "and", "or", "but", "in", "on", "at", "to", "for", "of", "with", "by", "from", "is", "are", "was", "were", "be", "been", "being", "have", "has", "had", "do", "does", "did", "will", "would", "could", "should", "may", "might", "can", "i", "you", "he", "she", "it", "we", "they", "this", "that", "these", "those"])
        
        let words = text.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.count > 2 && !stopWords.contains($0) }
        
        return Set(words)
    }
}

class LogLoader {
    func loadConversations(from source: LogSource) async throws -> [ConversationHistory] {
        let url = URL(fileURLWithPath: NSString(string: source.path).expandingTildeInPath)
        
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw AnalysisError.fileNotFound(source.path)
        }
        
        let data = try Data(contentsOf: url)
        
        switch source.format {
        case .json:
            return try parseJSONLog(data)
        case .csv:
            return try parseCSVLog(data)
        case .text:
            return try parseTextLog(data)
        case .auto:
            return try parseAutoDetectLog(data, url: url)
        }
    }
    
    private func parseJSONLog(_ data: Data) throws -> [ConversationHistory] {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        // Try to decode as array of conversations first
        if let conversations = try? decoder.decode([ConversationHistory].self, from: data) {
            return conversations
        }
        
        // Try to decode as single conversation
        if let conversation = try? decoder.decode(ConversationHistory.self, from: data) {
            return [conversation]
        }
        
        // Try to decode as array of messages and create a conversation
        if let messages = try? decoder.decode([ConversationMessage].self, from: data) {
            let conversation = ConversationHistory(
                sessionId: UUID().uuidString,
                messages: messages,
                startTime: messages.first?.timestamp ?? Date(),
                endTime: messages.last?.timestamp
            )
            return [conversation]
        }
        
        throw AnalysisError.invalidFormat("Unable to parse JSON log file")
    }
    
    private func parseCSVLog(_ data: Data) throws -> [ConversationHistory] {
        guard let content = String(data: data, encoding: .utf8) else {
            throw AnalysisError.invalidFormat("Unable to read CSV file as UTF-8")
        }
        
        let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }
        guard lines.count > 1 else {
            throw AnalysisError.invalidFormat("CSV file must have header and at least one data row")
        }
        
        var messages: [ConversationMessage] = []
        
        for line in lines.dropFirst() {
            let fields = line.components(separatedBy: ",")
            guard fields.count >= 3 else { continue }
            
            // Assuming CSV format: timestamp, sender, content
            let timestampString = fields[0].trimmingCharacters(in: .whitespacesAndNewlines)
            let senderString = fields[1].trimmingCharacters(in: .whitespacesAndNewlines)
            let content = fields[2].trimmingCharacters(in: .whitespacesAndNewlines)
            
            let formatter = ISO8601DateFormatter()
            let timestamp = formatter.date(from: timestampString) ?? Date()
            let sender: MessageSender = senderString.lowercased().contains("bot") ? .target : .patience
            
            let message = ConversationMessage(
                sender: sender,
                content: content,
                timestamp: timestamp
            )
            
            messages.append(message)
        }
        
        let conversation = ConversationHistory(
            sessionId: UUID().uuidString,
            messages: messages,
            startTime: messages.first?.timestamp ?? Date(),
            endTime: messages.last?.timestamp
        )
        
        return [conversation]
    }
    
    private func parseTextLog(_ data: Data) throws -> [ConversationHistory] {
        guard let content = String(data: data, encoding: .utf8) else {
            throw AnalysisError.invalidFormat("Unable to read text file as UTF-8")
        }
        
        // Simple text parsing - assumes alternating user/bot messages
        let lines = content.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        var messages: [ConversationMessage] = []
        
        for (index, line) in lines.enumerated() {
            let sender: MessageSender = index % 2 == 0 ? .patience : .target
            let message = ConversationMessage(
                sender: sender,
                content: line.trimmingCharacters(in: .whitespacesAndNewlines),
                timestamp: Date().addingTimeInterval(TimeInterval(index * 60)) // Fake timestamps
            )
            messages.append(message)
        }
        
        let conversation = ConversationHistory(
            sessionId: UUID().uuidString,
            messages: messages,
            startTime: Date(),
            endTime: Date()
        )
        
        return [conversation]
    }
    
    private func parseAutoDetectLog(_ data: Data, url: URL) throws -> [ConversationHistory] {
        let fileExtension = url.pathExtension.lowercased()
        
        switch fileExtension {
        case "json":
            return try parseJSONLog(data)
        case "csv":
            return try parseCSVLog(data)
        case "txt", "log":
            return try parseTextLog(data)
        default:
            // Try JSON first, then CSV, then text
            if let conversations = try? parseJSONLog(data) {
                return conversations
            } else if let conversations = try? parseCSVLog(data) {
                return conversations
            } else {
                return try parseTextLog(data)
            }
        }
    }
}

class MetricsCalculator {
    func calculate(from conversations: [ConversationHistory]) -> AnalysisMetrics {
        let totalMessages = conversations.reduce(0) { $0 + $1.messages.count }
        let averageMessagesPerConversation = conversations.isEmpty ? 0.0 : Double(totalMessages) / Double(conversations.count)
        
        // Calculate average response time if available
        var responseTimes: [Double] = []
        for conversation in conversations {
            for message in conversation.messages {
                if message.sender == .target, let validationResult = message.validationResult {
                    // Extract response time from validation details if available
                    if let responseTimeString = validationResult.details?["responseTime"],
                       let responseTime = Double(responseTimeString) {
                        responseTimes.append(responseTime)
                    }
                }
            }
        }
        
        let averageResponseTime = responseTimes.isEmpty ? nil : responseTimes.reduce(0, +) / Double(responseTimes.count)
        
        return AnalysisMetrics(
            totalMessages: totalMessages,
            averageMessagesPerConversation: averageMessagesPerConversation,
            averageResponseTime: averageResponseTime
        )
    }
}

class PatternDetector {
    func detectPatterns(in conversations: [ConversationHistory]) -> [DetectedPattern] {
        var patterns: [DetectedPattern] = []
        
        // Detect common greeting patterns
        let greetingPattern = detectGreetingPatterns(in: conversations)
        if let pattern = greetingPattern {
            patterns.append(pattern)
        }
        
        // Detect question patterns
        let questionPattern = detectQuestionPatterns(in: conversations)
        if let pattern = questionPattern {
            patterns.append(pattern)
        }
        
        // Detect error patterns
        let errorPattern = detectErrorPatterns(in: conversations)
        if let pattern = errorPattern {
            patterns.append(pattern)
        }
        
        return patterns
    }
    
    private func detectGreetingPatterns(in conversations: [ConversationHistory]) -> DetectedPattern? {
        let greetingWords = ["hello", "hi", "hey", "greetings", "good morning", "good afternoon"]
        var greetingCount = 0
        
        for conversation in conversations {
            for message in conversation.messages {
                if message.sender == .patience {
                    let content = message.content.lowercased()
                    if greetingWords.contains(where: { content.contains($0) }) {
                        greetingCount += 1
                        break // Only count once per conversation
                    }
                }
            }
        }
        
        guard greetingCount > 0 else { return nil }
        
        return DetectedPattern(
            type: "greeting",
            pattern: "Common greeting words",
            frequency: greetingCount,
            confidence: Double(greetingCount) / Double(conversations.count)
        )
    }
    
    private func detectQuestionPatterns(in conversations: [ConversationHistory]) -> DetectedPattern? {
        var questionCount = 0
        
        for conversation in conversations {
            for message in conversation.messages {
                if message.sender == .patience && message.content.contains("?") {
                    questionCount += 1
                }
            }
        }
        
        guard questionCount > 0 else { return nil }
        
        return DetectedPattern(
            type: "question",
            pattern: "Messages ending with question marks",
            frequency: questionCount,
            confidence: 0.9
        )
    }
    
    private func detectErrorPatterns(in conversations: [ConversationHistory]) -> DetectedPattern? {
        let errorWords = ["error", "sorry", "can't", "unable", "failed", "problem"]
        var errorCount = 0
        
        for conversation in conversations {
            for message in conversation.messages {
                if message.sender == .target {
                    let content = message.content.lowercased()
                    if errorWords.contains(where: { content.contains($0) }) {
                        errorCount += 1
                    }
                }
            }
        }
        
        guard errorCount > 0 else { return nil }
        
        return DetectedPattern(
            type: "error",
            pattern: "Error-related responses",
            frequency: errorCount,
            confidence: 0.8
        )
    }
}

enum AnalysisError: Error, LocalizedError {
    case fileNotFound(String)
    case invalidFormat(String)
    case parsingError(String)
    
    var errorDescription: String? {
        switch self {
        case .fileNotFound(let path):
            return "File not found: \(path)"
        case .invalidFormat(let message):
            return "Invalid file format: \(message)"
        case .parsingError(let message):
            return "Parsing error: \(message)"
        }
    }
}

