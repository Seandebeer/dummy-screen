import { base44 } from "@/api/base44Client";
import { getLinkedDeviceId } from "@/lib/deviceLink";

// localStorage keys holding this mock device's own data
const KEYS = [
  "takeover-os-config",   // OS layout, app pages, settings, configurations
  "takeover-os-notes",
  "takeover-os-calendar",
  "takeover-os-photos",
];

// IndexedDB databases holding device media (music tracks, camera clips)
const DBS = ["propsync-music", "propsync-camroll"];

// Factory reset: wipe this screen's mock device back to out-of-the-box -
// pages, apps, settings, configurations and locally stored app data.
// Items saved to the general Saved card on Home are untouched, but pages
// saved to the linked character's device are cleared from that record.
export async function factoryReset() {
  for (const k of KEYS) {
    try { localStorage.removeItem(k); } catch {}
  }
  for (const name of DBS) {
    try { indexedDB.deleteDatabase(name); } catch {}
  }
  const id = getLinkedDeviceId();
  if (id) {
    try { await base44.entities.Device.update(id, { config: "" }); } catch {}
  }
}