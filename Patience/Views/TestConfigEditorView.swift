import SwiftUI

struct TestConfigEditorView: View {
    let initialConfig: TestConfig?
    let onSave: ((TestConfig) -> Void)?
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    
    @State private var botName = ""
    @State private var botEndpoint = ""
    @State private var botProtocol: BotProtocol = .http
    @State private var botProvider: BotProvider = .generic
    @State private var useAuthentication = false
    @State private var authType: AuthType = .bearer
    @State private var authCredentials = ""
    
    @State private var scenarios: [Scenario] = []
    @State private var showingScenarioEditor = false
    @State private var editingScenario: Scenario? = nil
    
    @State private var validationType: ValidationType = .pattern
    @State private var semanticThreshold: Double = 0.8
    
    @State private var enableDelays = true
    @State private var baseDelay = 1000
    @State private var delayPerCharacter = 50
    @State private var responseTimeout = 30000
    
    init(initialConfig: TestConfig? = nil, onSave: ((TestConfig) -> Void)? = nil) {
        self.initialConfig = initialConfig
        self.onSave = onSave
        
        self._botName = State(initialValue: initialConfig?.targetBot.name ?? "")
        self._botEndpoint = State(initialValue: initialConfig?.targetBot.endpoint ?? "")
        self._botProtocol = State(initialValue: initialConfig?.targetBot.botProtocol ?? .http)
        self._botProvider = State(initialValue: initialConfig?.targetBot.provider ?? .generic)
        self._useAuthentication = State(initialValue: initialConfig?.targetBot.authentication != nil)
        self._authType = State(initialValue: initialConfig?.targetBot.authentication?.type ?? .bearer)
        self._authCredentials = State(initialValue: initialConfig?.targetBot.authentication?.credentials ?? "")
        self._scenarios = State(initialValue: initialConfig?.scenarios ?? [])
        self._validationType = State(initialValue: initialConfig?.validation.defaultType ?? .pattern)
        self._semanticThreshold = State(initialValue: initialConfig?.validation.semanticSimilarityThreshold ?? 0.8)
        self._enableDelays = State(initialValue: initialConfig?.timing.enableDelays ?? true)
        self._baseDelay = State(initialValue: initialConfig?.timing.baseDelay ?? 1000)
        self._delayPerCharacter = State(initialValue: initialConfig?.timing.delayPerCharacter ?? 50)
        self._responseTimeout = State(initialValue: initialConfig?.timing.responseTimeout ?? 30000)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(alignment: .center) {
                Text(initialConfig == nil ? "New Test Configuration" : "Edit Test Configuration")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Button("Cancel") { dismiss() }
                Button(initialConfig == nil ? "Create" : "Save") {
                    let config = buildConfiguration()
                    if let onSave = onSave {
                        onSave(config)
                    } else {
                        appState.addTestConfig(config)
                    }
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(botName.isEmpty || botEndpoint.isEmpty || scenarios.isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()

            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    GroupBox("Bot Configuration") {
                        VStack(alignment: .leading, spacing: 12) {
                            LabeledContent("Bot Name") {
                                TextField("Bot Name", text: $botName)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(maxWidth: 400)
                            }
                            LabeledContent("Endpoint URL") {
                                TextField("Endpoint URL", text: $botEndpoint)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(maxWidth: 500)
                            }
                            LabeledContent("Protocol") {
                                Picker("Protocol", selection: $botProtocol) {
                                    ForEach(BotProtocol.allCases, id: \.self) { proto in
                                        Text(proto.rawValue.uppercased()).tag(proto)
                                    }
                                }
                                .labelsHidden()
                                .frame(maxWidth: 300, alignment: .leading)
                            }
                            LabeledContent("Provider") {
                                Picker("Provider", selection: $botProvider) {
                                    ForEach(BotProvider.allCases, id: \.self) { provider in
                                        Text(provider.rawValue.capitalized).tag(provider)
                                    }
                                }
                                .labelsHidden()
                                .frame(maxWidth: 300, alignment: .leading)
                            }
                        }
                    }

                    GroupBox("Authentication") {
                        VStack(alignment: .leading, spacing: 12) {
                            Toggle("Enable Authentication", isOn: $useAuthentication)
                            
                            if useAuthentication {
                                LabeledContent("Auth Type") {
                                    Picker("Auth Type", selection: $authType) {
                                        ForEach(AuthType.allCases, id: \.self) { type in
                                            Text(type.rawValue.capitalized).tag(type)
                                        }
                                    }
                                    .labelsHidden()
                                    .frame(maxWidth: 300, alignment: .leading)
                                }
                                
                                LabeledContent("Credentials") {
                                    SecureField("API Key or Token", text: $authCredentials)
                                        .textFieldStyle(.roundedBorder)
                                        .frame(maxWidth: 500)
                                }
                                
                                Text("Credentials are stored securely and never logged")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    GroupBox("Scenarios") {
                        VStack(alignment: .leading, spacing: 12) {
                            if scenarios.isEmpty {
                                Text("No scenarios added yet.")
                                    .foregroundColor(.secondary)
                            } else {
                                ForEach(scenarios) { scenario in
                                    HStack(alignment: .center) {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(scenario.name)
                                                .font(.headline)
                                            Text("\(scenario.steps.count) steps")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        Spacer()
                                        Button("Edit") {
                                            editingScenario = scenario
                                            showingScenarioEditor = true
                                        }
                                        .buttonStyle(.bordered)
                                    }
                                    .padding(.vertical, 4)
                                }
                                .onDelete(perform: deleteScenario)
                            }
                            HStack {
                                Button("Add Scenario") {
                                    showingScenarioEditor = true
                                }
                                .buttonStyle(.borderedProminent)
                                Spacer()
                            }
                        }
                    }

                    GroupBox("Validation") {
                        VStack(alignment: .leading, spacing: 12) {
                            LabeledContent("Default Type") {
                                Picker("Default Type", selection: $validationType) {
                                    ForEach(ValidationType.allCases, id: \.self) { type in
                                        Text(type.rawValue.capitalized).tag(type)
                                    }
                                }
                                .labelsHidden()
                                .frame(maxWidth: 300, alignment: .leading)
                            }
                            if validationType == .semantic {
                                LabeledContent("Similarity Threshold") {
                                    HStack(spacing: 8) {
                                        Slider(value: $semanticThreshold, in: 0...1, step: 0.1)
                                            .frame(maxWidth: 300)
                                        Text(String(format: "%.1f", semanticThreshold))
                                            .frame(width: 40, alignment: .trailing)
                                    }
                                }
                            }
                        }
                    }

                    GroupBox("Timing") {
                        VStack(alignment: .leading, spacing: 12) {
                            LabeledContent("Enable Delays") {
                                Toggle("", isOn: $enableDelays)
                                    .labelsHidden()
                            }
                            if enableDelays {
                                LabeledContent("Base Delay (ms)") {
                                    HStack(spacing: 8) {
                                        TextField("ms", value: $baseDelay, format: .number)
                                            .textFieldStyle(.roundedBorder)
                                            .frame(width: 140)
                                        Text("ms").foregroundColor(.secondary)
                                    }
                                }
                                LabeledContent("Delay per Character (ms)") {
                                    HStack(spacing: 8) {
                                        TextField("ms", value: $delayPerCharacter, format: .number)
                                            .textFieldStyle(.roundedBorder)
                                            .frame(width: 140)
                                        Text("ms").foregroundColor(.secondary)
                                    }
                                }
                            }
                            LabeledContent("Response Timeout (ms)") {
                                HStack(spacing: 8) {
                                    TextField("ms", value: $responseTimeout, format: .number)
                                        .textFieldStyle(.roundedBorder)
                                        .frame(width: 140)
                                    Text("ms").foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
                .padding(20)
            }
        }
        .sheet(isPresented: $showingScenarioEditor) {
            ScenarioEditorView(initialScenario: editingScenario) { scenario in
                if let index = scenarios.firstIndex(where: { $0.id == scenario.id }) {
                    scenarios[index] = scenario
                } else {
                    scenarios.append(scenario)
                }
                editingScenario = nil
            }
        }
    }
    
    private func deleteScenario(at offsets: IndexSet) {
        scenarios.remove(atOffsets: offsets)
    }
    
    private func buildConfiguration() -> TestConfig {
        let authentication: AuthConfig? = useAuthentication && !authCredentials.isEmpty
            ? AuthConfig(type: authType, credentials: authCredentials)
            : nil
        
        let config = TestConfig(
            targetBot: BotConfig(
                name: botName,
                botProtocol: botProtocol,
                endpoint: botEndpoint,
                authentication: authentication,
                headers: nil,
                provider: botProvider,
                model: nil
            ),
            scenarios: scenarios,
            validation: ValidationConfig(
                defaultType: validationType,
                semanticSimilarityThreshold: validationType == .semantic ? semanticThreshold : nil,
                customValidators: nil
            ),
            timing: TimingConfig(
                enableDelays: enableDelays,
                baseDelay: baseDelay,
                delayPerCharacter: delayPerCharacter,
                rapidFire: false,
                responseTimeout: responseTimeout
            ),
            reporting: ReportConfig(
                outputPath: appState.defaultOutputPath,
                formats: [.html, .json],
                includeConversationHistory: true,
                verboseErrors: true
            )
        )
        
        return config
    }
}

struct ScenarioEditorView: View {
    @Environment(\.dismiss) private var dismiss
    let initialScenario: Scenario?
    let onSave: (Scenario) -> Void
    
    @State private var scenarioId: String
    @State private var scenarioName: String
    @State private var scenarioDescription: String
    @State private var steps: [ConversationStep]
    @State private var expectedOutcomes: [ValidationCriteria]
    
    init(initialScenario: Scenario? = nil, onSave: @escaping (Scenario) -> Void) {
        self.initialScenario = initialScenario
        self.onSave = onSave
        
        _scenarioId = State(initialValue: initialScenario?.id ?? UUID().uuidString)
        _scenarioName = State(initialValue: initialScenario?.name ?? "")
        _scenarioDescription = State(initialValue: initialScenario?.description ?? "")
        _steps = State(initialValue: initialScenario?.steps ?? [])
        _expectedOutcomes = State(initialValue: initialScenario?.expectedOutcomes ?? [])
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                Form {
                    Section("Scenario Details") {
                        TextField("Name", text: $scenarioName)
                        TextField("Description (optional)", text: $scenarioDescription, axis: .vertical)
                            .lineLimit(5)
                    }
                    
                    Section("Conversation Steps") {
                        ForEach(steps) { step in
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Message: \(step.message)")
                                    .font(.body)
                                
                                if let expected = step.expectedResponse {
                                    Text("Expected: \(expected.expected)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.vertical, 2)
                        }
                        .onDelete(perform: deleteStep)
                        
                        Button("Add Step") {
                            addStep()
                        }
                    }
                    
                    Section("Expected Outcomes") {
                        ForEach(expectedOutcomes) { outcome in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(outcome.expected)
                                    .font(.body)
                                
                                Text("Type: \(outcome.type.rawValue)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .onDelete(perform: deleteOutcome)
                        
                        Button("Add Outcome") {
                            addOutcome()
                        }
                    }
                }
                .formStyle(.grouped)
            }
            .frame(minWidth: 700, minHeight: 600)
            .navigationTitle("New Scenario")
#if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
#endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveScenario()
                        dismiss()
                    }
                    .disabled(scenarioName.isEmpty || steps.isEmpty)
                }
            }
        }
    }
    
    private func addStep() {
        let step = ConversationStep(
            message: "Hello",
            expectedResponse: ResponseCriteria(
                validationType: .pattern,
                expected: "hello|hi|greetings",
                threshold: 0.8
            )
        )
        steps.append(step)
    }
    
    private func deleteStep(at offsets: IndexSet) {
        steps.remove(atOffsets: offsets)
    }
    
    private func addOutcome() {
        let outcome = ValidationCriteria(
            type: .pattern,
            expected: "helpful response",
            threshold: 0.7,
            description: "Bot should provide helpful responses"
        )
        expectedOutcomes.append(outcome)
    }
    
    private func deleteOutcome(at offsets: IndexSet) {
        expectedOutcomes.remove(atOffsets: offsets)
    }
    
    private func saveScenario() {
        let scenario = Scenario(
            id: scenarioId,
            name: scenarioName,
            description: scenarioDescription.isEmpty ? nil : scenarioDescription,
            steps: steps,
            expectedOutcomes: expectedOutcomes
        )
        
        onSave(scenario)
    }
}

struct AnalysisConfigEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    
    @State private var logPath = ""
    @State private var logFormat: LogFormat = .auto
    @State private var calculateMetrics = true
    @State private var detectPatterns = true
    @State private var checkContextRetention = true
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(alignment: .center) {
                Text("New Analysis Configuration")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Button("Cancel") { dismiss() }
                Button("Create") {
                    createConfiguration()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(logPath.isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()

            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    GroupBox("Log Source") {
                        VStack(alignment: .leading, spacing: 12) {
                            LabeledContent("Log File Path") {
                                HStack(spacing: 8) {
                                    TextField("Log File Path", text: $logPath)
                                        .textFieldStyle(.roundedBorder)
                                        .frame(maxWidth: 500)
                                    Button("Browse") { selectLogFile() }
                                }
                            }
                            LabeledContent("Format") {
                                Picker("Format", selection: $logFormat) {
                                    ForEach(LogFormat.allCases, id: \.self) { format in
                                        Text(format.rawValue.uppercased()).tag(format)
                                    }
                                }
                                .labelsHidden()
                                .frame(maxWidth: 300, alignment: .leading)
                            }
                        }
                    }

                    GroupBox("Analysis Options") {
                        VStack(alignment: .leading, spacing: 12) {
                            Toggle("Calculate Metrics", isOn: $calculateMetrics)
                            Toggle("Detect Patterns", isOn: $detectPatterns)
                            Toggle("Check Context Retention", isOn: $checkContextRetention)
                        }
                    }
                }
                .padding(20)
            }
        }
    }
    
    private func selectLogFile() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json, .commaSeparatedText, .plainText]
        panel.allowsMultipleSelection = false
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                logPath = url.path
            }
        }
    }
    
    private func createConfiguration() {
        let config = AnalysisConfig(
            logSource: LogSource(path: logPath, format: logFormat),
            filters: nil,
            validation: nil,
            analysis: AnalysisSettings(
                calculateMetrics: calculateMetrics,
                detectPatterns: detectPatterns,
                checkContextRetention: checkContextRetention
            ),
            reporting: ReportConfig(
                outputPath: appState.defaultOutputPath,
                formats: [.html, .json],
                includeConversationHistory: true,
                verboseErrors: false
            )
        )
        
        appState.addAnalysisConfig(config)
    }
}

struct TestConfigDetailView: View {
    let config: TestConfig
    @EnvironmentObject var appState: AppState
    @State private var showingEditSheet = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Configuration header
                VStack(alignment: .leading, spacing: 8) {
                    Text(config.targetBot.name)
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text(config.targetBot.endpoint)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
                
                // Bot details
                VStack(alignment: .leading, spacing: 12) {
                    Text("Bot Configuration")
                        .font(.headline)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                        InfoCard(title: "Protocol", value: config.targetBot.botProtocol.rawValue.uppercased())
                        InfoCard(title: "Provider", value: config.targetBot.provider?.rawValue.capitalized ?? "Generic")
                        InfoCard(title: "Scenarios", value: "\(config.scenarios.count)")
                        InfoCard(title: "Validation", value: config.validation.defaultType.rawValue.capitalized)
                    }
                }
                
