# Log Analysis Guide

> **⚠️ IMPORTANT NOTICE**
> 
> This guide documents a **planned feature** that is not yet fully implemented in Patience. Currently, only basic context analysis is available. Full log analysis capabilities including multi-format import, pattern detection, and comprehensive metrics are planned for a future release.
> 
> This documentation serves as a specification for the planned implementation.

---

This guide explains how to use Patience's planned Log Analysis feature to analyze historical conversation logs from your chatbot.

## Overview

Log Analysis (when implemented) will allow you to import conversation logs from your production chatbot and analyze them for patterns, issues, and quality metrics. Unlike Live Testing (which tests in real-time), Log Analysis will work with historical data you've already collected.

## Current Status

**Currently Available:**
- Basic context retention analysis for multi-turn conversations
- Simple conversation quality scoring via `AnalysisEngine.analyzeContextRetention()`

**Planned for Future Release:**
- Multi-format log import (JSON, CSV, text)
- Comprehensive pattern detection
- Statistical metrics calculation
- Advanced filtering and reporting

## Getting Started *(Planned Feature)*

> **Note:** The following steps describe the planned user interface. Currently, only basic context analysis is available through the Analysis tab.

### Step 1: Navigate to Analysis

1. Open Patience
2. Click the **"Analysis"** tab in the sidebar

### Step 2: Prepare Your Log File *(Planned)*

Patience supports three log formats. Choose the one that matches your data:

#### JSON Format (Recommended)

```json
[
  {
    "sender": "user",
    "content": "Hello, I need help",
    "timestamp": "2024-12-12T10:00:00Z"
  },
  {
    "sender": "bot",
    "content": "Hi! How can I assist you today?",
    "timestamp": "2024-12-12T10:00:01Z"
  },
  {
    "sender": "user",
    "content": "What's my order status?",
    "timestamp": "2024-12-12T10:00:15Z"
  }
]
```

**Required Fields**:
- `sender`: Either "user" or "bot"
- `content`: The message text

**Optional Fields**:
- `timestamp`: ISO 8601 format (enables time-based analysis)
- `conversation_id`: Groups messages into conversations
- `metadata`: Additional context (ignored during analysis)

#### CSV Format

```csv
timestamp,sender,content
2024-12-12T10:00:00Z,user,Hello I need help
2024-12-12T10:00:01Z,bot,Hi! How can I assist you today?
2024-12-12T10:00:15Z,user,What's my order status?
```

**Column Requirements**:
- First row must be headers
- Must include `sender` and `content` columns
- `timestamp` column is optional but recommended
- Column order doesn't matter

**Tips**:
- Escape commas in content with quotes: `"Hello, world"`
- Escape quotes with double quotes: `"He said ""hello"""`

#### Plain Text Format

```
Hello, I need help
Hi! How can I assist you today?
What's my order status?
Let me look that up for you.
```

**Rules**:
- Each line is one message
- Lines alternate: user, bot, user, bot...
- First line is always from user
- No timestamps or metadata supported

**Best for**: Quick analysis of simple conversation exports

---

## Creating an Analysis Configuration

### Step 1: Click "New Analysis"

In the Analysis tab, click **"New Analysis"** to open the configuration editor.

### Step 2: Configure Log Source

| Field | Description |
|-------|-------------|
| **Name** | Descriptive name for this analysis |
| **Log File** | Click "Browse" to select your log file |
| **Format** | JSON, CSV, or Text (auto-detected if unsure) |

### Step 3: Configure Filters (Optional)

Filters let you focus on specific portions of your logs:

| Filter | Description | Example |
|--------|-------------|---------|
| **Date Range** | Only analyze messages within dates | Dec 1-15, 2024 |
| **Minimum Messages** | Skip short conversations | At least 3 messages |
| **Maximum Messages** | Skip very long conversations | At most 100 messages |
| **Sender Filter** | Only analyze specific senders | "user" only |

### Step 4: Configure Analysis Settings

| Setting | Description |
|---------|-------------|
| **Detect Patterns** | Find recurring phrases and topics |
| **Calculate Metrics** | Compute response times, lengths, etc. |
| **Identify Anomalies** | Flag unusual conversations |
| **Context Analysis** | Check if bot maintains context |

### Step 5: Configure Validation (Optional)

You can apply validation rules to historical conversations:

| Validation | Description |
|------------|-------------|
| **Pattern Matching** | Check if responses match expected patterns |
| **Semantic Similarity** | Compare responses to expected meanings |
| **Custom Rules** | Apply custom validation logic |

---

## Running Analysis

### Starting Analysis

1. Select your analysis configuration from the list
2. Click **"Run Analysis"**
3. Wait for processing to complete

### During Analysis

- Progress bar shows completion percentage
- Status text shows current operation
- **Cancel** button stops analysis (partial results available)

### Processing Steps

