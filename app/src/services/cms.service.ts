import content from '@/data/storyblok-content.json';

const mappedContent = {
  pages: {
    home: {
      landing: content['pages/home/landing'],
      intro: content['pages/home/intro'],
      work: content['pages/home/work'],
      services: content['pages/home/services'],
      contact: content['pages/home/contact']
    },
    notFound: content['pages/not-found'],
    privacyPolicy: content['pages/privacy-policy'],
    cookiesPolicy: content['pages/cookies-policy'],
    termsAndConditions: content['pages/terms-and-conditions']
  },
  common: {
    cookieBanner: content['common/cookie-banner'],
    menu: content['common/menu'],
    noJavascript: content['common/no-javascript'],
    unsupportedBrowser: content['common/unsupported-browser'],
    rotateDevice: content['common/rotate-device'],
    metadata: content['common/metadata']
  }
};

type PageId = keyof typeof mappedContent.pages;

class Service {
  getPageContent(pageId: PageId) {
    const page = mappedContent.pages[pageId];
    const common = mappedContent.common;

    return { page, common };
  }
}

export const CMS = new Service();
