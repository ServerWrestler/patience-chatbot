/**
 * CLI for adversarial chatbot testing
 */

import * as fs from 'fs/promises';
import { AdversarialTestOrchestrator, AdversarialTestConfig } from './adversarial';

export async function runAdversarialCommand(args: string[]): Promise<void> {
  // Parse command line arguments
  const options = parseArgs(args);

  if (options.help) {
    printHelp();
    return;
  }

  try {
    // Load configuration
    const config = await loadConfiguration(options);

    // Run adversarial tests
    const orchestrator = new AdversarialTestOrchestrator(config);
    await orchestrator.run();

    process.exit(0);
  } catch (error: any) {
    console.error(`\n❌ Error: ${error.message}\n`);
    process.exit(1);
  }
}

interface CommandOptions {
  help?: boolean;
  config?: string;
  target?: string;
  adversary?: string;
  model?: string;
  strategy?: string;
  turns?: number;
  conversations?: number;
  output?: string;
}

function parseArgs(args: string[]): CommandOptions {
  const options: CommandOptions = {};

  for (let i = 0; i < args.length; i++) {
    const arg = args[i];

    switch (arg) {
      case '-h':
      case '--help':
        options.help = true;
        break;
      case '-c':
      case '--config':
        options.config = args[++i];
        break;
      case '-t':
      case '--target':
        options.target = args[++i];
        break;
      case '-a':
      case '--adversary':
        options.adversary = args[++i];
        break;
      case '-m':
      case '--model':
        options.model = args[++i];
        break;
      case '-s':
      case '--strategy':
        options.strategy = args[++i];
        break;
      case '--turns':
        options.turns = parseInt(args[++i], 10);
        break;
      case '--conversations':
        options.conversations = parseInt(args[++i], 10);
        break;
      case '-o':
      case '--output':
        options.output = args[++i];
        break;
    }
  }

  return options;
}

async function loadConfiguration(options: CommandOptions): Promise<AdversarialTestConfig> {
  // If config file is provided, load it
  if (options.config) {
    const configContent = await fs.readFile(options.config, 'utf-8');
    const config = JSON.parse(configContent) as AdversarialTestConfig;

    // Override with command-line options
    if (options.target) {
      config.targetBot.endpoint = options.target;
    }
    if (options.adversary) {
      config.adversarialBot.provider = options.adversary as any;
    }
    if (options.model) {
      config.adversarialBot.model = options.model;
    }
    if (options.strategy) {
      config.conversation.strategy = options.strategy as any;
    }
    if (options.turns) {
      config.conversation.maxTurns = options.turns;
    }
    if (options.conversations) {
      config.execution.numConversations = options.conversations;
    }
    if (options.output) {
      config.reporting.outputPath = options.output;
    }

    return config;
  }

  // Build config from command-line options
  if (!options.target) {
    throw new Error('Target bot endpoint is required (--target or --config)');
  }

  const config: AdversarialTestConfig = {
    targetBot: {
      name: 'Target Bot',
      protocol: 'http',
      endpoint: options.target,
    },
    adversarialBot: {
      provider: (options.adversary as any) || 'ollama',
      model: options.model || 'llama2',
    },
    conversation: {
      strategy: (options.strategy as any) || 'exploratory',
      maxTurns: options.turns || 10,
    },
    execution: {
      numConversations: options.conversations || 1,
    },
    reporting: {
      outputPath: options.output || './adversarial-reports',
      formats: ['json'],
      includeTranscripts: true,
      realTimeMonitoring: true,
    },
  };

  return config;
}

function printHelp(): void {
  console.log(`
Patience - Adversarial Chatbot Testing

Usage:
  patience adversarial [options]

Options:
  -c, --config <file>         Path to configuration file (JSON)
  -t, --target <url>          Target bot endpoint
  -a, --adversary <provider>  Adversarial bot provider: ollama, openai, anthropic (default: ollama)
  -m, --model <model>         Model name (e.g., llama2, gpt-4, claude-3)
  -s, --strategy <strategy>   Testing strategy: exploratory, adversarial, focused, stress (default: exploratory)
  --turns <number>            Maximum turns per conversation (default: 10)
  --conversations <number>    Number of conversations to run (default: 1)
  -o, --output <path>         Output directory for reports (default: ./adversarial-reports)
  -h, --help                  Show this help message

Examples:
  # Quick start with Ollama (local)
  patience adversarial --target http://localhost:3000/chat --adversary ollama

  # Use configuration file
  patience adversarial --config adversarial-config.json

  # Specify all parameters
  patience adversarial \\
    --target http://localhost:3000/chat \\
    --adversary ollama \\
    --model llama2 \\
    --strategy adversarial \\
    --turns 20 \\
    --conversations 5

  # Run with OpenAI (requires API key in config)
  patience adversarial --config openai-config.json

Configuration File Format:
  {
    "targetBot": {
      "name": "My Bot",
      "protocol": "http",
      "endpoint": "http://localhost:3000/chat"
    },
    "adversarialBot": {
      "provider": "ollama",
      "model": "llama2",
      "endpoint": "http://localhost:11434",
      "temperature": 0.7
    },
    "conversation": {
      "strategy": "exploratory",
      "maxTurns": 10,
      "goals": ["Test greeting capabilities", "Test error handling"]
    },
    "validation": {
      "rules": [
        {
          "type": "pattern",
          "expected": "help|assist|support"
        }
      ],
      "realTime": true
    },
    "execution": {
      "numConversations": 5,
      "concurrent": 2,
      "delayBetweenTurns": 1000
    },
    "reporting": {
      "outputPath": "./adversarial-reports",
      "formats": ["json", "text", "csv"],
      "includeTranscripts": true,
      "realTimeMonitoring": true
    }
  }

Strategies:
  exploratory  - Broad, diverse questions to map capabilities
  adversarial  - Edge cases, contradictions, challenging inputs
  focused      - Deep dive into specific features (requires goals)
  stress       - Rapid context switching, complex inputs

Providers:
  ollama       - Local models (llama2, mistral, etc.) - No API key needed
  openai       - OpenAI models (gpt-4, gpt-3.5) - Requires API key
  anthropic    - Anthropic models (claude-3) - Requires API key

Setup Ollama:
  1. Install Ollama: https://ollama.ai
  2. Pull a model: ollama pull llama2
  3. Start Ollama: ollama serve
  4. Run tests: patience adversarial --target <your-bot> --adversary ollama
`);
}
