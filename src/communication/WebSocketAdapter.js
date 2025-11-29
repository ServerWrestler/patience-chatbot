"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.WebSocketAdapter = void 0;
const ProtocolAdapter_1 = require("./ProtocolAdapter");
const ws_1 = __importDefault(require("ws"));
/**
 * WebSocket protocol adapter implementation
 */
class WebSocketAdapter extends ProtocolAdapter_1.BaseProtocolAdapter {
    constructor() {
        super(...arguments);
        this.ws = null;
        this.messageQueue = [];
        this.connectionPromise = null;
    }
    /**
     * Connect to the WebSocket endpoint
     */
    async connect(config) {
        if (this.connectionPromise) {
            return this.connectionPromise;
        }
        this.connectionPromise = new Promise((resolve, reject) => {
            try {
                this.config = config;
                // Build WebSocket URL with authentication if needed
                let wsUrl = config.endpoint;
                // Add authentication to URL if using API key
                if (config.authentication?.type === 'apikey' && typeof config.authentication.credentials === 'string') {
                    const url = new URL(wsUrl);
                    url.searchParams.set('apikey', config.authentication.credentials);
                    wsUrl = url.toString();
                }
                // Create WebSocket connection
                const headers = { ...config.headers };
                // Add bearer token if configured
                if (config.authentication?.type === 'bearer' && typeof config.authentication.credentials === 'string') {
                    headers['Authorization'] = `Bearer ${config.authentication.credentials}`;
                }
                // Add basic auth if configured
                if (config.authentication?.type === 'basic' && typeof config.authentication.credentials === 'object') {
                    const { username, password } = config.authentication.credentials;
                    const encoded = Buffer.from(`${username}:${password}`).toString('base64');
                    headers['Authorization'] = `Basic ${encoded}`;
                }
                this.ws = new ws_1.default(wsUrl, { headers });
                // Handle connection open
                this.ws.on('open', () => {
                    this.connected = true;
                    resolve();
                });
                // Handle incoming messages
                this.ws.on('message', (data) => {
                    this.handleIncomingMessage(data);
                });
                // Handle errors
                this.ws.on('error', (error) => {
                    if (!this.connected) {
                        reject(error);
                    }
                    else {
                        console.error('WebSocket error:', error);
                        // Reject any pending messages
                        this.messageQueue.forEach(({ reject }) => reject(error));
                        this.messageQueue = [];
                    }
                });
                // Handle connection close
                this.ws.on('close', () => {
                    this.connected = false;
                    // Reject any pending messages
                    const error = new Error('WebSocket connection closed');
                    this.messageQueue.forEach(({ reject }) => reject(error));
                    this.messageQueue = [];
                });
                // Set connection timeout
                setTimeout(() => {
                    if (!this.connected) {
                        reject(new Error('WebSocket connection timeout'));
                        this.ws?.close();
                    }
                }, 10000); // 10 second timeout
            }
            catch (error) {
                reject(error);
            }
        });
        try {
            await this.connectionPromise;
        }
        catch (error) {
            this.connectionPromise = null;
            this.handleError(error, 'Failed to connect to WebSocket endpoint');
        }
    }
    /**
     * Send a message via WebSocket
     */
    async sendMessage(message) {
        this.ensureConnected();
        const startTime = Date.now();
        return new Promise((resolve, reject) => {
            try {
                // Add to message queue
                this.messageQueue.push({
                    resolve,
                    reject,
                    timestamp: startTime
                });
                // Send message
                const payload = JSON.stringify({ message });
                this.ws.send(payload, (error) => {
                    if (error) {
                        // Remove from queue and reject
                        const index = this.messageQueue.findIndex(item => item.timestamp === startTime);
                        if (index !== -1) {
                            this.messageQueue.splice(index, 1);
                        }
                        reject(error);
                    }
                });
                // Set timeout for response
                setTimeout(() => {
                    const index = this.messageQueue.findIndex(item => item.timestamp === startTime);
                    if (index !== -1) {
                        this.messageQueue.splice(index, 1);
                        const error = new Error('WebSocket response timeout');
                        resolve(this.createErrorResponse(error));
                    }
                }, 30000); // 30 second timeout
            }
            catch (error) {
                const responseTime = Date.now() - startTime;
                resolve({
                    ...this.createErrorResponse(error),
                    responseTime
                });
            }
        });
    }
    /**
     * Handle incoming WebSocket messages
     */
    handleIncomingMessage(data) {
        try {
            const content = data.toString();
            let parsedData;
            try {
                parsedData = JSON.parse(content);
            }
            catch {
                parsedData = content;
            }
            // Resolve the oldest pending message
            if (this.messageQueue.length > 0) {
                const { resolve, timestamp } = this.messageQueue.shift();
                const responseTime = Date.now() - timestamp;
                resolve({
                    content: parsedData,
                    timestamp: new Date(),
                    responseTime,
                    metadata: {
                        protocol: 'websocket'
                    }
                });
            }
        }
        catch (error) {
            console.error('Error handling WebSocket message:', error);
        }
    }
    /**
     * Disconnect from WebSocket
     */
    async disconnect() {
        return new Promise((resolve) => {
            if (this.ws) {
                this.ws.once('close', () => {
                    this.ws = null;
                    this.connected = false;
                    this.connectionPromise = null;
                    this.messageQueue = [];
                    resolve();
                });
                this.ws.close();
            }
            else {
                this.connected = false;
                this.connectionPromise = null;
                resolve();
            }
        });
    }
}
exports.WebSocketAdapter = WebSocketAdapter;
//# sourceMappingURL=WebSocketAdapter.js.map