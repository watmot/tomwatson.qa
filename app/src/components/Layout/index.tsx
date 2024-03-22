import { AppAdmin } from '../AppAdmin';
import { ReactNode } from 'react';
import { ScreenPreloader } from '@/components/ScreenPreloader';

interface LayoutProps {
  children: ReactNode;
}

export default function Layout({ children }: LayoutProps) {
  return (
    <>
      {process.env.NEXT_PUBLIC_BUILD_ENVIRONMENT !== 'production' && <AppAdmin />}
      <ScreenPreloader />
      <main>{children}</main>
    </>
  );
}
