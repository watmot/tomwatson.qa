import {StoryblokStory} from 'storyblok-generate-ts'

export interface RichtextStoryblok {
  type: string;
  content?: RichtextStoryblok[];
  marks?: RichtextStoryblok[];
  attrs?: any;
  text?: string;
  [k: string]: any;
}

export interface ContactStoryblok {
  heading?: string;
  body?: RichtextStoryblok;
  _uid: string;
  component: "contact";
  [k: string]: any;
}

export type MultilinkStoryblok =
  | {
      id?: string;
      cached_url?: string;
      anchor?: string;
      linktype?: "story";
      target?: "_self" | "_blank";
      story?: {
        name: string;
        created_at?: string;
        published_at?: string;
        id: number;
        uuid: string;
        content?: {
          [k: string]: any;
        };
        slug: string;
        full_slug: string;
        sort_by_date?: null | string;
        position?: number;
        tag_list?: string[];
        is_startpage?: boolean;
        parent_id?: null | number;
        meta_data?: null | {
          [k: string]: any;
        };
        group_id?: string;
        first_published_at?: string;
        release_id?: null | number;
        lang?: string;
        path?: null | string;
        alternates?: any[];
        default_full_slug?: null | string;
        translated_slugs?: null | any[];
        [k: string]: any;
      };
      [k: string]: any;
    }
  | {
      url?: string;
      cached_url?: string;
      anchor?: string;
      linktype?: "asset" | "url";
      target?: "_self" | "_blank";
      [k: string]: any;
    }
  | {
      email?: string;
      linktype?: "email";
      target?: "_self" | "_blank";
      [k: string]: any;
    };

export interface CookieBannerStoryblok {
  body?: string;
  cta_accept?: string;
  cta_policy?: Exclude<MultilinkStoryblok, {linktype?: "email"} | {linktype?: "asset"}>;
  _uid: string;
  component: "cookie_banner";
  [k: string]: any;
}

export interface ExternalLinkStoryblok {
  heading?: string;
  link?: Exclude<MultilinkStoryblok, {linktype?: "email"} | {linktype?: "asset"}>;
  _uid: string;
  component: "external_link";
  [k: string]: any;
}

export interface AssetStoryblok {
  _uid?: string;
  id: number;
  alt?: string;
  name: string;
  focus?: string;
  source?: string;
  title?: string;
  filename: string;
  copyright?: string;
  fieldtype?: string;
  meta_data?: null | {
    [k: string]: any;
  };
  is_external_url?: boolean;
  [k: string]: any;
}

export interface FloatingImageStoryblok {
  alt_text?: string;
  image?: AssetStoryblok;
  _uid: string;
  component: "floating_image";
  [k: string]: any;
}

export interface IntroStoryblok {
  image?: AssetStoryblok;
  heading?: string;
  cta?: string;
  _uid: string;
  component: "intro";
  [k: string]: any;
}

export interface LandingStoryblok {
  heading1?: string;
  heading2?: string;
  cta?: string;
  _uid: string;
  component: "landing";
  [k: string]: any;
}

export interface MenuStoryblok {
  menu_items?: (
    | ContactStoryblok
    | CookieBannerStoryblok
    | ExternalLinkStoryblok
    | FloatingImageStoryblok
    | IntroStoryblok
    | LandingStoryblok
    | MenuStoryblok
    | MetadataStoryblok
    | NoJavascriptStoryblok
    | NotFoundStoryblok
    | PolicyLinkStoryblok
    | PolicyPageStoryblok
    | ProjectStoryblok
    | RotateDeviceStoryblok
    | ServiceStoryblok
    | ServicesStoryblok
    | UnsupportedBrowserStoryblok
    | WindowTooSmallStoryblok
    | WorkStoryblok
  )[];
  socials?: (
    | ContactStoryblok
    | CookieBannerStoryblok
    | ExternalLinkStoryblok
    | FloatingImageStoryblok
    | IntroStoryblok
    | LandingStoryblok
    | MenuStoryblok
    | MetadataStoryblok
    | NoJavascriptStoryblok
    | NotFoundStoryblok
    | PolicyLinkStoryblok
    | PolicyPageStoryblok
    | ProjectStoryblok
    | RotateDeviceStoryblok
    | ServiceStoryblok
    | ServicesStoryblok
    | UnsupportedBrowserStoryblok
    | WindowTooSmallStoryblok
    | WorkStoryblok
  )[];
  policies?: (
    | ContactStoryblok
    | CookieBannerStoryblok
    | ExternalLinkStoryblok
    | FloatingImageStoryblok
    | IntroStoryblok
    | LandingStoryblok
    | MenuStoryblok
    | MetadataStoryblok
    | NoJavascriptStoryblok
    | NotFoundStoryblok
    | PolicyLinkStoryblok
    | PolicyPageStoryblok
    | ProjectStoryblok
    | RotateDeviceStoryblok
    | ServiceStoryblok
    | ServicesStoryblok
    | UnsupportedBrowserStoryblok
    | WindowTooSmallStoryblok
    | WorkStoryblok
  )[];
  legal_copyright?: string;
  _uid: string;
  component: "menu";
  [k: string]: any;
}

export interface MetadataStoryblok {
  title?: string;
  description?: string;
  image?: AssetStoryblok;
  _uid: string;
  component: "metadata";
  [k: string]: any;
}

export interface NoJavascriptStoryblok {
  heading?: string;
  _uid: string;
  component: "no_javascript";
  [k: string]: any;
}

export interface NotFoundStoryblok {
  heading?: string;
  _uid: string;
  component: "not_found";
  [k: string]: any;
}

export interface PolicyLinkStoryblok {
  link?: Exclude<MultilinkStoryblok, {linktype?: "email"} | {linktype?: "asset"}>;
  _uid: string;
  component: "policy_link";
  [k: string]: any;
}

export interface PolicyPageStoryblok {
  heading?: string;
  body?: RichtextStoryblok;
  _uid: string;
  component: "policy_page";
  [k: string]: any;
}

export interface ProjectStoryblok {
  heading?: string;
  image?: AssetStoryblok;
  link?: Exclude<MultilinkStoryblok, {linktype?: "email"} | {linktype?: "asset"}>;
  topic?: ("" | "web" | "app" | "experiential" | "spatial")[];
  _uid: string;
  component: "project";
  [k: string]: any;
}

export interface RotateDeviceStoryblok {
  heading?: string;
  _uid: string;
  component: "rotate_device";
  [k: string]: any;
}

export interface ServiceStoryblok {
  heading?: string;
  _uid: string;
  component: "service";
  [k: string]: any;
}

export interface ServicesStoryblok {
  heading?: string;
  body?: string;
  services?: ServiceStoryblok[];
  _uid: string;
  component: "services";
  [k: string]: any;
}

export interface UnsupportedBrowserStoryblok {
  heading?: string;
  _uid: string;
  component: "unsupported_browser";
  [k: string]: any;
}

export interface WindowTooSmallStoryblok {
  heading?: string;
  _uid: string;
  component: "window_too_small";
  [k: string]: any;
}

export interface WorkStoryblok {
  heading?: string;
  projects?: ProjectStoryblok[];
  cta?: string;
  _uid: string;
  component: "work";
  [k: string]: any;
}
