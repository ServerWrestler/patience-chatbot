import { MessageType, GenerationConstraints } from '../types';
/**
 * Message generator for creating diverse test messages
 */
export declare class MessageGenerator {
    private random;
    /**
     * Generate a random message
     */
    generateMessage(type?: MessageType, constraints?: GenerationConstraints): string;
    /**
     * Select a random message type
     */
    private selectRandomType;
    /**
     * Generate a question message
     * Questions end with question marks and use interrogative words
     */
    private generateQuestion;
    /**
     * Generate a statement message
     * Statements are declarative and end with periods
     */
    private generateStatement;
    /**
     * Generate a command message
     * Commands use imperative verbs and are directive
     */
    private generateCommand;
    /**
     * Apply generation constraints to a message
     */
    private applyConstraints;
    /**
     * Pad a message to meet minimum length
     */
    private padMessage;
    /**
     * Generate multiple diverse messages
     * Ensures variation in length and content
     */
    generateDiverseMessages(count: number, type?: MessageType): string[];
    /**
     * Generate a random length within a range
     */
    private randomLength;
    /**
     * Generate messages with varying lengths
     */
    generateVaryingLengthMessages(count: number): string[];
    /**
     * Generate messages with varying content types
     */
    generateVaryingContentMessages(count: number): string[];
    /**
     * Generate edge case messages
     * Includes empty strings, special characters, very long inputs, etc.
     */
    generateEdgeCases(): string[];
    /**
     * Generate a random edge case message
     */
    generateRandomEdgeCase(): string;
    /**
     * Generate very long message
     */
    generateVeryLongMessage(length?: number): string;
    /**
     * Generate message with special characters
     */
    generateSpecialCharacterMessage(): string;
    /**
     * Generate empty or whitespace-only message
     */
    generateEmptyMessage(): string;
    /**
     * Check if a message has characteristics of a question
     */
    static isQuestion(message: string): boolean;
    /**
     * Check if a message has characteristics of a statement
     */
    static isStatement(message: string): boolean;
    /**
     * Check if a message has characteristics of a command
     */
    static isCommand(message: string): boolean;
    /**
     * Validate that a message matches its intended type
     */
    static validateMessageType(message: string, expectedType: MessageType): boolean;
    /**
     * Generate a coherent sequence of messages on a topic
     * Messages maintain topic consistency and include referential links
     */
    generateCoherentSequence(count: number, topic?: string): string[];
    /**
     * Select a random topic for conversation
     */
    private selectRandomTopic;
    /**
     * Generate an opening message for a topic
     */
    private generateOpeningMessage;
    /**
     * Generate a follow-up message that references the topic and previous context
     */
    private generateFollowUpMessage;
    /**
     * Check if a sequence of messages maintains topic coherence
     */
    static hasTopicCoherence(messages: string[], topic: string): boolean;
    /**
     * Check if messages have referential links
     */
    static hasReferentialLinks(messages: string[]): boolean;
    /**
     * Generate a conversation sequence with natural flow
     */
    generateConversationFlow(length: number): string[];
}
//# sourceMappingURL=MessageGenerator.d.ts.map