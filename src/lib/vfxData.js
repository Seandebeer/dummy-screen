export const vfxColors = [
  { id: "green", name: "Green", hex: "#00B140", label: "Chroma Green" },
  { id: "blue", name: "Blue", hex: "#0047BB", label: "Chroma Blue" },
  { id: "grey", name: "Grey 18%", hex: "#7F7F7F", label: "18% Grey" },
  { id: "white", name: "White", hex: "#FFFFFF", label: "Pure White" },
  { id: "black", name: "OLED Black", hex: "#000000", label: "OLED Black" },
];

// composite point-marker styles (rendered by CompositeMarks.jsx)
export const compositeMarks = [
  { id: "circtriplus", label: "Tri Circle" },
  { id: "solidtri", label: "Solid Tri" },
  { id: "squaretri", label: "Square Tri" },
  { id: "invtri", label: "Inverse Tri" },
  { id: "plusgrid", label: "Plus Grid" },
  { id: "dotcircle", label: "Dot Circle" },
  { id: "quads", label: "Quadrant" },
  { id: "squads", label: "Square Quad" },
  { id: "crosshair", label: "Crosshair" },
];

// the standard VFX screen-replacement tracking marker styles
export const trackingMarks = [
  { id: "none", name: "None" },
  { id: "cross", name: "Cross" },
  { id: "circles", name: "Target" },
  { id: "checkerboard", name: "Checker", bwOnly: true },
  { id: "squares", name: "Square" },
  { id: "dots", name: "Dots" },
  { id: "brackets", name: "Brackets" },
  { id: "triangle", name: "Triangle" },
  ...compositeMarks.map((m) => ({ id: m.id, name: m.label })),
];

export const getColor = (id) => vfxColors.find((c) => c.id === id) || vfxColors[0];