import SwiftUI

struct TestingView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedConfigId: TestConfig.ID?
    @State private var showingConfigEditor = false

    /// Combined state for editing - contains both the config and presentation state
    /// This prevents race conditions between showingEditSheet and editingConfig
    @State private var editingState: EditingState = .none
    
    /// Enum to manage editing state more robustly
    private enum EditingState {
        case none
        case editing(TestConfig)
        
        var isPresented: Bool {
            switch self {
            case .none: return false
            case .editing: return true
            }
        }
        
        var config: TestConfig? {
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
                    Text("Live Testing")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text("Run real-time tests against your chatbot")
                        .foregroundColor(.secondary)
                }

                Spacer()
                
                // Export/Import buttons
                HStack(spacing: 8) {
                    Menu("Import") {
                        Button("Import Configuration...") {
                            appState.importTestConfigs()
                        }
                    }
                    .buttonStyle(.bordered)
                    .disabled(appState.isRunningTest)
                    
                    Menu("Export") {
                        Button("Export All Configurations...") {
                            appState.exportAllTestConfigs()
                        }
                        .disabled(appState.testConfigs.isEmpty)
                    }
                    .buttonStyle(.bordered)
                    .disabled(appState.testConfigs.isEmpty)

                    Button("New Configuration") {
                        showingConfigEditor = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()

            Divider()

            if appState.testConfigs.isEmpty {
                // Empty state
                if #available(macOS 14.0, *) {
                    ContentUnavailableView(
                        "No Test Configurations",
                        systemImage: "play.circle",
                        description: Text("Create your first test configuration to get started")
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "play.circle")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("No Test Configurations")
                            .font(.headline)
                        Text("Create your first test configuration to get started")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            } else {
                // Configuration list and test execution
                HSplitView {
                    // Left: Configuration list
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Configurations")
                            .font(.headline)
                            .padding()

                        List(appState.testConfigs, selection: $selectedConfigId) { config in
                            TestConfigRow(config: config, onEdit: { cfg in
                                // Set editing state atomically - no race condition possible
                                editingState = .editing(cfg)
                            })
                            .contentShape(Rectangle())
                        }
                        .listStyle(.sidebar)
                    }
                    .frame(minWidth: 300)

                    // Right: Test execution panel
                    VStack {
                        if let selectedId = selectedConfigId, let config = appState.testConfigs.first(where: { $0.id == selectedId }) {
                            TestExecutionPanel(config: config, onEdit: { cfg in
                                // Set editing state atomically - no race condition possible
                                editingState = .editing(cfg)
                            })
                        } else {
                            if #available(macOS 14.0, *) {
                                ContentUnavailableView(
                                    "Select a Configuration",
                                    systemImage: "gear",
                                    description: Text("Choose a test configuration to run tests")
                                )
                            } else {
                                VStack(spacing: 8) {
                                    Image(systemName: "gear")
                                        .font(.largeTitle)
                                        .foregroundColor(.secondary)
                                    Text("Select a Configuration")
                                        .font(.headline)
                                    Text("Choose a test configuration to run tests")
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
            TestConfigEditorView()
                .frame(minWidth: 900, minHeight: 700)
                .environmentObject(appState)
        }
        .sheet(isPresented: Binding(
            get: { editingState.isPresented },
            set: { if !$0 { editingState = .none } }
        )) {
            // The config is guaranteed to be available when the sheet is presented
            // because editingState.isPresented is only true when we have a config
            if let configToEdit = editingState.config {
                TestConfigEditorView(initialConfig: configToEdit) { updated in
                    appState.updateTestConfig(updated)
                    // Clear the editing state after successful update
                    editingState = .none
                }
                .frame(minWidth: 900, minHeight: 700)
                .environmentObject(appState)
            }
        }
    }
}

struct TestConfigRow: View {
    let config: TestConfig
    @EnvironmentObject var appState: AppState

    var onEdit: (TestConfig) -> Void = { _ in }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(config.targetBot.name)
                    .font(.headline)

                Spacer()

                Text(config.targetBot.botProtocol.rawValue.uppercased())
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.2))
                    .foregroundColor(.blue)
                    .cornerRadius(4)
            }

            Text(config.targetBot.endpoint)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)

            HStack {
                Text("\(config.scenarios.count) scenarios")
                    .font(.caption2)
                    .foregroundColor(.secondary)

                Spacer()

                if let provider = config.targetBot.provider {
                    Text(provider.rawValue)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
        .contextMenu {
            Button("Edit") {
                onEdit(config)
            }

            Button("Duplicate") {
                var duplicated = config
                duplicated.id = UUID()
                duplicated.targetBot.name = "\(config.targetBot.name) Copy"
                appState.addTestConfig(duplicated)
            }
            
            Divider()
            
            Button("Export...") {
                appState.exportTestConfig(config)
            }
            
            Button("Copy to Clipboard") {
                appState.copyConfigToClipboard(config)
            }

            Divider()

            Button("Delete", role: .destructive) {
                appState.deleteTestConfig(config)
            }
        }
    }
}

struct TestExecutionPanel: View {
    let config: TestConfig
    @EnvironmentObject var appState: AppState
    @State private var showingResults = false

    var onEdit: ((TestConfig) -> Void)? = nil

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Configuration details
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(config.targetBot.name)
                            .font(.title2)
                            .fontWeight(.semibold)

                        Spacer()

                        Button("Edit") {
                            onEdit?(config)
                        }
                        .buttonStyle(.bordered)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        InfoRow(label: "Endpoint", value: config.targetBot.endpoint)
                        InfoRow(label: "Protocol", value: config.targetBot.botProtocol.rawValue.uppercased())
                        InfoRow(label: "Scenarios", value: "\(config.scenarios.count)")
                        InfoRow(label: "Validation", value: config.validation.defaultType.rawValue)
                    }
                }
                .padding()
                .background(Color(.controlBackgroundColor))
                .cornerRadius(8)

                // Test execution controls
                VStack(spacing: 16) {
                    if appState.isRunningTest {
                        VStack(spacing: 12) {
                            ProgressView(value: appState.currentTestProgress)
                                .progressViewStyle(.linear)

                            Text(appState.currentTestStatus)
                                .font(.caption)
                                .foregroundColor(.secondary)

                            Button("Cancel") {
                                // Cancel test execution
                            }
                            .buttonStyle(.bordered)
                        }
                    } else {
                        Button("Run Tests") {
                            Task {
                                await appState.runTest(config: config)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.large)
                    }
                }

                // Recent results
                if !appState.testResults.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Recent Results")
                                .font(.headline)

                            Spacer()

                            Button("View All") {
                                showingResults = true
                            }
                            .buttonStyle(.plain)
                            .foregroundColor(.blue)
                        }

                        LazyVStack(spacing: 8) {
                            ForEach(appState.testResults.prefix(3)) { result in
                                TestResultSummaryRow(result: result)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.controlBackgroundColor))
                    .cornerRadius(8)
                }

                Spacer()
            }
            .padding()
        }
        .sheet(isPresented: $showingResults) {
            TestResultsView()
                .frame(minWidth: 900, minHeight: 700)
        }
    }
}

struct InfoRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)

            Text(value)
                .fontWeight(.medium)

            Spacer()
        }
        .font(.caption)
    }
}

struct TestResultSummaryRow: View {
    let result: TestResults

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Test Run")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(formatDate(result.startTime))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 4) {
                    Text("\(result.summary.passed)")
                        .foregroundColor(.green)
                    Text("/")
                        .foregroundColor(.secondary)
                    Text("\(result.summary.total)")
                        .foregroundColor(.primary)
                }
                .font(.caption)
                .fontWeight(.medium)

                Text("\(Int(result.summary.passRate * 100))% pass")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    TestingView()
        .environmentObject(AppState())
}
