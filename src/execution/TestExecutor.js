"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.TestExecutor = void 0;
const types_1 = require("../types");
const ScenarioRunner_1 = require("./ScenarioRunner");
const TimingManager_1 = require("./TimingManager");
const communication_1 = require("../communication");
/**
 * Test execution orchestrator
 */
class TestExecutor {
    constructor() {
        this.storage = new types_1.ResponseStorage();
        // Will be initialized with config
        this.timingManager = new TimingManager_1.TimingManager({
            enableDelays: false,
            baseDelay: 0,
            delayPerCharacter: 0,
            rapidFire: true,
            responseTimeout: 30000
        });
    }
    /**
     * Execute all tests from configuration
     */
    async executeTests(config) {
        const testRunId = `test-${Date.now()}`;
        const startTime = new Date();
        const scenarioResults = [];
        // Initialize timing manager with config
        this.timingManager = new TimingManager_1.TimingManager(config.timing);
        // Execute each scenario
        for (const scenario of config.scenarios) {
            try {
                const result = await this.executeScenario(scenario, config);
                scenarioResults.push(result);
            }
            catch (error) {
                // Create failed result for scenario
                const failedResult = {
                    scenarioId: scenario.id,
                    scenarioName: scenario.name,
                    passed: false,
                    conversationHistory: {
                        sessionId: `${scenario.id}-failed`,
                        messages: [],
                        startTime: new Date(),
                        endTime: new Date()
                    },
                    validationResults: [],
                    duration: 0,
                    error: error instanceof Error ? error : new Error('Unknown error')
                };
                scenarioResults.push(failedResult);
            }
        }
        const endTime = new Date();
        const passed = scenarioResults.filter(r => r.passed).length;
        const failed = scenarioResults.length - passed;
        return {
            testRunId,
            startTime,
            endTime,
            scenarioResults,
            summary: {
                total: scenarioResults.length,
                passed,
                failed
            }
        };
    }
    /**
     * Execute a single scenario
     */
    async executeScenario(scenario, config) {
        const startTime = Date.now();
        try {
            // Create protocol adapter
            const adapter = (0, communication_1.createProtocolAdapter)(config.targetBot);
            // Connect to target bot
            await adapter.connect(config.targetBot);
            // Create scenario runner
            const runner = new ScenarioRunner_1.ScenarioRunner(this.storage);
            // Run the scenario
            const history = await runner.runScenario(scenario, adapter);
            // Disconnect
            await adapter.disconnect();
            // Generate completion report
            const report = runner.generateCompletionReport(history);
            const duration = Date.now() - startTime;
            return {
                scenarioId: scenario.id,
                scenarioName: scenario.name,
                passed: report.success,
                conversationHistory: history,
                validationResults: report.validationResults,
                duration
            };
        }
        catch (error) {
            const duration = Date.now() - startTime;
            return {
                scenarioId: scenario.id,
                scenarioName: scenario.name,
                passed: false,
                conversationHistory: {
                    sessionId: `${scenario.id}-error`,
                    messages: [],
                    startTime: new Date(startTime),
                    endTime: new Date()
                },
                validationResults: [],
                duration,
                error: error instanceof Error ? error : new Error('Unknown error')
            };
        }
    }
    /**
     * Handle test failure
     */
    handleTestFailure(error, context) {
        console.error(`Test failure in scenario ${context.scenarioId}:`);
        console.error(`  Session: ${context.sessionId}`);
        console.error(`  Step: ${context.currentStep}`);
        console.error(`  Error: ${error.message}`);
        // Log conversation history if available
        if (context.conversationHistory.messages.length > 0) {
            console.error(`  Last messages:`);
            const recent = context.conversationHistory.messages.slice(-3);
            recent.forEach(msg => {
                console.error(`    ${msg.sender}: ${msg.content.substring(0, 50)}...`);
            });
        }
    }
    /**
     * Get storage instance
     */
    getStorage() {
        return this.storage;
    }
    /**
     * Get timing manager
     */
    getTimingManager() {
        return this.timingManager;
    }
}
exports.TestExecutor = TestExecutor;
//# sourceMappingURL=TestExecutor.js.map