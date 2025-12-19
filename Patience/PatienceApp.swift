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
        
        // Customizes the app's menu commands
        .commands {
            // Replaces the default Help menu items
            CommandGroup(replacing: .help) {
                Button("Patience Help") {
                    // Sends action to show help window when clicked
                    NSApp.sendAction(#selector(AppCommands.showHelpWindow), to: nil, from: nil)
                }
            }
        }
    }
}

/// Helper class for handling app-wide commands
/// Inherits from NSObject to work with Objective-C runtime (required for @objc)
class AppCommands: NSObject {
    /// Shows the help window when called
    /// @objc makes this method callable from Objective-C/AppKit
    @objc static func showHelpWindow() {
        // Posts a notification that the HelpView listens for
        // This is how we communicate between menu and window
        NotificationCenter.default.post(name: Notification.Name("ShowHelpWindow"), object: nil)
    }
}

/// Help window view that displays user documentation
/// Shows quick start guide, features, and documentation links
struct HelpView: View {
    /// Reference to the actual NSWindow for this view
    /// Used to bring window to front when menu item is clicked
    @State private var window: NSWindow? = nil
    
    /// Builds the help window's user interface
    var body: some View {
        // Vertical stack with left alignment and 20pt spacing
        VStack(alignment: .leading, spacing: 20) {
            // Main title
            Text("Patience Help")
                .font(.largeTitle)
                .padding(.bottom)
            
            // Welcome message
            Text("Welcome to Patience!")
                .font(.body)
            
            // Horizontal line separator
            Divider()
                .padding(.vertical)
            
            // Quick Start section
            VStack(alignment: .leading, spacing: 12) {
                Text("Quick Start")
                    .font(.headline)
                
                // Step-by-step instructions
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .top) {
                        Text("1.")
                            .fontWeight(.semibold)
                        Text("Create a test configuration in the Testing tab")
                    }
                    
                    HStack(alignment: .top) {
                        Text("2.")
                            .fontWeight(.semibold)
                        Text("Define scenarios and validation rules")
                    }
                    
                    HStack(alignment: .top) {
                        Text("3.")
                            .fontWeight(.semibold)
                        Text("Run tests and view results")
                    }
                    
                    HStack(alignment: .top) {
                        Text("4.")
                            .fontWeight(.semibold)
                        Text("Generate reports for analysis")
                    }
                }
                .font(.body)
            }
            
            Divider()
                .padding(.vertical)
            
            // Features section
            VStack(alignment: .leading, spacing: 12) {
                Text("Features")
                    .font(.headline)
                
                // List of main features with SF Symbols icons
                VStack(alignment: .leading, spacing: 8) {
                    Label("Live Testing - Test bots with predefined scenarios", systemImage: "play.circle")
                    Label("Log Analysis - Analyze conversation logs", systemImage: "chart.bar")
                    Label("Adversarial Testing - AI-powered testing", systemImage: "shield")
                    Label("Reports - Export results in multiple formats", systemImage: "doc.text")
                }
                .font(.body)
            }
            
            Divider()
                .padding(.vertical)
            
            // Documentation section
            VStack(alignment: .leading, spacing: 8) {
                Text("Documentation")
                    .font(.headline)
                
                Text("For detailed documentation, see the README.md and DOCUMENTATION.md files included with this application.")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            // Pushes content to top, fills remaining space
            Spacer()
        }
        .padding()
        // Sets minimum window size
        .frame(minWidth: 500, minHeight: 400)
        // Called when view first appears on screen
        .onAppear {
            // Run on main thread (UI updates must be on main thread)
            DispatchQueue.main.async {
                // Find and store reference to this window
                if window == nil {
                    window = NSApp.windows.first(where: { $0.contentView?.subviews.contains(where: { view in
                        (view as? NSHostingView<HelpView>) != nil
                    }) ?? false})
                }
            }
        }
        // Listen for "ShowHelpWindow" notification from menu
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("ShowHelpWindow"))) { _ in
            // When notification received, bring window to front
            if let window = window {
                window.makeKeyAndOrderFront(nil)
                // Activate app (brings to foreground)
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }
}
