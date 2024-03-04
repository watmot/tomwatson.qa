import { FC } from 'react';
import classNames from 'classnames';
import css from './PageHome.module.scss';

export interface ViewProps {
  title: string;
}

export const View: FC<ViewProps> = ({ title }) => {
  return (
    <main className={classNames('PageHome', css.root)}>
      <h1>{title}</h1>
    </main>
  );
};

export default View;
