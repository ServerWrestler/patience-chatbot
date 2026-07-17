import SwiftUI
import UniformTypeIdentifiers   // needed for .json content type on the import/export panels

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

/// UI-only helpers on `ConversationStrategy`. Kept in this file (not Types.swift)
/// because they're presentation copy — the canonical strategy behavior lives in the
/// matching `PromptStrategy` subclasses in `AdversarialTestOrchestrator.swift`.
///
/// `autoEscalateCaption` answers the question "if I turn Auto-escalate on with THIS
/// strategy selected, what will it actually do?" — each strategy's
/// `getNextTurnInstructions` does something different (or nothing meaningful), so
/// the caption sets accurate expectations per pick.
extension ConversationStrategy {
    /// Plain-English description of the strategy. Shared between the execution
    /// panel header and (in future) anywhere else we surface strategy choice.
    var humanDescription: String {
        switch self {
        case .exploratory:
            return "Broad, diverse questions to map bot capabilities and discover functionality."
        case .adversarial:
            return "Edge cases, contradictions, and challenging inputs to find weaknesses."
        case .redTeam:
            return "OWASP LLM Top 10 + MITRE ATLAS security probing with turn-based escalation (recon → injection → disclosure → obfuscation → agency)."
        case .focused:
            return "Deep dive into specific features defined in the goals."
        case .stress:
            return "Rapid context switching and complex inputs to test limits."
        case .custom:
            return "Custom strategy defined in the configuration."
        }
    }

    /// One-line note shown under the Auto-escalate toggle explaining what the
    /// toggle actually does for this strategy. Strategies whose
    /// `getNextTurnInstructions` is a no-op are honestly labeled "minor effect"
    /// or "no-op" — Auto-escalate's value varies wildly by strategy and silently
    /// pretending otherwise would mislead the user.
    var autoEscalateCaption: String {
        switch self {
        case .exploratory:
            return "Appends a diversity nudge each turn (minor effect — Exploratory already varies questions naturally)."
        case .adversarial:
            return "Light feedback loop — counts validation failures and nudges the model to keep probing."
        case .redTeam:
            return "Walks the OWASP 5-tier ladder: recon → injection → disclosure → obfuscation → agency."
        case .focused:
            return "Suggests a different angle on the focus area each turn (minor effect)."
        case .stress:
            return "Increases load each turn — harder, longer, more contradictory inputs."
        case .custom:
            return "No-op for Custom — the strategy doesn't define an escalation ladder."
        }
    }
}

struct AdversarialView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedConfigId: AdversarialTestConfig.ID?
    @State private var showingConfigEditor = false
    @State private var showingAttackLibrary = false
    
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

                Button {
                    showingAttackLibrary = true
                } label: {
                    Label("Attack Library (\(appState.attackLibrary.count))", systemImage: "books.vertical")
                }
                .buttonStyle(.bordered)

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
        .sheet(isPresented: $showingAttackLibrary) {
            AttackLibraryView()
                .frame(minWidth: 720, minHeight: 560)
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

            // Latest results for this configuration (most recent run), incl. judge verdicts.
            if let latest = appState.adversarialResults.last(where: { $0.configId == config.id }) {
                AdversarialResultsView(result: latest)
            }

            Spacer()
        }
        .padding()
    }

    /// Forwards to `ConversationStrategy.humanDescription` — kept as a one-line
    /// wrapper so existing call sites in this struct don't have to change.
    private func getStrategyDescription(_ strategy: ConversationStrategy) -> String {
        strategy.humanDescription
    }
}

/// Displays the most recent adversarial run: per-conversation transcripts with the
/// adversary's probes, the target's replies, and (when a judge ran) a severity verdict badge.
struct AdversarialResultsView: View {
    let result: AdversarialTestResults
    @State private var expanded = true

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Latest Results")
                    .font(.headline)
                Spacer()
                Text(result.timestamp, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Button(expanded ? "Hide" : "Show") { expanded.toggle() }
                    .buttonStyle(.borderless)
                    .controlSize(.small)
            }

