/**
 * Preload script - Exposes safe APIs to renderer process
 */

import { contextBridge, ipcRenderer } from 'electron';

// Define the API interface
export interface PatienceAPI {
  // File operations
  readFile: (path: string) => Promise<any>;
  writeFile: (path: string, content: string) => Promise<any>;
  browseFile: (options: any) => Promise<any>;
  saveDialog: (options: any) => Promise<any>;
  listDirectory: (path: string) => Promise<any>;

  // Live Testing
  runLiveTests: (config: any) => Promise<any>;
  
  // Configuration
  validateConfig: (config: any) => Promise<any>;
  getExampleConfigs: () => Promise<any>;

  // Event listeners
  onTestProgress: (callback: (data: any) => void) => void;
  removeTestProgressListener: () => void;
}

// Expose protected methods to renderer
contextBridge.exposeInMainWorld('patienceAPI', {
  // File operations
  readFile: (path: string) => ipcRenderer.invoke('file:read', path),
  writeFile: (path: string, content: string) => ipcRenderer.invoke('file:write', path, content),
  browseFile: (options: any) => ipcRenderer.invoke('file:browse', options),
  saveDialog: (options: any) => ipcRenderer.invoke('file:save-dialog', options),
  listDirectory: (path: string) => ipcRenderer.invoke('directory:list', path),

  // Live Testing
  runLiveTests: (config: any) => ipcRenderer.invoke('live-test:run', config),

  // Configuration
  validateConfig: (config: any) => ipcRenderer.invoke('config:validate', config),
  getExampleConfigs: () => ipcRenderer.invoke('config:get-examples'),

  // Event listeners
  onTestProgress: (callback: (data: any) => void) => {
    ipcRenderer.on('test-progress', (event, data) => callback(data));
  },
  removeTestProgressListener: () => {
    ipcRenderer.removeAllListeners('test-progress');
  }
} as PatienceAPI);
