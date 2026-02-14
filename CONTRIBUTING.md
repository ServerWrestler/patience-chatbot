# Contributing to Patience

## Prerequisites

- macOS 13.0+
- Xcode 15.0+
- Swift 5.9+ knowledge
- Git

## Quick Start

```bash
# Fork on GitHub, then clone
git clone https://github.com/YOUR_USERNAME/patience-chatbot.git
cd patience-chatbot
open Patience.xcodeproj
```

## Development Workflow

1. Create a feature branch: `git checkout -b feature/your-feature`
2. Make changes following project patterns (see [AI_ASSISTANT_GUIDE.md](AI_ASSISTANT_GUIDE.md))
3. Build and test: `⌘+B` then `⌘+R`
4. Commit with clear messages
5. Push and create a Pull Request

## Code Standards

- All types must be `Codable` and `Sendable`
- UI updates on `@MainActor`
- Use `async/await` for async operations
- Add clear comments (see [AI_ASSISTANT_GUIDE.md](AI_ASSISTANT_GUIDE.md#code-documentation-standards))
- Never store API keys in code (use Keychain)

## Project Structure

```
Patience/
├── Models/     # Data structures
├── Core/       # Business logic
├── Views/      # SwiftUI views
```

## Pull Request Checklist

- [ ] Code builds without warnings
- [ ] Follows existing patterns
- [ ] Includes comments
- [ ] No hardcoded secrets
- [ ] Updates relevant documentation

## Questions?

Open an issue or start a discussion on GitHub.
