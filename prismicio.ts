import * as prismic from '@prismicio/client';
import * as prismicNext from '@prismicio/next';

import { NextClientConfig } from '@prismicio/client';

export const repositoryName = process.env.NEXT_PUBLIC_PRISMIC_REPOSITORY_NAME;

// For use with SSR/SSG
export const createClient = (config?: NextClientConfig) => {
  const client = prismic.createClient(repositoryName, config);

  prismicNext.enableAutoPreviews({
    client,
    previewData: config?.previewData,
    req: config?.req
  });

  return client;
};
