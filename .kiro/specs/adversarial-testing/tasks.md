# Implementation Plan: Adversarial Chatbot Testing

## Phase 1: Core Infrastructure ✅

- [x] 1. Set up adversarial testing module structure
  - [x] 1.1 Create src/adversarial directory structure
    - Created Patience/Core/AdversarialTestOrchestrator.swift
    - _Requirements: All requirements - foundation_
  
  - [x] 1.2 Define core types and interfaces
    - Defined AdversarialTestConfig, ConversationResult, AdversarialMessage types in Types.swift
    - Defined AdversarialBotConnector protocol
    - Defined PromptStrategy protocol
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 7.1_

- [x] 2. Implement base connector interface
  - [x] 2.1 Create AdversarialBotConnector protocol
    - Defined initialize(), generateMessage(), disconnect() methods
    - Defined shouldEndConversation() method
    - _Requirements: 1.1, 1.3_
  
  - [x] 2.2 Create base connector utilities
    - Error handling via AdversarialError enum
    - Rate limiting in checkSafetyControls()
    - Response parsing in each connector
    - _Requirements: 9.1, 9.4_

## Phase 2: LLM Provider Connectors ✅

- [x] 3. Implement OpenAI Connector
  - [x] 3.1 Create OpenAIConnector class
    - Implemented full OpenAI chat completions API integration
    - Supports GPT-4, GPT-4-turbo, and GPT-3.5 models
    - _Requirements: 1.1, 1.3_
  
  - [x] 3.2 Handle OpenAI-specific features
    - Cost tracking in updateSafetyTracking()
    - Temperature and max_tokens configuration
    - Message history formatting
    - _Requirements: 1.4, 9.2_
  
  - [x] 3.3 Implement error handling
    - HTTP status code checking
    - API key validation on initialize
    - Detailed error messages with status codes
    - _Requirements: 9.1, 9.4_

- [x] 4. Implement Anthropic Connector
  - [x] 4.1 Create AnthropicConnector class
    - Implemented full Anthropic messages API integration
    - Supports Claude 3 Opus, Sonnet, and Haiku models
    - _Requirements: 1.1, 1.3_
  
  - [x] 4.2 Handle Anthropic-specific features
    - Cost tracking in updateSafetyTracking()
    - Temperature configuration
    - System prompt support via dedicated field
    - _Requirements: 1.4, 9.2_
  
  - [x] 4.3 Implement error handling
    - HTTP status code checking
    - API key validation on initialize
    - Detailed error messages with status codes
    - _Requirements: 9.1, 9.4_

- [x] 5. Implement Ollama Connector
  - [x] 5.1 Create OllamaConnector class
    - Implemented Ollama HTTP API integration
    - Supports local model connections (llama2, mistral, etc.)
    - _Requirements: 1.1, 1.3_
  
  - [x] 5.2 Handle Ollama-specific features
    - Model selection via configuration
    - Local endpoint configuration (default: localhost:11434)
    - No authentication required
    - _Requirements: 1.3, 1.4_
  
  - [x] 5.3 Implement error handling
    - Connection failure handling
    - HTTP status code checking
    - Detailed error messages
    - _Requirements: 9.4_

- [x] 6. Implement Generic Connector
  - [x] 6.1 Create GenericConnector class
    - Generic HTTP support
    - Configurable request/response format
    - _Requirements: 1.1_
  
  - [x] 6.2 Support flexible configuration
    - Custom headers and authentication (Bearer token)
    - Multiple response format parsing strategies
    - _Requirements: 1.3_

## Phase 3: Conversation Management ✅

- [x] 7. Implement Conversation Manager
  - [x] 7.1 Create ConversationManager (AdversarialTestOrchestrator)
    - Initializes adversarial and target bot connectors
    - Manages conversation state via runSingleConversation()
    - _Requirements: 2.1, 2.2_
  
  - [x] 7.2 Implement turn execution
    - Adversarial bot generates message via connector
    - Sends to target bot via CommunicationManager
    - Receives and processes response
    - _Requirements: 2.2_
  
  - [x] 7.3 Implement termination logic
    - Checks max turns
    - Checks goal achievement via strategy
    - Handles timeouts and errors with defer blocks
    - _Requirements: 2.3_
  
  - [x] 7.4 Add conversation context tracking
    - Maintains message history in messages array
    - Tracks validation results per turn
    - Updates metrics (response time, quality)
    - _Requirements: 2.2, 4.1, 4.4_

