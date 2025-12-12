# Patience

A comprehensive native macOS application for chatbot testing with three powerful modes: live scenarios, log analysis, and AI-powered adversarial testing.

## Features

### 🚀 Live Testing
- **Scenario-based Testing**: Create multi-step conversation flows with expected responses
- **Protocol Support**: HTTP REST APIs with WebSocket support planned
- **Validation Types**: Exact matching, regex patterns, semantic similarity, and custom validators
- **Realistic Timing**: Configurable delays to simulate human typing patterns
- **Real-time Monitoring**: Live progress tracking and immediate feedback
- **Provider Support**: Generic HTTP endpoints, Ollama local models, and cloud APIs

### 📊 Log Analysis
- **Multi-format Import**: Drag-and-drop support for JSON, CSV, and text log files
- **Automatic Detection**: Smart format detection and parsing
- **Pattern Recognition**: Identify conversation patterns, failures, and success indicators
- **Metrics Calculation**: Response rates, message statistics, and timing analysis
- **Context Analysis**: Multi-turn conversation quality scoring
- **Advanced Filtering**: Date ranges, message counts, and content-based filters

### 🤖 Adversarial Testing
- **AI-Powered Testing**: Let AI models test your chatbot through realistic conversations
- **Multiple Providers**: 
  - **Ollama** - Local models (llama2, mistral) - Free and private
  - **OpenAI** - GPT-4, GPT-3.5 - Requires API key
  - **Anthropic** - Claude 3 models - Requires API key
- **Testing Strategies**:
  - **Exploratory** - Broad questions to map capabilities
  - **Adversarial** - Edge cases and challenging inputs
  - **Focused** - Deep dive into specific features
  - **Stress** - Rapid context switching and complex scenarios
- **Safety Controls**: Cost monitoring, rate limiting, and content filtering

### 📈 Comprehensive Reporting
- **Multiple Formats**: Export as HTML, JSON, or Markdown
- **Interactive Viewing**: Native macOS interface for browsing results
- **Detailed Transcripts**: Complete conversation histories with timestamps
- **Validation Analysis**: Pass/fail rates with detailed explanations
- **Visual Summaries**: Charts and metrics for quick insights

## Requirements

- **macOS 13.0** or later
- **Xcode 15.0** or later (for development)
- **Swift 5.9** or later (for development)

## Installation

### Option 1: Download Release (Recommended)
1. Download the latest release from the releases page
2. Drag `Patience.app` to your Applications folder
3. Launch Patience from Applications or Spotlight

### Option 2: Build from Source
1. Clone this repository
2. Open `Patience.xcodeproj` in Xcode
3. Build and run (⌘+R)

## Quick Start

### 1. Live Testing
1. Click **"New Configuration"** in the Testing tab
2. Enter your bot's endpoint URL
3. Add conversation scenarios with expected responses
4. Click **"Run Tests"** to execute

### 2. Log Analysis
1. Switch to the **Analysis** tab
2. Drag a log file onto the interface or click **"Import Log File"**
3. Configure analysis options (metrics, patterns, context)
4. View results in the interactive interface

### 3. Adversarial Testing
1. Go to the **Adversarial** tab
2. Click **"New Configuration"**
3. Set up your target bot and choose an AI provider
4. Select a testing strategy and parameters
5. Click **"Start Adversarial Testing"**

## Configuration

### Live Testing Configuration

```json
{
  "targetBot": {
    "name": "My Chatbot",
    "protocol": "http",
    "endpoint": "https://api.example.com/chat",
    "provider": "generic"
  },
  "scenarios": [
    {
      "id": "greeting-test",
      "name": "Greeting Test",
      "steps": [
        {
          "message": "Hello!",
          "expectedResponse": {
            "validationType": "pattern",
            "expected": "hello|hi|hey|greetings",
            "threshold": 0.8
          }
        }
      ],
      "expectedOutcomes": [
        {
          "type": "pattern",
          "expected": "friendly.*response",
          "description": "Bot should respond in a friendly manner"
        }
      ]
    }
  ],
  "validation": {
    "defaultType": "pattern",
    "semanticSimilarityThreshold": 0.8
  },
  "timing": {
    "enableDelays": true,
    "baseDelay": 1000,
    "delayPerCharacter": 50,
    "rapidFire": false,
    "responseTimeout": 30000
  },
  "reporting": {
    "outputPath": "~/Documents/Patience Reports",
    "formats": ["html", "json"],
    "includeConversationHistory": true,
    "verboseErrors": true
  }
}
```

### Adversarial Testing Configuration

```json
{
  "targetBot": {
    "name": "My Chatbot",
    "protocol": "http",
    "endpoint": "https://api.example.com/chat"
  },
  "adversarialBot": {
    "provider": "ollama",
    "model": "llama2",
    "endpoint": "http://localhost:11434"
  },
  "conversation": {
    "strategy": "exploratory",
    "maxTurns": 10,
    "goals": [
      "Test greeting capabilities",
      "Verify error handling",
      "Check knowledge boundaries"
    ]
  },
  "execution": {
    "numConversations": 5,
    "delayBetweenTurns": 2000
  },
  "reporting": {
    "outputPath": "~/Documents/Patience Reports",
    "formats": ["html", "json"],
    "includeTranscripts": true,
    "realTimeMonitoring": true
  }
}
```

