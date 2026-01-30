import SwiftUI

/// Editor view for creating and modifying test configurations
/// This is a complex form with multiple sections for configuring all aspects of a test
/// 
/// Sections:
/// - Bot Configuration: Target bot name, endpoint, protocol, provider
/// - Authentication: Optional API key/token authentication
/// - Scenarios: List of test scenarios with conversation steps
/// - Validation: How to validate bot responses (pattern, semantic, etc.)
/// - Timing: Delays, timeouts, and pacing settings
/// 
/// Can be used in two modes:
/// 1. Create new config (initialConfig = nil)
/// 2. Edit existing config (initialConfig provided)
/// 
/// Changes are saved via onSave callback or directly to appState
struct TestConfigEditorView: View {
    /// Optional existing configuration to edit
    /// If nil, creates a new configuration
    let initialConfig: TestConfig?
    
    /// Optional callback when configuration is saved
    /// If nil, saves directly to appState
    let onSave: ((TestConfig) -> Void)?
    
    /// @Environment allows dismissing this sheet/window
    @Environment(\.dismiss) private var dismiss
    
    /// @EnvironmentObject provides access to global app state
    /// Used to save configurations and access default settings
    @EnvironmentObject var appState: AppState
    
    // MARK: - Bot Configuration State
    
    /// @State means this view owns and manages these values
    /// Changes trigger view re-renders
    /// Initialized from initialConfig if editing, otherwise defaults
    
    /// Name of the target bot being tested
    @State private var botName = ""
    
    /// HTTP/WebSocket endpoint URL for the target bot
    @State private var botEndpoint = ""
    
    /// Communication protocol (http, websocket, grpc)
    @State private var botProtocol: BotProtocol = .http
    
    /// Bot provider type (openai, anthropic, generic, etc.)
    @State private var botProvider: BotProvider = .generic
    
    /// Model name for AI providers (ollama, openai, anthropic)
    /// Only used when provider is not generic
    @State private var botModel = ""
    
    // MARK: - Authentication State
    
    /// Whether authentication is enabled for this bot
    @State private var useAuthentication = false
    
    /// Type of authentication (bearer, apiKey, basic, oauth)
    @State private var authType: AuthType = .bearer
    
    /// API key or token for authentication
    /// Stored securely via KeychainManager
    @State private var authCredentials = ""
    
    // MARK: - Scenarios State
    
    /// Array of test scenarios to run
    /// Each scenario has conversation steps and expected outcomes
    @State private var scenarios: [Scenario] = []
    
    /// Combined state for scenario editing - prevents race conditions
    /// Uses enum to ensure scenario and presentation state are always in sync
    @State private var scenarioEditingState: ScenarioEditingState = .none
    
    /// Enum to manage scenario editing state robustly
    private enum ScenarioEditingState {
        case none
        case editing(Scenario)
        case creating
        
        var isPresented: Bool {
            switch self {
            case .none: return false
            case .editing, .creating: return true
            }
        }
        
        var scenario: Scenario? {
            switch self {
            case .none, .creating: return nil
            case .editing(let scenario): return scenario
            }
        }
    }
    
    // MARK: - Validation State
    
    // MARK: - Timing State
    
    /// Whether to add realistic delays between messages
    @State private var enableDelays = true
    
    /// Base delay before sending each message (milliseconds)
    @State private var baseDelay = 1000
    
    /// Additional delay per character in message (milliseconds)
    /// Simulates typing speed
    @State private var delayPerCharacter = 50
    
    /// Maximum time to wait for bot response (milliseconds)
    @State private var responseTimeout = 30000
    
    /// Computed property that provides placeholder text for model field based on provider
    private var modelPlaceholder: String {
        switch botProvider {
        case .ollama:
            return "e.g., llama2, mistral, codellama"
        case .openai:
            return "e.g., gpt-4, gpt-3.5-turbo"
        case .anthropic:
            return "e.g., claude-3-sonnet, claude-3-opus"
        case .generic:
            return "Model name"
        }
    }
    
