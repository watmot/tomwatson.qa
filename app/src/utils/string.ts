export const toTitleCase = (str: string) => {
  return str.replace(
    /\w*/g,
    (val) => `${val.charAt(0).toUpperCase()}${val.substring(1).toLowerCase()}`
  );
};
