'use client';

import { FC, useEffect, useState } from 'react';

import classNames from 'classnames';
import css from './AppAdmin.module.scss';

export interface ViewProps {
  isDev: boolean;
  build: {
    env: 'local' | 'dev' | 'test' | 'staging' | 'production';
    version: string;
    commit: string;
  };
  device: {
    device?: string;
    resolution?: string;
    os?: string;
    browser?: string;
  };
}

export const View: FC<ViewProps> = ({ isDev, build, device }) => {
  const [expanded, setExpanded] = useState(false);
  const [hidden, setHidden] = useState(false);
  const [removed, setRemoved] = useState(false);
  const [render, setRender] = useState(true);

  const handleHide = () => {
    if (expanded) setExpanded(false);
    setHidden((prev) => !prev);
  };

  const handleExpand = () => {
    setExpanded((prev) => !prev);
  };

  const handleRemove = () => {
    setRemoved((prev) => !prev);
  };

  useEffect(() => {
    if (isDev && !removed) {
      setRender(true);
    } else {
      setRender(false);
    }
  }, [isDev, removed]);

  return render ? (
    <div data-testid="app-admin" className={classNames('AppAdmin', css.root)}>
      <div data-testid="basic" className={css.basic}>
        {!hidden && (
          <ul data-testid="info" className={css.info}>
            <li aria-label="basic-info-env">{build.env}</li>
            &nbsp;|&nbsp;
            <li aria-label="basic-info-version">{build.version}</li>
            &nbsp;|&nbsp;
          </ul>
        )}
        <div className={css.buttons}>
          {!hidden && (
            <button aria-label={`${expanded ? 'collapse' : 'expand'} admin`} onClick={handleExpand}>
              <div>{expanded ? '▼' : '▲'}</div>
            </button>
          )}
          <button aria-label={`${hidden ? 'show' : 'hide'} admin`} onClick={handleHide}>
            <div>{hidden ? '◀' : '▶'}</div>
          </button>
        </div>
      </div>
      {expanded && (
        <div data-testid="expanded">
          <div data-testid="device" className={css.section}>
            <h6>Device Info</h6>
            <ul>
              {Object.entries(device).map((entry) => {
                const key = entry[0] as keyof typeof device;
                const value = entry[1];
                return (
                  <li key={key} aria-label={`device-info-${key}`}>
                    {value}
                  </li>
                );
              })}
            </ul>
          </div>
          <div data-testid="build" className={css.section}>
            <h6>Build Info</h6>
            <ul>
              {Object.entries(build).map((entry) => {
                const key = entry[0] as keyof typeof build;
                const value = entry[1];
                return (
                  <li key={key} aria-label={`build-info-${key}`}>
                    {value}
                  </li>
                );
              })}
            </ul>
          </div>
          <button className={css.section} onClick={handleRemove}>
            Remove from DOM
          </button>
        </div>
      )}
    </div>
  ) : null;
};

export default View;