## Supported Log Formats

### JSON Format
```json
[
  {
    "sessionId": "session-123",
    "messages": [
      {
        "sender": "user",
        "content": "Hello",
        "timestamp": "2025-01-15T10:30:00Z"
      },
      {
        "sender": "bot",
        "content": "Hi there! How can I help you?",
        "timestamp": "2025-01-15T10:30:01Z"
      }
    ],
    "startTime": "2025-01-15T10:30:00Z",
    "endTime": "2025-01-15T10:35:00Z"
  }
]
```

### CSV Format
```csv
timestamp,sender,content
2025-01-15T10:30:00Z,user,Hello
2025-01-15T10:30:01Z,bot,Hi there! How can I help you?
```

### Text Format
```
User: Hello
Bot: Hi there! How can I help you?
User: What's the weather like?
Bot: I don't have access to weather information.
```

## Architecture

Patience is built with a clean, modular architecture:

### Core Components
- **TestExecutor**: Manages live test execution and scenario processing
- **AnalysisEngine**: Handles log parsing, filtering, and analysis
- **AdversarialTestOrchestrator**: Coordinates AI-powered testing sessions
- **ReportGenerator**: Creates formatted reports in multiple formats

### Communication Layer
- **CommunicationManager**: Handles HTTP/WebSocket protocols
- **ResponseValidator**: Validates bot responses against criteria
- **AI Connectors**: Interfaces with OpenAI, Anthropic, and Ollama

### User Interface
- **SwiftUI Views**: Native macOS interface components
- **AppState**: Centralized state management with Combine
- **Configuration Editors**: Visual editors for all configuration types

## Development

### Project Structure
```
Patience/
├── PatienceApp.swift          # App entry point
├── ContentView.swift          # Main interface
├── Models/
│   ├── Types.swift           # Core data models
│   └── AppState.swift        # State management
├── Core/
│   ├── TestExecutor.swift    # Test execution
│   ├── AnalysisEngine.swift  # Log analysis
│   ├── AdversarialTestOrchestrator.swift
│   └── ReportGenerator.swift
├── Views/
│   ├── TestingView.swift     # Live testing UI
│   ├── AnalysisView.swift    # Analysis UI
│   ├── AdversarialView.swift # Adversarial UI
│   └── ReportsView.swift     # Reports UI
└── Assets.xcassets/          # App icons and assets
```

### Building
```bash
# Open in Xcode
open Patience.xcodeproj

# Build from command line
xcodebuild -project Patience.xcodeproj -scheme Patience build

# Run tests
xcodebuild test -project Patience.xcodeproj -scheme Patience
```

### Contributing
1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Make your changes and add tests
4. Commit: `git commit -m 'Add amazing feature'`
5. Push: `git push origin feature/amazing-feature`
6. Open a Pull Request

## API Providers Setup

### Ollama (Local, Free)
1. Install Ollama from [ollama.ai](https://ollama.ai)
2. Pull a model: `ollama pull llama2`
3. Start Ollama: `ollama serve`
4. Use endpoint: `http://localhost:11434`

### OpenAI
1. Get API key from [OpenAI Platform](https://platform.openai.com)
2. Add to adversarial configuration
3. Choose model: `gpt-4`, `gpt-4-turbo`, `gpt-3.5-turbo`

### Anthropic
1. Get API key from [Anthropic Console](https://console.anthropic.com)
2. Add to adversarial configuration  
3. Choose model: `claude-3-opus`, `claude-3-sonnet`, `claude-3-haiku`

## Security & Privacy

- **App Sandboxing**: Patience runs in a secure sandbox environment
- **Network Access**: Only connects to endpoints you configure
- **File Access**: Only reads/writes files you explicitly select
- **API Keys**: Stored securely in macOS Keychain
- **Local Processing**: Log analysis happens entirely on your Mac

## Troubleshooting

### Common Issues

**"Connection failed" errors:**
- Verify the bot endpoint URL is correct and accessible
- Check if the bot requires authentication headers
- Ensure the bot is running and responding to requests

**"Invalid log format" errors:**
- Verify the log file format matches the selected type
- Check that JSON files are valid JSON
- Ensure CSV files have proper headers

**Adversarial testing not starting:**
- Verify API keys are correctly configured
- Check that Ollama is running (for local models)
- Ensure sufficient API credits (for paid providers)

### Getting Help

1. Check the built-in help documentation
2. Review configuration examples
3. Open an issue on GitHub with:
   - macOS version
   - Patience version
   - Steps to reproduce
   - Error messages or logs

## License

MIT License

Copyright (c) 2025 Patience Contributors
