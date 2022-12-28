import * as Styled from './index.styles';

import { useEffect, useState } from 'react';

const BuildVersion = () => {
  const isProduction = process.env.NEXT_PUBLIC_BUILD_ENVIRONMENT.toLowerCase() === 'production';
  const env = `Environment: ${process.env.NEXT_PUBLIC_BUILD_ENVIRONMENT}`;
  const version = `Version: ${process.env.NEXT_PUBLIC_PACKAGE_VERSION}`;
  const datetime = `Date: ${process.env.NEXT_PUBLIC_BUILD_DATE} ${process.env.NEXT_PUBLIC_BUILD_TIME}`;

  const [displayActive, setDisplayActive] = useState(false);

  useEffect(() => {
    console.info(
      `%c${env}\n${version}\n${datetime}`,
      'background: #34568B; color: white; padding: 10px 20px'
    );
  });

  const handleClick = () => {
    setDisplayActive((prev) => !prev);
  };

  return !isProduction ? (
    <Styled.Wrapper>
      <Styled.Button onClick={handleClick}>+</Styled.Button>
      {displayActive && (
        <>
          <Styled.Text>{`${env}`}</Styled.Text>
          <Styled.Text>{`${version}`}</Styled.Text>
          <Styled.Text>{`${datetime}`}</Styled.Text>
        </>
      )}
    </Styled.Wrapper>
  ) : null;
};

export default BuildVersion;
