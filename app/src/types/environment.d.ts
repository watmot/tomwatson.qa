declare global {
  namespace NodeJS {
    interface ProcessEnv {
      NODE_ENV: 'development' | 'production';
      NEXT_PUBLIC_PACKAGE_VERSION: string;
      NEXT_PUBLIC_BUILD_ENVIRONMENT: 'local' | 'dev' | 'test' | 'staging' | 'production';
      NEXT_PUBLIC_BUILD_VERSION: string;
      NEXT_PUBLIC_COMMIT_ID: string;
    }
  }
}

export {};
