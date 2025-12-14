import SwiftUI
import AppKit

struct HelpView: View {
    @State private var observer: NSObjectProtocol?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Help & Documentation")
                    .font(.largeTitle)
                    .bold()
                
                Group {
                    Text("Getting Started")
                        .font(.title2)
                        .bold()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("1. Create a test configuration in the Testing tab")
                        Text("2. Define scenarios and validation rules")
                        Text("3. Run tests and view results")
                        Text("4. Generate reports for analysis")
                    }
                    .padding(.leading)
                }
                
                Divider()
                    .padding(.vertical)
                
                Group {
                    Text("Features")
                        .font(.title2)
                        .bold()
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Live Testing", systemImage: "play.circle")
                            .font(.headline)
                        Text("Test your chatbot in real-time with predefined scenarios")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .padding(.leading, 28)
                        
                        Label("Log Analysis", systemImage: "chart.bar")
                            .font(.headline)
                        Text("Analyze historical conversation logs for patterns and metrics")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .padding(.leading, 28)
                        
                        Label("Adversarial Testing", systemImage: "shield")
                            .font(.headline)
                        Text("AI-powered testing to find edge cases and weaknesses")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .padding(.leading, 28)
                        
                        Label("Reports", systemImage: "doc.text")
                            .font(.headline)
                        Text("Export results in HTML, JSON, or Markdown formats")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .padding(.leading, 28)
                    }
                }
                
                Divider()
                    .padding(.vertical)
                
                Group {
                    Text("Documentation")
                        .font(.title2)
                        .bold()
                    
                    Text("For detailed documentation, please refer to:")
                        .font(.body)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("• README.md - Project overview and quick start")
                        Text("• DOCUMENTATION.md - Comprehensive feature guide")
                        Text("• CONTRIBUTING.md - Development guidelines")
                        Text("• CHANGELOG.md - Version history")
                    }
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding(.leading)
                    
                    Text("These files are included with the application source code.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
            }
            .padding()
        }
        .onAppear {
            observer = NotificationCenter.default.addObserver(forName: Notification.Name("ShowHelpWindow"), object: nil, queue: .main) { _ in
                NSApp.activate(ignoringOtherApps: true)
            }
        }
        .onDisappear {
            if let observer = observer {
                NotificationCenter.default.removeObserver(observer)
                self.observer = nil
            }
        }
    }
}

#Preview {
    HelpView()
}
