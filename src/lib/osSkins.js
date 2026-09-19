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
    name: "OS 5",
    desc: "2011-era OS 5 - glossy icons, dark metal dock, soft wallpaper.",
    preset: "aqua",
    preview: "radial-gradient(120% 90% at 30% 15%, rgba(90,130,190,0.5), transparent 60%), linear-gradient(180deg, #0a1526, #050910)",
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