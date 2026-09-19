import { useState, useEffect } from "react";

const KEY = "takeover-screen-marks";

const pt = (id, kind, x, y) => ({ id, kind, x, y });

// default marker layout for a point style - four corners (+ center for some)
export const defaultLayoutFor = (style) => {
  // corners sit one grid cell in from the edges: exact intersections of
  // the 5 x 8 snap grid (x = 20/80, y = 12.5/87.5), clear of the borders
  const corners = [
    ["tl", 20, 12.5], ["tr", 80, 12.5],
    ["bl", 20, 87.5], ["br", 80, 87.5],
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