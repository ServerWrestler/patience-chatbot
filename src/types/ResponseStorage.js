"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.globalResponseStorage = exports.ResponseStorage = void 0;
/**
 * In-memory storage for conversation history and responses
 */
class ResponseStorage {
    constructor() {
        this.histories = new Map();
    }
    /**
     * Create a new conversation history for a session
     */
    createHistory(sessionId) {
        const history = {
            sessionId,
            messages: [],
            startTime: new Date(),
            endTime: new Date()
        };
        this.histories.set(sessionId, history);
        return history;
    }
    /**
     * Store a message in the conversation history
     */
    storeMessage(sessionId, sender, content, validationResult) {
        const history = this.histories.get(sessionId);
        if (!history) {
            throw new Error(`No conversation history found for session: ${sessionId}`);
        }
        const message = {
            sender,
            content,
            timestamp: new Date(),
            validationResult
        };
        history.messages.push(message);
        history.endTime = new Date();
    }
    /**
     * Store a bot response in the conversation history
     */
    storeResponse(sessionId, response) {
        let content;
        // If there's an error, use the error message as content
        if (response.error) {
            content = `Error: ${response.error.message}`;
        }
        else {
            content = typeof response.content === 'string'
                ? response.content
                : JSON.stringify(response.content);
        }
        this.storeMessage(sessionId, 'target', content);
    }
    /**
     * Store a Patience message in the conversation history
     */
    storePatienceMessage(sessionId, message) {
        this.storeMessage(sessionId, 'patience', message);
    }
    /**
     * Retrieve conversation history for a session
     */
    getHistory(sessionId) {
        return this.histories.get(sessionId);
    }
    /**
     * Get all messages for a session
     */
    getMessages(sessionId) {
        const history = this.histories.get(sessionId);
        return history ? history.messages : [];
    }
    /**
     * Get the last N messages for a session
     */
    getRecentMessages(sessionId, count) {
        const messages = this.getMessages(sessionId);
        return messages.slice(-count);
    }
    /**
     * Get messages by sender
     */
    getMessagesBySender(sessionId, sender) {
        const messages = this.getMessages(sessionId);
        return messages.filter(msg => msg.sender === sender);
    }
    /**
     * Check if a session exists
     */
    hasSession(sessionId) {
        return this.histories.has(sessionId);
    }
    /**
     * Clear history for a specific session
     */
    clearSession(sessionId) {
        this.histories.delete(sessionId);
    }
    /**
     * Clear all histories
     */
    clearAll() {
        this.histories.clear();
    }
    /**
     * Get all session IDs
     */
    getAllSessionIds() {
        return Array.from(this.histories.keys());
    }
    /**
     * Get count of messages in a session
     */
    getMessageCount(sessionId) {
        return this.getMessages(sessionId).length;
    }
    /**
     * Update the end time of a conversation history
     */
    finalizeHistory(sessionId) {
        const history = this.histories.get(sessionId);
        if (history) {
            history.endTime = new Date();
        }
    }
}
exports.ResponseStorage = ResponseStorage;
/**
 * Global response storage instance
 */
exports.globalResponseStorage = new ResponseStorage();
//# sourceMappingURL=ResponseStorage.js.map