import 'dotenv/config';

import {
  ContactStoryblok,
  IntroStoryblok,
  LandingStoryblok,
  MenuStoryblok,
  NoJavascriptStoryblok,
  NotFoundStoryblok,
  ServicesStoryblok,
  WorkStoryblok
} from 'types/storyblok';
import { apiPlugin, storyblokInit } from '@storyblok/js';

import { StoryblokStory } from 'storyblok-generate-ts';
import { flatten } from 'flat';
import fs from 'fs';
import path from 'path';

const name = 'scripts/fetch-storyblok-content';

type StoryContent =
  | LandingStoryblok
  | IntroStoryblok
  | WorkStoryblok
  | ServicesStoryblok
  | ContactStoryblok
  | MenuStoryblok
  | NoJavascriptStoryblok
  | NotFoundStoryblok;

interface ParsedStory {
  uuid: string;
  name: string;
  slug: string;
  full_slug: string;
  content: StoryContent;
}

interface ParsedContent {
  [key: string]: ParsedStory;
}

const parseContent = (stories: StoryblokStory<StoryContent>[]) => {
  return stories.reduce<ParsedContent>((acc, story) => {
    const { uuid, name, slug, full_slug, content } = story;
    acc[full_slug] = { uuid, name, slug, full_slug, content };
    return acc;
  }, {} as ParsedContent);
};

const getAssetBinaries = (content: ParsedContent) => {
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
  content: string[] | ParsedContent;
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
