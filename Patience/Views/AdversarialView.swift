import SwiftUI

fileprivate enum EditingState {
    case none
    case editing(AdversarialTestConfig)

    var isPresented: Bool {
        switch self {
        case .none: return false
        case .editing: return true
        }
    }

    var config: AdversarialTestConfig? {
        switch self {
        case .none: return nil
        case .editing(let config): return config
        }
    }
}

struct AdversarialView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedConfigId: AdversarialTestConfig.ID?
    @State private var showingConfigEditor = false
    
    /// Combined state for editing - prevents race conditions between button click and sheet presentation
    /// Uses enum to ensure config data and presentation state are always in sync
    @State private var editingState: EditingState = .none
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text("Adversarial Testing")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    Text("AI-powered bot-to-bot testing to find edge cases")
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Button("New Configuration") {
                    showingConfigEditor = true
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
            
            Divider()
            
            if appState.adversarialConfigs.isEmpty {
                // Empty state
                if #available(macOS 14.0, *) {
                    ContentUnavailableView(
                        "No Adversarial Configurations",
                        systemImage: "shield",
                        description: Text("Create an adversarial testing configuration to test your bot against AI opponents")
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "shield")
                            .font(.largeTitle)
                            .foregroundColor(.secondary)
                        Text("No Adversarial Configurations")
                            .font(.headline)
                        Text("Create an adversarial testing configuration to test your bot against AI opponents")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            } else {
                // Configuration list and execution
                HSplitView {
                    // Left: Configuration list
                    VStack(alignment: .leading, spacing: 0) {
                        Text("Configurations")
                            .font(.headline)
                            .padding()
                        
                        List(appState.adversarialConfigs, selection: $selectedConfigId) { config in
                            AdversarialConfigRow(config: config)
                        }
                        .listStyle(.sidebar)
                    }
                    .frame(minWidth: 300)
                    
                    // Right: Execution panel
                    VStack {
                        if let selectedId = selectedConfigId, let config = appState.adversarialConfigs.first(where: { $0.id == selectedId }) {
                            AdversarialExecutionPanel(config: config)
                        } else {
                            if #available(macOS 14.0, *) {
                                ContentUnavailableView(
                                    "Select a Configuration",
                                    systemImage: "shield",
                                    description: Text("Choose an adversarial configuration to run tests")
                                )
                            } else {
                                VStack(spacing: 8) {
                                    Image(systemName: "shield")
                                        .font(.largeTitle)
                                        .foregroundColor(.secondary)
                                    Text("Select a Configuration")
                                        .font(.headline)
                                    Text("Choose an adversarial configuration to run tests")
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
            AdversarialConfigEditorView()
                .frame(minWidth: 900, minHeight: 700)
                .environmentObject(appState)
        }
        .sheet(isPresented: Binding(
            get: { editingState.isPresented },
            set: { if !$0 { editingState = .none } }
        )) {
            AdversarialConfigEditorView(initialConfig: editingState.config) { updatedConfig in
                appState.updateAdversarialConfig(updatedConfig)
                editingState = .none
            }
            .frame(minWidth: 900, minHeight: 700)
            .environmentObject(appState)
        }
    }
}

struct AdversarialConfigRow: View {
    let config: AdversarialTestConfig
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(config.targetBot.name)
                    .font(.headline)
                
                Spacer()
                
                Text(config.adversarialBot.provider.rawValue.uppercased())
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.red.opacity(0.2))
                    .foregroundColor(.red)
                    .cornerRadius(4)
            }
            
            Text(config.targetBot.endpoint)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(1)
            
            HStack {
                Text(config.conversation.strategy.rawValue)
                    .font(.caption2)
                    .padding(.horizontal, 4)
                    .padding(.vertical, 1)
                    .background(Color.purple.opacity(0.2))
                    .foregroundColor(.purple)
                    .cornerRadius(2)
                
                Text("\(config.conversation.maxTurns) turns")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Text("\(config.execution.numConversations) conv")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
        .contextMenu {
            Button("Run Test") {
                Task {
                    await appState.runAdversarialTest(config: config)
                }
            }
            
            Button("Edit") {
                // Edit configuration
            }
            
            Button("Duplicate") {
                // Duplicate configuration
            }
            
            Divider()
            
            Button("Delete", role: .destructive) {
                appState.deleteAdversarialConfig(config)
            }
        }
    }
}

struct AdversarialExecutionPanel: View {
    let config: AdversarialTestConfig
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(spacing: 20) {
            // Configuration details
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(config.targetBot.name)
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Spacer()
                    
                    Button("Edit") {
                        // Edit configuration
                    }
                    .buttonStyle(.bordered)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    InfoRow(label: "Target", value: config.targetBot.endpoint)
                    InfoRow(label: "Adversary", value: config.adversarialBot.provider.rawValue)
                    InfoRow(label: "Model", value: config.adversarialBot.model ?? "Default")
                    InfoRow(label: "Strategy", value: config.conversation.strategy.rawValue)
                    InfoRow(label: "Max Turns", value: "\(config.conversation.maxTurns)")
                    InfoRow(label: "Conversations", value: "\(config.execution.numConversations)")
                }
            }
            .padding()
            .background(Color(.controlBackgroundColor))
            .cornerRadius(8)
            
            // Strategy details
            VStack(alignment: .leading, spacing: 12) {
                Text("Strategy Details")
                    .font(.headline)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(getStrategyDescription(config.conversation.strategy))
                        .font(.body)
                        .foregroundColor(.secondary)
                    
                    if let goals = config.conversation.goals, !goals.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Goals:")
                                .font(.caption)
                                .fontWeight(.semibold)
                            
                            ForEach(goals, id: \.self) { goal in
                                Text("• \(goal)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .padding()
            .background(Color(.controlBackgroundColor))
            .cornerRadius(8)
            
            // Execution controls
            VStack(spacing: 16) {
                if appState.isRunningAdversarial {
                    VStack(spacing: 12) {
                        ProgressView()
                            .progressViewStyle(.circular)
                        
                        Text("Running adversarial tests...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Button("Cancel") {
                            // Cancel execution
                        }
                        .buttonStyle(.bordered)
                    }
                } else {
                    Button("Start Adversarial Testing") {
                        Task {
                            await appState.runAdversarialTest(config: config)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
            }
            
            // Safety warnings
            if config.adversarialBot.provider != .ollama {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.orange)
                        
                        Text("API Usage Warning")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    
                    Text("This test will use external API services which may incur costs. Monitor your usage carefully.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }
            
            Spacer()
        }
        .padding()
    }
    
    private func getStrategyDescription(_ strategy: ConversationStrategy) -> String {
        switch strategy {
        case .exploratory:
            return "Broad, diverse questions to map bot capabilities and discover functionality."
        case .adversarial:
            return "Edge cases, contradictions, and challenging inputs to find weaknesses."
        case .focused:
            return "Deep dive into specific features defined in the goals."
        case .stress:
            return "Rapid context switching and complex inputs to test limits."
        case .custom:
            return "Custom strategy defined in the configuration."
        }
    }
}

struct AdversarialConfigEditorView: View {
    /// Optional existing configuration to edit
    /// If nil, creates a new configuration
    let initialConfig: AdversarialTestConfig?
    
    /// Optional callback when configuration is saved
    /// If nil, saves directly to appState
    let onSave: ((AdversarialTestConfig) -> Void)?
    
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var appState: AppState
    
    @State private var targetBotName = ""
    @State private var targetBotEndpoint = ""
    @State private var targetBotProtocol: BotProtocol = .http
    
    @State private var adversarialProvider: BotProvider = .ollama
    @State private var adversarialModel = ""
    @State private var adversarialApiKey = ""
    
    @State private var strategy: ConversationStrategy = .exploratory
    @State private var maxTurns = 10
    @State private var numConversations = 1
    @State private var goals: [String] = []
    @State private var newGoal = ""
    
    /// Initializes the editor with optional existing configuration
    /// If initialConfig provided, pre-fills all fields with existing values
    /// Otherwise uses default values
    /// 
    /// - Parameters:
    ///   - initialConfig: Optional existing configuration to edit
    ///   - onSave: Optional callback when configuration is saved
    init(initialConfig: AdversarialTestConfig? = nil, onSave: ((AdversarialTestConfig) -> Void)? = nil) {
        self.initialConfig = initialConfig
        self.onSave = onSave
        
        self._targetBotName = State(initialValue: initialConfig?.targetBot.name ?? "")
        self._targetBotEndpoint = State(initialValue: initialConfig?.targetBot.endpoint ?? "")
        self._targetBotProtocol = State(initialValue: initialConfig?.targetBot.botProtocol ?? .http)
        self._adversarialProvider = State(initialValue: initialConfig?.adversarialBot.provider ?? .ollama)
        self._adversarialModel = State(initialValue: initialConfig?.adversarialBot.model ?? "")
        self._adversarialApiKey = State(initialValue: initialConfig?.adversarialBot.apiKey ?? "")
        self._strategy = State(initialValue: initialConfig?.conversation.strategy ?? .exploratory)
        self._maxTurns = State(initialValue: initialConfig?.conversation.maxTurns ?? 10)
        self._numConversations = State(initialValue: initialConfig?.execution.numConversations ?? 1)
        self._goals = State(initialValue: initialConfig?.conversation.goals ?? [])
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(alignment: .center) {
                Text(initialConfig == nil ? "New Adversarial Config" : "Edit Adversarial Config")
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
                        appState.updateAdversarialConfig(updatedConfig)
                    } else {
                        // Create new configuration
                        appState.addAdversarialConfig(config)
                    }
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
                .disabled(targetBotName.isEmpty || targetBotEndpoint.isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()

            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    GroupBox("Target Bot") {
                        VStack(alignment: .leading, spacing: 12) {
                            LabeledContent("Bot Name") {
                                TextField("Bot Name", text: $targetBotName)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(maxWidth: 400)
                            }
                            LabeledContent("Endpoint URL") {
                                TextField("Endpoint URL", text: $targetBotEndpoint)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(maxWidth: 500)
                            }
                            LabeledContent("Protocol") {
                                Picker("Protocol", selection: $targetBotProtocol) {
                                    ForEach(BotProtocol.allCases, id: \.self) { proto in
                                        Text(proto.rawValue.uppercased()).tag(proto)
                                    }
                                }
                                .labelsHidden()
                                .frame(maxWidth: 300, alignment: .leading)
                            }
                        }
                    }

                    GroupBox("Adversarial Bot") {
                        VStack(alignment: .leading, spacing: 12) {
                            LabeledContent("Provider") {
                                Picker("Provider", selection: $adversarialProvider) {
                                    ForEach(BotProvider.allCases, id: \.self) { provider in
                                        Text(provider.rawValue.capitalized).tag(provider)
                                    }
                                }
                                .labelsHidden()
                                .frame(maxWidth: 300, alignment: .leading)
                            }
                            LabeledContent("Model (optional)") {
                                TextField("Model", text: $adversarialModel)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(maxWidth: 300)
                            }
                            if adversarialProvider != .ollama {
                                LabeledContent("API Key") {
                                    SecureField("API Key", text: $adversarialApiKey)
                                        .textFieldStyle(.roundedBorder)
                                        .frame(maxWidth: 400)
                                }
                            }
                        }
                    }

                    GroupBox("Conversation Settings") {
                        VStack(alignment: .leading, spacing: 12) {
                            LabeledContent("Strategy") {
                                Picker("Strategy", selection: $strategy) {
                                    ForEach(ConversationStrategy.allCases, id: \.self) { strategy in
                                        Text(strategy.rawValue.capitalized).tag(strategy)
                                    }
                                }
                                .labelsHidden()
                                .frame(maxWidth: 300, alignment: .leading)
                            }
                            LabeledContent("Max Turns") {
                                Stepper("\(maxTurns)", value: $maxTurns, in: 1...50)
                                    .frame(maxWidth: 200, alignment: .leading)
                            }
                            LabeledContent("Conversations") {
                                Stepper("\(numConversations)", value: $numConversations, in: 1...20)
                                    .frame(maxWidth: 200, alignment: .leading)
                            }
                        }
                    }

                    GroupBox("Goals") {
                        VStack(alignment: .leading, spacing: 12) {
                            if goals.isEmpty {
                                Text("No goals added yet.")
                                    .foregroundColor(.secondary)
                            } else {
                                // Use enumerated() to create stable index-value pairs for SwiftUI
                                ForEach(Array(goals.enumerated()), id: \.offset) { index, _ in
                                    HStack(spacing: 8) {
                                        TextField("Goal", text: $goals[index])
                                            .textFieldStyle(.roundedBorder)
                                        
                                        Button("Remove") {
                                            goals.remove(at: index)
                                        }
                                        .buttonStyle(.bordered)
                                        .controlSize(.small)
                                    }
                                }
                            }
                            HStack(spacing: 8) {
                                TextField("Add goal", text: $newGoal)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(maxWidth: 400)
                                Button("Add") {
                                    if !newGoal.isEmpty {
                                        goals.append(newGoal)
                                        newGoal = ""
                                    }
                                }
                                .disabled(newGoal.isEmpty)
                            }
                        }
                    }
                }
                .padding(20)
            }
        }
    }
    
    private func deleteGoal(at offsets: IndexSet) {
        goals.remove(atOffsets: offsets)
    }
    
    /// Builds an AdversarialTestConfig from current form state
    /// Combines all sections (target bot, adversarial bot, conversation, execution, reporting)
    /// 
    /// - Returns: Complete AdversarialTestConfig ready to save
    /// 
    /// API key is only included if:
    /// - adversarialProvider is not ollama
    /// - adversarialApiKey is not empty
    private func buildConfiguration() -> AdversarialTestConfig {
        var config = AdversarialTestConfig(
            targetBot: AdversarialBotConfig(
                name: targetBotName,
                botProtocol: targetBotProtocol,
                endpoint: targetBotEndpoint,
                authentication: nil,
                headers: nil
            ),
            adversarialBot: AdversarialBotSettings(
                provider: adversarialProvider,
                model: adversarialModel.isEmpty ? nil : adversarialModel,
                apiKey: (adversarialProvider != .ollama && !adversarialApiKey.isEmpty) ? adversarialApiKey : nil,
                endpoint: nil,
                temperature: nil,
                maxTokens: nil
            ),
            conversation: ConversationSettings(
                strategy: strategy,
                maxTurns: maxTurns,
                startingPrompts: nil,
                systemPrompt: nil,
                goals: goals.isEmpty ? nil : goals,
                timeout: nil
            ),
            validation: nil,
            execution: ExecutionSettings(
                numConversations: numConversations,
                concurrent: nil,
                delayBetweenTurns: nil,
                delayBetweenConversations: nil
            ),
            safety: nil,
            reporting: AdversarialReportConfig(
                outputPath: appState.defaultOutputPath,
                formats: [.json, .html],
                includeTranscripts: true,
                realTimeMonitoring: true
            )
        )
        
        // Preserve original ID if editing existing configuration
        if let existingConfig = initialConfig {
            config.id = existingConfig.id
        }
        
        return config
    }
}

#Preview {
    AdversarialView()
        .environmentObject(AppState())
}
