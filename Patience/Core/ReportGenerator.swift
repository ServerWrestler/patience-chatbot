import Foundation

/// Generates formatted test reports from test results
/// Supports multiple output formats: JSON, HTML, and Markdown
/// 
/// Key features:
/// - Converts TestResults into formatted reports
/// - Sanitizes sensitive data (API keys, tokens) before output
/// - Generates professional HTML reports with styling
/// - Creates machine-readable JSON reports
/// - Produces human-readable Markdown reports
/// 
/// All reports include:
/// - Summary statistics (pass/fail counts, pass rate)
/// - Individual scenario results
/// - Conversation history
/// - Validation results
/// - Error messages
class ReportGenerator {
    /// Generates a TestReport from test execution results
    /// This is the main entry point for report generation
    /// 
    /// - Parameter results: Test results from TestExecutor
    /// - Returns: TestReport with summary and scenario results
    /// 
    /// The report includes:
    /// - Timestamp of report generation
    /// - Total/passed/failed scenario counts
    /// - All scenario results with conversation history
    /// - Text summary of the test run
    func generateReport(from results: TestResults) -> TestReport {
        let summary = generateSummary(from: results)
        
        return TestReport(
            timestamp: Date(),
            totalScenarios: results.summary.total,
            passedScenarios: results.summary.passed,
            failedScenarios: results.summary.failed,
            scenarioResults: results.scenarioResults,
            summary: summary
        )
    }
    
    /// Formats a report in the specified format
    /// 
    /// - Parameters:
    ///   - report: The report to format
    ///   - format: Output format (json, html, markdown)
    /// - Returns: Formatted report as a string
    /// 
    /// Format details:
    /// - .json: Machine-readable JSON with pretty printing
    /// - .html: Professional HTML with CSS styling and colors
    /// - .markdown: Human-readable Markdown with tables and formatting
    func formatReport(_ report: TestReport, format: ReportFormat) -> String {
        switch format {
        case .json:
            return formatAsJSON(report)
        case .html:
            return formatAsHTML(report)
        case .markdown:
            return formatAsMarkdown(report)
        }
    }
    
    /// Generates a text summary of test results
    /// 
    /// - Parameter results: Test results to summarize
    /// - Returns: Multi-line text summary
    /// 
    /// Summary includes:
    /// - Test run ID and timestamps
    /// - Duration of test execution
    /// - Pass/fail counts and pass rate percentage
    /// - List of failed scenarios with error messages
    private func generateSummary(from results: TestResults) -> String {
        let passRate = results.summary.passRate * 100
        let duration = results.endTime?.timeIntervalSince(results.startTime) ?? 0
        
        var summary = """
        Test Execution Summary
        =====================
        
        Test Run ID: \(results.testRunId)
        Start Time: \(formatDate(results.startTime))
        End Time: \(formatDate(results.endTime ?? Date()))
        Duration: \(formatDuration(duration))
        
        Results:
        - Total Scenarios: \(results.summary.total)
        - Passed: \(results.summary.passed)
        - Failed: \(results.summary.failed)
        - Pass Rate: \(String(format: "%.1f", passRate))%
        
        """
        
        if results.summary.failed > 0 {
            summary += "\nFailed Scenarios:\n"
            for result in results.scenarioResults where !result.passed {
                summary += "- \(result.scenarioName): \(result.error ?? "Validation failed")\n"
            }
        }
        
        return summary
    }
    
    /// Formats report as JSON
    /// 
    /// - Parameter report: Report to format
    /// - Returns: Pretty-printed JSON string
    /// 
    /// Features:
    /// - Sanitizes sensitive data before encoding
    /// - Uses ISO8601 date format
    /// - Pretty-printed with sorted keys for readability
    /// - Redacts long strings that might be API keys/tokens
    /// 
    /// Safe to share: All sensitive data is replaced with "***REDACTED***"
    private func formatAsJSON(_ report: TestReport) -> String {
        // Sanitize sensitive data before encoding
        var sanitizedReport = report
        sanitizedReport.scenarioResults = report.scenarioResults.map { scenario in
            var sanitized = scenario
            sanitized.conversationHistory.messages = scenario.conversationHistory.messages.map { message in
                var msg = message
                msg.content = redactSensitive(message.content)
                return msg
            }
            sanitized.validationResults = scenario.validationResults.map { validation in
                var val = validation
                val.actual = redactSensitive(validation.actual)
                return val
            }
            return sanitized
        }
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        
        do {
            let data = try encoder.encode(sanitizedReport)
            return String(data: data, encoding: .utf8) ?? "Error encoding JSON"
        } catch {
            return "Error generating JSON report: \(error.localizedDescription)"
        }
    }
    
