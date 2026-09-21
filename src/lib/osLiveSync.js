// Live device sync: when a layout is saved onto a device record from any
// screen, every OS screen showing that device applies it immediately.

// the config JSON this screen last pushed - its own saves shouldn't come
// back as "remote" updates and overwrite newer local edits
let lastPushed = null;
export const markOsPushed = (json) => { lastPushed = json; };
export const isOsPushedHere = (json) => Boolean(json) && json === lastPushed;

// apply a config arriving from the device record: side-loaded app data
// lands in its storage keys, the rest merges into the OS state
export function applyLiveOsConfig(json, applyRemote) {
  const { _notes, _calendar, _emails, ...rest } = JSON.parse(json);
  if (_notes) { try { localStorage.setItem("takeover-os-notes", JSON.stringify(_notes)); } catch {} }
  if (_calendar) { try { localStorage.setItem("takeover-os-calendar", JSON.stringify(_calendar)); } catch {} }
  if (_emails) { try { localStorage.setItem("takeover-os-emails", JSON.stringify(_emails)); } catch {} }
  applyRemote(rest);
}