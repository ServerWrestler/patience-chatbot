import { BotResponse } from './index';
/**
 * Builder class for creating BotResponse objects
 */
export declare class ResponseBuilder {
    private response;
    /**
     * Set the response content
     */
    withContent(content: string | object): ResponseBuilder;
    /**
     * Set the timestamp
     */
    withTimestamp(timestamp: Date): ResponseBuilder;
    /**
     * Set metadata
     */
    withMetadata(metadata: Record<string, any>): ResponseBuilder;
    /**
     * Add metadata field
     */
    addMetadata(key: string, value: any): ResponseBuilder;
    /**
     * Set error
     */
    withError(error: Error): ResponseBuilder;
    /**
     * Set response time
     */
    withResponseTime(responseTime: number): ResponseBuilder;
    /**
     * Build the BotResponse object
     */
    build(): BotResponse;
}
/**
 * Create a new ResponseBuilder instance
 */
export declare function createResponseBuilder(): ResponseBuilder;
//# sourceMappingURL=ResponseBuilder.d.ts.map