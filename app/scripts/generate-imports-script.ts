import fs from 'fs';
import path from 'path';
export type Paths = string[];

interface getLines {
  src: string;
  dir: string;
  lines?: string;
  prefix?: string;
  suffix?: string;
}

const name = 'scripts/generate-imports-script';

const isImage = (filePath: string) => {
  return /.(jpg|png|jpeg|gif|webp|avif|ico|bmp)/i.test(filePath);
};

const getLines = ({ src, dir, lines = '', prefix = '', suffix = '' }: getLines) => {
  const resolvedSrc = path.resolve(__dirname, src);
  const resolvedDir = path.resolve(resolvedSrc, dir);

  if (!fs.existsSync(resolvedDir)) throw new Error(`${resolvedDir} does not exist!`);

  if (!lines.length && prefix) lines += prefix;

  const dirents = fs.readdirSync(resolvedDir, { withFileTypes: true });
  dirents.forEach((dirent) => {
    if (dirent.isDirectory()) {
      lines = getLines({ src, dir: path.join(dir, dirent.name), lines });
    } else {
      const relativeDir = dirent.path.replace(resolvedSrc, '@');
      const filePath = path.join(relativeDir, dirent.name);
      // const isImage = getTypeCast(filePath);
      lines += `\t'${filePath}': require('${filePath}')${
        isImage(filePath) ? '.default.src' : ''
      } as string,\n`;
    }
  });

  if (suffix) lines += suffix;
  return lines;
};

interface WriteFile {
  filename: string;
  lines: string;
  outputDir?: string;
}

export const writeFile = ({ filename, lines, outputDir }: WriteFile) => {
  if (!outputDir) outputDir = './.data';

  if (!fs.existsSync(outputDir)) fs.mkdirSync(outputDir);

  const filePath = path.join(outputDir, filename);
  fs.writeFileSync(filePath, lines);
  return filePath;
};

interface generateImportsScript {
  src: string;
  dir: string;
  filename: string;
  prefix: string;
  suffix: string;
}

export const generateImportsScript = ({
  src,
  dir,
  filename,
  prefix,
  suffix
}: generateImportsScript) => {
  try {
    console.log(`[${name}] Generating ${dir} import script...`);
    const lines = getLines({ src, dir, prefix, suffix });
    const filePath = writeFile({ filename, lines });
    console.log(
      `[${name}] Import script for the ${dir} directory successfully written to ${filePath}`
    );
  } catch (err) {
    console.error(`[${name}] FATAL! Generation of ${dir} import script failed.`);
    console.error(err);
  }
};

generateImportsScript({
  src: '../src',
  dir: 'assets',
  filename: 'assets.ts',
  prefix: 'export const assets = {\n',
  suffix: '};\n\nexport type AssetIds = keyof typeof assets;'
});
