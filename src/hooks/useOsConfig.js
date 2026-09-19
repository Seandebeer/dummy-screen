import { useState, useEffect } from "react";
import { allApps } from "@/lib/osApps";

const STORAGE_KEY = "takeover-os-config";

export const bgPresets = [
  { id: "default", name: "Default", dark: "linear-gradient(160deg, #1a1d2e 0%, #0a0b14 60%, #000000 100%)", light: "linear-gradient(160deg, #dfe3f0 0%, #eef1f8 60%, #ffffff 100%)" },
  { id: "midnight", name: "Midnight", dark: "linear-gradient(160deg, #0b1030 0%, #1a1040 55%, #02030a 100%)", light: "linear-gradient(160deg, #c9d4ff 0%, #e4e9ff 55%, #ffffff 100%)" },
  { id: "sunset", name: "Sunset", dark: "linear-gradient(160deg, #2b1a3d 0%, #6b2c56 55%, #14090f 100%)", light: "linear-gradient(160deg, #ffd9a0 0%, #ffb1c9 55%, #fff5ea 100%)" },
  { id: "mono", name: "Mono", dark: "#0a0a0a", light: "#f2f2f7" },
];

const defaults = {
  order: allApps.map((a) => a.id),
  theme: "dark",
  clock: { mode: "live", time: "", date: "" },
  background: { type: "preset", preset: "default", url: "" },
  status: { battery: 75, signal: 4, wifi: 3 },
  passcode: "",
  pattern: "",
  lockscreen: { type: "passcode", background: { type: "preset", preset: "default", url: "" } },
};

function loadConfig() {
  try {
    const saved = JSON.parse(localStorage.getItem(STORAGE_KEY));
    if (saved && Array.isArray(saved.order)) {
      const known = allApps.map((a) => a.id);
      const order = saved.order.filter((id) => known.includes(id));
      known.forEach((id) => { if (!order.includes(id)) order.push(id); });
      return { ...defaults, ...saved, order };
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