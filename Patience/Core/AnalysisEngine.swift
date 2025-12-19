import Foundation

/// Analyzes conversation logs to extract insights, metrics, and patterns
/// This is the main engine for log analysis functionality
/// 
/// Capabilities:
/// - Loads conversation logs from JSON, CSV, or text files
/// - Calculates metrics (message counts, response times, etc.)
/// - Detects patterns (greetings, questions, errors)
/// - Validates conversations against rules
/// - Analyzes context retention (how well bot remembers earlier messages)
/// 
/// Typical workflow:
/// 1. Load conversations from log file
/// 2. Apply filters (date range, minimum messages)
/// 3. Calculate metrics if enabled
/// 4. Detect patterns if enabled
/// 5. Run validation if configured
/// 6. Analyze context retention if enabled
/// 7. Return comprehensive results
class AnalysisEngine {
    /// Loads and parses conversation logs from various file formats
    private let logLoader = LogLoader()
    
    /// Calculates statistical metrics from conversations
    private let metricsCalculator = MetricsCalculator()
    
    /// Detects common patterns in conversation data
    private let patternDetector = PatternDetector()
    
    /// Performs complete analysis of conversation logs
    /// This is the main entry point for log analysis
    /// 
    /// - Parameter config: Configuration specifying what to analyze and how
    /// - Returns: AnalysisResults with metrics, patterns, validations, and context analysis
    /// - Throws: AnalysisError if file not found, invalid format, or parsing fails
    /// 
    /// Process:
    /// 1. Load conversations from log file (JSON/CSV/text)
    /// 2. Apply filters (date range, minimum messages)
    /// 3. Calculate metrics if config.analysis.calculateMetrics is true
    /// 4. Detect patterns if config.analysis.detectPatterns is true
    /// 5. Run validation if config.validation is set
    /// 6. Analyze context retention if config.analysis.checkContextRetention is true
    /// 7. Build summary with pass rates and processing time
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
    
    /// Filters conversations based on configured criteria
    /// 
    /// - Parameters:
    ///   - conversations: All loaded conversations
    ///   - filters: Optional filter criteria (date range, minimum messages)
    /// - Returns: Filtered conversations that meet all criteria
    /// 
    /// Supported filters:
    /// - dateRange: Only include conversations within start/end dates
    /// - minMessages: Only include conversations with at least N messages
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
    
    /// Validates conversations against configured rules
    /// Currently checks that conversations have meaningful content
    /// 
    /// - Parameters:
    ///   - conversations: Conversations to validate
    ///   - config: Validation configuration with rules
    /// - Returns: Array of validation results, one per conversation
    /// 
    /// Current validation:
    /// - Checks that conversation text is not empty
    /// - Can be extended with custom validation rules
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
    
    /// Calculates the percentage of validations that passed
    /// 
    /// - Parameter validationResults: Optional array of validation results
    /// - Returns: Pass rate from 0.0 to 1.0 (1.0 = 100% passed, 0.0 = all failed)
    /// 
    /// Returns 1.0 if no validation results (nothing failed)
    private func calculatePassRate(_ validationResults: [ValidationResult]?) -> Double {
        guard let results = validationResults, !results.isEmpty else { return 1.0 }
        
        let passedCount = results.filter { $0.passed }.count
        return Double(passedCount) / Double(results.count)
    }
    
    /// Analyzes how well the bot retains context from earlier in the conversation
    /// Measures the bot's ability to remember and reference previous messages
    /// 
    /// - Parameter conversations: Conversations to analyze
    /// - Returns: ContextRetentionAnalysis with scores and metrics
    /// 
    /// Analysis includes:
    /// - averageContextScore: How much word overlap between consecutive messages (0-1)
    /// - topicSwitches: Number of times topic changed abruptly
    /// - averageReferenceDistance: How far back the bot references earlier messages
    /// - contextBreaks: Times bot showed confusion about earlier context
    /// 
    /// Higher context score = better memory and coherence
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
    
    /// Extracts meaningful keywords from text by removing stop words
    /// Used for context retention analysis to find topic overlap
    /// 
    /// - Parameter text: Text to extract keywords from
    /// - Returns: Set of lowercase keywords (3+ characters, not stop words)
    /// 
    /// Stop words removed: the, a, an, and, or, but, in, on, at, to, for, etc.
    /// Only keeps words with 3+ characters
    private func extractKeyWords(from text: String) -> Set<String> {
        let stopWords = Set(["the", "a", "an", "and", "or", "but", "in", "on", "at", "to", "for", "of", "with", "by", "from", "is", "are", "was", "were", "be", "been", "being", "have", "has", "had", "do", "does", "did", "will", "would", "could", "should", "may", "might", "can", "i", "you", "he", "she", "it", "we", "they", "this", "that", "these", "those"])
        
        let words = text.lowercased()
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.count > 2 && !stopWords.contains($0) }
        
