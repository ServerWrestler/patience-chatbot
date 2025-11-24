# Quick Start - Beta Release

## 🚀 Ready to Release in 3 Steps!

### Step 1: Commit and Tag (2 minutes)

```bash
# Make sure everything is committed
git add .
git commit -m "chore: prepare for v0.1.0-beta.1 release"

# Create and push tag
git tag -a v0.1.0-beta.1 -m "Release v0.1.0-beta.1"
git push origin main
git push origin v0.1.0-beta.1
```

### Step 2: Create GitHub Release (5 minutes)

1. Go to: https://github.com/ServerWrestler/patience-chatbot/releases/new
2. Choose tag: `v0.1.0-beta.1`
3. Title: `Patience v0.1.0-beta.1 - Beta Release`
4. Copy this description:

```markdown
# 🎉 Patience v0.1.0-beta.1 - First Beta Release

Comprehensive chatbot testing framework with three powerful modes.

## Features

- **Live Testing** - Scenario-based testing with HTTP/WebSocket
- **Log Analysis** - Retrospective conversation analysis  
- **Adversarial Testing** - AI-powered bot-to-bot testing (Ollama, OpenAI, Anthropic)

## Installation

```bash
git clone https://github.com/ServerWrestler/patience-chatbot.git
cd patience-chatbot
npm install && npm run build
```

## Quick Start

```bash
# Live testing
node dist/cli.js config.json

# Log analysis
node dist/cli.js analyze examples/sample-logs/conversations.json

# Adversarial testing (requires Ollama)
node dist/cli.js adversarial --target http://localhost:3000/chat --adversary ollama
```

## Documentation

- [README](README.md) - Overview
- [ADVERSARIAL_TESTING](examples/ADVERSARIAL_TESTING.md) - Detailed guide
- [CONTRIBUTING](CONTRIBUTING.md) - How to contribute

## Beta Notice

This is a beta release. Core functionality is stable but feedback welcome!

Report issues: https://github.com/ServerWrestler/patience-chatbot/issues
```

5. Check "This is a pre-release"
6. Click "Publish release"

### Step 3: Test It (3 minutes)

```bash
# In a new directory
git clone https://github.com/ServerWrestler/patience-chatbot.git test
cd test
npm install
npm run build
node dist/cli.js --help
```

## ✅ Done!

Your beta is now live at:
https://github.com/ServerWrestler/patience-chatbot

## 📢 Optional: Announce It

Share on Twitter/LinkedIn:

```
🎉 Just released Patience v0.1.0-beta.1!

A comprehensive chatbot testing framework with:
✅ Live scenario testing
✅ Historical log analysis
✅ AI-powered adversarial testing

Try it out: https://github.com/ServerWrestler/patience-chatbot

#chatbots #testing #AI #opensource
```

## 🐛 After Release

- Monitor issues: https://github.com/ServerWrestler/patience-chatbot/issues
- Respond to feedback
- Plan beta.2 based on input

---

**Need more details?** See [RELEASE_GUIDE.md](RELEASE_GUIDE.md)
