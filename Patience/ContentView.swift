import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @State private var selectedTab: TabSelection = .testing
    
    var body: some View {
        NavigationSplitView {
            SidebarView(selectedTab: $selectedTab)
        } detail: {
            Group {
                switch selectedTab {
                case .testing:
                    TestingView()
                case .analysis:
                    AnalysisView()
                case .adversarial:
                    AdversarialView()
                case .reports:
                    ReportsView()
                }
            }
        }
        .navigationTitle("Patience")
        .alert("Patience", isPresented: $appState.showError) {
            Button("OK") {
                appState.clearError()
            }
        } message: {
            if let errorMessage = appState.errorMessage {
                Text(errorMessage)
            }
        }
    }
    
    private func toggleSidebar() {
        NSApp.keyWindow?.firstResponder?.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
    }
}

enum TabSelection: String, CaseIterable {
    case testing = "Testing"
    case analysis = "Analysis"
    case adversarial = "Adversarial"
    case reports = "Reports"
    
    var icon: String {
        switch self {
        case .testing: return "play.circle"
        case .analysis: return "chart.bar"
        case .adversarial: return "shield"
        case .reports: return "doc.text"
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}
