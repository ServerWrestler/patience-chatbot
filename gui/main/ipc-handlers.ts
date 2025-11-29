/**
 * IPC Handlers for communication between main and renderer processes
 */

import { ipcMain, dialog } from 'electron';
import * as fs from 'fs/promises';
import * as path from 'path';
import { TestExecutor } from '../../src/execution/TestExecutor';

export function setupIpcHandlers() {
  // File operations
  ipcMain.handle('file:read', async (event, filePath: string) => {
    try {
      const content = await fs.readFile(filePath, 'utf-8');
      return { success: true, content };
    } catch (error) {
      return { success: false, error: (error as Error).message };
    }
  });

  ipcMain.handle('file:write', async (event, filePath: string, content: string) => {
    try {
      await fs.writeFile(filePath, content, 'utf-8');
      return { success: true };
    } catch (error) {
      return { success: false, error: (error as Error).message };
    }
  });

  ipcMain.handle('file:browse', async (event, options) => {
    try {
      const result = await dialog.showOpenDialog(options);
      return { success: true, ...result };
    } catch (error) {
      return { success: false, error: (error as Error).message };
    }
  });

  ipcMain.handle('file:save-dialog', async (event, options) => {
    try {
      const result = await dialog.showSaveDialog(options);
      return { success: true, ...result };
    } catch (error) {
      return { success: false, error: (error as Error).message };
    }
  });

  ipcMain.handle('directory:list', async (event, dirPath: string) => {
    try {
      const files = await fs.readdir(dirPath, { withFileTypes: true });
      const fileList = files.map(file => ({
        name: file.name,
        isDirectory: file.isDirectory(),
        path: path.join(dirPath, file.name)
      }));
      return { success: true, files: fileList };
    } catch (error) {
      return { success: false, error: (error as Error).message };
    }
  });

  // Live Testing
  ipcMain.handle('live-test:run', async (event, config) => {
    try {
      const executor = new TestExecutor();
      
      // Send progress updates
      const sendProgress = (type: string, data: any) => {
        event.sender.send('test-progress', { type, data });
      };

      // TODO: Hook up actual progress events from TestExecutor
      sendProgress('start', { totalScenarios: config.scenarios?.length || 0 });

      const results = await executor.executeTests(config);
      
      sendProgress('complete', results);
      
      return { success: true, results };
    } catch (error) {
      return { success: false, error: (error as Error).message };
    }
  });

  // Configuration validation
  ipcMain.handle('config:validate', async (event, config) => {
    try {
      // TODO: Implement proper validation
      const isValid = config && config.targetBot && config.scenarios;
      return { 
        success: true, 
        valid: isValid,
        errors: isValid ? [] : ['Invalid configuration structure']
      };
    } catch (error) {
      return { success: false, error: (error as Error).message };
    }
  });

  // Get example configurations
  ipcMain.handle('config:get-examples', async () => {
    try {
      const examplesDir = path.join(process.cwd(), 'examples', 'live-testing');
      const files = await fs.readdir(examplesDir);
      const configFiles = files.filter(f => f.endsWith('.json'));
      
      const examples = await Promise.all(
        configFiles.map(async (file) => {
          const filePath = path.join(examplesDir, file);
          const content = await fs.readFile(filePath, 'utf-8');
          return {
            name: file.replace('.json', ''),
            path: filePath,
            content: JSON.parse(content)
          };
        })
      );
      
      return { success: true, examples };
    } catch (error) {
      return { success: false, error: (error as Error).message };
    }
  });
}
