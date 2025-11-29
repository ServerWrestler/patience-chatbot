import { BotConfig, BotResponse } from '../types';
/**
 * Base interface for protocol adapters
 */
export interface ProtocolAdapter {
    connect(config: BotConfig): Promise<void>;
    sendMessage(message: string): Promise<BotResponse>;
    disconnect(): Promise<void>;
    isConnected(): boolean;
}
/**
 * Custom error class for protocol-specific errors
 */
export declare class ProtocolError extends Error {
    protocol: string;
    originalError?: Error | undefined;
    constructor(message: string, protocol: string, originalError?: Error | undefined);
}
/**
 * Abstract base class for protocol adapters with shared error handling
 */
export declare abstract class BaseProtocolAdapter implements ProtocolAdapter {
    protected config: BotConfig | null;
    protected connected: boolean;
    abstract connect(config: BotConfig): Promise<void>;
    abstract sendMessage(message: string): Promise<BotResponse>;
    abstract disconnect(): Promise<void>;
    isConnected(): boolean;
    /**
     * Handle errors with protocol-specific context
     */
    protected handleError(error: unknown, context: string): never;
    /**
     * Validate that adapter is connected before operations
     */
    protected ensureConnected(): void;
    /**
     * Create a BotResponse object with error information
     */
    protected createErrorResponse(error: Error): BotResponse;
}
//# sourceMappingURL=ProtocolAdapter.d.ts.map