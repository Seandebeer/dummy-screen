import { base44 } from "@/api/base44Client";

const KEY = "takeover-device-id";
const NAME_KEY = "takeover-device-name";

const link = (id) => { try { localStorage.setItem(KEY, id); } catch {} };

export const getLinkedDeviceId = () => {
  try { return localStorage.getItem(KEY) || null; } catch { return null; }
};

const fallbackName = () => {
  try { return localStorage.getItem(NAME_KEY) || "Prop phone"; } catch { return "Prop phone"; }
};

// keep this screen's device record online; create one when asked (QR connect)
export async function ensureDeviceOnline(createIfNeeded) {
  const id = getLinkedDeviceId();
  if (id) {
    try {
      await base44.entities.Device.update(id, { status: "online" });
      return id;
    } catch {} // device was deleted - recreate if allowed
  }
  if (!createIfNeeded) return null;
  try {
    const rec = await base44.entities.Device.create({ name: fallbackName(), kind: "phone", status: "online" });
    link(rec.id);
    return rec.id;
  } catch {
    return null;
  }
}

// save this screen's OS layout onto its device record (a character's device)
export async function saveDevice(name, slimmedConfig) {
  const payload = { name, kind: "phone", status: "online", config: JSON.stringify(slimmedConfig) };
  const id = getLinkedDeviceId();
  if (id) {
    try {
      await base44.entities.Device.update(id, payload);
      return id;
    } catch {} // device was deleted - recreate below
  }
  try {
    const rec = await base44.entities.Device.create(payload);
    link(rec.id);
    return rec.id;
  } catch {
    return null;
  }
}