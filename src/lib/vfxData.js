export const vfxColors = [
  { id: "green", name: "Green", hex: "#00FF00", label: "Chroma Green" },
  { id: "blue", name: "Blue", hex: "#0044FF", label: "Chroma Blue" },
  { id: "grey", name: "Grey 18%", hex: "#2A2A2A", label: "18% Grey" },
  { id: "white", name: "White", hex: "#FFFFFF", label: "Pure White" },
  { id: "black", name: "OLED Black", hex: "#000000", label: "OLED Black" },
];

export const trackingMarks = [
  { id: "none", name: "None" },
  { id: "crosshair", name: "Crosshair" },
  { id: "lbar", name: "L-Bar" },
  { id: "dotgrid", name: "Dot Grid" },
];

export const getColor = (id) => vfxColors.find((c) => c.id === id) || vfxColors[0];