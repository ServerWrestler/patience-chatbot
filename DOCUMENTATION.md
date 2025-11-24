# Patience Documentation Guide

This document provides an overview of all documentation available in the Patience project.

## 📚 Main Documentation Files

### [README.md](README.md)
**The main entry point for all users**

Contains:
- Project overview and features
- Installation instructions
- Quick start guides for all three modes (Live Testing, Analysis, Adversarial)
- CLI usage for all commands
- Configuration examples
- Programmatic API usage
- Architecture overview
- Project structure
- Technology stack

**Start here if you're new to Patience!**

---

### [CONTRIBUTING.md](CONTRIBUTING.md)
**Guide for contributors**

Contains:
- Development setup instructions
- Coding standards and style guide
- Git workflow and branch naming
- Commit message format
- Pull request process
- Testing guidelines
- How to add new features
- Code of conduct

**Read this if you want to contribute to Patience!**

---

### [CHANGELOG.md](CHANGELOG.md)
**Version history and changes**

Contains:
- Release notes for each version
- New features added
- Bug fixes
- Breaking changes
- Deprecations

**Check this to see what's new in each release!**

---

### [SECURITY.md](SECURITY.md)
**Security policy and vulnerability reporting**

Contains:
- Supported versions
- How to report security vulnerabilities
- Security best practices
- Contact information

**Read this for security-related concerns!**

---

### [LICENSE](LICENSE)
**MIT License**

Contains:
- Full text of the MIT License
- Copyright information
- Terms and conditions

---

## 📖 Feature-Specific Documentation

### [examples/ADVERSARIAL_TESTING.md](examples/ADVERSARIAL_TESTING.md)
**Complete guide to adversarial testing**

Contains:
- Detailed overview of adversarial testing
- Quick start for all LLM providers (Ollama, OpenAI, Anthropic)
- Provider comparison and setup instructions
- Testing strategies explained in detail
- Complete configuration reference
- CLI usage examples
- Best practices
- Troubleshooting guide
- Cost estimation for paid APIs

**Read this for in-depth adversarial testing knowledge!**

---

### [examples/sample-logs/README.md](examples/sample-logs/README.md)
**Log format documentation**

Contains:
- Explanation of supported log formats (JSON, CSV, text)
- Format specifications
- Field descriptions
- Examples of each format

**Read this to understand log file formats!**

---

### [examples/sample-logs/USAGE.md](examples/sample-logs/USAGE.md)
**Quick start for log analysis**

Contains:
- How to use the sample logs
- Quick analysis examples
- Common use cases

**Read this for a quick start with log analysis!**

---

## 🔧 Configuration Examples

### Live Testing
- No dedicated config example yet (use README examples)

### Chat Log Analysis
- **[examples/analysis-config.json](examples/analysis-config.json)** - Complete analysis configuration with all options

### Adversarial Testing
- **[examples/adversarial-config.json](examples/adversarial-config.json)** - Ollama configuration (local, free)
- **[examples/adversarial-openai-config.json](examples/adversarial-openai-config.json)** - OpenAI/GPT-4 configuration
- **[examples/adversarial-anthropic-config.json](examples/adversarial-anthropic-config.json)** - Anthropic/Claude configuration

---

## 📊 Sample Data

### [examples/sample-logs/](examples/sample-logs/)
Contains sample conversation logs in multiple formats:
- **conversations.json** - JSON format example
- **conversations.csv** - CSV format example
- **conversations.txt** - Text format example

Use these to test the analysis features!

---

## 🗂️ Internal Documentation

### [.kiro/steering/](..kiro/steering/)
Internal project guidance (for development):
- **product.md** - Product overview and purpose
- **structure.md** - Project structure conventions
- **tech.md** - Technology stack and tools

