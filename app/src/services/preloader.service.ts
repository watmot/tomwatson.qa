import { AssetIds, assets } from '@/data/assets';
import { Dispatch, SetStateAction } from 'react';

import axios from 'axios';

type PreloadedFile = null | string;

class Service {
  manifest: { [key in AssetIds]: string };
  totalFilesToLoad: number;
  totalFilesLoaded: number;
  files: { [key: string]: Promise<PreloadedFile> | PreloadedFile | null };
  onUpdate: Dispatch<SetStateAction<number>>;

  public constructor() {
    this.manifest = { ...assets };
    this.totalFilesToLoad = Object.keys(this.manifest).length;
    this.totalFilesLoaded = 0;
    this.files = {};
  }

  private updateProgress() {
    console.log(`${this.totalFilesLoaded}/${this.totalFilesToLoad}`);
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
      axios
        .get(url)
        .then(() => {
          resolve(url);
        })
        .catch((err) => {
          console.error(err);
          resolve(null);
        })
        .finally(() => {
          this.totalFilesLoaded++;
          this.updateProgress();
        });
    });

    this.files[url] = file;
  }
}

export const Preloader = new Service();
