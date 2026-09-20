const KEY = "propsync-app-theme";

export const APP_THEMES = [
  { id: "black", label: "Black" },
  { id: "grey", label: "Grey" },
  { id: "white", label: "Cream" },
];

export function getAppTheme() {
  const saved = localStorage.getItem(KEY);
  return APP_THEMES.some((t) => t.id === saved) ? saved : "black";
}

export function setAppTheme(theme) {
  localStorage.setItem(KEY, theme);
  document.documentElement.dataset.appTheme = theme;
}

// apply the saved theme immediately on first load
setAppTheme(getAppTheme());