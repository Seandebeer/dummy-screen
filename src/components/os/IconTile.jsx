import React from "react";
import { cn } from "@/lib/utils";

const SIZES = {
  sm: { box: "h-9 w-9", icon: 16 },
  md: { box: "h-14 w-14", icon: 26 },
  lg: { box: "h-20 w-20", icon: 38 },
};
// continuous-corner squircle, like a native app icon
const RADIUS = "rounded-[23%]";

function tileStyle(app) {
  const { bg, tile } = app;
  const t = tile || {};
  const fg = t.fg || "#fff";
  switch (t.type) {
    case "flat":
      return { style: { background: bg }, fg };
    case "duo":
      return { style: { background: `linear-gradient(180deg, ${bg}, ${t.bg2})` }, fg };
    case "stripes":
      return { style: { background: `repeating-linear-gradient(45deg, ${bg} 0 9px, ${t.bg2} 9px 18px)` }, fg };
    case "dots":
      return { style: { background: `radial-gradient(${t.bg2} 2.5px, transparent 3px), ${bg}`, backgroundSize: "13px 13px" }, fg };
    case "ring":
      return { style: { background: `repeating-radial-gradient(circle at 30% 25%, ${bg} 0 4px, ${t.bg2} 4px 8px)` }, fg };
    case "gloss":
      return { style: { background: `linear-gradient(180deg, rgba(255,255,255,0.5) 0%, rgba(255,255,255,0.1) 45%, rgba(255,255,255,0) 60%), ${bg}` }, fg };
    case "mono":
      return { style: { background: "#ffffff" }, fg: t.fg || bg };
    case "dark":
      return { style: { background: "linear-gradient(145deg, #1c1c1e, #0a0a0a)" }, fg: bg };
    case "outline":
      return { style: { background: `${bg}1f`, border: `2px solid ${bg}` }, fg: t.fg || bg };
    case "glass":
      return { style: { background: `linear-gradient(145deg, rgba(255,255,255,0.4) 0%, rgba(255,255,255,0.08) 45%, rgba(255,255,255,0) 60%), ${bg}` }, fg: "#fff" };
    default: // core apps - clean flat native icon
      return { style: { background: bg }, fg: "#fff" };
  }
}

export default function IconTile({ app, size = "md" }) {
  if (!app) return null;
  const { Icon } = app;
  const s = SIZES[size] || SIZES.md;
  const { style, fg } = tileStyle(app);
  return (
    <span
      className={cn("relative flex items-center justify-center overflow-hidden", s.box, RADIUS)}
      style={style}
    >
      <Icon size={s.icon} style={{ color: fg }} />
    </span>
  );
}