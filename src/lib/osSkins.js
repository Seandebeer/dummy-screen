// Interface skins for the mock OS - each restyles the status bar, dock,
// icon shape, clock, fonts and home button to evoke a different era / platform.
// SKIN_UI carries the per-skin styling consumed by PhoneFrame + Homescreen.
export const OS_SKINS = [
  {
    id: "modern",
    era: "modern",
    name: "Current OS",
    desc: "Modern premium look - squircle icons, glass dock, hub status bar.",
    preset: "default",
    preview: "linear-gradient(160deg, #1a1d2e 0%, #0a0b14 60%, #000000 100%)",
  },
  {
    id: "iphoneos",
    era: "legacy",
    name: "iPhone OS",
    desc: "2007 original iPhone. Glossy icons and a metal dock.",
    preset: "iphoneos",
    preview: "linear-gradient(180deg, #2a2a2e, #050506)",
  },
  {
    id: "ios6",
    era: "legacy",
    name: "iOS 6",
    desc: "2012. Glossy icons, water wallpaper, and a glass dock.",
    preset: "linen",
    preview: "linear-gradient(180deg, #7ec8e3, #0e3a5a)",
  },
  {
    id: "ios7",
    era: "legacy",
    name: "iOS 7",
    desc: "2013. Flat icons and a translucent dock.",
    preset: "ios7",
    preview: "radial-gradient(circle at 40% 20%, #3d6ea8, #0c1a33)",
  },
  {
    id: "winphone",
    era: "legacy",
    name: "Windows Phone",
    desc: "2010. Metro live tiles and a three-button bar.",
    preset: "wp",
    preview: "linear-gradient(180deg, #000000 70%, #1BA1E2 70%)",
  },
  {
    id: "holo",
    era: "legacy",
    name: "Android Holo",
    desc: "2011. Search, a clock, and a five-icon dock.",
    preset: "holo",
    preview: "linear-gradient(180deg, #2f80ed, #4a148c)",
  },
  {
    id: "webos",
    era: "legacy",
    name: "webOS",
    desc: "2009. A launcher grid and a quick-launch dock.",
    preset: "webos",
    preview: "linear-gradient(135deg, #8d8a7a, #4e5248)",
  },
  {
    id: "belle",
    era: "legacy",
    name: "Nokia Belle",
    desc: "2011. Widgets, name plates, and a status bar.",
    preset: "belle",
    preview: "linear-gradient(135deg, #f6b13a, #1b4f8a)",
  },
  {
    id: "android",
    era: "modern",
    name: "Current Android",
    desc: "Material You - circular icons, tinted dock, light status bar.",
    preset: "droid",
    preview: "linear-gradient(160deg, #101418 0%, #14202a 55%, #0a0e12 100%)",
  },
];

