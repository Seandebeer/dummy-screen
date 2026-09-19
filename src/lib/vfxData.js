export const vfxColors = [
  { id: "green", name: "Green", hex: "#00B140", label: "Chroma Green" },
  { id: "blue", name: "Blue", hex: "#0047BB", label: "Chroma Blue" },
  { id: "grey", name: "Grey 18%", hex: "#7F7F7F", label: "18% Grey" },
  { id: "white", name: "White", hex: "#FFFFFF", label: "Pure White" },
  { id: "black", name: "OLED Black", hex: "#000000", label: "OLED Black" },
];

export const trackingMarks = [
  { id: "none", name: "None" },
  { id: "crosshair", name: "Crosshair" },
  { id: "lbar", name: "L-Bar" },
  { id: "dotgrid", name: "Dot Grid" },
  { id: "grid", name: "Grid" },
  { id: "rings", name: "Rings" },
  { id: "triangles", name: "Triangles" },
  { id: "plus", name: "Plus" },
  { id: "registration", name: "Reg Mark" },
  { id: "checkerboard", name: "Checker", bwOnly: true },
];

export const getColor = (id) => vfxColors.find((c) => c.id === id) || vfxColors[0];