- [x] 8. Implement parallel conversation support
  - [x] 8.1 Create batch execution logic
    - Runs multiple conversations via loop in run()
    - Each conversation isolated with own state
    - _Requirements: 2.4_
  
  - [x] 8.2 Implement resource management
    - Safety controls check before each request
    - Rate limiting via checkSafetyControls()
    - _Requirements: 9.1_
  
  - [x] 8.3 Aggregate results
    - Collects results from all conversations
    - Generates AdversarialTestSummary with aggregate metrics
    - _Requirements: 2.4, 6.4_

## Phase 4: Prompt Strategies ✅

- [x] 9. Implement PromptStrategy protocol
  - [x] 9.1 Create PromptStrategy protocol
    - Defined getSystemPrompt() method
    - Defined getNextTurnInstructions() method
    - Defined isGoalAchieved() method
    - _Requirements: 3.1, 3.2_

- [x] 10. Implement strategy implementations
  - [x] 10.1 Create ExploratoryStrategy
    - Generates diverse, broad questions
    - Maps bot capabilities with varied question types
    - Enhanced with detailed testing tactics
    - _Requirements: 3.3_
  
  - [x] 10.2 Create AdversarialStrategy
    - Generates edge cases and contradictions
    - Tests boundaries with challenging inputs
    - Goal: Find 3+ failures
    - _Requirements: 3.3_
  
  - [x] 10.3 Create FocusedStrategy
    - Tests specific features with 5-step process
    - Deep dives into goal areas
    - Goal: Achieve 5+ passed validations
    - _Requirements: 3.3_
  
  - [x] 10.4 Create StressStrategy
    - Rapid context switching
    - Complex, long multi-part inputs
    - Detects performance degradation
    - _Requirements: 3.3_
  
  - [x] 10.5 Support custom strategies
    - CustomStrategy uses user-defined system prompts
    - Falls back to goal-based prompts
    - Configurable completion criteria
    - _Requirements: 1.2, 3.1_

- [x] 11. Implement adaptive prompting
  - [x] 11.1 Analyze validation results
    - Strategies track validation results
    - AdversarialStrategy counts failures
    - FocusedStrategy tracks progress
    - _Requirements: 3.2, 5.3_
  
  - [x] 11.2 Dynamic instruction injection
    - getNextTurnInstructions() provides real-time guidance
    - Strategies adapt based on conversation history
    - StressStrategy increases complexity over time
    - _Requirements: 3.2, 5.3_

## Phase 5: Logging and Monitoring ✅

- [x] 12. Implement Conversation Logger
  - [x] 12.1 Create conversation logging
    - All messages logged with timestamps in AdversarialMessage
    - Metadata tracked (IDs, response times, token counts)
    - _Requirements: 4.1_
  
  - [x] 12.2 Implement multi-format saving
    - Results stored in AdversarialTestResults (Codable)
    - Persisted via AppState.saveConfigs()
    - Can be exported via report generator
    - _Requirements: 4.3_
  
  - [x] 12.3 Add validation logging
    - Validation results logged per turn
    - Pass/fail rates tracked in ConversationResult
    - _Requirements: 5.1, 5.2_
  
  - [x] 12.4 Track conversation metrics
    - Number of turns tracked
    - Response times in ConversationMetrics
    - Conversation duration calculated
    - _Requirements: 4.4_

- [x] 13. Implement real-time monitoring
  - [x] 13.1 Create UI display
    - AdversarialView shows ongoing tests
    - Progress indicators via isRunningAdversarial
    - Results displayed after completion
    - _Requirements: 4.2_
  
  - [x] 13.2 Add interactive controls
    - Cancel button available during execution
    - Early termination via defer blocks
    - Error messages shown to user
    - _Requirements: 8.3_

## Phase 6: Validation Integration ✅

