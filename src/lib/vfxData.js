export const vfxColors = [
  { id: "green", name: "Green", hex: "#00B140", label: "Chroma Green" },
  { id: "blue", name: "Blue", hex: "#0047BB", label: "Chroma Blue" },
  { id: "grey", name: "Grey 18%", hex: "#7F7F7F", label: "18% Grey" },
  { id: "white", name: "White", hex: "#FFFFFF", label: "Pure White" },
  { id: "black", name: "OLED Black", hex: "#000000", label: "OLED Black" },
];

// the six standard VFX screen-replacement tracking marker styles
export const trackingMarks = [
  { id: "none", name: "None" },
  { id: "cross", name: "Cross" },
  { id: "circles", name: "Circle" },
  { id: "checkerboard", name: "Checker", bwOnly: true },
  { id: "squares", name: "Square" },
  { id: "dots", name: "Dots" },
  { id: "brackets", name: "Brackets" },
];

export const getColor = (id) => vfxColors.find((c) => c.id === id) || vfxColors[0];