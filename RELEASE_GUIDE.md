# Release Guide for Patience Beta

## Quick Steps to Release

### 1. Pre-Release Checks

```bash
# Ensure you're on main branch with clean working directory
git checkout main
git pull origin main
git status  # Should be clean

# Run tests
npm test

# Build
npm run build

# Test the build
node dist/cli.js --help
```

### 2. Update Package Version

The version is already set to `0.1.0-beta.1` in package.json. For future releases:

```bash
# For next beta
npm version 0.1.0-beta.2

# For release candidate
npm version 0.1.0-rc.1

# For stable release
npm version 0.1.0
```

### 3. Update CHANGELOG.md

Update the [Unreleased] section with the beta version and date:

```markdown
## [0.1.0-beta.1] - 2025-01-15

### Added
- Initial beta release
- Live testing feature
- Chat log analysis feature
- Adversarial testing feature with Ollama, OpenAI, and Anthropic
```

### 4. Commit and Tag

```bash
# Commit changes
git add .
git commit -m "chore: prepare for v0.1.0-beta.1 release"

# Create tag
git tag -a v0.1.0-beta.1 -m "Release v0.1.0-beta.1"

# Push to GitHub
git push origin main
git push origin v0.1.0-beta.1
```

### 5. Create GitHub Repository (if not exists)

1. Go to https://github.com/new
2. Repository name: `patience`
3. Description: "Comprehensive chatbot testing framework with live testing, log analysis, and AI-powered adversarial testing"
4. Public repository
5. Don't initialize with README (you already have one)
6. Create repository

### 6. Push to GitHub

```bash
# Add remote (replace YOUR_USERNAME)
git remote add origin https://github.com/YOUR_USERNAME/patience.git

# Or if remote exists, update URL
git remote set-url origin https://github.com/YOUR_USERNAME/patience.git

# Push
git push -u origin main
git push origin --tags
```

### 7. Update package.json with GitHub URL

Update these lines in package.json (replace YOUR_USERNAME):

```json
"repository": {
  "type": "git",
  "url": "https://github.com/YOUR_USERNAME/patience.git"
},
"bugs": {
  "url": "https://github.com/YOUR_USERNAME/patience/issues"
},
"homepage": "https://github.com/YOUR_USERNAME/patience#readme"
```

Then commit and push:

```bash
git add package.json
git commit -m "chore: update repository URLs"
git push origin main
```

### 8. Create GitHub Release

1. Go to your repository on GitHub
2. Click "Releases" → "Draft a new release"
3. Choose tag: `v0.1.0-beta.1`
4. Release title: `Patience v0.1.0-beta.1 - Beta Release`
5. Description: Use the template below
6. Check "This is a pre-release"
7. Click "Publish release"

**Release Description Template:**

```markdown
# 🎉 Patience v0.1.0-beta.1 - First Beta Release

Patience is a comprehensive chatbot testing framework with three powerful modes: live testing, log analysis, and AI-powered adversarial testing.

## ✨ Features

### Live Testing
- Scenario-based testing with HTTP/WebSocket support
- Multiple validation types (exact, pattern, semantic)
- Comprehensive reporting (JSON, HTML, Markdown)

### Chat Log Analysis
- Retrospective testing of historical conversations
- Multi-format support (JSON, CSV, text)
- Pattern detection and context analysis
- Advanced filtering and metrics

### Adversarial Testing
- AI-powered bot-to-bot testing
- Support for Ollama (local/free), OpenAI, and Anthropic
- Multiple testing strategies (exploratory, adversarial, focused, stress)
- Real-time validation and comprehensive logging

## 📦 Installation

```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/patience.git
cd patience

# Install dependencies
npm install

# Build
npm run build

# Test it works
node dist/cli.js --help
```

## 🚀 Quick Start

```bash
# Live testing
node dist/cli.js config.json

# Log analysis
node dist/cli.js analyze examples/sample-logs/conversations.json

# Adversarial testing (requires Ollama)
node dist/cli.js adversarial --target http://localhost:3000/chat --adversary ollama
```

## 📚 Documentation

- [README](README.md) - Overview and quick start
- [DOCUMENTATION](DOCUMENTATION.md) - Complete documentation guide
- [ADVERSARIAL_TESTING](examples/ADVERSARIAL_TESTING.md) - Detailed adversarial guide
- [CONTRIBUTING](CONTRIBUTING.md) - Contribution guidelines

## ⚠️ Beta Notice

This is a beta release. The core functionality is stable and tested, but you may encounter bugs or rough edges. Please report issues!

## 🐛 Known Issues

- None currently

## 🙏 Feedback Welcome

Try it out and let us know what you think! Open issues for bugs, feature requests, or questions.

## 📝 Full Changelog

See [CHANGELOG.md](CHANGELOG.md) for detailed changes.

---

**Note:** This is not yet published to npm. Install from source for now.
```

### 9. Optional: Publish to npm

**For beta testing only** (not recommended for first public beta):

```bash
# Login to npm (if not already)
npm login

# Publish as beta
npm publish --tag beta

# Users can then install with:
# npm install -g patience-chatbot@beta
```

**Recommendation:** Wait for initial feedback before publishing to npm.

### 10. Announce the Release

Consider announcing on:
- GitHub Discussions (if enabled)
- Twitter/X
- Reddit (r/chatbots, r/MachineLearning, etc.)
- Dev.to or Medium blog post
- LinkedIn
- Relevant Discord/Slack communities

**Sample Announcement:**

```
🎉 Introducing Patience v0.1.0-beta.1

A comprehensive chatbot testing framework with:
- Live scenario-based testing
- Historical log analysis
- AI-powered adversarial testing (Ollama, OpenAI, Anthropic)

Try it out and let me know what you think!
https://github.com/YOUR_USERNAME/patience

#chatbots #testing #AI #opensource
```

## Post-Release

### Monitor and Respond

1. Watch for GitHub issues
2. Respond to questions promptly
3. Fix critical bugs quickly
4. Collect feedback for next iteration

### Plan Next Release

Based on feedback:
- Fix reported bugs
- Add requested features
- Improve documentation
- Release beta.2, beta.3, etc.

### When Ready for Stable

1. Update version to `0.1.0` (remove beta)
2. Update CHANGELOG
3. Create release
4. Publish to npm without beta tag: `npm publish`

## Troubleshooting

### "npm ERR! 403 Forbidden"
- Package name might be taken
- Try: `patience-chatbot-testing` or similar

### "git push rejected"
- Pull latest changes: `git pull origin main --rebase`
- Then push again

### Build fails
- Check TypeScript errors: `npm run build`
- Fix errors and commit

### Tests fail
- Run tests: `npm test`
- Fix failing tests before release

## Checklist

Before releasing, ensure:
- [ ] All tests pass
- [ ] Build succeeds
- [ ] Documentation is complete
- [ ] CHANGELOG is updated
- [ ] Version is correct in package.json
- [ ] GitHub repository is created
- [ ] Repository URLs are updated in package.json
- [ ] Tag is created and pushed
- [ ] GitHub release is created
- [ ] Examples work

## Need Help?

If you run into issues:
1. Check this guide again
2. Search GitHub for similar issues
3. Ask in GitHub Discussions
4. Open an issue with the "question" label
