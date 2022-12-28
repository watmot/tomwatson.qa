const breakpoints = {
  mobile: '480px',
  tablet: '834px',
  small: '1133px',
  large: '1920px'
};

const device = {
  mobile: `(max-width: ${breakpoints.mobile})`,
  tablet: `(max-width: ${breakpoints.tablet})`,
  small: `(max-width: ${breakpoints.small})`,
  large: `(max-width: ${breakpoints.large})`
};

export default device;