- [x] 14. Integrate existing validation system
  - [x] 14.1 Adapt ResponseValidator for adversarial testing
    - validateResponse() applies rules to target bot responses
    - Results tracked in validationResults array
    - _Requirements: 5.1, 5.2_
  
  - [x] 14.2 Implement real-time validation
    - Validation runs during each conversation turn
    - Results influence strategy decisions via isGoalAchieved()
    - _Requirements: 5.1, 5.3_
  
  - [x] 14.3 Generate validation reports
    - Summary in AdversarialTestSummary (averagePassRate)
    - Detailed results in ConversationResult
    - _Requirements: 5.4_

## Phase 7: Reporting ✅

- [x] 15. Implement Adversarial Report Generator
  - [x] 15.1 Create AdversarialReportGenerator class
    - ReportGenerator handles adversarial test results
    - Generates conversation transcripts
    - Includes validation results and metrics
    - _Requirements: 6.1_
  
  - [x] 15.2 Implement HTML report format
    - HTML generation with conversation visualization
    - Interactive transcripts with styling
    - Charts and metrics display
    - _Requirements: 6.2_
  
  - [x] 15.3 Implement JSON report format
    - Structured JSON data export
    - Complete conversation data with metadata
    - _Requirements: 6.2_
  
  - [x] 15.4 Implement Markdown report format
    - Documentation-friendly markdown format
    - Summary tables and formatted transcripts
    - _Requirements: 6.2_
  
  - [x] 15.5 Implement CSV report format
    - CSV metrics export for analysis
    - Conversation summaries in tabular format
    - _Requirements: 6.2_

- [x] 16. Implement aggregate reporting
  - [x] 16.1 Generate multi-conversation reports
    - AdversarialTestSummary aggregates multiple conversations
    - Compares different strategies
    - Identifies patterns across conversations
    - _Requirements: 6.4_
  
  - [x] 16.2 Add adversarial insights
    - Summary includes bot assessment metrics
    - Identifies weaknesses via validation failures
    - Provides improvement suggestions in reports
    - _Requirements: 6.3_

## Phase 8: Configuration and CLI ⚠️

- [x] 17. Implement configuration management
  - [x] 17.1 Define AdversarialTestConfig schema
    - Complete configuration structure in Types.swift
    - Includes all connector settings and strategy options
    - _Requirements: 7.1_
  
  - [x] 17.2 Implement configuration loading
    - Configuration loaded via AppState
    - Persisted with saveConfigs() and loadConfigs()
    - _Requirements: 7.2, 7.3_
  
  - [x] 17.3 Create configuration templates
    - TestConfigEditorView provides UI templates
    - Pre-configured settings for each LLM provider
    - _Requirements: 7.4_

- [ ] 18. Implement CLI integration
  - [ ] 18.1 Add 'adversarial' command
    - **Note**: Application uses SwiftUI GUI, not CLI
    - Adversarial testing accessed via AdversarialView
    - _Requirements: 8.1, 8.2 - N/A for GUI app_
  
  - [ ] 18.2 Implement interactive mode
    - **Note**: Interactive mode via SwiftUI interface
    - Real-time display in AdversarialView
    - Cancel button for manual intervention
    - _Requirements: 8.3 - Implemented via GUI_
  
  - [ ] 18.3 Implement batch mode
    - Batch execution via runAdversarialTests()
    - Multiple conversations in single run
    - _Requirements: 8.4 - Implemented via GUI_
  
  - [ ] 18.4 Add CLI help and documentation
    - **Note**: Documentation in README.md and DOCUMENTATION.md
    - Usage examples provided for GUI application
    - _Requirements: 8.1, 8.2 - Documentation complete_

## Phase 9: Safety and Rate Limiting ✅

- [x] 19. Implement rate limiting
  - [x] 19.1 Create RateLimiter class
    - Rate limiting in checkSafetyControls()
    - Tracks requests per provider via safetyTracking
    - Enforces maxRequestsPerMinute limit
    - _Requirements: 9.1_
  
  - [x] 19.2 Implement backoff strategies
    - Error handling with detailed status codes
    - Graceful degradation on API errors
    - _Requirements: 9.1, 9.4_

