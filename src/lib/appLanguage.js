// app-wide language preference - stored locally and applied to the document
const KEY = "propscreen.appLanguage";

export const APP_LANGUAGES = [
  { code: "en", native: "English" },
  { code: "af", native: "Afrikaans" },
  { code: "es", native: "Español" },
  { code: "fr", native: "Français" },
  { code: "de", native: "Deutsch" },
  { code: "pt", native: "Português" },
  { code: "zh", native: "中文（简体）" },
  { code: "ar", native: "العربية", rtl: true },
];

export const getAppLanguage = () => localStorage.getItem(KEY) || "en";

export const applyAppLanguage = (code) => {
  const lang = APP_LANGUAGES.find((l) => l.code === code) || APP_LANGUAGES[0];
  document.documentElement.lang = lang.code;
  document.documentElement.dir = lang.rtl ? "rtl" : "ltr";
};

export const setAppLanguage = (code) => {
  localStorage.setItem(KEY, code);
  applyAppLanguage(code);
};