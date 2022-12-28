import { createGlobalStyle } from 'styled-components';
import reset from './reset';

const GlobalStyle = createGlobalStyle`
  // Reset
  ${reset}


  // Base
  * {
    box-sizing: border-box;
  }

  html,
  body,
  #__next {
    overflow-x: hidden;
    overscroll-behavior: none;
  }

  html {
    font-size: calc(100vw / 1440 * 10);
  }
`;

export default GlobalStyle;
