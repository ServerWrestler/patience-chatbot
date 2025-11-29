import { useState } from 'react';
import { Play, Square, Settings, FileJson } from 'lucide-react';
import ConfigEditor from '../components/ConfigEditor';
import TestRunner from '../components/TestRunner';
import { useAppStore } from '../store/useAppStore';

function LiveTesting() {
  const [showEditor, setShowEditor] = useState(false);
  const { currentConfig, isTestRunning } = useAppStore();

  return (
    <div className="flex-1 flex flex-col">
      {/* Header */}
      <div className="bg-gray-800 border-b border-gray-700 p-4">
        <div className="flex items-center justify-between">
          <div>
            <h2 className="text-xl font-semibold">Live Testing</h2>
            <p className="text-sm text-gray-400">Test your chatbot in real-time with scenarios</p>
          </div>
          <div className="flex gap-2">
            <button
              onClick={() => setShowEditor(!showEditor)}
              className="flex items-center gap-2 px-4 py-2 bg-gray-700 hover:bg-gray-600 rounded-lg transition-colors"
            >
              <FileJson size={18} />
              {showEditor ? 'Hide' : 'Show'} Config
            </button>
            <button
              className="flex items-center gap-2 px-4 py-2 bg-gray-700 hover:bg-gray-600 rounded-lg transition-colors"
            >
              <Settings size={18} />
              Settings
            </button>
          </div>
        </div>
      </div>

      {/* Content */}
      <div className="flex-1 flex overflow-hidden">
        {/* Config Editor (collapsible) */}
        {showEditor && (
          <div className="w-1/2 border-r border-gray-700 flex flex-col">
            <ConfigEditor />
          </div>
        )}

        {/* Test Runner */}
        <div className={`${showEditor ? 'w-1/2' : 'w-full'} flex flex-col`}>
          <TestRunner />
        </div>
      </div>
    </div>
  );
}

export default LiveTesting;
