import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import path from 'path';

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, 'src'),
      '#infrastructure': path.resolve(__dirname, '..', 'infrastructure'),
    },
  },
  server: {
    fs: {
      allow: ['..'],
    },
  },
});
