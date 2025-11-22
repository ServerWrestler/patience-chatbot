/**
 * Unit tests for ConfigurationManager
 */

import { describe, test, expect } from 'vitest';
import { ConfigurationManager } from '../../config/ConfigurationManager';
import { createMockTestConfig } from '../helpers/testUtils';
import * as fs from 'fs/promises';
import * as path from 'path';
import * as os from 'os';

describe('ConfigurationManager', () => {
  test('should load valid JSON configuration', async () => {
    const configManager = new ConfigurationManager();
    const config = createMockTestConfig();
    
    const tempDir = await fs.mkdtemp(path.join(os.tmpdir(), 'patience-test-'));
    const configPath = path.join(tempDir, 'config.json');
    
    try {
      await fs.writeFile(configPath, JSON.stringify(config));
      const loaded = await configManager.loadConfig(configPath);
      
      expect(loaded.targetBot.name).toBe(config.targetBot.name);
      expect(loaded.scenarios.length).toBe(config.scenarios.length);
    } finally {
      await fs.rm(tempDir, { recursive: true, force: true });
    }
  });

  test('should reject invalid configuration with specific errors', () => {
    const configManager = new ConfigurationManager();
    const invalidConfig = {
      targetBot: {
        name: '',
        protocol: 'invalid',
        endpoint: ''
      }
    };

    const result = configManager.validateConfig(invalidConfig as any);
    
    expect(result.passed).toBe(false);
    expect(result.details?.errors).toBeDefined();
    expect(result.details!.errors.length).toBeGreaterThan(0);
    expect(result.message).toContain('protocol');
  });

  test('should validate required fields', () => {
    const configManager = new ConfigurationManager();
    const config = createMockTestConfig({
      scenarios: [
        {
          id: 'test-1',
          name: 'Test Scenario',
          steps: [{ message: 'Hello' }],
          expectedOutcomes: []
        }
      ]
    });

    const result = configManager.validateConfig(config);
    
    expect(result.passed).toBe(true);
    expect(result.message).toContain('valid');
  });

  test('should load scenarios from file', async () => {
    const configManager = new ConfigurationManager();
    const scenarios = [
      {
        id: 'scenario-1',
        name: 'Test Scenario',
        steps: [{ message: 'Hello' }],
        expectedOutcomes: []
      }
    ];
    
    const tempDir = await fs.mkdtemp(path.join(os.tmpdir(), 'patience-test-'));
    const scenarioPath = path.join(tempDir, 'scenarios.json');
    
    try {
      await fs.writeFile(scenarioPath, JSON.stringify(scenarios));
      const loaded = await configManager.loadScenarios(scenarioPath);
      
      expect(loaded.length).toBe(1);
      expect(loaded[0].id).toBe('scenario-1');
    } finally {
      await fs.rm(tempDir, { recursive: true, force: true });
    }
  });

  test('should throw error for unsupported file format', async () => {
    const configManager = new ConfigurationManager();
    const tempDir = await fs.mkdtemp(path.join(os.tmpdir(), 'patience-test-'));
    const txtPath = path.join(tempDir, 'test.txt');
    
    try {
      await fs.writeFile(txtPath, 'invalid content');
      
      await expect(
        configManager.loadConfig(txtPath)
      ).rejects.toThrow('Unsupported file format');
    } finally {
      await fs.rm(tempDir, { recursive: true, force: true });
    }
  });

  test('should validate timing configuration', () => {
    const configManager = new ConfigurationManager();
    const config = createMockTestConfig({
      timing: {
        enableDelays: true,
        baseDelay: -1,
        delayPerCharacter: 10,
        rapidFire: false,
        responseTimeout: 5000
      }
    });

    const result = configManager.validateConfig(config);
    
    expect(result.passed).toBe(false);
    expect(result.message).toContain('baseDelay');
  });

  test('should validate reporting configuration', () => {
    const configManager = new ConfigurationManager();
    const config = createMockTestConfig({
      reporting: {
        outputPath: '',
        formats: [],
        includeConversationHistory: true,
        verboseErrors: true
      }
    });

    const result = configManager.validateConfig(config);
    
    expect(result.passed).toBe(false);
    expect(result.message).toContain('outputPath');
  });
});
