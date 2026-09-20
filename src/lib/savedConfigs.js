import { enqueueSavedUpsert, enqueueSavedDelete, queueKeys, pendingDeleteKeys } from "@/lib/cloudSync";

const KEY = "takeover-saved-configs";

// the Saved card - backed by the shared cloud library, with the local list
// kept as the working copy so everything still works with no signal

export const listSaved = () => {
  try {
    return JSON.parse(localStorage.getItem(KEY)) || [];
  } catch {
    return [];
  }
};

const writeList = (list) => {
  try { localStorage.setItem(KEY, JSON.stringify(list)); } catch {}
};

export const saveConfig = (entry) => {
  const item = { ...entry, id: `s-${Date.now()}-${Math.random().toString(36).slice(2, 6)}`, updated_at: Date.now() };
  writeList([item, ...listSaved()]);
  enqueueSavedUpsert(item);
  return listSaved();
};

export const deleteConfig = (id) => {
  writeList(listSaved().filter((s) => s.id !== id));
  enqueueSavedDelete(id);
  return listSaved();
};

// merge the team's cloud library into this screen's local list - the most
// recent change wins; items deleted here stay hidden until the deletion
// syncs; local items the cloud has never seen are pushed up (first sign-in
// migration), so nothing already set up is lost
export function mergeCloudEntries(entries) {
  const byId = new Map();
  for (const e of entries) byId.set(e.id, e);
  const tombstones = pendingDeleteKeys();
  for (const local of listSaved()) {
    if (tombstones.has(local.id)) { byId.delete(local.id); continue; }
    const cloud = byId.get(local.id);
    if (!cloud || (local.updated_at || 0) > (cloud.updated_at || 0)) byId.set(local.id, local);
  }
  const merged = [...byId.values()].sort((a, b) => (b.updated_at || 0) - (a.updated_at || 0));
  writeList(merged);
  const queued = new Set(queueKeys());
  const cloudIds = new Set(entries.map((e) => e.id));
  for (const item of merged) {
    if (!cloudIds.has(item.id) && !queued.has(item.id)) enqueueSavedUpsert(item);
  }
  return listSaved();
}