// local music storage for the OS Music app - tracks live in IndexedDB on
// this device so playback works offline.
const DB_NAME = "propsync-music";
const STORE = "tracks";
export const MAX_TRACKS = 10;

let dbPromise = null;
function openDb() {
  if (!dbPromise) {
    dbPromise = new Promise((resolve, reject) => {
      const req = indexedDB.open(DB_NAME, 1);
      req.onupgradeneeded = () => req.result.createObjectStore(STORE, { keyPath: "id" });
      req.onsuccess = () => resolve(req.result);
      req.onerror = () => reject(req.error);
    });
  }
  return dbPromise;
}

function tx(mode, fn) {
  return openDb().then((db) => new Promise((resolve, reject) => {
    const t = db.transaction(STORE, mode);
    const req = fn(t.objectStore(STORE));
    t.oncomplete = () => resolve(req && req.result);
    t.onerror = () => reject(t.error);
  }));
}

export const listTracks = async () => {
  const all = await tx("readonly", (s) => s.getAll());
  return (all || []).sort((a, b) => (a.order ?? 0) - (b.order ?? 0) || (a.created || 0) - (b.created || 0));
};
export const getTrack = (id) => tx("readonly", (s) => s.get(id));
export const putTrack = (record) => tx("readwrite", (s) => s.put(record));
export const deleteTrack = (id) => tx("readwrite", (s) => s.delete(id));

export const fmtDur = (t) => {
  if (!isFinite(t) || t < 0) t = 0;
  const m = Math.floor(t / 60);
  const s = Math.floor(t % 60);
  return `${m}:${String(s).padStart(2, "0")}`;
};

// validate + store a picked audio file
export const importTrack = async (file, order) => {
  const type = file.type || "";
  if (!/^audio\//.test(type)) throw new Error("Only audio files are supported");
  const duration = await new Promise((resolve) => {
    const url = URL.createObjectURL(file);
    const el = document.createElement("audio");
    el.preload = "metadata";
    const done = (v) => { URL.revokeObjectURL(url); resolve(v); };
    el.onloadedmetadata = () => done(isFinite(el.duration) ? el.duration : 0);
    el.onerror = () => done(0);
    el.src = url;
    setTimeout(() => done(0), 10000);
  });
  const record = {
    id: `trk-${Date.now()}-${Math.random().toString(36).slice(2, 7)}`,
    name: (file.name || "Track").replace(/\.[^.]+$/, ""),
    type,
    blob: file,
    duration,
    order,
    created: Date.now(),
  };
  await putTrack(record);
  return record;
};