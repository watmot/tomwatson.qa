import '@prismicio/client';
import { NextApiRequest, PreviewData } from 'next';

import { ClientConfig } from '@prismicio/client';

declare module '@prismicio/client' {
  export interface NextClientConfig extends ClientConfig {
    previewData?: PreviewData;
    req?: NextApiRequest | undefined;
  }
}
