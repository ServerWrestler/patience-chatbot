import { TestConfig, TestResults, ScenarioResult, Scenario, TestContext, ResponseStorage } from '../types';
import { TimingManager } from './TimingManager';
/**
 * Test execution orchestrator
 */
export declare class TestExecutor {
    private storage;
    private timingManager;
    constructor();
    /**
     * Execute all tests from configuration
     */
    executeTests(config: TestConfig): Promise<TestResults>;
    /**
     * Execute a single scenario
     */
    executeScenario(scenario: Scenario, config: TestConfig): Promise<ScenarioResult>;
    /**
     * Handle test failure
     */
    handleTestFailure(error: Error, context: TestContext): void;
    /**
     * Get storage instance
     */
    getStorage(): ResponseStorage;
    /**
     * Get timing manager
     */
    getTimingManager(): TimingManager;
}
//# sourceMappingURL=TestExecutor.d.ts.map