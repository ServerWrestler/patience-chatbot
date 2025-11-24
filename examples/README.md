# Patience Examples

This directory contains example configurations and sample data for all three testing modes.

## Directory Structure

```
examples/
├── live-testing/          # Live scenario-based testing
│   ├── README.md          # Detailed guide
│   ├── config.json        # Complete configuration
│   ├── simple-config.json # Minimal setup
│   └── advanced-config.json # Advanced features
│
├── log-analysis/          # Historical log analysis
│   ├── README.md          # Detailed guide
│   ├── config.json        # Complete configuration
│   ├── simple-config.json # Minimal setup
│   ├── filtered-config.json # Advanced filtering
│   └── sample-logs/       # Example log files
│       ├── README.md      # Format specifications
│       ├── USAGE.md       # Quick start
│       ├── conversations.json
│       ├── conversations.csv
│       └── conversations.txt
│
└── adversarial-testing/   # AI-powered bot-to-bot testing
    ├── README.md          # Complete guide
    ├── simple-config.json # Minimal setup (Ollama)
    ├── adversarial-config.json # Ollama configuration
    ├── adversarial-openai-config.json # OpenAI configuration
    └── adversarial-anthropic-config.json # Anthropic configuration
```

## Quick Start

### Live Testing

Test your bot in real-time with predefined scenarios:

```bash
patience examples/live-testing/config.json
```

See [live-testing/README.md](live-testing/README.md) for details.

### Log Analysis

Analyze historical conversation logs:

```bash
patience analyze examples/log-analysis/sample-logs/conversations.json
```

See [log-analysis/README.md](log-analysis/README.md) for details.

### Adversarial Testing

Run AI-powered bot-to-bot testing:

```bash
patience adversarial --config examples/adversarial-testing/simple-config.json
```

See [adversarial-testing/README.md](adversarial-testing/README.md) for details.

## Configuration Files

Each directory contains multiple configuration examples:

- **config.json** - Complete configuration with all options
- **simple-config.json** - Minimal setup to get started quickly
- **advanced/filtered-config.json** - Advanced features and options

## Sample Data

The `log-analysis/sample-logs/` directory contains example conversation logs in three formats:

- **conversations.json** - JSON format
- **conversations.csv** - CSV format
- **conversations.txt** - Text format

These can be used to test the log analysis features.

## Getting Started

1. **Choose your testing mode:**
   - Live testing for real-time validation
   - Log analysis for retrospective testing
   - Adversarial testing for AI-powered testing

2. **Start with simple configuration:**
   - Copy `simple-config.json` from the relevant directory
   - Update endpoint/paths for your setup
   - Run the test

3. **Explore advanced features:**
   - Review the complete `config.json` files
   - Try different options and strategies
   - Customize for your use case

## Tips

- Start with simple configurations before adding complexity
- Review the README in each directory for detailed documentation
- Use sample logs to test analysis features before using production data
- For adversarial testing, start with Ollama (local/free) before trying paid APIs

## Need Help?

- Check the README in each subdirectory for detailed guides
- See [../README.md](../README.md) for overall documentation
- See [../DOCUMENTATION.md](../DOCUMENTATION.md) for complete documentation guide
