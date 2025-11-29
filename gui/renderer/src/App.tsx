import { useState } from 'react';
import { FlaskConical, BarChart3, Bot, FileText } from 'lucide-react';
import LiveTesting from './pages/LiveTesting';
import { cn } from './lib/utils';

type Page = 'live-testing' | 'log-analysis' | 'adversarial' | 'reports';

function App() {
  const [currentPage, setCurrentPage] = useState<Page>('live-testing');

  const navigation = [
    { id: 'live-testing' as Page, label: 'Live Testing', icon: FlaskConical },
    { id: 'log-analysis' as Page, label: 'Log Analysis', icon: BarChart3 },
    { id: 'adversarial' as Page, label: 'Adversarial', icon: Bot },
    { id: 'reports' as Page, label: 'Reports', icon: FileText }
  ];

  return (
    <div className="flex h-screen bg-gray-900 text-gray-100">
      {/* Sidebar */}
      <div className="w-64 bg-gray-800 border-r border-gray-700 flex flex-col">
        <div className="p-4 border-b border-gray-700">
          <h1 className="text-xl font-bold text-blue-400">Patience</h1>
          <p className="text-xs text-gray-400">Chatbot Testing</p>
        </div>
        
        <nav className="flex-1 p-4">
          {navigation.map((item) => {
            const Icon = item.icon;
            return (
              <button
                key={item.id}
                onClick={() => setCurrentPage(item.id)}
                className={cn(
                  'w-full flex items-center gap-3 px-4 py-3 rounded-lg mb-2 transition-colors',
                  currentPage === item.id
                    ? 'bg-blue-600 text-white'
                    : 'text-gray-300 hover:bg-gray-700'
                )}
              >
                <Icon size={20} />
                <span>{item.label}</span>
              </button>
            );
          })}
        </nav>

        <div className="p-4 border-t border-gray-700 text-xs text-gray-400">
          <p>Version 0.2.0-beta.2</p>
        </div>
      </div>

      {/* Main Content */}
      <div className="flex-1 flex flex-col overflow-hidden">
        {currentPage === 'live-testing' && <LiveTesting />}
        {currentPage === 'log-analysis' && (
          <div className="flex-1 flex items-center justify-center">
            <p className="text-gray-400">Log Analysis - Coming Soon</p>
          </div>
        )}
        {currentPage === 'adversarial' && (
          <div className="flex-1 flex items-center justify-center">
            <p className="text-gray-400">Adversarial Testing - Coming Soon</p>
          </div>
        )}
        {currentPage === 'reports' && (
          <div className="flex-1 flex items-center justify-center">
            <p className="text-gray-400">Reports - Coming Soon</p>
          </div>
        )}
      </div>
    </div>
  );
}

export default App;
