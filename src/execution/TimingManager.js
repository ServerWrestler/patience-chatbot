"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.TimingManager = void 0;
/**
 * Timing manager for handling delays and timeouts
 */
class TimingManager {
    constructor(config) {
        this.config = config;
    }
    /**
     * Calculate delay for a message based on its length
     * Simulates human typing speed
     */
    calculateMessageDelay(message) {
        if (!this.config.enableDelays || this.config.rapidFire) {
            return 0;
        }
        const messageLength = message.length;
        const delay = this.config.baseDelay + (messageLength * this.config.delayPerCharacter);
        return Math.max(0, delay);
    }
    /**
     * Apply delay before sending a message
     */
    async applyDelay(message) {
        const delay = this.calculateMessageDelay(message);
        if (delay > 0) {
            await this.sleep(delay);
        }
    }
    /**
     * Sleep for specified milliseconds
     */
    sleep(ms) {
        return new Promise(resolve => setTimeout(resolve, ms));
    }
    /**
     * Get response timeout value
     */
    getResponseTimeout() {
        return this.config.responseTimeout;
    }
    /**
     * Check if delays are enabled
     */
    areDelaysEnabled() {
        return this.config.enableDelays && !this.config.rapidFire;
    }
    /**
     * Check if rapid-fire mode is enabled
     */
    isRapidFireMode() {
        return this.config.rapidFire;
    }
    /**
     * Update timing configuration
     */
    updateConfig(config) {
        this.config = { ...this.config, ...config };
    }
    /**
     * Get current timing configuration
     */
    getConfig() {
        return { ...this.config };
    }
    /**
     * Calculate human-like typing delay with variation
     * Adds randomness to simulate natural typing patterns
     */
    calculateHumanLikeDelay(message) {
        if (!this.config.enableDelays || this.config.rapidFire) {
            return 0;
        }
        const baseDelay = this.calculateMessageDelay(message);
        // Add random variation (±20%)
        const variation = baseDelay * 0.2;
        const randomOffset = (Math.random() * variation * 2) - variation;
        return Math.max(0, Math.floor(baseDelay + randomOffset));
    }
    /**
     * Calculate delay based on message characteristics
     * Longer delays for complex messages (punctuation, numbers)
     */
    calculateAdaptiveDelay(message) {
        if (!this.config.enableDelays || this.config.rapidFire) {
            return 0;
        }
        let delay = this.config.baseDelay;
        // Base delay per character
        delay += message.length * this.config.delayPerCharacter;
        // Add extra delay for punctuation (thinking time)
        const punctuationCount = (message.match(/[.,!?;:]/g) || []).length;
        delay += punctuationCount * 50;
        // Add extra delay for numbers (slower to type)
        const numberCount = (message.match(/\d/g) || []).length;
        delay += numberCount * 30;
        // Add extra delay for capital letters at word starts (shift key)
        const capitalCount = (message.match(/\b[A-Z]/g) || []).length;
        delay += capitalCount * 20;
        return Math.max(0, Math.floor(delay));
    }
    /**
     * Apply human-like delay with variation
     */
    async applyHumanLikeDelay(message) {
        const delay = this.calculateHumanLikeDelay(message);
        if (delay > 0) {
            await this.sleep(delay);
        }
    }
    /**
     * Apply adaptive delay based on message characteristics
     */
    async applyAdaptiveDelay(message) {
        const delay = this.calculateAdaptiveDelay(message);
        if (delay > 0) {
            await this.sleep(delay);
        }
    }
    /**
     * Get delay statistics for a message
     */
    getDelayStats(message) {
        return {
            baseDelay: this.calculateMessageDelay(message),
            humanLikeDelay: this.calculateHumanLikeDelay(message),
            adaptiveDelay: this.calculateAdaptiveDelay(message),
            messageLength: message.length
        };
    }
    /**
     * Enable rapid-fire mode
     * Messages are sent immediately without delays
     */
    enableRapidFire() {
        this.config.rapidFire = true;
    }
    /**
     * Disable rapid-fire mode
     * Restores normal delay behavior
     */
    disableRapidFire() {
        this.config.rapidFire = false;
    }
    /**
     * Toggle rapid-fire mode
     */
    toggleRapidFire() {
        this.config.rapidFire = !this.config.rapidFire;
        return this.config.rapidFire;
    }
    /**
     * Measure actual delay time
     * Returns time taken to send a message with delays
     */
    async measureDelay(message, useHumanLike = false) {
        const startTime = Date.now();
        if (useHumanLike) {
            await this.applyHumanLikeDelay(message);
        }
        else {
            await this.applyDelay(message);
        }
        return Date.now() - startTime;
    }
    /**
     * Verify rapid-fire mode timing
     * Ensures messages are sent with minimal delay
     */
    async verifyRapidFireTiming(message, maxDelay = 10) {
        const actualDelay = await this.measureDelay(message);
        return actualDelay < maxDelay;
    }
    /**
     * Execute a function with timeout enforcement
     * Throws error if operation exceeds timeout
     */
    async withTimeout(operation, timeoutMs) {
        const timeout = timeoutMs || this.config.responseTimeout;
        return Promise.race([
            operation(),
            new Promise((_, reject) => setTimeout(() => reject(new Error(`Operation timed out after ${timeout}ms`)), timeout))
        ]);
    }
    /**
     * Check if a response time exceeds the timeout threshold
     */
    isTimeout(responseTime) {
        return responseTime > this.config.responseTimeout;
    }
    /**
     * Mark an interaction as failed due to timeout
     */
    createTimeoutError(responseTime) {
        return new Error(`Response timeout: ${responseTime}ms exceeds threshold of ${this.config.responseTimeout}ms`);
    }
    /**
     * Track response time and check for timeout
     */
    async trackResponseTime(operation) {
        const startTime = Date.now();
        try {
            const result = await this.withTimeout(operation);
            const responseTime = Date.now() - startTime;
            return {
                result,
                responseTime,
                timedOut: false
            };
        }
        catch (error) {
            const responseTime = Date.now() - startTime;
            return {
                responseTime,
                timedOut: this.isTimeout(responseTime),
                error: error instanceof Error ? error : new Error('Unknown error')
            };
        }
    }
    /**
     * Get timeout configuration
     */
    getTimeoutConfig() {
        return {
            responseTimeout: this.config.responseTimeout,
            timeoutEnabled: this.config.responseTimeout > 0
        };
    }
    /**
     * Update response timeout
     */
    setResponseTimeout(timeoutMs) {
        this.config.responseTimeout = Math.max(0, timeoutMs);
    }
}
exports.TimingManager = TimingManager;
//# sourceMappingURL=TimingManager.js.map