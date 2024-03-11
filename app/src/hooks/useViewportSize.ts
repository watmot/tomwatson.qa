import { useEffect, useState } from 'react';

const useViewportSize = () => {
  const [width, setWidth] = useState(0);
  const [height, setHeight] = useState(0);

  const updateDimensions = () => {
    const { innerWidth, innerHeight } = window;

    setWidth(innerWidth);
    setHeight(innerHeight);
  };

  useEffect(() => {
    updateDimensions();

    window.addEventListener('resize', updateDimensions);

    return () => {
      window.removeEventListener('resize', updateDimensions);
    };
  }, []);

  return { width, height };
};

export default useViewportSize;
