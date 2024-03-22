import { ReactNode } from 'react';
import { ScreenPreloader } from '@/components/ScreenPreloader';

interface LayoutProps {
  children: ReactNode;
}

export default function Layout({ children }: LayoutProps) {
  return (
    <>
      <ScreenPreloader />
      <main>{children}</main>
    </>
  );
}
