// Interface skins for the mock OS - each restyles the status bar, dock,
// icon shape, clock, fonts and home button to evoke a different era / platform.
// SKIN_UI carries the per-skin styling consumed by PhoneFrame + Homescreen.
export const OS_SKINS = [
  {
    id: "modern",
    name: "Current OS",
    desc: "Modern premium look - squircle icons, glass dock, hub status bar.",
    preset: "default",
    preview: "linear-gradient(160deg, #1a1d2e 0%, #0a0b14 60%, #000000 100%)",
  },
  {
    id: "aqua",
    name: "OS 5",
    desc: "2011-era OS 5 - glossy icons, dark metal dock, soft wallpaper.",
    preset: "aqua",
    preview: "radial-gradient(120% 90% at 30% 15%, rgba(90,130,190,0.5), transparent 60%), linear-gradient(180deg, #0a1526, #050910)",
  },
  {
    id: "iphoneos",
    name: "iPhone OS",
    desc: "2007 original - glossy reflections, tactile controls, metal dock.",
    preset: "iphoneos",
    preview: "linear-gradient(180deg, #0d0e12, #000000)",
  },
  {
    id: "ios6",
    name: "OS 6",
    desc: "Peak skeuomorphism - linen texture, glass and rich gloss.",
    preset: "linen",
    preview: "repeating-linear-gradient(45deg, rgba(255,255,255,0.05) 0 2px, transparent 2px 4px), linear-gradient(180deg, #3c3c41, #1c1c20)",
  },
  {
    id: "ios7",
    name: "OS 7",
    desc: "The flat turn - thin type, translucency, light gradients.",
    preset: "ios7",
    preview: "linear-gradient(180deg, #123253, #0b1e38)",
  },
  {
    id: "blackberry",
    name: "BlackBerry",
    desc: "Corporate classic - dense info, tiny icons, dark blue.",
    preset: "bb",
    preview: "linear-gradient(180deg, #101b2a, #060b13)",
  },
  {
    id: "winphone",
    name: "Windows Phone",
    desc: "Live-tile radical - giant type, flat squares, accent colour.",
    preset: "wp",
    preview: "linear-gradient(180deg, #000000 72%, #1BA1E2 72%)",
  },
  {
    id: "holo",
    name: "Android Holo",
    desc: "Sci-fi Android - electric blue lines, dark panels, thin type.",
    preset: "holo",
    preview: "linear-gradient(180deg, #090c10, #020306)",
  },
  {
    id: "material",
    name: "Android Material",
    desc: "Google's Material - cards, elevation, bright colour.",
    preset: "material",
    preview: "linear-gradient(180deg, #263238, #11181c)",
  },
  {
    id: "android",
    name: "Current Android",
    desc: "Material You - circular icons, tinted dock, light status bar.",
    preset: "droid",
    preview: "linear-gradient(160deg, #101418 0%, #14202a 55%, #0a0e12 100%)",
  },
  {
    id: "webos",
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
    home: "modern",
  },
  aqua: {
    font: '"Helvetica Neue", Helvetica, Arial, sans-serif',
    clock: { size: 44, weight: 300, style: { color: "rgba(255,255,255,0.95)", textShadow: "0 -1px 0 rgba(0,0,0,0.5), 0 1px 1px rgba(255,255,255,0.25)" } },
    status: {
      className: "font-normal text-white border-b border-white/15",
      timeCenter: true,
      style: {
        backgroundImage:
          "linear-gradient(180deg, rgba(255,255,255,0.14), rgba(255,255,255,0.03) 45%, rgba(255,255,255,0) 50%), linear-gradient(180deg, #303236 0%, #0a0a0a 100%)",
      },
    },
    dock: {
      className: "rounded-xl shadow-[0_2px_10px_rgba(0,0,0,0.45)]",
      style: {
        backgroundImage:
          "repeating-linear-gradient(90deg, rgba(255,255,255,0.05) 0 2px, transparent 2px 4px), linear-gradient(180deg, rgba(255,255,255,0.25) 0%, rgba(255,255,255,0.06) 8%, rgba(255,255,255,0) 50%), linear-gradient(180deg, #3a3f4a 0%, #14161c 100%)",
        borderTop: "1px solid rgba(255,255,255,0.35)",
      },
    },
    home: "aqua",
  },
  iphoneos: {
    font: 'Helvetica, "Helvetica Neue", Arial, sans-serif',
    clock: { size: 44, weight: 300, style: { textShadow: "0 -1px 0 rgba(0,0,0,0.6)" } },
    status: {
      className: "font-normal text-[12px]",
      style: {
        backgroundImage:
          "linear-gradient(180deg, rgba(255,255,255,0.2) 0%, rgba(255,255,255,0.05) 45%, rgba(255,255,255,0) 55%), linear-gradient(180deg, #414147 0%, #16161a 100%)",
        borderBottom: "1px solid rgba(0,0,0,0.6)",
        boxShadow: "inset 0 -1px 0 rgba(255,255,255,0.14)",
      },
    },
    dock: {
      className: "rounded-lg",
      style: {
        backgroundImage:
          "linear-gradient(180deg, rgba(255,255,255,0.38) 0%, rgba(255,255,255,0.08) 10%, rgba(255,255,255,0) 50%), linear-gradient(180deg, #3c3c42 0%, #131317 100%)",
        borderTop: "1px solid rgba(255,255,255,0.42)",
        boxShadow: "0 -2px 8px rgba(0,0,0,0.55)",
      },
    },
    home: "aqua",
  },
  ios6: {
    font: '"Helvetica Neue", Helvetica, Arial, sans-serif',
    clock: { size: 46, weight: 300, style: { textShadow: "0 -1px 0 rgba(0,0,0,0.65)" } },
    status: {
      className: "font-normal text-[12px] text-white",
      style: {
        backgroundImage:
          "repeating-linear-gradient(45deg, rgba(255,255,255,0.03) 0 2px, transparent 2px 4px), linear-gradient(180deg, #3a3a40 0%, #141417 100%)",
        borderBottom: "1px solid rgba(0,0,0,0.55)",
        boxShadow: "inset 0 -1px 0 rgba(255,255,255,0.12)",
      },
    },
    dock: {
      className: "rounded-lg",
      style: {
        backgroundImage:
          "repeating-linear-gradient(90deg, rgba(255,255,255,0.05) 0 2px, transparent 2px 4px), linear-gradient(180deg, rgba(255,255,255,0.22) 0%, rgba(255,255,255,0.05) 10%, rgba(255,255,255,0) 50%), linear-gradient(180deg, #26262c 0%, #0b0b0e 100%)",
        borderTop: "1px solid rgba(255,255,255,0.32)",
      },
    },
    home: "aqua",
  },
  ios7: {
    font: '"Helvetica Neue", Helvetica, Arial, sans-serif',
    clock: { size: 50, weight: 200 },
    status: { className: "font-normal text-[12px]", style: { background: "rgba(0,0,0,0.12)" } },
    dock: { className: "rounded-[1.4rem] backdrop-blur-2xl", light: "bg-white/40", dark: "bg-white/15" },
    home: "modern",
  },
  blackberry: {
    font: '"BBAlpha Sans", "Open Sans", "Segoe UI", Tahoma, sans-serif',
    clock: { size: 36, weight: 500, style: { letterSpacing: "0.02em" } },
    status: {
      className: "font-normal text-[10px]",
      style: {
        backgroundImage: "linear-gradient(180deg, #1c2838 0%, #0a121d 100%)",
        borderBottom: "1px solid rgba(255,255,255,0.18)",
      },
    },
    dock: {
      className: "rounded-md",
      style: {
        backgroundImage: "linear-gradient(180deg, #22334a 0%, #101a28 100%)",
        borderTop: "1px solid rgba(255,255,255,0.22)",
        boxShadow: "inset 0 1px 0 rgba(255,255,255,0.1)",
      },
    },
    home: "trackpad",
  },
  winphone: {
    font: '"Segoe UI", "Segoe WP", Tahoma, sans-serif',
    clock: { size: 64, weight: 200, style: { letterSpacing: "-0.01em" } },
    status: { className: "font-normal text-[10px] pt-2.5" },
    dock: { className: "rounded-none", style: { background: "#1BA1E2" } },
    home: "wp",
  },
  holo: {
    font: 'Roboto, "Helvetica Neue", Arial, sans-serif',
    clock: { size: 56, weight: 200 },
    status: {
      className: "font-normal text-[11px]",
      style: {
        backgroundImage: "linear-gradient(180deg, rgba(51,181,229,0.22) 0%, rgba(51,181,229,0.05) 70%, rgba(0,0,0,0) 100%)",
        borderBottom: "1px solid rgba(51,181,229,0.5)",
      },
    },
    dock: {
      className: "rounded-none",
      style: {
        backgroundImage: "linear-gradient(180deg, rgba(51,181,229,0.14) 0%, rgba(0,0,0,0.4) 100%)",
        borderTop: "1px solid rgba(51,181,229,0.5)",
        boxShadow: "0 -2px 12px rgba(51,181,229,0.15)",
      },
    },
    home: "holo",
  },
  material: {
    font: 'Roboto, "Helvetica Neue", Arial, sans-serif',
    clock: { size: 50, weight: 400 },
    status: {
      className: "font-normal text-[12px]",
      style: { backgroundImage: "linear-gradient(180deg, #2c3944 0%, #171f25 100%)" },
    },
    dock: {
      className: "rounded-2xl",
      style: { background: "rgba(38,50,56,0.94)", boxShadow: "0 4px 14px rgba(0,0,0,0.55), 0 1px 3px rgba(0,0,0,0.4)" },
    },
    home: "holo",
  },
  android: {
    font: 'Roboto, "Helvetica Neue", Arial, sans-serif',
    clock: { size: 52, weight: 300 },
    status: { className: "font-normal text-[12px] pt-3" },
    dock: {
      className: "rounded-[1.6rem] border border-white/10 backdrop-blur-2xl",
      style: { background: "rgba(22,33,43,0.8)" },
    },
    home: "android",
  },
  webos: {
    font: 'Gotham, Montserrat, "Segoe UI", Arial, sans-serif',
    clock: { size: 46, weight: 200 },
    status: { className: "font-normal text-[12px]", style: { background: "rgba(0,0,0,0.3)" } },
    dock: {
      className: "rounded-[2rem] backdrop-blur-2xl",
      style: { background: "rgba(18,22,34,0.55)", border: "1px solid rgba(255,255,255,0.14)" },
    },
    home: "webos",
  },
};

export const skinUi = (id) => SKIN_UI[id] || SKIN_UI.modern;

export const skinOf = (config) =>
  OS_SKINS.find((s) => s.id === config?.skin) || OS_SKINS[0];