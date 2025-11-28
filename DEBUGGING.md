# Debugging Guide

## Live Testing Debugging

### 1. Enable Verbose Output

For live testing, enable verbose errors in your config:

```json
{
  "reporting": {
    "verboseErrors": true,
    "includeConversationHistory": true
  }
}
```

This will show:
- Detailed error messages
- Full conversation history in reports
- Validation failure reasons
- Response timing information

### 2. Check Your Configuration

**Common Issues:**

#### Target Bot Endpoint
```json
{
  "targetBot": {
    "name": "My Bot",
    "protocol": "http",              // "http" or "websocket"
    "endpoint": "http://localhost:3000/chat",  // ✓ Correct format
    // NOT: "localhost:3000" or missing http://
    
    // Optional: For Ollama bots
    "provider": "ollama",            // "ollama" or "generic" (default)
    "model": "llama2"                // Required if provider is "ollama"
  }
}
```

#### Scenario Structure
```json
{
  "scenarios": [
    {
      "id": "test-1",                // Required: unique ID
      "name": "Test Scenario",       // Required: display name
      "steps": [                     // Required: at least one step
        {
          "message": "Hello",        // Required: message to send
          "expectedResponse": {      // Optional but recommended
            "validationType": "pattern",  // "exact", "pattern", "semantic"
            "expected": "hi|hello"   // What to expect
          }
        }
      ],
      "expectedOutcomes": []         // Required: can be empty array
    }
  ]
}
```

#### Validation Types
```json
// Exact match
{
  "validationType": "exact",
  "expected": "Hello, how can I help you?"
}

// Pattern (regex)
{
  "validationType": "pattern",
  "expected": "hello|hi|hey"
}

// Semantic similarity
{
  "validationType": "semantic",
  "expected": "I can help you with that",
  "threshold": 0.7  // 0.0 to 1.0
}
```

### 3. Test Target Bot Connection

Verify your bot is accessible:

```bash
# For HTTP bots
curl -X POST http://localhost:3000/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Hello"}'

# Check what response format you get
# Patience expects: { "content": "response text" }
# or just: "response text"
```

### 4. Run with Minimal Config

Start with the simplest configuration:

**Generic Bot:**
```json
{
  "targetBot": {
    "name": "Test Bot",
    "protocol": "http",
    "endpoint": "http://localhost:3000/chat"
  },
  "scenarios": [
    {
      "id": "simple-test",
      "name": "Simple Test",
      "steps": [
        {
          "message": "Hello"
        }
      ],
      "expectedOutcomes": []
    }
  ],
  "validation": {
    "defaultType": "pattern"
  },
  "timing": {
    "enableDelays": false,
    "baseDelay": 0,
    "delayPerCharacter": 0,
    "rapidFire": true,
    "responseTimeout": 30000
  },
  "reporting": {
    "outputPath": "./reports",
    "formats": ["html"],
    "includeConversationHistory": true,
    "verboseErrors": true
  }
}
```

**Ollama Bot:**
```json
{
  "targetBot": {
    "name": "Ollama Bot",
    "protocol": "http",
    "endpoint": "http://localhost:11434/api/chat",
    "provider": "ollama",
    "model": "llama2"
  },
  "scenarios": [
    {
      "id": "simple-test",
      "name": "Simple Test",
      "steps": [
        {
          "message": "Hello"
        }
      ],
      "expectedOutcomes": []
    }
  ],
  "validation": {
    "defaultType": "pattern"
  },
  "timing": {
    "enableDelays": false,
    "baseDelay": 0,
    "delayPerCharacter": 0,
    "rapidFire": true,
    "responseTimeout": 30000
  },
  "reporting": {
    "outputPath": "./reports",
    "formats": ["html"],
    "includeConversationHistory": true,
    "verboseErrors": true
  }
}
```

### 5. Check Reports

Live testing generates detailed reports:

```bash
# View HTML report (most readable)
open reports/report-*.html

# View JSON for details
cat reports/report-*.json

# View markdown
cat reports/report-*.markdown
```

### 6. Common Live Testing Errors

#### "Connection refused" / "ECONNREFUSED"
**Solution:**
- Verify target bot is running
- Check port number is correct
- Test with curl first

#### "Timeout waiting for response"
**Solution:**
- Increase `responseTimeout` in timing config
- Check if bot is responding slowly
- Verify bot endpoint is correct