### [.kiro/specs/](..kiro/specs/)
Feature specifications (for development):
- **chat-log-analysis/** - Analysis feature specs
  - requirements.md
  - design.md
  - tasks.md
- **adversarial-testing/** - Adversarial testing specs
  - requirements.md
  - design.md
  - tasks.md
  - IMPLEMENTATION_STATUS.md

---

## 🎯 Quick Navigation by Use Case

### "I want to test my chatbot live"
1. Read [README.md](README.md) - "Live Testing" section
2. Check configuration examples in README
3. Run: `patience config.json`

### "I want to analyze historical chat logs"
1. Read [README.md](README.md) - "Chat Log Analysis" section
2. Check [examples/sample-logs/USAGE.md](examples/sample-logs/USAGE.md)
3. Review [examples/analysis-config.json](examples/analysis-config.json)
4. Run: `patience analyze conversations.json`

### "I want to run adversarial bot-to-bot testing"
1. Read [README.md](README.md) - "Adversarial Testing" section
2. Read [examples/ADVERSARIAL_TESTING.md](examples/ADVERSARIAL_TESTING.md) for details
3. Choose your LLM provider and review the appropriate config:
   - Ollama: [adversarial-config.json](examples/adversarial-config.json)
   - OpenAI: [adversarial-openai-config.json](examples/adversarial-openai-config.json)
   - Anthropic: [adversarial-anthropic-config.json](examples/adversarial-anthropic-config.json)
4. Run: `patience adversarial --config your-config.json`

### "I want to contribute to Patience"
1. Read [CONTRIBUTING.md](CONTRIBUTING.md)
2. Check [CHANGELOG.md](CHANGELOG.md) to see recent changes
3. Review the codebase structure in [README.md](README.md)
4. Follow the development workflow in CONTRIBUTING.md

### "I found a security issue"
1. Read [SECURITY.md](SECURITY.md)
2. Follow the vulnerability reporting process
3. Do NOT publicly disclose until addressed

### "I want to understand the architecture"
1. Read [README.md](README.md) - "Architecture" section
2. Review [README.md](README.md) - "Project Structure" section
3. Check feature-specific design docs in `.kiro/specs/`

---

## 📝 Documentation Standards

All documentation in Patience follows these principles:

1. **Clear and Concise** - Get to the point quickly
2. **Example-Driven** - Show, don't just tell
3. **Up-to-Date** - Updated with every feature change
4. **Accessible** - Written for various skill levels
5. **Searchable** - Well-organized with clear headings

---

## 🔄 Keeping Documentation Updated

When making changes to Patience:

1. **Update README.md** if:
   - Adding/removing features
   - Changing CLI commands
   - Modifying configuration options
   - Updating architecture

2. **Update CHANGELOG.md** for:
   - Every release
   - New features
   - Bug fixes
   - Breaking changes

3. **Update feature-specific docs** when:
   - Changing feature behavior
   - Adding new options
   - Modifying examples

4. **Update CONTRIBUTING.md** if:
   - Changing development workflow
   - Adding new coding standards
   - Modifying testing requirements

---

## 💡 Tips for Finding Information

### Use GitHub Search
Search across all documentation files for specific terms.

### Check Examples First
The `examples/` directory contains working configurations and sample data.

### Read Error Messages
Error messages in Patience are designed to be helpful and point to relevant documentation.

### CLI Help Commands
```bash
patience --help
patience analyze --help
patience adversarial --help
```

### Start with README
The README is comprehensive and links to all other documentation.

---

## 📧 Getting Help

If you can't find what you need in the documentation:

1. **Search existing issues** on GitHub
2. **Check closed issues** - your question may have been answered
3. **Open a new issue** with the "question" label
4. **Be specific** about what you're trying to do

---

## 🎉 Documentation Contributions Welcome!

Found a typo? Have a suggestion? Want to add an example?

Documentation improvements are highly valued! See [CONTRIBUTING.md](CONTRIBUTING.md) for how to contribute.

---

**Last Updated:** 2025-01-15
