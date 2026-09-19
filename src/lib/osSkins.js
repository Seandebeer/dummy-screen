// Interface skins for the mock OS - each restyles the status bar, dock,
// icon shape and home button to evoke a different era / platform
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
    name: "Apple 2000s",
    desc: "Early-2000s Aqua - glossy pinstripes, silver dock, candy hardware.",
    preset: "aqua",
    preview:
      "repeating-linear-gradient(90deg, rgba(255,255,255,0.25) 0 2px, transparent 2px 5px), linear-gradient(180deg, #6ba3e0, #2f5c94)",
  },
  {
    id: "android",
    name: "Current Android",
    desc: "Material You - circular icons, tinted dock, light status bar.",
    preset: "droid",
    preview: "linear-gradient(160deg, #101418 0%, #14202a 55%, #0a0e12 100%)",
  },
];

export const skinOf = (config) =>
  OS_SKINS.find((s) => s.id === config?.skin) || OS_SKINS[0];