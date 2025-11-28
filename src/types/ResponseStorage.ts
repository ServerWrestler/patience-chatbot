import { BotResponse, ConversationHistory, ConversationMessage } from './index';

/**
 * In-memory storage for conversation history and responses
 */
export class ResponseStorage {
  private histories: Map<string, ConversationHistory> = new Map();

  /**
   * Create a new conversation history for a session
   */
  createHistory(sessionId: string): ConversationHistory {
    const history: ConversationHistory = {
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
  storeMessage(
    sessionId: string,
    sender: 'patience' | 'target',
    content: string,
    validationResult?: any
  ): void {
    const history = this.histories.get(sessionId);
    
    if (!history) {
      throw new Error(`No conversation history found for session: ${sessionId}`);
    }

    const message: ConversationMessage = {
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
  storeResponse(sessionId: string, response: BotResponse): void {
    let content: string;
    
    // If there's an error, use the error message as content
    if (response.error) {
      content = `Error: ${response.error.message}`;
    } else {
      content = typeof response.content === 'string' 
        ? response.content 
        : JSON.stringify(response.content);
    }

    this.storeMessage(sessionId, 'target', content);
  }

  /**
   * Store a Patience message in the conversation history
   */
  storePatienceMessage(sessionId: string, message: string): void {
    this.storeMessage(sessionId, 'patience', message);
  }

  /**
   * Retrieve conversation history for a session
   */
  getHistory(sessionId: string): ConversationHistory | undefined {
    return this.histories.get(sessionId);
  }

  /**
   * Get all messages for a session
   */
  getMessages(sessionId: string): ConversationMessage[] {
    const history = this.histories.get(sessionId);
    return history ? history.messages : [];
  }

  /**
   * Get the last N messages for a session
   */
  getRecentMessages(sessionId: string, count: number): ConversationMessage[] {
    const messages = this.getMessages(sessionId);
    return messages.slice(-count);
  }

  /**
   * Get messages by sender
   */
  getMessagesBySender(
    sessionId: string,
    sender: 'patience' | 'target'
  ): ConversationMessage[] {
    const messages = this.getMessages(sessionId);
    return messages.filter(msg => msg.sender === sender);
  }

  /**
   * Check if a session exists
   */
  hasSession(sessionId: string): boolean {
    return this.histories.has(sessionId);
  }

  /**
   * Clear history for a specific session
   */
  clearSession(sessionId: string): void {
    this.histories.delete(sessionId);
  }

  /**
   * Clear all histories
   */
  clearAll(): void {
    this.histories.clear();
  }

  /**
   * Get all session IDs
   */
  getAllSessionIds(): string[] {
    return Array.from(this.histories.keys());
  }

  /**
   * Get count of messages in a session
   */
  getMessageCount(sessionId: string): number {
    return this.getMessages(sessionId).length;
  }

  /**
   * Update the end time of a conversation history
   */
  finalizeHistory(sessionId: string): void {
    const history = this.histories.get(sessionId);
    if (history) {
      history.endTime = new Date();
    }
  }
}

/**
 * Global response storage instance
 */
export const globalResponseStorage = new ResponseStorage();
