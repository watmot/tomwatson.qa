import 'styled-components';

declare module 'styled-components' {
  export interface DefaultTheme {
    zIndex: (name: string) => number;
  }
}
