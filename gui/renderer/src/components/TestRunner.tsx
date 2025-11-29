import { useState, useEffect } from 'react';
import { Play, Square, CheckCircle, XCircle, Clock } from 'lucide-react';
import { useAppStore } from '../store/useAppStore';
import StatusIndicator from './StatusIndicator';

function TestRunner() {
  const { currentConfig, isTestRunning, setTestRunning, testProgress, updateProgress } = useAppStore();
  const [results, setResults] = useState<any>(null);
  const [logs, setLogs] = useState<string[]>([]);

  useEffect(() => {
    // Listen for test progress
    window.patienceAPI.onTestProgress((data) => {
      updateProgress(data);
      addLog(`[${data.type}] ${JSON.stringify(data.data)}`);
    });

    return () => {
      window.patienceAPI.removeTestProgressListener();
    };
  }, []);

  const addLog = (message: string) => {
    const timestamp = new Date().toLocaleTimeString();
    setLogs(prev => [...prev, `[${timestamp}] ${message}`]);
  };

  const handleRunTests = async () => {
    if (!currentConfig) {
      addLog('Error: No configuration loaded');
      return;
    }

    setTestRunning(true);
    setResults(null);
    setLogs([]);
    addLog('Starting tests...');

    try {
      const result = await window.patienceAPI.runLiveTests(currentConfig);
      
      if (result.success) {
        setResults(result.results);
        addLog('Tests completed successfully');
      } else {
        addLog(`Error: ${result.error}`);
      }
    } catch (error) {
      addLog(`Error: ${(error as Error).message}`);
    } finally {
      setTestRunning(false);
    }
  };

  const handleStopTests = () => {
    setTestRunning(false);
    addLog('Tests stopped by user');
  };

  const scenarioCount = currentConfig?.scenarios?.length || 0;

  return (
    <div className="flex flex-col h-full">
      {/* Control Panel */}
      <div className="bg-gray-800 border-b border-gray-700 p-4">
        <div className="flex items-center justify-between mb-4">
          <div>
            <h3 className="text-lg font-semibold">Test Execution</h3>
            <p className="text-sm text-gray-400">
              {scenarioCount} scenario{scenarioCount !== 1 ? 's' : ''} configured
            </p>
          </div>
          <div className="flex gap-2">
            {!isTestRunning ? (
              <button
                onClick={handleRunTests}
                disabled={!currentConfig}
                className="flex items-center gap-2 px-4 py-2 bg-blue-600 hover:bg-blue-700 disabled:bg-gray-600 disabled:cursor-not-allowed rounded-lg transition-colors"
              >
                <Play size={18} />
                Run Tests
              </button>
            ) : (
              <button
                onClick={handleStopTests}
                className="flex items-center gap-2 px-4 py-2 bg-red-600 hover:bg-red-700 rounded-lg transition-colors"
              >
                <Square size={18} />
                Stop
              </button>
            )}
          </div>
        </div>

        {/* Scenario List */}
        {currentConfig?.scenarios && (
          <div className="space-y-2">
            {currentConfig.scenarios.map((scenario: any, index: number) => (
              <div
                key={scenario.id}
                className="flex items-center gap-3 p-3 bg-gray-700 rounded-lg"
              >
                <div className="flex-shrink-0">
                  {results?.scenarioResults?.[index]?.passed === true && (
                    <CheckCircle size={20} className="text-green-400" />
                  )}
                  {results?.scenarioResults?.[index]?.passed === false && (
                    <XCircle size={20} className="text-red-400" />
                  )}
                  {!results && isTestRunning && (
                    <Clock size={20} className="text-blue-400 animate-pulse" />
                  )}
                  {!results && !isTestRunning && (
                    <div className="w-5 h-5 rounded-full border-2 border-gray-500" />
                  )}
                </div>
                <div className="flex-1">
                  <p className="font-medium">{scenario.name}</p>
                  <p className="text-sm text-gray-400">
                    {scenario.steps?.length || 0} step{scenario.steps?.length !== 1 ? 's' : ''}
                  </p>
                </div>
                {results?.scenarioResults?.[index] && (
                  <div className="text-sm text-gray-400">
                    {results.scenarioResults[index].duration}ms
                  </div>
                )}
              </div>
            ))}
          </div>
        )}
      </div>

      {/* Status & Results */}
      <div className="flex-1 flex flex-col overflow-hidden">
        {isTestRunning && testProgress && (
          <StatusIndicator progress={testProgress} />
        )}

        {results && (
          <div className="p-4 border-b border-gray-700 bg-gray-800">
            <h4 className="font-semibold mb-2">Results Summary</h4>
            <div className="grid grid-cols-3 gap-4">
              <div className="bg-gray-700 p-3 rounded-lg">
                <p className="text-sm text-gray-400">Total</p>
                <p className="text-2xl font-bold">{results.totalScenarios}</p>
              </div>
              <div className="bg-green-900/30 p-3 rounded-lg">
                <p className="text-sm text-green-400">Passed</p>
                <p className="text-2xl font-bold text-green-400">{results.passedScenarios}</p>
              </div>
              <div className="bg-red-900/30 p-3 rounded-lg">
                <p className="text-sm text-red-400">Failed</p>
                <p className="text-2xl font-bold text-red-400">{results.failedScenarios}</p>
              </div>
            </div>
          </div>
        )}

        {/* Console Output */}
        <div className="flex-1 overflow-auto p-4">
          <h4 className="font-semibold mb-2 text-sm text-gray-400">Console Output</h4>
          <div className="bg-black/50 rounded-lg p-3 font-mono text-xs space-y-1">
            {logs.length === 0 ? (
              <p className="text-gray-500">No output yet. Run tests to see logs.</p>
            ) : (
              logs.map((log, index) => (
                <div key={index} className="text-gray-300">
                  {log}
                </div>
              ))
            )}
          </div>
        </div>
      </div>
    </div>
  );
}

export default TestRunner;
