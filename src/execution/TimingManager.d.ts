import { TimingConfig } from '../types';
/**
 * Timing manager for handling delays and timeouts
 */
export declare class TimingManager {
    private config;
    constructor(config: TimingConfig);
    /**
     * Calculate delay for a message based on its length
     * Simulates human typing speed
     */
    calculateMessageDelay(message: string): number;
    /**
     * Apply delay before sending a message
     */
    applyDelay(message: string): Promise<void>;
    /**
     * Sleep for specified milliseconds
     */
    private sleep;
    /**
     * Get response timeout value
     */
    getResponseTimeout(): number;
    /**
     * Check if delays are enabled
     */
    areDelaysEnabled(): boolean;
    /**
     * Check if rapid-fire mode is enabled
     */
    isRapidFireMode(): boolean;
    /**
     * Update timing configuration
     */
    updateConfig(config: Partial<TimingConfig>): void;
    /**
     * Get current timing configuration
     */
    getConfig(): TimingConfig;
    /**
     * Calculate human-like typing delay with variation
     * Adds randomness to simulate natural typing patterns
     */
    calculateHumanLikeDelay(message: string): number;
    /**
     * Calculate delay based on message characteristics
     * Longer delays for complex messages (punctuation, numbers)
     */
    calculateAdaptiveDelay(message: string): number;
    /**
     * Apply human-like delay with variation
     */
    applyHumanLikeDelay(message: string): Promise<void>;
    /**
     * Apply adaptive delay based on message characteristics
     */
    applyAdaptiveDelay(message: string): Promise<void>;
    /**
     * Get delay statistics for a message
     */
    getDelayStats(message: string): {
        baseDelay: number;
        humanLikeDelay: number;
        adaptiveDelay: number;
        messageLength: number;
    };
    /**
     * Enable rapid-fire mode
     * Messages are sent immediately without delays
     */
    enableRapidFire(): void;
    /**
     * Disable rapid-fire mode
     * Restores normal delay behavior
     */
    disableRapidFire(): void;
    /**
     * Toggle rapid-fire mode
     */
    toggleRapidFire(): boolean;
    /**
     * Measure actual delay time
     * Returns time taken to send a message with delays
     */
    measureDelay(message: string, useHumanLike?: boolean): Promise<number>;
    /**
     * Verify rapid-fire mode timing
     * Ensures messages are sent with minimal delay
     */
    verifyRapidFireTiming(message: string, maxDelay?: number): Promise<boolean>;
    /**
     * Execute a function with timeout enforcement
     * Throws error if operation exceeds timeout
     */
    withTimeout<T>(operation: () => Promise<T>, timeoutMs?: number): Promise<T>;
    /**
     * Check if a response time exceeds the timeout threshold
     */
    isTimeout(responseTime: number): boolean;
    /**
     * Mark an interaction as failed due to timeout
     */
    createTimeoutError(responseTime: number): Error;
    /**
     * Track response time and check for timeout
     */
    trackResponseTime<T>(operation: () => Promise<T>): Promise<{
        result?: T;
        responseTime: number;
        timedOut: boolean;
        error?: Error;
    }>;
    /**
     * Get timeout configuration
     */
    getTimeoutConfig(): {
        responseTimeout: number;
        timeoutEnabled: boolean;
    };
    /**
     * Update response timeout
     */
    setResponseTimeout(timeoutMs: number): void;
}
//# sourceMappingURL=TimingManager.d.ts.map