const zIndexes = ['version', 'cursor', 'header']; // decreasing in order of priority

const zIndex = (name: string) => {
  const foundIndex = zIndexes.findIndex((item) => item === name);
  if (foundIndex !== -1) return zIndexes.length - foundIndex;
  return 0;
};

export default zIndex;
