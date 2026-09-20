import { base44 } from "@/api/base44Client";

const KEY = "takeover-device-id";
const NAME_KEY = "takeover-device-name";

// fired whenever the linked device (or its name) changes, so badges
// across the app can refresh without a reload
export const DEVICE_EVENT = "takeover-device-changed";

const link = (id) => { try { localStorage.setItem(KEY, id); } catch {} };

// adopt a device whose layout was just loaded - later saves from this
// screen then update that device's record instead of creating a new one
export const linkDevice = (id, name) => {
  link(id);
  if (name) { try { localStorage.setItem(NAME_KEY, name); } catch {} }
  try { window.dispatchEvent(new Event(DEVICE_EVENT)); } catch {}
};

export const getLinkedDeviceId = () => {
  try { return localStorage.getItem(KEY) || null; } catch { return null; }
};

const fallbackName = () => {
  try { return localStorage.getItem(NAME_KEY) || "Sandbox"; } catch { return "Sandbox"; }
};

// this screen's device name - shown in the OS header. With no device
// loaded yet this screen is just a sandbox.
export const getDeviceName = () => (getLinkedDeviceId() ? fallbackName() : "Sandbox");

// keep this screen's device record online. Until the first save this screen
// is just a sandbox - no device record is ever created here.
export async function ensureDeviceOnline() {
  const id = getLinkedDeviceId();
  if (!id) return null;
  try {
    await base44.entities.Device.update(id, { status: "online" });
    return id;
  } catch {
    return null; // device was deleted - this screen is a sandbox again
  }
}

// save this screen's OS layout onto its device record (a character's device)
export async function saveDevice(name, slimmedConfig) {
  const payload = { name, kind: "phone", status: "online", config: JSON.stringify(slimmedConfig) };
  const id = getLinkedDeviceId();
  if (id) {
    try {
      await base44.entities.Device.update(id, payload);
      linkDevice(id, name);
      return id;
    } catch {} // device was deleted - recreate below
  }
  try {
    const rec = await base44.entities.Device.create(payload);
    linkDevice(rec.id, name);
    return rec.id;
  } catch {
    return null;
  }
}

// a random id unique to THIS browser screen - commands and messages carry it
// so a screen never reacts to triggers pushed from its own control deck
const SCREEN_KEY = "takeover-screen-id";
export const getScreenId = () => {
  try {
    let id = localStorage.getItem(SCREEN_KEY);
    if (!id) {
      id = `s-${Date.now().toString(36)}-${Math.random().toString(36).slice(2, 8)}`;
      localStorage.setItem(SCREEN_KEY, id);
    }
    return id;
  } catch { return "s-local"; }
};