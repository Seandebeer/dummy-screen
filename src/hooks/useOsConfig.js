import { useState, useEffect } from "react";
import { allApps, coreApps, defaultHomeOrder } from "@/lib/osApps";
import { makeDefaultContacts } from "@/lib/osData";

const STORAGE_KEY = "takeover-os-config";

export const bgPresets = [
  { id: "default", name: "Default", dark: "linear-gradient(160deg, #1a1d2e 0%, #0a0b14 60%, #000000 100%)", light: "linear-gradient(160deg, #dfe3f0 0%, #eef1f8 60%, #ffffff 100%)" },
  { id: "midnight", name: "Midnight", dark: "linear-gradient(160deg, #0b1030 0%, #1a1040 55%, #02030a 100%)", light: "linear-gradient(160deg, #c9d4ff 0%, #e4e9ff 55%, #ffffff 100%)" },
  { id: "sunset", name: "Sunset", dark: "linear-gradient(160deg, #2b1a3d 0%, #6b2c56 55%, #14090f 100%)", light: "linear-gradient(160deg, #ffd9a0 0%, #ffb1c9 55%, #fff5ea 100%)" },
  { id: "mono", name: "Mono", dark: "#0a0a0a", light: "#f2f2f7" },
  { id: "aqua", name: "Aqua", dark: "repeating-linear-gradient(90deg, rgba(255,255,255,0.06) 0 3px, transparent 3px 7px), linear-gradient(180deg, #2f5c94 0%, #1d3a63 60%, #0e1c30 100%)", light: "repeating-linear-gradient(90deg, rgba(255,255,255,0.5) 0 2px, transparent 2px 5px), linear-gradient(180deg, #cfe0f5 0%, #eaf2fc 60%, #ffffff 100%)" },
  { id: "droid", name: "Tint", dark: "linear-gradient(160deg, #101418 0%, #14202a 55%, #0a0e12 100%)", light: "linear-gradient(160deg, #d3e4f5 0%, #cfe8d8 55%, #f4f7fa 100%)" },
];

const defaults = {
  order: [...defaultHomeOrder],
  orderVer: 2,
  dock: ["phone", "messages", "email", "settings"],
  dockVer: 2,
  uiMarkers: { assignments: {}, barRow: 7, barCol: 5, barVRow: 2, layoutVer: 3 },
  osMarks: { style: "none", layouts: {} },
  osMarksVer: 1,
  dialCodes: ["026", "034", "049"],
  dialCode: "026",
  contacts: makeDefaultContacts(["026", "034", "049"], "en"),
  language: "en",
  contactsLang: "en",
  contactsVer: 2,
  callLog: [],
  theme: "dark",
  skin: "modern",
  callAnswer: "tap",
  clock: { mode: "live", time: "", date: "" },
  background: { type: "preset", preset: "default", url: "" },
  status: { battery: 75, signal: 4, wifi: 3 },
  passcode: "",
  pattern: "",
  lockscreen: { type: "none", background: { type: "preset", preset: "default", url: "" } },
  lockVer: 2,
  badges: { messages: 0, mail: 0, phone: 0 },
  notifications: [],
};

function loadConfig() {
  try {
    const saved = JSON.parse(localStorage.getItem(STORAGE_KEY));
    if (saved && Array.isArray(saved.order)) {
      const known = allApps.map((a) => a.id);
      // gather the functional apps on the first page (once) - everything
      // else gets added from the App Library
      // core apps added after a layout was saved (e.g. Music) land on page 1
      const order = saved.orderVer === 2
        ? [
          ...coreApps.filter((a) => !saved.order.includes(a.id)).map((a) => a.id),
          ...saved.order.filter((id) => known.includes(id)),
        ]
        : [...defaultHomeOrder];
      let dock = Array.isArray(saved.dock)
        ? saved.dock.filter((id) => known.includes(id)).slice(0, 4)
        : [...defaults.dock];
      // one-time refresh: the Videos app moved out of the OS dock
      if ((saved.dockVer || 0) < 2) dock = [...defaults.dock];
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
      const osMarks = { ...defaults.osMarks, ...(saved.osMarks || {}) };
      // one-time reset: OS tracking marks start as "None" for existing devices
      if ((saved.osMarksVer || 0) < 1) osMarks.style = "none";
      const uiMarkers = { ...defaults.uiMarkers, ...(saved.uiMarkers || {}) };
      // one-time reset: tracking marks start as "None" for existing devices
      if ((saved.uiMarkers || {}).markStyleVer !== 1) {
        uiMarkers.markStyle = "none";
        uiMarkers.markStyleVer = 1;
      }
      if ((uiMarkers.layoutVer || 0) < 3) {
        uiMarkers.barRow = defaults.uiMarkers.barRow;
        uiMarkers.barCol = defaults.uiMarkers.barCol;
        uiMarkers.barVRow = defaults.uiMarkers.barVRow;
        uiMarkers.layoutVer = 3;
      }
      return { ...defaults, ...saved, order, orderVer: 2, dock, dockVer: 2, lockVer: 2, lockscreen, uiMarkers, osMarks, osMarksVer: 1, badges: { ...defaults.badges, ...(saved.badges || {}) }, notifications: Array.isArray(saved.notifications) ? saved.notifications : [], dialCodes, dialCode: dialCodes[0], language, contactsLang: language, contactsVer: 2, contacts };
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