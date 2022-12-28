import type { AppProps } from 'next/app';
import BuildVersion from '../components/BuildVersion';
import GlobalStyle from '../styles/base';
import { PrismicPreview } from '@prismicio/next';
import { PrismicProvider } from '@prismicio/react';
import { ThemeProvider } from 'styled-components';
import { repositoryName } from '../prismicio';
import theme from '../styles/theme';

function App({ Component, pageProps }: AppProps) {
  return (
    <>
      <PrismicProvider>
        <PrismicPreview repositoryName={repositoryName}>
          <GlobalStyle />
          <ThemeProvider theme={theme}>
            <BuildVersion />
            <Component {...pageProps} />
          </ThemeProvider>
        </PrismicPreview>
      </PrismicProvider>
    </>
  );
}

export default App;