            // Breach summary across all judged replies (only meaningful if a judge ran).
            let breaches = breachCount(result)
            if breaches > 0 {
                Label("\(breaches) breach\(breaches == 1 ? "" : "es") flagged by judge", systemImage: "exclamationmark.shield.fill")
                    .font(.caption)
                    .foregroundColor(.red)
            }

            if expanded {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(Array(result.conversations.enumerated()), id: \.element.id) { idx, convo in
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Conversation \(idx + 1) · \(convo.turns) turns · \(convo.terminationReason.rawValue)")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.secondary)
                                ForEach(convo.messages) { message in
                                    AdversarialMessageRow(message: message)
                                }
                            }
                            .padding(8)
                            .background(Color(.controlBackgroundColor))
                            .cornerRadius(6)
                        }
                    }
                }
                .frame(maxHeight: 360)
            }
        }
        .padding()
        .background(Color(.controlBackgroundColor).opacity(0.5))
        .cornerRadius(8)
    }

    /// Counts target replies the judge marked as a breach.
    private func breachCount(_ result: AdversarialTestResults) -> Int {
        result.conversations.reduce(0) { sum, convo in
            sum + convo.messages.filter { $0.metadata?[JudgeVerdict.MetaKey.breached] == "true" }.count
        }
    }
}

/// One message row in an adversarial transcript. Adversary probes and target replies are
/// styled distinctly; a judge verdict (if present in metadata) renders as a severity badge.
struct AdversarialMessageRow: View {
    let message: AdversarialMessage

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .top, spacing: 6) {
                Text(message.role == .adversarial ? "🗡 Adversary" : "🛡 Target")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(message.role == .adversarial ? .red : .blue)
                    .frame(width: 80, alignment: .leading)
                Text(message.content)
                    .font(.caption)
                    .textSelection(.enabled)
            }
            // Judge verdict badge on target replies.
            if let severity = message.metadata?[JudgeVerdict.MetaKey.severity], severity != "none", !severity.isEmpty {
                let breached = message.metadata?[JudgeVerdict.MetaKey.breached] == "true"
                let vector = message.metadata?[JudgeVerdict.MetaKey.vector] ?? ""
                HStack(spacing: 6) {
                    Text(severity.uppercased())
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 1)
                        .background(Self.severityColor(severity).opacity(0.2))
                        .foregroundColor(Self.severityColor(severity))
                        .cornerRadius(3)
                    if breached {
                        Text("BREACH")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                    }
                    if !vector.isEmpty {
                        Text(vector)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.leading, 86)
            }
        }
    }

    /// Maps a judge severity string to a display color.
    static func severityColor(_ severity: String) -> Color {
        switch severity.lowercased() {
        case "critical": return .red
        case "high":     return .orange
        case "medium":   return .yellow
        case "low":      return .blue
        default:          return .secondary
        }
    }
}