1. **Loading**: Reading log file into memory
2. **Parsing**: Converting to internal format
3. **Filtering**: Applying date/message filters
4. **Analyzing**: Running pattern detection and metrics
5. **Validating**: Applying validation rules (if configured)
6. **Reporting**: Generating results summary

---

## Understanding Results

### Summary Statistics

| Metric | Description |
|--------|-------------|
| **Total Conversations** | Number of distinct conversations |
| **Total Messages** | Total messages across all conversations |
| **Avg Messages/Conversation** | Average conversation length |
| **Avg Response Time** | Average bot response time (if timestamps available) |
| **Pass Rate** | Percentage passing validation (if configured) |

### Pattern Analysis

Patience identifies recurring patterns in your logs:

#### Common Phrases
Shows frequently occurring phrases:
```
"I don't understand" - 47 occurrences (12%)
"Let me help you with that" - 38 occurrences (10%)
"Could you please clarify" - 29 occurrences (8%)
```

#### Topic Clusters
Groups conversations by topic:
```
Order Status - 156 conversations (32%)
Returns/Refunds - 89 conversations (18%)
Product Questions - 67 conversations (14%)
Technical Support - 45 conversations (9%)
```

#### Conversation Flow Patterns
Identifies common conversation paths:
```
Greeting → Question → Answer → Goodbye (45%)
Greeting → Question → Clarification → Answer → Goodbye (28%)
Greeting → Question → Error → Escalation (12%)
```

### Anomaly Detection

Flags unusual conversations for review:

| Anomaly Type | Description |
|--------------|-------------|
| **Unusually Long** | Conversations with many more turns than average |
| **Unusually Short** | Conversations that ended abruptly |
| **High Error Rate** | Conversations with multiple bot errors |
| **Context Loss** | Bot forgot earlier conversation context |
| **Repeated Questions** | User asked same question multiple times |

### Validation Results

If validation rules were configured:

| Result | Description |
|--------|-------------|
| **Passed** | Response met validation criteria |
| **Failed** | Response didn't meet criteria |
| **Skipped** | Validation couldn't be applied |

Each failure includes:
- The message that failed
- The validation rule that failed
- The expected vs actual content
- Suggestions for improvement

---

## Metrics Deep Dive

### Response Time Metrics

*Requires timestamps in your logs*

| Metric | Description | Good Target |
|--------|-------------|-------------|
| **Average** | Mean response time | < 2 seconds |
| **Median** | Middle response time | < 1.5 seconds |
| **P95** | 95th percentile | < 5 seconds |
| **P99** | 99th percentile | < 10 seconds |
| **Max** | Slowest response | < 30 seconds |

### Message Length Metrics

| Metric | Description |
|--------|-------------|
| **Avg User Message** | Average length of user messages |
| **Avg Bot Response** | Average length of bot responses |
| **Response Ratio** | Bot length / User length |

**Interpretation**:
- Ratio < 1: Bot responses shorter than questions (may be too brief)
- Ratio 1-3: Balanced responses
- Ratio > 3: Bot responses much longer (may be too verbose)

### Conversation Metrics

| Metric | Description |
|--------|-------------|
| **Avg Turns** | Average messages per conversation |
| **Resolution Rate** | Conversations ending positively |
| **Escalation Rate** | Conversations requiring human help |
| **Abandonment Rate** | Conversations ending without resolution |

---

## Filtering Strategies

### By Date Range

**Use Case**: Analyze conversations from a specific period

```
Start Date: 2024-12-01
End Date: 2024-12-15
```

**Good for**:
- Before/after comparisons (after bot update)
- Seasonal analysis
- Incident investigation

### By Conversation Length

**Use Case**: Focus on meaningful conversations

```
Minimum Messages: 4
Maximum Messages: 50
```

**Good for**:
- Filtering out "hello/goodbye" only conversations
- Excluding runaway conversations
- Focusing on typical interactions

### By Content

**Use Case**: Analyze specific topics

```
Content Contains: "refund"
```

**Good for**:
- Topic-specific analysis
- Issue investigation
- Feature usage analysis

---

## Validation in Log Analysis

### Why Validate Historical Logs?

1. **Quality Auditing**: Check if past responses met standards
2. **Regression Detection**: Find when quality degraded
3. **Training Data Validation**: Ensure logs are suitable for training
4. **Compliance Checking**: Verify responses met requirements

### Setting Up Validation

1. In the analysis configuration, enable **"Apply Validation"**
2. Add validation rules:

#### Pattern Validation
```
Rule: Bot should greet users
Pattern: hello|hi|hey|welcome
Apply To: First bot message
```

#### Semantic Validation
```
Rule: Responses should be helpful
Expected: "helpful and informative response"
Threshold: 0.7
Apply To: All bot messages
```

### Validation Results

Results show:
- Overall pass rate
- Pass rate by rule
- Failed conversations (for review)
- Trends over time

---

## Exporting Results

### Export Formats

