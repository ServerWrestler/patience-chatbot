import { BaseProtocolAdapter } from './ProtocolAdapter';
import { BotConfig, BotResponse } from '../types';
/**
 * HTTP protocol adapter implementation
 */
export declare class HTTPAdapter extends BaseProtocolAdapter {
    private client;
    /**
     * Connect to the HTTP endpoint
     */
    connect(config: BotConfig): Promise<void>;
    /**
     * Send a message via HTTP POST request
     */
    sendMessage(message: string): Promise<BotResponse>;
    /**
     * Format request body based on provider
     */
    private formatRequest;
    /**
     * Extract content from response based on provider
     */
    private extractContent;
    /**
     * Disconnect from HTTP endpoint (cleanup)
     */
    disconnect(): Promise<void>;
}
//# sourceMappingURL=HTTPAdapter.d.ts.map