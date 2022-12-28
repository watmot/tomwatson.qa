declare global {
  namespace NodeJS {
    interface ProcessEnv {
      NODE_ENV: 'development' | 'production';
      NEXT_PUBLIC_PACKAGE_VERSION: string;
      NEXT_PUBLIC_BUILD_ENVIRONMENT: 'local' | 'development' | 'staging' | 'production';
      NEXT_PUBLIC_BUILD_DATE: string;
      NEXT_PUBLIC_BUILD_TIME: string;
      NEXT_PUBLIC_PRISMIC_REPOSITORY_NAME: string;
    }
  }
}

export {};