#### "Validation failed"
**Solution:**
- Check expected response matches actual response
- Use `verboseErrors: true` to see what was received
- Try `pattern` validation instead of `exact`
- Review HTML report for actual vs expected

#### "Invalid configuration"
**Solution:**
- Validate JSON syntax
- Check all required fields are present
- Ensure scenarios array is not empty

### 7. Validate JSON Syntax

```bash
# Using Node.js
node -e "console.log(JSON.parse(require('fs').readFileSync('config.json')))"

# Using Python
python -m json.tool config.json

# Using jq
jq . config.json
```

## Adversarial Testing Debugging

### 1. Enable Verbose Output

For adversarial testing, ensure `realTimeMonitoring` is enabled in your config:

```json
{
  "reporting": {
    "realTimeMonitoring": true
  }
}
```

This will show:
- Each turn of the conversation
- Messages from both bots
- Validation results in real-time
- Error messages with details

### 2. Check Your Configuration

**Common Issues:**

#### Target Bot Endpoint
```json
{
  "targetBot": {
    "endpoint": "http://localhost:3000/chat"  // ✓ Correct
    // NOT: "localhost:3000" or "http://localhost:3000/"
  }
}
```

#### Ollama Endpoint
```json
{
  "adversarialBot": {
    "provider": "ollama",
    "endpoint": "http://localhost:11434"  // ✓ Default Ollama port
  }
}
```

#### Required Fields
```json
{
  "targetBot": {
    "name": "My Bot",           // Required
    "protocol": "http",         // Required: "http" or "websocket"
    "endpoint": "..."           // Required
  },
  "adversarialBot": {
    "provider": "ollama",       // Required
    "model": "llama2"           // Required
  },
  "conversation": {
    "strategy": "exploratory",  // Required
    "maxTurns": 10              // Required
  },
  "execution": {
    "numConversations": 1       // Required
  },
  "reporting": {
    "outputPath": "./reports",  // Required
    "formats": ["json"],        // Required
    "includeTranscripts": true, // Required
    "realTimeMonitoring": true  // Required
  }
}
```

### 3. Test Ollama Connection

Before running Patience, verify Ollama is working:

```bash
# Check if Ollama is running
curl http://localhost:11434/api/tags

# Test with a simple prompt
curl http://localhost:11434/api/generate -d '{
  "model": "llama2",
  "prompt": "Hello",
  "stream": false
}'
```

### 4. Test Target Bot Connection

Verify your target bot is accessible:

```bash
# For HTTP bots
curl -X POST http://localhost:3000/chat \
  -H "Content-Type: application/json" \
  -d '{"message": "Hello"}'
```

### 5. Run with Minimal Config

Start with the simplest possible configuration:

```json
{
  "targetBot": {
    "name": "Test Bot",
    "protocol": "http",
    "endpoint": "http://localhost:3000/chat"
  },
  "adversarialBot": {
    "provider": "ollama",
    "model": "llama2"
  },
  "conversation": {
    "strategy": "exploratory",
    "maxTurns": 3
  },
  "execution": {
    "numConversations": 1
  },
  "reporting": {
    "outputPath": "./test-reports",
    "formats": ["json"],
    "includeTranscripts": true,
    "realTimeMonitoring": true
  }
}
```

### 6. Check Error Messages

Patience provides detailed error messages:

**Configuration Errors:**
```
Configuration validation failed:
- Target bot endpoint is required
- Max turns must be greater than 0
```

**Connection Errors:**
```
Failed to connect to Ollama: Cannot connect to Ollama. 
Make sure Ollama is running (ollama serve)
```

**Model Errors:**
```
Model 'llama2' not found. Pull it with: ollama pull llama2
```

### 7. Validate JSON Syntax

Use a JSON validator to check your config file:

```bash
# Using Node.js
node -e "console.log(JSON.parse(require('fs').readFileSync('config.json')))"

# Using Python
python -m json.tool config.json

# Using jq
jq . config.json
```

## Common Errors and Solutions

### "Cannot connect to Ollama"

**Solution:**
```bash
# Start Ollama
ollama serve

# In another terminal, pull the model
ollama pull llama2
```

### "Target bot endpoint is required"

**Solution:** Check your config has `targetBot.endpoint` set

### "ECONNREFUSED"

**Solutions:**
- Verify the target bot is running
- Check the port number is correct
- Ensure no firewall is blocking the connection