                // Scenarios
                VStack(alignment: .leading, spacing: 12) {
                    Text("Scenarios")
                        .font(.headline)
                    
                    LazyVStack(spacing: 8) {
                        ForEach(config.scenarios) { scenario in
                            ScenarioCard(scenario: scenario)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Configuration Details")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Edit") {
                    showingEditSheet = true
                }
            }
        }
        .sheet(isPresented: $showingEditSheet) {
            TestConfigEditorView(initialConfig: config) { updated in
                appState.updateTestConfig(updated)
            }
            .frame(minWidth: 900, minHeight: 700)
            .environmentObject(appState)
        }
    }
}

struct InfoCard: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.body)
                .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }
}

struct ScenarioCard: View {
    let scenario: Scenario
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(scenario.name)
                    .font(.headline)
                
                Spacer()
                
                Text("\(scenario.steps.count) steps")
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.blue.opacity(0.2))
                    .foregroundColor(.blue)
                    .cornerRadius(4)
            }
            
            if let description = scenario.description {
                Text(description)
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            Text("Expected outcomes: \(scenario.expectedOutcomes.count)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
    }
}

struct TestResultDetailView: View {
    let result: TestResults
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Result header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Test Results")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Run ID: \(result.testRunId)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("Started: \(formatDate(result.startTime))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                // Summary
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 16) {
                    MetricCard(title: "Total", value: "\(result.summary.total)")
                    MetricCard(title: "Passed", value: "\(result.summary.passed)")
                    MetricCard(title: "Failed", value: "\(result.summary.failed)")
                }
                
                // Scenario results
                VStack(alignment: .leading, spacing: 12) {
                    Text("Scenario Results")
                        .font(.headline)
                    
                    LazyVStack(spacing: 8) {
                        ForEach(result.scenarioResults) { scenarioResult in
                            ScenarioResultCard(result: scenarioResult)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Test Results")
#if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
#endif
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct ScenarioResultCard: View {
    let result: ScenarioResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: result.passed ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(result.passed ? .green : .red)
                
                Text(result.scenarioName)
                    .font(.headline)
                
                Spacer()
                
                Text(formatDuration(result.duration))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            if let error = result.error {
                Text("Error: \(error)")
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.vertical, 4)
                    .padding(.horizontal, 8)
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(4)
            }
            
            Text("Messages: \(result.conversationHistory.messages.count)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.controlBackgroundColor))
        .cornerRadius(8)
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
    TestConfigEditorView()
        .environmentObject(AppState())
}