    /// Formats report as HTML with professional styling
    /// 
    /// - Parameter report: Report to format
    /// - Returns: Complete HTML document with embedded CSS
    /// 
    /// HTML features:
    /// - Responsive grid layout for metrics
    /// - Color-coded pass/fail indicators (green/red)
    /// - Pass rate color changes based on threshold (green ≥80%, orange ≥60%, red <60%)
    /// - Expandable scenario cards with conversation history
    /// - User messages in blue, bot messages in purple
    /// - Validation results with pass/fail styling
    /// - Box shadows and rounded corners for modern look
    /// 
    /// Safe to share: Sensitive data is redacted and HTML-escaped
    private func formatAsHTML(_ report: TestReport) -> String {
        let passRate = Double(report.passedScenarios) / Double(report.totalScenarios) * 100
        let statusColor = passRate >= 80 ? "green" : passRate >= 60 ? "orange" : "red"
        
        var html = """
        <!DOCTYPE html>
        <html>
        <head>
            <meta charset="UTF-8">
            <title>Patience Test Report</title>
            <style>
                body { font-family: -apple-system, BlinkMacSystemFont, sans-serif; margin: 40px; }
                .header { background: #f5f5f5; padding: 20px; border-radius: 8px; margin-bottom: 20px; }
                .summary { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 20px; margin-bottom: 30px; }
                .metric { background: white; padding: 15px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
                .metric-value { font-size: 24px; font-weight: bold; color: \(statusColor); }
                .scenario { border: 1px solid #ddd; border-radius: 8px; margin-bottom: 15px; overflow: hidden; }
                .scenario-header { background: #f8f9fa; padding: 15px; border-bottom: 1px solid #ddd; }
                .scenario-content { padding: 15px; }
                .passed { border-left: 4px solid green; }
                .failed { border-left: 4px solid red; }
                .message { background: #f8f9fa; padding: 10px; margin: 5px 0; border-radius: 4px; }
                .user-message { background: #e3f2fd; }
                .bot-message { background: #f3e5f5; }
                .validation { margin-top: 10px; padding: 10px; border-radius: 4px; }
                .validation.passed { background: #d4edda; color: #155724; }
                .validation.failed { background: #f8d7da; color: #721c24; }
                .status-icon { font-weight: bold; }
                .status-pass { color: green; }
                .status-fail { color: red; }
            </style>
        </head>
        <body>
            <div class="header">
                <h1>Patience Test Report</h1>
                <p>Generated on \(formatDate(report.timestamp))</p>
            </div>
            
            <div class="summary">
                <div class="metric">
                    <div class="metric-label">Total Scenarios</div>
                    <div class="metric-value">\(report.totalScenarios)</div>
                </div>
                <div class="metric">
                    <div class="metric-label">Passed</div>
                    <div class="metric-value" style="color: green;">\(report.passedScenarios)</div>
                </div>
                <div class="metric">
                    <div class="metric-label">Failed</div>
                    <div class="metric-value" style="color: red;">\(report.failedScenarios)</div>
                </div>
                <div class="metric">
                    <div class="metric-label">Pass Rate</div>
                    <div class="metric-value">\(String(format: "%.1f", passRate))%</div>
                </div>
            </div>
            
            <h2>Scenario Results</h2>
        """
        
        for result in report.scenarioResults {
            let statusClass = result.passed ? "passed" : "failed"
            let statusIcon = result.passed ? "<span class=\"status-icon status-pass\">PASS</span>" : "<span class=\"status-icon status-fail\">FAIL</span>"
            
            html += """
            <div class="scenario \(statusClass)">
                <div class="scenario-header">
                    <h3>\(statusIcon) \(result.scenarioName)</h3>
                    <p>Duration: \(formatDuration(result.duration))</p>
                </div>
                <div class="scenario-content">
            """
            
            // Add conversation messages
            for message in result.conversationHistory.messages {
                let messageClass = message.sender == .patience ? "user-message" : "bot-message"
                let senderLabel = message.sender == .patience ? "User" : "Bot"
                
                html += """
                <div class="message \(messageClass)">
                    <strong>\(senderLabel):</strong> \(escapeHTML(redactSensitive(message.content)))
                    <small>(\(formatTime(message.timestamp)))</small>
                </div>
                """
            }
            
            // Add validation results
            for validation in result.validationResults {
                let validationClass = validation.passed ? "passed" : "failed"
                let validationIcon = validation.passed ? "<span class=\"status-icon status-pass\">PASS</span>" : "<span class=\"status-icon status-fail\">FAIL</span>"
                
                html += """
                <div class="validation \(validationClass)">
                    \(validationIcon) \(validation.message ?? "Validation result")
                    <br><small>Expected: \(validation.expected ?? "N/A")</small>
                    <br><small>Actual: \(escapeHTML(redactSensitive(validation.actual)))</small>
                </div>
                """
            }
            
            if let error = result.error {
                html += """
                <div class="validation failed">
                    <span class="status-icon status-fail">ERROR</span> \(escapeHTML(error))
                </div>
                """
            }
            
            html += """
                </div>
            </div>
            """
        }
        
        html += """
        </body>
        </html>
        """
        
        return html
    }
    
