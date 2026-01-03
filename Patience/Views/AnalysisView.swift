import SwiftUI
import UniformTypeIdentifiers

struct AnalysisView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedConfigId: AnalysisConfig.ID?
    @State private var showingConfigEditor = false
    @State private var showingFilePicker = false
    
    /// Combined state for editing - prevents race conditions between button click and sheet presentation
    /// Uses enum to ensure config data and presentation state are always in sync
    @State private var editingState: EditingState = .none
    
    /// Enum to manage editing state robustly
    /// Prevents SwiftUI race conditions where config becomes nil between button click and sheet presentation
    fileprivate enum EditingState {
        case none
        case editing(AnalysisConfig)
        
        var isPresented: Bool {
            switch self {
            case .none: return false
            case .editing: return true
            }
        }
        
        var config: AnalysisConfig? {
            switch self {
            case .none: return nil
            case .editing(let config): return config
            }
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text("Log Analysis")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text("Analyze historical chat logs and conversations")
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                HStack(spacing: 12) {
                    Button("Import Log File") {
                        showingFilePicker = true
                    }
                    .buttonStyle(.bordered)
                    
                    Button("New Analysis") {
                        showingConfigEditor = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
            
            Divider()
            
            if appState.analysisConfigs.isEmpty && appState.analysisResults.isEmpty {
                // Empty state with drag and drop
                VStack(spacing: 20) {
                    if #available(macOS 14.0, *) {
                        ContentUnavailableView(
                            "No Analysis Configurations",
                            systemImage: "chart.bar",
                            description: Text("Create an analysis configuration or drag a log file here to get started")
                        )
                    } else {
                        VStack(spacing: 8) {
                            Image(systemName: "chart.bar")
                                .font(.largeTitle)
                                .foregroundColor(.secondary)
                            Text("No Analysis Configurations")
                                .font(.headline)
                            Text("Create an analysis configuration or drag a log file here to get started")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    VStack(spacing: 12) {
                        Image(systemName: "arrow.down.doc")
                            .font(.system(size: 48))
                            .foregroundColor(.blue.opacity(0.6))
                        
                        Text("Drag log files here")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("Supports JSON, CSV, and text formats")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(40)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(style: StrokeStyle(lineWidth: 2, dash: [8]))
                            .foregroundColor(.blue.opacity(0.3))
                    )
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .onDrop(of: [.fileURL], isTargeted: nil) { providers in
                    handleFileDrop(providers: providers)
                }
            } else {
                // Analysis interface
                HSplitView {
                    // Left: Configurations and results
                    VStack(alignment: .leading, spacing: 0) {
                        // Configurations section
                        if !appState.analysisConfigs.isEmpty {
                            VStack(alignment: .leading, spacing: 0) {
                                Text("Configurations")
                                    .font(.headline)
                                    .padding()
                                
                                List(appState.analysisConfigs, selection: $selectedConfigId) { config in
                                    AnalysisConfigRow(config: config)
                                }
                                .listStyle(.sidebar)
                                .frame(maxHeight: 200)
                            }
                        }
                        
                        // Results section
                        if !appState.analysisResults.isEmpty {
                            VStack(alignment: .leading, spacing: 0) {
                                Text("Analysis Results")
                                    .font(.headline)
                                    .padding()
                                
                                List(appState.analysisResults) { result in
                                    AnalysisResultRow(result: result)
                                }
                                .listStyle(.sidebar)
                            }
                        }
                    }
                    .frame(minWidth: 300)
                    
                    // Right: Analysis panel
                    VStack {
                        if let selectedId = selectedConfigId, let config = appState.analysisConfigs.first(where: { $0.id == selectedId }) {
                            AnalysisExecutionPanel(config: config)
                        } else if let result = appState.analysisResults.first {
                            AnalysisResultDetailView(result: result)
                        } else {
                            if #available(macOS 14.0, *) {
                                ContentUnavailableView(
                                    "Select an Analysis",
                                    systemImage: "chart.bar",
                                    description: Text("Choose a configuration or result to view details")
                                )
                            } else {
                                VStack(spacing: 8) {
                                    Image(systemName: "chart.bar")
                                        .font(.largeTitle)
                                        .foregroundColor(.secondary)
                                    Text("Select an Analysis")
                                        .font(.headline)
                                    Text("Choose a configuration or result to view details")
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
        .sheet(isPresented: $showingConfigEditor) {
            AnalysisConfigEditorView()
        }
        .sheet(isPresented: Binding(
            get: { editingState.isPresented },
            set: { if !$0 { editingState = .none } }
        )) {
            AnalysisConfigEditorView(initialConfig: editingState.config) { updatedConfig in
                appState.updateAnalysisConfig(updatedConfig)
                editingState = .none
            }
        }
        .fileImporter(
            isPresented: $showingFilePicker,
            allowedContentTypes: [.json, .commaSeparatedText, .plainText],
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result: result)
        }
    }
    
    private func handleFileDrop(providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        
        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, error in
            guard let data = item as? Data,
                  let url = URL(dataRepresentation: data, relativeTo: nil) else {
                return
            }
            
            DispatchQueue.main.async {
                createAnalysisFromFile(url: url)
            }
        }
        
        return true
    }
    
    private func handleFileImport(result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            if let url = urls.first {
                createAnalysisFromFile(url: url)
            }
        case .failure(let error):
            print("File import failed: \(error)")
        }
    }
    
    private func createAnalysisFromFile(url: URL) {
        let format = detectLogFormat(from: url)
        
        let config = AnalysisConfig(
            logSource: LogSource(path: url.path, format: format),
            filters: nil,
            validation: nil,
            analysis: AnalysisSettings(
                calculateMetrics: true,
                detectPatterns: true,
                checkContextRetention: true
            ),
            reporting: ReportConfig(
                outputPath: appState.defaultOutputPath,
                formats: [.html, .json],
                includeConversationHistory: true,
                verboseErrors: false
            )
        )
        
        appState.addAnalysisConfig(config)
        selectedConfigId = config.id
        
        // Automatically run analysis
        Task {
            await appState.runAnalysis(config: config)
        }
    }
    
    private func detectLogFormat(from url: URL) -> LogFormat {
        let pathExtension = url.pathExtension.lowercased()
        
        switch pathExtension {
        case "json":
            return .json
        case "csv":
            return .csv
        case "txt", "log":
            return .text
        default:
            return .auto
        }
    }
}

struct AnalysisConfigRow: View {
    let config: AnalysisConfig
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(URL(fileURLWithPath: config.logSource.path).lastPathComponent)
                    .font(.headline)
                    .lineLimit(1)
                
                Spacer()
                
                Text(config.logSource.format.rawValue.uppercased())
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.green.opacity(0.2))
                    .foregroundColor(.green)
                    .cornerRadius(4)
            }
            
            Text(config.logSource.path)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
            
            HStack {
                if config.analysis.calculateMetrics {
                    Text("Metrics")
                        .font(.caption2)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color.blue.opacity(0.2))
                        .foregroundColor(.blue)
                        .cornerRadius(2)
                }
                
                if config.analysis.detectPatterns {
                    Text("Patterns")
                        .font(.caption2)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color.purple.opacity(0.2))
                        .foregroundColor(.purple)
                        .cornerRadius(2)
                }
                
                Spacer()
            }
        }
        .padding(.vertical, 4)
        .contextMenu {
            Button("Run Analysis") {
                Task {
                    await appState.runAnalysis(config: config)
                }
            }
            
            Button("Edit") {
                // Edit configuration
            }
            
            Divider()
            
            Button("Delete", role: .destructive) {
                appState.deleteAnalysisConfig(config)
            }
        }
    }
}

