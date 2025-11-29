import { useState, useEffect } from 'react';
import { Save, FolderOpen, FileText } from 'lucide-react';
import Editor from '@monaco-editor/react';
import { useAppStore } from '../store/useAppStore';

function ConfigEditor() {
  const { currentConfig, setConfig } = useAppStore();
  const [editorValue, setEditorValue] = useState('');
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (currentConfig) {
      setEditorValue(JSON.stringify(currentConfig, null, 2));
    } else {
      // Default minimal config
      const defaultConfig = {
        targetBot: {
          name: 'My Bot',
          protocol: 'http',
          endpoint: 'http://localhost:3000/chat'
        },
        scenarios: [
          {
            id: 'test-1',
            name: 'Simple Test',
            steps: [
              {
                message: 'Hello'
              }
            ],
            expectedOutcomes: []
          }
        ],
        validation: {
          defaultType: 'pattern'
        },
        timing: {
          enableDelays: false,
          baseDelay: 0,
          delayPerCharacter: 0,
          rapidFire: true,
          responseTimeout: 30000
        },
        reporting: {
          outputPath: './reports',
          formats: ['html'],
          includeConversationHistory: true,
          verboseErrors: true
        }
      };
      setEditorValue(JSON.stringify(defaultConfig, null, 2));
      setConfig(defaultConfig);
    }
  }, []);

  const handleEditorChange = (value: string | undefined) => {
    if (!value) return;
    setEditorValue(value);
    
    try {
      const parsed = JSON.parse(value);
      setConfig(parsed);
      setError(null);
    } catch (e) {
      setError('Invalid JSON');
    }
  };

  const handleLoadExample = async () => {
    try {
      const result = await window.patienceAPI.getExampleConfigs();
      if (result.success && result.examples.length > 0) {
        const example = result.examples[0];
        setEditorValue(JSON.stringify(example.content, null, 2));
        setConfig(example.content);
      }
    } catch (e) {
      setError('Failed to load examples');
    }
  };

  const handleOpenFile = async () => {
    try {
      const result = await window.patienceAPI.browseFile({
        properties: ['openFile'],
        filters: [{ name: 'JSON', extensions: ['json'] }]
      });
      
      if (result.success && !result.canceled && result.filePaths.length > 0) {
        const fileResult = await window.patienceAPI.readFile(result.filePaths[0]);
        if (fileResult.success) {
          const parsed = JSON.parse(fileResult.content);
          setEditorValue(JSON.stringify(parsed, null, 2));
          setConfig(parsed);
        }
      }
    } catch (e) {
      setError('Failed to open file');
    }
  };

  const handleSaveFile = async () => {
    try {
      const result = await window.patienceAPI.saveDialog({
        filters: [{ name: 'JSON', extensions: ['json'] }],
        defaultPath: 'config.json'
      });
      
      if (result.success && !result.canceled && result.filePath) {
        await window.patienceAPI.writeFile(result.filePath, editorValue);
      }
    } catch (e) {
      setError('Failed to save file');
    }
  };

  return (
    <div className="flex flex-col h-full">
      {/* Toolbar */}
      <div className="bg-gray-800 border-b border-gray-700 p-2 flex items-center gap-2">
        <button
          onClick={handleOpenFile}
          className="flex items-center gap-2 px-3 py-1.5 bg-gray-700 hover:bg-gray-600 rounded text-sm transition-colors"
        >
          <FolderOpen size={16} />
          Open
        </button>
        <button
          onClick={handleSaveFile}
          className="flex items-center gap-2 px-3 py-1.5 bg-gray-700 hover:bg-gray-600 rounded text-sm transition-colors"
        >
          <Save size={16} />
          Save
        </button>
        <button
          onClick={handleLoadExample}
          className="flex items-center gap-2 px-3 py-1.5 bg-gray-700 hover:bg-gray-600 rounded text-sm transition-colors"
        >
          <FileText size={16} />
          Load Example
        </button>
        {error && (
          <span className="ml-auto text-sm text-red-400">{error}</span>
        )}
      </div>

      {/* Editor */}
      <div className="flex-1">
        <Editor
          height="100%"
          language="json"
          theme="vs-dark"
          value={editorValue}
          onChange={handleEditorChange}
          options={{
            minimap: { enabled: false },
            fontSize: 13,
            lineNumbers: 'on',
            scrollBeyondLastLine: false,
            automaticLayout: true,
            tabSize: 2,
            formatOnPaste: true,
            formatOnType: true
          }}
        />
      </div>
    </div>
  );
}

export default ConfigEditor;