    /// Formats report as Markdown
    /// 
    /// - Parameter report: Report to format
    /// - Returns: Markdown-formatted string
    /// 
    /// Markdown features:
    /// - Summary table with metrics
    /// - Scenario sections with headers
    /// - Emoji indicators (✅ for pass, ❌ for fail)
    /// - Conversation history with bold sender labels
    /// - Code blocks for errors
    /// - Horizontal rules between scenarios
    /// 
    /// Great for: GitHub, documentation, README files
    /// Safe to share: Sensitive data is redacted
    private func formatAsMarkdown(_ report: TestReport) -> String {
        let passRate = Double(report.passedScenarios) / Double(report.totalScenarios) * 100
        
        var markdown = """
        # Patience Test Report
        
        **Generated:** \(formatDate(report.timestamp))
        
        ## Summary
        
        | Metric | Value |
        |--------|-------|
        | Total Scenarios | \(report.totalScenarios) |
        | Passed | \(report.passedScenarios) |
        | Failed | \(report.failedScenarios) |
        | Pass Rate | \(String(format: "%.1f", passRate))% |
        
        ## Scenario Results
        
        """
        
        for result in report.scenarioResults {
            let statusIcon = result.passed ? "✅" : "❌"
            
            markdown += """
            ### \(statusIcon) \(result.scenarioName)
            
            **Duration:** \(formatDuration(result.duration))
            
            #### Conversation
            
            """
            
            for message in result.conversationHistory.messages {
                let senderLabel = message.sender == .patience ? "**User**" : "**Bot**"
                markdown += "\(senderLabel): \(redactSensitive(message.content))\n\n"
            }
            
            if !result.validationResults.isEmpty {
                markdown += "#### Validation Results\n\n"
                
                for validation in result.validationResults {
                    let validationIcon = validation.passed ? "✅" : "❌"
                    markdown += "- \(validationIcon) \(validation.message ?? "Validation result")\n"
                    
                    if let expected = validation.expected {
                        markdown += "  - Expected: `\(expected)`\n"
                    }
                    markdown += "  - Actual: `\(redactSensitive(validation.actual))`\n"
                }
                
                markdown += "\n"
            }
            
            if let error = result.error {
                markdown += "#### Error\n\n```\n\(error)\n```\n\n"
            }
            
            markdown += "---\n\n"
        }
        
        return markdown
    }
    
    // MARK: - Helper Methods
    
    /// Formats a date for display in reports
    /// Uses medium date style and medium time style
    /// 
    /// - Parameter date: Date to format
    /// - Returns: Formatted string like "Jan 15, 2024, 2:30:45 PM"
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }
    
    /// Formats a time for display (no date)
    /// Uses medium time style
    /// 
    /// - Parameter date: Date to extract time from
    /// - Returns: Formatted string like "2:30:45 PM"
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }
    
    /// Formats a duration in seconds to human-readable string
    /// 
    /// - Parameter duration: Duration in seconds
    /// - Returns: Formatted string with appropriate units
    /// 
    /// Format examples:
    /// - < 60s: "5.2s"
    /// - < 1h: "3m 45s"
    /// - ≥ 1h: "2h 15m"
    private func formatDuration(_ duration: Double) -> String {
        if duration < 60 {
            return String(format: "%.1fs", duration)
        } else if duration < 3600 {
            let minutes = Int(duration / 60)
            let seconds = Int(duration.truncatingRemainder(dividingBy: 60))
            return "\(minutes)m \(seconds)s"
        } else {
            let hours = Int(duration / 3600)
            let minutes = Int((duration.truncatingRemainder(dividingBy: 3600)) / 60)
            return "\(hours)h \(minutes)m"
        }
    }
    
    /// Escapes special HTML characters to prevent injection
    /// Essential for safely displaying user-generated content in HTML
    /// 
    /// - Parameter string: String to escape
    /// - Returns: HTML-safe string
    /// 
    /// Escapes:
    /// - & → &amp;
    /// - < → &lt;
    /// - > → &gt;
    /// - " → &quot;
    /// - ' → &#x27;
    private func escapeHTML(_ string: String) -> String {
        return string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#x27;")
    }
    
    /// Redacts potentially sensitive data from text
    /// Replaces long alphanumeric strings that might be API keys or tokens
    /// 
    /// - Parameter text: Text to redact
    /// - Returns: Text with sensitive data replaced with "***REDACTED***"
    /// 
    /// Pattern: Replaces any alphanumeric string (including _ and -) that's 20+ characters
    /// This catches most API keys, tokens, and secrets while preserving normal text
    /// 
    /// Examples:
    /// - "sk-1234567890abcdefghijklmnop" → "***REDACTED***"
    /// - "Hello world" → "Hello world" (unchanged)
    private func redactSensitive(_ text: String) -> String {
        let pattern = "[A-Za-z0-9_\\-]{20,}"
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return text }
        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return regex.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: "***REDACTED***")
    }
}
