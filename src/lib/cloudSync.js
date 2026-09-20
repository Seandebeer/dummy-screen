import { base44 } from "@/api/base44Client";
import { getLinkedDeviceId } from "@/lib/deviceLink";
import { readCurrentOsConfig, slimConfig } from "@/lib/osConfigStore";

// Cloud sync for the shared on-set library. Everything keeps working from
// the screen's local storage; changes are queued and pushed to the cloud
// (saved items + this screen's device state), pulling the team's latest on
// reconnect. Most recent change wins on conflicts.

const QUEUE_KEY = "takeover-sync-queue";

// fired whenever the queue or connection state changes; detail.entries
// carries freshly pulled cloud records when there are any
export const SYNC_EVENT = "takeover-sync-changed";

const readQueue = () => {
  try { return JSON.parse(localStorage.getItem(QUEUE_KEY)) || []; } catch { return []; }
};

const emit = (entries) => {
  try { window.dispatchEvent(new CustomEvent(SYNC_EVENT, { detail: { entries } })); } catch {}
};

const writeQueue = (q) => {
  try { localStorage.setItem(QUEUE_KEY, JSON.stringify(q)); } catch {}
  emit();
};

const enqueue = (op) => {
  op.opId = `${Date.now()}-${Math.random().toString(36).slice(2, 8)}`;
  let q = readQueue();
  if (op.key) q = q.filter((o) => !(o.type === op.type && o.key === op.key));
  q.push(op);
  writeQueue(q);
};

export const queueKeys = () => readQueue().map((o) => o.key).filter(Boolean);
export const pendingDeleteKeys = () =>
  new Set(readQueue().filter((o) => o.type === "saved_delete").map((o) => o.key));

export function syncStatus() {
  if (typeof navigator !== "undefined" && !navigator.onLine) return "offline";
  return readQueue().length ? "queued" : "synced";
}

// --- saved library items (the Saved card on Home) ---

export function enqueueSavedUpsert(entry) {
  ensureInit();
  enqueue({
    type: "saved_upsert",
    key: entry.id,
    payload: JSON.stringify(entry),
    updated_at: entry.updated_at || Date.now(),
  });
  flush();
}

export function enqueueSavedDelete(key) {
  ensureInit();
  enqueue({ type: "saved_delete", key });
  flush();
}

// fetch the team's cloud library - parsed entry payloads, or null offline
export async function pullSaved() {
  ensureInit();
  let records;
  try {
    records = await base44.entities.SavedItem.list("-created_date", 200);
  } catch {
    return null;
  }
  const entries = [];
  for (const r of records) {
    try { entries.push(JSON.parse(r.payload)); } catch {}
  }
  return entries;
}

// drain the queue, then pull the shared library
export async function syncNow() {
  await flush();
  const entries = await pullSaved();
  if (entries) emit(entries);
  return entries;
}

// --- this screen's device state (OS layout, notes, calendar) ---

let deviceTimer = null;

// schedule a debounced push of this screen's current device state
export function scheduleDeviceSync() {
  ensureInit();
  clearTimeout(deviceTimer);
  deviceTimer = setTimeout(() => {
    const cfg = readCurrentOsConfig();
    if (!cfg) return;
    let notes = null;
    let calendar = null;
    try { notes = JSON.parse(localStorage.getItem("takeover-os-notes")) || null; } catch {}
    try { calendar = JSON.parse(localStorage.getItem("takeover-os-calendar")) || null; } catch {}
    enqueue({
      type: "device_config",
      payload: JSON.stringify({ ...slimConfig(cfg), _notes: notes, _calendar: calendar }),
    });
    flush();
  }, 2500);
}

// drop any queued device state (factory reset - a fresh one syncs right after)
export function clearDeviceSync() {
  writeQueue(readQueue().filter((o) => o.type !== "device_config"));
}

async function pushDeviceConfig(configJson) {
  const fields = { config: configJson, status: "online" };
  const id = getLinkedDeviceId();
  // no linked device - this screen is a sandbox until its first save; the
  // OS layout stays local and nothing is pushed
  if (!id) return;
  try {
    await base44.entities.Device.update(id, fields);
  } catch {
    // the device still exists - transient failure, retry later; if it was
    // deleted this screen is a sandbox again, so drop the sync silently
    try { await base44.entities.Device.get(id); } catch { return; }
    throw new Error("device sync failed");
  }
}

// --- queue engine ---

let flushing = false;
let inited = false;

async function runOp(op) {
  if (op.type === "saved_upsert") {
    const entry = JSON.parse(op.payload);
    const fields = {
      name: entry.name || "Saved item",
      kind: entry.kind || "page",
      app: entry.app || "",
      category: entry.category || "",
      item_key: op.key,
      payload: op.payload,
      updated_at: op.updated_at,
    };
    const existing = await base44.entities.SavedItem.filter({ item_key: op.key }, "-created_date", 1);
    if (existing.length) await base44.entities.SavedItem.update(existing[0].id, fields);
    else await base44.entities.SavedItem.create(fields);
  } else if (op.type === "saved_delete") {
    await base44.entities.SavedItem.deleteMany({ item_key: op.key });
  } else if (op.type === "device_config") {
    await pushDeviceConfig(op.payload);
  }
}

export async function flush() {
  ensureInit();
  if (flushing || (typeof navigator !== "undefined" && !navigator.onLine)) return;
  flushing = true;
  try {
    while (true) {
      const q = readQueue();
      if (!q.length) break;
      const op = q[0];
      try {
        await runOp(op);
      } catch {
        break; // connection dropped - the op stays queued for the next attempt
      }
      writeQueue(readQueue().filter((o) => o.opId !== op.opId));
    }
  } finally {
    flushing = false;
  }
}

function ensureInit() {
  if (inited || typeof window === "undefined") return;
  inited = true;
  window.addEventListener("online", () => { syncNow(); });
  window.addEventListener("offline", () => emit());
  flush();
}