// local video storage for the OS Videos app - clips live in IndexedDB on
// this device so playback works offline. Up to 5 videos, 10 minutes each.
const DB_NAME = "propsync-videos";
const STORE = "videos";
export const MAX_VIDEOS = 5;
export const MAX_DURATION = 600; // seconds

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

export const listVideos = async () => {
  const all = await tx("readonly", (s) => s.getAll());
  return (all || []).sort((a, b) => (a.order ?? 0) - (b.order ?? 0) || (a.created || 0) - (b.created || 0));
};

export const getVideo = (id) => tx("readonly", (s) => s.get(id));
export const putVideo = (record) => tx("readwrite", (s) => s.put(record));
export const deleteVideo = (id) => tx("readwrite", (s) => s.delete(id));

export const updateVideo = async (id, patch) => {
  const rec = await getVideo(id);
  if (!rec) return null;
  const next = { ...rec, ...patch };
  await putVideo(next);
  return next;
};

export const fmtDur = (t) => {
  if (!isFinite(t) || t < 0) t = 0;
  const m = Math.floor(t / 60);
  const s = Math.floor(t % 60);
  return `${m}:${String(s).padStart(2, "0")}`;
};

const loadVideoEl = (url) => new Promise((resolve, reject) => {
  const v = document.createElement("video");
  v.preload = "auto";
  v.muted = true;
  v.playsInline = true;
  v.src = url;
  v.onloadeddata = () => resolve(v);
  v.onerror = () => reject(new Error("This video format is not supported"));
});

const seekTo = (v, t) => new Promise((resolve) => {
  const done = () => { v.removeEventListener("seeked", done); resolve(); };
  v.addEventListener("seeked", done);
  v.currentTime = t;
});

// filmstrip thumbnails for the editor timeline
export const grabThumbs = async (url, duration, count = 8) => {
  const v = await loadVideoEl(url);
  const w = 120;
  const h = Math.max(48, Math.round((v.videoHeight / (v.videoWidth || w)) * w));
  const canvas = document.createElement("canvas");
  canvas.width = w;
  canvas.height = h;
  const ctx = canvas.getContext("2d");
  const thumbs = [];
  for (let i = 0; i < count; i++) {
    try {
      await seekTo(v, ((i + 0.5) / count) * duration);
      ctx.drawImage(v, 0, 0, w, h);
      thumbs.push(canvas.toDataURL("image/jpeg", 0.55));
    } catch { break; }
  }
  v.removeAttribute("src");
  v.load();
  return thumbs;
};

// validate + store a picked file
export const importVideo = async (file, order) => {
  const url = URL.createObjectURL(file);
  try {
    const meta = await new Promise((resolve, reject) => {
      const el = document.createElement("video");
      el.preload = "metadata";
      el.onloadedmetadata = () => resolve(el);
      el.onerror = () => reject(new Error("This video format is not supported"));
      el.src = url;
    });
    const duration = meta.duration;
    if (!isFinite(duration) || duration <= 0) throw new Error("Cannot read this video");
    if (duration > MAX_DURATION) throw new Error("Videos must be 10 minutes or shorter");
    const thumbs = await grabThumbs(url, duration, 8);
    const record = {
      id: `vid-${Date.now()}-${Math.random().toString(36).slice(2, 7)}`,
      name: (file.name || "Video").replace(/\.[^.]+$/, ""),
      type: file.type || "video/mp4",
      blob: file,
      duration,
      thumbs,
      trimStart: 0,
      trimEnd: duration,
      loop: false,
      aspect: "fit",
      order,
      created: Date.now(),
    };
    await putVideo(record);
    return record;
  } finally {
    URL.revokeObjectURL(url);
  }
};