struct AnalysisResultRow: View {
    let result: AnalysisResults
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Analysis Result")
                    .font(.headline)
                
                Spacer()
                
                Text("\(Int(result.summary.overallPassRate * 100))%")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(result.summary.overallPassRate > 0.8 ? Color.green.opacity(0.2) : Color.orange.opacity(0.2))
                    .foregroundColor(result.summary.overallPassRate > 0.8 ? .green : .orange)
                    .cornerRadius(4)
            }
            
            HStack {
                Text("\(result.summary.analyzedConversations) conversations")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if let patterns = result.patterns {
                    Text("\(patterns.count) patterns")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct AnalysisExecutionPanel: View {
    let config: AnalysisConfig
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(spacing: 20) {
            // Configuration details
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Analysis Configuration")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Button("Edit") {
                        // Edit configuration
                    }
                    .buttonStyle(.bordered)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    InfoRow(label: "Log File", value: URL(fileURLWithPath: config.logSource.path).lastPathComponent)
                    InfoRow(label: "Format", value: config.logSource.format.rawValue.uppercased())
                    InfoRow(label: "Metrics", value: config.analysis.calculateMetrics ? "Enabled" : "Disabled")
                    InfoRow(label: "Patterns", value: config.analysis.detectPatterns ? "Enabled" : "Disabled")
                }
            }
            .padding()
            .background(Color(.controlBackgroundColor))
            .cornerRadius(8)
            
            // Analysis execution controls
            VStack(spacing: 16) {
                if appState.isRunningAnalysis {
                    VStack(spacing: 12) {
                        ProgressView()
                            .progressViewStyle(.circular)
                        
                        Text("Analyzing log file...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Button("Cancel") {
                            // Cancel analysis
                        }
                        .buttonStyle(.bordered)
                    }
                } else {
                    Button("Run Analysis") {
                        Task {
                            await appState.runAnalysis(config: config)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
            }
            
            Spacer()
        }
        .padding()
    }
}

struct AnalysisResultDetailView: View {
    let result: AnalysisResults
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Summary
                VStack(alignment: .leading, spacing: 12) {
                    Text("Analysis Summary")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                        MetricCard(title: "Total Conversations", value: "\(result.summary.totalConversations)")
                        MetricCard(title: "Analyzed", value: "\(result.summary.analyzedConversations)")
                        MetricCard(title: "Pass Rate", value: "\(Int(result.summary.overallPassRate * 100))%")
                        MetricCard(title: "Processing Time", value: "\(Int(result.summary.processingTime))ms")
                    }
                }
                
                // Metrics
                if let metrics = result.metrics {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Metrics")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                            MetricCard(title: "Total Messages", value: "\(metrics.totalMessages)")
                            MetricCard(title: "Avg Messages/Conv", value: String(format: "%.1f", metrics.averageMessagesPerConversation))
                            
                            if let avgResponseTime = metrics.averageResponseTime {
                                MetricCard(title: "Avg Response Time", value: String(format: "%.2fs", avgResponseTime))
                            }
                        }
                    }
                }
                
                // Patterns
                if let patterns = result.patterns, !patterns.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Detected Patterns")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        LazyVStack(spacing: 12) {
                            ForEach(patterns) { pattern in
                                PatternCard(pattern: pattern)
                            }
                        }
                    }
                }
            }
            .padding()
        }
    }
}

struct MetricCard: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }
}

struct PatternCard: View {
    let pattern: DetectedPattern
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(pattern.type.capitalized)
                    .font(.headline)
                
                Spacer()
                
                Text("\(Int(pattern.confidence * 100))%")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.2))
                    .foregroundColor(.blue)
                    .cornerRadius(4)
            }
            
            Text(pattern.pattern)
                .font(.body)
            
            Text("Frequency: \(pattern.frequency)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }
}

#Preview {
    AnalysisView()
        .environmentObject(AppState())
}
