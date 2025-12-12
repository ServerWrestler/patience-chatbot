# Patience Documentation Guide

This document provides comprehensive documentation for the Patience macOS application - a native Swift/SwiftUI chatbot testing framework.

## 📚 Main Documentation

### [README.md](README.md)
**The main entry point for all users**

Contains:
- Project overview and features
- Installation instructions
- Quick start guides for all three modes
- Configuration examples
- Architecture overview
- API provider setup
- Troubleshooting guide

**Start here if you're new to Patience!**

---

### [CONTRIBUTING.md](CONTRIBUTING.md)
**Guide for contributors**

Contains:
- Development setup with Xcode
- Swift coding standards and style guide
- SwiftUI best practices
- Git workflow and branch naming
- Pull request process
- Testing guidelines with XCTest
- How to add new features
- Code of conduct

**Read this if you want to contribute to Patience!**

---

### [CHANGELOG.md](CHANGELOG.md)
**Version history and changes**

Contains:
- Release notes for each version
- New features added
- Bug fixes and improvements
- Breaking changes
- Migration guides

**Check this to see what's new in each release!**

---

## 🎯 Feature Documentation

### Live Testing

**Purpose**: Test your chatbot in real-time with predefined scenarios

**Key Features**:
- Multi-step conversation flows
- Various validation types (exact, pattern, semantic)
- Configurable timing and delays
- Real-time progress monitoring
- Comprehensive reporting

**Configuration Structure**:
```swift
struct TestConfig {
    var targetBot: BotConfig
    var scenarios: [Scenario]
    var validation: ValidationConfig
    var timing: TimingConfig
    var reporting: ReportConfig
}