### "Model not found"

**Solution:**
```bash
ollama pull llama2
# or
ollama pull mistral
```

### "Validation failed"

**Solution:** Check your validation rules match expected bot responses

### JSON Parse Error

**Solution:** Validate JSON syntax:
- Check for missing commas
- Check for trailing commas (not allowed in JSON)
- Check quotes are properly closed
- Use a JSON validator

## Getting More Information

### 1. Check the Logs

Adversarial testing saves detailed logs:

```bash
# View the conversation log
cat ./adversarial-reports/conversation-*.txt

# View JSON for programmatic analysis
cat ./adversarial-reports/conversation-*.json
```

### 2. Enable All Logging

```json
{
  "reporting": {
    "realTimeMonitoring": true,
    "includeTranscripts": true,
    "formats": ["json", "text"]
  }
}
```

### 3. Reduce Complexity

If something fails:
1. Reduce `maxTurns` to 1-3
2. Set `numConversations` to 1
3. Remove validation rules
4. Use simplest strategy ("exploratory")

### 4. Test Components Separately

**Test Ollama:**
```bash
patience adversarial --help
```

**Test Target Bot:**
```bash
curl -X POST http://localhost:3000/chat -d '{"message":"test"}'
```

## Example Debugging Sessions

### Live Testing Debug Session

```bash
# 1. Test target bot is accessible
curl -X POST http://localhost:3000/chat \
  -H "Content-Type: application/json" \
  -d '{"message":"hello"}'
# Should return a response

# 2. Validate config JSON
node -e "console.log(JSON.parse(require('fs').readFileSync('config.json')))"
# Should print parsed JSON without errors

# 3. Run with verbose errors
patience config.json
# Check console output for errors

# 4. Review the HTML report
open reports/report-*.html
# Look for validation failures and actual responses

# 5. Check JSON report for details
cat reports/report-*.json | jq .
# See full conversation history and errors
```

### Adversarial Testing Debug Session

```bash
# 1. Verify Ollama is running (if using Ollama)
curl http://localhost:11434/api/tags
# Should return list of models

# 2. Verify model is available
ollama list
# Should show llama2

# 3. Test target bot
curl -X POST http://localhost:3000/chat -d '{"message":"hello"}'
# Should return a response

# 4. Validate config JSON
node -e "console.log(JSON.parse(require('fs').readFileSync('config.json')))"
# Should print parsed JSON

# 5. Run with verbose logging
patience adversarial --config config.json
# Watch for error messages in real-time

# 6. Check conversation logs
cat adversarial-reports/conversation-*.txt
# Review full conversation transcript
```

## Still Having Issues?

1. **Check the reports/logs** in the output directory
2. **Share the error message** - the full error output helps identify the issue
3. **Verify all services are running** - your target bot (and Ollama for adversarial)
4. **Try the simple-config.json** from the examples directory
5. **Check GitHub issues** for similar problems

## Quick Checklists

### Live Testing Checklist
- [ ] Target bot is running and accessible
- [ ] Config JSON is valid (no syntax errors)
- [ ] All required fields are present (targetBot, scenarios, validation, timing, reporting)
- [ ] Scenarios array has at least one scenario
- [ ] Each scenario has id, name, steps, and expectedOutcomes
- [ ] `verboseErrors` is set to `true`
- [ ] Endpoints use correct format (http://host:port/path)
- [ ] Test bot with curl before running Patience

### Adversarial Testing Checklist
- [ ] Ollama is running (`ollama serve`) - if using Ollama
- [ ] Model is pulled (`ollama pull llama2`) - if using Ollama
- [ ] API key is set - if using OpenAI/Anthropic
- [ ] Target bot is running and accessible
- [ ] Config JSON is valid (no syntax errors)
- [ ] All required fields are present
- [ ] `realTimeMonitoring` is set to `true`
- [ ] Endpoints use correct format (http://host:port/path)
- [ ] Ports are correct (Ollama: 11434, your bot: varies)

## Testing Mode Quick Reference

| Mode | Verbose Setting | Output Location | Best for Debugging |
|------|----------------|-----------------|-------------------|
| Live Testing | `verboseErrors: true` | `./reports/` | HTML reports |
| Log Analysis | N/A (always verbose) | `./analysis-reports/` | HTML reports |
| Adversarial | `realTimeMonitoring: true` | `./adversarial-reports/` | Console + text logs |
