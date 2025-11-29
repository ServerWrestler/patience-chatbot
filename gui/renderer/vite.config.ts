import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import path from 'path';

export default defineConfig({
  plugins: [react()],
  root: './gui/renderer',
  base: './',
  build: {
    outDir: '../../dist-gui/renderer',
    emptyOutDir: true
  },
  server: {
    port: 5555,
    strictPort: true
  },
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src')
    }
  }
});
