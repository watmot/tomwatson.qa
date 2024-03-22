import 'dotenv/config';

import { ISbStoryData, apiPlugin, storyblokInit } from '@storyblok/js';

import { flatten } from 'flat';
import fs from 'fs';
import path from 'path';

const name = 'scripts/fetch-storyblok-content';

interface SbContent {
  _uid?: string;
  component?: string;
  _editable?: string;
  [key: string]: any;
}

interface ParsedStory {
  uuid: string;
  content: SbContent;
}
interface Content {
  [key: string]: ParsedStory;
}

const parseContent = (stories: ISbStoryData[]) => {
  return stories.reduce<Content>((acc, story) => {
    const { uuid, full_slug, content } = story;
    acc[full_slug] = { uuid, content };
    return acc;
  }, {} as Content);
};

const getAssetBinaries = (content: Content) => {
  const values = Object.values(flatten(content)) as string[];
  const filtered = [
    ...new Set(
      values
        .filter((value) => /.(jpg|png|jpeg|gif|webp|avif|ico|bmp)/i.test(value))
        .map((url) => url.replace('a.storyblok.com', 's3.amazonaws.com/a.storyblok.com'))
    )
  ];

  return filtered;
};

interface WriteJsonFile {
  content: string[] | Content;
  outputDir?: string;
  filename: string;
}

const writeJsonFile = ({ content, outputDir, filename }: WriteJsonFile) => {
  if (!outputDir) outputDir = './.data';

  const json = JSON.stringify(content);
  const filePath = path.join(outputDir, filename);

  fs.writeFileSync(filePath, json, 'utf8');
  return filePath;
};

const fetchStoryblokContent = async () => {
  try {
    console.log(`[${name}] Fetching data from Storyblok...`);
    const { storyblokApi } = storyblokInit({
      accessToken: process.env.STORYBLOK_TOKEN,
      use: [apiPlugin]
    });

    const content = await storyblokApi?.get('cdn/stories');
    if (!content) throw new Error(`The response from the CDN is empty. Check access token.`);

    const { stories } = content.data;

    const parsedContent = parseContent(stories);
    const contentFilePath = writeJsonFile({
      content: parsedContent,
      filename: 'storyblok-content.json'
    });

    console.log(`[${name}] Storyblok content successfully written to ${contentFilePath}`);

    const assetBinaries = getAssetBinaries(stories);
    const assetBinariesFilePath = writeJsonFile({
      content: assetBinaries,
      filename: 'storyblok-asset-binaries.json'
    });
    console.log(
      `[${name}] Storyblok asset binaries successfully written to ${assetBinariesFilePath}`
    );
  } catch (err: any) {
    if (err instanceof Error) {
      console.error(`[${name}] ${err.stack}`);
    } else if (err.status && err.message) {
      if (err.status === 401) console.error(`[${name}] 401 - Unauthorized: Invalid access token.`);
    } else {
      console.error(`[${name}] `, err);
    }
    console.error(`[${name}] FATAL! Storyblok data fetch failed.`);
  }
};

fetchStoryblokContent();
