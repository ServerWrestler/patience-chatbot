# 😈 Patience

A comprehensive native macOS application for chatbot testing with three powerful modes: live scenarios, log analysis, and AI-powered adversarial testing.

## Features

### 🚀 Live Testing
- **Scenario-based Testing**: Create multi-step conversation flows with expected responses
- **Protocol Support**: HTTP REST APIs and WebSocket for real-time communication
- **Validation Types**: Exact matching, regex patterns, semantic similarity, and custom validators
- **Realistic Timing**: Configurable delays to simulate human typing patterns
- **Real-time Monitoring**: Live progress tracking and immediate feedback
- **Provider Support**: Generic HTTP endpoints, Ollama local models, and cloud APIs
- **Configuration Sharing**: Export/import configurations for team collaboration

### 📊 Log Analysis *(Coming Soon)*
- **Context Analysis**: Multi-turn conversation quality scoring *(Basic implementation available)*
- **Multi-format Import**: Drag-and-drop support for JSON, CSV, and text log files *(Planned)*
- **Pattern Recognition**: Identify conversation patterns and success indicators *(Planned)*
- **Metrics Calculation**: Response rates, message statistics, and timing analysis *(Planned)*
- **Advanced Filtering**: Date ranges, message counts, and content-based filters *(Planned)*

### 🤖 Adversarial Testing
- **AI-Powered Testing**: Let AI models test your chatbot through realistic conversations
- **Multiple Providers**: 
  - **Ollama** - Local models (llama2, mistral) - Free and private
  - **OpenAI** - GPT models - Requires API key
  - **Anthropic** - Claude models - Requires API key
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

### 🔒 Security Features
- **Secure API Key Storage**: API keys stored in macOS Keychain with encryption
- **No Plaintext Secrets**: Keys never persisted in configuration files
- **User Feedback**: Clear notifications if keychain operations fail
- **Sandboxed Application**: Runs with macOS App Sandbox for security

## Requirements

- **macOS 13.0** or later
- **Xcode 15.0** or later (for development)
- **Swift 5.9** or later (for development)

## Installation

### Option 1: Download Release (Recommended)
1. Download the latest release from the [releases page](https://github.com/ServerWrestler/patience-chatbot/releases)
2. Drag `Patience.app` to your Applications folder
3. Launch Patience from Applications or Spotlight

### Option 2: Build from Source

#### Initial Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/ServerWrestler/patience-chatbot.git
   cd patience-chatbot
   ```

2. **Build and Run**
   ```bash
   # Open in Xcode
   open Patience.xcodeproj
   
   # Or build from command line
   xcodebuild -project Patience.xcodeproj -scheme Patience build
   ```

## Quick Start

### 1. Live Testing ✅
1. Click **"New Configuration"** in the Testing tab
2. Enter your bot's endpoint URL (e.g., `http://localhost:3000/chat`)
3. Add conversation scenarios with expected responses
4. Configure validation rules and timing
5. Click **"Run Tests"** to execute

### 2. Log Analysis *(Basic Features Only)*
1. Switch to the **Analysis** tab
2. *(Currently supports basic context analysis only)*
3. *(Full log import and analysis features coming in future release)*

### 3. Adversarial Testing ✅
1. Go to the **Adversarial** tab
2. Click **"New Configuration"**
3. Set up your target bot endpoint
4. Choose an AI provider (Ollama for local, OpenAI/Anthropic for cloud)
5. Select a testing strategy and parameters
6. Click **"Start Adversarial Testing"**

## Configuration Examples

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
    "name": "Production Chatbot",
    "protocol": "http",
    "endpoint": "https://api.example.com/chat"
  },
  "adversarialBot": {
    "provider": "ollama",
    "model": "llama2",
    "endpoint": "http://localhost:11434"
  },
  "conversation": {
    "strategy": "adversarial",
    "maxTurns": 10,
    "goals": [
      "Test error handling",
      "Find edge cases",
      "Verify context retention"
    ]
  },
  "execution": {
    "numConversations": 5,
    "concurrent": 1
  }
}
```

## API Provider Setup

### Ollama (Local, Free)
1. Install Ollama from [ollama.ai](https://ollama.ai)
2. Pull a model: `ollama pull llama2`
3. Start Ollama (runs on `http://localhost:11434`)
4. Select "Ollama" provider in Patience

### OpenAI
1. Get API key from [platform.openai.com](https://platform.openai.com)
2. Select "OpenAI" provider in Patience
3. Enter API key (stored securely in Keychain)
4. Choose model (gpt-4, gpt-3.5-turbo)

### Anthropic
1. Get API key from [console.anthropic.com](https://console.anthropic.com)
2. Select "Anthropic" provider in Patience
3. Enter API key (stored securely in Keychain)
4. Choose model (claude-3-opus, claude-3-sonnet)

## Documentation

- **[DOCUMENTATION.md](DOCUMENTATION.md)** - Comprehensive feature documentation
- **[CONTRIBUTING.md](CONTRIBUTING.md)** - Development and contribution guidelines
- **[CHANGELOG.md](CHANGELOG.md)** - Version history and release notes
- **[SECURITY.md](SECURITY.md)** - Security policies and reporting

## Support

- **Issues**: [GitHub Issues](https://github.com/ServerWrestler/patience-chatbot/issues)
- **Wiki**: [Project Wiki](https://github.com/ServerWrestler/patience-chatbot/wiki)
- **Discussions**: [GitHub Discussions](https://github.com/ServerWrestler/patience-chatbot/discussions)

## Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for:
- Development setup
- Coding standards
- Pull request process
- Testing guidelines

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
