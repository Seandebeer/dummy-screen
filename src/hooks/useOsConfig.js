import { useState, useEffect } from "react";
import { allApps } from "@/lib/osApps";
import { makeDefaultContacts } from "@/lib/osData";

const STORAGE_KEY = "takeover-os-config";

export const bgPresets = [
  { id: "default", name: "Default", dark: "linear-gradient(160deg, #1a1d2e 0%, #0a0b14 60%, #000000 100%)", light: "linear-gradient(160deg, #dfe3f0 0%, #eef1f8 60%, #ffffff 100%)" },
  { id: "midnight", name: "Midnight", dark: "linear-gradient(160deg, #0b1030 0%, #1a1040 55%, #02030a 100%)", light: "linear-gradient(160deg, #c9d4ff 0%, #e4e9ff 55%, #ffffff 100%)" },
  { id: "sunset", name: "Sunset", dark: "linear-gradient(160deg, #2b1a3d 0%, #6b2c56 55%, #14090f 100%)", light: "linear-gradient(160deg, #ffd9a0 0%, #ffb1c9 55%, #fff5ea 100%)" },
  { id: "mono", name: "Mono", dark: "#0a0a0a", light: "#f2f2f7" },
];

const defaults = {
  order: allApps.map((a) => a.id),
  dock: ["phone", "messages", "email", "settings"],
  uiMarkers: { assignments: {}, barRow: 4 },
  dialCodes: ["026", "034", "049"],
  dialCode: "026",
  contacts: makeDefaultContacts(["026", "034", "049"], "en"),
  language: "en",
  contactsLang: "en",
  contactsVer: 2,
  callLog: [],
  theme: "dark",
  clock: { mode: "live", time: "", date: "" },
  background: { type: "preset", preset: "default", url: "" },
  status: { battery: 75, signal: 4, wifi: 3 },
  passcode: "",
  pattern: "",
  lockscreen: { type: "none", background: { type: "preset", preset: "default", url: "" } },
  lockVer: 2,
};

function loadConfig() {
  try {
    const saved = JSON.parse(localStorage.getItem(STORAGE_KEY));
    if (saved && Array.isArray(saved.order)) {
      const known = allApps.map((a) => a.id);
      const order = saved.order.filter((id) => known.includes(id));
      known.forEach((id) => { if (!order.includes(id)) order.push(id); });
      const dock = Array.isArray(saved.dock)
        ? saved.dock.filter((id) => known.includes(id)).slice(0, 4)
        : [...defaults.dock];
      const dialCodes = Array.isArray(saved.dialCodes) && saved.dialCodes.length
        ? saved.dialCodes.filter((c) => /^\d{3}$/.test(c)).slice(0, 3)
        : defaults.dialCodes;
      const language = saved.language || "en";
      let contacts = saved.contacts || defaults.contacts;
      // (re)generate the 100 localized defaults when the language changed or on legacy data
      if (saved.contactsVer !== 2 || saved.contactsLang !== language) {
        contacts = [...makeDefaultContacts(dialCodes, language), ...contacts.filter((c) => c.custom)];
      }
      const lockscreen = saved.lockVer === 2
        ? (saved.lockscreen || defaults.lockscreen)
        : { ...(saved.lockscreen || defaults.lockscreen), type: "none" };
      return { ...defaults, ...saved, order, dock, lockVer: 2, lockscreen, uiMarkers: { ...defaults.uiMarkers, ...(saved.uiMarkers || {}) }, dialCodes, dialCode: dialCodes[0], language, contactsLang: language, contactsVer: 2, contacts };
    }
  } catch {}
  return defaults;
}

export default function useOsConfig() {
  const [config, setConfig] = useState(loadConfig);

  useEffect(() => {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(config));
  }, [config]);

  const update = (patch) => setConfig((c) =>
    typeof patch === "function" ? { ...c, ...patch(c) } : { ...c, ...patch }
  );
  return { config, update };
}