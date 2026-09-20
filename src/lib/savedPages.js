import { saveConfig } from "./savedConfigs";

const OS_KEY = "takeover-os-config";

const CATEGORIES = {
  facepage: "Socials",
  photogram: "Socials",
  vidtube: "Socials",
  quicktok: "Socials",
  webdeck: "Websites",
  news: "Apps",
  property: "Apps",
};

export const categoryOf = (app) => CATEGORIES[app] || "Pages";

// merge one saved page (social app content, a Webdeck site, a news edition
// or property listings) into an OS config object
export const mergePageIntoConfig = (cfg, app, data) => {
  const next = { ...(cfg || {}) };
  if (app === "webdeck") {
    const sites = (next.webdeck || {}).sites || [];
    const exists = sites.some((x) => x.id === data?.id);
    next.webdeck = {
      ...(next.webdeck || {}),
      sites: exists
        ? sites.map((x) => (x.id === data.id ? data : x))
        : [...sites, data],
    };
  } else if (app === "news" || app === "property") {
    next[app] = data;
  } else {
    next.socials = { ...(next.socials || {}), [app]: data };
  }
  return next;
};

// apply a saved page snapshot back onto this screen's OS config
export const applyPage = (entry) => {
  try {
    const cfg = JSON.parse(localStorage.getItem(OS_KEY)) || {};
    localStorage.setItem(OS_KEY, JSON.stringify(mergePageIntoConfig(cfg, entry.app, entry.data)));
    return true;
  } catch {
    return false;
  }
};