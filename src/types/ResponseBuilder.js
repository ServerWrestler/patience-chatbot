"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.ResponseBuilder = void 0;
exports.createResponseBuilder = createResponseBuilder;
/**
 * Builder class for creating BotResponse objects
 */
class ResponseBuilder {
    constructor() {
        this.response = {
            timestamp: new Date()
        };
    }
    /**
     * Set the response content
     */
    withContent(content) {
        this.response.content = content;
        return this;
    }
    /**
     * Set the timestamp
     */
    withTimestamp(timestamp) {
        this.response.timestamp = timestamp;
        return this;
    }
    /**
     * Set metadata
     */
    withMetadata(metadata) {
        this.response.metadata = metadata;
        return this;
    }
    /**
     * Add metadata field
     */
    addMetadata(key, value) {
        if (!this.response.metadata) {
            this.response.metadata = {};
        }
        this.response.metadata[key] = value;
        return this;
    }
    /**
     * Set error
     */
    withError(error) {
        this.response.error = error;
        return this;
    }
    /**
     * Set response time
     */
    withResponseTime(responseTime) {
        this.response.responseTime = responseTime;
        return this;
    }
    /**
     * Build the BotResponse object
     */
    build() {
        if (!this.response.content && !this.response.error) {
            throw new Error('BotResponse must have either content or error');
        }
        return {
            content: this.response.content || '',
            timestamp: this.response.timestamp,
            metadata: this.response.metadata,
            error: this.response.error,
            responseTime: this.response.responseTime
        };
    }
}
exports.ResponseBuilder = ResponseBuilder;
/**
 * Create a new ResponseBuilder instance
 */
function createResponseBuilder() {
    return new ResponseBuilder();
}
//# sourceMappingURL=ResponseBuilder.js.map