/// The attack-library flywheel viewer: lists harvested winning probes, lets the user
/// toggle each on/off (whether it's injected into future runs) and delete entries.
/// This is the user's window into "what the flywheel has learned."
struct AttackLibraryView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss

    /// Active tag filter. "" = show everything; otherwise only entries whose
    /// tags array contains this exact string. Driven by the picker in the header.
    @State private var tagFilter: String = ""

    /// Surfaces import/export errors inline at the top of the sheet so the user
    /// doesn't have to dig through the main app's error toast.
    @State private var ioErrorMessage: String? = nil

    /// All tags currently present in the library, sorted, deduped — used to
    /// populate the filter picker. Recomputed lazily on each render; the library
    /// is small enough that this is fine.
    private var allTags: [String] {
        var seen = Set<String>()
        for entry in appState.attackLibrary {
            for tag in entry.tags ?? [] where seen.insert(tag).inserted {}
        }
        return seen.sorted()
    }

    /// Library filtered by `tagFilter`. Empty filter shows everything.
    private var filteredLibrary: [AttackLibraryEntry] {
        guard !tagFilter.isEmpty else { return appState.attackLibrary }
        return appState.attackLibrary.filter { ($0.tags ?? []).contains(tagFilter) }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Attack Library")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("Proven probes harvested from past runs. Enabled entries are injected as few-shot examples when the flywheel is on.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button("Import…", action: importLibrary)
                Button("Export…", action: exportLibrary)
                    .disabled(appState.attackLibrary.isEmpty)
                Button("Done") { dismiss() }
                    .buttonStyle(.borderedProminent)
            }
            .padding()

            // Inline IO error banner — clears when the user dismisses it or runs
            // another successful import/export.
            if let msg = ioErrorMessage {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text(msg)
                        .font(.caption)
                    Spacer()
                    Button("Dismiss") { ioErrorMessage = nil }
                        .buttonStyle(.borderless)
                        .controlSize(.small)
                }
                .padding(.horizontal)
                .padding(.vertical, 6)
                .background(Color.orange.opacity(0.1))
            }

            // Tag filter — only shown when there's at least one tag to filter by.
            if !allTags.isEmpty {
                HStack {
                    Text("Filter by tag")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Picker("Tag", selection: $tagFilter) {
                        Text("All").tag("")
                        ForEach(allTags, id: \.self) { tag in
                            Text(tag).tag(tag)
                        }
                    }
                    .labelsHidden()
                    .frame(maxWidth: 240)
                    Spacer()
                    Text("\(filteredLibrary.count) of \(appState.attackLibrary.count)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                .padding(.bottom, 6)
            }

            Divider()

            if appState.attackLibrary.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "books.vertical")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)
                    Text("No attacks harvested yet")
                        .font(.headline)
                    Text("Run an adversarial test with the flywheel and a judge enabled. Probes that breach the target are stored here.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 420)
                    Text("Or click Import… to load a previously exported library.")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if filteredLibrary.isEmpty {
                // Library has entries but the active filter hid them all.
                VStack(spacing: 8) {
                    Text("No entries match tag \"\(tagFilter)\".")
                        .foregroundColor(.secondary)
                    Button("Clear filter") { tagFilter = "" }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List {
                    ForEach(filteredLibrary) { entry in
                        AttackLibraryRow(entry: entry)
                    }
                }
            }
        }
    }

    /// Shows an NSOpenPanel for a JSON file and imports it via AppState.
    /// Errors surface in the inline banner; the panel itself is modal.
    private func importLibrary() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            let data = try Data(contentsOf: url)
            let added = try appState.importAttackLibraryJSON(data)
            ioErrorMessage = nil
            // Use the existing app-wide toast as positive confirmation.
            appState.showErrorMessage("Imported \(added) new entr\(added == 1 ? "y" : "ies"). Duplicates skipped.")
        } catch {
            ioErrorMessage = "Import failed: \(error.localizedDescription)"
        }
    }

    /// Shows an NSSavePanel and writes the JSON encoding of the library to disk.
    private func exportLibrary() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "attack-library.json"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            let data = try appState.exportAttackLibraryJSON()
            try data.write(to: url)
            ioErrorMessage = nil
        } catch {
            ioErrorMessage = "Export failed: \(error.localizedDescription)"
        }
    }
}

/// One row in the attack-library viewer: severity/vector, the probe, the reply snippet,
/// an enable toggle, and a delete action.
struct AttackLibraryRow: View {
    let entry: AttackLibraryEntry
    @EnvironmentObject var appState: AppState