export const SKIN_UI = {
  modern: {
    clock: { size: 52, weight: 600 },
    status: { className: "font-semibold" },
    dock: { className: "rounded-[1.9rem] backdrop-blur-2xl", light: "bg-white/35", dark: "bg-white/15" },
    lock: { method: "none" },
    home: "modern",
  },
  aqua: {
    font: '"Helvetica Neue", Helvetica, Arial, sans-serif',
    clock: { size: 44, weight: 300, style: { color: "rgba(255,255,255,0.95)", textShadow: "0 -1px 0 rgba(0,0,0,0.5), 0 1px 1px rgba(255,255,255,0.25)" } },
    status: {
      className: "font-normal text-white",
      timeCenter: true,
      carrier: true,
      batteryPct: true,
      style: {
        backgroundImage: "linear-gradient(180deg, rgba(0,0,0,0.38) 0%, rgba(0,0,0,0.14) 100%)",
      },
    },
    dock: {
      className: "rounded-xl",
      labels: true,
      style: {
        backgroundImage:
          "linear-gradient(180deg, rgba(255,255,255,0.22) 0%, rgba(255,255,255,0.07) 8%, rgba(255,255,255,0) 42%, rgba(255,255,255,0) 58%, rgba(255,255,255,0.07) 100%), linear-gradient(180deg, rgba(56,56,60,0.82) 0%, rgba(30,30,34,0.78) 100%)",
        borderTop: "1px solid rgba(255,255,255,0.28)",
        boxShadow: "0 -1px 8px rgba(0,0,0,0.22)",
      },
    },
    lock: { method: "slide", layout: "ios" },
    home: "aqua",
  },
  iphoneos: {
    font: 'Helvetica, "Helvetica Neue", Arial, sans-serif',
    clock: { hidden: true },
    status: {
      className: "font-normal text-[12px]",
      timeCenter: true,
      carrier: true,
      style: {
        backgroundImage:
          "linear-gradient(180deg, rgba(255,255,255,0.14) 0%, rgba(255,255,255,0.03) 45%, rgba(255,255,255,0) 55%), linear-gradient(180deg, rgba(0,0,0,0.5) 0%, rgba(0,0,0,0.22) 100%)",
      },
    },
    dock: {
      className: "rounded-lg",
      labels: true,
      style: {
        backgroundImage:
          "repeating-linear-gradient(90deg, rgba(255,255,255,0.05) 0 1px, transparent 1px 3px), linear-gradient(180deg, rgba(255,255,255,0.5) 0%, rgba(255,255,255,0.1) 10%, rgba(255,255,255,0) 50%), linear-gradient(180deg, #7C7F84 0%, #9EA2A8 55%, #A7AAB0 100%)",
        borderTop: "1px solid rgba(255,255,255,0.65)",
        boxShadow: "0 -2px 10px rgba(0,0,0,0.5)",
      },
    },
    lock: { method: "slide", layout: "ios" },
    home: "aqua",
  },
  ios6: {
    font: '"Helvetica Neue", Helvetica, Arial, sans-serif',
    clock: { hidden: true },
    status: {
      className: "font-normal text-[13px] text-white",
      timeCenter: true,
      carrier: true,
      batteryPct: true,
      style: {
        backgroundImage: "linear-gradient(180deg, rgba(0,0,0,0.38) 0%, rgba(0,0,0,0.14) 100%)",
      },
    },
    dock: {
      className: "rounded-xl",
      labels: true,
      style: {
        backgroundImage:
          "linear-gradient(180deg, rgba(255,255,255,0.22) 0%, rgba(255,255,255,0.07) 8%, rgba(255,255,255,0) 42%, rgba(255,255,255,0) 58%, rgba(255,255,255,0.07) 100%), linear-gradient(180deg, rgba(56,56,60,0.82) 0%, rgba(30,30,34,0.78) 100%)",
        borderTop: "1px solid rgba(255,255,255,0.28)",
        boxShadow: "0 -1px 8px rgba(0,0,0,0.22)",
      },
    },
    lock: { method: "slide", layout: "ios" },
    home: "aqua",
  },
  ios7: {
    font: '"Helvetica Neue", Helvetica, Arial, sans-serif',
    clock: { hidden: true },
    status: { className: "font-normal text-[12px]", timeCenter: true, carrier: true, style: { background: "rgba(0,0,0,0.12)" } },
    dock: { className: "rounded-[1.4rem] backdrop-blur-2xl", light: "bg-white/40", dark: "bg-white/15" },
    lock: { method: "slide", layout: "ios7" },
    home: "modern",
  },
  winphone: {
    font: '"Segoe UI", "Segoe WP", Tahoma, sans-serif',
    layout: "tiles",
    clock: { size: 64, weight: 200, style: { letterSpacing: "-0.01em" } },
    status: { className: "font-normal text-[13px]", timeRight: true },
    dock: { hidden: true, arrow: "wp" },
    lock: { method: "none", layout: "wp" },
    home: "wp",
  },
  holo: {
    font: 'Roboto, "Helvetica Neue", Arial, sans-serif',
    widget: "holo",
    clock: { size: 56, weight: 200 },
    status: { className: "font-normal text-[13px]", batteryPct: true, style: { background: "#000" } },
    dock: {
      drawer: "center",
      drawerStyle: "dots",
      labels: true,
      className: "rounded-lg border border-[#2a5d99]/60 bg-black/30",
    },
    lock: { method: "ring", layout: "holo" },
    home: "holo",
  },
  material: {
    font: 'Roboto, "Helvetica Neue", Arial, sans-serif',
    clock: { size: 50, weight: 400 },
    status: {
      className: "font-normal text-[12px]",
      style: { backgroundImage: "linear-gradient(180deg, #2c3944 0%, #171f25 100%)" },
    },
    dock: { drawer: "center" },
    lock: { method: "none" },
    home: "holo",
  },
  android: {
    font: 'Roboto, "Helvetica Neue", Arial, sans-serif',
    clock: { size: 52, weight: 300 },
    status: { className: "font-normal text-[12px] pt-3" },
    dock: { drawer: "center" },
    lock: { method: "none" },
    home: "android",
  },
  webos: {
    font: 'Gotham, Montserrat, "Segoe UI", Arial, sans-serif',
    clock: { size: 46, weight: 200 },
    status: { className: "font-normal text-[12px]", style: { background: "rgba(0,0,0,0.3)" } },
    dock: {
      drawer: "end",
      className: "mx-0 rounded-none px-2 pb-1.5",
      style: { backgroundImage: "linear-gradient(180deg, rgba(0,0,0,0.02) 0%, rgba(0,0,0,0.5) 100%)" },
    },
    lock: { method: "none" },
    home: "webos",
    columns: 3,
  },
  belle: {
    font: '"Nokia Pure", "Segoe UI", Arial, sans-serif',
    clock: { hidden: true },
    status: { className: "font-semibold text-[12px]", carrier: true, batteryPct: true },
    dock: { hidden: true, arrow: "belle" },
    lock: { method: "none" },
    home: "belle",
    columns: 4,
  },
};

export const skinUi = (id) => SKIN_UI[id] || SKIN_UI.modern;

export const skinOf = (config) =>
  OS_SKINS.find((s) => s.id === config?.skin) || OS_SKINS[0];