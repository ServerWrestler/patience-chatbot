import { BotResponse, ConversationHistory, ConversationMessage } from './index';
/**
 * In-memory storage for conversation history and responses
 */
export declare class ResponseStorage {
    private histories;
    /**
     * Create a new conversation history for a session
     */
    createHistory(sessionId: string): ConversationHistory;
    /**
     * Store a message in the conversation history
     */
    storeMessage(sessionId: string, sender: 'patience' | 'target', content: string, validationResult?: any): void;
    /**
     * Store a bot response in the conversation history
     */
    storeResponse(sessionId: string, response: BotResponse): void;
    /**
     * Store a Patience message in the conversation history
     */
    storePatienceMessage(sessionId: string, message: string): void;
    /**
     * Retrieve conversation history for a session
     */
    getHistory(sessionId: string): ConversationHistory | undefined;
    /**
     * Get all messages for a session
     */
    getMessages(sessionId: string): ConversationMessage[];
    /**
     * Get the last N messages for a session
     */
    getRecentMessages(sessionId: string, count: number): ConversationMessage[];
    /**
     * Get messages by sender
     */
    getMessagesBySender(sessionId: string, sender: 'patience' | 'target'): ConversationMessage[];
    /**
     * Check if a session exists
     */
    hasSession(sessionId: string): boolean;
    /**
     * Clear history for a specific session
     */
    clearSession(sessionId: string): void;
    /**
     * Clear all histories
     */
    clearAll(): void;
    /**
     * Get all session IDs
     */
    getAllSessionIds(): string[];
    /**
     * Get count of messages in a session
     */
    getMessageCount(sessionId: string): number;
    /**
     * Update the end time of a conversation history
     */
    finalizeHistory(sessionId: string): void;
}
/**
 * Global response storage instance
 */
export declare const globalResponseStorage: ResponseStorage;
//# sourceMappingURL=ResponseStorage.d.ts.map