- [x] 20. Implement cost management
  - [x] 20.1 Create CostTracker class
    - Cost tracking in updateSafetyTracking()
    - Tracks API usage per provider
    - Estimates costs based on token usage
    - _Requirements: 9.2_
  
  - [x] 20.2 Add cost limits
    - maxCostPerTest configuration option
    - Checks cost before each request
    - Stops execution when limit reached
    - _Requirements: 9.2_

- [ ] 21. Implement content filtering
  - [ ] 21.1 Add content safety checks
    - **Note**: Relies on LLM provider content policies
    - Validation rules can filter inappropriate responses
    - _Requirements: 9.3 - Delegated to providers_
  
  - [ ] 21.2 Implement data privacy
    - **Note**: User responsible for PII in test data
    - No automatic PII redaction implemented
    - _Requirements: 9.3 - Future enhancement_

## Phase 10: Testing

- [ ] 22. Write unit tests
  - [ ] 22.1 Test LLM connectors
    - Mock API responses
    - Test error handling
    - _Requirements: 1.1, 1.3, 1.4_
  
  - [ ] 22.2 Test conversation management
    - Test turn execution
    - Test termination logic
    - _Requirements: 2.1, 2.2, 2.3_
  
  - [ ] 22.3 Test prompt strategies
    - Verify system prompt generation
    - Test adaptive prompting
    - _Requirements: 3.1, 3.2, 3.3_
  
  - [ ] 22.4 Test logging and reporting
    - Verify log formats
    - Test report generation
    - _Requirements: 4.1, 4.3, 6.1, 6.2_

- [ ] 23. Write integration tests
  - [ ] 23.1 Test with mock bots
    - Simulate full conversations
    - Test error scenarios
    - _Requirements: All requirements_
  
  - [ ] 23.2 Test with Ollama (local)
    - End-to-end test with real LLM
    - Verify conversation flow
    - _Requirements: All requirements_
  
  - [ ] 23.3 Test CLI functionality
    - Test all CLI commands
    - Verify output formats
    - _Requirements: 8.1, 8.2, 8.3, 8.4_

## Phase 11: Documentation and Examples

- [ ] 24. Create documentation
  - [ ] 24.1 Update README with adversarial testing
    - Document adversarial mode
    - Provide usage examples
    - _Requirements: All requirements - documentation_
  
  - [ ] 24.2 Create configuration examples
    - Example configs for each LLM provider
    - Different strategy examples
    - _Requirements: 7.2, 7.4_
  
  - [ ] 24.3 Create setup guides
    - OpenAI setup guide
    - Anthropic setup guide
    - Ollama setup guide
    - _Requirements: 1.1, 1.3_

- [ ] 25. Final checkpoint
  - [ ] 25.1 Run all tests
    - Verify all tests pass
    - Check test coverage
    - _Requirements: All requirements_
  
  - [ ] 25.2 End-to-end testing
    - Test with real LLM providers
    - Verify report quality
    - _Requirements: All requirements_
  
  - [ ] 25.3 User acceptance testing
    - Test CLI usability
    - Verify conversation quality
    - _Requirements: All requirements_

## Implementation Notes

### Priority Order

1. **Phase 1-2**: Core infrastructure and at least one connector (Ollama recommended for local testing)
2. **Phase 3**: Conversation management (critical for functionality)
3. **Phase 4**: Basic prompt strategies (start with Exploratory)
4. **Phase 5**: Logging (essential for debugging and analysis)
5. **Phase 6**: Validation integration
6. **Phase 7**: Reporting
7. **Phase 8**: CLI integration
8. **Phase 9**: Safety features
9. **Phase 10-11**: Testing and documentation

### Recommended Starting Point

Start with Ollama connector since it:
- Runs locally (no API costs)
- No API key required
- Easy to test and debug
- Can be used for development without external dependencies

Once Ollama works, add OpenAI and Anthropic connectors.

### Dependencies

- `openai` package for OpenAI integration
- `@anthropic-ai/sdk` for Anthropic integration
- Ollama HTTP API (no package needed, use axios)
- Reuse existing `BotConnector` for target bot
- Reuse existing `ResponseValidator` for validation
