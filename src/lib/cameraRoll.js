const KEY = "takeover-os-photos";
const MAX = 12;

export const getPhotos = () => {
  try {
    const photos = JSON.parse(localStorage.getItem(KEY));
    return Array.isArray(photos) ? photos : [];
  } catch {
    return [];
  }
};

// keep within localStorage limits — drop oldest photos if the quota is hit
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

export const deletePhoto = (id) => {
  store(getPhotos().filter((p) => p.id !== id));
  return getPhotos();
};