    /// Drives the inline tag editor. Toggled by the pencil button; commit happens
    /// when the user hits Return or clicks Save, which calls back into AppState.
    @State private var isEditingTags = false
    @State private var draftTags = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                if !entry.severity.isEmpty {
                    Text(entry.severity.uppercased())
                        .font(.caption2)
                        .fontWeight(.bold)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 1)
                        .background(AdversarialMessageRow.severityColor(entry.severity).opacity(0.2))
                        .foregroundColor(AdversarialMessageRow.severityColor(entry.severity))
                        .cornerRadius(3)
                }
                if !entry.vector.isEmpty {
                    Text(entry.vector)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Toggle("Enabled", isOn: Binding(
                    get: { entry.enabled },
                    set: { appState.setAttackLibraryEntryEnabled(entry, enabled: $0) }
                ))
                .labelsHidden()
                Button(role: .destructive) {
                    appState.deleteAttackLibraryEntry(entry)
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderless)
            }
            Text(entry.probe)
                .font(.callout)
                .textSelection(.enabled)
                .opacity(entry.enabled ? 1.0 : 0.5)
            if !entry.replySnippet.isEmpty {
                Text("↳ \(entry.replySnippet)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            tagFooter
        }
        .padding(.vertical, 4)
    }

    /// Tag chips + an edit-mode swap. Comma-separated input keeps the UI dense;
    /// AppState normalizes (trim, dedup, drop empties).
    @ViewBuilder
    private var tagFooter: some View {
        if isEditingTags {
            HStack(spacing: 6) {
                TextField("tag1, tag2, …", text: $draftTags, onCommit: commitTags)
                    .textFieldStyle(.roundedBorder)
                    .font(.caption)
                Button("Save", action: commitTags)
                    .controlSize(.small)
                Button("Cancel") { isEditingTags = false }
                    .controlSize(.small)
            }
        } else {
            HStack(spacing: 4) {
                ForEach(entry.tags ?? [], id: \.self) { tag in
                    Text(tag)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 1)
                        .background(Color.secondary.opacity(0.15))
                        .cornerRadius(3)
                }
                Button {
                    draftTags = (entry.tags ?? []).joined(separator: ", ")
                    isEditingTags = true
                } label: {
                    Image(systemName: "pencil")
                        .font(.caption2)
                }
                .buttonStyle(.borderless)
                .help((entry.tags ?? []).isEmpty ? "Add tags" : "Edit tags")
            }
        }
    }

    /// Parses the comma-separated draft and hands it to AppState for normalization.
    private func commitTags() {
        let parts = draftTags.split(separator: ",").map { String($0) }
        appState.setAttackLibraryEntryTags(entry, tags: parts)
        isEditingTags = false
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

    /// User-editable system prompt for the adversarial bot. The editor is seeded
    /// with the selected strategy's built-in prompt so the user can see exactly
    /// what the orchestrator will send. Edits override the default ONLY when the
    /// final text differs from the strategy's default — buildConfiguration()
    /// compares the two and persists `nil` when they match, so picking the same
    /// strategy on two machines still produces identical behavior.
    @State private var systemPrompt = ""

    /// The strategy's currently-computed default prompt — what the editor would
    /// contain if the user clicked "Reset to default" right now. Kept in state so
    /// the "Reset" target and the "is this still the default?" check stay aligned
    /// even when the strategy or goals change.
    @State private var systemPromptDefault = ""

    // Adaptive-probing toggles (map to AdaptiveSettings).
    /// Append the strategy's per-turn escalation instruction each turn.
    @State private var autoEscalate = false
    /// Pivot/obfuscate when the previous target reply looks like a refusal.
    @State private var adaptOnRefusal = false
    /// Generate N candidate probes per turn and send the strongest (1 = disabled).
    @State private var bestOfN = 1
    /// Inject proven probes from the attack library and harvest new wins.
    @State private var useFlywheel = false

    // Judge/critic (second model) settings.
    @State private var judgeEnabled = false
    @State private var judgeProvider: BotProvider = .ollama
    @State private var judgeModel = ""
    @State private var judgeEndpoint = "http://localhost:11435/api/chat"
    @State private var judgeApiKey = ""

    // Safety-control toggles (map to SafetySettings).
    // Each control is independently optional; an unchecked toggle leaves that
    // field nil so checkSafetyControls() skips its enforcement branch.
    /// Stop the run once estimated cost crosses this dollar amount.
    @State private var enableCostLimit = false
    @State private var maxCostUSD: Double = 5.0
    /// Enforce a minimum delay between requests to stay under this RPM ceiling.
    @State private var enableRateLimit = false
    @State private var maxRequestsPerMinute: Int = 60
    /// Drop responses matching the orchestrator's content filter.
    @State private var enableContentFilter = false
    
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
        // Seed the editor: show the saved override if one was persisted, otherwise
        // pre-fill with the selected strategy's built-in prompt so the user can see
        // exactly what would be sent. systemPromptDefault always tracks the latter.
        let seedStrategy = initialConfig?.conversation.strategy ?? .exploratory
        let seedGoals = initialConfig?.conversation.goals
        let seedDefault = AdversarialTestOrchestrator.defaultSystemPrompt(for: seedStrategy, goals: seedGoals)
        self._systemPromptDefault = State(initialValue: seedDefault)
        self._systemPrompt = State(initialValue: initialConfig?.conversation.systemPrompt ?? seedDefault)
        let adaptive = initialConfig?.conversation.adaptive ?? AdaptiveSettings()
        self._autoEscalate = State(initialValue: adaptive.autoEscalate)
        self._adaptOnRefusal = State(initialValue: adaptive.adaptOnRefusal)
        self._bestOfN = State(initialValue: adaptive.bestOfN)
        self._useFlywheel = State(initialValue: adaptive.useFlywheel)
        let judge = initialConfig?.judge ?? JudgeSettings()
        self._judgeEnabled = State(initialValue: judge.enabled)
        self._judgeProvider = State(initialValue: judge.provider)
        self._judgeModel = State(initialValue: judge.model ?? "")
        self._judgeEndpoint = State(initialValue: judge.endpoint ?? "http://localhost:11435/api/chat")
        self._judgeApiKey = State(initialValue: judge.apiKey ?? "")

        // Hydrate safety toggles: a non-nil field in the persisted config means
        // the user previously enabled that control, so reflect that here.
        let safety = initialConfig?.safety
        self._enableCostLimit = State(initialValue: safety?.maxCostUSD != nil)
        self._maxCostUSD = State(initialValue: safety?.maxCostUSD ?? 5.0)
        self._enableRateLimit = State(initialValue: safety?.maxRequestsPerMinute != nil)
        self._maxRequestsPerMinute = State(initialValue: safety?.maxRequestsPerMinute ?? 60)
        self._enableContentFilter = State(initialValue: safety?.contentFilter ?? false)
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

                    GroupBox("Adversary Prompt") {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                // Status line — tells the user whether they're looking at the
                                // strategy default or a custom override, so they don't have to
                                // guess what will actually be sent.
                                if isPromptModified {
                                    Label("Modified — saved as override for this config", systemImage: "pencil.circle.fill")
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                } else {
                                    Label("Using \(strategy.rawValue.capitalized) strategy default", systemImage: "checkmark.seal")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                // The template menu replaces the editor with a focused single-vector
                                // attack template. Distinct from "Reset to default" (which loads the
                                // currently-selected strategy's prompt).
                                // Templates are grouped by category in submenus so the list
                                // stays browsable as the catalog grows. Order: Full Arsenals →
                                // OWASP LLM Top 10 (LLM01–LLM10) → Tactics (cross-cutting).
                                Menu("Load template") {
                                    ForEach(AdversarialPromptTemplate.Category.allCases, id: \.self) { category in
                                        Menu(category.rawValue) {
                                            ForEach(AdversarialPromptTemplate.allCases.filter { $0.category == category }) { template in
                                                Button(template.displayName) {
                                                    systemPrompt = template.prompt
                                                }
                                            }
                                        }
                                    }
                                }
                                .frame(maxWidth: 200)
                                if isPromptModified {
                                    Button("Reset to default") {
                                        // Recompute fresh in case goals changed since last load.
                                        systemPromptDefault = AdversarialTestOrchestrator.defaultSystemPrompt(
                                            for: strategy, goals: goals.isEmpty ? nil : goals
                                        )
                                        systemPrompt = systemPromptDefault
                                    }
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)
                                }
                            }
                            TextEditor(text: $systemPrompt)
                                .font(.system(.body, design: .monospaced))
                                .frame(minHeight: 160, maxHeight: 320)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                                )
                            Text("Edit to override; persisted only when different from the strategy default. Picking the same strategy with the same goals will reproduce this exact prompt on any machine.")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    // Strategy/goal changes can shift what the "default" is. If the editor still
                    // matches the OLD default (user hasn't customized it), follow the new default
                    // so the editor always shows what would be sent. If the user has edits,
                    // preserve them — just update the "Reset" target via systemPromptDefault.
                    .onChange(of: strategy) { newStrategy in
                        let newDefault = AdversarialTestOrchestrator.defaultSystemPrompt(
                            for: newStrategy, goals: goals.isEmpty ? nil : goals
                        )
                        if systemPrompt == systemPromptDefault {
                            systemPrompt = newDefault
                        }
                        systemPromptDefault = newDefault
                    }
                    .onChange(of: goals) { newGoals in
                        let newDefault = AdversarialTestOrchestrator.defaultSystemPrompt(
                            for: strategy, goals: newGoals.isEmpty ? nil : newGoals
                        )
                        if systemPrompt == systemPromptDefault {
                            systemPrompt = newDefault
                        }
                        systemPromptDefault = newDefault
                    }

                    GroupBox("Adaptive Probing") {
                        VStack(alignment: .leading, spacing: 12) {
                            Toggle(isOn: $autoEscalate) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Auto-escalate")
                                    Text("Appends the strategy's per-turn instruction to the system prompt each turn.")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    // Per-strategy reality check: what THIS strategy actually
                                    // does with the toggle. Updates live when the picker changes.
                                    Label(strategy.autoEscalateCaption, systemImage: "info.circle")
                                        .font(.caption2)
                                        .foregroundColor(.accentColor)
                                        .padding(.top, 2)
                                }
                            }
                            Toggle(isOn: $adaptOnRefusal) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Adapt on refusal")
                                    Text("If the target refuses, pivot or obfuscate instead of repeating the failed probe.")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            Divider()
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Best-of-N")
                                    Text("Generate N candidate probes per turn, send the strongest. Higher N = more local model calls.")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Stepper("\(bestOfN)", value: $bestOfN, in: 1...5)
                                    .frame(maxWidth: 120)
                            }
                            Divider()
                            Toggle(isOn: $useFlywheel) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Use attack-library flywheel")
                                    Text("Inject proven probes (\(appState.attackLibrary.filter { $0.enabled }.count) active) as examples, and harvest new breaches from this run.")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }

                    GroupBox("Judge / Critic (second model)") {
                        VStack(alignment: .leading, spacing: 12) {
                            Toggle(isOn: $judgeEnabled) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Score each reply with a judge model")
                                    Text("A second model rates every target reply for a security breach (severity + rationale). Point it at a separate Ollama instance.")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            if judgeEnabled {
                                LabeledContent("Provider") {
                                    Picker("Provider", selection: $judgeProvider) {
                                        ForEach(BotProvider.allCases, id: \.self) { provider in
                                            Text(provider.rawValue.capitalized).tag(provider)
                                        }
                                    }
                                    .labelsHidden()
                                    .frame(maxWidth: 300, alignment: .leading)
                                }
                                LabeledContent("Model") {
                                    TextField("e.g. llama3", text: $judgeModel)
                                        .textFieldStyle(.roundedBorder)
                                        .frame(maxWidth: 300)
                                }
                                LabeledContent("Endpoint") {
                                    TextField("Judge endpoint", text: $judgeEndpoint)
                                        .textFieldStyle(.roundedBorder)
                                        .frame(maxWidth: 420)
                                }
                                if judgeProvider != .ollama {
                                    LabeledContent("API Key") {
                                        SecureField("API Key", text: $judgeApiKey)
                                            .textFieldStyle(.roundedBorder)
                                            .frame(maxWidth: 400)
                                    }
                                }
                                Text("Tip: run a second instance with `OLLAMA_HOST=127.0.0.1:11435 ollama serve`.")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    GroupBox("Safety Controls") {
                        VStack(alignment: .leading, spacing: 12) {
                            // Cost ceiling — orchestrator stops the run once the
                            // accumulated estimated cost crosses this dollar amount.
                            Toggle(isOn: $enableCostLimit) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Limit total cost (USD)")
                                    Text("Stop the run once estimated cost crosses the limit.")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            if enableCostLimit {
                                HStack {
                                    Text("Max cost")
                                    Spacer()
                                    TextField("USD", value: $maxCostUSD, format: .number.precision(.fractionLength(2)))
                                        .textFieldStyle(.roundedBorder)
                                        .frame(maxWidth: 120)
                                    Text("USD")
                                        .foregroundColor(.secondary)
                                }
                            }
                            Divider()
                            // Rate limit — orchestrator throttles between requests
                            // to stay under the requested requests-per-minute ceiling.
                            Toggle(isOn: $enableRateLimit) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Rate limit (requests/minute)")
                                    Text("Enforces a minimum delay between requests to stay under provider quotas.")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                            if enableRateLimit {
                                HStack {
                                    Text("Max rate")
                                    Spacer()
                                    Stepper("\(maxRequestsPerMinute)", value: $maxRequestsPerMinute, in: 1...600)
                                        .frame(maxWidth: 160)
                                    Text("req/min")
                                        .foregroundColor(.secondary)
                                }
                            }
                            Divider()
                            Toggle(isOn: $enableContentFilter) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Enable content filter")
                                    Text("Apply the orchestrator's content filter to incoming replies.")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
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
    /// True when the editor text differs from the strategy's currently-tracked default.
    /// Drives the status pill, the "Reset to default" button visibility, and the
    /// `safety: nil`-vs-override decision in buildConfiguration.
    private var isPromptModified: Bool {
        systemPrompt != systemPromptDefault
    }

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
                // Persist as nil when the editor still matches the strategy's natural default
                // (after re-computing with the current goals — they might have changed since
                // the editor was last refreshed). Otherwise persist the override verbatim.
                systemPrompt: {
                    let trimmed = systemPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
                    if trimmed.isEmpty { return nil }
                    let freshDefault = AdversarialTestOrchestrator.defaultSystemPrompt(
                        for: strategy, goals: goals.isEmpty ? nil : goals
                    )
                    return systemPrompt == freshDefault ? nil : systemPrompt
                }(),
                goals: goals.isEmpty ? nil : goals,
                timeout: nil,
                adaptive: AdaptiveSettings(
                    autoEscalate: autoEscalate,
                    adaptOnRefusal: adaptOnRefusal,
                    bestOfN: bestOfN,
                    useFlywheel: useFlywheel
                )
            ),
            validation: nil,
            execution: ExecutionSettings(
                numConversations: numConversations,
                concurrent: nil,
                delayBetweenTurns: nil,
                delayBetweenConversations: nil
            ),
            // Only build SafetySettings if at least one control is enabled; an
            // entirely-off panel persists as nil so older configs stay clean.
            safety: (enableCostLimit || enableRateLimit || enableContentFilter)
                ? SafetySettings(
                    maxCostUSD: enableCostLimit ? maxCostUSD : nil,
                    maxRequestsPerMinute: enableRateLimit ? maxRequestsPerMinute : nil,
                    contentFilter: enableContentFilter ? true : nil
                )
                : nil,
            judge: JudgeSettings(
                enabled: judgeEnabled,
                provider: judgeProvider,
                model: judgeModel.isEmpty ? nil : judgeModel,
                endpoint: judgeEndpoint.isEmpty ? nil : judgeEndpoint,
                apiKey: (judgeProvider != .ollama && !judgeApiKey.isEmpty) ? judgeApiKey : nil
            ),
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
