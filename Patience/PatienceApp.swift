// Import SwiftUI framework for building the user interface
import SwiftUI
// Import AppKit for macOS-specific functionality
import AppKit

/// Main entry point for the Patience application
/// The @main attribute tells Swift this is where the app starts
@main
struct PatienceApp: App {
    /// Creates and manages the application's global state
    /// @StateObject ensures this persists for the lifetime of the app
    /// AppState contains all test configs, results, and settings
    @StateObject private var appState = AppState()
    
    @Environment(\.openWindow) private var openWindow
    
    /// Defines the app's window structure and content
    /// This is required by the App protocol
    var body: some Scene {
        // Main application window
        WindowGroup {
            ContentView()
                // Makes appState available to all child views
                // Child views can access it with @EnvironmentObject
                .environmentObject(appState)
        }
        // Hides the traditional macOS title bar for a modern look
        .windowStyle(.hiddenTitleBar)
        // Uses unified toolbar style (toolbar integrated with content)
        .windowToolbarStyle(.unified)
        
        // Settings window (accessed via Cmd+, or menu)
        Settings {
            SettingsView()
                // Settings also needs access to app state
                .environmentObject(appState)
        }
        
        // Separate Help window
        WindowGroup("Help") {
            HelpView()
        }
        // Allows this window to be opened via URL scheme
        .handlesExternalEvents(matching: Set(arrayLiteral: "help"))
        
        Window("About Patience", id: "about") {
            AboutSettingsView()
                .environmentObject(appState)
                .frame(minWidth: 500, minHeight: 400)
        }
        .defaultSize(width: 500, height: 400)
        
        // Customizes the app's menu commands
        .commands {
            // Replaces the default Help menu items
            CommandGroup(replacing: .help) {
                Button("Patience Help") {
                    AppCommands.showHelpWindow()
                }
            }
            CommandGroup(replacing: .appInfo) {
                Button("About Patience") {
                    openWindow(id: "about")
                }
            }
        }
    }
}

/// Helper class for handling app-wide commands
/// Inherits from NSObject to work with Objective-C runtime (required for @objc)
class AppCommands: NSObject {
    /// GitHub repository URL for documentation
    /// Update this if the repository location changes
    static let repositoryURL = "https://github.com/ServerWrestler/patience-chatbot/blob/main/DOCUMENTATION.md"
    
    /// Opens the GitHub documentation in the default browser
    /// @objc makes this method callable from Objective-C/AppKit
    @objc static func showHelpWindow() {
        // Open the GitHub repository documentation in the default browser
        if let url = URL(string: repositoryURL) {
            NSWorkspace.shared.open(url)
        }
    }
}

/// Placeholder HelpView - Help now opens external GitHub documentation
/// This view is kept for compatibility but the Help menu opens the browser instead
struct HelpView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "book.circle")
                .font(.system(size: 60))
                .foregroundColor(.accentColor)
            
            Text("Documentation")
                .font(.largeTitle)
            
            Text("Help documentation is available on GitHub.")
                .font(.body)
                .foregroundColor(.secondary)
            
            Button("Open Documentation") {
                if let url = URL(string: AppCommands.repositoryURL) {
                    NSWorkspace.shared.open(url)
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(40)
        .frame(minWidth: 400, minHeight: 300)
    }
}

