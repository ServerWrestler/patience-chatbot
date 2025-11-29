import { create } from 'zustand';

interface AppState {
  currentConfig: any | null;
  isTestRunning: boolean;
  testProgress: any | null;
  setConfig: (config: any) => void;
  setTestRunning: (running: boolean) => void;
  updateProgress: (progress: any) => void;
}

export const useAppStore = create<AppState>((set) => ({
  currentConfig: null,
  isTestRunning: false,
  testProgress: null,
  setConfig: (config) => set({ currentConfig: config }),
  setTestRunning: (running) => set({ isTestRunning: running }),
  updateProgress: (progress) => set({ testProgress: progress })
}));
