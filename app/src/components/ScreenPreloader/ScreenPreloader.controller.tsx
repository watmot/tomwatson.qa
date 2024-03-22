import { useEffect, useState } from 'react';

import { Preloader } from '@/services/preloader.service';
import View from './ScreenPreloader.view';

export const Controller = () => {
  const [progress, setProgress] = useState(0);

  useEffect(() => {
    Preloader.load(setProgress);
  }, [setProgress]);

  return <View progress={progress} />;
};
