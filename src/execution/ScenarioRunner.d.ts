import { Scenario, ConversationHistory, ConversationStep, BotResponse, Condition, ResponseStorage, ValidationResult } from '../types';
import type { ProtocolAdapter } from '../communication/ProtocolAdapter';
/**
 * Scenario execution runner
 */
export declare class ScenarioRunner {
    private storage;
    private validator;
    private messageGenerator;
    private currentAdapter;
    private currentStepIndex;
    private currentScenario;
    constructor(storage?: ResponseStorage);
    /**
     * Run a complete scenario
     * Executes all steps and returns conversation history
     */
    runScenario(scenario: Scenario, adapter: ProtocolAdapter): Promise<ConversationHistory>;
    /**
     * Execute a single conversation step
     */
    executeStep(step: ConversationStep): Promise<BotResponse>;
    /**
     * Get the message content from a conversation step
     */
    private getStepMessage;
    /**
     * Handle conditional branches
     * Returns the next step to execute based on conditions
     */
    private handleConditionalBranches;
    /**
     * Handle a single conditional branch (public method)
     * Evaluates condition and returns the appropriate next step
     */
    handleConditionalBranch(condition: Condition, response: BotResponse): ConversationStep | null;
    /**
     * Select the appropriate branch based on response
     * Returns the index of the selected branch, or -1 if none match
     */
    selectBranch(branches: Array<{
        condition: Condition;
        nextStep: ConversationStep;
    }>, response: BotResponse): number;
    /**
     * Evaluate a condition against a response
     */
    private evaluateCondition;
    /**
     * Delay execution for specified milliseconds
     */
    private delay;
    /**
     * Get the current conversation history
     */
    getHistory(sessionId: string): ConversationHistory | undefined;
    /**
     * Get the current step index
     */
    getCurrentStepIndex(): number;
    /**
     * Get the current scenario
     */
    getCurrentScenario(): Scenario | null;
    /**
     * Check if there are more steps to execute
     */
    hasMoreSteps(): boolean;
    /**
     * Advance to the next step
     */
    advanceStep(): boolean;
    /**
     * Generate a completion report for a scenario
     */
    generateCompletionReport(history: ConversationHistory): {
        scenarioId: string;
        completed: boolean;
        totalSteps: number;
        executedSteps: number;
        validationResults: ValidationResult[];
        allValidationsPassed: boolean;
        duration: number;
        success: boolean;
    };
    /**
     * Check if scenario execution was successful
     */
    isScenarioSuccessful(history: ConversationHistory): boolean;
    /**
     * Get scenario execution summary
     */
    getExecutionSummary(history: ConversationHistory): {
        totalMessages: number;
        patienceMessages: number;
        targetMessages: number;
        validations: number;
        passedValidations: number;
        failedValidations: number;
    };
}
//# sourceMappingURL=ScenarioRunner.d.ts.map