    /// Initializes the editor with optional existing configuration
    /// If initialConfig provided, pre-fills all fields with existing values
    /// Otherwise uses default values
    /// 
    /// - Parameters:
    ///   - initialConfig: Optional existing configuration to edit
    ///   - onSave: Optional callback when configuration is saved
    init(initialConfig: TestConfig? = nil, onSave: ((TestConfig) -> Void)? = nil) {
        self.initialConfig = initialConfig
        self.onSave = onSave
        
        self._botName = State(initialValue: initialConfig?.targetBot.name ?? "")
        self._botEndpoint = State(initialValue: initialConfig?.targetBot.endpoint ?? "")
        self._botProtocol = State(initialValue: initialConfig?.targetBot.botProtocol ?? .http)
        self._botProvider = State(initialValue: initialConfig?.targetBot.provider ?? .generic)
        self._botModel = State(initialValue: initialConfig?.targetBot.model ?? "")
        self._useAuthentication = State(initialValue: initialConfig?.targetBot.authentication != nil)
        self._authType = State(initialValue: initialConfig?.targetBot.authentication?.type ?? .bearer)
        self._authCredentials = State(initialValue: initialConfig?.targetBot.authentication?.credentials ?? "")
        self._scenarios = State(initialValue: initialConfig?.scenarios ?? [])
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
                    } else if let existingConfig = initialConfig {
                        // Update existing configuration
                        var updatedConfig = config
                        updatedConfig.id = existingConfig.id  // Preserve original ID
                        appState.updateTestConfig(updatedConfig)
                    } else {
                        // Create new configuration
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
                            
                            // Show model field for AI providers (not generic)
                            if botProvider != .generic {
                                LabeledContent("Model") {
                                    TextField(modelPlaceholder, text: $botModel)
                                        .textFieldStyle(.roundedBorder)
                                        .frame(maxWidth: 400)
                                }
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
                                            // Set editing state atomically - no race condition possible
                                            scenarioEditingState = .editing(scenario)
                                        }
                                        .buttonStyle(.bordered)
                                    }
                                    .padding(.vertical, 4)
                                }
                                .onDelete(perform: deleteScenario)
                            }
                            HStack {
                                Button("Add Scenario") {
                                    // Set creating state atomically
                                    scenarioEditingState = .creating
                                }
                                .buttonStyle(.borderedProminent)
                                Spacer()
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
        .sheet(isPresented: Binding(
            get: { scenarioEditingState.isPresented },
            set: { if !$0 { scenarioEditingState = .none } }
        )) {
            ScenarioEditorView(initialScenario: scenarioEditingState.scenario) { scenario in
                if let index = scenarios.firstIndex(where: { $0.id == scenario.id }) {
                    scenarios[index] = scenario
                } else {
                    scenarios.append(scenario)
                }
                scenarioEditingState = .none
            }
            .frame(minWidth: 700, minHeight: 600)
        }
    }
    
    /// Deletes scenarios at the specified indices
    /// Called by SwiftUI's .onDelete modifier
    /// 
    /// - Parameter offsets: Indices of scenarios to delete
    private func deleteScenario(at offsets: IndexSet) {
        scenarios.remove(atOffsets: offsets)
    }
    
    /// Builds a TestConfig from the current form state
    /// Combines all sections (bot, auth, scenarios, validation, timing, reporting)
    /// 
    /// - Returns: Complete TestConfig ready to save
    /// 
    /// Authentication is only included if:
    /// - useAuthentication is true
    /// - authCredentials is not empty
    private func buildConfiguration() -> TestConfig {
        let authentication: AuthConfig? = useAuthentication && !authCredentials.isEmpty
            ? AuthConfig(type: authType, credentials: authCredentials)
            : nil
        
        var config = TestConfig(
            targetBot: BotConfig(
                name: botName,
                botProtocol: botProtocol,
                endpoint: botEndpoint,
                authentication: authentication,
                headers: nil,
                provider: botProvider,
                model: botProvider != .generic && !botModel.isEmpty ? botModel : nil
            ),
            scenarios: scenarios,
            validation: ValidationConfig(
                defaultType: .pattern,
                semanticSimilarityThreshold: nil,
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
        
        // Preserve original ID if editing existing configuration
        if let existingConfig = initialConfig {
            config.id = existingConfig.id
        }
        
        return config
    }
}

/// Editor view for creating and modifying test scenarios
/// A scenario is a sequence of conversation steps with expected outcomes
/// 
/// Components:
/// - Scenario Details: Name and description
/// - Conversation Steps: Messages to send and expected responses
/// - Expected Outcomes: Overall validation criteria for the scenario
/// 
/// Each step has:
/// - message: What to send to the bot
/// - expectedResponse: Optional validation criteria for the response
/// 
/// Presented as a sheet from TestConfigEditorView
struct ScenarioEditorView: View {
    /// @Environment allows dismissing this sheet
    @Environment(\.dismiss) private var dismiss
    
    /// Optional existing scenario to edit (nil if creating new)
    let initialScenario: Scenario?
    
    /// Callback when scenario is saved
    /// Called with the complete scenario
    let onSave: (Scenario) -> Void
    
    // MARK: - Scenario State
    
    /// @State means this view owns these values
    /// Initialized from initialScenario if editing, otherwise defaults
    
    /// Unique identifier for this scenario
    /// Auto-generated if creating new
    @State private var scenarioId: String
    
    /// Human-readable name for this scenario
    @State private var scenarioName: String
    
    /// Optional description explaining what this scenario tests
    @State private var scenarioDescription: String
    
    /// Array of conversation steps (message + expected response)
    @State private var steps: [ConversationStep]
    
    /// Overall validation criteria for the entire scenario
    @State private var expectedOutcomes: [ValidationCriteria]
    
    /// Initializes the scenario editor
    /// If initialScenario provided, pre-fills all fields
    /// Otherwise uses defaults (empty name, no steps)
    /// 
    /// - Parameters:
    ///   - initialScenario: Optional existing scenario to edit
    ///   - onSave: Callback when scenario is saved (required)
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
            formContent
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
    
    /// Form content separated to avoid complex type-checking issues
    private var formContent: some View {
            ScrollView {
                Form {
                    Section("Scenario Details") {
                        TextField("Name", text: $scenarioName)
                        TextField("Description (optional)", text: $scenarioDescription, axis: .vertical)
                            .lineLimit(5)
                    }
                    
                    Section("Conversation Steps") {
                        Text("Define the step-by-step conversation flow. Each step sends a message and can validate the bot's immediate response to that specific message.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.bottom, 8)
                        
                        // Use enumerated() to create stable index-value pairs for SwiftUI
                        ForEach(Array(steps.enumerated()), id: \.offset) { index, _ in
                            ConversationStepEditor(step: $steps[index])
                        }
                        .onDelete(perform: deleteStep)
                        
                        Button("Add Step") {
                            addStep()
                        }
                    }
                    
                    Section("Expected Outcomes") {
                        Text("Define overall goals for the entire conversation. These validate the conversation as a whole after all steps are complete.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .padding(.bottom, 8)
                        
                        // Use enumerated() to create stable index-value pairs for SwiftUI
                        ForEach(Array(expectedOutcomes.enumerated()), id: \.offset) { index, _ in
                            VStack(alignment: .leading, spacing: 8) {
                                TextField("Expected outcome", text: $expectedOutcomes[index].expected)
                                    .textFieldStyle(.roundedBorder)
                                
                                HStack {
                                    Text("Type:")
                                        .font(.caption)
                                    
                                    Picker("Validation Type", selection: $expectedOutcomes[index].type) {
                                        ForEach(ValidationType.allCases, id: \.self) { type in
                                            Text(type.rawValue.capitalized).tag(type)
                                        }
                                    }
                                    .pickerStyle(.menu)
                                    .frame(maxWidth: 150)
                                    
                                    Spacer()
                                }
                                
                                // Show threshold slider for semantic validation
                                if expectedOutcomes[index].type == .semantic {
                                    HStack {
                                        Text("Threshold:")
                                            .font(.caption)
                                        
                                        Slider(value: Binding(
                                            get: { expectedOutcomes[index].threshold ?? 0.7 },
                                            set: { expectedOutcomes[index].threshold = $0 }
                                        ), in: 0...1, step: 0.1)
                                            .frame(maxWidth: 200)
                                        
                                        Text(String(format: "%.1f", expectedOutcomes[index].threshold ?? 0.7))
                                            .font(.caption)
                                            .frame(width: 30, alignment: .trailing)
                                        
                                        Spacer()
                                    }
                                }
                                
                                TextField("Description (optional)", text: Binding(
                                    get: { expectedOutcomes[index].description ?? "" },
                                    set: { newValue in
                                        expectedOutcomes[index].description = newValue.isEmpty ? nil : newValue
                                    }
                                ))
                                .textFieldStyle(.roundedBorder)
                            }
                            .padding(.vertical, 4)
                        }
                        .onDelete(perform: deleteOutcome)
                        
                        Button("Add Outcome") {
                            addOutcome()
                        }
                    }
                }
                .formStyle(.grouped)
            }
    }
    
    /// Adds a new conversation step with default values
    /// Step has empty message that user must fill in
    /// User can optionally add expected response validation
    private func addStep() {
        let step = ConversationStep(
            message: "",
            expectedResponse: nil,
            delay: nil
        )
        steps.append(step)
    }
    
    /// Deletes conversation steps at the specified indices
    /// Called by SwiftUI's .onDelete modifier
    /// 
    /// - Parameter offsets: Indices of steps to delete
    private func deleteStep(at offsets: IndexSet) {
        steps.remove(atOffsets: offsets)
    }
    
    /// Adds a new expected outcome with default values
    /// Outcome has empty expected text that user must fill in
    private func addOutcome() {
        let outcome = ValidationCriteria(
            type: .pattern,
            expected: "",
            threshold: 0.7,
            description: nil
        )
        expectedOutcomes.append(outcome)
    }
    
    /// Deletes expected outcomes at the specified indices
    /// Called by SwiftUI's .onDelete modifier
    /// 
    /// - Parameter offsets: Indices of outcomes to delete
    private func deleteOutcome(at offsets: IndexSet) {
        expectedOutcomes.remove(atOffsets: offsets)
    }
    
    /// Builds a Scenario from current form state and calls onSave
    /// Uses existing scenarioId if editing, otherwise creates new one
    /// Description is optional (nil if empty)
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

/// Editor view for creating and modifying log analysis configurations
/// Simpler than TestConfigEditorView - just configures what logs to analyze
/// 
/// Sections:
/// - Log Source: File path and format (JSON, CSV, text, auto)
/// - Analysis Options: What analysis to perform (metrics, patterns, context)
/// 
/// Can be used in two modes:
/// 1. Create new config (initialConfig = nil)
/// 2. Edit existing config (initialConfig provided)
/// 
/// Changes are saved via onSave callback or directly to appState
struct AnalysisConfigEditorView: View {
    /// Optional existing configuration to edit
    /// If nil, creates a new configuration
    let initialConfig: AnalysisConfig?
    
    /// Optional callback when configuration is saved
    /// If nil, saves directly to appState
    let onSave: ((AnalysisConfig) -> Void)?
    
    /// @Environment allows dismissing this sheet
    @Environment(\.dismiss) private var dismiss
    
    /// @EnvironmentObject provides access to global app state
    /// Used to save configuration and get default output path
    @EnvironmentObject var appState: AppState
    
    // MARK: - Analysis Configuration State
    
    /// @State means this view owns these values
    /// Initialized from initialConfig if editing, otherwise defaults
    
    /// Path to the log file to analyze
    @State private var logPath = ""
    
    /// Format of the log file (json, csv, text, auto)
    /// Auto-detection tries to determine format automatically
    @State private var logFormat: LogFormat = .auto
    
    /// Whether to calculate statistical metrics
    @State private var calculateMetrics = true
    
    /// Whether to detect common patterns (greetings, questions, errors)
    @State private var detectPatterns = true
    
    /// Whether to analyze context retention (bot memory)
    @State private var checkContextRetention = true
    
    /// Initializes the editor with optional existing configuration
    /// If initialConfig provided, pre-fills all fields with existing values
    /// Otherwise uses default values
    /// 
    /// - Parameters:
    ///   - initialConfig: Optional existing configuration to edit
    ///   - onSave: Optional callback when configuration is saved
    init(initialConfig: AnalysisConfig? = nil, onSave: ((AnalysisConfig) -> Void)? = nil) {
        self.initialConfig = initialConfig
        self.onSave = onSave
        
        self._logPath = State(initialValue: initialConfig?.logSource.path ?? "")
        self._logFormat = State(initialValue: initialConfig?.logSource.format ?? .auto)
        self._calculateMetrics = State(initialValue: initialConfig?.analysis.calculateMetrics ?? true)
        self._detectPatterns = State(initialValue: initialConfig?.analysis.detectPatterns ?? true)
        self._checkContextRetention = State(initialValue: initialConfig?.analysis.checkContextRetention ?? true)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(alignment: .center) {
                Text(initialConfig == nil ? "New Analysis Configuration" : "Edit Analysis Configuration")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Button("Cancel") { dismiss() }
                Button(initialConfig == nil ? "Create" : "Save") {
                    let config = buildConfiguration()
                    if let onSave = onSave {
                        onSave(config)
                    } else if let existingConfig = initialConfig {
                        // Update existing configuration
                        var updatedConfig = config
                        updatedConfig.id = existingConfig.id  // Preserve original ID
                        appState.updateAnalysisConfig(updatedConfig)
                    } else {
                        // Create new configuration
                        appState.addAnalysisConfig(config)
                    }
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
    
    /// Opens a file picker to select a log file
    /// Filters to JSON, CSV, and text files
    /// Updates logPath with selected file path
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
    
    /// Builds an AnalysisConfig from current form state
    /// Combines log source, analysis settings, and reporting configuration
    /// 
    /// - Returns: Complete AnalysisConfig ready to save
    /// 
    /// Uses appState.defaultOutputPath for report output
    private func buildConfiguration() -> AnalysisConfig {
        var config = AnalysisConfig(
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
        
        // Preserve original ID if editing existing configuration
        if let existingConfig = initialConfig {
            config.id = existingConfig.id
        }
        
        return config
    }
}

/// Detail view showing a test configuration's settings
/// Read-only display with option to edit
/// 
/// Shows:
/// - Bot name and endpoint
/// - Protocol and provider
/// - Number of scenarios
/// - Validation type
/// - List of all scenarios with details
/// 
/// Has "Edit" button that opens TestConfigEditorView sheet
struct TestConfigDetailView: View {
    /// The configuration to display
    let config: TestConfig
    
    /// @EnvironmentObject provides access to global app state
    /// Used to update configuration when edited
    @EnvironmentObject var appState: AppState
    
    /// @State tracks whether edit sheet is visible
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

/// Small card displaying a label and value
/// Used in TestConfigDetailView to show configuration properties
/// 
/// Example: "Protocol" / "HTTP"
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

/// Card displaying a scenario's summary
/// Shows name, description, step count, and outcome count
/// Used in TestConfigDetailView to list all scenarios
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

/// Detail view showing test results
/// Displays summary metrics and individual scenario results
/// 
/// Shows:
/// - Test run ID and start time
/// - Summary: Total/Passed/Failed counts
/// - Individual scenario results with pass/fail status
/// - Duration for each scenario
/// - Error messages if any
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
    
    /// Formats date for display
    /// Shows medium date style and short time style
    /// 
    /// - Parameter date: Date to format
    /// - Returns: Formatted string like "Jan 15, 2024 at 2:30 PM"
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

/// Card displaying a single scenario result
/// Shows pass/fail status, scenario name, duration, and errors
/// Used in TestResultDetailView to list all scenario results
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
    
    /// Formats duration for display
    /// Shows milliseconds if < 1 second, otherwise seconds
    /// 
    /// - Parameter duration: Duration in seconds
    /// - Returns: Formatted string like "500ms" or "2.5s"
    private func formatDuration(_ duration: Double) -> String {
        if duration < 1 {
            return String(format: "%.0fms", duration * 1000)
        } else {
            return String(format: "%.1fs", duration)
        }
    }
}

/// SwiftUI preview for TestConfigEditorView
/// Shows the editor in create mode with empty AppState
#Preview {
    TestConfigEditorView()
        .environmentObject(AppState())
}


/// Editor for individual conversation steps
/// Handles message input and expected response validation with threshold controls
/// Separated from main view to avoid Swift compiler type-checking issues with complex bindings
struct ConversationStepEditor: View {
    @Binding var step: ConversationStep
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("Message", text: $step.message)
                .textFieldStyle(.roundedBorder)
            
            if step.expectedResponse != nil {
                VStack(alignment: .leading, spacing: 4) {
                    TextField("Expected response", text: Binding(
                        get: { step.expectedResponse?.expected ?? "" },
                        set: { newValue in
                            step.expectedResponse?.expected = newValue
                        }
                    ))
                    .textFieldStyle(.roundedBorder)
                    
                    HStack {
                        Text("Type:")
                            .font(.caption)
                        
                        Picker("Validation Type", selection: Binding(
                            get: { step.expectedResponse?.validationType ?? .pattern },
                            set: { newValue in
                                step.expectedResponse?.validationType = newValue
                            }
                        )) {
                            ForEach(ValidationType.allCases, id: \.self) { type in
                                Text(type.rawValue.capitalized).tag(type)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(maxWidth: 150)
                    }
                    
                    // Show threshold slider for semantic validation
                    if step.expectedResponse?.validationType == .semantic {
                        HStack {
                            Text("Threshold:")
                                .font(.caption)
                            
                            Slider(value: Binding(
                                get: { step.expectedResponse?.threshold ?? 0.8 },
                                set: { newValue in
                                    step.expectedResponse?.threshold = newValue
                                }
                            ), in: 0...1, step: 0.1)
                            .frame(maxWidth: 200)
                            
                            Text(String(format: "%.1f", step.expectedResponse?.threshold ?? 0.8))
                                .font(.caption)
                                .frame(width: 30, alignment: .trailing)
                        }
                    }
                }
                .padding(.leading, 8)
                .background(Color(.controlBackgroundColor))
                .cornerRadius(4)
            }
            
            HStack {
                if step.expectedResponse == nil {
                    Button("Add Expected Response") {
                        step.expectedResponse = ResponseCriteria(
                            validationType: .pattern,
                            expected: "",
                            threshold: 0.8
                        )
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                } else {
                    Button("Remove Expected Response") {
                        step.expectedResponse = nil
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
        }
        .padding(.vertical, 4)
    }
}