import { AssetIds, assets } from '@/data/assets';
import { Dispatch, SetStateAction } from 'react';

import axios from 'axios';
import storyblokBinaries from '@/data/storyblok-asset-binaries.json';
import { toTitleCase } from '@/utils/string';

type PreloadedFile = null | string;

class Service {
  manifest: { [key in AssetIds]: string };
  totalFilesToLoad: number;
  totalFilesLoaded: number;
  files: { [key: string]: Promise<PreloadedFile> | PreloadedFile | null };
  onUpdate: Dispatch<SetStateAction<number>>;

  public constructor() {
    this.manifest = { ...assets, ...storyblokBinaries };
    this.totalFilesToLoad = Object.keys(this.manifest).length;
    this.totalFilesLoaded = 0;
    this.files = {};
  }

  private updateProgress() {
    console.log(`Preloaded ${this.totalFilesLoaded}/${this.totalFilesToLoad} files.`);
    const currProgress = Math.min(
      100,
      Math.floor((this.totalFilesLoaded / this.totalFilesToLoad) * 100)
    );
    this.onUpdate(currProgress);
  }

  public load(onUpdate: Dispatch<SetStateAction<number>>) {
    this.onUpdate = onUpdate;

    const filePaths = Object.keys(this.manifest) as AssetIds[];
    const urlsToLoad = filePaths.reduce((array, path) => {
      const url = this.manifest[path];
      if (url) array.push(url);
      return array;
    }, [] as string[]);

    if (this.totalFilesToLoad > 0) {
      urlsToLoad.forEach(async (url: string) => {
        await this.loadFile(url);
      });
    }
  }

  private loadFile(url: string) {
    if (this.files[url]) return this.files[url];

    const file = new Promise<PreloadedFile>((resolve) => {
      const fontMatch = url.match(/([a-z]+)-*([0-9]*)\..*(woff|woff2)$/i);
      if (fontMatch) {
        const name = toTitleCase(fontMatch[1]);
        const weight = fontMatch[2];
        const font = new FontFace(name, `url(${url})`, { weight });
        font
          .load()
          .then(() => {
            document.fonts.add(font);
            resolve(url);
          })
          .catch((err) => {
            console.error(err);
            resolve(null);
          });
      } else {
        axios
          .get(url, { responseType: 'blob' })
          .then(() => {
            resolve(url);
          })
          .catch((err) => {
            console.error(err);
            resolve(null);
          });
      }
    });

    this.files[url] = file.finally(() => {
      this.totalFilesLoaded++;
      this.updateProgress();
    });
  }
}

export const Preloader = new Service();
