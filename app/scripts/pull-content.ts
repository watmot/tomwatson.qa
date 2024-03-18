import 'dotenv/config';

import { apiPlugin, storyblokInit } from '@storyblok/js';

import { setTimeout } from 'timers/promises';
import { writeFileSync } from 'fs';

const { storyblokApi } = storyblokInit({
  accessToken: process.env.STORYBLOK_TOKEN,
  use: [apiPlugin]
});

const name = 'scripts/pull-content';
let requestTimeout = 0;

const getAssetUrls = () => {};

const fetchContent = async () => {
  console.log(`[${name}] Fetching data from Storyblok...\n`);
  try {
    const content = await storyblokApi?.get('cdn/stories');
    if (!content) throw new Error(`[${name}] The response from the CDN is empty.`);
    const json = JSON.stringify(content.data.stories);
    const path = './.data/storyblok-content.json';
    writeFileSync(path, json, 'utf8');
    console.log(`[${name}] Storyblok data fetch succeeded. Data written to ${path}`);
  } catch (err) {
    if (requestTimeout < 120) {
      requestTimeout += 10;
      console.error(`[${name}] Storyblok data fetch failed!`);
      console.error(err);
      console.log(`\n[${name}] Retrying in ${requestTimeout} seconds...\n`);
      await setTimeout(requestTimeout * 1000);
      fetchContent();
    } else {
      throw new Error(`[${name}] FATAL! Storyblok data fetch failed!`);
    }
  }
};

fetchContent();
