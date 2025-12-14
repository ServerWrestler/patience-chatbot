import SwiftUI
import AppKit

@main
struct PatienceApp: App {
    @StateObject private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
        }
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unified)
        
        Settings {
            SettingsView()
                .environmentObject(appState)
        }
        
        WindowGroup("Help") {
            HelpView()
        }
        .handlesExternalEvents(matching: Set(arrayLiteral: "help"))
        
        .commands {
            CommandGroup(replacing: .help) {
                Button("Patience Help") {
                    NSApp.sendAction(#selector(AppCommands.showHelpWindow), to: nil, from: nil)
                }
            }
        }
    }
}

class AppCommands: NSObject {
    @objc static func showHelpWindow() {
        NotificationCenter.default.post(name: Notification.Name("ShowHelpWindow"), object: nil)
    }
}

struct HelpView: View {
    @State private var window: NSWindow? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Patience Help")
                .font(.largeTitle)
                .padding(.bottom)
            
            Text("Welcome to Patience!")
                .font(.body)
            
            Divider()
                .padding(.vertical)
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Quick Start")
                    .font(.headline)
                
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
            
            VStack(alignment: .leading, spacing: 12) {
                Text("Features")
                    .font(.headline)
                
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
            
            VStack(alignment: .leading, spacing: 8) {
                Text("Documentation")
                    .font(.headline)
                
                Text("For detailed documentation, see the README.md and DOCUMENTATION.md files included with this application.")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .frame(minWidth: 500, minHeight: 400)
        .onAppear {
            DispatchQueue.main.async {
                if window == nil {
                    window = NSApp.windows.first(where: { $0.contentView?.subviews.contains(where: { view in
                        (view as? NSHostingView<HelpView>) != nil
                    }) ?? false})
                }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: Notification.Name("ShowHelpWindow"))) { _ in
            if let window = window {
                window.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }
}
