import SwiftUI

private enum SidebarSelection: Hashable {
    case tab(TabSelection)
    case config(TestConfig.ID)
}

extension SidebarSelection {
    static func == (lhs: SidebarSelection, rhs: SidebarSelection) -> Bool {
        switch (lhs, rhs) {
        case let (.tab(a), .tab(b)):
            return String(describing: a) == String(describing: b)
        case let (.config(a), .config(b)):
            return String(describing: a) == String(describing: b)
        default:
            return false
        }
    }

    func hash(into hasher: inout Hasher) {
        switch self {
        case let .tab(a):
            hasher.combine(0)
            hasher.combine(String(describing: a))
        case let .config(a):
            hasher.combine(1)
            hasher.combine(String(describing: a))
        }
    }
}

struct SidebarView: View {
    @Binding var selectedTab: TabSelection
    @EnvironmentObject var appState: AppState
    @State private var selection: SidebarSelection? = nil
    
    var body: some View {
        List(selection: $selection) {
            Section("Testing") {
                Label("Live Testing", systemImage: TabSelection.testing.icon)
                    .tag(SidebarSelection.tab(.testing))
                
                Label("Adversarial", systemImage: TabSelection.adversarial.icon)
                    .tag(SidebarSelection.tab(.adversarial))
            }
            
            Section("Analysis") {
                Label("Log Analysis", systemImage: TabSelection.analysis.icon)
                    .tag(SidebarSelection.tab(.analysis))
                
                Label("Reports", systemImage: TabSelection.reports.icon)
                    .tag(SidebarSelection.tab(.reports))
            }
            
            Section("Configurations") {
                ForEach(appState.testConfigs) { config in
                    NavigationLink(destination: TestConfigDetailView(config: config)) {
                        Label(config.targetBot.name, systemImage: "gear")
                    }
                    .tag(SidebarSelection.config(config.id))
                }
            }
        }
        .navigationTitle("Patience")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button("New Test Config") {
                        // Create new test config
                    }
                    
                    Button("New Adversarial Config") {
                        // Create new adversarial config
                    }
                    
                    Button("New Analysis Config") {
                        // Create new analysis config
                    }
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .onChange(of: selection) { newSelection in
            if case let .tab(tab)? = newSelection {
                selectedTab = tab
            }
        }
        .onChange(of: selectedTab) { newValue in
            selection = .tab(newValue)
        }
        .onAppear {
            selection = .tab(selectedTab)
        }
    }
}

#Preview {
    NavigationSplitView {
        SidebarView(selectedTab: .constant(.testing))
            .environmentObject(AppState())
    } detail: {
        Text("Select an item")
    }
}
