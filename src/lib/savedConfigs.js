const KEY = "takeover-saved-configs";

export const listSaved = () => {
  try {
    return JSON.parse(localStorage.getItem(KEY)) || [];
  } catch {
    return [];
  }
};

export const saveConfig = (entry) => {
  const list = listSaved();
  list.unshift({ id: `s-${Date.now()}`, ...entry });
  localStorage.setItem(KEY, JSON.stringify(list));
  return list;
};

export const deleteConfig = (id) => {
  const list = listSaved().filter((s) => s.id !== id);
  localStorage.setItem(KEY, JSON.stringify(list));
  return list;
};