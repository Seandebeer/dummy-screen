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
    id: "aqua",
    era: "legacy",
    name: "OS 5",
    desc: "2011-era OS 5 - glossy icons, dark metal dock, soft wallpaper.",
    preset: "aqua",
    preview: "radial-gradient(120% 90% at 30% 15%, rgba(90,130,190,0.5), transparent 60%), linear-gradient(180deg, #0a1526, #050910)",
  },
  {
    id: "iphoneos",
    era: "legacy",
    name: "iPhone OS",
    desc: "2007 original - glossy reflections, tactile controls, metal dock.",
    preset: "iphoneos",
    preview: "linear-gradient(180deg, #0d0e12, #000000)",
  },
  {
    id: "ios6",
    era: "legacy",
    name: "OS 6",
    desc: "Peak skeuomorphism - linen texture, glass and rich gloss.",
    preset: "linen",
    preview: "repeating-linear-gradient(45deg, rgba(255,255,255,0.05) 0 2px, transparent 2px 4px), linear-gradient(180deg, #3c3c41, #1c1c20)",
  },
  {
    id: "ios7",
    era: "legacy",
    name: "OS 7",
    desc: "The flat turn - thin type, translucency, light gradients.",
    preset: "ios7",
    preview: "linear-gradient(180deg, #123253, #0b1e38)",
  },
  {
    id: "winphone",
    era: "legacy",
    name: "Windows Phone",
    desc: "Live-tile radical - giant type, flat squares, accent colour.",
    preset: "wp",
    preview: "linear-gradient(180deg, #000000 72%, #1BA1E2 72%)",
  },
  {
    id: "holo",
    era: "legacy",
    name: "Android Holo",
    desc: "Sci-fi Android - electric blue lines, dark panels, thin type.",
    preset: "holo",
    preview: "linear-gradient(180deg, #090c10, #020306)",
  },
  {
    id: "material",
    era: "legacy",
    name: "Android Material",
    desc: "Google's Material - cards, elevation, bright colour.",
    preset: "material",
    preview: "linear-gradient(180deg, #263238, #11181c)",
  },
  {
    id: "android",
    era: "modern",
    name: "Current Android",
    desc: "Material You - circular icons, tinted dock, light status bar.",
    preset: "droid",
    preview: "linear-gradient(160deg, #101418 0%, #14202a 55%, #0a0e12 100%)",
  },
  {
    id: "webos",
    era: "legacy",
    name: "webOS",
    desc: "The cult classic - cards in space, soft glow, gesture bar.",
    preset: "webos",
    preview: "linear-gradient(180deg, #06070d, #10141f)",
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
    clock: { size: 44, weight: 300, style: { textShadow: "0 -1px 0 rgba(0,0,0,0.6)" } },
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
    clock: { size: 46, weight: 300, style: { textShadow: "0 -1px 0 rgba(0,0,0,0.65)" } },
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
    clock: { size: 50, weight: 200 },
    status: { className: "font-normal text-[12px]", style: { background: "rgba(0,0,0,0.12)" } },
    dock: { className: "rounded-[1.4rem] backdrop-blur-2xl", light: "bg-white/40", dark: "bg-white/15" },
    lock: { method: "slide", layout: "ios7" },
    home: "modern",
  },
  winphone: {
    font: '"Segoe UI", "Segoe WP", Tahoma, sans-serif',
    layout: "tiles",
    clock: { size: 64, weight: 200, style: { letterSpacing: "-0.01em" } },
    status: { className: "font-normal text-[13px]", batteryPct: true },
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
  },
};

export const skinUi = (id) => SKIN_UI[id] || SKIN_UI.modern;

export const skinOf = (config) =>
  OS_SKINS.find((s) => s.id === config?.skin) || OS_SKINS[0];