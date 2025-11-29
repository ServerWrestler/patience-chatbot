"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.BaseProtocolAdapter = exports.ProtocolError = void 0;
/**
 * Custom error class for protocol-specific errors
 */
class ProtocolError extends Error {
    constructor(message, protocol, originalError) {
        super(message);
        this.protocol = protocol;
        this.originalError = originalError;
        this.name = 'ProtocolError';
    }
}
exports.ProtocolError = ProtocolError;
/**
 * Abstract base class for protocol adapters with shared error handling
 */
class BaseProtocolAdapter {
    constructor() {
        this.config = null;
        this.connected = false;
    }
    isConnected() {
        return this.connected;
    }
    /**
     * Handle errors with protocol-specific context
     */
    handleError(error, context) {
        const protocol = this.config?.protocol || 'unknown';
        if (error instanceof Error) {
            throw new ProtocolError(`${context}: ${error.message}`, protocol, error);
        }
        throw new ProtocolError(`${context}: Unknown error occurred`, protocol);
    }
    /**
     * Validate that adapter is connected before operations
     */
    ensureConnected() {
        if (!this.connected) {
            throw new ProtocolError('Adapter is not connected. Call connect() first.', this.config?.protocol || 'unknown');
        }
    }
    /**
     * Create a BotResponse object with error information
     */
    createErrorResponse(error) {
        return {
            content: '',
            timestamp: new Date(),
            error,
            metadata: {
                protocol: this.config?.protocol,
                endpoint: this.config?.endpoint
            }
        };
    }
}
exports.BaseProtocolAdapter = BaseProtocolAdapter;
//# sourceMappingURL=ProtocolAdapter.js.map