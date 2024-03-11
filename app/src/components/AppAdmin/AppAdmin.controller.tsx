'use client';

import View from './AppAdmin.view';
import useUserAgent from '@/hooks/useUserAgent';
import useViewportSize from '@/hooks/useViewportSize';

export const Controller = () => {
  const ua = useUserAgent();
  const { width, height } = useViewportSize();

  return (
    <View
      isDev={process.env.NEXT_PUBLIC_BUILD_ENVIRONMENT !== 'production'}
      build={{
        env: process.env.NEXT_PUBLIC_BUILD_ENVIRONMENT,
        version: process.env.NEXT_PUBLIC_BUILD_VERSION,
        commit: process.env.NEXT_PUBLIC_COMMIT_ID,
        datetime: process.env.NEXT_PUBLIC_BUILD_DATETIME
      }}
      device={{
        device: ua?.device.type,
        resolution: `${width} x ${height}`,
        os: `${ua?.os.name} ${ua?.os.version}`,
        browser: `${ua?.browser.name} ${ua?.browser.version}`
      }}
    />
  );
};
