import { defineConfig } from 'cypress';
import { loadEnvConfig } from '@next/env';

const { combinedEnv, loadedEnvFiles } = loadEnvConfig(process.cwd());

export default defineConfig({
  e2e: {
    env: { ...combinedEnv, ...loadedEnvFiles },
    baseUrl: 'http://localhost:3000'
  },
  component: {
    devServer: {
      framework: 'next',
      bundler: 'webpack'
    }
  }
});
