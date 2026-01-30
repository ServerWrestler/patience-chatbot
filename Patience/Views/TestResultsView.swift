import SwiftUI

struct TestResultsView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @State private var selectedResultId: TestResults.ID?
    @State private var searchText = ""
    
    var filteredResults: [TestResults] {
        let results = searchText.isEmpty ? appState.testResults : appState.testResults.filter { result in
            result.scenarioResults.contains { scenario in
                scenario.scenarioName.localizedCaseInsensitiveContains(searchText)
            }
        }
        // Sort by start time descending (most recent first)
        return results.sorted(by: { $0.startTime > $1.startTime })
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if appState.testResults.isEmpty {
                    if #available(macOS 14.0, *) {
                        ContentUnavailableView(
                            "No Test Results",
                            systemImage: "play.circle",
                            description: Text("Run some tests to see results here")
                        )
                    } else {
                        VStack(spacing: 8) {
                            Image(systemName: "play.circle")
                                .font(.largeTitle)
                                .foregroundColor(.secondary)
                            Text("No Test Results")
                                .font(.headline)
                            Text("Run some tests to see results here")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                } else {
                    HSplitView {
                        // Left: Results list
                        VStack(alignment: .leading, spacing: 0) {
                            // Search bar
                            HStack {
                                Image(systemName: "magnifyingglass")
                                    .foregroundColor(.secondary)
                                
                                TextField("Search results...", text: $searchText)
                                    .textFieldStyle(.plain)
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background(Color(.controlBackgroundColor))
                            .cornerRadius(8)
                            .padding()
                            
                            // Results list
                            List(filteredResults, selection: $selectedResultId) { result in
                                TestResultRow(result: result)
                            }
                            .listStyle(.sidebar)
                        }
                        .frame(minWidth: 300)
                        
                        // Right: Result detail
                        VStack {
                            if let selectedId = selectedResultId, let result = filteredResults.first(where: { $0.id == selectedId }) {
                                TestResultDetailContentView(result: result)
                            } else {
                                if #available(macOS 14.0, *) {
                                    ContentUnavailableView(
                                        "Select a Test Result",
                                        systemImage: "play.circle",
                                        description: Text("Choose a test result to view details")
                                    )
                                } else {
                                    VStack(spacing: 8) {
                                        Image(systemName: "play.circle")
                                            .font(.largeTitle)
                                            .foregroundColor(.secondary)
                                        Text("Select a Test Result")
                                            .font(.headline)
                                        Text("Choose a test result to view details")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                }
            }
            .navigationTitle("Test Results")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button("Clear All") {
                        appState.testResults.removeAll()
                    }
                    .disabled(appState.testResults.isEmpty)
                }
            }
        }
    }
}

struct TestResultRow: View {
    let result: TestResults
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Test Run")
                        .font(.headline)
                    
                    Text(formatDate(result.startTime))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 4) {
                        Text("\(result.summary.passed)")
                            .foregroundColor(.green)
                            .fontWeight(.semibold)
                        Text("/")
                            .foregroundColor(.secondary)
                        Text("\(result.summary.total)")
                            .fontWeight(.semibold)
                    }
                    .font(.caption)
                    
                    let passRate = result.summary.passRate * 100
                    Text("\(Int(passRate))%")
                        .font(.caption2)
                        .foregroundColor(passRate >= 80 ? .green : passRate >= 60 ? .orange : .red)
                }
            }
            
            // Scenario summary
            HStack {
                ForEach(result.scenarioResults.prefix(2), id: \.scenarioId) { scenario in
                    HStack(spacing: 2) {
                        Image(systemName: scenario.passed ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(scenario.passed ? .green : .red)
                            .font(.caption2)
                        
                        Text(scenario.scenarioName)
                            .font(.caption2)
                            .lineLimit(1)
                    }
                }
                
                if result.scenarioResults.count > 2 {
                    Text("+\(result.scenarioResults.count - 2)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            if let duration = result.endTime?.timeIntervalSince(result.startTime) {
                Text("Duration: \(formatDuration(duration))")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        if duration < 60 {
            return String(format: "%.1fs", duration)
        } else {
            let minutes = Int(duration / 60)
            let seconds = Int(duration.truncatingRemainder(dividingBy: 60))
            return "\(minutes)m \(seconds)s"
        }
    }
}

struct TestResultDetailContentView: View {
    let result: TestResults
    @State private var selectedScenarioId: ScenarioResult.ID?
    
    var body: some View {
        VStack(spacing: 0) {
            // Result header
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Test Results")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Run ID: \(result.testRunId)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Text("Started: \(formatDateTime(result.startTime))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button("Export") {
                        exportResult()
                    }
                    .buttonStyle(.bordered)
                }
                
                // Summary metrics
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 16) {
                    MetricCard(title: "Total", value: "\(result.summary.total)")
                    MetricCard(title: "Passed", value: "\(result.summary.passed)")
                    MetricCard(title: "Failed", value: "\(result.summary.failed)")
                    
                    let passRate = result.summary.passRate * 100
                    MetricCard(title: "Pass Rate", value: "\(Int(passRate))%")
                }
            }
            .padding()
            .background(Color(.controlBackgroundColor))
            
            Divider()
            
            // Scenario results
            HSplitView {
                // Left: Scenario list
                VStack(alignment: .leading, spacing: 0) {
                    Text("Scenarios")
                        .font(.headline)
                        .padding()
                    
                    List(result.scenarioResults, selection: $selectedScenarioId) { scenario in
                        ScenarioResultListRow(scenario: scenario)
                    }
                    .listStyle(.sidebar)
                }
                .frame(minWidth: 250)
                
                // Right: Scenario detail
                VStack {
                    if let selectedId = selectedScenarioId, let scenario = result.scenarioResults.first(where: { $0.id == selectedId }) {
                        ScenarioDetailView(scenario: scenario)
                    } else {
                        if #available(macOS 14.0, *) {
                            ContentUnavailableView(
                                "Select a Scenario",
                                systemImage: "list.bullet",
                                description: Text("Choose a scenario to view conversation details")
                            )
                        } else {
                            VStack(spacing: 8) {
                                Image(systemName: "list.bullet")
                                    .font(.largeTitle)
                                    .foregroundColor(.secondary)
                                Text("Select a Scenario")
                                    .font(.headline)
                                Text("Choose a scenario to view conversation details")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
    
    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func exportResult() {
        let generator = ReportGenerator()
        let report = generator.generateReport(from: result)
        
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "test-result-\(result.testRunId).json"
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                let content = generator.formatReport(report, format: .json)
                
                do {
                    try content.write(to: url, atomically: true, encoding: .utf8)
                } catch {
                    print("Failed to export result: \(error)")
                }
            }
        }
    }
}

struct ScenarioResultListRow: View {
    let scenario: ScenarioResult
    
    var body: some View {
        HStack {
            Image(systemName: scenario.passed ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(scenario.passed ? .green : .red)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(scenario.scenarioName)
                    .font(.body)
                    .lineLimit(1)
                
                HStack {
                    Text("\(scenario.conversationHistory.messages.count) messages")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text(formatDuration(scenario.duration))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 2)
    }
    
    private func formatDuration(_ duration: Double) -> String {
        if duration < 1 {
            return String(format: "%.0fms", duration * 1000)
        } else {
            return String(format: "%.1fs", duration)
        }
    }
}

#Preview {
    TestResultsView()
        .environmentObject(AppState())
}
