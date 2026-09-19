import { useState, useEffect } from "react";

const KEY = "takeover-screen-marks";

const pt = (id, kind, x, y) => ({ id, kind, x, y });

// default marker layout for a point style - four corners (+ center for some)
export const defaultLayoutFor = (style) => {
  // extra horizontal inset so markers clear the side edges even when rotated
  const insetX = style === "squares" ? 16 : 14;
  const insetY = 14;
  const corners = [
    ["tl", insetX, insetY], ["tr", 100 - insetX, insetY],
    ["bl", insetX, 100 - insetY], ["br", 100 - insetX, 100 - insetY],
  ].map(([s, x, y]) => pt(`${style}-${s}`, style, x, y));
  if (style === "squares") return corners;
  return [...corners, pt(`${style}-c`, style === "brackets" ? "diamond" : style, 50, 50)];
};

const POINT_IDS = ["cross", "circles", "squares", "brackets", "triangle",
  "circtriplus", "solidtri", "squaretri", "invtri", "plusgrid", "dotcircle", "quads", "squads", "crosshair"];
const buildDefaults = () => Object.fromEntries(POINT_IDS.map((s) => [s, defaultLayoutFor(s)]));

const defaults = { scale: 1, thickness: 1, markColor: null, bgColor: null, bgImage: null, layouts: buildDefaults() };

function load() {
  try {
    const saved = JSON.parse(localStorage.getItem(KEY));
    if (saved) return { ...defaults, ...saved, layouts: { ...buildDefaults(), ...(saved.layouts || {}) } };
  } catch {}
  return defaults;
}

export default function useScreenMarks() {
  const [marks, setMarks] = useState(load);

  useEffect(() => { localStorage.setItem(KEY, JSON.stringify(marks)); }, [marks]);

  const update = (patch) => setMarks((m) => ({ ...m, ...(typeof patch === "function" ? patch(m) : patch) }));
  return { marks, update };
}