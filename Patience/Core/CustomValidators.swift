import Foundation

/// Custom validation rules that can be referenced by name
class CustomValidators {
    
    static func validate(response: BotResponse, validatorName: String) -> ValidationResult {
        switch validatorName.lowercased() {
        case "not_empty":
            return validateNotEmpty(response)
        case "contains_url":
            return validateContainsURL(response)
        case "is_json":
            return validateIsJSON(response)
        case "word_count":
            return validateWordCount(response, min: 5, max: 500)
        case "no_profanity":
            return validateNoProfanity(response)
        case "polite":
            return validatePolite(response)
        case "has_greeting":
            return validateHasGreeting(response)
        case "has_farewell":
            return validateHasFarewell(response)
        case "is_question":
            return validateIsQuestion(response)
        case "is_statement":
            return validateIsStatement(response)
        default:
            return ValidationResult(
                passed: false,
                expected: validatorName,
                actual: response.content,
                message: "Unknown custom validator: \(validatorName)",
                details: ["available": "not_empty, contains_url, is_json, word_count, no_profanity, polite, has_greeting, has_farewell, is_question, is_statement"]
            )
        }
    }
    
    private static func validateNotEmpty(_ response: BotResponse) -> ValidationResult {
        let trimmed = response.content.trimmingCharacters(in: .whitespacesAndNewlines)
        let passed = !trimmed.isEmpty
        
        return ValidationResult(
            passed: passed,
            expected: "Non-empty response",
            actual: response.content,
            message: passed ? "Response is not empty" : "Response is empty",
            details: ["length": String(trimmed.count)]
        )
    }
    
    private static func validateContainsURL(_ response: BotResponse) -> ValidationResult {
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let matches = detector?.matches(in: response.content, range: NSRange(response.content.startIndex..., in: response.content))
        let passed = (matches?.count ?? 0) > 0
        
        return ValidationResult(
            passed: passed,
            expected: "Contains URL",
            actual: response.content,
            message: passed ? "Response contains URL(s)" : "Response does not contain URLs",
            details: ["url_count": String(matches?.count ?? 0)]
        )
    }
    
    private static func validateIsJSON(_ response: BotResponse) -> ValidationResult {
        guard let data = response.content.data(using: .utf8) else {
            return ValidationResult(
                passed: false,
                expected: "Valid JSON",
                actual: response.content,
                message: "Cannot convert to data",
                details: nil
            )
        }
        
        do {
            _ = try JSONSerialization.jsonObject(with: data)
            return ValidationResult(
                passed: true,
                expected: "Valid JSON",
                actual: response.content,
                message: "Response is valid JSON",
                details: nil
            )
        } catch {
            return ValidationResult(
                passed: false,
                expected: "Valid JSON",
                actual: response.content,
                message: "Invalid JSON: \(error.localizedDescription)",
                details: nil
            )
        }
    }
    
    private static func validateWordCount(_ response: BotResponse, min: Int, max: Int) -> ValidationResult {
        let words = response.content.components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
        let count = words.count
        let passed = count >= min && count <= max
        
        return ValidationResult(
            passed: passed,
            expected: "Word count between \(min) and \(max)",
            actual: response.content,
            message: passed ? "Word count is within range" : "Word count is outside range",
            details: ["word_count": String(count), "min": String(min), "max": String(max)]
        )
    }
    
    private static func validateNoProfanity(_ response: BotResponse) -> ValidationResult {
        // Basic profanity check - in production, use a comprehensive list
        let profanityWords = ["damn", "hell", "crap", "stupid", "idiot", "dumb"]
        let lowercased = response.content.lowercased()
        
        for word in profanityWords {
            if lowercased.contains(word) {
                return ValidationResult(
                    passed: false,
                    expected: "No profanity",
                    actual: response.content,
                    message: "Response contains inappropriate language",
                    details: ["found": word]
                )
            }
        }
        
        return ValidationResult(
            passed: true,
            expected: "No profanity",
            actual: response.content,
            message: "Response is appropriate",
            details: nil
        )
    }
    
    private static func validatePolite(_ response: BotResponse) -> ValidationResult {
        let politeWords = ["please", "thank", "sorry", "appreciate", "kindly", "would you", "could you"]
        let lowercased = response.content.lowercased()
        
        let hasPoliteWord = politeWords.contains { lowercased.contains($0) }
        
        return ValidationResult(
            passed: hasPoliteWord,
            expected: "Polite language",
            actual: response.content,
            message: hasPoliteWord ? "Response uses polite language" : "Response could be more polite",
            details: nil
        )
    }
    
    private static func validateHasGreeting(_ response: BotResponse) -> ValidationResult {
        let greetings = ["hello", "hi", "hey", "greetings", "good morning", "good afternoon", "good evening", "welcome"]
        let lowercased = response.content.lowercased()
        
        let hasGreeting = greetings.contains { lowercased.contains($0) }
        
        return ValidationResult(
            passed: hasGreeting,
            expected: "Contains greeting",
            actual: response.content,
            message: hasGreeting ? "Response contains greeting" : "Response does not contain greeting",
            details: nil
        )
    }
    
    private static func validateHasFarewell(_ response: BotResponse) -> ValidationResult {
        let farewells = ["goodbye", "bye", "see you", "farewell", "take care", "have a nice", "talk soon"]
        let lowercased = response.content.lowercased()
        
        let hasFarewell = farewells.contains { lowercased.contains($0) }
        
        return ValidationResult(
            passed: hasFarewell,
            expected: "Contains farewell",
            actual: response.content,
            message: hasFarewell ? "Response contains farewell" : "Response does not contain farewell",
            details: nil
        )
    }
    
    private static func validateIsQuestion(_ response: BotResponse) -> ValidationResult {
        let hasQuestionMark = response.content.contains("?")
        let questionWords = ["what", "when", "where", "who", "why", "how", "which", "whose", "whom"]
        let lowercased = response.content.lowercased()
        
        let hasQuestionWord = questionWords.contains { lowercased.contains($0) }
        let passed = hasQuestionMark || hasQuestionWord
        
        return ValidationResult(
            passed: passed,
            expected: "Is a question",
            actual: response.content,
            message: passed ? "Response is a question" : "Response is not a question",
            details: ["has_question_mark": String(hasQuestionMark), "has_question_word": String(hasQuestionWord)]
        )
    }
    
    private static func validateIsStatement(_ response: BotResponse) -> ValidationResult {
        let hasQuestionMark = response.content.contains("?")
        let passed = !hasQuestionMark && !response.content.isEmpty
        
        return ValidationResult(
            passed: passed,
            expected: "Is a statement",
            actual: response.content,
            message: passed ? "Response is a statement" : "Response is not a statement",
            details: nil
        )
    }
}
