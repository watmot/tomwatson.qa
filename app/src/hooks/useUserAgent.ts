import { useEffect, useState } from 'react';

import UAParser from 'ua-parser-js';

const useUserAgent = () => {
  const [parsedUA, setParsedUA] = useState<UAParser.IResult | null>(null);

  useEffect(() => {
    if (!window) return;

    const userAgent = navigator.userAgent;
    const parser = new UAParser(userAgent);
    const results = parser.getResult();

    // Desktop as a device type is not detected by the UA Parser
    // If the device type is not mobile or tablet, we assume it is desktop
    if (results.device.type !== 'mobile' && results.device.type !== 'tablet') {
      results.device.type = 'desktop';
    }

    setParsedUA(results);
  }, [setParsedUA]);

  return parsedUA;
};

export default useUserAgent;
