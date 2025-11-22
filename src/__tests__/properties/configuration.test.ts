/**
 * Property-based tests for configuration management
 * Tests Properties 31-34
 */

import { describe, test, expect } from 'vitest';
import * as fc from 'fast-check';
import { ConfigurationManager } from '../../config/ConfigurationManager';
import { testConfigGenerator } from '../helpers/generators';
import * as fs from 'fs/promises';
import * as path from 'path';
import * as os from 'os';

describe('Configuration Management Properties', () => {
  /**
   * Property 31: Configuration loading success
   * For any valid configuration file, Patience should successfully load the
   * configuration and make all specified settings available for use.
   */
  test('Property 31: Configuration loading success', async () => {
    await fc.assert(
      fc.asyncProperty(
        testConfigGenerator(),
        async (config) => {
          const configManager = new ConfigurationManager();
          
          // Create temporary config file
          const tempDir = await fs.mkdtemp(path.join(os.tmpdir(), 'patience-test-'));
          const configPath = path.join(tempDir, 'test-config.json');
          
          try {
            await fs.writeFile(configPath, JSON.stringify(config, null, 2));

            // Load configuration
            const loadedConfig = await configManager.loadConfig(configPath);

            // Verify all settings are available
            expect(loadedConfig).toBeDefined();
            expect(loadedConfig.targetBot).toBeDefined();
            expect(loadedConfig.scenarios).toBeDefined();
            expect(loadedConfig.validation).toBeDefined();
            expect(loadedConfig.timing).toBeDefined();
            expect(loadedConfig.reporting).toBeDefined();

            return true;
          } finally {
            // Cleanup
            await fs.rm(tempDir, { recursive: true, force: true });
          }
        }
      ),
      { numRuns: 20 }
    );
  });

  /**
   * Property 32: Configuration validation error specificity
   * For any invalid configuration file, the reported validation errors should
   * identify the specific fields or values that are invalid.
   */
  test('Property 32: Configuration validation error specificity', () => {
    fc.assert(
      fc.property(
        fc.record({
          targetBot: fc.constant(undefined),
          scenarios: fc.constant([]),
          validation: fc.constant(undefined),
          timing: fc.constant(undefined),
          reporting: fc.constant(undefined)
        }),
        (invalidConfig) => {
          const configManager = new ConfigurationManager();
          const result = configManager.validateConfig(invalidConfig as any);

          // Should fail validation
          expect(result.passed).toBe(false);

          // Should have specific error messages
          expect(result.message).toBeDefined();
          expect(result.message!.length).toBeGreaterThan(0);

          // Should identify missing fields
          expect(result.details?.errors).toBeDefined();
          expect(result.details!.errors.length).toBeGreaterThan(0);

          return true;
        }
      ),
      { numRuns: 50 }
    );
  });

  /**
   * Property 33: Scenario file loading completeness
   * For any scenario file containing N scenario definitions, Patience should
   * load exactly N scenarios before test execution begins.
   */
  test('Property 33: Scenario file loading completeness', async () => {
    await fc.assert(
      fc.asyncProperty(
        fc.array(
          fc.record({
            id: fc.uuid(),
            name: fc.string({ minLength: 1, maxLength: 50 }),
            steps: fc.array(
              fc.record({
                message: fc.string({ minLength: 1, maxLength: 100 })
              }),
              { minLength: 1, maxLength: 5 }
            ),
            expectedOutcomes: fc.constant([])
          }),
          { minLength: 1, maxLength: 10 }
        ),
        async (scenarios) => {
          const configManager = new ConfigurationManager();
          
          // Create temporary scenario file
          const tempDir = await fs.mkdtemp(path.join(os.tmpdir(), 'patience-test-'));
          const scenarioPath = path.join(tempDir, 'scenarios.json');
          
          try {
            await fs.writeFile(scenarioPath, JSON.stringify(scenarios, null, 2));

            // Load scenarios
            const loadedScenarios = await configManager.loadScenarios(scenarioPath);

            // Verify exactly N scenarios are loaded
            expect(loadedScenarios.length).toBe(scenarios.length);

            // Verify all scenario IDs match
            const loadedIds = loadedScenarios.map(s => s.id).sort();
            const originalIds = scenarios.map(s => s.id).sort();
            expect(loadedIds).toEqual(originalIds);

            return true;
          } finally {
            // Cleanup
            await fs.rm(tempDir, { recursive: true, force: true });
          }
        }
      ),
      { numRuns: 20 }
    );
  });

  /**
   * Property 34: Configuration hot-reload
   * For any configuration change made while Patience is running, the new
   * configuration should take effect without requiring a process restart.
   */
  test('Property 34: Configuration hot-reload', async () => {
    await fc.assert(
      fc.asyncProperty(
        testConfigGenerator(),
        testConfigGenerator(),
        async (config1, config2) => {
          const configManager = new ConfigurationManager();
          
          // Create temporary config file
          const tempDir = await fs.mkdtemp(path.join(os.tmpdir(), 'patience-test-'));
          const configPath = path.join(tempDir, 'test-config.json');
          
          try {
            // Write initial config
            await fs.writeFile(configPath, JSON.stringify(config1, null, 2));
            const loadedConfig1 = await configManager.loadConfig(configPath);

            // Verify initial config is loaded
            expect(loadedConfig1.targetBot.name).toBe(config1.targetBot.name);

            // Manually reload with new config
            await fs.writeFile(configPath, JSON.stringify(config2, null, 2));
            const reloadedConfig = await configManager.reloadConfig();

            // Verify new config is loaded
            expect(reloadedConfig.targetBot.name).toBe(config2.targetBot.name);

            return true;
          } finally {
            // Cleanup
            configManager.disableHotReload();
            await fs.rm(tempDir, { recursive: true, force: true });
          }
        }
      ),
      { numRuns: 10 }
    );
  });
});
