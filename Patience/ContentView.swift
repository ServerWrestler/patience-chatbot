// Import SwiftUI framework for building the user interface
import SwiftUI

/// Main content view of the application
/// This is the root view that contains the sidebar navigation and main content area
/// It uses a split view layout (sidebar on left, content on right)
struct ContentView: View {
    /// Access to the global application state
    /// @EnvironmentObject means this is injected from a parent view
    /// Contains all test configs, results, and settings
    @EnvironmentObject var appState: AppState
    
    /// Tracks which tab is currently selected in the sidebar
    /// @State means this view owns and manages this value
    /// Starts with .testing tab selected by default
    @State private var selectedTab: TabSelection = .testing
    
    /// Builds the user interface for this view
    var body: some View {
        // Creates a split view with sidebar and detail area
        NavigationSplitView {
            // Left side: Sidebar with navigation options
            // $selectedTab passes a binding (two-way connection) to the sidebar
            // When sidebar changes selection, this variable updates automatically
            SidebarView(selectedTab: $selectedTab)
        } detail: {
            // Right side: Main content area that changes based on selected tab
            Group {
                // Switch statement determines which view to show
                switch selectedTab {
                case .testing:
                    // Live testing interface
                    TestingView()
                case .analysis:
                    // Log analysis interface
                    AnalysisView()
                case .adversarial:
                    // AI-powered adversarial testing interface
                    AdversarialView()
                case .reports:
                    // Reports and results interface
                    ReportsView()
                }
            }
        }
        // Sets the window title
        .navigationTitle("Patience")
        // Shows error alert when appState.showError becomes true
        .alert("Patience", isPresented: $appState.showError) {
            // Alert button
            Button("OK") {
                // Clears the error when user clicks OK
                appState.clearError()
            }
        } message: {
            // Alert message content
            // Shows the error message if one exists
            if let errorMessage = appState.errorMessage {
                Text(errorMessage)
            }
        }
    }
    
    /// Toggles the sidebar visibility (show/hide)
    /// This is a helper function for keyboard shortcuts or menu items
    private func toggleSidebar() {
        // Sends a message to the split view controller to toggle sidebar
        // Uses Objective-C selector for compatibility with AppKit
        NSApp.keyWindow?.firstResponder?.tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
    }
}

/// Enum defining the available tabs in the sidebar
/// Each case represents a different section of the app
/// String raw value is used for display text
/// CaseIterable allows us to loop through all cases
enum TabSelection: String, CaseIterable {
    case testing = "Testing"        // Live testing mode
    case analysis = "Analysis"      // Log analysis mode
    case adversarial = "Adversarial" // AI adversarial testing mode
    case reports = "Reports"        // Reports and results
    
    /// Returns the SF Symbol icon name for each tab
    /// SF Symbols are Apple's built-in icon system
    var icon: String {
        switch self {
        case .testing: return "play.circle"      // Play icon for testing
        case .analysis: return "chart.bar"       // Chart icon for analysis
        case .adversarial: return "shield"       // Shield icon for adversarial
        case .reports: return "doc.text"         // Document icon for reports
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AppState())
}
