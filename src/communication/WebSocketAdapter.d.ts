import { BaseProtocolAdapter } from './ProtocolAdapter';
import { BotConfig, BotResponse } from '../types';
/**
 * WebSocket protocol adapter implementation
 */
export declare class WebSocketAdapter extends BaseProtocolAdapter {
    private ws;
    private messageQueue;
    private connectionPromise;
    /**
     * Connect to the WebSocket endpoint
     */
    connect(config: BotConfig): Promise<void>;
    /**
     * Send a message via WebSocket
     */
    sendMessage(message: string): Promise<BotResponse>;
    /**
     * Handle incoming WebSocket messages
     */
    private handleIncomingMessage;
    /**
     * Disconnect from WebSocket
     */
    disconnect(): Promise<void>;
}
//# sourceMappingURL=WebSocketAdapter.d.ts.map