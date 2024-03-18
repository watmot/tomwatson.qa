import fs from 'fs';
import path from 'path';
export type Paths = string[];

interface GetLines {
  src?: string;
  dir: string;
  lines?: string;
  prefix?: string;
  suffix?: string;
}

const name = 'scripts/generate-imports';

const isImage = (filePath: string) => {
  return /.(jpg|png|jpeg|gif|webp|avif|ico|bmp)/i.test(filePath);
};

const generateSingleExportString = (filePath: string) =>
  `\t'${filePath}': require('${filePath}')${isImage(filePath) ? '.default.src' : ''} as string,\n`;

const getLines = ({ src, dir, lines = '', prefix = '', suffix = '' }: GetLines) => {
  if (!src) src = '../src';

  const resolvedSrc = path.resolve(__dirname, src);
  const resolvedDir = path.resolve(resolvedSrc, dir);

  if (!fs.existsSync(resolvedDir)) throw new Error(`${resolvedDir} does not exist!`);

  if (!lines.length && prefix) lines += prefix;

  const dirents = fs.readdirSync(resolvedDir, { withFileTypes: true });
  dirents.forEach((dirent) => {
    if (dirent.isDirectory()) {
      lines = getLines({ dir: path.join(dir, dirent.name), lines });
    } else {
      const relativeDir = dirent.path.replace(resolvedSrc, '@');
      const filePath = path.join(relativeDir, dirent.name);
      // const isImage = getTypeCast(filePath);
      lines += generateSingleExportString(filePath);
    }
  });

  if (suffix) lines += suffix;
  return lines;
};

interface Generate {
  src?: string;
  dir: string;
  filename: string;
  prefix: string;
  suffix: string;
}

export const generate = ({ src, dir, filename, prefix, suffix }: Generate) => {
  const outputDir = './.data';

  console.log(`[${name}] Generating asset import script...`);
  const lines = getLines({ src, dir, prefix, suffix });

  try {
    if (!fs.existsSync(outputDir)) fs.mkdirSync(outputDir);

    const filePath = path.join(outputDir, filename);
    fs.writeFileSync(filePath, lines);
    console.log(`[${name}] Imports generated. Data written to ${filePath}`);
  } catch (err) {
    console.error(`[${name}] ${err}`);
  }
};

generate({
  dir: 'assets',
  filename: 'assets.ts',
  prefix: 'export const assets = {\n',
  suffix: '};\n\nexport type AssetIds = keyof typeof assets;'
});
