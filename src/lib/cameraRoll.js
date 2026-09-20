const KEY = "takeover-os-photos";
const MAX = 12;

// photos are small data URLs in localStorage; recorded video clips are too
// big for that, so their blobs live in IndexedDB and the roll keeps only a
// poster frame + metadata in localStorage.
const DB_NAME = "propsync-camroll";
const STORE = "clips";

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

export const getPhotos = () => {
  try {
    const photos = JSON.parse(localStorage.getItem(KEY));
    return Array.isArray(photos) ? photos : [];
  } catch {
    return [];
  }
};

// keep within localStorage limits - drop oldest photos if the quota is hit
const store = (photos) => {
  const attempts = [photos, photos.slice(0, 8), photos.slice(0, 4)];
  for (const list of attempts) {
    try {
      localStorage.setItem(KEY, JSON.stringify(list));
      return;
    } catch {}
  }
};

export const addPhoto = (dataUrl) => {
  store([{ id: `p-${Date.now()}`, url: dataUrl, created: Date.now() }, ...getPhotos()].slice(0, MAX));
  return getPhotos();
};

export const addVideo = async (blob, poster) => {
  const id = `v-${Date.now()}`;
  await tx("readwrite", (s) => s.put({ id, blob }));
  store([{ id, type: "video", poster, created: Date.now() }, ...getPhotos()].slice(0, MAX));
  return getPhotos();
};

export const getClip = (id) => tx("readonly", (s) => s.get(id)).catch(() => null);

export const deletePhoto = (id) => {
  tx("readwrite", (s) => s.delete(id)).catch(() => {});
  store(getPhotos().filter((p) => p.id !== id));
  return getPhotos();
};