| Format | Best For |
|--------|----------|
| **HTML** | Sharing with stakeholders, presentations |
| **JSON** | Integration with other tools, further analysis |
| **Markdown** | Documentation, version control |
| **CSV** | Spreadsheet analysis, data processing |

### Export Contents

All exports include:
- Summary statistics
- Pattern analysis results
- Anomaly list
- Validation results (if applicable)
- Sample conversations

### Batch Export

Export multiple analyses at once:
1. Select analyses in the list (Cmd+click for multiple)
2. Click **"Export Selected"**
3. Choose format and destination

---

## Best Practices

### Log Collection

1. **Include Timestamps**: Enables response time analysis
2. **Include Conversation IDs**: Groups related messages
3. **Use Consistent Format**: Easier parsing and analysis
4. **Regular Exports**: Analyze frequently, not just when problems occur

### Analysis Frequency

| Frequency | Purpose |
|-----------|---------|
| **Daily** | Monitor for immediate issues |
| **Weekly** | Track trends and patterns |
| **Monthly** | Comprehensive quality review |
| **After Updates** | Regression testing |

### Interpreting Results

1. **Compare to Baseline**: Establish normal metrics first
2. **Look for Trends**: Single data points can be misleading
3. **Investigate Anomalies**: Don't ignore outliers
4. **Act on Findings**: Analysis is only valuable if you improve

### Common Pitfalls

| Pitfall | Solution |
|---------|----------|
| Analyzing too little data | Use at least 1000 conversations |
| Ignoring context | Review actual conversations, not just metrics |
| Over-filtering | Start broad, then narrow down |
| Not validating | Add validation rules for quality assurance |

---

## Troubleshooting

### "Failed to Parse Log File"

**Causes**:
- Incorrect format selected
- Malformed JSON/CSV
- Encoding issues

**Solutions**:
1. Verify file format matches selection
2. Validate JSON at jsonlint.com
3. Check CSV for unescaped commas
4. Ensure UTF-8 encoding

### "No Conversations Found"

**Causes**:
- Filters too restrictive
- Empty log file
- Wrong date format

**Solutions**:
1. Remove all filters and try again
2. Verify file contains data
3. Check date format matches expected

### "Analysis Taking Too Long"

**Causes**:
- Very large log file
- Complex validation rules
- Semantic analysis on many messages

**Solutions**:
1. Use date filters to reduce data
2. Simplify validation rules
3. Use pattern matching instead of semantic
4. Split into multiple smaller analyses

### "Unexpected Results"

**Causes**:
- Data quality issues
- Incorrect sender labels
- Missing messages

**Solutions**:
1. Review raw log file
2. Verify sender field values
3. Check for gaps in conversation IDs
4. Validate data before analysis

---

## Example: Complete Analysis Workflow

### Scenario: Monthly Quality Review

**Goal**: Analyze December 2024 conversations for quality trends

### Step 1: Export Logs

Export conversations from your chatbot platform:
```bash
# Example: Export from your system
chatbot-cli export --start 2024-12-01 --end 2024-12-31 --format json > december_logs.json
```

### Step 2: Create Analysis Configuration

**Log Source**:
- Name: "December 2024 Review"
- File: december_logs.json
- Format: JSON

**Filters**:
- Minimum Messages: 3 (skip trivial conversations)

**Analysis Settings**:
- ✅ Detect Patterns
- ✅ Calculate Metrics
- ✅ Identify Anomalies
- ✅ Context Analysis

**Validation**:
- Rule 1: "Greeting present" - Pattern: `hello|hi|welcome`
- Rule 2: "No errors" - Pattern: `(?!.*error|sorry|can't help)`
- Rule 3: "Helpful tone" - Semantic: "helpful response", threshold 0.7

### Step 3: Run Analysis

Click "Run Analysis" and wait for completion.

### Step 4: Review Results

**Summary**:
- 2,847 conversations analyzed
- 89% pass rate
- Average 6.2 messages per conversation
- Average response time: 1.3 seconds

**Key Findings**:
- "I don't understand" appeared 312 times (11%)
- 47 conversations flagged as anomalies
- Context loss detected in 3% of conversations

### Step 5: Take Action

Based on findings:
1. Review the 47 anomalous conversations
2. Investigate "I don't understand" triggers
3. Improve context retention for long conversations
4. Update training data with failed examples

### Step 6: Export Report

Export HTML report for stakeholder presentation.

---

## Next Steps

- **[Live Testing Guide](LIVE_TESTING_GUIDE.md)**: Test your bot in real-time ✅
- **[Adversarial Testing Guide](ADVERSARIAL_TESTING_GUIDE.md)**: AI-powered edge case testing ✅
- **[DOCUMENTATION.md](../DOCUMENTATION.md)**: Complete technical reference

---

> **Development Note:** This guide documents planned functionality. The current Patience release includes basic context analysis only. Full log analysis features including multi-format import, pattern detection, and comprehensive metrics are planned for future implementation. Check the project roadmap for updates on development progress.
