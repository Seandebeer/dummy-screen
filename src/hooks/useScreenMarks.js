import { useState, useEffect } from "react";

const KEY = "takeover-screen-marks";

const pt = (id, kind, x, y) => ({ id, kind, x, y });

// default marker layout for a point style — four corners (+ center for some)
export const defaultLayoutFor = (style) => {
  const corners = [
    ["tl", 8, 8], ["tr", 92, 8], ["bl", 8, 92], ["br", 92, 92],
  ].map(([s, x, y]) => pt(`${style}-${s}`, style, x, y));
  if (style === "squares") return corners;
  return [...corners, pt(`${style}-c`, style === "brackets" ? "diamond" : style, 50, 50)];
};

const buildDefaults = () => ({
  cross: defaultLayoutFor("cross"),
  circles: defaultLayoutFor("circles"),
  squares: defaultLayoutFor("squares"),
  brackets: defaultLayoutFor("brackets"),
});

const defaults = { scale: 1, thickness: 1, layouts: buildDefaults() };

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