"use strict";
/**
 * Communication module
 * Handles protocol-specific interactions with Target Bots
 */
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __exportStar = (this && this.__exportStar) || function(m, exports) {
    for (var p in m) if (p !== "default" && !Object.prototype.hasOwnProperty.call(exports, p)) __createBinding(exports, m, p);
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.createProtocolAdapter = createProtocolAdapter;
__exportStar(require("./ProtocolAdapter"), exports);
__exportStar(require("./HTTPAdapter"), exports);
__exportStar(require("./WebSocketAdapter"), exports);
const HTTPAdapter_1 = require("./HTTPAdapter");
const WebSocketAdapter_1 = require("./WebSocketAdapter");
/**
 * Factory function to create the appropriate protocol adapter based on configuration
 * @param config Bot configuration containing protocol type
 * @returns Instance of the appropriate protocol adapter
 */
function createProtocolAdapter(config) {
    switch (config.protocol) {
        case 'http':
            return new HTTPAdapter_1.HTTPAdapter();
        case 'websocket':
            return new WebSocketAdapter_1.WebSocketAdapter();
        default:
            throw new Error(`Unsupported protocol: ${config.protocol}. Supported protocols are: http, websocket`);
    }
}
//# sourceMappingURL=index.js.map