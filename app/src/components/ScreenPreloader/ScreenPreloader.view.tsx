import { FC, useEffect, useRef, useState } from 'react';

import classNames from 'classnames';
import css from './ScreenPreloader.module.scss';
import gsap from 'gsap';

export interface ViewProps {
  progress: number;
}

export const View: FC<ViewProps> = ({ progress }) => {
  const [loaded, setLoaded] = useState(false);

  const preloaderRef = useRef<HTMLDivElement>(null);
  const loadingBarRef = useRef<HTMLDivElement>(null);
  const crossRef = useRef<HTMLDivElement>(null);
  const fillRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const timeline = gsap
      .timeline()
      .to(fillRef.current, { height: `${progress}%`, duration: 1.5, ease: 'back.in', delay: 1 })
      .add(() => setLoaded(progress === 100));
    return () => {
      timeline.kill();
    };
  }, [progress, setLoaded]);

  useEffect(() => {
    let timeline: gsap.core.Timeline;
    if (loaded) {
      timeline = gsap
        .timeline()
        .to(crossRef.current, { width: '50%', ease: 'sine.out' })
        .to(loadingBarRef.current, { height: '100%', duration: 0.5, ease: 'sine.in' })
        .to(loadingBarRef.current, { width: '100%', duration: 0.5, ease: 'sine.in' })
        .set(preloaderRef.current, { autoAlpha: 0 });
    }

    return () => {
      timeline?.revert();
    };
  }, [loaded]);

  return (
    <div
      data-testid="preloader"
      ref={preloaderRef}
      className={classNames('ScreenPreloader', css.root)}>
      <div className={css.wrapper}>
        <div ref={loadingBarRef} className={css.loader}>
          <div className={css.outline} />
          <div ref={crossRef} className={css.cross} />
          <div data-testid="preloader_fill" ref={fillRef} className={css.fill} />
        </div>
      </div>
    </div>
  );
};

export default View;
