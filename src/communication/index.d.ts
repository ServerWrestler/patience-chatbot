/**
 * Communication module
 * Handles protocol-specific interactions with Target Bots
 */
export * from './ProtocolAdapter';
export * from './HTTPAdapter';
export * from './WebSocketAdapter';
import { ProtocolAdapter } from './ProtocolAdapter';
import { BotConfig } from '../types';
/**
 * Factory function to create the appropriate protocol adapter based on configuration
 * @param config Bot configuration containing protocol type
 * @returns Instance of the appropriate protocol adapter
 */
export declare function createProtocolAdapter(config: BotConfig): ProtocolAdapter;
//# sourceMappingURL=index.d.ts.map