import { saveConfig } from "./savedConfigs";

const OS_KEY = "takeover-os-config";

const CATEGORIES = {
  facepage: "Socials",
  photogram: "Socials",
  vidtube: "Socials",
  quicktok: "Socials",
  webdeck: "Websites",
};

export const categoryOf = (app) => CATEGORIES[app] || "Pages";

// save an edited page (social app content or a Webdeck site) into the
// Home saved card, asking the user for a display name
export const saveWithPrompt = (app, defaultName, data) => {
  const name = window.prompt("Save to Home as:", defaultName);
  if (!name || !name.trim()) return null;
  const entry = { kind: "page", app, category: categoryOf(app), name: name.trim(), data };
  saveConfig(entry);
  return entry;
};

// apply a saved page snapshot back onto this screen's OS config
export const applyPage = (entry) => {
  try {
    const cfg = JSON.parse(localStorage.getItem(OS_KEY)) || {};
    if (entry.app === "webdeck") {
      const sites = (cfg.webdeck || {}).sites || [];
      const exists = sites.some((x) => x.id === entry.data?.id);
      cfg.webdeck = {
        ...(cfg.webdeck || {}),
        sites: exists
          ? sites.map((x) => (x.id === entry.data.id ? entry.data : x))
          : [...sites, entry.data],
      };
    } else {
      cfg.socials = { ...(cfg.socials || {}), [entry.app]: entry.data };
    }
    localStorage.setItem(OS_KEY, JSON.stringify(cfg));
    return true;
  } catch {
    return false;
  }
};