        return Set(words)
    }
}

/// Loads conversation logs from various file formats
/// Supports JSON, CSV, text, and auto-detection
/// Handles different JSON structures (array of conversations, single conversation, array of messages)
class LogLoader {
    /// Loads conversations from a log file
    /// 
    /// - Parameter source: Log source with file path and format
    /// - Returns: Array of parsed conversations
    /// - Throws: AnalysisError if file not found or parsing fails
    /// 
    /// Supported formats:
    /// - .json: Parses as ConversationHistory array, single conversation, or message array
    /// - .csv: Parses CSV with timestamp, sender, content columns
    /// - .text: Parses plain text with alternating user/bot messages
    /// - .auto: Detects format from file extension or tries all parsers
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
    
    /// Parses JSON log data into conversations
    /// Tries multiple JSON structures to be flexible
    /// 
    /// - Parameter data: Raw JSON data
    /// - Returns: Array of conversations
    /// - Throws: AnalysisError if no valid JSON structure found
    /// 
    /// Tries in order:
    /// 1. Array of ConversationHistory objects
    /// 2. Single ConversationHistory object
    /// 3. Array of ConversationMessage objects (creates single conversation)
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
    
    /// Parses CSV log data into a single conversation
    /// 
    /// - Parameter data: Raw CSV data
    /// - Returns: Array with one conversation containing all messages
    /// - Throws: AnalysisError if CSV is invalid or empty
    /// 
    /// Expected CSV format:
    /// - Header row (skipped)
    /// - Data rows: timestamp, sender, content
    /// - Sender containing "bot" is treated as target, otherwise patience
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
    
    /// Parses plain text log into a single conversation
    /// Assumes alternating user/bot messages
    /// 
    /// - Parameter data: Raw text data
    /// - Returns: Array with one conversation
    /// - Throws: AnalysisError if text cannot be read as UTF-8
    /// 
    /// Format:
    /// - Each non-empty line is a message
    /// - Even lines (0, 2, 4...) are from patience
    /// - Odd lines (1, 3, 5...) are from target bot
    /// - Timestamps are fake (1 minute apart)
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
    
    /// Auto-detects log format and parses accordingly
    /// First tries file extension, then tries all parsers
    /// 
    /// - Parameters:
    ///   - data: Raw log data
    ///   - url: File URL (used to check extension)
    /// - Returns: Array of conversations
    /// - Throws: AnalysisError if all parsing attempts fail
    /// 
    /// Detection order:
    /// 1. Check file extension (.json, .csv, .txt, .log)
    /// 2. Try JSON parser
    /// 3. Try CSV parser
    /// 4. Try text parser
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

/// Calculates statistical metrics from conversation data
/// Provides quantitative analysis of conversation patterns
class MetricsCalculator {
    /// Calculates metrics from conversations
    /// 
    /// - Parameter conversations: Conversations to analyze
    /// - Returns: AnalysisMetrics with calculated values
    /// 
    /// Metrics calculated:
    /// - totalMessages: Sum of all messages across all conversations
    /// - averageMessagesPerConversation: Mean messages per conversation
    /// - averageResponseTime: Mean response time if available in validation results
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

/// Detects common patterns in conversation data
/// Identifies recurring behaviors and message types
class PatternDetector {
    /// Detects patterns across all conversations
    /// 
    /// - Parameter conversations: Conversations to analyze
    /// - Returns: Array of detected patterns with frequency and confidence
    /// 
    /// Patterns detected:
    /// - Greeting patterns (hello, hi, hey, etc.)
    /// - Question patterns (messages ending with ?)
    /// - Error patterns (error, sorry, can't, unable, etc.)
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
    
    /// Detects greeting patterns in conversations
    /// Looks for common greeting words in patience messages
    /// 
    /// - Parameter conversations: Conversations to analyze
    /// - Returns: DetectedPattern if greetings found, nil otherwise
    /// 
    /// Greeting words: hello, hi, hey, greetings, good morning, good afternoon
    /// Confidence: Ratio of conversations with greetings to total conversations
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
    
    /// Detects question patterns in conversations
    /// Counts messages from patience that contain question marks
    /// 
    /// - Parameter conversations: Conversations to analyze
    /// - Returns: DetectedPattern if questions found, nil otherwise
    /// 
    /// Simple detection: Any message with "?" is counted as a question
    /// Confidence: Fixed at 0.9 (high confidence in this simple pattern)
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
    
    /// Detects error patterns in target bot responses
    /// Looks for error-related words in bot messages
    /// 
    /// - Parameter conversations: Conversations to analyze
    /// - Returns: DetectedPattern if errors found, nil otherwise
    /// 
    /// Error words: error, sorry, can't, unable, failed, problem
    /// Confidence: Fixed at 0.8 (fairly confident but some false positives possible)
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

/// Errors that can occur during log analysis
/// LocalizedError: Provides user-friendly error messages
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

