import { Loader2 } from 'lucide-react';

interface StatusIndicatorProps {
  progress: any;
}

function StatusIndicator({ progress }: StatusIndicatorProps) {
  return (
    <div className="p-4 bg-blue-900/20 border-b border-blue-700">
      <div className="flex items-center gap-3">
        <Loader2 size={20} className="animate-spin text-blue-400" />
        <div className="flex-1">
          <p className="font-medium text-blue-400">Running Tests...</p>
          <p className="text-sm text-gray-400">
            {progress.type === 'start' && `Starting ${progress.data.totalScenarios} scenarios`}
            {progress.type === 'scenario-start' && `Running: ${progress.data.name}`}
            {progress.type === 'scenario-complete' && `Completed: ${progress.data.name}`}
          </p>
        </div>
      </div>
    </div>
  );
}

export default StatusIndicator;
